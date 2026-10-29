---
name: engineer
description: >
  Universal engineering entry point. Invoke as /engineer for ANY engineering task —
  quick fixes, bounded features, full epics, portfolios, research spikes, or
  refactors. Classifies the request, opens a Senior Dialogue (understand → discuss →
  explicit ledger-recorded human agreement → document → build test-first), waits
  for the human during discussion even in autopilot/allow-all, then executes the
  agreed lane with zero check-ins. Use this instead of invoking skills directly.
user-invocable: true
---

# /engineer — Engineering Router + Senior Dialogue

Single front door for all engineering work. The agent and the human work as two
senior engineers: understand the problem, discuss it, iterate until the human
explicitly agrees, document the agreement, then build with tests. Ownership comes
from the human being able to explain every decision, because most code is now
written by an agent and rarely read line by line. The protocol lives in
`senior-dialogue`; this skill decides the lane and runs it.

Every lane has two phases:

- **DISCUSS** waits for the human at every decision card. Autopilot and allow-all
  are not consent. Agreement exists only when the consent ledger records it
  (`senior-dialogue` → `references/consent-protocol.md`). With no human present,
  park; never self-agree.
- **BUILD** starts when `check` passes for the work item's cards and runs as fast
  as possible with zero check-ins.

**Reason, don't recite.** The skills this router calls teach how to reason and
iterate with the human; they are not scripts to execute mechanically. Derive
estimates, thresholds, and depth for this work item at runtime and show the
reasoning. Fixed rules apply only where they are intrinsic: the consent
mechanism, host limits, and standards' own definitions.

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

**Resume:** `/engineer resume .ai/<id>` re-enters a parked or interrupted work item: read its manifest, `dialogue/decisions.json`, and `dialogue/PARKED.md`, run the consent `status`, and continue where it stopped.

## Step 2 — Open the dialogue: D-000 (MANDATORY — nothing is changed before it is agreed)

Before D-000 you may investigate read-only (codebase-comprehension, reproducing a
defect, reading docs, web research) — look before you ask. You may not edit code,
tests, or docs, or commit.

Create the work item directory `.ai/YYYY-MM-DD-<slug>/` and run the consent
`activate` (`senior-dialogue` → "The consent ledger"). Then present this block in
chat:

```
Lane detected: [quick-fix | task | epic | portfolio | research | refactoring]

Why I see it this way:
- [signal from the request or the code, cited]

Dialogue depth: [minimal | light | standard | full] — [why, for this work item]

Agenda (discussion order, with reasoning):
1. [topic] — [why it is worth the human's time here: how likely we are wrong and on what basis, cost if wrong, reversibility]
...
Folded into a batch card of defaults: [topics] — [why discussing them would not pay off]

Proposed skill chain (BUILD):
1. [skill] → [what it produces]
...

Skipping (reason):
- [skill]: [why not needed here]

Also to agree: test-scenario iteration cap N (my proposal and why) · doc targets · optional token cap
```

Write the same content as card D-000 in `dialogue/decisions.md` and
`dialogue/decisions.json`, then ask with the host ask-user tool as
`senior-dialogue` describes. D-000 is agreed only when the ledger says so. If the
human adjusts scope, re-classify, rewrite D-000, and ask again. If no human
answers, park.

**Depth defaults by lane** (runtime reasoning may move topics in or out; say why):
quick-fix and refactoring are *minimal* (D-000 alone carries the root cause or
smell, the fix or move sequence, and the RED test); research is *light*; task is
*standard*; epic is *full*; portfolio is D-000 plus the business inputs for each
epic. If a lighter lane uncovers a one-way door or a high-blast-radius change,
step the depth up and re-present D-000. Prefer re-classifying (for example,
quick-fix → task) over silently stretching a light lane.

## Step 3 — Execute the agreed lane

Each lane lists its DISCUSS steps (cards, waits for the human) and its BUILD steps
(no check-ins). BUILD starts only when consent `check` exits 0.

---

### QUICK-FIX lane

Footprint: ~5 skills · `dialogue/` only (no manifest) · minutes.

**DISCUSS**
1. **karpathy** lens — surgical change only, verifiable success criteria
2. **systematic-debugging** (read-only until D-000 is agreed) — reproduce, isolate the root cause
3. **codebase-comprehension** (inline, 1–3 codegraph calls) — map the broken symbol and its callers
4. D-000 card: root cause (cited), fix approach, the RED test → agreed in the ledger

**BUILD**
5. **test-driven-development** — RED as agreed; GREEN minimal fix; commit
6. **verification-before-completion** — lint gate + covering tests
7. **commit-discipline** — WHY body: what was broken, what breaks without this fix

---

### TASK lane

Footprint: ~13 skills · work-item manifest · hours.

**First:** `.ai/YYYY-MM-DD-<slug>/manifest.md`:
```
tier: task
phase: discuss
dialogue: standard
gate_status: pending
artifacts: {}
```

**DISCUSS** (`senior-dialogue`, agenda order from D-000)
1. **codebase-comprehension** — topic (a): write `comprehension.md`; the human agrees the current state
2. Remaining agenda topics, usually (b) context and scope, (d) LLD, and (h) test scenarios, plus (c) only if the change has architectural weight. Use **brainstorming**'s conversation practices (look first, play back, lay out approaches) to build each card. Use `test-scenario-reviewer` in the (h) loop.
3. `check` exits 0 → manifest `phase: build`

**BUILD** (zero check-ins; the gates run autonomously)
4. Documents from the agreed record: business-context doc (features), REQ-format spec, LLD, test-scenario matrix, ADR-lite per card
5. **spec-quality-gate** *(⊘ spec-quality-reviewer)* — fix mechanical findings; a finding that changes an agreed decision opens one new card
6. **writing-plans** *(⊘ plan-reviewer)* — every task's tests cite TC ids; manifest `phase: plan`
7. **using-git-worktrees** — isolated branch
8. **subagent-driven-development** — manifest `phase: construct`
8a. **formal-verification** *(⊘ formal-verification-reviewer)* — only if `fv-eligible`; block on undischarged obligations
9. **verification-before-completion** *(⊘ linter-reviewer)* — manifest `phase: verify`
10. **requesting-code-review** — per-task `/review pr` during SDD; the full `/review all` runs once at step 12
11. **pr-creator** — consumes the step-12 verdict; manifest `phase: deliver`
12. **finishing-a-development-branch** — merge/cleanup; manifest `phase: done`

---

### PORTFOLIO lane

Footprint: portfolio manifest + N epic runs · weeks–months.

**First:** `.ai/portfolio/manifest.md`.

**DISCUSS** — D-000 plus one card per epic for the business judgments the
ranking depends on (cost of delay, job size, OKR link). These are the human's
numbers; propose them with reasoning, but never self-agree them.

**BUILD**
1. **portfolio-management** *(⊘ portfolio-reviewer)* — SAFe Portfolio Kanban, WSJF from the agreed inputs, WIP limits (Little's Law), dependency DAG, OKR links
2. **Pull loop:** when Implementing WIP < limit, pull the highest-WSJF backlog epic whose dependencies are done and dispatch `/engineer "<epic>"` at the epic lane. That epic runs its own dialogue.
3. On each epic `done`: record for **delivery-metrics**; consume its **outcome-review** decision (`kill` frees WIP and lowers follow-on cost of delay; `persevere` raises it). Never exceed the WIP limit to get ahead.

---

### EPIC lane

Footprint: most skills · epic manifest + N child manifests · days–weeks.

**First:** epic manifest (`dialogue: full`). Every gate below is hard-blocking.

**DISCUSS** — all agenda topics (a)–(i) through `senior-dialogue`, with teach-back on one-way doors:
1. (a) current state · (b) business context via **business-context-intake**'s territory · (c) HLD via **high-level-design**'s questions and analyses (C4, STRIDE, failure modes, capacity) · (d) LLD · (e) CI/CD · (f) deployment · (g) observability · (h) test scenarios with `test-scenario-reviewer` · (i) construction approach
2. If any critical-core invariant is `fv-eligible`, name it in (c) as proof-worthy or test-worthy. The spec-to-proof boundary is an architectural decision, and children inherit the `formal-verification` step.
3. `check` exits 0 → manifest `phase: build`

**BUILD**
4. Documents from the record: business context, spec, HLD + ADRs, LLD, test-scenario matrix, user and developer docs. Then **spec-quality-gate** and **hld-reviewer** run autonomously.
5. **epic-decomposition** — child manifests cite the parent's agreed cards; parallel vs sequential waves
6. **service-scaffolding** *(⊘ service-scaffolding-reviewer)* — new services only, before children build into them
7. **For each child story:** `/engineer "<story>"` at the task lane. The child's dialogue covers only decisions the parent did not already agree.
8. **deployment-workflow** *(⊘ deployment-reviewer)* · 9. **observability-standards** *(⊘ observability-reviewer)* · 10. **incident-response**
11. **production-readiness-review** *(⊘ production-readiness-reviewer)* — **go/no-go is a human decision card**, hard gate before first production traffic. For an `fv-eligible` core, the proof verdict is evidence; an undischarged obligation blocks launch.
12. **onboarding-guide** · 13. **delivery-metrics** · 14. **outcome-review** *(⊘ outcome-review-reviewer)* — persevere/iterate/kill is presented as a card

---

### RESEARCH lane

Footprint: ~5 skills · decision artifact · hours. No production commits.

**DISCUSS** — (a) current state and (b) the question and what a good answer
changes; D-000 includes the time box and the spike plan.
**BUILD**
1. **research-spike** — time-boxed investigation on a throwaway `spike/<topic>` branch
2. The recommendation card → ledger. The ADR is written `Accepted` only if that card is agreed, otherwise `Proposed`.
3. Output: `.ai/YYYY-MM-DD-<topic>-findings.md` or `wiki/architecture/YYYY-MM-DD-<topic>-adr.md`

If the spike expands into implementation, STOP and re-invoke `/engineer "<task>"` with the decision as context.

---

### REFACTORING lane

Footprint: ~4 skills · `dialogue/` only · hours. Zero new behavior.

**Hard gate:** the external contract (callers, return values, error behavior) is identical before and after. If a caller must change, it is a task.

**DISCUSS**
1. Name the smell (god class / duplication / deep nesting / long method / tight coupling / dead code / primitive obsession)
2. **codebase-comprehension** (inline) — target symbols, callers, `codegraph_impact`, covering tests
3. Test baseline — run the covering tests now; any failure → STOP, `systematic-debugging` in a separate lane
4. D-000 card: smell, move sequence, baseline result → ledger

**BUILD**
5. **refactoring** — one structural move per micro-commit, tests green after each
6. **verification-before-completion** — lint gate
7. **commit-discipline** — WHY body: which smell was removed and why the new shape is better

A bug found mid-refactor: commit progress, open a quick-fix lane (its own D-000), then resume.

---

## Session model per lane

| Lane | Launch on | Why |
|------|-----------|-----|
| quick-fix, refactoring, task | Sonnet | judgment work is in pinned-model subagents; orchestration is thin |
| epic design phases (dialogue, HLD) | Opus | these reason in the main session and cannot be offloaded |
| portfolio | Sonnet | Kanban bookkeeping + dispatch is thin; each epic picks its own launch model |
| research | Sonnet; Opus for hard trade-offs | spike judgment is sometimes deep |

Named subagents ignore the chat model (their frontmatter `model:` is pinned).

## Universal constraints (every lane, always active)

- **Consent floor:** no code, tests, final docs, or commits before D-000 is agreed in the ledger. In BUILD, a human is needed again only for (1) a finding or discovery that would change an agreed decision (one new card, asked alone), (2) a BLOCKED subagent, (3) a spend breach, or (4) the decisions the lane itself marks as human cards (PRR go/no-go, outcome-review). Mechanical gate FAILs are fixed without asking.
- **Downstream approval asks are pre-satisfied:** the human-approval steps in `business-context-intake`, `brainstorming`, `high-level-design`, `api-contract-first`, and `writing-plans`' execution choice are satisfied by a passing consent `check` on the cards the artifact cites. Skip them; choose subagent-driven execution.
- **Evidence and reasoning:** every recommendation in DISCUSS carries citations and, where a quantity is involved, numbers derived for this case with their basis (`senior-dialogue` → `references/decision-cards.md`).
- **karpathy lens:** surgical changes, no over-build, verifiable success criteria
- **design-principles:** SOLID, DRY, YAGNI applied during construction
- **pr-review-non-negotiables:** every review dispatch in every lane — `requesting-code-review`, SDD's task reviewer, `giving-code-review`, or an external tool like `scout-pr-review` — carries the global gate (backward compat, migration, performance, reuse, testing, security, why/ROI, UX, determinism, over/underengineering, compatibility matrix). It is standing, not a dimension the reviewer chooses.
- **Review discipline:** pattern propagation on accepted findings, zero negotiable review rounds, and the proportionality gate. Read `references/review-discipline.md` before acting on any review finding.
- **Never auto-continue past BLOCKED** or a FAIL that would change an agreed decision; surface it and wait.
- **Manifest updated at each phase transition** (task/epic lanes): `discuss → build → plan → construct → verify → deliver → done`, or `parked`.
- **Cost checkpoints, spend circuit breaker, per-subagent attribution:** mandatory around every numbered step and every named-subagent dispatch. Read `references/cost-ledger.md` at lane start and follow it.
- **Domain overlay:** when the files or task match a recognized technology domain (Android/Kotlin/Compose/KMP — `.kt`/`.kts`, `build.gradle(.kts)`, `@Composable`, `androidx.*`), activate the matching `<domain>-advisor` overlay (e.g. `android-advisor`) FIRST inside each construct/test/verify step. See `domain-overlay`.
- **Formal-verification gate (conditional):** when `fv-eligible` is set, `formal-verification` is standing at task step 8a and in every eligible child story, and its verdict feeds the epic PRR. Off by default; a critical-core in an unverifiable language routes to `property-based-testing`/`deterministic-simulation-testing`. A proof never replaces the review gate. Bounded results (C++) state their bound.
- **Skill not named above:** invoke `using-superpowers` to find the right one before improvising.
- **Artifact-by-reference:** each phase writes its output to a file and records the path in the manifest; hold only the manifest pointer, the ledger status, and the current phase in context.
- **Manifest and ledger are the source of truth:** read phase and agreement state from `.ai/<id>/manifest.md` and the consent `status`, not from memory. Both survive compaction.
- **Verdict-only returns:** gates and reviewers return `PASS|FAIL` plus a REPORT_FILE path; never paste their findings into the orchestrator.
- **After each phase:** tell the user "phase complete — safe to /compact; the manifest and ledger hold state."
- **Completion report (every step that produces work):** one line each: what was produced, where (path), the reviewer verdict if a gate ran, what's next.
