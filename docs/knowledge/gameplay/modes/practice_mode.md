# Practice-mode architecture

## Research coverage

Established: retail settings ownership/transactions, values/gates, dummy and
resource policies, reset/snapshot semantics, rendering failure, resident-global
ownership, and which Battle/Practice distinctions are latched rather than read
live. Open:
unrestricted owner reachability/overlap, complete AI/linked graphs, original
field names, mode reads through passed manager pointers outside the setting
getters, and hardware reproduction of packet exhaustion. Names come from
`@annotations/NA2`; per-routine details are in comments and addresses are live.

## Scope and evidence

This document owns the Battle and Practice Settings children in retail NA2
(`SLPS-25837`), starting-HP selection, and battle policies consuming Practice
settings. Binary identity and addressing are owned by
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
Localized strings and geometry belong to
[Practice screen layout](../../localization/font/screen_layouts/practice.md) and
[Battle and Practice settings presentation](../../localization/ui/battle/settings_presentation.md).
Related owners are [Battle AI](../session/battle_ai.md),
[Pause and replay](../session/pause_and_replay.md),
[Support mechanics](../characters/support_mechanics.md),
[Battle item inventory](../projectiles_and_items/battle_item_inventory.md),
[Chakra and guard](../combat/chakra_and_guard.md),
[Substitution](../characters/substitution.md), and
[Resident randomness](../../runtime/randomness.md).

Runtime evidence comprises six starting-HP states and observed retail text
loss; the remaining findings are static.

## Starting-HP selector

Health is an enum: Normal/full `0`, Half `1`, Almost/critical `2`.
Six paired states before and after selection show setup consumes it for both
fighters: `Fighter.hp` is respectively `1.0`, `0.5`, or float32 `0.1`,
identical on both sides.

`practice_pack_defaults` initializes Health to Normal.
`fighter_load_character_record` applies configuration HP/chakra, initializes
Link Gauge, and refreshes setting-derived flags/factors before applying Health
in Practice mode. Command and child-object initialization follow. Starting HP
therefore participates in construction as well as continuous policy.
A reconstruction snapshot restore can subsequently write HP directly.

Character construction and the factory census belong to
[Battle entities](../session/battle_entities.md).

## Ownership chain

The manager singleton pointer is `battle_manager`. `BattleManager` names
its mode, active side, menu state, control mode, settings packs, persistent
Difficulty/Strength mirror, and live fighter pointers. Mode `3` is Practice;
mode `2` is Battle. The active pack serves modes `2/3`, the alternate pack
other modes. Three packs are default-initialized; the third pack's established
Practice consumer is the persistent Strength mirror `difficulty`.

The preparation UI's `PracticePreparationOwner.settings` owns a
`SettingsParent`. `settings_parent_construct` allocates a `PracticeSettings`
child in mode `3`, a `BattleSettings` child in mode `2`, and neither in
other modes. The parent and children are respectively `0x54`, `0xB8`, and
`0x68` bytes.

The main update chain is `preparation_settings_update` →
`settings_parent_update` → `practice_settings_update`, with the last
call only in parent state `5`. Drawing separately follows
`stage_select_close` → `settings_parent_draw` →
`practice_settings_draw`.

A second owner, `PracticeWrapper.child`, invokes the same Practice update and
draw through `practice_wrapper_update` and `practice_wrapper_draw`.
It is module type `5` of `StartMenuHost`, not a second settings implementation.
`start_menu_create_module` replaces the host's sole module, copies input
source/context, constructs the replacement, and enters host state `5`.
The factory cannot retain two modules in that slot.

### Resident scheduling and controller lifetime

The outer controller pointer is `btl_process`.
`manager_dispatch_state` polls `battle_start_menu_update` before its outer
state handler. `PracticeDriver.variant`, returned by
`battle_driver_variant_get`, is distinct from manager mode; variant `2`
adds the standalone Practice command. The shared start-menu transaction belongs
to [Pause and replay](../session/pause_and_replay.md#resident-ownership-and-top-level-result-routing).

Outer state `9`, handled by `battle_state_select_stage`, lazily constructs
the `0x16C`-byte preparation owner. Variant `2` supplies raw stage value
`6`; that does not establish a player-facing stage name. Preparation owner
state `4` updates/draws the generic settings parent. While owner update
returns neither `1` nor `-1`, the outer handler retains and draws it.
Either result destroys/frees the owner and clears its pointer:

| Result | Outer transition |
| ---: | --- |
| `1` | Store selected stage, enter state `10`, countdown `3` |
| `-1` | Enter state `7` |

Successful preparation thus destroys that owner before resource-loading states
`11..14` and running state `15`. Ordinary child open/close retains it.

`battle_start_menu_admission` is cleared by the outer state-`2` initialization,
set when `PracticeSessionPhase.phase` advances `3 → 4`, and cleared on the
inspected departure from active phase `4` and on session completion.
The start menu requires admission `1`, local menu state `0`, manager menu
state `0`, all remaining opening gates below, and an eligible input side.
This establishes phase separation, not elapsed duration or every indirect route.

### Registered standalone Practice selection

`practice_wrapper_vtable` is resident, while its methods, type descriptor,
and name `ccStartMenuPractice` belong to BTL:

| Operation | Routine |
| --- | --- |
| Destroy, optionally free wrapper | `practice_wrapper_destroy` |
| Construct child | `practice_wrapper_construct` |
| Update child, Boolean completion | `practice_wrapper_update` |
| Draw child | `practice_wrapper_draw` |

The wrapper is `0x10` bytes. It constructs the same `0xB8`-byte child with
backdrop variant `0`; the main parent uses variant `1`.
The resident table supplies indirect dispatch; its location does not prove
that BTL methods remain usable after overlay replacement. See
[Overlay ABI](../../runtime/overlay_abi.md#indirect-dispatch-is-application-abi-not-loader-binding).

Variant `2` places Practice command `5` at list index `4`.
`start_menu_replace_command` replaces the first matching command:
the list's ID `4` becomes `2` for active side `0`, or `3` otherwise.
Practice stays at index `4`. Other command IDs are not given player-facing
names here. Selection invokes the factory by stored command ID; the later
state-`5` dispatch invokes update/draw.

The host uses the active side as its input source; the source-`2` OR-both
branch is separate. Its transitions are:

| Input/gate | Effect |
| --- | --- |
| Transition not ready | No selection input |
| New `0x20` | State `3 → 4` |
| New `0x40` | State `2`, request closing transition |
| `0x4000 / 0x1000` | Increment/decrement selection, wrap by command count, repeat countdown `4` |
| State `4`, `transition_x >= 562.0` | Construct selected command |

This is an invocation-counted transition, not measured elapsed time.

`battle_start_menu_input_side` considers sides `1/2`: their COM bit must be
clear unless manager control mode is `3`; variant `2` admits only the active
side, and that side must have new-input bit `0x800`.
Changing the selected command does not change the Practice input owner.

Additional opening gates in `battle_start_menu_update` are:

- A live `battle_session` with nonzero `battle_route_code` blocks opening.
- `fighter_coordinator_get_state` must return zero. Missing graph/coordinator
  returns `-1`; construction sets the selector to `1`, so graph existence
  alone is insufficient. The graph pointer is `battle_hub`.
- `battle_loading_active` must be inactive; timeout marker
  `battle_timeout_marker` must be zero.
- Admission `battle_start_menu_admission == 1`, local state
  `battle_start_menu_state == 0`, and
  `BattleManager.menu_state == 0` are all required.

Coordinator ownership belongs to
[Battle entities](../session/battle_entities.md#derived-fighter-registrycoordinator),
graph ownership to [Battle lifecycle](../session/battle_lifecycle.md#session-construction),
loading to [Startup](../../game/startup.md#controller-construction-resources-and-phases),
and the timeout producer to
[Match outcomes](../session/match_outcomes.md#terminal-detector-and-classifier).
The full coordinator graph remains unresolved.

Once manager menu state is nonzero and local menu state is `1`, the existing
host allocation/poll branch does not recheck opening gates.
`practice_driver_callback` returns zero and adds no Practice update/draw
([Mode flow](../../game/mode_flow.md#btl-handoff-and-return)).

`battle_destroy_graph` retires any remaining `battle_start_menu_host` before
deleting the graph: installed-module destruction, owned-handle release,
host free, global clear. `battle_session_initialize` clears that global
without a destructor; this is not a retirement path. See
[Battle lifecycle](../session/battle_lifecycle.md#teardown-order).
Wrapper destruction tears down/frees its child, clears the pointer, and
optionally frees the wrapper. These paths do not establish visible owner
overlap or unrestricted indirect reachability.

### Generic parent states

`settings_parent_update` dispatches `SettingsParent.state`:

| State | Behavior |
| ---: | --- |
| `0` | Wait for transition resource; ready → `2` |
| `1` | Finish close transition |
| `2` | Update selectors/open available child |
| `3` | After two parent updates, return recorded result |
| `4` | Update Battle child; completion → `2` |
| `5` | Update Practice child; completion → `2` |

`btl_reset_player_records` resets shared presentation and starts the parent
transition. Preparation reinitialization and completed stage confirmation use
it; the latter first enters preparation owner state `4`.

Unavailable selector entries are skipped. Selector result `2` cancels the
whole parent with result `-1`; result `3` opens/resets the available Battle
or Practice child; completion of both selectors closes with result `1`.
Cancel plays `0x33`; open/success plays `0x34`.

At this layer, manager control mode `3` supplies source `2` to both
selectors; otherwise their sources are `0` and `1`.
`SettingsSelector` caches new, secondary, and held masks. Once Practice opens,
its own input handler resamples the active side rather than using those caches.

Close completion updates manager control assignment even when the parent
result is Cancel: Manual Status chooses mode `0`; non-Manual chooses
mode `1` for active side `0`, or `2` otherwise.
`battle_control_mode_set` clears both COM bits for mode `0`, sets Player 2's
for `1`, Player 1's for `2`, and both for `3`. Thus Manual changes
controller assignment even on preparation cancellation without changing the
stored Status option. The delayed parent result is a separate boundary from
child completion.

`preparation_settings_update` propagates result `1`. Result `-1` enters
owner state `5` when its context is nonnegative, or reinitializes the owner
otherwise.

Each versus selector starts in phase `0` (`settings_selector_idle`): Circle
readies it, Cross cancels the parent, Square opens the settings child, and
Triangle opens Customize Jutsu only when the selector's flag at `+0x14` is
set. `settings_parent_assign_sides` derives selector availability and the
manager side flags from control mode; `btl_reset_player_records` reruns it
together with `settings_parent_refresh_sides`.

### Battle and Practice discriminators

The modes differ by `BattleManager.mode` (`2`/`3`) and `BtlProcess.entry_type`
(`1`/`2`), which `battle_driver_variant_get` returns. `free_battle_callback`
and `practice_callback` both fetch the existing process through
`battle_process_get_or_create`, which never rewrites its entry type.

Most consumers read both values when they run. Every
`battle_setting_handlers` entry reads the mode per call: Practice-only keys
return fixed values outside mode `3`, Handicap is read only in mode `2`, and
Time returns Unlimited (`100`) in mode `3`, which is the source of the
Practice timer. Difficulty/Strength, Items, Chakra, Ultimate Jutsu and
Simple Display share the active pack. A scan for direct loads of the manager
global found 17 resident and 37 BTL mode reads, all in code that runs when
needed (AI, Ultimate Jutsu contests, fighter construction and damage, versus
and battle drawing, the start-menu factory); reads through a passed manager
pointer were not inventoried. Outer states `1`, `5`, `7`, `9`, `14`, `15` and
`18` read the entry type as they run.

These distinctions are latched earlier:

| Latched value | Owner | Fixed at |
| --- | --- | --- |
| Battle (`+0x38`) or Practice (`+0x3C`) child and the selectors' Customize Jutsu flag (modes `2`/`4`, control mode not `3`) | `settings_parent_construct` | Preparation owner construction |
| Practice Character Select (1P versus COM, control mode from active side) | `character_select_prepare_practice` | Character Select allocation |
| Preselected stage (`6` for entry type `2`) and owner context | `battle_state_select_stage` | Preparation owner allocation |
| Resident `prac.ccs` in `practice_archive` | Outer states `1`/`5` for entry type `2`; released by `battle_cleanup_resources` and `battle_return_to_mode_select` | Mode entry |
| Manager settings reset | Outer state `2` | Mode entry; later returns re-enter at state `3` |

`practice_archive` holds `prac.ccs`. The separate `loading_spload_archive`
holds `loading/spload.ccs`; `loading_request_character_portrait` loads it and
`loading_release_spload` releases and clears it.

## Battle Settings child

The mode-`2` child's local transaction uses `BattleSettings.values`.
Its row/Handicap geometry belongs to
[Battle and Practice settings presentation](../../localization/ui/battle/settings_presentation.md#battle-rows-and-handicap).

| Row | Values | Manager key | Local default |
| ---: | --- | ---: | ---: |
| `0` | Time: `10..90` in tens, `99`, Unlimited (`100`) | `6` | Index `9` / `99` |
| `1` | Difficulty: Simple, Easy, Normal, Hard, Insane, Ultimate | `0xB` | `2` |
| `2` | Items: None, Less, Normal, More | `7` | `2` |
| `3` | Chakra: Normal, Unlimited | `2` | `0` |
| `4` | Ultimate Jutsu: No Use, Random, Command, Timing, Turn, Combo | `5` | `2` |
| `5` | Handicap: `0-10..10-0` | `8` | `5` |

`battle_settings_load` converts numeric time to `battle_time_values` index,
then clamps by `battle_value_counts = {11,6,4,2,6,11}`.
Profile slot `0x6A` clear caps Difficulty at index `4`.

`battle_value_arrays` reuses the exact Practice Strength, Items, Chakra,
and Ultimate arrays, including the resident Normal/Unlimited strings;
these are shared resources, not merely similar labels.

`battle_settings_input` applies on Confirm and closes on Confirm or Cancel.
Defaults finds the first time value at least `99`, writes
`{9,2,2,0,2,5}` locally, plays `0x33`, resets help, and queues the Defaults
notice. Only Confirm commits those defaults. Selection/repeat/input/phase/help
fields are named in `BattleSettings`; manager defaults are a separate operation.

## Practice child record

`PracticeSettings` names the archive handle, four backing/render objects,
four prompt/panel objects, three sprites, help object, phase, selected row,
repeat countdown, row offset, backdrop variant, cyclic presentation phases,
alpha, reveal delay, draw transform, input masks, 17 local values, and two
window starts. Original engine class names for several resources and
presentation accumulators remain unknown.

`practice_settings_snapshot` resets presentation/input/page state, snapshots
manager values through `practice_settings_load`, clamps by
`practice_value_counts`, and resets help. It retains resource pointers and
does not write the directional-repeat countdown.

## Rows, local values, and manager storage

The 17 rows use `PracticeSettings.values[row]`. Pack members belong to
`BattleManager.practice`; bit positions below are in `PracticeSettingsPack.flags`.
Default means the child-local Defaults action.

| Row | Label and values | Count | Manager key / storage | Default |
| ---: | --- | ---: | --- | ---: |
| `0` | Health: Normal, Half, Almost | 3 | `4` / `health` | `0` |
| `1` | Chakra: Normal, Unlimited | 2 | `2` / flags bit 2 | `0` |
| `2` | Linked Attack: Normal, Unlimited | 2 | `3` / flags bit 3 | `0` |
| `3` | Ultimate Jutsu: No Use, Random, Command, Timing, Turn, Combo | 6 | `5` / `ultimate` | `2` |
| `4` | Linked Mode: Manual, Auto | 2 | `SupportSideRecord.linked_mode` | `1` |
| `5` | Items: None, Less, Normal, More | 4 | `7` / `items` | `2` |
| `6` | Commands: OFF, ON | 2 | `1` / flags bit 0 | `1` |
| `7` | Damage: OFF, ON | 2 | `9` / flags bit 4 | `1` |
| `8` | Guide Ninja Sound: OFF, ON | 2 | `0xA` / flags bit 5 | `1` |
| `9` | Status: Manual, COM, Stand, Jump, Double-jump | 5 | `0xC` / `status` | `2` |
| `10` | Strength: Simple, Easy, Normal, Hard, Insane, Ultimate | 6 | `0xB` / `strength` | `2` |
| `11` | Attack: No, Single, Combo, Projectile, High Speed Move, Ultimate Jutsu, Jutsu | 7 | `0xD` / `attack` | `0` |
| `12` | Guard: No, Yes | 2 | `0xE` / `guard` | `0` |
| `13` | Move: Stay, Follow | 2 | `0xF` / `move` | `0` |
| `14` | Substitution Jutsu: Normal, No | 2 | `0x11` / flags bit 7 | `0` |
| `15` | Linked Attack: Don't use, Normal, frequent/random (`乱発`) | 3 | `0x12` / `linked_attack` | `1` |
| `16` | Extra Hit Counter: Normal, Return | 2 | `0x10` / flags bit 6 | `0` |

Rows `2` and `15` share an English-facing label but control different
policies: player Link Gauge charging and non-Manual dummy linked use.
Status is key `0xC`, Strength key `0xB`.
`manager_difficulty_set` mirrors only Strength into the persistent
`BattleManager.difficulty` byte.

Linked Mode is outside the 12-byte pack. It uses the controlling side's
three-byte `SupportSideRecord`; Manual is `0`, Auto `1`.
`support_linked_mode_get` and `support_linked_mode_set` operate on that
side's byte. `support_owner_construct` initializes both records to
`{0,1,0}`, so recreation starts Auto. Construction order creates the manager
before either settings snapshot. The helpers themselves do not safely handle
a missing manager: they select a zero record pointer before the final access.
The setter changes only the byte, without rebuilding manager/support objects
or writing an AI handshake. Ownership belongs to
[Support mechanics](../characters/support_mechanics.md#ownership-model) and
[Battle entities](../session/battle_entities.md#separate-owner-and-exact-side-slots).

### Row availability

`practice_row_enabled` governs input and grey presentation:

| Rows | Enabled |
| --- | --- |
| `0..9` | Always |
| `10` Strength, `14` Substitution | Status COM (`1`) |
| `11..13` Attack/Guard/Move | Stand, Jump, Double-jump (`2..4`) |
| `15..16` Linked Attack/Extra Hit | Non-Manual |

Disabled values cannot be changed. Profile slot `0x6A` additionally removes
Strength index `5` when zero. The resident difficulty selector uses the same
gate. Slot acquisition and its finite-Survival producer belong to
[Content availability](../../game/content_availability.md#recovered-difficulty-word-producer);
Practice consumers establish no separate acquisition event.

## Input and child state transitions

`practice_settings_input` samples the active side's new/held masks.
A positive repeat countdown chooses new presses and decrements; otherwise
held/repeat input drives navigation. No held direction clears the countdown.
Accepted navigation/value changes reload `4` and play `0x35`.
Confirm, Cancel, and Defaults bypass direction handling.

On Confirm, `practice_settings_input` sets phase `1` at `0x008816E0`, then applies at
`0x008816F4`, without directly clearing the raw new/held masks, command outputs or
fighter logical input. Menu acceptance and subsequent battle-input admission
are separate operations.

| Effective direction | Effect |
| ---: | --- |
| `0x1000` | Previous row, wrap `0 → 16` |
| `0x4000` | Next row, wrap `16 → 0` |
| `0x2000` | Increment enabled value below maximum |
| `0x8000` | Decrement enabled value above zero |

Reset clears sampled/effective masks but leaves repeat countdown intact.
It can survive close/reopen until directional updates decrement it or an
update sees no held direction. It selects an input mask; it does not alter
resources, phase, or draw gates.

`practice_settings_update` owns phases:

| Phase | Behavior |
| ---: | --- |
| `0` | Alpha rises in `0x32` steps to `0xC0`, then phase `2` |
| `2` | Input, navigation, value edits, actions |
| `1` | Alpha falls in `0x32` steps; completion only at zero |

Every update first advances cyclic presentation phases and row windows.
Upper rows `0..8` and lower rows `9..16` each have starts `0..2`.
The row offset approaches the selected page without reconstructing render
objects. Exact accumulators, window parameters, and easing constants are in
the update annotation; geometry belongs to
[Battle and Practice settings presentation](../../localization/ui/battle/settings_presentation.md#practice-content-and-contexts).

| New press | Transaction |
| ---: | --- |
| `0x20` | Confirm: apply immediately, fade out, sound `0x34` |
| `0x40` | Cancel: discard local edits, fade out, sound `0x33` |
| `0x100` | Defaults: replace only local values/help, sound `0x33` |

Defaults requires Confirm to persist. Cancel discards it; reopening snapshots
manager settings again. Rendering inserts the native section heading before
row `9`; its construction details are in `practice_settings_draw`.

## Confirm/apply side effects

`practice_settings_apply` writes the 16 manager-backed values through
`battle_setting_set`, Linked Mode through `support_linked_mode_set`, then
runs the dummy bridge. Setter mode checks and the Strength mirror do not
perform a general resource/fighter reset.

The order is Commands, Items, Health, Ultimate Jutsu, Linked Attack gauge,
Chakra, Damage, Guide Ninja Sound, Linked Mode, Status, Strength, Attack,
Guard, Move, Extra Hit, Substitution, dummy Linked Attack, then the bridge.
This is direct ordered mutation, without a staged manager transaction or
rollback. The post-write Strength comparison below depends on that order.

### Completion boundaries and fighter setting refresh

Main child completion returns the generic parent to selector state `2`,
retaining its child. Standalone completion becomes Boolean `1`; the host
returns to state `1` and reopens its command list without destroying its
module. The host updates before drawing, so that same invocation no longer
draws the completed child. Confirm and Cancel use the same completion route;
their difference is the earlier apply/discard step.

Selecting another module destroys/replaces the retained module and constructs
a new child. Reopening Practice through the factory therefore snapshots
current manager values in a new child. Whole-host teardown also destroys the
installed module. Ordinary main parent closure retains its constructed child.

Child completion does not finish the resident start-menu transaction.
Manager menu state stays active until overall host completion. Overall result
`1` destroys the host, clears manager menu state, and runs
`fighter_refresh_battle_settings` on both live fighters:

| Setting | Fighter update |
| --- | --- |
| Ultimate `5` | `staged_input_inhibit = (value == 0)` |
| Chakra `2` | `chakra_debit_inhibit = (value != 0)` |
| Handicap `8` | `handicap_attack`, `handicap_defense`; Practice neutral `5` gives `1.0` each |

The refresh does not write position, action, motion, input/history, current HP,
chakra, Link Gauge, item cache, or AI work. Its construction consumer is
`fighter_load_character_record`;
indirect overlay callers were not inventoried. Practice acquires no Handicap
control through this refresh
([Damage](../combat/damage.md#handicap-factors)).

Within one `manager_dispatch_state` invocation, menu work precedes the outer
state handler. Running state `15` then advances the session; when its updater
returns zero, subsystem masks are collected and dispatched. An active menu
zeros the first allowed mask, while the independent second mask and exceptions
remain. Confirm's manager writes therefore precede subsequent session dispatch,
but child completion leaves fighter first/third work suppressed while the
host remains active. Overall host closure can admit that work in the same
manager invocation; other suppression and session overrides still apply.
Acceptance does not itself guarantee a consumer runs or that held input is
neutralized. This is static invocation order, not a measured frame boundary. See
[Pause and replay](../session/pause_and_replay.md#selective-update-gating) and
[Battle AI](../session/battle_ai.md#controller-ownership-and-lifecycle).

### Dummy-status bridge

`practice_toggle_com` targets the side opposite the active side:
active `0` targets Player 2, active `1` Player 1.
It always stores `Status != Manual` in that manager side's COM bit,
including when no live fighter exists. A null fighter skips actor work.

Manual clears the fighter control/state word's behavior subfield.
Non-Manual initializes that subfield to `1` and calls `ai_initialize`
only when the previous subfield was zero or the comparison flag requests it.

That flag compares local Strength with its getter **after** writing Strength.
Ordinary Practice setter success makes it false even when the value changed.
An already-nonzero behavior subfield therefore avoids reinitialization;
`ai_tick` hot-reloads the profile instead. A broader “Status changed”
interpretation of the comparison is not established.

`ai_initialize` resets common work for both side records, then loads the
passed fighter's Strength profile, descriptor modifiers, and remaining side
initialization. It does not reset HP, chakra, or Link Gauge.

## Dummy behavior routing

Manual allows another controller. COM uses general AI and enables Strength
and Substitution. Stand/Jump/Double-jump use scripted behavior and enable
Attack/Guard/Move. Linked Attack/Extra Hit are available for every non-Manual
status.

The setting consumers are `ai_opponent_route_update` (COM branch),
`ai_guard_reaction_update`, `ai_state9_update` (Move Follow), and
`ai_state17_select_action` (broad Attack decision).
That broad path rejects Attack `0`, requests projectile/high-speed move for
`3/4`, resolves Ultimate/Jutsu for `5/6`, and keeps ordinary timing/action
selection for `1/2`.

`ai_states` contains two `0x1E0`-byte `AiState` records.
Names include request flags `logical_mask`, controller `state`,
`request_latch`, countdown array, effective `parameters`, selected
Ultimate slot `cached_action_index`, `linked_countdown`,
`practice_jump_countdown`, `practice_attack_countdown`,
`linked_partner_type`, and `linked_handshake`.
The general layout belongs to
[Battle AI](../session/battle_ai.md#per-side-state-block).

The direct seven-way dispatcher `ai_practice_attack_update` runs when the
retry timer is zero and shared eligibility passes. It initially reloads
`60`:

| Attack | Request after shared checks |
| --- | --- |
| No `0` | None; retry timer remains |
| Single `1` | Logical `0x00001000` |
| Combo `2` | Select ordinary action and queue its identifier |
| Projectile `3` | Logical `0x01000000` |
| High Speed Move `4` | Logical `0x00030000` |
| Ultimate Jutsu `5` | Validate selected slot; logical `0x08001000`, timer `240` |
| Jutsu `6` | Search classes `0x000F0000`, then `0x00080000`, queue valid action |

Failed `5/6` branches write flags `8` and clear retry timer. Fighter/action
validation can still stop any listed effect.

`ai_practice_scripted_tail` integrates the scripted rows:
Guard Yes can select code `0x12` with countdown `30`; Follow maintains
`5`; Jump/Double-jump reach `0x24` through their timer;
Stand/nonzero Attack can select `0x25`, followed by the attack dispatcher.
These are controller requests, not immediate fighter-state assignments.
Priority and exact gates belong to
[Battle AI](../session/battle_ai.md#scripted-practice-reaction-priority);
preceding ordinary/COM reactions to
[its main reaction stage](../session/battle_ai.md#main-reaction-stage-and-later-rewrites).

### Dummy ordinary-response recovery

`stage_navigation_response` (`0x006F4080`), used by AI state 35, requires
self in major 5. It calls `recovery_late_admission` at `0x006F41C0`, then
`recovery1_admission` at `0x006F41F8` if the first returned zero. Either
exact-1 result writes logical `0x10000` at `0x006F4230`. Selected stage slots
5/22 first check a predicted planar endpoint with `field_clamp_position`;
a failed clamp resets the AI and returns.

These admission helpers are broad eligibility queries. The native fighter
dispatcher still applies the actual first-grounded or late input/cursor/history
gates; their algorithms and independent automatic contacts belong to
[Hit response](../combat/hit_response.md#recovery-decision-boundaries).
This is a command proposal, not a direct recovery-state assignment.

`ai_dispatch_state` (`0x006FB840`) also emits `0x10000` from state 33 while
self action is `0x5D`, and from states 34/36 after resetting. State 36 is used
by scripted Jump/Double-jump. The same command thus has downed, ordinary
response and jumping consumers. `ai_practice_scripted_tail` and
`ai_late_reaction` do not expose a separate rebound setting; the 17 native
rows above contain none.

For the scripted statuses, `ai_main_reaction` goes straight to the tail, so
states 33 and 35 are not constructed, and `ai_practice_linked_attack` replaces
the support reactions that construct state 34. `ai_late_reaction` runs its body
only while `awakening_root_exception` holds for the dummy (awakened Deidara or
Gaara); only then can it select state 34 or, for Jump, write `0x10000` on an
expired jump countdown. The tail selects state 36 for Jump whenever the
countdown is zero outside majors 7/8, including the ordinary hit response
(major 5). Double-jump selects it only in major 0, or in major 2 with action
`0x18/0x22/0x24`. Static consequence: outside that awakening exception, a
Stand or Double-jump dummy emits no `0x10000` during a hit response, and a Jump
dummy emits it only when its 90-count timer expires there. Whether such a
timed press lands in a rebound window has not been observed. Decision priority and state-constructor coverage
remain owned by [Battle AI](../session/battle_ai.md#main-tick-and-output-boundary).

`fighters_update` (`0x0024FD80`) runs the actor's AI callback before
`fighter_copy_input_outputs`, then `fighter_update_phase_and_exits`, and then
`fighter_consume_logical_input`. A command can reach a response decision in
that pass, and a later jump consumer can see the state produced by it.
The bridge can suppress the proposed output. These are established ordering
facts, not an unconditional recovery success guarantee.

### Strength profiles

Strength is an AI profile selector, not a scalar damage multiplier.
`battle_strength_get` selects one of six menu-visible `0x50`-byte profiles
of 40 signed halfwords from `ai_behavior_profiles`.
Each side keeps an effective copy in `AiState.parameters`.
Profile consumers belong to
[Battle AI](../session/battle_ai.md#configuration-and-behavior-profiles) and
[its parameter ledger](../session/battle_ai.md#direct-profile-parameter-consumers).

Initial AI setup skips the other modes' secondary percentage modifier in
Practice, then applies descriptor-bit modifiers: bits `1/4/8` multiply
parameters `16/8/24` respectively by `1.2`, truncating to integer.
Practice Strength hot reload copies the new profile for the current side
without repeating those three adjustments.

Practice policy uses parameters `12` (Extra Hit cooldown), `11/39`
(response threshold/retry), `38` (linked retry), and `21` (linked request
threshold). `prng_inclusive(N)` returns inclusive `0..N` by modulo reduction
with bias ([Resident randomness](../../runtime/randomness.md#mt-wrappers)).

### Linked Attack and Extra Hit

Dummy Linked Attack key `0x12 == 0` blocks both request gates.
`ai_schedule_own_support` uses the Strength-linked policy after its
current-action and partner/action checks:

- Linked timer is `parameter38 + RNG(0..parameter38)`.
- Initial threshold is parameter `21`; with an available partner whose type
  is not `4`, fighter action state `5` replaces it with
  `p21 * trunc(1.5 * p21)`.
- Strict `RNG(0..100) < threshold` selects controller code `0x26`.

`ai_practice_linked_attack` supplies the setting-specific countdown policy:

| Setting/status | Timer | Threshold |
| --- | --- | --- |
| Normal / COM | `30 + RNG(0..60)` | Parameter `21` |
| Normal / scripted, Manual Linked Mode, no partner | `30` | `100` |
| Normal / other scripted conditions | `90` | `100` |
| Frequent/random | `5` | `100` |

A strict threshold draw requests logical bit `0x00200000`.
A separate no-current-request branch under its Linked Mode/partner gates
initializes `90 + RNG(0..30)`.

Retail parameter-`21` values are `0,0,0,0,30,50`.
An unmodified threshold accepts `0/30/50` of 101 result values; threshold
`100` accepts 100, not all. These are nominal ratios because modulo bias
remains. The boosted values `1350/3750` accept every `0..100` draw;
zero remains zero.

After code `0x26` selection, Auto Linked Mode writes handshake `2`.
Manual writes `1` without a partner, `2` when the available partner's
`SupportObject.reason` is `1`, and otherwise leaves the handshake unchanged.
Handshake `1` shortens the linked timer to `5`; the cached partner selector
is separate.

`ai_dispatch_state` code `0x26` writes request `0x20000000` and clears
the request latch only for signed handshake `2`. It does not reread Linked
Mode or rewrite the handshake; the menu setter does not perform this request.
The full linked graph and original field names remain unresolved
([Battle AI](../session/battle_ai.md#action-state-dispatcher)).
Rows `4/15` therefore interact through scheduling/handshake and request
enable/frequency while remaining distinct controls.

Extra Hit Return (`1`) makes `ai_select_exchange_response` clear cooldown
and commit the candidate immediately: code `0x0D` for response flags
`0x0400/0x1000`, code `0x13` for `0x0100`.
Normal retains cooldown, profile, and phase gates. Full state/profile
ownership belongs to
[Battle AI](../session/battle_ai.md#direct-state-constructors),
[its RNG section](../session/battle_ai.md#rng-ownership-and-confirmed-uses), and
[its parameter ledger](../session/battle_ai.md#direct-profile-parameter-consumers).

### Item amount

`field_item_amount_apply` consumes Items:

| Setting | Spawn effect |
| --- | --- |
| None | Reject entirely |
| Less | Keep base, extra count zero |
| Normal | Keep caller extra count |
| More | Extra count below one → `2`, otherwise double; another base-style spawn if `RNG(0..100) < 80` |

More's extra chance accepts 80 of 101 values, nominally `79.21%` with modulo
bias. Position and caller spawn kind still matter; amount does not select
item identity. Identity pools/weights belong to
[Random field-item selection](../projectiles_and_items/battle_item_inventory.md#random-field-item-selection).

### Substitution Jutsu

`ai_dispatch_state` code `20` checks Practice, then Substitution key
`0x11`. No Use (`1`) selects controller `0x12` and exits;
Normal (`0`) writes guard-input timing `-2` through
`guard_set_input_timing` and exits. The negative sentinel permits the early
eligibility path in `input_match_trigger_binding`.
Its maintenance and shortcut belong to
[Substitution](../characters/substitution.md#negative-guard-age-sentinel-and-temporary-effect-id-9).

### Presentation options and Ultimate gate

The presentation options are consumed outside the menu renderer:

- Damage OFF stops `practice_damage_draw`; ON still requires its enabled bit
  and side matching the active side.
- Commands OFF clears/hides the HUD, skips drawing, and forces its internal
  phase closed.
- Guide Ninja Sound OFF blocks event and scheduler paths. ON still needs
  their own event/audio-busy gates
  ([Battle audio](../session/battle_audio.md#guide-ninja-sound)).

`ai_state15_select_action` tests Ultimate raw key `5` only as zero versus
positive. Zero skips optional ultimate selection; positive retains chance,
target/action, and distance checks.

The setter stores the raw byte and refreshes both
`BattleCharacterSlot.ultimate_mode` caches;
`manager_refresh_selected_jutsu` fills the same caches. Fighter refresh
reduces it to `staged_input_inhibit = (value == 0)`; resident action admission
rejects while inhibited. The active rule stores `BattleRuleMode.ultimate_mode`.

`battle_rule_ultimate_mode_get` returns that raw rule byte or `-1` when
unavailable. `jutsu_presentation_update` falls back to the corresponding
manager side cache for `-1`, then passes the raw mode to
`sp_skill_play_start`. Outside manager mode `6`, skill-play creation
forwards it to `jutsu_contest_create`:

| Value | Meaning | Controller |
| ---: | --- | --- |
| `0` | No Use | None |
| `1` | Random | Sequential choice of `2..5` |
| `2` | Command | `0x3E8` bytes |
| `3` | Timing | `0xFE4` bytes |
| `4` | Turn | `0x108` bytes |
| `5` | Combo | `0x100` bytes plus helpers |

Random uses `jutsu_random_mode_pairs` in order
`(3,40),(2,55),(4,50),(5,100)`, making a fresh inclusive draw for each and
accepting the first draw at most its threshold. These are sequential tests,
not single-draw weights. Under uniform-draw approximation:

| Mode | Nominal probability |
| --- | --- |
| Timing | `418241/1030301` |
| Command | `339360/1030301` |
| Turn | `137700/1030301` |
| Combo | `135000/1030301` |

Modulo bias prevents exact probabilities. The final `<=100` always accepts,
so encoded fallback `2/3` is unreachable under this helper contract.
The factory contains mode `6`, but the retail menu count/clamp permits only
`0..5`. AI admission and later interaction-controller selection are separate
layers.

## Defaults, restart, and resource semantics

Local Defaults, manager defaults, and discrete controller reconstruction have
different ownership and effects.

### Manager defaults

`practice_pack_defaults` initializes one 12-byte block.
Manager construction applies it to all three packs; visible defaults match
the local Practice Defaults values. Flags bit `0x02` is Simple Display,
whose menu/getter/setter belong to
[Pause and replay](../session/pause_and_replay.md#simple-display-selection).

`battle_settings_reset_defaults` resets active/alternate packs, then in
modes `2/3` reapplies Strength from the persistent mirror.
Its established caller is Practice outer state `2`; no Battle caller is
established. Merely selecting Battle mode assigns mode `2` and rejoins its
common selector flow. Manager reset is separate from local menu Defaults.

### Discrete Practice-controller reset

Outer state `2` waits for the preceding transition, clears controller
globals, resets manager settings, and enters `3`.
`practice_driver_reset_snapshots` in state `3` seeds both resource snapshots
to HP `1.0` and chakra `15.0`, clears both item caches, clears transition
globals, and enters `4`.

`item_cache_clear` clears only the two sides' three-entry item caches.
It does not touch live HP/chakra/gauge. Cache construction/restoration,
category-`6` exclusion, and restoration normalization of IDs `0x51..0x73`
belong to
[Battle item inventory](../projectiles_and_items/battle_item_inventory.md#item-cache).

`battle_save_reentry_values` and `battle_restore_reentry_values` consume
only these mask bits:

| Bit | Capture / restore |
| ---: | --- |
| `0x01` | Fighter HP / per-side HP snapshot |
| `0x02` | Fighter chakra / per-side chakra snapshot |
| `0x10` | Global timer remaining/elapsed pair |
| `0x20` | Three-slot non-category-`6` item cache |

A capture side argument `1` or `2` first seeds **both** sides' HP/chakra
snapshots and clears both item caches, then captures the requested side.
Timer bit `0x10` performs one global two-word copy after any side loop.
There is no Link Gauge snapshot bit.

The current timer words are `battle_countdown_remaining` and
`battle_countdown_elapsed`; their saved words are
`battle_countdown_remaining_snapshot` and `battle_countdown_elapsed_snapshot`,
respectively.

Saved-battle reconstruction condition `2` makes `battle_create_graph`
restore both sides. Both full and `0xFFFFFFEF` masks include item state;
the latter excludes timer `0x10`. This is a real reconstruction snapshot.
Outer initialization forgets the cache; later requested capture repopulates it.

### Reconstruction entry and retained setting owners

For outer variant `2`, the inspected state-`18` route with battle-route
`6` enters `22`. `practice_driver_reenter` waits for a resource fence and
returns to state `3`. It reseeds resource snapshots/clears caches without the
state-`2` manager-default call. Later preparation constructs a fresh owner.
It therefore reconstructs snapshots/UI while retaining settings packs;
it is neither local Defaults nor restoring a closed menu's local values.
See [Pause and replay](../session/pause_and_replay.md#start-menu-result-paths-through-teardown).

Route-`8` branches capture differently:

- `manager_replace_form` captures both sides with side `-2`, mask `-1`
  before destroying the session.
- `manager_replace_configuration` selects one side from the reused
  `current.sides[0].pending_character_id` storage.
  Variant `2` captures only items with mask `0x20`; `0xFFFFFFEF` capture
  belongs to variant `4`.

The single-side item capture first resets both resource snapshots to
`1.0/15.0` and clears both caches; it then preserves only that side's
eligible items. The other cache stays empty. Both routes set reconstruction
condition `battle_continuation_phase` to `2` and reenter outer state `13`.
Reconstruction mode `battle_continuation_route` chooses full or timer-excluding
restore.
The restored resources are what capture left in snapshot storage, not proof
that capture preserved earlier HP/chakra. Neither operation includes Link Gauge.
These conditional branches do not establish an ordinary Practice menu route
([Pause and replay](../session/pause_and_replay.md#battle-teardown-and-reconstruction)).

Linked Mode outlives either UI: outer setup recreates the support manager with
Auto; outer cleanup destroys it. State-`14` battle entry and state-`16`
active-object cleanup retain its side selectors. A choice survives those
graph paths until the outer controller is rebuilt
([Support mechanics](../characters/support_mechanics.md#scheduled-lifecycle-and-teardown)).
Direct ELF/BTL snapshot callers were bounded; other overlays and indirect
calls were not inventoried.

### Continuous fighter policy

During eligible mode-`3` fighter maintenance:

1. Health/chakra consumption requires `major_state` outside `8,5,6`,
   no `exchange_roles`, and the engine root update counter's low five bits
   zero.
2. Health Almost adds `0.1 - hp`, Half `0.5 - hp`, Normal `1.0`;
   the HP helper keeps its own fighter-state gates and clamps at `1.0`.
3. Under the same eligibility gate, Unlimited Chakra refills through the
   gated/clamped adder with `15.0` only when `staged_chakra == 0`.
4. Independently of that narrower action-state gate, Unlimited Link Gauge
   adds `1.0` to `support_gauge` and clamps to `[0,1]`.

The root pointer is `engine_pad_context`; its `EnginePadContext.update_counter`
field supplies the periodic gate. Chakra reservation/adder ownership belongs to
[Chakra and guard](../combat/chakra_and_guard.md#initialization-maximum-and-resetrefill).

Confirm writes settings, not current HP/chakra/gauge.
Normal Health actively refills; Normal Chakra does not refill, and Normal
Link Gauge does not increment. Unlimited Chakra retains its reservation and
adder gates. No established menu Confirm/local Defaults path directly resets
items, Link Gauge, or the item cache.

## Rendering and control split

### Resource lifetime

`practice_settings_initialize` zeroes ownership pointers;
`practice_settings_construct` loads the archive, constructs four
`0x40`-byte backing objects, prompt/panels/sprites/help, then snapshots.
`practice_settings_destroy` runs on owner teardown.

Ordinary main-parent reopening calls only `practice_settings_snapshot`.
It retains constructed resources and resets presentation/input/page/help.
Ordinary open/close therefore reuses resources; selecting another standalone
module replaces them through owner destruction/construction.

Main parent variant `1` draws the full-frame backdrop; standalone variant
`0` does not. Backdrop alpha follows the child's fade and is independent of
backing animation, rows, and input owner.

Parent update and draw are separate, and parent state `3` draws nothing.
Practice drawing skips rows below full alpha; at full alpha it advances
`reveal_delay` to `3`, returning without rows on those three calls.
Thereafter it submits all 17 rows, including offscreen ones, with the section
gap before row `9`, the enabled/grey predicate, and selection/arrows helper.

Drawing therefore mutates presentation delay but neither applies settings nor
owns input/phase. Reveal delay is draw-call-counted. The bounded direct caller
families are the generic parent and standalone wrapper; each has separate
update/draw calls.

### Render-packet allocation failure

Practice label/value submission reaches `font_draw_text`.
For each glyph, `font_draw_glyph` requests transient GS packets through
`render_packet_allocate` and `render_pool_allocate`.
No suitable free block returns null and skips that glyph.
The pool occupies `0x00951480..0x00B51480`, exactly 2 MiB;
allocations retain their owning list in `RenderPoolAllocation.owner_list`.

This establishes selective text loss on pool exhaustion, not which state
exhausts it first. **Runtime observation:** the same text loss occurs in
unmodified retail NA2. **Inference:** because failure occurs in EE-side packet
construction before the renderer sees the GS stream, physical PS2 should
reproduce it on exhaustion. Hardware reproduction is unconfirmed; there is
no input recording or breakpoint trace for the reported loss.

### Native Practice Settings presentation geometry

Row windows, backing animation, title model, atlas/color data, resource
construction, cursor, and arrows belong to
[Battle and Practice settings presentation](../../localization/ui/battle/settings_presentation.md#practice-content-and-contexts)
and [its cursor/arrow section](../../localization/ui/battle/settings_presentation.md#cursor-and-arrows).

### Negative findings

`settings_prompt_draw` is the VS/Practice prompt renderer, not settings
control. `practice_draw_row_selection` owns selection/arrows drawing, not
input. Practice drawing does not reset/apply manager options.

## Address index

These live entries identify the ownership and consumption boundaries;
per-routine code detail is in annotations.

### BTL code

| Boundary | Name | Live entry |
| --- | --- | ---: |
| Generic parent construction | `settings_parent_construct` | `0x006BFFF0` |
| Parent update/draw | `settings_parent_update` / `settings_parent_draw` | `0x006C0F60` / `0x006C1120` |
| Standalone module factory | `start_menu_create_module` | `0x0087BB10` |
| Child snapshot/apply | `practice_settings_snapshot` / `practice_settings_apply` | `0x00880F30` / `0x008811A0` |
| Child input/update/draw | `practice_settings_input` / `practice_settings_update` / `practice_settings_draw` | `0x00881660` / `0x00881AB0` / `0x00882250` |
| Dummy bridge | `practice_toggle_com` | `0x008813F0` |
| Linked Mode access | `support_linked_mode_get` / `support_linked_mode_set` | `0x00882630` / `0x00882670` |

### BTL data

| Data | Live address |
| --- | ---: |
| `practice_labels` | `0x008BE6C0` |
| `practice_help` / `practice_status_help` | `0x008BEF70` / `0x008BF350` |
| `practice_values` / `practice_value_counts` | `0x008BF380` / `0x008D18C0` |
| `ai_behavior_profiles` | `0x008C3230` |
| `ai_states` | `0x008D6590`, side stride `0x1E0` |
| `ai_side_strength_parameters` | `0x008D66F0`, side stride `0x1E0` |
| `battle_item_cache` | `0x008D6A60` |

AI work/profile copies and item caches are live BSS; their initial runtime
content is not established by the imported file bytes.
