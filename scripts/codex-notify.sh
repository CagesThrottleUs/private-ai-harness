#!/usr/bin/env bash
set -o nounset -o pipefail -o errexit
#
# codex-notify - audio feedback adapter for Codex's `notify` config
#
# Codex calls a single external program (config.toml `notify = [...]`) with
# one JSON argument per event, e.g. {"type":"agent-turn-complete", ...}.
# Claude's hook-beep.sh instead reads JSON from stdin keyed by
# "hook_event_name" (PreToolUse, PostToolUse, Notification, Stop, ...).
#
# This adapter maps Codex's `type` field onto the closest Claude hook event
# name and pipes it to hook-beep.sh so both hosts share one sound library
# under assets/sounds/.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="${1:-}"

TYPE="agent-turn-complete"
if [[ -n "$PAYLOAD" ]]; then
  if command -v jq &>/dev/null; then
    TYPE=$(echo "$PAYLOAD" | jq -r '.type // "agent-turn-complete"')
  else
    TYPE=$(echo "$PAYLOAD" | grep -o '"type"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)"/\1/' || echo "agent-turn-complete")
  fi
fi

case "$TYPE" in
  agent-turn-complete) EVENT="Stop" ;;
  *)                   EVENT="Notification" ;;
esac

echo "{\"hook_event_name\":\"$EVENT\"}" | "$SCRIPT_DIR/hook-beep.sh"
