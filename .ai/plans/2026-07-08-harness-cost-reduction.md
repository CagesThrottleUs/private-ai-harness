# Harness cost reduction — mechanical runbook

Goal: cut $ of a one-shot `/engineer` → PR run, no quality loss. Structure
stays: same skills, same lanes. Only *what loads, which model, how many
reviewers* changes.

---

## EXECUTOR CONTRACT — read before touching anything

You are a Sonnet session. Do EXACTLY what each TASK says. Do not improvise,
redesign, or "improve" beyond the stated action.

Rules:
1. Do tasks in numeric order. Finish one (edit + verify + commit) before the next.
2. Each task gives: FILE, LOCATE (verbatim string that already exists in the
   file), ACTION (exact new text or precise transform), VERIFY (a command that
   must pass), COMMIT (message to use).
3. Before editing, open FILE and confirm the LOCATE string exists verbatim. If
   it does NOT match exactly → STOP, report the mismatch, do not guess.
4. Change only the lines the ACTION names. Do not reformat surrounding text.
5. After each edit, run VERIFY. If it fails → STOP, report, do not continue.
6. Commit with COMMIT. Body must explain WHY (already written for you below).
7. Bump `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` version
   (patch) in the SAME commit as any skill/agent change.
8. Tasks marked `[JUDGMENT — SKIP]` are NOT mechanical. Do not attempt them on
   Sonnet. Leave for an Opus/human pass.

Anchors below were verified against the files on 2026-07-08. If a file changed
since, re-verify before editing.

---

## TASK 0 — Baseline (measurement, no code edit)

Do this first. No optimization ships without a before number.

1. Run one representative `/engineer` task-lane job to PR on the CURRENT harness.
2. Capture with `/cost` and `rtk gain`: total $, total tokens, count of review
   agents actually dispatched.
3. Write the numbers to `.ai/performance/2026-07-08-harness-baseline.md`.
4. VERIFY: `test -f .ai/performance/2026-07-08-harness-baseline.md`
5. COMMIT: none (baseline file is git-ignored scratch under `.ai/`).

---

## LEVER 1 — one review pass, dispatched by diff scope

### TASK 1.1 — gate `/review all` by what changed
FILE: `skills/review/SKILL.md`

LOCATE (verbatim):
```
### Step 3 — `/review all` (parallel dispatch)

Dispatch all four PR-scoped agents simultaneously:
```

ACTION: replace the whole Step 3 block — from the `### Step 3` heading down to
and including the line `Wait for all four, then produce the aggregated report (Step 4).`
— with exactly:

```
### Step 3 — `/review all` (conditional parallel dispatch)

First scan the diff to decide which agents have something to review:

​```bash
CHANGED=$(git diff $BASE..$HEAD --name-only)
echo "$CHANGED" | grep -qE '(test|spec)' && TESTS=1 || TESTS=0
echo "$CHANGED" | grep -vqE '\.(md|txt)$' && CODE=1 || CODE=0
​```

Dispatch in parallel by rule. Always pass REPORT_FILE so findings go to a file,
not into the caller's context:

| Agent | Dispatch when | Inputs |
|-------|---------------|--------|
| pr-reviewer | always | DESCRIPTION, BASE_SHA, HEAD_SHA, REQUIREMENTS, REPORT_FILE |
| spec-impl-reviewer | always | SPEC_PATH, BASE_SHA, HEAD_SHA, REPORT_FILE |
| test-quality-reviewer | TESTS=1 | SPEC_PATH, BASE_SHA, HEAD_SHA, REPORT_FILE |
| security-reviewer | CODE=1 (skip only if docs/comment-only) | DESCRIPTION, BASE_SHA, HEAD_SHA, SPEC_PATH, REPORT_FILE |

Wait for all dispatched agents, then produce the aggregated report (Step 4).
```

(Note: the ​```bash fence above uses a zero-width char to show nesting — write a
normal ```bash fence.)

VERIFY: `grep -q "conditional parallel dispatch" skills/review/SKILL.md && grep -q "TESTS=1" skills/review/SKILL.md`

COMMIT:
```
feat(skills): gate /review all by diff scope

Suite ran all four agents on every diff, spending on test-quality when
no test changed and on security passes with nothing security-relevant.
Scope each agent to the diff; security stays on unless docs-only so a
misclassified change is never silently skipped.
```

WHY (do not remove coverage): security defaults ON. Only test-quality is gated,
plus the always-on pair. No dimension is dropped for a real code diff.

---

### TASK 1.2 — pr-creator consumes the verdict, stops re-reviewing
FILE: `skills/pr-creator/SKILL.md`

LOCATE (verbatim):
```
## Step 5 — Run All Review Agents (parallel)
```

ACTION: replace the entire Step 5 section — from that heading down to the last
line before `## Step 6 — Reviewer Assignment` — with exactly:

```
## Step 5 — Consume Review Verdict (no re-dispatch)

The authoritative review runs once, at `finishing-a-development-branch`
Step 1.5, which writes `.ai/reports/YYYY-MM-DD-<branch>-review-summary.md`.
pr-creator consumes that verdict — it does NOT run review agents again.

​```bash
BRANCH=$(git branch --show-current)
VERDICT=$(ls -t .ai/reports/*-"$BRANCH"-review-summary.md 2>/dev/null | head -1)
​```

- If `$VERDICT` exists and was written for the current HEAD → read it. Do NOT
  dispatch any review agent.
- If `$VERDICT` is absent → run `/review all` exactly once, then read the
  summary it writes.

Decide PR state from the verdict's `## Overall` line:

| Overall | PR state |
|---------|----------|
| MERGE READY | ready |
| NEEDS WORK | draft — list Important issues under `## Review Notes` |
| BLOCKED | STOP — do not create the PR |
```

VERIFY: `grep -q "Consume Review Verdict" skills/pr-creator/SKILL.md && ! grep -q "Run All Review Agents" skills/pr-creator/SKILL.md`

COMMIT:
```
refactor(skills): pr-creator consumes review verdict

The four-agent suite ran at the pre-merge gate, again in pr-creator, and
again in finishing — three whole-branch passes on the largest diff at the
most expensive point. pr-creator now reads the gate's verdict instead of
re-reviewing, removing one full Opus pass with no loss of coverage.
```

---

### TASK 1.3 — mark finishing's review the single authoritative gate
FILE: `skills/finishing-a-development-branch/SKILL.md`

LOCATE (verbatim):
```
This dispatches: pr-reviewer + spec-impl-reviewer + test-quality-reviewer + security-reviewer.
```

ACTION: insert immediately AFTER that line, on a new line:

```

The aggregated summary is written to `.ai/reports/YYYY-MM-DD-<branch>-review-summary.md`.
This is the authoritative branch verdict. `pr-creator` consumes it — do not run
the suite again downstream.
```

VERIFY: `grep -q "authoritative branch verdict" skills/finishing-a-development-branch/SKILL.md`

COMMIT:
```
feat(skills): finishing writes authoritative review verdict

pr-creator needs a single source of review truth to stop re-running the
suite. Name the summary this step writes as that source.
```

---

### TASK 1.4 — engineer routes the full suite to one place
FILE: `skills/engineer/SKILL.md`

LOCATE (verbatim):
```
8. **requesting-code-review** *(⊘ pr-reviewer)* — review before PR
9. **pr-creator** — assemble PR; update manifest `phase: deliver`
```

ACTION: replace those two lines with exactly:

```
8. **requesting-code-review** — per-task `/review pr` during SDD only (task-scoped). The authoritative full-suite `/review all` runs ONCE at step 10 (finishing), not here.
9. **pr-creator** — assemble PR; consumes the step-10 review verdict (no re-review); update manifest `phase: deliver`
```

VERIFY: `grep -q "runs ONCE at step 10" skills/engineer/SKILL.md`

COMMIT:
```
docs(skills): engineer routes single full-suite review

The chain implied a full /review all at three steps. State that the
per-task review is scoped and the one full suite is owned by finishing,
so the router does not trigger redundant passes.
```

---

## LEVER 2 — model routing (no risky downgrades)

Finding: `AGENTS.md` already right-sized the review agents — 9 are sonnet, the
rest are opus with a written rationale. Downgrading them contradicts that audit
and risks silent finding loss. So the model lever here is NOT frontmatter swaps
on review agents. It is two safe things:

### TASK 2.1 — session-model-per-lane guidance in engineer
FILE: `skills/engineer/SKILL.md`

LOCATE (verbatim):
```
## Universal constraints (every lane, always active)
```

ACTION: insert immediately BEFORE that heading:

```
## Session model per lane

The main session model cannot change mid-run. Pick the launch model by lane:

| Lane | Launch on | Why |
|------|-----------|-----|
| quick-fix, refactoring, task | Sonnet | judgment work is in pinned-model subagents; orchestration is thin |
| epic design phases (brainstorm, HLD) | Opus | these reason in the main session and cannot be offloaded |
| research | Sonnet; Opus for hard trade-offs | spike judgment is sometimes deep |

Named subagents ignore the chat model (their frontmatter `model:` is pinned).

```

VERIFY: `grep -q "Session model per lane" skills/engineer/SKILL.md`

COMMIT:
```
feat(skills): engineer session-model-per-lane guidance

Running every lane on Opus is the largest avoidable cost. Cheap lanes do
their judgment in pinned-model subagents, so the session can be Sonnet;
only epic design phases need Opus in-session.
```

### TASK 2.2 — no edit
SDD already mandates explicit cheap models for implementer subagents
(`subagent-driven-development/SKILL.md`, "Model Selection"). Confirm it still
says so; if yes, no change. VERIFY: `grep -q "Always specify the model explicitly" skills/subagent-driven-development/SKILL.md`

---

## LEVER 3 — lean orchestrator (avoid adding context)

### TASK 3.1 — artifact-by-reference + manifest-as-truth in engineer
FILE: `skills/engineer/SKILL.md`

LOCATE (verbatim):
```
- **Skill not named in any lane above:** invoke `using-superpowers` to discover the right one before improvising
```

ACTION: insert immediately AFTER that line:

```
- **Artifact-by-reference:** each phase writes its output to a file and records
  the path in the manifest. Hold only the manifest pointer, the ledger, and the
  current phase in context. Re-read a prior artifact only when a step needs it —
  do not keep full bodies resident.
- **Manifest is the source of truth:** read phase/gate/artifact state from
  `.ai/work/<id>/manifest.md`, not from memory. This survives compaction.
- **Verdict-only returns:** gates and reviewers return `PASS|FAIL` plus a
  REPORT_FILE path — never paste their findings into the orchestrator.
- **After each phase:** tell the user "phase complete — safe to /compact; the
  manifest holds state." Context eviction needs /compact; a prompt cannot evict.
```

VERIFY: `grep -q "Artifact-by-reference" skills/engineer/SKILL.md && grep -q "Manifest is the source of truth" skills/engineer/SKILL.md`

COMMIT:
```
feat(skills): engineer lean-orchestrator context rules

A one-shot run kept every phase's full artifact resident and re-sent it
each turn, so late turns cost the most. Hold artifacts by path, read
state from the manifest, and return verdicts not findings — the
orchestrator stops growing with the work.
```

---

## LEVER 4 — fold mechanical gate reviewers  [JUDGMENT — SKIP on Sonnet]

Do NOT attempt on a Sonnet pass. Folding a specialist reviewer into a generic
`test-gate-reviewer` + rubric file only preserves quality if the rubric encodes
the specialist's judgment (assess adequacy, not just presence). Authoring those
rubrics is judgment work.

When done on an Opus/human pass:
- Create `agents/test-gate-reviewer.md`, `agents/ops-gate-reviewer.md`,
  `agents/doc-gate-reviewer.md` (generic validator persona).
- Move each folded specialist's checklist into a rubric file under the owning
  skill, enriched to encode judgment.
- Fold ONLY: e2e, accessibility, load-test, visual-regression, chaos (test);
  ci, incident-response, iac, dast, feature-flag (ops); sequence-diagram,
  database-erd, api-versioning, onboarding (doc).
- KEEP specialist (do not fold): hld, spec-quality, business-context, plan,
  api-contract, deployment, observability, integration-test — and all code
  reviewers.
- Rewire the owning skills + `review/SKILL.md` roster; delete folded agent files;
  update `AGENTS.md` + `README.md` (doc-sync triple).

---

## TASK 9 — Regression gate (after each Lever)

Prove quality held before moving on.
1. Keep a known-buggy diff fixture (one correctness bug + one security bug).
2. Run the review under the NEW config against it.
3. VERIFY both planted bugs are flagged. If either is missed → revert the last
   Lever's edits and report.
4. Re-run the TASK 0 job; confirm cost dropped AND no finding class disappeared.
5. Write results to `.ai/performance/2026-07-08-harness-after.md`.

---

## Order of execution

TASK 0 → 1.1 → 1.2 → 1.3 → 1.4 → (TASK 9) → 2.1 → 2.2 → 3.1 → (TASK 9) →
[LEVER 4 only on Opus/human pass] → final TASK 9.

Separate, low-effort, not in this runbook: trim eager `@`-imports in the global
`~/.claude/CLAUDE.md` (caveman/commit-discipline/workflow/karpathy full bodies
resident every turn) → convert to lazy skill triggers.

---

## Appendix — rationale (REFERENCE ONLY, do not act on this section)

- Cost peaks at PR time: max context × repeated Opus review suite × biggest diff.
- Redundancy verified: the 4-agent suite is invoked at finishing Step 1.5, again
  in pr-creator Step 5, and referenced again via requesting-code-review — up to
  3 whole-branch passes. LEVER 1 collapses to one.
- Reasoning classes of edits: O1 (pr-creator evaluator→clerk), O2 (3×→1× review),
  O3 (conditional dispatch), O6 (artifact-by-reference) change how the LLM
  reasons; O4/O5/O7 (model/report-file/compact) do not. O8 (folding) is the
  deepest change (specialist→rubric-follower) — hence LEVER 4 is judgment-gated.
- Model: review-agent models already audited in AGENTS.md; the real model lever
  is session-per-lane + cheap SDD implementers, not agent downgrades.
- Honest limit: prompts can only avoid ADDING context; eviction needs /compact.
