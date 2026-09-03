---
name: closing-review-loops
description: Use after addressing review findings and before re-triggering any external reviewer (Talos, CodeRabbit, a queued human re-review, or a re-run of /review). Enforces one batched fix pass, an internal self-review that hunts the same failure classes already found in this PR plus anything the fix itself introduced, and a single push — so a PR converges in as few rounds as possible instead of churning comment-by-comment.
---

# Closing Review Loops

Every extra review round is a full reviewer pass plus wait time — not just the
diff line. How you *close* a round decides whether the next one has to exist.
Close it to **zero negotiable rounds**: nothing avoidable is allowed to reach
the external reviewer.

**Why this exists (evidence).** AI-authored PRs converge poorly — 33,707 agent
PRs (MSR 2026) merge instantly or else churn in iterative review ("approval
churning", author ghosts the reviewer). A pre-submission self-review cuts review
time ~28%. The bottleneck is the *review loop*, not the writing. See
`.ai/2026-07-30-pr-turnaround/reports/reports-pr-turnaround-review-gaps.md`.

`receiving-code-review` tells you how to fix each finding. This skill is the loop
*around* those fixes — how to close a round so no free round is spent.

---

## The Iron Law (strong default, explicit override)

```
NEVER re-trigger an external reviewer until an INTERNAL self-review pass
comes back CLEAN on the CURRENT diff.
```

**Override:** allowed only for a genuine emergency, and only with an explicit
reason recorded in the PR thread (e.g. `override: hotfix for active SEV-1, internal
review deferred to follow-up`). Absent that recorded reason, the gate is binding.
The default is: do not override.

---

## The loop — run every round, not just the first

```
0. MEASURE  — before BATCH, re-run the check below against the branch's
              base. Every round, not just before the first submission — a
              branch can drift through many individually-small,
              individually-justified rounds that never re-trigger a
              one-time, first-submission-only gate.
              COHESION — "is this still one describable change?"
                 (design-principles' Cohesion test, applied to the whole
                 branch, not one module). Picked up a second or third
                 concern since the last round? Flag it for a split
                 conversation now — don't wait for merge to notice.
1. BATCH   — collect EVERY open finding across all threads and all reviewers.
             Do NOT fix comment-by-comment. Do NOT push per comment.
2. FIX     — one pass. For each finding apply receiving-code-review:
             verify → fix → Pattern Propagation Check (parity checklist,
             shared-helper blast radius, concurrency determinism) →
             Proportionality Gate (is fixing this NOW still proportional,
             or does it deserve its own ticket?).
3. SELF-   — dispatch pr-reviewer / security-reviewer (or /scout-pr-review)
   REVIEW    against the CURRENT diff, explicitly instructed to:
               • hunt the SAME failure classes already found in this PR
                 (name each one — do not say "review the diff")
               • hunt anything the FIX itself introduced (regressions,
                 new edge cases, broken call sites)
4. CONVERGE — if the internal pass returns findings, go back to step 2.
5. PUSH ONCE — only when internal review is clean: a single push, THEN
              re-trigger the external reviewer.
6. RECEIPT  — after the push, report cumulative commits and LOC delta vs
              base since the branch opened. Unconditional, every round —
              so growth is visible before it forces the question three
              rounds later instead of at round one.
```

**Never:** push after each comment · re-trigger the external bot before the
internal pass is clean · reply "fixed" before the fix is verified · skip step
0 because this round felt small — cumulative growth is exactly what it exists
to catch.

---

## Why batch + push-once

Comment-by-comment burns one round per comment: every push re-runs the external
reviewer and CI. Batching every open finding into one verified push means **one
clean push = one external round.** The external reviewer should see the PR once
more and find nothing — that is a closed loop.

---

## Make the self-review dispatch adversarial — cold, not generic

A generic "review this diff" re-scan misses the cluster. Name the failure classes
this PR already exhibited, and tell the reviewer to assume the fix introduced new
ones:

> "This PR already had a missing-nil-check on one handler and a result-ordering
> bug in the parallel path. Hunt EVERY analogous path for both classes across the
> diff, and separately hunt anything these two fixes just introduced — a broken
> call site, a new race, a changed default. Assume the fix is guilty until the
> adversarial case proves otherwise."

This is the `karpathy` *Verify Load-Bearing Claims* posture turned on your own
fix: build the smallest input that would falsify "it's fixed now" before you
believe it.

**Scope bound:** "hunt anything the fix introduced" means close *this* round
cleanly — regressions, broken call sites, new edge cases from the actual
diff. It is not license to harden everything imaginable adjacent to the fix.
A real, in-scope finding that would need a disproportionate rewrite to
"fully" close goes through `receiving-code-review`'s Proportionality Gate —
simpler fix now, or a follow-up ticket — not into this round.

---

## Receiving comments on an existing PR (not just opening one)

This binds to a PR **already in review**, not only a fresh submission. When a
reviewer leaves N comments on an open PR: batch all N, fix in one pass,
self-review, push once, re-trigger — never a push-and-reply per comment. Reply to
each thread only after the single verified push, so every "fixed" reply points at
code that is already proven and already pushed.

**Cold session re-entry:** if the first substantive message in a session
references an existing PR, bot comments, or "address the review," that
session is re-entering this loop at whatever round it's already in — not
starting fresh. Run step 0 (MEASURE) immediately, before the first fix, even
before you know the branch's full history. A branch that grew past the PR
Size Gate through several prior sessions is invisible to a new session unless
it measures on entry instead of assuming the diff in front of it is the whole
story.

Surface this Iron Law in a project's `CLAUDE.md` PR Review Protocol so it binds in
every repo the harness touches, not just this one.

---

## Integration

- **receiving-code-review** — how to fix and verify each finding (verify before
  implementing, Pattern Propagation Check, parity/blast-radius/concurrency,
  Proportionality Gate). This skill wraps the loop around those per-finding fixes.
- **requesting-code-review** — the internal self-review in step 3 uses the same
  reviewer roster; dispatch via that skill's agents.
- **engineer** — the Universal-constraints zero-round bullet points here for any
  lane that receives review feedback.
