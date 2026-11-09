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

Modern AI-assisted development is moving away from reading code toward reading specs. The harness is built on this premise: requirements are the first thing you read; code is read to the depth you choose to own it.

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

## Ownership Through Understanding

Most code is now written by an agent and rarely read line by line, so
ownership cannot come from having typed it. It comes from holding the theory
of the system in your head: why this boundary, why this data structure, what
fails first and how you would know. Naur called this programming as theory
building ("Programming as Theory Building", 1985): the theory lives in people
and cannot be fully recovered from code or docs. You own a solution when you
can explain and teach it, from the highest level down to any line you choose.

That makes the harness a library, not a pipeline. A pipeline you hand a
request to and walk away from is the fastest way to stop understanding what
you ship.

- **Tools, not a workflow.** `/engineer` shows a catalogue of skills and
  subagents. You pick, or the AI picks with a one-line reason. Nothing chains
  on its own; when a tool works best after another, it says why and asks.
- **You think first; the AI fetches and attacks.** Write your own read of the
  problem before asking: the facts, what you infer from them, your first
  guess. The AI is fastest at retrieving facts (code paths, docs, prior art,
  numbers) and at attacking inferences. Drawing the inference is the skill,
  so keep it.
- **Validation points and asks; it does not hand over the fix.** In
  [Anthropic's 2026 randomized trial](https://www.anthropic.com/research/AI-assistance-coding-skills)
  (52 developers learning a new library), the AI group scored 50% on a
  follow-up comprehension quiz against 67% for those coding by hand, with the
  largest gap in debugging. How the AI was used mattered more than whether:
  conceptual questions scored 65%, and generating code then questioning it
  until it made sense scored 86%. Delegating scored 39%, and having the AI
  debug your code scored 24%. Each pattern group had 2–7 people, so read
  these as a direction, not a law.
- **Predict, then check.** Before a test runs, a root cause is revealed, or a
  reviewer reports, write down what you expect, then score it. Intuition
  becomes trustworthy only with fast, honest feedback (Kahneman & Klein,
  "Conditions for Intuitive Expertise", 2009). Repetition without scored
  predictions builds familiarity, not fingertip feel.
- **Explain it back.** People believe they understand mechanisms far better
  than they do until asked to explain them step by step (Rozenblit & Keil,
  "The Misunderstood Limits of Folk Science", 2002). The Feynman technique
  (explain simply, find the gap, go back to the source) is the test;
  `teacher` runs it on purpose.
- **Choose how deeply you own each piece.** *Teach*: you could teach it line
  by line (the core). *Explain*: you know why it is shaped this way and what
  it trades off. *Trust*: tests prove it, and you deliberately don't
  internalize it. Owning every line of everything doesn't scale; drifting from
  teach to trust without deciding to is how the theory gets lost.
- **Space and vary the practice.** Re-solve a problem from a blank page weeks
  later, or apply its principle somewhere else. Spaced, effortful retrieval is
  what lasts (Bjork); doing the same thing again and again is not.

Skills teach reasoning, not recipes. Numbers, thresholds, and depth are
derived for the case at hand and shown with their basis, so you can challenge
an input instead of accepting a constant.

## The Measure of Success

Two measures, in this order:

1. **Owned understanding.** Can you explain and teach what was built, at the
   depth you chose for each piece? Track your prediction hit rate per area;
   when it rises, your judgment is calibrating.
2. **Time from intent to done.** Speed counts for work you understand. Quality
   has to be there from the start, because fixing it later costs more time
   than building it in.

If a new plugin adds friction instead of removing it, it doesn't belong here.
If it removes friction by removing your understanding, it doesn't belong here
either.

## What This Is Not

- Not a product. Not a platform. Not designed to scale to teams.
- Not a pipeline you hand a request to and stop thinking.
- Not a replacement for deep work. It handles the mechanical so you can go deeper.
- Not a one-time build. It evolves — discarding what slows down, absorbing what accelerates.

## The Operating Model

0. **Understand first** — your own read of the problem: facts, inferences, a first guess, a prediction.
1. **Pick the tools** — the fewest from the catalogue (`/engineer`) that do the job.
2. **Write the spec** — requirements as testable statements of truth, when the work warrants one.
3. **Write the tests** — derived from the spec, covering every requirement and assumption.
4. **Generate the code** — AI produces the implementation; the tests are the acceptance criterion; you interrogate it to the depth you chose.
5. **Explain it back** — teach it, find the gaps, close them.
6. **Grow the harness** — prefer wrapping an existing plugin to building one; if a tool doesn't make the work faster without costing understanding, remove it.

## The Long Game

The harness is never finished. It is a living system that reflects the current shape of the work.

The goal is not to have more tools. The goal is to need fewer keystrokes, fewer decisions, fewer context switches — and to direct every freed second toward the work that actually matters.
