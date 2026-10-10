# Numeric and settings text rendering

Retail NA2 (`SLPS-25837`) and NUN5 formatting and layout differences for
Save/Load, Battle and Practice Settings, Jutsu rows, and Ninja Song values.

## Research coverage

Established: decimal padding, fullwidth versus ASCII ownership, Save/Load
time conversion, Battle infinity handling, Jutsu wrapping, and Ninja Song layouts.
Open: numeric callers outside these families and every fight-dependent bonus row.
Paired screens cover representative values, not every value on each shared path.
Names come from `@annotations/NA2` and `@annotations/NUN5`;
their comments hold per-routine details. All addresses below are live.

Related owners: [Renderer metrics](renderer_metrics.md) owns glyph metrics;
[NA2 and NUN5 text correspondence](../translation_importer.md) owns translation
wording; [Battle Results presentation](../ui/battle/battle_results.md) owns the
result screens and their lifecycle.

## Save/Load numeric fields

`save_ui_draw_slots` (NA2 resident `0x001E6370`, NUN5 resident `0x001EC0B0`)
renders saved date and Play Time. NA2's `format_decimal_cp932` (`0x00378510`)
emits fullwidth CP932 digits for all six fields. NUN5's
`format_decimal_ascii` (`0x003856B0`) emits ASCII date digits; Play Time uses
`save_two_digit_format`, the native `%.2d` format equivalent to `%02d` for
these nonnegative components.

| Field | NA2 | NUN5 |
| --- | --- | --- |
| Year | Unpadded, at most four digits | Unpadded `%d` |
| Month and day | Two digits, zero-padded | Two digits, zero-padded |
| Hour | Three digits, zero-padded | Two digits, capped at 99 |
| Minute and second | Two digits, zero-padded | Two digits, zero-padded |

NA2 reads the calendar from `SaveDescriptor.modified`; NUN5 reads
`SaveDescriptorNumericView.day`, `.month`, and `.year`. Play Time is stored
as ticks in `play_time`:

| Game | Ticks per hour | Ticks per minute | Ticks per second | Display cap |
| --- | ---: | ---: | ---: | --- |
| NA2 | 108,000 | 1,800 | 30 | `999:59:59` |
| NUN5 | 90,000 | 1,500 | 25 | `99:59:59` |

Separators are independent strings appended between formatted components.
NA2 uses the fullwidth `save_time_colon_cp932`; NUN5 uses
`save_date_slash_ascii` and `save_time_colon_ascii`.

## Battle Settings time

`battle_settings_draw_rows` (NA2 BTL `0x008801E0`, NUN5 BTL `0x0089CBD0`)
uses an unpadded decimal field of width three for time values below 100.
NA2 emits fullwidth digits and NUN5 emits ASCII digits. Value 100 takes a
separate infinity-symbol branch in both games.

## Ninja Song numbers

`ninja_song_draw_objective_values` (NA2 BTL `0x00718960`, NUN5 BTL
`0x0072E5F0`) renders arithmetic values. `ninja_song_draw_bonus` (NA2 BTL
`0x00718CA0`, NUN5 BTL `0x0072EA00`) renders later bonus labels and scores.
They use their game's decimal formatter with these field contracts:

| Field | Width | Padding mode |
| --- | ---: | --- |
| Left factor / target | 3 | 0: spaces |
| Right factor / current value | 3 | 0: spaces |
| Arithmetic total | 5 | 0: spaces |
| Inline bonus value | 4 | 1: unpadded |
| Bonus score | 4 | 0: spaces |

Mode 2 zero-pads. Width counts digit cells; NA2 emits two bytes per cell,
whereas NUN5 emits ASCII. Multiplication punctuation is independent of
number formatting: NA2's `ninja_song_multiply_cp932` contains `" × "`, and
NUN5's `ninja_song_multiply_ascii` contains `" * "`.

## Jutsu-selector row

`jutsu_select_draw` (NA2 BTL `0x006BCB70`, NUN5 BTL `0x006CFE70`) uses the
incoming row position `(x, y)` and the selector's side. NA2 places ordinary
text at `(30 + x, 16 + y)` on side one and `(310 - x, 16 + y)` on side two.
It supplies no width or line limit, so long English names remain on one line
and overflow.

NUN5 uses a `186 x 32` box, a two-line limit, start horizontal placement,
centered vertical placement, and wrapping. Relative to the NA2 points, its
box begins seven units left on side one, four units left on side two, and
ten units above on both sides.

## Settings page templates

Battle and Practice Settings render labels and values through shared row
loops. Battle uses `battle_settings_draw_rows`; Practice uses
`practice_settings_draw` in NA2 (BTL `0x00882250`) and
`practice_settings_draw_rows` in NUN5 (BTL `0x0089EA80`), including the
section heading before row nine. Individual row text does not own a separate
draw layout.

NUN5 ordinary values use a centered `104`-unit box beginning at X `304` on
both pages. Its Battle time branch sets bit `0x08` of
`RunningHelpFontView.render_flags` for infinity and clears it for ordinary
decimal values; NA2 clears `FontDrawState.render_flags` bit `0x08` for both.
Each branch restores the bit afterwards.

## Ninja Song templates

NUN5's expanded arithmetic positions are relative to the numeric origin
`(x + 10, y)` passed into `ninja_song_draw_objective_values`:

| Element | Relative placement / box |
| --- | --- |
| Left factor | X `30` |
| Multiplication separator | X `90` |
| Right factor | X `120` |
| Unit resource | `(176, -6, 52, 32)`, two lines |
| Equals | X `226` |
| Total | `(256, 0, 64, 20)`, right-aligned |

The result row selects expanded arithmetic, total-only, or N/A output.
A zero total draws N/A; objectives 9, 10, and 13 with a nonzero total draw
only that total; other nonzero rows draw the expanded expression. The unit
comes from the descriptor's `unit_index`; a missing or empty localized unit
is omitted.

`ninja_song_draw_details` (NUN5 BTL `0x0072DEE0`) places objective indices at
X `80` and prose at `(112, rowY - 6)` in a `320 x 32` two-line box.
Post-objective bonuses use 12-byte `NinjaSongResultRow` records, corresponding
to NA2's `BtlRecordOwnerRow`. Their descriptor chooses the label, and their
value and total supply the numbers; the selected rows vary with the fight.
NUN5 uses a shared `288 x 32` two-line label box and a `96 x 20`
right-aligned total box. Rows 17, 18, 22, 25, 26, and 27 insert an unpadded
inline number into the label; other rows use their descriptor text directly.
