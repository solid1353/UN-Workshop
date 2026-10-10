# Shared Font style

## Research coverage

Established: retail NA2 (`SLPS-25837`) has six primitives combining the
selected text's gray shade, offset foreground pass and text renderer across
`SLPS_258.37`, `ADV.BIN`, `BTL.BIN` and `ETC.BIN`. All six are resident ELF
routines. Open: their complete caller coverage and states outside the
documented gates. Names come from `@annotations/NA2`; addresses are live.

This document owns the cross-screen selected-style behavior. Selected-row
displacement and glyph metrics belong to
[Renderer metrics](../renderer_metrics.md); raster and palette findings belong
to [Font assets](../assets.md).

## Global selected-style default

Selected text is drawn first in gray `0xFF808080` at its supplied origin,
then in foreground color at X minus `1.0`, Y minus `2.0`. The foreground is
normally red `0xFF0000D4`; the caller-colored primitive supplies its own
foreground, and an empty selected save slot uses `0xFF2828D4`. These offsets
are independent of glyph metrics and any caller-applied row displacement.

| Routine | Live address | Role and gate |
| --- | --- | --- |
| `ui_draw_selected_text` | `0x00379040` | State-aware central primitive: nonzero selection draws both passes; zero draws black once at the supplied origin. |
| `ui_draw_selected_text_color` | `0x00379150` | Caller-colored central primitive: always draws both passes. |
| `modal_draw_yes_no` | `0x00379C30` | Fixed two-choice primitive: selection 0 or 1 draws the selected choice twice and the other once; -1 draws both black once. |
| `save_ui_draw_text_lines` | `0x001E6060` | Shared two-record choice list: selection styling requires a resting lower panel and `SaveDialogUi.choice_enabled`. |
| `save_ui_draw_slots` | `0x001E6370` | Three text records per save/load slot: selection styling requires an open upper panel and the selected row, and is suppressed for an all-empty Load list. |
| `save_ui_yes_no` | `0x001E6CE0` | Shared Save/Load, overwrite and return-to-title Yes/No component: selection styling requires a resting lower panel. |

The ordinary unselected color is black `0xFF000000`; empty unselected save
slots use `0xFF505050`. A selected save/load slot draws all three records in
gray before drawing all three displaced foreground records. The fixed
two-choice primitive draws both base choices before the selected foreground;
the two shared lower-panel choice components draw the selected gray pass
before the two foreground choices.

This is the bounded set of routines combining these colors, offsets and text
rendering in the four covered retail programs. It does not enumerate their
callers or establish that every selected element on every screen uses them.
Per-routine signatures, constants and gates are retained in the annotations.
