---
name: api-versioning
description: >
  Use during api-contract-first or high-level-design for any externally-facing API. Produces a versioning strategy ADR (URL path vs header vs content negotiation, with Stripe/Kubernetes evidence), a breaking-change policy defining what requires a new version, a deprecation timeline with Sunset header implementation, and a migration guide template. Adds oasdiff to CI to detect breaking changes automatically. Runs api-versioning-reviewer before committing.
---

# API Versioning Strategy

An API without a versioning strategy is an API that cannot evolve without breaking consumers. A versioning strategy without a documented breaking change policy is a versioning strategy that breaks consumers accidentally.

## References

- **Stripe API versioning** (stripe.com/blog/api-versioning) — account pinned to latest at first use; `Stripe-Version` header for override; additive changes never bump version; breaking changes get new version date
- **Kubernetes resource versioning** — `v1alpha1 → v1beta1 → v1`; promotion criteria for each stage; deprecation per version, not per field
- **RFC 8594** (Sunset HTTP Header) — machine-readable deprecation: `Sunset: Wed, 31 Dec 2025 23:59:59 GMT`; `Link: rel="successor-version"`
- **oasdiff** (github.com/tufin/oasdiff) — OpenAPI diff tool for breaking change detection in CI
- **Speakeasy API Design Guide** (speakeasy.com/api-design/versioning) — backward compatibility rules

---

## When to Use

**Required** for any externally-facing API that:
- Will be consumed by clients outside this team or service
- Is expected to evolve over more than one release
- Has SLA/contract obligations with consumers

**Skip** for: internal-only services with a single consumer, prototype/alpha APIs marked as such, CLI-only tools with no HTTP interface.

**Infer + confirm:**
> "This is an internal service with one consuming team. Skipping formal API versioning strategy. Should I add it anyway for future-proofing, or is internal coordination sufficient?"

---

## Strategy Selection

Choose once at project start. Document in an ADR. The choice affects every consumer forever.

| Strategy | Mechanism | Best for | Stripe/K8s equivalent |
|----------|-----------|---------|----------------------|
| **URL path** (recommended for REST) | `/v1/users`, `/v2/users` | Public APIs, REST, easy to route and document | Kubernetes `/apis/apps/v1/` |
| **Header** | `X-API-Version: 2025-06-01` or `Stripe-Version: 2024-06-20` | APIs where URL should be stable, date-based versioning | Stripe, GitHub |
| **Content negotiation** | `Accept: application/vnd.api.v2+json` | Hypermedia APIs, advanced clients | RFC 6906 |
| **Query parameter** | `?version=2` | Last resort — pollutes query space, breaks caching | Avoid unless legacy constraint |

**Default recommendation: URL path versioning for new REST APIs.** Simple, explicit, easy to document, easy to proxy/route.

---

## Outputs

### 1. Versioning Strategy ADR

Save to: `wiki/architecture/ADR-NNN-api-versioning.md`

````markdown
# ADR-NNN: API Versioning Strategy

**Status:** Accepted
**Date:** YYYY-MM-DD

## Context and Problem Statement

[This API will be consumed by [N external teams / public clients / internal services].
It must evolve without breaking existing consumers. What versioning strategy minimizes
consumer disruption while enabling safe API evolution?]

## Considered Options

- URL path versioning (`/v1/`, `/v2/`)
- Date-based header versioning (`Stripe-Version: YYYY-MM-DD`)
- Content negotiation (`Accept: vnd.api.v2+json`)
- No formal versioning (ad-hoc)

## Decision Outcome

**Chosen: [URL path / Header / Content negotiation]**

[One sentence rationale: why this strategy fits the API's consumer profile and evolution pace.]

### Consequences

**Positive:**
- [specific benefit given the chosen approach]

**Negative:**
- [specific trade-off]

## Breaking Change Policy

These changes REQUIRE a new version (breaking — consumer code will break):
- Removing a field from a response
- Changing a field's type (string → integer)
- Making an optional field required
- Changing an error code or error response shape
- Removing or renaming an endpoint
- Changing HTTP method for an operation

These changes are SAFE (non-breaking — consumers can ignore them):
- Adding a new optional field to a response
- Adding a new optional query parameter
- Adding a new endpoint
- Adding a new enum value (⚠️ may break strict decoders — document it)
- Updating descriptions, examples, documentation
- Performance improvements with same behavior

## Current Version

`v1` — initial API surface as of [date].

## Deprecation Policy

- Minimum notice period: [12 months] before removing a version
- Sunset header added on day 1 of deprecation announcement
- Migration guide published before deprecation announcement
- Usage analytics checked before retirement date
````

---

### 2. Versioning Policy Document

Save to: `wiki/guides/api-versioning-policy.md`

```markdown
# API Versioning Policy — [Service Name]

**Strategy:** [URL path / Header / Content negotiation]
**Current stable version:** v[N]
**Previous versions supported:** [list with EOL dates]

## Version Lifecycle

| Stage | Definition | Consumer action |
|-------|-----------|----------------|
| alpha (v1alpha1) | Unstable, may change without notice | Do not use in production |
| beta (v1beta1) | Feature complete, API may change with notice | Use with caution |
| stable (v1) | No breaking changes without new major version | Safe for production |

## Deprecation Timeline

When a breaking change requires a new version:

1. **Month 0:** New version released. Old version marked deprecated.
   - Add `Deprecation: true` header to all old version responses
   - Add `Sunset: [date 12 months away]` header (RFC 8594)
   - Add `Link: <[new version URL]>; rel="successor-version"` header
   - Publish migration guide
2. **Month 3:** Email/notification to all registered API consumers
3. **Month 6:** Warning in response body: `"deprecation_warning": "This API version retires on [date]"`
4. **Month 9:** Rate limiting on deprecated version (50% of normal quota)
5. **Month 12:** Return `410 Gone` with migration guide URL

## Adding Sunset Headers (implementation)

For URL path versioning:
```python
# Flask/FastAPI middleware
@app.middleware("http")
async def add_deprecation_headers(request: Request, call_next):
    response = await call_next(request)
    if request.url.path.startswith("/v1/"):
        response.headers["Deprecation"] = "true"
        response.headers["Sunset"] = "Wed, 31 Dec 2026 23:59:59 GMT"
        response.headers["Link"] = '</v2/>; rel="successor-version"'
    return response
```

```go
// Go middleware
func DeprecationMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if strings.HasPrefix(r.URL.Path, "/v1/") {
            w.Header().Set("Deprecation", "true")
            w.Header().Set("Sunset", "Wed, 31 Dec 2026 23:59:59 GMT")
            w.Header().Set("Link", `</v2/>; rel="successor-version"`)
        }
        next.ServeHTTP(w, r)
    })
}
```
```

---

### 3. Migration Guide Template

For every breaking change, create: `wiki/api/migration-v{N}-to-v{N+1}.md`

```markdown
# Migration Guide: v[N] → v[N+1]

**Breaking changes in v[N+1]:**

## Change 1: [Field name change]

**v[N] (old):**
```json
{ "user_id": 123 }
```

**v[N+1] (new):**
```json
{ "id": "usr_abc123" }
```

**Why:** [reason — integer IDs were leaking database implementation; UUID strings are stable]

**Migration steps:**
1. Update your client to read `id` instead of `user_id`
2. Update any storage of this field (databases, caches)
3. Test: `curl /v2/users/me` should return `id` field

**Timeline:** v[N] retires [date]. v[N+1] is stable now.
```

---

### 4. CI Breaking Change Detection

Add to CI pipeline (runs on every PR that changes `api/openapi.yaml`):

**GitHub Actions:**
```yaml
  api-breaking-change-check:
    name: API Breaking Change Detection
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Install oasdiff
        run: |
          curl -fsSL https://raw.githubusercontent.com/tufin/oasdiff/main/install.sh | sh
      - name: Check for breaking changes
        run: |
          # Compare current branch spec against base branch spec
          git show origin/${{ github.base_ref }}:api/openapi.yaml > /tmp/base-spec.yaml
          oasdiff breaking /tmp/base-spec.yaml api/openapi.yaml \
            --fail-on ERR \
            --format text
        # Exits non-zero if breaking changes detected → PR blocked
```

**When oasdiff detects breaking changes:**
1. The CI job fails and blocks the PR
2. Developer must either: (a) confirm the change is intentional and create a new API version, OR (b) revert the breaking change
3. To override intentionally: add `<!-- breaking-change: intentional, new version v2 created -->` to PR description

---

## Reviewer Dispatch Discipline

When dispatching the reviewer agent:
- Pass artifact as a file path, not pasted content — pasted reviewer reports stay resident in context for the rest of the session
- Do not pre-judge findings — never instruct the reviewer to ignore or not flag a specific issue, and never pre-rate severity ("treat X as Minor at most")
- If the reviewer returns findings: dispatch ONE fix agent with the complete findings list, not one fixer per finding
- Re-dispatch the same reviewer after fixes; repeat until PASS
- A ⚠️ item from the reviewer is yours to resolve — you hold cross-document context the reviewer lacks; treat confirmed gaps as a failed review
- Pattern check before re-dispatch: does this finding's pattern recur elsewhere in the artifact? Fix every occurrence in the same pass — a finding that resurfaces next cycle in a new spot is the cost this discipline exists to cut

## Self-Review: Run `api-versioning-reviewer` Agent

After producing all artifacts:

```
Agent(api-versioning-reviewer, {
  ADR_PATH: "wiki/architecture/ADR-NNN-api-versioning.md",
  POLICY_PATH: "wiki/guides/api-versioning-policy.md",
  OPENAPI_PATH: "api/openapi.yaml"
})
```

Fix all **Critical** findings before committing.
