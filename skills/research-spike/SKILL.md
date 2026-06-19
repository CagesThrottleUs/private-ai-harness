---
name: research-spike
description: >
  Time-boxed investigation for feasibility questions, technology comparisons, design
  documents, or proof-of-concept work. Use when the deliverable is a decision or
  recommendation, not working production code. Invoked by the research lane of /engineer.
  Produces a decision artifact committed to .ai/ or wiki/architecture/. Spike code is
  throwaway.
user-invocable: true
---

# Research Spike

Time-boxed investigation. The deliverable is a decision or recommendation, not production code. Anything written here is throwaway unless explicitly preserved as an artifact.

## Before starting — set the frame

State explicitly before any investigation:

1. **Question:** What specific decision or understanding will this spike answer?
   - Vague: "figure out if we should use Kafka"
   - Specific: "Can Kafka handle 50k events/sec at p99 < 20ms on our infra tier, based on benchmarks and a synthetic prototype?"
2. **Time budget:** hard limit in AI work hours. Stop at the limit even if incomplete.
3. **Decision criteria:** what would make each option the winner?

If the question is vague, turn it into a testable question first.

## Process

### Phase 1 — Map existing context

Run `codebase-comprehension` (inline) on the area affected by the decision.

Also check:
- `gh search code` for how the existing codebase approaches similar problems
- Context7 / vendor docs for current API behavior of each option
- Public benchmarks or case studies (web search) if performance is the question

### Phase 2 — Investigate options

For each option under consideration:

1. What does it require? (dependencies, infra changes, migration cost, team learning curve)
2. What does it solve? What does it leave open?
3. What is the riskiest assumption? Can a minimal prototype validate it?
   - If yes: write the smallest possible prototype — ONE function, ONE file — that validates the single riskiest assumption
   - Prototype lives in `spike/<topic>` branch or a temp file
   - It validates ONE thing only. It is not a feature skeleton.

### Phase 3 — Produce the decision artifact

Write to `.ai/YYYY-MM-DD-<topic>-findings.md`:

```markdown
# Spike: [question answered]
**Date:** YYYY-MM-DD
**Time spent:** Xh
**Decision:** [chosen option | "no decision — more info needed"]
**Confidence:** high / medium / low

## Options evaluated

### Option A: [name]
Fits because: ...
Risk: ...
Evidence: [benchmark link, prototype result, doc citation]

### Option B: [name]
Fits because: ...
Risk: ...
Evidence: ...

## Recommendation
[Chosen option + one-paragraph rationale grounded in evidence above]

## Open questions
[What remains unknown — and whether it matters for this decision]

## If this becomes a task
[The next concrete step: spec X, build Y, configure Z]
```

If the decision involves architecture: write an ADR at `wiki/architecture/YYYY-MM-DD-<topic>-adr.md` instead (same content, ADR format with Status/Context/Decision/Consequences).

### Phase 4 — Present and close

Present findings. Three outcomes:

1. **Decision clear** → artifact committed to `.ai/` (or `wiki/architecture/`), spike branch deleted. If continuing to build: re-invoke `/engineer "<task>"` with the artifact as context.
2. **Decision blocked on more info** → artifact states what is missing and why. Spike ends; human decides next step.
3. **Decision is "don't build this"** → artifact states why. This is a valid and valuable outcome — it prevents the wrong work.

## What ships

Only the artifact. Spike code is deleted or left in a dead branch (`spike/<topic>`) — never merged to main. The artifact captures the learning; the code was scaffolding.

## Red flags

- Spike expanding into full implementation → STOP. Re-invoke `/engineer "<task>"` with the decision as context.
- Artifact saying "we need more time" with no decision → the question was too large; split it.
- Prototype code "might be useful later" → delete it. The artifact has the learning.
- Benchmarking on localhost instead of representative infra → results are misleading; note caveat in artifact.
