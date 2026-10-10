# EE runtime lifetimes

## Research coverage

Established: overlay loading, effective ends and temporary phase slack.
Static CRI/ADX stacks, dynamic stacks and high-tail ownership are established.
Persistent pools, startup allocations and CCS-load transients have static lifetime coverage.
Open: battle and menu teardown totals; overlay-constructor callee allocations.
Sampled slack and high-tail changes do not establish future non-use or dynamic heap lifetimes.
Routine, field and data names come from `@annotations/NA2`; addresses are live.

Native lifetime and ownership of overlays, stacks, the high-memory tail, and
the main heap-backed regions in retail NA2 (`SLPS-25837`). CCS container release
belongs to [Resident CCS runtime](../../game/files/ccs_runtime.md); battle
object teardown belongs to
[Battle lifecycle](../../gameplay/session/battle_lifecycle.md).

## Overlay loading

`mwo3_load_file` reads a whole overlay into the fixed destination selected by
`overlay_destination_table`: slot 1 is `0x006B3F00`; slot 0 is `0x00100000`.
Only a complete read reaches `mwo3_initialize_image`. Initialization flushes
the data and instruction caches, zero-fills `Mwo3Header.bss_size` bytes
immediately after the file image, then runs the constructor list bounded by
`constructor_begin` and `constructor_end`.

The header fields are named in `Mwo3Header`. Current overlay program views
begin after the `0x40`-byte header, so these header values and product labels
are verified from the retail files rather than those views:

| Field | Meaning | BTL | ETC |
| --- | --- | ---: | ---: |
| `magic` | file identity | `MWo3` | `MWo3` |
| `kind` | overlay kind | 1 | 3 |
| `linked_base` | load base | `0x006B3F00` | `0x006B3F00` |
| `text_size`, `data_size` | sum plus the `0x40`-byte header is the file size | `0x1DB6C0`, `0x46C00` | `0x24E40`, `0xC080` |
| `bss_size` | zero-filled size after the image | `0x6E80` | `0` |
| `constructor_begin`, `constructor_end` | constructor list | `btl_constructor_table`, 9 entries | empty |
| `product_label` | internal name | `BTL_product.bin` | `ETC_product.bin` |

The image itself needs no heap allocation. The static constructors call no
allocator entry directly; allocation by their callees remains open within
this document's coverage. One BTL constructor registers
destructors through `compiler_cleanup_register`, but overlay replacement does
not run those destructors in the covered native paths. The resident
`compiler_cleanup_head` points to the most recently registered
`CompilerCleanupNode`; registration links its `previous_head` to the old head.

## Overlay lifetimes and phase-only space

Each loaded overlay begins with `Mwo3Header.magic` (`MWo3`) at `0x006B3F00`;
`Mwo3Header.kind` identifies the kind. Effective ends include the zero-filled
tail after the file image.

| State at overlay base | Kind | Effective end | Temporarily unused before `0x008DD080` |
| --- | ---: | ---: | ---: |
| No overlay | 0 | `0x006B3F00` | `0x229180` |
| `BTL.BIN` | 1 | `0x008DD080` | `0x0` |
| `ETC.BIN` | 3 | `0x006E4E00` | `0x1F8280` |

This slack is not persistent free memory. A later overlay transition can
overwrite it, and `BTL.BIN` consumes the complete window. A phase-local
experiment must guard overlay identity, load state, and lifetime.

## Stacks and thread-owned memory

Six resident CRI/ADX thread stacks are statically allocated inside the main
ELF:

| Stack | Range (end exclusive) | Size | Creation owner |
| --- | --- | ---: | --- |
| `cri_worker_88_stack` | `0x003D6B20..0x003D7320` | `0x800` | `cri_create_worker_88` |
| `cri_worker_8c_stack` | `0x003D7320..0x003D8320` | `0x1000` | `cri_create_worker_8c` |
| `cri_worker_90_stack` | `0x003D8320..0x003D9320` | `0x1000` | `cri_create_root_wake_worker` |
| `cri_worker_94_stack` | `0x003D9320..0x003DA320` | `0x1000` | `cri_create_worker_94` |
| `cri_worker_9c_stack` | `0x003DA320..0x003DC320` | `0x2000` | `cri_create_worker_9c` |
| `cri_worker_a0_stack` | `0x003DC320..0x003DE320` | `0x2000` | `cri_create_worker_a0` |

These ranges remain reserved for the resident thread layer. The 8c and a0
creation owners can instead use a caller-supplied stack and size; that does not
make their static default stacks persistent free storage.

`task_record_construct` separately obtains a dynamic stack through the game
allocator, with size `max(requested_stack, 0x800) + 0x400`. Its backing is owned
by the task, with the task's allocator lifetime
([Task system](../task_system.md)).

## High-memory tail

The `0x01FF6000..0x02000000` tail is outside the game allocator and changed
across sampled states. Startup code establishes its two owners:

- `0x01FF6000..0x01FF8000` remains with the `malloc` layer after the arena
  request. `text_draw_progressive` obtains temporary blocks from this layer
  when the string plus its terminator needs at least `0x200` bytes, and frees
  them after drawing.
- `0x01FF8000..0x02000000` is the `0x8000`-byte main-thread stack requested by
  `entry`, with the kernel selecting its address from the request `-1`.

The placement of the stack is an inference from the kernel call's arguments;
see [the allocator document](allocator_and_capacity.md#system-memory-layer).
Both parts must remain reserved.

## Heap-backed regions

| Region | Allocated | Released |
| --- | --- | --- |
| `0x200000`-byte renderer pool | once by display initialization `engine_root_initialize` | never in the covered paths; its entries are recycled every frame by `render_pool_release_frame` |
| `0x10000`-byte untracked buffer | once by `render_untracked_buffer_construct` | not observed |
| Sound controller | once by `afs_manager_allocate` | not observed |
| File-directory text and tables | once by `gzlist_build_tree` during front-end startup | never in the covered paths; the text allocation's base pointer is not retained |
| `0x4D000`-byte IOP module staging buffer | by `iop_bootstrap_modules` | before that routine returns |
| CCS load transients | by `ccs_run_load_pipeline` at the start of each load, at the low end | before a flags-`0` load returns; worker stacks follow their tasks' lifetimes |
| CCS containers | by the parser on the decode worker, at the high end | when their owner destroys the container |
| Deferred-free blocks | by their owner | when their frame countdown reaches zero in `arena_process_deferred_frees` |
