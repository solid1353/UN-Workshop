# Scene playback callers and owners

## Research coverage

Established: retail NA2 object and streamed playback ownership, worker ordering,
resident and ETC seek policies, and the inspected local rate, pause and cleanup gates.
Names and field layouts come from `@annotations/NA2`; annotation comments hold local code detail.
Open: the full advance-owner matrix, unresolved BTL seek owners, indirect scheduling,
ETC screen identities, compact-wrapper scheduling and the complete scene-factor producers.
Static evidence establishes neither wall-clock cadence nor observed instance behavior.

[BTL scene playback owners](scene_playback_owners_btl.md) owns the BTL owner matrix.
[Animation runtime](animation_runtime.md) owns evaluation algorithms;
[CCS runtime](../game/files/ccs_runtime.md) owns parsing and resource lifetime;
[Resident task system](task_system.md) owns task and wait mechanics; and
[Effect generator commands](effect_generator_commands.md) owns manager count contracts.
This document owns callers and scheduling. Retail inputs and live-address conventions
are identified by [Retail game file identities](../game/files/file_identities.md#address-conventions).

## Playback families

| Family | Operation | Owner and caller contract |
| --- | --- | --- |
| Object animation | `animation_advance_position` (`0x001BB210`) | A mutable `CcsAnimationPlayer`, distinct from its shared type-`0x0700` descriptor; delta is in 1/256-frame units. Advance does not itself submit drawing. |
| Object animation | `animation_player_seek` (`0x001BB5C0`) | Target is in 1/256-frame units. Without a blend, forward seeks advance the difference; backward seeks reset evaluation and reader state before advancing from zero. Flag bit 0 preserves the command callback during evaluation. |
| Streamed container | `ccs_step_streamed_blocks` (`0x001B4C60`) | The primary play task consumes `CcsContainer` rate, control and checkpoints. |
| Streamed container | `ccs_play_restart` (`0x0019FFC0`) | Play-loop or streamed-marker restart preparation requires a nonnull checkpoint table. |

These families share downstream evaluation and command machinery, but their
owners and increment producers differ. Cursor layout belongs to
[Animation runtime](animation_runtime.md); streamed retention belongs to
[CCS runtime](../game/files/ccs_runtime.md#streamed-playback-sp-skill-play).

Cancelling an active `CcsAnimationPlayer.blend` makes the seek comparison origin
zero while retaining the stored cursor. Target zero therefore returns without
reconstructing pose or cursor; a positive target becomes a delta added to that
retained cursor. A caller's target zero alone does not establish a rewind
([absolute seeks](animation_runtime.md#absolute-seeks-and-evaluator-reset)).

## Streamed worker scheduling

`ccs_play_task` (`0x001A0980`) runs `ccs_play_loop` (`0x001A0120`).
Each loop orders stream step, generator-manager update, frame callback,
per-object callback, scene update/submission, then
`task_yield_updates` (`0x001D0000`) with count 1. The frame callback receives
the request index from flags bits 16..22. The task's `TaskCleanupRecord.payload[6]`
is 1 during update/submission and 0 before waiting; `CcsContainer.play_task`
separately holds the task handle.

Cursor increments consume the signed container `rate` only when
`play_control` bit 0 is clear or bit 2 requests a single step. The step request
is consumed. With the cursor gate closed, the play loop still runs the manager
when rate is nonzero, callbacks and submission. Stream pause therefore does
not hold every object in the play context. Normal skill-play request flags
do not enable the optional controller-driven rate and pause controls; their
source belongs to the linked CCS request-list research.

Control `0x20` has two phases. At stream-step entry it is consumed as
checkpoint-zero restart parsing. After the loop's wait it is cleared and
passed to restart preparation. An end marker repeats automatically with play
flags bit 0; bit 2 instead permits continued presentation of the ended stream
until stopped. A streamed `-2` marker also invokes restart inside the step routine.

The streamed manager consumes raw `rate` as its iteration count, while object
advance supplies whole frame boundaries crossed. The distinction is owned by
[Effect generator commands](effect_generator_commands.md#scheduling-and-owner-gates).

A stop is processed after the ordinary count-1 wait. The loop clears control
`0x10`, closes the reader, releases the optional ring manager, waits with count
2, removes temporary controller state, calls the end callback and tears down
play state. It then publishes task state 2 and container `runtime_flags |= 0x20`.
`PlayDecode` owns container retention and destruction. `PlayLock` observes task
state and does not advance scenes
([task publication](task_system.md#playback-companion-and-sound-descendants)).

## Direct-call census and analysis limits

The inspected resident and ETC direct-seek owners are classified below.
The bounded advance, seek, stream-step and restart byte/xref counts, alias
deduplication and local call-site evidence are in the four playback API
annotations. Byte matches alone do not establish an owner or scheduling phase.

Analyzed overlay xrefs missed direct calls, so they cannot establish completeness.
The verified allocation/binding continuation of `bg_break_anm_parse`
(`BTL.BIN`, `0x006C6350`) includes a configured-frame seek followed by
unsigned-step advance/composition. Its local evidence is in the annotation.

The remaining BTL seek leads are the `scene_seek_unclassified_*` labels in
`@annotations/NA2/BTL.BIN`. Their live call instructions are verified, but
surrounding owner, gates and lifetime remain unresolved. The classified
matrix belongs to [BTL scene playback owners](scene_playback_owners_btl.md#summary).
Complete advance ownership, indirect callers and invocation cadence remain open;
the streamed worker/marker census does not exclude higher-level worker requests.

## Owner-stored cursor restoration wrappers

`stored_cursor_playback_update` (`0x0037E6B0`) restores
`StoredCursorPlayback.player` to `frame << 8` with seek flag 0, advances using
unsigned `player.step`, composes through `animation_player_compose`
(`0x001BB6F0`), stores `complete` and saves `player.cursor >> 8` as `frame`.
`stored_cursor_playback_submit` (`0x0037E760`) restores the same saved whole
frame, then calls `projectile_compound_submit` (`0x001BB790`) without advancing.

The record owns a whole-frame logical cursor while its player has a fractional
cursor. Restoration serves both update and submission; it need not be a timeline
command or restart. Neither wrapper supplies a pause predicate. Their constructors,
possible player sharing and scheduled use remain unresolved. The bounded caller
searches in their annotations do not prove absence of indirect dispatch.

## Fighter animation ownership

`fighter_advance_animation` (`0x0024D1C0`) owns
`Fighter.owned_animation_player`. It binds a changed animation through
`fighter_start_phase_animation` (`0x00218060`), multiplies unsigned
`secondary_rate` by `update_rate` and stores the truncated low halfword as
`player.step`. Major state 7 substitutes an overlay-provided rate before
multiplication. A nonzero `animation_result` supplies step zero; valid-player
advance still runs, followed by `animation_player_deliver_commands`
(`0x001BB190`) with the fighter as callback argument.

`fighter_update_movement_slot` (`0x0024DA50`) admits the main animation pass
only with `node_flags & 2` and `update_pause.current < 1`. In the active-fighter
branch, `auxiliary_playback` independently advances later when
`afterimage_marker` is nonzero and its `FighterAuxiliaryPlayback.complete` is
zero. That auxiliary pass is outside the main pause gate. Holding the main
animation therefore does not establish a hold of every attached animation.

Phase-animation setup binds a descriptor with blend duration zero and optionally
seeks to `animation_start_frame << 8`. `animation_start_callback_enabled`
chooses flag 0 or 1; a nonzero callback-enabled start installs
`fighter_event_callback` (`0x002145B0`) and delivers initial commands.
A rate below `0x100` with configured start zero instead requests frame 1 with
flag 1. Setup clears `animation_wrap_count` and `animation_wrap_notification`;
advance detects a whole-frame cursor decrease and updates them.

Raw instructions confirm these fields and gates. Current Fighter decompiler
expressions disagree with the saved declaration at some of these accesses;
the annotations identify the verified offsets. Phase ordering and hit-response
ownership remain in [Hit response](../gameplay/combat/hit_response.md).

## Generator child ownership

For `ParticleVisual.selector == 2`, `particle_visual_update_draw`
(`0x0034AB30`) applies these `playback_mode` policies:

| Mode | Policy |
| ---: | --- |
| 0 | Omit advance. |
| 1 | Advance only before the last integer frame. |
| 2 | Advance, then seek zero and advance again when the integer cursor reaches at least `F-2`. |

Each valid advance consumes unsigned `player.step` and composes afterward.
This repetition is owner policy, distinct from descriptor automatic looping.

`particle_emitter_spawn` (`0x0034CF70`) reuses a matching animation descriptor
by seeking the existing player to zero. A changed descriptor calls
`animation_attach` (`0x001B99B0`); a resource-kind change destroys the old child
before allocating its replacement. These are spawn, reuse and reset operations.
Broader lifetime belongs to
[Particle and emitter runtime](rendering/particle_runtime.md).

## Additional resident increment producers

| Owner path | Periodic policy | Setup or lifetime relationship |
| --- | --- | --- |
| `AnimationAlternateOutput`; `animation_alternate_output_update` (`0x001C7700`) | Requires nonnull `player` and `player.play_entries`; advances unsigned step with the owner as alternate output, then composes. | `ccs_load_point_dependency_cache` (`0x001C67E0`) allocates/binds the player and advances/composes once after constructing output controllers. These advances target owner output. |
| `LifetimeAnimationOwner`; `lifetime_animation_update` (`0x00212740`) | Lifetime zero omits advance; positive lifetime decrements. A prior completion supplies step zero while valid advance/composition still run. | Active calls run `lifetime_animation_update_motion` (`0x002120F0`), publish completion and increment `updates`. Zero step differs from omitted invocation. |
| `BgAnimationPlaybackView`; `bg_draw_animation_update` (`0x00396220`) | Produces `original_step * rate_multiplier * base.scene.update_factor`, storing the truncated low halfword as step before valid advance/composition. | No separate local pause predicate; a zero multiplier supplies zero increment. The scene factor's full meaning and producers remain unresolved. |

Ordinary advance loads step unsigned. A negative stored halfword therefore
does not supply a signed reverse step.

`animation_alternate_output_destroy` (`0x001C6BB0`) destroys and clears its
player through `animation_player_destroy` (`0x001B7570`) with deleting flag 1,
releases and clears the position, rotation, scale and alpha output controllers,
and optionally frees the owner. Seek, zero step and end-latch clearing do not
perform this teardown.

## Resident explicit-seek classification

These are explicit selection, restoration, repetition and setup policies within
the inspected direct-call set. `F` means descriptor frame count. Targets at or
beyond `(F-1) << 8` still obey descriptor end/loop policy and do not alone prove a
held last pose. Flag 0 suppresses the command callback during seek evaluation,
not every effect-manager update; [Animation runtime](animation_runtime.md)
owns the internals. Local call-site evidence is in each routine's annotation.

| Owner / routines | Phase and seek purpose |
| --- | --- |
| `TitleController`; `title_set_presentation_phase` (`0x001DEB50`) | Selector 3 binds `second_animation`, requests `F << 8` and stores phase 4. Selectors 1/2 bind and advance/compose once. |
| Fighter phase setup; `fighter_start_phase_animation` | [Start frame and callback selection](#fighter-animation-ownership). |
| Fighter-associated presentation; `paired_binding1_intercept` (`0x002455B0`), `fighter_request_table_voice` (`0x002466D0`) | State-transition reset rebinds paired players in `PairedPresentationPlayerSet` and seeks the third player of each group to frame 1. The intercept also resets `PairedPresentationOwner.outer_player`. These differ from the primary fighter player. |
| Fighter auxiliary; `afterimage_enter` (`0x00245C60`), `afterimage_counter_enter` (`0x00247860`) | Action setup binds `auxiliary_playback.player`, clears its completion and starts at frame 9 (`0x900`). Its periodic gate is described above. |
| Fighter secondary; `fighter_secondary_animation_synchronize` (`0x0027EB80`) | Follows the primary descriptor, copies its step and advances/composes. With matching descriptors, the recovered unsigned integer-cursor difference is converted to float and tested against 2.0; passing it seeks to the primary whole frame. This is correction after advance; unsigned subtraction limits a symmetric-distance interpretation. |
| Companion; `chiyo_switch_puppet_animation` (`0x002AD430`) | Selects a descriptor, optionally seeks to the primary fighter start frame, then resets `PuppetRecord.timeline` with `timeline_set_position` (`0x002117A0`). |
| `WrappedScenePlayback`; `indexed_effect_seek` (`0x0030ED40`) | Kinds 1/4 explicitly select a frame. Mask request to 16 bits, replace out-of-range values through random/modulo selection, change selected zero to one, then seek. Kind 3 stores `selected_index` instead. |
| Same wrapper; `wrapped_player_update` (`0x003108A0`) | Requires nonnull resource, kind 1/4 and clear `playback_gate`. Advance until `complete`; `looping` then requests frame 1. Without looping, `retirement_enabled` can invoke `vtable.retire`. |
| Pool reuse; `effect_pool_acquire_reused` (`0x003337D0`) | Resets/relinks an inactive `0x210`-byte wrapper and seeks its player to zero. New records use separate construction. |
| Generator child; `particle_visual_update_draw`, `particle_emitter_spawn` | [Owner repetition and spawn/reuse reset](#generator-child-ownership). |
| Compact cursor; `stored_cursor_playback_update`, `stored_cursor_playback_submit` | [Restore the saved whole frame for update and submission](#owner-stored-cursor-restoration-wrappers). |
| Mode Select; `mode_select_dispatch_input` (`0x003849C0`), `mode_select_update` (`0x003854F0`) | Directional input arms arrow bytes and requests zero for their players. Armed arrows advance until completion, then disarm. Seven item players advance only for the selected item with settled `abs(carousel_displacement) <= 0.01`; others are sought to zero. |
| Sound Settings; `options_audio_update` (`0x00389550`) | A directional row change restarts `OptionsAudioPresentation.row_change_player` at frame 1. Accept/cancel return before the decoration-advance tail; reset settings enters that tail without this seek. |
| Scene-linked setup; `bg_animation_initialize` (`0x00396320`), `background_shadow_animation_initialize` (`0x0039ABB0`), `bg_material_animation_initialize` (`0x0039B260`), `bg_distance_animation_initialize` (`0x003A55F0`) | Allocate/bind a player, advance/compose once using its default unsigned step, cache that step as a float, then seek the configured frame or `prng_inclusive(F-1)` (`0x00180210`). These choose initial positions. Shadow playback uses `BgShadowPlaybackView.player`; the other owners use `BgAnimationPlaybackView.player`. |
| Moving setup; `moving_animation_initialize` (`0x003AF5B0`) | Resolve three descriptor slots, bind the first, establish its transform and seek to `prng_inclusive(F-1) << 8`. |
| Character Select finalized state; `character_selector_update_12` (`0x003B7FA0`) | While `support_animation_complete` is nonzero, repeatedly request frame 1 for `presentation_players[2/3]`; a different `final_animation` supplies the event cursor check. |

Screen identities are cross-linked to [Running help](../localization/ui/running_help.md),
[menu input mapping](menu_input/function_map.tsv) and
[Character Select](../game/character_select.md). Geometry and transition
algorithms remain in [UI animation](ui_animation.md).

`bg_distance_animation_update` (`0x003A5380`), paired with the distance setup,
omits playback while `disabled` is nonzero or the player is absent. More than
6000 units from the inspected camera position, `fade` falls by 0.1; once it
would be negative, it clamps to zero and returns before producing or consuming
step. Otherwise it uses the scene-linked increment formula above. This is a
local distance/fade gate and does not establish a global pause.

## ETC explicit-seek owners

| Live routine | Owner and phase | Seek policy |
| --- | --- | --- |
| `etc_table_animation_select` (`0x006BF860`) | Explicit selection for `CollectionSkillViewer.selected_players[index]` using `shared_container` and table row `index % 3`. | Selector zero binds the default descriptor and requests `F << 8`, flag 0. Other selectors bind then advance/compose once using unsigned step. Descriptor end/loop policy still governs the endpoint. |
| `etc_table_animation_update` (`0x006C0990`) | Independently advances the selected player and `secondary_player`, publishing `selected_complete` and `secondary_complete`. | Secondary completion sets `playback_state` to 1, rebinds the selected player to its default descriptor, requests `F << 8` with flag 0 and clears selected completion. This is an end-driven pose transition. |
| `etc_five_slot_playback_update` (`0x006CE720`) | Loops over five nonnull `EtcFiveSlotPlayback.players`; the selected slot comes from the index/list fields. The enclosing entry is now verified. | The selected valid player advances/composes using unsigned step. Every other valid player is repeatedly sought to frame 1 (`0x100`), flag 0. Upstream scheduling remains unresolved. |

These paths use alternate output zero and require `CcsAnimationPlayer.play_entries`
before evaluation. They cover the inspected direct ETC seeks; other advance
owners and indirect calls remain open. Exact screen identities remain unresolved.

The first two owners use `etc_animation_descriptor_names` at live
`0x006E2BF0`, a three-by-three descriptor-name pointer table:

| Row | Selector 0 | Selector 1 | Selector 2 |
| ---: | --- | --- | --- |
| 0 | `ANM_home_vcr01a` | `ANM_home_vcr01b` | `ANM_home_vcr01c` |
| 1 | `ANM_home_vcr02a` | `ANM_home_vcr02b` | `ANM_home_vcr02c` |
| 2 | `ANM_home_vcr03a` | `ANM_home_vcr03b` | `ANM_home_vcr03c` |

The string annotations `etc_animation_name_vcr01a` through
`etc_animation_name_vcr03c` identify the verified resource names. The table
values establish descriptor selection; exact screen identity remains unresolved.
