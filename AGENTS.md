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
| `high-level-design` | `/high-level-design` | After spec-quality-gate passes — C4 diagrams, tech selection, STRIDE threat model, failure modes, capacity planning, ADRs. Runs `hld-reviewer` before human approval. |
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
| `language-expert-reviewer` | opus | Language-veteran review across 10 dimensions: type system, UB, ownership, idioms, concurrency, error handling, stdlib, performance, standard compliance, safety. Supports C++, Rust, Python, TypeScript, Go, Java. |
| `hld-reviewer` | opus | Pre-human HLD quality gate — validates C4 diagrams, technology selection, STRIDE threat model, failure modes, capacity planning, ADR completeness, spec coverage, and AWS Well-Architected alignment. Invoked by `high-level-design` skill before human review. |
| `spec-quality-reviewer` | opus | Spec quality gate — validates falsifiability, TC coverage, TC honesty, error path ownership, consistency, and dependency declaration against SQLite/RFC 8446/DO-178C standards. Invoked by `spec-quality-gate` skill. |
| `plan-reviewer` | opus | Implementation plan quality gate — validates spec coverage, task granularity, Karpathy anti-patterns, placeholder detection, type/interface consistency, design principle compliance, and commit discipline. Invoked by `writing-plans` skill before execution handoff. |

Code review agents (`pr-reviewer`, `security-reviewer`, `spec-impl-reviewer`, `test-quality-reviewer`, `full-project-reviewer`, `language-expert-reviewer`) require `BASE_SHA` and `HEAD_SHA` (and usually `SPEC_PATH`).
Design agents (`hld-reviewer`) require `HLD_PATH` and `SPEC_PATH`.
Spec agents (`spec-quality-reviewer`) require `SPEC_PATH`.
Plan agents (`plan-reviewer`) require `PLAN_PATH` and `SPEC_PATH`; `HLD_PATH` optional.
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
| `hld-reviewer` | opus | High — architecture quality judgment, threat model adequacy, ADR reasoning quality | ✅ Correct |
| `spec-quality-reviewer` | opus | High — falsifiability judgment, TC honesty ("would a wrong impl pass this?") | ✅ Correct (Sonnet handles format checks; Opus needed for quality checks 2a-2d) |
| `plan-reviewer` | opus | Medium-high — Karpathy anti-pattern judgment, YAGNI/SOLID violations, type consistency tracking | ✅ Correct |

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
