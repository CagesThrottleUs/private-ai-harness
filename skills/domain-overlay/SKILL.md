---
name: domain-overlay
description: >
  Use when engineering work sits in a technology domain served by several
  externally-installed, overlapping global skills (e.g. Android/Kotlin/Compose)
  and the agent must decide which specialist wins and in what order. The engineer
  router activates the matching domain overlay inside each construct/test/verify
  step so overlapping global skills stop feeding contradictory guidance.
---

# Domain Overlay

A **domain overlay** is a thin precedence-and-ordering layer over a set of
externally-installed global skills that all trigger on the same technology
domain. The harness's own skills (engineer, workflow, TDD, review) are
domain-agnostic. Global community skills (Android, iOS, backend framework packs)
are domain-deep but **uncoordinated** — many auto-trigger on the same task and
give different, sometimes contradictory, advice.

The overlay resolves that. It does not contain domain knowledge itself; it
routes to the skills that do.

## Why this exists

Auto-trigger by description match has three failure modes when N overlapping
skills are installed for one domain:

1. **Contradiction** — four Compose skills fire on "write this screen" and each
   pushes a different state-management idiom. The agent averages them into mush.
2. **Wrong order** — the agent writes code, skips the test skill, skips the perf
   audit, opens the PR. Reviewer and QE absorb the cost.
3. **Miss** — the correct narrow specialist never triggers because a broad skill
   ate the context first.

A domain overlay converts fuzzy auto-trigger into **deterministic precedence +
ordering + a stated tie-break reason**. The reason is the point: the agent needs
to know *why* one skill wins so it can break ties confidently instead of blending.

## How engineer uses an overlay

`engineer`'s Universal constraints carry one hook:

> When the working files/task match a recognized domain, activate the matching
> `<domain>-advisor` overlay FIRST inside each construct/test/verify step.

The overlay then tells the lane step which installed global skill to consult and
suppresses the ones that would conflict. Engineer's lane structure is unchanged —
the overlay only decides *which specialist fills each already-existing step*.

## Contract every domain instance MUST provide

A domain overlay skill (`<domain>-advisor`) is valid only if it states all four:

1. **Detection signals** — the exact file/marker patterns that mean "this domain
   is active" (e.g. `.kt` files, `build.gradle(.kts)`, `@Composable`).
2. **Precedence table** — for each sub-task, the PRIMARY skill, any support/verify
   skills, and a one-line **tie-break reason** (fresher / sole authority /
   fact-checker-only / measurement-vs-authoring). No row without a reason.
3. **Lane-step mapping** — which skill fires at which engineer lane step
   (comprehension, design, TDD-GREEN, TDD-test, verify).
4. **Pre-review audit gate** — the domain-specific self-audit that runs at
   `verification-before-completion`, before any human/agent review, so smells are
   caught before a reviewer sees them.

## Adding a new domain overlay

1. Copy the four-part contract above into `skills/<domain>-advisor/SKILL.md`.
2. List the installed global skills for that domain and, for every overlap, pick
   a winner with a stated reason (recency, authority, scope).
3. Map each survivor to an engineer lane step.
4. No new engineer hook is needed — the existing Universal-constraints hook
   matches any `<domain>-advisor` by detection signal.

## Precedence heuristics (reusable across domains)

When two skills overlap, pick the winner by, in order:

- **Sole authority** — one skill is the recognized source for that sub-task; it wins.
- **Authoring vs measurement** — a "write it right" skill and a "measure/profile
  it" skill are not rivals; sequence them, do not blend.
- **Fact-checker role** — a skill whose value is verifying an API/signature exists
  is a support role only; it never dictates style.
- **Recency** — for otherwise-equivalent skills, the more recently maintained one
  wins; suppress the stale twin to avoid contradiction.
- **Scope guard** — a skill scoped to a narrower target (KMP-only, Nav3-only)
  fires only when that target is actually present.
