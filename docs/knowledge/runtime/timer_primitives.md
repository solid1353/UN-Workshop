# Shared timer and frame-event primitives

## Research coverage

Established: NA2 fractional cursors, five event/range predicates, fixed-point
countdown arithmetic, reset/arming, selected caller gates and local ordering.
Names come from `@annotations/NA2`; annotations hold per-routine code detail.
Open: the reset sentinel's consumer, indirect-call coverage, exceptional inputs,
complete timer coverage and the wall-clock duration of a count.
Evidence is static retail `SLPS-25837` code; addresses below are live.

This document owns reusable timer contracts. Fighter phase meanings belong to
[Hit response](../gameplay/combat/hit_response.md), combo ownership to
[Damage](../gameplay/combat/damage.md), and countdown presentation/suppression to
[Pause and replay](../gameplay/session/pause_and_replay.md). Other owners:
[Animation runtime](animation_runtime.md), [UI animation](ui_animation.md),
[Battle audio](../gameplay/session/battle_audio.md),
[Randomness](randomness.md#ee-hardware-conversion-and-software-packing) and
[Retail game file identities](../game/files/file_identities.md#address-conventions).

## Fractional integer-cursor block

`TimelineBlock` is a `0x24`-byte embedded cursor/countdown record.
`timeline_construct` initializes `type` to `timeline_type_descriptor`
(`0x005DA070`), resets the record and returns its pointer. The descriptor's
semantic type remains unknown; reset and arithmetic preserve it.

| Field | Established contract |
| --- | --- |
| `reserved` | Reset to zero; unused by the scoped arithmetic/event helpers. |
| `flags` | Masks `0x1/0x2` mark whole-unit extraction or assignment. Mask `0x4` survives advancement; mask `0x8` is cleared. |
| `assigned` | Last explicit assignment; neither advance helper changes it. |
| `previous` | Previous integer, refreshed only when a whole unit is extracted; it can predate the immediately previous call. |
| `current` | Signed integer cursor/count. |
| `previous_position` | Previous call's fractional position. |
| `position` | Signed `current` converted to float plus `remainder`. |
| `predicted` | Position plus forward delta or minus countdown delta; countdown prediction is clamped at zero. |
| `remainder` | Fraction accumulated through repeated addition/subtraction of `1.0`. |
| `type` | Descriptor pointer preserved after construction. |

### Reset, assignment and flag contracts

| Routine | Live entry | Behavior |
| --- | --- | --- |
| `timeline_construct` | `0x00211730` | Initialize descriptor and reset. |
| `timeline_init` | `0x00211770` | Clear reserved, integer and float views; assign flags `3`. |
| `timeline_set_position` | `0x002117A0` | Assign all three integer views and their float conversions, zero remainder, assign `(flags | 3) & 0xFFF3`. |
| `timeline_hold` | `0x00211F70` | Clear only mask `0x2`; preserve positions and remainder. |

Reset and assignment arm exact-integer events without advancement. Assignment
clears pending mask `0x4` and mask `0x8`; reset replaces all flags.

### Forward and reverse arithmetic

`timeline_advance` (`0x00211D80`) adds caller-supplied delta to
`remainder`. At remainder at least `1.0`, it snapshots `current` into
`previous`, then subtracts whole units and increments the integer. Reaching
`0x7FFFFFFF` replaces it with `0x7FFFFFFD`: a two-step retreat, with no
other wrap check.

`countdown_decrement` (`0x00211E70`) subtracts delta. At remainder at most
`-1.0`, it snapshots the integer, extracts whole units and decrements, then
clamps a negative integer to zero. That clamp occurs only after whole-unit
extraction. Fractional position and remainder can remain negative; only
prediction is clamped unconditionally when negative.

Both set masks `0x1/0x2` after whole-unit extraction and clear them otherwise.
They update fractional history each call, preserve pending mask `0x4`, clear
mask `0x8`, and leave `assigned` unchanged. They read no clock, scheduler,
pause state or pending flag. Neither validates delta nor caps the extraction
loop; there is no float-to-integer rounding step.

For finite nonnegative deltas whose loops terminate, starting from reset or
assignment, forward remainder lies in `[0,1)` and countdown remainder in
`(-1,0]`. **Inference:** at ordinary small positive counts, delta `0.5`
extracts a whole unit every second call while fractional state changes each
call. Countdown zero can coexist with negative fractional position after
overshoot. Counts are invocation units; the helpers establish no seconds or
display cadence.

`entry` (`0x00100008`) clears FCSR at `boot_clear_fcsr`
(`0x00100118`). The scoped timer helpers do not write it. EE rounding is
fixed in hardware; clearing FCSR does not select a rounding mode
([Randomness](randomness.md#ee-hardware-conversion-and-software-packing)).

### Event and interval predicates

All five predicates return Boolean `0/1`, leave the record unchanged and
consume no event.

| Routine | Live entry | Contract for ordinary non-wrapping integer differences |
| --- | --- | --- |
| `timeline_integer_event_crossed` | `0x002117F0` | Differences at least `2` or at most `-2` visit previous-exclusive/current-inclusive integers in the chosen direction. Differences `-1/0/1` compare only current. Flags/floats are ignored. |
| `timeline_event_crossed` | `0x002118A0` | Fractional predicate below; exact-boundary enable mask `0x1`. |
| `timeline_secondary_event_crossed` | `0x00211A20` | Same fractional predicate; independent exact-boundary enable mask `0x2`. |
| `timeline_interval_crossed` | `0x00211BA0` | Same integer traversal, accepting any visited integer in inclusive `[low, high]`. |
| `timeline_interval_crossed_wrapped` | `0x00211C80` | Reduce previous/current by signed remainder modulo period; replace current remainder zero with period only when previous remainder is nonzero, then apply the inclusive traversal. |

Direction follows signed comparisons of a wrapping 32-bit difference. No
elapsed-time interpretation is established after difference overflow. The
wrapped helper neither guards its divisor nor reconstructs complete cycles:
equal reduced endpoints cannot distinguish a full cycle from no movement.
Only the nonzero-to-zero endpoint receives the explicit adjustment.

For the fractional predicates, let `C/R` be current/remainder,
`P/F/N` previous_position/position/predicted, and `E` the signed event
converted to float. For finite comparable values:

1. Selected flag set, `C == event` and `R == 0` succeeds immediately.
   Selected flag clear with `R == 0` fails immediately.
2. Remaining paths fail for event `0` or `P == F`.
3. Increasing `P < F` requires `P < E < N`, normally also `F <= E <= N`.
   Event `1` with previous integer `0` instead requires `P <= E <= F`.
4. Decreasing `F < P` requires `N < E < P` and `N <= E <= F`.

The usual increasing window can report an event before current reaches it,
excluding prediction's endpoint. The event-`1` exception waits for current.
Reverse uses a predicted-exclusive/current-inclusive lower window. Event
`0` needs the enabled exact boundary; integer zero with nonzero remainder
does not suffice. Neither predicate uses an epsilon or hidden one-shot latch.

**Inference:** unchanged repeated queries return the same result.
`timeline_hold` suppresses the secondary exact boundary while leaving the
primary enable independent. It does not disable fractional paths with nonzero
remainder, which matters when consumers run without advancement.

### Bounded callers and scheduling ownership

The selected callers establish these local gates; indirect calls and other
timer implementations remain outside the established coverage.

| Owner / named record | Delta or assignment | Local gate/order |
| --- | --- | --- |
| `fighter_advance_timelines`: `Fighter.primary_timeline/secondary_timeline` | Primary `update_rate`; secondary `secondary_rate / 256 * update_rate`, with `0x100` handled directly | Positive `update_pause.current` skips both and holds their event mask. `animation_wrap_notification` can select secondary reset instead of advance. |
| `combo_consume_pending_hits`: `NativeCombo.reset_window` | Decrement `1.0`; rearm `90` | Only when current is nonzero; decrement precedes pending-count consumption/rearming. |
| `fighter_update_countdowns`: `action_lock/embedded_block_26c/embedded_block_290` | `update_rate` | Inside `node_flags & 2`, with pause below `1`. Lock checks integer nonzero; other two query fractional event `0`. The first embedded block can activate pending work instead. |
| Same owner: `hit_rejection` | `1.0` | Under the preceding unpaused gates, event `0` precedes decrement/activation. Pending activation is also allowed during positive pause, without decrement. |
| Same owner: `update_pause` | `1.0` | Event `0` precedes decrement/activation after the `node_flags & 2` branch and the three rate-scaled channels. |
| `fighter_id_018_attack_timer_pass`: `FighterId018Lifecycle.timer` | `scene.step / 256` | Advance only when `fighter_timer_hold_gate == 0`; otherwise hold. |
| `kankuro_route_puppet_attacks`: both `KankuroAttackTimelineView` attack timelines | Corresponding `scene.step / 256` | Same gate; two independent records. |
| `chiyo_route_puppet_attacks`: both `ChiyoAttackTimelineView` attack timelines | Corresponding `scene.step / 256` | Same gate; two independent records. |
| `sasori_route_puppet_attacks`: `SasoriAttackTimelineView.timeline` | First `playback_scene.step / 256` | Same gate, even when attack publication selects the alternate scene. |
| `fighter_auxiliary_timeline_6168_update`: `CharacterTimeline6168.timeline` | Fighter `update_rate` | Same gate. |
| `wood_controller_late_pass` (BTL `0x007243E0`): `WoodTimerNode.timeline` | For finite comparable values, greater of `minimum_delta` and fighter `update_rate` | Duration-to-`0x7FFF` interval is checked first; success takes the expiry-callback path. Otherwise the same pause gate chooses advance or hold. |

`fighter_timer_hold_gate` means exactly signed
`Fighter.update_pause.current > 0`. Auxiliary records are separate embedded
instances. Their character/puppet meaning remains with gameplay ownership.

Pending activation belongs to the caller. Maintenance negates current, assigns
all integer views and their float conversions, zeroes remainder and assigns
`(flags | 3) & 0xFFF3`, instead of decrementing. Pending mask `0x4` itself
does not freeze a direct decrement call. For `embedded_block_26c`,
`hit_rejection` and `update_pause`, an enabled zero event can skip the
pending branch because that query comes first.

`fighter_motion_event_due` chooses fractional or integer events from its
crossing argument, and primary/secondary timeline from descriptor bits. Its
signed frame-relative values and `0x7FFF` omission sentinel are caller
policies. `fighter_register_attack_window` chooses wrapped intervals when
`CcsAnimationDescriptor.flags & 2` is set; its period is
`frame_count - 1`, narrowed to a signed halfword. A nonzero scene step below
`0x100` adds an authored-frame comparison which can replace the predicate
result.

`fighter_present_action_effects` uses secondary-enable event `0` on the
primary timeline before effect dispatch; `awakening_enter_class_seven` uses
it on the secondary timeline
([Awakening](../gameplay/characters/awakening.md)). Predicates do not advance
these records.

### Selected outer order

`fighters_update` runs countdown maintenance before its later state/contact
passes. Separately, `fighter_update_timelines_slot` performs its gated
contact-range work, the character virtual callback and
`character_dispatch_channel(fighter, 6)` before `fighter_advance_timelines`.
Its early-return and flags gates can omit advancement.

Inside `node_flags & 2`, `fighter_update_movement_slot` calls action effect
presentation then `fighter_schedule_action_audio`, outside its inner
positive-pause branch. Audio uses secondary-enable primary event `0`, or the
descriptor-authored event in major `8`. Cue ownership and other gates belong
to [Battle audio](../gameplay/session/battle_audio.md). These local orders
alone do not establish how often the outer scheduler invokes each owner.

## Fixed-point remaining/elapsed block

`BattleCountdown` is a separate `0x20`-byte record; it is not interchangeable
with `TimelineBlock`. The examined resident global instance is
`battle_countdown` in `SLPS_258.37`.

| Field | Established role |
| --- | --- |
| `flags` | Masks `0x1` suppress work, `0x2` freeze arithmetic and `0x4` mark terminal; reset/setters preserve other byte bits. |
| `remaining` | Signed-tested 32-bit fixed-point value, initialized from a whole count shifted left `24`. |
| `elapsed` | 32-bit fixed-point value, unsigned-capped at `0x63000000` before terminal handling. |
| `snapshot_0c/snapshot_10` | Words cleared by configured reset and unused by advance; snapshot ownership belongs to [Practice mode](../gameplay/modes/practice_mode.md). |
| `limit` | Initial whole count; terminal handling replaces elapsed with `limit << 24`. |
| `reset_sentinel` | Configured reset assigns `-1`; consumer meaning remains unknown. |
| `delta` | Subtracted from remaining/added to elapsed; configured value `0x00044444`. |

There are 24 fractional bits. Stored delta
`0x00044444 = floor(2^24 / 60)` is quantized. **Arithmetic consequence:**
sixty eligible updates sum to `0x00FFFFF0`, sixteen fixed-point units short
of `1 << 24`. This establishes a nominal sixty-update whole-unit scale,
without establishing display or wall-clock cadence.

### Advance, suppression and terminal ordering

`battle_countdown_advance` (`0x001EBA80`) runs in this order:

1. Existing terminal mask `0x4` returns `1` without mutation, even when
   suppression is set.
2. Otherwise suppression mask `0x1` returns `0` without arithmetic or
   remaining-value checks.
3. Freeze mask `0x2` skips subtraction/addition. Otherwise subtract delta
   from remaining and add it to elapsed, wrapping at 32 bits; cap elapsed
   only when its new unsigned value exceeds `0x63000000`.
4. Regardless of freeze, signed negative remaining clamps to zero, sets
   terminal, replaces elapsed with `limit << 24` and returns `1`.

An exact zero is not terminal until a later eligible decrement; previously
negative remaining can terminate while arithmetic is frozen. Terminal overwrite
follows the cap, so arbitrary caller-provided limits need not preserve that cap.
Delta validation and wrap prevention are absent.

### Clear versus configured reset

| Routine | Contract |
| --- | --- |
| `battle_countdown_clear` (`0x001EBA10`) | Clear low three flag bits and all named words, including delta; preserve other flag bits. |
| `battle_countdown_destroy` (`0x001EB9B0`) | For a nonnull record, clear it and additionally `heap_free` for positive signed-halfword delete flag; return the original pointer. |
| `practice_driver_reset_snapshots` | Clear low three flag bits, remaining/elapsed/snapshots; set limit `99`, sentinel `-1`, delta `0x00044444`. |
| `profile_static_initialize` | Same configured global-clock values at startup. |
| `battle_state_setup` | Set suppression, clear terminal; limit from manager selector `6`, remaining `limit << 24`, terminal if that is zero, elapsed zero; preserve delta/freeze. |

Generic clear has a zero-delta contract. The battle's configured reset and
presentation are owned by
[Pause and replay](../gameplay/session/pause_and_replay.md#battle-countdown-gate-and-presentation).

`battle_clock_freeze_set` replaces only the arithmetic-freeze bit from the
input's low bit. `battle_collect_scheduler_masks` assigns suppression from
two suppression words before complementing them into controller masks.
`battle_timer_update` owns the recovered advance call and its additional
fighter/session gates; flag bits alone do not establish scheduling.
`battle_evaluate_terminal_conditions` consumes terminal state and publishes
the expiry latch; [Collision](../gameplay/combat/collision.md) owns its combat
use.

## Integer time-unit conversion

`timer_whole_units` (`0x001EBB70`) is pure signed `count / 60`, truncating
toward zero. It has no timer record, reset, remainder or scheduler access.

`stats_condition` uses it to classify signed-halfword counts/maxima against
`4/6/60/1/3`; it does not advance or reset those counters. Gameplay meanings
and producer coverage belong to
[Match outcomes](../gameplay/session/match_outcomes.md).

## Confidence and remaining evidence limits

Arithmetic, branch endpoints and field writes are established by scoped code.
Names describe demonstrated operations; retail source type names were not
recovered. Caller coverage is bounded: incomplete function boundaries and
negative xrefs do not prove whole-program absence.

Some current typed Fighter expressions after pointer arrays disagree with raw
accesses and the saved field declaration. The raw accesses establish
`update_rate`, the embedded timeline locations and the pause gate used here;
no cause for that disagreement is established. The auxiliary Kankuro/Chiyo
views use the raw-confirmed timer locations. BTL's selected timer path is
corroborated by live disassembly where an older decompilation truncated paths
after calls classified as non-returning.

The fixed-point reset sentinel's consumer remains unknown. Positive nonzero
periods are not proved for every modulo caller; unusual signed, large or
non-finite deltas are outside established caller contracts. The helpers perform
native FPU operations without changing rounding control
([Randomness](randomness.md#ee-hardware-conversion-and-software-packing)).
