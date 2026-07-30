# PR Turnaround & Review-Round Gap Analysis

**Date:** 2026-07-30
**Author:** engineering-harness audit
**Scope:** Does the harness minimise review rounds / turnaround for AI-authored PRs?
**Trigger:** Observed increase in total turns per PR; goal is high submission quality
at the smallest possible turn-around-time (TAT).

---

## 1. What the research says (2024–2026)

The intuition is confirmed by data: **in the AI era the number of review rounds and
the end-to-end review time per PR have gone UP, not down.** AI shifted the bottleneck
from *writing* code to *reviewing* it.

| Signal | Finding | Source |
|---|---|---|
| Review time | High-AI teams merged **+98%** PRs but **PR review time +91%**, **avg PR size +154%**, **bug count +9%** | DORA Report 2025 (via Faros.ai) |
| Delivery stability | Every +25% AI adoption: throughput **−1.5%**, delivery stability **−7.2%** | DORA Report 2024 |
| Convergence | 28.3% of agent PRs merge almost instantly, but once a PR **enters iterative review, agents frequently fail to converge** — "approval churning", author ghosts the reviewer | MSR 2026 study, 33,707 agent PRs |
| Cycle time | p90 end-to-end cycle time peaked ~66h; p90 for PRs that got **substantive human review climbed to ~114h** | "AI Writes Faster Than Humans Can Review" (arXiv 2607.01904) |
| Issue density | AI-written code surfaces **1.7× more issues** than human-written; ~half of devs say debugging AI output takes longer than fixing human code | CodeRabbit 2025 |
| Review effort | Seniors spend **4.3 min** reviewing an AI suggestion vs **1.2 min** for human code | 2025 study (via LogRocket) |
| Churn | AI correlates with up to **9× code churn**; two-week churn rose **3.3% → 5.7–7.1%** | GitClear |
| Volume pressure | PRs merged **without any review up 31.3%** — reviewers can't keep pace | MSR 2026 |
| **The lever** | A **pre-submission self-review** checklist reduces review time **~28%**; AI raised individual output 2–3×, review capacity stayed flat | metacto / ClackyAI 2026 |

**One-line conclusion:** turns-per-PR increased because AI emits more code, larger diffs,
and code that reads clean but hides defect classes — and the fix loop **fails to converge**.
The proven counter-levers are: (a) small batch size, (b) **author-side pre-submission
self-review**, and (c) a bounded, verified fix loop.

---

## 1.5 Policy under review — "a finding is a pattern signal"

**Proposed policy:** *A review finding is a chance to understand the deep pattern that
missed/failed, and to review the entire codebase / PR for the same issue.*

**Verdict: VALID.** It is the correct generalisation of two long-established principles,
and the AI era strengthens the case for it rather than weakening it — with one scope
refinement (below).

### What humans did pre-AI

- **Defect clustering** (one of the ISTQB seven testing principles): defects concentrate in
  a few high-complexity, frequently-modified modules — they don't scatter uniformly. Finding
  one bug in a hotspot is a signal to test *wider* in that area.
- **Root Cause Analysis / Five Whys:** a single fix treats the symptom; RCA finds the
  systemic cause and "implements changes to prevent similar issues in future." Defect
  *analysis* looks across many bugs for the pattern; a single-bug patch does not.
- **The pre-AI constraint:** the codebase-wide sweep was **manual and expensive**, so the
  discipline was applied *selectively* — to the clustered hotspot, not literally the whole
  repository on every finding. Cost gated the breadth. Most teams swept the adjacent module,
  not the codebase.

### What it looks like in the AI world

Two things changed, both in the policy's favour:

1. **Detection is now cheap.** Semantic search, code-graph tools (tokensave / Scout), and
   AI "codebase scan" products (Sourcegraph Code Insights, cubic, CodeRabbit *similarity
   retrieval*) can sweep the **entire repository** for siblings of a finding in seconds —
   the cost that used to gate breadth is gone. CodeRabbit surfaces "a different test with the
   same callback pattern and proposes the same fix" automatically.
2. **The "prevent future" leg is now automatable.** Qodo's *Rules Miner* turns recurring PR
   comments into **enforceable repo rules** that run on every PR and decay when stale. RCA's
   final step — stop the pattern from recurring — becomes a persistent guardrail, not a note
   in a postmortem.

And AI makes the clustering **stronger**: the same prompt or copy-paste that emitted one
instance emitted its siblings in the same generation, so an LLM diff is *more* likely to
contain a cluster than a hand-written one.

### The one refinement: detection breadth ≠ fix breadth

The policy says "review the entire codebase / PR." Correct — but split the two verbs:

| Action | Correct scope in AI era | Why |
|---|---|---|
| **Detect** (read-only sweep) | **Entire codebase** — cheap now | Cost no longer gates breadth; siblings hide in untouched files |
| **Fix** | **This PR's diff only** | Google's scope-creep rule: a fix PR that grows to touch unrelated files gets harder to review and regression-test — the very thing that inflates turns |
| **Out-of-diff siblings** | Tracked follow-up **+ enforced repo rule** | Qodo Rules-Miner pattern: promote the pattern to a guardrail so it can't reappear, instead of silently expanding this PR |

So the policy operationalises as: **every accepted finding triggers a codebase-wide
*detection* sweep; in-diff siblings are fixed this pass; out-of-diff siblings become a named
follow-up plus a persistent guardrail (`AGENTS.md`/`CLAUDE.md` rule, lint rule, or a
reviewer-agent check).** This keeps the turn-reduction benefit without importing scope creep.

---

## 2. What the harness already does right

Do not re-invent these — they already align with the evidence:

- **PR Size Gate** (`requesting-code-review`) — hard-blocks >1000 LOC, warns 401–1000.
  This is the single best-measured lever and it is already stricter for AI diffs. ✅
- **Review Latency Norm** — first response within one business day. ✅
- **AI-Authored-Code Risk dimension** (`pr-reviewer` Dim 6 + `requesting-code-review`) —
  hallucinated APIs, dropped authz, happy-path-only. ✅
- **Pattern Propagation Check** (`receiving-code-review`, added 3.8.0) — fix every sibling
  occurrence in the diff so the reviewer doesn't re-discover them next round. ✅ (directly
  attacks extra rounds)
- **Trust-but-verify** (`giving-code-review` Step 3) + **self-review mode** (Step 5). ✅
- **Reviewer Dispatch Discipline** — one fix agent per findings batch, re-dispatch until PASS. ✅
- **SDD 5-round fix loop** with escalation and park/BLOCK at the cap. ✅ (but scoped to SDD only)

---

## 3. Gaps (ranked by impact on turns-per-PR)

### GAP 1 — No mandatory author-side pre-submission self-review gate  ⭐ highest leverage
**Evidence:** pre-submission self-review cuts review time ~28% — the strongest cheap lever.
**Current state:** `giving-code-review` HAS a rigorous self-review mode (Step 5: check out
and run it, adversarial pass, context switch, verify claims). But it is only invoked when a
human *chooses* to review their own PR via `gh`. The author path — `requesting-code-review`
→ dispatch `pr-reviewer` — only runs a `design-principles` self-check. It dispatches the
Opus reviewer **before** the author has run the adversarial self-pass.
**Consequence:** the first review round is spent on defects the author could have caught for
free. Every such round is a full reviewer pass + wait.
**Fix:** make `giving-code-review` Step 5 (self-review) a **mandatory gate inside
`requesting-code-review`** — run the AI-defect-class self-pass and fix findings *before*
the first `pr-reviewer` dispatch. "Self-review clean" becomes a precondition for requesting.

### GAP 2 — No convergence guard on the general review→fix→re-review loop
**Evidence:** agents "fail to converge" / "approval churning" is THE named AI failure mode.
**Current state:** only `subagent-driven-development` has a round cap (5) + escalation.
`requesting-code-review` says "re-dispatch the same reviewer after fixes; repeat until PASS"
— **unbounded, no convergence tracking.**
**Consequence:** the exact non-convergence the research documents is unguarded outside SDD.
**Fix:** add a **Review Round Ledger + convergence guard** to `requesting-code-review`:
track round number and findings hash; if a fix produces new findings or re-opens a closed
one for N rounds, stop the loop and escalate to a human / stronger model instead of churning.
Port the SDD cap pattern to the general loop.

### GAP 3 — Receiving side does not verify the fix actually closes the finding
**Current state:** `receiving-code-review` Step 6 implements "one item at a time, test each",
plus Pattern Propagation. There is no step that **proves each finding is closed and no
regression/new finding was introduced** before re-requesting review.
**Consequence:** a fix that doesn't fully resolve → the reviewer re-raises it → another round.
This is the receiving-side mirror of GAP 2.
**Fix:** add a **Fix-Verification step** to `receiving-code-review`: for each accepted
finding, state the falsifiable check that proves it closed, run it, and confirm no new
finding was created — before re-submitting for review.

### GAP 4 — No "resolve every severity in one pass" discipline
**Current state:** severity table says Critical→fix now, Important→before merge, Minor→"note
for later." Leaving Minors un-actioned invites the reviewer to re-raise them next round.
**Fix:** require that a re-request addresses **every** returned finding as either fixed OR
explicitly declined-with-reason (incl. Minors). Nothing silently deferred → no Minor-driven
extra round.

### GAP 5 — Review-rounds-per-PR is not a tracked delivery metric
**Current state:** `delivery-metrics` tracks DORA + flow efficiency but not **review
iterations per PR** or **rework churn** — the very quantities this report is about.
**Consequence:** we can't tell if any of these fixes actually reduced turns. "Measure" leg
of Document→Review→Ship→Measure is missing for review TAT.
**Fix:** add **review-rounds-per-PR** and **first-pass approval rate** as delivery keys
(guardrail metrics, not north-star). Source from the Review Round Ledger (GAP 2).

### GAP 6 — No noise floor / nit-suppression in pr-reviewer
**Evidence:** AI reviewers are nitpicky; noise causes important findings to be missed and
generates churn rounds over trivia.
**Current state:** `pr-reviewer` has severity calibration ("not everything is Critical") but
no explicit rule to **suppress or batch pure style nits** so they never gate a round.
**Fix:** add a nit-handling rule — pure style/nits are collected into a single non-blocking
"Advisory (batch)" note, never a reason to fail a review round; a formatter/linter owns them,
not a reviewer round.

### GAP 7 — PR body carries no author-verification attestation / risk lane
**Evidence:** 2026 pre-screening standard = disclose what the author *personally verified* +
risk lane, so the reviewer focuses effort and skips what's already proven.
**Current state:** `pr-creator` body has a Test Plan but no "Verified by author" attestation
and no risk-lane tag.
**Fix:** add a **"Verified by author"** block + risk-lane tag to the `pr-creator` body
template — primes the reviewer, shrinks the first-round surface.

### GAP 8 — Pattern sweep is diff-bounded; no codebase-wide detection, no rule-promotion  ⭐ (from §1.5 policy)

**Evidence:** defect clustering + RCA say a finding is a pattern signal; AI-era tooling makes
whole-codebase *detection* cheap (similarity retrieval, code-graph, codebase scans) and lets
recurring findings become *enforced repo rules* (Qodo Rules Miner).
**Current state:** the harness's **Pattern Propagation Check** (`receiving-code-review`)
deliberately bounds the sweep to the **PR diff only**. That was the right call when the only
tool was manual grep — but this repo has `tokensave` and `Scout` indexed, so a codebase-wide
*detection* sweep is now nearly free and is being left on the table. There is also **no step
that names the root-cause pattern** behind a finding, and **no mechanism to promote a
recurring finding to a persistent guardrail** — the RCA "prevent recurrence" leg is missing.
**Consequence:** siblings in untouched files ship undetected (caught "three days after merge"
per the research), and the same pattern re-arrives in the next PR, costing a fresh review
round every time — the exact turn-inflation this report targets.
**Fix (three parts, respecting detection-breadth ≠ fix-breadth from §1.5):**

1. **Name the root cause.** Add a step to `receiving-code-review` and `pr-reviewer`: for each
   accepted finding, state the underlying pattern in one phrase, not "this line."
2. **Sweep the whole codebase for detection.** Use `tokensave`/`Scout` (or ripgrep fallback)
   to find every sibling repo-wide — not just the diff. Fix in-diff siblings this pass;
   record out-of-diff siblings as a named follow-up (do **not** expand the PR).
3. **Promote recurring patterns to a guardrail.** If a pattern recurs across separate PRs,
   add an enforced rule (`AGENTS.md`/`CLAUDE.md`, lint rule, or reviewer-agent check) so it
   cannot reappear — the Rules-Miner mechanism, done manually via the doc-sync triple.

This upgrades the existing (good) diff-bounded propagation into the full policy: **detect
codebase-wide, fix PR-bounded, prevent via a persistent rule.**

---

## 4. Recommended action plan (in priority order)

| # | Change | Skill/Agent | Bump |
|---|---|---|---|
| 1 | Wire self-review as a mandatory pre-dispatch gate | `requesting-code-review` (reuse `giving-code-review` Step 5) | minor |
| 2 | Review Round Ledger + convergence guard (port SDD cap) | `requesting-code-review` | minor |
| 3 | Fix-Verification step before re-request | `receiving-code-review` | patch |
| 4 | Resolve-every-severity-in-one-pass rule | `receiving-code-review` | patch |
| 5 | review-rounds-per-PR + first-pass approval rate metric | `delivery-metrics` (+ reviewer) | minor |
| 6 | Nit-batch / noise-floor rule | `agents/pr-reviewer.md` | patch |
| 7 | "Verified by author" + risk-lane in PR body | `pr-creator` | patch |
| 8 | Root-cause naming + codebase-wide detection sweep + rule-promotion of recurring patterns | `receiving-code-review`, `agents/pr-reviewer.md` | minor |

**Biggest single win:** #1 + #2 together — force the author to burn zero reviewer rounds on
self-catchable defects, and bound the loop so non-convergence escalates instead of churning.
These two attack the exact mechanism the 2026 studies name.

**Highest structural leverage:** #8 — it converts every finding into a codebase-wide pattern
kill plus a permanent guardrail, so a class of defect costs at most one review round *ever*
instead of one round per PR that reintroduces it. This is the "a finding is a pattern signal"
policy, operationalised.

Doc-sync: any of the above requires updating `AGENTS.md`, `CLAUDE.md`, `README.md` (triple)
and bumping all three manifests.

---

## Sources

- [DORA Report 2025 Key Takeaways (Faros.ai)](https://www.faros.ai/blog/key-takeaways-from-the-dora-report-2025)
- [AI Writes Faster Than Humans Can Review — longitudinal enterprise study (arXiv 2607.01904)](https://arxiv.org/pdf/2607.01904)
- [Let's Make Every Pull Request Meaningful — agentic PR analysis (arXiv 2601.18749)](https://arxiv.org/pdf/2601.18749)
- [These Aren't the Reviews You're Looking For — humans reviewing AI PRs (arXiv 2605.02273)](https://arxiv.org/html/2605.02273v1)
- [Early-Stage Prediction of Review Effort in AI-Generated PRs (arXiv 2601.00753)](https://arxiv.org/html/2601.00753)
- [AI code looks fine until the review starts — CodeRabbit report (Help Net Security)](https://www.helpnetsecurity.com/2025/12/23/coderabbit-ai-assisted-pull-requests-report/)
- [Why AI coding tools shift the real bottleneck to review (LogRocket)](https://blog.logrocket.com/ai-coding-tools-shift-bottleneck-to-review/)
- [AI Is Breaking Code Review (Codacy)](https://blog.codacy.com/ai-breaking-code-review-how-engineering-teams-survive-pr-bottleneck)
- [AI Writes 41% of Code — Code Churn Doubling in 2026 (DEV / GitClear)](https://dev.to/code-board/ai-writes-41-of-code-now-but-code-churn-is-doubling-in-2026-372f)
- [Establishing Code Review Standards for AI-Generated Code (metacto)](https://www.metacto.com/blogs/establishing-code-review-standards-for-ai-generated-code)
- [Code Review Checklist for AI-Generated Code (ClackyAI)](https://clacky.ai/blog/code-review-checklist-ai-generated-code)
