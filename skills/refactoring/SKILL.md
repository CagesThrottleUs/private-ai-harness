---
name: refactoring
description: >
  Behavior-preserving code restructuring with a test guard at every step. Use when
  code is correct but has the wrong shape — god class, duplication, deep nesting,
  long method, tight coupling, dead code. Enforces: test baseline before touch, one
  structural move per micro-commit, behavior verified after each move. Zero new
  behavior. Invoked by the refactoring lane of /engineer.
user-invocable: true
---

# Refactoring

Restructure without changing what the code does. The external contract — callers, return values, side effects, error behavior — stays identical. Only internal shape changes.

## The hard rule

**No new behavior. Ever.**

If you find yourself adding a parameter, changing a return type, adding a new code path, or fixing a bug along the way — stop. Commit what you have. Open a new lane for the new behavior. Come back.

Mixing refactor + feature in one commit makes both harder to review and harder to revert.

## Step 1 — Name the smell

Before touching anything, identify the specific structural problem. One refactor session = one named smell.

| Smell | Signal |
|---|---|
| **God class** | One class owns too many responsibilities; hard to test in isolation |
| **Long method** | Method does more than one thing; hard to name accurately |
| **Duplicate code** | Same logic copy-pasted across 2+ locations |
| **Deep nesting** | Arrow anti-pattern; `if`s inside `for`s inside `try`s |
| **Long parameter list** | 4+ parameters; callers pass magic values |
| **Primitive obsession** | Domain concept represented as raw string/int instead of a type |
| **Feature envy** | Method uses another class's data more than its own |
| **Tight coupling** | Module directly imports another's internals |
| **Dead code** | Unreachable branch, unused import, orphaned function |
| **Shallow module** | Interface nearly as complex as the implementation; a pass-through that hides nothing, or many tiny modules to grasp one concept (classitis) |

If you can't name the smell in one phrase, the scope is too large — narrow it.

**Deletion test (for a suspected shallow module):** would deleting it *concentrate* complexity into its caller (it was pass-through indirection — inline it) or merely *move* complexity elsewhere (it was pulling its weight — leave it)? Only "concentrates" is a real deepening opportunity. (see `design-principles`: Prefer Deep Modules to Shallow Ones)

## Step 2 — Comprehension + blast radius

Run `codebase-comprehension` (inline) on the target area:
- Map the symbol(s) to restructure + their callers
- Note `codegraph_impact` — what else references this area
- Identify which tests cover the area (these are your behavior guard)
- If the target wasn't handed to you, prefer recently/frequently-changed files (`git log`) — deepening pays off where change concentrates (YAGNI)

If there are NO tests covering the target area → **STOP**. Refactoring untested code is rewriting, not refactoring. Either write characterization tests first (a valid task) or do not proceed.

## Step 3 — Establish the test baseline

Run the covering tests now, before any change:

```
[run test suite covering target area]
```

All tests must pass. If any fail → **STOP**. Fix failures first via `systematic-debugging` (separate commit, separate lane). Do not refactor broken code.

Record the baseline: N tests, all pass.

## Step 4 — One move at a time

Each structural move follows this micro-loop:

```
1. Make ONE change (extract, inline, rename, move, split, collapse)
2. Run covering tests → must still all pass
3. Commit: "refactor(<scope>): <move in imperative>" with WHY body
4. Repeat
```

**One move = one commit. No exceptions.**

Never batch: extract method + rename class + move file in a single commit. Each move must be independently revertable.

### The catalogue of moves (pick one per loop)

| Move | What it does |
|---|---|
| Extract method | Pull block into named function |
| Extract class | Pull group of methods + fields into new class |
| Inline method/variable | Fold trivial abstraction back into caller |
| Rename | Rename to match actual responsibility |
| Move method/field | Relocate to the class that owns the concept |
| Introduce parameter object | Replace 3+ params with a typed struct |
| Replace conditional with polymorphism | Swap `if type ==` chain for strategy/visitor |
| Collapse nesting | Invert condition + early return to flatten arrow |
| Remove dead code | Delete unreachable branch or unused symbol |

## Step 5 — karpathy lens before each commit

Before committing each move, apply the lens:

- Is this the minimum change that removes the smell? (no over-engineering)
- Did I change any behavior, even accidentally? (run tests, check diff)
- Is the new name more accurate than the old one? (not just different)
- Does this move delete complexity — a branch, a layer, a helper — or only relocate it? Prefer the move that removes concepts; a refactor that just shuffles complexity around hasn't earned the commit. (design-principles: Delete, Don't Rearrange)
- Would a future reader understand why this shape is better?

Stop when the named smell from Step 1 is gone. Do not continue to the next smell in the same session — open a new lane.

## Step 6 — Final verification

After all moves for this smell:

```
[run full test suite, not just covering tests]
```

All tests pass. Run `verification-before-completion` (lint gate). Then the final commit if there are any uncommitted cosmetic cleanups.

## Red flags

- Tests failing after a move → revert the move immediately, do not debug forward
- Commit message describing new behavior → wrong lane, stop
- Session growing beyond one named smell → scope creep, stop and open new lane
- "I'll just fix this bug while I'm here" → no; separate commit, separate lane
- Renaming something without updating all callers → `codegraph_impact` first
- Skipping the test baseline → this is the whole safety net; skipping it makes it rewriting
---

## Completion Report

When this skill's work is done, report to the user in chat — do not let a commit
message be the only trace of what happened:

- **Produced:** what was created or changed (artifact type + exact path).
- **Verdict:** the reviewer's PASS / NEEDS WORK / BLOCKED result, if a gate ran.
- **Coverage:** which spec REQ / NFR this satisfies, where applicable.
- **Next:** the next step in the flow, or "ready for review / merge".

One line per item is enough. The point is that the user sees what shipped and
its verdict without having to read the diff.
