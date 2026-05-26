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
| `caveman` | `/caveman` | Ultra-compressed comms, ~75% token reduction |
| `code-documentation` | `/code-documentation` | Writing or modifying any public construct |
| `commit-discipline` | `/commit-discipline` | Generating compliant commit messages |
| `design-principles` | `/design-principles` | DRY, KISS, YAGNI, SOLID, GoF patterns — planning and review lens |
| `dispatching-parallel-agents` | `/dispatching-parallel-agents` | 2+ independent tasks |
| `executing-plans` | `/executing-plans` | Running a `.ai/plans/` plan with checkpoints |
| `finishing-a-development-branch` | `/finishing-a-development-branch` | Pre-merge checklist |
| `github-workflows` | `/github-workflows` | GH Actions and PR workflow patterns |
| `karpathy` | `/karpathy` | Anti-LLM-pitfall coding guidelines |
| `pr-creator` | `/pr-creator` | Draft and open PRs |
| `prefer-deterministic-over-ai` | `/prefer-deterministic-over-ai` | Reach for grep/AST before LLM |
| `receiving-code-review` | `/receiving-code-review` | Acting on review feedback |
| `requesting-code-review` | `/requesting-code-review` | Requesting a review |
| `review` | `/review` | Central entry point for all review types |
| `spec-quality-gate` | `/spec-quality-gate` | Gate on spec completeness before coding |
| `subagent-driven-development` | `/subagent-driven-development` | Orchestrate subagents for implementation |
| `systematic-debugging` | `/systematic-debugging` | Scientific debugging |
| `test-driven-development` | `/test-driven-development` | Red-green-refactor TDD loop |
| `using-git-worktrees` | `/using-git-worktrees` | Parallel branches without stash churn |
| `using-superpowers` | `/using-superpowers` | How to find and invoke skills |
| `verification-before-completion` | `/verification-before-completion` | Verify before marking done |
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

All reviewer agents require `BASE_SHA` and `HEAD_SHA` (and usually `SPEC_PATH`).
See each `agents/<name>.md` for the full input contract.

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
