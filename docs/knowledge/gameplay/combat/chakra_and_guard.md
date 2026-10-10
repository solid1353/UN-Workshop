# Native chakra and guard state

## Research coverage

Established for retail NA2: chakra bounds/gates, reservation and effect ordering,
charge and recurring-effect rate inputs, recovery factors, bounded working-rate
writer/dispatch and supplied-vector coverage, and temporal guard state;
no durability pool was established.
Open: arbitrary aliases/computed targets, combined-state reachability, UI/timing units,
effect/flag names and control-object semantics. Evidence is static; names and
routine details come from `@annotations/NA2`. Addresses are live.

Values are raw native floats, without a pixels, icons, bars, or percentage
conversion. Reservation/history labels describe demonstrated operations;
their broader meanings remain medium confidence.

Related owners: [Substitution](../characters/substitution.md),
[Hit response](hit_response.md), [Damage](damage.md),
[Battle items and status effects](../projectiles_and_items/battle_items_and_status_effects.md),
[Support](../characters/support_mechanics.md),
[Battle HUD](../session/battle_hud.md#chakra-storage-and-display),
[Practice](../modes/practice_mode.md), [Battle AI](../session/battle_ai.md),
[Combat action execution](combat_action_execution.md), and
[Stage surface attributes](../stages/stage_surface_attributes.md).

## Source identity and address model

[Retail file identities and address conventions](../../game/files/file_identities.md#address-conventions)
own the source mappings. Fighter/resource routines are resident in
`SLPS_258.37`; `BTL.BIN` controllers call that core.
`controller_enter_guard_scaled_chakra` starts at live `0x00818360`.

`battle_manager` (`BattleManager *`) and `engine_pad_context`
(`EnginePadContext *`) are resident ELF BSS globals. The former supplies
the manager settings read by `fighter_refresh_battle_settings`; the latter
is published by `engine_root_allocate` and supplies the update counter read
by `fighter_update_countdowns` for periodic Practice refill.

## Fighter and action-record fields

`Fighter.chakra` is the only proven native current-chakra field. The maximum
is the literal `15.0`, without a proven per-fighter maximum field.
`chakra_recovery` is an authored recovery multiplier, not that maximum.

`staged_chakra`, `staged_tier`, `staged_lifetime` and `staged_lockout`
form a reservation transaction. A recorded claim does not prove that the
initial debit or eventual refund succeeded. `chakra_history_old/new` retain
eligible crossing samples; `chakra_full_feedback` gates feedback rather
than resource arithmetic.

`state_flags & 0x08` enables gain. `status_flags & 0x01` blocks gain,
`0x02` blocks ordinary spend, and `0x08` selects flat-`5.0` staged
eligibility. `staged_input_inhibit` and `chakra_debit_inhibit` cache manager
settings. `chakra_cost_tier` selects the authored `5/10/15` threshold and
cost, independently of current chakra.

`Fighter.actions` contains `ActionRecord`s. Their `cost` is raw chakra;
`flags` also carries the guard-sensitive masks described below.
`AwakeningEffectNode.lifetime != 0` makes a node active for resource folds
and flag scans; membership predicates can include a zero-countdown node.
`payload_94` contributes recovery scaling, `payload_a4/a8` are entry/zero-exit
chakra deltas, and `chakra_delta/chakra_boundary` govern per-update deltas.
The boundary suppresses a contribution; it is not a maximum.

`guard_state` is accepted held-guard age with sentinels. `guard_input_timing`
is signed input age, independently updated. Neither is durability.
The eligibility halfword `+0x9F0` retains its raw offset because its broader
meaning is unresolved.

## Chakra routine map

The resource surfaces have different gates:

| Operation | Effect gate | Fighter gates | Blocked result |
| --- | --- | --- | --- |
| Gain: `fighter_secondary_resource_add` | active `0x40` | status bit `0x01` clear; state bit `0x08` set | No arithmetic or requested feedback/event |
| Availability: `chakra_affordable` | active `0x40`, except zero cost | enough current chakra; no ordinary spend gate | False for a blocked nonzero request |
| Debit: `fighter_apply_chakra_debit` | active `0x80` when bypass is zero | debit inhibit differs from `1`; status bit `0x02` clear | False, no arithmetic |
| Staging: `chakra_staged_gate` | active `0x10`, plus availability's `0x40` | staged inhibit/lockout, action and tier gates | No new staged input |

A nonzero debit bypass skips only the effect scan. Traced direct simple-debit
requests use zero bypass. Availability therefore does not prove that a
subsequent debit will occur. Computed, split-immediate and external indirect
targets remain outside the direct-call evidence.

### Initialization, maximum, and reset/refill

Base construction (`fighter_base_construct` → `fighter_init`) zeroes chakra,
reservation metadata, crossing history and guard counters; it arms the full
feedback latch. `fighter_load_character_record` then copies
`ChakraCharacterRecord.chakra_recovery`, initializes HP and adds
`FighterResourceConfiguration.initial_chakra` through the ordinary gain
surface. Initialization accepts a general amount; all 74 screened
retail configurations author `15.0`.

Those 74 configurations author these recovery multipliers:

| Multiplier | Count |
| ---: | ---: |
| 0.80 | 4 |
| 0.85 | 3 |
| 0.90 | 11 |
| 0.95 | 2 |
| 1.00 | 32 |
| 1.10 | 9 |
| 1.15 | 5 |
| 1.20 | 5 |
| 1.50 | 3 |

Gain snaps to exactly `15.0` above the maximum or within `0.001` of it.
`jutsu_slots_rewrite` selects the authored tier through
`resource_table_signed_value` and `resource_table_signed_column`;
tiers `0/1/2` give thresholds and dynamic-record costs `5/10/15`.
Changing the selected record releases its reservation before replacing data.

`fighter_update_countdowns` attempts a Practice Unlimited refill through
gain `15.0` with feedback flags clear. It requires manager mode `3`,
major state outside `8/5/6`, clear `exchange_roles`, clear low five bits of
`EnginePadContext.update_counter`, no staged claim, and manager key `2 == 1`.
The normal gain gates still apply. No separate direct setter to maximum was
established in the traced paths.

### Manager settings behind the fighter gates

`fighter_resource_settings_init` clears both caches.
`fighter_refresh_battle_settings` obtains them through
`battle_ultimate_mode_get` and `battle_chakra_mode_get`:

| Key | Setting | Cached consequence |
| ---: | --- | --- |
| 2 | Chakra Normal/Unlimited, `0/1` | Any nonzero result sets debit inhibit to `1` |
| 5 | Ultimate Jutsu: No Use `0`, five positive modes | Zero sets staged-input inhibit; every positive mode clears it |

Manager modes `2/3` read key `2` from bit `2` of `practice.flags`;
other modes use `alternate_settings.flags`. Modes `2/3` read key `5` from
`practice.ultimate`; other modes return `2`.
[Practice settings](../modes/practice_mode.md#rows-local-values-and-manager-storage)
owns their labels and local values.

Unlimited inhibits ordinary debits without changing affordability or maximum.
Its maintenance refill has the additional gates above.
`fighter_load_character_record` refreshes the caches at setup;
`battle_start_menu_update` refreshes both fighter aliases after its
overlay-controlled result is `1`. No per-update refresh is established.

### Gain and clamp behavior

Gain adds to current chakra and applies only the upper clamp. Native gain
callers request nonnegative amounts. Its flags separately request resource
feedback, descriptor event `0x19`, and tier-crossing feedback; a blocked gain
performs none of them.

`chakra_threshold_crossed` accepts upward `old < threshold <= new` or
downward `new <= threshold < old`. Equal samples, thresholds outside the
closed interval, and nonzero nested context state do not update history.
Eligible intervals store the old/new pair and suppress a repeated endpoint
without progress beyond the prior baseline. Spend paths write `15.0` to
the old history sample; that does not refill chakra.

Charge action `(0,4)` rearms `chakra_full_feedback` on its initial primary
event and clears it after an accepted full crossing. Gain also consults that
latch for full-threshold feedback in the charge action.

The [recovery rate inputs](#recovery-rates-and-their-owners) distinguish charge,
immediate item amounts and recurring effect deltas.

| Chakra gate | Retail effect IDs |
| --- | --- |
| `0x10/0x20/0x40` | `0x0A`, `0x7C` |
| `0x80` | `0x0B`, `0x0E`, `0x0F`, `0x21`, `0x27..0x2B`, `0x38` |

No other of the 138 screened definitions sets those bits. Their recovery
modifier is `1.0`; their chakra consequences come from gates/deltas.
The `0x20` scanner has no established chakra role.
[Status effects](../projectiles_and_items/battle_items_and_status_effects.md#routing-flags)
owns authored routing, countdowns and deltas.

Item `0x0C` carries effect `0x0B`; item `0x29`, kind `3` with flags
`0x0180`, carries `0x0A` (`item_direct_effect_get`,
`item_metadata_energy_pills`, `item_metadata_code_29`).
[Field-item names](../../localization/field_item_names.md) names Energy Pills
and qualifies code `0x29`; these associations do not name every use of those
effect IDs.

The signed routes and their ordering matter:

1. `effect_generic_construct` applies `payload_a4` before
   `effect_create_node` inserts the new node. Its own blocker is not visible
   yet; other active nodes can block its delta.
2. `effect_tick_lifetime` invokes `effect_zero_countdown_actions` at zero.
   That node is already inactive to flag scans, so its own blocker cannot
   suppress `payload_a8`.
3. Forced removal and positive-node replacement do not apply the zero-exit
   delta. Replacement can repeat entry without exit. An indefinite negative
   lifetime, such as effect `0x7C`'s `-1`, never reaches ordinary zero exit;
   its authored `-15` exit is not evidence of an actual debit.
4. `effect_update` folds/routes per-update chakra before ticking countdowns.
   A node starting at `1` can contribute an update delta and an exit delta
   in the same pass. Aggregation and countdown gates are separate.
5. Boundary equality forwards the whole amount. At `15`, effect `0x88`'s
   approximately `+0.05` with boundary `15` reaches gain and clamps; at
   zero a surviving negative contribution with boundary zero can reach debit
   and write history despite unchanged current chakra.

[Countdown](../projectiles_and_items/battle_items_and_status_effects.md#countdown-pass),
[Entry and exit deltas](../projectiles_and_items/battle_items_and_status_effects.md#entry-and-ordinary-expiry-resource-deltas)
and [Signed sums](../projectiles_and_items/battle_items_and_status_effects.md#signed-sums-and-their-boundaries)
own the effect-list rules.

`effect_apply_chakra_contribution` also requires status bit `0x01` clear,
`fighter_restore_gate_b == 0`, and
`fighter_resource_contribution_blocked == 0` for self and `Fighter.opponent`.
The last predicate recognizes major `8`, a current record with category
`0x000C0000`, and its signed `streak_exempt > 0`.
The battle gate reaches `battle_footprint_gate`, which checks
`chakra_control_state` through `battle_control_resource_blocked`:
both `active` and `enabled` must be nonzero. Its broader meaning remains
unresolved. `fighter_restore_gate_a` recognizes `(6,0x61/0x62)`, and
`context_mode_word` supplies the nested context state used by aggregation
and crossing feedback.

The traced signed routes disable the additional boundary with `-1.0`.
When enabled, that boundary suppresses a call or forwards the original
amount; it never trims it. Positive amounts use ordinary gain, negative amounts
use ordinary debit with bypass zero. A successful negative `15.0` clears the
staged amount before release, preventing a refund while clearing metadata.

Representative gains:

| Path | Raw gain and consequence |
| --- | --- |
| `chakra_charge_update` | [Charge amount](#charge-amount-and-invocation), below maximum; threshold feedback |
| `item_immediate_dispatch` | [Immediate item amount](#immediate-item-recovery), gain/effect/event feedback |
| `item_status_dispatch`, event `0x5D` | `2.5`; all gain feedback flags; optional `fukidasi_create` |
| `item_pickup_callback`, event `0x0C` | `15.0`; resource/threshold feedback; other recovery events use the general router |
| `field_item_pickup_resolve`, event `0x0C` | `15.0`; resource/threshold feedback; other recovery events use the general router |
| `sp_skill_play_end` | positive target-minus-current top-up when manager exists, mode differs from `6`, and outcome is `2`; side index zero selects manager's second fighter, otherwise first |

The top-up does nothing when its callback target is no higher than current
chakra. None of these formulas establishes a per-second rate.

### Recovery rates and their owners

#### Charge amount and invocation

`chakra_charge_update` (`0x00227EE0`, resident ELF) requests this amount per
invocation while current chakra is below `15.0` and active effect flag `0x40`
is absent:

```text
amount = float32(0.05) * Fighter.chakra_recovery
         * effect_chakra_recovery_factor(fighter)
```

These are all numerical inputs in the charge amount's instruction sequence.

| Input | Owner and live evidence |
| --- | --- |
| Base amount `0.05`, bits `3D4CCCCD` | `chakra_charge_update_timing_228084` (`0x00228084`), completed by the `ori` at `0x00228088` |
| Character multiplier, fighter `+0x164` | `fighter_chakra_recovery_copy` (`0x002153B0`) copies selected character-record `+0xD8`; charge loads it at `0x00228090` |
| Active-effect multiplier | `effect_chakra_recovery_factor` (`0x00307230`); final multiply is `chakra_charge_amount_compose` (`0x002280A4`) |

The dormant source-selection alternative reads `Fighter.opponent` (`+0x20`),
but `receiver_vector_predicate` (`0x00307A50`) always returns zero in retail
NA2. Consequently the multiplier comes from the charging fighter itself.
The alternate branch does not establish an operative opponent-dependent rate.
[Replacement character parameters](../characters/awakening.md#replacement-character-parameters)
own the changes to that copied value when the fighter is reconstructed in a
different form.

The amount has no multiplication by `Fighter.update_rate`, its override or
its multiplier. Charge phase `2`, primary-timeline flag `1` and the
`current % 36` predicate select periodic presentation; they do not gate the
gain block. The native gain call is `chakra_charge_gain_call`
(`0x002280BC`), passing feedback flags `0,0,1` to
`fighter_secondary_resource_add` (`0x002254A0`). That helper retains its
status/life/effect gates and upper clamp described above.

`fighter_dispatch_action_update` (`0x00249640`) selects charge only for
major `0`, substate `4`, after character callback channels `2` and `3`.
`fighters_action_update_call` (`0x0025014C`) is in the ordinary
`fighters_update` (`0x0024FD80`) pass: node flag `0x02` must be set and
`update_pause.current < 1`. Input, phase exits and logical requests run
before that dispatch and can change the selected action.
[Ordinary dispatch order](combat_action_execution.md#ordinary-dispatch-order)
owns the surrounding action sequence.

Observed code establishes amount per admitted invocation. With neutral
character/effect multipliers, approximately 300 admitted charge calls fill
an empty 15-point gauge. At the nominal 30 service iterations per second
described in [Battle update cadence](../session/battle_lifecycle.md#battle-update-cadence),
uninterrupted eligible charging gives approximately `1.5` raw chakra per
second, or a ten-second fill. These are arithmetic consequences under that
cadence and eligibility assumption, not elapsed-time measurements.

#### Active recovery modifiers

`effect_chakra_recovery_factor` starts at `1.0` and adds
`payload_94 - 1.0` for each node whose `lifetime != 0`, without a local
clamp. Deviations stack additively, including negative lifetimes. The
payload is copied from `effect_factory_chakra_recovery_field`
(`0x0059E2D4`, factory-anchor `+0x30`) to node `+0x94` by
`effect_generic_construct` (`0x00304910`).

All 138 factory anchors were screened for this field. The complete
nonneutral authored values are:

| Effect IDs | Recovery multiplier |
| --- | ---: |
| `0x10`, `0x18`, `0x44`, `0x47`, `0x48` | `1.5` |
| `0x12`, `0x17`, `0x42`, `0x52` | `2.0` |
| `0x45` | approximately `1.3` (`1.2999999523` as float32) |
| `0x77` | `0.5` |

The other 127 anchors author `1.0`. Two active `1.5` modifiers therefore
produce `2.0`, not `2.25`. This describes the reducer; it does not establish
reachability of every combination. Effect admission, replacement and
lifetime ownership remain in
[Battle items and status effects](../projectiles_and_items/battle_items_and_status_effects.md).

#### Immediate item recovery

`item_immediate_dispatch` (`0x002369D0`) uses the same character and
active-effect multipliers when item metadata flag `0x40` selects its chakra
branch. Its base is a caller-supplied amount rather than the charge constant:

```text
amount = caller_amount * receiver.chakra_recovery
         * effect_chakra_recovery_factor(receiver)
```

`item_chakra_gain_amount_compose` (`0x00236B54`) precedes the native gain
call at `0x00236B6C`, with flags `1,1,1`. Immediate effect application occurs
before the recovery fold, so a successfully inserted effect can affect that
same item's amount. No action-rate scalar occurs in this amount either.

`item_amount_get` (`0x00376560`) reads the low-eight-bit item's metadata
amount and divides it by `100` when flag `0x20` is set. The screened direct
caller chain supplies it as follows:

| Caller | Supplied base |
| --- | --- |
| `field_item_pickup_resolve` (`0x00374190`, ELF) | Resolved item's `item_amount_get` result |
| `item_pickup_callback` (`0x0070BC20`, BTL) | Callback magnitude multiplied by `item_amount_get` |
| `item_pickup_result4` (`0x0070BE50`, BTL) | `item_amount_get(5)`, item code `5` |

These are discrete resource requests. The separate raw gains of `15.0`
for code `0x0C` and `2.5` for `0x5D`, shown above, bypass both recovery
multipliers.

#### Recurring effect recovery

`effect_chakra_contribution` (`0x00307020`) consumes each active node's
`chakra_delta` directly at `effect_chakra_delta_load` (`0x00307060`).
It sums positive and negative contributions before its net-sign boundary
decision; neither the copied character recovery, the recovery fold nor
`Fighter.update_rate` scales those values.

Among the 138 authored anchors, `effect_88_definition` (`0x005A17C4`)
is the only positive recurring chakra contribution. Its delta is
`0.0500000007451` (bits `3D4CCCCD`) and its boundary is `15.0`; its recovery
multiplier is neutral. Negative contributions can reduce or cancel this sum.
[Signed sums and their boundaries](../projectiles_and_items/battle_items_and_status_effects.md#signed-sums-and-their-boundaries)
own the aggregate decision.

The `effect_update` (`0x003059B0`) resource pass forwards a surviving nonzero
sum to `effect_apply_chakra_contribution` (`0x00306220`) before ticking
lifetimes. Its outer gates are state flag `0x80` clear,
`fighter_restore_gate_a == 0`, `exchange_roles == 0`, `context_state == 0`
and `context_mode_word == 0`. The signed router then applies the additional
fighter/opponent gates described above; positive values reach ordinary gain
with flags `0,0,0`.

`fighter_update_countdowns` calls this effect pass under node flag `0x02`
before its positive-pause branch. The action-update pause gate therefore
does not by itself suppress recurring effect gain. Its resource-pass gates
and countdown-pass gates remain independent.

#### Recovery coverage boundary

The direct gain census covers eight ELF callers and two BTL callers;
`effect_chakra_recovery_factor` has two ELF callers and no direct BTL caller.
The charge and immediate item paths are the only verified consumers of
`Fighter.chakra_recovery` in this census. Literal `lwc1 +0x164` inspection
in ELF/BTL distinguishes their loads from stack and unrelated-object loads.

The writer/alias audit used resident addresses `0x00100000..0x003FFFFF`,
BTL text `0x006B3F40..0x0088F5FF`, and ETC text
`0x006B3F40..0x006D8D7F`. It decoded aligned literal `+0x164` matches,
explicit `addiu/daddiu +0x8C` rebases, and selected neighboring stores:
64/128-bit stores beginning at `+0x160..+0x167`, plus byte/halfword stores
at `+0x164..+0x167`. This is an instruction-pattern screen, not arbitrary
pointer tracking or coverage of every unaligned/block write.

The `+0x164` screen contains 43 stores (25 ELF, 18 BTL) and 105
`addiu/daddiu` forms. `fighter_chakra_recovery_copy` remains the only
established working Fighter recovery writer in this coverage.
The loader copies record `+0x00..+0xD8` to Fighter `+0x8C..+0x164`;
`fighter_init` contains no separate recovery initialization. The verified
Fighter record aliases in gravity, jump prediction, action-array setup,
aerial steering, capture attachment and `effect_7d_update` add no recovery
write in their inspected bodies. Form reconstruction reloads the record;
its lifecycle remains owned by
[Replacement character parameters](../characters/awakening.md#replacement-character-parameters).

Matching offsets also belong to embedded projectile/query handles and
context, matrix or vector layouts. `skill_parameter_vector164_set`
(`0x00791D30`) and `skill_parameter_vector164_set_flagged` (`0x00791E40`)
occupy skill-interface slots `+0x144/+0x14C`; the inspected
`skill_parameter_vector_dispatch` passes controller `+0x200`, so the first
setter writes controller `+0x364`, rather than the linked Fighter's recovery.

For the flagged setter, all 26 literal `lw +0x14C` sites in those text ranges
(18 ELF, eight BTL, none ETC) load data or stack values, without dispatching
the skill slot. Exact direct `jal/j` targets and aligned conventional
low-`0x1E40` address construction are absent in the three imports.
The 27 standard `lw t9,+0x4C(t9)` sites (22 ELF, five BTL) load a table
from object `+0` or `+0x50`, without an observed primary-interface `+0x100`
rebase. These bounded checks recover no concrete flagged-setter invocation
or destination. Arbitrary computed/rebased dispatch remains unproved;
the slot's publication does not establish a working Fighter recovery writer.

`vector_pair160_170_set` (`0x0030F120`) copies 16-byte vectors into
destination `+0x170/+0x160`, including the numeric `+0x164` region.
All five exact BTL `jal` callers supply wrapped-resource storage:

| Annotated call and live address | Destination provenance |
| --- | --- |
| `wrapped_resource_vector_pair_call_73f3e8` (`0x0073F3E8`) | Unchanged `indexed_effect_acquire` return from `0x0073F1B0` |
| `wrapped_resource_vector_pair_call_74019c` (`0x0074019C`) | Unchanged acquire return from `0x0074008C` |
| `wrapped_resource_vector_pair_call_77af4c` (`0x0077AF4C`) | Unchanged acquire return from `0x0077AE00` |
| `wrapped_resource_vector_pair_call_819d14` (`0x00819D14`) | Unchanged, nonnull-gated acquire return from `wrapped_resource_acquire_call_819c28` (`0x00819C28`) |
| `rock_wrapper_vector_pair_call_7c5fb8` (`0x007C5FB8`) | Retained registered rock auxiliary `+0xB90`, constructed by `wrapped_resource_construct` at `0x007C5D90` |

The first four destinations are separately allocated `0x210`-byte
`WrappedScenePlayback` records; their
[indexed effect pool](../session/battle_auxiliary_services.md#indexed-effect-pool-cceffdrawobj)
owns allocation and handles. Identifying the BTL system pointer with the
resident manager remains the inference documented there.
For the fifth, `skill_jrb001_construct`
(`0x007C5AC0`) initializes the retained tuple to `(-1,-1,0)`.
`skill_jrb_rock_allocate` (`0x007C5D20`) allocates/constructs the rock
auxiliary in selector `0x0E` and publishes its registration tuple;
selector `0x14` validates slot, generation and pointer before using that
auxiliary's wrapper. None of these traced destinations is Fighter or
Fighter `+0x8C`. The three imports contain no exact stored `0x0030F120`
pointer, exact `j` target or aligned conventional low-`0xF120` address
construction. Arbitrary pointer/tuple rewrites and computed targets remain
outside this bounded result. A matching displacement alone cannot establish
Fighter ownership.

The effect audit resolves factory-installation code and node construction.
All 17 constructors reached through the 19 registered ID/factory pairs call
`effect_generic_construct` without a direct later rewrite of node recovery
`+0x94` or recurring chakra delta `+0xB4`. Their computed copies are
`effect_chakra_recovery_node_copy` (`0x00304A6C`) and
`effect_recurring_chakra_node_copy` (`0x00304B0C`). Generic entry chakra uses
node `+0xA4` through the rebased node `+0x68` alias's `+0x3C`; this is a
separate signed delta, not recovery scaling.

`effect_container_primary_dispatch_call` (`0x00305BCC`) resolves through
`effect_container_primary_update` to `list_phase_slot_10`, after resource
aggregation/countdown. Registered primary callback bodies add no direct
Fighter recovery write or gain call. `effect_container_secondary_update`
dispatches node slot `+0x14`; its registered secondary slots are the generic
no-op except `effect_4a_secondary_update`, whose inspected body adds no direct
recovery write or gain call. Embedded child-container callbacks and transitive
action/helper routes are outside this audit.
[Specialized callbacks](../projectiles_and_items/battle_items_and_status_effects.md#specialized-entry-exit-and-callback-behavior)
own their gameplay effects.

Exact full-word pointer searches in all three imported programs found no
stored target address for `fighter_secondary_resource_add` or
`effect_apply_chakra_contribution`. Split-address construction and computed
targets remain open. No additional unconditional baseline gain was established
in the inspected maintenance and dispatch paths. Initialization, reservation
refund, effect entry/zero-exit deltas, callback top-ups and Unlimited refill
remain discrete gains with the owners above; this bounded result does not
exclude complete character-script or arbitrary-alias exceptions.

### Spend, affordability, and lower clamp

Ordinary debit floors an overspend at zero and writes history old to `15.0`;
it does not independently require affordability. The simple debit returns
success only when arithmetic is admitted. `chakra_debit_feedback` selects
pre-debit feedback for modes `0/1`; modes `2..4` do not spend.

#### Direct affordability callers

The resident queued-action path (`action_queue_set`) sums costs along at most
four records, following signed `continuation`; absent initial record proposes
`30.0`. A chain can start with a record referencing the requested action and
signature flag `0x08000000`. Failure rejects before reservation/queue writes.
`action_chain_chakra_cost` supplies the same bounded sum to
`lee_loopy_channel3`; failure replaces the pending index with `0x23`.
`character_action_chakra_debit_a` and `character_action_chakra_debit_b`
check `1.5` before requesting a feedback debit of `1.5`, mode zero;
ordinary spend gates still apply.

Overlay availability checks gate selection without changing chakra. Observed
requests include record costs and raw `1.0/2.5/5.0/10.0/12.0`; some paths
continue only when the request is unaffordable. A signed table byte indexed by
integer-converted record cost is passed directly as a float, distinct from
both the bounded-chain sum and committed `5/10/15` costs. Presence of a check
does not establish its reachability. [Battle AI](../session/battle_ai.md) owns
complete selection; annotation comments retain each owner's amount and gates.

#### Debit and reservation behavior

`fighter_resource_effect_request` first requires affordability; acceptance
can emit feedback/apply the effect and return success despite a later blocked
debit. Zero amount goes directly to effect application.

`fighter_apply_hp_chakra_cadence` takes HP and chakra deltas separately.
Mode zero requires full chakra availability; mode one rejects exactly empty
chakra without requiring the full amount. Ordinary spend gates can suppress
chakra/history arithmetic while HP, cadence feedback and success continue.

`action_dispatch_index` similarly reads raw record cost, emits applicable
feedback, then conditionally spends; suppression alone does not stop later
action dispatch
([Action entry](combat_action_execution.md#action-entry-and-state-ownership)).

`chakra_reserve` accepts reservation classes `2..4` for staged record
categories `0x00100000..0x00800000`, rejecting an existing claim of at least
`15.0`. It performs no independent availability check. With spend gates
clear it subtracts/floors and writes history; whether that happens or not,
it records the requested amount and class minus one, starts lifetime `60`
if it was zero, emits feedback and succeeds.

Logical input `0x08000000` uses `chakra_staged_gate`, then records either
`(chakra_cost_tier + 1) × 5` or the status-bit-selected flat `5.0`.
Its inline debit uses ordinary spend gates, while metadata and feedback
still proceed when arithmetic is suppressed.

`chakra_cancel_stage` attempts a gated refund, then clears the amount,
class and lifetime unconditionally. Nonzero mode sets lockout `60`.
Maintenance outside staged action classes decrements lifetime without active
`0x40`, releasing at zero; active `0x40` releases immediately and blocks
that refund. A successful signed delta of `-15` discards the claim first.

`opponent_lock_override` releases its own and linked reservation, then
conditionally commits the selected tier before continuing the transition.
`action_phase_commit_chakra` releases/feeds back and conditionally commits
record cost at its phase/marker gate. Neither transition proves refund or
committed arithmetic succeeded.

The tier commit alone has a membership exception
(`effect_jutsu_debit_exception`):

| ID `0x0B` present | ID `0x3B/0x41` present | Commit effect gate |
| --- | --- | --- |
| Yes | Either | Scan active `0x80` |
| No | Yes | Skip active `0x80`; fighter gates still apply |
| No | No | Scan active `0x80` |

A zero-countdown `0x0B` still vetoes the exception but cannot itself block
the active scan. Another active blocker is needed.
`effect_3b_definition` and `effect_41_definition` author approximately
`-0.008333334` per update with boundary zero; those signed deltas still use
bypass zero. A list can therefore permit tier commit while suppressing its
ordinary delta; dynamic reachability of all combinations is unestablished.

Representative consumption:

| Path | Amount and ordering |
| --- | --- |
| `fighter_polygon_contact_class` | only contact class `1` reaches `0.008333334` debits; availability/reservation and ordinary spend gates differ |
| `contact_consume_chakra` | release first, choose integer `3..5 × 0.375`, cap to available, emit event/effect, then conditionally debit |
| Controller requests | authored positive amounts, computed aggregates, and raw `7.5/5.0/1.25`, under their respective component/state/object gates |
| Guard-scaled request | `5.0`, halved to `2.5` for admitted nonzero guard, including negative sentinel |

The contact-class path locally rejects availability under `0x40` or low
chakra, but a reservation still admits its counter branch. Both that branch
and the no-reservation/unaffordable fallback independently attempt ordinary
debit. The fallback returns `1` even when spend is blocked; the admitted
branch increments the bounded `stats[20].count/max` pair when status bit
`0x01` is clear. Class `2` returns zero before resources; classes `0/3`
return before the special section.
[Contact classes](../stages/stage_surface_attributes.md#query-eligibility-and-contact-classes)
owns polygon production and classification.

The traced controller debits use bypass zero and the ordinary floor. Their
player-facing action names and per-second rates are not established.
The separate substitution debit belongs to
[Substitution](../characters/substitution.md).

Traced recovery, configuration, effects and controller requests ultimately
change the same current-chakra field. Sharing a numeric offset in an unrelated
object does not establish another chakra pool.

## Guard routine map

`guard_update_input` owns held input and temporal counters;
`guard_entry_allowed` supplies the eligibility subset.
`hit_route_accepted` chooses ordinary/guarded responses, and
`guard_update_stance` owns subsequent exits. The direct setters are
`guard_set_state` and `guard_set_input_timing`.

`ai_dispatch_state` uses `ai_state_handlers`: cases `0x14/0x27`
write input-timing sentinel `-2`, the first after fighter/manager gates and
the second directly. They do not subtract attack strength. The separate
`hit_mode1_apply` → `transient_actor_lineage_notify` route carries the
guard-present choice described below.

### Guard input and action lifecycle

Logical `0x10000000` is guard input, passed by
`fighter_consume_logical_input` to `guard_update_input`. Input timing updates
first: nonnegative held values increment, release clears them, and negative
values advance toward zero even after release. The halfword is unsaturated:
`0x7FFF` wraps to `-32768`; `-2 → -1 → 0` takes two admitted updates.

Guard state processing is skipped in `(0,6)/(0,7)` or while
`action_lock.current` is nonzero. Those branches preserve the previous guard
state, including on release. Otherwise eligibility rejects majors `5/6/7/8`;
major `0` requires minor `0/3/4/5`; other majors retain acceptance.
Nonzero raw `+0x9F0` or `fighter_reaction_variant_high` also rejects.
`guard_entry_allowed` implements that subset without the outer preservation.

Eligible held input increments guard state up to `0x7FFF`. Release or
ineligibility clears it in this branch. Entering stance `(0,5)` additionally
requires grounded contact bit `0x80`, major other than `2`, and minor other
than `6/7`; accepted age may increment even when those entry gates skip
the transition. These predicates do not assign broader state names.

`fighter_update_phase_and_exits` calls `guard_update_stance` when stance
guard state is zero; `fighter_dispatch_action_update` separately updates
stance interpolation/animation.
`fighter_update_movement_slot` has a secondary timing-only update under
node flag `0x02`, positive `update_pause.current`, and clear
`0x01E0` in the combined control/state halfword. It changes input timing
without increasing guard state or entering stance.

`effect_update` checks `fighter_has_effect9` after aggregation but before
countdown processing and sets input timing to `-2`. Membership ignores
countdown, so the write can recur at zero pending removal or while countdown
processing is disabled
([Pending expiry](../projectiles_and_items/battle_items_and_status_effects.md#countdown-pass)).

`fighter_action_exit` sends stance `(0,5)` to `guard_stance_exit`,
which restores orientation/interpolation; guarded responses `(0,6)/(0,7)`
use `guard_response_exit`. These are temporal/action relationships, without
durability depletion.

### Guarded-hit selection and break-like flags

`hit_route_accepted` chooses ordinary `response_enter_ordinary` below
guard state `1`, and `guard_enter_response` at or above `1`; guarded
entry selects `(0,6)/(0,7)` and runs `guard_response_init`.
[Accepted-hit routing](hit_response.md#accepted-hit-routing) and
[Guarded hits](hit_response.md#guarded-hits) own admission and reactions.

Before that split, attack flag `0x00800000`, under a facing/state condition,
turns nonzero guard into `-1`; `0x00400000` clears it. Both route ordinary,
but only exact `-1` is consumed/cleared to force `(5,0x4F)` before normal
selection. It is a one-use reaction selector.

`hit_mode1_apply` orders its guard-sensitive flags:

| First matching flag | Guard operation and processing |
| --- | --- |
| `0x00400000` | Set zero, process record |
| `0x00800000` | Set `-1`, process record |
| `0x01000000` | Preserve guard, process with selector `1` for nonzero and `0` for zero |
| None | Process only with zero guard |

The local processing callee rechecks guard. The dispatcher marks its owner
processed afterwards. These effects do not establish player-facing flag names.
The overlay changes these counters through the resident setters; the traced
guard-state values are `0/-1` and timing value `-2`.

### Overlay guard-state read coverage

Named read labels in the annotations retain the live guard-load locations.
Many consumers substitute zero when a separate
fighter/component gate fails. They select flags, parameters, counters,
feedback or candidates, without treating magnitude as remaining durability.

Zero/nonzero consumers admit a negative sentinel; positive-only consumers
and the resident hit router do not. These tests cannot be collapsed
into one Boolean interpretation.

Two controller variants demonstrate the distinction:

| Routine | Guard-dependent choice |
| --- | --- |
| `skill_auxiliary_update_descriptor`, `skill_primary_update_descriptor` | Nonzero guard selects `InteractionRecord.response_selector` from signed `alternate_category`; zero uses controller-authored selection, repeat `1`, pause/rejection `0x7FFF`; nonzero also increments a local counter |
| `skill_auxiliary_submit_record` | Positive guard under accumulated flag `0x00800000` halves `attack_scalar` |
| `skill_primary_submit_record` | Same positive-only halve, additionally gated by the primary controller's component byte/predicate |
| `controller_enter_guard_scaled_chakra` | Nonzero guard halves the chakra request `5 → 2.5` |

The auxiliary positive test uses `ChakraGuardController.fighter` when
`fighter_unavailable == 0`; the primary positive test uses its separate
component predicate and linked fighter, while its selector reads through the
descriptor's fighter. Neither half changes guard state. Negative sentinels
therefore qualify for selector/cost choices but not positive-only halves.
The displayed meaning of `attack_scalar` and character/action identities
are not established here.

Coverage excludes alternate-displacement pointer arithmetic, neighboring
wider accesses and complete character-script reconstruction.

### Guard-state writer coverage

Besides arbitrary-value setters, traced writes are clear/initialization,
`-1`, or increments. The trigger helper can clear positive input timing
under another fighter-state mask; terminal paired cleanup clears guard state
before updating stance. None subtracts attack strength toward a break threshold.

The evidence bounds direct immediate field accesses, including the alternate
updater's clear. Computed-address and wider-access exceptions remain open.
[Substitution](../characters/substitution.md) owns the trigger helper's action
semantics. Census details are in the annotations.

### No proven guard-durability resource

No persistent guard-durability accumulator or maximum was established.
Guarded hits do not decrement either counter by attack strength; neither has
a depletion clamp or cumulative break consumer. State-invalidating attack
flags act per hit. Stance and flag `0x01000000` do not spend a guard resource.

This is a strong negative result for traced entry/exit/hit paths, with medium
confidence for the broader absence claim. Character-specific/scripted
exceptions remain possible.

## Rejected candidates and remaining hypotheses

### `ccEffCond_AbsGuard` is an effect class, not a durability pool

`abs_guard_effect_class_name` and `abs_guard_effect_vtable` identify
the internal class. `abs_guard_effect_construct` and `abs_guard_effect_destroy`
manage its visual object; `abs_guard_effect_update` optionally copies owner visual mode under
owner flag `0x04` and updates transforms.
`abs_guard_effect_set_position` copies position, lowers Y by `20`, then
updates the visual.

These routines do not access chakra or either guard counter and have no
decreasing resource, maximum or break transition. The class name establishes
an authored AbsGuard visual concept, without proving guard durability.

### Fighter `+0x74` is support, not guard

`support_gauge` and `support_recovery` belong to
[Support gauge](../characters/support_mechanics.md#gauge-state-and-availability).
`guard_response_init` reaches that resource through
`support_add_to_opponent`, which changes the linked fighter's gauge.
Neither is a guard maximum or durability value.

### Hypotheses requiring new evidence

- Flags `0x00800000/0x00400000` may be authored guard-bypass/invalidation
  categories. Their writes and the `0x01000000` branch are established;
  their authored/player-facing names are not.
- Timing `-2` from AI cases `0x14/0x27` and effect `0x09` may serve the
  adjacent eligibility system owned by Substitution. The writes and recovery
  toward zero are established; their purpose is not.
- A scripted guard exception may exist beyond the traced paths. A durability
  claim would require proven initialization, guarded-hit decrement, clamp and
  break consumer on the same field; none was found together.
