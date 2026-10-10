# Battle statistics

## Research coverage

Established: the 28 source metrics and direct producer families, fighter
statistic conditions and continuation lifetime, direct overlay condition
events, and score import, tier and ryo commit. Open: condition-menu and tier
names, every derived clash callback and prop reset, indirect writes, a
same-activation double Ultimate credit, state-5 reachability, and card-save or
grant timing.

Names come from `@annotations/NA2`; routine comments carry code details and
scoped call censuses. Evidence establishes per-invocation arithmetic and
ordering, with the negative bounds stated below.

Retail NA2 (`SLPS-25837`) has four distinct layers: the two-side result
source bank, 24 fighter count/maximum pairs, configured condition status, and
the result object's imported values/contributions. Match termination, result
codes and outer routing belong to [Match outcomes](match_outcomes.md).
Combo ownership belongs to [Combo accounting](../combat/combo_accounting.md);
fighter reconstruction belongs to
[Battle lifecycle](battle_lifecycle.md#fighter-statistics-across-reconstruction)
and [Hit response](../combat/hit_response.md#hit-count). Individual movement,
support, projectile, item and stage behavior stays with its linked owner.
Result rendering/layout and localization specifications are outside this
document.

## Address convention

All addresses are live, following
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
The reusable result object is `BtlRecordOwner`. Its existing annotation fields
`reset_word` and `context_value` hold the total and pre-result ryo snapshot;
each `BtlRecordOwnerRow` has `definition`, `mutable1` (value) and `mutable2`
(contribution). Descriptors use `ResultMetricDescriptor`, and bucket tables
use `ResultBucketRow`.

The resident fighter-stat backing bank `fighter_statistics_banks`, latched
result `battle_route_code`, timeout marker `battle_timeout_marker` and
continuation phase `battle_continuation_phase` are named in
`@annotations/NA2/SLPS_258.37`. Their roles are established by the owning
routines and the lifetime/import contracts below.

## Battle-statistic producers

### All 28 retail metric labels

`btl_record_definitions` (`0x008C3DE0`) contains 28 descriptors whose `text`
points to Shift-JIS strings with ruby markup. The table omits only the
pronunciation markup; `%s` is the retail substitution token. Text establishes
the categories, while producer contracts establish what counts.

| Index | Retail text | Meaning and source/import distinction | Text annotation |
| ---: | --- | --- | ---: |
| `0` | 敵は忍術にて攻めるべし | Ninjutsu; accepted actor/projectile events and token-suppressed contact. | `result_metric_0_text` |
| `1` | 敵は奥義にて攻めるべし | Ultimate Jutsu; action-marker and post-Ultimate producers both add. | `result_metric_1_text` |
| `2` | 敵は連係攻撃にて攻めるべし | Linked attacks; deduplicated support notification, sometimes transferred to `25`. | `result_metric_2_text` |
| `3` | 変わり身にて敵を欺くべし | Substitution; eligible ordinary substitution entry. | `result_metric_3_text` |
| `4` | 追い討ちにて敵を追撃すべし | Extra Hit follow-up; resolved exchange credit. | `result_metric_4_text` |
| `5` | 連続攻撃にて敵を圧倒するべし | Consecutive attacks; accumulated source is replaced by source `17` at import. | `result_metric_5_text` |
| `6` | 特殊忍具を用いて攻めるべし | Special ninja tools; item dispatch and projectile credits. | `result_metric_6_text` |
| `7` | 敵は素早く排除すべし | Finish quickly; computed remaining whole timer units. | `result_metric_7_text` |
| `8` | 己の体力は温存すべし | Preserve health; selected HP converted to a percentage-like integer. | `result_metric_8_text` |
| `9` | 強者を打ち破るべし | Strong opponent; COM strength plus one, or default `3`. | `result_metric_9_text` |
| `10` | 秘めたる力を解き放つべし | Hidden power; awakening-entry credits. | `result_metric_10_text` |
| `11` | 挑発を以って敵を刺激すべし | Taunt; accepted animation marker. | `result_metric_11_text` |
| `12` | 壊れ物を破壊すべし | Breakable objects; eligible stage-object interactions. | `result_metric_12_text` |
| `13` | 特殊条件を完遂すべし | Special conditions; finalized subtotal of contributions `14..16`. | `result_metric_13_text` |
| `14` | 敵の奥義を打ち破るべし | Defeat an enemy Ultimate; defender interruption credit. | `result_metric_14_text` |
| `15` | 術の競り合いにて勝利すべし | Jutsu clash win; actor outcome callback argument `0`. | `result_metric_15_text` |
| `16` | 敵に残影をもって挑むべし | Zanei/afterimage challenge; contest entry. | `result_metric_16_text` |
| `17` | コンボ数%sHitボーナス | Combo-count bonus; high-water value and floor bucket. | `result_metric_17_text` |
| `18` | 所持アイテム%s個ボーナス | Held-item bonus; occupied inventory slots at terminal phase transition. | `result_metric_18_text` |
| `19` | 背景破壊ボーナス | Background destruction; event count converted to a fixed bonus when positive. | `result_metric_19_text` |
| `20` | 残影勝利ボーナス | Afterimage victory; winner count converted to a fixed bonus when positive. | `result_metric_20_text` |
| `21` | 奥義ボーナス | Ultimate bonus; source receives `100/200/300`, result is forced to zero. | `result_metric_21_text` |
| `22` | 敵%sカウント以内撃破ボーナス | Fast-finish bonus; elapsed units and ceiling bucket. | `result_metric_22_text` |
| `23` | 体力１００％ボーナス | 100% health bonus; derived from converted HP. | `result_metric_23_text` |
| `24` | キャラクター組み合わせボーナス | Character combination; source qualification flag, result recomputed from `25..27`. | `result_metric_24_text` |
| `25` | 特殊連係攻撃%sHitボーナス | Special linked attack; imported from source `2` when source `24` is nonzero. | `result_metric_25_text` |
| `26` | 連係忍術%sHitボーナス | Linked ninjutsu; accepted action identifiers `0xC0..0xC4`. | `result_metric_26_text` |
| `27` | 連係奥義%sHitボーナス | Linked Ultimate; qualifying post-Ultimate helper. | `result_metric_27_text` |

### Direct producer inventory and its limits

The producer coverage is limited to direct add/set/max calls in the resident
and BTL images. Computed or indirect calls, differently constructed bank
stores and unrestricted writes remain outside that coverage. Mirrored
resident aliases do not represent additional physical producers.

### Resident event selectors and result-bank indices

`fighter_add_result_event` (`0x00223360`) translates selectors using
`result_event_jump_table`. It credits one-based side
`1 + (Fighter.control_flags & 1)`. Selector validity is a caller contract:
values above 9 reach the common add without translation.

| Event selector | Result metric | Operation |
| ---: | ---: | --- |
| 0 | 0 | Add delta |
| 1 | 3 | Add delta |
| 2 | 4 | Add delta |
| 3 | 17 | Set value |
| 4 | 1 | Add delta |
| 5 | 5 | Add delta |
| 6 | 10 | Add delta |
| 7 | 11 | Add delta |
| 8 | 16 | Add delta |
| 9 | 20 | Add delta |

| Metric | Producer contract |
| ---: | --- |
| 3 | `hit_intercept` admits ordinary substitution, excluding route bit `0x200` and low-nibble route 2; separately increments `stats[11]`. [Substitution](../characters/substitution.md) owns the routes. |
| 4 | `exchange_teardown` resolves `exchange_roles`: zero local role credits the opponent, otherwise the local fighter, while resolved role bits clear. [Extra Hit](../combat/extra_hit.md#exchange-state-at-fighter-0xb00) owns the exchange. |
| 17 | `combo_consume_pending_hits` and `combo_set_current_hits` publish current combo only when `stats_set_current` raises `stats[23].max`. |
| 1 | `action_phase_commit_chakra` credits an admitted major-8 phase-0 marker; the separate `stats[9]` update is terminal-gated. This does not establish an Ultimate win; see [its entry/cleanup contract](#metric-1-entry-cleanup-and-possible-double-credit). |
| 5 | `combo_consume_pending_hits` drains `pending_combo_hits` into the native combo and adds one if the new combo exceeds one, rather than adding the pending byte's magnitude. [Combo accounting](../combat/combo_accounting.md#resident-owner-and-update-order) owns the order. |
| 10 | `input_sector_widen_state_b` and `awakening_dispatch` credit awakening-entry tails. [Awakening](../characters/awakening.md#already-present-and-constructor-owned-adoption) owns reconstruction adoption that can suppress another entry credit. |
| 11 | `taunt_update` credits the character-specific marker accepted by `taunt_marker_accepted` in `(0,3)` with `action_progress_blocker == 0`; it also updates `stats[16]`. |
| 16 | `afterimage_enter` and `afterimage_counter_enter` credit entry to `(8,0x14)`, initialize `context_state`/`afterimage_marker` and clear `afterimage_flags`/`afterimage_count`/`afterimage_work`. |
| 20 | `exchange_rate_cleanup` credits when the local signed `afterimage_count` exceeds the opponent's; this is separate from entry metric 16. |

### Accepted ninjutsu and combo flushing

The accepted BTL paths classify identifiers `0xC0..0xC4` as linked ninjutsu
(metric 26) and other identifiers as ordinary ninjutsu (metric 0), adding one.
Actor paths use `CollisionSkillPrimary.resource_index` and require
`packet_neighbor_counter == 0` before incrementing it. Auxiliary paths
require `CollisionSkillAuxiliary.accepted_contact_flags & 1` and
`result_credit_count == 0`; they either forward credit to an identity-matched
primary actor using its gate, or classify their own `resource_index`, then
increment `result_credit_count`. Matching uses the context's registered pair,
rather than ownership inferred from a class name.

`skill_actor_accept_credit` (`0x007B9B30`) and
`skill_auxiliary_accept_credit` (`0x0077FE60`) are representative owners.
`skill_auxiliary_init` clears both auxiliary words;
`skill_primary_construct` clears the actor word. No separate reopening within
an activation is established; indirect field writes remain outside coverage.

Each established positive `InteractionManager.pending_combo_hits[side]` flush
first updates the resident combo through `combo_add_side_hits`, conditionally
adds the count to source 5 when `combo_accumulation_enabled` is true, always
max-updates source 17, then clears the pending word.
[Combo accounting](../combat/combo_accounting.md#per-side-accumulated-contribution-route)
owns the accumulated route and predicate. Source 5 is additive, source 17 a
high-water value. Import uses source 17 for both weighted metric 5 and bonus
17, so the source-5 tally is not the result-screen formula.

### Projectile contact deduplication

`projectile_lineage_age_consume` (`0x00735B70`) ages four selected-side
`ProjectileLineageSlot` records. A matching `key`/`word` token receives one
metric-0 credit only when `consumed` is zero, then sets it to one.
[Projectiles](../projectiles_and_items/projectiles.md) owns the record
lifecycle and common contact caller. This establishes token-suppressed contact
credit, without establishing a count of individual damage ticks.

### Ninja tools and stage objects

Metric 6 credits `item_status_dispatch` after the applicable `0x51..0x73`
code branch; an effect handler's rejection does not remove its tail credit.
`projectile_response40` requires the battle manager and credits the opposite
one-based side of signed `Projectile.side_tag` (`0 → 2`, `1 → 1`).
`projectile_chase_response40` and `projectile_special_tool_credit` use their
one-shot flags. These are measured events, not a universal count of button
presses or successful damage.
[Battle items and statuses](../projectiles_and_items/battle_items_and_status_effects.md)
and [Projectiles](../projectiles_and_items/projectiles.md) own effects and flag
lifetimes.

The established metric-12 paths admit a category-0 fighter contact and
attack record, reject `ActionRecord.category & 0x00F00000`,
`category & 2` or `flags & 0x02000000`, require the manager and credit the
contacting fighter's `1 + (control_flags & 1)`. The wrapper supplies no
deduplication.

| Retail owner / annotated routine | Credit and repeat boundary |
| --- | --- |
| `ccBgBreakObjectBattle` / `bg_break_update` (`0x006C4AD0`) | Admission requires `BgBreakObject.break_count != break_threshold`, nonzero `playback_state` and the earlier contact predicates. `bg_break_trigger` raises the count, capped at 99; only subsequent equality credits. Intermediate model transitions do not count. Equality prevents another contact pass until reset. A looping threshold of -1 cannot equal an ordinary nonnegative count. |
| `ccBgBreakObjectBattleAnm` / `bg_break_anm_update` (`0x006C5B60`) | Admission requires `BgBreakAnimation.break_count == 0`. `bg_break_anm_trigger` raises it, and nonzero afterward credits. Later updates service animation/reset rather than another contact. Completed reset clears the count, allowing another credit within the same allocation. |
| `ccBgBreakDollBattle` / `bg_break_doll_update` (`0x006C6940`) | Nonzero `BgBreakDoll.cooldown` decrements and returns. An admitted contact sets it to `prng_inclusive(60) + 60` and credits after the configured reaction/spawn path. This counts cooldown-admitted contacts without the base terminal-count comparison. |
| `ccBgBreakObjectBattleChandelier` / `chandelier_admit_break` (`0x006D24E0`) | Rejects nonzero `BgChandelier.broken`; eligible contact credits, clears `impact_ticks` and enters state 1. `chandelier_break_update` invokes admission only in state 0; states 1/2/3 use other paths. State 3 can return to 0 once `broken` clears. |

[Stages](../stages/stages.md#animated-and-breakable-background-evidence)
owns factories, authored distribution, receivers and resets. Reopening a
threshold permits repeated credit; source 12 measures qualifying transitions,
rather than distinct prop identities. The listed routes are established, while
every authored configuration and derived reset sequence remains open.

`bg_crash_break_update` (`0x006CA8A0`) credits metric 19 through two
alternative reaction routes. A primary fighter must match
`BgBreakObject.section_key`, be in major 5 at substates
`0x42/0x43/0x48` or `0x45/0x46/0x49` at marker zero, and pass the
corresponding `BgCrashBreak.contact_modes` and
`planar_threshold`/`vertical_threshold` comparisons. After the transition,
`break_count == break_threshold` hides the render objects and credits the
opposite side from the responding fighter. No attacker provenance is resolved
beyond that selection.

The initial unequal-count gate and exit after one accepted fighter prevent
unchanged terminal props from crediting repeatedly. Both flag branches share
this finite-threshold contract. Conditions `0x2C..0x2E` read count thresholds
3/5/7; score import instead gives one fixed bonus for a positive count.
Metrics 12 and 19 therefore differ in both recipient and source event.

### Jutsu-clash outcome selection and callback lifetime

`interaction_stage_pending_pair` (`0x0077BC00`) obtains active side-0/1
actors through `attack_object_get_special` and compares signed
`InteractionManager.clash_counts`:

| Comparison | Side-0 callback value | Side-1 callback value |
| --- | ---: | ---: |
| Side 0 greater | 0 | 1 |
| Side 1 greater | 1 | 0 |
| Equal | 2 | 2 |

The selected actor `interface` outcome callback receives that value. The
registered concrete `ccSkillKBW001` actor installs
`skill_kbw001_clash_outcome` (`0x00787E40`).

That callback stores `CollisionSkillPrimary.clash_outcome` before virtual
work. Only outcome 0 with a manager credits metric 15 to `side + 1`;
outcomes 1 and 2 do not. It has no terminal or duplicate-credit gate.
Credit precedes later virtual side effects, then `clash_flags & 1` and
`clash_count_a`/`clash_count_b` clear. The resolver separately clears both
actors' `published_category` and replaces the context's
`primary_candidates` with the selected hit-route flags. These local outcomes
are separate from the resident match result `battle_route_code`.

Actor-pair admission (`interaction_handoff_primary_pair`, `0x0077A750`)
requires both actors with `status_flags & 3` clear, resets contest receivers,
runs start/positioning work, then enters `clash_initialize` (`0x0077A8B0`).
Setup activates `InteractionManager.flags & 1` and clears `clash_timer`,
`clash_phase` and both counters before later setup work.
Later setup seeds an initial counter bias for the side with the larger actor
scalar and selects one of four authored input masks. Counts therefore need
not be zero when input accumulation starts.
`interaction_manager_remove_update` runs `interaction_pending_pair_call`
(`0x0077C270`) only while active.

Driver phase 0 reaches phase 1 at timer 5 and resets the timer. In phase 1
a human side's counter increments on every update whose shared pressed word
intersects `clash_input_mask`; a COM side uses its AI predicate.
[Controller input](../../runtime/controller_input.md#gameplay-readers-outside-command-history)
owns that input publication, and [Battle AI](battle_ai.md) owns the AI behavior.
When the old timer reaches 150, resolution runs and `clash_cleanup`
(`0x0077B4B0`) clears the active flag. This supplies one resolution per active
clash rather than a callback-level deduplication rule; the constants count
updates, without establishing presentation duration.

`interaction_handoff_primary_auxiliary` also enters shared setup.
The pair route and concrete installed callback are established, while all
derived callback overrides and authored actor/projectile combinations remain
open. The counter comparison proves the values sent, not identical metric
behavior in every callback or player-facing names.

### Ultimate and support producers

`jutsu_apply_completion` (`0x0035B3B0`) excludes mode 6. Outcome getter
`jutsu_get_outcome` returning 2 means successful defender interruption: it
credits opposite-side metric 14 and returns
([Ultimate Jutsu](../characters/ultimate_jutsu.md)). Other outcomes reach
same-side metric 1 and metric 21's class reward from
`ultimate_reward_for_class` and `ultimate_class_rewards` (100/200/300).
Conditions `0x3D/0x3E/0x3F` receive status 1 for the selected class.
Source 21 remains until bank reset, although its imported result is zero.

#### Metric-1 entry, cleanup, and possible double credit

The entry route requires `action_update_jutsu_record` to find a current
jutsu-category record with `ActionRecord.flags & 0x10000` **set**.
`action_phase_commit_chakra` additionally requires major 8, nonnegative
signed effect selector, phase 0 and `timeline_secondary_event_crossed` at
event zero. The predicate is marker-gated rather than unconditional.
Bank credit precedes the terminal gate; only the separate `stats[9]` pair
is suppressed by `status_flags & 1`. The producer neither latches a credit
nor changes phase at the add, so this routine alone does not establish one
invocation per activation. Its sound/event request does not prove cinematic
start. Phase-2 chakra handling belongs to
[Chakra and guard](../combat/chakra_and_guard.md).

`sp_skill_play_start` installs `sp_skill_play_end` and retains the attacker
side for its call to `jutsu_apply_completion`. A missing manager or mode 6
skips the cleanup tail. Interruption credits only metric 14; otherwise cleanup
credits metric 1 without checking terminal state, HP loss, successful damage,
or an earlier metric-1 value. It neither subtracts nor consults entry credit,
and interruption does not undo an earlier source event.

The callback lifetime is per played request. `ccs_play_decode_worker`
supplies it to `ccs_play_start`, and `ccs_play_loop` invokes it before
returning from stop/teardown.
[CCS runtime](../../game/files/ccs_runtime.md#request-table-source)
establishes zero or one stream request in each of 184 retail SINF rows.
Additional main/body paths are resident loads rather than played requests, so
those paths cannot independently manufacture another cleanup credit.
The [request lifecycle](../../game/files/ccs_runtime.md#per-request-lifecycle-in-playdecode)
and [play task](../../game/files/ccs_runtime.md#the-play-task) own transport and
timing; this is a bounded ordinary lifetime, not an internal duplicate guard.

The ordinary connecting-hit route (`opponent_lock_override`) requires the
same record's `flags & 0x10000` **clear**, together with hit-provenance
gates, before `jutsu_connection_cleanup` and presentation selection.
An unchanged record cannot pass both routes.
`naruto_ultimate_record_families` gives a concrete example: slots 4/5/6
have flags `0x85/0x85/0x89`, while slots 7/8/9 have `0x10001`.
`jutsu_slots_rewrite` changes category/name/cost and selects 7..9 only for
skill class 7 without toggling that bit. This establishes distinct record
families without proving selection in every battle.
[Ultimate Jutsu](../characters/ultimate_jutsu.md#start) owns connection and
presentation; [Action commands](../combat/action_commands.md#representative-paths)
owns selection.

**Inference:** a marker event and a qualifying cleanup event reaching the same
side within one bank lifetime sum to +2, because neither producer deduplicates
against the other. A single activation reaching both producers remains
unestablished. A concrete authored/scripted transition to a cinematic-producing
route or another actual
end-callback invocation remains necessary to establish an example. The two
source sites prove neither occurrence nor impossibility of that transition.

#### Linked Ultimate and support credit

A selected skill helper other than -1, with `jutsu_record_category` returning
2, invokes `support_credit_linked_ultimate` (`0x00886B80`), whose body adds
one to metric 27 for the supplied side plus one.

`support_lineage_consume` (`0x00886A40`) credits metric 2 after deduplication.
Identifier zero requires an active object's notification flag clear;
nonzero identifiers use `support_notification_rings`, rejecting repeats.
Acceptance sets the active object's flag when it exists, and common reason-2
entry clears it. [Support mechanics](../characters/support_mechanics.md)
owns resets, identifier allocation and attack lifetime.

Pass 1 of `support_owner_update` consumes its constructor flag and submits
each side's resolved code to `support_code_setup_event`. A true result credits
source 24, then the flag clears. The predicate scans
`support_combination_groups`, skips each leading group byte and qualifies a
matched member only when its ordinal is above zero; codes at least `0x44`
and missing codes fail. Numeric code-to-character names remain unassigned.
Import transfers source 2 to result 25 when source 24 is nonzero, zeros result
2, and recomputes result 24's separate 100-point bonus from contributions
25..27.

### Inventory snapshot and statistic lifetimes

`item_pickup_list_destroy` (`0x003747C0`) samples source 18 when phase
becomes 3 from a phase other than -1 or 3, a manager exists, and result is 1
or 2. It selects the winning inventory panel; `item_panel_count_for_full`
counts three slots whose item code and quantity are both nonzero. Quantity -1
is occupied. This counts slots rather than quantity and naturally ranges 0..3,
although the bonus table also has thresholds 4 and 5.
[Battle item inventory](../projectiles_and_items/battle_item_inventory.md#na2-panel-layout)
owns the layout.

`btl_register_static_cleanup` zeroes both 28-slot banks at module
initialization. Ordinary inner-cycle startup uses `result_bank_clear`;
continuation phase 2 preserves them. Source 18 is overwritten at the phase
transition; 17 is set on a rising resident combo maximum and max-updated on
BTL flush; normal import overwrites 7 on both sides; other audited events add.
No wholesale result-to-source copy occurs.

`Fighter.stats` contains 24 `StatPair` count/max values, saved and reloaded
through the per-side bank `fighter_statistics_banks`.
[Battle lifecycle](battle_lifecycle.md#fighter-statistics-across-reconstruction)
and [Hit response](../combat/hit_response.md#hit-count) own reconstruction.
Result import clears its own value/contribution pairs while preserving
descriptor pointers, then reads the selected source bank and fighter HP
before fighter destruction. Reusing the result object resets neither the
source bank nor fighter pairs.

## Statistic-derived conditions

`stats_evaluate_configured_conditions` (`0x002242D0`) walks only the
configured list and calls `stats_condition` (`0x00223450`). Return 0 leaves
status alone; 1 writes status 1; 2 writes status 0. `side_condition_set`
changes either direction when the value differs. Earlier success persists
only where the case explicitly checks it.

`battle_evaluate_terminal_conditions` invokes this after special KO/time
assignments, before unresolved-status completion and the result-5 scan.
[Match outcomes](match_outcomes.md#terminal-detector-and-classifier)
owns the classifier and outcome routing.

**E** means `Fighter.status_flags & 1`, the terminal condition gate.
Threshold cases succeed immediately when satisfied, otherwise wait then fail
on E. Avoid cases fail immediately when the prohibited count/threshold is
reached, otherwise wait then succeed on E. Fighter counter reads are signed
halfwords; numeric predicates alone do not establish retail menu names.

| Condition ID(s) | Statistic or predicate | Evaluation |
| --- | --- | --- |
| `0x0C/0x0D/0x0E` | Own chakra `chakra >= 5/10/15` | End-only success/failure on E. |
| `0x0F` | Own HP `hp <= 0.1` | End-only. |
| `0x10/0x11/0x12` | Own HP `>= 0.3/0.5/0.8` | End-only. |
| `0x13/0x14` | Opponent HP `<= 0.3/0.5` | End-only. |
| `0x15` | Own `stats[1].count == 0` | Avoid any nonzero count. |
| `0x16` | Own jump-event count `stats[10].count == 0` | Avoid any nonzero count. |
| `0x17` | Own `stats[7].count == 0` | Avoid any nonzero count. |
| `0x18` | Own Ultimate action-marker count `stats[9].count != 0` | Fail immediately; success is assigned by the separate terminal default in [Match outcomes](match_outcomes.md#terminal-detector-and-classifier). |
| `0x19` | Own guarded-hit count `stats[19].count < 1` | Avoid one or more guarded hits. |
| `0x1A` | Opponent Ultimate action-marker count `stats[9].count > 0` | Fail immediately; separate terminal default supplies success. |
| `0x1B` | Own accepted-hit count `stats[18].count < 1` | Avoid one or more ordinary accepted hits. |
| `0x1D` | Own `stats[2].count == 0` | Avoid any nonzero count. |
| `0x1E` | Own accepted-action count `stats[0].count == 0` | Avoid any nonzero count. |
| `0x1F/0x20` | Own surface-movement maximum `stats[21].max / 60 >= 4/6` | Threshold. |
| `0x21` | Own input/debit-path maximum `stats[20].max / 60 >= 60` | Threshold. |
| `0x22/0x23` | Own gated sequence maximum `stats[22].max / 60 < 1/3` | Avoid converted count `>= 1/3`. |
| `0x24/0x25` | Own substitution count `stats[11].count >= 3/6` | Threshold. |
| `0x26` | Own paired-response count `stats[13].count >= 3` | Threshold; producer and continuation lifetime below, retail condition name unresolved. |
| `0x27` | Own recovery-event count `stats[12].count >= 3` | Threshold. |
| `0x28/0x29` | Own record-category count `stats[4].count >= 3/6` | Threshold. |
| `0x2F..0x38` | Own combo maximum `stats[23].max >= 5,10,15,20,25,30,35,40,45,50` | Threshold, in ID order. |
| `0x39/0x3A` | Opponent recovery-substate count `stats[15].count >= 3/6` | Threshold. |
| `0x3B` | Own taunt count `stats[16].count != 0` | Immediate success; zero fails on E. |
| `0x3C` | Own awakening count `stats[17].count != 0` | Immediate success; zero fails on E. |
| `0x40` | Support creation counter returned by `support_creation_count(side)` is nonzero | Immediate success; zero fails on E. |

The converted maxima use `timer_whole_units`, signed division by 60 truncating
toward zero. [Timer primitives](../../runtime/timer_primitives.md#integer-time-unit-conversion)
owns the arithmetic; it does not establish seconds or scheduler frequency.

`surface_movement_update` raises `stats[21]`, and
`item_fighter_air_setup` clears only its current count on exit.
[Movement](../stages/movement_and_physics.md) owns `ACT_WMV_0..2`.
`fighter_polygon_contact_class` counts its admitted input/affordability path
in `stats[20]`; those guards differ from the debit guards, so a counted
invocation does not prove a debit
([Chakra and guard](../combat/chakra_and_guard.md)).
`fighter_advance_timelines` clears current `stats[22]` under its
auxiliary-state gate or major 7/8; other role/exchange/overlay/terminal gates
govern increment/max update. Its condition UI name remains unresolved.

`action_dispatch_index` classifies record dispatch into `stats[0]`,
`stats[4]`, `stats[7]` and a separately masked `stats[2]` path;
`action_exit_record` has its independently guarded `stats[1]` increment.
These exact record/exit categories do not establish condition labels such as
“normal attack,” “miss” or “support.”

`jump_impulse_update` produces `stats[10]`.
`recovery0_enter`, `recovery1_enter` and `response_dispatch_transition`
produce `stats[12]`, and `downed_motion_update` produces `stats[15]`
in recovery substate `0x61`. These pairs share the terminal-gated current/max
saturation contract; [Hit response](../combat/hit_response.md) owns recovery
and ordinary/guarded hit counts.

### Paired-response condition count

`hit_enter_trade` (`0x00221120`) increments `stats[13]` on both fighters
after their response entries and coordination. Each `stats_increment` call
independently rejects E, caps a valid rising count at 9,999 and raises the
maximum when exceeded. Neither publishes a result metric. Condition `0x26`
requires current count at least 3; below that it waits then fails on E.

`hit_resolve_pair` admits this only after earlier arbitration leaves the pair
unconsumed, both records exist, local incoming/outgoing flags 1 and `0x100`
are set, and neither fighter has positive `hit_rejection`. Ordinary pair
flags clear afterward.
[Hit response](../combat/hit_response.md#rehit-suppression) owns admission;
[Damage](../combat/damage.md#simultaneous-hits-and-knockout-boundaries)
owns later damage. The counted event is an admitted paired response, without
proving two HP debits or a double knockout. The increments can differ when
only one fighter has E.

`fighter_init` uses `stats_reset_block`: clear all local pairs, clear their
side backing pairs only outside continuation phase 2, then
`stats_load_side_bank`. `fighter_cleanup` uses `stats_save_side_bank`
before destroying internals. Pair 13 therefore reloads both saved halves
across phase-2 reconstruction; ordinary construction clears them.
Condition status has its own reset exception
([Match outcomes](match_outcomes.md#terminal-detector-and-classifier)), so
saved counts and saved status are separate contracts.

This direct producer and lifetime do not exclude indirect writes or computed
indices. No exact retail condition string has been joined to `0x26`; a player-facing
“simultaneous hit” name would exceed the evidence.

### Terminal provenance predicates

Other `stats_condition` cases use terminal flags and retained attack/source
records rather than a source-bank count. Cases 5/6/9/`0x0B` require E and the
opponent's `state_flags & 8` clear. Attack uses the opponent's
`recovery_record`, falling back to `actions`; source uses
`recovery_source`, falling back to the opponent itself.

| ID | Success predicate / preservation |
| ---: | --- |
| 5 | Source `node_kind == 0` and attack `category & 0xF00`; otherwise fails. |
| 6 | Opponent `recovery_grounded == 0`, excluding source category 0 with attack `flags & 1` and `category & 0xF00`; otherwise fails. |
| 8 | On E, own `contact_flags & 0x20` succeeds; absent bit fails only if prior status is not already 1. |
| 9 | Source category 0 and attack `category & 0xF0000`; failing provenance preserves prior status 1, otherwise fails. |
| `0x0A` | On E, opponent `state_flags & 8` clear and `chakra <= 0`; otherwise fails. |
| `0x0B` | Source category 2; failing provenance preserves prior status 1, otherwise fails. |

ID 7 and terminal assignments for 1..4 belong to
[Match outcomes](match_outcomes.md#terminal-detector-and-classifier).
IDs without a case return zero, without proving absence of an external
producer. These predicates do not recover condition-menu strings.

### Direct overlay condition events

`item_record_distinct_use` (`0x00713680`) writes condition `0x2A = 1` on
the third previously unseen nonzero code. `item_distinct_tracker_construct`
clears its list/count/flags; `item_manager_construct` owns the tracker
separately from inventory panels, and `item_panel_activate` calls it.
[Battle item inventory](../projectiles_and_items/battle_item_inventory.md#dispatch-and-consumption-boundary)
owns usage.

`item_check_full_inventory_condition` (`0x00713770`) checks both eligible
primary fighters once per `ItemDistinctUse.inventory_checked` latch and writes
`0x2B = 1` when all three slots are occupied. Its phase-3 caller runs after
the winner's source-18 sample and item-list removal. It can credit both sides,
where source 18 samples only the selected winner.

### Direct BTL condition-status writers

`stage_evaluate_break_conditions` (`0x006C3250`) checks configured
`0x2C/0x2D/0x2E` against the manager-selected side's source metric 19 at
thresholds 3/5/7 and writes status 1. Condition names and a universal meaning
of status zero remain unestablished.

The other direct families are:

| Producer | Status write and trigger |
| --- | --- |
| `item_record_distinct_use` | Side argument plus one, `0x2A = 1` when the newly accepted code makes the count exactly 3. |
| `item_check_full_inventory_condition` | Side 1 or 2, `0x2B = 1` for three occupied slots, with the one-shot latch. |
| `projectile_publish_provenance_condition` (`0x0072F220`) | `transient_actor_opposite_side + 1`, configured ID 9 when signed `Projectile.lineage_key != -1`, or `0x0B` when `support_notify == 1`; writes 1. |
| `jutsu_presentation_update` (`0x00769790`) | When the object's zero-based side equals `BattleManager.active_side`, writes own `0x18 = 0`; otherwise writes opposite `0x1A = 0`. |

The failure writes can enter `battle_scan_failed_conditions`'s outcome-5
scan when configured and the target side is active. These are the established
direct BTL writers; indirect and resident producers remain outside that
coverage.

## BTL score, tier, and point-accumulator handoff

`result_metric_bank` (`0x008D6A80`) holds two 28-slot signed-16 source
records. All wrappers select the record by one-based side minus one.

Adds are unsaturated: sign-extend the delta's low halfword, add and retain the
low halfword. Set/max also store low halfwords. Side 1..2 and metric 0..27
are unchecked caller domains. Fighter pairs instead saturate their count/max
at 9,999.

`battle_state_allocate` clears the source bank on ordinary inner-cycle
creation, preserving it in continuation phase 2. Timer reset, import and
resource teardown do not clear it. Outer restarts later pass through another
inner-cycle allocation and reset unless continuing. The source bank therefore
has an ordinary inner-cycle/sample lifetime, with the result-8 exception
([Match outcomes](match_outcomes.md#higher-level-sequence-counter-and-result-8-continuation)).

The six-word session outcome block resets only in initial outer state 2 and
updates after completed cycles. The result allocation lasts with the outer
controller, while its pairs and presentation internals reset per score view.

`result_import_metrics` runs after the end presentation and before resource
teardown, clears its own values/contributions and copies the selected source
bank. It selects side 1 only for result 1, otherwise side 2. Draws and special
result 5 therefore select side 2 without establishing that side won.
Outer state `0x10` imports results 1..5, but state `0x12` permits only its
field-qualified result-1/2 paths to create the score view. Imported draws,
double-zero and result-5 samples are not committed through that proven flow.

`result_metric_weighted` upper-caps each value by its descriptor selector,
with no lower floor, then multiplies by the signed coefficient.
`result_caps_and_tiers` begins `999,99,100,0,0,300,450,550,700`.

| Metric indices | `(coefficient, cap selector -> maximum)` |
| --- | --- |
| `0` | `(5, 0 -> 999)` |
| `1` | `(100, 1 -> 99)` |
| `2` | `(10, 0 -> 999)` |
| `3` | `(5, 0 -> 999)` |
| `4` | `(10, 0 -> 999)` |
| `5` | `(1, 0 -> 999)` |
| `6` | `(5, 0 -> 999)` |
| `7` | `(1, 1 -> 99)` |
| `8` | `(1, 2 -> 100)` |
| `9` | `(50, 0 -> 999)` |
| `10` | `(100, 1 -> 99)` |
| `11` | `(5, 0 -> 999)` |
| `12` | `(5, 0 -> 999)` |
| `13` | `(0, 0 -> 999)` |
| `14`, `15` | `(100, 1 -> 99)` |
| `16` | `(10, 1 -> 99)` |
| `17..24` | `(0, 0 -> 999)`; their relevant custom helpers replace the generic contribution |
| `25` | `(20, 0 -> 999)` |
| `26` | `(100, 0 -> 999)` |
| `27` | `(400, 1 -> 99)` |

Import overrides the initially weighted source values:

| Metric | Imported transformation |
| ---: | --- |
| 7 | Configured limit minus elapsed whole units, clamped to zero. Timeout marker `battle_timeout_marker` or manager mode 2 with configuration selector 6 equal to 100 forces zero. Normal path writes the remaining units into source 7 on both sides. |
| 8 | Selected fighter HP × 100 converted with the active FPU word-conversion rounding, plus one when HP < 0.05. |
| 5 | Weighted source 17, replacing source 5. |
| 17 | Source 17 through `result_combo_bonus_buckets`. |
| 18 | Source 18 through `result_item_bonus_buckets`. |
| 19 | Raw count, contribution 50 if at least one. |
| 20 | Raw count, contribution 20 if at least one. |
| 21 | Forced zero. |
| 22 | Elapsed whole units through `result_time_bonus_buckets`; the same timeout/mode/configuration conjunction forces zero. |
| 23 | Converted HP, contribution 500 if at least 100. |
| 25 / 2 | With source 24 nonzero, transfer source 2 to result 25 and zero result 2. |
| 24 | Contribution 100 if any contribution among 25..27 is positive, otherwise zero. |

`result_metric_threshold` stores the raw value and a fixed contribution
when its threshold holds. Floor/ceiling helpers store the selected **bucket
threshold** and its contribution, leaving both zero if no row qualifies.

| Table | Selection | (threshold, contribution) |
| --- | --- | --- |
| `result_combo_bonus_buckets` (`0x008C3CD0`) | Last threshold ≤ input | (30,50), (40,100), (50,200), (60,300), (70,400), (80,500), (90,1000) |
| `result_item_bonus_buckets` (`0x008C3D10`) | Last threshold ≤ input | (2,10), (3,20), (4,30), (5,50) |
| `result_time_bonus_buckets` (`0x008C3D30`) | First threshold ≥ input | (10,400), (20,200), (30,100) |

`result_finalize_contributions` sets metric 9 to 3 when manager
`control_mode == 0`; otherwise `battle_strength_get + 1`.
[Battle AI](battle_ai.md#configuration-and-behavior-profiles)
establishes configuration `0x0B` as COM Strength 0..5 and this zero control
assignment as no COM. Its 50-point coefficient gives 50..300 by strength,
or a fixed 150 when neither side is COM. The finalizer writes the upper-capped
subtotal of contributions 14..16 into metric 13's value; coefficient zero
adds no extra contribution. It then sums all 28 contributions into the total.

`result_initialize_total_tier` snapshots `profile_ryo_get`, selects
presentation side 1 only for result 2 (otherwise 0), finalizes contributions
and upper-caps total at 9,999. `result_tier_thresholds` gives:

| Total | Tier |
| ---: | ---: |
| < 300 | 0 |
| 300..449 | 1 |
| 450..549 | 2 |
| 550..699 | 3 |
| ≥ 700 | 4 |

Only numeric tiers are established; letter/rank labels remain open.

`result_summary_update` allows acceptance only once its child permits it;
before then native Circle accelerates tally states 2/3.
`result_details_update` uses the same `result_accept_commit`.
`result_accept_pressed` tests newly pressed native Circle for
`BtlRecordOwner.selected_side`.

Accepted input plays sound/event `0x34` and returns 1. With a manager,
the object enters state 3 and writes
`min(pre_result_ryo + total, profile_ryo_maximum())` through
`profile_ryo_set`. The maximum is 9,999,999 and the setter also enforces it.
Neither total nor accumulator has a lower floor. With no manager, acceptance
enters state 4 without a write.

[Save data](../../game/save_data.md) establishes this same field/getter/setter
as profile ryo, formatted with `両`. A Free Battle human win therefore adds
the capped result total to ryo. The scoped handoff has no direct item or
unlock grant; card persistence timing is outside this document.

`result_dispatch` initializes in state 0 and enters 1, updates the summary
and details in 1/2, waits for fade in 3 then enters 4, returns completion 1 in
4 and return 2 in 5. `battle_score_presentation_update` accepts only return
1, then waits for resource readiness, resets pairs, releases current
presentation internals, unloads the result resource and advances outer
`0x14 → 0x15`. It retains the result allocation for later cycles.
`battle_driver_cleanup` releases it again, frees it through `heap_free`
and clears the owner pointer. Commit therefore precedes presentation teardown,
and the result object does not persistently own the committed ryo.

State 5/return 2 is recognized by the interface, but the resident owner does
not complete on it. Established writes are 0..4; no direct state-5 write is
established in the result lifecycle or resident owner. Indirect writes and
state-5 reachability remain open.
