# Spike: Why do subagents cost so much on GitHub Copilot, and how do we fold reviewers into Senior Dialogue cheaply?
**Date:** 2026-10-29
**Time spent:** ~1.5h
**Decision:** Re-architect *where* reviewer power is applied (card-scoped critique during DISCUSS, evidence-packed gates during BUILD) and shrink the human-facing dialogue context. Do not reduce reviewer rigor.
**Confidence:** medium — spend data is measured; savings figures are estimates from that data, not yet re-measured after a change.

## Evidence base (all re-runnable)

Source: `~/.copilot/session-state/*/events.jsonl`, `session.usage_record` events
(fields `initiator`, `parentToolCallId`, `copilotUsage.tokenDetails[].costPerBatch`),
191 sessions, 2026-10-12 → 2026-10-29. 1 AI credit = $0.01
([GitHub billing](https://docs.github.com/en/copilot/concepts/billing-and-usage/individuals/billing)).

| Measure | Value |
|---|---|
| Main-session spend | **$1,251** (6,249 model calls) |
| Subagent spend | **$250** (17% of total) |
| Top 3 sessions | $1,091 of main spend |
| Avg main-session context per call (Opus 5.5) | **~400k tokens** |
| Main cache writes vs cache reads | **$657 vs $384** (writes > reads) |
| Cache rebuilds after >300s idle | **288 events, $589** (≈47% of main spend) |
| Rebuilds caused by compaction / model switch | $5 / $9 (negligible) |
| Opus 5.5 rates on Copilot (from logs) | input $4, cache read $0.20, cache write $5.00, output $20 per M |
| Cache TTL logged | 300s (8,385 records), 1800s (1,299) |
| Tool schemas per main request | 156 tools = 25,991 tokens (`promptCacheBreakState.tool_tokens`) |

Per-dispatch subagent cost (Copilot):

| Agent | n | $/dispatch | model calls | ctx tokens | first-call ctx | model |
|---|---|---|---|---|---|---|
| general-purpose | 27 | 8.09 | 68.6 | 17.9M | 107k | opus-5.5 (inherited) |
| code-review (built-in) | 2 | 4.61 | 61.0 | 10.1M | 64k | opus-5.5 |
| private-ai-harness-test-quality-reviewer | 4 | 3.97 | 41.2 | 8.3M | 69k | opus-5.5 (inherited) |
| explore (built-in) | 1 | 0.02 | 4.0 | 0.09M | 6k | gpt-5.6-luna |

## Why subagents (and the dialogue) cost what they cost — mechanics

1. **Every model call re-sends the whole context.** A subagent that makes 41–69 tool
   calls re-sends a growing context 41–69 times; cost scales with
   `calls × average context`, so it grows roughly quadratically with turns. This is
   the dominant subagent cost, not the prompt length. Anthropic measured agents at
   ~4× and multi-agent systems at ~15× chat tokens
   ([Anthropic, multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)).
2. **Each subagent starts a fresh cache.** First call writes 64–107k tokens at the
   cache-write rate (25× the read rate on Opus 5.5) before reading a single file.
   Copilot: subagents "run in their own session and don't inherit the main agent's
   conversation history" ([GitHub, optimize AI usage](https://docs.github.com/en/copilot/tutorials/optimize-ai-usage)).
3. **The Copilot adapter drops model tiering.** `scripts/install-copilot-agents.py`
   emits no `model:` and no `tools:`; Copilot then "inherits the default model" and
   "defaults to all tools" ([custom agents config](https://docs.github.com/en/copilot/reference/custom-agents-configuration)).
   Result: every reviewer — including the 11 Sonnet-tier mechanical ones — ran on
   Opus 5.5 with all 156 tools (incl. Jira, wiki, Adobe Analytics MCP servers).
4. **The real money is the human pause, not the subagent.** Copilot's prompt cache
   expires after 300s. Each time the human thinks >5 minutes between turns, the next
   call rewrites the full ~400k context at $5/M ≈ **$2.00**. Senior Dialogue's
   DISCUSS phase is, by design, a sequence of human pauses — on the current
   architecture every agreed card can cost ~$2 just to resume.
5. **Context bloat in this repo.** `AGENTS.md` (56 KB) is loaded directly *and* via
   `CLAUDE.md`'s `@AGENTS.md` import (visible twice in this session's instructions),
   plus ~195 custom-agent descriptions (~9k tokens) and 26k tokens of tool schemas,
   on every main call and every subagent's first call.

## Validation of the claims in the request

### "The reviewer subagents are very powerful" — partially validated
Strong: explicit input contracts, severity scales, standards-backed dimensions,
`REPORT_FILE` to keep findings out of main context, model right-sizing rationale.
Gaps versus external practice:

| Gap | Evidence | External reference |
|---|---|---|
| No eval set — reviewer precision/recall and $/true-finding are unmeasured, so "powerful" is asserted, not shown | no `evals/`; `grep confidence\|false.positive agents/` → 0 hits | Anthropic multi-agent post: evaluate early with small samples |
| No confidence score or false-positive filter stage | same grep | [claude-code-security-review](https://github.com/anthropics/claude-code-security-review) ships a dedicated FP-filter stage |
| No turn budget; reviewers average 41–75 calls | Copilot logs above | Copilot doc: "a clear stopping condition" cuts runs |
| Only `pr-reviewer`/`spec-impl-reviewer` accept a pre-built `DIFF_FILE`; the rest re-explore | `grep DIFF_FILE agents/` | Copilot doc: "Relevant context provided upfront" |
| Copilot adapter loses `model` tier and tool scoping | generated `.agent.md` frontmatter has only name/description | Copilot doc: "Use cheaper models for subagents"; "Bring in only the tools you need" |
| Mechanical (Sonnet-tier) reviewers are still LLM loops though their checks are regex/file-presence | AGENTS.md right-sizing table | Copilot Fusion only adds model calls "when a task warrants them" |

### "Senior Dialogue is part of how the harness behaves" — designed yes, enforced **no** on this machine
- Designed: `skills/engineer/SKILL.md` routes every lane through `senior-dialogue`;
  `dialogue-consent.py selftest` → PASS (19 checks).
- Not enforced on Copilot: `~/.copilot/hooks/private-ai-harness.json` contains only
  sound hooks — no `userPromptSubmitted`/`postToolUse`/`preToolUse` consent hooks.
  `install-copilot.sh` (lines 283–305) would add them but has not been re-run since
  the senior-dialogue commit (`085aed4`, today).
- Not enforced on Claude Code: plugin cache holds 4.0.2; repo is 5.0.0.
- Cost observability is blind on Copilot: `engineer-cost-ledger.jsonl` has 14 rows,
  all with empty `tokens_by_model`; `cost-checkpoint` reads only Claude/Codex
  transcripts. The spend circuit breaker therefore never fires on Copilot, even
  though Copilot logs exact per-call USD with sub-agent attribution.

## Options evaluated

### Option A: Cut reviewer usage
Fits because: fewer dispatches = less spend. Risk: loses the power the user values;
attacks 17% of spend. **Rejected.**

### Option B: Cheaper reviewer dispatch (model + tools + evidence pack + turn budget)
Fits because: directly addresses mechanics 1–3. Risk: a cheaper model misses
judgment findings — must be checked against an eval set, not assumed.
Evidence: Copilot's own `explore` ran on GPT-5.6 Luna for $0.02 vs $3.97–$8.09 for
Opus-inherited agents.

### Option C: Thin dialogue context + reviewers as card-scoped sparring partners (recommended, includes B)
Fits because: attacks the 47% (cache rebuilds on human pauses) and turns reviewer
power into *learning*, which is Senior Dialogue's goal. Copilot Fusion's "Critique"
pattern — draft, then several models critique in parallel, each receiving "only the
context they need" ([Copilot Fusion](https://docs.github.com/en/copilot/concepts/models/copilot-fusion)) —
is the same shape, validated by GitHub.
Risk: more files to keep in sync; critique quality on small context is unproven.

## Recommendation

Adopt C in this order (each is a separate decision card for discussion):

1. **D-001 Re-run installers / fix enforcement.** Copilot consent hooks + Claude
   plugin 5.0.0. Zero design risk; the dialogue is currently advisory-only.
2. **D-002 Copilot cost reader in `cost-checkpoint`.** Read `session.usage_record`,
   attribute by `parentToolCallId`, record USD (Copilot provides it exactly).
   Prerequisite for measuring every change below.
3. **D-003 Thin dialogue session.** State lives in `dialogue/decisions.md` and the
   ledger already; make "one agenda topic per session" (or `/compact` at each agreed
   card) the default rhythm, and push evidence gathering into subagents that return
   ≤1-page summaries. Estimate (labeled assumption: same 288 human pauses, context
   held at ~100k instead of ~400k): rebuild cost $2.00 → $0.50 each, ≈$430 of the
   $589 avoided.
4. **D-004 Card critique ("second senior").** Before presenting a card, dispatch
   one or two reviewers with *only* the card + its evidence pack, read-only tools,
   a hard stop ("≤3 objections, one falsifier, one question for the human, no
   exploration"). Present their objections on the card as questions to the human
   (teacher-style), so the human meets the angle they had not considered. Spend
   this where rework is cheapest — before code — instead of only after.
5. **D-005 Evidence-packed BUILD gates.** Generalise `DIFF_FILE` to every reviewer
   (one pre-built review package, read once), add a turn budget, a confidence score
   per finding, and an FP-filter pass before findings reach the human.
6. **D-006 Copilot adapter tiering.** Emit `tools:` allow-lists and a `model:` per
   tier in `install-copilot-agents.py` (which Copilot model maps to "opus"/"sonnet"
   is the human's call — e.g. Sonnet 5.5 or GPT-6.1 Sol at half Opus 5.5 rates per
   the Copilot pricing table). Convert purely mechanical reviewers to scripts.
7. **D-007 Reviewer eval set.** Seeded-defect fixtures per high-use reviewer
   (pr, test-quality, spec-quality, plan); measure recall, precision, $/true finding
   per model before switching any reviewer's tier.
8. **D-008 Context diet.** Stop the double load of `AGENTS.md`, move the large
   right-sizing tables out of always-loaded instructions, prune unused custom agents.

## Open questions
- ~~Whether Copilot exposes a longer cache TTL for Anthropic models~~ Resolved:
  `modelCacheState` shows Claude models (opus-5.5, sonnet-5/5.5) at 300s and GPT
  models (gpt-5.6-*, gpt-6-sol, gpt-6.1-sol) at 1800s. No Copilot CLI 1.0.105
  setting changes it (`copilot help config|environment` has no cache/TTL key).
  Corroboration: main-session gpt-6-sol (481 calls, ~388k ctx) spent $13 on cache
  writes vs $68 on reads; opus-5.5 spent $657 writes vs $384 reads. Caveat: GPT-6.x
  Sol pricing doubles above 272k input tokens (long-context tier), so context must
  stay under 272k for the cheaper rate. Claude Code alone offers a 1h TTL
  (`promptCacheTtl: "1h"`, [docs](https://code.claude.com/docs/en/prompt-caching#cache-lifetime)).
- Whether card-sized critique retains judgment quality — D-007 answers it.
- Main-session spend concentrates in 3 sessions; their topics were not inspected.

## Addendum: `/break:*` cache-keepalive idea (2026-10-29)

Evidence:
- Copilot CLI has experimental `/every INTERVAL PROMPT` and `/after DELAY PROMPT`
  ([CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference));
  the model-side tool is `manage_schedule`. Tested live: interval `285s` accepted →
  "every 4m 45s"; event `session.schedule_created {"intervalMs":285000,"origin":"model"}`;
  stop works by id. No count/duration limit is documented.
- Plugin `commands/` directory yields namespaced commands (`copilot-hud` ships
  `commands/setup.md` → `/copilot-hud:setup`), so a `break` plugin gives `/break:short`.
- No documented way for hooks or an external process to inject a prompt into a live
  interactive session; the SDK targets `--headless` servers. Not needed: the
  built-in scheduler sends the tick in-session.
- Economics: a tick costs ≈ context × cache-read rate; a rebuild ≈ context ×
  cache-write rate. Write/read = 25 on Opus 5.5 ($5/$0.20), Sonnet 5.5 and GPT-6.1
  Sol ($2.50/$0.10). Keepalive beats one rebuild for any break < 25 ticks × 4m45s
  ≈ 119 min, at any context size. Compaction pays only beyond that, and loses detail.

Untested (must pass before building): a tick preserves a half-typed draft; ticks
queue while an `ask_user` form is open; in autopilot a tick does not trigger work or
the autopilot completion-review subagent (≈$0.09 each in these logs).

Live test results (schedule #2, every 30s, deadline 09:27:30, ~273k context, Opus 5.5):
- Draft preserved while ticks fired (user typed ~15 lines across 3 ticks).
- Tick cost $0.057–0.059 (cache read ≈ whole context, cache write 200–900 tokens)
  vs ≈$1.37 to rebuild 273k at $5/M.
- Autopilot: a tick answered without `task_complete` drew an autopilot "not complete"
  nudge = a second paid turn. Ticks must end with `task_complete`. No
  completion-review subagent fired.
- Ticks fired every 30–35s; the timer appears to restart after each turn ends.
- Deadline worked: first tick at/after 09:27:30 (09:27:34) cancelled the schedule.
  One tick arrived without `<current_datetime>`, so the deadline needed a `date` call.
- In autopilot, `ask_user` returns "user not available" immediately — it never
  blocks, so the ask_user test is moot in autopilot.
- Hooks cannot do auto-back: `userPromptSubmitted` input is
  `sessionId, timestamp, cwd, prompt` (no initiator); `modifiedPrompt` is SDK-only.
  No external schedule API. But SDK extensions (`joinSession` from
  `@github/copilot-sdk/extension`, loaded from `~/.copilot/extensions/`) can
  `session.on(...)` events and `session.sendAndWait({prompt})` — an extension can own
  the keepalive timer and stop it on the next human message, deterministically.

Extension spike results (session-scoped `break-test`, copilot-sdk 1.0.105 local types):
- APIs present in 1.0.105 (upstream web docs lacked some): `joinSession({commands})`,
  `session.send({prompt, source})` with `MessageSource = "user"|"system"|"agent-${id}"`,
  `user.message.data.source|delivery|isAutopilotContinuation`, experimental
  `session.rpc.history.compact({customInstructions, trigger})` (typeof → function).
- `/break:test` (colon in command name) registered and ran.
- Keepalives logged `source:"agent-break", delivery:"idle"`; the human message logged
  `source:null` → extension stopped the break within 1 ms ("human prompt detected").
- Draft preserved while extension keepalives fired (user report).
- Keepalive cost $0.064–0.069 at ~310k context, one call each (ended with
  `task_complete`), cache write 154–1,174 tokens.
- Not yet exercised: running `rpc.history.compact` at the deadline; behavior after
  `/clear` (extensions reload) or with multiple concurrent sessions.

Automatic-keepalive simulation (Opus 5.5 main sessions, 5,175 inter-call gaps, 17
sessions, all with `session.shutdown`; tick every 270s at ctx×$0.20/M + 57 output
tokens; rebuild ctx×$5/M; compaction ignored):
none $659 · cap 15m $289 · 30m $219 · 45m $217 · **60m $202** · 90m $206 · 120m $206 ·
180m $228. Tail cost after the last call before shutdown ≤ $6 at any cap.
Loading scope: `~/.copilot/extensions/<name>/extension.mjs` loads into every CLI
process (copilot-hud loads as `[user]`); one instance per CLI process, attached to its
foreground session; reloaded on `/clear`; running sessions pick up a new extension
only after restart or `extensions_reload`. `settings.json` has `experimental: true`
(set by copilot-hud); whether extensions require it is not documented.

Session archive evidence (Copilot CLI 1.0.105):
- No archive or hide feature. Supported removal: `/session delete [ID]`,
  `delete-all`, `cleanup`, `prune` (semantics of cleanup/prune undocumented); session
  picker `x` and sidebar close both permanently delete stored history.
- SDK server RPC has `sessions.close`, `sessions.bulkDelete`, `sessions.pruneOld`,
  `sessions.getSizes`, `sessions.checkInUse` — no archive/tag/hidden field.
  Whether an extension's session-scoped `rpc` can reach these server calls: untested.
- Picker sorts by relevance to the current directory (default) and filters
  all/local/remote — no "this folder only" filter, and the UI is not extensible.
- Sessions are indexed in `~/.copilot/data.db` (+ `open-sessions-state.json`,
  `sidebar-sessions-state/`); moving `session-state/<id>` by hand risks desyncing it.
- `~/.copilot/session-state` is 53 GB across 191 sessions.

## If this becomes a task
`/engineer` epic lane starting at D-001/D-002 (instrumentation first), then D-003/D-004
as one task with `test-scenario-reviewer`, measured against the D-002 ledger.
