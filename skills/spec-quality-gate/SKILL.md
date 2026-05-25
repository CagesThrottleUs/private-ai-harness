---
name: spec-quality-gate
description: Use when a spec has been written and must be validated before implementation planning begins — checks requirements are testable, measurable, dependency-covered, logically complete, design-correct, and self-consistent
---

# Spec Quality Gate

Design reviewer for specs. Run after brainstorming writes the spec, before writing-plans starts.

**Extended principle:** The gate must prove the spec is the contract, code is the implementation of the contract. Ensure that spec is not a wish list or vague in nature.

## References — What a Great Spec Looks Like

These are the north star. When evaluating a spec, ask: *does this meet this bar?*

**SQLite** — [requirements.html](https://sqlite.org/requirements.html)
Every requirement has a test ID. Test suite is 8× larger than the implementation. Richard Hipp's rule: if it's not tested, it doesn't exist. Every statement is immediately testable.

**RFC 8446 (TLS 1.3)** — IETF RFC format
Every state, every transition, every error condition named. Implementable from the doc alone. The MUST/SHOULD/MAY taxonomy forces every statement to be universal truth or verifiable behavior.

**seL4 microkernel** — NICTA/Data61
Spec written in Isabelle/HOL. Mathematically proven correct. If the proof compiles, the code is correct by construction. Ultimate form of the contract idea.

**WebAssembly specification** — W3C
Every instruction has formal reduction rules. No ambiguity possible. Multiple independent implementations converged on identical behavior from the spec alone.

**DO-178C** — aviation flight software standard
Every requirement traced to a test, every test traced to a requirement. No orphans. Traceability matrix is a mandatory deliverable.

## North Star

> **Every statement in a spec is either a universal truth (an axiom) or something that can be immediately falsified by a test.**

Nothing in between. No statement survives if a reasonable engineer could disagree on whether it is satisfied without running a test.

When this standard is met, the resulting code tends to be provably correct at the boundaries that matter, maintainable by engineers who weren't there when it was written, and durable across refactors because the contract is explicit.

The checks below are the floor. The north star is the ceiling. Use it as the lens for every judgment call.

## The Iron Law

```
NO PLAN WITHOUT A PASSING QUALITY GATE FIRST
```

## Convergence Rule

**Max 2 re-run cycles.** Do not loop beyond this.

- **Cycle 0** — initial run. Report all failures.
- **Cycle 1** — re-run after author fixes Cycle 0 failures. Report remaining.
- **Cycle 2** — re-run after Cycle 1 fixes. If still failing, output a **Persistent Failures** report and stop. Escalate to human review.

A spec that cannot pass in 2 fix cycles has a design problem the gate cannot resolve.

## Gate Execution Order

Read the spec. Report ALL failures before asking for fixes.

1. Format checks — mechanical, verify presence and structure
2. Quality checks — judgment against the north star
3. Consistency checks — verify the spec is a closed system

---

## Spec Identity

Every spec file must begin with YAML frontmatter:

```markdown
---
spec_id: SPEC-N
title: <title>
status: draft | approved
---
```

`spec_id` is the root of the traceability chain:
```
SPEC-N → REQ-NNN → @spec_id + @req_id (code) → @spec_id + @validates_req (tests)
```

`SPEC-N` where N is a positive integer, no zero-padding. Missing or malformed = blocking failure.

---

## 1. Format Checks

Verify each. Every missing item is a blocking failure.

**1a.** Frontmatter has valid `spec_id: SPEC-N`

**1b.** Every requirement block starts with `### REQ-NNN:` — sequential, no gaps, no duplicates

**1c.** Every REQ block contains all four subsections:
- `**Statement:**` — what the system must do
- `**Acceptance Criteria:**` — measurable conditions for done
- `**Dependencies:**` — explicit list or "None"
- `**Test Cases:**` — named TCs, not empty, not "TBD"

**1d.** `## Test Coverage Matrix` section exists, mapping every TC to its REQ

**1e.** `## Out of Scope` section exists with at least one explicit exclusion

---

## 2. Quality Checks

For each REQ, apply the north star: *can this statement be proven true or false by running a test?*

**Scope rule:** These checks evaluate spec requirements and acceptance criteria only. A TC is evidence against an AC — it is not itself an AC requiring further coverage. Adding TCs to satisfy one check does not trigger re-evaluation of those TCs under remaining checks.

### 2a. Every Statement and AC Is Falsifiable

A statement passes if a deterministic test can prove it true or false. Fails if:

- Language is vague: `TBD`, `intuitive`, `fast enough`, `user-friendly`, `clean`, `seamless`, `appropriate`, `should work`, `simple`, `easy`, `nice`, `obvious`, `high-quality`
- A reasonable engineer could disagree on whether it is satisfied without running a test
- No threshold, binary outcome, or reference to a deterministic artifact

| Failing | Passing |
|---------|---------|
| "must be fast" | "p99 latency < 200ms under 100 concurrent requests" |
| "good error handling" | "all error paths return `{code, message, retry_hint}`" |
| "should be intuitive" | "new user completes task X without docs in < 3 min" |
| "TBD" | specific value, or explicit deferral with rationale in Out of Scope |

### 2b. Every AC Has at Least One TC That Would Fail If the AC Were Violated

For each AC line, a TC must exist that:
- States its inputs
- States its exact expected output, matching the AC's measurable condition
- Would produce a different result if the implementation violated the AC

A TC that asserts only "operation completed" or "no error" without checking the actual output is not a test — it is a green light with no signal. Mark FAIL.

### 2c. Every TC Is Honest

Ask: *if the implementation were subtly wrong — off-by-one, inverted condition, wrong error code, missing field — would this TC catch it?*

If no: the TC is a phantom. State what specific assertion makes it real.

### 2d. Every Error Path Is Owned

Every failure mode, error condition, or edge case mentioned anywhere in the spec must be:
- Handled by a REQ that specifies exact behavior, or
- Listed in Out of Scope with a rationale

An error path that falls through to unspecified behavior = FAIL.

---

## 3. Consistency Checks

### 3a. No Contradictions

No two REQs specify conflicting behavior for the same input. No AC in one REQ undercuts an AC in another.

### 3b. Terms Defined Once, Used Consistently

Every domain term, role, or concept is defined exactly once. No term carries two meanings across REQs.

### 3c. Every Dependency Named

Every external system, API, service, or component the spec depends on appears in a Dependencies table with its assumed behavior stated exactly. "Assumed to work" is not an assumed behavior.

### 3d. Out of Scope Is Clean

No item listed in Out of Scope appears in any requirement. If it has a footprint in a REQ, it is in scope — move it to a requirement.

---

## Output Format

```
## Spec Quality Gate Report
**Spec:** <path>
**Date:** YYYY-MM-DD
**Status:** PASS | FAIL
**North Star:** Every statement is either a universal truth or immediately falsifiable by a test.

### Format Failures (N)
- [check]: [what is missing or malformed]

### Quality Failures (N)
- [REQ-NNN / 2a]: AC "<text>" — vague; rewrite as [specific measurable form]
- [REQ-NNN / 2b]: AC "<text>" — no TC exercises it; or TC "<id>" passes against a wrong implementation
- [REQ-NNN / 2c]: TC "<id>" — asserts [what]; would not catch [specific wrong implementation]
- [REQ-NNN / 2d]: error path "<description>" — not handled in any REQ and not in Out of Scope

### Consistency Failures (N)
- [3a]: REQ-NNN and REQ-MMM contradict on [specific condition]
- [3b]: term "<word>" used with different meanings in REQ-NNN and REQ-MMM
- [3c]: "<dependency>" used but not named; assumed behavior not stated
- [3d]: Out of Scope item "<name>" has footprint in REQ-NNN

### Warnings (advisory, non-blocking)
- [something that passes the checks but does not meet the north star]

**Action required:** Fix all FAIL items. Re-run gate. Only proceed to writing-plans on PASS.
```

Save report to `.ai/reports/YYYY-MM-DD-<feature>-quality-gate.md`.

---

## Integration

Two gates:

1. **Spec gate** (Sections 1–3): After `brainstorming` writes spec, before `writing-plans` starts.
2. **Traceability gate**: After implementation, before merge. Every public construct annotated `@spec_id SPEC-N @req_id REQ-NNN`. Every test annotated `@spec_id SPEC-N @validates_req REQ-NNN`. Run via `pr-reviewer` agent or manually.
