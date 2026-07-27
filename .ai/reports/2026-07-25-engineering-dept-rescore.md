# Engineering-Department Capability — Re-Score (Round 2, after open-item closure)

**Date:** 2026-07-25
**Supersedes:** the Round-1 re-score (same filename, prior revision),
`2026-07-25-engineering-dept-benchmark.md`, and
`2026-07-25-engineering-standards-rubric.md`.
**What changed since Round 1:** the measurement loop and the six named remaining
open items were closed this round (8 commits, `f3f28ad`…`9c8ccd4`), each grounded
in a named standard via fresh web research and kept AI-age appropriate. Version
3.3.0 → 3.4.0. One new skill (`outcome-review`) + one new reviewer
(`outcome-review-reviewer`); the rest are enhancements to skills/agents already
wired into the `engineer` lanes.

Scale unchanged: 10 = meets or exceeds an elite human org against the named
standard, **measured as guidance-vs-standard** (this repo is a plugin of skills,
not a running platform — a 10 means the skill prescribes the elite practice with
the right gate, not that a server executes it). "10★" = exceeds the elite baseline.

---

## What closed this round

| Item (Round-1 open) | Standard grounded | Closure |
|---|---|---|
| **Measurement loop (business outcome)** — the "did the metric move?" leg was absent | North Star Framework; Google HEART; Lean Startup validated-learning; Working Backwards | New `outcome-review` skill + reviewer: measures the intake north-star + input metrics vs target at HEART-aligned checkpoints, every value cites a re-runnable source, renders persevere/iterate/kill, feeds the portfolio. AI-fabrication guard: a number without a source is `not measured`. |
| **Token governance** (Part-3 gap) | LLM FinOps 5-layer budget; circuit-breaker pattern; per-agent attribution | `cost-checkpoint budget --cap` circuit breaker (exit 3 on breach → halt like BLOCKED; 80% FinOps warn); per-subagent `agent`-row attribution promoted from optional to required at every dispatch. Monitoring → enforcement. |
| **Row 17** delivery ledger never populated | DORA 2024/2025; getDX | `delivery-record` upserts from real events — deploy (finishing), incident-start/resolve (incident-response), slo (observability). CFR/MTTR/reliability now from data, not a hand-edited file. |
| **Row 11** canary auto-rollback partial | Argo Rollouts/Flagger/Kayenta; CARM L1–L2; SLO-based rollback | Canary strategy now **requires** automated analysis with SLI queries tied to the SLO doc and auto-abort→rollback; reviewer flags human-watched-only canary as Critical. |
| **Row 14** incident action-items + DiRT | Google SRE postmortem action-item closure; DiRT; Wheel of Misfortune | Corrective actions become tracked, owned, due-dated tickets with a standing closure review + closure-rate signal + feedback into SLOs; DiRT/game-day drills on a cadence; reviewer D6/D7. |
| **Row 16** self-service provisioning | CNCF Platform Eng Maturity L4; Backstage templates; Terraform module registry | Infra provisioned by instantiating a curated, versioned golden-path module (policy-as-code inside the module = compliant by construction), not bespoke HCL; both skills mark L4-vs-manual honestly. |
| **Row 3 "push to 11"** | ISO/IEC/IEEE 29148 individual+set characteristics; Femmer/Smella | Spec reviewer Section 4: lexical requirements-smell lint (subjective/weak-verb/loophole/superlative/non-atomic) mapped to the 9 individual + 5 set characteristics; cited FAIL with the trigger word + measurable rewrite. |

---

## Re-scored scorecard (Δ from Round 1)

| # | Capability | R1 | R2 | What moved it |
|---|---|---|---|---|
| 1 | Business intake | 9 | **9** | unchanged |
| 2 | Ideation & alternatives | 10 | **10** | — |
| 3 | Spec quality | 10 | **10★** | + ISO 29148 individual/set smell lint beneath the falsifiability judgment — a deterministic layer most elite specs still do by hand |
| 4 | Architecture | 10 | **10** | — |
| 5 | Contract-first | 10 | **10** | — |
| 6 | Decomposition | 10 | **10** | — |
| 7 | Implementation | 10 | **10** | — |
| 8 | Code review | 10★ | **10★** | — |
| 9 | Testing | 10★ | **10★** | — |
| 10 | CI/CD | 10 | **10** | — |
| 11 | Deployment & release | 9 | **10** | SLO-based automated canary auto-rollback now required + gated (CARM L1–L2, the elite deployment-safety bar). L3+ auto-*remediation* is beyond the bar, not under it |
| 12 | Observability | 10 | **10** | — |
| 13 | Production Readiness Review | 10 | **10** | — |
| 14 | Incident response | 9 | **10** | action-item closure loop + feedback into SLOs + DiRT drills — the SRE-culture pieces that were the only gap |
| 15 | Docs & onboarding | 10 | **10** | — |
| 16 | Platform / golden paths | 9 | **10** | self-service golden-path module provisioning, compliant-by-construction (CNCF L4 mechanism). A literal one-click IDP portal is out of scope for a skills plugin — the pattern + guardrail is what's scored |
| 17 | Delivery measurement | 9 | **10** | delivery ledger auto-populated from real deploy/incident/SLO events → CFR, MTTR, reliability are now data-derived, not withheld |
| 18 | Portfolio / org | 9 | **9** | now consumes `outcome-review` persevere/iterate/kill as a WSJF re-rank input; continuous Kanban/OKR automation still manual → held at 9 |
| — | **Outcome measurement (new)** | (absent) | **9** | `outcome-review` closes the business-outcome leg with an AI-fabrication guard; not 10 because it needs real analytics access and is invoked, not continuous |
| — | **Token governance (Part-3)** | (open) | **9** | monitoring → enforcement (circuit breaker + required per-subagent attribution); not 10 because there's no cross-session/org spend policy or dollarized cap — deliberately tokens-only |

**Aggregate:**
- Per-epic SDLC rigor (1–15): **≈ 10.0/10** — effectively all 10s, five now beyond the elite baseline.
- Platform & measurement (16, 17, outcome, token-gov): **≈ 9.5/10** — was ~9.0.
- Portfolio / department (18): **9/10**.
- **Overall: ~9.8/10, up from Round-1 ~9.6 (and a blended ~7 at the start).**

---

## The measure leg is now pervasive

The standing meta-principle is **write it down → review it → measure what you
shipped.** Before this round the third leg was the thin one. It is now woven
through the harness at all three time horizons:

- **Build-time quality:** test pyramid + mutation score + CISQ/ISO-5055 structural
  measure + perf NFRs + lint gate. (already strong)
- **Delivery-time:** `delivery-metrics` DORA four keys + reliability + flow
  efficiency, now **data-derived** because `delivery-record` fills the ledger from
  real events. Error-budget/SLO enforced.
- **Outcome-time (the closed hole):** `outcome-review` returns to the intake
  north-star and records whether it actually moved, with a persevere/iterate/kill
  decision fed back to the portfolio.
- **Cost:** the engineer cost-ledger, now with an enforced spend circuit breaker.

Write and review were always pervasive; measure now matches them.

---

## Honest remaining boundary (next round candidates)

Grounded in the 2025/2026 sources below — the frontier moved while we closed the
Round-1 list:

1. **The "why" layer beyond DORA.** 2025 DORA and SPACE/DX research is explicit
   that delivery metrics tell you *what* happened, not *why*, and are "no longer
   sufficient" alone. The harness measures the *what* (DORA) and the *outcome*
   (north-star) but has no SPACE-style human/why signal (developer experience,
   satisfaction, rework rate). DORA added a 5th signal — **Rework Rate** — in 2025
   that `delivery-metrics` does not yet compute.
2. **Auto-remediation (CARM L3–L4).** Canary auto-rollback is CARM L1–L2. Closed-
   loop auto-*remediation* with policy gates (L4) is beyond the current bar.
3. **Continuous, not invoked.** `outcome-review`, `delivery-metrics`, and the
   portfolio Kanban are run on demand. A scheduled/event-driven runner would make
   the measure + portfolio legs continuous rather than manual.
4. **Token governance dollarization & org policy.** The circuit breaker enforces a
   per-session token cap; there is no cross-session/org budget policy or dollar
   conversion (deliberately — pricing drifts), and no model-tier auto-routing on
   approaching the cap.
5. **A running IDP.** Self-service provisioning is prescribed as a golden-path
   module pattern; a literal Backstage-style portal is out of scope for a skills
   plugin and would be a separate product.

---

## Sources (this round's fresh grounding)

- North Star Framework (Amplitude/Cutler); Google HEART (Rodden et al.); Lean Startup validated learning; Amazon Working Backwards
- ISO/IEC/IEEE 29148 individual vs set quality characteristics; Femmer et al. *Rapid Quality Assurance with Requirements Smells* (Smella)
- Argo Rollouts / Flagger / Kayenta (Mann-Whitney) automated canary analysis; CARM auto-remediation maturity spectrum (L0–L4); SLO-based automated rollback
- Google SRE postmortem action-item closure + DiRT + Wheel of Misfortune
- LLM agent cost governance — 5-layer token budgets, circuit breakers, per-agent attribution (FinOps for agentic AI)
- CNCF Platform Engineering Maturity Model L4; Backstage software templates; Terraform curated module registry
- DORA 2024 performance bands + AI throughput/stability finding; DORA 2025 (Rework Rate, "metrics tell what not why"); SPACE / DX Core 4
