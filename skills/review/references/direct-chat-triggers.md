# Direct Chat Triggers

Moved verbatim from `SKILL.md` (private-ai-harness 5.0.0) to keep the skill
under the 20,000-byte limit Claude Code applies when it re-attaches skills
after compaction. Read it at the step that points here.

| Phrase | Routes to |
|--------|-----------|
| "review my PR" / "review this PR" | `/review pr` |
| "does this satisfy the spec" / "check spec" | `/review spec` |
| "check my tests" / "test quality" | `/review tests` |
| "security review" / "check for vulnerabilities" | `/review security` |
| "full review" / "audit the codebase" | `/review full` |
| "review everything" / "full suite" | `/review all` |
| "review auto" / "choose reviewers for this codebase" / "review my codebase and pick agents" | `/review auto` |
| "language review" / "C++ review" / "Rust review" / "expert review" / "check idioms" | `/review lang` |
| "review my pipeline" / "check CI config" / "review CI" / "check my ci" | `/review ci` |
| "review the HLD" / "check the design doc" / "review architecture doc" / "validate HLD" | `/review hld` |
| "review observability" / "check SLOs" / "review runbooks" / "check alerts" | `/review observability` |
| "review deployment" / "check rollback" / "review my deploy plan" / "check migration safety" | `/review deployment` |
| "review integration tests" / "check my integration tests" / "are my tests mocking the DB" | `/review integration` |
| "review my API spec" / "check the openapi" / "review the contract" / "check my proto" | `/review api` |
| "review e2e tests" / "check my playwright tests" / "review my E2E" | `/review e2e` |
| "review feature flags" / "check flag registry" / "review flags" | `/review flags` |
| "review terraform" / "check IaC" / "review infrastructure code" / "check infra" | `/review iac` |
| "review the ERD" / "check the schema" / "review database design" | `/review schema` |
| "review visual regression" / "check screenshot tests" / "review VRT" | `/review visual` |
| "review chaos tests" / "check chaos engineering" / "review resilience tests" | `/review chaos` |
| "review incident response" / "check postmortem template" / "review IR process" | `/review incident` |
| "review the onboarding guide" / "check ONBOARDING.md" | `/review onboarding` |
| "review DAST" / "check ZAP config" / "review security scan" | `/review dast` |
| "review accessibility tests" / "check WCAG" / "check a11y" | `/review accessibility` |
| "review my API versioning" / "check the versioning strategy" / "review breaking changes" | `/review versioning` |
| "review my sequence diagrams" / "check the sequence diagram" | `/review sequence` |
| "review load tests" / "check my k6 script" / "review performance tests" | `/review performance` |
