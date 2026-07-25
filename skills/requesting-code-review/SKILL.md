---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging. Routes to the right review agent(s) based on context. For full suite use /review all. For targeted review use /review <type>.
---

# Requesting Code Review

Route to the right review agent(s) for what you've built. Reviews are mandatory before merge — the type and depth depend on what changed.

**Core principle:** Review early, review often. After each task, not just at PR time.

`pr-reviewer` walks every commit in the range, not just the aggregate diff — if it flags the range as too large to review thoroughly (30+ commits or ~1000+ changed lines), split the PR before re-requesting review rather than pushing for a faster pass.

---

## PR Size Gate (evidence-backed — check BEFORE dispatching any reviewer)

Review effectiveness is dominated by one variable: **change size**. This is the
best-measured lever in code review, so it gates first.

| Changed LOC (added + modified, excluding generated/vendored/lockfiles) | Action |
|---|---|
| ≤ 200 | Ideal — dispatch review |
| 201–400 | Good — dispatch review |
| 401–1000 | **Warn** — split if the diff spans independent concerns; otherwise proceed and tell the reviewer where to focus |
| > 1000 | **Block** — split into reviewable PRs before requesting review |

Evidence (SmartBear 2,500-review study; Google *Modern Code Review*): defect
detection peaks at **200–400 changed LOC** and ~60 minutes, and collapses from
~87% under 100 LOC to ~28% over 1,000 LOC. A 2,000-line PR is not "one big
review" — it is a review that silently misses two-thirds of its defects.

**Measure before requesting:**
```bash
git diff --numstat <base>...HEAD | awk '$1!="-"{a+=$1} $2!="-"{m+=$2} END{print a+m" changed LOC"}'
# Exclude generated/vendored: add  | grep -vE '(lock|\.min\.|dist/|vendor/|generated/)'
```
If over 1000, stop and split — one vertical slice per PR (see `epic-decomposition`).

## Review Latency Norm

Slow review decays the whole team's throughput (Google: review delay reduces
productivity super-linearly). Target a **first reviewer response within one
business day**. For AI reviewers this is immediate; the norm binds human
reviewers in the loop and any queued re-review after a fix.

## Reviewing AI-Authored Code (default assumption in this harness)

Most diffs here are AI-authored, so treat every review as an AI-code review
unless told otherwise. Two grounded facts set the posture:

- The **2024 DORA report** found AI adoption raises throughput but **lowers
  delivery stability (~7.2% per 25% adoption)** — "more code, more breakage."
  Small batch size is the named mitigation, so the **PR Size Gate above is
  stricter, not laxer, for AI diffs** — an AI can emit 1,500 plausible lines in
  a minute; that is the exact shape the evidence says review misses.
- AI code **reads cleanly and passes the happy path** while hiding specific
  defect classes; ~76% of developers report frequent AI hallucinations.

**Inspect the assumptions behind the code, not just its surface** — inputs,
outputs, dependencies, permissions, failure modes. Explicitly check for:

| AI-specific risk | What to verify |
|---|---|
| Hallucinated APIs / non-existent packages | Every imported symbol and dependency actually exists and is the current, non-deprecated one |
| Insecure/outdated libraries | No known-vulnerable or abandoned deps introduced |
| Hardcoded secrets | No API keys/tokens/passwords in the diff (AI frequently inlines these) |
| Happy-path-only logic | Error paths, empty/nil/boundary inputs, and concurrency are handled, not just the nominal case |
| Missing authorization | Auth/authz checks present on every new path — never assume the AI added them |
| Confident-but-wrong behavior | Claimed library/framework behavior matches its real contract (read the source, not the docstring) |

**Never skip human review for AI-authored code touching authentication,
payments, PII, or security boundaries** — route it through `security-reviewer`
regardless of size. AI review tools catch ~42–48% of runtime bugs (vs <20% for
static analysis) but do not replace the human gate on high-blast-radius code.

---

## Review Agent Roster

| Agent | Invocation | Use when |
|-------|-----------|----------|
| `pr-reviewer` | `/review pr` | Every PR, always. 6 dimensions (code quality, docs, security, reliability, performance, AI-authored-code risk) + traceability. Blocks without spec. |
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
| `feature-flag-reviewer` | `/review flags` | When feature flags are added. Naming conventions, registry completeness, CI hygiene, safe defaults, cleanup queue — 5 dims. Not in `/review all`. |
| `iac-reviewer` | `/review iac` | When IaC is added or changed. Pinned versions, remote state+locking, sensitive vars, env separation, tfsec scan, no secrets — 6 dims. Not in `/review all`. |
| `database-erd-reviewer` | `/review schema` | When ERD is written or updated. PKs, FK validity, crow's foot cardinality, no float money, index strategy, design decisions — 6 dims. Not in `/review all`. |
| `visual-regression-reviewer` | `/review visual` | When visual regression tests are written. Screenshots on critical pages, animations off, baselines committed, masked dynamic content, pinned Docker — 5 dims. Not in `/review all`. |
| `chaos-reviewer` | `/review chaos` | When chaos tests are written. Steady state + hypothesis, HLD failure modes, graceful degradation thresholds, abort criteria, CI staging — 5 dims. Not in `/review all`. |
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

## Reviewer Dispatch Discipline

When dispatching any reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review

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

For structured triage and resolution of returned findings (not just re-running the same reviewer), invoke `receiving-code-review`.

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
