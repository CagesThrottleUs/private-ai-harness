# AGENTS.md — AI agent reference for private-ai-harness

This file is the authoritative index for any AI (Claude Code, Codex, Gemini CLI, etc.)
working inside this repo. Keep it current whenever skills, agents, or the install flow change.

---

## Repo contract

This repo is a **Claude Code, Codex, and GitHub Copilot plugin** — no
application code, no build step, no test suite. Skills are shared and loaded
raw by all three hosts. Claude refreshes them on `/reload-plugins`; Codex
loads plugin changes in a new session after reinstalling the local plugin;
Copilot picks up a re-run of `install-copilot.sh` on its next session (no
plugin-reload step of its own).

| Directory | Role |
|-----------|------|
| `skills/<name>/SKILL.md` | Shared skill loaded by Claude Code and Codex; the same `skills/*/SKILL.md` layout is GitHub's native Agent Skills discovery convention, so Copilot loads it unmodified too |
| `skills/<name>/scripts/` | Auxiliary bash scripts for a skill (e.g., `task-brief`, `review-package` in `subagent-driven-development`) |
| `agents/<name>.md` | Canonical reviewer definition; Claude loads it directly, and Codex, opencode, and Copilot adapters are generated from it |
| `scripts/install-claude.sh` | One-shot shared + detected-host environment setup (Claude Code primary, also chains Codex install) |
| `scripts/install-codex.sh` | Codex plugin, custom-agent, global-guidance, and sound-notify installer |
| `scripts/install-opencode.sh` | opencode installer — symlinks `skills/` natively, registers Context7 MCP, installs sound plugin, commit-msg hook, adapts `agents/*.md` to opencode subagents, AGENTS.md guidance |
| `scripts/install-copilot.sh` | Copilot installer — per-skill symlinks `skills/<name>` into `~/.copilot/skills/` (shared directory, not a wholesale-tree symlink), adapts `agents/*.md` to Copilot Agent Skills via `install-copilot-agents.py`, syncs global guidance into `~/.copilot/copilot-instructions.md`; also ports whatever `install-claude.sh` sets up that has a verified Copilot equivalent — `rtk init -g --copilot`, Context7 MCP, UI/Android skills via the `skills` CLI's `github-copilot` agent target, skydoves/silvermoon/Meet-Miyani/rcosteira79/aldefy skill packs cloned and copied directly, and sound-notify hooks (`sessionStart`/`agentStop`/`preToolUse`/`postToolUse`) in `~/.copilot/hooks/private-ai-harness.json`; prints what has no Copilot equivalent (claude-mem, Claude's plugin-marketplace items, statusline) and why |
| `scripts/codex-notify.sh` | Adapter: Codex's single `notify` hook → `hook-beep.sh` event names |
| `scripts/copilot-notify.sh` | Adapter: Copilot CLI's per-event hooks (`sessionStart`/`agentStop`/`preToolUse`/`postToolUse`) → `hook-beep.sh` event names, invoked with the target event name as an argument since Copilot's own hook payloads don't always name the firing event |
| `scripts/opencode-notify-plugin.js` | opencode plugin (auto-loaded from `plugin/`): maps tool executes (blocking `tool.execute.before`/`after` hooks, NOT bus events) plus bus events (`session.idle`/`session.error`/`session.compacted`/`permission.asked`) → `hook-beep.sh` event names |
| `scripts/install-codex-agents.py` | Deterministic Markdown-to-Codex-TOML agent adapter |
| `scripts/install-opencode-agents.py` | Deterministic Markdown-to-opencode-subagent adapter (renders `agents/*.md` → `private-ai-harness-<name>.md` in opencode's global agents dir, `mode: subagent`, no `model` → inherits the invoking agent's model) |
| `scripts/install-copilot-agents.py` | Deterministic Markdown-to-Copilot-Agent-Skill adapter (renders `agents/*.md` → `~/.agents/skills/<name>/SKILL.md`; Copilot has no model-tier dispatch, so the Claude model label is replaced with a neutral "(GitHub Copilot)" tag) |
| `scripts/commit-msg.sh` | Conventional Commits enforcement hook |
| `scripts/hook-beep.sh` | Claude Code hook: plays a sound on tool/notification/stop/compact/permission events |
| `hooks/*.json` | Claude Code hook manifests wiring events to `scripts/hook-beep.sh` (Claude Code only, not loaded by Codex) |
| `assets/sounds/` | Default beep sound files, ported from voicemode (MIT) so the sound survives uninstalling that plugin |
| `.claude-plugin/plugin.json` | Claude Code plugin manifest (name, version) |
| `.claude-plugin/marketplace.json` | Local marketplace manifest used by Claude and supported by Codex as a legacy-compatible marketplace |
| `.codex-plugin/plugin.json` | Native Codex plugin manifest and install-surface metadata |

---

## Available skills

Claude Code invokes skills with the `Skill` tool or `/<name>`. Codex loads the
same skills natively; mention `$<name>` or select them with `/skills` (installed
plugin UIs may display the `private-ai-harness:` namespace). Copilot
auto-loads them from `~/.copilot/skills/` once relevant to the task — describe
the task, or name the skill directly in the prompt.

| Skill name | Invocation | When to use |
|------------|------------|-------------|
| `android-advisor` | `/android-advisor` | First `domain-overlay` instance — for Android/Kotlin/Compose/KMP work with multiple overlapping installed global skills, resolves which specialist wins per sub-task (precedence table + tie-break reason), maps each to an engineer lane step, defines the hamen+skydoves-perf pre-review audit gate; activated by the engineer Universal-constraints domain-overlay hook |
| `brainstorming` | `/brainstorming` | Before any feature/component work |
| `business-context-intake` | `/business-context-intake` | Before brainstorming — structured interview capturing user problem, JTBD, measurable success metrics, compliance, non-goals, stakeholder map; runs `business-context-reviewer`; hard gate before brainstorming |
| `caveman` | `/caveman` | Ultra-compressed comms, ~75% token reduction |
| `code-documentation` | `/code-documentation` | Writing or modifying any public construct |
| `codebase-comprehension` | `/codebase-comprehension` | Universal Step 1 in every lane — maps relevant symbols, callers, data flow, and dependencies using codegraph/scout before any code change; inline for quick-fix, writes `.ai/<id>/comprehension.md` for task/epic |
| `commit-discipline` | `/commit-discipline` | Generating compliant commit messages |
| `design-principles` | `/design-principles` | DRY, KISS, YAGNI, SOLID, GoF patterns — planning and review lens |
| `dispatching-parallel-agents` | `/dispatching-parallel-agents` | 2+ independent tasks |
| `domain-overlay` | `/domain-overlay` | Pattern for a precedence+ordering layer over overlapping externally-installed global skills in one technology domain — defines the four-part contract each `<domain>-advisor` instance must provide (detection signals, precedence table with tie-break reasons, lane-step mapping, pre-review audit gate); engineer's Universal-constraints hook activates the matching instance |
| `executing-plans` | `/executing-plans` | Running a `.ai/<feature-slug>/plans/` plan with checkpoints |
| `finishing-a-development-branch` | `/finishing-a-development-branch` | Pre-merge checklist |
| `ci-pipeline-setup` | `/ci-pipeline-setup` | After worktree creation — detects CI platform, generates platform-agnostic pipeline spec + config (GitHub Actions/GitLab CI/Jenkins/CircleCI/Azure DevOps/Bitbucket), runs `ci-reviewer` before committing |
| `observability-standards` | `/observability-standards` | After first API endpoint is created — instruments OTel structured logging, golden signal metrics, produces SLO definition doc, alert rules, per-alert runbooks; runs `observability-reviewer` before committing |
| `deployment-workflow` | `/deployment-workflow` | Before PR is deployment-ready — deployment strategy recommendation, zero-downtime migration checklist, rollback procedure, smoke test spec, release notes draft, deploy runbook; runs `deployment-reviewer` |
| `integration-testing` | `/integration-testing` | During TDD GREEN phase for components with external I/O — Testcontainers setup (real DB/queue/cache), transaction rollback isolation, factory pattern, Pact contract tests for service APIs, CI integration job; runs `integration-test-reviewer` |
| `property-based-testing` | `/property-based-testing` | During TDD's white-box pass for any function with a checkable invariant (round-trip, idempotence, algebraic law — parsers, serializers, sort/dedup logic) — generates Hypothesis/fast-check/jqwik/proptest/Go-fuzz tests instead of hand-picked examples; reviewed under `test-quality-reviewer`'s dimension 3i |
| `formal-verification` | `/formal-verification` | Risk-gated: a **critical-core** (crypto, auth/authz, monetary arithmetic, consensus/ordering, `unsafe` safety) in a language with a verifier — full-deductive (Rust/Verus, Dafny, Ada/SPARK, C/Frama-C, Java/OpenJML) or bounded (C++/CBMC·ESBMC). Escalates a property-based invariant to a machine-checked `requires`/`ensures` proof, web-confirms the live toolchain version before writing contracts, blocks on undischarged obligations, and falls back cleanly to `property-based-testing` when no verifier exists. Wired into the engineer `fv-eligible` flow (task lane 6a, epic HLD + PRR); runs `formal-verification-reviewer` |
| `api-contract-first` | `/api-contract-first` | Before any handler/gRPC service implementation — writes OpenAPI 3.1 spec or .proto file, sets up Spectral linting, Prism mock server, CI spec lint job; runs `api-contract-reviewer`; hard gate before handler code |
| `e2e-testing` | `/e2e-testing` | Before `finishing-a-development-branch` for user-facing features — identifies critical user journeys, sets up Playwright with POM/auth fixtures/semantic locators, adds post-deploy CI E2E job against staging; runs `e2e-reviewer` |
| `emil-design-eng` | `/emil-design-eng` | UI polish, component design, animation decisions, and invisible details that make software feel great — Emil Kowalski's design engineering philosophy |
| `engineer` | `/engineer` | **Universal entry point** — routes any request to the right lane (quick-fix/task/epic/research), classifies complexity from observable signals, proposes a skill chain, waits for user confirmation, then starts the flow |
| `epic-decomposition` | `/epic-decomposition` | After HLD human approval in the epic lane — breaks epic into bounded stories, creates child work-item manifests under `.ai/<epic-slug>/children/`, identifies parallel vs sequential dependency waves |
| `portfolio-management` | `/portfolio-management` | The layer ABOVE a single epic — SAFe Portfolio Kanban (Funnel→Reviewing→Analyzing→Backlog→Implementing→Done), WSJF ranking (cost of delay ÷ job size), WIP limits (Little's Law), cross-epic dependency DAG, OKR linkage; pulls the top-WSJF epic into the epic lane when WIP allows; the engineer PORTFOLIO lane routes here; runs `portfolio-reviewer` |
| `service-scaffolding` | `/service-scaffolding` | Golden-path scaffolding for a NEW service (CNCF Platform Eng Maturity L3) — emits the paved starting artifact (CI, observability, API contract stub, test harness, runbook, resource limits, `catalog-info.yaml`, scorecard) so the service is born compliant; registers it in the service catalog; runs in the epic lane before children build into it; runs `service-scaffolding-reviewer` |
| `load-testing` | `/load-testing` | Before `finishing-a-development-branch` when spec has NFR targets — generates k6 scripts (smoke/load/stress/spike/soak), thresholds tied to spec NFRs, CI performance job against staging; runs `load-test-reviewer` |
| `github-workflows` | `/github-workflows` | GH Actions and PR workflow patterns |
| `high-level-design` | `/high-level-design` | After spec-quality-gate passes — C4 diagrams, tech selection, STRIDE threat model, failure modes, capacity planning, ADRs. Runs `hld-reviewer` before human approval. |
| `karpathy` | `/karpathy` | Anti-LLM-pitfall coding guidelines |
| `pr-creator` | `/pr-creator` | Draft and open PRs |
| `pr-review-non-negotiables` | (reference only, no `/` invocation) | Global, tool-agnostic PR review checklist (backward compat, migration, performance, reuse, testing, security, why/ROI, UX, determinism, over/underengineering balance, compatibility matrix) — referenced from user-global `CLAUDE.md` so it applies to every reviewer (`pr-reviewer`, `giving-code-review`, `requesting-code-review`, `scout-pr-review`) in every repo, layered above any repo-local `.scout/review-policy.md` |
| `giving-code-review` | `/giving-code-review` | Acting as reviewer on a PR via `gh` — someone else's, or self-review of your own before requesting external review; walks every commit, applies `pr-reviewer`'s dimensions, runs a trust-but-verify pass on claims, doubles rigor in self-review mode |
| `receiving-code-review` | `/receiving-code-review` | Acting on review feedback — verify before implementing, and run the Pattern Propagation Check: fix every sibling occurrence of an accepted finding's pattern within the current PR's diff (analogous paths like CLI vs MCP / primary vs fallback, every call site of a changed shared helper, and a determinism self-check on new concurrency), not just the flagged line; then the Proportionality Gate — a real, in-scope finding needing a disproportionate rewrite (formal proof, multi-site truth table) gets a simpler fix or a follow-up ticket, not a maximal one |
| `closing-review-loops` | `/closing-review-loops` | Closing a review round to zero negotiable rounds — after fixing findings and before re-triggering any external reviewer (Talos/CodeRabbit/human), batch every open finding, fix in one pass, run an internal self-review that hunts the same failure classes plus fix-introduced regressions, push once, then re-trigger; re-checks cumulative branch size/commit count and cohesion every round — not only at first submission — and reports a commits/LOC receipt after each push; strong-default gate with recorded-reason override |
| `refactoring` | `/refactoring` | Behavior-preserving restructure with test guard at every step — names the smell (god class/duplication/nesting/coupling), establishes test baseline, one structural move per micro-commit, behavior verified after each; zero new behavior |
| `requesting-code-review` | `/requesting-code-review` | Requesting a review; before re-triggering an external reviewer after a fix, gates on `closing-review-loops` (internal self-review clean first) |
| `research-spike` | `/research-spike` | Time-boxed feasibility, comparison, or POC investigation — answer is the deliverable, not code; produces decision artifact in `.ai/` or ADR in `wiki/architecture/`; spike code is throwaway |
| `feature-flags` | `/feature-flags` | For any feature needing gradual rollout, A/B test, kill switch, or permission gate — OpenFeature SDK setup, naming conventions, flag registry, progressive rollout pattern, CI flag hygiene check; runs `feature-flag-reviewer` |
| `infrastructure-as-code` | `/infrastructure-as-code` | When feature needs new infrastructure (compute, DB, storage, networking) — Terraform/Pulumi structure with pinned versions, remote state + locking, typed variables, environment separation, tfsec CI scan; runs `iac-reviewer` |
| `database-erd` | `/database-erd` | During HLD §5.2 or writing-plans for any feature with DB changes — Mermaid erDiagram with entities/FKs/cardinality, index strategy, design decisions section; runs `database-erd-reviewer` |
| `visual-regression` | `/visual-regression` | For UI-bearing features after E2E setup — Playwright `toHaveScreenshot()`, animations disabled, baselines committed to git, pinned Docker CI job; runs `visual-regression-reviewer` |
| `chaos-engineering` | `/chaos-engineering` | For services with resilience NFRs (circuit breakers, retries) — k6 fault injection (HTTP errors, timeouts, latency spikes), Toxiproxy for network faults, steady state + hypothesis per scenario, CI chaos job post-staging; runs `chaos-reviewer` |
| `deterministic-simulation-testing` | `/deterministic-simulation-testing` | For concurrent/distributed components (consensus, replication, multi-node coordination) — seeded, replayable fault injection through every nondeterministic boundary (network/disk/clock), modeled on TigerBeetle's VOPR and FoundationDB's simulation testing; runs `chaos-reviewer`'s DST dimension |
| `incident-response` | `/incident-response` | For any production service — severity matrix (SEV-1/2/3 with SLAs), IC role, declaration process, response playbook, blameless postmortem template, MTTD/MTTR targets; runs `incident-response-reviewer` |
| `production-readiness-review` | `/production-readiness-review` | Before first production traffic — one go/no-go PRR artifact over the SRE Launch Coordination Checklist's seven dimensions (Service Levels, Architecture & Dependencies, Performance & Capacity, Observability, Deployment & Rollback, Operability, Testing & Security); accepts a readiness claim only when evidenced, not when plausibly written; runs `production-readiness-reviewer`; hard gate in the epic lane |
| `delivery-metrics` | `/delivery-metrics` | Score the harness's own delivery performance — DORA four keys + reliability and Flow Framework flow efficiency, derived from work-item manifest phase timestamps and the engineer cost-ledger via `scripts/dora-report`; withholds failure-dependent keys (CFR/MTTR/reliability) until a real incident linkage exists rather than fabricating them; runs `delivery-metrics-reviewer` |
| `onboarding-guide` | `/onboarding-guide` | On first production release or after major HLD changes — synthesizes HLD C4 diagrams, ADRs, OpenAPI spec, SLOs, runbooks into `wiki/ONBOARDING.md` with 8 required sections; runs `onboarding-reviewer` |
| `outcome-review` | `/outcome-review` | After a feature ships (and at HEART-aligned checkpoints) — measures the business-context north-star + input metrics against target with cited re-runnable sources, renders persevere/iterate/kill, feeds the portfolio; rejects any metric lacking a real data source (AI-fabrication guard); closes the "measure what you shipped" loop; runs `outcome-review-reviewer`; last epic-lane step |
| `dast-testing` | `/dast-testing` | Before `finishing-a-development-branch` for externally-facing services — ZAP baseline (every PR, passive), ZAP API scan (post-staging, uses OpenAPI spec), Nuclei targeted API scan, SARIF to Security tab, fails on HIGH; runs `dast-reviewer` |
| `api-versioning` | `/api-versioning` | During api-contract-first or HLD for externally-facing APIs — produces versioning strategy ADR, breaking change policy, deprecation timeline with Sunset headers, migration guide template, CI oasdiff check; runs `api-versioning-reviewer` |
| `sequence-diagram` | `/sequence-diagram` | During HLD §5 or writing-plans for flows crossing 3+ components — Mermaid sequenceDiagram with auth boundary, error paths, sync/async arrows, retry blocks; runs `sequence-diagram-reviewer` |
| `review` | `/review` | Central entry point for all review types |
| `spec-quality-gate` | `/spec-quality-gate` | Gate on spec completeness before coding — runs `scripts/pre-lint.sh` (zero-cost mechanical Section 1 format check) before ever dispatching the Opus reviewer, so specs stop failing the gate on frontmatter/heading defects the author can fix for free; pre-lint also requires the `north_star:` frontmatter field so a feature spec cannot pass without a declared business outcome |
| `subagent-driven-development` | `/subagent-driven-development` | Orchestrate subagents for implementation — file-based handoffs (`scripts/task-brief` + `scripts/review-package`), single-pass unified task reviewer (`task-reviewer-prompt.md`), plan-scoped progress ledger (`.ai/<feature-slug>/sdd/`), pre-flight plan scan, 5-round fix loop (resume implementer rounds 1-3, escalate fresh+stronger model rounds 4-5, scoped re-review via `re-review-prompt.md`, park/BLOCK adjudication at the cap) |
| `systematic-debugging` | `/systematic-debugging` | Scientific debugging |
| `teacher` | `/teacher` | **Independent front door, separate track from `/engineer`** — never touches production code. Takes a request, evidence-maps what was actually built (Scout/codegraph/git diff, cited `file:line`) against an ideal solution backed only by derived complexity proofs, official docs, or canonical references (no hand-wavy claims), then runs a Socratic question loop to surface the drift — never states the fix. Assigns near- and far-transfer exercises, grades the returned explanation via feed up/feed back/feed forward, and logs concepts for spaced re-quizzing. Exists to prevent engineering skill atrophy. |
| `test-driven-development` | `/test-driven-development` | Red-green-refactor TDD loop |
| `using-git-worktrees` | `/using-git-worktrees` | Parallel branches without stash churn |
| `using-superpowers` | `/using-superpowers` | How to find and invoke skills |
| `verification-before-completion` | `/verification-before-completion` | Verify before marking done — includes linter gate (Ruff/Biome/golangci-lint/Clippy auto-detected, zero issues required, dispatches `linter-reviewer`) |
| `workflow` | `/workflow` | Full feature development pipeline |
| `writing-plans` | `/writing-plans` | Plan documents agents can execute |
| `writing-skills` | `/writing-skills` | Author new skills |

---

## Available agents

Claude Code dispatches with the `Agent` tool and
`subagent_type: "private-ai-harness:<name>"`. Codex dispatches the generated
custom agent `private-ai-harness-<name>`. `scripts/install-codex-agents.py`
maps `opus` to high reasoning, `sonnet` to medium, and `haiku` to low while
inheriting the parent Codex model. opencode dispatches the generated subagent
`private-ai-harness-<name>` (via Task tool or @mention) with no `model` key,
so it inherits the invoking primary agent's model and permissions. Copilot has
no subagent-dispatch tool with a per-agent model tier, so
`scripts/install-copilot-agents.py` instead renders each agent as an ordinary
Agent Skill at `~/.agents/skills/<name>/SKILL.md` — Copilot loads it like any
other skill, triggered by matching the task against its description, and the
Claude model-tier label in the body is replaced with a neutral
"(GitHub Copilot)" tag since there is no reasoning-effort dial to map it to.

| Agent | Model | Purpose |
|-------|-------|---------|
| `pr-reviewer` | opus | PR diff review — 6 dimensions (incl. AI-authored-code risk) + spec traceability + regression-test check for fix-typed commits + global non-negotiables gate |
| `security-reviewer` | opus | Threat modeling, attack surface, auth/authz chains, cryptography |
| `spec-impl-reviewer` | opus | Verify implementation satisfies each REQ acceptance criterion |
| `test-quality-reviewer` | opus | Verify tests (including property-based/fuzz tests) are meaningful, not just annotated |
| `formal-verification-reviewer` | opus | Verify a machine-checked proof actually discharges against the live verifier toolchain, no obligation was silently skipped, a bounded-model-checking result never overclaims an unbounded proof, and — primary job — the specification proven is the correct one (a valid proof of a wrong spec is Critical). Invoked by `formal-verification` skill |
| `full-project-reviewer` | opus | Holistic audit: code quality, security, reliability, performance + global non-negotiables gate |
| `language-expert-reviewer` | opus | Language-veteran review across 9 dimensions centered on behavioral correctness, invariant integrity, and language fit — not feature checklists. Supports C++, Rust, Python, TypeScript, Go, Java. |
| `sequence-diagram-reviewer` | opus | Sequence diagram quality gate — validates flow coverage (auth flows, error paths, async patterns), error path per external call, arrow type correctness (sync vs async), auth boundary placement, HLD participant alignment. 5 dimensions. Invoked by `sequence-diagram` skill. |
| `business-context-reviewer` | opus | Business context quality gate — validates problem statement is user-focused (not solution-framed), JTBD statement is complete, success metrics are measurable with baselines, compliance is explicitly addressed, non-goals present, stakeholders mapped, internal consistency. 6 dimensions. Invoked by `business-context-intake` skill. |
| `hld-reviewer` | opus | Pre-human HLD quality gate — validates C4 diagrams, technology selection, STRIDE threat model, failure modes, capacity planning, ADR completeness, spec coverage, and AWS Well-Architected alignment. Invoked by `high-level-design` skill before human review. |
| `spec-quality-reviewer` | opus | Spec quality gate — validates falsifiability, TC coverage, TC honesty, error path ownership, consistency, dependency declaration, and an ISO/IEC/IEEE 29148 requirements-smell lint (individual + set characteristics; Femmer/Smella trigger-word detectors, singularity) against SQLite/RFC 8446/DO-178C standards. Invoked by `spec-quality-gate` skill. |
| `plan-reviewer` | opus | Implementation plan quality gate — validates spec coverage, task granularity (incl. Right-Sizing), Karpathy anti-patterns, placeholder detection, type/interface + Interfaces-block chain consistency, design principle compliance, Global Constraints section presence, and commit discipline. Invoked by `writing-plans` skill before execution handoff. |
| `portfolio-reviewer` | opus | Portfolio Kanban quality gate — WSJF computed from cost-of-delay components (not gut-ranked), every non-Funnel state within its WIP limit (Little's Law), `depends_on` a valid DAG with no cycles, each epic links an OKR, pull order respects WSJF and dependencies. Invoked by `portfolio-management` skill. |
| `ci-reviewer` | opus | CI/CD pipeline quality gate — validates stage completeness, fail-fast ordering, security hygiene, supply-chain integrity (SLSA L2+ provenance, SBOM, and slopsquatting/dependency-existence defense for AI-suggested deps), coverage gate, mutation-testing gate, artifact immutability, environment gates, DORA readiness, and branch protection alignment. Platform-agnostic: GitHub Actions, GitLab CI, Jenkins, CircleCI, Azure DevOps, Bitbucket. Invoked by `ci-pipeline-setup` skill. |
| `observability-reviewer` | opus | Observability quality gate — validates OTel logging compliance (6 mandatory fields), golden signal coverage (all 4 signals), SLO quality vs spec NFRs, alert design (symptom-based, burn rate), runbook completeness (7 required sections), distributed tracing, SLO-to-alert alignment. Invoked by `observability-standards` skill. |
| `deployment-reviewer` | opus | Deployment quality gate — validates rollback procedure (7 sections, tested), DB migration safety (expand-contract pattern, dangerous patterns), smoke test coverage, deployment runbook, release notes quality (Keep a Changelog format), strategy-migration alignment. Invoked by `deployment-workflow` skill. |
| `integration-test-reviewer` | opus | Integration test quality gate — validates no mocks at boundary (cardinal rule), test isolation (transaction rollback), factory pattern, Testcontainers config (pinned versions, dynamic ports), spec AC coverage, contract tests (Pact), CI integration. 7 dimensions. Invoked by `integration-testing` skill. |
| `api-contract-reviewer` | opus | API contract quality gate — validates OpenAPI 3.1 or .proto completeness, error taxonomy, security definitions, breaking change safety, schema quality (money as float = Critical), REQ-NNN coverage, naming conventions. 7 dimensions. Invoked by `api-contract-first` skill. |
| `feature-flag-reviewer` | **sonnet** | Feature flag quality gate — naming conventions (type prefix, lowercase-hyphen), registry completeness (owner, expiry, rollout %), CI hygiene check blocks expired flags, no hardcoded true defaults on temporary flags, cleanup queue maintained. 5 dimensions. Invoked by `feature-flags` skill. |
| `service-scaffolding-reviewer` | **sonnet** | Golden-path scaffold completeness gate — mechanically checks every paved-road component exists (CI, observability, API contract stub, tests, runbook, resource limits set not unbounded, infra as a curated golden-path module call not bespoke HCL, catalog entry with owner, scorecard). Deterministic file-presence checks. Invoked by `service-scaffolding` skill. |
| `iac-reviewer` | **sonnet** | IaC configuration gate — provider versions pinned, remote state with locking, sensitive variables marked, environment separation, security scan (tfsec/checkov) in CI, no secrets in code. 6 dimensions. Invoked by `infrastructure-as-code` skill. |
| `database-erd-reviewer` | **sonnet** | Database ERD quality gate — all entities have PK, FK references valid, cardinality with crow's foot notation, no money as float, index strategy documented, design decisions explained. 6 dimensions. Invoked by `database-erd` skill. |
| `visual-regression-reviewer` | **sonnet** | Visual regression test gate — screenshots on critical pages, animations disabled, baselines committed to git, dynamic content masked, CI uses pinned Docker image. 5 dimensions. Invoked by `visual-regression` skill. |
| `chaos-reviewer` | **sonnet** | Chaos + deterministic-simulation test gate — steady state + hypothesis defined, scenarios match HLD failure modes, thresholds allow graceful degradation (not zero failures), abort criteria present, CI on staging only, seed reproducibility for simulation artifacts. 6 dimensions. Invoked by `chaos-engineering` and `deterministic-simulation-testing` skills. |
| `incident-response-reviewer` | **sonnet** | Incident response docs gate — severity matrix (3 levels, SLAs), IC role documented, postmortem template has 7 required sections, MTTD/MTTR targets, communication templates, action-item closure loop (tracked tickets + closure review, not just a table), DiRT/game-day drill cadence. Invoked by `incident-response` skill. |
| `production-readiness-reviewer` | opus | Production readiness gate — validates the PRR covers the SRE Launch Coordination Checklist's seven dimensions and, critically, that each readiness claim is *evidenced* not plausibly restated (tested rollback linked, SLO/capacity numbers sourced, dependencies verified to exist, runbooks exercised); flags AI-plausible-but-unverified readiness. Advisory to the human go/no-go. Invoked by `production-readiness-review` skill. |
| `onboarding-reviewer` | opus | Onboarding guide quality gate — validates 8 required sections, dev setup has executable commands with verification steps, C4 Container diagram present, ADRs referenced with daily-impact explanations, first contribution path covers harness workflow, ops section actionable. Invoked by `onboarding-guide` skill. |
| `outcome-review-reviewer` | opus | Post-launch outcome quality gate — every promised metric present (no cherry-picking), every realized value cites a re-runnable source (fabricated-number = Critical), no metric failed before its HEART-aligned earliest read (premature-failure guard), unmeasurable metrics routed to instrumentation not guessed, persevere/iterate/kill follows the evidence. Invoked by `outcome-review` skill. |
| `dast-reviewer` | **sonnet** | DAST configuration gate — validates ZAP baseline on PRs, API scan on staging with OpenAPI spec, HIGH findings fail CI, SARIF uploaded, authentication configured. 5 dimensions. Invoked by `dast-testing` skill. |
| `accessibility-reviewer` | **sonnet** | Accessibility test gate — validates axe-playwright present on critical pages, correct WCAG tags (wcag21aa, wcag22aa for EU), violations fail CI (not just logged), exclusions documented. 4 dimensions. Invoked by `e2e-testing` skill. |
| `e2e-reviewer` | opus | E2E test quality gate — validates critical journey coverage, semantic selectors (CSS class selectors = Critical), no hardcoded waits (waitForTimeout = Critical), test independence, POM structure, auth fixtures, CI integration against staging. 7 dimensions. Invoked by `e2e-testing` skill. |
| `load-test-reviewer` | opus | Load test quality gate — validates NFR-aligned thresholds (arbitrary numbers = Critical), smoke test presence, realistic traffic modeling, appropriate test types (no soak for 99.9% availability = Critical), CI integration against staging (localhost = Critical), script quality. 6 dimensions. Invoked by `load-testing` skill. |
| `linter-reviewer` | **sonnet** | Linter gate validator — detects language from manifests, verifies correct 2025 tool used (Ruff/Biome/golangci-lint/Clippy), confirms zero output, type checker run, no new suppression comments. 4 checks. Invoked by `verification-before-completion`. First Sonnet review agent. |
| `delivery-metrics-reviewer` | **sonnet** | Delivery-metrics honesty gate — DORA bands match the 2024 clusters, no failure-dependent key (lead time/CFR/MTTR/reliability) fabricated when its signal is absent, flow efficiency formula-correct or withheld, every key cites its source, no delivery metric sold as a business outcome. 5 checks. Invoked by `delivery-metrics` skill. |

Code review agents (`pr-reviewer`, `security-reviewer`, `spec-impl-reviewer`, `test-quality-reviewer`, `full-project-reviewer`, `language-expert-reviewer`) require `BASE_SHA` and `HEAD_SHA` (and usually `SPEC_PATH`). `pr-reviewer` and `spec-impl-reviewer` accept optional `DIFF_FILE` (pre-generated by `scripts/review-package PLAN_FILE BASE HEAD`) — if present, the agent reads it instead of running git commands. `pr-reviewer` also accepts optional `PR_NUMBER` (read existing review threads via `gh` to flag adverse prior advice and amplify sound suggestions) and `REVIEW_POLICY` (repo review-policy file; auto-checks `.ai/review-policy.md` then repo-root `review-policy.md`) — both portable, `gh`/file-read only, no code-index dependency.
All reviewer agents accept optional `REPORT_FILE` — if present, full findings are written there and only the verdict summary is returned to context.
Formal-verification agents (`formal-verification-reviewer`) require `VERDICT_PATH` and `SOURCE_PATH`; `SPEC_PATH` optional.
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
Production readiness agents (`production-readiness-reviewer`) require `PRR_PATH`; `SLO_PATH`, `ROLLBACK_PATH`, and `SPEC_PATH` optional.
Portfolio agents (`portfolio-reviewer`) require `PORTFOLIO_PATH`; `WIP_LIMIT` optional.
Service scaffolding agents (`service-scaffolding-reviewer`) require `SCAFFOLD_DIR`; `CATALOG_PATH` and `SCORECARD_PATH` optional.
Onboarding agents (`onboarding-reviewer`) require `ONBOARDING_PATH`; `HLD_PATH` and `SPEC_PATH` optional.
Outcome review agents (`outcome-review-reviewer`) require `OUTCOME_PATH` and `CONTEXT_PATH`.
DAST agents (`dast-reviewer`) require `CI_CONFIG_PATH`; `OPENAPI_PATH` and `ZAP_RULES_PATH` optional.
Accessibility agents (`accessibility-reviewer`) require `TEST_FILES`; `SPEC_PATH` and `BUSINESS_CONTEXT_PATH` optional.
Linter agents (`linter-reviewer`) require `PROJECT_ROOT` and `CHANGED_FILES`.
Delivery-metrics agents (`delivery-metrics-reviewer`) require `REPORT_PATH`; `LEDGER_PATH` optional.
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
| `formal-verification-reviewer` | opus | High — spec-correctness judgment ("is this the right contract, or a vacuous/over-strong one?"), guarantee-vs-tool-output reasoning (bounded vs unbounded), detecting silently-discharged obligations. A cheaper model would rubber-stamp a proof of a wrong spec | ✅ Correct |
| `full-project-reviewer` | opus | High — cross-file coherence, architectural pattern reasoning | ✅ Correct |
| `language-expert-reviewer` | opus | High — language-standard nuances, UB, ownership, unsafe invariants | ✅ Correct |
| `business-context-reviewer` | opus | High — product judgment ("is this solution-framed?"), metric measurability assessment, JTBD completeness, internal consistency across problem/metric/non-goals | ✅ Correct |
| `hld-reviewer` | opus | High — architecture quality judgment, threat model adequacy, ADR reasoning quality | ✅ Correct |
| `spec-quality-reviewer` | opus | High — falsifiability judgment, TC honesty ("would a wrong impl pass this?") | ✅ Correct (Sonnet handles format checks; Opus needed for quality checks 2a-2d) |
| `plan-reviewer` | opus | Medium-high — Karpathy anti-pattern judgment, YAGNI/SOLID violations, type consistency tracking | ✅ Correct |
| `portfolio-reviewer` | opus | High — distinguishing genuine WSJF economic sequencing from gut-ranking, and judging whether a WIP-limit breach is a real capacity call or AI-throughput rationalization, is reasoning a checklist-matcher would miss | ✅ Correct |
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
| `service-scaffolding-reviewer` | sonnet | Mechanical — is each paved-road component present? (file-presence checks: CI config, SLO stub, contract stub, tests, runbook, resource limits, catalog entry, scorecard). Deterministic given the scaffold; no architecture judgment | ✅ Correct — Sonnet |
| `database-erd-reviewer` | sonnet | Mechanical — PK annotation present? (scan), FK references valid? (cross-check), cardinality notation? (symbol match), money as float? (field name + type scan) | ✅ Correct — Sonnet |
| `visual-regression-reviewer` | sonnet | Mechanical — toHaveScreenshot present? (pattern), animations disabled? (config check), snapshots in git? (.gitignore check), Docker pinned? (image tag check) | ✅ Correct — Sonnet |
| `chaos-reviewer` | sonnet | Mechanical — hypothesis present? (comment pattern), threshold allows failures? (number check), abort criteria? (documentation check), CI target? (URL pattern), seed reproducibility for DST artifacts? (pattern match) | ✅ Correct — Sonnet |
| `incident-response-reviewer` | sonnet | Mechanical — severity levels present? (count check), SLAs are numbers not prose? (format check), 7 postmortem sections present? (section count), MTTD/MTTR defined? (pattern match) | ✅ Correct — Sonnet |
| `onboarding-reviewer` | opus | High — "could a new engineer be productive in one day?" requires genuine newcomer perspective, narrative clarity judgment, cross-checking diagrams against HLD for staleness | ✅ Correct |
| `outcome-review-reviewer` | opus | High — "is this realized number measured or fabricated?" is the same evidence-vs-plausible-prose judgment as the PRR reviewer, and "flat but too-early vs genuinely failed" requires reasoning about HEART metric timelines a checklist-matcher would miss | ✅ Correct |
| `production-readiness-reviewer` | opus | High — "is this claim evidenced or just plausibly written?" is judgment work, especially on AI-authored PRRs; distinguishing a sourced SLO from a guessed one and a real dependency from a hallucinated one requires reasoning a checklist-matcher would miss | ✅ Correct |
| `dast-reviewer` | sonnet | Mechanical — ZAP action present? (pattern match), fail_action set? (config check), SARIF upload present? (step detection), auth configured? (secret reference check) | ✅ Correct — Sonnet |
| `accessibility-reviewer` | sonnet | Mechanical — is axe called? (pattern match), correct tags? (set comparison), assertion pattern? (code pattern), exclusion comments? (text search). No accessibility judgment required. | ✅ Correct — Sonnet |
| `linter-reviewer` | sonnet | Mechanical — tool detection via manifest pattern matching, output-clean check is deterministic, suppression scan is regex. No architectural judgment required. First Sonnet review agent. | ✅ Correct |
| `delivery-metrics-reviewer` | sonnet | Mechanical — band label vs 2024 DORA cluster (table lookup), fabricated-key detection (number present with no ledger/incident row = deterministic cross-check), flow-efficiency formula/withhold check, source-citation presence, delivery-vs-outcome keyword scan. No performance judgment. | ✅ Correct — Sonnet |

**When adding a new agent:** fill in the right-size verdict before merging. An agent created as `model: opus` without a rationale entry here is flagged for review.

---

## Metrics vocabulary: delivery metric ≠ business north-star

The harness measures two different things, and conflating them is a documented failure mode. Every skill and agent that touches a metric must respect this split:

| Aspect | **Delivery / operational metric** | **Business north-star** |
|---|---|---|
| Question | How fast and how reliably do we ship? | Did the shipped thing move the outcome it was justified by? |
| Examples | DORA four keys, flow efficiency, SLO/error budget, p99 latency, MTTD/MTTR, uptime | weekly active creators, activation rate, paid conversion, tickets deflected |
| Framework | DORA (dora.dev), Flow Framework | North Star Metric (Amplitude/Sean Ellis), HEART/GSM (Google) |
| Owned by | `delivery-metrics`, `observability-standards`, `ci-pipeline-setup`, `deployment-workflow`, `incident-response` | `business-context-intake` (defines) → spec `north_star` → `outcome-review` (measures) |

A delivery metric is a **guardrail**, not the needle. "Deployment frequency is elite" or "p99 is under target" says the machine runs well — it does **not** say the feature succeeded. That question belongs to `outcome-review` against the business north-star. A skill that presents a DORA/SLO number as evidence of business success has confused the layers; `delivery-metrics-reviewer` (D5) and `spec-quality-reviewer` (§2f) both reject that confusion.

---

## External skills loaded at install time

These are installed via `scripts/install-claude.sh` and available alongside this plugin.

| Source | What it adds |
|--------|-------------|
| `pbakaus/impeccable` | UI quality review |
| `emilkowalski/skill` | Frontend component patterns |
| `Leonxlnx/taste-skill` | Visual taste heuristics |
| Android skill pack (step 16) | Kotlin/Compose/KMP: `chrisbanes/skills`, `skydoves/android-testing-skills`, `skydoves/compose-performance-skills`, `rcosteira79/android-skills`, `new-silvermoon/awesome-android-agent-skills`, `aldefy/compose-skill`, `hamen/compose_skill`, `Meet-Miyani/compose-skill`, `Drjacky/claude-android-ninja`, `ceorkm/mobile-app-ui-design`, `jimliu/baoyu-skills` — overlapping by design; the `android-advisor` overlay resolves precedence per sub-task |

> `mukul975/Anthropic-Cybersecurity-Skills` (754 skills) is commented out in `scripts/install-claude.sh` — uncomment to enable.

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

Version lives in `.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`, and `.codex-plugin/plugin.json`.

| Change | Bump |
|--------|------|
| Typo, description tweak, prompt fix | patch |
| New skill or agent | minor |
| Structural change (manifest format, breaking rename) | major |

Always bump all three before committing a skill/agent change. Claude Code then
uses `/reload-plugins`; Codex reinstalls the local plugin and starts a new
session.
