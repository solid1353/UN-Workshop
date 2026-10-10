# Battle Results presentation

## Research coverage

Established: NA2 and NUN5 summary clouds, both rank paths, title pulse,
footer ownership, objective layout, arithmetic routing, bonus rows and scroll clamps.
Open: the shared-rank sprite's visible role and uncommon descriptor/bonus combinations.
Recorded comparisons cover all five visible stamps and representative Ninja Song layouts.
Names come from `@annotations/NA2` and `@annotations/NUN5`; comments hold routine detail.
Addresses are live under the [game binary conventions](../../../game/files/file_identities.md).

Result metrics, calculations and rank tiers belong to
[Battle statistics](../../../gameplay/session/battle_statistics.md); match results
belong to [Match outcomes](../../../gameplay/session/match_outcomes.md).
Input, sound and non-results battle UI are outside this document.

## Summary, clouds, and shared-rank sprite

`results_summary_draw` updates the clouds and owns the summary footer;
`results_summary_reveal_rows` owns row reveal and shared-rank sprite state.
`result_dispatch` owns the title presentation and screen dispatch.

| Owner | Retail NA2 | NUN5 |
| --- | --- | --- |
| `results_summary_draw` | `0x00716930` | `0x0072C480` |
| `results_summary_reveal_rows` | `0x00716ED0` | `0x0072CA40` |
| `result_dispatch` | `0x00719D80` | `0x0072FC00` |
| `results_cloud_layout` | `0x00899BC0` | `0x008B4EF0` |
| Summary label rectangles | `results_label_rectangles`, `0x008C3F30` | `results_label_rectangles_english`, `0x005DDB20` |
| `results_title_cloud_rectangles` | `0x008C3FD8` | `0x008DC5E0` |

The five-cloud loop has the same X, Y, speed and height values in both games.
Only widths differ:

| Cloud | NA2 width | NUN5 width |
| ---: | ---: | ---: |
| 0 | 156.4 | 293.25 |
| 1 | 102 | 191.25 |
| 2 | 136 | 255 |
| 3 | 102 | 191.25 |
| 4 | 136 | 255 |

Against NUN5's `XNINKA.CCS` atlas, the NA2 widths cross neighboring content;
the NUN5 widths select the cloud regions. Each cloud moves by its speed and
wraps from X at least 512 to minus its width.

The shared-rank label selects `BattleResultsSummaryView.result_rank - 1`.
NA2 reads `hud_character_name_rectangles` (`0x005B13A0`); NUN5 uses
`battle_hud_rectangle_get` (`0x003D5160`) and its
`battle_hud_rank_rectangles_english` (`0x005DE8B0`):

| Value | Rectangle `(u,v,width,height)` |
| --- | --- |
| Outstanding! | `(0,48,80,24)` |
| Nicely done! | `(80,48,80,24)` |
| Good job! | `(200,168,48,24)` |
| Keep trying | `(160,48,72,24)` |
| Try harder! | `(128,120,112,24)` |

NUN5 scales the rectangle by 1.35, fits its destination width to 220 with
`rectangle_width_fit_ratio` (`0x003D5700`), and draws it through
`sprite_draw_centered_rectangle_size` (`0x0038ADC0`). Its center is
`(animated X + 140, row Y - 1 + height × 1.35 × 0.6)`. The widest English
record is 112 pixels, so none reaches the fit ceiling after scaling.
NA2 lacks those localized access/fit helpers on this path and has the available
`sprite_draw_scaled_rectangle` (`0x0037BD00`) centered helper.

Previously recorded changes to the shared-rank rectangle and anchor changed
no visible rank pixels. Hidden, occluded or secondary-layer ownership remains
uncertain; this sprite cannot establish the visible rotated stamp's placement.

The paired title controllers use the same pulse algorithm. Independently
timed still frames can therefore show different title sizes without a static
layout difference.

### Summary footer batching

`results_summary_initialize` (NA2 `0x007164C0`, NUN5 `0x0072BFE0`) creates
the footer objects. In NA2, `BattleResultsSummaryView.details_sprite` uses
`TEX_xninka` for Display details, while `prompt_sprite` supplies Next; both
share `footer_render_context`.

The label sprite's `ProjectedTextGeometryView.rectangle_capacity` is one.
Display details consumes that rectangle before Next is drawn.
`text_draw_projected_rectangle` (`0x001CC3A0`) stops appending at capacity,
so a second rectangle requires a separate batch. `sprite_reset`
(`0x001CC070`) submits the batch and clears `rectangle_count` and `packet`,
allowing the same sprite to supply a later rectangle.

## Visible rotated rank stamps

The rotated red stamp is separate from `shared_rank_sprite`.
`BattleResultsSummaryView.stamp_rank` selects the same five-step sequence in
both games:

| Game/table | Index 0 | Index 1 | Index 2 | Index 3 | Index 4 |
| --- | --- | --- | --- | --- | --- |
| NA2 `results_rank_stamp_rectangles`, `0x008C3FB0` | `(352,200,64,56)` | `(416,168,64,56)` | `(416,112,64,56)` | `(416,56,64,56)` | `(416,0,64,56)` |
| NUN5 `results_rank_stamp_rectangles_english`, `0x005DDB60` | `(416,176,96,44)` | `(416,132,96,44)` | `(416,88,96,44)` | `(416,44,96,44)` | `(416,0,96,44)` |

NUN5's `results_rank_stamp_rectangle_tables` (`0x005BB390`) selects equivalent
tables in locale order at `0x005DDB60`, `0x005DEE90`, `0x005E14F0`,
`0x005E01C0` and `0x005E2820`. `results_rank_stamp_rectangle_get`
(`0x003D4350`) supplies the selected record and index-3 baseline.

`position_player_seek` (NA2 `0x00717A60`) and `results_rank_stamp_draw`
(NUN5 `0x0072D5F0`) select the stamp relative to that baseline:
`U = (selected.u - baseline.u) / 512` and
`V = 1 - (selected.v - baseline.v) / 256`.
They resolve the model from `stamp_animation`, convert those coordinates to
fixed12 and write its texture offset. The helpers are `sprite_uv_normalize`
(`0x0037DA40`), `resource_find_model` (`0x001BAB40`) and `model_set_uv_offset`
(`0x00198840`) in NA2; `rectangle_normalize_uv` (`0x0038C9C0`),
`resource_find_model` (`0x001BF290`) and `model_set_texture_offset`
(`0x0019BD70`) in NUN5.

NUN5's stamp animation has 21 frames and no material or UV controller. Its
model uses NA2's UVs with English-aspect geometry; the rectangle selection,
rather than model defaults, determines the displayed rank. Its labels occupy
adjacent 44-row cells in a shared 96-by-220 region.

## Ninja Song details footer

`endpoint_counter_player_draw` (NA2 `0x00718320`) and
`ninja_song_draw_details` (NUN5 `0x0072DEE0`) own the details footer and
objective layout. The summary and details footers have separate owners.

| Prompt | NA2 anchor | NUN5 anchor |
| --- | --- | --- |
| Next | `(395,348)` | `(375,348)` |
| Back | `(470,348)` | `(462,348)` |

NUN5 applies regional offsets -20 and -8 to the same nominal X values.
The recorded screen difference matches those offsets.

## Ninja Song objectives and totals

Both details renderers start at `70 - NinjaSongDetailsView.scroll`, advance
ordinary rows by 36 and grouped content by 50, and admit rows inside
Y `-100..484`. NUN5 draws the objective index at X 80 and prose at
`(112, row Y - 6)` in a 320-by-32 box.

`ninja_song_draw_objective_values` (NA2 `0x00718960`, NUN5 `0x0072E5F0`)
routes expanded, total-only and N/A rows from the descriptor/result values.
NUN5's localized unit is at relative `(176,-6)` in a 52-by-32 box; its total
is right-aligned at relative X 256 in a 64-unit box. Descriptor `unit_index`
2 selects the timer-counts resource and 4 suppresses the visible unit.
Renderer selection is descriptor-based, rather than based on displayed text.

`ninja_song_draw_bonus` (NA2 `0x00718CA0`, NUN5 `0x0072EA00`) consumes the
selected 12-byte result row: `BtlRecordOwnerRow` in NA2 and
`NinjaSongResultRow` in NUN5. The label and its Y position can vary by fight.
NUN5 wraps the label in a 288-by-32 two-line box and right-aligns the total in
a 96-by-20 box. BODY's two-unit inter-digit advance contributes to measured
total width.

`ninja_song_update_scroll` (NA2 `0x00719020`, NUN5 `0x0072EE10`) receives a
30-unit step and applies the same subtract/add, upper-limit and zero clamps
to `scroll` and `scroll_limit`.

Recorded representative comparisons confirmed objective line breaks,
arithmetic columns, the two-line timer label, percent-unit suppression, N/A
rows, dynamic bonus-label boxes and right-aligned totals. Uncommon result
combinations remain bounded by the paired static control flow.
