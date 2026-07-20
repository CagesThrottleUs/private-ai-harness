---
name: github-workflows
description: Use for any GitHub operation — PRs, issues, CI status, labels, reviewers, comments, merging. Always use gh CLI, never the GitHub web UI or raw API calls.
---

# GitHub Workflows

**Rule:** All GitHub operations use `gh` CLI. Never curl the GitHub API directly. Never instruct the user to open the browser for operations `gh` supports.

---

## Core Principle

```
gh > browser > raw API
```

If `gh` supports it, use `gh`. It handles auth, paginates automatically, and outputs structured JSON when needed.

---

## Authentication

```bash
gh auth status                        # check current auth
gh auth login                         # interactive login
gh auth login --with-token <<< $PAT   # non-interactive (CI)
```

---

## Pull Requests

### View

```bash
gh pr list                            # list open PRs (current repo)
gh pr list --state all                # include closed/merged
gh pr list --author @me               # my PRs
gh pr view <number>                   # view PR details
gh pr view <number> --json title,body,state,reviewRequests,checks
gh pr checks <number>                 # CI status for a PR
gh pr diff <number>                   # diff for a PR
```

### Create

For PR create, ensure that you use proper skills for the same.

```bash
gh pr create \
  --title "type(scope): imperative summary" \
  --body "$(cat <<'EOF'
## Summary
- bullet 1
- bullet 2

## Spec
Implements: .ai/specs/feature-name.md (REQ-001, REQ-002)

## Test plan
- [ ] unit tests pass
- [ ] integration tests pass
- [ ] manual smoke test: <steps>
EOF
)" \
  --base main \
  --head feature-branch

gh pr create --draft   # open as draft
gh pr create --web     # open in browser to finish (last resort only)
```

### Update

```bash
gh pr edit <number> --title "new title"
gh pr edit <number> --body "new body"
gh pr edit <number> --add-label "bug,urgent"
gh pr edit <number> --add-reviewer username
gh pr edit <number> --base main        # retarget base branch
```

### Review

```bash
gh pr review <number> --approve
gh pr review <number> --request-changes --body "see inline comments"
gh pr review <number> --comment --body "LGTM except for X"
```

**Posting review findings pinned to diff lines.** `gh pr review` above only
posts a body — no inline comments. For findings tied to specific `file:line`,
post one atomic GitHub Review via `gh api` instead so inline comments land
pinned to their diff lines, not buried in a wall-of-text body:

```bash
# Confirm identity first — a wrong-account review is hard to unsend
git config user.email
gh api user -q .login

# Metadata needed for the API call
gh pr view <number> --json baseRefName,headRefOid,headRefName \
  --jq '{base: .baseRefName, sha: .headRefOid, head: .headRefName}'

gh api -X POST "repos/{owner}/{repo}/pulls/<number>/reviews" --input - <<'JSON'
{
  "commit_id": "<headRefOid from above>",
  "event": "REQUEST_CHANGES",
  "body": "<overall summary — omit per-line findings, those go in comments[]>",
  "comments": [
    { "path": "src/foo.rs", "line": 42, "side": "RIGHT", "body": "**[CRITICAL]** <description>" }
  ]
}
JSON
```

`event`: `APPROVE` / `REQUEST_CHANGES` (any Critical or non-deferred High
finding) / `COMMENT` (discussion only, no block signal). `side: "RIGHT"` pins
to the PR's new file version; use `"LEFT"` only for comments on removed lines.

**Fallback** — if `gh api /reviews` fails (auth scope, enterprise host
quirks), post the body via `gh pr comment <number> --body-file <path>` and
say so — inline pinning is lost.

Do not auto-post: show findings to the user first and confirm Approve /
Request changes / Comment-only before submitting.

### Merge

```bash
gh pr merge <number> --squash --delete-branch   # squash merge (preferred)
gh pr merge <number> --merge                    # merge commit
gh pr merge <number> --rebase                   # rebase merge
gh pr merge <number> --auto --squash            # auto-merge when CI passes
```

### Comment

```bash
gh pr comment <number> --body "comment text"
gh pr comment <number> --body "$(cat review.md)"   # from file
```

---

## Issues

```bash
gh issue list                          # open issues
gh issue list --label "bug"
gh issue view <number>
gh issue create --title "title" --body "body" --label "bug"
gh issue close <number>
gh issue comment <number> --body "text"
gh issue edit <number> --add-label "priority:high"
```

---

## CI / Checks

```bash
gh pr checks <number>                  # checks for a PR
gh run list                            # recent workflow runs
gh run list --branch feature-branch
gh run view <run-id>                   # details of a run
gh run view <run-id> --log             # full logs
gh run watch <run-id>                  # stream until complete
gh run rerun <run-id>                  # rerun failed run
gh run rerun <run-id> --failed-only    # rerun only failed jobs
```

Wait for CI before merge:
```bash
gh run watch $(gh run list --branch $(git branch --show-current) --limit 1 --json databaseId --jq '.[0].databaseId')
```

---

## Labels and Milestones

```bash
gh label list
gh label create "req-id" --color "#0075ca" --description "Requirement traceability"
gh milestone list
gh issue edit <number> --milestone "v1.0"
```

---

## Releases

```bash
gh release list
gh release view v1.2.3
gh release create v1.2.3 --title "v1.2.3" --notes "$(cat changelog.md)"
gh release create v1.2.3 --generate-notes    # auto-generate from commits
```

---

## Repo Operations

```bash
gh repo view                           # current repo info
gh repo clone owner/repo
gh repo fork owner/repo --clone
gh repo set-default owner/repo         # set default repo for gh commands
```

---

## JSON Output (scripting)

```bash
# Get PR number of latest open PR
gh pr list --limit 1 --json number --jq '.[0].number'

# Get all check statuses
gh pr checks <number> --json name,state,conclusion

# Get all REQ labels on a PR
gh pr view <number> --json labels --jq '[.labels[].name]'

# List failed check names
gh pr checks <number> --json name,conclusion --jq '[.[] | select(.conclusion == "FAILURE") | .name]'
```

---

## Workflow for This Project

### Standard PR workflow

```bash
# 1. Push branch
git push -u origin HEAD

# 2. Create PR with spec reference (required)
gh pr create --title "type(scope): summary" --body "..."

# 3. Check CI
gh pr checks <number>

# 4. Watch CI complete
gh run watch <run-id>

# 5. Merge when green
gh pr merge <number> --squash --delete-branch
```

### Check if PR needs spec

```bash
# Check PR body for spec reference
gh pr view <number> --json body --jq '.body' | grep -E "REQ-[0-9]+|\.ai/specs/"
# Empty output = spec missing = block review
```

---

## Common Mistakes — Do Not Do These

| Wrong | Right |
|-------|-------|
| `curl -H "Authorization: token $TOKEN" https://api.github.com/...` | `gh api repos/:owner/:repo/...` |
| Opening browser to create PR | `gh pr create` |
| Polling CI manually | `gh run watch` |
| `git push` then forgetting to create PR | `git push && gh pr create` |
| Merging without CI passing | `gh pr merge --auto` (waits for CI) |

---

## Escape Hatch — Raw API

Only when `gh` has no subcommand for the operation:

```bash
gh api repos/:owner/:repo/pulls/<number>/reviews   # list reviews
gh api -X POST repos/:owner/:repo/issues/<number>/labels --field labels[]="req-id"
gh api graphql -f query='{ viewer { login } }'     # GraphQL
```

`:owner` and `:repo` are auto-resolved from the current git remote.
