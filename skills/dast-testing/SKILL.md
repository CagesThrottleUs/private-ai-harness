---
name: dast-testing
description: >
  Use before finishing-a-development-branch for any externally-facing service. Generates OWASP ZAP baseline scan (every PR, passive) and API scan (post-staging-deploy, uses OpenAPI spec), optionally Nuclei for targeted API vulnerability scanning, SARIF output to GitHub Security tab, and CI jobs that fail on HIGH severity findings. Runs dast-reviewer agent before committing. SAST reviews code; DAST attacks the running application — both are required.
---

# DAST Testing

SAST (static analysis) reviews code. DAST (dynamic analysis) attacks the running application. They catch different things. A SQL injection that's invisible in source code is obvious to DAST. A misconfigured CORS header that passes code review is caught in seconds by ZAP.

## References

- **OWASP ZAP** (owasp.org/www-project-zap) — free, Apache 2.0, official GitHub Actions, SARIF output. Industry standard for DevSecOps CI/CD integration.
- **ZAP GitHub Actions** (zaproxy/action-baseline, zaproxy/action-api-scan) — zero-config CI integration
- **Nuclei** (projectdiscovery.io/nuclei) — YAML templates, 7,000+ community templates covering CVEs, misconfigurations, API issues. Fewer false positives than ZAP for targeted API scanning.
- **OWASP Top 10** (owasp.org/www-project-top-ten) — benchmark for web application security risks

---

## When to Use

**Required** for any service with:
- External HTTP endpoints (user-facing or API)
- Authentication/authorization logic
- Input fields or parameters (SQL, XSS vectors)
- File upload or processing

**Skip** for: internal CLI tools with no HTTP interface, pure background workers with no API surface.

**Infer + confirm:**
> "This is an internal CLI tool with no HTTP endpoints. Skipping DAST. OK, or is there an HTTP surface I'm missing?"

---

## Scan Types

| Type | Tool | Trigger | Duration | What it finds |
|------|------|---------|---------|--------------|
| **Baseline** | ZAP | Every PR | < 2 min | Passive only: headers, cookies, obvious misconfigs |
| **API scan** | ZAP | Post-staging-deploy | 5-15 min | Active: injection, auth bypass, broken auth — uses OpenAPI spec |
| **Nuclei** | Nuclei | Post-staging-deploy | 2-5 min | CVEs, misconfigs, secrets in responses, API issues |
| **Full scan** | ZAP | Nightly | 20-60 min | Complete active + passive, all rules |

---

## Outputs

### 1. ZAP Configuration

Save to: `.zap/rules.tsv` — customize which rules to ignore (false positives, accepted risks):

```tsv
# Format: ID	THRESHOLD	STRENGTH
# THRESHOLD: OFF | WARN | FAIL  STRENGTH: LOW | MEDIUM | HIGH | INSANE
10016	WARN	LOW   # Web Browser XSS Protection Not Enabled — informational
10017	OFF	LOW    # Cross-Domain JavaScript Source File Inclusion — accepted for CDN
```

### 2. CI Jobs

**GitHub Actions — add after staging deploy:**

```yaml
  # Runs on every PR — baseline passive scan (fast)
  dast-baseline:
    name: DAST Baseline
    needs: [unit-tests]
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      - name: ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.14.0
        with:
          target: ${{ vars.PR_PREVIEW_URL || 'http://localhost:3000' }}
          rules_file_name: '.zap/rules.tsv'
          fail_action: true          # fail on FAIL-level alerts
          cmd_options: '-a'          # include alpha passive rules

  # Runs after staging deploy — active API scan
  dast-api-scan:
    name: DAST API Scan
    needs: [deploy-staging]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: ZAP API Scan
        uses: zaproxy/action-api-scan@v0.9.0
        with:
          target: ${{ vars.STAGING_URL }}/api/openapi.yaml  # uses your OpenAPI spec
          format: openapi
          fail_action: true
          cmd_options: '-config globalexcludeurl.url_list.url.regex=.*logout.*'
      - name: Upload SARIF to Security tab
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: zap.sarif
          category: dast

  # Nuclei — targeted API vulnerability scan (optional, complements ZAP)
  dast-nuclei:
    name: Nuclei API Scan
    needs: [deploy-staging]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Install Nuclei
        run: |
          go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
          nuclei -update-templates
      - name: Run Nuclei against staging
        run: |
          nuclei \
            -target ${{ vars.STAGING_URL }} \
            -tags api,auth,misconfiguration,exposure \
            -severity medium,high,critical \
            -sarif-export nuclei.sarif \
            -exit-code   # non-zero on findings
        env:
          NUCLEI_API_KEY: ${{ secrets.NUCLEI_API_KEY }}  # optional
      - name: Upload Nuclei SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: nuclei.sarif
          category: nuclei
```

**GitLab CI equivalent:**
```yaml
dast-baseline:
  stage: security
  image: ghcr.io/zaproxy/zaproxy:stable
  script:
    - zap-baseline.py -t $PR_PREVIEW_URL -r zap-report.html -x zap-report.xml
    - if grep -q "<riskdesc>High" zap-report.xml; then exit 1; fi
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
  artifacts:
    paths: [zap-report.html]
```

### 3. Authenticated Scanning

If your application requires authentication, ZAP needs to be configured to log in first:

```yaml
      - name: ZAP API Scan (authenticated)
        uses: zaproxy/action-api-scan@v0.9.0
        with:
          target: ${{ vars.STAGING_URL }}/api/openapi.yaml
          format: openapi
          fail_action: true
          # Authentication via ZAP automation framework
          env_vars: |
            ZAP_AUTH_HEADER=Authorization
            ZAP_AUTH_HEADER_VALUE=Bearer ${{ secrets.DAST_TEST_TOKEN }}
```

**Dedicated DAST test account:**
- Create a test user account in staging specifically for DAST
- Use minimal permissions (don't scan with admin credentials — findings will differ by auth level)
- Store credentials as CI secrets: `DAST_TEST_USER`, `DAST_TEST_PASSWORD`, `DAST_TEST_TOKEN`

### 4. Severity Thresholds

| Severity | Default action | Rationale |
|----------|---------------|-----------|
| CRITICAL | Fail CI | Always block |
| HIGH | Fail CI | Probable vulnerabilities |
| MEDIUM | Warn (review in PR) | Possible vulnerabilities |
| LOW | Informational only | Low risk, track in backlog |

Override per rule in `.zap/rules.tsv` with documented justification.

---

## OWASP Top 10 Coverage

ZAP + Nuclei together cover approximately 70% of OWASP Top 10 2021 automatically:

| OWASP Risk | Covered by | Coverage |
|-----------|-----------|---------|
| A01 Broken Access Control | ZAP active scan | Partial |
| A02 Cryptographic Failures | ZAP passive (TLS headers) | Headers only |
| A03 Injection (SQLi, XSS) | ZAP active + Nuclei templates | Good |
| A04 Insecure Design | Manual only | ❌ |
| A05 Security Misconfiguration | ZAP passive + Nuclei | Strong |
| A06 Vulnerable Components | Nuclei CVE templates | Good |
| A07 Auth Failures | ZAP active (session mgmt) | Partial |
| A08 Software & Data Integrity | Nuclei + SAST | Partial |
| A09 Security Logging Failures | Nuclei + manual | Partial |
| A10 SSRF | Nuclei templates | Good |

What DAST **cannot** catch: business logic flaws, insecure design decisions, authorization logic that requires understanding domain context.

---

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review
- Pattern check before re-dispatch: does this finding's pattern recur elsewhere in the artifact? Fix every occurrence in the same pass — a finding that resurfaces next cycle in a new spot is the cost this discipline exists to cut

## Self-Review: Run `dast-reviewer` Agent

After generating CI configs, before committing:

```
Agent(dast-reviewer, {
  CI_CONFIG_PATH: ".github/workflows/ci.yml",
  OPENAPI_PATH: "api/openapi.yaml",   // optional — for API scan validation
  ZAP_RULES_PATH: ".zap/rules.tsv"    // optional
})
```

Fix all **Critical** findings (no authentication in authenticated app, scan pointing to production, HIGH findings configured to warn not fail) before committing.
---

## Completion Report

When this skill's work is done, report to the user in chat — do not let a commit
message be the only trace of what happened:

- **Produced:** what was created or changed (artifact type + exact path).
- **Verdict:** the reviewer's PASS / NEEDS WORK / BLOCKED result, if a gate ran.
- **Coverage:** which spec REQ / NFR this satisfies, where applicable.
- **Next:** the next step in the flow, or "ready for review / merge".

One line per item is enough. The point is that the user sees what shipped and
its verdict without having to read the diff.
