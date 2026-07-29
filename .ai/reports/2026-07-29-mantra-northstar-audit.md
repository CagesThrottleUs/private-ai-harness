# Mantra + Northstar Audit — Action Plan

**Date:** 2026-07-29
**Scope:** 57 skills + 33 reviewer agents
**Mantra audited:** Document it → Review it → Ship it → Measure it
**Method:** 3-agent corpus sweep + web validation (North Star Metric, DORA, Google HEART/GSM, Spec-Driven Development 2025)

---

## Verdict

- **Mantra:** covered as a *system*; leaks at three seams as *individual units*.
- **Northstar:** near-absent — only 5/57 skills and 3/33 agents tie to a *business* north-star; most "northstar-ish" refs are SLO/NFR/DORA delivery proxies, which industry treats as delivery metrics, **not** business outcome.

The one real business-metric thread:

```
business-context-intake (defines NSM: one metric, baseline, target)
  → brainstorming        (anchors design to success metric)
  → engineer epic lane
  → outcome-review       (measures NSM vs target, re-runnable source)
  → portfolio-management (OKR linkage, WSJF business-value)
```

Guarded only by `business-context-reviewer`, `outcome-review-reviewer`, `portfolio-reviewer`. The **middle is unguarded** — everything between intake and outcome-review ships with no "does-this-move-the-needle" check.

---

## Findings → Actions

### A1 — Thread the NSM through the middle (highest leverage)
**Problem:** NSM held only at the two ends. The "inputs teams influence daily" layer of the North Star framework is missing from planning/PR. `pr-reviewer` (primary merge gate) never asks whether a change serves the business metric.
**Action:**
- Carry business-context north-star into spec YAML frontmatter.
- Propagate into plan `## Global Constraints`.
- Add to PR body template.
- Add one check to `spec-impl-reviewer` and/or `pr-reviewer`: "which input metric of the NSM does this change serve?"
**Effort:** small, surgical (template + prompt edits).
**Standard:** North Star Metric — inputs teams can directly influence.

### A2 — Add `delivery-metrics-reviewer` (close producer/reviewer asymmetry)
**Problem:** `delivery-metrics` self-scores DORA + flow efficiency with no independent gate. Every other producing skill has a dedicated reviewer.
**Action:** add `agents/delivery-metrics-reviewer.md` (sonnet — mechanical) OR fold the check into an existing gate. Update AGENTS.md / README.md / model right-size table.
**Effort:** small.

### A3 — Gate `research-spike` output
**Problem:** research-spike writes a decision artifact / ADR that drives **build-or-kill** decisions, yet dispatches no reviewer and runs no self-gate. Only unreviewed doc-producer that feeds a go/no-go.
**Action:** add a lightweight self-gate or route the findings artifact through an existing reviewer (e.g. reuse `hld-reviewer` for ADR-class output).
**Effort:** small.

### A4 — Separate "delivery metric" from "business north-star" in docs
**Problem:** ci-pipeline, deployment, delivery-metrics, incident-response cite DORA / SLO / MTTR and read as northstar-adjacent. Industry is explicit: DORA measures the *delivery loop*, not business outcome. SLO-passing work can masquerade as outcome-achieving.
**Action:** add an explicit distinction in AGENTS.md (and relevant SKILL bodies): delivery/reliability metric ≠ business north-star.
**Effort:** small (doc-only).
**Standard:** DORA (delivery outcomes); HEART/GSM (avoid vanity metrics).

### A5 — Emit in-chat completion summary for testing/infra cluster
**Problem:** chaos, dast, database-erd, e2e, iac, integration-testing, deployment surface results only via commit message + reviewer verdict — no explicit in-chat completion summary. `user_informed` = Partial. Same for refactoring / TDD / subagent-driven (code + git-ignored ledger only).
**Action:** add a short "what was produced / where / verdict" chat report to each skill's final step.
**Effort:** medium (touches ~10 skills).

---

## Supporting audit data

### Doc-producers with NO reviewer gate
research-spike (A3), codebase-comprehension, epic-decomposition, code-documentation, writing-skills (self-test only).

### Business-northstar coverage
- **Skills (5/57):** business-context-intake, brainstorming, engineer, outcome-review, portfolio-management.
- **Agents (3/33):** business-context-reviewer, outcome-review-reviewer, portfolio-reviewer.
- **NFR/SLO-only (not business):** spec-quality-reviewer, hld-reviewer, plan-reviewer, load-test-reviewer, observability-reviewer, api-contract-reviewer, deployment-reviewer, production-readiness-reviewer, incident-response-reviewer, onboarding-reviewer, chaos-reviewer.

### Reviewer verdict surfacing
Universal — all 33 agents emit structured PASS/FAIL or severity; verdict always returns to context (REPORT_FILE optional). No silent swallow.

---

## Priority order

1. **A1** — thread NSM through middle (highest leverage, small)
2. **A2** — delivery-metrics-reviewer (closes only reviewer gap, small)
3. **A3** — gate research-spike (build/kill artifact unreviewed, small)
4. **A4** — delivery-metric vs north-star doc separation (doc-only)
5. **A5** — in-chat completion summaries (medium, broad)

---

## Sources
- North Star Framework — https://www.productcompass.pm/p/the-north-star-framework-101
- DORA metrics — https://dora.dev/guides/dora-metrics/
- Google HEART / GSM — https://www.thefountaininstitute.com/blog/goals-signals-metrics
- Spec-Driven Development 2025 — https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering/
- SDD: From Code to Contract (arXiv 2602.00180) — https://arxiv.org/html/2602.00180v1
