---
name: deterministic-simulation-testing
description: >
  Use for concurrent or distributed components (multi-node protocols, consensus,
  replication, anything coordinating over a network or shared disk) where the bug
  class is a rare combination of faults arriving at the same moment — a partition
  and a slow disk and a crash together. Wires a single seeded random source through
  every nondeterministic boundary (network, disk, clock, scheduling) so a failing
  run replays exactly from its seed. Modeled on TigerBeetle's VOPR and FoundationDB's
  simulation testing. Distinct from chaos-engineering: chaos tests a real staging
  deployment black-box; this tests real production code in-process, seeded and
  replayable. Reviewed by chaos-reviewer (DST dimension).
---

# Deterministic Simulation Testing

Chaos engineering injects faults into a real running staging deployment and
watches what happens once. Deterministic simulation testing injects faults
into real production code running in-process, behind a single seeded random
source — so when it fails, the exact seed replays the exact fault
interleaving, every time. TigerBeetle's VOPR and FoundationDB's simulation
framework are the reference implementations; both credit this technique with
catching the class of bug that needs "a network partition **and** a slow disk
**and** a coordinator crash at the exact same moment" — the multi-fault
interaction that flaky, non-reproducible integration tests can't pin down,
and that chaos engineering's live-environment fault injection can observe
but not replay on demand.

## When to Use

**Required only for:** components coordinating state across a network or
disk boundary with concurrency — consensus, replication, distributed
transactions, multi-node protocols, anything with a "the two of these must
never both be true" invariant under concurrent access.

**Skip for:** single-process business logic, CRUD services, anything whose
concurrency surface is "the framework's request handler runs it," and any
component already covered adequately by `integration-testing`'s D8
failure-path checks (single dependency failure, not multi-fault
interaction).

**Infer + confirm:**
> "This component doesn't coordinate across nodes or hold state across a
> network boundary — deterministic simulation testing adds development cost
> without a matching bug class here. Skip, or is there a concurrency
> invariant I'm missing?"

## Core Method

1. **Replace every nondeterministic boundary with a seeded abstraction** —
   network I/O, disk I/O, the clock, and thread/goroutine scheduling each go
   through an interface with two implementations: the real one (production)
   and a simulated one driven by a single seeded PRNG (tests). This is a
   Dependency Inversion boundary (see `design-principles`), not a mock — the
   simulated implementation still runs real logic, it only controls *when*
   and *whether* an operation succeeds.
2. **One seed drives one run, fully deterministically** — record the seed
   (plus the git commit) in the failure output. Re-running with the same
   seed against the same commit reproduces the exact interleaving.
3. **Inject faults the seed decides:** drop/reorder/delay network messages,
   fail/corrupt/delay disk reads and writes, crash and restart a
   simulated node mid-operation, skew simulated clocks between nodes.
4. **Assert a steady-state invariant holds across the whole run**, not just
   at the end — e.g., "no two nodes ever commit conflicting values for the
   same key," checked after every simulated step, not only once at
   teardown.
5. **On a failure, the seed is the regression test.** Commit the failing
   seed (and commit hash) as a permanent regression case — same principle as
   `property-based-testing`'s shrunk counterexample and
   `test-driven-development`'s "never fix a bug without a test": the seed
   replays the exact bug forever.

## Example Shape (language-agnostic)

```
run_simulation(seed=12345):
    sim = SimulatedNetwork(seed) + SimulatedDisk(seed) + SimulatedClock(seed)
    nodes = [RealNodeImplementation(sim) for _ in range(3)]
    for step in range(MAX_STEPS):
        sim.maybe_inject_fault(step)   # decided by the seed, not real time
        sim.tick(nodes)
        assert_invariant_holds(nodes)  # every step, not just at the end
```

Nothing in `RealNodeImplementation` is aware it is being simulated — the
same code runs in production. Only the network/disk/clock it talks to
differ.

## Regression Discipline

A failing seed becomes a named permanent test (`test_regression_seed_12345`)
the same way a shrunk property-testing counterexample does — never delete a
failing seed once it has been fixed; it is proof the specific fault
combination is now handled.

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review

## Self-Review: Run `chaos-reviewer` Agent (DST dimension)

```
Agent(chaos-reviewer, {
  TEST_FILES: "tests/simulation/**/*",
  HLD_PATH: ".ai/hld/YYYY-MM-DD-<feature>.md",
  SPEC_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md"
})
```

Fix all **Critical** findings before committing.

---

## Completion Report

When this skill's work is done, report to the user in chat:

- **Produced:** which components gained a simulation harness, file + path.
- **Invariant:** the steady-state property the simulation checks every step.
- **Verdict:** `chaos-reviewer`'s PASS / NEEDS WORK / BLOCKED on the DST dimension.
- **Next:** back to `test-driven-development`, or ready for commit.
