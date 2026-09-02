---
name: property-based-testing
description: >
  Use during test-driven-development's white-box pass for any function with a checkable
  invariant — parsers, serializers, sort/dedup/normalize logic, encode/decode pairs,
  idempotent operations, anything with a round-trip or algebraic property. Generates
  property-based/fuzz tests (Hypothesis, fast-check, jqwik, proptest, or Go's native
  fuzzing, detected by manifest) instead of hand-picked example inputs. This is the
  single technique SQLite, Redis, and curl credit most directly for finding real bugs —
  example-based unit tests only catch inputs the author thought to write.
---

# Property-Based Testing

Example-based tests check specific inputs the author thought of. Property-based
tests check an invariant across thousands of generated inputs, including ones
no one would think to hand-write — and when one fails, the library shrinks the
failing case to the smallest reproducible counterexample.

**Why this matters more than more example tests:** Salvatore Sanfilippo (antirez),
on Redis's own test suite: "Almost all the bugs discovered thanks to Redis's
test suite were discovered thanks to fuzz tests and very rarely thanks to
regression tests and unit tests." SQLite's dbsqlfuzz and curl's OSS-Fuzz
integration are, by their own account, central to their reliability record.
Property-based testing is the same idea applied at the unit-test layer,
without needing a standalone fuzzing harness or a CI day-job.

## When to Use

Invoke from `test-driven-development`'s white-box strategy step whenever the
function under test has one of these shapes:

- **Round-trip:** `decode(encode(x)) == x`, `parse(serialize(x)) == x`
- **Idempotence:** `f(f(x)) == f(x)` (normalize, dedupe, sort)
- **Invariant preservation:** output length bounds, sortedness, no duplicates, sum/count conservation
- **Algebraic law:** commutativity, associativity, a known mathematical relationship
- **Metamorphic relation:** a known relationship between two calls (`f(x) <= f(x+1)` for a monotonic function) when no single "correct" output is easy to hand-write

**Skip when:** the function's correctness is inherently example-based (a fixed lookup table, a specific business rule with no general law — e.g., "tax rate for state X is 7%"). Forcing a property onto business-rule code produces a vacuous invariant ("output is a number") that the anti-pattern check below exists to catch.

## Detection and Tool Table

| Manifest found | Language | Tool | Install |
|---|---|---|---|
| `pyproject.toml` / `setup.py` | Python | Hypothesis | `pip install hypothesis` |
| `package.json` | TypeScript/JS | fast-check | `npm install --save-dev fast-check` |
| `pom.xml` / `build.gradle` | Java | jqwik | jqwik JUnit 5 extension |
| `Cargo.toml` | Rust | proptest | `cargo add --dev proptest` |
| `go.mod` | Go | native `testing/quick` or `go test -fuzz` | stdlib, Go 1.18+ |

## Writing the Property

1. **Name the invariant in one sentence before writing code** — the same discipline TDD's black-box strategy already requires. "Encoding then decoding returns the original value" is a property; "the function works" is not.
2. **Write the property test, watch it fail on a broken implementation** — same RED-GREEN discipline as TDD. A property test that passes against a deliberately broken implementation is vacuous (mirrors `test-quality-reviewer`'s 3b Trivial Assertion check) — verify it fails before trusting it.
3. **Let the library generate inputs** — do not hand-write the input list; that defeats the purpose. Configure generators for the domain (e.g., "strings", "integers in range", "lists of the domain type") and let the tool explore.
4. **On a failure, commit the shrunk counterexample as a regression test** — every property-testing library shrinks a failing case to its minimal form. That minimal case becomes a permanent example-based regression test (per `test-driven-development`'s "Debugging Integration" rule: never fix a bug without a test) — the property test found it, the example test guards it forever.

### Example (Python / Hypothesis)

```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers()))
def test_sort_is_idempotent(xs):
    once = sorted(xs)
    twice = sorted(once)
    assert once == twice

@given(st.text())
def test_round_trip_encoding(s):
    assert decode(encode(s)) == s
```

## Anti-Pattern: Vacuous Properties

The same failure mode `test-quality-reviewer` catches in example-based tests
has a property-based form — worse, because it looks more rigorous:

- **Property that's always true regardless of implementation:** `assert isinstance(result, str)` as the only check — this is 3b (Trivial Assertion) wearing a fuzzing costume.
- **Property that re-derives the implementation:** computing "expected" by calling the same function under test a second time (mirrors the self-grading failure mode) — the property must be an independent invariant, not a restatement of the function body.
- **No shrinking inspected:** if the library reports a failure, the shrunk counterexample must actually be read — accepting "it failed somewhere" without inspecting the minimal case wastes the tool's main advantage.

`test-quality-reviewer` reviews property-based test files under the same
anti-pattern taxonomy (3a-3h) plus dimension 3i (Vacuous Property).

## Escalating to a proof

A property-based test that survives thousands of generated cases still only
demonstrates absence of a counterexample among the inputs *tried*. When the same
invariant guards a **critical-core** (crypto, auth/authz, monetary arithmetic,
consensus/ordering, `unsafe` safety) **and** the code is in a language with a
verifier (Rust/Verus, Dafny, Ada/SPARK, C/Frama-C, Java/OpenJML; C++ via bounded
CBMC/ESBMC), escalate that invariant to `formal-verification` — it turns the PBT
property into a machine-checked `ensures` contract proving no counterexample can
exist. If there is no verifier for the language, PBT (plus
`deterministic-simulation-testing` for concurrent cores) is the strongest tool
available — stay here. This is a one-way on-ramp: PBT finds counterexamples
cheaply; FV proves none remain.

## Completion Report

When this skill's work is done, report to the user in chat:

- **Produced:** which functions gained property tests, file + path.
- **Invariant:** the one-sentence property each test checks.
- **Verdict:** did `test-quality-reviewer` (3i) pass on the new test file.
- **Next:** back to `test-driven-development`'s white-box pass, or ready for commit.
