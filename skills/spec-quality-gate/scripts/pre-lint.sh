#!/usr/bin/env bash
# pre-lint.sh — deterministic, zero-LLM-cost pre-check for a spec file.
# Mirrors the mechanical Section 1 (format) checks that agents/spec-quality-reviewer.md
# runs first, plus the Section 4 set-level placeholder check. If this script fails,
# the Opus reviewer will fail on the identical grounds — fix here first and skip
# paying for a review round-trip on a purely mechanical defect.
# Does NOT replace the agent: judgment checks (2a/2b/2c/2d, 3a-3d, north star)
# still require spec-quality-reviewer.
# Compatible with bash 3.2 (macOS default) — no mapfile/readarray/associative arrays.
# Usage: pre-lint.sh <spec-file>

SPEC_FILE="$1"

if [[ -z "$SPEC_FILE" ]]; then
  echo "Usage: pre-lint.sh <spec-file>"
  exit 2
fi
if [[ ! -f "$SPEC_FILE" ]]; then
  echo "spec file not found: $SPEC_FILE"
  exit 2
fi

RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

ERRORS=0
WARNINGS=0

fail() { echo -e "${RED}✖ [$1]${RESET} $2"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "${YELLOW}⚠ [$1]${RESET} $2"; WARNINGS=$((WARNINGS + 1)); }

# ── 1a. Frontmatter ──────────────────────────────────────────────────────────
if [[ "$(head -1 "$SPEC_FILE")" != "---" ]]; then
  fail "1a" "file must start with a YAML frontmatter block (---)"
else
  FRONTMATTER=$(awk '/^---$/{c++; next} c==1' "$SPEC_FILE")
  echo "$FRONTMATTER" | grep -qE '^spec_id:[[:space:]]*SPEC-[0-9]+' || fail "1a" "frontmatter missing 'spec_id: SPEC-N'"
  echo "$FRONTMATTER" | grep -qE '^title:[[:space:]]*[^[:space:]]' || fail "1a" "frontmatter missing 'title:'"
  echo "$FRONTMATTER" | grep -qE '^status:[[:space:]]*(draft|approved)' || fail "1a" "frontmatter missing 'status: draft|approved'"
fi

# ── 1b. REQ-NNN sequential, no gaps/dupes ───────────────────────────────────
REQ_NUMS=()
while IFS= read -r n; do
  [[ -n "$n" ]] && REQ_NUMS+=("$n")
done < <(grep -oE '^### REQ-[0-9]+' "$SPEC_FILE" | grep -oE '[0-9]+')

if [[ ${#REQ_NUMS[@]} -eq 0 ]]; then
  fail "1b" "no '### REQ-NNN:' blocks found"
else
  DUPES=$(printf '%s\n' "${REQ_NUMS[@]}" | sort | uniq -d)
  if [[ -n "$DUPES" ]]; then
    fail "1b" "duplicate REQ numbers: $(echo "$DUPES" | tr '\n' ' ')"
  fi
  SORTED=($(printf '%s\n' "${REQ_NUMS[@]}" | sort -n -u))
  EXPECT=1
  for n in "${SORTED[@]}"; do
    n_val=$((10#$n))
    if [[ "$n_val" -ne "$EXPECT" ]]; then
      fail "1b" "REQ numbering gap or non-sequential start: expected REQ-$(printf '%03d' "$EXPECT"), found REQ-$n"
      break
    fi
    EXPECT=$((EXPECT + 1))
  done
fi

# ── 1c. REQ block completeness ───────────────────────────────────────────────
while IFS='|' read -r reqname complete; do
  [[ -z "$reqname" ]] && continue
  if [[ "$complete" != "1" ]]; then
    fail "1c" "$reqname missing one of Statement/Acceptance Criteria/Dependencies/Test Cases"
  fi
done < <(awk '
  /^### REQ-[0-9]+:/ {
    if (name != "") print name "|" (stmt && ac && dep && tc ? "1" : "0")
    name = $0; stmt=0; ac=0; dep=0; tc=0; next
  }
  /^\*\*Statement:\*\*/ { stmt=1 }
  /^\*\*Acceptance Criteria:\*\*/ { ac=1 }
  /^\*\*Dependencies:\*\*/ { dep=1 }
  /^\*\*Test Cases:\*\*/ { tc=1 }
  END { if (name != "") print name "|" (stmt && ac && dep && tc ? "1" : "0") }
' "$SPEC_FILE")

# ── 1d. Test Coverage Matrix consistency ─────────────────────────────────────
MATRIX_SECTION=$(awk '/^## Test Coverage Matrix/{f=1; next} /^## /{if(f) exit} f' "$SPEC_FILE")
if [[ -z "$(echo "$MATRIX_SECTION" | tr -d '[:space:]')" ]]; then
  fail "1d" "'## Test Coverage Matrix' section missing or empty"
else
  BEFORE_MATRIX=$(awk '/^## Test Coverage Matrix/{exit} {print}' "$SPEC_FILE")
  DECLARED_TCS=$(echo "$BEFORE_MATRIX" | grep -oE 'TC-REQ[0-9]+-[0-9]+' | sort -u)
  MATRIX_TCS=$(echo "$MATRIX_SECTION" | grep -oE 'TC-REQ[0-9]+-[0-9]+' | sort -u)
  MISSING_FROM_MATRIX=$(comm -23 <(echo -n "$DECLARED_TCS") <(echo -n "$MATRIX_TCS"))
  MISSING_FROM_REQS=$(comm -13 <(echo -n "$DECLARED_TCS") <(echo -n "$MATRIX_TCS"))
  if [[ -n "$MISSING_FROM_MATRIX" ]]; then
    fail "1d" "TC(s) in REQ blocks but missing from Test Coverage Matrix: $(echo "$MISSING_FROM_MATRIX" | tr '\n' ' ')"
  fi
  if [[ -n "$MISSING_FROM_REQS" ]]; then
    fail "1d" "TC(s) in Test Coverage Matrix but not found in any REQ block: $(echo "$MISSING_FROM_REQS" | tr '\n' ' ')"
  fi
fi

# ── 1e. Out of Scope heading ──────────────────────────────────────────────────
OOS_SECTION=$(awk '/^## Out of Scope$/{f=1; next} /^## /{if(f) exit} f' "$SPEC_FILE")
if [[ -z "$(echo "$OOS_SECTION" | tr -d '[:space:]')" ]]; then
  fail "1e" "'## Out of Scope' section missing or empty (must be its own heading, not a bullet inside Scope)"
fi

# ── 1f. Non-Functional Requirements section ──────────────────────────────────
NFR_SECTION=$(awk '/^## Non-Functional Requirements/{f=1; next} /^## /{if(f) exit} f' "$SPEC_FILE")
if [[ -z "$(echo "$NFR_SECTION" | tr -d '[:space:]')" ]]; then
  fail "1f" "'## Non-Functional Requirements' section missing"
else
  if echo "$NFR_SECTION" | grep -qiE '\bTBD\b'; then
    fail "1f" "NFR section contains TBD — every cell needs a numeric target or explicit N/A with rationale"
  fi
  echo "$NFR_SECTION" | grep -qi 'Compliance' || fail "1f" "NFR Security table missing a Compliance row"
fi

# ── Section 4 set-level — residual placeholders anywhere in file ─────────────
while IFS=: read -r lineno match; do
  [[ -z "$lineno" ]] && continue
  fail "4" "line $lineno: residual placeholder '$match' — decide it or move to Out of Scope"
done < <(grep -noE 'TBD|TBC|TBX|\?\?\?|<placeholder>' "$SPEC_FILE")

echo
if [[ $ERRORS -gt 0 ]]; then
  echo -e "${RED}${ERRORS} format failure(s), ${WARNINGS} warning(s). Fix these before invoking spec-quality-reviewer — it will fail on the same grounds.${RESET}"
  exit 1
else
  echo -e "${CYAN}Pre-lint clean — Section 1 format checks pass. Safe to invoke spec-quality-reviewer for the judgment pass.${RESET}"
  exit 0
fi
