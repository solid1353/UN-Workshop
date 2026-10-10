# Command Chart and Practice title layouts

## Research coverage

Established with high confidence: retail NA2 (`SLPS-25837`) and NUN5 title
ownership, compared origins, fit denominators and thresholds, and separation
from Practice explanations. Open: strings, callers and animation phases outside
the compared states. Names come from `@annotations/NA2` and
`@annotations/NUN5`; their comments hold per-routine details. Addresses are live.

Related owners: [Renderer metrics](../renderer_metrics.md) for boxed
measurement and glyph metrics, and [Practice Font layouts](practice.md) for
explanation wrapping.

## Command Chart and Practice title boxes

`command_list_draw` draws Practice titles (NA2 BTL `0x00878860`; NUN5 BTL
`0x00894FA0`); `move_chart_draw` draws Command Chart titles (NA2 BTL
`0x0087A740`; NUN5 BTL `0x00896EB0`). Each title precedes its row's explanation
or relationship content.

NUN5 title rows share shrink-only fitting through
`ui_draw_paragraph_current_context` (ELF `0x00387EC0`) and
`font_draw_aligned_block`, but have different container geometry. The bounded
comparison records establish:

| Content | X | Y | Width | Height |
| --- | ---: | --- | ---: | ---: |
| Command Chart title | `28` | `17/117/217` | `288` | `20` |
| Practice title | `32` | `14/114/214` | `352` | `20` |
| Practice explanation | `40` | `42/142/242` | `364` | `48` |

Practice explanations use vertical alignment `1` and remain a separate draw
family; their box does not determine title fitting.

## Quotation delimiters and color controls

The compared long-title right-edge difference comes from the fit denominator
rather than a container offset. NUN5 `font_measure_markup` measures each raw
byte-`0x40` quotation delimiter with the 14-unit `@` metric;
`font_decode_glyph` renders it as a visible quotation mark. NA2 lacks this
delimiter remap, and its ordinary ASCII quotation mark advances 9 units.

Move titles may also contain renderer-consumed color controls. NUN5 English
`konohamaru_moveset_title` (TEXTENG `0x00904FD0`) is exactly
`<BLACK>Charge! Konohamaru <color0808C0>Ninja Squad<BLACK>!`.
NUN5 `font_classify_token` and `font_draw_markup` consume `<BLACK>`, `<WHITE>`,
`<RED>`, and six-digit `<colorRRGGBB>` controls without drawing them, so they
add no visible width. This does not imply zero measured width: the measurement
path can retain the closing `>` of a named control after skipping its prefix.
