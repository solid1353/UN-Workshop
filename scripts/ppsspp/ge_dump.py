"""Read PPSSPP GE frame dumps (.ppdmp, .ppdmp.zst, or a .zip holding one): list
a dump's texture uploads, VRAM writes, CLUT loads, register changes and draws
in submission order, or diff that list between two dumps.

Each draw shows the GE state it uses, with addresses as the game set them.
Textures, CLUTs and vertices are named by a hash of their contents, and
framebuffers by the order the dump first draws to them, so a diff can leave
addresses out and dumps of different games compare even when their memory
layouts differ."""

from __future__ import annotations

import argparse
import difflib
import hashlib
import re
import struct
import sys
import zipfile
from pathlib import Path

# Python's -I leaves the script's folder off the path.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from savestate import named, snappy_decompress

MAGIC = b"PPSSPPGE"
MIN_VERSION, MAX_VERSION = 2, 6
FIRST_VERSION_WITH_GAME_ID, FIRST_VERSION_WITH_ZSTD = 4, 5
COMMAND = struct.Struct("<BII")

INIT, REGISTERS, VERTICES, INDICES, CLUT, TRANSFERSRC, MEMSET, MEMCPYDEST, MEMCPYDATA, DISPLAY, \
    CLUTADDR, EDRAMTRANS = range(12)
TEXTURE0, FRAMEBUF0, LEVELS = 0x10, 0x18, 8
MINIMUM_SIZES = {INIT: 512 * 4, CLUTADDR: 8, MEMSET: 12, DISPLAY: 12, MEMCPYDEST: 4, EDRAMTRANS: 4,
                 **dict.fromkeys(range(FRAMEBUF0, FRAMEBUF0 + LEVELS), 16),
                 **dict.fromkeys((REGISTERS, VERTICES, INDICES, CLUT, TRANSFERSRC, MEMCPYDATA,
                                  *range(TEXTURE0, TEXTURE0 + LEVELS)), 0)}

# GE opcodes in order; "-" is one ge_constants.h leaves unnamed.
OPCODES = [f"unknown{index:02x}" if name == "-" else name for index, name in enumerate("""
nop vaddr iaddr - prim bezier spline boundingbox jump bjump call ret end - signal finish
base - vertextype offsetaddr origin region1 region2 lightingenable
lightenable0 lightenable1 lightenable2 lightenable3 depthclipenable cullfaceenable
texturemapenable fogenable ditherenable alphablendenable alphatestenable ztestenable
stenciltestenable antialiasenable patchcullenable colortestenable logicopenable -
bonematrixnumber bonematrixdata morphweight0 morphweight1 morphweight2 morphweight3
morphweight4 morphweight5 morphweight6 morphweight7 - - patchdivision patchprimitive
patchfacing - worldmatrixnumber worldmatrixdata viewmatrixnumber viewmatrixdata
projmatrixnumber projmatrixdata tgenmatrixnumber tgenmatrixdata viewportxscale viewportyscale
viewportzscale viewportxcenter viewportycenter viewportzcenter texscaleu texscalev texoffsetu
texoffsetv offsetx offsety - - shademode reversenormal - materialupdate materialemissive
materialambient materialdiffuse materialspecular materialalpha - - materialspecularcoef
ambientcolor ambientalpha lightmode lighttype0 lighttype1 lighttype2 lighttype3
lx0 ly0 lz0 lx1 ly1 lz1 lx2 ly2 lz2 lx3 ly3 lz3 ldx0 ldy0 ldz0 ldx1 ldy1 ldz1 ldx2 ldy2 ldz2
ldx3 ldy3 ldz3 lka0 lkb0 lkc0 lka1 lkb1 lkc1 lka2 lkb2 lkc2 lka3 lkb3 lkc3 lks0 lks1 lks2 lks3
lko0 lko1 lko2 lko3 lac0 ldc0 lsc0 lac1 ldc1 lsc1 lac2 ldc2 lsc2 lac3 ldc3 lsc3 cull
framebufptr framebufwidth zbufptr zbufwidth texaddr0 texaddr1 texaddr2 texaddr3 texaddr4
texaddr5 texaddr6 texaddr7 texbufwidth0 texbufwidth1 texbufwidth2 texbufwidth3 texbufwidth4
texbufwidth5 texbufwidth6 texbufwidth7 clutaddr clutaddrupper transfersrc transfersrcw
transferdst transferdstw - - texsize0 texsize1 texsize2 texsize3 texsize4 texsize5 texsize6
texsize7 texmapmode texshadels texmode texformat loadclut clutformat texfilter texwrap
texlevel texfunc texenvcolor texflush texsync fog1 fog2 fogcolor texlodslope -
framebufpixformat clearmode scissor1 scissor2 minz maxz colortest colorref colortestmask
alphatest stenciltest stencilop ztest blendmode blendfixeda blendfixedb dith0 dith1 dith2
dith3 logicop zwritedisable maskrgb maskalpha transferstart transfersrcpos transferdstpos -
transfersize - vscx vscy vscz vtcs vtct vtcq vcv vap vfc vscv - - - - - -
""".split())]

# The opcodes the INIT command's context saves, in its order, from word 17 on.
CONTEXT_RANGES = ((0x00, 0x02), (0x10, 0x10), (0x12, 0x28), (0x2C, 0x33), (0x36, 0x38),
                  (0x42, 0x4D), (0x50, 0x51), (0x53, 0x58), (0x5B, 0xB5), (0xB8, 0xC3),
                  (0xC5, 0xD0), (0xD2, 0xE9), (0xEB, 0xEC), (0xEE, 0xEE), (0xF0, 0xF6),
                  (0xF8, 0xF9))
CONTEXT_START = 17

# Registers holding memory addresses, which differ between layouts.
ADDRESS_REGISTERS = {"framebufptr", "framebufwidth", "zbufptr", "zbufwidth", "clutaddr",
                     "clutaddrupper", "transfersrc", "transfersrcw", "transferdst", "transferdstw",
                     *(f"texaddr{level}" for level in range(LEVELS)),
                     *(f"texbufwidth{level}" for level in range(LEVELS))}

PRIMITIVES = ("points", "lines", "line_strip", "triangles", "triangle_strip", "triangle_fan",
              "rectangles", "continue")
COMPARISONS = ("never", "always", "equal", "notequal", "less", "lequal", "greater", "gequal")
TEXTURE_FORMATS = ("565", "5551", "4444", "8888", "clut4", "clut8", "clut16", "clut32", "dxt1",
                   "dxt3", "dxt5")
BUFFER_FORMATS = ("565", "5551", "4444", "8888")
BLEND_EQUATIONS = ("add", "subtract", "reverse_subtract", "min", "max", "absdiff")
BLEND_FACTORS = ("srcalpha", "invsrcalpha", "dstalpha", "invdstalpha", "2srcalpha", "2invsrcalpha",
                 "2dstalpha", "2invdstalpha")
BLEND_SOURCES = ("dstcolor", "invdstcolor", *BLEND_FACTORS, "fixa")
BLEND_DESTINATIONS = ("srccolor", "invsrccolor", *BLEND_FACTORS, "fixb")
BLEND_FIXED = 10
STENCIL_OPS = ("keep", "zero", "replace", "invert", "incr", "decr")
INDEX_WIDTHS = ("", "8", "16", "32")
COMPONENT_WIDTHS = ("", "8", "16", "float")
COLOR_FORMATS = {4: "565", 5: "5551", 6: "4444", 7: "8888"}
THROUGH = 1 << 23
INDEX_MASK, MORPH_MASK = 3 << 11, 7 << 18
COMPONENT_SIZES = (0, 1, 2, 4)
COLOR_SIZES = (0, 0, 0, 0, 2, 2, 2, 4)
POSITION_FORMATS = {1: "2b", 2: "2h", 4: "2f"}


def load(path: Path) -> bytes:
    if path.suffix.lower() == ".zip":
        with zipfile.ZipFile(path) as archive:
            names = [name for name in archive.namelist() if name.lower().endswith(".ppdmp")]
            if len(names) != 1:
                raise SystemExit(f"{path}: expected one .ppdmp inside, found {names}")
            return archive.read(names[0])
    data = path.read_bytes()
    if path.suffix == ".zst":
        from compression import zstd

        data = zstd.decompress(data)
    return data


def hash_of(data) -> str:
    return hashlib.sha1(data).hexdigest()[:8]


def vertex_format(vtype: int) -> str:
    parts = ["through" if vtype & THROUGH else "transform"]
    fields = (("tc", COMPONENT_WIDTHS, vtype & 3), ("normal", COMPONENT_WIDTHS, (vtype >> 5) & 3),
              ("pos", COMPONENT_WIDTHS, (vtype >> 7) & 3), ("index", INDEX_WIDTHS, (vtype >> 11) & 3))
    parts += [label + widths[value] for label, widths, value in fields if value]
    if colour := (vtype >> 2) & 7:
        parts.append("col" + COLOR_FORMATS.get(colour, str(colour)))
    if weight := (vtype >> 9) & 3:
        parts.append(f"weight{COMPONENT_WIDTHS[weight]}x{((vtype >> 14) & 7) + 1}")
    if vtype & MORPH_MASK:
        parts.append(f"morph{((vtype >> 18) & 7) + 1}")
    return " ".join(parts)


def through_box(vtype: int, vertices, count: int) -> tuple | None:
    """The x and y range of a through mode draw, or None for what the replayer
    doesn't read either: an indexed, morphed or transformed one."""
    if not vtype & THROUGH or vtype & (INDEX_MASK | MORPH_MASK) or not count or vertices is None:
        return None
    offset, alignment = 0, 1

    def add(size: int, components: int) -> None:
        nonlocal offset, alignment
        if size:
            offset = ((offset + size - 1) & -size) + size * components
            alignment = max(alignment, size)

    add(COMPONENT_SIZES[(vtype >> 9) & 3], ((vtype >> 14) & 7) + 1)
    add(COMPONENT_SIZES[vtype & 3], 2)
    add(COLOR_SIZES[(vtype >> 2) & 7], 1)
    add(COMPONENT_SIZES[(vtype >> 5) & 3], 3)
    size = COMPONENT_SIZES[(vtype >> 7) & 3]
    if not size:
        return None
    add(size, 0)
    position = offset
    add(size, 3)
    stride = (offset + alignment - 1) & -alignment
    if stride * count > len(vertices):
        return None
    points = list(struct.iter_unpack(
        f"<{position}x{POSITION_FORMATS[size]}{stride - position - 2 * size}x", vertices[:stride * count]))
    xs, ys = zip(*points)
    return min(xs), max(xs), min(ys), max(ys)


class Dump:
    """The commands of one dump, walked in the order the replayer runs them."""

    def __init__(self, path: Path):
        data = load(path)
        if data[:len(MAGIC)] != MAGIC or len(data) < 12:
            raise SystemExit(f"{path}: not a PPSSPP GE dump")
        self.path = path
        self.version = struct.unpack_from("<I", data, 8)[0]
        if not MIN_VERSION <= self.version <= MAX_VERSION:
            raise SystemExit(f"{path}: unsupported version {self.version}")
        self.game = ""
        cursor = 12
        if self.version >= FIRST_VERSION_WITH_GAME_ID:
            self.game = data[12:21].split(b"\0", 1)[0].decode("ascii", "replace")
            cursor = 24
        try:
            command_count, pushbuf_size = struct.unpack_from("<II", data, cursor)
            commands, cursor = self.section(data, cursor + 8, command_count * COMMAND.size)
            self.pushbuf, cursor = self.section(data, cursor, pushbuf_size)
        except struct.error:
            raise SystemExit(f"{path}: truncated")
        self.memory = memoryview(self.pushbuf)
        self.commands = list(COMMAND.iter_unpack(commands))
        self.validate()

        self.state = dict.fromkeys(OPCODES, 0)
        self.events: list[tuple[int, str]] = []
        self.frame = 0
        self.drawn = False
        self.hashes: dict[tuple[int, int], str] = {}
        self.batch: dict[str, int] = {}
        self.batch_matrices: dict[str, list[int]] = {}
        self.batch_size = 0
        self.matrices: dict[str, list[int]] = {}
        self.level_images: dict[int, str] = {}
        self.listed_levels: dict[int, tuple] = {}
        self.vertices = self.indices = None
        self.transfer_source = None
        self.memcpy_dest = 0
        self.clut_target = None
        self.pending_clut = None
        self.initial_clut = False
        self.palette = self.palette_address = None
        self.framebuffers: dict[int, int] = {}
        self.depthbuffers: dict[int, int] = {}
        self.walk()

    def section(self, data: bytes, cursor: int, size: int) -> tuple[bytes, int]:
        stored = struct.unpack_from("<I", data, cursor)[0]
        cursor += 4
        blob = data[cursor:cursor + stored]
        if len(blob) != stored:
            raise SystemExit(f"{self.path}: truncated")
        if self.version < FIRST_VERSION_WITH_ZSTD:
            out = snappy_decompress(blob)
        else:
            from compression import zstd

            out = zstd.decompress(blob)
        if len(out) != size:
            raise SystemExit(f"{self.path}: section holds {len(out):#x} bytes, expected {size:#x}")
        return out, cursor + stored

    def validate(self) -> None:
        for index, (kind, size, pointer) in enumerate(self.commands):
            minimum = MINIMUM_SIZES.get(kind)
            if minimum is None:
                raise SystemExit(f"{self.path}: unknown command type {kind:#x} at {index}")
            if pointer > len(self.pushbuf) or size > len(self.pushbuf) - pointer or size < minimum:
                raise SystemExit(f"{self.path}: bad command {index}: type {kind:#x}, "
                                 f"offset {pointer:#x}, size {size:#x}")

    def add(self, line: str) -> None:
        self.events.append((self.frame, line))

    def image(self, pointer: int, size: int) -> str:
        key = (pointer, size)
        if key not in self.hashes:
            self.hashes[key] = hash_of(self.memory[pointer:pointer + size])
        return self.hashes[key]

    def walk(self) -> None:
        commands = iter(enumerate(self.commands))
        for index, (kind, size, pointer) in commands:
            view = self.memory[pointer:pointer + size]
            if kind == INIT and index:
                # Only the first is real, along with the CLUT saved right after it.
                self.add("init ignored")
                if index + 1 < len(self.commands) and self.commands[index + 1][0] == CLUT:
                    next(commands)
            elif kind == INIT:
                self.init(view)
            elif kind == REGISTERS:
                self.registers(view)
            elif kind == VERTICES:
                self.vertices = (pointer, size)
            elif kind == INDICES:
                self.indices = (pointer, size)
            elif kind == CLUTADDR:
                self.clut_target = struct.unpack_from("<2I", view)
            elif kind == CLUT:
                self.clut(pointer, size)
            elif kind == TRANSFERSRC:
                self.transfer_source = view
            elif kind == MEMSET:
                dest, value, length = struct.unpack_from("<3I", view)
                self.add(f"memset dst @{dest:#010x} value {value & 0xFF:#04x} size {length:#x}")
            elif kind == MEMCPYDEST:
                self.memcpy_dest = struct.unpack_from("<I", view)[0]
            elif kind == MEMCPYDATA:
                self.add(f"memcpy dst @{self.memcpy_dest:#010x} size {size:#x} "
                         f"data {self.image(pointer, size)}")
            elif kind == DISPLAY:
                self.display(view)
            elif kind == EDRAMTRANS:
                self.add(f"edramtrans {struct.unpack_from('<I', view)[0]:#x}")
            elif kind >= FRAMEBUF0:
                self.texture(kind - FRAMEBUF0, pointer + 16, size - 16, view)
            else:
                self.texture(kind - TEXTURE0, pointer, size, None)

    def init(self, view) -> None:
        words = struct.unpack_from("<512I", view)
        cursor = CONTEXT_START
        for start, end in CONTEXT_RANGES:
            for opcode in range(start, end + 1):
                self.state[OPCODES[opcode]] = words[cursor] & 0xFFFFFF
                cursor += 1
        self.initial_clut = True
        self.add("init")

    def registers(self, view) -> None:
        self.initial_clut = False
        for op, in struct.iter_unpack("<I", view[:len(view) & ~3]):
            name, data = OPCODES[op >> 24], op & 0xFFFFFF
            if name in ("prim", "bezier", "spline"):
                self.flush_batch()
                self.draw(name, data)
            elif name == "loadclut":
                self.flush_batch()
                self.load_clut(data)
            elif name == "transferstart":
                self.flush_batch()
                self.transfer(data)
            else:
                self.batch_size += 1
                if name.endswith("matrixdata"):
                    self.batch_matrices.setdefault(name, []).append(data)
                else:
                    self.batch.setdefault(name, self.state[name])
                self.state[name] = data
        self.flush_batch()

    def flush_batch(self) -> None:
        """Lists the registers that end the batch changed, and the matrices
        loaded with new values."""
        if not self.batch_size:
            return
        changes = []
        for name, before in self.batch.items():
            if self.state[name] != before:
                mark = "@" if name in ADDRESS_REGISTERS else ""
                changes.append(f"{name}={mark}{self.state[name]:#x}")
        for name, values in self.batch_matrices.items():
            if self.matrices.get(name) != values:
                self.matrices[name] = values
                changes.append(f"{name}={hash_of(struct.pack(f'<{len(values)}I', *values))}")
        self.add(" ".join([f"registers n {self.batch_size}", *changes]))
        self.batch = {}
        self.batch_matrices = {}
        self.batch_size = 0

    def texture_address(self, level: int) -> int:
        state = self.state
        return (state[f"texaddr{level}"] & 0xFFFFF0) | ((state[f"texbufwidth{level}"] << 8) & 0x0F000000)

    def texture(self, level: int, pointer: int, size: int, framebuffer) -> None:
        state = self.state
        # The recorder also sends every other level with an address left over
        # from earlier textures, which no draw reads.
        if level > (state["texmode"] >> 16) & 7:
            return
        image = self.image(pointer, size)
        self.level_images[level] = image
        if framebuffer is None:
            address = self.texture_address(level)
            bufw, detail = state[f"texbufwidth{level}"] & 0xFFFF, ""
        else:
            address, bufw, flags = struct.unpack_from("<IiI", framebuffer)
            detail = f" flags {flags:#x}"
        if self.listed_levels.get(level) == (address, image):
            return
        self.listed_levels[level] = (address, image)
        dimensions = state[f"texsize{level}"]
        self.add(f"{'texture' if framebuffer is None else 'framebuf'} {level} @{address:#010x} "
                 f"{1 << (dimensions & 0xF)}x{1 << ((dimensions >> 8) & 0xF)} "
                 f"{named(TEXTURE_FORMATS, state['texformat'] & 0xF)} bufw {bufw} size {size:#x}"
                 f"{detail} image {image}")

    def clut(self, pointer: int, size: int) -> None:
        loaded = (self.image(pointer, size), size)
        if self.initial_clut and self.clut_target is None:
            self.initial_clut = False
            self.palette, self.palette_address = loaded[0], None
            self.add(f"clut initial size {size:#x} palette {loaded[0]}")
        else:
            self.pending_clut = loaded

    def load_clut(self, data: int) -> None:
        state = self.state
        address = (state["clutaddr"] & 0xFFFFF0) | ((state["clutaddrupper"] << 8) & 0x0F000000)
        blocks = 0x40 if data & 0x7F == 0x40 else data & 0x3F
        detail = f" flags {self.clut_target[1]:#x}" if self.clut_target else ""
        if self.pending_clut:
            self.palette, self.palette_address = self.pending_clut[0], address
        self.add(f"clut load @{address:#010x} blocks {blocks} "
                 f"{named(BUFFER_FORMATS, state['clutformat'] & 3)}{detail} "
                 f"palette {self.pending_clut[0] if self.pending_clut else 'none'}")
        self.pending_clut = self.clut_target = None

    def transfer(self, data: int) -> None:
        state = self.state

        def endpoint(side: str) -> tuple:
            address = state[f"transfer{side}"] & 0xFFFFF0 | (state[f"transfer{side}w"] & 0xFF0000) << 8
            stride = state[f"transfer{side}w"] & 0x7F8
            position = state[f"transfer{side}pos"]
            return address, 0 if stride > 0x400 else stride, position & 0x3FF, (position >> 10) & 0x3FF

        source, source_stride, source_x, source_y = endpoint("src")
        dest, dest_stride, dest_x, dest_y = endpoint("dst")
        width = (state["transfersize"] & 0x3FF) + 1
        height = ((state["transfersize"] >> 10) & 0x3FF) + 1
        bpp = 4 if data & 1 else 2
        digest = "none"
        if self.transfer_source is not None:
            # Only the rectangle: the rest of the source's rows belong to something else.
            rows = hashlib.sha1()
            for row in range(height):
                start = ((source_y + row) * source_stride + source_x) * bpp
                rows.update(self.transfer_source[start:start + width * bpp])
            digest = rows.hexdigest()[:8]
        self.add(f"transfer src @{source:#010x} stride {source_stride} pos {source_x},{source_y} "
                 f"dst @{dest:#010x} stride {dest_stride} pos {dest_x},{dest_y} "
                 f"size {width}x{height} bpp {bpp} data {digest}")
        self.transfer_source = None

    def display(self, view) -> None:
        address, stride, pixel_format = struct.unpack_from("<3I", view)
        if address:
            self.add(f"display @{address:#010x} stride {stride} {named(BUFFER_FORMATS, pixel_format)}")
        else:
            self.add("display off")
        if self.drawn:
            self.frame += 1
            self.drawn = False

    def draw(self, name: str, data: int) -> None:
        self.drawn = True
        state = self.state
        vtype = state["vertextype"]
        vertices = None
        if self.vertices:
            vertices = self.memory[self.vertices[0]:sum(self.vertices)]
        if name == "prim":
            count = data & 0xFFFF
            parts = [f"draw {named(PRIMITIVES, (data >> 16) & 7)} n {count}"]
        else:
            count = 0
            parts = [f"draw {name} {data & 0xFF}x{(data >> 8) & 0xFF}"]
            if name == "spline":
                parts.append(f"type {(data >> 16) & 0xF:#x}")
        parts.append(f"vtype {vtype:#x} {vertex_format(vtype)}")
        if vertices is not None:
            parts.append(f"verts {self.image(*self.vertices)}")
        if self.indices:
            parts.append(f"indices {self.image(*self.indices)}")
        box = through_box(vtype, vertices, count) if name == "prim" else None
        if box:
            parts.append(f"box {box[0]:.0f}..{box[1]:.0f} x {box[2]:.0f}..{box[3]:.0f}")
        clear = state["clearmode"] & 1
        if clear:
            parts.append(f"clear {state['clearmode']:#x}")
        else:
            parts += self.texture_state()
        parts += self.target_state()
        if not clear:
            parts += self.pixel_state()
        self.add(" ".join(parts))
        self.level_images = {}
        self.vertices = self.indices = None

    def texture_state(self) -> list[str]:
        state = self.state
        if not state["texturemapenable"] & 1:
            return ["untextured"]
        dimensions = state["texsize0"]
        format_index = state["texformat"] & 0xF
        levels = ((state["texmode"] >> 16) & 7) + 1
        images = "+".join(self.level_images.get(level, "none") for level in range(levels))
        parts = [f"texture @{self.texture_address(0):#010x} "
                 f"{1 << (dimensions & 0xF)}x{1 << ((dimensions >> 8) & 0xF)} "
                 f"{named(TEXTURE_FORMATS, format_index)} bufw {state['texbufwidth0'] & 0xFFFF} "
                 f"image {images}"]
        if 4 <= format_index <= 7:
            parts.append(f"palette {self.palette or 'none'}")
            if self.palette_address is not None:
                parts.append(f"@{self.palette_address:#010x}")
            parts.append(f"{named(BUFFER_FORMATS, state['clutformat'] & 3)} "
                         f"clutformat {state['clutformat']:#x}")
        parts.append(f"texmode {state['texmode']:#x} texfunc {state['texfunc']:#x} "
                     f"texfilter {state['texfilter']:#x} texwrap {state['texwrap']:#x}")
        return parts

    def target_state(self) -> list[str]:
        state = self.state
        address = state["framebufptr"] & 0x1FFFF0
        number = self.framebuffers.setdefault(address, len(self.framebuffers))
        first, second = state["scissor1"], state["scissor2"]
        return [f"fb#{number}", f"@{0x04000000 | address:#010x}",
                f"stride {state['framebufwidth'] & 0x7FC} "
                f"{named(BUFFER_FORMATS, state['framebufpixformat'] & 3)} "
                f"scissor {first & 0x3FF},{(first >> 10) & 0x3FF}.."
                f"{second & 0x3FF},{(second >> 10) & 0x3FF}"]

    def pixel_state(self) -> list[str]:
        state = self.state
        parts = []
        if state["alphablendenable"] & 1:
            blend = state["blendmode"]
            source, dest = blend & 0xF, (blend >> 4) & 0xF
            parts.append(f"blend {named(BLEND_EQUATIONS, (blend >> 8) & 7)} "
                         f"{named(BLEND_SOURCES, source)} {named(BLEND_DESTINATIONS, dest)}")
            if source == BLEND_FIXED:
                parts.append(f"fixa {state['blendfixeda']:#x}")
            if dest == BLEND_FIXED:
                parts.append(f"fixb {state['blendfixedb']:#x}")
        else:
            parts.append("blend off")
        if state["alphatestenable"] & 1:
            test = state["alphatest"]
            parts.append(f"alpha {COMPARISONS[test & 7]} ref {(test >> 8) & 0xFF:#x} "
                         f"mask {(test >> 16) & 0xFF:#x}")
        else:
            parts.append("alpha off")
        if state["ztestenable"] & 1:
            address = state["zbufptr"] & 0x1FFFF0
            number = self.depthbuffers.setdefault(address, len(self.depthbuffers))
            parts += [f"depth {COMPARISONS[state['ztest'] & 7]} "
                      f"{'nowrite' if state['zwritedisable'] & 1 else 'write'} zb#{number}",
                      f"@{0x04000000 | address:#010x}", f"stride {state['zbufwidth'] & 0x7FC}"]
        else:
            parts.append("depth off")
        if state["stenciltestenable"] & 1:
            test, operations = state["stenciltest"], state["stencilop"]
            parts.append(f"stencil {COMPARISONS[test & 7]} ref {(test >> 8) & 0xFF:#x} "
                         f"mask {(test >> 16) & 0xFF:#x} " + " ".join(
                             named(STENCIL_OPS, (operations >> shift) & 7) for shift in (0, 8, 16)))
        if state["colortestenable"] & 1:
            parts.append(f"colortest {COMPARISONS[state['colortest'] & 3]} "
                         f"ref {state['colorref']:#x} mask {state['colortestmask']:#x}")
        if state["logicopenable"] & 1:
            parts.append(f"logic {state['logicop'] & 0xF}")
        if state["maskrgb"] or state["maskalpha"]:
            parts.append(f"writemask {state['maskrgb']:#x} {state['maskalpha']:#x}")
        return parts

    def header(self) -> str:
        frames = self.events[-1][0] + 1 if self.events else 0
        return (f"version {self.version} game {self.game or 'unknown'} commands {len(self.commands)} "
                f"pushbuf {len(self.pushbuf):#x} frames {frames}")

    def lines(self, frame: int | None) -> list[str]:
        return [line for number, line in self.events if frame is None or number == frame]


def comparable(lines: list[str]) -> list[str]:
    """Leaves out what differs between layouts: address tokens and how many
    register writes a batch took to reach the same state."""
    out = []
    for line in lines:
        line = re.sub(r" [^ ]*@[^ ]*", "", line)
        line = re.sub(r"^registers n \d+", "registers", line)
        if line != "registers":
            out.append(line)
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    listing = commands.add_parser("list", help="the dump's events in order")
    listing.add_argument("dump", type=Path)
    listing.add_argument("--frame", type=int, help="only this frame, from 0; frames end at a "
                         "DISPLAY that follows a draw")
    diff = commands.add_parser("diff", help="the events of two dumps, diffed")
    diff.add_argument("first", type=Path)
    diff.add_argument("second", type=Path)
    diff.add_argument("--frame", type=int)
    arguments = parser.parse_args()

    sys.stdout.reconfigure(errors="backslashreplace")
    if arguments.command == "list":
        dump = Dump(arguments.dump)
        print(dump.header())
        for index, line in enumerate(dump.lines(arguments.frame)):
            print(index, line)
        return
    first = comparable(Dump(arguments.first).lines(arguments.frame))
    second = comparable(Dump(arguments.second).lines(arguments.frame))
    sys.stdout.writelines(line + "\n" for line in difflib.unified_diff(
        first, second, str(arguments.first), str(arguments.second), lineterm="", n=2))


if __name__ == "__main__":
    main()
