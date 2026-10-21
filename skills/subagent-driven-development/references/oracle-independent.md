# Oracle-Independent Tasks

Part of subagent-driven-development. Read from disk at the step that needs it, so it survives compaction.

A task whose brief carries `**Oracle:** independent` (set by `writing-plans`'
Oracle-Independence Gate) is dispatched as two implementer calls, not one:

1. Run `scripts/task-brief PLAN_FILE N`, then strip the brief to REQ
   statement + Acceptance Criteria + Test Cases only before handing it to
   the oracle dispatch — the oracle must not see any other task's
   interfaces, any existing code in the touched files, or your own analysis
   of how to implement it. Dispatch it with `test-driven-development`'s RED
   step only: write the failing test(s), verify the failure reason, commit,
   report DONE. This is a fresh subagent — never the same agent instance
   that implements GREEN.
2. Record the oracle's commit. Dispatch the implementer as normal (full
   task brief, per File Handoffs), plus the oracle's test file path and the
   instruction from the Oracle-Independence Gate: make it pass; flag,
   don't edit, a suspected wrong assertion.
3. Before marking the task complete, confirm GREEN didn't modify the
   oracle's assertions.

Everything else about the task — ledger, completion — is
unchanged; only RED authorship is split into a separate, blinder dispatch.
