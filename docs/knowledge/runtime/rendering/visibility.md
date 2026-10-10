# Visibility bounds and culling

## Research coverage

Established: local box ownership, construction and lifetime; ordinary eight-corner X/Y/W classification;
controller-specific off-screen inputs; background state gates; effect depth and particle distance/draw gates.
Open: entry-0 additional-point register lifetime and later writes; other bounds writers;
indirect/other-overlay visibility coverage, lower primitive clipping and exact VU boundary behavior.
Routine, field and data names come from `@annotations/NA2`; comments hold per-routine detail.
Evidence is bounded static retail NA2 (`SLPS-25837`) inspection, without execution or live-memory observations.

## Evidence conventions

This document owns geometry retention/rejection before drawing and the bounds
and renderer inputs that determine it. Related owners are
[CCS object types](../../game/files/ccs_object_types.md) for resource parsing,
[Model runtime](model_runtime.md) for geometry and skeleton evaluation,
[Renderer coordinates](renderer_coordinates.md) for matrices,
[Battle camera](../../gameplay/session/battle_camera.md) for gameplay camera decisions,
[Shadow rendering](shadow_rendering.md) and [Particle runtime](particle_runtime.md)
for those producers and passes, and [Render submission](render_submission.md)
for downstream scheduling.

Addresses are live resident `SLPS_258.37` EE addresses; see
[address conventions](../../game/files/file_identities.md#address-conventions).
Observed contracts below have high confidence within the inspected paths;
inferences and open matters are identified explicitly. The direct-call screen
also covered `BTL.BIN` and `ETC.BIN`, but imported function/xref gaps prevent
whole-program absence claims. VU plane equations abstract floating-point sign
flags rather than establish exact hardware contact behavior. Opaque return
types in annotations preserve an unestablished original return while retaining
proved used parameters.

## Box ownership and lifetime

`ccs_parse_bounds` (`0x001ADBF0`) creates a temporary `CcsBoundsDescriptor`
with `minimum`, `maximum` and their component-wise floating midpoint; all
three vectors have W = 1. The box record and its linked target are separate
records. `CcsContainer.copy_fixups` owns the temporary attachment.

`ccs_finalize_dependencies` (`0x001AD240`) resolves the linked target
through `ccs_copy_fixup_resolve_target` (`0x001AD960`). A target runtime
that is neither null nor sentinel 4 receives all three vectors through
`model_copy_bounds` (`0x001AD8F0`). Finalization clears the source
`CcsRecord.runtime`, frees the temporary attachment through
`ccs_destroy_copy_fixup_node` (`0x001A9730`), and clears the list.
Drawing therefore consumes the target's retained local bounds, not a retained
parsed BOX attachment.

`ccs_parse_model` (`0x001B0C40`) also constructs default descriptor bounds
without an explicit BOX. Its shared six-integer extrema accumulator starts
with alternating `+0x10000` and `-0x10000`.
`model_bounds_from_extrema` (`0x0019B3A0`) scales converted endpoints by
`position_scale / 4096`; its midpoint converts signed `(min + max) >> 1`
before scaling. That midpoint need not match the floating endpoint average
bit-for-bit. The three W components are 1, and the descriptor retains them as
`bounds_minimum`, `bounds_maximum` and `bounds_midpoint`.

The extrema producers are `ccs_read_model_vertex_arrays`
(`0x001B0790`), `ccs_read_model_mesh_aux` (`0x001ADD80`) and
`model_prepare_projection_geometry` (`0x0018D740`), using signed XYZ
positions. `ccs_convert_packed_model_mesh` (`0x001AFF20`) does not consume
or forward the supplied outer extrema accumulator in its inspected body.
Passing an accumulator therefore does not prove every parser updates it.
[Model runtime](model_runtime.md) owns the geometry routes and packed flag bypass.

## Ordinary model draw boundary

`ccs_scene_child_bind_models` (`0x00196B40`) creates
`CcsScenePlayTarget.model` and optional `auxiliary` instances through
`ccs_model_instance_initialize` (`0x001992A0`). The instance's `bounds`
initially points directly to descriptor `bounds_minimum`; descriptor
`runtime_flags & 0x804` clears it. This construction-time ordinary box
bypass does not establish that those flags disable every geometry clipping operation.

`scene_object_submit_geometry` (`0x00190F40`) refreshes the child transform
and inherited draw factor when `alpha_flags & 1` is set. Primary geometry
requires `(flags & 0x0C) == 0x0C` and a resulting factor at least `1/128`.
Auxiliary geometry independently requires a non-null `auxiliary` and
`flags & 0x20`.

`model_dispatch_geometry` (`0x001910E0`) rejects an empty model or
`CcsModelDrawContext.alpha < 1/128`. It composes `device_matrix` from the
current model transform and `RendererTransformState.device_projection`.
Null instance bounds sets `bounds_classification = 2`; otherwise
`model_classify_bounds` (`0x001926A0`) receives those bounds, renderer,
matrix, `visibility_zero_vector` (`0x005BED40`) and entry `0x1F`.
Classification 0 returns before model-part packet production; nonzero results
survive this whole-model gate.

The classification also selects later packet variants:
`base_selector = bounds_classification - 1`, plus 2 for model flag
`0x10000`. The meanings of rejection, larger-limit containment and retained
geometry requiring the other variant are defined below.

### Bounds lifetime across transform and morph work

The instance borrows local descriptor bounds. Ordinary drawing transforms
their corners with the current model-to-device matrix, so movement changes
the classified points without requiring a local endpoint rewrite.

In the inspected non-packed draw continuation, the whole-model decision
precedes part preparation and `morpher_blend_vertices` (`0x00197570`).
Its position branch edits draw positions and can rescale source arrays, but
does not rewrite endpoint/midpoint vectors or perform a new whole-model
classification. This draw's visibility is consequently decided before its
morph edits. This ordering does not establish that every resource or animation
callback leaves bounds unchanged.
[Model runtime](model_runtime.md#morph-control-and-geometry-ownership) owns
the geometry mutation.

## Shared VU wrapper and off-screen inputs

`model_classify_bounds` executes the selected VU0 microprogram entry with
the supplied endpoints, additional vector, matrix and renderer limits,
waits and returns its classification. The entry argument chooses microprogram
execution; it is not a CPU plane mask. The wrapper performs no CPU-side
plane comparison. The ordinary additional vector is four zero floats.

`model_part_queue_projection` (`0x0018CF70`) requires a non-null
`CcsRenderEnvironment.projection_controller`, nonzero controller `mode`,
nonzero geometry packet length and nonzero environment `projection_strength`.
Its matrix uses `ProjectionVisibilityControllerView.renderer` and the
current model transform. The additional vector uses the environment direction
and `projection_scalar`; strength is a separate admission/queue input.
It selects entry 0. Rejection skips packet production and restores the scratch
cursor; retention permits `projection_controller_append_packets`
(`0x0018B700`).

This controller renderer can differ from the ordinary view renderer.
Ordinary view visibility is therefore not the sole off-screen decision.
Entry 0's extra-point geometry remains unresolved as described below.

## VU point tests and classification

`engine_root_allocate` (`0x00105FC0`) uploads
`visibility_vu0_classifier_upload` (`0x003D11E0`) through
`dma_channel_registers` (`0x001507F8`) and `dma_submit_chain`
(`0x00150B28`). Channel 0 of `dma_channel_register_table`
(`0x003F7640`) is VIF0 DMA at `0x10008000`.

The ordinary `visibility_vu0_box_entry` (`0x003D12E8`, VU entry
`0x1F`) tests all eight XYZ endpoint combinations. Each corner is transformed
with implicit homogeneous W = 1; stored endpoint W and midpoint are unused.
`visibility_vu0_point_loop` (`0x003D1390`, VU entry `0x34`) shares
the predicate between ordinary and off-screen entries.

For each projected point P, limit X/Y are multiplied by P.w while limit W
remains the near/far depth bound. There is no separate projected-Z predicate.
For ordinary finite values away from signed-zero/underflow boundaries, viewport
retention requires an inside point for each plane independently:

| Plane | Inside sign represented by the VU subtraction |
| --- | --- |
| Left | `P.x > device_min.x * P.w` |
| Right | `P.x < device_max.x * P.w` |
| Top | `P.y > device_min.y * P.w` |
| Bottom | `P.y < device_max.y * P.w` |
| Near | `P.w > device_min.plane` |
| Far | `P.w < device_max.plane` |

**Inference, high confidence:** this is conservative corner/plane rejection.
Different corners can supply different inside planes; no one corner needs to
satisfy all six. It performs no occlusion testing. Exact contact follows VU
subtraction sign bits, so effect-path CPU equality rules cannot substitute.

| Classification | Established meaning |
| ---: | --- |
| 0 | At least one viewport plane has no inside point. |
| 1 | Every viewport plane has an inside point and every tested point lies inside every larger-limit plane. |
| 2 | Every viewport plane has an inside point, but larger-limit containment is incomplete. |

Entry 0 prepares 16 points: eight from endpoint XYZ and eight from two
additional VU vectors. The wrapper initializes only one additional vector,
and the microprogram's initial writes modify only their W lanes. The bounded
evidence establishes the point count and shared predicate, but does not
establish a self-contained endpoint-plus-direction extrusion. Additional
register lifetime and later microprogram writes remain open; no exact shadow
extent or visible defect follows from this evidence.

## Renderer limits and matrix ownership

`RendererTransformState.device_min/device_max` supply viewport X/Y and
near/far in their `plane` components. `clip_min/clip_max` supply larger
limits, initially X/Y = 0 and 4095, also carrying near/far.
[Renderer coordinates](renderer_coordinates.md#persistent-transform-state)
owns their construction and refresh. The viewport setter
`abi_float_arguments_consume` (`0x0010E460`, existing annotation name)
does not rewrite the larger-limit X/Y pair.

Ordinary model and inspected background owners compose `device_projection`
with a child, owner or placement transform. The off-screen path uses its
controller's same matrix field. The classifier consumes the supplied matrix
and never reads `symmetric_projection`; that matrix's construction, copying
and unresolved consumers belong to
[Renderer coordinates](renderer_coordinates.md#persistent-0x0c0-and-bounded-alias-tracing).

## Bounded resident caller inventory

The bounded direct-call screen establishes the following decision owners,
without excluding indirect calls or other visibility routines. The opcode,
call-site counts and alias deduplication are recorded in
`model_classify_bounds`'s annotation.

Background owners below use entry `0x1F`, `visibility_zero_vector` and
`device_projection` composed with the relevant transform. Their common
default renderer pointer is `default_renderer`, the primary draw environment's
renderer member. `bg_classify_inline_transform` instead uses
the current submission context's `BattleHudRenderContext.renderer`.

| Decision owner | Bounds and retained behavior |
| --- | --- |
| `model_dispatch_geometry` (`0x001910E0`) | Ordinary model box gate; classification also selects packet variant. |
| `model_part_queue_projection` (`0x0018CF70`) | Off-screen entry 0 with controller renderer and additional vector. |
| `bg_update_visibility_rays` (`0x00392430`) | `BgVisibilityRayView.bounds_minimum/bounds_maximum` and `position`; retention permits ray queries and `visible`. |
| `bg_classify_inline_transform` (`0x00393AC0`) | `BgInlineVisibilityView.bounds/transform`; returns the wrapper result. |
| `bg_update_visibility_screen_placements` (`0x00394040`) | `BgVisibilityPlacementView.bounds_minimum/bounds_maximum` and `position`; retention permits ray queries, screen placement and `visible`. |
| `bg_submit_optional_model` (`0x003957C0`) | Existing primary instance box rejects before ordinary draw; absent primary draws directly. |
| `bg_submit_visible_composition` (`0x00395DD0`) | First composition child's primary box gates aggregate drawing through `projectile_simple_service_submit`. |
| `bg_update_visible_grass` (`0x00397E60`) | Each child has its own box; `BgVisibilityChildView.visible` records retention and only retained children run `bg_grass_sway_step` (`0x00397BC0`). |
| `bg_rotate_sky_update` (`0x00398510`) | `BgRotatingSky.visible`; retention advances angle and child transform. |
| `bg_sway_update` (`0x003997C0`) | `BgVisibilitySwayView.visible`; retention advances `phase` by `speed * BgScene.update_factor`, evaluates rotation and rewrites child local matrix. |
| `bg_uv_animation_update` (`0x0039B910`) | `BgVisibilityUvView.visible`; retention advances and wraps U/V using `BgScene.update_factor`. |
| `bg_two_model_update` (`0x0039C160`) | `BgVisibilityClothView.visible` is true if either child box survives; both reject skips countdown, random draws and cloth transforms. |
| `bg_submit_shared_model_placements` (`0x0039E710`) | Shared model box is tested per placement; retained placements update the child transform and draw. |
| `bg_submit_matrix_placements` (`0x003A08C0`) | Placement matrices and children are tested separately; rejection clears child `visible`, retention draws. |
| `bg_update_visible_near_vertices` (`0x003A1020`) | `BgVisibilityVertexView.visible`; retention permits camera distance comparison against `distance_max`, then `bg_update_vertex_oscillation` (`0x003A1150`). |
| `bg_update_visible_auxiliary_rotation` (`0x003A1D60`) | `BgVisibilityAuxRotationView.visible`; retention advances angle, transforms the child and updates its auxiliary geometry owner. |
| `bg_update_visible_trigger` (`0x003A27C0`) | `BgVisibilityTriggerView.visible`; retention advances countdown/trigger work and child draw factor. |
| `bg_submit_trigger_uv` (`0x003A2930`) | Records the same `visible` field, but UV parameter update and ordinary draw follow regardless of this result. |
| `bg_submit_optional_model_variant` (`0x003A4920`) | Optional primary-instance box rejects before ordinary draw. |
| `bg_submit_optional_composition` (`0x003A4EF0`) | Optional composition's first child primary box gates aggregate drawing. |
| `bg_submit_range_gated_model` (`0x003A7430`) | A separate `BgVisibilityRangeView.range_min/range_max` gate precedes the optional model box; retention permits auxiliary-owner update and ordinary draw. |

The verified retail class identities are `ccBgRotateSky` for
`bg_rotate_sky_update` and `ccBgUVAnm` for `bg_uv_animation_update`,
recorded by `bg_rotate_sky_vtable` and `bg_uv_animation_vtable` with their
named type descriptors and strings. Other rows receive no unproved class names.

**Inference, high confidence within these methods:** visibility can govern
state advancement as well as packet submission. Rejected rotating-sky and UV
owners skip their increments, and two rejected cloth boxes skip countdown
and PRNG work. Other callbacks' possible writes to those owners remain outside
this bounded conclusion.

## Animated textured-effect rejection

`ccs_effect_child_update` (`0x00195760`) requires a frame selector below
`0xFFFE`, refreshes the transform and inherited factor, then submits through
`effect_submit_transformed` (`0x001961D0`) and
`particle_sprite_submit` (`0x00195A90`). Effective intensity from the
factor and selected frame value is converted to integer and shifted right
five; values below 1 reject and values above 255 clamp to 255.

After composing the effect matrix through the current renderer, the sprite
path rejects translation W below `device_min.plane` or above
`device_max.plane`; equality survives. These are the depth limits also
supplied to the model wrapper, but this effect path does not invoke the box
classifier. `CcsEffectDrawDescriptor.projection_offset` changes the depth
projection calculation before rejection. This one path does not establish
whole-scene or population visibility.

## Particle visibility layers

Distance suppression is separate from box classification.
`particle_emitter_update` (`0x0034C610`) measures XYZ distance from
`ParticleVisual.position` to its supplied reference only when
`ParticleEmitter.distance_enabled` is set. Below `distance_min` or above
`distance_max` sets `ParticleVisual.suppressed`; the inclusive interval
clears it. With the option clear, the branch leaves that byte untouched.
It does not skip subsequent particle updates.
[Particle runtime](particle_runtime.md#distance-suppression-and-alpha-processing)
owns reference production, configured thresholds and alpha formulas.

`particle_manager_draw` (`0x0034FFD0`) requires
`ParticleManager.draw_enabled` before visiting constructed elements.
`ParticleElement.skip_draw_once` suppresses one submission and clears itself;
otherwise `particle_element_draw` (`0x0034B5A0`) requires a non-null visual,
nonzero `active` and clear `suppressed`. History snapshots use the same
visual draw slot. These gates precede the concrete resource's culling.

`particle_visual_vtable` selects `particle_visual_draw` (`0x0034B6F0`),
which rechecks `active` before `particle_visual_draw_resource`
(`0x0034AD60`). Its selector determines the final visibility path:

| Selector | Consumer and visibility boundary |
| --- | --- |
| 0 | `particle_sprite_submit`: intensity and translation-W depth rejection above. |
| 1 | `projectile_simple_service_submit` (`0x00194180`): composition children of type `0x100` use ordinary model drawing and `0xE00` use animated textured-effect drawing. |
| 2 | `projectile_compound_submit` (`0x001BB790`): entries require `CcsPlayEntry.flags & 4`; eligible `0x100/0xE00` entries use the same two draw consumers. |
| `0x12` | `scene_object_submit_geometry`: ordinary enable/factor and model-box gates above. |

`projectile_compound_submit` also draws linked compositions when
`SceneVisibilitySubmissionView.composition_draw_flags & 0x20` and submits
a non-null attached action/particle `attached_manager`. Its scoped renderer substitution
([Renderer coordinates](renderer_coordinates.md#refresh-and-binding-order))
applies to these draws. A particle scene resource can therefore use different
camera inputs from its manager.

**Inference, bounded scope:** no single common population frustum box occurs
at the inspected manager submission boundary. Visibility combines manager
and visual gates, optional distance suppression and the selected draw path.
[Particle runtime](particle_runtime.md#concrete-visual-update-and-draw) owns
construction, history and frame advancement; draw rejection alone does not
establish that particle lifetime or playback stopped.
