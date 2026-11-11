"""List one ordinary CCS model's vertices: model-space position, normal word,
colour and texture coordinates, part by part.

Use it to see how a flat model is built before fitting it to another screen:
which vertices form a back plane, a disc or a relief, and how its texture
coordinates run across it. Ordinary meshes only, as ccs_scene.py reads them.

Usage: python ccs_model.py <container.ccs> <MDL_name>
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ccs  # noqa: E402
from ccs_scene import object_names, sections  # noqa: E402

FLAG_NO_NORMALS = 0x40
FLAG_NO_COLORS = 0x200
FLAG_NO_COORDINATES = 0x400


def model_vertices(data: bytes, offset: int, size: int):
    """Each part's vertices as (position, normal, colour, coordinates)."""
    payload = data[offset + 8: offset + 8 + size * 4 + 4096]
    _, scale = struct.unpack_from("<If", payload, 0)
    flags, parts, _ = struct.unpack_from("<HHH", payload, 8)
    palette = payload[16]
    cursor = 28
    if palette:
        cursor = (cursor + palette + 3) & ~3
    result = []
    for _ in range(parts):
        _, _, count = struct.unpack_from("<III", payload, cursor)
        cursor += 12
        positions = [tuple(value * scale / 4096 for value in struct.unpack_from("<hhh", payload, cursor + 6 * i))
                     for i in range(count)]
        cursor = (cursor + 6 * count + 3) & ~3
        columns = {}
        for name, flag in (("normal", FLAG_NO_NORMALS), ("colour", FLAG_NO_COLORS)):
            if not flags & flag:
                columns[name] = [payload[cursor + 4 * i: cursor + 4 * i + 4].hex() for i in range(count)]
                cursor += 4 * count
        if not flags & FLAG_NO_COORDINATES:
            columns["coordinates"] = [struct.unpack_from("<hh", payload, cursor + 4 * i) for i in range(count)]
            cursor += 4 * count
        result.append([(positions[i], *(columns.get(name, [None] * count)[i]
                                         for name in ("normal", "colour", "coordinates")))
                       for i in range(count)])
    return flags, scale, result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("container", type=Path)
    parser.add_argument("model")
    args = parser.parse_args()
    data = ccs.decompressed(args.container.read_bytes())
    names = object_names(data)
    for offset, kind, size in sections(data):
        if kind != ccs.SECTION_MODEL or not size:
            continue
        if names[struct.unpack_from("<I", data, offset + 8)[0] - 1] != args.model:
            continue
        flags, scale, parts = model_vertices(data, offset, size)
        print(f"{args.model}: flags 0x{flags:X}, scale {scale}")
        for number, vertices in enumerate(parts):
            print(f"part {number}: {len(vertices)} vertices")
            for index, (position, normal, colour, coordinates) in enumerate(vertices):
                x, y, z = position
                print(f"  {index:3d} {x:8.1f} {y:8.1f} {z:8.1f}  normal {normal} colour {colour} uv {coordinates}")
        return 0
    print(f"{args.container.name} has no ordinary model {args.model}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
