# Resident file and archive services

## Research coverage

Static evidence establishes cache capacities, mount/preload ordering, path
routing, sector I/O, AFS selection, and transport/queue ownership. Indirect
removal and teardown callers, partial-AFS recovery, metadata release, the
dynamic root-buffer consumer and secondary gzip magic remain open. Failure
and concurrency outcomes were not exercised.

## Evidence and annotation owners

The clean retail NA2 resident ELF and extracted supporting files are the
evidence. `FLIST.DIR`, `GZLIST.TXT`, and `ICON.BIN` are
identified in [Retail game file identities](file_identities.md); its
[address conventions](file_identities.md#address-conventions) apply to the
disassembly evidence.

`@annotations/NA2/SLPS_258.37/symbols.tsv` owns routine names, prototypes,
instruction proofs and bounded searches, including `rofs_remove_volume`,
`afs_parse_partition_chunk`, `entry` and `ccs_clear_load_queue`.
`@annotations/NA2/types.h` owns layouts such as `AdxfHandle`,
`AfsPartitionMetadata`, `CcsReader` and `CcsStreamPlayer`. Later BSS addresses
are in owning routine comments because the resident program does not map them.
Exact vendor names and numeric status enum names remain unestablished.

CCS payload parsing, publication and registry ownership belong to
[Resident CCS runtime](ccs_runtime.md). Fighter tables belong to
[Character assets](../character_assets.md), sharing to
[Asset dependency graphs](asset_dependencies.md#all-nine-per-side-selection-slots),
and battle ordering to
[Battle lifecycle](../../gameplay/session/battle_lifecycle.md).
AFS content and codecs belong to [Disc files](disc_files.md) and the media
documents. Overlay selection, Adventure, and general save/load behavior are
outside this investigation; the icon path was followed only to establish its
file contract.

## `FLIST.DIR` cache capacity and normalization

`engine_boot_initialize` enters `file_services_bootstrap`, which describes
FLIST and loads it before mounting the archive. The configured storage is
`0x668` bytes with a maximum name length of 32. Capacity is
`storage_bytes / (maximum_name_length + 9)`: exactly 40 entries, each with
an eight-byte LSN/byte-size tuple and a 33-byte normalized name. The location
tuples precede the name area. `flist_load_cache` parses names and resolves
their physical disc locations; `flist_cache_state` records storage, parsed
count, capacity and name limit.

The clean file is 124 bytes with eight lines, leaving 32 slots unused. More
than 40 lines are not parsed. A name longer than 32 characters is copied
without prior rejection and can cross its reserved stride; unused slots do
not make long names safe.

Cache normalization uppercases ASCII and equates slash styles, unlike the
later case-sensitive ROFS tree lookup. The four direct consumers of
`flist_get_location` divide into two behaviors: the existence query and two
size queries treat zero cached bytes as a miss and search the disc; the cached
LSN predicate only checks for a nonzero LSN. A false predicate therefore does
not establish absence. Physical path construction uses the configured current
directory, adds a separator when needed, appends missing `;1`, uppercases
ASCII and converts `/` to `\`.

The query also accepts an exact 17-character literal with a dot at byte eight,
parsing the two halves as hexadecimal LSN and sector count and converting the
count to bytes. The shape check does not first validate all hexadecimal digits.
Literal `DVD-ROM` instead gives LSN zero and size `-1`.

Clearing resets all four cache-control words. Replacement clears old state
before initialization, and a miss never inserts a new entry. FLIST is a
location cache, not an authoritative list: explicit-device opens can access
unlisted files.

## `DATA.CVM` mount and root directory

`file_mount_data_cvm`, called directly only by the file bootstrap, performs
this startup sequence:

1. Retry ROFS initialization until success.
2. Initialize the ADXF/ROFS adapter with argument zero.
3. Retry mounting `VOL` from `CDV:data/data.cvm` with password
   `cc2fuku` until the mount returns zero.
4. Select `VOL`.
5. Register the no-op ROFS error callback.
6. Retry loading `VOL:/` into the fixed root-directory buffer until success.

The embedded ROFS banner identifies version 1.80, built
2005-11-29 13:28:55. Embedded `rofs_if.c` and `ROFS_LoadDir` identify the
directory service. Its root capacity is 68; directory storage is
`0x18 + capacity * 0x30` bytes, giving the fixed `0xCD8` root buffer.

Initialization, mount and root-load failure all retry indefinitely. This
startup sequence has no alternate CVM or host route. Wrapper names describe
their proven roles; exact vendor names are not embedded.

## `GZLIST.TXT` grammar and resident tree

`resident_flow_dispatch` calls `gzlist_build_tree` during startup. It reads
the complete clean 103,848-byte file and builds a linked directory/file tree.

The first section has 21 directory records: the root and 20 children. Their
counts sum to 2,332 children, comprising 2,312 files and 20 directories. The
files are the 2,310 CCS members, GZLIST and ICON. Each directory reserves four
extra entries and allocates `0x18 + (listed_count + 4) * 0x30` bytes.

`GzlistDirectoryNode` links siblings, file and child lists, its name, ROFS
capacity and directory buffer. `GzlistFileNode` links files and stores their
name and decoded size. The second-section grammar is
`path compressed_size gzip_size`: both numbers are read, but the compressed
size is discarded. `file_metadata` returns the stored gzip size. Consumers
treat zero as raw and nonzero as both the gzip marker and required decoded
allocation size. The compressed read length comes from ROFS.

Tree components use bytewise, case-sensitive comparisons. Both slash styles
parse, but case and spelling must match. The parser also allocates a dynamic
root-node buffer; established root opens use the fixed buffer. No consumer of
the dynamic root buffer is proven.

## Directory-metadata preload

Startup allocates the `rofs_data_load_task` worker at priority `0x28` with
requested stack `0x4000` (scheduler backing `0x4400`). Named
`Load ROFS_Data`, it waits for `rofs_preload_start` and yields before
recursing through the root's child list. Each child retries its directory
load with yields, then visits its children and siblings. The root was loaded
synchronously.

`rofs_preload_complete` participates in the startup barrier. This is eager
directory metadata loading, not reading or decompressing 2,310 CCS payloads.
All 21 dynamic buffers total 116,472 bytes (`0x1C6F8`); excluding the
unproven dynamic root buffer, the 20 children total `0x1BD80`.

## Logical and explicit path routes

`file_open_required` separates logical and explicit-device opens through
`file_resolve_device_path`:

| Class | CRI spelling | EE file-I/O spelling |
| --- | --- | --- |
| Host | `HST:` | `host0:` |
| Optical disc | `CDV:` | `cdrom0:` |

Recognition is a case-sensitive substring search, not a path-start check.
Once recognized, the resolver removes everything through the first colon and
chooses the requested output spelling.

An unrecognized path is logical: split its final component, find the preloaded
directory, and open the leaf relative to that handle. A leading slash starts
at the fixed root handle; a plain filename uses handle zero. An explicit disc
path instead becomes a complete rewritten pathname opened with directory zero,
bypassing the GZLIST tree.

The retail host-rewrite branch contains a null store before prefix copying.
Recognizing host spelling therefore does not establish a usable host open,
independently of later open failure. Both generic open branches also treat
failure as fatal, storing through zero and retrying rather than returning a
recoverable error.

### Device registry and mounted-volume selection

ADXF open requests a lower stream open and pumps until its pending flag clears.
The stream service performs generic device open, sets state 4 on failure and
settles bounds before reads. A lower stream owns an eight-byte
`DeviceFileHandle` from a 40-slot pool: a saved callback table and device
file handle. Close dispatches through that saved table and clears the pair.

Device splitting uppercases only the name before the colon. The remaining
filename is not normalized there. A separate 32-entry registry holds
callback tables and inline names. With no explicit device, selection uses the
registered default. An unregistered explicit name also retries with the
default, restoring the original complete pathname for it. This establishes a
selection branch, not successful unknown-device access or an alternate CVM.
The default can be set only to a registered name; an empty name clears it.

Control operation 100 governs rebuilding the filename with its device prefix.
ROFS returns 1, preserving mounted-volume identity through splitting and into
its open callback.

Startup registers `ROFS`; its adapter banner is ROCI 1.15, built
2005-11-29 13:28:57. Mount opens the backing CVM through the generic layer,
then issues control operation 2. The adapter accepts a non-`ROFS` volume
name no longer than eight bytes, registers mounted callbacks and passes the
backing handle/password into ROFS. The ordinary operations of the ROFS and
mounted-volume tables agree, but the volume table's first callback is null;
the ROFS table's first callback pumps services, not initializes them.

A failed mount unregisters the volume except for `-0x68`. Initialized ROFS
returns that value for an already-existing volume before allocating or reading
another archive. The outer mount closes the backing generic handle after a
negative result and retains it with the mounted archive on success.

Selecting `VOL` sets the generic default, queries volume information with
control 5 and invokes control 6 after a nonnegative result. Information returns
a borrowed name pointer and the backing generic handle; a missing volume
zeros both and returns `-0x69`. Selection stores the default volume-record
pointer in the ROFS context.

Ordinary mounted open accepts pathname and directory. Ordinary close releases
the ROFS file slot; it neither unmounts nor closes the backing CVM.

### Volume removal and backing-file close

`rofs_remove_volume_inner` queries information, requests control 3 removal
after a nonnegative information result, and unconditionally closes the saved
backing handle. It ignores the removal result and therefore does not preserve
the backing handle when removal fails. Its outer wrapper has no direct
resident reference; indirect retail reachability is unknown.

Backend deletion finds the volume, scans its file pool and releases in-use
linked files with the same backing handle. Release stops a state-2 file;
backend stop is called only when its operation is also 1. It then clears the
operation and in-use fields. Releasing a file slot does not close the archive.

The scan advances its row pointer only after an in-use row with a nonnull
volume link. An unused or unlinked row advances only the loop counter and is
revisited, skipping later slots. Afterward the volume record is zeroed and a
default pointing to it is cleared. This cleanup limitation is static evidence,
not an observed stale-handle or cancellation outcome.

#### Registered removal callback and wrapper reachability

Both registered tables dispatch control 3 directly through
`rofs_adapter_control` to backend deletion, bypassing the outer/inner
information-query and backing-close wrappers. The adapter rejects literal
`ROFS` and unregisters the device only after backend result zero.

Device unregistration clears only the first name byte and leaves the callback
pointer. It invokes no close, destructor or removal callback. Registration
obtains a table through the supplied constructor and uses the first empty-name
slot when there is no match.

Retail reachability of the backing-close wrappers remains unestablished;
registering removal does not prove retail invokes it. The bounded evidence
belongs to `rofs_remove_volume` and `device_remove_volume_control` annotations
and does not exclude computed pointers, aliases or uninspected callers.

#### Other teardown lifetimes

ROFS context finalization requires a nonnull context whose initialized word is
1. It releases every file, clears every volume, calls the physical driver's
finalization callback, zeroes storage and clears the context pointer. The
selected driver callback is a no-op: neither it nor volume-record clearing
closes the backing generic handle. Valid backend initialization first performs
this teardown. This establishes reinitialization's library contract, not a
retail unmount event.

Generic device finalization instead decrements an initialization count and acts
only when it reaches zero. It closes every allocated generic handle through its
saved table, then clears all 40 slots, registrations and the default. Retail
finalizer reachability remains unestablished.

An existing generic handle keeps its saved callback table after registration
clearing; ordinary close does not resolve the name again. Outer volume removal,
context teardown, unregistration and generic-pool finalization have distinct
responsibilities and gates, without an established retail shutdown sequence.
The outer volume enter/leave wrappers are no-ops and supply no locking around
query/remove/close. Concurrent outcomes and locks in lower layers remain
unresolved.

## AFS partition selection and member opens

AFS uses `afs_partition_registry`, a separate 256-pointer registry of borrowed
caller metadata. IDs must be 0 through 255 and metadata nonnull. Temporary
ADXF cleanup never frees those allocations.

`afs_begin_partition_load` is shared by explicit archives and nested members.
Its singleton parser rejects another admission while state is 2, requires
temporary storage with positive capacity, installs caller metadata, opens a
transport and reads sector chunks. Ordinary wrappers supply the 64-byte-aligned
`0x800`-byte `afs_default_input`. Polling samples lower status, consumes
completed chunks and starts subsequent reads. Explicit all-members completion
sets 3; visible format, count, size-limit and read-start failures set 4. These
transitions differ from merely copying lower handle status.

`AfsPartitionMetadata` records computed metadata size, word/halfword member counts,
size mode, a `0x100`-byte pathname, directory handle, archive base sector,
first member offset and member sizes. Mode 1 stores exact byte values as
words; mode 0 stores sector values as halfwords. Metadata size is
`count * 4 + 0x120` for exact mode and
`(count * 2 + 0x11C) & ~3` for sector mode. Established field offsets are
in the shared type, not a separate layout here.

The parser validates only the first three `AFS` magic bytes. It compares
the little-endian 32-bit count as signed against `0x10000`, then rebuilds
the accepted count from its low two bytes. Exactly `0x10000` therefore
becomes zero, while high-bit malformed counts are not rejected by that signed
upper test. This limitation does not establish archive usability.

Only the first member offset is retained; later offset words are skipped and
their adjacent sizes recorded. Exact mode keeps byte sizes; sector mode rounds
them upward and rejects values outside 16 bits. For nonnegative sizes the
bound is `ceil(bytes / 0x800) <= 0xFFFF`, at most `0x07FFF800` bytes,
one sector below the diagnostic's nominal 128 MB. The first sector-mode
offset is shifted down without that member-size ceiling check.

`afs_resolve_member` reconstructs start from archive base, first offset and
rounded sizes of preceding members. It returns the selected sector length and
exact or rounded byte length according to mode, without consulting the
selected original offset. The representation assumes sequential sector-packed
members; gaps or independently authored offsets are not represented.

Member open borrows the partition metadata's pathname and applies reconstructed
bounds to its stream. Metadata must outlive that handle; close releases the
member transport, not the partition. Explicit pathname/directory/start/count
open is a separate variant. Nested parsing uses the internal member opener;
retail callers of the two public wrappers remain unestablished.

Startup serially loads these top-level archives, prefixed with `CDV:data/`:

| Archive | Partition ID | Size mode |
| --- | ---: | --- |
| `sound.afs` | 255 | Exact bytes |
| `stream.afs` | 254 | Sectors |
| `rpgvoice.afs` | 253 | Sectors |
| `plvoice.afs` | 252 | Sectors |

It then follows three configured nested-partition arrays, using the top-level
ID and member index to load child metadata. Both startup helpers yield until
state 3 only; neither breaks on 4. The separate blocking sector-load helper
returns `-1` on 4, but startup does not use it. Packed halfword ID loads,
mode stores and tail-call argument forwarding are recorded with the startup
and mode-loader annotations.

Successful metadata completion and explicit parser failures close the
temporary handle and clear transport, member cursor and input-sector count.
Registry and metadata remain. Cancellation synchronously stops a non-idle
handle, sets state 1 and performs that same transport cleanup. It neither
unregisters nor erases partial metadata. Member validation checks presence and
index range, not parser completion. Scoped startup callers do not establish
use of canceled partial metadata.

### Interrupted partition ownership and library teardown

The admission gate is singleton state, not a per-partition completion marker.
After refusing state 2, a new admission closes a leftover handle, resets ID to
`-1` and state to 1, then validates storage/metadata. A populated registry
slot is allowed. Admission sets state 2, clears only the first `0x11C`
metadata bytes and replaces the selected registry pointer before open. It
neither frees previous metadata nor checks member handles borrowing it.

Cancellation requires a nonzero temporary handle and nonnegative recorded ID.
It stops a numeric status other than 1, sets parser state 1 and clears only
transport/cursor/input-sector count. The ID, input-buffer pointer, registry and
caller metadata survive. Matching-ID polling without a handle returns state 1
without reparsing; a different ID returns `-3` first.

Failure cleanup depends on its branch. A lower status other than 3 is copied
to parser state and returned before consumption/cleanup; lower 4 alone leaves
the temporary handle. A rejected initial read closes the handle but leaves its
global pointer nonzero. Open failure instead stores zero while leaving new
metadata registered. All preserve caller allocations. After starting another
chunk read, the parser again copies lower status, distinct from its explicit
all-members-recorded transition; malformed/truncated input cannot be treated
as proven complete from those copies alone.

Member validation reads no singleton completion state. Replacing a registry
pointer does not retarget an open handle's borrowed pathname. Opening unfilled
sizes or freeing old metadata while a member remains open is unproven, as are
concurrent replacement outcomes and retail partial-metadata recovery.

ADXF initialization increments a count and initializes the handle pool and
registry only on zero-count entry. Finalization decrements it; zero closes
all in-use ADXF handles, resets parser ID/state and clears registry/pool
without freeing caller metadata. Close-all has no registry operation. These
library contracts do not establish retail shutdown or cancellation admission;
the bounded caller evidence is in `adxf_finalize` and `afs_cancel_partition`.

### Nested metadata allocation and pathname ownership

Startup allocates a `0x718`-byte `AfsManager` immediately before partition
loading. Its four top-level pointer/capacity pairs and nested pairs refer to
separate heap allocations. Configured zero member count leaves a nested pair
zero, and the nested helper skips null metadata. Manager allocation, caller
metadata, parser transport and registry entry are separate lifetimes.

For the first sound path, 13 configured records produce a `0x154`-byte
top-level allocation. The first record's count `0x004E` produces a separate
`0x1B8`-byte child allocation. After top-level 255 completes, startup loads
destination ID 0 from source 255, member 0 and that child pointer. Source and
destination slots differ. The helper waits for 3 without cancellation/recovery.

Nested admission first opens a member borrowing the parent's pathname.
Resolution then copies up to `0x100` pathname bytes into the child's own
metadata and returns its directory/reconstructed base sector. The temporary
handle borrows the parent, while the child gets its own path copy. Closing
that handle frees neither parent nor child metadata. The selected startup
trace establishes no release path for the manager's metadata allocations.

## Sector I/O contract

The resident wrappers are sector-oriented. `file_read_sectors_required`
truncates signed byte length to `0x800`-byte sectors; a positive tail smaller
than a sector is not transferred. It returns the original requested length.
`file_seek_bytes_rounded` rounds positive byte offsets upward to sectors;
`file_size_sector_bytes` reports sector count shifted left eleven.

During a transfer, the engine pause flag causes the reader to seek back to its
saved sector and retry. Lower state 4 also retries. States 1, 3 and 4 remain
numeric because the binary does not identify their enum names. GZLIST consumers
use sector-rounded file sizes. The icon path independently reads a `0xE920`
payload through a `0xF000` request.

### Lower ADXF handle and request ownership

Embedded diagnostics identify `adxf_ReadNw32`, its 64-byte-alignment wrapper
`adxf_ReadNw`, and `adxf_Stop`; descriptive annotation names are
`adxf_read_nw32`, `adxf_read_nw`, and `adxf_stop`. Public wrappers use
the library critical section.

The pool has 16 inline `0x48`-byte `AdxfHandle` slots, separate from the
persistent player's 16 requests and the unbounded linked queue. Allocation
selects the first free slot and constructs a lower stream with arguments
`0, 0x100`. Open records path, directory, size and position; lower state 4
closes/clears the slot before returning zero. Exhaustion also returns zero
after a diagnostic; required-open does not propagate it.

Aligned read rejects an unaligned destination with `-3`. The inner read
returns `-3` for null handle, negative sector count or null buffer; zero
without replacing an active state-2 request; `-1` for an existing adapter;
and `-2` for adapter-construction failure. The adapter wraps a borrowed
caller buffer.

Requests are clamped to remaining sectors. An empty request immediately becomes
3; a nonempty request becomes 2 and starts the stream. Pumping scans all 16
in-use handles. State 2 copies lower status and transferred count; terminal
3 or 4 advances logical position and releases an owned adapter. The adapter
ownership marker controls destruction; the caller buffer is never freed.

Status getters return the handle byte without advancing I/O. Required-read
pumps before polling, returns the original byte length on 1 or 3 and retries
4. It ignores the read-start return and never checks transferred sectors
against requested length. Its returned byte count therefore does not prove
full transfer after rejection or EOF clamping. This is a static consequence,
not a measured short read.

Synchronous stop samples transferred count, releases owned adapter and returns
to 1. Asynchronous stop sets a pending latch; pumping releases/clears it when
the lower state becomes 1. A completed state 3 resets directly to 1. Seek
synchronously stops 2, applies absolute/current/end movement and clamps to
`0..file_size`.

Close stops state 2, closes/destroys the stream and clears the entire slot. It
does not free read buffers or partition metadata. This stop family differs
from cooperative wrapper cancellation and scheduler termination; CCS
publication/cancellation ownership is in
[Loading and cancellation](ccs_runtime.md#loading-and-cancellation).

## `ICON.BIN` memory-card role

`card_create_icon` copies `icon.bin` to each PS2 save directory as
`icon00.icn`. Its one-record source slice begins at zero with length
`0xE920`. It opens through the generic resident wrapper, reads the rounded
`0xF000`, opens the card destination with mode `0x203`, writes exactly
`0xE920` and closes it.

The clean source is 61,440 bytes (`0xF000`); its final 1,760 bytes
(`0xE920..0xEFFF`) are all `0xFF`, matching that rounded-read/short-write
contract.

`card_write_icon_sys` separately writes a `0x3C4`-byte `PS2D` file with
`icon00.icn` in `CardIconSystem.first_icon_name`, `second_icon_name` and
`third_icon_name`, embedded as `SaveCardContext.icon_sys`. The type names the
observed eleven-byte writes; full slot capacities remain unestablished.
The source's save-icon role is confirmed; its internal visual and animation
fields remain undecoded.

## Payload transport, gzip stage, and background requests

### One-shot loader

`ccs_run_load_pipeline` synchronously orchestrates a `0x34`-byte
`CcsLoadWrapper`. Zero GZLIST metadata connects read directly to the
raw/decoded consumer ring; nonzero metadata inserts compressed source and
`ccUngzip` stages. `LoadRead`, `LoadGzip` and `LoadDecode` have
priorities `0x74`, `0x7E` and `0x7F`. Input/output chunks are
`0x10000` with four slots each.

The coordinator waits for reader/consumer completion, closes the file, and
for transient compressed loads separately waits for gzip completion before
destroying the source ring. It exposes no load-status return.

Visible callers use two exact flags. Zero selects transient streaming: an
`0x80`-aligned `0x40000` input/raw backing and independently owned decoded
output backing when compressed, all released by orchestration. `0x100`
retains materialized transport: raw allocation rounds sector file size to an
input chunk; gzip allocation rounds the GZLIST decoded size to an output
chunk. Rings/backing survive until transport destruction, which does not
destroy the downstream result whose ownership already transferred.

Ring setup distinguishes external retained and owned backing. Retained
descriptor count is `(total + chunk) / chunk`, reserving a sentinel on exact
chunk multiples. Allocation tests exact `flags == 0x100`, but transient
cleanup tests that bit `0x100` is clear. No mixed-bit caller was found.
Allocation and open failures are unchecked.

### Transport close, drain, and cancellation

A `TransportDescriptor` is `0x0C` bytes: count, data and state. States
0, 1 and 2 mean available/empty, ordinary committed chunk and final descriptor.
Writable-span requests sleep while occupied; requesting the next span commits
a full preceding chunk as 1. Finish commits the current partial descriptor
as 2, clears abort and wakes the consumer. It finalizes a stream without
destroying storage.

Drain discards ordinary descriptors until 2. Reaching an empty slot first sets
abort, wakes a producer and waits for its final descriptor. Draining can stop
reading before the remaining file is consumed, but still waits for final
production; it does not immediately close the file. Retained mode preserves
consumed descriptors while transient mode clears them for reuse. Releasing a
span wakes the producer without destroying a ring or terminating a task.

The one-shot reader checks ring abort between chunks, then finishes and marks
read completion; it does not directly check wrapper cancellation. Inflate
checks destination abort between blocks and returns `-1`; whole-stream
decode then finishes the destination, drains/releases the source, frees
scratch and returns partial produced count. Thus consumer drain propagates
backward through gzip to the reader without a propagated load-status error.

Wrapper cancel sets its own byte and an existing container's cancel byte. A
previously canceled decode worker skips parsing and drains; parser and
already-published-container cancellation belong to
[Loading and cancellation](ccs_runtime.md#loading-and-cancellation).
The coordinator still waits for read/decode before file close. It clears its
serialization gate immediately after close, before ordinary compressed cleanup
waits for gzip. The gate therefore excludes neither the whole cleanup tail nor
the retained-ring lifetime.

Transport destruction releases nonzero rings, gzip object/task and backing.
It neither closes the file nor destroys the downstream object and leaves
destroyed pointers uncleared. It is one-use destruction after orchestration,
not cancel/reset/join. Ring storage release has no sleeping-user check.
`task_request_termination` marks termination only when unprotected and not
already marked, sleeping a newly marked caller; it has no completion wait.
Existing completion flags and caller ordering establish when storage can go.

### `ccUngzip`

`CcsUngzip` is `0x44` bytes. Its named routines cover header parse, CRC32,
whole decode, byte fetch, source/destination linking, destruction and inflate.

The header parser accepts `1F 8B` and a secondary `1F 1F` comparison,
requires method 8, reads MTIME and handles FEXTRA, FNAME and FCOMMENT. It
neither consumes FHCRC nor visibly rejects reserved flag bits. Invalid magic
reaches a null store; a positive non-8 method reaches the no-op diagnostic.
The secondary magic's purpose remains unresolved.

Except with destination mode 2, decode allocates output-chunk-sized scratch,
commits output chunks and frees scratch on normal/abort exit. Both resident
callers ignore its produced-byte return.

After inflate it reads the eight-byte trailer and checks CRC32/ISIZE. Memory,
format, invalid-method, CRC and length diagnostics all call the no-op
`ungzip_diagnostic`; no failure propagates, and a partial/corrupt count can
be returned as the stream closes. Produced length is not compared with
GZLIST allocation size. An undersized corrupt retained entry can therefore
make output capacity unsafe; this is an inference, not a corrupt-file experiment.

### Persistent three-task pipeline

The persistent `CcsStreamPlayer` owns `PlayRead`, `PlayGzip` and
`PlayDecode`, decoded/raw and compressed rings, and an embedded gzip object.
Its request array has 16 `0x14`-byte rows containing path, result, retention
byte, flags and metadata sentinel: `-1` unknown, zero raw, nonzero gzip.

The read worker opens, looks up GZLIST, records sector size and streams into
the selected ring. The gzip worker waits for lookup, skips raw entries and
decodes compressed entries into the shared decoded ring. Compressed-to-raw
transition waits for the gzip cursor to catch up, preventing entry
interleaving. Persistent orchestration holds serialization value 2; one-shot
uses 1.

Destruction requests all three terminations and releases rings/owned buffers.
That request is not join; normal orchestration separately waits for completion.

### `LoadBg` queue

The background queue is an unbounded linked FIFO of `0x48`-byte
`CcsQueueNode` objects, each with path, flags, state, prescanned sector size
and an embedded one-shot wrapper. A single `LoadBg` task processes it at
priority `0x73`, requested stack `0x1000` (allocated `0x1400`).

| State | Meaning |
| ---: | --- |
| 0 | Queued |
| 1 | One-shot running |
| 2 | One-shot returned |
| 3 | Already resident |

Enqueue borrows the pathname without copying it and returns a node or zero
for an exact case-sensitive duplicate. Duplicate detection covers all linked
states, including completed/already-resident nodes, until cleanup. It differs
from normalized container-basename lookup described in
[Handle layers](ccs_runtime.md#handle-layers).

The worker is asynchronous to its caller but serial internally. State 2 is
unconditional because one-shot has no failure result; it checks neither
publication nor retry. State 3 leaves the embedded result zero rather than
attaching the existing container. Cancellation is checked only between nodes,
with no proven public cancel-current API.

The task's caller payload records current node only during blocking load,
between-node stop and progress mode. Completed nodes remain linked after its
global worker pointer clears. The active predicate is consequently a worker
fence, not success, per-node status, empty-queue status or a thread join.
Starting while a worker exists returns without resetting states or removing
nodes.

The scheduler owns the `0x4C`-byte descriptor and stack. Construction stores
entry and clears callback/argument and caller fields. Queue start sets its
name/current/stop/progress but registers no retirement callback. Normal exit
clears the global pointer before requesting termination; later scheduler passes first
mark pending retirement, then unlink, invoke any callback, terminate/delete
the thread and free stack/descriptor. Queue inactivity precedes retirement,
which does not walk nodes or clean the queue. Generic name lookup exists,
but bounded name-construction searches establish no concrete name-based
queue stop/cleanup caller.

Progress mode prescans nonresident sector bytes and reports
`completed * 100 / total`, changing only after whole requests. Zero total
returns `-1`; exit resets counts, so durable 100 percent is not guaranteed.
Start argument 1 chooses progress, not result deletion.

Normal cleanup preserves registered downstream objects, detaches embedded
results, destroys transport and frees nodes. The alternate branch deletes a
nonzero result first; no nonzero mode writer is established. Neither branch
checks state or activity, and head/tail reset follows the complete walk.
Cleanup does not stop or wait for the current load; callers must reach the
inactive fence first. Selected resident callers follow that order.

#### Queue-global writes and rebasing bounds

Boot clears the cleanup mode and other queue globals before GP setup; new
worker start also clears that byte. An already-active start returns before
clearing it. These are the only observed mode writes, both zero, so the proven
start interface supplies no alternate deletion admission.

Queue storage, worker and byte-total ownership are separate. No nonzero
cleanup-mode writer or separate stop writer is established. Bounded direct
searches do not exclude indirect writers through computed pointers, aliases
or general memory-writing callers; retail result-deleting cleanup remains
unproven. Exact checks and live locations belong to `entry`,
`ccs_start_load_queue`, `ccs_load_queue_worker` and `ccs_clear_load_queue`.

`battle_state_create_fighters` waits for an inactive worker, cleans the
queue, then adopts both sides' published containers. Adoption/cache ownership
is in [Adoption and cache reset](asset_dependencies.md#adoption-and-cache-reset);
ordering is in
[Resident setup order](../../gameplay/session/battle_lifecycle.md#resident-setup-order).

## Useful negative results

- Startup preloads directory metadata rather than all CCS payloads.
- GZLIST's compressed-size column is discarded and its tree does not case-fold.
- Mount failures retry indefinitely; required-open has no recoverable failure.
- No dynamic root-buffer consumer is proven.
- Gzip diagnostics do not propagate load failure.
- Background requests run serially with no failure state or retry.
