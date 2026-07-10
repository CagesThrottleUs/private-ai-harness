# Codex Tool Mapping

Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:

| Skill references | Codex equivalent |
|-----------------|------------------|
| `Task` or `Agent` tool (dispatch subagent) | `spawn_agent` or an equivalent native subagent dispatch |
| Multiple `Task` calls (parallel) | Multiple `spawn_agent` calls |
| Task returns result | `wait_agent` |
| Stop or steer a task | `interrupt_agent`, `send_message`, or the available native equivalent |
| `TodoWrite` (task tracking) | `update_plan` |
| `Skill` tool (invoke a skill) | Skills load natively — mention `$<skill-name>` or use `/skills` |
| `Read`, `Write`, `Edit` (files) | Use your native file tools |
| `Bash` (run commands) | Use your native shell tools |

## Named Harness Agents

Claude agent identifiers map to Codex custom-agent names as follows:

| Claude identifier | Codex custom agent |
|-------------------|--------------------|
| `private-ai-harness:<name>` | `private-ai-harness-<name>` |

`scripts/install-codex.sh` installs these custom agents under
`$CODEX_HOME/agents/` from the shared Markdown definitions in `agents/`.
Their model is inherited from the parent Codex session; Claude `opus` definitions
map to high reasoning effort, `sonnet` to medium, and `haiku` to low.

If the requested custom agent is unavailable, read `agents/<name>.md` from the
plugin and spawn a general-purpose agent with that file's body as its
instructions. Preserve every input named by the calling skill.

Current Codex releases enable subagent workflows by default. Do not require a
legacy `features.multi_agent` flag. Respect any project or session rule that
restricts delegation.

Legacy note: Codex builds before `rust-v0.115.0` exposed spawned-agent waiting
as `wait`. Current Codex uses `wait_agent`; code-mode `exec/wait` is unrelated.

## Environment Detection

Skills that create worktrees or finish branches should detect their
environment with read-only git commands before proceeding:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` → already in a linked worktree (skip creation)
- `BRANCH` empty → detached HEAD (cannot branch/push/PR from sandbox)

See `using-git-worktrees` Step 0 and `finishing-a-development-branch`
Step 1 for how each skill uses these signals.

## Codex App Finishing

When the sandbox blocks branch/push operations (detached HEAD in an
externally managed worktree), the agent commits all work and informs
the user to use the App's native controls:

- **"Create branch"** — names the branch, then commit/push/PR via App UI
- **"Hand off to local"** — transfers work to the user's local checkout

The agent can still run tests, stage files, and output suggested branch
names, commit messages, and PR descriptions for the user to copy.

## Codex Plugin Refresh

After changing the harness source, reinstall it from the configured local
marketplace and start a new session so Codex loads the new skills and agents:

```bash
bash scripts/install-codex.sh
```
