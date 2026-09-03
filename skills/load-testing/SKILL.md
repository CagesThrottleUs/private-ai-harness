---
name: load-testing
description: >
  Use before finishing-a-development-branch for any feature with NFR targets (latency, throughput, availability). Reads spec NFRs and SLOs from observability-standards, generates k6 scripts for smoke, load, stress, and spike scenarios, sets thresholds tied directly to spec NFR targets, and adds a CI performance job against staging. Runs load-test-reviewer agent before committing. An NFR without a load test is an aspiration. An NFR with a passing load test is a guarantee.
---

# Load Testing

NFRs without load tests are aspirations. NFRs with passing load tests are contractual guarantees. If the spec says "p99 < 200ms at 500 RPS," there must be a test that runs at 500 RPS and fails when p99 exceeds 200ms.

## References

- **Grafana k6** (k6.io) — JavaScript-based, CLI-first, non-zero exit on threshold breach (native CI gate). 29.9k GitHub stars. Free OSS.
- **k6 Thresholds** (grafana.com/docs/k6/latest/using-k6/thresholds/) — SLOs codified directly into tests; threshold breach = non-zero exit = CI failure
- **k6 API Load Testing Guide** (grafana.com/docs/k6/latest/testing-guides/api-load-testing/) — scenarios, stages, realistic traffic modeling
- **Load Testing Manifesto** (k6.io/our-beliefs/) — "A slightly relaxed threshold that runs on every PR is far more valuable than a strict threshold that nobody runs"
- **NFR testing types** (radview.com/blog/non-functional-requirements-nfrs-for-performance-testing/) — load, stress, spike, soak — each validates a different NFR class

---

## Tool Selection

| Tool | Use when |
|------|---------|
| **k6** (recommended) | JavaScript teams, CI-first, Docker-friendly, threshold-based gates |
| **Locust** | Python teams, need custom protocols beyond HTTP |
| **Gatling** | Scala/Java teams, need stakeholder-readable HTML reports |
| **Artillery** | Node.js teams, YAML config preference |

Default: **k6**. All templates below are k6. Locust/Gatling templates available on request.

---

## When to Use

**See also:** `chaos-engineering` skill — extends load testing with fault injection scenarios for services with resilience NFRs (circuit breakers, retries, graceful degradation).

**Required** when the spec has numeric performance NFRs: latency targets, throughput targets, availability targets, concurrent user ceilings.

**Skip** when: spec has no NFR section, internal-only change, bug fix, utility function with no user-facing load.

**Infer + confirm:**
> "The spec has no performance NFRs and this is an internal utility. Skipping load-testing. OK, or did I miss an NFR?"

---

## Inputs Required

- **Spec NFRs** — read from `.ai/YYYY-MM-DD-<feature-slug>/specs/specs-<feature-slug>.md` NFR table
- **SLO targets** — read from `.ai/YYYY-MM-DD-<feature-slug>/observability/observability-<feature-slug>-slos.md`
- **Staging URL** — `$BASE_URL` environment variable

---

## Test Types and When to Run Each

| Test type | Purpose | VUs | Duration | When to run |
|-----------|---------|-----|----------|------------|
| **Smoke** | Script validity, no regressions | 1-2 | 1 min | Every PR, every commit |
| **Load** | Validates NFR targets at expected load | NFR target | 10-30 min | After staging deploy |
| **Stress** | Finds the breaking point | Escalating | 20-40 min | Before major releases |
| **Spike** | Tests auto-scaling response | 5-10× target | 15-20 min | When scaling is a concern |
| **Soak** | Reveals memory leaks, conn exhaustion | NFR target | 2-8 hours | For availability NFRs (99.9%+) |

---

## k6 Script Templates

### Base script structure

Save to: `tests/performance/load-test.js`

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// ---- NFR-ALIGNED THRESHOLDS ----
// These values MUST match the spec NFR table and .ai/<feature-slug>/observability/observability-<feature-slug>-slos.md
// Changing a threshold here requires updating the spec NFR and SLO document too
export const options = {
  // Smoke: validates script works, runs on every PR
  // Load: validates NFR targets at expected concurrent users
  // Stress: finds breaking point
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: 2,
      duration: '1m',
      tags: { scenario: 'smoke' },
      env: { SCENARIO: 'smoke' },
    },
    load: {
      executor: 'ramping-vus',
      stages: [
        { duration: '2m', target: 100 },  // ramp-up to target VUs
        { duration: '5m', target: 100 },  // steady state — validate NFRs here
        { duration: '2m', target: 0 },    // ramp-down
      ],
      tags: { scenario: 'load' },
      env: { SCENARIO: 'load' },
      startTime: '0s',
    },
  },

  thresholds: {
    // Latency NFR: p99 < [latency target from spec]
    // p95 is a leading indicator; p99 is the SLO target
    'http_req_duration{scenario:load}': [
      'p(95)<150',   // p95 well below SLO — early warning
      'p(99)<200',   // p99 = SLO target from spec NFR table
    ],
    // Error rate NFR: < 1% (from observability SLO)
    'http_req_failed{scenario:load}': ['rate<0.01'],
    // Throughput verification: ensure we're generating enough load
    'http_reqs{scenario:load}': ['rate>50'],  // minimum RPS to be valid
    // Smoke: must pass with minimal load
    'http_req_duration{scenario:smoke}': ['p(99)<500'],
    'http_req_failed{scenario:smoke}': ['rate<0.01'],
  },
};

// ---- CUSTOM METRICS ----
const customErrors = new Rate('custom_errors');
const responseTrend = new Trend('response_time_trend');

// ---- TEST SCENARIOS ----
export default function () {
  const baseUrl = __ENV.BASE_URL || 'http://localhost:3000';

  // Authenticated request (adjust to your auth mechanism)
  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${__ENV.API_TOKEN}`,
  };

  // ---- PRIMARY CRITICAL PATH (highest traffic endpoint) ----
  const listResponse = http.get(`${baseUrl}/api/resources`, { headers });
  
  const listCheck = check(listResponse, {
    'list: status 200': (r) => r.status === 200,
    'list: has items array': (r) => JSON.parse(r.body).items !== undefined,
    'list: response time < p99 target': (r) => r.timings.duration < 200,
  });
  
  customErrors.add(!listCheck);
  responseTrend.add(listResponse.timings.duration);

  // ---- SECONDARY PATHS ----
  // Include realistic user behavior — not just the happy path
  // A realistic mix: 70% reads, 20% creates, 10% deletes
  const rand = Math.random();
  
  if (rand < 0.7) {
    // Read path (most common)
    const getResponse = http.get(`${baseUrl}/api/resources/some-id`, { headers });
    check(getResponse, {
      'get: status 200 or 404': (r) => [200, 404].includes(r.status),
    });
  } else if (rand < 0.9) {
    // Write path
    const createResponse = http.post(
      `${baseUrl}/api/resources`,
      JSON.stringify({ name: `load-test-resource-${Date.now()}` }),
      { headers },
    );
    check(createResponse, {
      'create: status 201': (r) => r.status === 201,
    });
  }

  // Realistic think time between requests (adjust based on your use case)
  sleep(Math.random() * 0.5 + 0.5);  // 0.5-1s
}

// ---- LIFECYCLE HOOKS ----
export function setup() {
  // Obtain auth token, create test data, etc.
  // Return data available to all VUs
  return { startTime: Date.now() };
}

export function teardown(data) {
  // Clean up test data created during the run
  console.log(`Test ran for ${(Date.now() - data.startTime) / 1000}s`);
}
```

### Spike test scenario

Save to: `tests/performance/spike-test.js`

```javascript
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },   // baseline
    { duration: '1m', target: 500 },   // spike to 5× in 1 minute
    { duration: '10m', target: 500 },  // hold spike
    { duration: '2m', target: 100 },   // drop back to baseline
    { duration: '5m', target: 100 },   // recover: does it return to baseline?
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    // During spike: allow degraded p99 (auto-scaling needs time to react)
    'http_req_duration': ['p(99)<1000'],   // 5× relaxed SLO during spike
    'http_req_failed': ['rate<0.05'],       // 5× relaxed error rate during spike
  },
};

export default function () {
  const response = http.get(`${__ENV.BASE_URL}/api/resources`, {
    headers: { Authorization: `Bearer ${__ENV.API_TOKEN}` },
  });
  check(response, { 'status 200': (r) => r.status === 200 });
}
```

### Soak test scenario (use for availability NFRs ≥ 99.9%)

Save to: `tests/performance/soak-test.js`

```javascript
import http from 'k6/http';
import { check } from 'k6';

// Soak: run at target load for extended period
// Reveals: memory leaks, connection pool exhaustion, thread count drift
// Duration: 2 hours minimum for 99.9% availability; 8 hours for 99.99%
export const options = {
  stages: [
    { duration: '5m', target: 100 },    // ramp to target
    { duration: '2h', target: 100 },    // hold at target — looking for drift
    { duration: '5m', target: 0 },
  ],
  thresholds: {
    'http_req_duration': ['p(99)<200'],
    'http_req_failed': ['rate<0.001'],  // stricter for soak — any sustained error is a finding
  },
};

export default function () {
  const response = http.get(`${__ENV.BASE_URL}/api/resources`, {
    headers: { Authorization: `Bearer ${__ENV.API_TOKEN}` },
  });
  check(response, { 'status 200': (r) => r.status === 200 });
}
```

---

## Threshold Configuration from NFRs

**The thresholds in the k6 script MUST be derived from spec NFRs.**

```javascript
// From spec NFR table:
// | Response time | p99 < 200ms | APM histogram | Normal load |
// | Availability  | 99.9%       | Uptime monitor| 30-day      |
// | Throughput    | 1,000 RPS   | Load test      | Sustained   |

thresholds: {
  'http_req_duration': [
    'p(95)<150',    // p95 early warning (75% of SLO target)
    'p(99)<200',    // p99 = NFR target (pull from spec NFR table)
  ],
  'http_req_failed': ['rate<0.001'],  // 99.9% success = 0.1% error rate max
  'http_reqs': ['rate>1000'],         // Throughput NFR: 1,000 RPS minimum
},
```

**If spec has no NFR table:** use these safe defaults and flag as advisory:
```javascript
thresholds: {
  'http_req_duration': ['p(99)<500'],  // conservative default
  'http_req_failed': ['rate<0.01'],    // 99% success rate default
},
```

---

## CI Integration

Load tests run **after staging deploy** — not on every PR (smoke test runs on PR; full load test on staging).

**GitHub Actions:**
```yaml
# Adds to .github/workflows/ci.yml — after deploy-staging job
  performance-tests:
    name: Performance Tests
    needs: [deploy-staging]
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - name: Install k6
        run: |
          sudo gpg -k
          sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
            --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
          echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] \
            https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update && sudo apt-get install k6
      - name: Run smoke test (every deploy)
        run: k6 run --env BASE_URL=${{ vars.STAGING_URL }} tests/performance/load-test.js \
          --scenario smoke --quiet
        env:
          API_TOKEN: ${{ secrets.TEST_API_TOKEN }}
      - name: Run load test (validates NFR targets)
        run: k6 run --env BASE_URL=${{ vars.STAGING_URL }} tests/performance/load-test.js \
          --scenario load
        env:
          API_TOKEN: ${{ secrets.TEST_API_TOKEN }}
      - name: Upload k6 results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: k6-results
          path: '**/summary.json'
```

**Smoke test on every PR** (fast, cheap validation):
```yaml
  smoke-test:
    name: Smoke Test
    needs: [unit-tests]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get install k6
      - run: k6 run --env BASE_URL=http://localhost:3000 tests/performance/load-test.js \
          --scenario smoke --vus 1 --duration 30s
```

---

## Performance Baseline Report

Save results to: `.ai/YYYY-MM-DD-<feature-slug>/performance/performance-<feature-slug>-baseline.md`

````markdown
# Performance Baseline — [Feature Name]

**Date:** YYYY-MM-DD
**Environment:** Staging
**Target:** `$STAGING_URL`
**Tool:** k6 v[version]

## NFR Targets vs Actual

| NFR | Target | Actual (p95) | Actual (p99) | Status |
|-----|--------|-------------|-------------|--------|
| Response time | p99 < 200ms | [measured] | [measured] | ✅ PASS / 🔴 FAIL |
| Error rate | < 0.1% | [measured] | — | ✅ PASS / 🔴 FAIL |
| Throughput | > 1,000 RPS | [measured] | — | ✅ PASS / 🔴 FAIL |

## Load Scenario Summary

**Peak VUs:** [N]
**Duration:** [N] minutes
**Total requests:** [N]
**k6 threshold verdict:** PASS / FAIL

## Findings

[Any degradation patterns, memory drift, connection pool behavior]

## Breaking Point (stress test, if run)

**VUs at degradation:** [N]
**p99 at breaking point:** [Nms]
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

## Self-Review: Run `load-test-reviewer` Agent

After writing scripts, before committing:

```
Agent(load-test-reviewer, {
  SCRIPT_PATH: "tests/performance/load-test.js",
  SPEC_PATH: ".ai/YYYY-MM-DD-<feature-slug>/specs/specs-<feature-slug>.md",
  SLO_PATH: ".ai/YYYY-MM-DD-<feature-slug>/observability/observability-<feature-slug>-slos.md"  // optional
})
```

Fix all **Critical** findings (thresholds not tied to NFRs, no smoke test, test runs against localhost in CI). Fix **Important** findings (no soak test for availability NFR, unrealistic VU count).

---

## Commit

```
test(performance): add k6 load tests for [feature] NFR targets

[body: WHY — what performance guarantees these tests enforce, what would be
unknown without them, which NFRs are now contractually verified]
```
