"""Assemble an Allegrex listing through PPSSPP's debugger and print it as CwCheat lines."""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import struct
import sys
from typing import Sequence

from debugger import DebuggerClient

CHEAT_BASE = 0x08800000
LABEL = re.compile(r"^([A-Za-z_]\w*):\s*(.*)$")
NAME = re.compile(r"\b([A-Za-z_]\w*)\b")


def parse(lines: list[str], base: int) -> tuple[list[tuple[int, str, str]], dict[str, int]]:
    """One instruction per line from base on; `name:` labels a line, `;` starts a comment."""
    items: list[tuple[int, str, str]] = []
    labels: dict[str, int] = {}
    address = base
    for line in lines:
        code, _, comment = line.partition(";")
        code = code.strip()
        match = LABEL.match(code)
        if match:
            if match[1] in labels:
                raise ValueError(f"label {match[1]} is defined twice")
            labels[match[1]] = address
            code = match[2].strip()
        if code:
            items.append((address, code, comment.strip()))
            address += 4
    return items, labels


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--base", type=lambda text: int(text, 16), required=True,
                        help="guest address of the first instruction, such as 08800000")
    parser.add_argument("listing", type=Path)
    args = parser.parse_args(argv)
    if args.base < CHEAT_BASE or args.base % 4:
        parser.error("--base must be a word-aligned address from 08800000 on")

    items, labels = parse(args.listing.read_text(encoding="utf-8").splitlines(), args.base)
    names = {address: name for name, address in labels.items()}
    with DebuggerClient(args.port) as client:
        for address, code, comment in items:
            text = NAME.sub(lambda m: f"0x{labels[m[1]]:08X}" if m[1] in labels else m[1], code)
            # memory.assemble writes the instruction at its address and returns it.
            word = client.request("memory.assemble", address=address, code=text)["encoding"]
            if struct.unpack("<I", client.read(address, 4))[0] != word:
                raise RuntimeError(f"{address:08X}: memory does not hold the assembled {word:08X}")
            label = f"{names[address]}: " if address in names else ""
            note = f" ({comment})" if comment else ""
            print(f"_L 0x2{address - CHEAT_BASE:07X} 0x{word:08X} // {label}{text.lower()}{note}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
