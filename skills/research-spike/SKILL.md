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

### Phase 3.5 — Decision Quality Self-Gate (mandatory)

The spike artifact drives a build-or-kill decision, so it must clear a gate before it is presented — the same standard as a spec's self-review. Unlike code, this artifact has no downstream reviewer to catch a bad call; the gate is here or nowhere.

Run this checklist against the artifact. Every item must pass or the artifact is not ready to present:

1. **No fabricated evidence.** Every `Evidence:` line cites a *real, re-runnable or verifiable* source — a benchmark you actually ran (with the command/infra noted), a doc URL, a prototype result, a linked case study. A plausible-looking number with no source is the AI failure mode this gate exists to stop (SDD-2025: "spec quality equals output quality" — a spike's output is only as good as its evidence). Delete or mark any number you cannot back.
2. **Riskiest assumption addressed.** The single riskiest assumption from Phase 2 was either validated by the prototype, or is explicitly listed under Open questions as untested — never silently assumed.
3. **Decision is falsifiable.** The recommendation names the decision criteria it met. "Feels right" is not a decision; "meets the 50k events/sec criterion, measured at 62k on the staging tier" is.
4. **Caveats stated.** Benchmarks on non-representative infra (e.g. localhost), short time budgets, or partial coverage are noted as caveats, not hidden.
5. **Confidence matches evidence.** `Confidence: high` requires evidence for every option; if a load-bearing option rests on an untested assumption, confidence is `medium` or `low`.

If any item fails, fix the artifact before Phase 4. If the honest answer is "not enough evidence to decide," that is outcome 2 below — say so; do not manufacture confidence.

### Phase 4 — Present and close

Present findings. Three outcomes:

1. **Decision clear** → artifact committed to `.ai/` (or `wiki/architecture/`), spike branch deleted. If continuing to build: re-invoke `/engineer "<task>"` with the artifact as context. **If the decision is architectural (new service, data model, external integration, security boundary), the build does not start from the spike artifact directly — it enters `high-level-design`, where the ADR and its consequences are gated by `hld-reviewer`.** The spike self-gate proves the decision is honest; the HLD gate proves the architecture is sound. A kill / "don't build" decision (outcome 3) needs only the self-gate.
2. **Decision blocked on more info** → artifact states what is missing and why. Spike ends; human decides next step.
3. **Decision is "don't build this"** → artifact states why. This is a valid and valuable outcome — it prevents the wrong work.

## What ships

Only the artifact. Spike code is deleted or left in a dead branch (`spike/<topic>`) — never merged to main. The artifact captures the learning; the code was scaffolding.

## Red flags

- Spike expanding into full implementation → STOP. Re-invoke `/engineer "<task>"` with the decision as context.
- Artifact saying "we need more time" with no decision → the question was too large; split it.
- Prototype code "might be useful later" → delete it. The artifact has the learning.
- Benchmarking on localhost instead of representative infra → results are misleading; note caveat in artifact.
