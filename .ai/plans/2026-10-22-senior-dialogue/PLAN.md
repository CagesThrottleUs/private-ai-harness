# Plan — Senior Dialogue: `/engineer` as the single front door (private-ai-harness 5.0.0)

**Status:** ready to implement · **Base commit:** `f01a3ab` · **Target version:** 5.0.0 (MAJOR)
**Rehearsed:** `tools/rehearse.sh` applies all five commits to a clean clone of
`f01a3ab` and passes `tools/validate.py --final` (64 checks, 0 failures).

---

## 0. For the implementing agent — read this first

You do not need to make any design decision. Every new file is in `payloads/`,
byte-for-byte as it must land. Every edit to an existing file is an anchored,
asserted patch in `tools/apply_patches.py` or a verbatim move in
`tools/split_skills.py`. Your job is to run five steps in order, commit each
with the provided message, and run the final validation.

**Rules:**

1. Work from the repo root on a branch created from `f01a3ab` (or a descendant
   whose files touched below are unchanged; the tools abort if an anchor moved).
2. Never edit a payload, patch, or tool to make a step pass. If any command
   exits non-zero, **stop and report the full output**. Anchor misses mean the
   repo drifted from the base; that needs a human.
3. Do not install, reload, or restart the plugin until all five commits are
   done. Once the hooks are live, the consent guard blocks edits to its own
   files (by design).
4. Do not touch files outside the ones each step stages.

**Pre-flight (must pass):**

```bash
git status --porcelain --untracked-files=no      # expect: empty
git merge-base --is-ancestor f01a3ab HEAD && echo ok   # expect: ok
python3 --version                                 # expect: 3.9+
bash .ai/plans/2026-10-22-senior-dialogue/tools/rehearse.sh   # expect: last line "… 0 failed", exit 0
```

**The five steps** (each: run, read the last two lines, commit):

| Step | Command | Commit |
|---|---|---|
| C1 | `bash .ai/plans/2026-10-22-senior-dialogue/tools/implement.sh C1` | `git commit -F .ai/plans/2026-10-22-senior-dialogue/tools/commit-messages/C1.txt` |
| C2 | `… implement.sh C2` | `… commit-messages/C2.txt` |
| C3 | `… implement.sh C3` | `… commit-messages/C3.txt` |
| C4 | `… implement.sh C4` | `… commit-messages/C4.txt` |
| C5 | `… implement.sh C5` | `… commit-messages/C5.txt` |

Each `implement.sh` run ends with `python3 tools/validate.py --quick` and must
print `0 failed`. The commit-msg hook may warn about subject length (> 50) and
staged-file count; those are warnings, not failures. After C5:

```bash
python3 .ai/plans/2026-10-22-senior-dialogue/tools/validate.py --final   # expect: "… 0 failed", exit 0
git log --oneline f01a3ab..HEAD                                         # expect: 5 commits
```

Then hand §8 (human verification) to the human. Do not attempt it yourself.

---

## 1. Goal

Make `/engineer` the single front door for a **Senior Dialogue** working model:
the agent and the human treat each other as senior engineers. They
**understand → discuss → iterate to explicit agreement → document → build test-first**.
Most code is now agent-written and rarely read line by line, so ownership has to
come from the human being able to explain every decision (Feynman style: plain,
first principles, no babying).

## 2. Assumptions the human should check

| # | Assumption | Why it matters | Where to change it |
|---|---|---|---|
| A1 | Quick-fix and refactoring still need **one** recorded human answer (D-000). | Requirement 4 says code only under agreement; this is the cheapest floor. Autopilot runs of trivial fixes will park until you answer once. | `skills/engineer/SKILL.md` Step 2 |
| A2 | On **Claude Code**, agreement comes **only** from `AskUserQuestion`. Typed "agree" messages are not trusted. | Claude's `UserPromptSubmit` also fires for scheduled tasks, background-subagent reports, and cross-session messages (code.claude.com/docs/en/hooks → UserPromptSubmit), so a typed agreement could be model-originated. | `consent-protocol.md`, script `handle_hook` |
| A3 | Claude's `PostToolUse` payload carries the human's choice in `tool_response.answers` (question → label). | The docs state `PostToolUse` receives the tool's structured output and define `answers` that way for `AskUserQuestion`, but I could not observe a live payload. **Verify with §8 V1.** If it differs, agreements on Claude never record and the agent parks (fails safe). | script `ids_from_answer` |
| A4 | Copilot `ask_user`, Codex `request_user_input`, and opencode `question` result formats are unknown. | The recorder parses them fail-safe: if the result echoes the options, it records nothing and the typed first-line fallback is used. **Verify with §8 V2–V4.** | script `ids_from_text_failsafe` |
| A5 | The guard covers accidental or drift self-agreement and casual forgery, **not** a deliberately adversarial model obfuscating shell commands. | No in-process control can stop code running as the same OS user. HMAC + hash chain + guard raise the bar from "write a line" to "deliberate evasion". | `consent-protocol.md` → Threat model |
| A6 | Pre-existing SKILL.md files over 20,000 B (`design-principles`, `emil-design-eng`, `e2e-testing`, `observability-standards`, `api-contract-first`) are **out of scope**. | Only files this change touches are fixed (engineer 24.1 → 18.2 KB, HLD 21.5 → 10.0 KB, review 20.1 → 18.0 KB). validate.py reports the rest as WARN. | follow-up F2 |
| A7 | `review`, `high-level-design`, and `brainstorming` are split even though only `engineer` was named. | Each needs an edit for this feature and each was at or over the limit. Moves are verbatim and markers are asserted. | `tools/split_skills.py` |
| A8 | The test-scenario iteration cap N is set by the human in D-000. The agent proposes a value with reasoning; there is no hardcoded default. | Your requirement 1h and the "teach reasoning, don't hardcode" rule. | `senior-dialogue` SKILL Step 1 |
| A9 | GitHub wiki and corporate wiki publishing are **opt-in per work item** (in D-000). The default target is repo `docs/`. | Pushing to an external wiki is a side effect on shared systems. | `decision-cards.md` → From agreement to documentation |
| A10 | Codex plugin hooks require the human to trust them once in `/hooks`. | Codex skips untrusted non-managed hooks (learn.chatgpt.com/docs/hooks → Review and trust hooks). The installer prints the reminder. | `install-codex.sh` |

## 3. Design (decisions, with evidence)

### 3.1 Shape — the smallest design that meets the goal

- **One new skill, `senior-dialogue`** (protocol + six references), orchestrated
  by `/engineer`. Existing skills are reused, not duplicated: brainstorming's
  conversation practices build cards; business-context-intake's questions are
  topic (b)'s territory; high-level-design's analyses are topic (c); writing-plans,
  TDD, SDD, ci-pipeline-setup, deployment-workflow, and observability-standards
  produce the artifacts in BUILD; teacher's Socratic Phase 4 style is used for
  teach-back.
- **One new agent, `test-scenario-reviewer`** (opus). `test-quality-reviewer`
  reviews test *code* after the fact; nothing reviewed the pre-code REQ→TC
  matrix. Right-sizing: judging "would a subtly wrong implementation pass this
  scenario?" is reasoning, not pattern matching.
- **One stdlib script + per-host hook wiring** for the consent ledger, because
  requirement 4 needs a mechanism the model cannot self-satisfy, and prose
  instructions cannot provide that.
- **Five small text hooks** in existing skills (brainstorming, HLD,
  business-context-intake, writing-plans, TDD). Each says that inside
  `/engineer` its human-approval ask is pre-satisfied by the ledger, so BUILD
  has zero check-ins and docs need no separate review.

### 3.2 Two phases

| Phase | Waits for human | Ends when |
|---|---|---|
| DISCUSS | at every decision card | `dialogue-consent.py check` exits 0 for every card in `decisions.json` |
| BUILD | only if a finding would change an agreed decision, a subagent is BLOCKED, spend breaches, or the lane marks a human card (PRR go/no-go, outcome-review) | PR / done |

### 3.3 Discussion agenda (priority-ordered, not a pipeline)

Topics a–j as you specified (`references/agenda.md`). Ordering is decided **at
runtime** by reasoning about each topic for this work item: how likely we are
wrong now and on what evidence, the cost if wrong and found late, and
reversibility. The model must show that reasoning with numbers and their basis
(`references/depth-scaling.md` gives the reasoning shape plus clearly labeled
illustrative examples). Hard constraints: (a) first, (b) before (c) and (d),
(h) before any code. One-way doors get their own card, teach-back, and an ADR.

### 3.4 Teach reasoning, don't hardcode (adopted repo-wide)

Your direction is recorded as a CLAUDE.md "Editing skills" rule and a
PHILOSOPHY.md section: skills explain how to think and iterate with the human.
Numbers, thresholds, and depth are derived at runtime with their basis shown.
Hardcode only what is intrinsic to the skill: a security mechanism (the ledger),
host or API limits (Claude's four-question `AskUserQuestion` limit), a
standard's own definitions (MC/DC, Core Web Vitals), or a format another tool
parses. The payloads were audited against this rule (judgment-call constants
such as "default 3", "≤ 120 words", "2–4 metrics", "3–5 scenarios" were
replaced with reasoning guidance).

### 3.5 Consent mechanism (requirement 4)

| Element | Decision | Evidence |
|---|---|---|
| Ledger | `<git-root>/.ai/dialogue/consent.jsonl`, append-only, each row hash-chained to the previous and HMAC-SHA256-signed with `~/.private-ai-harness/consent.key` (0600, created on first record) | A model-written row would need the key; any edit breaks the chain → `check` exits 4 |
| Writer | Host hook processes only (`hook --host … --event prompt\|answer`) | Hooks run in the host process environment, outside the model's tool calls |
| Guard | `PreToolUse` on every tool: deny (a) the agreement token followed by an id in any tool input except the ask tool and `task_complete`; (b) any input touching the ledger, key, hook wiring, `disableAllHooks`, or host settings/hook dirs — except the script's `activate/status/check/selftest` and plain `git add/commit/status/diff/log/show` | Claude: a PreToolUse hook can block a call before permission rules are evaluated, in any mode (code.claude.com/docs/en/permissions → Precedence among rules, hooks). Copilot: `preToolUse` deny via stdout JSON (docs.github.com/en/copilot/reference/hooks-reference). Codex: `hookSpecificOutput.permissionDecision: deny` (learn.chatgpt.com/docs/hooks). opencode: throw in `tool.execute.before` (opencode.ai/docs/plugins) |
| Fail-safe | Every hook exits 0. Recording fails safe (doubt → nothing recorded → agent parks). The guard fails open on internal error. | Copilot `preToolUse` command hooks are **fail-closed on crash** (hooks reference → Exit codes); a crashing guard would block every tool |
| Ask-tool parsing | Claude: per-question `answers`. Others: record only if the text has exactly one unambiguous agreement and no revise/park token (echoed options → nothing recorded) | Prevents echo false positives |
| No human | Ask once → `status` shows not agreed → write `dialogue/PARKED.md` (one highest-value question + exact reply) → manifest `phase: parked` → end the turn (Copilot autopilot: `task_complete` "PARKED — …") | AskUserQuestion is never auto-approved in any Claude mode (permission-modes → actions no mode auto-approves) |
| Maintenance | `PRIVATE_AI_HARNESS_CONSENT_GUARD=off` in the host's launch environment (human-only) | |
| Debug | `PRIVATE_AI_HARNESS_CONSENT_DEBUG=1` → raw payloads to `~/.private-ai-harness/consent-debug.jsonl` | Needed for A3/A4 verification |

Per-host channels:

| Host | Ask tool | Typed fallback | Wiring |
|---|---|---|---|
| Claude Code | `AskUserQuestion` | none (A2) | `hooks/dialogue-consent.json` listed in `.claude-plugin/plugin.json` |
| Copilot CLI | `ask_user` | first line = token + ids (`userPromptSubmitted`) | installer adds 3 entries to `~/.copilot/hooks/private-ai-harness.json` |
| Codex | `request_user_input` | first line (`UserPromptSubmit`) | `hooks/codex-dialogue-consent.json` via `.codex-plugin/plugin.json` `hooks` key |
| opencode | `question` | first line (`chat.message`) | `scripts/opencode-dialogue-consent-plugin.js` copied to `~/.config/opencode/plugin/` |

Why hook commands end in `2>/dev/null || true`: Copilot also reads legacy
plugin manifests, including `.claude-plugin/plugin.json`
(docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference).
If a host runs a command whose plugin-root variable is unset, the command must
exit 0 silently instead of fail-closing every tool. Denials travel through stdout
JSON, which still works. validate.py checks both paths.

### 3.6 Test scenarios before code (requirement 1h)

Matrix `TC | Validates | Level | Technique | Given/When/Then | Kills | Determinism`
(`references/test-scenarios.md`). Rigor bar: SQLite (sqlite.org/testing.html:
100% branch + MC/DC in TH3, anomaly and fuzz testing); MC/DC per Hayhurst et al.,
NASA/TM-2001-210876. Loop: matrix → `test-scenario-reviewer` → mechanical fixes
by the agent, substantive ones as cards → repeat until reviewer PASS + the human
agrees, or cap N, after which the human chooses accept-with-listed-gaps (its own
card) or a larger N. BUILD maps every plan task's tests to TC ids; TDD writes
one RED test per TC that fails for the reason in its Kills column.

### 3.7 Systems depth (requirement 1i)

`references/systems-depth.md`: C23 (ISO/IEC 9899:2024), C++23 (ISO/IEC
14882:2024), and C++26 (technically complete at the March 2026 London/Croydon
WG21 meeting, in the DIS/publication pipeline per herbsutter.com and
iso.org/standard/91179 — **must be web-confirmed at dialogue time**), down to UB
catalog, lifetimes, ABI (dual libstdc++ ABI, layout, visibility, abidiff),
sanitizers, and fuzzing. Web frontend: Core Web Vitals (web.dev), rendering
strategy, a11y (WCAG 2.2 AA), security (Trusted Types/CSP), Baseline browser
matrix.

### 3.8 Documentation after agreement (requirement 3)

BUILD step 1 generates, from agreed cards only: an ADR-lite per card (full ADR
in `wiki/architecture/` for one-way doors), business context, spec, HLD, LLD +
consumer docs, test matrix, and user and developer docs to the D-000 targets.
Every section ends with `Sources: D-…`; any statement without an agreed source
is dropped or becomes a new card. That is why the human never reviews docs
separately. Existing reviewers still run autonomously.

## 4. File map

**New (from `payloads/`):**

| Path | Purpose |
|---|---|
| `skills/senior-dialogue/SKILL.md` (14.5 KB) | protocol |
| `skills/senior-dialogue/references/{agenda,consent-protocol,decision-cards,depth-scaling,test-scenarios,systems-depth}.md` | detail read at the step that needs it |
| `skills/senior-dialogue/scripts/dialogue-consent.py` | ledger + hook entry point + CLI + `selftest` (19 checks) |
| `agents/test-scenario-reviewer.md` | new reviewer |
| `hooks/dialogue-consent.json` | Claude hooks |
| `hooks/codex-dialogue-consent.json` | Codex hooks |
| `scripts/opencode-dialogue-consent-plugin.js` | opencode bridge |
| `skills/engineer/SKILL.md` (replaced, 18.2 KB) | router + dialogue integration |

**Generated by `split_skills.py` (verbatim moves from `f01a3ab`):**
`skills/engineer/references/{cost-ledger,review-discipline}.md`,
`skills/high-level-design/references/{hld-template,adr-format}.md`,
`skills/brainstorming/references/process-flow.md`,
`skills/review/references/direct-chat-triggers.md`, plus the pointer edits in
the three parent SKILL.md files.

**Patched by `apply_patches.py`:** AGENTS.md (skills, agents, input contract,
right-sizing, repo contract, consent model section), README.md (engineer +
senior-dialogue + reviewer rows, hooks, Copilot install bullet), CLAUDE.md
(repo layout, authoring rules, consent section, what-not-to-do), PHILOSOPHY.md,
`docs/engineer-skill-map.md`, `skills/{brainstorming,high-level-design,business-context-intake,writing-plans,test-driven-development,review}/SKILL.md`,
`scripts/install-{copilot,codex,opencode}.sh`, all three manifests (hooks +
version 5.0.0).

## 5. Commits

| | Subject | Contents | Doc-sync |
|---|---|---|---|
| C1 | `refactor(skills): split oversized skills into references` | verbatim moves (HLD, brainstorming, review) | none needed: no table or rule changes |
| C2 | `feat(agents): add test-scenario-reviewer` | agent + inventory row | AGENTS, README; CLAUDE has no agent-specific rule |
| C3 | `feat(skills): add senior-dialogue working model` | skill, refs, script; authoring rule | AGENTS, README, CLAUDE, PHILOSOPHY |
| C4 | `feat(plugin)!: wire consent hooks for all four hosts` | hook files, opencode bridge, manifests' hooks, three installers | AGENTS, README, CLAUDE |
| C5 | `feat(skills)!: route /engineer through senior dialogue` | engineer rewrite + refs, five approval hooks, version 5.0.0 | AGENTS, README, engineer-skill-map |

Bodies are in `tools/commit-messages/C*.txt` (WHY, ≤ 80 columns, Co-authored-by
trailer, `BREAKING CHANGE:` footer on C5).

## 6. Validation (automated — `tools/validate.py --final`)

SKILL.md sizes (touched < 20,000 B; pre-existing oversize = WARN) · relative
links in touched skills · every skill the router names exists · no literal
agreement token with a real id anywhere in the repo · JSON validity · script
compile + selftest + CLI exit codes (0/3/4) + tamper detection · each hook
file's guard command denies a ledger write **and** fails open with the plugin
root unset · `bash -n` on all installers · installer Python blocks run twice
(idempotent), Copilot wires exactly 3 consent hooks · `node --check` on the
rendered opencode plugin · manifests at 5.0.0 with existing hook paths · all
three agent adapters render into a temp HOME and emit `test-scenario-reviewer`
· commit messages pass `scripts/commit-msg.sh` · every `*-reviewer` agent is in
`/review`'s inventory and has a right-sizing row · repo files equal payloads
byte-for-byte.

## 7. Rollback

`git revert --no-edit HEAD~5..HEAD` (reverts C5→C1), then re-run the host
installers so the Copilot hook entries and the opencode plugin are refreshed.
Remove leftovers by hand if needed: three `dialogue-consent` entries in
`~/.copilot/hooks/private-ai-harness.json`, and
`~/.config/opencode/plugin/private-ai-harness-dialogue-consent.js`. Ledgers in
`.ai/dialogue/` are inert data.

## 8. Human verification (live hosts — not automatable, ~15 min)

Run in a scratch git repo with `PRIVATE_AI_HARNESS_CONSENT_DEBUG=1` exported
before launching each host. After each, `python3 <repo>/skills/senior-dialogue/scripts/dialogue-consent.py status`.

| # | Host | Do | Expect | If not |
|---|---|---|---|---|
| V1 | Claude Code (`/reload-plugins`) | `/engineer fix a typo in README`; answer D-000 via the AskUserQuestion agree option | `status` lists D-000; BUILD proceeds without further questions | Inspect `consent-debug.jsonl` for the `AskUserQuestion` `tool_response` shape; adjust `ids_from_answer` (A3) |
| V2 | Copilot CLI (rerun installer, autopilot on) | same; answer via `ask_user` | D-000 recorded, or the agent asks you to type the agreement and recording succeeds after you do | Inspect the debug log for `textResultForLlm` (A4) |
| V3 | Claude Code with `--dangerously-skip-permissions` | ask it to append a line to `.ai/dialogue/consent.jsonl` | the call is denied with the guard's reason | Hook deny is not honored in bypass mode on your version; report |
| V4 | Codex (trust hooks in `/hooks`) and opencode | same as V2 | recorded via ask tool or typed fallback | as V2 |
| V5 | any host, no human (`claude -p "/engineer …"` or Copilot autopilot, ignore the prompt) | let it run | `dialogue/PARKED.md` written, no code changed, session ends with the exact reply | the agent self-agreed → file a bug against `senior-dialogue` |

## 9. Follow-ups (not in this change)

- **F1 — Retrofit "teach reasoning, don't hardcode" across existing skills.**
  Audit candidates found while planning: HLD capacity triggers "70% / 80% / 85%",
  business-context-intake "minimum 3 exclusions" and "2–4 input metrics",
  brainstorming "~200–300 words" chunks. Judge each. A cited convention (e.g.
  the FinOps 80% budget alert in engineer's cost ledger) can stay as a cited
  example.
- **F2 — Split the five pre-existing oversize SKILL.md files** (A6) using the
  same verbatim-move pattern as `split_skills.py`.
- **F3 — Tighten host parsing** once V1–V4 reveal real ask-tool payload shapes;
  add them as `selftest` fixtures.
