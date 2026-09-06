#!/usr/bin/env python3
"""Render private-ai-harness reviewer agents as opencode subagent Markdown files.

opencode auto-loads every *.md file under ~/.config/opencode/agents/ (and
per-project .opencode/agents/). Unlike Claude Code, its agent frontmatter
schema is `description`/`mode`/`model`/`permission` — not Claude's
`name`/`description`/`model` — and a subagent with no `model` inherits the
parent session's model the same way Codex's generated agents inherit the
active Codex model.

So these adapters mirror install-codex-agents.py and
scripts/codex-notify.sh (which maps Codex's single notify hook onto
hook-beep.sh event names):
  - keep `agents/*.md` (Claude frontmatter) as the single source of truth,
  - rewrite the "{Tier}-powered " description prefix to "{Tier}: " (so the
    description opens with the reviewer's label, never a ruled-out tier),
  - drop `model:` entirely — the subagent inherits the invoking primary
    agent's session model, so the parent's `*: allow` permissions and model
    flow through; an opus-rated reviewer running under a weaker parent
    session inherits that session's model but keeps the full review brief.
  - emit `mode: subagent` so the agent appears only to @-mention / Task tool.

The rendered subagent prompt body is the Claude source's prompt body verbatim
(with its "**Reviewer:** <name> (<Tier>)" line rewritten to "<name>: <Tier>"
so the tier signal stays accurate after inheritance). One source file, N host
adapters — reviewer prompts do not drift between Claude, Codex, and opencode.
"""

from __future__ import annotations

import argparse
import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class AgentDefinition:
    name: str
    description: str
    claude_model: str
    instructions: str

    @property
    def opencode_description(self) -> str:
        # e.g. "Opus-powered ..." -> "Opus: ..."
        # Strip the tier prefix if the description uses the canonical
        # "{Tier}-powered " stem; otherwise leave it untouched.
        prefix = f"{self.claude_model.title()}-powered "
        if self.description.startswith(prefix):
            return f"{self.claude_model.title()}: " + self.description[len(prefix) :]
        return self.description

    @property
    def opencode_instructions(self) -> str:
        # The tier appears only on the output-format "**Reviewer:** <name> (<Tier>)"
        # line. After inheritance the tier label would be inaccurate, so swap to
        # "<name>: <Tier>" (mirrors Codex's rewrite of the same marker).
        tier = self.claude_model.title()
        marker = f"**Reviewer:** {self.name} ({tier})"
        replacement = f"**Reviewer:** {self.name}: {tier}"
        if marker in self.instructions:
            return self.instructions.replace(marker, replacement)
        return self.instructions


def parse_frontmatter(path: Path) -> AgentDefinition:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise ValueError(f"{path}: missing opening YAML frontmatter delimiter")

    delimiter = text.find("\n---\n", 4)
    if delimiter == -1:
        raise ValueError(f"{path}: missing closing YAML frontmatter delimiter")

    metadata: dict[str, str] = {}
    for line in text[4:delimiter].splitlines():
        if not line.strip():
            continue
        key, separator, value = line.partition(":")
        if not separator:
            raise ValueError(f"{path}: unsupported frontmatter line: {line!r}")
        metadata[key.strip()] = value.strip()

    required = {"name", "description", "model"}
    missing = sorted(required - metadata.keys())
    if missing:
        raise ValueError(f"{path}: missing frontmatter fields: {', '.join(missing)}")

    name = metadata["name"]
    model = metadata["model"]
    if name != path.stem:
        raise ValueError(f"{path}: frontmatter name must match the filename")
    if model not in {"opus", "sonnet", "haiku"}:
        raise ValueError(f"{path}: unsupported Claude model tier {model!r}")

    instructions = text[delimiter + 5 :].strip()
    if not instructions:
        raise ValueError(f"{path}: agent instructions are empty")

    return AgentDefinition(
        name=name,
        description=metadata["description"],
        claude_model=model,
        instructions=instructions,
    )


def render_agent(agent: AgentDefinition) -> str:
    return "\n".join(
        (
            "---",
            f"description: {agent.opencode_description}",
            "mode: subagent",
            "---",
            "",
            agent.opencode_instructions,
            "",
        )
    )


def parse_args() -> argparse.Namespace:
    repo_root = Path(__file__).resolve().parent.parent
    opencode_home = Path(
        os.environ.get("OPENCODE_CONFIG_DIR", Path.home() / ".config" / "opencode")
    )
    parser = argparse.ArgumentParser(
        description="Render private-ai-harness agents as opencode subagents."
    )
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=repo_root / "agents",
        help="Directory containing Claude-style Markdown agent definitions.",
    )
    parser.add_argument(
        "--dest-dir",
        type=Path,
        default=opencode_home / "agents",
        help="opencode subagent directory (default: $OPENCODE_CONFIG_DIR/agents).",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate and render in memory without writing files.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    paths = sorted(args.source_dir.glob("*.md"))
    if not paths:
        raise SystemExit(f"No agent definitions found in {args.source_dir}")

    rendered: list[tuple[AgentDefinition, str]] = []
    for path in paths:
        agent = parse_frontmatter(path)
        rendered.append((agent, render_agent(agent)))

    if args.check:
        print(f"Validated {len(rendered)} opencode agent adapters")
        return

    args.dest_dir.mkdir(parents=True, exist_ok=True)
    for agent, content in rendered:
        destination = args.dest_dir / f"private-ai-harness-{agent.name}.md"
        temporary = destination.with_suffix(".md.tmp")
        temporary.write_text(content, encoding="utf-8")
        temporary.replace(destination)

    print(f"Installed {len(rendered)} opencode agents in {args.dest_dir}")


if __name__ == "__main__":
    main()