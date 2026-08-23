---
name: design-principles
description: Use when writing plans, reviewing code, or designing any system — software or otherwise. Enforces DRY, KISS, YAGNI, SoC, SOLID, and GoF patterns as a mandatory lens during decomposition, implementation, and review.
---

# Design Principles

Universal laws of clean system design. Apply at every layer: architecture, module boundaries, class design, function signatures. Extends beyond code — API contracts, data schemas, workflow design, skill/agent decomposition all obey the same laws.

**Announce at start:** "I'm applying design-principles to this work."

> Full violation/fix tables for all principles: `skills/design-principles/principles.md`

## North Star

> **The ideal system is the smallest one that fully satisfies its requirements — no more, no less. Every component has exactly one reason to exist.**

- Removing any part breaks behavior → YAGNI passes
- Adding any feature touches the fewest files → SoC + coupling hold
- Any component understood, tested, replaced in isolation → SRP + cohesion hold

---

## Core Principles

**DRY — Don't Repeat Yourself**
Every piece of knowledge has exactly one authoritative representation. DRY is about knowledge duplication — not just identical code. Apply at third occurrence (see Conflict Resolution: DRY vs YAGNI).

**KISS — Keep It Simple, Stupid**
The simplest solution that correctly solves the problem is the right solution.
_Test:_ Can a new engineer understand this without asking anyone? If not, simplify.
_Module test (Parnas):_ Can a developer understand and modify this module without reading any other module? If not, the interface reveals implementation detail — the boundary is wrong.

**YAGNI — You Aren't Gonna Need It**
Don't build for hypothetical future requirements. No extension points without a concrete second use case in the spec. No generics/templates when one type exists. No versioning until a second version is needed.
_Override only when:_ a spec REQ explicitly names future extensibility.

**SoC — Separation of Concerns**
Each component addresses one concern. No concern bleeds into another. UI out of services. Auth out of data access. Formatters out of calculators.

**Loose Coupling**
Dependencies go through interfaces, not implementations. Changes in X don't force changes in Y.

**High Cohesion**
Things that change together live together. A module's contents all serve one purpose.
_Test:_ Can you describe the module in one noun phrase without "and"? If not, split it.

---

## Additional Core Principles

### Law of Demeter (LoD) — Don't Talk to Strangers

A method calls methods only on: itself, its parameters, objects it creates, its direct fields. Never chain through another object's internals.

| Violation | Fix |
|-----------|-----|
| `order.getCustomer().getAddress().getCity()` | `order.getCustomerCity()` — delegate through the owner |
| `a.getB().getC().doThing()` | Pass the needed object directly, or add a method to `A` |
| Controller reaches into repo internals to build a query | Service wraps the query; controller calls the service |

_Test:_ More than one dot on foreign objects = LoD violation. Own fields don't count.

### CQS — Command-Query Separation

Methods either **change state** (command) or **return data** (query). Never both.

| Violation | Fix |
|-----------|-----|
| `stack.pop()` returns value AND removes it | `peek()` + `remove()` — separate |
| `createUser()` returns entity AND sends email | Command creates; event triggers email; query fetches |
| `save()` returns saved object AND has side effects | Side effects in command; query fetches saved state |

_Test:_ Can you call this repeatedly without changing system state? Query. Can't? Command. Sometimes? CQS violation.

### Composition over Inheritance

Prefer assembling behavior from small focused objects over extending class hierarchies.

| Violation | Fix |
|-----------|-----|
| Deep hierarchy: `Animal → Bird → FlyingBird → Parrot` | `Parrot` has `FlyBehavior`, `TalkBehavior` as injected components |
| Override method in subclass to change behavior | Inject a Strategy instead |
| Change in base class breaks 6 subclasses | No base class — compose from stable interfaces |

_Rule:_ Inheritance for IS-A only, where LSP holds. Everything else: compose.

### Fail Fast

Detect and report errors immediately, at the earliest possible point, close to the source.

| Violation | Fix |
|-----------|-----|
| Null passed deep into call stack before crash | Validate at entry; throw/return error immediately |
| Invalid config discovered at runtime | Validate config at startup; refuse to start |
| Partial state written before validation fails | Validate entirely before writing anything |
| Error swallowed in empty catch | Log + rethrow with context |

_Test:_ How many function calls happen before bad input raises an error? Answer should be zero or one.

### POLA — Principle of Least Astonishment

Code behaves exactly as a reasonable reader expects from its name. No surprises.

| Violation | Fix |
|-----------|-----|
| `getUser()` also sends an analytics event | Side effects explicit: `getAndTrackUser()` or separate |
| `isValid()` returns `int` not `bool` | Return type matches what name implies |
| `save()` deletes orphans as side effect | `saveAndPruneOrphans()` — name the effect |
| `add()` silently no-ops on duplicate | Return bool or throw; never silent no-op on meaningful action |
| `disable_cache=false` means cache IS enabled | `enable_cache=true` — no double negatives |

_Test:_ Read only the function name. What would a new engineer expect? Does implementation match exactly?

---

## SOLID Principles

**S — Single Responsibility**
A class/module has exactly one reason to change.
_Test:_ "What would make this class change?" Two different answers → split it.

**O — Open/Closed**
Open for extension, closed for modification. New behavior through extension — new implementation, new decorator, new strategy.

| Violation | Fix |
|-----------|-----|
| Adding new payment method requires editing `processPayment()` switch | Strategy: new `PaymentStrategy` implementor |
| New export format requires editing `Exporter` | New `ExporterStrategy`; `Exporter` delegates |
| Every new feature touches the same core class | Core does too much — extract extension points |

_Test:_ Can you add the new requirement without opening any existing file? If not, OCP violated.

**L — Liskov Substitution**
Subtypes must be substitutable for their base type. If `Bird` has `fly()`, don't make `Penguin extends Bird`.
_Test:_ Can every caller use any subtype without `instanceof` checks? If not, the hierarchy is wrong.

**I — Interface Segregation**
Clients should not depend on methods they don't use.
_Test:_ Does any implementor leave a method empty or throwing? Does any caller use fewer than half the interface's methods? Both are violations.

**D — Dependency Inversion**
High-level modules define the interface. Low-level modules implement it.

| Violation | Fix |
|-----------|-----|
| `OrderService` creates `new MySQLOrderRepository()` | Inject `OrderRepository` interface through constructor |
| Business logic imports a specific logger class | Inject `Logger` interface; wired at startup |
| High-level module changes when low-level detail changes | High-level owns the interface; low-level implements it |

```
❌  OrderService → MySQLOrderRepository
✅  OrderService → OrderRepository (interface) ← MySQLOrderRepository
```

_Test:_ Swap low-level implementation — does high-level module need to change? Yes = DIP violated.

---

## Additional Design Principles

**Encapsulation / Information Hiding** — Each module hides one difficult design decision or one volatile requirement from the rest of the system. (Parnas, 1972)

**Modularization criterion:** When decomposing a system, the question is not "what steps does this perform?" but "what secret does this hide?" A module named after a step (`InputHandler`, `Sorter`, `OutputFormatter`) is process-decomposed — its structure is exposed through its name and will ripple when the process changes. A module named after what it hides (`LineStorage`, `SortStrategy`, `ReportLayout`) is information-hiding decomposed — callers only depend on its interface.

**Identifying the secret:** Before creating a module, ask: "What is the most volatile or difficult thing about this problem area?" That volatile thing is the secret. Wrap it behind an interface. The rest of the system must not know whether you store data in an array or linked list, call REST or gRPC, sort with QuickSort or MergeSort. Only the module owning that secret is allowed to know it.

| Violation | Signal | Fix |
|-----------|--------|-----|
| Module named after a step | `Parse`, `Transform`, `Emit` — flowchart decomposition | Rename to what it hides: `SchemaAdapter`, `FormatTranslator`, `OutputSink` |
| Changing a data structure requires editing N modules | The data structure leaked across module boundaries | One module owns the structure; others call its interface |
| Adding a new storage backend requires changing business logic | Storage detail leaked upward | Storage module hides the backend; business logic calls an interface |
| Module knows the caller's internal representation | Two-way coupling | Module exposes what it provides; caller reveals nothing about itself |

_Test:_ Can you completely replace this module's implementation — swap the data structure, algorithm, or backend — without changing any other module? If yes: well-hidden. If no: implementation detail leaked. (Parnas, 1972)

**Postel's Law** — Be conservative in what you send, liberal in what you accept. Normalize format variation on input; be strict on output. Not a license for accepting malformed data — that's Fail Fast's job.

**Immutability by Default** — Prefer immutable data. Mutation is the primary source of hard bugs in stateful and concurrent systems. Default to `const`/`final`/`readonly`. Mutability requires explicit justification.

**Explicit over Implicit** — Make behavior, dependencies, and decisions visible in code — not in convention, magic, or docs.
_Test:_ Can a reader understand what this code does without running it? If not, make it more explicit.

---

## Package / Component Principles

Apply at module, package, or service boundary. From Robert C. Martin's *Clean Architecture*.

| Principle | Rule | Violation signal |
|-----------|------|-----------------|
| **ADP** — Acyclic Dependencies | No cycles in the dependency graph | Package A → B → C → A |
| **SDP** — Stable Dependencies | Depend in direction of stability | Stable core imports volatile UI module |
| **SAP** — Stable Abstractions | Stable = abstract; unstable = concrete | Core package of concrete classes that never change |
| **CCP** — Common Closure | Classes changing for same reason live together | Auth logic split across 4 packages |
| **CRP** — Common Reuse | Don't force callers to depend on things they don't use | One import pulls in 80 unrelated utilities |

_Quick test:_ Any cycle in the dependency graph = ADP violation. Arrow from stable → volatile = SDP violation.

---

## Principle Conflict Resolution

| Conflict | Winner | Rule |
|----------|--------|------|
| **DRY vs YAGNI** | YAGNI until third occurrence | Rule of Three: once fine, twice coincidence, three times extract |
| **DRY vs readability** | Readability | Two identical 3-line blocks clearer than one abstraction both call into |
| **KISS vs OCP** | KISS for current requirements | Extension points only when spec names a second variant |
| **SoC vs YAGNI** | YAGNI | Don't pre-separate concerns that don't exist yet |
| **Composition vs LSP** | Complementary, not conflicting | Inheritance only where LSP holds (true IS-A); compose everything else |
| **Fail Fast vs Postel** | Both, at different boundaries | Liberal on format variation (Postel); strict on correctness (Fail Fast) |
| **Encapsulation vs DIP** | DIP at module boundaries | Inject through interfaces; implementation details still hidden |
| **POLA vs performance** | POLA unless measured | No surprising behavior for speculative gains; optimize after profiling |

---

## GoF Design Patterns

Apply the right pattern for the right problem. Never apply a pattern without a concrete need (YAGNI applies here too).

### Creational

| Pattern | When to use | When to avoid |
|---------|------------|--------------|
| **Factory Method** | Creation logic differs by subtype | One concrete type exists |
| **Abstract Factory** | Families of related objects, must be swappable | Only one family exists |
| **Builder** | Complex object with many optional parts | Few required fields |
| **Prototype** | Clone expensive-to-construct objects | Construction is cheap |
| **Singleton** | Exactly one instance required (registry, config) | You just want global state |

### Structural

| Pattern | When to use | When to avoid |
|---------|------------|--------------|
| **Adapter** | Incompatible interfaces must work together | You control both interfaces |
| **Bridge** | Abstraction and implementation vary independently | Only one variant of each |
| **Composite** | Tree structures, part-whole hierarchies | Flat, non-recursive structure |
| **Decorator** | Add behavior without subclassing; stackable | One fixed behavior |
| **Facade** | Simplify complex subsystem behind one entry point | Subsystem is already simple |
| **Flyweight** | Many identical objects sharing intrinsic state | Object count is small |
| **Proxy** | Control access: lazy load, cache, auth guard | Direct access is fine |

### Behavioral

| Pattern | When to use | When to avoid |
|---------|------------|--------------|
| **Chain of Responsibility** | Multiple handlers; unknown which handles | One handler always applies |
| **Command** | Parameterize, queue, or undo operations | Fire-and-forget; no undo needed |
| **Iterator** | Traverse collection without exposing structure | Collection is directly iterable |
| **Mediator** | Many-to-many communication becomes complex | Few objects; direct calls fine |
| **Memento** | Capture state for undo without exposing internals | No undo requirement |
| **Observer** | One change must notify many, decoupled | Single listener; direct call sufficient |
| **State** | Behavior changes with internal state | Few states; simple `if/switch` fine |
| **Strategy** | Algorithm swappable at runtime or per context | One algorithm; no variation |
| **Template Method** | Algorithm skeleton fixed; steps vary | All steps vary (use Strategy) |
| **Visitor** | New operations on a stable object structure | Object structure changes frequently |

### Code Smell → Principle + Pattern

| Smell | Principle violated | Fix |
|-------|-------------------|-----|
| Giant `if/else` or `switch` on type | OCP, SRP | **Strategy** or **State** |
| Telescoping constructor (5+ params) | SRP, KISS | **Builder** |
| Objects notify each other, creating spaghetti | SoC, coupling | **Observer** |
| Subsystem internals leak into every caller | SoC, coupling | **Facade** |
| Many objects depend on many others | Coupling | **Mediator** |
| Object creation duplicated in multiple places | DRY, OCP | **Factory Method** / **Abstract Factory** |
| Can't add behavior without modifying a class | OCP | **Decorator** or new Strategy |
| Incompatible third-party / legacy interface | Coupling | **Adapter** |
| Expensive object re-created repeatedly | KISS, DRY | **Prototype** / **Flyweight** |
| God class — does everything | SRP, SoC | Decompose; **Facade** at the seam |
| Method reaches into objects it shouldn't know | SoC, LoD | Move method; **Mediator** |
| Fragile base — subclass breaks when base changes | LSP, OCP | Composition over inheritance |
| Logic duplicated across subclasses | DRY | **Template Method** |
| Can't undo an operation | — | **Command** + **Memento** |
| Tree structure treated inconsistently | SoC | **Composite** |
| Resource needs guarding (lazy, cached, auth) | SoC | **Proxy** |
| Abstraction and implementation locked together | SoC, coupling | **Bridge** |

### Pattern Combinations

| Combination | What it solves |
|-------------|---------------|
| **Command + Memento** | Full undo/redo |
| **Composite + Iterator** | Traverse tree without exposing structure |
| **Composite + Visitor** | Execute operations over entire object tree |
| **Composite + Chain of Responsibility** | Leaf passes request up to root |
| **Abstract Factory + Bridge** | Bridge abstractions needing specific implementation families |
| **Command + Prototype** | Clone commands into history |
| **Visitor + Iterator** | Traverse + execute typed operations over complex structure |
| **Flyweight + Composite** | Shared leaf nodes — saves RAM |

### Easily Confused Pairs

| Pair | Key difference |
|------|---------------|
| **Strategy vs State** | Strategy: independent, unaware of each other. State: concrete states may trigger each other |
| **Template Method vs Strategy** | Template Method: inheritance, static. Strategy: composition, runtime-swappable |
| **Decorator vs Proxy** | Proxy manages service lifecycle. Decorator composition controlled by client |
| **Decorator vs Composite** | Decorator: one child, adds behavior. Composite: aggregates children |
| **Adapter vs Decorator** | Adapter: different interface. Decorator: same or extended interface |
| **Adapter vs Proxy** | Proxy: same interface. Adapter: translates to different one |
| **Facade vs Mediator** | Facade: subsystem unaware of it, direct comms still OK. Mediator: components only know mediator |
| **Command vs Strategy** | Command: encapsulates operation as object (queue, undo). Strategy: swaps algorithm in one context |

### Pattern Evolution Path

Upgrade only when the trigger condition is met.

```
Creational
  Factory Method → Abstract Factory → Builder / Prototype
  Trigger: second concrete type → Factory Method
  Trigger: second product family → Abstract Factory
  Trigger: telescoping constructor → Builder

Structural
  Direct access → Proxy → Facade → Adapter
  Trigger: lazy load / cache / auth guard → Proxy
  Trigger: subsystem too complex for callers → Facade
  Trigger: third-party interface doesn't fit → Adapter
  Trigger: abstraction + implementation vary independently → Bridge

Behavioral
  if/else on type → Strategy / State
  Trigger: algorithm variants multiply → Strategy
  Trigger: behavior depends on object's own state → State
  Trigger: direct notification fan-out → Observer
  Trigger: Observer graph grows complex → Mediator
  Trigger: need undo → Command + Memento
  Trigger: same op over heterogeneous tree → Visitor
```

---

## Craft Principles

How code reads and evolves. Structural principles govern architecture. Craft governs the moment-to-moment experience of reading and changing code.

**Names Are Design** — If you can't name something clearly, the abstraction is wrong. `Manager`, `Handler`, `Util` signal no clear responsibility — name the actual thing. If naming is hard, the design is wrong. Rename before abstracting.

**Boy Scout Rule** — Leave code better than you found it. Improve the immediate vicinity. Commit separately from the feature change.

**Make the Change Easy, Then Make the Easy Change** — Refactor first so the feature is trivial to add. Never mix refactoring and feature work in the same commit. — Kent Beck

**Pure Functions** — No side effects. Same input always produces same output. Push I/O to the edges; keep core logic pure. Pure functions need no mocks.

**Immutable First** — Never mutate parameters. Prefer value objects. Prefer events over in-place mutation.
```
❌  function process(list) { list.push(item); }
✅  function process(list) { return [...list, item]; }
```

**Temporal Coupling Is a Smell** — Steps that must run in order but have no type-level enforcement create invisible coupling. If a comment says "call A before B" — encode it in the type system instead.

**Error Paths Are First-Class Citizens** — Every function's failure modes are part of its interface. Empty catch blocks, `null` returns on failure, and "something went wrong" messages are design failures. Return typed errors or throw named exceptions.

---

## Maintainability & Simplification

A reviewer's lens as much as an author's. Working code that leaves the codebase messier is not done. Prefer removing complexity over redistributing it.

**Delete, Don't Rearrange (Code Judo)** — When restructuring, prefer the move that removes whole branches, layers, or helpers over one that redistributes the same complexity elsewhere. The best reframing makes the change feel inevitable in hindsight — fewer concepts, fewer conditionals. A refactor that only moves complexity around has not paid for itself.
_Test:_ After the change, are there fewer concepts a reader must hold at once? If not, it wasn't a simplification.

**Reuse the Canonical Helper** — Before writing a helper, check whether the codebase already owns this concept. A bespoke near-duplicate of an existing canonical utility is a DRY violation on first write — the Rule of Three does not apply when the authoritative version already exists.
_Test:_ Does a canonical utility/service already do this? If yes, reuse or extend it — don't fork it.

**No Special-Case Bolt-Ons** — A new ad-hoc conditional dropped into an unrelated, already-busy flow is a design smell, not a localized fix. Push the logic behind its own abstraction, strategy, or module rather than tangling an existing path. Each such branch makes the surrounding code harder to reason about even when it works.
_Test:_ Is this branch here because it belongs here, or because here was convenient? If convenient, move it behind a dedicated seam.

**Explicit Boundary over Silent Fallback** — A new cast, `any`/`unknown`, optional param, or silent fallback that papers over an unclear invariant hides the real contract. Make the boundary explicit — a typed model or validated input — so the control flow gets simpler, not so the ambiguity gets buried.
_Test:_ Does this cast/fallback handle a real shape, or avoid naming an invariant? If the latter, make the boundary explicit.

**Serial and Non-Atomic Are Smells** — Independent work serialized for no reason should run in parallel; related updates that can leave state half-applied should be made atomic. Don't micro-optimize — but don't ship avoidable orchestration complexity that makes the flow more brittle.
_Test:_ Do these steps depend on each other? If not, why sequential? Can this multi-step update half-apply? If so, make it atomic.

---

## Planning Checklist

Run **before finalizing file structure and task decomposition** in `writing-plans`:

**Structure**
- [ ] **DRY:** Logic duplicated across tasks? Extract at third occurrence — not second.
- [ ] **KISS:** Abstraction with one concrete use? Remove the layer.
- [ ] **YAGNI:** Component not backed by a spec REQ? Remove it.
- [ ] **SoC:** File mixing two concerns? Split boundary.
- [ ] **Cohesion:** Every module described in one noun phrase without "and"?
- [ ] **Coupling:** Hardcoded dependency where an interface would do? Invert it.
- [ ] **ADP:** Module dependency graph has cycles? Break before building.

**Class / function design**
- [ ] **SRP:** Planned class with two change axes? Split it.
- [ ] **OCP:** Extension points open without modifying existing files?
- [ ] **ISP:** Any planned interface some implementors will stub? Split it.
- [ ] **LoD:** Method chains on foreign objects (`a.getB().getC()`)? Add delegation.
- [ ] **CQS:** Method both returning data and changing state? Separate.
- [ ] **Composition:** Inheritance used for reuse, not IS-A? Replace with composition.
- [ ] **Fail Fast:** Validation at entry points — not three layers deep?
- [ ] **Names:** Every class/function/variable describable in one clear noun/verb phrase?

**Patterns**
- [ ] **Pattern fit:** Coordination problem matches GoF pattern? Apply it. Applied pattern lacks concrete need? Remove it.
- [ ] **Conflict check:** Two principles conflict? Apply Conflict Resolution table.

---

## Review Checklist

Run **after implementation, before marking complete** in `executing-plans` and `requesting-code-review`:

**Structure**
- [ ] **No phantom abstractions:** Interface with one implementor without a spec extensibility REQ?
- [ ] **No leaking concerns:** Business logic in transport? UI logic in domain?
- [ ] **Cohesion:** Every module has one describable purpose — no "and"?
- [ ] **No mid-function `new`:** Dependencies injected, not constructed inline?
- [ ] **Encapsulation:** Internal data structures or schema details exposed to callers?

**Class / function design**
- [ ] **LSP:** Every subtype satisfies base contract? No `instanceof` checks in callers?
- [ ] **No fat interfaces:** Every method a client uses? No stubs?
- [ ] **OCP held:** New behavior through extension, not by editing working code?
- [ ] **LoD:** No method chains on foreign objects?
- [ ] **CQS:** No method both returns data and mutates state?
- [ ] **Immutability:** Parameters not mutated? Shared objects not modified in place?
- [ ] **Explicit:** No magic, hidden config, or order-dependent calls without type enforcement?
- [ ] **No comment-synced constants:** a literal constant (threshold, cap, multiplier) duplicated across ≥2 call sites, kept in sync only by a comment referencing the other site, not a shared named const? Fail — a comment is not enforcement; the next edit desyncs them silently.

**Craft**
- [ ] **POLA:** Every function does exactly what its name implies — no hidden side effects?
- [ ] **Fail Fast:** Bad input rejected at boundary, not three frames later?
- [ ] **Error paths:** Every failure mode returns typed error or named exception. No silent failures?
- [ ] **Pure functions:** Core logic side-effect free? I/O at edges?
- [ ] **Names:** Every identifier communicates purpose without a comment?

**Simplification & maintainability**
- [ ] **Code judo:** A reframing that deletes whole branches/layers, not just relocates complexity? If visible, take it — don't rubber-stamp working-but-messy.
- [ ] **Canonical reuse:** New helper duplicating an existing canonical utility? Reuse/extend it — a first-write duplicate is a DRY violation.
- [ ] **No bolt-ons:** New ad-hoc branch tangled into an unrelated busy flow? Push it behind its own abstraction.
- [ ] **Explicit boundary:** New cast/`any`/`unknown`/optional/silent-fallback papering over an unclear invariant? Make the boundary explicit.
- [ ] **Serial/atomic:** Independent work serialized for no reason (parallelize)? A multi-step update that can half-apply (make atomic)?

**Patterns**
- [ ] **Smell scan:** Giant switch-on-type, God class, telescoping constructor, notification spaghetti? Apply smell → pattern table.
- [ ] **Patterns justified:** GoF pattern present has documented need in task or spec?

---

## Extensibility — Beyond Code

| Domain | DRY | KISS | YAGNI | SoC | Loose Coupling |
|--------|-----|------|-------|-----|----------------|
| **API design** | One endpoint per resource operation | No endpoint doing two things | No endpoint for a caller that doesn't exist yet | Auth separate from business logic | Consumers depend on contracts, not implementation |
| **Data schemas** | No field duplicated across tables | No JSONB columns hiding structure | No columns for features not built | One table per entity type | Schema changes don't cascade to unrelated tables |
| **Workflow / pipeline** | No step repeated in two pipelines | No multi-purpose orchestration node | No stage for a future use case | Each step: one transformation | Steps communicate through well-defined outputs |
| **Skill / agent design** | No skill duplicating another's scope | Each skill does one thing well | No skill for a scenario not yet needed | Skill = one concern | Skills invoked through Skill tool, not hard-wired |
| **Documentation** | One authoritative location per fact | No 500-line spec for a 2-line feature | No section for decisions not yet made | API docs ≠ architecture docs ≠ runbooks | Docs reference by link, don't duplicate |

---

## Integration

| When | Checklist |
|------|-----------|
| `writing-plans` — before finalizing decomposition | Planning Checklist |
| `executing-plans` — before committing each task | Review Checklist |
| `requesting-code-review` — structural review lens | Review Checklist |
| `brainstorming` — when proposing architecture | Planning Checklist |

---

## References

**Foundational sources**
- DRY, YAGNI, Boy Scout Rule, Fail Fast → *The Pragmatic Programmer* — Hunt & Thomas (1999)
- KISS → Kelly Johnson / US Navy; McIlroy in software
- SoC → Edsger Dijkstra, "On the role of scientific thought" (1974)
- Law of Demeter → Lieberherr & Holland, Northeastern University (1987)
- CQS → Bertrand Meyer, *Object-Oriented Software Construction* (1988)
- Encapsulation / Information Hiding → David Parnas (1972)
- Postel's Law → Jon Postel, RFC 793 (1981)
- SOLID + Package principles (ADP/SDP/SAP/CCP/CRP) → Robert C. Martin, *Clean Architecture* (2017)

**Deep-dive companions**
- Full violation/fix tables for all principles → `skills/design-principles/principles.md`
- Full GoF applicability + relations → `skills/design-principles/references.md`

**GoF pattern detail by name:** `refactoring.guru/design-patterns/<pattern-name>` (kebab-case, e.g. `chain-of-responsibility`, `template-method`)
