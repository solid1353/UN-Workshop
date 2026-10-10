# Ultimate Jutsu

How retail NA2 (`SLPS-25837`) starts an Ultimate Jutsu, runs its presentation
and input contest, resolves damage and outcome, and drives the CPU side.

## Research coverage

Established: Ultimate Jutsu admission and presentation, every contest class,
input retention, CPU scoring and results, cinematic damage, support-dependent
voices, branch frames, and the interruption animation's transforms and bindings.
Open: status `2`'s producer, the exact projected interruption appearance,
and measured display timings.
Names come from `@annotations/NA2`.

Related owners: [Chakra and guard](../combat/chakra_and_guard.md) owns Triangle
staging and reservation; [Awakening](awakening.md) owns the Ultimate Jutsu
record table, character lists and post-cinematic transformation;
[Ultimate Jutsu cinematics](ultimate_jutsu_cinematics.md) owns cinematic
selection and authored participant substitutions;
[Practice mode](../modes/practice_mode.md) owns options;
[Pause and replay](../session/pause_and_replay.md) owns presentation routing.
[Battle HUD](../session/battle_hud.md) owns hiding, HP trails and shake;
[Battle audio](../session/battle_audio.md) owns stream activity and sound rows.
[Controller input](../../runtime/controller_input.md),
[CCS runtime](../../game/files/ccs_runtime.md),
[CCS object types](../../game/files/ccs_object_types.md), and
[Animation runtime](../../runtime/animation_runtime.md) own the shared transport,
resource, record and curve contracts.

## Addresses

Binary identities follow
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
Addresses are live. Evidence comes from static code and authored asset reads.
Bounds on direct calls and stores do not exclude indirect callers or external
writers. Names come from `@annotations/NA2`; per-routine details are in their
comments. Fighter field names follow raw instruction offsets and saved
declarations; current MCP decompiler expressions do not consistently reflect
that layout.

The resident globals below have verified live roles and annotations in the
resident ELF, `SLPS_258.37`.

| Symbol | Role |
| --- | --- |
| `battle_manager` | battle manager |
| `jutsu_skill_play_owner` | current `UltimateJutsuSkillPlay` owner |
| `jutsu_contest_state` | current `ContestInputState` object |
| `jutsu_contest_damage_fraction_total` | contest damage total, a fraction of maximum HP |
| `0x00604310` (`jutsu_outcome_effect_id`) | attacker's post-cinematic effect ID, or `-1` |
| `0x00604314` (`jutsu_outcome_control_flag`) | defeat-latch enable byte |
| `stream_break_release_flag` | interruption release flag |
| `jutsu_cinematic_outcome` | cinematic control value |
| `jutsu_loaded_branch_frames` | loaded branch-frame table pointer |
| `jutsu_active_branch_frames` | active branch-frame table pointer |

## Start

Triangle staging debits `5.0 * (level + 1)`, with reservation and binding
behavior owned by [Chakra and guard](../combat/chakra_and_guard.md).
The connecting-hit path is `opponent_lock_override` (`0x00244F80`).
It starts a presentation only when:

- the attacker's `status_flags & 1` is clear; otherwise its reservation is
  released;
- `major_state == 8` and `action_outcome == 1`;
- `current_record.category` is `0x00100000`, `0x00200000` or
  `0x00400000`, and its `flags & 0x00010000` is clear;
- that record is the target's hit provenance: `response_attack_record`,
  then `hit_source_record_get` on `response_source` and
  `contact_attack_source`
  ([Damage](../combat/damage.md#native-damage-calculation)).

The category selects presentation level `0/1/2`. Both reservations are
released; the attacker pays `5/10/15` chakra according to
`Fighter.chakra_cost_tier`, subject to the spend gates. These tier values
are distinct from the presentation level.

`jutsu_slots_rewrite` (`0x002449C0`) selects the currently usable record.
Tier/category selection belongs to
[Awakening](awakening.md#effect-to-form-mapping-and-resource-replacement);
the selected slots are:

| Selected tier | Category flag | Ordinary record slot | Class-7 record slot |
| ---: | ---: | ---: | ---: |
| `0` | `0x00100000` | `4` | `7` |
| `1` | `0x00200000` | `5` | `8` |
| `2` | `0x00400000` | `6` | `9` |

Class comes from `UltimateJutsuRecord.record_class`; class `7` also copies
`effect` to `Fighter.selected_jutsu_effect`. Tier `0` may replace its
record through the support/primary lookup below. The record's signed
`cost_tier` supplies `chakra_cost_tier` and the `5/10/15` charge,
independently of the slot-selection tier.

The selected slot gets its category, display name and cost; the other five
lose those fields. The selected record is published in
`BattleManager.current.sides[side].selected_jutsu_record`. A tier-remap
result of `-1` clears all six slots; an unchanged tier with a nonnegative
remap returns before rewriting them. Input selection of slots `4..9` is
owned by [Action commands](../combat/action_commands.md#representative-paths).

`jutsu_connection_cleanup` (`0x00216EA0`) clears both fighters'
[update pauses](../combat/hit_response.md#pause-lock-and-update-order)
and sets both [hit-rejection countdowns](../combat/hit_response.md#rehit-suppression)
to `60`. Unless the coordinator is already in state `6`, it enters
that state with the attacker, target and level, then requests selector
`13 + level` for the attacker's side. BTL collapses `13..15` into the
same Ultimate Jutsu presentation.

### CPU attempt

`ai_state15_select_action` (BTL `0x006F8810`) attempts its cached jutsu
only with `AiState.cooldowns[8]` zero and Ultimate Jutsu setting
key `5` positive. The slot layout and profile parameters belong to
[Battle AI](../session/battle_ai.md). Admission requires:

- an inclusive `0..100` draw below profile parameter `16`
  (`0/0/0/50/60/70`, Simple through Ultimate);
- a valid cached record, the first usable slot among `4..9`;
- for slots `7..9`, planar distance at least `800.0`; for `4..6`,
  distance at most `ActionRecord.threshold`, unless it is `10000.0`
  or about `-17320.5`;
- different `Fighter.response_facing` values;
- `chakra_affordable` accepting the signed tier obtained by
  `resource_table_signed_value` from the integer-converted action cost.

All passing gates queue the slot through `action_queue_set`. A later
failure still reloads the countdown from parameter `18`; failed chance or
missing record instead diverts to the other masked attempt using parameters
`15/17`. The affordability path treats the action cost as a record index,
then uses its signed tier directly; whether that is intended remains open.

`fighter_set_facing_fields`, `fighter_facing_from_orientation` and
`fighter_restore_facing_orientation` establish binary facing values
`0/1`, the predicate `!(orientation[2] > 0.0)`, and the
`movement_direction_angles` choices `+pi/2` and `-pi/2`.
The inequality therefore means opposite binary directions; it does not
establish that either fighter faces the opponent's current position.

## Presentation state machine

`jutsu_presentation_update` (BTL `0x00769790`) owns
`UltimateJutsuPresentation.state/countdown`; the attacker side comes from
`AwakeningPauseGate.mode`, the signed controller byte, and the selected
record from the manager's side slot.

| State | Behavior |
| ---: | --- |
| `0` | Load cut-in models/text. Countdown `100`, `130` for `authored_id == 0x9C`, or `150` for the alternate-voice case. Play `intro_voice` on bank `1`, slot `0`. |
| `1` | At `100` (`150` for alternate voice), hide the clock and both lower HUD panels; top panels stay visible. At `100`, set both `update_rate_override` values to `0.05`. At `85`, create skill play and contest. End at zero, or after `85` once the voice has started and stopped; then set both rate overrides to `0`. |
| `2` | Wait for `ccs_stream_player_hold_point`, or count down when no owned handle exists (`30` with a manager, `15` without), then `jutsu_contest_begin_input` sets `active`. |
| `3` | Count down `12` with a manager (`6` without), set both rate overrides to `1.0`, stop the voice and clear the hold with `ccs_stream_player_release_hold`. |
| `4` | Poll `jutsu_contest_status`. Status `2` requests branch `1`. Status `4`, once `jutsu_branch_frame_reached(0)` accepts, writes cinematic control `2`, requests branch `2`, and enters state `5`. Ordinary skill-play completion writes control `1` and exits. |
| `5`–`7` | Wait for skill-play completion and interruption release, then exit. |

The update override's shared contract is in
[Hit response](../combat/hit_response.md); HUD requests are in
[Battle HUD](../session/battle_hud.md#visibility-and-shared-transforms).
Exit restores the HUD and writes condition statuses owned by
[Match outcomes](../session/match_outcomes.md).

`audio_cached_stream_activity(1, 0)` supplies the mono voice activity,
not controller input
([Battle audio](../session/battle_audio.md#cached-stream-activity-and-replacement)).
`UltimateJutsuPresentationResources.voice_started` latches the intro's observed start;
after a start is observed, its stop edge can end the intro. In the
alternate case, that edge first starts `secondary_intro_voice` once and
continues the countdown.

`ccs_stream_player_latch_stop_skip` independently latches request plus
one into `CcsStreamPlayer.stop_latch/skip_latch` only while each is zero.
Normal request advance clears the stop latch; a value at least `2`
ends the request list without clearing it. The skip latch retains its
first request for the player lifetime. A skip value at least `2`
jumps the entry index to the count; stop values `1/3` stop the scene,
and any nonzero stop skips ordinary entry start.
`cinematic_handle_finished` reports completion once both indices reach
the count. **Inference:** branch `2` stops the running scene and cuts the
remaining cinematic, including unreached hits. Shared controls belong to
[CCS runtime](../../game/files/ccs_runtime.md#player-controls).

`jutsu_presentation_render` (BTL `0x0076A8E0`) starts the separate
`ZgBreakScreen` task in state `5`. `stream_break_start` creates it only
when its handle is zero. `stream_break_transfer_group_initialize` prepares
`BLT_strbreak`, `TEX_strbreak` and `ANM_strbreak` from `strmcmn`.

`zg_break_screen_task` (`0x00373240`) captures the image through
`image_transfer_copy_request/image_transfer_copy` and `texture_readback`.
It converts every pixel to grayscale,
`g = (77*R + 151*G + 28*B) >> 8`, preserving alpha. It holds the break
animation near its start, yields for `15`, and may play defender voice
`audio_request_sound_member(8, defender_id - 1, 0)` on bank `1`, slot `0`.
The voice is omitted when `roster_character_valid(defender_id)` is
nonzero or the defender is `0x27`. The wait allows `60` before an observed
voice start and `90` in total. Then the task advances without the hold,
sets the release flag to `1`, and keeps running until animation completion
before freeing its resources.

`stream_break_released` (`0x00373770`) reads that flag alone. It signals
release after the voice wait, not animation completion; the task may still
be finishing when presentation restores the HUD. The status-`2` branch
has [no recovered producer](#status-2-producer-boundary).

The alternate-voice case requires `UltimateJutsuRecord.category == 2`
and a match in `support_cinematic_admission_table` (BTL `0x008D2660`).
Its ten `SupportCinematicAdmission` rows hold support ID, primary ID and
signed replacement skill ID:

| Support-list ID | Primary fighter ID | Replacement skill ID | Resolved record index |
| ---: | ---: | ---: | ---: |
| `0x00` | `0x3A` | `0x54` | `117` |
| `0x01` | `0x39` | `0x4F` | `112` |
| `0x01` | `0x3E` | `0x61` | `130` |
| `0x0B` | `0x3F` | `0x65` | `134` |
| `0x0D` | `0x48` | `0x88` | `164` |
| `0x0E` | `0x47` | `0x84` | `160` |
| `0x1B` | `0x3A` | `0x53` | `116` |
| `0x1C` | `0x5D` | `0xB5` | `222` |
| `0x1E` | `0x40` | `0x6B` | `138` |
| `0x21` | `0x59` | `0xA7` | `209` |

`support_cinematic_skill_lookup` (BTL `0x00883A30`) accepts the selected
support ([Support mechanics](support_mechanics.md#setup-and-selected-support))
and cached primary ID. A primary `0xFF` would match any fighter,
but no retail row uses it; no match returns `-1`.
The primary IDs were initialized from the manager's current side IDs by
`battle_create_graph` and `pause_controller_update`.
For tier `0`, `jutsu_find_record_by_skill` resolves the replacement in
`jutsu_name_table`; all ten resulting records have category `2`,
class `3` and cost tier `0`.

Presentation uses the match, not the replacement value as a voice ID:
it extends the intro to `150` and plays the selected record's second voice
after the first stops. `sp_skill_play_begin` uses the same pair/category
gate for `sp_skill_substitute_support_resources`. This establishes a
support-dependent voice/resource relationship; player-facing names for
the combinations remain unverified.

### Authored interruption animation

Retail `ANM_strbreak` declares `101` frames and has `72` object tracks,
odd directory IDs `1..143`, named `OBJ_strbrk00..OBJ_strbrk71`.
Every track has keyed position, keyed Euler rotation, no scale channel and
keyed alpha (`0x0412`). All pieces change position and rotation; every
alpha curve is `{0: 1.0, 35: 1.0, 50: 0.0}`.
The animation also has camera record `145` (`0x0503`), light record
`146` (`0x0603`), frame markers `0..100`, and end `-1`, with no
loop marker `-2`.

Representative authored vectors, rounded to five decimals:

| Piece | Position at frame 0 | Position at frame 50 | Euler rotation at frame 50 |
| --- | --- | --- | --- |
| `strbrk00` | `(76.97718, -84.22642, 0.00005)` | `(70.95950, -98.40812, -3.49707)` | `(79.85712, -39.16872, 103.46084)` |
| `strbrk01` | `(112.67823, -68.93830, 0.00005)` | `(51.20626, -60.39729, -14.38771)` | `(114.00680, 43.25048, 74.84045)` |
| `strbrk71` | `(78.39194, -84.17529, 0.00005)` | `(72.04525, -95.62317, -10.59493)` | `(-174.79240, -19.90574, 57.43475)` |

All three sampled rotations start at `(0, 0, 0)`. Pieces `00/71` have
17 position/rotation keys at
`0,8,10,12,14,17,20,23,26,29,32,35,38,41,44,47,50`; `01` has 20,
also including `2,4,6`. These are stored transforms, not measured screen
coordinates; curve evaluation belongs to
[Animation runtime](../../runtime/animation_runtime.md#typed-curve-evaluation).

Named animation binding associates all `72` tracks with same-named model
instances. Every stored parent is zero, every model has one mesh part,
and all parts select material record `232`, which selects texture record
`233`, `TEX_strbreak`. Thus the pieces share the captured/grayscale texture.
The sampled tracks `1/3/143` bind instances `2/4/144` and models
`MDL_strbrk00/01/71` (records `230/234/374`).
Record meanings are in
[CCS object types](../../game/files/ccs_object_types.md#confirmed-identities),
and transfer-group ownership is in its
[image-transfer section](../../game/files/ccs_object_types.md#runtime-tag-0x1000-from-texture-and-clut-construction-image-transfer-group);
binding is in
[Animation runtime](../../runtime/animation_runtime.md#target-binding-and-transform-application).

`stream_break_draw` advances by `0x200`, two frames, then composes the
animation. Hold argument `1` permits advance only at integer frame at
most `1`; `-1` removes that restriction. Drawing continues in both cases.
The task therefore holds the beginning of an authored moving, rotating,
fading animation and later releases it. These transforms and bindings do
not establish its exact projected appearance or display duration.

### Skill-play admission

At countdown `85`, presentation calls `sp_skill_play_start`
(`0x0035CF00`) only when `jutsu_record_playable_skill` is nonzero and
`jutsu_presentation_skill_blocked` returns zero.
The playable-skill accessor returns `authored_id`, except classifications
below `2` or equal to `5` return zero. The raw mode comes from
`battle_rule_ultimate_mode_get`, falling back to the side's cached
`ultimate_mode`
([Practice mode](../modes/practice_mode.md#presentation-options-and-ultimate-gate)).

Skill play creates its task, current `UltimateJutsuSkillPlay` owner and
`0x2E0`-byte `CcsStreamPlayer`. The owner's container holds the cinematic
playback cursor. Begin, frame, draw and end callbacks are
`sp_skill_play_begin`, `sp_skill_play_frame`, `sp_skill_play_draw` and
`sp_skill_play_end`. Outside manager mode `6` (Collection), the raw mode
passes through `jutsu_contest_start` to `jutsu_contest_create`.
Pair-specific skill replacement runs before constructing the player.
Request setup, draw callbacks and participant substitutions belong to
[Ultimate Jutsu cinematics](ultimate_jutsu_cinematics.md).

## Contest objects

`jutsu_contest_create` (`0x0036B6D0`) publishes one object in the current
contest slot. Random selection belongs to
[Practice mode](../modes/practice_mode.md#presentation-options-and-ultimate-gate).
Every class derives from `ccInputMatch` (`ContestInputState`):

| Mode | Native class | Size | Update / render |
| ---: | --- | ---: | --- |
| `2` Command | `ccInputMatchCmd` | `0x3E8` | `jutsu_command_update` / `jutsu_command_render` |
| `3` Timing | `ccInputMatchTim` | `0xFE4` | `jutsu_timing_update` / `jutsu_timing_render` |
| `4` Turn | `ccInputMatchRot` | `0x108` | `jutsu_turn_update` / `jutsu_turn_render` |
| `5` Combo | `ccInputMatchHit` | `0x100` | `jutsu_combo_update` / `jutsu_combo_render` |
| `6` unreachable through selectors | `ccInputMatchSign` | `0x1D8` | `jutsu_sign_update` / `jutsu_sign_render` |

Mode `0` creates no object. The manager admits
`jutsu_contest_update/jutsu_contest_render` through the respective phase
mask and nonzero `jutsu_contest_get_enabled` result, then dispatches through
`ContestVtable.update/render`. `sp_skill_play_destroy` clears the skill
owner before `jutsu_contest_destroy_current/jutsu_contest_destroy` clears
the contest.

### Common fields

`jutsu_contest_construct_base` and `jutsu_contest_init` establish the
named common state:

| Field | Contract |
| --- | --- |
| `mode`, `state`, `pending_state` | class, current state and next state; `-1` means no pending state |
| `attacker_side` | `0/1` |
| `cpu_tier`, `cpu_counter[side]` | difficulty tier and per-side update counter |
| `cpu[side]` | driven by manager side flags bit `1` |
| `time_bar_state`, `elapsed`, `time_limit`, `configured_time_limit` | render-path time state and copied limit |
| `meter` | positive toward side `0` |
| `attacker_result`, `defender_result` | result flags |
| `active`, `finishing`, `status` | start gate, finishing counter, BTL result status |

Initialization clears damage total, sets `jutsu_outcome_control_flag = 1`
and seeds `jutsu_outcome_effect_id` from the record's effect (record
`99` for skill `0x49`). CPU tiers are
`{0,1,2,3,3,4,4}[difficulty]`; difficulty key `0x0B` comes from the
Free Battle/Practice setting bank or the default bank otherwise.

### Status-2 producer boundary

No producer of status `2` was recovered. The inspected contest constructors
allocate fresh storage and clear status; the inspected direct stores write
only `0/1/4`. The adjacent `status_flags` byte is separate.
The inspected broader stores, rebased accesses, dispatch descriptors and
direct accessor callers did not establish another producer. Their exact
scan bounds and counts are retained in the owning routine annotations.
This does not exclude multi-step address arithmetic, escaped aliases,
indirect callers or external writers, and does not prove status `2`
unreachable throughout the game.

### Lifecycle and time limit

Updates do nothing until `active` is set. Applying `pending_state` clears
`elapsed`. Once `finishing` is nonzero, two more updates lead to state
`5` and clear `active`; every class repeats this lifecycle.

`sp_skill_play_begin` configures a limit of `70`, reduced to
`last_frame - 90` when `CcsContainer.last_frame < 160`, with no lower
clamp. The endpoint is an inclusive last index: `ccs_parse_terminator`
stores authored frame count minus one. It is distinct from the cinematic
player and the playback cursor
([CCS runtime](../../game/files/ccs_runtime.md#container-fields)).

All class renderers call `jutsu_contest_base_render`, which runs
`jutsu_contest_timebar_render`. Bar state `0` slides in over `10`
renders; state `1` counts `elapsed` while `time_bar_enabled` is set;
state `3` marks time up at the limit. A contest without renders never
times out.

### Controller source

Human sides read their newly pressed pad mask, side `0/1` using port
`0/1`; CPU sides generate input instead
([Controller input](../../runtime/controller_input.md)).
In Practice (manager mode `3`), a CPU side generates none unless Practice
Status is COM (key `0x0C == 1`) or Attack is Ultimate Jutsu
(key `0x0D == 5`).

`jutsu_contest_cpu_parameters` provides interval `I` and miss chance `M`:

| CPU tier | Difficulty | `I` | `M` |
| ---: | --- | ---: | ---: |
| `0` | Simple | `10` | `35` |
| `1` | Easy | `8` | `30` |
| `2` | Normal | `6` | `25` |
| `3` | Hard, Insane | `5` | `15` |
| `4` | Ultimate | `4` | `10` |

## Command mode

State `0` generates one `256`-entry sequence copied to both sides.
Codes `0..3` are Triangle, Cross, Circle, Square; `4..7` are Up, Down,
Right, Left. Each entry is a face button when a draw below `100` is less
than `75 + bias`; bias starts at zero, resets after a face button and
increases by `10` after a direction.

State `7` copies the time limit and resets both sides; state `9` waits
`15` updates before starting the bar. A matching code increments
`count[side]` and `ContestCommandInput.position[side]` and plays a hit
sound. A wrong decoded command plays a miss sound, vibrates the human
controller when allowed by `profile_vibration_enabled(side + 1)`, and
locks that side for `6` updates.

`ContestCommandInput.pending[side]` is one code latch. Recognized presses
overwrite it; sampling without a recognized press preserves it. Lockout
decrements before sampling and a still-positive value skips consumption without clearing
pending. Correct or wrong consumption clears it to `-1`, as does a bar
state other than `1`. A lockout-sampled code can therefore count once
lockout expires. Shared-pad publication and bit priority belong to
[Controller input](../../runtime/controller_input.md#gameplay-readers-outside-command-history).

The meter is `(count0 - count1) * 2.5`, clamped to `-10..10`.
Time-up resolves once neither side is mid-animation. CPU acts every
`2I` updates; an inclusive `0..100` draw above `M` gives the correct
code, otherwise a random `0..7`, which may still be correct.

## Timing mode

Each side has its own random face button and one of
`jutsu_timing_launch_schedules`, eleven five-entry schedules chosen by
`prng_inclusive(10)`. Each side has five `ContestTimingNote` records.
First launches are at `0/5/10` updates; later gaps are `5/6/10/12/15`.

From state `9`, notes launch on schedule and advance one step every
`3` updates; the first three spend one extra update on step `16`.
Presses and CPU decisions count only while the bar counts.
`jutsu_timing_score_side` applies:

- if any note is on step `16`, the side's button hits the first note on
  step `15/16`, increments its count and vibrates a human side when allowed;
- with a step-`15` note and none at `16`, that press misses the first note;
- a note passing `16` unhit is missed;
- unrelated buttons and presses without a step-`15/16` note are ignored.

The meter is `(hits0 - hits1) * 2.5`, clamped to `-10..10`; at most
five hits count per side. `jutsu_timing_cpu_score` decides once per note
at step `16`. It misses at the tier cap `{1,2,4,4,5}`
(`jutsu_timing_cpu_hit_caps`) or in the disabled Practice case.
Otherwise an inclusive `0..100` draw must exceed `M + 10`.

## Turn mode

Humans use the right stick at magnitude at least `32`, otherwise the left;
a chosen magnitude below `32` is neutral. Angle becomes one of eight
45-degree sectors. `jutsu_turn_create_trackers` installs both rotation
directions from `rotation_tracker_definitions`. A tracker starts in any
quadrant, visits the other three in order and returns to the start.
Neutral, a rejected sector or more than `5` updates outside the current
and next quadrant resets it.

`jutsu_turn_match_rotation` recognizes completion; completed turns
increment the side's count, with duration affecting sound pitch only.
There is no miss penalty or lockout. The meter is
`(turns0 - turns1) * 5 / 3`, clamped to `-10..10`.
CPU holds magnitude `0x2A` and completes a sweep every `I + 4` updates.

## Combo mode

State `0` chooses one shared face button, `ContestComboInput.required_button`.
Matching consumption increments the side's count. The next update rearms
without consuming another code, so at most one counts every two updates.
Sampling precedes rearm: a press can remain in `pending[side]` and count
later. Another face button overwrites pending and, when consumed, causes
a miss sound, allowed human vibration and a `6`-update lockout.
Directions are ignored.

Sampling without a recognized press preserves pending, including during
lockout. Positive lockout skips consumption; processing or bar state other
than `1` clears pending to `-1`. These are single-code latches: a newer code can replace
an unconsumed one, and missed outer-update pad publications cannot be
recovered.

The meter is `(count0 - count1) * 5 / 3`, clamped to `-10..10`.
CPU presses correctly every `I - 1` updates and never misses.

## Sign class

Mode `6`, `ccInputMatchSign`, requires explicit mode `6`; Battle Settings
and Practice selectors cannot produce it. `jutsu_sign_update` builds
one shared row of `15` random face buttons. Side `0` works upward from
the first entry, side `1` downward from the last. Correct presses claim
and count entries; wrong presses lock the side for `3` updates.
A side finishes beyond the row or at an entry claimed by its opponent;
time-up or both sides finished resolves the contest.
The meter is `(count0 - count1) * 2.5`.
CPU presses correctly every `2(I - 1)` updates.

## Resolution

`jutsu_contest_resolve` (`0x0035F610`) reads attacker-relative meter
`v = meter` for side `0`, `-meter` for side `1`.
`jutsu_record_damage_fraction` gives `D = damage_percent * 0.01`:

| Attacker meter | Status | Attacker / defender flags | Added damage total |
| --- | ---: | --- | --- |
| `v < -5` | `4` | `0x12` / `0x11` | `0.66 D`, then cleared |
| `-5 <= v < 0` | `1` | `0x01` / `0x41` | `0.66 D` |
| `0 <= v <= 5` | `1` | `0x01` / `0x02` | `D` |
| `v > 5` | `1` | `0x21` / `0x02` | `D + 0.08` |

The different meter scales produce these count thresholds:

| Mode | Defender lead for `0.66 D` | Defender lead for status `4` | Attacker lead for the bonus |
| --- | --- | --- | --- |
| Command, Timing | `1..2` | `3` or more | `3` or more |
| Turn, Combo | `1..3` | `4` or more | `4` or more |

Result state `3` shows each side's first sprite (frame `1` when its
result bit `0` is set) and waits about `21` renders through
`jutsu_contest_result_render_a`. State `4` uses
`jutsu_contest_select_result_b`: attacker `0x20` gives frame `3`,
defender `0x40` frame `1`, defender `0x10` frame `2`, otherwise none.
`jutsu_contest_result_render_b` waits about `28` renders but ends at
once for cinematic control `2`, or for status `4` when
`jutsu_branch_frame_reached(1)` accepts. Both waits depend on rendering.

Retail `OUGI.CCS` labels:

| Atlas | Frame | Label | Meaning |
| --- | ---: | --- | --- |
| `TEX_ougi_spgau1` | `0` | 失敗 | Failure |
| `TEX_ougi_spgau1` | `1` | 成功 | Success |
| `TEX_ougi_spgau2` | `1` | ダメージ軽減 | Damage reduced |
| `TEX_ougi_spgau2` | `2` | 中断成功 | Interruption successful |
| `TEX_ougi_spgau2` | `3` | 大ダメージ | Heavy damage |

`jutsu_result_a_rectangles` selects Failure/Success from the `64x64`
atlas at pixel rectangles `(32,0,32,64)/(0,0,32,64)`.
`jutsu_result_b_rectangles` selects its three labels from the `128x128`
atlas at `(0,0,32,50)`, `(32,0,16,60)`, `(0,64,16,64)`.
Coordinates are pixel `(x,y,width,height)` before
`sprite_normalize_frame_rectangles` converts vertical endpoints to
`1-y/height`. The decoded image's displayed orientation is vertically
flipped. Atlas `2` frame `0` is white backing, `4/5` black/red
exclamation marks.

Status `4` shows attacker Failure and defender Success, then defender
Interruption successful. Reduced damage shows both Success, then defender
Damage reduced; the positive bonus shows attacker Success, then Heavy damage.

After the second wait, attacker result bit `1` (status `4`) clears
damage total, sets effect ID to `-1`, clears the defeat-latch flag and
resets attacker condition `7` to `-1`. Other outcomes retain the flag
at `1`; the contest then finishes.

The branch-frame table comes from retail `STRMCMN.CCS` resource
`BIN_strtbln4`, relocated by `sp_skill_relocate_request_table`.
All `183` signed halfwords for skills `1..183` are `126`; the
following nine halfwords are zero padding. The runtime pointers are
uninitialized in the static image.
`jutsu_branch_frame_reached(1)` therefore accepts at cinematic frame
`125`, and argument `0` at `126`, for every retail entry.
These compare the CCS playback cursor, not contest elapsed time.
Status `4` requests branch `2` at `126`; cinematic control `2`
makes `jutsu_apply_completion` skip transformation
([Awakening](awakening.md)).

## Damage

HP is normalized: `D = 0.25` is one quarter of full health.
`sp_skill_play_frame` (`0x0035B740`) consumes the skill's
`cinematic_audio_descriptors`: counted `UltimateJutsuHitRow` records with
frame, popup, sound, damage and chakra fractions. Both fractions divide
by `32768`; sound cues belong to
[Battle audio](../session/battle_audio.md#authored-cinematic-frame-rows).

A hit occurs when the current cinematic frame equals the next row's frame.
`damage_apply_cinematic` uses calculator flag `0x100` only, so handicap
factors alone scale Ultimate Jutsu damage
([Damage](../combat/damage.md#calculator-formula)).
It applies HP debit with display enabled; Practice HP stops at `0.01`.

- With damage total zero, a hit deals `D * fraction` and adds it to
  `UltimateJutsuSkillPlay.damage_dealt`.
- At the first nonzero total, the reciprocal sum of remaining hit fractions
  is computed; remaining hits deal `(total - dealt) * fraction / sum`,
  delivering the resolved remainder.
- With `jutsu_outcome_control_flag == 1` and target HP at most zero,
  attacker condition `7` becomes `1`, blocking transformation.
- Chakra fraction at least `0.00001` debits `fraction * 15.0` chakra
  from the target through `fighter_apply_chakra_debit`.

For status `4`, hits between resolution and the clear use reduced
`0.66 D` total; a hit still played after clearing uses `D * fraction`
again. The branch-`2` cut normally ends the cinematic near this point.

`jutsu_post_cinematic_update` (`0x0024ED40`), the coordinator's state-`6`
handler, applies the retained effect ID to the attacker through
`effect_apply_outcome` when it is not `-1` and the target was not defeated.
