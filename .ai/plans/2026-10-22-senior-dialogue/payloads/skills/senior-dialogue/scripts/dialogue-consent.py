#!/usr/bin/env python3
"""Senior Dialogue consent ledger for private-ai-harness.

Hook processes record human agreement on decision cards into an append-only,
hash-chained, HMAC-signed ledger at ``<git-root>/.ai/dialogue/consent.jsonl``.
The model never writes the ledger: a PreToolUse guard denies tool calls that
touch it, the HMAC key, the hook wiring, or carry the agreement token outside
the host's ask-user tool. The agent only reads state through ``status`` and
``check``.

Fail-safe contract (every ``hook`` path exits 0):
- recording fails safe: on any doubt nothing is recorded, so the agent parks;
- the guard fails open on internal error, because Copilot CLI preToolUse
  command hooks are fail-closed on crash and a crash would block every tool.

Threat model: stops accidental or drift-driven self-agreement and casual
forgery. It cannot stop a deliberately adversarial model that obfuscates shell
commands while running as the same OS user; that limit is documented in
skills/senior-dialogue/references/consent-protocol.md.

Stdlib only. Python >= 3.9.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import fcntl
import hashlib
import hmac
import json
import os
import re
import secrets
import sys
import tempfile
from pathlib import Path

LEDGER_VERSION = 1
# Spelled split so this file never contains the literal token the guard blocks.
TOKEN = "AG" + "REE"
_ID = r"[Dd]-\d{3}"
IDS = rf"{_ID}(?:\.\.{_ID})?(?:\s*,\s*{_ID}(?:\.\.{_ID})?)*"
VERB_RE = re.compile(rf"(?i)\b({TOKEN}|REVISE|PARK)\s+({IDS})")
WHOLE_LINE_RE = re.compile(rf"(?i)^\s*{TOKEN}\s+({IDS})\s*$")
PREFIX_RE = re.compile(rf"(?i)^\s*{TOKEN}\s+({IDS})\b")
GUARD_TOKEN_RE = re.compile(rf"(?i)\b{TOKEN}\s+d-\d")
MAX_RANGE = 50

ASK_TOOLS = {"AskUserQuestion", "ask_user", "request_user_input", "question"}
TOKEN_EXEMPT_TOOLS = ASK_TOOLS | {"task_complete"}
PROTECTED = (
    "consent.jsonl",
    "consent.key",
    "dialogue-consent.py",
    "dialogue-consent.json",
    "private-ai-harness-dialogue-consent.js",
    "hooks/private-ai-harness.json",
    "disableAllHooks",
    ".claude/settings",
    ".codex/hooks",
    ".codex/config.toml",
    ".github/hooks",
    ".opencode/plugin",
    "copilot/settings",
)
SAFE_CLI_RE = re.compile(
    r"""^\s*(?:/usr/bin/env\s+)?python3?\s+["']?[^"';&|`$<>()\n]*"""
    r"""dialogue-consent\.py["']?\s+(?:activate|status|check|selftest)\b"""
    r"""[^;&|`$<>()\n]*$"""
)
SAFE_GIT_RE = re.compile(
    r"""^\s*git\s+(?:add|commit|status|diff|log|show)\b[^;&|`$<>()\n]*$"""
)

EXIT_OK, EXIT_MISSING, EXIT_TAMPER, EXIT_USAGE = 0, 3, 4, 5


# ── paths and keys ──────────────────────────────────────────────────────────


def harness_home() -> Path:
    default = Path.home() / ".private-ai-harness"
    return Path(os.environ.get("PRIVATE_AI_HARNESS_HOME", str(default)))


def git_root(start: Path) -> Path:
    path = start.resolve()
    for candidate in (path, *path.parents):
        if (candidate / ".git").exists():
            return candidate
    return path


def ledger_path(root: Path) -> Path:
    return root / ".ai" / "dialogue" / "consent.jsonl"


def pointer_path(root: Path) -> Path:
    return root / ".ai" / "dialogue" / "active"


def load_key(create: bool) -> bytes | None:
    path = harness_home() / "consent.key"
    if path.exists():
        return path.read_text(encoding="utf-8").strip().encode()
    if not create:
        return None
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError:
        return path.read_text(encoding="utf-8").strip().encode()
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(secrets.token_hex(32))
    return path.read_text(encoding="utf-8").strip().encode()


def canonical(row: dict) -> str:
    body = {k: v for k, v in row.items() if k != "mac"}
    return json.dumps(body, sort_keys=True, separators=(",", ":"))


def sign(key: bytes, row: dict) -> str:
    return hmac.new(key, canonical(row).encode(), hashlib.sha256).hexdigest()


def sha(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


# ── decision ids ────────────────────────────────────────────────────────────


def expand_ids(ids_text: str) -> list[str]:
    """Expand "D-003..D-005, D-009" into sorted unique ids; [] if malformed."""
    out: list[str] = []
    for part in re.split(r"\s*,\s*", ids_text.strip()):
        if ".." in part:
            low, high = part.split("..", 1)
            start, end = int(low[2:]), int(high[2:])
            if end < start or end - start > MAX_RANGE:
                return []
            out.extend(f"D-{n:03d}" for n in range(start, end + 1))
        else:
            out.append(f"D-{int(part[2:]):03d}")
    return sorted(set(out))


def first_line(text: str) -> str:
    stripped = text.strip()
    return stripped.splitlines()[0] if stripped else ""


def ids_from_prompt(prompt: str) -> list[str]:
    match = WHOLE_LINE_RE.match(first_line(prompt))
    return expand_ids(match.group(1)) if match else []


def ids_from_structured_answers(answers: dict) -> list[str]:
    ids: list[str] = []
    for value in answers.values():
        if isinstance(value, str):
            match = PREFIX_RE.match(first_line(value))
            if match:
                ids.extend(expand_ids(match.group(1)))
    return sorted(set(ids))


def ids_from_text_failsafe(text: str) -> list[str]:
    """Record only when the text carries exactly one unambiguous agreement.

    Ask-tool results may echo every offered option. If any REVISE/PARK token
    appears, or AGREE tokens disagree on the id set, record nothing.
    """
    verbs = VERB_RE.findall(text)
    agreements = [expand_ids(ids) for verb, ids in verbs if verb.upper() == TOKEN]
    if not agreements:
        return []
    if any(verb.upper() != TOKEN for verb, _ in verbs):
        return []
    if any(agreement != agreements[0] for agreement in agreements):
        return []
    return agreements[0]


def ids_from_answer(response, tool_input) -> list[str]:
    for source in (response, tool_input):
        if isinstance(source, dict) and isinstance(source.get("answers"), dict):
            return ids_from_structured_answers(source["answers"])
    text = response
    if isinstance(response, dict):
        for key in ("textResultForLlm", "text_result_for_llm"):
            if isinstance(response.get(key), str):
                text = response[key]
                break
    if not isinstance(text, str):
        text = json.dumps(text, sort_keys=True, default=str)
    return ids_from_text_failsafe(text)


# ── ledger ──────────────────────────────────────────────────────────────────


def active_work_item(root: Path) -> str | None:
    pointer = pointer_path(root)
    if not pointer.is_file():
        return None
    value = pointer.read_text(encoding="utf-8").strip()
    return value or None


def append_row(root: Path, host: str, channel: str, session: str,
               ids: list[str], evidence: str) -> bool:
    work_item = active_work_item(root)
    if not work_item or not ids:
        return False
    key = load_key(create=True)
    path = ledger_path(root)
    path.parent.mkdir(parents=True, exist_ok=True)
    evidence_sha = sha(evidence)
    with open(path, "a+", encoding="utf-8") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        handle.seek(0)
        lines = [line for line in handle.read().splitlines() if line.strip()]
        for line in lines[-20:]:
            try:
                previous = json.loads(line)
            except ValueError:
                continue
            if (previous.get("work_item") == work_item
                    and previous.get("decision_ids") == ids
                    and previous.get("evidence_sha256") == evidence_sha):
                return False
        row = {
            "v": LEDGER_VERSION,
            "ts": _dt.datetime.now(_dt.timezone.utc).isoformat(),
            "host": host,
            "channel": channel,
            "session_id": session or "",
            "work_item": work_item,
            "decision_ids": ids,
            "ranged": len(ids) > 1,
            "evidence_sha256": evidence_sha,
            "evidence_excerpt": evidence[:200],
            "prev": sha(lines[-1]) if lines else "GENESIS",
        }
        row["mac"] = sign(key, row)
        handle.seek(0, os.SEEK_END)
        handle.write(json.dumps(row, sort_keys=True) + "\n")
        handle.flush()
    return True


def read_ledger(root: Path) -> tuple[list[dict], list[str]]:
    path = ledger_path(root)
    if not path.is_file():
        return [], []
    key = load_key(create=False)
    rows: list[dict] = []
    problems: list[str] = []
    previous = "GENESIS"
    lines = path.read_text(encoding="utf-8").splitlines()
    for number, line in enumerate(lines, 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except ValueError:
            problems.append(f"line {number}: not JSON")
            previous = sha(line)
            continue
        chain_ok = row.get("prev") == previous
        mac_ok = key is not None and hmac.compare_digest(
            str(row.get("mac", "")), sign(key, row))
        if not chain_ok:
            problems.append(f"line {number}: hash chain broken")
        if not mac_ok:
            problems.append(f"line {number}: bad or unverifiable MAC")
        if chain_ok and mac_ok:
            rows.append(row)
        previous = sha(line)
    return rows, problems


def load_index(root: Path, work_item: str) -> list[dict]:
    path = root / work_item / "dialogue" / "decisions.json"
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except ValueError:
        return []
    items = data.get("decisions", data) if isinstance(data, dict) else data
    return [d for d in items if isinstance(d, dict) and "id" in d]


def evaluate(root: Path, work_item: str, requested: list[str]) -> tuple[dict, int]:
    rows, problems = read_ledger(root)
    agreed: dict[str, list[dict]] = {}
    for row in rows:
        if row.get("work_item") == work_item:
            for decision in row.get("decision_ids", []):
                agreed.setdefault(decision, []).append(row)
    index = load_index(root, work_item)
    if not requested:
        requested = [d["id"] for d in index]
    violations = []
    for decision in index:
        ident = decision["id"]
        if decision.get("door") != "one-way" or ident not in requested:
            continue
        rows_for = agreed.get(ident, [])
        if rows_for and not any(r.get("decision_ids") == [ident] for r in rows_for):
            violations.append(f"{ident}: one-way door needs a single-id agreement")
    missing = [d for d in requested if d not in agreed]
    result = {
        "work_item": work_item,
        "requested": requested,
        "agreed": [d for d in requested if d in agreed],
        "all_agreed": sorted(agreed),
        "missing": missing,
        "violations": violations,
        "problems": problems,
    }
    if problems or violations:
        return result, EXIT_TAMPER
    if not requested:
        return result, EXIT_USAGE
    return result, (EXIT_MISSING if missing else EXIT_OK)


# ── hook handling ───────────────────────────────────────────────────────────


def pick(data: dict, *keys):
    for key in keys:
        if key in data and data[key] is not None:
            return data[key]
    return None


def normalize(data: dict) -> dict:
    tool_input = pick(data, "tool_input", "toolArgs", "args")
    if isinstance(tool_input, str):
        try:
            tool_input = json.loads(tool_input)
        except ValueError:
            pass
    response = pick(data, "tool_response", "toolResult", "tool_result", "output")
    if isinstance(response, str):
        try:
            response = json.loads(response)
        except ValueError:
            pass
    return {
        "tool": str(pick(data, "tool_name", "toolName", "tool") or ""),
        "input": tool_input,
        "response": response,
        "prompt": pick(data, "prompt"),
        "cwd": str(pick(data, "cwd") or os.getcwd()),
        "session": str(pick(data, "session_id", "sessionId", "sessionID") or ""),
    }


def deny_output(host: str, reason: str) -> str:
    full = f"private-ai-harness dialogue-consent guard: {reason}"
    if host in ("claude", "codex"):
        return json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": full,
        }})
    return json.dumps({"permissionDecision": "deny", "permissionDecisionReason": full})


def command_text(tool_input) -> str:
    if isinstance(tool_input, dict):
        for key in ("command", "cmd"):
            if isinstance(tool_input.get(key), str):
                return tool_input[key]
    return ""


def guard(host: str, event: dict) -> str:
    if os.environ.get("PRIVATE_AI_HARNESS_CONSENT_GUARD", "").lower() == "off":
        return ""
    tool = event["tool"]
    blob = event["input"] if isinstance(event["input"], str) else json.dumps(
        event["input"], default=str)
    if tool not in TOKEN_EXEMPT_TOOLS and GUARD_TOKEN_RE.search(blob):
        return deny_output(host, "the agreement token may appear only as an "
                           "option in the host ask-user tool; agreement must "
                           "come from the human, never from a tool call")
    if not any(marker in blob for marker in PROTECTED):
        return ""
    command = command_text(event["input"])
    if command and (SAFE_CLI_RE.match(command) or SAFE_GIT_RE.match(command)):
        return ""
    return deny_output(host, "this call touches the consent ledger, its key, or "
                       "the hook wiring; read state only via the script's "
                       "status/check subcommands. A human can disable the guard "
                       "for maintenance with PRIVATE_AI_HARNESS_CONSENT_GUARD=off")


def debug_capture(host: str, event: str, raw: str) -> None:
    if os.environ.get("PRIVATE_AI_HARNESS_CONSENT_DEBUG") != "1":
        return
    path = harness_home() / "consent-debug.jsonl"
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "a", encoding="utf-8") as handle:
        handle.write(json.dumps({"host": host, "event": event, "raw": raw}) + "\n")


def handle_hook(host: str, event_name: str, raw: str) -> str:
    debug_capture(host, event_name, raw)
    data = json.loads(raw) if raw.strip() else {}
    if not isinstance(data, dict):
        return ""
    event = normalize(data)
    if event_name == "guard":
        return guard(host, event)
    root = git_root(Path(event["cwd"]))
    if event_name == "prompt":
        # Claude Code also fires UserPromptSubmit for scheduled tasks,
        # background-subagent reports and cross-session messages, so a typed
        # agreement there could be model-originated. Claude uses the ask tool only.
        if host == "claude" or not isinstance(event["prompt"], str):
            return ""
        ids = ids_from_prompt(event["prompt"])
        append_row(root, host, "prompt", event["session"], ids, event["prompt"])
        return ""
    if event_name == "answer":
        if event["tool"] not in ASK_TOOLS:
            return ""
        ids = ids_from_answer(event["response"], event["input"])
        evidence = event["response"] if isinstance(event["response"], str) else \
            json.dumps(event["response"], sort_keys=True, default=str)
        append_row(root, host, "answer", event["session"], ids, evidence)
    return ""


# ── CLI ─────────────────────────────────────────────────────────────────────


def resolve_work_item(root: Path, value: str | None) -> str | None:
    if not value:
        return active_work_item(root)
    path = Path(value)
    if path.is_absolute():
        try:
            path = path.resolve().relative_to(root)
        except ValueError:
            return None
    return path.as_posix().rstrip("/")


def cmd_activate(args) -> int:
    root = git_root(Path.cwd())
    work_item = resolve_work_item(root, args.work_item)
    if not work_item:
        print(json.dumps({"error": "work item must live inside the git root"}))
        return EXIT_USAGE
    (root / work_item / "dialogue").mkdir(parents=True, exist_ok=True)
    pointer = pointer_path(root)
    pointer.parent.mkdir(parents=True, exist_ok=True)
    pointer.write_text(work_item + "\n", encoding="utf-8")
    print(json.dumps({"active": work_item}))
    return EXIT_OK


def cmd_status(args) -> int:
    root = git_root(Path.cwd())
    work_item = resolve_work_item(root, args.work_item)
    if not work_item:
        print(json.dumps({"error": "no active work item; run activate first"}))
        return EXIT_USAGE
    result, _ = evaluate(root, work_item, [])
    print(json.dumps({
        "work_item": work_item,
        "agreed": result["all_agreed"],
        "pending": result["missing"],
        "violations": result["violations"],
        "problems": result["problems"],
    }, indent=2))
    return EXIT_TAMPER if result["problems"] or result["violations"] else EXIT_OK


def cmd_check(args) -> int:
    root = git_root(Path.cwd())
    work_item = resolve_work_item(root, args.work_item)
    if not work_item:
        print(json.dumps({"error": "no active work item; run activate first"}))
        return EXIT_USAGE
    requested = sorted({d for text in args.ids for d in expand_ids(text)})
    result, code = evaluate(root, work_item, requested)
    print(json.dumps(result, indent=2))
    return code


def cmd_hook(args) -> int:
    try:
        output = handle_hook(args.host, args.event, sys.stdin.read())
        if output:
            print(output)
    except Exception:  # noqa: BLE001 — hooks must never crash (see module doc)
        pass
    return EXIT_OK


def cmd_selftest(_args) -> int:
    failures: list[str] = []
    checks: list[str] = []

    def expect(name: str, condition: bool) -> None:
        checks.append(name)
        if not condition:
            failures.append(name)

    with tempfile.TemporaryDirectory() as tmp:
        os.environ["PRIVATE_AI_HARNESS_HOME"] = str(Path(tmp) / "home")
        os.environ.pop("PRIVATE_AI_HARNESS_CONSENT_GUARD", None)
        root = Path(tmp) / "repo"
        (root / ".git").mkdir(parents=True)
        work_item = ".ai/2026-01-01-demo"
        (root / work_item / "dialogue").mkdir(parents=True)
        pointer_path(root).parent.mkdir(parents=True)
        pointer_path(root).write_text(work_item + "\n", encoding="utf-8")
        (root / work_item / "dialogue" / "decisions.json").write_text(json.dumps(
            {"decisions": [{"id": "D-000", "door": "two-way"},
                           {"id": "D-001", "door": "one-way"},
                           {"id": "D-002", "door": "two-way"}]}), encoding="utf-8")
        agree = TOKEN + " "

        def run(host, event, payload):
            return handle_hook(host, event, json.dumps(payload))

        run("claude", "prompt", {"cwd": str(root), "prompt": agree + "D-000"})
        expect("claude prompt channel ignored", evaluate(root, work_item, ["D-000"])[1] == EXIT_MISSING)

        run("copilot", "prompt", {"cwd": str(root), "sessionId": "s", "prompt": agree + "D-000"})
        expect("copilot typed agreement recorded", evaluate(root, work_item, ["D-000"])[1] == EXIT_OK)

        run("copilot", "prompt", {"cwd": str(root), "prompt": "I " + agree.lower() + "D-002 mostly"})
        expect("prose mention not recorded", evaluate(root, work_item, ["D-002"])[1] == EXIT_MISSING)

        echoed = {"questions": [{"options": [{"label": agree + "D-002"}, {"label": "REVISE D-002"}]}]}
        run("claude", "answer", {"cwd": str(root), "tool_name": "AskUserQuestion", "tool_response": echoed})
        expect("echoed options without answers not recorded", evaluate(root, work_item, ["D-002"])[1] == EXIT_MISSING)

        structured = {"questions": echoed["questions"], "answers": {"D-002 ok?": agree + "D-002"}}
        run("claude", "answer", {"cwd": str(root), "tool_name": "AskUserQuestion", "tool_response": structured})
        expect("structured claude answer recorded", evaluate(root, work_item, ["D-002"])[1] == EXIT_OK)

        run("copilot", "answer", {"cwd": str(root), "toolName": "ask_user",
                                  "toolResult": {"resultType": "success", "textResultForLlm": agree + "D-001..D-002"}})
        result, code = evaluate(root, work_item, ["D-001"])
        expect("ranged agreement on one-way door is a violation", code == EXIT_TAMPER and result["violations"])

        run("copilot", "answer", {"cwd": str(root), "toolName": "ask_user",
                                  "toolResult": {"resultType": "success", "textResultForLlm": agree + "D-001"}})
        expect("single-id agreement satisfies one-way door", evaluate(root, work_item, [])[1] == EXIT_OK)
        expect("all_agreed lists every agreed id", evaluate(root, work_item, ["D-000"])[0]["all_agreed"] == ["D-000", "D-001", "D-002"])

        before = ledger_path(root).read_text(encoding="utf-8")
        run("copilot", "answer", {"cwd": str(root), "toolName": "ask_user",
                                  "toolResult": {"resultType": "success", "textResultForLlm": agree + "D-001"}})
        expect("duplicate evidence deduplicated", ledger_path(root).read_text(encoding="utf-8") == before)

        run("copilot", "answer", {"cwd": str(root), "toolName": "bash",
                                  "toolResult": {"textResultForLlm": agree + "D-009"}})
        expect("non-ask tool output ignored", evaluate(root, work_item, ["D-009"])[1] == EXIT_MISSING)

        bash = {"cwd": str(root), "toolName": "bash"}
        expect("token in bash denied", '"deny"' in run("copilot", "guard", dict(bash, toolArgs={"command": "echo " + agree + "D-003"})))
        expect("token in ask tool allowed", run("claude", "guard", {"cwd": str(root), "tool_name": "AskUserQuestion",
                                                                     "tool_input": {"questions": [{"options": [{"label": agree + "D-003"}]}]}}) == "")
        expect("ledger write denied", '"deny"' in run("claude", "guard", {"cwd": str(root), "tool_name": "Bash",
                                                                          "tool_input": {"command": "echo x >> .ai/dialogue/consent.jsonl"}}))
        expect("status call allowed", run("codex", "guard", {"cwd": str(root), "tool_name": "Bash",
                                                              "tool_input": {"command": "python3 /x/scripts/dialogue-consent.py status"}}) == "")
        expect("chained status call denied", '"deny"' in run("codex", "guard", {"cwd": str(root), "tool_name": "Bash",
                                                                                "tool_input": {"command": "python3 /x/dialogue-consent.py status; rm consent.key"}}))
        expect("unrelated write allowed", run("claude", "guard", {"cwd": str(root), "tool_name": "Write",
                                                                   "tool_input": {"file_path": "src/a.py", "content": "x = 1"}}) == "")
        os.environ["PRIVATE_AI_HARNESS_CONSENT_GUARD"] = "off"
        expect("human override disables guard", run("copilot", "guard", dict(bash, toolArgs={"command": "cat consent.key"})) == "")
        os.environ.pop("PRIVATE_AI_HARNESS_CONSENT_GUARD")
        expect("malformed payload is silent", handle_hook("copilot", "guard", "[1,2]") == "")

        lines = ledger_path(root).read_text(encoding="utf-8").splitlines()
        forged = json.loads(lines[-1])
        forged["decision_ids"] = ["D-099"]
        ledger_path(root).write_text("\n".join(lines[:-1] + [json.dumps(forged)]) + "\n", encoding="utf-8")
        expect("tampered row detected", evaluate(root, work_item, ["D-000"])[1] == EXIT_TAMPER)

    if failures:
        print(json.dumps({"selftest": "FAIL", "failed": failures}, indent=2))
        return 1
    print(json.dumps({"selftest": "PASS", "checks": len(checks)}))
    return EXIT_OK


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    hook = sub.add_parser("hook", help="host hook entry point (reads JSON on stdin)")
    hook.add_argument("--host", required=True, choices=["claude", "copilot", "codex", "opencode"])
    hook.add_argument("--event", required=True, choices=["prompt", "answer", "guard"])
    hook.set_defaults(func=cmd_hook)
    activate = sub.add_parser("activate", help="point the ledger at a work item")
    activate.add_argument("--work-item", required=True)
    activate.set_defaults(func=cmd_activate)
    status = sub.add_parser("status", help="agreed and pending decisions")
    status.add_argument("--work-item")
    status.set_defaults(func=cmd_status)
    check = sub.add_parser("check", help="exit 0 only if every id is agreed")
    check.add_argument("--work-item")
    check.add_argument("ids", nargs="*", help="D-NNN, ranges D-001..D-004, or empty for all cards")
    check.set_defaults(func=cmd_check)
    selftest = sub.add_parser("selftest", help="run built-in checks in a temp dir")
    selftest.set_defaults(func=cmd_selftest)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
