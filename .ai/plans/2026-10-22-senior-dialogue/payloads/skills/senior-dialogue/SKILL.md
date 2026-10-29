---
name: senior-dialogue
description: >
  Use inside /engineer for every lane (depth scales with lane and risk). Runs the
  Senior Dialogue working model: understand → discuss → iterate to explicit,
  ledger-recorded human agreement → document → build test-first with zero
  check-ins. Explains every decision plainly from first principles with evidence
  and numbers, waits for the human even in autopilot/allow-all, and parks with one
  clear question instead of ever self-agreeing.
---

# Senior Dialogue

## Why this exists

Most code is now written by an agent and rarely read line by line. Ownership can
no longer come from reading code; it has to come from the human being able to
explain every decision that shaped it. So the agent and the human work as two
senior engineers: the agent brings evidence, numbers, and options; the human
brings intent, context, and judgment; nothing is built until both agree, and
agreement means the human could re-explain the decision to a third engineer.

Explain the Feynman way: plain words, first principles, one idea at a time, no
jargon without a one-line definition — and no babying. Assume a senior listener.

## The Iron Laws

```
1. A DECISION IS AGREED ONLY WHEN THE CONSENT LEDGER SAYS SO.
2. NO PRODUCTION CODE, TEST CODE, OR FINAL DOCS UNTIL `check` PASSES.
3. AUTOPILOT AND ALLOW-ALL ARE NOT CONSENT. NO HUMAN → PARK. NEVER SELF-AGREE.
```

Approval of a tool permission, silence, "looks good" about something not yet on a
card, or your own confidence are not agreement. Only a ledger row is.

## Two phases

| Phase | Waits for human? | What happens |
|---|---|---|
| **DISCUSS** | Yes, at every card | Agenda topics in priority order → decision cards → human agrees, revises, or parks each card |
| **BUILD** | No — zero check-ins | Generate docs from the agreed record, then plan → test-first construction → verification → PR, as fast as possible |

BUILD starts only when `check` exits 0 for every card in the work item's index
(the *build contract*). Inside BUILD, a human is needed again only when (a) a
gate finding or a discovery would change an agreed decision — open one new card
for exactly that and ask, (b) a subagent is BLOCKED, or (c) the spend circuit
breaker trips. Mechanical gate FAILs are fixed silently.

## The consent ledger (how agreement is recorded)

Host hooks — not you — write agreements into `<git-root>/.ai/dialogue/` from an
explicit human answer in the host's ask-user tool (or, on hosts where it is safe,
a typed human message whose whole first line is the agreement). A guard hook
denies any tool call that touches the ledger or carries the agreement token, so
you cannot record agreement yourself even by accident. Read
`references/consent-protocol.md` once per session before the first card: it has
the per-host ask-tool mapping, the answer format, and the park procedure.

Use the bundled script only through these subcommands (`<skill-dir>` is this
skill's base directory):

```bash
python3 <skill-dir>/scripts/dialogue-consent.py activate --work-item .ai/<id>
python3 <skill-dir>/scripts/dialogue-consent.py status            # agreed + pending
python3 <skill-dir>/scripts/dialogue-consent.py check             # exit 0 = build contract met
python3 <skill-dir>/scripts/dialogue-consent.py check D-004 D-007 # specific cards
```

Exit codes: `0` agreed · `3` something pending · `4` tamper or rule violation
(stop and tell the human) · `5` usage error. Never edit, move, or delete ledger
files; never write the agreement token into a file, commit, prompt, or subagent
brief — the guard will deny it.

## Work item layout

```
.ai/<YYYY-MM-DD-slug>/
  manifest.md                 # tier, phase, gate_status, dialogue depth (task/epic)
  dialogue/decisions.md       # all decision cards, newest last
  dialogue/decisions.json     # index: {"decisions":[{"id","title","topic","door","ev_hours","status"}]}
  dialogue/PARKED.md          # only while parked
  decisions/D-<NNN>-<slug>.md # ADR-lite per agreed card (written in BUILD)
```

Quick-fix and refactoring lanes create only `dialogue/` (no manifest). Run
`activate` immediately after creating the directory. Keep `decisions.json` in
sync with `decisions.md` every time you add or revise a card: `check` with no
ids reads it as the build contract, and `door: "one-way"` makes the ledger
demand a single-id agreement for that card.

## Step 1 — Open: D-000

D-000 is the working agreement for this work item. `/engineer` presents it as
its Step 2 block plus a card containing: lane and why, dialogue depth, the
agenda in priority order with, per topic, your runtime estimate of what
discussing it is expected to save and the reasoning behind that estimate,
the skill chain, the test-scenario iteration cap **N** (the human sets it; propose a value and
say why — how contested the scenarios are, what a review round costs), doc targets
(repo `docs/` by default; GitHub wiki or corporate wiki only if the human opts
in), and the optional token cap. For quick-fix and refactoring, D-000 also
carries the root cause or smell, the fix or move sequence, and the RED test —
one card, one answer, then BUILD.

## Step 2 — Order the agenda by risk, not by habit

Decide at runtime, per topic, whether it is worth the human's time. Reason it
out for this work item: how likely we are wrong now (and on what evidence),
what it costs if we are wrong and find out late, whether it is a one-way door,
and how much of the human's attention the card needs. Put numbers on it where
you can, each with its basis: evidence, a citation, or a labeled assumption.
`references/depth-scaling.md` describes the reasoning and gives illustrative
examples; never copy its numbers. Discuss the topics that clearly pay off,
highest expected saving first. Fold the rest into one batch card of stated
defaults ("agent calls") the human can agree to in one answer. One-way doors
are never batched. Hard ordering constraints override the ranking: (a) comes
first, (b) precedes (c) and (d), and (h) precedes any code. In D-000, state the
order and the reasoning, plus the skipped topics with reasons.

Topics (detail, questions, evidence and the producing skill for each are in
`references/agenda.md` — read the section for a topic right before discussing it):

| | Topic | Settles |
|---|---|---|
| a | Problem + current state | What is actually true today, proven from the codebase step by step |
| b | Business context + scope | Who, why now, measurable targets, non-goals, future scenarios — from the human, never self-agreed |
| c | HLD | Components, industry lessons, failure scenarios, capacity, threat model, trade-offs |
| d | LLD | Interfaces, data structures, error model, everything a consumer must know |
| e | CI/CD | The gold-standard pipeline for this slice |
| f | Deployment + releases | Rollout, migration, rollback, versioning |
| g | Observability + ops | SLIs/SLOs, alerts, runbooks |
| h | Test scenarios | REQ→TC matrix, levels, honesty, reviewer loop to sync or cap N |
| i | Test-first construction approach | Language/stack-level hazards (C23, C++23/26, web frontend depth in `references/systems-depth.md`) |
| j | Build | Only after `check` passes |

## Step 3 — Discuss one card at a time

For each topic in order:

1. **Look first.** Gather evidence before you talk: code (`file:line`), docs,
   standards, postmortems, benchmarks — web search and Context7 are expected,
   not optional. Never ask the human what the repo or the web already answers.
2. **Write the card** in `dialogue/decisions.md` using the template in
   `references/decision-cards.md`: plain explanation, evidence with citations,
   back-of-envelope numbers you derive now for this case (inputs, units, and
   the source or assumption behind each input), the realistic options (drop
   the weak ones) with trade-offs and a recommendation, the falsifier ("changes our mind if"), and a re-explain
   question. A card is not ready to show without at least one citation, or
   without derived numbers when the decision has a quantity (latency, load,
   cost, availability, probability).
3. **Present it in chat**, then ask through the host ask-user tool with exactly
   three options per card: agree, revise, park (format in
   `references/consent-protocol.md`). Batch two-way-door cards in one ask when
   they are related and the host allows it (Claude Code: four questions per
   call); always ask a one-way-door card alone, because the ledger requires a
   single-id agreement for it.
4. **Teach-back on one-way doors.** Before offering agreement on a one-way door
   (or any card where being wrong would be costly or hard to undo), ask the human to re-explain the decision in two
   or three sentences. If a load-bearing point is missing, ask one narrowing
   Socratic question (the `teacher` skill's Phase 4 style — no lecture, no
   answer). Then offer the ask. The human may say "skip teach-back" for a card.
5. **Read the result** with `status`. Agreed → mark the card `agreed` in both
   files and continue. Revise → rewrite the card with the human's input (theirs
   is marked as theirs; anything you filled in stays marked as your proposal)
   and ask again. Park, no answer, or an ask the host could not show → park.
6. **Iterate until sync.** Disagreement is information: bring new evidence or
   numbers, never repetition or pressure. When a card stops converging, look
   for the hidden sub-decision you disagree on and offer to split it out.

Business context (topic b) is the human's to give. You may propose, quantify,
and challenge, but every target, persona, and non-goal must arrive on a card
the human agrees to. Use `business-context-intake`'s eight questions as your
territory, asked conversationally, one per message.

## Step 4 — Test scenarios before code (topic h)

Follow `references/test-scenarios.md`: build the REQ→TC matrix with level tags
and a named wrong implementation each TC kills, dispatch
`test-scenario-reviewer` (`SCENARIOS_PATH`, `SPEC_PATH`, optional `LLD_PATH`,
`ITERATION=k/N`, `REPORT_FILE`), fix mechanical findings yourself, turn
substantive disagreements into cards, and loop until the reviewer returns PASS
and the human agrees the matrix card — or until N iterations, where the human
chooses accept-with-listed-gaps (recorded as its own card) or a larger N.

## Step 5 — Park when no human is present

If the ask tool is unavailable, returns without a human answer, is cancelled,
or the session is non-interactive: write `dialogue/PARKED.md` (template in
`references/consent-protocol.md`) with what is agreed, what is pending, and the
single highest-EV question; set the manifest `phase: parked`,
`gate_status: awaiting-human`; end the turn with a one-paragraph summary that
shows the human the exact reply to give. On Copilot autopilot, end with
`task_complete` stating PARKED. Ask once, then park — never loop on the ask
tool. While parked you may gather evidence and draft cards for pending topics;
you may not write code, tests, or final docs, or commit outside `dialogue/`.

## Step 6 — BUILD: document, then build, with zero check-ins

When `check` exits 0:

1. **Documents from the record** (`references/decision-cards.md`, "From
   agreement to documentation"): an ADR-lite per agreed card; the
   business-context doc, spec, HLD, LLD, and test-scenario matrix in their
   existing skills' formats; user-facing and developer-facing docs to the agreed
   targets. Every statement must trace to an agreed card (footer
   `Sources: D-…`). A statement with no agreed source is dropped or becomes a
   new card — so the human never has to review the docs separately.
2. **Gates run autonomously.** `spec-quality-gate`, `hld-reviewer`,
   `plan-reviewer`, and the other reviewers still run. A finding you can fix
   without changing an agreed decision is fixed silently; one that would change
   a decision opens one new card and asks for that card only.
3. **Human-approval steps in downstream skills are already satisfied.** The
   approval asks in `business-context-intake`, `brainstorming` (user review of
   the spec), `high-level-design` (human approval gate), `api-contract-first`,
   and the execution-choice question in `writing-plans` are satisfied by a
   passing `check` on the cards the artifact cites. Skip those asks; choose
   subagent-driven execution.
4. **Test-first, then code.** `writing-plans` maps every task's tests to TC ids
   from the agreed matrix; `test-driven-development` writes those tests RED
   first; `subagent-driven-development` runs the tasks. Then
   `verification-before-completion`, review, PR — no questions.

## Depth by lane (defaults — runtime reasoning can move topics in or out)

| Lane | Default depth |
|---|---|
| quick-fix | minimal: D-000 only (one answer) |
| refactoring | minimal: D-000 (smell, moves, test baseline) |
| research | light: a, b, then the recommendation card |
| task | standard: the topics whose discussion clearly pays off (usually a, b, d, h) |
| epic | full: a–j, teach-back on one-way doors |
| portfolio | D-000 + business inputs per epic; each pulled epic runs its own epic dialogue |

If a lighter lane uncovers a one-way door or a high-blast-radius change, say so
and step the depth up by re-presenting D-000. Never absorb it silently.

## Red flags — stop

| Thought | Reality |
|---|---|
| "The user is in autopilot, they want speed — I'll treat silence as yes" | Autopilot is not consent. Park. |
| "It's obvious, I'll write the code and explain after" | Iron Law 2. The card is cheap; rework is not. |
| "I'll record the agreement in the ledger for them" | You cannot, by design. Ask. |
| "I'll ask all 12 cards in one go to save time" | Batch only two-way doors, max four per ask. |
| "The human said 'sounds good' to the overview" | Agreement is per card, through the ask tool. |
| "I'll explain the whole design in one wall of text" | One idea at a time. Plain words. Numbers. |
| "The docs need a separate human review" | They don't — every line traces to an agreed card. |
| "The reviewer and I disagree; I'll keep looping" | Stop at N; the human decides. |

## Completion report

At the end of DISCUSS: agreed cards (ids + titles), parked or skipped topics with
reasons, and the build contract `check` result. At the end of BUILD: produced
artifacts with paths, gate verdicts, the TC ids exercised, and the PR link.
