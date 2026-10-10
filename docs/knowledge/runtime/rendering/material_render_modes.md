# Material draw modes and GS state

Native material draw-mode selection, ALPHA/TEST/ZBUF composition and restoration,
and material packet contracts in retail NA2 (`SLPS-25837`).

## Research coverage

Established: independent GS-state inputs, model/effect blend selection, ordinary
and packed material contracts, optional-pass gates and bounded restoration.
Names come from `@annotations/NA2`; comments and types hold code-level detail.
Evidence includes eight model headers and four packed VU state kicks.
Open: whole-roster modes, indirect/other-overlay callers, every continuation's
state history, optional-pass names/reachability and visible outcomes.

Related owners: [Texture and material runtime](texture_material_runtime.md)
(resource binding and UV updates), [Model runtime](model_runtime.md)
(geometry and skeletons), [Model VU programs](model_vu_programs.md)
(microprogram arithmetic), [Render submission](render_submission.md)
(allocation, ordering and DMA lifetime), and [Shadow rendering](shadow_rendering.md)
(off-screen targets and compositing).

## Evidence conventions

All cited addresses are live resident `SLPS_258.37` EE addresses; see
[address conventions](../../game/files/file_identities.md#address-conventions).
Names describe demonstrated behavior, not recovered retail source symbols.
Static inspection establishes emitted values and ordering, not visible results.
The embedded VU streams are distinct from the resident program's EE instructions;
their annotation comments preserve the raw-word evidence and separate decoding.

## Shared draw context and state composition

`render_compose_gs_state` (`0x0010C7A0`) composes `RenderGsState` from the shared
`StartupRenderState`. This context, `CcsRenderMaterial`, and
`CcsModelDrawContext` are separate allocations with separate field meanings.
Interpolation, texture-coordinate mode, destination-alpha testing, depth
comparison and depth-write masking are independent of the blend index.

| Shared field | Composition |
| --- | --- |
| `blend_selector` | Indexes `model_blend_states` without a local range check. |
| `frame_mask` | FRAME high word; the display supplies its low word. |
| `interpolation` | Shifted left 3 into primitive attributes. |
| `antialias` | Shifted left 7 into primitive attributes. |
| `bound_texture`, `texturing_enabled` | A texture adds primitive `0x10`; selector zero gives software flag `0x80`, otherwise primitive `0x100` and software flag `0x100`. |
| `depth_comparison` | Zero selects TEST `0x30000`, otherwise `0x50000`. |
| `destination_alpha_test` | Nonzero adds `0x4000` and `((value-1)&1)<<15` to TEST. |
| `depth_writes` | Zero adds ZBUF bit 32; otherwise the display-derived base/format is retained. |

Primitive attributes start at `0x40`. `RenderGsState` holds reserved zero,
blend, TEST, primitive attributes, FRAME, ZBUF and software texture flags.
`display_get_frame_word` selects the display's `primary_frame` when
`frame_bank` is nonzero, otherwise `alternate_frame`, keeping the low 32 bits.
ZBUF uses signed `depth_base / 32`, truncated toward zero, and
`(depth_format & 0xF)<<24`. Model producers instead consume the display's
already composed `zbuf_state`.

`render_begin_draw_packet` (`0x001830A0`) merges the software texture flags
with the requested draw flags and emits FOGCOL, ALPHA_1, TEST_1, ZBUF_1 and
FRAME_1. Textured packets also emit TEXFLUSH, TEX0_1, TEX1_1, MIPTBP1_1 and
CLAMP_1. Allocation failure clears the current scratch state; no partial draw
is constructed. Resource preparation belongs to the texture owner.
GS register meanings follow
[PS2SDK's GS register definitions](https://github.com/ps2dev/ps2sdk/blob/master/common/include/gs_gp.h).

### Reset and texture sampling contributions

`render_reset_state` clears the blend selector, FRAME mask, texture pointer,
interpolation, destination-alpha test, depth comparison, depth writes and
antialias state regardless of its reset mask. Mask bit `4` additionally clears
`texturing_enabled` and `tex1_sampling`, then installs MMAG `1`, MMIN `5`,
L `0` and K bits `0xF18` through `render_set_tex1_filter` and
`render_set_tex1_lod`. These values are constructed defaults.

| Producer | TEX1 composition |
| --- | --- |
| `render_begin_draw_packet` | Texture `tex1_state` alone. |
| Ordinary and packed model packets | Texture `tex1_state` OR model-context `tex1_sampling`; setup retains only shared `0x00000FFF001801C0` (MMIN, L and K, excluding MMAG). |
| `particle_sprite_submit` | Texture `tex1_state` OR the full shared `tex1_sampling`. |

The shared setters store truncated values: `render_set_option114` selects the
blend, `render_set_depth_writes` and `render_set_depth_comparison` control
depth, `render_set_frame_mask` supplies the full mask, `render_set_texturing`
selects texture-coordinate mode, and `render_set_interpolation` supplies the
primitive interpolation byte. They do not impose a common boolean interface.

`font_draw_text` resets with mask zero, selects TEST through
`FontDrawState.render_flags` bit 7, selects texture-coordinate mode one and
uses `FontDrawState.blend_selector`. It repeats the setup after its embedded
callback. The draw/list environment and scratch cursor are saved/restored,
while shared draw state is replaced. The bound font texture owner is
`font_texture_owner`. Font geometry and metrics belong to
[Font renderer metrics](../../localization/font/renderer_metrics.md).

## Blend selection and model state producers

The inspected prefix of `model_blend_states` (`0x005B5940`) contains:

| Index | Packed ALPHA value | `(A,B,C,D,FIX)` |
| --- | --- | --- |
| 0 | `0x44` | `(0,1,0,1,0)` |
| 1 | `0x48` | `(0,2,0,1,0)` |
| 2 | `0x42` | `(2,0,0,1,0)` |
| 3 | `0x09` | `(1,2,0,0,0)` |
| 4 | `0x54` | `(0,1,1,1,0)` |
| 5 | `0x58` | `(0,2,1,1,0)` |
| 6 | `0x52` | `(2,0,1,1,0)` |
| 7 | `0x64` | `(0,1,2,1,0)` |
| 8 | `0x68` | `(0,2,2,1,0)` |
| 9 | `0x62` | `(2,0,2,1,0)` |
| 10 | `0x00000080000000A4` | `(0,1,2,2,128)` |

This prefix does not establish the complete table extent or public selector
range; the following bytes contain addresses. Numeric selectors have no
established player-facing names.

`model_instance_set_blend` (`0x001987A0`) copies the selected word into
`CcsModelInstance.blend_state` after masking the selector to eight bits, without
a local bounds check. Selectors 0 and 4 clear `draw_state` bit 0 and select
TEST low state `0x100B`; every other selector sets the bit and selects
`0x1001`. `model_instance_set_test` provides independent changes:

| Helper selector | TEST update |
| --- | --- |
| 0 | Clears bit 16, then ORs supplied value shifted left 16. |
| 1 | Clears low four bits and bits 12..13; ORs `0x100B` for nonzero value or `0x1001` for zero. |
| 2 | Clears bits 14..15; ORs `0x4000` and supplied value shifted left 15. |

Only helper selector 1 normalizes its value to a boolean branch. These masks
do not establish a malformed-input interface contract.
`ccs_model_instance_initialize` starts TEST at `0x50000` and clears
`draw_state`, then applies `CcsModelDescriptor.blend_selector`: defaults are
`0x5100B` for selectors 0/4 and `0x51001` otherwise.
`model_instance_pack_blend` separately packs supplied ALPHA fields and sets
`draw_state` bit 0 without changing TEST.

`model_draw_parameters_setup` and `model_draw_parameters_setup_variant`
snapshot the draw environment, renderer, shared draw base, three optional pass
owners and alpha into `CcsModelDrawContext`. Primitive state starts at `0x2C`
with an antialias contribution in bit 7; sampling is masked as above.
`model_copy_instance_draw_state` supplies runtime flags, draw state and scale;
`model_dispatch_geometry` separately copies the instance's blend and TEST
states. A shared draw-state reset does not undo persistent model setters.

### Bounded retail model-header sample

`ccs_parse_model` takes the low two bits of `CcsModelFileHeader.draw_modes` as
`CcsModelDescriptor.blend_selector`. Higher bits have separate conversion and
draw-dispatch roles owned by the model/VU documents. All eight sampled retail
headers—the six body models, the `2NRTBOD1.CCS` weapon and
`PL/1NRTBOD1.CCS`'s `MDL_1nrt00t0 eye1`—give initial selector 0 despite
differing higher bits; see
[Model VU programs](model_vu_programs.md#representative-retail-body-payloads).
This sample does not establish all-resource distribution or later runtime
selector values.

## Ordinary per-material packets

`model_dispatch_geometry` (`0x001910E0`) calculates
`material_alpha = CcsRenderMaterial.alpha * CcsModelDrawContext.alpha` for each
ordinary part and ordinarily skips values below `1/128`. With no optional
passes it forms separate direct and ordered chains:

| Condition | Chain |
| --- | --- |
| Alpha below `127/128`, `draw_state` bit 0 set, or texture `draw_flags & 8` | Ordered. |
| Otherwise | Direct, with material alpha set to exactly `1.0`. |

Optional passes use one chain, marked for ordering when any included part
requires it. Local pass bit 1 can bypass the later per-part alpha skip; it
cannot bypass the whole-model alpha gate.

`model_build_material_vif_setup` (`0x00192740`) emits eleven A+D pairs followed
by VU parameters and an entrypoint. Their ordered contract is:

| Register | Value |
| --- | --- |
| TEXFLUSH | Zero. |
| CLAMP_1 | Texture `clamp_state`; NOP register without a texture. |
| TEX0_1 | Texture state combined with separately cached CLUT; NOP without a texture. |
| MIPTBP1_1 | Texture `miptbp1_state`; NOP without a texture. |
| TEX1_1 | Texture `tex1_state` OR context `tex1_sampling`; NOP without a texture. |
| ALPHA_1 | Context `blend_state`. |
| TEST_1 | Composed TEST. |
| ZBUF_1 | Display-derived depth state. |
| FOG | Context `fog_value` shifted left 56. |
| FOGCOL | Context `fog_color`. |
| PRIM | Context primitive attributes with the material contribution. |

Model flag `0x400` suppresses the texture. A texture adds primitive `0x50`;
without one, bit `0x40` is added only when alpha differs from `1.0`.
With `draw_state` bit 0 clear, TEST gains
`int(texture.alpha_reference * material_alpha)<<4` by OR, preserving any
existing reference contribution; no local eight-bit clamp is visible.
If TEST bit 16 is clear, bits 16..18 become `0x30000` and ZBUF bit 32 is set.
Otherwise TEST and the display depth state are retained. Disabled depth thus
becomes an always-pass depth test with writes masked. Texture and VU selection
remain with their linked owners.

## Packed material packets and selection asymmetry

`model_submit_packed_geometry` (`0x0018FFB0`) emits one ALPHA/TEST/ZBUF/fog block
for the chain. The **first part's material** determines its alpha, texture TEST
reference and final direct-versus-ordered decision. Ordinary drawing makes
these decisions separately for each material.

Each packed part still supplies its material VU parameters. A material pointer
that differs from the previous part and has a texture uploads six pairs:
TEXFLUSH, TEX0_1, TEX1_1, MIPTBP1_1, CLAMP_1 and PRIM with primitive `0x50`.
The other branch uploads only PRIM with primitive `0x40`.

### Fixed GIF count and retained texture state

The initial upload installs a GIF header with **NLOOP eleven**, five state
pairs and six NOP-register pairs. Per-part uploads replace those last six slots
without installing a second header. A long upload replaces all six; a short
upload replaces only the first, retaining the last five and the eleven-pair
count. The fixed layout and command words are in the producer annotation.

Four representative embedded streams—`model_vu_upload_025` (`0x003C86C0`),
`model_vu_upload_024` (`0x003C9580`), `model_vu_upload_033` (`0x003CA210`) and
`model_vu_upload_032` (`0x003CADD0`)—kick the full state packet without
intervening state-slot stores. Their label comments hold the decoded evidence.

**Bounded inference:** after a long textured upload, a short upload retains the
later textured PRIM write among those last five slots. Consumption of the
fixed eleven-pair packet applies it after the short branch's PRIM. A first
short upload instead retains initialized NOPs. This establishes register-write
order, not every continuation's state history, a visible result, or safety of
arbitrary textured/untextured sequences.

## Optional material pass contracts

Optional owners are independent of the current material.
`model_dispatch_geometry` builds its local pass mask before ordinary/packed
selection, after rejecting whole-model alpha below `1/128`:

| Local bit | Gate | Packet family |
| --- | --- | --- |
| `1` | Model flag `0x80`, nonnull `extra_pass_descriptor`, its `enabled` nonzero. | Ordinary `model_submit_ordinary_extra_pass`; packed `model_submit_packed_extra_pass` / `model_build_packed_extra_pass`. |
| `2` | Model flags `&0x805 != 0` and `&0x8000 != 0`, `descriptor_pass_owner.enabled != 0`, and its `texture` nonnull. | Ordinary `model_build_packet`; packed `model_build_packed_descriptor_pass`. |
| `4` | Model flag `0x100`, nonnull `context2_owner`, its `enabled` nonzero. | Context-two rectangle and clear. |

These numeric gates do not establish authored effect names.
Descriptor-pass producers use `CcsDescriptorPassOwner` texture/CLUT, blend and
TEST selectors with the selected working owner:

| Producer / block | ALPHA | TEST | Depth writes |
| --- | --- | --- | --- |
| `model_build_packed_descriptor_pass` (`0x0018F610`) | Descriptor's `model_blend_states` entry. | Selector zero: `0x50000`; otherwise `0x53001`. | Display ZBUF without added mask. |
| `model_build_packet` (`0x0018F900`), first | Current model blend. | Ordinary reference/depth rule. | Ordinary rule. |
| `model_build_packet`, second | Descriptor's blend entry. | Selector zero: `0x51001`; otherwise `0x53001`. | ZBUF bit 32 set. |

Both descriptor blocks use masked model sampling, PRIM's low three working bits
OR `0x50`, and RGBAQ from owner `color` plus `int(owner.alpha*128)<<24`, Q `1.0`.
Flag `0x20000` also multiplies this alpha by `material_alpha`.
The packed descriptor producer can replace five texture registers with NOPs;
the ordinary second block dereferences the texture directly. The differing
zero-selector TEST defaults and depth masks are separate producer contracts.

### Extra model-owned blend state and FRAME restoration

`CcsModelInstance.extra_pass_owner` supplies an independent blend state; absent
owners use `model_blend_states[0]`. `model_extra_pass_set_blend` changes only
that owner's blend. The constructor creates an owner when flags `&0x84 != 0`
and none was supplied, initializing its width multiplier, low-24-bit color
and blend from `CcsModelDescriptor.extra_pass_width`, `extra_pass_color` and
`extra_pass_selector & 3`. This choice is separate from ordinary model blend.

`model_submit_ordinary_extra_pass` (`0x001C3DA0`) and
`model_build_packed_extra_pass` (`0x001C3A20`) emit eight state pairs:
TEST `(context.test_state&0xC000)|0x50000`, display ZBUF without an added mask,
PRIM `(context.primitive_state&7)|0x40`, and FRAME with display low word and
high mask `0xFF000000`, protecting alpha while permitting color writes.

The ordinary producer places its state ahead of the part chain and a FRAME
reset after the supplied geometry tail. The packed producer, through
`model_submit_packed_extra_pass`, brackets all packed parts with the same
state/reset contract. Both resets use the selected display FRAME low word and
**high mask zero**. They restore a known display configuration, without saving
an arbitrary preceding mask. Other GS state written by the extra pass has no
corresponding restoration packet in these producers.

`model_extra_pass_parameters` supplies color, width and alpha. Color sentinel
`0x80000000` selects model-owner color or zero. Owner `width_multiplier` scales
width, and `enabled` bit 0 controls adjustment below the descriptor's
`minimum_projected_width`. Alpha starts at descriptor `alpha * 128`; flag
`0x40000` multiplies it by material alpha. Ordinary width is normalized by
`uniform_scale*64` unless flag `0x1000` is set; packed drawing uploads width
and width/64 separately. The shared ALPHA/TEST/FRAME composition is unchanged.

### Context-two composition and alpha clearing

`render_context2_textured_rectangle` (`0x0018E9F0`) uses selected display
FRAME_2, masked depth writes, centered XYOFFSET_2, camera SCISSOR_2, FBA_2 zero
and descriptor texture state. TEST_2 is `0x71001`; ALPHA_2 uses
`CcsContext2Descriptor.blend_selector` to index `context2_blend_states`
(`0x005BEEA0`). Its four inspected entries are `0x54`, `0x58`, `0x52`, `0x52`;
`model_vu_descriptors` follows. The unchecked eight-bit index does not establish
a public accepted range. Missing texture or computed alpha below one returns
before allocation.

`render_context2_clear_alpha` (`0x0018F160`) uses display `color_base` and
`width` with FRAME_2 mask `0x00FFFFFF`, protecting RGB and permitting alpha
writes. XYOFFSET_2, FBA_2, TEST_2 and RGBAQ are zero; ALPHA_2 uses ordinary blend
entry zero. SCISSOR_2 is raw `0x0FFF00000FFF0000`, with effective eleven-bit
endpoints `0..2047`; the raw twelfth endpoint bit is padding. The annotation
records the supporting PCSX2 register definition. These are constructed
defaults, not saved GS words.

| Model path | Context-two order |
| --- | --- |
| Ordinary | Textured rectangle, optional chain, alpha clear. |
| Packed | Alpha clear, optional chain, textured rectangle. |

Neither order establishes restoration of all preceding context-two state.

## Scoped CPU state and restoration boundaries

`sp_skill_play_draw` (`0x0035C110`) temporarily substitutes
`active_render_descriptor` and `model_extra_pass_descriptor` from asset-owned
pass blocks around `sp_skill_draw_scene_entries`, then restores both pointers.
Model setup snapshots these owners into the working context, so packets retain
selected owners after the globals are restored for later producers.

`projectile_compound_submit` (`0x001BB790`) temporarily substitutes a camera
renderer ([renderer coordinates](renderer_coordinates.md#refresh-and-binding-order)).
When `CcsAnimationDescriptor.lighting_color` differs from `0x80000000`, it also
saves shared lighting through `render_get_packed_lighting_color`, overrides
it, and restores it through `render_set_packed_lighting_color` and
`packed_color_to_weighted_rgb`. The packed save converts shared RGB floats
multiplied by 255 to integers; restoration converts the packed representation
back. It is not an exact float snapshot. The shared `scene_traversal` pointer
is set for traversal and cleared afterwards without saving a previous pointer.

`scene_object_submit_geometry` obtains a working block, invokes child modifier
callbacks, submits model/shadow work and restores the scratch cursor. It does
not save model ALPHA/TEST or reconstruct earlier GS state. Persistent model
setters, scoped CPU-owner restoration and explicit register-setting packets
are separate mechanisms. A general GS push/pop contract is not established.

## Mode propagation and bounded direct callers

`scene_composition_set_blend` (`0x00194BA0`) forwards a selector to primary
models of `0x0100` children and effect descriptors of `0x0E00` children.
`effect_descriptor_set_blend` (`0x00196260`) has a different exceptional set:
only zero clears effect `draw_state` bit 0 and selects TEST low state `0x100B`;
every nonzero value sets the bit and selects `0x1001` through
`effect_descriptor_set_test`. Model selector 4's exception does not apply to
effects.

`particle_sprite_submit` (`0x00195A90`) emits the effect descriptor's blend
and TEST. With effect `draw_state` bit 0 clear, it ORs
`((texture.alpha_reference*integer_alpha+64)>>7)<<4` into TEST; the already
bounded integer alpha differs from the model's float-derived reference.
Its subsequent depth branch uses the same `0xFFF8FFFF` mask, `0x30000`
replacement and ZBUF write mask as ordinary model drawing. Ordering depends on
integer alpha below `0x80`, effect mode bit 0 or texture `draw_flags & 8`.
Numeric blend choice alone does not determine TEST reference or depth writes.
Frame-derived alpha belongs to
[Texture and material runtime](texture_material_runtime.md#draw-time-resource-and-state-consumers).

`scene_child_set_model_blend` and `scene_child_set_model_test` forward supplied
selectors/values only when the child's primary model exists.
`sp_skill_owner_set_blend` also propagates through its selected owner path.
`scene_apply_table_draw_modes` (`0x003592C0`) establishes a table-driven
selector-10 path while updating renderer priority and scene alpha. It does
not identify a player-facing effect or a particular character's use.

The bounded direct model-selector scan covers the resident, BTL and ETC
imports. Its counts and call sites are in `model_instance_set_blend`'s
annotation; indirect calls and other overlays remain open.
