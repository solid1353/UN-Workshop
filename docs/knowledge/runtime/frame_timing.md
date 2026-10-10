# Frame timing and clock domains

## Research coverage

Established: display-count pacing, its writers/readers, output mode and flips,
the direct engine-counter consumers, battle draw callbacks that change state,
whole-frame streamed rates, and soundtrack coupling.
Evidence is static across the resident ELF, BTL and ETC; ADV is excluded.
Open: wide/computed counter reads, RCNT0 snapshot readers, enabled viewer requests,
CRI stream-mode semantics and measured hardware cadence; register meanings are inferences.
Routine, field and data names come from `@annotations/NA2`; addresses are live.

This document owns the relation between engine updates, display interrupts
and subsystem clocks in retail NA2 (`SLPS-25837`). The root wait, manager
pass and per-update order belong to
[Task system](task_system.md#root-pacing-and-the-engine-gate) and
[Controller input](controller_input.md#ownership-initialization-and-update-order).
Packet rotation and GS environments belong to
[Render submission](rendering/render_submission.md#display-and-draw-environments).
Each subsystem's clock contract is owned by the linked document below.

## Update cadence

`engine_display_interrupt` is registered on EE interrupt channel 2.
**Inference from hardware convention:** channel 2 is VBlank start, so
`EnginePadContext.display_counter` counts VBlank starts, about 59.94 per
second with NTSC output.

The root releases one manager pass when `display_counter` reaches
`display_divisor`; `engine_root_update` clears the counter at the start of
the pass. At the retail divisor 2, this permits at most one engine update per
two VBlanks, nominally 29.97 updates per second. Static code establishes the
maximum rate, not whether each update finishes within its budget.

**There is no catch-up.** The wait accepts `count >= divisor`, and the next
pass resets the count to zero. After an overrun the following wait can return
at once, but accumulated VBlanks are discarded. No extra updates or larger
elapsed-time value compensate consumers; a slow update slows the game.

`engine_root_update` zeros RCNT0 at update start; `engine_root_finish_update`
stores its halfword count in `EnginePadContext.rcnt0_snapshot` when
`frame_gate & 7` is clear. `engine_root_allocate` configures RCNT0 with mode
`0x83` ([Startup](../game/startup.md#sdk-prelude)). **Inference from the timer
register layout:** this counts horizontal blanks, making the snapshot roughly
the scan lines spent between update start and the end of its tail. No reader
of the snapshot was recovered.

### Threshold writers

`engine_set_display_divisor` writes the divisor and clears the display
counter. The four recovered writers establish this lifetime:

| Owner | Value | When |
| --- | ---: | --- |
| `engine_root_initialize` | 1 | Boot context initialization |
| `resident_flow_dispatch` (`MOTHER`) | 2 | After the startup readiness barrier, before the outer mode loop |
| `mpeg_create_tasks` | 1 | After saving the current divisor through `engine_get_display_divisor` |
| `mpeg_destroy_tasks` | saved value | Movie teardown |

Later front-end, battle and result screens inherit divisor 2; movies temporarily
select 1 and restore the saved value. The movie lifecycle is owned by
[Disc files](../game/files/disc_files.md#pss-full-motion-video).

### Threshold readers

`engine_get_display_divisor` returns the divisor byte. The recovered consumers
use it in different units:

| Consumer | Contract |
| --- | --- |
| `engine_wait_display_counts` | Root wait threshold |
| `mpeg_create_tasks` | Saved value restored at movie end |
| `pad_age_vibration` | Subtract the divisor from the active vibration duration once per update, keeping its age in VBlank units ([Controller input](controller_input.md#vibration-and-actuator-scheduling)) |
| `input_history_construct` | Construct `300 / divisor` input-history records ([Action commands](../gameplay/combat/action_commands.md#battle-input-object-and-history)) |
| `ccs_viewer_update_analog`, `ccs_viewer_update_digital` | Scale pad-driven scene rotation, movement and `CcsViewerControl.hold_count` by the divisor |

The viewer helpers are selected by `ccs_viewer_update` inside the optional
branch of `ccs_play_loop`: request flags must contain a bit in `0x60` and
have `0x100` clear, and the viewer-control update requires
`CcsContainer.play_control & 1`. This branch uses raw pad input and changes
`CcsContainer.rate` in `0x40` steps. It is a pad-controlled scene viewer;
which retail requests enable it remains open. It does not establish divisor
scaling for ordinary battle or front-end movement.

## Display output and buffer flip

`engine_root_initialize` requests a 512 by 448 display through
`engine_configure_display`, with `EnginePadContext.setup_request` equal to 0.
`engine_install_display_interrupt` selects `display_field_mode = 1` because
the requested height exceeds `0x100`, and `field_adjustment = 0` because the
request mode is zero. `gs_reset_and_configure_output` resets the GS and calls
`SetGsCrt(1, 2, 0)`.

**Inference from GS convention:** this requests interlaced NTSC output in
field mode, displaying alternate lines of one 448-line frame buffer. Movies
configure their own dimensions before playback.

During ordinary configured output, each engine update selects the other
display buffer once through `display_environment_select`, writes its
`DISPFB1`/`DISPLAY1` values and records GS CSR field bit 13 in
`EnginePadContext.display_field`. **Inference:** at divisor 2, each rendered
image remains for two consecutive fields, showing both its even and odd
lines. At divisor 1, each field would come from a different update.

## Engine update counter readers

`EnginePadContext.update_counter` advances once per engine update through
`engine_root_update`. The recovered direct word-load consumers are below;
wide or computed-address reads remain outside this inventory. ETC has no
accepted reader in that bound, and same-offset loads from other BTL objects
are excluded. The annotation comments retain the load inventory.

| Consumer | Clock-dependent behavior |
| --- | --- |
| `engine_prepare_packet_buffer` | Select the master-chain template by counter parity ([Render submission](rendering/render_submission.md#frame-chain-and-vif1-submission)) |
| `resident_flow_dispatch` | Seed random state before setting divisor 2 ([Randomness](randomness.md#coordinated-initialization-and-reseeding)) |
| `fighter_update_countdowns` | Practice refill only when the counter's low five bits are zero ([Practice mode](../gameplay/modes/practice_mode.md#continuous-fighter-policy)) |
| `sasuke_trail_update` (`ccPl93Track`, character 93) | Emit a trail sample when `counter % d == 0`; `d = int(1 / Fighter.update_rate)`, clamped to 1..10, with 1 below rate `0.01` |
| `ranking_highlight_draw_a`, `ranking_highlight_draw_b`, `ranking_highlight_draw_c` | Ranking/record highlight pulse: `u = (counter & 0x1F) * 0x100`, folded to `0x2000 - u` above `0x1000`; period 32 updates |
| `track_render_weights` | Mode 3 swaps weights `0.98` and `0.02` between the two passes of one draw according to counter parity |
| `counter_accumulate_once_per_update` | Add the supplied increment to `ResponseUpdateCounter.count` only when its saved `update_stamp` differs; repeated calls within one update count once |
| `sasuke_effect_countdown_update` | Decrement `SasukeEffectCountdown.count` once per new counter value; negative counts release an attached valid effect, while `-999` disables countdown |
| `skill_kiw001_afterimage_update_a`, `skill_kiw001_afterimage_update_b` (`ccSkillKIW001`) | With per-update travel **at most 20.0**, emit afterimages only on odd updates; above 20.0, emit by distance travelled |

The accumulation helper is shared by character IDs 78, 80, 82, 91, 92 and 93,
including [Kiba's response-count exit](../gameplay/characters/character_action_callbacks.md#kibas-response-count-exit).
`sasuke_update_attached_effects` updates two countdown records in character
93's owner. Their proved layout is named by `SasukeTimingFighterView`.
Raw accesses agree with the saved `Fighter.update_rate` offset; some applied
decompiler field expressions disagree, so they are not used to infer layout.

## State advanced by draw callbacks

Battle phase-two callbacks, `pause_controller_post_update` and front-end draw
callbacks run once per engine update. Most only submit, but these change stored
state per call:

| Draw routine | Per-call change |
| --- | --- |
| `render_transient_jitter` (battle notice) | Counts shake counter `+0x20` down from 10, sound 0x57 at 4 and 0 |
| `pause_tone_effect_update` (character 0x49) | Adds 0.01 to accumulators `+0x698`/`+0x69C`, wrapped to 0..1 |
| `fukidasi_present` | Display position becomes the average of the previous one and the projected target |
| `fukidasi_numeric_digits_draw` | Digit scale falls 0.2 toward 1.2 |
| `field_item_state3_draw` | Opacity falls 0.03 until a counter reset |
| `ink_trail_points_age` (InkSnake, InkBird) | Ages, narrows and expires trail points |
| `bg_time_of_day_draw_blend`, `bg_time_of_day_draw_blend_late`, `bg_time_of_day_draw_restore` | Approach light, fog and color targets by `0.05 / (+8 / 20)` |
| `endpoint_counter_player_draw`, `item_auxiliary_draw`, `results_summary_draw`, `panel_completion_prompt_draw`, `ranking_highlight_draw_b` | Counters and phases advance per draw |

`projectile_service_end` and `render_transient_jitter` also take random
offsets from the shared generator on every draw, applied to local copies only.

## Clock domains

Each row is an independent unit of time. Conversion requires the owner's
contract; these domains do not consume elapsed wall time except the kernel
delay and media decoders.

| Domain | Unit and advance | Owner |
| --- | --- | --- |
| VBlank count | `EnginePadContext.display_counter`, one per VBlank start | [Task system](task_system.md#root-pacing-and-the-engine-gate) |
| Engine update | `EnginePadContext.update_counter`, one per manager pass | [Task system](task_system.md#manager-pass-and-ordering-boundary) |
| Task wait | `task_yield_updates` / `task_wait_current` counts of manager wakes | [Task system](task_system.md#wait-and-wake-semantics) |
| Pad publication and repeat | One publication per update; repeat after 15 unchanged updates | [Controller input](controller_input.md#held-edges-and-repeat) |
| Vibration | 60 Hz ticks, aged by the divisor per update | [Controller input](controller_input.md#vibration-and-actuator-scheduling) |
| Fractional timer block | Caller-supplied float delta per call | [Timer primitives](timer_primitives.md#fractional-integer-cursor-block) |
| Fixed-point countdown | `0x00044444` (2^24/60) per eligible call | [Timer primitives](timer_primitives.md#fixed-point-remainingelapsed-block) |
| Profile play time | One tick per manager pass through `profile_play_time_tick` (sole call `0x001E99D4`) while manager flags bit 0 is set, saturating at `0x066FF2E2`; displayed at 30 ticks per second | [Save data](../game/save_data.md) |
| Scene playback | 8.8 increment per advance, 256 = one authored frame | [Animation runtime](animation_runtime.md#advance-and-end-behavior) |
| Streamed CCS playback | Signed 8.8 `CcsContainer.rate` per worker cycle | [CCS runtime](../game/files/ccs_runtime.md#the-play-task), [Scene playback owners](scene_playback_owners.md#streamed-worker-scheduling) |
| Effect generator | Whole list passes per requested iteration | [Effect generator commands](effect_generator_commands.md#scheduling-and-owner-gates) |
| Particle emission | `rate / 30.0` accumulated per manager update | [Particle runtime](rendering/particle_runtime.md#emission-particle-lifetime-and-update-ordering) |
| Kernel delay | RCNT2 alarm, wall-clock units | [Kernel threads and synchronization](kernel_threads_and_sync.md#alarm-backed-delay-semaphore) |
| Movies | MPEG timestamps and audio hardware | [Disc files](../game/files/disc_files.md#pss-full-motion-video) |
| Audio samples | SPU2 sample rate of each stream; commands sent from tasks | [Audio and video replacement](../game/files/audio_video_replacement.md#observed-stream-contract), [Battle audio](../gameplay/session/battle_audio.md#transport-and-stream-poll-scheduling) |

Gameplay and presentation built on per-call domains—fractional timers,
fixed-point countdowns, scene playback, generator passes, particle emission,
integer counters and recursive approaches—advance once per call. Their
wall-clock rate is the call rate times the per-call amount. Audio samples and
movie decoding do not follow that call rate.

### Streamed CCS rate is whole-frame only

`ccs_step_streamed_blocks` adds `CcsContainer.rate` to `rate_remainder`, takes
the signed 16-bit sum's whole-frame step, and retains its sign-extended low
byte. The fraction therefore does not behave as an unsigned 1/256 remainder:

| Rate | Successive whole-frame steps from zero remainder |
| ---: | --- |
| `0x100` | 1, 1, 1, ... |
| `0x80` | 0, 0, 0, ... (remainder alternates `-0x80` and 0) |
| `0x40` | 0, 0, -1, 0, ... |

Steady frame-rate advancement requires whole multiples of `0x100`.
`ccs_reset_container_and_bind_reader` initializes the default `0x100`.
For any other rate, each frame parse first calls
`ccs_bind_environment_groups` with alpha 0.0. That routine binds each group
environment and sets alpha on type `0x0E00` and `0x0100` scene objects;
it also replaces the inherited factor when the alpha is not deferred,
otherwise marks it for deferred application.

The play worker passes the raw rate to `ccs_update_generator_actions`, so
`0x100` means 256 generator passes per step
([Effect generator commands](effect_generator_commands.md#scheduling-and-owner-gates)).

## Couplings between clock domains

Some presentation starts on one clock and continues on another. These
couplings retain their retail timing only while the starting clock keeps its
retail rate.

| Coupling | Start | Continuation |
| --- | --- | --- |
| Ultimate Jutsu soundtrack | `ccs_stream_player_run` requests `audio_request_skill_soundtrack`; music preset 9 opens the skill's stereo stream on slot 1 in mode 1 through `audio_start_streamed_music`. `sound_rpc_task` reaches `audio_start_skill_soundtrack_on_frame`, which requests unpause at cinematic frame 1 when `sp_skill_play_get_progress` succeeds, the stream identifier is below `0x9351` and the selected skill is nonnegative. | Sound-side playback continues in real time; no later stream-position/cinematic-frame comparison was recovered. At stream end, `audio_finish_skill_soundtrack` stops slot 1 and requests battle music under its battle/suppression gates. |
| Ultimate Jutsu cinematic frames | `ccs_play_loop`, one step per manager wake through `task_yield_updates(task, 1)` | Damage, sound-effect cues and camera rows in `sp_skill_play_frame` follow equality with `CcsContainer.frame`, independently of the soundtrack |
| Ultimate Jutsu intro voice | State 0 of `jutsu_presentation_update` starts a mono voice and stops battle music | Engine-update countdowns select later states; state 3 stops the voice |
| Movies | Movie creation selects divisor 1 ([threshold writers](#threshold-writers)) | Video/audio follow MPEG timestamps and audio hardware ([Disc files](../game/files/disc_files.md#pss-full-motion-video)) |

Mode 1 is the game's paused-start contract; the CRI-side meaning of
`cri_set_stream_mode` remains unclassified. The same persistent play path is
used by the ETC Collection viewer: `etc_skill_play_start` calls
`sp_skill_play_start`.