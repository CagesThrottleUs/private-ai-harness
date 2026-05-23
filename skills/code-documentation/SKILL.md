---
name: code-documentation
description: Use when writing or modifying any public construct — callable, type, module, endpoint, exported value, or test. Enforces spec/req traceability and full technical documentation at the point of authorship. Language-agnostic.
---

# Code Documentation

Document code at the moment of writing. Never as a cleanup step.

**Core principle:** A reader should understand what a construct does, what it needs, what it returns, when it fails, and which requirement it implements — without opening the implementation.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
EVERYTHING WRITTEN MUST HAVE @spec_id AND @req_id.
IF IT EXISTS IN THE CODEBASE, A SPEC MUST EXIST FOR IT.
NO EXCEPTIONS.
```

---

## Construct Taxonomy

Every construct that is **public/exported** AND **implements or validates behavior** must carry:
- `@spec_id SPEC-N` — which spec owns this construct
- `@req_id REQ-NNN` — which requirement within that spec (or `@validates_req` for tests)

Six tiers. Every tier has the same traceability requirement.

---

### Tier 1 — Callables

**What:** Anything invocable by name that contains logic.

**Includes:**
- Functions and standalone procedures
- Methods (instance and static)
- Constructors (non-trivial — if they do more than assign fields)
- Coroutines, generators, async functions
- Property accessors (get/set) when they contain logic beyond a field read/write
- Operator overloads
- Macros with logic bodies
- Named lambdas/closures exposed as public API

**Excludes:** trivial field getters (no logic), anonymous inline callbacks, private helpers

**Required fields:**

| Field | Required | Notes |
|-------|----------|-------|
| One-line summary | Always | What it does, not how |
| Parameters | If any | Name, type, description, whether optional |
| Return value | If non-void | Type and meaning |
| Throws/errors | If it can fail | Condition that triggers it |
| Example | Always | One concrete, runnable call |
| `@spec_id` | Always | SPEC-N of owning spec |
| `@req_id` | Always | REQ-NNN within that spec (comma-sep if multiple) |

**Examples across paradigms:**

```typescript
// TypeScript — JSDoc
/**
 * Validates a user-submitted email address against RFC 5321 rules.
 *
 * @param email - Raw string from user input. May be empty or malformed.
 * @returns Normalized lowercase email if valid.
 * @throws {ValidationError} When email is empty, missing @, or domain is invalid.
 * @spec_id SPEC-2
 * @req_id REQ-004
 *
 * @example
 * validateEmail("User@Example.COM") // → "user@example.com"
 */
function validateEmail(email: string): string
```

```python
# Python — docstring
def validate_email(email: str) -> str:
    """
    Validate a user-submitted email address against RFC 5321 rules.

    Args:
        email: Raw string from user input. May be empty or malformed.

    Returns:
        Normalized lowercase email if valid.

    Raises:
        ValidationError: When email is empty, missing @, or domain is invalid.

    spec_id: SPEC-2
    req_id: REQ-004

    Example:
        >>> validate_email("User@Example.COM")
        'user@example.com'
    """
```

```go
// Go — godoc comment
// ValidateEmail validates a user-submitted email address against RFC 5321 rules.
//
// Returns normalized lowercase email if valid.
// Returns ValidationError when email is empty, missing @, or domain is invalid.
//
// spec_id: SPEC-2
// req_id: REQ-004
//
// Example:
//   ValidateEmail("User@Example.COM") // → "user@example.com"
func ValidateEmail(email string) (string, error)
```

```rust
// Rust — doc comment
/// Validates a user-submitted email address against RFC 5321 rules.
///
/// Returns normalized lowercase email if valid.
///
/// # Errors
/// Returns `ValidationError` when email is empty, missing @, or domain is invalid.
///
/// spec_id: SPEC-2
/// req_id: REQ-004
///
/// # Examples
/// ```
/// validate_email("User@Example.COM") // → "user@example.com"
/// ```
pub fn validate_email(email: &str) -> Result<String, ValidationError>
```

```java
// Java — Javadoc
/**
 * Validates a user-submitted email address against RFC 5321 rules.
 *
 * @param email Raw string from user input. May be empty or malformed.
 * @return Normalized lowercase email if valid.
 * @throws ValidationError When email is empty, missing @, or domain is invalid.
 * @spec_id SPEC-2
 * @req_id REQ-004
 *
 * @example validateEmail("User@Example.COM") // → "user@example.com"
 */
public String validateEmail(String email)
```

---

### Tier 2 — Type Definitions

**What:** Anything that defines a data shape or behavior contract.

**Includes:**
- Classes, structs, records, data classes
- Interfaces, protocols, traits, abstract classes
- Enumerations (the enum type itself, and enum variants if they carry distinct business meaning)
- Type aliases and type definitions
- Union types / sum types / tagged unions / discriminated unions
- Generic/parameterized types
- Schema definitions (JSON Schema, Protobuf messages, GraphQL types, OpenAPI schemas)

**Required fields:**
- One-line purpose statement
- Responsibilities (what this type represents)
- What it deliberately does NOT represent (prevents scope creep)
- `@spec_id SPEC-N`
- `@req_id REQ-NNN`

```typescript
// TypeScript — interface
/**
 * Contract for email validation result returned by the validation pipeline.
 *
 * Represents: the outcome of a single validation attempt.
 * Does not represent: the email history, user identity, or send status.
 *
 * @spec_id SPEC-2
 * @req_id REQ-004, REQ-005
 */
export interface ValidationResult {
  normalized: string
  valid: boolean
  error?: string
}
```

```typescript
// TypeScript — enum
/**
 * Possible outcomes of an email validation attempt.
 *
 * @spec_id SPEC-2
 * @req_id REQ-005
 */
export enum ValidationStatus {
  Valid = 'valid',
  InvalidFormat = 'invalid_format',
  DomainUnresolvable = 'domain_unresolvable',
}
```

```python
# Python — dataclass
@dataclass
class ValidationResult:
    """
    Outcome of a single email validation attempt.

    Represents: the result of one call to validate_email.
    Does not represent: user identity, email history, or send queue state.

    spec_id: SPEC-2
    req_id: REQ-004, REQ-005
    """
    normalized: str
    valid: bool
    error: Optional[str] = None
```

---

### Tier 3 — Module Boundaries

**What:** The organizational unit that groups related code and defines a public surface.

**Includes:**
- Source files when they act as a module (file-level docstring/header comment)
- Package entry points (`__init__.py`, `mod.rs`, `index.ts`, `package.go`)
- Namespaces
- UI components (treated as modules — the component file gets a header)

The file-level annotation anchors all symbols within to a spec. Individual symbols may override with a different `@spec_id` if they implement a different spec.

**Required at file level:**
- Purpose: one sentence
- `@spec_id SPEC-N` — primary spec this module implements
- `@req_id REQ-NNN` — requirements covered by the module as a whole

```typescript
/**
 * auth/validation.ts — Email validation logic for the authentication pipeline.
 *
 * Responsibilities:
 * - Validate RFC 5321 format compliance
 * - Normalize email casing
 * - Check domain resolvability
 *
 * Not responsible for:
 * - User account creation (→ auth/accounts.ts)
 * - Rate limiting (→ middleware/ratelimit.ts)
 *
 * @spec_id SPEC-2
 * @req_id REQ-004, REQ-005, REQ-006
 */
```

```python
"""
auth/validation.py — Email validation logic for the authentication pipeline.

Responsibilities:
- Validate RFC 5321 format compliance
- Normalize email casing
- Check domain resolvability

Not responsible for:
- User account creation (→ auth/accounts.py)
- Rate limiting (→ middleware/ratelimit.py)

spec_id: SPEC-2
req_id: REQ-004, REQ-005, REQ-006
"""
```

---

### Tier 4 — External Contracts / Endpoints

**What:** Any construct that crosses a process boundary or defines an external-facing contract.

**Includes:**
- HTTP handlers (REST, GraphQL mutations/queries, gRPC service methods)
- WebSocket handlers
- CLI commands and subcommands
- Event handlers (when they define the public contract)
- Message consumers and producers (queue/pubsub)
- Cron job handlers
- Webhook handlers
- IPC handlers

**Required fields:**
- Method + path/topic/command name
- Auth requirements
- Input schema (parameters, body, headers)
- Output schema (all response codes / event payloads)
- Side effects
- `@spec_id SPEC-N`
- `@req_id REQ-NNN`

```typescript
/**
 * POST /api/v1/auth/login
 *
 * Authenticate user credentials and issue a session token.
 *
 * Auth: None (public endpoint)
 * @spec_id SPEC-1
 * @req_id REQ-001
 *
 * Request body:
 *   email    string  required
 *   password string  required
 *
 * Response 200: { token: string, expires_at: string }
 * Response 400: Invalid request body
 * Response 401: Credentials invalid or account locked
 * Response 429: Rate limit exceeded (Retry-After header set)
 *
 * Side effects:
 * - Increments failed attempt counter in Redis on 401
 * - Locks account after 5 consecutive failures (15-minute window)
 */
```

---

### Tier 5 — Exported Values

**What:** Named public values that other modules depend on.

**Includes:**
- Exported constants
- Configuration defaults
- Exported global state (flag if it exists — global mutable state is a code smell)
- Named export of shared fixtures or seed data

```typescript
/**
 * Maximum login attempts before account lock.
 * @spec_id SPEC-1
 * @req_id REQ-003
 */
export const MAX_LOGIN_ATTEMPTS = 5

/**
 * Account lock duration after MAX_LOGIN_ATTEMPTS failures.
 * @spec_id SPEC-1
 * @req_id REQ-003
 */
export const LOCK_DURATION_MS = 15 * 60 * 1000
```

```python
# spec_id: SPEC-1
# req_id: REQ-003
MAX_LOGIN_ATTEMPTS: Final[int] = 5

# spec_id: SPEC-1
# req_id: REQ-003
LOCK_DURATION_SECONDS: Final[int] = 15 * 60
```

---

### Tier 6 — Test Units

**What:** Anything that validates behavior against a requirement.

**Includes:**
- Test functions and test methods
- Test classes / test suites (at the class level if the suite tests one REQ)
- Parameterized test cases (each variant if they cover different REQs; the suite if all variants cover one REQ)
- Property-based test generators
- Integration test scenarios
- Fixture functions that encode business constraints (not pure setup)

**Required:**
- `@spec_id SPEC-N`
- `@validates_req REQ-NNN`
- Descriptive test name (must describe the behavior, not "test case 1")

```typescript
/**
 * @spec_id SPEC-2
 * @validates_req REQ-004
 */
it('rejects empty email with ValidationError', () => {
  expect(() => validateEmail('')).toThrow(ValidationError)
})
```

```python
def test_empty_email_raises_validation_error(self):
    """
    spec_id: SPEC-2
    validates_req: REQ-004
    """
    with pytest.raises(ValidationError):
        validate_email("")
```

```go
// spec_id: SPEC-2
// validates_req: REQ-004
func TestValidateEmail_EmptyInput_ReturnsError(t *testing.T) {
```

```rust
/// spec_id: SPEC-2
/// validates_req: REQ-004
#[test]
fn test_empty_email_returns_error() {
```

Multiple REQs: comma-separate. One test may cover multiple REQs when they share a single behavior.

---

## Annotation Format Reference

| Language | doc comment style | spec_id | req_id | validates_req |
|----------|------------------|---------|--------|---------------|
| TypeScript/JS | `/** */` | `@spec_id SPEC-N` | `@req_id REQ-NNN` | `@validates_req REQ-NNN` |
| Python | `""" """` or `# ` | `spec_id: SPEC-N` | `req_id: REQ-NNN` | `validates_req: REQ-NNN` |
| Go | `// ` | `spec_id: SPEC-N` | `req_id: REQ-NNN` | `validates_req: REQ-NNN` |
| Rust | `/// ` | `spec_id: SPEC-N` | `req_id: REQ-NNN` | `validates_req: REQ-NNN` |
| Java/Kotlin | `/** */` | `@spec_id SPEC-N` | `@req_id REQ-NNN` | `@validates_req REQ-NNN` |
| C/C++ | `/** */` or `// ` | `@spec_id SPEC-N` | `@req_id REQ-NNN` | `@validates_req REQ-NNN` |
| Swift | `/// ` | `spec_id: SPEC-N` | `req_id: REQ-NNN` | `validates_req: REQ-NNN` |
| Ruby | `# ` | `spec_id: SPEC-N` | `req_id: REQ-NNN` | `validates_req: REQ-NNN` |
| PHP | `/** */` | `@spec_id SPEC-N` | `@req_id REQ-NNN` | `@validates_req REQ-NNN` |
| Other | native doc style | same field names | same | same |

**Pattern:** use whatever comment/docstring syntax the language uses. The field names (`spec_id`, `req_id`, `validates_req`) are constant across all languages.

---

## Checklist (per construct before marking complete)

- [ ] Tier 1 (Callable): summary, params, returns, throws, example, `@spec_id`, `@req_id`
- [ ] Tier 2 (Type): purpose, represents, does-not-represent, `@spec_id`, `@req_id`
- [ ] Tier 3 (Module): purpose, responsibilities, not-responsible-for, `@spec_id`, `@req_id`
- [ ] Tier 4 (Endpoint): method+path, auth, `@spec_id`, `@req_id`, input, output, side effects
- [ ] Tier 5 (Exported value): one-line summary, `@spec_id`, `@req_id`
- [ ] Tier 6 (Test): descriptive name, `@spec_id`, `@validates_req`
- [ ] Wiki page updated if Tier 4 public contract changed

---

## Red Flags — STOP

- "It's just a type/interface" → types define contracts, they need traceability
- "Constants don't need docs" → exported constants are API surface
- "I'll add the spec_id later" → add it now
- "This is infrastructure/plumbing" → write a spec for it then, every written construct traces to a requirement
- Docstring that restates the symbol name → add params, returns, spec_id, req_id

## What NOT to Write

- Multi-paragraph prose explaining the algorithm (design doc → `wiki/`)
- Change history ("Added in v2.3") → git history
- Author attribution → git blame
- Comments that will go stale ("// Replace when we migrate to X")
