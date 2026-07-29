---
name: pr-creator
description: Use when creating a pull request. Runs pre-flight checks, enforces spec+plan linkage, generates a commit-msg.sh compliant title and WHY-focused body, auto-populates traceability from the diff, consumes the branch's review verdict before submitting, and creates the PR via gh CLI.
---

# PR Creator

Creates pull requests that are commit-msg.sh compliant, spec-linked, plan-linked, and traceability-verified before a single line reaches GitHub.

## The Iron Law

```
NO PR WITHOUT A SPEC AND A PLAN.
TITLE AND BODY MUST PASS commit-msg.sh.
WHY — NOT WHAT FILES CHANGED.
```

Before validation, resolve `HARNESS_ROOT` from this installed skill's path:
the plugin root is two directories above `skills/pr-creator/SKILL.md`. Use
`$HARNESS_ROOT/scripts/commit-msg.sh` in every command below. This works for
both Claude Code and Codex plugin installations; do not assume a
`~/.claude/scripts/` path.

---

## Execution Order

```
Step 0 → Pre-flight gates (all must pass)
Step 1 → Collect spec + plan
Step 2 → Generate title (commit-msg.sh validated)
Step 3 → Build WHY body
Step 4 → Auto-traceability block
Step 5 → Consume review verdict (no re-dispatch)
Step 6 → Assign reviewers
Step 7 → Create PR (draft if any gap, ready if all green)
Step 8 → Post-creation report
```

Do not skip steps. Do not create the PR until Step 5 passes or user explicitly overrides.

---

## Step 0 — Pre-flight Gates

All must pass before proceeding. Report failures and stop.

```bash
# 1. Working tree clean
git status --porcelain
# Any output = uncommitted changes = STOP

# 2. Branch pushed and not behind main
git fetch origin
git status -sb | grep -E "ahead|behind|diverged"
# "behind" or "diverged" = STOP

# 3. Build passes (auto-detect language)
# Node/npm:
npm run build 2>&1 | tail -5
# Go:
go build ./... 2>&1
# Rust:
cargo build 2>&1 | tail -10
# Python: (check imports compile)
python -m py_compile $(git diff --name-only origin/main...HEAD | grep '\.py$') 2>&1
# Other: run whatever build command the project defines

# 4. Tests pass
# Node:
npm test 2>&1 | tail -20
# Go:
go test ./... 2>&1 | tail -20
# Rust:
cargo test 2>&1 | tail -20
# Python:
pytest 2>&1 | tail -20

# 5. Commit messages all compliant
git log origin/main..HEAD --format="%H %s" | while read sha subject; do
  git show -s --format="%B" "$sha" | bash "$HARNESS_ROOT/scripts/commit-msg.sh" /dev/stdin
done
# Any red output = non-compliant commit = STOP, list failing commits
```

**Pre-flight report:**

```
Pre-flight:
  [ ] Working tree clean
  [ ] Branch up to date with origin/main
  [ ] Build passes
  [ ] Tests pass
  [ ] All commits pass commit-msg.sh

Status: PASS | FAIL
```

If any FAIL: list exactly what failed and what to fix. Do not proceed.

---

## Step 1 — Collect Spec + Plan

Both are **mandatory**. No PR without both.

**Spec:** The `.ai/specs/` file (with `spec_id: SPEC-N`) that governs this work.
**Plan:** The `.ai/plans/` file that broke down the implementation.

Ask the user:
```
Which spec does this PR implement?
→ Path: .ai/specs/<name>.md

Which plan did you follow?
→ Path: .ai/plans/<name>.md (or .ai/plans/<date>-<name>.md)
```

If neither exists: STOP. Do not create the PR.

```
❌ PR BLOCKED — NO SPEC / NO PLAN

Every PR must reference:
  1. A spec file (.ai/specs/) with a valid spec_id: SPEC-N
  2. A plan file (.ai/plans/) that governed the implementation

Reason: A PR without a spec is unverifiable.
         A PR without a plan has no baseline to compare against.

Create the spec and plan, then re-run /pr-creator.
```

Once paths are provided:
- Read the spec → extract `spec_id`, `north_star`, all `REQ-NNN` IDs, title
- Read the plan → extract the task list and what was implemented

---

## Step 2 — Generate PR Title

PR title = commit subject line. Must pass commit-msg.sh.

**Rules:**
- Format: `type(scope): imperative summary`
- ≤50 chars (aim); hard cap 72
- Lowercase start after colon, no trailing period
- Types: `feat` `fix` `refactor` `perf` `docs` `test` `chore` `build` `ci`
- Scope: module name, feature name, or SPEC-N label

**Auto-draft process:**
1. Read branch name → extract type/scope hint
2. Read commit subjects on this branch: `git log origin/main..HEAD --format="%s"`
3. Synthesize a single subject that captures the full PR intent

```bash
# Validate the drafted title
printf '<drafted-title>' | bash "$HARNESS_ROOT/scripts/commit-msg.sh" /dev/stdin
```

Present to user for confirmation. Re-draft if rejected.

**Examples:**
```
✅ feat(auth): add email validation against RFC 5321   (47 chars)
✅ fix(SPEC-2): correct token expiry boundary check    (44 chars)
✅ refactor(validation): extract pipeline into module  (50 chars)

❌ Add email validation and fix the token thing and also update docs
❌ feat: implemented the new authentication flow as per the spec
```

---

## Step 3 — Build PR Body

Body = commit body. Must pass commit-msg.sh. **Explains WHY, never what files changed.**

**Template:**

```markdown
<WHY: 2-4 sentences. What was wrong/missing? Why this approach over alternatives?
What breaks without this change? Never list files. Never say "I added X to Y.">

Spec: .ai/specs/<name>.md (SPEC-N)
Plan: .ai/plans/<name>.md
Requirements: REQ-001, REQ-002, REQ-003
North Star: <spec's north_star value — the business metric this change advances, or "N/A — <reason>">

<one line: which input metric of the north-star this PR moves — the reviewer and
outcome-review read this to close the "measure what you shipped" loop. Omit for N/A.>

## Traceability
<auto-populated in Step 4>

## Test Plan
- [ ] unit: <command and what it verifies>
- [ ] integration: <describe scenario>
- [ ] manual smoke: <exact steps to verify the change works>

## Wiki / Doc Updates
<list pages added/updated, or "None — no public API changed">
```

**WHY body rules (same as commit-msg.sh):**
- Wrap at 72 chars (aim); 80 hard block
- No file inventory — diff shows what changed
- No "I" / "we" / "now" / "currently"
- No AI attribution
- Required when PR touches more than one file (which is almost always)

**Validate body before using:**
```bash
printf '<title>\n\n<body>' | bash "$HARNESS_ROOT/scripts/commit-msg.sh" /dev/stdin
# Zero output = compliant. Any red = fix before proceeding.
```

---

## Step 4 — Auto-Traceability Block

Grep the diff for annotations. Populate the traceability table in the body.

```bash
BASE=$(git merge-base origin/main HEAD)
HEAD=$(git rev-parse HEAD)

# Symbols with spec_id + req_id in changed files
git diff $BASE..$HEAD --name-only | xargs grep -ln "spec_id:\|@spec_id" 2>/dev/null | \
  xargs grep -n "spec_id:\|@spec_id\|req_id:\|@req_id" 2>/dev/null

# Test annotations in changed files
git diff $BASE..$HEAD --name-only | xargs grep -ln "validates_req:\|@validates_req" 2>/dev/null | \
  xargs grep -n "spec_id:\|@spec_id\|validates_req:\|@validates_req" 2>/dev/null
```

Build the table:

```markdown
## Traceability

| Construct | File:Line | SPEC | REQ |
|-----------|-----------|------|-----|
| `validateEmail` | `auth/validation.ts:42` | SPEC-2 | REQ-004 |
| `TestValidateEmail_Empty` | `auth/validation_test.go:18` | SPEC-2 | validates REQ-004 |

Missing annotations (must fix before merge):
- `auth/accounts.ts:87` — `createAccount` — missing @spec_id + @req_id
```

If any public construct in the diff is missing `@spec_id` or `@req_id`: flag as gap. PR will be created as **draft** until fixed.

---

## Step 5 — Consume Review Verdict (no re-dispatch)

The authoritative review runs once, at `finishing-a-development-branch`
Step 1.5, which writes `.ai/reports/YYYY-MM-DD-<branch>-review-summary.md`.
pr-creator consumes that verdict — it does NOT run review agents again.

```bash
BRANCH=$(git branch --show-current)
VERDICT=$(ls -t .ai/reports/*-"$BRANCH"-review-summary.md 2>/dev/null | head -1)
```

- If `$VERDICT` exists and was written for the current HEAD → read it. Do NOT
  dispatch any review agent.
- If `$VERDICT` is absent → run `/review all` exactly once, then read the
  summary it writes.

Decide PR state from the verdict's `## Overall` line:

| Overall | PR state |
|---------|----------|
| MERGE READY | ready |
| NEEDS WORK | draft — list Important issues under `## Review Notes` |
| BLOCKED | STOP — do not create the PR |

---

## Step 6 — Reviewer Assignment

```bash
# Check for CODEOWNERS
cat CODEOWNERS 2>/dev/null | grep -E "$(git diff --name-only origin/main..HEAD | head -5 | tr '\n' '|')"
```

If `CODEOWNERS` matches changed files → suggest those owners.

Ask user: "Request review from: (enter GitHub usernames, or press enter to skip)"

Store for `gh pr create --reviewer` flag.

---

## Step 7 — Create PR

**Draft conditions** (any one = draft):
- Pre-flight had warnings (not hard failures — those stopped at Step 0)
- Traceability gaps found in Step 4
- Review verdict (Step 5) is NEEDS WORK

**Ready conditions** (all must be true):
- Pre-flight clean
- Full traceability coverage
- Review verdict (Step 5) is MERGE READY

```bash
# Validate final title+body one more time
printf '<title>\n\n<body>' | bash "$HARNESS_ROOT/scripts/commit-msg.sh" /dev/stdin

# Create PR
gh pr create \
  --title "<title from Step 2>" \
  --body "$(cat <<'EOF'
<body from Steps 3+4+5>
EOF
)" \
  --base main \
  --head "$(git branch --show-current)" \
  [--draft if draft conditions met] \
  [--reviewer user1,user2 if Step 6 produced reviewers]
```

If draft: print reason clearly.

---

## Step 8 — Post-creation Report

```bash
# Get PR number
PR_NUM=$(gh pr list --head "$(git branch --show-current)" --limit 1 --json number --jq '.[0].number')

# Print PR URL
gh pr view $PR_NUM --json url --jq '.url'

# Get CI run link
gh run list --branch "$(git branch --show-current)" --limit 1 --json url --jq '.[0].url'

# Offer to watch CI
echo "Watch CI? Run: gh run watch <run-id>"
```

**Post-creation summary:**

```
PR created: https://github.com/<owner>/<repo>/pull/<N>
Status: Ready | Draft
Reason (if draft): <reason>

CI: <run URL>
Reviewers requested: <list or none>

Traceability gaps (fix before merge):
- <list from Step 4, if any>

pr-reviewer issues (fix before merge):
- <list from Step 5, if any>
```

---

## Commit-msg.sh Compliance Reference

The same rules that govern commits govern PRs:

| Rule | Limit | Hard block |
|------|-------|-----------|
| Title length | ≤50 aim | >72 blocked |
| Title format | `type(scope): lowercase` | CC pattern required |
| No trailing period | — | Blocked |
| Body required | >1 file staged | Blocked if absent |
| Body line length | ≤72 aim | >80 blocked |
| Body explains WHY | — | File-list body blocked |

Run before every creation attempt:
```bash
printf '<title>\n\n<body>' | bash "$HARNESS_ROOT/scripts/commit-msg.sh" /dev/stdin
# Zero output = compliant. Any red line = fix first.
```

---

## Quick Reference — Flags

| Condition | PR state |
|-----------|----------|
| Pre-flight fails | STOP — don't create |
| No spec or plan | STOP — don't create |
| Traceability gaps | Draft |
| Any agent Critical | STOP — don't create |
| Any agent Important | Draft |
| All agents clean / Minor only | Ready |
