# .ai/

Ephemeral AI work artifacts. Think of this as `%TEMP%` for AI-driven development.

Anyone — human or AI — can read or write here. The distinction from `wiki/` is not who writes it: it's that `.ai/` contains **one-time artifacts** tied to a specific work session or feature cycle, not living product documentation.

Contents here go stale by design. A spec written for a feature in March is not updated in June — it's an audit trail, not a source of truth.

## Structure

One shared folder per task/feature, holding all its artifact-type subfolders:

```
.ai/
└── YYYY-MM-DD-feature-slug/
    ├── comprehension.md      # Codebase comprehension (Step 1), single top-level file
    ├── specs/                # specs-<slug>.md
    ├── plans/                # plans-<slug>.md
    ├── requirements/         # REQ→test traceability
    └── reports/              # Quality gate reports, drift detection, review output
```

Exceptions kept standalone at `.ai/` top level (not per-task) because they span
many tasks/epics: `.ai/portfolio/` (cross-epic Kanban) and `.ai/catalog/`
(service registry, maintained by `service-scaffolding`).

## What Goes Here

| Content | Location | Lifecycle |
|---------|----------|-----------|
| Feature design specs | `.ai/<feature-slug>/specs/` | Written during brainstorming; archived after ship |
| Implementation plans | `.ai/<feature-slug>/plans/` | Written before coding; audit trail after |
| Requirement traceability | `.ai/<feature-slug>/requirements/` | REQ-NNN → TC mapping; updated per feature |
| Spec quality gate reports | `.ai/<feature-slug>/reports/` | One per gate run |
| Code / spec review results | `.ai/<feature-slug>/reports/` | One per review pass |

## What Does NOT Go Here

Anything a developer would open to understand the current product → `wiki/`.

`.ai/` is the paper trail. `wiki/` is the map.
