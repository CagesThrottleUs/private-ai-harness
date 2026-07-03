# private-ai-harness — project instructions

This repo is a Claude Code plugin: skills, agents, scripts, and philosophy docs.
No application code. No tests. No build step.

@AGENTS.md

---

## Repo layout

```
skills/<name>/SKILL.md      skill definitions (frontmatter + prompt body)
agents/<name>.md            subagent definitions
scripts/install-tools.sh    one-shot environment setup
scripts/commit-msg.sh       conventional commits enforcement hook
.claude-plugin/plugin.json  plugin manifest
.claude-plugin/marketplace.json  local marketplace manifest
PHILOSOPHY.md               design rationale — read before changing structure
```

---

## Editing skills

Each skill lives in `skills/<name>/SKILL.md` with YAML frontmatter:

```yaml
---
name: <kebab-case>
description: >
  One sentence that tells Claude WHEN to invoke this skill automatically.
  This text is the trigger — be specific and actionable.
---
```

Body is the prompt Claude receives when the skill is invoked.

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

---

## Version bumping

Version is in `.claude-plugin/plugin.json` → `version` field (semver).

Bump rules:
- **patch** — fix a skill prompt, typo, description tweak
- **minor** — new skill or agent added; new auxiliary files in a skill directory (scripts, prompt templates) that add new capability
- **major** — structural change (manifest format, install flow, breaking rename)

Always bump version before committing a skill/agent change so Claude Code picks up the update on `/reload-plugins`.

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
| `skills/caveman/SKILL.md` | [emilkowalski/skill](https://github.com/emilkowalski/skill) | `gh repo view emilkowalski/skill --web` |
| `skills/using-superpowers/SKILL.md` | [obra/superpowers](https://github.com/obra/superpowers) — last synced v6.1.1 | `gh api repos/obra/superpowers/tags --jq '.[0].name'` |
| `skills/karpathy/SKILL.md` | [Karpathy tweet](https://x.com/karpathy/status/2015883857489522876) + community distillations | `gh search repos "karpathy claude skill"` |

When upgrading: diff upstream against local, preserve any local customizations, bump patch version.

---

## What not to do

- Don't create application code, test files, or CI pipelines in this repo
- Don't add a build step — the plugin is loaded raw by Claude Code
- Don't flatten `skills/` — each skill must be its own subdirectory
- Don't modify `scripts/commit-msg.sh` without testing the hook: `printf 'test(x): subject\n\nbody' | bash scripts/commit-msg.sh /dev/stdin`
