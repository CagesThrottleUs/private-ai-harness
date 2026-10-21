# Design Process Detail

Part of the brainstorming skill: structured questions, scoring approaches (ATAM/RAT), presenting the design, information-hiding boundaries, existing codebases. Read it before laying out approaches.

## The Process

**Using AskUserQuestion for clarifying questions:**

Open questions come first (see The Conversation). Use the `AskUserQuestion` tool for structured choices only when the user is stuck or the answer picks a significant branch between 2-4 discrete options (approach A vs B vs C) — it presents options as a structured UI rather than a free-text prompt.
Example:
```
AskUserQuestion({
  questions: [{
    question: "Which storage approach fits best?",
    header: "Storage",
    options: [
      { label: "PostgreSQL", description: "Relational, ACID, good for structured data" },
      { label: "Redis", description: "In-memory, fast reads, good for ephemeral state" },
    ]
  }]
})
```

For open-ended questions ("describe your problem"), continue using prose — the tool is for structured choices, not free-form input.

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
- For appropriately-scoped projects, ask questions one at a time to refine the idea
- Open questions first; offer a menu only when they're stuck
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, why, constraints, success criteria, and who owns the how-it-gets-made choices

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why
- YAGNI ruthlessly - remove unnecessary features from every approach and design
- **Score the options against named quality-attribute scenarios, not vibes**
  (ATAM, SEI). List the scenarios that matter for this system — e.g. "p99 read
  latency < 200ms under 10× load" (performance), "a new payment provider added
  without touching checkout" (modifiability), "one region fails, service stays
  up" (availability) — and rate each option against them. Surface **sensitivity
  points** (a decision that strongly moves one attribute) and **tradeoff points**
  (improving one attribute hurts another); name them in the recommendation.
- **Name the riskiest assumption** each approach rests on and how you'd cheaply
  test it before committing (RAT). The approach that looks best but hides an
  untested load-bearing assumption is not yet the safe choice.

**Presenting the design:**

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- **For each proposed component, name the difficult design decision or volatile requirement it hides from the rest of the system.** A component whose name describes a step in a sequence (`InputHandler`, `DataProcessor`, `OutputWriter`) is process-decomposed — change the step and callers break. A component whose name describes what it hides (`StorageLayout`, `SortStrategy`, `SchemaAdapter`) is information-hiding decomposed — change its internals and nothing else needs to know. (Parnas, 1972)
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

