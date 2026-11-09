# Harness catalogue

Every skill and subagent in this harness, grouped by the job it does. Browse it
yourself, or let `/engineer` pick from it. Nothing here runs on its own: a tool
runs because you asked for it or because it fits the request. When a tool says
it works best after another, that is advice: it explains what the earlier tool
would catch and asks whether to run it first.

- **Skill**: instructions the main agent follows in your session.
- **Subagent**: a reviewer with its own context. It takes explicit inputs and
  returns a verdict plus findings. Dispatch it as `private-ai-harness:<name>`
  on Claude Code, or `private-ai-harness-<name>` on Codex, opencode, and Copilot.

Jobs: [Understand](#understand) · [Learn](#learn) · [Define](#define) ·
[Design](#design) · [Build](#build) · [Test](#test) · [Review](#review) ·
[Ship and operate](#ship-and-operate) · [Measure](#measure) · [Meta](#meta) ·
[Subagents](#subagents) · [Scripts and references](#scripts-and-references) ·
[Where tools write](#where-tools-write)

## Skills

### Understand

What is true today, before anything changes.

| Tool | Use when | You get |
|---|---|---|
| `codebase-comprehension` | You are about to change code you don't know well | The relevant symbols, callers, data flow, and dependencies, cited `file:line` |
| `systematic-debugging` | A bug, failing test, or surprising behavior | A reproduced, evidenced root cause before any fix |
| `research-spike` | Feasibility, an A-vs-B comparison, or a POC where the answer is the deliverable | Time-boxed findings or an ADR; spike code is thrown away |

### Learn

| Tool | Use when | You get |
|---|---|---|
| `teacher` | You want to check or deepen your own understanding of code or a concept | A cited actual-vs-ideal dossier, Socratic questions (never the answer), transfer exercises, a spaced re-quiz log |

### Define

What to build and why.

| Tool | Use when | You get |
|---|---|---|
| `business-context-intake` | The user problem, success metric, compliance, and non-goals aren't written down | A business-context doc: JTBD, measurable metrics, non-goals, stakeholders |
| `brainstorming` | An idea is still fuzzy | Intent played back, approaches compared, then a design doc or REQ-format spec |
| `spec-quality-gate` | A spec exists and should be checked before design or code | A free mechanical pre-lint, then a `spec-quality-reviewer` verdict |
| `epic-decomposition` | A large, designed initiative needs splitting into stories | Child work items in dependency waves (parallel vs sequential) |
| `portfolio-management` | Several initiatives compete for limited capacity | A WSJF-ranked Kanban with WIP limits, a dependency DAG, OKR links |

### Design

| Tool | Use when | You get |
|---|---|---|
| `high-level-design` | A new service, data model, external integration, or security boundary | An HLD: C4 diagrams, STRIDE threat model, failure modes, capacity, ADRs |
| `database-erd` | The schema changes | A Mermaid ERD with keys, cardinality, and an index strategy |
| `sequence-diagram` | A flow crosses three or more components | A Mermaid sequence diagram with the auth boundary, error paths, sync vs async |
| `api-contract-first` | A new HTTP or gRPC surface, before handler code | OpenAPI 3.1 or `.proto`, Spectral lint, a Prism mock |
| `api-versioning` | An API with external consumers | A versioning ADR, breaking-change policy, Sunset-header deprecation, `oasdiff` in CI |
| `service-scaffolding` | Starting a brand-new service | A paved-road scaffold: CI, observability, contract stub, tests, runbook, catalog entry |
| `infrastructure-as-code` | The change needs new infrastructure | Terraform or Pulumi with pinned versions, locked remote state, environment split, tfsec |
| `feature-flags` | A gradual rollout, A/B test, kill switch, or permission gate | OpenFeature setup, a flag registry, CI flag hygiene |
| `design-principles` | Decomposing, planning, or reviewing structure | DRY, KISS, YAGNI, SOLID, and GoF applied as a lens |
| `karpathy` | Keeping AI-written changes small and checkable | Anti-LLM-pitfall rules: no speculation, surgical diffs, verifiable success |
| `emil-design-eng` | UI polish, component, and animation decisions | Design-engineering judgment on the details that make a UI feel right |
| `android-advisor` | Android, Kotlin, Compose, or KMP work | Which installed Android skill wins for each sub-task, and in what order |
| `domain-overlay` | Several installed skills overlap in one technology domain | The pattern for writing a `<domain>-advisor` like `android-advisor` |

### Build

| Tool | Use when | You get |
|---|---|---|
| `writing-plans` | You have a spec and the work has several steps | An executable plan: exact files, signatures, verification per task |
| `executing-plans` | Running a plan in this session with checkpoints | Tasks done in order, verified as you go |
| `subagent-driven-development` | Running a plan with a fresh subagent per task | Implemented, reviewed tasks with a progress ledger |
| `dispatching-parallel-agents` | Two or more independent tasks | Concurrent subagents with clean hand-offs |
| `using-git-worktrees` | Isolated work without stashing | A worktree on a new branch with a clean test baseline |
| `test-driven-development` | Implementing any feature or fix | Red, green, refactor: each test seen failing before the code |
| `refactoring` | Code works but has the wrong shape | Behavior-preserving moves, one per micro-commit, tests green after each |
| `code-documentation` | Writing or changing a public construct | Full docs with requirement traceability |
| `formal-verification` | A critical core (crypto, auth, money, consensus, `unsafe`) in a language with a verifier | A machine-checked proof against the live toolchain |

### Test

| Tool | Use when | You get |
|---|---|---|
| `property-based-testing` | A function has a checkable invariant (round-trip, idempotence, an algebraic law) | Generated property and fuzz tests instead of hand-picked examples |
| `integration-testing` | A component talks to a database, queue, cache, or another service | Testcontainers tests with real dependencies; contract tests |
| `e2e-testing` | User-facing journeys | Playwright tests with page objects and semantic locators |
| `visual-regression` | A UI with visual design intent | Screenshot baselines with animations off and dynamic content masked |
| `load-testing` | The spec has numeric performance targets | k6 scripts with thresholds tied to those targets |
| `chaos-engineering` | Resilience requirements (retries, circuit breakers, degradation) | Fault-injection experiments with a steady state and abort criteria |
| `deterministic-simulation-testing` | Concurrent or distributed components | Seeded, replayable fault simulation |
| `dast-testing` | An externally reachable service | ZAP and Nuclei scans in CI that fail on high findings |

### Review

| Tool | Use when | You get |
|---|---|---|
| `review` | Any review; `/review auto` picks reviewers and scopes for a codebase or diff | The right subagents dispatched with exact inputs |
| `requesting-code-review` | You want your change reviewed | Review agents routed by what changed |
| `giving-code-review` | Reviewing a PR, someone else's or your own | A commit-by-commit review with claims checked |
| `receiving-code-review` | Acting on review feedback | Verified fixes, with every sibling occurrence fixed too |
| `closing-review-loops` | Fixes are done and you are about to re-trigger a reviewer | All findings batched, self-reviewed, pushed once |
| `pr-review-non-negotiables` | A checklist any review applies | Backward compatibility, migration, performance, reuse, tests, security, and more |
| `verification-before-completion` | Before saying done, committing, or opening a PR | Evidence: tests run, linter clean |

### Ship and operate

| Tool | Use when | You get |
|---|---|---|
| `commit-discipline` | Writing a commit message | A Conventional Commit with a WHY body |
| `pr-creator` | Opening a pull request | A drafted and opened PR |
| `finishing-a-development-branch` | Work on a branch is done | Docs check, tests, review, then merge, PR, keep, or discard |
| `github-workflows` | GitHub Actions or PR automation | Workflow patterns |
| `ci-pipeline-setup` | A project or branch has no CI | A pipeline spec and config for the detected platform |
| `deployment-workflow` | Preparing a change for production | Strategy, migration checklist, rollback, smoke tests, runbook, release notes |
| `observability-standards` | A new endpoint or service | OTel logging, golden-signal metrics, SLOs, alerts, runbooks |
| `incident-response` | A production service needs an incident process | A severity matrix, incident commander role, postmortem template |
| `production-readiness-review` | Before first production traffic | An evidence-checked go/no-go across seven SRE dimensions |
| `onboarding-guide` | After a first release or a major design change | `wiki/ONBOARDING.md`, built from the HLD, ADRs, API, and SLOs |

### Measure

| Tool | Use when | You get |
|---|---|---|
| `delivery-metrics` | How fast and how reliably we ship | DORA keys and flow efficiency, withheld when the data is missing |
| `outcome-review` | After a feature ships | The business north-star measured against target: persevere, iterate, or kill |

### Meta

| Tool | Use when | You get |
|---|---|---|
| `engineer` | Browsing this catalogue or picking tools for a request | This catalogue, and a one-line reason for each pick |
| `using-superpowers` | Finding and invoking skills on Claude Code, Codex, Copilot, or Gemini | How skills load and which tool names map on each host |
| `writing-skills` | Creating or editing a skill | A skill tested against the failure it exists to prevent |
| `caveman` | You want terse, low-token replies | A compressed output mode |

## Subagents

**Needs** lists the required inputs; optional ones are in `agents/<name>.md`.
Every subagent also accepts `REPORT_FILE`, which writes the full findings to a
file and returns only the verdict.

### Define and plan

| Subagent | Checks | Needs | Model |
|---|---|---|---|
| `business-context-reviewer` | The problem is user-framed, JTBD complete, metrics measurable, non-goals and stakeholders present | `CONTEXT_PATH` | opus |
| `spec-quality-reviewer` | Requirements are falsifiable, each maps to an honest test, no requirement smells | `SPEC_PATH` | opus |
| `test-scenario-reviewer` | Before tests or code: every requirement covered, each test names the wrong implementation it catches, right test level | `SCENARIOS_PATH`, `SPEC_PATH` | opus |
| `plan-reviewer` | The plan covers the spec, tasks are right-sized, no placeholders, interfaces consistent | `PLAN_PATH`, `SPEC_PATH` | opus |
| `portfolio-reviewer` | WSJF computed rather than guessed, WIP limits respected, dependencies acyclic, OKRs linked | `PORTFOLIO_PATH` | opus |

### Design

| Subagent | Checks | Needs | Model |
|---|---|---|---|
| `hld-reviewer` | C4, threat model, failure modes, capacity, ADRs, spec coverage | `HLD_PATH`, `SPEC_PATH` | opus |
| `sequence-diagram-reviewer` | Critical flows, an error path per external call, sync vs async, the auth boundary | `DIAGRAM_PATH` | opus |
| `database-erd-reviewer` | Keys, valid foreign keys, cardinality, no money as float, an index strategy | `ERD_PATH` | sonnet |
| `api-contract-reviewer` | Contract completeness, error taxonomy, security, breaking changes | `SPEC_PATH`, `PROTOCOL` | opus |
| `api-versioning-reviewer` | Versioning ADR, breaking-change policy, Sunset headers, migration guide, CI check | `ADR_PATH`, `POLICY_PATH` | opus |
| `iac-reviewer` | Pinned providers, locked remote state, sensitive variables, environment split, security scan | `IAC_DIR`, `TOOL` | sonnet |
| `feature-flag-reviewer` | Flag naming, owner and expiry, CI hygiene, no hard-coded `true` | `REGISTRY_PATH` | sonnet |
| `service-scaffolding-reviewer` | Every paved-road component present, resource limits set | `SCAFFOLD_DIR` | sonnet |

### Code

| Subagent | Checks | Needs | Model |
|---|---|---|---|
| `pr-reviewer` | A diff across six dimensions, including AI-authored-code risk, plus spec traceability | `DESCRIPTION`, `BASE_SHA`, `HEAD_SHA`, `REQUIREMENTS` | opus |
| `security-reviewer` | A threat model of the change, auth chains, crypto, injection, secrets | `DESCRIPTION`, `BASE_SHA`, `HEAD_SHA` | opus |
| `spec-impl-reviewer` | The implementation actually satisfies each acceptance criterion | `SPEC_PATH`, `BASE_SHA`, `HEAD_SHA` | opus |
| `test-quality-reviewer` | The tests would catch real bugs, not just exist | `SPEC_PATH`, `BASE_SHA`, `HEAD_SHA` | opus |
| `language-expert-reviewer` | Behavior, invariants, and language fit, judged by a veteran of that language | `LANGUAGE`, `STANDARD`, `SCOPE` (+ SHAs for a diff) | opus |
| `full-project-reviewer` | A whole-codebase audit: quality, docs, security, reliability, performance | none (whole repo) | opus |
| `formal-verification-reviewer` | The proof discharges on the live verifier and proves the right spec | `VERDICT_PATH`, `SOURCE_PATH` | opus |
| `linter-reviewer` | The right linter and type checker ran, zero output, no new suppressions | `PROJECT_ROOT`, `CHANGED_FILES` | sonnet |

### Test

| Subagent | Checks | Needs | Model |
|---|---|---|---|
| `integration-test-reviewer` | Real dependencies at the boundary, isolation, factories, contract tests | `TEST_FILES` | opus |
| `e2e-reviewer` | Critical journeys, semantic selectors, no fixed waits, independent tests | `TEST_FILES` | opus |
| `accessibility-reviewer` | axe checks on critical pages with the right WCAG tags; violations fail CI | `TEST_FILES` | sonnet |
| `visual-regression-reviewer` | Screenshots on critical pages, animations off, baselines committed, pinned CI image | `TEST_FILES`, `SNAPSHOT_DIR` | sonnet |
| `load-test-reviewer` | Thresholds tied to the spec's targets, a smoke test, realistic traffic, a staging target | `SCRIPT_PATH` | opus |
| `chaos-reviewer` | Steady state, hypothesis, abort criteria, degradation thresholds, seed reproducibility | `TEST_FILES` | sonnet |
| `dast-reviewer` | ZAP on PRs, an API scan on staging, high findings fail CI, SARIF uploaded | `CI_CONFIG_PATH` | sonnet |

### Ship and operate

| Subagent | Checks | Needs | Model |
|---|---|---|---|
| `ci-reviewer` | Stage order, security hygiene, supply chain, coverage and mutation gates | `CI_CONFIG_PATH`, `PROJECT_ROOT` | opus |
| `deployment-reviewer` | Tested rollback, migration safety, smoke tests, runbook, release notes | `ROLLBACK_PATH`, `SMOKE_TEST_PATH` | opus |
| `observability-reviewer` | Logging fields, golden signals, SLO quality, burn-rate alerts, runbooks | `SLO_PATH`, `ALERTS_PATH` | opus |
| `incident-response-reviewer` | Severity matrix with SLAs, incident commander, postmortem sections, action-item closure | `PROCESS_PATH`, `POSTMORTEM_PATH` | sonnet |
| `production-readiness-reviewer` | Every readiness claim carries real evidence, across seven SRE dimensions | `PRR_PATH` | opus |
| `onboarding-reviewer` | A new engineer could be productive within a day from the guide | `ONBOARDING_PATH` | opus |

### Measure

| Subagent | Checks | Needs | Model |
|---|---|---|---|
| `delivery-metrics-reviewer` | DORA bands correct, no fabricated keys, every key sourced | `REPORT_PATH` | sonnet |
| `outcome-review-reviewer` | Every promised metric measured from a re-runnable source; the decision follows the evidence | `OUTCOME_PATH`, `CONTEXT_PATH` | opus |

## Scripts and references

- `engineer/scripts/catalogue-check`: fails when this catalogue and the skills
  or agents on disk disagree.
- `engineer/scripts/cost-checkpoint` with `engineer/references/cost-ledger.md`:
  an optional per-step token ledger (Claude Code and Codex), read by
  `delivery-metrics`.
- `engineer/references/review-discipline.md`: acting on review findings: fix
  the pattern everywhere, batch rounds, keep fixes proportionate.
- `subagent-driven-development/scripts/`: `task-brief`, `review-package`,
  `sdd-workspace`, and `sdd-repo` for file-based hand-offs.
- `spec-quality-gate/scripts/pre-lint.sh`: the free mechanical spec check.

## Where tools write

`wiki/` holds living product docs, updated in the same commit as the behavior.
`.ai/` holds working artifacts: an audit trail, not the source of truth.

Each piece of work gets one root, `.ai/YYYY-MM-DD-<feature-slug>/`, with a
subfolder per artifact type. File names inside drop the date and follow
`<artifact-type>-<feature-slug>[-suffix].md`. Two exceptions sit outside any
one work item: `.ai/portfolio/` spans many epics, and `.ai/teacher/` checks
understanding rather than delivering work.

| Artifact | Location | Notes |
|---|---|---|
| Onboarding guide | `wiki/ONBOARDING.md` | Written by `onboarding-guide` |
| API reference | `wiki/api/` | Must match the code |
| ADRs | `wiki/architecture/` | Immutable once merged |
| Guides and runbooks | `wiki/guides/` | How-tos and operational procedures |
| Changelog and release notes | `wiki/changelog/` | One file per release |
| Comprehension map | `.ai/<id>/comprehension.md` | One file at the work-item root |
| Business context | `.ai/<id>/business-context/` | Read by `brainstorming` when present |
| Specs | `.ai/<id>/specs/` | REQ-format |
| HLD | `.ai/<id>/hld/` | |
| ERD and sequence diagrams | `.ai/<id>/lld/` | `-schema.md`, `-sequences.md` |
| CI pipeline spec | `.ai/<id>/ci/` | Committed alongside the CI config |
| SLOs | `.ai/<id>/observability/` | Tied to the spec's NFRs |
| API contract | `api/openapi.yaml`, `proto/<pkg>/v1/<service>.proto` | Written before handler code |
| Performance baseline | `.ai/<id>/performance/` | k6 results against targets |
| Deployment artifacts | `.ai/<id>/deployment/` | Rollback, smoke tests, runbook, migration checklist |
| Plans | `.ai/<id>/plans/` | |
| Review and gate reports | `.ai/<id>/reports/` | One per run |
| Requirement traceability | `.ai/<id>/requirements/` | REQ → TC mapping |
| SDD scratch | `.ai/<id>/sdd/` | Self-ignoring; run state for `subagent-driven-development` |
| Brainstorm server files | `.ai/brainstorm/` | Self-ignoring; shared server workspace |
| Portfolio Kanban | `.ai/portfolio/` | Spans many epics |
| Teacher sessions | `.ai/teacher/<date>-<topic>/` | Dossier, session log, grading |
