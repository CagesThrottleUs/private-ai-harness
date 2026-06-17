# AGENTS.md — AI agent reference for private-ai-harness

This file is the authoritative index for any AI (Claude Code, Codex, Gemini CLI, etc.)
working inside this repo. Keep it current whenever skills, agents, or the install flow change.

---

## Repo contract

This repo is a **Claude Code plugin** — no application code, no build step, no test suite.
Every file is loaded raw by Claude Code on `/reload-plugins`.

| Directory | Role |
|-----------|------|
| `skills/<name>/SKILL.md` | Slash-command skill loaded by Claude Code |
| `skills/<name>/scripts/` | Auxiliary bash scripts for a skill (e.g., `task-brief`, `review-package` in `subagent-driven-development`) |
| `agents/<name>.md` | Subagent definition (dispatched via Agent tool) |
| `scripts/install-tools.sh` | One-shot environment setup |
| `scripts/commit-msg.sh` | Conventional Commits enforcement hook |
| `.claude-plugin/plugin.json` | Plugin manifest (name, version) |
| `.claude-plugin/marketplace.json` | Local marketplace manifest |

---

## Available skills

Invoke with the `Skill` tool or as a slash command (`/<name>`).

| Skill name | Invocation | When to use |
|------------|------------|-------------|
| `brainstorming` | `/brainstorming` | Before any feature/component work |
| `business-context-intake` | `/business-context-intake` | Before brainstorming — structured interview capturing user problem, JTBD, measurable success metrics, compliance, non-goals, stakeholder map; runs `business-context-reviewer`; hard gate before brainstorming |
| `caveman` | `/caveman` | Ultra-compressed comms, ~75% token reduction |
| `code-documentation` | `/code-documentation` | Writing or modifying any public construct |
| `commit-discipline` | `/commit-discipline` | Generating compliant commit messages |
| `design-principles` | `/design-principles` | DRY, KISS, YAGNI, SOLID, GoF patterns — planning and review lens |
| `dispatching-parallel-agents` | `/dispatching-parallel-agents` | 2+ independent tasks |
| `executing-plans` | `/executing-plans` | Running a `.ai/plans/` plan with checkpoints |
| `finishing-a-development-branch` | `/finishing-a-development-branch` | Pre-merge checklist |
| `ci-pipeline-setup` | `/ci-pipeline-setup` | After worktree creation — detects CI platform, generates platform-agnostic pipeline spec + config (GitHub Actions/GitLab CI/Jenkins/CircleCI/Azure DevOps/Bitbucket), runs `ci-reviewer` before committing |
| `observability-standards` | `/observability-standards` | After first API endpoint is created — instruments OTel structured logging, golden signal metrics, produces SLO definition doc, alert rules, per-alert runbooks; runs `observability-reviewer` before committing |
| `deployment-workflow` | `/deployment-workflow` | Before PR is deployment-ready — deployment strategy recommendation, zero-downtime migration checklist, rollback procedure, smoke test spec, release notes draft, deploy runbook; runs `deployment-reviewer` |
| `integration-testing` | `/integration-testing` | During TDD GREEN phase for components with external I/O — Testcontainers setup (real DB/queue/cache), transaction rollback isolation, factory pattern, Pact contract tests for service APIs, CI integration job; runs `integration-test-reviewer` |
| `api-contract-first` | `/api-contract-first` | Before any handler/gRPC service implementation — writes OpenAPI 3.1 spec or .proto file, sets up Spectral linting, Prism mock server, CI spec lint job; runs `api-contract-reviewer`; hard gate before handler code |
| `e2e-testing` | `/e2e-testing` | Before `finishing-a-development-branch` for user-facing features — identifies critical user journeys, sets up Playwright with POM/auth fixtures/semantic locators, adds post-deploy CI E2E job against staging; runs `e2e-reviewer` |
| `load-testing` | `/load-testing` | Before `finishing-a-development-branch` when spec has NFR targets — generates k6 scripts (smoke/load/stress/spike/soak), thresholds tied to spec NFRs, CI performance job against staging; runs `load-test-reviewer` |
| `github-workflows` | `/github-workflows` | GH Actions and PR workflow patterns |
| `high-level-design` | `/high-level-design` | After spec-quality-gate passes — C4 diagrams, tech selection, STRIDE threat model, failure modes, capacity planning, ADRs. Runs `hld-reviewer` before human approval. |
| `karpathy` | `/karpathy` | Anti-LLM-pitfall coding guidelines |
| `pr-creator` | `/pr-creator` | Draft and open PRs |
| `prefer-deterministic-over-ai` | `/prefer-deterministic-over-ai` | Reach for grep/AST before LLM |
| `receiving-code-review` | `/receiving-code-review` | Acting on review feedback |
| `requesting-code-review` | `/requesting-code-review` | Requesting a review |
| `feature-flags` | `/feature-flags` | For any feature needing gradual rollout, A/B test, kill switch, or permission gate — OpenFeature SDK setup, naming conventions, flag registry, progressive rollout pattern, CI flag hygiene check; runs `feature-flag-reviewer` |
| `infrastructure-as-code` | `/infrastructure-as-code` | When feature needs new infrastructure (compute, DB, storage, networking) — Terraform/Pulumi structure with pinned versions, remote state + locking, typed variables, environment separation, tfsec CI scan; runs `iac-reviewer` |
| `database-erd` | `/database-erd` | During HLD §5.2 or writing-plans for any feature with DB changes — Mermaid erDiagram with entities/FKs/cardinality, index strategy, design decisions section; runs `database-erd-reviewer` |
| `visual-regression` | `/visual-regression` | For UI-bearing features after E2E setup — Playwright `toHaveScreenshot()`, animations disabled, baselines committed to git, pinned Docker CI job; runs `visual-regression-reviewer` |
| `chaos-engineering` | `/chaos-engineering` | For services with resilience NFRs (circuit breakers, retries) — k6 fault injection (HTTP errors, timeouts, latency spikes), Toxiproxy for network faults, steady state + hypothesis per scenario, CI chaos job post-staging; runs `chaos-reviewer` |
| `incident-response` | `/incident-response` | For any production service — severity matrix (SEV-1/2/3 with SLAs), IC role, declaration process, response playbook, blameless postmortem template, MTTD/MTTR targets; runs `incident-response-reviewer` |
| `onboarding-guide` | `/onboarding-guide` | On first production release or after major HLD changes — synthesizes HLD C4 diagrams, ADRs, OpenAPI spec, SLOs, runbooks into `wiki/ONBOARDING.md` with 8 required sections; runs `onboarding-reviewer` |
| `dast-testing` | `/dast-testing` | Before `finishing-a-development-branch` for externally-facing services — ZAP baseline (every PR, passive), ZAP API scan (post-staging, uses OpenAPI spec), Nuclei targeted API scan, SARIF to Security tab, fails on HIGH; runs `dast-reviewer` |
| `api-versioning` | `/api-versioning` | During api-contract-first or HLD for externally-facing APIs — produces versioning strategy ADR, breaking change policy, deprecation timeline with Sunset headers, migration guide template, CI oasdiff check; runs `api-versioning-reviewer` |
| `sequence-diagram` | `/sequence-diagram` | During HLD §5 or writing-plans for flows crossing 3+ components — Mermaid sequenceDiagram with auth boundary, error paths, sync/async arrows, retry blocks; runs `sequence-diagram-reviewer` |
| `review` | `/review` | Central entry point for all review types |
| `spec-quality-gate` | `/spec-quality-gate` | Gate on spec completeness before coding |
| `subagent-driven-development` | `/subagent-driven-development` | Orchestrate subagents for implementation — file-based handoffs (`scripts/task-brief` + `scripts/review-package`), single-pass unified task reviewer (`task-reviewer-prompt.md`), durable progress ledger, pre-flight plan scan |
| `systematic-debugging` | `/systematic-debugging` | Scientific debugging |
| `test-driven-development` | `/test-driven-development` | Red-green-refactor TDD loop |
| `using-git-worktrees` | `/using-git-worktrees` | Parallel branches without stash churn |
| `using-superpowers` | `/using-superpowers` | How to find and invoke skills |
| `verification-before-completion` | `/verification-before-completion` | Verify before marking done — includes linter gate (Ruff/Biome/golangci-lint/Clippy auto-detected, zero issues required, dispatches `linter-reviewer`) |
| `workflow` | `/workflow` | Full feature development pipeline |
| `writing-plans` | `/writing-plans` | Plan documents agents can execute |
| `writing-skills` | `/writing-skills` | Author new skills |

---

## Available agents

Dispatched via the `Agent` tool with `subagent_type: "private-ai-harness:<name>"`.

| Agent | Model | Purpose |
|-------|-------|---------|
| `pr-reviewer` | opus | PR diff review — 5 dimensions + spec traceability |
| `security-reviewer` | opus | Threat modeling, attack surface, auth/authz chains, cryptography |
| `spec-impl-reviewer` | opus | Verify implementation satisfies each REQ acceptance criterion |
| `test-quality-reviewer` | opus | Verify tests are meaningful, not just annotated |
| `full-project-reviewer` | opus | Holistic audit: code quality, security, reliability, performance |
| `language-expert-reviewer` | opus | Language-veteran review across 9 dimensions centered on behavioral correctness, invariant integrity, and language fit — not feature checklists. Supports C++, Rust, Python, TypeScript, Go, Java. |
| `sequence-diagram-reviewer` | opus | Sequence diagram quality gate — validates flow coverage (auth flows, error paths, async patterns), error path per external call, arrow type correctness (sync vs async), auth boundary placement, HLD participant alignment. 5 dimensions. Invoked by `sequence-diagram` skill. |
| `business-context-reviewer` | opus | Business context quality gate — validates problem statement is user-focused (not solution-framed), JTBD statement is complete, success metrics are measurable with baselines, compliance is explicitly addressed, non-goals present, stakeholders mapped, internal consistency. 6 dimensions. Invoked by `business-context-intake` skill. |
| `hld-reviewer` | opus | Pre-human HLD quality gate — validates C4 diagrams, technology selection, STRIDE threat model, failure modes, capacity planning, ADR completeness, spec coverage, and AWS Well-Architected alignment. Invoked by `high-level-design` skill before human review. |
| `spec-quality-reviewer` | opus | Spec quality gate — validates falsifiability, TC coverage, TC honesty, error path ownership, consistency, and dependency declaration against SQLite/RFC 8446/DO-178C standards. Invoked by `spec-quality-gate` skill. |
| `plan-reviewer` | opus | Implementation plan quality gate — validates spec coverage, task granularity (incl. Right-Sizing), Karpathy anti-patterns, placeholder detection, type/interface + Interfaces-block chain consistency, design principle compliance, Global Constraints section presence, and commit discipline. Invoked by `writing-plans` skill before execution handoff. |
| `ci-reviewer` | opus | CI/CD pipeline quality gate — validates stage completeness, fail-fast ordering, security hygiene, coverage gate, artifact immutability, environment gates, DORA readiness, and branch protection alignment. Platform-agnostic: GitHub Actions, GitLab CI, Jenkins, CircleCI, Azure DevOps, Bitbucket. Invoked by `ci-pipeline-setup` skill. |
| `observability-reviewer` | opus | Observability quality gate — validates OTel logging compliance (6 mandatory fields), golden signal coverage (all 4 signals), SLO quality vs spec NFRs, alert design (symptom-based, burn rate), runbook completeness (7 required sections), distributed tracing, SLO-to-alert alignment. Invoked by `observability-standards` skill. |
| `deployment-reviewer` | opus | Deployment quality gate — validates rollback procedure (7 sections, tested), DB migration safety (expand-contract pattern, dangerous patterns), smoke test coverage, deployment runbook, release notes quality (Keep a Changelog format), strategy-migration alignment. Invoked by `deployment-workflow` skill. |
| `integration-test-reviewer` | opus | Integration test quality gate — validates no mocks at boundary (cardinal rule), test isolation (transaction rollback), factory pattern, Testcontainers config (pinned versions, dynamic ports), spec AC coverage, contract tests (Pact), CI integration. 7 dimensions. Invoked by `integration-testing` skill. |
| `api-contract-reviewer` | opus | API contract quality gate — validates OpenAPI 3.1 or .proto completeness, error taxonomy, security definitions, breaking change safety, schema quality (money as float = Critical), REQ-NNN coverage, naming conventions. 7 dimensions. Invoked by `api-contract-first` skill. |
| `feature-flag-reviewer` | **sonnet** | Feature flag quality gate — naming conventions (type prefix, lowercase-hyphen), registry completeness (owner, expiry, rollout %), CI hygiene check blocks expired flags, no hardcoded true defaults on temporary flags, cleanup queue maintained. 5 dimensions. Invoked by `feature-flags` skill. |
| `iac-reviewer` | **sonnet** | IaC configuration gate — provider versions pinned, remote state with locking, sensitive variables marked, environment separation, security scan (tfsec/checkov) in CI, no secrets in code. 6 dimensions. Invoked by `infrastructure-as-code` skill. |
| `database-erd-reviewer` | **sonnet** | Database ERD quality gate — all entities have PK, FK references valid, cardinality with crow's foot notation, no money as float, index strategy documented, design decisions explained. 6 dimensions. Invoked by `database-erd` skill. |
| `visual-regression-reviewer` | **sonnet** | Visual regression test gate — screenshots on critical pages, animations disabled, baselines committed to git, dynamic content masked, CI uses pinned Docker image. 5 dimensions. Invoked by `visual-regression` skill. |
| `chaos-reviewer` | **sonnet** | Chaos test gate — steady state + hypothesis defined, scenarios match HLD failure modes, thresholds allow graceful degradation (not zero failures), abort criteria present, CI on staging only. 5 dimensions. Invoked by `chaos-engineering` skill. |
| `incident-response-reviewer` | **sonnet** | Incident response docs gate — severity matrix (3 levels, SLAs), IC role documented, postmortem template has 7 required sections, MTTD/MTTR targets, communication templates. Invoked by `incident-response` skill. |
| `onboarding-reviewer` | opus | Onboarding guide quality gate — validates 8 required sections, dev setup has executable commands with verification steps, C4 Container diagram present, ADRs referenced with daily-impact explanations, first contribution path covers harness workflow, ops section actionable. Invoked by `onboarding-guide` skill. |
| `dast-reviewer` | **sonnet** | DAST configuration gate — validates ZAP baseline on PRs, API scan on staging with OpenAPI spec, HIGH findings fail CI, SARIF uploaded, authentication configured. 5 dimensions. Invoked by `dast-testing` skill. |
| `accessibility-reviewer` | **sonnet** | Accessibility test gate — validates axe-playwright present on critical pages, correct WCAG tags (wcag21aa, wcag22aa for EU), violations fail CI (not just logged), exclusions documented. 4 dimensions. Invoked by `e2e-testing` skill. |
| `e2e-reviewer` | opus | E2E test quality gate — validates critical journey coverage, semantic selectors (CSS class selectors = Critical), no hardcoded waits (waitForTimeout = Critical), test independence, POM structure, auth fixtures, CI integration against staging. 7 dimensions. Invoked by `e2e-testing` skill. |
| `load-test-reviewer` | opus | Load test quality gate — validates NFR-aligned thresholds (arbitrary numbers = Critical), smoke test presence, realistic traffic modeling, appropriate test types (no soak for 99.9% availability = Critical), CI integration against staging (localhost = Critical), script quality. 6 dimensions. Invoked by `load-testing` skill. |
| `linter-reviewer` | **sonnet** | Linter gate validator — detects language from manifests, verifies correct 2025 tool used (Ruff/Biome/golangci-lint/Clippy), confirms zero output, type checker run, no new suppression comments. 4 checks. Invoked by `verification-before-completion`. First Sonnet review agent. |

Code review agents (`pr-reviewer`, `security-reviewer`, `spec-impl-reviewer`, `test-quality-reviewer`, `full-project-reviewer`, `language-expert-reviewer`) require `BASE_SHA` and `HEAD_SHA` (and usually `SPEC_PATH`). `pr-reviewer` and `spec-impl-reviewer` accept optional `DIFF_FILE` (pre-generated by `scripts/review-package BASE HEAD`) — if present, the agent reads it instead of running git commands.
All reviewer agents accept optional `REPORT_FILE` — if present, full findings are written there and only the verdict summary is returned to context.
Business context agents (`business-context-reviewer`) require `CONTEXT_PATH`.
Design agents (`hld-reviewer`) require `HLD_PATH` and `SPEC_PATH`.
Spec agents (`spec-quality-reviewer`) require `SPEC_PATH`.
Plan agents (`plan-reviewer`) require `PLAN_PATH` and `SPEC_PATH`; `HLD_PATH` optional.
CI agents (`ci-reviewer`) require `CI_CONFIG_PATH` and `PROJECT_ROOT`; `PIPELINE_SPEC_PATH` optional.
Observability agents (`observability-reviewer`) require `SLO_PATH` and `ALERTS_PATH`; `RUNBOOK_DIR` and `SPEC_PATH` optional.
Deployment agents (`deployment-reviewer`) require `ROLLBACK_PATH` and `SMOKE_TEST_PATH`; `RUNBOOK_PATH`, `MIGRATION_CHECKLIST_PATH`, `SPEC_PATH` optional.
Integration test agents (`integration-test-reviewer`) require `TEST_FILES`; `SPEC_PATH` optional.
API contract agents (`api-contract-reviewer`) require `SPEC_PATH` and `PROTOCOL`; `SPEC_SOURCE_PATH` and `HLD_PATH` optional.
E2E test agents (`e2e-reviewer`) require `TEST_FILES`; `SPEC_PATH` optional.
Load test agents (`load-test-reviewer`) require `SCRIPT_PATH`; `SPEC_PATH` and `SLO_PATH` optional.
API versioning agents (`api-versioning-reviewer`) require `ADR_PATH` and `POLICY_PATH`; `OPENAPI_PATH` optional.
Sequence diagram agents (`sequence-diagram-reviewer`) require `DIAGRAM_PATH`; `HLD_PATH` and `SPEC_PATH` optional.
Feature flag agents (`feature-flag-reviewer`) require `REGISTRY_PATH`; `CODE_PATH` optional.
IaC agents (`iac-reviewer`) require `IAC_DIR` and `TOOL`.
Database ERD agents (`database-erd-reviewer`) require `ERD_PATH`; `SPEC_PATH` optional.
Visual regression agents (`visual-regression-reviewer`) require `TEST_FILES` and `SNAPSHOT_DIR`.
Chaos agents (`chaos-reviewer`) require `TEST_FILES`; `HLD_PATH` and `SPEC_PATH` optional.
Incident response agents (`incident-response-reviewer`) require `PROCESS_PATH` and `POSTMORTEM_PATH`; `SLO_PATH` optional.
Onboarding agents (`onboarding-reviewer`) require `ONBOARDING_PATH`; `HLD_PATH` and `SPEC_PATH` optional.
DAST agents (`dast-reviewer`) require `CI_CONFIG_PATH`; `OPENAPI_PATH` and `ZAP_RULES_PATH` optional.
Accessibility agents (`accessibility-reviewer`) require `TEST_FILES`; `SPEC_PATH` and `BUSINESS_CONTEXT_PATH` optional.
Linter agents (`linter-reviewer`) require `PROJECT_ROOT` and `CHANGED_FILES`.
See each `agents/<name>.md` for the full input contract.

### Model Right-Sizing Criteria

**Rule:** Use the cheapest model that can catch the failures the agent is meant to catch. The cost of a missed finding always exceeds the cost of a more capable model.

| Model | Use when |
|-------|---------|
| **opus** | Judgment-heavy: findings require reasoning about subtle behavioral equivalence, language-standard nuances, architectural trade-offs, threat actors, or spec falsifiability. A cheaper model would produce false negatives that defeat the purpose of the review. |
| **sonnet** | Mechanically complex but judgment-light: structural pattern matching, format validation, coverage mapping where findings are deterministic given the input. |
| **haiku** | Never for review agents. Review is judgment work. |

**Current assignments and rationale:**

| Agent | Model | Judgment load | Right-size verdict |
|-------|-------|--------------|-------------------|
| `pr-reviewer` | opus | High — multi-dim code review, security patterns, spec traceability | ✅ Correct |
| `security-reviewer` | opus | High — threat modeling, cryptographic correctness, trust boundary reasoning | ✅ Correct |
| `spec-impl-reviewer` | opus | High — behavioral equivalence: "does code actually satisfy AC?" | ✅ Correct |
| `test-quality-reviewer` | opus | Medium-high — mock boundary judgment, mutation reasoning ("would this catch a subtle bug?") | ✅ Correct (Sonnet would miss TC honesty failures) |
| `full-project-reviewer` | opus | High — cross-file coherence, architectural pattern reasoning | ✅ Correct |
| `language-expert-reviewer` | opus | High — language-standard nuances, UB, ownership, unsafe invariants | ✅ Correct |
| `business-context-reviewer` | opus | High — product judgment ("is this solution-framed?"), metric measurability assessment, JTBD completeness, internal consistency across problem/metric/non-goals | ✅ Correct |
| `hld-reviewer` | opus | High — architecture quality judgment, threat model adequacy, ADR reasoning quality | ✅ Correct |
| `spec-quality-reviewer` | opus | High — falsifiability judgment, TC honesty ("would a wrong impl pass this?") | ✅ Correct (Sonnet handles format checks; Opus needed for quality checks 2a-2d) |
| `plan-reviewer` | opus | Medium-high — Karpathy anti-pattern judgment, YAGNI/SOLID violations, type consistency tracking | ✅ Correct |
| `ci-reviewer` | opus | Medium-high — security hygiene judgment (OIDC vs secrets, pinning), DORA readiness reasoning, environment gate adequacy | ✅ Correct |
| `observability-reviewer` | opus | Medium-high — SLO quality judgment (are targets meaningful?), alert design (symptom vs cause reasoning), runbook adequacy ("investigate" ≠ remediation) | ✅ Correct |
| `deployment-reviewer` | opus | High — DB migration safety requires deep judgment (subtle lock patterns, backward-compatibility reasoning), rollback adequacy ("revert" ≠ command), strategy-migration alignment requires systems reasoning | ✅ Correct |
| `integration-test-reviewer` | opus | High — "is this testing the real behavior or the mock's behavior?" is a judgment call, SQLite-vs-PostgreSQL behavioral differences require deep knowledge, isolation violation detection requires understanding test execution model | ✅ Correct |
| `api-contract-reviewer` | opus | High — breaking change detection requires deep API versioning knowledge, security gap assessment requires auth/authz reasoning, schema quality (float vs string for money) requires financial systems knowledge | ✅ Correct |
| `e2e-reviewer` | opus | Medium-high — "is this a critical journey?" requires product judgment, selector quality assessment requires Playwright internals knowledge, test independence detection requires understanding of test execution model | ✅ Correct |
| `load-test-reviewer` | opus | High — threshold-to-NFR alignment requires reading both spec and script, appropriate test type selection (soak vs spike vs load) requires performance engineering knowledge, traffic modeling realism requires domain understanding | ✅ Correct |

| `api-versioning-reviewer` | opus | High — breaking change policy completeness requires API design expertise, sunset header RFC 8594 compliance requires standards knowledge, migration guide adequacy requires consumer empathy | ✅ Correct |
| `sequence-diagram-reviewer` | opus | High — "is this error path sufficient?" requires systems thinking, auth boundary placement requires security judgment, sync vs async distinction requires architecture knowledge | ✅ Correct |
| `feature-flag-reviewer` | sonnet | Mechanical — naming prefix match (regex), expiry field present (registry scan), CI job present (config check), defaultValue=false on temp flags (code scan) | ✅ Correct — Sonnet |
| `iac-reviewer` | sonnet | Mechanical — versions.tf present? (file check), backend not local? (keyword scan), sensitive flag? (variable scan), tfvars exist? (file check), tfsec in CI? (step detection), no plaintext secrets? (regex scan) | ✅ Correct — Sonnet |
| `database-erd-reviewer` | sonnet | Mechanical — PK annotation present? (scan), FK references valid? (cross-check), cardinality notation? (symbol match), money as float? (field name + type scan) | ✅ Correct — Sonnet |
| `visual-regression-reviewer` | sonnet | Mechanical — toHaveScreenshot present? (pattern), animations disabled? (config check), snapshots in git? (.gitignore check), Docker pinned? (image tag check) | ✅ Correct — Sonnet |
| `chaos-reviewer` | sonnet | Mechanical — hypothesis present? (comment pattern), threshold allows failures? (number check), abort criteria? (documentation check), CI target? (URL pattern) | ✅ Correct — Sonnet |
| `incident-response-reviewer` | sonnet | Mechanical — severity levels present? (count check), SLAs are numbers not prose? (format check), 7 postmortem sections present? (section count), MTTD/MTTR defined? (pattern match) | ✅ Correct — Sonnet |
| `onboarding-reviewer` | opus | High — "could a new engineer be productive in one day?" requires genuine newcomer perspective, narrative clarity judgment, cross-checking diagrams against HLD for staleness | ✅ Correct |
| `dast-reviewer` | sonnet | Mechanical — ZAP action present? (pattern match), fail_action set? (config check), SARIF upload present? (step detection), auth configured? (secret reference check) | ✅ Correct — Sonnet |
| `accessibility-reviewer` | sonnet | Mechanical — is axe called? (pattern match), correct tags? (set comparison), assertion pattern? (code pattern), exclusion comments? (text search). No accessibility judgment required. | ✅ Correct — Sonnet |
| `linter-reviewer` | sonnet | Mechanical — tool detection via manifest pattern matching, output-clean check is deterministic, suppression scan is regex. No architectural judgment required. First Sonnet review agent. | ✅ Correct |

**When adding a new agent:** fill in the right-size verdict before merging. An agent created as `model: opus` without a rationale entry here is flagged for review.

---

## External skills loaded at install time

These are installed via `scripts/install-tools.sh` and available alongside this plugin.

| Source | What it adds |
|--------|-------------|
| `pbakaus/impeccable` | UI quality review |
| `emilkowalski/skill` | Frontend component patterns |
| `Leonxlnx/taste-skill` | Visual taste heuristics |

> `mukul975/Anthropic-Cybersecurity-Skills` (754 skills) is commented out in `scripts/install-tools.sh` — uncomment to enable.

---

## Doc-sync rule

**Any change to skills, agents, install steps, or plugin structure must update:**

1. `AGENTS.md` — skill/agent table, external skill list, input contracts
2. `CLAUDE.md` — rules affected by the change (version bump criteria, workflow steps, upstream watch list)
3. `README.md` — install step list, prerequisites, skill/agent tables

Treat these three files as a synchronized triple. If one changes, check the others.

---

## Upstream skills to monitor

Three local skills are sourced from external references and can drift:

| Skill | Upstream | Check |
|-------|----------|-------|
| `skills/caveman/SKILL.md` | [emilkowalski/skill](https://github.com/emilkowalski/skill) | `gh repo view emilkowalski/skill --web` |
| `skills/using-superpowers/SKILL.md` | upstream superpowers skill | `gh search repos "claude superpowers skill"` |
| `skills/karpathy/SKILL.md` | Karpathy guidelines | `gh search repos "karpathy claude skill"` |

When upgrading: diff upstream against local, preserve local customizations, bump patch version.

---

## Version bump rules

Version lives in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

| Change | Bump |
|--------|------|
| Typo, description tweak, prompt fix | patch |
| New skill or agent | minor |
| Structural change (manifest format, breaking rename) | major |

Always bump before committing a skill/agent change so `/reload-plugins` picks it up.
