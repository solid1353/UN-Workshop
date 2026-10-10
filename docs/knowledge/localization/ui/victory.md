# Victory artwork

## Research coverage

Established: retail NA2 and NUN5 Victory emblem geometry and animation,
win-count artwork, name rectangles, and both battle initialization paths.
Evidence covers native owners, records, and paired screen states.
Open: unexamined callers, indirect consumers, and other animation phases.
Names come from `@annotations/NA2` and `@annotations/NUN5`; addresses are live.
Annotations hold routine detail and fixed-layout fields; owner views are partial.

## Scope and source identity

The retail container identities are listed in
[Standard game file identities](../../game/files/file_identities.md#ccs-research-inputs).
The Battle Results screen belongs to
[Battle Results presentation](battle/battle_results.md).

| Container | NA2 size | NUN5 size |
| --- | ---: | ---: |
| `3EYE/ENDDEMO.CCS` | 74,520 | 79,749 |
| `3EYE/3HAK3PCT.CCS` | 9,978 | 10,947 |
| `3EYE/3SKN3PCT.CCS` | 14,794 | 15,922 |

The canonical NA2 and NUN5 filesystems both contain 78 matching
`3EYE/3???3PCT.CCS` resources. Seventy-four contain exactly one `TEX_name`
visual in both games; the four structural variants `3GUY3PCT`, `3ITC3PCT`,
`3KKS3PCT`, and `3KSM3PCT` contain no `TEX_name` in either game. With resources
paired by object identity rather than internal filename, the only decoded
NA2/NUN5 visual differences in the name-bearing resources are `TEX_name` and,
where present, `TEX_mode1name*` ordinary-awakening labels.

Paired runtime memory contains the Japanese `TEX_name` body at EE
`0x01607140`; its exact 16,384-byte body SHA-256
`1DB17B6335F272F42F7B965742D195C01351900FE831D5BC981C3F2FBFD6DAA0`
matches on-disc `3EYE/3SSV3PCT.CCS`, confirming the Sasuke resource identity.

Two NUN5 name textures have these raster properties:

- `3HAK3PCT.CCS`: NUN5's 256x128 Haku name has nontransparent bounds
  `(4,4)..(116,51)`; the entire right 128 pixels and lower 64 pixels are
  transparent.
- `3SKN3PCT.CCS`: palette index 8 is a faint `(255,255,255,15)` antialias
  shade used by 156 pixels; the visible bounds are `(3,4)..(232,115)`.

## Large WINNER emblem

The large WINNER emblem belongs to `3EYE/ENDDEMO.CCS`, not the resident
win-count sprite renderer. Its atlas is `x\enddemo\tex\enddemo01.bmp`.
The atlas alone does not define its shape or placement:

| Object | NA2 | NUN5 |
| --- | --- | --- |
| `MDL_win` and `MDL_win_f` | four vertices, 120-byte sections | five vertices, 140-byte sections |
| `ANM_end_win01` | 592-byte section | 592-byte section with different transforms |
| `ANM_end_win02` | 872-byte section | 884-byte section including a rotation track |

The first `ANM_end_win01` root translation is `(-111, -15, 77.656845)` in
NA2 and `(-105, -15, 87)` in NUN5. Root rotation changes from `(0, 0, 0)`
to `(0, -10, 0)`; scale keys also differ. The five-vertex mesh and UV data
belong to NUN5's `MDL_win` and `MDL_win_f` pair. `CMP_win` is equivalent
after resolving object IDs.

Object IDs differ between the containers. Resolve mesh object/material
references and animation-controller targets by both TOC filename and object
name: object names alone are not unique. The relevant owners are
`x\enddemo\max\enddemo.max`, `x\enddemo\anm\end_win01.max`, and
`x\enddemo\anm\end_win02.max`.

## Small win-count label

The homologous Victory draw functions call the Winner renderer with the same
logical anchor, X `50` and Y `55`, but the regional renderers construct the
artwork differently.

NA2 `victory_win_count_draw` (`0x00202B50`) draws a fixed `(0,96,32,32)`
prefix at scale `1.2`, any decimal count digits as 32x32 cells, and a fixed
`(32,96,63,32)` suffix. NUN5
`victory_win_count_draw` (`0x00209A70`) instead obtains localized record 0
through `victory_label_rect_get` (`0x003D5070`). The English record
`victory_english_label_rectangles` (`0x005DE860`) is `(1,97,94,30)`.
NUN5 draws that complete rectangle at scale `1.2`, producing display
dimensions `112.8 x 36`, then
places any count digits after it with advance `27.6`. It does not draw NA2's
separate trailing suffix.

NUN5 derives the Winner center X as
`anchor_x + (112.8 - 38.4) / 2`, uses the unchanged Y anchor, and assigns local
offsets `(-112.8 / 2, -36 / 2)`. The resulting left edge remains
`anchor_x - 19.2`; the formula reserves the same digit-cell half-width while
allowing the localized Winner rectangle to own its full dimensions.

## Victory-name rectangle construction

The character-name renderer is split between the resident boot ELF and
`PRG/BTL.BIN`. The NA2 and NUN5 inputs are identified in
[Standard game file identities](../../game/files/file_identities.md).

The homologous resident functions have the same state update, two-part
centering, animation, and draw behavior:

| Annotated routine | NA2 live entry | NUN5 live entry |
| --- | --- | --- |
| `victory_presentation_update` | `0x002020D0` | `0x00208F80` |
| `victory_presentation_draw` | `0x002023D0` | `0x002092A0` |
| `victory_name_draw` | `0x00202FC0` | `0x00209EB0` |

Both draw helpers obtain two `VictoryNameRectangle` records and center their
combined width around the requested X position. Each record is 24 bytes and
holds `u`, `v`, `width`, `height`, `local_x`, `local_y`, `display_width`, and
`display_height`. The shared sprite uses the named fields in
`ProjectedTextGeometryView`. Both parts are submitted, with their local
offsets and display dimensions scaled and their opacity supplied separately.

The entry animation can halve both source and display heights. Mode 1 uses
the upper halves; mode 2 advances each V coordinate to the lower half and
moves the Y anchor by the first halved height times scale. Combined-width
centering happens before this height adjustment.

The regional providers enforce character IDs `0..93` and frame IDs `0..1`:

| Game | Provider | Valid result | Invalid result |
| --- | --- | --- | --- |
| NA2 | `victory_name_rect_get` (`0x0076B9F0`) | Pointer from `victory_japanese_rectangles` (`0x008A5C40`), a 94-by-2 table of prebuilt Japanese records | Null |
| NUN5 | `victory_name_rect_construct` (`0x007832E0`) | Writes a selected template to the destination and returns 1 | Returns 0 without writing the destination |

NUN5 obtains the active locale's width row through `victory_widths_get`
(`0x003D4F80`). `victory_english_widths` (`0x005DE550`) contains 94 eight-byte
`LocalizedVictoryWidths` rows, beginning with the unsigned `first` and
`second` widths. The constructor consumes these with signed halfword loads.
A zero selected width chooses `victory_empty_name_template`; otherwise the
selected frame template receives `width = selected_width - 2`.

| NUN5 template | Live address | U | V | Height | Local X / Y | Initial display dimensions |
| --- | --- | ---: | ---: | ---: | --- | --- |
| `victory_empty_name_template` | `0x008E26A0` | 0 | 0 | 0 | 0 / 0 | 0 / 0; all 24 bytes zero |
| `victory_first_name_template` | `0x008E26C0` | 1 | 1 | 62 | 0 / -31 | 0 / 0 |
| `victory_second_name_template` | `0x008E26E0` | 1 | 65 | 62 | 0 / -31 | 0 / 0 |

| Character | NA2 prebuilt widths | NUN5 English atlas widths | NUN5 constructed widths |
| --- | --- | --- | --- |
| Naruto (ID 1) | 236 / 173 | 156 / 192 | 154 / 190 |
| Classic Tenten (ID 13) and Tenten (ID 66) | 128 / 122 | 160 / 0 | 158 / 0 |

The NA2 examples are `victory_naruto_first` / `victory_naruto_second` and
`victory_tenten_first` / `victory_tenten_second`. Both Tenten IDs share the
same nonempty Japanese pair; NUN5's second frame is the empty template.

## Battle Victory initialization

The battle owners are NA2 `rng_case5_state_update` (`0x0076CC00`) and
NUN5 `battle_victory_state_update`
(`0x00784760`). After the initial animation completes and the resource
worker is inactive, their state-1 initialization creates the character-name
pair. This path is independent of resident `victory_name_draw`.

NA2 reads `victory_japanese_rectangles` directly. NUN5 calls
`victory_name_rect_construct` for each frame with the signed 16-bit character
ID. Both populate `BattleVictoryNameView.first_name` and `second_name`;
the view identifies only the name portion of the larger scene owner.

Both then derive float display dimensions from the source rectangles and
apply the same centering: first `local_x` gains `-(w0 + w1) / 2`, and second
`local_x` gains `w0 - (w0 + w1) / 2`. The centering code is identical in both
games. Thus the Japanese Tenten pair centers 128 + 122 pixels, while the
English pair centers 158 + 0 pixels. The difference comes from the
per-character frame pair; both use the same screen-coordinate formula.
