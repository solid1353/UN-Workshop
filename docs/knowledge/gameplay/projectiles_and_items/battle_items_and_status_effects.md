# Battle status effects and item-effect lifecycle

## Research coverage

Established: all 138 retail NA2 effect definitions, generic and specialized
lifetimes, payload combination, 116 item records, pickup and hit mappings,
the 19-row status dispatcher, exact per-fighter storage, direct application
and removal owners, every registered constructor/destructor/callback, shared
field ownership, scoped shared-timeline consumers, the gameplay/presentation
boundary, and naming coverage for all 138 IDs through notification, character,
item and form owners.
Open: fixed retail status names for 37 IDs, indirect reachability, the paired
pointer lanes, the complete indirect reach of the embedded `26C` timeline,
pickup-path overlap, selected-use fallback reachability, and the consumer of
interleaved `65/12`. Findings are static.
Names come from `@annotations/NA2` and, for status labels, `@annotations/NUN5`.
Annotation comments carry routine detail; addresses are live. Donor power-effect
comparisons are in [NUN3 and NUN4 characters](../characters/nun3_nun4_characters.md).

This document owns gameplay status membership and lifetime in unmodified NA2
(`SLPS-25837`). Numeric IDs remain numeric unless a gameplay consumer
establishes meaning. UI labels and nearby class names do not establish that
meaning. [Retail file identities](../../game/files/file_identities.md#address-conventions)
owns binary identities and address conventions.

Related owners: [Battle item inventory](battle_item_inventory.md) owns panel
selection, admission and consumption; [Character action callbacks](../characters/character_action_callbacks.md)
owns surrounding callback machines; [Battle entities](../session/battle_entities.md#generic-intrusive-node-and-list-contracts)
owns generic lists; [Battle item-status presentation](../../localization/ui/battle/item_status.md),
[Battle HUD](../session/battle_hud.md), and
[Field-item names](../../localization/field_item_names.md) own presentation
and labels. [Damage](../combat/damage.md), [Chakra and guard](../combat/chakra_and_guard.md),
[Substitution](../characters/substitution.md), [Combat action execution](../combat/combat_action_execution.md),
[Ultimate Jutsu](../characters/ultimate_jutsu.md), [Awakening](../characters/awakening.md),
and [Battle statistics](../session/battle_statistics.md#ninja-tools-and-stage-objects)
own their formulas, state machines and statistic credit. Code `29`'s name remains
qualified by [its naming evidence](../../localization/field_item_names.md#code-29-curse-tag-chakra-points-seal).

## Ownership summary

The resident executable owns gameplay definitions, nodes, application,
countdowns and removal. Resident and BTL callers supply IDs and requested
countdowns. `effect_apply` normalizes through `effect_cached_id_live`,
then `effect_create_node` replaces, constructs and appends. `effect_update`
ticks through `effect_tick_lifetime` and removes through `effect_remove_node`;
`generic_list_remove` owns unlinking and virtual destruction.

Gameplay nodes, auxiliary category-1/2 visuals and side-specific Fukidasi
notifications have separate lifetimes. Inventory counts are a fourth
structure. A visible notification, retained cache or item count does not prove
active gameplay status.

## Resident effect definitions

### Definition table

`effect_factory_records` (`0x0059E2A4`) contains 138 factory anchors with
stride `0x64`, for IDs `00..89`. `AwakeningEffectRecord` names their factory,
ID, default lifetime, flags, payload, display descriptor and presentation
selector. `AwakeningEffectNode` names the copied gameplay fields; field
comments and the lifecycle routines own entry/exit operations.

`effect_presentation_selector` and `effect_presentation_create` choose
presentation implementations for categories 1..3 and ID `89`. The selector
is independent of gameplay category, stacking and countdown. Input `-1`
has selector 5. The complete authored distribution is:

| Selector | Effect IDs |
| ---: | --- |
| `0` | `12,15,17,18,30,31,42,52,58,59,61,62,63,66,89` |
| `1` | `00..0D,13,14,19,1A,1B,1C,1E,20,21,24,25,35,36,37,3A,3B,3D,3F,41,43,4C,4D,4E,4F,54,56,57,6A,6C,73..88` |
| `2` | `0E,39,40,50,5B,5C,65,68,6B` |
| `3` | `11,46,67` |
| `4` | `0F,27..2B,38,4A,5D,69,6D..71` |
| `5` | `23` |
| `6` | `16,1F,3E,49,4B,53,64` |
| `9` | `10,22,26,2C..2F,44,45,47,48,5A,5E,5F,60` |
| `11` | `1D,51` |
| `12` | `32` |
| `13` | `33,34` |
| `14` | `3C` |
| `15` | `72` |
| `16` | `55` |

Only IDs `00..0C`, `23` and `75..77` have display descriptors.
`effect_display_descriptors` (`0x0059E190`) supplies
`EffectDisplayDescriptor.style`, `upper`, `lower_delta` and `upper_delta`.
`fighter_status_display_update` uses them for oscillation and styling,
independently of gameplay duration:

| Effect IDs | Descriptor style word | Upper / lower delta / upper delta |
| --- | ---: | --- |
| `00,01` | `0000E0E0` | `40 / 4 / -0.5` |
| `02` | `000000E0` | `40 / 4 / -0.5` |
| `03` | `00C0C0C0` | `40 / 4 / -0.5` |
| `04` | `00B02020` | `40 / 4 / -0.5` |
| `05` | `00E0E020` | `40 / 4 / -0.5` |
| `06` | `00C02020` | `40 / 4 / -0.5` |
| `07` | `00C020C0` | `40 / 4 / -0.5` |
| `08` | `00010101` | `40 / 1 / -1` |
| `09..0C` | `00C0C0C0` | `40 / 4 / -0.5` |
| `23,75,76,77` | `00202020` | `60 / 4 / -1` |

### Categories

`effect_classify` defines five control-flow categories:

| Effect IDs | Category |
| --- | ---: |
| `0x00..0x0D` | `0` |
| `0x0E..0x64` | `1` |
| `0x65..0x67` | `2` |
| `0x68..0x73` | `3` |
| `0x74..0x89` | `4` |
| Outside `0x00..0x89` | invalid / `-1` |

Categories 1..3 bypass the ordinary fighter application gate. Only categories
1 and 2 allocate an auxiliary status visual after successful construction.
The categories do not establish player-facing meanings.

### Category-0 effect catalog

All IDs `00..0D` use the generic factory and local route flag `02`.
`0A` adds flags `70`; `0B` adds `80`. Their record anchors are
`effect_factory_records` for `00` and `effect_01_definition` through
`effect_0d_definition`, at `0x0059E308..0x0059E7B8`, stride `0x64`.
The table names established mechanics, without assigning unproven UI names.
Neutral means the other generic payload fields retain their authored neutral
values; it does not mean membership has no specialized consumer.

| Effect | Base countdown | Established gameplay role |
| ---: | ---: | --- |
| `00` | `300` | Neutral payload; shares own-list membership restrictions with `01` |
| `01` | `300` | Neutral payload; shares own-list membership restrictions with `00` |
| `02` | `300` | Attack-factor input `1.5` |
| `03` | `300` | Defense-factor input `1.5` |
| `04` | `300` | Defense-factor input `0.5` |
| `05` | `240` | Action-rate input `1.25` |
| `06` | `240` | Action-rate input `0.75` |
| `07` | `300` | Recurring normalized HP input approximately `-1/1500`, boundary `0.1` |
| `08` | `300` | Neutral payload; membership gates the alternate action bank |
| `09` | `240` | Neutral payload; membership refreshes guard-input timing to `-2` |
| `0A` | `450` | Neutral payload; separate flag-`10/20/40` policies |
| `0B` | `300` | Neutral payload; flag-`80` resource/action policy |
| `0C` | `450` | Jump-height input `1.5` |
| `0D` | `240` | Action-rate input `0.75`; recurring chakra approximately `-1/48`, boundary `0` |

[Hit response](../combat/hit_response.md#input-recoveries) and
[Substitution](../characters/substitution.md) own the `00/01` restrictions;
[presence policies](#presence-policies-used-by-native-actions) own the `08`
predicate; [Substitution](../characters/substitution.md) and the
[countdown pass](#countdown-pass) own `09`'s timing consequences. Damage
inverts the defense fold, so `03/04` are not direct incoming multipliers.
Countdown normalization applies to `00..0C`; `0D` retains its input.

### Routing flags

With a nonzero route argument, `effect_apply` routes flags `04` to the
opponent first, with route zero. Flags `02` then permit local application.
Authored forms are local `02`, linked-only `04` and linked-plus-local `06`:
ID `7D` uses `06`, IDs `7E..89` use `04`, and earlier IDs keep `02`.

Additional bits `70` occur on `0A/7C`; additional `80` occurs on
`0B,0E,0F,21,27..2B,38`. Their active predicates require a nonzero node
lifetime, including negative sentinels:

| Flag | Predicate | Status-facing policy |
| ---: | --- | --- |
| `10` | `special_block_check` | Separate higher-level admission gate |
| `20` | `effect_flag20_active` | Candidate-validation rejection |
| `40` | `effect_flag40_active` | Candidate affordability bypass |
| `80` | `effect_flag80_active` | Resource/action gate |

In `action_validate_candidate`, flag `20` rejects before cost checks and
insufficient-resource feedback; flag `40` instead suppresses the subsequent
nonzero-cost affordability check. Co-authoring both on `0A/7C` does not
merge these policies.

Routing is independent and non-transactional. The linked request can succeed
while local construction fails, or conversely. `effect_apply` returns no
success result and does not undo the first application. Each successful
invocation has its own notification, auxiliary visual and cache writes.

The fourth `effect_apply` argument controls this routing only. Route zero
skips both routing-flag decisions and applies directly to the supplied fighter,
including a linked-only authored record. It still runs the normal success
notification, positional feedback, auxiliary allocation and cache tail.

### Base countdowns

These are authored inputs, not elapsed seconds or unconditional frame counts:

| Base countdown | Count | IDs or scope |
| ---: | ---: | --- |
| `-1` | 36 | `17,39,4C,4E,68..78,7B..89` |
| `30` | 2 | `79,7A` |
| `240` | 4 | `05,06,09,0D` |
| `300` | 9 | `00,01,02,03,04,07,08,0B,3C` |
| `450` | 7 | `0A,0C,23,26,48,4A,5E` |
| `600` | 77 | all other finite records |
| `900` | 1 | `4F` |
| `1200` | 2 | `1A,1B` |

No definition defaults to `-2`. Low-ID normalization and gated ticking can
change the effective lifetime.

### Specialized constructors

`effect_factory_registrations` (`0x0059E0F0`) has 19 ID/factory pairs and a
`-1` terminator. `fighter_effects_init` installs them into initially null
factory slots. Shared factories account for the paired IDs:

| ID | Original class | Factory |
| ---: | --- | ---: |
| `0E` | `ccPlConSpl01` | `effect_0e_create` |
| `0F` | `ccPlConSpl02A` | `effect_0f_create` |
| `10` | `ccPlConSpl03` | `effect_10_create` |
| `12` | `ccPlConSpl06` | `effect_12_create` |
| `17` | `ccPlConSpl12` | `effect_17_create` |
| `19` | `ccPlConSpl13` | `effect_19_create` |
| `1A` | `ccPlConSpl14` | `effect_1a_create` |
| `1D` | `ccPlConSpl17` | `effect_1d_create` |
| `22` | `ccPlConSpl25A` | `effect_22_create` |
| `23` | `ccPlConSpl25B` | `effect_23_create` |
| `39` | `ccPlConSpl57` | `effect_39_create` |
| `42` | `ccPlConSpl65` | `effect_42_create` |
| `44,45` | `ccPlConSpl67` | `effect_44_45_create` |
| `47,48` | `ccPlConSpl69` | `effect_47_48_create` |
| `4A` | `ccPlConSpl71` | `effect_4a_create` |
| `54` | `ccPlConSpl81` | `effect_54_create` |
| `7D` | `ccPlConMsnGrv` | `effect_7d_create` |

Each factory takes the fighter owner and effect ID and returns a constructed
node or null. All allocate `0xC0` except `4A`, which allocates `0xE0`.
`effect_39_create` (`0x00295BA0`) rejects a null owner or character other than
`39` before allocation. The other material factories do not impose that
character admission rule; their constructors gate only the material action.

### Specialized entry, exit, and callback behavior

All registered primary gameplay callbacks return zero, including those with
side effects. They do not inspect the node lifetime to disable their work.
Their return value therefore does not cause generic expiry. All registered
secondary slots use the generic no-op except `4A`. Virtual destructors run for
timeout, explicit removal, replacement and hard cleanup; specialized exit
actions are not timeout-only.

Effects `0E/0F/10` conditionally enable material state for owner IDs `1/2/3`;
`39` does so for owner `39`, `44/45` for owner `43`, and `47/48` for owner
`45`. Matching destructors use the same identity checks. Their primary
callbacks are three-instruction return-zero bodies. Character mismatch can
therefore retain a generic payload node without the character's material
change, except that `39` refuses construction. The shared bit and manager
ownership are detailed under [Shared presentation writes](#shared-presentation-writes).

Effects `12/17/42` use `fighter_status_toggle_enable` on entry and
`fighter_status_toggle_disable` on destruction, without a character gate.
Their primary callbacks return zero without other work. These presentation
toggles do not own the gameplay list.

Effects `19/1D` call `fighter_arm_effect_timeline_three` (`0x00237530`)
with argument `1` on every primary callback; they do not select action ID 1.
Effects `1A/54` call `fighter_arm_effect_timeline_one` (`0x002372C0`)
with argument `1` before their character-specific feedback checks. Both
helpers write `Fighter.embedded_block_26c`: reserved discriminator `3` or `1`,
flags `(old & FFF3) | 7`, all three integer and float count views `-1`, and
remainder zero. Neither helper checks remaining node lifetime.

`effect_1a_update` (`0x0025EC50`) then admits feedback only for character `0E`;
`effect_54_update` (`0x002E8880`) admits it only for character `51`, with
`effect_54_ground_feedback_allowed` (`0x002E8780`) additionally gating the
grounded branch. Their earlier timeline write occurs even on a mismatched
character. The four destructors have no inverse for that timeline write.
These effects share one discriminator/current channel: coexisting `1A/54`
and `19/1D` overwrite it in primary-callback list order, without storing a
per-node previous value. `fighter_update_countdowns` (`0x0024C440`) calls
`effect_update` before embedded-`26C` maintenance; an admitted pending-mask-`4`
activation changes the refreshed `-1` to `+1` without decrement on that pass.
Removal stops the removed producer's refresh, while surviving producers can
continue to overwrite the channel. Ordinary maintenance can activate and
decrement the retained request after removal;
[Timer primitives](../../runtime/timer_primitives.md#bounded-callers-and-scheduling-ownership)
owns the scheduling gates. `action_exit_record` (`0x00238D00`) clears all integer/
float views and remainder at `0x00239078..0x002390A4`, writes flags
`(old | 3) & FFF3`, and retains the discriminator. That owner also
performs broad action teardown; effect destruction does not call it merely
to stop this refresh. No isolated status-specific reset/restoration owner was
recovered in this direct chain.

`fighter_effect_timeline_one_active/two_active/three_active`
(`0x00237290/0x00237420/0x002374F0`) test discriminator `1/2/3` and integer
current `!= 0`, without scanning membership, lifetime or timeline flags.
Negative pending counts therefore satisfy these predicates too. Their wrappers
`fighter_effect_timeline_one_or_action_class` (`0x00237220`) and
`fighter_effect_timeline_two_or_response_gate` (`0x00237330`) also admit
independent action/response states; `fighter_effect_timeline_three_gate`
(`0x002374D0`) forwards only the third predicate.

BTL `hit_mode1_check` (`0x0072EDE0`) rejects with return zero under a non-`FF`,
signed-`< 4` `config14` gate when the receiver's third predicate is active.
Under that same gate, the first wrapper sets the source's
`action_callback_trigger` to `3` and returns zero. Other config values and
the second wrapper follow separate admission branches.
`projectile_classify_contact` (`0x0072F460`) queries the third wrapper for
side-specific fighter-contact bits `10/100`, or configurations `44/9B` with
bits `110`; active third state and the same config gate select result `5`
instead of ordinary result `2`. These are scoped collision/admission effects,
not a universal invulnerability definition. The direct wrapper census also
reaches `ai_action_record_allowed`, `stage_navigation_s13`,
`ai_react_incoming_collision_object`, `projectile_chase_action_response`, and
`projectile_enter_state_two_if_tagged_fighter_ready` (`0x0073CC80`). The last
owner queries the second wrapper alongside major-state and
`hit_rejection_active` checks before clearing its private word `+2C0` and
entering projectile state `2`; that word's wider meaning remains open.
Full indirect callers and final player-facing names remain open.

`effect_22_construct` (`0x00303780`) and `effect_23_construct`
(`0x003038F0`) add only their specialized vtables after generic construction.
Their primary callbacks are no-ops. `effect_23_destroy` (`0x00303930`) has
only generic cleanup; `22`'s exit requests the
[successor](#effect-0x22-successor).

Effect `4A` owns an extended `Effect4aNode` and two presentation objects.
`effect_4a_construct` initializes their ownership and private state. The
fourth private state word at `+0xDC` has no established scalar meaning.
Its primary `effect_4a_callback` may alter both fighters' rate multipliers
and linked actions; `effect_4a_secondary_update` performs phase-2 state,
variant and RNG work. `effect_4a_destroy` restores both multipliers and
releases those objects before generic cleanup.

`effect_4a_callback` (`0x002C8690`) reads the linked fighter from owner `+0x20`.
The rejection branch at `0x002C8744..0x002C874C` writes both multipliers to
one without checking that linked pointer. The admitted path checks it only
after writing the owner's multiplier. Its native contract therefore assumes
a valid opponent link. Secondary submission through
`effect_4a_submit_variant_packet` (`0x002C80C0`) also dereferences the owned
controller for variants `0/2` without a null guard. A gameplay node's successful
allocation alone does not certify its two owned controllers.

`effect_7d_construct` (`0x00303F60`) sets owner `motion_scale` to `0.5` and
`effect7d_motion_value` to `2.5`, then halves `recovery_planar_speed` and
`effect7d_motion_scale_a/b`. `effect_7d_destroy` (`0x00303FE0`) has no inverse
or stored originals. Its replaceable default `-1` node can therefore be
replaced and halve the current three values again; every removal reason leaves
these entry writes. Linked-plus-local routing does this independently to both
fighters. `fighter_load_character_record` (`0x002151E0`) initially supplies
these five values from character-record `+6C/+70/+74/+78/+7C`; invoking that
whole initializer also rebuilds resources/actions and initializes HP/chakra,
so it is not a narrow effect-removal operation. `effect_7d_update` has further
motion and action-state writes, owned by [Hit response](../combat/hit_response.md).

The two effect-54 controllers explicitly remove `54` with reason 1 under
their validity policies, clear the awakening marker and reset presentation.
`naruto_classic_effect09_toggle`, restricted to fighter `57`, applies `09`
with requested 9999 on the marker's rising edge and removes it with reason 1
on the falling edge. Low-ID normalization still applies. Surrounding
callback bodies belong to the
[character callback owner](../characters/character_action_callbacks.md#other-direct-rate-writer-families).

## Concurrent payload contributions

Payload reducers read gameplay nodes with `lifetime != 0`, including
negative sentinels. Display selection, the last-success cache and the
awakening marker do not control contributions. Different IDs contribute
independently of the currently shown status.

| Node field | Reducer | Combination |
| --- | --- | --- |
| `attack_factor` / `defense_factor` | `fighter_projectile_scalar` / `effect_defense_factor` | [Damage](../combat/damage.md#calculator-formula) owns sums, clamps and inversion |
| `action_rate` | `fighter_effect_rate_factor` | Start 1, add each value minus 1, cap 1.25, then apply state gates |
| `payload_80` | `effect_jump_height_factor` | Start 1, add each value minus 1, no local clamp; [jump-height consumer](../stages/movement_and_physics.md#jump-impulses-and-aerial-control) |
| `payload_84` | `fighter_knockback_scalar` | Same additive factor, no local clamp; [response consumer](../combat/hit_response.md) |
| `payload_8c` | `effect_hp_recovery_factor` | Same additive HP-recovery factor, no local clamp |
| `payload_90` | `effect_guard_damage_maximum` | Maximum positive value from 0; [guard damage](../combat/damage.md#guarded-hit-damage) |
| `payload_94` | `effect_chakra_recovery_factor` | Recovery fold; [resource consumer](../combat/chakra_and_guard.md#gain-and-clamp-behavior) |
| `payload_98` | `effect_hit_chakra_debit_maximum` | Maximum positive value from 0 |
| `hp_delta` / `hp_boundary` | `effect_hp_contribution` | Signed sum with aggregate boundary gate |
| `chakra_delta` / `chakra_boundary` | `effect_chakra_contribution` | Signed sum with aggregate boundary gate |

The complete authored exceptional values are:

| Node field | Effect IDs and authored values |
| --- | --- |
| `payload_8c` | `77: 0.5`; every other record is neutral `1` |
| `payload_90` | `16,48: 0.5`; `35,5A: 0.25`; every other record is `0` |
| `payload_98` | `12,42,4B: 0.05`; `17,31,52: 0.15`; `18,89: 0.1`; every other record is `0` |

Decimals use their nearest single-precision representation.
`hp_recovery_scale` combines source `hp_recovery` and the receiver's
HP-recovery fold. Effect `77` alone halves those requests. The immediate
item HP branch also uses the fold, but direct effect-entry HP deltas bypass
that scaler.

`hit_effect_chakra_debit` reads the linked fighter's `payload_98` maximum,
checks record flags and requests a debit on the receiver; there is no paired
credit. The debit includes record/caller scaling and cannot exceed current
chakra. Ordinary spend suppression remains. This does not establish that
every hit reaches the helper.

The rate fold returns neutral 1 under `fighter_restore_gate_b`, majors 5/6,
or major 8 with `action_current_category_c0000`. Suppression changes the
returned factor without changing nodes.
`fighter_update_countdowns` samples the rate fold or override, then the
multiplier, before status expiry. A final-positive node can contribute to
the already sampled rate and disappear in the same pass. Effect-4A cleanup
can restore its multiplier without recomputing that stored rate. This is
sampling order, not an extra lifetime tick; action clocks belong to
[Combat action execution](../combat/combat_action_execution.md#action-and-phase-clocks).

### Authored factor columns

The following distributions cover every nonneutral value in these five
columns of all 138 `effect_factory_records`. Unlisted IDs have value `1`.
Decimals represent the nearest authored single-precision values; these are
inputs to the linked reducers, rather than final damage, speed or jump values.
In particular, the action-rate fold caps at `1.25`, even for authored `67:1.5`.
Chakra-recovery payloads and their consumption belong to
[Chakra and guard](../combat/chakra_and_guard.md#gain-and-clamp-behavior).
Other exceptional columns are catalogued below and in
[Entry and ordinary-expiry resource deltas](#entry-and-ordinary-expiry-resource-deltas).

#### Attack factor

| Authored value | Effect IDs |
| ---: | --- |
| `0.5` | `75` |
| `0.75` | `23` |
| `1.1` | `2E,53,59` |
| `1.15` | `5C,81` |
| `1.2` | `25,26,2C,30,33,3F,40,49,58,5E,60` |
| `1.25` | `12,18,1A,36,42,4C,5B` |
| `1.3` | `35,3D,4F,5A,63` |
| `1.35` | `82` |
| `1.4` | `37,3A,45,4D,61,62` |
| `1.5` | `02,0E,0F,10,11,13,14,17,19,1B,1C,1D,1E,1F,20,24,27,28,29,2A,2B,34,39,3B,3E,41,43,46,47,4B,50,51,52,55,56,57,5D,5F,64,65,83` |
| `1.6` | `44,54` |
| `1.8` | `2D,2F,31,48` |
| `2` | `15,16,21,32,38` |

#### Defense factor

| Authored value | Effect IDs |
| ---: | --- |
| `0.5` | `04,76` |
| `0.9` | `1A` |
| `1.1` | `25,26,27,28,29,2A,2B,2C,2E,30,3F,40,49,4B,4E,58,59,5E` |
| `1.15` | `10,36,44,45,47,5B,5C,84` |
| `1.2` | `35,3A,4D,5A,61,63` |
| `1.25` | `0E,0F,11,13,14,15,16,18,19,1B,1C,1D,1E,1F,20,21,24,33,3B,3C,3D,41,43,46,48,4F,50,51,54,55,56,57,5D` |
| `1.3` | `37,53,60,62` |
| `1.35` | `85` |
| `1.4` | `64` |
| `1.5` | `03,17,2D,2F,31,32,34,39,3E,4C,52,5F,66,86` |
| `2` | `38` |

#### Action-rate factor

| Authored value | Effect IDs |
| ---: | --- |
| `0.75` | `06,0D,23` |
| `0.85` | `74` |
| `1.1` | `12,18,27,28,29,2A,2B,3A,42,49,4B,4D,53,59,5F,61,63,7E` |
| `1.15` | `1A,2C,32,33,34,35,36,37,5A,5B,5C,7F` |
| `1.2` | `25,26,38,3F,40,43,46,4A,4C,58,5E` |
| `1.25` | `05,0E,0F,10,11,13,14,15,16,17,19,1B,1C,1D,1E,1F,20,21,24,2D,2E,2F,30,31,39,3D,3E,44,45,47,48,4F,50,51,52,55,56,57,5D,60,62,64,80` |
| `1.5` | `67` |

#### Jump-height factor (`payload_80`)

| Authored value | Effect IDs |
| ---: | --- |
| `0.75` | `23` |
| `1.1` | `3A,4A` |
| `1.2` | `43` |
| `1.25` | `11,13,14,15,16,19,1B,1C,1D,1E,20,3B,3D,41,46,4B,50,51,56,5D` |
| `1.5` | `0C,21,3E,67` |
| `2` | `1F` |

#### Knockback factor (`payload_84`)

| Authored value | Effect IDs |
| ---: | --- |
| `0.75` | `23` |
| `1.1` | `12,17,18,25,26,2C,2D,2E,2F,30,31,32,33,34,35,36,39,3A,3F,40,42,49,4C,52,55,58,59,5A,5B,5C,5E,5F,60,61,62,63,64,65` |
| `1.2` | `37,43` |
| `1.25` | `11,13,14,15,16,19,1B,1C,1D,1E,1F,20,21,27,28,29,2A,2B,3B,3D,3E,46,50,51,56,5D` |
| `1.3` | `47` |
| `1.4` | `48` |
| `1.5` | `0E,0F,10,1A,24,38,44,45,54,57` |

### Signed sums and their boundaries

Each active nonzero delta contributes to one sum. Positive-delta boundaries
combine by maximum from 0; negative-delta boundaries by minimum from 1.
Only the boundary for the net sign is then checked:

- positive sum becomes zero only above the positive boundary;
- negative sum becomes zero only below the negative boundary;
- zero sum remains zero.

Opposing contributions cancel before choosing the boundary. Equality permits
the full delta. `effect_update` forwards it with boundary argument `-1`,
so an aggregate gate does not trim a crossing to the authored limit.
Resource clamps and downstream gain/spend suppression still apply.

These are the complete nonzero HP and chakra delta columns. Fractions and
decimals approximate the authored single-precision values; unlisted deltas
are zero. The boundary is paired with each authored delta before aggregation.

| Effect IDs | HP delta | HP boundary |
| --- | ---: | ---: |
| `07` | `-1/1500` | `0.1` |
| `21` | `-1/1500` | `0` |
| `0F,10,78` | `-1/3000` | `0.1` |
| `22` | `+1/1200` | `1` |
| `25,58,87` | `+1/2400` | `1` |
| `26,5E` | `+1/1800` | `1` |
| `27,28,29,2A,2B,38,49` | `-1/6000` | `0.1` |
| `3A` | `+1/4000` | `1` |
| `44,45` | `-1/4000` | `0.1` |
| `47` | `-1/12000` | `0.1` |
| `48` | `-1/4500` | `0.1` |
| `4A` | `-1/2250` | `0.1` |
| `59` | `+1/6000` | `1` |
| `79` | `-0.03` | `0.1` |

`effect_21_definition` (`0x0059EF88`) has boundary zero, unlike the other
negative HP records. It is included in the same signed sum and boundary fold.

| Effect IDs | Chakra delta | Chakra boundary |
| --- | ---: | ---: |
| `0D` | `-1/48` | `0` |
| `22` | `-0.025` | `0` |
| `3A,3B,41,49,54,5B,5C` | `-1/120` | `0` |
| `4A` | `-1/90` | `0` |
| `88` | `+0.05` | `15` |

### Entry and ordinary-expiry resource deltas

`payload_9c` is HP entry delta: approximately +0.1 only on `10/45`.
All HP zero-exit `payload_a0` values are zero. Chakra entry `payload_a4` is
+15 on `0E,0F,21,22,27,28,29,2A,2B,38,39`, -15 on `7A/7C`, and zero
elsewhere. Chakra zero-exit `payload_a8` is -15 only on
`0E,0F,27,28,29,2A,2B,38,7C`.

`effect_zero_countdown_actions` owns zero-exit fields, reached by the tick
helper at zero. `effect_generic_cleanup` does not consume them.
Explicit removal, family switching, replacement and hard cleanup therefore
do not themselves apply ordinary-expiry resource deltas. Virtual destructor
actions still occur. Replacement can repeat entry deltas without the old
zero-exit delta; resource gates/clamps determine actual mutation.

### Direct field writes do not use the payload folds

Nonneutral size-target `payload_88` values are `1A:1.5`, `54:3.0` and
`7B:0.5`. Entry calls `fighter_set_size_targets`; destroying any such node
requests target 1 without checking for other survivors. Natural removal uses
a timed transition, forced removal a direct write. The setter does not scan
or combine nodes, so application/removal order owns the shared target.
Different-ID coexistence does not imply additive targets or restoration to a
surviving effect's value.

The decoded direct setter owners are `effect_generic_construct`
(`0x00304910`), `effect_generic_cleanup` (`0x00304C20`) and `choji_set_mode`
(`0x002E8E90`). The latter requests direct size `3` when effective action
index is `6`, before comparing the requested mode. Status nodes therefore
are not the only recovered size owner; [Choji's mode](../characters/awakening.md#chojis-marker-selected-parameter-override)
owns its character actions and marker-selected parameter changes.

Effect `4A` separately writes paired `update_rate_multiplier` values.
Its rejected distance/state branch restores both to 1; other nonzero
`context_state` branches leave them alone; admission writes owner 0.75 and
opponent 0.25. Destruction restores both to 1 without checking for another
`4A` on either fighter. Two admitted callbacks can overwrite one another;
later callbacks may write again. No ownership count or additive fold
mediates these writes. Timeline/response consequences belong to
[Hit response](../combat/hit_response.md#timed-downed-recovery).

### Shared presentation writes

`fighter_effect_material_enable` (`0x00215F10`) sets one shared
`control_flags` bit `08`, refreshes bindings and informs the pause controller
only when the bit changes. `fighter_effect_material_disable` (`0x00216010`)
clears it when set. Neither retains an original bit or scans surviving nodes.
For owner `43`, removing either coexisting `44/45` clears the material bit
despite the other node; owner `45` has the same conflict for `47/48`.

Material helpers and `fighter_status_toggle_enable/disable`
(`0x003076C0/0x00307700`) share BTL `fighter_status_manager_toggle`
(`0x0076ECC0`). It writes pause-controller byte `8 + side` as
`(old & 1) | ((value << 1) & 6)`: input `1` sets bit `1`, input `0` clears
bits `1/2`, and bit `0` survives. This is one byte per side, not a bit indexed
by side in one byte. There is no reference count or status-list search.
Removing one of `12/17/42` can therefore clear those presentation bits while
another remains; material cleanup can clear the same shared manager state.
These conflicts affect presentation ownership, not surviving gameplay payloads.

## Per-fighter storage

`Fighter` names gameplay `effect_count`, `effects`, `effect_tail`,
`effect_vtable` and `effect_owner`; auxiliary head/tail/vtable; and
`last_effect_id` plus the status display trio. The auxiliary embedded
container is `EffectAuxList`, whose `count` occupies the word represented
by `effect_sidecar`. `AwakeningEffectNode` names its generic-node prefix, removal reason,
owner, ID, lifetime, flags and payload. `EffectAuxVisual` and `Fukidasi`
name the separate presentation objects.

The applied `Fighter` and `AwakeningEffectNode` layouts agree with the
resident lifecycle accesses:

| Fighter offset | Storage | Width |
| ---: | --- | ---: |
| `0x158` | `effect_countdown_scale` | float |
| `0x8C4` | `effect_count`, start of gameplay container | 4 |
| `0x8C8` | `effects`, gameplay head | pointer |
| `0x8CC` | `effect_tail` | pointer |
| `0x8D0` | `effect_vtable` | pointer |
| `0x8D4` | `effect_owner` | pointer |
| `0x8D8` | auxiliary count, represented by `effect_sidecar` | 4 |
| `0x8DC/0x8E0` | auxiliary head/tail | two pointers |
| `0x8E4` | `secondary_effect_vtable` | pointer |
| `0x8E8` | `last_effect_id` | signed 2 |
| `0x8EC/0x8F0/0x8F4` | display delta/value/style | float/float/4 |

| Gameplay-node offset | Storage | Width |
| ---: | --- | ---: |
| `0x18/0x1C` | generic previous/next | two pointers |
| `0x50` | generic virtual table | pointer |
| `0x60/0x64` | `removal_reason` / `owner` | signed 4 / pointer |
| `0x68/0x6C/0x70` | `effect` / `lifetime` / `flags` | signed 4 / signed 4 / unsigned 4 |
| `0x74..0xB8` | copied payload | 18 floats |

The generic allocation is `0xC0`; specialized nodes may extend it. The
gameplay list, auxiliary list and last-success cache are separate storage,
rather than an array indexed by effect ID.

Removal never clears `last_effect_id`. `effect_display_select` rescans
membership before honoring it; the cache is stale-capable. `effect_find_node`
returns the first exact member, and `fighter_has_effect` tests exact
membership, without a lifetime check. A zero node pending gated expiry
therefore remains a member. `effect_1a_argument_or_membership` queries
membership only for argument -1; argument `1A` returns true directly.

Display selection proceeds through: highest active category-4 ID; low ID
with greatest positive countdown (lower ID wins a tie); an active cached low
ID override; then highest active IDs in categories 1, 2 and 3.
Final priority is 3, 2, 1, selected low ID, 4. Effect 0 is suppressed by
`action_current_category_c0000`; all selection is suppressed unless
`status_flags & 0x80`. `effect_display_publish` still publishes `-1`.
This policy chooses presentation, rather than gameplay ownership.

### Presence policies used by native actions

These policies use membership, so a present zero-countdown node qualifies:

| Predicate | Policy |
| --- | --- |
| `effect08_action_bank_allowed` | Effect 08 and `fighter_resource_contribution_blocked == 0` |
| `effect_ordinary_category_present` | Category 1..3 member except 23/4E |
| `effect_material_family_present` | Any of 0E/0F/10 |
| `effect4a_nearby_present` | Effect 4A and `effect4a_distance <= 400` |
| `effect_jutsu_debit_exception` | 0B vetoes; otherwise 3B/41 permits; otherwise false |

The last predicate is not a three-ID OR. A zero-countdown `0B` awaiting
expiry still vetoes. Result 1 lets `opponent_lock_override` skip the active
flag-80 scan before tier debit; its own spend gates remain. Result 0 reaches
the scan and does not itself prove a failed debit: a zero `0B` is no longer
active for that scan. [Ultimate Jutsu](../characters/ultimate_jutsu.md#start)
owns connection reachability.

`status_family_pointer_choose` uses `0E/0F/10` membership and fighter identity
to select paired authored pointer lanes; their wider meaning is unresolved.
Effect 08 gates the
[separate attack bank](../combat/combat_action_execution.md#character-specific-scene-and-timer-selection).
`hit_classify_pair` can emit an event from the category predicate and eligible
record flags when the hit chakra maximum is zero; it creates no status.
`linked_effect4a_display_reset` restores a local presentation value without
removing either fighter's effect.

The generic node's removal bit is independent of lifetime. Generic
`effect_generic_primary_update` returns zero, and its other ordinary slots
are no-ops; zero-exit resource actions reside in the separate countdown
helper. Specialized classes replace selected slots and eventually use
generic cleanup.

## Initialization and inherent locked effects

`fighter_two_list_construct` creates the lists;
`fighter_effects_init` initializes owner, cache `FFFF` and display state.
`fighter_add_inherent_form_effect` installs category-3 nodes during
character initialization with explicit countdown `-2`:

| Fighter ID | Inherent effect |
| ---: | ---: |
| `0x49` | `0x72` |
| `0x4B` | `0x73` |
| `0x2F..0x38` | fighter ID `+ 0x39`, producing effects `0x68..0x71` |

They resist same-ID replacement and ordinary removal, but reason 5 removes
them.

## Application, replacement, and countdown normalization

### Native interface inputs

These routines use two different first-argument roots:

| Routine | Live address | Input root / result |
| --- | ---: | --- |
| `effect_apply` | `0x00305C30` | Fighter, ID, requested lifetime, route; void |
| `effect_create_node` | `0x00305270` | Gameplay container at Fighter `+0x8C4`, ID, normalized lifetime; insertion Boolean |
| `effect_find_node` | `0x00305210` | Gameplay container at Fighter `+0x8C4`, ID; first node or null |
| `effect_remove_id` | `0x00305510` | Fighter, ID, reason; void |
| `effect_remove_node` | `0x00305040` | Gameplay container at Fighter `+0x8C4`, node, reason; void |
| `effect_remove_ordinary_classes` | `0x003055C0` | Fighter, reason; void |
| `effect_force_clear` | `0x00305750` | Fighter; void |

`effect_create_node` supplies neither high-level eligibility/routing nor the
application success tail. It is not an interchangeable version of
`effect_apply` returning success. `effect_apply` and the removal helpers
assume valid nonnull input roots; they do not establish fighter liveness.
`primary_fighter_get` (`0x003769C0`) selects side `0/1` through current manager
aliases but assumes the manager exists. The alias lifetime belongs to
[Battle entities](../session/battle_entities.md#manager-allocation-and-alias-slots).

### High-level application

The ordered contract of `effect_apply` is ID/category admission, optional
linked/local routing, default resolution for input -1, normalization, then
construction. Categories 0/4 require `status_flags` bit 0 clear and
`context_mode_word == 0`; categories 1..3 bypass that gate.

`context_mode_word` (`0x00216820`) reads `battle_hub->fighters->state`,
or returns zero when either owner is missing. Passing this application gate
does not establish a live graph or a safe fighter pointer. The start-menu
opening predicate uses the separate `fighter_coordinator_get_state` result.

Success alone performs the notification, low-ID positional feedback,
category-1/2 auxiliary allocation and cache update. Failure does none of that
success tail.

Input lifetime `-1` resolves the definition's default before normalization.
For a finite default this requests that finite value, not a stored indefinite
node. A definition whose default is `-1` retains the indefinite sentinel.

### Same-ID replacement rule

The normal invariant is one node per exact ID, with different IDs coexisting.
A null container owner rejects before examining an old node. A first same-ID
`-2` rejects replacement; otherwise the old node is destroyed with reason 5
before allocation or construction. A new node is appended only on success.
Normalized values other than -1 override the constructor lifetime.

Replacement is destroy-first. Failure cannot restore the old effect or undo
its destructor. The first-match lookup does not repair externally duplicated
nodes: a locked first node rejects, and a replaceable first node is removed
without examining later duplicates. Exact-ID removal, in contrast, attempts
every matching node in its starting-count traversal.

Destroying `22` can apply successor `23` before a replacement `22` is
appended. Both IDs can remain active without violating exact-ID uniqueness.
The generic policy supplies neither category-wide eviction nor additive
same-ID stacking.

### Caller-enforced per-fighter effect families

`awakening_associations` (`0x005C1D30`) has `0x5E` fighter-indexed records.
Zero-count rows are omitted:

| Fighter ID(s) | Authored effect family |
| --- | --- |
| `05,06,07` | `11`; `12`; `13` |
| `09,0A,0B` | `14`; `15`; `16` |
| `0C,0D` | `{17,18}`; `19` |
| `0F..13` | `1B..1F`, one per fighter |
| `15,16` | `20`; `21` |
| `19,1B,1C` | `24`; `25`; `26` |
| `27` | `{2C,2D}` |
| `28` | `2F` |
| `29` | `{30,31}` |
| `2A` | `32` |
| `2B` | `{33,34}` |
| `2C,2D` | `35`; `36` |
| `2E` | `{37,38}` |
| `2F..38` | `68..71`, by `effect = fighter + 39` |
| `39` | `72` |
| `3A,3B` | `3A`; `3B` |
| `3C,3D,3E` | `3D`; `3E`; `3F` |
| `3F` | `73` |
| `40,41,42` | `41`; `42`; `43` |
| `43` | `{44,45}` |
| `44` | `46` |
| `45` | `{47,48}` |
| `46,47,48` | `49`; `4A`; `4B` |
| `49` | `72` |
| `4C` | `4C` |
| `4D,4E,4F` | `4E`; `50`; `51` |
| `50` | `{52,53}` |
| `51,52,53,54` | `54`; `55`; `56`; `57` |
| `55` | `{58,59}` |
| `56` | `5A` |
| `57` | `{5B,5C}` |
| `58,59,5A` | `00`; `5D`; `5E` |
| `5B,5C,5D` | `{5F,60}`; `{61,62}`; `{63,64}` |

`awakening_enter_class_seven` removes family members below `68` with
reason 1 before applying `selected_jutsu_effect` with default -1, then
checks whether the selected ID belongs to the family. This route enforces
multi-ID exclusivity despite generic different-ID coexistence. IDs `68+`
are excluded from that loop; those rows establish association rather than
exclusivity.

`input_sector_widen_state_b` and `awakening_reconcile` also use the family
table. Fighter `19` has explicit `22/23` handling; `3A` can remove `07`;
`45` has a first-family-member transition and `4D` has explicit/family
cleanup. The scoped exact-ID removal callers use reason 1, including
effect-54 cancellation, fighter-57 toggling and both code-0D pickup paths.

### Countdown normalization

`effect_cached_id_live` preserves every negative input. For nonnegative
requests, let `r` be the requested/default value and `s` be
`Fighter.effect_countdown_scale`:

| Effect IDs | Value before integer conversion |
| --- | --- |
| `00,01,04,06,07,0A` | `r * (2.0 - s)` |
| `02,03,05,08,09,0B,0C` | `r * s` |
| `0D..89` | `r` |

Negative computed values clamp to zero before integer conversion. The broader
gameplay meaning of this fighter scalar remains unproven.

`-1` never ticks or auto-expires but is replaceable/removable. `-2` also
blocks replacement and removal reasons 0..3; reason 5 still destroys it.
Other negative values would avoid generic expiry, though no definition
authors them.

## Update, expiry, and removal

### Countdown pass

`effect_update` initially allows ticking when `context_mode_word == 0`.
Effect-1A membership outside major 8 forces it on; a nonzero
`battle_status_tick_blocked` or `fighter_restore_gate_b` then forces it off.
Its earlier resource-sum gate is separate and does not govern countdown
lifetime. Effect-09 membership also requests guard timing -2 before this
gate, including when its countdown is zero.

On an allowed pass, a positive lifetime loses one. IDs 0/1 can additionally
lose `floor(3*n/2)` while still positive, where `n` is the popcount of
`BattleInput.logical_mask & 0xFFFFF00F`; the result clamps at zero.
Zero runs the resource exit helper and node zero-exit callback, then requests
reason-0 removal. Negative lifetimes do not auto-expire; a null-owner tick
also reports completion.

Zero is a pending-expiry state, not construction failure. A normalized or
overridden zero can be appended and perform the complete success tail.
Membership sees it, reducers/flags/display do not, and it remains until an
allowed countdown pass removes it. Later generic traversal does not remove
it merely for zero lifetime.

The post-countdown primary-callback traversal runs even when ticking is
disabled. Registered gameplay callbacks all return zero; the remaining
generic removal trigger is the base removal bit. Auxiliary visuals can
return one on their own completion.

`effect_secondary_update` runs separately in battle phase 2, after the
generic fighter-node secondary pass. It dispatches secondary callbacks
rather than ticking lifetime. Effect-4A's secondary work recomputes private
response state, checks the linked member, selects variants and advances
private phases/RNG under its own gates. Phase 2 is therefore not pure drawing.
[Battle lifecycle](../session/battle_lifecycle.md#what-phase-2-guarantees)
owns complete ordering.

### Core removal decision

`effect_remove_node` writes `removal_reason` before deciding:

| Reason | Proven generic behavior |
| ---: | --- |
| `5` | Unconditional immediate unlink/destruction, including `-2` nodes |
| `3` | Categories `3/4` remain; categories `0/1/2` remove unless countdown is `-2` |
| `0,1,2` | Remove unless `-2` or the effect-`1A` hold applies |

A blocked/deferred attempt still changes that field. For `1A` in major 8,
ordinary reasons 0..2 can reset countdown to 1 instead of destroying.
Natural expiry has already run zero-exit actions, so another zero crossing
can run them again until the state changes.

Final list destruction calls virtual destructors directly, leaving the prior
reason, commonly -1. It is not a reason-5 event, although generic cleanup
treats every nonzero reason as forced.

### Explicit and bulk cleanup

| Operation | Scope |
| --- | --- |
| `effect_remove_id` | Every matching ID in the starting traversal |
| `effect_remove_ordinary_classes` | Categories 0..2, then clear display trio |
| `effect_force_clear` | One starting-count reason-5 pass per category 0..4, then clear display trio |
| `fighter_two_list_destroy` | Both lists, including a second main-list clear |
| `fighter_remove_effects_0_1` | Every 0/1 member, then dedicated cleanup |

Exact-ID, ordinary-category and hard cleanup touch only the gameplay list.
Already-created auxiliary visuals complete independently. The two category
cleanups zero display delta/value/style after removal attempts but keep the
last-success cache. Locked gameplay nodes can therefore coexist with cleared
display state and a stale cache.

IDs 0/1 have caller-enforced paired cleanup with reason 1 from
`recovery_init` for values `61/62` and from `downed_recovery_enter`, when
either member is present. The post-cleanup helper runs even after blocked
removal. Generic application and exact removal still treat the IDs
independently. Numeric cleanup reasons 1..3 have no established player-facing
names.

### Native action and form boundaries

`fighter_end_exchange` performs ordinary-category reason-1 cleanup before
reservation/action/exchange cleanup and before setting its status bits;
already-bit-0 calls skip the body. `fighters_end_exchange` invokes that
policy independently for both fighters. `fighter_paired_event` requires an
eligible initiator and an existing coordinator before both reason-1 cleanups.

`jutsu_connection_cleanup` requests reason 2 only with a coordinator not
already in state 6. `jutsu_post_cinematic_update` substate 1 requests reason 3
for both participants before attempting the outcome effect. Both traverse
only categories 0..2; categories 3/4 are outside their scope independently of
sentinel protection.

Form reconstruction destroys old fighter ownership and creates fresh
containers. `battle_save_reentry_values` / `battle_restore_reentry_values`
retain selected HP/chakra/timer/inventory values, not status nodes or
countdowns. The new form installs its own `-2` inherent node; it does not
promote an old timed node. The twelve category-3 records have neutral generic
payloads, so replacement character parameters come from the
[form rebuild](../characters/awakening.md#replacement-character-parameters),
rather than that generic payload.

### Effect `0x22` successor

`effect_22_destroy` applies `23` whenever an owner exists, before base
cleanup, without checking reason. It can occur on expiry, explicit removal,
replacement and individual hard removal. Effect 23 has no successor; no
other registered destructor in the scoped research applies an effect.

Countdown traversal snapshots its starting count and captures next before
removal, so newly appended 23 is not ticked in that pass. Both category
cleanups snapshot separately for each category; a category-1 successor
appended during that pass is not revisited by later categories.

Consequently `effect_force_clear` can end with new 23, its auxiliary visual
and cache 23 still present. `fighter_cleanup` does not add a second gameplay
clear. Final container destruction differs: main clear, auxiliary clear,
then another main clear removes the successor and ends empty.

## Random field-item selection

`field_item_random_select` chooses an identity from authored BTL pools;
`field_item_amount_apply` separately applies the Items amount setting.
[Battle item inventory](battle_item_inventory.md#random-field-item-selection)
owns that selector contract and amount boundary.

## Immediate pickup/item-effect path (`0x00..0x13`)

### Resident item metadata

`item_metadata_table` (`0x005B04F0`) has 116 `ItemMetadata` records for codes
`00..73`. The following table is separate and does not extend item records
to `74`. Named accessors provide kind, flags, amount and signed direct effect.

`item_immediate_dispatch` applies the direct effect with default -1/route 1
when the alternate flag is clear and the effect is not -1, then runs the
selected resource branch. Flag `20` selects the HP path, `40` the secondary
resource path and `80` the alternate action path. Status failure does not
suppress later resource/presentation branches, and a resource gate does not
undo a created status.

### Resident pickup resolver

`field_item_pickup_resolve` obtains the concrete code and chooses inventory,
resource, effect or exact cleanse handling. Inventory collection applies no
status. Immediate code 06 has both its table effect and an extra 0C;
code 0D removes exactly 04/06/07/0A with reason 1.

### BTL pickup-object callback

`item_pickup_callback` resolves the fighter and scaled magnitude, performs
code-0D removals before common immediate dispatch, then performs code-0C's
separate resource adjustment or code-06's extra effect. The sequence has no
rollback. It shares the resident resolver's decisions, but the evidence does
not establish whether one pickup reaches both or whether they are alternate
phases; no double-application conclusion follows.

| Code | Kind | Flags | Amount | Table effect | Additional proven action |
| ---: | ---: | ---: | ---: | ---: | --- |
| `00,01` | `0` | `0000` | `0` | `-1` | none found |
| `02` | `1` | `0020` | `10` | `-1` | resource path only |
| `03` | `2` | `0040` | `5` | `-1` | resource path only |
| `04` | `2` | `0040` | `0.75` | `-1` | resource path only |
| `05` | `2` | `0040` | `0` | `-1` | resource path only |
| `06` | `4` | `0000` | `0` | `05` | also applies effect `0C` with default input `-1` |
| `07` | `4` | `0000` | `0` | `02` | none found |
| `08` | `4` | `0000` | `0` | `08` | none found |
| `09` | `4` | `0080` | `0` | `-1` | alternate action path; semantics outside this scope |
| `0A` | `4` | `0000` | `0` | `09` | none found |
| `0B` | `4` | `0000` | `0` | `03` | none found |
| `0C` | `4` | `0000` | `0` | `0B` | direct `15.0` secondary-resource adjustment and numeric notification `2` |
| `0D` | `1` | `0020` | `2` | `-1` | removes effects `04,06,07,0A` with reason `1`; BTL callback queues notification `4` |
| `0E` | `4` | `0080` | `0` | `-1` | alternate action path; semantics outside this scope |
| `0F..13` | `6` | `0000` | `0` | `-1` | no direct effect found |

`item_selected_resolve` has a separate direct-effect fallback:

| Item code | Direct request |
| ---: | ---: |
| `06` | Effect `05`, default `-1`, route `1` |
| `07` | Effect `02`, default `-1`, route `1` |
| `08` | Effect `08`, default `-1`, route `1` |
| `0A` | Effect `09`, default `-1`, route `1` |
| `0B` | Effect `03`, default `-1`, route `1` |
| `0C` | Effect `0B`, default `-1`, route `1` |

It excludes delayed kinds 3/6, table-driven flag 10, code 09 and direct
effect -1. It applies only the metadata effect, with neither the pickup
path's extra 06 effect nor its resource adjustments. These six records lack
inventory flag 80, so the branch's static presence does not establish
ordinary three-slot selection reachability.

### Direct-effect records carried by hit objects

All non--1 metadata direct-effect entries are:

| Item/object code | Kind / flags | Direct effect | BTL object-definition row |
| ---: | --- | ---: | ---: |
| `06` | `4 / 0000` | `05` | not present |
| `07` | `4 / 0000` | `02` | not present |
| `08` | `4 / 0000` | `08` | not present |
| `0A` | `4 / 0000` | `09` | not present |
| `0B` | `4 / 0000` | `03` | not present |
| `0C` | `4 / 0000` | `0B` | not present |
| `24` | `3 / 0180` | `06` | `09` |
| `26` | `3 / 0180` | `07` | `0C` |
| `29` | `3 / 0180` | `0A` | `1C` |
| `2A` | `3 / 0180` | `04` | `1D` |
| `31` | `3 / 0180` | `01` | `85` |
| `54` | `3 / 0380` | `07` | `A1` |
| `57` | `3 / 0280` | `07` | `88` |
| `5B` | `3 / 0380` | `06` | `7E` |
| `6E` | `3 / 0280` | `07` | `9C` |

`projectile_configs` (`0x0089C910`) has `0xB6` rows of `0x68` bytes.
`transient_actor_initialize` copies the leading item code to
`Projectile.external_id`; `transient_actor_lineage_notify` maps that code
and applies its direct effect to the struck fighter with default -1/route 1.
The complete leading-code range is 0..6F, within the metadata scan.

The six low codes are absent from that object table and are consumed by the
immediate pickup path. The other nine occur at the listed rows and carry
their effect through hit/result handling. Default selection still passes
through low-ID normalization.

Item `5B` has both mechanisms: delayed activation applies 05/requested 180
to its user; row `7E`'s hit object applies 06/default -1 to the struck fighter.
Codes `54/57/6E` lack three-slot status rows and carry hit effect 07 instead.

## Three-slot battle-item path (`0x51..0x73`)

### Collection and inventory ownership

All 19 status-row codes have metadata flag 80. Collection adds them to the
appropriate inventory instead of applying status.
[Battle item inventory](battle_item_inventory.md#dispatch-and-consumption-boundary)
owns selection, admission, delayed commit and consumption.

`item_input_dispatch` reads the selected item and enters
`item_selected_resolve`. The 18 kind-4 rows reach panel activation
immediately; kind-3 `5B` does so only at delayed commit.
`item_panel_activate` runs the status dispatcher before slot decrement and
its activation marker. Because the dispatcher returns no per-effect success,
a guarded or locked status rejection does not preserve the item count.
Recovery branches are not rolled back with a rejected status.

### Dispatcher and table layout

`item_status_dispatch` reads `item_status_table` (`0x00898EF0`), 19
`ItemStatusRow` records with `requested` and up to four effect lanes,
terminated by -1. Each lane's interleaved word is unread here.
`fighter_awakening_presentation` runs before the first actual effect.

| Item | Requested | Effects actually read | Interleaved words, not read here |
| ---: | ---: | --- | --- |
| `52` | `200` | `02,05` | `05,08` |
| `53` | `300` | `3C` | `00` |
| `55` | `300` | `05,0C` | `08,11` |
| `56` | `250` | `02,05` | `05,08` |
| `59` | `200` | `05` | `08` |
| `5B` | `180` | `05` | `08` |
| `5D` | `0` | none | none |
| `5F` | `250` | `02` | `05` |
| `60` | `180` | `03` | `06` |
| `63` | `250` | `02,03,05` | `05,06,08` |
| `64` | `200` | `02` | `05` |
| `66` | `250` | `02,03` | `05,06` |
| `67` | `0` | none | none |
| `68` | `250` | `03` | `06` |
| `6D` | `150` | `09,08` | `09,0C` |
| `70` | `250` | `03` | `06` |
| `71` | `250` | `02` | `05` |
| `72` | `250` | `05,03` | `08,06` |
| `73` | `250` | `65` | `12` |

The applied set is `{02,03,05,08,09,0C,3C,65}`. Interleaved `06/11/12`
are not extra effects at this site. Effects 3C/65 retain requests 300/250;
65 therefore uses 250 rather than default 600. Low-ID requests still
normalize by the fighter scalar.

Multi-effect rows are sequential and non-atomic. Failure neither stops later
entries nor undoes earlier successes. A partial subset may remain active.
Every successful entry has its own cache/presentation tail; the cache ends
at the last successful entry, unaffected by a failed later one.

Every matching row adds one to statistic metric 6, Special ninja tools,
including empty-effect rows and rejected applications. NUN5's
`item_status_table` (`0x008B48D0`) is byte-identical and its
`item_status_dispatch` (`0x00727020`) calls its resident `effect_apply`.
This corroborates the layout rather than supplying NA2 execution evidence.

### Additional recovery paths

After generic effects, `5D/67/71` separately take metadata amount through
`hp_recovery_scale` with receiver fighter/source zero, then
`fighter_hp_add` with flags 1/1:

| Item | Generic status first | Metadata recovery | Additional action |
| ---: | --- | ---: | --- |
| `5D` | none | `10.0` | Separate `fighter_secondary_resource_add` input `2.5`; numeric notification code `2` |
| `67` | none | `10.0` | none found |
| `71` | Effect `02`, requested `250` | `5.0` | none found |

The HP sequence emits notification 1. Item 5D's additional
`fighter_secondary_resource_add` input is exactly 2.5 and emits notification 2.

## Gameplay state versus status presentation

Only mappings and lifetime boundaries belong here; HUD drawing and label
composition belong to the linked presentation owners.

### Resident effect-to-notification map

Successful construction can use `effect_notification_map` (`0x005B0040`):

| Gameplay effect | Notification object code |
| ---: | ---: |
| `00` | `0D` |
| `02` | `05` |
| `03` | `06` |
| `04` | `0E` |
| `05` | `08` |
| `06` | `07` |
| `07` | `13` |
| `08` | `0C` |
| `09` | `09` |
| `0A` | `0F` |
| `0B` | `10` |
| `0C` | `11` |

Most low-ID interleaved status-table words agree, but the item dispatcher
does not read them. The `65/12` pair does not establish notification 12:
the resident map has no 65 entry and the scoped route has no literal
notification-12 call. Its consumer remains unresolved. Calling it unused
metadata is an untested hypothesis.

### Status identity and naming coverage

The naming census covers all `00..89` IDs. It separates 12 IDs in the
resident notification map, 77 character/item-qualified ordinary-panel labels,
12 transformed-character identities, and 37 IDs without an established fixed
retail status name. The last group includes known mechanics and owners; it
does not mean the effects are unused.

`effect_factory_records` has no fixed title field. Ordinary panels select
a texture from the recipient's side resource, independently of gameplay
identity. `battle_queue_fighter_ccs` supplies that slot from the character's
`3PCT` file; `battle_side_resource_get` and `effect_aux_visual_construct`
consume slot 4. [Ordinary awakening-label composition](../../localization/ui/battle/selectors_and_prompts.md#ordinary-awakening-label-composition)
owns that presentation chain. Applying the same ID to a different character
can therefore select a different phrase or a missing texture. A panel phrase
is a checked owner-qualified label, not a definition of every gameplay
consequence or a character admission rule.

#### Low-ID notification identities

These joins use `effect_notification_map`, the BTL Fukidasi maps and the
record words documented in [Item-status label words](../../localization/ui/battle/item_status.md#status-record-words).
Mechanics remain owned by the category-0 catalogue and its linked consumers.

| Effect | Supported identity or description | Exact presentation or item evidence |
| ---: | --- | --- |
| `00` | Sleep | Notification `0D` -> record `99` |
| `01` | Stun Ball status; no fixed status title recovered | Item `31`, Stun Ball -> metadata direct effect `01`; hit row `85` |
| `02` | Attack Power Up | Notification `05` -> `8F/92`; Food Pills `07` -> `02` |
| `03` | Defense Power Up | Notification `06` -> `90/92`; Tortoiseshell Pills `0B` -> `03` |
| `04` | Defense Power Down | Notification `0E` -> `90/93`; Curse Tag: Armor Break `2A` -> `04` |
| `05` | Speed Up | Notification `08` -> `91/92`; Shoes of Jonin `06` -> `05` |
| `06` | Speed Down | Notification `07` -> `91/93`; Weight of Determination `24` -> `06` |
| `07` | Poison, from the named item and HP-drain consumer | Notification `13` -> record `97`, whose checked English crop is `POI`; Poison Smoke Bomb `26` -> `07` |
| `08` | Invisible | Notification `0C` -> record `98`; Scroll of Hidden Cloud `08` -> `08` |
| `09` | Substitution Jutsu, as a presentation label | Notification `09` -> record `9A`; Scarecrow `0A` -> `09` |
| `0A` | Chakra Seal, as a presentation label | Notification `0F` -> `82/9B`; item `29` -> `0A`; the item's naming qualification remains with Field-item names |
| `0B` | Chakra Max, as a presentation label | Notification `10` -> `82/94`; Energy Pills `0C` -> `0B` |
| `0C` | Jump Power Up | Notification `11` -> `9C/92`; Shoes of Jonin `06` adds `0C` |
| `0D` | Action slowdown and recurring chakra drain; descriptive, not a recovered title | No notification-map row. `projectile_record99_callback` separately applies `0D` and queues Speed Down notification `07`, also used for `06` |

[Field-item names](../../localization/field_item_names.md) owns the item names;
[Direct-effect hit records](#direct-effect-records-carried-by-hit-objects)
owns the metadata/object joins through `item_direct_effect_get` and
`transient_actor_lineage_notify`. The Sleep, Invisible, Substitution Jutsu
and Chakra Max words do not establish universal action, visibility,
substitution or resource semantics. In particular, reused Speed Down feedback
does not make `06` and `0D` the same gameplay effect.

#### Character-qualified ordinary-panel identities

Every row below joins the checked NA2 `awakening_associations` entry or
character-local `jutsu_name_table` record to the panel's selected texture.
The exceptions are `39`, owned by `naruto_channel2`, and `3C`, owned by
Gaara's personal item `53` and its `item_status_dispatch` row.
Character names follow [Character identity](../characters/character_ids.md);
all character IDs in this table are hexadecimal.

The phrases are the official NUN5 English words in the corresponding retail
portrait assets. The NA2/NUN5 texture-name correspondences are owned by the
linked presentation document. Source hashes and all 72 mapped
`mode1name` textures were checked against the maintained retail inputs;
these are cross-game label correspondences, not evidence of equal mechanics.
In the asset column, `name1/name2` means `TEX_mode1name1/2` in that side's
`3eye/` portrait file. `name2` follows auxiliary selector 1, not the
definition's unrelated presentation selector.

| Effect IDs | Checked character owner | Corresponding English panel phrase | Portrait file / texture |
| --- | --- | --- | --- |
| `0E` | Naruto Uzumaki (Classic) `01` | Vermillion Mode | `3NRT3PCT.CCS`, `name1` |
| `0F` | Sasuke Uchiha (Classic) `02` | Curse Mark Mode | `3SSK3PCT.CCS`, `name1` |
| `10` | Rock Lee (Classic) `03` | The Eight Gates Mode | `3ROC3PCT.CCS`, `name1` |
| `11` | Shikamaru Nara (Classic) `05` | Strategy Mode | `3SIK3PCT.CCS`, `name1` |
| `12` | Neji Hyuga (Classic) `06` | Byakugan Mode | `3NEJ3PCT.CCS`, `name1` |
| `13` | Sakura Haruno (Classic) `07` | Rage Mode | `3SKR3PCT.CCS`, `name1` |
| `15` | Haku `0A` | Ice Blade Mode | `3HAK3PCT.CCS`, `name1` |
| `16` | Zabuza Momochi `0B` | Demon Mode | `3ZBZ3PCT.CCS`, `name1` |
| `17,18` | Hinata Hyuga (Classic) `0C` | Byakugan Mode | `3HNT3PCT.CCS`, `name1` |
| `19` | Tenten (Classic) `0D` | Ninja Tool Mode | `3TEN3PCT.CCS`, `name1` |
| `1A` | Choji Akimichi (Classic) `0E` | Expansion Mode | `3TYO3PCT.CCS`, `name1` |
| `1B` | Ino Yamanaka (Classic) `0F` | Covered with Flowers Mode | `3INO3PCT.CCS`, `name1` |
| `1C` | Kiba Inuzuka (Classic) `10` | Food Pills Mode | `3KIB3PCT.CCS`, `name1` |
| `1D` | Shino Aburame (Classic) `11` | Beetle Mode | `3SIN3PCT.CCS`, `name1` |
| `1E` | Kankuro (Classic) `12` | Dance Mode | `3KNK3PCT.CCS`, `name1` |
| `1F` | Temari (Classic) `13` | Fan Dance Mode | `3TMR3PCT.CCS`, `name1` |
| `21` | The Third Hokage `16` | Reaper Death Seal Mode | `3HKG3PCT.CCS`, `name1` |
| `22` | Tsunade `54` | Mitotic Regeneration Mode | `3TNW3PCT.CCS`, `name2` |
| `27` | Jirobo `22` | Curse Mark Mode | `3JRB3PCT.CCS`, `name1` |
| `28` | Kidomaru `23` | Curse Mark Mode | `3KDM3PCT.CCS`, `name1` |
| `29` | Tayuya `24` | Curse Mark Mode | `3TYY3PCT.CCS`, `name1` |
| `2A` | Sakon `25` | Curse Mark Mode | `3SKN3PCT.CCS`, `name1` |
| `2B` | Kimimaro `26` | Curse Mark Mode | `3KMM3PCT.CCS`, `name1` |
| `2C` | The Yellow Flash `27` | Ultimate Mode | `3FOU3PCT.CCS`, `name1` |
| `2D` | The Yellow Flash `27` | Flash Mode | `3FOU3PCT.CCS`, `name2` |
| `2E` | Konohamaru Ninja Squad `28` | Ultimate Mode | `3KHM3PCT.CCS`, `name2` |
| `2F` | Konohamaru Ninja Squad `28` | Grandson Mode | `3KHM3PCT.CCS`, `name1` |
| `30` | Hanabi Hyuga `29` | Ultimate Mode | `3HNB3PCT.CCS`, `name2` |
| `31` | Hanabi Hyuga `29` | Byakugan Mode | `3HNB3PCT.CCS`, `name1` |
| `32` | The First Hokage `2A` | Hokage Mode | `3FIR3PCT.CCS`, `name1` |
| `33` | The Second Hokage `2B` | Ultimate Mode | `3SEC3PCT.CCS`, `name1` |
| `34` | The Second Hokage `2B` | Hokage Mode | `3SEC3PCT.CCS`, `name2` |
| `37` | Anko Mitarashi `2E` | Ultimate Mode | `3ANK3PCT.CCS`, `name1` |
| `38` | Anko Mitarashi `2E` | Curse Mark Mode | `3ANK3PCT.CCS`, `name2` |
| `39` | Naruto Uzumaki `39` | Vermillion Mode | `3NRW3PCT.CCS`, `name1` |
| `3A` | Sakura Haruno `3A` | Medical Mode | `3SKW3PCT.CCS`, `name1` |
| `3B` | Kazekage Gaara `3B` | Kazekage Mode | `3GAW3PCT.CCS`, `name1` |
| `3C` | Kazekage Gaara `3B` | Ultimate Defense Mode | `3GAW3PCT.CCS`, `name2` |
| `3D` | Kankuro `3C` | Show Mode | `3KNW3PCT.CCS`, `name1` |
| `3E` | Temari `3D` | Wind Robe Mode | `3TMW3PCT.CCS`, `name1` |
| `3F` | Granny Chiyo `3E` | Puppet Mastery Mode | `3CHY3PCT.CCS`, `name1` |
| `41` | Deidara `40` | Sky Eagle Mode | `3DDR3PCT.CCS`, `name1` |
| `42` | Neji Hyuga `41` | Byakugan Mode | `3NEW3PCT.CCS`, `name1` |
| `43` | Tenten `42` | Tool Use Mode | `3TEW3PCT.CCS`, `name1` |
| `44,45` | Rock Lee `43` | The Eight Gates Mode | `3ROW3PCT.CCS`, `name1` |
| `46` | Shikamaru Nara `44` | Strategy Mode | `3SIW3PCT.CCS`, `name1` |
| `47,48` | Might Guy `45` | The Eight Gates Mode | `3GUW3PCT.CCS`, `name1` |
| `49` | Kakashi Hatake `46` | Mangekyo Sharingan Mode | `3KKW3PCT.CCS`, `name1` |
| `4A` | Itachi Uchiha `47` | Tsukuyomi Mode | `3ITW3PCT.CCS`, `name1` |
| `4B` | Kisame Hoshigaki `48` | Samehada Mode | `3KSW3PCT.CCS`, `name1` |
| `4C` | Sasori (Hiruko) `4C` | Poison Mode | `3SCH3PCT.CCS`, `name1` |
| `4D` | Granny Chiyo (Taijutsu) `4D` | Surprise Mode | `3CYB3PCT.CCS`, `name1` |
| `4E` | Granny Chiyo (Taijutsu) `4D` | Veteran Mode | `3CYB3PCT.CCS`, `name2` |
| `50` | Kiba Inuzuka `4E` | Fanged Beast Mode | `3KIW3PCT.CCS`, `name1` |
| `51` | Shino Aburame `4F` | Beetle Mode | `3SNW3PCT.CCS`, `name1` |
| `52` | Hinata Hyuga `50` | Byakugan Mode | `3HNW3PCT.CCS`, `name1` |
| `53` | Hinata Hyuga `50` | Guardian Dance Mode | `3HNW3PCT.CCS`, `name2` |
| `54` | Choji Akimichi `51` | Super Expansion Mode | `3TYW3PCT.CCS`, `name1` |
| `55` | Ino Yamanaka `52` | Blooming Flowers Mode | `3INW3PCT.CCS`, `name1` |
| `56` | Jiraiya `53` | Sannin Mode | `3JRW3PCT.CCS`, `name1` |
| `57` | Tsunade `54` | Sannin Mode | `3TNW3PCT.CCS`, `name1` |
| `58,59` | Shizune `55` | Medical Mode | `3SZW3PCT.CCS`, `name1` |
| `5A` | Asuma Sarutobi `56` | Fist Strike Mode | `3ASW3PCT.CCS`, `name1` |
| `5B,5C` | Kurenai Yuhi `57` | Haze Dance Mode | `3KRW3PCT.CCS`, `name1` |
| `5D` | Orochimaru `59` | Sannin Mode | `3ORW3PCT.CCS`, `name1` |
| `5E` | Kabuto Yakushi `5A` | Super Recovery Mode | `3KBW3PCT.CCS`, `name1` |
| `5F,60` | Yamato `5B` | Secret Wood Style Mode | `3YMT3PCT.CCS`, `name1` |
| `61` | Sai `5C` | Fast Brush Mode | `3SAI3PCT.CCS`, `name1` |
| `62` | Sai `5C` | Super Brush Mode | `3SAI3PCT.CCS`, `name2` |
| `63` | Sasuke Uchiha `5D` | Flash Sword Mode | `3SSW3PCT.CCS`, `name1` |
| `64` | Sasuke Uchiha `5D` | Thunderclap Mode | `3SSW3PCT.CCS`, `name2` |

Shared phrases do not distinguish paired mechanics: `17/18`, `44/45`,
`47/48`, `58/59`, `5B/5C` and `5F/60` require their numeric IDs or
another established mechanical qualifier. Conversely, `2C/33/37` all say
Ultimate Mode in different characters' assets. The same words do not identify
one cross-character status.

Effect `22` also occurs in UJ records 56/57 of excluded character row
`19`; the dedicated Tsunade owner is row `54`, record 191. The
Tsunade-qualified phrase above follows her texture 2, rather than assigning a
name to the excluded row. Konohamaru's `2E` phrase is texture 2 even though
its class-7 application mismatches his controller association; the
[Class-7 entry evidence](../characters/awakening.md#exact-class-7-uj-entry)
owns that difference. A UJ title describes the selected move and can be shared
by records with different post-effects; it is not itself an effect title.

#### Transformed-character identities

These are the character identities selected by
`fighter_add_inherent_form_effect` and the effect-to-form mapping, not
ordinary-panel status names. [Awakening](../characters/awakening.md#effect-to-form-mapping-and-resource-replacement)
owns reconstruction and the complete selected UJ-record evidence.

| Effect | Checked form character ID | Retail character identity |
| ---: | ---: | --- |
| `68` | `2F` | Naruto Uzumaki (Nine-Tailed) |
| `69` | `30` | Second Stage Sasuke Uchiha |
| `6A` | `31` | Loopy Fist Lee |
| `6B` | `32` | Possessed Gaara |
| `6C` | `33` | Super Choji |
| `6D` | `34` | Second Stage Jirobo |
| `6E` | `35` | Second Stage Kidomaru |
| `6F` | `36` | Second Stage Tayuya |
| `70` | `37` | Second Stage Sakon |
| `71` | `38` | Second Stage Kimimaro |
| `72` | `49` | Nine-Tailed Fourth Awakened State |
| `73` | `4B` | Sasori (Puppet) |

#### IDs without a fixed retail status name

The following table, together with low IDs `01/0D` above, accounts for the
37 IDs without an established fixed retail status name. The checked scope is
the complete notification, association, UJ, portrait-label and direct
condition/item joins. It does not exclude an indirect owner elsewhere.

| Effect IDs | Exact checked identity or limit |
| --- | --- |
| `14` | Association row `09`, an excluded filler definition with no dedicated portrait asset |
| `20` | Association row `15`, an excluded filler definition with no dedicated portrait asset |
| `24` | Association row `19`, an excluded filler definition with no dedicated portrait asset |
| `25` | Association/UJ row `1B`, record 60; excluded filler definition with no dedicated portrait asset |
| `26` | Association/UJ row `1C`, record 63; excluded filler definition with no dedicated portrait asset |
| `35` | Association row `2C`, an excluded filler definition with no dedicated portrait asset |
| `36` | Association row `2D`, an excluded filler definition with no dedicated portrait asset |
| `23` | Successor created by `effect_22_destroy`; auxiliary selector `-1` skips label construction. Tsunade's association with the chain does not supply a separate title |
| `40,4F` | No association, non-sentinel UJ post-effect or notification-map entry in the checked tables. A recipient's default/second texture cannot recover a fixed owner or title |
| `65` | Item `73` -> effect `65`. Its personal-code byte is in excluded character row `4A`, with no dedicated assets. Interleaved word `12` is not read by the dispatcher |
| `66,67` | No association, non-sentinel UJ post-effect or notification-map entry in the checked tables; auxiliary selector defaults to the recipient's texture 1 |
| `74..7A` | `condition_list_effect_dispatch` inputs `41..47`, respectively |
| `7B` | Condition input `57` |
| `7C` | Condition input `56` |
| `7D` | Condition input `48` |
| `7E..89` | Condition inputs `49..54`, respectively |

Notification `12` has the English phrase Ultimate Mode! in record `96`.
It is not established as effect `65`'s label: that ID is absent from
`effect_notification_map`, and the item's interleaved word has no recovered
consumer. The similarly named character-panel Ultimate Mode assets are a
different presentation route.

### Auxiliary category-1/2 visuals

Successful category-1/2 application appends a separate `EffectAuxVisual`,
original class `ccMode1Panel`. `effect_aux_selector_table` controls its
resource choice:

| Effect ID(s) | Signed selector | Proven constructor result |
| --- | ---: | --- |
| `22,2D,2E,30,34,38,3C,4E,4F,53,62,64` | `1` | Uses pointer-array index `1`, string `TEX_mode1name2` |
| `23` | `-1` (stored table byte `FF`) | Sets `EffectAuxVisual.countdown` to `10` and skips resource construction |
| Every unlisted category-1/2 ID | `0` | Uses pointer-array index `0`, string `TEX_mode1name1` |

The selector is signed; FF means -1 rather than index 255. Effect 65 follows
default selector 0 and 3C follows 1, independently of interleaved word 12.

The private lifetime starts at -1. Selector -1 or a missing resource changes
it to 10; otherwise the owned primary's completion changes it to 3.
Subsequent passes decrement and return 1 below 1, triggering unlinking.
There is no gameplay-node backpointer, and node removal never searches this
list. Replacement can append a second visual while the first completes;
visual overlap does not imply same-ID gameplay stacking.

`effect_aux_visual_destroy` (`0x003039D0`) releases its two animation players
and composition through their native destruction owners. With a present
common resource, `effect_aux_visual_construct` (`0x00303AA0`) allocates the
players and forwards them to `animation_attach_named` even if a player
allocation returned null; animation binding assumes valid player/resource
roots. Gameplay insertion precedes this presentation construction, which has
no rollback of that node. This ownership differs from `4A`'s private
controllers as well as from the independent Fukidasi list.

### Fukidasi notification objects

`fukidasi_create` produces separate side-list `Fukidasi` objects:

| Notification codes | Object family |
| --- | --- |
| `1,2,14` | Numeric/recovery |
| `5,6,7,8,0E,0F,10,11` | Paired/parameter-up-down |
| `9,0A,0B,0C,0D,12,13` | Single Fukidasi |
| `4` | Fixed/condition |
| `0,3,>14` | No allocation |

Their code, state, callback argument, side and next pointer are named fields.
`fukidasi_list_update` invokes their callback and removes on return zero,
the inverse of gameplay/auxiliary generic traversal. Update/unlink/draw do not
call gameplay-effect APIs.

Numeric display values cap at 999. Code 1 rounds magnitude ×100; codes 2/14
round ×20. Thus items 5D/67's HP requests display 999 (unbounded 1000),
item 71 displays 500, item 5D's extra 2.5 displays 50, and immediate 0C's
15.0 displays 300. These are display transformations rather than resource
amounts. Code 11's duplicate suppression applies only when the third factory
argument is zero.

Authored UI-record mappings are:

| Factory code | UI record(s) |
| ---: | --- |
| `1` | `81` |
| `2,14` | `82` |
| `9` | `9A` |
| `0C` | `98` |
| `0D` | `99` |
| `12` | `96` |
| `13` | `97` |
| `5` | `8F / 92` |
| `6` | `90 / 92` |
| `7` | `91 / 93` |
| `8` | `91 / 92` |
| `0E` | `90 / 93` |
| `0F` | `82 / 9B` |
| `10` | `82 / 94` |
| `11` | `9C / 92` |
| `4` | fixed `8E / 8D` |

The source tables are `fukidasi_numeric_records`, `fukidasi_single_records`
and `fukidasi_paired_records`. Their strings/families establish presentation
labels rather than gameplay meaning, countdown or stacking.

## Direct application mappings

### Record `0x99` callback

`projectile_record99_callback` (`0x0073FCC0`) applies effect 0D/requested
150/route 1 for object record 99, queues notification 7, then performs base
cleanup. Effect 0D is outside the low-ID normalization switch, so 150 is
retained. Nearby poison-named strings do not establish this callback's
semantic name.

### Other direct numeric mappings

`object_apply_effect1` uses these object values:

| Object value | Requested call |
| ---: | --- |
| `0xAC` | Effect `07`, requested `100`, route `1` |
| `0xAF` | Effect `01`, requested `120`, route `1` |

Both requests still normalize. `projectile_apply_effect` forwards a dynamic
ID/countdown to its resolved fighter, with route 1. Its fourth byte equal
to 1 adds a hit-rejection guard; other values bypass that guard.

`controller_apply_effect` applies to its controller fighter only while its
blocked field is zero, then writes `requested_effect` even after failed
construction. That field is a request cache rather than membership.

### Resident condition-list dispatcher

`condition_list_effect_dispatch` requires coordinator state zero, a list
and both fighters. Its default-countdown/route-1 mapping is:

| Input code(s) | Effect ID(s) | Rule |
| --- | --- | --- |
| `0x41..0x47` | `0x74..0x7A` | `effect = code + 0x33` |
| `0x48` | `0x7D` | explicit |
| `0x49..0x54` | `0x7E..0x89` | `effect = code + 0x35` |
| `0x56` | `0x7C` | explicit |
| `0x57` | `0x7B` | explicit |
| `0x5B` | `0x39` | explicit |

Routing makes 7D linked plus local and 7E..89 linked-only.
Code 55 instead writes the other fighter's HP to 0.5. User-facing names for
these configuration codes remain unproven.

### Additional requested effect lifetimes

Other resident and BTL sources request these effect/countdown combinations,
all with route 1:

| Effect | Requested countdowns |
| ---: | --- |
| `07` | -1, 150, 120, 85, 80 |
| `00` | 200 |
| `06` | 600, 300, 250 |
| `01` | 100 |
| `04` | 250, 360 |
| `39` | -1 |
| `0C` then `05` | -1 then -1, in each of two support paths |

Explicit values are requested rather than guaranteed stored countdowns.
Low-ID requests still normalize; a requested value therefore cannot be
used as the stored lifetime without the receiver's scalar and status gates.
These mappings do not establish indirect or dynamically selected reachability.

### Character callback's random status/resource branch

`character_random_status_resource_update` enters this branch only at current
action 3 with the primary timeline event flag set:

| Cursor | RNG call bounds and branch | Result |
| ---: | --- | --- |
| `30` | Draw `0..1`: `0` / `1` | Effect `03` / `02` |
| `40` | Draw `0..1`: `0` / `1` | Scaled HP request `0.025` / effect `0C` |
| `50` | Draw `0..5`: `0,4` / `1,2,3` / `5` | Scaled HP request `0.025` / effect `05` / no status or HP request |
| `60` | Draw `0..15`; `7` selects effect `09`. After a miss, draw `0..7`; `3` selects `08`. After that miss, draw `0..7`; `1` selects `0B` | First matched effect, or no status/HP request if all tests miss |
| `75` | Draw `0..3`: `2` / every other value | Scaled HP request `0.05` / `0.025` |
| Every other cursor | No random branch | No status or HP request |

Bounds use [the resident inclusive modulo contract](../../runtime/randomness.md#mt-wrappers).
These are branch bounds rather than measured frequencies.

A selected effect uses requested 450/route 1, followed by event 0 even after
failed application. HP branches instead scale with fighter as both source
and receiver, apply HP flags 1/0 and separately queue notification 1 if the
manager exists. They consume no item slot and debit no chakra.
The status/HP requests are mutually selected inside this callback; that
does not prevent later coexistence with other effects. Action 3 alone does
not establish a gameplay name or full native trigger reachability.

## Direct application and removal owners

Live MCP references and the containing bodies recover the following direct
owners in retail NA2. These lists describe decoded calls; an absent reference
does not prove that an indirect caller or an unanalysed path is absent.
`effect_apply` also calls itself for linked routing.

### Resident application owners

| Owner | Live address | Requested effects / source |
| --- | ---: | --- |
| `condition_list_effect_dispatch` | `0x001FD330` | Authored condition-code mapping above |
| `awakening_enter_class_seven` | `0x0020D690` | Selected Jutsu effect after family cleanup |
| `input_sector_widen_state_b` | `0x0020D910` | Fighter-specific association/entry selection |
| `fighter_resource_effect_request` | `0x00227CE0` | Caller ID/countdown after resource/state policy |
| `item_immediate_dispatch` | `0x002369D0` | Metadata direct-effect lane |
| `item_selected_resolve` | `0x00236C70` | Selected-use metadata fallback |
| `character_random_status_resource_update` | `0x0025CEE0` | RNG-selected `02/03/05/08/09/0B/0C`, requested `450` |
| `naruto_channel2` | `0x00299100` | `39`, default, under its low-HP policy |
| `sakura_hit_response` | `0x0029B8A0` | `04`, requested `360` |
| `sasori_hiruko_hit_response` | `0x002D5320` | `07`, requested `120` |
| `naruto_classic_effect09_toggle` | `0x002F2D70` | Fighter `57` rising edge: `09`, requested `9999` |
| `effect_22_destroy` | `0x003037C0` | Successor `23`, default |
| `fighter_add_inherent_form_effect` | `0x00305FF0` | Constructor-owned `68..73`, requested `-2` |
| `effect_apply_outcome` | `0x00307690` | Caller ID, default |
| `field_item_pickup_resolve` | `0x00374190` | Metadata direct effect; code `06` adds `0C` |

Every recovered external resident request uses route `1`. Their surrounding
native actions can change controller, marker, resource or family state; an
effect request is only one part of those actions.

### BTL application owners

The live direct census contains 27 call sites in these 20 bodies:

| Owner | Live address | Requested effects / source |
| --- | ---: | --- |
| `item_pickup_callback` | `0x0070BC20` | Code `06` extra `0C` |
| `item_status_dispatch` | `0x00711720` | The 19-row item-status table |
| `transient_actor_lineage_notify` | `0x0072E740` | Object-code metadata direct effect |
| `projectile_apply_effect` | `0x00730070` | Caller ID/countdown |
| `projectile_action_response` | `0x00730140` | Two `07` default requests |
| `object_apply_effect1` | `0x00739170` | Object `AC:07/100`, `AF:01/120` |
| `projectile_record99_callback` | `0x0073FCC0` | `0D/150` |
| `effect07_source_a` | `0x00743800` | `07`, default |
| `projectile_poison_explosion_update` | `0x00745AA0` | `07/150` |
| `effect07_source_duration85` | `0x0075C3D0` | `07/85` |
| `effect07_source_duration80` | `0x0075FC70` | `07/80` |
| `controller_apply_effect` | `0x0077F480` | Caller ID/countdown; stores request cache |
| `effect07_source_b` | `0x007C0B60` | Two `07` default requests |
| `effect00_source_duration200` | `0x007F55C0` | `00/200` |
| `effect06_source_duration600` | `0x007FC020` | `06/600` |
| `effect01_06_source` | `0x00802540` | `06/300`, `01/100` |
| `effect07_source_c` | `0x0083F450` | `07`, default |
| `effect06_04_source` | `0x0085F850` | `04/250`, `06/250` |
| `support_attack_11` | `0x0088D680` | `0C` then `05`, both default |
| `support_attack_0c` | `0x0088D780` | `0C` then `05`, both default |

All 27 sites supply route `1`. At `0x00745BCC`, raw instructions establish
`a3 = 1` before the call, despite the decompiler omitting its fourth
argument. No listed site explicitly requests inherent effects `68..73`.

### Exact-ID and bulk-removal owners

The seven resident exact-ID removal owners are `awakening_enter_class_seven`,
`awakening_reconcile` (`0x0020DDC0`), `input_sector_widen_state_b`,
`effect_54_cancel_valid_state` (`0x002E8DC0`),
`effect_54_cancel_invalid_state` (`0x002E99A0`),
`naruto_classic_effect09_toggle` and `field_item_pickup_resolve`.
Each supplies reason `1`; their scoped families and exact IDs are described
above. The live BTL census contains 15 exact-ID removal sites:

| Owner | Live address | Exact-ID scope / number of sites |
| --- | ---: | --- |
| `item_pickup_callback` | `0x0070BC20` | `04/06/07/0A`; four |
| `item_panel_activate` | `0x00711380` | Code `0D` cleanse `04/06/07/0A`; four |
| `controller_remove_requested_effects` | `0x0077F4E0` | Two actor subrecord caches or one supplied controller cache; three |
| `skill_control_cleanup` | `0x00794150` | Two dynamic actor effect caches; two |
| `btl_effect00_01_controller_enter_state` | `0x00801890` | State `3`, subrecord `+0x4CC` fighter `00/01`; two |

All 15 supply reason `1`; `0x00801BB4` supplies `a2 = 1` for the first
`00` call at `0x00801BCC`, which the decompiler renders without the reason.
Cache cleanup records a request rather than proving successful insertion.
`controller_remove_requested_effects` resets its cached ID to `-1` after
the eligible cleanup path, even if the pointer/hub existence check fails.
Its fighter-existence helper `downed_override_allowed` (`0x003083A0`)
checks only nonnull argument and battle hub; it does not inspect membership.

Direct ordinary-category cleanup owners are `fighter_end_exchange`
(`0x00216A60`, reason `1`), `fighter_paired_event` (`0x00216D00`, reason `1`),
`jutsu_connection_cleanup` (`0x00216EA0`, reason `2`) and
`jutsu_post_cinematic_update` (`0x0024ED40`, reason `3`).
The sole decoded direct `effect_force_clear` caller is `fighter_cleanup`
(`0x00215720`). `fighter_remove_effects_0_1` (`0x00306B00`) separately calls
`effect_remove_node`; generic traversal/destruction owns other removal paths.

`effect_create_node` has only `effect_apply` as a decoded direct caller.
The decoded resident callers of `effect_remove_node` are that creator,
`effect_remove_id`, `effect_remove_ordinary_classes`, `effect_force_clear`,
`effect_update` and `fighter_remove_effects_0_1`.
No direct BTL references were recovered for create-node, remove-node,
ordinary-category cleanup or force-clear. ETC has no recovered direct
references to any of these six application/removal interfaces.

## Exact BTL generic-list helpers

Both embedded effect lists use the named generic node/list helpers in
[Battle entities](../session/battle_entities.md#generic-intrusive-node-and-list-contracts).
Their slot contracts and address audit belong to that owner. The annotation
names distinguish append, unlink/destruction, clear and the primary/secondary
passes.
