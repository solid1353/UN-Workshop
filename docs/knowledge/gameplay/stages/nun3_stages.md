# NUN3 battle stages

## Research coverage

Established: archive compatibility, compiled records, construction routing,
update gates, selected prop states, the bounded summon switch/return path,
the per-stage camera, combo-anchor, route, intensity and music tables, Stage
Select preview and name assets, record translation evidence from the shared
stages and S04's stage-specific handlers. Open: other prop states/teardown,
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
| `stage_combo_anchors` (BATTLE `0x009297B0`) | 20 `Nun3StageAnchorRecord`s: side 0/1 array pointers at `+0/+4`, byte counts at `+8/+9` | `stage_choose_combo_anchor` (`0x007C1F60`) |
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
| `0x301` | `stage_animation_parse` | Token 10 Boolean propagated to model children; distinct from rotating sky. |
| `0x38A` | `stage_rotating_sky_parse` | First resource is animation; token 10 float speed; random initial angle over ±pi. |
| `0x390/0x590/0x690` | `stage_frame_animation_parse` | Shared parser; nonzero token 10 integer divides model playback step. |
| `0x392` | `stage_glare_parse` | Tokens 7/8/9/10 are mode, packed colour, float amount, packed colour; draw submits up to three resource models plus controller. |
| `0x502` | `stage_wire_parse` | Second/third resources are endpoints ordered by component 0; texture token 6; 15 interior nodes, three arrays and segment/controller storage. |
| `0x601` | `stage_transparent_parse` | Token 3 hit/position node; token 8 plus 150 contact divisor. Update blends from the smaller positive contact scalar matching the two fighters. |
| `0x587` | `stage_bridge_parse` | Tokens 1/2 endpoints, 3 segment-node stem, 5 segment count, 6 texture, 7 model, 8/9 floats, 10 byte; three model/rope/helper arrays. |
| `0x801/0x871`; `0x803/0x813` base | `stage_breakable_parse` | Token 0 count; 3/4 position nodes; 5 shape count; 7 debris; 8/9 integer-derived dimensions; 10 pose/sequence integer. Second/third resources are later animations. |
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
| Glare | Pack tokens 0..3 and 5..7 into colour words; mode 8, floats 4/9. | Already-packed integer colours 8/10; mode 7, float 9. |
| Wire | Endpoints/texture tokens 0/1/2; fifteen interior nodes and three arrays. | Endpoints in second/third record resources; texture token 6; parallel node/array setup. |
| Suspension bridge | Token contract in [Stages](stages.md#animated-and-breakable-background-evidence). | Segment/model/endpoint token positions differ as listed above. |
| Transparency | `ccBgTransObject` uses token 4 radius and fighter-distance easing. | Token 8 plus 150 and collision-contact scalars. |

Related scene responsibilities do not make these formats interchangeable.

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
| `0x50D` new leaves (NUN3 S07, S16 / NA2 S08, S14) | factory 48 `ccBgLandingTreeBattle` | object token 7 without `_`, count token 5 + 1 (S16) or 4 (S08), node token 3, `1,1`, then the receiver width/height. `stage_landing_tree_parse` reads those from token 10, `w,h,i,j`; NA2 re-authored them (S16's `100,180` → `250,200`). The record's animation resource has no NA2 token. |
| `0x81C` training doll (all pairs) | factory 41 per doll | `ANM_anm_doll,3,1`, doll node, `DMY_s??doll0N_hit,1,100,OBJ_doll_bre_000,4`; token 5's doll count becomes that many records on `DMY_dd_010`, `_1`, `_2` |
| `0x81D` monkey doll (all pairs) | factory 50 | `ANM_s??uki00,3,2`, token 4 node, `DMY_s??uki00_hit`, `0.8` or `1`, `100,OBJ_uki_bre_000,4`. NUN3's monkey animations hold absolute translation keys; NA2's equal them minus the token-4 node's position, because factory 50 places the doll at that node. |

The NA2 archives rename sections to the names those parsers build. NUN3 S16
→ NA2 S14 shows the rules:

- `ANM_anm_doll_a1/n1/v1` become `_a0/_a1/_a2`, byte-identical.
- `ANM_s2auki00_d1/n1/n2` become `ANM_s14uki00_a0/_a1/_a2`, with translation
  keys made node-relative (432/84/84 to 432/72/72 bytes).
- Each break stem's base piece gains `_a0` (`OBJ_doll_bre_000`,
  `OBJ_uki_bre_000`, `OBJ_obj_070_`).
- `DMY_s2auki00_hit` becomes `DMY_s14uki00_hit`.
- NA2 adds `DMY_s14doll00_hit`..`02_hit`, which NUN3 lacks, at each doll
  node + (0, -100, +100).

NA2 S14 also stores these nodes 400 lower in component 2 than NUN3 S16
(and the monkey-doll hit node 320 lower).

### S04 stage-specific records

S04's three `0x59x` records have no NA2 counterpart; their handlers use
fixed resource names:

| Type | Handlers | Behavior |
| --- | --- | --- |
| `0x595` water sparkle | `stage_memorial_sparkle_parse`, `stage_memorial_sparkle_reset` (`0x0080C7C0`, `0x0080C8B0`) | `EFF_s0befe07` at 30 random positions: x within ±5000, depth 6200..13200, scale depth/7000×5, angle π/4, random phase |
| `0x597` water surface | `stage_water_surface_parse`, `stage_water_surface_draw` (`0x0080D110`, `0x0080D4C0`) | token-3 object `OBJ_s0briv01` drawn three times, each layer scrolling its UVs from a random start by 1/period per update for periods (250, -250), (-250, -230), (0, -250); NA2's [factory 29](stages.md#native-background-configuration-formats) has the same per-layer contract |
| `0x59A` foot ripples | `stage_foot_ripple_parse`, `stage_foot_ripple_update` (`0x0080DD10`, `0x0080DF90`) | for each fighter's two feet, when `0x0080DE70` accepts its area and a 100-unit downward cast on collision flag `0x20000001` hits within 20, spawn an `OBJ_s0befe09` ripple (pool 40; scale 2 on first contact, then 1 every 15 updates) and an `EFF_s0befe10` splash (pool 10) |

`stage_water_surface_update` (`0x0080D370`) adds each step, `-1/period`, to its
layer's U/V and wraps them. `stage_foot_ripple_area` (`0x0080DE70`) accepts a
foot below height 100 at x in (-690, -480) or (420, 620) on section 0 and
(430, 665) on section 1.
