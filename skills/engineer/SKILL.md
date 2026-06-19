---
name: engineer
description: >
  Universal engineering entry point. Invoke as /engineer for ANY engineering task —
  quick fixes, bounded features, full epics, or research spikes. Classifies request
  complexity, proposes a skill chain, waits for user confirmation, then starts the
  flow. Use this instead of invoking individual skills directly.
user-invocable: true
---

# /engineer — Engineering Router

Single front door for all engineering work. Classifies the request → proposes a plan → confirms with you → starts the right skill chain. Never starts work without confirmation.

## Step 1 — Classify the request

Read the request. Apply the signal table. When signals conflict or span two lanes, ask ONE clarifying question before classifying.

| Lane | Key signals | Magnitude |
|---|---|---|
| **quick-fix** | Defect/bug/typo, single symbol broken, no new API or data model, obvious root cause | Minutes |
| **task** | Bounded feature, extending existing patterns, may add 1 endpoint or component, no new service | Hours |
| **epic** | New service/system, new data model, external integration, PII/auth/payment, multiple parallel workstreams | Days–weeks |
| **research** | "spike", "POC", "feasibility", "compare A vs B", "design doc", "evaluate X", "is X possible" — answer is the deliverable, not code | Hours |
| **refactoring** | "refactor", "clean up", "extract", "split class/method", "reduce duplication", "decouple", "restructure", "simplify", "rename module" — code is correct, shape is wrong; zero new behavior | Hours |

**Ambiguity rule:** if signals conflict, ask ONE question:
- fix-vs-refactor: "Is something broken, or does the code work but have the wrong shape?"
- refactor-vs-task: "Will callers need to change, or does the external contract stay identical?"
- task-vs-epic: "Is this extending an existing service, or creating something new?"
- any-vs-research: "Is the deliverable committed code or a decision document?"

## Step 2 — Present to user (MANDATORY — no skill fires before this)

Always output this exact block before invoking anything:

```
Lane detected: [quick-fix | task | epic | research]

Why I see it this way:
- [signal from the request]
- [signal from the request]

Proposed skill chain:
1. [skill name] → [what it produces]
2. [skill name] → [what it produces]
...

Skipping (reason):
- [skill]: [why not needed at this lane]

Confirm? (or tell me what to adjust — I'll re-plan before starting)
```

Do NOT invoke any skill until the user says yes. If they adjust scope, re-classify and re-present the full block.

## Step 3 — Execute the confirmed lane

---

### QUICK-FIX lane

Footprint: ~4 skills · no manifest · minutes.

Design phase entirely skipped — nothing to model in a one-function fix.

1. Activate **karpathy** lens — surgical change only, no over-build, verifiable success criteria
2. **systematic-debugging** — reproduce, isolate exact root cause before touching code
3. **codebase-comprehension** (inline, 1–3 codegraph calls) — map broken symbol + its callers
4. **test-driven-development** — RED: write failing test capturing the defect; GREEN: minimal fix; commit
5. **verification-before-completion** — lint gate + run the covering test
6. **commit-discipline** — WHY body: what was broken, what breaks without this fix

---

### TASK lane

Footprint: ~12 skills · work-item manifest · hours.

**First:** create `.ai/work/YYYY-MM-DD-<slug>/manifest.md`:
```
tier: task
phase: comprehend
gate_status: pending
artifacts: {}
```

1. **codebase-comprehension** — map the relevant area; write `comprehension.md`; user confirms understanding before proceeding
2. **brainstorming** — refine intent, scope, edge cases; produces spec draft in `.ai/specs/`
3. **spec-quality-gate** *(⊘ spec-quality-reviewer)* — FAIL = fix spec + re-run; PASS = advance; update manifest `phase: design, gate_status: pass`
4. **writing-plans** *(⊘ plan-reviewer)* — tasks with interfaces, global constraints; update manifest `phase: plan`
5. **using-git-worktrees** — isolated branch before any code
6. **subagent-driven-development** — the belt: orchestrator-workers + evaluator-optimizer + ledger; update manifest `phase: construct`
7. **verification-before-completion** *(⊘ linter-reviewer)* — lint + type check; update manifest `phase: verify`
8. **requesting-code-review** *(⊘ pr-reviewer)* — review before PR
9. **pr-creator** — assemble PR; update manifest `phase: deliver`
10. **finishing-a-development-branch** — merge/cleanup; update manifest `phase: done`

---

### EPIC lane

Footprint: ~all 44 skills · epic manifest + N child manifests · days–weeks.

**First:** create epic manifest at `.ai/work/YYYY-MM-DD-<slug>/manifest.md`. Every gate below is hard-blocking — do not advance past a FAIL without human resolution.

1. **business-context-intake** *(⊘ business-context-reviewer)* — JTBD, measurable metrics, compliance, non-goals; FAIL = restart intake
2. **brainstorming** — full exploration; produces spec draft
3. **spec-quality-gate** *(⊘ spec-quality-reviewer)*
4. **high-level-design** *(⊘ hld-reviewer → human must approve)* — C4, STRIDE, failure modes, capacity; human approval is required before next step
5. **epic-decomposition** — break epic → N bounded stories; produce child manifests; identify parallel vs sequential waves
6. **For each child story:** invoke this skill as `/engineer "<story description>"` at task lane — recursive orchestrator-workers one level down (SDD inside each story)
7. **deployment-workflow** *(⊘ deployment-reviewer)* — rollback, expand-contract migration, smoke tests
8. **observability-standards** *(⊘ observability-reviewer)* — SLOs, runbooks, golden signals
9. **incident-response** — severity matrix, postmortem template for new service
10. **onboarding-guide** — `wiki/ONBOARDING.md` updated for new service

---

### RESEARCH lane

Footprint: ~5 skills · decision artifact · hours. No production commits.

1. **codebase-comprehension** (inline) — map the area being evaluated
2. **research-spike** — time-boxed investigation; produces decision artifact
3. Output: `.ai/YYYY-MM-DD-<topic>-findings.md` or `wiki/architecture/YYYY-MM-DD-<topic>-adr.md`

Research code lives in a throwaway branch (`spike/<topic>`), deleted when spike closes. If the spike expands into implementation, STOP — re-invoke `/engineer "<task>"` with the decision as context.

---

### REFACTORING lane

Footprint: ~4 skills · no manifest · hours. Zero new behavior.

**Hard gate:** the external contract — callers, return values, error behavior — must be identical before and after. If a caller needs to change, that is a task not a refactor.

1. Name the smell in one phrase (god class / duplication / deep nesting / long method / tight coupling / dead code / primitive obsession)
2. **codebase-comprehension** (inline) — map target symbols + callers + `codegraph_impact`; identify covering tests
3. Test baseline — run covering tests NOW; all must pass; if any fail → STOP, fix first via `systematic-debugging` in a separate lane
4. **refactoring** — one structural move per micro-commit; behavior check (tests pass) after every move; stop when the named smell is gone
5. **verification-before-completion** — lint gate on final state
6. **commit-discipline** — WHY body: which smell was removed and why that shape is better

If you discover a bug mid-refactor: commit the refactor progress, open a quick-fix lane for the bug, then resume.

---

## Universal constraints (every lane, always active)

- **karpathy lens:** surgical changes, no over-build, verifiable success criteria
- **design-principles:** SOLID, DRY, YAGNI applied during construction
- **Confirmation required at:** initial plan (Step 2), every gate FAIL, every BLOCKED subagent status, HLD approval (epic only)
- **Never auto-continue past BLOCKED or FAIL** — surface to human, wait for resolution
- **Manifest updated at each phase transition** (task/epic lanes)
