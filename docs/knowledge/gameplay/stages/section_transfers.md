# Section transfers

This document records fighter stage-section transfers in unmodified retail
NA2 (`SLPS-25837`).

## Research coverage

Established: request returns, destination retention, motion and descriptor
ordering, interruption/cleanup, presentation and interaction gates, paired
placement, and selected character/resource values. Open: observed presentation,
audible samples, complete stage geometry and derived-callback coverage,
indirect/tail callers, and exact visual durations. Names come from
`@annotations/NA2`; its routine comments hold the code-level detail.

## Evidence and address conventions

All addresses are live, following
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
Static branches establish field operations and dispatch, not observed effects
or wall-clock timing. Numeric states retain their numeric identities.

Fighter field names follow the saved declaration in `@annotations/NA2/types.h`
and verified raw-offset accesses. Current decompiler field expressions can
disagree with that layout after pointer arrays; the affected transfer accesses
were checked against disassembly and the current declaration.

Geometry queries belong to [Collision](../combat/collision.md), authored stage
data to [Stages](stages.md), ordinary movement to
[Movement and physics](movement_and_physics.md), and input infrastructure to
[Action commands](../combat/action_commands.md). This document owns their
section-transfer consumers. The bounded direct-call and immediate-store
censuses are recorded in the owning routine annotations; they do not exclude
computed calls, tail jumps, wider stores or rebased aliases.

## Request admission and retained destination

`section_transfer_request` (`0x0022E760`) has three distinct results:

| Result | Contract |
| ---: | --- |
| `0` | Fighter admission fails: grounded `contact_flags & 0x80`, zero `section_transfer_delta`, zero `exchange_roles`, and `reaction_variant & 3 <= 1` are required. Allowed states are neutral `(0,0)`, running `(1,0x0E..0x11)`, jump preparation `(2,0x17)`, and major `4` with any substate. |
| `-1` | Admission passes but the field is missing, restriction mask `2` is active, or destination resolution fails. A failed resolution clears the requested delta. |
| `1` | Store the signed delta, resolve `section + delta` from physical `position` into `section_transfer_destination`, and snapshot `position` into `section_transfer_origin`. |

The helper retains a destination without entering an action.
`field_has_restriction` (`0x00708BC0`) reports whether the shared mask
intersects its argument when a background exists, and zero otherwise.
`stage_project_position` (`0x007090D0`) rejects a target below zero or at
least `BattleField.section_count`; otherwise it copies the candidate,
optionally applies `stage_resolve_boundary` (`0x006C1E50`), returns the
resulting vector, and reports success. Its wrapper does not propagate a
separate geometry-failure result.

### Input order and selected action

`fighter_consume_logical_input` (`0x00248EC0`) first requires
`contact_flags & 1 == 0` and a zero `fighter_attached_object_update` result.
It processes ordinary jump bit `0x10000` through `jump_request` before
transfer requests. Bit `0x80000` takes priority and requests delta `+1`;
otherwise `0x100000` tries `section_transfer_down_allowed` and requests
delta `-1` only when fast descent is unavailable. These are the Up/Down
modifiers of binding 2, default Cross
([logical mask](../combat/action_commands.md#logical-mask)).

Transfer result `1` enters `(1,0x15)` for `+1` or `(1,0x16)` for
`-1` through `fighter_set_action_state`. Result `-1` calls
`jump_select_variant(fighter,0)`, whose ordinary path enters `(2,0x17)`.
Result `0` makes no corresponding action change. The dispatcher's outer
gates and the helper's grounded/action gates are independent.

## Motion stages and relocation

`fighter_dispatch_action_update` dispatches both transfer substates to
`section_transfer_motion_update` (`0x0022E950`). Its
`section_transfer_stage` and `section_transfer_calls` are independent of
descriptor `phase`. Primary-timeline event `0` resets both local values.
Counts below are handler calls.

| Local stage | Behavior |
| --- | --- |
| `0` | Keep `tracking_position` at the origin. On old count zero, initialize `section_transfer_visual_position`, save `section_transfer_saved_section`, and request entry presentation `(0,0x100,8,4)`. New count `>=4` installs visual increment `80`, stage `1`, and count zero. Planar speed is snapped to zero. |
| `1` | Keep tracking at the origin; subtract `18` from the visual increment, clamp negative values to zero, otherwise add the new increment to visual component 2. Ease yaw toward direction-table index 2 for delta `-1` or index 3 for `+1`, coefficient `0.1`; snap planar speed to zero. Relocate only when the **old** count is `>=12`. |
| `2` | Ease the three tracking components toward the retained destination at `0.2`. Old count zero requests arrival presentation `(0,0x100,8,7)`. Each call copies physical position to origin and visual position. Airborne yaw approaches `paired_target_angle` at `0.3`; grounded yaw approaches the `response_facing & 1` direction at `0.1`. |

`movement_direction_angles` (`0x005C16B0`) contains approximately
`pi/2, -pi/2, 0, -pi`; those orientation values do not assign a screen
direction.

Normal relocation applies when `section == target_section` or there is no
logical `0x1000` in the newest 12 records. `input_history_has` counts
matching samples in the fighter's 32-entry ring: one match suffices; continuous
holding is unnecessary. Binding 1, default Circle, produces this bit, and
action-chain input can reinsert it
([Action commands](../combat/action_commands.md)).

Normal relocation installs the retained destination with `300` added to
component 2 as physical and visual position; sets relocation
`state_flags & 0x40`; adds the signed delta to the section; snapshots the
new physical position; and refreshes paired geometry for both fighters through
`fighter_refresh_opponent_geometry(fighter,0)`. It synchronizes
`movement_facing`, `placement_facing`, and `response_facing` from
`facing` and snaps yaw. `fighter_set_phase` (`0x0071EEF0`) selects phase
`2`; local stage becomes `2` with count zero. An unlatched
`hit_rejection` timeline block is initialized to integer/float `-4` and
latched with flag `4`.

Different sections with any recent `0x1000` sample select the alternative:
`fighter_place_relative_preset` uses paired
`contact_width * capture_uniform_scale * 0.75`, preset `4`, mode `4`,
and correction mask `0xFF`. The result is retained as the destination before
adding paired `contact_height * capture_uniform_scale` to physical component
2; an acquired `side_contact_active` reduces that addition to `0.75`.
Facing synchronizes as above, the unlatched timeline initializes to `-6`,
and the action becomes ordinary fall `(3,0x1E)`. This path skips local stage
`2` and the normal section-plus-delta store.

**Inference:** the alternative selects the paired fighter's section and a
relative placement instead of the initially resolved destination. A
player-facing move name is not established.

### Alternative placement correction and contact handoff

`fighter_place_relative_preset` (`0x0021D0C0`) installs `target_section`
as `section` before correcting the relative candidate. Preset
`relative_position_preset4` (`0x00407DB0`) is `(0,1,0,0)`; mode
`4` uses the paired `previous_response_facing` and `previous_position`.

`fighter_relative_destination` first applies
`fighter_adjust_paired_contact`. With paired `side_contact_active`, the
matching `previous_contact_side` can place candidate component 0 at paired
previous position plus or minus `10`. The relative service reports this
specific adjustment, while still applying segment/environment correction;
its result is not a general admission result, and the candidate is installed
either way.

When that result is true and paired contact remains active, placement moves
`side_contact_active` to the transferring fighter, clears it on the paired
fighter, copies `contact_side`, sets the transferring
`side_probe_distance` to `0.1`, and writes sentinel bits `0xC6875104`
to the paired distance. The later height addition reads this acquired byte.

`stage_correct_position`'s mask `0x10` applies
`field_clamp_section_endpoints` (`0x00708AF0`). Its background leaf,
`stage_clamp_section_endpoints` (`0x006C23A0`), replaces an
out-of-interval candidate with the corresponding full endpoint vector and
returns zero; inside or exactly at an endpoint returns one. Endpoint pairs
start at `BgControl.section0_min/section0_max`, with `0x20` bytes per
section. The caller restores component 2 after endpoint correction and sets
`endpoint_corrected`. Mask `0x20` also applies floor-profile correction
([boundary data](stages.md#boundary-and-floor-profile-data),
[stage queries](../combat/collision.md#stage-query-functions)).

Placement then sets the relocation flag and physical position, projects the
selected section to itself when a field exists, copies only a successful
returned component 1 into physical position, and refreshes paired geometry
with mode `1`. The transfer handler adds height afterwards. This ordering
does not establish the separation on every authored stage.

## Descriptor phases and normal return

`action_descriptor_table` (`0x0089AEB0`) maps `0x15` to
`action_name_lin_0` (`ACT_LIN_0`) and `section_transfer_up_phases`
(`0x0089A0C0`); `0x16` maps to `action_name_lin_1` (`ACT_LIN_1`)
and `section_transfer_down_phases` (`0x0089A0F0`). Both arrays are identical:

| Phase | Animation slot | Condition | Start | Rate / `256` |
| --- | ---: | ---: | ---: | ---: |
| `0` | `0x35` | `-0x10` | `0` | `1.5` |
| `1` | `0x36` | `0` | `0` | `2` |
| `2` | `0x39` | `-0x11` | `0` | `1` |
| `3` | `0x3B` | `-0x10` | `0` | `1` |
| `4` | `-1` | `0` | `0` | `0` |

`phase_event_completion` (`0x0071F160`) advances condition `-0x10`
on `animation_result`, and `-0x11` on grounded contact; condition zero
holds. Advances reset `secondary_timeline`; selected slot `-1` reports
completion. `fighter_update_phase_and_exits` returns completed transfers
to neutral through the state setter. Explicit phase `2` selection bypasses
the held phase `1`; local stage `2` has no fixed elapsed-call completion.

## Interruption and cleanup

`section_transfer_interrupt` (`0x0022F0B0`) restores the origin and saved
section only while local stage is below `2`, sets the relocation flag, then
always runs `section_transfer_cleanup` (`0x0022F110`).

Cleanup clears the delta and presentation duration/work/amount/style fields,
restores factor and target to `1`, derives facing from yaw's sign, snaps
yaw, and activates registrations `1/2` through
`query_list_registration_at` and `query_registration_activate`.
It leaves position, section, local stage/count, presentation lock and mode
flags alone. `fighter_status_display_update` clears active mode bits when
their durations are zero.

### Direct cleanup paths

The common state setter runs `fighter_action_exit` before its same-state
early return. Transfer exit through `section_transfer_exit` therefore
cleans up on both repeated and changed states.
`fighter_prepare_action_state` has no transfer-specific entry callback;
motion event `0` owns local initialization.

Transfer interruption also precedes neutral/fall selection during
`fighter_end_exchange` when `status_flags & 1` is clear, and precedes
accepted ordinary/guarded response dispatch in all four
`hit_route_accepted` modes. Rejected/intercepted hits can return first
([Hit response](../combat/hit_response.md)).
`fighter_interrupt_transfer_and_surface` interrupts any active transfer
before independent surface-axis exit, without choosing a new action.
The response-entry branch of `fighter_ko_recovery_arm` interrupts before
forcing `(5,0x37)`.

An own-list effect `0/1` makes `fighter_attached_object_update` interrupt
and call `fighter_enter_attached_state`, entering `(0,2)` with
`state_flags & 0x80` and `status_flags & 0x10`. Its return suppresses
ordinary requests when it first sets the latter bit; an already-set bit
does not produce that return. Membership comes from
`fighter_has_effect_0_1`; effect identity belongs to
[Battle items and status effects](../projectiles_and_items/battle_items_and_status_effects.md).
With its coordinator present and `status_flags & 1` clear,
`fighter_paired_event` cleans up both fighters directly before participant
selection, without origin restoration.

## Presentation, interaction and camera consumers

### Alternative outcome byte

The alternative writes `previous_action_outcome = 1` after the state setter
installs ordinary fall and runs transfer cleanup. This is shared action
history; general lifetime belongs to
[Combat action execution](../combat/combat_action_execution.md#prior-outcome-byte-lifetime).

### Visible placement and presentation amounts

During a transfer, `entity_resource_update` chooses
`section_transfer_visual_position` for `scene_child_set_transform`,
with ordinary orientation and scale. Stage-1 visual component-2 additions
therefore do not change physical component 2.

`paired_transition_start_effect(...,8,4)` requests factor target `0`,
low mode `2`, duration `8`, and amount mode `0x20`, duration `4`.
`paired_transition_arrival_effect(...,8,7)` requests target `1`,
complementary modes `1/0x10`, and durations `8/7`. A nonzero
`paired_transition_remaining` suppresses envelope setup; effect/audio
requests still run, and each helper installs the larger supplied duration
as the countdown.

`fighter_status_display_update` advances the factor by reciprocal duration
and the signed presentation amount toward `100` on entry or `0` on
arrival, converts every amount step to an integer, clears modes at their
bounds, and decrements the lock. Divisor `7` does not establish seven updates
to zero. `fighter_status_display_setup` supplies the factor to
`CcsAnimationPlayer.opacity` subject to its separate status branch, derives
`RendererPresentationView.factor_byte`, and sends amount/style through
`projectile_context_begin`, which clamps amount to `0..100`.

`projectile_compound_submit` forwards scene opacity to object rendering.
`scene_object_submit_geometry` multiplies it by the object's inherited
factor and requires a product of at least `1/128` for ordinary geometry.
`model_draw_parameters_setup` retains that product as
`CcsModelDrawContext.alpha`. **Inference:** this is a fade-out/fade-in
factor; complete material/shader mapping and observed appearance remain open.

Node flag `2` admits these presentation updates in phase 2 through
`fighter_render_slot`, separately from phase-1 motion
([phase-2 scheduling](../session/battle_lifecycle.md#what-phase-2-guarantees)).
Handler calls, animation timelines, and presentation updates are distinct
clocks.

### Authored animation, effect and sound bindings

Descriptor slots resolve through per-character animation names. Selected
`naruto_animation_names` and `hiruko_animation_names` give:

| Descriptor slot | Naruto ID 57: name / authored frames | Hiruko ID 76: name / authored frames |
| --- | --- | --- |
| `0x35` | `ANM_pnrwnxj0` / 7 | `ANM_pschnxj0` / 11 |
| `0x36` | `ANM_pnrwjmp0` / 17 | `ANM_pschjmp0` / 17 |
| `0x37` (alternative fall) | `ANM_pnrwdow0` / 16 | `ANM_pschdow0` / 16 |
| `0x39` | `ANM_pnrwdow1` / 16 | `ANM_pschdow0` / 16 |
| `0x3B` | `ANM_pnrwlan0` / 10 | `ANM_pschlan0` / 13 |

The alternative uses `ordinary_fall_phases` (`0x0089A190`), beginning
with slot `0x37`, condition/start zero, rate `1`, instead of the normal
phase-2/phase-3 return. Provider ownership belongs to
[Character asset tables](../../game/character_assets.md#animation-name-and-0x4c-stride-tables).
Selected local `0x0700` records in retail `PL/2NRWBOD1.CCS` and
`PL/2SCHBOD1.CCS` supply the frame counts. `ccs_load` establishes their
authored frame-count field
([CCS runtime](../../game/files/ccs_runtime.md#animation-track-parsing)).
Their differing lengths coexist with fixed handler counts; playback rate,
events, grounding and scheduling prevent inferring total duration.

Both relocation branches request entry resources through
`section_transition_spawn_effects`: resource `0x11` is
`section_transfer_line_effect_row`, kind `4`,
`effect0x/ANM_e0x_line_00`; resource `9` is
`section_transfer_smoke_effect_row`, kind `1`,
`effect0x/ANM_e0x_smok_01`. Retail `CMN/EFFECT0X.CCS` authors `13`
and `41` frames respectively. `effect_resolve_common_resources` resolves
the resources into the resident `common_effect_resources` lookup.
`effect_set_identifier` and `wrapped_resource_setup` consume those pointers.
Resource `9` also sets object mask `0x2000` on `OBJ_e0xsmok01a/b`.

Entry's line effect adds `75` to physical component 2; smoke uses unshifted
physical position at rate `0x100`. Normal stage-2 arrival uses
`section_transition_spawn_arrival` to bind the line resource at physical
position and reset its player to frame zero. The alternative exits before
this arrival. Effect anchors remain independent of visual position; names do
not establish observed appearance.

Both helpers request shared SFX event `0x0F`.
`section_transfer_sfx_selector` maps it to event `0x0F`;
`section_transfer_sfx_control` holds
`0F 00 00 3C 7F 7F 00 01`. Audible sample identity remains open
([SFX banks](../session/battle_audio.md#sfx-selectors-and-loaded-sound-banks)).
Allocation uses the shared manager's indexed controller;
`indexed_effect_acquire` can recycle a full pool. No fighter-owned effect
handle is retained.

`wrapped_resource_reset` enables retirement and clears looping/completion.
The inspected transfer bindings are nonlooping.
`wrapped_resource_vtable` selects `wrapped_player_update`: kinds `1/4`
advance only with the playback gate clear and a bound resource, publishing
completion. A later eligible completed/nonlooping update requests removal
through `node_request_removal`; `indexed_effects_update` releases and
unlinks flagged elements through `indexed_effect_release`. Transfer cleanup
does not retire them. This proves playback-driven lifetime, without guaranteed
allocation, visibility or timing
([effect scheduling](../session/battle_auxiliary_services.md#resident-effect-manager-callbacks-and-ownership)).

### Interaction-registration interval

Motion event `8` deactivates registrations `1/2` through
`query_registration_deactivate`. The first stage-2 call activates them if
event `8` is not crossing on that same call; cleanup activates them too.
The DD chain and generation-safe lookup belong to
[Collision](../combat/collision.md). This interval does not prove immunity
to every attack source or query family.

The movement pass avoids grounding on polygon attribute `0x10000` while
the delta is nonzero and local stage is `2` in its downward-contact branch
([floor/contact ownership](movement_and_physics.md#floor-side-surfaces-and-limits)).
Other polygons can ground descriptor phase `2`.

### Camera positions

`fighter_get_tracking_position` returns `tracking_position` while a
transfer is active. The main camera independently chooses physical position
or origin; delta and destination also select smoothing coefficients
([tracking](../session/battle_camera.md#tracking-target),
[smoothing](../session/battle_camera.md#smoothing)). Auxiliary easing alone
does not establish the camera's followed position.

## Representative character-dependent placement

The shared `4`/old-count-`12` boundaries, visual constants `80/18`,
normal height `300` and phase arrays are fixed. Alternative placement varies
with the **paired** fighter's copied contact dimensions and scale
([movement parameters](movement_and_physics.md#character-movement-parameters)).
Selected `AwakeningCharacterRecord.contact_height/contact_width` values:

| Paired ID / record | Height | Width | Offset at uniform scale 1 | Added height without / with contact |
| --- | ---: | ---: | ---: | ---: |
| Naruto `57`, `naruto_character_record` | `150` | `110` | `82.5` | `150 / 112.5` |
| Sakura `58`, `sakura_character_record` | `150` | `110` | `82.5` | `150 / 112.5` |
| Nine-Tailed Fourth Awakened State `73`, `nine_tails_fourth_character_record` | `145` | `130` | `97.5` | `145 / 108.75` |
| Sasori (Hiruko) `76`, `hiruko_character_record` | `170` | `160` | `120` | `170 / 127.5` |

These are inputs before environment correction, not guaranteed separations.
Character labels follow [Character identity](../characters/character_ids.md).
ID `47`'s sampled `naruto_nine_tails_present_auxiliary`, selected by
`fighter_id_047_vtable` slot `0x28`, uses transfer visual position and
copies the factor to its additional model subject to its status gate.
Other derived callbacks were not exhaustively inspected.

### Chiyo's additional scenes use a different position source

`fighter_id_062_construct` installs `fighter_id_062_vtable`, whose slot
`0x28` selects `chiyo_present_puppets` after primary scene submission.
With node flag `2`, `state_flags & 0x10` clear and
`fighter_timer_hold_gate(fighter) != 1`, it updates both
`ChiyoPuppetState.records`: copies primary playback rate, switches matching
animations through `chiyo_switch_puppet_animation`, places through
`chiyo_place_puppet`, and copies primary opacity. Additional submission
through `chiyo_submit_trails` separately requires `trail_flags & 2`.

Selected interleaved `chiyo_auxiliary_animation_names` entries and retail
`PL/2CHYBOD1.CCS` local `0x0700` records establish:

| Primary slot | First additional scene / authored frames | Second additional scene / authored frames |
| --- | --- | --- |
| `0x35` | `ANM_pfatnxj0` / 9 | `ANM_pmotnxj0` / 9 |
| `0x36` | `ANM_pfatjmp0` / 17 | `ANM_pmotjmp0` / 17 |
| `0x37`, `0x39` | `ANM_pfatdow0` / 16 | `ANM_pmotdow0` / 16 |
| `0x3B` | `ANM_pfatlan0` / 13 | `ANM_pmotlan0` / 13 |

Animation switching binds the selected lookup, retains the primary slot,
resets the additional timeline, and seeks a nonzero primary start frame when
the resource is bound. Missing lookup keeps an unfinished additional
animation; after completion it instead binds slot `0x29`. Each additional
player advances only while its own result is zero and its resource is bound,
so shared transfer counters do not give these scenes a universal duration.

All transfer slots and ordinary fall slot `0x37` fail the special
bone/offset gate (recorded slot below `0x23` and different from `0x1C`).
They therefore receive physical position, orientation and scale, while the
primary scene receives transfer visual position. Both receive the
presentation factor. This static distinction does not establish simultaneous
visibility because submission and model-factor gates are separate.
Provider/puppet ownership belongs to
[Character asset tables](../../game/character_assets.md#auxiliary-model-animation-providers)
and [Puppet control](../characters/puppet_control.md).

## Confidence and remaining leads

Request returns/order, transfer stages and comparisons, normal/alternative
relocation, phase arrays, interruption and presentation/control lifetime have
high static confidence. Contact handoff, outcome ordering and selected
resource/retirement paths are established from complete inspected bodies.

The four dimension records, Naruto/Hiruko primary resources, Chiyo scenes and
two common effects are bounded samples. Remaining character callbacks, audible
sample resolution and the complete authored stage-line set remain open;
direct-call/store censuses do not establish the absence of other entry or
write paths. None of these bounds changes the established transfer contract.
