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
| `/review lang` | Language-expert review (10 dimensions — type system, UB, idioms, ownership, concurrency, etc.) |
| `/review ci` | CI/CD pipeline review (stage completeness, security hygiene, coverage gate, DORA readiness) |
| `/review hld` | High-level design review (C4, tech selection, STRIDE, failure modes, capacity, ADRs) |
| `/review observability` | Observability setup review (OTel logging, golden signals, SLO quality, alert design, runbooks) |
| `/review deployment` | Deployment artifacts review (rollback, DB migration safety, smoke tests, runbook, release notes) |
| `/review integration` | Integration test review (no mocks at boundary, isolation, Testcontainers, contract tests) |
| `/review api` | API contract review (OpenAPI 3.1 / .proto — completeness, errors, security, breaking changes) |
| `/review e2e` | E2E test review (critical journeys, selector quality, no hardcoded waits, POM, CI) |
| `/review flags` | Feature flag review (naming, registry completeness, CI hygiene, safe defaults) |
| `/review iac` | IaC configuration review (pinned versions, remote state, sensitive vars, tfsec) |
| `/review schema` | Database ERD review (PKs, FKs, crow's foot, no float money, index strategy) |
| `/review visual` | Visual regression test review (screenshots, animations off, baselines in git, pinned Docker) |
| `/review chaos` | Chaos engineering review (steady state, HLD failure modes, degradation thresholds, abort criteria) |
| `/review incident` | Incident response docs review (severity matrix, IC role, postmortem 7 sections, MTTD/MTTR) |
| `/review onboarding` | Onboarding guide review (8 sections, dev setup commands, C4 diagram, ADRs, first contribution) |
| `/review dast` | DAST configuration review (ZAP baseline on PRs, API scan on staging, HIGH fails CI, SARIF) |
| `/review accessibility` | Accessibility test review (axe-playwright, WCAG 2.1/2.2 AA tags, violations fail CI) |
| `/review versioning` | API versioning strategy review (ADR, breaking change policy, Sunset headers, migration guides) |
| `/review sequence` | Sequence diagram review (flow coverage, error paths, auth boundary, arrow types, HLD alignment) |
| `/review performance` | Load test review (NFR-aligned thresholds, smoke test, realistic traffic, CI on staging) |

Also triggers on direct chat: "review my PR", "check my tests", "security review", "does this satisfy the spec".

---

## Agent Roster

**`/review all` scope:** runs only pr-reviewer + spec-impl-reviewer + test-quality-reviewer + security-reviewer in parallel. All other agents run independently via their specific subcommand.

**Platform dispatch:** Claude Code uses `private-ai-harness:<agent>` through
the `Agent` tool. Codex uses the installed custom agent
`private-ai-harness-<agent>` through its native subagent tools. If a Codex
custom agent is unavailable, follow the fallback in
`using-superpowers/references/codex-tools.md` and load `agents/<agent>.md` as
the spawned agent's instructions.

| Agent | Scope | When to use |
|-------|-------|-------------|
| `pr-reviewer` | PR diff | Every PR before merge. 5 dimensions + traceability. Blocks on missing spec. |
| `spec-impl-reviewer` | PR diff vs spec | Verify implementation satisfies acceptance criteria — not just annotated |
| `test-quality-reviewer` | PR diff (test files) | Tests added/modified — checks meaningful assertions, TC coverage, mutation resistance |
| `security-reviewer` | PR diff | Any PR touching auth, input, data access, external comms, config |
| `full-project-reviewer` | Entire codebase | Before releases, after major milestones, holistic audit |
| `language-expert-reviewer` | PR diff or full | Type system, UB, ownership, idioms, concurrency, error handling — 10 dimensions |
| `ci-reviewer` | CI/CD config | When CI config is created or modified |
| `hld-reviewer` | HLD document | When HLD is written or updated |
| `observability-reviewer` | Observability artifacts | When observability is set up or updated |
| `deployment-reviewer` | Deployment artifacts | When deployment artifacts are created |
| `integration-test-reviewer` | Integration test files | When integration tests are written |
| `api-contract-reviewer` | API spec | When API spec is written or updated |
| `e2e-reviewer` | E2E test files | When E2E tests are written |
| `feature-flag-reviewer` | Flag registry | When feature flags are added or changed |
| `iac-reviewer` | `infra/` | When IaC is added or changed |
| `database-erd-reviewer` | ERD files | When ERD is written or updated |
| `visual-regression-reviewer` | Visual test files | When visual regression tests are written |
| `chaos-reviewer` | Chaos test files | When chaos tests are written |
| `incident-response-reviewer` | IR docs | When IR docs are created/updated |
| `onboarding-reviewer` | `wiki/ONBOARDING.md` | When onboarding guide is written or updated |
| `dast-reviewer` | CI config / ZAP files | When DAST is configured |
| `accessibility-reviewer` | E2E test files | When UI feature ships |
| `api-versioning-reviewer` | Versioning artifacts | When versioning strategy is defined |
| `sequence-diagram-reviewer` | Sequence diagrams | When sequence diagrams are written |
| `load-test-reviewer` | Performance test scripts | When load tests are written |

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

```bash
BASE=$(git merge-base origin/main HEAD)
HEAD=$(git rev-parse HEAD)
```

Spec required for: pr, spec, tests, security, all. If not provided:
```
Spec is required for this review type.
Provide: .ai/specs/<name>.md or SPEC-N
```

### Step 2 — Route and Dispatch

For code-diff reviews (pr, spec, tests, security, lang), use BASE/HEAD from Step 1.
For artifact reviews, auto-detect paths per footnotes below.

| Command | Agent | Dispatch inputs |
|---------|-------|----------------|
| `/review pr` | pr-reviewer | DESCRIPTION, BASE_SHA, HEAD_SHA, REQUIREMENTS |
| `/review spec` | spec-impl-reviewer | SPEC_PATH, BASE_SHA, HEAD_SHA |
| `/review tests` | test-quality-reviewer | SPEC_PATH, BASE_SHA, HEAD_SHA |
| `/review security`¹ | security-reviewer | DESCRIPTION, BASE_SHA, HEAD_SHA, SPEC_PATH |
| `/review full` | full-project-reviewer | (no SHA inputs — whole codebase) |
| `/review lang`² | language-expert-reviewer | LANGUAGE, STANDARD, SCOPE, BASE_SHA, HEAD_SHA |
| `/review ci` | ci-reviewer | CI_CONFIG_PATH³, PIPELINE_SPEC_PATH⁴, PROJECT_ROOT=. |
| `/review hld` | hld-reviewer | HLD_PATH⁵, SPEC_PATH |
| `/review observability` | observability-reviewer | SLO_PATH⁶, ALERTS_PATH⁷, RUNBOOK_DIR⁸, SPEC_PATH |
| `/review deployment` | deployment-reviewer | ROLLBACK_PATH⁹, SMOKE_TEST_PATH⁹, RUNBOOK_PATH⁹, MIGRATION_CHECKLIST_PATH⁹, SPEC_PATH |
| `/review integration` | integration-test-reviewer | TEST_FILES¹⁰, SPEC_PATH |
| `/review api` | api-contract-reviewer | SPEC_PATH¹¹, PROTOCOL¹², SPEC_SOURCE_PATH, HLD_PATH |
| `/review e2e` | e2e-reviewer | TEST_FILES¹³, SPEC_PATH |
| `/review flags` | feature-flag-reviewer | REGISTRY_PATH¹⁴ |
| `/review iac` | iac-reviewer | IAC_DIR=infra/, TOOL |
| `/review schema` | database-erd-reviewer | ERD_PATH¹⁵, SPEC_PATH |
| `/review visual` | visual-regression-reviewer | TEST_FILES¹⁶, SNAPSHOT_DIR |
| `/review chaos` | chaos-reviewer | TEST_FILES¹⁷, HLD_PATH, SPEC_PATH |
| `/review incident` | incident-response-reviewer | PROCESS_PATH¹⁸, POSTMORTEM_PATH |
| `/review onboarding` | onboarding-reviewer | ONBOARDING_PATH=wiki/ONBOARDING.md |
| `/review dast` | dast-reviewer | CI_CONFIG_PATH, OPENAPI_PATH |
| `/review accessibility` | accessibility-reviewer | TEST_FILES¹³, SPEC_PATH |
| `/review versioning` | api-versioning-reviewer | ADR_PATH, POLICY_PATH |
| `/review sequence` | sequence-diagram-reviewer | DIAGRAM_PATH¹⁹, HLD_PATH, SPEC_PATH |
| `/review performance` | load-test-reviewer | SCRIPT_PATH²⁰, SPEC_PATH, SLO_PATH |

**Auto-detect footnotes:**

¹ Before dispatching, check for matching `Anthropic-Cybersecurity-Skills` (e.g. `testing-idor-*`, `analyzing-jwt-*`); invoke first.
² Ask: LANGUAGE (required), STANDARD (optional, default latest stable), SCOPE (`diff` default or `full`).
³ Auto-detect: `.github/workflows/ci.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/config.yml`, `azure-pipelines.yml`, `bitbucket-pipelines.yml`. Ask if ambiguous.
⁴ Check `.ai/ci/` for `*pipeline-spec.md`; omit if absent.
⁵ Check `.ai/hld/` for most recent `*hld*.md`. Ask if ambiguous.
⁶ Check `.ai/observability/` for most recent `*slos*.md`.
⁷ `wiki/guides/alerts.md`
⁸ `wiki/guides/runbooks/`
⁹ Check `.ai/deployment/` for `*rollback*.md`, `*smoke*.md`, `*runbook*.md`, `*migration*.md`. Omit MIGRATION_CHECKLIST_PATH if no DB changes.
¹⁰ Auto-detect: `tests/integration/**`, `test/integration/**`, `**/*_integration_test*`.
¹¹ Check `api/openapi.yaml`, `api/*.yaml`, `proto/**/*.proto`.
¹² Auto-detect: `.yaml`/`.json` → `rest`, `.proto` → `grpc`.
¹³ Auto-detect: `tests/e2e/**/*.spec.ts`, `e2e/**/*.spec.*`.
¹⁴ `wiki/guides/feature-flag-registry.md`
¹⁵ Check `.ai/lld/` for `*schema*.md`.
¹⁶ `tests/visual/`
¹⁷ `tests/chaos/`
¹⁸ `wiki/guides/incident-response.md`
¹⁹ Check `.ai/lld/` for `*sequences*.md`.
²⁰ Check `tests/performance/` for `*.js`, `*.py` (Locust), `*.scala` (Gatling).

### Step 3 — `/review all` (conditional parallel dispatch)

First scan the diff to decide which agents have something to review:

```bash
CHANGED=$(git diff $BASE..$HEAD --name-only)
echo "$CHANGED" | grep -qE '(test|spec)' && TESTS=1 || TESTS=0
echo "$CHANGED" | grep -vqE '\.(md|txt)$' && CODE=1 || CODE=0
```

Dispatch in parallel by rule. Always pass REPORT_FILE so findings go to a file,
not into the caller's context:

| Agent | Dispatch when | Inputs |
|-------|---------------|--------|
| pr-reviewer | always | DESCRIPTION, BASE_SHA, HEAD_SHA, REQUIREMENTS, REPORT_FILE |
| spec-impl-reviewer | always | SPEC_PATH, BASE_SHA, HEAD_SHA, REPORT_FILE |
| test-quality-reviewer | TESTS=1 | SPEC_PATH, BASE_SHA, HEAD_SHA, REPORT_FILE |
| security-reviewer | CODE=1 (skip only if docs/comment-only) | DESCRIPTION, BASE_SHA, HEAD_SHA, SPEC_PATH, REPORT_FILE |

Wait for all dispatched agents, then produce the aggregated report (Step 4).

### Step 4 — Aggregated Report (for `/review all` only)

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

## Must Fix Before Merge
1. [SOURCE] `file:line` — <issue> — <fix>

## Should Fix Before Merge
1. [SOURCE] `file:line` — <issue> — <fix>

## Future Impact (track or backlog)
1. [SOURCE] <item>
```

Save to `.ai/reports/YYYY-MM-DD-<branch>-review-summary.md`.

---

## Severity Escalation

- Any Critical finding from any agent → overall **BLOCKED**
- Any agent blocks (spec missing, pre-flight fail) → stop, report, don't run remaining agents
- All Important-or-lower → **NEEDS WORK**
- All Minor-or-clean → **MERGE READY**

---

## Direct Chat Triggers

| Phrase | Routes to |
|--------|-----------|
| "review my PR" / "review this PR" | `/review pr` |
| "does this satisfy the spec" / "check spec" | `/review spec` |
| "check my tests" / "test quality" | `/review tests` |
| "security review" / "check for vulnerabilities" | `/review security` |
| "full review" / "audit the codebase" | `/review full` |
| "review everything" / "full suite" | `/review all` |
| "language review" / "C++ review" / "Rust review" / "expert review" / "check idioms" | `/review lang` |
| "review my pipeline" / "check CI config" / "review CI" / "check my ci" | `/review ci` |
| "review the HLD" / "check the design doc" / "review architecture doc" / "validate HLD" | `/review hld` |
| "review observability" / "check SLOs" / "review runbooks" / "check alerts" | `/review observability` |
| "review deployment" / "check rollback" / "review my deploy plan" / "check migration safety" | `/review deployment` |
| "review integration tests" / "check my integration tests" / "are my tests mocking the DB" | `/review integration` |
| "review my API spec" / "check the openapi" / "review the contract" / "check my proto" | `/review api` |
| "review e2e tests" / "check my playwright tests" / "review my E2E" | `/review e2e` |
| "review feature flags" / "check flag registry" / "review flags" | `/review flags` |
| "review terraform" / "check IaC" / "review infrastructure code" / "check infra" | `/review iac` |
| "review the ERD" / "check the schema" / "review database design" | `/review schema` |
| "review visual regression" / "check screenshot tests" / "review VRT" | `/review visual` |
| "review chaos tests" / "check chaos engineering" / "review resilience tests" | `/review chaos` |
| "review incident response" / "check postmortem template" / "review IR process" | `/review incident` |
| "review the onboarding guide" / "check ONBOARDING.md" | `/review onboarding` |
| "review DAST" / "check ZAP config" / "review security scan" | `/review dast` |
| "review accessibility tests" / "check WCAG" / "check a11y" | `/review accessibility` |
| "review my API versioning" / "check the versioning strategy" / "review breaking changes" | `/review versioning` |
| "review my sequence diagrams" / "check the sequence diagram" | `/review sequence` |
| "review load tests" / "check my k6 script" / "review performance tests" | `/review performance` |

---

## Integration Points

- `pr-creator` — Step 5: `/review all` before PR is created
- `finishing-a-development-branch` — Step 1.5: before merge or PR option
- `requesting-code-review` — routes here for all agent-backed reviews
- Direct chat / slash command at any point during development
