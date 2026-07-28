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

**Max 2 re-run cycles.** Do not loop beyond this.

- **Cycle 0** — initial run. Present all failures to author.
- **Cycle 1** — re-run after author fixes Cycle 0 failures. Present remaining.
- **Cycle 2** — re-run after Cycle 1 fixes. If still failing, output a **Persistent Failures** report and stop. Escalate to human review.

A spec that cannot pass in 2 fix cycles has a design problem the gate cannot resolve.

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review

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

Wait for author to fix all blocking failures in the spec file.

### Step 4 — Re-run (if needed)

Re-run Step 0's pre-lint first — if it now fails on a different mechanical finding, fix that before spending another Opus call. Once pre-lint is clean, re-dispatch `spec-quality-reviewer` with the same `SPEC_PATH`. Increment cycle counter. Stop at Cycle 2 regardless of result — escalate persistent failures to human.

### Step 5 — Transition

On PASS:
- For architectural changes (new services, data models, external integrations, security boundaries): invoke `high-level-design` skill.
- For non-architectural changes (bug fixes, config, isolated utilities): invoke `writing-plans` skill.

On FAIL after Cycle 2: present the **Persistent Failures** block. Do not proceed. The spec needs human-level design intervention.

## Integration

Two gates in the lifecycle:

1. **Spec gate** (this skill): after `brainstorming` writes spec, before `high-level-design` or `writing-plans` starts.
2. **Traceability gate**: after implementation, before merge. Every public construct annotated `@spec_id SPEC-N @req_id REQ-NNN`. Every test annotated `@spec_id SPEC-N @validates_req REQ-NNN`. Run via `pr-reviewer` agent or `spec-impl-reviewer` agent.
