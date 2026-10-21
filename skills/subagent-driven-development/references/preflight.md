# Pre-Flight Plan Review

Part of subagent-driven-development. Read from disk at the step that needs it, so it survives compaction.

Before dispatching Task 1, read the plan's `Spec:` pointer (if not `N/A`) and
scan the plan once for conflicts, against the spec's actual text rather than
a guess at what it meant:

- tasks that contradict each other or the plan's Global Constraints
- anything the plan explicitly mandates that is a known defect pattern (a
  test that asserts nothing, verbatim duplication of a logic block)

Record the scan in the ledger either way —
`Pre-flight: clean` or `Pre-flight: N conflicts found` — so a resumed
session can see the scan happened instead of re-running it.

**Non-catastrophic conflicts and ambiguities do not stall the run.** Decide
and record a ruling, then continue: `Pre-flight: <finding> — ruling: <what
governs and why>`. Only stop for your human partner when the conflict is
destructive or irreversible (deleting data, an auth/security boundary
change, a decision that cannot be undone by a later task) — a session left
blocked on a decision the controller could safely make is a wasted turn, not
a caution. The final whole-branch review remains the net for conflicts that
only emerge from implementation.
