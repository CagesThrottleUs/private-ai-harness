# Formal Verification: Trend Analysis and Harness Readiness Assessment

**Date:** 2026-09-02
**Author:** laksh@adobe.com
**Type:** Research artifact / decision input (non-binding)
**Trigger:** Amazon Science article on provably-correct Rust with Verus
**Status:** Draft for review

---

## 1. Executive Summary

Formal verification (FV) is a decades-old technique for proving software correct
against a mathematical specification, historically confined to safety- and
security-critical niches because of its extreme cost. Two independent shifts —
the mainstreaming of Rust and the arrival of LLMs capable of writing machine-
checkable proofs ("vericoding") — are, for the first time, bending FV's cost
curve and pulling it toward wider relevance.

The honest assessment: this is a **real, well-funded, fast-improving trend**, but
it remains a **high-assurance niche that is expanding**, not a general-purpose
default that will replace testing. The cost wall (roughly 100×–1000× normal code,
scaling quadratically with specification size) is being eroded by LLMs but is not
gone, and the hardest part — writing a *correct specification* — is human
judgment that does not automate away.

The `private-ai-harness` currently sits entirely on the **probabilistic**
assurance side (spec gates, reviewer agents, tests, property-based and
deterministic-simulation testing). It has **zero deductive (proof-based)
coverage**. It is well positioned to add FV as a **risk-gated specialist** for a
narrow critical-core slice, consistent with its own complexity-assessment and
YAGNI discipline. It should not be made a first-class, always-on gate; the
economics do not justify that today.

**Recommended FV-readiness rating: 2/10 today, with a low-cost, high-leverage
path to a scoped 6–7/10.**

---

## 2. Primer: What Formal Verification Is

### 2.1 The core idea

Conventional testing runs code on a finite set of inputs and checks the outputs.
It can only ever demonstrate the presence of bugs on the inputs tried, never
their absence on the inputs not tried.

Formal verification inverts this. It requires three artifacts:

1. **Specification** — a mathematical statement of what the code must do,
   expressed as pre-conditions, post-conditions, and invariants (e.g. "the output
   is sorted and is a permutation of the input").
2. **Implementation** — the actual code.
3. **Proof** — a machine-checked argument that the implementation satisfies the
   specification for *all* possible inputs.

Where a passing test says "no bug found in the cases I tried," a passing proof
says "this class of bug cannot occur." It is evidence of absence.

In practice the engineer supplies *proof hints* (loop invariants, lemmas) and an
automated solver — typically an SMT solver such as Z3 — discharges the remaining
obligations.

### 2.2 The landscape of tools

| Tier | Tools | Character |
|------|-------|-----------|
| Practical program verifiers | **Verus** (Rust), **Dafny**, **SPARK** (Ada) | Verify real systems code; annotations live alongside the program. |
| Proof assistants | **Lean**, **Coq**, **Isabelle** | Math-grade, maximally powerful, highest effort. Used for the seL4 kernel. |

### 2.3 Verus specifically

Verus is formal verification embedded directly in Rust. Functions are annotated
with `requires` / `ensures` / `invariant` clauses; Verus lowers these to proof
obligations for Z3. Rust's ownership model already eliminates memory-safety bugs;
Verus adds **functional correctness** — a guarantee that the logic itself is
right, not merely that memory is handled safely. It received a best-paper award
at SOSP 2024.

---

## 3. The Trend and Why It Is Happening Now

Formal verification has existed for roughly forty years and remained niche. Two
structural changes are altering its trajectory simultaneously.

### 3.1 Rust reached the mainstream

- 48.8% of surveyed organizations now make non-trivial use of Rust, up 10.1
  percentage points in two years (2025 State of Rust Survey).
- The Linux kernel reclassified Rust from experimental to a core language in
  December 2025.

Rust's type and ownership system is a natural foundation for verification. Verus
rides this adoption directly.

### 3.2 LLMs attack FV's single largest cost — proof labor

FV's historical blocker was the human effort of writing proofs. LLMs make that
labor cheap. This has produced a named paradigm:

> **Vericoding** — the LLM generation of *formally verified* code from a *formal
> specification*. It is the disciplined counterpart to "vibe coding," which
> produces potentially buggy code from a natural-language description.

The strategic significance is the convergence: the technology that lowers proof
cost (LLMs) and the language that provides a verification substrate (Rust) both
matured at the same moment.

---

## 4. The Numbers (Cold Analysis)

### 4.1 Market

- The "formal verification copilot" market was valued at **$1.8B in 2025** and is
  projected to reach **$6.2B by 2034**, a **14.7% CAGR** (2026–2034).
- Fastest-growing deployment sub-segment: cloud, at 18.3% CAGR.
- Highest-growth vertical: automotive, 16.1% CAGR, driven by ISO 26262 ASIL-D
  mandates for next-generation ADAS silicon.
- **Caveat:** this market is concentrated in semiconductors, aerospace, and
  automotive — *not* general application development.

### 4.2 Investment signal

- Pramaana Labs raised a **$27M seed led by Khosla Ventures in June 2026** to
  bring formal verification to AI in high-stakes verticals. Capital is flowing.

### 4.3 Capability (vericoding benchmark, 12,504 specifications, POPL 2026)

| Target language | Automated pass rate |
|-----------------|---------------------|
| Dafny | 82.2% |
| Verus (Rust) | 44.2% |
| Lean | 26.8% |

- Pure Dafny verification success rose from **68% to 97% in a single year** of
  LLM progress — a steep improvement curve.
- Adding natural-language descriptions barely improved results; the *formal
  specification* is what carries the signal.

### 4.4 The cost wall (why FV is not yet everywhere)

- The seL4 microkernel cost approximately **$350–$400 per line of code**, at
  ~12–20 person-years for ~8,500 lines.
- Verification effort scales **roughly quadratically** with specification size —
  the dominant barrier to large or fast-changing codebases.
- Toolchain immaturity is real: the verified memory-management module of the
  Asterinas OS required **eight re-synchronizations over six months** to keep pace
  with Verus updates.

Interpretation: FV today costs on the order of 100×–1000× normal code. LLMs are
bending this curve sharply, but Verus at 44% automated pass means more than half
of cases still require human proof work.

---

## 5. Value Assessment: Current vs. Future

### 5.1 Where FV pays today (positive ROI)

Small, stable, catastrophic-if-wrong cores: cryptography (e.g. AWS s2n, the Cedar
authorization engine), kernels (seL4), chip logic, and ADAS. The blast radius is
enormous while the code is small and effectively frozen, so the one-time proof
cost amortizes.

### 5.2 Where it does not pay today

Ordinary application and business logic. It churns frequently, its per-feature
value is modest, quadratic scaling is punishing, and specifications go stale as
requirements move. A CRUD endpoint does not warrant a proof.

### 5.3 The 2–5 year outlook

- As LLMs continue to drop proof cost, the boundary of "verify the tiny critical
  core, test the rest" moves outward, and progressively more code becomes worth
  verifying.
- **The durable ceiling:** the specification itself remains hard. A perfectly
  proven implementation of a *wrong* specification is confidently wrong. Writing
  the correct spec is human judgment and does not automate away.
- Realistic destination: FV becomes a first-class *option* for a growing
  critical-core slice — "vericoding for the 5% that matters most" — not a
  universal replacement for testing.

**Bottom line:** a genuine trend with real money and a steep capability curve,
but structurally a high-assurance niche that is expanding. Any claim of "formal
verification for all AI code by 2027" is overselling; the 44% Verus pass rate and
the quadratic cost wall are the cold constraints.

---

## 6. Harness Readiness Assessment

### 6.1 Current posture

The harness treats **process rigor as a correctness proxy**: spec-quality gates,
40+ reviewer agents, the PR non-negotiables, TDD, property-based testing, and
deterministic-simulation testing. Every mechanism provides **probabilistic**
assurance (sampling, review, judgment). None provides **deductive** assurance
(proof).

### 6.2 Closest existing components

| Skill | Relationship to FV |
|-------|--------------------|
| `property-based-testing` | Checks invariants (round-trip, idempotence, algebraic laws) over generated inputs. One conceptual step toward specifications — but still sampling, not proof. |
| `deterministic-simulation-testing` | Seeded, replayable fault injection (TigerBeetle/FoundationDB style). Strong for concurrency; still not proof. |
| `spec-quality-gate` | Enforces falsifiable, testable specifications in prose. The natural hook point for formal specifications. |

### 6.3 The gap

There is no formal verification anywhere in the harness. No skill emits
`requires` / `ensures` clauses; no reviewer checks that a proof discharges.
Notably, PR non-negotiables #1 (backward compatibility) and #3 (performance) name
exactly the properties FV proves best — yet the harness verifies them by review,
not by proof.

### 6.4 Rating

**FV-readiness: ~2/10 today** — entirely probabilistic, no deductive coverage —
but well-positioned to add a scoped capability that could reach **6–7/10** for
the critical-core slice.

---

## 7. Recommendations

The correct move is *not* "verify everything" — that would contradict the
harness's own Karpathy simplicity and YAGNI discipline, and the cost economics
forbid it. The correct move is a sharp, risk-gated tool for the 5% of code where
being wrong is catastrophic.

1. **Add a `formal-verification` skill, gated to the critical-core slice only.**
   Explicit trigger: cryptography, authentication/authorization, monetary math,
   and invariants named in `pr-review-non-negotiables`. Default to skip unless
   catastrophic-if-wrong — mirroring the existing complexity-assessment table in
   `workflow`.

2. **Bridge from existing strength.** Escalate a `property-based-testing`
   invariant into a formal `ensures` clause when risk warrants. PBT finds a
   counterexample cheaply; FV proves none exists. This is a natural escalation
   ladder rather than a new silo.

3. **Add a vericoding review dimension.** When a spec carries a formal contract, a
   reviewer confirms the *proof discharges* — not merely that a test exists. This
   aligns with non-negotiable #9 (determinism): a machine-checked proof is the
   strongest possible structured, machine-verifiable output.

4. **Do not make it first-class or always-on.** The cost curve makes that wrong
   today. Position it as a specialist the "engineering-department-in-a-box"
   currently lacks — the verification/safety-critical role — triggered by risk and
   consistent with the harness's existing skip logic.

If adopted, this must follow the meta-doc sync rule: a new skill and reviewer
require updates to `AGENTS.md`, `CLAUDE.md`, and `README.md` in the same commit,
plus a version bump across all three manifests.

---

## 8. Sources

- [Amazon Science — Developing provably correct Rust with Verus](https://www.amazon.science/blog/developing-provably-correct-rust-code-with-verus)
- [Verus: A Practical Foundation for Systems Verification (SOSP 2024)](https://dl.acm.org/doi/10.1145/3694715.3695952)
- [Formal Verification Copilot Market Research Report 2034](https://dataintelo.com/report/formal-verification-copilot-market)
- [A benchmark for vericoding: formally verified program synthesis (POPL 2026)](https://arxiv.org/abs/2509.22908)
- [Vericoding: The End of "Trust Me Bro, The AI Wrote It"](https://blog.icme.io/vericoding-the-end-of-trust-me-bro-the-ai-wrote-it/)
- [seL4: Formal Verification of an Operating-System Kernel (CACM)](https://cacm.acm.org/research/sel4-formal-verification-of-an-operating-system-kernel/)
- [Formal Methods in Industry: A Critical Evaluation of Their Use at AWS](https://dl.acm.org/doi/10.1145/3815784)
- [Rust's 2026 Adoption Surge](https://www.refontelearning.com/blog/rust-adoption-linux-kernel-memory-safety)
- [Towards Practical Formal Verification for a General-Purpose OS in Rust (Asterinas)](https://asterinas.github.io/2025/02/13/towards-practical-formal-verification-for-a-general-purpose-os-in-rust.html)
