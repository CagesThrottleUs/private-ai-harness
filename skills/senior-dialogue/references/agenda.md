# Agenda — what each topic must settle

Read a topic's section right before you discuss it. Each topic ends in one or
more decision cards; artifacts are written in BUILD, from the agreed cards, by
the existing skill named under **Produces**. Never run that skill's own human
approval ask — the agreed cards already satisfy it.

---

## a. Problem statement + current-state validation

**Goal:** agree on what is true today, proven step by step, before discussing
what should change.

**Settle:** the problem in one sentence; how the relevant code path actually
works now (entry point → data flow → exit); what is broken or missing, and how
we know; what has been tried.

**Evidence:** `codebase-comprehension` output with `file:line` citations;
reproduction steps and observed output for defects; current metrics if they
exist. Walk the reasoning as a numbered chain — each step cites the line that
proves it. Separate *observed* from *inferred*.

**Numbers:** frequency and impact of the problem (how often, how many users,
how much time or money lost) — mark estimates as estimates.

**Produces:** `.ai/<id>/comprehension.md` (task/epic) or the D-000 body
(quick-fix/refactoring).

**Exit:** the human agrees the problem and current state as stated, or
corrects them.

---

## b. Business context + engineering requirements and scope

**Goal:** targets the human owns, never targets the model agreed with itself.

**Settle:** who the user is and the job they are hiring this for (JTBD); why
now; one north-star metric with baseline and target, plus the input metrics
that drive it; explicit non-goals (`business-context-intake` explains why
these matter and what makes them good); compliance (PII/PCI/HIPAA/SOC 2 — explicit
yes or no); stakeholders; NFRs (latency, availability, throughput) as numbers.
**Future scenarios:** enough "in a year…" scenarios to cover the forces that
could break the design (growth, new consumers, regulation, failure), each with
a reasoned likelihood and what the design must not preclude.

**Evidence:** what the human tells you; analytics or support data they point
to; comparable products. Use `business-context-intake`'s Q1–Q8 as territory,
one question per message.

**Numbers:** baseline → target with a date; the cost of not doing it (cost of
delay) when the human can estimate it.

**Produces:** business-context doc (`business-context-intake` template) and
the REQ-format spec (`brainstorming` → `references/requirement-format.md`),
then `spec-quality-gate` runs autonomously.

**Exit:** every target, non-goal and scenario is on a card the human agreed.
Anything you proposed is labeled as your proposal until agreed.

---

## c. High-level design

**Goal:** a shape that survives the failures this class of system is known for.

**Settle:** components and what each one hides (Parnas); sync vs async;
datastores; trust boundaries; key trade-offs (ATAM sensitivity and trade-off
points); which decisions are one-way doors (each gets its own card and ADR).

**Evidence — industry lessons:** back each major risk with a relevant
postmortem or practitioner source, for example: Google SRE book and workbook; AWS Builders'
Library; public postmortem collections (e.g. github.com/danluu/post-mortems);
vendor incident reports (Cloudflare, GitHub, AWS PES). Cite the specific
incident and the lesson that transfers.

**Failure scenarios:** per component, failure mode → user impact → probability
(per year or per request) → mitigation → recovery target. Rank by
probability × impact.

**Capacity:** pessimistic / expected / optimistic load from the NFRs; Little's
Law (`concurrency = arrival rate × latency`); headroom and scaling triggers,
with the reasoning for where they sit.

**Threat model:** Shostack's four questions plus STRIDE per component; data
classification.

**Produces:** HLD and ADRs via `high-level-design` (template in its
`references/`), `database-erd` and `sequence-diagram` where applicable.

**Exit:** each one-way door agreed alone with teach-back; the rest agreed or
batched.

---

## d. Low-level design

**Goal:** everything an implementer and every consumer needs, decided once.

**Settle:** public interfaces (exact signatures and types); data structures and
their invariants; the error model (error taxonomy, which errors are retryable,
idempotency keys, timeouts, partial-failure behavior, what the caller sees);
concurrency model; resource ownership and lifetimes; configuration surface;
backward compatibility and versioning.

**Consumer documentation checklist** (each item is decided, not left to the
docs writer): purpose; quick-start example; every input with type, range,
default; every output; every error with cause and caller action; limits and
quotas; performance expectations; thread-safety / reentrancy; versioning and
deprecation policy; security considerations.

**Evidence:** existing conventions in the codebase (`file:line`); official docs
for libraries used (Context7, version-matched).

**Numbers:** per-call latency budget, memory per object, payload size limits.

**Produces:** `.ai/<id>/lld/lld-<slug>.md`; `api-contract-first` for HTTP/gRPC
surfaces; `api-versioning` for external APIs.

**Exit:** a consumer could integrate from the LLD alone.

---

## e. CI/CD — gold standard for this slice

**Goal:** the pipeline catches what the test matrix (h) promises, fast.

**Settle:** stage order (fail fast: format/lint/type → unit → integration →
build → e2e/perf on staging); which test level tags from (h) run on every PR vs
nightly; coverage and mutation gates; supply chain (pinned actions and
dependencies, SBOM, provenance — SLSA); secrets handling (OIDC over long-lived
secrets); required checks and branch protection.

**Evidence:** current pipeline files (`file:line`); SLSA (slsa.dev); DORA
(dora.dev).

**Numbers:** PR pipeline wall-clock budget and flake budget, derived from the
team's current pipeline timings and merge frequency (cite them).

**Produces:** `ci-pipeline-setup` (and `github-workflows` for GitHub Actions).

**Exit:** agreed or batched as "existing pipeline already meets it" with the
evidence.

---

## f. Deployment + releases

**Settle:** strategy (rolling / blue-green / canary with step sizes and bake
times); database migration plan (expand → migrate → contract); rollback trigger
and target time; feature flags; release versioning and changelog; who is
notified.

**Numbers:** canary step sizes and bake time from traffic volume (enough
requests per step to detect the error-rate change you care about); rollback
time objective.

**Produces:** `deployment-workflow` (+ `feature-flags`).

---

## g. Observability + operations

**Settle:** SLIs and SLO targets; error budget; alert policy (symptom-based,
multi-window burn rate); dashboards; runbook per alert; on-call ownership.

**Numbers:** derive the error budget from the agreed SLO and window, and
burn-rate alert thresholds from that budget. The SRE workbook's alerting
chapter is a good source to cite for the method.

**Produces:** `observability-standards` (+ `incident-response` for new
services).

---

## h. Test scenarios — before any code

Follow `test-scenarios.md`. Exit: reviewer PASS and the matrix card agreed,
or cap N reached and the human chose accept-with-gaps or a larger N.

---

## i. Test-first construction approach

**Settle:** the language- and stack-level hazards the tests and code must
respect, decided before construction: memory and lifetime model, undefined
behavior exposure, ABI stability, concurrency primitives, sanitizer and fuzzing
plan (C/C++); rendering strategy, performance budgets, accessibility, browser
matrix (web frontend). Depth: `systems-depth.md`.

**Produces:** constraints recorded in the LLD and plan Global Constraints.

---

## j. Build

Only after `check` exits 0. See SKILL.md Step 6.
