"""Read PS2 memory-card icon geometry, animation keys and 16-bit textures.

No source or icon files are modified. Positions, normals and UVs use 12
fractional bits; each consecutive three vertices form an independent triangle.
"""
from __future__ import annotations

import struct
from dataclasses import dataclass


@dataclass
class Icon:
    shapes: int
    flags: int
    vertices: list[dict]
    animation: tuple
    sequences: list[tuple]
    texture_offset: int
    texture_end: int
    pixels: list[int]


def decode(data: bytes) -> Icon:
    magic, shapes, flags, scale, count = struct.unpack_from('<5I', data)
    if magic != 0x10000 or not 1 <= shapes <= 16 or count % 3:
        raise ValueError('Invalid PS2 icon header')
    vertices = []
    offset = 20
    for _ in range(count):
        positions = []
        for _ in range(shapes):
            positions.append(tuple(v / 4096 for v in struct.unpack_from('<3h', data, offset)))
            offset += 8
        nx, ny, nz, _, u, v, r, g, b, a = struct.unpack_from('<3hH2h4B', data, offset)
        offset += 16
        vertices.append(dict(positions=positions, normal=(nx/4096, ny/4096, nz/4096),
                             uv=(u/4096, v/4096), color=(r,g,b,a)))
    animation = struct.unpack_from('<IIfII', data, offset)
    if animation[0] != 1:
        raise ValueError('Invalid animation tag')
    offset += 20
    sequences = []
    for _ in range(animation[4]):
        shape, keys = struct.unpack_from('<2I', data, offset)
        offset += 8
        values = [struct.unpack_from('<2f', data, offset + i*8) for i in range(keys)]
        offset += keys*8
        sequences.append((shape, values))
    texture_offset = offset
    if not flags & 4:
        pixels = [0xffff]*16384
    elif flags & 8:
        length, = struct.unpack_from('<I', data, offset)
        offset += 4
        end = offset + length
        if end > len(data) or length % 2:
            raise ValueError('Invalid compressed texture length')
        pixels = []
        while offset < end:
            run, = struct.unpack_from('<h', data, offset)
            offset += 2
            if run > 0:
                if offset + 2 > end:
                    raise ValueError('Truncated repeated pixel')
                pixel, = struct.unpack_from('<H', data, offset)
                offset += 2
                pixels.extend([pixel]*run)
            elif run < 0:
                size = -run*2
                if offset + size > end:
                    raise ValueError('Truncated literal pixels')
                pixels.extend(struct.unpack_from(f'<{-run}H', data, offset))
                offset += size
            if len(pixels) > 16384:
                raise ValueError('Texture exceeds 128 by 128 pixels')
        if len(pixels) != 16384:
            raise ValueError('Texture does not fill 128 by 128 pixels')
    else:
        pixels = list(struct.unpack_from('<16384H', data, offset))
        offset += 32768
    return Icon(shapes, flags, vertices, animation, sequences, texture_offset, offset, pixels)


def rgb(pixel: int) -> tuple[int, int, int]:
    return tuple(((pixel >> shift) & 31)*255//31 for shift in (0,5,10))


def encode_rle(pixels: list[int]) -> bytes:
    """Deterministic signed-word RLE; only returns bytes, never writes a file."""
    result = bytearray()
    i = 0
    while i < len(pixels):
        end = i+1
        while end < len(pixels) and pixels[end] == pixels[i] and end-i < 32767:
            end += 1
        if end-i >= 2:
            result += struct.pack('<hH', end-i, pixels[i])
            i = end
        else:
            end = i+1
            while end < len(pixels) and end-i < 32767:
                if end+1 < len(pixels) and pixels[end] == pixels[end+1]:
                    break
                end += 1
            result += struct.pack('<h', i-end)
            result += struct.pack(f'<{end-i}H', *pixels[i:end])
            i = end
    return bytes(result)
