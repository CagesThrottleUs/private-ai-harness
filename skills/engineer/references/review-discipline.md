# Review Discipline (every lane)

Moved verbatim from `SKILL.md` (private-ai-harness 5.0.0) to keep the skill
under the 20,000-byte limit Claude Code applies when it re-attaches skills
after compaction. Read it at the step that points here.

- **Pattern propagation on review fixes:** when a review finding (from `requesting-code-review`, SDD's task reviewer, or a human) is accepted, search the current PR's diff — changed files only — for the same defect pattern before marking it fixed, and fix every occurrence in one pass. This includes analogous paths (CLI vs MCP, primary vs fallback), every call site of a changed shared helper, and a determinism self-check on any new concurrency. See `receiving-code-review`'s Pattern Propagation Check. A reviewer re-finding the same pattern in the next file over next round is the turnaround cost this exists to cut.
- **Zero negotiable review rounds:** never re-trigger an external reviewer until an internal self-review returns clean on the current diff — batch every open finding, fix in one pass, self-review (hunting the same failure classes plus fix-introduced regressions), push once, then re-trigger. Strong default; override only with a recorded reason. See `closing-review-loops`.
- **Proportionality Gate on every accepted finding:** a real, in-scope finding is not automatically "fix it now, fully." If defending the fix needs a formal proof or a multi-call-site truth table, that complexity signals the fix may be disproportionate — take the simpler fix or file a follow-up ticket instead. Read `closing-review-loops`' cumulative commits/LOC receipt every round; propagating and hardening a fix is not license to maximize scope. See `receiving-code-review`'s Proportionality Gate.
