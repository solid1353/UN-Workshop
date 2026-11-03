"""Decompressed CCS section walking and texture lookup."""

from __future__ import annotations

import struct
import gzip
import zlib
from pathlib import Path
from collections import Counter
from collections import defaultdict
from dataclasses import dataclass


SECTION_HEADER = 0xCCCC0001
SECTION_TOC = 0xCCCC0002
SECTION_INDEX = 0xCCCC0005
SECTION_FRAME = 0xCCCCFF01
SECTION_TEXTURE = 0xCCCC0300
SECTION_PALETTE = 0xCCCC0400
SECTION_MODEL = 0xCCCC0800
KNOWN_SECTION_TYPES = {
    0xCCCC0001, 0xCCCC0002, 0xCCCC0003, 0xCCCC0005,
    0xCCCC0100, 0xCCCC0102, 0xCCCC0108, 0xCCCC0200,
    0xCCCC0202, 0xCCCC0300, 0xCCCC0400, 0xCCCC0500,
    0xCCCC0502, 0xCCCC0600, 0xCCCC0601, 0xCCCC0603,
    0xCCCC0609, 0xCCCC0700, 0xCCCC0800, 0xCCCC0900,
    0xCCCC0A00, 0xCCCC0B00, 0xCCCC0C00, 0xCCCC0D00,
    0xCCCC0E00, 0xCCCC1000, 0xCCCC1100, 0xCCCC1200,
    0xCCCC1300, 0xCCCC1400, 0xCCCC1700, 0xCCCC1800,
    0xCCCC1900, 0xCCCC1901, 0xCCCC2000, 0xCCCC2200,
    0xCCCC2400, 0xCCCCFF01,
}
@dataclass(frozen=True)
class Section:
    section_type: int
    offset: int
    total_size: int
    object_id: int | None
    object_name: str | None

    @property
    def data_offset(self) -> int:
        return self.offset + 12

    @property
    def data_size(self) -> int:
        return self.total_size - 12


@dataclass(frozen=True)
class TextureEntry:
    name: str
    textures: tuple[Section, ...]
    palettes: tuple[Section, ...]


def read_u32(data: bytes | bytearray, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def read_c_string(data: bytes, offset: int, size: int) -> str:
    return data[offset : offset + size].split(b"\0", 1)[0].decode("ascii", "replace")


def parse_toc(data: bytes, offset: int) -> tuple[int, list[str], list[str], list[int]]:
    size_words = read_u32(data, offset + 4)
    file_count = read_u32(data, offset + 8) - 1
    object_count = read_u32(data, offset + 12) - 1
    toc_data = data[offset + 16 : offset + 16 + size_words * 4]
    cursor = 0x20
    filenames = []
    for _ in range(file_count):
        filenames.append(read_c_string(toc_data, cursor, 0x20).strip())
        cursor += 0x20
    cursor += 0x20
    object_names = []
    file_indexes = []
    for _ in range(object_count):
        object_names.append(read_c_string(toc_data, cursor, 0x1E).strip())
        file_indexes.append(struct.unpack_from("<H", toc_data, cursor + 0x1E)[0])
        cursor += 0x20
    return 16 + size_words * 4, filenames, object_names, file_indexes


def section_total_size(data: bytes, offset: int, section_type: int, size_words: int) -> int:
    if section_type == SECTION_TOC:
        return 16 + size_words * 4
    if section_type == SECTION_TEXTURE:
        if size_words < 51:
            raise ValueError(f"Texture section at 0x{offset:X} is smaller than 51 words")
        return 12 + (size_words - 51) * 4
    if section_type == SECTION_MODEL:
        cursor = offset + 12
        while cursor + 4 <= len(data):
            if read_u32(data, cursor) in KNOWN_SECTION_TYPES:
                return cursor - offset
            cursor += 4
        raise ValueError(f"Could not locate the section after model at 0x{offset:X}")
    return 8 + size_words * 4


def parse_ccs(payload: bytes | bytearray) -> dict[str, TextureEntry]:
    """Map each casefolded `.bmp` filename to its TEX and CLT sections."""
    data = bytes(payload)
    filenames: list[str] | None = None
    object_names: list[str] = []
    file_indexes: list[int] = []
    cursor = 0
    while cursor + 8 <= len(data):
        section_type = read_u32(data, cursor)
        size_words = read_u32(data, cursor + 4)
        if section_type == SECTION_TOC:
            _, filenames, object_names, file_indexes = parse_toc(data, cursor)
            break
        cursor += section_total_size(data, cursor, section_type, size_words)
    if filenames is None:
        raise ValueError("CCS has no TOC section")

    sections_by_object: dict[int, list[Section]] = defaultdict(list)
    cursor = 0
    while cursor + 8 <= len(data):
        section_type = read_u32(data, cursor)
        size_words = read_u32(data, cursor + 4)
        total_size = section_total_size(data, cursor, section_type, size_words)
        if total_size <= 0 or cursor + total_size > len(data):
            raise ValueError(f"Invalid CCS section at 0x{cursor:X}")
        object_id = None if section_type == SECTION_TOC or not size_words else read_u32(data, cursor + 8)
        object_name = None
        if object_id is not None and 1 <= object_id <= len(object_names):
            object_name = object_names[object_id - 1]
            sections_by_object[object_id].append(
                Section(section_type, cursor, total_size, object_id, object_name)
            )
        cursor += total_size
    if cursor != len(data):
        raise ValueError(f"CCS section walk ended at 0x{cursor:X}, expected 0x{len(data):X}")

    object_ids_by_file: dict[int, list[int]] = defaultdict(list)
    for object_id, file_index in enumerate(file_indexes, 1):
        object_ids_by_file[file_index].append(object_id)
    result: dict[str, TextureEntry] = {}
    for file_index, filename in enumerate(filenames, 1):
        if not filename.casefold().endswith(".bmp"):
            continue
        textures = []
        palettes = []
        for object_id in object_ids_by_file[file_index]:
            for section in sections_by_object.get(object_id, []):
                if section.section_type == SECTION_TEXTURE:
                    textures.append(section)
                elif section.section_type == SECTION_PALETTE:
                    palettes.append(section)
        key = filename.casefold()
        if key in result:
            raise ValueError(f"Duplicate CCS texture filename {filename!r}")
        result[key] = TextureEntry(filename, tuple(textures), tuple(palettes))
    return result


def decompressed(data: bytes) -> bytes:
    return gzip.decompress(data) if data[:2] == b"\x1f\x8b" else data


def _chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))


def texture_png(payload: bytes, entry: TextureEntry, palette_index: int = 0) -> bytes:
    """A retail indexed texture as PNG, retaining its indices and exact GS alpha."""
    if len(entry.textures) != 1 or not entry.palettes:
        raise ValueError(f"{entry.name}: expected one indexed texture and its palettes")
    tex = entry.textures[0]
    data = payload[tex.data_offset:tex.offset + tex.total_size]
    width, height = 1 << data[12], 1 << data[13]
    pixels = data[24:]
    if len(pixels) * 2 == width * height:
        pixels = bytes(component for value in pixels for component in (value & 15, value >> 4))
    elif len(pixels) != width * height:
        raise ValueError(f"{entry.name}: unsupported texture storage")
    palette = entry.palettes[palette_index]
    colors = payload[palette.data_offset + 16:palette.offset + palette.total_size]
    if len(colors) % 4 or not 0 < len(colors) // 4 <= 256 or max(pixels) >= len(colors) // 4:
        raise ValueError(f"{entry.name}: unsupported palette")
    rgb = bytes(channel for index in range(0, len(colors), 4) for channel in colors[index:index + 3])
    alpha = colors[3::4]
    rows = b"".join(b"\0" + pixels[row * width:(row + 1) * width]
                    for row in range(height - 1, -1, -1))
    result = b"\x89PNG\r\n\x1a\n" + _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 3, 0, 0, 0))
    result += _chunk(b"PLTE", rgb) + _chunk(b"tRNS", bytes(min(255, (a * 255 + 64) // 128) for a in alpha))
    if any(a > 128 for a in alpha):
        result += _chunk(b"tEXt", b"ps2_alpha\0" + alpha.hex().encode("ascii"))
    return result + _chunk(b"IDAT", zlib.compress(rows)) + _chunk(b"IEND", b"")


def texture_views(payload: bytes) -> dict[str, bytes]:
    """PNG filenames and bytes; retain namespaces only for colliding texture stems."""
    entries = [entry for entry in parse_ccs(payload).values() if entry.textures]
    stems = Counter(entry.name.replace("\\", "/").rsplit("/", 1)[-1].rsplit(".", 1)[0].casefold()
                    for entry in entries)
    result = {}
    for entry in entries:
        name = entry.name.replace("\\", "/")
        stem = name.rsplit("/", 1)[-1].rsplit(".", 1)[0]
        if stems[stem.casefold()] > 1:
            stem = name.rsplit(".", 1)[0]
        candidate = Path(stem)
        if candidate.is_absolute() or ".." in candidate.parts or ":" in stem:
            raise ValueError(f"Unsafe CCS texture name: {entry.name}")
        for index in range(len(entry.palettes)):
            filename = f"{stem}{'.' + str(index) if index else ''}.png"
            if filename.casefold() in {key.casefold() for key in result}:
                raise ValueError(f"Duplicate CCS texture view: {filename}")
            result[filename] = texture_png(payload, entry, index)
    return result


def verify_views(archive: Path, output: Path) -> int:
    """Verify every view against the original container, including all palettes."""
    images = texture_views(decompressed(archive.read_bytes()))
    actual = {path.relative_to(output).as_posix() for path in output.rglob("*") if path.is_file()}
    if actual != set(images):
        raise ValueError(f"{archive}: texture view inventory differs")
    for name, data in images.items():
        if (output / name).read_bytes() != data:
            raise ValueError(f"{archive}: texture view differs: {name}")
    return len(images)
