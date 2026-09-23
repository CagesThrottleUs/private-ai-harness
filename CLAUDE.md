# private-ai-harness — project instructions

This repo is a Claude Code, Codex, and GitHub Copilot plugin: shared skills,
canonical agent prompts, host adapters, scripts, and philosophy docs. No
application code. No tests. No build step.

@AGENTS.md

---

## Repo layout

```
skills/<name>/SKILL.md      skill definitions (frontmatter + prompt body)
agents/<name>.md            subagent definitions
scripts/install-claude.sh    one-shot environment setup (Claude Code)
scripts/install-codex.sh    Codex plugin + custom-agent + sound-notify installer
scripts/install-opencode.sh opencode installer (skills, Context7, sound plugin, agents, hooks)
scripts/install-copilot.sh  GitHub Copilot installer (skills symlink, agent-skill adapter, global instructions)
scripts/codex-notify.sh     Codex notify hook adapter → hook-beep.sh
scripts/copilot-notify.sh   Copilot CLI hooks adapter → hook-beep.sh
scripts/install-codex-agents.py  Markdown-to-Codex-agent adapter
scripts/install-opencode-agents.py Markdown-to-opencode-subagent adapter
scripts/install-copilot-agents.py  Markdown-to-Copilot-Agent-Skill adapter
scripts/commit-msg.sh       conventional commits enforcement hook
.claude-plugin/plugin.json  Claude Code plugin manifest
.claude-plugin/marketplace.json  Claude/local marketplace manifest
.codex-plugin/plugin.json   Codex plugin manifest
PHILOSOPHY.md               design rationale — read before changing structure
```

---

## Editing skills

Each skill lives in `skills/<name>/SKILL.md` with YAML frontmatter:

```yaml
---
name: <kebab-case>
description: >
  One sentence that tells an AI host WHEN to invoke this skill automatically.
  This text is the trigger — be specific and actionable.
---
```

Body is the prompt Claude Code or Codex receives when the skill is invoked.

Rules:
- `description` must answer "invoke this when…" — vague descriptions kill auto-trigger
- Keep body focused — one skill, one responsibility
- Auxiliary files (examples, prompts, references) go in `skills/<name>/` alongside SKILL.md
- Do not nest skills inside other skill directories

---

## Editing agents

Agents live in `agents/<name>.md`. Frontmatter controls model routing and tool access:

```yaml
---
name: <name>
description: <one-line purpose>
model: opus   # or sonnet, haiku
---
```

These Markdown files are the source of truth. Do not hand-maintain duplicate
Codex or opencode prompts. `scripts/install-codex-agents.py` generates Codex
TOML agents, mapping Opus/Sonnet/Haiku to high/medium/low reasoning while
inheriting the active Codex model. `scripts/install-opencode-agents.py`
generates opencode subagents (`mode: subagent`, no `model`), so opencode
agents inherit the invoking primary agent's model and permissions.

---

## Metrics vocabulary

A **delivery metric** (DORA, flow efficiency, SLO, latency, MTTR) answers "how
fast and how reliably do we ship" — a guardrail. A **business north-star**
(activation, conversion, active users) answers "did the shipped thing move the
outcome it was justified by." They are different layers; presenting a delivery
number as evidence of business success is a documented failure mode. The
canonical definition and ownership map live in `AGENTS.md` → *Metrics
vocabulary*. When writing or reviewing any skill/agent that touches a metric,
keep the two apart: `outcome-review` owns the north-star, `delivery-metrics`
owns the delivery keys.

---

## Version bumping

Version is synchronized across `.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`, and `.codex-plugin/plugin.json`.

Bump rules:
- **patch** — fix a skill prompt, typo, description tweak
- **minor** — new skill or agent added; new auxiliary files in a skill directory (scripts, prompt templates) that add new capability
- **major** — structural change (manifest format, install flow, breaking rename)

Always bump every manifest version before committing a skill/agent change so
Claude Code picks it up on `/reload-plugins` and Codex picks it up after local
plugin reinstall plus a new session.

---

## Commit discipline

Enforced by `scripts/commit-msg.sh` (installed as `.git/hooks/commit-msg`).

```
type(scope): imperative summary   ← ≤50 chars aim, ≤72 hard
<blank line>
WHY body — required when >1 file staged
```

Types: `feat` `fix` `docs` `refactor` `chore`
Scopes: `skills` `agents` `scripts` `plugin` `docs`

---

## PR Review Protocol

A session that opens on an already-open PR — answering bot comments (Talos,
CodeRabbit), a queued human review, or "address the review" — is **re-entering**
work, not starting fresh. Before the first fix:

- Invoke `closing-review-loops` explicitly. Its step 0 (MEASURE) asks "is
  this still one describable change?" — run it even if you don't yet know
  the branch's full history, because a branch can drift through many
  individually-small rounds that never re-trigger a first-submission-only
  gate.
- Never fix comment-by-comment. Batch every open finding, fix in one pass,
  run an internal self-review, push once, then re-trigger the external
  reviewer — the Iron Law in `closing-review-loops`.

This binds in every repo the harness touches, not just this one.

---

## Meta-doc sync rule

`AGENTS.md`, `CLAUDE.md`, and `README.md` are a synchronized triple.
Any change to skills, agents, install steps, or plugin structure must update all three in the same commit.

| Change | Must update |
|--------|-------------|
| New or renamed skill | `AGENTS.md` skill table, `README.md` skill table |
| New or changed agent | `AGENTS.md` agent table, `README.md` agent table |
| New install step | `README.md` install list, `AGENTS.md` external skills (if applicable) |
| Version bump rule change | `AGENTS.md` version bump table, `CLAUDE.md` version bump section |
| Upstream skill change | `AGENTS.md` upstream section, `CLAUDE.md` upstream section |
| New workflow rule | `CLAUDE.md` rules section |

---

## Upstream skills to keep current

Three skills are sourced from external references and can drift. Check and sync periodically:

| File | Source | How to check |
|------|--------|-------------|
| `skills/caveman/SKILL.md` | [emilkowalski/skill](https://github.com/emilkowalski/skill) | `gh repo view JuliusBrussee/caveman --web` |
| `skills/using-superpowers/SKILL.md` | [obra/superpowers](https://github.com/obra/superpowers) — reviewed against v6.4.1 (Muse/Pi/Antigravity host refs skipped as unsupported; v6.4.1 concepts integrated into writing-plans, test-driven-development, pr-reviewer, subagent-driven-development) | `gh api repos/obra/superpowers/tags --jq '.[0].name'` |
| `skills/karpathy/SKILL.md` | [Karpathy tweet](https://x.com/karpathy/status/2015883857489522876) + community distillations | `gh search repos "karpathy claude skill"` |

When upgrading: diff upstream against local, preserve any local customizations, bump patch version.

---

## What not to do

- Don't create application code, test files, or CI pipelines in this repo
- Don't add a build step — the plugin is loaded raw by Claude Code and Codex
- Don't flatten `skills/` — each skill must be its own subdirectory
- Don't modify `scripts/commit-msg.sh` without testing the hook: `printf 'test(x): subject\n\nbody' | bash scripts/commit-msg.sh /dev/stdin`
