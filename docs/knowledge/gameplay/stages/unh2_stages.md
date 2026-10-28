# UNH2 battle stages

## Research coverage

Established: the archive set and format, BOOT.BIN's scene table, record
dispatch and per-scene tables, scenes 5, 18 and 19's records with the
handlers of the types UN2 lacks and of scene 5's props, the breakables,
training dolls and item drops, the camera's section elevation and eye
height limits, scene 19's floor layout, the route
reader, the combo anchors, the scene-keyed code, the common sounds and
footsteps, the battle tracks' format and selection, the Stage Select
container and the English stage names, and what UNH2's scene 5 changes
from UN2's, the jutsu camera's end request and the screen-glare colour
overrides. Names come from
`@annotations/UNH2`; UN2 comparison names from `@annotations/UN2`.

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

Scene 18 also names `OBJ_s8awod00_hit`, which no record uses. UNH2 has no
category-12 handler, so the point nodes (`0xC0A`) of scenes 5 and 19 do
nothing. The far animations (`0x301`, `stage_far_animation_parse`,
`0x0889A4B8`) take token 10 as a Boolean fog mode, so scene 5's
`ANM_s1care02` (token 10 3) draws its background (`OBJ_bac_020_`..`050_`)
in the fog, as UN2's does.

### Breakables, training dolls and items

The breakables react as UN2's (`stage_breakable_react`, `0x0889AD34`): a
hit before the last plays prop effect 2 with the record's hit sound, the
last effect 7, 8 or 9 by token 8 (up to 100, up to 150, more) with its
break sound. The effects (`stage_dispatch_prop_effect`, `0x08896714`) are
UN3's: a hit spark, and for breaks common effect 1 at scale 1.5 up to
token 8 100, otherwise effects 2 and `0x44` at scale 2 (`0x0890E234`),
each with particle bursts; UNH2's `cmn/effect0x.ccs` holds
`ANM_e0x_hit_97`, `_98a` and `_98b` as model animations. The training dolls
(`0x825`, `stage_training_doll_parse`, `0x088A21D4`) break on the first hit
with the record's break sound, 58, and come back after 181..300 updates
(30 × token 1, less up to 40%, `0x088A26B0`).

A break drops an item drawn by kind weight (`stage_item_draw`,
`0x08899BF8`), then by the battle's item setting (`0x08931E74`)
(`stage_item_drop`, `0x0889A04C`): at 0 nothing more, at 1 the breaker's
extra `0xC` chakra items, at 2 twice as many (two for the dolls) and a
second item at 80%:

| Breaker | Kinds and weights | Extra chakra items |
| --- | --- | --- |
| Props (`0x0889AF40`) | 5 (item 9) 20%, 7 (one of 15) 60%, 9 (one of 8) 20% | 2, 1 for the bells (`0x818`) |
| Monkey doll (`0x088A2010`) | 2: one of 1, 4, 5, 9, `0xA`, `0xB` | 2 |
| Training dolls (`0x088A271C`) | 1 (1 or 4) 10%, 4 (9, `0xA`, `0xB`) 20%, 7 50%, 9 20% | 0 |

Kind 7 holds `0x30`, `0x14`, `0x0E`, `0x25`, `0x23`, `0x2B`, `0x26`,
`0x24`, `0x27`, `0x29`..`0x2E` and kind 9 `0x17`..`0x1B`, `0x23`, `0x25`,
`0x2B`. `item_class` (`0x0893EEA8`) groups items 1..7, 8..`0xC` with `0x21`,
`0xD`..`0x16` with `0x23`, `0x24` and `0x26`..`0x2B`, and `0x17`..`0x1B`
with `0x2C`..`0x2E`; in UN2, items 1, 4 and 5 heal and 8..`0xC` restore
chakra ([UN2 battle stages](un2_stages.md#record-types-of-the-six-scenes)).

## Per-scene tables

| Table | Address | Notes |
| --- | --- | --- |
| `stage_camera_records_by_scene` | `0x08B57B60` | 22-float records, UN2's fields 0..21; `camera_bind_stage_record` (`0x088ECF40`) binds them at camera `+0x17C` |
| `stage_effect_intensity` | `0x08B25E68` | UN2's 18 bytes, then `0xFF` for scenes 18 and 19 |
| `stage_render_coefficients` | `0x08B51D50` | UN2's, then (0.32, 0.3) and (0.45, 0.3) |
| `stage_scene_effect_defaults` | `0x08B51E70` | UN2's 18 [screen glare rows](un2_stages.md#per-scene-tables), then disabled zero rows for scenes 18 and 19. `stage_glare_apply_scene_row` (`0x0889148C`) applies UN2's colour overrides to rows 0, 1, 2, 4, 9 and 10 with the same values, so scene 5 uses its row unchanged, as in UN2; it writes the pass's colour, amount and second colour at `+0x64`/`+0x68`/`+0x6C` |
| `stage_music_tracks` | `0x08BD071C` | a `music_rows` index per scene, `0x0F` for scenes without an archive |
| `stage_navigation_authored_routes` | `0x08B58E30` | UN2's rows; scenes 18 and 19 point at scenes 16's and 17's lists |
| `stage_combo_anchors` | `0x08B31ED0` | UN3's and NA2's layout: side 0 and 1 vector pointers at `+0`/`+4`, counts at `+8`/`+9` |

`camera_stage_track` (`0x088ECF64`) lowers the desired elevation by field
19 (`+0x4C`) when the fighters' sections differ and by field 20 (`+0x50`)
when either is nonzero, as UN2's does. Scene 18's record equals UN2 scene
16's; scene 19's equals scene 17's except field 17 (`+0x44`), -2000
against 200; scene 5's differs from UN2's in field 17 alone (-1200).
`camera_place_eye` (`0x088EE2A8`) caps the eye's height at field 16
(`+0x40`), then raises it to field 17 when below it (`0x088EE848`), so
the eye stays at height 200 or above on UN2's scenes and scene 18, while
scenes 5 and 19 have no effective floor. No read of field 17 was found in
UN2's stage camera (`0x001ED960` and its placement routines). Each
fighter's tracked point rises by 0.55 of its scaled height
(`camera_stage_track`), where UN2's rises by 0.75 (`0x001EDFE8`).

Scene 19's floor (`MDL_obj_000_`) is a pit at height 0, |x| up to 492,
from depth -2496 to 488, between walkways at height 200 (|x| 548 to 1600)
along the whole room, with a rim from |x| 492 to 548 whose top is at 204.
Its camera has no eye floor, so nothing keeps the eye above the rim and
the walkways when it sits at |x| 492 or more.

Each route list ends with a zero row where UN2's end with source `0xFF`.
`stage_navigation_initialize` (`0x08905738`) copies rows until source
`0xFF` or 64 rows, so it also takes the zero row and the rows after it, the
next lists and, after scene 19's, the pointer table itself. Scene 5's list
is UN2 scene 5's, and the reader changes no scene-5 row.

Unlike UN2, UNH2 has combo anchors: its skill combos
(`skill_combo_choose_anchor`, `0x08A5C7A4`) place both participants at the
anchor nearest the first on its section (`stage_choose_combo_anchor`,
`0x08A5BECC`), as NA2's do. The chooser returns side 0 on scenes 1, 2, 7, 8
and 10, side 1 on 3, 4, 5 and 12, and the requested side elsewhere. Scenes
16 and 17 share one pair of arrays; 18 and 19 have their own:

| Scene | Side 0 (x, depth, height) | Side 1 |
| ---: | --- | --- |
| 5 | (0, 600, 400) | (0, 600, 400) |
| 18 | x -500..500 by 100 at (0, 100) | (-500, 750, 500); x 300, 400, 500 at (750, 100) |
| 19 | (-850, 0, 200); x -200..200 by 100 at (0, 0); (850, 0, 200) | x -500..500 by 100 at (750, 200) |

Scenes 18 and 19's line, `cl` and doll nodes equal UN2 scenes 16's and
17's.

## Scene-keyed code

These are the reads of the scene byte (`+0x3D` of the battle context at
`0x08C634C0`) in the decompiled `BOOT.BIN` that compare it with scene 5.
None singles out 16..19, so scenes 18 and 19 take every routine's
default.

| Routine | Scenes | Behavior |
| --- | --- | --- |
| `field_player_placement` (`0x0892EAD8`) | 5, 10 | Players start in section 1 |
| `stage_navigation_response` (`0x088F8AB4`) | 1, 5 | A COM in state 5 whose point ahead lies outside its section's endpoints resets, as UN3's on its scenes 1 and 4 |
| `ai_route_region_gate` (`0x08900834`) | 5 | Section 0 is rejected among secondary navigation points, as UN3's on its scenes 14 and 4 |
| `stage_choose_combo_anchor` | 5 | Return side 1 (above) |
| `skill_pair_place_rectangles` (`0x08A359C8`) | 0, 1, 2, 5, 13 | A jutsu's pair placement (`skill_pair_place`, `0x08A35DFC`, UN2's `0x007BEDE0`: ground probes at distances per jutsu) first moves a participant standing inside a rectangle of `skill_pair_rectangles` (`0x08BCEB10`) to its target row's point picked by the partner's side. On scene 5's section 0, x -1500..-500 below height 120 or -500..0 below 400 move both participants to (-720 or -500, 0, 0), the mirrored rectangles to (500 or 810, 0, 0); on section 1, x -1250..-1055 or 1055..1250 below 300 move the participant to (-550 or -300, 600, 400) or (300 or 550, 600, 400) |
| `skill_camera_kind13` (`0x08A44488`), `skill_camera_kind1b` (`0x08A44F10`), `skill_camera_scene5_high` (`0x08A47734`) | 5 | Three jutsus' cameras take scene-5 presets near the stage's ends or with both fighters high on section 1 |
| `skill_request_jutsu_camera_end` (`0x08A16A24`) | 5 | Every jutsu posts request 6 to the jutsu camera (battle `+0x1FC`, UN2's battle `+0x260`), which ends its shot and hands the view back to the battle camera (`jutsu_camera_take_request`, `0x08A41214`; `jutsu_camera_apply_state`, `0x08A4749C`), but jutsu 5 with the target off section 0 and jutsus `0x46` and `0xF` above height 500 keep the shot |

## Battle music

`audio_play_mode_music` (`0x08A3E7EC`) plays the scene's
`stage_music_tracks` row unless its override is set. Rows of `music_rows`
(`0x08AF5F88`, 12 bytes: path, loop flag, volume) 0..10 are
`sound/bgm/stage00.at3`..`stage10.at3`: scene 5 plays `stage03`, 18
`stage08` and 19 `stage09`, each looping at volume 150. The files are RIFF
ATRAC3plus at 44.1 kHz, stereo: the `fact` chunk gives the encoder delay
and the `smpl` loop counts samples from the decoder's first output, the
delay included.

## Common sounds

`audio_play_common` (`0x08A3F230`) plays a common event through its
8-byte row of `audio_common_controls` (`0x08BCDE00`), UN2's layout:
program, key and velocity. The stages' events play the program of their
own number at key `0x3C`, velocity `0x7F` but the wind's `0x3E` at `0x50`,
as UN2's (UN3's `0x40`); the snow step `0xB8` plays program `0x71`. The
programs are in `sound/se/commse0e.phd` and its Japanese twin
`commse0.phd`, Sony's PSP `PPHD` header over a `.pbd` of PS-ADPCM
samples: chunk offsets at `+0x10`; `PPPG` a table of program record
offsets from `+0x20`, each record a tone count at `+0` and tone indices
from `+0x10`; `PPTN` 0x60-byte tones from `+0x20`, each with its sample
index at `+0` and root key at `+0x30`; `PPVA` 16-byte rows from `+0x20`:
offset into the `.pbd`, rate and size. Decoded, the samples of events `0`,
`1`, `3`, `5`, `6`, `9`, `0x12`, `0x1F`, `0x23`, `0x37`..`0x3C` and `0x3E`
are UN3's, which are NA2's where NA2 holds them; UN2's are the same audio
with up to 60 ms of the faint decay cut. Programs `0x25`, `0x26` and `0x71`
have no tones, so events `0x25` and `0xB8` play nothing.

Positional sounds (`audio_play_common_at`, `0x08A3F4EC`) do not fade or
pan: `audio_position_velocity` (`0x08A3E4CC`) always returns `0x7F`,
capped by the row's velocity, and `audio_position_direction`
(`0x08A3E4D4`) the centre. Scene 5's wind starts its loop on its first
update (`audio_loop_start`, `0x08A3F6A0`) at the row's velocity and stops
it in battle phase 2 (`audio_loop_stop`); its position update
(`audio_loop_place`, `0x08A3F820`) is empty, so the loop keeps that level
through calm and gusts.

`fighter_request_periodic_surface_audio` (`0x08A3ED50`) plays footsteps by
the masked ground word every 5 updates (8, 12 and 11 for characters
`0x15`, `0xE` and 4): `0x80D0F0` event 0, `0x10C0`, `0x5000` and `0x3060`
1, `0xE0A000` and `0xE0E000` 5, `0xD000` 2, `0x60C0` 6, `0x90B0C0` 4,
`0xF0D0D0`, `0x606060`, `0x8080F0` and `0xE000E0` 3, `0x202020` `0xB7`,
`0xF0F0F0` `0xB8` and other ground `0x25`. On the stages' ground these are
NA2's events (`audio_surface_event`).

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
`MDL_bac_040_`, which in UN2 draws the ground plane below the castle
(`s1cbac01`) and its houses (`s1cbac08`), is two quads of a moon
(`s1cbac06`, `s1cbac07`), placed by `ANM_s1care01` at (0, 0, -3027.8), so
the night has neither. UNH2's models are UN2's with fewer vertices, its
`MDL_bac_050_` taking the narrower shape UN3 S05's has.

Its night also lives in vertex colours, which UNH2 repaints where UN2's
are mostly neutral (`808080`): the far forest (`MDL_bac_020_`..`_022_`)
all `323E43`, the hills (`MDL_bac_030_`) mostly `3C464B`, the near forest
(`MDL_bac_050_`, rows of upright cutouts) `3C464B` at each row's base and
neutral at its top, the sky dome (`MDL_bac_000_`) black at its top through
grey to neutral, and the castle's `MDL_obj_060_` and `_070_` darker in
places. UN2 bakes the sun into the vertex colours of the roof
(`MDL_obj_000_`), where the fish statues' shadows fall diagonally across
it, and of `MDL_obj_050_`, lit from one side; UNH2 shades both evenly and
symmetrically, at the same mean. Its base animation (`ANM_s1care00`) keys
UN2's subtracting roof overlay `OBJ_obj_003_` (`s1cobj04`, blend 2) with
rotation (180, 0, 0) and scale (-1, -1, -1), mirroring it and turning it
inside out, where UN2's key gives it opacity 0.8.

Its props behave as UN3 S05's counterparts:

- The one-way wind (`0x585`, `0x088D7548`/`0x088D7648`) pushes as UN3's
  `0x55E`, but its sound plays from the first update at a steady
  velocity `0x50` ([Common sounds](#common-sounds)).
- The wind-blown debris (`0x584`, `0x088D67B8`/`0x088D71C4`) is UN3's
  `0x55D`, but every piece breaks into the record's `CMP_bre_010`: the
  parse names `CMP_bre_020` and `_030` for the first four pieces only in
  the hit-animation slot, which a piece breaking at its first contact never
  plays, and `s1c2` holds neither.
- The torches (`0x51C`, parse `0x088C3F84`, update `0x088C42D8`, draw
  `0x088C4458`) are UN3's `0x517`: flames at opacity 0.5 and over each an
  `EFF_efe_020_` glow sprite at an opacity walking within 0.2..0.5.
- The bells (`0x818`) swing by their hits and 0.3 of the wind
  (`0x0889BA4C`), each completed swing at 0.6 of the last, and sound only
  when they break.
- The two swaying leaf clumps (`0x538`) are `CMP_obj_020_` and `_030_`
  (texture `s1cobj30`, which UNH2 keeps undarkened) at `OBJ_ha_010` and
  `_020`, (±2100, 1300, -650), where UN3 S05 has two trees of trunk and
  branches (`0x582`).
