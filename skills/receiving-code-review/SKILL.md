---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation
---

# Code Review Reception

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each — including sibling occurrences of the same pattern (see Pattern Propagation Check below)
```

## Forbidden Responses

**NEVER:**
- "You're absolutely right!" (explicit CLAUDE.md violation)
- "Great point!" / "Excellent feedback!" (performative)
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Example:**
```
your human partner: "Fix 1-6"
You understand 1,2,3,6. Unclear on 4,5.

❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later
✅ RIGHT: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."
```

## Source-Specific Handling

### From your human partner
- **Trusted** - implement after understanding
- **Still ask** if scope unclear
- **No performative agreement**
- **Skip to action** or technical acknowledgment

### From External Reviewers
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all platforms/versions?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF can't easily verify:
  Say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"

IF conflicts with your human partner's prior decisions:
  Stop and discuss with your human partner first
```

**your human partner's rule:** "External feedback - be skeptical, but check carefully"

## Design Principles Check for Suggested Changes

Before implementing any reviewer suggestion that changes structure, adds abstractions, or refactors:

```
Run design-principles Review Checklist against the suggested change:
- Does this create an abstraction with one concrete use? (YAGNI / KISS)
- Does this add an interface without an extensibility REQ? (YAGNI)
- Does this move logic that belongs where it is? (SoC)
- Does this introduce a pattern that has no concrete need? (GoF / YAGNI)

IF suggestion fails checklist:
  Push back with the specific principle it violates
  Reference design-principles skill if reviewer wants full context

IF suggestion passes checklist:
  Implement it
```

## YAGNI Check for "Professional" Features

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly — but still verify against design-principles checklist
```

**your human partner's rule:** "You and reviewer both report to me. If we don't need this feature, don't add it."

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

## Pattern Propagation Check (Fix It Everywhere, Not Just Here)

A review comment on one line is usually evidence of a pattern, not an isolated typo. Superficial compliance — patch the exact line quoted, ignore the same defect three files over — costs another review round when the reviewer finds the sibling instance. Real compliance closes the whole pattern in one pass.

```
FOR each finding accepted as correct:
  1. Name the underlying defect in one phrase, not "this line"
     (e.g. "missing null check before use", "unbounded query", "copy-pasted validation logic")
  2. Search the CURRENT PR's diff — changed files only — for the same defect
  3. Fix every occurrence found, in this pass, not just the one quoted
  4. State which other files/lines got the same fix — don't make the reviewer re-discover them
```

**Scope stays the current PR's diff, not the whole repo.** Google's engineering practices explicitly warn against scope creep: a fix PR that starts touching unrelated files is harder to review and regression-test. Propagation searches the files this PR already changed. If the same defect exists in untouched, unrelated files, name it as a follow-up instead of pulling it into this PR.

**Why this shrinks turnaround:** every extra review round is a full reviewer pass plus wait time, not just the diff line. Software testing's defect-clustering principle (defects concentrate rather than scatter uniformly) predates AI code review by decades and still applies to LLM-authored diffs — where one instance of a pattern was written, a sibling usually was too, because the same prompt or the same copy-paste produced both.

**If the same defect keeps recurring across separate, unrelated PRs over time** — not just within one diff — that's not a fix-it-here problem, it's a missing guardrail. Flag it for a persistent rule (`AGENTS.md`/`CLAUDE.md`, a lint rule, a reviewer-agent check) so future PRs don't reintroduce it, the same way modern AI review tools turn recurring past-PR feedback into enforced per-repo rules rather than re-litigating it every time.

## Style vs. Substance Triage

Not every disagreement is worth the same fight:
- **Style/convention preference** (formatting, naming taste, "I'd write it differently") → defer to the project's established convention or the reviewer's preference. Not worth pushing back on.
- **Correctness/design substance** (breaks behavior, violates an architectural decision, introduces a real bug) → verify first, then push back with technical reasoning if wrong.

Picking the wrong fight on style burns credibility for the substance pushback that actually matters.

## When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature) — see design-principles skill
- Violates KISS (adds abstraction with one concrete use)
- Violates SoC, SRP, or DIP — use design-principles Review Checklist as the argument
- Technically incorrect for this stack
- Legacy/compatibility reasons exist
- Conflicts with your human partner's architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code
- Involve your human partner if architectural

**Signal if uncomfortable pushing back out loud:** "Strange things are afoot at the Circle K"

## Acknowledging Correct Feedback

When feedback IS correct:
```
✅ "Fixed. [Brief description of what changed]"
✅ "Good catch - [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the code]

❌ "You're absolutely right!"
❌ "Great point!"
❌ "Thanks for catching that!"
❌ "Thanks for [anything]"
❌ ANY gratitude expression
```

**Why no thanks:** Actions speak. Just fix it. The code itself shows you heard the feedback.

**If you catch yourself about to write "Thanks":** DELETE IT. State the fix instead.

## Gracefully Correcting Your Pushback

If you pushed back and were wrong:
```
✅ "You were right - I checked [X] and it does [Y]. Implementing now."
✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."

❌ Long apology
❌ Defending why you pushed back
❌ Over-explaining
```

State the correction factually and move on.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just act |
| Blind implementation | Verify against codebase first |
| Batch without testing | One at a time, test each |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify all items first |
| Can't verify, proceed anyway | State limitation, ask for direction |
| Fixed only the quoted line, left sibling occurrences in the diff | Search the current PR's diff for the same pattern, fix every occurrence in this pass |

## Real Examples

**Performative Agreement (Bad):**
```
Reviewer: "Remove legacy code"
❌ "You're absolutely right! Let me remove that..."
```

**Technical Verification (Good):**
```
Reviewer: "Remove legacy code"
✅ "Checking... build target is 10.15+, this API needs 13+. Need legacy for backward compat. Current impl has wrong bundle ID - fix it or drop pre-13 support?"
```

**YAGNI (Good):**
```
Reviewer: "Implement proper metrics tracking with database, date filters, CSV export"
✅ "Grepped codebase - nothing calls this endpoint. Remove it (YAGNI)? Or is there usage I'm missing?"
```

**Unclear Item (Good):**
```
your human partner: "Fix items 1-6"
You understand 1,2,3,6. Unclear on 4,5.
✅ "Understand 1,2,3,6. Need clarification on 4 and 5 before implementing."
```

**Pattern Propagation (Good):**
```
Reviewer: "This handler doesn't check `user` for nil before calling .Role()"
✅ "Fixed. Same missing nil check was in the other 2 handlers this PR touched
   (auth.go:88, session.go:41) — fixed those too."
```

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

Reply to every comment, even trivial ones — a silent fix with no reply leaves the reviewer unsure whether it was seen or ignored. "Fixed." is a sufficient reply; no reply is not.
