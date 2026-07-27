# Engineering-Capability Standards Rubric — private-ai-harness

**Date:** 2026-07-25
**Companion to:** `2026-07-25-engineering-dept-benchmark.md` (Part 2, deepened)
**Method:** each capability is anchored to its authoritative standard(s)
landscape (multi-framework, web-researched), given a "what a 10 requires"
rubric drawn from those standards, scored, and handed concrete close-the-gap
(or push-past-10) actions. Shape mirrors `spec-quality-gate` /
`spec-quality-reviewer`, which anchors to SQLite test practice, RFC 8446, and
DO-178C.

**Scale:** 10 = meets or exceeds an elite human org measured against the named
standard; ≤3 = real gap. "11" notes appear on the current 10s.

---

## Summary — capability → anchor standard → score → gap

| # | Capability | Anchor standard(s) | Score | One-line gap to 10 |
|---|---|---|---|---|
| 1 | Business intake | Amazon PR-FAQ / Working Backwards; JTBD; ISO/IEC/IEEE 29148 stakeholder reqs | 8 | No PR-FAQ press-release artifact; no single north-star metric |
| 2 | Ideation & alternatives | SEI ATAM; RAT (riskiest-assumption test) | 9 | Trade-offs are prose, not a scored decision matrix vs QA scenarios |
| 3 | Spec quality | ISO/IEC/IEEE 29148; DO-178C; Requirements Smells | 10 | Split individual-vs-set quality; add smell lint (→11) |
| 4 | Architecture | ISO/IEC/IEEE 42010; arc42; C4; ADR; STRIDE; Well-Architected | 9 | No concern→viewpoint traceability; no QA scenarios; only 1 of 6 WA pillars deep |
| 5 | Contract-first | OpenAPI; Pact (CDC); JSON Schema; RFC 9457; Google AIP | 9 | Provider-side only; no consumer-driven contract test; error model not RFC 9457 |
| 6 | Decomposition | INVEST; vertical slicing; SPIDR; SAFe epic→story | 9 | No INVEST/vertical-slice check per story |
| 7 | Implementation | ISO/IEC 25010; ISO/IEC 5055 + CISQ (CWE) | 9 | Quality judged, not measured (no automated structural-weakness gate) |
| 8 | Code review | Google Modern Code Review; SmartBear; Microsoft | 10 | No PR-size gate (<400 LOC) or review-latency SLA — cheapest evidence-backed 11 |
| 9 | Testing | Test pyramid; TMMi L1-5; ISO/IEC 29119; mutation testing | 10 | Mutation testing is mental, not an automated gate; no coverage floor (→11) |
| 10 | CI/CD | Continuous Delivery; trunk-based; SLSA L0-3; 12-factor | 8 | No SLSA provenance/signing; supply-chain integrity absent |
| 11 | Deployment | Progressive delivery; expand-contract; SLO-triggered rollback | 8 | Rollback documented not automated; no canary auto-abort; no error-budget gate |
| 12 | Observability | OpenTelemetry semconv; golden signals + RED/USE; SLO/error budget | 9 | Error-budget policy not enforced; no OTel semconv lint; USE under-covered |
| 13 | Production Readiness Review | Google SRE PRR + Launch Checklist | 6 | No distinct PRR gate/artifact; readiness scattered |
| 14 | Incident response | Google SRE IM; blameless postmortem; ITIL 4 / ISO 20000 | 9 | No action-item-to-closure loop; no metrics feedback to SLOs; no drills |
| 15 | Docs & onboarding | Diátaxis (4 modes); docs-as-code; ISO/IEC 26514 | 9 | Docs not organized by Diátaxis's 4 needs; no true tutorial path |
| 16 | Platform / golden paths | CNCF Platform Eng Maturity Model; Backstage/IDP; Team Topologies | 5 | No self-service scaffolding, service catalog, or scorecards |
| 17 | Delivery measurement | DORA (+reliability); SPACE; DevEx (DX Core 4); Flow Framework | 3 | Measures token cost, not delivery performance (DORA/flow) |
| 18 | Portfolio / org | SAFe LPM (Portfolio Kanban, WSJF, WIP); OKRs; value-stream mgmt | 3 | No layer above one epic — no backlog, prioritization, WIP, roadmap |

---

## Detailed rubric — 18 capabilities

### 1 — Business intake · 8/10
**Landscape:** Amazon **PR-FAQ / Working Backwards** (write the future press
release + internal FAQ *before* specs — the org's shared "North Star");
**JTBD** (job statement, forces of progress); **north-star metric** + input
metrics; **ISO/IEC/IEEE 29148** stakeholder-requirements definition.
**A 10 requires:** (a) a customer-experience-first artifact written from the
launch date; (b) an internal FAQ surfacing business model, KPIs, *risks*, and
technical constraints; (c) exactly one designated north-star metric with 2–3
input metrics; (d) explicit non-goals; (e) stakeholder map.
**Harness today:** `business-context-intake` + `business-context-reviewer`
cover JTBD, measurable metrics, compliance, non-goals, stakeholders — strong.
**Why not 10:** no PR-FAQ *forcing function* (the future-press-release that
makes teams confront the customer experience before building); no single
north-star-metric designation; the FAQ risk-surfacing section is implicit.
**Close the gap:** add a PR-FAQ template to `business-context-intake` (1-page
press release + internal/external FAQ); require one north-star metric + input
metrics; add a "riskiest assumptions" FAQ block; have the reviewer check the
press release is solution-free and customer-outcome-framed.

### 2 — Ideation & alternatives · 9/10
**Landscape:** SEI **ATAM** (Architecture Tradeoff Analysis Method — utility
tree of quality-attribute scenarios, sensitivity points, tradeoff points, risk
themes); **RAT** (riskiest-assumption test); design-thinking divergence.
**A 10 requires:** 2–3 options each scored against *named quality-attribute
scenarios*, with sensitivity/tradeoff points made explicit and the riskiest
assumption tested before commit.
**Harness today:** `brainstorming` proposes 2–3 approaches with trade-offs,
leads with a recommendation, applies YAGNI — genuinely strong.
**Why not 10:** trade-off comparison is prose, not a **scored decision matrix**
(options × QA scenarios); no explicit riskiest-assumption test gate.
**Close the gap:** add a weighted decision matrix (options × quality-attribute
scenarios: latency, cost, security, operability) and a "riskiest assumption +
how we'd de-risk it" callout to the Exploring-approaches step; carry the ATAM
tradeoff points into the ADR as rationale.

### 3 — Spec quality · 10/10 (exceeds)
**Landscape:** **ISO/IEC/IEEE 29148** (individual-requirement quality:
necessary, unambiguous, singular, feasible, verifiable, traceable; *set*
quality: complete, consistent, non-redundant, bounded); **DO-178C** (accurate,
verifiable, traceable, no unintended function); **Requirements Smells**
(weak words, comparatives without reference, loopholes).
**Why it exceeds:** `spec-quality-reviewer` already enforces falsifiability and
TC honesty ("would a wrong impl pass this?") against SQLite/RFC 8446/DO-178C —
ahead of most orgs.
**Push to 11:** split checks explicitly into **individual-requirement** vs
**set-level** quality (29148's two-tier model); add an automated
**requirements-smell lint** (weak modal verbs, "fast/robust" without a number,
"etc./and/or" loopholes); assert **singularity** (one requirement per REQ-NNN).

### 4 — Architecture · 9/10
**Landscape:** **ISO/IEC/IEEE 42010** (architecture description: stakeholders →
concerns → viewpoints → views → decisions; correspondence rules); **arc42**
(12-section template incl. runtime view, deployment view, cross-cutting
concepts, risks/tech-debt); **C4**; **ADR** (Nygard); **STRIDE**; **AWS/Azure
Well-Architected** (6 pillars: operational excellence, security, reliability,
performance, cost, sustainability).
**A 10 requires:** every stakeholder concern traced to a viewpoint; QA
scenarios (ATAM utility tree) driving the design; all 6 WA pillars examined;
ADRs with alternatives + consequences; threat model.
**Harness today:** `high-level-design` + `hld-reviewer` (C4, STRIDE, failure
modes, capacity, ADRs, Well-Architected) + `database-erd` + `sequence-diagram`
+ `api-versioning` — strong and broad.
**Why not 10:** no explicit **concern→viewpoint traceability** (42010's core);
no **quality-attribute scenarios** linking NFRs to structure; STRIDE covers the
*security* pillar deeply but the other five WA pillars are lighter; no arc42
completeness check (runtime/deployment/cross-cutting as required sections).
**Close the gap:** map HLD sections onto arc42's 12 + add a 42010
concern→viewpoint table; require QA scenarios; make `hld-reviewer` assert all
six WA pillars, not just security.

### 5 — Contract-first · 9/10
**Landscape:** **OpenAPI 3.1** (provider-driven spec, JSON-Schema-based);
**Pact / consumer-driven contract testing** (consumer records real
expectations); **JSON Schema** validation; **RFC 9457** (problem+json error
model, supersedes 7807); org API **style guides** (Google AIP, Zalando,
Microsoft REST).
**A 10 requires:** provider spec *and* consumer-driven contracts verified in CI;
standardized machine-readable error model; conformance to a named style guide.
**Harness today:** `api-contract-first` + `api-contract-reviewer` (OpenAPI
3.1/proto, Spectral lint, Prism mock) — strong provider side.
**Why not 10:** **provider-side only** — no Pact/CDC verifying that real
consumers' expectations hold; error taxonomy not pinned to **RFC 9457**; style
governed by default Spectral rules, not a named org guide (AIP/Zalando).
**Close the gap:** add a CDC (Pact) step for service-to-service contracts;
enforce RFC 9457 problem+json; adopt and lint against a named style-guide
ruleset. **11:** bidirectional OpenAPI⇄Pact reconciliation.

### 6 — Decomposition & planning · 9/10
**Landscape:** **INVEST** (Independent, Negotiable, Valuable, Estimable, Small,
Testable); **vertical slicing** (each story crosses layers and delivers
observable user value — the near-universal recommendation); **SPIDR** /
Humanizing-Work splitting patterns; **SAFe** epic→capability→feature→story.
**A 10 requires:** every child story passes INVEST and is a *vertical* slice;
a walking-skeleton/thin-slice first; dependencies mapped.
**Harness today:** `writing-plans` + `plan-reviewer` (task right-sizing,
interfaces, global constraints) + `epic-decomposition` (parallel/sequential
waves) — strong.
**Why not 10:** no explicit **INVEST check** per story; no guarantee stories
are **vertical** (waves can still be layer-sliced); no walking-skeleton-first
rule.
**Close the gap:** add an INVEST lint + "is this a vertical slice with
observable value?" gate to `epic-decomposition` children; flag horizontal
(UI-only / DB-only) splits. (Single-epic scope limit → row 18.)

### 7 — Implementation · 9/10
**Landscape:** **ISO/IEC 25010** (8 product-quality characteristics);
**ISO/IEC 5055 + CISQ** (automated *source-code* measures for reliability,
security, performance, maintainability — defined as CWE structural-weakness
sets); Google readability; clean code.
**A 10 requires:** structural quality *measured*, not only reviewed — CWE
density, maintainability index, tracked over time.
**Harness today:** `test-driven-development` + `subagent-driven-development` +
`karpathy` + `design-principles` + `code-documentation` — strong process.
**Why not 10:** quality is **reviewer-judgment**, not **measured** — no
ISO-5055/CISQ-style automated structural-weakness gate (CWE scan +
maintainability metric).
**Close the gap:** add a CISQ/ISO-5055-aligned static measure (CWE scan +
maintainability index) to `verification-before-completion`, thresholded.
**11:** trend the maintainability index across commits.

### 8 — Code review · 10/10 (exceeds)
**Landscape:** **Google "Modern Code Review" study** (review is the single most
effective defect-finder; goal = long-term codebase health; first response
target < 1 business day); **SmartBear 2,500-review study** (effectiveness peaks
at **200–400 changed LOC** and ~60 min; detection drops from ~87% under 100 LOC
to ~28% over 1,000 LOC; catches 60–90% of defects before QA at ~1/10th prod
cost); Microsoft empirical (20–30% fewer escaped defects).
**Why it exceeds:** six specialized adversarial reviewer agents +
trust-but-verify + load-bearing-claim verification — beyond typical human orgs.
**The one true-11 lever (highest ROI in the whole doc, near-zero cost):** the
evidence says **PR size is the dominant variable** and the harness does not gate
it. Add to `requesting-code-review`: **warn > 400 changed LOC, block > 1,000**,
and a **first-response-within-1-business-day** norm. Pure evidence, trivial to
add.

### 9 — Testing · 10/10 (exceeds)
**Landscape:** **test pyramid** (Cohn); **TMMi** L1 initial → L5 optimized
(harness already ≈ L4 measured / L5 optimizing); **ISO/IEC/IEEE 29119**;
**mutation testing** (the falsifiability capstone — Stryker/PIT/mutmut);
coverage floors.
**Why it exceeds:** unit→integration→e2e→load→chaos→visual→dast→a11y, each with
a reviewer, wired as hard gates.
**Push to 11:** `writing-good-tests` treats mutation as a *mental* check — make
it an **automated gate** (mutation-score threshold via Stryker/PIT/mutmut) plus
a **coverage floor**; that closes TMMi L5's "defect prevention" loop with a
tool, not a reminder.

### 10 — CI/CD · 8/10
**Landscape:** **Continuous Delivery** (Humble/Farley deployment pipeline);
**trunk-based development**; **SLSA** build track L0→L3 (v1.1, 2025 — signed
provenance, hosted/isolated build); **12-factor**; SBOM.
**A 10 requires:** functional pipeline *plus* supply-chain integrity — build
provenance, artifact signing, SBOM, small-batch/trunk cadence.
**Harness today:** `ci-pipeline-setup` + `ci-reviewer` (multi-platform,
DORA-readiness, fail-fast, coverage gate) — strong on functional stages.
**Why not 10:** **no SLSA provenance/signing**, no SBOM, no dependency
provenance — supply-chain integrity (a first-class 2025 standard) is absent;
trunk-based/small-batch is not enforced.
**Close the gap:** add **SLSA L2+** (signed provenance, hosted build) + SBOM
generation + dependency-provenance scan to `ci-reviewer`; assert a lead-time
budget (DORA elite).

### 11 — Deployment & release · 8/10
**Landscape:** **progressive delivery** (canary → ring → blue-green, staged
percentages); **expand-contract** DB migration (already covered); **feature
flags**; **SLO-triggered automated rollback** (canary analysis auto-abort).
**A 10 requires:** automated canary analysis with auto-rollback on SLO breach;
staged percentage schedule; error-budget-gated releases.
**Harness today:** `deployment-workflow` + `deployment-reviewer`
(expand-contract, rollback procedure, smoke tests) + `feature-flags` +
`infrastructure-as-code` — strong.
**Why not 10:** rollback is a **documented procedure, not automated**; no
canary percentage schedule with **auto-abort on SLO breach**; no
error-budget release gate.
**Close the gap:** add a canary-analysis + automated-rollback-on-SLO-breach
spec to `deployment-workflow`; wire the error-budget gate (shared with row 12).

### 12 — Observability & reliability · 9/10
**Landscape:** **OpenTelemetry semantic conventions** (the vendor-neutral
interop standard — standardized attribute names); **golden signals** (latency,
traffic, errors, saturation) + **RED** (rate/errors/duration, request-driven) +
**USE** (utilization/saturation/errors, resource-driven); **SLO / error
budget**; multi-window multi-burn-rate alerting.
**A 10 requires:** OTel-semconv-conformant telemetry; golden signals + USE for
resources; SLOs with an *enforced* error-budget policy; burn-rate alerts.
**Harness today:** `observability-standards` + `observability-reviewer` (golden
signals, SLOs, burn-rate alerts, 7-section runbooks) — SRE-grade.
**Why not 10:** the **error-budget *policy*** (halt releases when the budget is
burned) is defined but **not enforced as a gate**; no **OTel semantic-convention
lint** (attribute-naming conformance); **USE** (resource saturation) is lighter
than RED.
**Close the gap:** add an error-budget-policy gate (shared with row 11); add an
OTel-semconv attribute-naming check; require USE coverage for resources.

### 13 — Production Readiness Review · 6/10
**Landscape:** **Google SRE Production Readiness Review + Launch Checklist** —
an explicit sign-off before a service takes production traffic: recent
incidents/postmortems reviewed, capacity/dependencies validated, on-call &
runbooks ready, monitoring/alerting complete, rollback *tested*, error budget
defined.
**A 10 requires:** a single, enumerated PRR checklist as a **hard gate** before
first production traffic.
**Harness today:** readiness is **implicit** — scattered across
`deployment-workflow`, `observability-standards`, and
`finishing-a-development-branch`.
**Why not 10:** there is **no distinct PRR artifact or gate**; nothing forces a
consolidated go-live sign-off.
**Close the gap (clean new skill):** add a `production-readiness-review` skill +
reviewer producing an SRE-launch-checklist artifact as a **hard gate** in the
epic lane before first production traffic — pulling SLO existence, tested
rollback, runbooks, on-call, capacity, and dependency checks into one sign-off.

### 14 — Incident response · 9/10
**Landscape:** **Google SRE incident management** (separated IC / Ops / Comms
roles, ICS-derived); **blameless postmortem** culture; severity matrix + SLAs;
**MTTD / MTTR / MTBF**; **ITIL 4 / ISO/IEC 20000** (adjacent process standard);
**DiRT** game-days.
**A 10 requires:** roles + severity + blameless template *plus* action-items
tracked to closure, incident metrics fed back into SLOs, and periodic drills.
**Harness today:** `incident-response` + `incident-response-reviewer` (SEV
matrix, IC role, 7-section blameless postmortem, MTTD/MTTR) — strong.
**Why not 10:** no **action-item-to-closure** tracking loop; postmortem outputs
don't feed back into **SLOs/error budget**; no **drill** (DiRT/game-day) to
validate the process (ties to `chaos-engineering`).
**Close the gap:** add action-item closure tracking; wire postmortem findings
back to `observability-standards` SLOs; reference a periodic incident drill.

### 15 — Docs & onboarding · 9/10
**Landscape:** **Diátaxis** — four distinct documentation needs: **tutorial**
(learning by doing), **how-to** (goal-oriented steps), **reference** (lookup),
**explanation** (understanding); **docs-as-code**; **ISO/IEC 26514** (adjacent).
**A 10 requires:** docs consciously organized into the four modes; a real
tutorial (skill acquisition) distinct from how-to and reference.
**Harness today:** `code-documentation` (docstrings, spec_id/req_id) +
`onboarding-guide` (8 sections) + wiki-sync rule — strong and *enforced*.
**Why not 10:** docs aren't organized by **Diátaxis's four needs** — reference
and explanation get conflated; there's no distinct **tutorial** (first
skill-acquisition walk-through) separate from how-to.
**Close the gap:** structure `wiki/` and `onboarding-guide` into the Diátaxis
four quadrants; ensure a genuine tutorial (guided first contribution) distinct
from reference. **11:** tag every doc with its audience-mode.

### 16 — Platform / golden paths · 5/10  ⚠ major gap
**Landscape:** **CNCF Platform Engineering Maturity Model** (5 levels;
**L3 = Self-Service & Standardization**: golden-path templates, service catalog,
self-service provisioning, scorecards); **Backstage / IDP**; **Team Topologies**
(platform-as-a-product, X-as-a-Service).
**A 10 requires:** self-service scaffolding that emits a paved starting artifact
(new service with CI + observability + contract + tests wired from birth), a
service catalog, and scorecards measuring per-service maturity.
**Harness today:** it paves the **process** (the `/engineer` router *is* a
golden path for the SDLC) — but there is **no artifact scaffolding**: no
service/repo template, no catalog, no scorecards. Against CNCF it's ≈ **L1–L2**
for scaffolding despite ≈ L4 for process.
**Close the gap:** add a **service-scaffolding** skill (opinionated repo/service
template with CI, obs, API contract, test harness, runbook stubs wired from
birth); a **service catalog / registry** (manifest of services + owners + SLOs);
and **scorecards** (per-service maturity checks). Biggest genuine gap alongside
17/18.

### 17 — Delivery measurement · 3/10  ⚠ major gap
**Landscape:** **DORA** (deployment frequency, lead time for change, change
failure rate, failed-deployment recovery time, + reliability; elite thresholds);
**SPACE** (satisfaction, performance, activity, communication, efficiency);
**DevEx / DX Core 4** (feedback loops, cognitive load, flow state); **Flow
Framework** (flow velocity/efficiency/time/load/distribution).
**A 10 requires:** the four DORA keys computed from delivered work, plus flow
efficiency (active vs wait time), tracked as a trend.
**Harness today:** the `cost-ledger` measures **token cost only** — not delivery
performance.
**Why not 10:** it ships work but never **scores its own delivery** — no
deployment frequency, lead time, change-fail rate, or MTTR captured.
**Close the gap (high ROI — data already exists):** the work-item **manifest
already timestamps every phase transition**, and the cost-ledger already spans
repos. Add a **delivery-metrics ledger** that derives the four DORA keys +
**flow efficiency** (sum of active phase time vs wait time across manifest
phases) per delivered work-item — cheap because the timestamps are already
being written. Add SPACE/DevEx only if a human-in-the-loop signal exists.

### 18 — Portfolio / org orchestration · 3/10  ⚠ major gap
**Landscape:** **SAFe Lean Portfolio Management** (Portfolio Kanban: Funnel →
Reviewing → Analyzing → Backlog → Implementing → Done; **WIP limits** ~1–2 epics
per value stream; **WSJF** cost-of-delay prioritization; Lean budgeting);
**OKRs** as strategic-theme outcomes; **value-stream management**; **Flow
Framework**.
**A 10 requires:** a layer *above* the epic — a prioritized portfolio backlog,
WSJF/cost-of-delay ranking, WIP limits, cross-epic dependency graph, OKR
linkage, and a roadmap.
**Harness today:** `epic-decomposition` (waves within one epic) + recursion
(`/engineer` per story) — depth, not breadth.
**Why not 10:** **no layer above one epic** — no portfolio backlog, no WSJF
prioritization across epics, no WIP limits, no cross-epic dependency tracking,
no OKR linkage, no roadmap. This is the single biggest blocker to true
"department" work.
**Close the gap:** add a **portfolio** lane/skill above `epic`: a portfolio
manifest holding N epics in Portfolio-Kanban states, **WSJF** scoring, **WIP
limits**, a cross-epic dependency graph, and OKR linkage; `/engineer` gains a
"portfolio" classification above the epic lane.

---

## Cross-cutting: highest-ROI actions, ranked

Ranked by (impact on reaching a real "department") × (inverse cost):

1. **PR-size gate (row 8)** — near-zero cost, strongest evidence base in the
   whole doc (SmartBear/Google). Warn > 400 / block > 1,000 changed LOC.
2. **DORA + flow ledger (row 17)** — data already exists in the manifest
   timestamps; derive the four keys + flow efficiency. Cheap, unlocks
   "measure what you shipped."
3. **Production Readiness Review skill (row 13)** — clean new gate; consolidates
   scattered readiness into one SRE-checklist sign-off.
4. **Portfolio lane (row 18)** — biggest capability gap; larger build. SAFe
   Portfolio Kanban + WSJF + WIP above the epic lane.
5. **Service scaffolding + catalog + scorecards (row 16)** — CNCF L3 golden
   paths; larger build, pairs with 18 for true department scale.
6. **Error-budget policy gate (rows 11+12)** — one gate serves both; enforces
   the SLO the harness already authors.
7. **Supply-chain integrity: SLSA L2+ + SBOM (row 10)** — 2025 table-stakes.
8. **Mutation-testing gate (row 9)** and **CISQ/ISO-5055 measure (row 7)** —
   turn "measured, not just reviewed" from reminder into tool.
9. **PR-FAQ intake (row 1)**, **CDC/Pact + RFC 9457 (row 5)**, **Diátaxis docs
   (row 15)**, **ATAM decision matrix (row 2)**, **INVEST/vertical-slice (row
   6)**, **arc42/42010 + QA scenarios (row 4)** — targeted per-skill upgrades.

---

## Sources

- Amazon Working Backwards PR/FAQ; JTBD north-star metric guidance
- ISO/IEC/IEEE 29148 & IEEE 830 (requirements); DO-178C; "Requirements Smells" (arXiv 1611.08847)
- ISO/IEC/IEEE 42010 (architecture description); arc42; C4 model; TOGAF; ADR (Nygard)
- OpenAPI / JSON Schema / Pact consumer-driven contract testing; RFC 9457
- INVEST; vertical slicing; SPIDR / Humanizing-Work story splitting
- ISO/IEC 25010 (SQuaRE); ISO/IEC 5055 + CISQ automated source-code measures (CWE)
- Google "Modern Code Review: A Case Study at Google"; SmartBear 2,500-review study; Microsoft empirical review data
- Test pyramid (Cohn); TMMi framework; ISO/IEC/IEEE 29119; mutation testing
- Continuous Delivery (Humble/Farley); trunk-based development; SLSA v1.1; 12-factor
- Progressive delivery (canary/blue-green/ring); expand-contract migration
- OpenTelemetry semantic conventions; golden signals / RED / USE; Google SRE SLO & error-budget policy
- Google SRE Production Readiness Review + Launch Checklist
- Google SRE incident management & blameless postmortem culture; ITIL 4 / ISO/IEC 20000
- Diátaxis documentation framework (diataxis.fr)
- CNCF Platform Engineering Maturity Model; Backstage / IDP; Team Topologies
- DORA (getDX); SPACE framework; DX Core 4 / DevEx; Flow Framework
- SAFe Lean Portfolio Management (Portfolio Kanban, WSJF, WIP limits); OKRs
