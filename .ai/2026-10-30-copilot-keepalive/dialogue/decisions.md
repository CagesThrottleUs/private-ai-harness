# Decisions — Copilot cache keepalive extension

Work item: `.ai/2026-10-30-copilot-keepalive` · Lane: task · Depth: light

---

## D-000 — Working agreement

**Lane: task.** One new component (a Copilot CLI extension, ~200 lines of JS)
that extends existing harness patterns (host plugin scripts in `scripts/`,
plugin auto-loading). No new service, no data model, not a critical-core
(`fv-eligible` off).

**Depth: light** — every design topic was already argued with evidence
(2026-10-29 → 2026-10-30): cost logs, scheduler and extension spikes, the
background-work probe, the API history trace, live pricing. D-001 records that
design so it can be agreed in the ledger; reopening it card by card would cost
attention without new information.

**Agenda:** D-000 (this) · D-001 design contract (batch). Nothing else is
expected to change the outcome.

**BUILD skill chain (cost-aware: this work item is about cutting cost):**
1. Branch `feat/copilot-keepalive` via **using-git-worktrees**.
2. Write `extensions/private-ai-harness-keepalive/extension.mjs` directly
   (single file; **subagent-driven-development** skipped — dispatching
   implementer + reviewer subagents for one file costs more than it saves).
3. Built-in `--selftest` (pure decision logic, no SDK), following the
   `dialogue-consent.py selftest` precedent. The repo forbids separate test files.
4. **verification-before-completion**: `node --check`, `--selftest`, then live
   acceptance TC1–TC12 in this session via a session-scoped symlink to the
   worktree file; evidence → `.ai/2026-10-30-copilot-keepalive/verification.md`.
5. Doc-sync triple (AGENTS.md, CLAUDE.md, README.md) and minor version bump
   5.0.0 → 5.1.0 in all three manifests.
6. One review: **pr-reviewer** (non-negotiables gate), report to file.
7. **commit-discipline** → **pr-creator** (PR, not direct merge).

**Skipped:** spec-quality-gate and plan-reviewer (the design is in D-001 and
the proposal; ~$8–16 of Opus review for one file), high-level-design (no
architecture weight), SDD subagents (see above), formal-verification (not
eligible).

**Test-scenario cap N = 1:** scenarios TC1–TC12 come straight from the probes
already run; one self-review pass, no reviewer loop.

**Doc targets:** the doc-sync triple plus the extension's header comment. No wiki.

**Spend cap for BUILD: $20.** Basis: main session on Opus at ~200k context costs
~$0.04–0.06 per call × ~100 calls ≈ $5; one pr-reviewer dispatch measured
$4–8; live keepalive tests ≈ $1. Expected ≈ $12; cap leaves headroom.

---

## D-001 — Keepalive design contract (batch)

1. **Trigger:** each main-agent `assistant.usage` (no `agentId`) records
   `cacheExpiresAt`; one keepalive fires at `cacheExpiresAt − 30s` when the main
   agent is between turns. Works during background agents/shells (probe:
   delivered in 262 ms, cache hit). Adapts to any model's TTL. No
   `cacheExpiresAt` → no keepalive.
2. **Stop rule (ski rental):** stop when keepalive spend + next keepalive >
   min(cap, rebuild saved). Rebuild saved = context × (cache-write − cache-read
   price), read live from the last call's `copilotUsage.tokenDetails`. Cap
   default $1, env `PRIVATE_AI_HARNESS_KEEPALIVE_CAP_USD`. Spend resets on a
   human message (`source` empty, not an autopilot continuation). Missing
   price data → no keepalive, logged.
3. **At the stop:** compact (the `/break:long` path), then idle until the next
   human message.
4. **`/break:long`:** compact now; keepalive paused until the next human message.
5. **`/break:off`:** no keepalives for the rest of the session.
6. **Compact safety:** load-time probe that `history.compact` exists; per call
   60s timeout and `success && !aborted && !cancelled && tokensRemoved > 0`;
   CLI version logged. Any failure → timeline warning ("run /compact"), sound,
   nothing sent to the model.
7. **Keepalive prompt:** one prompt for every mode: "reply ok; if a
   task_complete tool is available, call it; call no other tools". Messages sent with
   `source: "agent-keepalive"`.
8. **Kill switch:** env `PRIVATE_AI_HARNESS_KEEPALIVE=off`.
9. **Visibility:** one timeline line per keepalive
   (`keepalive n · $spent · next ~$x · stop at $y`); JSONL log at
   `~/.private-ai-harness/keepalive.jsonl`.
10. **Packaging:** ships in the repo's `extensions/`; the directory-sourced
    plugin loads it live (probe confirmed `[plugin]`). No installer step.
11. **Scope:** Copilot CLI only. Claude Code, Codex and opencode later.

## Outcome (2026-10-30)
The human chose to build directly, without the consent ledger (chat, 2026-10-30
~11:38 IST: "build without ledger"). D-000 and D-001 were therefore not recorded
in the ledger; the design above is what was built. Evidence: `../verification.md`.
