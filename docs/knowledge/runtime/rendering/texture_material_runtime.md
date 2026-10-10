# Texture palette and material runtime

## Research coverage

Established: retail NA2 texture/CLUT ownership, material binding and UV updates,
draw-time resource ordering, effect frame advancement and two palette controllers.
Open: downstream VU coordinates, sampling instances and borrowed lifetimes,
RGB-controller callers/owned cleanup, scheduler units and material `+0x08`.
Names come from `@annotations/NA2`; addresses are live resident `SLPS_258.37`
addresses. Evidence is static; scheduling and visual results remain unestablished.

This document owns runtime behavior across texture, palette, material and draw
routines. The annotation comments own individual routines, layouts and packing
details; names describe demonstrated behavior rather than recovered source
symbols. Missing direct references do not exclude computed calls or other
writers, and decompiler signatures can omit inputs or merge function bodies.

Related owners: [CCS object types](../../game/files/ccs_object_types.md)
(type parsing and shared transfer groups),
[Resident CCS runtime](../../game/files/ccs_runtime.md)
(handle layers and frame payloads),
[Material draw modes and GS state](material_render_modes.md)
(ALPHA, TEST and ZBUF),
[Model runtime](model_runtime.md)
(geometry and skin conversion),
[Animation runtime](../animation_runtime.md)
(player clocks and curve ownership), and
[Render submission](render_submission.md)
(packet allocation, submission and DMA lifetime).
See [address conventions](../../game/files/file_identities.md#address-conventions).

## Texture state and palette binding

`ccs_parse_image_block` constructs an ordinary `CcsTextureChunk` through
`texture_chunk_construct`, or a `CcsSamplingTexture` through
`sampling_texture_chunk_construct` when input flags contain `0x20`.
Both use `texture_initialize_from_descriptor`. The sampling branch consumes
and discards the file pixels, forces zero extra levels and pixel format zero,
and sets flags to `(flags & ~1) | 0x58`. These are separate resource paths;
sampling preparation does not advance a texture animation.

| Resource | Object size | Annotated vtable | Preparation behavior |
| --- | ---: | --- | --- |
| Ordinary | `0x48` | `texture_chunk_vtable` (`0x005D9E90`) | Submit existing per-level transfer descriptors |
| Sampling | `0x50` | `sampling_texture_chunk_vtable` (`0x005D9E70`) | Capture the current framebuffer into texture storage |

The [type identities](../../game/files/ccs_object_types.md#confirmed-identities)
own the embedded `ccTexChunk` and `ccSamplingTexChunk` names. Vtable slots and
their concrete methods are recorded on the two annotated vtables.

`CcsTextureChunk` holds its source `record`, packed `tex0_state`,
`tex1_state`, `miptbp1_state` and `clamp_state`, optional `levels`,
`transfer_group`, dimensions, format and `clut`. Construction retains input
flags through mask `0x3D`; `draw_flags` also acquires registration/update bits.
Dimensions are `1 << width_log2` and `1 << height_log2`. Input flag `0x40`
suppresses the descriptor array; otherwise it has `extra_levels + 1` entries
of `0x20` bytes each. Input flag `0x10` selects clamp state 5, otherwise zero.

`texture_set_level_coordinates` converts each coordinate pair through
`gs_vram_texture_address`; `texture_set_level_bases` applies the result to
packed texture state and each transfer descriptor's base fields. Descriptor
updates preserve their high two bits. Width halves at each successive level.
The inspected packed-state branches handle levels 0 through 3; they do not
establish validation for arbitrary level counts.

Texture `flags` has separate ownership bits: 1 owns the descriptor array,
2 marks transfer-group attachment, and 4 owns the palette. Construction clears
all three before claiming its allocated array.
`texture_copy_binding` shallow-copies the backing resources and state but
clears those bits. `sampling_texture_copy` also clears sampling `+0x48`.
Copies therefore borrow the same backing resources; a particular caller's
retention time is not established.

`clut_initialize_base` initializes `CcsClut.tex0_state` to
`0x2000000000000000`, clears transfer/group bindings and delegates storage
construction to `clut_initialize_from_descriptor`.

| Palette format | Storage dimensions | Transfer descriptors |
| --- | --- | ---: |
| `0x13` | `16 × 16` | 1 |
| Other inspected formats | `8 × 2` | 1 |

[CLUT parsing and CSM1 ordering](../../game/files/ccs_object_types.md#confirmed-identities)
remain owned by the type document.

`texture_chunk_destroy` unregisters `draw_flags & 0x80`, destroys only an
owned palette, frees only owned descriptors and unlinks an attached transfer
group. `sampling_texture_destroy` delegates that cleanup.
`clut_set_base` updates both the palette transfer and its packed state;
`texture_get_composed_state` ORs the current palette state into texture state
at lookup time. Palette state is not duplicated into `CcsTextureChunk.tex0_state`.

## Material binding and coordinate updates

`CcsMaterialDescriptor`, parsed by `ccs_parse_material`, is separate from
the `0x1C`-byte `CcsRenderMaterial`.
`ccs_finalize_secondary_values` constructs render materials through
`ccs_materialize_secondary_object` and `ccs_material_bind_texture`, then
publishes them as the source record's `secondary` value. Its primary
`runtime` value remains the parsed descriptor
([CCS handle layers](../../game/files/ccs_runtime.md#handle-layers)).

Binding copies the descriptor's alpha and coordinate fields. An absent
descriptor defaults to alpha 1, offsets 0 and scales `0x1000`.
The descriptor's `texture_record.runtime` supplies the texture; sentinel 4
is treated as absent. `ccs_effect_bind_texture` installs the texture and
overwrites the cached `clut` with its current palette, or zero for an absent
texture. It and `material_copy_binding` clear material `+0x08`, whose
meaning remains unresolved.

Rebinding has a different cache rule. `model_rebind_part_textures`,
`model_rebind_material_textures`, `effect_child_rebind_texture` and
`effect_descriptor_rebind_texture` replace the selected texture but replace
the cached palette only when `texture_get_clut` returns neither zero nor
sentinel 4. An absent new palette therefore leaves the old cached palette.
This rule applies to those inspected consumers, not every binding API.

`model_dispatch_geometry` multiplies material `alpha` by
`CcsModelDrawContext.alpha` and publishes `material_alpha` for each part.

Streamed material command `0x0201` (`ccs_frame_tag_0201`) reads six optional
floats in retail version `>= 0x120` and resolves a pointer vector with a
signed halfword count. Every nonzero material receives these low-16-bit
fixed-point values, where 4096 represents 1.0:

| Material field | Value from inputs |
| --- | --- |
| `u_offset` | `(a + e*c) * 4096` |
| `v_offset` | `[1 - ((1-f)*d + (1-b))] * 4096` |
| `u_scale` | `c * 4096` |
| `v_scale` | `d * 4096` |

The inputs `a,b,c,d,e,f` are in reader order and default to `0,1,1,1,0,1`.
The four annotated material setters store halfwords only; this command does
not upload pixels or palette colors.
[Stream frame payloads](../../game/files/ccs_runtime.md#frame-payloads)
own reader framing and masks. The packed snapshot parser uses bits
`1..0x20`, whereas this consumer reads under `2..0x40` without shifting
the flags. Only the all-fields form, flags zero, avoids that one-bit mismatch
([Packed material snapshot masks and cursor ownership](../../game/files/ccs_runtime.md#packed-material-snapshot-masks-and-cursor-ownership)).

Packed key command `0x0202` (`ccs_apply_packed_frame_command`) evaluates
six curves through `animation_scalar_evaluate` and uses the same formulas.
Its first five curve defaults are zero and its sixth is one. It applies the
setters to every pointer in its signed-count vector without the streamed
branch's per-material null check.

### Model UV consumption

The non-flag-4 routes of `model_dispatch_geometry` compare current material
scales with the initial descriptor scales as signed halfwords. A non-unit
fixed-point ratio reaches `material_rewrite_uv_pairs`, which obtains source
and destination arrays through `model_prepare_writable_uv`:

```text
ratio_u = initial_u_scale == 0 ? 4096 : (current_u_scale << 12) / initial_u_scale
ratio_v = initial_v_scale == 0 ? 4096 : (current_v_scale << 12) / initial_v_scale
u_out = ((current_u_offset << 12) + 2048 + ratio_u * ((u_in << 4) - initial_u_offset)) >> 12
v_out = ((current_v_offset << 12) + 2048 + ratio_v * ((v_in << 4) - initial_v_offset)) >> 12
```

Inputs and outputs are signed halfwords; integer division and arithmetic
shifts precede low-halfword stores. A successful rewrite sets
`CcsModelDrawContext.uv_modified`. `model_build_part_packet` then emits
zero offset modifiers, avoiding a second offset application. Without the
rewrite it emits material-minus-descriptor offset differences.

The flag-4 route, `model_submit_packed_geometry`, sends
`(current_offset - initial_offset) & 0xFFF` for both axes to VU slot
`0x14`, with unit scale words. That packet does not read the material scale
fields. Its complete downstream VU interpretation remains open. Both routes
prepare textures and separately cached palettes; this evidence does not make
their scale handling equivalent. Geometry selection and array ownership
belong to [Model runtime](model_runtime.md).

## Draw-time resource and state consumers

Resource preparation precedes drawing: texture virtual preparation comes
first, then a separate cached CLUT transfer through `image_transfer_submit`,
then texture/CLUT state in the draw packet. Blend/test state is independent of
those resources. Descriptor gates and group suppression belong to
[shared image-transfer groups](../../game/files/ccs_object_types.md#runtime-tag-0x1000-from-texture-and-clut-construction-image-transfer-group).

| Bounded consumer | Resource/state contract |
| --- | --- |
| `render_prepare_bound_texture` | Uses the current context texture; caller flags independently gate texture and palette preparation. |
| `render_begin_draw_packet` | Textured flags `& 0x180` prepare resources unless suppressed; emits TEX0 as texture OR palette, texture TEX1/MIPTBP1/CLAMP, and zero TEXFLUSH. |
| `particle_sprite_submit` | Uses draw `texture` and separately cached `clut`; missing texture zeros all four texture registers. A cached palette is used instead of rereading texture `clut`. |
| `render_context2_textured_rectangle` | Prepares its texture/cached palette before drawing and uses context-two texture registers. |
| `sprite_glyph_initialize` | Caches composed TEX0 and filter state; optional retention keeps texture/palette pointers in `SpriteTextureBindingView`. |

`particle_sprite_submit` computes integer alpha as
`int(draw.alpha * frame.alpha) >> 5`, skips values below 1 and caps at 255,
then writes packed color plus alpha to register `0x01`.
ALPHA, TEST, ZBUF and opaque/list-order decisions are owned by
[Material draw modes and GS state](material_render_modes.md#shared-draw-context-and-state-composition)
and its
[bounded callers](material_render_modes.md#mode-propagation-and-bounded-direct-callers).

## Effect texture frames

A `0x0E00` effect has one texture binding and a separate table of
`CcsEffectFrame` entries. `ccs_parse_effect` allocates
`0x34 + frame_count*8` bytes.
`ccs_effect_child_bind_descriptor` copies `frames`, `frame_count` and
`packed_dimensions` into `CcsEffectDrawDescriptor`, together with the
texture and cached palette. Frame selection changes the table entry consumed
by drawing, not the texture or palette binding.

Each eight-byte entry supplies `u`, `v` and `alpha` halfwords.
`particle_sprite_submit` emits the coordinates, packed dimensions and the
source descriptor's four `coordinate_parameters` floats into the VU packet.
Their full downstream coordinate interpretation is unresolved.
The source `projection_offset` is constructed from a signed halfword,
divided by 256 for version `>= 0x122`, copied to the draw descriptor and
consumed in projection calculations.

Source `flags` bit 5 sets draw `draw_state` bit 1 (repeat), bit 6 selects
the primitive, and the low three bits select the blend through
`effect_descriptor_set_blend`. Its GS state is owned by
[Material draw modes and GS state](material_render_modes.md#mode-propagation-and-bounded-direct-callers).

### Frame state and advancement

`ccs_effect_child_initialize` creates a `CcsEffectScene` with an embedded
draw descriptor, type `0x0E00` and frame zero.
`effect_request_restart` arms it with `0xFFFE`;
`effect_stop` writes `0xFFFF` and updates alpha/flags.
`effect_step_frame` follows this contract:

| Current frame/result | Result of a step |
| --- | --- |
| `0xFFFF` | Returns -1 without changing the frame |
| `0xFFFE` | Stores `delta - 1` |
| Ordinary frame | Adds the delta's low halfword and stores a halfword |
| Stored result below `draw.frame_count` | Retains and returns that result |
| Stored result at or beyond count | Stores zero with repeat (`draw.draw_state & 2`), otherwise `0xFFFF` |

The comparison is unsigned. Repeat discards overshoot rather than taking a
modulo, and stepping consumes no rate scalar.

The inspected draw owners use `ccs_effect_child_update`: despite its retained
name, it draws only frames below `0xFFFE` and does not advance them. It refreshes
the scene transform, multiplies caller alpha by scene/hierarchy alpha, and
submits through `effect_submit_transformed` and `particle_sprite_submit`.
A separate `effect_draw_and_step` draws and increments, but its caller remains
unestablished.

Two update paths establish frame advancement:

- Streamed object command `0x0101` (`ccs_frame_tag_0101`) may arm the effect
  on alpha/position conditions, then steps by 1 before storing its new
  transform and alpha.
- Packed player `animation_advance_position` evaluates typed keys first.
  When the integer part of its fixed-point clock changes, it advances every
  bound `0x0E00` child by that integer difference before dispatching crossed
  packed commands.

Draw-call count therefore does not establish effect-frame count.
Player clocks, command crossing and binding ownership belong to
[Animation runtime](../animation_runtime.md#advance-and-end-behavior).

## Palette changes and lifetime

Two resident controllers change palette color words independently of texture
selection.

### Reflected entry-range motion

`PaletteReflectionController` borrows a palette and its writable colors,
owns a snapshot, and tracks a float accumulator/increment, integer shift,
half-open range, repeat flag and completion byte. Initialization sets repeat
and clears completion; binding selects the full palette range.
`palette_reflection_set_range` and `palette_reflection_set_clock` replace
the range and float controls.

`palette_reflection_step` first rewrites every selected destination from the
snapshot, reflecting the shifted source index at the range ends. For 256
colors it maps both indexes through `clut_csm1_permutation`
(`0x003FB720`); smaller palettes use direct indexes. The reflection loop
allows five correction attempts before a trap.

After color writes, the step adds the float increment. Only an accumulator
strictly greater than 1.0 advances the shift once and subtracts 1.0 once.
Thus even an increment above one produces at most one shift per call.
At twice `range_length - 1`, repeat wraps the shift by that amount;
otherwise completion becomes one and later calls skip the controller.
The step itself does not submit a transfer.

`palette_reflection_wrapper_initialize` resolves a named record in
`PaletteScriptOwnerView.container`, reads four scalar arguments after the
name, configures the controller and attaches the wrapper to the selected
owner list. `palette_reflection_wrapper_update` sets the controller increment
to `wrapper.increment * owner.update_scalar` before stepping.
The units of that owner scalar and the scheduler's full calling frequency
remain open.

`palette_reflection_wrapper_vtable` (`0x005DD280`) names those methods and
`palette_reflection_wrapper_destroy`. Destruction restores the snapshot
through `palette_reflection_restore`, frees the snapshot/controller and
delegates wrapper cleanup. The palette remains borrowed.

### RGB-table interpolation

`palette_rgb_initialize` creates a `PaletteRgbController` that borrows
palette pixels when present. Otherwise it constructs a new `0x28`-byte CLUT
at the original palette base and allocates storage, retaining that owned CLUT.
The color count is the palette width-times-height halfword; the controller
owns original and target tables and copies the input vector.

`palette_rgb_target_color` forms a weighted source RGB sum with the three
`palette_rgb_weights` coefficients (`0x005D6260`), then multiplies it by
the controller's red, green and blue multipliers. Source alpha is preserved.
`palette_rgb_rebuild_target` regenerates the target table.
`palette_rgb_interpolate` applies
`original + t*(target-original)` to each RGB channel, preserving original
alpha without clamping `t`. For an owned CLUT with a descriptor it calls
`image_level_submit_pixels` after every color store, inside the entry loop.
Borrowed storage receives no immediate submission from this helper.

`palette_rgb_restore` destroys an owned CLUT before copying original colors
back through the retained color pointer, then frees both tables. The intended
validity of that copy in the owned branch remains unresolved.
Caller ownership and reachability remain unresolved within the inspected
resident/BTL/ETC scope. Computed calls and unexamined owners remain possible;
the bounded negative evidence is recorded on `palette_rgb_initialize`.

## Sampling texture resource consumer

`sampling_texture_capture` (`0x0019DCD0`) returns immediately when
`EnginePadContext.display_width` exceeds 512. Otherwise it halves the
display width and height separately until each fits the texture dimensions,
then draws the current framebuffer into the texture's composed destination
state. It has no time counter or frame-index advancement.

`sampling_build_transfer_state` derives the destination framebuffer and
scissor state from the composed texture state and writes the source texture
state. `sampling_draw_rectangles` emits the rectangles; the sampling caller
uses zero flags and color `0x80808080`. The packet is inserted into the
supplied draw chain
([Render submission](render_submission.md) owns allocation and chain lifetime).

Ordinary `texture_chunk_submit_levels` instead submits the existing
`extra_levels + 1` descriptors when `levels` is present. The same virtual
preparation interface therefore has two different resource behaviors.
Construction and copying clear sampling `+0x48`; no other
producer or consumer of that additional field is established here.

The asset evidence establishes local `TEX_sampling00` and `TEX_sampling01`
definitions in `CMN/EFFECT0X.CCS` and a startup load set containing that file.
[Locally filled external-marker rows](../../game/files/asset_dependencies.md#locally-filled-external-marker-rows)
and [Common providers and battle preparation](../../game/files/asset_dependencies.md#common-providers-and-battle-preparation)
own that evidence. It establishes available definitions, not which draw
instances use each named resource.
