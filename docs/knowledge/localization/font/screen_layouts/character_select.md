# Character Select Font layouts

## Research coverage

Established: retail NA2 (`SLPS-25837`) and NUN5 five-row Character Select
assignment-dialog owners, row coordinates and selected/ordinary routing.
Recorded Menus suite evidence covers the five-row player-mode list; other
callers, strings and animation phases remain open. Routine names come from
`@annotations/NA2` and `@annotations/NUN5`; their comments hold code details
and signature limitations. Addresses are live.

Secondary-font metrics and the selected-row offset belong to
[Renderer metrics](../renderer_metrics.md); Character Select name records
and footer geometry belong to
[Character Select UI layout](../../ui/character_select.md).

## Character Select modal selected row, return body, and choice list

The recorded Menus suite evidence established the shared row-family
behavior within this list. The resident assignment-dialog owners are
`character_select_draw_assignment_dialog` in NA2 (`0x003BC780`) and NUN5
(`0x003CF3F0`). Their native local Y coordinates differ:

| Row | NA2 Y | NUN5 Y |
| ---: | ---: | ---: |
| 0 | 8 | 0 |
| 1 | 32 | 24 |
| 2 | 56 | 48 |
| 3 | 80 | 72 |
| 4 | 120 | 106 |

These are caller coordinates before the text helpers apply their layout;
they do not establish final glyph positions for every string or animation
phase.

## Character Select ordinary-row metrics

NA2 draws the selected entry through `panel_draw_text_row` (`0x00382610`)
and every ordinary entry through `panel_draw_text_positioned`
(`0x00382470`). NUN5 routes both states through
`panel_draw_selected_boxed_text` (`0x00393210`), passing whether the row is
selected. The NA2 selected/ordinary split and NUN5 shared route are therefore
separate layout contracts; the bounded five-row evidence does not establish
ordinary-row behavior in other modal lists.
