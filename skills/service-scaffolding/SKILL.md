---
name: service-scaffolding
description: >
  Use when a new service/component is being created (epic lane) — emit the paved
  starting artifact so the service is born compliant: CI wired, observability
  instrumented, API contract stub, test harness, runbook stub, resource limits,
  and a service-catalog entry, all from the first commit. Registers the service
  in the catalog and attaches a maturity scorecard. Runs service-scaffolding-reviewer.
---

# Service Scaffolding (Golden Path)

The harness paves the *process* but every new service still started from a blank
repo, so CI, observability, contracts, and tests were bolted on later (or not).
A golden path emits the **paved starting artifact** — the service is born with
the guardrails already wired, not retrofitted.

**Standards anchored:** CNCF **Platform Engineering Maturity Model** L3
(Self-Service & Standardization — golden-path templates, service catalog,
scorecards); **Backstage Scaffolder** + `catalog-info.yaml`; per-service
**scorecards** (Cortex / Compass maturity levels).

**Why this matters in the AI age (the golden path is the guardrail):** the 2024
DORA report found that high-quality platform engineering is "the filter" that
determines whether AI-generated code improves or destabilizes delivery. AI makes
spinning up a service cheap; without a paved road each AI-built service
improvises its own (often missing) CI, monitoring, and tests, producing
unobservable, untested sprawl. The scaffold makes the compliant path the default
path, so AI-accelerated creation stays consistent and accountable.

## What the scaffold emits (every new service)

A new service must be born with all of these — a missing one is a scorecard fail:

| Component | Paved-road default |
|---|---|
| CI pipeline | `ci-pipeline-setup` config wired (build/test/lint/coverage, SLSA provenance) |
| Observability | golden-signal instrumentation + SLO stub (`observability-standards`) — born observable |
| API contract | OpenAPI/proto stub before handlers (`api-contract-first`) |
| Test harness | unit + integration skeleton (`test-driven-development`, `integration-testing`) |
| Runbook stub | `wiki/guides/runbooks/<service>.md` skeleton |
| Resource limits | container/K8s manifest with CPU/memory requests+limits set (no unbounded) |
| Catalog entry | `catalog-info.yaml` — see below |
| Docs skeleton | Diátaxis-shaped `wiki/` stub (reference + how-to + explanation) |

## The service catalog

Register every service in `.ai/catalog/services.yaml` (or `catalog-info.yaml`
per service, Backstage-compatible). One entry per service:

```yaml
- name: <service>
  owner: <team/person>
  lifecycle: experimental | production | deprecated
  slo: <link to SLO doc>
  repo: <url>
  depends_on: [<service>, ...]
  runbook: wiki/guides/runbooks/<service>.md
```

The catalog is the single registry of what exists, who owns it, and how healthy
it is — the lookup the portfolio and incident lanes need.

## Scorecards (maturity checks)

Attach `.ai/catalog/scorecards/<service>.md` — a maturity checklist the service
is graded against, so "born observable and accountable" is verifiable, not
aspirational:

- [ ] CI pipeline present and green
- [ ] Golden signals instrumented; SLO defined
- [ ] API contract exists before handlers
- [ ] Unit + integration tests present
- [ ] Runbook exists
- [ ] Resource limits set (no unbounded container)
- [ ] Catalog entry with an owner
- [ ] Security review done for external surfaces

Score = fraction passed. A new service should reach a defined threshold before
`production-readiness-review`.

## Review

Dispatch `service-scaffolding-reviewer` on the generated scaffold + catalog
entry + scorecard. It checks every paved-road component is present, the catalog
entry has an owner and lifecycle, resource limits are set (not unbounded), and
the scorecard is attached. Pass by file path; one fix agent for all findings;
re-review to PASS.

## Integration

- **engineer (epic lane):** runs for a NEW service after HLD approval and
  decomposition, before any child story implements into it — the child stories
  build on the paved artifact.
- **ci-pipeline-setup / observability-standards / api-contract-first /
  integration-testing:** the scaffold wires their outputs from birth rather than
  leaving them for later.
- **portfolio-management / incident-response:** consume the service catalog.
- **production-readiness-review:** the scorecard threshold is a PRR input.
