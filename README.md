# private-ai-harness

Personal Claude Code + Codex harness. One shared skill tree, full stack:
Karpathy guidelines, commit discipline, parallel agent patterns, TDD
workflows, systematic debugging, code review, and caveman mode.

Not a product. Optimized for one workflow.

---

## What's inside

| Directory | Contents |
|-----------|----------|
| `skills/` | Shared skills loaded into Claude Code and Codex |
| `agents/` | Canonical reviewer prompts used directly by Claude and adapted to Codex custom agents |
| `scripts/` | Shared installer, Codex installer/adapter, and `commit-msg.sh` hook |
| `.claude-plugin/` | Claude Code manifest and local marketplace |
| `.codex-plugin/` | Native Codex plugin manifest |

### Skills

Use `/<name>` in Claude Code. In Codex, mention `$<name>` or choose the skill
from `/skills`; installed plugin UIs may show the `private-ai-harness:` prefix.

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `android-advisor` | `/android-advisor` | First `domain-overlay` instance — routes overlapping installed Android/Kotlin/Compose/KMP global skills to a single winner per sub-task with a stated tie-break reason; activated by engineer on Android work |
| `brainstorming` | `/brainstorming` | Explore intent before implementing |
| `business-context-intake` | `/business-context-intake` | Before brainstorming — captures user problem, JTBD, measurable success metrics, compliance constraints, non-goals; hard gate before design |
| `caveman` | `/caveman` | 75% token reduction, full technical accuracy |
| `code-documentation` | `/code-documentation` | Spec-traceable docs at authorship time |
| `commit-discipline` | `/commit-discipline` | Conventional Commits + micro-commit rules |
| `design-principles` | `/design-principles` | DRY, KISS, YAGNI, SOLID, GoF patterns — planning and review lens |
| `dispatching-parallel-agents` | `/dispatching-parallel-agents` | Parallel agent patterns for independent tasks |
| `domain-overlay` | `/domain-overlay` | Pattern for a precedence+ordering layer over overlapping externally-installed global skills in one tech domain; engineer activates the matching `<domain>-advisor` inside each construct/test/verify step |
| `executing-plans` | `/executing-plans` | Structured plan execution with checkpoints |
| `finishing-a-development-branch` | `/finishing-a-development-branch` | Pre-merge checklist |
| `ci-pipeline-setup` | `/ci-pipeline-setup` | After worktree creation — platform-agnostic pipeline spec + config for GitHub Actions/GitLab CI/Jenkins/CircleCI/Azure DevOps/Bitbucket |
| `deployment-workflow` | `/deployment-workflow` | Before PR deployment-ready — deployment strategy, zero-downtime migration checklist, rollback procedure, smoke tests, release notes |
| `api-contract-first` | `/api-contract-first` | Before any handler/gRPC implementation — OpenAPI 3.1 or .proto spec, Spectral linting, Prism mock server, CI lint job; hard gate before handler code |
| `e2e-testing` | `/e2e-testing` | Before finishing a user-facing feature — Playwright POM + auth fixtures + semantic locators + CI post-deploy E2E job against staging |
| `load-testing` | `/load-testing` | Before finishing a feature with NFR targets — k6 smoke/load/stress/spike/soak scripts with thresholds tied to spec NFRs, CI performance job |
| `integration-testing` | `/integration-testing` | During TDD GREEN for components with external I/O — Testcontainers (real DB/queue/cache), transaction rollback isolation, factory pattern, Pact contract tests |
| `observability-standards` | `/observability-standards` | After first API endpoint — OTel structured logging, golden signal metrics, SLO doc, alert rules, per-alert runbooks |
| `github-workflows` | `/github-workflows` | GH Actions and PR workflow patterns |
| `high-level-design` | `/high-level-design` | After spec-quality-gate — C4 diagrams, tech selection, STRIDE threat model, failure modes, capacity planning, ADRs |
| `karpathy` | `/karpathy` | Anti-LLM-coding-pitfall guidelines |
| `pr-creator` | `/pr-creator` | Draft and open PRs with compliant messages |
| `prefer-deterministic-over-ai` | `/prefer-deterministic-over-ai` | Reach for grep/ast before LLM |
| `giving-code-review` | `/giving-code-review` | Act as reviewer via `gh` on someone else's PR, or self-review your own first — doubled rigor + trust-but-verify in self-review mode |
| `receiving-code-review` | `/receiving-code-review` | How to act on review feedback |
| `requesting-code-review` | `/requesting-code-review` | How to request a review |
| `review` | `/review` | Multi-dimension code review |
| `feature-flags` | `/feature-flags` | For gradual rollout/A/B test/kill switch — OpenFeature SDK, naming conventions, flag registry, CI hygiene |
| `infrastructure-as-code` | `/infrastructure-as-code` | When feature needs new infrastructure — Terraform/Pulumi with pinned versions, remote state, environment separation, tfsec CI |
| `database-erd` | `/database-erd` | During HLD or writing-plans for DB changes — Mermaid erDiagram with entities, FKs, cardinality, index strategy |
| `visual-regression` | `/visual-regression` | For UI features — Playwright toHaveScreenshot(), animations disabled, baselines in git, pinned Docker CI |
| `chaos-engineering` | `/chaos-engineering` | For resilience NFR services — k6 fault injection, Toxiproxy network faults, steady state hypothesis, CI chaos job |
| `incident-response` | `/incident-response` | For production services — severity matrix, IC role, postmortem template (Google SRE standard), MTTD/MTTR targets |
| `delivery-metrics` | `/delivery-metrics` | Score the harness's own delivery — DORA four keys + reliability and Flow Framework flow efficiency, derived from manifest phase timestamps + cost-ledger; never fabricates failure-dependent keys; runs `delivery-metrics-reviewer` |
| `onboarding-guide` | `/onboarding-guide` | On first production release — synthesizes HLD, ADRs, OpenAPI, SLOs into wiki/ONBOARDING.md with 8 required sections |
| `outcome-review` | `/outcome-review` | After ship (and at HEART-aligned checkpoints) — measures north-star + input metrics vs target with cited sources, renders persevere/iterate/kill, feeds the portfolio; rejects fabricated numbers; closes the measurement loop |
| `dast-testing` | `/dast-testing` | DAST for externally-facing services — ZAP baseline (PRs), API scan (staging), Nuclei, SARIF to Security tab, fails on HIGH |
| `api-versioning` | `/api-versioning` | For externally-facing APIs — versioning strategy ADR, breaking change policy, Sunset headers, migration guide template, CI oasdiff breaking change detection |
| `sequence-diagram` | `/sequence-diagram` | During HLD §5 or writing-plans for 3+ component flows — Mermaid sequenceDiagram with auth, error paths, sync/async, retry; runs `sequence-diagram-reviewer` |
| `portfolio-management` | `/portfolio-management` | Layer above one epic — SAFe Portfolio Kanban, WSJF ranking, WIP limits (Little's Law), cross-epic dependency DAG, OKR linkage; the engineer PORTFOLIO lane; runs `portfolio-reviewer` |
| `service-scaffolding` | `/service-scaffolding` | Golden-path scaffold for a NEW service (CNCF Platform Eng L3) — CI, observability, contract stub, tests, runbook, resource limits, catalog entry, scorecard from birth; runs `service-scaffolding-reviewer` |
| `spec-quality-gate` | `/spec-quality-gate` | Gate on spec completeness before coding — zero-cost `pre-lint.sh` format check (incl. required `north_star` field) runs before the Opus reviewer |
| `subagent-driven-development` | `/subagent-driven-development` | Orchestrate subagents for implementation |
| `systematic-debugging` | `/systematic-debugging` | Scientific debugging with condition-based waiting |
| `test-driven-development` | `/test-driven-development` | Red-green-refactor TDD loop |
| `using-git-worktrees` | `/using-git-worktrees` | Parallel branches without stash churn |
| `using-superpowers` | `/using-superpowers` | Leverage MCP tools effectively |
| `verification-before-completion` | `/verification-before-completion` | Verify before marking done |
| `workflow` | `/workflow` | Full feature development pipeline |
| `writing-plans` | `/writing-plans` | Plan documents that agents can execute |
| `writing-skills` | `/writing-skills` | Author new skills |

### Agents

Claude Code exposes agents as `private-ai-harness:<name>`. The Codex installer
generates equivalent `private-ai-harness-<name>` custom agents from the same
Markdown definitions, so reviewer prompts do not drift between hosts.

| Agent | Purpose |
|-------|---------|
| `pr-reviewer` | PR review across code, security, design, completeness |
| `security-reviewer` | Threat modeling, attack surface, auth/authz chains |
| `spec-impl-reviewer` | Verify implementation satisfies each REQ statement |
| `test-quality-reviewer` | Verify tests are meaningful, not just annotated |
| `full-project-reviewer` | Holistic audit across quality, security, reliability, performance |
| `language-expert-reviewer` | Language-veteran review: type system, UB, ownership, idioms, concurrency, error handling, stdlib, performance, standard compliance, safety — C++/Rust/Python/TS/Go/Java |
| `business-context-reviewer` | Business context quality gate — problem statement user-focused, JTBD complete, metrics measurable with baselines, compliance explicit, non-goals present, stakeholders mapped |
| `hld-reviewer` | Pre-human HLD quality gate — validates C4 diagrams, STRIDE threat model, failure modes, capacity planning, ADRs, spec coverage, AWS Well-Architected alignment |
| `spec-quality-reviewer` | Spec quality gate — falsifiability, TC coverage, TC honesty, error path ownership, consistency, dependency declaration, ISO 29148 requirements-smell lint (individual + set) against SQLite/RFC/DO-178C standards |
| `plan-reviewer` | Plan quality gate — spec coverage, task granularity, Karpathy anti-patterns, placeholder detection, type consistency, design principles, commit discipline |
| `portfolio-reviewer` | Portfolio Kanban gate — WSJF computed not gut-ranked, WIP limits respected (Little's Law), depends_on a valid DAG, OKR linkage, pull order respects WSJF + dependencies |
| `ci-reviewer` | CI/CD pipeline quality gate — stage completeness, fail-fast ordering, coverage gate, security hygiene, artifact immutability, DORA readiness. Platform-agnostic. |
| `observability-reviewer` | Observability quality gate — OTel logging compliance, golden signal coverage, SLO quality, alert design, runbook completeness, distributed tracing, SLO-to-alert alignment |
| `deployment-reviewer` | Deployment quality gate — rollback procedure, DB migration safety (expand-contract), smoke test coverage, deployment runbook, release notes, strategy-migration alignment |
| `integration-test-reviewer` | Integration test quality gate — no mocks at boundary, test isolation, factory pattern, Testcontainers config, spec AC coverage, contract tests, CI wiring |
| `api-contract-reviewer` | API contract quality gate — completeness, error taxonomy, security, breaking changes, schema quality (money-as-float Critical), REQ coverage, naming conventions |
| `e2e-reviewer` | E2E test quality gate — critical journey coverage, semantic selectors, no hardcoded waits, test independence, POM, auth fixtures, CI integration |
| `load-test-reviewer` | Load test quality gate — NFR-aligned thresholds, smoke test, realistic traffic, test type coverage (soak for availability NFRs), CI against staging |
| `feature-flag-reviewer` | **Sonnet** — Flag gate: naming conventions, registry completeness, CI expired-flag block, safe defaults, cleanup queue |
| `iac-reviewer` | **Sonnet** — IaC gate: versions pinned, remote state+locking, sensitive vars, env separation, tfsec/checkov scan, no secrets in code |
| `service-scaffolding-reviewer` | **Sonnet** — Scaffold completeness gate: CI, observability, contract stub, tests, runbook, resource limits (not unbounded), catalog entry with owner, scorecard all present |
| `database-erd-reviewer` | **Sonnet** — ERD gate: PKs present, FKs valid, crow's foot cardinality, no money-as-float, index strategy, design decisions |
| `visual-regression-reviewer` | **Sonnet** — VRT gate: screenshots on critical pages, animations off, baselines committed, dynamic content masked, pinned Docker CI |
| `chaos-reviewer` | **Sonnet** — Chaos test gate: steady state/hypothesis, scenarios match HLD, thresholds allow degradation, abort criteria, CI on staging |
| `incident-response-reviewer` | **Sonnet** — IR docs gate: severity matrix, IC role, 7-section postmortem, MTTD/MTTR, communication templates |
| `production-readiness-reviewer` | PRR gate — SRE Launch Coordination Checklist seven dimensions; accepts a readiness claim only when evidenced (tested rollback, sourced SLO, verified dependency, exercised runbook), not when plausibly written; flags AI-plausible-but-unverified readiness |
| `onboarding-reviewer` | Onboarding guide gate — 8 required sections, executable dev setup, C4 diagram, ADRs, contribution path, actionable ops section |
| `outcome-review-reviewer` | Post-launch outcome gate — every metric measured against a re-runnable source (fabricated = Critical), no premature failure before HEART horizon, decision follows evidence |
| `dast-reviewer` | **Sonnet** — DAST config gate: ZAP baseline on PRs, API scan on staging, HIGH fails CI, SARIF uploaded, auth configured |
| `accessibility-reviewer` | **Sonnet** — Accessibility gate: axe-playwright on critical pages, WCAG 2.1/2.2 AA tags, violations fail CI, exclusions documented |
| `linter-reviewer` | **Sonnet** — Linter gate validator: language detection, correct 2025 tool (Ruff/Biome/golangci-lint/Clippy), zero output, type checker, no new suppressions |
| `delivery-metrics-reviewer` | **Sonnet** — Delivery-metrics honesty gate: DORA bands match 2024 clusters, no fabricated failure-dependent key, flow efficiency formula-correct or withheld, every key cites its source, no delivery metric sold as a business outcome |

---

## Installation

### Prerequisites

| Dependency | Why |
|------------|-----|
| macOS | scripts assume `zsh`/`bash` |
| [Node.js](https://nodejs.org/) ≥ 18 | `npm`/`npx` for CodeGraph, Context7, claude-mem, skills |
| [Claude Code](https://claude.ai/code) CLI (`claude`) | plugin install, marketplace registration |
| [Codex](https://developers.openai.com/codex/) CLI (`codex`) | Codex plugin install and custom-agent dispatch |
| Python ≥ 3.11 | validates and renders Codex custom-agent TOML files |
| [GitHub CLI](https://cli.github.com/) (`gh`) | checking upstream skill repos for updates |

### Upstream skills to monitor for updates

These skills are sourced from external repos and may drift from the upstream originals.
Check them periodically with `gh` and sync if they've changed:

| Skill | Upstream | Check command |
|-------|----------|---------------|
| `skills/caveman/SKILL.md` | [emilkowalski/skill](https://github.com/emilkowalski/skill) | `gh repo view emilkowalski/skill` |
| `skills/using-superpowers/SKILL.md` | upstream superpowers skill | `gh search repos "claude superpowers skill"` |
| `skills/karpathy/SKILL.md` | [Karpathy guidelines](https://x.com/karpathy/status/2015883857489522876) | manual review |

### Install every detected host

```bash
bash scripts/install-tools.sh
```

This script installs (in order):

1. **RTK** — Rust Token Killer, token-optimized CLI proxy (`rtk init -g`)
2. **CodeGraph** — AST knowledge graph MCP server (`npm i -g @colbymchenry/codegraph`)
3. **Context7** — live library docs MCP (`npx ctx7 setup`)
4. **claude-mem** — persistent memory MCP (`npx claude-mem install`)
5. **Skills** — `impeccable`, `emilkowalski/skill`, `taste-skill` (`mukul975/Anthropic-Cybersecurity-Skills` is commented out — uncomment in `install-tools.sh` to enable)
6. **Claude plugins** — `code-review`, `code-simplifier`, `skill-creator`, `claude-md-management`, `security-guidance`
7. **LSP plugins** — `clangd-lsp`, `gopls-lsp`, `jdtls-lsp`, `kotlin-lsp`, `rust-analyzer-lsp`, `typescript-lsp`
8. **Understand-Anything** — multimodal analysis plugin (`Lum1104/Understand-Anything`)
9. **VoiceMode** — marketplace + plugin install
10. **This repo for Claude Code** — registers the harness as a local marketplace and installs it at user scope
11. **This repo for Codex** — registers the same local marketplace, installs the native Codex plugin, generates custom-agent TOML adapters, and synchronizes global Codex guidance
12. **Global Claude guidance** — caveman, commit discipline, workflow, and Karpathy blocks
13. **commit-msg hook** — symlinks `scripts/commit-msg.sh` into `.git/hooks/commit-msg`
14. **Android team skills** — Kotlin/Compose/KMP pack (chrisbanes, skydoves testing + performance, rcosteira79, new-silvermoon, aldefy, hamen, Meet-Miyani, Drjacky, ceorkm, baoyu); overlapping on purpose — the `android-advisor` overlay resolves which wins per sub-task

Host-specific steps are skipped when their CLI is not installed.

### Codex-only install

```bash
bash scripts/install-codex.sh
```

Pass `--no-global-guidance` to install only the plugin and custom agents. The
installer uses `$CODEX_HOME` when set, otherwise `~/.codex`, and keeps the
existing Claude agent files as the single source of truth.

After installation, start a new Codex session and open `/plugins`. Use `/agent`
to inspect reviewer agents.

### Claude Code manual steps

```
/voicemode:install    — install VoiceMode CLI, FFmpeg, voice services
/reload-plugins       — activate private-ai-harness skills + agents
```

Verify the plugin loaded:

```
/plugin list
```

### Install the commit-msg hook in another project

```bash
ln -sf /path/to/private-ai-harness/scripts/commit-msg.sh \
       /path/to/your-project/.git/hooks/commit-msg
```

---

## Philosophy

See [PHILOSOPHY.md](PHILOSOPHY.md). Short version: time from intent to done is the only metric.

---

## License

MIT
