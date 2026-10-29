---
name: high-level-design
description: >
  Use after spec-quality-gate passes and before writing-plans — for any feature requiring architectural decisions (new services, data models, external integrations, security boundaries, traffic-bearing endpoints). Produces a committed HLD document with C4 diagrams, technology selection records, threat model, failure mode analysis, and capacity planning — plus ADRs per significant decision. Runs hld-reviewer agent before presenting to human. Human approval required before writing-plans activates.
---

# High Level Design

Translate a validated spec into a committed architectural blueprint. Architecture decisions made here become permanent record — not conversation, not memory. The HLD is the contract between design and implementation.

## References

- **C4 Model** (Simon Brown, c4model.com) — Context + Container diagrams as the minimum visual contract
- **Google Design Doc** (industrialempathy.com/posts/design-docs-at-google) — Context, Goals/Non-Goals, Actual Design, Alternatives, Cross-Cutting Concerns
- **AWS Threat Modeling** (Shostack 4-Question Frame + STRIDE) — design-time security analysis
- **Michael Nygard / MADR ADR format** — immutable decision records
- **AWS Well-Architected Framework** — 6 pillars for cross-cutting review
- **Google SRE SLO document** — capacity and SLO structure

---

## When to Use

**Required** for new architectural elements: new service/process, new data model, new external integration, security boundary changes, traffic-bearing endpoints with capacity requirements.

**Skip** for: bug fixes, config changes, isolated utilities, adding a method/parameter/parsing capability to an existing component, new endpoint following an established service pattern.

**Infer + confirm before proceeding.** Don't silently skip — state the inference and ask once:
> "This adds array parsing to an existing parser — no new service, no data model change, no external dependency. I'm going to skip HLD. Correct, or am I missing something?"

Use `AskUserQuestion` when the scope is ambiguous (feature could be small or large depending on implementation approach).

---

## Inputs Required

- **Spec:** `.ai/YYYY-MM-DD-<feature-slug>/specs/specs-<feature-slug>.md` — must have passed `spec-quality-gate`
- **Business context:** `.ai/YYYY-MM-DD-<feature-slug>/business-context/business-context-<feature-slug>.md` — read if exists

Read both. Extract: NFRs (latency/throughput/availability), security requirements, compliance constraints, component dependencies from REQ-NNN statements.

<HARD-GATE>
Do NOT activate without a spec that has passed spec-quality-gate. If no spec exists, stop and invoke brainstorming first.
</HARD-GATE>

---

## Process

1. **Read spec and business context** — extract NFRs, security requirements, compliance, dependencies
2. **Ask clarifying architecture questions** — one at a time, multiple choice preferred
3. **Present component decomposition** — boxes and arrows; for each proposed component name what it hides (the design decision or volatile requirement other components must not know about); get approval before diagramming
4. **Generate C4 diagrams** — Context (Level 1) then Container (Level 2) in Mermaid
5. **Document technology selections** — one entry per major component with rationale
6. **Threat model** — Shostack 4 questions + STRIDE per component
7. **Failure mode analysis** — per component: what fails, user impact, mitigation, recovery target
8. **Capacity planning** — 3 scenarios from NFRs: pessimistic / expected / optimistic
9. **Identify ADR candidates** — every significant "why X over Y" decision
10. **Write ADR files** — one per decision, committed to `wiki/architecture/`
11. **Write HLD document** — all sections assembled, committed to `.ai/YYYY-MM-DD-<feature-slug>/hld/`
12. **Run `hld-reviewer` agent** — fix all Critical and Important findings before presenting
13. **Human review gate** — present for approval. Do NOT invoke `writing-plans` until approved.
14. **Resolve open questions** — all must be decided or explicitly deferred before `writing-plans`

---

## Architecture Questions (One at a Time)

Ask only what meaningfully changes the design. Stop when you can draw the boxes:

- "What environment does this run in? (single process / microservices / serverless / embedded)"
- "Which data stores exist or are being added?" (for each: relational, document, cache, object store, queue)
- "What external systems does this integrate with — and who owns them?"
- "Who are the callers? (human users / other internal services / scheduled jobs / event triggers)"
- "Are there existing services this must not break? What are their contracts?"
- "What's the expected peak RPS / data volume / concurrent users?" (if not in NFRs)
- "Where does authentication happen — at the edge, in this service, or delegated?"

---

## HLD Document Format

Save to: `.ai/YYYY-MM-DD-<feature-slug>/hld/hld-<feature-slug>.md`. Read
`references/hld-template.md` before writing the HLD — its section structure
(§1–§12) is what `hld-reviewer` checks and what the notes below refer to.

---

## ADR Format

Save each to `wiki/architecture/ADR-NNN-<kebab-title>.md`. Read
`references/adr-format.md` before writing an ADR — it holds the template and
the immutability rules (supersede, never edit an Accepted ADR).

---

## What Requires an ADR

Write an ADR for every choice where a reasonable engineer could pick differently AND changing it later costs significant rework:

| Category | ADR triggers |
|----------|-------------|
| Storage | Database engine, caching layer, object store, queue technology |
| Communication | Sync vs async between components, REST vs gRPC vs event-driven |
| Auth/authz | Auth mechanism, authorization model (RBAC vs ABAC) |
| Data | Partitioning strategy, consistency model, retention policy |
| Infrastructure | Hosting platform, IaC tool, deployment strategy |
| External | Any third-party dependency whose API you build against |
| Error handling | Retry strategy, DLQ design, graceful degradation policy |

---

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review
- Pattern check before re-dispatch: does this finding's pattern recur elsewhere in the artifact? Fix every occurrence in the same pass — a finding that resurfaces next cycle in a new spot is the cost this discipline exists to cut

## Self-Review: Run `hld-reviewer` Agent

After writing the HLD and ADRs, before presenting to human:

```
Agent(hld-reviewer, {
  HLD_PATH: ".ai/YYYY-MM-DD-<feature-slug>/hld/hld-<feature-slug>.md",
  SPEC_PATH: ".ai/YYYY-MM-DD-<feature-slug>/specs/specs-<feature-slug>.md"
})
```

Fix all **Critical** and **Important** findings before presenting. Advisory findings may be deferred with explicit acknowledgment.

---

## Human Approval Gate

After `hld-reviewer` passes, present to human:

> "HLD committed to `.ai/YYYY-MM-DD-<feature-slug>/hld/hld-<feature-slug>.md`. ADRs committed to `wiki/architecture/`. `hld-reviewer` passed with [N advisory findings — listed below].
>
> Key decisions made: [list 3–5 most consequential ADRs].
>
> Open questions remaining: [list, or 'none'].
>
> Please review and approve before I proceed to `writing-plans`."

<HARD-GATE>
Do NOT invoke writing-plans until the human explicitly approves the HLD. Silence is not approval.

*Senior Dialogue:* inside `/engineer`, the HLD is generated after the human
agreed its decision cards (topic c). That agreement, verified by a passing
consent `check` on the cards the HLD cites, is the approval — do not re-present
the document. A reviewer finding that would change an agreed decision opens
one new card instead.
</HARD-GATE>

If the human requests changes: update HLD and affected ADRs, re-run `hld-reviewer`, re-present.

---

## Transition to `writing-plans`

After explicit human approval:

1. Confirm all Open Questions are resolved or explicitly deferred with acknowledgment
2. Note the HLD path in the `writing-plans` invocation — every plan task should trace to a container in the C4 diagram
3. Invoke `writing-plans` skill

The HLD becomes the authoritative reference for implementation task design. If a `writing-plans` task cannot be traced to a component in the Container diagram, either add the component to the HLD or remove the task from the plan.

**Data model note:** §5.2 (Data Model) describes entities and relationships conceptually. For any feature with database changes, invoke `database-erd` skill to produce the formal Mermaid erDiagram with all entities, FK annotations, cardinality, index strategy, and design decisions. Saved to `.ai/YYYY-MM-DD-<feature-slug>/lld/` alongside sequence diagrams.

**API surface note:** §5.1 defines the API surface conceptually. Before any handler task is defined in `writing-plans`, invoke `api-contract-first` skill to produce the formal OpenAPI 3.1 or `.proto` contract. The handler task references the spec — not the HLD — as its implementation contract.

**Sequence diagram note:** For any flow crossing 3+ components or involving auth/async patterns, invoke `sequence-diagram` skill after the Container diagram is complete. Sequence diagrams show HOW components communicate; the Container diagram shows WHAT exists. Together they form the complete LLD picture.
