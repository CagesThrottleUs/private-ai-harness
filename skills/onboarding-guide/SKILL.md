---
name: onboarding-guide
description: >
  Use when a project reaches its first production release or when the onboarding guide is absent or stale. Synthesizes existing harness artifacts (HLD C4 diagrams, ADRs, OpenAPI spec, observability runbooks, business context, spec) into wiki/ONBOARDING.md. Produces 8 required sections: system overview, dev environment setup, architecture tour, key ADRs, API reference, first contribution guide, ops/monitoring, and where-to-find-things. Runs onboarding-reviewer agent before committing. A developer with no prior context should be productive in under one day.
---

# Onboarding Guide

Structured onboarding documentation makes new developers **40% faster to full productivity** and boosts overall productivity by **62%** (Forrester 2023). The harness already has all the source material — this skill assembles it.

## References

- **Microsoft Engineering Fundamentals Playbook** (microsoft.github.io/code-with-engineering-playbook/developer-experience/onboarding-guide-template/) — required sections and structure
- **Google Code Wiki** (Nov 2025) — AI-generated onboarding with C4 diagrams, ADR summaries, and chatbot
- **Developer Onboarding Research** — 40% productivity improvement with structured docs (Cortex, 2025)

---

## When to Use

**Required:**
- First production release (no `wiki/ONBOARDING.md` exists)
- After major architectural changes (HLD updated significantly)
- If `finishing-a-development-branch` detects the guide is > 6 months old

**Skip:** for every feature PR — onboarding guide is maintained, not regenerated per feature.

**Infer + confirm:**
> "This is a feature PR, not a major release. The onboarding guide hasn't changed. Skipping. Should I update the architecture section since the HLD was updated?"

---

## Source Artifacts

This skill reads **existing harness artifacts** — it does not invent content:

| Section | Reads from |
|---------|-----------|
| System overview | `.ai/business-context/` + HLD §1 (Context) |
| Architecture tour | HLD §3 (C4 Container diagram) + §5 (Actual Design) |
| Key ADRs | `wiki/architecture/ADR-*.md` — summary of all Accepted ADRs |
| API reference | `api/openapi.yaml` — endpoint listing |
| Ops/monitoring | `.ai/observability/YYYY-MM-DD-slos.md` + `wiki/guides/alerts.md` + `wiki/guides/runbooks/` |
| First contribution | Harness workflow (this plugin's workflow skill) |

---

## Process

1. **Check prerequisites** — confirm HLD, ADRs, observability docs, and OpenAPI spec exist. Flag missing ones before generating.
2. **Synthesize from source artifacts** — do not invent; quote or paraphrase existing content
3. **Generate dev setup** — read `package.json`/`pyproject.toml`/`go.mod`/`Cargo.toml` + CI config for setup commands
4. **Run `onboarding-reviewer`** — fix Critical and Important findings
5. **Commit** — `wiki/ONBOARDING.md`

---

## Output Format

Save to: `wiki/ONBOARDING.md`

````markdown
# Onboarding Guide — [Project Name]

**Welcome.** This guide gets you from zero to your first contribution.
**Target:** < 1 day to productive. If it takes longer, this guide needs updating.

**Last updated:** YYYY-MM-DD | **Updated by:** [link to PR/commit]

---

## 1. What Is This System?

[1-2 paragraphs from business-context doc: what problem it solves, who uses it, what "done" means. Non-technical enough for a new engineer to explain at a dinner party.]

**System at a glance:**
```mermaid
C4Context
    [Copy C4 Context diagram from HLD §3]
```

**Key facts:**
- Language/runtime: [from manifest files]
- Primary database: [from HLD tech selection]
- External dependencies: [from HLD Container diagram]
- Production SLO: [from .ai/observability/ SLO doc]

---

## 2. Dev Environment Setup

> These commands get a fresh macOS/Linux machine to a running local dev environment.
> Every command must be verified against the current `README` and CI config.

```bash
# 1. Clone
git clone [repo-url] && cd [repo-name]

# 2. Install dependencies [detect from manifest]
# Python: uv venv && source .venv/bin/activate && pip install -e ".[dev]"
# Node: npm install  (or: pnpm install / yarn)
# Go: go mod download
# Rust: cargo build

# 3. Environment variables
cp .env.example .env
# Edit .env — required variables:
# DATABASE_URL=postgres://localhost:5432/[db_name]_dev
# [other required vars from .env.example]

# 4. Start local database (if applicable)
docker compose up -d db   # or: brew services start postgresql

# 5. Run database migrations
[language-specific migration command]

# 6. Verify: run the tests
[test command]                     # Expected: all pass
[dev server command] &             # Start dev server
curl http://localhost:[port]/health # Expected: {"status": "ok"}
```

**If setup fails:** check `#dev-help` Slack channel or open an issue against the onboarding guide.

---

## 3. Architecture Tour

[2-3 paragraph narrative walking through the Container diagram. Explain WHY each component exists, not just what it is. Reference architectural decisions where relevant.]

```mermaid
C4Container
    [Copy C4 Container diagram from HLD §3.2]
```

**How a typical request flows:**

[Describe the critical path — from user action to response — in 5-7 steps. Reference the sequence diagram in `.ai/lld/` if it exists.]

**Key design decisions:**
- [One sentence summary of most important ADR, e.g., "We chose PostgreSQL over MongoDB because [reason from ADR-001]"]
- [Next most important ADR summary]
- [Third — see §4 for all ADRs]

---

## 4. Key Architectural Decisions

We use Architecture Decision Records (ADRs) stored in `wiki/architecture/`. Here's a summary of the most important ones:

| ADR | Decision | Status | Why it matters to you |
|-----|----------|--------|----------------------|
| [ADR-001](wiki/architecture/ADR-001-[name].md) | [one-line decision] | Accepted | [one sentence why a new engineer needs to know this] |
| [ADR-002](wiki/architecture/ADR-002-[name].md) | [one-line decision] | Accepted | [impact on daily work] |
| [More ADRs...] | | | |

**When to write a new ADR:** any time you make a non-obvious architectural choice. Use the template in `wiki/architecture/ADR-TEMPLATE.md` (if it exists).

---

## 5. API Reference

[Brief description of the API surface]

**OpenAPI spec:** `api/openapi.yaml` — view rendered at `http://localhost:[port]/docs` (dev server)

**Key endpoints:**

| Method | Path | What it does | Auth required? |
|--------|------|-------------|---------------|
| POST | `/api/auth/login` | Authenticate, returns JWT | No |
| GET | `/api/[resource]` | List [resources] | Yes |
| POST | `/api/[resource]` | Create [resource] | Yes |
[Generated from openapi.yaml paths section]

**Authentication:** [from OpenAPI security schemes — JWT/OAuth2/API key, how to get a token]

**Full API reference:** See `api/openapi.yaml` or render with `npx swagger-ui-express api/openapi.yaml`

---

## 6. Your First Contribution

*This section is a **Diátaxis tutorial** — learning by doing, not a reference.
It must walk a brand-new engineer through one real, small, guaranteed-to-succeed
change end-to-end (clone → change → test → PR), holding their hand at each step.
Keep it distinct from the how-to guides (§7 ops) and the reference (§5 API): a
tutorial's job is a first success, not completeness. The other seven sections map
to the remaining Diátaxis modes — §1/§3/§4 explanation (understanding), §5
reference (lookup), §7 how-to (operational steps).*

**The development workflow** (defined by this project's engineering harness):

```
business-context-intake → brainstorming → spec-quality-gate →
[high-level-design] → writing-plans → subagent-driven-development →
tests → requesting-code-review → pr-creator
```

**Step by step:**

1. **Pick a task** — check the issue tracker. Look for `good-first-issue` or `onboarding` labels.
2. **Read the spec** — every feature has a spec in `.ai/specs/`. Read it before writing code.
3. **Create a branch** — `git checkout -b feat/your-feature-name`
4. **Write tests first** — this project enforces TDD. Write the failing test before the implementation.
5. **Run the linter** — before committing: `[linter command for this project's language]`. Zero output required.
6. **Open a PR** — use `/pr-creator` or `gh pr create`. The description must explain WHY, not WHAT.
7. **Respond to review** — the project uses automated reviewers. Fix Critical findings before requesting human review.

**Coding conventions:**
- [Language/framework-specific conventions from CLAUDE.md or .cursorrules]
- Commit format: Conventional Commits (`feat:`, `fix:`, `docs:` etc.) — enforced by git hook
- Branch naming: `feat/`, `fix/`, `chore/` prefixes

---

## 7. Ops and Monitoring

**Production URL:** [from deployment docs]
**Staging URL:** [from CI/CD config]

**SLOs (what "healthy" means):**

| Endpoint | Availability SLO | Latency SLO (p99) |
|----------|-----------------|------------------|
[From .ai/observability/YYYY-MM-DD-slos.md]

**Dashboards:**
- [Link to primary dashboard if documented in wiki/guides/]

**Alerts (what wakes someone up):**
[From wiki/guides/alerts.md — list the 3-5 most important alerts and what they mean]

**If you're on-call:**
- Runbooks in `wiki/guides/runbooks/` — one per alert
- Escalation: [from runbooks]

**Logs:**
- Structured JSON, trace_id field in every entry
- [Log query for "recent errors": language-specific query]

---

## 8. Where to Find Things

| What | Where | Notes |
|------|-------|-------|
| Feature specs | `.ai/specs/` | One file per feature |
| Implementation plans | `.ai/plans/` | Bite-sized tasks |
| HLD (architecture doc) | `.ai/hld/` | C4 diagrams, ADRs, threat model |
| Sequence diagrams | `.ai/lld/` | Critical flow diagrams |
| SLO definitions | `.ai/observability/` | Availability/latency targets |
| Deployment runbooks | `.ai/deployment/` | Rollback, smoke tests |
| Architecture decisions | `wiki/architecture/` | ADR files |
| API reference | `api/openapi.yaml` | OpenAPI 3.1 spec |
| Operational runbooks | `wiki/guides/runbooks/` | One per alert |
| Changelog | `wiki/changelog/` | Per-release notes |
| This guide | `wiki/ONBOARDING.md` | Update when architecture changes |

---

*This guide is generated from harness artifacts and maintained by the team. If something is wrong or missing, open a PR against `wiki/ONBOARDING.md`.*
````

---

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review

## Self-Review: Run `onboarding-reviewer` Agent

After generating the guide:

```
Agent(onboarding-reviewer, {
  ONBOARDING_PATH: "wiki/ONBOARDING.md",
  HLD_PATH: ".ai/hld/YYYY-MM-DD-<feature>.md",
  SPEC_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md"
})
```

Fix all **Critical** findings before committing.

---

## Commit

```
docs(onboarding): generate wiki/ONBOARDING.md from harness artifacts

[body: WHY — first release / architecture changed / guide was stale]
```
