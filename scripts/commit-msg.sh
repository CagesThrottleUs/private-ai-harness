#!/usr/bin/env bash
# commit-msg hook — enforces micro-commit discipline and WHY body.
# Character limits are guidelines (warn, don't block).
# Hard blocks: no WHY body on multi-file commits, pure file-list body,
#   subject >72 chars, body lines >80 chars, bad Conventional Commits format.
# Install: ln -sf ~/.claude/scripts/commit-msg.sh .git/hooks/commit-msg
# Do not use set -e or pipefail — grep returning 1 (no match) must not abort the hook.

COMMIT_MSG_FILE="$1"
MSG=$(cat "$COMMIT_MSG_FILE")

# Strip comment lines
STRIPPED=$(echo "$MSG" | grep -v '^#' || true)

SUBJECT=$(echo "$STRIPPED" | head -1)
SUBJECT_LEN=${#SUBJECT}

RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

ERRORS=0

# ── 1. Subject length ──────────────────────────────────────────────────────────
if [ "$SUBJECT_LEN" -gt 72 ]; then
  echo -e "${RED}✖ subject is ${SUBJECT_LEN} chars — hard limit is 72.${RESET}"
  echo "  $SUBJECT"
  ERRORS=$((ERRORS + 1))
elif [ "$SUBJECT_LEN" -gt 50 ]; then
  echo -e "${YELLOW}⚠ subject is ${SUBJECT_LEN} chars — aim for ≤50 (hard limit 72).${RESET}"
  echo "  $SUBJECT"
fi

# ── 2. Conventional Commits format ────────────────────────────────────────────
CC_PATTERN='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9_-]+\))?!?: [a-z]'
if ! echo "$SUBJECT" | grep -qE "$CC_PATTERN"; then
  echo -e "${RED}✖ subject does not follow Conventional Commits format.${RESET}"
  echo "  Got:      $SUBJECT"
  echo "  Expected: type(scope): imperative description (lowercase start)"
  echo "  Types:    build chore ci docs feat fix perf refactor revert style test"
  ERRORS=$((ERRORS + 1))
fi

# ── 3. Subject must not end with a period ─────────────────────────────────────
if echo "$SUBJECT" | grep -q '\.$'; then
  echo -e "${RED}✖ subject ends with a period.${RESET}"
  ERRORS=$((ERRORS + 1))
fi

# ── 4. Body line length ────────────────────────────────────────────────────────
LINE_NUM=0
while IFS= read -r line; do
  LINE_NUM=$((LINE_NUM + 1))
  [ "$LINE_NUM" -le 2 ] && continue
  [[ "$line" == \#* ]] && continue
  LINE_LEN=${#line}
  if [ "$LINE_LEN" -gt 80 ]; then
    echo -e "${RED}✖ body line $LINE_NUM is ${LINE_LEN} chars — hard limit is 80.${RESET}"
    echo "  $line"
    ERRORS=$((ERRORS + 1))
  elif [ "$LINE_LEN" -gt 72 ]; then
    echo -e "${YELLOW}⚠ body line $LINE_NUM is ${LINE_LEN} chars — aim for ≤72.${RESET}"
  fi
done <<< "$STRIPPED"

# ── 5. Blank line between subject and body ────────────────────────────────────
SECOND_LINE=$(echo "$STRIPPED" | sed -n '2p')
BODY_LINE=$(echo "$STRIPPED" | sed -n '3p')
if [ -n "$BODY_LINE" ] && [ -n "$(echo "$SECOND_LINE" | tr -d '[:space:]')" ]; then
  echo -e "${RED}✖ missing blank line between subject and body.${RESET}"
  ERRORS=$((ERRORS + 1))
fi

# ── 6. HARD: body must explain WHY ────────────────────────────────────────────
BODY=$(echo "$STRIPPED" | tail -n +3 | grep -v '^$' | grep -v '^#' || true)
BODY_LINE_COUNT=$(echo "$BODY" | grep -c '' | tr -d ' ' || echo 0)
BODY_LINE_COUNT=${BODY_LINE_COUNT:-0}

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
STAGED_FILES=${STAGED_FILES:-0}

if [ "$STAGED_FILES" -gt 10 ]; then
  echo -e "${YELLOW}⚠ ${STAGED_FILES} files staged — consider splitting into smaller commits.${RESET}"
  echo "  Each commit should represent one logical change."
  echo -e "${CYAN}  → AI agent: stage only files for this one logical change, then commit.${RESET}"
fi

if [ "$STAGED_FILES" -gt 1 ] && [ "$BODY_LINE_COUNT" -eq 0 ]; then
  echo -e "${RED}✖ body required — commit touches ${STAGED_FILES} files.${RESET}"
  echo "  Body must explain WHY — what was wrong, why this approach?"
  echo "  Single-file commits may omit the body."
  echo -e "${CYAN}  → AI agent: write 2–3 sentences: what was the problem? why this fix?${RESET}"
  echo "    Do NOT list file names — the diff already shows what changed."
  ERRORS=$((ERRORS + 1))
fi

if [ "$BODY_LINE_COUNT" -gt 0 ]; then
  FILE_LIST_LINES=$(echo "$BODY" | grep -E '^\s*[-*]\s+[a-zA-Z0-9_./]+(\.[a-z]+)?(\s+[-—].*)?$' | wc -l | tr -d ' ')
  FILE_LIST_LINES=${FILE_LIST_LINES:-0}
  if [ "$FILE_LIST_LINES" -gt 0 ] && [ "$FILE_LIST_LINES" -ge "$BODY_LINE_COUNT" ]; then
    echo -e "${RED}✖ body is a file list — explain WHY, not what files changed.${RESET}"
    echo "  Body = motivation: what was broken, why this fix, why this approach."
    echo -e "${CYAN}  → AI agent: delete file list, replace with reason change was needed.${RESET}"
    ERRORS=$((ERRORS + 1))
  fi

  FILE_NAME_MENTIONS=$(echo "$BODY" | grep -E '[a-z_]+\.(py|md|yml|yaml|sh|json|toml|ts|js)' | wc -l | tr -d ' ')
  FILE_NAME_MENTIONS=${FILE_NAME_MENTIONS:-0}
  if [ "$FILE_NAME_MENTIONS" -gt 2 ]; then
    echo -e "${YELLOW}⚠ body mentions ${FILE_NAME_MENTIONS} filenames — explain WHY not WHERE.${RESET}"
    echo -e "${CYAN}  → AI agent: remove filenames, keep the reasoning.${RESET}"
  fi
fi

# ── Result ─────────────────────────────────────────────────────────────────────
if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo -e "${RED}Commit rejected ($ERRORS error(s)). Fix and retry.${RESET}"
  echo ""
  echo "  Hard rules:"
  echo "    subject ≤72 chars (aim ≤50), body lines ≤80 (aim ≤72)"
  echo "    type(scope): imperative — Conventional Commits"
  echo "    body required for >1 file; body explains WHY not what"
  echo ""
  echo "  Example body (WHY):"
  echo "    Repeated violations needed automation. Hook blocks commits"
  echo "    where body is absent or is a file list."
  exit 1
fi
