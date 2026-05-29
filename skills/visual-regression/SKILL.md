---
name: visual-regression
description: >
  Use for UI-bearing features after E2E tests are written. Adds Playwright's built-in toHaveScreenshot() on every critical page (zero new dependencies), disables animations for consistent captures, commits baseline snapshots to git, and adds a CI visual comparison job. Documents the baseline update workflow. Runs visual-regression-reviewer before committing. E2E tests verify user flows work; visual regression tests verify they still look right.
---

# Visual Regression Testing

E2E tests verify that a checkout flow completes. Visual regression tests verify that the checkout form still looks like the checkout form — not a broken layout with missing buttons and overlapping text. Both catch different bugs.

## References

- **Playwright visual comparisons** (playwright.dev/docs/test-snapshots) — `toHaveScreenshot()` built in, zero dependencies beyond Playwright
- **Pixelmatch** (github.com/mapbox/pixelmatch) — Playwright's underlying diff library
- **Chromatic** (chromatic.com) — optional: for Storybook component libraries, cloud-hosted baseline management
- **Percy** (percy.io) — optional: cross-browser screenshot comparison, BrowserStack integration

---

## When to Use

**Required** for UI features that have visual design intent (not just functional behavior):
- Marketing/landing pages where layout matters
- Design system components
- Form layouts with specific field arrangement
- Dashboard views with data visualization
- Any page where a CSS regression would go unnoticed in functional E2E tests

**Skip** for: API-only services, admin-only internal tools with no design requirements, pages that are purely functional with no layout-sensitive design.

**Infer + confirm:**
> "This is an internal admin tool with no design spec — layout isn't a concern beyond basic usability. Skipping visual regression. OK?"

---

## Tool Selection

| Approach | When | Setup | Cost |
|---------|------|-------|------|
| **Playwright `toHaveScreenshot()`** (default) | Page-level, full-page, no cloud | Zero deps beyond Playwright | Free |
| **Chromatic** | Storybook component library, isolation | Storybook integration | $149/mo+ |
| **Percy** | Cross-browser, multi-device | Playwright/Cypress plugin | Paid |

Default: **Playwright built-in**. Used here.

---

## Setup

No new dependencies — Playwright already installed from `e2e-testing`.

### `playwright.config.ts` additions

```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  // ... existing config ...

  expect: {
    toHaveScreenshot: {
      maxDiffPixels: 100,       // pixel budget — adjust based on content density
      threshold: 0.1,           // per-pixel color difference tolerance (0-1)
      animations: 'disabled',   // always — animated elements = flaky screenshots
    },
  },

  // Snapshots stored in tests/visual/__snapshots__/
  // These MUST be committed to git
  snapshotPathTemplate: '{testDir}/visual/__snapshots__/{projectName}/{testFilePath}/{arg}{ext}',
});
```

### Test structure

```
tests/
├── e2e/           ← functional E2E tests (user journeys)
└── visual/        ← visual regression tests (appearance)
    ├── __snapshots__/        ← baseline PNGs — COMMITTED TO GIT
    │   └── chromium/
    │       └── homepage.png
    ├── pages/
    │   ├── homepage.visual.ts
    │   └── checkout.visual.ts
    └── components/
        └── forms.visual.ts
```

---

## Test Templates

### Page-level visual test

```typescript
// tests/visual/pages/homepage.visual.ts
import { test, expect } from '@playwright/test';

test.describe('Homepage visual regression', () => {
  test.beforeEach(async ({ page }) => {
    // Disable all animations — critical for consistent screenshots
    await page.addStyleTag({
      content: `
        *, *::before, *::after {
          transition-duration: 0ms !important;
          animation-duration: 0ms !important;
          animation-delay: 0ms !important;
        }
      `,
    });
  });

  test('homepage renders correctly', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');  // wait for all resources

    await expect(page).toHaveScreenshot('homepage.png', {
      fullPage: true,
      // Mask dynamic content that changes per render
      mask: [
        page.locator('[data-testid="user-avatar"]'),  // user-specific
        page.locator('[data-testid="timestamp"]'),    // time-based
        page.locator('.ad-banner'),                   // third-party ads
      ],
    });
  });

  test('homepage on mobile viewport', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });  // iPhone 13
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveScreenshot('homepage-mobile.png');
  });
});
```

### Critical component visual test

```typescript
// tests/visual/components/checkout-form.visual.ts
import { test, expect } from '@playwright/test';

test.describe('Checkout form', () => {
  test('default state', async ({ page, context }) => {
    // Use auth fixture from e2e-testing
    await page.goto('/checkout');
    await page.waitForSelector('[data-testid="checkout-form"]');

    // Screenshot a specific component, not the whole page
    const form = page.locator('[data-testid="checkout-form"]');
    await expect(form).toHaveScreenshot('checkout-form-default.png');
  });

  test('validation error state', async ({ page }) => {
    await page.goto('/checkout');
    await page.getByRole('button', { name: 'Place Order' }).click();
    // Wait for validation errors to appear
    await page.waitForSelector('[data-testid="field-error"]');

    const form = page.locator('[data-testid="checkout-form"]');
    await expect(form).toHaveScreenshot('checkout-form-errors.png');
  });
});
```

---

## Baseline Management

### First run — creates baselines

```bash
npx playwright test tests/visual/ --update-snapshots
```

Commits the `tests/visual/__snapshots__/` directory to git. These PNGs are the source of truth.

### When baselines need updating (intentional design change)

```bash
# Update all baselines after a deliberate redesign
npx playwright test tests/visual/ --update-snapshots

# Update just one baseline
npx playwright test tests/visual/pages/homepage.visual.ts --update-snapshots

# Then commit the updated snapshots
git add tests/visual/__snapshots__/
git commit -m "chore(visual): update homepage baseline after redesign"
```

**Never auto-update baselines in CI** — baseline updates must be a deliberate human decision.

### `.gitignore` check

Ensure `tests/visual/__snapshots__/` is NOT in `.gitignore`. These files must be committed.

---

## CI Integration

Visual tests must run on the **same OS and browser version** as the baseline was captured. Dockerfile ensures consistency.

```yaml
# Adds to .github/workflows/ci.yml — after staging deploy or after E2E tests
  visual-regression:
    name: Visual Regression Tests
    needs: [deploy-staging]
    runs-on: ubuntu-latest
    container:
      image: mcr.microsoft.com/playwright:v1.52.0-noble  # pin to exact version
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: npm ci
      - name: Run visual regression tests
        run: npx playwright test tests/visual/
        env:
          BASE_URL: ${{ vars.STAGING_URL }}
      - name: Upload diff on failure
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: visual-diff
          path: test-results/
          retention-days: 14
```

**On CI failure:** Download the `visual-diff` artifact to see the diff image (red highlights on changed pixels). If the change is intentional, update baselines locally and push.

---

## Flakiness Reduction

Common sources of flaky visual tests and how to fix them:

| Source | Fix |
|--------|-----|
| Animations running | Add `animations: 'disabled'` + CSS injection |
| Dynamic content (timestamps, avatars) | Use `mask: [page.locator(...)]` |
| Font loading | `await page.waitForLoadState('networkidle')` |
| Third-party content | Mask or block with `page.route()` |
| Platform differences | Pin Docker image version in CI |
| Pixel density differences | Set explicit `deviceScaleFactor: 1` in config |

---

## Self-Review: Run `visual-regression-reviewer` Agent

```
Agent(visual-regression-reviewer, {
  TEST_FILES: "tests/visual/**/*.visual.ts",
  SNAPSHOT_DIR: "tests/visual/__snapshots__"
})
```

Fix all **Critical** findings before committing.
