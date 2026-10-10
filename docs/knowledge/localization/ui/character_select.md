# Character Select UI layout

## Research coverage

Established: retail NA2 and NUN5 character-name rectangle ownership, the
separate portrait grid, footer draw order and cross-game anchor differences.
The examined binaries, callers, records and paired screen states establish
these relationships; they do not cover every animation phase or indirect
caller. Other callers and states remain open.

Names come from `@annotations/NA2` and `@annotations/NUN5`; comments there
hold per-routine details. All addresses below are live.

## Binary identity and mapping

This compares the retail Japanese NA2 boot ELF `SLPS_258.37` with the official
English NUN5 boot ELF `SLES_556.05`. The routines and tables below are resident
ELF contents. `CHARSEL1.CCS` supplies localized artwork and model data, while
character-name rectangles come from separate resident tables.

## Shared character-name rectangle table

NA2 `character_name_rectangle_copy` (`0x0037D410`) reads
`character_name_rectangles` (`0x005D4E70`), a 96-entry table of
`FrontendRectangle` records. The NUN5 counterpart with the same name
(`0x0038C350`) uses `character_name_rectangle_get_localized` (`0x003D45D0`)
and `character_name_locale_tables` (`0x005BB490`). English language index zero
selects `character_name_rectangles_english` (`0x005DDC50`). Its table length is
not established here.

NUN5 `character_portrait_rectangle_copy` (`0x0038C3A0`) instead reads
`character_portrait_rectangles` (`0x005DBFA0`), the separate uniform 38 by 46
portrait grid. This grid does not supply localized character-name rectangles.

## Character Select footer compositor

`character_select_draw` (NA2 `0x003BCDA0`, NUN5 `0x003CFA00`) draws both player
selectors before calling `character_select_draw_footer` once (NA2
`0x003BC470`, NUN5 `0x003CF0D0`). State 6 skips the presentation. Dialog or
confirmation drawing follows the footer, and both sprite contexts are reset
afterwards.

The footer draws OK, Back, Random and Select Color in that order, all at
vertical anchor 362:

| Control | NA2 horizontal anchor | NUN5 horizontal anchor | Resource owner |
| --- | ---: | --- | --- |
| OK | 400 | 400 plus the OK global adjustment | `common_prompts` |
| Back | 470 | 470 plus the Back global adjustment | `common_prompts` |
| Random | 300 | 260 | `charsel_sprites`, `character_select_random_rectangle` |
| Select Color | 160 | 100 | `charsel_sprites`, `character_select_color_rectangle` |

`charsel_sprites` and `common_prompts` are named fields of NA2
`CharacterSelectRoot` and NUN5 `CharacterSelectFooterView`. Random and Select
Color use `CHARSEL1.CCS` records; OK and Back use the separate shared prompt
compositor and resources. NUN5 adds signed global adjustments to the latter
anchors, so the nominal constants alone do not establish their effective
positions. The adjustment values and their writers are not established here.

The NUN5 prompt setup depends on its own globals and calling convention;
its setup cannot be treated as interchangeable with NA2's.

## Relationships and evidence

The complete footer routines are homologous, and the recorded anchor words
match the retail code. The annotations retain those words and their code and
data owners.

Modal text layout belongs to
[Character Select Font layouts](../font/screen_layouts/character_select.md),
the shared OK and Back compositor to
[Shared frontend prompt layout](options.md), and selection behavior to
[Character Select](../../game/character_select.md).
