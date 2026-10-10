# Effect-generator commands

Retail NA2 (`SLPS-25837`) executes authored effect-generator action packets
through runners that control emission and publish scene anchors. This document
owns their ordering, count contracts, and reset/removal lifetime.

## Research coverage

Established: construction before command execution, byte gates and cursor
saturation, scene-anchor history, the two recovered resident count contracts,
and the distinction between rewind, immediate removal and deferred release.
Open: the preserved entry word, authored command/anchor distributions, every
outer scheduler, streamed-count consequences, and older generators after restart.
Names come from `@annotations/NA2`; code evidence is static and addresses are live.

Evidence is the retail resident `SLPS_258.37`, with bounded direct-call searches
of `BTL.BIN` and `ETC.BIN`. Incomplete analyzed function definitions, xrefs and
argument recovery limit whole-program conclusions; direct-call negatives do
not exclude indirect paths or other encodings. No live instance state has been
observed. The routine comments retain the code detail and search bounds; see
[address conventions](../game/files/file_identities.md#address-conventions).

Related owners: [CCS object types](../game/files/ccs_object_types.md) owns the
`0x0D80`/`0x0D90` parser/type evidence; [CCS runtime](../game/files/ccs_runtime.md)
owns container lists and stream playback; [Particle runtime](rendering/particle_runtime.md)
owns emitter simulation and particle survival; [Model runtime](rendering/model_runtime.md)
owns skeleton matrices; [Composition attachment dynamics](rendering/composition_attachment_dynamics.md)
owns the separate `0x2300` composition-child chains. Broader timing belongs to
[Scene playback owners](scene_playback_owners.md) and [Timer primitives](timer_primitives.md).

## Generator-action runners

`ccs_instantiate_generator_actions` (`0x001ABBE0`) constructs one
`CcsActionRunner` per `CcsGeneratorPacket` and links them in
`CcsGeneratorActionManager.runners`. The manager's `owner` selects the generator
owner; null selects the resident `default_particle_manager`.

The runner keeps its source `packet`, its `count`, and one
`CcsGeneratorAction` state per packet entry. Fields are named by their consumers:

| `CcsGeneratorPacketEntry` field | Role |
| --- | --- |
| `generator_record` | Source for materialization. |
| `attachment_record` | Optional primary scene anchor. |
| `auxiliary_record` | Optional secondary scene anchor. |
| `opaque_word` | Preserved dword with no established meaning; not consumed by the inspected construction, update, anchor, reset or release family. |
| `command_byte_count` | Unsigned command-byte count. |
| `commands` | Command start, copied to the action's `cursor`. |

The state retains `primary_anchor`, `secondary_anchor`, `emitter` and
`identifier`. `ccs_generator_action_initialize` (`0x001AB260`) starts with no
emitter and identifier `-1`. `ccs_materialize_generator_action`
(`0x001AACF0`) creates only while that identifier is `-1` and
`generator_record.runtime` is nonnull. It saves the returned identifier,
resolves the emitter, copies the seven numeric descriptor floats, and disables
emission. The fields and setters are recorded in the annotations; their emitter
meanings belong to Particle runtime.

Allocation therefore occurs during runner construction, before an enable
command. Enable/disable bytes control emission; they do not allocate or remove
generators. Anchor resolution uses the referenced
`CcsRecord.transient_play_entry` and its `CcsPlayEntry.value`. The action retains
the resolved scene pointer after binding clears those temporary lookup rows.

### Commands and iteration ordering

`ccs_action_runner_update` (`0x001AB280`) visits each entry in this order:

1. Read the unsigned byte at `cursor`. Byte `1` enables the emitter; byte `2`
   disables it; every other value leaves the gate unchanged.
2. Increment `cursor` only while it is below
   `commands + command_byte_count - 1`.
3. If `emitter` is nonnull, refresh each available anchor and publish its data.

The final byte is reread on every subsequent iteration. There is no wrap or
automatic runner removal. `particle_emitter_set_enabled` (`0x0034C400`) writes
`ParticleEmitter.emission_enabled`; enabling also clears `emission_stopped`.
An ending byte `1` therefore repeatedly clears the stopped state; an ending
byte `2` repeatedly disables emission.

`ccs_update_generator_actions` (`0x001ABC70`) repeats the entire runner list
exactly `count` times. Zero does nothing. After each traversal it calls
`particle_manager_update` only when the action manager has a nonnull `owner`;
the resident default owner is scheduled separately. Gate changes precede
anchor publication, and both precede the private owner's particle update.

The command consumer dereferences the cursor without a zero command-count
check and calls the gate setter for bytes `1`/`2` without first checking the
emitter pointer. Valid command storage and successful materialization are
preconditions for those branches; this does not establish a retail failure.

### Scene and bone anchors

`generator_action_refresh_anchor` refreshes `CcsScenePlayTarget.world_matrix`:
a root copies `local_matrix` and clears `matrix_dirty`; a child uses
`resource_transform_update`. The primary anchor supplies the world translation
through `generator_action_anchor_position` and the world basis through
`matrix_copy_4x4` and `generator_action_set_basis`. The copied basis has its
translation XYZ cleared before publication.

`particle_emitter_set_primary_origin` (`0x0034CA20`) stores a four-component
`primary_origin` and sets `primary_origin_changed`. On this command path its
history-control argument is zero, so `previous_primary_origin` receives the
old current position. First use selects the new position when both stored
vectors have zero XYZ length. `particle_emitter_set_secondary_origin`
(`0x0034CAF0`) always saves the old `secondary_origin` in
`previous_secondary_origin` before publishing the new position.

An anchor may be a scene child representing a bone. The command consumer
reads a scene-object pointer and performs no numeric bone-index lookup.
Object construction and hierarchy evaluation belong to Model runtime.

### Scheduling and owner gates

Two recovered resident callers supply different count units:

| Owner | Count and gates |
| --- | --- |
| `animation_advance_position` (`0x001BB210`) | Uses `CcsAnimationPlayer.completion_stream` as the action manager. After `ccs_apply_packed_frame_command`, passes `(new_cursor >> 8) - (old_cursor >> 8)` from the unsigned 8.8 cursor. `completion_flags & 0x04` suppresses actions; the blend-only early return also skips them. End clamping restricts the count to frames reached. |
| `ccs_play_loop` (`0x001A0120`) | Uses `CcsPlayContext.action_manager`. After `ccs_step_streamed_blocks`, passes the nonzero signed `CcsContainer.rate` directly, with no fixed-point shift. |

The manager consumes an unsigned integer iteration count without conversion.
A streamed rate of `0x100` therefore requests 256 iterations; an animation
advance of `0x100` normally crosses one scene-frame boundary and requests one.
A negative streamed rate becomes a large unsigned count after sign extension.
These are static contracts; the authored packets using the streamed path and
its visible consequences are not established. The recovered callers are a
bounded resident view, not proof that no other caller exists.

Animation streamed event blocks are dispatched after the action update. On an
animation loop, `ccs_reset_generator_actions` (`0x001ABD10`) disables emitters
and rewinds each cursor through `ccs_action_runner_reset`, retaining the
generators. The backward branch of `animation_player_seek` does the same
before advancing from time zero. These operations establish no wall-clock
frequency; blend and seek exceptions belong to
[Animation runtime](animation_runtime.md).

### Removal and reset lifetime

`animation_attach` (`0x001B99B0`) publishes temporary source-record lookup rows
while it builds scene objects and resolves anchors. Its action branch is
suppressed by `completion_flags & 0x04`. Otherwise it defers release of old
runners, obtains the new animation's generator-packet list, creates a manager
when needed, replaces the generator owner unless `completion_flags & 0x08`,
and instantiates new runners. It clears the temporary rows before returning;
the new actions keep their resolved scene pointers.

| Operation | Lifetime contract |
| --- | --- |
| `ccs_reset_generator_actions` / `ccs_action_runner_reset` | Disable and rewind; retain emitter pointers and identifiers. |
| `generator_actions_release_runners` / `ccs_action_runner_remove_emitters` / `ccs_generator_action_remove` | For each live identifier, immediately unlink and destroy the emitter through `particle_manager_remove_emitter` and `particle_emitter_destroy`; clear the action pointer/identifier, destroy entry storage and runners, and clear the manager list. |
| `ccs_generator_actions_defer_release` / `ccs_action_runner_defer_emitters` / `ccs_generator_action_defer` | Request owner state `2`, clear action pointers/identifiers, destroy entry storage and runners, and clear the manager list. The emitter stays on the owner list with `state=2`, `emission_stopped=1`, `repeat_enabled=0` and `fade_state=3`. |
| `ccs_generator_actions_destroy` (`0x001AB740`) | First defer-release runners. Destroy its private owner, or transfer that owner to the receiver from `particle_detached_manager_list` when `transfer_owner` is set and a receiver exists. Free the manager only for a positive destructor argument. |

`animation_player_release_actions` is the explicit immediate-release scene
wrapper; normal animation binding replacement uses deferred release.
`ccs_destroy_play_state` destroys `CcsPlayContext.action_manager` through
`ccs_generator_actions_destroy`.

`ccs_play_restart` instantiates new runners from `CcsContainer.generator_packets`
without a preceding runner-release call in its inspected body.
`ccs_instantiate_generator_actions` starts replacing `manager.runners`.
Stream restart therefore differs from animation cursor rewind. The complete
remaining owner lifetime of any older generator is not established.

## Remaining boundaries

- `CcsGeneratorPacketEntry.opaque_word` retains no established command meaning.
- The command cases are bounded, but the complete authored CCS corpus has not
  been counted for command values, packet lengths or anchor combinations.
- Not every outer scheduler is established. No seconds, displayed-frame
  frequency or universal pause contract is assigned here.
- Particle survival after deferred release and internal use of anchor history
  belong to Particle runtime; skeleton matrix evaluation belongs to Model runtime.
