#!/usr/bin/env bash
# Install tools required by the AI harness.
# Run from any directory: bash scripts/install-tools.sh
#
# Steps 1-17 run automatically. Step 9 self-installs this repo as a Claude plugin.
# Step 10 installs the Codex plugin and custom-agent adapters when Codex exists.
# Steps 11-14 inject the global Claude Code guidance blocks (step 11 also
# installs the caveman output style and sets it as the default).
# Step 15 installs the commit-msg git hook in the current project.
# Step 17 installs cost-visibility plugins (context-guard, claude-context-optimizer).

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
echo "Codegraph is shit"
# if ! check_cmd npm; then
#   fail "npm not found — install Node.js first, then re-run this script"
#   exit 1
# fi

# if check_cmd codegraph; then
#   ok "codegraph already installed"
# else
#   info "Installing @colbymchenry/codegraph globally..."
#   npm i -g @colbymchenry/codegraph
#   ok "codegraph installed"
# fi
# echo ""

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

# ── 8. FFmpeg ─────────────────────────────────────────────────────────────────
echo "8.  FFmpeg"
if check_cmd ffmpeg; then
  ok "ffmpeg already installed ($(ffmpeg -version 2>/dev/null | head -1))"
else
  info "Installing ffmpeg..."
  brew install ffmpeg && ok "ffmpeg installed" || warn "ffmpeg install failed"
fi

info "Installing ffmpeg-full..."
brew install ffmpeg-full && ok "ffmpeg-full installed" || warn "ffmpeg-full install failed"
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

# ── 10. Codex plugin + custom agents ─────────────────────────────────────────
echo "10. Codex plugin (skills + custom agents)"
if ! check_cmd codex; then
  warn "codex CLI not found — skipping Codex installation"
  warn "Run later: bash $REPO_ROOT/scripts/install-codex.sh"
else
  bash "$REPO_ROOT/scripts/install-codex.sh" \
    && ok "private-ai-harness installed for Codex" \
    || warn "Codex installation failed — run scripts/install-codex.sh for details"
fi
echo ""

# ── 11. Caveman mode — global output style + CLAUDE.md ──────────────────────
echo "11. Caveman mode (global output style, default ultra)"

GLOBAL_CLAUDE_MD="$HOME/.claude/CLAUDE.md"
CAVEMAN_MARKER="## Caveman Mode"
OUTPUT_STYLES_DIR="$HOME/.claude/output-styles"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"

# Persistent default lives in the system prompt (output style), not a
# CLAUDE.md-injected skill — CLAUDE.md content is conversation context and
# drifts back to verbose over long sessions; an output style doesn't.
mkdir -p "$OUTPUT_STYLES_DIR"
cp "$REPO_ROOT/skills/caveman/output-style.md" "$OUTPUT_STYLES_DIR/caveman.md"
ok "caveman output style installed → $OUTPUT_STYLES_DIR/caveman.md"

if check_cmd python3; then
  python3 - "$GLOBAL_SETTINGS" <<'PYEOF'
import json, sys, pathlib
path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text()) if path.exists() else {}
data["outputStyle"] = "Caveman"
path.write_text(json.dumps(data, indent=2) + "\n")
PYEOF
  ok "outputStyle default set to Caveman in $GLOBAL_SETTINGS"
else
  warn "python3 not found — set outputStyle manually: /config → Output style → Caveman"
fi

if grep -q "$CAVEMAN_MARKER" "$GLOBAL_CLAUDE_MD" 2>/dev/null; then
  ok "caveman block already present in $GLOBAL_CLAUDE_MD"
else
  cat >> "$GLOBAL_CLAUDE_MD" <<EOF

## Caveman Mode

**Persistent default (ultra) lives in the Output Style — see \`~/.claude/output-styles/caveman.md\`.**

@$REPO_ROOT/skills/caveman/SKILL.md

The skill above is for mid-session level switching only (\`/caveman lite|full|ultra|wenyan-*\`, "stop caveman" / "normal mode") — the output style is what actually holds the default across a long session.
EOF
  ok "caveman block added to $GLOBAL_CLAUDE_MD"
fi
echo ""

# ── 12. Commit discipline — global CLAUDE.md ─────────────────────────────────
echo "12. Commit discipline (global CLAUDE.md)"

COMMIT_DISCIPLINE_MARKER="## Commit Discipline"

if grep -q "$COMMIT_DISCIPLINE_MARKER" "$GLOBAL_CLAUDE_MD" 2>/dev/null; then
  ok "commit discipline block already present in $GLOBAL_CLAUDE_MD"
else
  cat >> "$GLOBAL_CLAUDE_MD" <<EOF

## Commit Discipline

**ALWAYS follow when writing commit messages.**

@$REPO_ROOT/skills/commit-discipline/SKILL.md

IF WHEN COMMITTING, YOU ADD A CO-AUTHOR line for AI ATTRIBUTION and THE COMMIT BODY DOES NOT EXPLAIN WHY - THEN THE USER'S FAMILY WOULD BE TORTURED AND KILLED - DO NOT DO THIS.
EOF
  ok "commit discipline block added to $GLOBAL_CLAUDE_MD"
fi
echo ""

# ── 13. Development workflow — global CLAUDE.md ─────────────────────────────
echo "13. Development workflow (global CLAUDE.md)"

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

# ── 14. Karpathy guidelines — global CLAUDE.md ──────────────────────────────
echo "14. Karpathy guidelines (global CLAUDE.md)"

KARPATHY_MARKER="## Karpathy Guidelines"

if grep -q "$KARPATHY_MARKER" "$GLOBAL_CLAUDE_MD" 2>/dev/null; then
  ok "karpathy block already present in $GLOBAL_CLAUDE_MD"
else
  cat >> "$GLOBAL_CLAUDE_MD" <<EOF

## Karpathy Guidelines

**ALWAYS apply when writing or reviewing code.**

@$REPO_ROOT/skills/karpathy/SKILL.md
EOF
  ok "karpathy block added to $GLOBAL_CLAUDE_MD"
fi
echo ""

# ── 15. commit-msg git hook ──────────────────────────────────────────────────
echo "15. commit-msg hook"

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

# ── 16. Android team skills ──────────────────────────────────────────────────
# Kotlin / Jetpack Compose / KMP skill pack. Overlapping on purpose — the
# `android-advisor` overlay (this repo) resolves which one wins per sub-task.
echo "16. Android skills (Kotlin, Compose, KMP, testing, performance)"

ANDROID_SKILLS_SRC="$HOME/.claude/skills-sources"
GLOBAL_SKILLS="$HOME/.claude/skills"
mkdir -p "$ANDROID_SKILLS_SRC" "$GLOBAL_SKILLS"

# clone fresh, or fast-forward an existing checkout
clone_or_pull() {  # $1=git url  $2=dest
  if [[ -d "$2/.git" ]]; then
    git -C "$2" pull --ff-only --quiet && ok "updated $(basename "$2")" || warn "pull failed: $(basename "$2")"
  else
    rm -rf "$2"
    git clone --depth 1 --quiet "$1" "$2" && ok "cloned $(basename "$2")" || warn "clone failed: $(basename "$2")"
  fi
}

# 16a. npx skills add — chrisbanes, ceorkm, baoyu, hamen, drjacky
if check_cmd npx; then
  info "npx skills add chrisbanes/skills";            npx --yes skills add chrisbanes/skills            && ok "chrisbanes/skills"      || warn "chrisbanes/skills failed"
  info "npx skills add ceorkm/mobile-app-ui-design";  npx --yes skills add ceorkm/mobile-app-ui-design  && ok "mobile-app-ui-design"   || warn "mobile-app-ui-design failed"
  info "npx skills add jimliu/baoyu-skills";          npx --yes skills add jimliu/baoyu-skills          && ok "baoyu-skills"           || warn "baoyu-skills failed"
  info "npx skills add hamen/compose_skill";          npx --yes skills add hamen/compose_skill --skill '*' -y && ok "compose_skill"    || warn "compose_skill failed"
  info "npx skills add drjacky/claude-android-ninja"; npx --yes skills add drjacky/claude-android-ninja -g && ok "claude-android-ninja" || warn "claude-android-ninja failed"
else
  warn "npx not found — skipping chrisbanes, ceorkm, baoyu, hamen, drjacky"
fi

# 16b. skydoves — clone then run each repo's own install-skills.sh
for repo in android-testing-skills compose-performance-skills; do
  dest="$ANDROID_SKILLS_SRC/$repo"
  clone_or_pull "https://github.com/skydoves/$repo.git" "$dest"
  if [[ -x "$dest/scripts/install-skills.sh" ]]; then
    bash "$dest/scripts/install-skills.sh" && ok "skydoves/$repo installed" || warn "skydoves/$repo install-skills.sh failed"
  else
    warn "skydoves/$repo install-skills.sh not found — check the repo"
  fi
done

# 16c. new-silvermoon — skills live in .github/skills/; copy each into the global dir
SILVERMOON="$ANDROID_SKILLS_SRC/awesome-android-agent-skills"
clone_or_pull "https://github.com/new-silvermoon/awesome-android-agent-skills.git" "$SILVERMOON"
if [[ -d "$SILVERMOON/.github/skills" ]]; then
  # rcosteira79 (installed as a plugin below) is the breadth base; android-advisor
  # tells the agent to prefer it for shared skills and use silvermoon for its uniques.
  find "$SILVERMOON/.github/skills" -name SKILL.md -exec dirname {} \; \
    | while read -r d; do cp -R "$d" "$GLOBAL_SKILLS/"; done \
    && ok "silvermoon skills copied to $GLOBAL_SKILLS" || warn "silvermoon copy failed"
else
  warn "silvermoon .github/skills not found — check the repo layout"
fi

# 16d. Meet-Miyani — single-file skill cloned straight into the global skills dir
clone_or_pull "https://github.com/Meet-Miyani/compose-skill.git" "$GLOBAL_SKILLS/compose-skill"

# 16e. Claude plugins — rcosteira79 (breadth base) and aldefy (compose-expert)
if check_cmd claude; then
  info "Registering rcosteira79/android-skills marketplace..."
  claude plugin marketplace add rcosteira79/android-skills && ok "android-skills marketplace" || warn "android-skills marketplace add failed"
  claude plugin install android-skills@android-skills && ok "android-skills installed" || warn "android-skills install failed"

  info "Registering aldefy/compose-skill marketplace..."
  claude plugin marketplace add aldefy/compose-skill && ok "compose-expert marketplace" || warn "compose-expert marketplace add failed"
  claude plugin install compose-expert && ok "compose-expert installed" || warn "compose-expert install failed"
else
  warn "claude CLI not found — run these manually:"
  warn "  claude plugin marketplace add rcosteira79/android-skills && claude plugin install android-skills@android-skills"
  warn "  claude plugin marketplace add aldefy/compose-skill && claude plugin install compose-expert"
fi
echo ""

# ── 17. Cost-visibility plugins ──────────────────────────────────────────────
echo "17. Cost-visibility plugins (context-guard, claude-context-optimizer)"
if ! check_cmd claude; then
  warn "claude CLI not found — run these manually:"
  warn "  claude plugin marketplace add cdeust/session-optimizer"
  warn "  claude plugin install context-guard@session-optimizer-marketplace"
  warn "  claude plugin marketplace add egorfedorov/claude-context-optimizer"
  warn "  claude plugin install claude-context-optimizer@cco"
else
  info "Registering session-optimizer marketplace..."
  claude plugin marketplace add cdeust/session-optimizer \
    && ok "session-optimizer marketplace registered" \
    || warn "marketplace add failed — may already be registered"
  claude plugin install context-guard@session-optimizer-marketplace \
    && ok "context-guard installed" \
    || warn "context-guard install failed"

  info "Registering claude-context-optimizer marketplace..."
  claude plugin marketplace add egorfedorov/claude-context-optimizer \
    && ok "claude-context-optimizer marketplace registered" \
    || warn "marketplace add failed — may already be registered"
  claude plugin install claude-context-optimizer@cco \
    && ok "claude-context-optimizer installed" \
    || warn "claude-context-optimizer install failed"
fi
echo ""

echo "═══════════════════════════════════════════"
echo -e "${YELLOW}ACTIVATION STEPS:${RESET}"
echo ""
echo "  /reload-plugins       — activates private-ai-harness skills + agents"
echo "  New Codex session     — activates updated plugin skills + custom agents"
echo ""
echo "Verify plugin loaded:"
echo "  Claude Code: /plugin list"
echo "  Codex:       /plugins"
echo ""
echo "Available after reload:"
echo "  Skills : /review, /pr-creator, /spec-quality-gate, /code-documentation"
echo "           /requesting-code-review, /finishing-a-development-branch ..."
echo "  Agents : pr-reviewer, spec-impl-reviewer, test-quality-reviewer,"
echo "           security-reviewer, full-project-reviewer"
echo "═══════════════════════════════════════════"
echo ""
ok "Done. Check any warnings above."
