---
name: giving-code-review
description: Use when acting as the reviewer for a pull request via gh — someone else's PR, or your own PR before requesting external review. Distinct from requesting-code-review (asking the harness's reviewer agents to review your own in-progress branch). Determines self vs external review stance, walks every commit, applies pr-reviewer's dimensions plus a trust-but-verify pass on claims, then posts findings through github-workflows.
---

# Giving Code Review

`requesting-code-review` is about asking for a review of your own work.
This skill is about *being* the reviewer — for someone else's PR, or your own
PR before you ask anyone else to look at it.

---

## Step 0: Whose PR is this?

```bash
gh pr view <number> --json author --jq .author.login
gh api user -q .login
```

Match → **self-review mode**. No match → **external-review mode**. Both run
Steps 1-4; self-review adds Step 5 and doubles the rigor on every step.

---

## Step 1: Map the change — walk every commit

```bash
gh pr view <number> --json headRefName,baseRefName,title,body,commits
git fetch origin <branch>
git log --reverse --format='%h %s' main..origin/<branch>
```

Do not stop at the tip — review every commit in the range, oldest first. Flag:
- Commits mixing unrelated changes (refactor + feature + fix together)
- Code added then reverted within the same range (net-zero noise)
- Commit messages that contradict what their diff actually does

If the range exceeds ~30 commits or ~1000 changed lines, say so up front and
recommend splitting rather than rushing a partial pass — a review that skips
commits to fit a budget is worse than an honest "this needs to be split."

---

## Step 2: Apply the review dimensions

Use the same checklist `pr-reviewer` runs against a diff: code quality, docs,
security, reliability, performance, plus its adversarial pass (empty/zero/
negative/unicode inputs, loop bounds, concurrency, numeric edge cases). See
`agents/pr-reviewer.md`.

- **This repo, with a spec attached:** dispatch the `pr-reviewer` agent
  directly rather than re-deriving the checklist by hand.
- **Any other repo, or no spec:** walk the diff yourself against the same
  dimensions — the checklist doesn't depend on this harness being installed.

---

## Step 3: Trust-but-verify pass on claims

Treat every claim in the PR description, commit messages, or a prior review
comment — "verified", "tested locally", "fixes the race", "backward
compatible" — as unproven until you've built the adversarial case yourself.
This is the `karpathy` skill's **Verify Load-Bearing Claims** guideline,
applied to the reviewer's side of the table:

- Read the actual source of the framework/dependency the claim leans on —
  not just its docs.
- Construct the smallest input that would falsify the claim, and check
  whether the diff actually handles it.
- For a change to a client-visible contract (API shape, config default, wire
  format), check what happens to a caller already running the old behavior
  in production — not just whether the new behavior works.
- A "confirmed" claim with no repro attached is still an open question, not
  a fact — say so rather than deferring to it.

---

## Step 4: Prior review threads

```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  --jq '.[] | "\(.user.login) on \(.path):\(.line): \(.body)"'
gh pr view <number> --json reviews --jq '.reviews[] | "\(.author.login) [\(.state)]: \(.body)"'
```

- **Adverse advice** — a comment that would make the PR worse if followed
  ("just catch and ignore this", "skip tests here"). Flag it explicitly;
  silence reads as agreement.
- **Good suggestions worth amplifying** — a real issue another reviewer
  raised that the author hasn't acted on. Restate and support it.
- **Don't re-raise** what's already been caught — cite the existing comment.

---

## Step 5 — Self-review mode: apply double the rigor

Authors carry a favorable bias toward their own code — the same blind spot
that let a bug through the first time is what a casual re-read reproduces.
Counter it explicitly rather than "looking it over again":

- **Checkout and run it**, don't eyeball the diff in the terminal — build,
  execute, exercise the golden path and the edge cases from Step 2.
- **Review after a context switch** — do something else first. Reviewing
  immediately after writing reuses the exact mental model that missed the
  issue.
- **Run every item in Step 2's adversarial pass anyway**, even though "you
  know what it does" — that assumption is exactly what hides bugs in your
  own code.
- **Don't shortcut Step 3** because you wrote the claim — "I tested this
  locally," written by you, is exactly as unverified as if a stranger wrote
  it. Re-derive the adversarial case that would break it.
- **Leave inline self-comments** on non-obvious changes, the way you'd want
  an external reviewer to flag them — this primes whoever reviews it next,
  and often surfaces the bug before anyone else sees the PR.
- Do not rubber-stamp your own PR to "just get to review." A self-review
  that finds nothing should be rare, not routine.

---

## Feedback etiquette

- Prioritize by severity: correctness/security first, design second,
  style/nits last — don't lead with a nit when a Critical exists.
- Prefix comments so intent is unambiguous: `blocking:`, `suggestion:`,
  `question:`, `nit:`.
- Write asks as falsifiable test cases the author can act on today ("cover
  the limit-plus-one and malformed-override cases"), not "add more tests."
- Specific and respectful — no unexplained "just do X."

---

## Posting

Use `github-workflows`'s Review section for the mechanics: confirm identity,
post inline comments pinned to `file:line` via `gh api .../reviews` in one
atomic review, pick the right `event`, fall back to `gh pr comment` if the
API call fails. Do not auto-post — show findings to the user first and
confirm Approve / Request changes / Comment-only.
