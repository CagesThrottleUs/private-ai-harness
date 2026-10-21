# Handling Implementer Status

Part of subagent-driven-development. Read from disk at the step that needs it, so it survives compaction.

Record BASE (`git rev-parse HEAD`) before dispatching the implementer — the
final whole-branch review needs the full commit range.

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Mark the task complete in the todo list and progress ledger, then move to the next task.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before moving on. If they're observations (e.g., "this file is getting large"), note them in the ledger and proceed.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, rule on the correction, ledger it (`Ruling: <what> — <why> — <cost if wrong>`), and re-dispatch with the ruling carried in the dispatch. Escalate to the human only for an irreversible, security-sensitive, or outside-the-worktree action, or a plan so broken every path is a guess

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## "Cannot verify from diff" items

If a reviewer reports a requirement it cannot verify from the diff (it lives in unchanged code or spans tasks), resolve it yourself before marking the task complete — you hold the cross-task context the reviewer lacks. A confirmed gap is a failed review: dispatch a fix subagent.
