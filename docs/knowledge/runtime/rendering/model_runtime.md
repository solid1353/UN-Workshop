# Model and skeleton runtime

## Research coverage

Established: geometry routes and ownership, hierarchy and bone matrices,
animation binding, CPU skinning, and inspected morph gates/arithmetic/mutation.
Open: authored morph pairs/counts, later property owners and borrowed lifetimes,
wider mutations, full attributes, and palette/influence limits.
Names and per-routine detail come from `@annotations/NA2` and `@annotations/NUN3`.

## Evidence conventions

All cited code is resident ELF code at live EE addresses; see
[address conventions](../../game/files/file_identities.md#address-conventions).
Static evidence concerns retail NA2 `SLPS_258.37` and official NUN3 `SLUS_217.27`.
Bounded reader agreement does not establish whole-file model equivalence or
complete asset interpretation; unexamined branches remain unknown.
`CcsRecord`, source descriptors, geometry resources, runtime model instances
and instantiated scene children describe distinct allocations. Annotated names
describe demonstrated behavior, rather than recovered retail symbols.

Related owners: [CCS runtime](../../game/files/ccs_runtime.md) owns parser framing
and publication; [CCS object types](../../game/files/ccs_object_types.md) owns
the tag ledger; [animation runtime](../animation_runtime.md) owns playback timing
and interpolation; [texture and material runtime](texture_material_runtime.md)
owns material/texture behavior. [Model VU programs](model_vu_programs.md) owns
microprograms, strip-control consumers and packed storage bounds;
[material render modes](material_render_modes.md) owns packet-state meanings;
[shadow rendering](shadow_rendering.md) and [shadow VU program](shadow_vu_program.md)
own the topology consumer and selected authored shadow distribution.
[Composition attachment dynamics](composition_attachment_dynamics.md) owns
`0x2300` attachment chains.

## Model loader and geometry routes

`ccs_parse_model` (`0x001B0C40`) publishes model tag `0x0800`.
A zero part count publishes a null runtime pointer. Otherwise it retains a
`CcsModelDescriptor` and its `CcsModelMesh` parts, including decoded
`runtime_flags`, `position_scale`, header values and optional palette indices.

The file geometry selector is `(file_flags >> 1) & 7`:

| Selector | Runtime flag added | Prefix and route |
| --- | --- | --- |
| 0 | none | Clear the bookkeeping record; read dependency and vertex count; ordinary arrays through `ccs_read_model_vertex_arrays`. |
| 1 | none | Fail-fast null store; no accepted route established. |
| 2 | `0x04` | Dependency, vertex count and second count; packed conversion through `ccs_convert_packed_model_mesh`. |
| 3 | `0x10` | The property reader `ccs_read_property_geometry_part` owns its prefix; the loader also adds flags `0x4a01`. |
| 4 | `0x08` | Reserved record zero as dependency and zero ordinary count; topology through `model_prepare_projection_geometry`. |
| 5..7 | none | Fail-fast null store; no accepted route established. |

The internal auxiliary route `ccs_read_model_mesh_aux` has no selector assignment in
the examined outer dispatch. Its reader contract does not establish reachability.

Older container versions mask or omit additional header fields. The optional
palette byte list is retained in `palette_indices`/`palette_count`, with no
visible admission limiting its declared count to its 64-byte allocation.
For version `>=0x123`, the low two bits of `extra_pass_selector` come from
extra-byte bits 2..3. They select one extra-pass blend entry; they are separate
from `blend_selector`, which controls ordinary blending. Version-specific
reads, scalar conversion and flag decoding are retained in the loader annotation.

## Retained header state and instance lifetime

`ccs_model_instance_initialize` (`0x001992A0`) constructs the runtime parts and
then establishes `CcsModelInstance.extra_pass_owner`. Property geometry kind 2
can supply the **first part's** borrowed `CcsPropertyGeometry.extra_pass_owner`,
adding flags `0x8180`. If flags `&0x84` are nonzero and there is no owner, the
constructor allocates an independent `CcsExtraPassOwner`, marks ownership
`0x10000`, and snapshots the descriptor's width, low-24-bit color and low-two-bit
selector. Borrowing does not perform those header assignments.

`model_extra_pass_initialize` initializes the owner; `model_extra_pass_set_blend` replaces only
its blend state from `model_blend_states`. Constructor selectors 0..3 select
`0x44`, `0x48`, `0x42` and `0x09`: this is a two-bit selector, not two
independently demonstrated enable flags. Ordinary selection through
`model_instance_set_blend` writes the instance's separate `blend_state`.
Neither inspected selector assignment changes the other state. Blend/state
meanings and width/color consumers belong to
[Extra model-owned blend state and FRAME restoration](material_render_modes.md#extra-model-owned-blend-state-and-frame-restoration).

Independently allocated owners are independent header snapshots.
`model_copy_instance_draw_state` copies flags and scale to the draw context without refreshing
the snapshot. `handle_e68_destroy` frees an extra-pass owner only with ownership
`0x10000`; a borrowed property's owner belongs to `property_geometry_destroy`.
The inspected `property_geometry_convert` clears that source owner on completion, so a
later producer is required for the nonnull borrowed case and remains unidentified.
These paths establish no reference count or safe source destruction while an
instance still uses its owner. Wider indirect consumers and later mutations
remain incompletely examined.

`model_instance_copy` (`0x00198E30`) copies the existing owner pointer and clears
destination ownership. It borrows the child array, copies flags/scale and
constructs a separate part table; it neither reconstructs nor duplicates the
extra-pass snapshot. Copying an instance therefore borrows a lifetime that
independent construction can own. `scene_child_copy` similarly borrows primary and
secondary scene-model handles, and `child_b30_handle_destroy` destroys them only for an
owning scene node. No reference-count increment appears in these inspected copies.

`list_node_handle_clear` installs an incoming model while clearing scene ownership.
When both models have flags `&0x804` nonzero it rebuilds the incoming bone mapping
by record-name matching. It neither refreshes the extra-pass snapshot nor
compares morph geometry. By contrast, `ccs_scene_child_bind_models` constructs new runtime
models. Scene attachment alone does not imply independent model storage.

The extra-pass gate is independent of the header selector.
`model_draw_parameters_setup` snapshots `model_extra_pass_descriptor` into the draw context.
`model_dispatch_geometry` (`0x001910E0`) requests the pass only with model flag
`0x80`, a nonnull descriptor and its nonzero halfword `+0x1c`; the descriptor
field's complete meaning is unresolved. Ordinary and packed routes then use
`model_submit_ordinary_extra_pass` and `model_submit_packed_extra_pass`, respectively.
Whole-model admission belongs to
[Visibility](visibility.md#ordinary-model-draw-boundary); selected VU behavior
belongs to [Shared direction-offset programs](model_vu_programs.md#shared-direction-offset-programs).

## Ordinary geometry and strip conversion

The ordinary reader rejects flags `0x804`, reads signed-halfword XYZ triples,
aligns to four bytes and updates aggregate extrema. Optional dword arrays follow:

| Runtime condition | Consumption and retention |
| --- | --- |
| `0x40` clear | One word per vertex in `elements`, plus its high byte in `strip_controls`. |
| `0x200` clear | One word per vertex; flag `0x01` discards it after reading, otherwise `uv_words` retains it. |
| `0x400` clear | One word per vertex in `auxiliary_attributes`. |

`ccs_normalize_ordinary_strips` treats control values 1/2 as run starts and zero as continuation.
Parity can reverse the geometry/attribute run or duplicate a vertex and rebuild
the arrays. Post-conversion count and order can therefore differ from the file.
Ordinary and packed strip normalization run only with flag `0x02000000` set
and `0x04000000` clear.

Ordinary arrays remain retained beside the geometry packet. Its layout depends
on the low 16 runtime-flag bits. Attribute widths alone do not establish every
attribute meaning or VU interpretation. Material binding, draw-time UV changes
and packed material offsets belong to
[Texture and material runtime](texture_material_runtime.md).

## Triangle topology conversion

Selector 4 consumes point/index counts, signed-halfword XYZ triples aligned to
four bytes, then `index_count / 3` dword-index triples. The integer quotient
controls consumption; there is no separate remainder read.

The converter builds triangle and edge-related packet data while leaving
ordinary position/attribute arrays null, then releases its temporary topology.
Construction limits can discard the packet and return 1; publication returns 0.
The outer loader does not branch on that result. Secondary-model attachment at
container finalization is a separate contract from ordinary and packed meshes.

Complete generated edge/plane meanings and draw consumption belong to
[Shadow rendering](shadow_rendering.md#geometry-inputs-and-renderer-ownership)
and [Shadow VU program](shadow_vu_program.md), including
[Selected authored shadow topology](shadow_vu_program.md#selected-authored-shadow-topology).

## Packed geometry, influences and matrix palette

Packed conversion retains a `CcsPackedGeometry` packet and qword count.
Ordinary part arrays remain null, and temporary reader arrays are released
after packet publication.

| Second count | Consumed payload and conversion |
| --- | --- |
| zero | `ccs_read_packed_rigid_part`: matrix-selector word, signed XYZ triples, alignment, attribute words and masked/shifted UV words; `ccs_convert_rigid_vif` batches at most `0x36` vertices. |
| nonzero | `ccs_read_packed_weighted_part`: eight-byte influence lists, one word per declared influence and one masked/shifted UV word per logical vertex; `ccs_convert_weighted_vif` batches complete lists. |

`CcsPackedInfluence.control &0x0200` terminates each influence list;
`position` contains signed XYZ. The generated fields are `(control&0x1ff)<<4`,
`0x50+4*(control>>10)`, and the first influence's list count (1 for subsequent
influences). **High-confidence inference:** these are a weight and matrix-palette
index. They do not establish normalization or a maximum influence count;
[Packed influence evaluation](model_vu_programs.md#packed-influence-evaluation)
owns the selected downstream accumulation rule.

Both converters emit float XYZ multiplied by `position_scale /4096`.
Weighted output consists of influence data, positions, per-influence words and
per-vertex UV words. Rigid output uses positions, per-vertex words and UV words
with one shared matrix index `0x50+4*selector`. Optional strip conversion can
change their original vertex order.

`ccs_count_weighted_batch_vertices` includes complete lists until
`3*(influences_so_far+vertices_so_far)+1>0xda` or the input ends.
The threshold-crossing vertex is included. This is a packet batching rule,
not a demonstrated per-vertex influence limit.

`model_submit_packed_geometry` (`0x0018FFB0`) uploads one 64-byte matrix per palette entry
starting at vector slot `0x50`, advancing four slots per matrix. A zero
`palette_count` uses the composition child order; otherwise each
`palette_indices` byte selects a child without a visible index bounds check.
Null children emit identity; nonnull children refresh their accumulated matrix
and combine it with the draw context. The resulting addresses agree with the
generated influence indices.

[Packed palette and influence storage bounds](model_vu_programs.md#packed-palette-and-influence-storage-bounds)
distinguishes storage representation from admission;
[source strip controls](model_vu_programs.md#source-strip-controls-and-their-selected-consumers)
owns the selected control interpretation. Neither supplies an omitted CPU check.

NA2 packed conversion does not propagate temporary extrema to the outer loader.
The loader nevertheless expands the outer extrema for flags `0x804` and builds
bounds, while instance construction clears its ordinary bounds pointer for those
flags. This establishes only that data flow; broader packed-model culling belongs
to [Visibility](visibility.md).

## Composition hierarchy and matrix lifetime

The composition parser `ccs_parse_morpher` retains child records and initial
`CcsTransform` values. Version `>=0x110` reads position, Euler degrees converted
to radians and scale; older versions retain initialized zero position/rotation
and unit scale.

`ccs_finalize_dependencies` builds `CcsCompositionDescriptor.parent_indexes` by matching
each child's parent record against the child-record array: match becomes its
index, otherwise -1. This is record identity, not bone-name or file-order matching.
A later pass can remove a flag-`0x08` geometry child, attach its model as its
parent's secondary model and adjust following indexes, so the published child
list can differ from the file.

`projectile_simple_service_configure` materializes `0x0100/0x0d00/0x0e00` scene children.
`CcsCompositionInstance.children` and `child_count` retain the instantiated list.
`ccs_composition_link_parents` gives each child its indexed parent, or the containing
composition for -1. Optional attachment chains follow child evaluation; see
[Composition attachment dynamics](composition_attachment_dynamics.md).

`CcsScenePlayTarget.world_matrix`, `local_matrix`, `parent`,
`matrix_dirty`, `type_tag` and `source_record` describe the common node layout.
Initialization sets both matrices to identity, clears the parent and marks dirty.
Initial transforms and streamed changes write the local matrix and mark dirty.
Scale precedes Z, Y, X rotation, then translation.

`resource_transform_update` (`0x0019C7C0`) finds the highest dirty ancestor,
starts from its clean parent's accumulated matrix (or its local matrix at a root),
and updates back toward the requested child. In column-vector notation:
`world=parent_world*local`. Updated nodes clear dirty. No cycle detection or
hierarchy-depth guard is visible in this inspected algorithm.
Unattached drawing copies local to accumulated and clears dirty; palette upload
uses the same root/parent distinction. These paths use the ordinary scene hierarchy
for bone matrices, rather than a separate skeleton-matrix allocation.

`model_rebind_composition_children` explicitly rebuilds the model's child mapping in source-composition
order through temporary record publications, then clears them. Ownership `0x40`
marks the replacement array; the helper does not update the child-count halfword.
An arbitrary scene array is therefore not automatically the model's palette order.

## Property geometry and CPU skinning

Selector 3 reads a dependency, property count, and typed property payloads.
Property selector and element type are independent fields.
`ccs_read_property_geometry_data` computes payload length as
`(flags&0x0f)*element_width*(flags&0x10?1:count)`, consumes rounded dwords
and zeroes unused bytes in the last word.

| Element type | Established width |
| --- | ---: |
| `0x00/0x07` | 1 |
| `0x01/0x08` | 2 |
| `0x02/0x09/0x0e/0x21` | 4 |
| `0x03/0x0a/0x20` | 8 |
| `0x22` | 64 |

Other element widths remain unestablished. Kind 1's registered factory creates
kind-2 `CcsPropertyGeometry`; `property_geometry_vtable` selects its converter.
Temporary payloads are released after conversion.

| Property selector | Retained result |
| --- | --- |
| `0x11` | Halfword `indexes`/`index_count`, also the file part's vertex count. |
| `0x05` | Byte `strip_controls`. |
| `0x04` | Separate unchanged four-byte-per-index part array. |
| `0x21` | Rigid XYZ and consecutive equal bone-index runs with `rigid_count`/`run_count`. |
| `0x22` | Eight-byte `influences`/`influence_count`; terminators determine `weighted_vertex_count`. |
| `0x24/0x25` | Three-byte vectors expanded to four bytes with zero fourth byte, rigid entries then weighted influences. |

One geometry allocation owns these arrays. Vector storage sizes against rigid
vertices plus **influences**, not logical weighted vertices.
`property_geometry_instance_create` creates a wrapper borrowing the source geometry.
Its destructor frees the wrapper; source destruction owns the array allocation.

With model flag `0x0800`, `model_property_matrix_workspace` constructs matrices
`inverse(context_matrix)*child_world`, refreshing children and emitting identity
for null children. Identity fill for missing entries stops strictly below
`highest_bone_index`. The converter records the highest index, not index+1;
initialization of a missing highest-index bone is not established.

`model_prepare_property_geometry` (`0x001921C0`) evaluates
`rigid_count+weighted_vertex_count` float positions and vectors. Rigid XYZ
uses model scalar /4096 and homogeneous W=1 before its bone transform;
signed vector bytes use /64 and W=0.

For each weighted influence, position accumulates
`matrix*position*((control&0x1ff)/256)`. The direction vector accumulates
its transform **without that weight multiplication**. At a terminator, the
position is emitted and the vector sum is normalized by its length; both
accumulators reset. Position weights are not sum-normalized.
**High-confidence inference:** the direction consumer interprets
`0x24/0x25` as normals.

After evaluation the draw scalar becomes 1.0, flags become `0x7000`, and
index/control gathering consumes the evaluated arrays before their temporary
allocation is freed.

## Animation binding to scene nodes

`ccs_parse_animation_tracks` builds animation record/track pairs and a signed-halfword
parent map. `animation_attach` builds the player's `CcsPlayEntry` targets,
types, flags and evaluator storage using temporary record publications, cleared
before return.

With `completion_flags &0x02` clear, existing `0x0100` scene children bind by
record identity in `composition_children`. With it set, `0x0100/0x0e00` match
available children by record names, including the player's `name_offset`.
Unbound ownership-marked entries materialize separately: `0x0100` gets a scene
node and model; `0x0800` gets a model without a scene-child array. Models needing
bone rebinding receive arrays in their source-composition order.

Entry flag `0x02` applies the parent map: -1 attaches to the player node,
otherwise to the indexed runtime target. Playback can thus construct or reparent
a hierarchy independently of composition construction. Entry flag `0x01`
controls target allocation/destruction. Prior-animation matching can copy
target/type/flags, but owned entries materialize again later; a copied handle
does not prove survival across switching. See
[Animation-to-animation blending](../animation_runtime.md#animation-to-animation-blending).

Typed `0x0102` evaluates translation, rotation, scale and opacity into the local
matrix. A transform attachment can replace scale and multiply translation by its
scalar; alternate output can substitute a separately looked-up transform.
Streamed `0x0101` also writes the local matrix and dirties it. Both feed the
hierarchy cache used by bone uploads; timing, interpolation and blend pose
composition belong to
[Animation evaluation](../animation_runtime.md#typed-curve-evaluation).

## Morph control and geometry ownership

Playback and animation binding materialize `0x1900` as a `CcsMorpherRuntime`
with zero source count and `morpher_vtable`. An object descriptor's
`morph_controller_record` binds the controller to the scene's
`morph_controller`. Non-packed drawing invokes `morpher_blend_vertices`
(`0x00197570`) after part preparation and before modified geometry production.

`morpher_set_source` writes borrowed source model/float weight entries;
`morpher_set_source_count` publishes their count. Streamed `0x1901` resolves and
compacts missing sources. Typed `0x1902` instead uses each key's bound-player
entry index and omits exactly zero evaluated weights; it does not perform the
streamed missing-source check.

`model_draw_part_setup` starts each part by borrowing its base arrays and packet,
clearing draw ownership. The first position edit through `model_draw_edit_positions`
allocates a separate destination, returns the old input separately and clears the
retained packet. Later modifiers use that destination as input and output.
The packed delegate has no corresponding controller hook and retains no ordinary
halfword position buffer. A universal morph contract across geometry modes is
not established.

### Selected morph admission and topology assumptions

Both inspected non-packed continuations invoke the controller after part setup
and before property preparation. Context initialization copies the scene controller
without comparing its sources or geometry.

| Inspected path | Enforced gate | Comparison absent |
| --- | --- | --- |
| Streamed producer and `ccs_play_target_unchecked` lookup | Target exists for installation; retain nonnull sources. Missing target still consumes every pair. | Entry type/index bounds; model kind, parts/counts, scalar compatibility or strip correspondence. |
| Typed `0x1902` evaluation | Omit exactly zero weights; fetch source by the key's halfword player index. | Source validity/type and part/count/format correspondence. |
| Entry/count setters | Store pointer/float and publish a halfword count. | Capacity, source validity or geometry. |
| Position blend | Nonzero controller count and successful destination allocation. | Source part existence, format/length, positive target count or topology equality. |

The blend uses the **target** vertex count and the same ordinal part index in
every source. It advances base and source XYZ by six bytes per target vertex;
the selected source part's count does not bound the blend. All-part rescaling
uses source counts separately.

**High-confidence inference:** each source must have the addressed part and
enough readable signed-halfword XYZ triples for the target's ordinal sequence.
Count equality is not required: a longer source supplies only the target-length
prefix. Meaningful vertex correspondence is an authored requirement, not an
inspected admission predicate. Independent strip reversal/duplication means equal
file counts do not prove equal post-conversion correspondence. Source indexes,
strip controls, material and normals are not substituted. The blend has no
target-count-zero precheck before its first iteration. These assumptions neither
establish malformed-asset outcomes nor prove such pairs occur in retail assets.

Arithmetic always uses six-byte signed-halfword XYZ. Destination allocation can
select six or twelve bytes per vertex, but that does not change the blend stride.
Packed and topology source parts lack the ordinary buffer; property coordinates
live in their separate object, and there is no explicit property rejection at
the hook. Later property preparation replaces the context position/vector inputs
from that object's arrays and indexes; it does not use the controller destination
as geometry input. No packed/property/topology adaptation or authored unsupported
pairing is established.

Controller allocation has room for 32 entries. Blend scratch reserves `0x100`
bytes and writes sixteen bytes per retained source, room for 16 records.
No inspected producer, setter or blend setup clamps to either capacity.
These are distinct storage bounds, not an established safe retail count;
authored counts and wider scratch use remain unmeasured.

### Shared mutation and draw-local results

When a source scalar differs from the target, the morpher rescales **all source
parts** in place by `source_scalar/target_scalar`, truncates to integers and
stores halfwords. It then writes the target scalar to both the source resource
and the participating runtime instance. A separate destination therefore does
not make morph application read-only for its sources.

The comparison reads the resource's current scalar, while the ratio uses this
instance's copied scalar. Initially borrowed arrays can be shared by independently
constructed instances with separate scalar copies. The morpher neither refreshes
other instances nor recomputes bounds or reverses mutations. Later aliasing
consequences depend on owner ordering; complete retail distribution and ordering
remain unresolved.

Explicit duplication through `model_instance_duplicate_arrays`/`model_part_duplicate_arrays` can create
private positions and controls for non-packed parts and rebuild their packet.
That is separate from initial borrowing. The morpher still updates the source
resource scalar, so private positions alone do not isolate the header mutation.
Complete use of duplication requests remains unestablished.

Streamed zero-weight sources remain in the list and can undergo pointer collection
and rescaling; typed zero weights are omitted. Zero contribution thus does not
imply no source mutation. No weight-sum or normalization admission appears.

Each part setup reborrows its base arrays. Packet reconstruction uses the current
draw-context arrays and references the destination buffer rather than copying
every vertex; the destination stays draw-local and does not replace runtime-part
positions. Source rescaling persists separately. Scene drawing and the morpher
restore their workspace cursors. Buffer/packet retirement belongs to
[Render submission](render_submission.md), not controller destruction.

Float weights convert to Q12 integers. Nominal arithmetic is
`base+sum(weight*(source-base))`, without normalized weight sums.
Halfword subtraction wrapping, integer truncation and the final saturating
signed-halfword add can differ from that unbounded float formula.
Position morphing does not update normals. Its separate flag-`0x80000`
UV-projection branch belongs to
[Texture and material runtime](texture_material_runtime.md).

Runtime parts initially borrow source arrays and virtually clone polymorphic
geometry. Runtime destruction frees arrays only under their ownership bits;
`0x20000` owns the geometry clone. Runtime model ownership `0x40` owns a
replacement bone array; source model destruction separately owns source arrays
and geometry. Morph source entries are borrowed. `morpher_destroy` frees only
the controller allocation when requested, without traversing its source list.

Playback and typed-player cleanup destroy owned controllers and runtime models
as separate entries, providing no independent source-list reference count.
Animation switching and evaluator/target lifetime belong to
[Restart, hold and removal boundaries](../animation_runtime.md#restart-hold-and-removal-boundaries).

## Bounded official NUN3 comparison

Official NUN3's resident `ccs_parse_model` (`0x001660A0`) agrees with
the inspected NA2 allocation, accepted geometry selectors and part prefixes.
Its internal auxiliary branch is likewise not assigned by the outer selector.
The comparison concerns bounded readers, not every asset.

| Contract | NA2 | Official NUN3 |
| --- | --- | --- |
| Packed rigid payload | Matrix selector, signed XYZ, attribute words, masked/shifted UVs; batches at most `0x36`. | `ccs_convert_packed_model_mesh` consumes the same fields in order with the same batch cap. |
| Packed weighted payload | Eight-byte terminated lists, per-influence words, per-vertex UVs, low-nine-bit weight shifted four and palette index `0x50+4*(control>>10)`. | Same widths, grouping and generated weight/index encoding. |
| Packed multiplier | Descriptor `position_scale /4096`. | `Nun3CcsModelDescriptor.position_scale /256`. |
| Packed extrema | Temporary extrema do not reach the outer buffer. | Both branches update the outer six-extrema argument. |
| Strip normalization | Additional header modes can reorder/duplicate ordinary and packed strips. | Outer loader does not decode those NA2 modes; packed converter has no corresponding normalization call. |
| Retained color/header word | Low 24 color bits plus separately assigned selector bits for version `>=0x123`. | Entire `header_color_word`; no matching extra-byte assignment. |
| Property framing | Dependency/count, 12-byte headers, width/multiplicity and rounded payload. | `ccs_read_property_geometry_part`/`ccs_read_property_geometry_data` agree for the listed types; selected converter was not compared. |
| Topology input | Counts, signed XYZ, alignment and integer(index_count/3) triples. | `model_prepare_projection_geometry` agrees on reads and cyclic triangle calls; complete generated packet equality is unestablished. |

**High-confidence inference:** identical packed coordinates and header scalar
produce positions 16 times larger in the inspected NUN3 converter.
Consumption agreement does not imply equal interpretation. Whether a particular
asset compensates through its scalar, hierarchy or coordinates is unresolved;
whole-file loading, VU behavior and animation/model pairing require separate evidence.
