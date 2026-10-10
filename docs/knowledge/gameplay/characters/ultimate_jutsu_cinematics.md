# Ultimate Jutsu cinematics

## Research coverage

Established: opponent selection, side/role setup, authored appearance and
texture/draw switches, defender draw/placement/matrix gates, bone replacement,
popup interruption, selected geometry providers, and the resident BSS globals
for opponent groups, optional switch tables and the derived main path.
Open: the intended optional-body constant/resource, targets across every
cinematic, accumulated matrix orientation and visible body animation in
omitted-draw ranges. Names come from `@annotations/NA2`; comments and types
carry code-level details. Static resident/BTL/ETC and clean CCS evidence
establishes dependencies, not live allocation success. NUN4's cinematic formats
are compared in [NUN4 Ultimate Jutsu](nun4/ultimate_jutsu.md); donor character
cinematics are in [NUN3 and NUN4 characters](nun3_nun4_characters.md).

Retail NA2 (`SLPS-25837`) selects and adjusts authored Ultimate Jutsu cinematics
for an attacker, defender and skill. Starting the cinematic, the contest and
its outcome belong to [Ultimate Jutsu](ultimate_jutsu.md).
Transport, request tables and player controls belong to
[CCS runtime](../../game/files/ccs_runtime.md);
record identities to [CCS object types](../../game/files/ccs_object_types.md);
character palette ownership to [Character assets](../../game/character_assets.md);
curve evaluation to [Animation runtime](../../runtime/animation_runtime.md);
cue rows to [Battle audio](../session/battle_audio.md#authored-cinematic-frame-rows).

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
the side-formatted `EXT_1xxx00t0 body` name. Appearance lookup uses each side's
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
