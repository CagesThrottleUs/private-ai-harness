# ADR Format and Rules

Moved verbatim from `SKILL.md` (private-ai-harness 5.0.0) to keep the skill
under the 20,000-byte limit Claude Code applies when it re-attaches skills
after compaction. Read it at the step that points here.

## ADR Format

Save each to: `wiki/architecture/ADR-NNN-<kebab-title>.md`

ADR numbering is global and monotonic across the project — check existing ADRs before assigning a number.

````markdown
# ADR-NNN: [Decision Title]

**Status:** Proposed | Accepted | Rejected | Deprecated | Superseded by ADR-NNN
**Date:** YYYY-MM-DD

## Context and Problem Statement

[What forces are at play? What constraints exist? What problem triggered this decision?
Be specific — the context explains why this decision was non-obvious and why a reasonable engineer could have picked differently.]

## Considered Options

- **Option A:** [name — one sentence]
- **Option B:** [name — one sentence]
- **Option C:** [name — one sentence]

## Decision Outcome

**Chosen: Option A** — [one sentence rationale tied to a specific property required by the spec or NFRs]

### Consequences

**Positive:**
- [specific benefit]

**Negative:**
- [specific trade-off — not "it's harder" but "requires X which costs Y"]

**Neutral:**
- [observation about the decision's implications]

## Options Analysis

| Option | Key Strength | Key Weakness | Eliminated Because |
|--------|-------------|--------------|-------------------|
| A (chosen) | [specific strength] | [acknowledged weakness] | — |
| B | [specific strength] | [specific weakness] | [specific disqualifying property] |
| C | [specific strength] | [specific weakness] | [specific disqualifying property] |
````

**ADR rules (from Nygard / AWS):**
- ADRs are **immutable once Accepted**. If a decision changes, supersede — do not edit.
- To supersede: add `**Superseded by:** ADR-NNN` at the top, change status to `Superseded`.
- One decision per ADR. Compound decisions get two ADRs.
- Status values: `Proposed → Accepted | Rejected | Deprecated | Superseded by ADR-NNN`
