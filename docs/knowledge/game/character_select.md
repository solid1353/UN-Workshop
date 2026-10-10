# Native Character Select flow

## Research coverage

Established: both fighter rows, both sides' input and state flow, appearance,
fixed choices, restoration, support/Linked Mode selection, display and handoff.
All 31 roster pairs, 15 entry/update records, 62 recommendations and 96 portraits are covered.
The bounded NUN4 ID-9/NA2 ID-89 comparison covers Orochimaru's selector
atlas/name rows, filename publishers and auxiliary descriptor-array entry.
Open: recommendation byte 7, seven spare support slots, random categories 2..5
and the complete visual matrix of fighter, fixed-choice and cancellation states.
Routine, field and data names come from `@annotations/NA2`, `@annotations/NUN4`
and `@annotations/NUN5`.

This records retail NA2 (`SLPS-25837`) and the named retail comparisons.
The evidence is bounded static code and data, not proof of every caller or
visual state. Imported startup code
and former split BTL boundaries required byte corroboration; details are in
annotations. Resident BSS pointers `battle_manager` (`BattleManager *`) and
`support_owner` (`SupportOwner *`) are annotated in `SLPS_258.37`; Character
Select reads them to restore choices and writes through them at final handoff.

Related owners: [Character identity](../gameplay/characters/character_ids.md),
[Content availability](content_availability.md),
[Controller input](../runtime/controller_input.md),
[UI animation](../runtime/ui_animation.md),
[Character asset tables](character_assets.md),
[Battle support mechanics](../gameplay/characters/support_mechanics.md),
[Character Select UI layout](../localization/ui/character_select.md), and
[Native Stage Select](stage_select.md).

## Binary identity and address conventions

Resident and BTL identities follow
[Retail game file identities](files/file_identities.md#address-conventions).
All addresses below are live addresses. Character/support IDs and sentinels
are hexadecimal; states, counts, indices and controller numbers are decimal.

## Primary fighter roster and shared selector data

`character_select_populate_fighters` (`0x003BB0B0`) reverses each pair in
`character_select_fighter_pairs` (`0x005D64C0`): source word 1 becomes row 0
and word 0 becomes row 1.

```text
row 0: 39 5C 41 42 44 52 4E 50 3B 3D 47 40 3E 53 55 59
       5D 02 06 0D 0E 10 0C 28 2A 16 04 13 25 23 0B
row 1: 3A 46 43 45 51 56 4F 57 3C 4D 48 4C 3F 54 5B 5A
       01 07 03 05 0F 11 29 2E 2B 27 12 26 24 22 0A
```

Columns 0..30 are active. Each row has capacity 50; columns 31..49 contain ID 0
and state 3. These are 62 base-fighter cells. Linked forms resolve from their
base cells, rather than adding columns
([form mapping](../gameplay/characters/character_ids.md#hard-coded-linked-form-mapping)).

`CharacterSelectRoot.data` is one `CharacterSelectData` shared by exactly
two `CharacterSelectorInput` objects. Each selector owns its cursor, state,
appearance, input snapshots and support choice.

| Shared field | Contract |
| --- | --- |
| `fighter_column_count` | 31 |
| `fighter_ids` | Two rows, 50 word IDs each |
| `fighter_states` | Two rows, 50 state bytes each |
| `support_count` | 33 active entries |
| `support_ids` / `support_states` | 40 entries each |
| `fighter_portraits` | 96 display-ID slots |
| `support_portraits` | 34 support-ID slots |

`character_select_fighter_state` assigns state 3 to ID 0, state 0 to an
available fighter and state 1 otherwise. `character_selector_move_fighter`
visits states 0/1; `character_selector_confirm_fighter` accepts only state 0.
Locked cells are reachable but cannot be confirmed normally. The save-backed
availability gates belong to Content availability.

`character_select_poll` refreshes fighter and support data before dispatching
the root state on every invocation. `character_selector_construct` starts
with fighter 39, support 0 and color 0; if its fighter cell is unavailable it
scans candidate IDs through `character_selector_lookup_fighter_state` until
it finds state 0 or returns to 39.

## Appearance, fixed choices, and final handoff

Color, form and Linked Mode are independent selector fields. In
`character_selector_handle_fighter_input`, L1 (`0x04`) cycles
`color` over 0..2. `character_selector_draw` uses
`character_select_color_rectangles` (`0x005D6460`) for the indicator.
Changing fighter through `character_selector_set_fighter` preserves color.

Held R1 (`0x08`) sets `form` subject to the progression gate. Numeric
base/form rules belong to
[Character identity](../gameplay/characters/character_ids.md#selector-id-filters)
and the gate to
[Content availability](content_availability.md#progress-gates).

`linked_mode` is byte 0..1: Manual (`マニュアル`) and Auto (`オート`).
`character_select_linked_labels` (`0x00604810`) points to
`character_select_linked_manual` (`0x005B4228`) and
`character_select_linked_auto` (`0x00604808`).
Construction sets 1 through `character_selector_set_linked_mode`;
`character_select_restore` can restore the existing support-side choice.

The retained name `character_select_prepare_practice` (`0x003B9F60`)
covers the screen constructor with arguments
`(root, mode, fighter0, fighter1, support0, support1)`.

| Argument | Selection contract |
| --- | --- |
| Fighter argument zero | Editable |
| Valid nonzero fighter | Fixed and positioned at its cell |
| Invalid nonzero fighter | Replaced by first ID accepted by the numeric filters |
| Support 24 | Editable |
| Other native support | Fixed support flag 1 |
| Support 25 / 26 | Fixed support flag 2 / 3 |

`character_selector_resolve_support` returns 25/26 directly for those last
flags. Fixed support bypasses support and Linked Mode input; the sentinels
are not added to the scrollable roster.

When `character_select_restore_suppressed` (`0x00604818`) is zero,
restoration recovers editable fighters from `BattleManager.saved.sides`,
normalizes recognized forms to their base cells, and restores editable
supports. It restores colors from `current.sides` and Linked Mode from
`SupportOwner.sides`, then seeds each `support_memory_fighter` with the
resolved fighter. Fixed choices remain fixed.

When both selectors reach 12, `character_select_update` calls
`character_select_commit_choices` (`0x003BB3A0`) before the exit
transition. Four fixed constructor choices use that same handoff immediately.

| Output | Owner |
| --- | --- |
| Resolved fighter ID | `BattleManager.current.sides[side].character_id` |
| Resolved support ID | `BattleManager.current.sides[side].selected_support` |
| Color | `BattleManager.current.sides[side].color` |
| Linked Mode | `SupportOwner.sides[side].linked_mode` |
| Match-start fighter/color/support | Corresponding `BattleManager.saved.sides` fields |

The handoff normalizes identities only for the color-collision comparison.
Equal normalized fighters with equal colors cause side 1's color to advance
modulo 3, updating its selector before the manager write. Selected IDs retain
their forms. Support color and its collision rules belong to
[Battle support mechanics](../gameplay/characters/support_mechanics.md#setup-and-selected-support).

`battle_character_select_poll` (`0x001ED450`) owns the screen:
construct, update, then draw while the result is 0. Success 1 follows the exit
transition and two-call completion delay; cancellation returns -1. Fully
fixed construction enters the return state with no delay. Resources are
destroyed in either case; success advances the parent to 9, cancellation to `0x19`.
`manager_dispatch_state` routes 9 to `battle_state_select_stage`; Stage
Select Back enters 7 and reconstructs Character Select through restoration.
Stage confirmation advances 10
([Stages](../gameplay/stages/stages.md)).

Later, `battle_create_primary_fighter` (`0x00709860`, BTL) reads those
manager fighter/color fields. The selected color becomes
`FighterResourceConfiguration.selected_color`, whose low two bits
`fighter_load_character_record` copies into `Fighter.control_flags`
bits 1..2 before model initialization. Factory ownership belongs to
[Battle entities](../gameplay/session/battle_entities.md#primary-fighter-factory-and-lookup)
and palette/material consumers to
[Character assets](character_assets.md#model-and-appearance-name-consumers).

## Both sides' input ownership

`character_select_resolve_controllers` maps `assignment_mode` to the
two controller fields:

| Mode | Retail label | Side 0 controller | Side 1 controller |
| ---: | --- | ---: | ---: |
| 0 | 1P vs 2P | 0 | 1 |
| 1 | 1P vs COM | 0 | -1 |
| 2 | COM vs 2P | -1 | 1 |
| 3 | COM vs COM | -1 | -1 |

`character_select_update` processes side 0 before side 1. An assigned side
normally invokes `character_selector_update(selector, port)`. Once its
selector is finalized 12, its controller can drive the other side if that
side is unassigned. Mode 3 processes both unassigned sides and uses
`controlling_port` to remember who last drove an editable choice.

Root screen `mode` 0 permits an unassigned side to join on Start
(`0x0800`), initializing its selector and publishing assignment to the
manager. Outside assignment mode 3, Cross on a physical controller whose
corresponding side is unassigned calls root cancellation directly.
`character_select_assignment_labels` (`0x005B4100`) supplies the labels
to `character_select_draw_assignment_dialog` in the order above, then exit.

`character_select_cancel` uses the independent root screen `mode`:
0 opens the assignment/exit dialog in root state 3, 1 opens exit confirmation
in 4, and 2 emits a rejection cue.

`character_select_handle_assignment_dialog` combines both controllers'
newly pressed masks. Up/Down wrap over five rows, Cross closes, Circle applies.
Rows 0..3 call `character_select_update_control_assignment`, resetting
only changed assignments to each selector's first editable choice and
clearing `controlling_port` to -1. Row 4 starts the cancellation exit through
`character_select_start_cancel_exit`. Exit confirmation returns to root
state 2 for result 0, otherwise starts that same cancellation exit.

The dialog panel uses the second `character_select_panel_rectangles` record
(X 120, Y 120, 272 by 160). Rows 0..3 draw at local X 64 and Y 8, 32, 56, 80;
the exit row draws at X 30, Y 120. `battle_character_select_poll` destroys the
root for every nonzero result but changes process state only for 1 and -1, so
any other result rebuilds Character Select on the next call from the current
entry type and manager mode.

`character_selector_update` snapshots the controller's public masks into
`pressed`, `repeat` and `held`. With `navigation_countdown` zero,
`navigation` combines pressed and held; otherwise it uses pressed only
and decrements the byte. Fighter/support movement sets the cooldown to 4.
Pad production and button mapping belong to Controller input.

Only states 1,5,9 dispatch ordinary input. `state1_blocked` is the fixed
fighter flag; `state59_blocked` is the fixed support flag. These block
their respective handlers. State 12 returns status 2, state 13 status 1; other
transition states receive no ordinary menu input.

## Selection state machine

The selector state is separate from the root state.
`character_selector_enter_state` invokes the entry action and
`character_selector_advance` invokes the update action through
`member_descriptor_dispatch`. The annotated source and writable dispatch
tables own the routine mapping; the source records establish the targets
because writable tables are zero in the file image.

| State | Entry action | Update action | Role and next state |
| ---: | --- | --- | --- |
| 0 | `character_selector_enter_0` | `character_selector_update_0` | Bring fighter panel in; endpoints then 1 |
| 1 | `character_selector_enter_1` | `character_selector_update_1` | Fighter input; Circle confirms, Cross 3 |
| 2 | `character_selector_enter_2` | `character_selector_update_2` | Accepted fighter; ordinary support 4, fixed support 12 |
| 3 | `character_selector_enter_3` | `character_selector_update_3` | Fighter cancellation, then 13 |
| 4 | `character_selector_enter_4` | `character_selector_update_4` | Bring support panel in; endpoints and support animation completion, then 5 |
| 5 | `character_selector_enter_5` | `character_selector_update_5` | Support input; eligible Circle 6, Cross 7 or 13 |
| 6 | `character_selector_enter_6` | `character_selector_update_6` | Accepted support, then 8 |
| 7 | `character_selector_enter_7` | `character_selector_update_7` | Support Back; progress/completion, then 0 or 13 |
| 8 | `character_selector_enter_8` | `character_selector_update_8` | Open Linked Mode window, then 9 |
| 9 | `character_selector_enter_9` | `character_selector_update_9` | Linked Mode input; Circle 10, Cross 11 |
| 10 | `character_selector_enter_10` | `character_selector_update_10` | Accepted window closes, then 12 |
| 11 | `character_selector_enter_11` | `character_selector_update_11` | Cancelled window closes, then 5 |
| 12 | `character_selector_enter_12` | `character_selector_update_12` | Finalized; root finishes or accepts Back |
| 13 | `character_selector_enter_13` | `character_selector_update_13` | Cancelled; status 1 to root |
| 14 | `character_selector_enter_14` | `character_selector_update_14` | Finalized Back; final animation completion, then 8 or 1 |

Updates 1,5,9,13 are empty return stubs. Input is handled separately.
Fighter/support transition progress changes by exactly 0.1 per selector
update; completion flags additionally gate the states above. This is a
per-call contract, not a measured frame rate.

The root owner updates before drawing. `character_selector_draw` reaches
`character_selector_draw_linked_mode`, then `panel_draw`, which advances
the shared window. Window completion can therefore be observed on the next
update after its draw
([shared panel controller](../runtime/ui_animation.md#shared-panel-openclose-controller)).

Fighter input prioritizes Circle, Cross, L1, Triangle, then directions.
Horizontal movement wraps active columns and requires the fighter anchor's
magnitude at most 1; vertical movement toggles rows in the current column and
does not move if neither row is navigable. Ordinary confirmation requires
state 0 before resolving a form or advancing.

Support input (`character_support_handle_input`) prioritizes Circle,
Cross, Triangle, then directions. Both ordinary and random confirmation
require availability/recommendation and compatibility. Cross from 5 enters 7
for an editable fighter or 13 for a fixed fighter.
`character_selector_handle_linked_input` uses newly pressed Circle/Cross
and repeated Up/Down to wrap Linked Mode 0..1. Back preserves the choice.

From finalized 12, Cross enters 14 if either choice is editable. State 14
normally reopens Linked Mode through 8; fixed support returns to fighter 1.
Both choices fixed instead enter 13. If the controller was driving the other
unassigned side, the root first resets that other editable selector, then
applies Back to its own finalized selector. Back follows ownership.

Triangle toggles `random_category` with `random_counter` and
`random_update_guard`. Circle still confirms; Cross/Triangle stops
random selection and returns to editing. `character_selector_sample_fighter`
scans both 50-slot rows for state 0 IDs different from the current resolver
result. `character_selector_sample_support` scans 40 slots, excludes the
current support and applies availability/recommendation plus compatibility.
Both use `prng_inclusive(count - 1)` and the native setter. Sampling occurs
every second eligible invocation, at most once per update; no candidates
leave the choice unchanged. Fighter categories 2..5 exist but the inspected
Triangle path sets only 1; their reachability remains open.

## Scrollable support roster

`character_select_populate_supports` (`0x003BB210`) reads 33 active IDs
from `character_select_support_roster` (`0x005D65C0`) into shared data.
The 40-byte source is:

```text
00 01 20 02 03 04 05 06 07 13 14 15 11 10 12 16
08 09 0A 0F 0D 0E 0B 0C 1B 1E 18 19 1A 1F 1C 1D
21 00 00 00 00 00 00 00
```

Only the first 33 bytes are active; the producer fills the remaining capacity
through 39 with sentinel 24/state 7. The purpose of those spare slots remains
open. NUN5's same-named producer (`0x003CDE30`) and table
(`0x005DD710`) have the same bound, capacity and active list.
NA2's No Support sentinel 25 is used in Story Mode and is absent here.

## Compatibility

`support_pair_compatible` (`0x008858C0`, BTL) rejects support IDs at
least 24, otherwise normalizes recognized fighter forms and rejects matches
in `support_exclusion_rows` (`0x008D1980`, 104 pairs). No exclusion
returns 1. This is independent of linked-attack relationships.

The table includes Hiruko 0C and Sasori 1E excluded for both Sasori 3F and
Hiruko 4C. `character_to_base` normalizes puppet 4B to 3F before lookup;
these four pairs are part of the larger 104-entry table.

The support-cell renderer uses that predicate for the red unavailable marker.
Confirmation also requires a fighter in 1..5D with
`roster_character_valid` and `roster_secondary_filter` returning 0, plus
state 4 or membership in the three recommendations. A locked recommended
support can therefore be selected when compatible.

## Support identities and relationships

`support_identity_rows` (`0x008D28A0`) maps 34 support IDs to character
and display records. Both bytes match in every row. Support 17 maps character 58;
the other 33 map playable characters.

The ten rows of `support_cinematic_admission_table` (`0x008D2660`),
consumed by `support_cinematic_archive_path` (`0x00885660`), define these
linked Ultimate relationships:

| Selected character | Support IDs |
| --- | --- |
| Naruto 39 | Sakura 01 |
| Sakura 3A | Naruto 00, Chiyo 1B |
| Chiyo 3E | Sakura 01 |
| Sasori 3F | Deidara 0B |
| Deidara 40 | Sasori 1E |
| Itachi 47 | Kisame 0E |
| Kisame 48 | Itachi 0D |
| Orochimaru 59 | Sasuke 21 |
| Sasuke 5D | Orochimaru 1C |

The five rows of `support_linked_jutsu_rows` (`0x008D2880`), consumed by
`support_linked_jutsu` (`0x00885F00`), match the ordinary Jutsu before
selecting its linked replacement:

| Selected character | Support IDs |
| --- | --- |
| Naruto 39 | Gaara 08, Sai 20 |
| Shikamaru 44 | Choji 13 |
| Tsunade 54 | Jiraiya 18 |
| Sasuke 5D | Naruto 00 |

These are separate from selection recommendations.

## Support cursor and carousel

`character_selector_draw_support_cells` visits 13 offsets -6..6 wrapped by
the support count; `support_anchor` is scaled by 36 internal pixels.
`character_selector_set_support` resets index, page and anchor to 0, then
scans 40 slots for the requested ID in state 4/5.

The cursor persists across fighter confirmations.
`character_selector_remember_fighter` stores the associated resolved
fighter in `support_memory_fighter`; restoration also seeds it.
Confirmation resets the default only when the fighter changes or the cursor's
support fails the state 4/recommendation/compatibility checks. The same
eligible fighter therefore returns to the previous support.
`character_selector_default_support` chooses recommendation 0 for an
eligible fighter, otherwise the first support in state 4.
`character_selector_move_support` handles Left/Right with directions 2/3,
decrementing/incrementing and wrapping at either end.

## Display resolution

`character_select_construct_portraits` builds fighter portraits for
display IDs 1..5F, leaving 0 null. They use `charsel1.ccs` plate resources
`CMP_chara_ita01` / `MDL_chara_ita01`, rather than fighter body containers.
`character_portrait_rows` (`0x005D46F0`) holds 96 records including
locked 5E and empty 5F. `character_portrait_bank` supplies the texture bank;
`character_portrait_origin` supplies normalized atlas coordinates.
Construction selects `TEX_purecharsel%02d` with bank+1 and installs that
texture into the plate model.

`character_selector_draw_fighter_cells` visits 13 wrapped columns in each
row. Only the central active cell uses the resolved form; the other cells
use stored IDs. State 1 displays 5E; states 2/3 display 5F. Selected-name and
large-portrait draws independently resolve the same fighter.
`character_selector_draw_fighter_portrait` positions the shared portrait
for its side before rendering. Name rectangles and footer artwork belong to
Character Select UI layout.

The separate support-object loop creates 34 entries through
`support_character_id` (`0x008859A0`). That helper scans native support
IDs 0..21 and returns display record 0 for unmatched/larger IDs.
`character_selector_draw_support_name` and
`character_selector_draw_support_portrait` resolve sentinel 26 through
recommendation 0. The inspected large support portrait uses
`fighter_portraits` indexed by resolved display ID and positions it from
the support-panel attachment; it does not read `support_portraits`.
Broader use of the separate support array remains unestablished.
`battle_driver_child34_release` destroys both arrays and both selectors;
`character_selector_release` destroys its owned panels, animations and
sprite groups.

## Recommendation records

`support_config_resolve` (`0x00885C30`) normalizes the fighter, scans
`support_candidate_rows` (`0x008D2690`, 62 records), and returns the
requested candidate byte from the first match, or 0 with no match. It does
not bounds-check the requested index.

The 62 fighter IDs exactly cover the 62 nonzero base-roster cells. Each row has
three recommendation bytes and a fourth byte that is zero throughout; that
last byte's purpose remains open.

`character_selector_support_recommended`, fighter confirmation, both
support-confirmation branches, random selection, navigation and support-cell
drawing compare indices 0..2. Recommendations permit locked selections while
compatibility remains independent. Default support and sentinel 26 name/portrait
resolution use index 0. The bounded BTL consumers likewise use index 0 for
special-support resolution; they establish no fourth-field meaning.

Duplicates are valid: fighter 04 recommends 09/0A/09, fighter 0A recommends
00/02/00. Naruto 39 recommends 01/02/18 while linked partners include 08/20.
Recommendations are selection suggestions and locked-selection exceptions,
not extra roster entries or the definition of linked attacks.
