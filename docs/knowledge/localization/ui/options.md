# Shared frontend prompt layout

## Research coverage

Established: retail NA2/NUN5 prompt geometry, Options backdrop ownership,
Controls lifecycle, nine-row layout, help ordering, and localized label sources.
Open: uncovered animation phases and indirect callers, beige-box asset ownership,
and the visible Select-icon source in NUN5; its case-3 request submits nothing.
Names come from `@annotations/NA2` and `@annotations/NUN5`; addresses are live.
The resident transition-manager pointer is annotated as `global_transition_pool`.

## Binary identity and mapping

The comparison uses the retail Japanese NA2 boot ELF
`@source_na2/SLPS_258.37` and official English NUN5 boot ELF
`@source_nun5/SLES_556.05`. English screen-position label pointers are in
NUN5 `TEXTENG.BIN`; their strings are in its boot ELF. Shared names below
resolve separately in each game's annotations.

| Routine | NA2 live entry | NUN5 live entry |
| --- | --- | --- |
| `button_icon_submit` | `0x0037C980` | `0x0038BB10` |
| `screen_position_present` | `0x0038ADB0` | `0x0039C730` |
| `options_controls_present` | `0x00388B90` | `0x0039A450` |
| `options_audio_present` | `0x0038A1F0` | `0x0039BB00` |
| `mode_select_present` | `0x00385C00` | `0x003972E0` |
| `options_present` | `0x0038C5F0` | `0x0039E050` |
| `difficulty_selector_draw` | `0x0038C160` | `0x0039DBA0` |

## Screen-position modal text

Both `screen_position_present` routines use identical anchors: X label/value
at `(40,12)` / `(72,12)`, Y label/value at `(40,40)` / `(72,40)`, color
index `15`. Label and numeric text require the panel-ready gate. Signed
formatting uses width `3`: zero is `"   0"`, negative one `"  -1"`.
Values come from `ScreenPositionView.x_offset / 3` and `-y_offset`.

NA2 reads `screen_position_x_label_pointer` and
`screen_position_y_label_pointer`, pointing to the eight-byte Shift-JIS slots
`screen_position_x_label` (`Ｘ ：`) and `screen_position_y_label` (`Ｙ ：`).
NUN5 `localized_screen_position_label` (`0x003D1580`) selects records 4 and 5
from the current language table. The English table is
`screen_position_english_label_table` at live `0x008F46D0` in `TEXTENG.BIN`;
its records point to ASCII `X:` / `Y:` at resident `0x00613CE0` / `0x00613CE4`.

Text objects differ: NA2 allocates `0x80` bytes and a `0x24`-byte renderer
record, NUN5 `0x88` and `0x424` bytes, with shifted renderer and descriptor
fields. `font_select_face` initializes secondary
`FrontendFontSpacingView.tracking` to `-1.0` in NA2 and `0.0` in NUN5;
`extra_spacing` is respectively `2.0` and `0.0`. Identical anchors therefore
do not establish identical geometry or interchangeable complete objects/draw
routines.

Ordinary leading spaces advance eight units in NUN5 and fourteen in NA2 when
secondary tracking is zero. Retaining the NA2 formula at that tracking moves
zero 18 logical units right and negative one 12 units right. Font formulas
are owned by [Renderer metrics](../font/renderer_metrics.md).

## Shared Cancel compositor

Both screen-position callers request `button_icon_submit` case 4 at logical
center `(170,340)`. It starts at
`center_x - (triangle.width + label.width + tail.width) / 2`, then submits
triangle, label, and tail consecutively, each vertically centered by half
its own height.

Records share the four signed-halfword rectangle layout (`BattleHudRectangle`
in NA2, `FrontendRectangle` in NUN5).

| Record | NA2 live address / rectangle | NUN5 English live address / rectangle |
| --- | --- | --- |
| `cancel_triangle_rectangle` | `0x005D46C0` / `(3,25,26,22)` | `0x005DE8A0` / `(2,24,24,24)` |
| `cancel_label_rectangle` | `0x005D46B0` / `(1,49,114,22)` | `0x005DE890` / `(1,49,56,22)` |
| `cancel_tail_rectangle` | `0x005D46B8` / `(1,73,42,22)` | `0x005DE898` / empty |

The Japanese group is 182 logical pixels wide; English is 80.
NUN5 `localized_common_prompt_rectangle` (`0x003D50C0`) selects records
6, 4, and 5 for triangle, label, and tail.

## Options-root OK and Back anchors

Both `options_present` routines pass nominal OK X=`400` and Back X=`470`
at Y=`356`. NA2 uses them directly; NUN5 converts two shared signed regional
globals to floats and adds their values first.

| Prompt | NA2 X | NUN5 adjustment | Effective NUN5 X |
| --- | ---: | ---: | ---: |
| OK | 400 | -12 | 388 |
| Back | 470 | -8 | 462 |

## Options backdrop resources

NA2 `options_initialize` acquires `option.ccs`, then
`options_construct_common_resources` (`0x0038B140`) creates the
`OptionsRootView.render_context`, `camera_player` (`ANM_option_ca`), and
`background_player` (`ANM_option_back`). Other resources belong to labels,
prompts, selection, or submenus.

`ccs_acquire_or_load` (`0x0037E1A0`) clears its ownership-output byte and
returns an already registered archive, or loads the archive and sets the byte
to `1`. Options retains the result in `archive` and the byte in `owns_archive`.
Archive destruction is permitted only with nonzero ownership.

Every `options_present` starts by selecting the render context, submitting the
camera animation, and binding its camera. Phase 7 reaches
`options_present_display_child` (`0x0038C5B0`), which submits the background
before the screen-position child. The minimal native full-frame backdrop is
the archive, render context, camera animation, and background animation;
construction of the complete Options controller or any submenu is not required
for that resource set.

## Native Controls lifecycle

NA2 `manager_options_lifecycle` (`0x001EB440`) allocates the `0x5C` Options
controller and calls `options_initialize`. Its `controls` child is `0xA0`
bytes. `options_controls_construct_resources` (`0x00387650`) loads its
registered archive resources, resets interaction, and invokes
`options_controls_initialize` (`0x00387950`) for both players' bindings and
vibration choices. `options_audio_initialize` (`0x003890F0`) initializes the
separate `audio` child.

`options_enter_selected_submenu` (`0x0038B970`) selects phase `5` for Controls
and calls `options_controls_reset_interaction` (`0x00387A40`).
`options_save_confirm_update` (`0x0038BBF0`) updates both players there and
returns to phase `0` after completion. `options_present` draws phase `5` with
the Options backdrop and `options_controls_present`. Assignment, defaults,
vibration, confirmation, and cancellation remain inside that child path.

The help banner appears before its instruction text. The first phase-5 update
changes `OptionsControlsView.state` from `0` to `2` without queuing text.
The next update calls `help_text_queue` (`0x0037F760`) with
`controls_help_messages[0]`. `scrolling_strip_draw` (`0x0037F900`) submits the
banner independently of its queue, then queued text. First enqueue through
`scrolling_strip_enqueue` (`0x0037F590`) starts `UiScrollingStrip.distance`
at 90% of viewport width, placing text 10% into the banner. The configured
30-update delay in `scrolling_strip_advance` (`0x0037F7F0`) holds that position
before scrolling; it does not postpone first appearance. Queue ownership and
scrolling behavior belong to [Running help](running_help.md).

Initialization clears the shared manager with `transition_pool_clear`
(`0x00183610`), starts a white `transition_start` (`0x00183F10`), and retains
`transition_slot`. Controls completion returns to phase `0`, clears the
manager, and requests a white `transition_opacity_out_start` (`0x00183DF0`).
The resident `global_transition_pool` holds the four-slot `UiTransitionPool`
pointer used by both paths.

### Controls rows

`OptionsControlsView` names `interaction_modes[2]`, `selected_rows[2]`,
`rows[2]`, and `staged_values[2]`. Each `OptionsControlsRows` has eight
`action_indices` followed by `vibration`. The two nine-word rows are contiguous
and immediately followed by staged values; this layout has no room for extra
rows. Native row count is nine and logical spacing is `26.8`.

| Element | Placement and gate |
| --- | --- |
| Center cells | X=`256`, Y=`57 + 26.8 * row`; nine `controls_cell_rectangles`; rows `0..3` use `face_sprite`, `4..7` `shoulder_sprite`, row `8` `menu_sprite` |
| Player labels | X=`124` / `388`, Y=`48 + 26.8 * row`; connected-pad gate |
| Cursor | Mode `2`; Y=`57 + 26.8 * selected`; `controls_cursor_rectangle` on both label sides, right horizontally mirrored |
| Row frame | Every nonzero interaction mode; player 1 / 2 `row_frames` at X=`-128` / `128`, Y=`-25.8 * row` |
| Title | `controls_title_rectangle` centered at `(256,26)` |
| Footer | Y=`356`; regional X anchors below |

`options_controls_confirm` (`0x00387E10`) moves Up/Down within `0..8`,
wrapping at either end. Circle (`0x20`) enters mode `2` and stages the row
value. Cross (`0x40`) confirms only when both players are in mode `0` or `1`;
otherwise it plays sound `0x3F` and uses `controls_help_messages[7 - side]`.
Select (`0x100`) copies nine `controls_default_rows` and shows
`controls_help_messages[1 + side]`.

`options_controls_cycle_shoulder` (`0x003881F0`, retained annotation name)
handles all row families: Circle assigns, Cross restores the staged value,
Left/Right cycle values. Face rows use `0..3`, shoulder rows `4..6`,
vibration `0..1`. Each notice replaces the banner through
`scrolling_strip_clear` (`0x0037EEE0`), then
`help_text_queue(20.0, help, message, 8, 0)`.

Drawing owners are `options_controls_draw_cells` (`0x00388460`),
`options_controls_draw_labels` (`0x003885B0`),
`options_controls_draw_row_frame` (`0x00388820`), and
`options_controls_draw_cursor` (`0x00388900`). The initializer uses the
registered `gauge` archive, `CMN/GAUGE.CCS`:

| Controls field | Asset |
| --- | --- |
| `menu_sprite` | `TEX_xmenu`: title, vibration cell, footer legend |
| `face_sprite` | `TEX_xcommand`: face-button cells |
| `shoulder_sprite` | `TEX_xcommand02`: shoulder-button cells |
| `background_player` | `ANM_xmenu01` |
| `camera_player` | `ANM_xmenu_ca` |
| `row_frames[0]`, `row_frames[1]` | `CMP_xfra_choise`, `CMP_xfra_choise01` |

`options_controls_present` submits `camera_player` and `background_player`
through `projectile_compound_submit` (`0x001BB790`) before cells and labels.
No separate nine-box draw was established in the inspected Controls code;
ownership of beige boxes by those animation objects remains an inference.
Help follows the footer. `sprite_reset` (`0x001CC070`) flushes each sprite's
accumulated draws afterwards; `shoulder_sprite` receives four cells per draw.

For these sprites, `ProjectedTextGeometryView.geometry_flags` bits `0x20` /
`0x40` swap quad corners horizontally / vertically in
`text_draw_projected_rectangle` (`0x001CC3A0`); battle sprite mirror bits feed
the same flags. Float `width` / `height` control drawn size, integer
`source_width` / `source_height` texel size. `OptionsSpriteColorView.red_green`
holds red in bits `0..7`, green in `32..39`; `blue` holds blue in `0..7`.
Both are 64-bit fields; texel color scales by color / 128.

`TEX_xcommand02` is a 64x64 4-bit texture stored bottom row first, so rectangle
Y counts from the last stored row. Its pixels remain resident in EE memory;
rows `40..63` are blank. `TEX_xmenu` is 256x128 and 8-bit with a 256-color
palette: index order in `CMN/GAUGE.CCS`, GS storage order after loading with
index bits 3 and 4 swapped. It contains down-pointing 20x22 chevrons at X=`130`,
`154`, `178`, Y=`29`: red `(240,51,51)`, blue `(74,41,237)`, green
`(21,175,76)`, with darker shading. The inspected Controls code does not draw
them. Texels X=`200..255`, Y=`26..57` are blank.

`options_destroy` (`0x0038B370`) calls `options_controls_destroy`
(`0x003874C0`) and frees the child. It releases the Options archive only when
`owns_archive` indicates ownership.

## Shared Controls and Music footer anchors

Controls and Music Options use `options_controls_present` and
`options_audio_present`. Each submits normal OK and Back, requests common
prompt case `3`, then submits the adjacent legend through
`sprite_draw_rectangle` at the same X. Footer Y is `356`.

| Footer element | NA2 X | Effective NUN5 X |
| --- | ---: | ---: |
| OK | 400 | 388 |
| Back | 470 | 462 |
| Case-3 request and companion legend | 230 | 200 |

Both NUN5 callers add the same signed regional globals (`-12` / `-8`) to
nominal OK / Back `400` / `470`. The four case-3/legend requests use the
regional shared X on both screens. In the verified NUN5 `button_icon_submit`
body, case `3` exits without submitting a rectangle; the request alone does
not prove an emitted Select icon. Its earlier visible-icon attribution remains
unresolved.

## Mode Select footer

Both `mode_select_present` routines submit common prompts and START at Y=`362`:

| Element | NA2 X | Effective NUN5 X |
| --- | ---: | ---: |
| OK | 400 | 388 |
| Back | 470 | 462 |
| START | 130 | 150 |

NUN5 adds signed regional globals to nominal OK/Back values. START goes through
`sprite_draw_rectangle` (`0x0037BC40` NA2, `0x0038AD00` NUN5), then prompt
sprites through `sprite_reset` (`0x001CC070` NA2, `0x001D1180` NUN5).
This order changes transient geometry and queues; it does not change the
selected mode, input state, or controller transitions.

NA2 `mode_select_construct_prompt_resources` (`0x00383F80`) binds
`TEX_modesel02` to `ModeSelectInput.legend_sprite`. The retail indexed
256x512 atlas is transparent from UV Y=`419` through its bottom; NUN5's
homolog is transparent from Y=`416`. The large description and START
rectangles stay outside the shared transparent region. NA2 START uses
`(1,397,206,22)`, and its sprite is finalized after that draw.

## Relationships and evidence

Compared live bodies and data establish the geometry, owners, ordering, and
gates above. Coverage is bounded to the inspected callers and screen states;
it does not establish every animation phase or indirect path. Per-routine
comments carry instruction sites, original comparison bounds, and record bytes.
NUN5 case-3 dispatch and corrected English string pointers are verified
directly; beige-box ownership remains an inference.

Options and Mode Select callbacks are owned by
[Resident front-end and mode flow](../../game/mode_flow.md). Help queues and
renderer spacing remain in their linked documents.

## Options labels and difficulty values

NUN5 `OPTION.CCS` does not contain the boot-ELF rectangle tables consumed by
the Options renderer. NA2 `difficulty_selector_draw` uses five
`options_menu_rectangles` and six `options_difficulty_rectangles`; NUN5's
homolog selects English records through language-dependent table accessors.
