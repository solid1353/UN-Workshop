"""Read PCSX2 GS dumps (.gs or .gs.zst): list one frame's uploads, moves and
draws in submission order, or diff that list between two dumps.

Each draw batch shows the GS state of the context its PRIM selects, its
vertex count and screen box; textures and palettes are named by a hash of the
image last uploaded to their base block, so dumps of different games compare
even when their VRAM layouts differ."""

from __future__ import annotations

import argparse
import difflib
import hashlib
import struct
import sys
from pathlib import Path

# Privileged registers in the dump's register snapshots.
PMODE, DISPFB1, DISPFB2 = 0x00, 0x70, 0x90

# General registers: context-1 address, context 2 is one higher.
PRIM, RGBAQ, ST, UV, XYZF2, XYZ2, TEX0, CLAMP, FOG, XYZF3, XYZ3 = (
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x08, 0x0A, 0x0C, 0x0D)
TEX1, XYOFFSET, SCISSOR, ALPHA, TEST, FRAME, ZBUF = 0x14, 0x18, 0x40, 0x42, 0x47, 0x4C, 0x4E
BITBLTBUF, TRXPOS, TRXREG, TRXDIR = 0x50, 0x51, 0x52, 0x53
CONTEXT_REGISTERS = (TEX0, CLAMP, TEX1, XYOFFSET, SCISSOR, ALPHA, TEST, FRAME, ZBUF)
CONTEXT_NAMES = ("tex0", "clamp", "tex1", "xyoffset", "scissor", "alpha", "test", "frame", "zbuf")
VERTEX_KICKS = (XYZF2, XYZ2, XYZF3, XYZ3)


def load(path: Path) -> bytes:
    data = path.read_bytes()
    if path.suffix == ".zst":
        from compression import zstd

        data = zstd.decompress(data)
    if struct.unpack_from("<I", data, 0)[0] != 0xFFFFFFFF:
        raise SystemExit(f"{path}: not a PCSX2 GS dump")
    return data


class Frame:
    """The events of one frame of a dump, in submission order."""

    def __init__(self, data: bytes, wanted: int):
        self.wanted = wanted
        self.state: dict[int, int] = {}
        self.image_hashes: dict[int, str] = {}
        self.events: list[list] = []
        self.batch = None
        self.display = None
        self.frame = 0
        self.walk(data)

    def walk(self, data: bytes) -> None:
        header_size = struct.unpack_from("<I", data, 4)[0]
        state_size = struct.unpack_from("<I", data, 12)[0]
        cursor = 8 + header_size + state_size
        self.privileged(data[cursor:cursor + 8192])
        cursor += 8192
        while cursor < len(data) and self.frame <= self.wanted:
            kind = data[cursor]
            cursor += 1
            if kind == 0:  # transfer: path, size, GIF data
                size = struct.unpack_from("<I", data, cursor + 1)[0]
                cursor += 5
                self.gif(data[cursor:cursor + size])
                cursor += size
            elif kind == 1:  # vsync
                cursor += 1
                self.frame += 1
                self.batch = None
            elif kind == 2:  # FIFO read
                cursor += 4
            elif kind == 3:  # privileged registers
                if self.frame == self.wanted and self.display is None:
                    self.privileged(data[cursor:cursor + 8192])
                cursor += 8192
            else:
                raise SystemExit(f"unknown packet {kind} at {cursor - 1:#x}")

    def privileged(self, registers: bytes) -> None:
        word = lambda offset: struct.unpack_from("<Q", registers, offset)[0]
        self.display = (word(PMODE), word(DISPFB1), word(DISPFB2))

    def gif(self, buffer: bytes) -> None:
        offset = 0
        while offset + 16 <= len(buffer):
            lo, hi = struct.unpack_from("<QQ", buffer, offset)
            offset += 16
            nloop = lo & 0x7FFF
            flg = (lo >> 58) & 3
            nreg = (lo >> 60) & 0xF or 16
            registers = [(hi >> (4 * index)) & 0xF for index in range(nreg)]
            if (lo >> 46) & 1 and flg != 2:
                self.write(PRIM, (lo >> 47) & 0x7FF)
            if flg == 0:
                for _ in range(nloop):
                    for register in registers:
                        if offset + 16 > len(buffer):
                            return
                        a, b = struct.unpack_from("<QQ", buffer, offset)
                        offset += 16
                        self.packed(register, a, b)
            elif flg == 1:
                count = nloop * nreg
                for index in range(count):
                    value = struct.unpack_from("<Q", buffer, offset)[0]
                    offset += 8
                    if registers[index % nreg] not in (0x0E, 0x0F):
                        self.write(registers[index % nreg], value)
                offset += 8 if count % 2 else 0
            else:
                self.image(buffer[offset:offset + nloop * 16])
                offset += nloop * 16

    def packed(self, register: int, lo: int, hi: int) -> None:
        if register == 0x0E:  # A+D
            self.write(hi & 0xFF, lo)
        elif register == RGBAQ:
            colour = (lo & 0xFF) | ((lo >> 32) & 0xFF) << 8 | (hi & 0xFF) << 16 | ((hi >> 32) & 0xFF) << 24
            self.write(RGBAQ, colour | (self.state.get(RGBAQ, 0) & ~0xFFFFFFFF))
        elif register == ST:
            self.write(ST, lo)
            self.state[RGBAQ] = (self.state.get(RGBAQ, 0) & 0xFFFFFFFF) | (hi & 0xFFFFFFFF) << 32
        elif register == UV:
            self.write(UV, (lo & 0x3FFF) | ((lo >> 32) & 0x3FFF) << 16)
        elif register in (XYZF2, XYZ2):
            x, y = lo & 0xFFFF, (lo >> 32) & 0xFFFF
            z = (hi >> 4) & 0xFFFFFF if register == XYZF2 else hi & 0xFFFFFFFF
            kick = (XYZF3 if register == XYZF2 else XYZ3) if (hi >> 47) & 1 else register
            self.write(kick, x | y << 16 | z << 32)
        elif register != 0x0F:
            self.write(register, lo)

    def write(self, register: int, value: int) -> None:
        self.state[register] = value
        if register == PRIM:
            self.batch = None
        if self.frame != self.wanted:
            return
        if register == TRXDIR and value & 3 == 2:
            blit = self.state.get(BITBLTBUF, 0)
            size = self.state.get(TRXREG, 0)
            self.events.append(["move", f"src {blit & 0x3FFF:#06x} dst {(blit >> 32) & 0x3FFF:#06x} "
                                        f"size {size & 0xFFF}x{(size >> 32) & 0xFFF}"])
            self.batch = None
        elif register in VERTEX_KICKS:
            self.vertex(value)

    def image(self, payload: bytes) -> None:
        blit = self.state.get(BITBLTBUF, 0)
        size = self.state.get(TRXREG, 0)
        base = (blit >> 32) & 0x3FFF
        digest = hashlib.sha1(payload).hexdigest()[:8]
        self.image_hashes[base] = digest
        if self.frame == self.wanted:
            self.events.append(["upload", f"dbp {base:#06x} psm {(blit >> 56) & 0x3F:#04x} "
                                          f"size {size & 0xFFF}x{(size >> 32) & 0xFFF} image {digest}"])
            self.batch = None

    def label(self, block: int) -> str:
        return self.image_hashes.get(block, f"@{block:#06x}")

    def vertex(self, value: int) -> None:
        prim = self.state.get(PRIM, 0)
        context = 1 if prim & 0x200 else 0
        registers = {name: self.state.get(address + context, 0)
                     for name, address in zip(CONTEXT_NAMES, CONTEXT_REGISTERS)}
        offset = registers["xyoffset"]
        x = ((value & 0xFFFF) - (offset & 0xFFFF)) / 16
        y = (((value >> 16) & 0xFFFF) - ((offset >> 32) & 0xFFFF)) / 16
        key = (prim, tuple(registers.values()))
        if self.batch is None or self.batch["key"] != key:
            tex0 = registers["tex0"]
            texture = (f"texture {self.label(tex0 & 0x3FFF)} palette {self.label((tex0 >> 37) & 0x3FFF)}"
                       if prim & 0x10 else "untextured")
            self.batch = {"key": key, "prim": prim, "registers": registers, "texture": texture,
                          "rgba": self.state.get(RGBAQ, 0) & 0xFFFFFFFF, "box": [x, x, y, y], "count": 0}
            self.events.append(["draw", self.batch])
        box = self.batch["box"]
        box[0], box[1] = min(box[0], x), max(box[1], x)
        box[2], box[3] = min(box[2], y), max(box[3], y)
        self.batch["count"] += 1

    def lines(self, addresses: bool) -> list[str]:
        out = []
        for kind, event in self.events:
            if kind != "draw":
                out.append(f"{kind} {event}")
                continue
            registers = event["registers"]
            shown = registers if addresses else {
                name: value for name, value in registers.items() if name not in ("tex0",)}
            box = event["box"]
            out.append(
                f"draw prim {event['prim']:#05x} {event['texture']} rgba {event['rgba']:08x} "
                + " ".join(f"{name} {value:#x}" for name, value in shown.items())
                + f" n {event['count']} box {box[0]:.0f}..{box[1]:.0f} x {box[2]:.0f}..{box[3]:.0f}")
        return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    listing = commands.add_parser("list", help="one frame's events in order")
    listing.add_argument("dump", type=Path)
    listing.add_argument("--frame", type=int, default=1)
    diff = commands.add_parser("diff", help="the frame's events of two dumps, diffed")
    diff.add_argument("first", type=Path)
    diff.add_argument("second", type=Path)
    diff.add_argument("--frame", type=int, default=1)
    arguments = parser.parse_args()

    if arguments.command == "list":
        frame = Frame(load(arguments.dump), arguments.frame)
        pmode, dispfb1, dispfb2 = frame.display
        print(f"pmode {pmode:#x} dispfb1 {dispfb1:#x} dispfb2 {dispfb2:#x}")
        for index, line in enumerate(frame.lines(addresses=True)):
            print(index, line)
        return
    # Diffs leave out raw TEX0, whose block addresses differ between layouts;
    # the content labels stand in for it.
    first = Frame(load(arguments.first), arguments.frame).lines(addresses=False)
    second = Frame(load(arguments.second), arguments.frame).lines(addresses=False)
    sys.stdout.writelines(line + "\n" for line in difflib.unified_diff(
        first, second, str(arguments.first), str(arguments.second), lineterm="", n=2))


if __name__ == "__main__":
    main()
