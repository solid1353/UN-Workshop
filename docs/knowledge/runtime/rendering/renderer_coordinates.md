# Renderer and coordinate systems

## Research coverage

Established: retail NA2 renderer lifetimes, column-vector transforms,
projection/viewport/2D conversions, primary/display ownership and publication,
exact scale inheritance through scoped camera copies, bounded UI renderer
ownership, streamed borrowing, draw-time resets and draw scratch.
The checked renderer methods' shifted matrix/vector output bounds, selected
callback bulk-write destinations and concrete draw-callback output paths are
established.
Open: population and targets of the pre-model scene callback list,
computational use of the persistent symmetric projection, unclassified
inline environment stores and attachments, extreme conversions and degenerate
camera bases. Names and layouts come from `@annotations/NA2`; addresses are live.

This document owns the shared transform contract of retail NA2 (`SLPS-25837`).
Routine comments hold the code-level detail and bounded search counts. Static
instruction operands take precedence over decompiler argument recovery; missing
xrefs do not establish whole-program absence. See
[address conventions](../../game/files/file_identities.md#address-conventions).

Related owners: [Visibility](visibility.md), [Model runtime](model_runtime.md),
[2D draw ownership](draw_2d_owners.md), [Render submission](render_submission.md),
[Texture and material runtime](texture_material_runtime.md),
[Shadow rendering](shadow_rendering.md), [Model VU programs](model_vu_programs.md),
[Shadow VU program](shadow_vu_program.md), [Particle runtime](particle_runtime.md),
and [Battle camera](../../gameplay/session/battle_camera.md).

## Persistent transform state

`renderer_construct` initializes a caller-supplied `RendererTransformState`.
It sets the four limit vectors to `(0,0,0,1)`, sets upper-limit XY to 4095,
installs the clip/depth defaults below and refreshes an identity camera **before** initializing
the logical viewport and projection scales. It performs no second camera
refresh. Matrices derived from the initialized viewport need a later refresh.

| Value | Constructor default |
| --- | ---: |
| Near / far plane | 8 / 1048576 |
| `depth_far` / `depth_near` | 0 / 1048575 |
| `field_of_view`, degrees | 45 |
| Logical viewport | `(0,0,512,384)` |
| Projection scales | `(1,1)` |

| Owner | Allocation and lifetime contract |
| --- | --- |
| `ordered_controller_register` | A null supplied renderer allocates and constructs a `0x2B0` renderer; a supplied renderer is borrowed. `BattleHudRenderContext.renderer` and `owns_renderer` retain that distinction. `draw_environment_replace_renderer` releases an owned previous renderer, installs a borrowed replacement and clears ownership. |
| `renderer_owner_construct` | Constructs `RendererOwner.embedded_renderer`. `renderer_owner_destroy` unlinks it with delete flag -1 before destroying the two embedded environments, without separately freeing it. |
| `lazy_camera_holder_initialize` | Lazily creates an eight-byte `LazyCameraHolder`, its separately allocated renderer, and a resource-linked player. It refreshes that renderer from the player's camera. `battle_item_globals_release` releases both children and holder, then clears the holder global. |

`renderer_owner_initialize_environments` (`0x00329930`) gives the owner's primary
environment the renderer borrowed by `effect_manager_global+0x2A10`, and its
secondary environment a separately allocated one, then sets both viewports.
The effect-manager environment belongs to the borrowed-default array described
below. Neither attachment follows merely from the existence of
`RendererOwner.embedded_renderer`.

Construction inserts a renderer into the registered list through
`renderer_list_insert`; `renderer_list_remove` unlinks a matching object.
`renderer_destroy` unlinks every nonnull object and frees it only for a positive
signed delete flag. This permits embedded renderers to be unlinked without
freeing their containing allocation.

`renderer_copy_state` transfers all eight matrices, four limit vectors, camera
reference, viewport/packed bounds, list pointer, centers, scales, logical
rectangle, depth endpoints, field of view and focal coefficient. It also
transfers words at `+0x2A4/+0x2A8`, whose meanings remain unestablished. Thus
`renderer_set_projection_scales` is not the only publisher of scale values.

The matrix and vector fields have these established roles; the same fields
are copied by `renderer_copy_state`:

| `RendererTransformState` field | Role |
| --- | --- |
| `inverse_camera_rotation` | `rigid_inverse(C)*Rx(-pi)`, with translation reset to `(0,0,0,1)` |
| `device_projection` | Configured-display projection composed with `C` |
| `camera_transform` | Supplied camera matrix, or its composition with the optional third matrix |
| `symmetric_projection` | Symmetric near/far projection composed with `C` |
| `logical_projection` | Fixed-512-reference projection composed with `C` |
| `projection_only` | Configured-display projection before camera composition |
| `device_affine` | Separate device mapping using display half-extents and depth midpoint |
| `transform_2d` | Logical 2D transform composed with device mapping at 16 units per display pixel |
| `device_min` / `device_max` | XY device viewport endpoints; `plane` holds near/far |
| `clip_min` / `clip_max` | XY initialized to 0/4095; `plane` holds near/far |
| `camera_reference` | `rigid_inverse(C)*camera_reference_axis`, where the constant is `(0,0,-1,1)` |

`renderer_set_clip_planes` writes both limit pairs' plane fields without
refreshing matrices. `renderer_set_depth_endpoints` independently writes depth
endpoints. `camera_output_submit` copies `EngineBattleCamera.field_of_view` and
refreshes from `view_matrix` plus the optional third matrix.

## Primary renderer publication and scale inheritance

`engine_root_allocate` (`0x00105FC0`) registers the resident
`primary_draw_environment` (`0x00609160`) with selector 0 and a null supplied
renderer at call `0x001060D4`. It therefore owns a constructed, registered
`0x2B0` renderer. The following two registrations give the engine's environment
at `+0x110`, selector `0x7FFE`, another owned renderer, and environment
`+0x150`, selector `0x7FFF`, the borrowed pointer from engine `+0x14C`.
The two display environments share one renderer; the resident primary owns
a different one. List membership, a full-frame viewport and the active
environment alone do not distinguish these allocations.

`ordered_controller_register` (`0x0010A1D0`) publishes an owned renderer at
environment `+0x3C` only after `renderer_construct` returns. The constructor's
centered-viewport call at `0x0010F3FC` has already written scales `(1,1)` and
its later call has registered the object. At `0x001060DC`, after the primary
registration returns, `default_renderer` (`0x0060919C`) identifies that
published object. During its constructor's scale write the primary slot does
not yet identify the new allocation.

`default_renderer` is the primary environment's actual `+0x3C` slot. In
`projectile_compound_submit` (`0x001BB790`), `s3` saves the active environment
and `s4` saves its renderer; the copy, bind, camera-refresh and restore calls
are `0x001BB7F0`, `0x001BB7FC`, `0x001BB808` and `0x001BB934`.
If that environment is the resident primary, `scene_renderer_set`
(`0x001BB9C0`) temporarily changes `default_renderer` to the player's copy.
If it is a different environment borrowing the primary renderer, only that
environment's slot changes. Other borrowed references retain their existing
pointer. The swap retains `owns_renderer`; that byte describes environment
ownership and does not prove ownership or registration of its temporary binding.

The scale pair has these publication rules:

| Operation | Exact scale behavior |
| --- | --- |
| `renderer_set_projection_scales`, `0x0010ECC0` | Stores `f12/f13` at renderer `+0x274/+0x278`, with no matrix refresh. The viewport updater calls it at `0x0010EC30`. |
| `renderer_list_refresh_viewports`, `0x0010F210` | Loads each registered object's stored X/Y into `f18/f19` at `0x0010F244/0x0010F248`, then republishes them through the viewport updater. It performs no scale arithmetic or camera refresh. |
| `renderer_copy_state`, `0x001BB9D0` | Load/store pairs `0x001BBC14/0x001BBC18` and `0x001BBC1C/0x001BBC20` reproduce source X/Y exactly, without arithmetic. |
| `camera_output_submit` / `renderer_refresh_camera` | Updates field of view and derived matrices using the existing scale pair; leaves the pair and current 2D matrix intact. |

Every camera-bearing submission copies from the currently bound source, even
when the player's allocation already exists. The allocation therefore has no
permanent renderer role: reuse under another environment replaces its old
viewport, scales and matrices with that environment's current state. Nested
camera-bearing submissions inherit the current binding by the same rule;
normal return restores pointers without copying state back to a source.
The registered list does not visit these unconstructed copies. Display-refresh
changes reach a reused copy through the next full-state copy from its source.

The [selected UI owners](#selected-ui-renderer-bindings) establish that the
scale pair is not universally `(1,1)`: the command HUD's two independent
renderers receive X 1 and Y bits `0x3F5B6DB7` at BTL calls `0x00728720` and
`0x007287AC`. Its camera copies retain those values by the same copy contract.
Streamed main/resource/auxiliary environments instead initially borrow one
renderer, as established under [streamed exceptions](#draw-environment-selection-and-streamed-exceptions).
Their separately allocated render/light state is another object class.

The bounded resident/BTL/ETC literal `swc1 +0x274` screen finds only the
scale setter and full-state copy as renderer writes; its other unique matches
use the stack pointer. The direct-call-word screen likewise finds only the
viewport updater's call to the setter. These checks do not cover shifted
aliases, integer/vector/wide stores, computed calls or external bulk copies.
The routine annotations retain the search bounds. The coordinate and
visibility sections own the consequences of the derived matrices.

### Projection-scale writer bounds

The checked renderer methods contain no additional scale writer through a
shifted matrix/vector destination. This closes their output intervals; it does
not close every route through which another routine can receive a renderer
pointer. `RendererTransformState` is `0x2B0` bytes, with the two floats occupying
`[+0x274,+0x27C)`, confirmed in the applied NA2 type.

| Checked route | Destination evidence |
| --- | --- |
| `renderer_refresh_camera`, `0x0010DAF0` | Persistent matrix outputs begin at `+0x000/+0x040/+0x080/+0x0C0/+0x100/+0x140/+0x180`, each spanning `0x40` bytes. The reference-vector output spans `+0x240..+0x24F`; focal coefficient is at `+0x2A0`. Other matrix work uses separate scratch. |
| `renderer_set_2d_transform_offset`, `0x0010ECD0` | Its shifted output at `0x0010EF60` is renderer `+0x1C0`; the multiplication at `0x0010EF6C` writes exactly `0x40` bytes, ending before `+0x200`. Local stores at scratch `+0x70/+0x74` are separate from the renderer. |
| `abi_float_arguments_consume`, `0x0010E460` | Other stores cover device XY, pixel/packed bounds, centers and logical fields. The `sd` at `0x0010E918` covers `+0x260..+0x267`. Scale publication reaches the checked setter; the final matrix publication ends at `+0x1FF`. |
| Constructor and camera/scalar publishers | `vector_store_vu_zero_constant` writes only each supplied limit vector's `0x10` bytes. Clip-plane stores remain in those vectors; depth stores are `+0x294/+0x298`; `camera_output_submit` stores field of view at `+0x29C` before refresh. |
| Environment binding | `scene_renderer_set` writes the pointer at environment `+0x3C`, while `draw_owner_register_environment` (`0x0038CFE0`) stores a newly allocated environment at owner `+0x3F4`. These operations do not copy renderer bytes. |

`matrix_identity_initialize` (`0x0010BAA0`), `matrix_copy_4x4`
(`0x0010BF20`), `matrix_multiply` (`0x00152020`) and
`matrix_rigid_inverse` (`0x00152138`) have exactly `0x40` output bytes.
`vector_transform_four_components` (`0x00151FF0`) has `0x10` output bytes.
Their raw stores and the checked callers' destination arguments establish the
intervals above, including loop increments and delay-slot stores.

The callback owner's bulk writes are a separate object identity.
`render_callback_owner_initialize` (`0x0036E920`) and
`render_callback_owner_reset` (`0x0036EDD0`) clear payload spans
`[0,0x288)`, `[0x28C,0x2A4)` and `[0x2B8,0x2C0)` relative to that owner.
`render_callback_owner_apply_record` (`0x0036EC20`), mode 2, copies eight
bytes at owner zero and five `0x80`-byte blocks at `8+i*0x80`, ending at
`+0x288`. These spans include numerical offsets `+0x274/+0x278` within
the callback payload, but its environment pointer is at `+0x2C8` and its
renderer is a separate allocation reached through environment `+0x3C`.
The copies/reset therefore do not overwrite renderer scales. Existing-context
reset changes the ordering group; absent-context reset creates an environment
and reaches ordinary viewport publication.

`copy_record_bytes` (`0x0017A420`), `memory_move` (`0x0017A4D0`) and
`memory_fill` (`0x0017A5D8`) write caller-selected byte spans. Their integer
`sq/sd/sb` loops can cover scale bytes if supplied such a destination; their
generic implementations establish no renderer exclusion. The checked resident
copy destinations and application fill owners, plus the BTL bulk-call cohort,
use payloads, arrays, snapshots, scratch or packet buffers; no additional live
primary/scoped renderer destination was verified. A generic output parameter
alone does not establish a renderer destination; the reachable draw paths below
retain distinct scratch, geometry and packet outputs.

The expanded literal store screen also includes byte, halfword, integer and
wide stores, and immediate address formation with `0x270/0x274/0x278`.
The checked resident non-stack candidates are
`battle_particle_generator_pre_update`'s particle position and
`battle_driver_child34_release`'s portrait-array base. In
`transient_actor_005e0270_construct` and `transient_actor_005e0270_destroy`,
the `0x270` immediate completes the absolute methods address `0x005E0270`,
stored at the actor's `+0x50`; it does not form a renderer-field alias.
Other operand matches remain candidates, not established renderer writes or
reachable aliases of primary/scoped state.

### Reachable draw destinations

`projectile_compound_submit` exposes its bound renderer through the selected
environment during ordinary model, effect, composition and particle submission.
The checked consumers retain these destination identities:

| Reachable route | Write destination and span |
| --- | --- |
| Registered-list insertion/removal | Only a four-byte `next` store at renderer `+0x268`, ending before `+0x26C`, or the list-head global. |
| `scene_object_submit_geometry` / `model_draw_parameters_setup` | Scene inline copy is `world_matrix[16]`. Drawing reserves a separate `0x280`-byte `CcsModelDrawContext`; its `+0x1F8` snapshots the renderer pointer. Context matrices and scalar stores do not address that renderer allocation. |
| `model_submit_packed_geometry` | Its inline `0x40`-byte `projection_only` copy targets context `+0x000..+0x03F`; depth adjustment and composition write context matrices. Renderer limit-vector copies target the allocated packet. |
| Checked morph-controller slots | `modifier_empty_apply` has no stores. `morpher_blend_vertices` reads the renderer into stack rectangle/matrix outputs and writes geometry arrays. `cloth_model_modifier_apply` and `background_strip_modifier_apply` obtain writable geometry through `model_draw_edit_positions`; they do not use `context.renderer` as output. |
| Concrete texture submission slots | `texture_chunk_submit_levels` reaches descriptor-array submission and `image_transfer_build_packet`, which writes a `0x90`-byte packet. `sampling_texture_capture` writes its separately allocated capture packet. Their environment argument supplies packet ownership/linkage, not a renderer output. |
| Effect/particle drawing | `particle_sprite_submit` reads renderer matrices into separate `0xD0` display scratch and emits a `0x1B0` packet. The checked emitter binding slots store only environment pointers at emitter `+0x1D8` or generator `+0x230`; their pre/post draw slots are empty. Concrete visual drawing returns to the same sprite/model/composition/scoped-camera paths. |
| Projection and optional model passes | `model_part_queue_projection` uses `0x3E0` scratch and a `0x170` packet; its renderer is input. Ordinary/packed extra passes allocate `0x100/0x110` packets, and packed descriptor state allocates `0x120`. Scalar helper outputs are three four-byte caller stack slots. |

The concrete morph slots are resolved from `morpher_vtable`,
`cloth_model_modifier_vtable` and `background_strip_modifier_vtable`; texture
slots come from `texture_chunk_vtable` and `sampling_texture_chunk_vtable`.
The [model geometry owner](model_runtime.md#morph-control-and-geometry-ownership)
owns their broader geometry contracts. The
[particle owner](particle_runtime.md#drawing-and-history) owns resource dispatch.

There is a transitive generic copy on the cloth path:
`cloth_model_positions_publish` installs the output of
`model_draw_edit_positions` at cloth owner `+0x3C`, and
`cloth_grid_positions_copy` passes that pointer plus computed `6*index` to
`copy_record_bytes`, always with length six. The destination is the acquired
geometry array. This computed bulk path supplies no additional renderer-scale
writer. Model property conversion similarly writes separate geometry and
matrix workspace; `model_classify_bounds` only loads renderer limit vectors.

The wire modifier has a second output besides its acquired 24-byte positions.
`bg_wire_segment_construct` installs `background_strip_modifier_vtable` on the
segment's inline modifier; `wire_segment_build` supplies its owner, and
`wire_segment_create_geometry` binds it to a separately allocated `0x200`-byte
procedural visual. `background_strip_positions_publish` follows segment
`+0x1C0`, then visual `+0x94`, and writes three vec4s. The latter pointer is
the inline model's bounds: `procedural_visual_bind_model` binds instance
`+0x4` to descriptor `+0x10`, so these 48 bytes are visual
`[+0x110,+0x140)`. `wire_segment_refresh_visual_bounds` writes the same span.
Neither output aliases the selected renderer. MCP data xrefs omit the BTL
constructor's computed vtable constant; its instructions at
`0x006C8C7C..0x006C8C84` establish that installation directly.

### Unresolved scene callback path

The separate pre-model list is a conditional edge whose retail reachability
remains unresolved.
`scene_pre_model_callback_dispatch` (`0x00191068`) follows scene `+0xA4`,
node `+0x4`, then table `+0x8`, and calls with the node and drawing context.
That context's `+0x1F8` can identify primary state or the currently bound scoped
copy. This is separate from the concrete morph-controller slot above.

`ccs_scene_child_bind_models` initializes scene `+0xA4` to null. A retail path
that subsequently populates the list, and the resulting target set, have not
been established. The indirect call supplies no fixed callee reference.
Without those targets, neither a renderer write nor an output byte span can be
assigned to this callback path. Its remaining question is whether a populated
node can write the renderer's `[+0x274,+0x27C)` directly or pass that destination
to another writer. No such overwrite is verified by the checked consumers.

## Matrix storage and multiplication

Matrices store four consecutive vec4 columns. `vector_transform_four_components`
computes `col0*x + col1*y + col2*z + col3*w`; translation is the fourth column.
`matrix_multiply(out,A,B)` produces `A*B`, applying `B` first.

`matrix_rigid_inverse` transposes the upper 3 by 3 basis and negates its product
with the original translation. It is a rigid-transform inverse; arbitrary
scale/shear inversion is not established for it.

With optional third matrix `T`, `renderer_refresh_camera` first forms
`C=T*cameraMatrix`; otherwise it copies the camera matrix. It stores `C` in
`camera_transform` and derives its projection matrices as `projection*C`.
`matrix_rotate_x`, `matrix_rotate_y_polynomial` and `matrix_rotate_z` left-multiply
the source matrix by their rotation. Their angles are radians. Field-of-view
conversion from degrees is a separate operation.

## Camera matrix builders

The renderer receives a world-to-view matrix in `EngineBattleCamera.view_matrix`.
Selection and movement remain with the camera's owner.

| Builder | Input-to-matrix contract |
| --- | --- |
| `engine_camera_set_view` | `forward=target-eye`; reference axis `(0,0,-1,0)`, replaced by `(1,0,0,0)` when forward X and Y are both zero. |
| `matrix_build_camera_basis` | `right=normalize(referenceAxis cross forward)`, `forward=normalize(forward)`, `up=forward cross right`; add eye translation, then rigid-invert to world-to-view. `vector_cross_xyz` and `vector_normalize_xyz` produce W zero. |
| `camera_set_from_transform` | Rigid inverse of `sourceTransform*Rx(pi)`; uses and returns `0x50` display-scratch bytes. |
| `hud_view_transform_initialize` | Build `Rz(az)*Ry(ay)*Rx(ax)*Rx(pi)`, add caller position, rigid-invert; uses and returns `0x50` scratch bytes. |

Degenerate camera bases are not established. The demonstrated position/angle
accesses do not supply the original asset names of the two input vectors.

## Projection refresh

`renderer_refresh_camera` uses and returns `0x1C0` scratch bytes separately from
the persistent object. Let `W/H` be `EnginePadContext.display_width/display_height`
and `gY` be `display_vertical_factor`; let `theta` be the renderer's
`field_of_view`, `sx/sy` its projection scales, and `cx/cy` its projection centers.
It computes `d=2*tan(theta*pi/360)`, `F=W/d` and `F512=512/d`, storing `F` in
`focal_coefficient`. The focal coefficients coincide only when `W=512`.

Before camera composition, the configured projection has diagonal coefficients
`F*sx` and `F*sy*gY`, homogeneous output `w'=z`, and center contributions
`cx*z`, `cy*z`. With near/far planes `n/f` and depth endpoints
`z0=depth_far`, `z1=depth_near`, its depth numerator is `B*z+A`, where
`A=n*f*(z1-z0)/(f-n)` and `B=(z0*f-z1*n)/(f-n)`. After division,
`depth=B+A/z`: near maps to `z1`, far to `z0`.

The fixed-reference projection uses `F512*sx`, `F512*sy`, and half the logical
viewport width/height as center contributions. It reuses the depth terms;
its vertical scale does not include `gY`.

The symmetric projection uses horizontal/vertical coefficients `F/(W/2)` and
`F/(H/2)`, depth coefficients `(f+n)/(f-n)` and `-2*f*n/(f-n)`, and `w'=z`.
The separate affine mapping contains `(W/2)*sx`, `(H/2)*sy*gY`, depth scale
`(z0-z1)/2`, depth translation `(z0+z1)/2`, and center translations `cx/cy`.

**Inference, high confidence:** these coefficients imply
`device_affine*symmetric_projection=device_projection`, apart from floating
rounding. The stored symmetric projection already includes `C`. This algebraic
equivalence does not establish a consumer or a draw path that multiplies the
stored matrices.

### Persistent `+0x0C0` and bounded alias tracing

The persistent `symmetric_projection` and the refresh's fixed-reference scratch
matrix are separate data paths. A literal `0xC0` displacement alone cannot
identify which one is accessed.

`renderer_copy_state` does copy the persistent symmetric projection. In its
scoped scene-draw use, `projectile_compound_submit` copies, binds, and refreshes
the clone before model, effect, composition or attached-manager submission.
No computational use of that copied matrix intervenes; the refresh replaces it.

The bounded candidate classifications are stored in the owning routine comments.
They identify light-environment storage, decoded triangle vectors, payload
strides, draw-workspace color, and local object orientation/vector storage.
They do not cover every scalar access within the matrix, computed indexing,
aliases formed by multiple smaller additions, indirect calls or arbitrary
external bulk copies. Other literal candidates remain unclassified. Neither
the copy nor the classified candidates prove the matrix unused or establish a
visible fault.

## Logical viewport and 2D device coordinates

The viewport updater retains the logical rectangle and center offsets, converts
X by `W/512` and Y by `H/384`, and publishes `pixel_left/top/right/bottom` as
`(left,top,left+width,top+height)`. Packed bounds add 0.5 to left/top and subtract
0.5 from right/bottom, truncate toward zero for finite viewport-sized inputs,
and clamp to `0..W-1` or `0..H-1`. Extreme and nonfinite inputs remain open.

Device-centered origin is the logical origin in display pixels plus
`2048-(W>>1)`, `2048-(H>>1)`. Projection center adds logical center offsets
scaled by `W/512`, `H/384`. Device endpoint fields use a separate scalar
float-to-integer rounding path after adding 0.5, then convert back to float;
this is distinct from packed-bound truncation.

After publishing projection scales, the updater resets the logical 2D
transform to scale `(1,1)`, rotation 0 and pivot `(256,192)`.
`renderer_set_2d_transform_offset` builds
`T(pivot+offset)*Rz(rotation)*S*T(-pivot)` and composes it with device mapping:

| Component | Coefficient |
| --- | --- |
| X / Y diagonal | `16*W/512` / `16*H/384` |
| X translation | `32768-8*W+viewport_left*16*W/512` |
| Y translation | `32768-8*H+viewport_top*16*H/384` |

With display 512 by 384, identity local transform and zero viewport origin,
logical `(256,192)` maps to device `(32768,32768)`, and one logical unit maps
to 16 device units. Packet-level meaning belongs to render submission.

### 2D publication and retention

The inspected publisher and binding paths have different effects on the stored
matrix. `renderer_set_2d_transform_offset` (`0x0010ECD0`) rebuilds its two scratch
matrices and writes their product to `renderer+0x1C0` at `0x0010EF6C`; it does
not compose with the previous `transform_2d`. Its raw inputs are renderer in
`a0`, scales in `f12/f13`, rotation in `f14`, pivot in `f15/f16` and offsets in
`f17/f18`. This register contract does not settle original mixed C parameter
order. `renderer_set_2d_transform` (`0x0010EC90`) supplies zero offsets and
forwards the other inputs.

| Operation | Effect on `transform_2d` |
| --- | --- |
| `abi_float_arguments_consume`, `0x0010E460` | Publishes viewport/scissor and projection scales, then replaces 2D with centered unit scale and zero rotation/offsets. |
| `renderer_list_refresh_viewports`, `0x0010F210` | Replays that replacement for registered renderers using their stored viewport and projection scales. |
| `renderer_refresh_camera`, `0x0010DAF0`; `camera_output_submit`, `0x0010E220` | Refresh camera/projection fields while retaining the current 2D matrix. The inspected camera-refresh body ends at `0x0010E1DC`. |
| `renderer_copy_state`, `0x001BB9D0` | Copies the full 2D matrix as well as viewport/scissor and projection state. |
| Environment selection or `scene_renderer_set` | Changes the pointer through which subsequent work finds renderer state; does not recompute its matrix. |

`scene_player_refresh_renderer` (`0x001BB990`) takes a draw environment:
`0x001BB998` loads its `+0x3C` renderer before camera output. Consequently the
scoped camera refresh in `projectile_compound_submit` retains the copied 2D
matrix even though it replaces copied camera/projection matrices. Restoring
either an environment global or a renderer pointer does not undo writes made
to the selected renderer. These conclusions cover the inspected paths, rather
than every possible inline matrix store or external bulk copy.

## Coordinate utility consumers

| Utility | Transform/output contract |
| --- | --- |
| `renderer_project_logical` | Homogeneous input through `logical_projection`, divide XYZ by W, quantize XY to four fractional bits and Z to integer, recover XY floats and write W zero; returns logical projected XY and mapped integer depth. |
| `matrix_project_integer` | XYZ homogeneous division, then four-fraction-bit conversion; with nonzero fourth argument only ZW are replaced by integer conversion, retaining XY fractional bits. |
| `renderer_screen_depth_to_world` | Camera-space `(depth*(screenX-256)/F,depth*(screenY-192)/F,depth,1)`, transformed by rigid inverse `camera_transform`. |
| `renderer_transform_2d_integer` | `transform_2d` then integer conversion on all components, without homogeneous division. XY already represents 16 units per display pixel. |
| `renderer_get_device_rectangle` / `renderer_get_device_rectangle_fixed4` | Return device XY endpoints as floats / four-fraction-bit integers; no point projection. |
| `renderer_get_pixel_viewport` / `renderer_get_pixel_viewport_fixed4` | Return pixel viewport bounds as floats / four-fraction-bit integers. |
| `renderer_get_camera_reference` | Copy the inverse-camera-derived reference vector. |

**Inference, high confidence:** the depth-specified screen-to-world utility is
not a general inverse of the projection. It uses fixed center `(256,192)` and
configured-width `F`, ignoring viewport center, rectangle and scales. XY formulas
coincide for the default 512-unit identity-scale case with matching camera-space
depth, subject to forward quantization. The inverse needs camera-space depth;
the forward utility returns mapped depth `B+A/z`.

Rectangle consumers transform anchors through the full `transform_2d` matrix
but scale extents only by its X/Y diagonal. Their clipping and caller ownership
belong to [2D draw ownership](draw_2d_owners.md#clipping-and-coordinate-ownership).

## Per-draw 2D transform records

`DrawTransformRecord2D` is separate from persistent renderer state.
`draw_transform_record_initialize` gives both scale fields the same caller
float, sets the caller rotation, pivot `(256,192)` and offsets `(0,0)`.
`draw_transform_record_reset` supplies the same transform defaults with unit
scale and zero rotation. Color, draw mode and other packet controls have separate
ownership.

Both `draw_environment_submit_2d_record` packet branches construct viewport
corners `(-px,-py)`, `(rw-px,-py)`, `(-px,rh-py)`, `(rw-px,rh-py)` and apply
`renderer.transform_2d*T(pivot)*T(offset)*Rz(rotation)*S` to all four. The packet
operations differ, but the transform contract is shared.

Three lifetimes remain distinct: persistent renderer, caller-supplied local
record, and temporary composed matrices. `display_scratch_allocate` rounds
requests to 16 bytes and advances `EnginePadContext.display_scratch_cursor`;
`display_scratch_restore` restores it. Scratch allocation does not construct
or register a renderer.

## Refresh and binding order

`renderer_set_centered_viewport` derives center offsets from half the caller
rectangle width/height. `renderer_list_refresh_viewports` replays each registered
renderer's stored rectangle, offsets and scales through the viewport updater.
Its display-reconfiguration caller, `engine_install_display_interrupt`, first
updates dimensions and `gY=H*(4/3)/W`. This republishes viewport/scales and resets
2D defaults without a camera projection refresh. Scale, clip-plane, depth,
viewport and camera refresh are distinct operations.

`draw_environment_select` chooses an environment. `scene_renderer_set` swaps
its renderer pointer and `scene_renderer_get` reads it, while `draw_environment_replace_renderer`
performs ownership-aware replacement. A direct swap preserves `owns_renderer`.
Battle camera publication is owned by
[Battle camera](../../gameplay/session/battle_camera.md#common-camera-update-and-output).

The following resident ELF BSS globals have verified roles and annotation names:

| Global | Role |
| --- | --- |
| `registered_renderer_list_head` | Registered renderer-list head |
| `active_render_environment` | Active render/light environment |
| `active_draw_environment` | Active draw environment |
| `lazy_camera_holder` | Lazy camera-holder pointer |
| `primary_draw_environment` | Primary draw environment |
| `default_renderer` | Primary environment's renderer pointer, at `primary_draw_environment+0x3C` |

When `CcsAnimationPlayer.camera` exists, `projectile_compound_submit` saves the
active environment's renderer, lazily allocates `renderer_copy`, copies the saved
renderer, binds the copy and refreshes it through `scene_player_refresh_renderer`
and `camera_output_submit`. It restores the saved pointer after drawing with no
copy-back. This path constructs no renderer and registers no clone; copying
`next` alone does not insert the clone into the list. `animation_player_destroy`
frees and clears `renderer_copy`. Other player ownership belongs to
[Scene playback owners](../scene_playback_owners.md).

### Selected UI renderer bindings

The following inspected owners distinguish environments from renderer objects.
An ordering selector identifies a list, not a unique renderer or coordinate
policy. The array and borrowed paths below can select many lists backed by one
renderer. Null renderer arguments instead create independently registered states.

| Owner | Selected renderer states and later publications |
| --- | --- |
| `panel_initialize`, `0x0037FFC0` | Backing/modal cover, border and text environments each own a renderer. Rectangle, origin, style, force-open/closed and transition updates republish only the text renderer's interior or zero viewport; backing and border remain distinct. |
| Running-help strip | Backing and text environments own separate renderers. `scrolling_strip_configure` and `scrolling_strip_set_rectangle` refresh both viewports with center offsets `(256-x,192-y)` and unit projection scales. |
| Ordinary battle top panel | Primary environment borrows `default_renderer`; secondary environment owns a renderer used by chakra feedback. The root, combo and prompt layers also include borrowed-default bindings. Full component ownership belongs to [Battle HUD](../../gameplay/session/battle_hud.md). |
| Lower item/support HUD, clock and notice | Item-manager setup creates seven borrowed-default environments; support and clock also borrow that renderer. `battle_notice_construct` owns a separate notice renderer plus its panel's three states. Notice text updates the panel text viewport. |
| `commands_hud_construct_children`, `BTL.BIN:0x00728620` | Two environments at owner `+0x50/+0x54` own separate renderers. Both viewport calls supply horizontal projection scale 1 and vertical bits `0x3F5B6DB7`; these are projection values, while the updater resets 2D to unit scale. |
| Ninja Song details | `endpoint_counter_player_construct` (`BTL.BIN:0x00717DA0`) creates three owned renderers. Update (`0x00717FC0`) republishes context `+0x58` with model-derived viewport X; draw selects `+0x54/+0x58/+0x5C` for animation, objectives and footer. Camera publication is separate. |
| Collection Figure and Diorama | Figure environments `+0x1C/+0x20` and Diorama `+0x18/+0x1C` each own two renderers; their footer environment borrows `default_renderer`. The paired setters republish panel-derived cropped viewports with a vertical center offset of half height plus 80. |
| Collection Voice, Skill, Movie and Music | Scene environments `+0x20`, `+0x1C8`, `+0x24` and `+0x74` respectively own renderers; footers borrow `default_renderer`. Movie's `+0x28` background environment also borrows it. Voice/Skill/Music republish cropped scene viewports; Movie present republishes full `(0,0,512,384)` before camera output. Panel renderers remain additional states. |
| `effect_manager_construct`, `0x00309DF0` | Twelve embedded environments at `+0x2950+i*0x40` and one at `+0x2B0` borrow `default_renderer`. Thirteen viewport updates reset that same borrowed state; the battle-generator fallback environment `+0x2990` is the array's second member. |
| `stream_break_transfer_group_initialize`, `0x00372DF0` | Capture and presentation environments each borrow `default_renderer` and reset its full viewport on first allocation. Selection is restored after initialization, but the renderer writes persist. `stream_break_draw` selects the presentation environment while camera output uses the capture environment's renderer. |

The Collection update/present entrypoints are `collection_figure_viewports_update`
(`ETC.BIN:0x006BA350`), `collection_diorama_viewports_update` (`0x006BD490`),
`collection_skill_viewport_update` (`0x006BF970`), `collection_voice_present`
(`0x006C2EB0`), `collection_movie_present` (`0x006C4560`) and
`collection_music_present` (`0x006C5D70`). Figure/Diorama setup creates two
scene states with selectors `0x50/0x49`; Voice/Skill/Movie/Music use `0x30` for
their separate scene state. All these footer bindings use selector `0x60`.
Their bounded UI draw purposes belong to
[Collection UI](../../localization/ui/collection.md). A scene viewport does not
make its authored model children logical-2D artwork.

Borrowing can republish primary state outside its original constructor.
`transition_pool_initialize` (`0x001834B0`) creates its shared selector-`0xFE`
environment only once, borrowing `default_renderer`, then sets the full viewport.
`pause_gauge_construct` (`BTL.BIN:0x0076AD20`), `pause_controller_cleanup`
(`0x0076F1A0`) and `skill_embedded_presentation_construct` (`0x007F0860`) also
reset a borrowed-default renderer. These paths do not restore old viewport or
2D values when they restore environment selection.

### Ultimate Jutsu callback renderer states

Streamed scene environments below borrow their main renderer, while the
Ultimate Jutsu draw callback has additional owner lifetimes. `sp_skill_play_start`
constructs the CCFM owner submitted by `sp_skill_play_draw` through
`ccfm_owner_draw` (`0x003701E0`). The inspected record families select these states:

| CCFM root member | Renderer and viewport-publication lifetime |
| --- | --- |
| Callback owner `+0xC8`, environment `+0x390` | Owns a renderer; constructor call `0x0036EA30` sets full-frame defaults. `render_callback_owner_reset` (`0x0036EDD0`) republishes at `0x0036EEFC` only when recreating an absent environment. |
| Auxiliary owner `+0x3E0`, environment `+0x484` | Owns a renderer; `ccfm_auxiliary_draw_owner_construct` (`0x0036F020`) republishes at `0x0036F0C0`. Root reset/load calls `0x0036FEEC/0x0037094C` do so only when the environment is absent. |
| Transformed owner `+0x490`, environment `+0x4DC` | `ccfm_transformed_draw_owner_construct` (`0x0036F260`) borrows `default_renderer` and unconditionally resets it at `0x0036F310`. It destroys the temporary nested callback environment and aliases that nested slot to its borrowed outer environment. |

`ccfm_transformed_draw_owner_reset` (`0x0036F640`) retains an existing outer
environment and changes only its group; an absent one instead requests an owned
renderer and publishes defaults at `0x0036F700`. Reset restores the nested alias.
Teardown clears it before environment destruction, preventing two releases of
one environment. Borrowed-default destruction preserves the renderer. Record
application changes payloads, groups and enables, without resetting viewport
or persistent 2D; draw temporarily selects each environment and restores the
previous selection. Callback content identity is not established by those bindings.

`jutsu_hit_popups_initialize` (`0x0035C1F0`) separately constructs selector-`0x200`
environment `UltimateJutsuSkillPlay+0x2B8` with an owned renderer.
`jutsu_hit_popups_draw` (`0x0035C5B0`) refreshes it from the `ANM_ougi_ca` player's
camera, submits the spark players and restores the environment without a viewport
or 2D reset. Skill-play destruction releases that environment. These states are
additional to the main streamed scene and its borrowed renderer.

### Interaction-region state lifetime

`interaction_manager_init` reaches `cutin_construct` (`BTL.BIN:0x0086ECF0`),
which constructs two regions at controller `+0x450/+0x610`, stride `0x1C0`.
`cutin_region_construct` (`0x0086EF80`) calls `interaction_region_construct`
(`0x0086D1A0`). Each region owns four embedded environments and four separately
allocated, constructed and registered renderers; the two regions own eight
states in total.

| Region environment / renderer slot | Submission role | Viewport / explicit 2D setter calls |
| --- | --- | --- |
| `+0x90 / +0xCC` | Cropped masks, then optional authored players | `0x0086D858 / 0x0086D888`, then `0x0086DB50 / 0x0086DB8C` |
| `+0xD0 / +0x10C` | Optional border with full-frame viewport | `0x0086DCA8 / 0x0086DCD8` |
| `+0x50 / +0x8C` | Subsequent cropped masks | `0x0086DFEC / 0x0086E028` |
| `+0x10 / +0x4C` | Optional tiles, width 512 and derived Y interval | `0x0086E6D0 / 0x0086E704` |

All five explicit setters use zero rotation and offsets, pivot `(256,192)`.
For `q=region+0x188`, `+0xCC` first receives scales `q/q`, then
`region+0x164*q / region+0x168*q`; `+0x8C` receives that latter pair;
`+0x10C` receives `q/q`; tiles receive `1/1`. These replace the earlier viewport
reset within the same draw. The tile routine's raw zero inputs contradict its
decompiler's reused temporary for rotation/offsets.

Optional players submit under environment `+0x90` after its second publication.
An own-camera player therefore copies that cropped viewport and current 2D
matrix into its scoped renderer. `interaction_region_draw` restores the previous
environment at `0x0086E20C`, after optional tiles, without restoring any renderer
viewport or matrix. Region reset disables the child/index while retaining the
environments. `cutin_destruct` destroys both regions through
`interaction_region_destroy` (`0x0086EEA0`), which releases/unlinks their eight
owned renderers. Geometry and crop purposes belong to
[Auxiliary interaction regions](draw_2d_owners.md#auxiliary-interaction-regions).

### Draw-environment selection and streamed exceptions

Ordinary engine paths select the primary environment after creation and before
normal update return. The optional early-callback path selects the second display
environment after the callback, gated by clear low frame-gate bits and callback
presence. Finish-update selects that display environment before draw/drain work,
with the selection outside the low-bit gate. Recovery-callback dispatch selects
it immediately before a present callback when recovery state is nonzero. Destroying
the active environment selects the primary environment before owned-renderer
release. These behaviors establish the ordinary direct-selector paths; inline
stores and other attachments are not exhaustively covered.

`ccs_play_submit_scene` uses a streamed scene distinct from the object-animation
player above. It saves both environment globals, selects that scene's render/light
and draw environments, builds its camera and refreshes the selected environment's
existing renderer. `ccs_submit_play_entry` selects each group's environment and
submits model (`0x0100`) and textured-effect (`0x0E00`) nodes. It leaves the last
environment selected; `ccs_bind_environment_groups` likewise has no local restore.
Group/list argument recovery remains imperfect, although the field relationship
is established by instructions.

After group work and the optional callback, the streamed wrapper selects its
auxiliary 2D environment only when nonnull, draws the trailing 2D records, then
restores both saved globals. It performs no renderer construction, full-state
copy or renderer-pointer substitution. Streamed scheduling and resource ownership
remain with [Scene playback owners](../scene_playback_owners.md).

`ccs_play_decode_worker` (`0x001CE410`) supplies `primary_draw_environment`
(`0x00609160`) and a null render/light state to `ccs_build_play_runtime_table`
(`0x001A0B80`). The setup retains that caller environment at scene `+0xF4`,
unless a default `0x1700` descriptor creates an environment borrowing its renderer.
Each materialized `0x1700` resource environment and the optional `+0x10C`
environment for `0x1C00/0x1D00` also receives the main environment's renderer
pointer. Those setup branches perform no viewport or 2D reset. Scene `+0x110`
holds separate supplied or allocated render/light state, not a renderer allocation.

`ccs_play_group_insert` (`0x001A21B0`) groups targets by environment pointer
equality. Targets use their descriptor-linked environment when supplied, otherwise
the main one; group creation changes no renderer state. Default/resource projection
controllers separately retain the main renderer pointer. Thus a later group
environment's renderer substitution does not also replace the projection
controller's slot. The decode worker's begin callback runs after setup and can
make further publications; the inspected Ultimate Jutsu callback path is mapped
above. Environment count alone therefore overstates renderer count in the initial
streamed binding graph.

### Lazy camera publication into existing environments

`lazy_camera_publish_environment` refreshes the supplied environment's existing
renderer from `LazyCameraHolder.player.camera` when the holder exists. It does
not fetch or select `LazyCameraHolder.renderer`.

`lazy_camera_get_renderer` (`0x00376BC0`) instead returns the holder's renderer
or null, without camera publication or environment selection.
`hud_shared_icons_bind` (`BTL.BIN:0x006B83A0`) supplies this result to its alternate
layer's registration: a nonnull holder renderer is borrowed; null creates an
independently owned renderer. Its main layer borrows `default_renderer`. Getter,
camera publication and draw-time environment selection are distinct operations.

| BTL routine, live entry | Selection and restoration contract |
| --- | --- |
| `camera_publish_optional_player`, `0x006B4D00` | If the first owned player exists, select the shared environment, publish the holder camera, optionally advance/evaluate the player, draw it, and restore the saved environment. |
| `camera_publish_player`, `0x006B4DA0` | Apply the same sequence to the second owned player. |
| `lazy_camera_player_draw`, `0x0087F2D0` | When its countdown byte is zero, select its owned environment, publish the camera, optionally advance/evaluate and submit its player, then restore. A nonzero byte decrements and bypasses environment work. |

Restoring the global does not roll back the camera refresh within its renderer.
The player-camera path may subsequently bind and refresh a scoped copy. These
callers establish ordering, not a player-facing identity, character-specific
difference or reachability from every battle state.

### Particle environment overrides and nested scene cameras

`particle_manager_draw` and `particle_manager_list_draw` save the current draw
environment after the emitter's pre-draw callback. They select nonnull
`ParticleEmitter.draw_environment` for the particle loop and restore the saved
global before the post-draw callback only when both override and saved pointer
are nonnull. A saved-zero case is not unconditionally restored; its occurrence
or visible consequence is not established.

The override is read live on each selection. Its publication through base/battle
generators and `ccs_draw_generator_actions` is owned by
[Particle runtime](particle_runtime.md#battle-particle-generator-extension).

**Inference, high confidence within these paths:** an emitter's environment
reference uses that environment's current renderer slot rather than a snapshot.
The scene-copy binding stays active while `ccs_draw_generator_actions` runs.
A particle dispatch into another `projectile_compound_submit` can perform a nested
scoped substitution. Normal return restores each saved renderer pointer without
copying the inner renderer back. Particle dispatch/history remain with
[Particle runtime](particle_runtime.md#concrete-visual-update-and-draw).

## Model-to-device composition and draw scratch

`scene_object_submit_geometry` allocates a `0x280` scratch `CcsModelDrawContext`
when needed. `model_draw_parameters_setup` supplies the accumulated world
`model_matrix`, captures `draw_environment` and its `renderer`, and separately
captures the render/light environment in `draw_base`. The context is not a
persistent renderer. After ordinary/shadow work, the caller restores scratch.
Hierarchy and accumulated matrices belong to
[Model runtime](model_runtime.md#composition-hierarchy-and-matrix-lifetime).

`model_dispatch_geometry` composes
`context.device_matrix=renderer.device_projection*context.model_matrix`.
With `runtime_flags & 0x100000`, it first replaces the world basis using its XYZ
column lengths as diagonal scales times `inverse_camera_rotation`, restores
world translation and redirects `model_matrix`. Both branches then use
`device_projection`; visibility decisions belong to [Visibility](visibility.md).

`model_submit_packed_geometry` normally copies the composed draw matrix. With
nonzero `CcsModelInstance.depth_offset`, it copies `projection_only` into scratch,
replaces the depth coefficient by `B-A*delta/(z*(z+delta))`, then composes
`camera_transform` and the current world matrix. Here `delta=depth_offset` and
`z=CcsModelDrawContext.camera_depth`. Raw instruction operands establish that
this offset belongs to the model instance. Persistent projection matrices remain
unchanged. Uploads and downstream execution belong to
[Render submission](render_submission.md).

`model_part_queue_projection` also starts from `device_projection*world`, then
applies local shape scale and a remap from the device rectangle; `projection_only`
is used separately for near-plane input. It reads `CcsExtendedController.renderer`,
so a scoped swap of the active draw environment's renderer leaves that controller
slot unchanged. Scratch remapping and target size do not themselves demonstrate
another persistent renderer. Attachments, remap coefficients and target lifetime
belong to [Shadow rendering](shadow_rendering.md#geometry-inputs-and-renderer-ownership).
