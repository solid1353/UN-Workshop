# Resident front-end and mode flow

## Research coverage

Established statically: opening/title and manager graphs, Mode Select input,
results and plate wheel, lifetimes, synchronous BTL/ETC selection, and resident returns.
Open: auxiliary-byte and BTL-sentinel meaning, allocation/malformed-state and
loader-failure consequences, and overlay-local behavior beyond the handoff.

Routines, structures, initialized data, and resident BSS globals are named by
`@annotations/NA2`.
Addresses are live.

## Evidence and conventions

This document owns the resident `SLPS_258.37` flow from opening/title through
New Game/Continue, Mode Select, Free Battle, Practice, Collection, Options,
and their returns. It stops at the overlay interface. The excluded mode and
its overlay, Save/Load child UI, layout, media, localization, and timing
remain outside this flow map.

Names describe established behavior, rather than recovered source identifiers.
`ccGbtlProcess` is an original RTTI string (`btl_process_type_name`).
The evidence is static against the retail ELF identity in
[Standard game file identities](files/file_identities.md); allocation failure,
corrupted state, and overlay-local behavior remain unconfirmed. Semantic
labels inferred from stock menu order are distinguished from numeric contracts.

Related owners: [Startup](startup.md), [Overlay ABI](../runtime/overlay_abi.md),
[Runtime lifetimes](../runtime/ee_memory_map/runtime_lifetimes.md),
[Practice mode](../gameplay/modes/practice_mode.md),
[Stages](../gameplay/stages/stages.md),
[Match outcomes](../gameplay/session/match_outcomes.md),
[Support mechanics](../gameplay/characters/support_mechanics.md),
[Pause and replay](../gameplay/session/pause_and_replay.md), and
[Save data](save_data.md).

## Controller hierarchy

The resident flow has three nested levels:

```text
resident_flow_dispatch
  outer state 2: opening_update
  outer state 3: title_update_dispatch
  outer state 4: manager_allocate
    manager phase 2/3: New Game / Continue preparation
    manager phase 4: callback selected by BattleManager.mode
      mode 1: resident Mode Select
      modes 2/3: BTL handoff
      mode 6: ETC Collection
      mode 7: resident Options
```

The outer loop is a state switch. `BattleManager.mode` is the high-level
callback selector, separate from the manager phase and overlay selector.

### Resident globals used by this flow

The pointer slots survive overlay replacement; their pointed-to objects have
different lifetimes. These globals belong to the resident ELF's BSS.

| Symbol | Established role |
| --- | --- |
| `engine_pad_context` | Pointer to the `0x530`-byte `EnginePadContext`, with two `PadRecord` banks `0x78` bytes apart |
| `front_end_outer_state` | Pointer to eight-byte `FrontEndOuterState` |
| `title_controller` | Pointer to `0x48`-byte `TitleController` |
| `live_profile` | Outer-owned `0x2400`-byte live profile borrowed by `BattleManager.profile` |
| `battle_manager` | Pointer to persistent `0xDF8`-byte `BattleManager` |
| `vibration_mask_cache` | Vibration-mask cache byte, copied into a new profile and back at manager teardown |
| `front_end_transient` | Shared `0x14`-byte `FrontEndTransient` pointer |
| `mode_select_controller` | `0xD4`-byte `ModeSelectInput` pointer |
| `collection_owner` | Mode-6 ETC `CollectionOwner` pointer |
| `mode5_controller` | Pointer slot belonging to an excluded callback |
| `options_root_view` | Mode-7 `0x5C`-byte resident Options pointer |
| `btl_process` | Shared `0x44`-byte `BtlProcess` pointer |
| `front_end_gate` | Shared `0x28`-byte `SaveDialogController` used by Continue and Mode Select back |
| `battle_route_code` | Resident battle-route word; value 7 converges on the front-end return path |
| `mode_select_back_auxiliary` | Auxiliary byte cleared by Mode Select back; wider meaning unknown |

The mapped signed halfword `mode_select_remembered_slot`
(`0x006045E0`) retains the physical Mode Select slot independently of the
manager.

### Allocation lifetimes

`resident_flow_dispatch` (`0x001E0EE0`) allocates the outer state and live
profile once before its non-returning loop. `profile_construct`
(`0x001E34F0`) initializes the profile before its publication.

`title_update_dispatch` (`0x001DE840`) owns the title controller only while
the title callback remains active; a nonzero result destroys it.
The manager persists across Mode Select, BTL, ETC, and Options callbacks.
Returning to title destroys the manager and clears its slot, while the
outer-owned profile remains.

The transient and Mode Select/BTL/ETC/Options objects have callback lifetimes.
Each terminal callback clears its own slots. `manager_destroy`
(`0x001F42B0`) does not sweep the transient, mode objects, or shared gate.

Allocator success is assumed at most construction boundaries:

- Failed top-level title allocation returns 0 without update/presentation and
  retries later.
- Failed shared BTL allocation leaves its slot null; both BTL callbacks skip
  dispatch and retry.
- The outer state, profile, manager, transient, Mode Select controller, and
  shared back gate are dereferenced immediately without a recovery branch.
- Manager-owned render-context and transition-owner allocations (`0x40` and
  `0x98` bytes) are dereferenced without recovery. Its optional `0x4C`-byte
  battle-condition object is checked for null at BTL entry.
- Collection and Options can pass a null object to their poll/update entry.
  Whether those callees tolerate null is not established by this boundary.

## Outer opening/title/front-end loop

`FrontEndOuterState.state` is 2 at the native opening entry. Its
`title_result` retains 1 or 2 for manager initialization. Startup prerequisites
belong to [Startup](startup.md).

| Outer state | Controller result | Transition |
| ---: | --- | --- |
| 2 | `opening_update` (`0x001DE6F0`) returns 1 | state 3 |
| 3 | `title_update_dispatch` returns -1 | state 2 |
| 3 | title returns 1 or 2 | retain title result; state 4 |
| 4 | `manager_allocate` (`0x001E9980`) returns 1 | state 3 |
| 4 | manager returns 2 | state 2; no producer of 2 in the inspected manager |

### Title controller result contract

The wrapper constructs through `title_construct` (`0x001DE900`), updates
through `title_update` (`0x001DF690`), presents through `title_present`
(`0x001DFAB0`) while the update returns 0, and destroys through
`title_destroy` (`0x001DE970`) before returning a nonzero result.

`TitleController` names its state, idle countdown, result, selection,
transition handle, presentation phase, and completion latch. The complete
controller graph is:

| State | Action and transition |
| ---: | --- |
| 0 | Construct presentation resources and items, initialize selection, start presentation phase 1, enter state 1 |
| 1 | Circle/Start (`0x0820`) selects state 2; the later phase-4 test selects state 3 and wins if both conditions hold |
| 2 | Reset the presentation surface, select phase 4, fall through states 3 and 4 in the same update |
| 3 | Enter state 4 and immediately run its decoder |
| 4 | Accepted item starts phase 5/state 6; otherwise decrement idle countdown, create idle-return transition at zero, enter state 5 |
| 5 | Completed idle-return transition resets transition slot 0, stores -1, enters state 8; while pending, Circle/Cross/Start (`0x0860`) cancels, clears result, resets countdown to 150, returns to state 4 |
| 6 | Wait for nonzero presentation-completion latch, create accepted-result transition, enter state 7 |
| 7 | Accepted-result transition completion enters state 9 |
| 8 | Advance to state 9 on the next update |
| 9 | Reset the presentation surface and return the stored result |

Presentation setup requests phase 1; common-tail phase servicing advances
1 → 2 → 4 on resource completion. Accepted input selects phase 5 instead.
The item service OR-latches two presentation completion reports, providing the
exact state-6 gate.

`title_initialize` (`0x001DEA30`) sets the idle counter to 570. State 4
decrements it once per update without an accepted result. Cancelling the
in-progress idle return resets it to 150. Conditional on one update per
30 FPS frame, these are 19 and 5 seconds. State 6 writes 570 again, but states
7–9 neither read nor decrement it; that final write has no established timing
role.

`title_navigation_input` (`0x001DF140`) uses only controller port 0's pressed
mask. Navigation clamps rather than wraps: Up at item 0 stays 0 and Down at
item 1 stays 1. Priority is Up, Down, then Circle/Start confirmation.
`title_construct_items` (`0x001DEED0`) initially selects item 1.
Confirmation stores selection + 1: item 0 is result 1 (New Game), item 1
result 2 (Continue), as corroborated by existing title-flow evidence.

Cross does not directly back out of the title decoder. Result -1 comes only
from completed state-5 idle return, through states 8 and 9. It is an internal
opening restart, rather than a third title item.

## Persistent front-end/profile manager

On its first entry, `manager_allocate` allocates `0xDF8` bytes, constructs
the manager, publishes its pointer, then calls `manager_setup`
(`0x001F45B0`). The front-end and profile manager are the same persistent
allocation.

### Manager fields used by mode flow

The fixed layout is in `BattleManager`. Its behavior-relevant fields are
`profile`, `phase`, `mode`, `cached_overlay_selector`, `menu_state`,
`active_side`, `current.sides[].character_id`, and its three owned
front-end subsystem pointers.

`manager_initialize` (`0x001F4360`) starts phase 1, mode 0, overlay
selector -1, menu state 0, and confirming port 0. `active_side` is a
zero-based controller-port index in this flow, despite its existing name.
An accepted Mode Select confirmation replaces it; callback returns and menu
reconstruction do not reset it. It persists until another accepted selection
or manager destruction.

Resident consumers choose one of the two input banks with this port value.
The Practice character-selection path maps port 0 to control mode 1 and port 1
to control mode 2. Existing independent evidence identifies
`current.sides[0/1].character_id` as the current Player 1/Player 2 IDs.

The manager's `menu_state` is 0 normally and 1 while its resident BTL
start-menu owner is active. The owner restores 0 before interpreting its
result; result 2 latches battle-route code 7. Scheduling effects belong to
[Pause and replay](../gameplay/session/pause_and_replay.md#resident-ownership-and-top-level-result-routing).

### Manager-construction binding side effect

Every manager construction resets all three resident `0x10`-byte binding
banks through `bindings_update` (`0x001F3DC0`). The source
`resident_default_bindings` (`0x005C06A0`) contains:

| Binding | Native mask | Native button |
| ---: | ---: | --- |
| 0 | `0x0010` | Triangle |
| 1 | `0x0020` | Circle |
| 2 | `0x0040` | Cross |
| 3 | `0x0080` | Square |
| 4 | `0x0004` | L1 |
| 5 | `0x0008` | R1 |
| 6 | `0x0001` | L2 |
| 7 | `0x0002` | R2 |

This is the only static 16-byte default copy. The destinations
`resident_bindings_bank0`, `resident_bindings_port0`, and
`resident_bindings_port1` are zero-filled resident storage repopulated on each
construction. The manager has not yet been
published, so the binding updater's synchronization tail cannot write the live
profile at this stage.

After publication, `manager_setup` copies the latter two banks into the
borrowed profile's two binding arrays, before consuming the title result.
Synchronization direction and serialized bytes belong to [Save data](save_data.md);
battle consumption belongs to
[Action commands](../gameplay/combat/action_commands.md).

### Manager phases

| Phase | Behavior |
| ---: | --- |
| 1 | Consume the retained outer title result |
| 2 | `new_game_prepare` (`0x001E9C00`) |
| 3 | `startup_load_profile` (`0x001E9EB0`) |
| 4 | Dispatch `mode` |
| 5 | Destroy manager, clear its pointer, return 1 to the outer loop |

Title result 1 selects phase 2; result 2 selects phase 3. An unrecognized
result falls through to phase 4/mode 1, but retail outer routing enters the
manager only for title results 1 and 2. Likewise, initialized mode 0 is
replaced with 1 on every retail path reaching phase 4.

Successful New Game and Continue preparation selects phase 4/mode 1.
New Game constructs only results 0 and 1, making the caller's -1 check dead.
Continue can return -1 on cancellation, which the manager converts to outer
result 1. The Save/Load workflow inside Continue is not analyzed here.

Before any nonzero manager return its allocation is gone and its pointer
clear. Phase 5 uses `manager_destroy`; Continue cancellation destroys it
inside its own preparation routine, so the final null guard prevents a second
destruction.

`manager_teardown` (`0x001F4680`) first copies the live profile vibration
byte back to the in-process cache, destroys optional battle-condition state,
and resets the selector to -1. The profile remains outer-owned.
[Save data](save_data.md#fresh-profile-initialization) owns cache semantics.

Outgoing callback cleanup precedes the next manager phase/mode observation:
Mode Select back frees its controller, gate, and transient before phase 5;
Continue cancellation cleans its gate/transient in the callee destroying the
manager; BTL/ETC/Options finish their objects before Mode Select re-entry.
Manager phase 5 and destruction do not perform that callback cleanup.

## High-level mode callback dispatcher

Phase 4 switches directly on `BattleManager.mode`:

| Mode | Meaning | Callback | Backing and return |
| ---: | --- | --- | --- |
| 1 | Mode Select | `battle_mode_selector_update` (`0x001EA240`) | Resident |
| 2 | Free Battle | `free_battle_callback` (`0x001EA8C0`) | BTL entry type 1; terminal helper writes mode 1 |
| 3 | Practice | `practice_callback` (`0x001EA940`) | BTL entry type 2; terminal helper writes mode 1 |
| 6 | Collection | `manager_snapshot_state6` (`0x001EB120`) | ETC; cleanup writes mode 1 |
| 7 | Options | `manager_options_lifecycle` (`0x001EB440`) | Resident; cleanup writes mode 1 |

English meanings are corroborated by stock menu order and called subsystems.
Analyzed mode returns write mode 1 while leaving phase 4 active. The next
manager invocation re-enters Mode Select without recreating the manager.

### Numeric-domain crosswalk

These small integers belong to different domains:

| Meaning | Physical slot | Result / manager mode | Overlay selector | Entry value |
| --- | ---: | ---: | ---: | --- |
| Free Battle | 1 | 2 | 0 | BTL type 1 |
| Practice | 2 | 3 | 0 | BTL type 2 |
| Collection | 5 | 6 | 2 | `0x80`-byte ETC object |
| Options | 6 | 7 | 0 retained | `0x5C`-byte resident object |

Title results 1/2 mean New Game/Continue. Overlay selectors 0/2 index the
filename table; they are neither manager modes nor overlay header kinds.

## Mode Select result table

`mode_select_results` (`0x005D51D0`) maps physical slots to signed mode
results:

| Physical slot | Result | Meaning and effect |
| ---: | ---: | --- |
| 1 | 2 | Free Battle, BTL type 1 |
| 2 | 3 | Practice, BTL type 2 |
| 3 | -1 | Disabled stock slot, filtered out |
| 5 | 6 | Collection, ETC |
| 6 | 7 | Options, resident |

`mode_select_build_slots` (`0x00384690`) scans all seven entries and keeps
the physical indices whose signed results are nonnegative. The stock active
count is 6. `mode_select_physical_slot_get` (`0x00384700`) translates
the compact selected index back to a physical slot.
`mode_select_result_get` (`0x003845D0`) maps it to a mode only in terminal
controller state 6; otherwise it returns -1. Visuals and remembered selection
therefore use physical slots, while table values are mode IDs.

Capacity is seven and the active count is computed solely by the sign filter.
There is no empty-list guard. With all entries negative, count is zero, but
restore still publishes compact entry 0. Construction never initialized that
array entry, so its indeterminate value reaches `visual_slot` and can later
index the result table during confirmation.

## Mode Select controller

Callback 1 initializes fields through `mode_select_initialize_fields`
(`0x003839E0`), then constructs resources/slots/selection through
`mode_select_construct_resources` (`0x00383DB0`), before publishing the
controller pointer. Its first update and draw therefore occur only after
both construction steps and publication.

`mode_select_cleanup` (`0x00383AA0`) is used on acceptance, back, and final
callback cleanup. The controller itself ends before terminal callback routing.

The footer uses `legend_sprite` and `button_sprite`, bound to
`prompt_context`. Resource construction uses render kinds `0x40` and
`0x60`, legend arguments `10, 1`, and button-icon arguments `10, 0`.
`mode_select_present` (`0x00385C00`) submits Cross and Triangle through
`button_icon_submit` (`0x0037C980`), then the START legend, and finalizes
both sprites. Compositor entry 3 selects Square through the same icon sprite.

Callback phase 4 draws only while the update returns zero. The draw routine
skips state 6 but continues drawing state 1 while its exit transition is pending.
After the callback, common resident presentation runs; the later frame path
submits the shared transition manager's primitives. Mode Select and Character
Select start transitions on that same manager.

### Relevant object fields

`ModeSelectInput` names the state, compact slots/count/index, floating
carousel displacement, sampled input masks, transition/result/countdown,
direct/scripted selector and target, Save/Load child, render contexts, footer
sprites, last visual slot, selection visual, modal kind, and back modal.

On every construction, `mode_select_reset_manager_characters`
(`0x00384570`) resets the manager's current Player 1/Player 2 IDs to 1/2
when the manager exists. This happens again on each analyzed return from BTL,
ETC, or Options, before another mode is accepted.

### Plate wheel

`mode_select_draw_plates` places plates on a ten-position wheel and draws
seven of them, offsets -3 to 3 around the selected entry, each wrapped by the
active count. Navigation changes the selected entry at once and adds one
position of `carousel_displacement` the other way, so the plates keep their
places as the wheel turns. The selected look (unfogged, larger,
tilted) goes to every plate whose physical slot is the selected one, not only
the center. With the stock six entries no other drawn plate has that slot; with
three, the offset -3 and 3 plates do, and with two, the offset -2 and 2
plates do, so they switch looks on every move.

`mode_select_update` plays the selected entry's plate animation once
`carousel_displacement` is within 0.01 of zero and holds every other plate
player at frame 0. Each entry has one plate player, so every drawn copy of the
selected entry shows that animation.

### Remembered physical slot

`mode_select_remembered_slot` is initially `0xFFFF`, read as signed -1.
Accepted selection persists the physical slot before starting exit.
Construction restores the matching compact entry; an absent match retains
compact index 0, which is then published to the visual.

Back resets the halfword to -1 before its modal decision. Manager teardown
does not reset it. The ordinary return mechanism is therefore: acceptance
remembers a physical slot, a completed mode writes manager mode 1, and the new
Mode Select controller restores that physical slot. No mode-specific remembered
return code is required.

### Input actions

`mode_select_update` (`0x003854F0`) samples the two embedded pad banks
before state dispatch. `port_pressed[0/1]` retain each port's pressed word;
`pressed` ORs them, `held` ORs held/current words, and `repeat` ORs the
initial/change and delayed-repeat stream. The repeat snapshot is not consumed
again by this controller's direct action decoder.

Navigation and back combine ports, but confirmation retains its origin.
Accepted action 3 writes port 0 to manager `active_side`; action 4 writes
port 1. Title navigation uses only port 0 instead.
Native names follow [Controller input](../runtime/controller_input.md).

| Action | Native input | Effect |
| ---: | --- | --- |
| 1 | either port held Up, `0x1000` | Previous compact entry |
| 2 | either port held Down, `0x4000` | Next compact entry |
| 3 | port 0 pressed Circle, `0x20` | Confirm as port 0 |
| 4 | port 1 pressed Circle, `0x20` | Confirm as port 1 |
| 5 | combined pressed Cross, `0x40` | Back/exit |
| 6 | combined pressed Start, `0x0800` | Save/Load branch, excluded |

`mode_select_decode_direct_input` (`0x00384CD0`) prioritizes port-0 Circle,
port-1 Circle, Cross, Start, Down, then Up. Port 0 wins simultaneous confirms;
confirm outranks back; Down wins simultaneous Up/Down.

Back clears the remembered slot and `mode_select_back_auxiliary`
before state 3 decides whether to exit or resume. Resume restores neither.
No in-scope resident consumer establishes the auxiliary byte's wider meaning.

When `input_source` is nonzero,
`mode_select_decode_scripted_input` (`0x00384D70`) treats target 7 as
back, target 8 as the excluded Save/Load action, a matching physical target
as action 3, and any other target as next-entry navigation. Scripted acceptance
therefore records port 0. A target filtered out of the compact list cannot
reach equality/confirmation; no missing-target guard exists.

Retail construction initializes `input_source` and `scripted_target` to
zero. No direct writer in the analyzed controller/callback path activates the
scripted selector, so normal retail flow uses the direct decoder. The scripted
interface requires an external or otherwise unresolved mutation.

### Resident pre-dispatch hook seam

`mode_select_pre_dispatch` (`0x00384DE0`) is the eight-byte retail no-op
called immediately before the direct/scripted choice in
`mode_select_dispatch_input` (`0x003849C0`). The sampled masks and scripted
fields already exist at this boundary; the decoder has not read them yet.
The controller pointer is supplied and the return is ignored. Exact call and
instruction details are retained in the routine annotations.

### Confirmation and terminal result

`menu_select_saved_gate` (`0x00384760`) resolves the compact selection to
its physical slot. A negative mode result enters modal kind 4, unreachable
through the stock sign-filtered list. Port 0 accepts any enabled slot. Port 1
accepts slots 1 and 2 immediately; the other in-scope slots 4, 5, and 6 enter a
modal path. The excluded slot is not characterized here.

Normal acceptance writes the confirming port to manager `active_side`,
persists the physical slot, writes controller result 1/state 1, and starts
exit. The lifecycle is:

| State | Behavior |
| ---: | --- |
| 0 | Wait for entry transition, then state 2 |
| 1 | Wait for exit transition, then state 6 with result countdown 2 |
| 2 | Active input dispatch |
| 3 | Update back modal; completed first-choice decision resumes state 2 or commits result -1/state 1 |
| 4 | Excluded Save/Load child path; returns to state 2 |
| 5 | Confirmation/error modal; returns to state 2 on dismissal |
| 6 | Decrement countdown, then return stored result |

The update returns 0 while active, 1 after acceptance, and -1 after a committed
back exit. The callback reads the mapped mode result only after update result 1.

The back decision uses `FrontEndModal.choices`, a nested
`ModalChoiceState`. It exits only when `result != 2` and
`selection == 0`. A back press alone does not establish terminal result -1.

The nested list merges pressed/repeat masks from both ports.
Up/Down navigate within its count; Circle sets result 1/event `0x02`;
allowed Cross sets result 2/event `0x04`; selection change sets event
`0x01`. Navigation, confirmation, and cancellation events play native sounds
`0x35`, `0x34`, and `0x33`.

After modal completion, Circle on selection 0 commits return to title;
Circle on selection 1 resumes Mode Select; Cross resumes regardless of
selection. This two-choice modal is inside state 3, rather than a top-level
callback.

## Mode Select callback and result routing

The shared `FrontEndTransient` uses `phase` and `mode_result` for callback 1.
Construction zeros its first four words and sets its final sentinel to -1.
Collection and Options reuse `countdown` for terminal cleanup.

| Transient phase | Action |
| ---: | --- |
| 0 | Wait for archive worker inactive, reset resident state, enter 1 |
| 1 | Wait for resident readiness nonzero, run transition helpers, enter 2 |
| 2 | Wait for archive worker inactive again, reset/stage, enter 3 |
| 3 | Select overlay 0 synchronously, write manager mode 1, stage Mode Select resources, enter 4 |
| 4 | Construct/update menu; save mapped acceptance or -1 back result, enter 5 |
| 5 | Accepted result advances to 6; -1 first passes the resident exit gate |
| 6 | Cleanup and route saved result |

The routing switch copies results 2, 3, 5, 6, and 7 verbatim to manager mode.
Result -1 writes manager phase 5, causing outer return to title. Results 5/6
also stage their resident resource groups; their resource composition is
outside this flow map.

The controller is destroyed and its slot cleared as soon as its update returns
1 or -1. Only the transient carries the result through phases 5/6.
Back temporarily owns the separate shared gate, destroyed before phase 6.

### Shared Continue/back gate

Continue preparation and Mode Select phase 5 lazily construct the same
`0x28`-byte parent through `front_end_gate_construct` (`0x001E3DB0`),
clear its `+0x20` word, and use the effective result of
`save_dialog_update` (`0x001E3F00`). The word's wider purpose is unknown;
the existing `SaveDialogController.ui` names its owned `0x44`-byte child.

| Caller | Gate mode | Interpretation |
| --- | ---: | --- |
| Continue | 1 | 1 proceeds toward Mode Select; 2 becomes -1/return to title |
| Mode Select back | 0 | 0 waits; any nonzero advances phase 5 → 6 |

The Mode Select back gate opens on the `Save data?` question, so a committed
back always asks whether to save before returning to title.

Both destroy the parent and clear its global slot. Child Save/Load UI remains
excluded. A callback change is not observed by a later manager invocation
until the shared transient has been freed; callbacks reuse that allocation
with different phase interpretations.

### End-to-end result chains

- Accept: remember physical slot → controller result 1 → mapped mode →
  transient result → manager mode → matching callback, with manager retained.
- Mode completion: cleanup → manager mode 1 → reconstruct Mode Select →
  restore remembered physical slot.
- Committed back: clear remembered slot → state-3 decision/result -1 →
  transient terminal route → manager phase 5/destruction/result 1 →
  outer state 3/title.

## Overlay selection boundary

BTL and ETC replace the same region starting at `0x006B3F00`.
Their established effective ranges are `[0x006B3F00, 0x008DD080)` and
`[0x006B3F00, 0x006E4E00)`, respectively. These ranges classify handoff
targets here; [Runtime lifetimes](../runtime/ee_memory_map/runtime_lifetimes.md)
owns their lifetime evidence.

### Filename table

`overlay_filename_table` (`0x004049E0`) is a contiguous three-pointer table:

| Selector | Filename |
| ---: | --- |
| 0 | `btl_overlay_filename` (`0x00603048`), `BTL.bin` |
| 2 | `etc_overlay_filename` (`0x00603058`), `ETC.bin` |

The excluded entry lies between them; its selector behavior remains outside
scope.

### Selection-and-cache interface

`overlay_select` (`0x001F3D10`) uses the manager's
`cached_overlay_selector`:

- Without a manager, synchronously load the chosen filename into loader slot 1;
  there is no cache, so a later manager-less call loads again.
- With a manager and a different selector, perform that load, then cache the
  requested index.
- With a matching cached selector, issue no request.
- After a cache hit or loader return, return 1 without a separate pending or
  failure status.

There is no index bounds check before the pointer-table read. Loader slot 1
selects the shared overlay destination. The synchronous boundary comes from
[Overlay ABI](../runtime/overlay_abi.md), rather than from unconditional return
1 alone.

The cache records the completed request, not independently verified image
identity or success. Neither selector nor bootstrap setup reads the overlay
header or checks a loader result before updating it. Retail overlay changes
pass through these helpers.

Manager construction starts selector -1; immediate setup loads BTL and stores
0 before consuming the title result. Mode Select phase 3 selects 0 again,
restoring BTL after ETC before constructing the menu.

### Overlay state across return routing

- Manager entry synchronously selects BTL before New Game/Continue.
- BTL return keeps BTL; Mode Select's selector-0 request is normally a cache hit.
- Collection cleans up while ETC is resident, then writes mode 1 without
  replacing it. Mode Select phases 0–2 remain resident-only; phase 3 restores
  BTL, and phase 4 constructs its controller.
- Options never selects an overlay. Normal entry inherited BTL from Mode
  Select, so its return also produces a selector-0 cache hit.
- Returning to title destroys the manager/cache but leaves the overlay image.
  A new manager starts -1 and reloads BTL even when old BTL bytes remain.

## BTL handoff and return

Free Battle and Practice share `BtlProcess` through `btl_process`.
`battle_process_get_or_create` (`0x001EC300`) uses entry type 1/2 only
when constructing an absent allocation. A nonnull existing process is returned
without reconstructing or rewriting its entry type. Retail routing destroys it
before a later BTL selection.

The process's `state`, `entry_type`, entry-type marker,
`character_select`, `stage_select`, `result_metrics`, and `methods` are
named in its annotation type. Raw word `+0x10` is initialized to -1; no
later direct read was found in this resident path and its wider meaning remains
unknown. Types 1/2 set `entry_type_enabled` to 1.

`btl_process_table` (`0x005D9F98`) contains a pointer to the original
type-name pointer, a null word, and `practice_driver_callback`
(`0x001ECBF0`). Its hook slot is `btl_process_callback_slot`
(`0x005D9FA0`).

The callback receives the process pointer and returns zero; both wrappers
discard the return. Free Battle invokes it only after dispatcher results 1/2,
while Practice also invokes it after result 0. Both destroy the process on 3.
Their differing hook-call conditions have no observable effect with the stock
return-zero target.

### Fixed-address BTL handoff surface

`battle_driver_setup` (`0x001EC7A0`) selects BTL synchronously and stores
the entry type, then performs this order:

1. If `result_metrics` is null, allocate `0x188` bytes and initialize it
   through `btl_record_owner_initialize` (`0x007190D0`).
2. If nonnull, clear it through `btl_record_owner_reset` (`0x00719500`).
3. Unconditionally recreate two-side support through
   `support_owner_allocate` (`0x00885210`).
4. If manager and `battle_conditions` exist, reset that resident object's
   payload through `battle_conditions_reset` (`0x001FD030`).
5. Write process state 1.

The manager constructed the optional `0x4C`-byte condition object;
its payload begins at `+0x08`. Detailed condition/outcome semantics remain
in [Match outcomes](../gameplay/session/match_outcomes.md); support belongs to
[Support mechanics](../gameplay/characters/support_mechanics.md).

`battle_process_release` (`0x001EC370`) reaches
`battle_driver_cleanup` (`0x001EC890`) through the deleting destructor.
Cleanup preserves the matching lifetime order:

- Clean/free/clear residual `0x4B4` Character Select through
  `battle_driver_child34_release` (`0x003B9CE0`).
- Clean/free/clear residual `0x16C` stage-selection child through
  `directional_players_release` (`0x00713B20`).
- Clean/free/clear `0x188` result child through
  `btl_record_owner_release` (`0x00719140`).
- After all three slots are clear, destroy support through
  `support_owner_release` (`0x00885290`).

All six overlay targets belong to the established BTL lifetime. Their
overlay-local implementations are outside this note.

`manager_dispatch_state` (`0x001EC960`) services resident
`battle_start_menu_update` (`0x001EBD90`) before process-state dispatch.

| Dispatcher return | Condition |
| ---: | --- |
| 0 | Defined nonterminal handler leaves state unchanged |
| 1 | Defined handler changes state |
| 2 | State matches no defined case |
| 3 | Terminal state `0x19` completes its return helper |

`battle_return_to_mode_select` (`0x001EEB10`) waits for the resident
transition/resource boundary to become idle, writes manager mode 1, restages
Mode Select resources, and returns 1. The dispatcher then returns 3, causing
wrapper destruction before the next manager invocation.

Two in-scope paths directly reach terminal state `0x19`: state 7's
Character Select cancellation (-1) destroys that child and returns to menu;
state `0x12` sees route code 7 and sends both entry types to terminal return.
The pre-dispatch start-menu owner can write route 7 after its owned object
returns 2. That route is a resident global, outside the process allocation.

Although construction initially zeros process state, setup changes it to 1
before the first normal update. Undefined-state return 2 is therefore not
the initial result of a newly constructed type-1/type-2 process.

The deeper graph belongs to [Practice mode](../gameplay/modes/practice_mode.md)
and [Stages](../gameplay/stages/stages.md): states 1–6 prepare resources, 7/9
own selection handoffs, 10–15 load/construct battle, and later states tear
down or switch the graph. This note owns entry, return, and wrapper contracts.

## ETC handoffs and returns

### Mode 6 / Collection

`manager_snapshot_state6` selects ETC before entering its `0x80`-byte
`CollectionOwner`. Its four live handoffs are
`collection_fields_initialize` (`0x006C65C0`),
`collection_resources_initialize` (`0x006C68F0`),
`collection_poll` (`0x006C8940`), and
`collection_resources_release` (`0x006C6630`). Their internals are
outside this front-end map.

| Transient phase | Action |
| ---: | --- |
| 0 | Unconditionally enter phase 1 |
| 1 | Wait for resident idle boundary, reset/stage, select ETC, construct object, enter 3 |
| 2 | Explicitly inert; retail callback never writes it |
| 3 | Poll; exact 1 enters 4 with countdown 3; any other result stays 3 |
| 4 | Decrement countdown; release resources, free/clear transient and ETC owner, restage resident resources, write manager mode 1 |

All four handoffs are inside the established ETC range and cleanup runs before
any replacement of ETC.

### Mode 7 / Options (resident-only)

`manager_options_lifecycle` owns a `0x5C`-byte resident Options object.
Phase 0 waits for the resident idle boundary only when constructing it,
then initializes and updates it. Exact update result 1 enters phase 1 with
countdown 3; other results invoke presentation and remain active.
Phase 1 decrements the counter, destroys/free/clears the object and transient,
then writes manager mode 1.

There is no overlay selector call. Mode Select already ensured BTL, so normal
Options entry/return keeps that selection.

## Negative results, limits, and open semantics

Unsupported states do not share one recovery policy:

| Owner | Unsupported-value behavior |
| --- | --- |
| Outer state | Outside 2/3/4, run common services without transition |
| Title state | Outside 0–9, common servicing then return 0, keeping allocation |
| Manager phase | Outside 1–5, common services then return 0, keeping phase |
| Manager mode in phase 4 | Unhandled ID invokes no callback; phase 4 persists |
| Mode Select state | Outside 0–6, common visual servicing then return 0 without assigning recovery |
| Shared transient phase | Outside that callback's cases, inert |
| BTL state | Outside 1–`0x19`, including 0, return 2; wrappers keep process and invoke its hook |

The scripted decoder, negative-result confirmation branch, initialized
manager mode 0, unrecognized-title fallback, and outer manager-result-2
branch have narrower or absent reachability in the retail composition, as
described above. Collection and Options accept only exact completion result 1.

Original source field names, auxiliary-byte purpose, BTL sentinel meaning,
loader-failure consequences, and malformed-state/allocation-failure effects
remain unresolved.
