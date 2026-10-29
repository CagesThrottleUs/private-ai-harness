---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, modifying behavior, or planning anything new. Draws out what the user actually wants and why, plays it back for correction, sizes the work, then produces a design/spec before implementation."
---

# Brainstorming Ideas Into Designs

You are very good at building. You build what you believe your human partner wants, and that belief is usually thinner than it feels. This skill finds out what they actually want, and why, before anything gets built — then turns it into a design/spec.

People often haven't finished working out what they want. Good questions help them think it through. When you understand the why, you make the hundred decisions they never mention the way they would have made them.

Start by understanding the current project context, then draw out intent through conversation, playing each part back as you understand it. Once you understand what you're building, size the work, write it down, and get user approval.

## First: What Do You Actually Know?

Before you reply, ask: what do I know about what they want, and why?

- **Everything that matters is in the request** ("make the icon cornflower blue"). This is a quick, clear task. Do it and say what you did — no spec, no gate.
- **Something non-trivial is missing.** Look first, then start the conversation (below).

Before you implement anything else, you must, in order: (1) lay out the approaches in a message of their own and have them pick one; (2) write the design doc, short or full (see Size the Work); (3) get their approval of that doc; (4) invoke the next skill (`high-level-design` or `writing-plans`). A spike they said yes to is not implementing.

## Look Before You Ask

In an existing project, or when they've given you context (a spec, a plan, a handoff, a business-context doc, files they pointed at, earlier conversation), dig in before your first message. Read what they referred to and the code or material it connects to, until you can explain how the relevant parts work today and what this change would touch. Never ask what the project or their context already answers.

## Your First Message

Move the work forward with one of these:

- **They've already said what they want** (a spec, a plan, a detailed request): about 200 words. Echo the request in your own words — what, for whom, why, as far as they've said. Add what you found that bears on it: how the relevant parts work today and what the change would touch. If you found a constraint, conflict, or cheaper path they may not have considered, say so plainly. How to build it comes later (Lay out the approaches). End with one line inviting corrections, then one question about the thing their request leaves open whose answer would most change what gets built.
- **They haven't:** one open question, in their terms, about the biggest thing still unsettled, and say what the answer would change about what you build.

How it ends depends on whether they asked for brainstorming:

- **They asked for it** (by name, `/brainstorming`, or asked for a design discussion): end with your question. They want this conversation.
- **They didn't:** after your question, add a light one-line offer to just get going ("Or if you'd rather I just dive in, say so"). If they take it, the *conversation* is done: state any significant how-it-gets-made choice (platform, language, medium) in one plain line, then proceed through the harness gates below (Business Context and spec still apply to feature work — they are harness policy, not questions).

You never need to quote this skill to your human partner.

## The Conversation

Each message ends with one question — a single sentence, no list of example answers hanging off it. Plain language, pitched slightly above where they are; match their vocabulary, never use process jargon. Lead with what matters; offer the rest.

- **Get them describing.** Open questions first — their own words carry intent your options can't. Offer a short menu (or `AskUserQuestion`) only when they're stuck. When they say "just guess" or "what do you think?", propose something concrete. A guess they can correct ("I'm guessing this is because X keeps biting you?") often beats a question.
- **How it gets made.** Find out early which choices about medium and tools (platform, language, libraries; medium for non-software) they want to own, which they hand to you, and what they already have. Strong views → talk it through. Handing over → pick sensible defaults and say them out loud. With existing work, build on what it already uses. Any choice you make goes in the spec as *your call*, never as something they agreed to. (Upstream added this after a session designed an iOS app, never asked about platform, and built a web app.)
- **Ground to cover** (territory, not a script — never read these out as questions): what kind of thing this is and what makes it special; why now and what success looks like to them; goals, non-goals, anti-goals (what would make it a failure even if it technically works); prior art they loved or hated; current state and what they've tried; the details they care about.
- **Make every question specific** to their project and what they've told you. Ask Socratically, like a sharp colleague: build each question on their last answer or on something you found, so it helps them think through a consequence or case they may have missed. When the reason isn't plain, say what the answer would change. A proposal they can correct, plus your reason for it, often beats a question.
- **Offer recon.** Once you have some grounding and looking would help, offer to look — their codebase/project, their files and data, or the web. Say what you'd look for; they decide.
- **Lay out the approaches.** Once you understand what they want, and before you write anything up, put the ways of building it in a message of its own. Generate several real alternatives privately and drop the weak ones (including any that work against *why* they want it or that the existing work rules out). Present the two or three that remain, grounded in what the project actually does, with what each trades off; recommend one and say why, then ask which way they want to go. If there's genuinely one sensible way, say so and why the others don't fit.
- **Show, don't tell.** Offer the Visual Companion (below) whenever seeing would help more than reading.
- **Spike to feel things out.** A quick throwaway build is often the cheapest way to learn what they want or whether something works. Offer one when it would help. When they just want to spike, get out of the way: spikes get no/minimal tests, aren't bulletproof, and skip plan/implementation/review. Bring what it taught you back into the conversation. Keeping spike output is a new request that returns through the gates.

## Play It Back

As soon as you understand one part well enough to describe it (what it's for and who it serves, how one piece behaves), describe that part back in ~200-300 words, then return to questions about the next part. Playback and questions alternate; the last chunk covers what's left. Only what they said goes in as theirs; anything you filled in goes in as *your proposal*, with your reason. End each chunk by asking what's wrong or missing.

If a chunk describes something they'll look at (page, screen, schedule, printout) and they haven't seen the Visual Companion offer yet, send the offer instead (its own message) and hold the chunk. Once they've accepted, put a mockup next to the description.

## Size the Work

Once you understand what they want and they've picked an approach, say how big the work is in plain words. They can override it; if it grows mid-task, stop, say so, and step up a size. If it is really several independent projects, say so, agree an order, and brainstorm them one at a time.

| Size | Full description | Then |
|------|------------------|------|
| Quick, clear task | the request itself | do it |
| Small change (bug fix, config, isolated utility — no business-context doc needed) | short design doc: what you covered together, written down, a line or two per point, plus Approaches; no builder check | `writing-plans` directly |
| Feature / project | REQ-format spec (`references/requirement-format.md`), through the gates | `high-level-design` or `writing-plans` |

Short or full, the design doc has an **Approaches** part: the two or three ways considered, what each trades off, which one they picked, and why.

## What a Great Spec Looks Like

The bar is SQLite, RFC 8446, seL4, WebAssembly, and DO-178C: every statement testable, every requirement traced to a test. Read `references/requirement-format.md` before writing a spec.

## Anti-Pattern: "This Is Too Simple To Need A Design"

"Simple" features are where unexamined assumptions cause the most wasted work. Sizing is a judgment made *after* you understand what they want and stated out loud — not a shortcut taken before asking. Approval covers what you showed them: "sounds good" to an idea is not approval of a design doc you haven't written.

| Thought | Reality |
|---------|---------|
| "I'll offer a menu of what they might want" | Options steer. Ask them to describe it first. |
| "I've answered their questions, so I'll write the doc" | Lay out the approaches first, in a message of their own. |
| "I'll fill in sensible defaults" | Good. Say them out loud — a default they never heard is one they couldn't reject. |
| "I should explain the process first" | Ask your question. The process shows itself. |
| "The spike works, I'll keep building on it" | Keeping it is a new request. Back through the gate. |

## Pre-Condition: Business Context Document

<HARD-GATE>
Before the first message of a feature/enhancement (not a bug fix, config change, or quick clear task), check if a business context document exists:

```bash
ls .ai/*/business-context/*.md 2>/dev/null
```

If absent AND this is a feature/enhancement (not a bug fix or config change): stop and invoke `business-context-intake` skill. Do NOT proceed with brainstorming without a completed business context document. The LLM cannot know the user's business context — a human must provide it.

If present: read it. Every design question must be anchored to the problem, persona, and success metrics in that document.
</HARD-GATE>

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Explore project context** — check files, docs, recent commits; read the task's `.ai/<feature-slug>/business-context/` if exists
2. **Look before you ask, then first message** — echo + findings + one question, or one open question (see Your First Message)
3. **Converse and play back** — open questions first, one per message; play each understood part back in ~200-300 words, marking your guesses; offer recon, spike, and the visual companion (its own message) when each would help
4. **Lay out 2-3 approaches** — in a message of its own, with trade-offs and your recommendation; they pick
5. **Size the work** — say it in plain words; quick clear task → do it; small change → short design doc → approval → `writing-plans`; feature/project → continue below
6. **Present design** — in sections scaled to their complexity, get user approval after each section
7. **Write design doc** — save to `.ai/YYYY-MM-DD-<topic-slug>/specs/specs-<topic-slug>-design.md` using the requirement format in `references/requirement-format.md`; commit
8. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
9. **Run spec-quality-gate** — invoke `spec-quality-gate` skill, which dispatches `spec-quality-reviewer` agent with fresh context; fix all FAIL items before proceeding
10. **Builder check** — dispatch a fresh subagent with `builder-check-prompt.md`; sort its questions into answered / minor / theirs (see below)
11. **User reviews written spec** — ask user to review the spec file before proceeding
12. **Transition to architecture or implementation** — for architectural changes (new services, data models, external integrations, security boundaries): invoke `high-level-design` skill. For non-architectural changes (bug fixes, config, isolated utilities): invoke `writing-plans` directly.

## Process Flow

The flow graph is in `references/process-flow.md`; the Checklist above walks
the same flow in order.

**The terminal state is invoking high-level-design (for architectural changes) or writing-plans (for non-architectural changes).** Do NOT invoke frontend-design, mcp-builder, or any other implementation skill. The only valid next skills after brainstorming are `high-level-design` and `writing-plans`.

## The Process

Before laying out approaches, read `references/design-process.md`: score options against named quality-attribute scenarios (ATAM), name each approach's riskiest assumption (RAT), present the design in sections scaled to complexity, and decompose by what each unit hides (Parnas). Use `AskUserQuestion` only for a 2-4 option branch or when they're stuck.

## After the Design

**Documentation:**

- Write the validated design (spec) to `.ai/YYYY-MM-DD-<topic-slug>/specs/specs-<topic-slug>-design.md`
  - (User preferences for spec location override this default)
- Use the `references/requirement-format.md` — every statement is a REQ-NNN with measurable acceptance criteria
- Pick `spec_id` by checking `grep -h '^spec_id:' .ai/*/specs/*.md 2>/dev/null` for the highest existing `SPEC-N` and incrementing; use `SPEC-1` if none exist
- Set `north_star` by copying the one north-star metric (and target) verbatim from the business-context doc read in the Pre-Condition gate. If this is a bug fix / config change with no business-context doc, set it to `N/A — <reason>`. This value threads forward into the plan's Global Constraints and the PR body — do not leave it blank.
- Commit the design document to git

**Requirement Format, quality rules, and spec self-review:** read `references/requirement-format.md` (this directory) before writing the spec and follow it exactly — it is not optional. Run its self-review checklist (starting with `pre-lint.sh`) before the gate.

Fix inline, then invoke `spec-quality-gate` skill (which dispatches `spec-quality-reviewer` agent) for the formal pass. The agent still owns judgment calls the script can't make (2b/2c/2d, 3a-3d, north star) — the pre-lint only removes the mechanical failures that would otherwise cost a full round-trip for a typo-class issue.

**Builder Check:**
After `spec-quality-gate` passes, dispatch a fresh subagent with `builder-check-prompt.md` (this directory) and the spec path; domain is usually "software engineer". It reads the spec as the person who must plan from it and lists what they'd still need to ask. When you tell the user you're writing it up, say a reviewer will read it first and you may come back once with a few questions. Don't hand over the spec until the check is back. Sort its questions into three piles:

- **Answered already** by the conversation or project: put the answer in the spec (as a REQ/AC/assumption — keep the format and re-run `pre-lint.sh`).
- **Minor:** a sensible builder could settle it without changing what gets built. Settle it yourself and mark it in the spec as your call (e.g. an `ASM-NNN` row).
- **Theirs:** only the user can answer it and the answer changes what gets built.

Bring the "theirs" pile in one message, most important first. Update the spec with their answers, re-run `spec-quality-gate` if requirements changed, then hand it over with a short list of the calls you made so they can check those while reading. That is the only round of questions the check produces. Without a subagent tool, read the spec as that builder yourself.

**User Review Gate:**
*Senior Dialogue:* inside `/engineer` (the work item has
`dialogue/decisions.json`), the spec is generated from agreed decision cards
and this review is already satisfied by a passing consent `check`; skip the ask
and continue.

After the spec review loop passes, ask the user to review the written spec before proceeding:

> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."

Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once the user approves.

**Implementation:**

- For architectural changes (new services, data models, external integrations, security boundaries): invoke `high-level-design` skill. It produces C4 diagrams, technology selection records, threat model, failure modes, capacity planning, and ADRs before `writing-plans` activates.
- For non-architectural changes (bug fixes, config, isolated utilities): invoke `writing-plans` directly.

## Visual Companion

A browser companion for mockups, diagrams, and visual options. Offer it just-in-time — the first time seeing would help more than reading — **as its own message**: "This might be easier if I show you. Want me to open a browser tab with some mockups?" Decide per question whether browser or terminal fits. Before using it, read `visual-companion.md` (this directory).
