# Combat action execution

How retail NA2 (`SLPS-25837`) executes a selected action: entry and cleanup,
phase progression, motion events, continuation, attack publication and input
interruption.

## Research coverage

Established: common entry/cleanup and its conditional owner boundary, dispatch
ordering, separate action/phase/playback restarts, authored rows,
continuation/interruption gates, attack publication and the objects that
inherit the fighter rate.
All 78 distinct definitions' counted action/phase arrays were checked.
Open: held-phase and loop lifetimes, indirect registrations, payload meanings,
rebased delta reads, untraced owners/consumers and player-facing durations.
Names come from `@annotations/NA2`; addresses are live.

## Evidence convention

Static code and retail bytes establish control flow and array bounds, not
observed animation outcomes or reachability of every record. Unexamined
character paths remain unknown. Per-routine details and bounded code/data
censuses are in the annotations. Address conventions and complete-file
identities follow [Retail game file identities](../../game/files/file_identities.md#address-conventions).

Related owners: [Action commands](action_commands.md) covers input matching,
selection and working-array setup; [Character action callbacks](../characters/character_action_callbacks.md)
covers callback algorithms; [Hit response](hit_response.md) covers accepted-hit
reactions; [Extra Hit](extra_hit.md), [Throws and captures](throws_and_captures.md),
[X-dash](xdash.md) and [Ultimate Jutsu](../characters/ultimate_jutsu.md)
cover their execution families. [Battle entities](../session/battle_entities.md)
owns allocation and fighter-class tables.

Fighter fields use `Fighter`. Authored rows use `CharacterAnimationRow`,
motion blocks `ActionMotionEvent`, attack banks `ActionAttackBank`, and clocks
`TimelineBlock`. Fields with established width and meaning use named types,
including partial owner views; raw offsets remain where either is unresolved.
Grounded means
`contact_flags & 0x80`. Saved field declarations and raw accesses determine
the layout; decompiler field expressions after pointer arrays can disagree
with those offsets.

## Action entry and state ownership

`action_dispatch_index` completes accepted selection through
`fighter_set_action_state(fighter, 8, index, mode)`. The setter calls
`fighter_action_exit` and `fighter_prepare_action_state` before its
same-state early return and before storing the requested major/substate.
A zero return for an unchanged state therefore does not establish that
cleanup and initialization were skipped.

Major-8 preparation calls `fighter_enter_action_record`. It installs
`current_action` and `current_record`, clears `pending_action` to -1,
clears the current outcome and auxiliary outcome bytes, and clears
`published_action_record`. If the opponent's retained
`response_attack_record` equals this selected record, that pointer is cleared.
Categories `0x2`, `0x100` and `0x200` have separate entry helpers.
These operations still see the old stored major/substate.

A changed or forced entry resets `primary_timeline`, then
`fighter_set_phase` (`BTL.BIN 0x0071EEF0`) installs phase zero and resets
`secondary_timeline`. A nonzero mode forces the substate comparison by
treating its prior value as -1. Major 8 publishes the current record as
`action_descriptor`; native substates below `0x66` select
`action_descriptor_table` (`BTL.BIN 0x0089AEB0`).
`ground_air_history` starts at 1 when grounded and 2 otherwise.

### Common exit boundary

`fighter_action_exit` (`0x00217BD0`) dispatches from the old state. Majors
2 and 3 have no exit handler in this dispatcher; native exits perform their
own facing, motion, transfer or response cleanup. The dispatcher and
`action_exit_record` (`0x00238D00`) contain no direct
`character_dispatch_channel` call or fighter-class virtual cancellation.
This bounded result does not classify indirect character paths.

Major-8 exit retains the old record while applying category/outcome gates.
It can increment action statistics, release paired motion, restore exchange
rates, deactivate two query registrations, clear current/pending indexes and
reset its local countdown. A non-8 destination can force an opponent in
exactly `(5,0x50)` to neutral. The category-`0x100` helper
`capture_starter_exit` is empty; category `0x200` reaches
`fighter_cancel_current_action`, which projects each fighter's position and
updates only `position[1]` (Y) on success. Its name does not establish general
object cancellation. Capture ownership belongs to
[Throws and captures](throws_and_captures.md).

For a non-8 destination, `fighter_end_charge_on_action_exit`
(`0x00247F80`) clears hold count/progress, release latch and overflow;
a previously set latch reloads hold cooldown. With input present, it clears
logical bits `0x6000`, copies input outputs and calls `fighter_pre_phase_step`.
Other held input remains live. Category `0xF00000` reaches
`action_exit_chakra_cancel` (`0x00245310`), which calls `chakra_cancel_stage`
with argument 1 only when `action_outcome != 1`.

There is also a conditional skill-service exit: `status_flags & 4` and
category `0xC0000` call `action_exit_release_skill_control(fighter,0)`.
Its matching-primary retirement and surviving child/presentation behavior are
owned by [Battle auxiliary services](../session/battle_auxiliary_services.md#conditional-action-exit-and-skill-retirement).
No common exit sweeps transient actors or support slots. Their independent
lifetimes belong to [Battle entities](../session/battle_entities.md#ownership-model).

### State restart and animation restart

`fighter_select_phase_animation` (`0x00218190`) records a changed slot in
`animation_slot`, saves the old slot in `previous_animation_slot` (`+0xB8E`)
and clears `animation_result`. Selecting the same slot sets the previous slot
to -1 only when `animation_wrap_count == 0` and the previous slot already
matches. A nonzero wrap count preserves that match.

`fighter_advance_animation` (`0x0024D1C0`) calls
`fighter_start_phase_animation` (`0x00218060`) only when those slots differ.
For a nonnull selected animation, the start helper binds it with zero blend,
seeks a nonzero `animation_start_frame` when play entries exist, and seeks
frame 1 instead when start is zero and rate is below `0x100` under that same
gate. It clears wrap count/notification. After
advance, composition and event delivery, the updater copies selected to
previous. Forced action-state entry resets clocks but does not independently
force this playback binding. A same-slot selection can therefore retain
playback after a forced state restart.

### Confirmed execution fields

| Fields | Execution ownership |
| --- | --- |
| `major_state`, `substate`, `phase` | State/action identity and phase |
| `update_rate` | Effective fighter delta |
| `primary_timeline.current` | Action cursor, reset on changed/forced entry |
| `secondary_timeline.current` | Phase cursor, reset on phase change |
| `current_action`, `pending_action` | Selected index and one pending index (-1 absent) |
| `current_record`, `action_descriptor` | Current action and descriptor |
| `current_action_payload` | Current row's first attack bank |
| `animations`, `animation_result` | Animation lookup and end result |
| `animation_slot`, `previous_animation_slot` | Selected and last applied slots; mismatch admits playback binding |
| `secondary_rate`, `animation_start_frame` | Phase animation/clock rate and start |
| `animation_wrap_notification` | Wrap consumed by the clock update |

## Shared phase progression

`phase_event_completion` (`BTL.BIN 0x0071F160`) reads the current phase,
using phase zero for a negative index. Major-8 phases are 0x4C-byte
`CharacterAnimationRow` records from the action's resolved `row`; other
majors use 8-byte `PhaseRecord` rows. Their common prefix is animation slot,
condition, start frame and rate.

| Condition | Progression |
| ---: | --- |
| `-0x10` | Animation end |
| `-0x11` | Grounded |
| `-0x12` | Descending or grounded |
| `-0x13` | Animation end or grounded |
| `-0x14` | Animation end and grounded |
| Positive | Secondary cursor reaches the condition |
| Zero | Hold |
| Other negative | Relative phase jump on animation end, clamped to phase zero |

The updater makes at most one phase change per call, resets the secondary
clock and refreshes the major-8 payload. It returns whether the resulting
animation slot is -1. The explicit phase setter and increment entry
`gaara_variant_presentation` (`BTL.BIN 0x0071EF70`; its existing annotation
name is retained) perform reset/publication without a progression predicate.

`phase_select_animation` (`BTL.BIN 0x0071F640`) selects a nonterminal
phase's animation at the secondary zero event, provided clock flag `0x8`
is clear. Negative authored start frames add the animation's frame count.
Rate is interpreted as /256. Animation evaluation belongs to
[Animation runtime](../../runtime/animation_runtime.md); response-specific
phase tables remain in Hit response.

### Action and phase clocks

The late pass advances clocks after ordinary attack publication, fighter
virtual slot `0x2C` and callback channel 6. Without positive pause,
`fighter_advance_timelines` advances the primary clock by `update_rate`
and the secondary clock by `secondary_rate / 256.0 * update_rate`;
rate `0x100` uses the equivalent direct-delta branch.
An action event can therefore continue across phase changes while a phase
event starts again from zero.

`fighter_advance_animation` writes the truncated rate product to
`CcsAnimationPlayer.step`, saves the previous frame and publishes the
animation-end result. A frame wrap sets `animation_wrap_notification`.
Consuming it skips one secondary advance. For a held phase it also resets
that clock's integer/fractional positions and sets
`(flags & ~0x4) | 0xB`; flag `0x8` prevents the ordinary animation restart.

Positive pause clears only clock event mask `0x2`, preserving positions
and remainder. Rounding/crossing contracts belong to
[Timer primitives](../../runtime/timer_primitives.md), and pause ownership to
[Pause and replay](../session/pause_and_replay.md). Invocation counts and
authored rates alone do not establish elapsed seconds or visible duration.

### Readers and writers of the update delta

`update_rate` is used for timeline/phase advances, displacement, angles,
scene rates and proportional approaches. `scalar_approach` implements
`value += (target - value) * k`; callers supply factors such as a clamped
constant times delta, delta divided by a divisor, or the reciprocal of a
divisor divided by delta. `fighter_set_scaled_velocity` scales a requested
gain unless it is exactly 1. Effect-child playback scaling is an inference
from the stored rate.

The rate affects more than continuous motion:

| Use | Established behavior |
| --- | --- |
| Entry/transition speed approaches | One application can use gains `0.5 * delta`, `0.75 * delta`, or a character braking scalar times delta; the transition's single-run interpretation is an inference |
| Paired state 6 | Gain `min(1, 1.25 * delta)` snaps at delta 1 |
| Definition ID 22 | Repeat count is 13/11/17 for delta equal to/above/below 1 |
| Definition ID 51 auxiliary scene | No advance while delta is at most 0.1 |
| `kimimaro_second_stage_channel3` | Record rejection count and event index branch on delta above 1 |
| Definition ID 71 | Copies opponent speed times opponent delta; a further own-delta multiplication is inferred from the integrator |
| Definition ID 78 pull | Delta scales the bounded pull term and then its accumulator |
| Definition ID 80 | Adds `25 * delta` at secondary event `0x10` |
| Definitions ID 80/93 | Effective animation-rate product is compared with `0x80/0x100/0x120` |
| ID 92 response | Tests rate product below 128 and writes receiver scaling values multiplied by source delta |
| ID 93 response | Computes `min(2 * delta - 1, 1)` |
| BTL skill counter | Compares its per-update counter with `30 * delta` |
| BTL reciprocal-rate path | Timer advances by `1 / delta`, movement by `50 / delta` |

The ID 80 and ID 93 values are retained in
`fighter_id80_rate_threshold_pair` (`0x00603D20`) and
`fighter_id93_rate_threshold_pair` (`0x00604148`). The ID 92/93 output
consumers and the skill owners were not traced by this census.
The former ID 57 attribution of `kimimaro_second_stage_channel3`
conflicts with that definition's `naruto_callbacks` table. Its numeric
delta-selection behavior is established; its character ownership remains open.
`hit_handle_bit2` tests delta above 1; `fighter_apply_movement` also has a
zero-delta branch.

Other objects inherit a fighter's rate:

| Inheritor | Route |
| --- | --- |
| Skill primaries and auxiliaries | Accumulate the rate and skip logic below 1 ([rate-following steps](../session/battle_auxiliary_services.md#rate-following-steps)) |
| Effect objects from `fighter_effect_children_action_update` | All 22 spawns pass `update_rate` to `effect_rated_child_spawn`, which stores it in individually registered effect-manager objects |
| Support player in nested state 3 | `buddy_player_update` copies the primary fighter's `player.step` and derives its own rate from it |
| Character auxiliary and puppet players | Copy `Fighter.owned_animation_player.step` before advancing ([fighter animation ownership](../../runtime/scene_playback_owners.md#fighter-animation-ownership)) |

`fighter_init_neutral_rates` stores 1.0 before the first composition;
`fighters_update` composes the rate in its first pass on every update.

Several skill objects use literal 1.0 when no owner is available. The
reciprocal path is `skill_reciprocal_rate_update`
(`BTL.BIN 0x0081BBB0`); `anb_update` (`BTL.BIN 0x00808F20`)
owns the counter comparison.

`fighter_update_countdowns` composes the rate. Other action paths write
literal 1.0 to both fighters or to the entering fighter; that write lasts
until the next composition. `associated_descriptor14_select`
(`BTL.BIN 0x007B96B0`) instead saves the associated owner's rate, writes
1.0 around its virtual call and restores it.

Other counters, override approaches and decays on these paths are unscaled:
paired-state invocation counts, action-motion counts, exchange-phase counts,
sequence-camera counts, statistic counts, override gains 0.0125/0.25/0.02,
halving decays and the auxiliary `3 * scalar` subtraction.
The annotation census bounds direct offset-based reads/writes; rebased
pointers and additional entry callers remain outside it.

## Ordinary dispatch order

`fighters_update` admits action processing with node flag `0x2` and no
positive pause. After hit routing and fighter virtual slot `0x1C`, it runs:

1. `fighter_copy_input_outputs`;
2. `fighter_pre_phase_step`;
3. `fighter_update_phase_and_exits`;
4. `fighter_consume_logical_input`;
5. `fighter_dispatch_action_update`.

Entity scheduling belongs to Battle entities and
[Battle lifecycle](../session/battle_lifecycle.md).

The phase/exit dispatcher skips a fighter routed this update, applies
`capture_update_sender_grounding`, advances the phase, then routes by
major state. Major 8 reaches `action_stage_outcome_continuation`;
majors 5/6 reach response/recovery owners.

The action updater runs character channels 2 and 3 first, routes major 8 to
`action_update_jutsu_record`, then selects phase animation and invokes
the embedded animation update. A transition or newly selected action can
therefore receive its update in the same list pass.

Major-8 execution branches on exchange roles, paired `context_state`,
record category and behavior flags. The ordinary path sends the phase's
motion block to `response_motion_update`; category `2`, category
`0xF00`, category `0xC0000` and behavior mask `0x2` select other consumers.

## Authored motion events and phase payload

`actions_resolve_rows` copies the character's counted rows into
`working_rows` and resolves action row indices to pointers there.
Configured jutsu can replace the first twelve rows; those provider rules
remain in [Character assets](../../game/character_assets.md) and Action commands.

Each row contains the common phase prefix, one motion block and two attack
banks. The first bank's flags also supply the shared phase/continuation gates.

| Motion field | Contract |
| --- | --- |
| `flags` | Zero suppresses the motion consumer |
| `event` | `0x7FFF` disables the event |
| `planar_speed`, `vertical_speed` | Authored speed arguments |
| `decay` | Planar approach toward zero when no event is taken |
| `multiplier` | A non-1 value replaces `next_gravity` while the motion block is nonzero |

Motion flag `0x1` chooses the primary clock; `0x2` chooses the secondary
clock and takes precedence. `fighter_motion_event_due` uses the floating
crossing predicate for this consumer. Negative event times derive from a
positive phase duration, otherwise animation frame count minus one, less
the phase start and plus the negative offset, clamped at zero. Beyond the
last animation advance, the secondary path can make one final check at the
current cursor. These are crossing thresholds, not unconditional impulses.

| Motion flag group | Planar argument | Vertical argument |
| --- | --- | --- |
| `0x0100` | Authored | Authored |
| `0x0200` | Current + authored | Current + authored |
| `0x0400` | Current + authored | Authored |
| `0x0800` | Authored | Current + authored |
| Other | Current | Current |

Flag `0x10` can invert authored planar motion when `movement_facing`
and `response_facing` differ. Subsequent scaling/integration belongs to
[Movement and physics](../stages/movement_and_physics.md).

## Continuation and common exit decisions

`action_stage_outcome_continuation` requires a current record and payload.
It resolves the opponent's record in order: retained
`response_attack_record`, `response_source`, then `contact_attack_source`.
The two source fallbacks require a nonzero source-kind word; if no record
is found, `atk_dummy_record` (`0x00407C00`) supplies the fallback.
Source-kind and lifetime distinctions belong to [Target selection](target_selection.md).

When the resolved record equals the current record and `action_outcome == 1`,
the common body scans the action array upward for a continuation of the
current index with signature `0x08000000`. After validation, result 3
dispatches immediately. Current behavior `0x02000000` also permits
immediate dispatch after facing synchronization; otherwise the candidate
is staged. Input-based selection belongs to Action commands.

| First applicable condition | Effect |
| --- | --- |
| Category `0xC0000` | Skip ordinary exits, retaining trailing opponent-lock maintenance |
| Low exchange-role byte nonzero | Exchange terminal handoff |
| No exchange roles, category `0xF000` | Exchange teardown then common exit |
| Paired `context_state` nonzero | Paired-state transition owner |
| Category mask `0x2` | X-dash/motion-class transition owner |
| Pending action present | Continuation admission |
| Otherwise | Behavior and terminal/grounded conditions |

Ordinary pending continuation requires zero exchange roles and current
payload bit `0x20`. Category `0x1000` first delegates to
`exchange_wait_update`
([Extra Hit eligibility](extra_hit.md#eligibility-and-action-exit)).
Pending category `0xF00000` additionally checks its low signature context
and current groundedness. A pending index therefore need not execute.

Behavior bit `0x2` selects `attack_landing_recovery`. With bits `0x2`
and `0x1` clear, terminal phase causes common exit. With bit `0x1` set,
airborne execution can exit earlier under battle-coordinator, zero-exchange,
zero `threshold_2` and bounded `floor_probe_distance` gates. Terminal exit
uses mode 2 on the first consecutive grounded update, otherwise mode 0.

The common exit `item_attack_banks_clear` first clears approach bookkeeping:

| Exit mode | Grounded | Airborne |
| ---: | --- | --- |
| 0 | `(0,0)` | `(3,0x1E)` |
| 1 | `(4,0x26)` | `(3,0x1E)` |
| 2 | `(4,0x26)` | `(4,0x26)` |

These are established state transitions; their movement behavior belongs to
Movement and physics.

For category `0x200`, the landing branch waits for terminal, clears the
approach flags/angle, then returns to neutral or air state. Other records
combine terminal state, prior phase ground conditions, consecutive grounding,
behavior `0x08000000`, current/prior outcomes and payload masks `0x4/0x8`.
They can exit on landing or retain a ground-sensitive phase; there is no
single fixed duration.

Damage interruption reaches the [common exit boundary](#common-exit-boundary)
through the state setter; accepted-hit decisions remain in Hit response.
Outcome-copying behavior belongs to [Prior outcome byte lifetime](#prior-outcome-byte-lifetime).

## Ordinary attack registration

`fighter_update_timelines_slot` publishes ordinary attack geometry for an
active, unpaused major-8 fighter with payload bit `0x2` and no exchange role
in `0xFF00`. It also requires the pass-enable bit `state_flags & 0x10`;
a pass with it clear sets the bit and returns.

The pass supplies the two banks to `fighter_register_attack_window`
with the primary animation scene, animation-end result and secondary clock.
Outside admission it deactivates both primary registrations within the
unpaused block. Positive pause neither publishes nor deactivates them there.

| Attack-bank field | Contract |
| --- | --- |
| `flags` | Phase/attack admission flags |
| `start`, `end` | Inclusive activation bounds |
| `radius` | Corresponding geometry-bank radius |
| `skeleton_object_name` | Empty name selects the fighter transform |
| `offset_x`, `offset_z` | Authored local position offsets |

Missing phase, scene, clock or payload, either bound `-0x7FFF`, or a missing
requested skeleton node deactivates the selected bank. Negative bounds use
the positive phase duration, otherwise animation frame count minus one,
less the phase start plus the signed offset, clamped at zero.

Ordinary playback uses `timeline_interval_crossed`; looped animation uses
`timeline_interval_crossed_wrapped`. A window includes crossed positions,
not only the current cursor. Playback rate changes admission: above
`0x100`, fractional/integer advance can lower a bound by one through the
1.9 comparison, and animation end can lower an unreached bound to the current
cursor. A nonzero rate below `0x100` instead checks the scene's integer
animation frame against adjusted inclusive bounds.

On admission, the consumer resolves the node/transform, applies offsets,
updates geometry, activates the selected registration and publishes
`current_record` through `fighter_publish_current_attack`.
Failure deactivates the bank. A nonterminal phase or attack-bearing row
therefore does not establish an active attack.
[Collision](collision.md) owns contact evaluation and Hit response owns the
accepted-hit result.

### Character-specific scene and timer selection

Character-specific consumers can supply an alternate playback scene while
publishing geometry and provenance on the primary fighter. They normally
skip a bank already registered in the earlier common pass.

Classic Kankuro, Kankuro, Chiyo and Sasori also own auxiliary attack clocks.
Their named views are `FighterId018Lifecycle`,
`KankuroAttackTimelineView`, `ChiyoAttackTimelineView` and
`SasoriAttackTimelineView`; each selected auxiliary block supplies its own
scene, end result and clock. Other alternate-scene paths retain the primary
end result and secondary clock. `CharacterAttackScene57a0.scene_array`
contains playback objects; its path temporarily substitutes rate `0x100`
around attack publication.

Auxiliary clocks advance by their playback scene's unsigned step /256 when
`fighter_timer_hold_gate` reports no positive pause. During pause
`timeline_hold` suppresses its event flag without resetting positions or
remainder. Sasori's clock always follows its first playback scene even when
the attack uses the alternate scene. Arithmetic belongs to Timer primitives
and scene ownership to [Puppet control](../characters/puppet_control.md).
The recovered direct callers do not establish complete indirect coverage.

A separate path, `fighter_register_auxiliary_attack_bank`, copies a supplied
center, scales radius by `capture_uniform_scale`, selects a side-dependent
mask and activates an auxiliary registration when the effect gate admits it.
`temari_action_event_update` supplies a concrete position/radius derived
from phase payload. Countdown maintenance deactivates both auxiliary banks.
Thus the shared row-window consumer does not account for every fighter-owned
activation path; registration masks remain with Collision.

## Input interruption of an executing action

The logical-input pass evaluates guard, transformation eligibility,
`action_rewrite_logical_mask` and its admitted transition, new action
selection, then native movement requests. It works on a local mask, so
earlier admission can affect later requests.

For major 8, the rewrite predicate rejects a missing record, category
`0xC0000`, category `0xF00000` with outcome 1, category `0x100` with a
pending continuation, category `0x200`, and payload bit `0x20`.
Motion class zero requires `action_window_progress` in inclusive
`[0.5,0.95]`. That progress depends on payload, phase, animation, cursor
and rate; it is not an unconditional fraction of an action's total duration.
With nonzero class, only class 3, stage 2 and positive vertical speed qualify.

Outer gates require matching `section`/`target_section`, zero
`section_transfer_delta`, zero exchange roles,
`fighter_reaction_variant_high` returning zero and logical bit `0x40000`.
On admission, `action_consume_binding2_route` exits the action, clears any
remaining pending index and forces `(0,0x0C)` grounded or `(0,0x0D)`
airborne. A nonzero opponent action-lock timer is assigned the signed
`primary_timeline.current >> 2`. The later action selector still runs.

A separate `section_transfer_down_allowed` request requires zero exchange
and paired states, groundedness, capability `movement_flags & 0x10000`
and the relevant logical input. In major 8 it rejects category `0xC0000`
and category `0x200` with `capture_classify` result 3/4. Its caller clears
the opponent's retained record and enters `(3,0x1F)`.
Conversely, `jump_request` rejects major 8 outright and
`section_transfer_request` accepts only specified native majors 0/1/2/4.
Movement requests therefore have distinct interruption permissions.

## Character execution callbacks

`character_dispatch_channel`, channel mapping, provider selection and the
callback census are owned by [Character assets](../../game/character_assets.md#per-character-code).
Configured-provider execution needs the provider's callback table as well as
its copied rows.

`fighter_current_action_index` returns an ordinary selected index only in
major 8; configured slots 0..3 map to the provider's local ID.
A callback action ID therefore need not equal the selected array index.
`fighter_action_record` with a negative current-record selector likewise
returns the current record only in major 8.

Callbacks can author events, change rates and writable rows, allow
continuation, and hold/redirect phases independently of the shipped rows.
A row alone therefore does not determine every event, speed, window or
phase lifetime. Algorithms belong to
[Character action callbacks](../characters/character_action_callbacks.md);
auxiliary behavior belongs to [Projectiles](../projectiles_and_items/projectiles.md),
Puppet control and its other specific owners.

## Complete authored-array census

The counted arrays from all 78 distinct definitions in
`character_definition_table` were read, including the four jutsu-only
providers (IDs 26, 29, 30, 31). Identity and shared/filler definitions remain
in [Character identity](../characters/character_ids.md) and Character assets.

Every original action row index lies within its definition's counted array,
and every forward sequence reaches a terminal before the array ends.
This establishes bounds, not linear execution or reachability:
held conditions, relative jumps, callbacks and interruption can change the path.
The annotation on the definition table retains the complete counts and
linear-length histogram.

All six relative-jump records:

| Definition ID | Action / phase | Named row | Relative condition | Rate |
| ---: | --- | --- | ---: | ---: |
| 51 | `0x2C / 3` | `character_id051_action2c_phase3` (`0x004BB39C`) | -3 | 256 |
| 53 | `0x23 / 2` | `character_id053_relative_phase_row` (`0x004C4ADC`) | -1 | 512 |
| 62 | `0x1C / 7` | `chiyo_action1c_phase7` (`0x004F4C30`) | -5 | 256 |
| 66 | `0x23 / 2` | `tenten_action23_phase2` (`0x0050B7C4`) | -2 | 256 |
| 69 | `0x1C / 2` | `might_guy_action1c_phase2` (`0x0051D1C4`) | -1 | 320 |
| 77 | `0x1B / 3` | `character_id077_action1b_phase3` (`0x00543B84`) | -3 | 256 |

`character_id058_zero_rate_phase_row` (`0x004DC064`) has rate zero and
grounded condition; `character_id093_slow_held_phase_row`
(`0x005986DC`) has rate 1 and condition zero. Slow/zero animation rate
alone does not establish a malformed action: progression and character/native
handlers are separate mechanisms. Their full action lifetimes remain open.

## Prior outcome byte lifetime

`previous_action_outcome` is shared action history beside `action_outcome`.
Initialization zeros it. Action entry clears current outcome and auxiliary
bytes while retaining prior outcome. Action exit copies current to prior
only for an attack-to-attack transition; other destinations clear it.

The state setter has no independent reset, the old-state dispatcher has no
major-3 exit callback, and inspected neutral entry changes facing/exchange
without clearing the byte. These paths establish no universal fall or
landing reset.

The alternative section-transfer branch writes prior outcome 1 after the
setter installs fall `(3,0x1E)`, so cleanup precedes the write. That value
can reach a subsequent attack without being its current hit result
([Section transfers](../stages/section_transfers.md#motion-stages-and-relocation)).
Guard-response exit, recovery exit and paired-action entry also write 1
under their own gates.

Character loops can copy current outcome to prior and clear current at a
secondary zero event with a nonzero owned loop counter. Most inspected loops
use `action_entry_count`; the alternate loop uses
`action_second_entry_count`. This can replace prior outcome inside an
attack, before exit. A prior value of 1 therefore does not identify its producer.

With a current record and payload, prior outcome 1 can satisfy one alternative
of `capture_update_sender_grounding`'s record gate; the remaining
record/phase conditions still apply. `attack_landing_recovery` distinguishes
prior/current 1 in its nonterminal grounded exit path, and
`capture_compute_approach` uses prior 1, -2 and nonzero values alongside
facing, distance, record and phase gates. These influence attack motion and
landing decisions without admitting an attack by themselves.

The annotations retain the bounded resident store search. Wider,
computed/rebased-pointer stores and indirect readers remain unresolved.
An auxiliary object can have independent bytes at the same offsets:
`skill_auxiliary_init` (`BTL.BIN 0x0077F2F0`) establishes a class-5 owner
with separate registry heads, not copied fighter outcome history
([Collision](collision.md#auxiliary-objects)).
