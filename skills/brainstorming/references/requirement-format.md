# Requirement Format, Quality Rules, Spec Self-Review

Part of the brainstorming skill. Read from disk when writing a spec so it survives compaction.

## What a Great Spec Looks Like

These are the north star. Every spec written here should aspire to this bar.

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

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, install dependencies, or take any implementation action until the user has approved the design doc: the short one for a small change, the REQ-format spec for a feature/project. Reading and exploring are fine.

Exceptions: a quick, clear task (the request already contains everything that matters), and a spike the user said yes to (stays labeled throwaway; keeping its output is a new request through this gate).
</HARD-GATE>


**Requirement Format (Living Requirement Document):**

Every spec must follow this structure. This is not optional.

```markdown
---
spec_id: SPEC-N
title: [Feature Name]
status: draft
north_star: [the ONE business-context north-star metric this spec advances — verbatim from .ai/YYYY-MM-DD-<feature-slug>/business-context/business-context-<feature-slug>.md, including its target; or "N/A — <bug fix / config / no business-context>"]
---

# [Feature Name] — Specification

**Version:** 1.0 | **Date:** YYYY-MM-DD

---

## Context

[Why this exists. What problem it solves. 1-3 paragraphs. No requirements here.]

## North Star Alignment

*This is the "inputs a team influences" layer of the North Star framework (Amplitude/Sean Ellis): the north-star is a lagging outcome; a feature earns its place by moving a named input metric that drives it. A delivery metric (latency, DORA, SLO) is NOT a business north-star — do not put one here.*

**Business north-star:** [metric + target, verbatim from `.ai/YYYY-MM-DD-<feature-slug>/business-context/` — matches the `north_star:` frontmatter value; or "N/A" with reason]

**Input metric this feature moves:** [the specific driver of the north-star this work advances, e.g. "activation rate (signup → first successful action)". If N/A, say why — e.g. "bug fix restoring existing behavior, no metric movement expected".]

## Scope

**In scope:** [explicit list]

## Out of Scope

- [explicit exclusion — state what could be assumed but isn't included]
- [another exclusion, if any]

---

## Requirements

> Each requirement is a testable statement of truth. No vague language. No emotional descriptors.
> Every statement in this section MUST be implemented and MUST have a test case.

### REQ-001: [Requirement Title]

**Statement:** [One precise, binary-or-measurable statement. Example: "The system SHALL reject login after 5 failures in 15 minutes."]

**Acceptance Criteria:**
- [ ] [Measurable criterion — include numbers, thresholds, or binary conditions]
- [ ] [Another criterion]

**Dependencies:**
| Dependency | Assumed Behavior |
|-----------|-----------------|
| [dep name] | [Exact behavior this requirement assumes — not "works correctly"] |

**Depends on:** REQ-NNN (if applicable)

**Test Cases:**
- TC-REQ001-01: [specific inputs → exact expected output; a wrong implementation must make this test fail]
- TC-REQ001-02: [one TC per AC — each proves its AC, not just witnesses it]

One TC per AC minimum. Each TC must state inputs and exact expected output.

**North star:** every statement in a spec is either a universal truth or immediately falsifiable by a test. A TC that would pass against a wrong implementation is not a test — it is a wish. Ask: *if the implementation were subtly wrong — off-by-one, inverted condition, missing field — would this TC catch it?* If not, rewrite it until it would.

---

[Repeat for REQ-002, REQ-003, ...]

---

## Non-Functional Requirements

*NFRs define HOW the system must behave, not WHAT it does. Each entry MUST have a numeric target — "fast" is not an NFR, "p99 < 200ms under 500 RPS" is.*

*Use RFC 2119 enforceability (IETF RFC 2119): **MUST** = absolute requirement (any conforming implementation satisfies it), **SHOULD** = strongly recommended (deviation requires explicit justification), **MAY** = optional.*

*Mark any row "N/A" with a one-line rationale if genuinely not applicable. A blank row = not considered = spec-quality-gate FAIL.*

### Performance

| NFR | Enforceability | Target | Measurement | Load condition |
|-----|---------------|--------|-------------|---------------|
| Response time (p99) | MUST | < [N]ms | APM/histogram | [N] concurrent users, normal load |
| Response time (p95) | SHOULD | < [N]ms | APM/histogram | Normal load |
| Throughput (sustained) | MUST | [N] RPS | Load test | Normal load |
| Throughput (peak) | SHOULD handle | [N] RPS | Load test | Peak load |
| Availability | MUST | [99.X%] | Uptime monitoring | 30-day rolling |

### Security

| NFR | Enforceability | Target |
|-----|---------------|--------|
| Authentication | MUST | [JWT RS256 / OAuth2 / API key / mTLS / N/A] |
| Authorization | MUST | [RBAC / ABAC / public endpoint] |
| Encryption at rest | MUST/N/A | [AES-256 via managed key / N/A — reason] |
| Encryption in transit | MUST | TLS 1.3 minimum |
| Compliance | MUST | [GDPR / PCI DSS / HIPAA / SOC 2 / None — explicit response required] |

### Scalability

| NFR | Enforceability | Target |
|-----|---------------|--------|
| Concurrent users | MUST handle | [N] concurrent users at p99 target |
| Data volume ceiling | SHOULD handle | [N] records at target latency |
| Horizontal scalability | MAY | [stateless / requires session affinity] |

*Performance NFRs feed directly into:*
- *HLD §8 (capacity planning) — scaling triggers and thresholds*
- *observability-standards — SLO targets*
- *load-testing — k6 threshold values (threshold must match NFR target)*

---

## Assumptions

| ID | Assumption | Impact if Wrong | Verified By |
|----|-----------|----------------|-------------|
| ASM-001 | [External behavior assumed] | [What breaks] | [TC or manual check] |

## Test Coverage Matrix

| REQ-ID | Requirement | Test Cases | Status |
|--------|-------------|-----------|--------|
| REQ-001 | [title] | TC-REQ001-01, TC-REQ001-02 | 🔴 Pending |
| REQ-002 | [title] | TC-REQ002-01 | 🔴 Pending |
```

**Requirement Quality Rules (enforced by spec-quality-gate):**

- **Technical, not emotional:** "response time < 200ms" not "fast". "returns HTTP 401" not "handles errors gracefully".
- **Binary or measurable:** every criterion must have a number, threshold, or deterministic condition.
- **Complete:** every happy path has a corresponding error/edge case REQ or explicit cross-reference.
- **Testable:** if you can't write a test case name for a requirement, the requirement is not specific enough.
- **No TBD:** unresolved items are either decided or moved to Out of Scope.
- **Dependencies declared:** if a requirement depends on external behavior, that behavior is stated explicitly.
- **Honest tests:** every TC must fail if its AC were slightly wrong — off-by-one, inverted condition, missing field. A TC that passes against a wrong implementation is a phantom.

**Spec Self-Review:**
After writing the spec document, check before running the formal quality gate:

0. **Run the mechanical pre-lint** — `bash skills/spec-quality-gate/scripts/pre-lint.sh <spec-path>`. This is a deterministic, zero-cost pass over the exact Section 1 format checks `spec-quality-reviewer` (Opus) will run: frontmatter, REQ-NNN numbering, REQ subsection completeness, Test Coverage Matrix consistency, Out of Scope heading, NFR presence/placeholders. Fix every finding before spending any review-agent tokens on this spec. This step alone eliminates most round-trips: those checks are 100% mechanical — if the script fails, the agent will fail on the identical grounds.
1. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
2. **Scope check:** Focused enough for a single implementation plan, or needs decomposition?
3. **Ambiguity check:** Any requirement interpretable two different ways? Pick one, state it.
4. **Forbidden-word scan** — grep the Requirements and NFR sections for the exact words `spec-quality-reviewer` treats as FAIL (2a/Section 4 smells). If any appear, rewrite that statement with a number, threshold, or named mechanism before moving on:
   - Subjective/vague: `TBD` `intuitive` `fast enough` `user-friendly` `clean` `seamless` `appropriate` `should work` `simple` `easy` `nice` `obvious` `high-quality` `reasonable` `robust` `efficient`
   - Loophole: `if possible` `as appropriate` `where practical` `to the extent that`
   - Open-ended: `including but not limited to` `etc.` `and so on` `and/or`
   - Superlative without baseline: `best` `fastest` `better` `faster` `more secure`
   - Non-atomic: `and also` `as well as` inside one AC/Statement line — split into separate REQs/ACs
   - Weak verb with no observable outcome: `support` `handle` `process` `manage` `be able to` — only OK if the same line names the exact mechanism/output
5. **Honest-test check:** For each TC, ask: "if the implementation were subtly wrong — off-by-one, inverted condition, missing field — would this TC catch it?" If not, rewrite the assertion.
6. **North star check:** For each REQ, ask: "Could a new engineer implement exactly this from the spec alone, without asking anyone?" If not, the requirement is incomplete.
7. **North Star Alignment check:** Is the `north_star:` frontmatter field present and non-blank? Does `## North Star Alignment` name a business metric (not a delivery/latency/DORA metric) and the specific input metric this feature moves — or an explicit `N/A — <reason>` for bug fixes/config? A feature spec with a blank or delivery-metric north-star has not been anchored to a business outcome.

