# Philosophy

## The Core Bet

Time is the only non-renewable resource. This harness exists for one reason: eliminate every second of friction between intention and result.

Not 10% faster. 10x faster.

## The Problem

The AI ecosystem is rich but fragmented. Dozens of tools, each excellent in isolation, each requiring a different interface, different mental context switch, different authentication, different workflow. The overhead of *orchestrating* AI tools has become its own tax.

The solution is not to build new tools. It's to build the glue that makes existing tools feel like one.

## The Principle: One Interface, Many Capabilities

This harness is a single entry point into a composable ecosystem of AI capabilities. The design constraints:

- **Personal only** — optimized for one workflow, one brain. No compromises for generalizability.
- **Reuse over build** — if a battle-tested plugin exists, wrap it. Don't reinvent.
- **Zero switching cost** — every capability accessible from the same surface, same context, same flow.
- **Progressive accumulation** — plugins install over time as needs emerge. The harness grows with the work.

## The Spec Is the Contract

Modern AI-assisted development is moving away from reading code toward reading specs. The harness is built on this premise: you do not look at code — you look at requirements.

Inspired by the [SQLite testing philosophy](https://sqlite.org/testing.html) and the DO-178B aviation safety standard, the quality bar for specs here is not "good enough to communicate intent." It is: **a spec is a testable statement of truth.**

### The Rules

**Every requirement is explicit.**
No undocumented behavior. If behavior exists but is not in the spec, it is either documented immediately or treated as a bug. Undocumented behavior causes project failure, not a warning.

**Every requirement maps to a test.**
A requirement without a test is a wish, not a contract. Test coverage is derived from the spec, not from the code. Code is the implementation detail; the spec-test pair is the artifact that matters.

**Every line of code maps to a requirement.**
No code exists without a traceable reason. Dead code violates the contract. If it cannot be traced to a requirement, it is deleted.

**Zero assumptions in tests and requirements**
Tests break every assumption. No mocking of behavior that should be verified. No "this probably works." Every dependency, every boundary condition, every edge case is exercised.
Requirements are rejected if they cannot be tested along with requirements

**Zero drift between spec and behavior.**
Documented behavior must exactly match actual behavior. The test suite is the proof. If they diverge, the spec wins — the code is wrong, not the spec.

This approach is not bureaucratic overhead. It is the mechanism by which AI-generated code remains trustworthy at scale. The spec quality determines the code quality. There is no other lever.

## The Measure of Success

One metric: time from intent to done.

Not code quality. Not elegance. Not feature count. The only question is: did you achieve this faster?. This implies that code quality must be there from start, else you are spending time on fixing quality which increases the time to achieve the result. Same for elegance

If a new plugin adds friction instead of removing it, it doesn't belong here.

## What This Is Not

- Not a product. Not a platform. Not designed to scale to teams.
- Not a replacement for deep work. It handles the mechanical so you can go deeper.
- Not a one-time build. It evolves — discarding what slows down, absorbing what accelerates.

## The Operating Model

1. **Write the spec** — requirements as testable statements of truth, not prose descriptions.
2. **Write the tests** — derived from the spec, covering every requirement and assumption.
3. **Generate the code** — AI produces the implementation; the test suite is the acceptance criterion.
4. **Find or wrap a plugin** — prefer existing tools; wrap, configure, compose.
5. **Wire it in** — one interface, one invocation pattern, same mental model.
6. **Measure** — if it doesn't make the workflow faster, remove it.

## The Long Game

The harness is never finished. It is a living system that reflects the current shape of the work.

The goal is not to have more tools. The goal is to need fewer keystrokes, fewer decisions, fewer context switches — and to direct every freed second toward the work that actually matters.
