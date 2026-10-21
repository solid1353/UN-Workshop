"""Rank one program's functions by how closely their instructions match given
functions of another program, from the preserved export listings, to find
counterparts match_annotations.ps1 cannot pair exactly.

Instructions are compared with call and branch targets, addresses, gp
offsets and large immediates set aside; the score is difflib's ratio of the
two sequences. Each listing's parsed functions are cached under @cache.
"""

from __future__ import annotations

import argparse
import difflib
import pickle
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from scripts.lib.paths import load_workshop_paths  # noqa: E402

HEADER = re.compile(r";\S*\s*(\S+)\s+(\w+)\(")
# A listing line: its address and bytes (in ELF listings a truncated address
# run into the bytes), mnemonic and operands.
LINE = re.compile(r"^\w+:(?:[0-9a-f]{4}\.\.\.[0-9a-f]{8}|[0-9a-f]{8}\s+[0-9a-f]{8})\s+(\S+)\s*(.*?)\s*(?:;.*)?$")
MEMORY_MNEMONICS = ("addiu", "lw", "sw", "lwc1", "swc1", "lbu", "lb", "lh", "lhu", "sh", "sb",
                    "ld", "sd", "lq", "sq")


def normalize(mnemonic: str, operands: str) -> str:
    mnemonic = mnemonic.lstrip("_")
    if mnemonic in ("jal", "j") or mnemonic.startswith("b"):
        return mnemonic
    if "gp" in operands:
        return f"{mnemonic} <gp>"
    if mnemonic == "lui":
        register, value = operands.split(",", 1)
        try:
            number = int(value, 16)
        except ValueError:
            return f"lui {register},<addr>"
        return f"lui {register},<addr>" if 0x10 <= number <= 0xB0 else f"lui {register},{value}"
    operands = re.sub(r"(?:DAT|PTR|SUB|FUN|LAB|s|u)_[0-9A-Za-z_]+", "<sym>", operands)

    def immediate(match: re.Match) -> str:
        value = int(match.group(0).lstrip("-"), 16)
        large = value > 0x7FFF or value >= 0x1000 and mnemonic in MEMORY_MNEMONICS
        return "<lo>" if large else match.group(0)
    return f"{mnemonic} {re.sub(r'-?0x[0-9a-f]+', immediate, operands)}"


def functions(listing: Path) -> dict[str, list[str]]:
    """Each function's normalized instructions, by its header name."""
    out, name, body, pending = {}, None, [], None
    with listing.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            stripped = line.strip()
            if stripped.startswith(";*") and "FUNCTION" in stripped:
                if name is not None:
                    out[name] = body
                name, body, pending = None, [], None
                continue
            if stripped.startswith(";") and name is None:
                header = HEADER.search(line)
                if header and "XREF" not in stripped:
                    pending = header.group(2)
                continue
            match = LINE.match(stripped)
            if match:
                if name is None and pending is not None:
                    name, pending = pending, None
                if name is not None:
                    body.append(normalize(match.group(1), match.group(2)))
    if name is not None:
        out[name] = body
    return out


def program_functions(game: str, program: str) -> dict[str, list[str]]:
    paths = load_workshop_paths()
    listing = paths.path("disassembly", game, "exports", program, f"{program}.txt")
    stamp = listing.stat()
    cache = paths.path("cache", "similar_functions", f"{game}_{program}.pickle")
    if cache.is_file():
        cached = pickle.loads(cache.read_bytes())
        if cached["stamp"] == (stamp.st_size, stamp.st_mtime_ns):
            return cached["functions"]
    found = functions(listing)
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_bytes(pickle.dumps({"stamp": (stamp.st_size, stamp.st_mtime_ns), "functions": found}))
    return found


def ranked(target: list[str], pool: dict[str, list[str]], count: int):
    scored = []
    for name, body in pool.items():
        if not body or not 0.5 <= len(body) / max(1, len(target)) <= 2.0:
            continue
        matcher = difflib.SequenceMatcher(None, target, body, autojunk=False)
        if matcher.real_quick_ratio() < 0.45 or matcher.quick_ratio() < 0.45:
            continue
        scored.append((matcher.ratio(), name, len(body)))
    return sorted(scored, reverse=True)[:count]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("from_game")
    parser.add_argument("from_program")
    parser.add_argument("to_game")
    parser.add_argument("to_program")
    parser.add_argument("functions", nargs="+", help="addresses such as 0x00178AD0, or listing names")
    parser.add_argument("--count", type=int, default=3)
    arguments = parser.parse_args()
    source = program_functions(arguments.from_game, arguments.from_program)
    target = program_functions(arguments.to_game, arguments.to_program)
    for function in arguments.functions:
        key = function if not re.fullmatch(r"(0x)?[0-9A-Fa-f]{1,8}", function) else f"FUN_{int(function, 16):08x}"
        body = source.get(key)
        if body is None:
            print(f"{function}: no such function in {arguments.from_game} {arguments.from_program}")
            continue
        matches = ranked(body, target, arguments.count)
        print(f"{key} ({len(body)}): " + "; ".join(
            f"{ratio:.2f} {name} ({length})" for ratio, name, length in matches))


if __name__ == "__main__":
    main()
