# UN3 and UN4 item inventories

## Research coverage

Established: UN3's field-item codes and their NA2 equivalents, five-slot
panel, cache, compacting removal and scrolling HUD; UN4's five-slot layout, placement, fading and item-select badges.
UN3 evidence is static with one corroborating screenshot; UN4 layout keys
were observed in one battle state, with formulas confirmed in retail code.
Names come from `@annotations/UN3` and `@annotations/UN4`; addresses are live.
Open: nothing.

This document records the battle-item inventories of retail UN3 and UN4.
Retail NA2 (`SLPS-25837`) uses the three-slot inventory recorded in
[Battle item inventory](battle_item_inventory.md). File identities and overlay
bases belong to [Retail game file identities](../../game/files/file_identities.md#address-conventions).

## UN3 field-item codes

UN3's item codes differ from NA2's. `item_catalog_rows` (`0x004D7440`) names
each inventory code; `item_metadata` (`0x00490930`) gives codes 1..3 life and
6..8 chakra of 5, 10 and 15, code 9 chakra 0.75, and code `0x1B` the kind,
flags and effect of NA2's Curse Tag: Chakra Points Seal (`29`). Matching names
give the NA2 codes:

| UN3 | NA2 | UN3 | NA2 | UN3 | NA2 |
| ---: | ---: | ---: | ---: | ---: | ---: |
| `0A` | `23` | `19` | `27` | `0C` | `06` |
| `0B` | `24` | `1A` | `28` | `0D` | `07` |
| `0F` | `09` | `1B` | `29` | `0E` | `08` |
| `17` | `25` | `1C` | `2A` | `10` | `0A` |
| `18` | `26` | `1E` | `2B` | `20` | `0B` |
| `2C` | `2C` | `2E` | `2E` | `21` | `0C` |
| `2F` | `2F` | `33` | `30` | | |

NA2 has no Curse Tag: Steal (`1D`), Frog Pill (`1F`) or Kunai Rain (`30`).
UN3's `field_item_random_select` (`0x0030FE80`) works as NA2's, with fallback
code 9 and its own pools: pool 1 is NA2's pool 1 with Frog Pill and without
Medical Pack and Item Pouch; pool 3 holds chakra codes 6..8.

## UN3 five-slot inventory

UN3's manager-and-panel structure is homologous to retail NA2's, with
different field layouts. `item_manager_init` (`0x00291120`, resident ELF)
creates one panel for each side through `item_panel_construct`
(`0x008294C0`, BATTLE.BIN). `un3ItemManager.panels` retains the two panels;
each panel has five fixed slot objects. Their layouts are named in
`un3ItemManager`, `un3ItemPanel` and `un3ItemSlot`.

`item_panel_init` (`0x00829560`) initializes the selected index and occupied
count to zero, stores the side and positions the panel from side-specific
base data plus a shared offset. Each slot has an occupied flag, fixed index,
item code and count. Its initial `list_position` is `index * 32 + 16`;
`animated_position` and both animation-state fields start at zero. The
panel's `scroll` starts at 16.

`item_cache_build` (`0x0082A740`) and `item_cache_restore`
(`0x0082A870`) operate on five `un3ItemCacheEntry` records per side.
`item_inventory_cache` (`0x00946050`) is their default runtime destination.
Each record stores an item code and a byte count; the side stride is
`0x28`. The imported file image has animation strings at this destination,
so those bytes do not show the cache's initial runtime contents.

`item_remove_selected` (`0x0082AD10`) removes the selected item, compacts
the remaining occupied items and decrements `occupied_count`. Removing the
last selected item returns selection to zero. `item_move_slot_range`
(`0x0082B210`) moves a contiguous range and restarts its slide animation.
Slot identity stays fixed while item payloads move.

The HUD is a scrolling list. `item_wheel_draw` (`0x0082B560`) derives a
list index from `scroll / 32` and uses `item_wheel_count_dispatch`
(`0x0093B270`) for occupied counts 0..5. The contract is:

| Occupied count | Item draws | Empty frame positions |
| ---: | ---: | --- |
| 0 | 0 | -2, -1, 1, 2 |
| 1 | 5 | -2, -1, 1, 2 |
| 2 | 5 | -2, -1, 2 |
| 3 | 5 | -2, 2 |
| 4 | 5 | -2 |
| 5 | 5 | none |

The five item draws are issued by `item_slot_draw` (`0x0082B900`) at
selectors -2..2. Empty frames use opacity 0.6. `item_frame_draw`
(`0x0082B810`) positions frames at side layout points and selects their
scale from `item_frame_scales`. `item_step_offset` (`0x0082B9D0`) gives
horizontal displacements 0, 35.2 and `28.8 + 35.2 = 64.0` for absolute
steps 0, 1 and 2, negated on the negative side.

`item_draw` (`0x0082BB60`) adds the step displacement, interpolates the
height between layout points and applies the panel position. Each side has
seven `un3ItemLayoutPoint` records. Their `x` fields are the interpolation
keys, but all are zero in the imported file image.
`item_visible_ranges` (`0x00919950`) supplies the
occupied-count-dependent fading boundaries.

| Data | Live address | Values at relative positions -3..3 |
| --- | --- | --- |
| `item_layout_side0` heights | `0x00919850` | -25, -25, -9, 0, 8, 7, 7 |
| `item_layout_side1` heights | `0x009198C0` | 7, 7, 8, 0, -9, -25, -50 |
| `item_frame_scales` | `0x00919930` | 0.6, 0.8, 1.0, 1.2, 1.0, 0.8, 0.6 |

One retail UN3 battle screenshot corroborates the list shape: P1's left
neighbors rise and its right neighbors stay level, P2 is mirrored, and the
two item-select badges sit below the wheel on either side.

## UN4 item wheel

UN4 retains the five-slot structure, with layouts named in
`un4ItemPanel`, `un4ItemSlot`, `un4ItemBadge` and `un4ItemLayoutPoint`.
The following layout keys were observed in one retail UN4
(`SLUS-21862`) battle state; the imported file image has zero `x` keys.

| Data | Live address | Values |
| --- | --- | --- |
| `item_layout_side0` (`x, y`) | `0x0083C810` | (-85,-25) (-60,-25) (-42,-9) (0,0) (43,8) (70,7) (100,7) |
| `item_layout_side1` (`x, y`) | `0x0083C880` | (-100,7) (-70,7) (-43,8) (0,0) (42,-9) (60,-25) (85,-50) |
| `item_frame_scales`, positions -3..3 | `0x0083C8F0` | 0.6, 0.8, 1.0, 1.2, 1.0, 0.8, 0.6 |
| `item_visible_ranges`, rows 2..5 | `0x0083C930` (row 2) | (-35,-10,35,60) (-60,-35,35,60) (-65,-40,47,75) (-75,-45,47,75) |
| `item_wheel_bases` (`x, y`) | `0x0083C970` | (10,340), (367.2,340) |
| `item_wheel_shared_offset` (x component) | `0x0083C990` | 67.4 |
| `item_count_offsets` (`x, y`) | `0x0083C9E0` | (0,27), (0,27) |
| `item_first_badge_offsets` (`x, y`) | `0x0083C9A0` | (-60,30), (-50,30) |
| `item_second_badge_offsets` (`x, y`) | `0x0083C9C0` | (50,30), (60,30) |

`item_panel_init` (`0x006EE960`) adds `item_wheel_shared_offset` to each
side's base to form `position`. A battle screenshot places the centers near
`x = 77` and `435` in the 512-unit HUD space, matching this construction.
`item_frame_draw` (`0x006F0C80`) draws frames at the layout points with
the position-indexed scales. `item_slot_draw` (`0x006F0D70`) issues five
item draws at selectors -2..2.

`item_step_offset` (`0x006F0E40`) returns signed offsets 0, 35.2 and
`28.8 + 35.2 = 64` for steps 0, 1 and 2. `item_draw`
(`0x006F0FD0`) adds the step offset to the slot's horizontal displacement;
`item_layout_bracket` (`0x006F0F20`) selects the neighboring records for
height interpolation.

With `d = |x|`, item scale is `1.2 - 0.6 * d / 96`. Opacity is 1 inside
the inner boundary, 0 beyond the outer boundary, and
`1 - (d - inner) / (outer - inner)` between them. Negative `x` uses the
first two range-row values as absolute outer and inner boundaries; positive
`x` uses the last two as inner and outer. Five items therefore use negative
boundaries 45..75 and positive boundaries 47..75, making distance-64 items
partially transparent even at rest. `item_unusable_marker_draw`
(`0x006F27A0`) receives `0.8 * opacity`, while `item_sprite_draw`
(`0x006F2770`) receives full opacity.

The visible ranges place the extra item on the positive-`x` side when the
count is even. By user observation, Item Select in UN4 and retail UN5
moves P1's selection to the item on the left. **Inference:** the positive-`x`
side therefore holds earlier items in selection order.

`item_panel_init` builds two badge objects from the side-indexed offsets.
Each is one button sprite with no separate frame. A battle screenshot
identifies the first as L2 on the left and the second as R2 on the right for
both players. `item_panel_draw` (`0x006F08B0`) draws both through
`item_badge_draw` (`0x006F2630`) and resident `sprite_draw_uniform`
(`0x003AC890`). Badge opacity is 0.2 while `occupied_count < 2` and 1.0
otherwise; scale comes from `un4ItemBadge.press_scale`.
