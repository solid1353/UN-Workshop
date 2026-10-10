# Practice Font layouts

## Research coverage

Established: retail NA2 (`SLPS-25837`) and NUN5 Practice explanation,
Settings headings, Jutsu titles and completed-move geometry and ownership.
Open: strings, callers and animation phases outside the compared states.
MCP exposes the Jutsu title tails; icon callback branches require the preserved
live listing. Names come from `@annotations/NA2` and `@annotations/NUN5`.
All addresses below are live; per-routine details belong to those annotations.

Related owners: [Renderer metrics](../renderer_metrics.md),
[Command Chart and Practice title layouts](command_and_practice_titles.md), and
[Battle and Practice settings presentation](../../ui/battle/settings_presentation.md).

## Practice explanation mixed-text wrapping

`command_list_draw` (NA2 BTL `0x00878860`; NUN5 BTL `0x00894FA0`)
draws the Practice explanation separately from the title immediately before it.
NA2 draws successive text and icon pieces. NUN5 assembles one bounded mixed
text/tag string, installs `command_list_icon_measure` and
`command_list_icon_draw` for this draw, and wraps the complete string. It
restores the default callbacks and clears the temporary icon-object bindings
afterwards.

The NUN5 `command_list_icon_tags` map covers all 13 Practice controller tokens:
D-pad directions, Circle, Triangle, Square, Cross, plus, L1, R1, L2 and R2.
Both games use their native `command_icon_rectangles` and sprite drawing.
NUN5's callbacks select the caller's primary or secondary icon object and
apply token-specific Y offsets, so text measurement and icon drawing must
share the same callback map and object bindings.

## Practice Settings left-column completion

Paired Practice Settings states select `Attack` and `Extra Hit Counter`.

NUN5 `practice_settings_draw_rows` (BTL `0x0089EA80`) supplies a left-aligned
section heading at X `84` with width `158`. `ui_font_draw_fitted` selects
the heading style before `font_draw_aligned_block` applies shrink-only
fitting through `font_fit_block_width`. The NUN5 glyph advances for
`Opponent Settings` total `164`, requiring horizontal scale `158 / 164`.

## Jutsu display and Practice completion plate

The Jutsu display is a general gameplay overlay. The completed-move plate
belongs to Practice. Both are separate from Practice Settings section headings.

`hud_command_strip_draw` (NA2 BTL `0x006B79B0`; NUN5 BTL `0x006CAA30`)
reads `BattleCommandStrip.title` in NA2 and `BattleCommandStripView.title`
in NUN5. The title follows the animated frame origin. Let `(x,y)` be that
origin after the frame branch's adjustments, including X minus `6` and
Y plus `27` in the mirrored branch:

| Presentation | NA2 | NUN5 |
| --- | --- | --- |
| Jutsu title | One line at `(x + 4, y)` | Box `(x, y - 11, 208, 30)`, two individually centered lines, vertically centered |
| Completed-move title | One measured line centered at `(248 + shakeX, 294 + shakeY)` | Box `(144 + shakeX, 283 + shakeY, 208, 32)`, two individually centered lines, vertically centered |

`practice_completion_draw` (NA2 BTL `0x00728320`; NUN5 BTL `0x0073E750`)
gets its title through `PracticeCompletionView.completed_move`: NA2 uses
`ActionRecord.display_name`, while NUN5 resolves `ActionNameView.display_name`.
The displayed title therefore follows the completed move rather than a fixed
Naruto string.

NUN5 `ui_font_draw_wrapped` wraps at the box width, retries with a wider wrap
when more than two lines remain, and then shrinks to the original box.
`font_fit_block_height` fits the 20-unit secondary-font line advances
vertically; `font_draw_aligned_block` centers each line. Glyph quads use the
separate 28-unit output height, scaled by the same factor:

| Two-line presentation | Line advance | Glyph quad height |
| --- | ---: | ---: |
| Jutsu display, height `30` | `15` | `21` |
| Completed plate, height `32` | `16` | `22.4` |

See [Renderer metrics](../renderer_metrics.md) for cell and output geometry.

The completed-move OK sprite uses the same shake-relative anchor `(356,303)`
and `PracticeCompletionView.ok_scale` in both games. Rectangle selection and
rotation differ:

| Game | Named source rectangle | `(u,v,width,height)` | Rotation bits |
| --- | --- | --- | --- |
| NA2 | `practice_ok_rectangle`, ELF `0x00604D58` | `(209,1,46,62)` | `0xBE99999A` |
| NUN5 English | `practice_ok_english_rectangle`, ELF `0x005DDC48` | `(80,0,48,64)` | `0x3FA2A974` |

NUN5 `localized_practice_ok_rectangle(0)` selects the rectangle through
`practice_ok_locale_tables` and the active language.
