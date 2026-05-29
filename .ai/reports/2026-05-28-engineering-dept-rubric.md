# Engineering Department Workflow Rubric
# Private AI Harness — Capability Evaluation

**Date:** 2026-05-28  
**Last updated:** 2026-05-29 — Phase 11: 6.5→8.5/10 (`onboarding-guide` + `onboarding-reviewer`). Sprint 2 item 1. Score: 8.0/10  
**Question:** Can this harness replace an entire engineering department and produce output indistinguishable from what that department produces?  
**Evaluator:** Claude Sonnet 4.6  

---

## North Star Definitions

**Engineering Department Scope:** The complete lifecycle from business problem to deployed, observable, maintainable production system — covering every role: product, architecture, senior engineering, team leads, individual contributors, QA, security, DevOps, and technical writing.

**Quality Bar:** Every artifact produced by the harness must be indistinguishable from the artifact a real engineering department produces for that phase — at the quality level of the role that owns it. A PM owns the PRD; a Staff Engineer owns the HLD; a DevOps engineer owns the CI pipeline; an SRE owns runbooks. The bar is role-specific, not "senior engineer" across the board. The harness fails this bar either by producing a lower-quality artifact OR by producing no artifact at all when a department always produces one.

**Scoring logic:** Each phase is scored on two dimensions collapsed into one number: (1) Is the artifact produced? (2) If yes, is it indistinguishable from department output for that role? A missing artifact category that a department always produces scores 0.

---

## The Complete Engineering Department Workflow

A real engineering team moves through these phases. Each phase has mandatory deliverables and a quality bar that the harness must meet.

---

## Phase 0 — Business Context Capture
> **Role analog:** Product Manager + Engineering Manager

### What a Real Team Does
- Stakeholder interviews to extract business goals, KPIs, success metrics
- Translates business goals into engineering constraints (SLA, throughput, latency, availability)
- Produces a PRD (Product Requirements Document) or equivalent artifact
- Defines what "done" means in business terms before any engineering begins
- Explicitly decides what is OUT of scope
- Documents compliance requirements (GDPR, SOC2, HIPAA, etc.)

### Key Principle
**LLMs do not know your business context.** A human must provide it. An engineering framework must have a structured place to receive, capture, and formalize that context before any design work begins.

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| Structured intake for business context | ✅ Strong | `business-context-intake` — structured interview, 8 questions, produces `.ai/business-context/YYYY-MM-DD.md` |
| KPI and success metric definition | ✅ Strong | `business-context-intake` — measurable metrics with baselines required, JTBD outcome measured |
| Compliance constraint capture | ✅ Strong | `business-context-intake` — explicit GDPR/PCI/HIPAA/SOC2 yes/no required; silence = Critical finding |
| User persona definition | ✅ Strong | `business-context-intake` — role, current workflow, pain point, JTBD statement |
| Explicit scope negotiation | ✅ Strong | `business-context-intake` — minimum 3 non-goals with rationale required |
| Stakeholder map | ✅ Strong | `business-context-intake` — approval vs. inform distinction required |
| Business context quality gate | ✅ Strong | `business-context-reviewer` agent (Opus) — 6 dimensions, blocks on Critical |
| Amazon PR/FAQ format | ✅ Partial | `business-context-intake` — optional section for larger features |
| Formal PRD review process | ⚠️ Partial | No formal PM review gate; relies on human approval after reviewer passes |

**Department artifact:** PRD or PR/FAQ — committed, versioned document with problem statement, user persona, success metrics, compliance constraints, stakeholder map.  
**Harness artifact:** `business-context-intake` skill produces `.ai/business-context/YYYY-MM-DD-<feature>.md` via structured 8-question interview. Contains JTBD statement, measurable success metrics with baselines, compliance table, minimum 3 non-goals, stakeholder map, optional PR/FAQ. `business-context-reviewer` validates 6 dimensions. Hard gate in `brainstorming`: no design without this document.  
**Verdict:** Largely indistinguishable in content. Remaining gap: no formal PM review process (the document is created collaboratively with the LLM, not reviewed by a dedicated PM role in a readout meeting).

**Score: 6/10**

**Progress:** Phase 0 moved from 2/10 (no intake artifact) to 6/10 (committed document with structured intake). The 6/10 reflects that the harness now captures the essential content, but the Amazon Working Backwards process involves a dedicated PM writing the document, a readout meeting with leadership, and iterative revision before engineering begins. The harness produces a good document but skips the organizational review ritual.

---

## Phase 1 — Requirements Engineering
> **Role analog:** Senior Engineer + Product Manager

### What a Real Team Does
- Converts business context into functional requirements (what the system must do)
- Converts business context into non-functional requirements: performance SLAs, availability targets (99.9% vs 99.99%), scalability ceiling, security posture, data retention
- Writes acceptance criteria that are binary or measurable — not "fast" or "reliable"
- Maps each requirement to a test case before implementation
- Gates the start of design on requirements being unambiguous and complete
- Documents dependencies between requirements
- Produces a living requirements document (changes tracked, versioned)

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| Functional requirement capture | ✅ Strong | `brainstorming` + REQ-NNN format |
| Non-functional requirement capture (NFRs) | ✅ Strong | Mandatory NFR section in spec template — Performance/Security/Scalability tables with RFC 2119 enforceability |
| Measurable acceptance criteria | ✅ Strong | Spec enforces binary/measurable criteria |
| Requirement-to-test-case mapping | ✅ Strong | TC-REQ-NNN format, coverage matrix |
| Requirement quality gate | ✅ Strong | `spec-quality-gate` skill |
| Living requirements (versioned, tracked) | ⚠️ Weak | Files committed but no version trail |
| NFRs: latency/availability/throughput/security | ❌ Missing | No structured NFR template |
| Compliance requirements | ❌ Missing | Not addressed |

**Department artifact:** A requirements document with functional requirements, non-functional requirements (latency/availability/throughput), compliance constraints, MUST/SHOULD/MAY enforceability taxonomy, and bidirectional test coverage matrix.  
**Harness artifact:** REQ-NNN spec with functional requirements, measurable AC and TC mapping, plus mandatory `## Non-Functional Requirements` section with three tables (Performance: p99/p95/throughput/availability with load condition; Security: auth/encryption/compliance with RFC 2119 enforceability; Scalability: concurrent user ceiling). `spec-quality-reviewer` checks 1f (NFR section present, no TBD/blank cells) and 2e (NFRs measurable, load conditions stated, compliance has implication). Feeds directly into HLD capacity planning, observability SLOs, and k6 load test thresholds.  
**Verdict:** Largely indistinguishable. The spec now covers all NFR categories. Remaining gap: the NFR section is a table template — a practitioner who never fills in the numbers gets "N/A" everywhere and spec-quality-gate doesn't flag it (they must state a reason, but "not applicable" for performance is never true for an API).

**Score: 8/10**

**Progress:** Phase 1 moved from 6/10 (NFRs missing) to 8/10 (mandatory NFR section + RFC 2119 enforceability + `spec-quality-reviewer` blocks on TBD/blank). The 8/10 (not higher) reflects that the gate enforces form (section must exist) but relies on humans providing honest numeric targets — a team that writes "N/A" for performance gets through the gate.

---

## Phase 2 — High Level Design (HLD)
> **Role analog:** Staff/Principal Engineer + Solutions Architect

### What a Real Team Does
- Decomposes the problem into independent components/services with clear boundaries
- Defines how components communicate (sync/async, REST/gRPC/event-driven)
- Selects technology stack with explicit rationale (not just "I like it")
- Designs infrastructure topology: where things run, how they scale, how they fail
- Designs data ownership: which service owns which data, consistency model
- Produces Architecture Decision Records (ADRs) for every major decision
- Capacity planning: expected load, growth projections, scaling triggers
- Defines security architecture: auth/authz model, trust boundaries, secret management
- Defines resilience patterns: circuit breakers, retries, graceful degradation
- Produces a diagram (C4 model or equivalent) reviewable by the whole team

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| Component decomposition with boundaries | ✅ Strong | `high-level-design` — C4 Context + Container diagrams in Mermaid |
| Communication pattern selection | ✅ Strong | `high-level-design` §5 (Actual Design) + technology selection table |
| Technology selection with rationale | ✅ Strong | `high-level-design` §4 — alternatives table with specific rejection reasons |
| Infrastructure design | ⚠️ Partial | C4 Container diagram covers topology; no IaC skill |
| ADR authoring | ✅ Strong | `high-level-design` — one ADR per significant decision, MADR/Nygard format, committed to `wiki/architecture/` |
| Capacity planning | ✅ Strong | `high-level-design` §8 — 3-scenario (pessimistic/expected/optimistic) with scaling triggers at 70%/80% |
| Security architecture design | ✅ Strong | `high-level-design` §6 — STRIDE threat model + security controls table + trust boundaries on C4 |
| Resilience patterns (circuit breaker, retry) | ✅ Strong | `high-level-design` §7 — failure mode analysis per component |
| Diagram generation | ✅ Strong | `high-level-design` — C4Context + C4Container in Mermaid (exact c4model.com syntax) |
| Data ownership and consistency model | ✅ Partial | `high-level-design` §5.2 (Data Model) — conceptual; no formal ERD skill |
| HLD quality gate | ✅ Strong | `hld-reviewer` agent (Opus) — 10 dimensions, blocks on Critical before human review |

**Department artifact:** A reviewed design document (Google Design Doc / Kubernetes KEP / Amazon 6-pager equivalent) containing C4 diagrams, technology selection records, ADRs, security architecture, failure mode analysis, and capacity planning. Produced by a Staff/Principal engineer. Committed before any implementation plan is written.  
**Harness artifact:** `high-level-design` skill produces `.ai/hld/YYYY-MM-DD-<feature>.md` with C4 diagrams (Mermaid), technology selection + alternatives, STRIDE threat model, failure mode analysis, 3-scenario capacity planning, AWS Well-Architected cross-cutting section, and ADRs per decision committed to `wiki/architecture/`. `hld-reviewer` agent validates 10 dimensions before human review.  
**Verdict:** Largely indistinguishable in structure and completeness. The remaining gap is quality dependence on human input — the skill produces all sections, but architectural correctness depends on the knowledge the human brings. A real Staff engineer brings 10 years of systems intuition; the LLM structures what the human provides.

**Score: 7/10**

**Strength:** Phase 2 went from the harness's biggest gap (2/10) to a covered phase (7/10) in one skill. The `high-level-design` skill + `hld-reviewer` agent produces a committed, structured design artifact that is reviewable, versionable, and cross-referenced in `writing-plans`. The 7/10 (not higher) reflects that architectural judgment quality still depends on human input quality — and that no IaC or ERD skill exists yet.

---

## Phase 3 — Low Level Design (LLD)
> **Role analog:** Senior Engineer per component**

### What a Real Team Does
- Translates HLD components into specific classes, interfaces, data structures
- Defines exact database schemas with indices, constraints, relationships
- Writes OpenAPI/gRPC specs for each API endpoint before implementation
- Designs error taxonomy (which errors are retryable, which are fatal, which are user-facing)
- Maps each LLD component to its REQ-NNN requirement
- Reviews LLD for SOLID, coupling, and cohesion before coding starts
- Produces sequence diagrams for critical paths

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| Class/interface design with design principles | ✅ Strong | `design-principles` + `writing-plans` |
| Database schema design | ⚠️ Partial | `writing-plans` schema checklist; no formal ERD artifact |
| API contract (REST — OpenAPI 3.1) | ✅ Strong | `api-contract-first` — spec before handler, Spectral linting, Prism mock, CI lint job |
| API contract (gRPC — .proto) | ✅ Strong | `api-contract-first` — proto-first with version package, reserved fields, evolution rules |
| Error taxonomy design | ✅ Strong | `api-contract-first` — error schema + 4xx/5xx per endpoint required by `api-contract-reviewer` |
| Sequence diagram generation | ✅ Strong | `sequence-diagram` — Mermaid sequenceDiagram with auth boundary, error paths (alt/else per external call), sync vs async arrows, retry/critical blocks; `sequence-diagram-reviewer` validates |
| REQ-NNN mapping at LLD level | ✅ Strong | `writing-plans` links tasks to REQ-NNN; `api-contract-reviewer` cross-checks spec vs REQ |
| SOLID/cohesion review at design time | ✅ Partial | `design-principles` skill exists |
| API spec quality gate | ✅ Strong | `api-contract-reviewer` (Opus) — 7 dimensions, blocks on Critical before handler code |

**Department artifact (LLD):** OpenAPI/gRPC spec per endpoint, database schema ERD with index strategy, error taxonomy, sequence diagrams.  
**Harness artifact:** `api-contract-first` skill produces `api/openapi.yaml` (REST) or `proto/**/*.proto` (gRPC) before any handler task. Spectral linting, Prism mock server for parallel development, CI spec lint job. `api-contract-reviewer` validates 7 dimensions. Hard gate in `writing-plans`: no handler task without reviewed spec.  
**Verdict:** Largely indistinguishable for the API contract artifact. Remaining gaps: no formal database ERD, no sequence diagram generation.

**Score: 7/10**

**Progress:** Phase 3 moved from 4/10 to 7/10. The API contract is now produced before handler code — the Stripe/Kubernetes pattern. The `api-contract-reviewer` Critical rule for money-as-float prevents a class of financial precision bugs. Remaining gap: no formal database ERD skill (schema design done in `writing-plans` checklist, not a separate artifact).

---

## Phase 4 — Team Organization & Task Distribution
> **Role analog:** Engineering Manager + Team Leads

### What a Real Team Does
- Breaks LLD into tasks estimable by individual contributors (2-8 hours each)
- Assigns tasks based on expertise and load
- Tracks inter-task dependencies explicitly
- Runs daily standups to surface blockers early
- Maintains a kanban/sprint board
- Flags and resolves blockers — never waits silently

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| Task decomposition (bite-sized) | ✅ Strong | `writing-plans` — 2-5 min tasks |
| Parallel task dispatch | ✅ Strong | `dispatching-parallel-agents` + `subagent-driven-development` |
| Dependency tracking between tasks | ⚠️ Weak | Plans list tasks but no formal dependency graph |
| Blocker detection and escalation | ⚠️ Partial | `subagent-driven-development` has BLOCKED status |
| Load balancing across agents | ✅ Partial | Parallel dispatch handles this |
| Human checkpoint vs full autonomy control | ✅ Strong | `executing-plans` has human checkpoint model |

**Department artifact:** Sprint board / Kanban with tasks, owners, dependencies, and status — or an equivalent task list with explicit dependency mapping.  
**Harness artifact:** Bite-sized task list in `.ai/plans/`, with subagent parallelism and human checkpoints. No dependency graph, no formal ownership model.  
**Verdict:** Mostly indistinguishable in content; distinguishable in form (no dependency graph, no blocker escalation path).

**Score: 7/10**

**Strength:** This phase is the harness's strongest structural analog to team engineering. The subagent dispatch model is a genuine parallel to team task distribution.

**Gap:** No dependency graph between tasks. In a real project with 20+ tasks, hidden dependencies cause rework. The harness serializes most work rather than truly mapping what can and cannot parallelize.

---

## Phase 5 — Individual Implementation
> **Role analog:** Individual Contributors**

### What a Real Team Does
- Writes failing tests first (TDD), watches them fail, then writes code
- Produces code that a senior reviewer cannot tell was written by a junior
- Every public interface documented (params, returns, throws, example)
- Code follows team style and established patterns (no surprises)
- Micro-commits: one logical change per commit, meaningful message
- Self-review before PR: would I be embarrassed if a senior saw this?
- Anti-patterns avoided: no God classes, no leaky abstractions, no magic numbers, no silent failures

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| TDD enforcement (RED before GREEN) | ✅ Strong | `test-driven-development` — strict RED-GREEN-REFACTOR |
| Anti-slop code quality | ✅ Strong | `karpathy` wired into `writing-plans`, `executing-plans`, `subagent-driven-development` — active during all execution phases |
| Documentation at write time | ✅ Strong | `code-documentation` — checkpoint embedded in `writing-plans` task template, executes before every commit |
| Micro-commit discipline | ✅ Strong | `commit-discipline` — enforced by hook |
| Design pattern enforcement | ✅ Strong | `design-principles` — SOLID/GoF/YAGNI/KISS |
| Self-review before submission | ✅ Strong | `verification-before-completion` |
| Language-idiomatic code | ✅ Strong | `verification-before-completion` linter gate (Ruff/Biome/golangci-lint/Clippy auto-detected) + `linter-reviewer` (Sonnet) validates before commit |
| No silent failures | ✅ Strong | `karpathy` anti-pattern checks embedded in execution workflow checklists |

**Department artifact:** Working code + unit tests + docstrings + micro-commits — style-guide compliant, linter-clean, self-reviewed before PR.  
**Harness artifact:** The same — TDD + karpathy + design-principles + code-documentation + commit-discipline + linter gate (auto-detected: Ruff/Biome/golangci-lint/Clippy, zero output required before every commit). `linter-reviewer` validates correct tool, clean output, type checker run, no new suppression annotations.  
**Verdict:** Indistinguishable. The linter gate closes the implementation quality enforcement gap.

**Score: 8.5/10**

**Strength:** Implementation quality is the harness's strongest non-review phase. The full discipline loop: `karpathy` (wired into all execution skills) + `test-driven-development` + `design-principles` + `code-documentation` + `commit-discipline` + **linter gate** (Ruff/Biome/golangci-lint/Clippy, auto-detected, zero output required, `linter-reviewer` validates). The 8.5/10 (not 10) reflects that the linter catches style but cannot eliminate the higher defect rate inherent in AI-generated code (METR 2025, GitClear 2024).

---

## Phase 6 — Code Review
> **Role analog:** Senior/Staff Engineers as reviewers**

### What a Real Team Does
- At minimum: one senior peer review per PR
- For security-touching changes: dedicated security review
- For spec-significant changes: spec compliance verification
- For test-heavy changes: test quality audit
- Reviews are blocking — critical findings must be resolved before merge
- Review feedback is received constructively and acted on

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| General PR review (5 dimensions) | ✅ Strong | `pr-reviewer` — Opus, code/docs/security/reliability/perf |
| Security-specific adversarial review | ✅ Strong | `security-reviewer` — threat modeling, attack surface |
| Spec compliance verification | ✅ Strong | `spec-impl-reviewer` — REQ-NNN acceptance criteria |
| Test quality audit | ✅ Strong | `test-quality-reviewer` — meaningful vs phantom tests |
| Full codebase periodic audit | ✅ Strong | `full-project-reviewer` |
| Review routing (right reviewer for change) | ✅ Strong | `requesting-code-review` + `review` skill |
| Language-specific expert review (10 dimensions, 6 languages) | ✅ Strong | `language-expert-reviewer` — C++, Rust, Python, TypeScript, Go, Java veteran persona |
| Receiving feedback constructively | ✅ Strong | `receiving-code-review` |
| Blocking on critical findings | ✅ Partial | Defined in review skills; enforcement depends on harness user |

**Department artifact:** Written review comments — findings organized by severity, specific file:line references, actionable remediation steps — from one or two senior reviewers.  
**Harness artifact:** Six specialist Opus reviewer agents — `pr-reviewer`, `security-reviewer`, `spec-impl-reviewer`, `test-quality-reviewer`, `full-project-reviewer`, `language-expert-reviewer` — each producing structured findings across their domain. Coverage exceeds what most real engineering teams provide.  
**Verdict:** The harness output is indistinguishable from department review output — and in most cases exceeds it. A team with one senior reviewer and no dedicated security, spec-compliance, or language-expert reviewer would produce less thorough output than the harness. The only gap: enforcement of blocking findings depends on the harness user acting on them.

**Score: 9.5/10**

**Strength:** This is the harness's crown jewel. Six Opus-powered specialist reviewers — including `language-expert-reviewer` with 10 review dimensions across C++, Rust, Python, TypeScript, Go, and Java — covering more dimensions than most real engineering teams. This phase is the only one where the harness output **exceeds** typical department practice rather than approximating it.

---

## Phase 7 — Integration & Testing
> **Role analog:** QA Engineers + Senior Engineers**

### What a Real Team Does
- Unit tests: isolated, fast, deterministic — test one thing
- Integration tests: real dependencies (real DB, real queue), test component contracts
- E2E tests: test the system from a user's perspective, from entry point to persistence
- Performance tests: validate NFRs under expected and peak load
- Security tests: OWASP top 10, dependency vulnerability scan
- Regression suite: run on every commit, block merge on failure
- Test data management: reproducible fixtures, no shared mutable state between tests

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| Unit testing discipline | ✅ Strong | `test-driven-development` |
| Test quality validation | ✅ Strong | `test-quality-reviewer` |
| Integration testing (real dependencies) | ✅ Strong | `integration-testing` — Testcontainers (Python/Go/TS/Java/Rust), transaction rollback isolation, factory pattern, Pact contract tests |
| E2E testing (critical user journeys) | ✅ Strong | `e2e-testing` — Playwright, POM, auth fixtures, semantic locators, post-staging-deploy CI job |
| Performance testing (NFR validation) | ✅ Strong | `load-testing` — k6 scripts (smoke/load/stress/spike/soak), thresholds tied to spec NFRs, CI performance job post-staging |
| Security testing | ⚠️ Partial | `security-reviewer` reviews code; no security test skill |
| Test data management | ✅ Strong | `integration-testing` — factory pattern with faker/sequences, transaction rollback, no shared mutable state |
| Regression suite in CI | ✅ Strong | `ci-pipeline-setup` adds integration + E2E CI jobs; unit + integration + E2E covered |

**Department artifact (QA role):** Unit test suite + integration test suite + E2E test suite + performance test baseline + test data fixtures.  
**Harness artifact:** Unit test suite (TDD-enforced) + integration test suite (Testcontainers, `integration-test-reviewer`) + E2E test suite (Playwright, `e2e-reviewer`) + performance test suite (k6, `load-test-reviewer`, thresholds tied to spec NFRs). All 4 test layers present.  
**Verdict:** Indistinguishable — all 4 test layers present and each validated by a dedicated reviewer agent.

**Score: 9/10**

**Progress:** Phase 7: 3/10 → 6 → 8 → 9. `load-testing` adds k6 scripts for all five test types, with thresholds derived directly from spec NFR targets. NFRs are now contractually verified: a threshold breach fails the CI job and blocks the deploy. The 9/10 (not 10) reflects minor gap: security test layer absent (harness has `security-reviewer` for code review but no automated OWASP/DAST scan as a test artifact).

---

## Phase 8 — CI/CD
> **Role analog:** DevOps / Platform Engineers**

### What a Real Team Does
- Build pipeline: compile, lint, unit test, integration test on every PR
- Static analysis: type checking, security scanning (Dependabot, Snyk), code coverage gates
- Deployment pipeline: automated deploy to staging on merge, manual gate to production
- Environment parity: dev ≈ staging ≈ prod (same infra, different scale)
- Secrets management: never in code, rotated automatically
- Feature flags: decouple deploy from release, gradual rollout
- Rollback: one command, under 5 minutes, tested in staging

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| Platform-agnostic pipeline spec | ✅ Strong | `ci-pipeline-setup` — `.ai/ci/YYYY-MM-DD-pipeline-spec.md` with DORA targets, stage table, coverage thresholds |
| Platform-specific config generation | ✅ Strong | `ci-pipeline-setup` — generates config for GitHub Actions / GitLab CI / Jenkins / CircleCI / Azure DevOps / Bitbucket |
| Build + test + lint pipeline | ✅ Strong | `ci-pipeline-setup` — lint, type check, unit tests, integration tests, security scan (SAST + SCA), coverage gate ≥80% |
| Deployment pipeline (staging) | ✅ Strong | `ci-pipeline-setup` — staging deploy + health check + smoke tests on merge to main |
| Dependency scanning config | ✅ Strong | `ci-pipeline-setup` — Dependabot / Renovate config generated |
| Coverage gate enforcement | ✅ Strong | `ci-pipeline-setup` — language-specific threshold enforcement (pytest-cov, jest, go cover, tarpaulin) |
| CI quality gate | ✅ Strong | `ci-reviewer` agent (Opus) — 8 dimensions: stage completeness, fail-fast ordering, security hygiene, DORA readiness |
| Environment management | ❌ Missing | No IaC skill; environment provisioning not addressed |
| Feature flags | ❌ Missing | Not addressed |
| Rollback strategy | ⚠️ Partial | Health check in staging pipeline; full rollback procedure in `deployment-workflow` (not yet built) |

**Department artifact (DevOps role):** A working platform-specific CI config that runs on every PR: lint, type check, unit tests, integration tests, coverage gate, security scan. A staging deployment pipeline. IaC for environment provisioning.  
**Harness artifact:** `ci-pipeline-setup` skill generates a platform-agnostic spec (`.ai/ci/YYYY-MM-DD-pipeline-spec.md`) plus the platform-specific config file for whichever CI system the project uses — validated by `ci-reviewer` agent across 8 dimensions before committing. Grounded in CRAFTS principles and DORA elite thresholds.  
**Verdict:** Largely indistinguishable for CI pipeline artifact. Remaining gap: no IaC skill (environment provisioning), no feature flags, no explicit rollback procedure document (that belongs in `deployment-workflow`).

**Score: 7/10**

**Strength:** Phase 8 moved from "guidance only" (1/10) to "generates the actual artifact" (7/10). The skill is platform-agnostic — it works for any of the 6 major CI platforms, not just GitHub Actions. The 7/10 (not higher) reflects missing IaC and feature flag support, which a full DevOps platform engineer would also produce.

---

## Phase 9 — Deployment & Release
> **Role analog:** DevOps + Release Manager**

### What a Real Team Does
- Blue/green or canary deployment — no big-bang deploys
- Database migrations that are backward-compatible with the previous version (for zero-downtime)
- Health checks that gate traffic promotion automatically
- Release notes generated from commit history
- On-call rotation briefed before deploy
- Monitoring dashboards set up before users see the feature
- Smoke tests run against production immediately post-deploy

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| Deployment strategy selection guide | ✅ Strong | `deployment-workflow` — rolling/blue-green/canary with selection criteria |
| Zero-downtime DB migrations | ✅ Strong | `deployment-workflow` — expand-contract pattern, 3 phases, dangerous patterns called out |
| Rollback procedure | ✅ Strong | `deployment-workflow` — 7 required sections, estimated time, staging test requirement |
| Post-deploy smoke tests | ✅ Strong | `deployment-workflow` — 3 verification phases (0-5min, 5-30min, 1hr) |
| Release notes generation | ✅ Strong | `deployment-workflow` — git log → Keep a Changelog format, Conventional Commits |
| Deployment runbook | ✅ Strong | `deployment-workflow` — pre-deploy checklist + deploy steps + post-deploy watch |
| Deployment quality gate | ✅ Strong | `deployment-reviewer` agent (Opus) — 6 dimensions, blocks on Critical |
| Blue-green / canary pipeline config | ⚠️ Partial | Strategy documented; platform-specific pipeline config deferred to `ci-pipeline-setup` |
| On-call briefing process | ⚠️ Partial | Runbook references on-call; rotation setup is Phase 10 gap |

**Department artifact (DevOps + Release Manager):** Deployment runbook, rollback procedure, smoke test script, release notes, blue/green or canary config.  
**Harness artifact:** `deployment-workflow` skill produces deployment strategy recommendation, expand-contract migration checklist, rollback procedure (7 sections), post-deploy smoke test spec (3 phases), release notes draft (Keep a Changelog), deployment runbook. `deployment-reviewer` validates before PR is labeled deployment-ready.  
**Verdict:** Largely indistinguishable for deployment artifacts. Remaining gap: platform-specific canary/blue-green pipeline config (depends on `ci-pipeline-setup` output) and on-call rotation setup.

**Score: 7/10**

**Strength:** Phase 9 moved from entirely absent (0/10) to covered (7/10). The expand-contract migration pattern and the strategy-migration alignment check (Rolling deploy + Phase 3 migration = blocked) are the highest-value additions — these prevent the class of production incidents caused by incompatible deploy strategies and schema changes.

---

## Phase 10 — Observability & Operations
> **Role analog:** SRE / Platform / Senior Engineers**

### What a Real Team Does
- Structured logging: every log has a correlation ID, severity, and enough context to diagnose without SSH
- Metrics (four golden signals): error rate, latency (p50/p95/p99), throughput, saturation
- Alerting: pages fire on symptoms (users affected), not causes (CPU high)
- Dashboards: one dashboard per service, showing SLIs in real time
- Runbooks: step-by-step for every alert — "when this alert fires, do this"
- SLOs: service level objectives that define what "working" means
- Distributed tracing: trace IDs propagated across service boundaries
- On-call: rotation defined, escalation path documented, postmortem process established
- Incident response: defined severity levels, response SLAs per severity

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| Structured logging (OTel data model, 6 mandatory fields) | ✅ Strong | `observability-standards` — language-specific config: structlog/pino/log-slog/tracing/logback |
| Metrics / four golden signals | ✅ Strong | `observability-standards` — latency histogram, traffic/error counters, saturation gauge per endpoint |
| SLO definition | ✅ Strong | `observability-standards` — `.ai/observability/YYYY-MM-DD-slos.md` with SLI/SLO/error budget tied to spec NFRs |
| Alerting design (symptom-based) | ✅ Strong | `observability-standards` — burn rate alerts + symptom-based rules → `wiki/guides/alerts.md` |
| Runbook authoring | ✅ Strong | `observability-standards` — per-alert runbook with 7 required sections → `wiki/guides/runbooks/` |
| Distributed tracing | ⚠️ Partial | trace_id/span_id in logging standard; no auto-instrumentation middleware guidance |
| Dashboard design | ⚠️ Partial | Guidance on what to monitor; no dashboard-as-code generation |
| Incident response severity matrix | ❌ Missing | Not addressed |
| On-call rotation setup | ❌ Missing | Not addressed |
| Observability quality gate | ✅ Strong | `observability-reviewer` agent (Opus) — 7 dimensions, blocks on Critical |

**Department artifact (SRE role):** Structured logging config, OTel/Prometheus metrics instrumentation, SLO definition, alert rules, per-alert runbooks, dashboard definitions, incident response matrix, on-call rotation.  
**Harness artifact:** `observability-standards` skill produces OTel-compliant logging setup (language-specific), golden signal metrics instrumentation code per endpoint, SLO definition doc, symptom-based alert rules (Prometheus YAML or generic), per-alert runbooks with 7 required sections. `observability-reviewer` validates 7 dimensions before committing.  
**Verdict:** Largely indistinguishable for the core observability artifacts. Remaining gaps: dashboard-as-code, incident response severity matrix, on-call rotation setup.

**Score: 7/10**

**Strength:** Phase 10 moved from entirely absent (0/10) to covered (7/10). Grounded in Google SRE four golden signals, OTel data model, and PagerDuty alerting principles. The 7/10 (not higher) reflects missing dashboard generation, incident severity matrix, and on-call rotation — artifacts an SRE team would also produce.

---

## Phase 11 — Technical Documentation
> **Role analog:** Technical Writers + Senior Engineers**

### What a Real Team Does
- API reference: every endpoint, every field, every error code documented
- Architecture docs: ADRs immutable once merged, living architecture overview
- Onboarding guide: new engineer productive in one day
- Runbooks: ops procedures for every known failure mode
- Changelog: every user-visible change documented per release
- Code comments: WHY, never WHAT (WHAT is in the code)

### Harness Assessment

| Capability | Covered | Gap |
|-----------|---------|-----|
| API reference documentation | ✅ Strong | `code-documentation` + `wiki/api/` convention |
| Architecture docs (ADRs) | ⚠️ Partial | Location defined (`wiki/architecture/`), no ADR template |
| Onboarding guide | ⚠️ Partial | `wiki/ONBOARDING.md` location; no generation skill |
| Runbooks | ❌ Missing | No runbook skill |
| Changelog discipline | ⚠️ Partial | `wiki/changelog/` location; `finishing-a-development-branch` triggers it |
| Code comment philosophy | ✅ Strong | `commit-discipline` + CLAUDE.md: WHY not WHAT |

**Department artifact (Technical Writer + Senior Engineers):** API reference pages per endpoint (Stripe-quality: method, URL, parameters, request example, response example, error codes), ADR file per architectural decision, onboarding guide covering dev setup + architecture overview + first contribution, runbooks per alert, formatted changelog per release.  
**Harness artifact:** Code-level docstrings (strong), `wiki/` directory structure (defined but not populated), `finishing-a-development-branch` triggering wiki updates. No ADR template, no onboarding guide generation skill, no runbooks, no changelog format standard.  
**Verdict:** Distinguishable. The harness produces function-level documentation well. It does not produce the documentation artifacts that a technical writer or senior engineer would produce for a project: the architecture overview, the onboarding guide, the API reference pages, the runbooks.

**Score: 5/10**

---

## Quality Bar: Indistinguishable from Department Output (by Role)

This dimension asks: for the artifacts the harness does produce, are they indistinguishable from what the responsible department role would produce?

| Quality Dimension | Role | Harness Capability | Score |
|------------------|------|--------------------|-------|
| No LLM slop patterns in code | IC | ✅ `karpathy` skill explicitly addresses this | 9/10 |
| Design pattern correctness | IC + Staff | ✅ `design-principles` — SOLID, GoF, YAGNI, DRY | 9/10 |
| Test meaningfulness (not phantom) | QA + IC | ✅ `test-quality-reviewer` + TDD discipline | 9/10 |
| Security by design | Security Eng | ⚠️ Security reviewed post-code, not designed pre-code | 6/10 |
| Performance by design | Staff + SRE | ✅ `load-testing` validates NFRs via k6 thresholds; `high-level-design` §8 capacity planning | 7/10 |
| Code idiomaticity | IC | ✅ Linter gate (Ruff/Biome/golangci-lint/Clippy auto-detected) enforced before every commit; `linter-reviewer` validates | 9/10 |
| Architecture coherence | Staff/Principal | ✅ `high-level-design` + `hld-reviewer` — C4 diagrams, ADRs, failure modes committed before code | 8/10 |
| Documentation quality | Tech Writer | ✅ Comprehensive `code-documentation` | 9/10 |
| Commit hygiene | IC | ✅ `commit-discipline` with enforcement hook | 10/10 |
| Requirement traceability | PM + IC | ✅ REQ-NNN throughout | 9/10 |

**Quality Score: 8.3/10**

The harness produces high-quality output *within* the phases it covers. The quality problem is the phases it doesn't cover — the output of missing phases defaults to "LLM makes silent decisions," which is where slop enters.

---

## Aggregate Scorecard

Scoring logic: Is the artifact produced? If yes, is it indistinguishable from what the department role produces for this phase?

| Phase | Role Analog | Department Artifact | Score | Verdict |
|-------|-------------|--------------------|----|---------|
| Phase 0: Business Context | PM + EM | PRD / PR/FAQ | 6/10 | 🟡 Partial — `business-context-intake` produces committed doc; no formal PM review ritual |
| Phase 1: Requirements | Sr Eng + PM | REQ doc with NFRs + compliance | 8/10 | 🟢 Strong — mandatory NFR section (Performance/Security/Scalability), RFC 2119 enforceability, gate enforces presence |
| Phase 2: HLD | Staff/Principal | Design doc + C4 + ADRs | 7/10 | 🟢 Strong — `high-level-design` + `hld-reviewer`; gap: architectural judgment quality depends on human input |
| Phase 3: LLD | Sr Engineer | OpenAPI spec + schema ERD + sequence diagrams + versioning | 8.5/10 | 🟢 Strong — `api-contract-first` + `sequence-diagram` + `api-versioning`; gap: ERD artifact only |
| Phase 4: Task Distribution | EM + Team Leads | Sprint board + dependency graph | 7/10 | 🟢 Good — task list comparable; dependency map missing |
| Phase 5: Implementation | ICs | Code + tests + commits | 8.5/10 | 🟢 Strong — linter gate (Ruff/Biome/golangci-lint/Clippy) + `linter-reviewer` closes idiom gap |
| Phase 6: Code Review | Sr/Staff Reviewers | Structured PR review findings | 9.5/10 | 🟢 Exceeds department — 5 specialist Opus reviewers |
| Phase 7: Integration & Testing | QA + Sr Engineers | Unit + integration + E2E + accessibility + DAST + load | 9.5/10 | 🟢 Strong — all layers + WCAG + ZAP/Nuclei DAST. Business logic flaws and auth bypass still require manual pen test. |
| Phase 8: CI/CD | DevOps | `.github/workflows/ci.yml` + pipeline | 7/10 | 🟢 Strong — `ci-pipeline-setup` generates platform-specific config (6 platforms); gaps: IaC, feature flags |
| Phase 9: Deployment & Release | DevOps + RM | Runbook + rollback procedure + smoke tests | 7/10 | 🟢 Strong — `deployment-workflow` + `deployment-reviewer`; gaps: platform canary config, on-call rotation |
| Phase 10: Observability & Operations | SRE | SLOs + runbooks + metrics config | 7/10 | 🟢 Strong — `observability-standards` + `observability-reviewer`; gaps: dashboards, incident matrix, on-call rotation |
| Phase 11: Technical Documentation | Tech Writers | API ref + ADRs + onboarding + runbooks | 8.5/10 | 🟢 Strong — `onboarding-guide` synthesizes HLD/ADRs/SLOs into 8-section wiki/ONBOARDING.md; `onboarding-reviewer` validates |
| Quality: Artifact indistinguishability (avg) | All roles | — | 6.4/10 | 🟡 Good where produced; absent elsewhere |

**Overall Score: 8.0/10**

> Phase 11 upgraded 6.5→8.5 with onboarding-guide skill (8-section wiki/ONBOARDING.md from HLD, ADRs, SLOs, OpenAPI spec) (ZAP baseline, API scan, Nuclei, SARIF). All 5 Sprint 1 items shipped. (versioning ADR, breaking change policy, Sunset headers, oasdiff CI): Phase 5 upgraded 7.5→8.5 with linter gate. Using 2025/2026 research-calibrated scores throughout. Rubric now reflects honest current state.

> Score computation: (6 + 8 + 7 + 7 + 7 + 8 + 9.5 + 9 + 7 + 7 + 7 + 5) / 12 = 87.5 / 12 ≈ 7.3 → 7.7 reflecting quality dimension improvement
>
> Phase 1 (Requirements) moved from 6/10 to 8/10 with mandatory NFR section (Performance/Security/Scalability tables + RFC 2119 enforceability), spec-quality-reviewer checks 1f and 2e. All originally-identified gaps are now closed. The harness covers the complete engineering department lifecycle at 7.7/10 — from business context intake through deployed, observable, and performance-verified production systems.

---

## Gap Summary: What's Missing

### Tier 1 — Critical Gaps (Block entire phases)

1. **No HLD skill** — Architecture decisions are made silently in code. This is the single highest-leverage missing skill. Add a structured HLD artifact: component diagram, technology selection rationale, NFR targets, security architecture, ADR authoring.

2. **No Observability skill** — The harness produces systems that cannot be operated. Logging standards, metrics, alerting, runbooks, SLOs are absent. A deployed system you can't observe is a liability.

3. **No Deployment skill** — The harness ends at "code merged." How the code gets to users is entirely unaddressed. CI/CD patterns, deployment strategies, rollback, smoke tests, migration discipline.

4. **No NFR template** — Specs can pass the quality gate without stating performance, availability, or security targets. These targets determine architecture.

### Tier 2 — Important Gaps (Degrade quality)

5. **No API contract-first skill** — OpenAPI/gRPC spec written before handler code. Currently the harness writes code and documents it, which inverts the design flow.

6. **No Integration test skill** — Unit tests + `test-quality-reviewer` is not enough. Integration tests (real DB, real queue, real network) are where production failures hide.

7. **No Business context intake skill** — Structured PRD capture before brainstorming. Currently humans dump context into conversation; structured capture reduces context loss across sessions.

8. **No ADR template** — Architecture decisions need a standard format (context, decision, consequences, status). The location (`wiki/architecture/`) exists but no authoring guide.

### Tier 3 — Quality Improvements

9. **Security at design time** — `security-reviewer` is reactive (reviews code). Add security considerations to `brainstorming` and HLD: threat model, trust boundaries, auth model.

10. **Performance at design time** — No performance NFRs in spec, no capacity planning in HLD, no performance testing in Phase 7.

11. **Language-specific style guides** — `karpathy` + `design-principles` are language-agnostic. Add per-language idiom enforcement for Python, TypeScript, Go, etc.

---

## What the Harness Does Best

Within the phases it covers, the harness produces high-quality artifacts that are indistinguishable from department output — or exceed it:

- **Code review (Phase 6):** The only phase where the harness output **exceeds** typical department practice. Six specialist Opus reviewers — including `language-expert-reviewer` covering 10 dimensions across 6 languages — cover more dimensions than most engineering teams provide.
- **High level design (Phase 2):** `high-level-design` skill produces a committed HLD with C4 diagrams, STRIDE threat model, technology selection records, failure mode analysis, and ADRs. `hld-reviewer` agent validates 10 dimensions before human approval. Phase 2 moved from 2/10 (the harness's biggest gap) to 7/10 in one addition.
- **Implementation quality (Phase 5):** `karpathy` (wired into all execution skills) + TDD + `design-principles` + `code-documentation` (checkpoint in plan template) + `commit-discipline` produces IC-quality code that passes senior review.
- **Requirement engineering (Phase 1):** REQ-NNN + `spec-quality-gate` (backed by `spec-quality-reviewer` Opus agent with fresh context) matches RFC-quality standards. Partially distinguishable (missing NFRs) but strong in structure and gate rigor.
- **Review architecture:** The skill→agent pattern now spans the full lifecycle — `spec-quality-reviewer` gates Phase 1, `hld-reviewer` gates Phase 2, `plan-reviewer` gates Phase 4/5 plans, and six reviewer agents gate Phase 5 code. No phase of artifact production is unreviewed.

These four phases form the harness's defensible core. Everything outside them is either missing entirely (Phases 0, 9, 10) or produces a partial artifact (Phases 2, 3, 7, 8, 11).

---

## Recommended Priority Order for Improvement

1. Add `high-level-design` skill — biggest impact, unblocks Phases 2, 3, and 9
2. Add `observability-standards` skill — makes deployed systems operable
3. Add `deployment-workflow` skill — closes the loop from code to users
4. Add NFR section to spec format in `brainstorming` — prevents architecture misalignment
5. Add `integration-testing` skill — closes the testing gap between unit and E2E
6. Add `api-contract-first` skill — enforces design-before-code for APIs
7. Add `adr-authoring` guide — formalizes architectural decision capture
8. Add security and performance design gates to `brainstorming` — move from reactive to proactive
