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
| `/review lang` | Language-expert review (10 language-specific dimensions — type system, UB, idioms, ownership, concurrency, etc.) |
| `/review ci` | CI/CD pipeline review (stage completeness, security hygiene, coverage gate, artifact immutability, DORA readiness) |
| `/review hld` | High-level design review (C4 diagrams, tech selection, STRIDE threat model, failure modes, capacity planning, ADRs, spec coverage, AWS Well-Architected alignment) |
| `/review observability` | Observability setup review (structured logging OTel compliance, golden signal coverage, SLO quality, alert design, runbook completeness) |
| `/review deployment` | Deployment artifacts review (rollback procedure, DB migration safety, smoke test coverage, deployment runbook, release notes quality) |
| `/review integration` | Integration test review (no mocks at boundary, test isolation, factory pattern, Testcontainers config, contract tests, CI wiring) |
| `/review api` | API contract review (OpenAPI 3.1 or .proto — completeness, error taxonomy, security, breaking changes, schema quality, REQ coverage) |
| `/review e2e` | E2E test review (critical journey coverage, selector quality, no hardcoded waits, test independence, POM, auth fixtures, CI integration) |
| `/review performance` | Load test review (NFR-aligned thresholds, smoke test present, realistic traffic, test type coverage, CI integration against staging) |

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
| `language-expert-reviewer` | PR diff or full codebase | When deep language expertise matters: type system, UB, ownership, idioms, concurrency, error handling, performance — 10 dimensions, veteran-level. |
| `ci-reviewer` | CI/CD config file | When CI config is created or modified — validates stage completeness, fail-fast ordering, security hygiene, coverage gate, artifact immutability, environment gates, DORA readiness, branch protection alignment. Not included in `/review all` (different artifact type). |
| `hld-reviewer` | HLD document (`.ai/hld/`) | When HLD is written or updated — validates C4 diagrams, tech selection, STRIDE threat model, failure modes, capacity planning, ADRs, spec coverage, AWS Well-Architected alignment. 10 dimensions. Not included in `/review all` (design artifact, not code diff). |
| `observability-reviewer` | Observability artifacts (`.ai/observability/`, `wiki/guides/alerts.md`, `wiki/guides/runbooks/`) | When observability is set up or updated — validates OTel logging compliance, golden signal coverage, SLO quality vs NFRs, alert design (symptom-based), runbook completeness. 7 dimensions. Not included in `/review all`. |
| `deployment-reviewer` | Deployment artifacts (`.ai/deployment/`) | When deployment artifacts are created — validates rollback procedure (7 sections, tested), DB migration safety (expand-contract), smoke test coverage, deployment runbook, release notes quality. 6 dimensions. Not included in `/review all`. |
| `integration-test-reviewer` | Integration test files (`tests/integration/`) | When integration tests are written — validates no mocks at boundary, test isolation, factory pattern, Testcontainers config, spec AC coverage, contract tests, CI wiring. 7 dimensions. Not included in `/review all`. |
| `api-contract-reviewer` | API spec (`api/openapi.yaml`, `proto/**/*.proto`) | When API spec is written or updated — validates completeness, error taxonomy, security definitions, breaking change safety, schema quality, REQ-NNN coverage, naming consistency. 7 dimensions. Not included in `/review all`. |
| `e2e-reviewer` | E2E test files (`tests/e2e/**`) | When E2E tests are written — validates critical journey coverage, selector quality (semantic vs CSS), no hardcoded waits, test independence, POM structure, auth fixtures, CI integration. 7 dimensions. Not included in `/review all`. |
| `load-test-reviewer` | Performance test scripts (`tests/performance/**`) | When load tests are written — validates NFR-aligned thresholds, smoke test, realistic traffic mix, appropriate test types (soak for 99.9% availability), CI integration against staging. 6 dimensions. Not included in `/review all`. |

---

## Pre-Dispatch Self-Check

Before dispatching any review agent, run the `design-principles` **Review Checklist** yourself. Fix violations now — reviewers catch bugs and spec gaps, not design debt.

- [ ] No phantom abstractions (interface with one implementor, no spec REQ for extensibility)
- [ ] No leaking concerns (business logic in transport layer, UI logic in domain model)
- [ ] No mid-function `new` (dependencies injected or accessed through interfaces)
- [ ] No Liskov violations (every subtype satisfies base contract completely)
- [ ] No fat interfaces (client depends only on methods it uses)
- [ ] GoF patterns present are justified by a concrete need in the spec

If any item fails → fix, re-verify, then dispatch.

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

#### `/review lang`

Collect additional inputs:
- **LANGUAGE** — required. Ask: "Which language? (C++, Rust, Python, TypeScript, Go, Java, other)"
- **STANDARD** — optional. Ask: "Target standard? (e.g. C++20, Rust 2021, Python 3.12+). Leave blank for latest stable."
- **SCOPE** — `diff` (default) or `full`. Default to `diff` if SHA range is available.

Dispatch `language-expert-reviewer` agent:
```
Agent (language-expert-reviewer):
  LANGUAGE: <language>
  STANDARD: <standard or "latest stable">
  SCOPE: diff | full
  BASE_SHA: <BASE>      ← diff mode only
  HEAD_SHA: <HEAD>      ← diff mode only
  TARGET_FILES: <glob>  ← full mode only, optional
```

Output: [language-expert report — dimension scores + findings + priority action list]

---

#### `/review ci`

Collect inputs:
- **CI_CONFIG_PATH** — required. Auto-detect from: `.github/workflows/ci.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/config.yml`, `azure-pipelines.yml`, `bitbucket-pipelines.yml`. Ask if ambiguous.
- **PIPELINE_SPEC_PATH** — optional. Check `.ai/ci/` for a `*pipeline-spec.md` file.

Dispatch `ci-reviewer` agent:
```
Agent (ci-reviewer):
  CI_CONFIG_PATH: <detected or provided path>
  PIPELINE_SPEC_PATH: <.ai/ci/YYYY-MM-DD-pipeline-spec.md or omit if absent>
  PROJECT_ROOT: .
```

Output: [ci-reviewer report — 8 dimensions + PASS/NEEDS WORK/BLOCKED]

Note: `/review ci` is NOT included in `/review all` because it reviews CI config files, not the application code diff. Run it separately when CI config is created or modified.

---

#### `/review hld`

Collect inputs:
- **HLD_PATH** — required. Check `.ai/hld/` for the most recent `*hld*.md` file. Ask if ambiguous.
- **SPEC_PATH** — required. Check `.ai/specs/` for the matching spec.

Dispatch `hld-reviewer` agent:
```
Agent (hld-reviewer):
  HLD_PATH: <.ai/hld/YYYY-MM-DD-<feature>.md>
  SPEC_PATH: <.ai/specs/YYYY-MM-DD-<feature>.md>
```

Output: [hld-reviewer report — 10 dimensions + PASS/NEEDS WORK/BLOCKED]

Note: `/review hld` is NOT included in `/review all`. Design artifact, not code diff. Run from within `high-level-design` skill or manually when HLD is updated mid-implementation.

---

#### `/review observability`

Collect inputs:
- **SLO_PATH** — check `.ai/observability/` for most recent `*slos*.md`. Ask if ambiguous.
- **ALERTS_PATH** — check `wiki/guides/alerts.md`.
- **RUNBOOK_DIR** — check `wiki/guides/runbooks/`.
- **SPEC_PATH** — check `.ai/specs/` for matching spec (for NFR cross-check).

Dispatch `observability-reviewer` agent:
```
Agent (observability-reviewer):
  SLO_PATH: <.ai/observability/YYYY-MM-DD-slos.md>
  ALERTS_PATH: wiki/guides/alerts.md
  RUNBOOK_DIR: wiki/guides/runbooks/
  SPEC_PATH: <.ai/specs/YYYY-MM-DD-<feature>.md>
```

Output: [observability-reviewer report — 7 dimensions + PASS/NEEDS WORK/BLOCKED]

Note: `/review observability` is NOT included in `/review all`. Reviews observability artifacts, not code diff. Run from within `observability-standards` skill or manually when observability setup is updated.

---

#### `/review deployment`

Collect inputs:
- **ROLLBACK_PATH** — check `.ai/deployment/` for `*rollback*.md`
- **SMOKE_TEST_PATH** — check `.ai/deployment/` for `*smoke*.md`
- **RUNBOOK_PATH** — check `.ai/deployment/` for `*runbook*.md` or `*deploy*.md`
- **MIGRATION_CHECKLIST_PATH** — check `.ai/deployment/` for `*migration*.md` (omit if no DB changes)
- **SPEC_PATH** — check `.ai/specs/` for matching spec

Dispatch `deployment-reviewer` agent:
```
Agent (deployment-reviewer):
  ROLLBACK_PATH: <.ai/deployment/YYYY-MM-DD-rollback.md>
  SMOKE_TEST_PATH: <.ai/deployment/YYYY-MM-DD-smoke-tests.md>
  RUNBOOK_PATH: <.ai/deployment/YYYY-MM-DD-deploy-runbook.md>
  MIGRATION_CHECKLIST_PATH: <.ai/deployment/YYYY-MM-DD-migration.md>  // omit if no DB changes
  SPEC_PATH: <.ai/specs/YYYY-MM-DD-<feature>.md>
```

Output: [deployment-reviewer report — 6 dimensions + PASS/NEEDS WORK/BLOCKED]

Note: `/review deployment` is NOT included in `/review all`. Invoked by `deployment-workflow` skill or manually when deployment artifacts are created.

---

#### `/review integration`

Collect inputs:
- **TEST_FILES** — glob to integration test files. Auto-detect: `tests/integration/**`, `test/integration/**`, `**/*_integration_test*`
- **SPEC_PATH** — check `.ai/specs/` for matching spec (optional but recommended)

Dispatch `integration-test-reviewer` agent:
```
Agent (integration-test-reviewer):
  TEST_FILES: <detected glob>
  SPEC_PATH: <.ai/specs/YYYY-MM-DD-<feature>.md>
```

Output: [integration-test-reviewer report — 7 dimensions + PASS/NEEDS WORK/BLOCKED]

Note: `/review integration` is NOT included in `/review all`. Run from `integration-testing` skill or from `finishing-a-development-branch` when integration tests are in the diff.

---

#### `/review api`

Collect inputs:
- **SPEC_PATH** — check `api/openapi.yaml`, `api/*.yaml`, `proto/**/*.proto`. Ask if ambiguous.
- **PROTOCOL** — auto-detect: `.yaml`/`.json` = `rest`, `.proto` = `grpc`
- **SPEC_SOURCE_PATH** — check `.ai/specs/` for matching spec (optional)
- **HLD_PATH** — check `.ai/hld/` for matching HLD (optional)

Dispatch `api-contract-reviewer` agent:
```
Agent (api-contract-reviewer):
  SPEC_PATH: <api/openapi.yaml or proto/**/*.proto>
  PROTOCOL: <rest | grpc>
  SPEC_SOURCE_PATH: <.ai/specs/YYYY-MM-DD-<feature>.md>
  HLD_PATH: <.ai/hld/YYYY-MM-DD-<feature>.md>
```

Output: [api-contract-reviewer report — 7 dimensions + PASS/NEEDS WORK/BLOCKED]

Note: `/review api` is NOT included in `/review all`. Run from `api-contract-first` skill before handler implementation, or from `finishing-a-development-branch` when API spec files are in the diff.

---

#### `/review e2e`

Collect inputs:
- **TEST_FILES** — glob to E2E test files. Auto-detect: `tests/e2e/**/*.spec.ts`, `e2e/**/*.spec.*`
- **SPEC_PATH** — check `.ai/specs/` for matching spec (optional)

Dispatch `e2e-reviewer` agent:
```
Agent (e2e-reviewer):
  TEST_FILES: <tests/e2e/**/*.spec.ts>
  SPEC_PATH: <.ai/specs/YYYY-MM-DD-<feature>.md>
```

Output: [e2e-reviewer report — 7 dimensions + PASS/NEEDS WORK/BLOCKED]

Note: `/review e2e` is NOT included in `/review all`. Run from `e2e-testing` skill or from `finishing-a-development-branch` when E2E tests are in the diff.

---

#### `/review performance`

Collect inputs:
- **SCRIPT_PATH** — check `tests/performance/` for `*.js`, `*.py` (Locust), `*.scala` (Gatling)
- **SPEC_PATH** — check `.ai/specs/` for matching spec (for NFR cross-check)
- **SLO_PATH** — check `.ai/observability/` for SLO document

Dispatch `load-test-reviewer` agent:
```
Agent (load-test-reviewer):
  SCRIPT_PATH: <tests/performance/load-test.js>
  SPEC_PATH: <.ai/specs/YYYY-MM-DD-<feature>.md>
  SLO_PATH: <.ai/observability/YYYY-MM-DD-slos.md>
```

Output: [load-test-reviewer report — 6 dimensions + PASS/NEEDS WORK/BLOCKED]

Note: `/review performance` is NOT included in `/review all`. Run from `load-testing` skill or from `finishing-a-development-branch` when performance test files are in the diff.

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
| "language review" / "C++ review" / "Rust review" / "expert review" / "check idioms" / "review against standard" | `/review lang` |
| "review my pipeline" / "check CI config" / "review CI" / "check my ci" / "review the pipeline" | `/review ci` |
| "review the HLD" / "check the design doc" / "review architecture doc" / "validate HLD" | `/review hld` |
| "review observability" / "check SLOs" / "review runbooks" / "check alerts" / "review my metrics" | `/review observability` |
| "review deployment" / "check rollback" / "review my deploy plan" / "check migration safety" / "review release notes" | `/review deployment` |
| "review integration tests" / "check my integration tests" / "are my tests mocking the DB" / "review testcontainers" | `/review integration` |
| "review my API spec" / "check the openapi" / "review the contract" / "check my proto" / "review API design" | `/review api` |
| "review e2e tests" / "check my playwright tests" / "review my E2E" / "are my e2e tests good" | `/review e2e` |
| "review load tests" / "check my k6 script" / "review performance tests" / "check my thresholds" | `/review performance` |

---

## Integration Points

This skill is called from:
- `pr-creator` (Step 5 — `/review all` before PR is created)
- `finishing-a-development-branch` (Step 1.5 — before merge or PR option)
- `requesting-code-review` (routes here for all agent-backed reviews)
- Direct chat / slash command at any point during development
