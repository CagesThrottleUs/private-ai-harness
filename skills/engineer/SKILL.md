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
| **portfolio** | 2+ epics/initiatives to sequence against finite capacity, a roadmap, "which should we do first", cross-epic dependencies, a standing backlog | Weeks–months |
| **research** | "spike", "POC", "feasibility", "compare A vs B", "design doc", "evaluate X", "is X possible" — answer is the deliverable, not code | Hours |
| **refactoring** | "refactor", "clean up", "extract", "split class/method", "reduce duplication", "decouple", "restructure", "simplify", "rename module" — code is correct, shape is wrong; zero new behavior | Hours |

**Ambiguity rule:** if signals conflict, ask ONE question:
- fix-vs-refactor: "Is something broken, or does the code work but have the wrong shape?"
- refactor-vs-task: "Will callers need to change, or does the external contract stay identical?"
- task-vs-epic: "Is this extending an existing service, or creating something new?"
- epic-vs-portfolio: "Is this one initiative, or several competing initiatives to prioritize and sequence?"
- any-vs-research: "Is the deliverable committed code or a decision document?"

**FV-eligibility flag (set during classify, independent of lane):** set `fv-eligible` when BOTH hold — (a) the change touches a **critical-core** (cryptography, auth/authz decisioning, monetary/accounting arithmetic, consensus/replication/ordering invariants, or the safety of an `unsafe`/FFI block), AND (b) the target language has a verifier (full-deductive: Rust/Verus, Dafny, Ada/SPARK, C/Frama-C, Java/OpenJML; bounded: C++/CBMC·ESBMC). If (a) holds but the language has no verifier (Kotlin/TS/Python/Go/…), do NOT set the flag — route the invariant to `property-based-testing` (and `deterministic-simulation-testing` for concurrent cores) instead. The flag gates the `formal-verification` step below; it is off by default and never fires on ordinary logic.

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

**Spec+plan loop by lane:** task, epic, and portfolio always carry brainstorming → spec-quality-gate → writing-plans in "Proposed skill chain". quick-fix and refactoring skip it by default — nothing to model in a one-symbol fix or a same-shape restructure — and surface it under "Skipping" with reason "lane default: single-symbol scope". If classifying (or executing) reveals the change spans multiple files/symbols, needs a new interface, or the root cause is genuinely ambiguous, stop and re-classify to task lane rather than bolting the loop onto quick-fix piecemeal.

## Step 3 — Execute the confirmed lane

---

### QUICK-FIX lane

Footprint: ~4 skills · no manifest · minutes. ~7 only if spec+plan is explicitly pulled in (see below).

Design phase skipped by default — nothing to model in a one-symbol fix. Pull in **brainstorming → spec-quality-gate → writing-plans** ahead of step 1 only if, while classifying or mid-fix, the change turns out to span multiple files/symbols, need a new interface, or have a genuinely ambiguous root cause — otherwise re-classify to task lane instead of running the loop at quick-fix scope.

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
6a. **formal-verification** *(⊘ formal-verification-reviewer)* — **only if `fv-eligible` set at classify.** Escalate the proof-worthy invariants of the critical-core to machine-checked contracts (web-confirmed toolchain); block on undischarged obligations. Not eligible = skipped with reason "no critical-core / no verifier for language"
7. **verification-before-completion** *(⊘ linter-reviewer)* — lint + type check; update manifest `phase: verify`
8. **requesting-code-review** *(⊘ receiving-code-review for triaging returned findings)* — per-task `/review pr` during SDD only (task-scoped). The authoritative full-suite `/review all` runs ONCE at step 10 (finishing), not here.
9. **pr-creator** — assemble PR; consumes the step-10 review verdict (no re-review); update manifest `phase: deliver`
10. **finishing-a-development-branch** — merge/cleanup; update manifest `phase: done`

---

### PORTFOLIO lane

Footprint: portfolio manifest + N epic runs · weeks–months. The layer above the
epic — sequences many epics against finite capacity.

**First:** create `.ai/portfolio/manifest.md`.

1. **portfolio-management** *(⊘ portfolio-reviewer)* — run the SAFe Portfolio Kanban: place each initiative in a state (Funnel→Reviewing→Analyzing→Backlog→Implementing→Done), score by **WSJF** (cost of delay ÷ job size), enforce **WIP limits** (Little's Law), validate the cross-epic dependency DAG, link each epic to an OKR
2. **Pull loop:** when Implementing WIP < limit, pull the highest-WSJF backlog epic whose dependencies are all done, and dispatch it as `/engineer "<epic>"` at the **epic lane** — recursive orchestration one level down
3. On each epic `done`: record for **delivery-metrics**, and consume its **outcome-review** decision — a `kill` frees WIP and lowers cost-of-delay for follow-ons; a `persevere` raises it. Then pull the next. Never exceed the WIP limit to get ahead — Little's Law says that lengthens every in-flight epic

Hold the WIP limit regardless of how cheaply AI can start epics; the 2024 DORA report ties undisciplined AI throughput to lower delivery stability.

---

### EPIC lane

Footprint: ~all 55 skills · epic manifest + N child manifests · days–weeks.

**First:** create epic manifest at `.ai/work/YYYY-MM-DD-<slug>/manifest.md`. Every gate below is hard-blocking — do not advance past a FAIL without human resolution.

1. **business-context-intake** *(⊘ business-context-reviewer)* — JTBD, measurable metrics, compliance, non-goals; FAIL = restart intake
2. **brainstorming** — full exploration; produces spec draft
3. **spec-quality-gate** *(⊘ spec-quality-reviewer)*
4. **high-level-design** *(⊘ hld-reviewer → human must approve)* — C4, STRIDE, failure modes, capacity; human approval is required before next step. If any critical-core invariant is `fv-eligible` (see classify), name it here as proof-worthy vs test-worthy — the spec-to-proof boundary is an architectural decision, and child stories inherit the `formal-verification` step (task lane 6a) automatically
5. **epic-decomposition** — break epic → N bounded stories; produce child manifests; identify parallel vs sequential waves
6. **service-scaffolding** *(⊘ service-scaffolding-reviewer)* — for a NEW service: emit the paved starting artifact (CI, observability, API contract stub, test harness, runbook, resource limits, catalog entry, scorecard) so it is born compliant *before* any child story implements into it. Skip if extending an existing service
7. **For each child story:** invoke this skill as `/engineer "<story description>"` at task lane — recursive orchestrator-workers one level down (SDD inside each story)
8. **deployment-workflow** *(⊘ deployment-reviewer)* — rollback, expand-contract migration, smoke tests
9. **observability-standards** *(⊘ observability-reviewer)* — SLOs, runbooks, golden signals
10. **incident-response** — severity matrix, postmortem template for new service
11. **production-readiness-review** *(⊘ production-readiness-reviewer → human go/no-go)* — consolidates SLOs, tested rollback, exercised runbooks, capacity, dependencies, on-call into one PRR artifact; **hard gate before first production traffic**, FAIL blocks launch. For an `fv-eligible` core, the PRR records the proof verdict (obligations discharged, tier, bound if bounded) as evidence — a discharged proof strengthens the readiness claim; an undischarged obligation on the core is a launch blocker
12. **onboarding-guide** — `wiki/ONBOARDING.md` updated for new service
13. **delivery-metrics** — after launch (and periodically): DORA four keys + reliability and flow efficiency from the manifest phase timestamps
14. **outcome-review** *(⊘ outcome-review-reviewer)* — after launch (and at each HEART-aligned checkpoint): measure the business-context north-star + input metrics against their targets with cited sources; render persevere/iterate/kill. Closes the "measure what you shipped" loop back to §4 intake and feeds the portfolio

---

### RESEARCH lane

Footprint: ~5 skills · decision artifact · hours. No production commits.

1. **codebase-comprehension** (inline) — map the area being evaluated
2. **research-spike** — time-boxed investigation; produces decision artifact
3. Output: `.ai/YYYY-MM-DD-<topic>-findings.md` or `wiki/architecture/YYYY-MM-DD-<topic>-adr.md`

Research code lives in a throwaway branch (`spike/<topic>`), deleted when spike closes. If the spike expands into implementation, STOP — re-invoke `/engineer "<task>"` with the decision as context.

---

### REFACTORING lane

Footprint: ~4 skills · no manifest · hours. Zero new behavior. ~7 only if spec+plan is explicitly pulled in (see below).

**Hard gate:** the external contract — callers, return values, error behavior — must be identical before and after. If a caller needs to change, that is a task not a refactor.

Design phase skipped by default — the shape change is scoped by the smell name and the move sequence below, not a separate spec. Pull in **brainstorming → spec-quality-gate → writing-plans** ahead of step 1 only if the restructure turns out to span multiple modules/services or the "zero new behavior" boundary is genuinely unclear — otherwise re-classify to task lane instead of running the loop at refactor scope.

1. Name the smell in one phrase (god class / duplication / deep nesting / long method / tight coupling / dead code / primitive obsession)
2. **codebase-comprehension** (inline) — map target symbols + callers + `codegraph_impact`; identify covering tests
3. Test baseline — run covering tests NOW; all must pass; if any fail → STOP, fix first via `systematic-debugging` in a separate lane
4. **refactoring** — one structural move per micro-commit; behavior check (tests pass) after every move; stop when the named smell is gone
5. **verification-before-completion** — lint gate on final state
6. **commit-discipline** — WHY body: which smell was removed and why that shape is better

If you discover a bug mid-refactor: commit the refactor progress, open a quick-fix lane for the bug, then resume.

---

## Session model per lane

The main session model cannot change mid-run. Pick the launch model by lane:

| Lane | Launch on | Why |
|------|-----------|-----|
| quick-fix, refactoring, task | Sonnet | judgment work is in pinned-model subagents; orchestration is thin |
| epic design phases (brainstorm, HLD) | Opus | these reason in the main session and cannot be offloaded |
| portfolio | Sonnet | Kanban bookkeeping + WSJF ranking + dispatch is thin; each dispatched epic picks its own launch model |
| research | Sonnet; Opus for hard trade-offs | spike judgment is sometimes deep |

Named subagents ignore the chat model (their frontmatter `model:` is pinned).

## Universal constraints (every lane, always active)

- **karpathy lens:** surgical changes, no over-build, verifiable success criteria
- **design-principles:** SOLID, DRY, YAGNI applied during construction
- **pr-review-non-negotiables:** every review dispatch in every lane — `requesting-code-review`, SDD's task reviewer, `giving-code-review`, or an external tool like `scout-pr-review` — carries the global gate (backward compat, migration, performance, reuse, testing, security, why/ROI, UX, determinism, over/underengineering, compatibility matrix). It's not a chosen dimension the reviewer picks up; it's standing, independent of which reviewer agent handles the rest.
- **Pattern propagation on review fixes:** when a review finding (from `requesting-code-review`, SDD's task reviewer, or a human) is accepted, search the current PR's diff — changed files only — for the same defect pattern before marking it fixed, and fix every occurrence in one pass. This includes analogous paths (CLI vs MCP, primary vs fallback), every call site of a changed shared helper, and a determinism self-check on any new concurrency. See `receiving-code-review`'s Pattern Propagation Check. A reviewer re-finding the same pattern in the next file over next round is the turnaround cost this exists to cut.
- **Zero negotiable review rounds:** never re-trigger an external reviewer until an internal self-review returns clean on the current diff — batch every open finding, fix in one pass, self-review (hunting the same failure classes plus fix-introduced regressions), push once, then re-trigger. Strong default; override only with a recorded reason. See `closing-review-loops`.
- **Spec+plan loop scales with lane:** see Step 2 — task, epic, and portfolio always carry brainstorming → spec-quality-gate → writing-plans. quick-fix and refactoring skip it by default; pull it in only when scope grows past a single symbol/file, and prefer re-classifying to task lane over bolting the loop on piecemeal.
- **Proportionality Gate on every accepted finding:** a real, in-scope finding is not automatically "fix it now, fully." If defending the fix needs a formal proof or a multi-call-site truth table, that complexity signals the fix may be disproportionate — take the simpler fix or file a follow-up ticket instead. Read `closing-review-loops`' cumulative commits/LOC receipt every round; propagating and hardening a fix is not license to maximize scope. See `receiving-code-review`'s Proportionality Gate.
- **Confirmation required at:** initial plan (Step 2), every gate FAIL, every BLOCKED subagent status, HLD approval (epic only)
- **Never auto-continue past BLOCKED or FAIL** — surface to human, wait for resolution
- **Manifest updated at each phase transition** (task/epic lanes)
- **Cost checkpoints:** before each numbered step in the lane, run
  `scripts/cost-checkpoint start <step-slug>` (from this skill's directory,
  e.g. `skills/engineer/scripts/cost-checkpoint`). Immediately after the step
  finishes — success, BLOCKED, or FAIL — run `scripts/cost-checkpoint end
  <step-slug> --row phase --lane <lane> --phase <phase> --skill <skill>`.
  For task/epic lanes, `--phase` is the manifest's current `phase:` value at
  that moment, read from `.ai/work/<id>/manifest.md` — the source of truth.
  For lanes with no manifest (quick-fix, research, refactoring), use the
  lane name as `--phase`. This appends one row to a global, cross-repo
  ledger — tokens only, no dollar figure, since pricing drifts and token
  counts don't. See "Cost ledger" below for the row schema and location.
- **Spend circuit breaker (enforcement, not just monitoring):** the ledger
  *records* what was spent; a runaway agentic loop needs a ceiling that
  *stops* spend before it happens. When the user (or a repo/session policy)
  sets a per-session token cap, run `scripts/cost-checkpoint budget --cap N`
  before each step. On `status: breach` (exit 3), **halt exactly like BLOCKED**
  — do not dispatch the next step; surface the ledger's per-phase breakdown and
  the cap to the human and wait. On `warning` (≥80% of cap — the FinOps
  budget-alert convention), tell the user the run is approaching its ceiling so
  they can decide to continue, raise the cap, or narrow scope. No cap set = no
  gate (opt-in), but always report `warning`/`breach` if a cap is present.
- **Per-subagent cost attribution (required at every dispatch):** bracket every
  named-subagent dispatch — reviewers inside a gate, workers inside SDD, the
  `/review all` agents — with `cost-checkpoint start <agent-slug>` … `end
  <agent-slug> --row agent --lane <lane> --agent NAME --role ROLE --model MODEL
  [--dispatch-mode parallel_batch]`. Without this, cost is attributed only to the
  coarse phase and the single most expensive dispatch (usually a reviewer) hides
  inside it. Attribution is what makes the circuit breaker and the delivery
  ledger honest about where tokens actually go.
- **Domain overlay:** when the working files/task match a recognized technology domain (Android/Kotlin/Compose/KMP — detected from `.kt`/`.kts`, `build.gradle(.kts)`, `@Composable`, `androidx.*`), activate the matching `<domain>-advisor` overlay (e.g. `android-advisor`) FIRST inside each construct/test/verify step. The overlay decides which installed global domain skill fills each already-existing lane step, and suppresses the ones that would contradict it. Without it, overlapping community skills feed conflicting guidance. See `domain-overlay` for the pattern.
- **Formal-verification gate (conditional, like domain-overlay):** when the `fv-eligible` flag is set at classify, the `formal-verification` step is standing — it fires at task-lane 6a and inside every `fv-eligible` child story, and its proof verdict feeds the epic PRR. It is off by default and never fires on ordinary logic or a language with no verifier; a critical-core in an unverifiable language (Kotlin/TS/Python) routes its invariant to `property-based-testing`/`deterministic-simulation-testing` instead. A proof is deductive assurance the review gate cannot give; it never replaces the review gate, it backs non-negotiables #1/#3 where it applies. Bounded-model-checking results (C++) state their bound and never claim an unbounded proof.
- **Skill not named in any lane above:** invoke `using-superpowers` to discover the right one before improvising
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
- **Completion report (every lane step that produces work):** end each step with
  a one-line user-facing report — *what* was produced, *where* it lives (path),
  the reviewer *verdict* if a gate ran, and *what's next*. A step whose only
  trace is a commit message leaves the user guessing; the report closes the
  "Document → Review → Ship" loop visibly. Skills carry their own
  `## Completion Report` block for when they run standalone; this constraint
  makes it non-optional inside a lane.

## Cost ledger

`scripts/cost-checkpoint` gives per-step token observability so a run's cost
is visible phase-by-phase, not just as a surprise total at the end.

**Location:** `~/.claude/private-ai-harness/engineer-cost-ledger.jsonl` on
Claude Code, or `$CODEX_HOME/private-ai-harness/engineer-cost-ledger.jsonl`
(normally `~/.codex/...`) on Codex. Each is outside any repo, shared across
every project on that host, and append-only with one JSON line per checkpoint.

**Row schema (phase rows — the only row type wired in this skill):**
```json
{"row": "phase", "session_id": "...", "repo": "owner/name", "timestamp": "...",
 "lane": "task", "phase": "construct", "skill": "subagent-driven-development",
 "tokens_by_model": {"<host-model>": {"input": 0, "output": 0, "cache_read": 0, "cache_creation": 0}}}
```

**Currency is tokens, not dollars.** Per-token pricing changes over time and
isn't reliably available to a running skill; token counts don't drift. If you
want a dollar figure, convert later yourself with whatever pricing you look
up at that time — the ledger deliberately does not store or estimate cost.

**Querying:**
- Everything for one run: filter by `session_id`.
- Most expensive phase across history: group by `phase`, sum `tokens_by_model`.
- Cross-repo total: the file already spans every repo — no aggregation step needed.
- One repo only: filter by `repo`.

**Enforcement:** `cost-checkpoint budget --cap N` reads cumulative session
tokens and returns `{"status": "ok|warning|breach", "used", "cap", "ratio"}`,
exiting 3 on breach so a caller can gate on `$?`. This is the circuit breaker —
the difference between *reading* spend after the fact and *stopping* it before a
runaway loop blows the ceiling. `warning` fires at 80% of cap (the conventional
FinOps/cloud-budget alert point); the cap itself is caller-supplied — there is no
baked-in magic number, since a reasonable ceiling depends on the work.

**Attribution:** `agent` rows (`--row agent --agent NAME --role ROLE --model
MODEL`) attribute cost to each named-subagent dispatch, not just the coarse
phase. The Universal-constraints "per-subagent cost attribution" bullet makes
these required at every dispatch site — a `phase` row alone hides which reviewer
or worker actually spent the tokens, and both the circuit breaker and
delivery-metrics are only as honest as that attribution.
