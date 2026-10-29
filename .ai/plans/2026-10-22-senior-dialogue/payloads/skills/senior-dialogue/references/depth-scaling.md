# Depth Scaling — reasoning, not a lookup table

How much to discuss is itself a decision, and you make it at runtime for this
work item. Do not copy numbers from this file. Derive them from what you found
in the codebase, what the human told you, and sources you can cite. Show the
reasoning so the human can challenge an input instead of a conclusion.

## The question to answer per topic

> If we skip this conversation and our current understanding turns out wrong,
> how much rework or damage do we expect, and is that clearly more than the
> human's time to discuss it?

Answer with these parts, in the card or in D-000's agenda table:

1. **How likely we are wrong right now**, and why. Point to the evidence you
   have (verified in code? stated by the human? inferred? assumed?). A
   probability with no stated basis is not acceptable.
2. **What it costs if we are wrong and find out late.** Name the blast radius
   concretely: which files, components, consumers, data, users, or obligations
   would have to change or would be hurt. Estimate in hours, money, or incident
   terms, whichever fits, and say where the estimate comes from.
3. **How reversible it is.** Two-way door (cheap to undo) or one-way door
   (expensive or impossible to undo: data model, public contract, external
   commitment, security posture, irreversible data operations). Explain why.
4. **How much a discussion is likely to catch.** Cite something when you can,
   for example inspection and review effectiveness studies. Otherwise state
   your assumption.
5. **The discussion's cost:** roughly how much of the human's attention the card
   needs.
6. **Verdict:** discuss on its own card, fold into a batch card of stated
   defaults, or skip with a reason. One-way doors are never batched.

Order the discussed topics by expected saving, highest first, subject to the
hard ordering constraints in SKILL.md: (a) first, (b) before (c) and (d), and
(h) before any code. When two topics are close, put the one with higher
uncertainty first. Resolving it changes the most downstream estimates.

## Rules that are not negotiable at runtime

- Every number has a stated basis: evidence, a cited source, or an explicitly
  labeled assumption the human can override.
- Uncertainty about an estimate is a reason to show a range, not to omit the
  number.
- If the human disputes an input, recompute with their value. Their correction
  is valuable dialogue, not friction.
- Re-estimate when new evidence arrives. If a lighter lane turns out to contain
  a one-way door, a high-blast-radius change (auth, payments, PII, public API,
  data model), or a topic whose expected saving dwarfs the rest, say so in chat
  and step the depth up by re-presenting D-000. Never silently do more or less.

## Lane defaults (starting points, not math)

| Lane | Default depth | Why it is the default |
|---|---|---|
| quick-fix | D-000 only (root cause + fix + RED test on one card) | the consent floor costs one answer; deeper discussion rarely pays for a reproduced single-symbol defect |
| refactoring | D-000 only (smell, move sequence, test baseline) | behavior is pinned by passing tests; the shape is the only decision |
| research | problem, context, then the recommendation card | the deliverable is a decision, so the decision is what gets agreed |
| task | topics whose expected saving clearly exceeds the discussion cost, usually a, b, d, h | bounded scope, real interfaces |
| epic | all topics a–j, teach-back on one-way doors | many one-way doors, high blast radius |
| portfolio | D-000 + business inputs per epic; each pulled epic runs its own epic dialogue | sequencing is a business judgment |

The runtime reasoning above can move a topic in or out of these defaults. Say
which and why.

## Illustrative examples (calibration only, do not reuse the numbers)

These show the shape of good runtime reasoning. Your numbers must come from the
work item in front of you.

One way to structure the arithmetic is
`expected saving ≈ p(wrong) × cost if wrong × reversibility factor × catch rate`.
Boehm & Basili ("Software Defect Reduction Top 10 List", IEEE Computer 34(1),
2001) report that peer reviews catch about 60% of defects and that fixing a
problem after delivery is often 100× more expensive than during requirements
and design. Bezos's 2015 shareholder letter distinguishes one-way (Type 1) and
two-way (Type 2) decisions. You may cite these if they fit. They are not
defaults.

| Situation (example) | Reasoning sketch | Outcome |
|---|---|---|
| Quick-fix: null check missing, reproduced, cited at `file:line` | p ≈ 0.05 because the root cause was observed. Cost if wrong ≈ 1 h: a one-function revert. Reversible. Saving ≈ 0.03 h, far below one card's ~15 min | batch into D-000 |
| Task: new public function signature with two internal callers | p ≈ 0.25 because callers' needs were inferred, not stated. Cost ≈ 2 days of tests, docs, and callers if wrong. Saving ≈ 2–3 h ≫ 15 min | own card |
| Task: CI already runs lint, unit, and integration on every PR | p ≈ 0.05 with the pipeline file cited. Cost ≈ half a day | batch with evidence |
| Epic: event schema consumed by external teams | p ≈ 0.4 because consumers have not been interviewed. Cost is weeks of migration plus a coordinated external change. One-way door. Saving in the hundreds of hours | own card + teach-back + ADR |
| Epic: datastore choice | p ≈ 0.4 because load and query patterns are only estimated. Cost is a data migration. One-way door | own card + teach-back + ADR |

In every row, the reasoning sketch carries the weight, not the number. A human
who disagrees with "consumers have not been interviewed" can fix the input. A
bare "0.4" gives them nothing to fix.
