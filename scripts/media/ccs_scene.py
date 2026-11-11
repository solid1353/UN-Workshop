"""Report how far each flat CCS model reaches across the screen under its scene camera.

For each container this lists its cameras' frame-0 position, Euler rotation and field
of view, and every flat ordinary model with its model-space bounds, the U/V span of its
texture coordinates in texels (a span of a few texels means a near-uniform sample),
frame-0 placement from each animation that keys its object, and the horizontal screen
range in 512-wide logical units under the camera of the same animation group.

Limits: ordinary meshes only (packed, property and topology meshes are skipped);
frame-0 keys only; parent chains are ignored; Euler angles are applied as Z*Y*X,
which only matters for compound rotations.

Usage: python ccs_scene.py [--min-extent N] <container.ccs>...
"""

from __future__ import annotations

import argparse
import math
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ccs  # noqa: E402

SECTION_OBJECT = 0xCCCC0100
SECTION_ANIMATION = 0xCCCC0700
KEY_CAMERA = 0xCCCC0503
KEY_OBJECT = 0xCCCC0102


def f32(word: int) -> float:
    return struct.unpack("<f", struct.pack("<I", word))[0]


def sections(data: bytes):
    """Each section's offset, type and readable payload word count."""
    cursor = 0
    while cursor + 8 <= len(data):
        kind, size = struct.unpack_from("<II", data, cursor)
        total = ccs.section_total_size(data, cursor, kind, size)
        yield cursor, kind, min(size, (total - 8) // 4)
        cursor += total


def object_names(data: bytes) -> list[str]:
    for offset, kind, _ in sections(data):
        if kind == ccs.SECTION_TOC:
            return ccs.parse_toc(data, offset)[2]
    raise ValueError("CCS has no TOC section")


def model_bounds(data: bytes, offset: int, size: int):
    """Bounds and texture coordinates of an ordinary model, or None."""
    payload = data[offset + 8: offset + 8 + size * 4 + 4096]
    _, scale = struct.unpack_from("<If", payload, 0)
    flags, parts, _ = struct.unpack_from("<HHH", payload, 8)
    palette = payload[16]
    cursor = 28
    if palette:
        cursor = (cursor + palette + 3) & ~3
    if (flags >> 1) & 7 or flags & 0x804:
        return None
    low, high, coords = [math.inf] * 3, [-math.inf] * 3, set()
    for _ in range(parts):
        _, _, count = struct.unpack_from("<III", payload, cursor)
        cursor += 12
        for index in range(count):
            vertex = struct.unpack_from("<hhh", payload, cursor + 6 * index)
            for axis in range(3):
                value = vertex[axis] * scale / 4096
                low[axis] = min(low[axis], value)
                high[axis] = max(high[axis], value)
        cursor = (cursor + 6 * count + 3) & ~3
        for bit in (0x40, 0x200):
            if not flags & bit:
                cursor += 4 * count
        if not flags & 0x400:
            coords.update(struct.unpack_from("<hh", payload, cursor + 4 * i) for i in range(count))
            cursor += 4 * count
    return low, high, coords


def _first_vector(words, index, mode):
    if mode == 1:
        return [f32(w) for w in words[index:index + 3]], index + 3
    if mode in (2, 0x12):
        return [f32(w) for w in words[index + 2:index + 5]], index + 1 + words[index] * 4
    return None, None


def animation_keys(words):
    """Frame-0 camera keys by camera ID and object keys by object ID."""
    keys = {}
    index = 3
    while index < len(words):
        tag, length = words[index], words[index + 1]
        body = words[index + 2:index + 2 + length]
        flags = body[1] if len(body) > 1 else 0
        if tag == KEY_CAMERA:
            position, cursor = _first_vector(body, 2, flags & 7)
            rotation, cursor = (_first_vector(body, cursor, (flags >> 3) & 7)
                                if cursor is not None else (None, None))
            fov = f32(body[cursor]) if cursor is not None and (flags >> 6) & 7 == 1 else None
            keys.setdefault(body[0], ("camera", position, rotation, fov))
        elif tag == KEY_OBJECT:
            position, cursor = _first_vector(body, 2, flags & 7)
            mode = (flags >> 3) & 7
            # An absent rotation channel (mode 0) leaves the scale channel next.
            if cursor is None or mode not in (0, 1, 2):
                rotation, cursor = None, None
            elif mode == 0:
                rotation = None
            else:
                rotation, cursor = _first_vector(body, cursor, mode)
            scale, _ = (_first_vector(body, cursor, (flags >> 6) & 7)
                        if cursor is not None else (None, None))
            keys.setdefault(body[0], ("object", position, rotation, scale))
        index += 2 + length
    return keys


def _rotation(angles):
    x, y, z = (math.radians(a) for a in angles)
    rx = [[1, 0, 0], [0, math.cos(x), -math.sin(x)], [0, math.sin(x), math.cos(x)]]
    ry = [[math.cos(y), 0, math.sin(y)], [0, 1, 0], [-math.sin(y), 0, math.cos(y)]]
    rz = [[math.cos(z), -math.sin(z), 0], [math.sin(z), math.cos(z), 0], [0, 0, 1]]

    def mul(a, b):
        return [[sum(a[r][k] * b[k][c] for k in range(3)) for c in range(3)] for r in range(3)]

    return mul(rz, mul(ry, rx))


def _apply(matrix, vector):
    return [sum(matrix[r][k] * vector[k] for k in range(3)) for r in range(3)]


def screen_range(low, high, position, rotation, scale, camera):
    """Horizontal logical range of a box's corners; a camera looks down its -Z axis."""
    _, cam_position, cam_rotation, fov = camera
    model = _rotation(rotation or (0, 0, 0))
    view = _rotation(cam_rotation)
    focal = 512 / (2 * math.tan(math.radians(fov) / 2))
    scale = scale or (1, 1, 1)
    xs = []
    for x in (low[0], high[0]):
        for y in (low[1], high[1]):
            for z in (low[2], high[2]):
                world = _apply(model, (x * scale[0], y * scale[1], z * scale[2]))
                relative = [world[k] + position[k] - cam_position[k] for k in range(3)]
                local = [sum(view[k][r] * relative[k] for k in range(3)) for r in range(3)]
                if -local[2] > 1:
                    xs.append(focal * local[0] / -local[2])
    return (min(xs), max(xs)) if xs else None


def report(path: Path, min_extent: float) -> None:
    data = ccs.decompressed(path.read_bytes())
    names = object_names(data)
    objects, bounds, keys = {}, {}, {}
    for offset, kind, size in sections(data):
        if not size:
            continue
        words = struct.unpack_from("<%dI" % size, data, offset + 8)
        if kind == SECTION_OBJECT:
            objects[words[0]] = words[2]
        elif kind == ccs.SECTION_MODEL:
            result = model_bounds(data, offset, size)
            if result:
                bounds[words[0]] = result
        elif kind == SECTION_ANIMATION:
            animation = names[words[0] - 1]
            for key_id, value in animation_keys(words).items():
                key = names[key_id - 1] if value[0] == "object" else key_id
                keys.setdefault(key, []).append((animation, value))
    cameras = [(names[k - 1], a, v) for k, rows in keys.items() if isinstance(k, int)
               for a, v in rows if v[0] == "camera" and None not in v[1:]]
    print(f"=== {path.name}")
    for name, animation, (_, position, rotation, fov) in cameras:
        print(f"camera {name} in {animation}: position {position} rotation {rotation} fov {fov}")
    for object_id, model_id in objects.items():
        if model_id not in bounds:
            continue
        low, high, coords = bounds[model_id]
        span = [max(c[i] for c in coords) - min(c[i] for c in coords) for i in range(2)] if coords else [0, 0]
        extent = [high[k] - low[k] for k in range(3)]
        if sorted(extent)[0] >= 0.02 * max(extent) or max(extent) < min_extent:
            continue
        name = names[object_id - 1]
        print(f"  {name} -> {names[model_id - 1]} bounds {[round(v, 1) for v in low]}.."
              f"{[round(v, 1) for v in high]} texture span {span[0]}x{span[1]}")
        for animation, (_, position, rotation, scale) in keys.get(name, []):
            if position is None:
                continue
            for cam_name, cam_animation, camera in cameras:
                group = cam_animation.replace("_ca", "")
                if len(cameras) > 1 and cam_animation != animation and group not in animation:
                    continue
                reach = screen_range(low, high, position, rotation, scale, camera)
                if reach:
                    print(f"     {animation} at {[round(v, 1) for v in position]} with {cam_name}:"
                          f" screen X {reach[0]:.0f}..{reach[1]:.0f}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--min-extent", type=float, default=400.0)
    parser.add_argument("containers", nargs="+", type=Path)
    args = parser.parse_args()
    for path in args.containers:
        report(path, args.min_extent)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
