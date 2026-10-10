# Jiraiya: NUN4 donor

## Research coverage

Established for NUN4 Jiraiya 21 against NA2 Jiraiya 83: 46/181/154 against
45/177/151 actions/rows/names with complete authored correspondence and callback
differences; Needle Jizo and the resource-aware Rasengan against NA2's jutsu,
their labels and helper dependencies; two ordinary films and their bindings; the
Gamabunta controller, stage, attacks, shadow, particles and voices; the timed
power effect's lifetime and factors; Rasengan's compact control and Needle Jizo
cue 89, which has no PLVOICE member.
Open: remaining indexed identity services; unassigned scalar fields, whose
stored values a conversion preserves.

Names come from `@annotations/NUN4` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [NUN3 and NUN4 characters](../nun3_nun4_characters.md).

## Records, moves and assets

This comparison checks **NUN4 Jiraiya ID 21, `jry`**, against **retail NA2
Jiraiya ID 83, `jrw`**. NUN4 addresses are resident `SLUS_218.62` unless
qualified `BATTLE`; NA2 addresses are resident `SLPS_258.37` unless
qualified `BTL`. NA2's definition slot 21 is the ID-1 filler and is excluded
by its roster filter, as established in
[Character identity](../character_ids.md#character-definition-table).

| Checked root | NUN4 Jiraiya, ID 21 | NA2 Jiraiya, ID 83 |
| --- | --- | --- |
| Definition `{factory, record}` | `0x00574588`: `{0x00260930, 0x00495E80}` | `0x005A2B98`: `{0x002EBEF0, 0x00569F90}` |
| Factory / constructor | `jiraiya_create` / `jiraiya_construct`, `0x00260930 / 0x00260980` | `0x002EBEF0 / 0x002EBF40` |
| Allocation / concrete vtable | `0x58F0` / `jiraiya_vtable`, `0x005EB7A0` | `0x54C0` / `0x005DA370` |
| Mutable constructor descriptor | `jiraiya_constructor_descriptor`, `0x00495F60` | `0x0056A070` |
| Actions | 46 at `jiraiya_actions`, `0x00494C80`; stride `0x64` | 45 at `0x005690B0`; stride `0x54` |
| Phase rows | 181 at `jiraiya_animation_rows`, `0x004916C0`; stride `0x4C` | 177 at `0x00565A70`; stride `0x4C` |
| Name slots | 154 at `jiraiya_animation_names`, `0x00491450` | 151 at `0x005657B0` |
| Palette / texture / model / effect names | `0x00491220 / 0x00491388 / 0x004913C8 / 0x00491408` | `0x00564EB8 / 0x00565020 / 0x00565060 / 0x005650A0` |
| Callback table | `jiraiya_callbacks`, `0x00491430` | `0x005650C0` |

**Observations:** both records store the displayed name `自来也`; their
body strings are `2jrybod1.ccs` and `2jrwbod1.ccs`. Record bytes
`+0x58..+0xDB` agree exactly. This agreement concerns that scalar region,
not moves or construction. The NUN4 constructor assigns embedded names,
actions and rows at fighter `+0xED0/+0x1138/+0x2330`, through record
`+0x4C/+0x30/+0x40`, before calling `fighter_load_character_record`
(`0x001FC390`). It then initializes a `Nun4FighterControlBlock` and
publishes it with `value_10 = 2`, `value_12 = 16`, replacing the tail
initializer's default value 12. `fighter_control_block_publish`
(`0x00231E10`) copies all twelve halfwords to `+0xB30..+0xB46` and
mirrors them at `+0x908..+0x91E`. Their individual gameplay meanings remain
unassigned.

NA2's constructor additionally finds `ANM_pjrwfrg01` in its body provider,
stores it at `+0x548C`, constructs a separate `0x120`-byte scene at
`+0x5494`, and initializes mode `+0x5490` to 2. The concrete virtual
`+0x24` calls `jiraiya_update_frog_animation` (`0x002EC370`); `+0x28`
places/submits the scene when its mode is not 2. Virtual `+0x2C`,
`fighter_scene_5494_attack_pass` (`0x002EC260`), can publish its attack
banks during action 30 under the action/phase/pause gates. The destructor
at `0x002EC080` destroys this scene before common fighter cleanup. The
inspected donor constructor creates no corresponding separate frog scene;
its concrete virtual `+0x20/+0x28` are verified `jr ra; nop`.

### Authored action correspondence

The first 32 actions share the same authored row-start indices; subsequent
correspondence changes because donor action 32 occupies four additional
rows. Donor actions 33..45 correspond by animation suffix group to NA2
actions 32..44. Suffix correspondence does not establish equal animation
bytes, frame timing, input signatures or hit behavior.

The following are all changed normal-attack suffix families in the checked
action groups, plus the added group. Each suffix is prefixed `ANM_pjry`
in NUN4 or `ANM_pjrw` in NA2.

| Donor / NA2 action | NUN4 suffixes | NA2 suffixes |
| --- | --- | --- |
| 23 / 23 | `kcs00, kcs02` | `pnc20, pnc22` |
| 25 / 25 | `pnc20, pnc22` | `hed00, hed02` |
| 27 / 27 | `pnc40, pnc42` | `hjz00, hjz02` |
| 28 / 28 | `hai00, hai02` | `kcn00, kcn02` |
| 29 / 29 | `hai10, hai12` | `kcn10, kcn12` |
| 30 / 30 | `pnc70, pnc72` | `frg00, frg02` |
| 31 / 31 | `kcs10, kcs12` | `bur00, bur02` |
| 32 / none | `elb00, elb01, elb02`, category `4`, row 132 | No corresponding group |

The remaining normal groups have matching suffix sequences: actions
21/22/24/26, then donor 33..45 against NA2 32..44. Their authored
parameters still differ. Comparing the 68 logical bytes before the final
row word, after adjusting only owner ID and the first-four-action selector
words, yields equal bytes only for donor actions `2,7,8,9,19,38,43` and
their corresponding NA2 actions. The comparison leaves pointer/name words
outside that logical region; it does not assign meaning to unknown fields.
In particular, donor action 0 has category zero, whereas NA2 action 0 has
`0x10000`.

### Callback and identity-dependent behavior

| Callback channel | NUN4 Jiraiya | NA2 Jiraiya |
| --- | --- | --- |
| 2 | `jiraiya_channel2`, `0x00260B50` | `0x002ECEF0` |
| 3 | `jiraiya_channel3`, `0x00260BA0` | `0x002ECF40` |
| 4 / hit response | `jiraiya_hit_response`, `0x00261280` | `jiraiya_hit_response`, `0x002ED720` |
| 5 | `jiraiya_channel5`, `0x002616A0` | `0x002ED9D0` |
| 6 | Null | `0x002EDE30` |

The donor's complete static hit-response return set is
`{-1,0x29,0x2A,0x2E,0x30,0x31,0x33,0x36,0x3E}`;
NA2's is `{-1,0x2A,0x32,0x33,0x40}`. Both callbacks additionally
change receiver response scalars under their mode-2 gates. Thus corresponding
action families do not supply equivalent contact results.

For actual donor ID 21, channel 5 adjusts the shared ponytail transform
during actions 28/29 under different frame ranges. It queries
`jiraiya_common_ponytail_node_name` (`0x005A9260`),
`OBJ_2cmn00t0 ﾎﾟﾆｰﾃｰﾙ 1`, against fighter scene `+0xE60`.
When the actual receiver ID is different, its configured-jutsu-owner path
instead queries `jiraiya_foreign_receiver_head_node_name`
(`0x005A9318`), `OBJ_2jryh00t0`. The callback's actual fighter identity
is therefore distinct from the authored owner.

NA2 channel 3 has an exact-ID-83 path for action 30's frog, and marker
`contact_flags & 0x40` selects alternate working-row parameters and its
variant byte `+0x54B0`. Its channel 5 updates that frog's movement;
channel 6 supplies additional action-31 attack work. These native paths
are separate from the donor's hair-transform logic. Ultimate Jutsu and
linked-form selection are recorded in
[Jiraiya Ultimate Jutsu selection](#ultimate-jutsu-and-effects).

Both concrete AI virtuals call their game's common AI updater. The checked
current-ID descriptor shorts are `{2,5}` at NUN4
`BATTLE:jiraiya_ai_character_values` (`0x00853C34`) versus `{1,30}` at
NA2 `BTL:ai_character_values + 83*4` (`0x008C35AC`). Complete
Jiraiya-specific AI exception coverage is not established by those rows.

### Jutsu construction and authored resource commands

Donor first-four packed owner/selector words are
`00010015,002A0015,00010015,002B0015`; NA2 Jiraiya's are
`00A60053,00A60053,00010053,00A70053`. Configured donor selectors 42/43
name `2jrycha0/1.ccs` and map to BATTLE resources 27/28; NA2 selectors
166/167 name `2jrwcha0/1.ccs` and map to BTL resources 170/171.

| Jutsu resource | Factory / concrete initialization | Verified class |
| --- | --- | --- |
| NUN4 27 | `jutsu_factory_jry000_resource27`, BATTLE `0x0074D5E0`; allocate `0x880`, `jutsu_jry000_construct` at `0x00791F70`, interface at `+0x100` uses `0x00601860` | `ccSkillJRY000`, RTTI `0x00862E10` → name `0x00862DF0` |
| NUN4 28 | `jutsu_factory_nrv001_resource28`, BATTLE `0x0074D608`; allocate `0x8B0`, shared `naruto_form_rasengan_construct` at `0x007AD1E0`, interface at `+0x100` uses `0x005FDAA0` | `ccSkillNRV001`, RTTI `0x008624A0` → name `0x00862480` |
| NA2 170 | `skill_factory_jrw000`, BTL `0x007757B0`; allocate `0x1110`, common `skill_tyo_base_construct` at `0x00797250`, then interface `+0x110` uses `0x005E4030` | `ccSkillJRW000`, RTTI `0x008CEC48` → name `0x008BB738` |
| NA2 171 | `skill_factory_jrw001`, BTL `0x0077592C`; allocate `0x1190`, `skill_jrw001_construct` at `0x0084D690`, interface `+0x110` uses `0x005E51B0` | `ccSkillJRW001`, derived from `ccSkillNRV001`; sets input-control byte `+0x1134 = 1` |

Donor `jutsu_jry000_update` (`BATTLE 0x00792110`) maintains two phases
with two helper positions per phase, using
`jutsu_jry000_phase_position_parameters` (`0x0084B180`). It activates
and clears linked-motion queries through
`jutsu_jry000_activate_linked_motion / jutsu_jry000_clear_linked_motion`
(`0x00792CD0 / 0x00792D50`). Its linked-contact callback
`jutsu_jry000_linked_contact_response` (`0x00793210`) emits particle and
ground effects through `jutsu_jry000_emit_contact_effects`
(`0x00792DC0`) and can assign partner motion values 30/15 and source
response 7. The particle descriptor at `0x00577250` selects cache index
0, built by `battle_initialize_particle_resources` (`0x003158D0`) from
`particle` / `EFF_e0xpar00` at `0x00576C00`. In `CMN/PARTICLE.CCS`,
typed effect row 64 binds texture row 65 `TEX_e0xpar00`, which binds
palette row 154 `CLT_e0xpar00`. The emitter copies its `0x38`-byte
descriptor and the selected `0x20`-byte force records at `0x00577A00`
through `particle_emitter_setup` (`0x0034BFD0`). It is constructed by
`battle_particle_create` (`0x0039C1B0`) and activated by
`battle_particle_activate` (`0x0039C0F0`).

The optional contact-ground effect is pool ID `0x37`, not effect-resource
index `0x37`. `battle_acquire_ground_effect` (`0x00302120`) translates
it through `0x005C3BA4` to resource `0x31`; descriptor
`0x00575638` binds `effect0x` / `ANM_e0x_zaku_00`.
The preceding manager-effect request uses resource 0,
`effect0x` / `ANM_e0x_hit_99`, through
`transient_bind_effect_resource` (`0x002DBD70`). Particle activation is
forwarded by `battle_start_particle` (`0x002D4F00`).

The shared donor NRV001 class explicitly branches on resource 28 in setup,
update and damage methods. `jutsu_nrv001_update_hand_anchor`
(`BATTLE 0x007ADDF0`) requires `OBJ_2cmn00t0 r hand` from the bound scene.
Resource-aware code is evidence against assuming every instance of that
class behaves alike.

`jutsu_nrv001_select_resource_descriptor` (`BATTLE 0x007B1430`)
selects `jiraiya_rasengan_resource_descriptor` (`0x0084C0B0`) for
resource 28. `jutsu_nrv001_bind_resource_descriptor` (`0x007B19D0`)
publishes it at `+0x720`: six attacker motion entries at `0x0084C080`,
one receiver motion at resident `0x006088A4`, four effect names at
`0x0084C0A0`, and scalar 1.2. The attacker array is
`{null, ANM_pjrycha11, ANM_pjrycha12, ANM_pjrycha13,
ANM_pjrycha14, ANM_pjrycha15}`; the receiver uses `ANM_pjrycha20`.
The four `ANM_ejrycha11a/b/c/d` effects are typed animation rows
10/30/45/55 in `2JRYCHA1`; the concrete updater and final-effect binder
retain them through handles `+0x73C/+0x748/+0x754/+0x760`.

That binding also constructs the retained emitter `+0x76C` from
`rasengan_particle_emitter_descriptor` (`0x00578C90`) and force records
`0x00578CD0/0x00578CF0`. Before activation, resource 28 overrides its
particle choice to 36. `jiraiya_rasengan_particle_choice`
(`0x00576E40`) aliases choice 1, `particle` / `CMP_e0xleaf01`, and selects
`CLT_e0xleaf01c2`. Its typed `PARTICLE` chain is composition 51 →
object 52 → model 53, material 55 → texture 56 → default palette 140;
the selected alternate palette is row 142. The initializer's cache
stride is `0x10`; cached runtime choices have stride 8.

The result-7 branch of `jutsu_nrv001_contact_resolution`
(`BATTLE 0x007AEB00`) allocates a `0x520`-byte
`ccSkillPlayerBlowWatch` helper: `skill_player_blow_construct`
(`0x0075B9C0`), then interface `+0x50` = `0x00604C10`, typeinfo
`skill_player_blow_watch_rtti` (`0x00863380`). It binds the existing
receiver scene, copies receiver position/motion, sets lifetime 90 and
registers handle `+0x730`. Its initialize/update/destructor at
`0x00772710/0x00772850/0x00772530` manage the watched fighter, stage
placement and side masks; the destructor restores fighter control and
destroys its scene. This is a shared helper dependency, with no new
character-specific provider requested by the inspected creation path.
`jutsu_nrv001_end_contact_phase` (`0x007B02B0`) releases auxiliary effect
handles through `jutsu_nrv001_release_auxiliary_effects` (`0x007B0360`)
and the retained common sound token; `jutsu_nrv001_finish_retained_effects`
(`0x007B1D20`) finishes the three ongoing main effects.

The NA2 derived class's byte `+0x1134 = 1` enables the final branch of
`skill_nrv_family_control_dispatch` (`BTL 0x007D2CF0`): allocate and
enable its input-event object at `+0x144`, clear four counters and set
`+0x150 = 1`. The NUN4 counterpart,
`jutsu_nrv001_control_dispatch` (`BATTLE 0x007B0780`), ends after
descriptor dispatch, participant motion reset and clearing its private
`+0x880` block; it has no corresponding final input-event allocation.
This is a checked concrete control-path difference, independent of the
shared Rasengan name.

The English ordinary-jutsu titles are established by their own initializer,
not by nearby strings. `jiraiya_jutsu0_bind_display_record`
(`0x005E733C`) binds selector 42's row `0x00573F88` to action 1;
the following initializer binds selector 43 to action 3.
`fighter_authored_action_static_initialize` (`0x005DA4A0`) installs
action display pointers `0x00494CEC/0x00494DB4` from
`0x00437AB0/0x00437AB4`: **Ninja Art: Needle Jizo**
(`0x00595330`) and **Rasengan** (`0x005939B0`). NA2's corresponding
action pointers at `0x0056910C/0x005691B4` select
`蝦蟇ドス斬` (`0x00568F00`) and `螺旋丸` (`0x0040C9C0`).
Thus the first selected jutsu differs in title and concrete actor; the
second retains the Rasengan identity with different resource-aware code.

The read-only typed section walks of both body files and all four jutsu
files reached terminator 5. Selected `0x0108` command payloads are:

| File / animation | Target record | Command words |
| --- | ---: | --- |
| NUN4 `2JRYCHA0`, `ANM_pjrycha00`, row 144 | 2 | `0x8003, 0x11B` |
| NUN4 `2JRYCHA1`, `ANM_pjrycha10`, row 125 | 124 | `0x8003, 0x11C` |
| NA2 `2JRWCHA0`, `ANM_pjrwcha00`, row 75 | 74 | `0x8003, 0x1AA` |
| NA2 `2JRWCHA1`, `ANM_pjrwcha10`, row 125 | 124 | `0x8003, 0x1AB` |

NA2 `ANM_pjrwcha01` additionally emits resource command `0x1AA` and
control values `1,2,10`; its provider contains
`BIN_skldamoffs_2jrwcha0`. Neither donor jutsu file contains a `0x2400`
blob. The walks identify these selected commands and local wrappers,
not complete input admission or every typed reference.

### File families and checked providers

Complete input hashes are recorded under
[Jiraiya comparison inputs](../../../game/files/file_identities.md#jiraiya-comparison-inputs).
The four presentation/body families and two jutsu providers are:

| Family | NUN4 / NA2 file | NUN4 / NA2 `ANM_` directory-name count |
| --- | --- | ---: |
| Presentation body | `PL/1JRYBOD1` / `PL/1JRWBOD1` | 0 / 0 |
| Battle body | `PL/2JRYBOD1` / `PL/2JRWBOD1` | 109 / 110 |
| First jutsu | `PL/2JRYCHA0` / `PL/2JRWCHA0` | 1 / 8 |
| Second jutsu | `PL/2JRYCHA1` / `PL/2JRWCHA1` | 13 / 12 |
| End-demo eye/body animation | `3EYE/3JRY3EYE` / `3EYE/3JRW3EYE` | 2 / 2 |
| Name portrait | `3EYE/3JRY3PCT` / `3EYE/3JRW3PCT` | 0 / 0 |

The donor body and first jutsu have 34 marked `2cmn` directory rows each;
the second jutsu has 35 marked rows including `TEX_e0xwave15`.
All exact namespace/name keys occur in NA2 `CMN/2CMNBOD1` and
`CMN/EFFECT0X`, as applicable. Donor body wrapper 29 targets marked
ponytail record 30; wrapper 53 targets marked right-hand record 54.
Those are `0x0A00` dependencies used by the inspected code, beyond a
filename resemblance. `ccs_parse_scene_object` (`0x001B5DD0`) establishes
the model field; common ponytail row 30 and right-hand row 54 select models
1331 and 1350 with zero parts. They provide transform anchors, rather than
a ponytail or hand mesh through those particular common models.

The battle body row 3928 `OBJ_2jry00t0 body` selects model 3991;
material 3992 `MAT_clut` selects texture 3993 `TEX_2jrybody`, with palette
4010. The presentation body's row 66 `OBJ_1jry00t0 body` selects model
189; material 190 selects texture 191 `TEX_1jrybody`, with palette 193.
Its eye material 118 `MAT_jryeye2` selects texture 119 `TEX_1jryeye1`
and palette 196. These field meanings are checked in `ccs_parse_model`
(`0x001B41E0`), `ccs_parse_material` (`0x001B6D10`) and
`ccs_parse_image_block` (`0x001B7590`). All 66 marked end-demo rows have
matching keys in the donor's `1JRYBOD1`. Full containers retain the authored
geometry, animation tracks and subordinate resources; the selected chains
above do not establish equivalence of donor and native visual data.

The streamed `PLVOICE.AFS` subarchive for donor ID 21 is outer member 20,
offset 4,450,304, size 350,208, with 20 populated physical members.
The first ten filename rows are `PL21_088,090,091,265,289,293,298,299,302,312`;
the other ten store `plv`. NA2 ID 83 uses outer member 82, offset
17,940,480, size 579,584, with 41 dense physical members. The recorded
names do not establish dialogue meaning. Their exact cue-to-member
correspondence is established through the resident Jiraiya cue list and
archive descriptor in the audio document.
Compact voice uses a separate SNDDATA bank, as established in
[Jiraiya compact voice](#voice).

## Ultimate Jutsu and effects

**Own-game code/data observations:** this checks NUN4 Jiraiya ID 21 (`jry`)
against retail NA2 Jiraiya ID 83 (`jrw`). NUN4
`jiraiya_local_ultimate_jutsu_records` (`SLUS_218.62 0x00607CF0`) is
`{count 3, indices 50,51,52}`; its default row at `0x00583C7A` is 50.
NA2's list at `0x006044F0` is `{3,188,189,190}`, with default 188
at `0x005AFE56`.

The NUN4 getters consume their own locale-selected `0x10`-byte records,
not NA2's `0x14`-byte representation. These are the complete three-record
metadata values for each checked character. NUN4 rows are in `TEXTENG.BIN`;
NA2 rows are resident.

| Character / row / address | Authored skill | Category | Class / signed cost tier | Intro selector | Post-effect | Damage percent |
| --- | ---: | ---: | --- | ---: | ---: | ---: |
| NUN4 Jiraiya 50, `0x0086FE30` | `0x01` | 2 | 3 / 1 | `0x86` | `0xFFFF` | 0 |
| NUN4 Jiraiya 51, `0x0086FE40` | `0x34` | 3 | 3 / 2 | `0x2F` | `0xFFFF` | 45 |
| NUN4 Jiraiya 52, `0x0086FE50` | `0x35` | 1 | 3 / 1 | `0x30` | `0xFFFF` | 35 |
| NA2 Jiraiya 188, `0x005AFAF0` | `0x9B` | 2 | 3 / 0 | `0xA2` | `0xFFFF` | 25 |
| NA2 Jiraiya 189, `0x005AFB04` | `0x9C` | 3 | 3 / 1 | `0xA3` | `0xFFFF` | 45 |
| NA2 Jiraiya 190, `0x005AFB18` | `0x99` | 1 | 3 / 2 | `0xA4` | `0xFFFF` | 35 |

`jutsu_record_classify_playability` (`NUN4 0x003CC6E0`) classifies
authored skill 1 as reversal. Thus the checked Jiraiya default is the
reversal record. `english_text_static_initialize` (`TEXTENG.BIN`,
`0x00899480`) installs the three display pointers from
`0x0086A94C/0x0086A944/0x0086A948`: **Gamabunta Summon**, **Fire Style:
Flame Rasengan**, and **Double Rapid Rasengan** at
`0x00873F40/0x00873F00/0x00873F20`, respectively.
Decoding the SINF row titles through the own-game
`sp_skill_relocate_request_table` rule gives `豪炎螺旋丸` for authored
`0x34` and `双迅螺旋丸` for `0x35`. NA2's direct record-name pointers
give `火遁・豪炎螺旋丸`, `双迅螺旋丸` and `火遁・消し幕が原`,
respectively. Gamabunta's concrete controller and stage resources are recorded
in [Jiraiya cinematic resources](#cinematics).

NUN4 `character_to_transformed` (`0x00326300`) and
`character_to_base` (`0x00326520`) contain no Jiraiya pair. The complete
NA2 form map likewise has no pair for ID 83. All six checked UJ rows have
post-effect `0xFFFF`. These observations establish no linked Jiraiya fighter
form in those paths; they do not exclude a parameter-changing power state.
NA2's controller association at `0x005C1FC8` is `{effect 0x56, count 1}`;
its trigger at `0x005C1C9C` has presentation selector `0x1F` and flags
`0x10`.

NUN4's Jiraiya trigger flags at `0x00592305` are likewise `0x10`, its
event selector at `0x0059236A` is `-1`, and the controller association at
`0x005924C8` is `{effect 0x21, count 1}`. `awakening_dispatch`
(`0x001F4B80`) uses `fighter_action_progress_gate` (`0x0020F8B0`) for
this ordinary flags-`0x10` path. `input_sector_widen_state_b`
(`0x001F4240`) requests the associated timed effect and sets fighter
`+0x63` bit `0x20`, which selects the category-1 UJ tier. It contains no
Jiraiya-specific branch.

The donor effect `0x21` record at `0x00571A1C` has lifetime 600, flags 2,
and seven consecutive factors `1.5,1.25,1.25,1.25,1.25,1,1`; NA2 effect
`0x56` at `0x005A0434` has the same lifetime, flags and seven factors in
its own layout. The donor effect-class mapping is 1. `fighter_apply_timed_effect`
(`0x002CF220`) inserts the effect into the fighter's timed list;
`fighter_update_timed_effects` (`0x002CEF50`) advances it through
`timed_effect_tick` (`0x002CE2F0`) and removes expired nodes through
`fighter_remove_timed_effect` (`0x002CE600`). The removal routine can
defer removal to lifetime 1 during its matching action-state gate. This is
a timed parameter state, with no linked Jiraiya fighter-form ID in the
checked form maps.

`awakening_reconcile_marker` (`0x001F4690`) checks the current fighter's
associated effect list. Jiraiya takes its ordinary branch: while effect
`0x21` is present it retains the marker; when absent it clears `+0x63`
bit `0x20`. `awakening_dispatch` reaches this on an unsuppressed marked
pass. The common effect's virtual expiry callback is
`timed_effect_expiry_noop` (`0x002CE420`); marker cleanup is performed by
the later reconciliation pass, rather than that callback.

The cinematic request pairs and their providers are owned by
[Jiraiya cinematic resources](#cinematics);
their frame damage weights and sound cues by
[Jiraiya compact voice](#voice).

## Cinematics

This bounded comparison concerns NUN4 Jiraiya ID 21 (`jry`), with retail
NA2 Jiraiya ID 83 (`jrw`) as the metadata comparison in
[Jiraiya Ultimate Jutsu selection](#ultimate-jutsu-and-effects).
The donor's normal authored skills are `0x34/0x35`; global metadata row
indices 51/52 are distinct from those authored skill numbers.

NUN4 `sp_skill_relocate_request_table` (`SLUS_218.62 0x0032D440`)
decodes the own-game SINF request representation from `STRMCMN.CCS`.
The checked payload begins at decompressed offset `0x348C`, has
`0x14`-byte request rows and 146 rows, and lacks NA2's appearance-row
pointer at request `+0x14`. `sp_skill_build_requests` (`0x00330590`)
consumes the selected main path, extra count and stream count separately.

| Authored skill / decoded title | Resident main path | Stream path | Extra resident / stream counts |
| --- | --- | --- | --- |
| `0x34`, `豪炎螺旋丸` | `str/d21_20e.ccs` | `str/d21_20.ccs` | 0 / 1 |
| `0x35`, `双迅螺旋丸` | `str/d21_30e.ccs` | `str/d21_30.ccs` | 0 / 1 |

The source directory records establish these provider relationships:

| Donor container | Marked directory rows | Checked providers |
| --- | ---: | --- |
| `D21_20` | 211 | Exact keys all present across `D21_20E`, `1JRYBOD1`, `1CMNBOD1` and common effects. Names include `1jry` body/eye/mouth, `1cmn` defender objects and `e21` scene/effect families. |
| `D21_20E` | 1 | `#c\1jry\tex\1jrybody.bmp` / `TEX_1jrybody` matches `1JRYBOD1`. |
| `D21_30` | 284 | Exact keys all present across `D21_30E`, `1JRYBOD1`, `1CMNBOD1` and common effects. Additional namespaces include `e00`, `e63` and `e67`. |
| `D21_30E` | 1 | `#e\0x\tex\sampling00.bmp` / `TEX_sampling00`, directory row 19, is locally filled. |

The last entry is not an absent bitmap provider: `D21_30E` contains a
`0x0300` block for record 19 at decompressed offset `0xBB00`, with flags
`0x21`, zero palette/group and zero pixel words. Own-game
`ccs_parse_image_block` (`NUN4 0x001B7590`) admits target runtime zero/4
without a namespace-marker gate; flag `0x20` chooses the `0x50`-byte
`sampling_texture_chunk_construct` path, then publishes type `0x0300`.
The namespace's authored marker therefore does not imply that another
container must supply ordinary pixels.

The opponent-substitution table decoded by
`sp_skill_opponent_stream_override` (`0x00330340`) has defender groups
9 and 76. Their authored skill selectors are `0x57`, and
`0x05/0x0D/0x1C/0x20/0x25/0x48/0x80/0x57`, respectively; neither
Jiraiya skill `0x34/0x35` matches. Both therefore retain the request pairs
above through this consumer.

`sp_skill_palette_substitution_descriptors` gives skill `0x34` one entry
at `0x005799B0` → `0x00607900` → `0x005CE5F0`; skill `0x35` at
`0x005799B8` has zero entries. The first descriptor selects provider
`1jrybod1`, target `EXT_2jhnd00t0 body` and `CLT_1jrybodyc1` for
`sp_skill_apply_authored_palettes` (`0x0032DB20`). The adjacent fourth
string is `CLT_1jrybodyc2`; that routine consumes the first three fields.
The two selected `sp_skill_frame_scripts` pointers at `0x005795C8` are
zero, so neither selects a resident operation-1/2/3 command script.

The streams retain their own camera commands and auxiliary blobs:

| Stream | Damage-position blob | Filter blob |
| --- | --- | --- |
| `D21_20` | `BIN_damoffs_d21_20`, payload 2,364 bytes; `_damOffs`, version `0x100`, five common thresholds and 78 defender variants | `BIN_strfilter_d21_20`, payload 960 bytes; `CCFM`, version `0x200` |
| `D21_30` | `BIN_damoffs_d21_30`, payload 1,896 bytes; `_damOffs`, version `0x100`, four common thresholds and 78 defender variants | `BIN_strfilter_d21_30`, payload 11,376 bytes; `CCFM`, version `0x200` |

`D21_20` contains the typed `CAM_camera01` resource, directory row 915,
at decompressed offset `0x12D50`; `D21_30` has the same camera name at
row 891 / offset `0x15D44`. These resources are consumed through the
[NUN4 cinematic callbacks](ultimate_jutsu.md#ordinary-cinematic-requests-and-callbacks),
including position and filter setup; they are not metadata damage rows.
The resident audio/damage rows are identified in
[Jiraiya compact voice](#voice).

### Gamabunta Summon controller

The selected authored-ID-1 route uses `jiraiya_reversal_definition`
(`BATTLE.BIN 0x00859CF0`), `{entry 2, character 21, stage 20, option 0}`,
and `STAGE/KTYS_BNT.CCS`. `jiraiya_reversal_construct`
(`0x00736970`) builds a `0x8F0`-byte `ccSumGamabunta` object with
vtable `0x005F0510` on the common controller base. Its descriptor is
`jiraiya_reversal_descriptor` (`0x00858840`).

`jiraiya_reversal_initialize` (`0x00736CE0`) positions the stage on the
attacker's side, binds Gamabunta and Jiraiya animation players, requests
the `CMP_xshadow` resource from `BATTLEGAUGE.CCS`, initializes four
held particle emitters and sets charge thresholds 35/54.
The gauge shadow is a checked typed chain: composition 303 → object
304 → model 305; material 307 → texture 308 → palette 388.
`jiraiya_reversal_bind_animations` (`0x007371B0`) binds the
`ANM_4bnt*` and `ANM_4jry*` arrays, with Jiraiya substitutions at
indices 4 and 8; `ANM_4jryact12` is bound only when the actual initiating
fighter ID is 21. Special bindings include `ANM_4bntrdy1`,
`ANM_4bntact12`, `ANM_4bntact04` and `ANM_bnttpd00`.

`jiraiya_reversal_update` (`0x00738840`) dispatches its four concrete
states. `jiraiya_reversal_release_charge` (`0x007389B0`) chooses
state 1 or 2 at the two thresholds. The attack states own different
descriptors and behavior:

| Descriptor offset / state | Base damage fraction | Authored repeat limit | Reaction | Concrete attack |
| --- | ---: | ---: | --- | --- |
| `+0x0C`, state 3 | 0.02 | 3 | `0x10` | Body contact during animation frames 43..47; distant contacts can select reaction `0x3E` |
| `+0x38`, state 1 | 0.035 | 1 | `0x10` | Two independently managed projectile players; contact and ground/expiry cleanup |
| `+0x64`, state 2 | 0.05 | 15 | `0x1C` | Timed area effect, with its own animation and collision interval |

`reversal_bind_hit_descriptor` (`0x00748E80`) creates a synthetic action
from those fields, including the controller's damage multiplier;
`reversal_game_deliver_hit` (`0x00748F50`) applies the common hit path. These
values describe admitted attack descriptors, not a guaranteed aggregate
damage total. They are independent of metadata row 50's zero damage and
the two cinematic arrays.

The concrete descendants include
`jiraiya_reversal_spawn_projectile` (`0x00738A80`),
`jiraiya_reversal_projectile_contact` (`0x00738FA0`),
`jiraiya_reversal_update_area_effect` (`0x007395C0`), and the attack
updates at `0x00739960/0x0073A040/0x0073A270`.
`jiraiya_reversal_destroy_fields` (`0x00736A10`) releases both main
animation players, both projectile records, the shadow, retained models,
four emitters and the owned stage provider. Shared stage transition,
input, camera and exit behavior is owned by
[the authored-ID-1 route](ultimate_jutsu.md#separate-authored-id-1-route).

The four held emitter descriptors at `0x008442F0`, `0x00844328`,
`0x00844360` and `0x00844398` select particle cache indices 60/60/13/16;
the attack emitter
at `0x008443D0` selects 19. The own-game cache initializer resolves 13
to `effect0x` / `EFF_e0xsmok03`, 16 to `particle` / `EFF_e0xsmok07`,
and 19 to `particle` / `EFF_e0xsmok11`. Index 60 aliases resource 11,
`effect0x` / `EFF_e0ybom01`, with its `CLT_e0ybom01` palette selection.
Projectile ground/expiry cleanup requests ground pool `0x3F`, which maps
through `0x005C3BC4` to effect-resource `0x39`,
`effect0x` / `ANM_e0x_dokan_00`, from descriptor `0x005756F8`.

The typed sprite chains are `EFFECT0X` effect 1261 → texture 2341 →
palette 2763 (`e0xsmok03`), effect 1734 → texture 271 → palette 2823
(`e0ybom01`), and `PARTICLE` effect 88 → texture 89 → palette 175
(`e0xsmok07`), effect 94 → texture 95 → palette 177 (`e0xsmok11`).
These are local typed resources in the named providers, separately from
the cache alias and ground-effect animation.

`KTYS_BNT` has 26 typed animation resources, including the complete
Gamabunta/Jiraiya arrays and the special bindings above, `ANM_bnttpd00`,
three `ANM_s10befe*` sequences and `ANM_stalig00`. Its 34 marked common
skeleton records match `CMN/2CMNBOD1` by exact namespace/name key.
The provider census also checks typed resources behind all marked body,
jutsu, end-demo, stage and main-stream keys; none is left as a
directory-name-only match in the selected donor provider set.
The stage, gauge, common-effect and particle providers accompany the
controller; the two ordinary cinematic pairs do not contain this stage.

## Voice

The checked characters are **NUN4 Jiraiya ID 21 (`jry`)** and
**retail NA2 Jiraiya ID 83 (`jrw`)**. Their SNDDATA descriptor selections
are separate from the physical PLVOICE subarchives inventoried in
[Jiraiya character assets](#records-moves-and-assets).

| Checked bank | Descriptor address | Header offset / bytes | Sample offset / bytes |
| --- | --- | --- | --- |
| NUN4 English, set 0 | `SLUS_218.62:jiraiya_compact_bank_english`, `0x0043576C` | `0x009D8800 / 0x13B0` | `0x009DA000 / 0x7D030` |
| NUN4 Japanese, set 1 | `SLUS_218.62:jiraiya_compact_bank_japanese`, `0x00435B14` | `0x01DA2800 / 0x13B0` | `0x01DA4000 / 0x61B20` |
| NA2 Jiraiya | `SLPS_258.37`, `0x003FDC14` | `0x01396000 / 0xF60` | `0x01397000 / 0x45CE0` |

Offsets in this table identify clean `DATA/SNDDATA.BIN` ranges, not EE
runtime addresses. Applying the established
[compact synthesizer lookup](../../session/battle_audio.md#compact-program-to-vag-lookup) to these
exact headers gives:

| Program / key | NUN4 Sset / Smpl / Vagi | NUN4 English / Japanese sample offsets | NA2 Sset / Smpl / Vagi | NA2 sample offset |
| --- | --- | --- | --- | --- |
| 0 / `0x3C` | 0 / 0 / 13 | `0x00A0DCC0 / 0x01DC24D0` | 0 / 0 / 3 | `0x013A00E0` |
| 26 / `0x3C` | 26 / 26 / 39 | `0x00A52B10 / 0x01E00C60` | 23 / 23 / 28 | `0x013D8670` |
| 27 / `0x3C` | 27 / 27 / 19 | `0x00A18160 / 0x01DCC3F0` | Prog entry missing | None through this lookup |
| 37 / `0x3C` | 30 / 30 / 23 | `0x00A27540 / 0x01DD9950` | Not compared | Not compared |

Every listed candidate has split keys `12..119`, Sset and Smpl velocity
`1..127`, and sample rate 22,050. The donor's ID-21 event-list pointer pair
at `0x004366C0` is base/base (`0x00591DD0` twice), with 33 event selectors.
Event 0 selects control/program 0; event `0x18` selects 26. Its event
`0x19` selects control 27, whose signed program byte is `-1`, so it is
disabled even though Prog entry 27 exists in the donor bank. The sample
table establishes stored lookup candidates, not spoken content, guaranteed
admission or bank-wide equivalence.

NUN4 Jiraiya's authored cinematic skills `0x34/0x35` bind resident
`jiraiya_cinematic_audio_descriptor_34/_35`
(`0x005CD650 / 0x005CD658`), containing 124/92 eight-byte rows at
`jiraiya_cinematic_audio_rows_34/_35`
(`0x005C8E60 / 0x005C9240`). The first skill's enabled sound cues are
frame 134 → 15 and 195 → 18; the second's are 85 → 12 and 185 → 15.
Each array's unsigned damage weights sum to 32,768; every chakra weight
is zero. `sp_skill_play_frame` (`NUN4 0x0032F200`) consumes weights as
fractions over 32,768 and emits cues through
`audio_request_cinematic_cue` (`0x001D7360`), whose ordinary route uses
the compact controls and selected participant bank. The separate mode-6
callee, `audio_request_compact_cinematic_cue_mode6` (`0x001D7590`), also selects compact
voice rather than a streamed PLVOICE member.

The metadata intro selectors `0x86/0x2F/0x30` for donor Jiraiya are
recorded in [Awakening](#ultimate-jutsu-and-effects).
`jutsu_presentation_update` (`0x00377730`) and the authored-ID-1
presentation request these through `audio_request_sound_member`
(`0x001D9FC0`), family 0 / bank 9 / slot 0. The bank descriptor at
`0x00435E58` selects the 272-member SOUND.AFS outer member 9 and adds
136 to the logical member in language setting 1. The NA2 counterparts
use SOUND outer member 7 and their own intro selectors.

| Selected intro | NUN4 setting-0 member / file offset / bytes | NUN4 setting-1 member / file offset / bytes | NA2 member / file offset / bytes |
| --- | --- | --- | --- |
| Gamabunta / first selected tier | 134 / `0x158F4800` / 20,860 | 270 / `0x15B13000` / 13,913 | 162 / `0x08490000` / 21,035 |
| Flame Rasengan / second selected tier | 47 / `0x15757000` / 14,334 | 183 / `0x159BF800` / 13,760 | 163 / `0x08495800` / 43,218 |
| Double Rapid Rasengan / third selected tier | 48 / `0x1575A800` / 35,584 | 184 / `0x159C3000` / 28,923 | 164 / `0x084A0800` / 18,974 |

This aligns selected tiers, not spoken content: NA2's three selected
move identities differ as recorded in Awakening. Gamabunta's controller
also uses logical SOUND bank-6 members 20..23 through its four presentation
phases. Descriptor `0x00435E40` has 56 members and language increment 28:

| Logical member | Setting-0 file offset / bytes | Setting-1 physical member / file offset / bytes |
| ---: | --- | --- |
| 20 | `0x14A9E000` / 19,669 | 48 / `0x14B19800` / 22,612 |
| 21 | `0x14AA3000` / 20,039 | 49 / `0x14B1F800` / 19,043 |
| 22 | `0x14AA8000` / 30,834 | 50 / `0x14B24800` / 36,602 |
| 23 | `0x14AB0000` / 29,309 | 51 / `0x14B2D800` / 27,498 |

The dialogue path is separate. `audio_queue_player_voice`
(`0x001D46F0`) scans `jiraiya_streamed_voice_cue_list`
(`0x004350B0`, selected by pointer `0x00435534`) and queues the matching
ordinal. `audio_dispatch_pending_voice` (`0x001D45F0`) requests archive
family 3. `jiraiya_streamed_voice_archive_descriptor` (`0x00436280`)
selects Jiraiya's PLVOICE outer member 20, count 20, language increment
10. Thus this complete checked cue list maps to the physical members below:

| Logical cue / ordinal | Setting-0 file offset / bytes | Setting-1 file offset / bytes |
| --- | --- | --- |
| 88 / 0 | `0x0043F000` / 23,375 | `0x0046D000` / 19,185 |
| 90 / 1 | `0x00445000` / 8,181 | `0x00472000` / 5,635 |
| 91 / 2 | `0x00447000` / 18,431 | `0x00473800` / 11,761 |
| 265 / 3 | `0x0044B800` / 12,756 | `0x00476800` / 11,315 |
| 289 / 4 | `0x0044F000` / 18,939 | `0x00479800` / 17,180 |
| 293 / 5 | `0x00454000` / 24,324 | `0x0047E000` / 16,043 |
| 298 / 6 | `0x0045A000` / 13,493 | `0x00482000` / 13,930 |
| 299 / 7 | `0x0045D800` / 17,278 | `0x00485800` / 16,247 |
| 302 / 8 | `0x00462000` / 15,555 | `0x00489800` / 15,152 |
| 312 / 9 | `0x00466000` / 27,321 | `0x0048D800` / 23,655 |

All offsets in these streamed tables are absolute clean-file offsets in
SOUND.AFS or PLVOICE.AFS, respectively. Archive identities are recorded in
[file identities](../../../game/files/file_identities.md#jiraiya-comparison-inputs).
`jutsu_request_participant_dialogue` (`BATTLE 0x0074B640`) chooses a cue
from `jutsu_dialogue_cue_row` (`0x0074BA60`) and queues it or passes the
actual fighter identity and slot to the producer. Exact cue-to-member
selection is established; semantic equivalence of recordings between games
is not inferred from filenames or member positions.

`jutsu_initialize_resource_binding` (`BATTLE 0x00768D90`) stores the
translated resource index at owner `+0x54C`, so the Jiraiya cue rows are
resource 27/28 at `jiraiya_jutsu_dialogue_cues` (`0x0085A0C8`):
`{88,89,88,88}` and `{90,91,91,-1}`. Cue 89 has no entry in the complete
Jiraiya cue list; the producer therefore queues member `-1` for it.
Resource 28 also requests compact cue selector `0x1F` at state-1 frame 5
through `jutsu_nrv001_update` (`0x007AE3D0`), separately from dialogue.
`jutsu_request_participant_compact_cue` (`0x0074B740`) reads the actual
fighter's row through `jutsu_participant_compact_cue_row` (`0x0074B840`).
Jiraiya ID 21's pointer pair at `0x00845430` selects
`jiraiya_jutsu_compact_cue_row` (`0x0085A4F0`) in both cases: selector
31 reads control 37 (`0x25`) at `0x0085A52E`. Its control row at
`0x00433DA8` enables program 37, whose stored lookup is included above.
This selector is distinct from both the compact control and PLVOICE cue.
During the same state, every fourth owner frame requests common effect
cue `0x4B` through `audio_request_common_effect_cue_with_velocity`
(`0x001D8B00`). Its eight-byte common row at `0x00434528` selects
program 69, independently of Jiraiya's compact voice bank.
`audio_load_common_bank` (`0x001DAE70`) selects
`audio_common_bank_descriptor` (`0x00435660`): SNDDATA header offset
0, length `0x2EB0`, and sample length `0x7B330`. At key `0x3C`,
program 69 selects Sset 32 / Smpl 32 / Vagi 73, sample-region offset
`0x65D00`, rate 22,050 Hz. The split admits keys 12..119 and both
velocity intervals are 1..127. This is a shared effect-bank dependency,
separate from the per-character and streamed dialogue banks.

Rasengan phase 1 also requests common cue 59 / program 59 through
`audio_request_common_or_mode_effect_cue` (`0x001D88B0`); contact entry
requests common cue 39 / program 39 through
`audio_start_tracked_common_effect_cue` (`0x001D95F0`), retains its token
at owner `+0x868`, and releases it through
`audio_release_tracked_common_effect_cue` (`0x001D9880`). At key 60,
their common-bank Sset / Smpl / Vagi selections are 82 / 82 / 71 and
62 / 62 / 83, with sample-region offsets `0x60000` and `0x760A0`,
rates 22,050 and 8,000 Hz. The checked split/velocity ranges agree with
the common program-69 ranges above. Contact result 7 separately requests
fighter compact control `0x29` through `battle_voice_control_by_id`
(`0x001D5CC0`); row `0x00433DC8` has signed program `-1`, so that
request emits no compact voice packet.

The shared `ccSkillPlayerBlowWatch` initializer requests mode cue
`0x1005`. `audio_common_or_mode_effect_cue_row` (`0x001D6600`)
selects combat mode-0 row `0x004345D8`, program 5. The mode descriptors
`audio_battle_bank_english/_japanese` (`0x00435DC0/0x00435DE4`) select
SNDDATA header offsets `0x7E800/0x1595000`, each length `0x2040`,
sample lengths `0x5B060/0x61F40`. At key 60, both select Sset 40 /
Smpl 40 / Vagi 21; sample-region offsets are `0x1C0F0/0x1E1A0`,
rates 11,025 / 22,050 Hz. Keys 12..119 and velocities 1..127 are admitted
by the stored split/sample records. These shared banks are separate
dependencies from the fighter voice bank.
