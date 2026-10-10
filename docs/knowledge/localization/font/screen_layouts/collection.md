# Collection Font layouts

## Research coverage

Established: retail NA2 (`SLPS-25837`) and NUN5 Collection list geometry,
fixed row cadence, selected-name string distinction, and Diorama title
placement. Open: callers, strings, states and animation phases outside the
bounded evidence. Names come from `@annotations/NA2` and `@annotations/NUN5`;
their comments carry code-level details, and cited addresses are live.

Glyph metrics belong to [Renderer metrics](../renderer_metrics.md); graphics
and prompts to [Collection UI draw-path analysis](../../ui/collection.md);
string ownership to
[NA2 and NUN5 text correspondence](../../translation_importer.md).

## Collection fixed-cadence list wrapping

NUN5 `collection_list_draw` (`0x006C7CA0`) takes the active box from
`CollectionListLayoutView.box_width` and `box_height`:

| List | Box width | Box height |
| --- | ---: | ---: |
| Movie titles | 192 | 32 |
| Moves | 152 | 32 |
| Relationships | 192 | 32 |

Every family uses native X, native Y minus 10, two lines and a 16-unit line
interval. The outer list retains a fixed 35-unit row cadence; wrapped titles
occupy two lines inside their existing row rather than increasing later row
positions. Exact visible breaks include:

- `Sealing Jutsu: Nine` / `Phantom Dragons`;
- `People of Endless` / `Darkness`;
- `Ninja Art: Beast` / `Scroll Replicas`;
- `Fourth Awakened` / `Mode`;
- `Shadow Clone` / `Jutsu`;
- `Unchanging` / `Relationship`.

## Structural Collection-family completion

Collection uses these relevant list families:

- ordinary characters: Figure, Ultimate Jutsu, and character-specific Music;
- legacy characters: Ultimate Jutsu only;
- Diorama;
- Movie;
- global Music;
- the Characters index where applicable.

Raw NUN5 ETC records are not byte-compatible with NA2: homologous list records
assign different field meanings and positions to resources. Only their
classification and layout semantics correspond.

## Collection Characters selected-name boxed positioning

NUN5 `collection_character_name_get` (`0x006D96B0`) first remaps the selected
record before resolving its localized name. `collection_granny_chiyo_remap_row`
stores character ID `24` and localized row `62` in
`CollectionCharacterRemapRecord`. English row `62`, named
`collection_granny_chiyo_localized_name`, has two distinct strings:

| `LocalizedCharacterNameRecord` field | String | Annotation name |
| --- | --- | --- |
| `primary_title` | `Granny Chiyo` | `granny_chiyo_unpadded_title` |
| `collection_title` | `Granny Chiyo ` (terminal space) | `collection_granny_chiyo_title` |

The caller returns `collection_title`. NA2's
`collection_granny_chiyo_name_pointer` selects the shared Japanese
`collection_granny_chiyo_source`; the three separately annotated
`collection_granny_chiyo_shared_pointer_a`,
`collection_granny_chiyo_shared_pointer_b` and
`collection_granny_chiyo_shared_pointer_c` references belong to different
record families. The isolated plaque pointer establishes that
the terminal-space distinction belongs to the Characters selected-name call
rather than to every reference to the shared string.

## Collection Figures Diorama boxed titles

The twelve Diorama presentations are covered by `collection_diorama_present`
in NA2 (`0x006BDDB0`) and NUN5 (`0x006D1060`). The title follows the controls
and requires `CollectionDioramaDrawView.state == 2`, readiness from
`ready_owner`, and `title_record.title_enabled`.

`CollectionPlaqueView` names the title record's origin and selected string.
NA2 passes `x` and `y` plus native half-extents to `ui_draw_centered_text`
(`0x00379240`), which centers at that point. NUN5 instead passes `x`,
`y + 4.0`, doubled half-extents, a two-line limit and `title` to
`ui_draw_boxed_text` (`0x0038A4F0`).

NUN5's `collection_diorama_title_half_width` is `95.0` and
`collection_diorama_title_half_height` is `16.0`. The wrapper receives
the exact `190` by `32` title box after doubling them.
