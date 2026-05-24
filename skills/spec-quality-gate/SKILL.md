---
name: spec-quality-gate
description: Use when a spec has been written and must be validated before implementation planning begins — checks requirements are testable, measurable, dependency-covered, logically complete, design-correct, and self-consistent
---

# Spec Quality Gate

Linter + design reviewer for specs. Run after brainstorming writes the spec, before writing-plans starts.

**Core principle:** A spec that passes human review but fails the quality gate is not a spec — it is a wish list.

**Extended principle:** The gate must prove the spec is *self-consistent and complete*, not just well-formatted. A spec with correct structure but wrong design is still a failing spec.

## The Iron Law

```
NO PLAN WITHOUT A PASSING QUALITY GATE FIRST
```

If the gate fails, fix the spec. Do not proceed to writing-plans.

## Gate Execution Order

Run all sections in order. Report ALL failures across all sections before asking for fixes.

1. Deterministic checks (mechanical, no judgment)
2. Structural checks (judgment on form)
3. Logic checks (judgment on completeness)
4. Design completeness checks (judgment on correctness)
5. Self-consistency checks (judgment on closure)
6. Code traceability checks (post-implementation only)

---

## Spec Identity

Every spec file must begin with a YAML frontmatter block assigning a globally unique `spec_id`.

**Format:** `SPEC-N` (no zero-padding, e.g., `SPEC-1`, `SPEC-42`)

```markdown
---
spec_id: SPEC-1
title: User Authentication
status: approved
---
```

`spec_id` is the root of the traceability chain:
```
SPEC-N → REQ-NNN → @spec_id + @req_id (code) → @spec_id + @validates_req (tests)
```

---

## 1. Deterministic Checks (automated — run these first)

Search the spec file for each pattern. Flag every match.

### 1a. Vague / Emotional Language (ZERO TOLERANCE)

```bash
grep -niE \
  "tbd|todo|somehow|appropriate(ly)?|intuitive|clean|nice|good performance|fast enough|user.?friendly|should work|seamless|simple(ly)?|obvious|easy to use|high.?quality" \
  <spec-file>
```

Every match is a blocking failure. Replace with a measurable criterion.

| Forbidden | Required |
|-----------|---------|
| "must be fast" | "p99 latency < 200ms under 100 concurrent requests" |
| "should be intuitive" | "new user completes task X without documentation in < 3 minutes" |
| "good error handling" | "all error paths return structured error with code, message, and retry hint" |
| "TBD" | Specific value or explicit deferral with rationale |

### 1b. Requirement ID Coverage

Every requirement block must start with `REQ-NNN:`. Count IDs and verify sequential, no gaps.

```bash
grep -c "^### REQ-[0-9]" <spec-file>
grep "^### REQ-[0-9]" <spec-file>
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

### 1f. spec_id Present and Valid Format

```bash
head -10 <spec-file> | grep -E "^spec_id: SPEC-[1-9][0-9]*$"
```

Missing or malformed spec_id = FAIL. Valid: `SPEC-1`, `SPEC-42`. Invalid: `SPEC-001`, `spec-1`, `SPEC-0`.

### 1g. spec_id Globally Unique

```bash
grep -rh "^spec_id:" .ai/specs/ | sort | uniq -d
```

Any duplicate = FAIL. Each spec must have a unique SPEC-N that is never reused, even after a spec is retired.

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

## 4. Design Completeness Checks

These catch design holes that pass structural review but represent incomplete thinking: unclassified capabilities, unjustified constants, missing observability requirements, uncovered delivery channels, uninventoried external interfaces, namespace violations, and unmotivated conditional logic. A spec can be perfectly formatted and still be designwise incomplete. These checks close that gap.

### 4a. Every Capability Must Be Classified as NEW or EXTENDING

For every feature, interface point, configuration option, or behavior the spec introduces:

- **NEW** — did not exist before this spec. Must include a one-sentence rationale for why it is being added.
- **EXTENDING** — modifies or builds on something that already exists. Must name the existing thing it extends.

A capability with no classification = FAIL.

**Deferred-but-present is not a valid classification.** Any element described as "reserved", "coming soon", or "implementation deferred" must be removed from the requirements entirely and placed in Out of Scope. If it has no implementation plan in this spec, it has no presence in this spec's requirements or interface surface.

### 4b. Non-Obvious Constants Require Justification

Every constant value in the spec — timeout, limit, retry count, size, rate, version number, threshold — that is not directly derivable from an industry standard, regulation, or existing project convention must cite its basis in an inline parenthetical.

**Bad:** "Request must complete within 10 seconds."

**Good:** "Request must complete within 10 seconds (matches the existing probe timeout established for all network operations in this system; see `<reference>`)."

Acceptable bases: measured benchmark, matching an existing system constant, cited standard or RFC, stated constraint from a stakeholder, hardware/platform limit. "Reasonable", "standard practice", or "industry norm" without a citation = FAIL.

### 4c. Every Observable Change Requires a Documentation Requirement

Any change the spec introduces that is visible outside the system boundary — new configuration option, new API field or endpoint, new error code, new log format, new metric, changed behavior of existing interface, new user-facing message — must have a corresponding REQ that covers updating the relevant documentation surface (API reference, user guide, changelog, operational runbook, inline help text, migration guide).

Test: for each observable change introduced, is there a REQ whose statement explicitly names a documentation artifact to be updated? If not = FAIL for that change.

This applies regardless of how small the change is. A new exit code with no documentation REQ is incomplete.

### 4d. All Delivery Channels Must Be Covered or Explicitly Excluded

Any spec that modifies how users acquire, activate, upgrade, configure, or remove the system must enumerate every supported delivery channel from the project's own documentation (README, install guide, release notes). Each channel must either:

- Have explicit handling in a REQ, or
- Appear in Out of Scope with a rationale.

A channel that falls through to an unspecified error state without being named = FAIL.

To enumerate channels: read the project's installation documentation before writing the spec. Do not rely on the spec author's knowledge. If the documentation lists it, the spec must account for it.

### 4e. External Interfaces Must Be Inventoried

Any interface the spec crosses outside the system's own process boundary — external API call, OS-level command, filesystem operation, database query, network request, inter-process communication, third-party service, hardware interface — must be inventoried in the relevant REQ's Dependencies table or a dedicated `**External Interfaces:**` section with:

- **Availability**: what environments, platforms, or versions provide this interface
- **Failure modes**: what the spec does when the interface is unavailable, slow, or returns unexpected output
- **Platform alternatives**: if the interface is not universally available, name the equivalent for each unsupported environment, or explicitly exclude that environment in Out of Scope

An interface that is used in a REQ but not inventoried = FAIL. An interface that is platform-specific without a named alternative or explicit exclusion = FAIL.

### 4f. Shared-Namespace Identifiers Must Follow Conventions and Be Conflict-Free

Any identifier introduced into a shared namespace — environment variable, configuration key, feature flag, API endpoint path, event or message type name, database column, metric name, log field — must:

1. Follow the project's established naming convention for that namespace (check the project's contribution guide or existing identifiers for the pattern).
2. Be verified as not already used by the system itself or by commonly co-installed tools. The spec must include one sentence confirming this check was performed.

An identifier that does not follow the project's naming convention = FAIL. An identifier with no collision-check statement = FAIL.

### 4g. Every Conditional Path Must Be Motivated

Every conditional branch in the spec — not just fallbacks, but every `if / else`, `on success / on failure`, `when X / otherwise` — must state WHY that path exists, not just WHAT it does.

**Bad:** "If the operation fails, return error code 503."

**Good:** "If the operation fails, return error code 503 (signals a transient upstream fault; allows the caller to retry without treating the request as definitively rejected)."

The motivation does not need to be long. One clause is enough. A branch whose existence cannot be explained = a branch whose necessity has not been established. Missing motivation = FAIL.

---

## 5. Self-Consistency Checks

These verify the spec is a closed logical system: every actor is accounted for, every decision is exhaustive, every term means exactly one thing, every assumption is visible, and scope boundaries have no contradictions. A spec that passes all prior sections but fails here is internally incoherent.

### 5a. Every Actor Is Accounted For

Enumerate every actor who interacts with the system described by this spec: user roles, system types, environment configurations, calling systems, integration partners, operators. For each actor, trace their path through the requirements. Every actor must reach a defined outcome — either handled by a REQ or explicitly excluded in Out of Scope.

No actor may fall into an undefined state. An actor who is implicitly assumed to behave identically to another actor = FAIL (make it explicit or prove it).

### 5b. Every Decision Is Exhaustively Enumerated

For every branching point in the spec — selection logic, conditional execution, fallback chains, error routing — list all possible input states and show which branch handles each one. An "else" that covers unnamed residual cases without describing what those cases are = FAIL.

**Bad:** "If condition A, do X. If condition B, do Y. Otherwise, return error."

**Good:**
```
All possible states:
  A — [description]: handled by REQ-NNN
  B — [description]: handled by REQ-NNN
  C — [description, why this is the residual]: returns error per REQ-NNN
  (exhaustive — no other states possible because [reason])
```

The exhaustiveness proof can be brief. What it cannot be is absent.

### 5c. Every Term Is Defined and Used Consistently

Every domain term, system concept, or role name used in the spec must be defined exactly once — either in a Glossary section, in the first REQ that introduces it, or in an Assumptions section. No term may be used as a synonym for another term. No term may carry two different meanings in different REQs. Ambiguous terminology is an unresolved requirement.

### 5d. Assumptions Are Explicit

Every assumption the spec makes — about the environment, about user behavior, about the state of the system before the spec's feature runs, about external systems — must be stated in an explicit Assumptions section or within the relevant REQ's Dependencies table. An implicit assumption is a hidden requirement. It will fail in production and be invisible in review.

**Bad:** A spec that requires network access without stating "assumes network is available and `registry.example.com` is reachable."

**Good:** An Assumptions section or dependency row that names each environmental precondition and what happens when it is violated.

Missing Assumptions section when the spec has environmental preconditions = FAIL.

### 5e. Scope Boundary Has No Contradictions

Every item listed in Out of Scope must have zero footprint inside the requirements. If an Out of Scope item is referenced in an AC, either the item is actually in scope (move it to a REQ) or the AC is wrong (remove the reference). Contradiction between Out of Scope and any REQ = FAIL.

Conversely: if an item is partially in scope, it must be split — the in-scope portion has a REQ, the out-of-scope portion is listed separately with the boundary clearly drawn.

---

## 6. Code Traceability Checks (run after implementation, before merge)

These checks are **post-implementation**. Run them after code exists — not at spec time.

**Required on every public construct (Tier 1–5 per code-documentation skill):**
- `@spec_id SPEC-N` — which spec this construct implements
- `@req_id REQ-NNN` — which requirement within that spec

**Required on every test unit (Tier 6):**
- `@spec_id SPEC-N` — which spec is being validated
- `@validates_req REQ-NNN` — which requirement within that spec

**No exemptions.** Every written construct must trace to a spec and requirement. If it exists in the codebase, a spec must exist for it.

### 6a. Every REQ Has At Least One Code Annotation

```bash
grep -rn "spec_id: SPEC-\|@spec_id SPEC-" \
  --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="vendor" \
  --exclude-dir="dist" --exclude-dir="build" --exclude-dir=".ai" \
  --exclude="*.json" --exclude="*.yaml" --exclude="*.yml" \
  --exclude="*.toml" --exclude="*.md" --exclude="*.lock" \
  <src-dir>

grep -rn "req_id: REQ-\|@req_id REQ-" \
  --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="vendor" \
  --exclude-dir="dist" --exclude-dir="build" --exclude-dir=".ai" \
  --exclude="*.json" --exclude="*.yaml" --exclude="*.yml" \
  --exclude="*.toml" --exclude="*.md" --exclude="*.lock" \
  <src-dir>
```

Every `REQ-NNN` in the spec must appear at least once as a `req_id:` / `@req_id` annotation in source, paired with the correct `spec_id:` / `@spec_id`. Missing = FAIL.

### 6b. Every REQ Has At Least One Test Annotation

```bash
grep -rn "validates_req: REQ-\|@validates_req REQ-" \
  --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="vendor" \
  <test-dir>

grep -rn "spec_id: SPEC-\|@spec_id SPEC-" \
  --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="vendor" \
  <test-dir>
```

Every `REQ-NNN` must appear at least once as `validates_req:` / `@validates_req` paired with the correct `spec_id:`. Missing = FAIL.

### 6c. No Orphaned Annotations

```bash
# All SPEC-N values referenced in source
grep -rh "spec_id: SPEC-\|@spec_id SPEC-" \
  --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir=".ai" \
  --exclude="*.md" \
  <src-dir> | grep -oE "SPEC-[1-9][0-9]*" | sort -u

# All SPEC-N values defined in spec files
grep -rh "^spec_id:" .ai/specs/ | grep -oE "SPEC-[1-9][0-9]*" | sort -u
```

Orphaned SPEC-N in code = FAIL. Orphaned REQ-NNN = FAIL.

### 6d. Every Source Module Has @spec_id at File Level

```bash
grep -rL "spec_id:\|@spec_id" \
  --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="vendor" \
  --exclude-dir="dist" --exclude-dir="build" \
  --exclude="*.json" --exclude="*.yaml" --exclude="*.yml" \
  --exclude="*.toml" --exclude="*.md" --exclude="*.lock" \
  <src-dir>
```

Missing `@spec_id` on any source file = FAIL.

### 6e. Traceability Matrix

Build and save to `.ai/reports/YYYY-MM-DD-<feature>-traceability.md`:

| SPEC | REQ | Statement | Implemented In | Tested In |
|------|-----|-----------|----------------|-----------|
| SPEC-1 | REQ-001 | ... | `auth.ts:42` | `auth.test.ts:15` |
| SPEC-1 | REQ-002 | ... | ❌ MISSING | ❌ MISSING |

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

### Design Completeness Failures (N)
- [4a] "<capability>": no NEW/EXTENDING classification; or deferred capability present in requirements
- [4b] <REQ-NNN>: constant "<value>" has no stated basis
- [4c] "<observable change>" introduced with no corresponding documentation REQ
- [4d] delivery channel "<name>" not handled or explicitly excluded
- [4e] external interface "<name>" used in <REQ-NNN> with no inventory entry
- [4f] identifier "<NAME>" missing naming-convention compliance or collision-check statement
- [4g] <REQ-NNN> branch "<condition>": no motivation stated for why this path exists

### Self-Consistency Failures (N)
- [5a] actor "<name>" has no mapped path through requirements or Out of Scope
- [5b] <REQ-NNN> branching point: residual "else" state not enumerated
- [5c] term "<word>" used without definition, or used with two different meanings
- [5d] environmental precondition assumed but not stated in Assumptions or Dependencies
- [5e] Out of Scope item "<name>" has footprint in <REQ-NNN>

### Code Traceability Failures (N) — post-implementation only
- SPEC-N: missing `spec_id:` frontmatter in spec file
- SPEC-N: duplicate spec_id detected across multiple spec files
- SPEC-N / REQ-NNN: no `@spec_id` + `@req_id` annotation found in codebase
- SPEC-N / REQ-NNN: no `@spec_id` + `@validates_req` annotation found in tests
- SPEC-N (orphaned): code references SPEC-N not found in any spec file
- REQ-NNN (orphaned): code references REQ-NNN not found in SPEC-N

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
| Capability not classified as NEW or EXTENDING | Classify inline with one-sentence rationale; move deferred items to Out of Scope |
| Non-obvious constant with no justification | Add inline parenthetical citing its basis: matching constant, standard, benchmark, or constraint |
| Observable change with no documentation REQ | Add a REQ whose statement names a specific documentation artifact to be updated |
| Delivery channel not covered or excluded | Read project install docs; add a REQ or Out of Scope entry per channel |
| External interface not inventoried | Add to Dependencies table with availability, failure modes, and platform alternatives |
| Shared-namespace identifier with no convention check | Verify naming pattern; add one-sentence collision-check confirmation |
| Conditional branch with no motivation | Add one clause explaining why the condition exists |
| Actor not accounted for | Map to a REQ or Out of Scope; prove the mapping is explicit |
| Else branch covering unnamed states | List all possible states; label each one; name the residual explicitly |
| Implicit environmental assumption | Move to Assumptions section with a stated violation behavior |

## Red Flags — Do NOT Approve

- "We'll figure out the metrics later"
- "This is obvious" (if it's obvious, state it explicitly)
- "The dependency works as expected" (expected by whom? state it)
- Acceptance criteria that an AI or human could disagree on without more data
- Test cases named "test1", "happy path", "edge case"
- A capability described as "reserved", "coming soon", or "deferred" inside requirements — absent or in a REQ, never in between
- A constant with no sentence explaining why that value and not another
- An identifier in a shared namespace with no stated convention check
- A conditional branch whose existence cannot be explained in one sentence
- An "else" that is not backed by a named, exhaustive enumeration of what states reach it
- Any spec touching acquisition, deployment, or upgrade that does not name every known delivery channel from the project's own documentation
- An environmental precondition that is assumed rather than stated
- A term used in two REQs with subtly different meanings

## Integration

Two gates:
1. **Spec gate** (Sections 1–5): After `brainstorming` writes spec, before `writing-plans` starts. Covers format, structure, logic, design completeness, and self-consistency.
2. **Traceability gate** (Section 6): After implementation, before merge. Run via `pr-reviewer` agent or manually.

```dot
digraph gate_position {
    "brainstorming writes spec" [shape=box];
    "spec-quality-gate (1-5)" [shape=box style=filled fillcolor=lightyellow];
    "spec gate passes?" [shape=diamond];
    "fix spec" [shape=box];
    "writing-plans + implementation" [shape=box];
    "traceability gate (section 6)" [shape=box style=filled fillcolor=lightyellow];
    "traceability passes?" [shape=diamond];
    "add @req_id / @validates_req" [shape=box];
    "merge / PR" [shape=box];

    "brainstorming writes spec" -> "spec-quality-gate (1-5)";
    "spec-quality-gate (1-5)" -> "spec gate passes?";
    "spec gate passes?" -> "fix spec" [label="FAIL"];
    "fix spec" -> "spec-quality-gate (1-5)" [label="re-run"];
    "spec gate passes?" -> "writing-plans + implementation" [label="PASS"];
    "writing-plans + implementation" -> "traceability gate (section 6)";
    "traceability gate (section 6)" -> "traceability passes?";
    "traceability passes?" -> "add @spec_id + @req_id / @validates_req" [label="FAIL"];
    "add @spec_id + @req_id / @validates_req" -> "traceability gate (section 6)" [label="re-run"];
    "traceability passes?" -> "merge / PR" [label="PASS"];
}
```
