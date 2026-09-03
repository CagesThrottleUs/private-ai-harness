---
name: production-readiness-review
description: >
  Use before a service takes its first production traffic — a single go/no-go
  Production Readiness Review (PRR) gate that consolidates the scattered
  readiness signals (SLOs, tested rollback, runbooks, capacity, dependencies,
  on-call) into one enumerated checklist artifact requiring human sign-off.
  Anchored to Google SRE's Launch Coordination Checklist. Hard gate in the epic
  lane before go-live; runs production-readiness-reviewer.
---

# Production Readiness Review (PRR)

Before this harness, launch readiness was implicit — spread across
`deployment-workflow`, `observability-standards`, and
`finishing-a-development-branch`, with nothing forcing a consolidated go-live
decision. A service can pass every individual gate and still be unready. The
PRR is the single sign-off that says "this may take production traffic."

**Standards anchored:** Google SRE **Launch Coordination Checklist** + Production
Readiness Review (dedicated Launch Coordination Engineers, dependency-driven
capacity planning); the open-source **Production Readiness Checklist** seven
dimensions — Service Levels, Architecture Design Review, Performance,
Documentation, Observability, Testing, Deployment Strategy.

**This is a human gate.** The reviewer agent validates completeness and
evidence, but a human makes the go/no-go call. Never auto-advance a PRR.

## When it runs

- **Epic lane:** hard gate after `deployment-workflow` + `observability-standards`
  and before first production traffic. A FAIL blocks launch.
- Any time a **new externally-reachable service** or a **materially new
  production surface** is about to go live.
- Skip for internal-only libraries, docs, or changes that add no new production
  surface.

## The PRR checklist artifact

Produce `.ai/YYYY-MM-DD-<service>/prr/prr-<service>.md` with all seven dimensions. Each
line is **PASS / FAIL / N-A with evidence** — a link to the artifact or command
output, never a bare "yes."

### 1. Service Levels
- [ ] SLI(s) defined and measured (from `observability-standards`)
- [ ] SLO set with a real target and window; error-budget policy exists
- [ ] SLO target is grounded in a real capacity/latency number, not a guess

### 2. Architecture & Dependencies
- [ ] Every upstream/downstream dependency enumerated (drives capacity planning)
- [ ] Each dependency exists, is owned, and has a known failure behavior
- [ ] Graceful degradation defined for each critical dependency failure
- [ ] Shared-infrastructure usage reviewed with its owners

### 3. Performance & Capacity
- [ ] Expected load estimated; headroom and autoscaling limits set
- [ ] Load/soak test run against staging with results vs the NFR targets
      (from `load-testing`)
- [ ] Known bottleneck / saturation point documented

### 4. Observability
- [ ] Golden signals (latency, traffic, errors, saturation) instrumented
- [ ] Alerts wired, symptom-based, with burn-rate policy
- [ ] Dashboards exist for the golden signals

### 5. Deployment & Rollback
- [ ] Progressive rollout strategy chosen (canary/blue-green/ring)
- [ ] **Rollback tested**, not just documented — link the test evidence
- [ ] Expand-contract used for any schema change (from `deployment-workflow`)
- [ ] Feature-flag kill switch for high-risk paths

### 6. Operability
- [ ] On-call defined; who is paged, and how
- [ ] Runbooks exist for each alert and have been **exercised**, not just written
- [ ] Recent incidents/postmortems for this or dependent services reviewed

### 7. Testing & Security
- [ ] Integration + e2e coverage of the critical journeys
- [ ] Security review done for auth/authz/PII/secrets surfaces
- [ ] DAST/relevant scans pass for externally-facing endpoints

### Go / No-Go
- [ ] All Critical items PASS
- [ ] Open risks explicitly accepted and named
- [ ] **Human sign-off:** name + date

## AI-age discipline (this service was likely AI-built)

The 2024 DORA report ties AI-assisted delivery to *lower stability*, and
AI-authored readiness artifacts read plausibly while being untested. So the PRR
does not accept a claim because it is written — it accepts it because it is
**evidenced**:

- A "rollback works" line needs a link to the rollback actually being run, not a
  procedure the model drafted.
- SLO targets and capacity numbers must trace to a real measurement, not an
  AI-guessed round number.
- Every dependency in dimension 2 must be verified to exist (AI can invent a
  plausible infra dependency or client that was never provisioned).
- Runbooks must have been exercised — an unexercised AI-written runbook is a
  hypothesis, not an operational control.

## Review

Dispatch `production-readiness-reviewer` on the artifact before presenting the
go/no-go to your human partner. It checks all seven dimensions are present,
every claim carries real evidence (not a plausible restatement), and flags
AI-plausible-but-unverified readiness. Pass artifact by file path; do not
pre-judge findings; dispatch one fix agent for all findings; re-review until
PASS. A ⚠️ item is yours to resolve.

## Integration

- **engineer (epic lane):** PRR is the go-live gate before first production
  traffic; a FAIL blocks launch.
- **observability-standards / deployment-workflow / load-testing:** supply the
  SLO, rollback, and capacity evidence the PRR consolidates.
- **incident-response:** the "recent incidents reviewed" and on-call items.
- **onboarding-guide:** a passed PRR is a prerequisite input for the go-live
  onboarding entry.
