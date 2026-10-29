# Test Scenarios — agreed before any code (topic h)

The matrix is the contract between the spec and the code. It is discussed and
agreed like any other decision; `writing-plans` and `test-driven-development`
then implement it TC by TC.

## Rigor bar

SQLite (sqlite.org/testing.html) ships with 100% branch and MC/DC coverage in
its TH3 harness, anomaly tests (out-of-memory, I/O error, crash and power
loss), fuzzing, and boundary tests — and still finds bugs with each. The bar
here is the same attitude, scaled by risk:

- **Traceable:** every REQ and every acceptance criterion has at least one TC;
  every TC cites the REQ/AC it validates; no orphan TCs.
- **Honest:** every TC names the concrete wrong implementation it would catch
  (an off-by-one at a named boundary, an inverted condition, a swallowed error,
  a missing idempotency check). A TC that would pass on a subtly wrong
  implementation is not a test (Myers, *The Art of Software Testing*).
- **Branch-complete where it matters:** for decision logic in Critical-tier
  REQs (auth, money, PII, public API, data integrity), use MC/DC: each
  condition is shown to independently flip the outcome — usually `n + 1` cases
  for `n` conditions (Hayhurst et al., *A Practical Tutorial on Modified
  Condition/Decision Coverage*, NASA/TM-2001-210876; required for DO-178C
  Level A).

## Matrix format

Save to `.ai/<id>/tests/test-scenarios.md`.

```markdown
# Test Scenarios — <feature>   (iteration k/N)

| TC | Validates | Level | Technique | Given / When / Then | Kills (wrong impl caught) | Determinism |
|----|-----------|-------|-----------|---------------------|---------------------------|-------------|
| TC-001 | REQ-001 AC-1 | unit | BVA | Given limit 255, when input has 256 chars, then error E_TOO_LONG | accepts 256 (`<=` vs `<`) | pure |
| TC-002 | REQ-001 AC-2 | property | round-trip | ∀ valid x: decode(encode(x)) == x | lossy escaping of `\u0000` | seed logged |
```

### Level tags (pick the cheapest level that can observe the behavior)

| Tag | Use for | Notes |
|---|---|---|
| `unit` | pure logic, one module | no I/O, no clock |
| `integration` | real DB / queue / cache / filesystem at the boundary | `integration-testing` skill; no mocks at the boundary |
| `contract` | service-to-service API agreements | Pact or schema tests |
| `e2e` | critical user journeys only | `e2e-testing` skill |
| `property` | invariants: round-trip, idempotence, algebraic laws | `property-based-testing` skill (QuickCheck lineage, Claessen & Hughes 2000) |
| `fuzz` | parsers, decoders, anything taking untrusted bytes | libFuzzer / AFL++ / language-native fuzzers; corpus committed |
| `simulation` | concurrency, distribution, ordering | `deterministic-simulation-testing` (FoundationDB / TigerBeetle VOPR style) |
| `perf` | NFRs with a number | threshold copied from the NFR, `load-testing` skill |
| `chaos` | resilience NFRs | `chaos-engineering` skill |
| `a11y` / `visual` | UI | `e2e-testing` / `visual-regression` |
| `security` | authz matrices, injection, DAST | `dast-testing` for running services |
| `mutation` | suite-level strength gate, not a TC | `verification-before-completion` Test-Strength Gate |

### Techniques

BVA (below / at / above each boundary) · equivalence partitioning · error
guessing (null, empty, zero, max, duplicate, concurrent, partial failure) ·
decision table · MC/DC · state transition (every transition, every illegal
transition) · metamorphic relations · round-trip · differential (against a
reference implementation or the previous version).

### Determinism column

`pure`, `seed logged`, `fake clock`, `isolated DB (rollback)`, `hermetic
network`. No sleeps; no wall-clock; no order dependence between TCs.

## The review loop

```
k = 1
loop:
  write or update the matrix (iteration k/N in the title)
  dispatch test-scenario-reviewer:
      SCENARIOS_PATH=.ai/<id>/tests/test-scenarios.md
      SPEC_PATH=.ai/<id>/specs/specs-<slug>.md
      LLD_PATH=.ai/<id>/lld/lld-<slug>.md        (if it exists)
      ITERATION=k/N
      REPORT_FILE=.ai/<id>/tests/review-k.md
  mechanical findings (missing trace, missing tag, vague Given/When/Then) → fix yourself
  substantive findings (scope, level choice, acceptable risk) → one card each, ask the human
  if reviewer PASS → present the matrix card (it cites the matrix file's sha256) → ask
  if agreed → done
  if k == N → present the remaining gaps; the human picks:
        accept with these gaps (its own card listing them)  |  raise N  |  change scope
  k += 1
```

N is the cap the human set in D-000. The reviewer's verdict is advisory to the human;
the human's agreement is what the ledger records.

## Handoff to BUILD

- `writing-plans`: every task's test steps reference TC ids; a TC with no task
  is a plan gap; a task with no TC is scope creep.
- `test-driven-development`: one RED test per TC (or per TC row for property and
  fuzz harnesses); the test name or docstring carries the TC id and
  `@validates_req REQ-NNN`; the test must fail first for the reason in the
  Kills column.
- Critical-tier TCs use `writing-plans`' Oracle-Independence Gate.
