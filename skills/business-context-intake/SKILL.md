---
name: business-context-intake
description: >
  Use before brainstorming — for any feature, enhancement, or new capability requiring engineering work. Conducts a structured interview to capture business context: user problem, JTBD statement, measurable success metrics, compliance constraints, out-of-scope exclusions, and stakeholder map. Produces .ai/business-context/YYYY-MM-DD-<feature>.md. Runs business-context-reviewer agent before committing. Brainstorming MUST NOT activate without a completed business-context document.
---

# Business Context Intake

**LLMs do not know your business.** This is the first principle of any engineering framework. The business context — who the user is, what problem they have, what success looks like — must be provided by a human and captured in a committed document before any design begins.

Engineering without a defined success metric is engineering toward an unknown destination. A team that cannot answer "what does done look like for users?" in measurable terms is building on assumptions.

## References

- **Amazon Working Backwards PR/FAQ** (workingbackwards.com) — write the press release before the product, so the product serves the press release, not the other way around
- **JTBD Framework** (Clayton Christensen, 2005) — "When [situation], I want to [motivation], so I can [outcome]" — captures the context of use, not just the feature request
- **PRD best practices** (Reforge, Product School) — success metrics, user personas, non-goals as important as goals
- **Google Design Doc** — "Goals and Non-Goals" section: non-goals prevent scope creep and misaligned review feedback

---

## The Iron Law

<HARD-GATE>
`brainstorming` MUST NOT activate without a completed business-context document at `.ai/business-context/YYYY-MM-DD-<feature>.md`. Check for the file first. If absent, complete this skill before invoking brainstorming.
</HARD-GATE>

---

## When to Use

**Required** for:
- Any new feature or capability
- Any significant enhancement changing user-visible behavior
- Any compliance or regulatory requirement
- Any performance or reliability initiative with user impact

**Skip** (go directly to brainstorming) for:
- Bug fixes where the problem is a defect (the "correct behavior" is obvious)
- Dependency upgrades with no behavior change
- Internal refactoring with no user-facing impact
- Config or environment variable changes

**Infer + confirm:**
> "This is a bug fix — the expected behavior is clear from the bug description. Skipping business-context-intake and going straight to brainstorming. OK?"

---

## Process: Structured Interview

Ask questions one at a time. Each question builds on the last. Do not proceed to the next question until the current one is answered fully.

**Announce at start:** "I'm using the business-context-intake skill to capture context before we design. I'll ask you a few questions — one at a time. This takes 5-10 minutes and prevents building toward the wrong goal."

**Use `AskUserQuestion`** for questions with discrete options (compliance yes/no, feature type, priority). Use prose for open-ended questions (problem description, user persona). Never combine multiple questions in one tool call during intake — ask one at a time so the human can think clearly.

### Question sequence:

**Q1 — The problem:**
> "What user problem are we solving? Describe it from the user's perspective, not the solution."
>
> (Probe if the answer is solution-framed: "That's what we're building. What problem does it solve for the user? What are they struggling with today?")

**Q2 — The user:**
> "Who is the primary user? Describe their role, what they're trying to accomplish, and what their current workflow looks like without this feature."

**Q3 — Why now:**
> "What changed that makes this the right time to build this? User research? A market event? A compliance deadline? Competitive pressure? Growth data?"
>
> (This prevents features that are nice-to-have but not urgent from blocking important work.)

**Q4 — Success metric:**
> "How will we know this worked? Give me a measurable metric — something you could track in a dashboard. Not 'users will be happier' but 'support tickets for X drop by 30%' or 'checkout completion rate increases to 85%'."
>
> (Probe if vague: "That's directionally right. Can you attach a number and a timeline to it?")

**Q5 — Out of scope:**
> "What are we explicitly NOT doing in this version? List at least 3 things that could be assumed to be in scope but aren't."

**Q6 — Compliance:**
> "Does this feature handle personal data (PII), payment data (PCI), health data (HIPAA), or fall under any regulatory requirement? Explicit yes or no — don't skip this."

**Q7 — Stakeholders:**
> "Who needs to approve this before engineering starts? Who is affected but doesn't need to approve?"

**Q8 — Performance constraints (optional):**
> "Are there any known performance or availability requirements? Response time targets? Uptime requirements? Or is performance not a constraint for this feature?"

---

## Document Template

Save to: `.ai/business-context/YYYY-MM-DD-<feature>.md`

````markdown
# Business Context — [Feature Name]

**Date:** YYYY-MM-DD
**Status:** Draft | Approved
**Feature type:** New capability | Enhancement | Compliance | Reliability

---

## 1. Problem Statement

[Written from the user's perspective. Not "we want to build X" but "users struggle with Y because Z."]

**JTBD Statement:**
> "When [situation/trigger], I want to [motivation/what they're trying to do], so I can [expected outcome/benefit they care about]."
>
> *(JTBD format from Clayton Christensen: captures when, why, and what success looks like from the user's perspective — not just what they click)*

---

## 2. Primary User Persona

**Who:** [role or user type — e.g. "small business owner managing weekly invoices"]
**Current workflow:** [what they do today, without this feature]
**Pain point:** [what makes today's approach painful, slow, or error-prone]
**Frequency:** [how often they encounter this problem]

---

## 3. Why Now?

[What changed? User research? Competitive analysis? Compliance deadline? Growth data showing the problem at scale? A retention driver?]

*"Nice to have" is not a sufficient answer. If we can't articulate why this matters now, we should reconsider priority.*

---

## 4. Success Metrics

*Success must be measurable before the feature ships, not after. If we can't define the metric now, we can't know if we succeeded.*

**North-star metric (exactly one):** the single measure that best captures the
customer value this delivers. One north star prevents the "improved five
dashboards, moved the business on none" failure. State it, its baseline, and its
target.

**Input metrics (2–4):** the leading indicators the team can move directly that
are expected to drive the north star. These are what you steer on week to week.

| Role | Metric | Baseline | Target | Measurement method | Timeline |
|------|--------|---------|--------|-------------------|---------|
| **North star** | [the one measure of value] | [current] | [goal] | [how tracked] | [by when] |
| Input | [leading indicator] | [current] | [target] | [method] | [when] |
| Input | [leading indicator] | [current] | [target] | [method] | [when] |

**Definition of done (for users):** [One sentence: what will users be able to do that they cannot do today?]

---

## 5. Non-Goals (Out of Scope)

*Non-goals are as important as goals. State what could be assumed but isn't included. This prevents scope creep and misaligned review feedback.*

- [ ] [Item A]: [Why excluded — defer to later, different team, not validated yet]
- [ ] [Item B]: [Why excluded]
- [ ] [Item C]: [Why excluded]

*Minimum 3 explicit exclusions. "We'll add X later" without stating it as out of scope invites scope creep.*

---

## 6. Constraints

**Compliance:**
| Regulation | Applies? | Implication |
|-----------|---------|------------|
| GDPR | Yes / No / Unknown | [if yes: what data is affected, what rights must be supported] |
| PCI DSS | Yes / No / Unknown | [if yes: payment data scope] |
| HIPAA | Yes / No / Unknown | [if yes: health data handling] |
| SOC 2 | Yes / No / Unknown | [if yes: audit trail requirements] |
| Other | [name] | [implication] |

**Performance targets (if known):**
- Response time: [< Xms at p99 / not specified]
- Availability: [99.9% / 99.99% / not specified]
- Throughput: [N requests/second / not specified]

*These feed directly into Phase 1 NFRs and HLD capacity planning.*

**Timeline:** [hard deadline? Or flexible?]
**Budget/resource constraints:** [any?]

---

## 7. Stakeholder Map

| Role | Name/Team | Impact | Approval required | When to involve |
|------|-----------|--------|------------------|----------------|
| Engineering lead | [name] | Direct | Yes | Now |
| Product/PM | [name] | Direct | Yes | Now |
| Legal/Compliance | [team] | If compliance change | Yes if GDPR/PCI | Before spec |
| Data/Analytics | [team] | Indirect | No | Before launch |
| [Other] | [name/team] | [level] | [yes/no] | [when] |

---

## 8. Amazon PR/FAQ (REQUIRED for epic-lane new capabilities; skip only for small enhancements)

*Written as if the feature has already launched — the Amazon Working Backwards
forcing function. This is not optional decoration for a new service or product
line: writing the future press release before any spec surfaces customer-value
gaps, business-model questions, and risks while they are still cheap to fix. The
press release must be **solution-free and customer-outcome-framed** — if it reads
like a feature list, the working-backwards discipline has not happened yet. The
Internal FAQ must include the **riskiest assumptions** and how they'd be tested.*

### Internal Press Release

**Headline:** [Company/Team] announces [feature name] to enable [user type] to [benefit]

**Summary (2-4 sentences):**
[Written from the customer's perspective. Launch date, what it does, primary benefit. No technical implementation details.]

**Problem (3-4 sentences):**
[The top 2-3 problems users have today. Written as user pain, not as engineering opportunity.]

**Solution (3-4 sentences):**
[How the product solves each problem. What the user experiences. Still no implementation details.]

**Customer quote:**
> "[Hypothetical quote from a user who would benefit. Should be specific to a persona and pain point, not generic praise.]" — [hypothetical persona name, role]

### Customer FAQ

**Q: [Most likely question a user would ask]**
A: [Answer]

**Q: [Second most likely question]**
A: [Answer]

### Internal FAQ

**Q: [Question leadership/finance would ask — e.g. "What's the revenue impact?"]**
A: [Answer]

**Q: [Question legal/compliance would ask]**
A: [Answer]

**Q: [Question engineering would ask — e.g. "Why now and not in the next quarter?"]**
A: [Answer]

---

## 9. Session Persistence

*Business context is lost when a conversation compresses. This document is the re-hydration source.*

On every new session for this feature:
1. Read this document first
2. Check `.ai/specs/` for any spec already written
3. Brief any new agent: "We are building [feature name]. Business context: `.ai/business-context/YYYY-MM-DD-[feature].md`"
````

---

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review
- Pattern check before re-dispatch: does this finding's pattern recur elsewhere in the artifact? Fix every occurrence in the same pass — a finding that resurfaces next cycle in a new spot is the cost this discipline exists to cut

## Self-Review: Run `business-context-reviewer` Agent

After completing the document, before committing:

```
Agent(business-context-reviewer, {
  CONTEXT_PATH: ".ai/business-context/YYYY-MM-DD-<feature>.md"
})
```

Fix all **Critical** findings (missing success metric, missing JTBD, missing compliance answer). Fix **Important** findings (vague problem statement, fewer than 3 non-goals). Advisory may be deferred.

---

## Commit

```
docs(context): add business context for [feature name]

[body: WHY — what business problem this feature addresses, what would be built wrong without this document]
```

---

## Transition to Brainstorming

After human approves the document:

> "Business context committed to `.ai/business-context/YYYY-MM-DD-<feature>.md`.
>
> I now have: [problem], [user persona], [success metric], [compliance status], [key non-goals].
>
> Ready to begin design. Invoking brainstorming."

Invoke `brainstorming` skill — it reads this document as input.
