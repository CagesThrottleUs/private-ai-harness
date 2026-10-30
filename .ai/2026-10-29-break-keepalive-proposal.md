# Proposal: automatic prompt-cache keepalive + `/break:long` + `/break:off` (Copilot CLI)

Status: PROPOSED — not agreed, nothing built. Evidence: `.ai/2026-10-29-copilot-subagent-cost-findings.md`.

## Goal
Stop paying ~$1.4–2.0 per cache rebuild when the human pauses >5 min, without the
human doing anything. Simulated on Oct 12–29 Opus main-session data: $659 → ~$206.

## Mechanism (all verified on Copilot CLI 1.0.105 in the `break-test` spike)
One Copilot **extension** (`extension.mjs`, loaded from `~/.copilot/extensions/`
into every CLI process, attached to that process's foreground session):

| Need | API |
|---|---|
| know when the agent is idle | `session.on("session.idle")`, `assistant.turn_start` |
| send keepalive, tagged | `session.send({ prompt, source: "agent-break" })` |
| tell human from keepalive | `user.message.data.source` (`"agent-break"` vs `null`) |
| commands | `joinSession({ commands: [{ name: "break:long" }, { name: "break:off" }] })` |
| compact | `session.rpc.history.compact({ customInstructions })` (experimental) |
| visible status | `session.log(...)` |

## Behavior (state machine)

```
            human message / agent turn
 ┌─────────► ACTIVE ──────────────┐
 │             │ session.idle     │
 │             ▼                  │
 │          IDLE-WATCH ── 270s idle ──► send keepalive (stays IDLE-WATCH, episode clock keeps running)
 │             │ episode age ≥ 2h │
 │             ▼                  │
 │          EXPIRED (no sends) ───┘ next human message → ACTIVE (new episode)
 │
 /break:long → compact now → EXPIRED          /break:off → OFF for this session (until /clear or restart)
```

- **Interval:** 270s after the last model call ends (TTL 300s minus 30s margin).
  Adapts to the session's cache TTL when the CLI reports it (`cacheTtlSeconds`:
  1800 for GPT models → ~1770s), else 270s.
- **Episode cap:** 2 hours from the first idle after a human message (≤ 26
  keepalives). Human-chosen; sim says 60m ≈ $202, 2h ≈ $206.
- **Never sends** while the agent is busy (mid-turn, permission prompt pending).
- **Keepalive prompt** depends on `agentMode`: autopilot → "reply ok, call
  `task_complete`, no other tools" (without `task_complete` autopilot nudges a second
  paid turn — measured); interactive → "reply ok, no tools".
- **Kill switch:** env `PRIVATE_AI_HARNESS_KEEPALIVE=off` disables the extension.
- **Evidence log:** one JSONL line per keepalive/episode in
  `~/.copilot/private-ai-harness/keepalive.jsonl` (feeds the D-002 cost reader).

## Harness integration (no build step)
- `scripts/copilot-keepalive-extension.mjs` — source (sits beside
  `scripts/opencode-notify-plugin.js`, the existing host-plugin precedent).
- `scripts/install-copilot.sh` — new idempotent step: symlink it to
  `~/.copilot/extensions/private-ai-harness-keepalive/extension.mjs` (live from the
  checkout like the rest of the harness). Running sessions pick it up after restart.
- Doc-sync triple (`AGENTS.md`, `CLAUDE.md`, `README.md`) + minor version bump in all
  three manifests.
- Claude Code later: not this extension — set `promptCacheTtl: "1h"`.

## Acceptance scenarios (evidence = extension log + `session.usage_record`)
| TC | Scenario | Pass |
|---|---|---|
| 1 | idle 270s | exactly one keepalive; ≥95% of its input from cache |
| 2 | typing a draft while keepalives fire | draft intact (passed in spike) |
| 3 | human message | no keepalive while agent busy; episode resets |
| 4 | episode reaches cap (test env shortens cap) | sends stop; log `expired` |
| 5 | `/break:long` | compaction completes, keepalive stops; next human message re-arms |
| 6 | `/break:off` | no keepalives for the rest of the session; `/clear` re-enables |
| 7 | autopilot | one model call per keepalive (no nudge turn) |
| 8 | GPT model (TTL 1800s) | interval ≈ 1770s or no keepalive |
| 9 | consent hooks | keepalive messages never recorded as agreement |
| 10 | two terminals | each keeps only its own session alive |

## Decisions still open (for D-000)
1. **Compact at the 2h cap?** Recommendation: no — stop quietly; you compact
   deliberately with `/break:long` ("see you tomorrow"). Auto-compact is wasted on
   sessions you never return to and loses detail.
2. **`/break:off` scope:** rest of this session (recommended) vs until your next message.
3. **TTL adaptation for GPT models** (TC 8): adapt (recommended) vs Claude-only.
4. **Delivery:** symlink from the checkout (recommended, live updates) vs copy.

## Known limits
- Only the **foreground** session of each CLI process is kept alive (extensions attach
  to it); background sessions in the same process are not.
- `rpc.history.compact` is marked experimental.
- Each keepalive adds ~150 tokens to the conversation (~4k over a full 2h episode).

## Addendum (2026-10-30): idle semantics, compact API history, Opus 5.5 cost

### How `session.idle` is determined (copilot-sdk 1.0.105)
- `generated/session-events.d.ts:2041` — "session is idle with no background agents or attached shell commands in flight"; payload `{ aborted?, mode? }`; `ephemeral: true` (NOT written to `events.jsonl` — our own JSONL is the only record).
- `generated/rpc.d.ts:23337-23414` — native queue defers idle: `FinishDeferredIdleDrain.action ∈ {none, processQueue, emitSessionIdle}`; queued messages run before idle is emitted.
- Gap: a long background agent/shell suppresses idle → main-session cache may expire with no keepalive. Proposed TC: log every event type across normal end, background shell, background agent, Esc-abort, autopilot nudge turn, after `/clear`.

### `history.compact` history (github/copilot-sdk, `nodejs/src/generated/rpc.ts`, `git log -G compact`)
| Date | Commit | Change | Breaking? |
|---|---|---|---|
| 2026-02-25 | 9d998fb8 | added as `session.compaction.compact`, no params | — |
| 2026-04-07 | 9351e26a | namespace renamed → `session.history.compact` | **yes** |
| 2026-04-14 | 68f46b34 | result type renamed, `contextWindow` added | additive (TS name only) |
| 2026-05-21 | 8ba75ec3 | optional params; `aborted`, `cancelled`, `summaryContent` | additive |
| 2026-08-19 | 1593e223 | `trigger` attribution param | additive |
| 2026-08-19 → 2026-10-26 | — | unchanged (local 1.0.101–1.0.105 identical) | — |

One breaking rename in 8 months; otherwise additive. Still listed as experimental in `docs/troubleshooting/compatibility.md`.

### Breakage detection → tell the user to `/compact`
1. Load-time probe: `typeof session.rpc?.history?.compact === "function"`.
2. Call-time: 60s timeout; require `success === true && !aborted && !cancelled && tokensRemoved > 0`.
3. Record CLI version on each success; first run on an unseen version is logged as unverified.
4. Any failure → `session.log(..., {level:"warning"})` + sound; send nothing to the model.

### Opus 5.5 cost (Copilot, per 1M: input $4, cache read $0.20, cache write $5, output $20 — from `costPerBatch` in session logs)
Per tick ≈ context × $0.20/M + ~$0.004 (measured $0.064–0.069 at ~310k). Full 2h = 26 ticks.
| Context | Per tick | 2h episode | Rebuild avoided |
|---|---|---|---|
| 100k | $0.024 | $0.62 | $0.48 |
| 300k | $0.064 | $1.66 | $1.44 |
| 400k | $0.084 | $2.18 | $1.92 |
The "~4k" above is tokens of context growth, not dollars (<$0.01 per later call). Replay of 17 real sessions: $659 → $206 with the 2h cap.

## Addendum (2026-10-30 11:16 IST): background-work probe, TTL source, packaging, decisions

### Evidence
- **Background work blocks `session.idle`** (probe log `/tmp/bgprobe.jsonl`): with a 120s background shell running, no `session.idle` fired between the last turn end (05:45:35Z) and the probe.
- **Cost of that gap (all local sessions):** 35 of 302 Claude rebuilds after a >5 min gap ($77 of $613) were the main session waking on a background-completion `system.notification`.
- **An extension message during background work is delivered immediately:** probe sent 05:45:55.288Z → `user.message {source:"agent-probe", delivery:"idle"}` 262 ms later → turn started; the shell was still running. That call read 193,218 tokens from cache and wrote 166.
- **TTL is exposed per call:** `assistant.usage.cacheExpiresAt` (ephemeral; `session-events.d.ts` AssistantUsageData) = call start + TTL (observed exactly +300s for claude-opus-5.5). Subagent usage carries `agentId`; main agent does not. `rpc.usage.getMetrics().modelMetrics[m].cacheExpiresAt` is a polling alternative.
- **Plugins ship extensions with no manifest change:** a probe at `<repo>/extensions/plugin-probe/extension.mjs` loaded as `[plugin]` from the live directory marketplace (`extraKnownMarketplaces.private-ai-harness.source = directory`). Symlinked session extensions also load (resolved path). Deleted extensions show `failed` until next discovery (harmless).

### Design changes (supersede the idle-triggered timer above)
- **Trigger:** on each main-agent `assistant.usage` (no `agentId`) record `cacheExpiresAt`; fire one keepalive at `cacheExpiresAt − 30s` when the main agent is between turns (last `assistant.turn_end` after last `assistant.turn_start`). Works during background agents/shells; adapts to Claude 300s and GPT 1800s with no model table. No `cacheExpiresAt` → no keepalive, log it.
- **2h cap:** run the `/break:long` path (compact via `history.compact`, verified per the breakage checks; on failure warn to `/compact` manually), then stop.
- **`/break:off`:** disables keepalive for the rest of the session.
- **Packaging:** `extensions/private-ai-harness-keepalive/extension.mjs` in the repo. The directory-sourced plugin loads it live — no installer step, no symlink, no copy. Edits apply on `extensions_reload` or next session.
- **Commands:** `/break:long` and `/break:off` only, typed by the human.
