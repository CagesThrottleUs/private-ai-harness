// opencode plugin — audio feedback via hook-beep.sh
//
// Dropped into ~/.config/opencode/plugin/, opencode auto-loads any .js/.ts
// file in that directory (no opencode.json entry needed). Subscribes to the
// "event" hook and maps opencode's event.type onto the same event names
// hook-beep.sh already understands (PreToolUse, PostToolUse, Notification,
// Stop, PreCompact, PermissionRequest), so all three hosts share one sound
// library under assets/sounds/.

import { spawn } from "node:child_process"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url))
const HOOK_BEEP = join(SCRIPT_DIR, "hook-beep.sh")

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
  child.stdin.end(JSON.stringify({ hook_event_name: eventName }))
  child.unref()
}

export const PrivateAiHarnessNotify = async () => ({
  event: async ({ event }) => {
    const mapped = EVENT_MAP[event?.type]
    if (mapped) beep(mapped)
  },
})
