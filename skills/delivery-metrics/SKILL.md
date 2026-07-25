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

## The metric set

### DORA — the four keys + reliability

| Metric | Definition | Elite threshold |
|---|---|---|
| Deployment frequency | Delivered work-items reaching `phase: done` per unit time | On-demand / multiple per day |
| Lead time for change | First commit (or work-item created) → merged/deployed | < 1 day |
| Change failure rate | Deployments causing a degraded service (linked incident) ÷ total deployments | < 5% (elite < 15% band; elite ~5%) |
| Failed-deployment recovery time | Incident start → service restored (MTTR) | < 1 hour |
| Reliability (5th key) | Meeting the service's SLO / staying in error budget | SLO met, budget not exhausted |

### Flow Framework — flow of value

| Metric | Definition |
|---|---|
| Flow efficiency | active work time ÷ (active + wait time) across manifest phases. Most orgs sit at 5–15%; the wait time between phases is the improvement target. |
| Flow time | work-item created → done (wall clock) |
| Flow load | work-items in-progress at once (WIP — ties to `portfolio-management`) |

## Data sources (already written by the harness)

- **Work-item manifests** `.ai/work/<id>/manifest.md` — `phase:` transitions.
- **Engineer cost-ledger** `~/.claude/private-ai-harness/engineer-cost-ledger.jsonl`
  (or `$CODEX_HOME/...`) — one row per checkpoint with a timestamp, so each
  phase has a `start` and `end`. Active time = Σ(end − start); wait time = the
  gaps between a phase's `end` and the next phase's `start`.
- **git** — commit timestamps for lead time; merge commit for delivery time.
- **Incident artifacts** `.ai/` / `wiki/` postmortems and `observability`
  SLO docs — for change failure rate, MTTR, and reliability (the two DORA keys
  that need a failure signal, which timestamps alone cannot supply).

## Deriving the report

Run the report script (from this skill's directory):
```bash
scripts/dora-report [--since 30d] [--repo owner/name] [--ledger PATH]
```
It groups the cost-ledger by `session_id`, joins the manifests, and prints:
deployment frequency, lead time (p50/p90), flow efficiency, and flow time.
Change failure rate, MTTR, and reliability are emitted only if an incident /
deployment linkage file is present — otherwise the script prints
`needs incident linkage` for those rows rather than a fabricated number.

**Never fabricate the failure-dependent keys.** Deployment frequency, lead
time, and flow efficiency come free from the timestamps. CFR, MTTR, and
reliability require a real failure signal; report them as unavailable until
that linkage exists rather than reporting 0%.

## The delivery-metrics ledger (optional enrichment)

To capture the failure-dependent keys, append one line per delivery to
`~/.claude/private-ai-harness/delivery-ledger.jsonl`:
```json
{"work_item": "2026-07-25-slug", "repo": "owner/name",
 "created_at": "...", "merged_at": "...", "deployed_at": "...",
 "caused_incident": false, "incident_start": null, "restored_at": null,
 "slo_met": true}
```
`dora-report` prefers this ledger when present. Without it, only the
timestamp-derived keys are reported.

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
