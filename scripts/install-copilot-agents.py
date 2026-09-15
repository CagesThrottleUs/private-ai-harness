#!/usr/bin/env python3
"""Install Claude-style harness agent definitions as GitHub Copilot Agent Skills."""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path


NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
MODEL_LABELS = {
    "opus": "opus",
    "sonnet": "sonnet",
    "haiku": "haiku",
}


@dataclass(frozen=True)
class AgentDefinition:
    name: str
    description: str
    claude_model: str
    instructions: str

    @property
    def copilot_instructions(self) -> str:
        return self.instructions.replace(
            f"({self.claude_model.title()})", "(GitHub Copilot)"
        )


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
    if not NAME_RE.fullmatch(name):
        raise ValueError(f"{path}: agent name must be lower-case kebab-case")
    if name != path.stem:
        raise ValueError(f"{path}: frontmatter name must match the filename")
    if model not in MODEL_LABELS:
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


def yaml_string(value: str) -> str:
    # A JSON basic string is also a valid YAML double-quoted scalar for the
    # single-line, no-control-character content these fields contain.
    return json.dumps(value, ensure_ascii=False)


def render_skill(agent: AgentDefinition) -> str:
    frontmatter = "\n".join(
        (
            "---",
            f"name: {yaml_string(agent.name)}",
            f"description: {yaml_string(agent.description)}",
            "---",
            "",
        )
    )
    return frontmatter + agent.copilot_instructions + "\n"


def parse_args() -> argparse.Namespace:
    repo_root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(
        description="Render private-ai-harness agents as GitHub Copilot Agent Skills."
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
        default=Path.home() / ".agents" / "skills",
        help="Global Copilot Agent Skills directory (default: ~/.agents/skills).",
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
        rendered.append((agent, render_skill(agent)))

    if args.check:
        print(f"Validated {len(rendered)} Copilot agent-skill adapters")
        return

    for agent, content in rendered:
        skill_dir = args.dest_dir / agent.name
        skill_dir.mkdir(parents=True, exist_ok=True)
        destination = skill_dir / "SKILL.md"
        temporary = destination.with_suffix(".md.tmp")
        temporary.write_text(content, encoding="utf-8")
        temporary.replace(destination)

    print(f"Installed {len(rendered)} Copilot agent skills in {args.dest_dir}")


if __name__ == "__main__":
    main()
