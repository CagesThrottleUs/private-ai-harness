---
name: observability-standards
description: >
  Use after the first API endpoint or service is created — before anything is deployed. Instruments structured logging (OpenTelemetry data model), golden signal metrics (latency histogram, request counter, error counter, saturation gauge), produces an SLO definition document, alert rules template, and per-alert runbooks. Runs observability-reviewer agent before committing. A system without observability is not a production system — it is code that happens to be running.
---

# Observability Standards

Instrument a system for production before it reaches production. Observability retrofitted after the first incident costs ten times more than observability built at endpoint creation time.

## References

- **OpenTelemetry Logs Data Model** (opentelemetry.io/docs/specs/otel/logs/data-model/) — mandatory fields, severity taxonomy, trace/span correlation
- **Google SRE Book: Monitoring Distributed Systems** (sre.google/sre-book/monitoring-distributed-systems/) — four golden signals: latency, traffic, errors, saturation
- **Google SRE Workbook: SLO Documents** (sre.google/workbook/slo-document/) — SLI/SLO/error budget format
- **Google SRE Workbook: Alerting on SLOs** (sre.google/workbook/alerting-on-slos/) — burn rate alerts over threshold alerts
- **PagerDuty Alerting Principles** (response.pagerduty.com/oncall/alerting_principles/) — alert on symptoms, not causes
- **Rootly Runbook Guide** (rootly.com/incident-response/runbooks) — alert context, diagnosis, remediation, escalation

---

## When to Use

**Required** when a task creates an external-facing component: API endpoint, background worker, service boundary, or anything handling external traffic.

**Skip** when: pure refactoring with no new endpoints, internal utility function, config change, documentation-only.

**Infer + confirm:**
> "This refactors an existing handler — no new endpoint, no new metrics path. Skipping observability-standards. Right?"

**Do not defer** when it does apply — observability added post-deployment is observability added during an incident.

---

## Inputs Required

- **Project root** — detect language from manifest files
- **Endpoints created** — list of new endpoints/handlers from the current task
- **NFRs** — latency and availability targets from `.ai/specs/` (used to set SLO targets)

---

## Process

1. **Detect language** — read manifest files (`pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`, `pom.xml`)
2. **Generate structured logging config** — language-specific, OpenTelemetry-compliant, all mandatory fields
3. **Instrument golden signals** — add metrics to each new endpoint (histogram, counter, gauge)
4. **Write SLO document** — pulled from NFRs in spec; saved to `.ai/observability/YYYY-MM-DD-slos.md`
5. **Write alert rules** — symptom-based; saved to `wiki/guides/alerts.md`
6. **Write runbook per alert** — saved to `wiki/guides/runbooks/alert-<name>.md`
7. **Write observability standards doc** — project-specific field names and conventions; `wiki/guides/observability.md`
8. **Run `observability-reviewer` agent** — fix Critical and Important findings before committing

---

## Structured Logging Standard

### Required fields (OpenTelemetry Log Data Model)

Every log entry MUST contain all six fields:

| Field | Type | Example | Purpose |
|-------|------|---------|---------|
| `timestamp` | ISO 8601 UTC | `2026-05-29T07:42:00.123Z` | Event time, nanosecond precision preferred |
| `severity` | string | `INFO` / `WARN` / `ERROR` | Normalized: TRACE, DEBUG, INFO, WARN, ERROR, FATAL |
| `trace_id` | hex string | `4bf92f3577b34da6a3ce929d0e0e4736` | OTel trace ID — correlates log to distributed trace |
| `span_id` | hex string | `00f067aa0ba902b7` | OTel span ID — correlates log to specific operation |
| `service.name` | string | `payment-api` | Service name — mandatory for multi-service correlation |
| `body` | string / object | `"user login failed"` | Human-readable message OR structured event object |

Optional but strongly recommended:
- `user_id` — for user-facing operations
- `request_id` — per-request correlation (if not using OTel trace_id)
- `error` — structured error object: `{type, message, stack}` — never a raw stack trace string

### Language-specific setup

**Python — `structlog`:**
```python
import structlog
import logging

structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.processors.JSONRenderer(),
    ],
    logger_factory=structlog.PrintLoggerFactory(),
)
log = structlog.get_logger()

# Usage — every request binds trace context
structlog.contextvars.bind_contextvars(
    trace_id=trace_id,
    span_id=span_id,
    service_name="your-service",
)
log.info("request.received", method="GET", path="/api/users", user_id=user_id)
```

**Go — `log/slog` (stdlib, Go 1.21+):**
```go
import (
    "log/slog"
    "os"
)

logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))

// Usage — attach trace context
logger.InfoContext(ctx, "request.received",
    slog.String("trace_id", traceID),
    slog.String("span_id", spanID),
    slog.String("service_name", "your-service"),
    slog.String("method", "GET"),
    slog.String("path", "/api/users"),
)

// For performance-critical: zerolog
// import "github.com/rs/zerolog"
// zerolog ~15x faster than slog under high concurrency
```

**TypeScript/Node.js, Java, Rust:** Same 6-field pattern using the language's structured logging library (`pino` for Node, `logback+logstash-encoder` for Java, `tracing` crate for Rust). Bind trace_id/span_id via middleware/MDC/instrument macro. Output JSON, not plain text.

### What NOT to log

- Raw stack traces as strings (use structured error object)
- Passwords, tokens, PII in log body (even at DEBUG)
- Unbounded string fields (truncate at 1KB)
- Redundant fields already in trace context

---

## Golden Signal Metrics

Per endpoint, instrument all four signals. Use OpenTelemetry SDK — output to Prometheus, Datadog, or any OTel-compatible backend.

### The four signals (Google SRE Book, Chapter 6)

| Signal | What it measures | Metric type | When it pages |
|--------|-----------------|-------------|--------------|
| **Latency** | Time to service a request. Distinguish successful vs failed — a fast error is not a good result. | Histogram (p50/p95/p99) | p99 > SLO threshold |
| **Traffic** | Demand on the system. Requests/second per endpoint. | Counter | Anomalous drops (traffic = 0) |
| **Errors** | Rate of failing requests. Explicit (5xx), implicit (200 with wrong content), by policy (response > SLA). | Counter | error_rate > 1% sustained |
| **Saturation** | How "full" the service is. The resource most constrained: CPU, memory, connection pool, queue depth. | Gauge | > 80% of limit |

### Instrumentation templates

**Python (OpenTelemetry):**
```python
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider

meter = metrics.get_meter("your-service")

# Latency histogram (p50/p95/p99 via exemplars)
request_duration = meter.create_histogram(
    name="http_request_duration_seconds",
    description="HTTP request duration in seconds",
    unit="s",
)

# Traffic counter
request_total = meter.create_counter(
    name="http_requests_total",
    description="Total HTTP requests",
)

# Error counter
request_errors = meter.create_counter(
    name="http_request_errors_total",
    description="Total HTTP request errors",
)

# Saturation gauge (e.g., active connections)
active_connections = meter.create_up_down_counter(
    name="http_active_connections",
    description="Active HTTP connections",
)

# Per-request recording
def record_request(method: str, path: str, status: int, duration: float):
    labels = {"method": method, "path": path, "status": str(status)}
    request_duration.record(duration, attributes=labels)
    request_total.add(1, attributes=labels)
    if status >= 500:
        request_errors.add(1, attributes=labels)
```

**Go, TypeScript, Java, Rust:** Same four instruments using the OpenTelemetry SDK for your language — `Float64Histogram` for duration, `Int64Counter` for requests and errors, `Int64UpDownCounter` for saturation. API is consistent across languages; only import paths differ.

### Metric naming convention

Follow OpenTelemetry semantic conventions (opentelemetry.io/docs/specs/semconv/):
- `http.request.duration` (histogram) — latency per endpoint
- `http.requests.total` or `http.server.request.count` (counter) — traffic
- `http.request.errors.total` (counter) — errors  
- `process.runtime.*.memory.usage` / `db.pool.connections` (gauges) — saturation

OTel Counter → Prometheus adds `_total` suffix automatically.
OTel Histogram → Prometheus generates `_bucket`, `_sum`, `_count`.

---

## SLO Definition Document

Save to: `.ai/observability/YYYY-MM-DD-slos.md`

````markdown
# Service Level Objectives — [Service Name]

**Date:** YYYY-MM-DD
**Author:** [name]
**Service:** [service name]
**Spec:** `.ai/specs/YYYY-MM-DD-<feature>.md`
**Revisit:** YYYY-MM-DD (quarterly)

---

## Service Overview

[1-2 sentences: what the service does, who uses it, what "working" means from a user's perspective]

---

## SLIs and SLOs

*SLI = measurement. SLO = target. Error budget = 100% - SLO.*
*Source: Google SRE Workbook slo-document format*

| Endpoint / Journey | SLI Definition | SLO Target | Window | Error Budget |
|--------------------|---------------|------------|--------|-------------|
| `POST /api/checkout` | % requests with status < 500 AND duration < 500ms | 99.9% | 28 days | 0.1% = 43.2 min/month |
| `GET /api/products` | % requests with status < 500 AND duration < 200ms | 99.95% | 28 days | 0.05% = 21.6 min/month |
| [user journey name] | [formula: good_events / total_events] | [%] | 28 days | [100% - SLO] |

*Targets pulled from NFRs in spec. If no NFR specified: default availability SLO = 99.9%, latency SLO = p99 < 500ms.*

---

## Error Budget Policy

When the error budget is exhausted:
- [ ] Stop new feature work
- [ ] Freeze non-critical deploys
- [ ] Engineering focus shifts to reliability
- [ ] Budget resets at window start

When burning at > 2× expected rate (burn rate alert):
- [ ] Page on-call immediately
- [ ] Escalate if not resolved within 1 hour
- [ ] Postmortem if downtime > 30 minutes

---

## Clarifications and Caveats

- Planned maintenance windows excluded from SLO calculation: [define window]
- Measurement point: [load balancer / service ingress / specific endpoint]
- "Good request" definition: [exact criteria — status code range AND latency threshold]
````

---

## Alert Rules

Save to: `wiki/guides/alerts.md`

**Core principle (PagerDuty):** Alert on **symptoms** (users are affected), not **causes** (system internals). CPU > 80% goes on a dashboard. p99 latency > SLO threshold pages.

````markdown
# Alert Rules — [Service Name]

**Platform:** [Prometheus/Alertmanager | Datadog | Grafana | CloudWatch | PagerDuty]

## Alerting Principles

- Page on user impact: latency, error rate, availability
- Dashboard-only: CPU, memory, disk (causes, not symptoms)
- Burn rate alerts preferred over threshold alerts (catches slow degradation)
- Every alert has exactly one runbook linked

---

## Alert Definitions

### HIGH_ERROR_RATE
**Condition:** `rate(http_request_errors_total[5m]) / rate(http_requests_total[5m]) > 0.01`
**Severity:** P1 (page immediately)
**Runbook:** `wiki/guides/runbooks/alert-high-error-rate.md`
**Rationale:** > 1% error rate sustained 5 minutes = users experiencing failures

### HIGH_LATENCY_P99
**Condition:** `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > <SLO_THRESHOLD>`
**Severity:** P1 (page immediately)
**Runbook:** `wiki/guides/runbooks/alert-high-latency.md`
**Rationale:** p99 above SLO threshold = users experiencing slowness at tail

### ERROR_BUDGET_BURN_FAST
**Condition:** error budget consuming at > 2× expected rate over 1-hour window
**Severity:** P1 (page immediately)
**Runbook:** `wiki/guides/runbooks/alert-budget-burn.md`
**Rationale:** Burns entire monthly budget in < 2 days — stop and investigate

### ERROR_BUDGET_BURN_SLOW
**Condition:** error budget consuming at > 5× expected rate over 6-hour window
**Severity:** P2 (notify, investigate within business hours)
**Runbook:** `wiki/guides/runbooks/alert-budget-burn.md`
**Rationale:** Slow burn visible in 6hr window — investigate before budget exhausted

### NO_TRAFFIC
**Condition:** `rate(http_requests_total[10m]) == 0` during expected business hours
**Severity:** P2
**Runbook:** `wiki/guides/runbooks/alert-no-traffic.md`
**Rationale:** Zero traffic during business hours = upstream routing failure or service down

### SATURATION_HIGH
**Condition:** `<saturation_metric> > 0.8` (> 80% of capacity)
**Severity:** P2
**Runbook:** `wiki/guides/runbooks/alert-saturation.md`
**Rationale:** 80% saturation = performance degradation imminent; 85% = hard limit
````

**Prometheus/Alertmanager YAML (if applicable):**
```yaml
groups:
  - name: service-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          rate(http_request_errors_total[5m])
          / rate(http_requests_total[5m]) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.service }}"
          runbook: "wiki/guides/runbooks/alert-high-error-rate.md"

      - alert: HighLatencyP99
        expr: |
          histogram_quantile(0.99,
            rate(http_request_duration_seconds_bucket[5m])
          ) > 0.5
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "p99 latency above SLO threshold"
          runbook: "wiki/guides/runbooks/alert-high-latency.md"
```

---

## Runbook Template

Save each runbook to: `wiki/guides/runbooks/alert-<name>.md`

````markdown
# Runbook: [ALERT_NAME]

**Alert:** `[ALERT_NAME]`
**Severity:** P1 / P2 / P3
**Service:** [service name]
**Dashboard:** [link to dashboard]

---

## What This Alert Means

[1-2 sentences: what condition fired, why it matters to users]

**User impact:** [what the user experiences when this alert fires]

---

## Immediate Diagnosis (first 5 minutes)

1. Check dashboard: [dashboard URL] → look at [specific panel]
2. Check recent deploys: `git log --oneline -10` or deployment history
3. Run diagnostic query:
   ```
   [specific log query or metric query for this alert]
   ```
4. Check dependencies: [upstream services, databases, external APIs]

---

## Remediation

*If cause is [known cause A]:*
1. [Step 1 — exact command or action]
2. [Step 2]
3. Verify: [how to confirm fix worked — specific metric or log to check]

*If cause is [known cause B]:*
1. [Step 1]
2. Verify: [specific check]

*If cause unknown:*
1. Check error logs: `[query]`
2. Check recent config changes
3. Escalate (see below)

---

## Verification

Alert should resolve within [N] minutes of fix. Confirm:
- [ ] Error rate returns to < 0.1%
- [ ] p99 latency returns to < [SLO threshold]
- [ ] Alert clears in alerting system

---

## Escalation

If not resolved within **30 minutes**:
- Page: [escalation contact or rotation name]
- Channel: [Slack channel]
- Context to provide: [what information to include when escalating]

---

## Related

- [Link to related runbooks]
- [Link to postmortem docs if applicable]
````

---

## Project Observability Standards Document

Save to: `wiki/guides/observability.md` — single source of truth for this project's observability conventions.

```markdown
# Observability Standards — [Project Name]

## Structured Logging

- Library: [structlog | pino | log/slog | tracing | logback]
- Format: JSON, UTF-8
- Required fields: timestamp (ISO 8601 UTC), severity, trace_id, span_id, service.name, body
- PII fields: NEVER log — [list PII fields in this project]
- Log levels: ERROR (pages oncall) | WARN (investigate) | INFO (normal operation) | DEBUG (dev only)

## Metrics

- SDK: OpenTelemetry [version]
- Backend: [Prometheus | Datadog | CloudWatch]
- Naming: OpenTelemetry semantic conventions (opentelemetry.io/docs/specs/semconv/)
- Per endpoint: request_duration histogram, requests_total counter, errors_total counter
- Retention: [N days raw, N months aggregated]

## SLOs

- Document: `.ai/observability/YYYY-MM-DD-slos.md`
- Window: 28 days rolling
- Review cadence: quarterly

## Alerts

- Rules: `wiki/guides/alerts.md`
- Principle: symptom-based (user impact), not cause-based (system internals)
- Every alert links to a runbook

## Runbooks

- Location: `wiki/guides/runbooks/alert-<name>.md`
- Required sections: what it means, immediate diagnosis, remediation, verification, escalation
```

---

## Self-Review: Run `observability-reviewer` Agent

After generating all artifacts, before committing:

```
Agent(observability-reviewer, {
  SLO_PATH: ".ai/observability/YYYY-MM-DD-slos.md",
  ALERTS_PATH: "wiki/guides/alerts.md",
  RUNBOOK_DIR: "wiki/guides/runbooks/",
  SPEC_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md"
})
```

Fix all **Critical** findings. **Important** findings should be fixed. Advisory may be deferred.

---

## Commit

Stage observability artifacts in a single commit:
```
feat(observability): add structured logging, golden signals, SLOs, and runbooks

[body: WHY — what would be unobservable without this, which signals are now tracked]
```

Instrumentation code commits with the endpoint code — not in a separate later commit.
