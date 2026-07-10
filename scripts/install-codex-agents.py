#!/usr/bin/env python3
"""Install Claude-style harness agent definitions as Codex custom agents."""

from __future__ import annotations

import argparse
import json
import os
import re
import tomllib
from dataclasses import dataclass
from pathlib import Path


PLUGIN_PREFIX = "private-ai-harness"
NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
REASONING_BY_CLAUDE_MODEL = {
    "opus": "high",
    "sonnet": "medium",
    "haiku": "low",
}


@dataclass(frozen=True)
class AgentDefinition:
    name: str
    description: str
    claude_model: str
    instructions: str

    @property
    def codex_name(self) -> str:
        return f"{PLUGIN_PREFIX}-{self.name}"

    @property
    def reasoning_effort(self) -> str:
        return REASONING_BY_CLAUDE_MODEL[self.claude_model]

    @property
    def codex_description(self) -> str:
        prefix = f"{self.claude_model.title()}-powered "
        if self.description.startswith(prefix):
            return self.description[len(prefix) :]
        return self.description

    @property
    def codex_instructions(self) -> str:
        labels = {
            "opus": "Codex: high reasoning",
            "sonnet": "Codex: medium reasoning",
            "haiku": "Codex: low reasoning",
        }
        return self.instructions.replace(
            f"({self.claude_model.title()})",
            f"({labels[self.claude_model]})",
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
    if model not in REASONING_BY_CLAUDE_MODEL:
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


def toml_string(value: str) -> str:
    # JSON basic strings are valid TOML basic strings and handle newlines safely.
    return json.dumps(value, ensure_ascii=False)


def render_agent(agent: AgentDefinition) -> str:
    content = "\n".join(
        (
            f"name = {toml_string(agent.codex_name)}",
            f"description = {toml_string(agent.codex_description)}",
            f"model_reasoning_effort = {toml_string(agent.reasoning_effort)}",
            f"developer_instructions = {toml_string(agent.codex_instructions)}",
            "",
        )
    )
    tomllib.loads(content)
    return content


def parse_args() -> argparse.Namespace:
    repo_root = Path(__file__).resolve().parent.parent
    codex_home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    parser = argparse.ArgumentParser(
        description="Render private-ai-harness agents as Codex custom-agent TOML files."
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
        default=codex_home / "agents",
        help="Codex custom-agent directory (default: $CODEX_HOME/agents).",
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
        print(f"Validated {len(rendered)} Codex agent adapters")
        return

    args.dest_dir.mkdir(parents=True, exist_ok=True)
    for agent, content in rendered:
        destination = args.dest_dir / f"{agent.codex_name}.toml"
        temporary = destination.with_suffix(".toml.tmp")
        temporary.write_text(content, encoding="utf-8")
        temporary.replace(destination)

    print(f"Installed {len(rendered)} Codex agents in {args.dest_dir}")


if __name__ == "__main__":
    main()
