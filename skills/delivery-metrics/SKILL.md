---
name: delivery-metrics
description: >
  Use to score the harness's own delivery performance — DORA four keys plus
  reliability and Flow Framework flow efficiency — derived from the work-item
  manifest phase timestamps and the engineer cost-ledger that already exist.
  Invoke after delivering work, or periodically, to answer "how fast and how
  reliably are we shipping?" — not "how many tokens did it cost."
---

# Delivery Metrics — DORA + Flow

The harness measures its own *token cost* (engineer cost-ledger) but never its
own *delivery performance*. This skill closes that: it derives the industry
delivery signals from data the harness already writes, so "measure what you
shipped" becomes a report, not a guess.

**Standards anchored:** DORA (four keys + reliability), Flow Framework (flow
efficiency / time / load), SPACE / DX Core 4 (human signals — only when a
human-in-loop signal exists).

> **These are delivery metrics, not a business north-star.** They answer "how
> fast and how reliably do we ship," never "did the feature succeed." An elite
> DORA band is a healthy machine, not a moved needle — the business outcome is
> `outcome-review`'s job, measured against the spec `north_star`. See
> `AGENTS.md` → *Metrics vocabulary*. Never present a key here as evidence a
> shipped feature achieved its goal.

## The metric set

### DORA — the four keys + reliability

Bands are the **2024 DORA State of DevOps performance clusters** (elite / high /
medium / low), not invented thresholds.

| Metric | Definition | Elite | High | Medium | Low |
|---|---|---|---|---|---|
| Deployment frequency | Delivered work-items reaching `phase: done` per unit time | On-demand (multiple/day) | Daily–weekly | Weekly–monthly | < monthly |
| Lead time for change | First commit / work-item created → deployed | < 1 day | 1 day–1 week | 1 week–1 month | 1–6 months |
| Change failure rate | Deployments causing degraded service (linked incident) ÷ total | < 5% | 0–15% | 0–15% | 46–60% |
| Failed-deployment recovery (MTTR) | Incident start → service restored | < 1 hour | < 1 day | < 1 day | 1 week–1 month |
| Reliability (5th key) | Meeting the service's SLO / staying in error budget | SLO met, budget not exhausted | — | — | — |

**AI-age caveat (why the stability keys matter more, not less):** the 2024 DORA
report found a **25% increase in AI adoption associated with ~1.5% lower
throughput and ~7.2% lower delivery *stability*** — "teams shipped more code but
broke more things." AI raises apparent velocity while pushing change failure
rate and MTTR the wrong way. So when deployment frequency and lead time improve
under AI assistance, **read CFR and MTTR as the guardrail** — velocity gains that
degrade stability are the documented AI failure mode, and small batch sizes plus
robust testing are the documented mitigations.

### Flow Framework — flow of value (Kersten)

| Metric | Definition |
|---|---|
| Flow efficiency | **active time ÷ total flow time** (the standard lean formula). Active vs wait is a *workflow-state* distinction — value-adding work vs queued/blocked — not a time-gap guess. Typical software teams run **15–40%**; top orgs reach **40–50%**; most start **below 10%**. |
| Flow time | work-item created → done (wall clock) |
| Flow load | work-items in-progress at once (WIP — ties to `portfolio-management`) |

## Data sources (already written by the harness)

- **Work-item manifests** `.ai/work/<id>/manifest.md` — `phase:` transitions.
- **Engineer cost-ledger** `~/.claude/private-ai-harness/engineer-cost-ledger.jsonl`
  (or `$CODEX_HOME/...`) — one row per phase checkpoint with a timestamp. The
  first→last timestamp gives **cycle/flow time** directly. **Flow efficiency
  additionally needs active work time**: `cost-checkpoint` should record
  `active_seconds` per step (its `start`→`end` delta). Without `active_seconds`
  the report *withholds* flow efficiency rather than approximating it — a
  time-gap heuristic is not the flow-efficiency formula.
- **git** — commit timestamps for lead time; merge commit for delivery time.
- **Incident artifacts** `.ai/` / `wiki/` postmortems and `observability`
  SLO docs — for change failure rate, MTTR, and reliability (the two DORA keys
  that need a failure signal, which timestamps alone cannot supply).

## Deriving the report

Run the report script (from this skill's directory):
```bash
scripts/dora-report [--since 30d] [--repo owner/name] [--ledger PATH]
```
It groups the cost-ledger by `session_id` and prints the **timestamp-derived**
keys (deployment frequency, harness cycle time, and flow efficiency *iff*
`active_seconds` is present). DORA **lead time** (commit→deploy), **change
failure rate**, **MTTR**, and **reliability** come only from the delivery
ledger; without it the script prints `needs delivery ledger` /
`needs incident linkage` rather than a fabricated number.

**Never fabricate a key.** Deployment frequency and cycle time come free from
the timestamps. Flow efficiency needs captured active time. Lead time, CFR,
MTTR, and reliability need a real change/failure signal. Report any of these as
unavailable until its input exists rather than reporting a 0.

## The delivery-metrics ledger (auto-populated from real events)

The failure-dependent keys (lead time, change failure rate, MTTR, reliability)
need a real change/failure signal. That signal is now **recorded from the events
that actually produce it**, not hand-edited — `scripts/delivery-record` upserts
one row per work-item into `~/.claude/private-ai-harness/delivery-ledger.jsonl`
and is fired at the moments the harness already passes through:

| Event | Fired by | Records |
|---|---|---|
| `deploy` | `finishing-a-development-branch` on merge/deploy | `created_at`, `merged_at`, `deployed_at` |
| `incident-start` | `incident-response` when an incident linked to this work-item is declared | `caused_incident=true`, `incident_start` |
| `incident-resolve` | `incident-response` when that incident is resolved | `restored_at` |
| `slo` | `observability-standards` / `outcome-review` | `slo_met` |

```bash
scripts/delivery-record deploy --work-item 2026-07-25-slug
scripts/delivery-record incident-start   --work-item 2026-07-25-slug
scripts/delivery-record incident-resolve --work-item 2026-07-25-slug
scripts/delivery-record slo --work-item 2026-07-25-slug --met true
```

Row shape:
```json
{"work_item": "2026-07-25-slug", "repo": "owner/name",
 "created_at": "...", "merged_at": "...", "deployed_at": "...",
 "caused_incident": false, "incident_start": null, "restored_at": null,
 "slo_met": true}
```
`dora-report` prefers this ledger when present. Because it fills from the deploy
and incident events themselves, CFR and MTTR reflect what happened rather than
what someone remembered to log — the difference between a real DORA read and a
fabricated one. Without any recorded event, only the timestamp-derived keys are
reported (never a fabricated 0).

## Review Gate

Before relying on the report — feeding it to `portfolio-management`, an
error-budget decision, or a stakeholder — capture it to a file and dispatch the
reviewer:

```
Agent(delivery-metrics-reviewer, {
  REPORT_PATH: ".ai/reports/YYYY-MM-DD-delivery-metrics.md",
  LEDGER_PATH: "~/.claude/private-ai-harness/delivery-ledger.jsonl"  // omit if none
})
```

This is the one producing skill that used to self-score with no independent
gate. The reviewer is mechanical (Sonnet): it confirms the DORA bands match the
2024 clusters, that no failure-dependent key was fabricated when its signal is
absent, that flow efficiency is formula-correct or withheld, that every key
cites its source, and that no delivery metric is presented as a business
outcome. Fix any **Critical** finding before the report is used — a fabricated
key is worse than a withheld one.

## Interpreting

- Report the four keys as an elite/high/medium/low band, not a bare number.
- Flow efficiency below ~15% means wait time between phases dominates —
  point the improvement at the slowest inter-phase gap, not at working faster.
- Feed change failure rate and MTTR back into `incident-response` and the
  error-budget policy (`observability-standards`).

## Integration

- **engineer:** invoke after a delivered work-item, or run periodically across
  the cross-repo ledger.
- **portfolio-management:** flow load (WIP) and lead time feed portfolio WIP
  limits and WSJF cost-of-delay.
- **incident-response / observability-standards:** supply the failure signal
  for CFR, MTTR, and reliability.
