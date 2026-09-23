---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development (TDD)

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

**Violating the letter of the rules is violating the spirit of the rules.**

## When to Use

**Always:**
- New features
- Bug fixes
- Refactoring
- Behavior changes

**Exceptions (ask your human partner):**
- Throwaway prototypes
- Generated code
- Configuration files

Thinking "skip TDD just this once"? Stop. That's rationalization.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Implement fresh from tests. Period.

## Red-Green-Refactor

```dot
digraph tdd_cycle {
    rankdir=LR;
    red [label="RED\nWrite failing test", shape=box, style=filled, fillcolor="#ffcccc"];
    verify_red [label="Verify fails\ncorrectly", shape=diamond];
    green [label="GREEN\nMinimal code", shape=box, style=filled, fillcolor="#ccffcc"];
    verify_green [label="Verify passes\nAll green", shape=diamond];
    refactor [label="REFACTOR\nClean up", shape=box, style=filled, fillcolor="#ccccff"];
    next [label="Next", shape=ellipse];

    red -> verify_red;
    verify_red -> green [label="yes"];
    verify_red -> red [label="wrong\nfailure"];
    green -> verify_green;
    verify_green -> refactor [label="yes"];
    verify_green -> green [label="no"];
    refactor -> verify_green [label="stay\ngreen"];
    verify_green -> next;
    next -> red;
}
```

### RED - Write Failing Test

Write one minimal test showing what should happen.

<Good>
```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```
Clear name, tests real behavior, one thing
</Good>

<Bad>
```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```
Vague name, tests mock not code
</Bad>

**Requirements:**
- One behavior
- Clear name
- Real code (no mocks unless unavoidable)

### Verify RED - Watch It Fail

**MANDATORY. Never skip.**

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

**Test passes?** You're testing existing behavior. Fix test.

**Test errors?** Fix error, re-run until it fails correctly.

### GREEN - Minimal Code

Write simplest code to pass the test.

<Good>
```typescript
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === 2) throw e;
    }
  }
  throw new Error('unreachable');
}
```
Just enough to pass
</Good>

<Bad>
```typescript
async function retryOperation<T>(
  fn: () => Promise<T>,
  options?: {
    maxRetries?: number;
    backoff?: 'linear' | 'exponential';
    onRetry?: (attempt: number) => void;
  }
): Promise<T> {
  // YAGNI
}
```
Over-engineered
</Bad>

Don't add features, refactor other code, or "improve" beyond the test.

**Before moving to REFACTOR:** document every public construct added — apply `code-documentation` (full docstring, `@spec_id`, `@req_id`).

**If this component has external dependencies (database, queue, cache, external HTTP):** after GREEN, invoke `integration-testing` skill. Unit tests verify logic; integration tests verify the contract with real dependencies. A mock at the DB boundary is a unit test, not an integration test. Write both.

### Verify GREEN - Watch It Pass

**MANDATORY.**

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

**Test fails?** Fix code, not test.

**Other tests fail?** Fix now.

**"Other tests" means the project's suite, not just your file.** A green run of the test you wrote is not a green suite. Before calling the change done, run the project's bare test command (`npm test`, `pytest`, `cargo test`, `go test ./...` — whatever the repo uses) even when your task named one test file. A scope statement bounds the deliverable, not your verification. Any failure that run shows — including one you didn't cause — goes in your report by name. A red test you watched scroll past and didn't mention is a report falsified by omission.

### REFACTOR - Clean Up

After green only:
- Remove duplication
- Improve names
- Extract helpers

Keep tests green. Don't add behavior.

### Repeat

Next failing test for next feature.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Shows intent** | Demonstrates desired API | Obscures what code should do |

## Test Design: Finding Errors, Not Confirming Success

Testing is the process of executing a program with the intent of finding errors (Myers, 1979). Design each RED test to be *likely to fail* on a wrong implementation. A test that passes regardless of whether the implementation is correct is not a test — it is noise.

**Exhaustive testing is impossible.** Even for trivial programs, the number of possible input combinations exceeds what can ever be tested completely. This is not a limitation to work around — it is a fundamental constraint that determines your entire approach. Because you cannot test everything, you must choose strategically. Two complementary strategies cover the space:

### Black-box strategy (derive from the spec)

Treat the component as a black box: you know inputs and expected outputs; you do not look at the implementation. Apply before writing each RED test.

**Boundary value analysis** — bugs cluster at edges. For any range, test below, at, and above:
- Max retries = 3: test 2 failures (still retrying), 3 failures (exhausted), 4 calls (must not happen)
- Field max length = 255: test 254 chars (valid), 255 (valid), 256 (rejected)

**Equivalence partitioning** — group inputs that behave identically; test one from each group, not ten from one:
- Email validation: valid format / invalid format / empty / whitespace-only — four groups, four tests

**Error guessing** — target where bugs actually hide:
- Null / zero / empty inputs
- Off-by-one conditions (`<` vs `<=`)
- Concurrent access (two requests hitting the same record)
- Partial failure (first step succeeds, second throws — is state consistent?)

### White-box strategy (derive from the code)

After GREEN, look at the implementation. Use the code structure to find paths that black-box analysis missed.

**Branch coverage** — every `if`/`else`/`switch` branch exercised at least once. An untested branch is an untested behavior.

**Path coverage** — for functions with multiple conditionals, each combination of branches is a distinct execution path. Test paths that combine edge conditions, not just the most common sequence.

**Condition coverage** — for compound conditions (`if (a && b)`), test each sub-expression independently so a bug that changes `&&` to `||` is caught:
- `a=true, b=true` / `a=true, b=false` / `a=false, b=true`

**Property-based testing** — for a function with a checkable invariant (round-trip, idempotence, an algebraic law — parsers, serializers, sort/dedup/normalize logic), hand-picked examples under-sample the input space no matter how many you add one at a time. Invoke the `property-based-testing` skill instead of writing more example cases.

Write a new RED test for every uncovered branch or path white-box analysis reveals. If you can only think of happy-path tests, the interface may be hiding its error contracts from callers. Listen to that signal.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests written after pass immediately — which proves nothing. They may test the wrong thing, test the implementation instead of the behavior, or miss the edge case you forgot. You never watched it fail, so you never proved it can catch the bug. Test-first forces that failure. |
| "Tests after achieve same goals (spirit not ritual)" | Tests-after answer "what does this do?"; tests-first answer "what should this do?" Tests written after are biased by the code you already wrote — you verify the cases you remembered, not the ones you'd have discovered. Coverage without proof the tests work. |
| "Already manually tested" | Manual testing is ad-hoc: no record of what you covered, no way to re-run it when the code changes, easy to forget cases under pressure. "Worked when I tried it" ≠ comprehensive. Automated tests run the same way every time. |
| "Deleting X hours is wasteful" | Sunk cost fallacy — that time is already spent either way. The real choice: rewrite with TDD (high confidence) vs. keep it and bolt tests on after (low confidence, likely bugs). Keeping code you can't trust is the waste. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = design unclear" | Listen to test. Hard to test = hard to use. |
| "TDD will slow me down" | TDD IS the pragmatic path: catches bugs before commit, prevents regressions, lets you refactor without fear. "Pragmatic" shortcuts mean debugging in production — slower, not faster. |
| "Manual test faster" | Manual doesn't prove edge cases. You'll re-test every change. |
| "Existing code has no tests" | You're improving it. Add tests for existing code. |

## Red Flags - STOP and Start Over

- Code before test
- Test after implementation
- Test passes immediately
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "Keep as reference" or "adapt existing code"
- "Already spent X hours, deleting is wasteful"
- "TDD is dogmatic, I'm being pragmatic"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**

## Example: Bug Fix

**Bug:** Empty email accepted

**RED**
```typescript
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' });
  expect(result.error).toBe('Email required');
});
```

**Verify RED**
```bash
$ npm test
FAIL: expected 'Email required', got undefined
```

**GREEN**
```typescript
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: 'Email required' };
  }
  // ...
}
```

**Verify GREEN**
```bash
$ npm test
PASS
```

**REFACTOR**
Extract validation for multiple fields if needed.

## Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Test cases cover boundary values, equivalence classes, and error inputs — not just happy paths
- [ ] Self-grading check (mandatory when no independent reviewer runs on this change — e.g. the quick-fix lane, which skips `requesting-code-review`): for every assertion just written, ask "would this fail if the implementation were subtly wrong — off-by-one, inverted condition, wrong error code, swallowed exception?" An assertion that can't clear that bar is exactly what `test-quality-reviewer` exists to catch (testing a mock, trivial assertion, happy-path-only, asserting an implementation detail) — rewrite it now, before commit, since no one else will check
- [ ] Test-strength gate: mutation score meets the threshold (Stryker/PIT/mutmut), not just line coverage — a green suite with a low mutation score is tautological (`verification-before-completion` Test-Strength Gate)
- [ ] Every public construct has full docstring, `@spec_id`, `@req_id` (code-documentation)
- [ ] Linter gate passed: format check + lint + type check for this language — zero issues, no new suppressions (run `verification-before-completion` linter gate, dispatch `linter-reviewer`)
- [ ] If component has external dependencies: integration tests written using `integration-testing` skill (Testcontainers, no mocks at boundary, transaction rollback isolation)

Can't check all boxes? You skipped TDD. Start over.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Debugging Integration

Bug found? Write failing test reproducing it. Follow TDD cycle. Test proves fix and prevents regression.

Never fix bugs without a test.

## Writing Good Tests

When writing or changing any test, read [writing-good-tests.md](writing-good-tests.md) for the rules that keep tests honest:
- Name the production change that would make the test fail — before writing it
- Assert on real behavior, never on mock behavior
- Keep test-only code in test utilities, out of production classes
- Understand a dependency's side effects before mocking it

## Final Rule

```
Production code → test exists and failed first
Otherwise → not TDD
```

No exceptions without your human partner's permission.
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
