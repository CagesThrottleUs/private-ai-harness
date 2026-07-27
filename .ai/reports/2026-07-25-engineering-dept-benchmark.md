# Engineering-Department Capability Benchmark — private-ai-harness

**Date:** 2026-07-25
**Author:** analysis run
**Question:** Can this harness produce the full body of work of a top-tier
engineering department, and how does it score against the durable
"north-star" practices of the most advanced engineering orgs?

---

## Part 1 — Reference model: what "engineering department work" is

Synthesized from the most-cited sources (Google *Software Engineering at
Google* + SRE books, Amazon Working Backwards, Team Topologies / platform
engineering, DORA/SPACE, agentic-SDLC research). A top-tier department is a
**capability chain**, each link carrying a durable north-star practice.

| # | Capability | North-star practice |
|---|---|---|
| 1 | Customer/business intake | Working Backwards / PR-FAQ; JTBD + measurable success metrics |
| 2 | Ideation & alternatives | 2–3 approaches with trade-offs; YAGNI |
| 3 | Spec / requirements | Falsifiable, testable requirements |
| 4 | Architecture / design docs | Design doc before code; C4, ADRs, STRIDE, capacity, failure modes, AWS Well-Architected |
| 5 | Contract-first | API/interface contract before handler code |
| 6 | Decomposition & planning | Small independently-shippable units; parallel vs sequential waves |
| 7 | Implementation | TDD; simplicity & readability over cleverness; small changes |
| 8 | Code review | Review for long-term codebase health, not correctness; first response < 1 business day |
| 9 | Testing | Automated by default; full pyramid unit→integration→e2e→load→chaos→security |
| 10 | CI/CD | Automate build/test/deploy; small frequent releases; shift security left |
| 11 | Deployment & release | Progressive rollout, expand-contract migrations, feature flags, tested rollback |
| 12 | Observability & reliability | Golden signals; SLOs + error budgets as launch-risk currency |
| 13 | Production Readiness Review | Explicit PRR gate before production traffic |
| 14 | Incident response | Severity matrix, blameless postmortems, MTTD/MTTR |
| 15 | Knowledge & onboarding | Living docs 1:1 with behavior; productive-in-a-day |
| 16 | Platform / golden paths | Paved roads — self-service scaffolding & opinionated templates |
| 17 | Delivery measurement | DORA (+ reliability) + SPACE |
| 18 | Portfolio / org orchestration | Roadmap, backlog, cross-team prioritization, dependency mgmt, distinct roles |

Meta-north-star: **write it down and review it before you build it, then
measure what you shipped.**

---

## Part 2 — Harness scored against the reference model

Score: 10 = matches or exceeds an elite human org; 5 = present but partial;
≤3 = real gap.

| # | Capability | Harness coverage | Score | Gap to 10 |
|---|---|---|---|---|
| 1 | Customer/business intake | `business-context-intake` + `business-context-reviewer` | 8 | No PR-FAQ / future-press-release forcing function |
| 2 | Ideation & alternatives | `brainstorming` | 9 | — |
| 3 | Spec quality | `spec-quality-gate` + `spec-quality-reviewer` (SQLite/RFC 8446/DO-178C) | 10 | Exceeds |
| 4 | Architecture / design docs | `high-level-design` + `hld-reviewer` + `database-erd` + `sequence-diagram` + `api-versioning` | 9 | No multi-stakeholder narrative-review sign-off |
| 5 | Contract-first | `api-contract-first` + `api-contract-reviewer` | 9 | — |
| 6 | Decomposition & planning | `writing-plans` + `plan-reviewer` + `epic-decomposition` | 9 | Single-epic only (see 18) |
| 7 | Implementation discipline | `test-driven-development` + `subagent-driven-development` + `karpathy` + `design-principles` + `code-documentation` | 9 | — |
| 8 | Code review | 6 reviewer agents + `giving/requesting/receiving-code-review` | 10 | Exceeds |
| 9 | Testing (full pyramid) | TDD + integration + e2e + load + chaos + visual + dast + a11y, each reviewed | 10 | Exceeds |
| 10 | CI/CD | `ci-pipeline-setup` + `ci-reviewer` | 8 | Generates config; doesn't run/measure a live pipeline |
| 11 | Deployment & release | `deployment-workflow` + `deployment-reviewer` + `feature-flags` + `infrastructure-as-code` | 8 | No error-budget release gate; small-batch cadence implicit |
| 12 | Observability & SLOs | `observability-standards` + `observability-reviewer` | 9 | Error-budget policy not enforced as a gate |
| 13 | Production Readiness Review | Implicit across deploy + obs + finishing | 6 | No distinct PRR gate/artifact |
| 14 | Incident response | `incident-response` + `incident-response-reviewer` | 9 | — |
| 15 | Knowledge & onboarding | `code-documentation` + `onboarding-guide` + wiki-sync | 9 | — |
| 16 | Platform / golden paths | The harness paves the *process*; no service scaffolding | 5 | No self-service repo/service templates |
| 17 | Delivery measurement | `cost-ledger` (tokens only) | 3 | No DORA/SPACE loop |
| 18 | Portfolio / org orchestration | `epic-decomposition` + recursion | 3 | No roadmap/backlog/multi-epic/role model |

**Aggregate:**
- Per-epic SDLC rigor (1–15): **≈ 9/10 — world-class.** Exceeds typical orgs
  on spec falsifiability, review depth, and testing breadth.
- Platform & measurement (16, 17): **≈ 4/10.**
- Department/portfolio (18): **≈ 3/10.**

**North-star gaps ranked by blocking impact on "department work":**
1. Portfolio orchestration (18) — no layer above one epic.
2. DORA/SPACE measurement (17) — ships work, never scores its own delivery.
3. Golden-path scaffolding (16) — paves the road, not the on-ramp.
4. Error-budget & PRR gates (12/13) — SLOs authored but not enforced.

**Where it exceeds a 10-baseline human org:** adversarial multi-agent review
(security-reviewer, trust-but-verify, load-bearing-claim verification),
falsifiability gates on specs, and a testing pyramid wired as hard gates.

---

## Part 3 — Entry-point verdict (`/engineer`)

**Can it create a full engineering department's work?**
- *One epic / product line, end-to-end:* **yes** — the epic lane chains
  intake → brainstorm → spec-gate → HLD (human-approved) → decomposition →
  recursive per-story task lanes → deployment → observability → incident →
  onboarding, every gate hard-blocking.
- *An entire department:* **not yet** — depth through recursion, not breadth
  through a portfolio layer. Missing: roadmap/backlog above epic, cross-epic
  dependency tracking, role-based org model, true concurrent multi-story
  execution.

**At minimized tokens?**
- Architecturally strong for single-epic scope: artifact-by-reference,
  verdict-only returns, file-based handoffs, `/compact` checkpoints, manifest
  as durable state, model right-sizing.
- Cost is **observed, not governed**: no per-subagent attribution, no spend
  cap / budget circuit-breaker. At department scale, spend stays visible but
  uncontrolled.

**Bottom line:** world-class single-epic SDLC engine (~9/10); not yet a
department portfolio orchestrator (~3/10); token architecture ~8/10 but
un-governed.

**Four highest-leverage additions:** (1) portfolio/roadmap layer above epic,
(2) DORA/SPACE delivery-measurement loop, (3) golden-path service
scaffolding, (4) per-subagent cost attribution + spend cap.

---

## Sources

- Applied "Software Engineering at Google" — Addy Osmani
- Google's Engineering Practices — Code Review
- DORA metrics guide — getdx; DORA vs SPACE — Hivel
- Platform Engineering: Golden Paths & IDPs — Forbes
- SDLC phases and best practices — CircleCI
- Google SRE — Error Budget Policy; Embracing Risk
- Amazon Working Backwards PR/FAQ
- Where do all the tokens go in agentic software engineering — RDEL
- Context Engineering for AI Agents (arXiv 2510.21413)
