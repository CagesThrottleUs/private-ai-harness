# Cost Checkpoints, Circuit Breaker, and Ledger

Moved verbatim from `SKILL.md` (private-ai-harness 5.0.0) to keep the skill
under the 20,000-byte limit Claude Code applies when it re-attaches skills
after compaction. Read it at the step that points here.

## Checkpoint protocol (every lane)

- **Cost checkpoints:** before each numbered step in the lane, run
  `scripts/cost-checkpoint start <step-slug>` (from this skill's directory,
  e.g. `skills/engineer/scripts/cost-checkpoint`). Immediately after the step
  finishes — success, BLOCKED, or FAIL — run `scripts/cost-checkpoint end
  <step-slug> --row phase --lane <lane> --phase <phase> --skill <skill>`.
  For task/epic lanes, `--phase` is the manifest's current `phase:` value at
  that moment, read from `.ai/<id>/manifest.md` — the source of truth.
  For lanes with no manifest (quick-fix, research, refactoring), use the
  lane name as `--phase`. This appends one row to a global, cross-repo
  ledger — tokens only, no dollar figure, since pricing drifts and token
  counts don't. See "Cost ledger" below for the row schema and location.
- **Spend circuit breaker (enforcement, not just monitoring):** the ledger
  *records* what was spent; a runaway agentic loop needs a ceiling that
  *stops* spend before it happens. When the user (or a repo/session policy)
  sets a per-session token cap, run `scripts/cost-checkpoint budget --cap N`
  before each step. On `status: breach` (exit 3), **halt exactly like BLOCKED**
  — do not dispatch the next step; surface the ledger's per-phase breakdown and
  the cap to the human and wait. On `warning` (≥80% of cap — the FinOps
  budget-alert convention), tell the user the run is approaching its ceiling so
  they can decide to continue, raise the cap, or narrow scope. No cap set = no
  gate (opt-in), but always report `warning`/`breach` if a cap is present.
- **Per-subagent cost attribution (required at every dispatch):** bracket every
  named-subagent dispatch — reviewers inside a gate, workers inside SDD, the
  `/review all` agents — with `cost-checkpoint start <agent-slug>` … `end
  <agent-slug> --row agent --lane <lane> --agent NAME --role ROLE --model MODEL
  [--dispatch-mode parallel_batch]`. Without this, cost is attributed only to the
  coarse phase and the single most expensive dispatch (usually a reviewer) hides
  inside it. Attribution is what makes the circuit breaker and the delivery
  ledger honest about where tokens actually go.

## Cost ledger

`scripts/cost-checkpoint` gives per-step token observability so a run's cost
is visible phase-by-phase, not just as a surprise total at the end.

**Location:** `~/.claude/private-ai-harness/engineer-cost-ledger.jsonl` on
Claude Code, or `$CODEX_HOME/private-ai-harness/engineer-cost-ledger.jsonl`
(normally `~/.codex/...`) on Codex. Each is outside any repo, shared across
every project on that host, and append-only with one JSON line per checkpoint.

**Row schema (phase rows — the only row type wired in this skill):**
```json
{"row": "phase", "session_id": "...", "repo": "owner/name", "timestamp": "...",
 "lane": "task", "phase": "construct", "skill": "subagent-driven-development",
 "tokens_by_model": {"<host-model>": {"input": 0, "output": 0, "cache_read": 0, "cache_creation": 0}}}
```

**Currency is tokens, not dollars.** Per-token pricing changes over time and
isn't reliably available to a running skill; token counts don't drift. If you
want a dollar figure, convert later yourself with whatever pricing you look
up at that time — the ledger deliberately does not store or estimate cost.

**Querying:**
- Everything for one run: filter by `session_id`.
- Most expensive phase across history: group by `phase`, sum `tokens_by_model`.
- Cross-repo total: the file already spans every repo — no aggregation step needed.
- One repo only: filter by `repo`.

**Enforcement:** `cost-checkpoint budget --cap N` reads cumulative session
tokens and returns `{"status": "ok|warning|breach", "used", "cap", "ratio"}`,
exiting 3 on breach so a caller can gate on `$?`. This is the circuit breaker —
the difference between *reading* spend after the fact and *stopping* it before a
runaway loop blows the ceiling. `warning` fires at 80% of cap (the conventional
FinOps/cloud-budget alert point); the cap itself is caller-supplied — there is no
baked-in magic number, since a reasonable ceiling depends on the work.

**Attribution:** `agent` rows (`--row agent --agent NAME --role ROLE --model
MODEL`) attribute cost to each named-subagent dispatch, not just the coarse
phase. The Universal-constraints "per-subagent cost attribution" bullet makes
these required at every dispatch site — a `phase` row alone hides which reviewer
or worker actually spent the tokens, and both the circuit breaker and
delivery-metrics are only as honest as that attribution.
