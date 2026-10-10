# Match termination and outcome flow

## Research coverage

Established: KO/timeout, condition/pause outcomes, inner/outer end flow, score qualification,
session tallies/streaks, both result-`8` continuations and cleanup ordering.
Open: player-facing names of `5/8/9` and signed wrapper returns, a latched `9` producer,
a best-of-N rule, other callers' screen roles, invocation/presentation timing,
and the complete encounter sequence-data layout.
Names, fields and per-routine comments are maintained in `@annotations/NA2`.

This document owns how a retail NA2 (`SLPS-25837`) battle ends.
[Battle statistics](battle_statistics.md) owns statistics, statistic-derived
conditions and scoring; [Battle lifecycle](battle_lifecycle.md) owns graph,
archive and reconstruction lifetimes; [Pause and replay](pause_and_replay.md)
owns menu construction. [Damage](../combat/damage.md) owns HP changes,
[Timer primitives](../../runtime/timer_primitives.md) owns timer arithmetic,
and Victory rendering is an interface boundary only.

## Game binary address conventions

Addresses follow
[Retail game file identities](../../game/files/file_identities.md#address-conventions)
and [Overlay ABI](../../runtime/overlay_abi.md#exact-clean-layouts).
Evidence is static and bounded to the inspected resident dispatchers and BTL
consumers. Addresses are live. The resident BSS globals in the following
section are named in `@annotations/NA2/SLPS_258.37`.

Result latching and the Victory handoff are resident. BTL reads the result
through `battle_route_get`; no direct BTL call to `battle_route_set` or
`battle_victory_request` was found in the scoped images. BTL boundaries are
`result_import_metrics` (`0x00719580`), `result_dispatch`
(`0x00719D80`), `btl_record_owner_reset` (`0x00719500`),
`btl_record_owner_release` (`0x00719140`) and
`result_presentation_create` (`0x00719290`).

## Outcome state and decisive fields

| Resident global | Established role |
| --- | --- |
| `battle_manager` | `BattleManager` pointer |
| `battle_session` | Pointer to the current `0x38`-byte `BattleState` / `BattleSession` |
| `btl_process` | Pointer to the `0x44`-byte `BtlProcess`, owning outer states and reusable result metrics |
| `battle_commands_hud` | Transient Commands HUD presentation pointer, retired in outer state `0x10` |
| `battle_start_menu_state`, `battle_start_menu_side`, `battle_start_menu_host` | Pause-flow active state, selected input side, and menu host pointer |
| `battle_route_code` | Latched result, initially `0` |
| `battle_timeout_marker` | Timeout/end-reason marker |
| `battle_continuation_phase` | Continuation phase: `1` request, `2` preserve on rebuild, `3` consumed |
| `battle_continuation_route` | Result-`8` rebuild route `1` or `2` |
| `battle_reentry_handshake` | Inner continuation readiness handshake |
| `battle_condition_flow_enable`, `battle_condition_phase` | Condition-flow enable byte and phase word |
| `battle_countdown` | `BattleCountdown` |
| `session_outcomes` | Six-word `SessionOutcomes` |
| `side_condition_statuses` | Three banks of `0x5D` signed condition statuses; this path uses sides `1/2` |

The relevant named fields are `BattleManager.mode`, `active_side`,
`control_mode`, `current.sides[].flags`, `fighters[]` and
`battle_conditions`; `Fighter.state_flags`, `hp` and `exchange_roles`;
`BattleCountdown.flags`, `remaining`, `elapsed`, `limit` and `delta`;
and the inner object's `flags`, `inner_state`, `entry_type` and
`inner_delay`. Whole clock units occupy the counter's high byte.

`battle_route_set` writes any supplied result without validation,
`battle_route_get` returns it, and `battle_timeout_marker_get` tests the
timeout marker. `battle_state_setup` clears both result and timeout marker.
Ordinary classification only latches while the result is zero; the enabled
condition branch can overwrite that classification later in the same update.

### Outer-controller types

`BtlProcess.entry_type` comes from `battle_process_get_or_create`.
The [mode callback dispatcher](../../game/mode_flow.md#high-level-mode-callback-dispatcher)
creates type `1` through `free_battle_callback` and type `2` through
`practice_callback`, establishing the Free Battle/Practice routes below.
Other higher-level callers exist; their enclosing screen roles were not
traced in this outcome scope.

### Control assignment and COM sides

`battle_control_mode_set` changes `BattleManager.control_mode` and bit
`0x02` of both `BattleCharacterSlot.flags` bytes:

| Control mode | Side 1 COM bit | Side 2 COM bit |
| ---: | :---: | :---: |
| `0` | clear | clear |
| `1` | clear | set |
| `2` | set | clear |
| `3` | set | set |

[Practice Mode](../modes/practice_mode.md) establishes this as the COM bit.
Manual uses mode `0`; other statuses make the side opposite the human COM.
Outer startup `practice_driver_reset_settings` applies mode `1` for
`active_side == 0`, otherwise `2`, and clears the session tally.
`manager_initialize` also applies mode `1`. Other control-assignment
callers' triggering screens remain outside this trace.

## KO and time termination

### Fighter life gate

`fighter_load_character_record` sets `Fighter.state_flags & 0x08`.
`fighter_apply_hp_debit` clears it when accepted HP subtraction leaves HP
at or below zero. In Practice (`BattleManager.mode == 3`), HP instead floors
at `0.01` and keeps the bit
([Damage](../combat/damage.md#damage-application)). Normal full HP is `1.0`.

### Timer path

`battle_state_setup` reads setting `6` through `battle_setting_get`,
sets the countdown limit and remaining high byte, and clears elapsed and the
result. Zero remaining sets expiry `0x04` immediately; this initializer has
no zero-as-unlimited interpretation.

`battle_countdown_advance` returns `1` when expired. Bit `0x01` blocks
accumulation; bit `0x02` freezes arithmetic while still allowing the negative
remainder check. Otherwise remaining decreases by `delta` and elapsed
increases by it, with elapsed capped at 99 whole units. Negative remaining
becomes zero, elapsed becomes the configured limit, and expiry `0x04` is set.

`battle_timer_update` advances this clock only with both live fighters,
both `exchange_roles == 0`, both life bits set, coordinator state zero,
`battle_footprint_gate` (`0x007064B0`) zero, result zero, and inner
`flags & 0x02` set. Timer advancement precedes terminal evaluation, allowing
new expiry to be classified in the same eligible update.

`battle_clock_freeze_set` writes bit `0x02`;
`battle_clock_unlimited` reads it (the existing annotation name is retained).
`battle_clock_get` rounds remaining whole units upward,
`battle_clock_elapsed_get` returns nonnegative elapsed whole units, and
`battle_clock_limit_get` returns the configured limit.

### Terminal detector and classifier

With a manager and an unresolved result, `battle_evaluate_terminal_conditions`
treats either cleared life bit or clock expiry as terminal. Either trigger first
calls `fighters_end_exchange(side1_fighter, 1)`, independent of which side
lost its life bit. Timeout sets the separate end-reason marker.

`battle_classify_hp_result` then compares current HP:

| Comparison | Result |
| --- | ---: |
| Side 1 greater | `1` |
| Side 2 greater | `2` |
| Both exactly zero | `4` |
| Otherwise equal | `3` |

A missing fighter contributes zero HP. An absent manager returns `9` without
latching it; the normal caller is manager-guarded. Timeout therefore has no
separate ordinary result: unequal HP yields `1/2`, equal nonzero HP `3`.
The life/timer trigger and HP classification are distinct decisions.

The optional `BattleConditionDefinition` uses `count`, stored-order
`ids[]` and `presentation_payloads[]`.
`battle_condition_flow_initialize` enables it and
`battle_record_controller_destruct` disables it.
`side_condition_init` sets every status to `-1`;
`side_condition_get` reads a status and `side_condition_set` changes it.
Writes and scans require the side's COM bit clear.

In the enabled condition path, terminal processing assigns:

| Condition ID | Terminal assignment |
| ---: | --- |
| `1` | Result `1` writes side 1 to `1`; other results first write side 2 to `0`. Side 2 is then written to `1` only for result `2`, otherwise `0`. This is asymmetric; unresolved completion later supplies side 1's remaining `-1` as `0`. |
| `2` | Timeout writes `1` for both sides |
| `3`, `4` | Non-timeout KO, ordinary winner `1/2`, and at least one life bit still set: winner gets `1` below 31 / 61 elapsed whole units |
| `0x18`, `0x1A` | Each side's unresolved `-1` becomes `1` |

Statistic-derived condition evaluation follows those assignments. On a
terminal update, `battle_conditions_resolve_unset` changes remaining
configured `-1` statuses to `0` through the active-side writer gate.
Finally, `battle_scan_failed_conditions` returns the first active side with
a configured status exactly zero, scanning condition-list order before side
1/2 order. It returns zero when none qualify.

A nonzero scan changes condition phase `1` to `3` when applicable and calls
`fighters_end_exchange(selected_fighter, 1)` on that transition, then sets
result `5` unconditionally. It can happen without KO/time or replace
ordinary `1..4` within that same invocation. An already-latched result blocks
a later terminal-evaluation invocation. Result `5` denotes this configured
zero-status path; a player-facing mode name is not established.

Condition progress has a separate lifetime from result/timeout. Setup normally
resets statuses, but preserves them in continuation phase `2` except when
inner `entry_type` is `4/5` and rebuild route is not `1`; that combination
forces reset. Result and timeout still clear for the new encounter.

BTL also writes statuses directly
([direct condition writers](battle_statistics.md#direct-btl-condition-status-writers)).
`jutsu_presentation_update` (`0x00769790`) has three zero-status writes for
IDs `0x18/0x1A`, eligible for the same scan when configured and active.

## Result-code table

| Code | Established meaning | Evidence bound |
| ---: | --- | --- |
| `0` | Unresolved/active | Timer and classifier gate |
| `1`, `2` | Side 1 / side 2 has greater terminal HP | HP comparison |
| `3` | Equal nonzero HP, normally a time draw | UI wording not fully established |
| `4` | Both HP values zero | Exact comparison |
| `5` | Active configured side has status zero; can override ordinary result | Original mode name open |
| `6` | Pause selection `3`: return through Character Select without scoring | Confirmation prompts, not traced input |
| `7` | Pause selection `2`: exit toward Mode Select | Confirmation prompts, not traced input |
| `8` | Synthetic continuation | Both resident routes established; original name open |
| `9` | Recognized by consumers | No latched producer found in scoped direct stores/calls |

Ordinary KO/time emits only `1..4`. `battle_start_menu_update` writes
`6/7` through `battle_route_set`; continuation producers write `8`
directly. No literal pointer to the setter was found in either scoped image;
computed indirect calls or other overlays remain possible sources of `9`.
Winner/loser names for `6..9` would exceed the evidence.

The pause host is a separate `0xCC`-byte allocation. Admission, existing
result/timeout and other services gate opening. A nonzero menu selection first
unpauses, clears pause state and destroys the host. Selection `1` refreshes
both fighters' battle settings without setting a result; `2` then latches
`7` and `3` latches `6`. Thus pause outcomes are written after the
selecting menu object has been destroyed.

## End-of-battle state machines

### Inner end sequence

`battle_loop_active` wraps `manager_update_substate_four`. Inner return
`0` runs battle/input services, timer advancement, then terminal evaluation;
`2` waits while skipping those services; `1/3` report completion.
A missing inner object reports completion `1`. The continuation readiness
barrier supplies the `2/3` pair.

The ordinary end sequence uses the named `inner_state` and `inner_delay`:

| Substate | Behavior |
| ---: | --- |
| `3` | Clear presentation flag; event `8` only while result zero; enter `4`, enable pause admission |
| `4` | Service continuation barrier first. Results `6/7/9` emit `0x17` and complete. Timeout emits `0x0A`, break event `0x32`, result-audio `0`, then enters `0x0A`. Other nonzero results emit `9` and enter `5`; zero waits. |
| `5` | Result-side exchange effect; wait `0x1E` for `1/2/4`, `0x5A` for `3`; `5` emits break `0x39`, result-audio `3`, wait `0x5A` |
| `6` | After first wait, `1/2/4` request result-audio `1`; all `1..5` seed another `0x5A`. Result `5` also requests audio `4`, event `0x13` and break events `0x3D/0x46`. |
| `7` | After wait, winner `1/2` enters `8` when manager is absent or control mode is `3`; otherwise only when winner COM bit is clear. Other winners and draw/special results fade through `0x0F`. |
| `8` | Select winning side `1/2`, pass HP and remaining whole units to `pause_controller_outcome_parameters` (`0x0076EDA0`), then request `pause_controller_opening_begin` (`0x0076EF60`) with winner record, zero-based winner mode, selector `1`; clear item manager's `end_sequence_flag`; enter `9` |
| `9` | Wait for the presentation controller's lifecycle to clear, then complete |
| `0x0F..0x11` | Start fade, wait for it, report completion |

The `control_mode == 3` branch is distinct from the human-winner score gate.
The manager-absent branch describes a local decision, not an established safe
full sequence with absent fighter pointers.

`pause_controller_outcome_parameters` uses HP buckets `>= 1.0/0.8/0.6/0.4/0.2`
or below to choose `retained_index = 0/1/2/3/4/5`, and clears
`presentation_index`. The caller supplies remaining time, but the callee
does not consume it. The opening wrapper discards the supplied winner record
and forwards mode/selector to its request normalizer.

Timeout substates `0x0A..0x0E` wait for the auxiliary overlay's readiness:

| Result | Timeout presentation route |
| --- | --- |
| `3/4` | Audio `2`, wait `0x5A`, substate `0x0C`, then fade `0x0F` |
| `5` | Result-side exchange effect, audio `4`, event `0x13`, break events `0x3D/0x46`, substate `0x0E`, then wait `0x5A` and rejoin `7` |
| `1/2` | Result-side exchange effect, audio `1`, wait `0x3C`, substate `0x0D`, then rejoin `7` |

`battle_end_exchange_for_result` selects side 2 for result `1`, side 1
for `2/3/4`, and for `5` repeats the failed-condition scan when a definition
exists, otherwise uses `active_side + 1`. A nonnull selected fighter is
passed to `fighters_end_exchange(fighter, 0)`. This does not establish a
loser for draws or condition outcomes; the helper acts on both fighters.

Wait and event constants are invocation arguments, not wall-clock durations.

### Outer controller

`battle_process_get_or_create` allocates the outer `BtlProcess`;
`battle_process_construct` / `battle_driver_setup` store the type,
create/reset `result_metrics`, and start state `1`.
`manager_dispatch_state` runs the pause handler and dispatches states
`1..0x19`. Outer and inner objects have independent lifetimes.

Outer `0x0E` (`battle_state_enter`) waits readiness, then
`battle_state_allocate` creates the inner object through
`battle_state_construct` / `battle_state_setup` and `battle_create_graph`.
State `0x0F` drives an active battle as well as its eventual end sequence.

| State | Handler | Result/cleanup behavior |
| ---: | --- | --- |
| `0x0F` | `battle_state_wait_graph` | Drive inner battle until completion; clear end gate, enter `0x10`, seed three-count delay |
| `0x10` | `battle_state_exit` | Clear Victory request and transient presentation; result `8` chooses continuation, `1..5` import metrics before inner destruction, `6/7/9` skip import; normal path enters `0x11` |
| `0x11` | `battle_state_release_archives` | Release archives, commit session outcome, enter `0x12` |
| `0x12` | `battle_return_route_dispatch` | Qualifying type-`1` winner enters score setup; otherwise route to restart or exit |
| `0x13` | `battle_score_presentation_create` | Wait resources, create result presentation and entrance transition, enter `0x14` |
| `0x14` | `battle_score_presentation_update` | Run result dispatcher; completion clears metrics/internals/resource, retains result allocation, enters `0x15` |
| `0x15` | `battle_score_return_selection` | Emit `0x0E`, return to state `3` |
| `0x16` | `practice_driver_reenter` | Wait resources, return to state `3` without score presentation |
| `0x17` | `manager_replace_form` | Result-`8` route `1`; selected-side Victory request and rebuild |
| `0x18` | `manager_replace_configuration` | Result-`8` route `2`; commit other-result tally, rebuild |
| `0x19` | `battle_return_to_mode_select` | Final resource transition, clear timer freeze, set manager mode `1`, dispatcher terminal return `3` |

The exact route matrix for Free Battle/Practice is:

| Result | Metric import | Type `1` (Free Battle) | Type `2` (Practice) |
| ---: | --- | --- | --- |
| `1/2` | Yes | Score `0x13` only for human winner; otherwise `0x16` | `0x16` |
| `3/4/5` | Yes | `0x16` | `0x16` |
| `6` | No | `0x16` | `0x16` |
| `7` | No | Terminal `0x19` | Terminal `0x19` |
| `8` | No | Direct `0x17/0x18` by rebuild route | Same |
| `9` | No | `0x16` | `0x16` |

Only a type-`1` result `1/2` with the winning side's COM bit clear runs
the score screen and point commit. COM wins, Practice, draws and special
results skip it. This is separate from inner presentation selection.

State `0x16` rejoins selection reset `3`, giving pause result `6` the
no-score Character Select return. Result `7` terminates this controller and
writes Mode Select mode `1`. The
[pause confirmation prompts](pause_and_replay.md) match those routes; a
second generic “end the battle?” command also produces `6`. A hypothetical
latched `9` shares the restart route, without establishing its producer.
The enclosing controller decides the meaning of the terminal return.

`battle_victory_request` stores six arguments only in an idle
`BattleVictoryRequest` and sets `requested`;
`battle_end_prepare` clears it and `battle_preload_ready_b` tests idleness.
Victory rendering/layout remains outside this interface boundary.

### Selection reset and battle-load boundary

Restart states `0x15/0x16` are not an immediate repeat of the same matchup.
State `3` (`practice_driver_reset_snapshots`) clears current selection and
stage configuration through `battle_selection_clear` /
`battle_manager_init`, resets countdown and side snapshots, and calls
`item_cache_clear` (`0x0070F1E0`). Saved configuration and session outcome
tallies survive.

States `4/5` queue/adopt Character Select, Stage Select and Settings archives;
state `6` waits `battle_preload_ready_a` before Character Select `7`.
Its readiness contract requires `loading_presentation_controller` to point
to an object in phase zero. Successful Stage Select `9` stores the stage,
requests `battle_selection_transition_request(1, 0)`, and starts a
three-count delay before state `10`.

State `10` releases selection resources, then
`manager_snapshot_configuration` normalizes jutsu/support choices, resolves
same-character costume conflicts, and copies the three `0x28`-byte current
records and three stage bytes into `BattleManager.saved`. It then calls
`battle_load_ccs(1)` and enters `11`. Selection reset, saved setup,
session tally and fresh-battle initialization are distinct boundaries.

### Results resource loading

Score qualification queues `score_archive_name` (`xninka.ccs`) only when
absent and starts the CCS queue. State `0x13` waits the fence, creates result
internals, then starts its entrance transition; `result_initialize_total_tier`
(`0x00719ED0`) runs in the later result dispatcher.

`ccs_acquire_or_load` checks the cache first; a miss uses
`ccs_load_if_absent` and the synchronous `ccs_run_load_pipeline`, which
yields until read/decode completion. Resource readiness precedes presentation.

## Session outcome and streak counters

Outer startup clears `SessionOutcomes` once.
`session_outcomes_update` commits the latched result after normal teardown
or on continuation route `2`:

| Field | Update |
| --- | --- |
| `side1` / `side2` | Increment for result `1` / `2` |
| `draws` | Increment for `3/4` |
| `other` | Increment for every other result |
| `streak_count`, `streak_side` | Same winner increments count; changed winner starts at one; `3/4` clear both; other results keep both |

The six 32-bit counters do not saturate. Their four accessors return ordinary
total (`session_outcomes_total`, excluding `other`), per-side count
(`session_outcomes_side`, zero for invalid sides), draws
(`session_outcomes_draws`), and current streak only for its owning side
(`session_outcomes_streak`, otherwise zero).

BTL consumes them in presentation:
`session_outcome_presentation_setup` (`0x006BE0A0`) chooses three variants
from selected/opposite zero versus nonzero streak;
`session_outcome_presentation_draw` (`0x006BF070`) derives opposite ordinary
count as total minus selected count minus draws and clamps numeric values to
`0..99`; `settings_prompt_draw` (`0x006C0A70`) separately displays ordinary
total plus one, also clamped.

The scoped direct consumers have no win/draw termination threshold; no resident
direct accessor caller was found. This establishes tally/streak presentation,
not a best-of-N rule or the match-limit mechanism.

## Higher-level sequence counter and result-8 continuation

`encounter_flow_construct`, `encounter_flow_clear` and
`rng_shuffle_allocate` establish a separate `EncounterFlow` with
`state`, `ordinal`, `limit`, `elapsed`, `type`, `conditions`,
`sequence_data`, `definition` and `selection_table`.
The `sequence_data` pointer refers to resident `encounter_sequence_data`;
its complete layout remains open. Type `4` owns a randomized selection table
and type `5` can own an `EncounterSequenceDefinition`.

Higher-flow state `4` starts ordinal `1`. Type `5` with a definition
uses its signed-16 `limit` and three-byte encounter records; other initialized
flows use `99`. Continuation compares signed `ordinal < limit` only for
type `5`: positive `N` permits at most `N` total encounters, and `1`
or less suppresses the first continuation. No positive-range validation is
visible. Non-type-`5` flows bypass the comparison, so their `99` is not
an enforced limit. This counts encounters, not wins.

While outer state `0x0F` remains active and inner substate is `8`,
`manager_request_alternate_reentry` adds nonnegative clock elapsed whole
units to cumulative `elapsed`. Unless type-`5` limit is reached, it
increments ordinal, selects pending slot `2` for result `1` or `1`
otherwise, requests phase `1` / rebuild route `2`, latches result `8`,
stores word `1` in that slot's `pending_character_id`, and resets inner
substate to `4`. Reaching the type-`5` limit leaves ordinary completion
to proceed. Player-facing type-`5` naming remains open.

`battle_reentry_ready` provides a barrier after that reset. In phase `1`,
the first pass clears each present top panel's `transition_selector` and
sets the handshake. Later passes service/draw each present panel through
`battle_side_service_reentry` (`0x0071AF30`) and
`battle_side_update_reentry` (`0x0071B2E0`), returning `2` until every
present `child_draw_suppressed` byte is nonzero. Then it clears the handshake
and returns `3`, allowing the inner wrapper to report completion.
Resetting inner state to `4` therefore does not immediately destroy the old
encounter.

| Producer | Rebuild route | Tally effect |
| --- | --- | --- |
| `battle_request_form_replacement(side, form)` | `1` → outer `0x17` / `manager_replace_form` | No session tally update |
| `manager_request_alternate_reentry` | `2` → outer `0x18` / `manager_replace_configuration` | Result `8` increments `other` |

Neither route imports ordinary metrics. Both set phase `2`, preserving the
BTL result bank and normally condition progress; the inner type-`4/5` and
route-other-than-`1` condition-reset exception still applies. New setup
clears result/timeout. The rebuild and retained values belong to
[Battle lifecycle](battle_lifecycle.md#continuation-encounters-rebuild-the-session).

The form-replacement producer's sole direct resident caller,
`jutsu_apply_completion`, passes side index plus one and nonzero
`jutsu_record_form` from the selected jutsu record only while that side's
condition `7` is not `1`. It stores the pending value for side `1/2`.
Route `1` selects side `1` if its pending value is nonzero, otherwise side
`2` if its value is nonzero, otherwise neither. Route `2` rebuilds side
`2` when side 1's pending value is zero and side `1` otherwise.
These mechanics establish the producer chain, not a player-facing condition
name.

The higher wrapper also owns sentinels `0x1D..0x20`, outside the outer
dispatcher's `1..0x19` cases. It samples outer state before and after dispatch.
Pre-state `0x12` writes sentinel `0x1D` and clears its mini-state, but the
already-sampled post-state remains decisive: post-state `0x19` selects
`0x20` instead.

On a later update beginning at `0x1D`,
`encounter_conditions_result_update` creates transition/result helpers,
updates then draws the result helper through
`encounter_result_helper_update` (`0x006EE380`) /
`encounter_result_helper_draw` (`0x006EE4E0`), and on readiness scans the
saved condition definition through `battle_has_failed_conditions`.
It destroys the transition/result helpers and chooses:

| Scan | Sentinel | Following wrapper return |
| --- | ---: | ---: |
| At least one active configured zero-status condition | `0x1F` (emit `0x14`) | `-1` |
| No qualifying condition | `0x1E` | `+1` |

The wrapper stores the sentinel and resets its mini-state. Sentinel `0x20`
waits the resource worker before returning `-1`. The mechanics are established;
player-facing meanings of these signed returns remain open.

## Battle statistics and scoring

[Battle statistics](battle_statistics.md) owns the 28-slot bank, producers,
statistic-derived conditions, metrics, tier and ryo commit. Outer `0x10`
imports results `1..5` before destroying live fighters. The qualified score
route later drives `result_dispatch`, total/tier initialization,
contribution summation and accepted point commit.

## Cleanup boundaries

| Boundary | Ownership and ordering |
| --- | --- |
| End presentation | `battle_state_exit` clears Victory request and destroys transient presentation before metric import |
| Inner battle cycle | Normal results `1..5` import first, then `battle_state_destroy` invokes `battle_destroy_graph`, frees the inner allocation and the outer owner clears its global; `6/7/9` share destruction without import; `8` destroys on its alternative route |
| Broader inner cleanup | `battle_state_delete` destroys the inner object and transient presentation; it is not the outer destructor |
| Completed cycle | `battle_state_release_archives` releases archives and commits still-latched outcome after inner destruction |
| Result internals | State `0x14` clears current metrics and owned presentation internals, preserving `BtlProcess.result_metrics` for reuse |
| Outer controller | `battle_process_release` / `battle_process_destroy` / `battle_driver_cleanup` release selection and result children, including finally freeing reusable result metrics; `battle_controller_destruct` handles its higher-level ownership boundary |

Detailed destruction order and archive lifetime belong to
[Battle lifecycle](battle_lifecycle.md#teardown-order).
Metric import must precede destruction of the live fighter pointers it reads.
Session tally update follows and needs only the latched result and tally block.
Result/timeout survive import and completed-cycle teardown; the next
`battle_state_setup` clears them. BTL only reads the timeout marker through
its resident getter.

## Call graph summary

The decisive ordering is `battle_loop_active` → inner presentation →
battle/input services → timer → terminal evaluation. Outer completion then
runs presentation cleanup → metric import (ordinary results) → inner
destruction → archive/tally cleanup → route decision. Only the qualified
score route drives the result presentation and point commit; continuation
routes substitute their own cleanup/rebuild boundary.
