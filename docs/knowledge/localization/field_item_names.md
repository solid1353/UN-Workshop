# Field-item names

## Research coverage

Established: the 22 resident field-item names, their index lookup and state
mirror, and the corresponding official NUN5 English names in table order.
Open: retail NA2/NUN5 names for code `29` and user-facing names for `02`/`03`;
the latter have internal BTL identifiers only. Other item-name sources remain open.
Names come from `@annotations/NA2` and `@annotations/NUN5`.
The code `29` identification is user-supplied; its English name is external.

Selection and weighting belong to
[Battle item inventory](../gameplay/projectiles_and_items/battle_item_inventory.md),
effects to
[Battle items and status effects](../gameplay/projectiles_and_items/battle_items_and_status_effects.md),
and presentation to [Battle item-status presentation](ui/battle/item_status.md).

## Address conventions

The retail NA2 executable and official NUN5 `PRG/TEXTENG.BIN` are identified
in [Retail game file identities](../game/files/file_identities.md).
All addresses below are live; the annotation comments own layout and mapping
details. External-bank loading belongs to
[External localization payloads](external_string_payload.md).

## Resident field-item name table

NA2 `profile_small_ids` (`SLPS_258.37`, `0x005B03F0`) contains 22
`FieldItemNameRow` records. Each associates `item_code` with a Shift-JIS
`name`; the source names below omit reading markup. The first and last titles
are `field_item_scroll_of_teleportation_title` and
`field_item_medical_pack_title`.

`profile_small_table_index` (`0x00373830`) resolves a code to its row index
or `-1`. The same row identity joins the names to saved per-item state:
`profile_small_table_to_byte_bank` (`0x0038E6E0`) and
`profile_byte_bank_to_small_table` (`0x0038E780`) mirror the mapped counts
between `SaveProfile.small_availability` and
`SaveProfile.secondary.byte_bank2`. Their saved-state contract belongs to
[Save-data lifecycle](../game/save_data.md#secondary-block-and-opaque-tail).

The official NUN5 English bank has the corresponding 22 titles in the same
order, from `field_item_scroll_of_teleportation_title` (`TEXTENG.BIN`,
`0x009052B0`) to `field_item_medical_pack_title` (`0x00905488`). This establishes
the English names for these NA2 rows, without establishing NUN5 numeric item
codes, naming absent NA2 codes, or proving every item source uses this table.

| NA2 code | Retail NA2 source name | Official NUN5 English name |
| ---: | --- | --- |
| `09` | `瞬身の巻物` | Scroll of Teleportation |
| `0E` | `アイテムポーチ` | Item Pouch |
| `23` | `風魔手裏剣` | Demon Wind Shuriken |
| `24` | `根性のおもり` | Weight of Determination |
| `25` | `起爆クナイ` | Exploding Kunai |
| `26` | `毒煙玉` | Poison Smoke Bomb |
| `27` | `撒き菱` | Makibishi Spikes |
| `28` | `起爆札` | Paper Bomb |
| `2A` | `呪札　鎧崩し` | Curse Tag: Armor Break |
| `2B` | `千影手裏剣` | 1000-Shadow Shuriken |
| `2C` | `炸裂クナイ` | Burst Kunai |
| `2E` | `起爆シール` | Exploding Seal |
| `2F` | `蝦蟇油` | Toad Oil |
| `30` | `博打玉` | Random Ball |
| `31` | `痺れ玉` | Stun Ball |
| `06` | `上忍の靴` | Shoes of Jonin |
| `07` | `兵糧丸` | Food Pills |
| `08` | `雲隠れの巻物` | Scroll of Hidden Cloud |
| `0A` | `カカシ人形` | Scarecrow |
| `0B` | `亀甲丸` | Tortoiseshell Pills |
| `0C` | `元気丸` | Energy Pills |
| `0D` | `医療パック` | Medical Pack |

The selector can also produce codes `02`, `03`, and `29`, which are absent
from this name table. BTL identifies the first two internally as
`ItemRecoverLife` (`item_recover_life_class_name`, `0x00898B60`) and
`ItemChakraBall` (`item_chakra_ball_class_name`, `0x00898B40`); no retail NA2 or official NUN5
user-facing name was established for code `29` from the binaries.

## Code `29`: Curse Tag: Chakra Points Seal

The user identified NA2 item `0x29` as the Chakra Seal Tag.
[Rampidzier's Ultimate Ninja 2 guide](https://gamefaqs.gamespot.com/ps2/921262-naruto-ultimate-ninja-2/faqs/48890)
lists **Curse Tag: Chakra Points Seal** and describes temporarily preventing
the struck opponent from using chakra. This provides the PS2-series English
name; the association with NA2 code `29` comes from the user's identification,
not from an NA2 or NUN5 name-table entry.

No corresponding item name was recovered from NUN5 `TEXTENG.BIN`.
**Curse Tag: Chakra Points Seal** remains an externally sourced UN2 name;
the negative-search evidence is retained in the NUN5 title-run annotation.

Pool membership and weighting are owned by
[Random field-item selection](../gameplay/projectiles_and_items/battle_item_inventory.md#random-field-item-selection).
