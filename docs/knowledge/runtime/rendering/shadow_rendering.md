# Shadows and off-screen passes

## Research coverage

Established: resident controller queues, copied-depth targets, geometry inputs,
composite corner units, separate animation ownership, and fighter/background consumers.
Open: projection-scalar physical units, construction selecting modes 2/3,
indirect consumers, and shadow-enabled parts across all model archives.
Names come from `@annotations/NA2`; comments hold per-routine code details.
Evidence is static retail NA2 and 24 stage payloads; visual results and real-time rates are unestablished.

Retail NA2 (`SLPS-25837`) uses a resident shadow-controller family and a
separate `ccBgDrawShadowAnm` owner. Addresses here are live resident
`SLPS_258.37` EE addresses; see
[address conventions](../../game/files/file_identities.md#address-conventions).
The embedded descriptor establishes the animation owner's original class
name; the `0x1800` controller tag's original class name remains unknown.

The [CCS controller layout](../../game/files/ccs_object_types.md#0x1800-descriptor-fields-and-off-screen-pass)
owns parsing and materialization. [Shadow VU program](shadow_vu_program.md)
owns the uploaded geometry pass. General transforms, model conversion,
visibility and packet allocation belong to
[renderer coordinates](renderer_coordinates.md),
[model runtime](model_runtime.md), [visibility](visibility.md), and
[render submission](render_submission.md).

## Controller drain and target state

`projection_controllers_process` (`0x0018B8E0`) walks the singly linked
controller list and drains each controller's queued work.
`projection_controller_drain` (`0x0018B930`) returns for an empty
`CcsExtendedController.queue_head`; otherwise it assembles an ordered
render chain, clears `queue_head` and `bucket_count`, and restores the
temporary `RenderDisplayState.workspace_cursor` reservation. Dimensions,
mode and animation state survive the drain.

`engine_root_finish_update` drains after draw preparation and before
`transition_present`. The drain lies outside the `frame_gate & 7` branch,
so that branch does not itself suppress it.

The pass order is established by the emitted GS operations:

| Operation | Annotated owner | Contract |
| --- | --- | --- |
| Copy scene depth | `projection_build_depth_setup` (`0x0018C800`) | Sample the selected display depth viewport into the controller's small depth target. Source UV bounds follow the renderer pixel viewport; destination bounds follow target dimensions. |
| Fill color | `projection_build_color_setup` (`0x0018C4C0`) | Fill the complete target with the supplied color, blend choice and framebuffer mask. |
| Install geometry target | `projection_build_color_finish` (`0x0018CC00`) | Select the color and copied-depth targets, centered origin and full-target scissor; enable depth comparison with depth writes masked. Mode 1 protects destination alpha during geometry. |
| Convert bucket alpha | `projection_convert_bucket_alpha` (`0x0018BC60`) | Sample RGB as a 24-bit texture, supplying the bucket key as alpha for nonzero texels and zero alpha for zero texels. Alpha-test failure writes RGB only, preserving accumulated destination alpha. |
| Composite rectangles | `projection_controller_composite` (`0x0018BF90`) | Sample the color target into the controller's ordered draw environment. The general mode-1 path samples accumulated alpha; its single-key special case uses textured black with alpha `0x80`. |

Off-screen work uses GS context 2; final compositing uses context 1.
Register definitions are in the
[PS2SDK GS definitions](https://github.com/ps2dev/ps2sdk/blob/master/common/include/gs_gp.h);
exact register/value pairs are retained in the routine annotations.

The source is the main scene depth buffer: display refresh
`engine_install_display_interrupt` places `RenderDisplayState.depth_base`
after the two color-buffer regions and packs the same base and
`depth_format` into `zbuf_state`. `display_get_depth_base` and
`render_compose_gs_state` use that depth region for ordinary drawing.
The shadow copy therefore preserves existing viewport depth, and subsequent
silhouettes can be compared against it without replacing it.

Target pixels are `W = 1 << width_log2` and `H = 1 << height_log2`.
`color_address` and `depth_address` are GS base-address units, not EE
pointers. Their descriptor mapping is owned by the CCS document.

Both `projection_controller_construct` and
`projection_controller_construct_default` initialize `mode = 1`.
Inspected fighter, background-list and named animation setup retains that
default. Modes 2/3 are concrete code branches; a retail construction path
selecting them has not been established.

| Mode | Drain behavior |
| --- | --- |
| 1, exactly one bucket with key `0x80` | Skip bucket alpha conversion and composite textured black with alpha `0x80`, sampling `PSMCT24`. |
| 1, general path | Process buckets separately, preserve accumulated alpha while clearing RGB between buckets, convert each bucket's alpha, then composite through `PSMCT32` with controller `alpha`. |
| 2/3 | Clear color once, append every bucket's geometry, and composite once without per-bucket alpha conversion. |

`projection_controller_select_bucket` orders distinct strength keys
descending, reuses equal keys, and provides fifteen inline slots. Once full
it reuses an existing neighboring bucket. This finite submission queue has
no animation-history role. The VU pass producing the sampled texels is
owned by [direction classification and extrusion](shadow_vu_program.md#direction-classification-and-extrusion).

`projection_controller_head` is the resident list root. Both controller
constructors prepend to it; `handle_e74_destroy` unlinks the destroyed
controller, and `projection_controllers_process` walks it to drain queues.

## Geometry inputs and renderer ownership

`CcsExtendedController.ordered_base` embeds the ordered environment, and
`renderer` is its renderer binding. Both controller constructors bind
through `ordered_controller_register`; its borrowed/owned contract is
owned by [persistent transform state](renderer_coordinates.md#persistent-transform-state).

The inspected fighter, background-list and named animation constructors
supply the shared `default_renderer` pointer. A `256x256` target does not
itself allocate a separate renderer. The descriptor constructor receives
its renderer from the materialization caller.

Animation submission `projectile_compound_submit` can temporarily replace
`CcsRenderEnvironment.renderer`, as described in
[refresh and binding order](renderer_coordinates.md#refresh-and-binding-order).
It leaves the controller's own `renderer` unchanged. Shadow geometry thus
continues to use the controller-bound renderer during that substitution.

`model_part_queue_projection` (`0x0018CF70`) requires an active controller,
nonzero mode, projection geometry and nonzero
`CcsRenderEnvironment.projection_strength`. Strength is capped to `0x80`
and supplies the queue key. The downstream inputs are:

| Named input | Behavior |
| --- | --- |
| Auxiliary `CcsModelInstance.uniform_scale` | Reciprocal uniform scale adjusts the inverse-model direction; original uniform scale adjusts the model-to-device matrix. Physical model units belong to model runtime. |
| `CcsModelDrawContext.model_matrix` | Supplies the model transform; `matrix_rigid_inverse` derives the inverse with translation XYZ cleared before direction transformation. |
| Environment `projection_direction` and `projection_scalar` | Supply inverse-model direction and scale-adjusted displacement. Displacement W is zero; mode 3 instead zeros displacement XYZ. A separately scaled direction is supplied to bounds classification. |
| Controller `renderer.device_projection` and model matrix | Form model-to-device coordinates before the off-screen remap, using the configured-display path. |
| Renderer `device_min` / `device_max` and target W/H | Remap scale is `W/(right-left)`, `H/(bottom-top)`, with centered origin `((4096-W)/2,(4096-H)/2)`. |
| Renderer `projection_only` and depth planes | Transform `(0,0,max(8,device_min.plane),1)` into the near reference and provide the depth-related bounds. General near/far semantics remain in renderer coordinates. |
| `CcsRuntimeModelPart.projection_geometry` and `projection_geometry_size` | Supply the geometry buffer and its quadword count to the DMA reference. |

Before emission, `model_classify_bounds` checks projected bounds with the
scaled direction, controller renderer, model transform and entry 0.
Its limits are owned by [visibility](visibility.md). Rejection and normal
completion both restore scratch. Successful packets are queued through
`projection_controller_append_packets`; `ShadowProjectionPacket` and
`ShadowVuParameters` name their established fields.

The producer swaps its two RGBA and blend variants when the model axes have
negative orientation. **Inference:** this corrects orientation sign.

The referenced `projection_geometry_microprogram` is `0xC40` bytes at live
`0x003C3CA0`. Its direction classification, displacement, transform and depth
are decoded in [Shadow VU program](shadow_vu_program.md#direction-classification-and-extrusion)
and [the transform and fast geometry pass](shadow_vu_program.md#transform-depth-and-the-fast-geometry-pass).
The physical distance unit of `projection_scalar` remains unestablished.

## Composite units and corner table

`projection_controller_composite` obtains the renderer's device rectangle
through `renderer_get_device_rectangle_fixed4`, which uses
`renderer_get_device_rectangle` and `vector_float_to_fixed4`. Screen
coordinates are integers in 1/16-pixel units; texture UV ends independently
remain `W << 4`, `H << 4`.

Mode 1 uses `N = composite_passes`; modes 2/3 force `N = 1`.
`projection_composite_offsets` at live `0x003FB500` contains ten signed
integer pairs, indexed by `8*N*(N-1)/2`:

| N | Pairs consumed in order |
| ---: | --- |
| 1 | `(0,0)` |
| 2 | `(16,16)`, `(-16,-16)` |
| 3 | `(0,14)`, `(-14,-8)`, `(14,-8)` |
| 4 | `(16,16)`, `(-16,16)`, `(16,-16)`, `(-16,-16)` |

For unsigned `M = offset_multiplier` and pair `(a,b)`, the signed
arithmetic-shift result `sra(M*a,4)` is added to **both coordinates of
the first screen corner**, and `sra(M*b,4)` to **both coordinates of the
second corner**. They are not an X/Y translation vector. Divide the resulting
increments by sixteen for pixel displacement. Unequal components can resize
the rectangle as well as move it, while UV coverage stays fixed.

With the observed two-pass setup `M = 14`, both corners move by
`+14/16` pixel in one pass and `-14/16` in the other. With `M = 0` every
pass has identical bounds. Offsets are fixed by controller settings; the
composite routine has no frame counter or random sample.

There is no count clamp before the table read. The table supports counts
1 through 4; the next data is the unrelated `tone_shade_random_name`
string at live `0x003FB550`. This establishes the table bound without
establishing that retail content requests an invalid count.

## Named shadow-animation owner

`background_shadow_animation_construct` (`0x0039B050`) creates the separate
`0x3C`-byte `ccBgDrawShadowAnm` owner. Its
`background_shadow_animation_vtable` and embedded type descriptor establish
that name. `BgShadowPlaybackView` names its owned `projection` controller
(`0x160` bytes), `player` (`0x120` bytes), `original_step`,
`rate_multiplier` and `projection_scalar`. It is distinct from the
`0x180`-byte CCS extended controller.

Initialization creates and binds the animation player, caches its initial
unsigned step as a float, selects a whole starting frame through
`animation_player_seek`, and creates the controller. Target color/depth
coordinates are `(896,0)` / `(960,0)`, dimensions `256x256`; composite
count, corner multiplier and alpha are separate configuration arguments.

Each `background_shadow_animation_update` writes the player's step from
`original_step * rate_multiplier * scene.update_factor`, converts it to an
integer and retains its low sixteen bits. With a nonnull track table it
calls `animation_advance_position(player, step, 0)` then
`animation_player_compose`. The increment is in 1/256-animation-frame units,
not milliseconds; this owner has no separate shadow-clock increment.
Terminal clamping and looping belong to
[animation runtime](../animation_runtime.md), while invocation follows the
background owner schedule.

`background_shadow_animation_draw` saves the environment controller and
projection scalar, installs its own pair, submits its player, and restores
both. It leaves projection direction and strength unchanged.
`background_shadow_animation_refresh_transform` copies local to world
matrix and clears the dirty byte when no transform parent exists; otherwise
it uses `resource_transform_update`. The register/unregister methods use
`resource_set_environment_enabled(player, 1)` /
`resource_unregister_environment(player)`; shared environment-selection
semantics belong to animation runtime.

`background_shadow_animation_destroy` destroys/frees its controller and
player, unlinks the base owner, and optionally frees itself.
`handle_e74_destroy` clears the environment binding if it refers to the
destroyed controller, removes that controller from the global list, and
destroys its ordered base through `ordered_controller_destroy`.
VRAM target addresses are not heap allocations released by that destructor.
Per-call scratch restoration and per-controller destruction have separate
lifetimes.

## Background controller and fighter consumers

`bg_scene_build` reaches `bg_scene_create_selectors`, which creates twelve
controllers in `BgScene.selector_objects`. Each controller owns a separate
queue and ordered pass while sharing target addresses and the borrowed
renderer:

| Owner | Color / copied depth | Target | Composites | Corner multiplier | Alpha | Ordered slot |
| --- | --- | --- | ---: | ---: | ---: | --- |
| Twelve background selectors | `(896,0)` / `(960,0)` | `256x256` | 2 | 14 | `0x20` | Corresponding `bg_selector_ordered_slots` value minus 5 |
| Fighter `owned_handle_e74` | `(896,0)` / `(960,0)` | `256x256` | 2 | 14 | `0x20` | `-0x800` |

`bg_scene_draw` supplies `BgScene.projection_scalar` and strength `0x80`,
visits all twelve selector lists, binds the matching controller, and submits
children whose `BgObject.draw_enabled` is nonzero. A named shadow-animation
child temporarily replaces that list controller with its own. The background
draw restores the original controller/scalar and prior strength, capped
to `0x80`, afterward.

`bg_scene_update` independently visits five owning child lists. Scene flag
bit 0 suppresses those loops, and each child's `update_enabled` gates its
update. `draw_enabled` and `update_enabled` are distinct. Destruction
first releases those children through their virtual destructor, then
`bg_scene_destroy_selectors` releases the twelve controllers.

`bg_scene_dispatch_records` uses `bg_record_factories`, whose slot 27
is `background_shadow_animation_construct`. The retail `STAGE/S01.CCS`
through `S24.CCS` background payload census found zero factory-27 entries.
That bounded census establishes no direct authored record for this class;
compiled methods do not establish an indirect construction route either.
It does not establish absence of other construction routes or ordinary
background shadows. Census counts and framing evidence are retained in
annotations; [stages](../../gameplay/stages/stages.md#per-stage-bin_bgdata-factory-census)
owns the record framing, and
[battle lifecycle](../../gameplay/session/battle_lifecycle.md) owns battle scheduling.

`fighter_load_character` creates the fighter-owned controller shown above
and binds it before finishing model initialization.
`fighter_release_handles` destroys it and clears `owned_handle_e74`.
This owner is distinct from the twelve background controllers and the named
animation child. [Character assets](../../game/character_assets.md) and
[battle entities](../../gameplay/session/battle_entities.md) own the loader
and fighter lifetime.

`scene_object_submit_geometry` treats ordinary geometry and shadow
auxiliary geometry as separate draw bits. A nonnull
`CcsScenePlayTarget.auxiliary` with `flags & 0x20` enables shadow submission
even when ordinary-model drawing is not selected. It prepares transforms
before `model_part_queue_projection`. Animation submission reaches this
common route for enabled type-`0x0100` track targets. Detailed model
preparation remains in [model runtime](model_runtime.md).

Static xrefs do not prove the absence of other consumers. Vector expressions
and reconstructed prototypes require raw instruction corroboration; no
complete model-archive inventory, visual result or elapsed real-time rate
is established here.
