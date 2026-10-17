# NUN3 battle stages

## Research coverage

Established: archive compatibility, compiled records, construction routing,
update gates, selected prop states, the bounded summon switch/return path,
the per-stage camera, combo-anchor, route, intensity and music tables, Stage
Select preview and name assets, record translation evidence from the shared
stages, the archive conversion rules those stages show, S04's stage-specific
handlers, the landing-tree reaction, the glare's draw order, S01's flags,
wind sound and far-animation fog modes, S02's gondolas, faces and kite, and
S14's falls mist and bridge planks. Open: other prop states/teardown,
full scene binding, mode/effect meanings, texture-pixel sharing, complete
NA2 equivalence and Stage Select name-sprite rectangles. Names and
layouts come from
`@annotations/NUN3`; NA2 comparison names come from `@annotations/NA2`.

This document owns retail NUN3 (`SLUS-21727`) battle-stage behavior and
correspondence with retail NA2 (`SLPS-25837`). NA2 implementation belongs to
[Battle stage gameplay knowledge](stages.md).

## Evidence and address convention

Inputs and live address mapping belong to
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
NUN3 stage archives are the retail `DATA.CVM` extraction's `STAGE/` directory.
Evidence is static against `SLUS_217.27`, `BATTLE.BIN` and those archives;
sizes agree with each game's `GZLIST.TXT`.

Coverage includes all 28 NUN3 and 24 NA2 archives and all 27 NUN3 scene tables.
Content comparisons covered every NA2/NUN3 archive pair; texture comparisons
used raw payload hashes only. Construction coverage includes every authored
subtype. Complete state/derived-cleanup coverage is limited to
`0x801/0x871/0x803/0x813/0x81C/0x81D`; other parser comparisons are bounded.
The summon branches do not prove every battle mode, upstream scene binding
or indirect destruction path. Local invocation counts do not establish time.

Resident CCS types belong to
[Resident CCS object-type identities](../../game/files/ccs_object_types.md).
NUN3 `RPGSTAGE/` was not examined.

## Archive set and CCS format

**Observations:**

- NUN3 `STAGE/` holds `S01.CCS` through `S20.CCS` and eight summon archives,
  `KTYS_BNT`, `KTYS_KTY`, `KTYS_MND`, `KTYS_SKK`, `KTYS_SKK2`, `KTYS_SKR`,
  `KTYS_STR`, and `KTYS_TYO`. NA2 `STAGE/` holds only `S01` through `S24`.
- Every archive in both directories is a gzip CCS stream whose compressed and
  decompressed sizes equal that game's `GZLIST.TXT` entry, whose chunk-2
  version halfword is `0x123`, and whose section walk ends at the type-5
  terminator.
- The section tags used by NUN3 `S01` through `S20` are a subset of the
  resident dispatcher documented in
  [Resident CCS object-type identities](../../game/files/ccs_object_types.md):
  `0x0100..0x0400`, `0x0600..0x0B00`, `0x0C00`, `0x0E00`, `0x1300`, `0x1400`,
  `0x1900`, `0x2000`, plus one `0x0500` camera in `S12` and
  `0x0D80`/`0x0D90` generator records in `S10` and `S17`. NUN3 `S05` has three
  `0x0600` lights; every other `Sxx` archive in both games has exactly one,
  `LGT_dis_0`. No NUN3 stage archive contains a
  `0x2400` section or a `BIN_bgdata` object; every NA2 stage archive does.
- Decompressed sizes: NA2 `S01..S24` range from 531,692 bytes (`S17`) to
  1,323,828 bytes (`S24`). NUN3 `S01..S20` range from 1,032,152 bytes (`S13`)
  to 1,412,076 bytes (`S08`); 13 of the 20 exceed NA2's largest archive
  (`S01`, `S03`, `S04`, `S07`, `S08`, `S09`, `S12`, `S14`, `S15`, `S17`,
  `S18`, `S19`, `S20`).

| NUN3 archive | Compressed | Decompressed | NUN3 archive | Compressed | Decompressed |
| --- | ---: | ---: | --- | ---: | ---: |
| `S01` | 574,632 | 1,352,844 | `S11` | 495,333 | 1,149,440 |
| `S02` | 600,237 | 1,266,532 | `S12` | 801,730 | 1,367,924 |
| `S03` | 638,320 | 1,375,380 | `S13` | 459,399 | 1,032,152 |
| `S04` | 626,606 | 1,355,476 | `S14` | 730,753 | 1,399,060 |
| `S05` | 431,639 | 1,187,584 | `S15` | 559,613 | 1,388,844 |
| `S06` | 599,084 | 1,273,552 | `S16` | 530,068 | 1,083,280 |
| `S07` | 601,986 | 1,386,132 | `S17` | 616,814 | 1,394,120 |
| `S08` | 675,392 | 1,412,076 | `S18` | 591,845 | 1,360,832 |
| `S09` | 457,467 | 1,344,808 | `S19` | 617,828 | 1,351,304 |
| `S10` | 409,507 | 1,177,460 | `S20` | 671,990 | 1,404,100 |

**Confirmed shared encoding:** for NA2/NUN3 archive pairs that carry the same
stage content (next table), same-named `0x0800` model, `0x0100` object, and
`0x1300` dummy sections are frequently byte-identical, or identical in length
with differences only in words below `0x4000` (object-table indices, which
differ because the two archives number their objects differently). For
example, 198 of the 223 `MDL_` sections in NA2 `S14` match NUN3 `S16` this
way, and 209 of 223 `0x0100` sections do. Model, object, and dummy sections
therefore use the same payload encoding in both games; the two archives differ
in their object-table index references.

## Stage content already shared with NA2

Comparing hit-mesh payloads (ignoring their first four words), same-named
model sections, and dummy positions gives these pairs:

| NA2 archive (slot / logical ID) | NUN3 archive (table index, name) | Evidence |
| --- | --- | --- |
| `S08` (7 / 8) | `S07` (6, 木ノ葉の森, Konoha forest) | 38 identical and 36 index-only-different of 137 models; 3 of 7 hit meshes |
| `S09` (8 / 9) | `S03` (2, 第４４演習場死の森, Forest of Death) | 5 of 5 hit meshes; 65 identical of 68 dummies; line counts below |
| `S10` (9 / 10) | `S14` (13, 終末の谷, Valley of the End) | 5 of 6 hit meshes; 45 identical dummies |
| `S13` (12 / 13) | `S10` (9, ナルト大橋, Great Naruto Bridge) | 7 of 11 hit meshes; 48 index-only-different models |
| `S14` (13 / 14) | `S16` (15, 中忍試験会場, Chunin exam arena) | 198 of 223 models, 209 of 223 objects |
| `S15` (14 / 15) | `S18` (17, 短冊街のはずれ, Tanzaku outskirts) | 72 of 102 models; 35 identical dummies |
| `S16` (15 / 16) | `S13` (12, 君麻呂戦の草原, Kimimaro battle field) | 5 of 5 hit meshes; 132 identical dummies |
| `S23` (22 / 3) | `S15` (14, 物見やぐら, watchtower) | 60 of 78 models; 55 identical dummies |
| `S24` (23 / 4) | `S09` (8, 短冊街, Tanzaku Town) | 5 of 5 hit meshes; 83 identical dummies; line counts below |

No pair is an identical copy: every pair also has differing models,
animations, and dummies. Texture sections were compared only by raw
payload hash, and none matched; whether texture pixels are shared was not
established. No match of
this kind was found for NUN3 `S01`, `S02`, `S04`, `S05`, `S06`, `S08`, `S11`,
`S12`, `S17`, `S19`, or `S20`, nor for NA2 `S01..S07`, `S11`, `S12`, or
`S17..S22`.

## NUN3 stage table and scene records

NUN3 compiles scene configuration into `BATTLE.BIN`. Neither its resident
ELF nor battle overlay contains a `BIN_bgdata` parser,
`takaCreateBackGround` string, or `ccBg*`, `ccField`, `ccBgControl`
class names.

`stage_scene_tables` (`0x00913450`) contains 27 pointers and a null
terminator. Each points to a zero-terminated sequence of 32-byte
`Nun3StageRecord` entries.

| Field | Meaning |
| --- | --- |
| `label` | Shift-JIS label; empty for unlabeled records. |
| `type` | Category in bits 8..15, subtype in bits 0..7. |
| `primary_resource`, `secondary_resource`, `tertiary_resource` | Resource-name pointers, or null. |
| `tokens` | Consecutive NUL-separated configuration tokens selected by `string_nul_token`. |
| `parameter_a`, `parameter_b` | Signed integers, -1 when unused; full meanings remain unassigned. |

Every table starts with type 1: its label is the stage name and its primary
resource is the archive path.

| Index | Archive | Label |
| ---: | --- | --- |
| 0 | `stage/s01.ccs` | ラーメン一楽 |
| 1 | `stage/s02.ccs` | 歴代火影の顔岩 |
| 2 | `stage/s03.ccs` | 第４４演習場死の森 |
| 3 | `stage/s04.ccs` | 英雄の慰霊碑 |
| 4 | `stage/s05.ccs` | 桔梗城天守閣 |
| 5 | `stage/s06.ccs` | 木ノ葉温泉 |
| 6 | `stage/s07.ccs` | 木ノ葉の森 |
| 7 | `stage/s08.ccs` | 風影の屋敷 |
| 8 | `stage/s09.ccs` | 短冊街 |
| 9 | `stage/s10.ccs` | ナルト大橋 |
| 10 | `stage/s11.ccs` | 砂肝亭と仏像 |
| 11 | `stage/s12.ccs` | 音忍戦の森 |
| 12 | `stage/s13.ccs` | 君麻呂戦の草原 |
| 13 | `stage/s14.ccs` | 終末の谷 |
| 14 | `stage/s15.ccs` | 物見やぐら |
| 15 | `stage/s16.ccs` | 中忍試験会場 |
| 16 | `stage/s17.ccs` | サバイバル演習場 |
| 17 | `stage/s18.ccs` | 短冊街のはずれ |
| 18 | `stage/s19.ccs` | ザブザの隠れ家 |
| 19 | `stage/s20.ccs` | 修練の崖 |
| 20..26 | `stage/ktys_skk/str/bnt/kty/mnd/skr/tyo.ccs` | 口寄せ（…）summon scenes |

`stage_unused_skk2_archive_path` names `stage/ktys_skk2.ccs`, which is absent
from this table and the character-to-summon-scene mapping below.

## Per-stage camera, anchor and route tables

All three readers index their table by `Nun3StageBattleContext.scene_index`,
the same index as `stage_scene_tables`, without a range check.

| Table | Live base | Entries | Reader |
| --- | --- | --- | --- |
| `stage_camera_records_by_scene` (resident `0x00477320`) | 27 pointers and a null terminator into `camera_stage_tracking_gains` (`0x00476900`), `0x60`-byte `Nun3StageCameraRecord`s | `camera_bind_stage_record` (`0x00234D80`) saves camera `+0x18C` to `+0x190` and installs the record; `camera_initialize` (`0x00234BA0`) first installs record 0 |
| `stage_combo_anchors` (BATTLE `0x009297B0`) | 20 `0x10`-byte `Nun3StageAnchorRecord`s: side 0/1 array pointers at `+0/+4`, byte counts at `+8/+9` | `stage_choose_combo_anchor` (`0x007C1F60`) |
| `stage_navigation_authored_routes` (BATTLE `0x009192D0`) | 20 pointers to `Nun3StageRouteRecord` lists ending at source `-1` | `stage_navigation_initialize` (`0x008257F0`) |

The anchor reader selects the input side's array, keeps the nearest vector
(the first on ties) and then forces the return side: 0 for scene indices
1/10/15/16/18 and 1 for 2/4/5/12/13/14. The route reader copies the list
into the 64-record `stage_navigation_routes` (`0x00945920`) and fills the rest with source
and destination `-1`. For scene 15 it moves line index 3's component-0 ends
from -400/400 to -415/420; for scene 5 a line condition sets the second work
record's fraction to 0 and type to 3.

These are NA2's layouts and readers. Of the nine
[shared-content pairs](#stage-content-already-shared-with-na2), eight have
byte-identical camera records: NA2 slots 7, 8, 9, 12, 13, 14, 15 and 22
equal NUN3 scenes 6, 2, 13, 9, 15, 17, 12 and 14; NA2 slot 23 and scene 8
differ. Anchor arrays are byte-identical for NA2 slots 8, 15 and 22 (scenes
2, 12 and 14), and route entries for NA2 slots 7, 8, 22 and 23 (scenes 6, 2,
14 and 8). The route numbering is therefore NA2's first-family line
numbering.

S04 (scene 3) has no NA2 counterpart in any of the three tables and no
scene-specific branch in these readers:

| S04 data | Value |
| --- | --- |
| Camera record, `0x00476D20` | 0.65, 0.3, 0.15, 0.05, 0.03, 0.65, 0.65, 0.15, 0.175, 0.03, 600, 4500, 1000, -1000, 1200, -1200, 1500, 200, 0.8, 5, 10, 1.2, 0, 0 |
| `stage_s04_combo_anchors_side0` (`0x00912A70`) | one vector (-50, 0, 50, 1) |
| `stage_s04_combo_anchors_side1` (`0x00912A80`) | c0 = -550, -450, -350, -250, -150 at (c1, c2) = (1100, 50), c3 = 1 |
| `stage_s04_navigation_routes` (`0x00918550`) | 3→2 at 0.2 type 1; 2→3 at 1 type 3; 3→1 at 0.75 type 1; 1→3 at 0 type 3 |

S04's routes use lines 1..3, numbered from its category-14 counts: one
front and three back `cl` lines.

`stage_apply_render_coefficients` copies `stage_render_coefficients`
(BATTLE `0x00929AA0`, two floats per `scene_index`) into the battle render
descriptor's `+0x28` and `+0x24`, the fields NA2's factory 17 sets from its
tokens 0 and 1: 0.45/0.35 for S01 and 0.2/0.45 for S04.

Two resident byte/word tables are also indexed by `scene_index`:

| Table | Contract | S04 |
| --- | --- | --- |
| `effect_4a_stage_intensity` (`0x004F78A0`), 27 bytes | `effect_4a_secondary_update` (`0x001FF710`) passes the byte, or `0xBF` without a context or for an index of 28 or more, to `effect_4a_submit_tint_packet` mode 2. That packet is NA2's `0x002C80C0` mode-3 packet with the byte as RGB. | `0x7F` |
| `stage_music_tracks` (`0x00388E20`), 27 words | The battle music preset at `0x001860F0` passes the word as the member of sound descriptor 0 to `audio_select_music_track`. Descriptor 0 is `SOUND.AFS` partition 0, 89 members. Scenes 0..19 use members 5..24. | member 8: stereo 48 kHz looped ADX, 2,721,271 samples |

Six of the nine shared-content pairs keep NUN3's intensity byte; NA2 slots
8, 9 and 15 change scenes 2, 13 and 12's `CF`, `AF` and `5F` to `AF`, `5F`
and `6F`. NA2's battle tracks are 24 kHz.

## Stage Select presentation

Stage Select loads `MAPSEL1.CCS`. `stage_select_bind_resources`
(`0x0082FF30`) binds `TEX_haipure01` through `TEX_haipure04`, all 512×512
8-bit, and `stage_select_initialize_choices` (`0x00830180`) lists scene
indices 0..19 in order.

`stage_select_bind_preview` (`0x008309B0`) draws the big preview of scene `s` from atlas
`haipure(s / 6 + 1)`. With `r = s % 6`, the 256×168 cell is column 0 for
`r < 3` and column 256 otherwise, at row `(r % 3) * 168`, in top-down
texture coordinates.

The small previews are 20 parts of `MDL_purepanel`, `OBJ_sam01` through
`OBJ_sam20` (`stage_select_transform_thumbnail`, `0x00830B20`, formats `OBJ_sam0%d`/`OBJ_sam%d` from choice
position + 1). Their models carry fixed UVs into the `haipure04` grid at
`(256..512, 0..240)`, 64×48 cells with a 2-pixel border, which hold
different shots from the big previews.

| S04 asset | Top-down rectangle |
| --- | --- |
| Big preview | `haipure01` `(256, 0, 256, 168)` |
| Small preview (`MDL_sam04` UV u 225..255, v 233..255 in 1/256 units) | `haipure04` `(450, 2, 60, 44)` |

`TEX_mapname` holds the English names; S04's is "Hero's Memorial Monument"
on two lines. Which code selects each name's rectangle was not traced.

## NUN3 summon selection and archive lifetime

`summon_scene_row` accesses eight `Nun3SummonSceneRow` entries in
`summon_scene_mappings` (`0x00673590`), each holding mapping index,
character ID, scene index and a zero word.

| Mapping index | Character ID | Scene index | Archive |
| ---: | ---: | ---: | --- |
| 0 | `0x04` | 20 | `stage/ktys_skk.ccs` |
| 1 | `0x10` | 21 | `stage/ktys_str.ccs` |
| 2 | `0x15` | 22 | `stage/ktys_bnt.ccs` |
| 3 | `0x01` | 22 | `stage/ktys_bnt.ccs` |
| 4 | `0x19` | 23 | `stage/ktys_kty.ccs` |
| 5 | `0x09` | 24 | `stage/ktys_mnd.ccs` |
| 6 | `0x07` | 25 | `stage/ktys_skr.ccs` |
| 7 | `0x0E` | 26 | `stage/ktys_tyo.ccs` |

`summon_scene_mapping_for_character` returns the matching mapping index or
-1; `summon_scene_index` resolves it to a scene. Character IDs are not
stage slots; two characters share scene 22. `battle_request_summon_scene`
accepts precisely the eight IDs and publishes the scene, request bit and
side plus one in `Nun3StageBattleContext`.

`summon_sequence_update` (`0x002E4900`) preloads before publication.
State 2 at `Nun3SummonSequence.counter == 85` maps the character and calls
`battle_preload_stage_archive`. It waits for `archive_queue_busy` to
return zero, cleans up, and publishes the request in state 4. The partial
sequence type names only the established signed counter; the remaining
owner layout is unassigned.

| Helper | Contract |
| --- | --- |
| `stage_queue_archive` | Queue the first record's path with loader argument 0. |
| `stage_load_archive` | Find or synchronously load the archive and retain its handle. |
| `stage_require_archive` | Require an already loaded archive and retain its handle. |
| `stage_release_archives` | Destroy/clear four tracked handles, then look up/free `ojmgmk`, `ojmgmt`, `ojmpkn`, `ojmnkm`. |

Handles are `stage_tracked_archives` (`0x00945910`); extra names are
`stage_auxiliary_archive_names` (`0x009133D0`).
`ccs_find_container` and `ccs_require_container` normalize names; absence
returns zero in the former and traps in the latter. Neither inspected lookup
increments an ownership counter. `ccs_destroy_container(handle, 1)`
unlinks, destroys and frees the archive. Retaining a handle does not establish
reference-counted ownership. The index-taking helpers and resident preloader
skip null table pointers but do not range-check indices.

`battle_stage_transition_update` (`0x00287630`) establishes this ordering:

1. State `0x12` destroys the battle owner. With
   `summon_side_plus_one != 0`, save `scene_index` into `saved_scene`,
   adopt `pending_scene`, queue/commit its archive and enter state 8.
   The release branch requires a zero side field.
2. State 8 waits for loader and transition fence, requires the loaded archive,
   then constructs the next owner. `battle_classify_stage_scene` sets
   `scene_class = 2` for indices 20..26 and 1 otherwise.
3. `battle_active_scene_update` can request return with class 2, its owner's
   raw halfword `+0x08 == 5`, context `flags & 0x20`, and both calls to
   `battle_participant_check` returning zero. That helper reads a global
   owner's child state; its gameplay role remains unassigned. Publish
   `saved_scene` as `pending_scene`, clear side, set request bit and
   `transition_reason = 11`.
4. State `0x0C` for class 2 releases the summon archive, restores the saved
   index, requires its archive, reclassifies, then releases again. This branch
   does not queue the saved archive again.

The constructor uses the same scene index. These branches establish selection,
preload, publication, switching and restoration ordering; complete scene
binding and all destruction paths remain open.

## NUN3 scene-record dispatch

`stage_scene_construct` (`0x007C26C0`) publishes the scene index to two
optional owners, walks records through `stage_category_dispatch`
(`0x00929B90`), then performs fixed setup.

| Category | Handler | Behavior |
| ---: | --- | --- |
| 0 | `stage_scene_construct` | Adopt archive basename, resolve `BLT_bg`/`BLT_obj`, retain index. |
| 1 | `stage_parse_fog` | Seven tokens: RGB, near/far distances, then far and near percentages: the parser stores tokens 5/6 in that order and passes token 6 as `fog_set_distances_and_percentages`'s near percentage. That routine maps percentages through `(100-p)*2.55` with a linear ramp. |
| 2 | `stage_parse_category2` | Empty; authored `0,-2750,800` tokens have no effect. |
| 3 | `stage_parse_far_objects` | Far/sky/effect objects; prepare doll nodes after each record. |
| 4 | `stage_parse_base_animation` | Subtype 1; first model fills empty `base_model`. |
| 5 | `stage_parse_animation_props` | Animations, particles/deformation and props. |
| 6 | `stage_parse_transparent_objects` | Transparency and frame animation. |
| 7 | `stage_parse_creature_props` | Creatures, flags and props. |
| 8 | `stage_parse_reactive_props` | Breakable/moving objects; doll record may create many objects. |
| 9 | `stage_parse_category9` | Empty; no retail records. |
| 10 | `stage_parse_player_nodes` | `プレイヤー１/２`; token 3 names `DMY_pp1_010`/`DMY_pp2_010`. |
| 11 | `stage_parse_line_nodes` | Front/back token 3 names `DMY_line_010`/`DMY_line_020`; token 5 counts family nodes. |
| 12 | none | Skipped; `0xC0A` occurs in three stages. |
| 13 | `stage_parse_lighting` | First resource is light animation (always `ANM_stalig00`); names follow `LGT_dis_%d`. |
| 14 | `stage_parse_cl_lines` | Front/back token 5 counts `DMY_{f,b}_cl_N_*` lines. |

Every authored category-3..8 type has a construction branch. Census counts
belong to handler annotations; later state machines are not all established.
`Nun3StageControl.object_lists` orders `far_objects`, `base_objects`,
`animation_props`, `creature_props`, `reactive_props`, `category9_objects`,
then `transparent_objects`. Their `Nun3StageVector` headers hold capacity,
count and pointer storage; `stage_vector_append` owns insertion.
Record counts may be smaller than constructed-object counts.

`stage_object_construct` and `stage_object_initialize_model` establish
common `Nun3StageObject` ownership. Stored `initialization_category`
need not equal record category: `0x79B` receives 5 and `0x601` stores
`subtype = 0x12`. `stage_object_draw_model` submits the model;
`stage_object_destroy` releases both models and optionally itself.
Derived arrays/controllers require their own cleanup.

Seven draw consumers require `disabled == 0`. Seven update consumers also
require that, and consult `updates_when_restricted` only with a nonzero
scene restriction mask. With no restriction the opt-in byte is ignored.

`stage_scene_update` (`0x007C24C0`) builds restrictions, then calls
`stage_update_permission(scene, 1)`, which permits. The effective
whole-scene gate is `updates_blocked`. When clear, `fade` changes by
0.05 toward zero/one according to `fade_out`. Mask bits
`1/2/4/8/0x10/0x20/0x40` map to the seven stored lists. Reactive props run
before creature props; category 5 uses the control's virtual dispatch.
Omitting a bit prevents that list's callbacks.

`stage_build_update_restrictions` clears its mask on each invocation and,
when a battle context exists, can set:

| Bit | Established condition |
| ---: | --- |
| 1 | Scene `updates_blocked` nonzero. |
| 2 | Context `restriction_owner` exists with word `+0x34 == 1`. |
| 4 | `stage_restriction_predicate` nonzero; complete retail body returns zero. |
| 8 | Chained mode words `(5,0)` and the optional `Nun3StageRestrictionOwner` has a nonzero restriction byte or halfword. |
| `0x10` | `battle_scene_restriction_active` on context embedded block `+0xAC0` is nonzero. |
| `0x20` | Another global owner's `+8` child exists with word `+0x10 == 2`. |
| `0x40` | Context `transition_reason` nonzero. |

Bits `0x8..0x40` additionally require the mode owner. The meanings of all
conditions are not established. Category-8 construction sets the opt-in, so
those objects remain eligible under restrictions, subject to outer gates.
Local counters count invocations: rotating sky adds `0.98 * angular_speed`
directly, while frame animation advances by `playback_step`; neither
derives seconds.

Category 11's index-0 counts 2/18 match `S01`; category 14's index-3 back
count 3 matches `S04`'s `DMY_b_cl_1_ewr`, `DMY_b_cl_2_ewr` and
`DMY_b_cl_3_nor`. Both games use `DMY_linemin01/02`,
`DMY_linemax01/02` and `DMY_%scl_%d_nor/ewr/mov`.
Representative labels/resources below count the 20 normal tables.

| Type | Normal tables | Example label (gloss) and resources |
| --- | ---: | --- |
| `0x301`, `0x38A`, `0x390`, `0x392` | 20, 8, 4, 3 | sky/far animations; `回る空` (rotating sky), `最遠景グレア` (far-view glare) |
| `0x401` | 20 | main stage animation `ANM_*are00` |
| `0x502` | 5 | `電線` (electric wire) with `DMY_dummy_010`/`020` endpoints |
| `0x526`, `0x528`, `0x582`, `0x583` | 8, 3, 9, 1 | swaying grass, leaves, and trees (`OBJ_eda_*`, `CMP_ki_*`) |
| `0x52B`, `0x52D`, `0x51B` | 8, 3, 6 | falling, rising, and blowing leaves (`CMP_*efe*`) |
| `0x579`, `0x57B`, `0x57D`, `0x587` | 1 each | water surface, rowing boat, mangrove, suspension bridge |
| `0x578` | 1 | `足跡` (footprints) |
| `0x595..0x59E` and other `0x5xx` | 1..2 | stage-specific effects (memorial water, hot-spring steam, waterfalls) |
| `0x601`, `0x690` | 7, 8 | `透過柱` transparent pillars with `DMY_*has*_hit` and a configured contact scalar; frame animations |
| `0x7xx` | 1..2 | stage creatures and props (toad, snake, spiders, fish, flags) |
| `0x81C`, `0x81D` | 20 | `訓練君` / `うっきー君` training dolls with `DMY_dd_010`/`DMY_pg_*` and break objects |
| `0x801..0x87C` | 1..5 | breakable props with `_n1`/`_d1`/`_n2` animations and `OBJ_bre_*` debris |

## NUN3 object parsers and concrete comparisons

`string_nul_token`, `string_parse_decimal`, `string_parse_floating_value`
and `soft_double_to_float` interpret configuration text. Layout stores and
controller construction belong to the routine annotations.

| Type | Parser | Authored contract |
| --- | --- | --- |
| `0x301` | `stage_animation_parse` | Token 10 Boolean, which `model_set_child_parameter` writes to bits 3-4 of each model child's `+0xA8` flags: the fog mode NA2 keeps in bits 0-1 (`model_draw_select_fog`: bit 0 distance fog, bit 1 the fixed percentage). S01's `are01`/`are02` set 1 and `are03` 0; base models keep 3. |
| `0x38A` | `stage_rotating_sky_parse` | First resource is animation; token 10 float speed; random initial angle over ±pi. `stage_rotating_sky_update` adds 0.98 × speed every update and wraps at ±pi. |
| `0x390/0x590/0x690` | `stage_frame_animation_parse` | Shared parser; nonzero token 10 integer divides model playback step. |
| `0x392` | `stage_glare_parse` | Tokens 7/8/9/10 are mode, packed colour, float amount, packed colour; draw submits up to three resource models plus controller. |
| `0x502` | `stage_wire_parse` | Second/third resources are endpoints ordered by component 0; texture token 6; 15 interior nodes, three arrays and segment/controller storage. |
| `0x507`, `0x506` | `stage_sway_animation_parse` (`0x007E58A0`) | Token 5 pieces: the record's animation and `_1`.. siblings, at the token-3 node and its `_1`.. siblings, each with a random phase and amplitude 0.1 + rng(0.3) (mode 0), or 0.025 + rng(0.01) when the label holds the lantern string (mode 1); `0x506` is mode 5. |
| `0x518` | `stage_wind_parse` | One wind per scene: after a hold of 10 × 60 / frame divisor updates (300 at 30 updates per second) the phase advances a degree per update with `stage_wind_strength` = sin(phase); it holds at +1 (phase 90), 0 (180) and -1 (270), and after 360 rests 25 × 60 / divisor updates. `stage_wind_update` starts common sound `0x3E` (velocity `0x40`) on its first update and, outside holds, places it at the camera eye plus (550 w − 600, 6000 \|w\| − 6000), or 6000 below while `battle_restriction_check` reports a restriction. `audio_position_velocity` gives volume × max(0, 5500 − distance) / 50 / 100 and `audio_position_direction` always centres it. The sound plays the same sample, split and sample record as NA2's common sound `0x27`. |
| `0x51B` | `stage_flying_leaves_parse` | A generator from `stage_flying_leaves_generator_parameters` and `stage_flying_leaves_force` with token 8 as lifetime, token 7's composition as its material, token 4 scale and distance fade 100/22000/500/20000. `stage_flying_leaves_update` puts its origin token 3 ahead of the camera along the view, offset upwind by token 10, sets the force's x to token 9 × -wind and the alpha scale to the wind's magnitude, or 0 below 0.3. |
| `0x52D` | `stage_rising_leaves_parse` | Token 7 composition, token 0 section, tokens 1/2 x range and 3/4 height range. `stage_rising_leaves_update` starts leaf generators at a fighter in states (1, 0x15/0x16) or (5, 0x42/0x43/0x45) inside them, up to six per kind. |
| `0x601` | `stage_transparent_parse` | Token 3 hit/position node; token 8 plus 150 contact divisor; a radius-150 receiver with mask `0x108` at the node. `stage_transparent_update` takes the nearer fighter's contact distance / divisor, 1 without contact, raises the fade by a tenth of that when it would rise more than 0.1, and sets opacity to fade × `bg_animation_limit(700)`. |
| `0x79B` | `stage_flag_parse` | Token 7 texture at the token-3 node, tokens 8/9 width and height × 4, token 10 solver selector; a 4 × 6 cloth with `stage_flag_constants` on the cloth solver NA2's factory 6 also uses. `stage_flag_update` blows it with w = −`stage_wind_strength`, at least ±0.005: force 5000 w along the normalized (0.5 w + rng(0.5), rng(0.02), rng(0.02)), then one solver step of 0.064. `stage_flag_draw` widens the render context's clip bounds by a tenth while the cloth draws. |
| `0x50C` | `stage_gondola_parse` | Token 3 node, token 1 wait × 30 updates, token 10 `line,list,amplitude,doll node`; list 2 is the back `cl` lines. `stage_gondola_update` stops while the battle director's state is 2 (`battle_state_is_2`); otherwise it steps its `curve_step` curve and moves the model, the selected line's two endpoints and the prepared doll node by their offsets. Each move (`stage_gondola_next_move`) rises `rand % amplitude`, or falls that far when the rise would pass the node's height + amplitude, through points at 1/2, 3/4 and 7/8 of it, at `curve_restart`'s random 0.03..0.045 speed with a 90-update end hold, then waits. S02's two gondolas carry back lines 1/2, the `DMY_b_cl_N_mov` pairs, and doll nodes 3/4. |
| `0x711` | `stage_face_rock_parse` | `stage_breakable_parse` with debris parameters (200, -200, 40, -10, 20), named damage animations `<d1>` and `<d1>_N` for each hit before the last, and the position and first attack sphere lowered 300. `stage_face_rock_trigger` binds the next damage animation with prop effect 5, and on the last hit the broken animation with effect `0xB`, crediting the attacker's side. The scene also keeps each face's position. |
| `0x81E` | `stage_kite_parse` | Token 3 start node and its `_1` center, token 1 absence × 30 updates, token 0 hits, tokens 8/9 as for breakables; receivers at the center's depth. `stage_kite_update` waits out the absence plus up to 0.4 of it, approaches the center along a `stage_kite_first_approach` curve, then flies `stage_kite_legs` legs between eight `stage_kite_lay_waypoints` around the center at 0.015, bobbing 10 × the 72-sample sine table in height, rolling by 0.2 + \|rng(0.3)\| of it and turning toward its heading by `angle_turn_toward`. Whenever its idle ends it replays at a random 1..1.5 speed. The breaking hit plays the third animation, drops it along a 0.07 curve 100/250/450 down while its opacity falls 0.02 per update (`stage_kite_flee`), and it then returns to the start for the next absence. |
| `0x58E` | `stage_falls_mist_parse` | Token 6 is read but unused; thirteen looping generators from `stage_falls_mist_rows` (generator and three field descriptors, origin, second point, alpha), each with S14's `EFF_s8aefe08` as its material, distance fade off, in `primary_draw_environment`. `stage_falls_mist_update` switches them to the current draw environment while `battle_restriction_check` reports a restriction; `stage_falls_mist_destroy` stops them with deferred stop 1. |
| `0x59E` | `stage_forest_effect_parse` | Three looping generators from `stage_forest_effect_rows` laid out as the falls-mist rows plus a scale, each with token 7's effect (`EFF_s2cefe08`) as its material. `stage_forest_effect_destroy` sets each live generator's `+0x34` and deferred stop 1. Its update hides them under the same restriction as the falling leaves. |
| `0x52F` | `stage_rainbow_parse`, `stage_rainbow_update` | Token 3 object (`OBJ_s2cefe07`) at (400, 700, -25), scale (7, 1, 7); while neither primary fighter's `+0x946` byte is set, opacity is (1600 - camera distance) / 1600 clamped to 0..1, otherwise 0. `stage_rainbow_draw` draws it in stage draw environment 2. |
| `0x52B` | `stage_falling_leaves_parse` | Token 3 node, token 7 composition; generator row token 8 of `stage_falling_leaves_generators` with force row token 9 of `stage_falling_leaves_forces` and spin row 0, scale token 10, playback 2, distance fade 100/500. S03 uses rows 1/2 (fall -2) at 0.25, S04 and S16 rows 0/1 (fall -7) at 0.5. `stage_falling_leaves_update` applies the restriction visibility; its wind rewrite of the rows reaches no generator, which copies its rows when made. |
| `0x746` | `stage_fish_parse`, `stage_fish_update` | Token 3 swim node and its `_1` leap point, `<record animation stem>_n1` swim and `_a1` leap, token 1 wait × 60 / frame divisor. `stage_fish_swim`, `stage_fish_to_leap`, `stage_fish_airborne` and `stage_fish_dive` follow curves at speed 0.025: swim through points up to ±100 and ±120 in depth back to the node; leap from the fish with depth -150 to the leap point with depth +150; dive back. Countdown wait - rand % (wait / 2) before each leap. Two radius-100 receivers (send 1, receive `0x210`) at the leap point, the second 80 higher, are active only in the air; `stage_prop_contact_accepted` hit gives a field item from `stage_fish_items` 200 above the leap point at depth `+0x64`, prop effect 3 with sound `0x12` and `stage_doll_increment_side_counter(0)`. `stage_water_splash_small` at leap frames 8 and 25; while swimming above height 32.5, one of five `effect0x` `ANM_e0x_move_02` rings every 10 updates at height 50. |
| `0x587` | `stage_bridge_parse` | Tokens 1/2 endpoints, 3 segment-node stem, 5 segment count, 6 texture, 7 model, 8/9 floats, 10 byte; three model/rope/helper arrays. |
| `0x801/0x871`; `0x803/0x813` base | `stage_breakable_parse` | Token 0 count; 3/4 position nodes; 5 shape count; 7 debris; 8/9 integer-derived dimensions; 10 pose/sequence integer. Second/third resources are later animations. Token 5 attack spheres of radius token 9 × 2, mask `0x210`, at `DMY_<stem>_hit` and its `_1`.. siblings; one proximity sphere of radius token 8 + 150, mask `0x108`, at the token-4 node with the first hit node's component 1. |
| `0x863` | `stage_breakable_parse` | As `0x801`; token 10 names the shadow object, and its `<token 10>s1` model child has its fog bits cleared, so the shadow draws without fog. |
| category 13 | `stage_parse_lighting` | Token 10 `r,g,b` sets the light colour /255. Without a comma the light keeps its animation's colour, which lights the models (S01: 247, 240, 223 in the per-draw light block), while the render environment's light colour (`+0x70`) stays (1, 1, 1). |
| `0x81C` | `stage_construct_training_dolls` / `stage_training_doll_parse` | Token 5 controls doll count; each borrows one prepared node and determines its section. |

`stage_prepare_doll_nodes` follows every category-3 record. If
`doll_nodes` is absent it scans the table for `0x81C` and invokes
`stage_build_doll_nodes`. That helper reads stem/count tokens 3/5 and
allocates the prepared-node and flag arrays. Node zero uses the stem;
subsequent nodes use `stage_indexed_node_format` (`%s_%d`), such as
`DMY_dd_010_1`. All 20 normal tables containing a training doll put category
3 first. This ordering supplies the prepared nodes before doll construction,
which can create several objects from one record.

## NUN3 reactive-object states and derived cleanup

These states cover `0x801/0x871/0x803/0x813/0x81C/0x81D`; other category-8
state machines and derived cleanup remain open.

`stage_breakable_prepass` resolves contact only with
`stage_contact_mode_blocked` false and a receiver contact present.
`stage_breakable_resolve_contact` rejects descriptor
`flags & 0x00F00000`, `flags & 2` or `secondary_flags & 0x02000000`.
Acceptance marks contact and unregisters the receiver; completion clears
the mark. The prepass also produces a triangular pulse and latches render
contact. The predicate's full mode meaning remains open.

`stage_breakable_trigger` accepts contact only with remaining count not -1.
Count below 2 becomes -1, selects the broken animation if present, enables
optional debris and unregisters the attack receiver. Larger counts lose one,
select the damaged animation if present and dispatch a stage effect.
`stage_breakable_update` updates debris and animation. Positive count,
pending reaction and animation completion re-register both receivers.
Broken objects can select their later animation and seek to the configured
pose; this seek is not a periodic increment. Types `0x801/0x871` share
`stage_breakable_vtable` and this update.

`model_advance_animation` uses 256 units per frame, clamps at
`(frame_count-1)*256` and returns completion; a loop flag can reset it to
zero and return false. Scoped methods normally pass `playback_step`.
`model_set_child_parameter(model, 3)` propagates a child parameter without
setting the loop flag. A transition can advance after replacing an animation
and again later in the same invocation; one update need not mean one advance
or one frame.

| Type / role | State behavior |
| --- | --- |
| `0x803`, lanterns | `stage_lantern_motion`: contact restores amplitude and local value 30. `Nun3StageLanternContactEntity.phase_selector` values 1/0 select phase 0/36; other values keep phase, absence selects 0. Phase advances by 2; samples scale amplitude. Each wrap decays amplitude by 0.6 with floor 0.05; positive count permits receiver re-registration. Transform uses sample and 0.3×sample. Contact side is retained and `stage_lantern_contact_effect` selects three parameter paths from `effect_mode`. |
| `0x813`, wind bells | `stage_wind_bell_motion`: contact resets phase, restores amplitude and local value 30. Phase advances by 2 through the same table; at its end amplitude decays by 0.6 with floor 0.05, phase resets and positive count permits receiver re-registration. Transform combines sample with 0.3×a resident scalar whose producer is unidentified. |
| `0x81D`, `うっきー君` | `stage_monkey_doll_update` shares count/animation/contact transitions; parser triples the base shape dimension and adds 50 to its offset. This update has no randomized doll-respawn delay. |
| `0x507` mode 0, noren | `stage_sway_animation_update` (`0x007E5C90`): angle = amplitude × `stage_sway_sine`[phase], phase advancing by 1; rotation (angle, 0, 0.3 × angle) about the piece's node. At the table's end the amplitude decays by 0.6, and below 0.1 becomes 0.2 + rng(0.3). Modes 5 and 2 add 0.7 and 0.5 × the wind scalar `0x006A3BB8` to the amplitude; mode 1 rotates about component 1 and does not decay. `stage_sway_tables_init` fills `stage_sway_sine` with 72 samples of sin(5i°), sample 36 at 3.14 radians. |
| `0x81C`, `訓練君` | `stage_training_doll_update` adds delayed appearance, a separate sequence and node-following reset. |

Training-doll token 1 sets `delay_base = D = 10 * integer(token 1)`;
token 10 sets initial/configured sequence. `stage_training_doll_reset`
zeros elapsed, restores sequence and chooses
`delay = D - (R % trunc(0.4 * D))`. The divisor must be nonzero; the
recovered token-1 example is 10, giving D = 100.

Before elapsed reaches delay, count becomes -1, elapsed increments once and
contact/animation handling is skipped. At equality the doll selects
`ANM_anm_doll_a1`, advances, restores count and increments beyond equality.
Later completions use `ANM_anm_doll_n1` for positive sequence steps and
`ANM_anm_doll_v1` at zero, decrement sequence and explicitly disable/re-enable
the receiver around selected transitions. A negative step or broken doll with
the retained contact/debris conditions schedules another random delay.
In scene 3, retained broken contact calls `stage_doll_increment_side_counter`
and `stage_doll_set_side_value` with contact side. Their writes are annotated;
their gameplay effect meanings remain unassigned.

The doll borrows `prepared_node`; active updates copy its position to model,
contact shapes and optional debris. Contact offsets are -100/+100 from that
node versus the parser's initial -150/+100. It does not own or free the scene's
node array. Elapsed increments per eligible invocation; seconds are unassigned.

`stage_training_doll_destroy`, `stage_monkey_doll_destroy`,
`stage_lantern_destroy` and `stage_wind_bell_destroy` reset derived state,
install the base vtable and invoke `stage_breakable_cleanup`.
They release shape/controller/debris resources, both receivers and common
models, then optionally themselves. This proves local derived teardown, not
every scene destruction entry path or ownership of the stage archive/borrowed
node.

## Parser-format differences

Concrete NA2 comparisons use `bg_rotating_sky_parse` (`0x003986F0`),
`bg_glare_parse` (`0x00398C40`) and `bg_electric_wire_parse`
(`0x006C84D0`).

| Behavior | NA2 inputs | NUN3 inputs |
| --- | --- | --- |
| Rotating sky | Resource/node tokens 0/1, float scale 2, initial integer angle 3 (-1 random), speed 4. | Animation in first record resource; speed token 10. |
| Glare | Pack tokens 0..3 and 5..7 into colour words; mode 8, floats 4/9. Every retail record is in selector 5 (draw key 10), after the scene. | Already-packed integer colours 8/10; mode 7, float 9. `stage_glare_draw` draws the record's models in a draw environment keyed -5122 and the glare in one keyed -5121, ahead of the stage's own environments (-5120, -2304, 15), so the glare samples only those models. |
| Wire | Endpoints/texture tokens 0/1/2; fifteen interior nodes and three arrays. | Endpoints in second/third record resources; texture token 6; parallel node/array setup. |
| Suspension bridge | Token contract in [Stages](stages.md#animated-and-breakable-background-evidence). | Segment/model/endpoint token positions differ as listed above. NUN3 S14 reads its 17 plank positions from the base model's empty `OBJ_hasi_aN` placeholders, which `ANM_s8aare00` places; NA2 reads `<stem>_aN` dummies. The rest of the parse matches `bg_bridge_parse` step for step. |
| Transparency | `ccBgTransObject` uses token 4 radius and fighter-distance easing. | Token 8 plus 150 and collision-contact scalars. |

Related scene responsibilities do not make these formats interchangeable.
Both games' glare objects use the same effect class (`pause_auxiliary_refresh`
initializer, `ccfm_sampling_pass_submit`) with byte-identical pass settings.

## Correspondence with NA2 records

**Confirmed:** every one of NUN3 `S01..S20` contains all node and resource
names that NA2's
[mandatory records](stages.md#resident-generic-factories-and-mandatory-records)
and [line builders](stages.md#line-construction) request: `DMY_pp1_010`,
`DMY_pp2_010`, both `DMY_line_010`/`DMY_line_020` pairs, the four
`DMY_linemin/max` nodes, `LGT_dis_0`, `ANM_stalig00`, `BLT_bg`, `BLT_obj`, and
`DMY_{f,b}_cl_N_{nor,ewr,mov}` lines using the same naming scheme.

**Supported:** NUN3 categories map onto the NA2
[factories](stages.md#bin_bgdata-records-and-factory-dispatch) by shared node
names, resource names, and token shapes:

| NUN3 record | NA2 record |
| --- | --- |
| category 0 archive and `BLT_bg`/`BLT_obj` | slot path table and factory 31 |
| category 1 fog | factory 10: NUN3 tokens 3/4 are near/far distances and 5/6 far/near percentages; NA2 tokens 3/4 are near/far percentages and 5/6 the distances. Both map percentages through `(100-p)*2.55`. |
| category 10 players | factories 33/34 |
| category 11 line nodes, token 5 | factories `0x23`/`0x24` (node count) |
| category 14 `cl` lines, token 5 | factories `0x25`/`0x26` (line count) |
| category 13 lighting | factory 18 `ccBgLightDistant` |
| rotating sky, glare | factories 8 `ccBgRotateSky`, 11 `ccBgGlareFilter` |
| swaying tree / grass, flags, wind bell | factories 5, 7, 6, 30 |
| `0x601` transparent pillars | factory 40 `ccBgTransObject` |
| `0x81C` training doll, `0x8xx` breakables | factories 41 `ccBgBreakDollBattle`, 50/78/80/102 |
| electric wire, rowing boat, mangrove, suspension bridge, footprints, crane truck | factories 43, 82, 95, 68, 93, 83 |

The line-count correspondence is exact where the stage is shared: NUN3
index 8 (Tanzaku) has 14/14 `DMY_line` nodes and 8/9 `cl` lines, and NA2 `S24`
has 7/7 second-family records and 8/9 first-family records; NUN3 index 2
(Forest of Death) has 10/10 and 5/5, and NA2 `S09` has 5/5/5/5.
NUN3 parser comparisons above establish several shared responsibilities and
specific input differences. Other subtype correspondences in this table
remain supported by labels/resources; their complete token formats and
update-state equivalence have not been established.

### Shared-stage record comparison

For the nine shared-content pairs, NUN3 records and NA2 `BIN_bgdata`
records name the same nodes and objects, so each NA2 record can be read
against its NUN3 source. NA2 kept every pair's structure: the factory, the
nodes and objects, counts, and fog distances. Look values were re-authored
per stage: fog colour and percentages, lighting colour, glare, opacity,
grass and leaf constants.

| NUN3 type (pair evidence) | NA2 record | Token correspondence |
| --- | --- | --- |
| `0x401` base, `0x301` far animation (all pairs) | factory 0 per object | Every `OBJ_` object the base animation references has a factory-0 record `OBJ,0,1,1` in NUN3 S03 → NA2 S09 and NUN3 S16 → NA2 S14; those base animations reference no grass or tree objects. S04's base animation also references its grass objects (`OBJ_obj_080_`..`110_a2`), keyed at their grass nodes. `model_bind_animation` (`0x0016F640`) gives every referenced object a drawn scene child, and `stage_swing_grass_draw` (`0x007EF970`) also draws the grass record's children, so NUN3 draws each S04 grass object twice at the same position; both instances use the resource geometry the grass update deforms. The far animation's `OBJ_bac_*` objects become factory-0 records too, and its `OBJ_cld_*` skies factory-8 rotating clouds. |
| `0x690`/`0x390` frame animation (NUN3 S03 / NA2 S09, NUN3 S07 / NA2 S08) | factory 2 | animation name, `0`, re-authored opacity 0.2..0.65, `1,1,1`; NUN3 S14's become factory-29 UV animations in NA2 S10 |
| `0x582` swaying tree (NUN3 S03, S16 / NA2 S09, S14) | factory 5 | `CMP` token 8, node token 3, `OBJ_eda` token 7, token 5, then `0,0,1`. NA2 S09 turns two of five trees into factory-0 draws and drops the `CLT_*` palette tokens. |
| `0x526` swaying grass (NUN3 S03, S16) | factory 7 | object token 7 without its trailing `_`, node token 3, count token 5 + 1, then re-authored constants: `150,20,100,0.8,80,4` (S09) or `300,1,300,1,100,4` (S14). NUN3's own grass (`stage_swing_grass_update`) uses NA2's deformer with fixed amplitude 20, gust length 100, gust chance 1 in 11 and step 3°, which are factory-7 tokens `20,100,100,<unused>,9,3`; its height threshold is 5 against NA2's 2.5. |
| `0x52B` falling leaves (NUN3 S16 / NA2 S14) | factory 26 | one composition for every node, node token 3, then `200,0.3,2`. Factory 26 is [`bg_factory_particle_emitter`](stages.md#native-background-configuration-formats). NA2 S09 and S08 drop or replace their falling leaves. |
| `0x50D` new leaves (NUN3 S07, S16 / NA2 S08, S14); `0x70D` in NUN3 S02 builds the same class from category 7 | factory 48 `ccBgLandingTreeBattle` | object token 7 without `_`, count token 5 + 1 (S16) or 4 (S08), node token 3, `1,1`, then the receiver width/height. `stage_landing_tree_parse` reads those from token 10, `w,h,i,j`; NA2 re-authored them (S16's `100,180` → `250,200`). The record's animation resource binds a branch whose `0xD801` hit mesh is the landing surface: S04's `ANM_s0banm00`/`10` bind `OBJ_obj_060_`/`070_`, and S16's bind the branch the other record names at token 7. `stage_landing_tree_parse` moves the base model to the node and gives it contact word `0x2000D801`. NA2 has no animation token; S14 keeps the token-7 branch as child `_a0`, and factory 48 registers each child's hit mesh. |
| `0x81C` training doll (all pairs) | factory 41 per doll | `ANM_anm_doll,3,1`, doll node, `DMY_s??doll0N_hit,1,100,OBJ_doll_bre_000,4`; token 5's doll count becomes that many records on `DMY_dd_010`, `_1`, `_2` |
| `0x81D` monkey doll (all pairs) | factory 50 | `ANM_s??uki00,3,2`, token 4 node, `DMY_s??uki00_hit`, `0.8` or `1`, `100,OBJ_uki_bre_000,4`. NUN3's monkey animations hold absolute translation keys; NA2's equal them minus the token-4 node's position, because factory 50 places the doll at that node. |

`stage_landing_tree_reaction` (`0x007E8580`) reacts to a fighter within the
receiver width, 30 in depth and the receiver height of the swaying node.
It queues the -50 sway, spawns ten leaves through `surface_effect_spawn` at
the node raised by height - 100, and plays common sound 7 there. The leaf
colour follows `field_surface_variant` (5 on S04): `surface_effect_variants`
rows `0x89 + v` and `0x90 + v` name `CLT_e0xleaf01`/`02` with suffix `cv`,
the same palettes as NA2's rows `0x7B + v`/`0x82 + v`, and both
`PARTICLE.CCS` archives hold the same colours. On a landing (major state 4)
`stage_landing_tree_landing_extra` (`0x007E8C50`) acts one time in five, at a
random point along the branch: `stage_dispatch_prop_effect` kind `0x10`
starts two falling-leaf generators (`prop_leaf_generator_parameters` with
catalog rows `0x34` and `0x4C`, the same rows as NA2's
`battle_particle_catalog_rows`), `field_item_random_select` draws an item from
`landing_extra_item_distribution`, and program `0x4E` plays at key `0x4B`.
NA2's common bank holds the same samples and program records as NUN3's
programs 7 and `0x4E` under its programs 7 and `0x2E`.

The nine pairs' archives, compared section by section, show how NA2
converted the content:

- Names: NUN3's stage code becomes the NA2 file's number: `s6b` → `s08`,
  `s2c` → `s09`, `s8a` → `s10` (partly kept), `s4a` → `s13`, `s2a` → `s14`,
  `s7b` → `s15`, `s3a` → `s16`, `s2b` → `s23`, `s7a` → `s24`.
- Breakable pieces: the parsers' `_a0`.. pieces take NUN3's role-named
  animations as idle `n1` → `a0`, hit `d1` → `a1`, broken `n2` → `a2` in
  seven pairs; S14's monkey doll alone orders `d1`, `n1`, `n2`. Training dolls
  map `a1/n1/v1` to `a0/a1/a2`, and each break stem's base piece gains `_a0`.
  Idle and broken poses lose their translation keys (84 to 72 bytes), because
  the factory places the piece at its node. Every converted break animation
  ends with frame -1; NUN3 ends them with -1 too, except S04's monkey-doll
  idle and broken poses, which end with the loop marker -2.
- Nodes: break-object nodes `DMY_pg_*` move 50..100 lower in component 2 in
  S08, S13, S16, S23 and S24, and hit nodes are re-placed one by one (monkey
  dolls 25..80 higher). In every pair the outer ends of the front and back
  `cl` lines move 25..65 inward along component 0. NA2 adds
  `DMY_s??doll0N_hit` at each doll node + (0, -100, +100). S14 also stores
  every node 400 lower in component 2 than NUN3 S16 (its monkey-doll hit node
  320 lower).
- Art: every pair's textures and palettes, and many models and other
  animations, differ.

### S04 stage-specific records

S04's three `0x59x` records have no NA2 counterpart; their handlers use
fixed resource names:

| Type | Handlers | Behavior |
| --- | --- | --- |
| `0x595` water sparkle | `stage_memorial_sparkle_parse`, `stage_memorial_sparkle_reset` (`0x0080C7C0`, `0x0080C8B0`) | `EFF_s0befe07` at 30 random positions: x within ±5000, depth 6200..13200, base scale depth/7000×5, angle π/4. `stage_memorial_sparkle_update` (`0x0080C9A0`) grows each size factor by 0.03 per update to 0.4, shrinks it by 0.03, and below 0.1 respawns that sparkle at a new random position; NA2's factory 96 (`bg_s13_sparkle_update`) runs the same cycle for S13 with 15 sparkles and its own constants |
| `0x597` water surface | `stage_water_surface_parse`, `stage_water_surface_draw` (`0x0080D110`, `0x0080D4C0`) | token-3 object `OBJ_s0briv01` drawn three times, each layer scrolling its UVs from a random start by 1/period per update for periods (250, -250), (-250, -230), (0, -250); NA2's [factory 29](stages.md#native-background-configuration-formats) has the same per-layer contract |
| `0x59A` foot ripples | `stage_foot_ripple_parse`, `stage_foot_ripple_update` (`0x0080DD10`, `0x0080DF90`) | for each fighter's two feet, when `0x0080DE70` accepts its area and a 100-unit downward cast on collision flag `0x20000001` hits within 20, spawn an `OBJ_s0befe09` ripple (pool 40; scale 2 on first contact, then 1 every 15 updates) and an `EFF_s0befe10` splash (pool 10) |

`stage_water_surface_update` (`0x0080D370`) adds each step, `-1/period`, to its
layer's U/V and wraps them. `stage_foot_ripple_area` (`0x0080DE70`) accepts a
foot below height 100 at x in (-690, -480) or (420, 620) on section 0 and
(430, 665) on section 1.
