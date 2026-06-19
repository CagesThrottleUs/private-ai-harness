# Conveyor-Belt Routing — Engineering Entry Point
**Date:** 2026-06-19
**Status:** Approved for implementation

## Problem Statement

The harness contains 44 skills covering all 5 phases of engineering work but has no front door. Engineers must self-assess complexity and manually invoke the right skill chain. `subagent-driven-development` proves the belt pattern works — orchestrator-workers + evaluator-optimizer + file handoffs + durable ledger — but it runs for Phase 3 only. The rest of the line is hand-carry.

Fix = extend the proven pattern to the full line via a router + 4 new skills. Not green-field.

## Requirements

### REQ-001 — Single entry point
The harness SHALL provide `/engineer` as a single entry point accepting free-text requests.

**Acceptance criteria:**
- TC-001a: Invoking `/engineer "<request>"` classifies the request into one of four lanes: quick-fix, task, epic, research.
- TC-001b: The router outputs its classification with explicit reasoning signals before starting any work.
- TC-001c: The router waits for explicit user confirmation before invoking any skill.
- TC-001d: On user modification or denial, the router adjusts the plan and re-presents.

### REQ-002 — Lane classification by observable signals
The router SHALL classify using concrete signals, not vague heuristics.

**Acceptance criteria:**
- TC-002a: Defect/bug/typo + single function → quick-fix.
- TC-002b: Bounded feature extending existing patterns, no new service → task.
- TC-002c: New service/system, new data model, external integration, PII/auth → epic.
- TC-002d: "spike"/"POC"/"feasibility"/"compare"/"design doc"/"evaluate" keyword → research.
- TC-002e: Ambiguous signals → router asks ONE clarifying question before classifying.

### REQ-003 — Codebase comprehension as universal Step 1
Every lane SHALL begin with codebase comprehension before any code change.

**Acceptance criteria:**
- TC-003a: Comprehension uses codegraph/scout structural tools, not grep.
- TC-003b: Quick-fix: inline (1–3 tool calls). Task/epic: produces `.ai/work/<id>/comprehension.md`.
- TC-003c: User can correct comprehension before proceeding.

### REQ-004 — Four lane skill chains

**Quick-fix (TC-004a):** karpathy → systematic-debugging → codebase-comprehension (inline) → TDD → verification-before-completion → commit-discipline. Design phase skipped. No manifest.

**Task (TC-004b):** codebase-comprehension → brainstorming → spec-quality-gate → writing-plans → using-git-worktrees → subagent-driven-development → verification-before-completion → requesting-code-review → pr-creator → finishing-a-development-branch. Creates work-item manifest.

**Epic (TC-004c):** business-context-intake → brainstorming → spec-quality-gate → high-level-design → epic-decomposition → [each child: task lane recursively] → deployment-workflow → observability-standards → incident-response → onboarding-guide. Creates epic manifest + N child manifests. Human must approve HLD before epic-decomposition fires.

**Research (TC-004d):** codebase-comprehension → research-spike → decision artifact. No production commits.

### REQ-005 — Work-item manifest (task and epic lanes)
**Acceptance criteria:**
- TC-005a: Manifest at `.ai/work/YYYY-MM-DD-<slug>/manifest.md`.
- TC-005b: Contains: `{tier, current_phase, gate_status, artifact_links}`.
- TC-005c: Each phase transition updates manifest status.

### REQ-006 — Confirmation gate (hard constraint)
**Acceptance criteria:**
- TC-006a: Router presents: detected lane, reasoning signals, skill chain, skip-set.
- TC-006b: Router asks "Confirm?" and waits. No skill fires before confirmation.
- TC-006c: Any modification request → adjust + re-present before proceeding.

### REQ-007 — Research lane produces decision artifact, no production code
**Acceptance criteria:**
- TC-007a: Output artifact at `.ai/YYYY-MM-DD-<topic>-findings.md` or `wiki/architecture/` ADR.
- TC-007b: Spike code lives in throwaway branch, deleted after spike closes.
- TC-007c: Spike expanding into implementation → STOP, re-invoke `/engineer` as task.

### REQ-008 — Epic decomposition produces child manifests + dependency graph
**Acceptance criteria:**
- TC-008a: Each story maps to one independently testable slice.
- TC-008b: Dependency graph identifies waves: parallel stories in same wave, sequential across waves.
- TC-008c: Interface artifacts (schema, API contract) committed before dependent story starts.

## Non-Goals
- Not a runtime scheduler — prompt convention, not a process engine
- Not replicating individual skill logic inside the router
- Not automatic execution without human confirmation (REQ-006 is hard)

## Dependencies
**Existing skills used:** subagent-driven-development, brainstorming, spec-quality-gate,
writing-plans, systematic-debugging, verification-before-completion, commit-discipline,
TDD, using-git-worktrees, pr-creator, requesting-code-review, finishing-a-development-branch,
business-context-intake, high-level-design, karpathy, design-principles,
deployment-workflow, observability-standards, incident-response, onboarding-guide.

**New skills (this feature):** engineer (router), codebase-comprehension, research-spike,
epic-decomposition.
