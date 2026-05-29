---
name: ci-pipeline-setup
description: >
  Use when starting work on a new branch or project — before any code is written. Detects the CI platform in use (GitHub Actions, GitLab CI, Jenkins, CircleCI, Azure DevOps, Bitbucket Pipelines) and generates two artifacts: a platform-agnostic pipeline specification document and the platform-specific configuration file. Runs ci-reviewer agent to validate before committing. The pipeline exists from day one, not as a pre-merge afterthought.
---

# CI Pipeline Setup

Generate a CI/CD pipeline that gates every merge — before any feature code exists. A pipeline retrofitted at PR time is not a pipeline; it is documentation.

## References

- **CRAFTS principles** (Kay Ren Fa, medium.com/@kay.renfa) — **C**onsistent, **R**eliable, **A**rtifact-first, **F**ast, **T**rustworthy, **S**ecure
- **DORA metrics** (dora.dev) — elite: deployment frequency multiple/day, lead time < 1 day, change failure rate < 4%, MTTR < 1 hour
- **Microsoft Engineering Fundamentals Playbook** (microsoft.github.io/code-with-engineering-playbook) — CI/CD mandatory on every project; main branch always shippable
- **Google Cloud: Four Keys** (cloud.google.com/blog/products/devops-sre/using-the-four-keys) — speed and stability are NOT tradeoffs
- **Semaphore: Pipelines Explained** (semaphore.io/blog/pipelines-explained-principles-ci-cd) — DAG structure, fail-fast, parallelism, idempotency

---

## When to Use

**Required when:**
- Starting any new branch via `using-git-worktrees`
- No CI configuration exists in the repository yet
- Existing CI configuration is missing required stages (lint, coverage gate, security scan)

**Skip if:** a comprehensive CI pipeline already exists and passes `ci-reviewer` with no Critical findings.

**Infer + confirm:**
> "There's already a `.github/workflows/ci.yml` that runs lint, tests, and deploys to staging. Skipping ci-pipeline-setup. Should I run `ci-reviewer` on the existing config instead?"

---

## Inputs Required

- **Project root** — read manifest files to detect language and package manager
- **CI platform** — detect from existing config files or ask once

---

## Platform Detection

Check for existing CI config before asking:

| File exists | Platform |
|-------------|---------|
| `.github/workflows/` | GitHub Actions |
| `.gitlab-ci.yml` | GitLab CI |
| `Jenkinsfile` | Jenkins |
| `.circleci/config.yml` | CircleCI |
| `azure-pipelines.yml` | Azure DevOps |
| `bitbucket-pipelines.yml` | Bitbucket Pipelines |
| None found | Ask user once |

---

## Process

1. **Detect platform and project type** — read manifest files (`pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `Gemfile`)
2. **Identify what already exists** — do not regenerate stages that are already correct
3. **Write pipeline spec** — technology-agnostic design document first
4. **Generate platform config** — implement the spec for the detected platform
5. **Generate dependency scanning config** — Dependabot / Renovate / platform equivalent
6. **Generate branch protection guidance** — what rules to set in the platform UI
7. **Run `ci-reviewer` agent** — fix all Critical and Important findings
8. **Commit** — pipeline config committed to branch; CI begins guarding from first push

---

## The Universal Pipeline

Every pipeline is a DAG. Stages run in this order regardless of platform. **Fail fast: cheapest, fastest checks first.**

```
[Checkout]
    │
    ├── [Lint & Format Check]  ← fastest (seconds); fails on style errors
    ├── [Type Check]           ← fast static analysis (seconds–minutes)
    │
    ▼ (all fast checks pass)
    │
    ├── [Unit Tests + Coverage Gate]  ← coverage < 80% = pipeline failure
    │
    ▼ (unit tests pass)
    │
    ├── [Integration Tests]     ← real dependencies (if present)
    ├── [Security Scan]         ← SAST + SCA (dependency vulnerabilities)
    │
    ▼ (quality gates pass)
    │
    ├── [Build Artifact]        ← build ONCE; deploy the same artifact everywhere
    │
    ▼ (on merge to main only)
    │
    ├── [Deploy to Staging]     ← automated; no human gate
    ├── [Health Check]          ← verify staging responds within 60s
    ├── [Smoke Tests]           ← critical user paths
    │
    ▼ (staging verified)
    │
    └── [Deploy to Production]  ← human gate or canary; rollback if health check fails
```

**CRAFTS check per stage:**
- **Consistent:** same commands locally and in CI — no "works on my machine"
- **Reliable:** every stage fails loudly; no `|| true` swallowing failures
- **Artifact-first:** build artifact produced in one job, referenced by deploy jobs — never rebuilt
- **Fast:** parallel-safe stages run concurrently; target < 10 min total for PR checks
- **Trustworthy:** no secrets in config; OIDC over long-lived credentials where platform supports it
- **Secure:** security scan runs on every PR; dependency scan on schedule

---

## Pipeline Spec Document Format

Save to: `.ai/ci/YYYY-MM-DD-pipeline-spec.md`

````markdown
# CI/CD Pipeline Specification

**Platform:** [GitHub Actions | GitLab CI | Jenkins | CircleCI | Azure DevOps | Bitbucket]
**Date:** YYYY-MM-DD
**Language/Runtime:** [detected from manifest]
**DORA target:** Deployment Frequency: on-merge | Lead Time: < 1 day | CFR: < 4% | MTTR: < 1 hr

---

## Stages

| Stage | Trigger | Parallel-safe? | Failure behavior | Target time |
|-------|---------|---------------|-----------------|-------------|
| Lint + Format | every push | yes | block merge | < 1 min |
| Type Check | every push | yes | block merge | < 2 min |
| Unit Tests + Coverage | every push | yes | block merge (< 80% line) | < 5 min |
| Integration Tests | every push | no (needs unit pass) | block merge | < 10 min |
| Security Scan (SAST) | every push | yes | block merge on Critical | < 5 min |
| Dependency Scan (SCA) | scheduled + every push | yes | block merge on Critical CVE | < 3 min |
| Build Artifact | merge to main | no (needs all tests) | block deploy | < 5 min |
| Deploy Staging | merge to main | no (needs build) | block prod deploy | < 5 min |
| Health Check | after staging deploy | no | rollback staging | < 1 min |
| Smoke Tests | after health check | yes | block prod deploy | < 3 min |
| Deploy Production | manual gate or canary | no (needs staging verified) | rollback | < 5 min |

## Coverage Gate

- Line coverage: ≥ 80% (minimum) — pipeline fails below this threshold
- Branch coverage: ≥ 70% (minimum)
- Tool: [pytest-cov | jest --coverage | go test -cover | cargo tarpaulin | jacoco]

## Security Scan Tools

- SAST: [CodeQL | Semgrep | Bandit | ESLint security plugin | gosec | cargo-audit]
- SCA: [Dependabot | Renovate | OWASP Dependency-Check | Trivy fs]
- Container scan (if applicable): [Trivy image | Snyk container]

## Secrets Management

- [OIDC federation with cloud provider | GitHub/GitLab secrets | Vault | Azure Key Vault]
- No long-lived credentials in config files
- Rotation policy: [define]

## Branch Protection Rules (set in platform UI)

- [ ] All CI checks must pass before merge
- [ ] At least 1 approving review required
- [ ] Stale reviews dismissed on new push
- [ ] Force push to main disabled
- [ ] All conversations must be resolved

## Artifact Immutability

- Artifact built once in `build` job
- Artifact digest/SHA pinned in deploy jobs
- Same artifact deployed to staging AND production

## DORA Instrumentation

- Deployment events logged to [platform dashboard | Four Keys | custom]
- Lead time measured from: first commit → production deploy
- Change failure rate: tracked via rollback events or post-deploy alerts
````

---

## Platform-Specific Config Templates

Generate the config for the detected platform. Use the spec above as the design contract.

### GitHub Actions (`.github/workflows/ci.yml`)

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

# Least-privilege token scope
permissions:
  contents: read
  pull-requests: read
  security-events: write   # for security scan SARIF upload

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    name: Lint & Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # [language-specific lint step — e.g. ruff, eslint, gofmt, rustfmt --check]

  typecheck:
    name: Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # [language-specific type check — e.g. mypy, tsc --noEmit, go vet]

  unit-tests:
    name: Unit Tests
    needs: [lint, typecheck]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # [test command with --cov-fail-under=80 or equivalent]

  security-scan:
    name: Security Scan
    needs: [lint]
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4
      # [SAST tool — CodeQL or Semgrep or language equivalent]
      # [SCA — Trivy or language audit tool]

  build:
    name: Build Artifact
    needs: [unit-tests, security-scan]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # [build command — docker build / go build / npm run build / etc.]
      # [upload artifact with upload-artifact@v4 or push to registry]

  deploy-staging:
    name: Deploy to Staging
    needs: [build]
    if: github.ref == 'refs/heads/main'
    environment:
      name: staging
      url: ${{ vars.STAGING_URL }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # [deploy command]
      - name: Health check
        run: |
          for i in {1..12}; do
            curl -sf ${{ vars.STAGING_URL }}/health && exit 0
            sleep 5
          done
          exit 1
```

### GitLab CI (`.gitlab-ci.yml`)

```yaml
stages:
  - lint
  - test
  - security
  - build
  - deploy-staging
  - deploy-production

variables:
  COVERAGE_THRESHOLD: "80"

lint:
  stage: lint
  script:
    # [language-specific lint command]
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

unit-tests:
  stage: test
  script:
    # [test command with coverage enforcement]
  coverage: '/TOTAL.*\s+(\d+%)$/'   # regex extracts coverage %
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

security-sast:
  stage: security
  include:
    - template: Security/SAST.gitlab-ci.yml

dependency-scan:
  stage: security
  include:
    - template: Security/Dependency-Scanning.gitlab-ci.yml

build:
  stage: build
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
  script:
    # [build command]
  artifacts:
    paths:
      - dist/          # adjust for your build output
    expire_in: 1 week

deploy-staging:
  stage: deploy-staging
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
  environment:
    name: staging
    url: $STAGING_URL
  script:
    # [deploy command]
    - curl -sf $STAGING_URL/health || exit 1
```

### Jenkins, CircleCI, Azure DevOps, Bitbucket

Same universal pipeline stages as GitHub Actions and GitLab CI — lint, type check, unit tests + coverage gate, integration tests, security scan, build artifact, deploy staging, health check. Only the syntax and job definition format differ.

**Jenkins (Jenkinsfile — declarative):** `pipeline { stages { stage('Lint') {...} stage('Test') {...} } }`
**CircleCI (config.yml):** `workflows:` → `jobs:` with `requires:` for dependencies
**Azure DevOps (azure-pipelines.yml):** `stages:` with `dependsOn:` and `environment:` for deployment gates
**Bitbucket (bitbucket-pipelines.yml):** `pipelines: default:` → `step:` blocks

For any platform, adapt the GitHub Actions template above: same stage order, same coverage gate threshold, same artifact-first principle. The platform's official docs provide the YAML syntax.
---

## Dependency Scanning Config

**Dependabot** (GitHub — `.github/dependabot.yml`):
```yaml
version: 2
updates:
  - package-ecosystem: "[pip|npm|cargo|gomod|maven|bundler]"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    groups:
      dev-dependencies:
        dependency-type: "development"
```

**Renovate** (`.renovaterc.json` — works across GitHub, GitLab, Bitbucket, Azure DevOps):
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "schedule": ["before 6am on Monday"],
  "automerge": true,
  "automergeType": "pr",
  "automergeStrategy": "squash",
  "platformAutomerge": true
}
```

---

## Branch Protection Guidance

These rules are set in the platform UI (not in config files):

| Rule | Required | Reason |
|------|---------|--------|
| All CI checks must pass | ✅ | Core DORA: main branch always shippable |
| ≥ 1 approving review | ✅ | Code review requirement |
| Dismiss stale reviews on push | ✅ | Prevents approval bypass |
| Enforce admins | ✅ | Prevents exceptions that erode the gate |
| No force push to main | ✅ | Immutable history |
| Require conversation resolution | ✅ | No unresolved review threads merged |
| Branch up-to-date before merge | recommended | Reduces merge conflicts in CI |

---

## Self-Review: Run `ci-reviewer` Agent

After generating configs, before committing:

```
Agent(ci-reviewer, {
  PIPELINE_SPEC_PATH: ".ai/ci/YYYY-MM-DD-pipeline-spec.md",
  CI_CONFIG_PATH: "[platform-specific file path]",
  PROJECT_ROOT: "."
})
```

Fix all **Critical** findings. **Important** findings should be fixed. **Advisory** may be deferred.

---

## Commit

Stage and commit all pipeline files in a single commit:
```
feat(ci): add CI/CD pipeline with coverage gate and security scan

[body: WHY — what was missing, what this pipeline now enforces]
```

CI takes effect immediately on the next push to the branch.
