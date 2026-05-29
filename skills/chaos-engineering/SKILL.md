---
name: chaos-engineering
description: >
  Use for any service with resilience NFRs (circuit breakers, retries, graceful degradation). Follows the Chaos Engineering scientific method: define steady state from SLOs, formulate hypothesis per failure scenario, inject faults via k6 (HTTP errors, timeouts, latency spikes) and optionally Toxiproxy (network-level), verify circuit breaker/retry behavior. Adds a chaos CI job that runs post-staging-deploy. Runs chaos-reviewer before committing. Load tests verify NFR targets; chaos tests verify the system fails gracefully when they're breached.
---

# Chaos Engineering

Load tests prove the system handles expected load. Chaos tests prove the system fails gracefully when dependencies break. The difference: load testing verifies steady-state performance; chaos engineering verifies fault tolerance.

**Core method** (Netflix/AWS Well-Architected standard):
1. **Define steady state** — measurable output of normal behavior (from SLOs)
2. **Hypothesize** — "When [failure] occurs, the system will [graceful behavior] and [steady state] will resume within [N] seconds"
3. **Inject failure** — controlled, scoped, with abort criteria
4. **Verify** — did the system behave as hypothesized?

## References

- **Netflix Chaos Engineering Principles** (principlesofchaos.org) — foundational; start with steady state
- **AWS Well-Architected: REL12-BP04** (docs.aws.amazon.com/wellarchitected/latest/reliability-pillar) — chaos in CI/CD pipeline
- **Toxiproxy** (github.com/Shopify/toxiproxy) — Shopify's network fault proxy; zero K8s dependency
- **k6 fault injection** — HTTP error injection via custom scenarios; already in the harness
- **Chaos Mesh / LitmusChaos** — Kubernetes-native for K8s deployments

---

## When to Use

**Required** only for services with explicit resilience NFRs:
- Circuit breaker pattern documented in HLD
- Retry with backoff in the design
- Graceful degradation to cached/default data
- Timeout budgets specified in spec

**Skip** for: services with no resilience NFRs, simple CRUD with no external dependencies, services in early development without 99.9%+ availability SLOs.

**Infer + confirm:**
> "The HLD doesn't mention circuit breakers or retry logic, and there are no availability NFRs. Chaos testing adds overhead without clear value here. Skip, or do you have resilience requirements I'm missing?"

---

## Failure Scenarios to Generate

Based on reading HLD failure mode analysis (§7) and spec NFRs:

| Failure type | What to inject | k6 tool | What to verify |
|-------------|---------------|---------|---------------|
| Dependency HTTP errors | 10% 503 responses | k6 error rate injection | Circuit breaker triggers; degraded mode activates |
| Timeout | 5% requests timeout at > budget | k6 latency injection | Retry fires; user sees timeout-specific error (not hang) |
| Latency spike | +500ms on all requests | k6 sleep injection | p99 degrades but stays < 2× SLO; circuit breaker doesn't trip |
| DB connection drop | TCP reset on DB connections | Toxiproxy | App returns 503 gracefully; doesn't crash; recovers when DB returns |
| Cascading failure | Slow dependency + high load | k6 combined | System sheds load; doesn't enter death spiral |

---

## k6 Chaos Test Scripts

Save to: `tests/chaos/`

### HTTP error rate injection

```javascript
// tests/chaos/circuit-breaker.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorsDuringChaos = new Rate('errors_during_chaos');

// STEADY STATE from SLOs:
// - Error rate < 0.1% (normal)
// - p99 latency < 200ms (normal)

// HYPOTHESIS:
// When 10% of upstream dependency calls fail with 503:
// - Circuit breaker opens after threshold (< 5 failed calls)
// - System returns 503 with Retry-After header (not 500)
// - Error rate stays < 15% (circuit breaker absorbs excess)
// - System recovers within 30s when dependency recovers

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // Ramp to normal load — baseline
    { duration: '2m', target: 50 },   // Steady state — verify baseline
    { duration: '30s', target: 50 },  // Keep load; chaos begins (see FAULT_INJECTION below)
    { duration: '2m', target: 50 },   // Chaos: dependency returning 503 10% of the time
    { duration: '30s', target: 50 },  // Recovery: dependency restored
    { duration: '1m', target: 50 },   // Verify system returns to steady state
    { duration: '30s', target: 0 },   // Ramp down
  ],
  thresholds: {
    // During chaos: circuit breaker should absorb most failures
    'http_req_failed': ['rate<0.15'],          // Allow up to 15% during chaos
    'http_req_duration': ['p(99)<2000'],        // Graceful degradation: allow longer p99
    // Check circuit breaker response shape
    'errors_during_chaos': ['rate<0.15'],
  },
};

export default function () {
  const baseUrl = __ENV.BASE_URL || 'http://localhost:3000';
  const res = http.get(`${baseUrl}/api/[critical-endpoint]`);

  const isOk = check(res, {
    'status is 200 or 503 (graceful)': (r) => [200, 503].includes(r.status),
    'no 500 Internal Server Error': (r) => r.status !== 500,
    // Verify graceful 503 has Retry-After header
    '503 has Retry-After': (r) => r.status !== 503 || r.headers['Retry-After'] !== undefined,
  });

  if (!isOk) errorsDuringChaos.add(1);
  sleep(0.5);
}

export function handleSummary(data) {
  // Print summary focused on chaos resilience metrics
  return { stdout: JSON.stringify(data.metrics, null, 2) };
}
```

### Network-level fault injection (Toxiproxy)

```bash
# Install Toxiproxy
brew install toxiproxy  # macOS
# or: docker run -d -p 8474:8474 -p 5433:5433 ghcr.io/shopify/toxiproxy

# Create proxy for database
toxiproxy-cli create db-proxy --listen 0.0.0.0:5433 --upstream db-host:5432

# Inject 500ms latency (latency spike scenario)
toxiproxy-cli toxic add db-proxy -t latency \
  --attribute latency=500 \
  --attribute jitter=100 \
  --toxicity 1.0  # 100% of connections affected

# Run your load test with DB going through proxy
BASE_URL=$STAGING_URL k6 run tests/performance/load-test.js \
  --env DB_HOST=localhost:5433

# Remove the toxic (simulates recovery)
toxiproxy-cli toxic remove db-proxy -n latency_0

# Verify system recovered
sleep 30  # wait for circuit breaker reset
k6 run tests/chaos/circuit-breaker.js --env BASE_URL=$STAGING_URL
```

### Latency spike test

```javascript
// tests/chaos/latency-spike.js
// HYPOTHESIS: When p99 latency rises to 500ms (2.5× SLO),
// the circuit breaker should NOT trip (latency alone shouldn't trigger it).
// The system should degrade gracefully and recover when latency returns to normal.

import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // Baseline
    { duration: '2m', target: 50 },   // Chaos: external latency added via Toxiproxy
    { duration: '1m', target: 50 },   // Recovery
  ],
  thresholds: {
    'http_req_failed': ['rate<0.01'],       // Circuit breaker should NOT trip on latency alone
    'http_req_duration': ['p(99)<2000'],    // Allow degraded p99 during chaos
  },
};

export default function () {
  const res = http.get(`${__ENV.BASE_URL}/api/[critical-endpoint]`, {
    timeout: '3s',  // explicit timeout — no hanging requests
  });
  check(res, { 'status 200': (r) => r.status === 200 });
  sleep(0.5);
}
```

---

## CI Integration

Chaos tests run **post-staging-deploy**, not on PRs (they require a real environment and controlled blast radius).

```yaml
# Adds to .github/workflows/ci.yml — after deploy-staging
  chaos-tests:
    name: Chaos Engineering
    needs: [deploy-staging, dast-api-scan]  # after staging is healthy
    runs-on: ubuntu-latest
    timeout-minutes: 20
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Install k6
        run: sudo apt-get install k6
      - name: Run circuit breaker chaos test
        run: |
          k6 run tests/chaos/circuit-breaker.js \
            --env BASE_URL=${{ vars.STAGING_URL }}
        # This test should PASS — it verifies the system handles failures gracefully
      - name: Upload chaos results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: chaos-results
          path: chaos-*.json
```

**Abort criteria** — stop chaos immediately if:
- Error rate exceeds 50% (system is not recovering)
- Any data corruption detected
- Test is running longer than the timeout

---

## Chaos Experiment Documentation

For each experiment, document:

```markdown
## Experiment: [Name]

**Steady state:** [measurable metric — e.g., "p99 < 200ms, error rate < 0.1%"]
**Hypothesis:** When [failure] occurs, the system will [behavior] and recover within [N] seconds.
**Blast radius:** [What is at risk — "10% of requests to /api/checkout during 2-minute window"]
**Abort criteria:** [When to stop — "if error rate > 50%, immediately remove fault"]
**Result:** [CONFIRMED / REFUTED] — [what actually happened]
**Action:** [What was fixed if hypothesis was refuted]
```

---

## Self-Review: Run `chaos-reviewer` Agent

```
Agent(chaos-reviewer, {
  TEST_FILES: "tests/chaos/**/*.js",
  HLD_PATH: ".ai/hld/YYYY-MM-DD-<feature>.md",
  SPEC_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md"
})
```

Fix all **Critical** findings before committing.
