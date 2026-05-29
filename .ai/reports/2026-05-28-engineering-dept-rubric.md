# Engineering Department Workflow Rubric
# Private AI Harness — Capability Evaluation

**Date:** 2026-05-28  
**Last updated:** 2026-05-29 — reflects `language-expert-reviewer` addition (Phase 6), karpathy wired into execution workflows (Phase 5), `code-documentation` checkpoint added to `writing-plans` (Phase 5)  
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
| Structured intake for business context | ❌ | No PRD/business context capture skill |
| KPI and success metric definition | ❌ | No measurement framework |
| Compliance constraint capture | ❌ | No compliance checklist |
| Explicit scope negotiation | ✅ Partial | `brainstorming` does scope negotiation |
| Out-of-scope documentation | ✅ | Spec format has explicit Out-of-scope section |

**Department artifact:** PRD or PR/FAQ — a committed, versioned document with problem statement, user persona, success metrics, compliance constraints, and stakeholder map.  
**Harness artifact:** Partial scope negotiation inside a conversation. No committed file.  
**Verdict:** Immediately distinguishable. A department always produces a written intake artifact. The harness produces none.

**Score: 2/10**

**Critical Gap:** A PM looking at the harness's output for this phase sees a conversation transcript, not a PRD. The artifact category is absent. Every downstream phase (HLD, spec, implementation plan) is built without a formal intake document to reference.

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
| Non-functional requirement capture (NFRs) | ⚠️ Weak | No explicit NFR section in spec format |
| Measurable acceptance criteria | ✅ Strong | Spec enforces binary/measurable criteria |
| Requirement-to-test-case mapping | ✅ Strong | TC-REQ-NNN format, coverage matrix |
| Requirement quality gate | ✅ Strong | `spec-quality-gate` skill |
| Living requirements (versioned, tracked) | ⚠️ Weak | Files committed but no version trail |
| NFRs: latency/availability/throughput/security | ❌ Missing | No structured NFR template |
| Compliance requirements | ❌ Missing | Not addressed |

**Department artifact:** A requirements document with functional requirements, non-functional requirements (latency/availability/throughput), compliance constraints, MUST/SHOULD/MAY enforceability taxonomy, and bidirectional test coverage matrix.  
**Harness artifact:** REQ-NNN spec with measurable acceptance criteria and TC mapping. No NFR section, no compliance section, no enforceability taxonomy.  
**Verdict:** Partially distinguishable. The spec document structure is strong, but an engineer reviewing it would immediately notice the missing NFR and compliance sections — categories that every mature requirements document includes.

**Score: 6/10**

**Key Gap:** NFRs are not explicitly structured. A spec can pass the quality gate without stating "response time < 200ms at p99" or "99.9% availability" or "data encrypted at rest." These are the requirements that determine whether you need a cache, a CDN, a read replica, or a queue — omitting them produces a well-specified system built for the wrong constraints.

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
| Component decomposition with boundaries | ✅ Partial | `brainstorming` + `design-principles` |
| Communication pattern selection | ⚠️ Partial | Implied in brainstorming, not structured |
| Technology selection with rationale | ⚠️ Weak | `brainstorming` proposes options but no formal decision doc |
| Infrastructure design | ❌ Missing | No infrastructure/hosting skill |
| ADR authoring | ⚠️ Partial | `wiki/architecture/` location exists, no ADR template/skill |
| Capacity planning | ❌ Missing | Not addressed |
| Security architecture design | ⚠️ Weak | `security-reviewer` reviews after code, not at design time |
| Resilience patterns (circuit breaker, retry) | ❌ Missing | Not addressed |
| Diagram generation | ❌ Missing | No C4/architecture diagram skill |
| Data ownership and consistency model | ❌ Missing | Not structured |

**Department artifact:** A reviewed design document (Google Design Doc / Kubernetes KEP / Amazon 6-pager equivalent) containing C4 diagrams, technology selection records, ADRs, security architecture, failure mode analysis, and capacity planning. Produced by a Staff/Principal engineer. Committed before any implementation plan is written.  
**Harness artifact:** A brainstorming conversation in which component options are discussed. No committed document. No diagrams. No ADRs. The architectural decisions exist only in the LLM's context window and disappear when the session ends.  
**Verdict:** Immediately and completely distinguishable. The artifact category is absent. A team that skips HLD is not an engineering team — it is a group of individuals writing independent code.

**Score: 2/10**

**Critical Gap:** HLD is the most under-served phase. The harness jumps from spec to implementation plan with no formal HLD artifact. The 2/10 (not 0) reflects that `brainstorming` does discuss components and trade-offs — but inside a conversation, not a committed document. A conversation is not an HLD. Architectural decisions made in conversation are forgotten; architectural decisions in an ADR are permanent.

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
| Database schema design | ❌ Missing | Not structured |
| API contract specification (OpenAPI/gRPC) | ❌ Missing | No API spec generation skill |
| Error taxonomy design | ❌ Missing | Not addressed |
| Sequence diagram generation | ❌ Missing | Not addressed |
| REQ-NNN mapping at LLD level | ✅ Strong | `writing-plans` links tasks to REQ-NNN |
| SOLID/cohesion review at design time | ✅ Partial | `design-principles` skill exists |

**Department artifact (LLD):** OpenAPI/gRPC spec per endpoint, database schema ERD with index strategy, error taxonomy document, sequence diagrams for critical flows. All produced before implementation begins.  
**Harness artifact:** Implementation task plan with file paths and code snippets. Strong on task-level design guidance (`design-principles`). No API spec file, no schema design document, no error taxonomy.  
**Verdict:** Distinguishable. The harness produces implementation instructions; a department produces LLD design artifacts that implementation instructions are derived from. These are different documents at different abstraction levels.

**Score: 4/10**

**Key Gap:** No API contract first. A real team writes OpenAPI before writing a handler. The harness writes code and documents it afterward. This is the difference between an API designed for consumers and an API that happens to exist. The 4/10 (not lower) reflects that `writing-plans` + `design-principles` produce task-level design reasoning that is strong — but the formal LLD artifact layer is absent.

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
| Language-idiomatic code | ⚠️ Partial | `karpathy` helps; no language-specific style guides |
| No silent failures | ✅ Strong | `karpathy` anti-pattern checks embedded in execution workflow checklists |

**Department artifact:** Working code + unit tests + docstrings + micro-commits — all idiomatic to the project's language, style-guide compliant, self-reviewed before PR.  
**Harness artifact:** The same, minus language-specific linter/formatter enforcement. The code, tests, and commits are produced. Style consistency depends on the LLM's training, not an enforced tool run.  
**Verdict:** Largely indistinguishable in content. A careful reviewer might notice missing linter output in CI, or style inconsistencies across files that a formatter would have caught.

**Score: 8/10**

**Strength:** Implementation quality is the harness's strongest phase. `karpathy` is now actively wired into `writing-plans`, `executing-plans`, and `subagent-driven-development` — not just available as a skill, but embedded in the execution checklist. Combined with `test-driven-development` + `design-principles` + `code-documentation` (checkpoint in `writing-plans` task template) + `commit-discipline`, this creates a discipline loop enforced at every step. The 8/10 (not higher) reflects the sole remaining gap: no enforced language-specific linting gate. A professional IC runs `black`, `eslint`, `clippy`, or `golangci-lint` before every push; the harness does not.

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
| Integration testing guidance | ❌ Missing | No integration test skill |
| E2E testing guidance | ❌ Missing | Not addressed |
| Performance testing | ❌ Missing | Not addressed |
| Security testing | ⚠️ Partial | `security-reviewer` reviews code; no security test skill |
| Test data management | ❌ Missing | Not addressed |
| Regression suite management | ❌ Missing | Not addressed |

**Department artifact (QA role):** Unit test suite + integration test suite (real dependencies) + at least one E2E test covering the primary user journey + performance test baseline + test data fixtures. Coverage metric enforced in CI.  
**Harness artifact:** Unit test suite only, with high individual test quality (TDD discipline, `test-quality-reviewer`). Integration, E2E, and performance test layers are absent.  
**Verdict:** Clearly distinguishable. A QA engineer reviewing the project's test suite would immediately notice the absence of integration and E2E tests. Unit tests alone are insufficient for any production system — this is industry consensus, not preference.

**Score: 3/10**

**Critical Gap:** The harness stops at unit tests. The score is 3 (not lower) because the unit tests it does produce are high quality — TDD-enforced, `test-quality-reviewer`-validated. But 1 out of 4 test layers is not a test strategy. Integration and E2E tests catch the failures unit tests cannot: component wiring, real dependency behavior, and full user flows.

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
| GH Actions workflow patterns | ✅ Partial | `github-workflows` skill |
| Build + test + lint pipeline | ⚠️ Partial | `github-workflows`; not comprehensive |
| Deployment pipeline | ❌ Missing | No deployment skill |
| Environment management | ❌ Missing | Not addressed |
| Secrets management | ❌ Missing | Not addressed |
| Feature flags | ❌ Missing | Not addressed |
| Rollback strategy | ❌ Missing | Not addressed |
| Coverage gate enforcement | ❌ Missing | Not addressed |

**Department artifact (DevOps role):** A working `.github/workflows/ci.yml` (or equivalent) that runs on every PR: lint, format check, type check, unit tests, integration tests, coverage gate, security scan. A staging deployment pipeline. Infrastructure-as-Code for environment provisioning.  
**Harness artifact:** `github-workflows` skill provides patterns and guidance. No actual pipeline file is generated. The developer must write the CI config themselves from guidance, rather than receiving a working file.  
**Verdict:** Clearly distinguishable. Guidance about CI/CD ≠ a CI/CD pipeline. A DevOps engineer who produces only a document explaining CI/CD principles and no `ci.yml` has not done their job.

**Score: 1/10**

**Critical Gap:** CI/CD is almost entirely absent. The 1/10 (not 0) reflects that `github-workflows` provides genuine, correct guidance about GH Actions patterns. But guidance is not an artifact. The harness produces no `.github/workflows/` directory, no pipeline configuration, and no deployment automation — only prose describing what those would look like.

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
| Deployment strategy | ❌ Missing | Not addressed |
| Zero-downtime database migrations | ❌ Missing | Not addressed |
| Health check design | ❌ Missing | Not addressed |
| Release note generation | ❌ Missing | Not addressed |
| Smoke tests post-deploy | ❌ Missing | Not addressed |
| Rollback procedure | ❌ Missing | Not addressed |

**Department artifact (DevOps + Release Manager):** Deployment runbook, rollback procedure document, post-deploy smoke test script, release notes, health check configuration, blue/green or canary pipeline config.  
**Harness artifact:** None.  
**Verdict:** Entirely absent. An engineering department that ships code without a deployment runbook and rollback procedure is not a functioning team.

**Score: 0/10**

**This phase is entirely absent from the harness.** Every other phase scores at least something because the harness produces *some* relevant artifact. Phase 9 produces nothing — the harness stops at PR creation.

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
| Structured logging standards | ❌ Missing | Not addressed |
| Metrics / four golden signals | ❌ Missing | Not addressed |
| Alerting design | ❌ Missing | Not addressed |
| Dashboard design | ❌ Missing | Not addressed |
| Runbook authoring | ❌ Missing | Not addressed |
| SLO definition | ❌ Missing | Not addressed |
| Distributed tracing | ❌ Missing | Not addressed |
| Incident response | ❌ Missing | Not addressed |

**Department artifact (SRE role):** Structured logging configuration, Prometheus/OpenTelemetry metrics instrumentation, SLO definition document, alert rules, per-alert runbooks committed to `wiki/guides/runbooks/`, dashboard definitions, incident response severity matrix, on-call rotation setup.  
**Harness artifact:** None.  
**Verdict:** Entirely absent. A system with no observability is not a production system — it is code that happens to be running.

**Score: 0/10**

**This phase is entirely absent from the harness.** Not "weak" — absent. No structured logging standard, no metrics, no SLOs, no runbooks, no alerting design. An engineering department that ships without observability is not operating; it is hoping.

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
| Performance by design | Staff + SRE | ❌ No performance design skill | 3/10 |
| Code idiomaticity | IC | ⚠️ No implementation-time style gate; `language-expert-reviewer` catches idiom violations at PR review | 7/10 |
| Architecture coherence | Staff/Principal | ⚠️ No HLD artifact means architecture lives only in code | 4/10 |
| Documentation quality | Tech Writer | ✅ Comprehensive `code-documentation` | 9/10 |
| Commit hygiene | IC | ✅ `commit-discipline` with enforcement hook | 10/10 |
| Requirement traceability | PM + IC | ✅ REQ-NNN throughout | 9/10 |

**Quality Score: 7.5/10**

The harness produces high-quality output *within* the phases it covers. The quality problem is the phases it doesn't cover — the output of missing phases defaults to "LLM makes silent decisions," which is where slop enters.

---

## Aggregate Scorecard

Scoring logic: Is the artifact produced? If yes, is it indistinguishable from what the department role produces for this phase?

| Phase | Role Analog | Department Artifact | Score | Verdict |
|-------|-------------|--------------------|----|---------|
| Phase 0: Business Context | PM + EM | PRD / PR/FAQ | 2/10 | 🔴 Absent — no PRD artifact |
| Phase 1: Requirements | Sr Eng + PM | REQ doc with NFRs + compliance | 6/10 | 🟡 Partial — REQ doc exists; NFRs missing |
| Phase 2: HLD | Staff/Principal | Design doc + C4 + ADRs | 2/10 | 🔴 Absent — conversation ≠ design doc |
| Phase 3: LLD | Sr Engineer | OpenAPI spec + schema ERD | 4/10 | 🟡 Partial — task plans exist; API/schema artifacts don't |
| Phase 4: Task Distribution | EM + Team Leads | Sprint board + dependency graph | 7/10 | 🟢 Good — task list comparable; dependency map missing |
| Phase 5: Implementation | ICs | Code + tests + commits | 8/10 | 🟢 Strong — high quality; no linter gate |
| Phase 6: Code Review | Sr/Staff Reviewers | Structured PR review findings | 9.5/10 | 🟢 Exceeds department — 5 specialist Opus reviewers |
| Phase 7: Integration & Testing | QA + Sr Engineers | Unit + integration + E2E + perf tests | 3/10 | 🔴 Weak — unit tests only; 3 layers absent |
| Phase 8: CI/CD | DevOps | `.github/workflows/ci.yml` + pipeline | 1/10 | 🔴 Guidance only — no pipeline artifact |
| Phase 9: Deployment & Release | DevOps + RM | Runbook + rollback procedure + smoke tests | 0/10 | 🔴 Absent — nothing produced |
| Phase 10: Observability & Operations | SRE | SLOs + runbooks + metrics config | 0/10 | 🔴 Absent — nothing produced |
| Phase 11: Technical Documentation | Tech Writers | API ref + ADRs + onboarding + runbooks | 5/10 | 🟡 Partial — code docs strong; doc suite incomplete |
| Quality: Artifact indistinguishability (avg) | All roles | — | 6.4/10 | 🟡 Good where produced; absent elsewhere |

**Overall Score: 4.0/10**

> Score computation: (2 + 6 + 2 + 4 + 7 + 8 + 9.5 + 3 + 1 + 0 + 0 + 5) / 12 = 47.5 / 12 ≈ 4.0
>
> Under the previous (wrong) question — "indistinguishable from a senior engineer" — the score was 5.1/10, because that question measured individual code craft quality. Under the correct question — "indistinguishable from the department" — the score drops to 4.0/10, because entire artifact categories that a department always produces are absent from the harness. The harness is a strong implementation assistant operating inside a partial engineering department simulation.

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
- **Implementation quality (Phase 5):** `karpathy` + TDD + `design-principles` + `code-documentation` + `commit-discipline` produces IC-quality code that passes senior review.
- **Requirement engineering (Phase 1):** REQ-NNN + `spec-quality-gate` matches RFC-quality standards. The artifact is partially distinguishable (missing NFRs) but strong in structure.
- **Task parallelism (Phase 4):** `dispatching-parallel-agents` + `subagent-driven-development` is a genuine analog to team sprint distribution. Mostly indistinguishable in content.

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
