---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging. Routes to the right review agent(s) based on context. For full suite use /review all. For targeted review use /review <type>.
---

# Requesting Code Review

Route to the right review agent(s) for what you've built. Reviews are mandatory before merge — the type and depth depend on what changed.

**Core principle:** Review early, review often. After each task, not just at PR time.

---

## Review Agent Roster

| Agent | Invocation | Use when |
|-------|-----------|----------|
| `pr-reviewer` | `/review pr` | Every PR, always. 5 dimensions (code quality, docs, security, reliability, performance) + traceability. Blocks without spec. |
| `spec-impl-reviewer` | `/review spec` | You have a spec and want to verify the implementation actually satisfies acceptance criteria — not just that annotations exist. |
| `test-quality-reviewer` | `/review tests` | Tests were added or modified. Checks meaningful assertions, spec TC coverage, mutation resistance, anti-patterns. |
| `security-reviewer` | `/review security` | PR touches auth, input handling, data access, external communication, config, or adds new endpoints/handlers. |
| `full-project-reviewer` | `/review full` | Before releases, after major milestones, full codebase audit. Not per-PR. |
| `language-expert-reviewer` | `/review lang` | When language depth matters: C++/Rust/Go/Python/TS/Java. Checks type system, UB, ownership, idioms, concurrency, error handling, stdlib, performance, standard compliance, safety — 10 dimensions. |
| `ci-reviewer` | `/review ci` | When CI config is created or modified. Validates stage completeness, fail-fast ordering, security hygiene, coverage gate, artifact immutability, DORA readiness. Not in `/review all`. |
| `hld-reviewer` | `/review hld` | When HLD is written or updated. Validates C4 diagrams, tech selection, STRIDE threat model, failure modes, capacity planning, ADRs — 10 dimensions. Not in `/review all`. |
| `observability-reviewer` | `/review observability` | When observability is set up or updated. Validates OTel logging, golden signals, SLO quality, alert design (symptom-based, burn rate), runbook completeness — 7 dimensions. Not in `/review all`. |
| `deployment-reviewer` | `/review deployment` | When deployment artifacts are created. Validates rollback procedure, DB migration safety (expand-contract), smoke test coverage, deployment runbook, release notes — 6 dimensions. Not in `/review all`. |
| `integration-test-reviewer` | `/review integration` | When integration tests are written. Validates no mocks at boundary, isolation (rollback), factory pattern, Testcontainers config, spec AC coverage, contract tests, CI wiring — 7 dimensions. Not in `/review all`. |
| `api-contract-reviewer` | `/review api` | When API spec is written or updated. Validates completeness, error taxonomy, security, breaking changes, schema quality, REQ coverage, naming consistency — 7 dimensions. Not in `/review all`. Run before any handler implementation. |
| `e2e-reviewer` | `/review e2e` | When E2E tests are written. Validates critical journey coverage, semantic selectors, no hardcoded waits, test independence, POM, auth fixtures, CI integration — 7 dimensions. Not in `/review all`. |
| `incident-response-reviewer` | `/review incident` | When IR docs are created. Severity matrix, IC role, 7-section postmortem, MTTD/MTTR targets — 5 dims. Not in `/review all`. |
| `onboarding-reviewer` | `/review onboarding` | When onboarding guide is created or updated. Validates 8 sections, dev setup, C4 diagram, ADRs, harness workflow, actionable ops. Not in `/review all`. |
| `dast-reviewer` | `/review dast` | When DAST is configured. Validates ZAP baseline on PRs, API scan on staging, HIGH fails CI, SARIF upload, auth — 5 dims. Not in `/review all`. |
| `accessibility-reviewer` | `/review accessibility` | When UI feature ships. Validates axe-playwright on critical pages, WCAG 2.1 AA (+ 2.2 for EU), violations fail CI, exclusions documented — 4 dims. Not in `/review all`. |
| `api-versioning-reviewer` | `/review versioning` | When versioning strategy is defined or updated. Validates ADR, breaking change policy, Sunset headers, migration guides, CI detection — 5 dimensions. Not in `/review all`. |
| `sequence-diagram-reviewer` | `/review sequence` | When sequence diagrams are written. Validates flow coverage, error paths, arrow types (sync/async), auth boundary, HLD participant alignment — 5 dimensions. Not in `/review all`. |
| `load-test-reviewer` | `/review performance` | When load tests are written. Validates NFR-aligned thresholds, smoke test, realistic traffic, appropriate test types (soak for 99.9% availability), CI integration — 6 dimensions. Not in `/review all`. |
| **All at once** | `/review all` | Before any merge. Runs all four PR-scoped agents in parallel. |

---

## When to Use Which

### Minimum (every PR)
```
/review pr
```

### Standard (recommended for all feature PRs)
```
/review all
```
Runs pr-reviewer + spec-impl-reviewer + test-quality-reviewer + security-reviewer in parallel.

### After each task (during subagent-driven development)
```
/review pr
```
Catch issues before they compound. Fix before moving to next task.

### Before merge (mandatory)
```
/review all
```
All four agents. Aggregated report. No merge if any Critical finding.

### Full codebase audit (periodic)
```
/review full
```
Not per-PR. Use after significant milestones or before production releases.

### Language-expert review (on-demand)
```
/review lang
```
Use when: C++/Rust code with complex ownership; performance-critical code; onboarding to a codebase with unusual language patterns; before a release on safety-critical code. Asks for language + standard, then runs 10 dimensions.

---

## How to Request

**Quick (most common):**
```
/review all
```
The `review` skill collects inputs, dispatches all agents in parallel, aggregates results.

**Targeted:**
```
/review security      ← just security
/review spec          ← just spec correctness
/review tests         ← just test quality
```

**Direct from chat:**
- "review my PR" → routes to `/review pr`
- "does this satisfy the spec" → routes to `/review spec`
- "check my tests" → routes to `/review tests`
- "security review" → routes to `/review security`

---

## Act on Feedback

| Severity | Action |
|----------|--------|
| Critical | Fix immediately before any other work |
| Important | Fix before merge — do not proceed |
| Minor | Note for later, address when possible |

Push back if reviewer is wrong — with technical reasoning and evidence.

---

## Self-Check Before Requesting

Before routing to any review agent, run the `design-principles` **Review Checklist**. Sending a design-violated diff multiplies review cost — fix structural violations first.

See `design-principles/SKILL.md` → Review Checklist.

## Integration

- **Subagent-driven development:** `/review pr` after each task
- **pr-creator:** runs `/review all` automatically before creating PR (Step 5)
- **finishing-a-development-branch:** runs `/review all` before merge/PR options
- **Ad-hoc:** `/review <type>` any time during development

See `review/SKILL.md` for the full orchestration logic.
