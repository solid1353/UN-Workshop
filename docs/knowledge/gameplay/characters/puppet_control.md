# Puppet and auxiliary-character control

## Research coverage

Established: primary ownership, playback synchronization, attack origins, update order and root-motion coupling for Classic Kankuro, Kankuro, Chiyo and Sasori, plus trail definitions, attachment precedence, fixed pools, expiry and curve equations.
Open: complete action-specific deformation, every generated descendant and visible configuration, Chiyo's nonzero decay-source writer, missing-attachment reachability, degenerate normalization, original action names and elapsed-time retention.

Routines, structures and data use names from `@annotations/NA2`; comments hold per-routine detail.

## Evidence conventions

Evidence is static inspection of retail NA2 (`SLPS-25837`), principally
resident `SLPS_258.37`, with the identified `BTL.BIN` helpers. Addresses are
live. Names describe established roles, not recovered source names.

Related owners: [Battle entities](../session/battle_entities.md),
[character assets](../../game/character_assets.md#auxiliary-model-animation-providers),
[collision](../combat/collision.md),
[combat action execution](../combat/combat_action_execution.md),
[model runtime](../../runtime/rendering/model_runtime.md),
[animation runtime](../../runtime/animation_runtime.md),
[scene playback owners](../../runtime/scene_playback_owners.md#fighter-animation-ownership),
[generator child ownership](../../runtime/scene_playback_owners.md#generator-child-ownership)
and [retail file identities](../../game/files/file_identities.md).

The typed views `PuppetRecord`, `FighterId018Lifecycle`,
`KankuroPuppetState`, `ChiyoPuppetState` and `SasoriPuppetState` name the
confirmed character-local state. Shared primary fields use `Fighter`;
playback fields use `CcsAnimationPlayer`. Unknown layouts retain raw offsets.

An auxiliary scene is not automatically an independently registered battle
actor. These control, allocation and attack paths establish primary coupling;
they do not establish separate controller input, independent fighter
registration or an independently damageable puppet. This is a bounded
conclusion, not a whole-program proof of absence. Large deformation routines
were inspected for control and ownership without decoding every authored
constant or matrix operation.

## Chiyo's two subordinate records

Chiyo owns two `PuppetRecord` instances and their embedded animation lookup
arrays. Each record has a playback, its bound scene and an additional
attachment scene. The playback borrows the primary fighter's body container;
the character owns the allocated objects. Construction and setup are
`fighter_id_062_construct` (`0x002A8E40`) and `chiyo_setup_puppets`
(`0x002A9150`).

| Record field | Relationship |
| --- | --- |
| `result` | Zero on an accepted switch; stores playback completion while zero; a later nonzero visit becomes 2. |
| `animation_index` | Primary `animation_slot` saved at switching; also chooses positioning and presentation. |
| `synchronized_index` | Last published primary index; a mismatch requests switching. |
| `timeline` | Local attack clock, reset on switching and advanced or event-suppressed by the attack bridge. |
| `attachment_scene`, `scene`, `playback` | Owned objects; the playback binds to `scene`. |
| `animations` | Borrowed pointer into the character's embedded lookup array. |

`chiyo_switch_puppet_animation` (`0x002AD430`) rejects a missing requested
animation while `result` is zero; otherwise a missing lookup uses slot
`0x29`. Slot `0x29` is also rejected while the result is zero and the
saved synchronized index exceeds `0x55`. An accepted switch saves the primary
index, clears the result, binds that record's animation, optionally seeks to
the primary start frame and zeroes the local timeline.

Publication only updates a record's synchronized index when its saved
animation index agrees with the primary. Ordinary update
(`chiyo_update_puppets`, `0x002AD910`) requires primary activity
(`node_flags & 2`) and a clear timer-hold gate. Each record switches on a
mismatch, follows primary playback speed and opacity, advances and updates
placement. The later presentation wrapper additionally requires
`state_flags & 0x10` clear before this work. Shared scheduling prevents
assuming that reaching both wrappers advances twice.

## Chiyo positioning and attack origin selection

`chiyo_place_puppet` (`0x002AD570`) uses an offset placement for saved
animation indices below `0x23`, except `0x1C`. It starts at the primary
position, adds a record-dependent Y offset and, for indices `0..3`, an X
offset. Primary `response_facing` selects the signs. Rotation and scale come
from the primary. The named `OBJ_2kgt00t0 spine1` attachment
(`chiyo_spine_attachment_name`) supplies the extra scene's matrix; the scene
is marked changed. Other indices use the primary transform directly.
Movement separately resolves `OBJ_2kgt00t0 trall`
(`chiyo_trall_attachment_name`).

`chiyo_select_attack_puppet` (`0x002A98E0`) uses
`fighter_current_action_index`. The shipped `chiyo_action_definition`
contains 44 actions. `chiyo_attack_puppet_map` supplies the following
selection inside that range; the lookup itself has no upper-bound check, so
no behavior is assigned here beyond the authored range.

| Selected record | Normalized selectors |
| --- | --- |
| 0 | `4/5/6`, `0x15`, `0x17..0x1A`, `0x1E`, `0x20/0x21`, `0x24/0x25`, `0x27`, `0x2A` |
| 1 | `0`, `0x16`, `0x1B`, `0x1D`, `0x1F`, `0x22/0x23`, `0x26`, `0x28/0x29`, `0x2B` |
| Null | Other values below `0x15` |
| Phase-dependent | `0x1C`, as below |

For `0x1C`, record 0 is the default. The count is
`secondary_timeline.current`; these signed comparisons select record 1.

| Primary phase | Condition selecting record 1 |
| ---: | --- |
| 0 | Count >= 10 |
| 1 | Count < 5 |
| 2 | Always |
| 3 | Count >= 11 |
| 4 | Count < 4 or count >= 10 |
| 5, 6 | Count >= 10 |
| 7 | Count < 5 |

Other phases, including negative phases, return record 0. Selection is
action-relative spatial routing, not input-device assignment.

`chiyo_route_puppet_attacks` (`0x002A9AA0`) redirects the two authored
attack banks only when all these gates hold:

- Primary major state is 8.
- The current action word has bit 1 set.
- The timer-hold gate is clear.
- `exchange_roles & 0xFF00` is zero.
- Selection returns a record.

Each bank also requires `fighter_attack_bank_registered` to return zero.
The selected record supplies playback, result and timeline to
`fighter_register_attack_window`; the primary action remains the source.
Afterwards both local clocks advance from their own playback speeds, or their
event flags are cleared under the hold gate. During a hold,
`state_flags & 0x40` can also reset the linked visual samples.

## Chiyo-owned teardown

`chiyo_release_puppets` (`0x002A96A0`) destroys each record's playback,
bound scene and attachment scene in that order, nulling the owning fields,
then destroys and nulls the linked helper. The deleting destructor
`fighter_id_062_destroy` releases these resources before destroying the two
embedded records and the common fighter. The helper borrows both playbacks;
its lifetime is described under [Linked presentation helpers](#linked-presentation-helpers).

## Kankuro's two-record variant

Kankuro `0x3C` likewise owns two `PuppetRecord` instances, each with a
bound scene/playback pair and its own embedded lookup array; it lacks Chiyo's
additional attachment scene. `fighter_id_060_construct` (`0x0029E9E0`)
and `kankuro_setup_puppets` (`0x0029ED70`) establish that ownership.

`kankuro_sync_puppet_animations` (`0x002A2D00`) follows the primary
animation index. A mismatch clears the result and selects the requested
animation, falling back to slot `0x29`. If both are missing, result 3 skips
placement and playback work. While zero, the result stores the advance result;
other non-3 results become 2. Placement, speed and opacity follow the primary.
Publication saves the primary index into both synchronized indices.

Ordinary and later presentation wrappers use the same primary activity and
timer-hold gates as Chiyo, with the later wrapper's separate already-updated
flag. The root-motion consumer retains the existing annotation name
`kankuro_channel3` (`0x0029FEB0`); it is distinct from the default
channel-3 callback.

`kankuro_route_puppet_attacks` (`0x0029F3F0`) uses the shared authored
attack gates. Selectors `0x1F..0x22` use record 1; every other selector uses
record 0. Both banks receive that record's playback, result and local clock.
Both clocks advance independently at their own playback speed, or have their
event flags cleared under the primary hold gate.

The primary owns two linked helpers, one per playback, each with two nodes.
`kankuro_release_puppets` (`0x0029F1A0`) destroys and nulls both
playback/scene pairs, then the helpers. `fighter_id_060_destroy` then
destroys the embedded records and common primary fighter.

## Classic Kankuro ID `0x12`: one playback with an authored rate

`FighterId018Lifecycle` names Classic Kankuro's one result, animation and
synchronized indices, local timeline, scene, playback and linked helper.
The lookup pointer addresses an embedded array. Setup binds the scene/playback
pair to the primary body container and selects slot `0x29`; the constructor
then creates a helper with five nodes. Ownership is established by
`fighter_id_018_construct` (`0x00265B10`) and
`fighter_id_018_bind_resources` (`0x00265D70`).

`classic_kankuro_sync_puppet_animation` (`0x0026A2B0`) follows the primary
animation index, clears its halfword result on switching, binds a nonnull
lookup and resets the timeline. Its rate differs from Kankuro `0x3C`:

```text
base = primary.update_rate                 when major_state == 8
base = signed(primary_playback.step)/256    otherwise
authored = signed(name_table[index].rate)/256
puppet.step = trunc(base * authored * 256)
```

`PuppetAnimationNameRate.rate` names the signed authored table field.
A zero result advances playback and stores the return; a later nonzero result
becomes 2. Position, rotation, scale and opacity follow the primary.
The ordinary and later wrappers use the shared activity/hold gates; the latter
also checks the already-updated flag before playback/movement work.

`fighter_id_018_attack_timer_pass` (`0x002662A0`) supplies this one
playback, result and timeline to both banks. Its local clock reads the stored
speed as **unsigned** `step/256`, despite the signed inputs to the rate
calculation. `fighter_id_018_release_resources` (`0x00266220`) destroys
and nulls playback, scene and helper; `fighter_id_018_destroy` calls it
before common primary destruction.

## Sasori ID `0x3F`: one local timer, two playback choices

The primary ID/name comes from [character identity](character_ids.md);
its auxiliary animation resources use `kkg` names
([character assets](../../game/character_assets.md#auxiliary-model-animation-providers)).
It is distinct from separately constructed playable IDs `0x4B/0x4C`.

`SasoriPuppetState` has one bound scene, first playback, a separate second
playback, one trail helper and one local attack timeline. The first animation
lookup is embedded; the second has seven slots, a remembered selector and a
transform snapshot. `fighter_id_063_construct` (`0x002AEA00`) and
`sasori_setup_puppets` (`0x002AEC80`) establish this ownership. Setup
initializes the second playback's state to 2.

`sasori_sync_puppet_animations` (`0x002B1C90`) switches the first playback
when the primary index changes, resets the local clock and selects the second
animation. Selector `0x19`, phase 2 preserves the first animation while
still selecting the second. Both speeds follow the primary playback, except
selector `0x20` uses primary `secondary_rate`. The first playback's
result, transform and opacity follow the primary.

`sasori_select_second_animation` (`0x002B1F50`) maps selectors as follows:

| Selector | Second-animation slot |
| --- | ---: |
| `0x1C` | 0 |
| `0x1D` | 1 |
| `0x20` | 2 |
| `0x1B` | 3 |
| `0x1E` | 4 |
| `0x19`, `0x22` | 5 |
| 0 | 6 |

Only phase 0 starts a nonnull selected animation; this stores state 2 and the
normalized selector. For other selectors the separate global owner-state
predicate can return state to 2.

`sasori_set_second_playback_state` (`0x002B20B0`) also sets the transform
and snapshot on entering state 0. Selector `0x20` starts at a
facing-dependent 100-unit X offset. Selectors `0x1C/0x1D` can use the
linked fighter's position or a facing-dependent 200-unit offset. They call
`field_floor_profile` (live BTL `0x00708CE0`); result sentinel
`-32768.0` restores placement to the primary. The broader geometry contract
belongs to the shared owner.

`sasori_update_second_playback` (`0x002B22A0`) advances only while state
is zero, stores the result and sets opacity to 1. Selectors `0x19/0x22`
also update placement. Selector `0x22` scales opacity from the remaining
animation frames when fewer than five remain. An already nonzero state
becomes 2. Ordinary/presentation wrappers combine first-playback
synchronization, root motion, the named attachment-position consumer and this
second-playback update.

`sasori_route_puppet_attacks` (`0x002AF360`) chooses the first playback
when second state is 2 or selector is `0x19/0x22`; otherwise it chooses the
second. Both choices use the **same first result and local timeline**.
The timeline's increment always reads the first playback speed. Changing the
visual origin therefore creates no second local attack clock.

`sasori_release_puppets` (`0x002AF1E0`) destroys and nulls first playback,
scene, helper and second playback in that order. The deleting destructor is
`fighter_id_063_destroy`.

### Sasori's activation comes from primary action callbacks

Default `sasori_channel3` (`0x002B2C30`) derives the selector, phase and
events from the primary, and enables state zero at these events:

| Selector | Primary event activating the second playback |
| --- | --- |
| `0`, `0x1E` | Primary timeline event 1 |
| `0x1C`, `0x1D`, `0x20` | Phase 0, primary timeline event 1 |
| `0x1B` | Primary timeline event 11 |
| `0x19` | Phase 0, secondary timeline event 8 |
| `0x22` | Phase 0, secondary timeline event 4 |

The owned-state calls require primary ID `0x3F`. The same callback can
create registered battle particle generators through
`sasori_create_puppet_generator`, using a snapshot or second-playback bone.
Those generators have a separate manager-owned lifecycle
([particle runtime](../../runtime/rendering/particle_runtime.md#battle-particle-generator-extension)).

### Sasori's generated presentation descendant

`sasori_create_puppet_generator` (`0x002B26F0`) accepts only primary
ID `0x3F`. Mode zero copies `snapshot`; nonzero mode resolves
`OBJ_gpos_stt` (`sasori_generator_attachment_name`) in the second playback
and returns without creation if absent. It has no root-position substitute.
It copies the attachment translation before creation; the caller retains no
attachment pointer in the generator.

Default channel 3 supplies mode zero for selector `0x21` while
`primary_timeline.current < 19`. Its snapshot is primary position plus
`(60,0,150)`, with X reversed when `response_facing == 1`. It supplies
mode one for `0x1B/0x1E/0x20` while second state is zero, for `0x1D`
throughout the inspected callback branch, and for `0x1C` in phase 1 or
in phase 0 while second state is zero. These are callback predicates,
not recovered action names or observed emission frequencies.

Every successful call uses `sasori_puppet_generator_descriptor` and
`sasori_puppet_generator_force`. It chooses one of two borrowed materials
through `prng_inclusive(1)`, sets the transform and
`SasoriGeneratorState.position_enabled`, and saves the position.
`battle_generator_allocate_material_objects` creates one material-object
entry, to which `material_object_assign` applies the chosen material with
mode 2. `battle_generator_register` is called without a tracking-handle
request; the primary stores no generator pointer.

| Authored generator value | Value |
| --- | ---: |
| Emitter lifetime | 5 |
| Particle lifetime | 5 |
| Emission | 10 |
| Variation | 2 |
| Fade halfwords | `0x0400 / 0x0080` |
| Default resource-catalog index | 0 |
| Resource choices after registration | 1 |

The descriptor uses shared estimated capacity, yielding 16 under the
[pool-sizing formula](../../runtime/rendering/particle_runtime.md#pool-sizing-and-lazy-visual-resources).
Finite expiry uses `age > 5`, followed by retention until live visuals drain,
under manager update gates. Primary puppet teardown is not the demonstrated
owner of this registered generator. Registration publishes the explicitly
supplied material-object array and bypasses
`battle_generator_resolve_visual_resource`, whose catalog branch applies
when no array is supplied. Descendants' actual appearance remains unsampled;
other overlay creation calls in this callback remain unclassified.
[Scene playback owners](../../runtime/scene_playback_owners.md#generator-child-ownership)
owns construction/reuse of those resources.

### Playable Sasori variants use distinct construction paths

Playable `0x4B` uses `fighter_id_075_construct` (`0x002D2A60`),
`fighter_id_075_vtable` and three borrowed
`SasoriVariant75Materials.materials`. Its presentation callback can create
presentation objects under primary action-timer gates. This inspected path
does not construct the `0x3F` playback/timeline family.

Playable `0x4C` uses `fighter_id_076_construct` (`0x002D42D0`) and
`fighter_id_076_vtable`, two embedded records and
`sasori_variant76_setup_bone_geometry` (`0x002D46A0`). Setup walks the
17 `sasori_variant76_bone_definitions`, can allocate replacement geometry
and substitute the bone's `CcsScenePlayTarget.auxiliary`, preserving its
prior pointer in `SasoriBoneGeometryRecord.saved_geometry`.
`sasori_variant76_release_bone_geometry` (`0x002D4910`) destroys the
owned replacements and restores nonnull saved pointers. These model/bone
ownership paths do not establish that playable `0x4B/0x4C` alias the
`0x3F` controlled auxiliary playbacks.

## Primary dispatch and subordinate update order

`character_dispatch_channel` passes the original primary fighter pointer,
following the [common contract](../../game/character_assets.md#per-character-code).
The four default definitions use these callback tables:

| Primary ID | Table | Channel 2 | Channel 3 | Channel 5 |
| --- | --- | --- | --- | --- |
| `0x12` | `classic_kankuro_callback_table` | `classic_kankuro_channel2` | `classic_kankuro_channel3` | Null |
| `0x3C` | `kankuro_callback_table` | `kankuro_channel2` | `kankuro_default_channel3` | `kankuro_channel5` |
| `0x3E` | `chiyo_callback_table` | `chiyo_channel2` | `chiyo_channel3` | Null |
| `0x3F` | `sasori_callback_table` | `sasori_channel2` | `sasori_channel3` | Null |

Default channels 1/6/7 are null. This covers these definitions, not every
configured-jutsu replacement. `fighter_dispatch_action_update` invokes
channels 2 and 3 before common major-state work. These callbacks inspect the
primary action and phase clocks; they are not separately registered puppet
callbacks.

The first coordinator phase runs action/list processing, removal maintenance,
then surviving-primary auxiliary work. Each primary receives
`entity_resource_update`, its ordinary class update, then channel 5.
The generic movement/animation pass sets `state_flags & 0x10` for an
active fighter. Later phase-2 submission reaches the class presentation
wrapper, whose playback/movement work requires that bit clear. Reaching both
wrappers therefore does not prove two subordinate advances.
[Battle lifecycle](../session/battle_lifecycle.md#what-phase-2-guarantees)
owns the full session order.

The late `fighter_update_timelines_slot` processes primary attack banks
before the class puppet bridge. The bridge shares that primary bank state and
checks registration before redirecting each bank; ordering is part of the
attack-origin contract.

## Root movement remains coupled to the primary

`PuppetMotion` names the matching character-local movement layout. This
ownership is separate from the embedded animation-provider arrays.

| Primary | Motion fields | Root consumer | Reset |
| --- | --- | --- | --- |
| `0x12` | `FighterId018Lifecycle.motion` | `classic_kankuro_update_puppet_motion` | `classic_kankuro_reset_puppet_motion` |
| `0x3C` | `KankuroPuppetState.motion0/1` | `kankuro_channel3` | `kankuro_reset_puppet_motion` |
| `0x3E` | `ChiyoPuppetState.motion0/1` | `chiyo_update_puppet_motion` | `chiyo_reset_puppet_motion` |
| `0x3F` | `SasoriPuppetState.motion` | `sasori_update_puppet_motion` | `sasori_reset_puppet_motion` |

| Motion field | Established role |
| --- | --- |
| `height`, `width` | Dimensions derived from the primary's dimensions and scale. |
| `cached_position` | Cached XYZ; reset uses sentinel bits `0xC6875104`. |
| `mode` | Nonzero enables root movement. |
| `previous_x/current_x/target_x/interpolation_x` | X interpolation state and authored parameter. |
| `previous_z/current_z/target_z/interpolation_z` | Z interpolation state and authored parameter. |
| `vertical_delta`, `vertical_decay` | Vertical increment and eligible-call decrement parameter. |
| `previous_y` | Y component of the previous-position vector. |

Reset restores dimensions and the invalid cache sentinel, clears the motion
block and preceding query result. Some characters also reset a separate
deformation block; it is not another playback/timeline record.

Outbound mode 1 begins at the valid cached subordinate position, otherwise
the primary position. The destination comes from the linked fighter and a
scaled authored offset through `fighter_relative_destination`; both axes
are initialized. Mode-2 and return helpers can use primary-relative
destinations. Primary timeline events, normalized action and phase select
these transitions.

A positive primary hold gate preserves interpolation. Otherwise each enabled
axis uses `scalar_approach` with factor
`primary.update_rate / stored_interpolation_parameter`, giving
`current += (target-current)*factor` per eligible call.
`puppet_reconcile_motion` uses previous/proposed positions and dimensions
with the **primary** collision context, followed by `collision_segment_query`
with mask `0x20000001` and options `1,0,-1`.

A no-hit result (`-1.0`) clears the local query result. A hit stores the
resident published primitive attribute word `environment_published_primitive_flags`.
When no hit is returned and the hold gate is clear, vertical delta decreases
by `3*vertical_decay` and is added to Z. Otherwise Z takes the query
endpoint and vertical delta becomes zero. The subordinate receives that
position with primary rotation and scale. These local fields do not
establish a separate fighter movement dispatcher; generic query semantics
belong to [collision](../combat/collision.md).

## Linked presentation helpers

A `PuppetTrailHelper` owns a linked list of `PuppetTrailNode` objects.
Each node borrows its authored definition, primary fighter and one playback,
caches four primary attachments and owns its sample pool. Helper update ages,
inserts and smooths samples; submission draws segmented geometry; reset clears
samples and is **not** playback advance. The retained playback's opacity
modulates sample alpha.

**Inference, high confidence:** primary/puppet attachment names and the
segmented fading geometry identify this as the puppet-string/trail family.
They do not establish which configuration is visible in every action.
The inspected helper allocation/cleanup owns neither an input object nor a
primary battle slot. `puppet_trail_helper_destroy` frees its sample buffers
and nodes, then the helper; borrowed fighter/playback lifetime stays with the
character.

### Published definitions and retained attachments

Constructors publish definition arrays directly. No action index replaces
them in the inspected helper API. Appending advances by one definition.
Chiyo appends the same pair again with the other playback; Sasori keeps the
first playback even when attacks select the second. Sample reset rebinds
neither definition nor playback.

| Primary | Helper | First definition / nodes | Retained playback |
| --- | --- | --- | --- |
| Classic Kankuro | `control` | `classic_kankuro_trail_right_arm`, five entries | One puppet playback |
| Kankuro | `helpers[0]` | `kankuro_karasu_trail_leg`, two entries | Record 0 |
| Kankuro | `helpers[1]` | `kankuro_kuroari_trail_body`, two entries | Record 1 |
| Chiyo | `helper` | `chiyo_trail_left_arm`, two entries appended twice | First pair record 0, second pair record 1 |
| Sasori | `helper` | `sasori_trail_left_arm`, two entries | First playback |

Successful construction produces 15 nodes from **13 distinct definitions**.

| Definition field | Contract |
| --- | --- |
| `attachment_names[4]` | Four fixed 30-byte slots, sampled in order. |
| `lifetime` | Initial sample lifetime and reciprocal surviving fade decrement. |
| `pool_count` | Fixed sample capacity. |
| `point_count` | Spatial points, parameter `i/(N-1)`. |
| `extra_temporal_samples` | Subdivisions between retained samples once at least four are active. |
| `tension` | Shared authored value for spatial and temporal curves. |
| Raw `+0x84` | Zero in the sampled definitions; meaning unknown. |

All definitions have lifetime 4, pool count 8, point count 16 and tension
`-1.0`. Extra temporal count is 2 for
`classic_kankuro_trail_head`, `kankuro_karasu_trail_head` and
`kankuro_kuroari_trail_head`; the other ten use zero.
Each node therefore owns `8*0x310 = 0x1880` bytes: a sample header and
16 point records per slot. The embedded parameter array also holds 16 floats.
These shipped capacities do not prove arbitrary authored counts safe: the
inspected code does not clamp them.

For each sample, a cached primary attachment wins. Only a null cache invokes
a fresh retained-playback name lookup; the result is local and looked up again
later. If both fail, the producer uses the playback root-matrix translation.
There is no missing-name rejection in this producer. Reachability of that
fallback in every shipped action remains unmeasured.

The configurations preserve slot order. Primary suffixes complete
`OBJ_2cmn00t0 `; auxiliary suffixes complete the listed prefix plus a space.
“Prefix alone” is the exact name without a suffix.

| Definition | Primary suffixes P0 / P1 | Auxiliary prefix | Auxiliary suffixes P2 / P3 |
| --- | --- | --- | --- |
| `classic_kankuro_trail_right_arm` | r clavicle / r finger0 | `OBJ_2krs00t0` | l finger0 / l clavicle |
| `classic_kankuro_trail_left_arm` | l clavicle / l finger0 | `OBJ_2krs00t0` | r finger0 / r clavicle |
| `classic_kankuro_trail_left_leg` | r forearm / r finger0 | `OBJ_2krs00t0` | l calf / l foot |
| `classic_kankuro_trail_right_leg` | l forerarm / l finger0 | `OBJ_2krs00t0` | r calf / r foot |
| `classic_kankuro_trail_head` | r forearm / r hand | `OBJ_2krs00t0` | head01 / spine |
| `kankuro_karasu_trail_leg` | l forearm / l finger0 | `OBJ_2krs00t0` | l calf / l foot |
| `kankuro_karasu_trail_head` | r forearm / r hand | `OBJ_2krs00t0` | head01 / spine |
| `kankuro_kuroari_trail_body` | l forearm / l finger0 | `OBJ_2kar00t0` | Prefix alone / bone13 |
| `kankuro_kuroari_trail_head` | r forearm / r hand | `OBJ_2kar00t0` | head / bone01 |
| `chiyo_trail_left_arm` | l clavicle / l finger0 | `OBJ_2kgt00t0` | l hand / l forearm |
| `chiyo_trail_right_arm` | r clavicle / r finger0 | `OBJ_2kgt00t0` | r hand / r forearm |
| `sasori_trail_left_arm` | r clavicle / r finger0 | `OBJ_2kkg00t0` | l hand / l forearm |
| `sasori_trail_right_arm` | l clavicle / l finger0 | `OBJ_2kkg00t0` | r hand / r forearm |

The literal `l forerarm` spelling is confirmed data; it does not establish
a lookup failure.

### Pool reuse, expiry and smoothing

`PuppetTrailNode.active_count` counts linked samples;
`newest/oldest` bound the list. Samples carry remaining lifetime, fade and
newer/older links. `puppet_trail_reuse_sample` takes the first slot with
zero lifetime and increases the active count; if none is free it detaches and
reuses the oldest without increasing the count. Reuse restores fade to 1,
clears projection bits and regenerates colors. Point alpha begins at the
integer conversion of `128*i/(N-1)`, clamped to a byte. This is fixed
storage reuse, not one allocation per update.

`puppet_trail_node_update` (`0x0020FFA0`) orders the work:

1. Age previously active samples by one. Nonpositive lifetime frees/unlinks
   the slot; survivors get `fade=max(0,fade-1/L)`, with authored lifetime
   `L`, independent of playback speed and local clock increments.
2. Insert one current sample and any requested temporal samples.
3. Hold newest point XYZ as target `H_i`. Every older sample independently
   applies `P_i += (H_i-P_i)*(1-sin(pi*i/(N-1)))` and clears its projection
   cache. The newest is untouched; the target does not become the preceding
   older sample.
4. Replace alpha with the integer conversion of its **stored alpha** times
   sample fade times retained playback opacity, preserving the other color
   bytes. Repeated updates compound attenuation.

With lifetime 4, an ordinary sample survives insertion and three subsequent
eligible updates, then expires before the fourth insertion. Pool reuse and
temporal subdivision can shorten an individual slot's retention.
This is an update-call lifetime, not a measured display-frame or wall-clock
duration; drawing has separate admission.

Reset clears lifetime, links and active count and regenerates parameters and
colors. It preserves the definition, cached attachments, borrowed primary and
playback, and deformation fields.

### Spatial curve and temporal subdivision equations

Let `H00=2t^3-3t^2+1`, `H10=t^3-2t^2+t`,
`H11=t^3-t^2`, `H01=-2t^3+3t^2` and `s=(1-tension)/2`.

The spatial producer sends four sampled/modified attachments to
`spatial_curve_interpolate` (live BTL `0x00706FF0`),
with `t=i/(N-1)`. Authored tension `-1` gives `s=1`:

```text
C(t) = H00*P1 + H10*s*(P2-P0) + H11*s*(P3-P1) + H01*P2
```

W is forced to 1. Each point then adds
`sin(pi*t/2)*rng_central_band(5.0,1.0)` to Z.
[Randomness](../../runtime/randomness.md) owns the random service; these fixed
arguments do not establish an observed visible amplitude distribution or
reproducible sequence here.

`puppet_trail_insert_temporal_samples` (`0x0020F8E0`) snapshots the newest
four samples as `Q0/Q1/Q2/Q3`, inserts the authored extra count `k`
between `Q1/Q2`, and uses `t=j/(k+1)`, `j=1..k`. Positions use the
original snapshots even as insertion changes the list.
`temporal_curve_interpolate` (`0x00208360`) has a different first tangent:

```text
D(t) = H00*Q1 + H10*s*(Q1+Q2-2*Q0) + H11*s*(Q3-Q1) + H01*Q2
```

The temporal and spatial helpers therefore do not share the same tangent
formula. Inserted samples set their temporal flag and receive lifetime

```text
convert(max(1, prev_lifetime - t*(prev_lifetime-Q2_lifetime)))
```

For the first insertion `prev_lifetime` belongs to `Q1`; afterwards it
belongs to the previously inserted sample, not the original `Q1`. Fade and
colors come from pool reuse, not endpoint interpolation.

### Action-produced curve deformation

`puppet_trail_set_deformation` (`0x002108B0`) sets the envelope to 1,
resets the selected channel phase and stores amplitude/decay. Node `-1`
selects all nodes; an excessive index caps at the last node; channel clamps
to `0..3`. Inspected character wrappers set channels 0 and 1 to the same
float pair.

Let `A0/A1` be the first two attachment translations and `A2/A3` the
last two before modification. Each produced sample advances the first three
phases by `pi/16`, `pi/32`, `pi/64`, wrapped to `[-pi,pi]`; the
inspected controls use the first two. A nonzero envelope `q` first moves
`A0` toward `A1` and `A3` toward `A2` by factor `q`, then forms:

```text
U0 = normalize(A0-A1), with positive U0.z negated
U1 = normalize(A2-A3)
P0 = A1 + U0*(1+sin(phase0))*(amplitude0 != 0 ? amplitude0 : 50)
P1 = A1
P2 = A2
P3 = A2 + U1*cos(phase1)*(amplitude1 != 0 ? amplitude1 : 50)
```

Nonzero amplitudes approach zero by their own decay factor and clear below 1.
The envelope independently approaches zero with factor `0.25`, hence
`q_next=0.75*q`. Resetting samples does not alter these fields.
Zero-length normalization and visible geometry for every pose remain open.

In major 0, minor 3, `classic_kankuro_channel2` checks each node's
channel-0 amplitude below 50 and `prng_inclusive(1)==0`, then sets both
channels to amplitude `300+rng_signed_scaled(100)` and decay
`0.05+rng_signed_scaled(0.025)`.

`kankuro_channel2` uses the same predicate and pair, taking each node's
decision from the **first** helper. Accepted decisions reach corresponding
nodes in both nonnull helpers whose associated record result is not 3; the
second puppet makes no independent random decision.
[Randomness](../../runtime/randomness.md#mt-wrappers) owns the signed-scale
semantics.

Chiyo selector `0x2A`, phase 0, secondary event 3
(`chiyo_selector2a_event`) requests deterministic deformation.
The common final request applies to all four nodes, with amplitude 400 when
the current record is absent or its `ActionRecord.damage` is zero; otherwise
amplitude is `300*(current_record.damage/0.015)`. Decay is

```text
0.75 / (motion0.deformation_decay_source / primary.update_rate)
```

This publishes curve controls without replacing definitions or resetting
samples. Other branches sharing the request were not exhaustively assigned
action-specific equations.

The nonzero writer of `motion0.deformation_decay_source` (primary
`+0x5710`) remains open. Reset clears it. The inspected outbound,
mode-2/return, playback wrappers and default channel-2/3 routines do not write
it; their bounded negative findings are in their annotation comments.
Those reads establish neither the value for every request nor avoidance of a
zero denominator.

### Draw admission, update and reset remain separate

Constructors clear, and setup enables, character-local `trail_flags` bit 1.
This is the presentation outer gate:

| Primary | Flags | Helper presentation |
| --- | --- | --- |
| `0x12` | `FighterId018Lifecycle.trail_flags` | `classic_kankuro_present_puppet` |
| `0x3C` | `KankuroPuppetState.trail_flags` | `kankuro_submit_trails` |
| `0x3E` | `ChiyoPuppetState.trail_flags` | `chiyo_submit_trails` |
| `0x3F` | `SasoriPuppetState.trail_flags` | `sasori_submit_trails` |

Inside it, sample **update** additionally needs primary `node_flags & 2`
and `state_flags & 0x20`. **Submission** needs only a nonnull helper.
Kankuro `0x3C` additionally requires the associated record result not equal
to 3 for both operations. A closed update gate permits retained-sample
submission; submission does not age, insert or smooth.
Sasori's helper still uses first-playback opacity when the presentation
callback separately submits the second playback.

The later class wrapper resets samples when primary activity is enabled and
`state_flags & 0x10` is clear, independently of the timer-hold gate's
suppression of subordinate playback/movement. It then reaches presentation.
Sasori also resets before ordinary movement when `battle_owner_state_6_4`
returns 1: the global owner's numeric states are `+0x14==6` and
`+0x18==4`; no broader state name is assigned.

With `state_flags & 0x40`, `fighter_id_018_attack_timer_pass` calls
`classic_kankuro_reset_trails` (`0x0026A580`) after its timer work regardless
of the hold branch. `kankuro_route_puppet_attacks` and
`chiyo_route_puppet_attacks` call `kankuro_reset_trails` (`0x002A2F40`) and
`chiyo_reset_trails` (`0x002AD7D0`) only inside their positive-hold branches.
Each resets its nonnull trail helper through `puppet_trail_helper_reset`;
these calls neither destroy the helper nor cancel subordinate playback.
Sasori's inspected attack bridge has no corresponding reset.
Generic flag ownership and scheduling remain with
[scene playback owners](../../runtime/scene_playback_owners.md#fighter-animation-ownership)
and [battle lifecycle](../session/battle_lifecycle.md#what-phase-2-guarantees).

`puppet_trail_node_submit` (`0x002103C0`) reserves
`4*active_slots*(N-1)+6` units of `0x20` bytes.
A nonzero packet pointer admits active-list traversal, one segment per
adjacent point pair and final submission; failed reservation skips that node's
segments. Projection-cache bits are cleared before traversal. Drawing does
not change remaining sample lifetime.
[Render submission](../../runtime/rendering/render_submission.md) owns shared
packets, and [renderer coordinates](../../runtime/rendering/renderer_coordinates.md)
owns view mathematics. Node/helper teardown does not destroy their borrowed
playbacks.

## Attack results remain primary-owned

`fighter_register_attack_window` (`0x0021FC70`) receives the selected
playback and local timeline; its common contract belongs to
[combat action execution](../combat/combat_action_execution.md#character-specific-scene-and-timer-selection).

The playback supplies animation length, speed and the bank's named scene/bone
lookup; the timeline supplies the event window. The bank word, transformed
origin and collision registration are published on the **primary**, with
origin Y replaced by primary Y, and `fighter_publish_current_attack`
receives the primary's current record. A subordinate scene can supply an
origin without establishing an independently damageable Chiyo/Kankuro actor.

## Shared local clock and primary gate

`fighter_timer_hold_gate` (`0x00224650`) returns 1 exactly when signed
`Fighter.update_pause.current` is positive. These callbacks suppress normal
advance and clear local crossing-event bit 1 through `timeline_hold`,
preserving all positions and remainder. Otherwise `timeline_advance` carries
complete units out of its fractional accumulator and updates the timeline.

Each local increment is the clock-owning playback's unsigned 8.8
`step/256`. Sasori always uses the **first** playback even for attacks
originating from the second. The generic clock contract belongs to
[timer primitives](../../runtime/timer_primitives.md), and auxiliary attack
caller coverage to
[combat action execution](../combat/combat_action_execution.md#character-specific-scene-and-timer-selection).

**Inference, high confidence within the inspected callbacks:** separate
playback, pose and clocks permit action-relative motion and event timing.
Dispatch still derives from the primary normalized action, activity, hold
gate and current banks. Separate scene allocation is insufficient evidence of
an independent controller or battle-registry slot.
