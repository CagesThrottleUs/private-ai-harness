---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Update wiki → Verify tests → Detect environment → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 0: Wiki Sync Check

Before touching tests or merge options, verify wiki is in sync with the changes on this branch.

**Check what changed:**
```bash
git diff <base-branch>...HEAD --name-only
```

For each changed file, ask: does this change public behavior, an API surface, an architecture decision, or developer-facing docs?

| Change type | Wiki action required |
|-------------|---------------------|
| New API endpoint | Add / update `wiki/api/<module>.md` |
| Changed API contract (params, response, errors) | Update `wiki/api/<module>.md` |
| Architecture change | Add ADR to `wiki/architecture/` |
| New developer workflow | Add guide to `wiki/guides/` |
| Bug fix (behavior was wrong, now correct) | Update wiki if the old (wrong) behavior was documented |
| Refactor only (no behavior change) | No wiki update needed |
| New feature visible to users | Add changelog entry in `wiki/changelog/` |

**If wiki update needed:** Make the change and commit it before proceeding to Step 1.  
**If no wiki update needed:** Document the reasoning in a brief comment and proceed.

Wiki entries must ship in the same branch as the behavior. There is no "doc pass" later.

**In any project:** also verify `CLAUDE.md` and `AGENTS.md` are in sync with this branch.

| Change on this branch | Must update |
|-----------------------|-------------|
| New skill / tool / command | `AGENTS.md` inventory |
| New or changed agent / subagent | `AGENTS.md` agent table |
| New install or setup step | `AGENTS.md` + `CLAUDE.md` if workflow changes |
| New workflow rule or convention | `CLAUDE.md` rules section |
| Breaking API or behavior change | `CLAUDE.md` + `AGENTS.md` contracts |

If either file does not exist in the project, create it before merging.
Commit `AGENTS.md` and `CLAUDE.md` in the same commit as the doc change.

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 1.5.

**If tests pass:** Continue to Step 1.5.

### Step 1: Performance, E2E, and Deployment Artifacts Check

Before running the review gate, verify required artifacts exist.

**Load tests** — required when spec contains performance NFRs (latency, throughput, availability):
```bash
ls tests/performance/*.js 2>/dev/null | wc -l
```
If zero load tests AND spec has NFR table → invoke `load-testing` skill first.

**Onboarding guide** — required on first production release or after major HLD changes:
```bash
# Check if guide exists and is recent (< 6 months old)
[ -f wiki/ONBOARDING.md ] && find wiki/ONBOARDING.md -mtime -180 | grep -q . || echo "NEEDS UPDATE"
```
If missing or stale AND this is a significant release → invoke `onboarding-guide` skill.

**E2E tests** — required for any feature with user-facing behavior:
```bash
ls tests/e2e/**/*.spec.ts 2>/dev/null | wc -l
```
If zero E2E tests AND feature has user-facing behavior → invoke `e2e-testing` skill first.

**Deployment artifacts** — required for any feature changing user-facing behavior:

```bash
ls .ai/deployment/YYYY-MM-DD-rollback.md .ai/deployment/YYYY-MM-DD-smoke-tests.md .ai/deployment/YYYY-MM-DD-deploy-runbook.md 2>/dev/null
```

**If deployment artifacts are absent AND this branch changes user-facing behavior, endpoints, or DB schema:**
Invoke `deployment-workflow` skill first. Do NOT proceed to review gate without deployment artifacts.

**If documentation-only or config-only change:** skip.

### Step 1.5: Review Gate

Run `/review all` before presenting merge/PR options. All four agents run in parallel.

```
/review all
```

This dispatches: pr-reviewer + spec-impl-reviewer + test-quality-reviewer + security-reviewer.

**Dispatch additional reviewers** for changed artifact types — run in parallel with `/review all`:

| If diff contains | Agent | Key inputs |
|-----------------|-------|------------|
| `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `.ai/ci/` | `ci-reviewer` | `CI_CONFIG_PATH`, `PROJECT_ROOT` |
| `tests/performance/` | `load-test-reviewer` | `SCRIPT_PATH`, `SPEC_PATH`, `SLO_PATH` |
| `tests/visual/` | `visual-regression-reviewer` | `TEST_FILES`, `SNAPSHOT_DIR` |
| `tests/chaos/` | `chaos-reviewer` | `TEST_FILES`, `HLD_PATH` |
| `.*github/workflows.*dast.*\.yml`, `.zap/` | `dast-reviewer` | `CI_CONFIG_PATH`, `OPENAPI_PATH` |
| `wiki/guides/incident-response.md`, `wiki/guides/postmortem-template.md` | `incident-response-reviewer` | `PROCESS_PATH`, `POSTMORTEM_PATH` |
| `wiki/ONBOARDING.md` | `onboarding-reviewer` | `ONBOARDING_PATH`, `HLD_PATH` |
| `wiki/architecture/*versioning*`, `wiki/guides/api-versioning*` | `api-versioning-reviewer` | `ADR_PATH`, `POLICY_PATH`, `OPENAPI_PATH` |
| `api/`, `.proto`, `openapi.` | `api-contract-reviewer` | `SPEC_PATH`, `PROTOCOL`, `SPEC_SOURCE_PATH` |
| `tests/integration/` | `integration-test-reviewer` | `TEST_FILES`, `SPEC_PATH` |
| `.ai/deployment/` | `deployment-reviewer` | `ROLLBACK_PATH`, `SMOKE_TEST_PATH`, `RUNBOOK_PATH` |
| `.ai/observability/`, `wiki/guides/alerts`, `wiki/guides/runbooks/` | `observability-reviewer` | `SLO_PATH`, `ALERTS_PATH`, `RUNBOOK_DIR` |
| `.ai/hld/` | `hld-reviewer` | `HLD_PATH`, `SPEC_PATH` |
| `tests/e2e/` | `e2e-reviewer` + `accessibility-reviewer` | `TEST_FILES`, `SPEC_PATH`, `BUSINESS_CONTEXT_PATH` |
| `infra/` | `iac-reviewer` | `IAC_DIR`, `TOOL` |
| `.ai/lld/*-schema.md` | `database-erd-reviewer` | `ERD_PATH`, `SPEC_PATH` |
| `.ai/lld/*-sequences.md` | `sequence-diagram-reviewer` | `DIAGRAM_PATH`, `HLD_PATH`, `SPEC_PATH` |

Run: `git diff <base-branch>...HEAD --name-only` to detect which artifact types changed. Dispatch matching reviewers in parallel. All Critical findings from all agents block merge.

**If any agent returns Critical:** Stop. Do not present merge/PR options.
```
Review gate failed — Critical issues found.
Fix all Critical issues before completing this branch.

Critical findings:
1. [AGENT] file:line — issue
2. ...
```

**If any agent returns Important:** Present options but pre-select **draft PR** for Option 2. Note all Important issues.

**If all agents clean / Minor only:** Continue to Step 2. All options available.

**Skip review gate only if:**
- User explicitly says "skip review" (they take responsibility)
- This is a pure `chore` commit (no code logic changed — only config, lockfile, tooling)

```bash
# Verify it's truly chore-only (no source file changes)
git diff <base>...HEAD --name-only | grep -vE "\.(json|lock|yaml|yml|toml|md|txt)$"
# If output is empty → chore-only, gate can be skipped
# If output has source files → gate required
```

### Step 2: Detect Environment

**Determine workspace state before presenting options:**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |

### Step 3: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 4: Present Options

**Normal repo and named-branch worktree — present exactly these 4 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Detached HEAD — present exactly these 3 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 5: Execute Choice

#### Option 1: Merge Locally

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
```

Then: Cleanup worktree (Step 6), then delete branch:

```bash
git branch -d <feature-branch>
```

#### Option 2: Push and Create PR

Use the `pr-creator` skill — it handles spec linkage, commit-msg.sh compliance, WHY body, traceability, and review gates automatically.

```
/pr-creator
```

`pr-creator` will:
1. Push the branch
2. Validate title + body via commit-msg.sh
3. Run `/review all` (already done in Step 1.5 — skip if results are fresh)
4. Create PR as draft or ready based on review results

**Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then: Cleanup worktree (Step 6), then force-delete branch:
```bash
git branch -D <feature-branch>
```

### Step 6: Cleanup Workspace

**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If worktree path is under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`:** Superpowers created this worktree — we own cleanup.

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" is ambiguous
- **Fix:** Present exactly 4 structured options (or 3 for detached HEAD)

**Cleaning up worktree for Option 2**
- **Problem:** Remove worktree user needs for PR iteration
- **Fix:** Only cleanup for Options 1 and 4

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` fails because worktree still references the branch
- **Fix:** Merge first, remove worktree, then delete branch

**Running git worktree remove from inside the worktree**
- **Problem:** Command fails silently when CWD is inside the worktree being removed
- **Fix:** Always `cd` to main repo root before `git worktree remove`

**Cleaning up harness-owned worktrees**
- **Problem:** Removing a worktree the harness created causes phantom state
- **Fix:** Only clean up worktrees under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Skip the wiki sync check (Step 0)
- Merge behavior changes without updating wiki in the same branch
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request
- Remove a worktree before confirming merge success
- Clean up worktrees you didn't create (provenance check)
- Run `git worktree remove` from inside the worktree

**Always:**
- Check wiki sync before anything else
- Commit wiki updates on this branch, not separately
- Verify tests before offering options
- Detect environment before presenting menu
- Present exactly 4 options (or 3 for detached HEAD)
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only
- `cd` to main repo root before worktree removal
- Run `git worktree prune` after removal
