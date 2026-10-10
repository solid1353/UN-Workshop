# Resident CCS runtime

## Research coverage

Established: retail NA2's container/object lookup, parsing and publication,
cross-container references, reader and caller ownership, load/queue/residency
lifetimes, stream playback, version gates and retail version census, and the
bounded NUN3 reader, wrapper-binding and cross-container resolver comparisons,
plus NUN4's selected unresolved animation-wrapper/evaluator path.
Names and layouts come from
`@annotations/NA2`, `@annotations/NUN3` and `@annotations/NUN4`;
annotations hold the per-routine detail. All addresses are live.

Open: unclassified fields and type-specific consumers, residency activity
counter production, indirect control writers, the two queued `0x0108` values,
selective packed material records beyond the scanned assets, complete delegated
model conversion, downstream animation interpretation, and whole-file
NUN3-to-NA2 loading/playback agreement. Evidence is static and bounded.

## Evidence and scope

This document owns the in-memory resident CCS services of retail NA2
(`SLPS-25837`), with sampled BTL/ETC callers and a NUN3
`SLUS_217.27` parser comparison and a selected NUN4 `SLUS_218.62`
animation-binding comparison. Inputs and address conventions are owned by
[Retail game file identities](file_identities.md#address-conventions).
The retail census reads headers; declared-length walks alone cannot establish
complete consumption because some retail lengths are inaccurate. Selected
overlay operands and literal strings were checked, without establishing
caller serialization or every indirect writer.

Related owners: [CCS object types](ccs_object_types.md) (tags and destructors),
[Resident file and resource services](runtime_services.md) (ROFS/GZLIST,
transport and gzip), [Allocator and capacity](../../runtime/ee_memory_map/allocator_and_capacity.md),
[Ultimate jutsu](../../gameplay/characters/ultimate_jutsu.md),
[Disc files](disc_files.md),
[Animation runtime](../../runtime/animation_runtime.md), and
[Texture and material runtime](../../runtime/rendering/texture_material_runtime.md).
This document does not claim that a NUN3 CCS has been loaded by NA2 or that
matching reader consumption implies identical runtime results.

## Handle layers

Five different objects are called a CCS handle by callers:

| Layer | Layout | Meaning |
| --- | --- | --- |
| Residency entry | `CcsResidencyEntry`, 0x2C bytes | Requested name, state and signed use count; `ccs_residency_acquire` manages it. |
| Load wrapper | `CcsLoadWrapper`, 0x34 bytes | Owns file/read/decompression work while producing a container. |
| Container | `CcsContainer`, 0xC0 bytes | Parsed CCS linked into the global list; returned by `ccs_find_container`. |
| Object record | `CcsRecord`, 0x38 bytes | Directory name, namespace, hash/type and runtime pointers. |
| Runtime object | `CcsRecord.runtime` | Type-specific result of generic object lookup, whose retained annotation name is `animation_find_by_name`. |

`CcsRecord.secondary` is a separate type-specific value, returned by
`ccs_find_secondary` and collected by `ccs_collect_secondary_matches`.
It is not the ordinary runtime object.

## Container and record layouts

### Container fields

The named layout is `CcsContainer`. Its list/name/directory fields establish
identity; work lists establish ownership; playback fields belong to a separate
lifecycle. The important flag contracts are:

| Field | Established bits and state |
| --- | --- |
| `reference_flags` | Bit 0 hints at unresolved cross-container records; older containers can retain it after resolution. Bit 1 permits global dependency-group reconciliation. Reset sets bit 1 and no resident clear was found, so that gate remains open in the resident code. |
| `runtime_flags` | Bits 0/1 are parse milestones; bit 3 selects `play_entries`; bits 2/4 mark frame-stream end; bit 5 marks completed play-state teardown; bit 7 marks a held `0x2200` ring batch. |
| `ownership_flags` | Bit 1 owns `reader`; play bits 0, 2 and 3 own the scene environment, default controller and default extended controller. |
| `parse_state` | 1 while object blocks are consumed, 2 after terminator finalization. |
| `version` | Starts at `0x80`, is replaced from chunk 1, and must be at least `0x90`. |
| `canceled` | Nonzero stops object parsing and prevents publication. |
| `frame`, `last_frame`, `checkpoint_count` | Current frame, tag-5 payload minus one, and header checkpoint count. A zero last frame clears the checkpoint count after parsing. |
| `rate`, `rate_remainder` | Signed 8.8 playback rate and remainder; see [Frame timing](../../runtime/frame_timing.md#streamed-ccs-rate-is-whole-frame-only). |
| `play_control` | Seek, restart and stop requests consumed by the play loop and streamed stepper. |

`ccs_reset_container_and_bind_reader` borrows a supplied reader. With no reader
it allocates a 0x40-byte `CcsReader` and sets reader ownership. Generic
destruction closes/frees the reader only under that ownership bit.

Borrowing does not establish a persistent reader lifetime. An ordinary flag-0
load supplies the wrapper reader and destroys it after parsing, leaving the
container's reader pointer stale. Whole-buffer/play-stream owners retain their
wrapper until seeking is finished, then destroy the container before wrapper
cleanup. A normally resident container's borrowed reader cannot be treated as
a live reader handle.

### Finalization work-list ownership

Directory finalization orders cross-container resolution, the no-op
`ccs_reserved_finalize_hook`, dependency finalization, then secondary-value
finalization. Reset clears all five work-list heads. Surviving nodes stay linked
until their source record's destructor removes them.

| Container field | Lifetime and result |
| --- | --- |
| `copy_fixups` | Temporary `CcsCopyFixupNode` directives. A resolved target receives the 0x30-byte payload at runtime `+0x10`; zero/sentinel-4 targets receive no copy. Every source runtime is cleared and every node freed, then the head is cleared. |
| `dependency_groups` | Retained `CcsDependencyGroup` nodes with allocated halfword index maps; later publication can reconcile their links. |
| `light_secondaries` | Retained nodes whose source secondary is materialized through `ccs_materialize_light_secondary`. |
| `object_secondaries` | Retained nodes whose source secondary becomes a 0x1C-byte object through `ccs_materialize_secondary_object`. |
| `reference_links` | Retained links whose source record is installed in a resolved target's `CcsReferenceRuntime.source_record`. |

The `relation_blocks` vector owns parse-time blocks. Dependency finalization
uses each block's first record index to select a runtime, installs a 0x0C-byte
`CcsRelationData` through `CcsRelationRuntime.relations`, and filters the
0x10- and 0x1C-byte arrays by `ccs_relation_record_eligible`. Every input
block is freed even when its runtime target is absent. Interrupted parsing
leaves any remaining blocks for generic vector destruction.
The copy destination `+0x10` remains type-specific; neither it nor the
reference-link prefix asserts one universal runtime layout.

A `0x0D80` packet with a nonzero animation record ID enters a global pending
list and is later linked into that animation runtime. ID zero instead links
the `CcsGeneratorPacket` to `generator_packets`. Finalization leaves that
container list alone; playback and restart instantiate one 0x10-byte
`CcsActionRunner` per packet in the play context's action manager.
The source record still owns the packet. Its destructor frees the packet even
when it is absent from the global pending list, so the container list can be
stale during teardown; playback has already ended before that happens.

### Object record fields

`CcsRecord` names the directory fields, including `name`,
`namespace_name`, `hash_next`, `name_hash`, `type_tag`, `runtime`,
`secondary` and `transient_play_entry`.

Record zero is reserved by clearing its name and runtime after the directory
read. Destruction starts at record 1. Numeric-ID conversion is unchecked, so
malformed typed blocks can reconstruct record zero and evade that teardown.
Valid files keep record zero unconstructed.

Fixed-width input names must contain NUL: 0x20 bytes for the container and
namespace names, 0x1E for object names. The parser does not force terminators.
The 16-bit namespace index is also unchecked, and record count zero is not
rejected even though record zero is unconditionally cleared and the count
later becomes a hash modulus. These are format contracts, not validations.

`ccs_record_from_index_unchecked` computes the indexed 0x38-byte record.
`ccs_container_owns_record_allocation_address` accepts any address in the
half-open allocation interval, without requiring record alignment.
Consequently, owner lookup identifies the containing allocation rather than
proving a valid record.

### Common runtime-object back-pointer

Record-backed descriptor families use `CcsRuntimeRecordPrefix.record`.
Provider unwrapping, unload invalidation and
`ccs_find_runtime_object_container` rely on that first word. The ownership
wrapper checks no type before reading it; this is not a universal contract for
generic object results or secondary values.

The confirmed exception is the runtime `0x1000` image-transfer group.
`ccs_image_transfer_group_construct` initializes its image/CLUT lists, one
name byte and global next link, but writes no record back-pointer.
`ccs_image_attach_transfer_group` and `ccs_clut_attach_transfer_group`
can publish that node as a record runtime, so ownership traversal and unload
invalidation are unproved for this case. Its partial-name and same-name
attachment contracts are owned by
[CCS object types](ccs_object_types.md#runtime-tag-0x1000-from-texture-and-clut-construction-image-transfer-group).

## Container-name lookup

`ccs_make_container_key` takes the basename after either slash, removes the
final extension only when its dot follows the first basename byte, and
preserves case. A leading-dot basename survives. The copy has no defensive
destination bound; the safe normalized basename is 31 bytes plus NUL.

`ccs_find_container` compares that key with the header name, using
case-sensitive string comparison. A file whose header name differs from its
path is published under the header name and can miss later path lookups.
`ccs_require_container` has the same search but traps through a null store on
a miss.

Publication prepends and does not reject duplicate names. The newest matching
container wins; destruction removes the exact pointer rather than every
same-name entry.

## Object-name lookup

### Exact hash path

The generic lookup's retained name is `animation_find_by_name`; it supports
`ANM_` animation names and all runtime object types without a prefix or type
check. Its path is query adaptation, exact-only selection,
then hashed record matching. Wildcard-bearing queries are rejected. The
exact-only adapter forces external-record resolution off, so the matched
record's own runtime is returned.

The query adapter copies at most 30 bytes and records a wildcard at byte 30.
It zero-fills only after an earlier NUL and has no truncation result.
Wildcards after byte 29 disappear; a wildcard in an unterminated 30-byte query
can make the matcher scan beyond its query object. The safe object-name query
is 29 bytes plus NUL.

Linear non-wildcard matching compares all 30 name bytes, while hash matching
stops at NUL. A name with nonzero bytes after an early NUL can therefore match
the hash path and fail collectors. Consistent names must be NUL-terminated and
zero-padded through the entire name field.

`ccs_hash_object_name` XORs each signed byte, shifted by
`(byte & 7) + 2`, with a running step that advances by `0x40F9`; the
returned hash is 16 bits. The finalizer sorts packed hash/index words unsigned
and builds equal-hash chains in ascending record-index order. Duplicate object
names select the lowest matching index. Only 16 index bits survive that packing:
at most 65,536 records is an unchecked format contract.

Record zero participates in hashing. An empty query matches its empty name and
returns zero without taking a record-miss trap. The lookup's third argument
controls only that trap: zero is required; nonzero is optional. A matched
record can still return zero or unresolved sentinel `4`, and there is no
generic expected-type assertion. Callers depend on naming and load order.

### Thin and batch wrappers

`ccs_find_object_optional` and `ccs_find_object_required` select the two
miss conventions and return the generic result. `ccs_resolve_object_batch_optional`
produces one slot per `CcsObjectSpec`, reusing a container when consecutive
spec pointers are identical. A spec beginning with `#` indexes the caller's
path table using a parsed decimal index. Both that index and the vector getter
are unchecked.

Missing containers or objects become zero slots. Fifth-argument bit 0 cannot
detect those misses for ordinary nonnegative counts: the output count advances
for every requested row. `ccs_object_vector_clear` frees and resets the
result. The observed resident batch caller supplies seven direct specs; it
does not establish use of the indexed form.

### Wildcards and secondary values

Secondary lookup tries exact hash matching, then a linear/pattern fallback.
Only the fallback and collector skip `#` namespace rows; an exact hash hit
has no marker test. Required/optional means record miss here too.

`*` accepts an arbitrary span. `?` is asymmetric: at the first byte of
the source or a segment after `*`, the helper tests the source against
`?`, making the query character literal there; later positions treat it as
a one-byte wildcard. Matching remains case-sensitive.

Fallback starts at record zero. Pattern `*` normally selects its empty
name and zero secondary first, and the collector can append an initial
`(0,0)` value/type pair. Collected pairs are deduplicated solely by pointer.

When `runtime_flags` bit 3 is clear, secondary lookup returns
`CcsRecord.secondary`. While set, it selects `CcsPlayEntry.value` and
the collector reports that entry's provider type. The play builder unwraps
provider records, snapshots the secondary and type, initializes the
`type_specific` word to zero, and owns only rows whose entry flag bit 0 is
set. Unresolved providers produce zero provider pointers.
`transient_play_entry` links are cleared before publication.

Publication sets bit 3 before storing `play_entries`, without a local lock.
Setup therefore requires caller serialization until the builder returns.
A stop request clears bit 3 but does not free the table; full play teardown
clears the selector before destroying owned rows and freeing the table.
`ccs_play_lock_waiter` only waits for primary-task state 2, which follows
normal play teardown; it does not build or own the table.

For reader state 1 or 2, the builder allocates and zeroes the checkpoint table
and seeds row zero from `terminator_position`. Even a zero-byte allocation
gets the allocator's minimum block and that initial write; a zero checkpoint
count still is not a safe playback contract. Marker stores check the count,
but playback target indexing does not: the forward cap is `last_frame`.
Every target, including the inclusive last frame, must fit the table.

Frame markers replace the range cursor; ordinary blocks do not advance it.
No monotonicity check ensures eventual progress. A backward seek scans down
without a lower-bound check and therefore requires a nonzero row-zero fallback.
Play teardown owns and clears the checkpoints before destroying play entries.

### Type-`0x0A00` traversal

Linear/pattern lookup normally follows `CcsExternalRuntime.owner_link`
through that linked record's runtime and first-word record pointer until the
type is no longer `0x0A00`. A zero or sentinel-4 intermediate fails.
The current external runtime and link are dereferenced before such a guard,
and there is no visited set or hop limit. Valid inputs must form a live,
acyclic reference graph.

A query beginning `EXT_` instead requires the original external record and
does not unwrap it. The external parser changes only the first three name
bytes to `EXT`, leaving byte 3 untouched; the bypass consequently depends
on the original underscore.

The parser makes a 0x20-byte runtime with its record and two record links.
When replacing a `0x2000` placeholder it retains four words in the
named `preserved_08/14/18/1C` fields before freeing it. The `#`
namespace marker and external type tag are separate tests.

### Animation wrapper resolution

NA2 `animation_attach` (`0x001B99B0`) applies
`ccs_resolve_external_record_chain` (`0x00116210`) to every retained
animation record/key pair. A zero result initializes the play entry's target,
provider, type, flags and evaluator to zero. A usable `0x0100` provider can
instead create a scene child and its model when no existing composition child
binds it. These are consumer-specific branches, not a promise that every
unresolved CCS record can be omitted safely.

The own-game NUN3 comparison establishes the same wrapper-target guard and
empty-entry branch in `ccs_resolve_external_record_chain` (`0x001123A0`)
and `model_bind_animation` (`0x0016F640`). Its
`ccs_parse_external_record` (`0x00167E10`) consumes wrapper/parent/target
IDs and stores the target at runtime `+0x10`, as NA2 does.
`ccs_parse_animation_tracks` (`0x00156410`) retains eight-byte record/key
pairs at animation `+0x1C`, count `+0x20` and relations `+0x28`;
NA2 uses `+0x18/+0x1C/+0x24`. NUN3 relation construction additionally
handles `0x0D00/0x0E00` sources; NA2 handles `0x0100/0x0A00`.
NUN3's `ccs_parse_scene_object` (`0x00167C60`) has an extra list word,
placing its ordinary model at `+0x10` rather than NA2's `+0x0C`.

NUN4 `ccs_parse_external_object` (`0x001B5F70`) likewise stores the
target record at wrapper runtime `+0x10`. Its
`ccs_resolve_external_record_chain` (`0x00116A50`) returns zero for
a target runtime of zero or sentinel 4. `animation_attach`
(`0x001BD710`) then clears the play entry and does not create its typed
evaluator. `animation_evaluate_typed_tracks` (`0x001BC0B0`) skips an
entry whose evaluator at `+0x0C` is zero. The concrete undefined guard
tracks and the extracted-provider search are owned by
[Shizune/Kabuto effect providers](../../gameplay/characters/nun4/shizune_kabuto.md#code-selected-ordinary-jutsu-effect-providers).
This establishes that selected absent edge's binding/evaluation branch;
it does not extend the conclusion to every CCS consumer.

The selected retail wrapper/animation/provider chains are owned by
[Marked character-reference consumers](../../gameplay/characters/nun3_nun4_characters.md#marked-character-reference-consumers).
Binding snapshots the available provider; later directory resolution alone
does not establish repair of an already empty player entry.

## Parsing, type dispatch, and publication

`ccs_parse_container` reads the decompressed stream in order:

| Part | Consumption and gate |
| --- | --- |
| Chunk 1 | Low halfword 1; discard length and the following `CCSF` dword; then the 0x20-byte name, version halfword, one discarded halfword, checkpoint-count dword, extension count and its discarded dwords. A first dword equal to `CCSF` traps. |
| Chunk 2 | Low halfword 2; discard high halfword and length; read namespace/record counts, 0x20-byte namespace rows and 0x20-byte record rows (30-byte name plus namespace index). |
| Chunk 3 | Low halfword 3; discard high halfword and length. |
| Typed blocks | 8-byte header: tag halfword, discarded high halfword, payload dword count. The selected handler receives that count multiplied by four. |
| Tag 5 | Read one dword `n`; set last frame to `n - 1`, finalize the directory and publish unless canceled. |
| Frame stream | Playback files continue with later frame dispatch. |

The consumed `CCSF` payload is not validated as a signature. The only
chunk-1 value gate is version at least `0x90`; extension words are not kept.
Object lengths matter according to the handler: blobs, expanded generator
packets and temporary model-conversion input use them for copy/allocation,
while other handlers consume internal-count layouts. There is no generic
seek-to-end or unknown-tag skip. An unknown tag traps. Each handler must leave
the reader at the actual next header.

Retail lengths are not uniformly exact. A `HOME.CCS` `0x0800` block
declares `0x386` payload dwords but its next header is four bytes earlier.
Declared-length walks also lose synchronization after some `0x0300` and
`0x0800` blocks. Chunk-3 and tag-5 high halves can be zero rather than
`0xCCCC`. Every one of NA2's 2,310 files has one extension dword and
chunk-1 length `0x0D` dwords.

Finalization hashes/sorts records, builds buckets, resolves references and
dependencies, installs secondary values, and sets parser state 2.
Publication prepends only while cancellation is zero. Publication and
cross-container resolution use the interrupt synchronization pair.
The complete tag/destructor ledger belongs to [CCS object types](ccs_object_types.md).

## Cross-container references

The resolver considers `#` namespace rows with sentinel-4 runtimes.
Provider matching compares the stored hash, namespace text after its marker,
and inline object name. Success copies the provider type and runtime, never
its secondary value. Generic lookup therefore sees the provider runtime,
whereas an exact secondary hit can return the consumer's own usually-zero
secondary. Fallback/collectors skip marked rows. The play builder separately
unwraps and snapshots the provider secondary.

Provider matching does not require a direct non-`#` row or a ready runtime.
A name match counts as success even when it copies zero or `4`.
Copying zero removes the row from subsequent sentinel-based attempts.
Reference chaining and provider readiness are load-format/order contracts.

The lowest matching record index wins within a provider directory. Across
already-published containers, the newest matching provider wins.
Resolution runs both ways between a new directory and older eligible
containers; the new unresolved hint reflects its own remaining records, while
older hints can remain sticky after success.

Own-game NUN3 `ccs_resolve_cross_container_refs` (`0x001634A0`) and
`ccs_match_cross_reference_provider` (`0x00162930`) agree in the checked
sentinel/marker, hash/namespace/name, two-direction search and type/runtime
copy behavior. Neither resolver requests files. This comparison does not
establish every provider's readiness or lifetime in either game.

Before matching, every non-sentinel record's namespace marker becomes space.
Namespace strings are shared by index, so this changes every record using
that row. The parser does not validate compatible resolution states among
those uses.

Retail namespace text retains source paths. `PL/1NRTBOD1.CCS` uses
` c\1nrt\max\1nrtbod1.max`; the jutsu stream refers to marked
`#c\1nrt\max\1nrtbod1.max`, `#c\2nrt\max\2nrtbod1.max`
and `#c\1cmn\max\1cmnbod1.max`.
NUN3's body namespace strings agree, with an extra
` x\name\nrt\name.bmp` row.

Unload scans surviving marked rows and invalidates those whose runtime
record prefix lies in the departing record allocation: runtime becomes
sentinel 4, type becomes zero and unresolved state propagates.
There is no type check before that prefix read; the guarantee does not extend
to image-transfer groups.

## Format versions and NUN3 comparison

### Version gates in the NA2 parsers

Thresholds below are the first version taking the newer branch of
`CcsContainer.version`:

| Parser | File tag | Version thresholds |
| --- | --- | --- |
| `ccs_read_header` | chunk 1 | `0x90` required; lower traps |
| `ccs_parse_scene_object` | `0x0100` | `0x96`, `0x122` |
| `ccs_parse_material` | `0x0200` | `0x120` |
| `ccs_parse_image_block` | `0x0300` | `0x90`, `0x92` |
| `ccs_parse_clut_block` | `0x0400` | `0x90`, `0x92` |
| `ccs_parse_animation_tracks` | `0x0700` | `0x120` in nested tag `0x0201`, through `ccs_dispatch_packed_tracks -> ccs_pack_tag_0201` |
| `ccs_parse_model` | `0x0800` | `0x100`, `0x111`, `0x121`, `0x122`, `0x123` |
| `ccs_parse_morpher` | `0x0900` | `0x110` |
| `ccs_parse_generator` | `0x0D90` | `0x123` |
| `ccs_parse_effect` | `0x0E00` | `0x122` |
| `ccs_frame_tag_0201` | frame tag `0x0201` | `0x120` |
| `ccs_frame_tag_1a01` | frame tag `0x1A01` | `0x111` |

The gates cover every resident version halfword read, including reused model
comparisons. Per-type gated meanings belong to [CCS object types](ccs_object_types.md).
**Inference:** NA2 accepts the interval from `0x90` through at least
`0x123`; with no higher gate, newer versions would take the `0x123`
branches. That does not establish their layouts.

### Animation-track parsing

The animation wrapper's retained name is `ccs_load`. It reads record ID,
frame count and track-storage count, constructs the descriptor and delegates
to `ccs_parse_animation_tracks`. Packed dispatch receives the container
version separately from the frame-count limit used by typed keys.

The complete dispatch has two marker routes, twelve snapshots and eight
typed-key routes; unknown tags trap. Tag and length are copied to packed
output, while the high marker halfword is crossed by four-byte reader/output
alignment. Actual handler consumption determines the next command.

| Tag | Annotation routine (NA2 / NUN3 where different) | NA2 live address | NUN3 live address |
| --- | --- | --- | --- |
| `0x0101` | `ccs_pack_tag_0101` | `0x001A8A10` | `0x0015E6F0` |
| `0x0108` | `animation_payload_parse` / `ccs_pack_tag_0108` | `0x001A8C10` | `0x0015EF00` |
| `0x0201` | `ccs_pack_tag_0201` | `0x001A8220` | `0x0015C760` |
| `0x0502` | `ccs_pack_tag_0502` | `0x001A8900` | `0x0015E2A0` |
| `0x0601` | `ccs_pack_tag_0601` | `0x001A88D0` | `0x0015E210` |
| `0x0602` | `ccs_pack_tag_0602` | `0x001A8840` | `0x0015DF00` |
| `0x0604` | `ccs_pack_tag_0604` | `0x001A8770` | `0x0015D990` |
| `0x0606` | `ccs_pack_tag_0606` | `0x001A86A0` | `0x0015D420` |
| `0x0608` | `ccs_pack_tag_0608` | `0x001A8610` | `0x0015D070` |
| `0x0802` | `ccs_pack_tag_0802` | `0x001A8530` | `0x0015CD50` |
| `0x0803` | `ccs_pack_tag_0803` | `0x001A8470` | `0x0015CB00` |
| `0x1901` | `ccs_pack_tag_1901` | `0x001A8B60` | `0x0015EC60` |
| `0x0102` | `ccs_pack_tag_0102` | `0x001A8000` | `0x0015C470` |
| `0x0202` | `ccs_pack_tag_0202` | `0x001A7D70` | `0x0015C110` |
| `0x0503` | `ccs_pack_tag_0503` | `0x001A7740` | `0x0015B6D0` |
| `0x0603` | `ccs_pack_tag_0603` | `0x001A7C80` | `0x0015BF50` |
| `0x0605` | `ccs_pack_tag_0605` | `0x001A7AF0` | `0x0015BCF0` |
| `0x0607` | `ccs_pack_tag_0607` | `0x001A7960` | `0x0015BA90` |
| `0x0609` | `ccs_pack_tag_0609` | `0x001A7830` | `0x0015B890` |
| `0x1902` | `ccs_pack_tag_1902` | `0x001A7520` | `0x0015B3E0` |

Marker tags `0xFF01` and `5` each copy one dword. Both games agree in
marker compaction, first-nonzero start selection, loop flag and distinct-ID
limit, at different descriptor offsets. Snapshot/key handlers agree in field
widths, masks, counts, alignment, ID remapping and channel order.

Only packed `0x0201` receives the version: it reads ID/flags, then floats
for clear bits `1,2`, adding clear bits `4,8,0x10,0x20` at
`0x120`. The paired NUN3 handler has the same gate. The other packed
handlers neither receive nor read it.

Curve readers have the following matching input contracts in both games.
`U` is a four-byte integer and `F` a float. Counted positive curves have
a preceding `U count`, then each key begins with `U time`.

| Annotation reader | Selector | Input |
| --- | --- | --- |
| `ccs_read_scalar_curve` | low three bits 1 / 2 / other | One four-byte value / counted `{U time,F value}` / none |
| `ccs_read_word_curve` | low three bits 1 / 2 / other | One `U` / counted `{U time,U value}` / none |
| `ccs_read_vector_curve` | 1 / 2 or `0x12` / 4 / other | Three components / counted `{U time,3F}` / counted time plus ten components / none |
| `ccs_read_rotation_curve` | 1 / 2 or `0x12` / 4 or `0x14` / other | Three components / counted Euler-degree triples / counted four components / none |

Selectors `0x12/0x14` compress the runtime form, not the file into
halfwords. Initial time precedes loops, and some selector-2 readers fetch an
initial value before later keys; this is not a malformed/zero-count contract.
Generated padding and rotation conversion consume no extra file bytes.
Reader agreement does not establish all downstream interpolation.

Both NA2 ID helpers deduplicate `ID*4+1` in the shared scratch table
`ccs_animation_track_scratch`. Snapshots store the resulting track index,
keys attach separate descriptors, and track finalization makes eight-byte record/key rows
plus a halfword relation map. A post-dispatch count at least `0x400`
traps; the insertion helpers do not enforce it. Accepted data has at most
1,023 distinct IDs.

Consecutive frame markers compact the packed cursor by 12 bytes. The first
nonzero marker selects `CcsAnimationDescriptor.reader_start`; marker -2
sets descriptor flag bit 1 for looping. Tag equality does not imply packed
and streamed layouts match: packed object snapshots select individual float
fields, while streamed object snapshots group position/scale and always read
Euler, alpha and visibility.

### Packed material snapshot masks and cursor ownership

**Established:** the packed material parser tests clear bits `1..0x20`;
the streamed consumer tests `2..0x40`. Both expand from two to six fields
at version `0x120`, and the flag word passes between them unchanged.

ID remapping changes the ID, not flags. Word/float packing advances output and
copies without arithmetic; refilling changes transport pointers rather than
payload values. Descriptor finalization builds relations without rewriting the
packed stream. `animation_attach` binds the player reader to
`reader_start`; `animation_advance_position` temporarily installs its
reader/table in the container and invokes streamed dispatch, then restores the
previous reader. Dispatch discards length rather than seeking past a consumer.
The material consumer reads all selected floats before target lookup, so an
absent target cannot repair the mask shift.

For unchanged bits `b_i`, consumer bytes minus parser bytes are
`4*(b_0-b_6)` at/after `0x120`, and `4*(b_0-b_2)` before it.
Equal counts alone do not establish equal field assignment. Six-field patterns
agree only when bits 0..6 are all equal: zero reads all, all seven set reads
none. These are static mask consequences, not observations of selective
authored records. The streamed coordinate formulas are owned by
[Texture and material runtime](../../runtime/rendering/texture_material_runtime.md#material-binding-and-coordinate-updates).

#### Authored all-fields snapshots

The bounded scan found 31 real packed `0x0201` records, all flags zero,
confirmed by complete nested-command walks ending at the declared endpoint
and `0xFF01/-1`. Each payload is eight dwords: ID, flags and six floats.

| Directory below the retail DATA view | Files searched | Confirmed `0x0201` records |
| --- | ---: | ---: |
| `PL/` | 325 | 15 |
| `BUDDY/` | 98 | 0 |
| `CMN/` | 6 | 16 |
| `STAGE/` | 24 | 0 |
| `CUTIN/` | 37 | 0 |
| `PUPPET/` | 46 | 0 |
| `3BSC/` | 9 | 0 |
| `3EYE/` | 157 | 0 |

All 702 immediate files decoded. The scan used the authored `CC CC`
header convention and excluded root/other directories; it establishes no
whole-disc absence or gameplay selection.

| File / animation | Established stream | Material |
| --- | --- | --- |
| `PL/2HAKCHA0.CCS`, ID 5, `ANM_2hak_metu_0` | Version `0x123`; 426-dword animation payload; 15 frames; markers 0..14,-1; 15 each of material and object snapshots | ID 3, `MAT_2hakmetu0` |
| `CMN/EFFECT0X.CCS`, ID 327, `ANM_e0x_bom_02` | Version `0x123`; 454-dword payload; 16 frames; markers 0..15,-1; 16 each of material and object snapshots | ID 325, `MAT_e0xbom01b` |

The first material tuple is `(0.125,1,0.390625,0.25,0,1)` in the first
file; later snapshots vary only its first two values. The second file begins
`(0.00390625,1,0.25,0.25,0,1)`, then varies the first coordinate by
`column*0.25` and the second as `1-row*0.25` in a four-by-four sequence.
Both readers consume the tuples unchanged.

Each stream repeats a 12-byte marker, 40-byte material snapshot and 60-byte
object snapshot. Object snapshots have flags zero and thirteen payload dwords:
ID/flags, ten floats and a trailing word. No typed keys occur.
The first material target becomes packed track 0 and the object target track 1;
track zero is distinct from reserved directory record zero.

The first nonzero marker is frame one, after 112 packed bytes, so retained
reader start is descriptor `+0x9C`. This is separate from the final output
cursor; in-place resize does not move or convert the payload.
Source material coordinate halfwords `(512,4096,1600,1024)` and
`(16,4096,1024,1024)` equal the first all-fields tuples after the
established coordinate formulas. This is byte/arithmetic agreement, without
establishing author intent or whether frame zero is dispatched.

Every confirmed record avoids the shift by selecting all fields.
A selective record would be misread; none was found in this bounded scan.
The inspected direct-call census has only the resident packed dispatch and
streamed dispatch consumers, with no BTL/ETC direct calls; computed calls and
unexamined payload writers remain outside that bound.

### Versions in the retail files

Chunk-1 versions of every extracted retail `.CCS`:

| Game | Files | Versions |
| --- | ---: | --- |
| NA2 | 2,310 | `0x123` except `STR/ATTENTION.CCS` (`0x120`) |
| NUN3 | 2,400 | 2,348 `0x123`; 41 `0x111` (card images and `XLANGUAGE.CCS`); 10 `0x120` (`1CMNBOD1.CCS`, eight `RPGF/FRPG*.CCS`, `STR/ATTENTION.CCS`); 1 `0x122` (`RPGF/FRPGPKN.CCS`) |
| NUN4 | 4,031 | 4,029 `0x123`, 2 `0x120` |
| NUN5 | 3,552 | 3,551 `0x123`, 1 `0x120` |

All recorded versions fall inside NA2's accepted interval.

### NUN3's parser compared with NA2's

NUN3's `ccs_parse_container` agrees in the three chunk frames,
`CCSF` trap, minimum version and ignored marker/section-length fields.
Its typed dispatcher has the same 34 object/control routes and terminator,
unknown-tag trap and byte-length argument. Its terminator stores payload minus
one. The larger runtime container differs; `Nun3CcsContainer.version`
is at `+0x20C`.

All 35 outer routes agree in direct field order, widths, internal-count loops,
alignment and thresholds, including the four draw-environment thunks.
This covers length-driven `0x2300/0x2400` copies, expanded `0x0D80`
packets, `0x1F00` conversion, compositions, generators, collision and
packet streams. Model wrappers consume the same prefixes, with additional
NA2 flag decoding, including the `0x123` two-bit field in the second extra
byte. Animation wrappers consume the same three dwords before delegating.

Two model reader pairs were followed through direct reads:

| Pair | Matching consumption |
| --- | --- |
| `ccs_read_model_vertex_arrays` | Ordinary `(flags & 0x804)==0`: three halfwords per vertex then four-byte alignment; one dword per vertex for arrays whose suppress bits `0x40,0x200,0x400` are clear, in that order. Bit 1 discards the `0x200` array instead of storing, without suppressing reads. |
| `ccs_read_model_mesh_aux` | Zero auxiliary count: one dword then three halfwords per vertex and alignment. Nonzero: eight bytes per auxiliary entry. Both then read one dword per selected entry and one per vertex. |

NUN3's first helper has a `0x804` branch without position reads, where
NA2 traps. Its reachability through the outer model parsers is open.
`ccs_convert_packed_model_mesh` and special model modes remain only
partially compared.

Matching reads still produce these demonstrated runtime differences:

- NUN3 `0x0100/0x0700` objects have an extra list-link word; other
  compared NUN3 type-list insertions also have no matching NA2 insertion.
- With `0x0D90` payload byte `+0x09` high nibble zero, NA2 frees the
  constructed generator and clears its record runtime; NUN3 retains it.
- A new ordinary `0x0300` image in NA2 compares declared data against four
  times its computed storage count, stores or discards the declared words and
  fills the remaining count with `0xFFFFFFFF`. NUN3 stores all declared
  dwords directly. Both consume the declared number of dwords.

**Inference, medium confidence:** agreement extends beyond framing to direct
outer reads, packed curves and streamed payloads. Complete delegated conversion,
object interpretation and loading/playback agreement remain unproved.
Handler consumption, rather than inaccurate length fields alone, is required
to assess the format.

## Loading and cancellation

`ccs_load_if_absent` returns zero when its precheck finds an existing
container; it neither returns nor retains that handle. An absent container is
loaded through a heap wrapper, detached and returned. File-open and rejected
CCS framing/tag paths trap rather than providing a recoverable zero error.

Observed convenience callers use flags zero. The wrapper is freed only when
the argument equals zero; a nonzero convenience call loses its wrapper, and
bit `0x100` also retains transport resources. It is therefore not a safe
general retained-load interface.

The precheck recognizes only backslash separators and literal lowercase
`.ccs`, limits its derived key to 29 bytes, and does not stop at source
NUL. Missing/lowercase-mismatched suffixes can scan beyond the string.
It runs before the pipeline gate and there is no second absence check:
concurrent callers can both pass, load serially, then publish duplicates that
shadow by prepend order.

`CcsLoadWrapper` names the file, metadata, direct/compressed transports,
reader, bridge/task, block settings, buffer, cancellation/completion bytes and
produced container. Defaults are four input/output blocks of `0x10000`.
Zero file metadata selects direct input to the decode reader; nonzero adds
gzip transport, but the parser always sees that same wrapper reader.

The read/gzip/decode tasks are internally asynchronous; their coordinator is
externally blocking. The global mode byte is 1 for ordinary loading and 2 for
the persistent player. Both acquire zero under the same synchronization pair.
The ordinary path waits for read/decode completion, closes the file, and clears
the gate before its gzip-completion/cleanup tail, so the gate does not cover
every transport object's lifetime.

Exact flag `0x100` selects a whole-file buffer; its bit suppresses ordinary
temporary cleanup. Later `ccs_destroy_load_wrapper_resources` frees
retained transports but never the produced container. It leaves destroyed
pointers stale, closes no file, and joins no read/decode workers: it is a
one-shot destructor for callers that already completed those responsibilities.
Observed direct coordinator flags are zero or exact `0x100`; no mixed-bit
caller was found. The stream player explicitly destroys retained containers
before wrapper cleanup.

Cancellation sets both wrapper and allocated container cancel bytes.
Decode checks before parsing, and typed dispatch between blocks; read/gzip do
not directly test cancellation. The coordinator still waits for completion.
Cancellation before the terminator prevents finalization/publication; a late
race can leave a published container for the residency load owner to destroy.

The queue stores borrowed paths, exact-case duplicate identity and an embedded
wrapper. Its caller must preserve the path until consumption.

| `CcsQueueNode.state` | Meaning |
| ---: | --- |
| 0 | Queued |
| 1 | Loading |
| 2 | Blocking pipeline returned for an absent path; no separate publication check or retry |
| 3 | Path was already resident |

The worker processes serial blocking loads. Start argument 1 enables file-size
and aggregate-progress accounting, without changing ownership or cancellation.
Its active-node, stop and progress fields are in `CcsQueueWorkerTask`;
no resident stop-field writer was found in this family.

An inactive worker pointer does not mean the list was freed. Completed nodes
retain wrappers until callers adopt published containers and clear the queue.
Normal starts reset the cleanup mode byte to zero, detaching and retaining
containers. A nonzero cleanup mode would destroy produced containers, but no
resident writer enabling it was found. Queue cleanup checks no worker state;
waiting before freeing nodes is a caller contract.

The residency batch path separately drains state-1 entries and promotes
deferred state-2 entries for a later pass.

## Residency use count and release

The low-level container has no proven reference count.
`CcsResidencyEntry.use_count` is a signed halfword for participating
registry clients only. Its other named fields hold an exact requested name,
load state, allocation origin and previous/next links.

Registry names use direct case-sensitive comparison and unbounded copy, with
31 bytes plus NUL available. The missing-load stack copy appends `.ccs`
unconditionally and safely fits only 27 key bytes plus NUL.
Callers therefore require an extensionless bare key. Two exact registry keys
such as `foo` and `dir/foo` have separate counts but normalize to the
same container; releasing either can destroy it while the other still has users.

| State | Meaning |
| ---: | --- |
| 0 | Inactive/suppressed linked entry. Acquire does not increment or load, ordinary named release skips it unless forced; no resident producer was found. |
| 1 | Pending current batch |
| 2 | Deferred to a future batch |
| 3 | Settled |
| 4 | Loading |
| 5 | Cancellation during final state-4 release; the ordinary release immediately unlinks it |

A new acquire starts count 1 in state 1 or 2; an existing nonzero-state entry
increments without overflow/underflow guards. Ensure-loaded sets state 4,
adopts an existing container or loads the suffixed path, then settles to 3/5.
The not-pending query accepts missing names as well as state 3; its null-name
branch reports manager/worker activity rather than name readiness.

Release decrements unless forced and retains positive counts. Final state-4
release cooperatively cancels and sets state 5; other final releases look up
the current container by name and destroy it. Unlinking returns checked-out
inline entries to the 64-slot pool and frees heap-overflow entries.
The worker's state-5 scan has no ordinary producer leaving such an entry linked.

`CcsResidencyManager` names its flags, stop/cancel bytes, entry count,
head/tail, inline entries, cached free entry, active wrapper and signed counters.
Flag bit 0 serializes a load; bit 2 marks batch activity.
`activity_count` is initialized to zero and only its positive test in the
aggregate query is established. No producer was found in the bounded
resident/BTL/ETC direct-displacement audit; indirect/rebased writes remain open.
`batch_workers` is incremented/decremented by batch start/finish.
The batch worker uses the singleton manager rather than the start call's
manager argument. A zero acknowledgement-mode byte waits for external
acknowledgement or abort; nonzero permits immediate teardown.

Entries store no container pointer and discover no direct owners. Final
release repeats name lookup, so a newly prepended duplicate can cause it to
destroy a different instance from the originally adopted one. Name uniqueness,
consistent registry keys and publication/unload serialization are higher-level
contracts.

### Low-level destruction

`ccs_destroy_container` performs full teardown only for a listed or canceled
container. It invalidates external references, releases ordered controllers,
owned readers and temporary allocations, destroys records 1..count-1, and
frees buckets, records and namespaces. An unlisted non-canceled container
reaches only relation-vector destruction and optional storage free.
Every observed resident caller requests storage free.

Generic destruction owns no play-entry/checkpoint teardown and does not stop
the play task. Normal playback reaches its separate teardown before retention
destroys the container; the generic destructor does not enforce that order.

`ccs_destroy_record` dispatches type-specific, direct or virtual destruction.
Marked reference rows skip dispatch but still clear runtime and secondary,
leaving the provider object owned by its provider. No generic object retain
counter was found. The container destructor itself has no matching publication
lock in this bounded slice.

## Streamed playback (SP Skill Play)

### Who plays CCS files

The bounded direct-call census finds one play-builder caller,
`ccs_play_decode_worker`, and no BTL/ETC/ADV direct caller.
The persistent player's owner is `sp_skill_play_task`, created by
`sp_skill_play_start` and reached from BTL and ETC.

The ultimate jutsu cutscene is the only battle use found for this play runtime.
Stage, fighter, HUD and other battle containers use ordinary lookup-built
objects; they have no play context, alternate table or checkpoints.
The bit-3 secondary selector consequently belongs to played containers.
Transport rings, `PlayRead/PlayGzip` and the request rows are owned by
[Persistent three-task pipeline](runtime_services.md#persistent-three-task-pipeline).

### Request-table source

`sp_skill_relocate_request_table` requires `strmcmn.ccs`, resolves
`BIN_strtbln4` and relocates its `0x2400` object's inline SINF bytes.
The relocated row pointer is published as `sp_skill_request_rows`.

Retail `STRMCMN.CCS` is 452,360 bytes decompressed; directory record 405 is
`BIN_strtbln4`. Its payload declares `0x5878` bytes including the ID,
with a `0x5874`-byte SINF blob. The relocated request data contains:

| Data | Retail count / contract |
| --- | --- |
| Extra resident paths | 38 four-byte entries; string-base relocation |
| Stream path pairs | 184 eight-byte pairs; both words receive string-base relocation |
| Skill rows | 184 `SpSkillRequestRow` rows, 0x18 bytes each; main path and indexed extra/pair references relocate |
| String pool | Header offset plus four supplies the string base |

Skill rows contain the main path, extra-path count, stream count and relocated
extra-path/pair pointers. The stream filename is the pair's second word and
would repeat when its count exceeds one. All 184 retail rows have extra counts
0..2 and stream counts 0..1: at most three resident requests and one streamed
request.

| Row | Main | Extra resident paths | Stream |
| --- | --- | --- | --- |
| 1 | `str/d01_10e.ccs` | `pl/2nrtbod1.ccs` | `str/d01_10.ccs` |
| `0x20` | `str/d14_20e.ccs` | `pl/1tovbod1.ccs`, `pl/1tyobod1.ccs` | `str/d14_20.ccs` |
| `0xB7` (last) | `str/d12_11e.ccs` | none | `str/d12_11.ccs` |

Display and contest data are outside this document's ownership.

### Request list

The skill player is 0x2E0 bytes with two rings of four `0x10000` blocks.
Its request list contains eight-byte `CcsPlayRequest` rows:
resident paths have `0x1000`, the main first except skill `0x20`;
streams follow, first `0x400` and additional ones zero.

A selected override replaces the stream path and derives the main by replacing
`.ccs` with `e.ccs`. Retail `D01_10.CCS` and `D01_10E.CCS`
are 5,579,180 and 413,428 bytes decompressed.
**Inference:** the smaller E file is an ordinary resident load and the base
file is streamed.

The player first loads missing resident requests with flag zero, retaining at
most 16 wrappers; already-resident containers are borrowed. Nonresident rows
are registered for streaming, except flag `0x100` or `whole_file`
requests first load a retained whole-file container.
It then takes pipeline gate 2, allocates two 0x40000-byte rings aligned to
0x80, and starts the three play workers.

After read/decode completion it destroys `0x80` request containers and
containers it loaded into wrapper slots, then frees those wrappers.
It waits for read/decode tasks, releases the gate and destroys the player.
Containers already resident remain resident.

### Player controls

Construction clears `play_flags`, `stop_latch`, `skip_latch` and
`whole_file`; ordinary skill construction/task setup leaves those values.
The bounded direct-displacement audit found only the constructor clears of
play flags and whole-file mode. Indirect/rebased writers remain open.
Ordinary request construction uses `0x1000/0x400/0`, without requesting
`0x100` retention.

`ccs_stream_player_latch_stop_skip` independently writes
`(request & 0xFF) + 1` only while each latch is zero.
Decode clears the current-scene stop latch after a request, allowing reuse;
skip stays latched for the player lifetime.
Effects are owned by the
[Ultimate Jutsu presentation state machine](../../gameplay/characters/ultimate_jutsu.md#presentation-state-machine).

### Per-request lifecycle in `PlayDecode`

For each request, decode constructs/parses a streamed container over the
decoded-ring reader unless a whole-file container was supplied. Publication
resolves its marked references against already-resident fighter/effect data.
It builds the play runtime with `primary_draw_environment`, then calls
the player's begin callback.

Flag `0x400` sets `0x4000` and holds the first stream until released.
Play starts with flags `play_flags | 4 | (request_index << 16)`.
Decode waits for completed-teardown bit 5, asking play to stop when the frame
stream ended with neither play bit 0 nor 2, or when stop latch is 1 or 3.
Bit 0 makes the loop restart instead of ending.

After a request, retention bytes through the current request count down.
Zero destroys the corresponding container. Registration initializes retention
from the low four request-flag bits; flags `0x80/0x100` use
`0xFE/0xFF` sentinels that do not count down. A flag-zero stream is
destroyed after its own playback. Decode advances, or jumps to the end when
stop latch is at least 2.

### The play task

Each primary step advances streamed frames, updates generator actions, invokes
the frame and per-object callbacks, submits the scene and yields once.
Generator updates receive the signed 8.8 rate as a raw pass count:
`0x100` produces 256 action passes, although it advances one frame.

Stopping releases a held ring batch, calls the end callback and destroys play
state before primary task state 2 and container completed bit 5.
The container itself remains for request retention to destroy.

Play teardown frees checkpoints, releases light secondaries from the scene,
frees context object lists and owned table rows, destroys its owned controllers
and scene environment, clears their ownership bits, destroys the action
manager and frees the 0x120-byte play context.

### Frame stream

Frame headers reuse the eight-byte framing. Marker `0xFF01` updates
the logical frame/checkpoint; terminator 5 can be encountered when seeking
checkpoint zero. Other supported handlers are:

| Frame tag | Annotation routine in both games | NA2 live address | NUN3 live address |
| --- | --- | --- | --- |
| `0x0101` | `ccs_frame_tag_0101` | `0x001B5900` | `0x0016B1F0` |
| `0x0108` | `ccs_frame_tag_0108` | `0x001B69B0` | `0x0016C3C0` |
| `0x0201` | `ccs_frame_tag_0201` | `0x001B5400` | `0x0016AC80` |
| `0x0502` | `ccs_frame_tag_0502` | `0x001B5D50` | `0x0016B660` |
| `0x0601` | `ccs_frame_tag_0601` | `0x001B5F70` | `0x0016B860` |
| `0x0602` | `ccs_frame_tag_0602` | `0x001B6020` | `0x0016B930` |
| `0x0604` | `ccs_frame_tag_0604` | `0x001B61E0` | `0x0016BB10` |
| `0x0606` | `ccs_frame_tag_0606` | `0x001B64A0` | `0x0016BE20` |
| `0x0608` | `ccs_frame_tag_0608` | `0x001B6810` | `0x0016C1E0` |
| `0x0802` | `ccs_frame_tag_0802` | `0x001B6AB0` | `0x0016C4C0` |
| `0x0803` | `ccs_frame_tag_0803` | `0x001B6C60` | `0x0016C680` |
| `0x1801` | `ccs_frame_tag_1801` | `0x001B57F0` | `0x0016B090` |
| `0x1901` | `ccs_frame_tag_1901` | `0x001B56E0` | `0x0016AF60` |
| `0x1A01` | `ccs_frame_tag_1a01` | `0x001B6E40` | `0x0016C870` |
| `0x1B01` | `ccs_frame_tag_1b01` | `0x001B6FD0` | `0x0016CA10` |
| `0x1C01` | `ccs_frame_tag_1c01` | `0x001B71A0` | `0x0016CC00` |
| `0x1D01` | `ccs_frame_tag_1d01` | `0x001B7340` | `0x0016CDB0` |
| `0x2201` | `ccs_frame_tag_2201` | `0x001B52D0` | `0x0016AB30` |

NUN3's `ccs_parse_streamed_block_range` has the same dispatch set and
all eighteen data handlers agree in reads, masks, counts, alignment and version
branches, including absent targets. Runtime effects/layouts below describe NA2;
downstream equivalence is not established.

**Inference:** frame-tag high bytes identify the animated object families:
object, material, camera, lights, model, controllers/morpher, draw environment
and ring batch. Payload consumption does not depend on the unused marker or
generic declared length.

#### Frame payloads

`U` is a four-byte integer, `F` an IEEE float and `H` a halfword.
Commands normally begin with ID/flags; exceptions are explicit below.
Fields are consumed in listed order.
`ccs_play_target_unchecked` returns a play-entry value or zero if the table
is absent, without ID bounds or type assertion. It does not return direct
directory runtimes.

| Tag / handler | Payload after the common ID/flags, unless stated otherwise |
| --- | --- |
| `0x0101` / `ccs_frame_tag_0101` | `3F` position when `(flags & 0x0e)==0`; always `3F` Euler degrees; `3F` scale when `(flags & 0x380)==0`; always `F` alpha and `U` visibility. Euler is converted to radians and alpha is clamped to `[0,1]`. All input is consumed before target lookup. |
| `0x0108` / `ccs_frame_tag_0108` | No flags: exactly `U ID, U value1, U value2`. Creates a 0x18-byte queued node containing both values, current frame, resolved target, and table type (`ccs_play_target_type_unchecked`). Links it into the `CcsPlayContext.queued_commands` or `CcsExternalPlayContext.queued_commands`. The values' command meanings remain unresolved. |
| `0x0201` / `ccs_frame_tag_0201` | `F` for each clear bit `2`, `4`; version `>=0x120` adds `F` for each clear bit `8`, `0x10`, `0x20`, `0x40`. Defaults are respectively `0,1,1,1,0,1`. Consumption precedes lookup; resulting values update every nonzero material in the target's pointer/count vector. |
| `0x0502` / `ccs_frame_tag_0502` | With a resolved target and bit 0 clear: `F` position components for clear bits `2,4,8`, Euler degrees for clear bits `0x10,0x20,0x40`, then `F` for clear bits `0x80,0x100`. Bit 0 set reads no following fields. A missing target instead consumes exactly `8F` regardless of flags. |
| `0x0601` / `ccs_frame_tag_0601` | No ID/flags: one `U` packed color. Its low three bytes become the RGB vector applied at `CcsContainer.ambient_color`. |
| `0x0602` / `ccs_frame_tag_0602` | Always `3F` Euler degrees and `U` packed color; one extra `F` when bit `0x20` is set. The missing-target branch consumes the same widths. |
| `0x0604` / `ccs_frame_tag_0604` | Always `3F` position, `3F` Euler degrees, `U` packed color, and `5F` light parameters. Flags are read but do not suppress fields. |
| `0x0606` / `ccs_frame_tag_0606` | Same widths as `0x0604`. Two of the five trailing floats are angles converted to radians and divided by two. Flags do not suppress fields. |
| `0x0608` / `ccs_frame_tag_0608` | Always `3F` position, `U` packed color, `3F` light parameters. Flags do not suppress fields. |
| `0x0802` / `ccs_frame_tag_0802` | Second word is mesh count, not flags. For each mesh: `U vertex count`, that many `3H` position triples, then align reader to four bytes. A missing/non-model target uses the declared mesh count; a resolved `0x0100` scene object with `CcsScenePlayTarget.model` uses the runtime model's `CcsModelRuntime.mesh_count` instead. Vertex triples overwrite each mesh's `positions` buffer. |
| `0x0803` / `ccs_frame_tag_0803` | Second word is mesh count. For each mesh: `U element count`, that many `U` values. Uses the same declared-versus-runtime mesh-count split as `0x0802`; writes each mesh's `elements` buffer. |
| `0x1801` / `ccs_frame_tag_1801` | No flags: `U ID, 3F Euler degrees, F parameter`. Missing target falls back to `CcsPlayContext.default_extended_controller`. Rotation builds the `CcsExtendedController.direction`; the last word is stored in `CcsExtendedController.parameter`. |
| `0x1901` / `ccs_frame_tag_1901` | No flags: `U ID, H count, H padding`, then `count` pairs `{U source ID,F weight}`. Missing sources are omitted from the output list; all pairs are still consumed. Calls `morpher_set_source` for retained pairs and `morpher_set_source_count` with the retained count. |
| `0x1A01` / `ccs_frame_tag_1a01` | `F` for each clear bit `1,2`; third field for clear bit `4` is `F` before version `0x111` and `U` at/after it. Missing-target consumption uses the same four-byte width for the third field. |
| `0x1B01` / `ccs_frame_tag_1b01` | `3F` Euler degrees for clear bit `2`, `F` for clear bit `4`, `F` for clear bit `8`. |
| `0x1C01` / `ccs_frame_tag_1c01` | `F` for each clear bit `2,4,8`, then `2F` for clear bit `0x10`. |
| `0x1D01` / `ccs_frame_tag_1d01` | `F` for each clear bit `2,4,8,0x10`. |
| `0x2201` / `ccs_frame_tag_2201` | No ID/flags lookup: 12-byte header with ignored first dword, packet count `H` at `+4`, padding `H` at `+6`, and dwords-per-packet `U` at `+8`, then that many fixed-width packets. Publishes each available ring slot only when the global owner is zero or this container; otherwise consumes and discards its words. |

Camera fields omitted by flags require a resolved target: the missing-target
branch still reads eight floats and can consume a following header.
Mesh counts/vertex counts must agree with the resolved model, whose successful
branch uses runtime mesh count and copies without a destination-capacity check.
Numeric light/environment parameters remain unnamed where consumer meaning
is open; class identities are owned by [CCS object types](ccs_object_types.md).

Marker -1 sets end bits 2/4. Marker -2 does the same, rewinds to checkpoint
zero, restarts `0x0E00` effects and reinstantiates container generator
actions, so the stream loops.

Retail `STR/D01_10.CCS` has tag-5 payload and header checkpoint count
`0x13F`, begins frame markers at index zero and ends with marker -1.
Its marked namespace rows include
`#c\1nrt\max\1nrtbod1.max` and `#e\00\max\e00hit01.max`.

## CCS memory

Allocator placement/transients/capacity are owned by
[EE allocator](../../runtime/ee_memory_map/allocator_and_capacity.md#ccs-load-cost).

| Allocation | Size | Lifetime |
| --- | --- | --- |
| Container | 0xC0 | Decode/player allocation; generic container destruction |
| Namespaces | namespace count × 0x20 | Directory parse to container destruction |
| Records | record count × 0x38 | Directory parse to container destruction |
| Hash buckets | one word per record | Finalization to container destruction |
| Type objects | parser-dependent | Per-record type destruction |
| Owned reader | 0x40 | Only when construction received no reader |
| Play context | 0x120 | Separate play-state teardown |
| Play entries and checkpoints | record count × 0x10; checkpoint count × 4 | Separate play-state teardown, including owned materializations |

Container parsing enters high placement, so parse-time allocations come from
the top of the arena. Play building runs on the decode thread outside that
parser scope.

## Representative overlay callers

### Battle setup (resident)

Preparation order belongs to
[Battle lifecycle](../../gameplay/session/battle_lifecycle.md#resident-setup-order).
Battle loading checks presence before either synchronous load or one queued
`LoadBg` worker with progress mode 1.

`CcsBattleResourcesManager.sides` holds nine container slots and
30-byte path buffers per side. Paths combine `pl/`, `3eye/` or
`cutin/` with the
[character filename tables](../character_assets.md); mask bits 0/1 select the
classic/current body tables. Adoption fills empty slots by name.
Full side release clears another side's identical handle; single-slot release
only destroys an unshared handle. Mirror-match sharing is explicitly guarded
by these callers, without a container reference count.

### BTL.BIN

The stage family uses `stage_archive_paths` at live `0x00890A10`:
24 already-live pointers to `stage/s01.ccs` through `stage/s24.ccs`.
`stage_archive_acquire` reuses a resident container or loads a miss;
`stage_archive_release` destroys and clears its slot.
`stage_archive_enqueue` defers a load and `stage_archive_adopt`
performs the required lookup.

The spbattle pair retains `CcsSpBattleOwner.container`, setting
`owns_container` only when it loaded a miss. Release destroys only that
case, then clears pointer/flag. An already-resident container is borrowed.

The four-resource family uses `skill_ccs_paths` at `0x008A59E0`
for shade, gauge, stream-common and ougi. Synchronous and deferred acquisition
mark missing rows in the same ownership mask; adoption resolves all four into
`skill_ccs_handles` at live BSS `0x008DA9C0`; release destroys only
marked rows. Encoded path pointers already contain live addresses.

The stage-object helper selects one of two names for event `0x21/0x22`
and makes required lookup through a retained container slot. This illustrates
the caller contract of owning a container and repeatedly obtaining its
type-specific objects.

### ETC.BIN

An optional caller stores `EtcContainerOwner.container` before required
object lookup. Another caller requires the container as well.
These names are resident-populated GP globals with no static ETC strings;
nearby data cannot establish their identities. Adjacent split decompiler
fragments do not establish a complete C consumer assignment.

The mixed owner borrows `EtcSkillCcsOwner.shared` and loads-if-absent
stream-common/body-common into its other two fields. It destroys only those
owned fields; an already-resident path leaves its owned slot zero rather than
adopting it. The proven literals are `strmcmn.ccs` at live
`0x006E2C30` and `pl/1cmnbod1.ccs` at `0x006E2C20`.

The deferred replacement caller releases its previous
`EtcDeferredCcsOwner.container` on a selected-name miss, queues the new
path, starts progress mode zero, waits for inactivity, adopts by name and
cleans retained queue nodes.

## Negative results and confidence

Lookup, framing, direct consumption, ownership, cancellation, publication,
retail table bounds and demonstrated teardown order have high static
confidence. The registry entry owns the observed use count; direct holders
still depend on caller ownership and explicit reference invalidation.

The NA2/NUN3 reader comparison supports the bounded direct paths and exposes
specific result differences. Full delegated model conversion and downstream
behavior remain open. Secondary-value names describe demonstrated access,
without claiming one meaning for every type.

No generic expected-type assertion or object retain counter was found in the
lookup/record family. Publication/reference resolution is synchronized, but
caller-side unload serialization is not established.
