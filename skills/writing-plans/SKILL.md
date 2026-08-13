---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.

**Save plans to:** `.ai/plans/YYYY-MM-DD-<feature-name>.md`
**Spec reference:** Link to `.ai/specs/YYYY-MM-DD-<feature-name>.md` in plan header.
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Design Principles Check

**Before defining file structure:** invoke the `design-principles` skill and run its **Planning Checklist** against the decomposition. This is mandatory — not a suggestion.

The checklist enforces: DRY (no duplicated logic across tasks), KISS (no abstraction layers with one concrete use), YAGNI (no components without a spec REQ backing them), SoC (no file mixing two concerns), loose coupling, SRP, and correct GoF pattern application.

## Karpathy Anti-Pattern Check

**Before finalizing task list:** apply the `karpathy` skill as a mandatory lens over the plan draft.

Catch these before code is written:
- **Unstated assumptions** — each task must name what it assumes. If ambiguous, surface the ambiguity in the task text so the implementer asks before coding.
- **Over-engineering** — no abstractions, flexibility, or error handling not directly required by a spec REQ. If a task has more than one concrete consumer, question the abstraction.
- **Weak success criteria** — every task's verification step must be a concrete, runnable check (command + expected output). "Make sure it works" is a plan failure.
- **Blast radius** — each task should touch only what it must. If a step modifies more than 2 files, consider splitting it.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Each file has one clear responsibility (SRP). If you can't state it in one sentence, split the file.
- Files that change together live together. Split by responsibility, not by technical layer.
- Dependencies flow through interfaces, not concrete types (DIP). No `new ConcreteX()` at call sites.
- **Before finalizing any file boundary, ask: "What difficult design decision or volatile requirement does this file hide?"** A file that can only be described as a step in a sequence ("handle input", "run the sort", "write output") is process-decomposed. Rename it to describe what it hides, or merge it into the module that owns that secret. (Parnas, 1972)
- In existing codebases, follow established patterns. If a file you're modifying has grown unwieldy, include a targeted split in the plan.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Oracle-Independence Gate (Critical-tier tasks only)

**Applies when:** the task implements a REQ that is Critical complexity per
`workflow.md`'s table (auth, payment, PII, or a public API breaking change) —
never to Small/Medium/Large tasks; doubling dispatch cost on every task buys
nothing there. It exists because a single continuous-context agent that both
reasons about the implementation and writes the "independent" RED test isn't
actually independent — an LLM that has already planned the fix in-context
tends to write tests asserting what it's about to build rather than what the
spec requires (the misguidance-effect finding: buggy or intended code already
visible in context steers test generation toward confirming it, not
falsifying it).

**Mark the task** with `**Oracle:** independent` in its header, alongside
`Interfaces:`. This tells `subagent-driven-development` to split the task
into two dispatches instead of one:

1. **Oracle dispatch** — a fresh subagent whose brief contains ONLY the REQ
   statement, its Acceptance Criteria, and its Test Cases from the spec —
   never the current implementation, never a suggested approach, never the
   controller's own reasoning about how to fix it. Its job stops at RED:
   write the failing test(s), verify they fail for the right reason, commit,
   report DONE. It never sees GREEN.
2. **Implementer dispatch** — the normal task brief, plus the oracle's test
   file path, with the instruction: "This test file was written by a
   separate agent from the spec alone, before any implementation existed.
   Make it pass. If an assertion looks wrong per the spec, stop and report
   the discrepancy — do not edit the assertion yourself." Editing the
   oracle's assertions is a Critical task-review finding, not a normal code
   change — it collapses the independence the gate exists to buy.

The task reviewer checks both: does GREEN satisfy the oracle's RED test
unmodified, and does the oracle's test itself pass `test-quality-reviewer`'s
anti-pattern check (3a-3h, or 3i for a property-based oracle test)?
Independence buys nothing if the independent test is vacuous.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec:** [exact path to the spec this plan implements, e.g. `.ai/specs/2026-08-13-feature-design.md` — or "N/A" with reason for a spec-less trivial change. SDD reads this file at setup, so a plan conflict is resolved against the design's actual text, not guessed at.]

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

**North Star:** [copy the spec's `north_star:` value verbatim, and the input
metric from its `## North Star Alignment`. Every task should be answerable to
"which input metric of the north-star does this advance?" — a task that moves
no driver and traces to no REQ is scope creep. If the spec's north_star is
`N/A`, state that here too.]

[Then the spec's other project-wide requirements — version floors, dependency
limits, naming and copy rules, platform requirements — one line each, with
exact values copied verbatim from the spec. Every task's requirements
implicitly include this section.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Document public constructs added** (docstring + `@spec_id` + `@req_id`)

- [ ] **Step 6: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, KISS, SOLID, TDD, frequent commits
- Design principles are enforced by `design-principles` skill — run its Planning Checklist before finalizing structure
- Karpathy lens is enforced by `karpathy` skill — run its anti-pattern check before finalizing task list

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Sequence Diagram Gate

**Before defining tasks for any flow crossing 3+ components:** confirm that `.ai/lld/YYYY-MM-DD-<feature>-sequences.md` exists. If absent and the flow has auth, async, or retry behavior → invoke `sequence-diagram` skill.

Sequence diagrams answer "what does the implementer do when the external service times out?" — a question that cannot be answered from the Container diagram alone.

## API Contract Gate

**Before defining tasks for any HTTP endpoint or gRPC service:** invoke `api-contract-first` skill.

The handler task must not appear in the plan until:
1. The API spec (`api/openapi.yaml` or `proto/**/*.proto`) exists
2. Spectral lint passes
3. `api-contract-reviewer` passes (no Critical findings)
4. Human approves the spec

Reference the spec in every handler task:
```markdown
- [ ] Implement handler per spec: `api/openapi.yaml#paths/~1resources/get`
```

A plan task that says "write the GET /resources endpoint" without a spec reference is a plan failure.

## Plan Review Gate

After the self-review, dispatch `plan-reviewer` agent before offering execution:

```
Agent(plan-reviewer, {
  PLAN_PATH: ".ai/plans/YYYY-MM-DD-<feature>.md",
  SPEC_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md",
  HLD_PATH: ".ai/hld/YYYY-MM-DD-<feature>.md"  // omit if non-architectural
})
```

Fix all **Critical** findings before offering execution. **Important** findings should be fixed but are not blocking. **Advisory** findings may be deferred.

The plan-reviewer runs with fresh context — no brainstorming or spec history. If it finds spec coverage gaps or type inconsistencies you missed in self-review, fix them before dispatching to a subagent.

## Execution Handoff

After plan-reviewer passes, offer execution choice:

**"Plan complete and saved to `.ai/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
- Batch execution with checkpoints for review
