# Startup sequence

Startup, Continue Save/Load, main-menu loading presentation, and audio
initialization in retail NA2 (`SLPS-25837`).

## Research coverage

The resident bootstrap, initial task handoff, card check, splash, readiness
barrier, Continue controller, loading presentation, and eager audio loading
have direct static coverage and existing sampled observations.
Names come from `@annotations/NA2` and `@annotations/NUN5`.
SDK handler semantics, most sound commands, task timing, initializer-failure
reachability, physical card failures, and indirect voice consumers remain open.

Existing samples establish ordering and observed bottlenecks, not a fixed
startup duration or exact visible-frame boundaries. Frame and duration
interpretations use 30 FPS. Ignored error returns do not establish a failure
in normal play. Statements about absent teardown apply to the covered
boot/front-end paths and recovered direct callers, not arbitrary indirect calls
or the whole game.

[Save data](save_data.md) owns the record, descriptors, and load worker;
[Character asset tables](character_assets.md#voice-descriptors-and-filename-number-lists)
owns player-voice descriptors. General [task mechanics](../runtime/task_system.md),
[render submission](../runtime/rendering/render_submission.md),
[UI transitions](../runtime/ui_animation.md),
[file services](files/runtime_services.md), and
[front-end navigation](mode_flow.md) retain their separate ownership.

## Retail ELF entry and resident bootstrap

The clean resident identity follows
[Retail game file identities](files/file_identities.md). Its sole declared
entry is `entry`. It clears processor state and uninitialized resident storage,
establishes the root stack and heap, runs `sdk_boot_initialize`, flushes cache,
and enables interrupts before entering `engine_boot_initialize`.
The first bootstrap argument is a stored word; the second is a pointer to the
remaining startup-argument storage. The entry annotation records their exact
storage and calling sequence.

The ordinary bootstrap stays in a permanent pacing loop. If it returned,
`library_exit_callbacks` would invoke the registered exit callbacks and the
optional context callback, then reach `library_exit_dispatch_thunk` and
`library_exit_dispatch`. The latter uses `library_exit_tlb` for the
memory-size-selected TLB setup and calls `_Exit`.
[EE allocator](../runtime/ee_memory_map/allocator_and_capacity.md) owns the
stack, heap, and memory-boundary interpretation.

### SDK prelude

`sdk_boot_initialize` runs these services in order, before the game arena or
game task list exists:

| Service | Established responsibility and gate |
| --- | --- |
| `sdk_libc_semaphores_initialize` | Create the `SceKernelLibc` and `SceKernelLibcEh` semaphores. |
| `sdk_kernel_pattern_handlers_initialize` | Install and invoke the kernel pattern handlers, retaining their returned shared address. Their wider semantics remain unresolved. |
| `sdk_counter3_syscalls_install` | Install resident kernel payloads and syscall entries when counter 3's installation gate is clear. |
| `sdk_counter2_records_initialize` | Initialize the counter-2 records, install `sdk_counter2_interrupt`, and configure and enable the interrupt source. |
| `sdk_counter2_start` | Start inactive counter-2 timing through `sdk_counter2_time_read` and `sdk_counter2_alarm_program`; an already-active counter returns 1. |
| `kernel_dispatch_initialize` | Create the independent `SceKerneltopThread` dispatch service and change the root caller's priority to 1. |
| `sdk_osd_syscalls_install` | Use `sdk_osd_patch_required` to probe and restore the OSD configuration; a zero reread version selects the kernel patch. |
| `sdk_exit_syscalls_install` | Install the exit-related kernel payload and syscall family, retaining the selector-3 result. |
| `sdk_startup_state_clear` | Clear the startup words and state area. |

The prelude ignores its initializers' returned errors. Its installed kernel
payloads' complete behavior and a live kernel image were not investigated;
the original SDK source names remain unknown. Kernel copy destinations and
payload sizes belong to the routine annotations.
[EE kernel threads and synchronization](../runtime/kernel_threads_and_sync.md#separate-kernel-dispatch-queue-and-semaphore)
owns the independent dispatch queue and its lifetime.

`engine_boot_initialize` then prepares the game services in this order:

| Stage | Service and result |
| ---: | --- |
| 1 | `game_arena_initialize` acquires the arena through `library_arena_allocate`, reducing the request until allocation succeeds, and establishes aligned heap boundaries and allocator records. |
| 2 | `resident_initialize_constructors` runs the 20 static initializers through `constructor_range_run`, followed by `constructor_range_finish`. This is the static-initializer walk. |
| 3 | `iop_bootstrap_reset` resets and synchronizes the IOP, reinitializes its services, and uses `iop_bootstrap_modules` to load the nine images in `MODULES.BIN`. |
| 4 | `engine_root_allocate` constructs the system/input and render contexts, configures counter 0, and prepares display services. |
| 5 | `sound_module_load` loads `sndbase.irx` through `iop_load_module_path`. |
| 6 | `sound_rpc_initialize` binds the two sound RPC clients, sends their initial commands, and clears the sound-service startup word. Most command meanings remain unresolved. |
| 7 | `card_context_initialize` constructs the lower card context only when `card_rpc_initialize` returns zero. Its expected-block count is `0x67`. |
| 8 | `GetThreadId` and `ChangeThreadPriority` retain the root thread identity and set its priority to `0x78`. |
| 9 | `file_services_bootstrap` loads `cri_adxi.irx`, initializes FLIST and ADX, mounts `DATA.CVM`, and loads the ROFS root. |
| 10 | `task_manager_initialize` constructs and immediately starts `scheduler_update_loop`, publishing the task-list head and tail. |

The module bootstrap uses temporary EE and IOP transfer buffers, reads the
complete fixed-size module archive, transfers it by SIF DMA, and loads the
nine embedded images. It frees both buffers through `heap_free_synchronized`
and `iop_heap_free_bridge`. These buffers have a finite bootstrap lifetime;
the service contexts above persist. Later `iop_load_module_path` requests
append the configured suffix to the IRX name and retry negative loader
results indefinitely.

The root creates the PAD and MOTHER task records through
`task_allocate_dormant`, passes the entry arguments in MOTHER's
`TaskCleanupRecord.payload`, and submits both through `task_record_start`.
It then repeatedly waits through `engine_wait_display_counts` and awakens the
scheduler through `task_manager_wake`.

### Initial task handoff

[Resident task system](../runtime/task_system.md) owns the task record layout,
start/defer rules, scheduler barriers, wait/wake APIs, and destruction.
The initial list and stack allocation are:

| Task | Entry | Priority | Requested / effective stack |
| --- | --- | ---: | --- |
| Scheduler/head | `scheduler_update_loop` | `0x18` | `0x1000` / `0x1400` |
| PAD | `pad_worker` | `0x19` | `0x800` / `0xC00` |
| MOTHER | `resident_flow_dispatch` | `0x23` | `0xC000` / `0xC400` |

Submission flag zero queues PAD and MOTHER because their numeric priorities
are smaller than the root thread's `0x78`; the scheduler starts them. This
establishes list/start-call order, not the interleaving of their first
instructions. The root continues display pacing and scheduler wakeups.

PAD combines its entry policy mask with the creator's mask, opens both
`EnginePadContext.pads`, and publishes ready value 1. When its lifecycle byte
becomes 2, it closes both ports and ends the pad library before publishing 3.
MOTHER installs `mother_cleanup_noop` and runs the permanent outer front-end
loop. Neither task supplies a central update/draw callback. Their service
lifetime differs from the temporary controllers described below.

## Initial memory-card check

Before constructing the splash or starting resource loaders,
`resident_flow_dispatch` allocates its persistent outer state, memory-card
worker, and live save-data object, then calls `startup_card_check_run`.

The temporary `StartupCardCheck` runs `startup_card_check_loop`, which starts
the card worker in mode zero and yields one frame per loop. Worker statuses
`0x24..0x27` display an initial confirmation through `startup_card_check_draw`;
choosing Yes permits completion. Worker status 1 also completes the check.
The routine stops the worker before returning and destroys the temporary
controller. Continue later uses the same persistent worker in a separate
loading session.

An existing no-card sample had worker status `0x24`, result class 3, and mode
zero before a main-menu object existed. The initial blocking check therefore
precedes the Continue Save/Load screen.

## Splash controller

`splash_load_resources` loads `logo.ccs` through `ccs_load_if_absent`;
`splash_find_resource` retrieves its container through `ccs_find_container`.
The root member occupies 53,973 compressed bytes and expands to 921,452 bytes.
It contains four 512×512 indexed textures: the notice has 16 colors, while the
Bandai Namco, Bandai, and CRIWARE textures each have 256.

The CCS loader opens the name through `file_open_required`, which accepts
device paths through `file_resolve_device_path`. Its decoded size comes from
`file_metadata` and `rofs_find_file_metadata`. **Inference:** this native decode
path has a decompressed size only for files represented in the mounted ROFS tree.

`splash_draw` uses `SplashObject.texture` and `SplashObject.opacity` to draw
a quad from `(0, 0)` to `(512, 384)`, with vertically reversed texture
coordinates spanning `1..512`; state 7 skips drawing. The path requires no
later main-menu resources. The native solid-rectangle path in
`movie_update_subtitles` first calls `render_reset_state`, which clears the
bound texture even with flags zero. A solid rectangle therefore does not
inherit the splash texture.

`splash_create_children` constructs the notice, Bandai Namco, Bandai, and
CRIWARE objects, using `TEX_logo_notice_pss`, `TEX_logo_bn_pss`,
`TEX_logo_b_pss`, and `TEX_logo_adx_pss` in that order.
`frontend_slideshow_update` advances them; result 1 completes the splash.

| Visible phase | Main state | Splash index |
| --- | ---: | ---: |
| Notice | 0 | 0 |
| Bandai Namco | 0 | 1 |
| Bandai | 0 | 2 |
| CRIWARE | 0 | 3 |
| Title animation | 3 | absent |
| Interactive title | 3 | absent |

`opening_update` dispatches the post-splash sequence. The main-state and splash
owners are recorded in `resident_flow_dispatch`'s annotation.

## Startup readiness barrier

The startup loop waits for all three conditions together:

- `frontend_slideshow_update` has returned 1.
- The ROFS/data-ready byte is 1.
- `AudioCommandContext.ready` is 1.

`file_services_bootstrap` mounts `DATA.CVM` as `VOL` and loads the root
synchronously. `rofs_data_load_task` recursively loads metadata for the 20
`GZLIST.TXT` directories before setting the ROFS gate. It does not preload
the 2,310 CCS payloads.

After the barrier and cleanup, the outer state becomes 2. Later,
`title_update_dispatch` returns 1 for New Game or 2 for Continue, selecting
main state 4 and the corresponding substate. The barrier covers startup
metadata and audio readiness; menu payload loading has its own gates below.

### Sound-service setup before readiness

The sound-control owner `audio_command_context_ptr` refers to `AudioCommandContext`, a
`0x18C`-byte object constructed by `sound_control_initialize`. The separate
archive/stream owner `audio_stream_manager_ptr` refers to `AudioStreamManager`, whose
allocation is `0x718` bytes. `sound_task` initializes them in this order:

1. Construct the control object and separate request/state object, name the
   task SOUND, and set its task policy mask to 3.
2. Send the initial commands through `audio_rpc_call`, retaining their returned
   destinations, and publish the `cdrom0:\DATA\` and `snddata.bin` path strings.
3. Complete `sound_snddata_handshake`.
4. Construct the archive/stream manager and perform its eager initialization
   through `afs_manager_startup`.
5. Set `AudioCommandContext.ready` to 1 and submit `sound_rpc_task` and
   `sound_rpc2_task` at priorities `0x71` and `0x72`, with requested stacks
   `0x1000` and `0x800` respectively.
6. Call `audio_set_volume` with `0x100`, then continually yield and drain
   nonempty command buffers through `audio_drain_packet`.

`sound_snddata_handshake` allocates IOP storage and sends its
`SndDataStartupDescriptor`. It sets `AudioCommandContext.loading`, yields until
the returned word equals the descriptor's completion value, clears loading,
registers the command-buffer chain through `audio_common_packet_initialize`,
and finishes the initial commands. The handshake precedes index loading.
An IOP allocation failure returns `-1`, which SOUND ignores; readiness marks
sequence completion rather than checked success of every lower initializer.

`audio_rpc_call` refuses commands while loading or while `rpc_lock` is held,
and holds the lock during an accepted call. Selected commands additionally
wait for the fixed RPC client to become idle. `audio_drain_packet` transfers
three command buffers and clears their pending words. `audio_submit_packet_dma`
flushes cache and starts DMA; its bounded polling records a timeout instead
of withholding startup readiness.

SOUND and `sound_rpc_task` are permanent yielding loops; the latter updates
requests and status once per yield. `sound_rpc2_task` first waits for
`sound_rpc2_ready`, then yields and calls `sound_rpc2_service` only when
`AudioCommandContext.poll_enabled` is nonzero. The service polls all three
stereo and all three mono channels through `audio_poll_stream_activity`.

`afs_manager_allocate_metadata` and `afs_manager_allocate_group` allocate the
four archive/index buffer sets from their sentinel tables. Before the barrier,
`audio_players_initialize` also constructs three type-2 players with
`0x1C1E4` backing each and three type-1 players with `0x11924` backing plus
`0x3000` supplementary backing each. `afs_manager_allocate` ignores this
initializer's failure result. `audio_stop_stereo_handle` and
`audio_stop_mono_handle` reset individual players without freeing the manager
or closing its archive buffers. The covered boot-to-title path has no
sound-task termination or whole-manager destruction.
[Audio and video replacement](files/audio_video_replacement.md) owns stream
completion and codec/AFS details.

### Post-splash cleanup and front-end services

`resident_flow_dispatch` follows barrier completion with this sequence:

1. `splash_destroy` uses `splash_clear_children` to reset, destroy, and free
   children in reverse order, clear the count, and release `logo.ccs` through
   `splash_release_resources`. It then frees the vector backing and controller
   and clears the splash owner.
2. `frontend_load_common_ccs` synchronously loads each missing member of the
   five common provider paths. These payloads are loaded after the barrier.
   [Common providers](files/asset_dependencies.md#common-providers-and-battle-preparation)
   owns their inventory and dependency edges.
3. `engine_set_packed_display_value` clears the system value,
   `render_reset_state` resets the renderer, and `task_yield_updates` yields
   MOTHER for two update counts.
4. Bind the default font renderer, set alpha to `0x80` through
   `font_set_alpha`, and clear the second global four-slot pool through
   `transition_pool_clear`. Clearing slots leaves the pool allocated.
5. Seed the random tag from `EnginePadContext.update_counter` through
   `rng_set_tag`, run `rng_initialize`, set the root pacing threshold to 2
   through `engine_set_display_divisor`, and enter outer state 2.

These draw services already exist before the scheduler and game task.
`font_services_initialize` creates the font manager, default/alternate render
contexts, and both `0x98`-byte transition pools. `engine_root_initialize`
creates the display packet pool, and `render_ordering_pool_initialize`
creates the `0x400`-node ordering pool.
[Render submission](../runtime/rendering/render_submission.md) and
[UI animation](../runtime/ui_animation.md) own those allocation and slot
contracts. Title returns reuse the services through binding and resetting.

MOTHER allocates its outer state, `0x60`-byte card worker, and `0x2400`-byte
live save object once, before the initial card check. The lower card context
already exists from root bootstrap. The covered outer loop does not free
these persistent objects, the sound-control/stream manager, or system/render
contexts. Splash, title, front-end manager, and loading presentation have
finite lifetimes. [Mode flow](mode_flow.md#allocation-lifetimes) owns the
title/manager/callback split; returning to title reuses the persistent services.

## Continue and shared Save/Load controller

`front_end_gate_construct` allocates the `SaveDialogController`, resets it
through `save_dialog_reset`, starts the global card worker through
`save_worker_start` in mode 2, and constructs its UI child.
`save_dialog_update` updates Continue once per frame:

| Result | Native Continue behavior |
| ---: | --- |
| 0 | Continue updating and drawing the Save/Load child. |
| 1 | Record load success, destroy the controller, and start the main-menu loader. |
| 2 | Record no-load completion and destroy the controller. |

`front_end_gate_destroy` stops the worker, frees the child, resets the parent,
and frees it. Success retains the save-dependent `display_set_position`,
`profile_apply_audio`, and `profile_bindings_to_global` setup.

`SaveWorker` holds four `SaveDescriptor` records, the port and selected slot,
requested operation, detailed status, result class, mode, latest card
classification, and task handle. Mode 1 means load.
[Descriptor table](save_data.md#descriptor-table) owns the record layout.
`save_ui_draw_slots` renders record dates and converts play time from 30 Hz
ticks, capping the display at `999:59:59`.

The PS2 clock represents JST. The PS2SDK conversion applies the configured
timezone minus 540 minutes, plus the configured daylight-saving hour. Version
zero selects the early-Japanese fallback; later configuration supplies the
daylight-saving setting. The `GetOsdConfigParam` annotation records the
configuration fields and syscall details.

Loading sets mode 1 and calls `save_load_begin`, stops music through
`audio_stop_music_bridge`, scans with `save_scan_start`, selects a record
through `save_record_select`, and resolves the choice through
`save_confirm_operation`. Yes changes status `0x10` into operation 6: read,
validate, and copy the record before reporting success.
[Load path](save_data.md#load-path) owns that worker operation.

## Native main-menu loading presentation

`new_game_prepare` shares a `MenuLoadTransient` that advances through these
phases:

| Phase | Work and completion gate |
| ---: | --- |
| 0 | Enter phase 1. |
| 1 | `save_directory_check_run` creates MC_CHECKDIR, waits for its completion, reads its result, and requests task termination. Zero selects phase 3; nonzero selects phase 2. [Save data](save_data.md) owns the directory contract. |
| 2 | Update `menu_load_optional_update` until it returns 1. |
| 3 | Request random artwork through `loading_load_selected_asset` with background loading enabled; enter phase 4. |
| 4 | Wait for `ccs_load_queue_worker_active` to report an inactive queue, free transport nodes, resolve the artwork through `loading_resolve_selected_asset`, and request presentation. Queue missing `modesel1.ccs`, `option.ccs`, `charsel1.ccs`, `mapsel1.ccs`, and `setting.ccs`, then start the queue with size pre-scan enabled and enter phase 5. Character/stage absence is checked through resident pointer slots. |
| 5 | Wait for the second queue to become inactive, free its transport nodes, clear the request through `loading_request_clear`, and enter phase 6. |
| 6 | Wait for `battle_preload_ready_a` to report idle presentation, release artwork through `loading_release_selected_asset`, free and clear the transient, and return 1. |

The [background queue](files/runtime_services.md#loadbg-queue) owns file reads,
pre-scan totals, transport cleanup, and publication. The artwork request uses
pre-scan flag zero; menu-resource loading uses flag one. File completion and
presentation completion are separate gates.

### Controller construction, resources, and phases

During front-end manager construction, `frontend_present_services_create`
creates a `LoadingPresentationController` and two other presentation
services. `front_end_present_services` updates loading through
`loading_controller_update` before those other services. The boot loop does
not construct it earlier; `battle_selection_transition_request` has no effect
when the controller is absent or already active.

The controller owns its phase and initial-delay counter, transition handle
and selectors, request flag, artwork-ownership flag, and optional
`LoadingPresentationChild`. Construction starts idle with no child and
transition handle/selectors set to `-1`.

Random `loading_load_selected_asset` selection uses a nonnegative value
modulo 7 over the first seven `loading_asset_paths` entries: `loading00`,
`loading01`, `loading02`, `loading04`, `loading05`, `loading08`, and
`loading09`, all suffixed `.ccs`. The complete 13-entry table also contains
`03`, `06`, `10`, `11`, `12`, and `13`; this caller does not randomly select
them. Missing artwork is loaded from `loading/<filename>`, synchronously or
through the background queue as requested. `loading_resolve_selected_asset`
retrieves the published container; `loading_release_selected_asset` destroys
it and clears the artwork owner.

`loading_child_initialize` creates a priority-`0xE0` renderer and two
`0x120`-byte gauge animations, `ANM_xload_ba` and `ANM_xload_fa`, from
`cmn/gauge.ccs`. A third animation, `ANM_xloada`, uses the selected artwork;
absent artwork skips only that object. `loading_child_update` still uses both
gauge objects. The child also creates the `0x208`-byte progress display
through `loading_progress_display_create`, using `TEX_xnum` from the gauge.

`loading_controller_update` implements this presentation lifecycle:

| Phase | Behavior |
| ---: | --- |
| 0 | No request returns immediately; a request enters phase 1 in the same call. |
| 1 | Borrow supplied artwork, or load it synchronously and mark local ownership. Enter phase 2 with counter zero. |
| 2 | A counter above 5 permits phase 3. A cleared request enters phase 6 before child creation. This is six service calls, not a proven six-frame duration. |
| 3 | If selected, clear transition slots and start the entry transition. Create the child; success enters phase 4, absence enters phase 6. |
| 4 | Update and draw the child. Clearing the request permits phase 5 and starts the selected exit transition; selector `-1` supplies handle zero. |
| 5 | Continue drawing until `settings_resource_pending` reports an inactive exit transition, then enter phase 6. |
| 6 | Destroy animations, unregister/free the renderer, destroy the progress display, free the child, and release locally owned artwork. Return to idle. |

The normal menu loader supplies artwork before presentation starts, so the
controller borrows it and leaves release to `new_game_prepare`.
`battle_loading_active` reports a nonzero phase; `battle_preload_ready_a`
requires a non-null, idle controller. An absent controller does not complete
that gate. `frontend_present_services_destroy` additionally releases any
remaining artwork, child, progress display, and controller and clears their
owners. [Mode flow](mode_flow.md) owns the wider manager teardown.

### Progress value and exit

`ccs_load_queue_progress` returns floating-point `completed * 100 / total`,
or `-1.0` when the total is zero. `loading_child_update` passes that float to
`loading_progress_store`.

`loading_progress_reset` makes the cache invalid with value `-1.0`. A known
value makes it valid; values above 99 become 100. A later unknown value changes
an already-valid cache to 100, while an initially unknown value leaves it
invalid. `loading_progress_read` returns `-1.0` until valid. Presentation can
therefore retain 100 after queue exit clears the raw total. Only drawing
converts the cached float to an integer. Completion depends on the inactive
file queue and idle presentation, independently of the displayed percentage.

## Audio initialization bottleneck

SOUND does not publish readiness until `afs_manager_startup` returns. That
routine constructs the manager through `afs_manager_allocate` and calls
`afs_startup_load_partitions`:

1. `afs_startup_load_archive` opens `sound.afs`, `stream.afs`, `rpgvoice.afs`,
   and `plvoice.afs`.
2. `afs_startup_load_nested` loads 13 sound indexes, 82 RPG-voice indexes,
   and 93 player-voice indexes.
3. Each helper starts one ADXF operation and yields until state 3 before
   beginning the next operation.

There are 188 serialized index loads. The shared ADXF state permits one
current operation, and destination buffers are allocated before eager loading.
Existing samples show ROFS ready while audio proceeds through both voice
ranges, with final readiness only after player-voice index 242.

`audio_request_rpg_voice` forwards playback with archive category 2. Its direct
caller census and battle-bank request are recorded in the annotation.
`audio_consume_pending_streams` uses category 3 for player voices, indexing
its 93 descriptors by character ID minus one; see
[Voice descriptors and filename-number lists](character_assets.md#voice-descriptors-and-filename-number-lists).

NUN5 retains the same `AfsManager` layout and eager-loading sequence.
Its `afs_manager_startup` calls `afs_startup_load_partitions`, which opens the
four archives through `afs_startup_load_archive` and performs each blocking
index load through `afs_startup_load_nested`. `rpgvoice_index_table` and
`plvoice_index_table` provide the index records; `rpgvoice_archive_handle` and
`plvoice_archive_handle` hold their handles. The shared clip routine is
`audio_request_archive_member`; `audio_consume_pending_streams` requests
category 3 and `audio_request_rpg_voice` supplies category 2. The manager owner
is `audio_stream_manager_ptr` in NUN5's resident ELF.
