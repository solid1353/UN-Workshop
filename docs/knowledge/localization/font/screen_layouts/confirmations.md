# Confirmation Font layouts

## Research coverage

Established: retail NA2 (`SLPS-25837`) and NUN5 confirmation owners,
geometry, fragment/paragraph drawing, choices, closing, and message boundaries.
The supplied NUN5 create-data confirmation has observed coverage; other
documented states have static coverage. Open: other callers, strings and
animation phases. Names come from `@annotations/NA2` and `@annotations/NUN5`;
per-routine details are in their comments. All addresses below are live.

Glyph metrics belong to [Renderer metrics](../renderer_metrics.md);
memory-card text and storage belong to
[NA2 and NUN5 text correspondence](../../translation_importer.md#memory-card-failure-messages).

## Battle quit-confirmation callers

NA2 `start_menu_yes_no_draw` (`0x00877F20`, BTL) draws two distinct
widgets: `StartMenuYesNo.window` holds the Yes/No list and
`StartMenuYesNo.body_panel` holds the prompt. The former uses
`modal_draw_choices` (`0x00383600`), the latter `panel_draw_body`
(`0x003825B0`). Each content draw requires its panel to be open; the panel
draw still advances its animation.

`modal_initialize_yes_no` (`0x00382DD0`) uses `modal_yes_no_layout`.
Its `ModalChoiceState.x/y` are `50/24`, with `row_extra = 12`;
the native 20-unit line advance puts the second row at Y `56`.
The NUN5 measurements map Yes to `(64.5,31.5)` and No to `(68.5,49)`.

## Mode Select Return to Title confirmation caller

`mode_select_present` (`0x00385C00`) draws the prompt through
`ModeSelectInput.prompt_panel`. `prompt_choices` has an empty list while
the prompt is visible, so it does not own the visible body.

`panel_draw_body` builds a `UiTextDrawRecord` at local X/Y `24/16`
from `panel_body_x/y`, with the supplied text and indexed color.
`ui_draw_text_record` (`0x00379A20`) performs the native text draw.

## Collection exit-confirmation body and choice list

`collection_exit_confirmation_draw` (`0x006C6520`, ETC) owns the ordinary
exit modal. `CollectionExitConfirmationView.body_panel` uses
`panel_draw_body`; `choice_panel` uses the complete `modal_draw_choices`
list. Both content draws require an open panel.

`collection_update` (`0x006C8290`) repeats that same body/list arrangement
in its exit-confirmation render state. The body and choices remain separate
owners in both paths.

## NA2 memory-card message body

`save_ui_initialize` (`0x001E57B0`) constructs the lower message panel at
`(18,235)` with size `476x130`. `panel_get_inner_extent`
(`0x00382110`) subtracts twice the signed `UiPanel.border_x/border_y`
from `width/height`.

`save_ui_draw` (`0x001E5BA0`) dispatches
`save_ui_draw_text_lines` (`0x001E6060`) with four fragments.
The body requires a resting `SaveDialogUi.lower_panel`,
`text_enabled`, and non-null `text`. `save_body_draw_record` supplies
local X/Y `22/18` and indexed color `15`.

Each adjacent NUL-terminated fragment is drawn through
`panel_draw_text_record` (`0x003821D0`), followed by a Y advance of
`30`. This path does not wrap paragraphs. The panel wrapper retains
visibility and bounds checks before passing its `text_draw_object` and
`text_context` to `ui_draw_text_record`. Choice handling follows separately.

`save_ui_next` (`0x001E5DC0`) places Next at the panel's inner height
minus `12`, independently of the body loop. `save_dialog_initial_choice`
(`0x001E70B0`) and `save_dialog_return_to_title_choice` (`0x001E7130`)
draw their fixed Save/Return-to-title questions through
`save_question_draw_record` and `return_to_title_draw_record`,
outside the fragment loop.

### Panel closing

`save_dialog_controller` (`0x001E3F20`) states `8`, `9`, and `10`
wait for `save_ui_close_panels` (`0x001E5C30`). The helper requests
`menu_transition_close` (`0x00381930`) with duration `8` for each
visible open panel and waits for `menu_transition_closed` (`0x00381FC0`)
before clearing `SaveDialogUi.visible/slots_visible`.

Closing sets `UiPanel.state = 2` and `cursor/duration = 8`.
`save_ui_draw` continues `panel_draw` (`0x00380B60`) for each visible
panel during the close; drawing owns the animation progress.

State `9` then resets the worker through `save_worker_request_stop`
(`0x001E1D20`), starts the optional outer transition through
`save_dialog_start_outer_transition` (`0x001E5730`), and advances to
state `11`. State `11` returns `1` when that transition finishes,
or immediately if `SaveDialogController.outer_transition_enabled` is zero.
State `8` returns `2` in Load mode or reinitializes the Save question
in Save mode.

### Message boundaries

`save_ui_draw_slots` (`0x001E6370`) uses the date record for an empty
slot: `save_empty_slot_label_pointer` supplies its label,
`save_empty_time_string` clears time text, and the label uses the row's
Y plus `18`. It does not derive a centered position from panel bounds.

The selected row adds `SaveDialogUi.selected_x_offset` to X before shadow
and foreground drawing. Each draw moves that offset one third of the remaining
distance toward `-24`, snapping when the step is smaller than one unit.
All-empty Load suppresses selected-row movement; Save retains it for the
selected empty row.

`save_status_text_get` (`0x001E34D0`) selects a pointer from the
48-entry `save_status_messages` table; `save_ui_refresh_text`
(`0x001E5B20`) publishes it in `SaveDialogUi.text`. A message can
contain multiple adjacent NUL fragments.

| NA2 message | Status or use | Boundary |
| --- | --- | --- |
| `card_create_data_prompt` | `0x0C` | Absent-data statement and create-data question in one state; `card_create_data_question_fragment` is its continuation |
| `card_startup_absent_prompt` | Startup | Six fragments |
| `card_insufficient_space_startup` | Startup | Six fragments |
| `card_wrong_type_message` | `0x07` | Distinct wrong-card-type warning |
| `card_load_failed` | `0x14` | Distinct ordinary load failure |
| `card_save_failed` | `0x19` | Distinct save failure |

The startup path `startup_card_check_draw` (`0x001E74E0`) dispatches
`startup_card_check_draw_fragments` (`0x001E7530`) with count `7`
for statuses `0x24..0x27`. It draws `StartupCardCheck.message` from
`(50,100)` with Y advance `30`, without the lower panel. Choices use
Y `316`, selected foreground `314`. Six-fragment startup strings
therefore do not establish a lower-panel truncation bug.

`save_confirm_operation` (`0x001E3120`) advances acknowledged
unformatted-card notice `0x0A` to format question `0x0B` and
insufficient-space warning `0x08` to required-space explanation `0x09`.
Status `0x0C` already combines its statement and question.
NUN5 combines some of the separate notices into one paragraph, so message
counts alone do not identify lost text.

`save_yes_draw_record` and `save_no_draw_record` use local Y `80`
in the lower panel; the startup renderer replaces that Y before drawing.
The fixed Save/Return questions use their own records and direct body draws.

### NUN5 memory-card paragraph

NUN5 `save_ui_refresh_text` (`0x001EB950`) publishes the selected
message in `SaveDialogUi.text`. `save_ui_draw` (`0x001EB9D0`)
dispatches `save_ui_draw_paragraph` (`0x001EBEE0`), which draws the
complete NUL-terminated message through `panel_draw_paragraph`
(`0x003937D0`) with a five-line limit and height `85`.
Its `save_body_draw_record` has origin `0/0` and indexed color `15`.
Yes/No is dispatched separately through `panel_draw_yes_no`
(`0x00392920`).

The supplied create-data confirmation has lower panel `(8,230,496,144)`,
border widths `8/8`, and `UiPanel.text_inset_x/text_inset_y = 16/12`.
Paragraph width is panel width minus `16` and twice the horizontal inset,
giving `448` here. `ui_draw_paragraph` (`0x00387E80`) and
`ui_draw_paragraph_current_context` (`0x00387EC0`) copy the message,
process line breaks, wrap it, and adjust wrapping when the line limit is
exceeded before the final bounded draw.

`font_draw_aligned_block` (`0x0018B1B0`) receives alignment `0/0`
for the body: left/top. `font_fit_block_height` (`0x0018CAE0`) measures
the complete block and reduces vertical scale only when it exceeds the
supplied height; short paragraphs keep their native advance.

Yes/No forms one styled string with `choice_space_separator`: five ordinary
spaces between the labels. `panel_draw_aligned_text` (`0x00392A90`),
`ui_draw_aligned_text` (`0x00387BD0`), and
`ui_draw_aligned_text_current_context` (`0x00387C10`) forward
alignment `2/2`: horizontal center and vertical bottom.

The choice rectangle is panel size minus `16` and twice the corresponding
text inset: `448x104`, starting at `(16,12)` in the supplied state.
With 20-unit text height, its choice origin is Y `96`; the text insets
remain part of the placement. Selected-label shadow/color markup does not
change the group alignment.

`memory_card_message_get` (`0x003D3800`) selects the English 48-entry
`memory_card_messages` bank. Status `0x0C` points to `card_create_data_prompt`
(`0x0091D3A0`, TEXTENG), containing both the absent-data statement and
create-data question. The supplied wrapped copy retains both, and the
screenshot shows four body lines above Yes/No. This establishes that state
and the shared mechanism; it does not establish every error or transition.
