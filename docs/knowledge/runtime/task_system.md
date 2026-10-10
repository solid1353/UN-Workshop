# Resident task system

## Research coverage

Established: the resident task record, start/wait/wake and destruction contracts,
manager ordering, root pacing and engine gate, and the 24 direct resident
creation lifecycles. NUN5 corroborates the core; NUN3 corroborates the shifted
gate and pending-resume state. Open: gate producers and units, indirect callers,
callback installation, failure recovery and independent-thread scheduling.
Names come from `@annotations/NA2`, `@annotations/NUN5` and
`@annotations/NUN3`; routine comments carry local code details. Addresses are live.

The retail NA2 (`SLPS-25837`) framework coordinates independent EE kernel
threads. `TaskCleanupRecord.entry` is a thread entry receiving its own record,
not a per-pass update or draw callback. The manager is both a thread and the
head sentinel of a flat singly linked list; ordinary records append in creation
order. There is no framework parent pointer, child list, priority sorting,
semaphore or central update/draw dispatch.

The resident core and all 24 direct constructions were covered; BTL and ETC
coverage is limited to direct calls and static references. Adventure and
runtime-generated or aliased calls are outside the negative conclusions.
Static ordering does not establish kernel scheduling, presentation order or
measured pacing cadence. Binary addresses follow
[Retail game file identities](../game/files/file_identities.md#address-conventions).

Related owners: [EE kernel threads and synchronization](kernel_threads_and_sync.md),
[Render submission](rendering/render_submission.md),
[Scene playback owners](scene_playback_owners.md),
[Battle audio](../gameplay/session/battle_audio.md),
[Resident file and archive services](../game/files/runtime_services.md),
[Controller input](controller_input.md) and [Save data](../game/save_data.md).
Their callers are covered here only for task ownership and lifetime.

## Task record

`TaskCleanupRecord` is `0x4C` bytes. `task_record_construct` initializes it;
`task_allocate_dormant`, `task_allocate_started` and
`task_manager_initialize` allocate that size. The annotation type names
`next`, `name`, `initial_priority`, `thread_id`, `entry`,
`runtime_flags`, `control_flags`, `wake_gate`, `stack_size`, `stack`,
`cleanup_argument`, `cleanup_callback` and the seven caller-owned
`payload` words.

The stack rule is `max(requested, 0x800) + 0x400`. Record and stack allocations
request `0x10` alignment. The thread ID is a signed halfword, initially -1;
kernel creation results are truncated to it and later sign-extended.

`name` defaults to `task_name_none` (`NO NAME`). It is borrowed metadata:
`task_set_name` stores the pointer without copying it, and destruction never
frees it. Dynamic name storage must outlive lookup. Most names are static;
the primary play task borrows an owner-resident string.

The manager never interprets `payload`. Caller-defined relationships belong
there or in an owning object: `ccs_play_start` makes a primary task and a
`PlayLock` companion with a borrowed primary pointer, while
`SaveWorker.task` retains the save worker handle. Neither is a framework
parent/child relation.

The opaque word `+0x44`, halfword `+0x48` and byte `+0x4A` are zeroed;
byte `+0x4B` is untouched. No direct use outside initialization was recovered
among the 24 resident creator/entry paths. NUN5 retains the same pattern;
NUN3 retains it at `+0x4C/+0x4E`, leaving `+0x4F` untouched. Their meaning
remains unknown; aliasing and excluded overlays remain limits.

`resident_flow_dispatch` installs `mother_cleanup_noop` and a zero
`cleanup_argument`. It is the only recovered cleanup registration among
the 24 entries. The callback has no side effect, but both destruction paths
implement the same `cleanup_callback(cleanup_argument)` contract.

## Flags

### Runtime flags at `+0x10`

These are `TaskCleanupRecord.runtime_flags`.

| Mask | Meaning and transition |
| ---: | --- |
| `0x0001` | Deferred start: creation has already made a dormant kernel thread; the manager clears the bit and starts it. |
| `0x0002` | Termination requested; takes precedence over resume and cooperative wake. |
| `0x0004` | Termination observed; the first eligible request pass sets it, the next destroys the record. |
| `0x0008` | Cooperative sleep: waits set it before sleeping; the manager clears it and wakes only when `wake_gate == 0`. |
| `0x0010` | Pending resume: the manager clears it and resumes the thread. NUN3 has a set/suspend helper; no in-scope NA2 producer was recovered. |
| `0x0020` | One-pass barrier bypass: immediate starts and `task_force_wake` set it; the barrier consumes it. It is not a persistent started state. |

### Control flags at `+0x12`

These are `TaskCleanupRecord.control_flags`.

| Mask | Meaning and limit |
| ---: | --- |
| `0x0001` | Protects against `task_request_termination`; does not protect against immediate removal or a request already set. |
| `0x0002` | Written but no direct resident task-layer consumer recovered; domain meaning unknown. `FADE END` leaves it set when self-terminating. |
| `0x0004` | Cooperative-barrier exemption; used by background MPEG, load/decode and save workers. |
| `0x0008` | Engine-gate bypass for lifecycle service while `EnginePadContext.frame_gate & 7` is nonzero. |

The only direct task-layer control consumers are ordinary protection and the
manager's engine-gate/barrier checks. The resident halfword-read census is
recorded in their annotations; it does not rule out indirect aliases or
Adventure consumers.

Normal startup begins `NO NAME` manager → `PAD` → `MOTHER`.
The caller pre-sets PAD control `0x0008`, and `pad_worker` adds
`0x0007`, leaving `0x000F`. PAD is the only inventoried ordinary entry
that acquires `0x0008`. MOTHER uses `0x0003`. Protected finite entries
`FADE END` and `ZgBreakScreen` clear protection before self-requesting
termination; persistent protected entries leave it set.

## Core function map

Creators own task initialization and any retained handles. The manager owns
ordinary deferred starts, cooperative wake and two-pass destruction; immediate
removal instead runs on the caller's thread. Neither route tracks owner or
borrowed-pointer lifetime. Local routine contracts and addresses belong to
the annotations; the sections below describe the shared lifecycle.

`task_find_by_name` returns a borrowed pointer with no reference count or
uniqueness check. The first equal name wins. Dormant records are visible with
`NO NAME` before final naming, and entry-installed names introduce another
append-to-entry window. No atomic named registration exists. The per-entry
annotations record when naming occurs. No lookup caller was recovered in
resident, BTL or ETC; indirect reachability remains open.

The manager head `task_list_head`, tail `task_list_tail`, published engine
pointer `engine_pad_context`, root thread ID `engine_root_thread_id` and
CRI activity byte `cri_activity` are annotated resident ELF BSS globals.

## Allocation, registration, and starting

The dormant path allocates and initializes the record, links it through the
old tail's `next`, and replaces the tail. The caller then fills name,
control and payload before starting. There is no priority sorting,
construction-complete bit or list lock. All recovered creators needing
payload use this path.

`task_allocate_started` appends before starting and provides no guaranteed
post-start initialization window. Its three ordinary uses—`SND_RPC`,
`SND_RPC2` and `MC_CHECKDIR`—install their own names/control or result
fields and need no creator write after return. Every one of the 24 direct
ordinary constructions has a recovered start path.

The framework presupposes a successful manager initialization. Append writes
through the tail; manager wake and ordinary lookup dereference the head.
There is no uninitialized-state guard or second-initialization teardown.

With force bit 1, start is immediate. Otherwise the signed numeric record
priority is compared with the caller's current priority: a smaller number
defers the start, all other values start immediately. Kernel creation and
thread-ID installation happen before this choice. Deferral does not wake
the manager; it waits for the root-driven manager wake.

A record carrying both deferred-start and termination-request bits starts
first; termination begins on a later eligible pass. Deferral therefore does
not cancel kernel creation or suppress the entry.

`thread_start_dormant` starts only a thread whose reported status is
`0x10`. The caller and manager ignore its result and update flags as if
the transition succeeded. Creation also ignores kernel creation/status
failure, and only the established descriptor inputs are explicitly
initialized; the exact descriptor writes are in `task_record_start`.

Allocation failure is not recovered: dormant allocation still links null and
sets a null tail; allocate-and-start additionally starts null; manager
initialization publishes and starts null. A failed stack allocation is not
rejected. Teardown treats only ID -1 as the no-thread sentinel, so another
negative creation result can be truncated and later used as an ID. These
are static failure consequences, not observed normal-play failures.

## Manager pass and ordering boundary

Each `scheduler_update_loop` iteration has this order:

1. `engine_root_update`, including refresh of the engine gate.
2. Append-order lifecycle traversal of ordinary records eligible under
   `frame_gate & 7 == 0` or control `0x0008`.
3. Lower manager scheduling priority from numeric `0x18` to `0x76`.
4. A second, ungated ordinary-record traversal: consume runtime `0x0020`;
   otherwise exempt control `0x0004`; otherwise spin until
   `runtime_flags & 0x001B` is nonzero.
5. Restore manager priority `0x18`.
6. `engine_root_finish_update`.
7. Sleep until another `task_manager_wake`.

The eligible lifecycle traversal performs exactly one action per record:

| First matching state | Action |
| --- | --- |
| Deferred start `0x0001` | Clear it and start; other pending states wait. |
| Request `0x0002`, observed `0x0004` clear | Set observed. |
| Request `0x0002`, observed `0x0004` set | Unlink and destroy. |
| Pending resume `0x0010` | Clear it and resume. |
| Sleep `0x0008` with `wake_gate == 0` | Clear it and wake. |
| Otherwise | No lifecycle action. |

The engine gate affects only lifecycle service. The barrier still visits every
ordinary record. Its `0x001B` mask includes deferred start, termination
request, cooperative sleep and pending resume; it excludes observed
termination and the bypass token.

Immediate start gives one bypass pass. A manager-started deferred record gets
no token: unless exempt, it must run and publish a mask state before the same
manager iteration finishes. The barrier has no timeout, sleep, queue rotation
or kernel-status check. A failed deferred start can therefore stall the same
iteration; a failed immediate start can stall after its one token is consumed.
A non-exempt natural return with no lifecycle bit has the same problem.
Exemption avoids the spin but does not free the failed or returned record.

Smaller EE numeric priorities have higher scheduling priority. Lowering the
manager to `0x76` allows ordinary non-exempt tasks to run during its spin.
Every directly created task below that scheduling priority (numeric
`0x7D/0x7E/0x7F`) is exempt. **Inference:** that exemption is needed for the
barrier to complete under the recovered priority relation; it does not
establish update/draw phases.

Ordinary priorities span `0x14..0x7F`; SAVE SYS at `0x14` is the only
inventoried ordinary task above the manager's normal priority `0x18`.
The boot thread first selects `0x78`, initializes and force-starts the
`0x18` manager, then appends PAD `0x19` and MOTHER `0x23`.
Both starts defer and are serviced in append order. Head publication precedes
manager start; tail publication follows its return. This proves bootstrap
call order, not the context-switch point inside start.

The manager sentinel is excluded from both traversals, so its own
force-start `0x0020` token is not consumed there. No manager teardown or
root-token clearer was recovered. The head remains published after
initialization; initialization, append and removal maintain the tail.

`engine_boot_initialize` repeats `engine_wait_display_counts` followed by
`task_manager_wake`. List order proves lifecycle and barrier-scan order,
not independent-thread execution, updates, drawing, VBlank cadence or frame
rate. Pre/post engine calls are boundaries, not a universal update/draw
classification of all their work.

## Root pacing and the engine gate

Root pacing is separate from `TaskCleanupRecord.wake_gate` and counted task
waits. `engine_wait_display_counts` uses `EnginePadContext`:

| Predicate | Pacing behavior |
| --- | --- |
| `pacing_bypass != 0` | Return immediately. |
| Bypass clear, `cri_polling_mode == 0` | Busy-poll unsigned `display_counter >= display_divisor`; publish `display_field` from GS CSR bit 13 when `display_field_mode == 1`, otherwise 1. |
| Bypass clear, polling mode nonzero | Run the CRI polling service until the same unsigned count predicate passes; that service can sleep the root. |

`engine_set_display_divisor` sets the threshold and resets the byte counter.
Initialization selects divisor 1 and polling mode 1; display configuration
clears the temporary bypass before interrupt installation. MOTHER selects
divisor 2 after readiness. These are byte counts, not duration arguments;
MPEG can select other thresholds. Display configuration's opaque
`+0x2A8/+0x2AA/+0x2AC` fields are not task-record fields.

`engine_display_interrupt`, installed on interrupt channel 2 through
`engine_install_display_interrupt` and `intc_register_channel2_handler`,
increments `display_counter` through `engine_increment_display_counter`;
the byte wraps. The next `engine_root_update` resets it before advancing
the independent 32-bit `update_counter`. Interrupt counts, engine cycles
and task handshakes are different quantities.

The interrupt also conditionally wakes the root: with the CRI activity byte
zero, it checks the root status and wakes only status 4; otherwise it runs
`cri_display_interrupt_service`. Neither branch directly wakes the task
manager. The ordinary root loop requests that wake after pacing returns.

The nonzero polling branch calls `cri_service_before_root_wait` then
`cri_root_wait_service`. The latter orders the registered pre-wait
callback, conditional CRI worker resume/wake, registered wait callback,
root sleep request and registered post-wait callback.
`cri_request_root_sleep` sets `cri_root_sleep_request = 1` and performs
a plain kernel sleep without a task flag. The root cannot return to the
count comparison or wake the manager until a kernel wake resumes it.

The worker-side `cri_wake_requested_root` requires request 1 and saved
root status 4 or `0xC`, and clears the request only when wake returns the
requested ID. The interrupt-side CRI path separately wakes inactive CRI
workers, with an additional worker conditional on the library mode.
These are outside the task-record relationship.

**Inference:** when pacing is enabled, the root's manager-wake requests are
bounded by an interrupt-count predicate. There is no established one-to-one
mapping to completed manager passes, task handshakes, displayed frames or
elapsed time. Byte wrap, bypass, alternate MPEG thresholds, independent
kernel wakes and work around the barrier prevent substituting a measured
time unit. Display submission/completion belongs to
[Render submission](rendering/render_submission.md#completion-and-packet-lifetime).

### Engine gate bit `0x04`

Before lifecycle service, `engine_root_update` calls
`engine_update_frame_gate`. It clears bit `0x04`, advances signed
`cdvd_recovery_state`, optionally invokes `cdvd_recovery_callback`,
then sets bit `0x04` only when the callback is non-null and the resulting
signed state is at least 2. The manager sees the post-transition gate.

| Entry state | Transition |
| ---: | --- |
| 0 | `cdvd_get_lower_status` result 1 or `0x20`, with `cdvd_recovery_suppressed == 0`, selects 1. |
| 1 | Select 2. |
| 2 | `cdvd_disk_ready(1)` result 2 selects 3 and clears lower control. |
| 3 | `cdvd_recovery_status` in `0x12..0x14` selects 4; otherwise 2. |
| 4 | Null `cdvd_recovery_task` or `cdvd_query_recovery_task` result 1 selects 0; otherwise 2. |

Before the transitions, lower control receives `state < 3` through
`cdvd_set_lower_control`/`cdvd_store_lower_control`.
`cdvd_get_lower_status`/`cdvd_read_lower_status` supplies the lower
status word. Those status/control dependencies do not establish
player-facing names for the state numbers.

A null callback leaves gate `0x04` clear even while states advance.
A non-null callback runs for any resulting nonzero state, including 1;
the state is reread afterwards. Callback mutation can therefore change the
final gate in the same manager iteration.

No direct engine producer of gate bits `0x01/0x02` was established.
The bounded store scan does not cover copied pointers, computed or overlapping
stores, bulk copies or excluded code. The manager still tests all three bits;
the independent task `wake_gate` producer is also unresolved.

### Callback installation and selected engine aliases

`engine_root_allocate` publishes a `0x530`-byte engine;
`engine_root_initialize` clears its recovery callback, task, state/control
bytes and gate. `engine_root_construct` initializes the two embedded
`0x40`-byte objects. Their selected constructors, resets and registration
paths do not reach the gate or recovery callback. The packet-buffer rebase
also writes a different region. Local access/candidate details are in those
routine annotations.

The installed `engine_sif_recovery_callback` is a separate SIF registration
through `cdvd_register_sif_callback`, not the engine recovery callback or
the CD kernel-thread callback
([CD callback interface](kernel_threads_and_sync.md#callback-registration-and-constructor-reachability)).
It sets `cdvd_recovery_suppressed = 1` using the SIF owner's saved global
context. It takes no task record and writes neither the gate nor recovery
callback. It blocks state 0's advance; arrival after state advance is not an
immediate reset. SIF delivery order remains unresolved.

The inspected resident constructors, aliases and registrations reveal no
nonzero recovery-callback installer or gate-`0x01/0x02` producer.
The selected BTL skill-object initialization and ETC code supply no
established engine installer; local candidate details are in annotations.
This does not prove global nonuse: indirect writes, bulk copy, rebasing or
excluded code could supply the callback. A concrete write/copy reaching the
published engine and a nonzero callback's clearing path remain open.

### Other consumers of engine bits `0x01/0x02`

`mpeg_main_task` tests the same published engine's narrower `frame_gate & 3`.
Either low bit skips its main/video service; `0x04` alone does not.
Both low bits therefore participate in a scheduling gate, but their individual
producers and domain meanings remain unknown.

`engine_root_update` gates `early_callback` after refreshing the recovery
state; that is a different callback slot. `engine_root_finish_update`
gates selected post-barrier service, late public-held snapshots and the RCNT0
snapshot while still performing surrounding work
([Controller input](controller_input.md)).
The gate is selective, not evidence that every operation or independent
thread pauses. Task control `0x0008` bypasses only lifecycle service.

## Wait and wake semantics

`task_yield_updates(record, count)` decrements a positive local count, sets
cooperative-sleep and sleeps each time. Once the count is nonpositive, it
returns only if signed `wake_gate <= 0` and termination is not requested;
otherwise it sleeps again. A terminating waiter therefore remains asleep for
manager destruction rather than returning to ordinary work.

`task_wait_current` uses the same loop after locating the ordinary record
by kernel thread ID. If the thread is unregistered—including the manager
sentinel—it ignores the count and sleeps exactly once, even for zero or
negative counts. Lookup temporarily disables interrupts and restores them
according to the previous state.

Positive counts describe completed sleep/wake handshakes, normally serviced
by the manager but also satisfiable by force wake or another kernel wake.
The recovered callers use small positive constants; their exact census is
in the wait annotations. No frame, millisecond, refresh or VBlank unit is
established.

The manager wakes only for exact `wake_gate == 0`, narrower than the
waiter's signed `<= 0` return condition. Only constructor zeroing and
`task_force_wake` zeroing were established; no in-scope nonzero writer,
incrementer or decrementer was recovered. NUN5 preserves both predicates;
NUN3 has the same asymmetry with its shifted `+0x10` gate. None supplies
the producer or unit.

## Kernel threads and synchronization outside the task list

The kernel dispatch queue, alarm-backed delay, MPEG buffer semaphore, CD
callback thread/semaphore set and six CRI threads do not use this record.
Their contracts belong to
[EE kernel threads and synchronization](kernel_threads_and_sync.md).
They add no framework semaphore, parent link or lifecycle flag and supply
no recovered NA2 pending-resume producer.

## Creator ancestry

### Playback companion and sound descendants

`ccs_play_start` creates the primary play record and `PlayLock` as siblings;
the primary entry does not create the companion. The owner retains the primary
handle, primary `payload[1]` borrows the owner, and companion
`payload[0]` borrows the primary. Primary `payload[6]` publishes:

| Value | Primary region / companion response |
| ---: | --- |
| 0 | Initial or pre-wait state; companion performs its one-count wait. |
| 1 | Update/submission region; companion spins without sleeping. |
| 2 | Play-state teardown complete; companion self-requests termination. |

`ccs_play_task` requests termination after `ccs_play_loop` returns;
`ccs_destroy_play_state` precedes publication 2. No join, reference count,
semaphore or framework parent relation is added. Primary priority `0x1B`
is higher than companion `0x1E`, but does not prove safe borrowed-pointer
lifetime or interleaving under every cancellation.
Scene evaluation/submission belongs to
[Scene playback callers and owners](scene_playback_owners.md#streamed-worker-scheduling).

Sound has a different creator chain: MOTHER → SOUND → SND_RPC and SND_RPC2.
`sound_task` publishes shared readiness before creating the two RPC tasks
and retains neither returned handle. Their numeric priorities `0x71/0x72`
are larger than creator `0x70`, so normal starts are immediate if that
creator priority has not changed. No framework ancestry is stored.

`sound_rpc_task` initializes shared state and waits once before each service.
`sound_rpc2_task` waits while `sound_rpc2_ready` is zero, then waits for
shared owner byte `+0x21` to become nonzero, calls `sound_rpc2_service`,
and repeats. These are task handshakes, not fixed RPC timing intervals.
Audio meaning belongs to [Battle audio](../gameplay/session/battle_audio.md).

## Termination, destruction, and ownership

Ordinary termination is asynchronous:

1. `task_request_termination` checks protection and sets the request once;
   a first self-request sleeps immediately.
2. The next eligible manager pass marks termination observed.
3. The following eligible pass unlinks the record and repairs the tail.
4. A non-null cleanup callback receives its argument.
5. The target thread is terminated/deleted unless its stored ID is -1.
6. `heap_free_synchronized` frees the stack, then `heap_free` frees the record.

Repeated requests return without another sleep. Neither request nor force
wake wakes the manager; the root drives that independently.
The engine gate can delay both passes without control `0x0008`.

The callback runs after unlink/tail repair while the record and thread still
exist. Ordinary cleanup runs on the manager thread; immediate cleanup runs
synchronously on the remover's thread. Callback return and kernel-deletion
results are ignored, and both frees continue. ID -1 skips only the two kernel
calls, so a dormant record can still receive cleanup and be freed.

Cleanup is not an ownership transfer: it must not free the record or stack
itself. A callback creating another task would see the repaired tail, but
the only recovered callback is the no-op MOTHER registration and no such
reentrant use was found.

Owners may wait on task-defined completion before requesting termination,
then release buffers or drop handles; this is not a core join.
`save_worker_request_stop` requests and clears `SaveWorker.task`
immediately. `ccs_stream_player_destroy` requests all three play workers
after their protocol and releases shared buffers; `save_directory_check_run`
drops the completed directory-check handle. Actual destruction remains separate.

`task_remove_immediate` bypasses protection and the two-pass protocol.
Its search skips the sentinel and the first ordinary record, and assumes a
nonnull first record before checking candidates. Normal boot's skipped PAD
record is persistent, but that does not establish design intent.
`mpeg_destroy_tasks` uses it on the later MPEG records and clears their handles.

Append, manager traversal/removal and immediate removal have no internal
interrupt guard or list lock. Only lookup uses the DI/EI guard. Cooperative
or external serialization is an assumed caller contract, not an established
general guarantee.

The recovered task-record destruction routes are manager removal and
immediate removal. CD and CRI self-exit routes belong to the separate
kernel-thread owner and do not destroy task records.

No manager teardown was found. Natural return is not automatic destruction:
PAD returns after initialization with control `0x000F`, no request and no
kernel-exit polling. Its exempt record remains registered. It is the only
ordinary natural return recovered among the 24 entries. Other non-exempt
entries loop cooperatively or self-request termination; safe natural return
for a non-exempt record remains unestablished.

## Direct resident creation inventory

The recovered static graph has 24 ordinary constructions. Priority and
requested → effective stack values are game values; creator call-site
details and name/payload installation are in the entry annotations.
An asterisk marks the three allocate-and-start entries; the others use
dormant allocation and separate start.

| Entry / installed name | Priority | Stack requested → effective | Control and lifetime |
| --- | ---: | --- | --- |
| `mpeg_main_task` / MPEG MAIN | `0x7D` | `0x4000 → 0x4400` | `0x0004`; external handle, immediate removal. |
| `mpeg_video_decode_task` / MPEG VIDEO DEC | `0x7D` | `0x4000 → 0x4400` | `0x0004`; external handle, immediate removal. |
| `ccs_play_task` / owner name | `0x1B` | `0x1000 → 0x1400` | Owner/arguments in payload; finite self-request. |
| `ccs_play_lock_waiter` / PlayLock | `0x1E` | `0x800 → 0xC00` | Borrowed primary, force start, self-request. |
| `pad_worker` / PAD | `0x19` | `0x800 → 0xC00` | `0x000F`; natural return, retained. |
| `resident_flow_dispatch` / MOTHER | `0x23` | `0xC000 → 0xC400` | `0x0003`; boot payload, no-op cleanup, permanent loop. |
| `ccs_loading_info_task` / LoadingInfo | `0x28` | `0x800 → 0xC00` | Control 0; cooperative loop, external request. |
| `ccs_play_decode_task` / PlayDecode | `0x1A` | `0x1000 → 0x1400` | `0x0004`; owner/completion, wait after completion for external request. |
| `ccs_play_read_task` / PlayRead | `0x1D` | `0x1000 → 0x1400` | `0x0004`; same completion/owner protocol. |
| `ccs_play_gzip_task` / PlayGzip | `0x1C` | `0x10000 → 0x10400` | `0x0004`; owner, cooperative loop until external request. |
| `ccs_load_gzip_worker` / LoadGzip | `0x7E` | `0x10000 → 0x10400` | `0x0004`; context, self-request. |
| `ccs_load_read_worker` / LoadRead | `0x74` | `0x1000 → 0x1400` | `0x0004`; context, self-request. |
| `ccs_load_decode_worker` / LoadDecode | `0x7F` | `0x1000 → 0x1400` | `0x0004`; context, self-request. |
| `ccs_load_queue_worker` / LoadBg | `0x73` | `0x1000 → 0x1400` | Item, stop/cancel and progress payload; self-request via global handle. |
| `sound_task` / SOUND | `0x70` | `0x1000 → 0x1400` | `0x0003`; creates RPC workers, permanent loop. |
| `rofs_data_load_task` / Load ROFS_Data | `0x28` | `0x4000 → 0x4400` | `0x0006`; readiness/load waits, self-request. |
| `save_task` / SAVE SYS | `0x14` | `0x1000 → 0x1400` | `0x0004`; owner handle, infinite worker, external request without join. |
| `fade_end_task` / FADE END | `0x29` | `0x800 → 0xC00` | `0x0003`; five waits, clear protection, self-request. |
| `sp_skill_play_task` / SP Skill Play | `0x40` | `0x1000 → 0x1400` | Context, finite self-request. |
| `zg_break_screen_task` / ZgBreakScreen | `0x28` | `0x800 → 0xC00` | `0x0001`; creator payload, clear protection, self-request. |
| `ccs_batch_load_worker` / Load File All | `0x73` | `0x1000 → 0x1400` | `0x0004`; completion/byte/start gate payload, self-request. |
| `sound_rpc_task` / SND_RPC * | `0x71` | `0x1000 → 0x1400` | `0x0003`; permanent RPC loop. |
| `sound_rpc2_task` / SND_RPC2 * | `0x72` | `0x800 → 0xC00` | `0x0003`; permanent RPC loop. |
| `save_directory_check_task` / MC_CHECKDIR * | `0x64` | `0x800 → 0xC00` | Completion/result payload, wait indefinitely for external request. |

Eleven normal paths self-request; six use an external request after a
completion/stop protocol; two MPEG records use immediate destruction; five
have no recovered ordinary teardown (returned PAD and permanent MOTHER,
SOUND and both RPC tasks). Cancellation can request a normally self-terminating
load worker, so these are normal lifecycle classes, not exclusive requester
types.

Completion publication followed by retained worker lifetime lets play owners
control context lifetime before requesting destruction. Other finite load
workers self-request. The core imposes neither convention.

## Cross-version corroboration and overlay boundary

NUN5 (`SLES_556.05`) retains the same record shape, start/wait/wake contracts,
manager precedence and barrier, and two-pass destruction. Its
immediate-removal search also skips the first ordinary record. That
behavior and the wake-gate asymmetry are inherited, not NA2 decompiler
artifacts; source-level design intent remains unknown.

NUN3 (`SLUS_217.27`) uses a different `0x50`-byte record.
`task_suspend_pending_resume` sets pending-resume and
suspends the target; its manager clears that bit and resumes. Callers check
thread status. This establishes the historical state role, not normal NA2
reachability. NA2's recovered CRI and kernel-dispatch suspension paths are
outside the task list.

All 24 recognized NA2 entry pointers target resident code. BTL has no
recovered direct family reference. ETC's `etc_skill_play_wait` uses the
resident current-task wait with count 1 and
has no recovered task construction or termination. It borrows the current
resident task rather than retaining an overlay-owned entry. Adventure,
indirect aliases and runtime-generated calls remain outside that boundary.

No recovered resident/BTL/ETC static installation reaches
`ccs_play_decode_force_wake` or the force-wake API. The target handle is
established, but reachability remains open rather than proven unused.

## Evidence confidence and open questions

Record layout, core predicates, transition precedence, two-pass destruction,
cleanup order, skipped-first immediate removal, direct creator lifecycles and
local pacing/gate contracts have strong static evidence. The wake-gate
comparisons are established, while the neutral name “wake gate” supplies
no domain meaning or unit. Pending resume is established historically;
NA2 reachability is unresolved. Control `0x0002` has no recovered direct
resident consumer, not a proven absence of all consumers.

Remaining questions are the wake-gate producer/unit, opaque tail meanings,
low engine-gate producers and meanings, nonzero recovery-callback installation
and teardown, force-wake reachability, allocation/kernel failure behavior,
non-exempt natural return, append/removal serialization, indirect callers,
SIF delivery order and measured scheduling/presentation cadence. None changes
the established record or manager state machine.
