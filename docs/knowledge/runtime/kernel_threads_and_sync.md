# EE kernel threads and synchronization outside the task list

## Research coverage

Established: the independent dispatcher, RCNT2 alarm-delay lifetime and mode
contracts, MPEG semaphore ownership, CD callback registrations and teardown,
and six CRI thread families with their priorities and stop/done protocol.
Open: constructor reachability, physical delay timing, mode persistence,
wait failures, optional CRI callers and successful shutdown interleavings.
Routine, structure and resident data names come from `@annotations/NA2`.

These are static contracts of the retail NA2 (`SLPS-25837`) resident ELF.
Scheduling, elapsed time, queue overrun and failure-path outcomes have not
been observed. CRI vendor workloads were not reverse engineered. Counter
coverage is the selected alarm backend, not a complete timer-library census.
Binary identity and live address conventions follow
[Retail game file identities](../game/files/file_identities.md#address-conventions).

These owners do not allocate, append or flag a `0x4C` task record.
Task records, manager waits and root pacing belong to
[Resident task system](task_system.md); file and CD request semantics to
[Resident file and archive services](../game/files/runtime_services.md); and
PSS selection to
[Audio and video replacement](../game/files/audio_video_replacement.md).

## Separate kernel dispatch queue and semaphore

`kernel_dispatch_initialize` (`0x0015EAB8`), reached by
`sdk_boot_initialize` (`0x00168058`), creates the separate
`SceKerneltopThread` dispatcher. Its entry is
`kernel_dispatch_queue_worker` (`0x0015E9E0`), its stack is
`0x400` bytes and its initial priority is 0. It starts through
`thread_start_dormant` with its queue as the argument and changes the
bootstrap caller's priority to 1. The ordinary root later changes its own
priority to `0x78`
([manager ordering](task_system.md#manager-pass-and-ordering-boundary)).

The dispatcher uses `kernel_dispatch_thread_id` and a separate event
semaphore whose maximum/initial count is `0xFF / 0`. The BSS storage is:

| Named BSS storage | Established role |
| --- | --- |
| `kernel_dispatch_stack` | Fixed dispatcher stack, `0x400` bytes |
| `kernel_dispatch_semaphore` | Dispatcher semaphore ID |
| `kernel_dispatch_read_index` | `KernelDispatchQueue` base and read index |
| `kernel_dispatch_write_index` | Queue write index |
| `kernel_dispatch_commands` | 512 `KernelDispatchCommand` slots |

Each slot holds a command and byte operand. Producers and the consumer mask
their index with `0x1FF`, use that slot, and replace the index with the masked
value plus one. A producer stores both bytes before signaling; one semaphore
wake consumes one slot.

| Command | Operation | Producer |
| ---: | --- | --- |
| 0 | Wake the operand's EE thread | `thread_wake_interrupt` (`0x0015EBA8`) |
| 1 | Rotate the operand's ready queue | `kernel_dispatch_rotate_ready` (`0x0015EC40`), unsigned priority below `0x80` |
| 2 | Suspend the operand's EE thread | `kernel_dispatch_enqueue` (`0x0015ECC0`) |

Wake and suspend compare the requested thread with the interrupt-context
current thread. A different thread is operated on directly; the current
thread is queued only when its unsigned ID is below `0x100` and the
dispatcher ID is nonzero. `cri_wake_thread_interrupt` (`0x0012E530`)
admits a nonzero ID only for reported status 4 or `0xC`; the display
interrupt's root wake is separately gated on status 4.

There is no queue-full comparison, pending-slot ownership check or retry on
signal failure. Semaphore creation failure stops construction; thread
creation failure deletes the semaphore. No normal teardown is recovered
after start. These contracts do not establish an actual overrun. Callers of
rotate/suspend remain unresolved within the bounded direct-reference search.

The dispatcher does not read task runtime flags. Command 2 therefore does
not supply the task manager's missing
[runtime-`0x0010` producer](task_system.md#runtime-flags-at-0x10).
Its semaphore wake is separate from `task_manager_wake`.

## Alarm-backed delay semaphore

`thread_delay_microseconds` (`0x0015ED58`) owns a private semaphore named
`SceKernelDelayThread`, with maximum/initial count `1 / 0`. CPU status
bit `0x10000` must be set. It converts the request through
`alarm_units_to_count(0, requested_delay)`, registers
`delay_alarm_signal` (`0x0015EF98`) through `alarm_register`, waits,
deletes the semaphore and returns zero. A failed registration also deletes
the semaphore. The callback signals its semaphore context and returns zero;
it does not delete the semaphore.

The wrapper ignores the wait result, retains no alarm handle and never
cancels the alarm. Successful wait and callback completion are therefore
assumptions of the local lifetime, not checked guarantees under kernel
failure. The alarm registration borrows its callback and context: it neither
copies nor retains nor frees the pointed-to context. Recycling changes the
free-list link and clears `KernelAlarmRecord.timer_handle`; callback/context
persist until a later registration overwrites them.

This path uses a counter deadline, not manager wakes or task-cycle counts.
It calls no task wait helper and publishes no task runtime `0x0008`.
File-service retry semantics remain with their linked owner.

### Counter mode admission and conversion units

The boot path selects mode 2 through
`sdk_counter2_records_initialize` (`0x001686B0`), then calls
`sdk_counter2_start` (`0x001688F0`). The initializer rejects an already
installed handler, installs `sdk_counter2_interrupt` (`0x00168C50`) on
interrupt channel `0x0B`, and sets
`mode = (old_mode & ~3) | caller_mode | 0x300`. It does not range-check or
mask the caller's mode. If enable bit `0x80` is clear, it resets count,
sets target `0xFFFF` and additionally ORs `0xC80`; an already enabled
counter keeps its count and target.

Starting an inactive counter sets `0x80` and clears `0xC00`, preserving
the low mode bits; an active counter returns 1. `timer_counter_stop`
also preserves those bits. `timer_library_uninstall` refuses to remove the
handler while the allocated timer count is nonzero. This constrains this
library's mode lifetime, but does not prove successful boot installation or
exclude an external writer. Persistence of mode 2 beyond the inspected
family remains open.

The readers extend RCNT2 count with `timer_overflow_count << 16`, correcting
for pending mode bit `0x800`. Let `m = RCNT2_MODE & 3` and `C` be that
extended count:

| `m` | `sdk_counter2_time_read` / `timer_read_clock_guarded` | `sdk_counter2_interrupt` |
| ---: | ---: | ---: |
| 0 | `C << 0` | `C << 0` |
| 1 | `C << 4` | `C << 4` |
| 2 | `C << 8` | `C << 8` |
| 3 | `C << 16` | `C << 12` |

Mode 2 agrees across start and deadline consumption. Mode 3 has a confirmed
static difference, without demonstrated reachable mode-3 alarms or a
demonstrated retail failure.

`alarm_units_to_count` (`0x00169880`) computes

`u32(whole) * 147456000 + floor(u32(millionths) * 147456000 / 1000000)`.

Both products retain their full unsigned 64-bit values.
`alarm_count_to_units` (`0x001697D8`) returns a whole-unit quotient and
millionths remainder, storing 32 bits for each output. It narrows the whole
quotient before reconstructing the remainder and uses wrapping 64-bit
remainder scaling, so it is not an unrestricted inverse for all 64-bit counts.

The second input is millionths of the first unit; the delay wrapper uses
only that second input. **Strong numeric inference:** the convention is
nominal seconds/microseconds at 147,456,000 counts per second. Physical
counter frequency and observed delay duration are not established.

Configuration accepts duration zero without a minimum. Compare programming
has a separate grouping rule: `sdk_counter2_alarm_program`
(`0x00168A00`) advances through successive deadlines while each is below
the selected deadline plus `0x7333`, replacing the selection each time.
When selected deadline minus supplied count is signed-less-than `0x7333`,
it programs raw count plus `0x7333 >> (m << 2)`; in mode 2 that increment
is `0x73` raw steps. Otherwise it programs the selected absolute deadline
shifted right by `m << 2`. This does not change stored duration or establish
an exact wake instant or physical minimum delay.

### Two record pools and callback lifetime

The delay uses separate timer and alarm allocations:

| Named BSS storage | Pool / root | Capacity / record size |
| --- | --- | --- |
| `timer_record_pool` | Timer pool | 128 / `0x40` |
| `alarm_record_pool` | Alarm pool | 64 / `0x10` |
| `alarm_free_list` | Alarm free-list root | Pointer |

The timer free-list root is `timer_free_list`. Fixed-layout fields are named
in `KernelTimerRecord` and `KernelAlarmRecord`. Timer handles identify a
record and an odd generation, cycling through 512 values across the timer
pool. Alarm handles retain 128 low-byte generation patterns in their
cancellation comparison. Neither is a task-record pointer or thread ID,
and wraparound does not establish indefinite stale-handle protection.

Configuration rejects a negative/mismatched handle and the currently
dispatched timer. Armed bit `0x02` selects unlinking before reconfiguration
without an additional started-bit check. A null callback clears that armed
bit; a nonnull callback installs duration, saved callback context and owner
GP, arms the record and reinserts it if started. Start separately sets
bit `0x01` and snapshots `start_count`; already started returns 1.
These flags are independent of task lifecycle flags.

The queue orders the unsigned deadline
`duration + start_count - adjustment`. Dispatch removes a due timer before
calling it and restores its saved callback GP. The callback receives its
handle, configured duration, adjusted elapsed count and context.
`alarm_callback_trampoline` (`0x001699D0`) substitutes the alarm handle
and the alarm's own context.

| Alarm callback return | Alarm / timer lifetime |
| --- | --- |
| 0 | Recycle alarm and clear its timer handle; trampoline returns -1; backend clears timer generation/flags, frees timer and decrements allocated count. This is the delay callback path. |
| Nonzero other than -1 | Keep both records; backend adds `max_unsigned(return, 0x3999)` to duration and reinserts the timer, preserving start and adjustment. |
| -1 | Keep alarm record allocated and forward -1; backend frees timer. This return alone does not recycle the alarm; the selected delay callback never returns it. |

The timer backend itself accepts zero to disarm without freeing, but an alarm
callback's zero is mapped to -1, so it cannot select that timer-only result.
The repeat minimum `0x3999` is an integer counter quantity, not a measured
minimum duration. Registration checks timer allocation but ignores the two
configuration/start results; a failed allocation returns its alarm record
to the free list.

`alarm_cancel_guarded` (`0x00169C50`) validates the low-byte handle
relation under an interrupt guard, calls guarded timer-free and recycles the
alarm without checking that result. `alarm_cancel` (`0x00169CF8`)
recycles only on an exact zero timer-free result. Timer-free refuses the
currently dispatched timer; otherwise it removes an armed record and clears
generation/flags before freeing it. These differences establish local
reuse boundaries, not a safe concurrent cancellation interleaving.

## MPEG buffer semaphore ownership

The two barrier-exempt MPEG tasks share a decoder object and embedded buffer;
the semaphore belongs to neither task record. `mpeg_create_tasks`
(`0x001057B0`) allocates a `0xB8`-byte `MpegDecoder` at pointer word
`mpeg_decoder`. `abi_general_arguments_forward` (`0x001020E0`) initializes
its `buffer`; `mpeg_buffer_initialize` (`0x00103660`) creates a
maximum/initial-count `1 / 1` semaphore in `MpegBuffer.semaphore_id`.
`pending_bytes` is buffer bookkeeping, unrelated to the task record's gate.

The semaphore protects metadata consumption/publication, byte bookkeeping,
occupied/free-span queries and IPU/DMA snapshot, restore and commit operations.
Ordinary completed branches balance acquisition with release, with one
confirmed exception: `mpeg_buffer_commit` (`0x00102FB0`) acquires it,
then a zero `transfer_active` calls the no-op diagnostic and returns zero
without release. Its nonzero branch releases and returns one.
`mpeg_buffer_reset` initializes that flag to 1; snapshot clears it and
restore sets it back to 1. Whether decoder callbacks reach the retaining
branch between snapshot and restore remains unestablished; no playback
failure is demonstrated.

`mpeg_destroy_tasks` (`0x00105320`) removes `MPEG VIDEO DEC` and
`MPEG MAIN` immediately before `mpeg_decoder_destroy` reaches
`mpeg_buffer_destroy` and deletes the semaphore, then releases the outer
object. The MPEG owner controls this lifetime; the task manager neither
owns nor signals nor deletes the semaphore.

## CD callback thread and semaphore set

`cdvd_callback_thread_create` (`0x001721D0`) uses a static
`KernelThreadDescriptor`, `cdvd_callback_thread_descriptor`, named
`SceCdCallbackThread`.
With a zero thread ID it supplies caller priority/stack/stack-size, entry
`cdvd_callback_thread` (`0x00172100`) and explicit GP zero, creates the
thread, stores its ID and starts it with argument zero. That branch returns
literal 1 without validating creation or start. With an existing nonzero ID,
it changes priority and returns that operation's result, leaving stack and
stack size unchanged.

No reachable constructor installation, selected priority or caller-supplied
stack has been recovered. The bounded direct-call, pointer and selected
writer searches also leave the thread callback setter's caller unresolved.
Installing that callback does not construct a thread; the live SIF
registration uses different slots and cannot fill the reachability gap.

`cdvd_semaphores_create` (`0x00172328`) creates all four when any of the
three request IDs is -1:

| Named ID | Descriptor name | Maximum / initial | Established role |
| --- | --- | --- | --- |
| `cdvd_ncmd_semaphore` | `SceCdNcmdSema` | 1 / 1 | Request serialization; interrupt completion signals it |
| `cdvd_scmd_semaphore` | `SceCdScmdSema` | 1 / 1 | Separate request semaphore; complete operation family unclassified here |
| `cdvd_rcmd_semaphore` | `SceCdRcmdSema` | 1 / 1 | Disk-ready admission; an [engine gate](task_system.md#engine-gate-bit-0x04) dependency |
| `cdvd_callback_semaphore` | `SceCdCallbackSema` | 1 / 0 | Callback-thread event |

`cdvd_interrupt_complete` (`0x00172060`) copies the incoming word to
`cdvd_completion_publication` and `cdvd_callback_argument`. Value
`0xB` clears busy without signaling. Other values signal the request
semaphore, then signal the callback semaphore only when both the thread ID
and callback pointer are nonzero; otherwise they clear busy directly.
The handler finally clears the completion publication. This is one shared
publication/event, not a task-record queue or per-task completion token.

The worker consumes the callback semaphore. Ordinary events invoke the
registered callback only with a nonzero pointer and argument, using its saved
GP and restoring the worker GP afterwards, then clear busy. A zero argument
still consumes the wake while skipping the callback. Publication -1 clears
busy, publication, thread ID and `cdvd_thread_exit_cleared_word`, then
exits/deletes the current thread.

`cdvd_semaphores_destroy` (`0x00172410`) publishes -1 and signals only
when the callback thread ID is nonzero, then immediately deletes all four
semaphores and removes the SIF registration. It has no join or done-spin
before deletion. This differs from CRI cleanup and the task manager's
two-pass removal; successful delivery and shutdown interleaving remain open.

### Callback registration and constructor reachability

`cdvd_thread_callback_register` (`0x00171FF8`) first performs the
nonblocking `cdvd_ncmd_sync(1)` readiness probe. Only exact zero admits
replacement under an interrupt guard. It returns the previous pointer and
stores the new callback and current GP. Probe failure returns zero without
installation; zero alone cannot distinguish failure from replacing a null
callback.

The independent `cdvd_register_sif_callback` (`0x001724B0`) ensures SIF
registration, then stores its callback, context and current GP.
`cdvd_sif_callback_install` (`0x00172588`) registers
`cdvd_sif_callback_dispatch` (`0x00172530`) for command `0x80000012`,
bracketed by `cdvd_sif_registration_busy`. Dispatch skips a null callback
or nonzero registration-busy word, invokes it with its context and saved GP,
then restores GP. The concrete engine registration uses
`engine_sif_recovery_callback` and context zero; it creates no EE thread.
Its engine-gate effect is owned by
[Resident task system](task_system.md#callback-installation-and-selected-engine-aliases).

| Named BSS storage | Thread registration / state | Named BSS storage | SIF registration |
| --- | --- | --- | --- |
| `cdvd_thread_callback` | Callback pointer | `cdvd_sif_callback` | Callback pointer |
| `cdvd_thread_callback_gp` | Callback owner GP | `cdvd_sif_callback_gp` | Callback owner GP |
| `cdvd_thread_exit_cleared_word` | Word cleared on thread exit; broader role open | `cdvd_sif_callback_context` | Context |
| `cdvd_callback_thread_descriptor` | Thread descriptor | — | — |

## CRI-owned kernel threads

The [direct task-record inventory](task_system.md#direct-resident-creation-inventory)
does not count every EE thread. Six CRI constructors use independent handles,
fixed or caller-supplied stack storage and `thread_start_dormant(id, 0)`.
They do not allocate or append task records or set their lifecycle flags.

| Constructor / live address | Entry / live address | ID | Default stack / size | Assigned priority |
| --- | --- | --- | --- | --- |
| `cri_create_worker_88` / `0x0012E6B0` | `cri_worker_88` / `0x0012E038` | `cri_thread_id_88` | `cri_worker_88_stack` / `0x800` | `cri_worker_88_priority` |
| `cri_create_worker_8c` / `0x0012E758` | `cri_worker_8c` / `0x0012E090` | `cri_thread_id_8c` | `cri_worker_8c_stack` / `0x1000`; optional caller stack/size | `cri_worker_8c_priority` |
| `cri_create_root_wake_worker` / `0x0012E810` | `cri_root_wake_worker` / `0x0012E128` | `cri_thread_id_90` | `cri_worker_90_stack` / `0x1000` | `cri_worker_90_priority` |
| `cri_create_worker_94` / `0x0012E898` | `cri_worker_94` / `0x0012E230` | `cri_thread_id_94` | `cri_worker_94_stack` / `0x1000` | `cri_worker_94_priority` |
| `cri_create_worker_9c` / `0x0012E920` | `cri_worker_9c` / `0x0012E320` | `cri_thread_id_9c` | `cri_worker_9c_stack` / `0x2000` | `cri_worker_9c_priority` |
| `cri_create_worker_a0` / `0x0012E9B8` | `cri_worker_a0` / `0x0012E458` | `cri_thread_id_a0` | `cri_worker_a0_stack` / `0x2000`; optional caller stack/size | `cri_worker_a0_priority` |

Each descriptor inherits `cri_saved_creator_priority`, populated from the
creator's current priority by `cri_threads_initialize` (`0x0012EAC0`).
Retail zero data does not establish initial execution priority. The library
remembers `cri_saved_root_thread_id`, starts each worker and applies its
assigned priority.

The selected root bootstrap supplies `[1, 8, 0x10, 0x12, 0x78, 0x7A]`.
It creates workers 88, 90, 94 and 9C at assigned priorities
8, `0x10`, `0x12` and `0x7A`, changing the creator to `0x78`.
The optional 8C/A0 priorities are not supplied by that six-word configuration;
their selected creation paths remain unresolved. These independent priorities
extend beyond the ordinary task-record range
([deferred-start comparison](task_system.md#manager-pass-and-ordering-boundary)).

CRI helpers operate directly on IDs:

| Operation | Admission |
| --- | --- |
| `cri_sleep_current_thread` | Plain kernel sleep; no task runtime `0x0008` |
| `cri_wake_thread` / `cri_wake_thread_interrupt` | Nonzero ID, reported status 4 or `0xC` |
| `cri_resume_thread` | Nonzero ID, status 8 or `0xC` |
| `cri_suspend_thread` | Nonzero ID, neither status 8 nor `0xC` |

Each entry checks its named 64-bit stop publication, sets its corresponding
done publication eight bytes later and tail-exits/deletes itself.
`cri_threads_request_stop` sets all six stops. The inspected cleanups for
A0, 9C, 90, 94 and 88 spin until done, repeatedly setting stop, boosting
priority to 1, waking and conditionally resuming, then clear stop/done/ID.
There is no timeout. When `cri_worker_94_activity == 1`, its cleanup instead
uses a pure done-spin; `cri_worker_94_cleanup_retries` counts iterations,
not elapsed time. `cri_threads_release` cleans the selected four workers
and restores the saved creator priority.

`cri_worker_handshake` (`0x0012DEE8`) is separately bounded: for a
nonzero target it sets `cri_handshake_request = 1`, changes the target to
`cri_handshake_priority`, and repeatedly performs status-gated wake/resume
until the request clears. Without a clear it performs 200,000,001 pairs,
then reports a diagnostic and restores the supplied priority. It contains
no clock read or sleep; the bound is an iteration count. Workers 9C/A0 clear
the request after service; their registered handshake callbacks supply the
worker ID and configured restored priority. This protocol neither publishes
task runtime `0x0010` nor joins task-record destruction.

## Evidence confidence

| Finding | Established confidence / remaining limit |
| --- | --- |
| Alarm conversion, mode admission and two-pool lifetime | High for static contracts; nominal time units are inference. Physical frequency, external mode persistence, wait failures and interleavings remain open. |
| CD registration and constructor boundary | High for inspected interfaces and separate callback slots; reachable thread installation and selected priority remain unresolved. |
| Semaphore ownership and lifetimes | High for static ordering, including the retaining MPEG branch and CD deletion without a join; outcomes are unobserved. |
| CRI construction, priorities and stop/done | High for all six inspected families and selected root configuration; optional creator paths and vendor workloads remain open. |
