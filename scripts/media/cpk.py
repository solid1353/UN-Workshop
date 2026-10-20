"""CRI CPK archives: table of contents, CRILAYLA decompression and extraction.

usage: cpk.py <cpk> <out-dir>
"""
from __future__ import annotations

import os
import struct
import sys
from dataclasses import dataclass
from pathlib import Path, PurePosixPath

MAGIC = b"CPK "
_VALUE_FORMATS = {0: ">B", 1: ">b", 2: ">H", 3: ">h", 4: ">I", 5: ">i", 6: ">Q", 7: ">q", 8: ">f"}


@dataclass(frozen=True)
class CpkMember:
    path: str
    offset: int
    size: int
    extract_size: int


def _utf_rows(table: bytes) -> list[dict[str, object]]:
    if table[:4] != b"@UTF":
        raise RuntimeError("Missing @UTF table")
    size, = struct.unpack(">I", table[4:8])
    body = table[8:8 + size]
    rows_offset, strings_offset, data_offset, _name, columns, row_length, row_count = struct.unpack(
        ">2xHIIIHHI", body[:24])

    def text(offset: int) -> str:
        start = strings_offset + offset
        return body[start:body.index(0, start)].decode("utf-8")

    def value(position: int, kind: int) -> tuple[object, int]:
        if kind in _VALUE_FORMATS:
            width = struct.calcsize(_VALUE_FORMATS[kind])
            return struct.unpack(_VALUE_FORMATS[kind], body[position:position + width])[0], position + width
        if kind == 0xA:
            return text(struct.unpack(">I", body[position:position + 4])[0]), position + 4
        if kind == 0xB:
            offset, length = struct.unpack(">II", body[position:position + 8])
            return body[data_offset + offset:data_offset + offset + length], position + 8
        raise RuntimeError(f"Unsupported @UTF column type {kind:#x}")

    schema: list[tuple[int, str, object]] = []
    position = 24
    for _ in range(columns):
        flags = body[position]
        name = text(struct.unpack(">I", body[position + 1:position + 5])[0])
        position += 5
        constant = None
        if flags & 0xF0 == 0x30:
            constant, position = value(position, flags & 0x0F)
        schema.append((flags, name, constant))

    rows = []
    for index in range(row_count):
        position = rows_offset + index * row_length
        row: dict[str, object] = {}
        for flags, name, constant in schema:
            if flags & 0xF0 == 0x50:
                row[name], position = value(position, flags & 0x0F)
            else:
                row[name] = constant
        rows.append(row)
    return rows


def read_members(path: Path) -> list[CpkMember]:
    with path.open("rb") as handle:
        head = handle.read(0x800)
        if head[:4] != MAGIC:
            raise RuntimeError(f"Not a CPK archive: {path}")
        header = _utf_rows(head[0x10:])[0]
        toc_offset = header.get("TocOffset")
        content_offset = header.get("ContentOffset")
        if not toc_offset:
            raise RuntimeError(f"CPK has no TOC: {path}")
        handle.seek(toc_offset)
        chunk = handle.read(0x10)
        if chunk[:4] != b"TOC ":
            raise RuntimeError(f"Invalid CPK TOC chunk: {path}")
        toc_size, = struct.unpack("<Q", chunk[8:16])
        rows = _utf_rows(handle.read(toc_size))
    base = min(toc_offset, content_offset) if content_offset else toc_offset
    members = []
    seen: set[str] = set()
    for row in rows:
        directory = row.get("DirName") or ""
        member_path = str(PurePosixPath(directory, row["FileName"]))
        if member_path.casefold() in seen:
            raise RuntimeError(f"Duplicate CPK member: {member_path}")
        seen.add(member_path.casefold())
        members.append(CpkMember(member_path, base + row["FileOffset"], row["FileSize"], row["ExtractSize"]))
    if len(members) != header.get("Files", len(members)):
        raise RuntimeError(f"CPK TOC lists {len(members)} of {header['Files']} files: {path}")
    return members


def crilayla_decompress(data: bytes) -> bytes:
    if data[:8] != b"CRILAYLA":
        raise RuntimeError("Missing CRILAYLA header")
    raw_size, compressed_size = struct.unpack("<II", data[8:16])
    prefix = data[0x10 + compressed_size:0x10 + compressed_size + 0x100]
    if len(prefix) != 0x100:
        raise RuntimeError("Truncated CRILAYLA prefix")
    # The bitstream is read MSB first from the last compressed byte backwards,
    # which equals reading the reversed bytes forwards.
    stream = data[0x10:0x10 + compressed_size][::-1] + b"\0\0\0\0"
    out = bytearray(raw_size)
    bit = 0

    def bits(count: int) -> int:
        nonlocal bit
        byte = bit >> 3
        word = int.from_bytes(stream[byte:byte + 4], "big")
        value = (word >> (32 - (bit & 7) - count)) & ((1 << count) - 1)
        bit += count
        return value

    write = raw_size - 1
    while write >= 0:
        if bits(1):
            source = write + bits(13) + 3
            length = 3
            for width in (2, 3, 5, 8):
                level = bits(width)
                length += level
                if level != (1 << width) - 1:
                    break
            else:
                while True:
                    level = bits(8)
                    length += level
                    if level != 255:
                        break
            if length > write + 1:
                raise RuntimeError("CRILAYLA reference overruns the output")
            for _ in range(length):
                out[write] = out[source]
                write -= 1
                source -= 1
        else:
            out[write] = bits(8)
            write -= 1
    return prefix + bytes(out)


def member_bytes(handle, member: CpkMember) -> bytes:
    handle.seek(member.offset)
    data = handle.read(member.size)
    if len(data) != member.size:
        raise RuntimeError(f"CPK member outside the archive: {member.path}")
    if member.size != member.extract_size:
        data = crilayla_decompress(data)
    if len(data) != member.extract_size:
        raise RuntimeError(f"CPK member size mismatch: {member.path}")
    return data


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
    print(f"Extracted {extract(archive, out_dir)} CPK members: {archive.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
