---
name: portfolio-management
description: >
  Use when there is more than one epic to run — the layer ABOVE a single epic
  that a department needs. Maintains a portfolio of epics in a SAFe Portfolio
  Kanban, ranks them by WSJF (cost of delay ÷ job size), enforces WIP limits
  (Little's Law), tracks cross-epic dependencies, and links each epic to an OKR.
  The engineer PORTFOLIO lane routes here; it pulls the top-ranked epic into the
  epic lane when WIP allows. Runs portfolio-reviewer.
---

# Portfolio Management

A single epic runs end-to-end well in the epic lane, but a department runs
*many* epics against finite capacity. Without a layer above the epic, there is
no prioritization, no WIP discipline, and no cross-epic dependency view — work
starts because it can, not because it should. This skill is that layer.

**Standards anchored:** SAFe **Lean Portfolio Management** — Portfolio Kanban,
**WSJF** prioritization (Reinertsen cost-of-delay), **WIP limits**; **Little's
Law** (Cycle Time = WIP ÷ Throughput); **OKRs** as strategic-theme outcomes.

## The portfolio manifest

Maintain `.ai/portfolio/manifest.md`. One entry per epic:

```
## <epic-slug>
state: funnel | reviewing | analyzing | backlog | implementing | done
okr: <objective / key result this epic advances>
wsjf: <computed>            # cost_of_delay / job_size
  business_value: <1-13>    # relative, Fibonacci
  time_criticality: <1-13>
  risk_reduction_opp_enable: <1-13>
  job_size: <1-13>          # relative duration/effort
depends_on: [<epic-slug>, ...]   # cross-epic edges (must be DAG)
owner: <name>
epic_manifest: .ai/<id>/manifest.md   # once it enters Implementing
```

## Portfolio Kanban — the states

Epics flow through fixed states (SAFe): **Funnel → Reviewing → Analyzing →
Portfolio Backlog → Implementing → Done.**

- **Funnel** — every idea; *no WIP limit* (capturing is free).
- **Reviewing** — is it worth a WSJF estimate? (filters AI-cheap volume — see below)
- **Analyzing** — lightweight business case + `business-context-intake` sketch; WSJF estimated.
- **Portfolio Backlog** — approved, WSJF-ranked, waiting for capacity.
- **Implementing** — actively running in the epic lane.
- **Done** — delivered; feeds `delivery-metrics`.

**Every state except Funnel has a WIP limit.**

## WSJF — how epics are ranked

```
WSJF = Cost of Delay / Job Size
Cost of Delay = Business Value + Time Criticality + Risk Reduction/Opportunity Enablement
```
Estimate each component *relatively* (Fibonacci 1,2,3,5,8,13). Highest WSJF is
pulled first — it maximizes economic return per unit of delay. Do not use raw
effort or gut feel; WSJF is the SAFe-recommended economic sequencing.

## WIP limits — why, and how much

Little's Law: **Cycle Time = WIP ÷ Throughput.** More epics in flight at once
means every epic takes longer to finish. So cap **Implementing** WIP (SAFe
guidance: roughly **1–2 active epics per value stream**; set it to your real
parallel capacity and hold the line). Pulling a new epic is allowed only when
Implementing is below its limit.

## The pull loop

1. When Implementing WIP < limit, pull the **highest-WSJF** epic from the
   Portfolio Backlog whose `depends_on` epics are all `done`.
2. Set it `implementing`, create its epic manifest, and dispatch it via
   `/engineer "<epic>"` at the **epic lane**.
3. On epic completion, set it `done`, record it for `delivery-metrics`, and pull
   the next. Never exceed the WIP limit to "get ahead" — that lengthens every
   in-flight epic's cycle time.

## Cross-epic dependencies

`depends_on` forms a **DAG** — detect and reject cycles. An epic cannot enter
Implementing while any dependency is not `done`. Surface the dependency graph so
sequencing respects it (a high-WSJF epic blocked by a dependency waits; the next
unblocked highest-WSJF epic goes first).

## OKR linkage

Every epic past Funnel names the **OKR** it advances. An epic that advances no
strategic objective is a candidate to drop, not to sequence — surface it.

## AI-age discipline (the WIP limits matter MORE, not less)

- AI makes *starting* work cheap, which tempts unbounded WIP. Little's Law is
  indifferent to how fast you start — more WIP still means longer cycle time,
  and the 2024 DORA report ties undisciplined AI throughput to *lower delivery
  stability*. **Hold the WIP limit regardless of how fast epics can be spun up.**
- AI also makes *proposing* epics cheap — the Funnel can flood. The Reviewing
  gate exists to filter for real value (does it advance an OKR? plausible WSJF?)
  before an idea consumes analysis capacity. Volume is not signal.

## Review

Dispatch `portfolio-reviewer` on the manifest before acting on the ranking. It
checks WSJF is computed (not gut-ranked), every non-Funnel state respects its
WIP limit, `depends_on` is a valid DAG (no cycles), each epic links an OKR, and
the pull order respects both WSJF and dependencies. Pass by file path; one fix
agent for all findings; re-review to PASS.

## Integration

- **engineer (PORTFOLIO lane):** classification above the epic lane; this skill
  runs the Kanban and dispatches the top epic into the epic lane.
- **business-context-intake:** the Analyzing-state business case per epic.
- **delivery-metrics:** consumes Done epics for DORA/flow; flow load (WIP) here
  is the same WIP the limits cap.
