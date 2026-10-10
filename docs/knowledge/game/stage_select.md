# Native Stage Select

## Research coverage

Established: object lifetime, 24-slot limits, previews, name rectangles,
atlas free area and carousel.
Established: input gates, Random bounds and eight-state ordering.
Evidence: static retail BTL, resident ELF and decoded `MAPSEL1.CCS`.
Open: button identities and input-source meaning.
Open: carousel draw-parameter effect and unscreened indirect callers.
Routine, field and data names come from `@annotations/NA2`.

The native Stage Select screen of retail NA2 (`SLPS-25837`): its choices,
stage records, previews and names, browsing, Random, and confirmation handoff.

Related owners: [Content availability](content_availability.md#resident-stage-slot-availability)
owns slot availability;
[Stages](../gameplay/stages/stages.md#stage-identity-and-resource-mapping)
owns battle-manager slot publication, logical IDs and loading;
[Practice mode](../gameplay/modes/practice_mode.md)
owns the settings parent and outer-state lifetime;
[Stage Select UI](../localization/ui/stage_select.md)
owns NA2/NUN5 layout and localization differences.

## Binary identity and address conventions

Addresses below are live BTL addresses unless marked resident. Input identities
and address conventions follow
[Retail game file identities](files/file_identities.md#address-conventions).
Annotation comments hold the per-routine code details.

## Lifetime

Resident outer state 9, `battle_state_select_stage` (`0x001ED6D0`), allocates
a `0x16C`-byte `PracticePreparationOwner` through resident `heap_allocate`
(`0x00117150`), constructs it with `stage_select_construct`
(`0x00713A50`), initializes it with `stage_select_initialize`
(`0x00713DC0`), and selects a raw load slot through `stage_select_set_slot`
(`0x007147C0`). The initializer builds the choices, selects the manager's
saved slot, loads resources through `stage_select_load_resources`
(`0x00713ED0`), then resets the screen. The outer caller's setter
subsequently selects its supplied slot.

Each invocation calls `directional_players_update` (`0x00715830`), then
`stage_select_close` (`0x00715CC0`) while the result is neither `1` nor `-1`.
Despite its inherited annotation name, `stage_select_close` is the drawing
routine. Result `1` publishes the selected raw slot returned by
`stage_select_get_slot` (`0x00714810`); either completion result releases and
frees the owner. The surrounding outer states are owned by
[Practice mode](../gameplay/modes/practice_mode.md#resident-scheduling-and-controller-lifetime).

## Object fields

`PracticePreparationOwner` names the fixed layout. Its `context` field is the
preselected raw slot; a negative value means no preselection.

| Fields | Role |
| --- | --- |
| `state`, `reinitialize` | Eight-state screen and reset request |
| `input_source` | `0`: first input record; `1`: second; `2`: bitwise OR of both |
| `context` | Preselection and settings/cancel gate |
| `choice_count`, `choices[24]`, `choice_index` | Raw load-slot list and cursor |
| `carousel_displacement` | Float displacement during browsing |
| `fade_handle`, `result`, `result_countdown` | Transition and delayed completion |
| `random_ticks`, `update_count`, `random_phase` | Random cadence, capped counter and float phase |
| `input_primary`, `input_secondary`, `input_directional` | Three input words copied every update |
| `settings`, `mapsel_container` | `0x54`-byte settings parent and `mapsel1` resources |
| `scene_draw_list`, `sprite_draw_list`, sprite and animation fields | Screen rendering resources |
| `titlebox`, `carousel` | `CMP_titlebox` and `CMP_sirinder1` objects |
| `owned_objects[24]` | TV objects indexed by raw load slot |
| `big_preview_model`, `preview_textures[4]` | `MDL_circle0` and `TEX_mappure01..04` |
| `arrow_animation`, `arrow_trigger[2]`, `extra_objects[2]` | Arrow players and trigger bytes |

Initialization chooses `input_source` from `BattleManager.control_mode`:
`5` or `2` selects the second record, `4` or `1` the first, and other values
select both. It also selects both when no manager is present.

## Choice list

`stage_select_build_choices` (`0x00714460`) appends every admitted slot
`0..23` in ascending order. Admission is resident `stage_slot_get`
(`0x001F58B0`); without a manager all slots are admitted. The on-screen order
is the resulting array order.

The 24-word `choices` array is followed directly by `choice_index`: a 25th
append would overwrite the cursor. The setter clears the cursor and
displacement, then selects the requested slot when present; an absent slot
leaves cursor 0. The getter returns `choices[choice_index]`.

## Stage records

`stage_select_records` (`0x008C3B10`) holds 24 `StageSelectRecord`s:

| Field | Meaning |
| --- | --- |
| `logical_id` | Logical stage ID |
| `preview_index` | Preview cell index |
| `name_rectangle` | Signed-halfword `u`, `v`, `width`, `height` in `TEX_mapname01` |

Rows are in raw load-slot order. Their logical IDs are
`1, 2, 23, 24, 5..22, 3, 4`; each preview index equals its raw slot.
The eight-entry `preparation_state_handlers` table (`0x008C3C90`) immediately
follows the last record.

`stage_select_find_record` (`0x007143D0`) and the preview/name paths search
the same 24 rows by the logical ID supplied by `stage_slot_logical_id`
(`0x006C14E0`). A missing row returns `-1`. Preview builders use row 0;
the name path adds the fallback described below.

## Preview images

Both paths use the record's `preview_index`, denoted `p`.

**TV objects.** `stage_select_build_tv_objects` (`0x007141C0`) creates one
`0xA0`-byte `CMP_sirinder_tv` object with `MDL_sirinder_tv` for every raw
slot `0..23`. Its cell origin is `u = (p % 5) * 96`,
`v = (p / 5) * 72 + 96`, normalized against 512×512. Resident
`sprite_uv_normalize` (`0x0037DA40`) supplies the normalized coordinates;
`model_set_uv_offset` (`0x00198840`) applies their fixed-point form.

**Inference, high confidence:** these are the 96×72 cells of
`TEX_mappure04`. The code does not identify that texture, but its image data
fills exactly a 5×5 grid at `v = 96..455`. Cells 0–23 contain images and
cell 24 is a single color.

**Big preview.** `stage_select_refresh_preview` (`0x00714520`) binds
`TEX_mappure0(1 + p / 9)` to `big_preview_model` and offsets its UV to a
168×168 cell: `u = (q % 3) * 168`, `v = (q / 3) * 168`, where `q = p % 9`.
Four textures provide 36 indices: 0–23 are retail previews, 24–26 are the
remaining image-bearing cells of `TEX_mappure03`, and 27–35 fall in
`TEX_mappure04`, the TV atlas. Visual comparison identifies cells 24–26,
with high confidence, as additional pictures of the Training Field, Hidden Leaf
Forest and Forest of Death, respectively: their scenes match
the used cells 6–8. The decoded RGBA crops are not byte-identical to cells 6–8.

The four preview textures are 512×512 indexed images stored bottom-up.
The TV grid's `v = 96..455` occupies stored rows `56..415`.


## Retail name-atlas rectangles and unused area

The 512×512 `TEX_mapname01` is indexed and stored bottom-up; coordinates here
are the top-origin sprite coordinates, after reversing the stored image rows.
The following rectangles are the signed halfwords at record offset `+8` in
`stage_select_records` (`0x008C3B10`), in raw-slot order. Preview indices equal
these raw slots.

| Raw slot | Logical ID | `u` | `v` | Width | Height |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 1 | 0 | 0 | 190 | 40 |
| 1 | 2 | 190 | 0 | 144 | 40 |
| 2 | 23 | 334 | 0 | 168 | 40 |
| 3 | 24 | 0 | 40 | 134 | 40 |
| 4 | 5 | 134 | 40 | 142 | 40 |
| 5 | 6 | 276 | 40 | 164 | 40 |
| 6 | 7 | 0 | 80 | 180 | 68 |
| 7 | 8 | 180 | 80 | 140 | 40 |
| 8 | 9 | 320 | 80 | 186 | 68 |
| 9 | 10 | 0 | 148 | 116 | 40 |
| 10 | 11 | 116 | 148 | 140 | 40 |
| 11 | 12 | 280 | 148 | 142 | 40 |
| 12 | 13 | 0 | 188 | 140 | 40 |
| 13 | 14 | 140 | 188 | 174 | 68 |
| 14 | 15 | 314 | 188 | 194 | 40 |
| 15 | 16 | 0 | 256 | 136 | 40 |
| 16 | 17 | 136 | 256 | 140 | 40 |
| 17 | 18 | 276 | 256 | 116 | 40 |
| 18 | 19 | 0 | 296 | 192 | 40 |
| 19 | 20 | 192 | 296 | 116 | 40 |
| 20 | 21 | 308 | 296 | 140 | 40 |
| 21 | 22 | 416 | 364 | 90 | 40 |
| 22 | 3 | 192 | 364 | 132 | 40 |
| 23 | 4 | 326 | 364 | 90 | 40 |

Every rectangle ends at or above `v = 404`. The full-width rectangle
`(0,404,512,108)` is therefore outside all 24 name rectangles and has zero
alpha throughout in the decoded retail image. It provides room for another
name within the existing texture dimensions. The image's entire nonzero-alpha
bounding box is `(3,5)..(505,397)` with exclusive upper bounds; the reserved
rectangle bounds, rather than visible glyph bounds, establish the safe band.

## Stage name and counters

`stage_select_selected_stage_draw` (`0x007151D0`) draws `name_sprite`
(`TEX_mapname01`) with the matched record's `name_rectangle` at `(380,298)`
through resident `sprite_draw_scaled_rectangle` (`0x0037BD00`).

On a record miss, it first draws a `(20,340,200,40)` box in `0x7F000000`
and text from resident `stage_select_fallback_names` (`0x005C04C0`), indexed
by raw slot. It then still draws the atlas name sprite with row 0's rectangle.
The fallback table has 24 Shift-JIS name pointers; its following word is zero.

`stage_select_counter_draw` (`0x00715630`) draws `choice_index + 1` at
`(192,270)` and `choice_count` at `(218,288)`, with at most two decimal digits
and no leading-zero padding.

## Carousel

`stage_select_carousel_draw` (`0x00714D40`) draws seven offsets `-3..3`
around `choice_index`. Each cursor wraps into `0..choice_count-1`, then uses
the TV object indexed by that choice's raw slot. With fewer than seven
choices, an object can appear more than once.

Ring placement uses approximately `0.62832` radians per step, including
`carousel_displacement` and, in state 3, `random_phase`. The selected entry
outside Random receives a different draw parameter from the others; its
visual effect remains unestablished.

## States and input

`directional_players_update` copies the three input words according to
`input_source`, then dispatches through `preparation_state_handlers`. The
state targets are labeled branches inside this routine.

| State | Branch label | Behavior |
| ---: | --- | --- |
| 0 | `stage_select_state_invalid` | Stores to address zero; also the invalid-state branch |
| 1 | `stage_select_state_fade_in` | Waits for fade completion, then enters state 2 |
| 2 | `stage_select_state_browse` | Browsing through `directional_players_input` (`0x00714830`) |
| 3 | `stage_select_state_random` | Random through `stage_select_random_update` (`0x00714AD0`) |
| 4 | `stage_select_state_settings` | Settings success latches result `1` and enters state 7 |
| 5 | `stage_select_state_cancel` | Latches result `-1` after the fade, or immediately with preselection; enters state 7 |
| 6 | `stage_select_state_confirm` | Waits for fade completion, resets settings and enters state 4 |
| 7 | `stage_select_state_result` | Returns the result once its countdown ends |

`preparation_owner_reset` (`0x00714700`) enters state 4 directly with
preselection; otherwise it starts a fade and enters state 1.
`preparation_settings_update` (`0x00714CB0`) propagates settings success.
Settings cancellation without preselection resets Stage Select; with
preselection it enters state 5. Completion results use a two-update countdown.

**Browsing:** `input_primary` bit `0x20` confirms, `0x40` cancels, and
`0x10` enters Random only when `choice_count >= 2`. `input_directional`
bit `0x4000` increments the cursor while displacement is at most `0.1`;
`0x1000` decrements it while displacement is at least `-0.1`. The cursor
then wraps by `choice_count`.

**Random:** every second update, resident `prng_inclusive` (`0x00180210`)
draws from `0..choice_count-1` until it differs from the current cursor.
Bit `0x20` confirms the current entry; `0x40` or `0x10` returns to browsing.
The two-choice entry gate ensures a different choice exists. Both paths use
the current choice count rather than a separate fixed Random bound.

## Destruction

`directional_players_release` (`0x00713B20`) releases the sprites, draw
lists, animation objects, both clumps, all 24 TV objects, arrow players and
settings parent before the resident caller frees the owner.

## Fixed stage-count limits

| Limit | Owning annotation or resource |
| --- | --- |
| 24 choices; a 25th would overwrite the cursor | `PracticePreparationOwner.choices`, `stage_select_build_choices` |
| Raw-slot scan `0..23` | `stage_select_build_choices` |
| 24 TV objects; slot 24 would address `big_preview_model` | `owned_objects`, construction, TV builder and destruction |
| 24 records, followed immediately by state dispatch data | `stage_select_records`, `preparation_state_handlers` |
| 24-row searches | `stage_select_find_record`, preview refresh and selected-stage draw |
| 24 fallback names | `stage_select_fallback_names` |
| 25 TV cells; 36 big-preview indices | `TEX_mappure01..04` |
