#!/usr/bin/env bash
# Install private-ai-harness for GitHub Copilot from this checkout.
# Run from any directory: bash scripts/install-copilot.sh
#
# Mirrors install-claude.sh's optional-tool lineup where a real Copilot
# equivalent exists. Everything below was verified against the actual CLIs
# installed on the reference machine (not just docs/web search) before being
# wired in — see the "not ported" summary at the end for what has no
# Copilot equivalent and why.

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

check_cmd() { command -v "$1" &>/dev/null; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COPILOT_HOME="${COPILOT_HOME:-$HOME/.copilot}"
GLOBAL_INSTRUCTIONS="$COPILOT_HOME/copilot-instructions.md"
GLOBAL_CONFIG="$COPILOT_HOME/config.json"
GLOBAL_HOOKS_FILE="$COPILOT_HOME/hooks/private-ai-harness.json"
GLOBAL_SKILLS_DIR="$COPILOT_HOME/skills"
AGENT_SKILLS_DIR="$HOME/.agents/skills"
ANDROID_SKILLS_SRC="$HOME/.copilot-skills-sources"

if ! check_cmd copilot; then
  fail "copilot CLI not found — install it first: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli"
  exit 1
fi
if ! check_cmd python3; then
  fail "python3 not found"
  exit 1
fi

# clone fresh, or fast-forward an existing checkout (mirrors install-claude.sh)
clone_or_pull() {  # $1=git url  $2=dest
  if [[ -d "$2/.git" ]]; then
    git -C "$2" pull --ff-only --quiet && ok "updated $(basename "$2")" || warn "pull failed: $(basename "$2")"
  else
    rm -rf "$2"
    git clone --depth 1 --quiet "$1" "$2" && ok "cloned $(basename "$2")" || warn "clone failed: $(basename "$2")"
  fi
}

# copy every SKILL.md directory found under $1 into $GLOBAL_SKILLS_DIR
copy_skills_from() {  # $1=source root
  find "$1" -name SKILL.md -exec dirname {} \; 2>/dev/null \
    | while read -r d; do cp -R "$d" "$GLOBAL_SKILLS_DIR/"; done
}

echo ""
echo "═══════════════════════════════════════════"
echo "  Private AI Harness — GitHub Copilot installer"
echo "═══════════════════════════════════════════"
echo ""

# ── 1. private-ai-harness skills + agents ────────────────────────────────────
echo "1. private-ai-harness skills + agents"

info "Validating Copilot agent-skill adapters"
python3 "$REPO_ROOT/scripts/install-copilot-agents.py" --check
ok "agent definitions valid"

info "Linking harness skills into $GLOBAL_SKILLS_DIR"
mkdir -p "$GLOBAL_SKILLS_DIR"
linked=0
for skill_dir in "$REPO_ROOT"/skills/*/; do
  name="$(basename "$skill_dir")"
  target="$GLOBAL_SKILLS_DIR/$name"
  if [[ -e "$target" && ! -L "$target" ]]; then
    warn "$target exists and is not a symlink — leaving it untouched"
  else
    ln -sfn "${skill_dir%/}" "$target" && linked=$((linked + 1))
  fi
done
ok "linked $linked skills → $GLOBAL_SKILLS_DIR"

info "Installing Copilot agent skills (reviewer definitions)"
python3 "$REPO_ROOT/scripts/install-copilot-agents.py" --dest-dir "$AGENT_SKILLS_DIR"
ok "agent skills installed → $AGENT_SKILLS_DIR"
echo ""

# ── 2. RTK ────────────────────────────────────────────────────────────────────
echo "2. RTK (token-optimized CLI proxy)"
if check_cmd rtk; then
  rtk init -g --copilot \
    && ok "rtk Copilot hook + instructions installed" \
    || warn "rtk init -g --copilot failed — check output above"
else
  warn "rtk not found — skipping (see install-claude.sh step 1)"
fi
echo ""

# ── 3. Context7 ───────────────────────────────────────────────────────────────
echo "3. Context7 (MCP)"
if check_cmd npx; then
  copilot mcp add context7 -- npx -y @upstash/context7-mcp \
    && ok "context7 MCP server added" \
    || warn "context7 add failed — may already be configured (copilot mcp list)"
else
  warn "npx not found — skipping Context7"
fi
echo ""

# ── 4. UI skills ──────────────────────────────────────────────────────────────
echo "4. Skills (impeccable, taste-skill)"
if check_cmd npx; then
  info "npx skills add pbakaus/impeccable --agent github-copilot"
  npx --yes skills add pbakaus/impeccable --agent github-copilot -g -y \
    && ok "impeccable" || warn "impeccable failed"

  info "npx skills add Leonxlnx/taste-skill --agent github-copilot"
  npx --yes skills add Leonxlnx/taste-skill --agent github-copilot -g -y \
    && ok "taste-skill" || warn "taste-skill failed"
else
  warn "npx not found — skipping skills"
fi
echo ""

# ── 5. Android team skills ────────────────────────────────────────────────────
echo "5. Android skills (Kotlin, Compose, KMP, testing, performance)"
mkdir -p "$ANDROID_SKILLS_SRC" "$GLOBAL_SKILLS_DIR"

# 5a. npx skills add — chrisbanes, ceorkm, baoyu, hamen, drjacky (same tool
# install-claude.sh already uses; --agent github-copilot targets Copilot
# directly instead of Claude Code)
if check_cmd npx; then
  info "npx skills add chrisbanes/skills";            npx --yes skills add chrisbanes/skills            --agent github-copilot -g -y && ok "chrisbanes/skills"      || warn "chrisbanes/skills failed"
  info "npx skills add ceorkm/mobile-app-ui-design";  npx --yes skills add ceorkm/mobile-app-ui-design  --agent github-copilot -g -y && ok "mobile-app-ui-design"   || warn "mobile-app-ui-design failed"
  info "npx skills add jimliu/baoyu-skills";          npx --yes skills add jimliu/baoyu-skills          --agent github-copilot -g -y && ok "baoyu-skills"           || warn "baoyu-skills failed"
  info "npx skills add hamen/compose_skill";          npx --yes skills add hamen/compose_skill --skill '*' --agent github-copilot -g -y && ok "compose_skill"    || warn "compose_skill failed"
  info "npx skills add drjacky/claude-android-ninja"; npx --yes skills add drjacky/claude-android-ninja --agent github-copilot -g -y && ok "claude-android-ninja" || warn "claude-android-ninja failed"
else
  warn "npx not found — skipping chrisbanes, ceorkm, baoyu, hamen, drjacky"
fi

# 5b. skydoves — no Copilot-aware installer of their own (their
# install-skills.sh only targets Claude Code/Android Studio/Gemini), but the
# SKILL.md files themselves are plain markdown — clone and copy directly
for repo in android-testing-skills compose-performance-skills; do
  dest="$ANDROID_SKILLS_SRC/$repo"
  clone_or_pull "https://github.com/skydoves/$repo.git" "$dest"
  copy_skills_from "$dest" && ok "skydoves/$repo skills copied" || warn "skydoves/$repo copy failed"
done

# 5c. new-silvermoon — already ships .github/skills/, Copilot's own native path
SILVERMOON="$ANDROID_SKILLS_SRC/awesome-android-agent-skills"
clone_or_pull "https://github.com/new-silvermoon/awesome-android-agent-skills.git" "$SILVERMOON"
copy_skills_from "$SILVERMOON" && ok "silvermoon skills copied" || warn "silvermoon copy failed"

# 5d. Meet-Miyani — single-file skill
MEET_MIYANI="$ANDROID_SKILLS_SRC/compose-skill-meet-miyani"
clone_or_pull "https://github.com/Meet-Miyani/compose-skill.git" "$MEET_MIYANI"
copy_skills_from "$MEET_MIYANI" && ok "Meet-Miyani/compose-skill copied" || warn "Meet-Miyani/compose-skill copy failed"

# 5e. rcosteira79 + aldefy — installed via Claude's plugin marketplace in
# install-claude.sh, which has no Copilot equivalent; the underlying
# SKILL.md content is plain markdown, so clone the source repos directly
# instead (bypasses the marketplace layer entirely)
RCOSTEIRA="$ANDROID_SKILLS_SRC/android-skills-rcosteira79"
clone_or_pull "https://github.com/rcosteira79/android-skills.git" "$RCOSTEIRA"
copy_skills_from "$RCOSTEIRA" && ok "rcosteira79/android-skills copied" || warn "rcosteira79/android-skills copy failed"

ALDEFY="$ANDROID_SKILLS_SRC/compose-skill-aldefy"
clone_or_pull "https://github.com/aldefy/compose-skill.git" "$ALDEFY"
copy_skills_from "$ALDEFY" && ok "aldefy/compose-skill copied" || warn "aldefy/compose-skill copy failed"
echo ""

# ── 6. Audio feedback (hooks) ─────────────────────────────────────────────────
echo "6. Audio feedback (Copilot CLI hooks)"
# Personal hooks live in their own files under ~/.copilot/hooks/*.json, NOT
# under a "hooks" key in config.json (that key is silently ignored — verified
# against docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks).
# Each file needs {"version": 1, "hooks": {...}} and entries use "bash"/
# "timeoutSec", not "command"/"timeout". Copilot CLI has no preCompact event
# (valid: sessionStart, sessionEnd, userPromptSubmitted, preToolUse,
# postToolUse, errorOccurred, agentStop). preToolUse/postToolUse are wired
# too — without them the only audible cue all session is the single Stop
# beep at the very end, since Copilot fires no other event hook-beep.sh has
# a dedicated sound for.
chmod +x "$REPO_ROOT/scripts/copilot-notify.sh"
mkdir -p "$(dirname "$GLOBAL_HOOKS_FILE")"
python3 - "$GLOBAL_HOOKS_FILE" "$REPO_ROOT" <<'PYEOF'
from pathlib import Path
import json
import shutil
import sys
import datetime

path = Path(sys.argv[1])
repo_root = sys.argv[2]

data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
data.setdefault("version", 1)
hooks = data.setdefault("hooks", {})
notify_cmd = f"{repo_root}/scripts/copilot-notify.sh"

def ensure_hook(event_key: str, claude_event_name: str) -> None:
    entries = hooks.setdefault(event_key, [])
    bash_cmd = f"{notify_cmd} {claude_event_name}"
    if not any(e.get("bash") == bash_cmd for e in entries):
        entries.append({"type": "command", "bash": bash_cmd, "timeoutSec": 5})

ensure_hook("sessionStart", "SessionStart")
ensure_hook("agentStop", "Stop")
ensure_hook("preToolUse", "PreToolUse")
ensure_hook("postToolUse", "PostToolUse")

if path.exists():
    backup = path.with_name(f"{path.name}.bak.{datetime.datetime.now():%Y%m%d%H%M%S}")
    shutil.copy2(path, backup)

path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PYEOF
ok "sound hooks wired into $GLOBAL_HOOKS_FILE (SessionStart/Stop/PreToolUse/PostToolUse)"
echo ""

# ── 7. Global Copilot instructions ────────────────────────────────────────────
echo "7. Global Copilot instructions"
python3 - "$GLOBAL_INSTRUCTIONS" <<'PYEOF'
from pathlib import Path
import sys

path = Path(sys.argv[1])
start = "<!-- private-ai-harness:start -->"
end = "<!-- private-ai-harness:end -->"
block = f"""{start}
## Private AI Harness

- Skills auto-load from `~/.copilot/skills/` (symlinked to the harness `skills/` tree)
  — invoke by describing the task, or by name (e.g. "use the workflow skill").
- Reviewer agent skills live in `~/.agents/skills/private-ai-harness-*` — same
  trigger model, loaded when a task matches their description.
- Repos built with this harness already ship an `AGENTS.md`; Copilot coding
  agent and Copilot CLI read it natively — no extra step needed per repo.
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
ok "global guidance synchronized in $GLOBAL_INSTRUCTIONS"
echo ""

echo "═══════════════════════════════════════════"
echo -e "${YELLOW}Not ported (no Copilot equivalent found):${RESET}"
echo "  claude-mem        — Claude Code-specific hook/plugin memory system, no"
echo "                      standalone MCP mode (cmem.ai bridges it, but that's a"
echo "                      separate paid hosted product, not a CLI install step)"
echo "  Claude plugins    — code-review, code-simplifier, skill-creator,"
echo "                      claude-md-management, security-guidance, the 6 LSP"
echo "                      plugins, Understand-Anything, context-guard,"
echo "                      claude-context-optimizer — Claude's plugin-marketplace"
echo "                      system has no Copilot counterpart (installed-plugins/"
echo "                      exists in ~/.copilot/ but is unused on this machine)"
echo "  statusline        — Claude Code terminal UI feature, not applicable to a"
echo "                      Copilot CLI/Chat session"
echo "═══════════════════════════════════════════"
echo "Start a new Copilot CLI / Copilot Chat session to pick up the changes."
echo "Verify: ask Copilot to list its available skills; run 'copilot mcp list'."
echo "═══════════════════════════════════════════"
echo ""
