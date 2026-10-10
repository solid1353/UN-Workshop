# Battle and Practice settings presentation

## Research coverage

Established: retail NA2 settings geometry, viewports, resource bindings,
scrolling, title/cell separation, cursor/arrow gates, Handicap and footers;
NUN5 footer and VS prompt comparisons. Names come from `@annotations/NA2`
and `@annotations/NUN5`; addresses are live. Open: complete menu lifecycle,
every animation phase/configuration, and the model stream attribute mapping.
Prior object/resource observations establish the layouts within those bounds.

Addresses follow the
[Game binary address conventions](../../../game/files/file_identities.md#address-conventions).
Setting storage, input, child state, resource lifetime and gameplay effects
belong to [Practice mode](../../../gameplay/modes/practice_mode.md);
localized Practice text layout belongs to
[Practice screen layout](../../font/screen_layouts/practice.md); shared draw
owners belong to [2D draw owners](../../../runtime/rendering/draw_2d_owners.md).

## Practice content and contexts

`practice_settings_construct` (`0x00880BE0`) creates separate content and
foreground contexts in `PracticeSettings.backing[2]` and `backing[3]`.
Both have viewport `(0,70,512,210)`, set by
`settings_context_set_viewport` (`0x0037DAA0`), with priorities `0xE8`
and `0xE9` respectively.

`practice_settings_draw` (`0x00882250`) binds the foreground context
through `font_set_render_context` (`0x001866D0`) before text submission.
`FontDrawState.render_context` is independent of the animation draw context:
changing the latter alone does not change text's viewport, and using the
backing context for text puts it beneath the backing layer. The resident
`global_font_draw_state` pointer supplies the `FontDrawState` passed to
`font_set_render_context`.

`PracticeSettings.row_offset` is the scrolling displacement. The backing
parent translates by `-0.96 * row_offset`; text begins at
`14 + row_offset`, advances by `28` per row, and inserts an `18`-unit
section gap followed by a heading row. The heading moves with the content and
is clipped by the same viewport.

Rows `0..8` form the upper window and `9..16` the lower window.
`practice_settings_update` (`0x00881AB0`) eases the displacement toward
`-28 * upper_start` or `-270 - 28 * lower_start` by at most `20.0` per
update. The lower target includes nine `28`-unit rows and the `18`-unit
gap. Window selection and easing ownership are described in
[Practice mode](../../../gameplay/modes/practice_mode.md#input-and-child-state-transitions).

### Backing animation and title

The backing `ANM_prac_cel` is `PracticeSettings.sprites[1]`.
Its `CcsAnimationPlayer.play_entries` contains 18 `CcsPlayEntry` records:

| Records | Resource role |
| --- | --- |
| 0 | `OBJ_prac_title`, whose model is `MDL_prac_title` |
| 1, 10..17 | Nine player-row cells |
| 2..9 | Eight opponent-row cells |

`projectile_compound_submit` (`0x001BB790`) draws an entry only when
`CcsPlayEntry.flags & 0x04` is nonzero. The title therefore has its own
entry-level draw boundary, independent of every cell and of the text windows.
`CcsPlayEntry.value` points to the render target; its
`CcsScenePlayTarget.world_matrix[14]` and `local_matrix[14]` are distinct
world and authored-local Y values.

The update advances the backing and cursor through
`animation_advance_position` (`0x001BB210`), using each player's
`step` when `play_entries` exists, then immediately runs
`animation_player_compose` (`0x001BB6F0`). Hierarchy composition thus
precedes submission and the draw-time row translation.

`MDL_prac_title` has one rigid 28-vertex mesh. After the model's `1/16`
coordinate scale, its authored bounds are X `-179.9375..4.25` and vertical
`-13.5..13.5625`: a `184.1875 x 27.0625` local-unit footprint.

The separate `PracticeSettings.panels[0]` draw uses
`practice_settings_panel_rectangle`, `(1,1,126,30)`, from
`TEX_prac_t01`. That region contains panel and arrow imagery; the title is
the separate model above.

### Model colors and atlas regions

`scene_object_submit_geometry` (`0x00190F40`) draws the type-`0x0100`
model resolved through `CcsScenePlayTarget.model`.
`CcsModelInstance.parts` points to `0x40`-byte `CcsRuntimeModelPart`
records, with `part_count` and each part's `vertex_count` controlling the
work.

`model_draw_part_setup` (`0x00198230`) borrows source stream pointers
into `CcsModelDrawContext`; it does not copy their payload.
`model_geometry_packet_set_uv` (`0x00193B50`, existing annotation name)
emits source DMA references in batches of up to 48 four-byte elements.
The referenced stream is therefore read when DMA consumes it.

The earlier settings resource interpretation identifies part `+0x1C` as
vertex colors and `+0x20` as UVs, with the former borrowed into scratch
`+0x238`. The current declarations name these pointers
`CcsRuntimeModelPart.uv_words` / `auxiliary_attributes` and
`CcsModelDrawContext.uv_words` / `auxiliary_attributes`. Their offsets
and borrowing are verified; the conflict in final attribute meaning remains
open, so those authored names are retained without treating them as proof of
color/UV semantics.

In retail NA2 `PRAC.CCS`, `MDL_prac_cel_a1`, `MDL_prac_cel_b1` and
`MDL_prac_title` share `MAT_char_prac` and neutral `0x80808080` vertex
colors. Their yellow, olive and orange appearances come from distinct
`prac_t01` atlas regions:

| Geometry | U coordinates |
| --- | --- |
| First 18 player-row vertices | 0 / 32 / 74 |
| First 18 opponent-row vertices | 76 / 108 / 150 |
| Title | 162 / 206 / 246 / 254 |

Row vertices `0..17` form the label panel; `18..61` form the divider and
value panel. NA2 `SETTING.CCS` uses the same 62-vertex player-row geometry
with the separate `s_menu` atlas, which contains the yellow row but no orange
title or olive row region. Both NA2 and NUN5 `prac_t01` have dominant opaque
fill RGBA `(230,195,43,255)` and orange title fill `(245,134,32,255)`.

### Resource construction

`practice_settings_construct` loads `practice_archive_path`
(`prac.ccs`) through `ccs_acquire_or_load` (`0x0037E1A0`), retaining
the archive and its ownership flag. `practice_settings_build_panels`
(`0x00880DB0`) binds the backing, camera and cursor resources through
`animation_player_allocate_bound` (`0x0037D5B0`). That helper allocates
a `0x120`-byte player and initially advances/composes it when records exist.

`practice_settings_destroy` (`0x00880A20`) releases animation players
through `animation_player_destroy` (`0x001B7570`) and an owned archive
through `ccs_destroy_container` (`0x001A9790`). Animation-player and
archive ownership are separate.

## Cursor and arrows

| Practice field | Bound animation |
| --- | --- |
| `sprites[0]` | `ANM_prac_ca` camera |
| `sprites[1]` | `ANM_prac_cel` backing |
| `sprites[2]` | `ANM_carsol01_a` selection cursor |

`practice_draw_row_selection` (`0x00881E50`) gives the cursor local Y
`94 - 26.5 * selection - 0.939 * row_offset`, subtracting another `40`
after the fixed nine-row player section. The update advances and composes
the cursor before this draw helper applies its translation.

| Value arrows | Rectangle | Horizontal radius around X 356 |
| --- | --- | --- |
| Practice | `practice_value_arrow_rectangle`: (52,69,15,14) | `64 + 3*sin(pi*phase_a)` |
| Battle | `battle_value_arrow_rectangle`: (81,61,18,18) | `60 + 3*sin(pi*phase_a)` |

Practice value arrows require an enabled row and a value that can move in the
corresponding direction. Orange scroll arrows share
`practice_scroll_arrow_rectangle`, at local Y
`14 - 5*sin(pi*phase_c)` and `196 + 5*sin(pi*phase_c)`.
The up arrow is suppressed while the upper section's `upper_start` is zero;
it is always available in the lower section. The down arrow is always
available in the upper section and requires `lower_start < 2` in the lower.

## Footer legends

| Owner | Retail NA2 live entry | NUN5 live entry |
| --- | --- | --- |
| `battle_settings_present` | `0x008807A0` | `0x0089D280` |
| `practice_settings_draw` | `0x00882250` | `0x0089F130` |
| `button_icon_submit` | `0x0037C980` | `0x0038BB10` |
| `sprite_draw_rectangle` | `0x0037BC40` | `0x0038AD00` |

Both screens use the same footer Y `356` and horizontal values:

| Legend call | NA2 X | NUN5 effective X |
| --- | ---: | ---: |
| OK | 400 | 388 |
| Back | 470 | 462 |
| Select icon request | 230 | 200 |
| Select companion sprite | 230 | 200 |

NUN5 loads both Select positions directly as `200`; nominal OK/Back
positions `400`/`470` receive regional additions `-12`/`-8` before
submission. NA2 has no equivalent additions. NUN5's
`button_icon_submit` returns without drawing for icon `3`, so its Select
request coordinates do not establish an emitted icon; the companion sprite
has a separate draw. The VS confirmation prompt has its own draw owner and
does not belong to either Settings footer.

## Battle rows and Handicap

`battle_settings_draw_rows` (`0x008801E0`) lays out six labels at
`Y = 79 + 28 * slot`; ordinary value rows also advance by `28`.
Slot `5` is Handicap, whose label is at Y `219`. Its red and blue value
paths independently keep fixed Y `257`, 38 below the label.

The backing contains five ordinary row strips and a double-height Handicap
panel. The cursor and arrows follow the selected slot, while Handicap values
and backing stay in the fixed sixth position.

Handicap is a ten-segment graphic. `BattleSettings.values[5]` chooses the
Player 1 red count; blue fills the remainder, so the total remains ten.
`sprite_draw_scaled_rectangle` (`0x0037BD00`) submits each segment at
`X = 128 + 28 * segment`, Y `257`, scale `0.9`, using
`battle_handicap_red_rectangle` `(33,61,23,23)` or
`battle_handicap_blue_rectangle` `(57,61,23,23)`.

`battle_settings_build_resources` (`0x0087F6D0`) uses the
`setting.ccs` archive in `BattleSettings.archive`.
`sprite_allocate_from_container` (`0x0037B670`) creates
`legend_sprite` from `TEX_s_menu`, with capacity `0x14`, enabled flag
`1` and `font_context`. `animation_player_allocate_bound` creates
`backing_player` (`ANM_setting01`), `scene_player`
(`ANM_setting_ca`), `row_cursor` (`ANM_carsol01_a`) and
`handicap_cursor` (`ANM_carsol02_a`). Handicap uses `legend_sprite`;
Practice's `backing[0]` is a different object type.

`ANM_setting01` record `0` is the double-height panel; `1..5` are
ordinary strips for slots `0..4`. Observed target `local_matrix[14]`
values are `0.0` for the panel and `99.03`, `72.42`, `45.80`,
`19.18`, `-7.43` for records `1..5`. The panel is modeled `34.04`
above the extrapolated sixth ordinary strip. The root's local matrix also
holds its Y translation; observed target `world_matrix[14]` values were
`0.0`, not composed positions.

`battle_strength_draw` (`0x008804F0`) places the cursor at local
`Y = 100 - 26.5 * selection`. Slot `5` uses the label-only
`handicap_cursor`; other slots use `row_cursor`. Handicap emits no value
arrows.

## VS Practice Settings prompt

`vs_settings_draw_prompts` is separate from both Settings footers:

| Game | Live entry | Practice prompt source | X |
| --- | --- | --- | ---: |
| NA2 | `0x006C0D00` | `vs_practice_prompt_rectangle`: (1,281,112,22) | 60 |
| NUN5 | `0x006D4170` | English (0,280,176,24) | 100 |

NUN5 selects the rectangle through
`localized_vs_practice_prompt_rectangle` (`0x003D46C0`) and
`vs_practice_prompt_locale_tables`. Its English entry,
`vs_practice_prompt_english_rectangle`, draws the label and Square icon as
one `176 x 24` sprite at UV `(0,280)`.
