# Font renderer metrics and spacing

Retail NA2 (`SLPS-25837`) and NUN5 secondary-font geometry, tracking, spacing,
measurement, and selected-row behavior.

## Research coverage

Established: secondary output height, selected-row displacement, tracking,
ordinary-space advance, boxed widths and horizontal leading-bearing scaling.
Open: NUN5 measurement paths outside the examined secondary-font callers;
representative labels do not establish every markup or vertical-writing path.
Routine and field names come from `@annotations/NA2` and `@annotations/NUN5`;
their comments hold code-level detail, and all cited addresses are live.

Raster and palette findings belong to [Font assets](assets.md); screen-specific
placement belongs to the screen layout documents, starting with
[Shared Font style](screen_layouts/shared_style.md).

## Glyph geometry

The normal `font_draw_glyph` quad uses `FontDrawState.output_width` for both
axes in NA2 (`0x00187CC0`). NUN5's counterpart (`0x001891A0`) uses
`RunningHelpFontView.output_width` for X and `output_height` for Y, multiplied
by `horizontal_scale` and `vertical_scale` respectively. Both use the inclusive
right endpoint one unit before the nominal right edge.

| Secondary output dimensions | NA2 nominal quad extent | NUN5 nominal quad extent at unit scales |
| --- | --- | --- |
| 24 x 28 | 24 x 24 | 24 x 28 |

The cross-game difference is specifically secondary vertical extent.
NA2 `font_decode_glyph` (`0x00186F90`) copies the cell into a padded texture;
`font_draw_glyph` retains `output_height` for its V extent, including
transparent rows beyond the ink. When texture and quad heights match, an ink
row maps to one local Y unit. Centering the whole quad or the cell's line
advance does not by itself center visible letters.

`FontGlyphMetrics.left_margin`, `top_margin`, `right_margin` and
`bottom_margin` hold the corresponding transparent margins minus one,
clamped to zero. Their meaning differs from the whole cell's dimensions.

The compared NUN5 cells do not become heavier when mapped through retail NA2's
palette. Across 85 cells and 23,800 source samples, alpha mass changes by a
ratio of `0.993762`, making it fractionally lighter. The observed height deficit
comes from quad geometry, not palette weight.

## Native selected-row offset

For a selected row, NA2 `ui_draw_selected_text` (`0x00379040`) draws the gray
shade at the caller origin, then the red foreground one local X unit left and
two local Y units up. NUN5 `ui_draw_selected_boxed_text` (`0x00389B30`)
enables shadow state and draws the foreground with the input origin and
rectangle unchanged. The selected-row jump is native NA2 behavior and is
independent of font metrics or caller positioning.

## Tracking and ordinary spaces

`font_select_face` initializes secondary tracking to -1.0 in NA2
(`0x00186510`) and 0.0 in NUN5 (`0x001878E0`). NUN5 also initializes both
axis scales to 1.0 and `horizontal_space_extra` to 0.0. Line spacing is a
separate quantity: `FrontendFontSpacingView.extra_spacing` names the same
field as the renderer views' `line_extra`.

Horizontal ordinary ASCII-space advance is owned by NA2 `font_draw_text`
(`0x00188140`) and NUN5 `font_draw_markup` (`0x00189640`):

| Game | One-byte ordinary-space advance | Native secondary value |
| --- | --- | ---: |
| NA2 | `cell_width + tracking * 0.5` | 13.5 |
| NUN5 | `horizontal_scale * (horizontal_space_extra + cell_width + tracking * 0.5 - 6)` | 8 |

The secondary cell width is 14 units. NUN5's zero tracking adds half a unit
per visible glyph relative to NA2, while its narrower spaces compensate most
of that expansion. NA2's inline-markup half-space advances half the cell
dimension on the selected axis; it is a separate path from ordinary spaces.

## Boxed measurement and leading bearings

With secondary tracking zero, NA2's trimmed visible-glyph widths match NUN5.
The remaining ordinary-space difference gives the equivalent NUN5 width:

```text
NA2 width at zero tracking - 6 * ordinary ASCII space count
```

For `Ultimate Jutsu Prep`, NA2 returns 190; subtracting 12 for two spaces gives
NUN5's exact logical width 178 and shrink scale `128 / 178 = 0.7191011236`.

A separate difference affects fitted glyph origins. With metrics enabled and
a metrics table present, `font_decode_glyph` subtracts `left_margin` directly
from NA2's `glyph_x`; NUN5's counterpart (`0x00188270`) subtracts
`left_margin * horizontal_scale`. Both retain `right_margin` as
`trailing_margin` for subsequent advance. Without the metric gate, the
trailing margin is zero.

The missing horizontal multiply explains the fitted-label origin and span
difference without implicating raster data, palette or the width formula.
Vertical and alternate-glyph paths are separate.
