#!/usr/bin/env bash
# Install tools required by the AI harness.
# Run from any directory: bash scripts/install-tools.sh
#
# Steps 1-14 run automatically. Step 10 self-installs this repo as a Claude plugin.
# Step 11 injects caveman mode into ~/.claude/CLAUDE.md.
# Step 12 injects commit discipline into ~/.claude/CLAUDE.md.
# Step 13 injects development workflow into ~/.claude/CLAUDE.md.
# Step 14 installs the commit-msg git hook in the current project.
# VoiceMode (/voicemode:install) must be run manually inside Claude Code.

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
  brew install rtk
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

# ── 5. UI skills ─────────────────────────────────────────────
echo "5.  Skills (impeccable, taste-skill)"
if ! check_cmd npx; then
  warn "npx not found — skipping skills"
else
  info "npx skills add pbakaus/impeccable"
  npx skills add pbakaus/impeccable && ok "impeccable" || warn "impeccable failed"

  info "npx skills add Leonxlnx/taste-skill"
  npx skills add Leonxlnx/taste-skill && ok "taste-skill" || warn "taste-skill failed"
fi
echo ""

# ── 6. Claude plugins ────────────────────────────────────────────────────────
echo "6.  Claude plugins (code-review, code-simplifier, skill-creator, claude-md-management, security-guidance)"
if ! check_cmd claude; then
  warn "claude CLI not found — run these manually:"
  warn "  claude plugin marketplace add anthropics/claude-plugins-official"
  warn "  claude plugin install code-review@claude-plugins-official"
  warn "  claude plugin install code-simplifier@claude-plugins-official"
  warn "  claude plugin install skill-creator@claude-plugins-official"
  warn "  claude plugin install claude-md-management@claude-plugins-official"
  warn "  claude plugin install security-guidance@claude-plugins-official"
else
  info "Registering claude-plugins-official marketplace..."
  claude plugin marketplace add anthropics/claude-plugins-official \
    && ok "marketplace registered" \
    || warn "marketplace add failed — may already be registered"

  info "Refreshing claude-plugins-official marketplace..."
  claude plugin marketplace update claude-plugins-official \
    && ok "marketplace refreshed" \
    || warn "marketplace refresh failed — installs below may also fail"

  for plugin in \
    code-review@claude-plugins-official \
    code-simplifier@claude-plugins-official \
    skill-creator@claude-plugins-official \
    claude-md-management@claude-plugins-official \
    security-guidance@claude-plugins-official
  do
    info "Installing $plugin..."
    claude plugin install "$plugin" && ok "$plugin installed" || warn "$plugin install failed"
  done
fi
echo ""

# ── 7. LSP plugins ───────────────────────────────────────────────────────────
echo "7.  LSP plugins (clangd, gopls, jdtls, kotlin, rust-analyzer, typescript)"
if ! check_cmd claude; then
  warn "claude CLI not found — run these manually:"
  warn "  claude plugin install clangd-lsp@claude-plugins-official"
  warn "  claude plugin install gopls-lsp@claude-plugins-official"
  warn "  claude plugin install jdtls-lsp@claude-plugins-official"
  warn "  claude plugin install kotlin-lsp@claude-plugins-official"
  warn "  claude plugin install rust-analyzer-lsp@claude-plugins-official"
  warn "  claude plugin install typescript-lsp@claude-plugins-official"
else
  for plugin in \
    clangd-lsp@claude-plugins-official \
    gopls-lsp@claude-plugins-official \
    jdtls-lsp@claude-plugins-official \
    kotlin-lsp@claude-plugins-official \
    rust-analyzer-lsp@claude-plugins-official \
    typescript-lsp@claude-plugins-official
  do
    info "Installing $plugin..."
    claude plugin install "$plugin" && ok "$plugin installed" || warn "$plugin install failed"
  done
fi
echo ""

# ── 8. VoiceMode ─────────────────────────────────────────────────────────────
echo "8.  VoiceMode"
if ! check_cmd claude; then
  warn "claude CLI not found — run VoiceMode steps manually inside Claude Code"
else
  info "Adding VoiceMode marketplace..."
  claude plugin marketplace add mbailey/voicemode && ok "marketplace added" || warn "marketplace add failed"

  info "Installing VoiceMode plugin..."
  claude plugin install voicemode@voicemode && ok "voicemode plugin installed" || warn "plugin install failed"
fi
echo ""

# ── 9. Self-install: private-ai-harness plugin ──────────────────────────────
echo "9. private-ai-harness plugin (skills + agents)"

# Resolve repo root relative to this script — works from any CWD
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
info "Repo root: $REPO_ROOT"

if ! check_cmd claude; then
  warn "claude CLI not found — run these manually inside Claude Code:"
  warn "  /plugin marketplace add $REPO_ROOT"
  warn "  /plugin install private-ai-harness@private-ai-harness --scope user"
  warn "  /reload-plugins"
else
  info "Adding private-ai-harness as marketplace..."
  claude plugin marketplace add "$REPO_ROOT" \
    && ok "marketplace registered" \
    || warn "marketplace add failed — may already be registered"

  info "Installing private-ai-harness plugin (user scope)..."
  claude plugin install private-ai-harness@private-ai-harness --scope user \
    && ok "private-ai-harness installed" \
    || warn "install failed — check output above"
fi
echo ""

# ── 10. Caveman mode — global CLAUDE.md ──────────────────────────────────────
echo "10. Caveman mode (global CLAUDE.md)"

GLOBAL_CLAUDE_MD="$HOME/.claude/CLAUDE.md"
CAVEMAN_MARKER="## Caveman Mode"

if grep -q "$CAVEMAN_MARKER" "$GLOBAL_CLAUDE_MD" 2>/dev/null; then
  ok "caveman block already present in $GLOBAL_CLAUDE_MD"
else
  cat >> "$GLOBAL_CLAUDE_MD" <<EOF

## Caveman Mode

**ALWAYS active. Every session. Every response.**

@$REPO_ROOT/skills/caveman/SKILL.md

Default level: **full**. Active unless user says "stop caveman" or "normal mode".
EOF
  ok "caveman block added to $GLOBAL_CLAUDE_MD"
fi
echo ""

# ── 11. Commit discipline — global CLAUDE.md ─────────────────────────────────
echo "11. Commit discipline (global CLAUDE.md)"

COMMIT_DISCIPLINE_MARKER="## Commit Discipline"

if grep -q "$COMMIT_DISCIPLINE_MARKER" "$GLOBAL_CLAUDE_MD" 2>/dev/null; then
  ok "commit discipline block already present in $GLOBAL_CLAUDE_MD"
else
  cat >> "$GLOBAL_CLAUDE_MD" <<EOF

## Commit Discipline

**ALWAYS follow when writing commit messages.**

@$REPO_ROOT/skills/commit-discipline/SKILL.md
EOF
  ok "commit discipline block added to $GLOBAL_CLAUDE_MD"
fi
echo ""

# ── 12. Development workflow — global CLAUDE.md ─────────────────────────────
echo "12. Development workflow (global CLAUDE.md)"

WORKFLOW_MARKER="## Development Workflow"

if grep -q "$WORKFLOW_MARKER" "$GLOBAL_CLAUDE_MD" 2>/dev/null; then
  ok "workflow block already present in $GLOBAL_CLAUDE_MD"
else
  # Insert before CODEGRAPH_START if present, otherwise append
  if grep -q "<!-- CODEGRAPH_START -->" "$GLOBAL_CLAUDE_MD" 2>/dev/null; then
    sed -i '' "s|<!-- CODEGRAPH_START -->|## Development Workflow\n\n**ALWAYS follow for any feature, fix, or spec work. Mandatory, not suggestions.**\n\n@$REPO_ROOT/skills/workflow/SKILL.md\n\n<!-- CODEGRAPH_START -->|" "$GLOBAL_CLAUDE_MD"
  else
    cat >> "$GLOBAL_CLAUDE_MD" <<EOF

## Development Workflow

**ALWAYS follow for any feature, fix, or spec work. Mandatory, not suggestions.**

@$REPO_ROOT/skills/workflow/SKILL.md
EOF
  fi
  ok "workflow block added to $GLOBAL_CLAUDE_MD"
fi
echo ""

# ── 13. commit-msg git hook ──────────────────────────────────────────────────
echo "13. commit-msg hook"

# Install into the repo containing this script (the harness itself)
HOOK_TARGET="$REPO_ROOT/.git/hooks/commit-msg"
HOOK_SOURCE="$REPO_ROOT/scripts/commit-msg.sh"

if [[ ! -f "$HOOK_SOURCE" ]]; then
  warn "scripts/commit-msg.sh not found — skipping hook install"
elif [[ ! -d "$REPO_ROOT/.git" ]]; then
  warn "$REPO_ROOT is not a git repo — skipping hook install"
else
  chmod +x "$HOOK_SOURCE"
  ln -sf "$HOOK_SOURCE" "$HOOK_TARGET"
  ok "commit-msg hook installed → $HOOK_TARGET"
fi

# Also offer to install into the current working directory's repo if different
CWD_GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -n "$CWD_GIT_ROOT" && "$CWD_GIT_ROOT" != "$REPO_ROOT" ]]; then
  CWD_HOOK="$CWD_GIT_ROOT/.git/hooks/commit-msg"
  info "Also installing hook into current project: $CWD_GIT_ROOT"
  ln -sf "$HOOK_SOURCE" "$CWD_HOOK" \
    && ok "commit-msg hook installed → $CWD_HOOK" \
    || warn "hook install failed for $CWD_GIT_ROOT"
fi
echo ""

echo "═══════════════════════════════════════════"
echo -e "${YELLOW}MANUAL STEPS REQUIRED — run inside Claude Code:${RESET}"
echo ""
echo "  /voicemode:install    — installs VoiceMode CLI, FFmpeg, voice services"
echo "  /reload-plugins       — activates private-ai-harness skills + agents"
echo ""
echo "Verify plugin loaded:"
echo "  /plugin list"
echo ""
echo "Available after reload:"
echo "  Skills : /review, /pr-creator, /spec-quality-gate, /code-documentation"
echo "           /requesting-code-review, /finishing-a-development-branch ..."
echo "  Agents : pr-reviewer, spec-impl-reviewer, test-quality-reviewer,"
echo "           security-reviewer, full-project-reviewer"
echo "═══════════════════════════════════════════"
echo ""
ok "Done. Check any warnings above."
