---
name: spec-quality-gate
description: Use when a spec has been written and must be validated before implementation planning begins — checks requirements are testable, measurable, dependency-covered, and logically complete
---

# Spec Quality Gate

Linter for specs. Run after brainstorming writes the spec, before writing-plans starts.

**Core principle:** A spec that passes human review but fails the quality gate is not a spec — it is a wish list.

## The Iron Law

```
NO PLAN WITHOUT A PASSING QUALITY GATE FIRST
```

If the gate fails, fix the spec. Do not proceed to writing-plans.

## Gate Execution Order

Run deterministic checks first (mechanical, no judgment). Then run structural checks. Then run logic checks. Report all failures before asking for fixes.

---

## 1. Deterministic Checks (automated — run these first)

Search the spec file for each pattern. Flag every match.

### 1a. Vague / Emotional Language (ZERO TOLERANCE)

```bash
# Run against spec file — any match = FAIL
grep -niE \
  "tbd|todo|somehow|appropriate(ly)?|intuitive|clean|nice|good performance|fast enough|user.?friendly|should work|seamless|simple(ly)?|obvious|easy to use|high.?quality" \
  <spec-file>
```

Every match is a blocking failure. Replace with a measurable criterion.

**Examples of forbidden → required rewrites:**

| Forbidden | Required |
|-----------|---------|
| "must be fast" | "p99 latency < 200ms under 100 concurrent requests" |
| "should be intuitive" | "new user completes task X without documentation in < 3 minutes" |
| "good error handling" | "all error paths return structured error with code, message, and retry hint" |
| "TBD" | Specific value or explicit deferral with rationale |

### 1b. Requirement ID Coverage

Every requirement block must start with `REQ-NNN:`. Count IDs and verify sequential, no gaps.

```bash
grep -c "^### REQ-[0-9]" <spec-file>   # count
grep "^### REQ-[0-9]" <spec-file>       # list — check for gaps
```

### 1c. Mandatory Subsections Per Requirement

Each `### REQ-NNN` block must contain all four:

```bash
# For each REQ block, verify presence of:
# - "**Statement:**"
# - "**Acceptance Criteria:**"
# - "**Dependencies:**" (may be "None" explicitly)
# - "**Test Cases:**"
```

Missing any subsection = FAIL for that REQ.

### 1d. Test Coverage Matrix Present

```bash
grep -c "## Test Coverage Matrix" <spec-file>
```

Must be exactly 1. Missing = FAIL.

### 1e. Out of Scope Section Present

```bash
grep -c "## Out of Scope" <spec-file>
```

Must be exactly 1. Missing = FAIL. Empty = FAIL.

---

## 2. Structural Checks (judgment required)

### 2a. Acceptance Criteria Are Measurable

For every acceptance criterion line (`- [ ]`), verify it contains at least one of:
- A number, threshold, or count (e.g., `< 200ms`, `>= 99.9%`, `exactly 3 retries`)
- A binary condition with specific inputs and outputs (e.g., "returns HTTP 401 when token is expired")
- A reference to a deterministic comparison (e.g., "output matches fixture in `tests/fixtures/expected.json`")

Criteria that are purely qualitative → FAIL.

### 2b. Dependency Assumed Behaviors

Every entry in a `**Dependencies:**` table must have a non-empty "Assumed Behavior" column. "N/A" is acceptable only for internal utilities with no external surface. "Assumed to work" is NOT acceptable.

**Good:**
```
| Redis | Returns cached value within 1ms on hit; returns nil on miss |
```

**Bad:**
```
| Redis | Assumed to work |
```

### 2c. Test Cases Are Named, Not Generic

Every `- TC-` entry must have a descriptive name (not "test case 1", "happy path").

### 2d. No Orphaned Test Cases

Every test case ID in the Test Coverage Matrix must appear in exactly one `REQ-NNN` block's Test Cases list. Orphaned TCs (in matrix but not in a REQ) = FAIL.

---

## 3. Logic Checks

### 3a. Dependencies Have Their Own REQs or Are External

If a dependency is internal (a component in this system), it must have its own `REQ-NNN` block. If external, it must appear in the Assumptions table.

### 3b. Requirements Are Independent

Each REQ must be implementable without implementing all other REQs simultaneously. If REQ-003 can only be tested after REQ-001 and REQ-002 are complete, mark it explicitly:

```
**Depends on:** REQ-001, REQ-002
```

### 3c. Requirements Are Complete — No Implicit Behavior

If the spec says "returns user data on success", it must also specify what happens on failure. Every happy path REQ must have a corresponding error/edge REQ or explicitly state "error handling covered by REQ-NNN".

---

## Output Format

```
## Spec Quality Gate Report
**Spec:** <path>
**Date:** YYYY-MM-DD
**Status:** PASS | FAIL

### Deterministic Failures (N)
- [REQ-NNN / Section]: [exact failing text] → [required fix]

### Structural Failures (N)
- [REQ-NNN]: [description of structural gap]

### Logic Failures (N)
- [description]

### Warnings (advisory, non-blocking)
- [observation]

**Action required:** Fix all FAIL items. Re-run gate. Only proceed to writing-plans on PASS.
```

Save report to `.ai/reports/YYYY-MM-DD-<feature>-quality-gate.md`.

---

## Common Failures

| Failure | Fix |
|---------|-----|
| "TBD" in acceptance criteria | Decide now or mark REQ as out of scope |
| No test cases in REQ block | Name at least two TCs: happy path + error case |
| Dependency with no assumed behavior | Write exact contract this requirement depends on |
| Acceptance criterion is "user can do X easily" | Rewrite with a time limit, success rate, or error count |
| Missing Out of Scope section | Add explicit exclusions — what someone might assume is in scope |
| REQ with no acceptance criteria | Every REQ needs ≥ 1 measurable criterion |

## Red Flags — Do NOT Approve

- "We'll figure out the metrics later"
- "This is obvious" (if it's obvious, state it explicitly)
- "The dependency works as expected" (expected by whom? state it)
- Acceptance criteria that an AI or human could disagree on without more data
- Test cases named "test1", "happy path", "edge case"

## Integration

Run after `brainstorming` writes spec, before `writing-plans` starts.

```dot
digraph gate_position {
    "brainstorming writes spec" [shape=box];
    "spec-quality-gate" [shape=box style=filled fillcolor=lightyellow];
    "spec-quality-gate passes?" [shape=diamond];
    "fix spec" [shape=box];
    "writing-plans" [shape=box];

    "brainstorming writes spec" -> "spec-quality-gate";
    "spec-quality-gate" -> "spec-quality-gate passes?";
    "spec-quality-gate passes?" -> "fix spec" [label="FAIL"];
    "fix spec" -> "spec-quality-gate" [label="re-run"];
    "spec-quality-gate passes?" -> "writing-plans" [label="PASS"];
}
```
