# Character action callbacks

## Research coverage

Established: selected character events, held exits, rate overrides, writable
rows, all six relative-cycle destinations, and Lee/Guy drawing-state ownership.
Open: unvisited aliases, copied-descriptor lifetimes, action reachability and
Kidomaru interruptions; static paths do not establish duration or appearance.
Routine, field and data names come from `@annotations/NA2`. Donor callback
comparisons are in [NUN3 and NUN4 characters](nun3_nun4_characters.md).

## Static scope

This document describes unmodified retail NA2 (`SLPS-25837`). The bounded
screen covered all seven callback slots of 78 definitions and nine virtual
slots of 74 concrete fighter classes selected by `character_definition_table`,
including the four jutsu-only definitions. It excludes independently constructed
classes and later virtual slots; selected descendants were followed, without a
complete transitive call graph. The annotation comments retain census counts
and instruction evidence. Successful decompilation or a nonzero pointer does
not establish complete behavior or ordinary-play reachability.

MCP currently displays some `Fighter` fields incorrectly after pointer-array
members despite the saved declaration matching checked raw offsets. Conclusions
here use the recorded offsets and instruction evidence, rather than those
decompiler field expressions.

## Evidence convention and ownership

Binary identities and live-address conventions belong to
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
Numeric actions are callback-local IDs; provider remapping belongs to
[Combat action execution](../combat/combat_action_execution.md#character-execution-callbacks).

`character_dispatch_channel` selects execution channels 1, 2, 3, 5, 6 and 7.
The definition's source-response callback has no execution channel. Provider
selection belongs to [Character assets](../../game/character_assets.md#per-character-code);
the source-response caller contract belongs to
[Hit response](../combat/hit_response.md#character-callbacks).

[Combat action execution](../combat/combat_action_execution.md) owns common
phase dispatch and authored-array coverage;
[Battle entities](../session/battle_entities.md#complete-table-selected-concrete-lifetime-paths)
owns class construction and lifetime.
[Puppet control](puppet_control.md), [Projectiles](../projectiles_and_items/projectiles.md),
[Awakening](awakening.md) and [Ultimate Jutsu](ultimate_jutsu.md) own their
specialized effects.

## Complete bounded class/slot census

The complete selected definition/vtable root inventory and bounded direct-writer
screen are attached to `character_definition_table`. The algorithm sections
below describe selected matches. Equivalent operations through aliases, indirect
calls, unparsed instructions or transitive helpers remain outside that screen.

## Code-authored events and continuation permission

Some callbacks author events in code rather than in phase rows. Character
names follow the numeric reference and do not establish roster reachability.

| Definition / callback | Established behavior |
| --- | --- |
| 1, Classic Naruto / `naruto_classic_channel5` | After active/pass-bit gates, delegates through `naruto_classic_auxiliary_update` to `naruto_classic_timed_events`. Action `0x23` phase 0 event 5 and phase 1 event 7 invoke different event helpers. Channels 2/3 are no-ops. |
| 2, Classic Sasuke / `sasuke_classic_channel3` | Action `0x2B` phase 0 secondary event 2 requests a voice event; phase 1 event zero applies transform/contact feedback. |
| 4, Classic Gaara / `gaara_classic_channel3` | Action `0x22` phase 0 emits effects at secondary events 7, 8, 9 and 11; other actions have different schedules. |
| 69, Might Guy / `might_guy_channel3` | Action `0x30` sets or clears continuation bit `0x20` in both phase-1 payload banks according to `action_outcome == 1`. |

Guy therefore produces action `0x30`'s continuation window in code. Its
consumer belongs to
[Combat action execution](../combat/combat_action_execution.md#continuation-and-common-exit-decisions).

## Held phases controlled by animation wraps

`fighter_advance_animation` detects a decrease from the saved unsigned frame,
increments `Fighter.animation_wrap_count` up to `0xFF`, and sets
`animation_wrap_notification`. `fighter_start_phase_animation` clears both
when it installs a nonnull animation. The count can remain nonzero through
later updates of that animation; it counts wraps, rather than hits or callback
invocations.

The following branches increment phase through `gaara_variant_presentation`
(BTL live `0x0071EF70`; its existing annotation name is retained). The shared
timer reset and payload refresh belong to Combat action execution. “Release”
means logical bit `0x8000` is clear in `Fighter.logical_input`; no physical
button name is assigned here.

| Definition / channel-3 callback | Action / phase | Admission and exit |
| --- | --- | --- |
| 6 / `character_id006_channel3` | `0x1C / 1` | Nonzero wraps; advance on release or wraps > 2. |
| 14 / `character_id014_channel3` | `0x28 / 1` | Nonzero wraps; advance on release or wraps > 15. |
| 16 / `fighter_secondary_timeline_voice_update` | `0x1C / 1` | Nonzero wraps; advance on release or wraps > 2. |
| 38 / `character_id038_channel3` | `0x1C / 1` | Nonzero wraps; advance on release or wraps > 3. |
| 49 / `lee_loopy_channel3` | `0x20 / 1` | Nonzero wraps and secondary event zero; advance on release or wraps > 7. |
| 65 / `fighter_boosted_state_update` | `0x18 / 1` | Nonzero wraps; advance on release or wraps ≥ 6, raised to ≥ 7 when `update_rate > 1`. |
| 75 / `character_id075_channel3` | `0x1F / 1` | Wraps > 1; advance on release or wraps > 9. |
| 80 / `fighter_id80_action_update` | `0x33 / 1` | Nonzero wraps; advance on release or wraps > 2. |
| 86 / `character_id086_channel3` | `0x17 / 0` | Nonzero wraps and release; no count ceiling. |
| 93 / `sasuke_channel3` | `0x1D / 1` | Wraps > 1; advance on release or wraps > 4. |
| 93 / `sasuke_channel3` | `0x19 / 1` | Nonzero wraps; advance on release or wraps > 2. |

A phase increment often does not return from the callback: later work can
still run. Selected callbacks also compare frame wrap directly, clear an
auxiliary outcome equal to 1, or clear the opponent's retained record through
`hit_clear_retained_record`
([Hit response](../combat/hit_response.md)). These are held-branch contracts,
without establishing an action's only interruption or elapsed duration.

### Writable motion in two held variants

ID 14 action `0x28` also changes phase 1's
`CharacterAnimationRow.planar_speed` to +6 or -6 from logical direction
bits 1/2 and `Fighter.placement_facing`. Phase-0 event zero initializes +6.

ID 75 action `0x1F` stops vertical speed when the non-sentinel
`floor_probe_distance` is at most 165. In phase 1, zero vertical speed
selects `bank2_attack_offset = -60` and `bank2_radius = 70 + 2 * wraps`;
nonzero vertical speed selects +60 and radius zero. These writable row values
do not establish visible geometry or contact results.

### Kiba's response-count exit

`kiba_channel3` requires actual ID `0x4E`. Action `0x2F` phase 2
compares the signed `ResponseUpdateCounter.count` in
`FighterId78.owned_children[1]` with `ActionRecord.repeat_count`.
At or above the limit it increments phase; below it, release increments phase.
Its unsigned-wrap nonnegative check imposes no positive-wrap requirement.

Phase-0 secondary event zero clears the counter. `kiba_hit_response` calls
`counter_accumulate_once_per_update` (BTL live `0x00722D90`) with
increment 1 before its action-specific work. The helper adds only when the
saved `update_stamp` differs from the selected object's current stamp, so
repeated response callbacks at one stamp add at most once. This counter is
separate from animation wraps; no wider meaning is assigned to the stamp.
Hit response owns dispatch, and Battle entities owns the child lifetime.

## Rate overrides and their record side effects

The callbacks write `Fighter.secondary_rate`. The phase timeline uses
rate / 256; scene playback also multiplies by `update_rate`
([Combat action execution](../combat/combat_action_execution.md)).
These values are not elapsed-time measurements.

### Neji's per-update rate ramp

ID 65 action `0x18` clamps a rate above `0x100` to `0x100` at primary
event zero. Phase 1 adds 8 on each admitted invocation, capped at `0x200`,
using `neji_rate_response_constants`:

| Resulting rate | `ActionRecord.update_pause` | `ActionRecord.rejection_count` |
| --- | ---: | ---: |
| Below `0x160` | 2 | 2 |
| `0x160..0x1FF` | 1 | 1 |
| At cap `0x200` | 0 | 1 |

The held-exit check precedes the ramp without returning. An invocation that
advances out of phase 1 can still write the rate and record fields. Their
accepted-hit effects belong to Hit response.

### Rock Lee's count-dependent rate and additional exits

`rock_lee_channel3`, action `0x18`, resets
`RockLeeCallbackState.loop_entry_count` and `presentation_countdown`
at primary event zero. In phase 1:

- Animation-descriptor flag 2 clear: a secondary event at
  `loop_entry_count * frame_count` increments the signed count.
- Flag 2 set: the count becomes `animation_wrap_count + 1`.

It then writes rate `0x100 + 24 * count`. With a positive count it
increments phase on release, count ≥ 8, or `effect_mode == 0`. It also
exits on signed outcome -1 or 1 combined with
`hit_repeat_value(fighter, opponent) == 1`. This record-sensitive repeat
contract belongs to Hit response.

`rock_lee_effect_mode_update` produces the mode: either effect `0x44`
or `0x45` sets 1; neither sets zero. That same mode selects category/radius
changes below. Specialized effect behavior belongs to Awakening.

### Hinata and Sasuke's wrap-indexed rate/response pairs

ID 80 action `0x33` phase 1 selects rates `0x130 / 0x150 / 0x180` for
wraps 0/1/2; other counts leave the rate unchanged in this branch.
`fighter_id80_rate_threshold_pair` supplies rate-times-delta thresholds
`0x80 / 0x120` and pause/rejection pairs `3/13, 2/5, 1/3` for the
lower, middle and upper intervals.

ID 93 action `0x19` phase 1 selects rates
`0x100 / 0x110 / 0x120 / 0x130` for wraps 0/1/2/3.
`fighter_id93_rate_threshold_pair` uses the same product thresholds and
pairs `2/7, 1/4, 0/2`.

Its action `0x1D` phase 1 uses rate `0x100` and planar speed 50 below
wrap 2, then rate `0x200` and speed 100. It changes the action's first row,
rather than the current phase row. Phase-0 secondary event zero restores rate
`0x100` and that row's planar speed to zero.

### Other direct rate-writer families

| Definition / callback | Rate branch |
| --- | --- |
| 40 / `konohamaru_squad_channel3` | Action `0x18` phase 1: truncate `16 + 752 * hold_ratio` to a halfword. |
| 63 / `sasori_channel3` | Action `0x20` phase 0, secondary cursor > 11: `0x100`; specialized control belongs to Puppet control. |
| 76 / `sasori_hiruko_channel2` | Actual ID `0x4C`, major 0 substate 3: `0xD0`. |
| 77 / `fighter_authored_voice_update` | Action `0x1C` phase 1: truncate `16 + 496 * hold_ratio` to a halfword. |
| 87 / `naruto_classic_effect09_toggle` | Actual ID `0x57`, major 0 substate 3 phase 1: `0xB0`; existing annotation name retained. |
| 87 / `character_id087_channel3` | Action `0x23` phase 0 secondary event 1: `0x120` only with effect `0x5B` or `0x5C`; effects belong to Awakening. |

`hold_ratio` is `fighter_auxiliary_audio_scalar`: signed release latch,
falling back to progress when zero, divided by the signed nonzero progress cap;
cap zero returns zero. The rate callbacks do not independently clamp it.
Producer, latch and constructor caps belong to
[Action commands](../combat/action_commands.md#resident-synthesis-after-translation).
Tenten and Chiyo's remaining writers are coupled to phase loops.

## Phase-entry loops and explicit destinations

Relative jumps are evaluated on animation end by the shared phase updater.
The following table combines callback control with selected retail rows;
Combat action execution owns the complete authored-array census.

| Definition / action | Authored cycle | Callback exit |
| --- | --- | --- |
| 51 / `0x2C` | `character_id051_action2c_phase3`: phase 3 condition -3 → phase 0. | `character_id051_channel3` resets `action_entry_count` at primary zero, then increments at phase-0 zero events. At count ≥ 1, release or count ≥ 8 sets phase 4; manages current/prior outcomes. |
| 62 / `0x1C` | `chiyo_action1c_phase7`: phase 7 condition -5 → phase 2. | `chiyo_channel3` resets `action_entry_count`, `action_loop_auxiliary` and `action_rate_addition_count` at primary zero; phase-2 zero increments the entry count. In phases 2..7, count ≥ 4 sets phase 8, otherwise release sets phase 9. |
| 66 / `0x23` | `tenten_action23_phase2`: phase 2 condition -2 → phase 0. | `tenten_channel3` latches the current phase on release/count admission, then sets phase 3 only after the phase differs. |
| 77 / `0x1B` | `character_id077_action1b_phase3`: phase 3 condition -3 → phase 0. | `fighter_authored_voice_update` resets `action_second_entry_count` at primary zero, then increments at phase-0 zero events. In phases 2..3, release or count ≥ 3 sets phase 4. |

For IDs 51, 62 and 77, primary zero clears instead of counting that entry.
Their float entry counters are separate from the wrap byte. ID 51 first runs
a ground query and landing transition, then rechecks action `0x2C`;
a landing-driven action change can bypass the later held decision.

### Chiyo's growing increment

Each admitted secondary event 1 increases `action_rate_addition_count`,
truncates it to a signed halfword, and adds that halfword times 37 to the
current rate, capped unsigned at `0x300`
(`chiyo_rate_increment_constants`). Event crossing and the accumulated count
govern the addition; it is not a fixed per-update increment. Intervening
phase-animation selection may reinstall the base row rate.

### Tenten's latch and phase-3 row rewrite

Primary zero initializes `TentenCallbackState.exit_phase_latch`,
`phase_entry_count` and `cleared_work` to -1/0/0. Secondary zero in
phases 0/1/2 independently increments the signed count, so it can count that
same invocation. Those phases write rate `0xF4 + 12 * count`.

While unlatched, positive count plus release or count > 4 records the current
phase. That invocation still selects phase 3's animation as
`0x80 / 0x82 / 0x84` from current phase 0/1/2. A later differing phase sets
phase 3, deferring the exit to a phase boundary.

On that exit, count exactly 6 rewrites `tenten_action23_phase3` to animation
`0x85`, motion event 2, planar speed -30, vertical speed zero, decay 0.1
and multiplier 1. Other counts disable the motion event with `0x7FFF`,
set both speeds zero, decay 0.2 and multiplier 1.

### Might Guy's two delegated loops

`might_guy_channel3` first calls `might_guy_loop_update`; a nonzero
result suppresses its ordinary body. The helper handles actions
`0x1C / 0x1D`, so a root-only writer screen does not expose these rate writes.

Action `0x1C` clears `GuySubstitutionState.loop_entry_count` at primary
zero and increments it at phase-1 secondary zero. Phases 1/2 write
`0x100 + 36 * count`. Positive count sets phase 3 on release, count > 3,
or outcome -1/1 with `hit_repeat_value == 1`.
`might_guy_action1c_phase2`'s condition -1 returns to phase 1.

Action `0x1D` phase 2 writes `0x100 + 24 * wraps` and increments phase
on release, wraps ≥ 8, the same outcome/repeat predicate, or `effect_mode == 0`.
There is no positive-wrap gate, so release can be admitted before the first
wrap. Both branches can continue presentation/outcome work after changing phase.

`might_guy_effect_mode_update` produces `GuySubstitutionState.effect_mode`:
effect `0x47` selects 1; otherwise `0x48` selects 2; neither selects zero.
Effect `0x47` takes precedence when both are present. The mode also selects
writable categories.

## Effect-dependent action and row mutation

Both channel-1 callbacks require their actual fighter ID and mutate
`Fighter.alternate_actions`, selected by `fighter_load_character_record`.
Setup belongs to [Action commands](../combat/action_commands.md#working-action-arrays);
row layout belongs to Combat action execution. Shipped categories and rows
therefore do not fully describe the live configuration.

### Rock Lee

`rock_lee_channel1` requires ID `0x43` and uses `effect_mode`:

| Local actions | Mode zero | Mode nonzero |
| --- | ---: | ---: |
| `0x18` | 0 | 4 |
| `0x1D, 0x1E, 0x27, 0x28, 0x29` | 0 | 1 |
| `0x1C, 0x23, 0x24, 0x25, 0x26` | 1 | 0 |

Action `0x2E` radii change in phase 1 bank 1, phase 2 banks 1/2,
phase 3 bank 1 and phase 4 banks 1/2. Mode zero assigns 70 to all six;
nonzero assigns 100 to the first four and 110 to the last two. Centers are
unchanged; the assignments do not establish a contact result.

### Might Guy

`might_guy_channel1` requires ID `0x45`:

| Local actions | Mode 0 or other | Mode 1 | Mode 2 |
| --- | ---: | ---: | ---: |
| `0x1C` | 4 | 0 | 0 |
| `0x1D` | 0 | 4 | 4 |
| `0x1E, 0x1F` | 0 | 1 | 1 |
| `0x20, 0x21` | 1 | 0 | 0 |
| `0x22, 0x23, 0x26, 0x27, 0x28` | 1 | 1 | 0 |
| `0x24, 0x25` | 0 | 0 | 1 |
| `0x29` | 0 | 0 | `0x100` |
| `0x2A` | 0 | 0 | `0x200` |

These assign whole category words and do not themselves select or begin an
action. The producer establishes modes 0/1/2; every other byte value receives
the mode-0 assignments.

## Lee/Guy's channel-7 render-owner publications

`fighter_render_slot` requires node flag 4, dispatches channel 7, submits
the primary scene through `projectile_compound_submit`, then invokes the
concrete auxiliary-draw virtual method. The two intervening presentation hooks
are immediate returns. Channel-7 publication therefore precedes selected
drawing work.

### Fighter-owned optional-pass parameters

`rock_lee_construct` and `fighter_id_069_construct` each allocate a
0x34-byte `CcsExtraPassDescriptor`, retain it in their private
`extra_pass_descriptor` field, and initialize it through
`transient_manager_aux_construct`. Enable starts at 1, width scalar at 1.0;
the constructors choose color `0x80`.

| Producer | Mode | `color` | `width_scalar` |
| --- | --- | --- | --- |
| `rock_lee_effect_mode_update` | Neither effect `0x44/0x45` | `0x80000000` | 1.0 |
| Same | Either present | `0x80` | 1.25 |
| `might_guy_effect_mode_update` | Mode 0 | `0x80000000` | 1.0 |
| Same | Mode 1 or 2 | `0x80` | 1.25 |

The ID-gated channel-7 leaves publish those blocks to
`model_extra_pass_descriptor`. `model_draw_parameters_setup` and
`model_draw_parameters_setup_variant` snapshot that global into
`CcsModelDrawContext.extra_pass_descriptor`.
The selected primary-scene path connects through `scene_object_submit_geometry`
to `model_dispatch_geometry`.

Optional pass bit 1 requires model flag `0x80`, a nonnull descriptor alias
and nonzero `enabled`. Ordinary drawing reaches
`model_submit_ordinary_extra_pass`; packed drawing reaches
`model_submit_packed_extra_pass` then `model_build_packed_extra_pass`.
Both supply descriptor/context to `model_extra_pass_parameters`.
Color fallback, width/alpha, packet state and geometry belong to
[Material draw modes](../../runtime/rendering/material_render_modes.md#extra-model-owned-blend-state-and-frame-restoration)
and its linked VU investigation. The static trace does not measure appearance.

`rock_lee_auxiliary_draw` restores the default optional-pass descriptor after
auxiliary traversal; `might_guy_auxiliary_draw` restores it before additional
drawing. Their deleting destructors call
`projectile_manager_member_destruct(block, 1)` and clear the private field.
That destructor also restores the default if the global still equals the freed
block, without finding or clearing already copied context aliases. The fighter
owns the block throughout temporary publication.

### Lee's separate draw/list environment

Lee additionally owns a 0x40-byte `BattleHudRenderContext` in
`RockLeeCallbackState.draw_environment`. Construction passes selector
`0x100` and the default renderer to `ordered_controller_register`;
`owns_renderer` is clear, so the renderer is borrowed.
`publish_draw_environment` starts zero.
`rock_lee_channel2` sets it at local action 6 primary event 5 and clears
it at event 13. These selected writers do not establish that every interruption
clears it. Channel 7 publishes the environment only while that byte is nonzero.

Both model-working initializers snapshot the shared environment into
`CcsModelDrawContext.draw_environment` and its renderer into `renderer`.
Optional-pass packet producers use the environment's
`allocation_list_selector` to choose their list/allocation path.
`projectile_compound_submit` also saves/restores the scene renderer through
`scene_renderer_get` and `scene_renderer_set` around scene-specific substitution.
This environment has a separate role from the optional-pass descriptor.
[Render submission](../../runtime/rendering/render_submission.md) owns generic
list/buffer lifetime and links to renderer-coordinate ownership.

Lee's auxiliary draw captures the current shared environment after channel 7.
When `auxiliary_scene` exists and `auxiliary_draw_enabled` is nonzero,
it prepares the owned environment, substitutes it except for local action
`0x33`, traverses that scene, then restores the captured value. That value
can preserve channel 7's environment; it need not be the pre-callback value.

Lee's destructor releases the environment through
`ordered_controller_destroy(block, 1)` and clears the field. The helper
selects the default through `draw_environment_select` if the global still
equals the destroyed block, and frees its renderer only when
`owns_renderer` is nonzero. Guy's mode-2 auxiliary draw saves/restores this
environment separately; his channel-7 callback publishes only the optional-pass
descriptor.

The resident BSS globals are `active_draw_environment`, the shared environment
pointer; `primary_draw_environment`, the default environment; `default_renderer`,
its renderer pointer; and `default_extra_pass_descriptor`, the default optional-pass
block. `engine_root_allocate` constructs and selects the default environment,
and `model_default_extra_pass_initialize` constructs the default optional-pass block.

### Bounded alias coverage

Equal offsets do not establish aliases. The selected owner-link routines
`projectile_linked_owner_destroy` and `projectile_linked_owner_update` compare
another object's owner-stamp field, rather than the model-working descriptor alias.

`sp_skill_copy_draw_descriptors` copies a supplied context's optional-pass
descriptor to supplied storage and repoints the context to that copy. No
incoming reference was returned in the bounded investigation, so reachability
from Lee/Guy traversal and the copy's full lifetime remain open.
`sp_skill_play_draw`'s distinct scoped global substitution belongs to
[Material draw modes](../../runtime/rendering/material_render_modes.md#scoped-cpu-state-and-restoration-boundaries).
The selected paths establish roles and concrete owners, without a complete
whole-program alias-consumer census.

## Kidomaru's secondary holds and delegated relative-cycle exit

`kidomaru_channel3` has three phase-1 secondary-timer holds:

| Local action / row | Reset while cursor | Condition | Rate | Start frame |
| --- | --- | ---: | ---: | ---: |
| `0x16` / `kidomaru_action16_hold_phase` | > 0 | 0 | `0x20` | 10 |
| `0x1F` / `kidomaru_action1f_hold_phase` | > 2 | 0 | `0x100` | 9 |
| `0x22` / `kidomaru_action22_hold_phase` | > 1 | 0 | `0x80` | 9 |

Reset preserves phase and does not reach the terminal row. Channel 2 is
`kidomaru_channel2_noop`; the charge-presentation helper
`fighter_schedule_auxiliary_audio` reads the progress ratio and schedules
presentation, without a phase setter or state transition. Another channel
produces the exit.

### Channel-1 release dispatch

`kidomaru_callback_table` selects `kidomaru_channel1`. It invokes
`input_match_binding1_release` for `0x16, 0x1F, 0x22`, in order, with
the same phase/context/direction arguments (1/1/0). It ORs the results and calls
`fighter_clear_unlatched_charge` only when all are zero. An existing release
latch preserves its amount.

The final release branch requires an input object, empty `pending_action`,
the supplied callback-local action, phase 1, and neither logical `0x2000`
nor `0x4000` in `BattleInput.logical_mask`. It latches progress (zero
becomes 1), clears progress/overflow, and scans the working array in increasing
order for the first `ActionRecord.continuation` equal to the hold action.
`action_dispatch_index` dispatches that record in mode 0, changing action.
Earlier context/direction predicates affect return values and input rewriting,
rather than adding guards to this final release branch. Dispatch still has its
own eligibility gate.

All 39 shipped records in `kidomaru_actions` establish these first matches:

| Hold / signature | First release / continuation / signature | Row indices |
| --- | --- | --- |
| `0x16 / 0x00400212` | `0x17 / 0x16 / 0x00800112` | 100 / 103 |
| `0x1F / 0x00400214` | `0x20 / 0x1F / 0x00800114` | 127 / 130 |
| `0x22 / 0x00400414` | `0x23 / 0x22 / 0x00800114` | 136 / 139 |

Hold categories are 8 and release categories `0x10`; flags are
`0x00070009` for the first pair and `0x0007000A` for the others.
Shipped row indices become pointers during
[Action-table setup](../combat/action_commands.md#working-action-arrays).
Each hold has phase 0, held phase 1 and terminal phase 2; release dispatch
bypasses that otherwise unreached terminal row.

The constructor supplies hold threshold 12 and progress cap 36. Common synthesis
publishes `0x2000` while charging and `0x4000` on release while latching
progress; channel 1 can dispatch when both disappear. `fighters_update` runs
charge synthesis through `fighter_update_countdowns` before channel 1 and
copies the resulting input to the fighter later. This helper dispatch differs
from ordinary signature/pending selection
([Action commands](../combat/action_commands.md#resident-synthesis-after-translation)).
The static destinations do not establish every interrupted or delayed sequence.

### Channel-5 count and phase-3 destination

`kidomaru_channel5` reaches `kidomaru_auxiliary_events` when node flag 2
and `state_flags & 0x20` are set. `fighters_update_character_auxiliaries`
dispatches channel 5 after the concrete pre-attachment pass, which is a no-op
for this class. The cycle producer is therefore a channel-5 descendant.

For release action `0x23`, primary event zero clears the 25-word working
region containing the cycle fields. Phase-0 secondary zero saves
`kidomaru_cycle_limit = 2 + 8 * hold_ratio` and the ratio.
Phase-1 secondary zero increments `kidomaru_cycle_entry_count`.
At phase-2 secondary zero, count **strictly greater** than the saved limit
increments phase to 3. It counts phase entries, rather than wraps or successful
projectiles.

Phase 2 independently checks secondary event 2, sets the current phase minus 1
and sets `contact_flags` bit 0. This explicit return to phase 1 supplements
the authored animation-end jump. The check follows the phase-3 increment;
the phase setter resets the secondary timeline, so the later check sees that
reset. Shared event/reset contracts belong to Combat action execution and
[Timer primitives](../../runtime/timer_primitives.md).

`kidomaru_action23_rows` supplies:

| Phase | Animation | Condition | Start frame | Rate |
| --- | ---: | ---: | ---: | ---: |
| 0 | 107 | 1 | 0 | `0x200` |
| 1 | 106 | 4 | 1 | `0x200` |
| 2 | 107 | -1 | 0 | `0x200` |
| 3 | 107 | -16 | 0 | `0x180` |
| 4 | -1 (terminal) | — | — | — |

This is the sixth authored relative-cycle destination: count above the
charge-derived limit reaches phase 3, then its animation-end condition reaches
terminal phase 4. Channel 3 only schedules sound/presentation for this action.
The channel-5 helper independently requests emission at phase-0 and phase-2
zero events, including the invocation advancing to phase 3.
`kidomaru_emit_projectile` fails on a null spawn and does not write the
entry count; successful creation does not gate the phase exit.
[Projectiles](../projectiles_and_items/projectiles.md) owns construction and
later behavior. Ordinary-play cadence, emitted totals and all interruptions
remain outside this result.
