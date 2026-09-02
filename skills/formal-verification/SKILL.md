---
name: formal-verification
description: >
  Use for a critical-core slice — cryptography, authentication/authorization, monetary
  arithmetic, consensus/replication invariants, memory-safety of unsafe blocks — written
  in a language with a real verifier (Rust/Verus, Dafny, Ada/SPARK, C/Frama-C, Java/OpenJML
  for full deductive proof; C++/CBMC/ESBMC for bounded model checking). Escalates a
  property-based-testing invariant into a machine-checked proof: writes requires/ensures
  contracts, discharges proof obligations against a live toolchain (version confirmed by
  web search at invocation, because verifier syntax churns fast), and blocks on undischarged
  obligations. Falls back cleanly to property-based-testing + deterministic-simulation-testing
  when no verifier exists for the language. Runs formal-verification-reviewer. Never claims a
  proof the toolchain did not produce.
---

# Formal Verification

Testing samples inputs and shows the *presence* of bugs on the cases tried.
Formal verification proves a property holds for *all* inputs — evidence of
absence for a whole bug class. It is the strongest assurance available, and the
most expensive. This skill applies it **only** where the payoff justifies the
cost: a small, stable, catastrophic-if-wrong core.

**This is a risk-gated specialist, not a default.** If you are reaching for it on
ordinary application logic, stop — that is the wrong tool. Real cost data: seL4
ran ~$350–400 per line of code; effort scales roughly quadratically with
specification size. LLM-assisted proof (vericoding) is bending that curve — Verus
auto-pass ~44%, Dafny ~82% and climbing — but more than half of Verus attempts
still need human proof labor. Spend it where being wrong is a breach, a data-loss
event, or a fund-mispayment — not on a CRUD endpoint.

## Step 0 — Eligibility gate (run first, always)

Two conditions must BOTH hold, or this skill does not run:

1. **Critical-core.** The change touches at least one of: cryptography, auth/authz
   decisioning, monetary or accounting arithmetic, consensus/replication/ordering
   invariants, or the safety of an `unsafe`/FFI block. If it is not
   catastrophic-if-wrong, exit — route to `property-based-testing`.

2. **A verifier exists for the language.** Use the tier table:

   | Tier | Language / tool | Guarantee |
   |------|-----------------|-----------|
   | **Full deductive** | Rust/**Verus**, **Dafny**, Ada/**SPARK**, C/**Frama-C-WP**, Java/**OpenJML** | proof holds for all inputs |
   | **Bounded** | **C++**/**CBMC** or **ESBMC**, C/**CBMC** | proof holds up to a stated loop/depth bound only |
   | **None** | Kotlin, TypeScript, JavaScript, Python, Go, Swift, Ruby | no deductive verifier |

   - **Full deductive:** proceed. You may state "proven for all inputs."
   - **Bounded (C++ especially):** proceed, but you MUST state the bound and MUST
     NOT claim an unbounded proof. A CBMC/ESBMC pass says "no violation up to
     bound N," nothing more. Pair it with property-based-testing for the
     unbounded tail.
   - **None:** exit immediately. Emit: "No deductive verifier for `<lang>`;
     escalating the invariant to `property-based-testing` and, for concurrent or
     distributed cores, `deterministic-simulation-testing` instead." Do not
     fabricate a proof. This exit is a success, not a failure.

Record the eligibility decision (both conditions, the tier, the fallback if any)
in the work-item manifest before doing anything else.

## Step 1 — Confirm the live toolchain (web search — mandatory)

Verifier toolchains churn faster than any frozen snippet can track (Verus
required 8 re-syncs in 6 months against upstream). Before writing a single
contract, web-search for the **current** state of the chosen tool:

- Latest release and any breaking contract/annotation syntax changes since this
  skill was last touched.
- Current recommended solver backend (Z3 / Alt-Ergo / cvc5) and known
  unsoundness or timeout pitfalls for the constructs you will use.
- Current vericoding SOTA idioms for that tool if LLM-assisted proof is in play.

Use the fetched syntax, not remembered syntax. If web search is unavailable this
session, say so and proceed with best-known syntax flagged as
version-unconfirmed — the reviewer will re-confirm.

## Step 2 — Fix the specification boundary

Take the formal spec from `spec-quality-gate` (or the invariant from a
`property-based-testing` escalation). Split its properties:

- **Proof-worthy** — small, stable, catastrophic-if-wrong. These get contracts.
- **Test-worthy** — everything else. These stay in tests. Do not gold-plate.

The single largest risk in FV is a **correct proof of a wrong specification** —
confidently wrong. The specification, not the proof, is where judgment lives.
State each contract in one plain sentence *before* formalizing it, and make sure
that sentence is what the system actually requires.

## Step 3 — Write contracts and discharge obligations

1. Write `requires` (preconditions), `ensures` (postconditions), and loop
   `invariant`s using the version-confirmed syntax.
2. Run the verifier. Let the SMT backend discharge what it can.
3. On an undischarged obligation, feed the solver's counterexample back and add
   the missing invariant or lemma (the iterative-refinement / vericoding loop).
   Bounded retries — do not loop forever.
4. If obligations remain undischarged after the retry budget: **do not ship a
   partial claim.** Either escalate to a human prover, or downgrade the
   unprovable property to property-based-testing and record why. A green build
   with silently-skipped obligations is worse than no proof.

## Step 4 — Emit a machine-readable verdict

Per non-negotiable #9 (determinism), the proof result must be structured, not
prose. Produce:

```json
{
  "tool": "verus",
  "tool_version": "<confirmed via web search>",
  "tier": "full_deductive | bounded",
  "bound": null,
  "solver": "z3-<version>",
  "obligations_total": 0,
  "obligations_discharged": 0,
  "obligations_undischarged": [],
  "spec_sentences": ["<one plain-language sentence per contract>"],
  "fallback_for_unproven": null
}
```

For the bounded tier, `bound` MUST be a number, never null.

## Step 5 — Review

Dispatch `formal-verification-reviewer` (opus). It re-confirms the proof
discharges against the *live* toolchain, and — its primary job — checks the
specification is correct, not merely that obligations closed. A passing proof of
a wrong spec is a Critical finding.

## Relationship to neighbouring skills

- **`property-based-testing`** is the on-ramp and the fallback. A PBT invariant
  that survives thousands of cases is the natural candidate to escalate to a
  proof; a language with no verifier sends the invariant back to PBT.
- **`deterministic-simulation-testing`** covers concurrent/distributed cores
  where a single-function proof is not the right shape.
- **`spec-quality-gate`** owns the formal-but-prose spec; this skill turns the
  proof-worthy subset into machine-checked contracts.
- **`pr-review-non-negotiables`** #1 (backward compat) and #3 (performance) name
  properties a proof can discharge more strongly than review — the reviewer notes
  where a proof now backs a non-negotiable.

## Completion Report

When this skill's work is done, report to the user in chat:

- **Eligibility:** critical-core reason + language tier (or the clean fallback taken).
- **Tool + version:** which verifier, which version (web-confirmed), which solver.
- **Proof:** obligations discharged / total; the bound if bounded-tier.
- **Spec:** the one-sentence contract(s) proven — so a human can sanity-check the spec, not the proof.
- **Verdict:** did `formal-verification-reviewer` pass.
- **Next:** back to verification-before-completion, or the unproven tail routed to PBT.
