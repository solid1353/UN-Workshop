# Stage Select UI

## Research coverage

Established: retail NA2/NUN5 record layouts, TV-preview and carousel equivalence,
localized name selection, draw ordering and bottom prompt anchors. Open:
uncovered animation phases and indirect callers, and the carousel draw
parameter's visual effect. Names come from `@annotations/NA2` and
`@annotations/NUN5`; addresses are live.

NA2 choices and screen behavior belong to
[Native Stage Select](../../game/stage_select.md), stage loading to
[Stages](../../gameplay/stages/stages.md), and the shared OK and Back compositor
to [Shared frontend prompt layout](options.md).

## Binary identity and address mapping

The comparison uses the retail NA2 and NUN5 `BTL.BIN` programs and NUN5's
resident `SLES_556.05`. Input identities and address conventions belong to
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
Current MCP code and data verify the owners below; the earlier paired memory
and screen observations cover only the examined states. Annotation comments
hold signatures and per-routine code detail.

## Stage records

Both games have 24 rows in `stage_select_records`. NA2's sixteen-byte
`StageSelectRecord` adds `name_rectangle` to the logical ID and preview index
([Native Stage Select](../../game/stage_select.md#stage-records)). NUN5's
eight-byte `Nun5StageRecord` contains only `stage_id` (the logical ID) and
`preview_index`; localized name rectangles are selected separately.

`stage_select_build_tv_objects` is structurally equivalent in both games,
apart from the record stride. Both use the preview index to place TV images
in the same 96×72 grid.

| BTL owner | NA2 live address | NUN5 live address |
| --- | --- | --- |
| `stage_select_records` | `0x008C3B10` | `0x008DC380` |
| `stage_select_build_tv_objects` | `0x007141C0` | `0x00729BC0` |

## Localized stage names

`stage_select_selected_stage_draw` places the stage name at `(380,298)` in
both games. NA2 uses the matched record's `name_rectangle` at scale 1. NUN5
uses resident `localized_stage_name_rectangle` (`0x003D4120`), which selects
the row from `stage_name_rectangle_tables` for the current locale. Its
horizontal scale is `min(1, 214 / rectangle.width)`; vertical scale stays 1.

The carousel transform and seven-entry draw in `stage_select_carousel_draw`
are structurally equivalent apart from relocated engine calls. Selection,
browsing displacement and Random phase affect ring placement in the same way.

| BTL routine | NA2 live entry | NUN5 live entry |
| --- | --- | --- |
| `stage_select_carousel_draw` | `0x00714D40` | `0x0072A7A0` |
| `stage_select_selected_stage_draw` | `0x007151D0` | `0x0072AC30` |

## Bottom prompt placement

NA2 `stage_select_close` (`0x00715CC0`, the inherited name of the drawing
routine) and NUN5 `stage_select_draw` (`0x0072B7B0`) draw settings in state 4
and suppress ordinary drawing in state 7. Otherwise they submit camera and
ring animations, then the carousel, selected-stage title/name/counters and
arrows, followed by the legends and bottom prompts.

Both pass nominal OK X=400 and Back X=470 at Y=356. NUN5 adds the signed
regional offsets before submission; the examined English values give:

| Prompt | NA2 X | NUN5 adjustment | Effective NUN5 X |
| --- | ---: | ---: | ---: |
| OK | 400 | -12 | 388 |
| Back | 470 | -8 | 462 |
