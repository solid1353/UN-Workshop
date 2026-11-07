"""One-shot CwCheat writes through the debugger, also used by the file watcher."""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import re
import sys
import time

from debugger import DebuggerClient, DebuggerError

CHEAT_BASE = 0x08800000
LINE = re.compile(r"_L\s+0x([0-9a-fA-F]{8})\s+0x([0-9a-fA-F]{8})\Z")
HEX_ADDRESS = re.compile(r"[0-9a-fA-F]{1,8}\Z")
HEX_BYTES = re.compile(r"(?:[0-9a-fA-F]{2})+\Z")
POLL_SECONDS = 0.15
SAVE_DELAY_SECONDS = 0.4


@dataclass(frozen=True)
class MemoryValue:
    address: int
    data: bytes


def parse_line(text: str) -> MemoryValue | None:
    text = text.split("//", 1)[0].strip()
    if not text or text.startswith(("#", ";")):
        return None
    match = LINE.fullmatch(text)
    if match is None:
        raise ValueError("expected a direct _L line or a comment; sections and other commands are unsupported")
    code = int(match[1], 16)
    value = int(match[2], 16)
    kind = code >> 28
    if kind == 0:
        # PPSSPP widens this type to fit its value.
        size = 4 if value > 0xFFFF else 2 if value > 0xFF else 1
    elif kind == 1:
        size = 2
    elif kind == 2:
        size = 4
    else:
        raise ValueError(f"unsupported code type {kind:X}; use the 0, 1 or 2 constant writes")
    if value >= 1 << (size * 8):
        raise ValueError("value does not fit its write")
    return MemoryValue(CHEAT_BASE + (code & 0x0FFFFFFF), value.to_bytes(size, "little"))


def parse_lines(lines: list[str], label: str) -> tuple[MemoryValue, ...]:
    writes = []
    for number, line in enumerate(lines, 1):
        if "\n" in line or "\r" in line:
            raise ValueError(f"{label}:{number}: supply each cheat line separately")
        try:
            write = parse_line(line)
        except ValueError as exc:
            raise ValueError(f"{label}:{number}: {exc}") from exc
        if write is not None:
            writes.append(write)
    return tuple(writes)


def parse_file(content: bytes, label: str) -> tuple[MemoryValue, ...]:
    return parse_lines(content.decode("utf-8-sig").splitlines(), label)


def parse_expectation(text: str) -> MemoryValue:
    address_text, separator, hex_text = text.partition(":")
    address_text = address_text.removeprefix("0x").removeprefix("0X")
    if not separator or not HEX_ADDRESS.fullmatch(address_text) or not HEX_BYTES.fullmatch(hex_text):
        raise ValueError("expectation must use ADDRESS:HEXBYTES, with bytes in memory order")
    return MemoryValue(int(address_text, 16), bytes.fromhex(hex_text))


def apply(
    client: DebuggerClient,
    writes: tuple[MemoryValue, ...],
    expectations: tuple[MemoryValue, ...],
) -> int:
    """Apply one parsed batch in source order. The debugger's writes clear compiled code themselves."""
    state = client.status()
    if state not in {"running", "paused"}:
        raise RuntimeError("PPSSPP has no running or paused game")
    was_running = state == "running"
    if was_running:
        client.pause()
    try:
        for expected in expectations:
            actual = client.read(expected.address, len(expected.data))
            if actual != expected.data:
                raise RuntimeError(
                    f"expected bytes differ at {expected.address:08X}: "
                    f"expected {expected.data.hex().upper()}, got {actual.hex().upper()}; no writes applied"
                )
        final: dict[int, int] = {}
        for write in writes:
            client.write(write.address, write.data)
            for offset, value in enumerate(write.data):
                final[write.address + offset] = value
        for address, value in final.items():
            if client.read(address, 1)[0] != value:
                raise RuntimeError(f"write readback differs at {address:08X}; some writes may already be applied")
        return len(writes)
    finally:
        if was_running:
            client.resume()


def connect_for_watch(port: int) -> DebuggerClient:
    """A launcher can return before its game is ready; wait without choosing a port."""
    deadline = time.monotonic() + 60
    while True:
        client = None
        try:
            client = DebuggerClient(port)
            if client.status() in {"running", "paused"}:
                return client
        except (OSError, RuntimeError):
            pass
        if client is not None:
            client.close()
        if time.monotonic() >= deadline:
            raise RuntimeError(f"no running or paused game on debugger port {port} within 60 seconds")
        time.sleep(0.25)


def watch(path: Path, port: int, expectations: tuple[MemoryValue, ...]) -> None:
    content = path.read_bytes()
    parse_file(content, str(path))
    print(f"[cheat] Waiting for debugger port {port}", flush=True)
    with connect_for_watch(port) as client:
        content = path.read_bytes()
        count = apply(client, parse_file(content, str(path)), expectations)
        print(f"[cheat] Applied {count} writes; watching {path}. Ctrl+C stops watching.", flush=True)
        observed: bytes | None = content
        pending = False
        changed_at = 0.0
        while True:
            time.sleep(POLL_SECONDS)
            if client.status() == "shutdown":
                print("[cheat] Game shut down; watcher stopped.", flush=True)
                return
            try:
                current = path.read_bytes()
            except OSError as exc:
                if observed is not None:
                    print(f"[cheat] Cannot read {path}: {exc}; waiting for the file.", file=sys.stderr, flush=True)
                observed = None
                pending = False
                continue
            if current != observed:
                observed = current
                pending = True
                changed_at = time.monotonic()
                continue
            if not pending or time.monotonic() - changed_at < SAVE_DELAY_SECONDS:
                continue
            pending = False
            try:
                writes = parse_file(current, str(path))
            except (ValueError, UnicodeError) as exc:
                print(f"[cheat] {exc}; no writes applied. Waiting for the next save.", file=sys.stderr, flush=True)
                continue
            try:
                count = apply(client, writes, expectations)
            except (DebuggerError, RuntimeError) as exc:
                print(f"[cheat] {exc}; waiting for the next save.", file=sys.stderr, flush=True)
                continue
            print(f"[cheat] Applied {count} writes.", flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", nargs="?", type=Path)
    parser.add_argument("--line", action="append", default=[])
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--watch", action="store_true")
    parser.add_argument("--expect", action="append", default=[])
    args = parser.parse_args()
    if not 1 <= args.port <= 65535:
        parser.error("port must be inside 1..65535")
    if (args.file is None) == (not args.line):
        parser.error("supply a file or one or more --line values")
    if args.watch and args.file is None:
        parser.error("watching requires a file")
    expectations = tuple(parse_expectation(text) for text in args.expect)
    if args.watch:
        watch(args.file.resolve(), args.port, expectations)
    else:
        writes = (
            parse_file(args.file.read_bytes(), str(args.file))
            if args.file is not None
            else parse_lines(args.line, "inline")
        )
        with DebuggerClient(args.port) as client:
            count = apply(client, writes, expectations)
        print(f"[cheat] Applied {count} writes on debugger port {args.port}.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\n[cheat] Watcher stopped; applied writes remain in memory.")
        raise SystemExit(0)
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"[cheat] {exc}", file=sys.stderr)
        raise SystemExit(1)
