# MWo3 overlay ABI

## Research coverage

Established for retail NA2's resident executable, BTL and ETC: header and
placement, synchronous loader/cache ordering, fixed-address linkage,
constructor initialization, bounded Collection and BTL cleanup, and returned
data lifetime. Open: other MWo3 variants, complete typed interfaces and payload
semantics, indirect workers and cleanup beyond the traced owners.
Names come from `@annotations/NA2`; all addresses here are live.

Static evidence establishes reachable behavior, not observed concurrent-load
or malformed-file failures. The other overlay is outside this analysis.
Task scheduling belongs to [Resident task system](task_system.md), mode
sequencing to [Mode flow](../game/mode_flow.md), animation ownership to
[Animation runtime](animation_runtime.md), and input identities/address
mapping to [Retail game file identities](../game/files/file_identities.md#address-conventions).

## Result

For these two linked images, the loader reads the complete file, including the
`0x40` header, into destination slot 1 at `0x006B3F00`. Text, data, BSS,
constructors and absolute pointers already assume that placement. No runtime
relocation, import/export resolution, magic/kind/base validation or generic
exit hook exists in the recovered loader path.

The sole automatic format hook is the half-open constructor pointer interval.
Application entry and cleanup are ordinary fixed-address interfaces owned by
the mode that calls them. Direct calls, indirect methods and returned overlay
data all require the defining image to remain resident. A resident allocation,
pointer table or context argument does not extend an overlay target's lifetime.

## Inputs and identity

The stripped resident ELF has no symbol-table entries and an empty string
table. Annotation names are recovered names; recognized SDK symbols and original
product/class strings are exceptions. The image labels are `BTL_product.bin`
and `ETC_product.bin`; ETC is 200,448 bytes (`0x30F00`).

The resident load segment starts at `0x00100000`, has `0x507380` file-backed
bytes and `0x5B3F00` memory bytes, ending at the overlay base. Its zero-file-size,
RWE, `0x80`-aligned overlay reservations include these program-header entries:

| Image | Entry | Base | Memory size | End |
| --- | ---: | ---: | ---: | ---: |
| BTL | 1 | `0x006B3F00` | `0x229180` | `0x008DD080` |
| ETC | 3 | `0x006B3F00` | `0x030F00` | `0x006E4E00` |

The intervening reservation is outside this scope.

## File and runtime addresses

Address mapping is owned by
[Retail game file identities](../game/files/file_identities.md#address-conventions).
The imported payload uses live addresses; encoded absolute pointers and
branches use the same addresses. Initialized-data examples are
`btl_u16_table_pointer` → `btl_u16_index_table` (starts 0,1,2,3,4,5), and
`collection_base_type_info_pointer` → `collection_base_type_info` →
`collection_base_type_name` (`ccHomeIspBase`). These are absolute data links,
not relocation or switch records.

The imported overlay programs omit the headers; their established live
locations remain explicit below, and the layout types and consuming routines
are annotated. The resident import maps its zero-filled BSS, whose globals
are annotated in the resident ELF even when overlay code accesses them.
Bytes returned as zero outside a block are not evidence for retail contents.

## Common 0x40-byte header

`Mwo3Header` records the recovered little-endian layout. Field names describe
the proved meaning, not vendor terminology.

| Field | Meaning | Loader use |
| --- | --- | --- |
| `magic` | ASCII MWo3, word `0x336F574D` | Not validated |
| `kind` | BTL 1, ETC 3 | Not validated |
| `linked_base` | `0x006B3F00` | Not validated; destination table chooses placement |
| `text_size` | Text byte count after the header | Not read |
| `data_size` | Initialized-data byte count after text | Not read; not a relocation size |
| `bss_size` | BSS byte count after physical file bytes | Consumed by `mwo3_initialize_image` |
| `constructor_begin`, `constructor_end` | Absolute half-open pointer interval | Consumed by `mwo3_initialize_image` |
| `product_label` | NUL-terminated, zero-padded 32-byte label | Not read |

For both valid retail images:

```text
physical_file_size = 0x40 + text_size + data_size
file_backed_end     = load_base + physical_file_size
effective_end       = file_backed_end + bss_size
```

The loader obtains the physical size from seek, not header arithmetic, and
clears BSS at destination plus bytes read. It does not cross-check these
equations. Text/data spans are linker spans, not EE protection boundaries;
BTL's nominal data includes executable constructors. The import marks that
span non-executable, so some functions require annotation-created entries.
The decoded-instruction censuses in annotations exclude undiscovered executable
data-span bytes.

## Exact clean layouts

| Property | BTL | ETC |
| --- | ---: | ---: |
| Kind | 1 | 3 |
| Base | `0x006B3F00` | `0x006B3F00` |
| Text size | `0x1DB6C0` | `0x024E40` |
| Data size | `0x046C00` | `0x00C080` |
| BSS size | `0x006E80` | 0 |
| Constructor begin | `0x008D6180` | `0x006E4E00` |
| Constructor end | `0x008D61A4` | `0x006E4E00` |
| Product label | BTL_product.bin | ETC_product.bin |
| Physical size | `0x222300` | `0x30F00` |
| File-backed end | `0x008D6200` | `0x006E4E00` |
| Effective end | `0x008DD080` | `0x006E4E00` |

All spans below are half-open memory regions:

| Image | Header | Text | Initialized data | BSS |
| --- | --- | --- | --- | --- |
| BTL | `0x006B3F00..0x006B3F40` | `0x006B3F40..0x0088F600` | `0x0088F600..0x008D6200` | `0x008D6200..0x008DD080` |
| ETC | `0x006B3F00..0x006B3F40` | `0x006B3F40..0x006D8D80` | `0x006D8D80..0x006E4E00` | Empty |

Each image has another zero-filled `0x40` bytes after the header; its first
linked function is at `0x006B3F80`. This is a build convention, not a header
entrypoint.

## Resident loader and selection

`overlay_select` calls `mwo3_load_file`, which normalizes its path, reads
the complete file, and calls `mwo3_initialize_image`; the latter flushes
caches, clears new BSS and runs `constructor_range_run`. The recovered loader
callers, the selector and `manager_setup`, select destination slot 1; the loader
owns the post-read initialization path.

Resident startup separately calls `resident_initialize_constructors` over
`resident_constructor_table`, ending at `0x005D9D40`.

### Destination and filename tables

`overlay_destination_table` is a 16-word internal address array:

| Slot | Destination |
| ---: | ---: |
| 0 | `0x00100000` |
| 1 | `0x006B3F00` |
| 2..15 | Null |

Slot 0 is unused by the recovered path and would overwrite the resident.
There is no slot bounds check: slot 16 uses the next unrelated word, value 1,
and later indices read more unrelated data. Null slots and out-of-range slots
are not recoverable errors.

`overlay_filename_table` contains three pointers. The scoped choices are:

| Selector | Named filename | Normalized path |
| ---: | --- | --- |
| 0 | `btl_overlay_filename`: BTL.bin | `cdrom0:\PRG\BTL.BIN;1` |
| 2 | `etc_overlay_filename`: ETC.bin | `cdrom0:\PRG\ETC.BIN;1` |

The other image is outside this analysis. Selector and header kind are
different fields: kind equals selector plus one for these two files only.
Neither relation nor image identity is checked.

There is no selector bounds check. Selector 3 reads the following zero word
and passes a null filename to append; 4 treats adjacent inline bytes as a
pointer; negative indices read before the table. None returns an
“unknown selector” result.

The resident manager pointer is `battle_manager`. `overlay_select` reloads if
that pointer is null or `BattleManager.cached_overlay_selector` differs.
A null manager permits loading but cannot cache it, so another call reloads.
The return is always 1 after a cache hit or eventual loader completion;
failure cannot be reported.

The cache records the last request, not measured identity. A hit reads no
header or code. External replacement/corruption with the cache unchanged can
suppress a repairing reload. Publication follows the entire read, BSS clear
and constructor interval; `manager_setup` follows the same order when restoring
BTL. Neither supplies a lock or an in-progress value.

**Static concurrency possibility:** during an incoming load the cache still
names the outgoing image; another request for that selector could return on
a hit while bytes are changing, and another incoming request could start a
second load. Disc-readiness polling does not close this interval, because
cache hits bypass it and selection does not set its state. The normal front-end
chain below is serialized; other ordering remains open.

The recovered selection owners are `battle_mode_selector_update`,
`manager_snapshot_state6`, `battle_driver_setup`, `btl_transition_prepare`
and `btl_prepared_state_wrap`. Incoming overlay calls follow selection.
`btl_transition_prepare` first calls the outgoing image at `0x007D7580`
and retains its result, then selects BTL. That outgoing identity remains
unresolved. In BTL this number lies inside `btl_owner_pair_initialize`,
not at a valid entry; membership in BTL's larger reservation does not establish
BTL ownership.

`manager_allocate` creates a `0xDF8` manager when absent, constructs and
publishes it, then calls `manager_setup`. `manager_initialize` sets the cache
to -1, ensuring an explicit initial BTL load and publication of 0.
Allocation failure is not handled before setup dereferences the manager.

Collection releases its ETC objects and returns to a resident Mode Select
callback without replacing ETC immediately. Resident phases run first;
Mode Select phase 3 restores BTL, and phase 4 constructs its selection
controller. Returning to title destroys the manager/cache without clearing
the bytes; a new manager's -1 cache forces BTL reload even if BTL remains.
Object cleanup, replacement and cache destruction are distinct events.

### Front-end thread ordering and its limit

`engine_boot_initialize` creates and starts the MOTHER kernel task with
`resident_flow_dispatch` as its resident entry. Its permanent loop calls
`manager_allocate` directly; the manager selects one callback per invocation,
without spawning BTL/ETC mode callbacks on another thread. The bootstrap,
Mode Select, BTL setup and Collection selection therefore share one thread.
Each synchronous load and constructor interval finishes before its incoming
overlay calls. The loop yields through `task_yield_updates(record, 1)`.
This establishes control-flow serialization, not a loader mutex.

The task lifecycle pass checks neither selector nor header, and
`task_record_construct` accepts arbitrary entry addresses. Its annotation and
`task_record_start` record the bounded construction evidence. Indirect creation,
resident-created workers and resident workers calling overlay methods remain
untraced possibilities.
Resident entry placement, sleep or one lifecycle pass cannot prove overlay
independence or worker completion.

Both task retirement paths invoke the `TaskCleanupRecord.cleanup_callback`
with `cleanup_argument` before terminating and deleting its thread, as owned
by [task termination](task_system.md#termination-destruction-and-ownership).
The recovered MOTHER registration is `mother_cleanup_noop`, retaining no
overlay address. No BTL/ETC cleanup registration is confirmed; indirect
assignments and the original callback type remain open. A retained overlay
callback requires that image through its actual invocation; requesting
retirement does not discharge this obligation. This mechanism is separate
from both compiler cleanup registration and the MWo3 constructor interval.

### Recovered mode-owned entry and cleanup contracts

Collection's resident state machine owns a `0x80` `CollectionOwner`.
Within ETC residence it initializes fields, initializes resources, polls until
exactly 1, releases resources and finally frees the owner. The initializer
does not clear every allocation byte; the paired resource initializer and
fresh-allocation contract matter. Its ten `controllers`, `owned_resources`
and `nested_owner` are released before ETC replacement.

The BTL driver owns a `0x188` `BtlRecordOwner`. Initialization binds 28
rows to `btl_record_definitions`; reset clears their mutable fields and
rebuilds the context value from the resident manager when present.
`btl_record_owner_release` clears some released slots but leaves others;
the resident frees the owner immediately, so this is not an idempotent
release contract for a retained object.

The same setup calls `support_owner_allocate`: reset internal state,
destroy the old resident-held singleton `support_owner`, allocate
`0x24` bytes, construct when allocation succeeds and publish the pointer.
`battle_driver_cleanup` destroys/frees/clears its three child slots in order
(`PracticeDriver.child34` resident child, `preparation` BTL selection child,
`record_owner` BTL record owner), then calls `support_owner_release` to destroy
and clear the singleton. The selection child releases its resources,
`PracticePreparationOwner.owned_objects`, `extra_objects` and its nested
`settings` owner; its fields also are not all cleared before the outer free.

`SupportOwner.vtable` is the resident `support_owner_vtable`, and its member
table is `support_generation_vtable`. The type chain ends at the BTL
`support_owner_class_name`, original `ccBuddyAtkCtrl`; the deleting method
is `support_owner_destroy`. Its signed 16-bit delete flag controls the outer
free; cleanup destroys the two `SupportOwner.slots` children through
`SupportObject.node.vtable`, deleting slot `+0x08`, and clears them. Those
child destinations remain open.
Support gameplay belongs to
[Support mechanics](../gameplay/characters/support_mechanics.md).

Another setup allocates `0x28` bytes and calls `btl_small_owner_initialize`
after BTL selection. The small owner's field meanings remain open: its dwords
at `+0x00/+0x04/+0x08/+0x0C/+0x10/+0x18/+0x1C/+0x20/+0x24` and byte
`+0x14` are cleared. These are application contracts, not header exports;
the loader neither discovers nor invokes their teardown.

### Complete-file read

`mwo3_load_file` builds a 128-byte path from `overlay_prg_prefix`, the
filename and `cdrom_path_normalize`. Normalization changes slashes, uppercases
ASCII after the device colon and appends `;1` if absent.

Before open and again before read it polls
`EnginePadContext.cdvd_recovery_state` through resident pointer
`engine_pad_context`, sleeping 200000 while nonzero. The `0x530` core is
allocated by `engine_root_allocate`, initializes this byte to 0, and advances it through
`engine_update_frame_gate`:

| State | Next |
| ---: | --- |
| 0 | 1 when lower status is 1 or `0x20` and `cdvd_recovery_suppressed` is zero |
| 1 | 2 on next pump |
| 2 | 3 when `cdvd_disk_ready(1)` returns 2 |
| 3 | 4 for `cdvd_recovery_status` results `0x12..0x14`, otherwise 2 |
| 4 | 0 when `cdvd_recovery_task` is absent/complete, otherwise 2 |

The original `cdvd_disk_ready_message` literal, NEW DiskReady Call, identifies
disc readiness/recovery.
The loader does not change this state or check overlay execution; it is no
overlay lifetime lock.

The read order is open with flags 1/mode `0x1FF`, seek end for expected
physical size, seek start, read, close, then postinitialize on exact size.
Each negative operation retries itself on the same descriptor without delay
(the open loop has not acquired a descriptor). A nonnegative short read
closes and restarts the complete open/seek/read cycle. The only delays are
the separate readiness waits. Persistent filesystem failures can spin or
retry indefinitely.

There is no maximum or minimum size check, header validation or span
consistency check. Oversized successful reads can exceed the reservation.
Copy/append have no length bound; the prefix occupies 12 bytes. A filename
up to 113 bytes fits with added `;1` and terminator, or 115 if already
suffixed. The two built-in names are seven bytes. The interface enforces none
of those bounds.

Retries are not transactional: a short read has already replaced the beginning
of the live slot and neither restores the outgoing image nor clears the
partial image. A zero-byte file is an exact-size success using stale metadata:

| Request / previous image | Static result |
| --- | --- |
| BTL / ETC | Stale BSS 0 and empty constructor interval; ETC bytes stay, cache publishes BTL 0 |
| ETC / BTL | Stale BSS `0x6E80` clears `0x006B3F00..0x006BAD80`; reread constructor bounds now zero, cache publishes ETC 2 |

No recovered selector/loader identity check exists. Arbitrary indirect header
consumers remain untraced; the bounded search evidence belongs to
`mwo3_load_file`. Safe slot entry requires higher-level exclusion throughout
retries and initialization.

### Cache, BSS, constructors

`mwo3_initialize_image` reads `bss_size`, calls `FlushCache(0)` then
`FlushCache(2)`, clears BSS at image plus physical size when nonzero, and
then reads both constructor bounds. The subsequent walker advances one
pointer at a time while begin is below end, invokes every entry and finishes
with `constructor_range_finish`, a return-zero no-op.

No range, alignment, nullness or target check exists. Constructors have no
supported parameter interface; `constructor_range_run` records the exact
invocation behavior.

## Relocation, imports, exports, and call convention

### No runtime relocation or symbol records

The header, text and initialized data exactly consume both physical files.
There is no appended relocation/symbol stream. The text/data boundary begins
ordinary payload (`btl_data_boundary_name`, battlegauge, in BTL;
`etc_data_boundary_path`, home.ccs, in ETC). The complete
loader only reads bytes, flushes caches, clears BSS and runs constructors;
it walks no fixups or names. Constructor bounds, constructor entries, data
pointers and direct calls are already absolute.

Changing the destination table or header base alone cannot relocate either
image: calls and dereferences would still use their linked addresses.

### Direct resident-import surface

The two images use a broad statically linked resident interface, including
allocation, CCS lookup, animation, scene composition, matrices and random
values. Their imported service sets differ substantially; the recovered
surface is not a tiny interchangeable service table. Per-target call counts
belong to the target annotations, and aggregate decoded linkage coverage to
`resident_text_start`, `btl_text_start` and `etc_text_start`.
Those censuses count static decoded sites, not execution frequency or complete
semantic coverage.

The interaction-head imports register/unlink objects in resident lists;
their destructor removes an active head before releasing registrations/results
and conditionally frees it. This lifetime belongs to
[Collision](../gameplay/combat/collision.md#resident-query-list-boundary),
separate from compiler cleanup and image loading.

### Indirect dispatch is application ABI, not loader binding

An indirect call does not identify its target's ownership. Concrete object
construction and pointer-table chains establish that boundary; register usage
and decoded call counts remain in the annotations.

Object dispatch varies by class: a BTL object example uses table `+0x00`,
method `+0x24`; Collection teardown uses `CollectionController.vtable` and
`CollectionControllerVtable.delete_method`, with delete flag 1. No single
universal layout or loader import table follows from these examples.

Resident code, current overlay code or callbacks can all occupy a method slot.
An object/table surviving replacement may retain an aligned pointer into the
outgoing image. Mode owners must quiesce and release those objects while their
defining image remains resident.

### Collection tables live in the resident, methods live in ETC

`collection_controllers_construct` creates ten controllers, stores them in
`CollectionOwner.controllers` and invokes each initialization method.
The resident `CollectionControllerVtable` layout has an ETC type-information
pointer, zero word, and delete/initialize/update/present slots. Each construction
first installs `collection_base_vtable` then its derived table.

| Index | Bytes | Original type | Resident table |
| ---: | ---: | --- | --- |
| 0 | 0x34 | ccHomeIspSelectKind | `collection_kind_vtable` |
| 1 | 0x100 | ccHomeIspSelectChar | `collection_character_vtable` |
| 2 | 0x70 | ccHomeIspMovie | `collection_movie_vtable` |
| 3 | 0xA0 | ccHomeIspMusic | `collection_music_vtable` |
| 4 | 0x70 | ccHomeIspCharMenu | `collection_character_menu_vtable` |
| 5 | 0xB30 | ccHomeIspDoll | `collection_doll_vtable` |
| 6 | 0x34C | ccHomeIspVoice | `collection_voice_vtable` |
| 7 | 0x478 | ccHomeIspSkill | `collection_skill_vtable` |
| 8 | 0x190 | ccHomeIspDiorama | `collection_diorama_vtable` |
| 9 | 0x2C | ccHomeIspDioramaMenu | `collection_diorama_menu_vtable` |

Each named table's annotation maps `CollectionControllerVtable.delete_method`,
`initialize_method`, `update_method` and `present_method` to its ETC routines.

The original names are binary strings. For example,
`collection_kind_vtable` → `collection_kind_type_info` →
`collection_kind_type_name` (`ccHomeIspSelectKind`); the base chain ends at
`ccHomeIspBase`. Resident placement extends neither type-information nor
method lifetime.

Construction invokes initialize; controller polling consumes update's integer
result; presentation invokes present. Teardown calls delete with signed
16-bit flag 1 for each nonnull controller and clears its owner slot. Every
deleting wrapper performs class cleanup, restores the base table, frees only
for a positive flag and returns the original object. All ten deletes occur
inside ETC residence before the resident frees the owner. This resolves this
boundary, not every class layout or complete update-state/result semantics.

### Overlay to resident

Overlay imports call final resident addresses directly, without trampolines
or global-offset-table resolution. Both images depend on inherited resident
global state; explicit parameters alone do not describe that dependency.
`resident_text_start`, `btl_text_start` and `etc_text_start` record its exact
addressing evidence. The following globals are annotated in resident ELF BSS:

| Global | Role |
| --- | --- |
| `battle_manager` | Manager/cache owner |
| `active_draw_environment` | Active draw environment |
| `engine_pad_context` | Core/CD/DVD recovery owner |
| `global_font_draw_state` | Shared font draw state |
| `active_render_environment` | Render/light environment |
| `global_transition_pool` | Shared transition pool |

`btl_initialize_remaining_globals` additionally consumes resident constants
and initializes a resident word; its annotation records those accesses.

### Resident context does not extend returned-data lifetime

`btl_record_lookup` ignores its resident context argument. Its unchecked code
index selects `btl_record_descriptor_table`; `BtlRecordDescriptor.count`,
`keys` and `records` describe an ordered signed-halfword key scan. A missing
descriptor/key returns zero; a match returns an initialized-data record with
stride `0x440`. It copies nothing, allocates nothing and checks no image
identity. Invalid indices can read outside the examined table.

The bounded interval has 66 words (codes 0..65): 18 shared descriptors, code
31's three-record descriptor and 47 nulls. The shared codes are
0,2,5,6,8,10,13,14,17,21,23,25,35,42,61,62,63,64.

| Code/key | Descriptor | Keys | Returned record |
| --- | --- | --- | ---: |
| 0 / 1 | `btl_shared_record_descriptor`, count 1 | `btl_shared_record_keys`: 1 | `0x008D0390` |
| 31 / 1 | `btl_code31_record_descriptor`, count 3 | `btl_code31_record_keys`: 1,70,92 | `0x008D07F0` |
| 31 / 70 | same | same | `0x008D0C30` |
| 31 / 92 | same | same | `0x008D1070` |
| 1 / any | Null | None | Zero |

`btl_shared_record_payload` and `btl_code31_record_payloads` end exactly
at their descriptors. They are overlay initialized data, not resident
allocations. Payload fields, key meaning and the supported domain beyond
0..65 remain open.

The examined owners supply code word `+0x56C` with key word `+0x1DC`, or
constant keys 0 and 1; some retain the pointer at `+0x10C`. Those owner-field
meanings beyond their lookup use remain open. The complete leaf overwrites
the context with its descriptor before dereferencing it.
`btl_initialized_resident_word`, cleared on BTL initialization, is neither its
cache nor owner; its broader purpose remains open.

The bounded address-formation evidence does not exclude absolute or indirectly
aliased access; its exact formation census remains in the lookup annotation.

### Resident to overlay

`side_condition_set` calls `battle_session_root`, a BTL root accessor.
At the same address, `0x006B3F80`, ETC has `etc_output_setup`, a
multi-argument output initializer. Both are callable but behavior/signature
differ, so an address alone cannot identify an interface.

Resident calls reach both the shared address range and addresses above ETC's
physical end. Numeric placement establishes neither image identity nor a
common signature: the pre-switch `0x007D7580` example above belongs to
the outgoing image even though it lies within BTL's larger reservation.

The compared resident-called entries in the shared range have different BTL
and ETC bytes. No byte-compatible common entrypoint was found in that set;
similar higher-level behavior elsewhere remains possible. Exact comparison
widths, first words and target/call counts belong to annotations.

The broad fixed-address surface and stale-tail behavior matter together:
under ETC, a wrong call to a higher BTL address can execute stale bytes.
Apparent success does not establish the right image.

### Recovered call convention

Annotation prototypes define the inspected interfaces where their signatures
are established. `abi_general_arguments_forward`, `abi_stack_arguments_consume`,
`abi_float_arguments_consume`, `etc_output_setup`, `btl_scalar_convert` and
`skill_fir_anchor` hold the exact call-convention evidence; unestablished
signatures remain open.

Decompiler ordering of mixed floating and general arguments can mislead;
actual argument use and callers establish the interface. A replacement must
preserve the compiled interface, including inherited resident global state
and saved caller state. The full fixed-address typed catalog remains
unrecovered.

## Automatic entry and lifetime

### Constructor interval

`btl_constructor_table` contains nine entries, invoked after BSS clear in
this order:

| Index | Routine | Live entry |
| ---: | --- | ---: |
| 0 | `btl_initialize_numeric_globals` | `0x008D3400` |
| 1 | `btl_initialize_secondary_numeric_globals` | `0x008D5B70` |
| 2 | `btl_initialize_static_record_owner` | `0x008D5DF0` |
| 3 | `btl_initialize_six_byte_pair` | `0x008D5E20` |
| 4 | `btl_register_static_cleanup` | `0x008D5E60` |
| 5 | `btl_initialize_halfword_float_constants` | `0x008D5F00` |
| 6 | `btl_initialize_derived_float_constants` | `0x008D5F40` |
| 7 | `btl_initialize_converted_scalar_constants` | `0x008D6000` |
| 8 | `btl_initialize_remaining_globals` | `0x008D6060` |

Their per-routine constants, targets and field writes belong to annotations.
The complete ordinary callee family allocates no heap memory and starts no
worker. This is bounded to automatic initialization; later application setup
allocates separately. The two resident array-helper calls pass null element
destructors; the helper supplies each constructor with element/constructing
arguments and can unwind through an optional destructor.

The six-byte and twelve-byte element initializers return the input pointer.
`chakra_control_state` has no virtual table or heap owner. Reset clears its
incompletely understood dwords `+0x00/+0x04` and three pairs of byte/pointer
records at `+0x08..+0x34`, then `ChakraControlState.enabled` and `active`.

The last constructor calls `btl_resident_word_clear` on
`btl_initialized_resident_word`.
Every actual BTL initialization therefore clears this resident word; ELF
residence does not imply preservation across overlay loads. The loader itself
does not clear it.

The bytes after the constructor interval through BTL's physical end are zero:
there is no adjacent nonzero destructor array or tail record. ETC has equal
constructor bounds at `0x006E4E00` and therefore no automatic calls.

### First linked routine is not an automatic loader hook

The first linked address `0x006B3F80` has no header reference and is not
called by either loader routine. BTL's `battle_session_root` takes no
arguments and returns zero or the resident session's root at
`BtlSessionRoot.root`; its resident consumer reads returned-root `+0x1C`
when nonnull. ETC's `etc_output_setup` instead fills its output from signed
halfwords, float pairs and scalar values before calling `scene_output_finalize`.
Neither is a common signature or format entrypoint.

### Replacement and exit

The loader overwrites slot 1 without generic unload, destructor interval or
exit callback. Owning modes explicitly clean objects before selecting another
image.

`btl_register_static_cleanup` instead uses `compiler_cleanup_register`.
`btl_static_cleanup_node` stores `CompilerCleanupNode.previous_head`,
`cleanup_callback` and `object`, with callback `btl_static_cleanup_delete`
and `result_metric_bank`; node and object are BTL BSS.
The resident head is `compiler_cleanup_head`. The scoped reference scan found
registration but no consumer or reset, and neither loader nor selector unlinks it.
This is consistent with process-lifetime compiler cleanup, not an unload hook.
Neighboring BSS owners belong to the
[item cache](../gameplay/projectiles_and_items/battle_item_inventory.md#item-cache).

**Conditional reload hazard:** unless untraced code resets the head, first
BTL initialization leaves it pointing to the BSS node. Reload clears that
same node then registers it again, so `previous_head` becomes a self-link.
No scoped consumer proves a mode-switch failure, but this chain cannot safely
be reinterpreted as an unload facility.

Replacement writes only the incoming physical file and clears only its BSS.
BTL writes through `0x008D61FF` and clears through `0x008DD07F`; ETC
writes through `0x006E4DFF` and clears no BSS. The half-open region
`0x006E4E00..0x008DD080` can retain old BTL bytes after ETC loads.
It is not safely persistent free space; see
[Runtime lifetimes](ee_memory_map/runtime_lifetimes.md) and
[Address space](ee_memory_map/address_space.md).

At the common base, the clean image identity is
`Mwo3Header.magic == 0x336F574D`, `linked_base == 0x006B3F00`, with kind 1
for BTL or 3 for ETC. Only kind distinguishes these images. This tuple has no
hash/version and cannot identify a build. It describes the slot at the instant
read; no execution lock binds that read to a subsequent call. Front-end
sequencing is established, retained workers/callbacks require separate lifetime
evidence.

## Evidence strength and unknowns

The loader/header placement, cache ordering, constructor family, inherited state,
Collection method/type chains, BTL child/singleton boundary and bounded lookup
have strong static evidence. They do not establish a universal vendor format
or an exhaustive semantic catalog of the three programs.

Still open are original vendor field/type names, other format versions and
kinds, precise linker-section composition, complete typed fixed-address
interfaces, indirect worker creation/completion and retained callbacks,
lookup payload/key meanings and the supported code domain beyond 65, and
cleanup/polymorphic targets beyond the resolved owners.

MCP annotates all named routines, mapped tables and resident BSS globals here.
The two header locations cannot receive symbol rows because their imported
overlay programs omit those memory blocks; their facts remain in this document
and consuming routine comments.
