# Pause, start-menu, and battle-restart control

Retail NA2 (`SLPS-25837`) pauses selected battle consumers, routes start-menu
results, and rebuilds battle sessions. Numeric states and commands remain
numeric where their meaning is unresolved; presentation names inferred from
resources are distinguished from recovered class identities.

## Research coverage

Established: persistent suppression masks, selective scheduling and its
exceptions, controller ownership and cleanup, cut-in gating, menu admission,
command/result routing, Simple Display selection, and session reconstruction.
Open: indirect writers and interruption restoration, exact presentation phases,
unidentified subsystem roles and menu labels, some route producers, and any
replay mechanism outside the inspected paths. The evidence establishes static
ordering and gates, not measured display timing or exhaustive reachability.

Routines, fields and data are named by `@annotations/NA2`; annotation comments
carry per-routine details and bounded code searches. Addresses are live.

Related owners: [Controller input](../../runtime/controller_input.md),
[Practice mode](../modes/practice_mode.md), [Match outcomes](match_outcomes.md),
[Modes and navigation](../../game/modes_and_navigation.md),
[Battle lifecycle](battle_lifecycle.md),
[Timer primitives](../../runtime/timer_primitives.md),
[Target selection](../combat/target_selection.md), and
[Battle entities](battle_entities.md).

## Evidence identity and address conventions

File identity and live addresses follow
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
The resident globals below are verified through their code consumers. BSS
globals are named in `@annotations/NA2/SLPS_258.37`; their storage belongs to
the resident ELF even when BTL code accesses them.

| Resident global | Role |
| --- | --- |
| `battle_manager` | `BattleManager` pointer |
| `battle_session` | `BattleSession` pointer |
| `btl_process` | Battle-process pointer |
| `battle_start_menu_state`, `battle_start_menu_side`, `battle_start_menu_host` | Start-menu state, selected side, object pointer |
| `battle_route_code`, `battle_continuation_route` | Battle route and route-8 continuation mode |
| `battle_transient_manager` | Transient manager used by scheduler bit 5 |
| `battle_pause_controller` | Resident-owned pause controller (`AwakeningPauseGate`) |
| `battle_input_phase_override` | BTL-owned auxiliary interaction system (`BattleInputPhaseOverride`) |
| `support_owner` | `ccBuddyAtkCtrl` singleton |
| `0x00602A64`, `tone_shade_default_destination` | Current tone destination pointer and resident default destination |
| `battle_effect_first_phase_enabled`, `battle_effect_second_phase_enabled` | Effect-system first/second-phase enable bytes |
| `battle_countdown` | Countdown record; aggregate pause gate uses its `flags` byte |

## Resident pause-controller consumption

On a running pass admitted by its state handler, `battle_loop_active`
(`0x001EF8F0`) calls `battle_collect_scheduler_masks`,
`battle_dispatch_phases`, `battle_timer_update`, and
`battle_evaluate_terminal_conditions`, in that order. A skipped phase
therefore does not imply that every later session operation also stops.

### Controller fields and mask construction

`battle_collect_scheduler_masks` (`0x001F0290`) copies
`AwakeningPauseGate.suppression_first_third` and `suppression_second` without
clearing them. It adds suppression from the session overrides and publishes
the complements as `BattleSession.allowed_first_third` and `allowed_second`.
The names describe the demonstrated complement operation, not recovered
retail type terminology.

Two independent first-mask overrides matter:

- `interaction_apply_first_suppression` (`0x007729E0`) forces first-phase
  suppression to `0xFFFF` only when the auxiliary system's `force_history`
  byte equals `1`. It leaves the second suppression word unchanged.
- `BattleManager.menu_state == 1` also forces first-phase suppression to
  `0xFFFF`; it does not force the second word.

Each session override contributes the complement of its value by OR, so it
can only narrow the corresponding allowed mask. The first mask is shared by
phases one and three. Any nonzero resulting suppression also sets countdown
flags bit `0`; both suppression words zero clear that bit.

### Session-local override writer

`battle_field_second_override_set` (`0x001EC620`) samples the current
`allowed_second`, sets bit `0x10` for a nonzero argument or clears it for
zero, and copies that result to `override_second`. A null session is a no-op.
It writes neither controller suppression word.

The sampled source is the computed allowed mask, not the old override.
Consequently, the nonzero request restores this override's bit-4 contribution
without restoring a saved mask or guaranteeing that the next final mask has
bit 4 enabled. Other sampled disabled bits remain disabled, and controller
suppression can still disable bit 4. That bit controls `ccFieldCtrl`'s second
callback.

Several native presentation bodies issue disable/restore pairs, while one
inspected animation body issues only the disable. Their exact conditions are
in the owning routine annotations. These paths establish use of the copied
mask but do not establish restoration after every possible interruption.
Indirect calls, arbitrary aliases and other overlays remain outside the
bounded direct-call coverage.

### Auxiliary BTL global and the `+0xA50` override

The auxiliary interaction system is a separate BTL-owned `0x3330`-byte object.
`battle_auxiliary_create(1)` reaches `interaction_manager_allocate`
(`0x00776AD0`), which constructs and publishes it;
`battle_auxiliary_release` reaches `interaction_manager_release`
(`0x00776B20`), which destroys it and clears its global. Its full semantic
class identity remains unresolved.

`force_history` is tied to the embedded `CutinController` by the resource
formats `cutin_ccs_path` (`1%scutin.ccs`) and `cutin_animation_name`
(`ANM_1%s_cutin`), together with `battlegauge.ccs`.
`interaction_prepare_fighters` clears the byte, `cutin_stage_record` sets it
to `1` after validating and staging a side record and ensuring an effect
exists, and `cutin_reset` and `cutin_update` clear it at the traced resets,
state progression and both-sides-idle boundary.

A cut-in presentation active/staged flag is a high-confidence functional
interpretation. Its exact visible phase, and whether every cut-in uses it,
remain open. While it equals `1`, the first allowed mask becomes zero, the
command controller's first callback can run despite cleared bit 1, and the
two pending-command publication calls are skipped.

### Proven BTL suppression writers

The two proved child writers are `rng_case5_state_update` (selector 1;
`0x0076CC00`) and `jutsu_presentation_update` (selector 13;
`0x00769790`). The former's existing annotation name is retained; its
presentation resources identify the end-demo branch.

| Selector | Controller suppression progression |
| ---: | --- |
| `1` | Reassert `0xFFFF / 0xFFFF` at two transitions |
| `13` | `0x0110 / 0x0110`; then first `0xFBFF`, second `(old \| 0x0200) & 0xFBFF`; then `0xFBFF / 0xFBFF` |

The middle selector-13 operation produces `0xFBFF / 0x0310` only on the
traced path whose previous second word is `0x0110`. Both suppression words
persist until changed; the mask collector does not clear them. Common
controller cleanup is their proved eventual clear. No parent-mask writer was
identified in the bounded selector-0 gauge branch.

Before session overrides and the separate forced-first-mask cases, the
controller's complements are:

| Suppression first/third and second | Allowed first/third and second |
| --- | --- |
| `0xFFFF / 0xFFFF` | `0x0000 / 0x0000` |
| `0x0110 / 0x0110` | `0xFEEF / 0xFEEF` |
| `0xFBFF / 0x0310` | `0x0400 / 0xFCEF` |
| `0xFBFF / 0xFBFF` | `0x0400 / 0x0400` |

An active start menu forces the first/third allowed mask to exactly zero
regardless of this table. The independently constructed second mask remains
in force.

### Bounded pointer-based writer review

The inspected controller-pointer consumers change `stage`, query `selector`,
request a branch, read side identity/appearance, or toggle side flags. The
resource callbacks used by `pause_branch_resource_setup` do not write the
controller masks. No additional suppression-word writer or nonzero
`request_filter` producer was identified in those paths.

This bounds the evidence rather than proving complete writer coverage:
cached pointers, other address-loading forms, arbitrary callbacks, bulk
writes and unexamined overlays remain open. The session-local override has a
different destination and is a separate mechanism.

### Selective update gating

`battle_dispatch_phases` (`0x001F03E0`) caches both masks before controller
pre-work. A child mask write or cleanup during that dispatch affects the next
eligible collection, not the cached masks already in use. This establishes
ordering, not a measured display-frame delay. The cut-in exceptions read the
auxiliary byte separately during dispatch.

| Phase | Session mask | Primary callback |
| --- | --- | --- |
| First | `allowed_first_third` | First callback |
| Second | `allowed_second` | Second callback |
| Third | `allowed_first_third` | Third callback |

`battle_allocate_registries` builds the primary owner in the following order.
Class identities come from RTTI; allocation and callback details are in the
constructor and vtable annotations.

| Primary index | Bit | Class | Vtable annotation |
| ---: | ---: | --- | --- |
| 0 | 0 | `ccCameraCtrl` | `cc_camera_ctrl_vtable` |
| 1 | 1 | `ccCommandCtrl` | `cc_command_ctrl_vtable` |
| 2 | 2 | `ccPlayerCtrl` | `fighter_controller_vtable` |
| 3 | 4 | `ccFieldCtrl` | `cc_field_ctrl_vtable` |

The allowed-bit contract is:

| Bit | First phase | Second phase | Third phase |
| ---: | --- | --- | --- |
| `0` (`0x001`) | Camera first | Camera second | Camera third |
| `1` (`0x002`) | Command first | Command second | Command third |
| `2` (`0x004`) | Player first | Player second | Player third |
| `3` (`0x008`) | `support_update` | `support_second_pass` | `support_third_pass` |
| `4` (`0x010`) | Field first | Field second | Field third |
| `5` (`0x020`) | `transient_manager_update`, nonnull transient manager | `transient_manager_second_pass`, same gate | None |
| `6` (`0x040`) | `interaction_collision_frame`, nonnull auxiliary | `interaction_phase_second`, same gate | `interaction_phase_third`, same gate |
| `7` (`0x080`) | Set first enable byte, `battle_auxiliary_first_pass`; otherwise clear byte | Set second enable byte, `battle_auxiliary_second_pass`; otherwise clear byte | `battle_auxiliary_third_pass` |
| `8` (`0x100`) | `item_pickup_list_destroy`, nonnull `secondary_owner` | `item_pickup_list_present`, same gate | None |
| `9` (`0x200`) | `battle_clock_update` and `battle_root_update`, each for its nonnull owner | `battle_clock_present` and `battle_root_draw`, same gates | None |
| `10` (`0x400`) | `jutsu_contest_update(0)` when enabled | `jutsu_contest_render(0)` when enabled | None |

The bit-8 routine's existing name is retained; this scheduler invocation does
not establish destruction. The fixed consumers' gameplay meanings, especially
bits 5..10, are not all established. Each nonnull `side_services` entry also
runs `battle_side_service_reentry` in phase one and
`battle_side_update_reentry` in phase two when the respective mask has either
bit 9 or 10 (`mask & 0x600`). Bit 3's singleton is the recovered
`ccBuddyAtkCtrl` class.

The explicit exceptions and work outside these masks are:

- With `menu_state == 1`, camera first and third still run even if bit 0 is
  clear. Camera second has no equivalent exception.
- With `force_history == 1`, command first still runs even if bit 1 is clear;
  this exception does not admit its other phases.
- `fighter_overrides_before_phase1`, `fighter_overrides_before_phase2`,
  `fighter_overrides_before_phase3`, and final `query_process_active_pairs`
  run outside the allowed-bit checks.
- `pause_controller_before_phases` runs only outside `menu_state == 1`;
  `pause_controller_post_update` runs after phase one whenever the controller
  exists.
- `battle_camera_controller_update` requires a nonnull `camera_helper` and
  `menu_state != 1`.
- `interaction_stage_cutins` runs whenever the auxiliary exists;
  `interaction_update_cutins` additionally requires `menu_state != 1`.
- `battle_pair_helper_publish_pending` runs once per side only when the
  auxiliary exists and `force_history == 0`.

The two-side cut-in helper checks actors before staging them, updates up to
four children per side, and separately retains pending command words. When
the flag is clear, publication transfers each nonzero pending word to the
side's fighter command node and clears the slot. Its state timing, sine
motion and decay constants are in `cutin_update`'s annotation; these are
presentation behavior, not a second global stop switch.

An active start menu consequently leaves camera first/third, any separately
admitted command-first work, the second mask, and the work outside masks in
force. Later `battle_timer_update` and
`battle_evaluate_terminal_conditions` also remain eligible on the enclosing
running path.

### Battle-countdown gate and presentation

The countdown uses an aggregate pause gate outside the per-bit scheduler.
`battle_collect_scheduler_masks` sets countdown flags bit 0 for either
nonzero suppression word; `battle_timer_update` later conditionally calls
`battle_countdown_advance`, which does not accumulate while that bit is set.

The accumulator's other gates belong to
[Match outcomes](match_outcomes.md#timer-path); configured session reset
versus round initialization to
[Timer primitives](../../runtime/timer_primitives.md#clear-versus-configured-reset);
owner-creation arming of bit 1 to
[Battle lifecycle](battle_lifecycle.md#session-construction); and two-digit
clock presentation to
[Battle HUD](battle_hud.md#central-battle-clock-display).
Route 8 re-enters outer state 13 without state 3, rebuilding and rearming the
session without traversing the configured countdown reset.

### Shared ownership and controller lifecycle

`battle_create_graph` (`0x001EF330`) allocates and publishes the pause
controller; `battle_destroy_graph` (`0x001EEFD0`) performs BTL destruction,
releases the resident members, frees it, and clears its global. Allocation
and publication are resident-owned; BTL owns its internal construction and
behavior. The existing name `pause_controller_update` at `0x0076E9D0`
denotes the constructor body in this ownership chain.

The pause controller lives for the session. Normal session exit, either
route-8 reconstruction, and outer teardown destroy it together with the
separate auxiliary object. The next state-14 session construction allocates
new objects. Teardown order belongs to
[Battle lifecycle](battle_lifecycle.md#teardown-order).

| Selector | Functional interpretation | Pre-update | Post-update | Release | Child allocation |
| ---: | --- | --- | --- | --- | --- |
| `0` | Battle-gauge presentation | `pause_gauge_pre_update` | `pause_gauge_post_update` | `pause_gauge_release` | `0x20` behind a `0x14` wrapper |
| `1` | End-demo presentation | `pause_end_demo_pre_update` | `pause_end_demo_post_update` | `pause_end_demo_release` | `0x440` |
| `13` | Ougi presentation | `pause_ougi_pre_update` | `pause_ougi_post_update` | `pause_ougi_release` | `0x4C` behind a `0x14` wrapper |

The interpretations follow `battle_gauge_resource_name`, `end_demo_ccs_path`
and `ougi_ccs_path` plus their animation/text resource families. They do not
establish recovered enum names, translations or exact visible phases.

The demonstrated `lifecycle` is 0 inactive, 1 construction pending, and 2
child active. A pre-update constructs the selected child while the value is
1, then changes it to 2. Subsequent pre/post calls update and draw the child.
A zero child-update result calls `pause_controller_cleanup`; selectors 0 and
1 then call `presentation_completion_notify`, while selector 13 does not.

`pause_controller_cleanup` (`0x0076F1A0`) ends a branch on a retained
controller. It releases the child graph, clears the child, suppression words,
lifecycle and branch resources, and resets `selector` and
`presentation_index` to -1. It retains `mode`, `retained_index` and
`request_filter`. The ougi-specific release additionally restores both
manager-published fighters' `update_rate_override` to `1.0`. Branch cleanup
and controller destruction are distinct operations.

`pause_controller_request` (`0x0076EE80`) ignores selector -1 and normalizes
13..15 to 13. Filter 1 blocks every request; filter 2 blocks selectors 0 and
1. Starting a replacement branch first cleans up any active branch, then
records the new mode/selector and returns to lifecycle 1. Only the
constructor's direct clear of `request_filter` was found in the inspected
resident and BTL code; producers of values 1 and 2 remain unestablished.

The resident session requests selector 0 with mode 0 in substate 1. In
substate 8, only routes 1 and 2 request selector 1 with mode `route - 1`.
`jutsu_connection_cleanup` requests selectors 13..15 with a one-bit mode;
the normalizer makes all three selector 13. Argument forwarding details are
in `pause_controller_opening_begin`'s annotation.

### Tone-shade destination block

The controller embeds `tone_destination` and the eight-byte `tone_animator`.
The animator's LCG behavior belongs to
[Randomness](../../runtime/randomness.md#tone-shade-animator-timing-is-not-another-seed).
Construction initializes the destination before the animator. Destruction
runs the BTL body before `tone_shade_destination_destroy` and free; the
destination destructor redirects the current global to the resident default
if it still points at the destroyed destination. Neither inspected teardown
calls the animator's update or a separate animator destructor.

`pause_controller_post_update` publishes the destination and adjacent render
blocks unless `request_filter == 1`. Render-context constructors copy the
current destination, and `battle_dispatch_phases` restores the default after
post-work. Publication alone does not establish an animator invocation.

There is also an independent non-random writer:
`pause_tone_effect_update` (`0x0076F3F0`) acts only for numeric ID `0x49`.
Both tone accumulators advance by binary32 `0.01f`, add one when negative,
and subtract one only when strictly greater than one. It binds the resource,
writes the supplied destination coefficient and numeric parameters, and
copies the two accumulators to `random_component0/1`. It leaves the animator
counter and period unchanged. `pause_end_demo_effect_update` admits this
writer under record flag `0x400` with coefficient `1.2f` below numeric state
6 and `1.0f` otherwise. The evidence does not establish cadence or
reachability of every ID/flag combination.

### Session resets and retained skill participants

`battle_session_initialize` resets the session's two allowed masks and two
overrides to `0xFFFF` and clears its owner pointers. It runs before round
initialization on construction and after graph teardown on destruction.
It does not reset the countdown or separately allocated pause controller in
place. The ownership contract belongs to
[Battle lifecycle](battle_lifecycle.md#session-construction).

The `FighterCoordinator.participants` pair has an independent lifetime.
Construction clears it; the paired state-entry routines retain the supplied
fighters after setting the coordinator state. Pause cleanup does not access
that coordinator, so presentation completion does not release the pair.
Coordinator state 6 can resume with the same pair after the controller becomes
inactive. State setting, input locks and release belong to
[Target selection](../combat/target_selection.md#skill-participants-and-lock-release)
and [Battle entities](battle_entities.md#derived-fighter-registrycoordinator).

### Additional hold consumer

`jutsu_post_cinematic_update` (`0x0024ED40`) requires the controller. In local
state 0, a nonzero signed lifecycle keeps the paired fighters' fields and
positions reasserted and returns; only zero permits progression. Its other
ownership belongs to
[Target selection](../combat/target_selection.md#skill-participants-and-lock-release)
and [Ultimate Jutsu](../characters/ultimate_jutsu.md#damage).

## BTL start-menu construction and UI states

### Resident ownership and top-level result routing

`battle_start_menu_update` (`0x001EBD90`) owns the separate `0xCC` menu. With
`menu_state == 0`, other blockers clear, and a nonzero admission side (1 or
2), it stores that side and sets manager/menu state to 1. It constructs the
child when needed, initializes its resident member, and calls
`start_menu_update_draw` each active pass.

Every nonzero child result closes and frees the menu, clears its globals, and
restores `menu_state` to zero before routing:

| Result | Effect |
| ---: | --- |
| `1` | Refresh both fighters through `fighter_refresh_battle_settings`; leave route unchanged |
| `2` | Set battle route `7` |
| `3` | Set battle route `6` |

Result 1 is therefore the structural local-continuation path; the exact input
that produces top-level result 1 remains open. Results 2 and 3 enter session
teardown. Manager `menu_state` couples this separate menu to the pause
scheduler by forcing the first mask, admitting camera exceptions and blocking
controller pre-work.

`start_menu_build_commands` (`0x0087B3B0`) selects its list by
`battle_driver_variant_get`, the battle-process `entry_type`, with zero
returned for a missing process. The secondary selector is manager
`control_mode`, except Practice derives it as 1 or 2 from whether
`active_side` is zero.

| Entry type | Established mode | Command IDs before placeholder replacement |
| ---: | --- | --- |
| `4`, `5` | Producers unresolved | `0, 4, 1, 6, 0xE` |
| `1` | Free Battle | `0, 4,` optional `4, 1, 6, 0xA, 0xB` |
| `3` | Other battle-process entries | `0, 4, 1, 6, 9,` optional `7, 0xE` |
| `2` | Practice | `0, 4, 1, 6, 5, 0xA, 0xB` |

Free Battle includes its second 4 when `control_mode` is 0 or 3. Entry type 3
includes 7 when `ai_profile_modifier_bypass_get` returns zero. Its three
proved process-entry producers are annotated; their joins belong to
[Mode flow](../../game/mode_flow.md#btl-handoff-and-return). Each append is
limited to seven commands.

ID 4 is a placeholder. Replacement changes the first 4 to 2 unless the final
secondary value is 5 or 2, then always changes the first remaining 4 to 3.
Thus secondary 5/2 selects 3; other values select 2 and any second placeholder
becomes 3. Practice selects 2 for `active_side == 0`, otherwise 3. The
numeric `StartMenuHost.input_source` / `secondary_state1` values become
1/1 for secondary 5/2, 0/0 for
4/1, and 2/0 for 0; their meaning remains unresolved.

### Start-menu admission timeout-marker check

Only inactive-menu admission checks `battle_timeout_marker_get`.
A set marker skips input/admission and its writes; the existing-child branch
does not repeat that check. It blocks opening a menu without independently
canceling an already active child. The producer/reset belong to
[Match outcomes](match_outcomes.md#terminal-detector-and-classifier).

### Command identities and observed labels

The recovered class family is represented by the `start_menu_*_class_name`
annotations. `start_menu_create_module` (`0x0087BB10`) maps commands as
follows:

| ID | Child identity | Established visible role |
| ---: | --- | --- |
| `0` | `ccStartMenuKeyconfig` | Controls |
| `1` | `ccStartMenuBasicCmd` | Command Chart |
| `2`, `3` | `ccStartMenuPrivateCmd` | 1P / 2P Commands (character move list) |
| `5` | `ccStartMenuPractice` | Practice settings wrapper |
| `6` | `ccStartMenuSimpleDisp` | Simple Display |
| `7` | `ccStartMenuItemStock` | Label unresolved |
| `8`, `9` | `ccStartMenuMission` | Labels unresolved |
| `0xA..0xE` | `ccStartMenuYesNo` | Confirmation children |

Private-command children retain side `ID - 2`. Dispatching ID 4 would store a
null child, but Free Battle and Practice replace all their placeholders first.
The observed Free Battle order is Controls, 1P Commands, optional 2P Commands
in a joined-player-2 round, Command Chart, Simple Display, Back to Game Mode
Screen, Back to Character Select. Practice adds Practice after Simple Display.
The label joins are recorded in
[Modes and navigation](../../game/modes_and_navigation.md#free-battle-round-and-pause-menu)
and its [Practice menu](../../game/modes_and_navigation.md#practice-pause-menu).
The lists place 7/9 only in entry type 3; 0xE occurs there and in types 4/5.
Labels for those modes and producers of types 4/5 remain open.

`start_menu_update_module` sends child result 1 to parent state 1, result 2
to state 7, and result 3 to state 8. The Yes/No child returns 1 on one
completion and its `accepted_result` on the other: command A stores 2;
B..E store 3. Physical input mapping is not established by this updater.

The Shift-JIS fragments named `start_menu_battle_text`,
`start_menu_end_and_text`, `start_menu_mode_select_text`,
`start_menu_character_select_text`, `start_menu_return_confirmation_text`
and `start_menu_end_confirmation_text` establish these prompts:

| Command | Prompt interpretation | Accepted result / battle route |
| ---: | --- | --- |
| `0xA` | End the battle and return to game-mode selection? | `2 / 7` |
| `0xB` | End the battle and return to character selection? | `3 / 6` |
| `0xE` | End the battle? | `3 / 6`; no destination named |

They compose `<r対戦|たいせん>`, `を<r終了|しゅうりょう>して`,
`ゲームモード<r選択|せんたく>` or `キャラクター<r選択|せんたく>`,
and `に<r戻|もど>りますが、...よろしいですか？`; E uses
`を<r終了|しゅうりょう>しますが、よろしいですか？`.
All contain `<iconCANCEL>キャンセル`.

`start_menu_dispatch_result` (`0x0087D330`) completes the parent contract:

| Parent state | Behavior / result |
| ---: | --- |
| `1..4` | Run UI updater; return 0 |
| `5` | Poll child; return 0 |
| `6` | Return 1 |
| `7` | Wait for the effect; return 2 when complete |
| `8` | Wait for the effect; return 3 when complete |
| `9` | Complete/release asynchronous owner, then return stored result on a pass with no owner |

UI state 1 waits for the opening transition before entering 3; state 2 waits
for the closing transition before entering 6; state 3 handles input; state 4
advances the opening/closing animation. `start_menu_update_draw` calls this
dispatcher, then draw/update, and preserves the result for the resident owner.

### Simple Display selection

`start_menu_simple_display_initialize` (`0x00877870`) initializes its window
choices with row 0 selected, then disables `automatic_completion`. That
write does not choose a row and does not read the current Simple Display
setting. Input changes `selection`; `modal_choices_selection_get` returns
-1 for cancellation (`result == 2`) and the selected row otherwise.

Automatic completion mode 1 confirms and 2 cancels. When
`completion_counter` reaches `completion_threshold`, it publishes the result
and event bit `0x08`; confirmation animation then precedes window closure.
The initializer clears the counter but does not write the threshold. Thus a
zero-threshold mode-1 choice can confirm as soon as ready, but that initializer
alone does not establish a zero delay for every window.

`start_menu_simple_display_update` (`0x00877A10`) enables the setting for row
0 and disables it for row 1: On, Off order. The setter/getter use setting 0,
bit `0x02` of the active settings pack, with `practice` selected in manager
modes 2/3 and `alternate_settings` otherwise. The fixed initial On selection
and the current active setting are independent.

## Battle teardown and reconstruction

Outer states 11..14 load resources and construct the session; 15 runs it;
16 destroys it for routes other than 8; 17 releases archives. Route 8 instead
selects state 23 (`manager_replace_form`, `0x001EE1C0`) for continuation
mode 1 or state 24 (`manager_replace_configuration`, `0x001EE500`) for
mode 2. Both destroy the session, including its pause controller and auxiliary
system, and re-enter at state 13.

The rebuild and state-24 stage-archive comparison belong to
[Battle lifecycle](battle_lifecycle.md#continuation-encounters-rebuild-the-session).
The two proved immediate route-8 producers are `battle_request_form_replacement`
after an Ultimate Jutsu form request and `manager_request_alternate_reentry`
in the higher sequence; their owners are
[Awakening](../characters/awakening.md#effect-to-form-mapping-and-resource-replacement)
and [Match outcomes](match_outcomes.md#higher-level-sequence-counter-and-result-8-continuation).
Their user-facing triggering events remain unresolved. The bounded scan found
no other immediate resident writer; indirect writers and other overlays remain
open. This establishes object/resource reconstruction, without establishing
rewind or recorded-input playback.

### Start-menu result paths through teardown

Results 2/3 become routes 7/6 and traverse teardown states 16..18. State 18
sends route 6 through state 22 to state 3 and the full initialization chain
(4..10, then 11..15), including new session/controller allocation at 14.
Route 7 ends at terminal state 25. The outer routing belongs to
[Match outcomes](match_outcomes.md#outer-controller). Multiple commands can
produce result 3, so route 6 has no single menu label.

## Replay result and useful negatives

No battle replay capture/playback mechanism was established in the inspected
resident/BTL reconstruction and initialization paths. The bounded search
found no meaningful replay/record/playback/rematch identifier, replay buffer,
capture/playback mode, serialized battle snapshot, or explicit random-seed
or state restoration. That result does not establish absence of a replay
facility elsewhere; the search and call graph were not exhaustive.

The resident sector-read status returned by `sector_read_status_get` and
advanced through states 0..4 by `engine_update_frame_gate` belongs to
[Overlay ABI](../../runtime/overlay_abi.md) and
[Resident task system](../../runtime/task_system.md), not pause control.
