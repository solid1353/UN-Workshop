from __future__ import annotations

import argparse
import json
from pathlib import Path

from game_catalog import resolve_game, resolve_game_property_names


WORKSHOP = Path(__file__).resolve().parents[2]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("selector", nargs="?")
    parser.add_argument("--project-root", type=Path)
    parser.add_argument("--properties", action="store_true")
    args = parser.parse_args()
    if args.properties:
        if args.selector is not None:
            parser.error("selector cannot be used with --properties")
        result = resolve_game_property_names(WORKSHOP, args.project_root)
    else:
        if args.selector is None:
            parser.error("selector is required unless --properties is used")
        result = resolve_game(args.selector, WORKSHOP, args.project_root)
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
