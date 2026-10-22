# UNH3 battle stages

## Research coverage

Established: the archive set and its format, EBOOT.BIN's scene, name, track
and Stage Select tables, how the 13 Stage Select scenes build their lines,
player positions, camera bounds and paired placement from markers, the
normal-stage camera, the fog, glare and render records, factories 134 and
135, the scaled marker, how its handlers for the factories it shares with
NA2 and its renderer differ from NA2's, its scene-keyed code, how its
computer fighters choose sections, its sound banks, its item records, and
what the 29 mission scenes are. Open: the NA2 codes of some of its item
numbers, its camera's field of view and its running dust's art. Names
are UNH3 `EBOOT.BIN` addresses; NA2
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

## Scene-keyed code

The battle manager (`0x08CE0580`) holds the scene at `+0x90`, and the
background control keeps a copy at `+0x10` (`bg_control_load_scene`) that
no caller of its getter (`0x088E650C`) reads back. Of the manager's scene
reads, most separate mission scenes from battle scenes
(`stage_is_mission_scene`); three key Stage Select scenes:

| Routine | Scenes | Behavior |
| --- | --- | --- |
| `0x0895BF0C`, from presentation camera mode 7 (`0x0895BF8C`) | 2, 8 | The side probe from a fighter on section 0 with `+0x9FE` 1 reaches 250 (scene 2) or 230 (scene 8) instead of 200, which decides the side of the camera's offsets. NA2's presentation cameras (`effect_adapt_camera_record`, BTL `0x00776610`) have no such probe. |
| `bg_break_anm_trigger`, factory 102's break | 0 | Plays sound `0x38` before `0x3A`; only `s21` (scene 11) has factory-102 records. |
| `0x08A8E144`, positional sound volume | 0..12 | Full volume within 2200, fading out over 4000 beyond it (also on mission 35; 1000 on other missions). NA2's `audio_position_scalar` (`0x001D2FD0`) fades from 700 to 2700. |

UNH3 has none of the constants of NA2's stage-keyed exceptions, such as
`stage_nearest_line_extended`'s 1100 or `stage_effect_height_override`'s
387 ([Stages](stages.md#logical-id-equality-cases)), so NA2's slot and
logical-ID branches have no UNH3 counterpart.

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
  walkable line of that section. A corrected position
  (`fighter_correct_position`, NA2's `stage_correct_position`) is clamped
  to the x extremes of the section's nodes, every variant's
  (`bg_clamp_to_section_extremes`), where NA2 clamps to
  `DMY_linemin0<n>`/`linemax0<n>`, which UNH3 also reads; the two differ
  only on `s09`'s and `s22`'s second sections and `s10`'s two, by up to
  102. The floor profile keeps variant 0's segments, and only the
  section-transfer projection (`bg_resolve_section_transfer`) reads the
  active variant's lines, over variant 0's end nodes.
- `0x088E7F5C`: line-change pairs `DMY_<f|b><n>_cl_<k>_nor/end/mov`, which
  NA2 reads as its first-family lines; the 13 Stage Select archives have
  none.
- `0x088E8850`: player positions `DMY_pp1_010`..`DMY_pp9_010`; slot `n`
  starts at `DMY_pp<n+1>_010`, in the section holding it, facing the other
  side's (`field_player_placement`). Every Stage Select archive's
  `DMY_pp1_010` and `DMY_pp2_010` stand on section 0.
- `0x088E88F4`: `DMY_safe_pos` (or `(0,0,0)`), where `0x089CA408` places
  both fighters of a paired action, side by side on section 0.
- `DMY_cpmin`/`cpmax` and `DMY_cvmin`/`cvmax` bound the camera's eye and
  target (defaults `0x08B38960`).

NA2 instead takes the line and player setup from records 33..38 and the
camera and paired placement from per-slot tables
([Stages](stages.md#native-background-configuration-formats)).
`s01` and `s04` have one section and `s09` three.

The normal-stage camera (`camera_track_stage`) picks a mode each update by
the opponents on the tracked fighter's section (`camera_select_stage_mode`).
With one or more there, it is mode 3
(`camera_frame_fighter_box_same_section`): the active fighters' bounding
box's centre raised 100 as target, the eye back on y by 1.44 times the
box's diagonal, at least 600, and up by 0.11 of that. With none, mode 0
(`camera_frame_fighter_box`) raises the target 75 and stands back twice
the diagonal, at least 800, up 0.22 of that. While the tracked fighter is
in major state 8 near its one opponent, mode 1 (`camera_follow_behind_fighter`)
looks past it from behind. `camera_clamp_to_stage_bounds` clamps the eye
to `cpmin..cpmax`, pulling it back by any lateral overshoot, and the target
to `cvmin..cvmax`; both ease 0.3 of the way each update. Its field of view
is not established. No per-scene combo-anchor, route or effect-intensity
table exists; only mission scene `r008` carries a route table
(`BIN_cpucooproutetbl`).

Computer fighters (`ai_controller_update`, four `ai_controllers`) choose
sections by number alone: on another section than their target's they
step toward it (`ai_state_approach_target`, state `0xC` up, `0xD` down),
now and then step toward a section drawn at random from the scene's count
(background `+0x14`), and on their target's section close in along x. They
read no per-section x range.

## Records

Factory 10 (`bg_factory_fog`) reads NA2's fog tokens. Factory 11 reads NA2's
glare tokens (parse `0x08906B08`), and its draw (`0x088A3B54`) makes the
same passes as NA2's `ccfm_sampling_pass_submit`, on the PSP's scale: its own
passes draw at colour `0xFFFFFFFF` where NA2's draw at `0x80808080`, its
composite colour (tokens 0..3, alpha first) modulates the glare texture
(`sceGuColor`) and blends by its alpha, and its threshold pass is an
untextured quad of colour tokens 5..7 at alpha `token4 × 255`. Factory 17
(`bg_factory_render_coefficients`) sets two render coefficients; every
Stage Select archive but `s06` gives `0.30,0.30`. No battle setup resets
them (`stage_render_colour_coefficient`, `_packet_coefficient`, in bss),
so `s06` keeps the last record's, `0.30,0.30` after any other Stage Select
stage, where NA2's battle setup resets them to `0.4,0.3`
(`battle_initialize_render_descriptor`). UNH3's factories 0, 2 and 29 take
their object's scale from the placement marker and ignore the scale
token, which is 1 in every Stage Select record.

The factories the Stage Select archives share with NA2 read the same
tokens as NA2's and differ as follows (UNH3 parse / update / draw; NA2's
in `SLPS_258.37`, or `BTL.BIN` where marked):

| Factory | Archives | UNH3 | Against NA2's |
| ---: | --- | --- | --- |
| 0 | all | `0x089040B8` / — / `0x08904094` | Draws without NA2's `model_classify_bounds` gate (`0x003957C0`). |
| 2 | `s05`, `s10`, `s21` | `0x0890477C` / `0x089046D8` / `0x08904760` | Same playback: step × rate × scene factor in 1/256 frames; UNH3 keeps a 32-bit step, NA2 16 bits (`0x00396220`). |
| 8 | `s02` | `0x0890662C` / `0x08906524` / `0x089065D4` | Rotates every update; NA2's (`0x00398510`) only while its bounds gate passes. Token 2 is opacity in both. |
| 10, 18 | all | `0x0890695C`; `0x08907230` | Same fog and distant-light setup (RGB / 255). |
| 17 | all but `s06` | `0x08907160` | Same two floats; UNH3's pass scales the colour coefficient by 255 where NA2's packet uses 128. |
| 29 | all but `s21` | `0x08909484` / `0x08909320` / `0x0890941C` | Advances its UV while the model has geometry; NA2's (`0x0039B910`) only while its bounds gate passes. |
| 41 | all but `s01`, `s21` | `0x088ECDB0` / `bg_break_doll_update` / `0x088ECD54` | Same doll cycle (BTL `0x006C6940`), silent as NA2's, with factory 50's receiver differences. |
| 48 | `s01`, `s06`, `s07` | `0x088EF2CC` / `0x088EF584` / `0x088EF718` | Same displacement (BTL `0x006C9FB0`); reacts to four fighters, plays sound `0x50` at the fighter on a grounded reaction, also once one has stood there over 8 updates (`bg_landing_tree_reaction`), and emits no effect, where NA2's plays nothing and emits ten surface effects at the tree on each reaction (BTL `0x006CA310`, `surface_effect_spawn`). |
| 50 | all but `s21` | `0x088EB5BC` / `0x088EB2D0` / `0x088EB4F4` | Same hit progression and drops (BTL `0x006C47B0`). One receiver of 32 `0x30`-byte entries (`0x770`-byte class) against NA2's attack and proximity receivers (BTL `0x006C55B0`, `0x190`); rejects record flag `0x04000000`, NA2's `0x02000000`, as UNH3's attack-record flags of that range sit a bit above NA2's at the same offset (its guard sound takes the response sound on `0x02000000` where NA2's does on `0x01000000`, `fighter_schedule_action_audio`); flashes for any flagged actor within radius + 50 where NA2 tests the two fighters against its enlarged receiver; breaks with sound `0x3A` at its row's note `0x40`, and `ANM_s03gim00`'s with `0x38` at note `0x42`, two semitones up (`bg_break_initialize`, `bg_break_trigger`), where NA2 plays `0x22`; draws its broken model without NA2's `+0xCC` context clear (BTL `0x006C5040`). |
| 55 | `s04`, `s13` | `0x088F0098` / `0x088EFDC4` / `0x088F0058` | Reacts to four fighters, on crash actions `0x44`/`0x45`/`0x4A` and `0x47`/`0x48`/`0x4B`, NA2's `0x42`/`0x43`/`0x48` and `0x45`/`0x46`/`0x49` (`ACT_DMG_SSF`/`_SSB`/`_SBS` and `_SD`/`_SD2`/`_SBD`; UNH3 numbers its damage actions two above NA2's, `action_descriptor_table`). Its final break advances its section's line variant (section `+0xF0` = (`+0xF0` + 1) % `+0xF4`, `bg_crash_break_update`). `s13`'s, `DMY_line_0201`, differs from `DMY_line_020` only in starting at -1550 instead of -1010, at the same height, so section transfers land where they did; its wall's own collision (`HIT_s13are01_hit`), which the break removes, is what holds fighters right of it before. `s04` has no variant markers. NA2's (BTL `0x006CA8A0`) changes no line. |
| 57 | `s07` | `0x0890B568` / — / `0x0890B4EC` | Keeps a scale per placement and draws each without NA2's per-placement bounds gate (`0x0039E710`). |
| 78, 102 | `s08`; `s21` | `0x088F2690` / `0x088F2530`; `0x088EC5FC` / `0x088EC214` | Same rebirth (wait over 120 updates, frame 1, alpha +0.05) with factory 50's differences; factory 102's token 5 is the initial frame, and its break plays `0x38` on scene 0 only, then `0x3A` (`bg_break_anm_trigger`), as NA2's plays `0x26` on raw slots 0 and 19 only, then `0x22` (BTL `bg_break_anm_trigger`). |

Their debris and drop weights (21/60/19 over pools 1..3) are NA2's.
UNH3's item records (`0x34` bytes from `0x08B884A8`) give codes 0..`0E`
NA2's kinds, flags (one hex digit lower) and amounts, with direct effects
two above NA2's, so these are NA2's items. Pool 3 is NA2's, `03`, but
pool 1 (`0x08B8483C`) holds `06`..`0D`, `12`, `11` against NA2's
`06`..`0C`, `25`, `27`, `2B`, `0D`, `0E` (`item_random_pool1`), and
pool 2 (`0x08B84880`) `29`, `28`, `2C`, `2A`, `30`, `2B`, `2D`, `2E`,
`32`, `19` against NA2's fifteen lanes of `23`..`31`
(`item_random_pool2`). UNH3 numbers its inventory items (kind 3)
otherwise: by direct effect, `29`, `2B`, `2D` and `2E` are NA2's `24`,
`26`, `29` and `2A`; `28`, `2A`, `2C`, `30` and `32` have no direct effect
and `19` effect 2, which no NA2 item has. Pool 1's `11` (an alternate
action with effect 17) and `12` (no effect) match no NA2 record of their
kind, 4. Which of UNH3's
item names (text entries 1250..1287, such as Bomb Kunai and Curse Tag:
Steal) these codes carry is not established.

UNH3's renderer differs where the archives depend on it. It expands palette
alpha to `2A - 1` (`0x088B4870`) yet discards each texel whose expanded
alpha does not exceed the texture's stored cutoff `r` times the material
alpha (`material_set_alpha_test`, `sceGuAlphaFunc` greater), so it keeps
the texels whose stored alpha is at least `⌊(r + 1) / 2⌋ + 1`. NA2 tests
the stored alpha itself against `r` and draws a texel below it without
writing depth
([Material draw modes](../../runtime/rendering/material_render_modes.md#blend-selection-and-model-state-producers)).
Every Stage Select archive has cutoff 112, and `s01`, `s04`, `s06`..`s10`
and `s22` also cutoffs above 128, which no unmodulated NA2 texel reaches
(`s01`'s `TEX_s01obj105`: 165), on trees, floors and scenery. It also
expands vertex colour channels to `2c - 1` without an upper clamp
(`0x088A6874`), so a channel above `0x80` overflows into the next:
`83 83 83 80` packs as `0xFF050505`. `s05`, `s09`, `s10`, `s21` and `s22`
have such vertices. Texture flag `0x08`, the models' blend selectors (0
and 1), animation tracks and hit meshes read as NA2's.

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
2. Blasts (unless the record names a second object; `s10`'s give `0`):
   plays `04cmn/effect0x.ccs` `ANM_e0x_bom0` at a point jittered ±10,
   turned at random about z; starts a `ccEffectBlur` of type 6 from
   `0x08B39190`, a copy of the screen at scale 1.1, turned π/16, colour
   `0x50808080`, easing back to scale 1, no turn and no alpha over 20
   updates (NA2's `ccEffBlur`, `effect_blur_create` `0x00333700` and
   `effect_blur_configure` `0x0030DAA0`, takes the same values but eases
   its alpha to `0x80`); plays sound `0x1011` at the bomb
   (`sound_play_at`), `battleSE`'s program `0x11`, whose tone plays VAG
   `0x20` (8000 Hz, `.pbd` `0x31AB0`, `0x1C30` bytes), with the envelope
   of `commse0`'s tones, which no bank of NA2's `DATA/SNDDATA.BIN`
   contains; and for 16 updates hits each of the manager's four fighters
   (`+0x32C`; NA2's manager has two) whose hit-rejection count `+0x25C` is
   zero and that lies within the radius (the count is `current` of the
   fighter's `TimelineBlock` at `+0x250`, NA2's `Fighter.hit_rejection`:
   negative while an assigned rejection waits to start, positive while hits
   are refused; NA2's `hit_enter_stage_object` skips only a positive count)
   with the record
   時限爆弾: category 1, flag `0x100000`, attack 0.1, knockback 1, repeat 1,
   rejection 10 and a response chosen at random from `0x12, 0x14, 0x10,
   0x11, 0x0B, 0x0C, 0x0D, 0x0E` (`0x08B39160`), NA2's InteractionRecord
   layout.
3. Waits hidden 200 under a random spot for the stay-away updates, then
   rises to it over 30 updates.

It holds while stage updates are restricted.

## Sounds and surface effects

A sound's high hex digit picks a bank of `sound_banks` (`0x08C72188`: 0
`sound/se/commse0`, 1 `battleSE`, 2 `eventSE`, then characters' banks) and
its low digits a six-byte row of that bank (`sound_row`): program, note
(mostly `0x40`) and maximum volume. `sound_play_at` plays it at a position
with the row's note, `sound_play_at_note` with another. A bank is a PSP
`PPHD` header (`.phd`) over its samples (`.pbd`): `PPPG` programs, each a
tone count and tone indexes; `PPTN` tones of `0x60` bytes, a VAG index
first and the key range at `+0x10`..`+0x14`; `PPVA` VAGs of 16 bytes: the
`.pbd` offset, the rate and the size. Each VAG's data is NA2's ADPCM
followed by one more 16-byte frame (`00 07 77`..). `commse0` holds NA2's
common samples (tones 3, 5, 9 and `0x34` at the index of the NA2 VAG
records holding them), so most of its sounds are NA2's under other
numbers: `0x38` NA2's program `0x26`, `0x3A` `0x22`,
`0x42` `0x30`, `0x50` `0x07`, `0x3B` `0x23`, `0x48` `0x09`, and the
footsteps below. Those tones carry the same envelope words (`0x800F`,
`0x9FE0` at `+0x50`) where NA2's records give program volume `0x7F`,
sample parameters `80D0` and VAG flags `00FF`. `0x45` and `0x47`, and
`battleSE`'s `0x11` (sound `0x1011`), are none of NA2's.

Footsteps (`fighter_play_footstep`, from the walk and run states of
`fighter_schedule_action_audio`) follow NA2's surface map at NA2's
per-character notes, with sounds that are NA2's samples (`0x2D` NA2's
program 0, `0x2E` 1, `0x31` 2, `0x33` 3, `0x34` 4, `0x35` 5, `0x32`
`0x3E`, and `0x2F`, NA2's `0x3F`, as the extra step of characters `0x15`
and `0x53`), except that `0x60C0` takes the `0x80D0F0` step, program 0,
where NA2 plays its event 6. Running dust (`fighter_surface_run_effects`)
rises only on `0x90B0C0`, `0x3060`, `0x606060` and `0x5000`, where NA2
also raises it on `0x80D0F0`, `0xF0D0D0` and `0xF0F0F0`, and comes from
UNH3's own effect catalog (entry `0x3F`), whose art is not compared with
NA2's ground smoke. Knockdowns, bounces and falls in damage states
(`fighter_present_action_effects`) add a surface thud
(`fighter_surface_thud`) NA2 has no counterpart of: `0x45`, or `0x47` on
two damage-state landings, on `0x8080F0`, `0x5000`, `0x80D0F0`,
`0x606060`, `0x90B0C0` and `0x3060`; `0x48` on water and, at note `0x32`,
on `0x202020`; `0x3B` on `0x60C0`.
