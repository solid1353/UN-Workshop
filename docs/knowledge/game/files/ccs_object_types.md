# Resident CCS object-type identities

## Research coverage

Established: the 34 resident file routes, 29 resource identities or block roles,
texture/CLUT transfer groups, projection/composite controller behavior, the
packet-ring producer contract and their resident BSS globals. Open: legacy file
tags `0x1000..0x1200`, `0x1F00` semantics, the projection algorithm/units, and ring activation,
read-side consumer and packet language. Names and per-routine facts come from
`@annotations/NA2`, with comparisons in `@annotations/NUN3` and
`@annotations/NUN5`; addresses are live.

This document maps CCS numeric tags to resident resource identities. Container
loading, publication, hashing, residency and generic lookup belong to
[Resident CCS runtime](ccs_runtime.md). A dispatch branch, object-name prefix
or tool label alone does not establish a class identity: named classes require
a direct constructor/vtable/name chain.

## Evidence identity and address spaces

Address conventions and source identities are owned by
[Retail game file identities](file_identities.md#address-conventions).
The corroborating clean inputs are `PL/1KHWBOD1.CCS`,
`PL/2DDRBOD1.CCS`, `PL/2HKGCHA1.CCS`, `PL/2TEWCHA1.CCS`,
`BUDDY/2ASWBDY0.CCS`, `SCENE/PPT2310_ST00.CCS`,
`SCENE/PPTS04.CCS` and `XNINKA.CCS`; their hashes and sizes are in
[CCS research inputs](file_identities.md#ccs-research-inputs).

The first input corroborates object, material, texture, CLUT, model,
composition and bounds resources. `2HKGCHA1.CCS` and `2TEWCHA1.CCS`
supply hit meshes, generator packets/definitions and effects.
`2DDRBOD1.CCS` supplies composition attachments; `2ASWBDY0.CCS` binary
blobs; `PPT2310_ST00.CCS` ordered controllers and a default projection
descriptor; `PPTS04.CCS` position/rotation markers; `XNINKA.CCS`
animation, camera, external references and pre-object metadata.

The file-block tag selects a parser; `CcsRecord.type_tag` selects runtime
interpretation and destruction. They can share a number without sharing a
resource meaning. Parser descriptors and materialized playback objects also
have distinct lifetimes. Fixed layouts are named in annotation types;
unknown semantics remain explicit.

Static coverage reaches direct parsers, materialization, immediate
constructors/destructors, finalizers and consumers, rather than the whole
program. Corpus conclusions cover the non-excluded clean inputs, including
texture walks using per-level counts.
NA2 resident code and bounded literal/direct-call searches of `BTL.BIN` and
`ETC.BIN`, plus NUN3/NUN5 comparisons, bound the
negative conclusions. Overlay resource trees were not inspected.

## Confirmed identities

The following mappings have high confidence. Resource labels describe proved
behavior; only names with recovered constructor/vtable/name chains are C++
class names.

| Tag | Identity | Behavior and independent evidence |
| ---: | --- | --- |
| `0x0100` | Model-instance/object descriptor | `CcsSceneObjectDescriptor.model_record` binds the model. `ccs_classify_resource_dependencies` classifies its model, part-material, texture and CLUT dependencies. Clean names use `OBJ_`. |
| `0x0200` | Material resource | `CcsMaterialDescriptor.texture_record` joins the model-part material to its texture; clean names use `MAT_`. |
| `0x0300` | `ccTexChunk` / `ccSamplingTexChunk` | Ordinary and sampling constructions have distinct named vtables; texture teardown is virtual. Both publish the texture tag. |
| `0x0400` | CLUT/palette resource | Texture palette dependency and packed-color preparation agree with `CLT_` inputs. Eight-bit palettes use GS CSM1 ordering, swapping index bits 3 and 4. All 256 `CLT_s_menu` entries agreed in the recorded memory capture. Its transfer descriptor has the same layout as texture-level descriptors. No C++ name is established. |
| `0x0500` | Camera/view resource | `CcsCamera.matrix` is updated from position/rotation before rendering; `view_scalar` starts at 45.0. Alternate playback selects `CcsCameraPlaybackOwner.active_camera` by record name (`ccs_select_camera_by_name`), with clean example `CAM_camera01`. |
| `0x0600` | `ccLight` family | `CcsLightDescriptor.kind` selects distant, direct, spot or omni light. Unknown kinds produce no secondary object. |
| `0x0700` | Animation/track resource | Nested tracks, record/track pairs and cross-indexes feed quaternion/vector interpolation and transform evaluation; clean names use `ANM_`. |
| `0x0800` | Model/mesh resource | Model parts bind materials and own geometry, strips/indices and auxiliary projection geometry. Resident consumption establishes the role; `MDL_` inputs and explorer geometry decoding corroborate it. |
| `0x0900` | Scene composition/aggregate | Resolved children of types `0x0100`, `0x0D00` and `0x0E00` are constructed before aggregate finalization. Each child has a transform; newer streams provide position, Euler degrees converted to radians and scale. Clean names use `CMP_`. No `ccBg*Clump` name is established. |
| `0x0A00` | External-object reference wrapper | Parsing changes the name prefix to `EXT` while retaining its suffix. Reference resolution repeatedly follows wrappers; an `EXT_` query keeps the wrapper typed `0x0A00`. This differs from `#` namespace ownership. No `ccExtObjLinker` construction chain is established. |
| `0x0B00` | Model-linked hit/collision mesh | Nonzero triangle geometry supplies transformed spatial records and aggregate minima/maxima; dependency finalization attaches the hit record to its model. `HIT_2hkgwal0_hit` links `MDL_2hkgwal0` in `2HKGCHA1.CCS`. |
| `0x0C00` | Axis-aligned bounding box | `CcsBoundsDescriptor.minimum`, `maximum` and component-wise `midpoint` are built from six input floats. Clean `BOX_` names include `bbox`. |
| `0x0D00` | Transform-only scene child | A composition child accepts position, Euler rotation and scale without the frame/draw behavior of `0x0E00`. No clean sample or C++ class name establishes narrower “dummy”, “locator” or particle terminology. |
| `0x0D80` | Animation-attached generator-action packet | Packets join a target to an animation and entries join generator, attachment and auxiliary records with command bytes. Finalization installs them on the animation's packet list, then runners materialize generators. `PAC_ptewcha11` links `ANM_ptewcha11` and `PGE_`/`OBJ_` entries. |
| `0x0D90` | `ccGenerator2` definition | The direct packet consumer materializes the named generator from its parameter descriptor and registers composition, effect and animation children. Clean names use `PGE_`. |
| `0x0E00` | Animated textured effect | `CcsEffectDescriptor.texture_record`, `frame_count` and packed per-frame triples drive an effect child with frame evaluation and drawing. `EFF_2hkgwal3` and `EFF_2tewbom0` link textures; palette dependencies also resolve. |
| `0x1300` | Position-only dummy marker | Four payload dwords encode target and XYZ. `DMY_tyo_r0` is `(0,2000,1030)`; `DMY_dummy_010` is `(-300,1100,660)`. The descriptor is directly freed; no specialized downstream class is established. |
| `0x1400` | Position-and-Euler dummy marker | Seven payload dwords encode target, XYZ and Euler degrees. `DMY_dummy_100` has position `(-785.9584,-229.4614,235)` and Euler `(0,0,60)`; runtime Euler values are radians. The descriptor is directly freed. |
| `0x1700` | Lightweight ordered-controller binding | Kind-zero entries bind their `ordered_slot` in the shared playback context's ordered list; absent records create defaults. `PPT2310_ST00.CCS` binds `LYR_sky`, `LYR_bg`, `LYR_clr`, `LYR_clr01` and `LYR_board`. |
| `0x1800` | Off-screen model-geometry projection/composite controller | Kind-one table entries or a direct block supply a named/default parameter descriptor. The controller queues model geometry for off-screen rendering and compositing; [its controls and constraints](#0x1800-descriptor-fields-and-off-screen-pass) are below. |
| `0x1900` | `ccMorpher`, derived from `ccModifier` | `morpher_vtable` installs the concrete blend method `morpher_blend_vertices`. Weighted sources from materialized playback objects blend packed model vertex positions. Neither recovered source-population path reads a `0x1F00` descriptor. |
| `0x1A00` | `ccStreamOutlineParam`, derived from `ccDrawEnvCtrl` | Named concrete draw-environment parameter; playback object and small parser descriptor are destroyed separately. |
| `0x1B00` | `ccStreamCelShadeParam`, derived from `ccDrawEnvCtrl` | Same separate lifetimes with its own named concrete vtable. |
| `0x1C00` | `ccStreamToneShadeParam`, derived from `ccDrawEnvCtrl` | Same separate lifetimes with its own named concrete vtable. |
| `0x1D00` | `ccStreamFBSBlurParam` | Own vtable and playback destruction layout, separate from the parser descriptor. |
| `0x2000` | Transitional pre-object metadata carrier | A scalar and three nullable references update an existing object/effect/external wrapper or wait in a temporary carrier. The later final parser recovers the fields, frees the carrier and replaces it. `XNINKA.CCS` includes this ordering for `OBJ_xback01` and `OBJ_sun01`. It is not a stable object class. |
| `0x2200` | Global packet-ring batch | A block-only packet producer copies into available ring slots or consumes/discards the same words. [The producer/control contract](#0x2200-batch-and-global-ring) does not establish audio semantics. |
| `0x2300` | Composition child-attachment parameters | A block-only payload targets a composition and supplies two entry families. Finalization replaces child records with composition indices and compact parameter arrays; playback constructs attachments against resolved children. `CMP_2ddrh00t0 trall` includes `OBJ_2ddrh00t0 bone03` with floats `(0.85,0.9,0.2)`. |
| `0x2400` | Opaque binary blob | `CcsBinaryBlob.byte_length` and inline `payload` are copied unchanged. The `BIN_stfdata` consumer uses the same length/data contract. `BIN_asw0scr`, `_atk`, `_ent`, `_ext` and `_wit` examples range from 12 to 936 bytes; this does not establish that every blob is a script. |

Exact light selection is established by `ccs_materialize_light_secondary` (`0x0019B240`):

| Kind | Allocation | Class | Named vtable |
| ---: | ---: | --- | --- |
| 1 | `0xE0` | `ccDistantLight` | `distant_light_vtable` |
| 2 | `0x160` | `ccDirectLight` | `direct_light_vtable` |
| 3 | `0x160` | `ccSpotLight` | `spot_light_vtable` |
| 4 | `0xD0` | `ccOmniLight` | `omni_light_vtable` |

Texture, light, generator, modifier/morpher and draw-parameter RTTI/name
links are recorded as named data/label annotations. Materialization uses
`ccs_build_play_runtime_table` (`0x001A0B80`); composition construction uses
`projectile_simple_service_configure` (`0x001952F0`); attachment finalization uses
`ccs_finalize_dependencies` (`0x001AD240`). Their annotations carry allocation sizes and virtual
destruction details.

## Numeric dispatch ledger

`ccs_parse_typed_blocks` (`0x001AC8A0`) recognizes 34 object/control routes, plus
stream terminator `0x0005`. Unknown tags reach the deliberate null-store
failure. Terminator finalization is owned by
[Resident CCS runtime](ccs_runtime.md#parsing-type-dispatch-and-publication).
The runtime teardown switch is `ccs_destroy_record` (`0x001A9F10`); its annotation
holds the complete destructor mapping.

The 29 rows above are confirmed resource/block roles. The remaining file
routes are the section marker and four unresolved entries:

| File tag | Annotated parser | Established behavior | Open identity |
| ---: | --- | --- | --- |
| `0x0003` | `ccs_object_section_noop` | Object-section marker; repeated header is a no-op. | Reason for accepting an in-stream repeat. |
| `0x1000` | `ccs_parse_legacy_group_marker` | Publish numeric runtime tag with null descriptor; consume counted dwords without retaining them. Runtime teardown clears pointers only. | Relationship to texture/CLUT-created transfer groups is an inference. |
| `0x1100` | `ccs_parse_legacy_page_marker` | Read 16 bytes; use only the target record to publish the numeric tag; create no descriptor and leave its runtime pointer unchanged. | No consumer, materializer or class-name chain recovered. |
| `0x1200` | `ccs_parse_legacy_rect_marker` | Consume counted eight-byte entries without retaining them; publish the numeric tag with unchanged runtime pointer. | No consumer, materializer or class-name chain recovered. |
| `0x1F00` | `ccs_parse_nested_halfword_table` | One owned allocation containing resolved records and nested halfword arrays. | No semantic consumer or non-excluded sample recovered. |

### `0x2200` batch and global ring

`ccs_parse_packet_batch` (`0x001B44B0`) consumes `CcsPacketBatchHeader`, followed by
`packet_count * words_per_packet` dwords. The first eight header bytes
are uninterpreted; the two count fields define the producer work. It sets
`CcsContainer.runtime_flags & 0x80`, snapshots the queued count and
claims `ccs_packet_ring_owner`. It publishes no object record.

The manager pointer `ccs_packet_ring_pointer` (`0x00602A04`) initially
points to `ccs_packet_ring`. `CcsPacketRing` names its fields.
`ccs_packet_ring_construct` leaves `buffer`, `command_target`, counts and indices
zero, `semaphore` and `count_snapshot` at -1, and the unresolved
`value_3f` halfword at `0x3F`. `resident_heap_marker_initialize` registers
`ccs_packet_ring_destroy` through `ccs_packet_ring_cleanup_node`, a
`CompilerCleanupNode`, and returns without activating the buffer or command
target.

A slot requires a command target, a buffer and `queued_count != 0x100`.
With a command target, unavailable buffer/full count increments
`unavailable_slots`. Slots are `buffer + write_index * 0x400`;
commit increments the queued count, advances the index modulo `0x100`
and signals the semaphore. The count snapshot is taken only while negative.
The initialized read index's consumer is not established.

File `0x2200` and frame `0x2201` producers request a slot, copy and
commit, or consume/discard exactly the same packet words. The frame producer
`ccs_frame_tag_2201` permits owner attachment only when `ccs_packet_ring_owner`
is zero or the current container. Its stream schema belongs to
[Resident CCS runtime](ccs_runtime.md).

Playback entry requests command bit 1, stop/exit requests bit 2, and teardown
requests bit 4 in `CcsCommandTarget.command_bits`; each control signals
the semaphore. Playback requests require the container's `0x80` flag.
Teardown clears `ccs_packet_ring_owner` and the manager's command target.
These are proved producer/control operations, not meanings assigned to a
consumer's commands.

The producer trusts `words_per_packet`: a `0x400`-byte slot fits at most
`0x100` dwords, but neither loop enforces that bound. In the state created
by the inspected constructor, the missing command target causes all declared
words to be consumed/discarded. No activation writer, read-side consumer,
packet decoder or PCM/sample interpretation is established; the reference
audit does not prove that activation never occurs.

NUN3 and NUN5 corroborate the same count/index/semaphore layout, target gate,
capacity, stride and commit behavior:

| Retail program | Producer | Slot / commit | Constructor |
| --- | --- | --- | --- |
| NUN3 `SLUS_217.27` | `ccs_frame_tag_2201` (`0x0016AB30`) | `ccs_packet_ring_request_slot` (`0x00108D10`) / `ccs_packet_ring_commit` (`0x00108C90`) | `ccs_packet_ring_construct` (`0x00108F40`) |
| NUN5 `SLES_556.05` | `ccs_parse_packet_batch` (`0x001B87A0`) | `ccs_packet_ring_request_slot` (`0x00109230`) / `ccs_packet_ring_commit` (`0x00109170`) | `ccs_packet_ring_construct` (`0x00109530`) |

Their inspected static initializers likewise return after destructor
registration without publishing the buffer/target. The generic GS
command-target initializer `gs_command_target_initialize` supplies DMA tags,
callback and callback argument to a GS transfer/draw path; no established
join connects that target to the CCS ring.

### `0x1800` descriptor fields and off-screen pass

`CcsProjectionDescriptor` separates ordered slot, color/depth VRAM
coordinates, size, composite-pass count, offset multiplier and projection
scalar. The default descriptor in `PPT2310_ST00.CCS` has:

| Parameter | Game value |
| --- | --- |
| Color target | `PSMCT32`, VRAM coordinates `(960,0)`, size `256×256` |
| Depth region | `PSMZ24`, coordinates `(896,0)` |
| Composite passes | 3 |
| Offset multiplier | 0 |
| Projection scalar | `0x447A0000` / 1000.0 |

`projection_controller_construct` embeds the ordered-controller base and links
`projection_controller_head`. `projection_controller_set_target` converts the
color coordinates and stores logarithmic size; depth conversion uses `PSMZ24`.
The materializer, rather than the constructor, supplies
`CcsExtendedController.projection_scalar`, direction `(0,0,0,1)`
and strength `parameter = 0`.

Frame `0x1801` is `ccs_frame_tag_1801` (`0x001B57F0`). Its target ID selects a
play object, falling back to `CcsPlayContext.default_extended_controller`
on zero resolution. It converts Euler degrees to radians, rotates the
initialized XYZ `(0,0,-1)` into `direction`, and stores the final scalar
as strength. The input W component is uninitialized by this handler and the
four-component multiply reads it; no definite W value can be assigned.

Binding copies the controller, direction and projection scalar into
`CcsRenderEnvironment`, converting strength to its byte as
`(int(clamp(strength,0,1) * 256) + 1) >> 1`.
Zero strength suppresses geometry; values above `0x80` are capped.
The initialized controller therefore contributes no geometry until a frame
control or another owner supplies nonzero strength.

The scene's `CcsScenePlayTarget.auxiliary` reaches
`model_part_queue_projection` (`0x0018CF70`) when `flags & 0x20` is set. The producer
requires an active controller, nonzero controller mode,
`CcsModelMesh.projection_geometry_size` and nonzero strength.
The model parser prepares `projection_geometry` from packed XYZ vertices
and triangle-index triplets; preparation failure clears the geometry pointer
and size.

The producer constructs a `0x170`-byte VIF/DMA packet with
`projection_geometry_microprogram` (`0x003C3CA0`) and the geometry
buffer, then queues it through `projection_controller_append_packets`.
`CcsExtendedController.buckets` contains 15 inline
`CcsProjectionBucket` slots. Equal strength keys reuse a bucket;
new keys use another slot while `bucket_count < 15`, then an existing
nearby key. Packet chains append to each bucket's head/tail.

`projection_controllers_process` walks `projection_controller_head` and processes
controllers with nonempty queues.
`projection_controller_drain` builds depth/color setup, splices queued DMA chains
into the off-screen chain and drains the buckets, clearing head/count.
`projection_controller_composite` samples the color target as `TEX0_1` and draws
textured `UV`/`XYZ2` rectangles. Each normal composite pass uses
`projection_composite_offsets` scaled by `offset_multiplier`.
Modes 2 and 3 use one neutral-gray pass; other modes use black with alpha
`0x80` or the controller alpha byte, initially `0x20`.

Independent class corroboration is the separate `ccBgDrawShadowAnm`
owner (`background_shadow_animation_vtable`).
`background_shadow_animation_initialize` creates a controller with the same ordered base,
global list, queue and render-parameter layout, then sets render-target/depth
coordinates, passes, offset multiplier and alpha.
`background_shadow_animation_draw` temporarily binds its controller and owner's scalar,
draws its animation, and restores both environment fields.
That owner's vtable does not belong to the CCS-created controller.

**Inference:** off-screen queued model draws followed by darkened,
alpha-blended compositing fit a soft-shadow/silhouette overlay.
Direction, strength, projection scalar and the named shadow-animation use
support this more directly than the explorer's `Shadow` label.
The exact VU operation, projection units and a C++ class name for the
CCS-created object remain unresolved. The resident analysis exposes no
function for the referenced microprogram.

### File tag `0x0003`: object-section marker

`ccs_parse_container` requires section ID 3 before object dispatch.
The dispatcher ignores each header's high halfword and passes its dword
length converted to bytes to the type parser. Length use is parser-specific:
there is no generic seek to the declared block end. Generator packets,
nested tables, attachment blocks and binary blobs use that size for payload
reads/allocation.

A repeated `0x0003` block consumes exactly its eight-byte header,
publishes nothing and leaves object-block parsing active.
`ccs_object_section_noop` is a no-op.

Each of the 1,731 non-excluded clean inputs has one section-3 header directly
after chunk 2, with length zero: 1,683 high halfwords are `0x0000` and
48 are `0xCCCC`. Nine additional aligned `0xCCCC0003` words were inside
other payloads and did not begin valid block chains. Synchronized length
walks found no in-stream repeat. Tolerance of repeated/concatenated markers
is a hypothesis about why the route exists.

### Unresolved `0x1F00` binary and runtime layouts

`ccs_parse_nested_halfword_table` (`0x001B2930`) copies the complete payload, computes the
required size and packs one runtime allocation. Record IDs are resolved;
all other pointers refer into that allocation. Publication sets
`CcsRecord.type_tag` and `runtime`; teardown frees only the root.
The temporary input is freed.

`CcsNestedTableInputHeader` supplies target ID, group count and record-ID
table count. Its counted four-byte ID table follows, then variable groups.
Each `CcsNestedGroupInputHeader` selects an ID-table index, ignores one
halfword and supplies pair/item counts. The pair array consists of opaque
halfword pairs; the variable items follow it.

Each `CcsNestedItemInputHeader` holds an element count, flags, four opaque
bytes and two opaque halfwords. Its primary array has one four-byte
halfword pair per element. Flag `0x1000` adds one secondary halfword
per element after that array, rounded to a four-byte boundary.
No other flag interpretation is established.

The runtime `CcsNestedTable.groups` tail and `group_records` form two
parallel tables with `group_count` entries each. The resolved-record table
immediately follows the group-descriptor pointers; packed groups follow both
tables. Root halfword `+0x06` is unwritten.
Each `CcsNestedGroup` header precedes its `0x10`-byte
`CcsNestedItem` descriptors, followed by copied pairs and item arrays.
Each item's `primary` points to its copied array; optional secondary arrays
immediately follow and the next region is four-byte aligned.

These ownership and packing relationships are established; the semantics
of the pairs, opaque fields, arrays and remaining flags are open.
The bounded direct-literal audit supplied no related-game semantic consumer.
NUN3 has the same two-pass parser; literal searches cannot exclude
table-driven or synthesized-tag consumption.

### Runtime tag `0x1000` from texture and CLUT construction: image-transfer group

At container version `>= 0x92`, texture and CLUT parsing read an extra
group-record ID after their own target (after the CLUT ID for textures).
A nonempty group name invokes `ccs_image_attach_transfer_group` or
`ccs_clut_attach_transfer_group`.

For `CcsRecord.runtime == 4`, both helpers compare the first 30 name
bytes against the list at `ccs_image_transfer_group_head`. Without a match,
they allocate/construct a `CcsImageTransferGroup`, publish its pointer and runtime tag
`0x1000`. A match attaches to the existing node without publishing the
requesting record: its pointer stays at 4 and its tag is unchanged.
Already materialized records use their existing pointer.

The constructor copies only the first byte of the name key. Neither that
constructor nor its allocation path initializes the other 29 comparison
bytes, and node `+0x00` is not initialized as a source-record backpointer.
Thus matching depends on previous payload contents; specific allocated bytes
were not observed.

Textures and CLUTs store the group pointer and set their flag bit
`0x02`. Their destructors unlink them; when both `image_members` and
`clut_members` are empty, the node is freed. Record teardown merely
clears pointers. Member ownership, rather than the record, controls the
group lifetime.

The independent `BLT_strbreak` consumer
`stream_break_draw` (`0x003730C0`) uses `stream_break_transfer_group`, resolved
by `stream_break_transfer_group_initialize`, and orders the operations:

1. Submit member texture-level and CLUT transfers through
   `image_transfer_group_submit`.
2. Set `CcsTransferDescriptor.flags & 0x02` for every member transfer,
   suppressing uploads.
3. Run the draw path through `projectile_compound_submit`.
4. Clear the suppression bits through `image_transfer_group_unsuppress`.

Both submission variants require that bit clear. The submission packet
writes `BITBLTBUF`, `TRXPOS`, `TRXREG` and `TRXDIR` before the image
data. These operations establish a shared GS image-transfer group without
a recovered node vtable or embedded C++ name.

The parser-count-based texture corpus walk found 3,631 nonzero group
references, paired between texture and CLUT except for one texture-only
group. Every referenced name begins `BLT_`, including `BLT_obj`,
`BLT_bg` and `BLT_item`. Clean `STRMCMN.CCS` supplies the
texture-only `BLT_strbreak` with member `TEX_strbreak`; the named
resident consumer resolves it. The `BLT_`/GS transfer terminology is
corroboration.

**Inference about the file handler:** file `0x1000` publishes a null
runtime pointer, whereas texture/CLUT helpers reuse materialized pointers.
A later member naming that record would therefore dereference a null group
at the member-list field. That file block cannot safely precede group
members in the same stream. A legacy placeholder relationship is plausible,
but neither the shared number nor pointer-only teardown proves it; no clean
non-excluded file block uses it.

## Negative results and labels not promoted

No class-name chain joins `ccExtObjLinker` to the external wrapper,
`ccAnmCtrlInterpObj`/`ccAnmCtrlInterpBase` to the non-vtable
`0x1700`/`0x1800` controller layouts, or background `Clump` names to
the composition resource. Particle names `ccParticleManager`,
`ccHigeParticleGenerator` and `ccHigeParticleManager` do not establish
these route identities; only `ccGenerator2` has the direct generator chain.
Destructor-family differences alone do not name unresolved classes.

The inspected non-excluded corpus had no `0x0D00`, `0x1000`,
`0x1100`, `0x1200`, `0x1F00` or `0x2200` blocks.
This absence is bounded: declared lengths can exceed texture consumption,
so length-directed walks can lose synchronization. The aligned-word recheck
only recognizes the `0xCCCC` high halfword; other accepted high halfwords
remain outside that check. It supplied no additional valid blocks for these
routes. These findings do not establish unreachability in other inputs.

The bounded legacy-tag search supplied no consumer, and NUN3's corresponding
stubs preserve no fuller payload. No proved runtime relationship joins
`0x1F00` to `0x1900`; the nested-table shape does not justify calling
it morph data. The annotation comments retain the literal-use census.

The corroborating `CCSFileExplorer.exe` geometry decoder supports the resident
model finding, while its script/function/Puppet interpretation of `0x2400`
remains a lead.
Its label table includes:

| Tag | Tool label | Status |
| ---: | --- | --- |
| `0x0003` | `Setup` | Consistent with section marker. |
| `0x0D00` | `Particle` | Not established; resident child is transform-only. |
| `0x1000` | `Blit_Group` | Consistent with texture/CLUT-created runtime group; unresolved file handler. |
| `0x1100` | `FrameBuffer_Page` | Unverified. |
| `0x1200` | `FrameBuffer_Rect` | Unverified; eight-byte entries could encode four halfword rectangle fields. |
| `0x1800` | `Shadow` | Supports the projection/composite interpretation. |
| `0x1F00` | `Sprite2Tbl` | Unverified nested-table semantics. |
| `0x2000` | `AnimationObject` | Resident behavior is a transitional metadata carrier. |
| `0x2200` | `PCM_Audio` | Unverified; no decoder or sample semantics recovered. |
| `0x2300` | `Dynamics` | Resident behavior establishes composition attachments only. |

The tool includes `BLT_bg` and `BLT_obj`; none of its semantic label
strings is present in the resident executable. Object-name prefixes
`OBJ_`, `MAT_`, `TEX_`, `CLT_`, `ANM_`, `HIT_`,
`PAC_`, `PGE_` and `EFF_` corroborate independently established
roles. Only `EXT_` participates directly in type-sensitive logic.
The identities remain resident findings, not claims about every file variant
or every object instance.
