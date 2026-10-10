# Movement and physics

## Research coverage

Established: ordinary locomotion, jump selection and impulses, aerial steering,
landing, contact/gravity ordering, surface axes, initialization, character-record
ranges, selected controller-marker/physics-selector boundaries, and bounded
placement-notification consumers and pass order, native floor projection, and
body-collision snapshot publication.
Open: complete caller/writer coverage, mode-4 production, combined-mode reachability,
saved-speed restoration, polygon names, and geometry-dependent landing timing.
Names come from `@annotations/NA2`.

## Evidence and address conventions

All addresses are live, following
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
The shared movement entry is `fighter_apply_movement` at `0x0024A660`.
The BTL phase consumer is `phase_event_completion` at `0x0071F160`.

The winning environment-attribute word is
`environment_published_primitive_flags`, established by
`fighter_environment_query` and its consumers.

## Shared movement fields and ordering

The fields below belong to `Fighter`. Existing annotation names are retained:
`movement_facing` is movement direction, `placement_facing` is desired
direction, and `response_facing` is facing. The names do not restrict the
fields to placement or hit responses.

| Field | Movement role |
| --- | --- |
| `position`, `orientation` | World position and orientation; ordinary height is `position[2]`, facing yaw is `orientation[2]`. |
| `major_state`, `substate`, `phase` | Action and descriptor state. |
| `primary_timeline`, `secondary_timeline` | Action cursor and phase cursor; integer thresholds use `current`. |
| `update_rate` | Multiplies speed-derived displacement and most approach factors. |
| `physics_mode` | Persistent shared-pass selector; 0 is ordinary gravity. |
| `bridge_output_age` | Signed held-direction duration used by ordinary movement. `fighter_pre_phase_step` adds 1 per call while logical bit 1 or 2 is held and clears it otherwise. `running_transition`, `surface_enter_from_running`, `surface_enter_from_air` and `landing_transition` require at least 4; other readers test only for a positive value. |
| `movement_facing`, `placement_facing`, `response_facing` | Movement angle-table index, desired direction, and facing index. |
| `response_planar_speed`, `response_vertical_speed` | Actual directional and vertical speeds. |
| `smoothed_input_speed` | Input-derived target, separate from actual speed. |
| `landing_vertical_speed`, `next_gravity` | Saved/auxiliary vertical speed and requested gravity multiplier. |
| `reaction_variant` | Low two bits select the surface axis; `0x4` marks a wall jump. |
| `contact_flags`, `ceiling_flags` | Ground `0x80`, side `0x40`, controller marker `0x20`; ceiling `0x1`. |
| `grounded_updates`, `ground_air_history` | Consecutive grounded updates and action-entry contact history. |
| `transient_input_motion`, `transient_motion` | Per-pass vector contributions cleared after movement. |

The grounded count increments up to `0x7FFF` and clears while airborne.
Contact-history low nibble 1 means grounded at action entry, 2 airborne;
`0x10` latches an air-entered action's ground arrival, and `0x20` a
ground-entered action's departure.

With `update_pause.current < 1`, `fighter_update_movement_slot` runs
`fighter_movement_pass` and then `fighter_advance_animation`.
The wrapper sets surface-axis orientation before the shared integration.
Axes 0/1 use the ordinary vertical component; axes 2/3 rotate motion and use
the X component for surface contact. Final world displacement along
`position[1]` is zero in every case.

The shared pass constructs displacement from current speeds and
`update_rate`, adds the transient vectors, resolves side/floor/ceiling
contact, and applies gravity to the speed for the next pass. Overlap and
movement-segment corrections precede the final position write. Gravity
therefore does not alter the current pass's already-constructed displacement.
The slot clears both transient vectors afterwards. Pause and hit-specific
scheduling belong to
[Hit response](../combat/hit_response.md#pause-lock-and-update-order).

## Gravity and input smoothing

`fighter_load_character_record` supplies the copied movement parameters.
`apply_gravity` uses them outside major 8; major 8 uses the current
character's static record from `character_definition_table`.
For ordinary motion:

```text
v_next = max(v - multiplier * gravity_factor * 3 * update_rate, terminal)
terminal = -terminal_factor * 3   when multiplier == 1
terminal = -FLT_MAX               when multiplier != 1
```

A zero multiplier skips gravity. Major 5, nonzero `exchange_roles`, or
`state_flags & 0x80` uses the separate fixed-gravity contract in
[Hit response](../combat/hit_response.md#gravity).
Ordinary mode 0 resets `next_gravity` to 1 after gravity, making it a one-pass
request. Ungrounded mode 3 bypasses that reset and the later corrections.

`fighter_pre_phase_step` smooths the published logical input before state
transitions. Logical bit 1 precedes bit 2, choosing desired direction 0/1;
either increments the signed duration, while neither clears it. Grounded
input targets `ground_target`, with `ground_braking` on release. Airborne
input targets `recovery_planar_speed`, with `effect7d_motion_scale_b` on
release. With input held, `stick_magnitude` supplies the approach factor.
State handlers decide how this target becomes actual motion.

`fighter_set_scaled_velocity` scales a factor by `update_rate` unless it is
exactly 1, caps it at 1, and snaps an error below 0.1. Its primitive
`scalar_approach` is proportional:

```text
value += (target - value) * factor
```

At unit rate, factor 0.3 closes 30% of the remaining difference per update;
it is not constant acceleration.

## Ordinary state dispatch

The unpaused `fighters_update` order is `fighter_copy_input_outputs`,
`fighter_pre_phase_step`, `fighter_update_phase_and_exits`,
`fighter_consume_logical_input`, then `fighter_dispatch_action_update`.
Existing-state transitions and new requests are separate passes: a request
can replace the state whose transition handler already ran. The subsequent
movement/animation pass is owned by the hit-response scheduling contract.

`action_descriptor_table` supplies the retail strings below; their
`action_name_*` labels retain the identifiers in annotations. The ordinary
interval `0x0E..0x26` contains 25 descriptors.

| Major/substate | Retail descriptor | Behavior owner |
| --- | --- | --- |
| `(0,0)` | `ACT_NUT_0` | Neutral; loses ground into `(3,0x1E)`, held direction starts major 1. |
| `(1,0x0E..0x11)` | `ACT_RUN_0..3` | `running_transition`, `running_motion_update`. |
| `(1,0x12..0x14)` | `ACT_WMV_0..2` | `surface_movement_transition`, `surface_movement_update`. |
| `(1,0x15/0x16)` | `ACT_LIN_0/1` | `section_transfer_motion_update`; section-transfer owner. |
| `(2,0x17)` | `ACT_JMP_0` | Preparation; `jump_transition` waits for startup or ground loss. |
| `(2,0x18/0x19)` | `ACT_JMP_V1/V2` | First/second low-directional-input variants. |
| `(2,0x1A/0x1B)` | `ACT_JMP_F1/F2` | First/second directional variants. |
| `(2,0x1C/0x1D)` | `ACT_JMP_B1/B2` | B1 changes movement direction; B2 also depends on the prior variant. |
| `(3,0x1E/0x1F)` | `ACT_FAL_0/FT` | Ordinary fall and input-triggered faster descent. |
| `(3,0x20..0x25)` | `ACT_FAL_V1/V2/F1/F2/B1/B2` | Corresponding post-jump states. |
| `(4,0x26)` | `ACT_LND_0` | `landing_transition` and shared landing deceleration. |

### Ground motion and facing

Grounded neutral begins running after one held-direction update. Matching
movement and desired direction selects `0x0E`; a changed direction selects
`0x10`, except speed/ground-target above 0.5 selects `0x11`.
The bounded shared consumers use `ACT_RUN_0` for weak and strong input.
Input amount changes the approach toward the same target; a separate walk
state or every possible character-specific callback is not established.

| Run substate | Motion and exit |
| --- | --- |
| `0x0E` | Approach smoothed input with ground acceleration; publish desired movement/facing on entry or direction change. Release above half target enters `0x0F`, otherwise neutral. |
| `0x0F` | Brake toward zero with ground braking. |
| `0x10` | Neutral-entry turn; brake toward zero. Four held-direction updates permit running; descriptor completion returns to neutral. |
| `0x11` | High-speed reversal; above half target brake with ground braking × 0.66, otherwise approach negative ground target with acceleration × 1.8. `running_exit` turns negative speed positive and publishes the new direction. |

Every variant snaps speed to zero when side contact is on the current movement
side, and falls into `(3,0x1E)` on ground loss. While already in `0x0E`,
only a direction change above half target enters `0x11`; a slower change
stays in `0x0E` and publishes the new direction without neutral's turn route.

Movement direction and facing can differ. `movement_direction_angles`
contains `{+pi/2,-pi/2,0,-pi}`, so ordinary indices 0/1 move in positive/
negative X. Facing uses `angle_approach_signed_gain`.
`neutral_prepare` derives all three indices from yaw, first negating speed
if movement and facing disagree. Re-entering the same action still runs the
old exit and new preparation before `fighter_set_action_state` returns early.

### Jump requests and state selection

Logical input `0x10000` reaches `jump_request`, which rejects major 8 and
a nonzero action lock.

| Source | Admitted result |
| --- | --- |
| Neutral, substates 3/4/5, run `0x0E..0x11`, landing `0x26` | Preparation `(2,0x17)`; landing first derives directions from orientation. |
| First jump `0x18/0x1A/0x1C`, first post-jump `0x20/0x22/0x24`, fall `0x1E` | Second-jump selection. |
| Second jump `0x19/0x1B/0x1D`, second post-jump `0x21/0x23/0x25`, faster fall `0x1F` | Another jump only with side contact, `side_damage_attributes & 0x100`, and desired direction different from `contact_side`. |
| Surface `0x12/0x13` | Detach, set wall-jump bit 4, enter `(2,0x1B)`. |
| Preparation `0x17`, surface `0x14`, transfer `0x15/0x16` | No jump admitted by this helper. |

Preparation brakes with ground braking × 0.33. The first jump is selected
when the primary integer cursor reaches `jump_preparation`, or immediately
on ground loss. In `jump_select_variant`, matching directions give V1
unless magnitude is at least 0.3 and logical bits `0x10/0x20` are both
clear, which gives F1. Changed direction gives B1 and publishes movement
direction.

The same magnitude/bit predicate qualifies directional second-jump input:

| Movement/desired direction | Source B1 or FAL_B1 | Other admitted source |
| --- | --- | --- |
| Equal | B2 when qualified, otherwise V2 | F2 when qualified, otherwise V2 |
| Different | F2 when qualified, otherwise V2 | B2 regardless of input amount |

A changed-direction second selection publishes desired movement direction.
Qualifying wall contact sets wall-jump bit 4; otherwise selection clears it.

### Jump impulses and aerial control

`jump_impulse_update` installs the impulse when the primary timeline crosses
event zero. With `g = motion_scale * 3`:

```text
v_first  = sqrt(first_jump_height  * effect_height_factor * g * 2) - g/2
v_second = sqrt(second_jump_height * effect_height_factor * g * 2) - g/2
```

Ground primitive flag `0x800` doubles the grounded first-jump height.
A second jump with the wall-jump bit uses fixed height 300 and the full aerial
directional target. Otherwise first planar speed is
`air_target * normalized_input`, second is that value × 0.75.
Normalization divides smoothed input by the grounded or airborne target;
the 74 dedicated records have nonzero targets. V1/F1 publish movement and
facing, while B1 publishes only movement, allowing the two to differ.

`effect_jump_height_factor` adds each active
`AwakeningEffectNode.payload_80 - 1` to a starting value of 1, rather than
multiplying individual factors. Effect identities and writers belong to
[Battle items and status effects](../projectiles_and_items/battle_items_and_status_effects.md).

Outside the impulse crossing, jump and fall handlers use
`aerial_steering_update`. Input below 0.3 brakes toward zero. Matching
direction in variant 0 can approach smoothed input; opposite direction or a
target below current speed instead approaches `current_speed - input_target`
with a negative aerial clamp. Variants 1/2 otherwise retain speed.
A wall jump through primary cursor 9, or speed above the aerial target, skips
these ordinary approaches. Steering is stateful rather than a direct
stick-to-velocity assignment.

Completion maps `0x18/19 → 0x20/21`, `0x1A/1B → 0x22/23`, and
`0x1C/1D → 0x24/25`; ground contact enters landing `(4,0x26)`.
Landing brakes with ground braking × 0.8. Matching desired direction with
either movement or facing permits locomotion from cursor 5 with duration 4.
When desired direction differs from both, cursor below 5, duration at least 4,
and speed above 30% of ground target first snap to that target and enter
reversal `0x11`; otherwise this case waits for cursor 8 and duration 4.
The subsequent selection retains the half-target reversal gate. Descriptor
completion can then return to neutral even after a locomotion branch changed
state earlier in the same call. Ground loss immediately returns to ordinary fall.

Faster descent `0x1F` writes vertical speed
`-(terminal_factor * 3 * 0.6)` and cooldown 10 at event zero, then uses
variant-0 steering. `fast_fall_transition` retains it with unavailable
auxiliary floor distance but nonzero auxiliary flags. Otherwise a floor nearer
than half scaled fighter height permits landing only while grounded; without
that nearby floor it becomes `(3,0x22)`.

## Character movement parameters

`character_definition_table` has 94 eight-byte entries and 78 distinct
movement parameter blocks. The ranges cover 74 dedicated fighters, excluding
fillers and the four zero-valued auxiliary metadata records; identities belong to
[Character identity](../characters/character_ids.md#character-definition-table).

The static fields are in `AwakeningCharacterRecord`; this type's existing
name is retained for the ordinary character records. Copied fighter names are
also retained even where their original annotation described another consumer.

| Record field / Fighter field | Contract | Dedicated-record range |
| --- | --- | --- |
| `contact_height / contact_height` | Query height, multiplied by `capture_uniform_scale` | 120..180 |
| `contact_width / contact_width` | Query width, multiplied by the same scale | 100..160 |
| `ground_target / ground_target` | Ground directional target | 7..30 |
| `ground_acceleration / ground_acceleration` | Proportional acceleration | 0.125..0.35 |
| `ground_braking / ground_braking` | Proportional braking | 0.2..0.35 |
| `gravity_factor / motion_scale` | Gravity decrement × 3 at unit rate | 0.95..1.5 |
| `terminal_factor / effect7d_motion_value` | Terminal downward magnitude × 3 | 10..20 |
| `aerial_target / recovery_planar_speed` | Aerial directional target | 10..16 |
| `aerial_steering / effect7d_motion_scale_a` | Proportional steering | 0.02..0.06 |
| `aerial_braking / effect7d_motion_scale_b` | Proportional braking | 0.01..0.05 |
| `jump_preparation / jump_preparation` | Integer action-cursor threshold | 2..7 |
| `first_jump_height / first_jump_height` | First height parameter | 250..400 |
| `second_jump_height / second_jump_height` | Second height parameter | 200..300 |

Floats are rounded to authored decimal values. Speeds are game-space units per
active movement update before rate scaling, not units per second. Height
parameters feed the impulse formula; they do not promise an apex above arbitrary
geometry.

| Character / record | Ground | Gravity decrement | Terminal magnitude | Air | Preparation | H1 / H2 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Naruto 57 / `naruto_character_record` | 21 | 3 | 34.5 | 16 | 3 | 290 / 220 |
| Sakura 58 / `sakura_character_record` | 24 | 2.85 | 33 | 15 | 3 | 300 / 250 |
| Fourth Awakened Naruto 73 / `nine_tails_fourth_character_record` | 26 | 3 | 34.5 | 16 | 3 | 290 / 210 |
| Might Guy 69 / `might_guy_character_record` | 30 | 4.05 | 60 | 14 | 4 | 400 / 300 |
| Sasori (Hiruko) 76 / `hiruko_character_record` | 7 | 4.5 | 45 | 10 | 7 | 250 / 200 |
| Second Stage Kidomaru 53 / `kidomaru_second_stage_character_record` | 19.5 | 3 | 36 | 12 | 4 | 400 / 250 |

These are shared-record variations, not a complete audit of special callbacks.

## Floor, side surfaces, and limits

Movement does not use one global floor height. `fighter_environment_query`
queries registered environments through `fighter_environment_collect`,
returns the nearest retained distance, changes the endpoint to the winning
point, and publishes its primitive flags. No hit returns -1.
[Collision](../combat/collision.md) owns the generic
`collision_segment_query` and primitive structures. The fighter query's
registry walk, distance retention, and result storage are recorded in annotations;
its attribute predicate belongs to
[Stage surface attributes](stage_surface_attributes.md#query-eligibility-and-contact-classes).

| Fighter output | Meaning |
| --- | --- |
| `side_probe_distance`, `side_damage_attributes`, `contact_side` | Side distance, direct side-contact primitive flags and side selector. `fighter_probe_sides` probes both directions up to 1.5 widths; direct contact uses `fighter_publish_side_contact`. |
| `floor_probe_distance`, `floor_probe_attributes` | Auxiliary downward distance and flags from `fighter_probe_floor`; ray starts half a scaled height above position and ends two heights below. |
| `movement_flags` | Primitive flags of the direct ground-contact decision, distinct from auxiliary flags. |
| `ceiling_probe_distance`, `ceiling_damage_attributes` | Upward clearance and direct ceiling-contact flags; `fighter_probe_ceiling` supplies auxiliary clearance. |
| `contact_flags`, `ceiling_flags` | Side, ground and ceiling bits cleared and recomputed each pass. |

Unavailable distance is -17320.5078125, not a world height or valid distance.

`fighter_probe_floor` (`0x0021C240`) writes only the auxiliary floor distance
and attributes; it does not publish grounded contact, move the fighter or
refresh contact history. `fighter_probe_sides` (`0x0021BCC0`) similarly
publishes auxiliary distance/side selection rather than the full direct
side-contact state. A successful auxiliary query is not a complete contact
refresh.

The shared movement pass snapshots prior grounded state before clearing
ground/side/ceiling bits and the three probe distances. Its subsequent contact
branches use that snapshot as well as current action, surface axis and physics
mode. Even with zero actual speeds it can apply gravity, overlap projection
and movement-segment correction, then write position and grounded history.
Calling it is therefore a movement operation, not a query-only refresh.

| Axis | Side mask | Down mask | Up mask | Contact component / normal |
| --- | --- | --- | --- | --- |
| 0/1 | `0x40000000` | `0x20000000` | `0x80000000` | Vertical / positive |
| 2 | `0xA0000000` | `0x40000000` | `0x40000000` | X / negative |
| 3 | `0xA0000000` | `0x40000000` | `0x40000000` | X / positive |

The direct downward ray follows candidate displacement and extends by a height
fraction when vertical motion is zero. An ordinary-axis miss retries after a
planar offset of width × 0.25 if previously grounded, or × 0.125 if airborne.
Accepted floor contact saves the pre-contact vertical speed on first grounding,
clears actual vertical speed, sets grounded, and replaces vertical displacement
with the hit-point delta.

Attribute `0x10000` is selectively passable: majors 2/3 skip grounding with
logical bit 8 or faster-fall `0x1F`; other state/phase gates can also decline
it. Its player-facing name is open. `fighter_polygon_contact_class` can
further decline ordinary grounding; response consequences belong to
[Hit response](../combat/hit_response.md#response-exits).

Ceiling contact replaces displacement with the ceiling-hit delta minus fighter
height and halves positive vertical speed. Later auxiliary-distance corrections
resolve under-floor and over-ceiling overlap unless a major-8 record has
`ActionRecord.category & 0xC0000`. The final movement-segment query uses mask
`0xE0000000`; a hit corrects position and damps directional speed toward zero
with `min(1, 0.25 * update_rate)`.

### Native floor projection and contact publication

The native midpoint placement paths `pair_place_at_native_midpoint`
(`0x007945E0`) and `pair_restore_native_midpoint` (`0x00797980`) call
`pair_placement_project_floor` (`0x00786D60`) with depth 1000 after publishing
the candidate coordinate. With an enabled participant and a present fighter
and battle hub, it queries from current position plus half scaled height down
to current position minus that depth. The generic `collision_segment_query`
arguments are `(0x20000001,1,0,-1)`. A hit writes the endpoint to the output;
a miss leaves the output unchanged. These callers ignore its return value.
The helper can separately return masked surface-class bits, but these two
calls supply no such output. Its disabled/absent-participant paths do not
initialize the source vectors, so it is not an unrestricted coordinate API.

Neither helper nor these complete midpoint bodies publishes grounded, side,
ceiling, probe/history, speed or placement-notification state.
`pair_placement_publish_section` (`0x00796610`) publishes only the selected
fighter's section and the paired target section; the restore body makes the
equivalent stores inline. Their enclosing gameplay roles remain unclassified.
The initial and downed-recovery tuple stores likewise do not constitute a full
contact refresh. [Stages](stages.md#resident-generic-factories-and-mandatory-records)
owns the authored placement tuple and its component-2 offset of 200.

The ordinary direct ground decision remains inside `fighter_apply_movement`.
At `0x0024AE7C..0x0024AEEC`, a false prior-grounded snapshot and exactly zero
axial displacement add positive `0.0001` before the strict magnitude snap;
the downward branch requires a nonpositive result. This differs from the
grounded zero-motion path. Skipping the direct decision does not republish
the current or retained ground word. Auxiliary overlap correction can then
change position without supplying that missing direct decision. Thus a
zero-speed pass with cleared grounded state does not guarantee grounding at
an otherwise projected coordinate.

A selected downward hit calls `fighter_polygon_contact_class` before the
grounded store. Its special-class paths can create effects, debit chakra and
count statistics, or reject grounding. Contact publication is therefore a
state-dependent gameplay operation, even when speed is zero. Surface classes,
query eligibility and current/retained word ownership belong to
[Stage surface attributes](stage_surface_attributes.md#attribute-data-flow).

### Body-collision snapshots across movement

`fighter_refresh_body_collision_spheres` (`0x0021FA60`) writes the two
embedded body-sphere centers from current position when
`section_transfer_delta == 0`, otherwise from the retained transfer vector.
The second center can instead use evaluated model/bone X and Z. Its first
z-bias is 0.4 scaled height, or 0.15 under
`fighter_uses_low_response_collision_shape` (`0x00230D50`); neutral `(0,0)`
does not select that low shape. It supplies no environment-contact or action
transition. `fighter_prepare_collision_queries` (`0x0021E390`) is broader
construction/setup work and also changes registrations and source pointers.

The ordinary body refresh is called at `0x0024DF28` in
`fighter_update_timelines_slot`, in phase 3 after the contact/node/first-pass
and pause gates. Earlier movement temporarily installs its own candidate
center/radius/bias, runs `sphere_resolve_active` with environment mask
`0x40000001`, applies correction, then restores its saved sphere vectors and
dimensions (`0x0024B98C..0x0024BD00`). The resolver reads the other active
spheres' stored centers; changing both fighter positions alone does not
change those centers. **Inference:** movement immediately after paired
coordinate publication can still resolve against pre-publication body
snapshots until their producer runs. Refreshing one fighter at a time does
not establish a coherent pair snapshot. The simple sphere chain and query
registrations have separate activation contracts, owned by
[Collision](../combat/collision.md#resident-query-list-boundary).

### Surface-axis movement and special character gate

`surface_enter_from_running` admits axis 1 after more than three held
direction updates, chooses axis 2/3, offsets horizontally by 0.75 scaled width
and vertically by 0.25 scaled height, then enters `(1,0x12)`.
`surface_enter_from_air` additionally requires side attribute `0x100`
and chooses surface `0x12` or `0x13`. These are gated surface paths.

Surface `0x12` accelerates toward smoothed input, `0x13` snaps speed to
zero, and `0x14` brakes. `surface_segment_eligible` checks a projected
segment with mask `0x40000001`; a miss is treated as attribute `0x100`,
while a hit requires that attribute to remain eligible. Transitions route
ineligibility, input change, side contact, release and completion to stop,
detach, or ordinary running/falling.

`item_fighter_air_setup` clears the surface-axis bits. A requested detach
also offsets X away from the surface by half scaled width, publishes ordinary
facing, and clears grounded. A changed-direction detach from `0x13` can enter
`(2,0x1B)` with fixed height 100 and primary cursor 1, skipping the normal
event-zero impulse. That path differs from the height-300 ordinary wall jump.

For Kazekage Gaara 59 and Deidara 64, the shared pass samples controller marker
`contact_flags & 0x20` before contact flags clear. In mode 0 it applies gravity
without reversing vertical speed's sign: downward magnitude is reduced then
its sign restored; positive speed clamps at zero if gravity would cross it.
The marker also supplies the additional downward probe and final-ground rule
described below. Animation presentation is not established.

World height is capped at 3000 while `state_flags & 0x80` is clear,
clearing positive speed; the lower clamp is -500, grounded with zero vertical
speed. The marked Gaara/Deidara floor is -460 outside majors 5/6.
At height at most -500 the next request pass enters recovery `(6,0x61)`
unless already in `0x61/0x62`.
[Stages](stages.md#boundary-and-floor-profile-data) owns the separate boundary
and floor-line services; they are not established as every movement probe's source.

### Gaara and Deidara marker lifetime and ordinary dispatch

The movement gate is the awakened controller marker, separate from the character
variant byte. `input_sector_widen_state_b` sets it on ordinary entry;
`input_sector_widen_state_a` supplies Deidara's effect-presence adoption route.
`awakening_dispatch`, `awakening_reconcile`, and `awakening_clear_marker`
provide suppression/reconciliation/removal. Their special-flag `0x10`
cleanup clears neither the physics selector nor actual speed, so marker removal
is not a complete movement reset. Activation, effects and variants belong to
[Awakening](../characters/awakening.md#per-fighter-dispatch) and
[Deidara and Gaara character variants](../characters/awakening.md#deidara-and-gaara-character-variants).

Ordinary activation requires `(major,substate,phase) = (0,3,2)`,
`action_progress_blocker == 0`, and a secondary timeline crossing of selector
0 for Gaara or 6 for Deidara. `gaara_awakening_trigger` has flags `0x10`;
`deidara_awakening_trigger` has `0x11`, whose extra bit 1 admits adoption.
`action_descriptor_prv_0` identifies `ACT_PRV_0` through
`action_name_prv_0`; this retail identity does not establish a player-facing
name. Predicate and association ownership remain in
[Awakening's raw state predicate](../characters/awakening.md#raw-state-predicate)
and [ordinary controller entry](../characters/awakening.md#ordinary-controller-entry).

Construction clears the marker. Ordinary movement, its slot tail, and state
changes retain it; this is controller state rather than a per-pass flag or a
fixed duration. Other exits and effect lifetimes belong to
[Controller exit and reconciliation](../characters/awakening.md#controller-exit-and-reconciliation).

With `node_flags & 2`, controller dispatch precedes the movement-slot pause
test. Only the unpaused branch then runs `awakened_vertical_input`, the
movement wrapper, and animation. Reconciliation can therefore clear the marker
during a paused movement pass; the integration samples the ID/marker predicate
once before clearing contact bits.

Altitude input uses the same predicate, leaves majors 6/8 untouched, and admits
held up/down in major 1 or major 0/substate 0/4. Other admitted states approach
zero. It prepares vertical speed and the gravity multiplier immediately before
displacement construction; the sampled marker independently changes gravity and
contact. Authored altitude values and input-sector interpretation belong to
[Action commands](../combat/action_commands.md#logical-mask).
The request pass bypasses ordinary held-up `(0,3)` and held-down `(0,4)`
entries under this marker; its jump branch remains outside those bypasses.

The additional ray extends downward by 40 and adds 40 back to an accepted
hit-point delta. A miss does not create a constant 40-unit displacement.
The marker rejects attribute `0x10000`. After integration and world limits,
the pass updates `grounded_updates` and `ground_air_history`, then forces
grounded outside major 2. **Inference:** that final bit alone does not prove
the count/history recorded actual floor contact on the same pass.

Marker, effect association, variant byte, physics selector, and surface-axis
bits are independently gated. Their consumers do not prove all combinations
reachable.

## Special physics selector and return to ordinary motion

`fighter_set_physics_mode` snapshots actual vertical speed into
`landing_vertical_speed` for modes 1/2 and clears it for 0/3/4.
The mode persists across updates; the setter does not imply restoration of saved
speed. The gravity multiplier's one-pass contract is separate.

| Mode | Shared consumer contract |
| --- | --- |
| 0 | Ordinary side, auxiliary floor/ceiling and direct vertical contact; ordinary gravity, including the marked Gaara/Deidara branch. |
| 1 | Side and auxiliary queries retained, direct vertical contact skipped. Ungrounded actual speed gets unit-multiplier gravity then a nonnegative clamp; saved speed separately gets gravity. |
| 2 | Same query selection; ungrounded actual speed approaches zero with `min(1,0.25*update_rate)` and 0.1 snap, while gravity advances saved speed. |
| 3 | Initial contact-query block skipped. If still ungrounded, unit-multiplier gravity advances actual speed then integration bypasses multiplier reset and later overlap/segment corrections. |
| 4 | Wrapper snaps actual speeds to zero and clears transient vectors. The shared pass admits the ordinary contact block but has no ungrounded mode-4 gravity branch. Producer open. |

All modes reach the final world limits and contact bookkeeping. Mode 3's
shortcut depends on the recomputed grounded bit; it is not an unconditional
return.

### Selected producer and reset boundaries

The bounded direct-store census is recorded with the movement annotations.
It establishes selected resident halfword writers, not the absence of wider,
displaced-base or computed writes, and not a full character-callback audit.

Construction and placement clear mode and saved speed. Neutral preparation
reaches `exchange_teardown` only with its own exchange role; running/landing
cleanup and `fighter_set_action_state` have no universal selector reset.
**Inference:** entering an ordinary state alone does not prove the selector
returned to zero.

| Boundary | Selector contract |
| --- | --- |
| `response_exit_cleanup` | Clear mode and saved speed only when `exchange_roles == 0`. |
| `response_update_ordinary` | Its action-row gate selects mode 1 and snapshots vertical speed, or mode 0 and clears saved speed; these are response paths. |
| `fighter_action_rate_reset_a`, `fighter_action_rate_reset_b` | Exchange paths select modes 1/2; completion clears both fighters. |
| `action_update_jutsu_record` | Requires a current record; roles `& 3` route the first writer with priority, otherwise `& 0xC` or `& 0x30` route the second. |
| `exchange_teardown` | Clears both fighters only when at least one has a nonzero exchange role. |
| `exchange_receiver_update` | Additional targeted clear paths. |
| `exchange_terminal_handoff` | Cleanup before neutral/fall when terminal is nonzero, own recovery is `0x61/0x62`, or the paired fighter is in major 6. |
| `recovery_init`, `neutral_prepare` | Preparation cleanup only with own exchange role. |

The exchange gate is independent of the controller marker. Admission and
choreography belong to
[Combat action execution](../combat/combat_action_execution.md#continuation-and-common-exit-decisions)
and [Action commands](../combat/action_commands.md#selector-modes-and-entry-gates).

The reported direct caller of the mode setter is `jutsu_connection_cleanup`,
which installs the Ultimate Jutsu owner and gives the paired fighter mode 3.
`opponent_lock_override` establishes the connected current-record route;
complete admission and presentation belong to
[Ultimate Jutsu](../characters/ultimate_jutsu.md#start).
`jutsu_post_cinematic_update` clears the paired mode and saved speed in its
state-1 continuation before ordinary handoff. Its failed-precondition branch
clears local sequence fields and returns without a fighter-selector store.
Reachability of that branch after live mode-3 entry and surrounding cleanup
remain open; it is not evidence for universal interruption cleanup or mode 4.

Ground contact retains the selector while it may save pre-contact vertical
speed and clear actual speed. Final height clamps also clear actual speed
without clearing the selector. Reconstruction and participant-removal ordering
belong to [Battle lifecycle](../session/battle_lifecycle.md) and
[Battle entities](../session/battle_entities.md).
No named authored action is assigned to an untraced producer.

## Initialization, history, and descriptor lifetime

`fighter_init` constructs neutral movement state: mode, duration, three
direction/facing indices, actual/input/saved speeds and contact history zero;
gravity multiplier and dimension scale 1; surface/wall-jump bits clear;
probe distances unavailable. This does not imply neutral entry repeats
construction.

`fighter_initialize_placement` obtains position, orientation and section from
`field_player_placement`, marks placement, clears actual/saved speed and mode,
derives directions from yaw, clears the retained attack record, fills all eight
`placement_history` vectors, and enters neutral. Section and spawn data belong
to [Stages](stages.md). `fighter_update_countdowns` separately fills the
`previous_position` and previous direction/contact-side snapshots consumed by
[Target selection](../combat/target_selection.md#paired-opponent-and-geometry-refresh).

The placement method stores its tuple and marks `state_flags & 0x40` before
calling `fighter_set_action_state` at its tail. It does not clear the two
transient vectors, reset the history-ring cursor, copy `previous_position`,
or clear pause/rejection/action-lock clocks. Old-state exit and preparation
can therefore act after the new tuple has been stored. Their conditional
effects belong to [Combat action execution](../combat/combat_action_execution.md#common-exit-boundary).

### Placement notification and pass order

The byte-read screen of resident ELF and BTL inspected 286 aligned sites in
189 containing functions and found eight local tests of placement bit `0x40`:

| Consumer | Established use |
| --- | --- |
| `fighter_model_attachments_rebase_on_placement` | Requests rebase across the owned animation player's compositions under activity/menu gates. |
| `linked_effect4a_display_reset` | Refreshes retained linked presentation, opacity and attachment rebase. |
| `fighter_auxiliary_composition_step` | Requests rebase on the auxiliary composition. |
| `battle_attachment_composition_step`, `battle_state_attachment_composition_step` | Request composition rebase before stepping. |
| `fighter_id_018_attack_timer_pass` | Resets Classic Kankuro trails regardless of the hold branch. |
| `kankuro_route_puppet_attacks`, `chiyo_route_puppet_attacks` | Reset trails inside their positive-hold branches. |

Rebase ownership belongs to
[Composition attachment dynamics](../../runtime/rendering/composition_attachment_dynamics.md#bounded-caller-coverage);
sample-reset gates belong to [Puppet control](../characters/puppet_control.md#draw-admission-update-and-reset-remain-separate).
The screen covers unsigned byte reads at `+0x61` with a nearby bit test.
Wider, rebased, computed or more distant reads remain outside it; eight is
not a whole-game consumer count.

`fighters_phase_slot_0c` (`0x002504B0`) calls `fighters_update` at
`0x00250658`, the generic `list_phase_slot_10` movement/animation pass at
`0x00250664`, then character auxiliaries at `0x00250670`.
The first call runs maintenance before collision responses, input processing
and action updates. Maintenance's `fighter_update_countdowns` snapshots
history and clears placement bit `0x40` near its tail, including when node
update is disabled. Every coordinator-state branch rejoins the common tail;
it has no ordinary-state-zero admission check. The generic pass can remove
flagged nodes before reaching their movement slot, so borrowed manager aliases
do not alone establish surviving list membership.

The boundary after `fighters_update` has already passed maintenance's clear
and the ordinary input/action decision. A new placement flag can therefore
reach later movement/concrete tails and character auxiliaries without another
countdown clear in between. Actual movement and its ordinary animation/tail
require `node_flags & 2` and `update_pause.current < 1`; the wrapper's
awakening dispatch precedes its pause check, and auxiliary work has separate
gates. Setting the flag alone does not guarantee every listed consumer runs.

Fighter phase 1 and phase 3 require bit `0x004` of the same mask cached by
`battle_dispatch_phases`; phase 2 independently uses its second cached mask.
An active start menu forces the first/third mask to zero. A mask change inside
the fighter tail does not change the cached third-pass admission. Full mask
construction and exceptions belong to
[Pause and replay](../session/pause_and_replay.md#selective-update-gating),
and the surrounding owner order to
[Battle lifecycle](../session/battle_lifecycle.md#per-update-dispatch).
**Inference:** a publication after maintenance has an opportunity for later
consumers, but contact/body publication, per-consumer admission, later owner
work and the next eligible maintenance clear remain separate boundaries.

Major/substate changes reset the primary timeline, then
`fighter_set_phase` selects phase zero and resets the secondary timeline.
`phase_event_completion` advances from the current phase condition and reports
completion on the next row's animation-slot sentinel -1. Jump impulse variants
`0x18..0x1D` and landing `0x26` have one animation-end condition followed
by the sentinel; running `0x0E` and ordinary fall `0x1E` have held condition
zero. Completion therefore depends on animation/contact, not one universal
elapsed-frame count.

`timeline_event_crossed` queries a crossing without consuming or clearing it;
fractional/rate behavior belongs to
[Timer primitives](../../runtime/timer_primitives.md#event-and-interval-predicates).
State entry, pause, animation completion, contact, and multiplier reset remain
separate when interpreting elapsed motion updates.

## Confidence and evidence limits

Static confidence is high for the shared state and field contracts, complete
ordinary descriptor interval and record ranges, jump arithmetic, placement,
surface transitions, movement/contact/gravity ordering, limits, marker scheduling
and final-ground ordering, and the selected mode producer/cleanup contracts.

The character-record survey covers all 94 table rows and 78 parameter blocks.
Open scope includes the complete character-callback and stage-boundary caller
sets, wider/computed marker and selector writes, a mode-4 producer, combined-mode
reachability, saved-speed restoration beyond the selected paths, polygon names,
and geometry-dependent landing times.

Routine comments hold code-level detail.
This document describes unmodified retail NA2 (`SLPS-25837`). Static evidence
establishes dispatch and arithmetic, not observed animation presentation or
elapsed wall-clock timing.

Field conclusions use verified raw accesses and saved widths. A decompiler
field expression alone does not establish a layout or a field's meaning.

Retail RUN/JMP/FAL/LND identities and input/contact transitions support the
ordinary locomotion terms used here. No additional animation presentation,
selectively passable surface name, or untraced character-specific movement mode
is inferred.

`fighter_convert_direction_selector` has verified selector branches and
integer results in its annotation, but their wider direction-conversion meaning
is not established. Movement conclusions use the callers' actual stored indices.
Missing direct references do not exclude computed callers or overrides.

Related owners: [Hit response](../combat/hit_response.md),
[X-dash](../combat/xdash.md), [Collision](../combat/collision.md),
[Stage surface attributes](stage_surface_attributes.md), [Stages](stages.md),
[Battle entities](../session/battle_entities.md),
[Awakening](../characters/awakening.md),
[Combat action execution](../combat/combat_action_execution.md),
[Character action callbacks](../characters/character_action_callbacks.md),
[Projectiles](../projectiles_and_items/projectiles.md),
[Section transfers](section_transfers.md), and
[Battle lifecycle](../session/battle_lifecycle.md).
