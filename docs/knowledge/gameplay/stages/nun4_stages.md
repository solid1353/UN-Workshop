# NUN4 battle stages

## Research coverage

Established: stage identity, S01 camera/anchors/routes, authored scene formats,
resource/scene allocation bounds, conditional load sufficiency,
group-0 parallel-animation correspondence,
decoded soundtrack comparison and localized previews.
Open: indirect consumers, full prop equivalence, minimum available load-time capacity,
musical title, alternate arrangements and the clash-camera selector's meaning.
Names and types come from `@annotations/NUN4`; NA2 comparison names come from
`@annotations/NA2`.

This document owns retail NUN4 (`SLUS-21862`) battle-stage facts and its
correspondence with retail NA2 (`SLPS-25837`). The NA2 contracts belong to
[Battle stages](stages.md), [Battle camera](../session/battle_camera.md), and
[Native Stage Select](../../game/stage_select.md).

## Evidence and address convention

Inputs and live addresses follow
[Retail file identities](../../game/files/file_identities.md#address-conventions).
NUN4 evidence uses MCP programs `SLUS_218.62` and `BATTLE.BIN`, and the English
`@source/NUN4.iso.files/DATA/DATAE.CVM.files/DATAE.CVM.iso.files/` extraction.
`DATAF.CVM` contains the French resources. Code addresses below are live;
the battle overlay has header base `0x006B8200`.

The direct logical-ID call census covers 16 resident and 11 battle-overlay
`jal` instructions; the resident's two mirrored address regions are excluded
from those counts. This does not cover every computed call or unidentified
owner alias.

## Archive set and CCS format

The English `STAGE/` directory holds `S01.CCS` through `S18.CCS`, plus
`KTYS_BNT`, `KTYS_KTY`, `KTYS_MND`, `KTYS_SKK`, `KTYS_SKK2`, `KTYS_SKR`,
`KTYS_STR`, and `KTYS_TYO`. All 26 are gzip CCS streams with version `0x123`.
Their section walks consume the complete decompressed bytes; all contain
tag 5 and finish with the `0xCCCCFF01` section. Header container names are
the lowercase archive stems. `KTYS_SKK2` exists on disc but is absent from
the 25-entry stage path table.

| Archive | Compressed bytes | Decompressed bytes | Archive | Compressed bytes | Decompressed bytes |
| --- | ---: | ---: | --- | ---: | ---: |
| S01 | 610,339 | 1,406,876 | S10 | 702,071 | 1,406,332 |
| S02 | 586,083 | 1,247,932 | S11 | 645,553 | 1,127,300 |
| S03 | 455,763 | 1,246,296 | S12 | 452,419 | 869,272 |
| S04 | 476,313 | 1,353,172 | S13 | 410,574 | 1,165,636 |
| S05 | 717,670 | 1,401,360 | S14 | 534,999 | 1,132,864 |
| S06 | 541,051 | 990,596 | S15 | 602,552 | 1,397,620 |
| S07 | 561,282 | 1,166,952 | S16 | 411,516 | 964,188 |
| S08 | 607,363 | 1,356,800 | S17 | 304,605 | 531,332 |
| S09 | 621,275 | 1,340,300 | S18 | 373,626 | 843,608 |

Resident type identities and version gates belong to
[CCS object types](../../game/files/ccs_object_types.md) and
[CCS runtime](../../game/files/ccs_runtime.md#format-versions-and-nun3-comparison).

## Stage content shared with NA2

The established asset-name and masked-payload comparison gives the following
correspondence. This identifies shared stage content, not identical archives.

| NUN4 archive | NA2 archive |
| --- | --- |
| S01 | No corresponding stage |
| S02 | S02 |
| S03 | S23 |
| S04 | S24 |
| S05..S10 | Same number |
| S11 | No corresponding stage |
| S12..S18 | Same number |

S01 and S11 are the only NUN4 battle stages absent from NA2. For either,
asset-name overlap with any NA2 stage is at most 0.22, and identical masked
bytes are at most 4%. These comparisons do not establish texture-pixel
equivalence or whole-scene behavioral equivalence.

## Raw slots, logical IDs and archive ownership

`stage_archive_paths` in `BATTLE.BIN` (`0x0083ABE0`) contains 25 pointers.
Slots 0..17 select `stage/s01.ccs` through `stage/s18.ccs`; the following
word after slot 24 is zero. Resident `stage_slot_logical_id`
(`0x00312D00`) accepts unsigned slots below 18 and uses 18 jump targets in
`stage_slot_logical_id_cases` (`0x005C3C80`). Target `0x00312D28 + n*0x10`
loads `n+1`; out-of-range inputs return zero. Thus S01 is raw slot **0**,
logical ID **1**.

| Raw slot | Logical ID | Archive |
| ---: | ---: | --- |
| 0..17 | 1..18 respectively | `stage/s01.ccs`..`stage/s18.ccs` |
| 18 | 0 | `stage/ktys_skk.ccs` |
| 19 | 0 | `stage/ktys_str.ccs` |
| 20 | 0 | `stage/ktys_bnt.ccs` |
| 21 | 0 | `stage/ktys_kty.ccs` |
| 22 | 0 | `stage/ktys_mnd.ccs` |
| 23 | 0 | `stage/ktys_skr.ccs` |
| 24 | 0 | `stage/ktys_tyo.ccs` |

`bg_control_load_stage` (`0x006C3EB0`) publishes the incoming raw slot to
the manager byte at `+0xFC`, pause-controller byte at `+0x0E`, and background
word at `+0x80`. It then requires the directly indexed archive and stores the
handle at background `+0x1D4` and `+0`. No logical-ID conversion intervenes.
`stage_archive_acquire` (`0x006C5760`), `stage_archive_enqueue`
(`0x006C5870`) and `stage_archive_adopt` (`0x006C58B0`) likewise take raw slots.
These table consumers have no upper-bound check.

`stage_select_initialize_choices` (`0x006F5CC0`) builds ascending raw slots
0..17, filtered through `battle_stage_is_unlocked` (`0x00323630`) and
`profile_stage_is_unlocked` (`0x0039CFF0`). The profile bit-array base is
`+0x82C`; choice halfwords start at owner `+0x1C`, their count is `+0x40`,
and the restored cursor at `+0x100` comes from manager `+0xFC`.
Confirmation (`0x006F6AA0`) publishes that raw value. Presentation assets
are described under [Stage Select presentation](#stage-select-presentation).

## S01 per-stage camera record

NUN4's camera data is resident. `stage_camera_records_by_slot`
(`0x005750B0`) has 25 pointers: battle slots 0..17 point to the contiguous
18-record `camera_stage_tracking_gains` array (`0x005749F0`, stride `0x60`),
while 18..24 point to seven earlier summon records.
`camera_bind_stage_record` (`0x002D16D0`) saves camera `+0x194` to `+0x198`
and installs the raw-slot pointer, without a range check.

S01's 96 bytes at `0x005749F0` are identical to NA2's S01 record at
`0x00891510`. The following is the field-by-field comparison; every offset
and S01 value agrees. NUN4 uses `Nun4StageCameraRecord`; NA2 uses
`StageCameraRecord`.

| Offset | Field | S01 value in both games |
| --- | --- | ---: |
| +00 | `eye_decreasing` | 0.65 |
| +04 | `eye_increasing_large` | 0.3 |
| +08 | `eye_increasing_medium` | 0.15 |
| +0C | `eye_increasing_small` | 0.05 |
| +10 | `unknown_10` | 0.03 |
| +14 | `target_same_section` | 0.65 |
| +18 | `unknown_18` | 0.65 |
| +1C | `target_large` | 0.15 |
| +20 | `target_medium` | 0.175 |
| +24 | `target_small` | 0.03 |
| +28 | `min_distance` | 600 |
| +2C | `max_distance` | 4000 |
| +30 | `target_upper` | 1000 |
| +34 | `target_lower` | -1000 |
| +38 | `edge_upper` | 1200 |
| +3C | `edge_lower` | -1200 |
| +40 | `eye_height_cap` | 1500 |
| +44 | `unknown_44` | 200 |
| +48 | `eye_lateral_scale` | 0.8 |
| +4C | `differing_section_elevation` | 2.5 |
| +50 | `same_nonzero_section_elevation` | 5 |
| +54 | `spread_control` | 1.2 |
| +58 | `unknown_58` | 0 |
| +5C | `unknown_5c` | 0 |

NUN4's consumers establish the same named field roles: `camera_stage_track`
(`0x002D17F0`) handles section elevation; `camera_select_target`
(`0x002D2350`) target clamps; `camera_compute_fit` (`0x002D2760`) spread;
`camera_place_eye` (`0x002D31B0`) edges, distance, lateral scale and height;
`camera_main_track` (`0x002D3970`) eye gains; and `camera_main_finish_track`
(`0x002D3CA0`) target gains. The five unknown fields retain their names:
the inspected consumers do not establish their roles. Shared camera behavior
is detailed in [Battle camera](../session/battle_camera.md#per-stage-camera-record).

## S01 combo/skill anchors and authored navigation

`stage_combo_anchors` (`0x00852CA0`) has 18 `Nun4StageAnchorRecord` entries,
each `0x10` bytes. Array pointers are at `+0/+4`, unsigned byte counts at
`+8/+9`; the remaining six bytes are unassigned. This is the same field
layout as NA2's `StageAnchorRecord`. Vectors are four floats, 16 bytes each.

| Side | NUN4 S01 array | Count | Vectors in raw order |
| ---: | --- | ---: | --- |
| 0 | `stage_s01_combo_anchors_side0`, `0x00839F80` | 15 | c0 = 700,600,500,400,300,200,100,0,-100,-200,-300,-400,-500,-600,-700; c1=0, c2=0, c3=1 |
| 1 | `stage_s01_combo_anchors_side1`, `0x0083A070` | 6 | c0 = 200,100,0,-100,-200,-300; c1=1000, c2=749, c3=1 |

NA2 S01 uses 13 side-0 vectors (600..-600) and nine side-1 vectors
(400..-400, c1=1000, c2=699), so equal camera records do not imply equal
anchor data. `stage_choose_combo_anchor` (`0x006C3760`) selects the input
side's array before any return-side override, then finds the nearest 3D
vector, retaining the first on ties. It preserves the requested side for
S01. Slots 13/3 force return side 0 and 15/9/8/2 force 1.

`stage_navigation_initialize` (`0x006EAAA0`) indexes the 18 pointers in
`stage_navigation_authored_routes` (`0x0083C620`) by raw manager `+0xFC`,
without a bound. S01 points to `stage_s01_navigation_routes`
(`0x0083BEB0`):

| Source line | Destination line | Fraction | Action/type |
| ---: | ---: | ---: | ---: |
| 2 | 1 | 0 | 3 |
| 1 | 2 | 1 | 3 |
| -1 | -1 | 0 | 0 (terminator) |

`Nun4StageRouteRecord` is 12 bytes: signed source/destination bytes at
`+0/+1`, float fraction at `+4`, action/type byte at `+8`. Its layout agrees
with NA2's route records. NUN4 copies authored entries until source -1 into
a 64-entry work table at `0x00863990`, then sentinel-fills the remainder.
The entries refer to the combined first-family line numbering, not stage IDs.
The script configurations produce one front and two back first-family lines,
and one front and two back second-family pairs. All named normal-line nodes,
second-line endpoints and section boundary nodes are present in S01.

## Fixed `n_rash` archive

Resident `battle_load_ccs` (`0x00317130`) checks and loads the fixed
`battle_rash_archive_path` (`0x005C5980`, `n_rash.ccs`) before loading the
selected stage. Both synchronous and queued paths use that literal. Thus S01
uses NUN4 `N_RASH.CCS`; this path has no per-stage selector equivalent to
NA2's six-path grouping. The native parallel-animation consumer at
`0x001FC390` also uses a fixed pointer (`0x006070B8`) to `n_rash.ccs`.

NUN4's English archive is 59,056 compressed / 226,912 decompressed bytes.
Its SHA-256 values are:

- Compressed: `10018225f704a23541b58c0b0c8261eacddce5ad5253bbac3b2e949a23746858`.
- Decompressed: `3db5de485e6cee3f1a3784353a0e4bf9c28084b2740a7ad272af4859928230fa`.

None of NA2's `N_RASH`, `N_RASH1`..`N_RASH5` archives is identical, either
compressed or decompressed. Their decompressed sizes are respectively
241,284; 243,696; 244,568; 241,732; 242,204; and 242,692 bytes.
Individual-resource comparison establishes that NA2 group 0 already contains
NUN4's required parallel content.

The resident constructor (`0x001FC390`) resolves `ANM_rash_p1` and
`ANM_rash_b`, then binds `OBJ_camera_dm` and `OBJ_target_dm`. NUN4's
93-frame `ANM_rash_b` section at decoded `0x30F8` is byte-identical to NA2
group 0 at `0x3B18` (56,236 bytes); its 22-frame `ANM_rash_p1` at
`0x10CF0` is byte-identical to NA2 group 0 at `0x11710` (404 bytes).
The b stream contains 94 frame markers, 24 object tracks, ten material
tracks, two morph tracks and eighteen event commands. Every authored
position, rotation, scale, alpha and camera/target key agrees.

| NA2 group / parallel animation | Object tracks | Donor tracks with identical complete values | Camera / target position key counts |
| --- | ---: | ---: | --- |
| 0 / b | 24 | 24/24 | 93 / 93 |
| 1 / c | 25 | 22/24 | 56 / 75 |
| 2 / d | 25 | 11/24 | 57 / 76 |
| 3 / e | 24 | 0/24 | 93 / 93 |
| 4 / f | 24 | 0/24 | 93 / 93 |
| 5 / g | 24 | 0/24 | 93 / 92 |

All variants declare 93 frames. The comparison resolves local IDs to target
names and retains every channel's times and float values; c/d each have one
additional object track. Equal camera endpoints do not imply equal curves.
Donor/group-0 camera positions at frames 0/92 are
`(-1367.821045,599.631775,356.916321)` /
`(-477.822205,-72.120033,205.212555)`; target positions are
`(-198.425140,252.160812,277.031616)` /
`(324.546661,17.667404,241.435059)`. Both have position and Euler keys at
every frame 0..92. The p1 constant shadow transform also matches all six
groups after IDs are mapped.

The b/p1 dependency walk covers 88 resource rows / 112 typed sections after
excluding twelve cleared mesh bookkeeping rows. Of the 86 non-animation
rows, 84 have identical complete typed payloads in every NA2 group after
typed references are mapped; the final material and sampling rows differ
only in sampling-provider ownership. Complete model geometry, material
fields, shadow pixel words and CLUT words are included. All eleven authored
main-source composition records also match group 0.

NUN4 locally defines `TEX_sampling01` under
`#c\rash\tex\sampling01.bmp` (row 111, decoded `0x22EF8`). NA2 rash
imports `#e\0x\tex\sampling01.bmp` (group-0 row 81) from common
`CMN/EFFECT0X.CCS` row 2090 at `0x15E3B4`. Both 36-byte sampling definitions
match after own IDs are omitted: flags `0x21`, 8x8 header dimensions,
no CLUT/group and no pixel words. Available common providers and local
sampling definitions are established in
[Asset dependencies](../../game/files/asset_dependencies.md#locally-filled-external-marker-rows).
This is descriptor equivalence, not captured-framebuffer pixel equivalence.

The games' auxiliary consumers require different resource sets. NUN4
`rash_coordinator_auxiliary_initialize` (`0x001ECF70`) binds
`ANM_xrush01a/03a`, `TEX_xrush`, and two side children using
`ANM_xrush01a/02a/04a`. Those four names are absent from NA2 rash archives;
NA2's native fight/gear/wait/start/kizu names are absent from donor rash.
All fifteen nonvariant NA2 animations match across the six groups after
target-ID normalization. The archive's two-frame `ANM_xrush_ca` camera
resource matches all six NA2 copies: position `(0,-127.032967,0)`, Euler
degrees `(90,0,-0)`, FOV 45. Native NA2 resource consumers belong to
[Stage-grouped n_rash](stages.md#stage-grouped-n_rash-battle-animationeffect-archive).

## Stage and section branch homologs

The following inspected NUN4 paths have counterparts already present in NA2.
None contains an S01-only branch. The values tested here are raw slots except
for the explicitly identified logical-ID and section predicates.

| NUN4 routine | Stage-dependent behavior and S01 result | NA2 counterpart |
| --- | --- | --- |
| `bg_surface_variant`, `0x006C49F0` | Slots 6/12/13 select classifier exceptions; S01 returns default 0. | `bg_surface_variant`; same raw-slot exceptions. |
| `bg_setup_s15_animation`, `0x006C5460` | Only slot 14 resolves `ANM_s15efe04`; S01 clears the pointer. | `bg_setup_s15_animation`. |
| `stage_nearest_line_extended`, `0x006D6180` | Slots 1/7 set the argument to 1100 before multiplication by 10; a separate common query can also do so. S01 uses the ordinary argument when that query is false. | `stage_nearest_line_extended`; NA2 additionally checks slots 18/20. |
| `stage_navigation_response`, `0x006D84B0` | Major state 5 invokes the special response for slots 5/2; S01 uses common handling. | `stage_navigation_response`; NA2's equivalent slots are 5/22. |
| `stage_plan_route`, `0x006D7A80` | Slot 7 source line 1/2 can enter direct state 3 when the target/route is missing; S01 follows its authored route list. | `stage_plan_route`; NA2 also has raw 18/20 exceptions. |
| `stage_navigation_s08`, `0x006DD380` | Slot 7 receives special line 1/2 handling with c2 threshold 800; S01 uses common handling. | `stage_navigation_s08`. |
| `stage_navigation_s13`, `0x006D9530` | Slot 12 tests fighter section and action IDs `0x2B/0x26/0x21/0x1F`; S01 uses common handling. | `stage_navigation_s13`; NA2's corresponding action IDs are `0x30/0x2C/0x27/0x25`. |
| `field_player_placement`, `0x006EBDA0` | Slot 12 returns initial section 1; S01 returns 0. Both sides add 200 to node c2, set c3=1 and orient by ±pi/2. | `field_player_placement`. |
| `stage_choose_combo_anchor`, `0x006C3760` | Return-side overrides exclude S01, which preserves its input side. | `stage_choose_combo_anchor`; same data format, different arrays/override set. |
| `bg_scene_set_type_updates`, `0x006C5690` | Slot 15 remaps selector 7 to 2; S01 uses the supplied selector. | Shared scene-selector update capability. |
| `stage_clamp_section_endpoints`, `0x006C4920` | Section min/max vectors at background +B40/+B50, stride 0x20; no raw-slot branch. | `stage_clamp_section_endpoints`; NA2 vectors are +A40/+A50. |
| `stage_placement_section`, `0x006EBEF0` | Validates a section against field +7C and uses common boundary resolution; no S01 exception. | `stage_placement_section`. |
| `stage_resolve_boundary`, `0x006C4320` | Uses section containers at background +B80 to interpolate normalized c0 spans and clamp/project endpoints; no raw-slot or logical-ID branch. | Shared section-boundary resolution. |

An additional direct raw-slot reader, `ai_stage_environment_adjust`
(`0x006E2910`), has a slot-12 tail gated by the resident query at
`0x0020DBB0`. For that slot and a false query, selected AI states can enter
states `0x19/0x15/0x16` through a random choice. S01 skips this tail. The
inspected code does not establish an exact NA2 counterpart for that tail.

Main-camera section elevation and transfer smoothing use the shared record
and fighter-section state, not an S01-specific predicate. The clash handler
is resident `camera_controller_clash` (`0x00388BB0`), dispatched by
`camera_controller_update` (`0x00387D30`) for selector `0x54`. This is the
behavioral homolog of NA2's `camera_controller_mode18`; its selector number
and object offsets differ.

For request -4, it chooses presentation slot 1, binds the normal record
`camera_clash_record` (`0x0057E6B0`) or the alternative at `0x0057E760`, and
uses interaction anchors +AA0/+AB0. Once its counter reaches
`eye_delay + eye_duration` (20 in both records), it calls
`camera_clash_correct_angle` (`0x003885D0`). It then overwrites the eye offset
at presentation camera +1B0 with the authored endpoint and adds 80 to c2
only for logical ID 5. S01's ID 1 receives no bias. NA2 already has this
angle/section/segment correction and logical-5 bias. The NUN4 alternative
record selector's broader context remains unassigned.

The 27 direct calls to `stage_slot_logical_id` were traced. Their explicit
special IDs are 2,3,5,6,7,8,9,10,12,13,18; none tests ID 1 as a special
case. The annotation labels `stage_logical_id_call_<address>` retain each
call's scoped branch result. Likewise, the inspected direct reads of manager
+FC in the battle overlay contain no S01-only numeric branch. These bounded
negative results do not establish absence through every indirect call,
alternative accessor, or unidentified memory alias.

## S01 background archive and native factory parity

The retail English `STAGE/S01.CCS` has header container name `s01`
and version `0x123`. Its directory has 267 namespaces and 1693
object records, including row zero. A handler-aware walk reaches the
exact decompressed end at 1,406,876 bytes. Its resource sections are:

| File tag | Count |
| --- | ---: |
| `0x100` | 114 |
| `0x1300` | 50 |
| `0x1400` | 56 |
| `0x200` | 337 |
| `0x2000` | 55 |
| `0x2400` | 1 |
| `0x300` | 204 |
| `0x400` | 204 |
| `0x600` | 1 |
| `0x700` | 42 |
| `0x800` | 116 |
| `0x900` | 112 |
| `0xA00` | 55 |
| `0xB00` | 7 |

The header/directory occur once, followed at the end by one `0x0005`
terminator and one frame `0xFF01` command; that final frame command
is outside the typed-object dispatch. The section types all have NA2
native routes. Version `0x123` takes NA2's newest documented branches
for objects, material, model and other gated resources. This archive uses
only ordinary family-0 models and two family-4 projection models.
Its animation nested tags are `0x0102` (49), `0x0603` (1), and
`0xFF01` (919); each typed command's curve consumption agrees with
the NA2 reader widths and reaches the next header. The absence of an
unknown tag and a supported version establish input compatibility on
these inspected routes, not all later rendering behavior.

No namespace begins with `#`. All 266 nonzero namespace filenames are
source-export `.max` or `.bmp` paths, rather than CCS container imports.
The only case-insensitive `.ccs` byte sequences in the decompressed
archive are eight lowercase `s01.ccs` strings in bird configurations
104..111, at byte offsets 86188, 86261, 86334, 86407, 86480, 86553,
86626 and 86699 (offsets identify the dot). The header name begins at
byte 12. Other occurrences of `s01` are asset/export names, not container
filenames. The birds select their own container using token 4 and
`ANM_s01efe00_a0/a1` using tokens 5/6.

`bg_scene_parse_records` (`SLUS_218.62`, `0x003B6C50`) expands
the 117 signed-short triples into 16-byte records, copies each pipe-ended
configuration, and replaces commas with NULs.
`bg_scene_dispatch_records` (`0x003B7040`) indexes the 129-pointer
resident `bg_record_factories` at `0x00583860`; NA2's homolog is
`0x005B3970`. The factory occupies record `+4`, owning selector
`+0`, scene-list selector `+8`, configuration `+0xC`. Native scene
layout differs: NUN4 records/count are `+0xC0/+0xC4`, versus NA2
`+0xC4/+0xC8`. That compiled-object difference does not change the
archive's triples or token layout.

Twelve S01 factory indices construct matching named classes in both
games. Their constructors install the listed outer object vtable; its
RTTI link resolves to the listed identical class string. The other ten
indices configure scene/control state and construct no class, so there
is no class-vtable identity to prove for those entries.

| Index | Identity/role | NA2 factory | NUN4 factory | NA2 vtable → RTTI → name | NUN4 vtable → RTTI → name |
| ---: | --- | --- | --- | --- | --- |
| 0 | `ccBgDrawObject` | `0x00395CB0` | `0x003B86F0` | `0x005DD550 → 0x005D5CE0 → 0x005B3508` | `0x005EE020 → 0x005D7588 → 0x005D7568` |
| 2 | `ccBgDrawAnm` | `0x00396750` | `0x003B9080` | `0x005DD4C0 → 0x005D5F70 → 0x005B3768` | `0x005EDFC0 → 0x005D74C8 → 0x005D74A8` |
| 6 | `ccBgClothFlag` | `0x00397AA0` | `0x003BA2E0` | `0x005DD400 → 0x005D6150 → 0x005B3910` | `0x005EDF00 → 0x005D77E0 → 0x005D77C0` |
| 10 | `fog` | `0x00398A90` | `0x003BB240` | no constructed class | no constructed class |
| 11 | `ccBgGlareFilter` | `0x00398EF0` | `0x003BB6A0` | `0x005DD370 → 0x005D6120 → 0x005B38F0` | `0x005EDE70 → 0x005D6A98 → 0x005D6A60` |
| 17 | `render coefficients` | `0x00399340` | `0x003BBB00` | no constructed class | no constructed class |
| 18 | `ccBgLightDistant` | `0x00399690` | `0x003BBE80` | `0x005DD310 → 0x005D60F0 → 0x005B38C0` | `0x005EDE10 → 0x005D7768 → 0x005D7740` |
| 22 | `scene scalar +0x30` | `0x00399770` | `0x003BBF60` | no constructed class | no constructed class |
| 23 | `ccBgCurtain` | `0x00399D70` | `0x003BC550` | `0x005DD2E0 → 0x005D60D8 → 0x005B38A8` | `0x005EDDE0 → 0x005D7730 → 0x005D7710` |
| 31 | `selector resource` | `0x0039D2B0` | `0x003BF680` | no constructed class | no constructed class |
| 33 | `player 1 position` | `0x006C44C0` | `0x006C6B30` | no constructed class | no constructed class |
| 34 | `player 2 position` | `0x006C4520` | `0x006C6BA0` | no constructed class | no constructed class |
| 35 | `front second lines` | `0x006C4580` | `0x006C6C10` | no constructed class | no constructed class |
| 36 | `back second lines` | `0x006C45E0` | `0x006C6C80` | no constructed class | no constructed class |
| 37 | `front first lines` | `0x006C4640` | `0x006C6CF0` | no constructed class | no constructed class |
| 38 | `back first lines` | `0x006C46A0` | `0x006C6D60` | no constructed class | no constructed class |
| 41 | `ccBgBreakDollBattle` | `0x006C71E0` | `0x006C87D0` | `0x005DDA70 → 0x008C22E8 → 0x00891480` | `0x005EE710 → 0x008538A8 → 0x00853870` |
| 45 | `ccBgLantern` | `0x003A20B0` | `0x003C46B0` | `0x005DCFF0 → 0x005D5EC8 → 0x005B36C8` | `0x005EDB20 → 0x005D73A0 → 0x005D7380` |
| 50 | `ccBgBreakObjectBattle` | `0x006C55B0` | `0x006C7CB0` | `0x005DDAE0 → 0x008C2140 → 0x008912F0` | `0x005EE750 → 0x008535B8 → 0x00853590` |
| 75 | `ccBgEscapeBirdBattle` | `0x006CD580` | `0x006CE9D0` | `0x005DD8E0 → 0x008C2220 → 0x008913B0` | `0x005EE5B0 → 0x00853748 → 0x00853720` |
| 79 | `ccBgTransObject2` | `0x006CE430` | `0x006CF910` | `0x005DD840 → 0x008C21C8 → 0x00891330` | `0x005EE510 → 0x00853688 → 0x00853620` |
| 80 | `ccBgBreakObjectFallBattle` | `0x006CEA20` | `0x006CFFD0` | `0x005DD810 → 0x008C2188 → 0x00891310` | `0x005EE4E0 → 0x00853618 → 0x008535E0` |


Factory/parser token positions, numeric conversions, name lookups and
literal-`0` handling agree for all 117 authored S01 records. **Records
read differently by NA2: none found.** This is parser-input parity,
not a claim of identical complete object behavior or layouts: native
break-object damage receiver constants and some playback setup calls
differ between games.

The three cloth records 73..75 use factory 6:
`TEX_s01art89/81/90`, `DMY_hata_020/010/000`, selectors 5/6/5,
float dimensions 55/160 (passed onward as 220/640), and a 6×4 grid.
Both parsers convert token 7 `0.0015` with the **integer** converter,
producing zero, rather than a different NA2 interpretation.
Lantern records 45/47/48/49 use factory 45, owning selector 4 and
scene-list selector 1, with float angular step `0.04` and amplitudes
`0.1/0.025/0.05/0.1`. Their object/dummy pairs all exist.

**Required configuration resources/nodes missing from S01: none found.**
This covers direct names and generated `stem_aN` names for every break
animation and debris object, both bird animations, and the fixed player/
navigation nodes. Factory 33/34 ignores its authored `-1` and resolves
`DMY_pp1_010/DMY_pp2_010`. Factories 35/36 consume counts 2/4,
building one/two second-line pairs from `DMY_line_010/_1` and
`DMY_line_020/_1/_2/_3`; the four `DMY_linemin/max01/02`
boundary nodes exist. Factories 37/38 consume counts 1/2, and the
normal-node pairs `DMY_f_cl_1_nor/_1`,
`DMY_b_cl_1_nor/_1`, `DMY_b_cl_2_nor/_1` all exist.
Absent `ewr/mov` alternatives are not missing requirements when the
normal pair resolves. The break record 98 names
`ANM_s01gim08` with `DMY_pg_070/DMY_s01gim07_hit`; all generated
animation names exist, so this authored pairing is not a missing name.

### Complete BIN_bgdata record ledger

Record numbers below are zero-based. The three stored fields are signed
16-bit values. Configuration strings are shown before comma-to-NUL
conversion.

| Record | Field 0 | Factory | Scene-list selector | Configuration |
| ---: | ---: | ---: | ---: | --- |
| 0 | 4 | 35 | 2 | `2` |
| 1 | 4 | 36 | 2 | `4` |
| 2 | 4 | 37 | 2 | `1` |
| 3 | 4 | 38 | 2 | `2` |
| 4 | 4 | 33 | 2 | `-1` |
| 5 | 4 | 34 | 2 | `-1` |
| 6 | 0 | 31 | 0 | `BLT_bg` |
| 7 | 1 | 31 | 1 | `BLT_art` |
| 8 | 2 | 31 | 2 | `BLT_obj` |
| 9 | 0 | 0 | 0 | `OBJ_bac_000_,0,1,1` |
| 10 | 0 | 2 | 0 | `ANM_s01cld00_a0,DMY_dmy_cld000,1,1,0.07,1` |
| 11 | 0 | 2 | 0 | `ANM_s01cld01_a0,DMY_dmy_cld010,1,1,0.07,1` |
| 12 | 0 | 2 | 0 | `ANM_s01cld02_a0,DMY_dmy_cld020,1,1,0.07,1` |
| 13 | 0 | 2 | 0 | `ANM_s01cld03_a0,DMY_dmy_cld030,1,1,0.07,1` |
| 14 | 0 | 2 | 0 | `ANM_s01cld04_a0,DMY_dmy_cld040,1,1,0.07,1` |
| 15 | 0 | 2 | 0 | `ANM_s01cld05_a0,DMY_dmy_cld050,1,1,0.07,1` |
| 16 | 0 | 2 | 0 | `ANM_s01cld00_a0,DMY_dmy_cld060,1,1,0.07,33` |
| 17 | 0 | 2 | 0 | `ANM_s01cld01_a0,DMY_dmy_cld070,1,1,0.07,33` |
| 18 | 0 | 2 | 0 | `ANM_s01cld02_a0,DMY_dmy_cld080,1,1,0.07,33` |
| 19 | 0 | 2 | 0 | `ANM_s01cld03_a0,DMY_dmy_cld090,1,1,0.07,33` |
| 20 | 0 | 2 | 0 | `ANM_s01cld04_a0,DMY_dmy_cld100,1,1,0.07,33` |
| 21 | 0 | 2 | 0 | `ANM_s01cld05_a0,DMY_dmy_cld110,1,1,0.07,33` |
| 22 | 0 | 2 | 0 | `ANM_s01cld00_a0,DMY_dmy_cld000,1,1,0.07,66` |
| 23 | 0 | 2 | 0 | `ANM_s01cld01_a0,DMY_dmy_cld010,1,1,0.07,66` |
| 24 | 0 | 2 | 0 | `ANM_s01cld02_a0,DMY_dmy_cld020,1,1,0.07,66` |
| 25 | 0 | 2 | 0 | `ANM_s01cld03_a0,DMY_dmy_cld030,1,1,0.07,66` |
| 26 | 0 | 2 | 0 | `ANM_s01cld04_a0,DMY_dmy_cld040,1,1,0.07,66` |
| 27 | 0 | 2 | 0 | `ANM_s01cld05_a0,DMY_dmy_cld050,1,1,0.07,66` |
| 28 | 0 | 0 | 0 | `OBJ_bac_010_,0,1,1` |
| 29 | 0 | 0 | 0 | `OBJ_bac_020_,0,1,1` |
| 30 | 0 | 0 | 0 | `OBJ_bac_030_,0,1,1` |
| 31 | 0 | 0 | 0 | `OBJ_bac_040_,0,1,1` |
| 32 | 0 | 0 | 0 | `OBJ_bac_050_,0,1,1` |
| 33 | 0 | 0 | 0 | `OBJ_flo_000_,0,1,1` |
| 34 | 0 | 0 | 0 | `OBJ_flo_010_,0,1,1` |
| 35 | 0 | 0 | 0 | `OBJ_flo_020_,0,1,1` |
| 36 | 1 | 0 | 1 | `OBJ_flo_030_,0,1,1` |
| 37 | 1 | 0 | 1 | `OBJ_flo_040_,0,1,1` |
| 38 | 1 | 0 | 1 | `OBJ_flo_050_,0,1,1` |
| 39 | 1 | 0 | 1 | `OBJ_art_000_,0,1,1` |
| 40 | 1 | 0 | 1 | `OBJ_art_010_,0,1,1` |
| 41 | 1 | 0 | 1 | `OBJ_art_020_,0,1,1` |
| 42 | 1 | 0 | 1 | `OBJ_art_030_,0,1,1` |
| 43 | 1 | 0 | 1 | `OBJ_art_040_,0,1,1` |
| 44 | 1 | 0 | 1 | `OBJ_art_050_,0,1,1` |
| 45 | 4 | 45 | 1 | `OBJ_art_060_,DMY_dummy_060,0.04,0.1` |
| 46 | 1 | 0 | 1 | `OBJ_obj_243_,0,1,1` |
| 47 | 4 | 45 | 1 | `OBJ_obj_242_,DMY_dummy_240_3,0.04,0.025` |
| 48 | 4 | 45 | 1 | `OBJ_obj_242_,DMY_dummy_240_2,0.04,0.05` |
| 49 | 4 | 45 | 1 | `OBJ_obj_241_,DMY_dummy_240_1,0.04,0.1` |
| 50 | 1 | 23 | 1 | `OBJ_obj_234_,DMY_dummy_230_4,1,1,4,0.1,0.0` |
| 51 | 1 | 23 | 1 | `OBJ_obj_233_,DMY_dummy_230_3,1,1,4,0.1,0.0` |
| 52 | 1 | 23 | 1 | `OBJ_obj_232_,DMY_dummy_230_2,1,1,4,0.1,0.0` |
| 53 | 1 | 23 | 1 | `OBJ_obj_231_,DMY_dummy_230_1,1,1,4,0.1,0.0` |
| 54 | 1 | 23 | 1 | `OBJ_obj_230_,DMY_dummy_230_0,1,1,4,0.1,0.0` |
| 55 | 1 | 23 | 1 | `OBJ_obj_229_,DMY_dummy_220_9,1,1,4,0.1,0.0` |
| 56 | 1 | 23 | 1 | `OBJ_obj_228_,DMY_dummy_220_8,1,1,4,0.1,0.0` |
| 57 | 1 | 0 | 1 | `OBJ_obj_221_,0,1,1` |
| 58 | 1 | 23 | 1 | `OBJ_obj_220_,DMY_dummy_220_0,1,1,4,0.1,0.0` |
| 59 | 1 | 23 | 1 | `OBJ_obj_219_,DMY_dummy_210_9,1,1,4,0.1,0.0` |
| 60 | 1 | 23 | 1 | `OBJ_obj_218_,DMY_dummy_210_8,1,1,4,0.1,0.0` |
| 61 | 1 | 23 | 1 | `OBJ_obj_217_,DMY_dummy_210_7,1,1,4,0.1,0.0` |
| 62 | 1 | 23 | 1 | `OBJ_obj_216_,DMY_dummy_210_6,1,1,4,0.1,0.0` |
| 63 | 1 | 0 | 1 | `OBJ_obj_010_,0,1,1` |
| 64 | 2 | 0 | 2 | `OBJ_obj_100_,0,0.5,1` |
| 65 | 2 | 0 | 2 | `OBJ_obj_110_,0,0.5,1` |
| 66 | 2 | 0 | 2 | `OBJ_obj_120_,0,0.5,1` |
| 67 | 2 | 0 | 2 | `OBJ_obj_000_,0,1,1` |
| 68 | 2 | 0 | 2 | `OBJ_obj_060_,0,0.6,1` |
| 69 | 2 | 0 | 2 | `OBJ_obj_020_,0,1,1` |
| 70 | 2 | 0 | 2 | `OBJ_obj_030_,0,1,1` |
| 71 | 2 | 0 | 2 | `OBJ_obj_040_,0,1,1` |
| 72 | 2 | 0 | 2 | `OBJ_obj_050_,0,1,1` |
| 73 | 2 | 6 | 2 | `TEX_s01art89,DMY_hata_020,5,55,160,400,-100,0.0015,1000,50,6,4` |
| 74 | 2 | 6 | 2 | `TEX_s01art81,DMY_hata_010,6,55,160,400,-100,0.0015,1000,50,6,4` |
| 75 | 2 | 6 | 2 | `TEX_s01art90,DMY_hata_000,5,55,160,400,-100,0.0015,1000,50,6,4` |
| 76 | 2 | 23 | 2 | `OBJ_obj_201_,DMY_dummy_200_1,1,1,4,0.1,0.0` |
| 77 | 2 | 23 | 2 | `OBJ_obj_202_,DMY_dummy_200_2,1,1,4,0.1,0.0` |
| 78 | 2 | 23 | 2 | `OBJ_obj_203_,DMY_dummy_200_3,1,1,4,0.1,0.0` |
| 79 | 2 | 0 | 2 | `OBJ_obj_261_,0,1,1` |
| 80 | 4 | 79 | 2 | `OBJ_efe_040_,DMY_has2_000,1,DMY_has2_000,650,0.7` |
| 81 | 4 | 79 | 2 | `OBJ_efe_050_,DMY_has2_010,1,DMY_has2_010,650,1` |
| 82 | 2 | 0 | 2 | `OBJ_obj_310_,0,1,1` |
| 83 | 2 | 0 | 2 | `OBJ_obj_320_,0,1,1` |
| 84 | 2 | 0 | 2 | `OBJ_obj_330_,0,1,1` |
| 85 | 2 | 0 | 2 | `OBJ_obj_340_,0,1,1` |
| 86 | 4 | 80 | 2 | `ANM_s01gim01,3,2,DMY_pg_010,DMY_s01gim10_hit,1,100,OBJ_bre_010,4` |
| 87 | 4 | 80 | 2 | `ANM_s01gim01,3,2,DMY_pg_011,DMY_s01gim11_hit,1,100,OBJ_bre_010,4` |
| 88 | 4 | 80 | 2 | `ANM_s01gim01,3,2,DMY_pg_012,DMY_s01gim12_hit,1,100,OBJ_bre_010,4` |
| 89 | 4 | 80 | 2 | `ANM_s01gim01,3,2,DMY_pg_013,DMY_s01gim13_hit,1,100,OBJ_bre_010,4` |
| 90 | 4 | 80 | 2 | `ANM_s01gim01,3,2,DMY_pg_014,DMY_s01gim14_hit,1,100,OBJ_bre_010,4` |
| 91 | 4 | 80 | 2 | `ANM_s01gim15,3,2,DMY_pg_015,DMY_s01gim15_hit,1,100,OBJ_bre_150,4` |
| 92 | 4 | 80 | 2 | `ANM_s01gim15,3,2,DMY_pg_016,DMY_s01gim16_hit,1,100,OBJ_bre_150,4` |
| 93 | 4 | 50 | 2 | `ANM_s01gim02,3,2,DMY_pg_020,DMY_s01gim02_hit,1,100,OBJ_bre_020,4` |
| 94 | 4 | 50 | 2 | `ANM_s01gim03,3,2,DMY_pg_030,DMY_s01gim03_hit,1,100,OBJ_bre_030,4` |
| 95 | 4 | 50 | 2 | `ANM_s01gim04,2,-1,DMY_pg_040,DMY_s01gim04_hit,1,100,OBJ_bre_010,4` |
| 96 | 4 | 50 | 2 | `ANM_s01gim05,3,2,DMY_pg_050,DMY_s01gim05_hit,1,100,OBJ_bre_010,4` |
| 97 | 4 | 50 | 2 | `ANM_s01gim06,3,2,DMY_pg_060,DMY_s01gim06_hit,1,100,OBJ_bre_060,4` |
| 98 | 4 | 50 | 2 | `ANM_s01gim08,3,2,DMY_pg_070,DMY_s01gim07_hit,1,100,OBJ_bre_080,4` |
| 99 | 4 | 50 | 2 | `ANM_s01gim08,3,2,DMY_pg_080,DMY_s01gim08_hit,1,100,OBJ_bre_080,4` |
| 100 | 4 | 50 | 2 | `ANM_s01gim09,3,2,DMY_pg_090,DMY_s01gim09_hit,1,100,OBJ_bre_090,4` |
| 101 | 4 | 41 | 2 | `ANM_anm_doll,3,1,DMY_dd_010,DMY_s01doll00_hit,1,100,OBJ_doll_bre_000,4` |
| 102 | 4 | 41 | 2 | `ANM_anm_doll,3,1,DMY_dd_010_1,DMY_s01doll01_hit,1,100,OBJ_doll_bre_000,4` |
| 103 | 4 | 50 | 2 | `ANM_s01uki00,3,2,DMY_pg_200,DMY_s01uki00_hit,1,100,OBJ_uki_bre_000,4` |
| 104 | 4 | 75 | 2 | `DMY_tori00_0,300,10,DMY_tori01_0,s01.ccs,ANM_s01efe00_a0,ANM_s01efe00_a1` |
| 105 | 4 | 75 | 2 | `DMY_tori00_1,300,12,DMY_tori01_1,s01.ccs,ANM_s01efe00_a0,ANM_s01efe00_a1` |
| 106 | 4 | 75 | 2 | `DMY_tori00_2,300,11,DMY_tori01_2,s01.ccs,ANM_s01efe00_a0,ANM_s01efe00_a1` |
| 107 | 4 | 75 | 2 | `DMY_tori00_3,300,10,DMY_tori01_3,s01.ccs,ANM_s01efe00_a0,ANM_s01efe00_a1` |
| 108 | 4 | 75 | 2 | `DMY_tori00_4,300,12,DMY_tori01_4,s01.ccs,ANM_s01efe00_a0,ANM_s01efe00_a1` |
| 109 | 4 | 75 | 2 | `DMY_tori00_5,300,10,DMY_tori01_5,s01.ccs,ANM_s01efe00_a0,ANM_s01efe00_a1` |
| 110 | 4 | 75 | 2 | `DMY_tori00_6,300,11,DMY_tori01_6,s01.ccs,ANM_s01efe00_a0,ANM_s01efe00_a1` |
| 111 | 4 | 75 | 2 | `DMY_tori00_7,300,13,DMY_tori01_7,s01.ccs,ANM_s01efe00_a0,ANM_s01efe00_a1` |
| 112 | 3 | 22 | 2 | `1000` |
| 113 | 3 | 11 | 5 | `30,255,240,150,-0.15,128,128,128,1,0` |
| 114 | 3 | 10 | 5 | `120,180,255,0,32,0,40000` |
| 115 | 3 | 18 | 5 | `ANM_stalig00,255,255,255,LGT_dis_0` |
| 116 | 3 | 17 | 5 | `0.45,0.35` |


### S01 resource allocation compared with NA2 S24

Applying the [NA2 allocator formulas](../../runtime/ee_memory_map/allocator_and_capacity.md#directory-and-finalization-cost)
to the two complete archives gives the following successful-allocation node
costs. They include the allocator's 16-byte headers and rounding
`Q(n) = (n + 31) & ~15`; they exclude placement gaps and scene instances.
The counts are archive data, and the conversion costs are NA2 parser behavior.

| Retained resource category | NUN4 S01 in NA2, bytes | NA2 S24, bytes |
| --- | ---: | ---: |
| Container/directory | 110,400 | 82,032 |
| Objects | 7,296 | 8,064 |
| Materials plus secondary values | 32,352 | 14,976 |
| External wrappers | 2,640 | 3,312 |
| Light descriptor and secondary | 272 | 272 |
| Position/Euler markers | 5,984 | 7,488 |
| Binary blob | 5,216 | 3,520 |
| Compositions and dependency arrays | 16,224 | 15,584 |
| Model descriptors | 38,080 | 30,048 |
| Ordinary model arrays and packets | 849,328 | 1,006,576 |
| Collision meshes | 108,464 | 118,640 |
| Ordinary textures, level tables and pixels | 635,456 | 415,840 |
| CLUT descriptors | 13,056 | 7,296 |
| Transfer-group controllers/bindings | 13,296 | 7,456 |
| Animation packed blocks | 5,136 | 4,960 |
| Animation reference/relation arrays | 2,720 | 2,752 |
| Typed-key descriptors | 2,400 | 3,360 |
| Typed-key curve blocks | 4,928 | 5,360 |
| Effects | 0 | 480 |
| Counted resource subtotal | 1,853,248 | 1,738,016 |
| Conditional CLUT levels/pixels, additional range | 0..43,392 | 0..33,792 |
| Two family-4 output packets, additional conservative range | 0..3,360 | 0 |
| Resource estimate, including those ranges | **1,853,248..1,900,000** | **1,738,016..1,771,808** |

S01 has `F=267` namespace rows and `N=1693` object-directory rows,
including row zero; S24 has `F=183`, `N=1265`. S01's 116 models
contain 392 parts, with 33,152 ordinary vertices; S24's 126 models
contain 249 parts and 41,618 ordinary vertices. Every ordinary model in
both archives uses file flags zero and modes `0`, `1`, `0x1000`,
or `0x1001`; no ordinary-strip expansion is selected. S01's two
projection models each have eight unique vertices and 36 indices
(12 triangles); the upper packet allowance uses `H<=3T`, `S<=3T`.
Exact output direction/edge counts and construction success were not
reproduced. Collision triangle totals are 673 versus 738.

All 204 S01 textures and 114 S24 textures have no mip levels and flags
`1` or `5`, retaining their ordinary pixel storage; their palette
formats are 4-bit/8-bit. S01 has 186 16-color and 18 256-color palettes;
S24 has 94 and 20. Transfer groups/bindings are 3/408 versus 2/228.
The CLUT range reflects the transfer-state condition that can release
palette level/pixel blocks; it is not added as an unconditional cost.

The animation total includes allocations beyond the wrapper: separate
typed-key descriptors and counted curve nodes, plus packed static values
and compacted frame-marker runs. S01 has 49 `0x0102` and one `0x0603`
typed command; S24 has 69 and one, plus two `0x0601` snapshots.
Their total distinct-reference counts are 50 versus 70. Their nested
handler walks consume each animation exactly to its declared end.

#### S01 scene ownership and capacity condition

The [retail NA2 instance formulas](../../runtime/ee_memory_map/allocator_and_capacity.md#background-scene-and-playback-instances)
applied to the decoded 117 records give **234,448 bytes** for the retained
eager scene/control/field graph. Its eight escape birds increase that to
**235,472 bytes** after all switch animations. These counts include the
previously omitted model/playback, procedural cloth, debris, lines, selectors
and enclosing owners; resource geometry, texture pixels and parsed curves
remain shared.

| Retained scene ownership | Bytes |
| --- | ---: |
| 105 primary classes and 105 registration links | 20,352 |
| Field/control/scene and capacity-two vector | 3,328 |
| Collection owners, particle controller/manager and 12 selector sets | 6,288 |
| Both line families | 912 |
| 56 standalone children and their models | 41,872 |
| 80 animation players | 24,320 |
| Cloud/break/light bound entries, evaluators, targets/models/light | 55,744 |
| 18 break arrays/36 registrations and 72 debris models | 51,840 |
| Three 6×4 cloth visual/solver graphs | 15,216 |
| Eight moving owners plus idle bird bindings | 14,080 |
| Glare secondary and transparent-object controllers | 496 |
| Initial scene total | **234,448** |
| All birds escaped, additional work | 1,024 |

Ordinary model material counts were read from every part; the native part
walks close at each declared model end. Instances borrow source geometry
and material secondary values. S01 selects neither property clones nor
extra-pass/bone-array construction. Break parsing creates all 53 players and
72 debris models eagerly. Each 6×4 cloth contributes 5,072 bytes beyond its
outer class, with 36 visual vertices and 68 solver springs. The bird path
creates eight moving owners/players and 24 model targets; its zero-blend
rebind constructs the incoming graph before freeing the old one.

Expanded record/configuration storage costs 9,344 bytes for S01 and 6,592
for S24, but `bg_scene_finish_graph` (`0x003AE170`) frees it after factory
dispatch. The temporary S01 blob copy/triple array adds 5,920 bytes and is
freed before dispatch. Thus those record costs are construction overlap,
not retained scene ownership. S24's earlier 12,864-byte primary-class
subtotal is likewise only the outer-class comparison, not its full scene.

**Retained bound:** S01 resource plus finite scene ownership is
**2,087,696..2,135,472 bytes**, about 1.99..2.04 MiB, before placement gaps.
The conditional resource range remains the palette/projection allowance
shown above. An ordinary successful flags-zero gzip construction has a
conservative additive overlap allowance of **2,886,096 bytes** including
alignment; this sums some scratch that is actually in separate phases and
is not an observed peak.

The count assumes one ordinary successful flags-zero gzip load, one
scene/control/field graph, the existing nonnull renderer, available required
dependencies and zero-blend binding on initially empty players. Extra
allocations introduced by a different consumer are outside this count.

**Sufficient capacity condition:** reserve a **4 MiB contiguous general-arena
gap** for the stage after reserving all concurrent battle/common-effect/item
activity outside it. Charging every finite request without reusing freed
holes gives **3,202,992 bytes**, leaving **991,312 bytes** in that reserve.
The budget includes 667,472 bytes of pipeline nodes, all 297,184 bytes of
Huffman allocations across 37 blocks (only 8,960 coexist), all directory,
animation/provisional/projection/record/model/vector scratch, 448 bytes for
four 0x80-aligned pipeline requests, and all 16 possible incoming bird
rebind graphs plus their material scratch. The two-fighter proximity loop
can issue two successive attaches per bird; they do not coexist as two
incoming graphs.

This establishes finite stage allocation sufficiency under that capacity
condition. Shared break-contact effects and item spawns, fighters/supports,
other loads and unrelated arena activity have their own lifetimes and must
be reserved separately. The sampled 8.3 MiB free gap is a battle end-state
observation; it does not establish the required minimum load-time gap or
an unrestricted all-battle peak. Available headroom under those concurrent
conditions remains unestablished by the static evidence.

## Battle music and S01 soundtrack

The shared battle transition `battle_update_audio_transition`
(`0x00320AC0`) requests battle event0 at `0x00320D54` once the
pause-controller byte at `+0x10` is clear, session halfword `+0x08` is zero,
and the manager's result at `+0x4F8` is zero. The resident wrappers
`audio_request_battle_event` (`0x001D9E50`) and
`audio_dispatch_battle_event` (`0x001D5070`) send music preset5 through
`audio_request_music_preset` (`0x001DA4A0`). The event dispatcher admits
manager category `+0x50 == 1` and modes `+0x54 == 1..4`.

`audio_dispatch_music_preset` (`0x001D5230`) uses the eleven-entry
`audio_music_preset_table` (`0x005913C0`); preset5 reaches
`audio_music_preset_battle` (`0x001D5378`). A nonnegative request-context
word at `+0x00` supplies an explicit member on stereo channel0. A negative
word instead indexes `stage_music_tracks` (`0x00434E00`) directly by the
manager's **signed raw-slot byte** at `+0xFC`, without an upper-bound check.
Neither route selects by logical ID, fighter, random draw or a music-menu
setting. `sound_task` (`0x001D3F30`) allocates and publishes the request
context through `audio_request_context_initialize` (`0x001D3E70`), which
sets its word0 override to -1. This establishes stage selection as the
initial default. Complete override-writer reachability remains open.

| Raw slots | SOUND descriptor0 members in slot order |
| --- | --- |
| 0..5 | 4, 7, 14, 15, 5, 6 |
| 6..11 | 12, 16, 17, 13, 18, 9 |
| 12..17 | 18, 19, 20, 21, 10, 11 |
| 18..24 | 24 for all seven summon slots |

S01, raw slot 0 / logical ID 1, therefore defaults to **member 4 on stereo
channel 0**. Summon raw slots 18..24 select channel 1 after requesting a
fade/stop for channel 0. The descriptor 0 row at `0x00435E10` resolves
archive handle 0; its start parameter is 2.
`audio_select_music_track` (`0x001DA020`) forwards the archive/member
through `audio_start_streamed_music` (`0x001536E0`) and retains the selection.

The S01 track is
`@source/NUN4.iso.files/DATA/SOUND.AFS.files/000.afs.files/004.adx`:
2,058,240 bytes, stereo ADX type 3 at 24,000 Hz, 1,826,830 samples, SHA-256
`e24ecefa66fd1ba7cc6188a7984183cf30f655e95dd3e91deaba4f1430743ec5`.
NA2's same-numbered member is 2,115,584 bytes and is not identical. No exact
donor file occurs in NA2 SOUND; all 246 NA2 stereo ADX leaves across SOUND
and STREAM also share zero nontrivial aligned coded frames with this donor.
A separate decoded comparison covered all 246 leaves (73 SOUND, 173 STREAM;
161,392,641 stereo sample frames), following vgmstream's
[header/history parser](https://github.com/vgmstream/vgmstream/blob/master/src/meta/adx.c)
and [type-3/version-4 decoder](https://github.com/vgmstream/vgmstream/blob/master/src/coding/adx_decoder.c).
The donor's 1,826,830-frame signed-16-bit interleaved little-endian PCM has
SHA-256 `b150b80418c0205b228f3c6f4870d4870d16e54adb7dc98654f8149d59393ddd`;
no candidate has that hash. NA2 member 4 has 1,880,094 frames and PCM hash
`a96d8d6df6327dc7a7d45b5125208f78f263364cca0c7ac420a10b6663b36bd1`.

No matching recording was detected with decoded spectral fingerprints:
6,000-Hz mono, 1,024-sample Hann windows, 0.1-second hops, 33 logarithmic
bands from 80 to 2,800 Hz, and 32 bits describing adjacent-band change.
Every available 0.1-second lag and every 10-second window was compared;
17 short leaves used their full available 4.9–9.8-second fingerprints.
Highest 10-second agreement was 0.549375 (`STREAM/017`), followed by
SOUND/000/009 at 0.5490625; NA2 member 4 scored 0.5475. The maximum over
complete overlaps of at least 50 seconds was 0.517147117 (SOUND/000/035).
Gain 0.35 plus 8-bit PCM quantization and prefix offsets 1.000..1.100 seconds
in 10-ms steps gave a 10-second control floor of 0.7240625. A 16,000-Hz
resampled donor scored 0.9446875; self-comparison scored 1.0. Internal decode
consistency was checked, but external-decoder PCM parity was not.

This is evidence against the same recording under the checked transforms,
not proof excluding a different arrangement or tempo/pitch-altered version
of the composition. Musical title remains unidentified. NA2 selection rules
belong to [Battle audio](../session/battle_audio.md#battle-music-selection).

## Stage Select presentation

S01 is preview index 0. `stage_select_update_preview` (`0x006F5E40`)
and `stage_select_build_tv_objects` (`0x006F59D0`) both index pictures by
the raw slot.

`stage_select_load_name_and_preview_resources` (`0x006F5870`) resolves
`TEX_mapname01`, `MDL_pure_ita`, and `TEX_mappure01..04` from `mapsel1`.
The English DATAE and French DATAF `MAPSEL1.CCS` contain a 512×256 indexed
`TEX_mapname01`, four 512×512 indexed `TEX_mappure` atlases, and a separate
512×512 `TEX_mapsel02`. These images are stored bottom-up. `mapsel02` is a
texture in the MAPSEL1 container; its presence does not establish a separately
loaded container named mapsel02.

Big previews use six cells per texture: two columns spaced 256 pixels and
three rows spaced 168 pixels. For raw slot s, texture index is `s / 6` and
cell is `s % 6`; normalized offsets are `1 - column * 0.5` and
`1 - row * 0.328125`. S01's decoded picture occupies top-origin rectangle
`(0,0,256,168)` in `TEX_mappure01`. The TV builder uses normalized offsets
`(s % 5) * 0.1875` and `1 - (s / 5) * 0.140625`; decoded S01's 96×72 TV
image lies at `(0,168,96,72)` in `TEX_mappure04`. The image location and
the code's 96×72 offset steps establish the matching TV cell by visual
comparison; the inspected routine does not name its texture explicitly.

`stage_select_draw` (`0x006F7720`) reads the selected raw slot and indexes
`stage_name_rectangle_tables` (`0x00854540`) as five banks of 18 signed
halfword `(u,v,width,height)` rectangles, each bank 144 bytes. Resident
`ui_language_index` (`0x003F51D0`) supplies the bank. The English bank 0
S01 row is `(0,0,200,28)` and the French bank 1 row is `(0,0,184,28)`;
banks 2–4 duplicate the English rectangles. The draw crops one pixel from
every edge and scales width/height by 1.3: English effective source rectangle
`(1,1,198,26)`, French `(1,1,182,26)`. Decoding those first rectangles
reads **Hidden Leaf Village** and **Village de Konoha**, respectively.
These are NUN4 S01's retail localized display names.
