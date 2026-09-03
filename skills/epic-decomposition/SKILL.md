---
name: epic-decomposition
description: >
  Break an approved epic into bounded stories, produce child work-item manifests, and
  identify parallel vs sequential story dependencies. Fires after HLD human approval in
  the epic lane of /engineer. Each child story then runs the task lane independently
  (spec → plan → subagent-driven-development). Human must approve HLD before this skill
  activates.
user-invocable: true
---

# Epic Decomposition

An epic is a system. Decomposition turns it into N bounded stories, each independently executable through the task lane. The output is a dependency graph and a set of child manifests — not exhaustive task lists (those come from `writing-plans` inside each story).

## Hard gate — HLD must be approved by human before this runs

The HLD C4 Container diagram IS the decomposition map. Without it, stories are invented rather than derived. Do not decompose without an approved HLD.

**Inputs required:**
- Approved HLD at `.ai/YYYY-MM-DD-<epic>/hld/hld-<epic>.md` (human-approved)
- Approved spec at `.ai/YYYY-MM-DD-<epic>/specs/specs-<epic>.md`
- Epic manifest at `.ai/YYYY-MM-DD-<epic>/manifest.md`

## Process

### Step 1 — Derive stories from the HLD

Read the HLD's C4 Container diagram. Each container or component maps to one story.

**Rules for a valid story — INVEST + vertical slice:**
- **Vertical slice, not a layer.** Each story delivers an observable change in
  system behaviour end-to-end (it may touch DB + API + UI together). Do NOT split
  by architectural layer — "the data-model story", "the API story", "the UI story"
  are horizontal slices that fail INVEST: none is independently valuable, and they
  force lockstep integration. Split by *user-visible capability* instead.
- **INVEST:** Independent (minimal cross-story coupling), Negotiable, **Valuable**
  (a user or a downstream system is observably better when it's done), Estimable,
  **Small** (fits one task-lane run, ~1 session, 1 PR), **Testable** (a clear
  done-state verifiable in isolation).
- Prefer a **walking skeleton first** — a thin end-to-end slice that proves the
  whole path works — then thicken it with subsequent stories.
- A story may still *produce* an interface another consumes (schema, contract,
  event), but that interface is a byproduct of a valuable slice, not a story unto
  itself.

Split a large capability by the SPIDR patterns: **S**pike, **P**aths (workflow
variations), **I**nterfaces (channels/clients), **D**ata (data variations),
**R**ules (business-rule subsets) — each yielding a vertical, INVEST-passing
slice. Example (notifications epic): "user gets an email on order-ship" is a
vertical slice; "the email templating layer" is not.

### Step 2 — Map dependencies

Draw the dependency graph. For each pair of stories, label the edge:

- **blocks:** story B cannot start until story A's artifact is committed (e.g., B uses A's schema)
- **informs:** B can start in parallel if A's contract is stable, even if A is still implementing

Stories with no upstream blockers form Wave 1 and can run in parallel.

```
A (data model) ──blocks──► B (API)     ──blocks──► D (UI)
                ──blocks──► C (worker)
```

### Step 3 — Create child manifests

For each story, create `.ai/YYYY-MM-DD-<epic>/children/YYYY-MM-DD-<story-slug>/manifest.md`:

```markdown
# Story: [name]
**Parent epic:** YYYY-MM-DD-<epic>
**Tier:** task
**Phase:** not-started
**Gate status:** pending
**Depends on:** [story slugs that must complete first, or "none"]
**Produces:** [interface/artifact/schema downstream stories consume]
**Spec scope:** [REQ-NNN IDs from the epic spec this story covers]
**HLD containers:** [C4 container names this story implements]
```

### Step 4 — Present execution plan to user

```
Epic: [name]
Stories: N total

Dependency waves:
  Wave 1 (parallel): [story A] — produces schema
                     [story B] — produces auth contract
  Wave 2 (parallel): [story C] — needs A's schema
                     [story D] — needs A's schema
  Wave 3:            [story E] — needs B's auth + C's events

Each story runs: codebase-comprehension → spec → plan → SDD belt → verify → PR

Interface artifacts committed before dependent story starts.

Confirm this decomposition, or tell me to adjust story boundaries?
```

Wait for confirmation. Adjust if user sees a story as too broad or too narrow.

### Step 5 — Hand off to task lane

When a wave contains 2+ independent stories, invoke `dispatching-parallel-agents` to coordinate their concurrent task-lane runs instead of executing them one at a time.

For each story (respecting wave order):

1. Re-invoke `/engineer "<story description>"` at task lane with context:
   - Parent epic manifest path
   - This story's child manifest path
   - The HLD section covering this story's C4 containers
   - Interface artifacts produced by upstream stories (schema file, OpenAPI stub, event schema)
2. The task lane (SDD belt) runs independently per story.
3. When a story produces its interface artifact, commit it before the dependent story starts — this is the handoff that unlocks the next wave.

## Red flags

- Stories that "depend on everything" → too broad; split further
- A story with no testable done-state → not a story, it is a task list; decompose more
- Decomposing before HLD human approval → the HLD is the map; invented stories drift from architecture
- Starting Wave 2 while Wave 1 has BLOCKED status → blockers propagate; surface to human before proceeding
- A "story" that is actually just one function → merge it into a sibling story
