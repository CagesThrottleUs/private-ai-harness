---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors AND type checker: 0 errors | Partial check, extrapolation, "I didn't add any new code so linter is fine" |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Language Linter Gate

**Required before every commit that creates or modifies source code files.**

Detect the project's language from manifest files, run the correct tool in check mode (never auto-fix — just fail if changes needed), and run the type checker. Zero issues required.

**References:**
- Ruff replaces black + isort + flake8 for Python (2024/2025 standard — same speed advantage, single tool)
- Biome replaces ESLint + Prettier for TypeScript/JS (2025, Rust-based, ~35× faster)
- golangci-lint is the Go standard; gofmt is mandatory
- clippy + rustfmt are the Rust standard

### Detection and Command Table

| Manifest found | Language | Format check | Lint check | Type check |
|---------------|---------|-------------|-----------|-----------|
| `pyproject.toml` / `setup.py` | Python | `ruff format --check .` | `ruff check .` | `mypy . --ignore-missing-imports` |
| `package.json` with `biome.json` | TypeScript/JS (Biome) | `npx biome format --diagnostic-level error .` | `npx biome lint --diagnostic-level error .` | `npx tsc --noEmit` |
| `package.json` without `biome.json` | TypeScript/JS (ESLint) | `npx prettier --check .` | `npx eslint .` | `npx tsc --noEmit` |
| `go.mod` | Go | `gofmt -l . \| grep . && exit 1 \|\| true` | `golangci-lint run ./...` | *(included in golangci-lint)* |
| `Cargo.toml` | Rust | `cargo fmt --check` | `cargo clippy -- -D warnings` | *(included in clippy)* |
| `pom.xml` | Java | `mvn checkstyle:check -q` | `mvn spotbugs:check -q` | `mvn compile -q` |
| `build.gradle` | Java (Gradle) | `./gradlew checkstyleMain -q` | `./gradlew spotbugsMain -q` | `./gradlew compileJava -q` |
| `Gemfile` | Ruby | `bundle exec rubocop --format quiet` | *(rubocop covers both)* | *(N/A)* |

**Run all three columns where applicable. Any non-zero exit = do not commit.**

### Failure handling

If the linter produces output:
1. Show the exact output
2. Fix the violations (do NOT add ignore comments or suppressions to pass)
3. Re-run to confirm clean
4. Only then: proceed to commit

**Never add `# noqa`, `// eslint-disable`, or `#[allow(clippy::...)]` to silence linter output unless the finding is a confirmed false positive with a documented reason.**

### Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review
- Pattern check before re-dispatch: does this finding's pattern recur elsewhere in the artifact? Fix every occurrence in the same pass — a finding that resurfaces next cycle in a new spot is the cost this discipline exists to cut

### Self-review: Run `linter-reviewer` agent

After running the linter gate manually, before committing, dispatch the agent to validate:

```
Agent(linter-reviewer, {
  PROJECT_ROOT: ".",
  CHANGED_FILES: "$(git diff --name-only HEAD)"
})
```

---

## Test-Strength Gate (mutation score, not just coverage)

**Required when this change added or modified tests.** Line coverage is
gameable — a test that runs a function and asserts nothing scores 100%
coverage. Mutation score (killed ÷ non-equivalent mutants) is not gameable, so
it is the real signal that the tests would catch a regression.

| Language | Tool | Gate |
|---|---|---|
| JS / TS | Stryker | break < 50%, aim 60–80% |
| Java | PIT | `mutationThreshold` ~60 |
| Python | mutmut | survivors reviewed, gap closed |

- Coverage is a **floor** (don't ship untested code); mutation score is the
  strength check on top of it.
- **AI-generated tests especially:** 80%+ coverage with **< 50–60% mutation
  score means the assertions are tautological** — the suite executes the code
  without checking it. Feed surviving mutants back as the next assertions to add;
  do not accept a green-but-tautological suite.

## Structural Quality Measure (ISO/IEC 5055 / CISQ)

**For source changes**, quality must be *measured*, not only eyeballed. ISO/IEC
5055 (CISQ) defines automated source-code measures for four characteristics —
Reliability, Security, Performance Efficiency, Maintainability — as sets of CWE
structural weaknesses. Run a CWE-oriented static scan (e.g., the SAST/SCA tools
already configured in `ci-pipeline-setup`) and a maintainability check:
- No new Critical/High CWE structural weaknesses introduced by the change.
- Maintainability not materially worsened (function length, nesting, duplication
  — the same signals `pr-reviewer` Dimension 1 flags, here as a measured floor).

---

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness
