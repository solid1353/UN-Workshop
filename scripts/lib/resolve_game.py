from __future__ import annotations

import argparse
import json
from pathlib import Path

from game_catalog import resolve_game


WORKSHOP = Path(__file__).resolve().parents[2]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("selector")
    parser.add_argument("--project-root", type=Path)
    args = parser.parse_args()
    print(json.dumps(resolve_game(args.selector, WORKSHOP, args.project_root)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
