#!/usr/bin/env bash
# Install private-ai-harness for Codex from this checkout.
# Run from any directory: bash scripts/install-codex.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}✔${RESET} $*"; }
info() { echo -e "${CYAN}→${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET} $*"; }
fail() { echo -e "${RED}✖${RESET} $*" >&2; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
GLOBAL_AGENTS="$CODEX_HOME/AGENTS.md"
INSTALL_GLOBAL_GUIDANCE=1

if [[ "${1:-}" == "--no-global-guidance" ]]; then
  INSTALL_GLOBAL_GUIDANCE=0
elif [[ $# -gt 0 ]]; then
  fail "usage: bash scripts/install-codex.sh [--no-global-guidance]"
  exit 2
fi

if ! command -v codex >/dev/null 2>&1; then
  fail "codex CLI not found"
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  fail "python3 not found"
  exit 1
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  Private AI Harness — Codex installer"
echo "═══════════════════════════════════════════"
echo ""

info "Validating Codex agent adapters"
python3 "$REPO_ROOT/scripts/install-codex-agents.py" --check
ok "agent definitions valid"

info "Registering the local marketplace"
if codex plugin marketplace add "$REPO_ROOT"; then
  ok "private-ai-harness marketplace registered"
else
  warn "marketplace registration returned an error; it may already be registered"
fi

info "Installing private-ai-harness from the local marketplace"
codex plugin add private-ai-harness@private-ai-harness
ok "Codex plugin installed"

info "Registering the ponytail marketplace"
if codex plugin marketplace add DietrichGebert/ponytail; then
  ok "ponytail marketplace registered"
else
  warn "marketplace registration returned an error; it may already be registered"
fi

info "Installing ponytail (YAGNI / lazy-dev skill pack)"
codex plugin add ponytail@ponytail && ok "ponytail installed" || warn "ponytail install failed"

info "Installing Codex custom-agent adapters"
python3 "$REPO_ROOT/scripts/install-codex-agents.py"
ok "Codex agents installed"

if [[ "$INSTALL_GLOBAL_GUIDANCE" -eq 1 ]]; then
  info "Synchronizing global Codex guidance"
  mkdir -p "$CODEX_HOME"
  python3 - "$GLOBAL_AGENTS" <<'PYEOF'
from pathlib import Path
import sys

path = Path(sys.argv[1])
start = "<!-- private-ai-harness:start -->"
end = "<!-- private-ai-harness:end -->"
block = f"""{start}
## Private AI Harness

- Use the installed `private-ai-harness:engineer` skill as the entry point for engineering work.
- Apply `private-ai-harness:karpathy` and `private-ai-harness:commit-discipline` when writing code or commit messages.
- Use the `private-ai-harness-<agent-name>` Codex custom agents when a harness skill requests a named reviewer.
- Read `private-ai-harness:using-superpowers` for Codex tool and subagent mappings when a skill uses Claude-oriented tool names.
{end}"""

current = path.read_text(encoding="utf-8") if path.exists() else ""
if start in current and end in current:
    before, remainder = current.split(start, 1)
    _, after = remainder.split(end, 1)
    updated = before.rstrip() + "\n\n" + block + after
else:
    updated = current.rstrip() + ("\n\n" if current.strip() else "") + block + "\n"
path.write_text(updated, encoding="utf-8")
PYEOF
  ok "global guidance synchronized in $GLOBAL_AGENTS"
  if [[ -s "$CODEX_HOME/AGENTS.override.md" ]]; then
    warn "$CODEX_HOME/AGENTS.override.md exists; Codex will prefer it over AGENTS.md"
  fi
else
  warn "global Codex guidance skipped"
fi

info "Wiring audio feedback (notify hook)"
CODEX_CONFIG="$CODEX_HOME/config.toml"
NOTIFY_SCRIPT="$REPO_ROOT/scripts/codex-notify.sh"
chmod +x "$NOTIFY_SCRIPT"
mkdir -p "$CODEX_HOME"
if [[ -f "$CODEX_CONFIG" ]] && grep -q '^notify *=' "$CODEX_CONFIG"; then
  warn "notify already set in $CODEX_CONFIG — leaving it untouched (edit manually to use $NOTIFY_SCRIPT)"
else
  printf '\nnotify = ["%s"]\n' "$NOTIFY_SCRIPT" >> "$CODEX_CONFIG"
  ok "notify hook added → $CODEX_CONFIG"
fi

echo ""
echo "Start a new Codex session, then open /plugins to verify the plugin."
echo "Use /agent to inspect harness reviewer agents."
echo ""
