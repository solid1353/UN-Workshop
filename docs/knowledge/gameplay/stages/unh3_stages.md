# UNH3 battle stages

## Research coverage

Established: the archive set and its format, EBOOT.BIN's scene, name, track
and Stage Select tables, how the 13 Stage Select scenes build their lines,
player positions, camera bounds and paired placement from markers, the
normal-stage camera, the fog, glare and render records, factories 134 and
135, the scaled marker, and what the 29 mission scenes are. Open: whether UNH3's
handlers for the factories it shares with NA2 behave as NA2's (its break
object is a larger class than NA2's), the bombs' screen effect and sound,
the effective render coefficients where no record gives them, and
stage-specific code branches. Names are UNH3 `EBOOT.BIN` addresses; NA2
comparison names come from `@annotations/NA2`.

This document owns retail UNH3 (*Naruto Shippuden: Ultimate Ninja Heroes
3*, PSP) battle-stage facts. UNH3 runs NA2's stage engine
([Stages](stages.md)).

## Evidence and address convention

Evidence is static, from MCP target `UNH3` (program `EBOOT.BIN`) and the
`@source/UNH3.iso.files` extraction; paths below are in
`PSP_GAME/USRDIR/data.cpk.files/`.

## Archives

`31btlstg/` holds 42 stage archives, `s01`..`s10`, `s13`, `s21`, `s22`
and `r001`..`r029`, and `gim.ccs`: uncompressed CCS streams of version
`0x123`, NA2's, with NA2's `takaCreateBackGround` `BIN_bgdata` records and
factory numbers. Their textures and palettes are NA2's formats at PS2
scale (UNH3 expands palette alpha as `max(2a-1,0)` and keeps RGB); most
carry VRAM coordinates `(0,0)` or shared ones, which the PSP ignores.
Two section kinds NA2's parser lacks occur: `0xCCCC1480`, a marker with
position, Euler rotation and scale (one in `s10`, `DMY_dummy_030`, which
no record uses), and `0xCCCC2700` in mission archives.

## Scene table

Three scene-indexed arrays give each scene's archive
(`stage_archive_names`, `0x08B83DD8`), name text entry (`0x08B48B14`,
`01text/text_e.bin`) and default battle track (`0x08C71D74`, a
`sound/bgm.afs` member). Scenes 0..12 are the `s` archives in file order,
13..41 `r001`..`r029`; `r028` and `r029` reuse entries 181 and 182.

| Scene | Archive | Text name | Stage Select name | Track |
| ---: | --- | --- | --- | ---: |
| 0 | `s01` | Village Hidden in the Leaves | Village Hidden in the Leaves | 5 |
| 1 | `s02` | Village Hidden in the Sand | Village Hidden in the Sand | 9 |
| 2 | `s03` | East Hideout Lab | East Hideout Lab | 14 |
| 3 | `s04` | Akatsuki Hideout | Akatsuki Hideout | 10 |
| 4 | `s05` | Field of Flowing Water | Wilderness of Running Water | 7 |
| 5 | `s06` | Cliff of Morning Mist | Cliff of Morning Mist | 8 |
| 6 | `s07` | Training Field | Training Field | 6 |
| 7 | `s08` | Cataract Giant Wall | Cataract Giant Wall | 13 |
| 8 | `s09` | Forest of Dead Trees | Forest of Dead Trees | 16 |
| 9 | `s10` | Vacant Lot of Explosion Arts | Vacant Lot of Explosion Arts | 17 |
| 10 | `s13` | North Hideout Confinement Facility | North Hideout Confinement Facility | 15 |
| 11 | `s21` | Giant Snake Altar | Giant Snake Altar | 12 |
| 12 | `s22` | Tenchi Bridge | Tenchi Bridge | 11 |

The tracks are 22,050 Hz stereo ADX with loop points in their headers.
`stage_get_default_bgm_member` (`0x08A8E670`) plays the scene's track
unless a mission overrides it.

Scenes 13..41 are Master Road's mission battles (`13adv/10event/eventBattle.ccbpm`,
191 records of `0x52` bytes, scene at `+0x2A`): `stage_is_mission_scene`
(`0x08974000`) is 1 for them, and
`mission_stage_load_auxiliary_archives` (`0x08984960`) loads `gim.ccs`,
`13adv/e000`, `e007` and `e300` with them. Each is a side-scrolling course,
one line up to about 36,000 long built from `maptip` pieces, with an
`end_dmy` goal; their camera follows six scene-indexed vector tables
(`mission_camera_track`, `0x08959B74`), and scene 35 its own
(`0x089592C4`).

## Stage Select

`stage_select_records` (`0x08B44FC8`, 13 rows of scene, name frame, big
and small picture objects) gives Stage Select's order: scenes 0, 6, 7, 8,
1, 4, 5, 3, 12, 11, 2, 10, 9. `21btlsel/mapsel1_e.ccs` draws them from
`m\map\tex\mappure01.bmp`: big pictures in 162×83 cells, three to a row
from the top-left in that order, thumbnails in 72×39 cells below them,
and names from `m\map\tex\en\map_name.bmp` rows. A 14th picture
(`SPD_map_st13`, a grassy field) is drawn in the atlas but no record uses
it.

## Lines, placement and camera

`bg_control_load_scene` (`0x088E6D60`) builds a scene's lines and positions
from its markers, before its records:

- `0x088E816C`: for sections 1..4, pairs of `DMY_line_0<n>0` markers
  (`<stem>`, `<stem>_1`, then `_2`/`_3` and so on, up to 32 pairs, and
  three variant sets `<stem>1`..`3`) are each a floor segment and a
  walkable line of that section. `DMY_linemin0<n>`/`linemax0<n>` bound each
  section.
- `0x088E7F5C`: line-change pairs `DMY_<f|b><n>_cl_<k>_nor/end/mov`, which
  NA2 reads as its first-family lines; the 13 Stage Select archives have
  none.
- `0x088E8850`: player positions `DMY_pp1_010`..`DMY_pp9_010`.
- `0x088E88F4`: `DMY_safe_pos` (or `(0,0,0)`), where `0x089CA408` places
  both fighters of a paired action, side by side on section 0.
- `DMY_cpmin`/`cpmax` and `DMY_cvmin`/`cvmax` bound the camera's eye and
  target (defaults `0x08B38960`).

NA2 instead takes the line and player setup from records 33..38 and the
camera and paired placement from per-slot tables
([Stages](stages.md#native-background-configuration-formats)).
`s01` and `s04` have one section and `s09` three.

The normal-stage camera (`0x08958724`, mode 0 `0x08958F6C`) targets the
centre of the fighters' bounding box raised 75; its eye stands back on y by
twice the box's diagonal, at least 800, and up by 0.22 of that.
`0x089599F0` clamps the eye to `cpmin..cpmax`, pulling it back by any
lateral overshoot, and the target to `cvmin..cvmax`; both ease 0.3 of the
way each update. No per-scene combo-anchor, route or effect-intensity
table exists; only mission scene `r008` carries a route table
(`BIN_cpucooproutetbl`).

## Records

Factory 10 (`0x0890695C`) reads NA2's fog tokens. Factory 11 reads NA2's
glare tokens (parse `0x08906B08`), and its draw (`0x088A3B54`) makes the
same passes as NA2's `ccfm_sampling_pass_submit`, on the PSP's scale: its own
passes draw at colour `0xFFFFFFFF` where NA2's draw at `0x80808080`, its
composite colour (tokens 0..3, alpha first) modulates the glare texture
(`sceGuColor`) and blends by its alpha, and its threshold pass is an
untextured quad of colour tokens 5..7 at alpha `token4 × 255`. Factory 17
(`0x08907160`) sets two render coefficients; every Stage Select archive
but `s06` gives `0.30,0.30`. UNH3's factories 0, 2 and 29 take their
object's scale from the placement marker and ignore the scale token,
which is 1 in every Stage Select record. Its break object (factory 50) is
a `0x770`-byte class against NA2's `0x190`.

Two factories the Stage Select archives use have no NA2 counterpart:

| Factory | Class / routines | Use |
| ---: | --- | --- |
| 135 | parse `0x088F954C`, update `0x088F9408`, draw `0x088F9528` | `s02`'s `OBJ_efe_010_` and `_020_`: an object at its marker (token 1, or none for `0`) that every 30 updates starts flickering with chance token 2 in 3001 (`random(3000) <= chance`), toggling its opacity between 0 and 1 each update for 2..4 updates, then returns to 1. |
| 134 | `ccBgCrashBreakRebornBattle`: parse `0x088F8790`, update `0x088F8B4C`, draw `0x088F900C`, blast `0x088F90D0` | `s10`'s two time bombs, described below. |

Factory 134's tokens are the bomb, a second object or `0`, the stem of its
spots (`<stem>_a<n>`, up to 8), the blast radius (250), the updates it
stays away (90 when not positive) and its fuse (150 when not positive).
Each bomb:

1. Burns its fuse, starting at a random 0..30: an angle advancing
   `0.1 + 0.9t²` per update tints it toward red (`0x0000FF`) by
   `sin(angle) × 50` percent; past 85% of the fuse it blinks at 50% every
   other update and swells toward scale 2 by `((t - 0.85) / 0.15)²`.
2. Blasts: plays `04cmn/effect0x.ccs` `ANM_e0x_bom0` at a point jittered
   ±10, turned at random about z; starts a screen effect of type 6 (20
   updates, value 1.1, angle π/16, `0x08B39190`); plays sound `0x1011`; and
   for 16 updates hits each fighter within the radius with the record
   時限爆弾: category 1, flag `0x100000`, attack 0.1, knockback 1, repeat 1,
   rejection 10 and a response chosen at random from `0x12, 0x14, 0x10,
   0x11, 0x0B, 0x0C, 0x0D, 0x0E` (`0x08B39160`), NA2's InteractionRecord
   layout.
3. Waits hidden 200 under a random spot for the stay-away updates, then
   rises to it over 30 updates.

It holds while stage updates are restricted.
