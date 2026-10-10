# Battle Command List and move chart

## Research coverage

Established: retail NA2 binding icons, Command List rows, move-chart filtering,
command-token derivation, texture selection and the native labels below.
Open: complete chart sequences for every named action and the rear-direction
label's relation to every object-relative selector; no visible result was captured.
Evidence is static code and data; displayed rows do not establish executability.
Names come from `@annotations/NA2`; addresses are live.

This document owns battle Command List and character move-chart presentation.
[Action commands](../../../gameplay/combat/action_commands.md) owns bindings,
logical input, action records and selection.
[Battle UI selectors and prompts](selectors_and_prompts.md#command-menu-and-command-chart-scroll-indicators)
owns the shared scroll indicators. Address conventions follow
[Retail game file identities](../../../game/files/file_identities.md#address-conventions).

## Binding presentation readers

Battle input tests each configured binding as a full 16-bit mask
([Action commands](../../../gameplay/combat/action_commands.md#native-masks-and-bindings)).
Presentation readers use narrower mappings:

| Reader | Mapping |
| --- | --- |
| resident `binding_prompt_index` (`0x0020CE10`) | one binding to a prompt index for the eight face and shoulder masks; missing bindings or any other value returns `0x1E` |
| resident `options_controls_initialize` (`0x00387950`) | Options Controls row reconstruction using the eight masks in `control_editor_masks` (`0x005D5230`) |
| BTL `object_binding1_prompt_draw` (`0x00796950`), `attachment_binding1_prompt_draw` (`0x007FDD00`), `for_submit` (`0x00804D40`) | binding 1's glyph through `hud_glyph_get` (`0x006B4110`) |
| BTL `hud_support_draw` (`0x0071CAF0`) | binding 5's glyph through `hud_glyph_get` |
| BTL `command_list_build` (`0x00877FB0`) | face and shoulder icons; see [Command List rows](#command-list-rows) |
| BTL `move_chart_convert_bindings` (`0x008793A0`) | face-button icons; see [Binding icons](#binding-icons-and-direction-tokens) |

## Command List rows

`command_list_build` converts the side's eight configured bindings:

| Binding mask | Control | Icon token |
| ---: | --- | ---: |
| `0x20` | Circle | 4 |
| `0x10` | Triangle | 5 |
| `0x80` | Square | 6 |
| `0x40` | Cross | 7 |
| `0x04` | L1 | 9 |
| `0x08` | R1 | 10 |
| `0x01` | L2 | 11 |
| `0x02` | R2 | 12 |

Any other mask, including zero, leaves its converted token unassigned.
The builder fills 18 `CommandListRow`s from `command_list_table`
(`0x008D1550`) and sets `CommandList.row_count` to 18. Each
`CommandListEntry` supplies a name and up to five tokens, terminated by `-1`.
Tokens 0..25 copy directly; binding placeholders resolve as follows:

| Table token | Binding index | Default control |
| ---: | ---: | --- |
| 27 | 1 | Circle |
| 28 | 2 | Cross |
| 29 | 3 | Square |
| 30 | 4 | L1 |
| 31 | 6 | L2 |
| 32 | 5 | R1 |

For bindings 3 and 6, L2 expands to L2 + R2 and L1 to L1 + R1.
These expansions use textual plus token 24; ordinary sprite plus is token 8.
The guard row and substitution row's button both use placeholder 31.

`command_list_draw` (`0x00878860`) selects the token presentation:

| Tokens | Content | Source |
| --- | --- | --- |
| 0..3 | d-pad directions | layer 0, `TEX_xcommand` |
| 4..8 | face buttons and plus | layer 0, `TEX_xcommand` |
| 9..12 | shoulder buttons | layer 1, `TEX_xcommand02` |
| 13..25 | input-condition text | `command_list_texts` (`0x008BD510`) |

The sprite records are `command_icon_rectangles` (`0x008D14C0`). Shoulder
record widths advance the next token. The renderer draws
`CommandList.visible_rows` from `scroll`, wraps at `row_count`, and passes
the scroll position and row count to the scroll bar. Per-row `token_count`
is the number of tokens drawn.

Native input-condition wording, with ruby omitted:

| Token | Annotated string | Native label | Meaning |
| ---: | --- | --- | --- |
| 13 | `command_help_while_jumping` (`0x008BD230`) | （ジャンプ中） | while jumping |
| 15 | `command_help_rear_direction` (`0x008BD280`) | 後側方向キー | rear-direction key |
| 16 | `command_help_substitution` (`0x008BD2B0`) | （相手の攻撃の当たる瞬間） | at the instant the opponent's attack hits |
| 20 | `command_help_hold` (`0x008BD400`) | （しばらく押す） | hold for a while |
| 21 | `command_help_grounded` (`0x008BD420`) | （地上で） | on the ground |
| 23 | `command_help_linked_attack` (`0x008BD4B0`) | （マニュアル：出現後もう一度押すと攻撃） | in manual mode, press again after appearance to attack |

Row 8's `command_list_substitution_name` (`0x008BD620`),
「変わり身の術（チャクラ消費）」, includes the chakra-consumption suffix.
The input-condition wording does not establish that the rear-direction label
matches every object-relative direction selector in the input interpreter.

## Character move chart

The move chart derives rows from the fighter's current action arrays rather
than the two static `ccCommand` sequences.

### Row construction

`move_chart_build_rows` (`0x008794B0`) scans `Fighter.action_count` and resolves
each index through `fighter_action_record` (`0x00217930`) and
`fighter_chart_action_record` (`0x00217990`), using `actions` and
`initial_actions`. The verified signed count is at fighter `+0xA38`, and the
array pointers are at `+0xA54` and `+0xA58`; MCP's applied `Fighter` view
currently disagrees with the saved declaration, so those offsets qualify the
field names here.

A zero `ActionRecord.category` or any category bit in `0xF002` omits the row.
Nonempty `display_name`s become visible names; empty names accumulate command
tokens for later named continuation entries. `ActionRecord.display_prefix`
controls prefix handling. This is a presentation scan, separate from the
action-state validator.

`MoveChartView.rows` contains `MoveChartRow`s:

| Field | Display use |
| --- | --- |
| `name` | action-name pointer |
| `condition_index`, `category_index` | condition/category text indices |
| `tokens` | ten command-icon slots |
| `last_token_index` | renderer draws this value plus one tokens |

### Binding icons and direction tokens

`move_chart_convert_bindings` reads the first four configured bindings through
resident `bindings_get` (`0x001F3F10`) into `MoveChartView.binding_tokens`.
Masks `0x10/0x20/0x40/0x80` (Triangle/Circle/Cross/Square) become tokens
`5/4/7/6`. Any other mask becomes token 0, the up d-pad. A configured binding
change therefore changes the chart's button icon.

For ordinary records, `ActionRecord.signature` supplies the first applicable
direction in this priority order:

| Signature condition | Token |
| --- | --- |
| bit `0x200` | 0 |
| bit `0x400` | 1 |
| any bit in `0x5000` | 2 for side 0, 3 for the other side |
| any bit in `0xA000` | the opposite side-dependent token |

A direction is followed by separator token 8. Signature family `0x00100000`
appends binding 1's icon; otherwise `0x01000000` appends binding 2's icon.
In the rapid-press/charge branch, category bit `0x4` takes priority over
`0x10`. Either appends another binding-1 icon and selects its label, with
airborne variants when signature bit 4 is set. The chart interprets record
fields for presentation; its tokens are not a literal dump of the
hold/release sequencer's logical bits.

`move_chart_draw` (`0x0087A740`) uses layer 0, `TEX_xcommand`, and
`command_icon_rectangles` for every token. Tokens below 4 use the row's icon
line; the rest draw 4 units lower. Shoulder tokens 9..12 would therefore
sample d-pad texels in that layer.

### Category text

`command_chart_relationship_strings` (`0x008BD1D0`) supplies the category
labels. Relevant native labels, with ruby omitted:

| Index | Annotated string | Native label | Meaning |
| ---: | --- | --- | --- |
| 9 | `command_chart_rapid_press` (`0x008BCF90`) | 連打技 | rapid-press technique |
| 10 | `command_chart_charge_qualifier` (`0x008BCFB0`) | 溜め技 | charge technique |
| 11 | `command_chart_air_rapid_press` (`0x008BCFD0`) | 空中連打技 | airborne rapid-press technique |
| 12 | `command_chart_air_charge` (`0x008BD000`) | 空中溜め技 | airborne charge technique |

The related `command_list_draw` uses the input-condition wording listed under
[Command List rows](#command-list-rows).
