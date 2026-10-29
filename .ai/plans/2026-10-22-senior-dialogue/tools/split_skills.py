#!/usr/bin/env python3
"""Move oversized sections out of SKILL.md files, verbatim, into references/.

Part of the Senior Dialogue (5.0.0) plan. Reads every source from the pinned
base commit (so it is deterministic regardless of working-tree state), writes
reference files, and rewrites the SKILL.md with a short pointer in place of the
moved text. Every marker must match exactly once or the script aborts without
writing anything.

Usage (from the repo root):
  python3 .ai/plans/2026-10-22-senior-dialogue/tools/split_skills.py --group split   [--check]
  python3 .ai/plans/2026-10-22-senior-dialogue/tools/split_skills.py --group engineer [--check]

Groups:
  split    — high-level-design, brainstorming, review (commit C1)
  engineer — engineer references only; SKILL.md itself is replaced by the payload (commit C5)
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

BASE = "f01a3ab"
HEADER = (
    "{title}\n\n"
    "Moved verbatim from `SKILL.md` (private-ai-harness 5.0.0) to keep the skill\n"
    "under the 20,000-byte limit Claude Code applies when it re-attaches skills\n"
    "after compaction. Read it at the step that points here.\n\n"
)


def base_text(path: str) -> str:
    return subprocess.run(
        ["git", "show", f"{BASE}:{path}"], check=True, capture_output=True, text=True
    ).stdout


def between(text: str, start: str, end: str | None) -> tuple[int, int]:
    if text.count(start) != 1:
        raise SystemExit(f"start marker matched {text.count(start)}x: {start[:70]!r}")
    i = text.index(start)
    if end is None:
        return i, len(text)
    if text.count(end) != 1:
        raise SystemExit(f"end marker matched {text.count(end)}x: {end[:70]!r}")
    j = text.index(end)
    if j <= i:
        raise SystemExit(f"end marker precedes start: {end[:70]!r}")
    return i, j


def plan_split() -> dict[str, str]:
    out: dict[str, str] = {}

    # high-level-design: HLD template and ADR format
    path = "skills/high-level-design/SKILL.md"
    text = base_text(path)
    a0, a1 = between(text, "## HLD Document Format\n", "## ADR Format\n")
    b0, b1 = between(text, "## ADR Format\n", "## What Requires an ADR\n")
    out["skills/high-level-design/references/hld-template.md"] = (
        HEADER.format(title="# HLD Document Template") + text[a0:a1].rstrip("-\n ") + "\n")
    out["skills/high-level-design/references/adr-format.md"] = (
        HEADER.format(title="# ADR Format and Rules") + text[b0:b1].rstrip("-\n ") + "\n")
    pointer = (
        "## HLD Document Format\n\n"
        "Save to: `.ai/YYYY-MM-DD-<feature-slug>/hld/hld-<feature-slug>.md`. Read\n"
        "`references/hld-template.md` before writing the HLD — its section structure\n"
        "(§1–§12) is what `hld-reviewer` checks and what the notes below refer to.\n\n"
        "---\n\n"
        "## ADR Format\n\n"
        "Save each to `wiki/architecture/ADR-NNN-<kebab-title>.md`. Read\n"
        "`references/adr-format.md` before writing an ADR — it holds the template and\n"
        "the immutability rules (supersede, never edit an Accepted ADR).\n\n"
        "---\n\n"
    )
    out[path] = text[:a0] + pointer + text[b1:]

    # brainstorming: the dot process-flow graph (the terminal-state rule stays)
    path = "skills/brainstorming/SKILL.md"
    text = base_text(path)
    c0, c1 = between(text, "```dot\ndigraph brainstorming {", "\n**The terminal state is invoking")
    out["skills/brainstorming/references/process-flow.md"] = (
        HEADER.format(title="# Brainstorming Process Flow") + text[c0:c1].strip() + "\n")
    out[path] = text[:c0] + (
        "The flow graph is in `references/process-flow.md`; the Checklist above walks\n"
        "the same flow in order.\n") + text[c1:]

    # review: direct chat triggers table
    path = "skills/review/SKILL.md"
    text = base_text(path)
    d0, d1 = between(text, "## Direct Chat Triggers\n", "## Integration Points\n")
    out["skills/review/references/direct-chat-triggers.md"] = (
        HEADER.format(title="# Direct Chat Triggers") +
        text[d0:d1].replace("## Direct Chat Triggers\n", "", 1).strip("-\n ") + "\n")
    out[path] = text[:d0] + (
        "## Direct Chat Triggers\n\n"
        "Natural-language phrasings that map to each `/review` subcommand are in\n"
        "`references/direct-chat-triggers.md`. Read it when a request names a review\n"
        "without a subcommand.\n\n"
        "---\n\n") + text[d1:]
    return out


def plan_engineer() -> dict[str, str]:
    out: dict[str, str] = {}
    text = base_text("skills/engineer/SKILL.md")
    e0, e1 = between(text, "- **Cost checkpoints:** before each numbered step",
                     "- **Domain overlay:**")
    f0, f1 = between(text, "## Cost ledger\n", None)
    out["skills/engineer/references/cost-ledger.md"] = (
        HEADER.format(title="# Cost Checkpoints, Circuit Breaker, and Ledger")
        + "## Checkpoint protocol (every lane)\n\n" + text[e0:e1].rstrip() + "\n\n"
        + text[f0:f1].rstrip() + "\n")
    g0, g1 = between(text, "- **Pattern propagation on review fixes:**",
                     "- **Spec+plan loop scales with lane:**")
    h0, h1 = between(text, "- **Proportionality Gate on every accepted finding:**",
                     "- **Confirmation required at:**")
    out["skills/engineer/references/review-discipline.md"] = (
        HEADER.format(title="# Review Discipline (every lane)")
        + text[g0:g1].rstrip() + "\n" + text[h0:h1].rstrip() + "\n")
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--group", required=True, choices=["split", "engineer"])
    parser.add_argument("--check", action="store_true", help="validate markers only")
    args = parser.parse_args()
    files = plan_split() if args.group == "split" else plan_engineer()
    for path, content in files.items():
        size = len(content.encode())
        print(f"{'would write' if args.check else 'wrote'} {path} ({size} bytes)")
        if path.endswith("/SKILL.md") and size >= 20000:
            raise SystemExit(f"{path} would still be {size} bytes (limit 20000)")
    if args.check:
        return 0
    for path, content in files.items():
        target = Path(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
