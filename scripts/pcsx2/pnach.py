"""One-shot EE PNACH writes, also used by the file watcher."""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import re
import sys
import time

from pine import PineClient


EE_MEMORY_SIZE = 0x02000000
WRITE_SIZES = {"byte": 1, "short": 2, "word": 4, "double": 8}
HEX_ADDRESS = re.compile(r"[0-9a-fA-F]{1,8}\Z")
HEX_BYTES = re.compile(r"(?:[0-9a-fA-F]{2})+\Z")
POLL_SECONDS = 0.15
SAVE_DELAY_SECONDS = 0.4


@dataclass(frozen=True)
class MemoryValue:
    address: int
    data: bytes


def memory_range(address: int, size: int) -> None:
    if address < 0 or size < 1 or address + size > EE_MEMORY_SIZE:
        raise ValueError("address range must be inside EE main memory (00000000..01FFFFFF)")


def parse_line(text: str) -> MemoryValue | None:
    # PNACH uses // comments; whole-line # and ; comments are also accepted.
    text = text.split("//", 1)[0].strip()
    if not text or text.startswith(("#", ";")):
        return None
    command, separator, value = text.partition("=")
    if not separator or command.strip() != "patch":
        raise ValueError("expected a direct patch= line or a comment; sections and other commands are unsupported")
    parts = [part.strip() for part in value.split(",")]
    if len(parts) != 5:
        raise ValueError("patch= requires timing, CPU, address, type and value")
    timing, cpu, address_text, kind, value_text = parts
    if timing not in {"0", "1", "2", "3"}:
        raise ValueError("PNACH timing must be 0, 1, 2 or 3; this tool applies once")
    if cpu != "EE":
        raise ValueError("only EE writes are supported")
    if kind not in WRITE_SIZES:
        raise ValueError(f"unsupported write type {kind!r}; use byte, short, word or double")
    if not HEX_ADDRESS.fullmatch(address_text):
        raise ValueError("address must contain 1..8 hexadecimal digits without a prefix")
    size = WRITE_SIZES[kind]
    if not re.fullmatch(r"[0-9a-fA-F]{1,16}", value_text):
        raise ValueError("value must contain 1..16 hexadecimal digits without a prefix")
    number = int(value_text, 16)
    if number >= 1 << (size * 8):
        raise ValueError(f"value does not fit a {kind} write")
    address = int(address_text, 16)
    memory_range(address, size)
    return MemoryValue(address, number.to_bytes(size, "little"))


def parse_lines(lines: list[str], label: str) -> tuple[MemoryValue, ...]:
    writes = []
    for number, line in enumerate(lines, 1):
        if "\n" in line or "\r" in line:
            raise ValueError(f"{label}:{number}: supply each PNACH line separately")
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
    address = int(address_text, 16)
    data = bytes.fromhex(hex_text)
    memory_range(address, len(data))
    return MemoryValue(address, data)


def read_bytes(client: PineClient, address: int, size: int) -> bytes:
    """PINE's shared client operates on aligned words; trim an enclosing read."""
    start = address & ~3
    end = (address + size + 3) & ~3
    data = b"".join(client.read32(at).to_bytes(4, "little") for at in range(start, end, 4))
    return data[address - start : address - start + size]


def apply(
    client: PineClient,
    writes: tuple[MemoryValue, ...],
    expectations: tuple[MemoryValue, ...],
) -> int:
    """Apply one parsed batch, preserving adjacent bytes and source write order."""
    state = client.status()
    if state not in {"running", "paused"}:
        raise RuntimeError("PCSX2 has no running or paused game")
    was_running = state == "running"
    if was_running:
        client.pause()
    touched = False
    try:
        for expected in expectations:
            actual = read_bytes(client, expected.address, len(expected.data))
            if actual != expected.data:
                raise RuntimeError(
                    f"expected bytes differ at {expected.address:08X}: "
                    f"expected {expected.data.hex().upper()}, got {actual.hex().upper()}; no writes applied"
                )
        words: dict[int, bytearray] = {}
        for write in writes:
            for offset, value in enumerate(write.data):
                address = write.address + offset
                aligned = address & ~3
                if aligned not in words:
                    words[aligned] = bytearray(client.read32(aligned).to_bytes(4, "little"))
                words[aligned][address - aligned] = value
        try:
            for address, data in words.items():
                touched = True
                client.write32(address, int.from_bytes(data, "little"))
            for address, data in words.items():
                if client.read32(address).to_bytes(4, "little") != data:
                    raise RuntimeError(f"write readback differs at {address:08X}; some writes may already be applied")
        finally:
            # Invalidate even after a partial write/readback failure.
            if touched:
                client.clear_execution_caches()
        return len(writes)
    finally:
        if was_running:
            client.resume()


def connect_for_watch(port: int) -> PineClient:
    """A launcher can return before its VM is ready; wait without choosing a port."""
    deadline = time.monotonic() + 60
    while True:
        client = None
        try:
            client = PineClient(port)
            if client.status() in {"running", "paused"}:
                return client
        except (OSError, RuntimeError):
            pass
        if client is not None:
            client.close()
        if time.monotonic() >= deadline:
            raise RuntimeError(f"no running or paused game on PINE port {port} within 60 seconds")
        time.sleep(0.25)


def watch(path: Path, port: int, expectations: tuple[MemoryValue, ...]) -> None:
    content = path.read_bytes()
    writes = parse_file(content, str(path))
    print(f"[pnach] Waiting for PINE port {port}", flush=True)
    with connect_for_watch(port) as client:
        # A launch may take time; apply the file as it exists when the VM is ready.
        content = path.read_bytes()
        writes = parse_file(content, str(path))
        count = apply(client, writes, expectations)
        print(f"[pnach] Applied {count} writes; watching {path}. Ctrl+C stops watching.", flush=True)
        observed: bytes | None = content
        pending = False
        changed_at = 0.0
        while True:
            time.sleep(POLL_SECONDS)
            if client.status() == "shutdown":
                print("[pnach] Game shut down; watcher stopped.", flush=True)
                return
            try:
                current = path.read_bytes()
            except OSError as exc:
                if observed is not None:
                    print(f"[pnach] Cannot read {path}: {exc}; waiting for the file.", file=sys.stderr, flush=True)
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
                print(f"[pnach] {exc}; no writes applied. Waiting for the next save.", file=sys.stderr, flush=True)
                continue
            try:
                count = apply(client, writes, expectations)
            except RuntimeError as exc:
                # Failed expectations/readback are visible; another save may correct them.
                print(f"[pnach] {exc}; waiting for the next save.", file=sys.stderr, flush=True)
                continue
            print(f"[pnach] Applied {count} writes.", flush=True)


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
        with PineClient(args.port) as client:
            count = apply(client, writes, expectations)
        print(f"[pnach] Applied {count} writes on PINE port {args.port}.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\n[pnach] Watcher stopped; applied writes remain in memory.")
        raise SystemExit(0)
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"[pnach] {exc}", file=sys.stderr)
        raise SystemExit(1)
