# Verification — Copilot cache keepalive extension

Extension: `extensions/private-ai-harness-keepalive/extension.mjs` · CLI 1.0.105 · model claude-opus-5.5
Log: `~/.private-ai-harness/keepalive.jsonl`

## Static
- `node --check` passes.
- `node extension.mjs --selftest` → 30/30 passed (prices, cost, limit, next-cost, decide incl. mid-turn/quiet/missed/no-price/once-per-expiry, ski-rental 22 sends at 193k, human detection, compact success rules, config precedence and kill switch).

## Live run 1 (2026-10-30 06:14–06:22Z, test config `leadSeconds: 240`, cap $1)
| Check | Evidence | Result |
|---|---|---|
| Loads from the plugin with no install step | `extensions_reload` → `private-ai-harness-keepalive — ready [plugin]` | PASS |
| CLI version and compact API detected | log `joined`: `cliVersion 1.0.105`, `compactApi function` | PASS |
| Fires at expiry − lead, between turns | sends at 06:15:25, 06:16:26 … every ~61s (300s TTL − 240s lead + turn time) | PASS |
| Fires during background work | sends 1–2 while a 170s background shell ran (06:14:20–06:17:10) | PASS |
| Live prices present in `assistant.usage` | `limit` = $1 = min(cap, 274k × (5.00 − 0.20)/M = $1.32), not `no-price` | PASS |
| Spend tracks real billed cost | spent 0 → 0.057 → 0.113 … 0.403 after 8; next uses last actual ($0.057) | PASS |
| Draft and agent unaffected | keepalive turns answered `ok` + task_complete; no autopilot nudge turns | PASS |
| Human message resets spend | user typed at 06:23Z; chain restarted from spent 0 | see run 2 |
| Context growth | ~172 tokens per keepalive (273,831 → 275,188 over 8) | as predicted |

Projected stop: 17 keepalives ($0.97) at 274k context; normal pace (~4.5 min) ≈ 77 min.

## Live run 2 (2026-10-30 06:25–06:28Z, test config `capUsd: 0.1`, `leadSeconds: 240`)
| Check | Evidence | Result |
|---|---|---|
| Human message resets spend | after the user's "complete your tests" message: `send` n=1 with `spent 0` | PASS |
| Ski-rental stop | 06:26:35 `stop`: spent $0.0578 + next $0.0578 > limit $0.10 | PASS |
| Compacts at the stop, between turns | 06:27:34 `compacted`, reason `keepalive limit`, 132,965 tokens / 238 messages removed | PASS |
| No re-arm after compaction | no `send` after `compacted` until the next human message | PASS |

## `/break:off` persistence
| Check | Evidence | Result |
|---|---|---|
| Off marker survives reload | created `~/.private-ai-harness/keepalive-off/<sessionId>`, `extensions_reload` → `joined off:true` | PASS |
| Removing it re-enables | marker removed, reload → `joined off:false` | PASS |
| Test config removed, defaults back | `joined capUsd 1, leadSeconds 30` | PASS |

## Not verified live
- Typing `/break:long` and `/break:off` (only the user can type slash commands); the handlers share the code paths verified above (compaction, off marker).
- Compaction failure path (warning + beep): covered by the selftest's success rules only.
- Non-autopilot sessions.
