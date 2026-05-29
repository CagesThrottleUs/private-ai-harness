# Private AI Harness — Detailed Gap Analysis
# Benchmarked Against World-Class Engineering Products + FAANG

**Date:** 2026-05-28  
**Last updated:** 2026-05-29 — reflects `high-level-design` skill + `hld-reviewer` agent (Phase 2: 2→7/10), `spec-quality-reviewer` agent (Phase 1 gate), `plan-reviewer` agent (plan gate), `language-expert-reviewer` (Phase 6), karpathy wiring (Phase 5). Overall: 4.0→4.4/10  
**Question:** Can this harness replace an entire engineering department and produce output indistinguishable from what that department produces?  
**Benchmark standard:** World-class products (Linux, PostgreSQL, SQLite, Kubernetes, seL4, DO-178C, RFC 8446) + Top engineering organizations (Amazon, Google, Meta, Netflix, Stripe, Microsoft, Spotify, GitHub)  
**Scoring threshold:** Below 9/10 = gap. Scored on two dimensions: (1) is the artifact produced? (2) if yes, is it indistinguishable from department output for that role? Missing artifact categories that a department always produces score 0. Overall score: 4.0/10 (down from 5.1/10 under the corrected question).

---

## How to Read This Document

Each phase section has five parts:

1. **Industry benchmark** — what world-class products AND FAANG engineering orgs actually do
2. **Harness score + what it does** — honest assessment
3. **Precise gaps** — specific, numbered, not vague
4. **Human → LLM translation** — what human engineers do instinctively that LLMs need explicit skills to replicate
5. **Remediation** — what skill to add or enhance, how it integrates, speed/quality/results tradeoff

---

## Phase 0 — Business Context Capture | Score: 2/10

### Industry Benchmark

**Amazon (FAANG):** Working Backwards is the mandatory first step for any new product or feature at Amazon. Before any technical design begins, the PM writes an internal Press Release + FAQ (PR/FAQ). The press release is written from the customer's perspective: "Today, customers can now…" The FAQ addresses: why build this, who is the customer, what do they gain, what's the alternative, why will this succeed. Only after this artifact is reviewed and approved in a readout meeting does engineering begin. No PR/FAQ = no engineering.

**Google (FAANG):** Design Doc (sometimes called a TDD — Technical Design Document) is required before any significant engineering. Google's design doc template starts with "Context and Scope" — why does this problem exist, what is the current state, who is affected. This is the business context in technical form. Staff+ engineers review the business framing before the technical design.

**Meta (FAANG):** Before any engineering engagement, Meta product managers write a product spec using their internal "brief" format. The brief answers: what problem are we solving, who is the user, what is the metric we're moving, what is success. Engineering doesn't start until the brief is signed off.

**Linux kernel (world-class product):** Every patch submission must explain *why* the change is needed — not what it does. Linus Torvalds is explicit: "I don't accept patches without a clear explanation of the problem they solve." Patches without business context are rejected without review. The changelogs of every commit in the kernel are a record of business context at the patch level.

**DO-178C aviation standard (world-class process):** System Requirements specification is a mandatory prerequisite. The System Requirements define what the aircraft must do. Software Requirements can only be written to satisfy System Requirements, not invented from scratch. Business context (what the system must do for the aircraft) is the input gate to the entire development lifecycle.

### Harness Score: 2/10

**Department produces:** PRD/PR/FAQ — committed, versioned artifact with problem statement, user persona, success metrics, and compliance constraints. **Harness produces:** Partial scope negotiation inside a conversation. No committed file. **Verdict:** Absent — a conversation transcript is not a PRD.

`brainstorming` does scope negotiation and out-of-scope documentation. The spec has an explicit out-of-scope section. Beyond this, the harness relies on the human dumping context into conversation. No structured intake artifact. No mandatory first gate.

### Precise Gaps

1. **No structured business context intake artifact.** No equivalent of Amazon PR/FAQ or Google Design Doc context section. The LLM infers goals from conversation, which may be incomplete, inconsistent, or lost across sessions.

2. **No KPI or success metric required.** No mechanism forces the human to answer "what does success look like in measurable terms?" before design begins. Engineers working without a success metric optimize for the wrong thing.

3. **No compliance constraint capture.** GDPR, SOC2, HIPAA, CCPA, data residency — these change every architectural decision. The harness has no mandatory intake place for them.

4. **No stakeholder mapping.** Who must approve this? Who are the external dependencies? What teams are affected? World-class products identify these before design because they determine the review chain.

5. **No session-persistent context.** Business context is lost when a conversation is compressed or a new session starts. No mechanism to re-hydrate it.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "Who is the user?" is always the first question | `business-context-intake` must hard-block until user persona is answered |
| "What does success look like?" before any design | Mandatory KPI field — measurable, not "users are happy" |
| "What are the compliance constraints?" for any data-handling system | Compliance checklist as mandatory intake gate |
| "Who has to sign off?" determines the review chain | Stakeholder map required before HLD begins |
| Context survives across meetings in a PM's memory | Saved to `.ai/specs/business-context.md`, re-read at every session start |

### Remediation

**New skill:** `business-context-intake`  
**Invokes:** Before `brainstorming` — hard gate. `brainstorming` MUST NOT activate without a completed `business-context.md`.  
**Produces:** `.ai/specs/business-context.md` with required fields: problem statement, success metric (measurable), primary user persona, compliance constraints (explicit yes/no per regulation), out-of-scope (≥3 explicit exclusions), stakeholder map, and optional Amazon-style press release for large features.  
**Integration:** `workflow` SKILL.md gains step 0.5: `business-context-intake` before step 1 `brainstorming`.  
**Speed cost:** 5–10 minutes per feature. Eliminates entire sprints built toward the wrong goal.

---

## Phase 1 — Requirements Engineering | Score: 6/10

### Industry Benchmark

**DO-178C (world-class process):** Bidirectional traceability is mandatory: system requirements → software requirements → design → code → tests → verification results. Every requirement must trace to at least one test. Every test must trace to at least one requirement. Orphan requirements and orphan tests are certification failures, not quality warnings. Requirements changes are treated as certification events requiring full re-review.

**seL4 microkernel (world-class product):** The specification is a formal mathematical object in Isabelle/HOL. Every requirement is a theorem. Every implementation is a proof obligation. If the proof compiles, the requirement is satisfied. Zero ambiguity is possible because the spec is machine-checkable.

**SQLite (world-class product):** 8× more test code than implementation code. Every documented behavior has a test that would catch a regression. The specification IS the test suite. Richard Hipp's rule: "If it's not in the test suite, it doesn't exist."

**RFC 8446 TLS 1.3 (world-class standard):** Every requirement uses MUST/SHOULD/MAY taxonomy from RFC 2119. MUST = universal truth, any conforming implementation must satisfy it. SHOULD = strong recommendation, deviation requires justification. MAY = optional. This taxonomy makes enforceability explicit in every sentence.

**PostgreSQL (world-class product):** CommitFest requires a regression test demonstrating new behavior before any reviewer sees a patch. No test = rejected without review, regardless of code quality. Tests are requirements made executable.

**Google (FAANG):** Design docs require explicit "Goals" and "Non-goals" sections. Non-goals are as important as goals — they prevent scope creep and misaligned review feedback. Everything in Non-goals is explicitly not the engineer's responsibility to implement.

### Harness Score: 6/10

**Department produces:** Requirements doc with NFRs, compliance section, MUST/SHOULD/MAY taxonomy. **Harness produces:** REQ-NNN doc with measurable AC and TC mapping. NFR and compliance sections absent. **Verdict:** Partially distinguishable.

`brainstorming` produces REQ-NNN structured requirements with measurable acceptance criteria. `spec-quality-gate` lints for vague language and missing test cases. TC-REQ-NNN maps tests to requirements. This is genuinely good. But several critical requirement categories are not enforced.

### Precise Gaps

1. **No Non-Functional Requirements (NFR) section enforced.** A spec can pass the quality gate without stating: response time < 200ms at p99, availability 99.9%, throughput 10,000 RPS, data retention 7 years, encryption AES-256 at rest. NFRs determine whether you need a cache, a CDN, a read replica, or a queue. Without them, the architecture is designed for unknown constraints.

2. **No compliance requirement section.** No structured place to record: "this system handles PII → GDPR applies → data export and deletion must be implemented." The harness will generate a system without compliance requirements if the human doesn't explicitly mention them.

3. **MUST/SHOULD/MAY taxonomy absent.** A "SHOULD" treated as "MUST" creates overengineering; a "MUST" treated as "SHOULD" creates compliance gaps. Plain English requirements don't distinguish between them.

4. **No traceability for rejected requirements.** World-class specs record WHY something was out-of-scoped. Without this, rejected requirements get relitigated in future sessions.

5. **No living requirements — versioning absent.** When a requirement changes during implementation, there is no mechanism to record the change, the rationale, and the previous version. DO-178C treats this as a certification event.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "This system will need to handle 10× load at peak" — scale intuition | Mandatory NFR table: target throughput, peak throughput, p99 latency target |
| "GDPR applies here because we're storing emails" — compliance radar | Compliance section in spec format, enforced by `spec-quality-gate` |
| "That's a SHOULD, not a MUST" — enforceability judgment | MUST/SHOULD/MAY taxonomy enforced in spec template |
| "We decided not to do X because Y" | Rejected requirements section with rationale, persisted in spec |
| "Requirements changed after the architecture meeting" | Spec change log: every modification stamped with date and rationale |

### Remediation

**Enhance:** `brainstorming` spec template and `spec-quality-gate`  
**Changes:**
- Add mandatory NFR section to spec format:
  ```markdown
  ## Non-Functional Requirements
  | NFR | Target | Measurement | Load Condition |
  |-----|--------|-------------|---------------|
  | Response time | p99 < 200ms | APM histogram | Normal load |
  | Availability | 99.9% | Uptime monitoring | 30-day rolling |
  | Throughput | 1,000 RPS sustained | Load test | Sustained |
  ```
- `spec-quality-gate` fails if NFR section absent or any entry reads "TBD"
- Add MUST/SHOULD/MAY labels to all requirement statements
- Add compliance section: explicit yes/no per regulation with implementation implications
- Add rejected requirements subsection with rationale

**Speed cost:** 5 minutes per spec. Eliminates scale-driven rewrites post-launch.

---

## Phase 2 — High Level Design (HLD) | Score: 7/10

### Industry Benchmark

**Google (FAANG):** Every significant engineering project requires a Design Doc reviewed before coding begins. Staff engineer design docs include: context, goals, non-goals, proposed solution, design details, alternatives considered, cross-cutting concerns (security, privacy, reliability), open questions, and a timeline. The doc is shared async, reviewed by stakeholders, and revised before any code is written. The review is the gate.

**Amazon (FAANG):** AWS services are proposed via a "6-pager" — six sections: overview, regional considerations, security model, high-level architecture, data model, operational considerations. Reviewed by leadership in a readout meeting where the first 15 minutes are silent reading. No presentation — just writing, because writing forces precision.

**Kubernetes (world-class product):** KEPs (Kubernetes Enhancement Proposals) are mandatory for significant changes. A KEP includes: motivation, goals, non-goals, proposal, design details, drawbacks, alternatives, graduation criteria. A KEP must be approved before implementation begins. The KEP IS the HLD.

**Stripe (FAANG-adjacent):** Before any new API is designed, Stripe writes the API design document first — the exact endpoints, request shapes, response shapes, error codes, and versioning strategy. The API contract review happens before a single line of Go is written. This is their version of HLD for API systems.

**Linux kernel (world-class product):** New subsystems require documentation in `Documentation/` before any code is merged. The subsystem maintainer reviews the architecture on the mailing list before accepting patches. Architecture is public and reviewed by domain experts, not just the author.

**C4 Model (industry standard):** Four levels: Context (system in environment), Container (services and data stores), Component (internal structure), Code (class diagrams for critical paths). Every production system should have at minimum Context + Container diagrams. Reviewable by non-technical stakeholders at Context level, by engineers at Container level.

**ADRs (industry standard — Spotify, SoundCloud, ThoughtWorks, AWS):** Architecture Decision Records — immutable once accepted. Format: context, decision, consequences, status (proposed/accepted/deprecated/superseded). Every significant architectural decision gets its own file. When a decision changes, the old ADR is superseded, not edited.

### Harness Score: 7/10

**Department produces:** Design doc (C4 diagrams + ADRs + technology selection + security architecture). Committed before any code. **Harness produces:** `high-level-design` skill produces `.ai/hld/YYYY-MM-DD-<feature>.md` with C4 Context + Container diagrams (Mermaid), technology selection table with alternatives, STRIDE threat model, failure mode analysis per component, 3-scenario capacity planning with scaling triggers, AWS Well-Architected cross-cutting section, and ADRs committed to `wiki/architecture/`. `hld-reviewer` agent (Opus, 10 dimensions) validates before human approval. **Verdict:** Largely indistinguishable in structure. Remaining gap: architectural correctness depends on human input quality; no IaC or ERD artifact.

`high-level-design` skill produces all standard HLD sections. `hld-reviewer` validates against C4 model, Google Design Doc, AWS Well-Architected, and Shostack threat modeling standards. `brainstorming` → `spec-quality-gate` → `high-level-design` is now the canonical architectural path.

### Precise Gaps

1. **No HLD artifact.** No template, no format, no mandatory file. Architecture decisions are made implicitly in brainstorming conversation and then silently encoded in code. The next engineer to touch the system has no design document to read.

2. **No C4 diagram at any level.** No component diagram means architecture lives in the implementer's head and eventually in the code. New engineers reconstruct it by reading code — exactly what documentation should prevent.

3. **No ADR authoring.** The location `wiki/architecture/` exists but there's no ADR template and no skill that guides writing one. Decisions happen; they just aren't recorded. The next session's LLM makes the same decision again — or a different one, silently contradicting the first.

4. **No technology selection record.** When the harness proposes "use PostgreSQL," it does so as an option in brainstorming. There's no formal record: why PostgreSQL over MySQL, what properties matter, what criteria were used, who approved it.

5. **No infrastructure design.** Where does this run? How does it scale? What does failure look like? HLD in any production system must answer these. The harness produces no infrastructure artifact.

6. **No security architecture at design time.** Trust boundaries, auth/authz model, encryption strategy, secret management — these must be designed before code. `security-reviewer` reviews code after it's written. Retrofitting security into code is 10× harder than designing it in.

7. **No capacity planning.** At what load does this need a cache? At what data volume does the schema need partitioning? Without capacity planning at HLD, these become production surprises.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "Draw the boxes first" before any code | HLD artifact required as gate before `writing-plans` activates |
| "What happens when the DB goes down?" — failure thinking | HLD skill asks failure mode for every component: single point of failure? |
| "Use PostgreSQL — here's why" | Technology Selection Record: candidates, criteria, decision, owner |
| "Let's write an ADR so we don't re-debate this" | ADR authoring is part of HLD skill output, template-driven |
| "Where does auth happen in this system?" | Security architecture section: trust boundaries, auth model, secret locations |
| "How much data in 2 years?" — capacity intuition | Capacity planning section: current, 1-year projection, scaling trigger |

### Remediation

**New skill:** `high-level-design`  
**Invokes after:** `spec-quality-gate` passes (and `business-context-intake` completed)  
**Produces:**
- `.ai/hld/YYYY-MM-DD-<feature>.md` — the master HLD document:
  - C4 Context diagram (system in environment, in Mermaid or ASCII)
  - C4 Container diagram (services, databases, queues, their relationships)
  - Technology selection record per major component
  - Security architecture (trust boundaries, auth model, encryption, secrets)
  - Failure mode analysis per component (what fails? what's the impact? what's the mitigation?)
  - Capacity planning (current load, 1-year estimate, scaling trigger)
  - Open questions (unresolved design decisions, with owner and deadline)
- `wiki/architecture/ADR-NNN-<decision>.md` per significant decision:
  ```markdown
  # ADR-NNN: [Decision Title]
  **Status:** Proposed | Accepted | Superseded by ADR-NNN
  **Date:** YYYY-MM-DD
  ## Context
  ## Decision
  ## Consequences — Positive / Negative
  ## Alternatives Considered
  | Alternative | Why Rejected |
  ```

**Human gate:** User reviews and approves HLD before `writing-plans` activates.  
**Integration:** `workflow` SKILL.md gains step 2.5: `high-level-design` between `spec-quality-gate` and `writing-plans`.  
**Speed cost:** 30–60 minutes per feature. Saves multiple rework cycles when architecture surprises emerge mid-implementation.

---

## Phase 3 — Low Level Design (LLD) | Score: 4/10

### Industry Benchmark

**Stripe (FAANG-adjacent):** API-first is non-negotiable. The OpenAPI specification for every endpoint is reviewed and published before any handler code is written. Teams use Prism to mock the API spec so frontend can develop against it simultaneously. The spec review IS the design review.

**Google (FAANG):** gRPC proto-first is Google's internal standard. The `.proto` file is the contract. Server and client code is generated from it. The proto review (which defines every field name, type, and wire format) is the API review. This happens before any service is implemented.

**PostgreSQL (world-class product):** Schema migrations are reviewed more carefully than application code. Every migration is reviewed for: backward compatibility with the previous app version (for zero-downtime deploys), index strategy (no table scans on queries running > 1/sec), constraint completeness (NOT NULL where business logic requires it, foreign keys where relationships exist). A migration that locks a large table is rejected.

**Kubernetes (world-class product):** KEP design details section includes the exact YAML schema for every new resource type — all fields, types, validation rules, and defaulting behavior — before any Go struct is written. The API shape is the most important architectural decision.

**Linux kernel (world-class product):** Error handling design is explicit. Every kernel function that can fail documents: what errors are returned, what the caller must do with each error, and which errors are fatal vs recoverable. The error taxonomy is designed, not discovered.

**Netflix (FAANG):** Sequence diagrams for any operation crossing service boundaries. "Draw the sequence diagram first" is a standard design practice at Netflix for new microservice interactions. The diagram shows who talks to whom, in what order, what happens on failure at each step.

### Harness Score: 4/10

**Department produces:** OpenAPI/gRPC spec per endpoint, schema ERD, error taxonomy. **Harness produces:** Implementation task plan with file paths and code snippets. No API spec file, no schema doc. **Verdict:** Distinguishable — different abstraction levels.

`writing-plans` produces task-level instructions with file paths and code snippets. `design-principles` guides SOLID/cohesion/coupling. `code-documentation` documents code after writing. API contracts, schema design, and error taxonomy design are absent.

### Precise Gaps

1. **No API contract before code.** The harness writes handler code and then documents it. API-first means OpenAPI spec reviewed before first handler. Without this, frontend and backend can't develop in parallel, and the API shape is determined by what was convenient to implement.

2. **No database schema design artifact.** Schemas are written inline in migration files as implementation happens. No formal schema review. Schema decisions (column types, indices, constraints, normalization) are as architecturally important as algorithm decisions.

3. **No error taxonomy design.** Which errors are retryable? Which are user-facing with actionable messages? Which require alerting? Without a taxonomy, each component invents its own error handling, producing inconsistent behavior at system boundaries.

4. **No sequence diagrams for critical paths.** For operations touching 3+ components, a sequence diagram shows who talks to whom, in what order, what data is exchanged, and what happens on failure. These are discovered during debugging without diagrams.

5. **No interface-first module design.** World-class practice: write the interface/contract first, then implement it. The harness writes implementation and extracts interfaces later (if at all).

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "Write the OpenAPI spec first, then the handler" | `api-contract-first`: OpenAPI/proto written before any handler code |
| "This index will die on 100M rows" — query performance intuition | Schema checklist: every query against this table, supporting index for each |
| "Nullable columns in business logic are a bug" | Schema review: NOT NULL constraint where business logic requires it |
| "This migration will lock the table" | Zero-downtime migration checklist in `schema-design` skill |
| "HTTP 503 = retry, HTTP 400 = don't retry" | Error taxonomy document: retryable, non-retryable, user-facing, fatal |
| "Draw the sequence diagram for the auth flow" | Sequence diagram required for flows touching 3+ components |

### Remediation

**New skill:** `api-contract-first`  
**Invokes during:** `writing-plans` — when a plan task creates a new API endpoint  
**Produces:**
- `api/<resource>.yaml` — OpenAPI 3.1 spec (method, path, parameters, request body, response schemas including error responses, versioning)
- Mock server config (Prism or equivalent) from the spec

**Human gate:** OpenAPI spec review before any handler code is written.  
**LLM instruction:** "Do not write the handler until the spec is reviewed. Implement to the spec, not from the implementation."

**New skill addition to `writing-plans`:** Schema design checklist per migration task:
- Every column: data type justified, NOT NULL or explicitly nullable with reason, foreign key if relationship exists
- Every query: supporting index identified, `EXPLAIN ANALYZE` output if table > 100k rows
- Zero-downtime migration path: add nullable → backfill → add constraint → drop old

**Speed cost:** 15 minutes per endpoint. Enables parallel frontend/backend development — net time savings for any team.

---

## Phase 4 — Task Distribution | Score: 7/10

### Industry Benchmark

**Linux kernel (world-class product):** Hierarchical maintainer tree. Every subsystem has a maintainer who reviews and approves all patches for that domain. Patches go to subsystem maintainer → Linus's tree. No patch bypasses its maintainer. Hundreds of subsystems develop in parallel without conflict because ownership is explicit and hierarchical.

**Kubernetes (world-class product):** Special Interest Groups (SIGs) own subsystems. SIG-API-Machinery, SIG-Network, SIG-Storage. Every KEP must be approved by the relevant SIG leads. Ownership is public. Task ownership is not ambiguous.

**PostgreSQL (world-class product):** CommitFest: five review windows per year. Every patch is assigned to a reviewer who is not the author. Patch status (Needs Review → Waiting on Author → Ready for Committer → Committed/Rejected) is tracked publicly. Nothing merges without reviewer sign-off.

**Meta (FAANG):** Stacked diffs — large changes are broken into a stack of small, independently-reviewable diffs. Each diff in the stack has a clear dependency chain. Reviewers can review each level of the stack without waiting for the full feature to be complete.

### Harness Score: 7/10

**Department produces:** Sprint board / Kanban with tasks, owners, dependencies, status. **Harness produces:** `.ai/plans/` task list with subagent parallelism. No dependency graph or ownership model. **Verdict:** Mostly indistinguishable in content; form is different.

`dispatching-parallel-agents` parallelizes independent tasks. `subagent-driven-development` dispatches fresh agents per task. `writing-plans` creates bite-sized tasks. Human checkpoints in `executing-plans`. This is a genuine analog to team task distribution.

### Precise Gaps

1. **No dependency graph between tasks.** If Task 5 depends on Task 3's interface, starting Task 5 before Task 3 completes produces code against a not-yet-defined contract. Dependencies are implicit in current plan format.

2. **No ownership model.** When a subagent blocks, there is no escalation path. In a real team, blocked tasks escalate to a lead who can unblock. The harness has `BLOCKED` status but no resolution path.

3. **No estimation calibration.** "2-5 minute tasks" has no calibration mechanism. Underestimated tasks cause surprise mid-implementation.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "Task 5 can't start until Task 3 defines the interface" | Explicit `depends_on: [task-3]` in plan format, DAG generated |
| "When blocked, escalate to me immediately" | Escalation path in `subagent-driven-development`: BLOCKED → senior agent |
| "How long will this actually take?" — estimation | Estimation field per task, tracked against actuals |

### Remediation

**Enhance `writing-plans`:** Add `depends_on: []` field to task format. Generate a dependency graph (Mermaid) showing which tasks can parallelize and which must sequence. Add a "senior agent" escalation role in `subagent-driven-development` for BLOCKED resolution.  
**Speed cost:** Low. Adds structure to existing plan format.

---

## Phase 5 — Individual Implementation | Score: 8/10

### Industry Benchmark

**Linux kernel (world-class product):** `checkpatch.pl` runs on every patch before human review. Style errors are blocking — the patch is not forwarded to maintainers with unresolved `checkpatch.pl` errors. Code style is not a preference; it's an automated gate.

**PostgreSQL (world-class product):** `pgindent` runs on all C code before commit. Unindented code is not accepted. The formatting is so consistent across 30 years that code written in 1996 and code written in 2025 look identical.

**SQLite (world-class product):** 21 coding conventions documented in the source. Every file follows them. The consistency across 370,000 lines of C maintained by one person is the result of enforced, documented conventions — not personal discipline.

**Rust compiler (world-class product):** The borrow checker IS the code review for memory safety. If it compiles, a class of bugs is provably absent. The type system enforces world-class safety standards automatically — the developer's code is correct by construction if it compiles.

**Google (FAANG):** Language-specific style guides (Google C++ Style Guide, Google Python Style Guide, etc.) are enforced by automated tools in CI. No debate about formatting — the tool decides. Reviewer time is spent on logic, not style.

### Harness Score: 8/10

**Department produces:** Code + unit tests + docstrings + micro-commits, style-guide compliant, linter-clean. **Harness produces:** Same minus language-specific linter enforcement. **Verdict:** Largely indistinguishable.

`karpathy` is now actively wired into `writing-plans`, `executing-plans`, and `subagent-driven-development` — anti-pattern checks run at every plan step, not only when the skill is manually invoked. `code-documentation` checkpoint is embedded in the `writing-plans` task template, executing before every commit. `test-driven-development` enforces RED-GREEN-REFACTOR. `design-principles` enforces SOLID. `commit-discipline` enforces micro-commits. This stack is very good.

### Precise Gaps

1. **No language-specific style gate.** The harness is language-agnostic at implementation time. Python needs Black + isort + mypy --strict. TypeScript needs ESLint + Prettier + tsc --strict. Go needs gofmt + golangci-lint. Rust needs clippy + rustfmt. `karpathy` (now wired into execution workflows) catches LLM-specific anti-patterns but is not a formatter or linter — it does not enforce language-specific style conventions. Note: `language-expert-reviewer` catches idiom violations at PR review, which partially closes this gap retroactively, but does not prevent style violations from entering the codebase in the first place.

2. **`verification-before-completion` missing linter gate.** The checklist doesn't include: run formatter, run linter, run type checker, all pass. This remains the primary open gap for Phase 5.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "Run the linter before you push" — muscle memory | Linter/formatter gate in `verification-before-completion`, project-type-detected |
| "That's not idiomatic Go" — language expertise | Language-specific style guidance in `verification-before-completion` |

### Remediation

**Enhance `verification-before-completion`:** Detect project type from `pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`. Run the appropriate tool stack before marking any task complete. Fail if linter or formatter produces output.  
**Speed cost:** Near zero — these tools run in seconds. Eliminates style-based review comments entirely.

---

## Phase 7 — Integration & Testing | Score: 3/10

### Industry Benchmark

**Spotify (world-class org):** Explicitly rejected the Testing Pyramid for microservices in favor of the Testing Honeycomb: fewer unit tests, more integration tests, minimal E2E tests. Their finding: "The biggest complexity in a microservice is not within the service itself, but in how it interacts with others." Unit tests test internal functions in isolation — they don't catch the real bugs.

**PostgreSQL (world-class product):** The regression test suite runs every query through a real PostgreSQL instance. No mocks. 230,000+ lines of SQL running against a real database since 1994. Every test is a real database transaction.

**Netflix (FAANG):** E2E tests simulate the full user journey: authenticate → browse → select → stream → quality adaptation → completion across device types. Because Netflix integrates CDN, DRM, recommendation, billing, and device SDKs, only E2E tests verify the system works cohesively. These run before every deployment.

**SQLite (world-class product):** 8× test-to-code ratio. 100% branch coverage is the standard — not aspirational, achieved. If a branch isn't exercised by a test, it's treated as dead code.

**DO-178C (world-class process):** Structural coverage requirements: Level C = statement coverage (every executable statement runs), Level B = decision coverage (every branch taken both ways), Level A = MC/DC (every condition independently exercised). For flight-critical software, 100% MC/DC is mandatory, not a stretch goal.

**Kubernetes (world-class product):** Integration tests use `envtest` — a real in-memory API server. Controller behavior is tested against the real API server, not mocked. If the real API server doesn't exist in the test, the behavior being tested doesn't exist either.

**Microsoft (FAANG):** Engineering Fundamentals Playbook requires E2E tests for every critical user journey. "The main branch should always be shippable" — which requires E2E tests verifying the critical paths in CI.

### Harness Score: 3/10

**Department produces (QA role):** Unit + integration + E2E + performance tests, coverage gate enforced. **Harness produces:** Unit tests only. **Verdict:** Clearly distinguishable — 1 of 4 test layers present.

`test-driven-development` enforces unit test TDD. `test-quality-reviewer` validates tests are meaningful. `requesting-code-review` triggers test quality review. The harness stops at unit tests.

### Precise Gaps

1. **Unit tests only — no integration test skill.** Unit tests with mocks encode assumptions about collaborator behavior. When those assumptions are wrong — the real DB returns a different error code, the real queue has at-least-once delivery — tests pass and production fails. This is where production failures hide.

2. **No E2E test skill.** At least one critical user journey must be tested end-to-end: real HTTP requests, real responses, real persistence. The harness produces no E2E test artifacts.

3. **No test coverage gate.** "Tests exist" ≠ "tests cover the code." No minimum threshold enforced. No mechanism to fail CI when coverage drops.

4. **No performance test.** NFRs define performance targets. Performance tests verify them under load. Without them, NFRs are aspirations. With them, they're contractual guarantees.

5. **No test data management.** Integration tests require reproducible, isolated test data. Without fixtures and factories, tests share mutable state, causing flaky, order-dependent failures.

6. **No contract testing.** Consumer-driven contract tests (Pact) verify that producer responses match consumer expectations. This catches breaking API changes before deployment.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "A mock isn't the same as the real thing" | `integration-testing`: tests run against real dependencies, never mocks at boundary |
| "Test the happy path from the browser's perspective" | `e2e-testing`: critical user journeys through real entry point |
| "What's our coverage?" — coverage awareness | Coverage gate in `verification-before-completion`: minimum threshold required |
| "Can this handle 100 concurrent users?" | `load-testing`: k6/Locust script targeting NFR targets |
| "Test data must be isolated — don't touch prod" | Test data management: fixtures, factories, teardown documented in `integration-testing` |
| "Does our producer still satisfy the consumer?" | Contract testing guidance: Pact or equivalent for service-to-service APIs |

### Remediation

**New skill:** `integration-testing`  
**Invokes during:** `test-driven-development` GREEN phase, for any component with external dependencies (DB, queue, external API)  
**Produces:**
- Integration test files using testcontainers (or equivalent) for real DB/queue/cache
- Test fixture and factory definitions
- Integration test CI job added to `ci.yml`

**LLM instruction in skill:** "No mocks at the integration test boundary. The database in the test is a real database started by testcontainers. A test using `mock.DB` is a unit test, not an integration test. Write both."

**New skill:** `e2e-testing`  
**Invokes:** Before `finishing-a-development-branch`, for any user-facing system  
**Produces:** At least one E2E test covering the primary user journey

**Enhance `verification-before-completion`:** Add coverage gate — run coverage tool, fail if below project threshold (default: 80% line, 70% branch).

**Speed cost:** Integration tests add ~20% to test write time. They save ~80% of production bug investigation time.

---

## Phase 8 — CI/CD | Score: 1/10

### Industry Benchmark

**DORA Research 2025 (industry standard):** Elite engineering teams deploy daily or on-demand. Lead time from commit to production < 1 day. Change failure rate < 5%. Recovery time < 1 hour. Elite performers show 2.5× faster time to market and 50% higher market cap growth. CI/CD is the primary differentiator between engineering organizations.

**Microsoft (FAANG):** Engineering Fundamentals Playbook mandates CI/CD on every engineering project: "build, test, and deploy each change." Main branch must always be shippable. CI builds on every PR. CD to staging automatically on merge. Infrastructure as Code for all environments — "provisioning should be a repeatable process driven off code artifacts in git."

**Meta (FAANG):** Sandcastle (CI) integrates with Phabricator (code review). Every diff triggers Sandcastle before human review. CI result is visible on the diff. No human review without CI passing.

**GitHub (FAANG):** Branch protection rules enforce: all CI checks must pass, required reviewers must approve, no force pushes to main. Mergify (or Tide for Kubernetes) automates merge when all conditions are met. Human decisions are architectural; merge mechanics are automated.

**Netflix (FAANG):** Spinnaker for deployment pipelines. Automated health checks after deploy — if error rate rises within 5 minutes, deploy auto-rolls back. No human required for rollback. Deployment and rollback are as automated as the code itself.

**PostgreSQL (world-class product):** CFbot runs CI on every proposed patch across 4+ operating systems before any human reviewer sees it. A patch that fails CFbot is not reviewed. Automated gate before human gate.

### Harness Score: 1/10

**Department produces (DevOps):** Working `.github/workflows/ci.yml` + staging deploy pipeline + IaC configuration. **Harness produces:** `github-workflows` skill with GH Actions patterns and guidance — no pipeline file generated. **Verdict:** Clearly distinguishable — guidance is not an artifact. A DevOps engineer who produces only a document explaining CI/CD principles has not done their job.

`github-workflows` covers GH Actions patterns. `finishing-a-development-branch` guides post-implementation options. The harness ends at code merge.

### Precise Gaps

1. **No CI pipeline as deliverable.** The harness produces application code but no `.github/workflows/ci.yml`. When a developer ships using the harness, there is no automated gate between their branch and main.

2. **No required pre-merge checks defined.** No standard for "these checks must pass before any PR merges." The harness has a developer checklist; world-class teams have automated enforcement.

3. **No deployment pipeline.** The harness has no concept of staging, production, or the promotion pipeline between them.

4. **No secrets management.** Credentials in code, environment variables without rotation, accidental secret commits — the harness has no guidance on any of this.

5. **No feature flags.** Decouple deploy from release — deploy at 100%, release at 1%, ramp gradually. Not addressed.

6. **No coverage gate in CI.** Code coverage below threshold should fail CI. Not defined.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "It works on my machine" is not enough | CI pipeline as mandatory deliverable — not optional |
| "Every PR should be green before merge" | Branch protection rules + required CI checks in `ci-pipeline-setup` |
| "Never hardcode secrets" — security hygiene | Secrets management checklist: env vars, vault, rotation |
| "Deploy to staging before production" | Deployment pipeline: staging promotion gate |
| "Infrastructure should be code, not ClickOps" | IaC requirement: Terraform/Pulumi committed alongside code |

### Remediation

**New skill:** `ci-pipeline-setup`  
**Invokes at:** `using-git-worktrees` (branch creation) — CI exists from day one, not as a pre-merge afterthought  
**Produces:**
- `.github/workflows/ci.yml` — detects project type, generates: lint + format check + type check + unit tests + integration tests + coverage gate + security scan (Dependabot/Trivy)
- `.github/workflows/deploy-staging.yml` — deploys to staging on merge to main
- Secrets management guidance: where to store them, rotation expectations

**Integration:** `using-git-worktrees` SKILL.md triggers `ci-pipeline-setup` immediately after branch creation.  
**Speed cost:** Near zero — template generation. CI runs automatically. Saves all merge-blocking CI setup sessions at PR time.

---

## Phase 9 — Deployment & Release | Score: 0/10

### Industry Benchmark

**Netflix (FAANG):** Spinnaker deploys via blue/green or canary. Health checks monitor error rate and latency post-deploy. If metrics degrade within 5 minutes, automatic rollback with no human approval required. Deploy and rollback are symmetrical operations.

**Amazon (FAANG):** Separate deployment from release. Code is deployed dark (no users), then traffic is shifted gradually using weighted routing (1% → 10% → 50% → 100%). If any metric degrades at any traffic level, shift back. Deployment is automated; release is deliberate.

**Stripe (FAANG-adjacent):** Database migrations are the highest-risk event. Every migration must be backward-compatible with the previous application version. Three-step approach: (1) add new nullable column, deploy new code that writes to both, (2) backfill, (3) add constraint, drop old column. No single migration breaks a running instance.

**Kubernetes (world-class product):** Rolling deployments are the default. New pods start before old pods terminate. Health checks (liveness, readiness) must pass before traffic is shifted. If rollout fails, `kubectl rollout undo` restores the previous version in seconds.

**Meta (FAANG):** 1 million+ Android beta testers receive mobile release candidates daily. Canary users get new code before broad rollout. Problems surface at 0.1% of traffic, not 100%.

**Microsoft (FAANG):** "The main branch should always be shippable" — meaning every commit to main could be deployed to production. Post-deploy smoke tests run automatically to verify core journeys work.

### Harness Score: 0/10

Phase 9 is entirely absent.

### Precise Gaps

1. **No deployment strategy skill.** Blue/green, canary, rolling, dark launch — each has trade-offs. The harness doesn't guide selection or implementation.

2. **No zero-downtime migration discipline.** Database migrations are the highest-risk event in any deployment. The harness writes migrations but has no backward-compatibility guidance.

3. **No rollback procedure.** Every deployment needs a documented, tested rollback procedure. Not "undo the merge" — a specific command sequence with estimated time.

4. **No post-deploy smoke tests.** After production deployment, automated smoke tests should verify core journeys work. Not present.

5. **No release notes generation.** The harness produces good commit messages but has no mechanism to extract them into user-facing release notes.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "This migration must be backward-compatible" | Zero-downtime migration checklist: add nullable → backfill → constrain → drop old |
| "What's the rollback command?" — muscle memory | Rollback procedure document: one command, estimated time, tested in staging |
| "Run the smoke tests after deploy" | Post-deploy smoke test spec: critical endpoints verified within 5 minutes |
| "Blue/green for stateful, canary for stateless" | Deployment strategy decision guide |
| "Write the release notes from the commit log" | `release-notes` skill: git log parsing → user-facing changelog |

### Remediation

**New skill:** `deployment-workflow`  
**Invokes at:** `finishing-a-development-branch` — required before PR can be labeled deployment-ready  
**Produces:**
- Zero-downtime migration checklist (auto-generated if database changes exist in diff)
- Rollback procedure document: step-by-step, estimated time, verified in staging
- Post-deploy smoke test list: critical endpoints and user journeys to verify
- Release notes draft from `git log --oneline <last-tag>..HEAD`
- Deployment strategy recommendation based on system type

**Human gate:** Rollback procedure acknowledgment before PR is labeled deployment-ready.  
**Integration:** `finishing-a-development-branch` SKILL.md requires `deployment-workflow` completion before presenting merge options.  
**Speed cost:** 10 minutes per release. Saves hours per production incident.

---

## Phase 10 — Observability & Operations | Score: 0/10

### Industry Benchmark

**Google SRE (FAANG — and world-standard):** Four Golden Signals: latency (how long requests take), traffic (how much demand), errors (rate of failing requests), saturation (how full the constrained resource is). These four metrics are the minimum for any production system. Defined in the Google SRE Book (2016) and now the industry standard. If you can only monitor four things, monitor these.

**Google SRE:** SLI (Service Level Indicator — the actual measurement), SLO (Service Level Objective — the target: e.g., 99.9% of requests < 200ms), SLA (the user contract). SLOs are agreed before deployment, not after the first incident. An SLO breach triggers the error budget policy — engineering stops new features and focuses on reliability.

**Netflix (FAANG):** Distributed tracing with correlation IDs propagated through every service call. Every log entry has a request ID. A single user request can be traced across 50+ microservices from a single search. Without this, debugging a multi-service failure requires coordinating log tailing across N services simultaneously.

**Amazon (FAANG):** Every new AWS service is required to have operational runbooks before launch. Runbooks describe: what does this alert mean, what is the user impact, what are the immediate diagnosis steps, what are the remediation actions, when to escalate. Oncall engineers should be able to resolve 80% of incidents from the runbook alone.

**PostgreSQL (world-class product):** Built-in observability: `pg_stat_statements`, `pg_stat_activity`, `pg_locks`, slow query log, auto_explain. Every production PostgreSQL database runs with these enabled. Query performance is observable without any external tooling, by design.

**Microsoft (FAANG):** Engineering Fundamentals Playbook requires structured logging on every project: timestamps, severity, correlation IDs, context. "The logging approach should be agreed on and consistent across all team members."

### Harness Score: 0/10

Phase 10 is entirely absent.

### Precise Gaps

1. **No structured logging standard.** Every log entry should have: timestamp (ISO 8601), severity, correlation ID, service name, operation name, enough context to diagnose without SSH. The harness produces systems with ad-hoc logging, if any.

2. **No metrics design.** No golden signal metrics defined for the system. Latency histograms, error rate counters, throughput gauges — must be instrumented in code before deployment, not added after the first incident.

3. **No SLO definition.** "What does working mean?" must be answered before deployment. The harness has no mechanism for this.

4. **No alerting design.** Alert on symptoms (p99 latency > 500ms, error rate > 1%), not causes (CPU > 80%). Not present.

5. **No runbook authoring.** Without runbooks, oncall engineers make decisions under pressure without guidance. Every incident takes longer than it should.

6. **No distributed tracing.** Without correlation IDs, debugging a multi-service failure requires manual log correlation across every service.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "Every log needs a correlation ID" | Structured logging standard: mandatory fields per log entry |
| "Alert on symptoms, not causes" | Alert design guide: user-impacting symptoms only; cause metrics go to dashboard |
| "What's our p99?" — latency budget instinct | Golden signal instrumentation: histogram per endpoint |
| "The runbook should let oncall resolve without waking me up" | Runbook template: what it means, diagnosis, remediation, escalation |
| "Agree on the SLO before we deploy" | SLO definition as required pre-deployment artifact |
| "Propagate the trace ID through every call" | Distributed tracing instrumentation guide |

### Remediation

**New skill:** `observability-standards`  
**Invokes after:** First implementation task creating any API endpoint  
**Produces:**
- Structured logging configuration per language (structlog for Python, zerolog for Go, pino for Node, etc.)
- Golden signal metrics instrumentation: latency histogram + error counter + throughput gauge per endpoint (Prometheus/OpenTelemetry)
- SLO definition document: `wiki/guides/slos.md` — pulls targets from NFRs defined in Phase 1
- Alert rules template: `wiki/guides/alerts.md` — symptom-based, not cause-based
- Runbook template: `wiki/guides/runbooks/RUNBOOK-TEMPLATE.md`

**Integration:** `executing-plans` and `subagent-driven-development` — after any task creating an API endpoint, `observability-standards` instruments it. Not a separate phase — part of endpoint creation.  
**Speed cost:** 10 minutes per service. Saves hours per production incident — and there will be incidents.

---

## Phase 11 — Technical Documentation | Score: 5/10

### Industry Benchmark

**SQLite (world-class product):** Every function, every SQL keyword, every configuration parameter documented at sqlite.org. Documentation maintained by the author, updated in the same commit as behavior changes. Complete enough to implement SQLite from scratch without reading the source.

**PostgreSQL (world-class product):** The PostgreSQL docs are the industry standard for database documentation. Every version ships with documentation for every feature, function, operator, and parameter. Undocumented features are not released.

**Kubernetes (world-class product):** API reference auto-generated from Go struct comments. Every field in every resource has a description embedded in the code. The comment IS the documentation.

**Stripe (FAANG-adjacent):** Industry standard for developer API docs. Every endpoint: method, URL, parameters (name, type, required/optional, description), request example, response example, error codes. Updated in the same PR as the code change. If the docs are wrong, the PR is rejected.

**Linux kernel (world-class product):** `Documentation/` directory required for every new subsystem. New subsystems are not accepted without documentation. The documentation is peer-reviewed by domain experts alongside the code.

**AWS (FAANG):** ADR best practices published on the AWS Architecture Blog. ADRs are immutable once accepted. If a decision changes, the old ADR is superseded — not edited. The history of decisions is as important as the current decision.

### Harness Score: 5/10

**Department produces (Tech Writer + Sr Engineers):** API reference per endpoint, ADR per architectural decision, onboarding guide, per-alert runbooks, formatted changelog. **Harness produces:** Code-level docstrings + wiki directory structure. No ADR template, no onboarding skill, no runbooks, no changelog standard. **Verdict:** Distinguishable — function docs are present; project-level documentation suite is absent.

`code-documentation` requires full docstring per public construct. Wiki sync rules enforce simultaneous doc + code updates. `wiki/api/`, `wiki/architecture/`, `wiki/guides/` locations defined. Changelog convention defined. Good structure but incomplete.

### Precise Gaps

1. **No ADR template.** The location `wiki/architecture/` exists but no template. Without a template, decisions don't get documented or get documented inconsistently.

2. **No runbook template or authoring skill.** Entirely absent (see Phase 10).

3. **No API reference generation.** Docstrings exist; Stripe-quality API reference pages with request/response examples for every endpoint do not.

4. **No onboarding guide authoring skill.** Location exists; no skill to generate the content.

5. **No changelog format standard.** `wiki/changelog/` exists. Format (Keep a Changelog? Conventional Changelog? GitOps?) is undefined.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "Write an ADR for this decision" | ADR template in `wiki/architecture/ADR-TEMPLATE.md`, skill to author it |
| "New engineers should be productive on day one" | `onboarding-guide-authoring` skill: generates dev setup, architecture overview, first contribution guide |
| "Write the release notes from the git log" | Changelog format standard + `release-notes` skill |

### Remediation

**Enhance `high-level-design`:** Include ADR authoring as mandatory output. Template embedded in skill.  
**Enhance `finishing-a-development-branch`:** Run `release-notes` generation from git log. Define Keep a Changelog format as standard.  
**Add:** `onboarding-guide-authoring` section to `finishing-a-development-branch` — triggered on first production release.  
**Speed cost:** Low. All template-driven. Eliminates undocumented decision archaeology.

---

## Quality Dimension: Security by Design | Score: 6/10

### Industry Benchmark

**seL4 (world-class product):** Security architecture IS the mathematical proof object. There are no "security features added later." The capability-based security model is designed from axiom level. Every security property is a theorem proven before a line of C is written.

**TLS 1.3 / RFC 8446 (world-class standard):** Designed with a threat model by cryptographers before implementation. Every message is designed knowing the network is adversarial. Every field is sized to prevent oracle attacks. Protocol → implementation, not implementation → protocol.

**Amazon (FAANG):** Every new AWS service undergoes a threat modeling review at HLD stage. The threat model identifies: who are the adversarial actors, what are the assets, what are the attack surfaces, what are the mitigations. This review precedes any code.

**OWASP ASVS (industry standard):** Application Security Verification Standard — testable security requirements at three levels. Level 1 (opportunistic), Level 2 (standard), Level 3 (advanced/defense-in-depth). World-class teams pick a level and verify every requirement before deployment.

**Google (FAANG):** "Security by Design" is a non-negotiable principle. Security review is part of the design doc review process — before implementation begins.

### Harness Score: 6/10

`security-reviewer` is an excellent reactive reviewer — one of the harness's strengths. But it reviews code after it's written. Security architecture (trust boundaries, auth model, encryption, secrets) must be designed before code is written. Retrofitting security into code is 10× harder.

### Precise Gaps

1. **Security at design time absent.** Threat modeling, trust boundary definition, auth/authz model — these belong in HLD. The harness puts them in code review.

2. **No OWASP ASVS integration.** No structured security requirements framework. OWASP ASVS provides testable security requirements — exactly the format the harness already uses for functional requirements.

3. **No security section in spec.** A spec can pass `spec-quality-gate` with no mention of authentication, authorization, encryption, or data classification.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "Who are the adversaries? What are they after?" | Threat model section in `high-level-design` |
| "Where do trust boundaries cross?" | Trust boundary drawing on C4 Container diagram |
| "What's the auth model for this API?" | Security section in spec format (auth mechanism, authz model, data classification) |

### Remediation

**Enhance `brainstorming` spec template:** Add security requirements section — enforced by `spec-quality-gate`:
```markdown
## Security Requirements
**Authentication:** [JWT, OAuth2, API key, mTLS]
**Authorization:** [RBAC, ABAC, capability-based]
**Data classification:** [PII? PCI? Internal only?]
**Encryption at rest:** [required? which fields? key management?]
**Encryption in transit:** [TLS version?]
**Secret management:** [vault? env vars? rotation?]
**Threat model summary:** [primary adversarial actors, key assets, mitigations]
```

**Enhance `high-level-design`:** Threat modeling is mandatory output. Trust boundaries on C4 diagram. Attack surface enumeration.  
**Speed cost:** 10 minutes per design. Saves days of security remediation post-`security-reviewer` findings.

---

## Quality Dimension: Performance by Design | Score: 3/10

### Industry Benchmark

**SQLite (world-class product):** Benchmarks comparing SQLite to every major database are published and maintained. Every significant optimization is documented with the workload that motivated it. Performance is designed, not discovered.

**Netflix (FAANG):** Continuous performance tests run against production using production traffic replay. p99 latency is known for every endpoint. A deploy that increases latency by 5% is detected before full rollout.

**Google (FAANG):** Core Web Vitals (LCP < 2.5s, FID < 100ms, CLS < 0.1) are measurable performance requirements for web properties. Not "fast" — specific, measurable targets.

**PostgreSQL (world-class product):** Every major release runs the pgbench benchmark suite. Performance regressions block release. A patch that makes a standard workload slower doesn't merge.

### Harness Score: 3/10

Performance is not addressed at any phase.

### Precise Gaps

1. **No performance NFRs enforced in spec.** Without latency/throughput/resource targets in the spec, implementation has no performance goals.

2. **No performance testing.** No `load-testing` skill. Code that is correct and slow passes all harness gates.

3. **No performance design.** Caching, indexing, async vs sync, connection pooling — performance design decisions made at HLD/LLD. Not guided by the harness.

4. **No performance regression gate in CI.** No mechanism to block merges that regress performance.

### Human → LLM Translation

| Human Tacit Knowledge | LLM Needs Explicit Skill |
|-----------------------|--------------------------|
| "This will need a cache at 1000 RPS" | Performance design section in HLD: caching strategy, async boundaries |
| "This query will kill the DB without an index" | Query performance checklist in LLD/schema design |
| "Can this handle the load?" | `load-testing` skill: k6/Locust targeting NFR targets |

### Remediation

**Enhance spec template:** NFR table (mandatory, in Phase 1 remediation) covers performance targets.  
**Enhance `high-level-design`:** Add caching strategy, async vs sync boundary, query plan sections.  
**New skill:** `load-testing` — invokes before `finishing-a-development-branch` for any API project. Produces k6/Locust script targeting NFR targets. Runs in CI.  
**Speed cost:** 15 minutes per milestone. Eliminates performance surprises post-launch.

---

## Aggregate Gap Priority

| Priority | Gap | New Skill/Enhancement | Harness Integration Point |
|----------|-----|----------------------|--------------------------|
| ✅ **P0 CLOSED** | ~~No HLD artifact~~ | `high-level-design` skill + `hld-reviewer` agent | After `spec-quality-gate`, before `writing-plans` — **shipped 2026-05-29** |
| **P0** | No observability | `observability-standards` (new) | During `executing-plans`, per endpoint |
| **P0** | No CI/CD pipeline | `ci-pipeline-setup` (new) | At `using-git-worktrees` |
| **P0** | No deployment | `deployment-workflow` (new) | At `finishing-a-development-branch` |
| **P1** | No NFR section | Enhance `brainstorming` + `spec-quality-gate` (backed by `spec-quality-reviewer` agent — **shipped**) | Spec template + quality gate |
| **P1** | No integration tests | `integration-testing` (new) | During `test-driven-development` |
| **P1** | Security at design time | Enhance `brainstorming` + `high-level-design` | Spec template + HLD |
| **P1** | No API contract first | `api-contract-first` (new) | During `writing-plans` per endpoint |
| **P2** | No business context intake | `business-context-intake` (new) | Before `brainstorming` |
| **P2** | No performance by design | Enhance HLD + `load-testing` (new) | HLD + `finishing-a-development-branch` |
| **P2** | No E2E tests | `e2e-testing` (new) | Before `finishing-a-development-branch` |
| **P2** | No runbooks | Enhance `observability-standards` | During `observability-standards` |
| **P3** | Language-specific linting | Enhance `verification-before-completion` | Per task completion |
| **P3** | No task dependency graph | Enhance `writing-plans` format | Plan authoring |
| **P3** | No ADR template | Enhance `high-level-design` | HLD output |
| **P3** | Changelog format | Enhance `finishing-a-development-branch` | Pre-merge |

---

## Complete Workflow After All Remediations

```
[New P2] business-context-intake
  → business-context.md committed
  ↓
brainstorming (enhanced: NFR section, security section, MUST/SHOULD/MAY)
  ↓
spec-quality-gate (enhanced: validates NFR + security sections)
  ↓
[New P0] high-level-design
  → C4 diagrams + ADRs + technology selection + security arch + capacity plan
  ↓ [human reviews HLD]
using-git-worktrees → [auto-triggers New P0] ci-pipeline-setup
  → .github/workflows/ci.yml + deploy-staging.yml
  ↓
writing-plans (enhanced: dependency graph, [auto-triggers New P1] api-contract-first per endpoint)
  ↓
subagent-driven-development / executing-plans
  │
  ├── test-driven-development (unit tests, TDD)
  ├── [New P1] integration-testing (real dependencies, per component)
  ├── [New P0] observability-standards (logging + metrics, per endpoint)
  ├── code-documentation + commit-discipline
  └── [Enhanced P3] verification-before-completion (+ linter gate + coverage gate)
  ↓
requesting-code-review
  → pr-reviewer + security-reviewer + spec-impl-reviewer + test-quality-reviewer + language-expert-reviewer
  ↓
[New P2] load-testing (validates NFR targets)
  ↓
[New P2] e2e-testing (critical user journey)
  ↓
finishing-a-development-branch
  │
  └── [New P0] deployment-workflow
       → rollback procedure + smoke tests + release notes
  ↓
pr-creator → PR opened
```

---

## Quality / Speed / Results Balance

| New Skill | Quality Gain | Speed Cost | Result |
|-----------|-------------|------------|--------|
| `business-context-intake` | Build the right thing | 5–10 min | Eliminate wasted sprints |
| `high-level-design` | Architecture documented before code | 30–60 min | No mid-impl arch rework |
| `ci-pipeline-setup` | Automated merge gate | 0 min (template) | Faster, safer merges |
| `observability-standards` | Production incidents diagnosed in minutes | 10 min/service | Hours saved per incident |
| `deployment-workflow` | Zero-downtime deploys, tested rollbacks | 10 min/release | No 3am emergencies |
| `integration-testing` | Real dependency bugs caught in dev | +20% test time | −80% production surprises |
| `api-contract-first` | Parallel front/backend, no API drift | 15 min/endpoint | Faster parallel development |
| `load-testing` | NFRs verified, not aspirational | 15 min/milestone | No post-launch perf surprises |
| NFR + security in spec | Architecture grounded in constraints | 5 min/spec | No scale/security rewrites |
| Language linting gate | Code style eliminated from review | 0 min (automated) | Faster reviews |

**Net overhead per feature:** 90–120 minutes of structured conversation and template generation.  
**Net savings per feature:** Multiple rework cycles (days), security remediations (days to weeks), production incidents (hours each, recurring).  
**Payback:** Positive from the first feature. Scales with team size and project complexity.

---

## Final Verdict

**Corrected question:** Can this harness replace an entire engineering department and produce output **indistinguishable from what that department produces**? The previous framing — "indistinguishable from a senior engineer" — was wrong. A senior engineer produces code. A department produces PRDs, HLD docs, CI pipelines, runbooks, SLOs, release notes, architecture diagrams, API specs, deployment configs. The bar is the full artifact set, at the quality level of the role that owns each artifact.

**Current state (2026-05-29):** The Private AI Harness scores **4.4/10** under the corrected question (up from 4.0/10).

**What changed today:**
- Phase 2 (HLD): **2/10 → 7/10** — `high-level-design` skill produces a committed HLD with C4 diagrams, STRIDE threat model, technology selection, failure mode analysis, and ADRs. `hld-reviewer` agent validates 10 dimensions before human approval. This was the P0 gap and the most impactful single change.
- Review architecture: `spec-quality-reviewer` (gates Phase 1 output), `hld-reviewer` (gates Phase 2 output), `plan-reviewer` (gates plan before execution) — the skill→agent pattern now spans spec → design → plan → code. Context isolation at every gate.
- `language-expert-reviewer`, karpathy wiring, `code-documentation` checkpoint strengthened Phase 5/6 (scores unchanged, quality improved).

**What remains:** Phases 9 (Deployment) and 10 (Observability) are still 0/10. No deployment runbook, no observability setup, no CI pipeline artifact. These are the next P0 gaps. The harness now covers the design-through-implementation lifecycle well; it stops at PR creation.

**With remediations:** 8 new skills + 5 enhancements closes every gap below 9. The harness covers the complete engineering department workflow — from business context through production observability — at a quality level benchmarked against Linux, PostgreSQL, SQLite, seL4, Amazon, Google, Meta, Netflix, Stripe, and Microsoft.

**The single most important change:** `high-level-design`. Every other phase — testing, deployment, observability — is easier to do correctly when the architecture is documented and reviewed before code is written. Without HLD, the harness builds systems in the dark.

---

*Sources: Amazon Working Backwards (Amazon Press Library), Google SRE Book (Beyer et al., 2016), DORA State of DevOps 2025 (dora.dev), Meta Engineering Blog — Rapid Release at Massive Scale (engineering.fb.com), Microsoft Engineering Fundamentals Playbook (microsoft.github.io/code-with-engineering-playbook), Linux kernel Documentation/process (docs.kernel.org), Kubernetes Enhancement Proposals (github.com/kubernetes/enhancements), PostgreSQL CommitFest wiki (wiki.postgresql.org/wiki/CommitFest), seL4 Verification (sel4.systems/Verification), DO-178C standard (Ansys, Parasoft overviews), SQLite development history (sqlite.org), Spotify Testing Honeycomb (Spotify Engineering), OWASP ASVS (owasp.org), AWS Architecture Blog on ADRs (aws.amazon.com/blogs/architecture), C4 Model (c4model.com), RFC 8446 TLS 1.3 (IETF), PostgreSQL CommitFest CFbot (cfbot.cputube.org).*
