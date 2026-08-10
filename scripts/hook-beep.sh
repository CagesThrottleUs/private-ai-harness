#!/usr/bin/env bash
set -o nounset -o pipefail -o errexit
#
# hook-beep - audio feedback for Claude Code hook events
#
# Plays a short sound whenever Claude Code fires PreToolUse, PostToolUse,
# Notification, Stop, PreCompact, or PermissionRequest. Reads the event
# name from stdin JSON (hook_event_name) and picks the matching sound
# under assets/sounds/, falling back to assets/sounds/fallback.mp3.
#
# Ported from voicemode's voicemode-hook-receiver.sh (MIT) so this beep
# survives uninstalling the voicemode plugin.
#
# Disable:
#   ~/.private-ai-harness/beep-disabled - sentinel file, if present
#   PAH_BEEP_ENABLED=false             - env var override

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/../assets/sounds"

if [[ -f "$HOME/.private-ai-harness/beep-disabled" ]]; then
  exit 0
fi

if [[ "${PAH_BEEP_ENABLED:-true}" == "false" ]]; then
  exit 0
fi

EVENT="PreToolUse"
if [[ ! -t 0 ]]; then
  JSON_INPUT=$(cat)
  if command -v jq &>/dev/null; then
    EVENT=$(echo "$JSON_INPUT" | jq -r '.hook_event_name // "PreToolUse"')
  else
    EVENT=$(echo "$JSON_INPUT" | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)"/\1/' || echo "PreToolUse")
  fi
fi

SOUND_FILE="$SOUNDS_DIR/$EVENT/default.mp3"
if [[ ! -f "$SOUND_FILE" ]]; then
  SOUND_FILE="$SOUNDS_DIR/fallback.mp3"
fi

if [[ ! -f "$SOUND_FILE" ]]; then
  exit 0
fi

if command -v afplay &>/dev/null; then
  afplay "$SOUND_FILE" >/dev/null 2>&1 &
  disown 2>/dev/null || true
elif command -v paplay &>/dev/null; then
  paplay "$SOUND_FILE" >/dev/null 2>&1 &
  disown 2>/dev/null || true
elif command -v ffplay &>/dev/null; then
  ffplay -nodisp -autoexit -loglevel quiet "$SOUND_FILE" >/dev/null 2>&1 &
  disown 2>/dev/null || true
fi

exit 0
