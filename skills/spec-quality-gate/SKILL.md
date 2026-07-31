---
name: spec-quality-gate
description: Use when a spec has been written and must be validated before implementation planning begins — dispatches spec-quality-reviewer agent, handles re-run cycles, and gates progression to high-level-design or writing-plans on PASS.
---

# Spec Quality Gate

Thin orchestrator. The actual review logic lives in the `spec-quality-reviewer` agent, which runs with fresh context and no brainstorming drift.

## The Iron Law

```
NO PLAN WITHOUT A PASSING QUALITY GATE FIRST
```

## Inputs Required

- **Spec path:** `.ai/specs/YYYY-MM-DD-<feature>.md` — the file brainstorming just wrote

If no spec path is known, check `.ai/specs/` for the most recent file. If ambiguous, ask the human.

## Convergence Rule

**Loop until PASS.** No fixed cycle cap — matches every other reviewer-dispatching skill in this harness (`repeat until PASS`, see Reviewer Dispatch Discipline below).

- Each re-run: re-dispatch `spec-quality-reviewer` against the fixed spec. Present remaining failures to the author.
- Escalate to human only on genuine non-convergence — a re-run returns the SAME failure the author already attempted to fix, with no forward progress. That is a design problem the gate cannot resolve; a cycle count cannot detect it and an arbitrary cap would either stop short of a fixable spec or let a stuck one loop forever.

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review
- Pattern check before re-dispatch: does this finding's pattern recur elsewhere in the artifact? Fix every occurrence in the same pass — a finding that resurfaces next cycle in a new spot is the cost this discipline exists to cut

## Execution

### Step 0 — Mechanical Pre-Lint (zero LLM cost)

Run before dispatching the agent, every cycle:

```bash
bash skills/spec-quality-gate/scripts/pre-lint.sh .ai/specs/YYYY-MM-DD-<feature>.md
```

This is a deterministic pass over the exact Section 1 (format) checks the agent runs first, plus the Section 4 placeholder scan. If it exits non-zero, the agent will fail on the identical grounds — fix the reported findings and re-run the script until it exits 0 before spending any Opus tokens. Do not dispatch the agent while this script is failing.

### Step 1 — Dispatch Agent

```
Agent(spec-quality-reviewer, {
  SPEC_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md"
})
```

### Step 2 — Present Report

Show the full report to the author. Do not summarize or soften findings. Every blocking failure must be visible.

### Step 3 — Author Fixes

Wait for author to fix all blocking failures in the spec file. For each finding, check whether its pattern recurs elsewhere in the spec (a vague term flagged in REQ-3 was likely copy-pasted into REQ-7) and fix every occurrence in the same pass — a finding that resurfaces next cycle in a new section is the cost this rule exists to cut.

### Step 4 — Re-run (loop until PASS)

Re-run Step 0's pre-lint first — if it now fails on a different mechanical finding, fix that before spending another Opus call. Once pre-lint is clean, re-dispatch `spec-quality-reviewer` with the same `SPEC_PATH`. Repeat Steps 2-4 until PASS. Stop and escalate only on genuine non-convergence (see Convergence Rule) — never on a cycle count.

### Step 5 — Transition

On PASS:
- For architectural changes (new services, data models, external integrations, security boundaries): invoke `high-level-design` skill.
- For non-architectural changes (bug fixes, config, isolated utilities): invoke `writing-plans` skill.

On genuine non-convergence: present the **Persistent Failures** block. Do not proceed. The spec needs human-level design intervention.

## Integration

Two gates in the lifecycle:

1. **Spec gate** (this skill): after `brainstorming` writes spec, before `high-level-design` or `writing-plans` starts.
2. **Traceability gate**: after implementation, before merge. Every public construct annotated `@spec_id SPEC-N @req_id REQ-NNN`. Every test annotated `@spec_id SPEC-N @validates_req REQ-NNN`. Run via `pr-reviewer` agent or `spec-impl-reviewer` agent.
