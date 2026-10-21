# Batching Small Same-Shape Tasks

Part of subagent-driven-development. Read from disk at the step that needs it, so it survives compaction.

When consecutive tasks are the same shape (e.g. "add field X to model A", "add
field Y to model B", each touching one file with a complete, literal spec),
dispatch them as one implementer call carrying all the briefs, not one
dispatch per task. Batch only when: each task is independently a cheap-model
task per Model Selection below, none depends on another's output, and the
plan's per-task Interfaces blocks don't collide. The final whole-branch
review still verifies every file named across all the batched briefs shows
up in the diff — a batch that silently drops one task's file is not
complete. Tightly
coupled or judgment-heavy tasks are never batched.
