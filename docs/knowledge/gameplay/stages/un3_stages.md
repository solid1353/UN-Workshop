# UN3 battle stages

## Research coverage

Established: archive compatibility, compiled records, construction routing,
update gates, selected prop states, the bounded summon switch/return path,
the per-stage camera, combo-anchor, route, intensity and music tables, Stage
Select preview and name assets, record translation evidence from the shared
stages, the archive conversion rules those stages show, S04's stage-specific
handlers, the landing-tree reaction, the glare's draw order, S02's faded-pillar
order relative to the charging aura, S01's flags,
wind sound and far-animation fog modes, S02's gondolas, faces and kite,
S14's falls mist and bridge planks, S20's clouds, lens flare and depth of
field, S05's directional wind, flying debris, bells and torches, S08's cargo,
vending machine and desert eagle, S19's wall, dappled/root sunlight, canopy
and bed, S06's crash boundaries and steam, S11's sandstorm, their shared
jutsu-resource particle gates and NA2 factory correspondence, S12's dome,
the giant and hanging spiders, the water ripples, and every scene
comparison outside the records. Open: other prop
states/teardown, full scene binding, mode/effect meanings, texture-pixel
sharing, complete NA2 equivalence and Stage Select name-sprite rectangles.
Names and layouts come from
`@annotations/UN3`; NA2 comparison names come from `@annotations/NA2`.

This document owns retail UN3 (`SLUS-21727`) battle-stage behavior and
correspondence with retail NA2 (`SLPS-25837`). NA2 implementation belongs to
[Battle stage gameplay knowledge](stages.md).

## Evidence and address convention

Inputs and live address mapping belong to
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
UN3 stage archives are the retail `DATA.CVM` extraction's `STAGE/` directory.
Evidence is static against `SLUS_217.27`, `BATTLE.BIN` and those archives;
sizes agree with each game's `GZLIST.TXT`.
The faded-pillar comparison also uses the user-identified retail S02 charge
capture, inspected offline.

Coverage includes all 28 UN3 and 24 NA2 archives and all 27 UN3 scene tables.
Content comparisons covered every NA2/UN3 archive pair; texture comparisons
used raw payload hashes only. Construction coverage includes every authored
subtype. Complete state/derived-cleanup coverage is limited to
`0x801/0x871/0x803/0x813/0x81C/0x81D`; other parser comparisons are bounded.
The summon branches do not prove every battle mode, upstream scene binding
or indirect destruction path. Local invocation counts do not establish time.

Resident CCS types belong to
[Resident CCS object-type identities](../../game/files/ccs_object_types.md).
UN3 `RPGSTAGE/` was not examined.

## Archive set and CCS format

**Observations:**

- UN3 `STAGE/` holds `S01.CCS` through `S20.CCS` and eight summon archives,
  `KTYS_BNT`, `KTYS_KTY`, `KTYS_MND`, `KTYS_SKK`, `KTYS_SKK2`, `KTYS_SKR`,
  `KTYS_STR`, and `KTYS_TYO`. NA2 `STAGE/` holds only `S01` through `S24`.
- Every archive in both directories is a gzip CCS stream whose compressed and
  decompressed sizes equal that game's `GZLIST.TXT` entry, whose chunk-2
  version halfword is `0x123`, and whose section walk ends at the type-5
  terminator.
- The section tags used by UN3 `S01` through `S20` are a subset of the
  resident dispatcher documented in
  [Resident CCS object-type identities](../../game/files/ccs_object_types.md):
  `0x0100..0x0400`, `0x0600..0x0B00`, `0x0C00`, `0x0E00`, `0x1300`, `0x1400`,
  `0x1900`, `0x2000`, plus one `0x0500` camera in `S12` and
  `0x0D80`/`0x0D90` generator records in `S10` and `S17`. UN3 `S05` has three
  `0x0600` lights; every other `Sxx` archive in both games has exactly one,
  `LGT_dis_0`. No UN3 stage archive contains a
  `0x2400` section or a `BIN_bgdata` object; every NA2 stage archive does.
- Decompressed sizes: NA2 `S01..S24` range from 531,692 bytes (`S17`) to
  1,323,828 bytes (`S24`). UN3 `S01..S20` range from 1,032,152 bytes (`S13`)
  to 1,412,076 bytes (`S08`); 13 of the 20 exceed NA2's largest archive
  (`S01`, `S03`, `S04`, `S07`, `S08`, `S09`, `S12`, `S14`, `S15`, `S17`,
  `S18`, `S19`, `S20`).

| UN3 archive | Compressed | Decompressed | UN3 archive | Compressed | Decompressed |
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

**Confirmed shared encoding:** for NA2/UN3 archive pairs that carry the same
stage content (next table), same-named `0x0800` model, `0x0100` object, and
`0x1300` dummy sections are frequently byte-identical, or identical in length
with differences only in words below `0x4000` (object-table indices, which
differ because the two archives number their objects differently). For
example, 198 of the 223 `MDL_` sections in NA2 `S14` match UN3 `S16` this
way, and 209 of 223 `0x0100` sections do. Model, object, and dummy sections
therefore use the same payload encoding in both games; the two archives differ
in their object-table index references.

## Stage content already shared with NA2

Comparing hit-mesh payloads (ignoring their first four words), same-named
model sections, and dummy positions gives these pairs:

| NA2 archive (slot / logical ID) | UN3 archive (table index, name) | Evidence |
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
this kind was found for UN3 `S01`, `S02`, `S04`, `S05`, `S06`, `S08`, `S11`,
`S12`, `S17`, `S19`, or `S20`, nor for NA2 `S01..S07`, `S11`, `S12`, or
`S17..S22`.

## UN3 stage table and scene records

UN3 compiles scene configuration into `BATTLE.BIN`. Neither its resident
ELF nor battle overlay contains a `BIN_bgdata` parser,
`takaCreateBackGround` string, or `ccBg*`, `ccField`, `ccBgControl`
class names.

`stage_scene_tables` (`0x00913450`) contains 27 pointers and a null
terminator. Each points to a zero-terminated sequence of 32-byte
`un3StageRecord` entries.

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

All three readers index their table by `un3StageBattleContext.scene_index`,
the same index as `stage_scene_tables`, without a range check.

| Table | Live base | Entries | Reader |
| --- | --- | --- | --- |
| `stage_camera_records_by_scene` (resident `0x00477320`) | 27 pointers and a null terminator into `camera_stage_tracking_gains` (`0x00476900`), `0x60`-byte `un3StageCameraRecord`s | `camera_bind_stage_record` (`0x00234D80`) saves camera `+0x18C` to `+0x190` and installs the record; `camera_initialize` (`0x00234BA0`) first installs record 0 |
| `stage_combo_anchors` (BATTLE `0x009297B0`) | 20 `0x10`-byte `un3StageAnchorRecord`s: side 0/1 array pointers at `+0/+4`, byte counts at `+8/+9` | `stage_choose_combo_anchor` (`0x007C1F60`) |
| `stage_navigation_authored_routes` (BATTLE `0x009192D0`) | 20 pointers to `un3StageRouteRecord` lists ending at source `-1` | `stage_navigation_initialize` (`0x008257F0`) |

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
equal UN3 scenes 6, 2, 13, 9, 15, 17, 12 and 14; NA2 slot 23 and scene 8
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

Six of the nine shared-content pairs keep UN3's intensity byte; NA2 slots
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

## UN3 summon selection and archive lifetime

`summon_scene_row` accesses eight `un3SummonSceneRow` entries in
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
side plus one in `un3StageBattleContext`.

`summon_sequence_update` (`0x002E4900`) preloads before publication.
State 2 at `un3SummonSequence.counter == 85` maps the character and calls
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

## UN3 scene-record dispatch

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
`un3StageControl.object_lists` orders `far_objects`, `base_objects`,
`animation_props`, `creature_props`, `reactive_props`, `category9_objects`,
then `transparent_objects`. Their `un3StageVector` headers hold capacity,
count and pointer storage; `stage_vector_append` owns insertion.
Record counts may be smaller than constructed-object counts.

`stage_object_construct` and `stage_object_initialize_model` establish
common `un3StageObject` ownership. Stored `initialization_category`
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
| 8 | Chained mode words `(5,0)` and the optional `un3StageRestrictionOwner` has a nonzero restriction byte or halfword. |
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

## Faded pillars and the charging aura

In the captured retail S02 frame, `ANM_e0x_aura_01` submits to priority 1
(environment `0x0141B7A0`); the faded pillars submit to priority 15
(`0x015BD4A0`). `stage_transparent_draw` (`0x007E9580`) retains this transparent
environment while its contact blend is below 1, and selects stage environment
1 otherwise. `ordered_controller_list_insert` (`0x001095C0`) sorts descending;
`ordered_controller_list_process` (`0x00109620`) and
`render_packet_list_splice_submission` (`0x0010E2F0`) prepend each environment
at the same insertion tag, producing ascending final priority. The aura
therefore draws before the faded pillars.

The emitted pillar and aura material packets both retain depth comparison
`GEQUAL` and enabled depth writes (`ZBUF = 0x310000E0`). The left pillar's
TEST is `0x5130B`, and the aura's is `0x51001`. Fading does not disable depth:
the later foreground pillar blends over aura colour already in the frame.
This ordering, rather than opacity alone, permits the aura to remain visible
through the pillar. These capture observations do not establish every effect's
environment or every stage's foreground order.

## UN3 object parsers and concrete comparisons

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

## UN3 reactive-object states and derived cleanup

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
| `0x803`, lanterns | `stage_lantern_motion`: contact restores amplitude and local value 30. `un3StageLanternContactEntity.phase_selector` values 1/0 select phase 0/36; other values keep phase, absence selects 0. Phase advances by 2; samples scale amplitude. Each wrap decays amplitude by 0.6 with floor 0.05; positive count permits receiver re-registration. Transform uses sample and 0.3×sample. Contact side is retained and `stage_lantern_contact_effect` selects three parameter paths from `effect_mode`. |
| `0x813`, wind bells | `stage_wind_bell_motion`: contact resets phase, restores amplitude 0.5 and local value 30. Phase advances by 2 through the same table; at its end amplitude decays by 0.6 with floor 0.05, phase resets and positive count permits receiver re-registration. Transform combines sample with 0.3×the directional-wind scalar. S05's records have one hit and no later animation, so `stage_wind_bell_draw` stops drawing the original model after that hit; debris still draws. |
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

| Behavior | NA2 inputs | UN3 inputs |
| --- | --- | --- |
| Rotating sky | Resource/node tokens 0/1, float scale 2, initial integer angle 3 (-1 random), speed 4. | Animation in first record resource; speed token 10. |
| Glare | Pack tokens 0..3 and 5..7 into colour words; mode 8, floats 4/9. Every retail record is in selector 5 (draw key 10), after the scene. | Already-packed integer colours 8/10; mode 7, float 9. `stage_glare_draw` draws the record's models in a draw environment keyed -5122 and the glare in one keyed -5121, ahead of the stage's own environments (-5120, -2304, 15), so the glare samples only those models. |
| Wire | Endpoints/texture tokens 0/1/2; fifteen interior nodes and three arrays. | Endpoints in second/third record resources; texture token 6; parallel node/array setup. |
| Suspension bridge | Token contract in [Stages](stages.md#animated-and-breakable-background-evidence). | Segment/model/endpoint token positions differ as listed above. UN3 S14 reads its 17 plank positions from the base model's empty `OBJ_hasi_aN` placeholders, which `ANM_s8aare00` places; NA2 reads `<stem>_aN` dummies. The rest of the parse matches `bg_bridge_parse` step for step. |
| Transparency | `ccBgTransObject` uses token 4 radius and fighter-distance easing. | Token 8 plus 150 and collision-contact scalars. |

Related scene responsibilities do not make these formats interchangeable.
Both games' glare objects use the same effect class (`pause_auxiliary_refresh`
initializer, `ccfm_sampling_pass_submit`) with byte-identical pass settings.

## Correspondence with NA2 records

**Confirmed:** every one of UN3 `S01..S20` contains all node and resource
names that NA2's
[mandatory records](stages.md#resident-generic-factories-and-mandatory-records)
and [line builders](stages.md#line-construction) request: `DMY_pp1_010`,
`DMY_pp2_010`, both `DMY_line_010`/`DMY_line_020` pairs, the four
`DMY_linemin/max` nodes, `LGT_dis_0`, `ANM_stalig00`, `BLT_bg`, `BLT_obj`, and
`DMY_{f,b}_cl_N_{nor,ewr,mov}` lines using the same naming scheme.

**Supported:** UN3 categories map onto the NA2
[factories](stages.md#bin_bgdata-records-and-factory-dispatch) by shared node
names, resource names, and token shapes:

| UN3 record | NA2 record |
| --- | --- |
| category 0 archive and `BLT_bg`/`BLT_obj` | slot path table and factory 31 |
| category 1 fog | factory 10: UN3 tokens 3/4 are near/far distances and 5/6 far/near percentages; NA2 tokens 3/4 are near/far percentages and 5/6 the distances. Both map percentages through `(100-p)*2.55`. |
| category 10 players | factories 33/34 |
| category 11 line nodes, token 5 | factories `0x23`/`0x24` (node count) |
| category 14 `cl` lines, token 5 | factories `0x25`/`0x26` (line count) |
| category 13 lighting | factory 18 `ccBgLightDistant` |
| rotating sky, glare | factories 8 `ccBgRotateSky`, 11 `ccBgGlareFilter` |
| swaying tree / grass, flags, wind bell | factories 5, 7, 6, 30 |
| `0x601` transparent pillars | factory 40 `ccBgTransObject` |
| `0x81C` training doll, `0x8xx` breakables | factories 41 `ccBgBreakDollBattle`, 50/78/80/102 |
| electric wire, rowing boat, mangrove, suspension bridge, footprints, crane truck | factories 43, 82, 95, 68, 93, 83 |

The line-count correspondence is exact where the stage is shared: UN3
index 8 (Tanzaku) has 14/14 `DMY_line` nodes and 8/9 `cl` lines, and NA2 `S24`
has 7/7 second-family records and 8/9 first-family records; UN3 index 2
(Forest of Death) has 10/10 and 5/5, and NA2 `S09` has 5/5/5/5.
UN3 parser comparisons above establish several shared responsibilities and
specific input differences. Other subtype correspondences in this table
remain supported by labels/resources; their complete token formats and
update-state equivalence have not been established.

### Shared-stage record comparison

For the nine shared-content pairs, UN3 records and NA2 `BIN_bgdata`
records name the same nodes and objects, so each NA2 record can be read
against its UN3 source. NA2 kept every pair's structure: the factory, the
nodes and objects, counts, and fog distances. Look values were re-authored
per stage: fog colour and percentages, lighting colour, glare, opacity,
grass and leaf constants.

| UN3 type (pair evidence) | NA2 record | Token correspondence |
| --- | --- | --- |
| `0x401` base, `0x301` far animation (all pairs) | factory 0 per object | Every `OBJ_` object the base animation references has a factory-0 record `OBJ,0,1,1` in UN3 S03 → NA2 S09 and UN3 S16 → NA2 S14; those base animations reference no grass or tree objects. S04's base animation also references its grass objects (`OBJ_obj_080_`..`110_a2`), keyed at their grass nodes. `model_bind_animation` (`0x0016F640`) gives every referenced object a drawn scene child, and `stage_swing_grass_draw` (`0x007EF970`) also draws the grass record's children, so UN3 draws each S04 grass object twice at the same position; both instances use the resource geometry the grass update deforms. The far animation's `OBJ_bac_*` objects become factory-0 records too, and its `OBJ_cld_*` skies factory-8 rotating clouds. |
| `0x690`/`0x390` frame animation (UN3 S03 / NA2 S09, UN3 S07 / NA2 S08) | factory 2 | animation name, `0`, re-authored opacity 0.2..0.65, `1,1,1`; UN3 S14's become factory-29 UV animations in NA2 S10 |
| `0x582` swaying tree (UN3 S03, S16 / NA2 S09, S14) | factory 5 | `CMP` token 8, node token 3, `OBJ_eda` token 7, token 5, then `0,0,1`. NA2 S09 turns two of five trees into factory-0 draws and drops the `CLT_*` palette tokens. |
| `0x526` swaying grass (UN3 S03, S16) | factory 7 | object token 7 without its trailing `_`, node token 3, count token 5 + 1, then re-authored constants: `150,20,100,0.8,80,4` (S09) or `300,1,300,1,100,4` (S14). UN3's own grass (`stage_swing_grass_update`) uses NA2's deformer with fixed amplitude 20, gust length 100, gust chance 1 in 11 and step 3°, which are factory-7 tokens `20,100,100,<unused>,9,3`; its height threshold is 5 against NA2's 2.5. |
| `0x52B` falling leaves (UN3 S16 / NA2 S14) | factory 26 | one composition for every node, node token 3, then `200,0.3,2`. Factory 26 is [`bg_factory_particle_emitter`](stages.md#native-background-configuration-formats). NA2 S09 and S08 drop or replace their falling leaves. |
| `0x50D` new leaves (UN3 S07, S16 / NA2 S08, S14); `0x70D` in UN3 S02 builds the same class from category 7 | factory 48 `ccBgLandingTreeBattle` | object token 7 without `_`, count token 5 + 1 (S16) or 4 (S08), node token 3, `1,1`, then the receiver width/height. `stage_landing_tree_parse` reads those from token 10, `w,h,i,j`; NA2 re-authored them (S16's `100,180` → `250,200`). The record's animation resource binds a branch whose `0xD801` hit mesh is the landing surface: S04's `ANM_s0banm00`/`10` bind `OBJ_obj_060_`/`070_`, and S16's bind the branch the other record names at token 7. `stage_landing_tree_parse` moves the base model to the node and gives it contact word `0x2000D801`. NA2 has no animation token; S14 keeps the token-7 branch as child `_a0`, and factory 48 registers each child's hit mesh. |
| `0x81C` training doll (all pairs) | factory 41 per doll | `ANM_anm_doll,3,1`, doll node, `DMY_s??doll0N_hit,1,100,OBJ_doll_bre_000,4`; token 5's doll count becomes that many records on `DMY_dd_010`, `_1`, `_2` |
| `0x81D` monkey doll (all pairs) | factory 50 | `ANM_s??uki00,3,2`, token 4 node, `DMY_s??uki00_hit`, `0.8` or `1`, `100,OBJ_uki_bre_000,4`. UN3's monkey animations hold absolute translation keys; NA2's equal them minus the token-4 node's position, because factory 50 places the doll at that node. |

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
NA2's common bank holds the same samples and program records as UN3's
programs 7 and `0x4E` under its programs 7 and `0x2E`.

The nine pairs' archives, compared section by section, show how NA2
converted the content:

- Names: UN3's stage code becomes the NA2 file's number: `s6b` → `s08`,
  `s2c` → `s09`, `s8a` → `s10` (partly kept), `s4a` → `s13`, `s2a` → `s14`,
  `s7b` → `s15`, `s3a` → `s16`, `s2b` → `s23`, `s7a` → `s24`.
- Breakable pieces: the parsers' `_a0`.. pieces take UN3's role-named
  animations as idle `n1` → `a0`, hit `d1` → `a1`, broken `n2` → `a2` in
  seven pairs; S14's monkey doll alone orders `d1`, `n1`, `n2`. Training dolls
  map `a1/n1/v1` to `a0/a1/a2`, and each break stem's base piece gains `_a0`.
  Idle and broken poses lose their translation keys (84 to 72 bytes), because
  the factory places the piece at its node. Every converted break animation
  ends with frame -1; UN3 ends them with -1 too, except S04's monkey-doll
  idle and broken poses, which end with the loop marker -2.
- Nodes: break-object nodes `DMY_pg_*` move 50..100 lower in component 2 in
  S08, S13, S16, S23 and S24, and hit nodes are re-placed one by one (monkey
  dolls 25..80 higher). In every pair the outer ends of the front and back
  `cl` lines move 25..65 inward along component 0. NA2 adds
  `DMY_s??doll0N_hit` at each doll node + (0, -100, +100). S14 also stores
  every node 400 lower in component 2 than UN3 S16 (its monkey-doll hit node
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

### S20 stage-specific records

S20's `0x39F`, `0x3A1` and `0x6A0` records use fixed tables; `0x501` is a
plain animation object in the animation-props list.

| Type | Handlers | Behavior |
| --- | --- | --- |
| `0x39F` clouds below the cliff | `stage_cliff_clouds_parse`, `_update`, `_draw` | Sixteen models from the first 16 rows of `stage_cliff_cloud_rows`, each bound to `ANM_s8bbac00_b00` or `_c00` at its initial frame (0..550), with the playback step divided by its divisor (4..7), translated to one of `DMY_kumo_dummy00`..`04`. In the far-objects list. |
| `0x3A1` depth of field | `stage_depth_of_field_parse`, `stage_depth_of_field_draw` | A draw environment at token 10's priority (-3000) holding two glare-filter passes: mode 0, colour `0x20808080`, amount -0.2, second colour 0, parameter 50000 and 80000 (`stage_depth_of_field_depths`). That priority falls between the far-objects environment (-5120) and the main one (-2304). NA2's factory 11 builds the same pass class with the same fields. |
| `0x6A0` lens flare | `stage_lens_flare_parse`, `_update`, `_draw` | The resident lens flare (`lens_flare_initialize`, `_update`, `_draw`; NA2 carries the same code unused) with token 3's node as the sun, descriptor `stage_lens_flare_descriptors`[token 9] (priority `0x65`, 19 quads, screen radius 933.33) and quads `lens_flare_quad_sets`[token 10] (`TEX_s8befe10`..`40`). The flare shows while the sun is on screen and two segment queries from the camera reach it; each quad sits along the sun-to-screen-centre axis at its distance, and a full-screen white flash grows to (1 − d/r)³ × 60 as the sun nears the centre. |

## S05 directional wind and flying props

S05's `0x55E` uses `stage_directional_wind_parse` (`0x007FA980`) and
`stage_directional_wind_update` (`0x007FAAB0`), separate from the alternating
`0x518` wind. Parse chooses one direction and sets a five-second initial
hold. The unsigned strength is sin(phase / 2 degrees), with 360 phases.
At phases 90, 180 and 270 each update draws a hold of rand(0..3) seconds;
at phase 360 it resets phase and rests 30 seconds. The sign stays fixed
for the scene. Token 10 times -2 times signed strength is written to both
fighters' transient movement component `+0x4B0`; the shared movement routine
consumes that vector with its ordinary state and contact gates. The sound
is common `0x3E`; its placement uses the unsigned half-sine. This object
opts into updates under scene restrictions.

`stage_wind_debris_parse` (`0x007F9A60`) builds 17 pieces from seven S05
animations. The first four choose among animations 0..2, with matching
debris sets 1..3; the other thirteen choose animations 3..6 and debris set 1.
`stage_wind_debris_update` (`0x007FA580`) updates them unless the scene-effect
restriction is active. Available pieces launch only while 0.9 < abs(wind) < 1:
each foreground slot draws rand(0..1000) > 990, and at most one background
slot draws rand(0..100) > 80 per update. Launch timing is therefore confined
to the shoulders of the gust, excluding its exact peak.

Two pieces use `stage_wind_debris_foreground_path` (`0x007F9E30`), two
`stage_wind_debris_background_path` (`0x007FA230`), and thirteen
`stage_wind_debris_far_path` (`0x007FA3E0`). Their endpoint rows are at
`0x00913BA0..0x00913C3B`; `stage_wind_debris_start_curve` (`0x007F8D10`)
places the cubic control points at one and two thirds of the horizontal
span. Rotation advances 0.5 radians on axes 0 and 2 per update. Foreground
contacts break the piece; a curve ending within absolute x 1500 also breaks
it with sound `0x37`. Drops and debris snap the depth component to 600 when
above 600, or zero when below. Offscreen completion or finished debris
enters a rand(0..20)+10-update cooldown before reuse.

S05's `0x517` creates two independent copies of `EFF_efe_000_` at
`DMY_dummy_120` and its `_1` node. Each starts at a random effect frame;
the effect loops by restarting then advancing after its end. Opacity moves
by a signed random 0.05 per update, clamped to 0.2..0.5. Each node also owns
a spark generator using descriptors `0x009136A8` and `0x00913700`.
The lighting animation has one distant light and two animated omni lights,
all registered by `stage_parse_lighting`; `stage_scene_update` advances the
lighting animation after its prop lists. Its lens-flare descriptor and
19 numeric quad rows match S20's, with `TEX_s1cefe10/20/30/40` in place of
the S20 texture names.

S05's bells have distinct render, interaction and attack nodes. For the first
bell, `DMY_dummy_010` places the visible model, `DMY_pg_010` supplies the
interaction anchor, and `DMY_s1cfuu00_hit` supplies the attack sphere. Their
depths are 745, 700 and 600 respectively. `stage_breakable_parse` takes the
first attack sphere's depth for the proximity center and item-drop position;
it keeps the interaction anchor's horizontal position and height. The pickup
constructor preserves the supplied depth. Using the interaction node as an
attack node therefore also puts the drop behind the fighting plane.

`stage_wind_bell_draw` (`0x007DA570`) delegates to `stage_breakable_draw`
(`0x007D9BB0`). The latter submits the original model while remaining count
is positive; after destruction it submits a model only when the record has
a later animation. Its debris branch remains independent. A missing later
animation means disappearance, rather than reuse of the idle model.

## S08 cargo, vending machine and desert eagle

S08's `0x835` cargo uses `stage_cargo_stack_parse` (`0x007E0780`). Token 3
selects the base node and token 10 the box count, with zero meaning three;
its two authored stacks contain two and three boxes. The parser creates a
breakable per box using `ANM_s5bhak00_n1` and `_d1`, places them 100 units
apart in height, and retains the base position and rank. Contact, proximity
and item positions are the current box position plus `(0,-150,50)`.

`stage_cargo_piece_fall` (`0x007DFB80`) increases time by 0.12 and subtracts
`time * 9.8 * time * 0.5` from height on each falling update. It clamps to
base height plus rank times 100, then clears time and the falling flag.
`stage_cargo_piece_break_update` (`0x007DFD80`) records destruction;
`stage_stack_settle` (`0x007E05A0`) then compacts the surviving ranks and
starts their fall. A destroyed box has no third animation and disappears
under the shared breakable draw rule, independently of its debris.

The `0x842` vending machine runs `stage_vending_machine_trigger`
(`0x007E3150`). It plays its damage animation on each accepted hit without
decreasing its remaining-hit value, and emits an item on a random draw below
20 out of 100. On scene 7, either side's prop-hit counter being exactly ten
reduces that threshold to 5; scene 8 compares with eight.
`stage_doll_side_counter` (`0x0030FCE0`, resident) reads the same signed
halfword that `stage_doll_increment_side_counter` increments. The trigger
compares both counters before incrementing the hitting side's counter, so
the reduced chance applies to exact equality rather than a permanent cap.

`stage_vending_machine_update` (`0x007E2FF0`) rearms contact receivers when
the damage animation finishes. Every fifth completed contact also sets the
separate availability value to -1 for 300 updates, then restores it to 1.
`stage_vending_availability_pointer` (`0x00812EF0`) exposes that value's
address. Neither the hit trigger nor `stage_vending_machine_drop`
(`0x007E3400`) tests it, so it is not a timed lock on hitting the machine
or directly on its drop routine.

S08's `0x83F` desert eagle constructs the ordinary kite subtype and uses
`stage_kite_parse`. `stage_desert_eagle_update` (`0x007DCC60`) delegates to
`stage_kite_update`; its draw delegates to `stage_kite_draw`, which draws
only while the absence counter is zero. Its own three donor animations
and `DMY_bird_010`/`_1` nodes supply its appearance and flight locations.

## S19 interior, sunlight, canopy and bed

S19's `0x639` binds `ANM_s4bkab00` as the separate house wall.
`stage_hideout_wall_update` (`0x007E4AB0`) tests both primary fighters'
section halfword at `+0x946`. With both on section 0 its opacity rises by
0.03 to 1; with either elsewhere it falls by 0.09 to 0. The wall shares that
opacity with three root-light groups created from `stage_hideout_wall_light_rows`
(`0x00913370`): `ANM_s4bmoo20/21`, `30/31` and `40/41`.
`stage_hideout_wall_draw` (`0x007E4C20`) skips under the battle restriction;
outdoors it submits to the main stage environment and indoors to the current
transparent environment. It does not advance the wall animation.
`stage_scene_draw` (`0x007C2190`) submits category-9 and creature objects in
the main environment before the base animation, animated props and reactive
props. It then submits the far objects in their environment and transparent
objects in the third environment.

Nineteen `0x73A` records place two ground-light models at each `DMY_ld_010`
node and its numbered siblings. `stage_dappled_light_parse`/`_reset`
(`0x007E35F0`/`0x007E36C0`) choose from `ANM_s4bmoo00/01`, randomize each
model's Z rotation within plus/minus pi and its two motion amplitudes within
plus/minus 5, and choose an initial crossfade fraction. The update
(`0x007E3B00`) moves them by the shared cosine/sine tables in components 0/1
and raises component 2 by 1. The 72-entry phase advances every second update.
The fraction falls by 0.02, restarting at 1 and switching which model fades
out each time it passes zero; the newly fading-in model gets a new rotation.

Three authored `0x73B` records use `ANM_s4bmoo10/11`, `12/13` and `14/15`;
the wall adds the other three groups above. `stage_root_light_parse`/`_reset`
(`0x007E3F00`/`0x007E3FA0`) give each group two independently fading models,
each with a random initial animation, alpha from 0 to 0.7 and fade direction.
`stage_root_light_update` (`0x007E41E0`) moves alpha by 0.01: below zero it
binds the next animation and starts fading in; above 0.5 it clamps to 0.5 and
fades out. The wall-created groups multiply their alpha by the wall's fade.
`stage_root_light_draw` (`0x007E45A0`) uses their optional environment override;
the wall gives its three groups the third stage environment.

The `0x528` canopy record binds `OBJ_obj_170_` and its two siblings at
`DMY_hadummy_000_`. `stage_sway_leaves_parse` (`0x007EFAC0`) initializes
independent random phases. `stage_sway_leaves_update` (`0x007EFD60`) negates
the scene wind and clamps its magnitude to at least 0.3, increments phase by that value times
0.1, and uses token 10 times `20 * (0.2 + abs(wind))` as its amplitude, with
component-0 sine scaled by 1.3 and component-2 cosine by 0.5. S19 has no wind
record; at zero wind its phase advances by 0.03. Its five `0x526` grass groups
use the shared grass behavior. `ANM_usa_run00` uses frame-animation divisor 4;
`ANM_s4bmoo70/71` have no divisor.

The bed's `0x83C` uses `stage_hideout_bed_parse`/`_update`/`_trigger`
(`0x007E2F70`/`0x007E2C10`/`0x007E2D70`). Its three remaining hits do not
decrease: each accepted contact binds the damage animation, plays kind-2
prop feedback with its hit sound and rolls `rand % 100 < 20` for an item.
The update rearms receivers after that animation ends. Every fifth completed
contact also sets separate availability to -1 for 300 updates, then restores
it to 1; neither the trigger nor its item-drop path reads that availability.
Its scene-12 side-counter branch does not run on S19 (scene 18).

## Scene-keyed code outside the stage records

Code reads the battle context's scene byte (`+0x61`) outside the record
handlers. Every read that compares it with a normal scene (0..19), traced
in both `SLUS_217.27` and `BATTLE.BIN`, falls into these groups; NA2's
counterpart compares its raw slot where one exists
([Stages](stages.md#other-recovered-raw-slot-equality-cases)).

| UN3 routine | Scenes | Behavior | NA2 counterpart |
| --- | --- | --- | --- |
| `stage_choose_combo_anchor` | 1/10/15/16/18, 2/4/5/12/13/14 | Forced return side 0, 1 | Its own slots |
| `effect_select_polygon_code` | 9, 16 | Water (`E0E000`) landing effect variant 4, or 2 at scale 0.55, both at height 0 | Slot 12 only |
| `field_player_placement` | 9, 16 | Players start in section 1 | Slot 12 |
| `stage_landing_tree_reaction` | 1 | Leaving a branch calls `stage_doll_increment_side_counter` | None |
| `stage_scene2_resource_select` | 2 | Resource `+0x24A0`, environment index 4 | `stage_slot8_resource_select`, slot 8 |
| `stage_scene13_object_initialize` | 13 | Byte `+0x60` set | `stage_slot9_object_initialize`, slot 9 |
| `ai_water_chakra_gate`, `ai_water_section_gate` | 9, 16 | COM water handling | `ai_predict_environment_reaction`, `stage_navigation_s13`, slot 12 |
| `ai_point_route_update` | 0/5/6; 6 | Near gate 40; input `0x1000` | Slot 7 at both |
| `stage_navigation_response` | 19/14/4/1 | Planar endpoint clamp before recovery | Slots 5/22 |
| `ai_route_region_gate` | 14/4 | Region 0 rejected | `ai_construct_point_route`, slot 22 |
| `stage_execute_route` | 2 | COM in section 0 on `E0E000`/`E0A000` past route step 1 jumps on rand100 < 5 | None |
| `fanged_pursuit_hide_stage_objects`, `interaction_hide_stage_objects` | 0 | Hide swaying trees (subtype `0x82`); other scenes hide subtypes `0x26`/`0x86` | None |
| `interaction_scene13_reflection` | 13 | Second effect copy 400 below | None |
| `effect_scene13_burst_delay` | 13 | Random delay range 1 instead of 30 | None |
| `projectile_fall_to_ground` | 13 | Ground probe raised by 70 | Probe padding differs |
| `stage_vending_machine_trigger` | 7, 8 | A side's prop-hit counter equal to ten or eight reduces the drop threshold from 20 to 5 | Different field-item selection |
| Water-height reads (about 25 sites) | 2, 13 | Heights 50, 387 | `stage_effect_height_override`/`_bits` |

The remaining reads pass the scene to archive, record or summon routines
without comparing it. UN3 has no line-change rules or `n_rash` groups.

## Water ripples

Both games ring water from the same places. UN3 plays its effect0x row
`0x25`, `ANM_e0x_move_02` on the `OBJ_rpg_hamon00` ring; NA2 plays its row
`0x21`, an `ANM_e0x_move_02` on its own `e0xhamon00` rings, always at scale 1
through `effect_create_ground_21`. NA2's effect0x has neither UN3 animation.

| Source (UN3 / NA2) | UN3's effects |
| --- | --- |
| `0x00266A50` / `effect_periodic_ground_code`: standing in water, when the cursor is a multiple of 15 | The ring at scale 3 with the fighter's orientation: on `E0A000` at the stage's water height (`0x00267560`), on `E0E000` at the fighter's, a frame per update (`0x002672E0`) |
| `0x00265330` / `water_splash_spawn`: water splash | The ring at scale 3, at half speed in mode 3 |
| `0x00266B70` / `effect_create_contact_variant`: contact splash | The ring at scale 3; the splash is row `0x26` at scale 0.75 in effect view 1 plus 60 row-`0x80` droplets, where NA2 plays row `0xC` |
| `water_ripple_spawn` (`0x0026B3C0`) / `effect_emit_position_code`: a foot entering water, and an effect dispatcher | 20 along x toward the facing, on `E0A000` at the stage's water height: row `0x26` `ANM_e0x_down_04`, a 14-piece wave, at scale 1/7 from frame 6 in effect view 2, and the ring at scale 2 delayed 10 updates, both a frame per update |

A foot enters water when, in the walk/run state (major 1, substate `0xE`),
`fighter_foot_surface_effects` casts ±15 around the lower of the fighter's
`OBJ_2cmn00t0 l foot`/`r foot` nodes and hits the surface for the first time
for that side since a miss; NA2's `FUN_0033A2D0` does the same.

UN3's ring grows from 0.01 to 1 over 37 frames and fades from frame 29.
UN3's fish rings (`stage_fish_spawn_ring`) play the same ring at scale 1.
S04's pond (`E0E090`) does not trigger these; its own `0x59A` record makes
its ripples. Of S01–S06, S08, S11, S12, S14, S17, S19 and S20, the hit
meshes give S03 and S14 `E0A000` water and S17 `E0E000`; the other stages
were not checked.

## Hidden Leaf Hot Spring boundaries and ambient objects

Scene 5's `0x54B` wall and `0x551` bamboo boundary have two crash transitions,
not ordinary breakable-object contacts. `hot_spring_wall_check_crash` and
`hot_spring_bamboo_check_crash` read major-state 5 timeline event 0, positional
limits and distinct crash substate sets. The wall excludes section 1. The
final wall transition lowers the section's first pair and linked navigation
and collision endpoints to height 40. The bamboo extends its last projection
pair to x1260, moves the last collision endpoint to x1300, changes its separate
`ANM_s6atake00` backdrop to `ANM_s6atake01` and rebuilds navigation. After the
wall opens, `stage_navigation_initialize` detects equal heights at the first
two collision-line starts and changes work route 1 to fraction 0/action 3.

The model collision has a separate lifetime from these section lines.
`resource_register_environment` (`0x00170C00` in the ELF) registers nested
and direct animation-track collision environments; registration is idempotent.
The intact wall and bamboo updates call it. Their final transitions stop
registering the solid mesh; the wall explicitly unregisters it.
`resource_update_environment_transforms` (`0x00170F70`) copies scene-child
transforms and inverse matrices into nested model collision environments;
the bamboo calls it after advancing. Drawing does not perform registration.

`stage_noren_fixed_parse`/`_update` (`0x598`) preserve a base-animation dummy
matrix and apply x rotation sin(phase)*0.1, incrementing phase by four degrees
without visibility gating. This differs from the decaying `0x507` curtains.
`stage_tree_matrix_parse` (`0x583`) likewise passes the dummy matrix to the
compound tree solver, preserving its authored rotation and scale.

`hot_spring_steam_parse` creates ten common-particle generators from
`0x00913C60`; it does not replace their materials with a stage composition.
`hot_spring_steam_update` zeros alpha under battle restriction and the shared
[jutsu-resource gates](#steam-and-sand-jutsu-resource-gates), and otherwise
restores each row's authored colour alpha at generator `+0x16C`. Its live
generator retirement branch uses `stage_restriction_predicate`
(`0x0030FE70`), whose complete retail body returns zero, so that branch never
retires steam in retail. It does not use `battle_scene_restriction_active`
for retirement. The three water-light
records advance their animations and draw in main environment 1 unless battle
restriction is active. Falling-leaf records at nodes050/060 occur twice in the
retail table; both copies are authored.

## Sunagimo Estate sandstorm

Scene10's `0x73E` controller waits300 updates and follows four randomized
points (363±300,5000,0),(547±200,900,0),(-363±200,600,0),(-563±200,3000,0)
at speed0.0028. It fades on the first and last curve segments, rotates the
camera-relative `ANM_s5astom` overlay by -0.1 per update, moves a common
particle generator and positional sound71, then repeats after another calm.
Two spheres of radius250 at offsets200/600 from the moving origin raised500
are registered per fighter side. Contact reaches the stage-object hit path
with damage0.03, response selector11 and one hit per descriptor. The two
carried breakable objects choose among fly00/01/02 animations with matching
debris each pass and orbit at offsets(0,300,1000)/(0,-300,1200), with randomized
rotation rates and height sway. Their proximity depth snaps to1000 near the
back plane. The eagles use the ordinary kite parser/update/draw unchanged.

### Shared particle names do not establish matching visuals

S06's ten emitter descriptors select common catalog row 4 for the two
chimneys and row 70 for the other eight. Row 4 names
`PARTICLE/EFF_e0xsmok05`; its catalog playback-mode selector is 2. S11's
storm descriptor selects row 80, which uses `EFF_e0xsmok11` with palette
`CLT_e0xsmok11c1` and playback-mode selector 0. These catalog identities
agree between UN3 and NA2, but their visual assets do not.

In UN3 `CMN/PARTICLE.CCS`, both effects use flags `0x40`, 64x64 8-bit
textures and 256-colour palettes. NA2's same-named effects use flags `0x60`,
different 64x64 4-bit textures and different 16-colour palettes. In the
user-identified S06 ss1 pair, both games have matching emitter descriptors,
origins and colour alpha, while NA2's two chimney emitters resolve to its
brown `EFF_e0xsmok05` visual. The eight row-70 emitters use `EFF_x001`,
`TEX_x001` and `CLT_x001c7` from `EFFECT0X.CCS`; their content matches across
the games after excluding object references and VRAM coordinates.

### Steam and sand jutsu-resource gates

`hot_spring_steam_update` (`0x007FCC30`) and `sandstorm_advance`
(`0x007EB310`) read `jutsu_update_resource` (`0x006A1E08`, GP minus
`0x6E68`). `interaction_update_resource_callbacks` (`0x00875740`) resets
this value to -1, then publishes each eligible primary actor's resource at
`+0x3EC` before its callback, retaining the last publication.
`jutsu_bind_participants` (`0x00884690`) stores the resource argument there.
This is a jutsu resource ID, not a sequence or event ID.

Both particle controllers suppress colour alpha for resource 69 regardless
of the manager predicate, and for resources 29 or 67 only while
`battle_scene_restriction_active` (`0x002B7D30`) reports the manager's
`+0xAC0` control active. That conjunction is distinct from the steam
retirement predicate above. Resource 29 is Guy's Dynamic Entry and 67 is
Green Beast's Ultimate Entry; their actor dependencies are recorded in
[Guy](../characters/un3/guy.md#shared-guy-jutsu-actor-dependencies).
UN3's resource-69 factory branch (`0x0086D2D0`, table entry `0x0093FCA4`)
is a `break` followed by a self-loop, with no actor construction, despite
its retained `2hnxcha0.ccs` filename.

NA2's corresponding factory entries 29, 67 and 69 at `0x008CD264`,
`0x008CD2FC` and `0x008CD304` lead to empty arms at `0x00774308`,
`0x0077459C` and `0x007745B4`. None allocates or constructs an actor.
The resource-specific particle gates therefore have no actor counterpart
in retail NA2. Playable NA2 Guy's different resources 140/141 do not establish
a replacement for these checks. NA2's
`interaction_reset_sphere_caches_update` (`0x0077E6B0`) does publish its
current resource from actor `+0x56C`, but adding the donor's numeric checks
would not supply the missing actors.


## Forest of the Giant Spider

Scene 11's `earth_dome_parse` (`0x0080A240`) creates a two-crash dome rather
than an ordinary attack receiver. `earth_dome_detect_crash` requires front
section, major 5 and timeline event 0. Substates 3F/40/44 require x500..800
and height at most500; substates42/43/45 allow x500..1100 and height600.
`earth_dome_crash` (`0x0080A5C0`) selects the damaged then broken animation.
The final hit selects front CL and DMY variant1 and rebuilds navigation;
the variant nodes are `DMY_f2_cl_*` and `DMY_line_0101*`. It scatters15 item9
and three random items3..5. `earth_dome_update` eases opacity by0.1 toward0.3
when a back-section fighter is beyond x600, otherwise toward1; its draw
uses the third environment while faded.

The dome registers its initial animation's collision environment during parse.
The first crash unregisters the old environment, binds the damaged animation
and registers its environment. The last binds the broken animation and
unregisters collision. Intact updates refresh the collision transforms after
advancing; the broken branch advances without that refresh. These calls are
independent of selecting the front CL and DMY variants.

`giant_spider_parse` (`0x008079A0`) binds eight spider animations and three
nest animations, starts at `DMY_km_020`, and creates five web missiles.
`giant_spider_update` (`0x00809DA0`) dispatches15 states. Idle lasts90..150
updates, roaming uses speed7.5 and yaw steps0.03 radians, the attack wait
lasts210..270, and shot frame20 launches an available web toward random
x±800 on either section. Accepted hits disable the damage receiver, play
common sound65, drop three pool2 items and retreat500 above home. After
three hits the spider rises offscreen, chooses x±600 on either section,
casts to ground and falls from10000, accelerating downward by0.5. Its
radius600 contact sphere has offset300; stage-hit damage is0.1. Landing
plays sound12, common dust descriptor `0x00913610` with field `0x00913650`,
and shake priority3/mode2/duration10. After30 updates it rises and returns.
The main spider draws at scale1.5; its nest has independent animation.

`spider_web_update` (`0x00807300`) rises150 per update to height3000, moves
to its target section, then descends at up to10 with lateral sine sway.
Collision starts the landing animation. Its completed web remains for100
updates with a radius200 contact sphere, applies status6 on contact, and
fades by0.1. Retail status6 has action-rate factor0.75 and duration240;
NA2's effect6 definition and `effect_apply` (`0x00305C30`) carry those values.

`small_spiders_parse` (`0x0080C470`) creates11 spiders at `DMY_pg_020..120`.
Their vertical offsets are -400,-600,-800,-500,-700,-900,-700,-500,-800,
-600,-400. `small_spider_update` (`0x0080BD70`) emerges on rand100<11,
descends3 toward the authored height, occasionally moves within its ±20
range, and responds to accepted attacks. A hit plays65 and rolls a one-in-three
item chance, launches sideways30 with lift28.5, then gravity3 and fade0.025.
Each silk thread uses22 strip vertices along a bowed cubic, width5, and
`TEX_s3bobj43`; the model turns along its terminal tangent.

The dive's auxiliary registration is an AI danger circle, not a rendering
or height override. `stage_ai_danger_register`/`_unregister`
(`0x007D14F0`/`0x007D1560`) maintain section lists of borrowed position,
radius and next pointers at scene+334. `field_ai_danger_head` (`0x00826A50`)
feeds `ai_predict_environment_reaction` (`0x008204C0`): within radius plus
fighter radius and outside its cooldown, rand100<60 selects escape; the
other outcome sets cooldown150. The spider registers radius300 at its ground
target and removes it after the landing wait. NA2 retains the same12-byte
node layout and decision path through `field_ai_danger_head` (`0x00708DE0`),
with lists at background+100 instead. Both games initialize these lists empty.

Reaction selectors are game-specific. The sandstorm sets UN3 selector0B,
which selects substate32; NA2 selector0D selects corresponding substate34.
Their motion rows share the flags, event, planar/vertical speeds and damping.
The dive sets UN3 selector13/substate3E; NA2 selector15/substate40 has its
byte-identical24-byte motion row: zero planar speed, vertical -50, damping0.35,
gravity auxiliary1.25, pause1 and lock120. The rows are at UN3 resident
`0x00389778` and NA2 resident `0x004078C8`.
