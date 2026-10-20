"""CyberConnect2 PIDX archives (Ultimate Ninja Heroes 2's naruto.dat).

The header is ten u32 words: magic "PIDX0", the offset and count of 0x20-byte
records extraction does not need, entry table offset and count, a word
extraction does not need, the sorted name index's offset and size, and the
string table's offset and size. Each 0x18-byte entry holds a type,
its name's string offset and four words: a file's container name offset, data
offset, size and stored size, or a folder's child count and first child index.
Entry 0 is the root folder. A stored member begins with " 3;" and a mode
digit, then its size; every following byte is XORed with 0x72. Mode 0 stores
the bytes as they are, mode 1 packs them with LZSS (4 KiB window starting at
0xFEE, flag bits low first, 1 = literal).

usage: pidx.py <archive> <out-dir>
"""
from __future__ import annotations

import os
import struct
import sys
from dataclasses import dataclass
from pathlib import Path, PurePosixPath

MAGIC = b"PIDX0\0\0\0"
MASKED = b" 3;"
_UNMASK = bytes(value ^ 0x72 for value in range(256))


@dataclass(frozen=True)
class PidxMember:
    path: str
    offset: int
    size: int
    stored_size: int


def read_members(path: Path) -> list[PidxMember]:
    with path.open("rb") as handle:
        header = handle.read(0x28)
        if header[:8] != MAGIC:
            raise RuntimeError(f"Not a PIDX archive: {path}")
        words = struct.unpack("<10I", header)
        table_offset, count, strings_offset, strings_size = words[3], words[4], words[8], words[9]
        handle.seek(table_offset)
        table = handle.read(count * 0x18)
        handle.seek(strings_offset)
        strings = handle.read(strings_size)
    archive_size = path.stat().st_size

    def name(offset: int) -> str:
        return strings[offset:strings.index(0, offset)].decode("ascii")

    entries = [struct.unpack_from("<6I", table, index * 0x18) for index in range(count)]
    members: list[PidxMember] = []
    placed = [False] * count

    def visit(index: int, parent: PurePosixPath) -> None:
        if placed[index]:
            raise RuntimeError(f"PIDX entry {index} is reached twice: {path}")
        placed[index] = True
        kind, name_offset, first, second, third, fourth = entries[index]
        member_path = parent / name(name_offset)
        if kind == 1:
            if second + first > count:
                raise RuntimeError(f"PIDX folder {member_path} lists entries past the table: {path}")
            for child in range(second, second + first):
                visit(child, member_path)
        elif kind == 0:
            if name(first).casefold() != path.name.casefold():
                raise RuntimeError(f"PIDX member {member_path} lives in {name(first)}: {path}")
            if second + fourth > archive_size:
                raise RuntimeError(f"PIDX member outside the archive: {member_path}")
            members.append(PidxMember(str(member_path), second, third, fourth))
        else:
            raise RuntimeError(f"Unknown PIDX entry type {kind}: {member_path}")

    visit(0, PurePosixPath())
    if not all(placed):
        raise RuntimeError(f"PIDX entries outside the folder tree: {path}")
    return members


def lzss_decompress(data: bytes, size: int) -> bytes:
    source = data.translate(_UNMASK)
    ring = bytearray(0x1000)
    position = 0xFEE
    out = bytearray()
    index = 0
    end = len(source)
    while len(out) < size:
        if index >= end:
            raise RuntimeError("PIDX stream ends before its size")
        flags = source[index]
        index += 1
        for bit in range(8):
            if len(out) >= size:
                break
            if flags >> bit & 1:
                value = source[index]
                index += 1
                out.append(value)
                ring[position] = value
                position = (position + 1) & 0xFFF
            else:
                low, high = source[index], source[index + 1]
                index += 2
                start = low | (high & 0xF0) << 4
                for step in range((high & 0x0F) + 3):
                    value = ring[(start + step) & 0xFFF]
                    out.append(value)
                    ring[position] = value
                    position = (position + 1) & 0xFFF
    if index != end or len(out) != size:
        raise RuntimeError("PIDX stream does not match its sizes")
    return bytes(out)


def member_bytes(handle, member: PidxMember) -> bytes:
    handle.seek(member.offset)
    data = handle.read(member.stored_size)
    if len(data) != member.stored_size:
        raise RuntimeError(f"PIDX member outside the archive: {member.path}")
    if data[:3] != MASKED or struct.unpack("<I", data[4:8])[0] != member.size:
        raise RuntimeError(f"Invalid PIDX member header: {member.path}")
    if data[3:4] == b"1":
        return lzss_decompress(data[8:], member.size)
    if data[3:4] == b"0" and member.stored_size == member.size + 8:
        return data[8:].translate(_UNMASK)
    raise RuntimeError(f"Unknown PIDX member mode: {member.path}")


def extract(path: Path, out_dir: Path) -> int:
    timestamp = path.stat().st_mtime
    members = read_members(path)
    with path.open("rb") as handle:
        for member in members:
            target = out_dir.joinpath(*PurePosixPath(member.path).parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(member_bytes(handle, member))
            os.utime(target, (timestamp, timestamp))
    return len(members)


def main() -> int:
    archive, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    if out_dir.exists():
        raise RuntimeError(f"Output already exists: {out_dir}")
    out_dir.mkdir()
    print(f"Extracted {extract(archive, out_dir)} PIDX members: {archive.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
