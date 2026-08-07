# Research: Coverage vs. Quality — Benchmarking the Harness's Test Generation Against Legendary Test Suites

**Date:** 2026-08-07
**Time spent:** ~1 session (1 web-research subagent pass + direct reads of 7 harness skill/agent files + 3 targeted greps)
**Question:** Does `private-ai-harness`'s test-generation machinery (test-driven-development, test-quality-reviewer, integration-test-reviewer, verification-before-completion) optimize for coverage or for the kind of bug-catching, regression-proofing quality that repos like SQLite are famous for?
**Decision:** Not a build/kill call — this is an audit. Verdict and ranked recommendations are in Parts 4–5.
**Confidence:** medium-high. The exemplar claims are grounded in live web search/fetch (not training recall) with citations below. The harness claims are grounded in direct file:line reads. The one unverified piece is real session transcripts — see Open Questions.

---

## Part 1 — What the legendary repos actually do

### SQLite
Source: [sqlite.org/testing.html](https://www.sqlite.org/testing.html)

- Test code outweighs production code **590×** by SLOC (v3.42.0: ~155.8K core vs ~92M test).
- Four independent harnesses: TCL (51,445 cases), **TH3** (proprietary C, full-coverage run = 2.4M test instances, soak run = 248.5M), SQL Logic Test (7.2M queries diffed against Postgres/MySQL/MSSQL/Oracle), dbsqlfuzz (~1 billion mutations/day).
- **100% MC/DC branch coverage** on the core + unix VFS, measured by gcov.
- Out-of-memory injection (fail-once and fail-forever-after), I/O-error injection with post-hoc `integrity_check`, and crash testing (kill the process mid-write, verify the change is either fully applied or fully rolled back).
- Fuzzing lineage: AFL (2015–19) → OSS-Fuzz (2016–) → dbsqlfuzz (2018–) → jfuzz (2024, JSONB).
- The rule that matters most here: **"Whenever a bug is reported against SQLite, that bug is not considered fixed until new test cases that would exhibit the bug have been added to either the TCL or TH3 test suites."** This is a regression-recurrence guarantee, not a coverage target.

### TigerBeetle / FoundationDB — deterministic simulation testing
Sources: [TigerBeetle VOPR](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/internals/vopr.md), [A Descent Into the Vörtex](https://tigerbeetle.com/blog/2025-02-13-a-descent-into-the-vortex/), [Diving into FoundationDB's Simulation](https://pierrezemb.fr/posts/diving-into-foundationdb-simulation/), [Will Wilson, Strange Loop 2014](https://www.thestrangeloop.com/2014/testing-distributed-systems-w-slash-deterministic-simulation.html)

- A single seed deterministically replays packet loss/reorder, disk corruption, and process crashes against the *real* production code (not mocks), running single-threaded.
- A failing seed reproduces the exact fault interleaving — the class of bug that needs "a network partition **and** a slow disk **and** a coordinator crash at the exact same moment" to appear, which flaky non-reproducible integration tests can't pin down.
- FoundationDB: ~1 trillion CPU-hours simulated; an operator's line: "I've never been woken up by FDB."

### Redis (antirez)
Source: [Redis new test engine](https://oldblog.antirez.com/post/redis-new-test-engine.html)

> "Almost all the bugs discovered thanks to Redis's test suite were discovered thanks to fuzz tests and very rarely thanks to regression tests and unit tests."

This is the single most direct data point against a coverage-first mental model: the author of the suite says plain regression/unit tests were **not** where the value came from.

### curl (Daniel Stenberg)
Sources: [Testing curl](https://daniel.haxx.se/blog/2017/10/12/testing-curl/), [5 years on OSS-Fuzz](https://daniel.haxx.se/blog/2022/07/01/5-years-on-oss-fuzz/)

- "Torture testing": rerun each test once per fallible call (malloc/socket/file op) in the run, forcing exactly one to fail each time — checks for leaks/crashes under partial failure.
- Continuous OSS-Fuzz since 2017, near-zero false-positive rate on its findings.

### Classic (pre-AI) testing-quality literature
- **Kent Beck, Test Desiderata**: isolated, composable, deterministic, fast, specific, behavioral. "No property should be given up without receiving a property of greater value in return." [Medium](https://medium.com/@kentbeck_7670/test-desiderata-94150638a4b3)
- **Martin Fowler, TestCoverage**: "Test coverage is a useful tool for finding untested parts of a codebase. Test coverage is of little use as a numeric statement of how good your tests are" — and cites Brian Marick: "If a part of your test suite is weak in a way coverage can detect, it's likely also weak in a way coverage can't detect." [martinfowler.com](https://martinfowler.com/bliki/TestCoverage.html)
- **Google Testing Blog**: test-size pyramid, ~80% unit / 15% integration / 5% e2e. [Test Sizes](https://testing.googleblog.com/2010/12/test-sizes.html)
- **Kent C. Dodds, Testing Trophy**: "Write tests. Not too many. Mostly integration." [kentcdodds.com](https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications)

### 2024–2026 critique of AI-generated tests
- **"AI Test Theater"**: when one model writes the code and the test in the same session, oracle independence collapses into self-grading. Concrete pattern: the expected value is computed by re-running the same code path, so implementation bugs become invisible. Reported gap: 78%+ line coverage against a 31% mutation score. [getautonoma.com](https://getautonoma.com/blog/ai-generated-tests-pass-but-dont-assert)
- **"Misguidance effect"** (arXiv:2607.22883, ISSTA 2026): buggy code already present in the prompt/context steers the LLM to write tests that assert the *buggy* behavior, while suppressing bug-finding tests — i.e. it tests the implementation it can see, not the spec. Mitigation: derive a spec first, discard the implementation, generate tests from the spec alone. [arxiv.org/abs/2607.22883](https://arxiv.org/abs/2607.22883)
- **Mutation-feedback effect size**: vanilla LLM prompting scores 53% mutation score on HumanEval-Java vs. 89.5% once a mutation-testing feedback loop is added. [augmentcode.com](https://www.augmentcode.com/guides/mutation-testing-ai-generated-code)

---

## Part 2 — Where the harness already matches this (evidence, not assumption)

This is the part worth stating plainly: **the harness's prompt design is not naively coverage-driven.** It already anticipates most of the Part 1 failure modes, in writing, with citations of its own:

| Harness mechanism | What it does | Matches |
|---|---|---|
| [`skills/test-driven-development/SKILL.md:212`](../skills/test-driven-development/SKILL.md) | Opens the RED-test design section with Myers 1979 ("testing is the process of executing a program with the intent of finding errors") and requires both black-box (boundary value, equivalence partition, error guessing) and white-box (branch/path/condition coverage) strategies | Fowler's "weak in a way coverage can't detect" — forces two independent lenses, not one |
| [`agents/test-quality-reviewer.md:13`](../agents/test-quality-reviewer.md) | "A test that always passes regardless of the implementation is not a test — it is noise" + 8 named anti-patterns (3a–3h: testing mocks, trivial assertion, happy-path-only, testing implementation detail, no isolation of failure, missing boundary conditions, exception swallowing, single-strategy coverage) | Near-1:1 match to the "AI Test Theater" catalogue, written before this research pass existed |
| [`skills/verification-before-completion/SKILL.md:168-186`](../skills/verification-before-completion/SKILL.md) | Test-Strength Gate: mutation score (Stryker/PIT/mutmut) required, not just line coverage. Explicit line: "80%+ coverage with < 50–60% mutation score means the assertions are tautological" | This is word-for-word the finding in the "AI Test Theater" / mutation-feedback research — already encoded, pre-emptively |
| [`agents/spec-quality-reviewer.md:25`](../agents/spec-quality-reviewer.md) | North Star section cites SQLite by name: "every requirement has a test ID. Test suite is 8× larger than the implementation. Richard Hipp's rule: if it's not tested, it doesn't exist" | The harness already uses SQLite as its own explicit benchmark |
| [`agents/spec-quality-reviewer.md:141-151`](../agents/spec-quality-reviewer.md) (§2c, "TC Honesty") | "If the implementation were subtly wrong... would this TC catch it?" with phantom-TC examples (`assert result is not None`) | Directly operationalizes Fowler's coverage-as-diagnostic-not-target argument |
| [`agents/integration-test-reviewer.md:173-199`](../agents/integration-test-reviewer.md) (D8, Failure Path Coverage) | Requires tests for unique-constraint violations, FK violations, rollback-on-error against a *real* dependency | A scaled-down, DB-integration-test version of SQLite's I/O-error-injection/crash-testing philosophy |
| [`skills/test-driven-development/SKILL.md:345-349`](../skills/test-driven-development/SKILL.md) | "Bug found? Write failing test reproducing it... Never fix bugs without a test" | Matches SQLite's regression rule in spirit |

Conclusion of Part 2: if the question is "does the harness's *design* know the difference between coverage and quality," the answer is yes, unusually so. The gap is not in what the prompts say. It's in Part 3.

---

## Part 3 — The actual gaps

### Gap 1 (highest impact): the rigorous gate is real but skippable, and the fastest lane skips it by design

- **QUICK-FIX lane** (`skills/engineer/SKILL.md:65-77`) — 6 steps: karpathy → systematic-debugging → codebase-comprehension → test-driven-development → verification-before-completion → commit-discipline. **`requesting-code-review` is not in this list.** `test-quality-reviewer` is therefore never invoked.
- **TASK lane** (`skills/engineer/SKILL.md:80-102`) — step 8 explicitly scopes `requesting-code-review` to "per-task `/review pr` **during SDD only**"; the full suite (`pr-reviewer + spec-impl-reviewer + test-quality-reviewer + security-reviewer`, per `skills/finishing-a-development-branch/SKILL.md:127`) runs **once, at the very end**, not per task.
- Net effect: on the fastest and (by construction) most frequently used lane, the same agent that writes the implementation also writes the tests and grades them itself via the TDD skill's own checklist — no independent reviewer ever asks "would this test fail on a wrong implementation." This is the self-grading problem from Part 1's "AI Test Theater" research, reproduced one layer up: not "same model, same message" but "same lane, no external reviewer ever dispatched."
- This is the most direct, structural explanation for the user's stated experience. The SQLite-grade machinery isn't missing — it's gated behind a workflow tier that quick, everyday changes are explicitly routed around.

### Gap 2: oracle independence is asked for, not architected

`skills/test-driven-development/SKILL.md:216-232`'s black-box section tells the *same* continuous-context agent to write RED tests "as if" it can't see the implementation. Per the misguidance-effect finding (Part 1), an LLM that has already reasoned about the implementation in-context tends to write tests that assert what it's about to build, not what the spec independently requires — asking the same model to role-play blindness doesn't reproduce the effect of genuine separation. No skill currently dispatches a fresh subagent that receives only the spec/REQ (never the implementation, never the implementer's session) to author the test oracle.

### Gap 3: no fuzzing / property-based testing skill

Antirez's own claim — "almost all the bugs... thanks to fuzz tests and very rarely thanks to regression tests and unit tests" — is the strongest single data point in Part 1, and the harness's skill table (per `AGENTS.md`) has nothing at the unit-test layer for it. `load-testing` is k6/performance, `chaos-engineering` is infra-level fault injection via Toxiproxy against staging, `dast-testing` is ZAP security fuzzing — none of these wire a property-based/fuzz tool (Hypothesis, fast-check, jqwik, proptest, Go's native fuzzing) into the same place TDD's white-box section already operates.

### Gap 4: mutation testing is a checklist line, not a CI gate

Confirmed by grep: `skills/ci-pipeline-setup/SKILL.md` and `agents/ci-reviewer.md` contain **zero** mentions of mutation testing. The requirement lives only in `verification-before-completion`'s manual checklist. Nothing mechanically stops an agent from skipping the mutation run — it depends entirely on the implementing agent remembering, self-reported, with no gate.

### Gap 5: no mechanical bugfix → regression-test check

Confirmed by grep: `agents/pr-reviewer.md` contains **zero** mentions of "regression." TDD skill states the rule in prose ("Never fix bugs without a test"), but nothing cross-checks that a `fix:`-typed commit/PR actually includes a new or modified test file — SQLite enforces this as project policy; the harness only asks nicely.

### Gap 6 (narrow audience, lower priority): no deterministic-simulation-testing pattern

TigerBeetle/FoundationDB-style seeded, single-process, replayable fault simulation has no analog. `chaos-engineering` is the nearest relative but operates at the infra/staging level, not as a unit-level simulation harness. Only relevant to harness users building concurrent or distributed systems — named for completeness, not urgency.

---

## Part 4 — Verdict

Two different, both-true answers depending on which layer you look at:

- **By design:** quality-driven. The prompts explicitly name Myers' error-finding definition, benchmark against SQLite by name, gate on mutation score instead of line coverage, and enumerate an anti-pattern list that overlaps almost completely with 2024–2026 published critiques of AI-generated tests — several of which (verification-before-completion's Test-Strength Gate) predate the specific research citations in Part 1.
- **By routing, in practice:** coverage-shaped by default. The one mechanism that would catch a coverage-shaped test (`test-quality-reviewer`) is wired to fire only on the review-heavy paths (`finishing-a-development-branch`, `/review tests`, `/review all`) — and the fastest, almost certainly most-used lane (quick-fix) is structurally routed around it. A test written on that lane is graded only by the same agent that wrote it, against its own TDD-skill checklist.

The user's intuition is correct, but the mechanism is not "the harness doesn't know what good tests look like." It's "the harness knows, and built the reviewer for it, but the fast lane never calls the reviewer."

---

## Part 5 — Actionable recommendations, ranked by leverage ÷ effort

| # | Recommendation | Effort | Leverage |
|---|---|---|---|
| 1 | Add a self-check question to QUICK-FIX's TDD step, and/or a cheap mechanical assertion-shape check at the existing `verification-before-completion` dispatch point (already in the lane) — no new Opus call, no new skill | Small (prompt-only edit) | High — closes Gap 1 for the highest-volume lane without adding an expensive review step |
| 2 | Cross-check `fix:`-typed commits/PRs against test-file presence in `pr-reviewer` (or `requesting-code-review` routing) | Small | High — directly operationalizes the SQLite regression rule the harness already states in prose |
| 3 | Wire mutation testing into `ci-pipeline-setup`'s generated CI config and `ci-reviewer`'s mechanical checks, using the same per-language table pattern `verification-before-completion` already has | Medium | High — turns Gap 4 from "hope the agent remembers" into an enforced gate |
| 4 | New `property-based-testing` skill (Hypothesis/fast-check/jqwik/proptest/Go fuzz, detected by manifest like the existing linter table), invoked from TDD's white-box section for pure/invariant-bearing functions | Medium | High — imports the single technique the exemplars credit most for real bug-finding |
| 5 | Oracle-independence task variant in `writing-plans`/`subagent-driven-development`: a fresh, implementation-blind subagent authors the RED test from the spec alone, reserved for Critical-complexity work per `workflow.md`'s complexity table | Large | Medium — real fix for Gap 2, but too expensive to apply universally |
| 6 | Deterministic-simulation-testing skill for concurrent/distributed components | Large | Low/niche — only relevant if harness users build that class of system |

Suggested order: **1 and 2 first** (cheapest, no new files, close the highest-impact gap), then **3**, then **4**. **5** and **6** are follow-up proposals, not immediate work.

---

## Open questions

- This audit is based on the skills' *control flow*, not sampled evidence from real past sessions. I did not have access to actual quick-fix-lane transcripts to confirm that tests produced under that lane exhibit the anti-patterns `test-quality-reviewer` is built to catch. The routing gap (Gap 1) is structurally certain; its real-world frequency is inferred, not measured. A cheap way to convert this from "structurally likely" to "measured": sample N recent commits made under the quick-fix lane and run `test-quality-reviewer` against them ad hoc.

## If this becomes a task

Recommendations 1–2 fit the **small** change classification in `workflow.md`'s complexity table (prompt-only edits to existing skill/agent files, no new architecture) — brainstorming/HLD can be skipped, spec+plan optional. Recommendation 3–4 are also **small–medium** (new CI table row, one new skill file) but touch `AGENTS.md`/`README.md`/version bump per this repo's own meta-doc sync rule. Recommendations 5–6 would warrant at least a short spec before touching skill files, given they change control flow across multiple skills.
