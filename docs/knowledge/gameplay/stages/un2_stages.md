# UN2 battle stages

## Research coverage

Established: archive set, format version and NA2 parser compatibility, the
scene record table and its walker, the six-scene record census (scenes 0, 9,
10, 11, 16, 17) with every handler's address and UN3 counterpart or
behavior, stage node placement, collision attribute words, content
comparison with UN3's same places, the per-scene camera, route, intensity,
render, music, glare and auxiliary tables, US/JP differences, Stage Select choices,
previews and names, the surface effects and sounds, stage sounds, the
scene-keyed code census, every UN3-matched type's differences from UN3, the
fighter-pair placement's scene rules, the pest characters' and support
points' records, the event that names `0x59F`'s puff fighter, and the
jutsu camera that `0x00770BE0` ends, and the users of the scene-9 draw
environment branch and the rectangle lists.
Names come from `@annotations/UN2`; UN3 and NA2 comparison names come from
`@annotations/UN3` and `@annotations/NA2`.
Open: nothing.

This document owns retail UN2 (US `SLUS-21575`, JP `SLPS-25398`)
battle-stage facts and their correspondence with UN3 and retail NA2
(`SLPS-25837`). UN3's design, which UN2's resembles closely, is in
[UN3 battle stages](un3_stages.md); NA2's contracts belong to
[Battle stages](stages.md).

## Evidence and address convention

Evidence is static, from MCP target `UN2` (programs `SLUS_215.75` and
`BATTLE.BIN`) and the `@source/UN2.iso.files` and `@source/UN2_JP.iso.files`
extractions, with `@disassembly/UN2/manifest.tsv` identifying the programs.
`BATTLE.BIN` loads whole with its header at live base `0x006AB000` (JP
`0x00713800`), so a complete-file offset is the live address minus that base.
`SLUS_215.75` maps file offset `0x800` to `0x00100000`. Addresses below are
live US addresses unless marked JP.

## Archive set and CCS format

`STAGE/` holds 18 archives in both releases: `S0A2`, `S0B2`, `S1A2`, `S1B2`,
`S1C2`, `S2A2`, `S2B2`, `S2C2`, `S3A`, `S3B`, `S4A2`, `S4B2`, `S5A2`, `S5B2`,
`S6A`, `S6B`, `S7A` and `S7B`. JP also holds `S0A`, `S0B`, `S1A`..`S1C`,
`S2A`..`S2C`, `S4A`, `S4B`, `S5A` and `S5B`, dated 2003; no `BATTLE.BIN`
path names them. Each archive is a gzip CCS stream whose container name is
its lowercase stem, with version `0x111`; NA2, UN3 and UN4 stage archives
are `0x123`. The builder's section walk consumes each completely. The 18
decompress to the same bytes in both releases.

| Archive | Compressed | Decompressed | Archive | Compressed | Decompressed |
| --- | ---: | ---: | --- | ---: | ---: |
| S0A2 | 332,737 | 974,772 | S3B | 534,754 | 997,232 |
| S0B2 | 365,086 | 1,106,784 | S4A2 | 389,134 | 1,225,316 |
| S1A2 | 546,192 | 1,365,324 | S4B2 | 576,128 | 1,290,496 |
| S1B2 | 590,975 | 1,300,436 | S5A2 | 465,814 | 1,222,276 |
| S1C2 | 362,896 | 1,087,760 | S5B2 | 440,600 | 1,358,904 |
| S2A2 | 399,171 | 1,061,584 | S6A | 589,300 | 1,377,960 |
| S2B2 | 547,737 | 1,352,944 | S6B | 366,429 | 1,021,780 |
| S2C2 | 601,274 | 1,357,412 | S7A | 457,661 | 1,378,160 |
| S3A | 287,539 | 731,748 | S7B | 568,396 | 1,345,772 |

No archive holds a `BIN_bgdata` object or position markers (`0x1300`/`0x1400`
sections). Besides the common types, `S0A2` holds a `0x1900` morpher driven by
61 `0x1901` animation blocks, and every other animation block is a `0x0102`
object transform, a `0x0202`, `0x0601` or `0x0603` block, or a frame marker,
the kinds UN3's stage animations use.

NA2's parsers keep a branch for every version gate the section types of
these archives reach
([older-version branches](../../game/files/ccs_object_types.md#older-version-parser-branches)),
and its position-marker and binary-blob parsers have no gate. A container's
version applies to all its sections, so sections from a `0x123` container
cannot be copied into a UN2 archive unchanged.

## Stage table and scene records

UN2 compiles its stage configuration into `BATTLE.BIN`, as UN3 does.
`stage_scene_tables` (`0x0081C760`, JP `0x00884870`) holds 18 pointers and
a null terminator, each to a zero-terminated list of 32-byte records with
UN3's layout ([UN3 scene records](un3_stages.md#un3-stage-table-and-scene-records)).
The first record of each list has type 1, the stage's label and its archive
path. The six scenes below have identical records in both releases.

| Index | Archive | Label | US Stage Select name |
| ---: | --- | --- | --- |
| 0 | `stage/s1a2.ccs` | 一楽2 | Ichiraku Ramen Shop |
| 1 | `stage/s1b2.ccs` | 顔岩2 | Hokage Great Stone Faces |
| 2 | `stage/s2a2.ccs` | 試験会場2 | Chunin Exams Stadium |
| 3 | `stage/s2b2.ccs` | やぐら2 | Top of Lookout Tower |
| 4 | `stage/s2c2.ccs` | 死の森2 | The Forest of Death |
| 5 | `stage/s1c2.ccs` | 城屋根2 | Kikyo Castle Tower |
| 6 | `stage/s4a2.ccs` | ナルト大橋2 | Great Naruto Bridge |
| 7 | `stage/s4b2.ccs` | 再不斬の隠れ家2 | Zabuza's Hideout |
| 8 | `stage/s5a2.ccs` | 砂肝亭と仏像2 | Sunagimo Estate and Buddha Statue |
| 9 | `stage/s5b2.ccs` | 風影の屋敷2 | Kazekage's Mansion |
| 10 | `stage/s0a2.ccs` | 演習場2 | Training Field |
| 11 | `stage/s0b2.ccs` | 慰霊碑2 | Hero's Memorial Monument |
| 12 | `stage/s6a.ccs` | 木ノ葉温泉 | Hidden Leaf Hot Spring |
| 13 | `stage/s6b.ccs` | 木ノ葉の森 | Hidden Leaf Forest |
| 14 | `stage/s7a.ccs` | 短冊街 | Tanzaku Town |
| 15 | `stage/s7b.ccs` | 短冊街のはずれ | Tanzaku Town Outskirts |
| 16 | `stage/s3a.ccs` | 雪原 | — |
| 17 | `stage/s3b.ccs` | 虹の氷壁 | — |

The US name list (`SLUS_215.75` file offset `0x40B880`) holds the 16 names
above in scene order. JP's (`SLPS_253.98` file offset `0x487CF8`) holds 18
with ruby readings, ending with 雪原 (snowfield) and 虹の氷壁 (rainbow ice wall); the
US release has no English name for scenes 16 and 17.

## Stage Select presentation

Stage Select is in `BATTLE.BIN` and loads `MAPSEL1.CCS`.
`stage_select_initialize_choices` (`0x006AF200`, JP `0x00717950`) lists
scenes 0..15 (JP 0..17) as choice bytes, keeping scene pairs by
availability, and `stage_select_confirm_scene` writes the chosen byte to the
battle context's scene; US entries 16 and 17 are random and next, JP's 18 and
19. US Stage Select therefore never offers scenes 16 and 17.

`stage_select_bind_preview` (`0x006B0F40`) shows scene `s` from
`haipure(s / 8 + 1)` (`stage_select_preview_texture_names`, `0x0081C700`):
column `(s % 8) / 4` at 256 pixels, row `s % 4` at 128, a 256×128 cell, on
the `MDL_gamen` quad, whose UVs show pixels 40..214 by 2..128 of the cell.
`stage_select_draw_thumbnails` (`0x006B0760`) draws a 64×48 sprite from
`haipure_s01` at `stage_select_thumbnail_origins` (`0x0081C6A0`).

| Scene | Big preview cell, shown part | Thumbnail |
| ---: | --- | --- |
| 0 | `haipure01` (0, 0)–(256, 128), x 40..214, y 2..128 | (1, 1) |
| 9 | `haipure02` (0, 128)–(256, 256), x 40..214, y 130..256 | (65, 49) |
| 10 | `haipure02` (0, 256)–(256, 384), x 40..214, y 258..384 | (129, 49) |
| 11 | `haipure02` (0, 384)–(256, 512), x 40..214, y 386..512 | (193, 49) |
| 16 | `haipure03` (0, 0)–(256, 128), x 40..214, y 2..128 | (1, 97), JP |
| 17 | `haipure03` (0, 128)–(256, 256), x 40..214, y 130..256 | (65, 97), JP |

Boxes are top-down pixels. The decompressed US and JP `MAPSEL1.CCS` differ
only in `TEX_haipure_s01` and `CLT_haipure_s01`, the thumbnails; the big
previews are identical. The thumbnails are the same shots with different
palettes: the six cells above differ by up to 123 levels per channel. US's
texture holds the snow thumbnails at JP's cells, but only JP's Stage Select
draws them.

## Scene-record dispatch

`stage_scene_construct` (`0x002D6FA0`, resident) publishes the scene index
to byte `+0x41` of the object at `gp-0x681C` and byte `+0x0E` of the one at
`gp-0x6558`, walks the scene's records and switches on the category (type
bits 8..15), then runs fixed setup. Category 0 adopts the archive's basename
and resolves `BLT_bg`/`BLT_obj`, as UN3's does; categories 1..14 call their
own handlers, and category 3 is followed by `0x002D63A0`. Unlike UN3, which
skips category 12, UN2 has a category-12 handler (`0x002DB450`).

| Category | Handler (resident) |
| ---: | --- |
| 1 | `stage_parse_fog` (`0x002DB220`) |
| 2 | `stage_parse_category2` (`0x002DB390`) |
| 3 | `stage_parse_far_objects` (`0x002DBF90`), then `stage_prepare_doll_nodes` (`0x002D63A0`) |
| 4 | `stage_parse_base_animation` (`0x002DC850`) |
| 5 | `stage_parse_animation_props` (`0x002DC960`) |
| 6 | `stage_parse_transparent_objects` (`0x002E77C0`) |
| 7 | `stage_parse_creature_props` (`0x002E0ED0`) |
| 8 | `stage_parse_reactive_props` (`0x002E2920`) |
| 9 | `stage_parse_category9` (`0x002E48D0`) |
| 10 | `stage_parse_player_nodes` (`0x002DAAE0`) |
| 11 | `stage_parse_line_nodes` (`0x002DAB80`) |
| 12 | `stage_parse_point_nodes` (`0x002DB450`) |
| 13 | `stage_parse_lighting` (`0x002DB600`) |
| 14 | `stage_parse_cl_lines` (`0x002DBBD0`) |

Categories 3 and 5..9 allocate one object per record, install a subtype's
vtable from `SLUS_215.75` (`+0x10` update, `+0x14` draw, `+0x18` destroy) and
call its constructor and parser in `BATTLE.BIN`.

## Record types of the six scenes

Scenes 0, 9, 10, 11, 16 and 17 use these types. UN2 numbers its subtypes
differently from UN3: the training and monkey dolls are `0x825`/`0x826`
(UN3 `0x81C`/`0x81D`), the wind `0x51D` (UN3 `0x518`), and the falling and
rising leaves `0x53B`/`0x53D` (UN3 `0x52B`/`0x52D`). The UN3 counterparts
come from comparing each UN2 function's normalized instructions with every
UN3 `BATTLE.BIN` function; the figure is the best match's similarity. It
establishes correspondence, not identical tokens or constants.

| Type | Label | Scenes | UN2 parser | UN3 counterpart |
| --- | --- | --- | --- | --- |
| `0x001`, `0x101`, `0x201`, `0x401` | archive, fog, category 2, base animation | all | category handlers | categories 0, 1, 2, 4 |
| `0x301` | far animation | all | category 3 | `0x301` |
| `0x334` | 水面 (water surface) | 10 | `stage_water_surface_parse` (`0x006DCEA0`) | a category-3 helper (0.93) |
| `0x36F` | 演習場水底 (riverbed) | 10 | plain object, vtable `0x00553F20` | — |
| `0x501` | — | 16 | plain object; scene 16's names no animation | `0x501` |
| `0x502` | 電線 (wire) | 0 | `stage_wire_parse` (`0x006D9780`) | `stage_wire_parse` (0.77) |
| `0x506`, `0x507` | のれん (noren) | 0 | `stage_sway_animation_parse` (`0x006B9510`) | `stage_sway_animation_parse` |
| `0x50E` | 新葉っぱ (new leaves) | 11 | `stage_landing_tree_parse` (`0x006FC590`) | landing tree (update 0.76) |
| `0x51D` | 風力 (wind) | 0, 10, 11 | `stage_wind_parse` (`0x006F5900`) | `stage_wind_parse` (0.73) |
| `0x524` | 新舞う木の葉 (flying leaves) | 0 | `stage_flying_leaves_parse` (`0x00704E30`) | `stage_flying_leaves_parse` (0.60) |
| `0x536` | 揺れる草 (swaying grass) | 10, 11 | `0x006F0DB0` | swaying leaves (draw 0.88; parse and update below 0.45) |
| `0x537` | 揺れる葉の影 (swaying leaf shadows) | 10 | `0x006F16A0` | swaying leaves (update 0.76) |
| `0x538` | 揺れる葉 (swaying leaves) | 0, 10, 11 | `stage_sway_leaves_parse` (`0x006F1FC0`) | `stage_sway_leaves_update` (0.94) |
| `0x539` | 桜の花びら (cherry petals) | 10 | `stage_cherry_petals_parse` (`0x006FF360`) | — |
| `0x53B` | 舞い散る落ち葉 (falling leaves) | 0 | `stage_falling_leaves_parse` (`0x00700D20`) | `stage_falling_leaves_parse` (0.61) |
| `0x53D` | 巻き上がる落ち葉 (rising leaves) | 0 | `0x007017D0` | `stage_rising_leaves_update` (0.61) |
| `0x579` | 雨 (rain) | 11 | `stage_rain_parse` (`0x006FA620`) | — |
| `0x57B`, `0x57C` | 草の/慰霊碑の水飛沫 (grass, monument spray) | 11 | `stage_grass_spray_parse` (`0x006FAFD0`), `stage_memorial_spray_parse` (`0x006FB560`) | — |
| `0x57D` | 雲光 (lightning) | 11 | `stage_lightning_parse` (`0x006FB890`) | — |
| `0x57E` | 水溜りの波紋 (puddle ripples) | 11 | `stage_puddle_ripples_parse` (`0x006FC2B0`) | — |
| `0x57F` | 動く雲 (moving clouds) | 11 | `stage_moving_clouds_parse` (`0x006FE960`) | — |
| `0x580` | ぼかし (blur) | 11 | `stage_blur_parse` (`0x00705370`) | — |
| `0x58D` | 擬似ブラ提灯 (trail lanterns) | 9 | `stage_trail_lanterns_parse` (`0x00709540`) | an unnamed update (0.81) |
| `0x59A` | 氷壁の虹 (ice-wall rainbow) | 17 | plain animation; its update only advances the model | — |
| `0x59B` | ダイヤモンドダスト (diamond dust) | 17 | `stage_diamond_dust_parse` (`0x0070B9D0`) | — |
| `0x59C` | 氷壁エフェクト (ice-wall effect) | 17 | `stage_ice_wall_effect_parse` (`0x0070BC80`) | — |
| `0x59D` | 揺れる針葉 (swaying needles) | 16 | `stage_sway_needles_parse` (`0x006F25E0`) | swaying leaves |
| `0x59E` | 雪 (snow) | 16 | `stage_snow_parse` (`0x006F2A50`) | — |
| `0x59F` | 足跡 (footprints) | 16 | `stage_footprints_parse` (`0x006F2E20`) | — |
| `0x601` | 透過柱 (transparent pillar) | 9 | `stage_transparent_parse` (`0x006DC650`) | `stage_transparent_parse` (0.60) |
| `0x660` | 電灯の光 (lamp light) | 9 | `stage_lamp_light_parse` (`0x006D9120`) | an unnamed update/draw pair (0.88) |
| `0x786` | 一楽布シミュ (cloth) | 0 | `stage_cloth_parse` (`0x007086A0`) | `stage_flag_update` (0.59) |
| `0x801`, `0x898` | tanks, signs, crates | 0, 9 | `stage_breakable_parse` (`0x006B7A20`) | `stage_breakable_parse` (0.73) |
| `0x803` | ちょうちん (lanterns) | 0 | `stage_breakable_parse`, lantern vtable `0x00554540` | `0x803` |
| `0x825` | 訓練君 (training dolls) | all | `stage_construct_training_dolls` (`0x002D7720`) | `0x81C` |
| `0x826` | うっきー君 (monkey doll) | all | `stage_monkey_doll_parse` (`0x006C0E30`) | `stage_monkey_doll_parse` (0.92) |
| `0x846` | 風影の積荷 (cargo) | 9 | `stage_cargo_parse` (`0x006C6700`) | cargo (draw 0.83) |
| `0x862` | 自動販売機 (vending machine) | 9 | `stage_vending_machine_parse` (`0x006C8A50`) | `stage_vending_machine_parse` (0.88) |
| `0x88A` | 影付きオブジェクト (shadowed object) | 0 | `stage_shadowed_object_parse` (`0x00708E20`) | `0x863` |
| `0x990` | お邪魔キャラ (pest characters) | all | `stage_intruder_parse` (`0x00712860`) | — |
| `0xA08`/`0xA09`, `0xB01`, `0xD01`, `0xE0A`/`0xE0B` | players, line nodes, lighting, `cl` lines | all | categories 10, 11, 13, 14 | same |
| `0xC0A` | 前 | all | `stage_parse_point_nodes` | — |

Behavior of the types without a UN3 counterpart:

| Type | Behavior |
| --- | --- |
| `0x334` | Plays the resource animation with its playback step divided by token 10 when nonzero (scene 10's two records hold 0), in a draw environment of its own registered at priority `-0xF00` plus a per-scene counter, sized to the screen (`0x00106170`); its update advances the animation and the model at `+0x30`. UN3 `S17` records the same rivers as `0x690` frame animations (`stage_frame_animation_parse`), with divisor 1 and no draw environment. |
| `0x36F` | A plain animated object (vtable `0x00553F20`) in the far-object list. |
| `0x539` | Seven looping generators (`0x00820440`, fields `0x00820970`/`0x008209B0`) at `OBJ_ha_010`..`070` with `CMP_s0aefe00` at scale 0.25 (`+0x30`), fading in from 100 to 500 units (`0x00839230`/`0x00839238`) and out at the generator's default 4,000 to 5,000; a generator (`0x00820478`, same fields) that the update (`0x00700050`) keeps 250 units ahead of the camera toward its target and 100 higher; and bursts (`0x006FFB40`) from 50 to 150 above a fighter at x -1100..-830 or 870..1100 in section 0, otherwise -950..-750 or 770..950, without distance fade, six slots per kind: on a section transfer (1, `0x15`/`0x16`, `ACT_LIN_0`/`1`) generator `0x00820C50` (fields `0x00820C90`/`0x00820CB0`), turned after 16 updates to the force objects of `0x00820CD0`, `0x00820CF0` and `0x00820D10`; on (5, `0x3D`), `ACT_DMG_BD` (NA2's `0x40`), generator `0x00820D30` (`0x00820D70`/`0x00820DB0`), turned to `0x00820D90`. Each update applies the generator visibility to all of them and, until `+0xB1` of the object at `gp-0x6560` is set, writes the wind q = -`gp-0x657C`, at least 0.2 either way, into the rows: field `0x00820970`'s values 0 and 2 become 8q and -5 - 3\|q\| (`0x00820980`, `0x00820988`) and the trees' emission rate 1 + \|q\| (`0x00820458`). UN3 splits these into its falling, flying and rising leaves. |
| `0x579` | 50 drop models `OBJ_s0befe00` (`0x008395C0`) at local (±50, ±40, 30), the first time at a random height within ±35, falling 8 + up to 2 per update and respawning below -35. Each update (`0x006FAA10`) places them, unrotated, at the point 100 ahead of the camera's eye toward its target (camera `+0x10`, `+0x60`) plus their local position, computed before a respawn; sets opacity 0.2 (0.75 at parse); turns them to (-camera `+0x20`, 0, camera `+0x28` - π) and scales them (0.1, 1, 5) (`0x0081D220`). The draw (`0x006FAEE0`) submits them in draw environment 3 (stage owner `+0x0C`, priority 15) unless `0x002B0C90` reports the mask at battle context `+0x2EC` and latch `+0x2E8` set. |
| `0x57B`, `0x57C`, `0x57E` | Looping generators from the 0x38-byte descriptor table at `0x0081FF70`, without distance fade: the grass spray rows 12..18 at `OBJ_sibuki_010`..`070` and row 13 at (-1080, 0, 50), (1030, 0, 50) and (1050, 1100, 50), each with growth field `0x00820950` (key 5, scale 0.1 to 0.3 over five ages) and `EFF_s0befe01`, scale 1; the memorial spray rows `0x13`..`0x15` at (0, 1850, 200), (0, 1850, 100) and (0, 1700, 100) with `EFF_s0befe02`, scale 0.2 (`+0x30`); the puddle ripples rows 6..11 at `OBJ_hamon_010`..`060`, catalog row 12 (`effect0x`/`ANM_e0x_ring_01`), scale 0.2. Their updates apply the generator visibility; their draws are empty. |
| `0x57D` | Lightning: models `OBJ_s0befe03` (single) and `_04`..`_06` (group), fog flags cleared. After a wait of 4 × 60 / frame divisor updates, with `0x002A9650(450)` = 0 (one in 451) while no group shows, `0x006FBA90` places the group at (±10000, 40000, 3000) (`0x0081D2B0`), each model at scale (80, 1, 100) or, with even odds, (0, 0, 0), at least the first showing, and the single model 2000 nearer and 5000 higher at (250, 1, 60), all at opacity 0.75, which falls by 0.05 per update; it sets `gp-0x6568` and writes the stage owner's glare pass `+0x270` amount from 0.1 down by 0.01 to -0.3. `0x002D4930` draws that pass (mode 1, colours `0x80808080`/`0xFFFFFF` from [scene 11's glare row](#scene-glare)) in the owner's environment `+0x28` (priority 16) while `gp-0x6568` is set and `stage_flash_allowed` (`0x002EB210`) is nonzero: it is zero only in battle while the last active of the battle's four jutsu actors (battle `+0x1048`, updated by `battle_update_jutsu_actors`, `0x00758D20`, which leaves the actor's resource index in `gp-0x6F70`) is built from resource 1, `2nrtcha0.ccs`. While no group shows and the single model's own opacity has fallen by 0.05 to 0, `0x006FBD80` draws 0..100: 0 shows it alone at (±8000, 38000, 8000 ± 1000) at (100 + up to 150, 1, 30 + up to 30) and opacity 1, 1 the group without a flash. The draw (`0x006FC200`) submits the group while it shows and always the single model. |
| `0x57F` | Three animation players, `ANM_s0bare04` (`0x00839710`) and twice `ANM_s0bare05` (`0x00839720`), at the origin from random angles about the vertical axis; the update (`0x006FEBB0`) turns the first two by +0.0025 and the third by -0.0025 radians per update. The first's opacity (player `+0x88`) bounces by 0.001 between 0.1 and 0.2; the others' takes their step instead of adding it, which clamps it to 0.1. The draw (`0x006FEEA0`) submits them in draw environment 0 (priority -0x1400), the first a second time turned π about component 1. |
| `0x580` | A glare-filter pass (`0x002B2310`, matching UN3's `pause_auxiliary_refresh` initializer at 0.73, the class NA2's factory 11 builds) with token 8 (`-0.019`) at `+0x88`, token 9 (`0x808080`) at `+0x8C` and token 10 (`0x3A808080`) at `+0x84`. |
| `0x58D` | Token-5 lanterns at the token-3 stem's nodes `<stem>0`, `<stem>1`.. (`%s%d`, `0x00839B68`), each the token-7 composition with a token-6 glow effect. The update (`0x00709890`) turns each lantern about the depth axis by 0.65 × sin(phase), replacing the second float of `(0, 0, 0, 1)` at `0x0081D890`, the phase starting at random(360) and stepping 4° per update, less 360 above 360, and stores the glow's position, (0, -10, token 9) turned with the lantern from its node, in the next slot of a ring of 32. The draw (`0x00709A80`) submits each composition, then shows the first token-10 lanterns' glows at frame 0 from ring slots head + 0, 8, 16 and 24, which are 0, 24, 16 and 8 updates old, at alpha 1, 0.6, 0.36 and 0.216 and size 0.6, 0.525, 0.45 and 0.375, and each other lantern's glow once, in the stage's environment. The scene's tokens 9 and 10 are -30 and 2. |
| `0x59B` | One generator (`0x00821B80`, fields `0x00821BC0`/`0x00821BE0`) at alpha 0.5, which the generator visibility sets to 1 from the first update, kept 400 units from the camera toward its target and 200 lower (`stage_diamond_dust_update`, `0x0070BAC0`), fading in from 100 to 500 and out from 6,000 to 8,000 units (the `0x524` squares). |
| `0x59C` | Eleven looping generators from 0x40-byte rows at `0x0081DCB0`: origin `+0x00`, second point `+0x10`, generator descriptor `+0x20`, four field descriptors `+0x24..+0x30` (null when absent), scale `+0x34`. Rows 0 and 1 have origin (0, 2950, 230), generators `0x00821C00`/`0x00821C38` with one field each, and scales 1 and 3. Their resources are `EFF_e0xpar00` and `EFF_x002` from `CMN/PARTICLE.CCS`. The parser turns off each generator's distance fade; the update (`0x0070BE30`) applies the generator visibility. |
| `0x59E` | One generator (`0x00821D60`, field `0x00821DA0`) at (150, 400, 200) with material `EFF_s3aefe01` and scale 7.5, fading as `0x59B`'s. Its update (`0x006F2BB0`) raises global `gp-0x70C0` (`0x0055F6B0`, 200 at boot) toward 3500 by 10 per update and copies it to the origin's height; nothing resets it, so only the first scene-16 battle after boot starts the snow low. It sets alpha `+0x108` to 0 under `stage_effect_allowed(2)`, otherwise 1, and stops the generator as the visibility does. |
| `0x59F` | 30 footprint models of the token-6 composition per foot per fighter, at opacity 0.5 fading by 0.01. On a `0xF0F0F0` surface within 20 below a foot, a print is placed 4 above the last contact when the foot lifts: NA2's `ccBgFootMarkBattle` (factory 93) with the same pools and constants, which selects surfaces by a mask where UN2 tests snow alone. UN2 also starts a puff effect for three updates at the fighter that `stage_owner_knockdown_contact` (`0x002E9970`) names in `gp-0x70BC`: on scene 16 it stores the side of a fighter whose knockdown landing (`fighter_knockdown_landing`, `0x001A45E0`, damage states `0x3A`..`0x3D`) meets a contact word with bit `0x400`, which also doubles that landing's damage, through `0x0081BFA0`. In S3A only the `0xE004EF` batch (4 triangles) has that bit. |
| `0x660` | Token-5 copies of the token-6 effect (`EFF_efe_000_`, 31 frames, 0..15 at full alpha, then fading to 0 at 30) at the token-3 node and its `_N` siblings (`%s_%d`). The parse writes 0.75 to each copy's relative opacity (`+0x88`), which, with no parent, the resolver (`SLUS_215.75` `0x0014694C`) does not read, and starts each on a random frame of -1..29, -1 drawing nothing. It flags copies 5 and 6 (`+0x41`, `+0x42`); the constructor (`0x006D90C0`) clears the flags of copies 0..6 only. Each update (`0x006D94D0`) a steady copy shows a random frame of 0..13; a flagged one counts its hold down, then shows a random frame of 14..28 and holds 0..59 updates on 14..16, otherwise 0..1. The draw (`0x006D96D0`) skips while `stage_effect_allowed(2)` reports nonzero. |
| `0x990` | Loads `ojmgmk`, `ojmgmt`, `ojmpkn` or `ojmnkm` and their characters, only when the battle-mode object exists, its mode is not 1 or 6, and `battle_mode_intruders_enabled` (`0x0023C3D0`) is set: the pest characters, which UN2's battle settings can allow (help text `SLUS_215.75` `0x0053F170`). NA2's executables name none of these files. |
| `0xC0A` | Stores the positions of `OBJ_ps_010` and its siblings (token 5, four in every scene) and token 0 in the stage control (`+0x214`, count `+0x20C`, token 0 `+0x210`): the points where the support characters appear. `0x002825F0` gives them, 2 higher, to the two per-side support actors (`0x00282850`), the first token-0 as type 1 and the rest as type 2, when `0x0023BE30` passes and the battle mode (context `+0x3C`) is not 1. Each appearance (`0x00285BF0`) stands the support at a random point other than the other side's, on section type - 1, section 1 in the six scenes, whose token 0 is 0. NA2's supports enter through its support owner and read no stage point ([Battle support mechanics](../characters/support_mechanics.md)). |

The generator rows use NA2's layouts: 0x38-byte generator descriptors and
0x20-byte force descriptors whose keys are NA2's
([force keys](../../runtime/rendering/particle_runtime.md#force-field-consumer-table)).
UN2's generator (`particle_generator_construct`, `SLUS_215.75`
`0x002A46B0`, 0x130 bytes) sets bit 0 of `+0x04`, which turns on each
particle's distance fade (`particle_distance_fade`, `0x002A7C60`): alpha 0
outside the squared distances at `+0x118` and `+0x120`, ramping in to
`+0x114` and out from `+0x11C`, by default 50, 400, 4,000 and 5,000 units.
`+0x30` is its scale, `+0x108` and `+0x10C` its two alphas. The generator
visibility (`stage_generator_visibility`, `0x006EC0A0`) sets a live
generator's `+0x10C` to 0 under `stage_effect_allowed(2)` or while
`0x002B0C90` reports true and otherwise to 1, and stops it once byte
`+0xB1` of the object at `gp-0x6560` is set.

A particle (fade `0x002A79A0`) starts at
alpha 0 with the descriptor's fade-in (`+0x2C`) and fade-out (`+0x2E`) and a
lifetime from `+0x0C` reduced by up to `+0x20` of it. Each update it counts
its age; once the age reaches the lifetime it turns to fading out, from
whatever alpha it has, otherwise it adds the fade-in up to 0x800 (full).
Its draw alpha is that alpha / 2048 times the generator alpha `+0x10C`. A
2-update spray with fade-in 0x400 therefore shows at half alpha, then a
quarter. NA2's `particle_fade_update` instead completes the fade-in, then
holds for the lifetime.

UN2's model instances (`0x00149CA0`, TEST state at `+0x28`, setter
`0x0014AD90`) start with the TEST state NA2's `model_instance_set_blend`
gives
([Material render modes](../../runtime/rendering/material_render_modes.md)):
`0x100B` for blend selectors 0 and 4, otherwise `0x1001`, without depth
writes. The `0x537` leaf shadows and `0x57D` lightning keep it and draw
from the stage objects' pass through the ordinary composition and model
submits (`0x00151C10`, `0x001518F0`), where the `0x579` rain draws in
environment 3.

UN3's `S01` records are scene 0's renumbered: the 忍看板 sign is a plain
`0x801`, the shadowed objects `0x863`, and the sound pairs are the same
numbers. The types with a UN3 counterpart differ from it only as follows;
the rest of their parse, hit, update and draw is UN3's.

| Type | Differences from UN3 |
| --- | --- |
| `0x502` | The fighter reaction (`0x006DAA30`) forgets the fighter's remembered position whenever its major state changes, so a state change alone can shake the wire, and accepts heights below 150 (UN3 up to 150). |
| `0x506`, `0x507` | The parser reseeds the random generator (`0x002A94A0`) before choosing amplitudes and phases, and the props are not opted into restricted updates, so they stop swaying under a restriction where UN3's keep going. |
| `0x50E` | The landing extra (`0x006DC160`) draws its item from kinds 5, 1 and 0 with weights 60, 40 and 0 (`0x0081CE10`) before its one-in-five chance (UN3 after it): kind 5 is item 9 (`gp-0x7138`), kind 1 item 1 or 4 (`gp-0x7140`). UN2's item amounts (`SLUS_215.75` `0x004154A0`, read by `0x00253DB0`) give items 1, 4 and 5 0.05, 0.10 and 0.15 health and items 8 and 9 5, 10 10, 11 15 and `0xC` 1 chakra (`0x00253820` marks the chakra items). It launches the item at (0, 0, 30) without UN3's random horizontal speed (`0x006B72F0`), which, by the items setting (`0x0023BD80`), adds nothing at 0, no extras at 1, and at 2 a second item four times in five and two extra `0xC` chakra items. The leaf variant follows the fighter's position: on scene 11, 5 within 200 of x = -825, 4 within 200 of x = 825, otherwise 0 (`0x002D8AD0`). |
| `0x51D` | As UN3's `0x518`, it never sounds: `stage_wind_update` starts sound `0x3E` only if byte `+0x30` is set, which the constructor (`0x006F58B0`) clears and the parse leaves clear. Its control row (`0x00419080`) gives volume 80 against UN3's 64; its samples are UN3's, which NA2's common program `0x27` holds. |
| `0x524` | The leaves fade in from 100 to 500 and out from 6,000 to 8,000 units from the camera (squares at `0x00839230`..`0x00839248`, written by code at `0x0083EA34`), where UN3's fade out from 20,000 to 22,000. |
| `0x536` | Each piece starts a 20-update push with a one-in-eleven chance per update, as UN3's gusts start, adding -2 × wind (at least 0.3) along component 0 and lowering component 2 by as much, then damps by 0.98 until below 0.01 (`0x006F1200`); UN3's gusts last 100 updates and swing 20 × sine in 3° steps. |
| `0x537` | Tokens 6 and 7 name paired compositions sharing one opacity, which random-walks by up to 0.01 within 0.3..0.6 (`0x006F1AD0`); the wind sway moves components 0 and 1, where UN3's leaves move 0 and 2. |
| `0x538` | None (`0x006F2250`); UN2 binds compositions where UN3 binds models. |
| `0x53B` | None in its tokens or its generator and force rows (from `0x00820DF0`, byte for byte UN3's). Its wind rewrite (q = -wind, at least 0.2; horizontal force 4q, vertical base - 2\|q\|, emission × (1 + \|q\|)) moves live leaves in UN2 only (below). |
| `0x53D` | The second kind starts when a fighter's action timeline crosses its start (`0x00702100`) in major state 5, minor `0x41` `ACT_DMG_SD` or `0x42` `ACT_DMG_SD2` (action table `0x00410CB0`); UN3's starts on its `0x42` `ACT_DMG_SD`, `0x43` `ACT_DMG_SD2` or `0x45` `ACT_DMG_SBD`. NA2 numbers these `0x45`, `0x46` and `0x49` (`action_descriptor_table`, BTL `0x0089AEB0`). |
| `0x59D` | Ignores wind and token 10: each needle turns by 0.02 × \|sin(phase)\| about all three axes, the phase starting at random and stepping 3..5° per update (`0x006F2860`). |
| `0x601` | The draw (`0x006DCC00`) would move the pillar to draw environment 1 from blend 0.4 (UN3 1.0), but only when `stage_effect_allowed(4)` reports false, which it never does, so the pillar draws in the stage's pass at every blend; the update (`0x006DC790`) is skipped while byte `+0xB1` of the object at `gp-0x6560` is set. |
| `0x786` | No tokens: five flags from `0x0081D780`, (node, texture, solver selector) `OBJ_hata_010`/`TEX_s1aart18`/6, `_020`/`_19`/6, `_030`/`_14`/5, `_040`/`_16`/5 and `_050`/`_15`/5, each 260 × 680 (UN3: tokens 8 and 9 × 4, 208 × 544 in `S01`) on UN3's 4 × 6 grid with UN3's `stage_flag_constants` (`0x0081D850`), turned about the vertical axis by -5°, -10°, 5°, 10° and 0° (`0x0081D800`). The update (`0x00708AB0`) gusts by a random 0.8 in x and 0.01 in y and z (UN3 0.5 and 0.02). |
| `0x801`, `0x898` | The hit node is `OBJ_<stem>_hit` (`0x00838A78`; UN3 `DMY_`), and token 7 names a clump (`CMP_bre_*`) whose pieces are `_a1`..`_a3` (`0x0022F6B0`, with UN3's four pieces, 20 particles, gravity 9.8, bounce 0.6 and damping 0.8). `stage_breakable_react`, the update (`0x006B7FD0`), the draw (`0x006B86D0`) and its hit-flash colors (`0x0081CAC0`) equal UN3's. `0x898` only clears word `+0x148` after parsing, which the parser sets to 1 (UN3 `+0x138`): only props holding 1 join the COM's prop-target lists (`stage_build_breakable_ai_targets`, `SLUS_215.75` `0x002D5FC0`) and count for mission conditions `0x2C` and `0x2E` (`0x00728240`, `0x00728680`), so the sign stays breakable but the COM ignores it. UN3 records the same sign as a plain `0x801`. |
| `0x803` | None: the hit (`0x006B89A0`) also keeps the hitter's side on hits before the last, as UN3's does; the swing (`0x006B8E30`) and the break's item drop (`0x006B8890`, mode token 1) match. UN2 does not read token 6 (`EFF_efe_*`). |
| `0x825` | `stage_construct_training_dolls` builds token-5 dolls at the scene's doll nodes (`OBJ_dd_010` and siblings: six in scene 10, four in 16 and 17, two elsewhere). The parser (`0x006C1160`) sets the reappearance base to 30 × token 1 (UN3 10 ×), 300 updates in every scene, and needs no hit node: the attack sphere, radius token 9 × 2, follows the doll node at (0, -100, 100). A broken doll counts for its side (`gp-0x6560` `+0x30`) only on scenes 10 and 16 (UN3: scene 3). Dolls clear `+0x148` too; the COM targets them through their own list (`0x002D5C10`). The first hit breaks a doll (token 0 is 1) through `stage_breakable_react`, which plays the record's break sound, 58. |
| `0x826` | None (`stage_monkey_doll_parse`, update `0x006C0F10`). |
| `0x846` | None: `stage_cargo_parse` and the piece parser (`0x006C5F20`) are UN3's `0x835` cargo stack, with token-10 pieces (0 → 3) 100 apart at the token-3 node, each one sphere of radius token 9 at (0, -150, 50), falling by 0.12 and 9.8. Scene 9 names `ANM_s4akiz00`. |
| `0x862` | None: each hit counts for the hitter's side (`gp-0x6560` `+0x30`), and the drop chance (`0x006C8740`) is 5% when a side's count is exactly 10 on scene 9 (8 on scene 14), otherwise 20%. |
| `0x88A` | None: UN3's `0x863`, clearing fog flags `0x18` of the `<token 10>s1` shadow child (`0x00708E20`) and again after each damage animation (`0x00708EC0`). |

UN2's particle fields read their descriptor rows each time they apply
(`particle_field_apply`, `SLUS_215.75` `0x002A2BA0`), where UN3 copies the
rows at creation, so a stage's later writes to a row reach live particles
only in UN2. The wind's cycle and sound placement, the flying leaves'
tokens and motion, the rising leaves' rows and the noren, landing-tree and
wire equations are UN3's.

## Per-scene tables

All are indexed by scene without a range check.

| Table | Address | Reader |
| --- | --- | --- |
| `stage_camera_records_by_scene` | `SLUS_215.75` `0x00410390`, 18 pointers to 24-float records | `camera_bind_stage_record` (`0x001ED930`), camera `+0x17C` |
| `stage_navigation_authored_routes` | `BATTLE.BIN` `0x008251A0`, 18 pointers to 64 rows of 12 bytes | `0x00746A40` copies all 64 rows (UN3 stops at -1); a null pointer skips the copy |
| `stage_effect_intensity` | `SLUS_215.75` `0x004AD2D0`, 18 bytes | `effect_stage_intensity_tint_update` (`0x001E0BB0`), no default |
| `stage_render_coefficients` | `SLUS_215.75` `0x004424C0`, two floats per scene | `stage_apply_render_coefficients` (`0x002DAA30`) |
| `stage_music_tracks` | `SLUS_215.75` `0x00419B50`, a word per scene | `audio_apply_music_preset` (`0x002B8090`): member of `SOUND.AFS/000` unless the context `+0x1AC` override is set |
| `stage_scene_variants` | `SLUS_215.75` `0x00442470` | `0x002D8D10` selects the `_a` suffix of `BLT_bg`/`BLT_obj` for even scenes and `_b` for odd ones; each archive holds only its own |
| `stage_scene_auxiliary_filenames` | `SLUS_215.75` `0x00440070` | `3eye/3eye%s` paths |
| `stage_scene_rectangle_lists` | `SLUS_215.75` `0x0043EFA0`, 32-byte records of section, line, endpoint, side byte and rectangle | `stage_rectangle_x_offset` (`0x0027C9E0`): the x offset out of the first rectangle of the fighter's section containing a position. Only `actor_target_rectangle_x_offset` (`0x0027CB10`) calls it, for two actor update methods (call sites `0x00278618`, `0x0027A39C`); the first adds it to a fighter's x before placing it. No stage code reads the table. |
| `stage_scene_effect_defaults` | `SLUS_215.75` `0x004425D0`, 16-byte screen glare rows: enable byte, packed colour, float amount, packed second colour | `stage_apply_scene_glare` (`0x002DAAA0`) through `stage_glare_apply_scene_row` (`0x002EB5F0`), which overrides some colours on a stack copy, then sets the stage owner's glare pass (`+0x270`, mode 1) as UN3 does ([UN3 screen glare](un3_stages.md#per-stage-camera-anchor-and-route-tables)). As NA2 factory-11 tokens: scene 0 `50,200,250,0,-0.5,100,150,255`, 9 `100,50,50,100,-0.1,255,255,175`, 10 `50,130,130,130,-0.3,255,255,255`, 16 `100,120,120,120,-0.35,255,255,255`, 17 `100,125,125,125,-0.1,255,255,255`, 5 `128,128,128,128,-0.24,255,255,255`; scene 11 is disabled. `SLPS_253.98` holds the same rows. |

UN2 has no anchor list: no UN2 code matches UN3's
`stage_choose_combo_anchor` or its caller, and no data holds UN3's or NA2's
anchor-vector layout. A method that ten fighter vtables in `SLUS_215.75`
hold (`0x007BEDE0`, calling `0x007BB410`) places a fighter and its
partner (`+0x2A0`) in fighter states 3, `0x15`, `0x32`, `0x3D`..`0x40` and
`0x42` by probing the ground at distances per state, such as 500 for
`0x3D`. First `0x007BA710` checks per-scene rectangles (`0x00826AB0`, rows
of two corner points; each row's target row at `0x0083C150`): a fighter
whose x and height lie inside one is moved to one of its target row's two
points, picked by the partner's side, or, for target -1, the placement is
dropped. Among the six scenes only scene 0 has rectangles: while the
fighter is outside section 0 (its section is `+0x7A6`), rows 14 and 15
(x -1000..-450 and 450..1000, height 600..900) move it to x -900 or -700, or
700 or 900, at depth 500 and height 400, on the back line. After placing,
`0x007BB190` sets both fighters' heights to 50 on scene 11 and to 60 on
scene 10 outside section 0; UN3 `S04`'s anchors stand at height 50 and
`S17`'s at 0.

Sealed Orochimaru's Giant Snake: Underworld Dash (vtable `0x00555B30`,
`2forcha1.ccs`) sets up its two participants (`+0x90` and `+0x1D0`) in
`0x007F1620`, which places both fighters through `0x007F2210`: at their
`field_player_placement` start positions (`0x007F2440`), or on scene 17 at
the fixed point (0, 750, 220) of `0x00829640` in section 1, the first
participant 250 lower in component 0 (`0x007F2990`).

| Scene | Camera record | Intensity | Track | Render | Routes (source, destination, fraction, action) |
| ---: | --- | ---: | --- | --- | --- |
| 0 | 0.8, 0.4, 0.2, 0.1, 0.05, 0.8, 0.4, 0.2, 0.1, 0.05, 600, 3600, 900, -900, 1300, -1300, 1200, 200, 0.4, 10, 10, 1, 0, 0 | `0xCF` | `005.adx` | 0.45, 0.35 | (4,2,.1,1) (4,2,.9,1) (4,2,.5,1) (2,4,.45,4) (2,4,.2,4) (2,4,.9,4) (2,3,.1,1) (2,1,.9,1) (3,4,1,3) (1,4,0,3) |
| 9 | 0.65, 0.3, 0.15, 0.05, 0.03, 0.65, 0.65, 0.15, 0.175, 0.03, 600, 3300, 1000, -1000, 1200, -1200, 1500, 200, 0.8, 2.5, 5, 1.2, 0, 0 | `0x8F` | `010.adx` | 0.4, 0.4 | (0,1,1,3) (1,0,0,3) (1,2,1,3) (2,1,0,3) (3,4,1,3) (4,3,0,3) (4,5,1,3) (5,4,.05,3) |
| 10 | 0.65, 0.3, 0.15, 0.05, 0.03, 0.65, 0.65, 0.15, 0.175, 0.03, 600, 4500, 1000, -1000, 1200, -1200, 1500, 200, 0.8, 10, 2.5, 1.2, 0, 0 | `0xFF` | `004.adx` | 0.4, 0.4 | none |
| 11 | 0.65, 0.3, 0.15, 0.05, 0.03, 0.65, 0.65, 0.15, 0.175, 0.03, 600, 4500, 1000, -1000, 1200, -1200, 1500, 200, 0.8, 5, 10, 1.2, 0, 0 | `0x8F` | `004.adx` | 0.5, 0.3 | (3,2,.2,1) (2,3,1,3) (3,1,.75,1) (1,3,0,3) |
| 16 | 0.8, 0.4, 0.2, 0.1, 0.05, 0.8, 0.4, 0.2, 0.1, 0.05, 600, 3400, 900, -900, 1300, -1300, 1200, 200, 1, 10, 10, 1.5, 0, 0 | `0xCF` | `006.adx` | 0.3, 0.3 | (0,1,1,3) (1,0,0,3) (4,5,1,3) (5,4,0,3) (4,3,0,3) (3,4,1,3) (3,2,0,3) (2,3,1,3) |
| 17 | 0.8, 0.4, 0.2, 0.1, 0.05, 0.8, 0.4, 0.2, 0.1, 0.05, 600, 4000, 1500, -1500, 1300, -1300, 2000, 200, 0.8, 5, 12, 1.5, 0, 0 | `0x7F` | `006.adx` | 0.3, 0.3 | (0,1,1,3) (1,0,0,3) (2,1,0,3) (1,2,1,3) |

The camera records of scenes 9, 10 and 11 equal UN3 S08's, S17's and S04's
float for float; scene 0's differs from UN3 S01's (3600, 900 and 1200
against 4000, 1200 and 1500 among others). UN3's records have NA2's layout
([UN3 tables](un3_stages.md#per-stage-camera-anchor-and-route-tables)).
UN2's stage camera (`0x001ED960`) lowers its desired elevation by field
`+0x4C` when the fighters' sections differ and by `+0x50` whenever either
section is nonzero, both at once on different lines (scene 11: 15°);
NA2's `camera_stage_track` takes `+0x4C` alone there and `+0x50` only for
equal nonzero sections. Its fit (`0x001EE8A0`) and eye placement
(`0x001EF310`) follow NA2's routines, which project the fighters along that
elevation.
Scenes 10 and 11's routes equal UN3 S17's (none) and S04's. The
intensities of scenes 9, 10 and 11 are `0x8F`, `0xFF` and `0x8F`, against
UN3's `0x6F`, `0x7F` and `0x7F`.

The tracks are stereo 48 kHz ADX: `004` 5,068,835 samples, `005` 3,456,143,
`006` 3,836,498 and `010` 3,980,038.

### Scene glare

`stage_scene_construct` calls `stage_apply_scene_glare` (`0x002DAAA0`),
which writes the scene's `stage_scene_effect_defaults` row (above) through
`stage_glare_apply_scene_row`: its enable byte to `stage_glare_enabled`
(`gp-0x6568`) and its colours and amount to the stage owner's glare pass,
whether or not the row is enabled. While the byte is set and
`stage_flash_allowed` is nonzero, the owner's draw submits the pass
(`glare_pass_draw`, `0x002B2620`) in its environment `+0x28` (priority 16).
The pass shrinks the frame to 256, 128 and 64 pixels square, blurs it back
up to 256, subtracts the amount × 255 of the second colour, then adds the
result over the frame by its colour's alpha: light areas brighten and glow
into their surroundings. In the JP savestates of scene 17 the pass holds
the row's values and its draws come after the stage's particles and before
the HUD. Scene 11's disabled row still sets the colours its `0x57D`
lightning flash draws with.

## Scene-keyed code outside the stage records

These are the reads of the battle context's scene byte (`+0x41` of the
object at `gp-0x681C`, also reached as `0x0055FF54`) that compare it with
scene 0, 9, 10, 11, 16 or 17, from the decompiled `SLUS_215.75` and
`BATTLE.BIN` (133 read sites, comparisons on the byte or a local copy).
Reads through other fields or computed addresses are outside this census.

| Routine | Scenes | Behavior |
| --- | --- | --- |
| `0x001F1220` | 10, 6 | On `0xE0A000`/`0xE0E000` water: variant 1 on scene 10, 2 on scene 6 |
| `0x00206DC0` | 10, 6 | An effect selector set to 1 |
| `0x0021D500`, `effect_emit_manager_ground_code` (`0x00220230`) | 10 | Water contact variant 2 at scale 0.55 (UN3 does this on its scenes 9 and 16) |
| `field_player_placement` (`0x0081BFE0`) | 5, 6, 10 | Players start in section 1, which the routine returns for the fighter's section `+0x7A6` |
| `0x0073DF60` | 10, 6 (other branches 3, 8) | A COM with less than 2.5 chakra (`0x001974B0`, threshold at `0x0055F79C`) in route states 3..5, 9, `0x18`, `0x1A`, `0x1C` or `0x1D`, or 2 at step 5, replans and picks a random reaction, as UN3's `ai_water_chakra_gate` does on its scenes 9 and 16 |
| `0x00734A20` | 10, 6 (15) | With the fighter in section 0 on scenes 10 and 6 (section 1 on scene 15), COM route kinds `0x25` and `0x37` replan |
| `0x00770BE0` | 10, 6 | When a fighter is at or below height -10 while the battle context's jutsu camera (`+0x260`, updated by `jutsu_camera_update`, `0x00331A80`) runs a shot in state 1, `jutsu_camera_reset` (`0x00331EA0`) ends the shot with state 0, switching straight back to the battle camera (`jutsu_camera_apply_state`, `0x0033B430`), and clears byte `+0x134` of the object at `gp-0x6804` → `+0x10` → `+0x14` |
| `0x007325D0` | 0 (with 12, 13) | COM point routes take 40 instead of 10 as their near distance, as UN3's `ai_point_route_update` does on its scenes 0, 5 and 6 |
| `0x007BA710`, `0x007BB190` | 0; 10, 11 | Fighter-pair placement rectangles and heights (above) |
| `0x00818EF0`, `0x00807510` | 10 (with 4, 6, 15) | An actor's ground handling (`0x008181F0`), not stage code: landing on `E0E000` water or `0x202020` ground plays splash variant 2 on scene 10 (4 on 6, 3 on 15) and keeps 0.2 of its speed; `0x00807510` sets byte `+0x0E` of generator row `0x0082BAE0` to `0x15` on scenes 4 and 10 (`0x5C` on 6, `0x5F` on 15) before its burst and sound 9 |
| `stage_vending_machine_trigger` (`0x006C8740`) | 9, 14 | Hit-counter value 10 on scene 9, 8 on scene 14 |
| `knockout_screen_effect_begin` (`0x001F27C0`) | 9 | Part of the knockout screen effect: `battle_director_knockout` (`0x001BF518` call) sets draw environment `0x00561460` to priority `0x10` and starts the effect when the director's fighter `+0x20` is knocked out and its fighter `+0x24` is not. On scene 9 the effect sets that environment back to priority 0; other scenes reinsert manager `+0x2440` at its priority, 100 from setup. On every scene it moves qualifying actors to layer 3 (manager `+0x24C0`). After 31 updates `knockout_screen_effect_end` (`0x001F28F0`) restores the layers and reinserts `+0x2440` at priority 1, and the director sets `0x00561460` to 0. |
| `effect_emit_surface_puffs` (`0x0021C370`) | 16, 17 | Three `EFF_e0x_ice` particles; smoke variant `0x95` on scene 16 |
| `0x007D3610`, `0x007D36F0`, `0x007D7E70`, `0x007D7F50` | 16 | Treat the ground as `0xF0F0F0` snow in effect routines |
| `0x00286110` | 11, 17 | Credits a side counter through `0x006B6950` |
| `0x007F2210` | 17 | Sealed Orochimaru's jutsu places its participants at a fixed point (above) |
| `0x003307C0`, `0x007F40E0` | 0 | Jutsu-camera substitutions around the back platforms. The shared preset routine `0x003307C0` swaps in presets `0x8D`..`0x90` of table `0x0044A880` for controller kinds 3, 8, 9, 10, `0x10`, `0x13`, `0x21`, `0x27`, `0x2A`, `0x2E`, `0x34` and `0x37` when a participant in section 1 stands at 730 < \|x\| < 1000 and height 300..700 (rectangles at `0x005002F0`); Sealed Orochimaru's Giant Snake: Underworld Dash (`0x007F40E0`) picks its camera shots 7 and 8 at 500 < \|x\| < 1000 and height 300..800 in section 1 (`0x00829670`) |

Apart from the water-contact variant and the pair heights, every site that
tests scene 10 also accepts scene 6, the Great Naruto Bridge, as UN3 groups
its Training Field with its bridge.

## Stage nodes

UN2 names its nodes as UN3 and NA2 do but with an `OBJ_` prefix:
`OBJ_pp1_010`, `OBJ_line_010`, `OBJ_linemin01`, `OBJ_f_cl_1_nor`,
`OBJ_dd_010`, `OBJ_pg_*`, `OBJ_dummy_*`. Each is a scene object
(`0x0100` with a `0x2000` placeholder), placed by a `0x0102` transform at
frame 0 of the stage's base animation (`ANM_s??are00`); every `OBJ_` node
named by a record of scenes 0 and 10 is keyed there. Scene 10's nodes equal
UN3 S17's `DMY_` markers, for example `OBJ_pp1_010` at (-200, 1100, 50) and
`OBJ_f_cl_1_nor` at (-1150, 0, 0). NA2's mandatory records and line builders
request `DMY_` position markers
([mandatory records](stages.md#resident-generic-factories-and-mandatory-records),
[line construction](stages.md#line-construction)), which UN2's archives do
not contain.

Against UN3's same places, compared node by node: scene 10's player, line,
bound, `cl` and doll nodes all equal UN3 S17's; scene 11's equal UN3 S04's
except the outer ends of `b_cl_3_nor` (±1000 against ±1020); scene 9's equal
UN3 S08's except the outer ends of the first and last front and back lines
and the back bounds (10 to 55 units further in). Scene 0's layout differs
from UN3 S01's: its back line runs at depth 500 and height 400 where UN3's
runs at 1000 and 1100, and its `cl` lines differ in count and place. Scene
16's `linemax01`/`02` lie at x = 2000, beyond its line ends at 950/1125.

## Collision attributes

Each of the six archives has one stage hit mesh holding all its ground, walls
and limits (`HIT_s??are00_hit`); `S0B2` adds two `0xD80F` branch meshes. UN3
splits the same places' ground into per-section meshes. UN2's words carry
UN3's codes with other low bits: `0x306F`, `0x500F`, `0x61CF`, `0xE0E00F`,
`0xE000EF`, `0xE002E6` and `0xD80F` against UN3 S17's `0x3061`, `0x5001`,
`0x61C1`, `0xE0E001`, `0xE000E1`, `0xE002E2` and `0xD801`. NA2's own S24
uses the same style (`0x0060626F`, `0x0080D0FF`, `0x00E000EF`,
`0x00E002E6`; [authored distribution](stage_surface_attributes.md#stage-authored-attribute-distribution)).

| Archive | Batches: word (triangles) |
| --- | --- |
| S1A2 | `E000EF` (20), `60626F` (8), `60636F` (4), `80D2FF` (8), `80D3FF` (4), `60606F` (8), `80D0FF` (12), `E002E6` (288) |
| S5B2 | `E000EF` (28), `80D0FF` (4), `60626F` (4), `60616F` (8), `60606F` (28), `E002E6` (683) |
| S0A2 | `E000EF` (8), `306F` (16), `500F` (10), `61CF` (8), `E0E00F` (2), `E002E6` (105) |
| S0B2 | `E000EF` (8), `306F` (18), `61CF` (8), `500F` (10), `E002E6` (121) |
| S3A | `E000EF` (12), `E004EF` (4), `F0F0FF` (28), `60606F` (48), `60616F` (2), `E002E6` (135) |
| S3B | `E000EF` (8), `F0D0DF` (8), `F0D1DF` (12), `E002E6` (290) |

S3A's snow masks to `0xF0F0F0` and S3B's ice to `0xF0D0D0`, footprint
selection bits 15 and 16 of NA2's
[footprint table](stage_surface_attributes.md#footprint-surface-selection).
S0A2's `0xE0E00F` is NA2's class-1 water code.

## Surface effects, sounds and common visuals

`fighter_periodic_surface_effects` (`0x0021E8B0`) emits ground effects while
a fighter runs (`ACT_RUN_0`, `0x0E` in both games; `0x0019E1F0`), from its
masked word and the run's frame. `0xE0A000` water splashes (`0x0021F9F0`)
every 10 updates for character 4 (fighter `+0x54`), otherwise every other
update after the sixth. `0xF0D0D0`, `0xF0F0F0`, `0x005000`, `0x606060`,
`0x80D0F0`, `0x90B0C0` and `0x003060` puff (`effect_emit_surface_puffs`,
`0x0021C370`): two ground smokes, effect `0x93` (`EFF_e0xsmok20` with
`CLT_e0xsmok20c1`) or, on snow and ice and on scene 16, `0x95`
(`CLT_e0xsmok20c3`), at scale 4 for the first eight updates, then at 2.5
every 10 updates for character 4 or every 4 otherwise; on
snow and ice on scenes 16 and 17 three particles of the stage's own
`EFF_e0x_ice` (`stage_bind_ice_resources`, `0x002EB2A0`) join them.
`0x90B0C0` also places an effect at the lower foot (`0x00224010`).
`0x00D000`, `0x0060C0`, `0x202020` and `0xE0E000` emit nothing there.
NA2's `fighter_foot_surface_effects` (`0x0033A2D0`, from
`entity_run_surface_effects` in `ACT_RUN_0`) raises the same puffs on the
same codes at the same cadence, but its burst (`effect_spawn_debris_burst`)
tints only snow and ice, and takes its three ice particles from a stage
lookup (`0x006C2FF0`) that always returns none (`0x006C2EB0`).
Water has its own periodic path, as in NA2
([NA2's periodic path](stage_surface_attributes.md#query-eligibility-and-contact-classes)):
`effect_emit_periodic_water_code` (`0x0021EF30`) plays, every 15 updates,
the `0xE0A000` splash or, for `0xE0E000`, `0x0021F7E0` (effect `0x2E`,
`ANM_e0x_move_02` from UN2's `EFFECT0X.CCS`). No UN2 resident function
matches UN3's `water_ripple_spawn` (best normalized-instruction similarity
0.34).

Breakables play common sounds from their record's two trailing words:
`stage_breakable_react` (`0x006B8160`) plays the first on a hit before the
last and the second on destruction. The six scenes use 18/55, 18/56, 18/58,
18/60, 57/55 and 57/58. UN2's common bank (`DATA/SNDDATA.BIN`, descriptor
`audio_common_bank_descriptor`, `0x00419768`; event rows
`audio_common_controls`, `0x00418E90`, each naming its program) plays, for
events 18, 55, 56, 57, 58, 60, `0x23`, `0xB8`, `0x1F` and `0x25`, samples
that no NA2 common program holds byte for byte; event 9 plays NA2's program
9's, and events 0, 1, 3, 5 and 6 play NA2's programs 0, 1, 3, 5 and 6's
audio, 7 to 59 ms of faint tail shorter. Of 18, 55..58, 60, `0xB8`, `0x23`
and `0x1F`, only `0x1F` matches a UN3 program's samples byte for byte. Each
of 18, 55..58 and 60 is a one-sample 8,000 Hz program with the common
control row `00003C7F7F0001`; their samples take
18,512 bytes together, and `0xB8`'s (program `0x71`) 1,376.

Surface sounds come from `fighter_request_periodic_surface_audio`
(`0x002B8F70`), which maps `0xF0F0F0` snow to common event `0xB8` (program
`0x71`), `0xF0D0D0` ice to 3, `0xE0E000` water to 5, `0x003060` and
`0x005000` to 1, `0x0060C0` to 6, `0x606060` and `0xE000E0` to 3, `0x80D0F0`
to 0 and anything else to `0x25`, at velocity `0x7F` with program volume
`0x7F`. NA2's `audio_surface_event` maps the same codes to the same events
but suppresses `0xF0F0F0`, and its rows (`sfx_common_controls`,
`0x003FC9A0`) cap velocity at `0x50` (`0x40` for event 1) and its programs
0, 1, 3, 5 and 6 have volumes `0x50`, `0x50`, `0x64`, `0x7F` and `0x3C`;
NA2's program-6 sample record has byte `+0x0B` `0x3E` where UN2's has
`0x3C`. As in NA2, `fighter_event_dispatch` (`0x001F15A0`) writes
`0xF0F0F0` to the manager's ground word after each event.

The stage effects draw common resources through `generator_resource_rows`
(`0x004128A0`) and `effect_resource_rows` (`0x00410FD0`) from UN2's
`CMN/PARTICLE.CCS` and `CMN/EFFECT0X.CCS`, such as `EFF_x002`,
`EFF_e0xpar00`, `EFF_e0xsmok06`, `CMP_e0xleaf01`, `EFF_e0xdrop01` and
`ANM_e0x_ring_01`. NA2's files have the same names. Decoded with each of
their palettes, 10 of the 25 textures both `PARTICLE.CCS` files hold and 4
of the 16 both `EFFECT0X.CCS` files hold show the same colours in both
games, among them `x002` and `e0xpar01` with all their palettes and
`e0xpar00` with all but its sixth; `x002`'s sections differ only in IDs, a
flag byte (texture `+0x08`, palette `+0x04`) and VRAM placement. Among
those that differ are the leaves (`e0xleaf01`, `e0xleaf02`) in all seven
colours, which the surface effects index the same way (`0x00411DE0`,
NA2's `0x005A4B50`): colour 4 is a dark green where NA2's is khaki.
Generator catalog row 1 is `CMP_e0xleaf01` in both games (NA2's
`battle_particle_catalog_rows`, `0x005A6E20`), which the `0x524` flying
leaves draw, as their record names no composition. The ground smoke's
(`EFF_e0xsmok20`) texture and palettes equal UN3's. UN2's archives are CCS
version `0x111`, UN3's and NA2's `0x123`.

## Comparison with UN3's same places

UN3 remade the four places UN2 shares with it: S1A2 → UN3 S01, S0B2 → S04,
S5B2 → S08, S0A2 → S17. Only 31–53% of UN2's object names recur, and no
hit mesh, texture, palette or animation payload is byte-identical. S0A2's
dolls, monkey doll and their debris objects have UN3 S17's names
(`ANM_anm_doll_a1/n1/v1`, `OBJ_obj_uki_0`, `OBJ_doll_bre_000_a1..a3`).
Scene 11's rain, spray, puddle-ripple, cloud and blur records have no
counterpart among UN3 S04's records.
