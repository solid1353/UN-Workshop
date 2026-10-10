# Asset dependency graphs

## Research coverage

Established: the authored-key census of 1,094 battle-related retail files;
nine typed dependency routes; startup, battle, stage and nine-slot fighter
selection; request/adoption/release ordering; selected effect leaves; and the
skill-1 provider, child, body, material and shadow closures. Open: every retail
combination's typed closure, actual simultaneous residency, later substitution
of initially empty stream targets, fighter-dependent replacement bindings, and
Collection's permitted skill-list values. Donor provider graphs and NUN4's jutsu
load and cache edges are in
[NUN3 and NUN4 characters](../../gameplay/characters/nun3_nun4_characters.md).

Routines, structures and data are named by the owning game's annotations;
their comments carry per-routine detail. Addresses are live. The evidence
concerns unmodified retail NA2 (`SLPS-25837`) and is static.

## Evidence and ownership

[Resident CCS runtime](ccs_runtime.md) owns lookup, publication and resource
lifetime; [CCS object types](ccs_object_types.md) owns payload contracts;
[Character asset tables](../character_assets.md) owns complete fighter and
jutsu filename inventories. This document owns relationships between those
resources. File identities and overlay address conversion belong to
[Retail game file identities](file_identities.md#address-conventions).

A published-directory match does not establish successful parsing,
materialization or retention for a battle. The census excludes other disc
families, and its candidate counts precede typed parsing. Inspected direct
callers do not exclude indirect or unanalyzed callers.

## Three different edge layers

| Layer | Edge | What it establishes |
| --- | --- | --- |
| Authored directory | Consumer record to an external namespace/name key | Requested provider identity, independent of a disc filename or load request. |
| Parser/runtime descriptor | Object or composition to a directory record and its resolved object | Typed relationship retained by the parser and traversed by a consumer. |
| Loader selection | Match configuration, skill row or stage index to a CCS path | File request selected by a specific caller and condition. |

A namespace beginning with `#` marks an authored external record, rather
than a request to open a similarly named file. `ccs_read_object_directory`
initializes ordinary records with unresolved runtime sentinel `4`; record
zero is cleared. `ccs_match_cross_reference_provider` compares object names
and namespace text after its first byte.

`ccs_resolve_cross_container_refs` searches new and published directories
in both directions. A match copies `CcsRecord.type_tag` and `runtime`,
but not `secondary`, and does not issue a file request. Provider choice
belongs to [Cross-container references](ccs_runtime.md#cross-container-references).

`ccs_classify_resource_dependencies` follows an ordinary scene object's
model, its parts' materials, their textures and palettes; it also follows
effect textures and palettes. Its `MDL`, `MAT`, `TEX` and `CLT`
selectors restrict the collected resources, and downstream null or sentinel
intermediates are skipped. This selected path does not cover every resource
type.

**Inference:** usable closure requires selected provider records and the
typed consumer path to agree. Directory-key equality, disc presence and a
loader request each establish a different part of that relationship.

## Typed dependency routes

Full payload contracts remain in [CCS object types](ccs_object_types.md).
The named fields below describe the retained dependencies.

| Source | Stored dependency | Selected consumer and boundary |
| --- | --- | --- |
| `0x0100`, `ccs_parse_scene_object` | `CcsSceneObjectDescriptor.linked_record` (parent), `model_record`, and version-gated `shadow_model_record` | The collector follows the ordinary model chain; `ccs_scene_child_bind_models` separately materializes the shadow model. Record pointers can be local or externally resolved. |
| `0x0200`, `ccs_parse_material` | `CcsMaterialDescriptor.texture_record` | Model-material traversal reaches this record before texture/palette collection. |
| `0x0800`, `ccs_parse_model` | `CcsModelDescriptor.parts`, `part_count`, and each `CcsModelMesh.material_record` | The collector visits each part; model subtype also selects geometry consumption. Directory rows alone cannot reconstruct geometry dependencies. |
| `0x0900`, `ccs_parse_morpher` | `CcsCompositionDescriptor.child_count`, `children` and `child_transforms` | `projectile_simple_service_configure` resolves children through `ccs_resolve_external_record_chain`, then constructs tags `0x0100`, `0x0D00` or `0x0E00`. Publication precedes materialization. |
| `0x0A00`, `ccs_parse_external_record` | `CcsExternalRuntime.link` (parent) and `owner_link` (target) | Chain traversal follows targets back to provider records. The wrapper is distinct from an authored `#` namespace; neither requests a file. |
| `0x0700`, `ccs_parse_animation_tracks` | Eight-byte record/key pairs and a halfword parent map | `animation_attach` unwraps each source record; an unresolved `0x0A00` target yields an empty entry. A usable unbound scene provider can materialize its model. [Animation wrapper resolution](ccs_runtime.md#animation-wrapper-resolution) owns the guard and bounded NUN3 comparison. |
| `0x0D90`, `ccs_parse_generator` | `CcsGeneratorDescriptor.children`, low-nibble child count in `child_count_flags`, and each `CcsGeneratorChild.record` | `ccs_materialize_generator_action` registers resolved tags `0x0900`, `0x0E00` or `0x0700`. A zero-child descriptor is freed and its runtime pointer cleared. |
| `0x0E00`, `ccs_parse_effect` | `CcsEffectDescriptor.texture_record` | Effect texture/palette traversal is independent of model traversal. |
| `0x2300`, `ccs_finalize_dependencies` | Composition children selected by attachment records | A negative child index from `ccs_relation_record_eligible` omits that child from compact attachment arrays. This is a selected omission rule. |

Missing behavior belongs to the consumer. Required `animation_find_by_name`
traps when the name is absent, but can return sentinel `4` for a matched
unresolved record. Chain traversal guards the next target object while
dereferencing the current wrapper without the same guard. A nonzero lookup
therefore does not establish readiness. The detailed boundaries belong to
[Object-name lookup](ccs_runtime.md#object-name-lookup) and
[Type-0x0A00 traversal](ccs_runtime.md#type-0x0a00-traversal).

Dependency edges also have a lifetime. `ccs_destroy_container` resets
surviving external records whose object back-pointers identify the departing
provider to type zero/runtime `4`; later publication can resolve them again.
That guarantee depends on the back-pointer contract and does not establish
repair of every secondary cache or materialized child.

### Collection and materialization are separate consumers

The inspected point-cache path supplies `MDL_point*` through
`ccs_load_point_dependency_cache` and `ccs_collect_pattern_dependencies`.
It walks the selected input records and passes the supplied pattern and
three-character selector to the collector. `EXT_point*` and `OBJ_root`
are adjacent literals. This identifies one concrete selected closure path;
it does not establish that every loader invokes it.

`ccs_dependency_vector_append_unique` deduplicates pointer values without
rejecting zero or `4`. The initial pattern match can append a record's
runtime before the guarded subordinate walk. The resulting vector therefore
does not itself validate every collected entry.

Composition construction and model absence have different boundaries.
`projectile_simple_service_configure` leaves an allocated child slot
unwritten when its resolved tag has no constructor branch. The later
`ccs_composition_link_parents` and `ccs_composition_bind_controllers`
passes dereference every child entry without a null-child guard. Safe
omission is not established: the finalized child array needs usable children.

For a valid scene-object child, `ccs_scene_child_bind_models` instead maps
an ordinary model's zero or sentinel runtime to no model, clears the
model-present flags and stores zero in `CcsScenePlayTarget.model`.
A usable child can therefore intentionally lack an ordinary model.

Rendering requires a separate material cache.
`ccs_model_instance_initialize` builds parts through
`ccs_model_part_instance_initialize`, which copies the material record's
`secondary` into the draw instance. The collector follows the descriptor's
`runtime` instead. Since cross-container resolution does not copy
`secondary`, descriptor closure alone cannot establish draw-cache closure.
Cache creation and refresh belong to
[Texture and material runtime](../../runtime/rendering/texture_material_runtime.md).

Material binding through `ccs_material_bind_texture` maps texture sentinel
`4` to zero. Effect construction through
`ccs_effect_child_bind_descriptor` passes the texture runtime directly to
`ccs_effect_bind_texture`; that helper excludes only zero before palette
lookup through `texture_get_clut`. Sentinel `4` would consequently be
used as a pointer. The later draw-time zero-texture branch does not protect
construction. This is a requirement of the consumer, not an observed retail
failure.

Generator registration also does not validate readiness. Its composition,
effect and animation registration helpers retain the supplied descriptor
without checking zero or `4`. Unrecognized child tags skip registration,
but the first child still reaches `ccs_generator_lookup_auxiliary`.
Nonzero color/texture selector bytes enable optional name-derived queries;
zero selectors add no auxiliary resource. Eventual consumption determines
the missing-resource boundary.

### Selected animation-effect leaves

The following selected leaves have independently checked typed definitions
and count-based consumption. They are bounded leaf closures; the remaining
animation tracks and shared-skeleton routes are not closed by them.

| Input | Selected typed route |
| --- | --- |
| `PL/2TEWCHA1.CCS` | Generator row 1, `PGE_ptewcha11_0` -> effect row 2, `EFF_2tewbom0` -> texture row 164, `TEX_2tewbom0` -> palette row 194, `CLT_2tewbom0`. |
| `PL/2TEWCHA1.CCS` | Generator rows 3 and 5, `PGE_ptewcha11_1/2` -> effect row 4, `EFF_2tewbom3` -> texture row 171, `TEX_2tewbom3` -> palette row 196, `CLT_2tewbom3`. |
| `PL/2HKGCHA1.CCS` | Effect row 290, `EFF_2hkgwal3` -> texture row 224, `TEX_2hkgwal2` -> palette row 292, `CLT_2hkgwal2`. |

`PAC_ptewcha11`, row 6, contains three generators and names animation
row 7, `ANM_ptewcha11`. All generators use attachment row 8 and auxiliary
record zero, with one child each. The middle generator's two parameter
entries do not add a child. The packet thus selects three generators but
only two effect/texture/palette chains.

All three child-registration gates are `-1`, and both name selectors are
zero, so their auxiliary name queries add no resource. This stored sharing
does not establish simultaneous instance counts.

Attachment row 8 is a local `0x0A00` wrapper targeting row 106,
`OBJ_gpos_tew`. That object's parent, model and controller IDs are zero,
providing a concrete intentional model-absence case. These local leaf
definitions do not themselves request another file.

### Model geometry outside the material chain

A model can own geometry independently of a material chain. The inspected
`MDL_1nrt00t0 shadow10` and `MDL_1cmn00t0 shadow10` definitions use
subtype four, one part, 20 vertices and 96 index words. The model parser
assigns record zero as the material and uses
`model_prepare_projection_geometry` to generate geometry retained in
`CcsModelMesh.projection_geometry` and `projection_geometry_size`.

Part-instance initialization copies those fields independently of the material
cache. The collector skips the null material runtime, while the model and
generated geometry remain separate requirements. The complete selected
body/shadow closure is described below.

## Authored directory census

The census covers all namespace and directory rows in 1,094 retail CCS files
under `@source_na2/DATA/DATA.CVM.files/DATA.CVM.iso.files/`. Keys compare
exact bytes up to the first NUL, preserving non-ASCII bytes. It does not
infer typed block boundaries from declared lengths, which are not uniformly
exact ([Parsing and publication](ccs_runtime.md#parsing-type-dispatch-and-publication)).

| Corpus | Files | Directory records, including record zero | Authored `#` records | No other-file non-`#` key candidate | Multiple other-file non-`#` key candidates |
| --- | ---: | ---: | ---: | ---: | ---: |
| `PL/` | 325 | 435,860 | 13,600 | 44 | 262 |
| `CMN/` | 6 | 4,743 | 2 | 2 | 0 |
| `STAGE/` | 24 | 17,940 | 3 | 2 | 0 |
| `STR/` | 383 | 345,246 | 47,279 | 217 | 11,867 |
| `BUDDY/` | 98 | 17,006 | 2,005 | 1 | 55 |
| `PUPPET/` | 46 | 92 | 0 | 0 | 0 |
| `CUTIN/` | 37 | 4,818 | 2,297 | 4 | 453 |
| `3BSC/` | 9 | 27 | 0 | 0 | 0 |
| `3EYE/` | 157 | 19,789 | 4,853 | 266 | 455 |
| `MODENAME/MODE1CMN.CCS` | 1 | 14 | 0 | 0 | 0 |
| Selected root files | 8 | 2,905 | 11 | 11 | 0 |
| **Total** | **1,094** | **848,440** | **70,050** | **547** | **13,092** |

The eight root files are `BATTLEGAUGE.CCS`, `OUGI.CCS`, `STRMCMN.CCS`,
`N_RASH.CCS`, and `N_RASH2.CCS` through `N_RASH5.CCS`. They cover
ordinary battle paths and one retained adjacent file, rather than the full
disc corpus. The disc inventory belongs to [Media layout inventories](media/README.md).

A candidate is another file's non-`#` row with the same namespace suffix
and object-name bytes. Candidate counts predict neither a parsed descriptor
nor load order. Typed blocks may locally fill authored `#` rows, and
parsers may rename records. The 547 unmatched rows are therefore not 547
confirmed missing resources. Zero authored `#` rows also does not exclude
loader, typed-record or code-selected dependencies.

### Locally filled external-marker rows

`ccs_parse_image_block` fills a texture row whose runtime is zero or `4`
without checking its namespace marker. Its sampling flag selects
`sampling_texture_chunk_construct` (original class `ccSamplingTexChunk`).
After parsing, cross-container resolution changes the namespace's first
byte to space when runtime is no longer `4`. An authored external marker
can thus become a local typed provider.

| Retail file and row | Authored identity | Selected texture content |
| --- | --- | --- |
| `CMN/EFFECT0X.CCS`, 2615 | `TEX_sampling00`, `#e\0x\tex\sampling00.bmp` | Flags `0x21`, no CLUT/group, zero pixel words. |
| `CMN/EFFECT0X.CCS`, 2090 | `TEX_sampling01`, `#e\0x\tex\sampling01.bmp` | Flags `0x21`, no CLUT/group, zero pixel words. |
| `STRMCMN.CCS`, 233 | `TEX_strbreak`, `#e\00\tex\strbreak.bmp` | Flags `0x01`, CLUT zero, transfer-group row 377, 65,536 pixel words. |

Their consumed sizes follow the selected parser and mip counts rather than
the declared payload lengths. `PL/2NWVBOD1.CCS` rows 4721 and 4732 request
the two sampling keys. Although the census has no authored non-`#`
provider for either key, `EFFECT0X` supplies both typed definitions.
Sampling construction and drawing belong to
[Texture and material runtime](../../runtime/rendering/texture_material_runtime.md).

### Shared skeleton and effect-key examples

| Consumer file | Authored `#` rows | Matching provider set in the inspected corpus |
| --- | ---: | --- |
| `PL/1NRTBOD1.CCS` | 0 | No authored external-marker edge. |
| `PL/2NRTBOD1.CCS` | 34 | `CMN/2CMNBOD1.CCS`. |
| `PL/2NRTCHA0.CCS` | 94 | `CMN/2CMNBOD1.CCS` and `PL/1CMNBOD1.CCS`. |
| `PL/2NRTCHA1.CCS` | 34 | `CMN/2CMNBOD1.CCS`. |
| `CMN/2CMNBOD1.CCS`, `PL/1CMNBOD1.CCS` | 0 each | No authored external-marker edge. |
| `STAGE/S01.CCS` | 0 | No authored external-marker edge. |

These relationships support
[Shared skeleton containers](../character_assets.md#shared-skeleton-containers)
without substituting a shared skeleton for the selected character model.

`STR/D01_10.CCS` row 18 requests `TEX_e00smok04` under
`#e\00\tex\e00smok04.bmp`. Its authored candidates are `D01_10E`,
`D03_30E` and `D19_20E`. Row 476 requests `OBJ_e00line03` under
`#e\00\max\e00line03.max` and has ten candidate files. Skill 1 selects
`D01_10E`; it does not request every candidate. Actual published-provider
order matters ([Cross-container references](ccs_runtime.md#cross-container-references)).

## Selected load sets

### Common providers and battle preparation

`resident_flow_dispatch` selects the startup set before its permanent
frontend loop. `frontend_load_common_ccs` looks up each `startup_ccs_paths`
entry and synchronously loads an absent one: `cmn/cw2.ccs`,
`cmn/effect0x.ccs`, `cmn/gauge.ccs`, `cmn/particle.ccs` and
`cmn/shade.ccs`. This includes the sampling provider above without
establishing later residency.

`battle_load_ccs` selects `battle_common_ccs_paths`
(`cmn/2cmnbod1.ccs`, `pl/1cmnbod1.ccs`, `modename/mode1cmn.ccs`),
`battlegauge.ccs`, BTL's `skill_ccs_paths`
(`shade.ccs`, `gauge.ccs`, `strmcmn.ccs`, `ougi.ccs`), one stage,
both sides' conditional paths, and the stage-associated `n_rash` path.
Argument zero loads missing containers synchronously; nonzero queues them
and starts one background worker after selection.

The setup order and fence belong to
[Resident setup order](../../gameplay/session/battle_lifecycle.md#resident-setup-order).
Bare logical requests such as `gauge.ccs` resolve separately from physical
disc placement (`CMN/GAUGE.CCS`), through
[Resident file services](runtime_services.md#logical-and-explicit-path-routes).

### All nine per-side selection slots

`battle_queue_fighter_ccs` handles sides 1 and 2. Each
`FighterCcsSide` has nine corresponding `paths` and `containers`;
`BattleCharacterSlot` supplies the selected identities and selectors.

| Mask | Slot | Source and selection condition |
| ---: | ---: | --- |
| `0x001` | 0 | Fighter's `1BOD1` filename under `pl/`. |
| `0x002` | 1 | Fighter's `2BOD1` filename under `pl/`. |
| `0x004` | 2 | `jutsu_animation_archive_name(first_animation_selector)` under `pl/`, when selector > 1. |
| `0x008` | 3 | Same route with `second_animation_selector`, when selector > 1. |
| `0x010` | 4 | Fighter's `3PCT` filename under `3eye/`. |
| `0x020` | 5 | `support_body_archive_path` supplies `buddy/2%sbdy.ccs` when support != `0x24`. |
| `0x040` | 6 | `support_variant_archive_path` supplies `buddy/2%sbdy%d.ccs` from `support_selector`, with the same support gate. |
| `0x080` | 7 | `support_cinematic_archive_path` supplies `3bsc/3%s3bsc.ccs` for an admitted support/fighter combination in its ten-row table. |
| `0x100` | 8 | `fighter_cutin_archive_path` supplies `cutin/1%scutin.ccs` for an admitted fighter in its 94-byte table. |

Filename inventories, `manager_publish_six_selections`, and side 2's
loading portrait belong to
[Character asset tables](../character_assets.md#selection-and-loading-consumers).

This selection path does not derive extra body requests from marked CCS rows.
For Sai, slot 1 selects `2saibod1.ccs`; the typed sword wrappers in
[Marked character-reference consumers](../../gameplay/characters/nun3_nun4_characters.md#marked-character-reference-consumers)
need the matching Sasuke provider objects at binding, but add no
`2sswbod1.ccs` request through this path. Provider publication by another
selection or an older load is a separate edge, rather than an implicit
consequence of loading Sai's body.

#### Request writes

Synchronous requests call `ccs_load_if_absent`. Deferred requests first use
`ccs_find_container`: an absent path is submitted to
`ccs_enqueue_unique_load`; an existing path goes through the blocking
wrapper instead.

That wrapper returns zero for an already published container, rather than
returning its handle. Only a nonzero new-load result writes a side handle;
queue submission's result is ignored. A stored path can therefore coexist
with a zero handle until adoption. No branch clears a stale handle or reports
a status. Wrapper and queue contracts belong to
[Loading and cancellation](ccs_runtime.md#loading-and-cancellation).

#### Adoption and cache reset

`battle_adopt_fighter_ccs` fills selected zero handles from stored paths
using `ccs_find_container`. It neither loads nor increments a container
use count. Jutsu slots additionally require their current animation selectors
to exceed 1; support and cut-in adoption do not repeat request-time gates.
Two adopted slots can share one allocation.

`battle_state_create_fighters` waits for
`ccs_load_queue_worker_active` to report no worker, clears the queue and
adopts mask `0x1FF` for both sides before advancing to state `0x0E`.
The fence establishes ordering, rather than successful publication of every
requested file.

`manager_clear_character_resource_slots` clears handles and paths without
destroying containers. Side `-2` resets slots 0, 1 and 2; side 1 or 2 resets
one side. Release must be arranged separately by the caller.

#### Masked release and shared aliases

`manager_release_character_resources` destroys selected nonzero handles,
clears their local slots and clears matching aliases on both sides. Sharing
does not defer destruction: this is full release and alias invalidation.
The low-level contract belongs to
[Low-level destruction](ccs_runtime.md#low-level-destruction).

Either jutsu mask bit (`0x04` or `0x08`) releases both jutsu slots.
After each destruction, both sides' two jutsu slots are checked. If local
slots share a pointer, the first release clears its aliases before the second
slot is visited. Other families clear only corresponding slots across sides;
there is no general scan of every manager handle.

#### Pending-side release preserves the other side's resources

`battle_release_unshared_fighter_ccs_slot` retains a handle when the other
side's same slot matches it; otherwise it destroys and clears the local slot.
It has no internal side/slot bounds check. The inspected pending-side path
supplies support slots 5, 6 and 7.

`manager_release_pending_character_resources` chooses side 1 if its
pending character ID is nonzero, otherwise side 2 if its pending ID is
nonzero, and returns when neither is pending.

- Body, portrait and cut-in mask `0x113` is fully released only when the
  sides' current character IDs differ.
- Support slots 5, 6 and 7 retain exact matches on the other side independently
  of character identity.
- Each jutsu handle is compared with both other-side jutsu slots. Unshared
  handles are released, with the original first local pointer retained for
  comparison so a matching second local handle is not destroyed twice.

Retained or duplicate local handles can remain when the helper returns.
`manager_replace_form` subsequently resets that side's cache, installs its
pending identity and requests mask `0x1FF`. The other side retains its
adopted pointers. Form gates and reconstruction order belong to
[Post-UJ replacement](../../gameplay/characters/awakening.md#static-reconstruction-order);
this resource ordering does not establish display timing or an in-place swap.

#### Established release callers

Global cleanup releases side 1 before side 2 with full mask `0x1FF`;
first-side alias clearing prevents duplicate destruction. Configuration
replacement can release an altered other side before restoring saved
configuration, then release the pending side and request its replacement.
Character-resource reset releases all changed sides, restores the saved
configuration once, then submits deferred replacement requests.

The configuration and continuation contracts belong to
[Manager identity and resource reset](../../gameplay/characters/awakening.md#manager-identity-and-resource-reset)
and [Continuation encounters](../../gameplay/session/battle_lifecycle.md#continuation-encounters-rebuild-the-session).
The per-routine caller details are carried by the cleanup and reset annotations.

### Stage-selected edges

BTL's `stage_archive_acquire` indexes the 24-entry `stage_archive_paths`
table (`stage/s01.ccs` through `stage/s24.ccs`), looks up the selected
container and loads on a miss. It does not derive further file requests
from that container's directory.

Battle preparation separately requests `stage_rash_archive_path(stage_slot)`.
Its reachable groups are `n_rash.ccs`, `n_rash3.ccs`, `n_rash4.ccs`
and `n_rash5.ccs`; two entries in the retained six-path table are unselected.
Exact slot mapping and lifetime belong to
[Stage identity and resource mapping](../../gameplay/stages/stages.md#stage-identity-and-resource-mapping).

Across all 24 directories, only three authored external rows occur:
`S03` row 649 and `S18` row 244 request `TEX_sampling00`;
`S04` row 585 requests `TEX_e0xpar03` under
`#e\0x\tex\e0xpar03.bmp`, matching `CMN/EFFECT0X.CCS`.
These rows do not replace the separate stage-selection and typed-object paths.

### Cinematic request table and bounded closure

The 184 retail `SINF` rows have 151 zero-extra, 28 one-extra and five
two-extra requests. Row zero has no stream, and
`sp_skill_relocate_request_table` clears its main path during initialization.
The other 183 rows each have one stream. Framing, relocation and flags belong
to [Request-table source](ccs_runtime.md#request-table-source) and
[Request list](ccs_runtime.md#request-list).

Skill 1 requests main `str/d01_10e.ccs`, extra `pl/2nrtbod1.ccs`,
then stream `str/d01_10.ccs`. Together with the selected common and Classic
Naruto body files, these providers cover all 187 stream external rows:

| Candidate provider | Stream rows with matching key |
| --- | ---: |
| `PL/1NRTBOD1.CCS` | 54 |
| `PL/1CMNBOD1.CCS` | 68 |
| `PL/2NRTBOD1.CCS` | 25 |
| `STR/D01_10E.CCS` | 40 |
| `STRMCMN.CCS` | 2 |

The 189 matches cover 187 distinct rows. Stream rows 495
(`OBJ_e00board01_w`) and 503 (`OBJ_e00board01_b`) each match
both main and common providers under `#e\00\max\e00board01.max`.
Directory matching alone does not select the winner.

`2NRTBOD1`'s 34 external skeleton rows match `CMN/2CMNBOD1.CCS`.
The main provider, `1NRTBOD1` and both skeleton providers have no authored
external rows. The common sampling and break textures are locally filled.
This closes selected authored keys without closing every materialization or
lifetime. Fighter-dependent replacement belongs to
[Explicit jutsu-stream body dependencies](../character_assets.md#explicit-jutsu-stream-body-dependencies).

The main provider has 230 typed definitions: 40 compositions, 40 scene
objects, 40 models, 38 materials, 36 textures and 36 palettes. All models
use subtype zero, flags zero and one part. The 40 matching stream keys select
36 objects and four textures; following their typed links reaches 171
distinct definitions: 36 objects, 36 models, 35 materials, 32 textures and
32 palettes. Every nonzero link is correctly typed and local. Parent,
controller and image-transfer-group IDs are zero.

Forty part-bookkeeping rows are explicitly cleared by the model parser;
with record zero they explain the difference between 271 directory rows
and 230 definitions. They are not missing models.

| Board route | Object -> model -> material -> texture -> palette rows |
| --- | --- |
| Main white | 46 -> 51 -> 49 -> 50 -> 116 |
| Main black | 44 -> 47 -> 49 -> 50 -> 116 |
| Common row 149 | 149 -> 152 -> 154 -> 155 -> 376 |
| Common row 151 | 151 -> 156 -> 154 -> 155 -> 376 |

Both routes use the same board resource names and typed links.
Their shared named leaf chain is `MAT_e00board01` -> `TEX_e00white01` ->
`CLT_e00white01`.
`ccs_finalize_secondary_values` constructs local material caches, supplying
the part consumer's cache-creation path without establishing allocation
success or residency.

Corresponding black/white object, model, material, texture and palette payloads
are equal after normalizing only container-local record IDs and checking
their named targets. Parent, controller and group IDs are zero in both.
Compared payload lengths are respectively 20, 652, 20, 540 and 84 bytes;
geometry, scalar parameters, pixels and palette words agree.
The equality covers only these board chains. Provider records, cache
instances and ownership remain separate.

### Skill-1 composition and body targets

The stream has 48 compositions with 388 distinct child records:
368 `0x0A00` wrappers and 20 `0x0100` objects. Wrappers target
178 imported object records: 52 from `1NRTBOD1`, 65 from `1CMNBOD1`,
25 from `2NRTBOD1` and 36 from the main provider. The other nine external
keys are textures. Repeated wrappers share a provider while retaining
separate authored child identities.

Wrapper parsing changes the name prefix from `OBJ` to `EXT` without
changing its record index or requesting a file. The 20 local objects select
defined zero-part models with null primary runtime. Parent IDs are zero or
local object records, and controller IDs are zero. Their absent ordinary
models are intentional stored structure.

Every nonzero parent link among the 388 children stays within its composition.
The stream's 383 metadata blocks have zero first/third nullable references;
53 middle references select eleven `LYR_*` records. All eleven are
kind-zero entries in the initial registry, constructed before metadata
installation. This is a local registry relationship. The selected object
section contains no `0x0700` packed animation or `0x2300` attachment block.

`ccs_build_play_runtime_table` first initializes per-record entries from
resolved providers' secondary values. After composition construction it
replaces each source child entry with the actual scene child, tag `0x0100`,
flags `6`: drawing is permitted, destruction is borrowed from the composition.
Repeated wrappers thus share descriptors but have separate scene instances.
Transient record associations are cleared; `CcsContainer.play_entries`
retains the table. `ccs_destroy_play_runtime_table` destroys entries with
ownership bit 0 set; borrowed children follow their composition's lifetime.

`ccs_frame_tag_0101` consumes its transform, alpha and visibility fields
before `ccs_play_target_unchecked` looks up the entry; a null target returns
after those reads. Nested packed-animation binding is separately owned by
[Animation target binding](../../runtime/animation_runtime.md#target-binding-and-transform-application).

Frames 0 through 318 end with marker `-1` at the file boundary.
All inspected command targets lie inside the 883-row directory.
The 87,566 transforms address 581 distinct rows: 368 wrappers, 20 defined
objects and 193 undefined local `OBJ_*` rows 690 through 882 under
`d\01\sss\d01_10.max`. Those local rows are not missing external files.
Their initial play targets are null; later callback substitution remains open.

Frame-zero body wrappers include rows 204 (`1cmn`), 258 (`1nrt00`)
and 338 (`2nrt00`). The second `1nrt` uses row 312; additional
`2nrt` instances use 364, 390, 416 and 442. These distinct child identities
can share provider models. The stream contains no `0x0802/0x0803`
mesh-position/index replacement commands.

Other addressed routes are ten local materials, local camera/light records,
one `0x1A00`, eight `0x1B00` and one `0x1D00` descriptor.
The `0x1801` command names undefined local `SHD_shadow_buffer` row 689;
`ccs_frame_tag_1801` selects the play context's default shadow object on
its null-target branch. Parameter contracts belong to
[Streamed frame data](ccs_runtime.md#frame-stream).

All selected imported body objects have local `0x0100` definitions;
their parent links stay within their respective provider object sets.

| Selected provider | Body object -> model rows | Model route |
| --- | --- | --- |
| `PL/1NRTBOD1.CCS` | 54, `OBJ_1nrt00t0 body` -> 189, `MDL_1nrt00t0 body` | Subtype 2, 31 parts, 43-byte palette-order list. |
| `PL/2NRTBOD1.CCS` | 118, `OBJ_2nrt00t0 body` -> 4633, `MDL_2nrt00t0 body` | Subtype 2, 20 parts, 20-byte palette-order list. |
| `PL/1CMNBOD1.CCS` | 67, `OBJ_1cmn00t0 body` -> 190, `MDL_1cmn00t0 body` | Subtype 2, one part, one-byte palette-order list. |
| `CMN/2CMNBOD1.CCS` | 68, `OBJ_2cmn00t0 body` -> 1362, `MDL_2cmn00t0 body` | Subtype 3, one property-geometry part, one-byte palette-order list. |

`CMP_1cmn00t0 trall` row 3 has 64 typed local children;
`CMP_2cmn00t0 trall` row 1299 has 34. The latter children match
`2NRTBOD1`'s 34 skeleton imports, while the selected `2nrt` body
nodes themselves are local. Shared skeleton imports must not be substituted
for the selected body model. Ordering and replacement binding belong to
[Model and skeleton runtime](../../runtime/rendering/model_runtime.md#packed-geometry-influences-and-matrix-palette).

The four providers contain 242 selected model definitions: 170 subtype zero,
three subtype two, one subtype three and 68 subtype four. Nonempty ordinary
models in `1NRTBOD1` and `1CMNBOD1` add eye/mouth leaves;
the selected subtype-zero models in `2NRTBOD1` and `2CMNBOD1` are empty.

Both Naruto subtype-two bodies use one body material across all parts.
Their first 30/19 parts use `ccs_read_packed_rigid_part`, and their final
parts use `ccs_read_packed_weighted_part`. The weighted counts are
2,628 vertices/4,382 influence words for `1nrt` and
976/1,457 for `2nrt`; influence-group terminators produce the stored
vertex counts. The `1cmn` rigid part has 24 vertices.
The `2cmn` subtype-three part has six property headers through
`ccs_read_property_geometry_part` and `ccs_read_property_geometry_data`;
it follows a different consumption route.

| Provider | Body material -> texture -> palette rows | Distinct material/texture/palette leaves |
| --- | --- | --- |
| `1NRTBOD1` | 190 -> 191 -> 193 | 4 / 3 / 3 |
| `2NRTBOD1` | 4634 -> 4635 -> 4642 | 1 / 1 / 1 |
| `1CMNBOD1` | 191 -> 192 -> 194 | 4 / 4 / 4 |
| `2CMNBOD1` | 1363 -> 1364 -> 1366 | 1 / 1 / 1 |

The `1NRTBOD1` eye materials share a texture; `1CMNBOD1` uses
separate eye textures. All selected leaves are typed local definitions,
all transfer-group IDs are zero, and they enter the local material-cache
construction path. This closes stored geometry/material routes without
establishing allocation success or replacement matrix binding.

The two `1nrt` stream body compositions each have 51 children;
the five `2nrt` compositions each have 25. Their palette-order lists stay
within those arrays. Rigid selectors and weighted indexes remain inside
palettes `0..42` (`1nrt`), `0..19` (`2nrt`) or `0`
(`1cmn`). Common model lists select child 2 or 3 within the corresponding
64/34-child composition. Stored index bounds do not establish allocated
matrices or later name mapping.

After initial playback-table construction, `sp_skill_play_begin` obtains
the defender's body/eye1/eye2/mou1 descriptors from its shared lookup holder,
conditionally creates models and rebinds the four `EXT_1cmn00t0`
placeholders through `list_node_handle_clear`. Body mode 6 maps incoming
packed composition names to existing children and installs the replacement
in `CcsScenePlayTarget.model`. Actual defender body, appearance palette
and attachment resources consequently depend on the selected fighter.

The later `sp_skill_select_body_composition` and `sp_skill_bind_body_model`
path uses the separately materialized common composition and selected
fighter model. Its selection contract belongs to
[Explicit jutsu-stream body dependencies](../character_assets.md#explicit-jutsu-stream-body-dependencies).
These bindings do not create file definitions for local rows 690 through 882.

Each of the four body/skeleton sets has 17 shadow links, covering
`shadow01` through `shadow17`. They occupy
`CcsSceneObjectDescriptor.shadow_model_record`, separately from
`model_record` and `morph_controller_record`; zero stays null through
`ccs_nullable_record_from_index`.

All 68 shadows use subtype four, one part and record-zero material.
The pelvis ordinary/shadow pairs are 58/59 (`1NRT`), 4564/4565 (`2NRT`),
71/72 (`1CMN`) and 1302/1303 (`2CMN`); the ordinary pelvis models
are empty. The `1NRT` body separately selects skinned model 189.
Selected shadows contain 8, 12, 16, 20 or 24 vertices and
36, 60, 72, 96 or 120 index words, with complete count-based geometry.

Child construction materializes a resolved shadow separately in
`CcsScenePlayTarget.auxiliary`, while the ordinary model uses `model`.
The empty ordinary pelvis model therefore does not imply absent shadow
geometry. Static inputs do not establish generated packets or later selection;
the renderer contract belongs to
[Shadow rendering](../../runtime/rendering/shadow_rendering.md).

### Selected provider identity and lifetime

Skill 1's main/extra requests use flag `0x1000`: an already published
provider is borrowed, while an absent one is loaded into a one-shot wrapper
destroyed at playback end ([Request list](ccs_runtime.md#request-list)).

**Inference:** when the selected main provider is newly loaded after
`STRMCMN`, its head insertion by `ccs_parse_typed_blocks` puts it before
the older common provider for duplicate board-key resolution. If already
resident, the request does not republish it, so request order alone does not
determine the winner. Equal payload content does not merge provider identity,
allocations or ownership.

Unload invalidates imported record runtimes and types without rebuilding
the copied playback targets. Authored-key equality and invalidation alone
therefore do not prove borrowed scene-target validity over a playback lifetime.

All default main/extra/stream paths for rows 1 through 183 exist except
`0x9A`'s `str/d21_10e.ccs` and `str/d21_10.ccs`, and
`0xA0`'s `str/d25_30e.ccs` and `str/d25_30.ccs`.
All nine opponent path replacements and their derived `E` files exist.
The other three overrides replace a skill row without requesting their
placeholder paths. Override behavior belongs to
[Opponent-dependent cinematic selection](../../gameplay/characters/ultimate_jutsu_cinematics.md#opponent-dependent-cinematic-selection).

No inspected path establishes retail battle selection of either absent-path
skill. Their missing files are a table/availability observation, rather than
evidence of a player-visible failure.

At countdown 85, BTL's `jutsu_presentation_update` obtains the side
manager's selected record and supplies the admitted skill from
`jutsu_record_playable_skill` to `sp_skill_play_start`.
The 223-entry `jutsu_name_table` contains neither `0x9A` nor `0xA0`
in `UltimateJutsuRecord.authored_id`; `jutsu_find_record_by_skill`
searches that same domain. An index in this retail table cannot directly
supply either skill through that battle path. This does not prove every
manager index valid or exclude later table writes. The ten support skill
replacements and twelve opponent overrides also contain neither value.
General admission belongs to
[Skill-play admission](../../gameplay/characters/ultimate_jutsu.md#skill-play-admission).

ETC's `etc_skill_select_list_row` instead copies the selected
`CollectionSkillListRow.skill` into `CollectionSkillViewer.selected_skill`
and requires `jutsu_skill_classification` > 1 before its playback-selection
state. `etc_skill_play_start` passes that value directly to the constructor.
The viewer-list producer and permitted values remain open.

The constructor does not check an upper bound before indexing the post-override
SINF row. The battle table consequently provides a caller-specific limit,
rather than whole-program proof that the two absent rows are unreachable.
