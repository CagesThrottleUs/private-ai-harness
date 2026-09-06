// opencode plugin — audio feedback via hook-beep.sh
//
// Dropped into ~/.config/opencode/plugin/, opencode auto-loads any .js/.ts
// file in that directory (no opencode.json entry needed). Subscribes to the
// "event" hook and maps opencode's event.type onto the same event names
// hook-beep.sh already understands (PreToolUse, PostToolUse, Notification,
// Stop, PreCompact, PermissionRequest), so all three hosts share one sound
// library under assets/sounds/.
//
// This file gets copied (not symlinked) into ~/.config/opencode/plugin/, so
// it cannot find hook-beep.sh next to itself at runtime the way codex-notify.sh
// can (that one stays in place inside the repo checkout). install-opencode.sh
// substitutes __HOOK_BEEP_PATH__ below with the absolute path to this repo's
// scripts/hook-beep.sh at install time.

import { spawn } from "node:child_process"

const HOOK_BEEP = "__HOOK_BEEP_PATH__"

const EVENT_MAP = {
  "session.idle": "Stop",
  "session.error": "Notification",
  "permission.updated": "PermissionRequest",
  "tool.execute.before": "PreToolUse",
  "tool.execute.after": "PostToolUse",
  "session.compacted": "PreCompact",
}

function beep(eventName) {
  const child = spawn(HOOK_BEEP, [], { stdio: ["pipe", "ignore", "ignore"], detached: true })
  child.on("error", (err) => console.error(`[private-ai-harness-notify] ${HOOK_BEEP}: ${err.message}`))
  child.stdin.end(JSON.stringify({ hook_event_name: eventName }))
  child.unref()
}

export const PrivateAiHarnessNotify = async () => ({
  event: async ({ event }) => {
    const mapped = EVENT_MAP[event?.type]
    if (mapped) beep(mapped)
  },
})
