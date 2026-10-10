# Battle item inventory

## Research coverage

Established: retail NA2's three-slot inventory, starting items, selection and
use gates, delayed consumption, drops and aliases, random field-item identity
and amount, pickup lifecycle, HUD wheel, CPU use, and cache restoration.
The side lookup chain, exact slot offsets, first-code-match behavior, and
selected-indicator refresh during menu suspension are also established.
The known writer callers and inspected surviving presentation paths are
classified below; they do not establish unrestricted menu-time immutability.
The resident add-pointer block has no recovered live publication in the
bounded forms below; its seven literal-alias candidates are particle fades.
Open: threshold-field population, timing bytes, indirect reachability,
wider interruption/removal ordering, CPU probability,
and badge-side writers. Specific limits are retained below.

Routine, field and data names come from `@annotations/NA2`; annotation
comments own code details and direct-call/writer censuses. Addresses are live.
Findings are static retail evidence except the observed layer-17 texture
contents; timing, frequencies and visual outcomes remain unconfirmed.

This document describes retail NA2 (`SLPS-25837`). Related owners are
[Battle status effects](battle_items_and_status_effects.md) for item effects,
[Field-item names](../../localization/field_item_names.md),
[Target selection](../combat/target_selection.md#separate-side-index-eligibility-selector)
for the pickup side selector,
[Battle lifecycle](../session/battle_lifecycle.md#values-crossing-the-reconstruction-boundary)
and [Practice](../modes/practice_mode.md) for reconstruction,
[Battle AI](../session/battle_ai.md), [Battle HUD](../session/battle_hud.md),
[item-status presentation](../../localization/ui/battle/item_status.md),
[Projectiles](projectiles.md), [Resident randomness](../../runtime/randomness.md),
and [NUN3/NUN4 inventories](item_wheels_nun3_nun4.md).

## NA2 ownership

`item_manager_construct` (`0x00373AB0`) owns one `0x80`-byte `ItemPanel` for
each side in `BattleItemPresentationManager.panels`.
Initialization precedes side-specific construction. `world_side_object_get`
returns the requested panel; `item_panel_destroy` frees its slots and
owned objects.

`battle_session_get` (`0x001EC2F0`) reads `battle_session` at
`0x00607604`. `battle_active_object` (`0x00376610`) returns that session's
item-manager pointer at `+0x20`, or null for a missing session.
`world_side_object_get` (`0x00375A60`) reads manager `+0x6C` for side index
0 and `+0x70` for side index 1, returning null for other indexes. It does
not check a null manager. The panels belong to battle sides; the current
fighter is a separate lookup through `primary_fighter_get`.

`battle_create_graph` publishes fighter aliases before constructing the item
manager. `battle_destroy_graph` retires the start-menu host before destroying
that manager. The panel and slot addresses are allocated ownership, not fixed
resident addresses; reconstruction creates their replacements. The complete
graph order belongs to [Battle lifecycle](../session/battle_lifecycle.md).

## NA2 panel layout

`ItemPanel` contains three pointers to separately allocated eight-byte
`ItemInventorySlot` objects. A slot is occupied only when `item` and
signed `count` are both nonzero. Slots stay in their physical positions;
selection and removals never compact them.

The following offsets are verified by `item_panel_construct`
(`0x0070F740`), `item_panel_initialize` (`0x0070F460`), and slot consumers:

| Owner | Offset | Width / meaning |
| --- | ---: | --- |
| `ItemPanel` | `+0x00/+0x04/+0x08` | Three independent slot pointers, four bytes each |
| `ItemInventorySlot` | `+0x00` | Unsigned item-code byte |
| `ItemInventorySlot` | `+0x01..+0x03` | Unnamed bytes; not part of the code or quantity |
| `ItemInventorySlot` | `+0x04` | Signed four-byte quantity |
| `ItemPanel` | `+0x14` | Selected-item presentation object pointer |
| `ItemPanel` | `+0x20` | Signed four-byte side index, 0 or 1 |
| `ItemPanel` | `+0x24` | Signed four-byte physical selection index, 0..2 |
| `ItemPanel` | `+0x28` | Float wheel displacement |
| `ItemPanel` | `+0x61/+0x62/+0x63` | Activation / advance / event marker bytes |

`item_panel_seed_infinite` (`0x007102A0`) writes the supplied byte directly
to physical slot zero and quantity -1, setting `activation_marker=3`.
The ordinary finite-add path has different placement and stacking semantics.

The panel owns an animation object (28 bytes), `ItemSelectBadge` (48),
selected-item object (24), list object (16), and support-gauge controller (44).
Its `side`, `selected_slot`, `wheel_offset`, `base_position`,
`position_offset`, and `wheel_origin` describe the wheel.
`base_position` is X 66 for side 0 or 446 for side 1, Y 340.
`item_panel_position` adds the two position vectors.
`item_panel_animate_position` approaches `vertical_offset` toward 200;
`item_panel_vertical_offset` reads it. The inline object's width and complete
layout at panel `+0x64` remain unnamed.

`activation_marker`, `advance_marker`, and `event_marker` are per-update
signals cleared by `item_panel_update`, not retained consumption state.
The constructor seeds the inventory in order: the character's kind-6 item,
a personal consumable when admitted, then all qualifying threshold rows.
All three steps share ordinary three-slot capacity.

### Starting-item generation

`Fighter.character_id` is the active battle ID
([Character identity](../characters/character_ids.md#active-battle-identity)).
`item_character_seeds` contains 93 ascending keys, every ID `01..5D` once.
The first matching nonzero code goes into slot zero with count -1; unmatched
or zero keys do not seed it. All 19 distinct seed codes have metadata kind 6.

| Seed code | Character IDs |
| ---: | --- |
| `0F` | `01,03,06,0C,0E,10,12,15,16,17,1A,1D,1E,1F,20,21,2A,2F,31,33,39,3C,41,43,47,48,4E,50,51,53,56,58` |
| `10` | `02,05,07,08,09,0B,0F,13,18,25,29,2B,2C,2D,2E,30,37,3A,3D,3E,44,46,4A,4D,57,59,5B,5C,5D` |
| `11` | `0A,19,1B,1C,4C,52,54,55` |
| `12` | `04,32,3B` |
| `13` | `0D,42` |
| `15` | `11,4F` |
| `16` | `14,45` |
| `17` | `22,34` |
| `18` | `23,35` |
| `19` | `24` |
| `1A` | `36` |
| `1B` | `26,38` |
| `1C` | `27` |
| `1D` | `28` |
| `1E` | `40` |
| `1F` | `3F` |
| `20` | `49` |
| `21` | `5A` |
| `22` | `4B` |

`item_has_personal` admits IDs at least `39`.
`item_personal_code` returns zero for a null fighter; IDs below `39`
draw inclusively from the five-code pool `24,25,26,27,28`.
Supported higher IDs use `item_personal_records`' first byte:

| Character IDs, in order | Returned codes, in order |
| --- | --- |
| `39,3A,3B,3C,3D,3E,3F,40` | `51,52,53,54,55,56,57,58` |
| `41,42,43,44,45,46,47,48` | `59,5A,5B,5C,5B,5D,5E,5F` |
| `49,4A,4B,4C,4D,4E,4F,50` | `60,73,61,62,63,64,65,66` |
| `51,52,53,54,55,56,57,58` | `67,68,69,6A,6B,6C,6D,51` |
| `59,5A,5B,5C,5D` | `6E,6F,70,71,72` |

ID `54` starts with three copies of `6A`; every other nonzero personal
result starts with one. The lower-ID random branch is not reached by this
constructor's personal-consumable gate.

`item_threshold_seeds` is a cumulative threshold list. Every qualifying row
adds one, in stored group order:

| Code | Thresholds, in stored order |
| ---: | --- |
| `27` | `5,28,50,72,96,112,142,169,186` |
| `09` | `20,44,66,88,102,134,156,178,195` |
| `26` | `40,80,120,160,190` |
| `28` | `66,147,200` |

The threshold compares fighter signed halfword `+0x17E`, whose meaning and
nonzero population remain unresolved. `fighter_load_character_record` clears it.
No nonzero writer is established; overlapping word stores, calculated
addresses and bulk copies remain unclassified.
This does not establish positive thresholds in ordinary battles.

`battle_save_reentry_values` and `battle_restore_reentry_values` retain HP, chakra,
timers and item cache, not `+0x17E`; `battle_create_graph` creates fresh
fighters whose setup clears it. Thus those snapshot paths do not supply it.
Earlier threshold groups can fill capacity before later rows.
Reconstruction contracts belong to
[Awakening](../characters/awakening.md#state-retained-across-the-native-rebuild)
and [Practice](../modes/practice_mode.md#reconstruction-entry-and-retained-setting-owners).

## NA2 slot routines

There are exactly three physical slots, with selection wrapping over indexes
0..2. `item_panel_count` and the HUD count only occupied slots.
`item_panel_can_add` (`0x0070FBD0`) first requires metadata flag `0x80`.
It accepts a first same-code slot whose signed count is below 9, without
checking that slot's occupancy; when there is no code match, it requires
free capacity. `world_side_object_blocked` reports occupied count at least three.

`item_panel_find_code` (`0x0070FD40`) searches physical indexes 0..2 and
returns the first pointer with the matching code byte. It does not check
quantity or reject zero; an empty slot can match zero. `item_panel_count_code`
(`0x0070FD00`) returns that slot's quantity, or zero when no code matches.
It does not sum multiple matching slots.

### Metadata bounds and inventory admission

`item_metadata_table` (`0x005B04F0`) contains 116 twelve-byte records for
codes `00..73`. `world_object_kind_get` (`0x003765B0`) masks the code to
eight bits and indexes the table without a `73` upper-bound check.
`item_flag80_get` (`0x003763D0`) also lacks a table-bound check.
The table's flag-`0x80` codes are exactly `09,0E,23..2C,2E..31,51..73`;
kind 6 is exactly `0F..22`. These are separate properties: the native
kind-6 seed path does not require flag `0x80`.

Flag `0x80` establishes inventory admission, not successful use or a valid
projectile. Code `0E` is a field alias resolved before ordinary inventory
collection; see [pickup aliases](#field-object-drops-and-pickup-aliases).
Kind-6 `14` has no established projectile match; see
[item codes and projectile indexes](#item-codes-and-projectile-config-indexes).
Effect interpretation belongs to [Battle status effects](battle_items_and_status_effects.md).

### Occupied-order access and removal

`item_panel_code_relative` and `item_panel_count_relative` use occupied-entry
displacements from the selection. Displacement zero finds the first occupied
slot at or after it; signed displacements walk occupied slots in either
direction. Empty panels return zero. `item_panel_relation` and
`item_panel_category` instead take raw physical indexes.

`item_inventory_add` first stacks onto the same occupied code below 9.
Count -1 stays unchanged; other sums clamp to 0..9.
A same-code slot already at 9 rejects addition even with another slot empty.
An absent code uses the first empty slot relative to selection if capacity
remains, writing the incoming count directly without an arithmetic clamp.
Stacking and new insertion return 1; capacity rejection returns 0.
Metadata flag `0x80` is a caller's gate, not this routine's validation.

`item_inventory_add` stops at the first matching code byte before checking
occupancy. A stale first match with quantity zero can therefore hide a later
occupied duplicate. Native add operations merge a code into its existing
occupied slot rather than deliberately creating duplicate occupied codes.

`item_inventory_consume` and `item_panel_remove_relative` reject kind-6
items before count handling. Other items clear when amount is at least count
or equals -1; otherwise subtraction clamps to 0..9. The count--1 bypass is
inside that subtraction branch, so it does not protect arbitrary non-kind-6
negative counts from positive removals.

`item_inventory_consume` (`0x007102D0`) searches physical indexes in order,
stopping at the first code match; an unoccupied first match ends removal.
With two occupied same-code slots, it decrements the earlier one even when
the later one is selected. `item_panel_remove_relative` (`0x00710470`)
instead identifies its target by occupied displacement. A dispatch code,
selected slot, and code-based removal target are consequently separate inputs.

If the selected slot empties, both choose occupied-step zero, or physical
index zero when all are empty. Only relative removal adds 1.0 to
`wheel_offset`. `item_panel_clear_finite` clears non-kind-6 slots without
reselection. Native infinite entries survive by their kind-6 gate.

### Field-object drops and pickup aliases

`item_inventory_random_drop` chooses an occupied displacement while skipping
the last kind-6 displacement it found; with only that entry it returns.
Native initialization supplies one kind-6 entry. Each selected object count
is one, except original `6A` with count at least three, which yields
`floor(count/3)`. Personal codes `51..73` become field code `0E`.

`item_field_emit` uses the fighter's position with native height adjustment
and the supplied spread/radius. Removal follows emission, consuming the
emitted object count from the original displacement. Its special three-count
removal tests the already-normalized code, so original `6A` cannot take it:
count three emits one `0E` object, consumes one, and leaves two.
This is a static branch result.

`item_inventory_bulk_drop` walks occupied displacements before changing
inventory. It emits every non-kind-6 code unchanged with its full count,
except `6A`: one below three, otherwise `floor(count/3)`.
It then clears every non-kind-6 slot without checking per-entry success.
Thus random drops normalize personal codes; bulk drops preserve them.

#### Drop callback identities and gates

`ccProjSIWTrap` overrides the root action callback with
`item_trap_random_drop`. It first disables collision and signals its handle
through `projectile_trap_terminate`. A cached fighter major state of 6
suppresses both four random-drop requests and a separate visual service.
`projectile_siw_trap_motion` samples that state from the same-tag fighter during local
phase zero. The gate therefore uses a prior sample, not a fresh lookup.
Requests use spread 90 and radius inputs 15,10.

The root `projectile_contact_response` calls its action callback when
`Projectile.action_callback_trigger` equals 1.
`hit_mode1_apply` can set it even on a branch that skips the
downstream contact effect, unless its initial gate result is 1.
The callback trigger alone therefore does not prove a successful effect.
Wider collision and motion belong to
[Projectiles](projectiles.md#collision-facing-interface) and
[Projectile motion](projectile_motion.md#stationary-and-resource-controlled-phase-timing).

`ccSkillTND001`'s `item_tnd001_action_update` reaches
`item_tnd001_random_drop`, which makes three separate one-request drops
using `ItemTnd001Work.side`, spread 25 and radius inputs 20,10.
The earlier `action_age/action_limit` gate increments an age below the
limit and exits while the resulting age is still below it and nonnegative.
Only after that gate does a nonzero `drop_countdown` decrement; its
transition to zero invokes the drop helper.

`tnd_construct` initializes that countdown to zero.
The phase-4 helper `effect01_06_source` processes a nonzero
`phase4_event`; it samples `phase4_branch` before its separate call to
`item_skill_event_service`. Branch value 2 arms countdown 3.
The event tail sets age -2 and limit 15, including branch 2.
Branch 1 requests effect 1 for 100; branch 3 requests effect 6 for 300.
The byte is the finishing-pattern index at actor `+0x18F3`, written by
`tsunade_legacy_jutsu1_select_pattern` (`BTL 0x00802240`) during
`tsunade_legacy_jutsu1_initialize` (`0x008009A0`): weighted indices
0..3 or computed index 4. This is NA2's retained resource-52 TND actor,
corresponding to NUN4 ID-25 Tsunade's Gambling Shot, rather than playable
NA2 ID-84 Tsunade's resource-173 TNW actor. The countdown is not armed
merely by entering phase 4 or calling the separate helper. The actor comparison
is owned by [Character assets](../characters/nun4/tsunade.md#retained-tnd-ordinary-jutsu-executable-comparison).

The root bulk case of `projectile_action_response` calls
`projectile_begin_retirement_countdown` first, then bulk-drops only if the manager
exists. Its integer spread input is 120 when `Projectile.scalar1 > 0`,
otherwise 60; radius inputs are 30,10 and final spread 50.
It still performs its separate visual service and common tail:
clear `service_enabled`; when `retirement_gate == 0`, set state 3
and signal the handle.

Only config `6E`, external ID `004B`, has authored action selector 4.
Its factory chooses SIWTrap, whose override performs random drops.
That authored selector therefore does not establish ordinary virtual
reachability of the root bulk body. The inspected direct base callers are
outside the SIWTrap family; indirect routes and record mutation remain open
([root state transitions](projectiles.md#hit-and-despawn-evidence)).

`field_item_code_resolve` ignores its object argument and returns the incoming
code for a null fighter. Code `0E` always becomes that fighter's personal
code (or the five-code random result below ID `39`). For higher IDs, a
matching adjacent alias byte also resolves to the personal code:

| Character IDs | Alias pickup code | Personal inventory code |
| --- | ---: | ---: |
| `39,58` | `23` | `51` |
| `3C` | `26` | `54` |
| `43,45` | `24` | `5B` |
| `53` | `2F` | `69` |
| `54` | `30` | `6A` |

All other supported IDs `39..5D` have alias byte zero. The resolver has a
lower-ID gate and no upper bound; these are supported rows only.
Resolved `6A` adds three; other inventory codes add one.
Metadata and effects belong to
[the resident pickup resolver](battle_items_and_status_effects.md#resident-pickup-resolver).

### Random field-item selection

#### Selector contract and pools

`field_item_random_select` accepts `ItemRandomDistributionRow` pairs.
It draws inclusively over 0..99 and accepts when the draw is at most the
cumulative threshold, adding the next increment after a miss.
Pool kind zero terminates after row zero, so only the first row can use it.
Failure to select a nonzero code returns `04`.
Both fixed distributions reach cumulative 100, making that fallback
unreachable for their draw. A shortened distribution can produce `04`,
whose metadata is kind 2, flags `0040`, positive-resource amount 0.75.

| Kind | Item-code lanes | In-pool selection | Data |
| ---: | --- | --- | --- |
| 0 | `02,03` | equal two-lane draw | `item_random_pool0` |
| 1 | `06,07,08,09,0A,0B,0C,25,27,2B,0D,0E` | modulo 12; nominal 1/12 | `item_random_pool1` |
| 2 | `24,23,27,25,2B,28,26,29,2A,2B,2C,2E,2F,30,31` | modulo 15; nominal 1/15 | `item_random_pool2` |
| 3 | `03` | deterministic | `item_random_pool3` |
| 4 | `02,02` | two-lane draw, deterministic result | `item_random_pool4` |

Pool 2 duplicates `2B`, doubling its lane weight. Fixed distributions
do not use pool 4. The 22 resident named codes belong to
[Field-item names](../../localization/field_item_names.md#resident-field-item-name-table).
Codes `02/03` are outside that name table, on positive-resource paths.
Their recorded internal strings are `ItemRecoverLife/ItemChakraBall`;
how those code associations relate to the kind-1/code-4 factory branches
remains unresolved. Code `29` is also outside that table: kind 3,
flags `0180`, direct effect `0A`, identified as **Curse Tag: Chakra Points
Seal** ([name reference](../../localization/field_item_names.md#code-29-curse-tag-chakra-points-seal)).

#### Fixed BTL distributions

| Copies | Rows |
| --- | --- |
| `item_general_distribution_a`, `item_general_distribution_b`, `item_general_distribution_c` | `(1,20),(2,60),(3,20),(0,0)` |
| `item_recovery_distribution_a`, `item_recovery_distribution_b` | `(0,50),(3,50),(0,0)` |

Each family's copies are byte-identical. Inclusive threshold boundaries
give General rolls 0..20 to pool 1 (21%), 21..80 to pool 2 (60%), and
81..99 to pool 3 (19%). Recovery gives 0..50 to pool 0 (51%) and
51..99 to pool 3 (49%). General has 24 unique outcomes: all 22 named codes
plus `03/29`; Recovery has only `02/03`; their union has 25.

| Code | General | Recovery |
| ---: | ---: | ---: |
| `02` | — | `25.5%` |
| `03` | `19%` | `74.5%` |
| `06` | `1.75%` | — |
| `07` | `1.75%` | — |
| `08` | `1.75%` | — |
| `09` | `1.75%` | — |
| `0A` | `1.75%` | — |
| `0B` | `1.75%` | — |
| `0C` | `1.75%` | — |
| `0D` | `1.75%` | — |
| `0E` | `1.75%` | — |
| `23` | `4%` | — |
| `24` | `4%` | — |
| `25` | `5.75%` | — |
| `26` | `4%` | — |
| `27` | `5.75%` | — |
| `28` | `4%` | — |
| `29` | `4%` | — |
| `2A` | `4%` | — |
| `2B` | `9.75%` | — |
| `2C` | `4%` | — |
| `2E` | `4%` | — |
| `2F` | `4%` | — |
| `30` | `4%` | — |
| `31` | `4%` | — |

Each column totals 100%. Pool 2 contributes 8% to `2B`, combining with
pool 1 to give 9.75%; overlapping `25/27` similarly total 5.75% each.
These are authored bucket/lane weights. `prng_inclusive` takes a
32-bit PRNG result modulo `abs(bound)+1`: modulo 100 residues 0..95,
modulo 12 lanes 0..3, and modulo 15 lane zero each have one extra source
value. Each excess is one in `2^32` inputs per call. Actual frequencies
also depend on the PRNG sequence
([MT wrappers](../../runtime/randomness.md#mt-wrappers)).

#### BTL call sites and limits

`item_field_random_spawn_a` and `item_field_random_spawn_b` select their
Recovery copy only for mode 1, General otherwise. Their inspected direct
callers pass mode zero. `bg_break_doll_update` uses General A;
its wider object semantics remain unresolved.
`item_field_random_spawn_c` always uses General C; its two state-dependent
caller branches each make three requests while varying one position
component by a random offset bounded by 10.0. Their branch state is open.

The four inspected direct selector paths each pair identity selection with
the amount helper. No direct caller selects Recovery, so Recovery is authored
and callable but not proven reachable; indirect scheduling remains possible.
Only General's 24 outcomes have established direct-call behavior.

#### Identity and amount boundary

Identity and quantity are separate: `field_item_random_select` chooses
a code without a spawn-frequency input; `field_item_amount_apply` applies
the mode-aware Items amount setting. Its base and probabilistic extra-base
requests pass the selected code. Its final count-controlled loop instead
publishes literal `04`, independently of the unreachable fixed-distribution
fallback. Codes `03/04` share kind 2 and flags `0040`, with resource
amounts 5.0 and 0.75 respectively.

`item_field_publish` rejects a zero selected code. That suppresses its base
requests but does not stop the amount helper's later code-`04` loop.

## Field-pickup object lifecycle

Pickup objects choose a collecting side through
[Target selection](../combat/target_selection.md#admission-gate-and-selector-body).
They retain a side index, not a fighter pointer.

### Factory, classes and publication

`item_pickup_factory` has three established branches:

| Branch | Registered class | Allocation | Constructor | Methods |
| --- | --- | ---: | --- | --- |
| ordinary | ItemData | `0x80` | `item_pickup_construct` | `item_data_methods` |
| metadata kind 1 | ItemRecoverLife | `0x80` | `item_pickup_life_construct` | `item_life_methods` |
| code 4 | ItemChakraBall | `0x1A0` | `item_pickup_chakra_construct` | `item_chakra_methods` |

These are registered identities, not recovered source declarations or a
complete class census. ItemData and ItemRecoverLife share
`item_pickup_admit`; ItemChakraBall uses `item_pickup_chakra_admit`.
All lead to `item_pickup_select_continue` under their admission gates.

`item_pickup_initialize` copies position/velocity, stores `active_item`,
clears `authored_item` (the secondary resolved-code byte), sets `side=-1`,
and enters state 1. It owns a collision handle and auxiliary object.
`position` is a vector; it is not the fighter's same-offset paired pointer.
`item_field_publish` assigns the manager's serial, links the previous head
through `next`, and publishes in `pickups`. Publication does not select
or retain a fighter.

### State dispatcher and admission wrappers

`item_pickup_dispatch` routes states 1/2 to methods `state1/state2`,
6/7 to `state6/state7`, and 5 to `state5`.
The ordinary state-2 method calls admission first; ordinary state 3 can
call it again. Wider indirect callers remain open.

Ordinary admission requires a collision handle with nonzero
`CollisionQueryList.result_count` and `result_mask` intersecting `0x110`.
Continuation result 2 enters state 5 and
returns 4; result 3 enters state 5 and returns 2; both clear
`state_counter`. Other results return 1 without transitioning;
a null handle returns zero. These are lifecycle results, not fighter pointers.

Chakra admission assumes a nonnull handle and uses the same result/flag gates.
Continuation result 2 sets `collection_latched=1` and returns zero;
other results return 1. It does not perform the ordinary state-5 transition.
Its state-2 method invokes admission only while unlatched and while preceding
local motion permits continuation. After latching, selection stops but the
object stays until its eight local decay entries complete. Admission's zero
therefore does not immediately free it, and its retained index can survive
that interval. `item_pickup_chakra_decay` approaches each positive alpha
toward zero by 0.1 and reports completion when none remains positive.

### Selector continuation and terminal results

After side selection, `item_pickup_select_continue` resolves `active_item`
against that side's fighter, storing the result in `authored_item`.
For metadata flag `0x80`, the resolved code must pass the side-inventory
gate. Rejection unregisters the handle, sets `retry_countdown=10`,
clears `side=-1`, and returns 1.

Other terminal selector results depend on `side_result_mode`:

| Mode | Side 0 | Side 1 |
| ---: | ---: | ---: |
| 1 | 3 | 4 |
| 2 | 4 | 3 |
| other | 0 | 0 |

No eligible side returns zero with index -1. These values are not fighter
pointers.

### Collection, retained-index readers and teardown

After the fresh fighter recheck, continuation unregisters the collision
handle and clears `collection_scalar`. Selector result 4 additionally
runs `item_pickup_result4`. Collection then invokes the virtual `collect`
method with magnitude 1.0: `item_pickup_callback` for ItemData/ChakraBall,
`item_pickup_life_collect` for ItemRecoverLife. Both resolve the fighter
afresh from `side`; the ordinary callback also requires the side-control
alias. Effects belong to
[the pickup callback contract](battle_items_and_status_effects.md#btl-pickup-object-callback).
The continuation returns 3 for metadata flag `0x80` on `active_item`,
otherwise 2; it stores no fighter pointer.

The index survives successful state-5 entry. `item_pickup_retained_side`
later requires a freshly resolved fighter and
`fighter_placement_check_b`, a different predicate from initial admission.
State 8 uses `item_inventory_point` to request a point from that side's
inventory. `item_pickup_retry_tick` decrements a positive retry countdown
once; transition to zero registers the retained handle again.
This defines rejection/retry, not fighter ownership.

`primary_fighter_get` accepts indexes 0/1, returning the primary fighter
aliases; other indexes return null. It assumes the manager global exists.
Fresh null checks do not establish arbitrary manager safety or ordering
against isolated fighter removal.

`item_pickup_list_update` adds `active_item` to `side` inventory on
dispatch result 2; zero unlinks and invokes destruction.
`item_pickup_destroy` and `item_pickup_life_destroy` release collision
and auxiliary objects; positive destructor mode also frees the pickup.
Cleanup never resolves or releases a fighter and need not clear the index
before free. `item_pickup_list_destroy` destroys the complete list on the
coordinator transition and clears its head.
These establish the index owner's lifetime; wider removal ordering is open.

## NA2 selection

`item_input_dispatch` requests forward selection through the resident manager
wrapper. `item_panel_advance` refuses while panel state is 1 or occupied
count is below two. Otherwise it sets `advance_marker`, adds 1.0 to
`wheel_offset`, advances one occupied slot, and plays sound 42.
Selection moves forward, skipping empty slots.

`input_build_logical_mask` maps Use Item to logical `0x01000000` and Item
Select to `0x02000000`. Linked Attack's transient `0x04000000` is replaced
by `0x20000000`, so native output does not provide it.
The fighter gate nevertheless checks that bit after Item Select and reaches
the alternative resident wrapper, whose panel alias calls the same forward
advance. No other BTL producer was found.

### Selected-use eligibility and fallback

The native input gate rejects major 7 before selection or use.
Its selection states are:

| Major | Selection admitted |
| ---: | --- |
| 0 | substates 0,3,4,5,6,7 |
| 1 | `0E..14` |
| 2,3,4,5 | all |
| 6 | `5D..60` |
| 8 | zero `exchange_roles` and `context_state` |

Initial use eligibility is narrower: major 0 substate 0/5, major 1
`0E..14`, majors 2/3/4, or admitted major 8. Other selection states try
`item_input_fallback` but require result 2; its inspected body returns only
0/1. That branch establishes no additional native use state.
Delayed action admission remains separate.

`item_panel_selected_use` reads the physical selected code.
Metadata flag `0x100` additionally requires equality of **side 0's**
`section/target_section`, regardless of panel side.
Its unsigned-byte comparisons to -1 do not establish an effective `FF`
sentinel rejection.

`item_panel_item_eligible` requires the projectile manager and checks:

| Item code | Item-specific rejection condition |
| ---: | --- |
| `28` | Config `0D` exists for the panel side |
| `27` | Config `12` exists, or config `13` count is at least `11` |
| `2E` | Either config `2E` or `2F` exists |
| `2F` | Config `44` count is at least `2` |
| `5C` | Config `34` count is positive |
| `6E` | Config `9C` exists, or config `9D` count is at least `6` |
| `6B` | `support_get(side)` is nonzero and `item_character_selector(0x19, selected_character_id)` returns byte `0x35`; or config `B5` count is positive |
| `69` | Config `9B` count is positive |
| `65` | Config `99` count is at least `3` |

The extra `6B` branch uses `support_get` and
`item_character_selector`; its wider gameplay interpretation is open.
`transient_actor_exists` and `transient_actor_count` walk the actual
per-side list using config index and inverse side tag, including objects
awaiting removal
([Projectile limits](projectiles.md#limits-and-pooling)).
Other byte codes pass when the manager exists. This helper does not check
occupancy or count.

Successful gates return the original code. Failure uses that panel side's
controller nibble: zero plays sound 44 and returns zero; nonzero samples
slot-zero relation once and attempts at most two advances toward kind 6.
Relation 2 uses the ordinary advance; other relations use its forward alias.
It returns the resulting selected code even if advancement is blocked or
kind 6 is not reached, without rerunning eligibility. Successful fallback
advances retain sound 42 and offset changes
([Battle AI](../session/battle_ai.md)).

### Dispatch and consumption boundary

`item_selected_resolve` requires the item manager.
Metadata kinds 3/6 with flag `0x10` clear take the delayed action route,
requiring zero `item_action_blocker` and `item_action_admit`.
`action_exit_clear_pending` stores `pending_item_code` and enters major 7,
substate `63/64/65`, without decrementing inventory.
Kind-4/flag-`0x10` codes use the same readiness gate but activate immediately.
Other immediate effects and their six-code fallback belong to
[Battle status effects](battle_items_and_status_effects.md#btl-pickup-object-callback).

After either accepted route, `item_use_voice` can request a fighter
voice event before any delayed commit. Nonzero code draws 0..99; below 50
draws 0..2 to select event 3,4,5. The request neither consumes inventory nor
proves emission or audible playback
([Battle audio](../session/battle_audio.md#fighter-voice-event-selection)).

#### Admission and pending-action setup

`item_action_admitted` combines zero cooldown with `item_action_admit`.
The action-facing predicate admits major 0 substates 0,3,4,5;
major 1 `0E..13`; and majors 2/3/4. Major-1 `12/13` also approach
planar/vertical speed toward zero, so admission can change motion.

Major 8 requires a current record, rejects flag `0x200`, rejects
`0x100` when `pending_action != -1`, and requires zero exchange roles
and context state. With flags `0xC0000`, primary cursor must be below 16.
Otherwise `item_action_admission` admits immediately when nonzero;
failing that, animation progress at the current final frame must be in
inclusive 0.5..0.95. Other majors fail.

Pending setup saves `item_use_work` to `saved_item_use_work`, clears
the former, and increments `item_projectile_count` after entry.
From major 8 it clears attack banks and inline work and resets pending
continuation. Grounding normally chooses `63`, airborne `64`.
For `reaction_variant & 3 >= 2`, grounded entry clears motion and uses
`65`; airborne entry performs its air setup and uses `64`.
The two-bit value's wider meaning is not established by this trace
([action ownership](../combat/combat_action_execution.md#action-entry-and-state-ownership),
[awakening counter](../characters/awakening.md#proven-hp-and-counter-prerequisites)).

#### Timing-record producer and exit cooldown

Major-7 `item_action_update` supplies active character ID minus one to
`item_delayed_use_commit`. Its code argument is the retained signed halfword
`Fighter.pending_item_code` at `+0xB70`, read at `0x00237E28` before the
call at `0x00237E34`; it does not reread the selected slot for that argument.
`item_use_timing` has 93 `ItemTimingRecord`s,
each containing lanes `63/64/65`. There is no ID range check.
Signed `start/end` bound kind-6 cursor emissions; unsigned `rate`
provides animation rate and the non-kind-6 secondary target.
Lane bytes `+2/+3` remain unresolved.

`fighter_advance_animation` uses `item_use_rate` only for major 7,
otherwise the fighter's `secondary_rate`. It multiplies the chosen rate
by `update_rate`, converts to integer and writes the primary player's
halfword step. Nonzero `animation_result` overrides it with zero.
Steps are in 1/256 frame
([Animation runtime](../../runtime/animation_runtime.md#advance-and-end-behavior)).

Leaving major 7, including interruption through the common setter,
runs `item_exit` and `item_cooldown_assign`, obtaining
`item_use_cooldown` for the same substate/ID lane.
This assigns `item_action_blocker` without activation or decrement.
Cooldowns are 8 for lane `64`, 24 for `65`, and 16 for `63`
except IDs `05/0A`, which use 12. Unsupported substates leave a null
lane pointer; established major-7 paths use `63..65`.

`fighter_update_countdowns` decrements every nonzero signed cooldown by
one before the later pause gate, independent of fighter delta.
Negative values also decrement. `effect_7d_update` can assign 30
on its major-7/`64` exit; `effect_4a_callback` clears it.
An overlapping BTL skill-object `+0xB72=8` store is not a proved fighter
writer. Wider interruption ordering remains open.

#### Authored lanes and action completion

Native descriptors `ACT_ITM_0/1/2` (`63/64/65`) use animation slots
`42/43/1B`, start zero, rate `0100`, with progression animation end /
grounded / animation end, each followed by a terminal row.
Shared progression belongs to
[Combat action execution](../combat/combat_action_execution.md#shared-phase-progression).

Representative timing variants: each cell is
`[start,end), cooldown, rate`; cursors/cooldowns decimal, IDs/rates hex.
Unknown bytes are omitted.

| Character ID | Lane `63` | Lane `64` | Lane `65` |
| --- | --- | --- | --- |
| `01` | `[7,11),16,01A0` | `[5,9),8,0100` | `[5,9),24,0100` |
| `02` | `[7,11),16,0180` | `[5,9),8,0100` | `[5,9),24,0100` |
| `05` | `[10,14),12,0100` | `[5,9),8,0100` | `[5,9),24,0100` |
| `0A` | `[9,13),12,0140` | `[4,8),8,0100` | `[7,11),24,0100` |
| `22` | `[5,9),16,0170` | `[4,9),8,0100` | `[8,12),24,0100` |
| `23` | `[7,11),16,01A0` | `[5,9),8,0100` | `[8,12),24,0100` |
| `40` | `[5,11),16,01A0` | `[7,13),8,0100` | `[7,13),24,0100` |
| `5B` | `[4,7),16,01A0` | `[4,8),8,0100` | `[5,9),24,0100` |

After shared progression, `item_action_complete` handles major 7:

| Substate | Completion |
| ---: | --- |
| `63` terminal | grounded → `(0,0)`; airborne with equal movement/placement facing → `(3,1E)`, otherwise `(3,25)` |
| `64` | grounding → `(4,26)` even without terminal; airborne terminal → `(3,21)` when facings equal, otherwise `(3,25)` |
| `65` terminal | enter `(1,13)` and advance phase if zero; then run the fresh-ground check below |

The fresh check for `65` can, even without terminal, clear airborne setup,
set grounding, approach planar speed toward 10, set vertical speed to float
bits `3851B717`, and enter `(7,63)`. These statements run in order,
so completion outcomes are not mutually exclusive.
The late physical exit also requires status byte bit zero clear, no contact
query result and nonzero animation result before assigning cooldown 30.

Neither completion path activates an item. Exit before a successful commit
does not decrement in the inspected cleanup chain; an earlier activation
is not refunded there. This is a static boundary, not a timing/reachability
observation.

`item_delayed_use_commit` checks kind-6 primary cursor positions with
`item_emission_scale` influencing emission count and spacing.
Other delayed codes require the primary cursor-zero check to return zero
and a secondary-cursor check to succeed; that target is half the action
frame length divided by `rate/256`. Only a successful timing gate
activates, then calls `item_emit`. The helper returns 1 for kind 6 or
code `2B`, otherwise 0, independently of whether that invocation committed.
Projectile contact is not a prerequisite established by this cursor gate.

`item_panel_activate` requires manager, side fighter and at least one
occupied slot. Zero supplied code resolves selected use; nonzero code is used
directly. Code `27` has a separate rejection before the tail;
`51..73` dispatch status effects. The common tail consumes one from the
**currently selected slot's code**, not necessarily the supplied dispatch
code, and sets `activation_marker=1` without per-effect success checking.
Kind-6 survives; positive counts lose one once the tail is reached.

Activation also calls `item_record_distinct_use` twice for finite counts,
once for -1. For a fighter with controller nibble zero,
`ItemDistinctUse` records each distinct code once among 116 bytes and
increments its count only on a new insertion. At three it signals condition
42 for `side+1`. Repeated calls do not double-count; this bookkeeping is
separate from inventory quantities.

### Item codes and projectile config indexes

`item_emit` treats the incoming item code unchanged as an external
projectile ID and searches the first matching signed leading halfword in
the 182-row `projectile_configs`. It spawns with that config index,
fighter control bit zero and vectors; nonzero spread perturbs the target.
The post-loop `ProjectileConfig.emission_sound` lookup uses the same external ID.
Item code, external ID, config index and class selector are distinct
([Projectile configuration](projectiles.md#configuration-and-factory)).

All values below are hexadecimal and paired left to right.

| Seeded kind-6 codes | Projectile config indexes |
| --- | --- |
| `0F,10,11,12,13,15,16` | `00,01,02,03,0E,0F,11` |
| `17,18,19,1A,1B,1C,1D` | `36,37,38,39,3C,3A,3B` |
| `1E,1F,20,21,22` | `8A,91,7C,AE,92` |

| Generic inventory codes | Projectile config indexes |
| --- | --- |
| `23,24,25,26,27,28,29` | `04,09,0B,0C,12,0D,1C` |
| `2A,2B,2C,2E,2F,30,31` | `1D,0A,2B,2F,30,35,85` |

Code `27` reaches config `12` through activation's direct external-ID
wrapper. Missing generic code `2D` has metadata `0x80` clear and maps to
config `2E`; mapping alone does not establish ordinary inventory collection.

| Personal kind-3 codes | Projectile config indexes |
| --- | --- |
| `51,54,57,58,5A,5B,5C,5E` | `7D,A1,88,8C,83,7E,84,A2` |
| `61,62,65,69,6A,6B,6C,6E,6F` | `93,90,98,9A,80,B5,AD,9C,B0` |

Other `51..73` codes are kind 4 and use immediate status effects.
`5B` participates in both a delayed projectile path and a status row.
Kind-6 `14` is absent from the seed table and has no matching external ID.
The emitter passes lookup failure -1 onward and does not cancel preceding
activation or refund a consumed count on lookup/construction failure.
Native reachability of `14` remains unproved.

## NA2 HUD wheel

`item_panel_draw_wheel` uses occupied count `n <= 3`.
It draws the background at `wheel_origin`, empty frames at positions
`n..2`, then occupied items at `k=-1..n-1` shifted by `wheel_offset`:

```text
x = -45 * sin(0.2 * pi * k)     (negated for side 1)
y = -20 * k
first factor  = 1 - 0.10 * |k|
second factor = 1 - 0.15 * |k| for k >= 0, else 1 - |k|
```

Position zero is selected; following occupied slots use `1..n-1`.
At rest the second factor is zero at -1, so the previous item appears only
during animation. Resting positions are 0..2; X returns to zero at k=5.
The selected count has a separate element for -1.

`item_panel_draw` computes `wheel_origin=base_position+position_offset`,
draws the selection badge, wheel, list and selected-item object, then the
support gauge. Support sampling/visibility belong to
[Battle HUD](../session/battle_hud.md#child-update-and-draw-boundaries).

The badge offset is (-38,16), X reversed for side 1.
Its frame is sprite `7B`; the button is dimmed to 0.8 with fewer than
two occupied slots. `item_binding_sprite` maps:

| Binding | Sprite |
| --- | ---: |
| R1 | `76` |
| R2 | `77` |
| L1 | `74` |
| L2 | `75` |
| L1+R1 | `74` |
| L2+R2 | `75` |

Unmatched binding returns sprite -1 but the frame still draws.
`ItemSelectBadge.item_select=1` chooses action 4 (Item Select);
zero chooses action 5. The draw uses the badge's own `side`,
initialized to zero for **both** panels, so both show P1's binding.
Other writers of that side are unresolved.

The shared `battle_sprite_records` supplies sprite mode, flags, UV, size and layer.
Flag bits 0/1 become mirror flags `20/40`.
Buttons `74..77` are 32×16 cells (190,222), (190,239), (223,222),
(223,239) on layer 17; frame `7B` is 36×24 on layer 16.
Other layer-17 cells are 30×30 item icons
([item-status atlas](../../localization/ui/battle/item_status.md#substitution-doll-pickup-atlas-binding)).

`item_panel_update` first clamps offset to [-1,1] and approaches zero by
0.2, discarding accumulated excess before drawing.
It updates the list, supplies occupied-step-zero code or zero to the
selected-item object, updates support pulses, then clears event markers.
Badge scale decreases by 0.1 on an advance signal, increases by 0.1 otherwise,
and clamps to 0.8..1.0.
`item_panel_draw_item` forwards scale and opacity to sprite drawing;
`item_auxiliary_draw` renders `51..73` through a model with position and
scale but no opacity argument.

### Cached selected indicator and menu suspension

`item_selected_indicator_update` (`0x00712EC0`) stores its incoming code
at the selected-item object's `+4`. A changed nonzero code resets its age,
float factor and enabled byte. An unchanged code increments age; after 30
it reduces the factor by 1/6 and eventually disables the object. A changed
zero code stores zero without that reset. The ordinary caller is
`item_panel_update`, which supplies occupied-step-zero code or zero.

`item_selected_indicator_draw` (`0x00712F60`) reads this cached byte, not
the slot array. It also requires `hud_marker_visible`, the object's enabled
byte, a side fighter and an item manager. The wheel itself reads live slots.

`item_pickup_list_destroy` (`0x003747C0`), despite its retained name, is the
scheduled owner-update consumer. It invokes both panels' updates when its
update-flags word `+0xB8` has bit `0x02` clear and coordinator state is
0, 3 or 4. `item_manager_draw_contents` (`0x00374DF0`) draws both panels
when manager byte `+0xB0` is nonzero and draw-flags word `+0xBC` has bit
`0x02` clear. `item_pickup_list_present` (`0x00374D90`) calls that draw
and then `item_manager_reset_sprite_batch` (`0x003750F0`).

The session dispatcher gates these owner update/draw calls separately on
first/second mask bit `0x100`. An open start menu forces the first mask to
zero while leaving the second mask independently constructed. Thus a menu
can suppress selected-indicator refresh while its lower-panel draw remains
eligible. This is a static dispatch condition, not measured presentation
timing. The menu and mask owners are described in
[Pause and replay](../session/pause_and_replay.md#selective-update-gating).

### Inventory writers while the start menu is open

`battle_collect_scheduler_masks` (`0x001F0290`) forces the first/third
allowed mask to zero for manager `menu_state == 1`. It does not force the
second mask to zero. `battle_dispatch_phases` (`0x001F03E0`) retains its
second-phase and ungated work; the complete schedule and exceptions belong to
[Pause and replay](../session/pause_and_replay.md#selective-update-gating).
An open menu therefore suppresses the ordinary inventory update paths without
establishing a whole-frame stop.

The following are the inspected direct caller chains in the resident program
and `BTL.BIN`. No direct callers of these inventory mutators or their inspected
resident bridges were found in `ETC.BIN`. A direct-call census does not include
unjoined virtual calls or calculated slot stores.

| Mutation | Joined caller and scheduling boundary |
| --- | --- |
| Add or native infinite seed | `item_panel_construct` (`0x0070F740`) constructs the side image. `item_pickup_list_update` (`0x00374B30`) adds collected items under the first-mask `0x100` owner, `item_pickup_list_destroy` (`0x003747C0`). |
| Add through the resident pickup resolver | `field_item_pickup_resolve` (`0x00374190`) has a direct BTL caller in `battle_item_selection_update` at `0x008763DC`. This is the separate item-selection menu module; that call was not joined to the Practice child. |
| Consume a selected item | `item_panel_activate` (`0x00711380`) reaches `item_inventory_consume`. Its resident bridge, `item_panel_activation_bridge` (`0x00375690`), is called by `item_selected_resolve` and `item_delayed_use_commit`. The inspected input and delayed-action callers are fighter first-pass work. |
| Advance selection | `item_input_dispatch` (`0x002366F0`) calls `item_inventory_advance` (`0x003755D0`) or `item_inventory_advance_alias` (`0x00375570`). Its resident caller is the fighter logical-input first pass at `0x00248F00`. |
| Remove relative entries | `item_inventory_random_drop` (`0x00375AA0`) calls `item_panel_remove_relative`. Its direct BTL callers are `item_trap_random_drop` (`0x00757FE0`) and `item_tnd001_random_drop` (`0x00802810`), reached through their action callbacks. |
| Clear finite entries | `item_inventory_bulk_drop` (`0x00375DF0`) calls `item_panel_clear_finite`. Its direct BTL caller is the root action-selector-4 branch of `projectile_action_response` (`0x00730140`). |
| Restore codes, counts and selection | `item_cache_restore` (`0x00376050`) calls `item_cache_restore_side` (`0x00710B00`). Its resident caller is `battle_restore_reentry_values` (`0x001ECDE0`), called while constructing a replacement graph after fighters and the item manager exist. |

The coordinator-transition call from `item_pickup_list_destroy` to
`item_panel_notify_parent` (`0x00710650`) is not another finite-inventory
clear. It forwards to `top_display_children_invalidate` (`0x006BA180`),
which invalidates the top display's child state. The inspected bodies contain
no slot-code, quantity or selection write.

#### Surviving second-pass bodies

`item_pickup_list_present` (`0x00374D90`) draws the item manager, resets its
sprite batch, and presents deferred children. Its panel draw reads live slots;
it does not invoke pickup collection or `item_panel_update`.
`transient_child_second_pass` (`0x00708720`) invokes
`transient_child_draw_ribbons` (`0x00707A70`), whose inspected body draws
enabled ribbons rather than advancing the item inventory.

`transient_manager_second_pass` (`0x00734D30`) invokes enabled projectile
interface slot `0x48` with argument 1. It does not directly invoke contact
slot `0x24` or action slot `0x30`. A census of 95 resident tables annotated as
projectile vtables found 16 distinct slot-`0x48` implementations: 79 tables
use `typed_resource_submit` (`0x0072CDA0`), and the remaining 16 table rows
use 15 overrides. Their inspected bodies submit resources, owned visuals or
positioned sprites and adjust draw context; none directly calls the known
inventory writers or the drop action callbacks. This is coverage of those
annotated tables and inspected helpers, not a complete proof for every factory
product or every descendant of an owned visual.

The auxiliary second pass reaches `interaction_second_pass_dispatch`
(`0x0077E840`). It calls primary interface slot `0x128`, secondary-node
slot `0x60`, and the scaled-fighter presentation path. For `ccSkillTND001`,
primary slot `0x128` is `skill_primary_draw_callback` (`0x007956E0`): its
draw branches reach slot `0xFC`, `tnd_submit` (`0x00800F10`), rather than
action slot `0x100`, `item_tnd001_action_update`. The latter owns the drop
countdown decrement. The inspected `tnd_submit` path submits its group,
embedded player and `skill_blur_draw` (`0x00807850`), without decrementing
that countdown or calling the drop helper. Its inherited associated-actor
presentation also invokes actor slot `0x68`; all implementations of that
separate virtual slot have not been enumerated.

The ungated `interaction_stage_cutins` (`0x00778D90`) can invoke primary
slot `0xD8`. In `tnd_vtable` (`0x005EBD30`) that slot is
`dialogue_voice_produce` (`0x0076FE50`), which queues or stores a voice cue;
its inspected body does not invoke the TND001 drop update. The final helper
of `skill_primary_draw_callback`, `object_binding1_prompt_draw`
(`0x00796950`), presents a binding prompt and has no direct inventory writer.
These joins close those TND001 branches, not the other actors' virtual slots.

`interaction_second_pass_prepare` (`0x00778B00`) dispatches the constructed
offset gauge's slot `0x10`, `skill_offset_gauge_draw` (`0x00771A70`). Its
marker helper is `skill_offset_gauge_draw_markers` (`0x00771FF0`). The
inspected gauge path draws markers and has no inventory writer. The ungated
fighter-override helpers change fighter/node flag bits in
`fighter_overrides_apply` (`0x007065E0`); they do not write inventory.
The inspected final `query_process_active_pairs` (`0x001DE1C0`) publishes
collision results/corrections without invoking an item action callback.

#### Remaining pointer block

The file-backed resident `item_inventory_add_pointer_block` contains the
observed twelve words at `0x006007E0..0x0060080F`.
`item_inventory_add_function_pointer` (`0x006007F8`) is its word at
`+0x18`, containing the entry address of `item_inventory_add`
(`0x00710040`). No live interface owner, descriptor type, publication or
indirect caller was recovered for this block.

Its pattern alone does not identify an active method table. The leading
word `0x0087B908` lies in the current BTL text block. The words at `+0x14`
and `+0x1C` point to `0x00710030`, inside the epilogue of
`item_panel_remaining_capacity` (`0x0070FEF0`), and `0x0070FA40`, inside
`item_panel_construct` (`0x0070F740`). Other neighboring words likewise
target current routine interiors. The annotated block retains the exact words;
no class identity is inferred from them.

The inspected manager/panel initialization and construction bodies publish
the two panels, their three slot allocations and presentation children without
publishing this block. The inline initialization, selected-indicator
initialization and list initializer do not introduce it. This is coverage of
those bodies, not every descendant of a resource constructor.

MCP xrefs to all twelve aligned word addresses found no reader in the
resident program, `BTL.BIN` or `ETC.BIN`. Exact little-endian address
searches found seven aligned BTL words equal to `0x00600800`, an interior
block address. All seven are `ParticleGeneratorParameters` records passed
as the first argument to `battle_generator_create` (`0x00349BA0`):

| Annotated parameter record | Matching word at `+0x2C` |
| --- | --- |
| `skill_particle_parameters_8b37f0`, `0x008B37F0` | `0x008B381C` |
| `skill_particle_parameters_8b5a60`, `0x008B5A60` | `0x008B5A8C` |
| `skill_particle_parameters_8b5ad0`, `0x008B5AD0` | `0x008B5AFC` |
| `skill_particle_parameters_8b5d00`, `0x008B5D00` | `0x008B5D2C` |
| `skill_particle_parameters_8b6390`, `0x008B6390` | `0x008B63BC` |
| `skill_particle_parameters_8b6d30`, `0x008B6D30` | `0x008B6D5C` |
| `skill_particle_parameters_8b6d68`, `0x008B6D68` | `0x008B6D94` |

`generator_initialize_parameters` (`0x0034BBB0`) copies each supplied
`0x38`-byte record. Its signed halfword reads and division by 2048 establish
that these matching words are `fade_in=0x0800,fade_out=0x0060`, rather
than inventory-pointer aliases. The other exact-address matches are unaligned
instruction coincidences or resident mapped mirrors, not additional pointer
objects. The only aligned literal `0x00710040`, apart from resident mapped
mirrors, is the resident slot itself. The examined split-immediate address
formations and load candidates for the block's aligned
addresses did not establish publication. Checked literal uncached aliases for
the base, `+8`, `+0x10` and the writer slot likewise supplied no reader.

No surviving menu-time writer path was established through this block.
Its semantic origin and arbitrary calculated aliases or copied descriptors
remain unresolved; these bounded searches do not prove universal unreachability.

#### Static limit

No surviving inventory mutation was established in these joined paths. This
does **not** establish that codes, counts and selection are immutable for the
entire menu transaction. Field, support, fighter, interaction-child and cut-in
virtual descendants have not all been enumerated, and a raw-store census of
every slot alias was not performed. The remaining pointer block has the
separate bounded coverage above; it supplies no established additional caller.

## NA2 CPU item use

`ai_item_use_update` stores its target in `AiState.item_slot` and works in raw
slot indexes. Without a target it scans indexes
below the occupied count, selecting the first kind 3,4,6 that passes its
random gate with threshold 30. Its draw bound/comparison remain unrecorded,
so an exact 30% probability is not established.
The occupied-count loop can miss holes because its indexes are physical
([Battle AI](../session/battle_ai.md#direct-profile-parameter-consumers)).

With a target, relation 1 can set use mask `01000000`;
relations 2/3 set select mask `02000000`; relation zero resets the state.
The relation helper recognizes selected, one occupied step forward,
one occupied step back, and otherwise zero.

## Item cache

`battle_item_cache` contains two `ItemCacheSide`s, three two-byte
(code,count) pairs per side, total 12 bytes.
Static construction initializes the two six-byte objects; `item_cache_clear`
zeroes both sides. Neighboring cleanup node `btl_static_cleanup_node` and
source bank `result_metric_bank` are separate owners, not cache extension;
the four bytes before each are inferred alignment padding
([Overlay ABI](../../runtime/overlay_abi.md#constructor-interval),
[Battle statistics](../session/battle_statistics.md#btl-score-tier-and-point-accumulator-handoff)).

Item snapshot mask is `0x20`. Capture for a single side (1/2) first clears
both stale side records. Resident capture/restore masks use bit 1 for side 0,
bit 2 for side 1 and check each panel before dispatch.
Callers/reconstruction order belong to
[Battle lifecycle](../session/battle_lifecycle.md#values-crossing-the-reconstruction-boundary)
and [Practice](../modes/practice_mode.md#discrete-practice-controller-reset).

`item_cache_capture_side` accepts an explicit buffer; zero uses its side's
BSS record. It clears output pairs and walks physical slots in index order,
omitting kind 6 but copying all others, including empty pairs. Only kind-6
omission changes the output index. Counts narrow to a byte.
Selection and wheel offset are not retained.

`item_cache_restore_side` similarly accepts an explicit buffer or its side's
BSS record. It resets selection to zero, clears only non-kind-6 slots,
and skips pairs with zero code/count. Cached `51..73` codes normalize through
the **current** fighter's personal resolver, writing differing results
back into the cache before adding. Counts are signed bytes.
Below ID `39`, each pair independently draws from the five-code pool.
Live kind-6 slots survive and never restore from cache; add failures are
unchecked. Restoration can therefore change both the cache and inventory.
