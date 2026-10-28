# NA2 memory-card icon

## Research coverage

Established from the retail NA2 `ICON.BIN`: header, all triangle records,
the single constant shape key, complete RLE texture, sheet UVs and sector
padding. The resident writer's background and lighting tables are identified.
Open: nothing.

## Source and extent

The source is `DATA/DATA.CVM` member `ICON.BIN`. Its SHA-256 is
`80D7F62704FC9F59DEF83ED8AF68C0A26609215C2C398F2CA2EBBB99057CF017`.
The member is `0xF000` bytes; its complete icon occupies `0xE920` bytes,
followed by `0x6E0` bytes of `0xFF`. The card writer copies only the icon
extent to `icon00.icn`; see [Save data](../save_data.md#on-card-files-and-visible-slot-model).
The encrypted-CVM reader resolves the member at inner ISO offset `0x291000`;
with the `0x1800`-byte CVM header, its member bytes start at CVM offset
`0x292800`. Ordinary member bytes are unencrypted; the reader's hash agrees
with the extracted member above.
The reusable reader is [ps2_icon.py](../../../../scripts/media/ps2_icon.py).

## Header and geometry

All multibyte values are little-endian. The header occupies `0x14` bytes.

| Offset | Type | Retail value | Interpretation |
| --- | --- | --- | --- |
| `0x00` | u32 | `0x00010000` | Icon format magic |
| `0x04` | u32 | 1 | Shape count |
| `0x08` | u32 | `0x0F` | Flags: texture present (`0x04`), RLE (`0x08`) |
| `0x0C` | f32 | 1.0 | Header scalar |
| `0x10` | u32 | 1,302 | Vertex count, forming 434 independent triangles |

Geometry is `0x0014..0x7A23`: 1,302 records of 24 bytes. Each record has
one signed-int16 XYZ position and a fourth 16-bit component (8 bytes),
one signed-int16 XYZ normal and a fourth 16-bit component (8 bytes),
signed-int16 UV (4 bytes), then RGBA bytes (4 bytes). Positions, normals
and UVs use 12 fractional bits. Consecutive groups of three records form
triangles; no separate index buffer exists. Position bounds are
X `[-1.99755859375, 2.033447265625]`,
Y `[-2.90673828125, -0.083984375]`, and
Z `[-1.961181640625, 2.064453125]`.

The geometry is the rolled scroll, extended sheet, handles and detached ink
marks. Most vertex colors are white; other records provide gray/lilac
modulation. Keeping the texture alone does not preserve all shading: normals
and vertex colors are separate inputs.

## Shape key

At `0x7A24`, the 20-byte animation header is `(u32 tag=1,
u32 frame_length=10, f32 speed=10.0, u32 play_offset=0,
u32 sequence_count=1)`. At `0x7A38`, the sequence has shape ID 0,
key count 1, and one `(f32 time=0.0, f32 weight=1.0)` key.
There are no changing poses: the only shape remains at full weight.
The key block ends at `0x7A48`.

## Texture and UV layout

The u32 at `0x7A48` is the compressed byte count, `0x6ED4` (28,372).
The stream at `0x7A4C..0xE91F` expands to exactly 16,384 words:
a row-major 128 by 128 ABGR1555 texture, with red in bits 0..4,
green in 5..9, blue in 10..14, and alpha in bit 15. Every retail alpha
bit is set. Five-bit channels can be displayed as `component * 255 / 31`.

The stream consists of signed 16-bit controls: positive controls repeat
the next pixel word that many times; negative controls copy that many
following literal pixel words. NA2 uses 7,093 positive-control packets
and no literal packets. The stream consumes the entire declared size and
ends exactly at the card-file boundary. The signed-control interpretation
is also implemented by the primary
[HDLGameInstaller reader](https://github.com/ps2homebrew/HDLGameInstaller/blob/main/IconLoader.c).

Zero-based triangles 152..199 cover the front sheet in eight columns,
each divided across three rows. Their U boundaries,
in texels (`U * 128`), are `10, 21, 33, 49, 59, 71, 84, 96, 110`.
V boundaries are `0.96875, 2.96875, 36, 38.96875`.
The middle band shows the printed face. The old printed pixels occupy
X 19..106 and Y 3..36. Unprinted sheet texels are ABGR1555 color
`0xF3BE`, displayed as RGB `(246,238,230)` with integer expansion.
The atlas below this sheet area contains the scroll's wood grain, dark
wrapping, green region and end/fastener textures. The entire atlas must
not be replaced by one flat logo image.
Increasing V runs toward the top of the displayed sheet, so upright new
lettering must be vertically flipped when placed into this atlas.

## Retail background and lighting

`card_write_icon_sys` (`0x001C2680`) copies four resident tables to the
fresh `icon.sys`. GhidrAssist live decompilation and table bytes establish
these values; vector W values are all zero.

| Annotated table | Address | `icon.sys` offset | Values |
| --- | --- | --- | --- |
| `card_icon_background_corners` | `0x003FBB40` | `0x10` | Four unsigned-int RGBA vectors `(16,16,16,0)` |
| `card_icon_light_directions` | `0x003FBB80` | `0x50` | `(0.5,0.5,0.5)`, `(0,-0.4,-0.1)`, `(-0.5,-0.5,0.5)` |
| `card_icon_light_colors` | `0x003FBBB0` | `0x80` | `(0.3,0.3,0.3)`, `(0.5,0.33,0.2)`, `(0.14,0.14,0.38)` |
| `card_icon_ambient_color` | `0x003FBBE0` | `0xB0` | `(0.3,0.3,0.3)` |

The writer sets the transparency field at `icon.sys+0x0C` to `0x60`.
