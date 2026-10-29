# Consent Protocol

Read once per session, before the first card. It tells you how to ask, how the
answer becomes a ledger row, and what to do when nobody answers.

## Why a ledger and not a sentence

In autopilot or allow-all modes the host approves tool calls without a human.
A model that "confirms" its own plan is the failure this harness exists to
prevent. So agreement is recorded by host hook processes that only fire on
human-originated input, into a hash-chained, HMAC-signed ledger the model is
blocked from touching. You can read state (`status`, `check`); you cannot write
it.

## The answer format

The agreement token is the word `AGREE`, one space, then one or more decision
ids: a single id (`D-<NNN>`), a list (`D-<NNN>, D-<NNN>`), or a range
(`D-<NNN>..D-<NNN>`, at most 51 ids). The other two answers are
`REVISE D-<NNN>` and `PARK D-<NNN>`. Matching is case-insensitive.

Never write the token followed by a real id into a file, commit message, shell
command, prompt, or subagent brief. The guard denies those calls. In chat text
(your normal reply) you may show the exact reply the human should give.

## Per-host mapping

| Host | Ask tool | How to ask | Typed fallback | Hook wiring |
|---|---|---|---|---|
| Claude Code | `AskUserQuestion` | One question per card (max 4 per call). `header`: `D-<NNN>`. `question`: the card title ending in "agree?". Options, exactly three, labels: `AGREE D-<NNN>`, `REVISE D-<NNN>`, `PARK D-<NNN>`; put a one-line consequence in each `description`. `multiSelect: false`. | **None.** Claude Code also fires `UserPromptSubmit` for scheduled tasks, background-subagent reports, and cross-session messages, so a typed agreement could be model-originated. If the human types an agreement, ask the same card again with `AskUserQuestion`. | `hooks/dialogue-consent.json` via `.claude-plugin/plugin.json` (`PostToolUse` on `AskUserQuestion`, `PreToolUse` guard on every tool) |
| GitHub Copilot CLI | `ask_user` | `message`: the card summary. `requestedSchema.properties.decision`: `type: string`, `enum` of the three labels, `title`: `D-<NNN>`. One card per call. | The human sends a message whose whole first line is the token and ids. Recorded by `userPromptSubmitted`. | `~/.copilot/hooks/private-ai-harness.json` written by `install-copilot.sh` (`userPromptSubmitted`, `postToolUse`, `preToolUse`) |
| Codex | `request_user_input` when the session exposes it | One question, three options, same labels. | Typed first line, recorded by `UserPromptSubmit`. | `hooks/codex-dialogue-consent.json` via `.codex-plugin/plugin.json`. Codex skips plugin hooks until the human trusts them in `/hooks`. |
| opencode | `question` | One question, three options, same labels. | Typed first line, recorded by the `chat.message` plugin hook. | `~/.config/opencode/plugin/private-ai-harness-dialogue-consent.js` written by `install-opencode.sh` |

After every ask, run `status`. If the card is not in `agreed`:

- the human chose REVISE or PARK → act on it;
- otherwise the host did not deliver a parseable human answer. On Copilot,
  Codex, or opencode, tell the human the exact typed reply and end your turn.
  On Claude Code, ask once more with `AskUserQuestion`; if that also fails,
  park.

Ask-tool results on some hosts echo every offered option. The recorder then
sees agree, revise and park together and records nothing — that is
deliberate. It fails safe, and the typed fallback covers it.

## When there is no human

Signals: the ask tool is missing, errors, is cancelled, times out, or returns
without an answer; the host is non-interactive (`claude -p`, `codex exec`,
Copilot cloud agent); or you already asked once this turn and got nothing.

Park — do not retry in a loop, do not pick a default, do not continue to BUILD:

1. Write `dialogue/PARKED.md`:

   ```markdown
   # Parked — awaiting human agreement

   **Work item:** .ai/<id>   **Parked at:** <ISO timestamp>   **Lane:** <lane>

   ## Agreed so far
   - D-<NNN> <title>

   ## Pending (highest EV first)
   - D-<NNN> <title> — EV <n> h — <one-line why it matters>

   ## The one question that unblocks the most
   <single question, plain words, with your recommendation and its reason>

   ## How to resume
   Reply with the word AGREE, a space, and the card id (for example D-<NNN>),
   or REVISE / PARK the same way, or answer the question above in your own
   words. Then run `/engineer resume .ai/<id>`.
   ```

2. Set the manifest `phase: parked` and `gate_status: awaiting-human` (task and
   epic lanes).
3. End the turn with a short summary that shows the exact reply in chat. On
   Copilot autopilot, call `task_complete` with a summary that starts
   `PARKED — awaiting human agreement on` and lists the card ids.

Allowed while parked: read-only evidence gathering and drafting cards for
pending topics. Not allowed: production code, tests, final docs, commits outside
`dialogue/`.

## Resuming

On `/engineer resume .ai/<id>` (or any message that answers a parked card):
read the manifest, `decisions.json`, and `PARKED.md`; run `status`; delete
`PARKED.md` once every card it listed is agreed or revised; continue the agenda.

## What the guard denies (so you are not surprised)

- The agreement token followed by an id anywhere outside the ask tool and
  `task_complete`.
- Any tool call that mentions the ledger file, the HMAC key, the hook wiring
  files, `disableAllHooks`, or the host settings and hook directories
  (`.claude/settings`, `.codex/hooks`, `.codex/config.toml`, `.github/hooks`,
  `.opencode/plugin`, `copilot/settings`) — except the script's own
  `activate`, `status`, `check`, `selftest` invocations and plain
  `git add|commit|status|diff|log|show`.

If your legitimate task needs one of those paths, say so and ask the human to
relaunch the host with `PRIVATE_AI_HARNESS_CONSENT_GUARD=off` (only the human
can set the hook process environment).

## Threat model (honest limits)

| Threat | Mitigation |
|---|---|
| Model "records" agreement by writing the ledger | Guard denies the path; rows need the HMAC key at `~/.private-ai-harness/consent.key` (0600), also guarded |
| Model edits or deletes a row | Hash chain + HMAC; `check` exits 4 on any broken row |
| Model injects a typed agreement via a scheduled prompt, subagent brief, or message tool | Guard denies the token in every tool input except the ask tool; Claude's prompt channel is not trusted at all |
| Model disables hooks | Guard denies hook files, settings paths, and `disableAllHooks` |
| Ask tool echoes the options | Recorder requires one unambiguous agreement or records nothing |
| A user-installed hook answers the ask tool programmatically | Out of scope: hooks the human installed are human-authorized automation |
| Deliberately adversarial model obfuscates a shell command | **Not covered.** A process running as the same OS user can always defeat in-process controls. The ledger stops drift and accidental self-agreement, not a determined attacker |

## Debugging

`PRIVATE_AI_HARNESS_CONSENT_DEBUG=1` in the host's environment makes every hook
call append its raw payload to `~/.private-ai-harness/consent-debug.jsonl`.
Use it when a host's ask tool never records (for example, to see the exact
answer shape) and fix the extraction in the script, keeping its fail-safe rule.
