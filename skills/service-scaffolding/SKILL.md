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
| Infra provisioning | root module that **instantiates a curated golden-path module** from the platform registry (`infrastructure-as-code`) — not hand-written HCL — so infra is self-service and compliant by construction |
| Catalog entry | `catalog-info.yaml` — see below |
| Docs skeleton | Diátaxis-shaped `wiki/` stub (reference + how-to + explanation) |

### Self-service provisioning (CNCF L4 target)

The scaffold is the *template*, but the maturity goal is that instantiating it is
**self-service** — a developer creates a new compliant service without a platform
ticket. CNCF Platform Engineering Maturity Level 4 (Optimizing) is full
self-service with golden paths and automated compliance; that is the direction
this skill points, even where a step is still manual today.

- **Template, not blank page:** the service is generated from a golden-path
  template (Backstage Software Template / `cookiecutter` / a repo template), so
  every artifact above comes pre-wired, not hand-assembled.
- **Curated module registry, not bespoke infra:** the infra root instantiates a
  **versioned module from the platform's curated registry** (private Terraform
  registry / a library of Terraform modules + CRDs the platform team owns).
  Developers instantiate; the platform team curates. See `infrastructure-as-code`
  §Golden-path modules.
- **Compliant by construction:** policy (tfsec / OPA / Conftest) and the paved
  defaults live *inside* the template and module, so a self-service provision
  cannot produce a non-compliant service — the guardrail is the road, not a
  gate bolted on after.
- **Honest maturity marker:** record in the scorecard whether provisioning is
  genuinely self-service (L4) or template-assisted-but-manual (L2–L3). Do not
  claim L4 for a golden path that still needs a human to run it.

## The service catalog

Register every service in `.ai/catalog/services.yaml` (cross-service registry,
deliberately NOT nested under one task folder — same rationale as
`.ai/portfolio/`: it spans every service, not one feature) (or `catalog-info.yaml`
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

Attach `.ai/catalog/scorecards/<service>.md` (same standalone catalog, not
task-scoped) — a maturity checklist the service
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
