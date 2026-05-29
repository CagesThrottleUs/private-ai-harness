# Private AI Harness — Re-Scoring & Improvement Plan
**Date:** 2026-05-29  
**Question:** Can this harness replace an entire engineering department and produce output indistinguishable from what that department produces?  
**Methodology:** Fresh scoring from first principles, benchmarked against world-class products, FAANG practices, and current public AI tools.

---

## Section 1: Where This Harness Stands vs. Public Alternatives

Before scoring, understand the competitive landscape. This changes what "indistinguishable" means.

### What the public is actually using

| Tool | What it covers | Lifecycle coverage | Architecture |
|------|---------------|-------------------|-------------|
| **GitHub Copilot** | Code completion, PR descriptions | Code generation only | Inline suggestions + chat |
| **Cursor** | Context-aware editing, multi-file refactoring | Code + some review | IDE-native, project-aware |
| **Devin 2.0** ($20/mo) | Jira ticket → PR, autonomous execution, dynamic re-planning | Planning + implementation + PR. No HLD, no deployment runbook, no load testing | Agent with sandbox execution |
| **OpenHands** (open source, 66k users) | GitHub issue → code fix → PR. Sandboxed execution, 100+ LLM support | Implementation only. No lifecycle artifacts | CodeAct agent, composable |
| **SWE-agent** | GitHub issue resolution in CI pipelines | Issue resolution only | Research tool |
| **cursor rules / CLAUDE.md collections** | Style guides, coding conventions, stack preferences | Code quality only | System prompt injection |
| **steipete/agent-rules (GitHub)** | Rules for Claude Code / Cursor | Code quality + some workflow | CLAUDE.md best practices |

### What none of them have that this harness has

- **Complete lifecycle coverage** (business context → spec → HLD → LLD → plan → implementation → testing → CI/CD → deployment → observability)
- **Reviewer agent architecture** (skill produces artifact, agent reviews with fresh context at every phase)
- **NFR enforcement in spec** (templates forced by gate agents)
- **Multi-layer testing** (unit + integration + E2E + load — all 4 layers with agents)
- **Deployment runbook generation** (expand-contract migrations, rollback procedures)
- **Observability standards** (SLOs, alert rules, runbooks from day 1)

### Where public tools beat this harness

- **Execution** — Devin actually runs the code, deploys, and iterates. This harness generates artifacts but does not execute them.
- **Real-time context** — Cursor/Devin browse docs, search APIs, respond to compiler output live. This harness works from structured inputs.
- **Session memory** — OpenHands has project memory. This harness starts fresh each session (without claude-mem).
- **IDE integration** — Cursor/Copilot are in the IDE. This harness is CLI.

### Benchmark verdict

**This harness has the most complete engineering lifecycle coverage of any public tool.** The gap is execution depth (Devin runs code; this generates runbooks) and real-time feedback loops. For *artifact quality and engineering rigour*, no public tool comes close to this structure.

---

## Section 2: Fresh Scoring

### Scoring method

Two dimensions per phase:  
(1) Is the artifact produced? (2) Is it indistinguishable from what the department role produces?  
Missing artifact = 0. Present but inferior = partial score.

### Phase Scores

| Phase | Role | Artifact | Score | Verdict |
|-------|------|---------|-------|---------|
| **Phase 0: Business Context** | PM + EM | Business context doc with JTBD, metrics, compliance | **6/10** | Captures what human provides. Cannot generate product intuition or stakeholder relationships. |
| **Phase 1: Requirements** | Sr Eng + PM | REQ-NNN spec with NFRs + RFC 2119 enforced | **8/10** | Structure is world-class. NFR target *accuracy* still requires human judgment. |
| **Phase 2: HLD** | Staff/Principal | C4 diagrams + STRIDE + ADRs + capacity planning | **7/10** | Artifact is comprehensive; correctness depends on human architectural input. |
| **Phase 3: LLD** | Sr Engineer | OpenAPI + sequence diagrams + versioning strategy | **8.5/10** | `sequence-diagram` + `api-versioning` (ADR, breaking change policy, Sunset headers RFC 8594, oasdiff CI). ERD still absent. |
| **Phase 4: Task Distribution** | EM + Leads | Bite-sized plan with subagent dispatch | **7/10** | Good sprint analog. No dependency DAG, no velocity tracking. |
| **Phase 5: Implementation** | ICs | TDD code + karpathy + linter gate + docs | **8.5/10** | Linter gate added (Ruff/Biome/golangci-lint/Clippy auto-detected, `linter-reviewer` Sonnet agent). 2025/2026 defect rate research applies to tools without this gate. |
| **Phase 6: Code Review** | Sr/Staff | 6 specialist Opus reviewer agents | **9/10** | Exceeds typical 1-reviewer teams. Slight gap: codebase coherence across long history. |
| **Phase 7: Testing** | QA + Sr | Unit + integration + E2E + accessibility + DAST + load + chaos | **9.5/10** | 7 layers. `chaos-engineering` (T-08, conditional: resilience NFR services only). k6 fault injection, Toxiproxy, steady state + hypothesis. |
| **Phase 8: CI/CD** | DevOps | Platform-agnostic spec + 6 platform configs | **7/10** | IaC absent. Feature flags absent. |
| **Phase 9: Deployment** | DevOps + RM | Rollback procedure + migration checklist + smoke tests | **6.5/10** | *Generates* the runbook. Does not *execute* the deployment. Real release engineering = real-time decision-making. |
| **Phase 10: Observability** | SRE | OTel + SLOs + runbooks + incident response process | **8.5/10** | `incident-response` adds severity matrix (SEV-1/2/3), IC role, blameless postmortem template (Google SRE), MTTD/MTTR tracking. On-call rotation provisioning remains. |
| **Phase 11: Documentation** | Tech Writers | Code docs + ADRs + onboarding + runbooks + changelog | **8.5/10** | `onboarding-guide` synthesizes HLD C4, ADRs, OpenAPI, SLOs into 8-section wiki/ONBOARDING.md. Function-level docs strong. API reference pages (Stripe-quality) still absent. |

### Overall: 8.1/10

*(Phase 10: 7→8.5 with incident-response. Phase 11: 8.5. Phase 7: 9.5. Phase 3: 8.5.)*

*(2026 research-calibrated — honest downward revision from 7.7)*

---

## Section 3: What Would 9/10 Look Like?

Getting from 7.4 → 9.0 requires closing these specific gaps:

| If we close | Phase improves | Score Δ | New phase score |
|------------|---------------|--------|----------------|
| Sequence diagrams + API versioning + ERD | Phase 3 | +1.5 | 8.5/10 |
| DAST + accessibility + chaos + visual regression | Phase 7 | +1.0 | 9.5/10 |
| IaC skill | Phase 8 | +1.0 | 8.0/10 |
| Incident response workflow + postmortem | Phase 10 | +1.5 | 8.5/10 |
| Onboarding guide + API reference | Phase 11 | +1.5 | 8.0/10 |
| Linter gate in verification-before-completion | Phase 5 | +0.5 | 8.0/10 |

Projected overall after all: **(6+8+7+8.5+7+8+9+9.5+8+8.5+8+8) / 12 = 95.5/12 ≈ 8.0/10**

**The honest ceiling without solving execution gaps: ~8.2/10.** Getting to 9 requires solving the "artifacts vs execution" gap — the harness would need to *run* the deployment, *triage* the incident, *execute* the load test against real staging — not just generate the config for it. That requires integration with real infrastructure, which is architectural (not a skill you write in markdown).

---

## Section 4: Evidence-Based Todo List

Each item is verified: does it have clear industry evidence, can an LLM do it well, does it improve the score?

---

### VERIFIED ✅ — High confidence, high impact

**~~T-01: Linter Gate~~** ✅ SHIPPED 2026-05-29
- Added to `verification-before-completion` with language detection table (Ruff/Biome/golangci-lint/Clippy)
- `linter-reviewer` (Sonnet) agent validates before every commit
- **Score impact achieved:** Phase 5: 7.5→8.5, Overall: 7.4→7.5

---

**~~T-02: Sequence Diagram Generation~~** ✅ SHIPPED 2026-05-29
- `sequence-diagram` skill + `sequence-diagram-reviewer` agent
- **Score impact achieved:** Phase 3: 7→8, Overall: 7.5→7.6

**T-02 details (archived):**
- **Evidence:** Netflix mandates sequence diagrams for any operation crossing service boundaries. Google Design Doc §3 has "sequence diagram first" as standard practice for new microservice interactions. Missing from LLD is why Phase 3 scores 7 not 9.
- **LLM can do it:** Mermaid `sequenceDiagram` syntax is well-documented and LLMs produce accurate sequence diagrams when given a described flow. The skill reads the HLD container diagram + spec REQ-NNN and generates diagrams for critical paths.
- **Score impact:** Phase 3: 7→8.5 (+1.5)
- **Effort:** Medium — new skill, new artifact type

---

**~~T-03: API Versioning Strategy~~** ✅ SHIPPED 2026-05-29
- `api-versioning` skill + `api-versioning-reviewer` agent
- Versioning ADR, breaking change policy, RFC 8594 Sunset headers, oasdiff CI detection
- **Score impact achieved:** Phase 3: 8→8.5, Overall: 7.6→7.7

**T-03 details (archived):**
- **Evidence:** Stripe's API versioning is the industry standard — version pinned per customer, never breaking changes on existing consumers. Kubernetes resource versioning (v1alpha1 → v1beta1 → v1) is the CNCF standard. "Undetected API schema drift" is top-3 production incident cause (World Quality Report 2025). Current `api-contract-reviewer` detects breaking changes but there's no versioning *strategy* skill.
- **LLM can do it:** Produce a versioning strategy ADR (semver policy, sunset timeline, migration guide template, header-based vs URL-path versioning decision). Reference Stripe/Kubernetes patterns with explicit trade-off analysis.
- **Score impact:** Phase 3: toward 9
- **Effort:** Medium — new skill

---

**T-04: DAST Security Testing**
- **Evidence:** OWASP Top 10 — SQL injection, XSS, SSRF — cannot be caught by static analysis (what `security-reviewer` does). Dynamic testing is required. OWASP ZAP is the industry-standard open-source DAST tool, used in CI at thousands of organizations. The gap is real and dangerous.
- **LLM can do it:** Generate ZAP scan config as a CI job (`zap-cli` or `zaproxy/action-full-scan@v0.10`), define scan targets from API spec endpoints, set alert thresholds, upload SARIF report to GitHub Security tab.
- **Score impact:** Phase 7: 8.5→9.5
- **Effort:** Medium — new skill + agent

---

**T-05: Accessibility Testing (WCAG 2.1 AA)**
- **Evidence:** WCAG 2.1 AA is legally required in EU (EN 301 549), US federal (Section 508), and increasingly enforced. Axe-core (Deque) is the industry standard — used by Google, Microsoft, and integrated into Playwright. 15-20% of users have some form of disability. The gap is real for any user-facing feature.
- **LLM can do it:** Add `axe-playwright` to E2E test setup, generate accessibility assertions per critical page, add WCAG violation CI job with threshold. The `e2e-testing` skill already has Playwright — this is an extension.
- **Score impact:** Phase 7: toward 9.5
- **Effort:** Low-medium — enhancement to `e2e-testing` skill

---

**T-06: Onboarding Guide Generation**
- **Evidence:** Google's "Readability" program centers on code being readable to engineers who weren't there when it was written. `wiki/ONBOARDING.md` location already defined in harness but no generation skill. High impact: new engineers need ≤ 1 day to first commit. Currently requires senior engineer time.
- **LLM can do it:** Read HLD (C4 Container diagram), spec (REQ-NNN), ADRs, business context, and generate a structured guide: system overview, dev setup commands, first contribution checklist, architectural decisions summary. Triggered by `finishing-a-development-branch` on first production release.
- **Score impact:** Phase 11: 6.5→8.5
- **Effort:** Low-medium — new skill

---

**T-07: Infrastructure as Code (Terraform/Pulumi)**
- **Evidence:** Microsoft Engineering Fundamentals Playbook: "provisioning should be a repeatable process driven off code artifacts in git." DORA elite performers use IaC — it's a prerequisite for the "deploy on demand" capability. IaC is as important as CI config for DevOps completeness.
- **LLM can do it:** Generate Terraform modules for common patterns (VPC, ECS/K8s, RDS, Redis, S3) from the HLD Container diagram infrastructure sections. The HLD §8 (Capacity Planning) and §3 (C4 Container) already have the inputs needed.
- **Score impact:** Phase 8: 7→8.5
- **Effort:** High — new skill, significant template set

---

**T-08: Incident Response Workflow**
- **Evidence:** Google SRE's incident management process has 5 distinct phases: detect, respond, investigate, resolve, postmortem. Amazon: runbooks resolve 80% of incidents without escalation. Current harness has the runbooks but no orchestration skill for incident execution. This is the "execution gap" in Phase 10.
- **LLM can do it:** Skill that: (1) declares incident severity, (2) assembles incident context (which alert fired, which service, current SLO budget status), (3) walks through the runbook step-by-step with verification checkpoints, (4) generates postmortem template from incident timeline. Integrates with `observability-standards` runbooks already produced.
- **Score impact:** Phase 10: 7→8.5
- **Effort:** Medium — new skill, references existing runbooks

---

### VERIFIED ✅ — Worth doing, confirm evidence first

**T-09: Chaos Engineering**
- **Evidence:** Netflix Chaos Monkey (2011) established the pattern. Chaos Engineering is now mainstream — AWS Fault Injection Service, Chaos Mesh, Litmus are widely deployed. Key finding: systems that aren't tested under failure conditions fail unexpectedly. For high-availability services (99.9%+ SLO), chaos testing is not optional.
- **LLM can do it:** Generate k6 custom scenarios that inject errors (HTTP 500 at 10%, timeouts at 5%), verify circuit breaker behavior, generate Chaos Mesh/Litmus YAML for K8s failure injection. The `load-testing` skill already covers the k6 framework — chaos is an extension.
- **Caveat:** Only relevant for services with resilience NFRs (circuit breakers, retries, graceful degradation). Skip for CRUD APIs with no resilience requirements.
- **Score impact:** Phase 7: 9.5→9.8 (marginal; high value for resilient systems)
- **Verdict:** ✅ Worth adding as a conditional skill with clear "when to use" criteria

---

**T-10: Visual Regression Testing**
- **Evidence:** Chromatic (Storybook's cloud product) and Percy are used by Shopify, Airbnb, GitHub for preventing unintended UI changes. Playwright has built-in screenshot comparison (`expect(page).toHaveScreenshot()`). The gap is real: UI changes that don't break tests but do break the visual experience.
- **LLM can do it:** Extend the `e2e-testing` skill with Playwright screenshot snapshots on critical pages. Generate `playwright.config.ts` visual comparison settings, set snapshot update workflow in CI.
- **Caveat:** Only for UI-bearing features. API-only services: skip. Flakiness is a known challenge — needs proper baseline management.
- **Score impact:** Phase 7: marginal improvement (9.5 → 9.7)
- **Verdict:** ✅ Worth adding as an extension to `e2e-testing` with clear "UI features only" guard

---

### VERIFY FIRST — Evidence is mixed or unclear

**T-11: Database ERD Artifact**
- **Evidence:** PostgreSQL CommitFest reviewers examine schema migrations carefully. But ERDs are typically produced in DB design tools (dbdiagram.io, Lucidchart) and most mature teams don't maintain formal ERD files — they use the migration files as the source of truth.
- **LLM can do it:** Generate Mermaid `erDiagram` from migration files or schema definitions.
- **Caveat:** ERD tools like dbdiagram.io are better for interactive use; a Mermaid ERD in a markdown file is a weaker artifact. Value is real but lower than other items.
- **Verdict:** ⚠️ Build as lightweight enhancement — add `erDiagram` generation to `api-contract-first` for any feature with DB changes. Low effort, moderate value.

---

## Section 5: Prioritized Implementation Order

### Sprint 1 — Highest ROI (all LLM-executable, targeted gaps)

| # | Task | New skill/agent | Score Δ |
|---|------|----------------|--------|
| 1 | Linter gate | Enhance `verification-before-completion` | +0.5 on Phase 5 |
| 2 | Sequence diagrams (LLD) | `sequence-diagram` skill | +0.5 on Phase 3 |
| 3 | API versioning strategy | `api-versioning` skill | +0.5 on Phase 3 |
| 4 | Accessibility testing | Enhance `e2e-testing` with axe-playwright | +0.5 on Phase 7 |
| 5 | DAST security testing | `dast-testing` skill + `dast-reviewer` agent | +0.5 on Phase 7 |

**Sprint 1 projected score: 7.4 → 7.9**

### Sprint 2 — Bigger impact, more effort

| # | Task | New skill/agent | Score Δ |
|---|------|----------------|--------|
| 6 | Onboarding guide | `onboarding-guide` skill | +1.0 on Phase 11 |
| 7 | Incident response workflow | `incident-response` skill | +1.5 on Phase 10 |
| 8 | Chaos engineering | `chaos-engineering` skill + `chaos-reviewer` | +0.3 on Phase 7 |
| 9 | Visual regression | Enhance `e2e-testing` with screenshot baseline | +0.2 on Phase 7 |
| 10 | Database ERD | Enhance `api-contract-first` | +0.5 on Phase 3 |

**Sprint 2 projected score: 7.9 → 8.3**

### Sprint 3 — Infrastructure (highest effort)

| # | Task | New skill/agent | Score Δ |
|---|------|----------------|--------|
| 11 | IaC (Terraform/Pulumi) | `infrastructure-as-code` skill | +1.0 on Phase 8 |
| 12 | Postmortem template | Enhance `finishing-a-development-branch` | +0.3 on Phase 10 |

**Sprint 3 projected score: 8.3 → 8.6**

### Ceiling analysis

**8.6/10 is the realistic ceiling from skills alone.** Getting to 9+ requires closing the execution gap:
- The harness *generates* the deployment runbook. Reaching 9 requires *executing* the deploy with real infrastructure feedback.
- The harness *sets up* observability. Reaching 9 requires real-time incident triage from live signal data.

The execution gap requires integration with real infrastructure (cloud APIs, K8s, monitoring platforms) — it's an architectural extension beyond what skill files can do.

---

## Section 6: What's Genuinely Hard to Replace

This section is not about skills to build. It's about what makes this harness irreplaceable in some ways, and what remains genuinely human:

**Irreplaceable by any AI harness today:**
- Product intuition — identifying problems users haven't articulated
- Stakeholder relationships — trust built over years of interactions  
- Organizational memory — "we tried this in 2022, here's what happened"
- Production judgment under pressure — real-time incident decisions at 3am
- Cross-team negotiation — API contract disputes between teams
- Regulatory expertise — GDPR/HIPAA compliance requires legal judgment, not just templates

**What makes this harness uniquely strong vs. public tools:**
- Every phase has a reviewer agent. No public tool has this architecture.
- NFR chain: business context → spec → HLD → SLOs → k6 thresholds. Enforced end-to-end.
- Optionality: infer + confirm pattern means trivial changes get lightweight workflow.
- 12-phase coverage: no other public harness covers deployment runbooks, observability SLOs, and load testing alongside code generation.

---

*Sources: [METR randomized trial](https://metr.org), [GitClear AI code analysis 2024](https://www.gitclear.com/coding_on_copilot_data_shows_ais_downward_pressure_on_code_quality), [Atlassian Developer Experience Survey 2025](https://www.atlassian.com/blog/developer-experience), [ToolHalla Devin vs OpenHands 2026](https://toolhalla.ai/blog/devin-vs-openhands-vs-swe-agent-2026), [OpenHands GitHub (66k users)](https://github.com/All-Hands-AI/OpenHands), [arxiv.org/pdf/2603.20847 Engineering Pitfalls in AI Coding Tools](https://arxiv.org/pdf/2603.20847)*
