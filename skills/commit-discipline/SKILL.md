---
name: commit-discipline
description: >
  Authoritative commit message generator and git discipline rules.
  Conventional Commits format, micro-commit discipline, PR title/body rules,
  and pre-commit enforcement. Use when user says "write a commit",
  "commit message", "generate commit", "/commit", or invokes /caveman-commit.
---

Write commit messages terse and exact. Conventional Commits format. Why over what.

## Subject Line

- `<type>(<scope>): <imperative summary>` — `<scope>` optional
- Types: `feat` `fix` `refactor` `perf` `docs` `test` `chore` `build` `ci` `style` `revert`
- Imperative mood: "add", "fix", "remove" — not "added", "adds", "adding"
- ≤50 chars (aim); hard cap 72 — commits rejected over this
- No trailing period; lowercase start after colon

## Body

- Skip when subject is self-explanatory (single-file, obvious change)
- **Required** when commit touches more than one file
- Explains **WHY**: what was wrong, why this fix, what would break without it
- Never a file inventory — diff shows what changed
- Wrap at 72 chars (aim); 80 hard block
- Bullets `-` not `*`
- Reference issues/PRs at end: `Closes #42`, `Refs #17`

Always include body for: breaking changes, security fixes, data migrations, reverts.

## Micro-commit Discipline

One logical change per commit. Never batch:
- implementation + test changes
- doc changes + code changes
- unrelated module edits

Stage only the files for one logical change, commit, then move on.

## What Never Goes In

- "This commit does X", "I", "we", "now", "currently" — diff says what
- "As requested by..." — BANNED FROM USING THIS!
- AI attribution of any kind
- Emoji (unless project requires)
- File names when scope already says it
- Restating what the diff already shows

## Examples

```
✅ feat(sp6b): add db_read_memory tool          (36 chars)
✅ fix(sp9): guard empty log_handles early       (40 chars)
✅ docs(agents): add PR title/body contract      (43 chars)

❌ feat(sp6b): add db_read_remediation_history CLI tool  (51+ chars)
❌ Bundling prompt change + test + doc in one commit
❌ Body that lists files changed
```

Multi-file commit with WHY body:
```
fix(sp9): guard empty log handles

Handler passed empty dict to classify on every suite where
log fetch raised — produced a spurious infra escalation with
no diagnostic evidence. Guard exits early; writes
failed_no_log_handles so cause is visible in Splunk.
```

Breaking change:
```
feat(api)!: rename /v1/orders to /v1/checkout

BREAKING CHANGE: clients on /v1/orders must migrate before
2026-06-01. Old route returns 410 after that date.
```

New endpoint with business context:
```
feat(api): add GET /users/:id/profile

Mobile client needs profile data without the full user payload
to reduce LTE bandwidth on cold-launch screens.

Closes #128
```

## PR Title and Description

Same rules apply — PR title = commit subject, PR body = commit body.
Every PR title and body must be directly copyable as a commit message.

Verify before opening:
```bash
printf '<title>\n\n<body>' | bash scripts/commit-msg.sh /dev/stdin
# Zero output = ready. Any red line = fix first.
```

## Pre-commit Compliance Check

Canonical script: `scripts/commit-msg.sh`

Ad-hoc check:
```bash
printf 'type(scope): subject\n\nbody text here' | bash scripts/commit-msg.sh /dev/stdin
# Zero output = compliant. Any red line = fix before committing.
```

Install as git hook in any project:
```bash
ln -sf scripts/commit-msg.sh .git/hooks/commit-msg
```

Hook auto-rejects: subject >72 chars, bad CC format, no body on multi-file commit,
pure file-list body, body lines >80 chars.

## Boundaries

Generates the message only. Does not run `git commit`, stage files, or amend.
Output as code block ready to paste.
