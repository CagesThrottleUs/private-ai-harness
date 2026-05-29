---
name: workflow
description: The basic development workflow — ordered sequence of skills to invoke for any feature or fix, from brainstorming through branch completion. Mandatory, not suggestions.
user-invocable: true
---

## The Basic Workflow

## Complexity Assessment (before every workflow)

**Infer the change type first. Confirm with the user before proceeding.**

| Change type | Signals | Suggested skips |
|-------------|---------|----------------|
| **Trivial** | Bug fix, rename, config, docs, dependency bump | business-context-intake, high-level-design, api-contract-first, load-testing, deployment-workflow |
| **Small** | New utility function, adding a parameter, isolated feature with no new API/DB | high-level-design, load-testing (no NFRs), deployment-workflow (no migration) |
| **Medium** | New endpoint on existing service, new UI feature, new DB column | high-level-design (if extending existing pattern) |
| **Large** | New service, new data model, new external integration, new API surface | Full workflow |
| **Critical** | Auth/payment/PII changes, public API breaking change | Full workflow + extra security gate |

**Always confirm before skipping any step.** Use `AskUserQuestion` when the category is ambiguous. For obvious trivials (fixing a typo, bumping a version), a single inline question is fine.

Example confirm message:
> "This looks like a **small** change (adding array parsing to an existing parser — no new service, no new API, no NFRs). I suggest skipping: HLD, api-contract-first, business-context-intake, load-testing, deployment-workflow. Should I use the lightweight workflow (brainstorming → spec → plan → implement → review), or do you want the full suite?"

---

0. **Research & Reuse** _(mandatory before any new implementation)_
   - `gh search repos` and `gh search code` first — find existing implementations before writing anything new.
   - Context7 or vendor docs second — confirm API behavior, package usage, version-specific details.
   - Check npm/PyPI/crates.io/etc. for battle-tested libraries before writing utility code.
   - Prefer adopting or porting a proven approach over net-new code when it meets the requirement.

0.5. **business-context-intake** — Activates before brainstorming for any new feature or enhancement. Produces `.ai/business-context/YYYY-MM-DD-<feature>.md` with user problem, JTBD statement, measurable success metrics, compliance constraints, non-goals, and stakeholder map. Runs `business-context-reviewer` agent. Brainstorming MUST NOT activate without this document. **Skip** for bug fixes, config changes, and refactoring with no user-facing impact.

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Saves spec to `.ai/specs/` using REQ-NNN requirement format with test case mappings.

2. **spec-quality-gate** - Activates after spec is written. Lints spec for vague language, missing REQ-NNN structure, unmeasurable criteria, undeclared dependencies. FAIL = fix spec, re-run. PASS = proceed.

3. **high-level-design** - Activates after spec gate passes for any feature requiring architectural decisions (new services, data models, external integrations, security boundaries). Produces committed HLD document (C4 diagrams, technology selection, threat model via STRIDE, failure mode analysis, capacity planning) and ADRs in `wiki/architecture/`. Runs `hld-reviewer` agent before presenting to human. Human must approve HLD before `writing-plans` activates. **Skip** for bug fixes, config changes, and isolated non-architectural changes.

4. **using-git-worktrees** - Activates after HLD is approved (or after spec gate for non-architectural changes). Creates isolated workspace on new branch, runs project setup, verifies clean test baseline. Immediately triggers `ci-pipeline-setup` if no CI config exists.

4.5. **ci-pipeline-setup** - Activates immediately after worktree creation if no CI configuration exists. Detects platform (GitHub Actions, GitLab CI, Jenkins, CircleCI, Azure DevOps, Bitbucket), generates platform-agnostic pipeline spec and platform-specific config, runs `ci-reviewer` agent. Pipeline commits to branch before first feature commit — CI guards from day one.

5. **writing-plans** - Activates with approved spec and HLD. Breaks work into bite-sized tasks (2-5 minutes each). Saves plan to `.ai/plans/`. Every task has exact file paths, complete code, verification steps tied to REQ-NNN IDs. Each task should trace to a container in the HLD's C4 diagram.

6. **subagent-driven-development** or **executing-plans** - Activates with plan. Dispatches fresh subagent per task with two-stage review (spec compliance, then code quality), or executes in batches with human checkpoints. After any task that creates an API endpoint or service component, triggers `observability-standards` to instrument logging, metrics, SLOs, alerts, and runbooks.

7. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.

8. **code-documentation** - Activates for every public function, class, or API endpoint written. Full docstring, params, returns, throws, example. Wiki updated in same commit for API changes.

9. **requesting-code-review** - Activates between tasks. Reviews against plan and spec REQ-NNN IDs, reports issues by severity. Critical issues block progress.

10. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, presents options (merge/PR/keep/discard), cleans up worktree.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## Documentation Locations

`wiki/` = living product docs — always 1:1 with the product, updated in the same commit as behavior changes.  
`.ai/` = ephemeral work artifacts (`%TEMP%` for AI) — audit trail, not source of truth.

| Artifact | Location | Notes |
|----------|----------|-------|
| Team onboarding | `wiki/ONBOARDING.md` | Generated by `/team-onboarding`; lives here, not repo root |
| API endpoint reference | `wiki/api/` | Must match code; updated in same commit as behavior |
| Architecture decisions (ADRs) | `wiki/architecture/` | Immutable once merged |
| Developer guides / runbooks | `wiki/guides/` | How-tos, operational procedures |
| Changelog / release notes / news | `wiki/changelog/` | One file per release or sprint |
| Business context | `.ai/business-context/YYYY-MM-DD-feature.md` | User problem, JTBD, success metrics, compliance; gate before brainstorming |
| Feature design specs | `.ai/specs/YYYY-MM-DD-feature.md` | Ephemeral; audit trail after ship |
| High level design | `.ai/hld/YYYY-MM-DD-feature.md` | Ephemeral; audit trail after ship |
| Sequence diagrams | `.ai/lld/YYYY-MM-DD-<feature>-sequences.md` | Critical flows with error paths, auth boundary, sync/async |
| CI/CD pipeline spec | `.ai/ci/YYYY-MM-DD-pipeline-spec.md` | Platform-agnostic pipeline design; committed alongside CI config |
| SLO definition | `.ai/observability/YYYY-MM-DD-slos.md` | SLI/SLO/error budget; tied to spec NFRs |
| API contract (REST) | `api/openapi.yaml` | OpenAPI 3.1 spec — written before handler code |
| API contract (gRPC) | `proto/<pkg>/v1/<service>.proto` | Protobuf service definition — written before service implementation |
| Performance baseline | `.ai/performance/YYYY-MM-DD-baseline.md` | k6 results vs NFR targets; committed after load test run |
| Deployment artifacts | `.ai/deployment/YYYY-MM-DD-*.md` | Rollback procedure, smoke tests, deploy runbook, migration checklist |
| Implementation plans | `.ai/plans/YYYY-MM-DD-feature.md` | Ephemeral; audit trail after ship |
| Quality gate reports | `.ai/reports/` | Ephemeral; one per run |
| Requirement traceability | `.ai/requirements/` | REQ-NNN → TC mapping |

## Wiki Sync Rule

**Every behavior change ships with a wiki update in the same commit.**

No exceptions. No "I'll document it later." The `finishing-a-development-branch` skill (Step 0) enforces this before any merge or PR is allowed.

Checklist before merge:
- [ ] New / changed API endpoint → `wiki/api/` updated
- [ ] Architecture decision made → ADR added to `wiki/architecture/`
- [ ] New developer workflow → guide added to `wiki/guides/`
- [ ] Feature shipped → changelog entry in `wiki/changelog/`
- [ ] Breaking change → onboarding updated in `wiki/ONBOARDING.md`

## AGENTS.md + CLAUDE.md Sync Rule

**In any project:** any commit that touches documentation, public behavior, project structure,
or tooling must also update `CLAUDE.md` and `AGENTS.md` in the same commit.

If either file does not exist yet, create it. A missing file is not a reason to skip.

| Change made | Must update |
|-------------|-------------|
| New skill / tool / command | `AGENTS.md` inventory |
| New or changed agent / subagent | `AGENTS.md` agent table |
| New install or setup step | `AGENTS.md` tools section + `CLAUDE.md` if workflow changes |
| New workflow rule or convention | `CLAUDE.md` rules section |
| Breaking API or behavior change | `CLAUDE.md` + `AGENTS.md` contracts |
| New external dependency | `AGENTS.md` if AI-relevant, `CLAUDE.md` if it affects how to work in the repo |

Commit `AGENTS.md` and `CLAUDE.md` in the same commit as the change that triggered the update.
