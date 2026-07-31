---
name: outcome-review
description: >
  Use after a feature ships (and at defined checkpoints thereafter) to close the measurement loop — did the north-star and input metrics promised at business-context-intake actually move? Reads .ai/business-context/ success metrics and the PR-FAQ claims, records the realized value vs target for each metric with a cited data source, and renders a verdict: moved / did-not-move / inconclusive-need-more-time. Feeds a persevere / iterate / kill signal back to the portfolio. Runs outcome-review-reviewer to reject any metric that is not backed by a real measured source. This is the leg that makes "measure what you shipped" as pervasive as "write it down" and "review it."
---

# Outcome Review

The harness writes the target down at intake and reviews everything it builds —
but until a feature's promised metric is measured *after* launch, "success" is a
claim, not a fact. This skill closes that loop. It is the third leg of the
harness's meta-principle: **write it down → review it → measure what you shipped.**

Intake sets a north-star metric and input metrics with baselines and targets
(`business-context-intake` §4) and writes a PR-FAQ as if the feature already
launched (§8). Outcome review returns to those exact numbers once real usage
data exists and asks the only question that ultimately matters: *did the value
we promised actually show up?*

## References

- **North Star Framework** (Amplitude / John Cutler) — the NSM is a *leading
  indicator* of business outcomes; if it moves, revenue and retention follow. The
  test of a launch is whether the NSM moved, not whether code shipped.
- **Google HEART framework** (Rodden et al., Google) — Happiness, Engagement,
  Adoption, Retention, Task Success. HEART supplies the *input* metrics a team can
  own to move the NSM. Timeline expectation: Task Success and Engagement typically
  move within 1–2 sprints; Retention and Happiness need 1–3 cohorts (1–3 months).
  Use this to decide whether a flat metric means *failed* or *too early*.
- **Amazon Working Backwards** — the PR-FAQ's customer-outcome claims are
  hypotheses. Working backwards is only complete when you check the realized
  outcome against the press release you wrote before building.
- **Lean Startup (Ries) — validated learning** — the post-launch decision is
  **persevere / pivot(iterate) / kill**, made on measured evidence, not opinion.

---

## When to Use

**Required:**
- After an epic-lane feature reaches production (fires as the last epic-lane step,
  after `delivery-metrics`).
- At each metric's HEART-aligned checkpoint thereafter (see the checkpoint
  schedule below) until a verdict is reached.

**Skip:**
- Bug fixes, refactors, config changes, and internal-only work — these have no
  business-context north-star metric to measure against. (If there is no
  `.ai/business-context/` doc, there is nothing to review; skip.)

**Infer + confirm:**
> "This feature has a north-star metric (`checkout completion → 85%`) with a
> 30-day target. It shipped 32 days ago. Running outcome-review to check whether
> it moved. OK?"

---

## The AI-age failure this guards against

An AI can write a flawless-looking outcome report that says "north-star metric
improved 27%, target met" **with no underlying data** — the same
plausible-but-unverified failure the production-readiness-review guards at launch.
Every metric row in the output MUST cite a real, re-runnable data source (a
dashboard link, a query, an analytics event name + date range). A row without a
source is treated as **not measured**, never as "met." The reviewer rejects the
document if any realized value lacks a source.

---

## Process

### Step 1 — Load the promises

Read `.ai/business-context/YYYY-MM-DD-<feature>.md`:
- §4 north-star metric: baseline, target, measurement method, timeline.
- §4 input metrics (2–4): each baseline/target/method/timeline.
- §8 PR-FAQ: the customer-outcome claims and the *riskiest assumptions* from the
  Internal FAQ — those assumptions are what the data must now confirm or refute.

If the doc has no measurable metric, STOP — that is an intake defect, not an
outcome-review one. Surface it; do not invent a metric retroactively.

### Step 2 — Pick the checkpoint honestly (HEART timeline)

Do not declare failure on a metric that has not had time to move.

| Metric class | Earliest meaningful read | Verdict allowed before then |
|---|---|---|
| Task Success, Adoption, Engagement (input) | ~1–2 sprints post-launch | `inconclusive-too-early` only |
| North-star (value) | its stated timeline | `inconclusive-too-early` only |
| Retention, Happiness | 1–3 cohorts (~1–3 months) | `inconclusive-too-early` only |

If now is before a metric's earliest meaningful read, record
`inconclusive-too-early` and schedule the next checkpoint — do NOT force a verdict.

### Step 3 — Measure each metric against its cited source

For every metric, pull the realized value from its stated measurement method.
Record the source verbatim (dashboard URL / query / event + window). If the
measurement method named at intake doesn't exist yet (no dashboard, no event
instrumented), that is a finding: the metric was **unmeasurable as specified** —
record it and route back to `observability-standards` to instrument it, rather
than guessing a number.

### Step 4 — Render the verdict and the decision

Per metric: `moved` (crossed or trending to target) / `did-not-move` (flat or
regressed past its earliest meaningful read) / `inconclusive-too-early` /
`unmeasurable-as-specified`.

Roll up to one launch decision (Lean Startup):
- **persevere** — NSM moved or is on-track; keep investing.
- **iterate** — input metrics moved but NSM lagging, or vice-versa; the mechanism
  is partly working; adjust and re-measure.
- **kill / roll back** — NSM flat/regressed past its horizon and no input metric
  moved; the hypothesis is falsified. Feed this to the portfolio as a
  cost-of-delay signal against continued investment.

### Step 5 — Feed the loop

- Write the decision into the epic manifest and, if a portfolio exists, into
  `.ai/portfolio/manifest.md` as an input to WSJF re-ranking (a killed hypothesis
  frees WIP; a persevere raises cost-of-delay for follow-ons).
- If any metric was `unmeasurable-as-specified`, open the instrumentation gap
  against `observability-standards`.

---

## Output Format

Save to: `.ai/outcome/YYYY-MM-DD-<feature>.md`

````markdown
# Outcome Review — [Feature Name]

**Date:** YYYY-MM-DD
**Shipped:** YYYY-MM-DD (day N post-launch)
**Business context:** .ai/business-context/YYYY-MM-DD-<feature>.md
**Launch decision:** persevere | iterate | kill/roll-back | inconclusive-too-early

---

## Metrics vs. promise

| Role | Metric | Baseline | Target | Realized | Source (re-runnable) | Verdict |
|------|--------|---------|--------|---------|---------------------|---------|
| North star | [metric] | [x] | [y] | [measured z] | [dashboard URL / query / event+window] | moved / did-not-move / inconclusive-too-early / unmeasurable-as-specified |
| Input | [metric] | | | | | |
| Input | [metric] | | | | | |

*A blank "Realized"/"Source" cell is a `not measured`, never a pass.*

## PR-FAQ assumption check

For each riskiest assumption from business-context §8 Internal FAQ:
- **[assumption]:** confirmed / refuted / still-untested — [evidence, with source]

## Decision rationale

[2–4 sentences: why persevere/iterate/kill. Tie to the measured NSM movement and
the HEART timeline — e.g. "input metrics moved as predicted but NSM read is at
day 12 of a 30-day horizon, so verdict is inconclusive-too-early; next checkpoint
YYYY-MM-DD."]

## Next checkpoint

**Date:** YYYY-MM-DD — [which metrics are still inconclusive-too-early and when
they become readable].
````

---

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review
- Pattern check before re-dispatch: does this finding's pattern recur elsewhere in the artifact? Fix every occurrence in the same pass — a finding that resurfaces next cycle in a new spot is the cost this discipline exists to cut

## Self-Review: Run `outcome-review-reviewer` Agent

After writing the document, before committing:

```
Agent(outcome-review-reviewer, {
  OUTCOME_PATH: ".ai/outcome/YYYY-MM-DD-<feature>.md",
  CONTEXT_PATH: ".ai/business-context/YYYY-MM-DD-<feature>.md"
})
```

Fix all **Critical** findings — chiefly any realized value that lacks a
re-runnable source (fabricated outcome), or a `did-not-move` verdict rendered
before the metric's earliest meaningful read (premature failure).

---

## Commit

```
docs(outcome): record post-launch outcome for [feature name]

[body: WHY — which promised metric this measured, and what the persevere/iterate/
kill decision changes about continued investment]
```
