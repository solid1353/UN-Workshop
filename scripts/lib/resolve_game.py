from __future__ import annotations

import argparse
import json
from pathlib import Path

from game_catalog import load_catalog, resolve_game, resolve_game_property_names


WORKSHOP = Path(__file__).resolve().parents[2]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("selector", nargs="?")
    parser.add_argument("--project-root", type=Path)
    output_mode = parser.add_mutually_exclusive_group()
    output_mode.add_argument("--properties", action="store_true")
    output_mode.add_argument("--available-sources", action="store_true")
    args = parser.parse_args()
    if args.properties or args.available_sources:
        if args.selector is not None:
            option = "--properties" if args.properties else "--available-sources"
            parser.error(f"selector cannot be used with {option}")
        result = (
            resolve_game_property_names(WORKSHOP, args.project_root)
            if args.properties
            else list(load_catalog(WORKSHOP, args.project_root)["sources"])
        )
    else:
        if args.selector is None:
            parser.error("selector is required unless --properties is used")
        result = resolve_game(args.selector, WORKSHOP, args.project_root)
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
