#!/usr/bin/env bash
# Install tools required by the AI harness.
# Run from any directory: bash scripts/install-tools.sh
#
# Steps 1-6 run automatically. Step 7 (VoiceMode /voicemode:install)
# must be run manually inside Claude Code — see instructions at the end.

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

echo ""
echo "═══════════════════════════════════════════"
echo "  AI Harness — tool installer"
echo "═══════════════════════════════════════════"
echo ""

# ── 1. RTK ────────────────────────────────────────────────────────────────────
echo "1.  RTK (Rust Tool Killer)"
if check_cmd rtk; then
  ok "rtk already installed ($(rtk --version 2>/dev/null || echo 'version unknown'))"
else
  info "Installing rtk..."
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | sh
  ok "rtk installed"
fi

info "Running: rtk init -g"
rtk init -g && ok "rtk global init done" || warn "rtk init -g failed — check output above"
echo ""

# ── 2. CodeGraph ──────────────────────────────────────────────────────────────
echo "2.  CodeGraph"
if ! check_cmd npm; then
  fail "npm not found — install Node.js first, then re-run this script"
  exit 1
fi

if check_cmd codegraph; then
  ok "codegraph already installed"
else
  info "Installing @colbymchenry/codegraph globally..."
  npm i -g @colbymchenry/codegraph
  ok "codegraph installed"
fi
echo ""

# ── 3. Context7 ───────────────────────────────────────────────────────────────
echo "3.  Context7"
info "Running: npx ctx7 setup"
npx ctx7 setup && ok "Context7 setup done" || warn "Context7 setup failed — check output above"
echo ""

# ── 4. claude-mem ────────────────────────────────────────────────────────────
echo "4.  claude-mem"
info "Running: npx claude-mem install"
npx claude-mem install && ok "claude-mem installed" || warn "claude-mem install failed — check output above"
echo ""

# ── 5. UI skills ──────────────────────────────────────────────────────────────
echo "5.  UI skills (impeccable, emilkowalski/skill, taste-skill)"
if ! check_cmd npx; then
  warn "npx not found — skipping UI skills"
else
  info "npx skills add pbakaus/impeccable"
  npx skills add pbakaus/impeccable && ok "impeccable" || warn "impeccable failed"

  info "npx skills add emilkowalski/skill"
  npx skills add emilkowalski/skill && ok "emilkowalski/skill" || warn "emilkowalski/skill failed"

  info "npx skills add Leonxlnx/taste-skill"
  npx skills add Leonxlnx/taste-skill && ok "taste-skill" || warn "taste-skill failed"
fi
echo ""

# ── 6. Claude plugins ────────────────────────────────────────────────────────
echo "6.  Claude plugins (code-review, code-simplifier, skill-creator, claude-md-management)"
if ! check_cmd claude; then
  warn "claude CLI not found — run these manually:"
  warn "  claude plugin install code-review@claude-plugins-official"
  warn "  claude plugin install code-simplifier@claude-plugins-official"
  warn "  claude plugin install skill-creator@claude-plugins-official"
  warn "  claude plugin install claude-md-management@claude-plugins-official"
else
  for plugin in \
    code-review@claude-plugins-official \
    code-simplifier@claude-plugins-official \
    skill-creator@claude-plugins-official \
    claude-md-management@claude-plugins-official
  do
    info "Installing $plugin..."
    claude plugin install "$plugin" && ok "$plugin installed" || warn "$plugin install failed"
  done
fi
echo ""

# ── 7. VoiceMode ─────────────────────────────────────────────────────────────
echo "7.  VoiceMode"
if ! check_cmd claude; then
  warn "claude CLI not found — run VoiceMode steps manually inside Claude Code"
else
  info "Adding VoiceMode marketplace..."
  claude plugin marketplace add mbailey/voicemode && ok "marketplace added" || warn "marketplace add failed"

  info "Installing VoiceMode plugin..."
  claude plugin install voicemode@voicemode && ok "voicemode plugin installed" || warn "plugin install failed"
fi

echo ""
echo "═══════════════════════════════════════════"
echo -e "${YELLOW}MANUAL STEP REQUIRED — run inside Claude Code:${RESET}"
echo ""
echo "  /voicemode:install"
echo ""
echo "This installs VoiceMode CLI, FFmpeg, and local voice services."
echo "It cannot be scripted because it runs as a Claude skill."
echo "═══════════════════════════════════════════"
echo ""
ok "Done. Check any warnings above."
