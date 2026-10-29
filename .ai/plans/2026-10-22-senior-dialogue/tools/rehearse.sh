#!/usr/bin/env bash
# rehearse.sh — dry-run the entire plan in a throwaway clone; never touches this checkout.
#
# Usage (from the repo root):  bash .ai/plans/2026-10-22-senior-dialogue/tools/rehearse.sh
# Clones the repo at the pinned base commit into a temp dir, copies this plan in,
# runs implement.sh C1..C5 with real commits (commit-msg hook installed), then
# validate.py --final. Exit 0 = the plan applies cleanly and passes every check.
set -o errexit -o nounset -o pipefail

BASE="f01a3ab"
PLAN_REL=".ai/plans/2026-10-22-senior-dialogue"
SRC="$(pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --quiet --no-hardlinks "$SRC" "$TMP/repo"
cd "$TMP/repo"
git checkout --quiet "$BASE"
git switch --quiet -c rehearsal
mkdir -p "$(dirname "$PLAN_REL")"
cp -R "$SRC/$PLAN_REL" "$PLAN_REL"
cp scripts/commit-msg.sh .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg
git config user.name "rehearsal" && git config user.email "rehearsal@example.invalid"

for step in C1 C2 C3 C4 C5; do
  echo "── $step"
  if ! bash "$PLAN_REL/tools/implement.sh" "$step" > "$TMP/$step.log" 2>&1; then
    cat "$TMP/$step.log" >&2
    echo "step $step FAILED" >&2
    exit 1
  fi
  tail -n 2 "$TMP/$step.log"
  git commit --quiet -F "$PLAN_REL/tools/commit-messages/$step.txt"
  if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
    echo "uncommitted tracked changes after $step:" >&2
    git status --short --untracked-files=no >&2
    exit 1
  fi
done

echo "── commits"
git log --oneline "$BASE"..HEAD
echo "── validate --final"
python3 "$PLAN_REL/tools/validate.py" --final
