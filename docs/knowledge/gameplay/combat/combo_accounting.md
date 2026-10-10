# Combo accounting

Live combo accumulation, interruption, reset and display publication in
unmodified retail NA2 (`SLPS-25837`).

## Research coverage

Established: side-owned counters, signed pending hits, update/reset ordering,
accepted-result and selected projectile attribution, HNW contribution gates,
auxiliary mask routing, and the separate clamped presentation count.
Open: indirect writers/callers, full admission and state reachability,
borrowed-record reuse, auxiliary UI meanings, and measured cadence.
Names come from `@annotations/NA2`; routine comments hold code-level detail.

Static code establishes operations and local ordering, not visible timing or
exhaustive player-facing reachability. Direct-call and fixed-offset screens
do not exclude indexed stores, retained-pointer aliases or indirect calls.

Related owners: [Damage](damage.md) (HP arithmetic and scaling),
[Match outcomes](../session/match_outcomes.md) and
[Battle statistics](../session/battle_statistics.md#accepted-ninjutsu-and-combo-flushing)
(metrics), [Hit response](hit_response.md) (response states),
[Battle HUD](../session/battle_hud.md#combo-digit-presentation) (digits, fade and
draw), [Battle lifecycle](../session/battle_lifecycle.md#fighter-overrides-at-phase-boundaries)
(override layout and application), [Battle entities](../session/battle_entities.md#ccskillhnw001-skill-actor)
(HNW identity, creation and state machine),
[Collision](collision.md#ccskillhnw001-interaction-records-and-accepted-event-route)
(borrowed interaction records and admission),
[Character assets](../../game/character_assets.md#action-records) (action
records), and [Ultimate Jutsu](../characters/ultimate_jutsu.md) (its controller).

## Evidence convention

Addresses are live, following
[Address conventions](../../game/files/file_identities.md#address-conventions).
Named routines, structures and data resolve through the NA2 annotations.

The resident globals are `combo_owners`, the two `NativeCombo *` slots
published by `combo_create` and read by `combo_add_side_hits`, and
`battle_input_phase_override`, the auxiliary manager pointer whose
`force_history` byte controls the input-history override in
`battle_dispatch_phases`. Both globals belong to the resident ELF, including
when accessed by overlay code.

## Resident owner and update order

`fighter_init` creates a `NativeCombo` through `combo_create`,
`combo_construct` and `combo_init`. Ownership is keyed by the low side bit
of `Fighter.control_flags`: two slots share the battle, rather than each
projectile owning a counter. Initialization clears counts, timer,
notification phase and borrowed presentation pointers.

| `NativeCombo` field | Role |
| --- | --- |
| `fighter` | Owning fighter. |
| `combo_display` | Borrowed side combo presentation child. |
| `other_displays[2]` | Independently resolved borrowed root children. |
| `reset_window.current` | Integer remaining window. |
| `current` | Signed-halfword live count. |
| `largest_completed` | Signed-halfword largest archived count. |
| `notification_phase` | Independent presentation/action notification state. |

`fighter_cleanup` frees the nonnull side owner and clears its slot after
resetting the embedded timer's type. This local teardown does not free the
three borrowed presentation children.
[Battle lifecycle](../session/battle_lifecycle.md#teardown-order) owns root
teardown.

`combo_consume_pending_hits` resolves missing children in order through
`battle_combo_display_get`, `battle_prompt_get` and
`overlay_abi_target_006b4000`. Every lookup ends that invocation, even if
successful. Count processing requires all three children present on entry.

The direct update route is `fighter_update_timelines_slot`. It visits both
nonnull owners only when the callback fighter has `contact_flags & 1` clear,
side bit zero and `node_flags & 2` set. This loop precedes the
`state_flags & 0x10` first-pass early return and positive
`update_pause.current` gate; neither later gate suppresses the loop itself.

With all children present, accounting runs in this order:

1. Decrement a nonzero `reset_window.current` through
   `countdown_decrement` by literal `1.0`.
2. Consume nonzero signed `pending_combo_hits` only while
   `status_flags & 1` is clear. Forward its exact signed delta to the
   display, add it to signed-halfword `current` without saturation, rearm
   the window to `90`, and clear the pending byte.
3. If the newly accumulated count exceeds one, publish the related result
   event; then evaluate retention/reset.
4. Publish a changed high-water statistic for a remaining nonzero count,
   then run the independent presentation/action notification tail.

The 90-unit window is in native update units. This local route does not
establish invocation frequency.

## Retention and reset

Let `attacker = combo.fighter` and `defender = attacker.opponent`.
The reset contract of `combo_consume_pending_hits` is:

```text
keep = fighter_current_action_index(attacker) in {1, 3}
       and (defender.state_flags & 0x80) != 0
free = (defender.major_state, defender.substate) not in {(0,6), (0,7)}
       and defender.action_lock.current == 0
       and guard_entry_allowed(defender) != 0
reset = not keep and ((combo.current != 0 and reset_window.current == 0) or free)
```

`guard_entry_allowed` accepts major 0 only in substates 0/3/4/5,
rejects majors 5..8, and otherwise retains its initial nonzero result.
A nonzero `section_transfer_delta` or
`fighter_reaction_variant_high(defender)` rejects eligibility.
The latter tests the defender's reaction-variant low bits; it is a
fighter-specific query. Full reachability of these numeric predicates remains
open.

`fighter_current_action_index` returns -1 outside major 8. Within major 8,
indices outside 0..3 pass through. For 0/1 it uses `jutsu_selector[0]`;
for 2/3 it uses `jutsu_selector[1]`. Selector 1 rejects either pair.
Otherwise an odd first selector maps 0/1 to 2/3, and an even second selector
maps 2/3 to 0/1. Retention follows the resolved configured slot.

Reset invokes `hud_combo_reset_running`, raises `largest_completed` only
when the current count is larger, and clears `current`. It leaves the
pending byte and timer untouched. Thus `free` can discard a newly consumed
count in the same invocation and can reset presentation when current is
already zero; `keep` prevents both timeout and free-state reset.

## Explicit and pending updates

`combo_add_pending(fighter, delta)` performs byte-width wrapping addition
without a positivity or saturation check. `action_publish_outcome` adds one
only for outcome 1 with auxiliary publication enabled. `action_outcome` and
`action_outcome_auxiliary` are separate result bytes.

`combo_add_side_hits(side, delta)` sends the nonnull side owner's
`current + delta` to `combo_set_current_hits`. The setter acts only with
a resolved display, nonnull owner fighter and `status_flags & 1` clear.
It sends display increment **1**, stores the supplied halfword count, and
rearms/publishes the high-water path only when that supplied count is nonzero.
Its display input therefore does not track the supplied magnitude. A zero
setter neither rearms the timer nor archives `largest_completed`.

### Pending-byte lifetime and accepted-result attribution

`fighter_init`, manager consumption and `fighter_update_countdowns` clear
the pending byte. Countdown maintenance clears it independently after its
hit-stop block and outside its node-update block. Skipping manager consumption
because of unresolved children or the status gate does not establish durable
queued work.
[Battle lifecycle](../session/battle_lifecycle.md#phase-3-and-the-final-collision-boundary)
owns broader phase ordering.

`hit_classify_pair` publishes to the **initiating** fighter with auxiliary
publication enabled: ordinary acceptance gives 1, guard gives -1, successful
substitution gives -2, and earlier rejection returns before publication.
There is also a result-1 branch when `hit_attacker_gate_bits` returns zero;
its response meaning belongs to [Hit response](hit_response.md).
A combo hit is therefore not synonymous with every collision or damage event.

The screened character callbacks publish outcome 1 with auxiliary publication
disabled, so their outcome byte alone does not add a pending hit. Their
routine annotations retain the bounded publication inventory.
[Character action callbacks](../characters/character_action_callbacks.md)
owns callback identity and bodies; numeric entries alone do not assign move
names.

### Other direct byte producers

| Producer | Attribution and contribution |
| --- | --- |
| `projectile_response34` (`0x007305A0`) | Skip exactly when `Projectile.combo_publication_suppressed == 1`; otherwise sign-extend the incoming side halfword, resolve `primary_fighter_get`, and add one when nonnull. |
| `skill_shared_float_damage_a` (`0x0079FDC0`) | Primary fighter selected by the actor's side; pending +1 follows optional accumulated-count flush and optional direct damage. |
| `skill_shared_float_damage_b` (`0x007D4470`) | Same side attribution and ordering. |
| `skill_hnw001_contribute_combo` (`0x0085EA00`) | HNW's conditional repeated-event contribution below. |

`primary_fighter_get` returns the corresponding primary fighter for side
0 or 1 and null otherwise. The projectile's suppression flag is independent
of that argument. `transient_actor_reset` clears it;
`projectile_contact_response` sets it to 1 on a spawned child, suppressing
that child's future common publication.
[Projectile motion](../projectiles_and_items/projectile_motion.md#representative-callback-composition)
owns the projectile callback table.

The concrete contact route `transient_actor_lineage_notify`
(`0x0072E740`) calls projectile slot 0x34 only with contacted
`guard_state == 0`. It supplies the projectile and signed-halfword
`(contacted.control_flags & 1) ^ 1`, crediting the primary fighter opposite
the contacted fighter without reading `Projectile.side_tag`.
Optional direct damage joins before this gate; later affiliation and slot
0x40 gates do not guard this earlier publication.
[Projectile contact](../projectiles_and_items/projectiles.md#hit-and-despawn-evidence)
and [Damage](damage.md#shared-wrapper-and-combo-call-contracts) own the broader
contracts. Other attribution callers remain open.

`hit_paired_marker_consume(fighter, enabled)` requires a nonzero low enabled
byte and the opponent's signed-byte `paired_hit_marker` outside 0/-1/-2
before either side effect. On admission, it notifies the opposite-side
support child through `support_notify_object_hit`, then adds one to
**fighter.opponent**. This differs from initiating-fighter
pair publication. In `hit_route_accepted`, a disabled call cannot count;
substitution writes -2 before the enabled call; ordinary routing writes 1
and reaches the enabled join after hit handling, as does the guarded handler's
continuation. The marker predicate remains authoritative.

### Repeated-event contribution in `ccSkillHNW001`

HNW is Hinata's `守護八卦六十四掌` skill actor; its creation and identity
are owned by [Battle entities](../session/battle_entities.md#ccskillhnw001-skill-actor).
Its borrowed-record admission is owned by
[Collision](collision.md#ccskillhnw001-interaction-records-and-accepted-event-route).

`skill_hnw001_contribute_combo` uses the following gate and values:

| Condition / old value | Result |
| --- | --- |
| Valid linked target with `guard_state != 0` | Block contribution. |
| `finish_event != 0`, `finish_requested != 0`, or `accepted_event == 0` | Block contribution. |
| Signed `counting_counter < 8` | Add one to that counter only. |
| Signed `counting_counter >= 8` | Add two to the counter and publish exactly one pending hit to the actor side's primary fighter. |

Target validity combines `target_valid`, `target` and
`downed_override_allowed`. Either accepted counting branch clears
`accepted_event`; a blocked gate retains it.

`skill_hnw001_initialize` and `skill_hnw_activate` clear the counting and
local counters and all four contribution bytes.
`skill_hnw_accepted_event` sets `descriptor_threshold_reached` from its
descriptor comparison, requests state 2 only below that state, writes linked
target statistic 3 without guard or 9 with guard, and sets `accepted_event`.
When `finish_requested == 1`, it also sets `finish_event = 1`; a count
at least 32 emits feedback. Both feedback paths continue through the receiver,
rather than returning before the latch write.

`skill_hnw_update_state_2` increments `local_hit_count`. Its descriptor
branch requires `descriptor_threshold_reached == 1` and no valid guarded
target. Positive unsigned `pending_hit_count` is consumed for descriptor
rebuilding; zero requests state 3. That branch clears the descriptor latch
and local counter. The contribution helper runs **after the branch join**,
so its own event/finish/target gates determine counting independently of the
input and descriptor predicates.

`skill_hnw001_set_state` state 4 sets `finish_requested`; a later
receiver acknowledges `finish_event` and can still write `accepted_event`.
The contribution helper blocks on the finish bytes. These finish bytes are
not independent pending-hit producers.

Activation separately resets the nonnull side display's running count before
selecting state 0. It does not reset the resident gameplay current at that
point.

### Shared input producer of the contribution gate

`skill_update_input_contributions` requires an `input_event` and
`input_events_enabled`. It first ages a nonzero pending count when
`input_event_age_limit` is nonzero: increment age below the limit, otherwise
clear pending. A successful `binding1_shared_press_a` then increments
unsigned halfword `total_input_events` and `pending_input_events` with
halfword wrapping, clears age, and notifies the side prompt.

HNW activation clears all four input halfwords and initializes its
`SharedSkillInputEvent`. The zero age limit disables age-based clearing
until another writer changes it. State 0 enables the actor and input-object
bytes at call counter 5; state 1 clears positive pending input and the local
counter; state 5 disables input. This input count governs the descriptor
branch above, rather than being a prerequisite inside the contribution helper.

`binding1_shared_press_a` uses `controlled_press & 1` on the admitted
alternate-controller branch. Otherwise it obtains `bindings_get(side + 1)`
and intersects configured binding 1 with the side's shared pressed mask;
missing bindings return false. The configuration does not establish a fixed
physical button. [Action commands](action_commands.md#native-masks-and-bindings)
and [Controller input](../../runtime/controller_input.md) own those input
domains.

Inherited slot 0x124 uses `skill_primary_input_callback`, which performs
ordinary virtual work before the input updater. A nonzero
`BtlSkillPlayback.transfer_blocked` selects another branch and skips that
route. This establishes an invocation path, not one increment per frame or
a measured order relative to every HNW update.

## Per-side accumulated contribution route

`InteractionManager.pending_combo_hits[2]` contains pending **words**,
distinct from the fighter byte; `combo_countdown[2]` supplies their
maintenance countdowns.
[Battle statistics](../session/battle_statistics.md#accepted-ninjutsu-and-combo-flushing)
owns accepted-event writers, the flush inventory and metrics.

`interaction_accumulate_contributions` requires the battle manager and
loops over exactly two sides. A missing display skips that side's work.
Every side's pending word is cleared at the loop tail, including this case.

`fighter_overrides_get` returns the shared `chakra_control_state`.
`combo_accumulation_enabled` accepts only side 0/1 and tests the first
channel's `update_requests[side].mask`, independently of its requested byte.

| First-channel mask | Maintenance behavior |
| --- | --- |
| Nonzero | Resolve auxiliary actor resource identifier, or -1 when unavailable. When `battle_control_resource_blocked` is false and identifier is not `0x20`, decrement a nonzero countdown; if already zero, reset the display running count. Otherwise flush the full pending magnitude. |
| Zero | A positive pending word publishes `action_publish_outcome(fighter, 1, 1)` when the primary fighter exists: exactly one pending-byte increment. Countdown is not decremented. |

`combo_flush_pending` forwards a positive magnitude through
`combo_add_side_hits`, publishes result metrics, and clears the word;
nonpositive words also clear. The explicit setter still sends display +1
even when the word is larger. Maintenance's display-only reset does not
directly clear `NativeCombo.current`.

The override bank's layout, application and reset belong to
[Battle lifecycle](../session/battle_lifecycle.md#fighter-overrides-at-phase-boundaries).
Its fields' UI meanings and all selecting paths remain unresolved.

### Request-mask producers and retained values

`fighter_update_override_acquire(bank, side, value, mask)` accepts side 0/1
only. It accepts an empty first-channel record or the same stored byte, writes
the value and ORs the supplied mask. A different occupied value remains
unchanged. `fighter_update_override_release` removes intersecting bits,
clears value and mask only when no bits remain, and reapplies the bank through
`fighter_overrides_apply`. Mask bits express ownership, rather than a
decrementing reference count.

The trailing request uses `ChakraControlState.enabled` and its mask
`active`. `battle_control_acquire_mask` ORs bits and sets enabled to 1;
`battle_control_release_mask` clears supplied bits and clears enabled only
when no bits remain. `battle_control_resource_blocked` is false with mask
zero and otherwise tests enabled.

`skill_hnw001_mask` acquires first-channel value 0 for the actor's side and
`opposite_side`, using `actor.side + 1` for both masks. Its zero-argument
route releases those same bits. HNW states 3/4 acquire/release respectively.
The helper directly clears/sets linked fighters' `node_flags` bit 1 when
nonnull and separately pauses/restores admitted child animations.
Those resource operations do not add a combo hit. Requested value 0 can still
select full-count maintenance while its mask survives.

### Trailing-mask owners and inherited callbacks

HNW's `skill_hnw001_vtable` inherits `skill_control_acquire` and
`skill_control_release` at slots 0x210/0x214. Acquisition requires the
battle manager; with a bank it adds trailing `actor.side + 1` and
third-channel value-1 requests for own/opposite sides, and sets valid linked
fighters' `state_flags` bit 7. It sets `control_mask_active` even if the
bank is null. Release requires that latch and the battle manager for its
requests, removes the same masks, and clears valid linked fighters' bit 7.
It always clears the latch; it does not restore a saved fighter flag.
`downed_override_allowed` is a Boolean pointer/hub-existence predicate,
not a reader of fighter node flags.

`skill_control_definition_enabled` tests the first fixed definition's
`InteractionDefinition.control_definition_enabled` byte. HNW's
`skill_hnw_definitions` byte is zero.
In `skill_primary_event_update`, that zero-result branch selects setup
slot 0x22C; the **nonzero** branch invokes slot 0x208 with flags -1.
Thus this binding does not establish HNW acquisition of a trailing mask.

When invoked, slot 0x208's `skill_control_dispatch` retains flags in
`InteractionManager.control_dispatch_flags`, invokes acquisition for bit 0
and marks `control_dispatch_active`. Other bits choose separate control
callbacks. Slot 0x20C's `skill_control_cleanup` clears retained flags,
performs eligible linked-descriptor cleanup, and invokes release before
clearing `control_dispatch_active`. The release latch is independent of
that dispatcher.

Another directly screened actor family also owns trailing requests; its
player-facing identity remains unassigned.
`fighter_overrides_acquire_global` uses mask `0x1000` for the trailing
request and first-channel value 0 / third-channel value 1 on both sides.
`fighter_overrides_release_global` removes those bits. `clash_initialize`
provides a nonnull-bank acquisition route before later primary-fighter flag
changes; its earlier admission gates are outside this join.
A local release need not clear maintenance gates while another owner's mask
survives.

## Separate presentation count

`btl_counter_arm_stopped_player` (`0x006B6C30`) adds its signed integer
delta to `BattleRootCombo.running_count` and clamps it to 0..255.
Only a result greater than one copies to `latched_count`, sets `active`,
restarts appearance values, writes `shake_count = 10`, and resets the
associated render child. One hit alone does not start that branch.

`hud_combo_reset_running` (`0x006B6BF0`) clears only the running count,
leaving the latch and active visual result intact. Completed digits can
therefore remain after gameplay current becomes zero.
[Battle HUD](../session/battle_hud.md#combo-digit-presentation) owns side
binding, fade, shake and digit styling. Drawing uses the latched count; fading
does not inspect gameplay current or its 90-unit timer.

## Remaining static leads

- Complete projectile slot-0x34 invocation and attribution sources beyond the
  concrete contact join remain open. The screened indirect-slot encoding
  includes primary actor tables as well as projectile tables.
- Complete HNW collision admission, all state-2 entries, later borrowed-record
  mutation and simultaneous reuse remain open. Authored markers and local
  counters do not establish visible cadence.
- Auxiliary masks have concrete setters, HNW side-mask selection, inherited
  acquisition/cleanup interfaces and a global-request caller. Every indirect
  owner, actual HNW trailing-mask acquisition path, alternate selection and
  UI meaning remains unresolved.
