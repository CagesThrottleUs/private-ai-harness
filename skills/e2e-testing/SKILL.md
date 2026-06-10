---
name: e2e-testing
description: >
  Use before finishing-a-development-branch for any feature with user-facing behavior. Identifies the critical user journeys from spec REQ-NNN acceptance criteria, sets up Playwright (with Page Object Model, auth fixtures, semantic locators), adds WCAG 2.1/2.2 AA accessibility checks via axe-playwright on every critical page, and adds an E2E CI job against staging. Tests critical paths only. Runs e2e-reviewer and accessibility-reviewer agents before committing.
---

# E2E Testing

E2E tests are the thin top layer of the testing pyramid — not a replacement for unit and integration tests, but the only layer that verifies the full user journey from browser to database to external service and back. Unit tests verify logic. Integration tests verify component contracts. E2E tests verify that the system works for a user.

The adversarial framing matters: a suite that only covers success flows leaves rejection logic, permission enforcement, and validation errors unverified at the system level. Test what breaks, not just what works.

## References

- **Playwright** (playwright.dev) — #1 E2E framework 2025 (20-30M weekly NPM downloads, surpassed Cypress mid-2024)
- **Microsoft Engineering Fundamentals** (microsoft.github.io/code-with-engineering-playbook/automated-testing/e2e-testing/) — E2E for critical user journeys; `main` branch always shippable
- **Netflix testing strategy** — PR pipeline E2E suite under 30 minutes; post-merge suite under 120 minutes
- **Playwright best practices** (playwright.dev/docs/best-practices) — semantic locators, auto-waiting, POM, fixtures
- **Shopware E2E guide** (frontends.shopware.com/best-practices/testing/e2e-testing) — POM structure, fixture reuse

---

## The Rule: Cover Journeys, Not Pages

**Test 5-10 critical user journeys per feature. Never test every page.**

A critical user journey is a sequence of actions that represents a core business operation. E2E tests exist to answer: "Does the system work for users?" Not: "Does every button exist?"

| ✅ Critical journey (test this) | ❌ Page coverage (don't test this) |
|--------------------------------|-----------------------------------|
| User registers, verifies email, logs in | Header renders correctly |
| User adds item to cart and checks out | Footer links work |
| User creates a resource, edits it, deletes it | 404 page shows |
| User searches and filters results | Sidebar navigation expands |
| Admin user can access settings that non-admin cannot | Styling matches design |

---

## When to Use

**Required** before `finishing-a-development-branch` for any feature that:
- Has a user-facing UI (web, mobile, CLI)
- Changes a critical user flow (auth, checkout, core CRUD, search)
- Has acceptance criteria that can only be verified end-to-end

**For API-only services** (no UI): E2E tests are HTTP integration tests covering the full request chain (auth → routing → handler → DB → response). Use Playwright's `request` API or `curl`/`httpx` in a CI test script.

**Skip** for: internal utilities, config changes, refactors with no user-flow change.

**Infer + confirm:**
> "This adds a backend utility with no user-facing endpoints or UI changes. Skipping e2e-testing. Correct?"

---

## Critical Journey Identification

**Read the spec REQ-NNN acceptance criteria.** Every AC that says "when user does X, the system shows Y" is a candidate E2E test.

**Prioritize by blast radius:**
1. Auth flows (login, logout, session expiry) — if broken, nothing else works
2. Money/payment flows — highest business risk
3. Core CRUD (create/edit/delete the primary resource) — most-used operations
4. Permission boundaries (admin vs. regular user) — security properties
5. Search/filter on the primary resource — high usage

**For each journey, also test the rejection path:**
- Auth: failed login (wrong credentials), session expiry redirect
- CRUD: create with invalid data (validation error shown), access resource owned by another user (403/redirect)
- Payment: declined card, insufficient balance
- Permissions: non-admin attempts admin-only action → rejected, not only that admin succeeds

A journey tested only on the success path is half a test.

**Target 5-10 tests for a typical feature.** Suite runtime target: < 15 minutes in CI.

---

## Playwright Setup

**Detect or ask:** What is the application type? (web browser / CLI / API)

**Install (TypeScript — recommended):**
```bash
npm init playwright@latest
# Choose: TypeScript, tests/ folder, yes to GitHub Actions
```

**`playwright.config.ts`:**
```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30_000,          // per test
  expect: { timeout: 5_000 },
  fullyParallel: true,
  forbidOnly: !!process.env.CI,  // fail if test.only left in CI
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? '50%' : undefined,
  reporter: [
    ['html', { open: 'never' }],
    ['junit', { outputFile: 'test-results/e2e-results.xml' }],
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    // Add Firefox/WebKit only if cross-browser matters for this feature
    // { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
  ],
});
```

---

## Test Structure

```
tests/e2e/
├── fixtures/
│   ├── auth.ts          ← authenticated user fixture
│   └── test-data.ts     ← test data factory for E2E state
├── pages/               ← Page Object Model
│   ├── login.page.ts
│   ├── dashboard.page.ts
│   └── [resource].page.ts
└── [feature]/
    ├── auth.spec.ts
    ├── [resource].crud.spec.ts
    └── [permission].spec.ts
```

---

## Page Object Model

Locators and actions in page objects. Test specs contain only assertions and user-intent steps.

```typescript
// tests/e2e/pages/login.page.ts
import { type Page, type Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    // ✅ Semantic locators — resilient to CSS/DOM changes
    this.emailInput = page.getByLabel('Email');
    this.passwordInput = page.getByLabel('Password');
    this.submitButton = page.getByRole('button', { name: 'Sign in' });
    this.errorMessage = page.getByRole('alert');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}
```

**Selector priority (most to least resilient):**
1. `getByRole('button', { name: '...' })` — ARIA semantics, survives style changes
2. `getByLabel('Email')` — form labels, survives DOM structure changes
3. `getByText('Submit')` — exact text, fragile with i18n but clear intent
4. `getByTestId('submit-btn')` — use `data-testid` attribute when no semantic option
5. CSS selector `.submit-btn` — LAST RESORT, couples to implementation

**Never use:** `page.waitForTimeout(3000)` — always wait for a specific condition instead.

---

## Auth Fixtures

Reusable authentication state — avoids repeating login UI in every test.

```typescript
// tests/e2e/fixtures/auth.ts
import { test as base } from '@playwright/test';
import { LoginPage } from '../pages/login.page';

type AuthFixtures = {
  authenticatedPage: Page;
  adminPage: Page;
};

export const test = base.extend<AuthFixtures>({
  // Standard user — authenticated via UI once, state saved to storageState
  authenticatedPage: async ({ browser }, use) => {
    const context = await browser.newContext();
    const page = await context.newPage();
    const loginPage = new LoginPage(page);
    
    await loginPage.goto();
    await loginPage.login(
      process.env.TEST_USER_EMAIL!,
      process.env.TEST_USER_PASSWORD!,
    );
    await page.waitForURL('/dashboard');
    
    await use(page);
    await context.close();
  },

  // Admin user — separate context, separate credentials
  adminPage: async ({ browser }, use) => {
    const context = await browser.newContext();
    const page = await context.newPage();
    const loginPage = new LoginPage(page);
    
    await loginPage.goto();
    await loginPage.login(
      process.env.TEST_ADMIN_EMAIL!,
      process.env.TEST_ADMIN_PASSWORD!,
    );
    await page.waitForURL('/dashboard');
    
    await use(page);
    await context.close();
  },
});

export { expect } from '@playwright/test';
```

**Performance note:** Use `storageState` to persist auth session across tests — saves the login UI round-trip:
```typescript
// Setup: save authenticated state once
await page.context().storageState({ path: '.auth/user.json' });

// Use: load pre-authenticated state  
const context = await browser.newContext({ storageState: '.auth/user.json' });
```

---

## Test Patterns

```typescript
// tests/e2e/resources/resource.crud.spec.ts
import { test, expect } from '../fixtures/auth';
import { ResourcePage } from '../pages/resource.page';

test.describe('Resource CRUD', () => {
  test('user can create a resource', async ({ authenticatedPage }) => {
    const resourcePage = new ResourcePage(authenticatedPage);
    
    await resourcePage.goto();
    await resourcePage.clickCreate();
    await resourcePage.fillName('My Test Resource');
    
    // ✅ Wait for navigation, not a timeout
    await resourcePage.submit();
    await authenticatedPage.waitForURL('/resources/*');
    
    // ✅ Assert on visible user-facing state, not DOM structure
    await expect(authenticatedPage.getByRole('heading', { name: 'My Test Resource' })).toBeVisible();
    await expect(authenticatedPage.getByText('Resource created')).toBeVisible();
  });

  test('user sees validation error on empty name', async ({ authenticatedPage }) => {
    const resourcePage = new ResourcePage(authenticatedPage);
    
    await resourcePage.goto();
    await resourcePage.clickCreate();
    await resourcePage.submit();  // no name filled
    
    await expect(authenticatedPage.getByRole('alert')).toContainText('Name is required');
  });

  test('admin can delete any resource', async ({ adminPage, authenticatedPage }) => {
    // Create as user
    const resourcePage = new ResourcePage(authenticatedPage);
    await resourcePage.createResource('To Be Deleted');
    const resourceId = await resourcePage.getCurrentResourceId();
    
    // Delete as admin
    const adminResourcePage = new ResourcePage(adminPage);
    await adminResourcePage.gotoById(resourceId);
    await adminResourcePage.delete();
    
    await expect(adminPage.getByText('Resource deleted')).toBeVisible();
    await adminPage.goto(`/resources/${resourceId}`);
    await expect(adminPage.getByRole('heading', { name: '404' })).toBeVisible();
  });
});
```

**Anti-patterns — never do these:**
```typescript
// ❌ Hardcoded wait
await page.waitForTimeout(3000);

// ❌ CSS selector coupling
await page.locator('.submit-btn.primary').click();

// ❌ Testing implementation, not behavior
await expect(page.locator('[data-state="active"]')).toBeVisible();

// ❌ Tests depending on previous test's state
test('create resource', ...) // modifies shared state
test('delete resource', ...)  // depends on previous test
```

---

## API-Only E2E Tests (No UI)

For pure API services, E2E tests verify the full request chain through the real deployed service:

```typescript
// tests/e2e/api/resources.e2e.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Resources API — E2E', () => {
  let authToken: string;

  test.beforeAll(async ({ request }) => {
    // Authenticate against real staging endpoint
    const response = await request.post(`${process.env.BASE_URL}/auth/token`, {
      data: { email: process.env.TEST_USER_EMAIL, password: process.env.TEST_USER_PASSWORD },
    });
    const body = await response.json();
    authToken = body.token;
  });

  test('authenticated user can create and retrieve a resource', async ({ request }) => {
    // Create
    const create = await request.post(`${process.env.BASE_URL}/resources`, {
      headers: { Authorization: `Bearer ${authToken}` },
      data: { name: 'E2E Test Resource' },
    });
    expect(create.status()).toBe(201);
    const { id } = await create.json();
    
    // Retrieve
    const get = await request.get(`${process.env.BASE_URL}/resources/${id}`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    expect(get.status()).toBe(200);
    const resource = await get.json();
    expect(resource.name).toBe('E2E Test Resource');
  });

  test('unauthenticated request is rejected', async ({ request }) => {
    const response = await request.get(`${process.env.BASE_URL}/resources`);
    expect(response.status()).toBe(401);
    const body = await response.json();
    expect(body.code).toBe('UNAUTHORIZED');
  });
});
```

---

## CI E2E Job

E2E tests run **after staging deploy** — not on every PR (too slow). Triggered after `deploy-staging` job succeeds.

**GitHub Actions:**
```yaml
# Adds after deploy-staging in .github/workflows/ci.yml
  e2e-tests:
    name: E2E Tests
    needs: [deploy-staging]
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - name: Run E2E tests against staging
        run: npx playwright test
        env:
          BASE_URL: ${{ vars.STAGING_URL }}
          TEST_USER_EMAIL: ${{ secrets.TEST_USER_EMAIL }}
          TEST_USER_PASSWORD: ${{ secrets.TEST_USER_PASSWORD }}
          TEST_ADMIN_EMAIL: ${{ secrets.TEST_ADMIN_EMAIL }}
          TEST_ADMIN_PASSWORD: ${{ secrets.TEST_ADMIN_PASSWORD }}
      - name: Upload Playwright report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 7
```

**Sharding** (when suite > 15 minutes):
```yaml
  e2e-tests:
    strategy:
      matrix:
        shard: [1/3, 2/3, 3/3]
    steps:
      - run: npx playwright test --shard ${{ matrix.shard }}
```

---

## Environment Variables Required

Document in `.env.example`:
```
BASE_URL=https://staging.example.com
TEST_USER_EMAIL=e2e-user@test.example
TEST_USER_PASSWORD=<set in CI secrets>
TEST_ADMIN_EMAIL=e2e-admin@test.example
TEST_ADMIN_PASSWORD=<set in CI secrets>
```

Test accounts must exist in staging environment and be dedicated to E2E (not shared with humans — test data gets modified).

---

## Accessibility Testing (WCAG 2.1 AA / 2.2 AA)

**Required for any UI-bearing feature.** The European Accessibility Act (June 2025) mandates WCAG 2.2 AA for EU-serving products. Axe-core catches 57% of WCAG issues automatically — run it on every critical page.

**References:**
- `@axe-core/playwright` (playwright.dev/docs/accessibility-testing) — official Playwright integration
- European Accessibility Act (June 2025) — WCAG 2.2 AA now legally required for EU
- axe-core (deque.com/axe) — 4B+ downloads, W3C ACT implementation

### Setup

```bash
npm install @axe-core/playwright
```

### Reusable helper

```typescript
// tests/e2e/fixtures/accessibility.ts
import AxeBuilder from '@axe-core/playwright';
import { type Page } from '@playwright/test';

/**
 * Run WCAG check on the current page.
 * @param page - Playwright page
 * @param wcagLevel - 'AA' for WCAG 2.1 AA (default), '22AA' for WCAG 2.2 AA (EU compliance)
 * @param include - CSS selector to scope scan (optional — scans full page by default)
 */
export async function checkAccessibility(
  page: Page,
  wcagLevel: 'AA' | '22AA' = 'AA',
  include?: string,
) {
  const tags = wcagLevel === '22AA'
    ? ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa']  // EU compliance
    : ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'];               // default

  let builder = new AxeBuilder({ page }).withTags(tags);
  if (include) builder = builder.include(include);
  return builder.analyze();
}
```

### Adding to critical path tests

```typescript
// tests/e2e/auth/login.spec.ts
import { test, expect } from '@playwright/test';
import { checkAccessibility } from '../fixtures/accessibility';

test('login page has no WCAG 2.1 AA violations', async ({ page }) => {
  await page.goto('/login');
  const results = await checkAccessibility(page);
  expect(results.violations).toEqual([]);
});

test('authenticated dashboard has no WCAG violations', async ({ authenticatedPage }) => {
  const results = await checkAccessibility(authenticatedPage);
  // If violations exist, format them for readable output
  if (results.violations.length > 0) {
    const formatted = results.violations.map(v => ({
      id: v.id,
      impact: v.impact,
      description: v.description,
      nodes: v.nodes.map(n => n.html).slice(0, 2),
    }));
    expect(formatted).toEqual([]);  // fails with readable diff
  }
});
```

### EU compliance (WCAG 2.2 AA)

If your business-context-intake compliance section includes EU users, use `'22AA'` level:

```typescript
const results = await checkAccessibility(page, '22AA');
expect(results.violations).toEqual([]);
```

### What axe catches (57% of WCAG issues)

✅ Automated: missing alt text, insufficient color contrast, missing form labels, keyboard trap, empty button text, improper heading hierarchy, missing ARIA landmarks.

❌ Requires manual testing: screen reader announcement quality, keyboard navigation flow, cognitive accessibility, animation sensitivity.

### Exclusions

Only exclude elements with documented justification:

```typescript
let builder = new AxeBuilder({ page })
  .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
  .exclude('#third-party-widget');  // vendor widget — accessibility outside our control, tracked in #1234
```

Never exclude entire pages or `body`. Exclusions are flagged by `accessibility-reviewer`.

### CI addition

Add to the E2E CI job (runs post-staging-deploy):
```yaml
      - name: Run accessibility checks
        run: npx playwright test --grep "@a11y"  # tag accessibility tests with @a11y
```

Or integrate into existing E2E run — no separate job needed if axe assertions are in the E2E specs.

---

## Self-Review: Run both `e2e-reviewer` and `accessibility-reviewer` Agents

```
Agent(accessibility-reviewer, {
  TEST_FILES: "tests/e2e/**/*.spec.ts",
  SPEC_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md",
  BUSINESS_CONTEXT_PATH: ".ai/business-context/YYYY-MM-DD-<feature>.md"  // for EU check
})
```

Fix all Critical findings from both agents before committing.

---

## Self-Review: Run `e2e-reviewer` Agent

After writing E2E tests, before committing:

```
Agent(e2e-reviewer, {
  TEST_FILES: "tests/e2e/**/*.spec.ts",
  SPEC_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md"
})
```

Fix all **Critical** findings (hardcoded waits, CSS selector brittleness, missing auth coverage). Fix **Important** findings (no POM, tests depending on order). Advisory may be deferred.

---

## Commit

```
test(e2e): add E2E tests for [critical user journey]

[body: WHY — what production failures unit/integration tests cannot catch,
which user journeys are covered, which are intentionally excluded]
```
