# Composition attachment dynamics

## Research coverage

Established: hierarchy-derived chains, coefficients, collision volumes,
integration order, rebase, destruction and bounded caller gates.
Open: other force writers, the Z-bound writer, outer scheduling, authored
coefficient ranges and visible consequences of degenerate collision geometry.
Names come from `@annotations/NA2`; all addresses below are live.
Evidence is static retail code; no seconds or display-frame cadence is assigned.

Retail NA2 (`SLPS-25837`) turns the composition's `0x2300` attachment
resource into scene-child dynamics. The manager changes child transforms;
it does not interpret battle action-command bytes or create particle emitters.

[CCS object types](../../game/files/ccs_object_types.md) owns resource parsing
and the compact arrays; [Model runtime](model_runtime.md#composition-hierarchy-and-matrix-lifetime)
owns composition hierarchy and skeleton matrices.
[Effect-generator commands](../effect_generator_commands.md) owns generator
actions and their anchors; [Scene playback owners](../scene_playback_owners.md)
and [Timer primitives](../timer_primitives.md) own broader scheduling.
See [address conventions](../../game/files/file_identities.md#address-conventions).

## Construction and ownership

`CcsCompositionDescriptor.attachments` supplies two separately consumed arrays
in `CcsRelationData`. `projectile_simple_service_configure` materializes
`CcsCompositionInstance.children` and `child_count`, links parents and evaluates
the children through `ccs_composition_link_parents` and
`ccs_composition_bind_controllers`, then constructs the attachment manager.
`composition_attachments_construct` (`0x00189B60`) returns the manager retained
in `CcsCompositionInstance.attachments`; `ownership_flags & 0x01` identifies
owned attachment storage.

The first array (`relations_a`) selects hierarchy children and supplies
coefficients. The second (`relations_b`) supplies child-anchored collision
volumes. Resolved runtime pointers and coefficients survive the temporary
hierarchy's destruction.

## Chain coefficients and anchoring

`attachment_hierarchy_construct` follows the authored
`CcsCompositionDescriptor.parent_indexes`: -1 selects the containing root.
An `AttachmentParameters.child_index` selects the child whose parameters
override inherited parent parameters. A newly marked child without an already
marked parent starts a separate `AttachmentChain`; participating descendants
receive `AttachmentState` objects.

`attachment_hierarchy_build_chains` allocates the participating chains and
states, binds runtime scene children and first-child states, then initializes
points, rest shape and coefficients. These passes preserve the distinction
between `AttachmentState.first_child`, which supplies the authored rest
segment, and `AttachmentState.next`, which supplies the flattened traversal
and following point. They need not coincide in every branching hierarchy.

| Authored `AttachmentParameters` field | Runtime contract |
| --- | --- |
| `velocity_retention` | Applied to the first-child state's `velocity_retention` when that state exists; multiplies its velocity on each integration pass before force is added. |
| `length_correction` | Retained on the current state; scales `rest_length - current_segment_length` to correct the following point along the segment direction. |
| `shape_attraction` | Retained on the current state; when nonzero, moves the following point toward the transformed authored segment endpoint by this fraction before length correction. |

`attachment_state_initialize_points` initializes `current_point` and
`previous_point` from the evaluated scene child, retains `rest_local_matrix`,
and derives `rest_direction` and `rest_length` from the first child's local
translation. The coefficients act on these runtime points rather than numeric
bone IDs or CCS records. The temporary builder and its authored parameter nodes
are released after the chains retain their resolved values.

## Authored offsets and collision volumes

Each `AttachmentCollisionParameters` entry selects a scene child with
`child_index` and supplies `translation` and `axis_scale`.
`attachment_collision_append` retains these in an `AttachmentCollision`
linked into `AttachmentManager.collisions`.

`attachment_collision_construct` builds the local matrix from translation
and diagonal scale. `attachment_collision_refresh` combines it with the
child's evaluated world transform, or uses the local matrix alone without a
child, then computes `inverse_matrix` through `matrix_inverse`.

`attachment_state_integrate` (`0x0018AC80`) transforms a point into each
volume's local space. Squared XYZ length below one causes projection onto the
unit-radius surface and transformation back to world space, setting
`AttachmentState.collision_corrected` and `AttachmentCollision.correction_flags`
bit `0x01`. The first correcting volume ends that point's volume search.
Translation therefore supplies authored center offsets and diagonal scale
supplies axis extents for transformed unit-sphere collision volumes.

This geometry is established by the consumer independently of the CCS explorer's
`Dynamics` label. The inspected path does not guard zero center-distance or
singular scale; whether authored retail data contains them and their visible
consequences remain open.

## Attachment step, rebase, and destruction

`scene_list_node_refresh` steps only a nonnull composition attachment manager.
`attachment_manager_step` (`0x00189D10`) performs one pass per invocation:

1. Refresh every collision node, including its inverse, and clear its
   per-step correction flags.
2. Consume and clear `rebase_requested` when set, then rebase every chain.
   `attachment_chain_rebase` adds the displacement between the first scene
   child's current evaluated position and its retained previous point to
   every current and previous chain point. It preserves velocities and chains.
3. When the chain anchor exists, evaluate it and initialize the first point
   and velocity; then integrate every point: `previous = current`,
   `velocity = velocity * velocity_retention + force`, `current += velocity`,
   collision-volume projection, and finally the Z lower bound.
4. For every state with a flattened following state,
   `attachment_state_correct_segment` (`0x0018A840`) applies shape attraction
   and segment-length correction, replaces the current state's velocity with
   `current - previous`, reconstructs `scene_child.local_matrix`, and sets
   `scene_child.matrix_dirty` to one.

Terminal points are integrated but do not run the following-point transform
path. Collision projection and the Z bound precede attraction/length correction;
the correction pass does not search collision volumes again.

`attachment_force` is the four-component float force vector, and
`attachment_z_lower_bound` is the float Z lower bound.
`oscillating_composition_step` is one established force
writer; other force writers and the lower-bound writer remain open.

There is no delta-time argument or frame-count loop in the manager step.
`composition_attachments_request_rebase` sets the latch without immediately
stepping. A call to construct a composition does not establish that the owner
has nonnull attachments or schedules their integration.

`composition_attachments_release` destroys an owned manager and clears its
pointer and ownership bit. The composition destructor `handle_e6c_destroy`
also releases an owned manager before destroying children.
`attachment_manager_destroy` releases chains and their states, then collision
nodes, and frees the manager only for a positive deleting argument. Rebase,
step and destruction are separate operations; emitter ownership is absent from
this teardown.

## Bounded caller coverage

`animation_player_compose` refreshes each composition in
`CcsAnimationPlayer.composition_children`. The auxiliary fighter path
`fighter_auxiliary_composition_step` and `oscillating_composition_step`
publish the composition's local transform before stepping. The oscillating
owner's `flags & 0x01` suppresses this path and its force-vector preparation.

`animation_player_attachments_request_rebase` (`0x001BB740`) walks the
player's composition-child chain and requests rebase on each composition.
It does not step, seek animation or release the children.
`fighter_model_attachments_rebase_on_placement` (`0x00296090`) calls it on
`Fighter.owned_animation_player` only with placement bit `state_flags & 0x40`,
activity bit `node_flags & 2`, a nonnull battle manager and `menu_state != 1`.
`linked_effect4a_display_reset` also rebases its separate player on its
placement-marked path after refreshing the linked transform and opacity.
Its `fighter_id051_refresh_wing_transform` (`0x00286DA0`) refreshes the
separate playback from `OBJ_eff_dummy_wing0` when present, or uses the
primary matrix and fixed rotations under its alternate resource gates.
These paths update retained presentation rather than retire it.

The battle attachment paths `battle_attachment_composition_step` and
`battle_state_attachment_composition_step` also publish the local transform
before stepping. `Fighter.state_flags & 0x40` requests rebase first.
The former requires a nonnull `BattleAttachmentOwner.composition` and evaluates
its anchor; the latter refreshes its anchor only while `refresh_anchor` is
nonzero. The corresponding `battle_attachment_composition_rebase` and
`battle_state_attachment_composition_rebase` require a nonnull composition,
invoke `BattleAttachmentVtable.refresh_transform`, request rebase and step
immediately.

The state-dependent path (`battle_state_attachment_composition_step`,
live `0x00726ED0`) additionally marks composition children dirty and requests
rebase when all these gates hold: `Fighter.animation_slot == 0x29`,
`BattleStateAttachmentOwner.previous_animation_slot == 0x31`,
`Fighter.phase == 0`, and `timeline_event_crossed` admits secondary
timeline event 0. It then saves the current animation slot and performs the
ordinary step. The numeric animation slots are not assigned action names.

The bounded direct-call screen covers the resident executable and `BTL.BIN`;
it found no direct step call in `ETC.BIN`. It does not exclude indirect calls,
other encodings or untraced outer scheduling owners. No live instance state
was observed.
