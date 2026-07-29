---
name: deployment-workflow
description: >
  Use when implementation is complete, before a branch is labeled deployment-ready. Produces a deployment strategy recommendation, zero-downtime migration checklist per DB change, rollback procedure document, post-deploy smoke test spec, and release notes draft from git log. Runs deployment-reviewer agent before committing. A merged PR without a rollback procedure is a future incident waiting to happen.
---

# Deployment Workflow

Produce the deployment artifacts before the PR is opened — not as a post-merge scramble during an incident. Every deployment needs a verified rollback path and a smoke test spec before the first user sees the change.

## References

- **Expand-Contract pattern** (prisma.io/dataguide/types/relational/expand-and-contract-pattern) — zero-downtime DB migrations: Expand → Migrate → Contract
- **Google SRE Workbook: Canarying Releases** (sre.google/workbook/canarying-releases/) — canary with automatic rollback on metric degradation
- **HashiCorp Well-Architected: Zero-Downtime Deployments** (developer.hashicorp.com/well-architected-framework) — strategy selection criteria
- **Keep a Changelog** (keepachangelog.com) — Added/Changed/Deprecated/Removed/Fixed/Security format
- **Conventional Changelog / git-cliff** — automated release notes from Conventional Commits
- **Octopus Deploy: Deployment Checklist** (octopus.com/devops/software-deployments/deployment-checklist) — 16-step pre/deploy/post checklist

---

## When to Use

**Required** before any PR is labeled deployment-ready — invoked from `finishing-a-development-branch`.

**Produces artifacts for:**
- Any feature that changes user-facing behavior
- Any change touching the database schema
- Any new endpoint or service component
- Any dependency upgrade affecting runtime behavior

**Skip** for: documentation-only changes, config-only changes with no runtime effect.

**Infer + confirm:**
> "This is a config-only change with no behavior impact. Skipping deployment-workflow (no rollback procedure, migration checklist, or smoke tests needed). OK?"

---

## Inputs Required

- **Branch diff** — `git diff <base>...HEAD --name-only` to detect DB migrations and changed endpoints
- **Spec** — `.ai/specs/` for the feature (NFRs inform smoke test thresholds)
- **Observability setup** — `.ai/observability/YYYY-MM-DD-slos.md` for SLO targets used in verification
- **Last git tag** — for release notes scope: `git describe --tags --abbrev=0`

---

## Error Budget Release Gate (check FIRST, before recommending a strategy)

Before planning any non-critical release, read the target service's **error
budget status** from its SLO doc (`observability-standards` records it as
`ok | warning | frozen`):

- **frozen (budget exhausted):** **block the release.** Only P0/SEV-1 or security
  fixes ship, each with explicit reliability/SRE approval, until the budget
  recovers. This is the Google SRE error-budget policy — it exists so reliability
  is not silently traded for feature velocity.
- **warning (< ~25% remaining):** proceed with caution; no risky launches; prefer
  a safer strategy (blue-green/canary with tight auto-rollback).
- **ok:** proceed normally.

**AI-age rationale:** AI raises deploy frequency, which the 2024 DORA report ties
to lower delivery stability. The error-budget gate is the objective circuit
breaker that stops AI-accelerated velocity from burning the SLO — it binds
regardless of how fast a change was produced. If no SLO/error budget exists yet,
that is itself a release blocker: invoke `observability-standards` first.

## Process

1. **Detect what changed** — DB migrations? New endpoints? Breaking changes? Config changes?
2. **Recommend deployment strategy** — based on system type and change risk
3. **Write zero-downtime migration checklist** — if DB migrations detected (expand-contract per change)
4. **Write rollback procedure** — step-by-step, estimated time, staging verification requirement
5. **Write smoke test spec** — per endpoint created/modified; three verification phases
6. **Draft release notes** — from `git log <last-tag>..HEAD`, Conventional Commits format
7. **Write deployment runbook** — ordered checklist from pre-deploy through post-deploy monitoring
8. **Run `deployment-reviewer` agent** — fix Critical and Important findings
9. **Commit all artifacts** — before PR is opened

---

## Deployment Strategy Selection

Choose based on system type and change risk. State the choice explicitly in the runbook.

| Strategy | Best for | Rollback | Cost |
|----------|---------|---------|------|
| **Rolling** | Stateless services, K8s, default choice | `kubectl rollout undo` — seconds | Low |
| **Blue-Green** | Stateful services, DB-heavy changes, need instant router-level rollback | Reverse LB rule — seconds | High (2× infra) |
| **Canary** | High-traffic, risk-averse, gradual validation (1% → 10% → 100%) | Shift traffic back to stable — seconds | Medium |
| **Dark Launch** | High-risk feature, shadow traffic validation needed | No user impact — no rollback needed | Medium |

**Selection guidance:**
- Database schema change → **Blue-Green** or **Canary** (not Rolling — old version must still be able to read DB)
- New stateless endpoint → **Rolling** (simple, cheap, default)
- Major feature impacting many users → **Canary** (limit blast radius)
- Security fix or patch → **Blue-Green** (instant rollback if regression found)
- Rollout needs a kill switch, percentage ramp, or A/B split independent of deploy → invoke `feature-flags` before finalizing the strategy; the flag becomes the actual rollback lever instead of a full redeploy

### Automated Canary Analysis (required when the strategy is Canary)

A canary that a human watches on a dashboard is a manual gate — it fails exactly
when everyone is asleep. When the strategy is Canary, the rollback trigger below
("When to Rollback") must be **executed by the rollout controller, not a person**:
the controller queries the SLIs at each traffic step and auto-promotes on healthy,
auto-aborts-and-rolls-back on breach.

Specify, in the runbook, an analysis definition the controller enforces:

- **Controller + analysis:** Argo Rollouts `AnalysisTemplate`, Flagger
  `MetricTemplate`, or Kayenta automated canary analysis (Mann-Whitney statistical
  comparison of canary vs. baseline). Pick the one native to the platform.
- **Metric provider:** where the SLIs are read — Prometheus, Datadog, CloudWatch,
  New Relic, or Kayenta.
- **SLI queries tied to the SLOs** (not arbitrary numbers): the same error-rate and
  latency SLIs the `observability-standards` SLO document defines. A canary that
  passes on metrics unrelated to the SLO proves nothing.
- **Step schedule + analysis per step:** e.g. 1% → 10% → 50% → 100%, with the
  analysis run at each step before promotion.
- **Failure condition → automatic abort:** breach of the SLI threshold (or a
  failed Mann-Whitney vs. baseline) aborts the rollout and shifts 100% of traffic
  back to stable with no human in the loop. `failureLimit`/`inconclusive` handling
  stated explicitly.

```yaml
# Argo Rollouts AnalysisTemplate (illustrative) — SLIs from the SLO doc
metrics:
  - name: error-rate
    interval: 1m
    failureLimit: 2               # abort after 2 breaching reads
    successCondition: result < 0.01   # ties to the 99% success SLO
    provider:
      prometheus:
        query: |
          sum(rate(http_requests_total{status=~"5..",app="{{args.svc}}"}[1m]))
          / sum(rate(http_requests_total{app="{{args.svc}}"}[1m]))
```

This makes the "When to Rollback" trigger machine-enforced: the same conditions a
human would watch for become the controller's abort criteria, so a bad canary
rolls back in seconds regardless of who is watching.

---

## Zero-Downtime Migration Checklist

**Required if:** `git diff <base>...HEAD --name-only | grep -i migrat` finds migration files.

Apply the **Expand-Contract pattern** (Prisma Data Guide) per migration. Breaking schema changes in 3 deployments:

````markdown
# Migration Safety Checklist — [Feature Name]

**Migration files:** [list files]
**Pattern:** Expand-Contract (zero-downtime)

---

## Phase 1 — Expand (Deploy with old + new schema)

- [ ] New column added as NULLABLE (no NOT NULL constraint yet)
- [ ] New column has no foreign key constraint requiring data (add after backfill)
- [ ] Application code writes to BOTH old and new column/table
- [ ] Old column/table still read by application code
- [ ] Migration is backward-compatible: previous app version can still run against new schema
- [ ] Verify: deploy v_new alongside v_old — both function correctly

## Phase 2 — Migrate (Backfill existing data)

- [ ] Backfill script runs in batches (not a single UPDATE — locks table)
- [ ] Batch size: ≤ 1,000 rows per transaction to avoid lock escalation
- [ ] Progress tracked: log every 10k rows backfilled
- [ ] Verify: `SELECT COUNT(*) WHERE new_column IS NULL` = 0 before Phase 3

## Phase 3 — Contract (Remove old structure)

- [ ] Application code no longer reads from old column/table
- [ ] NOT NULL constraint added (if required)
- [ ] Index added (if required for query performance)
- [ ] Old column/table dropped in separate migration
- [ ] Verify: `SELECT COUNT(*) FROM information_schema.columns WHERE column_name = '<old_col>'` = 0

---

## Rollback per Phase

| Phase | Rollback action |
|-------|----------------|
| Phase 1 fails | Drop new column (no data loss) |
| Phase 2 fails | Stop backfill, revert app to Phase 1 code, re-examine backfill |
| Phase 3 fails | Do not drop old column yet; re-examine code dependencies |
````

---

## Rollback Procedure Document

Save to: `.ai/deployment/YYYY-MM-DD-rollback.md`

````markdown
# Rollback Procedure — [Feature Name]

**Estimated rollback time:** [N] minutes
**Tested in staging:** [ ] Yes — [date tested] / [ ] No — MUST test before production deploy
**Rollback owner:** [on-call role or name]

---

## When to Rollback

Trigger rollback if, within 30 minutes of production deploy:
- Error rate rises > 2× pre-deploy baseline
- p99 latency rises > 50% above SLO threshold
- Smoke tests fail
- Manual decision by on-call engineer

**Under a Canary strategy these are the controller's automated abort conditions
(see Automated Canary Analysis above), not a dashboard someone watches** — encode
the first three as the `AnalysisTemplate` failure conditions so rollback is
automatic; the manual trigger remains as the human override.

Do NOT wait for a postmortem. Rollback first, investigate after.

---

## Pre-Rollback Steps (2 minutes)

1. Notify team: post in [incident channel] — "Initiating rollback of [feature] — [timestamp]"
2. Capture current state: `[command to capture metrics snapshot or error log]`
3. Confirm rollback target version: `[command to show current + previous version]`

---

## Rollback Steps

### Application Rollback

**Rolling (Kubernetes):**
```bash
kubectl rollout undo deployment/<service-name> -n <namespace>
kubectl rollout status deployment/<service-name> -n <namespace> --timeout=5m
```

**Blue-Green:**
```bash
# Switch LB/router back to blue environment
[platform-specific routing command]
```

**Canary:**
```bash
# Shift 100% traffic back to stable
[platform-specific canary rollback command]
```

### Database Rollback (if applicable)

**Phase 1 migration (expand only — safe to revert):**
```bash
[migration rollback command — e.g. alembic downgrade -1 / rails db:rollback]
```

**Phase 2/3 migration (data exists — do NOT auto-rollback):**
- Stop here. Consult the team.
- Data in new schema cannot be safely dropped.
- Fix-forward is the path (not rollback).

---

## Verification (5 minutes post-rollback)

- [ ] Health check: `curl -sf $PROD_URL/health && echo "OK"`
- [ ] Error rate returns to pre-deploy baseline (check dashboard)
- [ ] p99 latency returns to SLO range (check dashboard)
- [ ] Smoke test re-run: [command]
- [ ] Alert clears within 5 minutes

---

## If Rollback Fails

Estimated time remaining: [N] minutes to full resolution

1. Escalate to: [escalation contact/rotation]
2. Enable maintenance mode if applicable: [command]
3. Disable feature flag if applicable: [command]
4. Open incident: [incident management tool/channel]
````

---

## Post-Deploy Smoke Test Spec

Save to: `.ai/deployment/YYYY-MM-DD-smoke-tests.md`

````markdown
# Post-Deploy Smoke Tests — [Feature Name]

**Run immediately after deploy.** Target: all pass within 5 minutes.
**On failure:** initiate rollback per `.ai/deployment/YYYY-MM-DD-rollback.md`

---

## Phase 1 — Immediate (0–5 minutes)

| Check | Command / URL | Expected result |
|-------|--------------|----------------|
| Health endpoint | `curl -sf $PROD_URL/health` | HTTP 200, `{"status":"ok"}` |
| [Critical endpoint 1] | `curl -sf $PROD_URL/api/[path]` | HTTP 200, [expected field present] |
| [Critical user journey] | [smoke test command or synthetic check] | [expected behavior] |
| Auth flow | `curl -sf -H "Authorization: Bearer $TEST_TOKEN" $PROD_URL/api/me` | HTTP 200 |
| Database connectivity | [health check that exercises a DB read] | Returns expected data |

## Phase 2 — Short-term (5–30 minutes)

Monitor in dashboard or via query:

| Metric | Threshold | Action if breached |
|--------|-----------|-------------------|
| Error rate | < 2× pre-deploy baseline | Initiate rollback |
| p99 latency | < SLO threshold | Investigate, consider rollback |
| Active connections | < 80% of pool limit | Alert — investigate |
| Memory (if applicable) | No upward trend | Flag — potential leak |

## Phase 3 — Stability (1 hour)

- [ ] Error budget burn rate not elevated vs baseline
- [ ] No memory leak signals (flat memory curve)
- [ ] No unexpected log volume spike
- [ ] No spike in support tickets or user-facing errors (if monitored)

---

## Automated Smoke Test Command

```bash
# Run after every production deploy
[test runner command — e.g. npm run test:smoke or pytest tests/smoke/]
```

Expected: all pass. On any failure → rollback immediately.
````

---

## Release Notes Draft

Generate from git log using Conventional Commits:

```bash
# Get commits since last tag
git log $(git describe --tags --abbrev=0)..HEAD \
  --pretty=format:"- %s (%h)" \
  --no-merges
```

Organize by type into **Keep a Changelog** format. Save to: `wiki/changelog/YYYY-MM-DD-<version>.md`

````markdown
# [v1.2.0] — YYYY-MM-DD

## Added
<!-- feat: commits -->
- [description] ([hash])

## Changed
<!-- feat: commits that modify existing behavior -->
- [description] ([hash])

## Fixed
<!-- fix: commits -->
- [description] ([hash])

## Security
<!-- fix: commits touching auth, input validation, secrets -->
- [description] ([hash])

## Breaking Changes
<!-- feat!: or BREAKING CHANGE: commits -->
- **[description]** — [migration path for users]

## Deprecated
<!-- Functionality that works but will be removed in a future release -->

## Removed
<!-- Previously deprecated items now removed -->
````

**Automation note:** `git-cliff` (Rust, fast) or `conventional-changelog` generate this automatically from Conventional Commits. Use if project has them installed.

---

## Deployment Runbook

Save to: `.ai/deployment/YYYY-MM-DD-deploy-runbook.md`

````markdown
# Deployment Runbook — [Feature Name]

**Deployment strategy:** [Rolling | Blue-Green | Canary]
**Estimated deploy time:** [N] minutes
**Rollback time:** [N] minutes
**On-call:** [name/rotation]
**DB migrations:** [Yes — Phase N | No]

---

## Pre-Deploy Checklist (T-30 minutes)

- [ ] All CI checks green on branch
- [ ] `deployment-reviewer` passed (no Critical findings)
- [ ] Staging deployed and smoke tests passing
- [ ] Rollback procedure reviewed and tested: `.ai/deployment/YYYY-MM-DD-rollback.md`
- [ ] On-call briefed on what is shipping
- [ ] Observability dashboard open: [dashboard link]
- [ ] Feature flag configured (if applicable)
- [ ] DB migration Phase 1 already deployed (if using expand-contract)

## Deploy Steps

1. Trigger deployment: [command or CI job name]
2. Monitor rollout progress: [command to watch rollout]
3. Confirm new version running: [command to verify version]

## Post-Deploy Verification (first 5 minutes)

Run smoke tests: [command]

- [ ] All Phase 1 smoke tests pass (see `.ai/deployment/YYYY-MM-DD-smoke-tests.md`)
- [ ] Error rate stable in dashboard
- [ ] No spike in p99 latency

## 30-Minute Watch

- [ ] Phase 2 smoke test thresholds not breached
- [ ] Error budget burn rate not elevated
- [ ] No unexpected alerts fired

## Deployment Complete

- [ ] Post to [incident/deployment channel]: "Deploy of [feature] complete at [timestamp] — monitoring stable"
- [ ] Update ticket/issue status

## If Issues Found

See rollback procedure: `.ai/deployment/YYYY-MM-DD-rollback.md`
````

---

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review

## Self-Review: Run `deployment-reviewer` Agent

After writing all artifacts, before committing:

```
Agent(deployment-reviewer, {
  ROLLBACK_PATH: ".ai/deployment/YYYY-MM-DD-rollback.md",
  SMOKE_TEST_PATH: ".ai/deployment/YYYY-MM-DD-smoke-tests.md",
  RUNBOOK_PATH: ".ai/deployment/YYYY-MM-DD-deploy-runbook.md",
  MIGRATION_CHECKLIST_PATH: ".ai/deployment/YYYY-MM-DD-migration.md",  // omit if no DB changes
  SPEC_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md"
})
```

Fix all **Critical** findings. **Important** findings should be fixed. Advisory may be deferred.

---

## Commit

```
feat(deployment): add rollback procedure, smoke tests, and deploy runbook

[body: WHY — what is the deployment risk, what would happen without these artifacts]
```

Deployment artifacts commit before or alongside the PR — never after.
---

## Completion Report

When this skill's work is done, report to the user in chat — do not let a commit
message be the only trace of what happened:

- **Produced:** what was created or changed (artifact type + exact path).
- **Verdict:** the reviewer's PASS / NEEDS WORK / BLOCKED result, if a gate ran.
- **Coverage:** which spec REQ / NFR this satisfies, where applicable.
- **Next:** the next step in the flow, or "ready for review / merge".

One line per item is enough. The point is that the user sees what shipped and
its verdict without having to read the diff.
