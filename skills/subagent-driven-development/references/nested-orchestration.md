# Cheaper Orchestration

Part of subagent-driven-development. Read from disk at the step that needs it, so it survives compaction.

The controller session is the most expensive seat in an SDD run: it reads
every dispatch result and every report, usually on the session's most capable
model. Claude Code allows nested subagents (three layers deep by default;
`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` adjusts it), so the whole loop can run
one layer down for roughly half the cost and wall-clock.

Do this only when your human partner asks for it, or has said the session
model is too expensive to spend on coordination:

- Dispatch **one** orchestrator subagent on a mid-tier model with the plan
  path and the instruction to run this skill end to end.
- The orchestrator dispatches its own implementers and reviewers per Model
  Selection above. The workspace and ledger live on disk, so nothing is lost
  to the extra layer.
- Its final message must carry the **Completion Report** and every pre-flight
  ruling **verbatim** — that relay is how the decisions reach your human
  partner. Relay it, do not summarize it.

Nest a whole plan, never a single task's dispatch — one task buys nothing and
adds a seat.
