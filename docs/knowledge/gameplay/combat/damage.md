# Battle damage

## Research coverage

Native character durability, effective HP, combo hit index, and damage paths in
retail NA2 (`SLPS-25837`).

Established: normalized HP, durability/recovery parameters, damage factors and
precision boundaries, ordinary/guarded/contact gates, direct/cinematic paths,
shared skill-record lifetime bounds, FOR/ANB arithmetic, the complete bounded
direct-call inventory, shared-float input-event producers/class gates,
inherited and specialized direct-skill class/action joins and count ordering,
TYO/FIR/ANB action identities, retained FOR/ANB resource limits, and current
native field offsets, default projectile response/raw separation and ordinary
support record/count ownership. One observed
Practice string confirms ordinary and `0.02` contact damage. Open: other-path
execution, remaining object identities/numeric tier attribution, arbitrary aliases, skill reuse,
broader input-source aliases and later FPU rounding mode.

Names come from `@annotations/NA2`; comments hold per-routine code detail and
search bounds. Addresses are live. Static reachability does not establish
ordinary-play execution or every hardware rounding/frame-order outcome.

Related owners: [Combo accounting](combo_accounting.md),
[Target selection](target_selection.md#accepted-hit-source-boundary),
[Hit response](hit_response.md), [Collision](collision.md#definition-to-runtime-copy),
[Stage attributes](../stages/stage_surface_attributes.md#stage-authored-attribute-distribution),
[Chakra and guard](chakra_and_guard.md#gain-and-clamp-behavior),
[Support](../characters/support_mechanics.md#gauge-state-and-availability),
[Match outcomes](../session/match_outcomes.md#terminal-detector-and-classifier),
[Battle entities](../session/battle_entities.md#btl-skill-classes-on-damage-paths),
[Character IDs](../characters/character_ids.md),
[Ultimate Jutsu](../characters/ultimate_jutsu.md#damage), and
[Status effects](../projectiles_and_items/battle_items_and_status_effects.md#resident-effect-definitions).
Retail inputs are identified in
[Retail game file identities](../../game/files/file_identities.md).

## Character durability and effective base HP

`Fighter.hp` is normalized single-precision HP; full health is `1.0` for every
character. `fighter_apply_hp_debit` subtracts damage with a zero floor outside
Practice and a `0.01` floor in Practice. `fighter_load_character_record`
initializes HP through `fighter_hp_add` from the instance configuration.

Character durability is separate, copied from
`AwakeningCharacterRecord.durability` into `Fighter.durability`. Calculator
flag `0x2` converts it to incoming multiplier `m`:

```text
d = clamp(durability, 0.0, 3.0)
m = 2.0 - d                              when d < 1.0
m = 1.0 - ((d - 1.0) / 0.5) * 0.5       when 1.0 <= d < 1.5
m = 0.5 - ((d - 1.5) / 1.5) * 0.2       when d >= 1.5
```

The last coefficient is a mathematical description; its exact executable
value is under [precision boundaries](#arithmetic-precision-and-clamp-boundaries).
Neutral effective base HP on a 100-point scale is `100 / m`. This isolates
static durability, with offense and temporary effects separate. It is a derived
balance value, not stored full-gauge HP.

`character_definition_table` selects `naruto_character_record` (57) and
`sakura_character_record` (58). `hp_recovery` scales healing in
`hp_recovery_scale` and `item_immediate_dispatch`, rather than defining HP.

### Confirmed character-record fields

`fighter_load_character_record` copies these parameters to the fighter:

| Character-record field | Fighter field | Role |
| --- | --- | --- |
| `character_id` | `copied_character_id`, then `character_id` | Identity |
| `offense` | `offense` | Outgoing factor, flag `0x1` |
| `durability` | `durability` | Incoming curve, flag `0x2` |
| `hp_recovery` | `hp_recovery` | Healing multiplier |
| `chakra_recovery` | `chakra_recovery` | Recovery passed to `fighter_secondary_resource_add` |

The chakra adder's `15.0` cap and recovery belong to
[Chakra gain](chakra_and_guard.md#gain-and-clamp-behavior).

| Character | Offense | Durability | HP recovery | Chakra recovery | Effective base HP |
| --- | ---: | ---: | ---: | ---: | ---: |
| Naruto (57) | `1.1` | `0.9` | `1.0` | `1.2` | `90.909091` |
| Sakura (58) | `1.2` | `0.8` | `1.1` | `1.1` | `83.333333` |

`FighterResourceConfiguration.character_record`, `initial_hp` and
`initial_chakra` supply construction independently of durability. Both observed
Practice instances began at `1.0` HP and `15.0` chakra. Durability therefore
acts during damage, not full-health initialization. The remaining copied
fields are not all semantically identified.

## Combo hit state and damage path

Observed deterministic Practice string: Sakura (58), No Support, no starting
effect, normal attacks against Naruto (57) on the bootstrap stage. Only ordinary
`response_apply_table_timing` and `response_contact_enter`'s `0.02` branch
provided damage.

| Event | Visible hit | Path | Raw | Flags | Current / pending | Hit index | Damage | Naruto HP / counter after |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 1 | ordinary | `0.02` | `0x133` | `0 / 1` | 1 | `0.0264` | — |
| 2 | 2 | ordinary | `0.03` | `0x133` | `1 / 1` | 2 | `0.0396` | `0.934000015` / `6.5%` |
| 3 | 3, main | ordinary | `0.05` | `0x133` | `2 / 1` | 3 | `0.0660` | — |
| 4 | 3, secondary | contact | `0.02` | `0x122` | `3 / 0` | 3 | `0.0220` | `0.846000016` / `15.3%` |
| 5 | 4 | ordinary | `0.02` | `0x133` | `3 / 1` | 4 | `0.0264` | `0.819599986` / `18.0%` |
| 6 | 5 | ordinary | `0.015` | `0x133` | `4 / 1` | 5 | `0.0198` | `0.799799979` / `20.0%` |
| 7 | Fresh after reset | ordinary | `0.02` | `0x133` | `0 / 1` | 1 | `0.0264` | `0.973600030` / `2.6%` |
| 8, 9 | Later fresh hits | ordinary | `0.02` | `0x133` | `0 / 1` | 1 | `0.0264` | — |

`NativeCombo.current` reached five while `largest_completed` was zero. Reset
cleared current and raised the completed record to five; later hits counted
from one while the record stayed five. HP changes exactly match:

```text
0.02 * 1.32 + 0.03 * 1.32 = 0.066
0.05 * 1.32 + 0.02 * 1.10 = 0.088
0.02 * 1.32 = 0.0264
0.015 * 1.32 = 0.0198
```

Flags `0x133` apply Sakura's offense `1.2` and Naruto's incoming multiplier
`1.1`; `0x122` applies only the latter here. Differing records and the third
hit's secondary event explain the nonuniform damage. The calculator has no
combo-scaling factor.

### Native combo owner

`NativeCombo.current`, `largest_completed` and the 90-count reset window are
separate from `Fighter.pending_combo_hits`, consumed by the update manager.
Ownership, retention and reset belong to
[Combo accounting](combo_accounting.md#resident-owner-and-update-order),
including [retention](combo_accounting.md#retention-and-reset) and
[pending updates](combo_accounting.md#explicit-and-pending-updates).

At a damage boundary the attacker's derived one-based index is:

```text
max(1, current + max(pending_combo_hits, 0))
```

Observed ordinary damage preceded pending consumption, seeing `(0,1)` through
`(4,1)`; third-hit contact damage followed it, seeing `(3,0)`. The formula gives
`1, 2, 3, 3, 4, 5`, assigning both third-hit events index three without a latch
or increment. Fresh post-reset calls saw `(0,1)` and index one. This observation
covers ordinary and `0.02` contact only; the calculator does not read the index.

### Native field contract

Raw instructions and live applied `Fighter`/`ComboScalingFighterView`
declarations agree on these accesses. `damage_calculate` loads opponent
at `0x00224E50`, offense at `0x00224E64`, durability at `0x00224E78`,
signed reservation tier at `0x00224F58`, and Handicap factors at
`0x00224FE8/0x00224FF0`. `combo_create` selects the side at
`0x0020C2A8`; `combo_consume_pending_hits` reads signed pending at
`0x0020C4FC/0x0020C558` and signed current at `0x0020C55C`.

| Object/member | Byte offset | Access |
| --- | ---: | --- |
| `Fighter.opponent` | `0x20` | Pointer |
| `Fighter.control_flags` | `0x60` | Byte; low bit selects side |
| `Fighter.staged_tier` | `0x80` | Signed halfword |
| `Fighter.offense / durability` | `0x148 / 0x14C` | Float32 |
| `Fighter.handicap_attack / handicap_defense` | `0x16C / 0x170` | Float32 |
| `Fighter.pending_combo_hits` | `0xA45` | Signed byte |
| `Fighter.side_damage_attributes` | `0xBB0` | Word |
| `Fighter.movement_flags` | `0xBB4` | Word |
| `Fighter.ceiling_damage_attributes` | `0xBBC` | Word |
| `NativeCombo.fighter` | `0x00` | Pointer |
| `NativeCombo.current / largest_completed` | `0x34 / 0x36` | Signed halfwords |

`combo_owners` is the resident two-pointer array at `0x006076B8`,
indexed with four-byte stride. It does not require a `battle_manager`
dereference. The current decompiler names the calculator fields correctly;
the earlier typed/raw disagreement is absent in this live check.
Agreement of these fields does not prove the complete fighter layout.

### Native damage calculation

`guard_response_init` and `response_apply_table_timing` resolve an attack,
read `ActionRecord.damage`, and divide by signed `repeat_count` when nonzero.
This is also the expected count copied to `Fighter.attack_repeat_countdown`,
so a multi-sample attack divides its authored total across samples. Both
calculate with `0x133` or `0x122` and pass the result to HP debit. Only the
guarded path first multiplies the raw sample by its guard factor.

BTL's constructed `InteractionRecord.attack_scalar` occupies the consumed
damage field. Construction belongs to [Collision](collision.md#definition-to-runtime-copy);
the source-definition field at the same offset is separate.

Resolution priority:

1. `Fighter.response_attack_record`.
2. `hit_source_record_get` on `response_source`, then `contact_attack_source`,
   each only with a nonnull pointer and nonzero `GenericNode.node_kind`.
3. `atk_dummy_record`: damage `0`, repeat `1`, row `0`.

The getter requires source marker `0x474F`. Kind 0 can return a source fighter's
`current_record` only in major 8; kind 1 uses `transient_record_get`; kind 2
uses `support_record_get` with a side argument. The consumers' nonzero-kind
fallback gate excludes the getter's fighter branch. Missing/unsupported results
use the dummy at the consumer boundary. Writers and provenance belong to
[Target selection](target_selection.md#accepted-hit-source-boundary).

### Calculator formula

`damage_calculate` (`0x00224E30`) takes raw normalized damage, defender and
flags. `defender.opponent` supplies the attacker. Factors apply in this order:

| Flag | Factor | Source |
| ---: | --- | --- |
| `0x001` | `attacker.offense` | Character offense |
| `0x002` | `m(defender.durability)`, then `1.5` when signed `staged_tier != 0` | Durability/reservation |
| `0x010` | `A = fighter_projectile_scalar(attacker)` | Attacker effects |
| `0x020` | `max(0.1, 2.0 - D)`, `D = effect_defense_factor(defender)` | Defender effects |
| `0x100` | `attacker.handicap_attack`, then `defender.handicap_defense` | Handicap |

Final damage is clamped to `[0.0, 1.0]`. Bits `0x004`, `0x008`, `0x040` and
`0x080` are unused. Native flag words are `0x133` (all factors), `0x122`
(durability/reservation, defender effects, Handicap), and `0x100` (Handicap
only); every bounded caller includes Handicap.

`staged_tier` is `1..3` during a staged chakra reservation and cleared on
release ([Chakra and guard](chakra_and_guard.md)). Holding it increases
flag-`0x2` damage by `1.5`; its player-facing name is not established here.

Both effect folds walk `effect_count` / `effects` via `GenericNode.next`,
including only nonzero `AwakeningEffectNode.lifetime`, even negative values:

```text
A = 1 + sum(attack_factor - 1), upper-capped at 2.0 when nonneutral
D = 1 + sum(defense_factor - 1), lower-capped at 0.25 when nonneutral
incoming effect factor = max(0.1, 2.0 - D)
```

Concurrent effects add deviations from `1.0`. Defense above `1.0` reduces
incoming damage; below `1.0` increases it. Incoming effect factor is bounded
`[0.1, 1.75]`; attack has no lower bound before the final clamp. Neither fold
tests controller marker, character ID or awakening class. Effect presence and
the controller marker are not interchangeable
([Effect 0x2E](../characters/awakening.md#exact-class-7-uj-entry)).
Effect-definition ownership is in
[Status effects](../projectiles_and_items/battle_items_and_status_effects.md#resident-effect-definitions).

### Arithmetic precision and clamp boundaries

Calculation uses ordered EE single-precision operations, with no integer HP
conversion, decimal rounding or minimum positive damage. The `[0,1]` clamp
applies per call before subtraction, not to a multi-event sum or remaining HP.

The upper durability coefficient is bits `0x3E4CCCCC`
(`0.19999998807907104`), rather than nearest decimal-`0.2` float `0x3E4CCCCD`.
Upper segments retain division/accumulator order. Reservation and the two
Handicap factors are separate subsequent multiplies; algebraic simplification
or precombining can change operation order. This alone does not establish every
hardware rounding result.

Sample division converts the signed repeat count to float. Zero bypasses it;
negative divisors are not rejected, and no remainder is allocated to the last
sample. Authored validity of all divisors is a separate data question.

Each application subtracts and stores HP separately. Practice's exact floor is
bits `0x3C23D70A` (`0.009999999776482582`). Outside Practice the zero check uses
stored HP even when `status_flags & 0x02` suppressed subtraction, so already-zero
HP can return knockout for zero damage. Counter/support notifications precede
subtraction and can include overkill or suppressed subtraction. They measure
calculated damage, not actual gauge loss.

### Damage-counter decimal conversion

`DamageCounter.current` retains percentage, `maximum` its maximum.
`damage_counter_add` ignores nonpositive additions and caps at `999.0`.
`damage_popup_set_value` stores `DamagePopup.percentage`, multiplies by `10.0`,
converts using the active EE FPU rounding mode, and extracts up to four `digits`.
The low digit is tenths; `digit_count` is at least two, including leading zero
below `1.0%`. No `+0.5` bias or decimal-rounded writeback affects percentage/HP.

The helper does not set rounding control. Boot FCSR and unknown later lifetime
belong to [Timer arithmetic limitations](../../runtime/timer_primitives.md#confidence-and-remaining-evidence-limits).
Conversion is not unconditionally truncation or round-to-nearest. Observed
`6.5%` for HP loss `0.066` shows displayed digits are not exact gauge loss.

### Handicap factors

`fighter_resource_settings_init` sets both Handicap fields to `1.0`.
`fighter_refresh_battle_settings` rewrites them during character setup and on
both live fighters after `battle_start_menu_update` closes with result 1.
`battle_handicap_get` returns key 8:

```text
s = h / 10        for side 0
s = 1 - h / 10    for side 1
f = s * 0.5 - 0.25
handicap_attack = 1 + f
handicap_defense = 1 - f
```

The signed setting applies only in Free Battle (mode 2); other modes return
neutral `5` ([Battle Settings](../modes/practice_mode.md#battle-settings-child)).
Neutral gives four factors `1.0`. At `h=10`, side-0 outgoing and side-1 incoming
are `1.25`; at `h=0`, both are `0.75`. Flag-`0x100` damage therefore gets
`1.5625` in the favored direction and `0.5625` in the opposite direction.

### Damage application

`fighter_apply_hp_debit` (`0x00225050`) orders work as follows:

1. `status_flags & 0x01` suppresses the entire call, returning 0.
2. Display enabled plus null `recovery_record` or category without bits
   `0x00100000`, `0x00200000`, `0x00400000` credits calculated damage times 100
   to the attacker's counter (opposite defender side).
3. `support_gauge_add` receives calculated damage before subtraction.
4. Practice mode 3 subtracts, floors results at or below `0.01` to that value,
   and always returns 0.
5. Other modes subtract only with `status_flags & 0x02` clear. Stored HP at or
   below zero is clamped to zero, clears `state_flags & 0x08`, and returns 1;
   otherwise returns 0.

The cleared life bit also admits ordinary damage, chakra gain and timed downed
recovery. Raw attacker-side support credit is separate: record consumers pass
their pre-calculator sample to `support_add_to_opponent`, crediting the defender's
paired fighter. Recipients, clamps, active-support gates and notifications belong
to [Support](../characters/support_mechanics.md#gauge-state-and-availability).

### Simultaneous hits and knockout boundaries

Application changes one fighter's HP/life bit and returns local knockout; it
neither latches match result nor prevents the other fighter's damage call.
Double-zero classification, first-result latch, timeout comparison and overrides
belong to [Match outcomes](../session/match_outcomes.md#terminal-detector-and-classifier).
Two damage events must finish before that detector for its double-zero case;
simultaneous input alone does not establish double knockout.

Paired arbitration's `hit_enter_trade` puts both fighters in ordinary response
`0x5B/0x5C` without directly calculating/subtracting damage.
`hit_retain_attack_record` supplies opposing records/expected repeats under its
repeated-record gate. Arbitration clears ordinary incoming/outgoing bits before
later `hit_classify_pair` branches, bypassing that helper's pending producer for
this pair; other producers remain possible
([Hit response](hit_response.md#rehit-suppression)).

Both ordinary consumers can then read opposing records. `0x5B/0x5C` have no
shared amount or averaging: each retains ordinary samples, flags, coordinator
and life gates. This is a static route, not a guarantee of both applications
on every simultaneous contact.

### Ordinary-hit damage gates

`response_apply_table_timing` applies HP damage only with:

- `state_flags & 0x08` set;
- `ActionRecord.category & 0x01000000` clear;
- `ActionRecord.flags & 0x02000000` clear;
- response outside `(5, 0x42..0x49)`, whose contact damage is separate;
- coordinator state other than 6;
- nonzero raw sample.

Flags are `0x133` only with `category & 0x000C0000 == 0` and nonzero `row`;
otherwise `0x122`. Category bits `0x40000`/`0x80000` or zero row therefore
exclude attacker offense/temporary attack factors.

### Guarded-hit damage

`guard_response_init` skips HP damage for category bit `0x01000000`; otherwise:

```text
base = 0.5 when ActionRecord.flags & 0x01000000, else 0
G = max(base, effect_guard_damage_maximum(attacker))
```

The effect fold returns maximum active nonzero-lifetime `payload_90` from zero.
Zero `G` means no guard damage. Otherwise raw sample is credited to attacker-side
support before coordinator/raw-zero gates; `G * raw_sample` is calculated with
`0x133` for `category & 0x000C0000 == 0`, else `0x122`. There is no row gate.
Blocked ordinary attacks need the static half-chip flag or guard-damage effect,
with the larger selected. Support credit excludes `G`. Guard statistics update
independently of HP ([Hit count](hit_response.md#hit-count)). Flag `0x01000000`
in `ActionRecord.flags` is the static half-chip selector.

### Damage caller coverage

An exact direct-`jal` byte search finds ten physical resident calls to
`damage_calculate`. Two mirrored address sets in the ELF analysis repeat
those same bytes; they are not additional native call sites.
BTL/ETC have no direct calculator or HP-debit calls. BTL reaches the calculator
through one `damage_apply_direct` and fifteen `hit_retain_source` calls;
ETC has no direct calls to either wrapper. These are direct-call bounds,
not an exclusion of indirect dispatch or undiscovered code.

| Calculator boundary | Owner | Raw / flags | Adjacent consequence |
| --- | --- | --- | --- |
| `damage_direct_calculate_call` `0x0022529C` | `damage_apply_direct` | Caller raw/flags | HP debit at `0x002252B0` |
| `damage_cinematic_calculate_call` `0x002252F4` | `damage_apply_cinematic` | Cinematic raw / `0x100` | HP debit at `0x00225308` |
| `combo_scaling_guard_damage_call` `0x00228D18` | `guard_response_init` | `G * record sample` / `0x133` or `0x122` | HP debit at `0x00228D2C` |
| `combo_scaling_contact_damage_004_call` `0x00231634` | `response_contact_enter` | `0.04` / `0x122` | HP debit at `0x00231648` |
| `combo_scaling_contact_damage_002_call` `0x00231698` | `response_contact_enter` | `0.02` / `0x122` | HP debit at `0x002316AC` |
| `damage_source_calculate_call` `0x002334BC` | `hit_retain_source` | Explicit raw / `0x122` | HP debit at `0x002334D0` |
| `combo_scaling_ordinary_damage_call` `0x00234A80` | `response_apply_table_timing` | Record sample / `0x133` or `0x122` | HP debit at `0x00234A94` |
| `damage_downed_calculate_call` `0x00236354` | `downed_motion_update` | Fixed `0.05` / `0x122` | HP debit at `0x00236368` |
| `damage_post_cinematic_calculate_call` `0x0024F00C` | `jutsu_post_cinematic_update` | Zero / `0x100` | HP debit at `0x0024F020` |
| `damage_cinematic_counter_calculate_call` `0x0035B2F8` | `sp_skill_play_end` | Contest total / `0x100` | Counter only; result times 100 |

The ten physical direct HP-debit calls are the nine HP rows above plus
`damage_effect_hp_debit_call` at `0x003061F8` inside
`effect_apply_hp_contribution`. That call supplies negative delta's magnitude
with display disabled and bypasses calculation. The cinematic counter-only
row has no adjacent HP debit.

The fixed `0.05` row requires downed substate `0x61`, primary event zero
and coordinator other than six. Its self/`atk_dummy_record` recovery
provenance gates are independent of damage; the fixed amount is not sampled
from an accepted attack record.

#### Source categories and paths

Record-response and direct damage are separate routes. The ordinary/guarded
consumers' resolution priority admits retained records, transient-object
records and opposite-side support records through
`hit_source_record_get`; there is no normal-attack-only predicate.
`ActionRecord.category & 0x000C0000` changes calculator flags, not source
identity or exclusive ownership of a call site.

| Source/effect | Established route | Limit |
| --- | --- | --- |
| Fighter and support attack records; admitted transient overrides | Ordinary response consumer; guarded consumer when admitted | Default projectile records suppress HP sampling and contain zero damage |
| Generic object contact | `transient_actor_lineage_notify` to `damage_apply_direct` with `0x122` | Direct amount precedes optional pending publication |
| BTL skill-owned explicit amounts | Fifteen `hit_retain_source` calls below | Record provenance is shared; raw amount and combo accounting are caller-owned |
| Ultimate Jutsu cinematic fractions | `damage_apply_cinematic` with `0x100` | Completion also has counter-only and zero-raw calls |
| Signed effect HP contribution | HP add or display-disabled debit, bypassing calculator | This establishes the signed path, not every item/status identity |
| Contact environment and fixed downed event | Fixed `0.02/0.04` contact or `0.05` downed path | Separate from ordinary record sampling |

Throws, projectiles, Jutsu and supports are player/source categories rather
than exclusive calculator branches. Complete per-move attribution remains
open where the source/class/action joins are unestablished. The direct-call
inventory is complete within its search bound; it does not establish every
indirect route or ordinary-play execution.

#### Ordinary object and support attribution

The source getter's kind-1 branch does not establish ordinary projectile HP
damage. All 182 default projectile response records have category
`0x01000000`, damage `0`, repeat count `1` and row `0`. The bounded
private-record/callback census finds response edits but no nonzero ordinary
raw producer, including Chase's category-clearing override. Their construction,
copy ownership and search limits belong to
[Projectile lifecycle](../projectiles_and_items/projectiles.md#response-records-and-damage-ownership).

Support records are different. Their initializer sets category `0x08000000`,
repeat `1` and row `0`; script opcode `6` writes a positive authored damage
expression for the checked `new1` and `ymt1` resources. These records can
reach ordinary `0x00234A80` when the ordinary gates admit them, using
calculator flags `0x122`. The getter chooses the receiving fighter's
opposite-side record, and mode-2 accepted-hit counting credits
`receiver.opponent`, not the support object or its identifier.
[Support mechanics](../characters/support_mechanics.md#authored-support-damage-records)
owns the raw inputs and shared current/retained record lifetime.

`hit_route_accepted` (`0x002209A0`) produces mode-2 marker `1` for an
ordinary hit, `-1` for a guarded hit and `-2` for interception. The enabled
`hit_paired_marker_consume` (`0x00233540`) admits markers outside
`0/-1/-2`, notifies the opposite-side support first, then adds one to
`receiver.opponent.pending_combo_hits` at `0x002335CC`. Notification
deduplication does not suppress that increment. The ordinary initializer
at `0x00220E10` precedes the enabled consume call at `0x00220E20`, but
does not apply ordinary damage synchronously. That amount is sampled later
by the event-zero call at `0x00234DD4` in `response_update_ordinary`.

The checked resident order is maintenance, collision arbitration/routing,
then the eligible unpaused action dispatcher in `fighters_update`
(`0x0024FD80`). Its route calls at `0x0024FF9C/0x0024FFBC/0x0024FFDC`
precede `fighter_dispatch_action_update` at `0x0025014C`. Ordinary sampling
can therefore follow accepted pending publication in that local pass.
Neither the router nor the ordinary damage event flushes `NativeCombo`.
The later graph-phase timeline callback can consume both side owners at
`0x0024DEB0`, under its own gates. Native pending clearing, consumption and
retention belong to [Combo accounting](combo_accounting.md#explicit-and-pending-updates).
This is checked call order, not a measured universal frame cadence or a
guarantee that pending remains positive at every later damage event.

Generic projectile contact uses the separate raw scalar path described in
[Generic wrapper](#generic-wrapper). `transient_actor_lineage_notify`
(`0x0072E740`) applies its optional direct amount at `0x0072E7F0` before
the `+0x34` callback at `0x0072E824`. The latter requires the contacted
fighter's guard state to be exactly `0`, even though the ordinary router
uses a less-than-`1` test. All 95 final projectile factory vtables retain
`projectile_response34` (`0x007305A0`): unless
`combo_publication_suppressed == 1`, a nonnull primary fighter selected by
`(contacted.control_flags & 1) ^ 1` receives pending `+1` at `0x007305D8`.
Neither routine flushes native counts. Mode-1 routing invokes this path
before its ordinary response initializer; the default record then supplies
no ordinary HP amount.

Direct damage and pending publication have independent gates. A zero scalar
can still publish a count; nonzero guard or the exact suppression flag can
leave direct damage without that count. Support notification, lineage-key
deduplication and the child/affiliation gates run after `+0x34`; they do not
move or suppress its earlier increment. Their token/statistic bookkeeping
must not be used as native combo hit multiplicity.

Representative checked sources separate config identity from player move
identity. TEN001 emits config `0x17` (`ccProjectileHoming`), INO001 emits
`0x19` (`ccProjectileStraight`), and KNK000's selected schedule emits
`0x0C` (`ccProjectileParabola`). A parent's support tag/identifier can
survive into descendants without retaining a support pointer; the two
support emitters snapshot their current support raw into `config_scalar`.
Those origins retain the generic direct/count ordering rather than gaining
ordinary support sampling. The class, external ID, numeric side and lineage
token are separate identities; none alone proves a named player action or
the native damage attacker.

`damage_calculate` always derives its attacker from `defender.opponent`.
**Inference:** For an admitted generic contact that will publish a new count, the new
contribution is not yet in either current or pending at its raw boundary.
Its prospective slot is therefore existing current plus positive existing
pending plus one, provided the selected primary fighter, paired attacker
and `NativeCombo.fighter` agree, signed accounting has not wrapped, and no
reset intervenes. Retail damage does not compute this index. The relationship
does not apply to a direct amount whose later publication gates fail. A numeric tier for
arbitrary contact sequences, aliased sources or every item/support/Jutsu
remains outside this bounded attribution.

### Contact damage

`response_contact_enter` selects fixed damage by response/environment:

| Response | `0x400` attribute source | Raw when set | Otherwise |
| --- | --- | ---: | ---: |
| `0x42/0x43` | `side_damage_attributes` at `+0xBB0` | `0.04` | `0.02` |
| `0x44` | `ceiling_damage_attributes` at `+0xBBC` | `0.04` | `0.02` |
| `0x45..0x47` | `movement_flags` at `+0xBB4` (current ground) | `0.04` | `0.02` |
| `0x48/0x49` | none | — | `0.02` |

Both amounts use `0x122`: float32 raw bits `0x3D23D70A` and
`0x3CA3D70A`. At `0x002315C8..0x002315FC`, the outer gate reads
`battle_hub->fighters->state`, treating either missing pointer as zero,
and skips damage for any nonzero state. Each amount then separately requires
`fighter_coordinator_get_state() != 6`. That getter returns `-1` for
missing pointers, so absence does not reject these local gates.
There is no attack-record damage/category, repeat-count or pending-hit check
in these fixed-amount branches.

The `0.04` branch additionally calls
`battle_field_notify_background_contact` (`0x00708F90`) when
`fighter.field` is nonnull, even if its second coordinator gate skipped
damage. The wrapper loads `BattleField.background` at `+0x70`;
a nonnull child reaches `bg_contact_noop` (`0x006C2E00`).
Its complete `move v0,zero; jr ra; nop` body returns zero with no side
effect. This inspected retail call does not introduce additional damage.

Observed third-hit damage began while Naruto was `(5,0x3D)` and reached
`(5,0x43)`, consistent with launch/contact promotion
([Response exits](hit_response.md#response-exits)). Its `0.022` applied
damage is separate from the main event, not another accepted hit.
No visual name such as wall splat is established; `0.04` is unobserved.

Among 24 retail stage archives, only `S08.CCS` (load slot 7, logical stage 8)
has authored `0x400` triangles: two in group 2 of `HIT_s08are00_hit_s3`,
word `0x00959595`, vertices spanning approximately
`x=-824..-713`, `y=736..923`, `z=1059..1124`.
Bootstrap `S07.CCS` (load slot 6) has none and cannot provide the
prerequisite through authored geometry
([Stage distribution](../stages/stage_surface_attributes.md#stage-authored-attribute-distribution)).

The historical stage-only `S08` control exposed 395 active primitives,
including two `0x40959595` flags (authored bits plus orientation).
The unchanged movie remained in the lower side-0 region rather than the
upper side-1 area near components `(800,1030)`; no checkpoint had the
required response/attribute, and the `0.04` call count stayed zero.
The `S07` walk found 1,125 active primitives with no `0x400` flag.
These observations establish resource availability and coverage bounds,
without contradicting the statically established branch.

## Direct-damage wrappers and character exceptions

Direct damage has a different raw boundary from record sampling. Bounded BTL
paths enter through `damage_apply_direct` or `hit_retain_source`; ETC has no
direct calls to either. Direct-call searches do not bound indirect or
undiscovered code.

### Direct signed HP adjustment from effects

`effect_apply_hp_contribution` bypasses calculation. It requires
`status_flags & 0x01` clear, `fighter_restore_gate_b == 0`, and
`fighter_resource_contribution_blocked == 0` on both fighters. Exact bound
`-1.0` skips adjustment. Otherwise positive delta shortens toward the upper
bound without lowering HP; negative shortens toward the lower without raising
HP. Zero is a no-op. Positive uses HP add; negative HP debit disables display
and ignores knockout return.

No offense, durability, reservation, temporary damage factor, Handicap or
calculator clamp applies. Application still supplies support notification and
Practice/ordinary HP rules. Entry/expiry payloads and bounds belong to
[Effect definitions](../projectiles_and_items/battle_items_and_status_effects.md#definition-table);
the signed-HP role does not establish every item/status name.

### Generic wrapper

`damage_apply_direct` returns zero for coordinator 6 or raw zero; otherwise it
calculates with supplied flags and returns display-enabled HP debit's knockout.
It does not resolve records or increment pending combo hits.

Rock Lee's `rock_lee_channel3` extra event requires ID `0x43`, major 8, action
`0x33`, phase 0, secondary event `0xF` after event `0xE` is absent. It uses
`hit_consume_attack_damage` with `0x133`, preserving raw support credit.
Sasori/Hiruko's `sasori_hiruko_hit_response` uses ID `0x4C`, major 8, action
`0x17`, phase 1, raw `0.004` (bits `0x3B83126F`), `0x133`, and response `0x3D`;
it bypasses the raw-sample helper. These identify characters, not move names.

BTL's `transient_actor_lineage_notify` object-hit path requires
`battle_active_object` nonzero. That returns a global object's word `+0x20`
or zero for a null global; the word's gameplay meaning remains open.
A registered kind-1 `Projectile` supplies `config_scalar * incoming_magnitude`,
halved for nonzero incoming selector, with `0x122`; `config_index == 0x31`
forces zero. `transient_object_damage_get` returns the scalar only with manager
list membership, without item-code lookup. `external_id` is used for later
[Hit-carried effects](../projectiles_and_items/battle_items_and_status_effects.md#direct-effect-records-carried-by-hit-objects).

### Source-retaining wrapper

`hit_retain_source` (`0x002333A0`) receives raw damage, struck fighter, source
and retained record. Nonnull marker-`0x474F` source can replace
`recovery_source` / `recovery_record` and save `recovery_grounded`, when
`fighter_status_suppressed` and `context_mode_word` are zero. Kind 0 retains
the source pointer; others copy it into `embedded_node` via `hit_source_copy`.

Failing provenance gates does not prevent independent damage: coordinator
other than 6 and nonzero raw calculate with `0x122`, display enabled. Clear life
bit ends the exchange on both fighters. There is no native combo increment or
ordinary response initializer; callers choose source, record and amount
independently ([Accepted-hit routing](hit_response.md#accepted-hit-routing)).

### All fifteen BTL source-retaining calls

Bounded paths retain `shared_skill_damage_record` (`0x008DAA10`) and use
`target.opponent` as source. The record's own damage is zero; explicit raw is
separate. Raw comes from active interaction records, linked current records,
shared float data, guard-sensitive stored amounts or FOR/ANB arithmetic.
Class/action joins and contribution ordering are documented below.

| Direct call | Owner | Explicit raw source |
| --- | --- | --- |
| `damage_skill_primary_record_call` `0x007898D0` | `skill_primary_submit_record` | Supplied `InteractionRecord.attack_scalar` for response selector `0x28` |
| `damage_skill_shared_float_a_call` `0x0079FF08` | `skill_shared_float_damage_a` | `shared_skill_damage` |
| `damage_skill_tyo_record_call` `0x007A5078` | `skill_tyo000b_damage` | Active `InteractionRecord.attack_scalar` |
| `damage_skill_two_route_half_call` `0x007AFE64` | `skill_two_route_flush` | Auxiliary `direct_damage * 0.5`, nonzero guard |
| `damage_skill_two_route_full_call` `0x007AFF28` | `skill_two_route_flush` | Auxiliary `direct_damage`, zero guard |
| `damage_skill_route_half_call` `0x007B0A54` | `skill_route_flush` | Auxiliary `direct_damage * 0.5`, nonzero guard |
| `damage_downed_override_b_record_call` `0x007C2E88` | `downed_override_b` | Active `InteractionRecord.attack_scalar` |
| `damage_skill_contact_record_call` `0x007CDC6C` | `skill_contact_flush` | Linked fighter `current_record.damage` |
| `damage_skill_shared_float_b_call` `0x007D45B8` | `skill_shared_float_damage_b` | `shared_skill_damage` |
| `damage_downed_override_e_record_call` `0x007D5008` | `downed_override_e` | Active `InteractionRecord.attack_scalar` |
| `damage_skill_auxiliary_record_call` `0x007D80CC` | `skill_auxiliary_flush` | Linked fighter `current_record.damage` |
| `damage_skill_delayed_record_call` `0x007DCF30` | `skill_delayed_flush` | Linked fighter `current_record.damage`; separate emitted record uses descriptor scaling |
| `damage_skill_for_primary_call` `0x00805250` | `skill_for000_update` | Primary cumulative-state formula below |
| `damage_skill_for_secondary_call` `0x00805340` | `skill_for000_update` | Secondary damage snapshot |
| `damage_skill_anb_half_call` `0x00808544` | `skill_anb000_damage` | Descriptor guard multiplier times linked record damage times `0.5` |

All fifteen pass target, target's `opponent` and the shared record separately.
Common wrapper flags are `0x122`; no call uses the shared record's zero
damage field as its explicit amount. The callers' local guards and count
ordering are summarized below and retained in their annotations.

Every `interaction_manager_init` resets this BSS record through
`interaction_record_init`, then sets category `0x00040000` and response/guard
selectors `0xFF`. Defaults include damage `0`, repeat `1`, row `0`. Reset is
not confined to overlay BSS clearing. Owner lifetime belongs to
[Skill services](../session/battle_auxiliary_services.md#btl-skill-service-callbacks-and-ownership).

File-backed `shared_skill_damage` (`0x008CC490`) starts at zero. Ninth automatic
constructor `btl_initialize_remaining_globals` sets `0.03 / 23` (approximately
`0.00130434777`), before `0x122` factors. It is not recomputed per skill/owner
teardown ([Constructor ordering](../../runtime/overlay_abi.md#constructor-interval)).
`interaction_manager_destruct` writes neither shared value. Exact-address
bounds find only the record reset and raw-float initialization writer; arbitrary
aliases/external writes remain open.

#### Fighter-held aliases of the shared record

`recovery_record` aliases shared storage; no record/damage copy occurs.
`embedded_node` is a source-object copy. Skill destruction and fighter-pointer
replacement are separate ([Recovery-source lifetime](hit_response.md#input-recoveries)).
Inspected resident readers test flags, dummy-drop identity or nonnullness without
writing through the retained pointer.

BTL `skill_retained_record_teardown_a` and `skill_retained_record_teardown_b`
inspect category `0x000F0000` after
linked-fighter, registry and target-state gates, then can invoke an auxiliary
callback without passing, mutating or freeing the record. Shared `0x00040000`
satisfies the mask if retained; execution is unestablished. Computed field
addresses and arbitrary aliases remain outside the bound.

#### Shared wrapper and combo-call contracts

Primary damage requires `CollisionSkillPrimary.damage_target_valid` and
`downed_override_allowed(damage_target)`. Linked-current reads use
`entity_link_valid` and that predicate on `entity`. The predicate checks only
argument/global nonnullness, with no dereference or marker validation. Some
decompiler success branches are lost through an incorrect nonreturn inference;
annotations retain instruction-based bounds.

Accumulated contribution is flushed before optional damage, then cleared.
Primary and auxiliary objects use their own `manager` / `side`
([Accumulated contribution](combo_accounting.md#per-side-accumulated-contribution-route);
[Metric publication](../session/battle_statistics.md#accepted-ninjutsu-and-combo-flushing)).
Shared-float helpers order flush, optional damage, then
`combo_add_pending(primary_fighter, 1)`. This increment is outside the wrapper
and queues no response request or `hit_route_accepted` call
([Primary aliases](../session/battle_entities.md#manager-allocation-and-alias-slots);
[Pending producers](combo_accounting.md#other-direct-byte-producers)).

The two floor-fire helpers' distinct guard subjects and counted/timed routes
belong to [Specialized skill amounts](#specialized-skill-amounts-and-counted-tier).
Their `0x122` half amounts are independent of ordinary chip factor `G`.

#### Shared-float event count and categories

**Observation:** `CollisionSkillPrimary.damage_event_source` (`+0x144`)
and `damage_event_count` (`+0x14A`) are the same storage viewed as
`SharedBindingInputReader.input_event` and unsigned `pending_input_events`.
`skill_update_input_contributions` (`0x00796880`) produces that count on
`binding1_shared_press_a` success; it counts input events, not collisions.
Its age, wrapping and configured-binding rules belong to
[the shared input producer](combo_accounting.md#shared-input-producer-of-the-contribution-gate).
The inherited `skill_primary_input_callback` (`0x007950D0`) calls it after
ordinary virtual work, while `transfer_blocked` skips that route.

`skill_shared_float_damage_a` (`0x0079FDC0`) and
`skill_shared_float_damage_b` (`0x007D4470`) require a nonnull input source
and unsigned count converted to float at least `1.0`. Each clears the
**whole** count, flushes a positive `InteractionManager.pending_combo_hits`
word into the side's native current and clears that word, optionally supplies
`shared_skill_damage` to `hit_retain_source`, then publishes exactly one
`combo_add_pending(primary_fighter, 1)`. A count greater than one still produces
at most one optional fixed raw contribution and exactly one pending hit;
neither is multiplied by the input count. The `23.0` divisor does not establish
23 delivered contributions.

**Observation:** Authored resource/action joins and class gates identify
Naruto's **Great Ball Rasengan** (metadata owner 57, action 3) and Jiraiya's
**Rasengan** (metadata owner 83, action 3) on the enabled input-source routes.
Configured Jutsu selection can replace a fighter's working records, so the
metadata owner does not restrict the performing fighter's identity.
Classic Naruto's Rasengan, Nine-Tailed Naruto's `朱い螺旋丸`, and The Yellow
Flash's Rasengan
share or inherit these methods but leave their input-enable flag zero.
This bounds the inspected source path; it does not assert that arbitrary
aliases cannot supply a source. Exact records, factory arms, authored spawn
events and disabled legacy resource 28 belong to
[Shared-float caller classes](../session/battle_entities.md#shared-float-caller-classes).
The joined action records have Jutsu category `0x00080000`; this establishes
these Jutsu amounts, without attributing throws or every Jutsu to this route.

Helper A runs from `skill_nrt_nrw_update` (`0x0079DFE0`) when signed short
`actor +0x5E4 == 3`; its other caller,
`skill_auxiliary_register_ascending_call` (`0x0079F5F0`), uses the complementary
short condition and nonzero byte `+0x1170`. Helper B runs from
`skill_nrv_jrw_damage` (`0x007D0A50`) with that short equal to 3, or
`skill_nrv_jrw_interaction_update` (`0x007D11F0`) with it unequal to 3 and
byte `+0x1134` nonzero. The short's wider state meaning and actual cadence
are not established by these comparisons.

The optional raw calls are `damage_skill_shared_float_a_call`
(`0x0079FF08`) and `damage_skill_shared_float_b_call` (`0x007D45B8`).
The new pending publication follows at `0x0079FF28` / `0x007D45D8`, even if
target validity or the wrapper's damage gates suppress the amount.
Damage's source is `target.opponent`; publication instead resolves the primary
fighter from `actor.side`. The authored bridge supplies fighter/opponent,
and `skill_bind_fighter_header` (`0x00793650`) binds them to the two headers;
the damage helpers do not check that `target.opponent` is still the primary.

**Inference, high confidence:** When those identities and the combo owner
agree, and signed fighter-pending accounting has not wrapped, the contribution
being published belongs to the next one-based slot:

```text
new_contribution_index = max(1, current_after_flush + max(existing_fighter_pending, 0) + 1)
```

This is an attribution derived from ordering, not an index computed by retail
damage code. Ordinary `current + pending` at the raw boundary omits this new
event: with `(current,pending) = (3,0)`, it gives 3 while the new contribution
is 4. The input count must not replace the final `+1`. A source/primary/owner
mismatch, signed-byte overflow, or reset/interruption prevents treating that
algebra as an unconditional contract. Frame cadence, total contributions and
later alias writes remain outside the static result.

#### Inherited primary-record categories and tier

**Observation:** `skill_primary_submit_record` (`0x00789630`) is shared
base behavior, reached through `skill_combo_submit_record`
(`0x007984A0`) by all 21 counted response-`0x28` resource definitions.
The exact class, metadata owner, action, display and resource joins belong to
[Battle entities](../session/battle_entities.md#inherited-primary-record-caller-classes).
Twenty have shipped named action metadata; resource 23 has no selected
classic Orochimaru record. These are Jutsu action 1/3 categories
`0x00040000/0x00080000`, including auxiliary metadata 30/31, rather than
a throw-only or one-class boundary.

The response-`0x28` branch reads the supplied
`InteractionRecord.attack_scalar`, flushes a positive side manager word
through `combo_add_side_hits`, clears the word, then calls
`hit_retain_source` at `0x007898D0`. It does not itself publish a new
combo hit. Before this branch, the resource filename's byte 7 selects an
OR of category `0x00040000` for `cha0`, otherwise `0x00080000`.
The independently retained shared record's fixed `0x00040000` category
does not identify the originating move.

Common descriptor construction multiplies definition `attack_scalar`
by linked fighter `current_record.damage`; sample update can divide it
by the signed repeat count before submission. All response-28 definitions
have multiplier `1.0` except TEN resource 35, whose multiplier is zero. Its custom
emitter therefore supplies zero at the inherited boundary on the joined
retail record, then applies its separate current-record amount below.
`ccSkillNEW000` resource 132's response-28 definition is index 1/repeat 12;
the other response-28 definitions use index 0/repeat 1. An authored repeat is
not proof of accepted contribution totals. Positive linked-target guard can
additionally halve a supplied scalar only under the existing
`0x800000` flag/component gate.

**Observation:** The two common update-form branches in
`skill_primary_update_descriptor` (`0x00788C20`) call slot `+0x194`
before `skill_primary_accept_event` (`0x00787A50`). The latter's
zero-guard branch adds exactly one to the side manager word and immediately
flushes it; its guarded branch does not add that contribution. This gives a
concrete path whose current contribution is not yet counted at the raw
boundary. In contrast, custom `+0x260` emitters reconstruct a descriptor
and submit it after earlier authored-event contributions, without a new count
in the emitter. The helper's local flush does not distinguish these origins.

**Inference:** Let `C` be actual native current after the helper's flush
and `P` the existing signed fighter pending byte. For a confirmed subsequent
zero-guard accepted contribution from the common updater, next-slot attribution
is `max(1, C + max(P, 0) + 1)`. For an emitter consuming already counted
events, last-counted-slot attribution is `max(1, C + max(P, 0))`.
Neither expression is a retail damage calculation or an unconditional
contract for all 21 resources. Ownership must agree among actor side,
`target.opponent`, the side's primary fighter and `NativeCombo.fighter`;
reset, setter rejection and signed count wrapping limit the attribution.

#### Specialized skill amounts and counted tier

**Observation:** The seven remaining explicit amounts join to five action-1
Jutsu origins, category `0x00040000`. The two HKG floor-fire classes
share Third Hokage's originating action. Exact action/class/factory joins belong to
[Battle entities](../session/battle_entities.md#specialized-source-retaining-caller-classes).

| Explicit boundary | Class / originating move | Raw and admission | Count at boundary |
| --- | --- | --- | --- |
| `0x007AFE64` / `0x007AFF28` | `ccSkillHKG000FloorFire`, `火遁・火龍炎弾` | Stored amount times `0.5` with nonzero linked-victim guard, full with zero guard | Accepted auxiliary contribution is already flushed on the established full route |
| `0x007B0A54` | `ccSkillHKG000FloorFire2`, same action | Stored amount times `0.5` when a selected **same-side fighter** has nonzero guard; damaged linked victim is separate | Timed callback adds no local hit |
| `0x007C2E88` | `ccSkillSSK000A`, `無双豪炎弾` | Active interaction scalar under linked-target gates | Finish follows earlier authored-event counts; adds no new pending hit |
| `0x007CDC6C` | `ccSkillKMM000`, `茨` | Linked source fighter's current-record damage under source/target gates | Same finish/count ordering |
| `0x007D5008` | `ccSkillSSV000`, `無双豪風陣` | Active interaction scalar under linked-target gates | Same finish/count ordering |
| `0x007DCF30` | `ccSkillTEN000B`, `双燕刈` | Linked source current-record damage after separate zero-raw descriptor emit | Custom second-header callback adds no local hit |

HKG damage is a snapshot: `skill_hkg000_update` reads current-record
damage at `0x007B2480`, stores `FireGen +0xE04` at `0x007B2484`,
and the floor-fire constructors copy it into their `+0xB20` amount.
Later changes to the source current record do not update these copied amounts.

`skill_auxiliary_accept_credit` (`0x0077FE60`) admits an ordinary
zero-guard event, sets auxiliary outcome mask `0x1`, and adds exactly one to
the side manager pending word at `0x0077FF20`. A positive incremented word
calls `combo_add_side_hits` at `0x0077FF60`, then clears the word before
the `+0x30` callback.
The one-time Ninjutsu metric gates do not suppress this native contribution.
`skill_two_route_contact_update` (`0x007AFB40`) requires that bit and
`+0xB30`, then calls the helper on the same linked victim.
Its intervening `skill_auxiliary_scale_target_motion` writes motion
fields, with no guard/count write. This bounded synchronous chain establishes
the full `0x007AFF28` route after its event's count. The half instruction
exists, but no admitted guard transition or alternate caller establishes it
within this chain; arbitrary aliased writes remain outside coverage.

`skill_route_timed_contact_update` (`0x007B05C0`) instead resolves its
guard subject with `skill_route_select_same_side_fighter`
(`0x007B0C20`). That subject's side matches the actor's side; the raw
wrapper still damages the actor's separate linked target. Its nonzero-guard
half amount is therefore not evidence of chip damage to that victim.

For SSK/SSV/KMM/TEN, admitted authored events reach
`skill_combo_accepted_event` (`0x0079BAB0`): event value other than 10
adds one to the manager pending word at `0x0079BC5C`; event 10 instead
sets finish byte `+0x10B8` at `0x0079BB54` without a count increment.
`skill_combo_phase3` (`0x0079B4F0`) clears the byte, then invokes
`+0x24C` for SSK/SSV/KMM. TEN's `+0x11C` interaction update invokes
`+0x260` through its second-header/latch gate; the later local
`+0x10C4` increment is not a native combo hit.

Read-only complete nested-animation walks establish authored SSK
`ANM_psskcha01` has 24 nonterminal commands before finish event 10 at
marker 165; SSV `ANM_pssvcha01` has two before finish at marker 153.
Their spawn commands select resources 2/88. These are authored command
counts, not guaranteed observed or native boundary totals: relay admission,
interruption, flush/reset ordering and owner gates still apply.

The SSK/SSV finish callbacks read the active interaction record's scalar,
not `ActionRecord.damage` directly. Their first definitions
(`0x008A8314` / `0x008AA7BC`) have category `0x00040000` and multiplier
`1.0`; each remaining three-row set has category `0x00080000` and multiplier
zero (`0x008A8358/0x008A839C/0x008A83E0` and
`0x008AA800/0x008AA844/0x008AA888`). An explicit amount of `0.125`
therefore requires the first definition to be active. These callbacks alone
do not establish that identity.

All seven explicit instructions see actual native current **after** any
positive manager-word flush; a flushed word is cleared and no new fighter
pending increment follows in the inspected route. Under matching ownership
and valid native accounting, their last-counted-slot attribution is:

```text
max(1, current_after_flush + max(existing_fighter_pending, 0))
```

This is an inference for assigning a final or timed amount to an existing
slot. Retail reads no combo tier for these amounts and does not apportion a
final lump across the earlier event slots. Actual numeric tuples depend on
prior state; a design could choose a different treatment for an aggregate
amount without changing these observed ordering facts.

#### Known class source categories and hit tiers

**Observation:** TYO joins Classic Choji's **曇撫離投げ**, FIR joins
The First Hokage's **木遁・森羅万象**, and ANB resources 3/89/143 join
Classic Sasuke's **千鳥**, Second Stage Sasuke's **黒い千鳥**, and
Kakashi's **雷切**. These are Jutsu action 1/3 categories
`0x00040000/0x00080000`; a throw in a move name does not establish an
ordinary throw route. Exact action/resource/factory and authored startup
joins belong to [Battle entities](../session/battle_entities.md#ccskilltyo000b).
FOR resource 22, ANB resource 11 and ANB resource 53 have no verified
active NA2 move: the first two map only to filler definitions, and the
third is absent from the complete selector map. Their retained code must
not be attributed to an active retail character from the filename alone.

| Explicit boundary | Count ordering established on the joined route |
| --- | --- |
| TYO `0x007A5078` | Unguarded accepted event is incremented and flushed before slot `+0x1A0`; guarded acceptance contributes no new hit |
| FIR `0x007D80CC` | Terminal event 10 contributes no hit; final slot `+0x24C` flushes any prior positive manager word before raw |
| FOR primary `0x00805250` and secondary `0x00805340` | Unguarded entry follows its accepted count; update amounts flush existing words without a new hit publication |
| ANB half `0x00808544` | Unguarded response `(5,0x4F)` can follow the already-counted accepted event; positive-guard acceptance adds no new hit |

None of these five raw instructions publishes a later fighter-pending `+1`.
**Inference:** For a confirmed already-counted contribution, matching actor
side, `target.opponent`, side primary fighter and `NativeCombo.fighter`,
with valid signed accounting and no reset between them, the existing-slot
attribution is:

```text
max(1, current_after_flush + max(existing_fighter_pending, 0))
```

This attributes an amount to actual counted state; retail calculates no
combo tier. Guarded contributions have no new slot of their own. Whether
they use an existing slot is a scaling-scope decision. A final lump can
likewise be assigned to the last counted slot, but native code does not
divide it among earlier slots. No numeric tier follows from a class name,
an authored marker or a damage-update counter.

##### TYO sample and accepted contribution

`skill_tyo000b_damage` (`0x007A4F00`) reads the active interaction record's
scalar at `0x007A4FB4/0x007A4FB8` when `damage_ready` is nonzero.
The common descriptor builder multiplies definition `+0x28` by valid linked
fighter `current_record.damage`, saves the result at header `+0x238`, and
retains the original repeat count. Common form-0 updating divides that saved
amount by the signed repeat and writes the active record before submission.
Resource 31 initially selects definition 0, multiplier `1.0` and repeat 1;
its second definition has multiplier zero and repeat 1. Thus the active
record producer is established, without assuming every later alias selects
the first definition.

The common zero-guard accepted producer has already incremented/flushed its
contribution before dispatching this class's slot `+0x1A0`. TYO clears any
remaining manager word at `0x007A5038`, then applies raw at `0x007A5078`.
Adding another `+1` there would advance the ordinary accepted event twice.
The guarded branch still admits the callback but supplies no new count.
Further internal animation commands do not prove total move contributions.

##### FIR terminal amount

`fir000_vtable` (`0x005F2C20`) slot `+0x24C` at `0x005F2E6C`
holds `skill_auxiliary_flush` (`0x007D7FB0`). It reads linked-current
record damage at `0x007D800C`, flushes a positive side manager word through
`combo_add_side_hits` at `0x007D8044`, clears it at `0x007D808C`, then
passes the explicit amount to `hit_retain_source` at `0x007D80CC`.
The shared retained record's zero damage is separate.

The inherited terminal callback sets the finish latch without counting event
10; `skill_combo_phase3` clears the latch before slot `+0x24C`.
The shipped main animation contains only terminal event 10 at marker 115,
with no nonterminal authored count events. The common accepted-contact
route can previously count an unguarded contact, but FIR's slot `+0x1A0`
is `skill_primary_accepted_callback_noop`. Actual prior contact admission,
reset/retention and numeric tier remain unestablished; neither tier one nor
a 115-hit sequence follows from this static join.

##### FOR and ANB accepted callbacks

FOR's authored-event slot `+0x13C` is
`skill_primary_event_callback_noop` (`0x007967D0`); ANB's is
`skill_anb000_accepted_event_noop` (`0x0080BAB0`). Both are complete
`jr ra; nop` leaves and add no count. This differs from the inherited
authored-event producer used by TYO/FIR.

`skill_for000_damage_entry` (`0x00805540`) at slot `+0x1A0` enters
state 2 after the common unguarded accepted count. Primary and secondary
amounts in `skill_for000_update` add neither manager hits nor fighter pending.
When both execute in one invocation, the primary clears the manager word
before the secondary; their inspected intervening recovery adds no hit.
They therefore share the existing counted state, subject to ownership and
later external producers. `damage_updates` counts update work, not new
combo hits. These are code-order facts for a retained resource without
an active native move join.

ANB's slot `+0x1A0` is `skill_anb000_damage`. Its positive-guard half amount
follows guarded acceptance without a new count. If instead the common
unguarded callback admits response `(5,0x4F)`, that accepted contribution
is already counted before the half amount. The callback's final local
flush supplies no extra event; its motion helper and state transition
must not be treated as hit producers.

### Skill multiplier gates and paired recovery

`skill_for000_update` (`0x00804E40`) is `ccSkillFOR000`'s damage update
([Class lifetime](../session/battle_entities.md#ccskillfor000-allocation-and-lifetime)).
`for_construct` initializes `BtlForPlayback.cumulative_damage` (`C`) to `0.6`
(bits `0x3F19999A`), `damage_step` (`q`) to approximately `0.03628118`
(bits `0x3D149B93`), and `secondary_damage` to zero. Setup snapshots
`secondary_damage = (C * then_current_record_damage) / 63.0`, storing between
multiplication and division. Primary damage reads the current record anew.

`selector == 2`, unsigned `damage_updates < 64`, and
`projectile_context_predicate() != 1` admit the update.
`binding1_shared_press_c == 1` first stores `C + q`, then uses new `C`:

```text
C <= 1.0:       primary_raw = q * current_record_damage
1 < C <= 1.2:   primary_raw = (q * 0.5) * current_record_damage
C > 1.2:        no primary damage or primary recovery
secondary_raw = secondary_damage
```

Threshold `1.2` is bits `0x3F99999A`. `C` remains above it when primary is
skipped. This is skill-owned scaling with no combo-count read. Secondary runs
on every admitted update even with false primary predicate or exceeded limit.
Counter increment and exits are separate from the primary gate.

Each contribution optionally calls `hit_retain_source` under target gates,
then independently `fighter_hp_add(raw * 0.5, linked_fighter, 0, 0)`.
Recovery uses half raw, not calculated damage/actual HP loss. It retains the
adder's suppression/life gates and `1.0` cap, without `hp_recovery`/effect folds.
Target damage can be suppressed while recovery runs; no success return joins
them. This does not establish ordinary availability or full reuse lifetime.

#### FOR damage-state lifetime

`skill_for000_setup` recomputes the secondary snapshot from current `C`/record
without resetting `C` or `q`. Repeated setup would use existing cumulative
value; normal reuse is unproven. The inspected spawn allocates freshly.
`for_select` stores the byte selector: state 0 clears `damage_updates`, state 3
clears it after release, state 2 performs entry work without clearing it.
None resets `C`, `q` or snapshot. Earlier state-0 updates can advance the
counter, so contributions depend on its entry value rather than always being 64.

### Guard-or-response skill contribution

`skill_anb000_damage` (`0x00808200`) belongs to `ccSkillANB000`
([Creation/destruction](../session/battle_entities.md#ccskillanb000-creation-and-destruction)).
After cleanup, target `guard_state > 0` or response `(5,0x4F)` admits damage.
`resource_index` in `0..196` selects the first descriptor pointer in
`owner_descriptor_transfer_table`; raw is:

```text
(descriptor.guard_damage_multiplier * linked_current_record.damage) * 0.5
```

The multiplications stay separate. Accumulated flush precedes optional
source-retaining `0x122` damage under target gates. There is no ordinary guard
factor `G` or corresponding HP recovery in this bounded contribution.
Current ANB action identities and conditional tier ordering are established
[above](#known-class-source-categories-and-hit-tiers).

| Resource index | Descriptor annotation | Multiplier bits / value | Common CCS |
| ---: | --- | --- | --- |
| 3 | `skill_anb_descriptor_3` | `0x3F800000` / `1.0` | `2sskcha1.ccs` |
| 11 | `skill_anb_descriptor_11` | `0x3F99999A` / approximately `1.2` | `2kkscha1.ccs` |
| 53 | `skill_anb_descriptor_53` | `0x3F800000` / `1.0` | `2anbcha0.ccs` |
| 89 | `skill_anb_descriptor_89` | `0x3FACCCCD` / approximately `1.35` | `2ssvcha1.ccs` |
| 143 | `skill_anb_descriptor_143` | `0x3F8CCCCD` / approximately `1.1` | `2kkwcha1.ccs` |

`skill_primary_event_update` uses `skill_resource_name_table` before class setup.
The action joins, rather than CCS names alone, establish the three current
ANB move identities. ANB resolves the multiplier per contribution, not via
constructor snapshot. FOR resource 22
uses `skill_for_descriptor_22` / `2orccha0.ccs` but does not consume this
multiplier in damage arithmetic.

### Ultimate Jutsu and damage-counter-only calls

`damage_apply_cinematic` calculates raw with `0x100` and applies with display,
without generic coordinator/raw-zero gates. `sp_skill_play_frame` supplies
cinematic fractions and remaining total
([Ultimate Jutsu](../characters/ultimate_jutsu.md#damage)).
`sp_skill_play_end` calculates with `0x100` but sends result times 100 only to
counter, without adjacent HP subtraction; the branch is not Practice-only.
`jutsu_post_cinematic_update` state-6 completion uses raw zero, `0x100`, applies,
and selects post-cinematic effect/KO. It introduces no extra nonzero amount.

## Evidence limits

The single observation covers ordinary/`0.02` contact only. `0.04` contact,
guard damage, Handicap, temporary factors and every direct path remain
unobserved here. Other characters and throws, projectiles, Jutsu, Ultimate
Jutsu, support, status and transformations are not covered by that observation.

Other move/tier attribution and arbitrary shared-record aliases/mutation,
reuse beyond fresh spawn, broader input-source aliases and later FPU rounding
control remain unresolved. Observed heap addresses are allocation-specific.
There is no original source; static branches, authored data and the Practice
observation have distinct bounds.
