---
name: pr-review-non-negotiables
description: >
  Global, tool-agnostic PR review checklist. Apply every time a PR or diff is
  reviewed — via pr-reviewer, giving-code-review, requesting-code-review,
  scout-pr-review, or any ad-hoc review — regardless of which repo or which
  reviewer tool is doing the reviewing.
---

# PR Review Non-Negotiables

These are hard gates, not preferences. A review that skips one silently is a
worse review than one that flags "not applicable" and says why.

1. **Backward compatibility** — preserve existing behavior/contract unless
   the prior behavior was itself a bug, defect, or incorrect result. A
   deliberate break must say so and name what it replaces.

2. **Migration** — any behavior, config, or compatibility change that breaks
   an existing client must migrate that client automatically. No manual
   intervention required from users on the old path. Use the **expand-contract
   (parallel change)** pattern for anything that can't flip atomically: expand
   (add the new path alongside the old, both work), migrate (move callers/data
   over, monitor usage until it hits zero), contract (remove the old path only
   after usage is verified at zero — not assumed). A change with no expand
   phase and no verified-zero-usage check before removing the old path is a
   finding, not a nit.

3. **Performance** — no regression. A change that trades correctness/features
   for slower hot paths needs an explicit call-out and justification, not a
   silent trade.

4. **Reuse** — check for an existing construct (helper, abstraction, pattern)
   before accepting a new one. A new one next to an equivalent old one is a
   finding, not a style nit.

5. **Testing** — coverage must be detailed enough that a regression on this
   change surfaces in CI, not in production. Judge tests by "would this catch
   a real regression," not by "does a test exist."

6. **Security** — no new vulnerability or gap. Apply the standard checklist
   (secrets, injection, resource exhaustion, path traversal, deserialization,
   permissions, dependency provenance) regardless of what other dimensions the
   PR review tool already covers.

7. **Why / ROI** — every change should trace to a real user problem with
   enough payoff to justify the change. A change with no stated why, or a why
   that doesn't hold up, is a finding.

8. **User experience** — no degradation, including forcing a rebuild, reindex,
   restart, or other disruptive step the user didn't already expect.

9. **Determinism** — prefer structured, machine-distinguishable output
   (typed fields, enums, explicit status codes, file+line+severity+category)
   over prose an agent has to parse heuristically. This applies to what the
   *reviewed change* emits, not just to the review output itself. A finding
   or a result an agent needs to act on next should be schema-shaped, not a
   paragraph the next step has to re-parse — if it isn't encoded somewhere
   structured and machine-accessible, the next agent in the chain can't
   reliably reason about it.

10. **Overengineering / underengineering balance** — flag both directions.
    Speculative abstraction, unused flexibility, and premature generalization
    are findings exactly like duct-taped fixes and missing structure are. Test
    each new abstraction against YAGNI's actual bar: not "might this be
    useful later" but "do I have enough confidence I can add this cheaply via
    refactor when a second real caller shows up" — if yes, defer it now and
    flag the premature version as a finding.

11. **Compatibility matrix** — if the product ships multiple supported
    deployment modes, backend combinations, or operating configurations
    (e.g. distributed vs single-node, index-only vs full, online vs offline),
    verify the change works across every mode it claims to support — not just
    the reviewer's default local setup. Name the modes checked.

## Applying this with scout-pr-review

`scout-pr-review` (global skill, Scout MCP) already has a repo-specific hook —
`.scout/review-policy.md`, read in its Phase 0 and applied in Phase 5/7. These
non-negotiables are the meta layer above that: they apply everywhere,
independent of whether a given repo ships a `.scout/review-policy.md`. When
both are present, repo policy adds detail; it never overrides a non-negotiable
here.
