# private-ai-harness

Personal Claude Code harness. One install, full stack: Karpathy guidelines, commit discipline, parallel agent patterns, TDD workflows, systematic debugging, code review, and caveman mode.

Not a product. Optimized for one workflow.

---

## What's inside

| Directory | Contents |
|-----------|----------|
| `skills/` | Slash-command skills loaded into Claude Code |
| `agents/` | Subagent definitions (pr-reviewer, security-reviewer, etc.) |
| `scripts/` | `install-tools.sh` and `commit-msg.sh` hook |

### Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `brainstorming` | `/brainstorming` | Explore intent before implementing |
| `business-context-intake` | `/business-context-intake` | Before brainstorming — captures user problem, JTBD, measurable success metrics, compliance constraints, non-goals; hard gate before design |
| `caveman` | `/caveman` | 75% token reduction, full technical accuracy |
| `code-documentation` | `/code-documentation` | Spec-traceable docs at authorship time |
| `commit-discipline` | `/commit-discipline` | Conventional Commits + micro-commit rules |
| `design-principles` | `/design-principles` | DRY, KISS, YAGNI, SOLID, GoF patterns — planning and review lens |
| `dispatching-parallel-agents` | `/dispatching-parallel-agents` | Parallel agent patterns for independent tasks |
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
| `receiving-code-review` | `/receiving-code-review` | How to act on review feedback |
| `requesting-code-review` | `/requesting-code-review` | How to request a review |
| `review` | `/review` | Multi-dimension code review |
| `onboarding-guide` | `/onboarding-guide` | On first production release — synthesizes HLD, ADRs, OpenAPI, SLOs into wiki/ONBOARDING.md with 8 required sections |
| `dast-testing` | `/dast-testing` | DAST for externally-facing services — ZAP baseline (PRs), API scan (staging), Nuclei, SARIF to Security tab, fails on HIGH |
| `api-versioning` | `/api-versioning` | For externally-facing APIs — versioning strategy ADR, breaking change policy, Sunset headers, migration guide template, CI oasdiff breaking change detection |
| `sequence-diagram` | `/sequence-diagram` | During HLD §5 or writing-plans for 3+ component flows — Mermaid sequenceDiagram with auth, error paths, sync/async, retry; runs `sequence-diagram-reviewer` |
| `spec-quality-gate` | `/spec-quality-gate` | Gate on spec completeness before coding |
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
| `spec-quality-reviewer` | Spec quality gate — falsifiability, TC coverage, TC honesty, error path ownership, consistency, dependency declaration against SQLite/RFC/DO-178C standards |
| `plan-reviewer` | Plan quality gate — spec coverage, task granularity, Karpathy anti-patterns, placeholder detection, type consistency, design principles, commit discipline |
| `ci-reviewer` | CI/CD pipeline quality gate — stage completeness, fail-fast ordering, coverage gate, security hygiene, artifact immutability, DORA readiness. Platform-agnostic. |
| `observability-reviewer` | Observability quality gate — OTel logging compliance, golden signal coverage, SLO quality, alert design, runbook completeness, distributed tracing, SLO-to-alert alignment |
| `deployment-reviewer` | Deployment quality gate — rollback procedure, DB migration safety (expand-contract), smoke test coverage, deployment runbook, release notes, strategy-migration alignment |
| `integration-test-reviewer` | Integration test quality gate — no mocks at boundary, test isolation, factory pattern, Testcontainers config, spec AC coverage, contract tests, CI wiring |
| `api-contract-reviewer` | API contract quality gate — completeness, error taxonomy, security, breaking changes, schema quality (money-as-float Critical), REQ coverage, naming conventions |
| `e2e-reviewer` | E2E test quality gate — critical journey coverage, semantic selectors, no hardcoded waits, test independence, POM, auth fixtures, CI integration |
| `load-test-reviewer` | Load test quality gate — NFR-aligned thresholds, smoke test, realistic traffic, test type coverage (soak for availability NFRs), CI against staging |
| `onboarding-reviewer` | Onboarding guide gate — 8 required sections, executable dev setup, C4 diagram, ADRs, contribution path, actionable ops section |
| `dast-reviewer` | **Sonnet** — DAST config gate: ZAP baseline on PRs, API scan on staging, HIGH fails CI, SARIF uploaded, auth configured |
| `accessibility-reviewer` | **Sonnet** — Accessibility gate: axe-playwright on critical pages, WCAG 2.1/2.2 AA tags, violations fail CI, exclusions documented |
| `linter-reviewer` | **Sonnet** — Linter gate validator: language detection, correct 2025 tool (Ruff/Biome/golangci-lint/Clippy), zero output, type checker, no new suppressions |

---

## Installation

### Prerequisites

| Dependency | Why |
|------------|-----|
| macOS | scripts assume `zsh`/`bash` |
| [Node.js](https://nodejs.org/) ≥ 18 | `npm`/`npx` for CodeGraph, Context7, claude-mem, skills |
| [Claude Code](https://claude.ai/code) CLI (`claude`) | plugin install, marketplace registration |
| [GitHub CLI](https://cli.github.com/) (`gh`) | checking upstream skill repos for updates |

### Upstream skills to monitor for updates

These skills are sourced from external repos and may drift from the upstream originals.
Check them periodically with `gh` and sync if they've changed:

| Skill | Upstream | Check command |
|-------|----------|---------------|
| `skills/caveman/SKILL.md` | [emilkowalski/skill](https://github.com/emilkowalski/skill) | `gh repo view emilkowalski/skill` |
| `skills/using-superpowers/SKILL.md` | upstream superpowers skill | `gh search repos "claude superpowers skill"` |
| `skills/karpathy/SKILL.md` | [Karpathy guidelines](https://x.com/karpathy/status/2015883857489522876) | manual review |

### One-command install

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
10. **This repo as a plugin** — registers the harness as a local Claude marketplace and installs it at user scope
11. **commit-msg hook** — symlinks `scripts/commit-msg.sh` into `.git/hooks/commit-msg`

### Manual steps (run inside Claude Code after the script)

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
