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
| `caveman` | `/caveman` | 75% token reduction, full technical accuracy |
| `code-documentation` | `/code-documentation` | Spec-traceable docs at authorship time |
| `commit-discipline` | `/commit-discipline` | Conventional Commits + micro-commit rules |
| `dispatching-parallel-agents` | `/dispatching-parallel-agents` | Parallel agent patterns for independent tasks |
| `executing-plans` | `/executing-plans` | Structured plan execution with checkpoints |
| `finishing-a-development-branch` | `/finishing-a-development-branch` | Pre-merge checklist |
| `github-workflows` | `/github-workflows` | GH Actions and PR workflow patterns |
| `karpathy` | `/karpathy` | Anti-LLM-coding-pitfall guidelines |
| `pr-creator` | `/pr-creator` | Draft and open PRs with compliant messages |
| `prefer-deterministic-over-ai` | `/prefer-deterministic-over-ai` | Reach for grep/ast before LLM |
| `receiving-code-review` | `/receiving-code-review` | How to act on review feedback |
| `requesting-code-review` | `/requesting-code-review` | How to request a review |
| `review` | `/review` | Multi-dimension code review |
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

---

## Installation

### Prerequisites

- macOS (scripts assume `zsh`/`bash`)
- [Node.js](https://nodejs.org/) ≥ 18 (for `npm`/`npx`)
- [Claude Code](https://claude.ai/code) CLI installed and authenticated

### One-command install

```bash
bash scripts/install-tools.sh
```

This script installs (in order):

1. **RTK** — Rust Token Killer, token-optimized CLI proxy (`rtk init -g`)
2. **CodeGraph** — AST knowledge graph MCP server (`npm i -g @colbymchenry/codegraph`)
3. **Context7** — live library docs MCP (`npx ctx7 setup`)
4. **claude-mem** — persistent memory MCP (`npx claude-mem install`)
5. **UI skills** — `impeccable`, `emilkowalski/skill`, `taste-skill` via `npx skills add`
6. **Claude plugins** — `code-review`, `code-simplifier`, `skill-creator`, `claude-md-management`, `security-guidance`
7. **VoiceMode** — marketplace + plugin install
8. **This repo as a plugin** — registers the harness as a local Claude marketplace and installs it at user scope
9. **commit-msg hook** — symlinks `scripts/commit-msg.sh` into `.git/hooks/commit-msg`

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
