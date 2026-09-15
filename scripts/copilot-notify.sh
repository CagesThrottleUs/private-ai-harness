#!/usr/bin/env bash
set -o nounset -o pipefail -o errexit
#
# copilot-notify - audio feedback adapter for Copilot CLI's hooks config
#
# Copilot CLI invokes a hook command per lifecycle event (sessionStart,
# agentStop, preCompact, notification, ...) with event-specific JSON on
# stdin, but — unlike Codex's single `notify` hook — it does not always
# include a field naming which event fired; the event is implied by which
# hooks.<eventName> array in ~/.copilot/config.json invoked the command.
#
# So instead of parsing stdin, install-copilot.sh passes the target
# Claude-style event name as $1 for each hook slot, and this adapter just
# forwards it to hook-beep.sh in the JSON shape it expects.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVENT="${1:-Notification}"

echo "{\"hook_event_name\":\"$EVENT\"}" | "$SCRIPT_DIR/hook-beep.sh"
