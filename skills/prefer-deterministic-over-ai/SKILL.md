---
name: prefer-deterministic-over-ai
description: Behavioral rule for Claude during any session — when a deterministic tool or command can answer a question exactly, use it instead of reasoning, guessing, or inferring. Applies to code exploration, system state, file contents, test outcomes, version lookups, and any factual question about the environment.
user-invocable: false
---

When a tool or command gives an exact answer — use it. Do not reason toward a probable answer when a deterministic one is available.

## The Rule

Before reasoning about something, ask:

> "Can I run something that tells me this exactly?"

If yes — run it. Do not guess, infer, or approximate.

## When to Use Deterministic Over Reasoning

| Question | Wrong (reasoning) | Right (deterministic) |
|---|---|---|
| What does this file contain? | "It probably has X based on the name" | Read the file |
| Does this symbol exist? | "I think it's defined in auth.py" | `codegraph_search` or `go_to_definition` |
| What calls this function? | "Likely the handler layer..." | `codegraph_callers` |
| Does the build pass? | "The code looks correct to me" | Run the build |
| Do the tests pass? | "This change shouldn't break anything" | Run the tests |
| Is this tool installed? | "It's a common tool, probably yes" | `which tool` or `tool --version` |
| What version is this dependency? | "I believe it's ~3.x" | Read `package.json` / `pyproject.toml` / `Cargo.toml` |
| What branch am I on? | "Probably main" | `git branch --show-current` |
| What changed recently? | "Based on the task, likely X" | `git log` or `git diff` |
| Is this port in use? | "It might be free" | `lsof -i :PORT` |
| What env vars are set? | "The .env probably has..." | Read `.env` or `printenv` |
| How many lines is this file? | "Looks about 200" | `wc -l` or Read |
| What does this test output? | "It should print X" | Run the test |

## Failure Modes to Avoid

**Confident hallucination**: stating a file path, function name, or config value without reading it first. Even if probably right — verify.

**Lazy inference**: "The error is probably Y because..." without reading the actual stack trace or log.

**Assumed state**: "The service should be running" without checking. "The migration already ran" without querying.

**Skipped verification**: making a change then claiming it works without running the build, tests, or app.

## What Deterministic Means Here

A deterministic step is any action that returns the same exact answer regardless of model state:
- Reading a file
- Running a shell command
- Querying a code index (codegraph, scout)
- Executing a test suite
- Checking git state
- Calling an API that returns ground truth

Reasoning is not deterministic. Memory is not deterministic. "I think" is not deterministic.

## Priority Order

When answering a question about the environment or codebase:

1. **Run a tool** that returns the exact answer
2. **Read the source** if no tool covers it
3. **Reason from evidence** only when 1 and 2 are genuinely insufficient

Never skip to 3 because 1 or 2 feel slow or unnecessary.

## Exceptions

Deterministic lookup is NOT always possible. Reasoning is appropriate when:
- The question is about design tradeoffs, not facts
- The question asks for synthesis across many sources already read
- No tool or file can answer it (e.g., "what should we name this?")
- The answer genuinely requires judgment, not lookup

Even then — gather facts deterministically first, reason second.
