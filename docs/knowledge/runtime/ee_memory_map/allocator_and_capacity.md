# EE allocator

## Research coverage

Established: arena initialization, placement, accounting, deferred release, and sampled capacity.
CCS coverage includes transport, directory finalization, object costs, model overlaps, image storage,
and bounded background scene construction, model/playback instances, cloth and debris.
Routine names, prototypes, layouts, and code-level facts are maintained in `@annotations/NA2`.
Open: unexamined per-asset totals, property-geometry costs, whole-battle concurrent service lifetimes,
and minimum available load-time capacity.
No allocation/lifetime trace attributes a battle-load peak or individual assets' live nodes.
The six sampled states establish end-state capacity, not a minimum across all allocation sequences.

This document describes the unmodified retail NA2 (`SLPS-25837`) EE allocator.
Resident addresses use the conventions in
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
CCS parsing and ownership belong to
[Resident CCS runtime](../../game/files/ccs_runtime.md); task records and stacks
belong to [Task system](../task_system.md). Static formulas describe direct
requests and lifetimes; the samples do not measure load-time overlaps.

## System memory layer

`entry` initializes the kernel heap at `0x008DD080`. `system_sbrk` maintains
`system_heap_break` and rejects growth beyond kernel `EndOfHeap()`.
`library_arena_allocate` serializes `system_malloc_reentrant`. The arena is obtained
once at startup; `text_draw_progressive` also uses this layer for temporary strings of
at least `0x200` bytes, releasing them after drawing. Shorter strings use the resident
`0x200`-byte `progressive_text_buffer`.

**Inference (high confidence):** The kernel's `0x8000`-byte main-thread stack occupies
`0x01FF8000..0x02000000`, and `EndOfHeap()` returns its base. The first arena request
succeeds: its `malloc` user pointer is `0x008DD088`, and alignment places the base
sentinel at `0x008DD090`. The arena ends at `0x01FF6000`, leaving `0x2000` bytes below
the inferred stack base for the system allocator's top chunk and later requests.

## Allocator model

`game_arena_initialize`, called from the main routine `engine_boot_initialize`,
requests `0x1718F70` bytes from `malloc` and backs the request down in `0x100` steps
until it succeeds. It aligns the returned base, installs two 16-byte sentinels,
initializes two free-bin structures, caches the largest free gap, and clears the
placement-scope list.

| Global | Role |
| --- | --- |
| `arena_low_boundary` | low-placement boundary; initialized to the first user address and lowered only when the topmost low block is freed or shrunk |
| `arena_high_boundary` | high-placement boundary; initialized to the end sentinel and raised only when the lowest high block is freed |
| `arena_tracked_bytes` | current tracked bytes |
| `arena_peak_tracked_bytes` | peak tracked bytes |
| `arena_allocation_count` | live allocation count |
| `arena_deferred_free_head` | deferred-free list head |
| `arena_base_sentinel` | base sentinel |
| `arena_end_sentinel` | end sentinel |
| `arena_largest_gap_predecessor` | cached predecessor of the largest gap |
| `arena_largest_gap_bytes` | cached largest-gap size |
| `arena_placement_scope_head` | per-thread placement-scope list head |
| `arena_one_shot_high_placement` | one-shot placement byte |

The boundary words are maintained by free and resize; they do not limit allocation in
the inspected paths.

Each allocation has a 16-byte `HeapNode` header. `heap_allocate_payload` rounds the
payload plus its header to 16 bytes. Free gaps are indexed through `HeapFreeGap` records
occupying their first 16 bytes. Two segregated-bin families serve gaps below `0x1000` in
16-byte size classes; larger gaps use ordered lists, with fallback to the cached largest
gap. `arena_find_gap` selects the first sufficiently large gap in the chosen list.

The general-list sentinels are `arena_low_large_gap_sentinel` and
`arena_high_large_gap_sentinel`. Their two bin families are
`arena_low_free_bins` and `arena_high_free_bins`.

### Flags and placement

| Flags bits | Meaning |
| --- | --- |
| `0x3` | Placement class. `0` places the block at the low end of the chosen gap and indexes leftover gaps in `arena_low_free_bins`; `1` places it at the high end of the gap and uses `arena_high_free_bins`. |
| `0x4` | Untracked: the block is excluded from the tracked-byte counters. |
| `0x8` | Nullable: failure returns zero. Without it, `heap_allocate_payload` executes a trap on failure. |
| `0xF0` | Deferred-free countdown, used only while the block is on the deferred-free list. |

The ordinary flag values are therefore `0` low trapping, `1` high trapping, `8` low
nullable, and `9` high nullable.

Placement comes from the per-thread scope list headed by `arena_placement_scope_head`.
`arena_placement_scope_push` pushes a stack-backed `HeapPlacementScope` carrying the
current thread and direction; `arena_placement_scope_pop` removes it;
`arena_placement_scope_direction` returns the current thread's innermost direction or
`3` when it has none. The inspected resident scopes are:

| Scope | Direction | Covered work |
| --- | ---: | --- |
| `ccs_run_load_pipeline` | 0, low | CCS file-load coordinator: transport buffers, readers, and worker records |
| `ccs_parse_container` | 1, high | CCS container parsing on the decode worker thread |

Without a scope, the default entry points consume `arena_one_shot_high_placement`,
clearing it on every call; a nonzero value selects high placement. Selected resident
allocations set this preference before calling the allocator.

**Observation:** CCS parsing requests high placement, while the transport coordinator
requests low placement. The container descriptor is allocated before the parser's high
scope. Fallback can place a block on the opposite side, so the scopes establish a
preference rather than a guarantee that all container-related blocks occupy one end.

### Entry points

| Function | Arguments | Direction choice | Try, then fallback |
| --- | --- | --- | --- |
| `heap_allocate_default` | size | scope, else one-shot byte | preferred side nullable, other side trapping |
| `heap_allocate` | size | same as `heap_allocate_default` | same |
| `heap_allocate_scope_high` | size | scope only; none selects high | preferred side nullable, other side trapping |
| `heap_allocate_aligned_scope_high` | alignment, size | scope only; none selects high | same |
| `heap_allocate_aligned_scope_low` | alignment, size | scope `1` selects high, otherwise low | same |
| `heap_allocate_synchronized` | size | same as `heap_allocate_aligned_scope_low` | same |
| `heap_allocate_nullable` | size | same as `heap_allocate_aligned_scope_low` | both sides nullable; may return zero |
| `heap_allocate_untracked` | size | always low first | low untracked nullable, then high untracked trapping |

Frees use `heap_free_synchronized`, directly or through `heap_free`. A free unlinks
the node, merges the neighbouring gaps into its predecessor's gap, and reindexes that
gap in the family matching the freed block's class.

`arena_resize_in_place(pointer, size)` changes a block's recorded size in place and
reindexes the following gap. It does not check that growth fits. Animation construction
in `ccs_parse_animation_tracks` shrinks the block to the end of the parsed track data.
`arena_defer_free(pointer, frames)` queues a block for deferred release; the frame
routine `engine_root_finish_update` calls `arena_process_deferred_frees`, which
decrements every queued countdown and frees blocks that reach zero.
`render_pool_defer_free` uses this deferred path.

Complete list walks in every sampled state established that:

- forward and backward links are consistent and acyclic;
- the walked node count equals `arena_allocation_count`;
- walked tracked bytes equal `arena_tracked_bytes`;
- the cached largest gap and predecessor match the computed maximum;
- one flag-12 allocation of `0x10010` bytes is excluded from tracked bytes.

The flag-12 block is the `0x10000`-byte buffer that `render_untracked_buffer_construct`
obtains through `heap_allocate_untracked`.

The tracked peak starts at zero. Each tracked allocation updates it after adding the
node's recorded bytes to the current total. Resize changes current tracked bytes without
updating the peak. It therefore describes allocation high-water history since arena
initialization, excludes untracked nodes and free gaps, and has no battle-load reset in
the inspected direct-write paths. Indirect counter writes remain outside that bounded
inspection.

`total_free` is the sum of gaps between live nodes. `largest_free` is the largest single
gap. An ordinary allocation must also fit its 16-byte header inside that gap.
`fragmentation_bytes` is `total_free - largest_free`.

## Resident secondary pool

During display initialization, `engine_root_initialize` allocates a `0x14`-byte pool
descriptor and `render_pool_configure` gives it a `0x200000`-byte block from
`heap_allocate_synchronized`. The descriptor is stored in
`EnginePadContext.render_pool` and linked into the pool list headed by `render_pool_list_head`.
`render_pool_allocate` serves first-fit requests from the pools on that list for
renderer work. The frame routine `engine_root_update` calls `engine_update_services`,
whose final step `render_pool_release_frame` releases the frame's pool entries.

**Observation:** This 2 MiB block is allocated once at startup and remains live. It is
unavailable to the general arena in every mode.

## Resident file directory

`gzlist_build_tree`, called from front-end startup `resident_flow_dispatch`, reads
`gzlist.txt` whole into a `heap_allocate_aligned_scope_high` block and parses it. For
each of its 21 directories it allocates a table of `(files + 4) * 0x30 + 0x18` bytes
through `heap_allocate_synchronized`, and for each file it stores the listed
decompressed size in `GzlistFileNode.decoded_size`. A zero size takes the null-store
failure path. The routine frees only its `0x12C`-byte parse record; it advances the
text pointer while parsing and never frees the text block.

**Observation:** The retail list is `0x195A8` bytes. Its header declares 21 directories
with 2,332 file slots, so this directory permanently holds about `0x195C0` bytes of text
plus `0x1C6F8` bytes of tables, about 216 KiB, before per-directory node overhead. Its
2,310 file rows each match the extracted file's compressed size and gzip-trailer
decompressed size. With no placement scope active, the text block goes to the high end
and the tables to the low end.

`file_metadata` returns an entry's `decoded_size` value to the load coordinator. It is
the decompressed size, so a nonzero value selects the gzip path and sizes the whole-file
buffer of a flags-`0x100` load. `rofs_find_file_metadata` resolves a path through this
directory and takes the null-store failure path for a directory or file it does not
list.

## CCS load cost

`ccs_run_load_pipeline` opens the file, pushes a low-placement scope, and allocates its
buffers according to the file-list metadata and flags:

| Path | Transient allocations |
| --- | --- |
| Uncompressed, flags `0` | one `0x40000`-byte transport ring (four `0x10000` blocks, alignment `0x80`) and a `0x40`-byte reader |
| Compressed, flags `0` | a `0x40000`-byte input ring, a `0x40000`-byte output ring, a `0x10000`-byte decompression block, two readers, a `0x44`-byte bridge, and the `LoadGzip` task with a `0x10400`-byte stack |
| Flags `0x100` | a buffer for the whole file, or for the whole decompressed size plus a `0x40000`-byte input ring when compressed, rounded up to whole blocks; retained until the owner releases the wrapper |

Every path also starts `LoadRead` and `LoadDecode` tasks with `0x1400`-byte stacks and
`0x4C`-byte records. With flags `0`, the coordinator frees the transport buffer and
the parser-facing reader with its ring once reading and decoding finish. On the
compressed path it then waits for the gzip worker and destroys the input reader before
returning.

Every retail CCS file in `DATA.CVM` is gzip-compressed and listed with a nonzero
decompressed size in the [resident file directory](#resident-file-directory), which
rejects zero sizes and unlisted paths. **Inference (high confidence):** retail loads
always take the compressed path.

**Observation:** The ordinary compressed path's two rings, decompression block, and
three worker stacks request `0xA2C00` payload bytes: roughly `0xA3000` bytes (650 KiB)
before the smaller records, node headers, alignment gaps, and variable inflate tables.
This is a fixed-buffer subtotal, not the complete transient requirement. The
decompression block size is read from the output ring's block size, `0x10000` on this
path. With flags `0`, the file is streamed rather than held whole. Parsing builds the
retained allocations described below.

`transport_ring_configure` additionally allocates one `0xC * block_count` descriptor
array per ring, aligned to `0x80`; an ordinary four-block ring therefore adds a `0x30`-byte request. These arrays are distinct from each ring's byte buffer.

Including node headers, the two rings, decompression block, three stacks,
three `Q(0x4C)` task records, two `Q(0x40)` readers, `Q(0x44)` gzip bridge,
two `Q(0x30)` ring descriptor arrays and the caller's `Q(0x34)` load wrapper
sum to **667,472 bytes** on the ordinary compressed path. The wrapper is
created by `ccs_load_if_absent` (`0x00116DE0`) and freed after a flags-zero
load. Four requests use `0x80` alignment: both byte rings and both descriptor
arrays. Their placement can consume at most `4 * (0x80 - 0x10) = 448`
additional bytes between nodes. The other listed requests use `0x10`
alignment. This subtotal excludes variable tables and resource/parser nodes.

`inflate_build_tables` requests `8 * (2^k + 1)` bytes for each Huffman subtable, where
`k` is its selected bit width; the extra eight bytes hold the table-list prefix.
`inflate_free_tables` releases the linked blocks. `inflate_decode_dynamic_block` builds
and frees the code-length table before holding the literal/length and distance tables
together during decoding. `inflate_decode_fixed_block` also creates and releases two
tables per block. These allocations vary with the compressed codes and are additional to
the worker stack, which already contains the code-length work arrays.

Decompressed sizes establish the input scale, not resident allocation totals. The
directory alone expands every file record and allocates additional hash storage, as
shown below. Texture pixel data is separately copied into decoded storage; other
type-specific costs and the whole-file total need their own accounting. Retail
decompressed sizes from the resident file directory are:

| Family | Files | Decompressed median | Decompressed maximum |
| --- | ---: | ---: | ---: |
| `STAGE/S??.CCS` | 24 | `0x119CFA` | `0x143334` |
| `PL/1???BOD1.CCS` | 86 | `0x082742` | `0x0AA0EC` |
| `PL/2???BOD1.CCS` | 149 | `0x07C410` | `0x1AF14C` |
| `PL/2???CHA0.CCS` | 76 | `0x036EE0` | `0x065A7C` |
| `PL/2???CHA1.CCS` | 77 | `0x01BEE8` | `0x060A30` |
| `3EYE/3???3PCT.CCS` | 78 | `0x00CF0C` | `0x01018C` |
| `3EYE/3???3EYE.CCS` | 78 | `0x0119E0` | `0x08DA78` |
| `CMN/*.CCS` | 6 | `0x037AC4` | `0x1693DC` |

### Directory and finalization cost

For an ordinary 16-byte-aligned allocation, define `Q(n) = (n + 0x1F) & ~0xF`.
`heap_allocate_payload` records this many bytes, including the 16-byte node header; even
a zero-byte request records `0x10` bytes. Higher requested alignment can leave
additional free gaps, so `Q` describes node bytes rather than a fragmentation allowance.

Let `F` be the namespace count and `N` the object-record count read by
`ccs_read_object_directory`. The fixed retained container/directory node cost is:

```text
Q(0xC0) + Q(0x20 * F) + Q(0x38 * N) + Q(4 * N)
```

`ccs_load_decode_worker` allocates the container before entering `ccs_parse_container`'s high-placement scope. The other three blocks are namespace strings, records, and hash
buckets. A file record occupies `0x20` bytes in the stream but `0x38` bytes in the
directory and another 4 bytes in the hash table: `0x1C` extra payload bytes per record
before node headers and rounding. Namespace rows retain their original `0x20`-byte
width. A caller-created owned reader adds `Q(0x40)`; an ordinary load borrows its
transport reader, whose cost belongs to the transient pipeline instead. Container
ownership is described in
[Resident CCS runtime](../../game/files/ccs_runtime.md#ccs-memory).

`ccs_finalize_directory` first allocates two temporary `4 * N` arrays. For `N > 2`, its
sort helper `ccs_sort_directory_keys` additionally allocates `8 * N` bytes, split into
two word arrays. During sorting, the extra node cost is therefore
`2 * Q(4 * N) + Q(8 * N)`; the hash bucket block has not yet been allocated. The helper
frees its scratch block before the finalizer allocates the retained `4 * N` hash
buckets. At that later point the two `4 * N` temporary arrays still overlap the buckets;
the finalizer then frees both temporaries before dependency finalization. These are two
different transient phases, not four simultaneously retained arrays.

**Observation:** Directory expansion and sort scratch depend on record count, which
decompressed byte length alone does not reveal. Adding only the fixed-buffer subtotal to
the final container cost omits inflate tables, this parse-time scratch, and conversion
overlaps, and does not establish the load's peak.

### Non-image objects and discarded data

The following costs are additional to the container/directory blocks. `Q` is the node
cost defined above. These are allocation consequences of the resident parsers; tag
identities and payload layouts belong to
[Resident CCS object-type identities](../../game/files/ccs_object_types.md). For
conditional constructors, the row applies when a new object is built; reusing an already
constructed record does not incur that request again.

| File tag | Node cost or direct request | Owner and lifetime |
| ---: | --- | --- |
| `0x0100` | `Q(0x24)` | `ccs_parse_scene_object`; replaces and frees a preceding `0x2000` placeholder. |
| `0x0200` | `Q(0x18) + Q(0x1C)` | `ccs_parse_material` constructs the descriptor; `ccs_finalize_secondary_values` adds its secondary object during finalization. |
| `0x0500` | `Q(8)` | `ccs_parse_camera`; camera materialization is later and separate. |
| `0x0600` | `Q(0xC)` plus `Q(0xE0)`, `Q(0x160)`, `Q(0x160)`, or `Q(0xD0)` for selector 1, 2, 3, or 4 | `ccs_parse_light` and finalizer `ccs_materialize_light_secondary`; an unknown selector produces no secondary. The constructors initialize inline state without further allocations. |
| `0x0A00` | `Q(0x20)` | `ccs_parse_external_record`; replaces and frees a preceding `0x2000` placeholder. |
| `0x0C00` | `Q(0x40)` while parsing; zero retained block | `ccs_parse_bounds`; `ccs_finalize_dependencies` applies the directive, clears its record pointer, and frees the block. |
| `0x0D00` | `Q(0xC)` | `ccs_parse_transform_child`. |
| `0x1300`, `0x1400` | `Q(0x20)`, `Q(0x30)` respectively | `ccs_parse_position_marker`, `ccs_parse_transform_marker`; their stream payloads are only `0x10` and `0x1C` bytes. |
| `0x1800` | `Q(0x18)` for a new explicit record | `ccs_parse_projection_controller`; record ID zero updates an existing default descriptor instead. Later play-object materialization is separate from this resource block. |
| `0x1900` | `Q(8)` | `ccs_parse_morpher_binding`. |
| `0x1A00`, `0x1B00`, `0x1C00` | `Q(0x10)` each | `ccs_parse_outline_parameter`, `ccs_parse_celshade_parameter`, `ccs_parse_toneshade_parameter`. |
| `0x1D00` | `Q(8)` | `ccs_parse_blur_parameter`. |
| `0x2000` | `Q(0x14)` only for a not-yet-typed record | `ccs_parse_preobject_metadata`; existing `0x0100`, `0x0A00`, or `0x0E00` objects are updated in place. |
| `0x0003`, `0x1000`, `0x1100`, `0x1200` | no new object block | `ccs_object_section_noop`, `ccs_parse_legacy_group_marker`, `ccs_parse_legacy_page_marker`, `ccs_parse_legacy_rect_marker`. The latter three consume their payloads without retaining them; `0x1000` consumes `8 + 4 * count` bytes and `0x1200` consumes `8 + 8 * count` bytes. |

Counted and length-driven routes add these costs:

| File tag | Cost variables and allocation consequence | Owner and lifetime |
| ---: | --- | --- |
| `0x0700` | Initial request `0x2C + 4 * W`, where `W` is the declared track-word budget. After parsing, resize records `Q(A(end - start))`, with `A(n) = (n + 0xF) & ~0xF`; two retained index blocks add `Q(8 * R) + Q(2 * R)` for the collected reference count `R`. | `ccs_load`, `ccs_parse_animation_tracks`, `arena_resize_in_place`. The initially larger block can affect the peak even though it is later shrunk. |
| `0x0800` | For nonzero part count `P`, a model requests `0x60 + 0x40 * P`. A nonzero header byte-table count additionally requests `0x40`, independent of that count. Per-part geometry and generated packets are additional. | `ccs_parse_model`; part families are discussed below. |
| `0x0900` | For child count `C`, the initial block is `Q(A(0x1C) + A(4 * C) + A(0x30 * C))`. Retained dependency groups add `Q(2 * C)` during finalization. | `ccs_parse_morpher`, rounding helper `align_size_in_place`, `ccs_finalize_dependencies`. The special first-child `0x0E00` path clears the record and frees this provisional block through `ccs_destroy_composition_descriptor`. |
| `0x0B00` | For a nonzero group count, `Q(0x10) + Q(0x40 + 0xA0 * T)`, where `T` is the header's total vertex count divided by 3. | `ccs_parse_hit_mesh`; retained runtime triangles have stride `0xA0`. |
| `0x0D80` | `Q(B + 4 + 4 * K)`, where `B` is the header length in bytes and `K` is the packet count. | `ccs_parse_generator_packet`; `0x14`-byte file packet descriptors become `0x18`-byte runtime descriptors. |
| `0x0D90` | `Q(0x70 + 0x30 * U + 0xC * V)`, where `U` is the low nibble of `CcsGeneratorFileHeader.packed_parameter_count` and `V` is the high nibble of `packed_child_count`. | `ccs_parse_generator`; the parser frees this block and clears its record pointer when `V` is zero. |
| `0x0E00` | `Q(0x34 + 8 * C)`, where `C` is `CcsEffectFileHeader.frame_count`. | `ccs_parse_effect`; replaces and frees a preceding `0x2000` placeholder. The descriptor expands the `0x24`-byte file header by `0x10` bytes and retains the eight-byte rows. |
| `0x1700` | Temporary `Q(8 * rows)`, retained `Q(0x10)` root, and individual `Q(8)` or `Q(0x18)` controller descriptors, including missing default slots. | `ccs_parse_ordered_controller_table`; the temporary row table is freed on return. An already constructed extended descriptor is reused. Root constructor `ccs_controller_table_construct` adds no allocation. |
| `0x1F00` | Temporary `Q(B)` plus the exact converted allocation `Q(output_size)`; both are live during conversion. | `ccs_parse_nested_halfword_table`; the input block is freed before return. Its nested count/packing rules are owned by the object-type document. |
| `0x2200` | No new parser-owned object block; payload is copied into an existing ring manager or consumed and discarded when no ring slot is available. | `ccs_parse_packet_batch`; manager lookup `ccs_packet_ring_get` and slot acquisition `ccs_packet_ring_request_slot` are separate from CCS object allocation. |
| `0x2300` | Temporary `Q(B)` input blocks persist until dependency finalization. A resolved target adds `Q(0xC)` and, for nonzero source counts `U`/`V`, `Q(0x10 * U)` / `Q(0x1C * V)`. | `ccs_parse_relation_block`, `ccs_finalize_dependencies`; arrays are allocated for the source counts, even when only a smaller subset resolves. Input blocks are then freed; pointer-vector capacity is accounted for below. |
| `0x2400` | `Q(B + 4)`; the retained blob has `B - 4` data bytes after an eight-byte descriptor. | `ccs_parse_binary_blob`; the first four file bytes are the record ID. |

`B` is four times the block-header payload-length dword. The `0x1F00`, `0x0D80`,
`0x2300`, and `0x2400` handlers size their requests from this byte length; other
parsers consume payloads according to their own counts.

For `G > 0` blocks of type `0x2300`, `CcsContainer.relation_blocks` additionally
retains `Q(4 * K)`, where `K` is the smallest power of two at least `G`.
`ccs_construct_container` initializes this `CcsPointerVector` with zero capacity,
length, and data pointer. Append `ccs_relation_vector_append` calls
`ccs_pointer_vector_insert`, which grows capacity from 1 by doubling and allocates the
new backing block before freeing the old one. During growth, both backing blocks
therefore overlap the input blocks. After freeing each input,
`ccs_finalize_dependencies` calls `ccs_pointer_vector_clear`, which clears only
`CcsPointerVector.length`; it does not release the capacity block. For `G == 0`, this
vector has no backing allocation.

The `0x1800` resource illustrates the distinction between parsing and play
materialization. `ccs_build_play_runtime_table` requests a primary `Q(0x180)` play block
and calls `projection_controller_construct`. Its ordered-controller initializer
`ordered_controller_register` borrows the supplied render-environment pointer, or
requests `Q(0x2B0)` and invokes `renderer_construct` when that pointer is zero. These
are later costs, separate from the parser's `Q(0x18)` descriptor; the primary request
alone does not establish all nested environment or scene costs. The controller's
behavior is owned by
[the object-type document](../../game/files/ccs_object_types.md#0x1800-descriptor-fields-and-off-screen-pass).

**Observation:** Non-texture storage can expand, contract, or disappear during
finalization. For example, `0x0B00` consumes two sets of three 3D points per triangle
(`0x48` bytes), builds a `0xA0`-byte runtime triangle, and retains only the processed
representation; the second point set is consumed without being retained. Conversely, the
file-block `0x1000` payload creates no object block. Thus no single
decompressed-to-resident ratio follows from the parser. The allocation sum requires
actual type/count/flag data and the relevant lifetime.

### Typed animation keys and curve nodes

The typed animation routes additionally allocate separate key descriptors:
`ccs_pack_tag_0102` (`0x001A8000`) requests `0x18` bytes;
`ccs_pack_tag_0603` (`0x001A7C80`) requests `0x14` bytes.
These are additional to the animation wrapper, packed output and reference
arrays. The curve readers retain separately allocated nodes for counted
channels; constant selector-1 values remain inside the wrapper's packed
output (12 bytes for vector/rotation, 4 for scalar/word).

For a counted channel, define `M = C + I(first_time != 0) + 1`,
where `C` is the file key count. The retained node requests are:

| Curve reader | Selector | Request before `Q` |
| --- | ---: | --- |
| `ccs_read_vector_curve`, `0x001A4D30` | 2 / 4 / `0x12` | `16*M+4` / `44*M+4` / `10*M+8` |
| `ccs_read_rotation_curve`, `0x001A30C0` | 2 / 4 / `0x12` / `0x14` | `32*M+0x50` / `10*M+8` / `10*M+8` / `18*M+0x10` |
| `ccs_read_scalar_curve`, `0x001A6520` | 2 | `8*M+4` |
| `ccs_read_word_curve`, `0x001A6990` | 2 | `8*M+4` |

The dispatcher writes each typed command's eight-byte header and its
constant values to the packed cursor; ID/flags are consumed into the
separate descriptor. Consecutive `0xFF01` markers compact to one
12-byte marker. Thus a file's track-word budget does not alone give the
retained animation cost: counted channels can move out of the resized
wrapper and into these independent nodes.

### Model-part allocation and conversion

`ccs_parse_model` selects parts by `(file_flags >> 1) & 7`. File selector 0 uses
`ccs_read_model_vertex_arrays`, 2 uses `ccs_convert_packed_model_mesh`, 3 uses
`ccs_read_property_geometry_part`, and 4 uses `model_prepare_projection_geometry`. The
auxiliary reader `ccs_read_model_mesh_aux` is behind internal selector 3, which the
outer selector does not assign. Its conditional cost remains useful, but it is not the
file-selector-3 path.

Costs below are additional to the model's `Q(0x60 + 0x40 * part_count)` block. Let `V`
be `CcsModelMesh.vertex_count`, `E` its `auxiliary_count`, `f` the part-parser flags,
and `A(n) = (n + 0xF) & ~0xF`.

| Reader path | Retained allocations |
| --- | --- |
| File selector 0 | Vertex-marker block `Q(A(V))`, positions `Q(A(6 * V))`, conditional four-byte-per-vertex attribute blocks, and a generated packet. |
| Internal auxiliary selector 3 | When `E == 0`, positions `Q(A(6 * V))`; otherwise `CcsModelMesh.index_entries` costs `Q(8 * E)`. Both paths retain `Q(A(4 * (E == 0 ? V : E)))` and `Q(A(4 * V))` attribute blocks. This reader generates no packet. |
| File selector 2 | A `Q(0x10)` descriptor and its converted packet; input attribute arrays are freed after construction. |
| File selector 3 | Property-geometry reader confirmed; its complete allocation and overlap formula is unresolved. |
| File selector 4 | A generated packet when construction succeeds; geometry and edge-building arrays are freed before return. |

In the formulas below, family numbers refer to file selectors.

For family 0, `CcsModelMesh.elements` is allocated when `f & 0x40` is zero, `uv_words`
when both `f & 0x200` and `f & 1` are zero, and `auxiliary_attributes` when `f & 0x400`
is zero. When `f & 0x200` is zero but `f & 1` is set, the corresponding file words are
consumed without retaining that attribute block. Size helper
`model_geometry_packet_size` gives the generated packet request:

```text
16 * (ceil(V / 48) * (7 + I(!(f & 0x40)) + I(!(f & 1))
                         + 2 * I(!(f & 0x400))) + 2)
```

`I(condition)` is 1 when true and 0 otherwise. If `CcsModelDescriptor.runtime_flags` has
`0x02000000` set and `0x04000000` clear, `ccs_normalize_ordinary_strips` may insert
duplicate vertices according to the strip markers. It allocates replacements for every
present attribute block at the expanded count before freeing the old blocks. The packet
is then sized from that expanded count. Final retained size alone therefore misses an
overlap of the old and new attribute arrays.

Family 2's non-indexed path (`E == 0`) temporarily holds `Q(6 * V) + 2 * Q(4 * V)`
through `ccs_read_packed_rigid_part`. Its strip conversion `ccs_normalize_rigid_strips`
can allocate all three replacements before freeing the old arrays. With `M` the
resulting count and `r = M % 54`, packet builder `ccs_convert_rigid_vif` requests:

```text
A(4 * (289 * floor(M / 54) + 1 + (r == 0 ? 0 : 5 * r + 19)))
```

The indexed path temporarily holds `Q(8 * E) + Q(4 * E) + Q(4 * V) + Q(0x10 * V)`
through `ccs_read_packed_weighted_part`. `ccs_normalize_weighted_strips` can replace
the last array at the expanded vertex count before freeing its predecessor.
`ccs_convert_weighted_vif` groups the resulting records with
`ccs_count_weighted_batch_vertices` and sums their entry counts with
`ccs_count_batch_influences`. For a batch of `q` records containing `s` entries, its
packet contribution is `4 * (4 * s + ceil(3 * s / 2) + 20 + q)` bytes; the sum over all
batches is rounded with `A`. Both family-2 paths use nullable packet allocation and
then free their input arrays through `packed_rigid_buffer_destroy` or
`packed_weighted_buffer_destroy`. The packet and descriptor remain.

For family 4, let `U` be the unique-vertex count read by
`model_prepare_projection_geometry`, `W` its index count, and `T = W / 3`. For nonzero
`U`, its initial scratch nodes are:

```text
Q(0x140) + Q(0x20 * W) + Q(8 * T) + 2 * Q(0x10 * T)
         + Q(8 * U) + Q(0x3C * U)
```

One `0x10 * T` work array is freed before the construction checks, and the `0x20 * W`
array is freed before allocating the successful output packet. Let `H` and `S` be the
resulting normal and edge counts produced by the scratch context. The packet request is:

```text
16 * H + 48 * ceil(T / 24) + 24 * T
       + 48 * ceil(S / 24) + 80 + 16 * S
```

The other scratch nodes remain live during that allocation and are freed afterward.
`model_topology_build_edge` and `model_topology_build_triangle` build the edge and
normal data in these preallocated arrays. The zero-vertex and unsuccessful construction
paths retain no generated packet. Thus the file's geometry counts, strip markers, and
conversion family determine both its retained cost and its temporary overlaps.

## Texture and palette storage

The ordinary texture path in `ccs_parse_image_block`, with file flags `0x20` clear,
builds a `Q(0x48)` texture through `texture_chunk_construct` and
`texture_initialize_from_descriptor`. When constructor flags `0x40` are clear, it
additionally allocates a level table `Q((mip_count + 1) * 0x20 + 0x10)` and calls
`image_level_initialize` for the base level and each mip level. With no source pointer,
each level requests `16 * ceil(bits_per_pixel * width * height / 128)` pixel bytes
through nullable `heap_allocate_nullable`, with its own node overhead. The parser
copies the file's pixel dwords into that buffer and fills any remainder with
`0xFFFFFFFF`. When the payload is larger than the buffer, it copies nothing and fills
the whole buffer with `0xFFFFFFFF`.

The file-flags-`0x20` path instead consumes the pixel words without retaining them,
clears the mip count, sets constructor flags `0x58`, and allocates a `Q(0x50)` object
through `sampling_texture_chunk_construct`. Constructor
`texture_initialize_from_descriptor` sees `0x40` and omits the level table and pixel
allocations. Thus a texture tag does not invariably imply retained decoded pixels.
Ordinary owned pixel buffers prefer the high end inside the parser's placement scope.

When a level's pixel allocation fails, `image_level_initialize` shrinks that level to
8×8 and allocates the smaller buffer through trapping `heap_allocate_synchronized`; the
parser then fills it with `0xFFFFFFFF` instead of the payload. **Inference (high
confidence):** near exhaustion, affected texture levels become 8×8 blocks of
`0xFFFFFFFF` before the game stops. Most other allocations use the default entry points,
which trap after both placement sides fail.

Palette parser `ccs_parse_clut_block` requests a `Q(0x28)` descriptor when creating a
new `0x0400` record. `clut_initialize_from_descriptor` adds a `Q(0x20)` level descriptor
and, through `image_level_initialize`, a pixel block sized from the palette format and
its 16×16 or 8×2 dimensions. Its nullable allocation uses the palette branch, which has
no texture-style 8×8 retry. When `CcsClut.transfer_flags & 0x1` is clear, the parser
calls `image_level_submit_pixels` to submit the pixels, then `clut_release_transfer`
frees the level and owned pixel blocks. When that mask is set, those blocks remain.
Consequently this path's construction-time allocations can exceed its retained
descriptor cost.

Texture and palette name bindings also materialize shared image-transfer groups:
`ccs_image_attach_transfer_group` / `ccs_clut_attach_transfer_group` reuse a matching
controller or create a `Q(0x38)` controller through `ccs_image_transfer_group_construct`; each binding adds a `Q(8)` list node through `image_transfer_group_add_texture` /
`image_transfer_group_add_clut`. This indirect construction is distinct from the
`0x1000` file-block parser, which discards its payload.

## Background scene and playback instances

These allocations are additional to the loaded CCS resources. A stage graph
borrows its container and resource arrays; it does not make a second copy of
every composition, model geometry, texture or animation in the archive.
Native background factories and their configuration fields belong to
[Stages](../../gameplay/stages/stages.md#native-background-configuration-formats).

`bg_scene_build` (`0x003AC7A0`) creates three collection owners with requests
`0x1C`, `0x14` and `0x10`. The first owner additionally creates a `0x40`
ordered controller and a `0x70` particle manager through
`particle_standalone_owner_initialize` (`0x003AB220`): **336 node bytes**
altogether. The manager starts with no emitters. `bg_scene_create_selectors`
(`0x003AD9A0`) creates twelve sets of `Q(0x20) + Q(0x40) + Q(0x160)`,
**5,952 bytes**. Their controllers borrow the nonzero `default_renderer`;
a null renderer would select a separate `Q(0x2B0)` allocation
through `ordered_controller_register` and is outside that count.

`bg_scene_attach_object` (`0x003AC4D0`) creates one `Q(8)` registration link
when its registration argument is nonzero. Owning-list links and collection
headers are inline. The class's own primary allocation and its parser's nested
requests remain separate. For example, `bg_glare_parse` (`0x00398C40`)
creates a `Q(0xA0)` effect; the transparent-object parser in BTL
`bg_trans_object_parse` (`0x006C7510`) creates two `Q(0x40)` controllers
in addition to its visual child/model.

### Construction records and line storage

`bg_scene_parse_records` (`0x003ADE40`) copies the binary blob, allocates
a six-byte triple array, then expands each triple into a 16-byte record and
copies each configuration string. The blob copy and triple array are freed
before factory dispatch. The expanded records and strings overlap factory
construction. `bg_scene_finish_graph` (`0x003AE170`) frees every copied
configuration and the expanded record array after dispatch, clearing the
scene's record pointer. Their `Q(16*C) + sum(Q(string_bytes+1))` cost is
construction scratch, not retained scene memory.

The enclosing retail BTL path additionally allocates a field `Q(0x90)`,
background control `Q(0xAD0)`, its capacity-two pointer vector `Q(8)`, and
scene `Q(0x150)`. The state records initialized inside that control and the
scene's five owning-list headers are inline. Slot-specific helpers can add
further allocations and must be inspected for the selected slot.

BTL first-line construction (`0x006C33C0`) retains `Q(4)` for the head and
`Q(0x30*P)` for `P` pairs. Second-line construction (`0x006C3750`) with
`L=floor(node_count/2)>0` retains a boundary `Q(0x40)`, vector owner
`Q(0xC)`, head `Q(4)`, segment array `Q(0x30*L)`, `L` endpoint blocks
`Q(0x20)`, and pointer backing `Q(4*K)`, where `K` is the smallest power
of two at least `L`. Vector growth allocates the new capacity before freeing
the old backing, so the previous `Q(4*K_old)` is additional overlap.

### Model instances

`ccs_scene_child_bind_models` (`0x00196B40`) creates a primary model
`Q(0x50)` and, when a valid secondary descriptor exists, a separate shadow
model `Q(0x60)`. `ccs_model_instance_initialize` (`0x001992A0`) additionally
retains a part array `Q(0x40*P+0x10)` and a distinct-material pointer list
`Q(4*D)` when `D>0`; `0<=D<=P`. Material-list construction
(`0x00198520`) temporarily requests `Q(4*P)` and frees it before returning.
A linked collision mesh additionally creates `Q(0xA0)` environment state,
borrowing its processed triangle hierarchy. Thus the ordinary-model cost is:

```text
Q(0x50) + Q(0x40*P+0x10) + I(D>0)*Q(4*D)
        + I(linked_hit_mesh)*Q(0xA0)
```

Use `Q(0x60)` instead of `Q(0x50)` for the separately allocated shadow.
The scene child itself normally costs `Q(0xB0)`; a child inside a constructor's
array is already covered by that array request. Part instances borrow ordinary
geometry/packets/attributes and resource material secondary values. They clone
polymorphic property geometry when present, so this formula applies only when
that clone route is absent. Flags `0x84` can add a `Q(0x18)` extra-pass owner;
animation materialization of models requiring flags `0x804` can additionally
build the ordered-bone pointer array. Neither conditional term follows merely
from a nonzero model part count.

### Animation binding and bounded rebinding

Background animation players normally request `Q(0x120)`. On an empty player,
`animation_attach` (`0x001B99B0`) allocates `Q(0x10*R)` play entries for the
animation's `R` collected references and one evaluator per typed key. Owned
object entries create their scene child and models through the preceding
formula; owned light entries create the light secondary. Borrowed composition
targets do not incur those primary/child costs again. Material references can
create a separate material cache, and nonzero blending and generator packets
have their own costs. Counting every archive composition for every background
player would overstate the inspected empty-player path.

`animation_evaluator_allocate` (`0x001B8020`) requests a `0x10` prefix plus
channel work. Vector modes `1/2/4/5` request `0x10/0x20/0x50/0x40`;
rotation modes `1/2/4/5` request `0x40/0x50/0x50/0x50`; scalar and color
modes `1/2` request `0x10`. Other listed modes request no channel work.
Type `0x0102` sums vector, rotation, vector and scalar work; `0x0603` sums
rotation, color and scalar work. Use the runtime descriptor modes: compressed
file curves can be remapped to mode 5 by the typed-key parser.

Rebinding creates the incoming play entries/evaluators/owned targets before
clearing the outgoing target table. Zero blending suppresses blend allocation
but does not suppress this old/new overlap. Moving birds additionally retain
a `Q(0xB0)` moving owner. `moving_animation_check_escape` (`0x003AF950`)
checks two fighter pointers without breaking its loop; both can request a
synchronous zero-blend escape rebind during the one idle-to-escape callback.
They are two successive overlaps, not two simultaneously incoming graphs.

### Debris and procedural cloth

BTL `bg_break_object_parse` (`0x006C5190`) eagerly creates all `A` players
and their `Q(4*A)` pointer array. `bg_break_debris_initialize` (`0x003951A0`)
eagerly allocates `Q(0x30*D+0x10)` state records,
`Q(0xB0*D+0x10)` inline children and, per debris entry,
`Q(0x60*floor(maximum/D))` placement state plus its bound model. Two attack
registrations add `2*Q(0x34)` when their inline sphere owners are supplied.
Resetting or activating those prebuilt debris states does not copy the model
geometry. Shared effects and item spawns requested by a contact are separate
battle-service owners and lifetimes.

`bg_cloth_build_geometry` (`0x003B1AF0`) allocates `Q(0x50) + Q(0x24) +
Q(0x30)`. For grid dimensions `X,Y`, visual construction (`0x003B10B0`)
uses `V=2*X*(Y-1)` vertices and adds a `Q(0x18)` modifier plus `Q(0x200)`
procedural visual. With its nonnull texture and options 1, that visual retains
three `Q(A(4*V))` arrays and `Q(A(V))` markers; the position block is omitted.
Its material/descriptor/part definitions and primary model are inline, while
binding adds `Q(0x50)` for one runtime part and `Q(4)` for one material pointer
(plus temporary `Q(4)`). Solver construction (`0x003B00C0`) adds:

```text
Q(6*X*Y) + Q(4*X) + X*Q(0x50*Y) + Q(0x14*E)
E = X*(Y-1) + (X-1)*Y + 2*(X-1)*(Y-1)
```

For `X=6,Y=4`, `V=36,E=68`: solver nodes cost 3,600 bytes and visual/work
nodes 1,472, **5,072 bytes per cloth**, excluding its outer background class
and registration link. Both helpers borrow and restore the renderer's work
cursor; their temporary work records are not additional heap allocations.

### Interpreting a capacity bound

A retained total is not a load peak. Include transport, inflate tables,
directory sorting, provisional/replaced parser blocks, conversion scratch,
scene records and temporary model/vector construction, with their lifetimes.
The maximum simultaneous node sum still does not prove allocation success in
a fragmented arena. A conservative cumulative request budget can instead
charge every successful allocation once, even blocks later freed or shrunk,
plus each alignment gap. This deliberately avoids assuming those freed holes
will be reused. For a finite construction/rebind sequence, one initially
contiguous gap at least that budget is sufficient if all other allocations
and activity are reserved outside it: each allocation can consume an end of
the remaining gap, and low/high preference can fall back to the available
side. Allocating into another adequate gap can only preserve that reserve.
This is a conditional capacity statement; it does not establish that the
required gap is available at a particular battle load.

## Sampled retail capacity

The arena's usable span between the sentinels is `0x1718F50` bytes. Occupied bytes are
that span minus total free, including node headers, alignment, and the 2 MiB secondary
pool. Fragmentation is total free minus largest free.

| Screen | Overlay | Total free | Largest free | Occupied | Fragmentation |
| --- | --- | ---: | ---: | ---: | ---: |
| Title | BTL | `0x101F7F0` | `0x1018330` | `0x06F9760` | `0x0074C0` |
| Mode select | BTL | `0x0B0B940` | `0x0A6B290` | `0x0C0D610` | `0x0A06B0` |
| Character select | BTL | `0x0CD1560` | `0x0AFD2E0` | `0x0A479F0` | `0x1D4280` |
| Active battle | BTL | `0x0866FB0` | `0x084E210` | `0x0EB1FA0` | `0x018DA0` |
| Collection | ETC | `0x0C89CB0` | `0x0A7EB80` | `0x0A8F2A0` | `0x20B130` |
| Options | BTL | `0x0B09660` | `0x0A96680` | `0x0C0F8F0` | `0x072FE0` |

The active-battle sample recorded peak tracked bytes `0xFCE500`. The same peak also
appears in the sampled Character Select, Collection, and Options states, so it cannot be
attributed to the sampled battle's load. The accumulated counter does not identify when
or for which load the maximum occurred.

**Observation:** The sampled active battle had about 14.7 MiB occupied and one free gap
of `0x084E210` bytes, about 8.3 MiB, holding all but `0x18DA0` bytes of the free space.
An ordinary compressed CCS load adds the fixed transport subtotal, inflate tables, and
parsing/conversion scratch described above; the sample alone does not show their
simultaneous peak or placement.

**Inference (medium confidence):** The two-ended placement preference is consistent with
the sampled battle's large central free gap. That end-state measurement does not
establish the allocation history that produced it or a minimum capacity across battles.
