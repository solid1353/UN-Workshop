# Menu input runtime behavior

Native NA2 and NUN5 menu-input handler relationships and Save/Load control
flow.

## Research coverage

Established: retail regional button masks, the shared selectable-modal family,
Save/Load parent and child ownership, three-row rendering/navigation and
confirmation statuses, from static regional comparisons and recorded modal
and Save/Load observations. Open: each regional Save/Load handler's independent
necessity; combined-path observations do not isolate the participating handlers.

Routine, field and data names come from `@annotations/NA2` and
`@annotations/NUN5`; annotation comments hold per-routine details. Addresses
below are live NA2 resident addresses.

## Save/Load controller

`save_ui_draw_slots` (`0x001E6370`) draws three record rows and independently
scans all three for occupancy. `save_ui_select_slot` (`0x001E69B0`) owns
selection and navigation: Down and Up wrap `SaveDialogUi.selected_slot`
over 0..2, reset `selected_x_offset` to zero and play sound `0x35`.

`save_ui_initialize` (`0x001E57B0`) constructs the upper frame. Date and
play-time placement belongs to the row renderer; the independent cursor model
is resolved through `save_slot_cursor_model_name` (`0x00404998`, `MDL_xkun1`).
Frame, row text and cursor presentation have separate owners from occupancy,
save data and save execution, whose contracts are owned by
[Save-data record format and lifecycle](../../game/save_data.md).

In `save_dialog_controller` (`0x001E3F20`), Save-mode status `0x0C` is the
no-save-data confirmation. No returns through panel closure to the initial
save prompt. Status `0x2C` is a separate repair confirmation. Both status
`0x0B` and `0x0C` accept Circle (`0x20`), but their gates are independent:
`0x0B` uses `save_ui_acknowledge_choice` (`0x001E6FB0`), while `0x0C` tests
the mask in the parent controller.

[`function_map.tsv`](function_map.tsv) is the reusable NA2/NUN5 handler
inventory and regional button-mask comparison. Its row notes bound the
handler-specific findings and recorded observations; it complements this
overview's Save/Load ownership relationships.
