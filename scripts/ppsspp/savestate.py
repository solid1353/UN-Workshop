"""Read PPSSPP savestates (.ppst): print what the header and the start of the
state hold, or write the state's RAM to a file.

A state is a header, a title, then one compressed stream of PointerWrap
sections, which carry no sizes. SaveStart's own fields come first and Memory
follows them, so the walk stops at the end of Memory: what comes after it can
only be reached by parsing every module's state."""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

# Revision, compression, stored size, uncompressed size, git version.
HEADER = struct.Struct("<iiII32s")
REVISION_MIN, REVISION_TITLE = 4, 5
TITLE_SIZE = 128
SECTION_NAME_SIZE = 16
COMPRESSION = ("none", "snappy", "zstd")
BOOT_TYPES = ("unknown", "iso", "pbp", "elf", "disc directory")
PSP_MODELS = ("fat", "slim")
MARKER = 0x42

RAM_BASE, USER_BASE, VRAM_BASE, SCRATCHPAD_BASE = 0x08000000, 0x08800000, 0x04000000, 0x00010000
RAM_NORMAL_SIZE, RAM_DOUBLE_SIZE = 0x02000000, 0x04000000
VRAM_SIZE, SCRATCHPAD_SIZE = 0x00200000, 0x00004000


def snappy_decompress(data: bytes) -> bytes:
    """A raw snappy block: a varint size, then literals and back-references."""
    size = shift = cursor = 0
    while True:
        byte = data[cursor]
        cursor += 1
        size |= (byte & 0x7F) << shift
        shift += 7
        if byte < 0x80:
            break
    out = bytearray()
    while cursor < len(data):
        tag = data[cursor]
        cursor += 1
        kind = tag & 3
        if kind == 0:
            length = (tag >> 2) + 1
            if length > 60:
                width = length - 60
                length = int.from_bytes(data[cursor:cursor + width], "little") + 1
                cursor += width
            out += data[cursor:cursor + length]
            cursor += length
            continue
        if kind == 1:
            length = ((tag >> 2) & 7) + 4
            distance = (tag >> 5) << 8 | data[cursor]
            cursor += 1
        else:
            width = 2 if kind == 2 else 4
            length = (tag >> 2) + 1
            distance = int.from_bytes(data[cursor:cursor + width], "little")
            cursor += width
        start = len(out) - distance
        if distance == 0 or start < 0:
            raise SystemExit("corrupt snappy data")
        # A copy may run into its own output.
        while length > 0:
            chunk = out[start:start + min(length, distance)]
            out += chunk
            start += len(chunk)
            length -= len(chunk)
    if len(out) != size:
        raise SystemExit(f"snappy data holds {len(out):#x} bytes, not {size:#x}")
    return bytes(out)


def text(raw: bytes) -> str:
    return raw.split(b"\0", 1)[0].decode("utf-8", "replace")


class Stream:
    """PointerWrap's read side over the decompressed state."""

    def __init__(self, data: bytes):
        self.data = memoryview(data)
        self.offset = 0

    def read(self, size: int) -> memoryview:
        end = self.offset + size
        if end > len(self.data):
            raise SystemExit(f"state ends at {len(self.data):#x}, before {end:#x}")
        chunk = self.data[self.offset:end]
        self.offset = end
        return chunk

    def u32(self) -> int:
        return struct.unpack("<I", self.read(4))[0]

    def string(self) -> str:
        return text(bytes(self.read(self.u32())))

    def marker(self, after: str) -> None:
        found = self.u32()
        if found != MARKER:
            raise SystemExit(f"after {after}: found {found:#x} at {self.offset - 4:#x} "
                             f"instead of the marker {MARKER:#x}")

    def section(self, title: str, newest: int) -> int:
        name = bytes(self.read(SECTION_NAME_SIZE))
        if name != title.encode().ljust(SECTION_NAME_SIZE, b"\0"):
            raise SystemExit(f"expected section {title} at {self.offset - SECTION_NAME_SIZE:#x}, "
                             f"found {name!r}")
        version = self.u32()
        if not 1 <= version <= newest:
            raise SystemExit(f"unsupported {title} section version {version}")
        return version


class Savestate:
    def __init__(self, path: Path):
        self.path = path
        self.file = path.read_bytes()
        if len(self.file) < HEADER.size:
            raise SystemExit(f"{path}: too small for a PPSSPP savestate")
        (self.revision, self.compression, self.stored_size, self.uncompressed_size,
         git_version) = HEADER.unpack_from(self.file)
        self.git_version = text(git_version)
        if not REVISION_MIN <= self.revision <= REVISION_TITLE:
            raise SystemExit(f"{path}: unsupported revision {self.revision}")
        self.body = HEADER.size
        self.title = ""
        if self.revision >= REVISION_TITLE:
            self.title = text(self.file[self.body:self.body + TITLE_SIZE])
            self.body += TITLE_SIZE
        if len(self.file) - self.body != self.stored_size:
            raise SystemExit(f"{path}: {len(self.file) - self.body:#x} bytes after the header, "
                             f"expected {self.stored_size:#x}")
        if not 0 <= self.compression < len(COMPRESSION):
            raise SystemExit(f"{path}: unsupported compression {self.compression}")

    def decompressed(self) -> bytes:
        stored = self.file[self.body:]
        if COMPRESSION[self.compression] == "none":
            return stored
        if COMPRESSION[self.compression] == "snappy":
            data = snappy_decompress(stored)
        else:
            from compression import zstd

            data = zstd.decompress(stored)
        if len(data) != self.uncompressed_size:
            raise SystemExit(f"{self.path}: decompressed to {len(data):#x} bytes, "
                             f"expected {self.uncompressed_size:#x}")
        return data

    def walk(self) -> None:
        """Reads SaveStart's fields and the Memory section, in the order
        SaveStart::DoState and Memory::DoState serialize them."""
        stream = Stream(self.decompressed())
        self.start_version = stream.section("SaveStart", 6)
        if self.start_version < 3:
            raise SystemExit(f"SaveStart version {self.start_version} serializes CoreTiming before "
                             "Memory, which is unsupported")
        self.disc_id = self.disc_version = self.boot_type = None
        if self.start_version >= 6:
            self.disc_id = text(bytes(stream.read(16)))
            self.disc_version = text(bytes(stream.read(8)))
            self.boot_type = stream.read(1)[0]
        self.state_generation = stream.u32()
        self.initial_git_version = stream.string()
        self.data_generation = stream.u32()

        self.memory_version = stream.section("Memory", 3)
        self.model = None
        if self.memory_version >= 2:
            self.model = stream.u32()
            stream.marker("PSPModel")
        if self.memory_version >= 3:
            size = stream.u32()
        else:
            size = RAM_DOUBLE_SIZE if self.model else RAM_NORMAL_SIZE
        self.ram_offset = stream.offset
        self.ram = stream.read(size)
        stream.marker("RAM")
        self.vram_offset = stream.offset
        stream.read(VRAM_SIZE)
        stream.marker("VRAM")
        self.scratchpad_offset = stream.offset
        stream.read(SCRATCHPAD_SIZE)
        stream.marker("ScratchPad")
        stream.marker("Memory")


def named(names: tuple, index: int) -> str:
    return names[index] if index < len(names) else f"{index:#x}"


def info(state: Savestate) -> None:
    print(f"revision {state.revision}")
    print(f"compression {named(COMPRESSION, state.compression)}")
    print(f"stored size {state.stored_size:#x}")
    print(f"uncompressed size {state.uncompressed_size:#x}")
    print(f"git version {state.git_version}")
    print(f"title {state.title}")
    sys.stdout.flush()
    state.walk()
    print(f"SaveStart version {state.start_version}")
    if state.disc_id is not None:
        print(f"disc id {state.disc_id}")
        print(f"disc version {state.disc_version}")
        print(f"boot type {named(BOOT_TYPES, state.boot_type)}")
    print(f"state generation {state.state_generation}")
    print(f"first git version {state.initial_git_version}")
    print(f"savedata generation {state.data_generation}")
    print(f"Memory version {state.memory_version}")
    if state.model is not None:
        print(f"PSP model {named(PSP_MODELS, state.model)}")
    print(f"RAM {RAM_BASE:#010x} size {len(state.ram):#x} at state offset {state.ram_offset:#x}")
    print(f"VRAM {VRAM_BASE:#010x} size {VRAM_SIZE:#x} at state offset {state.vram_offset:#x}")
    print(f"scratchpad {SCRATCHPAD_BASE:#010x} size {SCRATCHPAD_SIZE:#x} "
          f"at state offset {state.scratchpad_offset:#x}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    information = commands.add_parser("info", help="the header and the fields before Memory")
    information.add_argument("state", type=Path)
    ram = commands.add_parser("ram", help="write the state's RAM to a file")
    ram.add_argument("state", type=Path)
    ram.add_argument("-o", "--output", type=Path, required=True)
    arguments = parser.parse_args()

    sys.stdout.reconfigure(errors="backslashreplace")
    state = Savestate(arguments.state)
    if arguments.command == "info":
        info(state)
        return
    state.walk()
    arguments.output.write_bytes(state.ram)
    # The image holds the kernel partition too, so an address is its offset
    # from the RAM base.
    print(f"wrote {arguments.output}: {len(state.ram):#x} bytes from guest {RAM_BASE:#010x}, "
          f"kernel memory included; user memory {USER_BASE:#010x} is file offset "
          f"{USER_BASE - RAM_BASE:#x}")


if __name__ == "__main__":
    main()
