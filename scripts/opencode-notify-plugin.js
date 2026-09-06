// opencode plugin — audio feedback via hook-beep.sh
//
// Dropped into ~/.config/opencode/plugin/, opencode auto-loads any .js/.ts
// file in that directory (no opencode.json entry needed). Maps opencode's
// surfaces onto the same event names hook-beep.sh already understands
// (PreToolUse, PostToolUse, Notification, Stop, PreCompact,
// PermissionRequest), so all three hosts share one sound library under
// assets/sounds/.
//
// Two distinct surfaces, per opencode's plugin docs + source:
//   - tool.execute.before / tool.execute.after are BLOCKING HOOKS, not bus
//     events ("do not confuse hooks with events"); they fire only when the
//     plugin returns them as hook keys, so they are registered here as hooks.
//   - session.* and permission.* events arrive on the bus, delivered to the
//     "event" hook. permission.updated does not exist; the real events are
//     permission.asked / permission.replied.
//
// This file gets copied (not symlinked) into ~/.config/opencode/plugin/, so
// it cannot find hook-beep.sh next to itself at runtime the way codex-notify.sh
// can (that one stays in place inside the repo checkout). install-opencode.sh
// substitutes __HOOK_BEEP_PATH__ below with the absolute path to this repo's
// scripts/hook-beep.sh at install time.

import { spawn } from "node:child_process"

const HOOK_BEEP = "__HOOK_BEEP_PATH__"

const BUS_EVENT_MAP = {
  "session.idle": "Stop",
  "session.error": "Notification",
  "session.compacted": "PreCompact",
  "permission.asked": "PermissionRequest",
}

function beep(eventName) {
  const child = spawn(HOOK_BEEP, [], { stdio: ["pipe", "ignore", "ignore"], detached: true })
  child.on("error", (err) => console.error(`[private-ai-harness-notify] ${HOOK_BEEP}: ${err.message}`))
  child.stdin.end(JSON.stringify({ hook_event_name: eventName }))
  child.unref()
}

export const PrivateAiHarnessNotify = async () => ({
  "tool.execute.before": (_input) => {
    beep("PreToolUse")
  },
  "tool.execute.after": (_input) => {
    beep("PostToolUse")
  },
  event: async ({ event }) => {
    const mapped = BUS_EVENT_MAP[event?.type]
    if (mapped) beep(mapped)
  },
})