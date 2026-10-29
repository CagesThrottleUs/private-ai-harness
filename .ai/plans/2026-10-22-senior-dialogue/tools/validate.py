#!/usr/bin/env python3
"""Acceptance checks for the Senior Dialogue (5.0.0) change.

Usage (from the repo root):
  python3 .ai/plans/2026-10-22-senior-dialogue/tools/validate.py --quick   # after each step
  python3 .ai/plans/2026-10-22-senior-dialogue/tools/validate.py --final   # after C5

--quick runs the checks that hold at every intermediate commit. --final runs
everything and requires the full change to be present. Exit 0 only if every
check passes. Pre-existing oversize skills outside this change are reported
as WARN, not FAIL.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path.cwd()
PLAN = ROOT / ".ai/plans/2026-10-22-senior-dialogue"
SCRIPT = ROOT / "skills/senior-dialogue/scripts/dialogue-consent.py"
TOKEN = "AG" + "REE"
TOKEN_RE = re.compile(rf"(?i)\b{TOKEN}\s+d-\d")
LIMIT = 20000
TOUCHED_SKILLS = ["engineer", "senior-dialogue", "high-level-design", "brainstorming", "review",
                  "business-context-intake", "writing-plans", "test-driven-development"]
PREEXISTING_OVERSIZE = {"design-principles", "emil-design-eng", "e2e-testing",
                        "observability-standards", "api-contract-first"}
REQUIRED_SKILLS = [
    "brainstorming", "business-context-intake", "high-level-design", "writing-plans",
    "spec-quality-gate", "test-driven-development", "ci-pipeline-setup", "deployment-workflow",
    "observability-standards", "teacher", "codebase-comprehension", "systematic-debugging",
    "verification-before-completion", "commit-discipline", "using-git-worktrees",
    "subagent-driven-development", "formal-verification", "requesting-code-review", "pr-creator",
    "finishing-a-development-branch", "portfolio-management", "delivery-metrics", "outcome-review",
    "epic-decomposition", "service-scaffolding", "incident-response", "production-readiness-review",
    "onboarding-guide", "research-spike", "refactoring", "karpathy", "design-principles",
    "pr-review-non-negotiables", "domain-overlay", "android-advisor", "using-superpowers",
    "property-based-testing", "deterministic-simulation-testing", "integration-testing",
    "e2e-testing", "load-testing", "chaos-engineering", "visual-regression", "dast-testing",
    "feature-flags", "api-contract-first", "api-versioning", "database-erd", "sequence-diagram",
    "github-workflows", "senior-dialogue",
]
PATH_PREFIXES = ("references/", "scripts/", "skills/", "agents/", "hooks/", ".claude-plugin/",
                 ".codex-plugin/", "docs/")

results: list[tuple[str, str, str]] = []
FINAL = False


def record(status: str, name: str, detail: str = "") -> None:
    results.append((status, name, detail))


def check(name: str, ok: bool, detail: str = "") -> None:
    record("PASS" if ok else "FAIL", name, detail)


def run(cmd, **kw) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


# ── checks ──────────────────────────────────────────────────────────────────


def skill_sizes() -> None:
    for path in sorted(ROOT.glob("skills/*/SKILL.md")):
        name, size = path.parent.name, path.stat().st_size
        if size < LIMIT:
            continue
        if name == "engineer" and "senior-dialogue" not in path.read_text(encoding="utf-8") \
                and not FINAL:
            record("WARN", f"size {name}", f"{size} bytes (replaced in step C5)")
        elif name in TOUCHED_SKILLS:
            check(f"size {name}", False, f"{size} bytes >= {LIMIT}")
        elif name in PREEXISTING_OVERSIZE:
            record("WARN", f"size {name}", f"{size} bytes (pre-existing, out of scope)")
        else:
            check(f"size {name}", False, f"{size} bytes >= {LIMIT} (new oversize)")
    for name in TOUCHED_SKILLS:
        path = ROOT / "skills" / name / "SKILL.md"
        if path.exists() and path.stat().st_size < LIMIT:
            check(f"size {name}", True, f"{path.stat().st_size} bytes")


def resolve(token: str, md: Path) -> bool:
    skill_dir = next((p for p in md.parents if p.parent.name == "skills"), None)
    candidates = [md.parent / token, ROOT / token]
    if skill_dir:
        candidates.append(skill_dir / token)
    candidates.extend((ROOT / "skills").glob(f"*/{token}"))
    return any(c.exists() for c in candidates)


def links() -> None:
    files: list[Path] = []
    for name in TOUCHED_SKILLS:
        files.extend(sorted((ROOT / "skills" / name).rglob("*.md")))
    agent = ROOT / "agents/test-scenario-reviewer.md"
    if agent.exists():
        files.append(agent)
    broken = []
    for md in files:
        for token in re.findall(r"`([^`\s]+)`", md.read_text(encoding="utf-8")):
            if not token.startswith(PATH_PREFIXES) or re.search(r"[<>*…]|YYYY|NNN", token):
                continue
            if not resolve(token.rstrip("/.,"), md):
                broken.append(f"{md.relative_to(ROOT)} → {token}")
    check("relative links in touched skills", not broken, "; ".join(broken[:10]))


def skill_names() -> None:
    missing = [s for s in REQUIRED_SKILLS if not (ROOT / "skills" / s / "SKILL.md").exists()]
    check("skills referenced by engineer/senior-dialogue exist", not missing, ", ".join(missing))


def token_scan() -> None:
    hits = []
    for path in ROOT.rglob("*"):
        rel = path.relative_to(ROOT).as_posix()
        if not path.is_file() or rel.startswith((".git/", ".tokensave/")) or "/__pycache__/" in f"/{rel}":
            continue
        if rel.endswith("consent.jsonl"):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        if TOKEN_RE.search(text):
            hits.append(rel)
    check("no literal agreement token with a real id in repo files", not hits, ", ".join(hits[:10]))


def json_files() -> None:
    bad = []
    for path in [*ROOT.glob("hooks/*.json"), ROOT / ".claude-plugin/plugin.json",
                 ROOT / ".claude-plugin/marketplace.json", ROOT / ".codex-plugin/plugin.json"]:
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except ValueError as exc:
            bad.append(f"{path.name}: {exc}")
    check("JSON files parse", not bad, "; ".join(bad))


def consent_script() -> None:
    if not SCRIPT.exists():
        record("SKIP", "consent script", "not present yet")
        return
    check("consent script compiles", run([sys.executable, "-m", "py_compile", str(SCRIPT)]).returncode == 0)
    selftest = run([sys.executable, str(SCRIPT), "selftest"])
    check("consent script selftest", selftest.returncode == 0 and '"PASS"' in selftest.stdout,
          selftest.stdout.strip()[-200:])
    with tempfile.TemporaryDirectory() as tmp:
        env = dict(os.environ, PRIVATE_AI_HARNESS_HOME=str(Path(tmp) / "home"))
        env.pop("PRIVATE_AI_HARNESS_CONSENT_GUARD", None)
        repo = Path(tmp) / "repo"
        repo.mkdir()
        run(["git", "init", "-q"], cwd=repo)
        cli = lambda *a: run([sys.executable, str(SCRIPT), *a], cwd=repo, env=env)  # noqa: E731
        act = cli("activate", "--work-item", ".ai/2026-01-01-x")
        check("cli activate", act.returncode == 0 and (repo / ".ai/dialogue/active").exists(), act.stdout)
        check("cli check pending → exit 3", cli("check", "D-000").returncode == 3)
        payload = json.dumps({"cwd": str(repo), "prompt": TOKEN + " D-000"})
        run([sys.executable, str(SCRIPT), "hook", "--host", "copilot", "--event", "prompt"],
            input=payload, cwd=repo, env=env)
        check("cli check agreed → exit 0", cli("check", "D-000").returncode == 0)
        status = cli("status")
        check("cli status", status.returncode == 0 and "D-000" in status.stdout, status.stdout[-200:])
        ledger = repo / ".ai/dialogue/consent.jsonl"
        ledger.write_text(ledger.read_text().replace("D-000", "D-001"))
        check("cli tamper → exit 4", cli("check", "D-001").returncode == 4)


def hook_commands() -> None:
    specs = [("hooks/dialogue-consent.json", "CLAUDE_PLUGIN_ROOT"),
             ("hooks/codex-dialogue-consent.json", "PLUGIN_ROOT")]
    deny_payload = json.dumps({"cwd": str(ROOT), "tool_name": "Bash",
                               "tool_input": {"command": "echo x >> .ai/dialogue/consent.jsonl"}})
    for path, var in specs:
        file = ROOT / path
        if not file.exists():
            record("SKIP", f"hook commands {path}", "not present yet")
            continue
        data = json.loads(file.read_text(encoding="utf-8"))
        guards = [h["command"] for groups in data["hooks"].get("PreToolUse", [])
                  for h in groups["hooks"]]
        check(f"{path} has a PreToolUse guard", len(guards) == 1)
        if not guards:
            continue
        env = dict(os.environ, **{var: str(ROOT)})
        env.pop("PRIVATE_AI_HARNESS_CONSENT_GUARD", None)
        out = run(["bash", "-c", guards[0]], input=deny_payload, env=env)
        check(f"{path} guard denies ledger write", out.returncode == 0 and '"deny"' in out.stdout,
              out.stdout[-200:] + out.stderr[-200:])
        env_missing = {k: v for k, v in os.environ.items() if k != var}
        out = run(["bash", "-c", guards[0]], input=deny_payload, env=env_missing)
        check(f"{path} guard fails open when plugin root is unset",
              out.returncode == 0 and out.stdout.strip() == "")


def installers() -> None:
    for name in ("install-claude.sh", "install-codex.sh", "install-copilot.sh", "install-opencode.sh"):
        check(f"bash -n scripts/{name}", run(["bash", "-n", str(ROOT / "scripts" / name)]).returncode == 0)
    with tempfile.TemporaryDirectory() as tmp:
        for name in ("install-copilot.sh", "install-codex.sh", "install-opencode.sh"):
            text = (ROOT / "scripts" / name).read_text(encoding="utf-8")
            blocks = re.findall(r"<<'PYEOF'\n(.*?)\nPYEOF", text, flags=re.S)
            blocks = [b for b in blocks if "Senior Dialogue" in b]
            check(f"{name} has Senior Dialogue python blocks", bool(blocks))
            for index, block in enumerate(blocks):
                target = Path(tmp) / f"{name}-{index}.out"
                first = run([sys.executable, "-", str(target), str(ROOT)], input=block)
                second = run([sys.executable, "-", str(target), str(ROOT)], input=block)
                content = target.read_text(encoding="utf-8") if target.exists() else ""
                ok = first.returncode == 0 and second.returncode == 0 and (
                    "Senior Dialogue" in content or "dialogue-consent.py" in content)
                check(f"{name} block {index} runs idempotently", ok, (first.stderr + second.stderr)[-300:])
                if "dialogue-consent.py" in content:
                    data = json.loads(content)
                    count = sum("dialogue-consent.py" in e.get("bash", "")
                                for entries in data["hooks"].values() for e in entries)
                    check(f"{name} wires exactly 3 consent hooks", count == 3, f"found {count}")
        plugin = ROOT / "scripts/opencode-dialogue-consent-plugin.js"
        if plugin.exists():
            rendered = Path(tmp) / "plugin.mjs"
            rendered.write_text(plugin.read_text(encoding="utf-8").replace(
                "__CONSENT_SCRIPT_PATH__", str(SCRIPT)), encoding="utf-8")
            if shutil.which("node"):
                out = run(["node", "--check", str(rendered)])
                check("opencode consent plugin parses (node --check)", out.returncode == 0, out.stderr[-300:])
            else:
                record("WARN", "opencode plugin syntax", "node not installed; skipped")
            install_text = (ROOT / "scripts/install-opencode.sh").read_text(encoding="utf-8")
            check("install-opencode.sh substitutes the consent script path",
                  "__CONSENT_SCRIPT_PATH__" in install_text)


def manifests() -> None:
    versions = {
        ".claude-plugin/plugin.json": json.loads((ROOT / ".claude-plugin/plugin.json").read_text())["version"],
        ".claude-plugin/marketplace.json": json.loads((ROOT / ".claude-plugin/marketplace.json").read_text())["plugins"][0]["version"],
        ".codex-plugin/plugin.json": json.loads((ROOT / ".codex-plugin/plugin.json").read_text())["version"],
    }
    check("manifest versions are 5.0.0", set(versions.values()) == {"5.0.0"}, json.dumps(versions))
    claude_hooks = json.loads((ROOT / ".claude-plugin/plugin.json").read_text())["hooks"]
    check("claude manifest lists dialogue-consent hooks", "./hooks/dialogue-consent.json" in claude_hooks)
    check("all claude manifest hook files exist", all((ROOT / h).exists() for h in claude_hooks))
    codex = json.loads((ROOT / ".codex-plugin/plugin.json").read_text())
    check("codex manifest hooks file exists", (ROOT / codex.get("hooks", "missing")).exists(),
          codex.get("hooks", "no hooks key"))


def adapters() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        for host, extra in (("codex", []), ("opencode", []), ("copilot", ["--agent-dir", f"{tmp}/copilot-agents"])):
            dest = Path(tmp) / host
            out = run([sys.executable, str(ROOT / f"scripts/install-{host}-agents.py"),
                       "--source-dir", str(ROOT / "agents"), "--dest-dir", str(dest), *extra],
                      env=dict(os.environ, HOME=tmp, CODEX_HOME=f"{tmp}/codex",
                               OPENCODE_CONFIG_DIR=f"{tmp}/opencode", COPILOT_HOME=f"{tmp}/copilot"))
            produced = [p for p in Path(tmp).rglob("*") if "test-scenario-reviewer" in p.as_posix()]
            check(f"{host} adapter renders agents into temp HOME", out.returncode == 0,
                  (out.stdout + out.stderr)[-300:])
        check("adapters produced test-scenario-reviewer outputs", len(produced) >= 3,
              f"{len(produced)} paths")


def commit_messages() -> None:
    for path in sorted((PLAN / "tools/commit-messages").glob("C*.txt")):
        out = run(["bash", str(ROOT / "scripts/commit-msg.sh"), str(path)])
        check(f"commit message {path.name} passes commit-msg.sh", out.returncode == 0, out.stdout[-200:])


def doc_sync() -> None:
    agents = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    claude = (ROOT / "CLAUDE.md").read_text(encoding="utf-8")
    review = (ROOT / "skills/review/SKILL.md").read_text(encoding="utf-8")
    check("AGENTS.md lists senior-dialogue", "| `senior-dialogue` |" in agents)
    check("AGENTS.md lists test-scenario-reviewer 3x (table, contract, right-size)",
          agents.count("test-scenario-reviewer") >= 3)
    check("README.md lists engineer, senior-dialogue, test-scenario-reviewer",
          all(f"| `{n}` |" in readme for n in ("engineer", "senior-dialogue", "test-scenario-reviewer")))
    check("CLAUDE.md has the Senior Dialogue section and authoring rule",
          "## Senior Dialogue consent ledger" in claude and "Teach reasoning, don't hardcode it" in claude)
    reviewers = sorted(p.stem for p in (ROOT / "agents").glob("*-reviewer.md"))
    missing_review = [r for r in reviewers if f"| `{r}` |" not in review]
    check("every reviewer agent is in /review's inventory", not missing_review, ", ".join(missing_review))
    missing_rows = [r for r in reviewers if f"| `{r}` | opus |" not in agents and f"| `{r}` | sonnet |" not in agents]
    check("every reviewer agent has a right-sizing row", not missing_rows, ", ".join(missing_rows))


def payload_parity() -> None:
    payloads = PLAN / "payloads"
    drift = [p.relative_to(payloads).as_posix() for p in payloads.rglob("*") if p.is_file()
             and "__pycache__" not in p.parts
             and (not (ROOT / p.relative_to(payloads)).exists()
                  or (ROOT / p.relative_to(payloads)).read_bytes() != p.read_bytes())]
    check("repo files match payloads byte-for-byte", not drift, ", ".join(drift))


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--quick", action="store_true")
    mode.add_argument("--final", action="store_true")
    args = parser.parse_args()
    global FINAL
    FINAL = args.final
    skill_sizes()
    token_scan()
    json_files()
    consent_script()
    hook_commands()
    if args.final:
        links()
        skill_names()
        installers()
        manifests()
        adapters()
        commit_messages()
        doc_sync()
        payload_parity()
    width = max(len(n) for _, n, _ in results)
    for status, name, detail in results:
        print(f"{status:4}  {name:<{width}}  {detail}".rstrip())
    failed = [r for r in results if r[0] == "FAIL"]
    print(f"\n{len(results) - len(failed)} ok/warn/skip, {len(failed)} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
