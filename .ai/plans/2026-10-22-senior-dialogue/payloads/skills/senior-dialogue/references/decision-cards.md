# Decision Cards — explain, evidence, quantify; then document

## The card template

Append to `.ai/<id>/dialogue/decisions.md`. Update `decisions.json` in the same
edit.

```markdown
### D-<NNN> — <the decision, as a short title>

- **Topic:** <a–j> · **Door:** one-way | two-way · **Status:** proposed | agreed | revised | parked
- **Worth discussing because:** <runtime reasoning: how likely we are wrong now and on what evidence; what it costs if wrong and found late, and the basis for that estimate; reversibility>

**Plainly.** As short as the decision allows, readable in one pass. What we
are deciding and why, from first principles,
as you would explain it to a strong engineer from another team. One idea per
sentence. Define any term a generalist might not know in one line.

**Evidence.**
- <claim> — <citation: `file:line`, doc URL + version, paper, postmortem, benchmark>

**Numbers.** <derived now for this case: formula, inputs with units, and for each input whether it is measured, sourced (cite), or assumed (say why)>

**Options.**
| Option | Gain | Pay |
|---|---|---|
| A (recommended) | … | … |
| B | … | … |

**Changes our mind if.** <an observable condition that would flip the decision>

**Re-explain check.** <one question the human should be able to answer after agreeing>

**Theirs vs mine.** <what the human stated; what you proposed and why>
```

Batch cards (agent calls) use the same header, set `Door: two-way`, and replace
the body with a table: `default | why | what would change it`.

## Explaining (Feynman, for seniors)

- Start from the constraint that forces the decision, not from the solution.
- Build up in steps; each step should be checkable on its own.
- Use the concrete case (this codebase, this load) before the general rule.
- Name the trade-off plainly: "we buy X by paying Y".
- If you cannot explain it simply, you do not understand it yet — go back to
  evidence, do not add words.
- No babying: skip definitions a senior engineer knows; never restate the
  human's own words back as explanation.

## Evidence rules

Every card needs at least one citation. Acceptable sources, strongest first:

1. The repository itself (`file:line`, test output, command output).
2. Official documentation, version-matched (Context7 or the vendor site).
3. Standards and specifications (ISO, RFC, W3C/WHATWG, NIST).
4. Peer-reviewed papers and well-known industry papers.
5. Public postmortems and incident reports — name the incident and the lesson.
6. Reproducible benchmarks — with method and hardware; never "X is faster"
   unqualified.

Mark anything you could not verify `unverified` and do not let it carry a
recommendation. Web-confirm anything version-sensitive at dialogue time.

## Rational backing at runtime

Every argument you make in the dialogue must be backed when you make it, for
this case, in front of the human. Use whichever of these fits the claim:

- **Evidence**: what the code, docs, standard, or incident record actually
  says (cited).
- **Derivation**: a back-of-envelope calculation built from this work item's
  own inputs, with units and the basis of each input.
- **Comparison**: the options' gains and costs on the same axes.
- **Falsifier**: what observation would prove you wrong.

Do not reach for a stock number. If an input is unknown, say so, give a range,
and either ask the human or propose how to measure it cheaply. A conclusion
whose inputs the human cannot inspect is an opinion, not an argument.

### Example derivations (illustrative; derive your own each time)

These are well-known tools that often fit. They are examples of the kind of
backing expected, not a checklist. Cite the source when you use one, and plug
in this case's numbers.

| Question | One way to reason about it | Example |
|---|---|---|
| How many in flight? | Little's Law `L = λ × W` | 200 req/s × 0.05 s ≈ 10 concurrent |
| Serial availability | `A = Π Aᵢ` | three 99.9% hops ≈ 99.7% |
| Redundant availability | `A = 1 − Π (1 − Aᵢ)`, assumes independent failures, so say whether they are | |
| Error budget | `(1 − SLO) × window` | 99.9% over 30 d = 43.2 min |
| Fan-out tail | `P(≥1 slow) = 1 − (1 − q)ⁿ` | 100 calls at p99 → 63% (Dean & Barroso, "The Tail at Scale", CACM 2013) |
| Failure over n tries | `1 − (1 − p)ⁿ` | retries, deploys, disks |
| Cost | units × unit price | cite the pricing page and date |
| Choosing between options | expected value `Σ pᵢ × payoffᵢ`, plus the worst-case regret | |
| Storage | rows × bytes/row × replication × retention + index overhead | |

Order-of-magnitude reference numbers are fine for a first estimate. Label them
as such and prefer a measurement when the decision hinges on them.

## From agreement to documentation (BUILD step 1)

Documentation is generated after agreement, from the agreed record, so the
human never has to review it separately.

| Output | Source cards | Producer / format | Location |
|---|---|---|---|
| ADR-lite per agreed card | that card + its ledger status | template below | `.ai/<id>/decisions/D-<NNN>-<slug>.md` |
| Full ADR per one-way door | the card | `high-level-design` ADR format | `wiki/architecture/ADR-NNN-<slug>.md` |
| Business context | topic b | `business-context-intake` template | `.ai/<id>/business-context/` |
| Spec (REQ format) | b, d, h | `brainstorming/references/requirement-format.md` | `.ai/<id>/specs/` |
| HLD | c | `high-level-design` | `.ai/<id>/hld/` |
| LLD + consumer docs | d | agenda (d) checklist | `.ai/<id>/lld/` |
| Test-scenario matrix | h | `test-scenarios.md` | `.ai/<id>/tests/test-scenarios.md` |
| CI / deploy / observability | e, f, g | their skills | as those skills specify |
| User-facing docs | b, d | README section, usage guide, CHANGELOG entry | repo `docs/` (default) |
| Developer-facing docs | c, d, i | architecture overview, onboarding delta | repo `docs/` or `wiki/` |
| External wiki | any | GitHub wiki (clone `<repo>.wiki.git` with `gh`) or a corporate wiki tool | only if D-000 opted in |

Rules:

- Every generated section ends with `Sources: D-<NNN>, …`.
- A statement with no agreed source is either removed or raised as a new card.
- Reviewers (`spec-quality-reviewer`, `hld-reviewer`, `plan-reviewer`, …) run
  on the generated artifacts autonomously; see SKILL.md Step 6 for how their
  findings are handled.
- Write for the reader: user docs answer "how do I use it and what can go
  wrong"; developer docs answer "why is it shaped like this and how do I change
  it safely". Lead with an example.

### ADR-lite template

```markdown
# D-<NNN>: <title>

**Status:** Agreed (ledger) · **Date:** YYYY-MM-DD · **Door:** one-way | two-way

## Context
<the forcing constraint, from the card's "Plainly">

## Decision
<the chosen option, one paragraph>

## Evidence and numbers
<from the card, citations kept>

## Alternatives
<the other options and why not>

## Consequences
<what gets easier, what gets harder, the falsifier to watch>
```
