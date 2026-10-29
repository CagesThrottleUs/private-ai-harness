#!/usr/bin/env python3
"""Apply the Senior Dialogue (5.0.0) text patches to existing repo files.

Each patch is anchored on a line prefix or an exact string that must match
exactly once. Patches are idempotent: if the new text is already present, the
patch is skipped. A group is applied all-or-nothing: every patch in the group
is computed in memory first; if any anchor fails, nothing is written.

Usage (from the repo root):
  python3 .ai/plans/2026-10-22-senior-dialogue/tools/apply_patches.py --group agent  [--check]
  python3 .ai/plans/2026-10-22-senior-dialogue/tools/apply_patches.py --group skill  [--check]
  python3 .ai/plans/2026-10-22-senior-dialogue/tools/apply_patches.py --group hooks  [--check]
  python3 .ai/plans/2026-10-22-senior-dialogue/tools/apply_patches.py --group engineer [--check]

Groups map one-to-one to commits C2, C3, C4, C5 in PLAN.md and must be applied
in that order.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# ── patch primitives ────────────────────────────────────────────────────────


def _one_line(text: str, prefix: str, path: str) -> int:
    lines = text.split("\n")
    hits = [i for i, line in enumerate(lines) if line.startswith(prefix)]
    if len(hits) != 1:
        raise SystemExit(f"{path}: line prefix matched {len(hits)}x: {prefix[:70]!r}")
    return hits[0]


def insert_after(prefix: str, new: str):
    def apply(text: str, path: str) -> str:
        if new.strip() in text:
            return text
        lines = text.split("\n")
        i = _one_line(text, prefix, path)
        return "\n".join(lines[: i + 1] + new.split("\n") + lines[i + 1:])
    return apply


def insert_before(prefix: str, new: str):
    def apply(text: str, path: str) -> str:
        if new.strip() in text:
            return text
        lines = text.split("\n")
        i = _one_line(text, prefix, path)
        return "\n".join(lines[:i] + new.split("\n") + lines[i:])
    return apply


def replace_line(prefix: str, new: str):
    def apply(text: str, path: str) -> str:
        if new in text:
            return text
        lines = text.split("\n")
        i = _one_line(text, prefix, path)
        lines[i] = new
        return "\n".join(lines)
    return apply


def replace_exact(old: str, new: str):
    def apply(text: str, path: str) -> str:
        if new in text:
            return text
        if text.count(old) != 1:
            raise SystemExit(f"{path}: exact text matched {text.count(old)}x: {old[:70]!r}")
        return text.replace(old, new)
    return apply


# ── group: agent (commit C2) ────────────────────────────────────────────────

AGENT = {
    "AGENTS.md": [
        insert_after(
            "| `delivery-metrics-reviewer` | **sonnet** |",
            "| `test-scenario-reviewer` | opus | Pre-code test-scenario gate — validates the REQ→TC matrix before any test or production code exists: traceability (every REQ/AC covered, no orphans), honesty (each TC names the wrong implementation it kills), level fit (unit/integration/contract/e2e/property/fuzz/simulation/perf/chaos/a11y/visual/security), MC/DC on Critical-tier decision logic, boundaries and error paths, determinism, C/C++ UB/ABI and web-frontend hazards; splits findings into mechanical vs substantive so substantive ones return to the human as decision cards. Invoked by `senior-dialogue` topic (h). |",
        ),
        insert_after(
            "Delivery-metrics agents (`delivery-metrics-reviewer`)",
            "Test-scenario agents (`test-scenario-reviewer`) require `SCENARIOS_PATH` and `SPEC_PATH`; `LLD_PATH` and `ITERATION` (`k/N`) optional.",
        ),
        insert_after(
            "| `delivery-metrics-reviewer` | sonnet |",
            "| `test-scenario-reviewer` | opus | High — \"would a subtly wrong implementation pass this scenario?\" and \"is this the cheapest level that can observe the behavior?\" are judgment calls, as are MC/DC independence on real decision logic and spotting failure modes the spec implies but never states; a checklist-matcher would pass vague oracles | ✅ Correct |",
        ),
    ],
    "README.md": [
        insert_after(
            "| `delivery-metrics-reviewer` |",
            "| `test-scenario-reviewer` | Pre-code test-scenario gate — REQ→TC traceability, honest kills, level fit, MC/DC on Critical-tier logic, determinism, C/C++ and web hazards; feeds the Senior Dialogue's test-scenario loop |",
        ),
    ],
    "skills/review/SKILL.md": [
        insert_after(
            "| `load-test-reviewer` | Performance test scripts |",
            "| `test-scenario-reviewer` | Test-scenario matrix and spec | Before any test code — REQ→TC traceability, honest kills, level fit, MC/DC, determinism |",
        ),
    ],
}

# ── group: skill (commit C3) ────────────────────────────────────────────────

SKILL = {
    "AGENTS.md": [
        insert_after(
            "| `engineer` | `/engineer` |",
            "| `senior-dialogue` | via `/engineer` | The Senior Dialogue working model behind every `/engineer` lane — understand → discuss → explicit human agreement recorded by host hooks in a signed consent ledger → documentation generated from the agreed record → test-first build with zero check-ins. Feynman-style decision cards with citations and numbers derived at runtime; agenda ordered by runtime risk reasoning; waits for the human in autopilot/allow-all and parks instead of self-agreeing; test-scenario loop with `test-scenario-reviewer` to sync or a human-set cap N; C23 / C++23/26 and web-frontend depth in `references/` |",
        ),
    ],
    "README.md": [
        insert_after(
            "| `teacher` | `/teacher` |",
            "| `senior-dialogue` | via `/engineer` | Senior Dialogue working model — evidence-backed Feynman decision cards, runtime risk reasoning for depth, human agreement recorded by host hooks in a signed consent ledger (autopilot is not consent; no human → park), docs generated from the agreed record, test scenarios agreed before code |",
        ),
    ],
    "CLAUDE.md": [
        insert_after(
            "- Do not nest skills inside other skill directories",
            "- **Teach reasoning, don't hardcode it.** A skill explains how to think about\n"
            "  its job and how to iterate with the human; it does not hand the model fixed\n"
            "  numbers, thresholds, word counts, or step counts to apply mechanically.\n"
            "  Estimates, thresholds, and depth are derived at runtime for the case at\n"
            "  hand, with the reasoning shown. Hardcode only what is intrinsic to the\n"
            "  skill — a security mechanism (the consent ledger), a host or API limit, a\n"
            "  standard's own definition (MC/DC, Core Web Vitals), or a format another\n"
            "  tool parses. Worked numbers belong in clearly labeled examples, never in\n"
            "  rules.\n"
            "- **SKILL.md stays under 20,000 bytes.** Claude Code truncates re-attached\n"
            "  skills after compaction. Move detail into `references/` and point to it\n"
            "  from the step that needs it.",
        ),
    ],
    "PHILOSOPHY.md": [
        insert_before(
            "## The Measure of Success",
            "## Ownership Through Dialogue\n"
            "\n"
            "Most code is now written by an agent and rarely read line by line. That moves\n"
            "ownership: you own a system when you can explain every decision that shaped\n"
            "it — why this boundary, why this data structure, what fails first and how we\n"
            "would know. The harness therefore treats the human and the agent as two senior\n"
            "engineers. The agent brings evidence, numbers, and options; the human brings\n"
            "intent, context, and judgment. They discuss until the human explicitly agrees\n"
            "and could re-explain the decision to a third engineer; only then is the\n"
            "agreement documented and built, test-first.\n"
            "\n"
            "This is not a detour from \"time from intent to done\": an unexamined decision\n"
            "is the most expensive rework there is. Two consequences follow:\n"
            "\n"
            "- **Agreement is a recorded human act, not a model inference.** Autopilot or\n"
            "  allow-all permissions speed up execution; they never stand in for consent to\n"
            "  a design decision. When no human is present, the agent stops with one clear\n"
            "  question instead of guessing.\n"
            "- **Skills teach reasoning, not recipes.** A skill explains how to think about\n"
            "  its job and how to iterate with the human. Numbers, thresholds, and depth are\n"
            "  derived for the case at hand and shown with their basis, so the human can\n"
            "  challenge an input instead of accepting a constant.\n",
        ),
        insert_before(
            "1. **Write the spec**",
            "0. **Discuss to agreement** — understand the problem, discuss each decision with evidence and numbers, and record the human's explicit agreement.",
        ),
    ],
}

# ── group: hooks (commit C4) ────────────────────────────────────────────────

COPILOT_HOOKS = '''
# Senior Dialogue consent ledger (skills/senior-dialogue): record human
# agreement from typed prompts and ask_user answers; guard the ledger.
consent_script = f"{repo_root}/skills/senior-dialogue/scripts/dialogue-consent.py"

def ensure_consent_hook(event_key: str, consent_event: str) -> None:
    entries = hooks.setdefault(event_key, [])
    bash_cmd = (f'python3 "{consent_script}" hook --host copilot '
                f'--event {consent_event} 2>/dev/null || true')
    if not any(e.get("bash") == bash_cmd for e in entries):
        entries.append({"type": "command", "bash": bash_cmd, "timeoutSec": 10})

ensure_consent_hook("userPromptSubmitted", "prompt")
ensure_consent_hook("postToolUse", "answer")
ensure_consent_hook("preToolUse", "guard")'''

AGENTS_CONSENT_SECTION = """## Senior Dialogue consent model

`/engineer` runs every lane through `senior-dialogue`: DISCUSS waits for the
human at each decision card; BUILD runs with zero check-ins once every card is
agreed. Agreement is recorded only by host hooks from human input, never by the
model, into `<git-root>/.ai/dialogue/consent.jsonl` (hash-chained, HMAC-signed
with `~/.private-ai-harness/consent.key`). A PreToolUse guard denies tool calls
that touch the ledger, the key, or the hook wiring, or that carry the agreement
token outside the ask-user tool. Script:
`skills/senior-dialogue/scripts/dialogue-consent.py`.

| Host | Agreement channel | Wiring |
|------|-------------------|--------|
| Claude Code | `AskUserQuestion` answers only (its `UserPromptSubmit` also fires for model-originated turns) | `hooks/dialogue-consent.json` via `.claude-plugin/plugin.json` |
| Copilot CLI | `ask_user` answers + typed first-line agreement | `~/.copilot/hooks/private-ai-harness.json` (installer) |
| Codex | `request_user_input` answers + typed first-line agreement | `hooks/codex-dialogue-consent.json` via `.codex-plugin/plugin.json` (trust it in `/hooks`) |
| opencode | `question` answers + typed first-line agreement | `~/.config/opencode/plugin/private-ai-harness-dialogue-consent.js` (installer) |

With no human present the agent parks with one question; it never fabricates
agreement. Editing the guarded files needs the host launched with
`PRIVATE_AI_HARNESS_CONSENT_GUARD=off` (only a human can set the hook
environment).

---
"""

CLAUDE_CONSENT_SECTION = """## Senior Dialogue consent ledger

`/engineer` waits for the human during discussion and records agreement only
through host hooks (see `AGENTS.md` → *Senior Dialogue consent model*). When
working on this repo with the plugin installed:

- The guard blocks edits to the consent script, the hook wiring, and any tool
  input containing the agreement token followed by a decision id. Launch the
  host with `PRIVATE_AI_HARNESS_CONSENT_GUARD=off` for that maintenance.
- In docs and examples, write the token as `AGREE D-<NNN>`, never with a real
  id; in code, build it at runtime (see the script's `TOKEN`).
- After changing the script, run its `selftest` subcommand.

---
"""

README_HOOKS = """
**Senior Dialogue consent hooks.** `/engineer` records a human's agreement to
each decision card through host hooks, never through the model:
`skills/senior-dialogue/scripts/dialogue-consent.py` appends to a hash-chained,
HMAC-signed ledger at `<git-root>/.ai/dialogue/consent.jsonl`, and a
`PreToolUse` guard denies tool calls that touch the ledger, its key, or the hook
wiring. Claude Code loads `hooks/dialogue-consent.json` from the plugin
manifest; Codex loads `hooks/codex-dialogue-consent.json` (trust it in
`/hooks`); the Copilot and opencode installers wire their equivalents. To edit
the guarded files, launch the host with `PRIVATE_AI_HARNESS_CONSENT_GUARD=off`.
Set `PRIVATE_AI_HARNESS_CONSENT_DEBUG=1` to capture raw hook payloads in
`~/.private-ai-harness/consent-debug.jsonl`."""

HOOKS = {
    ".claude-plugin/plugin.json": [
        replace_exact(
            '    "./hooks/permission-request.json"\n  ]',
            '    "./hooks/permission-request.json",\n    "./hooks/dialogue-consent.json"\n  ]',
        ),
    ],
    ".codex-plugin/plugin.json": [
        replace_exact(
            '  "skills": "./skills/",\n',
            '  "skills": "./skills/",\n  "hooks": "./hooks/codex-dialogue-consent.json",\n',
        ),
    ],
    "scripts/install-copilot.sh": [
        insert_after('ensure_hook("preCompact", "PreCompact")', COPILOT_HOOKS),
        insert_after(
            'ok "sound hooks wired into $GLOBAL_HOOKS_FILE',
            'ok "Senior Dialogue consent hooks wired into $GLOBAL_HOOKS_FILE (userPromptSubmitted/postToolUse/preToolUse)"',
        ),
        insert_after(
            "  agent and Copilot CLI read it natively",
            "- Senior Dialogue: `/engineer` discussion phases wait for the human even in\n"
            "  autopilot or allow-all; those permissions are not consent. Agreement is\n"
            "  recorded only by the consent hooks from an `ask_user` answer or a typed\n"
            "  message whose first line is the agreement. With no human present, park\n"
            "  with one question and never self-agree.",
        ),
    ],
    "scripts/install-codex.sh": [
        insert_after(
            "- Read `private-ai-harness:using-superpowers` for Codex tool",
            "- Senior Dialogue: `/engineer` discussion phases wait for the human even with approvals bypassed; agreement is recorded only by the plugin's consent hooks from a `request_user_input` answer or a typed message whose first line is the agreement. With no human present, park with one question and never self-agree.",
        ),
        insert_after(
            'echo "Use /agent to inspect harness reviewer agents."',
            'echo "Open /hooks and trust the private-ai-harness hooks: the Senior Dialogue consent ledger is skipped until they are trusted."',
        ),
    ],
    "scripts/install-opencode.sh": [
        insert_after(
            'info "baked in — do not move',
            'sed "s#__CONSENT_SCRIPT_PATH__#$REPO_ROOT/skills/senior-dialogue/scripts/dialogue-consent.py#" \\\n'
            '  "$REPO_ROOT/scripts/opencode-dialogue-consent-plugin.js" \\\n'
            '  > "$GLOBAL_PLUGIN_DIR/private-ai-harness-dialogue-consent.js"\n'
            'ok "Senior Dialogue consent plugin installed → $GLOBAL_PLUGIN_DIR/private-ai-harness-dialogue-consent.js"',
        ),
        insert_after(
            "the brief.",
            "\n"
            "Senior Dialogue: `/engineer` discussion phases wait for the human even when\n"
            "permissions are set to allow; agreement is recorded only by the consent plugin\n"
            "from a `question` answer or a typed message whose first line is the agreement.\n"
            "With no human present, park with one question and never self-agree.",
        ),
    ],
    "AGENTS.md": [
        replace_line(
            "| `hooks/*.json` |",
            "| `hooks/*.json` | Claude Code hook manifests: sound feedback via `scripts/hook-beep.sh`, and `dialogue-consent.json` (Senior Dialogue consent ledger). `codex-dialogue-consent.json` is the Codex equivalent, loaded through `.codex-plugin/plugin.json`'s `hooks` key; Claude does not load it |",
        ),
        insert_after(
            "| `scripts/opencode-notify-plugin.js` |",
            "| `scripts/opencode-dialogue-consent-plugin.js` | opencode plugin copied into `plugin/` by `install-opencode.sh`: bridges `chat.message` and `tool.execute.before`/`after` to the Senior Dialogue consent script (typed agreement, `question` answers, guard) |",
        ),
        insert_after(
            "| `skills/<name>/scripts/` |",
            "| `skills/senior-dialogue/scripts/dialogue-consent.py` | Senior Dialogue consent ledger (stdlib Python): host hook entry point (`hook --host … --event prompt`/`answer`/`guard`) plus `activate`/`status`/`check`/`selftest`; ledger `<git-root>/.ai/dialogue/consent.jsonl`, hash-chained and HMAC-signed |",
        ),
        insert_before("## External skills loaded at install time", AGENTS_CONSENT_SECTION),
    ],
    "README.md": [
        insert_after("- Disable: create `~/.private-ai-harness/beep-disabled`", README_HOOKS),
        insert_after(
            "- **Autopilot default**",
            "- **Senior Dialogue consent hooks** — adds `userPromptSubmitted`, `postToolUse`, and `preToolUse` entries to `~/.copilot/hooks/private-ai-harness.json`. Autopilot speeds up execution but is not consent: `/engineer` still waits for an `ask_user` answer or a typed agreement before building, and parks when nobody answers.",
        ),
    ],
    "CLAUDE.md": [
        insert_after(
            "scripts/commit-msg.sh       conventional",
            "skills/senior-dialogue/scripts/dialogue-consent.py  Senior Dialogue consent ledger + hook entry point\n"
            "hooks/dialogue-consent.json Claude consent hooks (codex-dialogue-consent.json: Codex)\n"
            "scripts/opencode-dialogue-consent-plugin.js  opencode consent bridge (copied by installer)",
        ),
        insert_before("## Metrics vocabulary", CLAUDE_CONSENT_SECTION),
        insert_after(
            "- Don't modify `scripts/commit-msg.sh`",
            "- Don't write the agreement token followed by a real decision id into any repo file; the consent guard treats it as attempted self-agreement",
        ),
    ],
}

# ── group: engineer (commit C5) ─────────────────────────────────────────────

ENGINEER = {
    "skills/brainstorming/SKILL.md": [
        insert_after(
            "**User Review Gate:**",
            "*Senior Dialogue:* inside `/engineer` (the work item has\n"
            "`dialogue/decisions.json`), the spec is generated from agreed decision cards\n"
            "and this review is already satisfied by a passing consent `check`; skip the ask\n"
            "and continue.\n",
        ),
    ],
    "skills/high-level-design/SKILL.md": [
        insert_after(
            "Do NOT invoke writing-plans until the human explicitly approves the HLD",
            "\n"
            "*Senior Dialogue:* inside `/engineer`, the HLD is generated after the human\n"
            "agreed its decision cards (topic c). That agreement, verified by a passing\n"
            "consent `check` on the cards the HLD cites, is the approval — do not re-present\n"
            "the document. A reviewer finding that would change an agreed decision opens\n"
            "one new card instead.",
        ),
    ],
    "skills/business-context-intake/SKILL.md": [
        insert_before(
            "After human approves the document:",
            "*Senior Dialogue:* inside `/engineer`, this interview happens as topic (b)\n"
            "decision cards and the document is generated from the agreed cards; a passing\n"
            "consent `check` on them is the approval.\n",
        ),
    ],
    "skills/writing-plans/SKILL.md": [
        insert_before(
            "After plan-reviewer passes, offer execution choice:",
            "*Senior Dialogue:* inside `/engineer` BUILD, do not ask — the human already\n"
            "agreed the build; use Subagent-Driven execution. Every task's test steps cite\n"
            "TC ids from the agreed test-scenario matrix.\n",
        ),
    ],
    "skills/test-driven-development/SKILL.md": [
        insert_after(
            "Write one minimal test showing what should happen.",
            "\n"
            "Inside `/engineer`, each RED test implements one TC from the agreed\n"
            "test-scenario matrix: carry the TC id and `@validates_req REQ-NNN`, and make it\n"
            "fail for the reason in the TC's Kills column.",
        ),
    ],
    "AGENTS.md": [
        replace_line(
            "| `engineer` | `/engineer` |",
            "| `engineer` | `/engineer` | **Universal entry point** — classifies the request into a lane (quick-fix/task/epic/portfolio/research/refactoring), opens the Senior Dialogue with card D-000 (lane, depth, risk-ordered agenda with runtime reasoning, skill chain, test-scenario cap N, doc targets), waits for ledger-recorded human agreement even in autopilot/allow-all, then runs the lane's BUILD phase with zero check-ins; `/engineer resume .ai/<id>` re-enters a parked work item; cost and review-discipline detail in `references/` |",
        ),
    ],
    "README.md": [
        insert_after(
            "| `teacher` | `/teacher` |",
            "| `engineer` | `/engineer` | Universal entry point — classifies the request into a lane, opens the Senior Dialogue (card D-000), waits for recorded human agreement during DISCUSS, then runs the lane's BUILD chain with zero check-ins |",
        ),
    ],
    "docs/engineer-skill-map.md": [
        insert_after(
            "Every skill below",
            "\n"
            "**5.0.0 — Senior Dialogue.** Every lane now opens with `senior-dialogue`: card\n"
            "D-000, then a DISCUSS phase that waits for ledger-recorded human agreement,\n"
            "then a BUILD phase with zero check-ins. The lane chains below are the BUILD\n"
            "chains; DISCUSS uses `codebase-comprehension`, `brainstorming`'s conversation\n"
            "practices, `business-context-intake`'s territory, `high-level-design`'s\n"
            "analyses, and `test-scenario-reviewer`.",
        ),
    ],
    ".claude-plugin/plugin.json": [replace_exact('"version": "4.1.1"', '"version": "5.0.0"')],
    ".claude-plugin/marketplace.json": [replace_exact('"version": "4.1.1"', '"version": "5.0.0"')],
    ".codex-plugin/plugin.json": [replace_exact('"version": "4.1.1"', '"version": "5.0.0"')],
}

GROUPS = {"agent": AGENT, "skill": SKILL, "hooks": HOOKS, "engineer": ENGINEER}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--group", required=True, choices=sorted(GROUPS))
    parser.add_argument("--check", action="store_true", help="validate anchors only")
    args = parser.parse_args()
    results: dict[str, str] = {}
    for path, patches in GROUPS[args.group].items():
        text = Path(path).read_text(encoding="utf-8")
        original = text
        for patch in patches:
            text = patch(text, path)
        if text != original:
            results[path] = text
        print(f"{'would patch' if args.check else 'patched'} {path}"
              f"{'' if text != original else ' (already applied)'}")
    if not args.check:
        for path, text in results.items():
            Path(path).write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
