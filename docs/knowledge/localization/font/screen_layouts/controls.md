# Controls Font layouts

Retail NA2 (`SLPS-25837`) and UN5 1P/2P Commands relationship layout.

## Research coverage

Established: relationship composition, wrapping widths and cross-game row
geometry. Open: other strings and animation phases, and Pause Controls and
Special Controls layouts. Names come from `@annotations/NA2` and
`@annotations/UN5`; their comments hold code-level detail. Addresses are live.

Secondary-font metrics belong to [Renderer metrics](../renderer_metrics.md);
Command Chart and 1P/2P Commands tokens belong to
[Battle Command Chart and 1P/2P Commands](../../ui/battle/command_chart_and_commands.md).

## 1P/2P Commands relationship rows

UN5 `move_chart_draw` (`0x00896EB0`) is the structural counterpart of NA2
`move_chart_draw` (`0x0087A740`). A nonzero `MoveChartRow.condition_index`
enables the relationship; `category_index` adds its qualifier only inside that
gate. UN5 resolves both through `localized_chart_relationship`
(`0x003D16C0`) and composes them before drawing one paragraph. A long
relationship therefore wraps jointly into a two-line block. NA2 draws the
condition and optional category separately at the same row Y.

UN5 `panel_draw_wrapped_text` (`0x00393ED0`) subtracts the composed caller X
from the requested right edge before wrapping. The panel's own X origin is
added to visible placement, but is not subtracted again from wrapping width.
`move_chart_text_x_offsets` (`0x008C1A34`) supplies the two local X values:

| UN5 text | Local X | Container X | Panel X | Visible X | Right edge | Wrapping width |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Title | 4 | 16 | 8 | 28 | 308 | `308 - (16 + 4) = 288` |
| Relationship | 20 | 16 | 8 | 44 | 308 | `308 - (16 + 20) = 272` |

The relationship request uses height `32`, line limit `2`, style `9`, left
horizontal alignment and centered vertical alignment. Its icon placement is
independent of the paragraph's wrapped line count:

| Game | Relationship below title | Base icon line below relationship |
| --- | ---: | ---: |
| NA2 | 30 | 20 |
| UN5 | 17 | 40 |

Tokens below 4 use the base icon line; other tokens draw 4 units lower.
Thus the three previously observed single-line rows have repeatable vertical
differences between games, while UN5 also leaves space for a jointly wrapped
relationship without moving its icons for each additional line.

Previously recorded observations at UN5 `font_wrap_words` (`0x0018C4F0`)
confirmed widths `288` and `272` with tracking `0`, horizontal and vertical
scales `1`, and descriptor address `0x00B592D0`. They cover only the recorded
states, not every string or animation phase. MCP rejects that descriptor
address as outside program memory, so its observed role remains unannotated;
no static descriptor contents are established here.
