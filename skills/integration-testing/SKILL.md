---
name: integration-testing
description: >
  Use during the TDD GREEN phase for any component with external dependencies (database, queue, cache, external API). Sets up Testcontainers with real Docker dependencies (not mocks), implements transaction rollback for test isolation, factory pattern for test data, and adds an integration test CI job. For service-to-service APIs, adds Pact consumer-driven contract tests. Runs integration-test-reviewer agent before committing.
---

# Integration Testing

Unit tests verify internal logic. Integration tests verify contracts — how your code behaves against real dependencies. Over 60% of production bugs live at service boundaries, not inside isolated units (Spotify Engineering, 2018). A test suite that only mocks the database encodes assumptions about database behavior, not the behavior itself.

## References

- **Testcontainers** (testcontainers.com) — multi-language, Docker-based real dependencies, production-identical versions
- **Spotify Testing Honeycomb** (engineering.atspotify.com/2018/01/testing-of-microservices) — integration tests at center; most bugs live at service boundaries
- **Pact** (docs.pact.io) — consumer-driven contract testing; "undetected API schema drift" is top-3 production incident cause (World Quality Report 2025)
- **Testcontainers Best Practices** (docker.com/blog/testcontainers-best-practices/) — pinned versions, dynamic ports, no `latest` tag
- **PostgreSQL Regression Suite** — real DB in every test; no mocks since 1994

---

## The Iron Law

> **No mock at the integration test boundary.** A test using `mock.DB`, `mock.Queue`, or `mock.HTTP` is a unit test. Write both — they test different things. Integration tests run against the real dependency in a container.

---

## When to Use

**Required** during the TDD GREEN phase for any component that:
- Queries or writes to a database
- Publishes to or consumes from a queue or event bus
- Calls an external HTTP API
- Reads from or writes to a cache

**Also required** for service-to-service APIs (contract tests via Pact or equivalent).

**Skip** for: pure business logic with no I/O, utility functions, pure transformations.

---

## Inputs Required

- **Component type** — what external dependency (PostgreSQL, MySQL, Redis, RabbitMQ, Kafka, HTTP API)
- **Language** — detect from manifest files
- **Test framework** — pytest, Jest, testing/t, JUnit, cargo test

---

## Process

1. **Detect dependencies** — read code to identify external I/O (DB clients, queue clients, HTTP clients)
2. **Set up Testcontainers** — language-specific, pinned image version matching production
3. **Implement test isolation** — transaction rollback per test (not container restart)
4. **Set up test data factories** — factory pattern, not hardcoded fixtures
5. **Write integration tests** — one test per acceptance criterion requiring I/O verification
6. **Add contract tests** — if service makes or receives HTTP calls from other services
7. **Add integration test CI job** — if not already present in CI config
8. **Run `integration-test-reviewer` agent** — fix Critical and Important findings

---

## Testcontainers Setup

**Critical rule:** Always pin the container image to the same version running in production. Never use `latest`.

**Python — `pytest` + `testcontainers-python`:**

```python
# tests/conftest.py
import pytest
from testcontainers.postgres import PostgresContainer
from testcontainers.redis import RedisContainer
from sqlalchemy import create_engine, text

@pytest.fixture(scope="session")
def pg_container():
    """Start PostgreSQL container once per test session."""
    with PostgresContainer("postgres:15.2") as pg:  # pin to production version
        yield pg

@pytest.fixture(scope="session")
def db_engine(pg_container):
    engine = create_engine(pg_container.get_connection_url())
    # Run migrations
    from alembic.config import Config
    from alembic import command
    alembic_cfg = Config("alembic.ini")
    alembic_cfg.set_main_option("sqlalchemy.url", pg_container.get_connection_url())
    command.upgrade(alembic_cfg, "head")
    yield engine
    engine.dispose()

@pytest.fixture(autouse=True)
def db_transaction(db_engine):
    """Wrap each test in a transaction that rolls back — no shared state."""
    connection = db_engine.connect()
    transaction = connection.begin()
    yield connection
    transaction.rollback()
    connection.close()
```

**Go — `testing` + `testcontainers-go`:**

```go
// testutil/containers.go
package testutil

import (
    "context"
    "testing"
    "github.com/testcontainers/testcontainers-go/modules/postgres"
)

func SetupPostgres(t *testing.T) string {
    t.Helper()
    ctx := context.Background()
    pg, err := postgres.Run(ctx,
        "postgres:15.2",  // pin to production version
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
        postgres.WithSQLDriver("pgx"),
        testcontainers.WithWaitStrategy(
            wait.ForLog("database system is ready to accept connections").
                WithOccurrence(2).WithStartupTimeout(30*time.Second),
        ),
    )
    if err != nil {
        t.Fatalf("failed to start postgres: %v", err)
    }
    t.Cleanup(func() { pg.Terminate(ctx) })
    
    connStr, _ := pg.ConnectionString(ctx, "sslmode=disable")
    return connStr
}

// Transaction rollback per test
func WithTransaction(t *testing.T, db *sqlx.DB, fn func(tx *sqlx.Tx)) {
    t.Helper()
    tx := db.MustBegin()
    defer tx.Rollback()  // always rolls back — isolation guaranteed
    fn(tx)
}
```

**TypeScript — `jest` + `testcontainers`:**

```typescript
// tests/setup/containers.ts
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';

let container: StartedPostgreSqlContainer;

beforeAll(async () => {
    container = await new PostgreSqlContainer('postgres:15.2')  // pin version
        .withDatabase('testdb')
        .withUsername('test')
        .withPassword('test')
        .start();
    
    process.env.DATABASE_URL = container.getConnectionUri();
    // run migrations
    await runMigrations(container.getConnectionUri());
}, 60_000);

afterAll(async () => {
    await container.stop();
});

// Per-test isolation via transaction rollback
beforeEach(async () => {
    await db.query('BEGIN');
});

afterEach(async () => {
    await db.query('ROLLBACK');
});
```

**Java — `JUnit 5` + `testcontainers`:**

```java
// Integration test base class
@Testcontainers
@SpringBootTest
abstract class IntegrationTestBase {

    @Container
    static final PostgreSQLContainer<?> postgres = 
        new PostgreSQLContainer<>("postgres:15.2")  // pin version
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    protected PlatformTransactionManager transactionManager;

    private TransactionStatus tx;

    @BeforeEach
    void beginTransaction() {
        tx = transactionManager.getTransaction(new DefaultTransactionDefinition());
    }

    @AfterEach
    void rollbackTransaction() {
        transactionManager.rollback(tx);  // guaranteed isolation
    }
}
```

**Rust — `#[tokio::test]` + `testcontainers`:**

```rust
// tests/common/mod.rs
use testcontainers::{clients::Cli, images::postgres::Postgres, Container};

pub async fn setup_postgres<'d>(docker: &'d Cli) -> (Container<'d, Postgres>, String) {
    let pg_image = Postgres::default().with_tag("15.2");  // pin version
    let container = docker.run(pg_image);
    let port = container.get_host_port_ipv4(5432);
    let url = format!("postgresql://postgres:postgres@127.0.0.1:{}/postgres", port);
    sqlx::migrate!("./migrations").run(&pool).await.unwrap();
    (container, url)
}
```

---

## Test Data Factories

**Factory pattern** over hardcoded fixtures — factories generate unique data per test, preventing cross-test contamination.

**Python:**
```python
# tests/factories.py
import factory
from factory.alchemy import SQLAlchemyModelFactory
from app.models import User, Order

class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session_persistence = "flush"

    id = factory.Sequence(lambda n: n + 1)
    email = factory.LazyAttribute(lambda obj: f"user{obj.id}@test.example")
    name = factory.Faker("name")
    created_at = factory.LazyFunction(datetime.utcnow)

class OrderFactory(SQLAlchemyModelFactory):
    class Meta:
        model = Order
    
    user = factory.SubFactory(UserFactory)
    total = factory.Faker("pydecimal", min_value=1, max_value=1000, right_digits=2)

# Usage in test
def test_user_can_place_order(db_transaction):
    user = UserFactory(session=db_transaction)
    order = OrderFactory(user=user, session=db_transaction)
    assert order.user_id == user.id
```

**Go:**
```go
// tests/factory/factory.go
package factory

func NewUser(db *sqlx.DB, overrides ...func(*User)) *User {
    u := &User{
        Email:     fmt.Sprintf("user-%d@test.example", time.Now().UnixNano()),
        Name:      "Test User",
        CreatedAt: time.Now(),
    }
    for _, override := range overrides {
        override(u)
    }
    db.MustExec("INSERT INTO users ...", u.Email, u.Name)
    return u
}
// Usage: user := factory.NewUser(tx, func(u *User) { u.Email = "specific@test.com" })
```

**TypeScript:**
```typescript
// tests/factories/user.factory.ts
import { faker } from '@faker-js/faker';

export function createUser(overrides: Partial<User> = {}): UserCreateInput {
    return {
        email: faker.internet.email(),
        name: faker.person.fullName(),
        createdAt: new Date(),
        ...overrides,
    };
}
// Usage: const user = await userService.create(createUser({ email: 'specific@test.com' }))
```

---

## Contract Testing (Service-to-Service APIs)

**Required when:** this service makes HTTP calls to another service, OR provides an HTTP API consumed by other services.

**Pact — consumer side (the service making the call):**

```typescript
// tests/contracts/payment-api.pact.ts
import { Pact } from '@pact-foundation/pact';

const provider = new Pact({
    consumer: 'checkout-service',
    provider: 'payment-api',
    port: 4000,
});

describe('payment-api contract', () => {
    before(() => provider.setup());
    after(() => provider.finalize());

    it('processes a payment', async () => {
        await provider.addInteraction({
            state: 'user has valid payment method',
            uponReceiving: 'a charge request',
            withRequest: {
                method: 'POST',
                path: '/v1/charges',
                headers: { 'Content-Type': 'application/json' },
                body: { amount: 1000, currency: 'usd', userId: 'usr_123' },
            },
            willRespondWith: {
                status: 200,
                body: { id: like('ch_abc'), status: 'succeeded' },
            },
        });
        
        const result = await chargeUser('usr_123', 1000);
        expect(result.status).toBe('succeeded');
    });
});
```

**Pact — provider side (the service providing the API):**
```typescript
// tests/contracts/verify-payment-pact.ts
import { Verifier } from '@pact-foundation/pact';

it('verifies pact with checkout-service', () => {
    return new Verifier({
        provider: 'payment-api',
        providerBaseUrl: 'http://localhost:3000',
        pactUrls: ['./pacts/checkout-service-payment-api.json'],
    }).verifyProvider();
});
```

---

## Integration Test CI Job

Add to existing CI pipeline (detected by `ci-pipeline-setup`):

**GitHub Actions addition:**
```yaml
# Adds to .github/workflows/ci.yml
  integration-tests:
    name: Integration Tests
    needs: [unit-tests]     # run after unit tests pass
    runs-on: ubuntu-latest
    services:
      # Alternative to Testcontainers for simple cases
      # (Testcontainers manages its own Docker — no services block needed when using TC)
    steps:
      - uses: actions/checkout@v4
      - name: Set up language runtime
        # [language-specific setup]
      - name: Run integration tests
        run: |
          # [language-specific integration test command]
          # pytest tests/integration/ -v --timeout=120
          # go test ./tests/integration/... -v -timeout 120s
          # npm run test:integration
        env:
          TESTCONTAINERS_RYUK_DISABLED: "false"  # Ryuk handles container cleanup
      - name: Upload coverage (integration)
        # [coverage upload step]
```

**GitLab CI addition:**
```yaml
integration-tests:
  stage: test
  needs: [unit-tests]
  services:
    - docker:dind
  variables:
    DOCKER_HOST: tcp://docker:2375
  script:
    - [integration test command]
```

---

## Integration Test Naming Convention

Integration tests are distinguishable from unit tests by location and naming:

| Language | Unit test location | Integration test location |
|----------|-------------------|--------------------------|
| Python | `tests/unit/` | `tests/integration/` |
| Go | `*_test.go` (same package) | `tests/integration/*_test.go` |
| TypeScript | `src/**/*.test.ts` | `tests/integration/*.test.ts` |
| Java | `src/test/unit/` | `src/test/integration/` |
| Rust | `#[cfg(test)]` inline | `tests/` directory |

Tag integration tests so they can be run selectively:

```python
# Python — pytest mark
@pytest.mark.integration
def test_user_saved_to_database(): ...

# Go — build tag
//go:build integration
package integration

# TypeScript — jest project config
// jest.config.js: testMatch for integration/ directory
```

---

## Self-Review: Run `integration-test-reviewer` Agent

After writing integration tests, before committing:

```
Agent(integration-test-reviewer, {
  TEST_FILES: "tests/integration/**",
  SPEC_PATH: ".ai/specs/YYYY-MM-DD-<feature>.md"
})
```

Fix all **Critical** findings (no mocks at boundary, not testing real behavior). **Important** findings should be fixed.

---

## Commit

```
test(integration): add integration tests for [component] with Testcontainers

[body: WHY — what production behavior unit tests cannot verify, what this catches]
```

Integration tests commit alongside the component they test — not in a separate PR.
