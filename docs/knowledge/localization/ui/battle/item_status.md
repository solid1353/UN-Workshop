# Battle item-status presentation

## Research coverage

Established: retail NA2 and NUN5 status classes, record selection,
foreground geometry, bubble width, rank offsets, the doll atlas binding, and
18 checked English status-record crops with their atlas bindings.
Names come from `@annotations/NA2` and `@annotations/NUN5`; addresses are live.
Evidence covers paired native paths, records, and recorded object states.
Open: indirect callers and states outside those examined, including other animation phases.
Annotations carry per-routine code detail and fixed object layouts.

Binary identities and addresses follow
[Retail game file identities](../../../game/files/file_identities.md).
Item selection, pickup, and inventory belong to
[Battle item inventory](../../../gameplay/projectiles_and_items/battle_item_inventory.md);
effects and timing to
[Battle items and status effects](../../../gameplay/projectiles_and_items/battle_items_and_status_effects.md);
names to [Field-item names](../../field_item_names.md).

## Status record words

The checked English words below are decoded retail NUN5 `BATTLEGAUGE.CCS`
crops at the rectangles selected by `battle_sprite_records`
(`0x005B7ED0`). NA2's corresponding table is `0x005B0A60`.
The paired, numeric and single maps below establish the shared logical
record selection; corresponding IDs do not imply equal rectangle geometry.

NA2 `item_sprite_texture_names_initialize` (`0x005D92F0`) fills
`item_sprite_binding_records` (`0x005AFF20`).
`item_manager_initialize_sprite_batch` (`0x00374F80`) binds those
texture names through `battle_sprite_bind_resource_context` and
`sprite_bind_named_container_texture` (`0x001CD8C0`).
The relevant bindings are layers `0/3` to `TEX_xselect2`,
`1/4` to `TEX_xselect5`, and `2/5` to `TEX_xselect`.
The selected side chooses one member of each pair.

| Logical record | Checked English crop | Atlas / base layer |
| --- | --- | --- |
| `81` | Health | `TEX_xselect2`, layer `0` |
| `82` | Chakra | `TEX_xselect2`, layer `0` |
| `8D` | Recovery | `TEX_xselect`, layer `2` |
| `8E` | Status Effect | `TEX_xselect2`, layer `0` |
| `8F` | Attack Power | `TEX_xselect2`, layer `0` |
| `90` | Defense Power | `TEX_xselect2`, layer `0` |
| `91` | Speed | `TEX_xselect2`, layer `0` |
| `92` | Up | `TEX_xselect5`, layer `1` |
| `93` | Down | `TEX_xselect5`, layer `1` |
| `94` | Max | `TEX_xselect5`, layer `1` |
| `95` | Decrease | `TEX_xselect5`, layer `1` |
| `96` | Ultimate Mode! | `TEX_xselect5`, layer `1` |
| `97` | POI | `TEX_xselect`, layer `2` |
| `98` | Invisible | `TEX_xselect2`, layer `0` |
| `99` | Sleep | `TEX_xselect2`, layer `0` |
| `9A` | Substitution Jutsu | `TEX_xselect2`, layer `0` |
| `9B` | Seal | `TEX_xselect2`, layer `0` |
| `9C` | Jump Power | `TEX_xselect2`, layer `0` |

Record `97`'s rectangle reads only `POI`. The Poison identity comes
from the separate named-item and gameplay join, rather than a complete
Poison word in that crop. Record `96` reads Ultimate Mode!; the single
notification map selects it for notification `12`. That establishes a
notification phrase, not a gameplay effect-ID join.

[Status identity and naming coverage](../../../gameplay/projectiles_and_items/battle_items_and_status_effects.md#status-identity-and-naming-coverage)
owns those joins and their naming limits.

## Paired item-status labels

### Identity and address map

| Role | NA2 | NUN5 |
| --- | --- | --- |
| Notification factory | `fukidasi_create` (`0x0070D5F0`) | `fukidasi_create` (`0x00722640`) |
| Pair constructor | `fukidasi_pair_construct` (`0x0070EBF0`) | `fukidasi_pair_construct` (`0x00724010`) |
| Shared presentation | `fukidasi_present` (`0x0070DDA0`) | `fukidasi_present` (`0x00722E10`) |
| Pair foreground | `fukidasi_pair_draw` (`0x0070ECC0`) | `fukidasi_pair_draw` (`0x007240F0`) |
| Bubble draw | `fukidasi_bubble_draw` (`0x0070DFB0`) | `fukidasi_bubble_draw` (`0x007230F0`) |
| Width update | Shared presentation | `fukidasi_pair_width_update` (`0x00724820`) |
| Rank offsets | `fukidasi_rank_offsets` (`0x00898B90`) | `fukidasi_rank_offsets` (`0x008B4570`) |
| Pair map | `fukidasi_paired_records` (`0x00898C00`) | `fukidasi_paired_records` (`0x008B45E0`) |

The pair maps agree. Their ninth row supplies the fixed class's records:

| Object code | First record | Second record |
| ---: | ---: | ---: |
| `0x05` | `0x8F` | `0x92` |
| `0x06` | `0x90` | `0x92` |
| `0x0E` | `0x90` | `0x93` |
| `0x08` | `0x91` | `0x92` |
| `0x07` | `0x91` | `0x93` |
| `0x0F` | `0x82` | `0x9B` |
| `0x10` | `0x82` | `0x94` |
| `0x11` | `0x9C` | `0x92` |
| `0x04` | `0x8E` | `0x8D` |

Records `0x8E..0x94` and `0x9B..0x9C` occupy the corresponding portions of
each game's `battle_sprite_records`. A shared logical map does not imply
identical atlas geometry.

### Reconstructed behavior

The factory assigns a rank offset at insertion, signing X by the
side-to-opponent orientation. The table has three entries:

| Rank | NA2 offset | NUN5 offset |
| ---: | --- | --- |
| 1 | `(50,-20)` | `(20,-30)` |
| 2 | `(-16,-62)` | `(-64,-63)` |
| 3 | `(30,-104)` | `(0,-96)` |

Shared presentation projects the followed position, adds the rank offset,
clamps it to the screen, and smooths it against the previous display position.
It draws the bubble at that position and admits foreground drawing only when
`Fukidasi.bubble_scale > 0.3`. Relative to that position, the foreground
origin is `(-33,-42)` in NA2 and `(0,-33)` in NUN5.

NUN5 updates `Fukidasi.width_scale` before clamping. The paired class uses the
greater live record width, divided by 64 when above 64, otherwise 1. Bubble
drawing receives this scale separately from the animated `bubble_scale`;
foreground records draw at scale 1. NUN5's bubble rotation is `1.57`;
NA2's is zero.

Foreground offsets are relative to the class foreground origin:

| Row | NA2 | NUN5 |
| --- | --- | --- |
| First | `(+38,+11)` | X centered by half the live record width; Y `+18` |
| Second | `(+18,+30)` | X centered by half the live record width; Y `+20` |

NUN5's first record `0x82` or `0x99` moves Y another `-14` and rotates by
pi/2. Its second record `0x9B` moves Y another `+14` with zero rotation;
other second records rotate by `1.57`. Width halving rounds signed integers
toward zero. Both games select the side's layer and use the notification's opacity.

### Shared foreground renderer difference

| Role | NA2 boot ELF | NUN5 boot ELF |
| --- | --- | --- |
| Top-left record renderer | `item_sprite_draw_top_left` (`0x00377060`) | `item_sprite_draw_top_left_rotated` (`0x00384100`) |
| Uniform sprite wrapper | `item_sprite_draw` (`0x00377720`) | `item_sprite_draw` (`0x00384800`) |

The top-left renderers copy a selected record into the reusable layer sprite,
scale both dimensions uniformly, add half the source dimensions to the supplied
position, and center the local offsets using the supplied scale:
`local_x = -scale * source_width / 2` and
`local_y = -scale * source_height / 2`. Opacity is independent of scale.
NUN5 additionally accepts rotation; NA2's cited top-left renderer sets it to
zero. The uniform sprite wrappers provide a distinct path with a directly
supplied position and rotation.

### Evidence and limits

The paired-class mapping and geometry are verified by the native paths,
records, and recorded object states. Other classes have different constructors
and geometry. The observations do not cover every animation phase or indirect caller.

## Numeric item-status labels and recovery values

### Identity and address map

| Role | NA2 | NUN5 |
| --- | --- | --- |
| Numeric constructor | `fukidasi_construct` (`0x0070E090`) | `fukidasi_numeric_construct` (`0x007231E0`) |
| Numeric foreground | `fukidasi_numeric_draw` (`0x0070E190`) | `fukidasi_numeric_draw` (`0x007232F0`) |
| Top localized label | `fukidasi_numeric_top_draw` (`0x0070E200`) | `fukidasi_numeric_top_draw` (`0x00723360`) |
| Lower Recovery label | `fukidasi_numeric_lower_draw` (`0x0070E350`) | `fukidasi_numeric_lower_draw` (`0x00723570`) |
| Numeric value | `fukidasi_numeric_digits_draw` (`0x0070E660`) | `fukidasi_numeric_digits_draw` (`0x00723930`) |
| Numeric map | `fukidasi_numeric_records` (`0x00898BB0`) | `fukidasi_numeric_records` (`0x008B4590`) |

The map selects Health record `0x81` for object code 1 and Chakra record
`0x82` for codes 2 and `0x14`. The ordinary lower label is Recovery `0x8D`;
code `0x14` selects `0x95` instead.

### Reconstructed behavior

Foreground drawing orders the top label, lower label, then digits. NA2 passes
top offsets `(36,11)` and lower offsets `(16,37)`. NUN5 passes `(22,20)` and
`(37,37)`, but its lower-label method ignores the forwarded X offset.

NUN5 centers the top record by half its live width before adding caller offsets.
Top records `0x82` and `0x99` then subtract 14 from X and Y and rotate by pi/2;
others use zero rotation. The lower record is centered by its own width.
Recovery uses Y `+37` and zero rotation; code `0x14` uses Y `+37-24` and
rotation `1.57`. NA2 uses caller offsets directly without these width-centering
or rotation adjustments.

NUN5's digit X origin is `-50`. It adds `14/23/32`, `18/28`, or `24` for
three, two, or one digit, giving `-36/-27/-18`, `-32/-22`, and `-26`.
NA2 uses the same additions without the `-50` origin. Both use Y `+25` and
draw digits after the labels.

### Evidence and limits

These paths own record selection and presentation geometry. They do not own
gameplay recovery arithmetic, effect timing, allocation, links, or atlas content.
The object layouts and renderer interfaces differ: `Fukidasi.next` occupies
NA2's `+0x40`, while NUN5 has `width_scale` there and `next` at `+0x44`.
The numeric value and digit animation are named in `FukidasiNumeric`.
Native paths, retail record bytes, and recorded numeric objects establish the comparison.

## Single item-status labels

### Identity and address map

| Role | NA2 | NUN5 |
| --- | --- | --- |
| Single constructor | `fukidasi_single_construct` (`0x0070E9C0`) | `fukidasi_single_construct` (`0x00723CC0`) |
| Single foreground | `fukidasi_single_draw` (`0x0070EA90`) | `fukidasi_single_draw` (`0x00723DA0`) |
| Width update | Shared `fukidasi_present` | `fukidasi_single_width_update` (`0x00723F30`) |
| Object-code map | `fukidasi_single_records` (`0x00898BD0`) | `fukidasi_single_records` (`0x008B45B0`) |
| Single-class vtable | `fukidasi_single_vtable` (`0x005DDEC0`) | `fukidasi_single_vtable` (`0x005EB3D0`) |

The five mappings are byte-identical:

| Object code | Item record |
| ---: | ---: |
| `0x09` | `0x9A` |
| `0x0C` | `0x98` |
| `0x0D` | `0x99` |
| `0x13` | `0x97` |
| `0x12` | `0x96` |

These records occupy `0x96..0x9A` in each game's `battle_sprite_records`.

### Reconstructed behavior

Relative to the supplied foreground origin, NA2 adds `(33,42)` and NUN5
adds `(0,33)`. NUN5 uses a quarter-turn for records `0x82` and `0x99`, zero
for others; of the five mapped records, only `0x99` takes that branch.
NA2 uses zero rotation. Each class draws through its game's `item_sprite_draw`
uniform wrapper at scale 1 with the notification's opacity.

NUN5 derives bubble width from the mapped live record: width at most 64
gives `width_scale = 1`; otherwise it gives `width / 64`. Retail object code
`0x09` therefore uses `122/64 = 1.90625`; the other mapped codes use 1.
NA2's corresponding object field is its next-object link.

### Evidence and limits

The verified differences concern records, foreground origin, bubble width,
and record-specific rotation. These paths do not own effect selection, duration,
gameplay status, damage, allocation, links, or resource identity. The comparison
includes both native functions, identical maps, retail records, and recorded
class-vtable and object inventories.

## Substitution-doll pickup atlas binding

### Identity and address map

| Role | NA2 boot ELF | NUN5 boot ELF |
| --- | --- | --- |
| Record table | `battle_sprite_records` (`0x005B0A60`) | `battle_sprite_records` (`0x005B7ED0`) |
| Doll record `0x0A` | `battle_sprite_record_substitution_doll` (`0x005B0AD8`) | `battle_sprite_record_substitution_doll` (`0x005B7F48`) |
| Record renderer | `item_sprite_draw_top_left` | `item_sprite_draw_top_left_rotated` |
| Resource owner | `battle_active_object` (`0x00376610`) | `battle_active_object` (`0x00383470`) |
| Layer sprite lookup | `battle_sprite_for_layer` (`0x00375180`) | `battle_sprite_for_layer` (`0x00381FB0`) |
| Submission | `scene_output_finalize` (`0x001CC350`) | `scene_output_finalize` (`0x001D1480`) |
| Atlas name | `battle_item_atlas_name` (`0x005AFEC0`) | `battle_item_atlas_name` (`0x005B76F0`) |

Each record is a 12-byte `ItemBattleSpriteRecord`. The renderer selects by
logical ID and copies U, V, width, and height into the sprite before centering
and submission.

### Reconstructed behavior

Both recorded live objects retain logical code `0x0A` at sprite `+0x0C`;
the field width is not established here. Both use `TEX_xselect`, 30 by 30
source dimensions, and sprite flags `0xC127FFFF`. Their anchors differ by
three pixels at the observed animation phase.

| Record `0x0A` | U | V | Width | Height |
| --- | ---: | ---: | ---: | ---: |
| NA2 | 161 | 193 | 30 | 30 |
| NUN5 | 161 | 225 | 30 | 30 |

The recorded NA2 sprite initially had geometry matching record `0x2E`;
its next updater pass replaced it from retained code `0x0A`. Thus the
same-index NUN5 record supplies the homologous doll geometry. Other semantic
record IDs are not globally aligned. Record bytes and matched object states
establish this correspondence; dynamic sprite addresses and initial geometry
are retained in the record annotations.

## Fixed two-label item status

### Identity and address map

| Role | NA2 | NUN5 |
| --- | --- | --- |
| Fixed constructor | `fukidasi_fixed_construct` (`0x0070EF20`) | `fukidasi_fixed_construct` (`0x007244D0`) |
| Fixed foreground | `fukidasi_fixed_draw` (`0x0070EFF0`) | `fukidasi_fixed_draw` (`0x007245B0`) |
| Fixed width update | Absent from NA2's class interface | `fukidasi_fixed_width_update` (`0x007247F0`) |
| Fixed-class vtable | `fukidasi_fixed_vtable` (`0x005DDE80`) | `fukidasi_fixed_vtable` (`0x005EB370`) |

The class always draws `0x8E` then `0x8D`. NUN5 uses the same records as
its paired and numeric classes, with no separate texture or table.

### Reconstructed behavior

NA2 uses `(+38,+11)` for `0x8E` and `(+18,+25)` for `0x8D`. NUN5 obtains
each live width, halves it with signed integer rounding toward zero, subtracts
it from X, then adds 20 or 37 to Y. Both foreground draws use scale 1 and zero
rotation with the notification's opacity.

NUN5's fixed bubble method writes `width_scale = 1.6`. Record `0x8E` is
102 pixels wide, whose width divided by 64 is `1.59375`; that ratio is
distinct from the method's fixed value. Width querying belongs to foreground
centering; the paired class has its own dynamic width method. As in the other
classes, NA2 has its next-object pointer where NUN5 has the width scale.
