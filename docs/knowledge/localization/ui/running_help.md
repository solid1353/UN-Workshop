# Running help

## Research coverage

Established: shared queue movement, holds, placement, repeat spacing, NA2 render contexts and per-frame draw scope in retail NA2 (SLPS-25837) and NUN5; native NA2 backing texture slices, caller viewports and priorities.
NA2 reserves character-count distance; NUN5 reserves measured width with a short-string minimum.
Open: numeric icon extents across callers, elapsed repeat timing and visual coverage of all callers.
The buffered SPBATTLE help belongs to linked Terms windows; its exact player-facing screen name remains unresolved.
Names come from `@annotations/NA2` and `@annotations/NUN5`; addresses are live.
Static caller coverage and one saved NUN5 frame bound the findings below.

General glyph metrics and secondary-font spacing belong to
[Renderer metrics](../font/renderer_metrics.md); the Controls help-banner
lifecycle belongs to [Shared frontend prompt layout](options.md#native-controls-lifecycle).
Not every menu family is described.

## Shared implementation

Both games use `UiScrollingStrip` and linked 16-byte `UiScrollSegment` nodes.
The strip retains `head`, `distance`, `speed`, `delay` and `elapsed_delay`;
each segment retains its `string`, reserved `extent` and `next` pointer.
`vertical` selects the movement axis and therefore whether `viewport_width`
or `viewport_height` supplies the viewport extent.

`scrolling_strip_initialize` creates the component with an empty queue and
zero hold counters. `scrolling_strip_clear` releases queued text, while
`help_text_queue` calculates the reservation before
`scrolling_strip_enqueue` attempts to append it.
`scrolling_strip_advance` owns motion and retirement;
`scrolling_strip_draw` positions and draws the queue without advancing it.

In NA2, each strip owns two render contexts: `scrolling_strip_initialize`
registers a backing context at priority `0xE6` and a text context at `0xE7`.
`scrolling_strip_set_priority` (`0x0037F120`) moves them to a caller priority
`p` and `p + 1`. `practice_settings_build_help` passes the priority of
`PracticeSettings.backing[2]`, so the Practice help strip runs at `0xE8`/`0xE9`
beside the settings content contexts. Every frame, `scrolling_strip_draw`
passes each whole queued segment string to `font_draw_text` in the text context.
It does not test which characters fall inside the viewport, so characters that
have scrolled off either edge still go to the glyph renderer.

## Extent calculation

NA2 `help_text_queue` (`0x0037F760`) selects the character-count result of
`font_text_extent`, backed by `font_measure_text` and `font_measure_markup`.
If the caller supplies unit `u` and gap count `g`, its reservation is:

```text
L_NA2 = u * (character_count + g)
```

NUN5 `help_text_queue` (`0x0038E790`) selects its measurement font through
`font_select_resource`, then selects the width result of `font_text_extent`:

```text
L_NUN5 = measured_width + u * g
if L_NUN5 < 512:
    L_NUN5 = 512 + u
```

The comparison is strictly below 512; a reservation already equal to 512
stays 512. NUN5's `font_measure_markup` accounts for proportional glyph margins
and ordinary spaces. In both games, icon advances contribute to measured
width without contributing to the character count selected by NA2.
A character count therefore cannot stand in for rendered extent, including
when visible text contains icons.

Icon width comes from the active renderer's installed
`icon_measure_callback`, reached through `font_measure_icon`; NA2 passes
`font_icon_selector`. It is not a universal character-cell width.
`font_classify_token` recognizes markup and can change renderer state while
parsing; the two games' measurement and draw paths need not consume markup
identically.

## How the extent affects visibility

For horizontal movement, `scrolling_strip_draw` places the first string at
`viewport_width - distance`. Later strings follow the sum of preceding
segment extents. After the initial hold, each `scrolling_strip_advance` adds
`speed` to `distance`. It retires the first node when distance reaches
`extent + viewport_width`, subtracting that node's extent from distance.

`scrolling_strip_enqueue` accepts another node when enqueueing is enabled
and the sum of current extents is no greater than distance. Repeated
submissions can therefore queue the next copy before the first is retired.
Reserved extent controls spacing between copies independently of drawn width.

A count-derived extent larger than the rendered width adds empty travel;
the excess varies with character count and glyph widths. This establishes a
mechanism for string-dependent spacing, without establishing elapsed blank
time for every caller.

For a continuously resubmitted, unchanged horizontal string, let `W` be
viewport width, `R` rendered horizontal extent, `L` reserved extent and `v`
distance per update. Ignoring update quantization and glyph edge bearings,
the derived completely blank part of a steady repeat is:

```text
blank_updates = max(0, L - R - W) / v
```

The previous copy's trailing edge can leave the left clip boundary before
the next copy's leading edge enters the right boundary. An inter-string gap
does not necessarily leave the whole viewport blank.

With a 512-unit viewport and measurement matching rendering, NUN5's ordinary
branch leaves `u * g` between copies; its short-string branch gives
`max(0, u - R) / v` blank updates. NA2's blank interval can instead grow
with `u * character_count - R`. These are geometric relationships, not
measured wall-clock timings.

## Saved NUN5 Free Battle example

The recorded Mode Select state contains strip `0x00BF83F0`, node
`0x00BF2600` and `mode_select_free_battle_help` at `0x008F5790`:

```text
<color00FFFF>Free Battle<WHITE> allows you to use any character to fight how you like.
```

| Saved value | Value |
| --- | ---: |
| Reserved extent | 788 |
| Viewport width | 512 |
| Speed per update | 2 |
| Distance | approximately 460.8 |
| Elapsed hold / hold limit | 30 / 30 |
| Measured width | 612 |
| Drawn horizontal advance | 602 |
| Effective gap between copies | 186 |

The renderer at `0x00B3F220`, referenced by `global_font_draw_state`,
retains `RunningHelpFontView.start_x/start_y` of `(51,20)` and final
`pen_x/pen_y` of `(653,20)`. Its GF4 descriptor at `0x00B592D0` and metric
table at `0x00B60ED0`, zero tracking and eight-unit ordinary spaces reproduce
the 602-unit advance. `global_font_draw_state` is the resident NUN5
`RunningHelpFontView *` used by `help_text_queue` and `scrolling_strip_draw`.

The measured width is `788 - 22 * 8 = 612`, ten units above the drawn advance.
NUN5 `font_classify_token` and `font_measure_markup` leave the closing
`>` of `<WHITE>` to be measured; its saved margins `[2,7,2,3]` contribute
ten units. `font_draw_markup` consumes that closing byte without drawing it.
The resulting gap is 186 rather than 176, but the entire viewport still
never becomes empty under the steady-repeat geometry above.
A width-based reservation alone does not establish identical markup
consumption by measurement and drawing.

## Placement and spacing

The shared draw functions derive origin from distance and the style's
`text_axis_offset`, inheriting selected font and tracking. NA2
`mode_select_present` selects the secondary face through `font_select_face`
before drawing help. Secondary-font spacing is owned by
[Renderer metrics](../font/renderer_metrics.md).

`scrolling_strip_configure` applies separate text and backing viewports
from `UiScrollConfiguration`; NA2 uses `abi_float_arguments_consume` for
their logical rectangles. The corresponding fields are
`RendererTransformState.viewport_left/top/width/height` in NA2 and
`RunningHelpViewportView.viewport_left/top/width/height` in NUN5.
The saved NUN5 text viewport at `0x00BF87A0` holds `(0,300,512,48)`,
with text starting at local `(51,20)`. These positions are distinct from
glyph ink bearings and accumulated word spacing.

With an untextured backing, NA2 `scrolling_strip_draw` submits
`immediate_rectangle_integer`, whose packed color is decoded by
`packed_rgba_to_float`. Native configuration 3 uses `0xBF2F2807`: red 7, green 40,
blue 47, alpha 191, a translucent dark teal.

## Native NA2 backing resources

`scrolling_strip_initialize` (`0x0037ED00`) constructs separate backing and
text renderers, binding the backing sprite to its own context at `0x0037EDDC`.
`scrolling_strip_set_backing_descriptor` (`0x0037F180`) resolves a named texture;
`scrolling_strip_set_backing_texture` (`0x0037F210`) sets its texture state and
source rectangle. A null descriptor/texture/rectangle selects solid backing.
Changing ordering priority does not attach either renderer to the caller's
renderer.

`scrolling_strip_select_backing_style` (`0x0037F2C0`) selects one of two records in
`scrolling_strip_backing_styles` (`0x005B1770`): both name
`gauge/TEX_xpanel`, with source rectangles `(121,48,2,48)` for style 0 and
`(125,48,2,48)` for style 1. These are distinct from the four scrolling
configurations. `scrolling_strip_draw` stretches the selected slice to local
`(0,0,viewport_width,viewport_height)`; its text uses the independent cropped
context.

Original `CMN/GAUGE.CCS` links `TEX_xpanel` object `155` to `CLT_xpanel` object
`154`, with a `128x128` image. Both selected slices contain white RGB wherever
alpha is positive, plus transparent texels; they contain no bounded logo or
colored artwork. Style 0 has identical columns, while style 1 varies alpha.
The file palette's logical order agrees with `ccs_parse_clut_block`
(`0x001B3810`) preparing resident CSM1 order and `ccs_parse_image_block`
(`0x001B3C70`) copying image words unchanged. The compressed source SHA-256 is
`92d76fbbd28197fcdffcc1f072ae0b2bfb0504b098a2b0f0a8553fbec6040c52`.

The inspected native producers select these textured styles before drawing:

| Caller family | Viewport `(x,y,width,height)` | Backing style | Backing/text priority |
| --- | --- | ---: | --- |
| Mode Select | `(0,300,512,48)` | 1 | `0x50/0x51` |
| Controls | `(0,290,512,48)` | 1 | `0xE9/0xEA` |
| Audio / Options | `(0,290,512,48)` | 1 | `0x51/0x52` |
| Battle Settings | `(0,290,512,48)` | 1 | `0x41/0x42` |
| Practice Settings | `(0,290,512,48)` | 1 | `0xE8/0xE9` |
| Ultimate Battle menu / rank | `(0,290,512,48)` | 0 | `0x80/0x81` |
| SPBATTLE linked Terms windows | `(0,290,512,48)` | 0 | `0xC0/0xC1` |
| Continue | `(0,334,512,48)` | 0 | `0x67/0x68` |

These are full-width backing bands, rather than full-height covers or bounded
artwork. Arbitrary descriptors and uninspected indirect callers remain outside
this source/caller cohort. SPBATTLE window resources and computed draw ownership
are in [2D draw ownership](../../runtime/rendering/draw_2d_owners.md#direct-immediate-rectangle-caller-inventory).

## Initial hold and short first entries

Mode Select, Control Settings, Sound Settings and Options set `delay` to
30 updates and enable `minimum_first_extent` in both games. Battle and
Practice Settings also select configuration 3 with that same hold and minimum policy.

On the first append to an empty queue with a nonzero delay, both games set
distance to `0.9 * W` and clear `elapsed_delay`. If
`minimum_first_extent` is enabled, the first extent is raised to
`0.9 * W + 20` when necessary. The initial horizontal origin is therefore
`0.1 * W`, already inside the viewport: the hold retains the initial
position. It is distinct from excess travel between repeated copies.

That first-node minimum applies only to the first delayed entry. NUN5's
short-string minimum in `help_text_queue` applies to every submission.

Both games' `scrolling_strip_configurations` contain four corresponding
36-byte records that are byte-identical between NA2 and NUN5, all specifying
a horizontal 512-unit viewport, height 48 and speed 2 units per update.
This does not establish that every caller
leaves its configuration unchanged.

## Menu caller families

The paired setters receive equal unit and gap values in the examined families:

| Caller family | Unit | Gap count |
| --- | ---: | ---: |
| Mode Select | 22 | 8 |
| Control Settings update and edit/reset | 20 | 8 |
| Sound Settings | 20 | 8 |
| Options and embedded Controls | 20 | 8 |
| Battle Settings | 20 | 8 |
| Practice Settings | 20 | 8 |
| Ultimate Battle menu help | 20 | 8 |
| Ultimate Battle level/rank help | 20 | 8 |
| SPBATTLE buffered help | 20 | 8 |
| Continue entry | 22 | 4 |

Selection, value-change and reset notices use the same shared setter.
The resident and battle-overlay routine annotations retain their individual
submission and ordering details.

NUN5 `ultimate_battle_help_text` selects localized menu help; its English
`ultimate_battle_help_messages` names Ultimate Battle Series, Epic Survival
and Customized Battle, establishing this family. The level/rank family uses
`ultimate_battle_rank_help_text` entries 5..7 and
`ultimate_battle_rank_help_messages`.

`spbattle_update_buffered_help` submits
`SpBattleHelpOwnerView.text_buffer`. Its owner constructs and links
`ccTermsInfoWnd`, `ccTermsBtlSetWnd` and `ccTermsSelWnd`; their computed draw
dispatcher establishes the window family. Its exact player-facing screen name
remains unresolved.

## Evidence coverage

The common setter owns the examined direct append paths in the resident ELF,
BTL and ETC. This bounded coverage leaves unresolved indirect calls open;
it does not establish exclusive ownership of every possible path.

Preserved cross-reference coverage is incomplete for some battle-overlay
help submissions and constructors. Their byte-established use of the shared
component remains recorded in annotations; missing cross-references do not
establish absence of that use. The saved NUN5 frame establishes one string's
queue, renderer and layout values, without establishing elapsed repeat timing
or visual coverage of every menu.
