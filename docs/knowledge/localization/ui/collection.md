# Collection UI draw-path analysis

## Research coverage

Established: retail NA2 and NUN5 Collection category titles, page controls,
HOME Play/Stop geometry, root footers, and Doll/Diorama control ownership.
Open: callers and animation phases outside the bounded screen evidence,
and NA2 animation-suffix selection outside the inspected control helpers.
Names come from `@annotations/NA2` and `@annotations/NUN5`; addresses are live.
Paired states establish the listed geometry, not every indirect caller or phase.

## Scope and binary identities

This record covers Collection -> Characters, Movie/Music titles and Play/Stop,
the four lower character-viewer controls, and Diorama controls. Evidence is
the paired retail screen states, retail records, and live-address MCP analysis.
Retail file identities, sizes and load mappings belong to
[Standard game file identities](../../game/files/file_identities.md).

Related owners are [Collection Font layouts](../font/screen_layouts/collection.md),
[NA2 and NUN5 text correspondence](../translation_importer.md), and
[Shared frontend prompt layout](options.md).

## Homologous class and draw methods

Both games use the original `ccHomeIspSelectChar` class, named
`collection_character_type_name`, with `collection_character_type_info` and
the resident `collection_character_vtable`. Its methods require ETC residence.
The captured objects have `CollectionCharacterView.state == 1` and a reusable
`page_prompt_renderer`.

`collection_character_present` first draws the character grid, using
`collection_character_grid_draw` in state 1 and
`collection_character_grid_transition_draw` in states 0, 2, 3 and 4. It then
draws exactly two page controls when the state is neither 0, 3 nor 4, and
finishes their shared renderer through `sprite_reset`. The first record is
Previous Page; the second is Next Page. This presentation path does not write
Collection selection state.

| Owner / data | NA2 live address | NUN5 live address |
| --- | --- | --- |
| `collection_character_present` | `0x006B6F20` | `0x006C9FD0` |
| `collection_character_vtable` | `0x006028B0` | `0x0060FDD0` |
| `collection_page_positions` | `0x006E2830` | `0x006EEEC0` |
| `collection_page_rectangles` | `0x006E4980` | `0x006F0760` |

The page and viewer position tables use `CollectionSpritePosition`; atlas
records use the signed-halfword fields of `FrontendRectangle`. Their exact
game values are retained below.

## Collection category-title helper

`collection_category_title_draw` selects the category position from
`collection_category_positions` in both games. NA2 selects its rectangle from
the static ETC `collection_category_rectangles`; NUN5 uses
`localized_collection_category_rectangle`, selected by `frontend_locale_index`
through `collection_category_locale_tables`. Locale 0 selects
`collection_category_rectangles_english`.

| Owner / data | NA2 live address | NUN5 live address |
| --- | --- | --- |
| `collection_category_title_draw` | `0x006C7C70` | `0x006DB450` |
| `collection_category_positions` | `0x006E2F20` | `0x006EF570` |
| Category rectangles | `collection_category_rectangles`, `0x006E4390` | `collection_category_rectangles_english`, `0x005DDAD0` |

| Category | NA2 atlas rectangle | NUN5 English atlas rectangle |
| --- | --- | --- |
| Characters | `(1,1,192,34)` | `(0,0,192,28)` |
| Movie | `(1,37,136,34)` | `(0,28,96,28)` |
| Music | `(1,83,80,37)` | `(0,56,96,28)` |

The NUN5 `home03` atlas stores the English labels in consecutive 28-pixel rows.
Paired states and the tables establish matching title positions with different
rectangle rows.

## Shared Play prompt helper

Movie and Music use `home_action_prompt_draw`: state 2 requests the button
prompt and draws Play, while state 4 requests the button prompt and draws Stop.
It finishes the optional button renderer, then the label renderer. NA2 uses
the static ETC `home_action_rectangles`; NUN5 selects
`home_action_rectangles_english` through `localized_home_action_rectangle`
and `home_action_locale_tables` for locale 0.

| Owner / data | NA2 live address | NUN5 live address |
| --- | --- | --- |
| `home_action_prompt_draw` | `0x006B44B0` | `0x006C7250` |
| Action rectangles | `home_action_rectangles`, `0x006E2690` | `home_action_rectangles_english`, `0x005DDAF0` |

Play changes from `(120,24,72,24)` to `(144,24,72,24)`, a 24-pixel U shift.
The paired Music state also establishes Stop changing from `(120,48,72,24)`
to `(144,48,76,24)`.

The native NUN5 `button_icon_submit` does not draw for the requested icon 3.
Consequently, its Play/Stop request coordinates below establish the helper's
geometry calculation, not an emitted Square sprite. Label drawing is separate.

## Collection state footer positions

The root `collection_update` owns `collection_footer_positions`, separately
from the HOME action helper. Both games use nominal Cross/Triangle positions
`(380,360)` and `(460,360)`. NUN5 adds the signed
`frontend_cross_x_offset` and `frontend_triangle_x_offset`: the captured English
values are -12 and -8, yielding X 368 and 452. NA2 makes neither addition.

| Owner / data | NA2 live address | NUN5 live address |
| --- | --- | --- |
| `collection_update` | `0x006C8290` | `0x006DBAA0` |
| `collection_footer_positions` | `0x006E2F10` | `0x006EF560` |

Root states 1, 2, 5 and 10 draw both prompts; states 6 and 9 draw Triangle
alone. Other cases in the inspected root switch draw neither of these prompts.
Child screen presentation precedes the footer in the cases that dispatch it.

## HOME action footer and localized state geometry

`home_action_prompt_geometry` has the same nominal anchors in both games,
at NA2 `0x006E26E0` and NUN5 `0x006EED70`. The helper applies the following
state-dependent geometry. Every prompt request keeps Y 360; the label delta
in the nominal geometry is `(-35,-12)`.

| State / coordinate | NA2 | NUN5 English |
| --- | --- | --- |
| 1, Cross X | `380` | `380-12=368` |
| 2, Play button request X | `380` | `380-44+56-(72/2)=356` |
| 2, Play label X | `380-35=345` | `356-35=321` |
| 3, Triangle X | `460` | `460-8=452` |
| 4, Stop button request X | `460` | `460+(76-64)/2-8=458` |
| 4, Stop label X | `460-35=425` | `458-(76/2)=420` |

NUN5 states 1 and 3 read regional offsets. State 2 instead centers with the
localized Play width, using `(x-44+56)-width/2`. State 4 uses the difference
between the localized Stop width 76 and Triangle width 64, then centers the
label by half its own width. NA2 uses static rectangles and unadjusted anchors.
The nominal table alone cannot express the distinct -12, -24 and -8 deltas.

Collection Music and Characters consume this HOME helper; the Collection root
uses its separate footer table and state renderer.

## Character viewer lower-control renderer

The four lower controls belong to `collection_doll_present`, the Doll viewer's
presentation method: NA2 `0x006BB000`, NUN5 `0x006CE190`. They are drawn only
with `CollectionDollDrawView.state == 2` and a successful readiness query on
`ready_owner`. The branch submits exactly four paired position/rectangle
records through `control_renderer`, then finishes with `sprite_reset`; it does
not change Collection selection state.

Record order is Rotate, Move, Zoom In, Zoom Out. NA2 puts all four at Y 360.
NUN5 puts Move/Rotate on the bottom row and Zoom In/Zoom Out on the top row,
as in the paired screen evidence. Its first two rectangles match NA2; the Zoom
widths increase from 108 to 112 and Zoom Out's U changes from 120 to 144.

Diorama is a separate original class, `ccHomeIspDiorama`, named
`collection_diorama_type_name`. Its `collection_diorama_vtable` resolves to
`collection_diorama_present`: NA2 `0x006BDDB0`, NUN5 `0x006D1060`. With
`CollectionDioramaDrawView.state == 2` and readiness accepted, that method
directly calls `collection_diorama_controls_draw` at NA2 `0x006BDAA0` /
NUN5 `0x006D0D10`. This helper shares `collection_viewer_rectangles` but uses
`collection_diorama_positions`. Thus the live vtables and direct calls establish
the parent edge; it is not an unresolved indirect child relationship.

`CollectionDioramaDrawView.controls_visible` gates the four control sprites.
The helper always draws Controls and then selects Hide while controls are
visible or Display while hidden. NUN5 uses
`localized_collection_viewer_prompt_rectangle` and its locale table, with the
English records at `collection_viewer_prompt_rectangles_english`; it does not
use `ANM_home_vcr_ca` for these prompts. NA2's inspected helper reads static
`collection_viewer_prompt_rectangles`. Animation-suffix selection elsewhere
remains unestablished by these routines.

## Exact paired tables

Positions below are `(x,y)` unless all four components are shown; unused Z/W
components of viewer positions are zero. Rectangles are `(u,v,width,height)`.
Names identify whole tables; indices identify their records.

| Table / entry | NA2 values | NUN5 English values |
| --- | --- | --- |
| `collection_page_positions` | `(100,360,0,0)`, `(220,360,0,0)` | `(87,360,0,0)`, `(233,360,0,0)` |
| `collection_page_rectangles` | `(1,1,118,24)`, `(1,24,118,24)` | `(1,1,144,24)`, `(1,24,144,24)` |
| Category rectangles `[0]` / Characters | `(1,1,192,34)` | `(0,0,192,28)` |
| Category rectangles `[1]` / Movie | `(1,37,136,34)` | `(0,28,96,28)` |
| Category rectangles `[2]` / Music | `(1,83,80,37)` | `(0,56,96,28)` |
| Action rectangles `[0]` / Play | `(120,24,72,24)` | `(144,24,72,24)` |
| Action rectangles `[1]` / Stop | `(120,48,72,24)` | `(144,48,76,24)` |
| `collection_viewer_positions` | `(344,360)`, `(232,360)`, `(66,360)`, `(148,360)` | `(206,364)`, `(99,364)`, `(97,339)`, `(207,339)` |
| `collection_diorama_positions` | `(440,290)`, `(440,266)`, `(469,218)`, `(468,242)` | `(440,290)`, `(440,266)`, `(440,218)`, `(440,242)` |
| `collection_viewer_rectangles` | `(1,72,108,24)`, `(1,48,108,24)`, `(1,96,108,24)`, `(120,1,108,23)` | `(1,72,108,24)`, `(1,48,108,24)`, `(1,96,112,24)`, `(144,1,112,23)` |

| Viewer table | NA2 live address | NUN5 live address |
| --- | --- | --- |
| `collection_viewer_positions` | `0x006E2A40` | `0x006EF0D0` |
| `collection_diorama_positions` | `0x006E2AD0` | `0x006EF160` |
| `collection_viewer_rectangles` | `0x006E49B0` | `0x006F0790` |

The Diorama table is one semantic position table. NUN5 keeps all four X values
at 440; NA2's Zoom In and Zoom Out use X 469 and 468.

NUN5 English viewer-state prompts are Controls `(144,72,112,24)` at `(374,309)`
and Hide `(208,96,48,24)` or Display `(132,96,76,24)` at `(414,324)`.
Controls and the visibility-dependent label are separate submissions.

The paired page-renderer observation agrees with the tables: after the second
page draw its width is 118 in NA2 and 144 in NUN5. The derived right edges are
`220+118=338` and `233+144=377`.