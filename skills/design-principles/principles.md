# Principles — Full Violation/Fix Reference

Deep-dive companion to `SKILL.md`. Contains full violation/fix tables for all principles. Consult when a checklist item flags a violation and you need specifics.

---

## DRY — Don't Repeat Yourself

| Violation | Fix |
|-----------|-----|
| Same logic in two functions | Extract to shared function |
| Same config value in two files | Single source of truth (env/config) |
| Same validation in client and server | Shared validator, called from both |
| Copy-paste with minor edits | Parameterize the shared logic |

---

## KISS — Keep It Simple, Stupid

| Violation | Fix |
|-----------|-----|
| Abstract base class for one concrete type | Direct implementation |
| Factory for objects with one variant | Constructor |
| Config-driven behavior for one use case | Hardcode it |
| Generic framework for one caller | Simple function |

---

## SoC — Separation of Concerns

| Mixed (bad) | Separated (good) |
|-------------|-----------------|
| UI + business logic in same file | View calls service; service is pure |
| Validation + persistence in same function | Validator returns errors; persistence separate |
| Auth + data access in same method | Middleware handles auth; service handles data |
| Formatting + calculation together | Pure calculation; separate formatter |

---

## Loose Coupling

| Tight (bad) | Loose (good) |
|-------------|-------------|
| Class A creates `new B()` mid-method | A receives B through constructor |
| Module imports from 10 different places | Module has 1–2 well-defined dependencies |
| DB schema change forces UI change | Schema change stays within data layer |
| Function calls 6 different services directly | Orchestrator delegates through single interface |

---

## High Cohesion

| Low cohesion (bad) | High cohesion (good) |
|--------------------|---------------------|
| `UserService` handles auth, billing, email, and profiles | Separate `AuthService`, `BillingService`, `NotificationService` |
| Utility file with 40 unrelated helper functions | Focused module where every function shares a domain concept |
| Class that knows about DB schema AND HTTP response format | Class knows one thing; adapter translates at the boundary |
| Module changes for 3 different reasons per sprint | Module changes for exactly one reason: its domain changes |

---

## SRP — Single Responsibility

| Violation | Fix |
|-----------|-----|
| `UserService` handles auth logic AND sends welcome emails | Split into `AuthService` + `UserNotifier` |
| Report class formats data AND writes to file | Separate formatter from writer |
| DB model validates input AND maps to HTTP response | Validator, model, and serializer are three classes |
| One class changes when business rules change AND when DB schema changes | Two responsibilities — split it |

---

## LSP — Liskov Substitution

| Violation | Fix |
|-----------|-----|
| `Penguin extends Bird` but `fly()` throws or no-ops | Remove `fly()` from base; use composition |
| `ReadOnlyList extends List` but `add()` throws `UnsupportedOperationException` | Separate `ReadableList` interface |
| Override weakens precondition or strengthens postcondition | Redesign the hierarchy |
| Caller must `instanceof`-check before using subtype | Hierarchy is wrong; callers should not need to know the subtype |

---

## ISP — Interface Segregation

| Violation | Fix |
|-----------|-----|
| `IWorker` has `work()` + `eat()` + `sleep()`; robot implements all three | Split into `IWorkable`, `IFeedable`, `IRestable` |
| 15-method interface where 3 clients each use 5 methods | 3 focused interfaces of 5 methods each |
| Implementing class has methods that throw `NotImplementedException` | Interface is too fat; the implementor is forced to stub |
| Client imports interface but only calls 2 of its 10 methods | Extract those 2 into a smaller interface |

---

## Encapsulation / Information Hiding

| Violation | Fix |
|-----------|-----|
| Public field on a class | Private field + accessor only if callers need it |
| Returning internal collection directly (`getItems()` returns the live list) | Return a copy or an unmodifiable view |
| Leaking DB row structure to API response | Map to a DTO; internal schema stays internal |
| Internal helper methods are public | Default to private; make public only when there's a caller |

---

## Immutability by Default

| Violation | Fix |
|-----------|-----|
| Shared mutable object passed to multiple threads | Immutable value object; copy-on-write |
| Function mutates its input argument | Return new object; leave input unchanged |
| Object's fields change after construction | Constructor sets all fields; no setters |
| List returned from function is mutated by caller | Return `ImmutableList` / `unmodifiableList` |

---

## Explicit over Implicit

| Violation | Fix |
|-----------|-----|
| Framework auto-injects dependency with no declaration | Explicit constructor injection |
| Function behavior changes based on global flag | Pass the flag as a parameter |
| Order of method calls matters but nothing enforces it | Encode order in types or structure |
| Config loaded from mysterious default location | Pass config path explicitly |
| Magic string `"admin"` scattered through codebase | Named constant or enum |

---

## Temporal Coupling

| Violation | Fix |
|-----------|-----|
| `init()` must be called before `run()` but nothing enforces this | Return initialized object from `init()`; `run()` takes it as parameter |
| Step 2 silently does nothing if Step 1 wasn't called | Make Step 2 impossible without Step 1's output |
| Comment says "call A before B" | Encode it in the type system |

---

## Error Paths

| Violation | Fix |
|-----------|-----|
| Empty `catch` block swallows exception | Log + rethrow with context, or return typed error |
| `null` returned on failure with no indication | Return `Result<T, Error>` or throw named exception |
| Error message says "something went wrong" | Error message names the condition and suggests a fix |
| Errors only documented in comments | Encode in return type or exception type |

---

## Names Are Design

| Bad name | What it signals | Fix |
|----------|----------------|-----|
| `Manager`, `Handler`, `Util`, `Helper` | No clear responsibility | Name the actual thing: `OrderValidator`, `InvoicePrinter` |
| `data`, `info`, `stuff`, `temp` | Temporary thinking made permanent | Name the domain concept |
| `flag`, `mode`, `type` as booleans | Hidden enum | Replace with enum or named constants |
| Function named `process()` | Does too many things | Split until each part has a clear name |
