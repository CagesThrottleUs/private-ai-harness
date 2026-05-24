# private-ai-harness — project instructions

This repo is a Claude Code plugin: skills, agents, scripts, and philosophy docs.
No application code. No tests. No build step.

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
- **minor** — new skill or agent added
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

## Upstream skills to keep current

Three skills are sourced from external references and can drift. Check and sync periodically:

| File | Source | How to check |
|------|--------|-------------|
| `skills/caveman/SKILL.md` | [emilkowalski/skill](https://github.com/emilkowalski/skill) | `gh repo view emilkowalski/skill --web` |
| `skills/using-superpowers/SKILL.md` | upstream superpowers skill | `gh search repos "claude superpowers skill"` |
| `skills/karpathy/SKILL.md` | [Karpathy tweet](https://x.com/karpathy/status/2015883857489522876) + community distillations | `gh search repos "karpathy claude skill"` |

When upgrading: diff upstream against local, preserve any local customizations, bump patch version.

---

## What not to do

- Don't create application code, test files, or CI pipelines in this repo
- Don't add a build step — the plugin is loaded raw by Claude Code
- Don't flatten `skills/` — each skill must be its own subdirectory
- Don't modify `scripts/commit-msg.sh` without testing the hook: `printf 'test(x): subject\n\nbody' | bash scripts/commit-msg.sh /dev/stdin`
