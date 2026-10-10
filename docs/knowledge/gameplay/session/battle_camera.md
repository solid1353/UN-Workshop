# Battle camera control

## Research coverage

Established: retail NA2 camera classes and activation, main-camera tracking,
stage parameters and smoothing, presentation requests and ownership, preset
families, effect adaptation, timing gates, the scoped producer families, and
the direct stage-table reader and its 24-entry limit.
Open: player-facing request and move names, vertical-axis sign, unused stage
fields, mode 1's exit alternative, visible behavior and script selectability.
Routines, structures and data use the names in `@annotations/NA2`.

## Camera classes and activation

This document covers the retail battle camera; cutscene cameras and rendering
projection internals are outside its scope. Axis roles and timing consequences
come from code. Annotation comments carry per-routine detail and bounded searches.

The graph's `BattleHub.camera` is a `CameraRegistry` (native
`ccCameraCtrl`). Its nodes share the `ccCamera` base initialized by
`camera_base_initialize`. The annotated `BattleCamera` layout names their
common view and activation fields.

| Native class | Annotated layout | Instances | Compute |
| --- | --- | --- | --- |
| `ccCamera01` | `MainBattleCamera` | One main camera, `0x1D0` bytes | `camera_stage_track` |
| `ccDummyCamera` | `BattleCamera` | Controller slot 0, `0x160` bytes | `camera_dummy_compute` |
| `ccPMCCamera` | `PresentationCamera` | Controller slots 1..3, `0x250` bytes | `camera_presentation_compute` |

The class tables are `camera_main_vtable`, `camera_dummy_vtable` and
`camera_pmc_vtable`; `camera_base_vtable` names the base table and
`cc_camera_ctrl_vtable` the registry table. The Shift-JIS `debug_name` is
`基本カメラ` for the main camera, `ダミーカメラ＃０` for slot 0, and
`演出カメラ「子」`, `演出カメラ「丑」`, `演出カメラ「寅」` for slots 1..3
(Rat, Ox, Tiger). The session's `camera_root` is the resident default camera.

Each camera owns a `0x50`-byte `EngineBattleCamera`. `camera_bind_output`
allocates it, binds the same borrowed output object for all battle cameras,
and enables node flag bit 1. `active` controls output; the registry retains
`current` and `previous`.

| Helper | Activation contract |
| --- | --- |
| `camera_registry_insert` | Deactivate a matching-output member, append the new camera, make it current and active; graph setup uses this for the main camera. |
| `camera_registry_activate` | Make the camera current and active; deactivate the old current unless `keep`. |
| `camera_registry_activate_copy` | First copy the old eye, angles, target and distance, then activate under the same `keep` rule. |

The controller uses plain `field_ctrl_append` for its four slot cameras,
which therefore start inactive.

## Common camera update and output

`camera_update` computes the class view, then `camera_update_geometry`
updates distance and the two wrapped direction angles. A nonzero compute
result makes the phase walker remove and destroy the camera.

With a zero compute result, an active camera with both its engine camera and
output object builds the view through `engine_camera_set_view` and submits
it through `camera_output_submit`. The submitted eye is
`eye + eye_offset`, and the look-at point is `target`. View construction uses
`target - eye` and axis `(0, 0, -1)`, with `(1, 0, 0)` as fallback when
direction components 0 and 1 are both zero. Component 2 is therefore the
vertical axis; the sign of “up” remains open.

Only active cameras publish a view. The camera registry runs before the
fighter registry in phase 1. Stage drawing temporarily selects each background
selector group's view and then restores the battle output; ordering is owned
by [Battle lifecycle](battle_lifecycle.md#per-update-stage-work).

These globals belong to the resident ELF's BSS:

| Global | Role |
| --- | --- |
| `active_draw_environment` | Current output pointer, published by the active camera and temporarily replaced by stage drawing. |
| `battle_camera_controller` | Published presentation-controller pointer. |
| `primary_draw_environment` | Shared battle output object restored after stage drawing. |

`camera_update` publishes `active_draw_environment`; `bg_scene_draw` selects
each background selector group's output and restores `primary_draw_environment`.
`battle_camera_controller_publish` stores `battle_camera_controller`, and
`battle_status_tick_blocked` reads its `ownership` field.

## Main camera

`camera_node_allocate` and `camera_node_initialize` create the main camera.
Its initial eye is `(0, -5000, 1500)`, both component step limits are 300, and
`snap` is set. `camera_bind_stage_record` saves the previous record and
selects the current record by `BattleManager.current.active_load_slot`, or
slot 0 without a manager. Binding occurs once per session.

`hold == 1` or `BattleManager.menu_state == 1` stops tracking and preserves
the current position. The compute uses a `MainCameraFrame` with both
fighters and a copy of `BgControl.camera_vector` obtained through
`field_copy_camera_vector`. No reader of that copied background vector was
found in the main-camera routines.

### Tracking target

`camera_select_target` chooses the look-at point from
`BattleCamera.tracking_mode`:

- Mode 0 uses the fighter midpoint and the component-1 half-spread.
- Modes 1/2 use the first/second fighter and zero the spread. Tracking
  submodes 1/2 add 100 to component 0 and -50/-100 to component 2.
- `average_third_point == 1` averages any chosen target with the frame's third
  point.

With `tracking_submode == 0`, target component 0 is clamped between the
record's `target_lower` and `target_upper`; a zero bound disables that
side. `camera_set_tracking_submode` derives the submode from fighter state,
and `camera_set_tracking_counters` controls the two retained tracking counters.

For either fighter with nonzero `section_transfer_delta`, the main compute
uses physical `position` only when its component 1 exactly equals
`section_transfer_destination[1]`; otherwise it uses
`section_transfer_origin`. It saves that point in the frame and
`saved_tracking`, clears the corresponding tracking counter, and adds 0.75
of the scaled fighter height to the vertical component.

`fighter_get_tracking_position` supplies the eased `tracking_position`
during transfers, but this independent main-camera branch does not establish
that the camera follows the eased point. Neither direction requests a
presentation event or ownership change. Transfer admission and lifetime belong
to [Section transfers](../stages/section_transfers.md#request-admission-and-retained-destination).

### Distance, elevation, and framing

`camera_compute_fit` sets `EngineBattleCamera.field_of_view` from code
constants while `dynamic_fov` is clear. The fit distance is the larger of the
fighter fit and half the frame span divided by the half-angle tangent.
`StageCameraRecord.spread_control == 1.0` disables the extra spread term.

`camera_place_eye` applies the framing contract in order:

1. With submode 0, compare lateral view edges against `edge_upper` and `edge_lower`.
   Move target component 0 back toward zero by a quarter of any overshoot,
   without crossing zero; cap target component 2 at 2500.
2. Add fit distance and spread, then clamp to `min_distance` and `max_distance`.
   `camera_min_distance` and `camera_max_distance` expose these limits.
3. Form the component-1/2 eye offset from the negative distance and the
   smoothed elevation angle.
4. In mode 0 with both fighter sections zero, raise target component 2 by
   `(distance - min) * 425 / (max - min) - 0.5 * vertical_span + 8`.
5. Add the offset to the target. With submode 0, scale eye component 0 by
   `eye_lateral_scale`; restore the chosen distance along the resulting
   direction and cap eye component 2 at `eye_height_cap`.

Desired elevation starts at zero. In mode 0, different fighter sections
subtract `differing_section_elevation`; equal nonzero sections subtract
`same_nonzero_section_elevation`. If still zero, elevation comes from the
current eye-target separation and the distance range with constant -5.0.
A nonzero tracking submode forces -20. Smoothed elevation advances one eighth
toward the desired elevation, or snaps with `snap == 1`.

### Smoothing

`camera_main_track` moves the eye and `camera_main_finish_track` the target.
Each component advances by the clamped difference (default ±300) times its
coefficient. The coefficients normally relax one eighth toward the stage
value; the transfer exceptions below assign the eye coefficient directly.

| Vector | Condition | Stage record coefficient |
| --- | --- | --- |
| Eye | Component 1 decreasing | `eye_decreasing`; 1.5 times it when an active transfer's destination component 1 is below the eye. |
| Eye | Component 1 increasing by ≥1500 / ≥100 / <100 | `eye_increasing_large`, `eye_increasing_medium`, `eye_increasing_small`; an active transfer uses half the medium coefficient. |
| Target | Equal sections, no active transfer | `target_same_section` |
| Target | Component 1 not increasing, distance ≥100 / ≥50 / <50 | `target_large`, `target_medium`, `target_small` |
| Target | Component 1 increasing without transfer, distance ≥1000 / ≥50 / <50 | `target_large`, `target_medium`, `target_small`; otherwise `target_same_section` |

Nonzero `eye_coefficient_override` or `target_coefficient_override` wins.
`snap == 1` copies the placed vectors directly.

### Fighter section-transition inputs

The smoothing exceptions use `Fighter.section_transfer_delta` and
`section_transfer_destination[1]`. Initialization, cleanup and interruption
clear the delta and end those checks; their ownership is in
[Section transfers](../stages/section_transfers.md#interruption-and-cleanup).

## Per-stage camera record

`stage_camera_records_by_slot` has 24 entries. Each points into the
contiguous `camera_stage_tracking_gains` array of `0x60`-byte
`StageCameraRecord` values. Record n serves raw slot n, whose archive is
`S(n+1)`; stage identity is owned by
[Stages](../stages/stages.md#stage-identity-and-resource-mapping).

The named fields cover smoothing, distance, target clamps, lateral edge
limits, eye height and lateral scale, section elevation, and spread control.
Offsets `+0x10`, `+0x18`, `+0x44`, `+0x58` and `+0x5C` have no direct
camera reader and retain unknown meanings.

| Archives | Smoothing | Distance | Target clamp | Edge limits | Eye cap | Lateral scale | Elevation reductions | Spread control |
| --- | --- | --- | --- | --- | ---: | ---: | --- | ---: |
| `S01`, `S02`, `S19..S22` | A | 600..4000 | ±1000 | ±1200 | 1500 | 0.8 | 2.5 / 5 | 1.2 |
| `S05` | A | 600..3800 | ±1000 | ±1200 | 1500 | 0.8 | 2.5 / 5 | 1.2 |
| `S06`, `S07` | A | 600..3600 | ±1000 | ±1200 | 1500 | 0.8 | 2.5 / 5 | 1.2 |
| `S08` | A | 600..4000 | ±1000 | ±1000 | 1500 | 0.9 | 2.5 / 5 | 1.2 |
| `S11` | A | 600..4000 | ±1000 | ±1200 | 1500 | 0.8 | 5 / 5 | 1.2 |
| `S12`, `S17`, `S18` | A | 600..3300 | ±1000 | ±1200 | 1500 | 0.8 | 2.5 / 5 | 1.2 |
| `S13` | A | 600..4100 | ±1000 | ±1200 | 1500 | 0.4 | 2.5 / 5 | 1.2 |
| `S03` | B | 600..4000 | ±1200 | ±1300 | 1200 | 1.0 | 10 / 10 | 1.1 |
| `S04` | B | 600..4000 | ±1800 | ±1500 | 2000 | 0.5 | 15 / 10 | 2.0 |
| `S09` | B | 600..4000 | ±1100 | ±1300 | 1200 | 0.6 | 10 / 10 | 1.2 |
| `S10` | B | 800..6000 | ±1300 | ±1600 | 2000 | 0.2 | 5 / 5 | 1.4 |
| `S14` | B | 600..3400 | ±1000 | ±1300 | 1200 | 1.0 | 10 / 10 | 1.2 |
| `S15` | B | 600..4000 | ±1500 | ±1500 | 2000 | 0.8 | 10 / 15 | 1.5 |
| `S16` | B | 600..3600 | ±1100 | ±1300 | 1200 | 0.8 | 10 / 10 | 1.2 |
| `S23` | B | 600..3600 | ±1200 | ±1300 | 1200 | 1.0 | 10 / 10 | 1.0 |
| `S24` | B | 600..4000 | ±1800 | ±1500 | 2000 | 0.5 | 2.5 / 15 | 2.0 |

Coefficient set A is `0.65, 0.3, 0.15, 0.05, 0.03, 0.65, 0.65, 0.15, 0.175,
0.03`; set B is `0.8, 0.4, 0.2, 0.1, 0.05, 0.8, 0.4, 0.2, 0.1, 0.05`. Field
`+0x44` is `200` except `-500` for `S10` and `-200` for `S15`.

### Stage-count limits

The pointer table is live `0x00891E10..0x00891E6F`; its 24 pointed-to
records occupy `0x00891510..0x00891E0F`. The sole recovered code reader of
the table is `camera_bind_stage_record` (`0x006D69D0`), materializing its
base at `0x006D69E8`. It saves the old pointer to `previous_stage_record`
and binds `table[slot]` without a range check. Its recovered direct caller,
`camera_node_initialize` (`0x006D6800`), supplies signed manager byte
`+0x98` at `0x006D6894`, or slot 0 without a manager. The per-field and
table-word reference scan recovered no independent reader of a fixed stage
record; compute routines consume the pointer bound here. Computed-address
and indirect paths remain outside that recovered-reference claim.

Raw slot 24 reads the word at `0x00891E70`: `0x7B96EE8A`, the beginning
of a Shift-JIS camera debug name. It is treated as a `StageCameraRecord *`,
not a default record. The table has no safe out-of-range fallback. Stage
selection/generation limits and other indexed stage data belong to
[Stages](../stages/stages.md#stage-count-limits).

Presentation mode 18 (`camera_controller_mode18`, `0x006DA6B0`) uses one
shared `camera_mode18_record` at `0x00893CD0`, not an array indexed by
stage. Its call to `stage_get_logical_id` at `0x006DA8E0` has one stage
equality exception: ID 5 adds 80 to the local eye endpoint's component 2
before the final offset write. The retail mapper returns 0 for raw slot 24;
that value, or an explicit comparison value 25, skips the addition. Common
section/segment correction continues. This does not supply a valid main
camera record for an out-of-range raw slot.

## Shared controller entry points

`BattleCameraController` is a separate `0x68`-byte presentation controller.
`battle_create_graph` constructs it with the camera registry, retains it in
the session, and publishes it through `battle_camera_controller_publish`.
`battle_destroy_graph` destroys it, clears the session pointer, and publishes
null.

| Routine | Public behavior |
| --- | --- |
| `battle_status_tick_blocked` | True only while a published controller owns presentation output (`ownership == 1`). |
| `camera_controller_request_reset` | Request `camera_controller_reset(controller, 1)`. |
| `overlay_abi_target_006dbdd0` | Write the pending event. |
| `camera_controller_set_effect` | Write the side and discriminator. |

`battle_dispatch_phases` runs `battle_camera_controller_update` at most once
per battle service update, before any registry callback, and skips it while
`menu_state == 1`.

## Address map

The live routine and data map is in `@annotations/NA2/BTL.BIN/symbols.tsv`
and `@annotations/NA2/SLPS_258.37/symbols.tsv`. Address conventions are owned
by [Retail game file identities](../../game/files/file_identities.md#address-conventions).

## Controller layout

`BattleCameraController` names the side, derived mode and previous mode,
preset and previous preset, request and previous request, pending and previous
event, discriminator, counter enable and counter, ownership, slot count,
selected and previous slot, eight slot pointers, registry and correction angle.

`camera_controller_initialize` starts with zero state and a discriminator
of -1. `camera_controller_create_slots` constructs four cameras; slots 4..7
stay null. Allocation failure is unhandled: the result is dereferenced.
`camera_controller_remove_slots` removes every nonnull slot through the
registry, then clears the registry pointer.

| Slot | Initial view or anchors |
| ---: | --- |
| 0 | Eye `(0, 0, -10000)`, target `(0, 0, -11000)`. |
| 1 | First/second fighter physical positions; offset component 2 is 140/120. |
| 2 | Same, with fighter anchors swapped. |
| 3 | Apply `camera_slot3_initial_record` through `camera_controller_apply_record` with both fighter positions. |

The presentation camera's `anchors[1]` and the main camera's
`stage_record` are distinct class fields even though they occupy the same
object offset.

## Request-to-mode mapping

A changed request derives a new mode through `camera_controller_derive_mode`.
Requests -5/-6/-7 map directly to modes 4/5/6. Request 1 queries the selected
fighter-side subsystem: results 0/1/2 map to modes 2/1/3.
Other requests pass the discriminator and request to `camera_discriminator_mode`;
an unrecognized result -1 keeps the previous mode. These are numeric control
values, with player-facing camera names still open.

| Discriminator or request | Derived mode |
| --- | ---: |
| `0x10` | 8 |
| `0x21` | 9 |
| `0x27` | 10 |
| `0x2C` | 11 |
| `0x89` | 12 |
| `0x34` | 13 |
| `0x39` | 14 |
| `0x2E` | 15 |
| `0x59`, `0x8F`, 3 | 16 |
| 1, `0x1C`, `0x6B`, `0x71`, `0x75`, `0x95`, `0xAB` | 7 |
| Other bounded skill/effect ID with nonzero `BtlDescriptorTransferRow.transfer_enabled` | 17 |
| Request -4, independent of discriminator | 18 |

`camera_controller_resolve_event` maps pending events:

| Event | Request and gate |
| ---: | --- |
| 2 | 5 |
| 3/4/5 | 2/3/4 while either fighter has nonzero `exchange_roles` |
| 6 | -1 |
| 7 | -4 |
| 8/9/10 | -5/-6/-7 |

Event 1 selects side 1 from the first fighter's nonzero exchange-role low byte,
otherwise side 2 from the second. Selected role bit 0 gives request 1.
Otherwise `camera_effect_request` maps the listed discriminator families to
requests 6..15; other signed IDs 0..`0xC4` give -3, and out-of-range values
give 0. Event 1 can therefore enter either the Extra Hit family or an
effect-specific family ([Extra Hit](../combat/extra_hit.md#exchange-state-at-fighter-0xb00)).

### Update order, event edges, and automatic requests

The controller first resolves events, overwriting the request only for a
nonzero result, then derives the mode only for a changed request. It dispatches
the mode before committing current mode, preset, request, event and slot to
their previous fields and clearing the pending event. Handlers see the
preceding update's snapshot.

Explicit events require a nonzero value different from the previous event.
Identical events on consecutive updates decode only once. **Inference:** one
zero-event update commits zero and re-arms the same event; producer timing
beyond the scoped local gates remains open.

Without a new explicit event, nonzero ownership in modes 1..3 returns request
-1 when both exchange roles are zero. Mode 1 with request 3 can instead return
request 4 when the opposite selected fighter's height differs from
`stage_query_height` and the signed difference is below 300. Side 1 chooses
the second fighter here, and other values the first. The difference is not
absolute.

`stage_query_height(position, 0x20000000)` probes from
`position + (0,0,5)` to `position - (0,0,1000)`. It returns the hit height or
the original height without a hit. The enabled controller counter advances
exactly once when `manager_menu_state_equals(manager, 0)`; otherwise it clears.

## Camera ownership switching

`camera_controller_switch_ownership` applies three states:

- 1 activates the selected slot and deactivates the main camera; a changed slot
  also becomes registry current.
- 0 reactivates the main camera, deactivates all eight slots, and clears mode,
  preset, request and slot fields.
- -1 copies the presentation view into the main camera before the same cleanup.

One camera owns output at a time. **Inference:** state 0 cuts to the main
camera's retained view; state -1 starts it from the presentation view and lets
its own smoothing return it.

## Preset orientation and non-repetition

Preset selection chooses orientation from fighter coordinates or state, takes
`prng_u32()` modulo that orientation's candidate count, and adds one before
indexing. The chosen short becomes `preset`; equality with `previous_preset`
clears the previous value to -1.

| Candidate table | Signed-short contents |
| --- | --- |
| `camera_preset_candidates_a` | 3, 3, 1, 2, 4, 5, 6, 7 |
| `camera_preset_candidates_b` | 2, 2, 10, 11, 12, 13, 0, 0 |
| `camera_preset_candidates_c` | 3, 3, 1, 2, 3, 4, 7, 8 |
| `camera_preset_candidates_d` | 3, 3, 0, 1, 2, 3, 4, 5 |

The first two shorts are the two orientation counts; subsequent candidates are
interleaved. `camera_preset_family_a`, `camera_preset_family_b` and
`camera_preset_family_c` select these or equivalent resident constant tables
by mode.

### Mode handlers and preset records

Modes 1..3 select `0xB0`-byte `PresentationCameraRecord` values by preset.
Modes 4..6 each use a fixed record. These records are shared across stages.

| Mode | Handler | Record source |
| ---: | --- | --- |
| 1 | `camera_controller_mode1` | `camera_mode1_records[preset]` |
| 2 | `camera_controller_mode2` | `camera_mode2_records[preset]` |
| 3 | `camera_controller_mode3` | `camera_mode3_records[preset]` |
| 4 | `camera_table_random_select` | `camera_mode4_record` |
| 5 | `camera_table_random_select` | `camera_mode5_record` |
| 6 | `camera_table_random_select` | `camera_mode6_record` |

`camera_presentation_apply_record` binds enabled anchor channels, chooses
supplied or inline initial vectors, copies enabled offsets and both endpoints,
and installs flags, channel delays/durations and snap behavior.
`camera_controller_apply_record` applies it to a selected slot.

The controller and mode handlers do not directly read the raw stage slot or
stage-controller global. Edge and clash correction reach the stage through
the field, and mode 18 queries `stage_get_logical_id`.

### Numeric request choreography

Modes 1..3 act on request changes. A mode change enables the counter; request
1 calls `camera_main_hold`, and request 2 calls `camera_main_release`, takes
ownership 1 and resets the counter. Requests 2/3/4 choose a new preset for side
slot 1/2. Request 4 substitutes the other fighter's queried height into an
inline anchor. Mode 1 uses it for both channels; mode 2 also forces slot 2.
Mode 3 supplies the same other-fighter anchor to both channels for all three
requests.

Request -1 disables the counter and clears main hold. Mode 2 chooses ownership
-1 after preset 22/23, otherwise 0; mode 3 chooses -1. Mode 1 assigns -1 but
then compares the current request to 3; whether this has an ownership-0
alternative remains unresolved.

Mode 2 requests 2/3 with previous slot invalidated map previous preset 1 to 9
(`camera_mode2_preset9`) and 2 to 10 (`camera_mode2_preset10`) before random
selection. Mode 1 request 2 forces preset 1/2 for native fighter ID 4.
Player-facing move names for these exceptions remain open.

Modes 4..6 choose slot 1. Mode 4 takes ownership on the request edge and
refreshes both anchors every update through `sequence_camera_anchor_eye`
and `sequence_camera_anchor_target` from the fighter's `owned_child_list`.
Mode 5 applies only on a request edge, using both fighters'
`sequence_camera_anchor` vectors and orientation-dependent endpoints.
Mode 6 also applies on the edge, ordering fighters by `afterimage_count`
before writing offsets. These belong to the separate `context_state`
sequence, rather than the Extra Hit exchange roles.

The effect variant is `CollisionSkillPrimary.camera_variant`, obtained by
`effect_get_camera_variant` at live `0x007765B0`; it is an effect value,
rather than a camera frame counter.

| Mode / handler | Entry request | Record source | Continued update |
| --- | ---: | --- | --- |
| 7 / `camera_controller_mode7` | 6 | `camera_mode7_records` | Variant 0 on entry. |
| 8 / `camera_controller_mode8` | 7 | `camera_mode8_record` | Variant 0, both anchors at the other fighter. |
| 9 / `camera_controller_mode9` | 8 | `camera_mode9_records` | Reapply a changed variant. |
| 10 / `camera_controller_mode10` | 9 | `camera_mode10_records` | Reapply a changed variant. |
| 11 / `camera_controller_mode11` | 10 | `camera_mode11_records` | Entry reads current variant; unchanged-request branch checks request 11 before refresh. |
| 12 / `camera_controller_mode12` | 11 | `camera_mode12_record` | Variant 0, both anchors from effect channel 1. |
| 13 / `camera_controller_mode13` | 12 | `camera_mode13_records` | Reapply a changed variant. |
| 14 / `camera_controller_mode14` | 13 | `camera_mode14_records` | Reapply a changed variant. |
| 15 / `camera_controller_mode15` | 14 | `camera_mode15_records` | Reapply a changed variant. |
| 16 / `camera_controller_mode16` | 15 | `camera_mode16_records` | Reapply a changed variant; force both anchor selectors to 1. |
| 17 / `camera_controller_mode17` | -3 | Effect-supplied record | Fetch and apply every eligible update. |
| 18 / `camera_controller_mode18` | -4 | `camera_mode18_record` | Counter-driven correction after the timed threshold. |

The contiguous effect block has 55 complete records, ending before the camera
debug strings. These are physical intervals; the bytes do not prove that
shipped scripts can select every index. Both channels have equal delay and
duration in these records.

| Mode | Physical indices | Enabled delay / duration |
| ---: | --- | --- |
| 7 | 0..1 | None |
| 8 | 0 | None |
| 9 | 0..5 | 0 / 93 on 0/1; other timed bits clear |
| 10 | 0..3 | 0 / 66 on 0/1; others retain duration 66 with timed bits clear |
| 11 | 0..1 | None |
| 12 | 0 | 0 / 30 |
| 13 | 0..7 | 0 / 100 on 0/1; 0 / 10 on 2..7 |
| 14 | 0..9 | None |
| 15 | 0..3 | 19 / 7 on 0/1; other timed bits clear |
| 16 | 0..15 | 10 / 15 on every record |
| 18 | 0 | 0 / 20 |

Modes 7..17 use side slot 1/2. Matching entry requests reset the counter, take
ownership 1, initialize the preset and clear a matching previous preset to -1.
Request -1 disables the counter, sets ownership -1 and clears the discriminator.
Mode 18 always chooses slot 1 and invalidates the previous slot.

Mode 17's `effect_get_camera_record` returns the active effect's
`camera_record` only while `camera_record_disabled == 0`; null keeps the
existing camera. Mode 18 anchors to `InteractionManager.camera_anchors`.
Once the counter reaches `eye_delay + eye_duration` (20 in retail),
`camera_clash_correct_angle` derives a signed angle from the two
`clash_camera_side_fraction` results. Each fraction uses the signed
`clash_counts` difference clamped to -15..15 and returns a float in 0..1.
Clash outcome and callback lifetime belong to
[Match outcomes](battle_statistics.md#jutsu-clash-outcome-selection-and-callback-lifetime).

Correction approaches `correction_angle` through `angle_approach` with
step `0x40`, suppressing negative angles for effect IDs `0x30/0x69`.
It resolves a point in the selected fighter's section, probes a segment using
its component 1, and rotates the eye endpoint unless blocked. It stores the
angle and corrected eye offset. The caller then overwrites the offset with
its local record endpoint, adding 80 to component 2 only for logical stage
ID 5 (raw slot 4). The angle store survives, but its visible contribution
cannot be inferred from that store alone.

Modes 7/10/11/13/14/15/16 first adapt base and variant through
`effect_adapt_camera_record`, which can substitute a record using effect
anchors, orientation/variant and substitution tables, then a stage segment
from an anchor raised 75 toward the record's component-0 offset.
Modes 7/11/13/14 also choose supplied anchors by the record's
`anchor_selectors`. Adaptation precedes camera initialization and does not
directly select the main per-stage camera record.

### Stage-edge correction

`camera_probe_stage_edge` reads `BgControl.boundary_min` and `BgControl.boundary_max` through
`field_get_stage_bounds`. The bounds come from
`DMY_linemin01/02` and `DMY_linemax01/02`
([Stages](../stages/stages.md#line-construction)).
It tests component 0 first, then ambiguous directions through
`collision_segment_query` from the subject raised 75 along component 2.
A blocked direction returns side code 1/2 and forces candidate 1 on that
side. Screen-left/right labels depend on orientation and remain unassigned.

### Presentation-camera smoothing

Eye and target have independent `eye_counter` and `target_counter`,
`eye_delay` and `target_delay`, and `eye_duration` and `target_duration`.
Flags `0x08/0x10` enable their timed offset movers.
`camera_presentation_initialize_motion` clears enabled counters and computes
`(endpoint - initial_offset) / max(duration - 4, 1)`.

`camera_eye_preset_update` and `camera_target_preset_update` move only for
`delay < counter < delay + duration`. With remaining updates equal to
`delay + duration - counter`, the displacement multiplier is 0.25 when
remaining is below 2 or at least `duration - 1`, 0.5 when it equals 2 or
`duration - 2`, and 1 otherwise. At exactly `delay + duration`, copy the
endpoint. Every invocation increments its counter, including delayed and
already-completed calls. These are update counts without seconds conversion.

`camera_build_eye_goal` and `camera_build_target_goal` keep an initial
anchor snapshot while a nonzero delay is unexpired (`counter <= delay`);
afterward they read the live anchor each update. Delay 0 reads it immediately.
Inline initial anchors and one-shot snapshots belong to their own channel.
Goal construction runs the enabled offset mover before final smoothing.

`camera_eye_track` and `camera_target_track` add the corresponding offset
to the channel goal. `snap_goals == 1` copies directly; otherwise each
component advances by `clamp(goal - current, -300, 300) * coefficient`,
with coefficients 0.125 and 0.25. Maximum displacement is therefore 37.5
and 75 per eligible update.

Presentation compute initializes motion before checking
`manager_menu_state_equals(manager, 1)`. A true result skips goal construction,
both movers and clearing `initialize_motion`, so initialization can repeat
while movement remains gated. Otherwise compute builds target then eye goals,
moves eye then target, restores its working frame and clears the flag.
This differs from the controller counter gate, which requires menu state 0.
Registry scheduling belongs to [Pause and replay](pause_and_replay.md).

Record application sets `initialize_motion = 1`. **Static consequence:**
mode 17 repeatedly applying a nonnull record restarts enabled channel counters
before each eligible movement update. Which timed records retail effects
supply here remains open.

## Stage- and event-driven inputs

Stage inputs are the once-bound main record, background bounds, section point
resolution, stage segment queries, and mode 18's logical-stage-5 height bias.
[Collision](../combat/collision.md) owns query contracts and
[Stages](../stages/stages.md) owns archive bounds and line data.

The scoped producer families below supply explicit events and discriminator
values. The bounded direct-call census excludes indirect producers and does
not prove every authored action reaches a listed family.

`scene_update_restricted` includes the presentation-ownership predicate.
When its combined state is true, background phase 1 disables scene selectors
2 and `0x30` once and restores them on exit through
`bg_scene_set_type_updates`. Its enabled argument is 0 on entry and 1 on
exit; the on/off interpretation remains an inference from these calls.

### Action and effect producers

Native class names identify retail code families; translated move names and
individual inherited action/asset ownership remain open.

| Producer | Event and local gate |
| --- | --- |
| `exchange_camera_event` | Exchange phases 0/1/2/6 emit 1/2/3/4. Counter zero gates entry except the scaled event-3 branch. |
| `paired_sequence_update` | Event 8 when incremented signed `afterimage_marker == 0` and the fighter side bit is clear. At `0x4C`, enter the next sequence. |
| `fighter_request_table_voice` | Sequence entry emits 9 with the fighter side bit clear. |
| `paired_sequence_finish` | Event 10 with `context_state == 5`, `substate != 5`, incremented `sequence_camera_counter > 3`; successive updates can repeat it. |
| `skill_camera_enter`, `skill_camera_exit` | Entry emits 1; exit emits 6 unless `BtlCameraExitRecordPrefix.camera_reset_on_exit == 1`, which requests reset. |
| `hak000_camera_enter`, `hak000_camera_exit` | Same entry/exit contract for `ccSkillHAK000`. |
| `fir000_camera_enter` / `skill_auxiliary_flush` | `ccSkillFIR000` entry emits 1 with discriminator 1 after its scene predicate; exit emits 6 when side pending contribution ≤0 and both substitution bytes are clear. |
| `kbt001_camera_exit`, `sin000_camera_exit`, `tnd001_camera_exit`, `for000_camera_exit`, `anb000_camera_exit` | With nonzero `camera_event_active`, request reset then emit 6. |
| `clash_initialize`, `clash_cleanup` | Setup emits 7 after publishing its first camera anchor; cleanup emits 6 after any conditional child callback. |

For phase 2 with `exchange_count == 1`, event 3 uses counter zero.
Otherwise `scale = max(0.01, 1 - (count - 1) * 0.25)` and the gate is integer
conversion of `scale * 5`. The producer runs before its phase updater
advances or resets the counter. Exchange role and action ownership remain
with [Hit response](../combat/hit_response.md).

Shared skill entry writes side `side == 0 ? 1 : 2` and its resource ID as
discriminator, emits event 1, then sets `camera_event_active`. Shared exit
checks and clears the latch before consulting metadata, preventing another
event on a repeated exit. HAK follows the same order. FIR uses `side + 1`
and literal discriminator 1. `skill_camera_reset` clears the latch before
requesting reset. Extra Hit teardown and the separate sequence termination
also request reset; they do not establish additional event producers.

FIR's pending contribution is
`InteractionManager.pending_combo_hits[side]`
([Combo accounting](../combat/combo_accounting.md#per-side-accumulated-contribution-route)).
Its substitution gates are the skill's primary and secondary substitution
bytes. Effect/action execution is owned by
[Combat action execution](../combat/combat_action_execution.md) and
[Effect-generator commands](../../runtime/effect_generator_commands.md).

### Camera-named resources

The scoped camera-named resources serve other presentation paths.
`cutin_resources_initialize` alone consumes `ANM_bg_camera`,
`CAM_%s_camera1` and `CAM_%s_camera2` alongside `battlegauge.ccs`.
`rng_case5_state_update` references `CAM_camera01`.
`skill_build_camera_resource_names` constructs `ANM_%c%c%c_camera`,
`%d_camera`, `OBJ_%c%c%c%d_camera` and `OBJ_%c%c%c_camera`.
Fixed `OBJ_camera*` names occur only in resident data tables, beginning at
`camera_named_resource_table_start`. None is a battle-camera controller input.
