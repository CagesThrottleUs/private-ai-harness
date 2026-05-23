# .ai/

Ephemeral AI work artifacts. Think of this as `%TEMP%` for AI-driven development.

Anyone — human or AI — can read or write here. The distinction from `wiki/` is not who writes it: it's that `.ai/` contains **one-time artifacts** tied to a specific work session or feature cycle, not living product documentation.

Contents here go stale by design. A spec written for a feature in March is not updated in June — it's an audit trail, not a source of truth.

## Structure

```
.ai/
├── specs/           # Feature design specs (YYYY-MM-DD-feature.md)
├── plans/           # Implementation plans (YYYY-MM-DD-feature.md)
├── requirements/    # Requirement registry and REQ→test traceability
└── reports/         # Quality gate reports, drift detection, review output
```

## What Goes Here

| Content | Location | Lifecycle |
|---------|----------|-----------|
| Feature design specs | `.ai/specs/` | Written during brainstorming; archived after ship |
| Implementation plans | `.ai/plans/` | Written before coding; audit trail after |
| Requirement traceability | `.ai/requirements/` | REQ-NNN → TC mapping; updated per feature |
| Spec quality gate reports | `.ai/reports/` | One per gate run |
| Code / spec review results | `.ai/reports/` | One per review pass |

## What Does NOT Go Here

Anything a developer would open to understand the current product → `wiki/`.

`.ai/` is the paper trail. `wiki/` is the map.
