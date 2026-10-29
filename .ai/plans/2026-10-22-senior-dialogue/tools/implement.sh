#!/usr/bin/env bash
# implement.sh — apply one commit's worth of the Senior Dialogue (5.0.0) change.
#
# Usage (from the repo root):  bash .ai/plans/2026-10-22-senior-dialogue/tools/implement.sh C1
# Steps must run in order C1 → C5, each followed by its commit (see PLAN.md).
# The script stages exactly the files of that step and nothing else.
set -o errexit -o nounset -o pipefail

PLAN_DIR=".ai/plans/2026-10-22-senior-dialogue"
PAY="$PLAN_DIR/payloads"
TOOLS="$PLAN_DIR/tools"
STEP="${1:?usage: implement.sh C1|C2|C3|C4|C5}"

[[ -f AGENTS.md && -d skills && -d "$PLAN_DIR" ]] || { echo "run from the repo root" >&2; exit 2; }

copy() {  # copy payload path → same repo path
  mkdir -p "$(dirname "$1")"
  cp "$PAY/$1" "$1"
}

case "$STEP" in
  C1)
    python3 "$TOOLS/split_skills.py" --group split
    git add skills/high-level-design/SKILL.md skills/high-level-design/references \
            skills/brainstorming/SKILL.md skills/brainstorming/references/process-flow.md \
            skills/review/SKILL.md skills/review/references
    ;;
  C2)
    copy agents/test-scenario-reviewer.md
    python3 "$TOOLS/apply_patches.py" --group agent
    git add agents/test-scenario-reviewer.md AGENTS.md README.md skills/review/SKILL.md
    ;;
  C3)
    for f in SKILL.md references/agenda.md references/consent-protocol.md \
             references/decision-cards.md references/depth-scaling.md \
             references/systems-depth.md references/test-scenarios.md \
             scripts/dialogue-consent.py; do
      copy "skills/senior-dialogue/$f"
    done
    chmod +x skills/senior-dialogue/scripts/dialogue-consent.py
    python3 "$TOOLS/apply_patches.py" --group skill
    git add skills/senior-dialogue AGENTS.md README.md CLAUDE.md PHILOSOPHY.md
    ;;
  C4)
    copy hooks/dialogue-consent.json
    copy hooks/codex-dialogue-consent.json
    copy scripts/opencode-dialogue-consent-plugin.js
    python3 "$TOOLS/apply_patches.py" --group hooks
    git add hooks/dialogue-consent.json hooks/codex-dialogue-consent.json \
            scripts/opencode-dialogue-consent-plugin.js \
            .claude-plugin/plugin.json .codex-plugin/plugin.json \
            scripts/install-copilot.sh scripts/install-codex.sh scripts/install-opencode.sh \
            AGENTS.md README.md CLAUDE.md
    ;;
  C5)
    python3 "$TOOLS/split_skills.py" --group engineer
    copy skills/engineer/SKILL.md
    python3 "$TOOLS/apply_patches.py" --group engineer
    git add skills/engineer/SKILL.md skills/engineer/references \
            skills/brainstorming/SKILL.md skills/high-level-design/SKILL.md \
            skills/business-context-intake/SKILL.md skills/writing-plans/SKILL.md \
            skills/test-driven-development/SKILL.md \
            AGENTS.md README.md docs/engineer-skill-map.md \
            .claude-plugin/plugin.json .claude-plugin/marketplace.json .codex-plugin/plugin.json
    ;;
  *) echo "unknown step: $STEP" >&2; exit 2 ;;
esac

python3 "$TOOLS/validate.py" --quick
echo "step $STEP applied and staged; commit with: git commit -F $TOOLS/commit-messages/$STEP.txt"
