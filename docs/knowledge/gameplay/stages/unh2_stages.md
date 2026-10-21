# UNH2 battle stages

## Research coverage

Established: the archive set and format, BOOT.BIN's scene table, record
dispatch and per-scene tables, scenes 5, 18 and 19's records with the
handlers of the types UN2 lacks, the camera's section elevation, the route
reader, the battle tracks' format and selection, the Stage Select container
and the English stage names, and what UNH2's scene 5 changes from UN2's.
Open: the other scenes' records, and whether UNH2's common sound samples
equal UN2's. Names come from `@annotations/UNH2`; UN2 comparison names from
`@annotations/UN2`.

This document owns retail UNH2 (*Naruto: Ultimate Ninja Heroes 2*, US
`ULUS-10349`) battle-stage facts and their correspondence with UN2, whose
stage engine UNH2 carries over ([UN2 battle stages](un2_stages.md)).

## Evidence and address convention

Evidence is static, from MCP target `UNH2` (program `BOOT.BIN`) and the
`@source/UNH2.iso.files` extraction. `BOOT.BIN` is a relocatable PRX: file
offset `0x60` holds address 0 and its pointers are stored relative to 0;
the target loads it at `0x08804000`, and addresses below are those.

## Archives

The data archive (`PSP_GAME/USRDIR/naruto.dat`, extracted as
`naruto.dat.files/data/rofs`) holds ten stage archives in `stage/`:
`s0a2`, `s1a2`, `s1b2`, `s1c2`, `s2a2`, `s2c2`, `s6a`, `s6b`, `s8a` and
`s8b`, uncompressed CCS streams of version `0x111`, UN2's. Their models,
materials, palettes and animations have UN2's layouts; most textures are
UN2's at half the width and height, some with their palettes requantized
from 16 colours to 256.
NA2's parsers read them as they read UN2's
([older-version branches](../../game/files/ccs_object_types.md#older-version-parser-branches)).

## Scene table and records

`stage_scene_tables` (`0x08B51FB0`) holds 20 pointers to lists of UN2's
32-byte records: scenes 0..17 in UN2's order, then 18, `s8a`, and 19,
`s8b`. `stage_scene_construct` (`0x08880220`) dispatches each record's
category to UN2's handlers. The US English stage names (`cmn/text.bin`)
follow the same order:

| Scene | Archive | Label | English name |
| ---: | --- | --- | --- |
| 5 | `s1c2` | 城屋根2 | Kikyo Castle Keep |
| 18 | `s8a` | 無幻城屋外 | Outside the Mugenjo |
| 19 | `s8b` | 無幻城屋内 | Inside the Mugenjo |

The fog (`stage_parse_fog`, `0x08882E78`) reads UN2's tokens: colour,
near and far distance and far percentage. The lighting
(`stage_parse_lighting`, `0x08883040`) sets the render environment's colour
from token 10 unless it is `0`, otherwise from the light. Scene 19 runs two
lighting records on the same animation; `light_list_insert` (`0x088254B4`)
skips a light already listed, so the second only replaces the environment
colour.

Scenes 18 and 19 use UN2's types `0x001`..`0x401`, `0x301`, `0x825`,
`0x826`, `0xA08`/`0xA09`, `0xB01`, `0xC0A`, `0xD01` and `0xE0A`/`0xE0B`
with UN2's tokens, and three types UN2's scenes lack, all category 5
(`stage_parse_animation_props`, `0x08884018`):

| Type | Label | Behavior |
| --- | --- | --- |
| `0x5A9` | 灯篭の明かり (lantern lights) | `stage_lantern_lights_parse` (`0x088C4618`): the token-6 effect at the token-3 node and its `%s_%d` siblings, token 5 of them (6 in scene 18, 18 in scene 19). The update (`0x088C477C`) walks each opacity by `random_signed_scaled(0.05)` within 0.2..0.5 unless stage effects are restricted (`0x08898EA4(2)`); the draw (`0x088C484C`) shows frame 0 of the effect, never advanced, at each node at its opacity in draw environment 3. The sprite draw (`0x08828FC8`) passes the effect's depth offset (100 here, kept at instance `+0x22` by `0x08828A0C`) to `sceGuDepthOffset` (`0x088117EC`) when it is below `0x199A`, moving each glow 100 units of the 16-bit depth (range `0xFFF0..0x10`) toward the eye, over its own lamp. |
| `0x5AA` | 無幻城霧 (Mugenjo mist) | A plain looping animation (scene 18's `ANM_s8amis00`..`02`) whose objects take fog mode 1 (`animation_set_fog_mode`, `0x0883C09C`). |
| `0x5AB` | 汎用半透明 (generic translucent) | `stage_translucent_parse` (`0x088C4960`): the token-10 composition in a player, its models' TEST state set to `0x1001` (`composition_set_model_test` selector 1, value 0), which writes the frame buffer without depth where models start at `0x100B`; drawn by `composition_draw` where its models place it, no animation keying its objects. Its update is empty. Scene 18's four are `CMP_bac_100_` and `_1`..`_3`. |

Scene 18 also names `OBJ_s8awod00_hit`, which no record uses.

## Per-scene tables

| Table | Address | Notes |
| --- | --- | --- |
| `stage_camera_records_by_scene` | `0x08B57B60` | 22-float records, UN2's fields 0..21; `camera_bind_stage_record` (`0x088ECF40`) binds them at camera `+0x17C` |
| `stage_effect_intensity` | `0x08B25E68` | UN2's 18 bytes, then `0xFF` for scenes 18 and 19 |
| `stage_render_coefficients` | `0x08B51D50` | UN2's, then (0.32, 0.3) and (0.45, 0.3) |
| `stage_music_tracks` | `0x08BD071C` | a `music_rows` index per scene, `0x0F` for scenes without an archive |
| `stage_navigation_authored_routes` | `0x08B58E30` | UN2's rows; scenes 18 and 19 point at scenes 16's and 17's lists |

`camera_stage_track` (`0x088ECF64`) lowers the desired elevation by field
19 (`+0x4C`) when the fighters' sections differ and by field 20 (`+0x50`)
when either is nonzero, as UN2's does. Scene 18's record equals UN2 scene
16's; scene 19's equals scene 17's except field 17 (`+0x44`), -2000
against 200, which NA2 does not read either; scene 5's differs from UN2's
in field 17 alone (-1200).

Each route list ends with a zero row where UN2's end with source `0xFF`.
`stage_navigation_initialize` (`0x08905738`) copies rows until source
`0xFF` or 64 rows, so it also takes the zero row and the rows after it, the
next lists and, after scene 19's, the pointer table itself.

Scenes 18 and 19's line, `cl` and doll nodes equal UN2 scenes 16's and
17's.

## Battle music

`audio_play_mode_music` (`0x08A3E7EC`) plays the scene's
`stage_music_tracks` row unless its override is set. Rows of `music_rows`
(`0x08AF5F88`, 12 bytes: path, loop flag, volume) 0..10 are
`sound/bgm/stage00.at3`..`stage10.at3`: scene 5 plays `stage03`, 18
`stage08` and 19 `stage09`, each looping at volume 150. The files are RIFF
ATRAC3plus at 44.1 kHz, stereo: the `fact` chunk gives the encoder delay
and the `smpl` loop counts samples from the decoder's first output, the
delay included.

## Stage Select

`mapsel1.ccs`, the Stage Select container, shows UNH2's stages from
`new\tex\map.bmp` (512×256): 98×72 cells in 100×74 steps from (1, 1), in
Stage Select's order, scene 5's night roof at (401, 1), scene 18's at
(1, 149) and scene 19's at (101, 149). The container also keeps UN2's
pictures in 192×96 cells of `haipure01`..`03` and its thumbnails in
`haipure_s01`, where scene 5's show UN2's daytime roof and scenes 18 and
19 have none.

## Scene 5 against UN2's

UNH2's scene 5 is UN2's castle roof at night. Its records differ from UN2
scene 5's only in the fog, (48, 64, 96) from 1,000 to 28,000 at 40% where
UN2's is white from 0 to 100,000, in lighting token 10 (220, 220, 196,
where UN2's is `0`), and in dropping UN2's lens flare (`0x519`), sunrise
(`0x51A`), sunlight (`0x71B`), flying leaves (`0x524`) and intruders
(`0x990`).

Of its scenery textures, UNH2 keeps UN2's apart from the sky and moon and
eight it darkens (mean pixel luminance against UN2's in brackets):
`s1cbac04` (0.88), `s1cobj23` (0.67), `s1cobj24` (0.42), `s1cobj25`
(0.70), `s1cobj31` (0.78), `s1cobj32` (0.36), `s1cobj34` (0.71) and
`s1cobj35` (0.48). Its sky dome takes a night gradient (`s1cbac00`), and
`MDL_bac_040_`, which in UN2 draws `s1cbac01` and `s1cbac08`, is two quads
of a moon (`s1cbac06`, `s1cbac07`), placed by `ANM_s1care01` at
(0, 0, -3027.8).
