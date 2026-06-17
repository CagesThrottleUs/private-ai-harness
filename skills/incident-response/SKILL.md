---
name: incident-response
description: >
  Use when setting up or updating incident response for any production service. Produces: severity matrix (SEV-1/2/3 with response SLAs), incident declaration process (IC role, war room, Slack commands), response playbook referencing existing runbooks, blameless postmortem template (Google SRE standard: summary/timeline/RCA/impact/corrective actions), and MTTD/MTTR tracking guidance. Runs incident-response-reviewer before committing. Runbooks set up the system; incident response is what you do when the system breaks anyway.
---

# Incident Response

Runbooks tell you how to fix known problems. Incident response tells you how to behave when something breaks that you didn't anticipate. Every engineering team that operates production systems needs documented incident response — not because incidents are frequent, but because when they do happen, being under pressure with no documented process makes everything worse.

## References

- **Google SRE Book: Incident Management** (sre.google/workbook/incident-response/) — IC role, severity levels, postmortem process
- **PagerDuty Incident Response** (response.pagerduty.com) — postmortem template, severity matrix, communication templates
- **Google SRE Postmortem Example** (sre.google/sre-book/example-postmortem/) — blameless postmortem format
- **Rootly 2025 SRE Checklist** (rootly.com/sre/2025-sre-incident-management-best-practices-checklist)

---

## When to Use

**Required** for any service that:
- Is running in production
- Has users or downstream consumers
- Has observability set up (`observability-standards` has been run)

**Skip** for: local development tools, scripts with no users, staging-only services.

**Infer + confirm:**
> "This service has SLOs and runbooks but no documented incident response process. Generating now. Confirm?"

---

## Outputs

### 1. Severity Matrix

Save to: `wiki/guides/incident-response.md` (primary document)

```markdown
# Incident Response Process — [Service Name]

**Version:** YYYY-MM-DD
**SLO reference:** `.ai/observability/YYYY-MM-DD-slos.md`
**Runbooks:** `wiki/guides/runbooks/`

---

## Severity Levels

| Severity | Definition | User impact | Response SLA | Who joins |
|----------|-----------|------------|-------------|-----------|
| **SEV-1 (Critical)** | Service completely down or data loss occurring | All users affected | Page immediately, respond < 15 min | IC + full team |
| **SEV-2 (Major)** | Core feature broken, significant degradation | Many users affected | Page primary on-call, respond < 30 min | IC + on-call |
| **SEV-3 (Minor)** | Non-critical feature broken, minor degradation | Few users affected | Slack alert, address in < 4 hours | On-call engineer |

**Escalation:** If a SEV-3 doesn't resolve within 1 hour, escalate to SEV-2.
If a SEV-2 doesn't resolve within 2 hours, escalate to SEV-1.

---

## Declaring an Incident

**When to declare:** Any time you're uncertain whether something is an incident, declare it.
Declaring and closing is better than not declaring and being wrong.

**How to declare (Slack):**
```
/incident --title "[brief description]" --sev [1|2|3]
```

Or manually: post in `#incidents` with:
```
🚨 INCIDENT DECLARED — SEV-[N]
Title: [what is broken]
Impact: [who is affected, how many users]
Declared by: @[your-handle]
IC: @[incident-commander]
War room: [Slack channel or video link]
Time: [HH:MM UTC]
```

**Incident Commander (IC):** The IC owns the response — not the fix. The IC:
- Coordinates the team, not the technical debugging
- Provides status updates every 15 minutes (SEV-1) or 30 minutes (SEV-2)
- Decides when to escalate
- Declares the incident resolved
- Assigns postmortem owner

First person to the incident is the IC until someone more senior takes over.

---

## Response Playbook

**First 5 minutes:**
1. Declare the incident (see above) — do not wait until you understand it
2. Open the relevant runbook: `wiki/guides/runbooks/alert-[name].md`
3. Check: was there a recent deploy? → See `wiki/changelog/` and consider rollback
4. Check: is the monitoring dashboard showing the right signals?

**If runbook doesn't resolve it:**
1. Escalate to SEV-1 if not already
2. Add more engineers to the war room
3. Document everything in the incident channel as you go (timestamps matter for postmortem)
4. Consider a service degradation page / user communication

**Resolution criteria:**
- Error rate at or below pre-incident baseline for 10+ minutes
- p99 latency at or below SLO threshold for 10+ minutes
- No new related alerts firing

**After resolution:**
1. Declare resolved in `#incidents`
2. Capture: start time, resolution time, user impact scope
3. Schedule postmortem within 5 business days (any SEV-1 or significant SEV-2)
4. Send customer communication if users were affected

---

## MTTD / MTTR Tracking

| Metric | Definition | Target | How to measure |
|--------|-----------|--------|---------------|
| MTTD (Mean Time to Detect) | Alert fired → incident declared | < 5 min (SEV-1), < 15 min (SEV-2) | PagerDuty alert time → Slack incident declaration timestamp |
| MTTR (Mean Time to Resolve) | Incident declared → resolved | < 1 hour (SEV-1), < 4 hours (SEV-2) | Incident declaration → resolution declaration |

Record each incident in `wiki/guides/incident-log.md` (one row per incident):

```markdown
| Date | Title | SEV | MTTD | MTTR | Root cause category | Postmortem |
|------|-------|-----|------|------|---------------------|-----------|
| YYYY-MM-DD | [title] | [1/2/3] | [N min] | [N min] | [Deploy/Config/External/Code bug] | [link] |
```
```

---

### 2. Blameless Postmortem Template

Save to: `wiki/guides/postmortem-template.md`

```markdown
# Postmortem: [Incident Title]

**Date:** YYYY-MM-DD
**Severity:** SEV-[N]
**Duration:** [N hours N minutes]
**Author:** [name]
**Reviewed by:** [names]
**Status:** Draft | In Review | Complete

---

## Summary

[2-3 sentences: what broke, what the user impact was, and how it was resolved.
Written for someone who has no context about the incident.]

---

## Timeline

All times in UTC.

| Time | Event |
|------|-------|
| HH:MM | [Earliest signal — alert fired, user report, or engineer noticed] |
| HH:MM | [Incident declared — by whom, severity] |
| HH:MM | [First diagnosis — what was found] |
| HH:MM | [First mitigation attempt — what was tried] |
| HH:MM | [Root cause identified] |
| HH:MM | [Fix deployed or rollback executed] |
| HH:MM | [Incident resolved — criteria met] |

---

## Root Cause Analysis

**What broke:** [Specific component, query, code path, or external service]

**Why it broke:** [The technical reason — not "because we deployed" but what the deployment changed that caused the failure]

**Why it wasn't caught earlier:**
- In tests: [What test would have caught this? Did it not exist, or did it not cover this path?]
- In monitoring: [Was there an alert for this? If not, why not?]
- In deployment: [Did the deployment pipeline have a check that should have caught this?]

---

## Impact

| Metric | Value |
|--------|-------|
| Users affected | [N users / all users / [%] of requests] |
| Duration | [N hours N minutes] |
| Error rate peak | [N%] |
| p99 latency peak | [Nms] |
| SLO error budget consumed | [N% of monthly budget] |
| Revenue impact (if applicable) | [N transactions failed / $N affected] |

---

## What Went Well

- [Something that worked: the alert fired within 2 minutes, the rollback took < 5 minutes, the runbook was accurate]
- [...]

## What Went Wrong

- [Something that failed: the runbook was outdated, the alert threshold was wrong, communication was delayed]
- [...]

---

## Corrective Actions

| Action | Owner | Due date | Priority |
|--------|-------|---------|---------|
| [Add test for X edge case] | @[name] | YYYY-MM-DD | P1 |
| [Update runbook with new diagnosis step] | @[name] | YYYY-MM-DD | P1 |
| [Add alert for Y metric] | @[name] | YYYY-MM-DD | P2 |
| [Improve deploy verification step] | @[name] | YYYY-MM-DD | P2 |

**P1:** Must be done before next production deploy.
**P2:** Must be done within 2 weeks.

---

## Blameless Statement

This postmortem focuses on systemic issues, not individual mistakes.
Everyone involved in this incident acted in good faith with the information available to them at the time.
The goal is to improve our systems, monitoring, and procedures — not to assign blame.

---
*Postmortem scheduled within 5 business days of incident resolution.*
*Template based on Google SRE (sre.google/sre-book/example-postmortem/) and PagerDuty (response.pagerduty.com/after/post_mortem_template/).*
```

---

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review

## Self-Review: Run `incident-response-reviewer` Agent

After generating all artifacts:

```
Agent(incident-response-reviewer, {
  PROCESS_PATH: "wiki/guides/incident-response.md",
  POSTMORTEM_PATH: "wiki/guides/postmortem-template.md",
  SLO_PATH: ".ai/observability/YYYY-MM-DD-slos.md"  // optional — for SLA alignment
})
```

Fix all **Critical** findings before committing.
