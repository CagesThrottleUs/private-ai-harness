#!/usr/bin/env python3
"""Set the default Copilot mode without replacing existing user settings."""

import argparse
import json
import os
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--settings",
        type=Path,
        default=Path(os.environ.get("COPILOT_HOME", str(Path.home() / ".copilot")))
        / "settings.json",
    )
    args = parser.parse_args()
    path = args.settings
    settings = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    if not isinstance(settings, dict):
        raise ValueError(f"{path}: expected a JSON object")
    if settings.get("defaultMode") == "autopilot":
        return
    settings["defaultMode"] = "autopilot"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
