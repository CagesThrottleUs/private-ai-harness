---
name: review
description: Central entry point for all code review types. Routes to the right agent(s) based on what you need reviewed — PR diff, spec correctness, test quality, security, or full project. Invoke as /review, /review pr, /review spec, /review tests, /review security, /review full, or /review all. Also handles direct chat requests like "review my PR" or "check security".
---

# Review Orchestrator

Single entry point for all reviews. Routes to the right agent(s), collects required inputs, dispatches in parallel where possible, and aggregates results.

---

## Invocation Forms

| Command | What runs |
|---------|-----------|
| `/review` | Asks which type, then routes |
| `/review pr` | PR diff review (5 dimensions + spec gate + traceability) |
| `/review spec` | Spec-vs-implementation (does code satisfy REQ criteria?) |
| `/review tests` | Test quality (meaningful assertions, TC coverage, mutation resistance) |
| `/review security` | Adversarial security review (threat model, OWASP, future attack surface) |
| `/review full` | Full project review (all dimensions, whole codebase) |
| `/review all` | All PR-scoped agents in parallel (pr + spec + tests + security) |

Also triggers on direct chat: "review my PR", "check my tests", "security review", "does this satisfy the spec".

---

## Agent Roster

| Agent | Scope | When to use |
|-------|-------|-------------|
| `pr-reviewer` | PR diff | Every PR before merge. 5 dimensions + traceability. Blocks on missing spec. |
| `spec-impl-reviewer` | PR diff vs spec | When you have a spec and need to verify implementation satisfies acceptance criteria — not just that it's annotated |
| `test-quality-reviewer` | PR diff (test files) | When tests are added or modified — checks meaningful assertions, TC coverage, mutation resistance |
| `security-reviewer` | PR diff | Any PR touching auth, input, data access, external comms, config. Always on new endpoints. |
| `full-project-reviewer` | Entire codebase | Before releases, after major milestones, or for a holistic audit |

---

## Execution

### Step 1 — Collect Shared Inputs

Regardless of review type, gather:

```bash
# Current branch SHA range
BASE=$(git merge-base origin/main HEAD)
HEAD=$(git rev-parse HEAD)

# Spec (required for pr, spec, tests, security, all)
# Ask if not provided: "Which spec does this work implement? (.ai/specs/X.md or SPEC-N)"
```

If no spec provided and review type requires it:
```
Spec is required for this review type.
Provide: .ai/specs/<name>.md or SPEC-N
```

### Step 2 — Route and Dispatch

#### `/review pr`

Dispatch `pr-reviewer` agent:
```
Agent (pr-reviewer):
  DESCRIPTION: <branch description from git log --oneline>
  BASE_SHA: <BASE>
  HEAD_SHA: <HEAD>
  REQUIREMENTS: <spec path or SPEC-N>
```

Output: [pr-reviewer report]

---

#### `/review spec`

Dispatch `spec-impl-reviewer` agent:
```
Agent (spec-impl-reviewer):
  SPEC_PATH: <spec path>
  BASE_SHA: <BASE>
  HEAD_SHA: <HEAD>
```

Output: [spec-impl report with per-REQ verdict and future impact]

---

#### `/review tests`

Dispatch `test-quality-reviewer` agent:
```
Agent (test-quality-reviewer):
  SPEC_PATH: <spec path>
  BASE_SHA: <BASE>
  HEAD_SHA: <HEAD>
```

Output: [test quality report with anti-patterns and TC coverage]

---

#### `/review security`

Before dispatching, check whether any `Anthropic-Cybersecurity-Skills` apply to the
change (e.g. `testing-idor-*`, `performing-sql-injection-*`, `analyzing-jwt-*`).
Invoke matching skills first — they provide domain-specific checklists the agent should follow.

Dispatch `security-reviewer` agent:
```
Agent (security-reviewer):
  DESCRIPTION: <what this PR does>
  BASE_SHA: <BASE>
  HEAD_SHA: <HEAD>
  SPEC_PATH: <spec path — optional but recommended>
```

Output: [security report with threat model, findings, future attack surface]

---

#### `/review full`

Dispatch `full-project-reviewer` agent:
```
Agent (full-project-reviewer):
  [no SHA inputs — reviews entire codebase]
```

Output: [full project report — 5 dimensions + traceability matrix]

---

#### `/review all`

Dispatch all four PR-scoped agents **in parallel** (they are independent):

```
Parallel dispatch:
  Agent 1 → pr-reviewer         (DESCRIPTION, BASE_SHA, HEAD_SHA, REQUIREMENTS)
  Agent 2 → spec-impl-reviewer  (SPEC_PATH, BASE_SHA, HEAD_SHA)
  Agent 3 → test-quality-reviewer (SPEC_PATH, BASE_SHA, HEAD_SHA)
  Agent 4 → security-reviewer   (DESCRIPTION, BASE_SHA, HEAD_SHA, SPEC_PATH)
```

Wait for all four to complete, then produce the aggregated report (Step 3).

---

### Step 3 — Aggregated Report (for `/review all` only)

After all agents complete:

```markdown
# Review Summary
**Branch:** <branch name>
**Spec:** <spec path>
**Date:** YYYY-MM-DD

## Gate Status

| Review | Verdict | Blocking Issues |
|--------|---------|----------------|
| PR Review (5 dimensions) | PASS / NEEDS WORK / BLOCK | N |
| Spec Correctness | SATISFIES / PARTIAL / FAILS | N |
| Test Quality | PASS / NEEDS WORK / FAILING | N |
| Security | MERGE / WITH FIXES / BLOCK | N |

## Overall: MERGE READY | NEEDS WORK | BLOCKED

## Must Fix Before Merge (all Critical across all agents)
1. [SOURCE] `file:line` — <issue> — <fix>
2. ...

## Should Fix Before Merge (Important)
1. [SOURCE] `file:line` — <issue> — <fix>

## Future Impact (track or backlog)
1. [SOURCE] <item>
```

Save to `.ai/reports/YYYY-MM-DD-<branch>-review-summary.md`.

---

## Severity Escalation

If any single agent returns a Critical finding → overall status = **BLOCKED**.
If any agent blocks (spec missing, pre-flight fail) → stop, report, do not run remaining agents.
If all agents return Important-or-lower → overall status = **NEEDS WORK**.
If all agents return Minor-or-clean → overall status = **MERGE READY**.

---

## Direct Chat Triggers

These phrases trigger this skill automatically:

| Phrase | Routes to |
|--------|-----------|
| "review my PR" / "review this PR" | `/review pr` |
| "does this satisfy the spec" / "check spec" | `/review spec` |
| "check my tests" / "test quality" | `/review tests` |
| "security review" / "check for vulnerabilities" | `/review security` |
| "full review" / "audit the codebase" | `/review full` |
| "review everything" / "full suite" | `/review all` |

---

## Integration Points

This skill is called from:
- `pr-creator` (Step 5 — `/review all` before PR is created)
- `finishing-a-development-branch` (Step 1.5 — before merge or PR option)
- `requesting-code-review` (routes here for all agent-backed reviews)
- Direct chat / slash command at any point during development
