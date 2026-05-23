---
name: code-documentation
description: Use when writing or modifying any public function, class, module, or API endpoint — enforces full technical documentation at the point of authorship, not as a post-step
---

# Code Documentation

Document code at the moment of writing. Never as a cleanup step.

**Core principle:** A reader should understand what a function does, what it needs, what it returns, when it fails, and how to call it — without opening the implementation.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO PUBLIC SYMBOL WITHOUT COMPLETE DOCUMENTATION
```

"I'll document it later" = violating this rule. Document at the moment of writing.

---

## What to Document

### Public Functions / Methods

Every public function gets a docstring/JSDoc. No exceptions.

**Required fields:**

| Field | Required | Description |
|-------|----------|-------------|
| One-line summary | Always | What it does (not how) |
| `@param` / `:param` | If params exist | Name, type, description, whether optional |
| `@returns` / `:returns` | If not void | Type and what it means |
| `@throws` / `:raises` | If it can throw | What condition triggers it |
| `@example` | Always | One concrete, runnable example |

**TypeScript/JavaScript:**
```typescript
/**
 * Validates a user-submitted email address against RFC 5321 rules.
 *
 * @param email - Raw string from user input. May be empty or malformed.
 * @returns Normalized lowercase email if valid.
 * @throws {ValidationError} When email is empty, missing @, or domain is invalid.
 *
 * @example
 * validateEmail("User@Example.COM") // → "user@example.com"
 * validateEmail("")                 // throws ValidationError("email required")
 */
function validateEmail(email: string): string
```

**Python:**
```python
def validate_email(email: str) -> str:
    """
    Validate a user-submitted email address against RFC 5321 rules.

    Args:
        email: Raw string from user input. May be empty or malformed.

    Returns:
        Normalized lowercase email if valid.

    Raises:
        ValidationError: When email is empty, missing @, or domain is invalid.

    Example:
        >>> validate_email("User@Example.COM")
        'user@example.com'
        >>> validate_email("")
        # raises ValidationError("email required")
    """
```

---

### Classes / Modules

Every class and module file gets a header block.

**Required:**
- **Purpose:** One sentence. What responsibility does this own?
- **Responsibilities:** 3-5 bullet points. What does it do?
- **Not responsible for:** 2-3 bullet points. What it deliberately does NOT do (prevents scope creep).
- **Key dependencies:** What external services / classes does it rely on?

**TypeScript example:**
```typescript
/**
 * UserAuthService — manages authentication state for a single user session.
 *
 * Responsibilities:
 * - Validate credentials against the identity provider
 * - Issue and refresh session tokens
 * - Revoke tokens on logout or expiry
 *
 * Not responsible for:
 * - User account creation or password reset (→ UserAccountService)
 * - Authorization / permission checks (→ PermissionService)
 *
 * Dependencies:
 * - IdentityProvider: external OAuth2 server
 * - TokenStore: Redis-backed token cache
 */
class UserAuthService
```

---

### API Endpoints

Every endpoint gets an inline doc block immediately above the handler.

**Required fields:**

```typescript
/**
 * POST /api/v1/auth/login
 *
 * Authenticate user credentials and issue a session token.
 *
 * Auth: None (public endpoint)
 *
 * Request body:
 *   email    string  required  User email address
 *   password string  required  Plaintext password (TLS-protected in transit)
 *
 * Response 200:
 *   token      string  JWT session token (expires in 24h)
 *   expires_at string  ISO 8601 expiry timestamp
 *
 * Response 400: Invalid request body (missing fields or malformed email)
 * Response 401: Credentials invalid or account locked
 * Response 429: Too many login attempts — retry after N seconds (header: Retry-After)
 *
 * Side effects:
 * - Increments failed attempt counter in Redis on 401
 * - Locks account after 5 consecutive failures (15-minute window)
 */
```

---

### Private Functions

**One line only if behavior is non-obvious.** Nothing if the name is self-explanatory.

```typescript
// Decodes JWT without verifying signature — caller must verify before trusting claims
function decodeJwtPayload(token: string): JwtPayload

// No comment needed — name is sufficient
function isExpired(timestamp: number): boolean
```

---

### Inline Comments

Only explain **why**, never **what**. If you're explaining what the code does, rename the variable or extract a function.

```typescript
// ❌ BAD: explains what
// Increment the counter by 1
count++;

// ❌ BAD: restates the code
// Check if user is admin before deleting
if (user.role === 'admin') { ... }

// ✅ GOOD: explains why (non-obvious constraint)
// RFC 5321 limits local-part to 64 chars; truncate silently per spec § 4.5.3.1
const localPart = email.split('@')[0].slice(0, 64);

// ✅ GOOD: explains a workaround
// Safari 16 ignores 'color-scheme' on inputs; force white background explicitly
input.style.backgroundColor = '#ffffff';
```

---

## Wiki Integration

API and module docs live in `wiki/api/`. When you add or change a public API, update the corresponding wiki page in the same commit — by anyone (human or AI). The wiki is the living product reference; it must be 1:1 with the code.

```
wiki/
└── api/
    ├── auth.md         # Auth endpoints
    ├── users.md        # User endpoints
    └── modules/
        ├── UserAuthService.md
        └── TokenStore.md
```

Inline docstrings are the source of truth. Wiki pages are the human-readable reference. If they diverge, fix the wiki — that divergence is a bug.

---

## Checklist (per function / class / endpoint)

Before marking implementation complete:

- [ ] Every public function has one-line summary, params, returns, throws, example
- [ ] Every class has purpose, responsibilities, not-responsible-for, dependencies
- [ ] Every API endpoint has method+path, auth, request body, all response codes, side effects
- [ ] Inline comments explain only WHY, never WHAT
- [ ] Wiki page updated if public API changed
- [ ] No `// TODO: document this` left behind

## Red Flags — STOP

- "I'll add docs in a cleanup pass" → add them now
- "The name is obvious" → the example and throws section are still required
- "It's an internal function" → if it's public to the module, document it
- Docstring that restates the function name: `// Gets the user` on `getUser()` → add params, returns, throws, example

## What NOT to Write

- Multi-paragraph prose explaining the algorithm (that's a design doc, put it in `wiki/`)
- Change history ("Added in v2.3 to fix bug #123") — that's git history
- Author attribution ("Written by X") — that's git blame
- Comments that will go stale (`// This will be replaced when we migrate to PostgreSQL`)
