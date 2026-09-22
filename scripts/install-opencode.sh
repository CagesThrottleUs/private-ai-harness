#!/usr/bin/env bash
# Install private-ai-harness tooling for opencode (opencode.ai) from this checkout.
# Run from any directory: bash scripts/install-opencode.sh
#
# opencode's skill format is identical to Claude Code's SKILL.md — skills
# written for Claude Code work in opencode unmodified — and it reads a global
# ~/.config/opencode/AGENTS.md the same way Claude reads ~/.claude/CLAUDE.md.
# It has no plugin marketplace (npm packages or local files in
# ~/.config/opencode/plugin/ instead). Reviewer agents use opencode's own
# subagent schema (mode/model/permission), so scripts/install-opencode-agents.py
# adapts agents/*.md into ~/.config/opencode/agents/ subagents that inherit the
# invoking primary agent's model and permissions.
#
# What this script ports from install-claude.sh:
#   - host-agnostic CLI tools (rtk, ffmpeg)
#   - Context7 MCP, registered via `opencode mcp add`
#   - this repo's skills/ directory, symlinked into opencode's global skill
#     dir so every private-ai-harness skill loads natively (no adapter)
#   - a sound-notify plugin (scripts/opencode-notify-plugin.js), dropped into
#     opencode's auto-loaded plugin/ dir, reusing hook-beep.sh + assets/sounds
#   - reviewer agents (agents/*.md) adapted into opencode subagents
#   - the commit-msg git hook
#   - global guidance appended to opencode's AGENTS.md
#
# Not ported (no opencode equivalent): Claude/Codex plugin marketplace,
# LSP plugins, Android skill pack, cost-visibility plugins.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}✔${RESET} $*"; }
info() { echo -e "${CYAN}→${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET} $*"; }
fail() { echo -e "${RED}✖${RESET} $*"; }

check_cmd() { command -v "$1" &>/dev/null; }

# clone fresh, or fast-forward an existing checkout
clone_or_pull() {  # $1=git url  $2=dest
  if [[ -d "$2/.git" ]]; then
    git -C "$2" pull --ff-only --quiet && ok "updated $(basename "$2")" || warn "pull failed: $(basename "$2")"
  else
    rm -rf "$2"
    git clone --depth 1 --quiet "$1" "$2" && ok "cloned $(basename "$2")" || warn "clone failed: $(basename "$2")"
  fi
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCODE_HOME="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
GLOBAL_AGENTS="$OPENCODE_HOME/AGENTS.md"
GLOBAL_SKILLS="$OPENCODE_HOME/skills"
GLOBAL_PLUGIN_DIR="$OPENCODE_HOME/plugin"
GLOBAL_OPENCODE_JSON="$OPENCODE_HOME/opencode.json"
PONYTAIL_SRC="$OPENCODE_HOME/ponytail-src"

echo ""
echo "═══════════════════════════════════════════"
echo "  Private AI Harness — opencode installer"
echo "═══════════════════════════════════════════"
echo ""

HAVE_OPENCODE=1
if ! check_cmd opencode; then
  HAVE_OPENCODE=0
  warn "opencode CLI not found — continuing with file-based steps only"
  warn "install opencode first: https://opencode.ai"
fi

# ── 1. RTK ────────────────────────────────────────────────────────────────────
echo "1. RTK (Rust Tool Killer)"
if check_cmd rtk; then
  ok "rtk already installed ($(rtk --version 2>/dev/null || echo 'version unknown'))"
else
  info "Installing rtk..."
  brew install rtk && ok "rtk installed" || warn "rtk install failed"
fi
info "Running: rtk init -g"
rtk init -g && ok "rtk global init done" || warn "rtk init -g failed — check output above"
echo ""

# ── 2. Context7 MCP ──────────────────────────────────────────────────────────
echo "2. Context7 (MCP server)"
if [[ "$HAVE_OPENCODE" -eq 1 ]]; then
  info "Running: opencode mcp add context7 npx -y @upstash/context7-mcp@latest"
  opencode mcp add context7 npx -y @upstash/context7-mcp@latest \
    && ok "context7 MCP server registered" \
    || warn "context7 registration failed — may already be registered; verify with 'opencode mcp list'"
else
  warn "opencode CLI not found — add manually once installed:"
  warn "  opencode mcp add context7 npx -y @upstash/context7-mcp@latest"
fi
echo ""

# ── 3. FFmpeg ─────────────────────────────────────────────────────────────────
echo "3. FFmpeg"
if check_cmd ffmpeg; then
  ok "ffmpeg already installed ($(ffmpeg -version 2>/dev/null | head -1))"
else
  info "Installing ffmpeg..."
  brew install ffmpeg && ok "ffmpeg installed" || warn "ffmpeg install failed"
fi
echo ""

# ── 4. Skills — symlink into opencode's global skill dir ────────────────────
echo "4. private-ai-harness skills (native, no adapter needed)"
mkdir -p "$GLOBAL_SKILLS"
count=0
for skill_dir in "$REPO_ROOT"/skills/*/; do
  name="$(basename "$skill_dir")"
  [[ -f "$skill_dir/SKILL.md" ]] || { warn "$name has no SKILL.md — skipping"; continue; }
  ln -sfn "$skill_dir" "$GLOBAL_SKILLS/$name"
  count=$((count + 1))
done
ok "$count skills symlinked → $GLOBAL_SKILLS"
echo ""

# ── 5. Sound-notify plugin ───────────────────────────────────────────────────
echo "5. Sound-notify plugin"
mkdir -p "$GLOBAL_PLUGIN_DIR"
chmod +x "$REPO_ROOT/scripts/hook-beep.sh"
sed "s#__HOOK_BEEP_PATH__#$REPO_ROOT/scripts/hook-beep.sh#" \
  "$REPO_ROOT/scripts/opencode-notify-plugin.js" \
  > "$GLOBAL_PLUGIN_DIR/private-ai-harness-notify.js"
ok "sound-notify plugin installed → $GLOBAL_PLUGIN_DIR/private-ai-harness-notify.js"
info "Note: the installed copy has an absolute path to this checkout's hook-beep.sh"
info "baked in — do not move or delete this repo checkout, or re-run this installer after moving it."
echo ""

# ── 6. commit-msg git hook ───────────────────────────────────────────────────
echo "6. commit-msg hook"
HOOK_SOURCE="$REPO_ROOT/scripts/commit-msg.sh"
HOOK_TARGET="$REPO_ROOT/.git/hooks/commit-msg"
if [[ ! -f "$HOOK_SOURCE" ]]; then
  warn "scripts/commit-msg.sh not found — skipping hook install"
elif [[ ! -d "$REPO_ROOT/.git" ]]; then
  warn "$REPO_ROOT is not a git repo — skipping hook install"
else
  chmod +x "$HOOK_SOURCE"
  ln -sf "$HOOK_SOURCE" "$HOOK_TARGET"
  ok "commit-msg hook installed → $HOOK_TARGET"
fi

CWD_GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -n "$CWD_GIT_ROOT" && "$CWD_GIT_ROOT" != "$REPO_ROOT" ]]; then
  CWD_HOOK="$CWD_GIT_ROOT/.git/hooks/commit-msg"
  ln -sf "$HOOK_SOURCE" "$CWD_HOOK" \
    && ok "commit-msg hook installed → $CWD_HOOK" \
    || warn "hook install failed for $CWD_GIT_ROOT"
fi
echo ""

# ── 7. Global guidance — opencode AGENTS.md ──────────────────────────────────
echo "7. Global guidance (opencode AGENTS.md)"
mkdir -p "$OPENCODE_HOME"
if check_cmd python3; then
  python3 - "$GLOBAL_AGENTS" "$REPO_ROOT" <<'PYEOF'
from pathlib import Path
import sys

path = Path(sys.argv[1])
repo_root = sys.argv[2]
start = "<!-- private-ai-harness:start -->"
end = "<!-- private-ai-harness:end -->"
block = f"""{start}
## Private AI Harness

Skills are installed natively (symlinked into ~/.config/opencode/skills/) and
auto-invoke like any other opencode skill — no manual reference needed.

Reviewer agents from `{repo_root}/agents/*.md` are adapted into opencode
subagents in ~/.config/opencode/agents/, named `private-ai-harness-<name>`.
They inherit the invoking primary agent's model and permissions. When a skill
asks for a named reviewer, dispatch the matching `private-ai-harness-<name>`
subagent via the Task tool or @mention — do not read the file and re-derive
the brief.
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
else
  warn "python3 not found — skipping global guidance sync"
fi
echo ""

# ── 8. Reviewer agents — opencode subagents ─────────────────────────────────
echo "8. Reviewer agents (opencode subagents)"
if check_cmd python3; then
  if python3 "$REPO_ROOT/scripts/install-opencode-agents.py" --check >/dev/null; then
    python3 "$REPO_ROOT/scripts/install-opencode-agents.py" \
      --dest-dir "$OPENCODE_HOME/agents"
  else
    warn "agent validation failed — skipping reviewer agent adapters"
  fi
else
  warn "python3 not found — skipping reviewer agent adapters"
fi
echo ""

# ── 9. Ponytail (YAGNI / lazy-dev enforcement plugin) ────────────────────────
echo "9. Ponytail (YAGNI / lazy-dev skill pack)"
clone_or_pull "https://github.com/DietrichGebert/ponytail.git" "$PONYTAIL_SRC"

if [[ -d "$PONYTAIL_SRC/skills" ]]; then
  linked=0
  for skill_dir in "$PONYTAIL_SRC"/skills/*/; do
    name="$(basename "$skill_dir")"
    ln -sfn "${skill_dir%/}" "$GLOBAL_SKILLS/$name"
    linked=$((linked + 1))
  done
  ok "$linked ponytail skills symlinked → $GLOBAL_SKILLS"
else
  warn "ponytail skills/ not found in checkout — skipping skill symlinks"
fi

if check_cmd python3; then
  python3 - "$GLOBAL_OPENCODE_JSON" <<'PYEOF'
import json, sys, pathlib
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text()) if path.exists() else {}
plugins = data.setdefault("plugin", [])
if "@dietrichgebert/ponytail" not in plugins:
    plugins.append("@dietrichgebert/ponytail")
path.write_text(json.dumps(data, indent=2) + "\n")
PYEOF
  ok "ponytail plugin registered in $GLOBAL_OPENCODE_JSON"
else
  warn "python3 not found — add manually to $GLOBAL_OPENCODE_JSON:"
  warn '  { "plugin": ["@dietrichgebert/ponytail"] }'
fi
echo ""

echo "═══════════════════════════════════════════"
echo -e "${YELLOW}NOT PORTED (no opencode equivalent):${RESET}"
echo "  - Claude/Codex plugin marketplace"
echo "  - LSP plugins, Android skill pack, cost-visibility plugins"
echo "═══════════════════════════════════════════"
echo ""
ok "Done. Start a new opencode session — skills load from ~/.config/opencode/skills/,"
ok "reviewer agents from ~/.config/opencode/agents/ (@private-ai-harness-<name>)."
