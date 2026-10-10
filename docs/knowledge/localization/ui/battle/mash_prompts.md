# Battle Mash prompts

## Research coverage

Established: the NA2 and NUN5 main-label selection paths, shared observed
object layout, complete seven-record tables, Mash rectangle difference, and
separation from controller glyphs. Only main prompt ID zero was directly
observed; the other six correspond by table and accessor structure, with their
on-screen identities still open. Names come from `@annotations/NA2` and
`@annotations/NUN5`; addresses follow the
[live address conventions](../../../game/files/file_identities.md#address-conventions).

This document owns main-label localization. Supplemental glyph rendering and
Mash gameplay behavior are outside its scope.

## Objects and address map

The previously observed paired objects, heap instances seen at `0x00E4F3D0`
and `0x00E4F950` in NA2 and at `0x00DCE550` and `0x00DCEAD0` in NUN5, have the
same `0x580`-byte stride. Their player side, main `label`, and
supplemental `commands` are named in NA2's `BattlePromptDisplay` (an alias of
`BattleRootGauge`) and NUN5's `BattlePromptDisplayView`. These are observed
instance addresses, not fixed object locations. Main label `0` means Mash;
supplemental ID `0x0C` selects Cross independently of that main label.

| Role | NA2 | NUN5 |
| --- | --- | --- |
| Main-label renderer | `battle_prompt_draw_main_label`, BTL `0x006B6480` | `battle_prompt_draw_main_label`, BTL `0x006C94A0` |
| Complete main-prompt rectangle table | `battle_main_prompt_rectangles`, BTL `0x0088F630` | `battle_main_prompt_english_rectangles`, resident ELF `0x005DE4B0` |
| Regional accessor | Direct BTL table selection | `localized_battle_main_prompt_rectangle`, resident ELF `0x003D4E40` |
| Adjacent controller-glyph table | `battle_controller_glyph_rectangles`, BTL `0x0088F670` | Separate from the regional main-prompt table |

NUN5's main-label renderer uses `localized_battle_main_prompt_rectangle` for
IDs below seven. The accessor selects `battle_main_prompt_locale_tables` by
the current locale and returns the requested rectangle. Higher IDs use
`battle_static_prompt_rectangles` in BTL. NA2 directly indexes its Japanese
BTL table. Both renderers use the selected rectangle's width and height for
placement and the scaled echo; changing a rectangle therefore changes the
label's displayed extent as well as its source region.

Both complete tables contain seven contiguous eight-byte
`BattlePromptRectangle` records, totaling 56 bytes. Values below are
`(u, v, width, height)`; only ID zero has an established on-screen identity.

| ID | NA2 Japanese | NUN5 official English |
| ---: | --- | --- |
| 0 (Mash) | `(0,24,48,24)` | `(0,84,64,20)` |
| 1 | `(48,0,48,24)` | `(64,64,64,20)` |
| 2 | `(0,0,48,24)` | `(0,64,64,20)` |
| 3 | `(48,24,64,24)` | `(0,104,64,20)` |
| 4 | `(0,72,94,24)` | `(0,32,128,32)` |
| 5 | `(0,48,112,24)` | `(0,0,128,32)` |
| 6 | `(0,96,48,24)` | `(64,84,64,20)` |

## Adjacent controller-glyph table

NA2's `battle_controller_glyph_rectangles` is a separate controller-glyph
table after `battle_main_prompt_rectangles`. Its inspected 56-byte span
contains seven 24-by-24 glyph rectangles; that span does not establish the
complete glyph inventory. The main-label renderer selects
`battle_main_prompt_rectangles`, so the adjacent glyph table cannot supply
alternate localized main labels.
