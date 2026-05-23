What's Missing — Additions to Build
High priority (directly from philosophy):

spec-quality-gate skill — validates spec before planning starts. Checks: every requirement is testable, no ambiguity, no "TBD", no undocumented behavior left implicit. Like a linter for specs.

requirement-tracer skill — maps requirements to tests and back. Flags: requirements with no test, tests with no traceable requirement, dead code paths with no requirement owner. The DO-178B traceability matrix.

dead-code-audit skill — wraps knip/depcheck/ts-prune into a harness step. Runs before merging, blocks merge if dead code found. Enforces "no dead code" from the philosophy.

spec-drift-detector skill — compares actual behavior (test output) against spec requirements. Flags when behavior exists but isn't in the spec. The "undocumented behavior = failure" enforcer.

