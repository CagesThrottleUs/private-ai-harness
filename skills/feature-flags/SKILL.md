---
name: feature-flags
description: >
  Use when deploying a feature that should be decoupled from release, or when gradual rollout / A/B testing is needed. Produces a naming convention and flag registry (wiki/guides/feature-flag-registry.md), OpenFeature SDK setup code, progressive rollout pattern (1%→10%→50%→100%), and a CI flag hygiene check that blocks merges when flags have expired. Runs feature-flag-reviewer before committing. Deploy at 100%, release at 1% — feature flags make this the default, not the exception.
---

# Feature Flags

The difference between deployment and release: deployment is code reaching production; release is users experiencing the feature. Feature flags decouple these — you can deploy at any time and release when the business is ready. Canary releases, A/B tests, instant rollbacks, and permission gates all become standard operations.

## References

- **OpenFeature** (openfeature.dev) — CNCF project; vendor-neutral standard for feature flag evaluation. Works with any backend (LaunchDarkly, GrowthBook, DevCycle, environment variables)
- **LaunchDarkly Feature Management Guide** (launchdarkly.com/the-definitive-guide-to-feature-management) — progressive delivery, naming conventions, lifecycle management
- **Octopus Deploy: 12 Commandments of Feature Flags** (octopus.com/devops/feature-flags/feature-flag-best-practices) — treat flags as technical debt; enforce expiry from creation
- **ConfigCat Blog** (configcat.com/blog/feature-flag-best-practices) — naming, canary rollout, cleanup patterns

---

## When to Use

**Required** when:
- Deploying a risky feature to production without exposing it to all users immediately
- Gradual rollout needed (1% → 10% → 50% → 100%)
- A/B test or experiment on a subset of users
- Kill switch needed for an operation (disable a payment provider, throttle a heavy query)
- Permission gate needed (beta users, paying customers, internal users only)

**Skip** for: bug fixes going to all users immediately, infrastructure changes, docs-only changes.

**Infer + confirm:**
> "This adds a new payment flow. Should I set up a feature flag for gradual rollout, or ship to 100% immediately?"

---

## Flag Types and Naming

| Type | Prefix | Purpose | Expiry |
|------|--------|---------|--------|
| `release-` | release | Gradual rollout of a new feature | After reaching 100% rollout — remove within 2 sprints |
| `exp-` | experiment | A/B test or multivariate experiment | After experiment concludes |
| `ops-` | ops | Kill switch for operational control | Permanent (remove only by explicit decision) |
| `permission-` | permission | Access control (beta, premium, internal) | Permanent or until feature is GA |

**Naming convention:** `{type}-{feature}-{context}`

```
release-checkout-v2            ← new checkout flow gradual rollout
exp-checkout-button-color      ← A/B test on button color
ops-payment-provider-stripe    ← kill switch to disable Stripe
permission-admin-dashboard     ← admin-only feature
```

Rules: lowercase, hyphens only, descriptive, no version numbers in names (use context instead).

---

## Outputs

### 1. Flag Registry

Save to: `wiki/guides/feature-flag-registry.md`

```markdown
# Feature Flag Registry

**Last updated:** YYYY-MM-DD

All feature flags must be registered here before use.
Flags without an expiry date or owner are flagged by CI.

| Flag key | Type | Owner | Created | Expiry | Rollout % | Status | Notes |
|----------|------|-------|---------|--------|-----------|--------|-------|
| `release-checkout-v2` | release | @[owner] | YYYY-MM-DD | YYYY-MM-DD | 5% | active | New checkout flow |
| `ops-payment-stripe` | ops | @payments-team | YYYY-MM-DD | permanent | — | active | Stripe kill switch |
| `exp-hero-copy` | experiment | @growth | YYYY-MM-DD | YYYY-MM-DD | 50% | active | A/B test hero section |

## Cleanup Queue

Flags that have reached 100% rollout and are pending code cleanup:

| Flag | Date reached 100% | Code cleanup deadline | Owner |
|------|-------------------|----------------------|-------|
| `release-old-feature` | YYYY-MM-DD | YYYY-MM-DD | @owner |
```

### 2. OpenFeature SDK Setup

**TypeScript/Node.js:**
```typescript
// lib/flags.ts
import { OpenFeature } from '@openfeature/server-sdk';

// Initialize with your provider (GrowthBook, LaunchDarkly, or environment variable fallback)
OpenFeature.setProvider(yourProvider);

const client = OpenFeature.getClient();

// Evaluate a flag with a fallback value
export async function isEnabled(
  flagKey: string,
  userId: string,
  defaultValue: boolean = false,
): Promise<boolean> {
  return client.getBooleanValue(flagKey, defaultValue, {
    targetingKey: userId,  // consistent per user
  });
}

// Usage:
// if (await isEnabled('release-checkout-v2', user.id)) { ... }
```

**Python:**
```python
# lib/flags.py
from openfeature import api
from openfeature.evaluation_context import EvaluationContext

client = api.get_client()

def is_enabled(flag_key: str, user_id: str, default: bool = False) -> bool:
    ctx = EvaluationContext(targeting_key=user_id)
    return client.get_boolean_value(flag_key, default, ctx)
```

**Go:**
```go
// lib/flags/flags.go
import (
    openfeature "github.com/open-feature/go-sdk/pkg/openfeature"
)

func IsEnabled(flagKey, userID string, defaultValue bool) (bool, error) {
    client := openfeature.NewClient("app")
    ctx := openfeature.NewEvaluationContext(userID, nil)
    return client.BooleanValue(context.Background(), flagKey, defaultValue, ctx)
}
```

### 3. Progressive Rollout Pattern

```typescript
// Canary rollout: stable per-user percentage via consistent hash
// Hash user UUID → determine if they're in the rollout group

function isInRollout(userId: string, flagKey: string, percentage: number): boolean {
  const hash = crypto.createHash('sha256')
    .update(`${flagKey}:${userId}`)
    .digest('hex');
  const bucket = (parseInt(hash.substring(0, 8), 16) % 10000) / 100;
  return bucket < percentage;
}

// Rollout stages — update registry at each stage:
// Day 1:  1% — internal testing, monitor error rate
// Day 3:  5% — canary, monitor SLOs
// Week 1: 25% — limited beta
// Week 2: 50% — wide beta
// Week 3: 100% — GA, schedule cleanup
```

### 4. CI Flag Hygiene Check

Add to CI — fails if any flag in the registry is past its expiry date:

```yaml
# In .github/workflows/ci.yml
  flag-hygiene:
    name: Feature Flag Hygiene
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check expired flags
        run: |
          python3 - << 'EOF'
          import re, sys
          from datetime import date

          with open('wiki/guides/feature-flag-registry.md') as f:
              content = f.read()

          today = date.today().isoformat()
          # Find rows with expiry dates that have passed
          rows = re.findall(r'\| `([^`]+)` \| \w+ \| [^|]+ \| \d{4}-\d{2}-\d{2} \| (\d{4}-\d{2}-\d{2}) \|', content)
          expired = [(key, expiry) for key, expiry in rows if expiry < today]

          if expired:
              print("EXPIRED FLAGS - must be cleaned up before merging:")
              for key, expiry in expired:
                  print(f"  {key} (expired: {expiry})")
              sys.exit(1)
          print("All flags are within their expiry dates.")
          EOF
```

---

## Flag Lifecycle

Every non-permanent flag must go through this lifecycle:

```
1. CREATE — add to registry with owner + expiry date
2. DEPLOY — ship code with flag evaluation (flag starts at 0%)
3. ROLLOUT — increase percentage: 1% → 5% → 25% → 50% → 100%
4. MONITOR — watch error rate, SLO, and user metrics at each stage
5. EVALUATE — at 100%: does the feature work? Is the A/B test concluded?
6. CLEANUP — remove flag from code + registry within 2 sprints of reaching 100%
```

**Cleanup means:**
- Delete the flag evaluation call from code
- Delete the old code path (the code behind `else { /* old behavior */ }`)
- Update tests (tests for both paths → tests for one path)
- Remove from registry
- Commit with: `chore: remove release-checkout-v2 flag (fully rolled out)`

---

## Self-Review: Run `feature-flag-reviewer` Agent

```
Agent(feature-flag-reviewer, {
  REGISTRY_PATH: "wiki/guides/feature-flag-registry.md",
  CODE_PATH: "src/"  // optional: scan for flag evaluations
})
```

Fix all **Critical** findings before committing.
