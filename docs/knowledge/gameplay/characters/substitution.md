# Substitution Knowledge

## Research coverage

Established: acceptance, debit, seven transition phases, conditional exit/rate
cleanup, physical-input timing, effect/item exceptions, two AI sentinels and
six character timing writers.
Open: exceptional-record reachability, observed random distributions,
indirect table reloads and uninterrupted guard-age wrap.
Names come from `@annotations/NA2`; all addresses are live.

## Stable references

Retail NA2 (`SLPS-25837`) uses resident `SLPS_258.37` and `BTL.BIN`.
Source identities and address conventions are owned by
[Retail game file identities](../../game/files/file_identities.md#address-conventions).

Coverage is bounded to the inspected resident ELF and BTL paths. The 78-owner,
3,444-record inventory is static; table membership does not prove gameplay
reachability. Annotation comments hold per-routine details. The bounded Practice
observation is retained separately from static conclusions.

This document owns substitution acceptance, cost, transition, input-history
timing, sentinel exceptions and character timing mutations. Related owners are
[Hit response](../combat/hit_response.md),
[Chakra and guard](../combat/chakra_and_guard.md),
[Controller input](../../runtime/controller_input.md),
[Character action callbacks](character_action_callbacks.md),
[Combo accounting](../combat/combo_accounting.md),
[Battle AI](../session/battle_ai.md),
[Battle item inventory](../projectiles_and_items/battle_item_inventory.md),
[Battle HUD](../session/battle_hud.md#support-gauge),
[Match outcomes](../session/match_outcomes.md#timer-path), and
[Battle lifecycle](../session/battle_lifecycle.md).

## Substitution-cost mechanism

`hit_intercept` (`0x002297D0`) spends `1.0` chakra and clamps the
remainder to zero when its charged-debit branch runs.
`input_match_trigger_binding` (`0x00229130`) independently requires at
least `1.0` chakra for resource-validating callers. Acceptance and spending
are separate decisions.

`Fighter.hp`, `chakra` and `support_gauge` are distinct resources.
The battle clock supplies no per-substitution cooldown; its accumulator belongs
to [Match outcomes](../session/match_outcomes.md#timer-path).

### Conditional native spending and commit effects

Charged entry creates its presentation through `substitution_spawn_entry_effect`
and dispatches its sound before checking the debit exemptions. Arithmetic is
skipped when an active effect has behavior flag `0x80`
(`effect_flag80_active`), `chakra_debit_inhibit == 1`, or
`status_flags & 0x02`. Those exemptions preserve the charged-entry
presentation and do not remove the acceptance predicate's resource check.
An uncharged entry skips the entire charged block.

When the debit runs, it also writes `15.0` to `chakra_history_old`.
Active behavior-flag queries require a nonzero `AwakeningEffectNode.lifetime`;
effect membership queries have different rules.

Every commit stores `substitution_route`, clears `action_lock`, and
enters major/substate `0/8` through `fighter_set_action_state`. If
`hit_rejection.flags & 4` is clear, it stages integer `-20` and float
`-20.0` rejection values and marks them pending. An existing pending count
is preserved. Activation belongs to the common fighter updater
([Hit response](../combat/hit_response.md)).

Routes with bit `0x200` or low nibble `2` omit the statistics/event tail.
Other routes increment `stats[11].count`, cap it at `9999`, and update
its maximum unless `status_flags & 0x01`; they then request result event
`1` with amount `1` through `fighter_add_result_event`. Thus supplied
routes `0x211` and `2` omit this tail, while `0x11/0x21/0x41`
include it. A free debit and omission of this tail are separate decisions.

For the `0x11` route family, including supplied `0x211`,
`hit_intercept` can add bit `0x100` when the opponent's capture
classification is zero and the facing comparison matches. The supplied route
value therefore need not equal the stored route.

### Native substitution transition and exit

`fighter_dispatch_action_update` dispatches `0/8` to
`paired_state_update` (`0x00229B80`). Primary animation event `0`
starts `substitution_phase = 1` and clears `substitution_phase_calls`.

| Phase | Native transition |
| ---: | --- |
| `1` | `paired_transition_start_effect` uses selector `1` for route low nibble `1`, `0` for nibble `2`; stages rejection if needed, enters phase `2`, and initializes movement. |
| `2` | Adjusts movement toward zero/opponent values; advances to `3` when `paired_transition_flags` or `paired_transition_remaining` is zero, or the previous phase count is at least `5`. |
| `3` | Opponent `0/10` selects `6`; otherwise opponent grounded bit `0x80` selects `4`, else `5`. Updates its own grounded bit and movement/animation setup. |
| `4` | Advances to `7` on either zero transition field or previous count at least `9`. |
| `5` | Initially matches opponent movement; advances immediately to `7` with its own grounded bit, otherwise on either zero transition field or previous count at least `5`. |
| `6` | Tracks opponent movement/direction while the opponent remains in `0/10`, otherwise advances to `7`. |
| `7` | Clears opponent `pending_action`, own `action_lock` and own `guard_state`, then calls `guard_update_stance`. |

These counts measure handler calls; no wall-clock duration is established.
Phase `3` uses relative-placement preset `6` instead of `4` through
`fighter_place_relative_preset` when the stored route has bit `0x100`.

With the cleared action lock, `guard_update_stance` enters `0/5` when
grounded and logical guard `0x10000000` is held, `0/0` when grounded
and released, or `3/0x21` when airborne. The exit clears `guard_state`,
not the separate `guard_input_timing`.

Leaving `(0,8)` runs `substitution_exit_cleanup` (`0x00229050`). It clears
phase/count and the whole action lock, restores both fighters'
`update_rate_override` to 1.0, and resets the caller's presentation factor,
amount, durations and style. It retains `substitution_route`.
`substitution_release_special_actor_rate` (`0x007763D0`) receives the
opponent and performs the same side/selector-0 special-actor lookup twice
before either release. Each nonnull result reaches
`special_actor_restore_fighter_rate` (`0x00786F70`): an active local latch
and valid associated fighter restore that fighter's `secondary_rate` to
`0x100`, then the actor's latch clears. These calls do not request actor
retirement, unlink or delete it; this is rate cleanup rather than a two-side
actor sweep. Skill lifetimes belong to
[Battle auxiliary services](../session/battle_auxiliary_services.md#btl-skill-service-callbacks-and-ownership).

`fighter_init` clears both guard fields, route, phase and phase count.
This establishes fresh-object initialization, not a once-per-battle call count.

## Acceptance predicate

`input_match_trigger_binding` is the shared upstream substitution gate for
the ordinary hit routes. Their varying arguments and supplied commit routes are:

| Branch | Selector / response / resource validation | Successful commit |
| --- | --- | --- |
| `hit_classify_pair`, effect `9` attempt | selector `0`, response `6`, or selector `5` with `response_select_substate`; validation `0` | route `0x211`, uncharged |
| `hit_classify_pair`, ordinary fallback | same definition, selector and response; validation `1` | route `0x11`, charged |
| `hit_route_accepted`, mode `2` | selector `5`, `response_select_substate`, validation `1` | route `0x41`, charged |
| `hit_route_accepted`, mode `1` | selector `5`, `response_select_substate`, validation `1` | route `0x21`, charged |

Each requires a nonzero predicate result. Direct ordinary callers use selectors
`0` or `5`; none supplies rejected selector `8`. The selected
item/status-`9` route commits separately without this predicate.

### Input path and history

`input_build_logical_mask` (`BTL.BIN`, `0x006EFDC0`) translates
either physical guard binding `6` or `7` into logical
`0x10000000`. `fighter_copy_input_outputs` publishes the logical mask,
stick magnitude and direction into the fighter.

Substitution instead consumes physical pressed input from the circular history:

| Named field | Role |
| --- | --- |
| `BattleInput.bindings[6/7]` | Configurable signed physical masks, read by `bindings_get_by_index` (`0x006EF7F0`) |
| `BattleInput.records` | `0x18`-byte `InputRecord` ring |
| `BattleInput.current_index` | Newest record |
| `BattleInput.capacity` | Wrap count |
| `InputRecord.pressed` | History word `1` consumed by substitution |

`input_history_match` (`0x006EFAC0`) searches the current record plus
the normalized number of earlier records, newest first, with no initial skip,
subset matching and no mask filtering. The current logical mask alone does
not determine acceptance.

The separate signed `Fighter.guard_input_timing` counts held-guard
maintenance calls. The ordinary path rejects nonnegative ages at least
`16`; negative values use the sentinel rules below.

### Per-attack timing byte

The signed `ActionRecord.substitution_timing` byte selects the history window:

| Effective timing | Behavior |
| ---: | --- |
| `0` | Current history record only |
| `1` | Current plus one earlier record |
| `2` | Current plus two earlier records |
| `3` | Current plus three earlier records |
| `4..127` | Clamped to `3` |
| negative `-n` | Require remainder `2n` modulo `2n + 1`, then search only the current record |

The negative gate uses unsigned
`(Fighter.random_word XOR 0x80000000) % (2n + 1)`.
`fighter_update_countdowns` stores one complete MT19937 word from
`effect_context_bit` before `fighter_grounded_rejection_update` and
`fighter_update_side_contact_latch`; `fighters_update` runs this
maintenance for every linked fighter. Multiple predicate calls during that
fighter update, including the effect/fallback pair, reuse the word.
The predicate draws nothing itself
([Runtime randomness](../../runtime/randomness.md)).

For a uniformly selected 32-bit word, the exact pass fraction is
`floor(2^32 / (2n + 1)) / 2^32`:

| Raw timing | Exact fraction | Nominal approximation |
| ---: | --- | --- |
| `-1` | `1431655765 / 4294967296` | Just below `1/3` |
| `-2` | `858993459 / 4294967296` | Just below `1/5` |
| `-3` | `613566756 / 4294967296` | Just below `1/7` |

Fighter-update scheduling and other shared MT consumers can correlate samples;
these fractions are not measured battle success rates.

When `ActionRecord.category & 0x000C0000` is nonzero, raw timing zero
becomes effective `-1`: modulo-three eligibility, current record only.
After normalization, ordinary guard age must remain below `16`, then
binding `6` is searched before binding `7`.

### Negative guard-age sentinel and temporary-effect ID 9

After the earlier eligibility checks, negative `guard_input_timing`
skips timing normalization, random reduction, the held-age limit and both
history searches when `contact_attack_source` has state `0`. States
`1/2` permit the same shortcut only without temporary effect `9`.
The source's state is `GenericNode.node_kind`.

This shortcut precedes ordinary non-player-mode rejection, so it can admit a
CPU-mode fighter. It preserves the earlier fighter, response, source and record
flag gates, and still runs the final resource check when requested.

`fighter_has_effect9` scans the fighter's bounded effect list by effect ID;
it does not require a nonzero lifetime. `effect_update` refreshes the
sentinel to `-2` through `guard_set_input_timing` before the new random
word and hit processing.

With effect `9`, `hit_classify_pair` first tries validation disabled
and route `0x211`, uncharged; only failure reaches ordinary validation.
The result can be automatic and free when the sentinel shortcut is available,
or free but timing/input-gated when it is not.

The bounded direct producer search identifies Kurenai's awakened controller
callback. `kurenai_character_record` (`0x0057FD20`) selects
`kurenai_callbacks` (`0x0057ACE0`); its channel-2 callback retains the
existing annotation name `naruto_classic_effect09_toggle`
(`0x002F2D70`), although the verified character ID is Kurenai
`0x57`. Outside context mode `6`, it watches awakened
`contact_flags & 0x20` against
`KurenaiSubstitutionState.previous_awakened_marker`: rising edges request
`effect_apply` with ID `9`, duration argument `9999` and notify
`1`; falling edges request `effect_remove_id` with reason `1`.
The literal duration argument does not establish a unit. This callback does
not distinguish associated effects `0x5B/0x5C`, so the exception cannot
be assigned to just one awakening variant.

Item/status ID `9` has separate producers and consumers.
`item_selected_resolve` (`0x00236C70`) checks its own state and the
current record's category-`0x200` guard, then directly commits route
`2`, uncharged. It checks no substitution predicate, timing byte or guard
history. `item_input_dispatch` requires item-use input and an available
manager item. This is a separate free item/status substitution.

#### Guard-age maintenance and other sentinel sources

`guard_update_input` increments negative `guard_input_timing` toward
zero regardless of guard input. Nonnegative values clear on release and
increment while held. One isolated `-2` write therefore provides at most
two maintenance calls with a negative value, depending on predicate order;
effect `9` repeatedly refreshes it.

During positive hit-stop, `fighter_update_movement_slot` skips ordinary
animation/action callbacks but still translates/selects player input and applies
the same signed age update when controller mode
`((control/state halfword & 0x1FF) >> 5) == 0`.
The separate guard-active state and stance lifecycle belong to
[Chakra and guard](../combat/chakra_and_guard.md#guard-input-and-action-lifecycle).

Held-age increments are unsaturated; `guard_state` saturates separately.
**Derived static consequence:** from zero, 32,768 uninterrupted held-input
increments wrap `guard_input_timing` to `-32768`. If other gates pass,
it then follows the sentinel shortcut and continues toward zero even after
release. This is an arithmetic consequence, not an observed exploit or proof
that battle states permit the required uninterrupted sequence.

`ai_dispatch_state` (`BTL.BIN`, `0x006FB840`) has two additional
sentinel branches selected by `ai_state_handlers` (`0x008C3810`):

| Zero-based AI state | Branch label / live address | Sentinel behavior |
| ---: | --- | --- |
| `20` (`0x14`) | `ai_substitution_state20`, `0x006FBD7C` | Conditional `-2`; Practice key `0x11 == 1` first switches to state `18` and returns |
| `39` (`0x27`) | `ai_substitution_state39`, `0x006FC2A8` | Direct `-2` |

These are branches inside the dispatcher, not independent routines. Neither
requires the effect-`9` scanner. The actor comes from
`ai_slot_fighter_lane`; state selection and input production belong to
[Battle AI](../session/battle_ai.md#direct-state-constructors).

### Attack-record ownership and clean-ELF inventory

`fighter_load_character_record` initializes the fighter from
`AwakeningCharacterRecord.action_count`, `default_actions` and,
when nonnull, `alternate_actions`. It selects the working base for
`Fighter.actions`, `initial_actions` and initially `current_record`.

`fighter_enter_action_record` selects the signed action index and the
corresponding `0x54`-byte record. An incoming defender definition normally
belongs to the attacker's table. Owner ID plus record index identifies the
native record; `ActionRecord.display_name` references its retail move name.

All 74 primary metadata owners have a null optional action base and use their
default table. The timing byte is the selected record's
`substitution_timing`; table relocation and live mutation can change it.

The 3,428 primary records contain:

| Raw timing | Records | Predicate policy |
| ---: | ---: | --- |
| `-3` | 6 | Nominal `1/7`, current record |
| `-2` | 30 | Nominal `1/5`, current record |
| `-1` | 319 | Nominal `1/3`, current record |
| `0` | 2,794 | Current record, except category conversion |
| `1` | 261 | Current plus one |
| `2` | 18 | Current plus two |

Of the raw-zero records, 148 have conversion category bits and become effective
`-1`. No primary record has raw `3` or above. These counts include
dummies, transitions and non-damaging actions, not just distinct reachable attacks.

Primary-record rejection flags occur on 109 records: 91 have
`0x00008000`, 18 have `0x02008000`, none has only `0x02000000`.
Eighty-four also have exceptional timing: 83 effective `-1`, one
effective `-3`. Their flags reject before timing is read.

Authored `response_selector` values are `0x00..0x1E` and `0xFF`;
none uses `0x1F..0x27`. Context, callbacks and repeated hits support a
broader final response domain.

Four auxiliary metadata owners each have four records and no optional base:

| Auxiliary ID | Metadata annotation | Action-table annotation |
| ---: | --- | --- |
| `0x1A` | `auxiliary_1a_character_record` (`0x0059C7A0`) | `auxiliary_1a_actions` (`0x0059C630`) |
| `0x1D` | `auxiliary_1d_character_record` (`0x0059CF80`) | `auxiliary_1d_actions` (`0x0059CE10`) |
| `0x1E` | `auxiliary_1e_character_record` (`0x0059D750`) | `auxiliary_1e_actions` (`0x0059D5E0`) |
| `0x1F` | `auxiliary_1f_character_record` (`0x0059DF20`) | `auxiliary_1f_actions` (`0x0059DDB0`) |

Their IDs are established; player-facing owner names are not inferred.
Record `1` of each has category `0x00040000`, raw timing zero and no
rejection bit. Record `3` has category `0x00080000` and raw zero;
only ID `0x1F` record `3` has rejection bit `0x00008000`.
All eight use response selector `0x0F`, normally `0x36/0x37`, both
whitelisted. Seven therefore have the exact modulo-three current-record policy
when other gates pass; `0x1F/3` rejects before timing. Specific gameplay
reachability remains open.

Including auxiliaries gives 78 owners and 3,444 records:

| Timing | Combined raw records | Combined effective records |
| ---: | ---: | ---: |
| `-3` | 6 | 6 |
| `-2` | 30 | 30 |
| `-1` | 319 | 475 |
| `0` | 2,810 | 2,654 |
| `1` | 261 | 261 |
| `2` | 18 | 18 |

Conversion affects 156 records; 790 have exceptional effective timing.
The combined rejection total is 110 (92 with `0x00008000`, 18 with
`0x02008000`); 85 also have exceptional timing.

#### Runtime-mutated action records

The clean tables are templates. `fighter_action_record` with selector
`-3` resolves the current live record; six records have direct
character timing writers. Template branches read `Fighter.default_actions`;
other branches supply literals or retain the previous live value.

| Owner / decimal record index | Stock effective timing | Writer / possible live timing |
| --- | ---: | --- |
| Deidara `43` | `-3` | `deidara_channel3`: template, `-1`, `0` |
| Deidara `44` | `-3`, blocked | `deidara_channel3`, then `deidara_hit_response`: template, retained, `-1/-2/0/2` |
| Deidara `45` | `-3` | `deidara_channel3`: template, `-1`, `0` |
| Rock Lee `39` | `-3` | `rock_lee_channel3`: template or `0` |
| Might Guy `42` | `0` | `might_guy_hit_response`: retained at chain count `<=1`, then `1/2/3` |
| Sasori (Hiruko) `30` | `-1` | `sasori_hiruko_hit_response`: template plus `0/1/2` |

Deidara's three records and Lee's record also change rejection bit
`0x00008000`. Deidara `44` can lose its stock block; the other three
can acquire a block. Hit-callback mutations of `0x00080000` are a
different flag and do not satisfy this rejection mask.

##### Callback ordering and counter ownership

`character_dispatch_channel` uses the ordinary character vector for these
six indices: selectors `1/2/3` choose its first three entries.
Alternative effect-associated selection applies to major-`8` indices
below `4`, not these records. `receiver_vector_predicate` returns
zero in the clean resident program.

The outer `fighters_update` order is maintenance for all fighters,
selector-`1` callbacks, collision building and pairwise hit responses,
then unpaused input/action processing. `fighter_dispatch_action_update`
runs selectors `2` then `3` before its major-state dispatch.
Consequently Deidara/Lee channel-`3` writers run after that outer hit pass,
while Guy/Hiruko channel-`2` resets precede their channel-`3` increments.
`response_select_substate` separately calls the vector's hit-response
entry during hit handling, so its timing write can affect the following
substitution predicate. These are static ordering constraints, not measured cadence.

| Character | Callback-vector annotation | Channel 2 | Channel 3 | Hit response |
| --- | --- | --- | --- | --- |
| Deidara | `deidara_callbacks` | `deidara_channel2` | `deidara_channel3` | `deidara_hit_response` |
| Rock Lee | `rock_lee_callbacks` | `rock_lee_channel2` | `rock_lee_channel3` | `rock_lee_hit_response` |
| Might Guy | `might_guy_callbacks` | `might_guy_channel2` | `might_guy_channel3` | `might_guy_hit_response` |
| Hiruko | `sasori_hiruko_callbacks` | `sasori_hiruko_channel2` | `sasori_hiruko_channel3` | `sasori_hiruko_hit_response` |

Deidara and Lee read `response_streak`, a repeated-hit counter, not an
awakening tier. `fighter_init` clears it and `streak_attack_record`.
The final `response_enter_ordinary` repeat branch needs a nonnull attack
`row` and neither category mask `0x01000000` nor `0x000C0000`.
It compares `repeat_count` with effective repeat `1` when receiver
`exchange_roles` is nonzero, otherwise positive `attack_repeat_countdown`
or zero. On a match, a null/same streak record permits increment, then the
incoming record is retained. `response_exit_cleanup` clears both on
leaving major `5`
([Hit response](../combat/hit_response.md#character-callbacks)).

Below own streak `2`, Deidara `43..45` use template timing and set
the block when `action_outcome == 1`; otherwise they use `-1` and
clear it. At streak `>=2`, `43/45` use zero; `44` clears the block
but retains timing. Lee `39` below `2` uses template plus block for
outcome `1`, otherwise zero without block; at `>=2` it uses zero
without block. Deidara's hit-response callback instead reads the defender's
streak: `44` becomes `-2` below `2`, zero at `2`, and `2`
at `>=3`.

`GuySubstitutionState.chain_count` is initialized by
`fighter_id_069_construct`. `might_guy_channel2` clears it when the
opponent's action query is `-1` and substate is zero.
`might_guy_channel3` increments it on primary event `0` for actions
`42/38`, and secondary event `0`, phase `1`, for action `37`.
Action `42` writes timing `1` at count `2`, `2` at `3`, and
`3` at `>=4`; count `<=1` retains timing.
Generic action entry selects the same live record and
`fighter_clear_action_bytes` resets outcome fields without restoring timing.
Clearing the chain counter alone therefore does not restore the clean byte;
a separate table reload is not excluded.

`HirukoSubstitutionState.chain_count` is cleared by
`sasori_hiruko_channel2` when the opponent leaves major `5`;
`sasori_hiruko_channel3` increments it on primary event `0` for
actions `30/31`. Action `30` uses template timing below `2`,
template plus `1` at `2`, and plus `2` at `>=3`.
With clean template `-1`, the live values are `-1/0/1`.

These six records describe direct writer families, not every indirect live
mutation. Their eligibility changes remain separate from timing changes.

Kakashi (decimal ID `70`) supplies a concrete static example:
`kakashi_actions` (`0x00524BF0`) has 48 records. Hex indices
`0x01/0x03` have raw zero with conversion categories
`0x00040000/0x00080000` and effective `-1`;
`0x17/0x18` have raw `-1`; `0x23/0x2B/0x2C` have `1`;
all others have zero. Positive timing bypasses the zero-specific conversion.

### Other eligibility gates

The predicate rejects before timing/resource handling for
`state_flags & 0x80`, nonzero `exchange_roles`, own temporary
effect `0/1`, or existing major/substate `0/8`.
`fighter_has_effect_0_1` checks bounded membership regardless of lifetime.

Other rejection gates are selector `8`, a response outside the whitelist,
`ActionRecord.flags & (0x02000000 | 0x00008000)`, an unsupported
`contact_attack_source` state, and non-player controller mode except
the earlier sentinel shortcut. When normal resource validation is requested,
active `effect_flag40_active` or chakra below `1.0` also rejects.
These are eligibility controls, not per-attack probabilities.

A missing definition first uses `SubstitutionFallbackSources.record`; if absent,
it queries `SubstitutionFallbackSources.source` and then
`Fighter.contact_attack_source` when their `GenericNode.node_kind` is nonzero,
and finally uses `atk_dummy_record`
(`0x00407C00`). This never bypasses the required contact source state gate.
Nonzero controller mode clears a positive guard-input age, retaining zero and
negative values, before ordinary mode rejection.

Insufficient chakra requests the side's `fighter_feedback_request` when
present. `substitution_shortage_sound` plays only while
`chakra_shortage_sound_cooldown == 0`, then sets that count to `15`.
The earlier active-effect-`0x40` rejection produces no shortage feedback.
Both return zero and prevent the caller's commit.

The exact response whitelist is:

```text
0x06, 0x07,
0x27..0x39,
0x3C..0x41,
0x48..0x59
```

`response_select_substate` derives it from `response_selector` plus
grounding, orientation, context, callbacks and repeated-hit remaps.
Contextual failures `0x3A/0x3B` and responses `0x42..0x47` are outside
the whitelist. The complete mapping belongs to
[Hit response](../combat/hit_response.md).

## Timing arithmetic bounds

All signed negative bytes use the same unsigned arithmetic:
`-n`, `1 <= n <= 128`, gives denominator `2n + 1`, nominal
fractions `1/3..1/257`, and the exact floor formula above.
Positive values above `3` have the same four-record search as `3`.

A nonnegative window still requires a physical guard edge, ordinary guard age
below `16`, and every earlier eligibility/resource gate. Raw zero is not
effective zero with conversion category bits. Sentinel, Kurenai effect and
direct item routes have their own boundaries.

## Retail observation

A bounded Practice observation selected Naruto record `21` with P1 Circle.
On the hit, P2's retained incoming definition became relocated P1 record
`21`, whose clean timing is `-1`; P2 HP changed `1.0 -> 0.98`,
then regenerated. This supports the incoming owner/index calculation.

Slot-1 L2 independently produced pressed native mask `0x00000001` in
history word `1` and the matching release in word `2`. The defender's
logical action and guard-input age stayed zero because its controller mode was
`1`, consistent with static suppression. No memory patch was used.
This sample does not establish roster-wide success rates.

## Remaining evidence limits

The predicate, ordinary callers, effect/item routes, two AI sentinel states,
six writer records and native transition are resolved within the stated scope.
Negative fractions describe uniform-word arithmetic, not observed distributions.

Direct-store searches cannot exclude indirect table replacement. Guy's retention
holds for the inspected writer, counter reset and generic action entry, not
every form change. Guard-age wrap requires uninterrupted maintenance; no
evidence establishes it as an observed retail event.
