"""List, remove and move the markers of a PPSSPP input recording."""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import json
import re
import struct
import sys
import uuid

MAGIC = b"PPREPLAY"
HEADER_SIZE = 32
ITEM_SIZE = 17
MARKER = 0x02
END = 0x03
SIDEDATA = 0x80
# A PSP vblank at 59.94 Hz.
FRAME_US = 16683


@dataclass
class Item:
    action: int
    timestamp: int
    payload: bytes
    side_data: bytes

    def pack(self) -> bytes:
        return struct.pack("<BQ", self.action, self.timestamp) + self.payload + self.side_data


def read_recording(data: bytes) -> tuple[bytes, list[Item]]:
    if len(data) < HEADER_SIZE or data[:8] != MAGIC:
        raise ValueError("not a PPSSPP input recording")
    items = []
    offset = HEADER_SIZE
    while offset < len(data):
        if offset + ITEM_SIZE > len(data):
            raise ValueError(f"truncated event at offset {offset}")
        action, timestamp = struct.unpack_from("<BQ", data, offset)
        payload = data[offset + 9 : offset + ITEM_SIZE]
        offset += ITEM_SIZE
        side_data = b""
        if action & SIDEDATA:
            size = struct.unpack_from("<I", payload)[0]
            if offset + size > len(data):
                raise ValueError(f"truncated side data at offset {offset}")
            side_data = data[offset : offset + size]
            offset += size
        items.append(Item(action, timestamp, payload, side_data))
    return data[:HEADER_SIZE], items


def markers(items: list[Item]) -> list[Item]:
    return [item for item in items if item.action == MARKER]


def describe(items: list[Item]) -> list[dict[str, int]]:
    return [
        {"Marker": number, "TimeUs": item.timestamp, "Frame": item.timestamp // FRAME_US}
        for number, item in enumerate(markers(items), 1)
    ]


def end_time(items: list[Item]) -> int:
    return items[-1].timestamp if items else 0


def remove(items: list[Item], numbers: list[int]) -> list[Item]:
    found = markers(items)
    selected = set(numbers)
    for number in selected:
        if not 1 <= number <= len(found):
            raise ValueError(f"marker {number} is outside the recording's marker range 1-{len(found)}")
    dropped = {id(found[number - 1]) for number in selected}
    return [item for item in items if id(item) not in dropped]


def move(items: list[Item], number: int, offset_frames: int) -> list[Item]:
    found = markers(items)
    if not 1 <= number <= len(found):
        raise ValueError(f"marker {number} is outside the recording's marker range 1-{len(found)}")
    if offset_frames == 0:
        raise ValueError("OffsetFrames must not be zero")
    marker = found[number - 1]
    destination = marker.timestamp + offset_frames * FRAME_US
    if not 0 <= destination <= end_time(items):
        raise ValueError(f"moved marker would be outside 0-{end_time(items)} us: {destination}")
    edited = [item for item in items if item is not marker]
    # Replay stops at the first event still in the future, so events stay in time order.
    index = next((at for at, item in enumerate(edited) if item.timestamp > destination), len(edited))
    if index == len(edited) and edited and edited[-1].action == END:
        index -= 1
    edited.insert(index, Item(MARKER, destination, marker.payload, marker.side_data))
    return edited


def backups(path: Path) -> list[tuple[int, Path]]:
    pattern = re.compile(re.escape(path.name) + r"\.bak([1-9][0-9]*)\Z")
    found = []
    for candidate in path.parent.iterdir():
        match = pattern.fullmatch(candidate.name)
        if match is not None and candidate.is_file():
            found.append((int(match[1]), candidate))
    return sorted(found)


def save(path: Path, header: bytes, items: list[Item], expected: list[dict[str, int]]) -> None:
    output = header + b"".join(item.pack() for item in items)
    temporary = path.with_name(f"{path.name}.edit-{uuid.uuid4().hex}.tmp")
    try:
        temporary.write_bytes(output)
        if describe(read_recording(temporary.read_bytes())[1]) != expected:
            raise RuntimeError("the edited recording does not hold the expected markers")
        for number, backup in reversed(backups(path)):
            backup.rename(path.with_name(f"{path.name}.bak{number + 1}"))
        path.rename(path.with_name(f"{path.name}.bak1"))
        temporary.rename(path)
    finally:
        temporary.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("recording", type=Path)
    parser.add_argument("--remove", type=int, nargs="+")
    parser.add_argument("--move", type=int)
    parser.add_argument("--offset-frames", type=int)
    args = parser.parse_args()
    if args.remove and args.move is not None:
        parser.error("use only one of --remove or --move")
    if (args.move is None) != (args.offset_frames is None):
        parser.error("--move requires --offset-frames")

    path = args.recording.resolve()
    header, items = read_recording(path.read_bytes())
    if args.remove:
        items = remove(items, args.remove)
    elif args.move is not None:
        items = move(items, args.move, args.offset_frames)
    else:
        print(json.dumps(describe(items), indent=2))
        return 0

    result = describe(items)
    save(path, header, items, result)
    print(json.dumps({"Recording": str(path), "Backup": f"{path}.bak1", "Markers": result}, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"[recording_markers] {exc}", file=sys.stderr)
        raise SystemExit(1)
