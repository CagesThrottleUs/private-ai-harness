# Final Review

Part of subagent-driven-development. Read from disk at the step that needs it, so it survives compaction.

The final whole-branch review gets a package too: run
`scripts/review-package PLAN_FILE MERGE_BASE HEAD` (MERGE_BASE = the commit the
branch started from, e.g. `git merge-base main HEAD`) and include the
printed path in the final review dispatch, so the final reviewer reads
one file instead of re-deriving the branch diff with git commands.

If the final whole-branch review returns findings, dispatch ONE fix
subagent with the complete findings list — not one fixer per finding.
Per-finding fixers each rebuild context and re-run suites; a real
session's final-review fix wave cost more than all its tasks combined.
Then run exactly one scoped re-review of the fix wave
(`scripts/review-package PLAN_FILE FIX_BASE HEAD` over the fix range,
[re-review-prompt.md](../re-review-prompt.md)). Load-bearing residual findings
surface to your human partner when finishing-a-development-branch presents
the options. There is no second fix wave.
