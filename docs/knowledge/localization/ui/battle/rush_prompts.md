# Battle rush prompts

## Research coverage

Established: the attack-clash rush HUD's `TEX_xrush` rectangle tables in NA2
and NUN5, including the rock-paper-scissors gear labels, their record roles,
NUN5's per-locale accessor and the shared placement formulas; the five
accessor callers are all listed below. Open: nothing about the rectangles. Names come from `@annotations/NA2` and `@annotations/NUN5`;
addresses follow the
[live address conventions](../../../game/files/file_identities.md#address-conventions).

The rush is the attack-clash minigame whose art and animations come from the
stage-selected `N_RASH*.CCS` archive
([Asset dependencies](../../../game/files/asset_dependencies.md#stage-selected-edges)).
Its labels are cut from the archive's `TEX_xrush` atlas by rectangles held in
code, not in the archive, so every archive a stage can select must carry the
atlas layout those rectangles expect. NUN5's `N_RASH3` and `N_RASH5` decode to
the same `TEX_xrush` pixels as its `N_RASH`.

## Tables and drawers

| Role | NA2 | NUN5 |
| --- | --- | --- |
| Instruction line and PRESS! | `battle_auxiliary_draw_setup`, `0x002074B8` reader | `battle_rush_draw_instructions`, `0x0020E2A0` |
| Gauge dots | reader at `0x002077C4` | `battle_rush_draw_gauge_dots`, `0x0020E610` |
| Side label with win, or draw | `battle_auxiliary_draw_overlay` | `battle_rush_draw_result`, `0x0020E9A0` |
| Gear label | `battle_rush_draw_gear_label`, `0x00205F40` | `battle_rush_draw_gear_label`, `0x0020CCD0` |
| Gear centre: empty label or hand sign | `battle_rush_draw_gear_center`, `0x00206050` | `battle_rush_draw_gear_center`, `0x0020CDE0` |
| 1P, 2P or COM above a gear | `battle_rush_draw_gear_side_label`, `0x002062B0` | `battle_rush_draw_gear_side_label`, `0x0020D080` |
| Rectangles | `battle_rush_rectangles`, `0x004072E0`; gears in `battle_rush_gear_label_rectangle` (`0x00603180`), `battle_rush_gear_center_rectangles` (`0x004071B0`) and `battle_rush_gear_side_rectangles` (`0x004071E0`) | `localized_battle_rush_rectangle`, `0x003D4EE0`, over `battle_rush_locale_tables`; dots in `battle_rush_dot_rectangles`, `0x0041A710`; hand signs in `battle_rush_gear_sign_rectangles`, `0x0041A5F0` |

NA2 indexes fixed tables directly. NUN5 keeps only the two dot records
in its fixed table and asks the accessor for every label, which returns the
current locale's record from five per-locale tables; the English table is
`battle_rush_english_rectangles` at `0x005DE500`. Both games centre each label
from its rectangle width with the same formulas, so a rectangle sets both the
source region and the drawn extent.

Records are `(u, v, width, height)` in `TEX_xrush` pixels:

| NA2 record | Label | NA2 Japanese | NUN5 English (accessor id) |
| ---: | --- | --- | --- |
| 0 | Instruction line | `(19,166,236,28)` | `(0,192,256,28)` (0) |
| 1 | PRESS! | `(1,196,70,28)` | `(140,164,116,28)` (1) |
| 2 | Gauge dot | `(83,212,10,10)` | `(7,124,10,10)` (fixed) |
| 3 | Gauge dot | `(78,212,4,10)` | `(2,124,4,10)` (fixed) |
| 4 | 1P | `(55,229,36,24)` | `(0,164,40,28)` (6) |
| 5 | 2P | `(93,229,36,24)` | `(40,164,40,28)` (7) |
| 6 | COM | `(132,229,58,24)` | `(80,164,60,28)` (8) |
| 7 | win | `(190,228,66,27)` | `(72,220,104,36)` (5) |
| 8 | draw | `(156,198,99,29)` | `(176,220,80,36)` (4) |

The rock-paper-scissors gears use these:

| NA2 record | Label | NA2 Japanese | NUN5 English (accessor id) |
| --- | --- | --- | --- |
| `battle_rush_gear_label_rectangle` | Gear label | `(128,200,26,25)` | `(0,238,72,18)` (3) |
| `battle_rush_gear_center_rectangles` 0 | Empty-count label | `(101,200,25,25)` | `(0,220,72,18)` (2) |
| `battle_rush_gear_center_rectangles` 1..3 | Hand signs | `(95,77,40,40)`, `(55,62,40,54)`, `(1,62,52,54)` | the same, in `battle_rush_gear_sign_rectangles` |
| `battle_rush_gear_side_rectangles` 0..2 | 1P, 2P, COM | the same as records 4..6 | ids 6, 7, 8 through `battle_rush_gear_side_label_ids` |

**Runtime observation:** a NUN5 savestate during a rush result draws the win
label from `(72,220,104,36)`, and an NA2-code savestate with NUN5's archive
draws it from `(190,228,66,27)`, cutting fragments of neighbouring labels.
