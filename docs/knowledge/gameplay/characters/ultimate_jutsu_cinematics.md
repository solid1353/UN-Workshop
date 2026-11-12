# Ultimate Jutsu cinematics

## Research coverage

Established: opponent selection, side/role setup, the names of a stream's
optional offsets and filter, authored appearance and
texture/draw switches and how UN3 keeps its appearance substitutions, defender draw/placement/matrix gates, bone replacement,
popup interruption, selected geometry providers, the resident BSS globals
for opponent groups, optional switch tables and the derived main path, and
the screen-held panels, domes, distortion lenses and backdrops ending at the
4:3 view of sampled films.
Open: the intended optional-body constant/resource, the capacity of the
derived main-path buffer, targets across every cinematic, accumulated matrix orientation and visible body animation in
omitted-draw ranges. Names come from `@annotations/NA2`; comments and types
carry code-level details. Static resident/BTL/ETC and clean CCS evidence
establishes dependencies, not live allocation success. UN4's cinematic formats
are compared in [UN4 Ultimate Jutsu](un4/ultimate_jutsu.md); donor character
cinematics are in [UN3 and UN4 characters](un3_un4_characters.md).

Retail NA2 (`SLPS-25837`) selects and adjusts authored Ultimate Jutsu cinematics
for an attacker, defender and skill. Starting the cinematic, the contest and
its outcome belong to [Ultimate Jutsu](ultimate_jutsu.md).
Transport, request tables and player controls belong to
[CCS runtime](../../game/files/ccs_runtime.md);
record identities to [CCS object types](../../game/files/ccs_object_types.md);
character palette ownership to [Character assets](../../game/character_assets.md);
curve evaluation to [Animation runtime](../../runtime/animation_runtime.md);
cue rows to [Battle audio](../session/battle_audio.md#authored-cinematic-frame-rows).

## Screen-held panels

Films cover the screen with flat effect models held in front of their
camera, each sized to the 4:3 screen with a small margin. White flashes and
letterbox bars are the shared boards `MDL_e00board01_w` and `MDL_e00board01_b`
(` e\00\max\e00board01.max`), as in `D81_20` and `D65_10`; `D92_10`'s green
band `MDL_e92img01b` and its speed-line sheets `MDL_e92syt02a/b` face the
camera the same way. A distant backdrop can be tilted: `D68_20`'s sky
`MDL_e68sky02` is a flat plane whose corners' depths differ by about 8%.
`D70_25`'s smoke instead comes from strongly tilted sheets
(`MDL_e21windw02_a..e`), and `D58_50`'s background from 3D pieces
(`MDL_e58bgcla..d`), which `D62_50` shares. Speed lines can be several
copies of one flat piece, each from one screen edge toward the middle:
`D69_20` draws `MDL_e00line46a` (` e\00\max\e00line46.max`) that way, with
no depth offset. Some screen covers are domes around the camera rather than
flat panels: `D58_50`'s expanding air disc `MDL_e58air5a` (frame 28) spans
the whole 4:3 width with its far corners 1.21–1.40 times as deep as its near
ones, and `D69_20`'s green disc `MDL_e69back03` (frame 168) 1.53–2.56 times.
`D76_10`'s light sphere `MDL_e76img01` (frame 44), 2.5 times as deep at its
far corners as at its near ones, ends just past both 4:3 edges, behind a
burst panel that covers the screen's height. It loads from the film's
effect container `str/d76_10e.ccs`, as a hemisphere of seven vertex rings
(scale 512) from its pole at the origin, under the burst, to its rim at
raw radius about 3075 and Z 3082, which leaves the 16:9 corners bare.
The streak lines `MDL_e71line03a/b` of `D71_50` and `D72_50` start at the left 4:3 edge at frame 147. Backdrops and effects of other films end just past
the 4:3 view: `D07_10`'s pink backdrop `MDL_e07back01` (frame 195),
`D13_30`'s red backdrop `MDL_e13img03` (frame 153), which `D13_10` shares,
`D13_30`'s backdrop `MDL_e00back35` (frame 206), the sky
`MDL_e60sky02_a` of `D60_10` (frame 34) and `D60_20`, `D60_20`'s fire
`MDL_e60smp02_b` (frame 353), `D62_20`'s smoke `MDL_e62smk01c` (frame 597)
and sky dome `MDL_e62bg_sky` (frame 565), and `D86_20`'s fire cloud
`MDL_e86fir01a..d` (frame 183). So do 3D sets, such as `D70_10`'s rocks and
`D78_20`'s smoke and walls. `D07_10`'s orange filter `MDL_e07fil01` (frames
362 and 376) is a flat panel facing the camera that ends just past the right
4:3 edge, while its left end stops inside the left one. `D60_10`'s light
pillar `MDL_e60img02_a/b` (frame 128), which `D18_20` and `D60_20` share, is
curved, its far corners 1.6 times as deep as its near ones, and each of its
two layers ends just past one 4:3 edge. `D57_20`'s floor `MDL_e57flo01`
(frame 177), which `D57_25` shares, is a round crater disc seen from above at
an angle, its far corners 1.7 times as deep as its near ones, whose edge ends
just past both 4:3 edges. `D57_35`'s blast dome `MDL_e57shoth` (frame
428) ends just past the left 4:3 edge. `D58_10`'s floor `MDL_e58flo05`
(frame 188), part of which is behind the camera, ends past the left 4:3 edge
in the screen's top-left corner. Its other floor `MDL_e58flo04` and its
mesas `MDL_e58gak02` and `MDL_e58gak03` (frames 38, 202, 242 and 266) end
just past the 4:3 edges, leaving the sky showing below the horizon at the
sides; `D58_30` shares `MDL_e58gak02`. At frame 150, the slope of
`MDL_e58flo04` hides a darker part of the sky `MDL_e58sky04`. `D58_20`'s canyon walls `MDL_e58gake03`
(frame 38) end in a straight vertical cut just past the right 4:3 edge. Just
past a 4:3 edge also end `D58_20`'s pink burst `MDL_e58img02sr` (frames 206
and 287) and clouds `MDL_e58kmo01` (frame 378), `D58_30`'s cliff
`MDL_e58gak01` (frame 218) and rubble `MDL_e58rocs01b` (frame 285; it and
`MDL_e58rocs01a`, which meets it, are in `D58_20` too), `D65_30`'s floor
`MDL_e65flo05` (frame 378), `D70_20`'s distant mountain `MDL_e70mtn01a`
(frame 271) and the sky `MDL_e70sky01` (`D70_10` frame 348), which `D70_20`
and `D70_25` share. At `D70_20` frame 240 the base of `MDL_e70mtn01a` hides
part of the sky that is dark below the horizon. `D65_20`'s
background blocks `MDL_e65fbk00_00..10` (frame 285) form a ring around the
scene, and one of them stands with a straight edge just past the right 4:3
edge. Also ending just past a 4:3 edge: `D66_30`'s light column
`MDL_e66img02` (frame 213), `D67_30`'s canyon wall pieces
`MDL_e67rock01_a..d` (frame 20) and rock step `MDL_e67rock02_e/f` (frame
44), `D68_30`'s smoke `MDL_e68kem7b` (frame 460), which `D93_30` shares,
`D79_10`'s disc `MDL_e79clr00` (frame 401), and `D80_10`'s backdrops
`MDL_e80bgf20`, `MDL_e80bgs20`, `MDL_e80bgm20` and `MDL_e80bgr20` (frames
72, 176 and 285); widening the rear one, `MDL_e80bgr20`, cuts its cliff
open at frame 285. In
`D64_30` at
frame 23, the forest `MDL_e64ki00` ends just past the right 4:3 edge, and
its nearest trunk hides a dark area that the far forest `MDL_e64enki00`,
which ends left of the screen center, leaves uncovered; the dark areas at
the sides of frames 30, 104, 165 and 369 come from the same forest.

More films' skies, backdrops and effects end just past a 4:3 edge:
`D59_10`'s sky `MDL_e59sky00` (frame 90) and `D59_35`'s sky
`MDL_e59sky02` (frame 408), `D59_30`'s ring of background pieces
`MDL_e59back01_a..i` (frame 77), which `D59_20` shares, `D60_30`'s sky
`MDL_e60sky01r` (frame 146) and red glow `MDL_e60gre01` (frame 324),
`D61_10`'s smoke ring `MDL_e61skrm01b` (frame 279), `D61_20`'s background
`MDL_e61bg001` and floor `MDL_e61fl01`, which leave a dark line at the right
horizon between them (frame 333), `D61_30`'s cliff `MDL_e61roc04_01..03`
(frame 278), `D62_10`'s sound-effect letters `MDL_e62zugaa/b`, cut where
their panel ends (frame 313), `D63_10`'s rocks `MDL_e63roch01a/b` and
`MDL_e63bgrc01b/d/e` (frame 315), which `D63_20` shares, the sky
`MDL_e63sky01_01` of `D63_50` and `D64_50` (`D64_50` frame 114),
`D71_10`'s floor `MDL_e71flo01` (frame 293), which `D71_50`, `D71_51`,
`D72_50` and `D72_51` share, `D72_20`'s water burst `MDL_e72hasi04` (frame
385), `D72_30`'s sky `MDL_e72_sora` (frame 288), `D83_10`'s sky `MDL_e83sky10` (frames 91 and
162), `D90_10`'s speed lines `MDL_e90line01k` (frame 145) and blue flames
`MDL_e90cut07` and `MDL_e90cut07b` (frame 352), `D91_10`'s speed lines
`MDL_e91line01` (frame 49), `D91_20`'s filter `MDL_e91fil0` (frame 165),
the background `MDL_e93bg01_sky` and `MDL_e93bg01_mut` of `D89_50` (frame
25), which `D93_20` and `D93_50` share, the speed-line tunnel
`MDL_e93img01b` of `D93_30` (frame 25), which `D89_50` and `D93_50` share,
and `D93_30`'s backdrop `MDL_e93_bgl` (frame 398). `D76_10`'s background
pieces `MDL_e76back01_a..i` end just past the 4:3 edges too (frames 63 and
384), but at frame 384 those drawn, widened together, open a dark band at
the left. In `D93_30` at frame 119, Sasuke's close-up face `MDL_e93ssfac0`
ends short of the right 16:9 edge. `D72_20`'s sky dome `MDL_e72sky00` has a
dark rim just past the left 4:3 edge in the top-left corner (frame 385), and
`D80_10`'s floor `MDL_e80bgf20` leaves the bottom-right corner of the 16:9
view bare (frame 176).

`scene_object_submit_geometry` (`0x00190F40`) gates a scene object's shadow,
its auxiliary model queued through `model_part_queue_projection`, apart from
its body, so a hidden body still casts one. In `D62_10` at frame 313,
Chiyo's `MDL_1chy00t0 shadowNN` and the wire puppet's
`MDL_e6200t0 shadow` reach the shadow pass while neither body draws; both
shadows lie just outside the 4:3 view. These are frames sampled through PINE
while the film plays, not every film.

Distortion lenses are `ygm` models, such as `D58_50`'s `MDL_58ygm_a` and
`D57_25`'s `MDL_e57zygm02_b`, which about forty films carry. Before one draws,
the film copies the screen with sprites to its own buffer, and the lens draws
that copy back blended at half, through a destination-alpha test. Its texture
coordinates follow its own projected vertices, clamped to the copy: in
`D58_50` frame 28 each vertex samples about 0.63 of its distance from the
screen center, a zoom, in both directions.

## Addresses

Addresses are live and follow
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
The following globals belong to the resident ELF, `SLPS_258.37`, and are
annotated in its BSS block. Their producers and consumers establish these roles:

| Symbol | Role |
| --- | --- |
| `sp_skill_opponent_groups` | Relocated `SpSkillOpponentGroup` array pointer |
| `sp_skill_opponent_group_count` | Signed halfword opponent-group count |
| `sp_skill_texture_switch_table` | Owned expanded texture-switch table pointer |
| `sp_skill_draw_switch_table` | Owned expanded draw-switch table pointer |
| `sp_skill_override_main_path` | Buffer for the derived main resident path; capacity remains unestablished |

## Opponent-dependent cinematic selection

`sp_skill_play_start` (`0x0035CF00`) resolves the attacker/defender roles,
then asks `jutsu_resolve_character_skill` (`0x0035CA80`) for a replacement.
Any result other than `-1` replaces the requested skill before resource
lookup. The initialized opponent table contains three defender groups:

| Defender ID | Requested skill | Replacement skill | Stored path |
| ---: | ---: | ---: | --- |
| `0x59` | `0x48` | `0x49` | `pl/2nrtbod1.ccs` |
| `0x4C` | `0x04` | `0xB6` | `pl/2nrtbod1.ccs` |
| `0x4C` | `0x0C` | — | `str/d05_11.ccs` |
| `0x4C` | `0x18` | `0xB7` | `pl/2nrtbod1.ccs` |
| `0x4C` | `0x1C` | — | `str/d13_21.ccs` |
| `0x4C` | `0x22` | — | `str/d15_21.ccs` |
| `0x4C` | `0x3B` | — | `str/d36_21.ccs` |
| `0x4C` | `0x7A` | — | `str/d69_21.ccs` |
| `0x4C` | `0x48` | — | `str/d46_12.ccs` |
| `0x4C` | `0x84` | — | `str/d71_51.ccs` |
| `0x4C` | `0x88` | — | `str/d72_51.ccs` |
| `0x28` | `0xB0` | — | `str/d92_11.ccs` |

A dash represents stored replacement `-1`. These nine rows keep the skill
and let `sp_skill_find_stream_override` (`0x0035C930`) choose the stored
opponent-specific stream path. The main resident path in
`sp_skill_override_main_path` substitutes `e.ccs` for `.ccs`, using
`sp_skill_main_ccs_extension` and
`sp_skill_ccs_extension`. `sp_skill_build_requests` (`0x0035CC20`) uses
both paths. The three nonnegative replacements change the skill first,
so their old stored paths are not selected by lookup on the replacement;
that skill's normal SINF row supplies its resources
([request-table source](../../game/files/ccs_runtime.md#request-table-source)).

Attacker `0x51` has the only additional attacker-specific branch:
skill `0x95` becomes `0x96` when `Fighter.contact_flags` has marker
`0x20`. `awakening_clear_marker` (`0x0020DD20`) clears it before return.
With this attacker and a valid fighter, the helper also clears the marker
when the replacement condition fails, before the table lookup. The raw
byte access and saved field declaration establish this gate.

An uninitialized group pointer or zero count returns `0`, whereas an
initialized search without replacement returns `-1`; the constructor accepts
the former as a replacement. This contract does not establish a presentation
before initialization. `sp_skill_relocate_request_table` (`0x00357B10`)
initializes the tables after resource adoption in
`battle_skill_ccs_adopt` (`BTL.BIN 0x00769110`) and
`etc_skill_ccs_acquire` (`ETC.BIN 0x006BE710`).
The direct-call coverage does not exclude indirect callers.

## Participant fields and request callbacks

The two side descriptors are independent of attacker side. Each descriptor's
low byte is its fighter ID; bits `16..23` are its appearance flags.
`UltimateJutsuSkillPlay` retains both side and role ordering. These fields
are established by raw accesses; typed owner-array expressions alone do not
establish their layout:

| Field | Initial value |
| --- | --- |
| `attacker_side` | attacker side |
| `side_ids[0/1]` | side-0 / side-1 fighter IDs |
| `appearance_flags[0/1]` | side-0 / side-1 appearance flags |
| `attacker_id / defender_id` | role-ordered fighter IDs |
| `selected_skill / skill` | selected skill after replacement |
| `request_ordinal` | zero |

`sp_skill_play_begin` (`0x0035A070`) runs for each request. It retains
`container` and the first resident request's `main_container`, binds defender
body/eye/mouth resources to `EXT_1cmn00t0`, and finds the attacker body through
the side-formatted `EXT_1xxx00t0 body` name. It names the stream's optional
defender offsets and filter after the stream's header name,
`sp_skill_damage_offset_name_format` (`0x005AB668`) and
`skill_stream_filter_resource_format` (`0x005AB760`, any extension removed),
and finds each through the case-sensitive optional lookup, so a stream whose
header name differs from those objects' suffix, even in letter case only,
plays without them. Appearance lookup uses each side's
own retained flags. After installing resources and the time limit, setup
increments `request_ordinal`. Callback order belongs to
[CCS runtime](../../game/files/ccs_runtime.md#per-request-lifecycle-in-playdecode).

Two exclusions skip construction of `optional_body` while setup continues:
defender `0x5D`, or defender `0x0A` with `stream_identifier == 0x200302`.
The latter identifies no shipped move.

### Stream-name identifier and the optional-body comparison

The identifier comes from the inline CCS header name read by
`ccs_read_header` (`0x001AC290`) into `CcsContainer.name`, independently
of request path, selected skill or defender ID. Setup computes:

`(((name[1]-'0')*16 + name[2]-'0') << 8) | ((name[4]-'0')*16 + name[5]-'0')`.

The bytes are signed. The parser ignores the `d`, underscore, optional
`e` suffix and any third digit in either pair; `d14_20` produces `0x1420`.

The inspected retail numeric headers have two decimal digits in each pair.
Their maximum result is `0x9999`, so they cannot satisfy the setup comparison
with `0x200302`. The separate defender-`0x5D` exclusion remains unconditional.
No alternate identifier producer appears between parsing and comparison
inside this callback. The mismatch establishes neither an intended constant,
resource nor player-facing move name.

UN2's begin routine builds its identifier from three digits of a
`dDD_L_P` stream name, so `0x200302` there is stream `D20_3_2` (Guy's
Ultimate: Hidden Lotus), the one film in which defender Haku (ID 10) does
not get his mask, and `0x70302` is `D07_3_2`, where UN2 also hides
`OBJ_1skr20t0 bod`
([Nine-Tailed Naruto: UN2](un2/nine_tailed_naruto.md#ultimate-jutsu-contest-and-damage)).
NA2 kept both constants.

| SINF skill | Stream path | Header identifier |
| ---: | --- | ---: |
| `0x20` | `str/d14_20.ccs` | `0x1420` |
| `0x84` | `str/d71_50.ccs` | `0x7150` |
| `0x88` | `str/d72_50.ccs` | `0x7250` |
| `0x95` | `str/d81_20.ccs` | `0x8120` |
| `0x96` | `str/d81_30.ccs` | `0x8130` |

The header check does not decode every cinematic or establish selection of
every request.

## Authored appearance substitutions

`SpSkillRequestRow.appearance_count` and `appearance_rows` select
`SpSkillAppearanceRow` entries independently of the resident/stream request
counts. The clean table contains 142 entries used by 57 skills: 96 `EXT`
and 46 `MAT` targets. A zero count has a null appearance pointer.

Each entry names a source container, source palette and target.
A null source-container name means the request's main resident container.
Attacker-side flags are masked with `5`: bit `0` appends
`sp_skill_palette_c1_suffix` (`c1`), otherwise bit `2` appends
`sp_skill_palette_c2_suffix` (`c2`), otherwise the name is unchanged.
Bit `0` wins when both are set
([palette ownership](../../game/character_assets.md#model-and-appearance-name-consumers)).

`sp_skill_apply_external_palette` (`0x00357FE0`) substitutes streamed
`EXT` targets only after finding the target, source container, selected
palette and target `CcsScenePlayTarget.model`. It duplicates the affected
arrays through `model_instance_duplicate_arrays` (`0x00198B10`) with
`0x2000`, then applies the palette through
`model_instance_rebind_palettes` (`0x00198AB0`).
`sp_skill_apply_material_palette` (`0x00358130`) substitutes other targets
in the selected resident container through `SpSkillPaletteTarget.palette`.
Missing required lookups omit the substitution; this does not establish a
shipped lookup miss.

`sp_skill_play_begin` applies a skill's entries after rebinding the attacker's
and defender's bodies (`sp_skill_play_begin_apply_appearance_rows`). It reads
the request row by skill with no upper bound, sends an entry whose target
starts with `EXT` to the external routine and any other to the material
routine, and applies entries with the default costume too, through the
unsuffixed palette.

UN3 keeps these substitutions in its executable instead.
`sp_skill_palette_record_lists` gives each skill `{container, target,
CLT…c1, CLT…c2}` records, applied only when the attacker's flags masked with
`5` are set. `sp_skill_apply_appearance_substitutions` also swaps material
palettes in code for streams `d23_101`, `d10_102`, `d03_202` and `d01_204`,
whatever the flags, with the unsuffixed palette when they are zero.

| Skill | Entries | Representative substitutions |
| ---: | ---: | --- |
| `0x01` | `5` | `2nrtbod1/CLT_2nrtbody` on five `EXT_2nrt00t0..04t0 body` targets. |
| `0x02` | `24` | Nine main-container copy targets, four body-provider targets, and eleven main-container material targets. |
| `0x20` | `2` | `1tovbod1/CLT_1tovbody` on `EXT_1tov00t0 body`; `1tyobod1/CLT_1tyobody` on `EXT_1tovudebody`. |
| `0x7F` | `5` | Three `1kkwbod1` and two `2kkwbod1` body targets. |
| `0x95 / 0x96` | `1` each | Both use main-container `CLT_2tywhss` on `MAT_e81hss01e`. |
| `0xB5` | `1` | Main-container `CLT_e93ssw` on `EXT_e93ssw`. |

## Per-character texture and draw-state switches

Two optional families use `character_model_abbreviations` to load attacker
`BIN_` resources from `strmcmn`, independently of the SINF appearance count.
The clean resource inventory is:

| Resource | Directory ID | Authored changes |
| --- | ---: | --- |
| `BIN_strtc_data_kiw` | `404` | Skill `0x8F`: source `d78_30e.ccs`, `TEX_1kiwakw1 -> TEX_1kiwakw2` on `EXT_1akw00t0 body` at frame `1`, reversed at `510`. |
| `BIN_strrev_data_itw` | `401` | Skill `0x84`: `OBJ_rev01/OBJ_rev03`, enabled at `385`, disabled at `538`, group values `15/5`. |
| `BIN_strrev_data_kbw` | `402` | Skill `0xAC`: `OBJ_rev01`, enabled at `235`, disabled at `263`, group value `10`. |
| `BIN_strrev_data_ksw` | `403` | Skill `0x88`: the same target names and `385/538` changes as the `itw` resource. |

`sp_skill_load_texture_switches` (`0x00358560`) runs before player
construction. Missing resources or zero groups return zero; no group for
the requested skill frees the table but returns one. The constructor does
not branch on this return.

`sp_skill_apply_texture_switches` (`0x00358AD0`) does nothing without a
table. Forward playback applies matching changes at their exact frame;
frame `1` or negative playback instead uses
`sp_skill_reconstruct_textures` (`0x003588D0`) to restore each target from
the latest eligible entry.
`sp_skill_apply_texture_entry` (`0x00358BF0`) requires the source,
target and texture before applying a change. `sp_skill_play_destroy`
(`0x0035D7C0`) releases the table during teardown.

`sp_skill_load_draw_switches` (`0x00358DA0`) runs during request setup.
Missing resources, zero groups or no matching skill return zero; the last
case frees its table. A match initializes targets hidden through
`scene_apply_table_draw_modes` (`0x003592C0`).
Per-frame application selects the last change at or before the current frame,
updates the render group through `ordered_controller_set_group`
(`0x0010A0A0`), and sets `CcsScenePlayTarget.alpha` and its
flag-dependent `inherited_factor` to `0.0/1.0`.
`model_instance_set_blend` (`0x001987A0`) selects `0/10`.
`sp_skill_release_draw_switches` (`0x003590D0`) frees the table and
attached helpers at request end.

Absent tables omit optional changes while the surrounding callbacks continue.
The resource inventory comes from clean CCS contents; the receiving resident
pointer slots are uninitialized in the static image. These facts establish
neither failure nor provider/target presence in every stream.

## Defender-specific draw and placement dispatch

`sp_skill_play_draw` (`0x0035C110`) uses
`sp_skill_defender_body_draw_allowed` (`0x00356E90`) with defender ID,
selected skill and current frame. Zero omits
`sp_skill_draw_scene_entries` (`0x003556C0`) for `optional_body`;
other drawing continues.

`sp_skill_defender_draw_gates` holds inclusive frame ranges and optional
defender lists. An empty list selects `{0x38,0x35,0x23,0x32,0x33,0x30}`.
Outside the ranges, for an unlisted defender or without a skill table, ordinary
drawing proceeds. Seven code-driven substitutions replace the selected gates:

| Skill | Defender | Replacement omitted-draw ranges |
| ---: | ---: | --- |
| `0x84 / 0x88` | `0x30` | `258..274`, `426..539` |
| `0x84 / 0x88` | `0x49` | `426..635` |
| `0xB0` | `0x30` | `170..219` |
| `0x78` | `0x30` | `470..521` |
| `0x4E` | `0x35` | `333..667` |

Ordinary skill `0x78` omits `169..180`, `350..405` and `460..469`
only for `0x49/0x30`; the override changes the `0x30` case.
Ordinary `0x84/0x88` omit `426..539` for
`{0x3B,0x30,0x38,0x33,0x32,0x49,0x4B}`.
These gates affect rendering, not damage, contest state or cinematic stopping.

UN3 keeps the same hiding in `sp_skill_optional_body_hide_ranges`
(`0x0047C010`): per skill, a range count and inclusive `{start, end}` frame
halfwords, always for the six default defenders, read by
`sp_skill_defender_optional_body_allowed`. Against Kidomaru, the hidden
optional body includes his fourth arm, which disappears in those frames
(runtime observation).
Visible body animation within the omitted ranges remains unestablished.

`sp_skill_adjust_defender_position` (`0x003571F0`) selects from
`sp_skill_defender_position_groups` and `sp_skill_defender_position_rules`.
A matching defender and inclusive frame range replaces the four-component
position prepared by the frame callback; no match keeps it unchanged.
Shared lists cover skills `0x4F/0x54`, `0x84/0x88`, `0xA7/0xB5` and
`0x1E/0x1F`. Representative entries show why the replacement skill matters:

| Skill | Defender | Frame range | Stored vector |
| ---: | ---: | --- | --- |
| `0x4F / 0x54` | `0x33` | `400..460` | `(-36,82,0,1)` |
| `0x84 / 0x88` | `0x3F` | `426..539` | `(9,-5,5,1)` |
| `0x95` | `0x28` | `421..470` | `(-144,-29,33,1)` |
| `0x96` | `0x28` | `461..510` | `(-144,-29,33,1)` |

`ccs_matrix_row_toggle` (`0x003572E0`) applies
`sp_skill_defender_object_groups` for a specific defender or `-1`
and an inclusive frame range. Authored command prefixes mean:

- `U ` clears `CcsScenePlayTarget.flags` bits `2..3`; `D ` sets them
  and restores `alpha/inherited_factor` to `1.0` through the ordinary
  flag-dependent update.
- `UU` finds the named subobject of `CMP_1cmn00t0 trall` and replaces
  the first three local-matrix vectors with zero vectors.
- `SXR` negates the first local-matrix vector and marks `matrix_dirty`.

The helper also implements `SR/SYR/SZR`, negating all three, the second
or the third vector, respectively; none occurs in the inspected clean table.
Missing targets keep their existing state. The complete shipped dispatch is:

| Skill | Defender | Inclusive frame ranges and targets |
| ---: | --- | --- |
| `0x05` | any | From `336` through `9999`, `U ` on `EXT_e02_tdrn01/02`. |
| `0x84 / 0x88` | `0x16` / any | `UU` on the named common-body subobject at `426..539` for `0x16`; `SXR` on `EXT_e71eye02` at `0..9999` for every defender. |
| `0xA7 / 0xB5` | any | `U ` on `EXT_e93smk05c32/33/34`, `0..9999`. |
| `0x29` | any | `U ` on `EXT_1sin00t0 body`, `111..269`. |
| `0x9B` | any | `U ` on `EXT_1jrw00t0 body`, `151..168`. |
| `0x94` | any | `U ` on both `EXT_1tyw00t0` and `EXT_1cmn00t0` eye1/eye2/mou1 targets, `97..139`. |
| `0xB2` | any | On common eye1/eye2/mou1 targets: `D ` at `212..236`, `U ` at `237..281`, `D ` at `282..455`. |

These predicates can run every eligible frame, including `SXR`.
The operation and ordering do not establish the accumulated visible
orientation after surrounding animation updates.

`jutsu_hit_popups_draw` (`0x0035C5B0`) consumes the same interruption gate
as the presentation cut. With contest status `4` and
`jutsu_branch_frame_reached` (`0x0035DB20`) accepting argument `0`,
both `UltimateJutsuSkillPlay.popups[].active` fields clear and normal popup
animation is skipped. The authored threshold is frame `126`.
This consumer neither produces status `2` nor issues a cinematic branch.

`sp_skill_bind_alternate_body_parts` (`0x00358250`) retains original models
for `sp_skill_defender_bone_names`. Defender `0x32` enables all 17 through
`sp_skill_gaara_bone_mask`; `0x4C` enables only `pelvis/spine/spine1`
through `sp_skill_hiruko_bone_mask`; other IDs do no replacement.
It requires the node and provider before constructing a replacement.
`sp_skill_play_end` (`0x0035AF20`) restores the models at request end.

### Selected defender providers and cinematic targets

The provider comes from `CcsSceneObjectDescriptor.shadow_model_record`,
which `ccs_parse_scene_object` (`0x001B2670`) populates separately from
`model_record`. Replacement requires a `CcsRecord.runtime` other than
null or sentinel `4`; `ccs_model_instance_initialize` (`0x001992A0`)
constructs the replacement handle, installed as
`CcsScenePlayTarget.auxiliary` while `bone_replacements[].original`
retains the previous model. Before that geometry check, the node mask writes
target `flags` bit `5`, including clearing it for a disabled node.
Both node-name lookups are optional; their handling belongs to
[CCS runtime](../../game/files/ccs_runtime.md#wildcards-and-secondary-values).

`character_presentation_body_filenames` and `character_model_abbreviations`
select `1gavbod1.ccs/gav` for defender `0x32` and `1schbod1.ccs/sch`
for `0x4C`. Names follow `sp_skill_defender_node_name_format`
(`EXT_1cmn00t0 %s`) and `sp_skill_provider_node_name_format`
(`OBJ_1%s00t0 %s`)
([body-table ownership](../../game/character_assets.md#character-indexed-filename-families)).

Both `PL/1GAVBOD1.CCS` and `PL/1SCHBOD1.CCS` contain all 17 requested
provider nodes with these directory IDs. Secondary links select
`MDL_1gav00t0 shadowNN` or `MDL_1sch00t0 shadowNN`, each with model flags
`0x0008` and one mesh part. The primary bone-node models have zero parts
and are not this helper's source.

| Node | Provider object ID | Secondary model ID / `shadow` suffix | Cinematic wrapper ID |
| --- | ---: | --- | ---: |
| `pelvis` | `6` | `72 / 17` | `118` |
| `spine` | `7` | `74 / 16` | `119` |
| `l thigh` | `8` | `76 / 12` | `120` |
| `l calf` | `9` | `78 / 11` | `121` |
| `l foot` | `10` | `80 / 10` | `122` |
| `r thigh` | `12` | `88 / 15` | `124` |
| `r calf` | `13` | `90 / 14` | `125` |
| `r foot` | `14` | `92 / 13` | `126` |
| `spine1` | `19` | `104 / 09` | `131` |
| `neck` | `20` | `106 / 08` | `132` |
| `head` | `21` | `108 / 01` | `133` |
| `l upperarm` | `33` | `132 / 04` | `145` |
| `l forearm` | `34` | `134 / 03` | `146` |
| `l hand` | `35` | `136 / 02` | `147` |
| `r upperarm` | `48` | `157 / 07` | `160` |
| `r forearm` | `49` | `159 / 06` | `161` |
| `r hand` | `50` | `161 / 05` | `162` |

`ccs_parse_model` (`0x001B0C40`) allocates model descriptors for the nonzero
part counts. These stored dependencies and the parser path do not establish
successful allocation during a cinematic.

The wrapper IDs in the table are shared by the inspected
`D71_50/D71_51/D72_50/D72_51.CCS` files. All 17 common-node records use
`0x0A00` wrappers; `ccs_parse_external_record` (`0x001B2800`) changes
only the first three name bytes from `OBJ` to `EXT`.
[CCS runtime](../../game/files/ccs_runtime.md#type-0x0a00-traversal)
owns wrapper traversal.

| Variant | Pelvis/spine/spine1 linked model-instance IDs | Stored parents |
| --- | --- | --- |
| `50` | `1161/1162/1174` | `117/118/119` |
| `51` | `1252/1253/1265` | `117/118/119` |

The independently adjusted `EXT_e71eye02` is wrapper `112` in all four
files, linked to same-named `OBJ_e71eye02`: ID `1155` for `50`, ID
`1246` for `51`, parent `72` in both.
SINF skills `0x84/0x88` normally select `50`; defender `0x4C` selects
`51` through the [opponent override](#opponent-dependent-cinematic-selection).
These selected targets and providers are present. The bounded asset evidence
does not establish every cinematic's targets, allocation success or the
accumulated result of repeated `SXR`.
