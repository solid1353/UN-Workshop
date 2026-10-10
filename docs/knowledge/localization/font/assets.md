# Font assets

## Research coverage

Established: all five retail NA2 (`SLPS-25837`) font resources, their loading,
selection, descriptors, glyph cells and palettes; GRF4 ruby behavior; and the
NUN5 GF4/GF4C cell and palette differences. Open: meanings of every descriptor
flag. Static comparisons establish data differences, not rendered appearance.
Routine, field and data names come from `@annotations/NA2`; addresses are live.

## Resident loader and auxiliary ruby atlas

Retail file identities are owned by
[Standard game file identities](../../game/files/file_identities.md).

`font_load_assets` (`0x00186050`) loads the complete five-file family through
`font_register_resource` (`0x00184840`). `font_select_face` (`0x00186510`)
selects SF1 plus SF1C for mode 0 and GF4 plus GF4C for nonzero mode. Raster
and palette selection stay paired; GRF4 remains a separate ruby atlas.

`font_load_resource` (`0x00184100`) routes type 1 to `font_parse_raster`
(`0x00184240`) and type 2 to `font_parse_palette` (`0x00184630`).
`FontResource.raster` owns the raster asset; `FontResource.palette` holds the
raw companion record and `FontResource.clut` its render-side CLUT object.
`font_bind_palette` (`0x00189860`) installs the raw record in
`FontAssetRendererView.palette` and selects the shared CLUT. The binary layouts
are named in `FontResourceHeader`, `FontRasterAsset`, `FontRasterDescriptor`
and `FontPaletteRecord`; parser comments retain the file-layout details.

| Asset family | Descriptors / entries | Content |
| --- | ---: | --- |
| GF4, SF1 | Two raster descriptors each | Selectable font rasters and metrics |
| GF4C, SF1C | 16 RGBA entries each | Palette for the matching raster |
| GRF4 | One descriptor, 167 glyphs, 334 two-byte-code map records | 8×8 ruby cells; 32 packed 4-bpp bytes per glyph |

`FontAssetRendererView.ruby` retains GRF4 independently of the selected face.
Its only examined renderer path is `font_decode_ruby_glyph` (`0x00186C30`),
reached from `font_draw_text` (`0x00188140`) when inline markup enters the
annotation arm after a pipe character. This arm requires bit 0 of
`FontDrawState.render_flags`; otherwise the annotation is skipped through `>`.
The renderer counts two-byte annotation glyphs through the closing `>`, centers
their aggregate width over the base-text span in horizontal layout (or beside
it in vertical layout), and resolves each glyph through the GRF4 code map.
GRF4 therefore supplies the small ruby/furigana annotation atlas.

GRF4's parsed counts account for its complete 6,756-byte file, with no
unexplained trailer.

| Resource | Retail size | Loader type | Confirmed resident use |
| --- | ---: | ---: | --- |
| `GF4.BIN` | 906,678 | 1 | Nonzero-mode selectable font rasters and metrics |
| `GF4C.BIN` | 104 | 2 | GF4's 16-entry RGBA CLUT |
| `GRF4.BIN` | 6,756 | 1 | 8×8 inline ruby/annotation glyphs |
| `SF1.BIN` | 103,046 | 1 | Mode-0 selectable font rasters and metrics |
| `SF1C.BIN` | 104 | 2 | SF1's 16-entry RGBA CLUT |

The semantic names of every type-1 descriptor flag remain unresolved; observed
branches establish only the behavior recorded in the parser annotations.

## Retail NA2 10x22 baseline

Retail NA2 contains a coherent 10x22 bitmap font with 157
cells and complete printable-ASCII coverage: 95 of 95 semantic slots exist and
94 of 94 non-space slots contain visible raster data. Its median visible glyph
box is 6x14 pixels, with median top 4 and bottom 17.

NA2's native `font_decode_secondary_byte` (`0x001873E0`) selects cell `107`
for byte `0xAE`, the halfwidth small katakana yo (`ョ`), rather than the
Windows-1252 registered sign. NUN5's GF4 raster has the registered sign
at cell `142`, with metric bytes `00 04 00 03`, and the middle dot at cell
`151`, with metric bytes `05 09 04 06`. The middle dot's Windows-1252 byte
`0xB7` selects NA2 secondary cell `116`. These are static decoder and
raster observations.

## NA2 and NUN5 cell and palette differences

The two GF4 rasters do not share cell semantics throughout their first 123
cells: NUN5 cells `59..64` and `91..94` are blank or have different semantics
from the NA2 cells at the same indices, and NUN5 stores the at-sign in cell
`63` while NA2 printable ASCII addresses cell `32`.

Retail NA2's primary GF4 raster uses palette index 15 for 265,344 of 1,746,272
pixels (`15.194884%`). NA2's GF4C maps index 15 to opaque white, while NUN5's
maps it to black. The same NA2 raster uses palette indices 13 and 14 zero times.

Renderer math belongs to [Renderer metrics](renderer_metrics.md); screen
placement belongs to the screen layout documents, starting with
[Shared Font style](screen_layouts/shared_style.md).
