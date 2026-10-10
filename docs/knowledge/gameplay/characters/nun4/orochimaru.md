# Orochimaru: NUN4 donor

## Research coverage

Established for NUN4 Orochimaru 9 (`orc`) against NA2 Orochimaru 89 (`orw`):
differing move arrays, sword and helper mechanisms, callbacks and both
ordinary-jutsu classes; titles and input admission; complete selected stored
typed graphs; first- and second-jutsu actors; the entry-4 Manda reversal's state,
input, CPU, contact, damage and teardown; compact and streamed voices; and the
indexed AI, support, availability and presentation services.
Open: shared-effect dispatch arms, Manda stage sampling, foreign matrix/cache
lifetime, ordinary-film payload bindings, shared streamed voice admission,
category execution, authored motion and contact windows, Ultimate Jutsu titles
and ordinary power consumers.

Names come from `@annotations/NUN4` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [NUN3 and NUN4 characters](../nun3_nun4_characters.md).

## Records, moves and assets

Checked identities are NUN4 Orochimaru **ID 9 (`orc`)**, resident
`SLUS_218.62` and `BATTLE.BIN`, and retail NA2 Orochimaru **ID 89
(`0x59`, `orw`)**, resident `SLPS_258.37` and `BTL.BIN`.
NA2 ID 9 is a Classic Naruto filler record, not this comparison's destination.

### Definition and construction

| Root | NUN4 ID 9 | NA2 ID 89 |
| --- | --- | --- |
| Character record | `orochimaru_character_record`, `0x00460C80` | `orochimaru_character_record`, `0x005857A0` |
| Actions / phase rows / animation-name slots | 47 / 180 / 156 | 48 / 187 / 138 |
| Authored arrays | `orochimaru_actions`, `0x0045FA20`; `orochimaru_rows`, `0x0045C4B0`; `orochimaru_animation_names`, `0x0045C240` | `orochimaru_actions`, `0x005847D0`; `orochimaru_rows`, `0x00580EA0`; `orochimaru_animation_names`, `0x00580A30` |
| Factory / constructor / allocation | `orochimaru_create`, `0x0024A840`; `orochimaru_construct`, `0x0024A890`; `0x5910` bytes | `fighter_id_089_create`, `0x002F3B40`; `fighter_id_089_construct`, `0x002F3B90`; `0x5900` bytes |
| Descriptor / vtable | `orochimaru_character_descriptor`, `0x00460D60`; `orochimaru_vtable`, `0x005EBA30` | `0x00585880` / `0x005DA280` |
| Palette / texture / model / anchor tables | `orochimaru_palette_names`, `0x0045BF80`; `orochimaru_texture_names`, `0x0045C0E8`; `orochimaru_model_names`, `0x0045C128`; `orochimaru_anchor_name`, `0x0045C168` | Same annotated names at `0x00580150/0x005802B8/0x005802F8/0x00580338` |

The checked physical-parameter words at record `+0x58..+0xDC` agree
byte-for-byte. Native defaults include HP 105.263158, durability 1.05,
incoming-damage factor 0.95, offense 1.15, and health/chakra recovery 0.8.
This agreement excludes the records' different pointers, arrays and controllers.

The donor constructor installs its vtable and descriptor, supplies the common
base constructor, and publishes the record's name/action-related pointers at
fighter `+0xED0/+0x1140/+0x239C`. It sets record `+0x50/+0x54` to one
named handle at `orochimaru_named_handle_descriptor` (`0x0045C190`): common
right hand `OBJ_2cmn00t0 r hand` and local model `MDL_2orc00t0 ktn0`.
The handle list is at fighter `+0x940`. Its destructor releases common state
and frees the object for a positive destruction flag.

Native `orochimaru_initialize_helpers` (`0x002F3F90`) binds eleven animations from
`0x005803E0` and creates three `0x120`-byte compound players, in helper
records at `+0x5880 + i*0x20`. Native vtable slots `+0x24/+0x28/+0x2C`
select `orochimaru_update_helpers` (`0x002F3D80`),
`orochimaru_draw_helpers` (`0x002F3DC0`), and
`fighter_scene_array_attack_pass` (`0x002F3E70`); the donor uses shared
methods there.
`fighter_id_089_destroy` (`0x002F3C60`) destroys each nonnull player in
those three helper records and clears its pointer before common fighter
cleanup/destruction. Thus the three native helper owners have an explicit
release path, separate from either ordinary-jutsu actor.
Both classes have an AI wrapper at vtable `+0x1C`: donor
`orochimaru_update` (`0x0024A9E0`) and native `orochimaru_update_ai`
(`0x002F3D40`) gate their own overlay AI tick on control bits 5..8 and
return zero. Donor `orochimaru_ai_character_values` (`0x00853C04`) stores
two signed per-tick values, separately from `orochimaru_ai_flags`
(`0x008538D9`). Their consumers and bounded numeric exceptions belong to
[Orochimaru AI services](#nun4-orochimaru-and-na2-orochimaru-ai-services).
Availability and selector ownership belong to
[Orochimaru admission](#orochimaru-fighter-and-jutsu-admission);
support relationships to
[Orochimaru support selection](#orochimaru-indexed-support-selection);
and selector artwork to
[Orochimaru presentation](#nun4-and-na2-orochimaru-presentation).

### Complete authored animation correspondence

Names below omit `ANM_porc` or `ANM_porw`. Ranges use decimal action
indices, and list phase animation suffixes in authored order. They are not
physical input commands or proof that every stored chain is reachable.

| Donor action / sequence | Native action / sequence |
| --- | --- |
| 0..9: jutsu, UJ and common control slots | 0..9: same roles; different jutsu rows described below; donor action 6 also repeats `spl20` under condition 6 |
| 10 `pna20/22`; 11 `pna00/02`; 12 `pna40/42` | 10 `jaa50/52`; 11 `jaa20/22`; 12 `jaa00/02` |
| 13 `pna30/32`; 14 `pna10/12`; 15 `kca00/02` | 13 `jaa50/52`; 14 `jaa20/22`; 15 `jaa00/02` |
| 16 `pnb00/02`; 17 `pnb10/12`; 18 `pnb20/22` | 16 `jaa50/52`; 17 `jaa20/22`; 18 `jaa00/02` |
| 19..20: common motion slots | 19..20: corresponding slots |
| 21 `pnc00/02`; 22 `pnc10/12`; 23 `kcn00/02` | 21 `pja00/02`; 22 `pja10/12`; 23 `pja20/22` |
| 24 `pnc20/22`; 25 `pnc90/92`; 26 `snk00/02` | 24 `snk00/02`; 25 `snk10/12`; 26 `snk20/22` |
| 27 `kcn10/11/12`; 28 `pnc50/52`; 29 `pnc60/62` | 27 `pja30/32`; 28 `pja40/42`; 29 `pja50/52` |
| 30 `pnc70/72`; 31 `pnc80/81/82`; 32 `pnc30/32`; 33 `pnc40/42` | 30 `pja60/62`; 31 `snk30/32`; 32 `snk40/42`; 33 `snk50/52`; 34 `pja70/72`; 35 `pja80/82` |
| 34 `hol00/01`; 35 `hol02/03` | 36 `hol00/01`; 37 `hol02/03` |
| 36 `ktn10/12`; 37 `ktn20/22`; 38 `ktn30/32`; 39 `pna80/82`; 40 `pna90/92`; 41 `ktn00/02` | 38 `jaa00/02`; 39 `jaa10/12`; 40 `jaa20/22`; 41 `jaa30/32`; 42 `jaa40/42` |
| 42 `hla00/01`; 43 `hla02/03` | 43 `hla00/01`; 44 `hla02/03` |
| 44 `pna50/52`; 45 `pna60/62`; 46 `pna70/72` | 45 `jaa50/52`; 46 `jaa60/62`; 47 `jaa70/72` |

These are authored families, not an assertion that differently positioned
rows implement equivalent attacks. Donor action stride is `0x64`, native
`0x54`; donor has five locale display pointers rather than native's one.
Packed owner/selector and final row index consequently occupy different offsets.
The callback-dependent sword and hit paths are owned by
[Character callbacks](#callbacks).

### Orochimaru ordinary-jutsu display bindings

NUN4 `fighter_authored_action_static_initialize` (`0x005DA4A0`) writes
action 1's English slot at `0x0045FA8C` through
`orochimaru_jutsu0_bind_english_title` (`0x005DBA8C`), using pointer
`0x004377F0` to literal `0x00594370`. Action 3's corresponding store
`orochimaru_jutsu1_bind_english_title` (`0x005DBAC4`) fills `0x0045FB54`
from `0x004377F4`, literal `0x00594390`. These display slots are zero
in the stored actions before initialization.

| Exact fighter / configured selector / action | Display title | Other display slots |
| --- | --- | --- |
| NUN4 Orochimaru 9 / 18 / 1 | **Snake Tongue Sucks In** | `Drain du Serpent` at `0x00599FA0`, pointer `0x00438820` |
| NUN4 Orochimaru 9 / 19 / 3 | **Snake Sword: Sky Blade** | `Épée Céleste Serpent` at `0x00599FC0`, pointer `0x00438824` |
| NA2 Orochimaru 89 / 178 / 1 | `陀演呂迦`, ruby `だえんろか` | Single Shift-JIS display pointer, literal `0x00584630` |
| NA2 Orochimaru 89 / 179 / 3 | `邪蛇蜿蜒`, ruby `じゃじゃえんえん` | Single Shift-JIS display pointer, literal `0x00584650` |

Each donor action's `+0x0C..+0x18` slots receive the same French pointer.
`orochimaru_jutsu0_bind_display_record` (`0x005E715C`) loads ID 9's
definition record at `0x0057452C`, takes its action base `+0x2C`, adds
`0x64`, and writes selector 18's action pointer `0x00573E6C`. The store
at `0x005E716C` uses `+0x12C` for selector 19 at `0x00573E78`.
`jutsu_selector_display_name` (`0x002D1310`) returns that record's
`+0x08 + 4*ui_language_index()` display pointer. These selector rows'
filename fields independently select `2orccha0/1.ccs`.

Native `orochimaru_jutsu0_bind_display_record` (`0x005D9174`) loads
ID 89's record from `0x005A2BCC`, adds `0x54` to its action base and
writes selector 178's pointer at `0x005A28B0`. Its following store at
`0x005D9180` uses `+0xFC` for selector 179 at `0x005A28B8`.
`jutsu_selector_title` (`0x00307C80`) returns the selected record's
single pointer at `+0x08`. This is an ordinary-jutsu title join;
the separate UJ metadata and its titles are not these action records.
MCP does not expose the selector-initializer tails as functions; the
loads/additions/stores above were checked from MCP memory bytes.

### Orochimaru input admission and phase rows

The following comparison reads all 47 donor and 48 native action records,
and all 180/187 phase rows. It establishes conditional selection paths,
not unconditional execution or equal animation motion.
NUN4 action fields `category/flags/continuation/signature/cost/row` are at
`+0x20/+0x24/+0x28/+0x2C/+0x30/+0x60`; native fields are sixteen
bytes earlier. `Nun4ActionRecord` is applied with size `0x64`.

Donor `input_bindings_reset` (`0x0023E330`) supplies
`default_battle_bindings` (`0x004375D0`): Triangle, Circle, Cross,
Square, L1, R1, L2, R2. `input_build_logical_mask` (`0x0023E9C0`)
turns a Circle press into logical `0x1000`; Up/Down sectors produce
`0x10/0x20`, opponent direction/opposite `0x40/0x80`, and facing
half-planes `0x100/0x200`. `input_history_advance` (`0x0023F5A0`)
computes opponent angle at input `+0x88` from both positions and camera,
and facing angle at `+0x84` from fighter yaw and camera.
The checked sector jump-table arms were read as MCP bytes because its
decompiler omits those arms. The same checked native interpretation is
owned by [Action commands](../../combat/action_commands.md#logical-mask).

Donor `command_tables_evaluate` (`0x0023F210`) uses two two-step
direction-press groups: Down, Down at `0x004375E0` and Up, Up at
`0x00437600`. Logical `0x400/0x800` becomes signature `0x10000/0x20000`
and replaces the single-direction context. These are history matches,
not simultaneous held directions. With the default bindings, selected
native/donor jutsu pairs and the admission gates satisfied:

| Input / route | NUN4 Orochimaru 9 | NA2 Orochimaru 89 |
| --- | --- | --- |
| Down, Down, Circle; signature `0x00110012` | Action 1 directly selects Snake Tongue Sucks In, cost 3 | Action 3 directly selects 邪蛇蜿蜒, cost 3 |
| Up, Up, Circle; signature `0x00120012` | Startup action 2, cost 3; outcome continuation 3 selects Snake Sword: Sky Blade, cost 0 | Startup action 0, cost 3; outcome continuation 1 selects 陀演呂迦, cost 0 |

Both startup continuations have signature `0x08000012` and classification
byte 1 (`+0x29` donor, `+0x19` native). That signature is absent from
the direct button translation. `action_stage_outcome_continuation`
(`0x002241B0` donor, `0x0023B280` native) requires current outcome 1
and the opponent's recovered source record to equal this current action;
`action_validate_candidate` (`0x0022DFE0` / `0x00244190`) also requires
matching sections for this classification and returns 3 for immediate
dispatch. The startup's affordability check uses startup plus follower
cost, therefore 3 in both pairs. Direct actor actions instead pass the
grounded/context, status/effect, affordability and input-override gates.
This does not establish the actor's internal contact or lifetime behavior.

Ordinary selection uses `action_select_from_signature`
(`0x00223110` donor / `0x0023A390` native) and
`action_select_record` (`0x002220F0` / `0x00239530`). Both require no
queued chain, a valid selector mode, no paired interception and an admitted
entry state. Action lock rejects entry. Major 8 with category `0xC0000`
also rejects entry. The donor major-5 accepted substates are `0x59/0x5A`,
versus native `0x5B/0x5C`; major-6 cursor gates are donor `0x5E >= 3`
and `0x5D >= 8`, versus native `0x60 >= 3` and `0x5F >= 8`.
These numbers must be interpreted in their own game's state layout.

In mode 0, continuations below require their stored prior action index.
The current phase must permit staging through payload bit `0x10`;
execution of a pending ordinary action requires zero exchange roles and
payload bit `0x20`. Immediate reselection is separately available for
motion class 3/stage 2 from update 5 of the category-2 motion action.
Candidate normalization and scan order make the first two basic-ground
continuations accept any direction; later forks retain their specific
direction tests. All action indices below are decimal.

| Circle route after admission | NUN4 ID 9 actions | NA2 ID 89 actions |
| --- | --- | --- |
| Ground basic opener and two further presses | `21 → 22 → 23` | `21 → 22 → 23` |
| Branch from 23: Up / facing half-plane / Down / opposite facing half-plane | `24 / 25 / 26 / 27` | `24 / 25 / 26 / 27` |
| Ground Up opener and continuation presses | `28 → 29` | `28 → 29 → 30` |
| Ground Down opener and continuation presses | `30 → 31` | `31 → 32 → 33`; action 32 signature `0x00100111` allows either groundedness, unlike 33's ground-only `0x00100112` |
| Ground opponent-direction opener and continuation | `32 → 33` | `34 → 35`; native opener category `0x200`, donor category 1 |
| Ground opposite-opponent direction throw / outcome follower | `34 / 35` | `36 / 37` |
| Air Up opener and continuation presses | `36 → 37 → 38` | `38 → 39` |
| Air Down opener and continuation presses | `39 → 40 → 41` | `40 → 41 → 42` |
| Air basic opener and continuation presses | `44 → 45 → 46` | `45 → 46 → 47` |
| Air opposite-opponent direction throw / outcome follower | `42 / 43` | `43 / 44` |

The two throw followers have `0x08000011/0x08000014` signatures;
they use the same source-record/outcome continuation mechanism, not a
second direct Circle command. Extra Hit slots 10..18 are selected through
`action_stage_chain_slot` (`0x002227E0` / `0x00239B00`), not as ordinary
air openers. `action_selector_mode` (`0x00222E20` / `0x0023A0D0`) selects
mode 1 only with current flags `0x380`, chainable phase bit `0x10` and
no jutsu category `0xF00000`; attached effects and exchange roles can
select other modes. The two versions' stored non-UJ action flags supply
mode-1 groups in different rows:

| Group in current flags | NUN4 ID 9 action indices | NA2 ID 89 action indices |
| --- | --- | --- |
| `0x80` | 25, 33, 35, 43, 46 | 25, 37 |
| `0x100` | 24, 29, 38 | 24 |
| `0x200` | 31, 41 | 33 |

`action_build_chain_masks` (`0x0022A660` / `0x00240C40`) maps those
groups to candidate flags `0x400/0x800/0x1000`, respectively, with
category `0x1000`. Modes 2/3 use exchange groups and their own gates.
Thus matching Circle signatures do not establish matching Extra Hit
eligibility. The table gives stored eligibility groups; remaining contact,
effect and exchange prerequisites can still prevent selection.

`phase_event_completion` (`BATTLE 0x006FC140` / `BTL 0x0071F160`)
has matching checked condition semantics for this comparison:
`-16` animation end, `-17` grounded, `-18` descending or grounded,
`-19` end or grounded, `-20` end and grounded, positive secondary cursor,
zero hold and other negatives relative jumps on animation end.
`phase_select_animation` (`BATTLE 0x006FC650`) publishes start/rate at
the secondary zero event; rate units are /256. This agrees with the
[native phase contract](../../combat/combat_action_execution.md#shared-phase-progression).

Concrete differences include donor action 6's extra `spl20` phase
`{condition 6,start -1,rate 256}`; native omits it. Donor Air-Up 36
repeats its opening animation for 8 cursor units at start -1; native 38
repeats for 1 with a different continuation payload. Donor Air-Down 39
repeats for 12 at start -1; native 40 has no repeated phase.
Native ground 24 instead splits `snk02` into conditions 7, 9 and
animation end with starts 0, 7 and 16. Native ground 26 uses condition
25/rate 352 followed by animation end/start 26; donor 26 has two
animation-end rows at rate 256. Donor direct-startup rates are 256;
native first-jutsu startup `chb00` uses 176. All 47/48 row walks stay
within their 180/187 arrays and reach an animation-slot -1 sentinel;
held entry phases still need their execution owners to advance them.

These observations leave animation payload/motion and exact active contact
windows independent of input admission. Category-specific approach/throw
and Extra Hit descendants, interruption and every external effect writer
are not fully closed by this comparison. Character callback overrides
remain owned by the linked callback document.

### Jutsu records and concrete actors

| Action | NUN4 packed owner/selector; category; cost; animation slots | NA2 packed owner/selector; category; cost; animation slots |
| ---: | --- | --- |
| 0 | `00010009`; 0; 0; none | `00B20059`; `0x10000`; 3; `porwchb00/02` |
| 1 | `00120009`; `0x40000`; 3; `porccha00` | `00B20059`; `0x40000`; 0; `porwcha00` |
| 2 | `00130009`; `0x20000`; 3; `porcchb10/12` | `00010059`; 0; 0; none |
| 3 | `00130009`; `0x80000`; 0; `porccha10` | `00B30059`; `0x80000`; 3; `porwcha10` |

Donor configured selectors 18/19 map to BATTLE resources 22/23 and
`2orccha0/1.ccs`; native selectors 178/179 map to resources **182/183**
and `2orwcha0/1.ccs`. Retained NA2 resources 22/23 and their engine names
are not the native ID-89 jutsu. Resource IDs, configured selectors and packed
authored commands remain separate domains.

| Actor root | Donor | Native ID 89 |
| --- | --- | --- |
| First factory arm | `orochimaru_jutsu0_factory_case`, `0x0074D0D8`; allocate `0xD50`, construct `0x007E4600` | `orochimaru_jutsu0_factory_case`, `0x00775684`; allocate `0x1110`, common constructor `0x00797250` |
| First concrete interface | `orochimaru_jutsu0_vtable`, `0x005F59B0`, at `+0x100`; RTTI `ccSkillFOR000` | `0x005E4A30`, at `+0x110`; RTTI `ccSkillORW000` |
| Second factory arm | `orochimaru_jutsu1_factory_case`, `0x0074D100`; allocate `0x830`, construct `0x00784170` | `orochimaru_jutsu1_factory_case`, `0x00775D2C`; allocate `0xFF0`, common constructor `0x00785410` |
| Second concrete interface | `orochimaru_jutsu1_vtable`, `0x00602990`, at `+0x100`; RTTI `ccSkillORO001` | `0x005E1490`, at `+0x110`; RTTI `ccSkillORW001` |

The retained donor `FOR000` class name does not assign its resource to another
character: factory 22 and its literal `porc` animations establish this binding.
`orochimaru_jutsu0_construct` owns five `0x50`-byte collision/query shapes,
two compound animation players at `+0x8D0/+0xA60`, and private history
at `+0xBF0`. `orochimaru_jutsu0_initialize` (`0x007E49A0`) binds
`ANM_porccha01`, `ANM_porccha01_1`, `ANM_porctan2`, `ANM_porccha03`.

#### Donor first jutsu: contact, drain and owned helpers

`orochimaru_jutsu0_process` (`0x007E4D30`) enables the initial query group
at source animation frames 8..16 and disables it after frame 16.
`orochimaru_jutsu0_accepted_event` (`0x007E5530`, interface `+0x1E0`)
checks the target's `+0x94A`
counter: zero clears the source participant, reports condition `0x0E`,
requests participant dialogue index 0 and enters private phase 2; the other
arm clears the query and reports condition `0x13`. Phase-1 animation
completion also enters phase 2. Phase 2 continues while its counter is below
64 and the shared interruption query is clear; phase 3 restores participant
state, and its completion requests actor finish.

Let `D` be the initiating fighter's current action float `+0x34`. Each
phase-2 drain update directly calls the defender HP-debit service
(`0x0020D280`, flags `0x122`) with `0.6*D/63`, then `fighter_hp_add`
(`0x0020CE00`) for the initiating fighter with half that amount and both
feedback flags zero. The latter honors its own fighter-state gates and HP
ceiling, so this call is not proof of an unconditional HP increase.
`orochimaru_jutsu0_charge_input` (`0x007E6920`) uses actor `+0x12C` bit 0
for a valid CPU participant, or the initiating side's new-input mask and
configured primary action mask for a human participant. Accepted input adds
the stored `+0x72C` increment to charge `+0x724`, initially 0.6. When the
new charge is at most 1.2 it also debits `increment*D`, halved above 1.0,
and requests half as much HP addition. The two consecutive comparisons in
the disassembly exclude the apparent clamp arm: charge can exceed 1.2,
after which extra charge damage is skipped. The base drain continues.

`orochimaru_jutsu0_update_sword_player` (`0x007E6C80`) and
`orochimaru_jutsu0_update_target_player` (`0x007E7190`) follow the initiating
right hand and target head, with timer-controlled position, rotation and
distance scaling. `orochimaru_jutsu0_adjust_target_model` (`0x007E7470`)
has actual-target-ID branches for 50, 53/35 and 4. The history is sixteen
inline records; `orochimaru_jutsu0_emit_history` (`0x007E4330`) and its
update allocate no separate history owner. Two inline participant-effect
helpers at `+0xD28/+0xD38` periodically request effect `0x40`, while
phase 2 owns the held effect at `+0xD14`. Effect descriptor roots are
`0x0084E960/0x0084E9A0/0x0084E9C0`; their complete typed provider graphs
are outside this executable closure. Named anchors include
`OBJ_gpos_eng00`, `OBJ_hit_dummy01..05` and the common spine.
Every fifteen drain updates the process requests positional SFX `0x4F`
and reports fighter condition `0x0E`; the condition call is not audio.
Phase-0 counter 13 requests positional SFX `0x16`. Dialogue and compact
cue domains are owned by [Battle audio](#voice).

`orochimaru_jutsu0_destroy` (`0x007E4720`) clears registration and target
state, releases input/camera/query state, clears the two participant-effect
helpers, checks the held effect's live registry identity before retiring it,
destroys the inline players and five query shapes, then delegates common
destruction. `skill_primary_destroy` (`0x0075F460`) unregisters the side,
destroys its five query helpers and scene owner; a positive concrete delete
flag frees the complete `0xD50` allocation.

#### Donor second jutsu: inherited paired-scene execution

`skill_combo_construct` (`0x00798CD0`) supplies the primary base and
embedded camera-player owner at `+0x720`. The concrete initializer
(`0x007843D0`) calls vtable `+0x26C`, which is
`skill_combo_bind_animations` (`0x0079B160`), rather than the empty method
at `+0x240`. It binds source names `{null, ANM_porccha11}` and target
name `{ANM_porccha12}` through `skill_primary_bind_participant_animations`
(`0x00760DF0`) in provider `+0x1C8`. It also retains the camera anchor
names `OBJ_camera` / `OBJ_camera_target` through interface `+0x0C`.
`skill_combo_initialize_camera_player` (`0x00798910`) looks up
`ANM_%c%c%c_camera` in that provider and creates an owned `0x120`-byte
compound player when the lookup succeeds. GP-relative names were checked
using NUN4's own entry-established GP `0x0060EF70`.

`skill_combo_prepare_participants` (`0x0079B260`) establishes paired
placement/facing, stage-update state and saved source/target transforms.
`skill_combo_begin` / `skill_combo_end` (`0x0079CA50/0x0079D2D0`) manage participant state
and restore the saved transforms under their linked-fighter gates.
`skill_combo_advance` (`0x0079D610`, slot `+0x128`) requests finish when
`skill_combo_is_complete` (`0x0079D740`, slot `+0x268`) finds source
completion and `+0x2A8 == +0x2A4-1`. `skill_combo_accepted_event`
(`0x0079DB40`, slot `+0x138`) presents its contact, updates shared combo
counters, pauses linked fighters and requests target compact selectors
9..17 for events 0..3/5. Event 10 instead sets a latch consumed by the
concrete empty `+0x240` method. Draw `+0xF8`, process `+0xFC` and
concrete finish `+0x250` are also empty. These empty callbacks do not
replace the inherited binding, advancement or submission methods.

`orochimaru_jutsu1_update` (`0x00784250`) scans **sixteen**
frame/compact-selector pairs at `0x0084AEF0`: `33:1, 45:2, 55:4, 65:5,
100:6, 130:7`, followed by ten `-1/-1` pairs. They request participant
compact cues, not action dispatch. Nine frame/SFX triples at `0x0084AE80`
are `15:0x0B/0x3C, 34:0x10/0x3C, 45:0x10/0x3C, 57:0x10/0x3C,
65:0x0A/0x3C, 73:0x13/0x3C, 95:0x1033/0x37, 110:0x1005/0x46,
155:0x16/0x3F` (frame:cue/key).

`orochimaru_jutsu1_emit_definition` (`0x00784440`, slot `+0x254`)
selects the facing-pair definition and shared side bank through
`0x00849FE4`. Resource 23 selects two `0x44`-byte rows at `0x0084616C`:
the first has category `0x80000`, response `0x26`, scalar `+0x28 = 1`
and repeat count 1; the second has response 2 and scalar zero. Submission
multiplies the selected scalar by the initiating current action `+0x34`.
`skill_combo_submit_record` (`0x00799F20`, slot `+0x190`) establishes
spine-based facing/spacing and delegates to `skill_primary_submit_record`
(`0x00762E80`). Response `0x26` takes its direct HP-debit arm with flags
`0x122`; other responses use the resident ordinary response route. A
positive target guard counter halves the scalar when record flag `0x800000`
is set. Authored scalar, response and submission gates therefore travel
together; this actor does not use Manda's synthetic action.

`skill_combo_field_override_start`, `skill_combo_field_override_end` and
`skill_combo_field_override_update`
(`0x0079DE50/0x0079E030/0x0079E0E0`, slots
`+0x244/+0x248/+0x24C`) retain, expire and release the paired field effect
and participant pause state. `orochimaru_jutsu1_destroy` (`0x007841B0`) releases
the embedded camera player through `skill_combo_player_destroy`
(`0x00798830`) and `skill_combo_player_release` (`0x007988A0`), then
the primary base; a positive delete flag frees `0x830` bytes.

#### Native ownership comparison

Native first-jutsu `linked_players_orw_setup` (BTL `0x0084E3A0`) binds
six `porwcha03..08` linked players. Its concrete destructor
`orochimaru_jutsu0_destroy` (`0x00872520`) delegates to
`linked_players_owner_destruct` (`0x007973A0`): release the `+0x10B4`
list, delete its private camera player at `+0xFFC`, then release primary
scene/registry storage and queries. `linked_players_release`
(`0x0079C1B0`) saves each node's next pointer before destroying and freeing
it. Native second-jutsu `orochimaru_jutsu1_update` (`0x00867760`) uses
states 0..2: source frame above 19 enters state 1; timer above 29 enters
state 2 and requests source animation index 1; target completion requests
finish. Its destructor (`0x00871320`) delegates directly to
`skill_base_destroy`, without the donor's embedded combo-camera owner.

### CCS providers

The donor presentation/body/jutsu files are `1ORCBOD1`, `2ORCBOD1`,
`2ORCCHA0/1`, `3ORC3EYE` and `3ORC3PCT`. The body has 119 named
animation directory entries; the two jutsu files have nine/six. All ten
sword-helper bone names occur locally in `2ORCBOD1`, including its
`2forn` bone hierarchy, shadow/model pairs, `MAT_2forneck`, and sword
compound `CMP_2orc00t0 ktn0`. Their prefixes do not request a separate
Fourth Hokage provider.

After normalizing the namespace marker, exact marked namespace/name lookup
against checked NA2 common providers finds zero absent keys among the
donor body's 34 and first jutsu's 35 marked rows. The second jutsu's 103
marked rows and `3ORC3EYE`'s 67 also resolve in the checked directory unions.
The complete stored typed graphs refine those unions: CHA1 requires common-1
and common-2; the eye requires `1ORCBOD1`. Model/material/image/palette,
controller and packed-animation edges resolve, including against native common
providers with identical decompressed bytes. Selected code-created effects,
geometry counts and precise remaining boundaries belong to
[Orochimaru typed providers](#typed-providers).
Complete-file identities belong to
[File identities](../../../game/files/file_identities.md#orochimaru-comparison-inputs).

## Callbacks

Checked characters are NUN4 ID 9 (`orc`) and NA2 ID 89 (`orw`). The donor
`orochimaru_callbacks` (`0x0045C220`) selects a no-op channel 2,
`orochimaru_channel3` (`0x0024B180`), `orochimaru_hit_response`
(`0x0024B7A0`) and `orochimaru_channel5` (`0x0024BA00`); the other slots
are null. Native `orochimaru_callbacks` (`0x00580410`) selects
`0x002F5730/0x002F5740/0x002F7890/0x002F7D50` in those four slots.
Action numbers here are hexadecimal and local to each class.

Donor channel 3 resets the named hand/sword handle on action 1. Its UJ
slots 4/5/6 request sound index `0x2C` and compact pseudo events 6/7/8 at
secondary events 6/8/7. Action `0x1B`, phase 1, event 9 requests voice
`0x14` and sound index `0x10`; event `0xB` requests sound index `0x23`.
Despite its name, `fighter_emit_effect_event` (`0x001EA6D0`) maps an
index through `0x00436890` to `sound_request_positional` (`0x001D9070`);
these calls do not select CCS effects.
Action `0x1F` phase 1 rewrites the current payload's four halfwords
`+0x56..+0x5C` to `0x3E/9/0x5F/3`; phase 0 uses
`0x35/0xFFFF/0x56/0xFFFF`. The same action's voice/sound events differ
between those phases. Actions `0x28/0x29`, phase 0, use the stored
partner outcome to smooth relative placement. These are code-owned changes
in addition to the authored phase rows.

Donor source hit response selects `0x3A/0x3B` for action `0x19` according
to the receiver's current response. For actions `0x1A/0x1B`, variants below
2 select response `0x36` with respective receiver factors
`1/0.125/1.25` and `1/0.5/1.5`; later variants select `0x31/0x2A`.
Action `0x1C` selects `0x31` with factor 0.5 or `0x30` with 0.35.
Action `0x20`, with contact bit `0x80` clear, selects `0x33` with
`1/0.5/0.25`. Movement writes occur only for response mode 2.
Native's inspected callback returns a different response set,
`{-1,0x2F,0x30,0x32,0x33,0x35,0x3D}`. Matching character names do not
establish matching hit response.

Donor channel 5, after node/state gates, calls
`orochimaru_update_sword_chain` (`0x0024AA20`). Its six checked floats at
fighter `+0xA50..+0xA64` are recorded as `Nun4OrochimaruSwordState`.
Action `0x23`, phase 0, event zero, and action `0x22`, phase 1, event
zero enable the chain with target extent zero and duration 5. Action
`0x22`, phase 0, event 9 sets target extent 600 and duration 6.
The helper smooths extent with the fighter's timing scalar and adjusts nine
consecutive segments using ten names in `orochimaru_sword_bone_names`
(`0x00460DB0`): `OBJ_2forn00t0 bone02/03/05/06/08/09/11/12/14/15`.
The query parameters at `+0xA60/+0xA64` enter segment queries; their broader
meaning is not assigned. All ten named nodes are local to the donor body.

Both versions modify the head transform for their own throw indices,
donor `0x22/0x23` versus native `0x24/0x25`. Native channel 5 additionally
  changes thigh transforms on its own actions `0x23/0x22/0x1B`.
The donor's sword-chain state and native's separately constructed helper
players are different mechanisms. The complete inherited/helper call graphs
and physical-input reachability remain outside this bounded comparison.

## Typed providers

Checked donor is **NUN4 Orochimaru ID 9 (`orc`)**, `SLUS_218.62` /
`BATTLE.BIN`; comparison is **retail NA2 Orochimaru ID 89 (`orw`)**,
`SLPS_258.37` / `BTL.BIN`. Inputs are original extracted CVM files.
The 23 selected complete-file hashes agree with the recorded
[input identities](../../../game/files/file_identities.md#orochimaru-comparison-inputs) and
the character comparison identities. Key matching removes only the leading
namespace ownership marker. A metadata carrier alone is not a typed provider.

### Stored graphs and geometry

Complete files were walked through actual model and texture payload consumption.
Edges include model-part materials, material/effect images, image palettes and
generated transfer groups, scene parents/models/shadows, wrapper targets,
compositions, nullable metadata controllers, generator/action-packet resources
and children, and packed animation targets including morph sources.
The graph starts from every stored typed definition.

| Donor input | External typed providers required by its stored graph |
| --- | --- |
| `PL/1ORCBOD1.CCS` | None |
| `PL/2ORCBOD1.CCS` | `CMN/2CMNBOD1.CCS` |
| `PL/2ORCCHA0.CCS` | `CMN/2CMNBOD1.CCS` |
| `PL/2ORCCHA1.CCS` | `CMN/2CMNBOD1.CCS`, `PL/1CMNBOD1.CCS` |
| `3EYE/3ORC3EYE.CCS` | `PL/1ORCBOD1.CCS` |
| `3EYE/3ORC3PCT.CCS` | None |

Every required edge resolves in these original unions. Substituting the checked
NA2 common-1/common-2 files leaves no absent donor typed key; their complete
decompressed bytes are identical between games. The second jutsu's common-1
graph does not require donor `1ORCBOD1`; the eye file does. The body-local
`2forn` neck/sword hierarchy remains local, including packed model 69/material 70.

The readers establish ordinary subtype 0, packed rigid/weighted subtype 2,
shadow subtype 4 and common-body property subtype 3 consumption:
`ccs_read_model_vertex_arrays` (`0x001B3CC0`),
`ccs_read_packed_rigid_part` (`0x001B2670`),
`ccs_read_packed_weighted_part` (`0x001B16E0`) and
`ccs_read_property_geometry_data` (`0x001CC740`). Palette-order bytes
begin at model payload `+0x1C`, with byte count at `+0x10`; preceding
colour/float fields are not palette entries. Donor battle model 5122 has
16 parts and 29 palette bytes.

| File | Nonempty ordinary / packed / shadow models |
| --- | --- |
| NUN4 `1ORCBOD1` | 4 / 1 / 17 |
| NUN4 `2ORCBOD1` | 1 / 6 / 32 |
| NUN4 `2ORCCHA0` | 3 / 1 / 20 |
| NUN4 `2ORCCHA1` | 2 / 0 / 0 |
| NUN4 `3ORC3EYE` | 1 / 0 / 0 |
| NUN4 `D09_20E`, `D09_30E` | 69 / 1 / 0; 51 / 2 / 0 |
| NUN4 `KTYS_MND` | 20 / 4 / 34 |
| NA2 `2ORWBOD1` | 22 / 9 / 91 |
| NA2 `2ORWCHA0`, `2ORWCHA1` | 10 / 1 / 16; 9 / 0 / 0 |

Zero-part bone models are excluded. Parsed geometry and keys do not establish
foreign matrix remapping, draw-cache equivalence or borrowed-provider lifetime.
Native `2ORWBOD1` and `2ORWCHA1` close with native common-2.
Native `2ORWCHA0` additionally uses its body for the `sej` child graph.
Its original union has one absent external key: row 444 `OBJ_2snwwhi01`,
under `#c\2snw\max\2snwwhi0.max`, targeted by wrappers 441/442.
That native provider/consumer boundary is not a donor graph gap.

### Packed commands and selected effect leaves

Complete command endpoints and typed vector/rotation/scalar curves were checked
in the selected body, jutsu, eye, common and stage files. No `0x0802/0x0803`
mesh-write command occurs in these selected animations or either ordinary
cinematic stream. Queued `0x0108` commands remain separate from stored edges.

| Donor file / target | Encoded kind / values |
| --- | --- |
| `2ORCBOD1`, `OBJ_eff_dummy_htn3` | `0x8002`: 35, 512, 513 |
| `2ORCCHA0`, `OBJ_eff_dummy_orccha0` | `0x8003`: 278 |
| `2ORCCHA1`, `OBJ_eff_dummy_htn3` | `0x8002`: 35 |
| `2ORCCHA1`, `OBJ_eff_dummy_orccha1` | `0x8003`: 279 |
| `2ORCCHA1`, `OBJ_eff_dummy_orccha11` | `0x8003`: 2, 5, 10 |

`fighter_deliver_animation_resource_command` (`0x001FB5A0`) forwards to
`battle_apply_animation_resource_command` (`0x002D4FE0`). Values 512/513
start/stop the side-selected attachment; start requires selector 0..3.
`attached_effect_initialize` (`0x002F73E0`) selects transient IDs
25/77/25/25 and particle resource 11 for even-index anchors.
All selected roots and image/palette descendants resolve within each game's
`CMN/EFFECT0X.CCS`:

| Selection | Typed root and leaves |
| --- | --- |
| Attachment selectors 0/2/3 | `EFF_e0xfire01` → `TEX_e0yfire00` → its palette |
| Selector 1, NUN4 | `ANM_e0x_bom_00` → `TEX_e0xfla01`, `TEX_e0xpar12`, `TEX_e0xbom04`, `TEX_e0xfla04` and their palettes |
| Selector 1, NA2 | Same animation name → `TEX_e0xcolor00`, `TEX_e0xwave08`, `TEX_e0ybom02` and their palettes |
| Anchor particle 11 | `EFF_e0ybom01` → `TEX_e0ybom01` → its palette |

The same animation name therefore does not establish matching presentation.
The attachment selector's producer is separate from this conditional leaf closure.

First-jutsu phase 2 (`BATTLE 0x007E5690`) supplies
`orochimaru_jutsu0_particle_definition` (`0x0084E960`): one choice,
catalog resource 65 (`0x00577010`), base 15 and palette variant 2.
This selects `EFFECT0X`'s `EFF_x001` → `TEX_x001` with `CLT_x001c2`.
Donor IDs are 2651/2652/2800; native IDs are 2459/2460/2618.
After excluding payload-local ID words, complete effect parameters, image
metadata/pixels and selected palette bytes agree. Participant effect `0x40`
sets material flags; it does not identify an additional CCS file.

`interaction_create_jutsu_from_command` (`BATTLE 0x0074CCF0`) maps
278/279 to resources 22/23. Values 2/5/10 instead use
`jutsu_active_primary_command_dispatch`, its checked side handle and virtual
`+0x138`. Resource 23's `skill_combo_accepted_event` (`0x0079DB40`)
invokes virtual `+0x258`, installed
`skill_combo_contact_presentation_except_event10` (`0x00838400`).
Event 10 bypasses contact presentation; events 2/5 reach
`skill_combo_present_contact_effect` (`0x0079D770`), whose table
`0x0085D600` selects `skill_combo_contact_events0to3_case`
(`0x0079D7B8`) and `skill_combo_contact_event5_case` (`0x0079D8A0`).
Both arms lie outside the mapped function body; GhidrAssist returns
“Function not found” for both. Their effect descendants remain open.

`battle_dispatch_shared_effect` (`0x002D9200`) similarly dispatches
command 35 through table `0x005C3200`, row `0x005C328C`, to
`shared_effect35_dispatch_case` (`0x002D9560`). That arm also lies
outside the mapped body and cannot be inspected through the available
function-code endpoint. Its selected provider remains open.

### Ordinary cinematic streams

Each donor `D09_20E/D09_20` or `D09_30E/D09_30` pair closes stored
external typed edges with donor `1ORCBOD1`, `1CMNBOD1`, `EFFECT0X`
and `STRMCMN`. Corresponding native pairs close with their own presentation/
common files. No additional `SHADE` edge is reached. All camera commands
`0x0502` have flags zero and 40-byte payloads: 391 target camera 1065
in both `D09_20` streams; 470 target donor 940/native 859 in `D09_30`.
Neither stream has queued `0x0108` or mesh-write commands.

There are also 103 directory-only targeted rows in each `D09_20` and 49
in each `D09_30`. They belong to ordinary local namespaces, not marked
external providers. `ccs_build_play_runtime` (`0x001A1520`) initially
snapshots their zero secondary pointer; transform/material/environment handlers
consume fields before returning for a missing target. `ccs_frame_tag_1801`
(`0x001B91B0`) uses the default projection controller for an absent target.
Later participant substitutions/local producers remain distinct from stored closure.

The streams' 20/27 morpher linked-name rows also lack typed models, but
`animation_morph_child_construct` (`0x001BE630`) creates the empty instance
without dereferencing that linked descriptor. Actual `0x1901` source IDs
resolve to typed models in the paired E file: `MDL_e09samp01a` for
`D09_20`; `MDL_e09snk00_b`, `MDL_e09ygm01b`, `MDL_e09ygm01c`
for `D09_30`. Unused linked-name rows are not missing external assets.

### Manda stage and code-selected effects

Manda's emitter definitions are distinct from transform/force/shape parameter
blocks. Every selected chain below resolves in the original providers:

| Emitter descriptor / selection | Typed provider |
| --- | --- |
| `0x00844568`, resource 80 / base 19 / variant 1 | `CMN/PARTICLE`: `EFF_e0xsmok11` → `TEX_e0xsmok11`, selected `CLT_e0xsmok11c1` |
| `0x008445A0`, initial resource 63 / base 15 | `CMN/EFFECT0X`: `EFF_x001` → `TEX_x001` → `CLT_x001` |
| Rising choice overrides | `KTYS_MND`: `EFF_4mndgmi0/1` → corresponding textures/palettes; `EFF_plane01` → `TEX_4kzmkaz0` → `CLT_4kzmkaz0` |
| Conditional rising animation | `EFFECT0X`: `ANM_e0x_par_07` → `MDL_e0xshim00` and morph source `MDL_e0xshim00_tgt` → `MAT_01 - default` → `TEX_sampling01` |
| `0x008445D8` / `0x00844610`, resource 19 | `PARTICLE`: smoke11 effect/image/default palette |

`orochimaru_reversal_start_rising_effects` (`0x0073DCA0`) binds the
fourth animation only when the published `effect0x.ccs` container exists;
`particle_choice_bind_animation` (`0x00348BC0`) changes choice kind to 2
and stores the selected descriptor. Auxiliary/travel selections come from
`orochimaru_reversal_recreate_auxiliary_effects` (`0x0073DAA0`) and
`orochimaru_reversal_start_travel_effects` (`0x0073E530`). The entire
decompressed `PARTICLE.CCS` is identical between NUN4 and NA2; shared
names alone do not establish that fact for `EFFECT0X`.

The complete stage graph still has three absent marked sampling targets,
under `#c\ktys\4mnd\max\emnd_smp0.max`: rows 782 `OBJ_emnd_smp0`,
784 `OBJ_emnd_smp0_trg1` and 788 `MDL_emnd_smp0_trg1`.
Wrappers 781/783 target the objects. Animation 787 `ANM_emnd_smp00`
has a typed `0x1902` track for controller 785/source 788 and seven scalar
keys at times 0/1/3/4/5/7/8; weight reaches 1 at time 4.
It is not an all-zero inactive track. Activation and source producer/binding
remain open; empty morpher linked-name row 786 is not another required provider.

`BLT_4mnd`, `BLT_bg`, `BLT_obj` are generated local transfer groups.
`texture_bind_or_create_transfer_group` (`0x0019F490`) creates/reuses the
nonzero image group and publishes type `0x1000`; these are not absent
external definitions. Stage sampling targets, mapped shared-effect arms,
later local participant bindings and matrix/cache lifetime remain the precise
independent limits of this static audit.

## Ultimate Jutsu and effects

Checked identities are NUN4 Orochimaru ID 9 (`orc`) and retail NA2
Orochimaru ID 89 (`orw`). NUN4 `orochimaru_awakening_flags`
(`0x005922F9`) is `0x10`; `awakening_dispatch` (`0x001F4B80`)
therefore admits its ordinary action-progress predicate. Its
`orochimaru_awakening_association` (`0x00592468`) stores effect `0x13`,
count 1. `input_sector_widen_state_b` (`0x001F4240`) inserts that effect
on the existing fighter, sets byte `+0x63` bit `0x20`, and requests
presentation event `0x1F` from `0x00592352`. ID 9 does not take a
replacement-identity branch in this entry body.

NA2's ID-89 association (`0x005C1FF8`) is effect `0x5D`, count 1;
its trigger row (`0x005C1CB4`) likewise stores event `0x1F` and flags
`0x10`. This is the native Sannin Mode effect. Donor
`orochimaru_ordinary_effect_definition` (`0x00571434`) and native
effect `0x5D` (`0x005A06F8`) have the same stored duration 600, flags 2,
and seven leading factors `1.5/1.25/1.25/1.25/1.25/1/1` after the
layout offset. This establishes the ordinary mode's identity-preserving
entry and selected stored parameters, not every later effect consumer,
cleanup path or visible behavior.

All three donor UJ records have effect `0xFFFF`, as do all four native
records listed in the
[Orochimaru UJ comparison](#cinematics).
None of those records requests a separate fighter form. The donor's
authored-skill-1 reversal instead uses the separate controller lifetime in
[NUN4 Ultimate Jutsu](ultimate_jutsu.md#separate-authored-id-1-route).

## Cinematics

Checked donor is NUN4 ID 9 (`orc`); native comparison is NA2 ID 89 (`orw`).
Donor `orochimaru_ultimate_jutsu_list` (`0x00607C98`) has count 3 and
records 18/19/20; default 18 is at `0x00583C62`. Native's same-named list
(`0x005ACF90`), selected by `0x005AD114`, has count 4 and records
206/207/208/209; default 206 is at `0x005AFE62`.

| Game / record / live address | Authored skill | Category / class / cost tier | Intro / effect / damage percent |
| --- | ---: | --- | --- |
| NUN4 18 / TEXTENG `0x0086FC30` | 22 | 2 / 3 / 0 | 19 / `0xFFFF` / 25 |
| NUN4 19 / TEXTENG `0x0086FC40` | 1 | 3 / 3 / 2 | 131 / `0xFFFF` / 0 |
| NUN4 20 / TEXTENG `0x0086FC50` | 23 | 1 / 3 / 1 | 20 / `0xFFFF` / 35 |
| NA2 206 / `0x005AFC58` | 169 | 2 / 3 / 0 | 174 / `0xFFFF` / 25 |
| NA2 207 / `0x005AFC6C` | 170 | 3 / 3 / 1 | 175 / `0xFFFF` / 45 |
| NA2 208 / `0x005AFC80` | 166 | 1 / 3 / 2 | 176 / `0xFFFF` / 35 |
| NA2 209 / `0x005AFC94` | 167 | 2 / 3 / 0 | 177 / `0xFFFF` / 30 |

Each native secondary intro is -1. Native has `0x14`-byte records versus
donor `0x10`; the donor display pointers are initialized by the locale
loader. Exact localized-title-to-record binding is not established here.
General category/tier consumers are owned by
[NUN4 Ultimate Jutsu](ultimate_jutsu.md#selection-and-metadata).

Clean SINF rows select the following paths:

| Game / skill | Decoded authored SINF title | Main / stream request |
| --- | --- | --- |
| NUN4 22 | `禁術　穢土封滅` | `str/d09_20e.ccs` / `str/d09_20.ccs` |
| NUN4 23 | `千影蛇絡` | `str/d09_30e.ccs` / `str/d09_30.ccs` |
| NA2 169 | `禁術・穢土封滅` | `str/d09_20e.ccs` / `str/d09_20.ccs` |
| NA2 170 | `潜影多蛇手` | `str/d09_30e.ccs` / `str/d09_30.ccs` |
| NA2 166 | `蟒蛇` | `str/d89_10e.ccs` / `str/d89_10.ccs` |
| NA2 167 | `二凪ノ草薙(大蛇丸)` | `str/d89_50e.ccs` / `str/d89_50.ccs` |

Authored titles use the checked second-byte complement decoding. These SINF
strings identify their skill rows; they do not establish each locale's final
display string. Native skill 167 has one appearance entry; donor rows have
no native appearance-count field.

Both selected donor rows have zero extra requests and one stream. Donor
skill 21's `d09_10` pair exists but is not selected by ID 9's local list;
record 19 executes authored skill 1 instead. Complete donor/native `D09`
files have different hashes, so identical paths do not establish byte or
scene equivalence. Identities are in
[File identities](../../../game/files/file_identities.md#orochimaru-comparison-inputs).

Exact marked namespace/name keys in donor `D09_20` (207) and `D09_30`
(219) resolve in their matching main file, donor `1ORCBOD1`, and checked
common providers. The main files' marked sampling keys also resolve in
their corresponding pair. Both streams name their own `BIN_damoffs_d09_*`
and `BIN_strfilter_d09_*`. Complete stored external typed graphs, camera
payloads, morph sources and command endpoints also close in these original
unions. Initially unbound local targets and later participant substitution remain
separate questions; exact counts and consumer boundaries belong to
[Orochimaru typed providers](#ordinary-cinematic-streams).
Resident hit/cue descriptors are owned by
[Battle audio](#voice).

### Reversal entry 4

`reversal_entry_for_character` (`BATTLE 0x007459C0`) returns entry 4
for ID 9 from `orochimaru_reversal_definition` (`0x00859D10`), raw
`{4,9,22,0}`. This selects `stage/ktys_mnd.ccs`, allocation `0x650`,
`reversal_manda_vtable` (`0x005F0470`) and retained class `ccSumManda`.
This is a separate interactive controller, not ordinary skill 21 or a
zero-damage ordinary cinematic. Its hit route does not use the cinematic
damage words above.

`orochimaru_reversal_construct` (`0x0073CE60`) uses the common controller
base and private state from `+0x370`. `orochimaru_reversal_initialize`
(`0x0073D330`) consumes `orochimaru_reversal_descriptor` (`0x00858D00`),
creates two `0x120`-byte players, and initializes the initiating model,
HUD, camera and placement. `orochimaru_reversal_set_state` (`0x0073E9D0`)
selects idle 0, rising attack 1, travel attack 2, body attack 3 and charge 4.
Incoming-contact reactions can select states 5..8. The nine paired animation
suffixes are `nut0/atc10/atc20/atc30/nxc0/dmg0/dmg1/dmg2/dmg2`;
the initiating model uses `nut0` instead of `nxc0` for state 4.
The checked resource contains 29 named animation directory entries.
`reversal_game_request_voice` uses family 6 and entry-4 cues 8..11;
these are not Orochimaru's PLVOICE member indices.

#### Owned presentation and contacts

`orochimaru_reversal_bind_animations` (`0x0073D570`) binds the paired
`ANM_4mnd*` / `ANM_4orc*` animations in stage container `+0xB4`, three
body variants `atc30/atc50/atc40`, return animations `atc22`, charge loop
`ANM_4mndchg0` and stationary player `ANM_4mndkaz0`. Shared
`reversal_game_bind_initiator_model` (`0x00747B20`) uses `2cmnbod1`,
`CMP_2cmn00t0 trall` and `OBJ_2cmn00t0 body`, attaches the ID-9 body
model from its indexed provider, and takes palettes from the initiating
fighter. The private scene owns its initiating player `+0xE0` and model
helpers `+0xE4/+0xE8`, Manda player `+0xDC`, stationary player `+0x3AC`,
and two `0xA0` models in allocated backing storage at `+0x614`, bound to
`CMP_4mnd00t0 loop`.

`orochimaru_reversal_initialize_contacts` (`0x0073E710`) creates the
base contact at `+0x2D0`, body contact `+0x320` in group `+0x60`, five
rising contacts at `+0x3D0+i*0x50` and two travel contacts at
`+0x560/+0x5B0` in group `+0x84`; private contacts start disabled.
`orochimaru_reversal_camera_anchor` (`0x0073E8C0`) uses
`OBJ_4mnd00t0 bone14`; `orochimaru_reversal_update_attached_player`
(`0x0073F230`) uses `OBJ_eff_dummy_orcpos0`;
travel uses bone16, and body contact uses bone15. `orochimaru_reversal_draw` (`0x0073EF50`)
includes the initiating player, stationary player only in state 1, the two
auxiliary models and shared HUD. `orochimaru_reversal_configure_draw_environment` (`0x0073F010`)
sets borrowed environment `+0xE0` to 1500 and byte `+0xE4` to `0x60`.
`reversal_game_initialize_presentation` (`0x00747900`) owns the HUD renderer,
sprites and camera helper. Its direct HUD providers are `battlegauge`
with `TEX_xicon03` / `TEX_xgauge`, and `gauge` with `TEX_xcommand`.

Held effect groups are `+0x618..+0x624`, `+0x3B0..+0x3BC` and
`+0x3C0/+0x3C4`. `orochimaru_reversal_start_rising_effects` (`0x0073DCA0`) binds stage names
`EFF_4mndgmi0`, `EFF_4mndgmi1`, `EFF_plane01`, scales contact radii
with charge, and conditionally binds `ANM_e0x_par_07` only when the
resident `effect0x.ccs` container exists. Direct descriptor roots are
`0x00844568/0x00844690` for auxiliary effects,
`0x008445A0/0x008446B0/0x008446D0/0x008446F0/0x00844770` for rising,
and `0x008445D8/0x00844710/0x00844730/0x00844610/0x00844750` for travel.
The emitter selections and full stored effect/model/material/image descendants
resolve in the original `PARTICLE`, `EFFECT0X` and stage files, including the
conditional animation's morph source. The parameter blocks listed beside the
emitter descriptors are not additional asset selectors. Exact chains and the
separate stage sampling gap belong to
[Manda typed providers](#manda-stage-and-code-selected-effects).

#### Attack windows and ordinary damage

`orochimaru_reversal_update_attacks` (`0x0073F770`) dispatches states
1/2/3/4 to rising/travel/body/charge callbacks. The three `0x2C`-byte
patterns in `orochimaru_reversal_descriptor` are:

| State / pattern address | State-count voice trigger | Authored damage scalar | Repeat/contact cap | Intermediate / final reaction | Final response multiplier |
| --- | ---: | ---: | ---: | --- | ---: |
| Body 3 / `0x00858D0C` | 4 | 0.035 | 2 | `0x02 / 0x10` | 8 |
| Rising 1 / `0x00858D38` | 4 | 0.045 | 10 | `0x01 / 0x10` | 12 |
| Travel 2 / `0x00858D64` | 2 | 0.06 | 20 | `0x10 / 0x10` | 12 |

`orochimaru_reversal_select_body_variant` (`0x0073F8D0`) uses
`abs(facing*1000 - opponentX)`: below 750 selects 0, below 1500 selects 1,
otherwise 2. `orochimaru_reversal_update_body_attack` (`0x00740180`)
uses start frames `{29,24,30}`, end frames `{38,36,37}` and effect frames
`{32,28,35}` for those variants, from resident tables
`0x006084B0/0x006084B8/0x006084C0`. It reads player `+0x98`, while the
rising/travel callbacks read animation cursor `+0xEC >> 8`.

`orochimaru_reversal_update_rising_attack` (`0x0073F970`) starts its effect group at frame 10 and
enables the five contacts at frames 10/16/22/28/34. After frame 64 it
retires the rising effects and disables all five. `orochimaru_reversal_position_rising_contacts`
(`0x0073E140`) follows the initiating model's common neck and a mirrored
radius-spaced chain. `orochimaru_reversal_update_travel_attack` (`0x0073FD10`) enables its first
contact at frame 20, the second at 78, and disables both at 112; each has
radius 540. It also updates defender placement/air state and consumes the
shared contact latch for presentation. Body, rising and travel therefore
have distinct contact ownership and frame sources.

`reversal_game_initialize_synthetic_hit` (`0x00747F90`) initializes action
`+0x170` through `action_initialize_default` (resident `0x001F7680`):
category 1, flags zero and final field `+0x60` zero. The pattern's
`+0x16` values in the table schedule state-count voice dispatch, not category.
`reversal_bind_hit_descriptor` (`0x00748E80`) fills that action
for synthetic source `+0x110`, sets damage `+0x34` from the selected
scalar, repeat `+0x3E` from the cap, response and auxiliary fields, and
resets contact counters. The active outgoing multiplier `+0x1D4` is 1.
`reversal_game_check_attack_contact` (`0x00749A50`) checks air-state,
pattern, group masks and cap; intermediate contacts use response multiplier
1, while the cap contact selects the final multiplier and reaction above.
It increments the contact count before delivery and sets the contact latch
even when delivery rejects the hit. `reversal_game_deliver_hit`
(`0x00748F50`) separately rejects finish state, defender status-bit 0 or
major state 6. Admitted hits enter the resident ordinary reaction route;
its damage consumer divides action `+0x34` by nonzero repeat `+0x3E`
before ordinary factors and HP gates. Authored scalars are consequently not
unconditional total HP loss. The exact resident route and gates are owned
by [NUN4 Ultimate Jutsu](ultimate_jutsu.md#separate-authored-id-1-route).

Manda also receives the opponent's ordinary contacts through
`reversal_game_receive_opponent_contact` (`0x007490A0`). Its side masks,
action/repeat admission and cooldown gate a controller-meter debit using
incoming action damage divided by repeat, multiplier `+0x1D8 = 0.75`
and meter factor `+0x54`. It increases the CPU cooldown and can select
reaction states 5..8 while idle or in reactions 5/6. This controller meter
is separate from the defender HP route. `reversal_game_report_initiator_condition`
(`0x00749F10`) forwards to the initiating fighter; it is not a voice request.

#### Input and CPU selection

`reversal_game_sample_input` (`0x00748A00`) reads the initiating side's
configured masks: a new secondary-mask press enters charge 4 and sets hold
`+0x38`; a primary-mask press enters body 3. Releasing the secondary mask
clears hold. `reversal_game_update_charge` (`0x00749F80`) advances charge,
requests common SFX at thirty-count intervals and pattern thresholds, and
automatically releases after count 59. Manda changes the first pattern
threshold to 56. `orochimaru_reversal_release_charge` (`0x0073F800`) chooses travel 2
when the accumulated count exceeds the last threshold, otherwise rising 1.
These are configured mask consumers, not a fixed physical-button mapping.

`reversal_game_bind_fighters` (`0x00747650`) replaces initialization's
default CPU weights with the selected difficulty row. Manda's four rows
at `0x00858D90` are `{45,8,20,15}`, `{40,8,20,20}`, `{30,8,20,20}`,
`{24,8,20,25}`, copied to `+0xF8/+0xFA/+0xFC/+0xFE`. Shared timing
rows at `0x00858100` are `{90,7,32}`, `{75,6,24}`, `{60,6,16}`,
`{45,5,8}`, copied to `+0x100/+0x102/+0x104`.
`reversal_game_generate_cpu_input` (`0x00748B60`) respects Practice
selectors and may use the human path. Otherwise it waits for cooldown,
draws against `FA+FC+FE`, chooses charge below `FC/2`, body in the next
band, and uses Manda's strictly-below-1000 distance predicate for the
`FE` band, falling back to charge when out of range. The remaining band
does nothing. A selected action resets cooldown to `F8 + random(104)`;
while holding charge, a `random(400) <= 10` result releases it.

#### Teardown and evidence limits

`orochimaru_reversal_release_resources` (`0x0073CF50`) destroys the three
owned players, initiating model helpers and two-model array; retires all
held effect groups after checking their live registry identity; releases
stage container `+0xB4` only when ownership flag `+0xB0` is set.
`orochimaru_reversal_destroy` (`0x0074ACF0`, vtable `+0x48`) then destroys the
body, five rising, two travel and base contacts, releases common controller
state and embedded helpers, and frees the complete allocation for a positive
delete flag. The shared finish voice, wait, smoke return and scene rebuild
lifetime are established in
[NUN4 Ultimate Jutsu](ultimate_jutsu.md#separate-authored-id-1-route).
This closes the selected controller's executable state/input/contact/damage
and ownership paths to the shared engine services. Remaining independent
questions are stage sampling activation/bindings, foreign matrix/cache lifetime
and spoken-content equivalence. The selected code-created effect chains close
in their original providers. [Manda controller voices](#manda-controller-voices)
joins start/finish/rising/travel producers to family-6 members 8..11 or
36..39, separately from compact state controls. The code does not prove how
many contacts a particular opponent trajectory will admit.

## Voice

Checked identities are **NUN4 Orochimaru ID 9 (`orc`)**, resident
`SLUS_218.62` / `BATTLE.BIN`, in both English and Japanese audio
sets, and **retail NA2 Orochimaru ID 89 (`orw`)**,
`SLPS_258.37` / `BTL.BIN`. Compact SNDDATA, streamed PLVOICE
dialogue and streamed SOUND intros have separate lookups.

### Compact candidates and ordinary producers

Donor `orochimaru_voice_event_pair` (`0x00436660`) selects base/base
`voice_events_base` at `0x00591DD0`; native's pair
(`0x00406FA0`) selects base/base `0x005C16C0`.
Their own voice-list consumers select the base list for these exact IDs;
changing the donor audio set changes its bank, not this event list.
All enabled base controls select the same-numbered program and default
key **60 (`0x3C`)**. Event 25 selects disabled control 27 and event 32
disabled control 41. Event 23 selects enabled control 28, whose program
entry is missing in all three checked banks.

| Bank | Descriptor / SNDDATA header offset / bytes | Sample region offset / bytes |
| --- | --- | --- |
| NUN4 English 0 | `orochimaru_compact_bank_english`, `0x004356DC`; `0x00641000 / 0x13B0` | `0x00642800 / 0x7AFC0` |
| NUN4 Japanese 1 | `orochimaru_compact_bank_japanese`, `0x00435A84`; `0x01AA9000 / 0x13B0` | `0x01AAA800 / 0x50B90` |
| NA2 ID 89 | `orochimaru_compact_bank`, `0x003FDC5C`; `0x014BD000 / 0xF60` | `0x014BE000 / 0x38550` |

Applying the established [compact decoder](../../session/battle_audio.md#compact-program-to-vag-lookup)
to the clean bank bytes resolves all 29 remaining enabled base programs
below. Each has one matching split, index 0, keys **12..119**, one
sample per set and both velocity ranges **1..127**; sample rate is
**22,050 Hz**, group 0, priority 10 and VAG flags 0.
Offsets are absolute within the owning **SNDDATA.BIN**, not EE addresses.
Donor index tuples agree between languages; their sample offsets differ.

| Program | Donor Sset/Smpl/Vagi | NA2 Sset/Smpl/Vagi | NUN4 English sample | NUN4 Japanese sample | NA2 sample |
| ---: | --- | --- | --- | --- | --- |
| 0 | 0/0/13 | 0/0/3 | `0x0067CF80` | `0x01AC7080` | `0x014C6120` |
| 1 | 1/1/14 | 1/1/4 | `0x0067DE70` | `0x01AC7A40` | `0x014C6AF0` |
| 2 | 2/2/15 | 2/2/5 | `0x0067EC30` | `0x01AC8540` | `0x014C77E0` |
| 3 | 3/3/16 | 3/3/6 | `0x0067F9B0` | `0x01AC8F30` | `0x014C8190` |
| 4 | 4/4/17 | 4/4/7 | `0x00680E20` | `0x01ACA2A0` | `0x014C9320` |
| 5 | 5/5/18 | 5/5/8 | `0x00681C90` | `0x01ACAFD0` | `0x014CA2B0` |
| 6 | 6/6/10 | 6/6/0 | `0x00671660` | `0x01ABE720` | `0x014BE000` |
| 7 | 7/7/11 | 7/7/1 | `0x00673D70` | `0x01AC11D0` | `0x014BFA90` |
| 8 | 8/8/12 | 8/8/2 | `0x00678E90` | `0x01AC55F0` | `0x014C2AB0` |
| 12 | 12/12/28 | 9/9/17 | `0x006A3BB0` | `0x01AE77D0` | `0x014E2020` |
| 13 | 13/13/29 | 10/10/18 | `0x006A4FB0` | `0x01AE8AA0` | `0x014E2560` |
| 14 | 14/14/30 | 11/11/19 | `0x006A6DC0` | `0x01AE9F40` | `0x014E3670` |
| 15 | 15/15/31 | 12/12/20 | `0x006A8BC0` | `0x01AEB530` | `0x014E4070` |
| 16 | 16/16/32 | 13/13/21 | `0x006AA950` | `0x01AEC4E0` | `0x014E5720` |
| 17 | 17/17/33 | 14/14/22 | `0x006ACB20` | `0x01AED990` | `0x014E6490` |
| 18 | 18/18/25 | 15/15/14 | `0x0069AF70` | `0x01AE20A0` | `0x014DADE0` |
| 19 | 19/19/26 | 16/16/15 | `0x0069D770` | `0x01AE3660` | `0x014DC6B0` |
| 20 | 20/20/27 | 17/17/16 | `0x0069FE00` | `0x01AE4A70` | `0x014DE4A0` |
| 21 | 21/21/34 | 18/18/23 | `0x006AE620` | `0x01AEEA10` | `0x014E7A40` |
| 22 | 22/22/36 | 19/19/25 | `0x006B60F0` | `0x01AF4530` | `0x014EEBA0` |
| 23 | 23/23/37 | 20/20/26 | `0x006B71C0` | `0x01AF54F0` | `0x014F05C0` |
| 24 | 24/24/38 | 21/21/27 | `0x006B8770` | `0x01AF66C0` | `0x014F13F0` |
| 25 | 25/25/35 | 22/22/24 | `0x006B17E0` | `0x01AF0540` | `0x014E9FC0` |
| 26 | 26/26/39 | 23/23/28 | `0x006B95C0` | `0x01AF72F0` | `0x014F2FF0` |
| 36 | 29/29/24 | 24/24/13 | `0x00695BC0` | `0x01ADDBD0` | `0x014D5040` |
| 37 | 30/30/23 | 25/25/12 | `0x006924E0` | `0x01ADB150` | `0x014D1CF0` |
| 38 | 31/31/20 | 26/26/9 | `0x00687A80` | `0x01AD0DC0` | `0x014CAF80` |
| 39 | 32/32/21 | 27/27/10 | `0x0068AA00` | `0x01AD4610` | `0x014CD000` |
| 40 | 33/33/22 | 28/28/11 | `0x0068FB20` | `0x01AD8F30` | `0x014D02B0` |

Donor program 27 is present as Sset/Smpl/Vagi `27/27/19`, sample
`0x00682AB0` English / `0x01ACBC40` Japanese, with the same checked
key/velocity ranges and rate. The checked base control disables it; no
selected producer below enables program 27. Native program 27 is a hole.
Program presence therefore does not establish a requested voice.

The authored startup difference is explicit: donor `orochimaru_actions`
(`0x0045FA20`, stride `0x64`) action 2 has voice **-2**, time **12**;
its actions 0/1/3 have -1/time 0. Native `orochimaru_actions`
(`0x005847D0`, stride `0x54`) action 0 has **-2**, time **8**;
actions 1/2/3 have -1/time 0. Under the shared scheduler's major-8 and
category gates, -2 draws events 6..8 or suppresses on draw 3; the
candidate programs are 6/7/8 above.

Donor `orochimaru_channel3` (`0x0024B180`) additionally requests
events 6/7/8 on actions 4/5/6, phase 1, using the secondary timeline;
their respective frames are 6/8/7. Action `0x1B`, phase 1,
secondary frame 9 requests event `0x14`, hence program 23.
Action `0x1F` requests pseudo -2 at phase-1 frame 5, or pseudo -3
at phase-0 frame 13; these select programs 6..8 or 3..5 respectively,
with draw 3 suppressing. These are compact requests, not PLVOICE indices.
The native `orochimaru_channel3` (`0x002F5740`) contains position
SFX/effect/helper calls but no direct descriptor/pseudo voice or PLVOICE
queue call; its shared action scheduler remains independent.

Donor resource 23's `orochimaru_jutsu1_update` (`0x00784250`)
consumes `orochimaru_jutsu1_compact_frames` (`0x0084AEF0`):
frame/selector pairs **33/1, 45/2, 55/4, 65/5, 100/6, 130/7**,
then ten -1/-1 pairs. The selector is resolved by
`jutsu_request_participant_compact_cue` (`0x0074B740`) through the
actual participant ID. Orochimaru 9's
`orochimaru_jutsu_compact_cue_pair` (`0x008453D0`) points twice
to the shared `jiraiya_jutsu_compact_cue_row` (`0x0085A4F0`).
Those six selectors become controls/programs **1/2/4/5/8/7**, at key 60,
with the exact candidates above. The row's name does not make its
consumer Jiraiya or select Jiraiya's bank.

In the first donor actor, `orochimaru_jutsu0_process`
(`0x007E4D30`) emits common positional SFX `0x16` at private phase-0
count 13 and `0x4F` every 15 phase-2 updates. Its calls to
`fighter_report_condition_event` (`0x00236980`) with index
`0x0E`, and the accepted-event call with `0x13`, forward a condition
row to a retained child. That routine contains no audio request.
Those indices must not be interpreted as descriptor voice events.

The second actor also inherits `skill_combo_accepted_event`
(`0x0079DB40`) at primary `+0x138`. Its compact requests use the
**target participant `+0x390`**, independently of the six source-frame
requests. Events 0/5 choose selectors 9..11, event 1 chooses 12..14,
and events 2/3 choose 15..17, using a permuted `random % 3`.
The [selected CHA1 commands](#packed-commands-and-selected-effect-leaves)
are 2/5/10; consequently they admit target selectors **15..17 / 9..11**,
while event 10 only sets the completion latch. If that target is
Orochimaru 9, its checked participant row maps those ranges to
controls/programs **18..20 / 12..14**, at default key 60, already
decoded above. Another target selects its own character row and bank.
`jutsu_request_participant_compact_cue` requires the valid participant
fighter and coordinator gate. Nonzero target `+0xD0` suppresses a
request; an admitted target request sets it to **20**. Source requests
are exempt from that target cooldown. Authored commands establish
request opportunities, not a clip for every command.

### Streamed dialogue selection and physical members

Donor `audio_queue_player_voice` (`0x001D46F0`) resolves a signed
cue against the ID-indexed list. `orochimaru_player_voice_cue_pointer`
(`0x00435504`) selects `orochimaru_player_voice_cues`
(`0x00434F50`): **38,39,265,289,293,298,299,302,312,-1**.
The ordinal is the English physical member. Its
`orochimaru_player_voice_archive` (`0x00436220`) has handle 129,
type/start 1/1 and count 18, loaded from PLVOICE outer **8** at
`0x001BA800`. `audio_request_archive_member` (`0x001DA180`)
adds half the descriptor count when audio context `+0x10 == 1`.
Together with the established [language selector](../nun3_nun4_characters.md#compact-bank-set-language),
this proves **English members 0..8 / Japanese members 9..17**,
despite the latter directory filenames being only `plv`.

Every member below fits its outer archive. File offsets are absolute
within the clean **PLVOICE.AFS**; sizes exclude padding.

| Donor cue | English member / offset / bytes | Japanese member / offset / bytes |
| ---: | --- | --- |
| 38 | 0 / `0x001BB000` / 12,133 | 9 / `0x001DF000` / 7,766 |
| 39 | 1 / `0x001BE000` / 22,402 | 10 / `0x001E1000` / 19,037 |
| 265 | 2 / `0x001C3800` / 5,981 | 11 / `0x001E6000` / 9,448 |
| 289 | 3 / `0x001C5000` / 18,939 | 12 / `0x001E8800` / 18,230 |
| 293 | 4 / `0x001CA000` / 17,601 | 13 / `0x001ED000` / 15,672 |
| 298 | 5 / `0x001CE800` / 13,461 | 14 / `0x001F1000` / 10,222 |
| 299 | 6 / `0x001D2000` / 16,788 | 15 / `0x001F3800` / 17,069 |
| 302 | 7 / `0x001D6800` / 9,740 | 16 / `0x001F8000` / 12,631 |
| 312 | 8 / `0x001D9000` / 24,108 | 17 / `0x001FB800` / 16,174 |

Native outer **88**, at `0x0133D800`, has 42 members. Descriptor
`0x003FE2B0` holds handle **238**, count 42. Its number-list pointer
`0x003FFA64` selects `0x003FF720`, with ordered suffixes
`45,47,49,63,68,69,125,126,151,155,165,166,167,199,209,210,211,235,269,290,293,302,303,308,312,313,318,323,324,338,339,364,365,366,369,370,373,374,379,389,390,391`.
NA2 adds no language-half offset. Same-suffix native members 293/302/312
are **20/21/24**, at `0x01377000/0x01378000/0x01380000`, sizes
**3,776/10,570/8,520**. Donor cues 38/39/265/289/298/299 are absent
from that native list. Matching suffixes do not establish matching speech.

| Ordinary actor / resource | Indexed dialogue row | Four cue values | Checked source producer |
| --- | --- | --- | --- |
| NUN4 first / 22 | `orochimaru_jutsu0_dialogue_row 0x0085A0A0` | 39 / 38 / 39 / 39 | `orochimaru_jutsu0_accepted_event 0x007E5530`, private phase 0 and target input-count 0, calls virtual `+0xD4`, index 0, immediate 1: cue 39. |
| NUN4 second / 23 | `orochimaru_jutsu1_dialogue_row 0x0085A0A8` | 38 / 38 / 38 / 38 | `jutsu_update_resource_binding 0x0076FE70` matches frame 0/index 0 in `orochimaru_jutsu1_dialogue_frames 0x0085A668`: cue 38. |
| NA2 first / 182 | `orochimaru_jutsu0_dialogue_row 0x008CBD10` | 389 / -1 / -1 / -1 | `skill_primary_action_dispatch 0x00795190` matches frame 0/index 0 in `orochimaru_jutsu0_dialogue_frames 0x008CC340`: cue 389. |
| NA2 second / 183 | `orochimaru_jutsu1_dialogue_row 0x008CBD18` | 390 / 391 / -1 / -1 | `orochimaru_jutsu1_set_state 0x008676A0` and inlined `orochimaru_jutsu1_update 0x00867760` state-2 entry request index 1: cue 391. |

Donor resource 22's `orochimaru_jutsu0_dialogue_frames`
(`0x0085A660`) and native resource 183's
`orochimaru_jutsu1_dialogue_frames` (`0x008CC348`) contain only
-1, so their generic loops add no nonnegative authored-frame request.
Native `interaction_stage_cutins` (`0x00778D90`), after its predicate
and resource >115 check, calls source index 0 at
`orochimaru_native_cutin_dialogue_call` (`0x00778E2C`).
Both native resources meet that numeric bound; the conditional request
selects **389** or **390** respectively.

Installed methods determine timing: donor resource 22's `+0xD4` is
`jutsu_request_participant_dialogue` (`0x0074B640`), which respects
immediate 1. Donor resource 23 instead installs
`jutsu_defer_participant_dialogue` (`0x007790B0`), whose MIPS
`move a3,zero` forces deferred FIFO storage. Both native actors install
`skill_primary_voice_produce_mode0` (`0x007A3AE0`) at `+0xD8`;
it likewise forces deferred storage before `dialogue_voice_consume`.
An immediate flag at a caller alone therefore does not establish an
immediate stream request. The producer uses the actual participant ID;
another speaker's row cannot be assigned Orochimaru's archive by resource
number alone.

| Native cue | Physical member / absolute PLVOICE offset / bytes |
| ---: | --- |
| 389 | 39 / `0x013AE800` / 53,933 |
| 390 | 40 / `0x013BC000` / 8,960 |
| 391 | 41 / `0x013BE800` / 14,698 |

### Selected ordinary-actor indirect request closure

The donor [concrete actor bindings](#jutsu-records-and-concrete-actors)
select primary vtables `orochimaru_jutsu0_vtable` (`0x005F59B0`)
and `orochimaru_jutsu1_vtable` (`0x00602990`). Their installed primary
methods and direct overlay callees contain only the two indexed
dialogue call sites above: `jutsu_update_resource_binding` and
`orochimaru_jutsu0_accepted_event`. Their selected frame/state paths
request **source index 0**; they supply no request for stored indices
1/2/3. Short methods omitted from MCP's function inventory were checked
through its live-byte view, including the complete `jr ra; nop`
`skill_primary_command_noop` (`0x007715F0`) installed at resource 22's
`+0x138`.

The shared [participant-command bridge](shizune_kabuto.md#selected-dialogue-producers)
routes eligible authored commands through
`jutsu_active_primary_command_dispatch` (`0x007714F0`) to the selected
primary `+0x138`. Resource 22 terminates at that empty method. Resource
23 reaches `skill_combo_accepted_event`, which adds the target compact
selectors above and no PLVOICE row index. Its selected contact
presentation arms `skill_combo_contact_events0to3_case` /
`skill_combo_contact_event5_case` (`0x0079D7B8/0x0079D8A0`) likewise
have no primary `+0xD4` dialogue dispatch. Finish and destruction add
no indexed dialogue request on these selected actor paths.

Donor `interaction_stage_cutins` (`0x00751520`) has the same numeric
resource **>115** gate as the native route above. Resources 22/23 fail
that gate, so it adds no donor ordinary-jutsu dialogue request. This
closure concerns these two installed actor contexts, not unrelated
fighter/global audio or the shared PLVOICE cue producers below.

### Selected Ultimate Jutsu intros and compact frame cues

Donor `jutsu_presentation_update` (`0x00377730`) and
`reversal_presentation_update` (`0x00378940`) request the selected
intro through `audio_request_sound_member` (`0x001D9FC0`), bank 9,
slot 0, archive family 0. Its
`ultimate_jutsu_sound_archive_descriptor` (`0x00435E58`) holds
handle 9 and 272 members, loaded from **SOUND outer 9** at
`0x15668800`; Japanese adds **136**. Native
`jutsu_presentation_update` (`BTL 0x00769790`, call `0x00769F30`)
uses **SOUND outer 7**, descriptor `0x003FDD08`, handle 7,
189 members, at `0x08226000`, without a language-half addition.
[Selected UJ records](#cinematics)
supply these exact intro selectors:

| Selected record / intro | English SOUND member / absolute offset / bytes | Japanese SOUND member / absolute offset / bytes |
| --- | --- | --- |
| NUN4 18 / 19 | 19 / `0x156C0000` / 39,568 | 155 / `0x15945800` / 29,624 |
| NUN4 19 / 131, reversal startup | 131 / `0x158E9000` / 14,015 | 267 / `0x15B08800` / 10,023 |
| NUN4 20 / 20 | 20 / `0x156CA000` / 23,684 | 156 / `0x1594D000` / 23,413 |
| NA2 206 / 174 | 174 / `0x084C7800` / 28,492 | — |
| NA2 207 / 175 | 175 / `0x084CE800` / 16,756 | — |
| NA2 208 / 176 | 176 / `0x084D3000` / 21,005 | — |
| NA2 209 / 177 | 177 / `0x084D8800` / 41,977 | — |

The donor English names are `strST_019/131/020.ahx`, Japanese
`str`; native names are `strST_174/175/176/177.ahx`.
These are streamed SOUND clips, independent of PLVOICE cue 38/39.

Donor ordinary skills 22/23 retain
`orochimaru_cinematic22_hits` / `orochimaru_cinematic23_hits`
(`0x005CD560/0x005CD568`), rows `0x005C7F00/0x005C7F10`.
Skill 22 has two rows: frames 140/190, popup 2/3, sound `0x0F/0x12`,
damage words 5461/27307. Skill 23 has 51 rows; its popup rows are
79/115/130/184/345 with values 1/1/1/2/3. Each descriptor's damage
words sum to `0x8000`, with all chakra words zero, separately from
the UJ record's total damage percentage.

Their nonnegative sound bytes enter `audio_request_cinematic_cue`
(NUN4 `0x001D7360`, NA2 `0x001D5820`), selecting **compact
controls/programs** at default key 60 through the ordinary scene route.
The complete selected frame/control pairs are:

| Game / skill | Descriptor / rows / count | Frame : compact control |
| --- | --- | --- |
| NUN4 22 | `0x005CD560 / 0x005C7F00 / 2` | 140:15, 190:18 |
| NUN4 23 | `0x005CD568 / 0x005C7F10 / 51` | 66:12, 79:13, 99:15, 115:16, 184:18 |
| NA2 169 | `orochimaru_cinematic169_hits 0x005D4268 / 0x005D3140 / 2` | 140:15, 190:18 |
| NA2 170 | `orochimaru_cinematic170_hits 0x005D4270 / 0x005D3150 / 51` | 66:12, 79:13, 99:15, 115:16, 184:18 |
| NA2 166 | `orochimaru_cinematic166_hits 0x005D4250 / 0x005D2ED0 / 57` | 207:15, 455:18 |
| NA2 167 | `orochimaru_cinematic167_hits 0x005D4258 / 0x005D30A0 / 18` | 137:16, 161:12, 251:13, 473:16, 484:17, 533:15, 568:14 |

These controls all resolve to the compact candidates above; they are
neither SOUND intro selectors nor PLVOICE member indices. Matching donor
22/23 and native 169/170 frame/control pairs do not establish identical
sample bytes or whole-scene behavior. Category-6 requests use the
separate [category-6 route](../../session/battle_audio.md#match-category-6-request-admission), so this
ordinary scene lookup must not be applied to that branch.

### Manda controller voices

The authored-skill-1 Manda controller uses `reversal_game_request_voice`
(BATTLE `0x00730600`), family 6, entry-4 cues 8..11, in the initiating
fighter's side slot. `reversal_game_request_start_voice` (`0x00747AD0`)
requests phase 0/cue 8 once at controller start. `reversal_game_finish_ready`
(`0x00747E40`) requests phase 1/cue 9 after finish is set and state is idle,
then waits for the slot's observed start and stop before completion.
`reversal_game_dispatch_state_voice` (`0x007307D0`) runs from progress
update: rising state 1 requests phase 2/cue 10 at state count 4; travel
state 2 requests phase 3/cue 11 at count 2. These are controller state
counts at `+0x10`, not animation frames. The trigger comes from attack
pattern `+0x16`, independently of its damage and reaction fields.

`audio_request_sound_member` (resident `0x001D9FC0`) forwards through
`audio_request_archive_member` (`0x001DA180`) to
`reversal_sound_archive_descriptor` (`0x00435E40`): handle 6, 56 members,
audio setting 1 adds 28. Startup partition loading (`0x001D8250`) binds
that handle to `@source_nun4/DATA/SOUND.AFS` outer member 6. The nested
AFS is at complete-file offset `0x14A46000`, size 1,034,240, with 56
entries. The exact selected members are:

| Producer / cue | Setting 0 member; file offset; bytes | Setting 1 member; file offset; bytes |
| --- | --- | --- |
| Start / 8 | 8; `0x14A6D000`; 17,877 | 36; `0x14AE9000`; 15,168 |
| Finish / 9 | 9; `0x14A71800`; 25,145 | 37; `0x14AED000`; 29,090 |
| Rising / 10 | 10; `0x14A78000`; 2,798 | 38; `0x14AF4800`; 8,563 |
| Travel / 11 | 11; `0x14A79000`; 7,339 | 39; `0x14AF7000`; 9,178 |

Setting-0 names are `summon08..11.ahx`; setting-1 names are `kuc`.
All eight selected entries have AHX headers. The complete SOUND hash
matches [the recorded input](../../../game/files/file_identities.md#tsunade-comparison-inputs).
This joins producers to exact stored members without asserting spoken
equivalence. Startup intro 131 remains a separate family-9 request.

Body state 3 instead calls `battle_voice_control_by_object`
(`0x001D5900`) with compact control `0x5F` at state count 4.
`reversal_game_request_state_control` (BATTLE `0x00730700`) maps incoming
states 5/6 to controls `0x5C/0x5D` and 7/8 to `0x5E`; their dispatcher
uses state count 1. The six controls `0x5C..0x61` at
`reversal_compact_state_controls` (`0x00433F60`) select program 55,
stream/channel 0 and default scalar 62..67. The object dispatcher writes
program and parameter commands to the initiating side's compact packet
handle, subject to its existing admission gates. These controls are not
SOUND members or physical sample keys. The exact controller state and
resource ownership is in [Reversal entry 4](#reversal-entry-4).

**Evidence limits:** code and clean archive tables establish the exact
requests, selected bank halves and stored sample/member bytes. The source
PLVOICE/SNDDATA hashes were checked against
[File identities](../../../game/files/file_identities.md#character-comparison-inputs);
MCP does not expose these external archives, so their tables were read
directly without modifying or extracting them.
The remaining independent streamed question is the actual producer/admission
paths for donor shared dialogue cues **265/289/293/298/299/302/312**.
It belongs to the generic NUN4 PLVOICE machinery, separately from the
selected resource-22/23 actor closure. Row/list presence does not close
those call paths. Spoken meaning and audible equivalence remain
unestablished; exact selected bytes do not depend on establishing either.

## Indexed services

### NUN4 Orochimaru and NA2 Orochimaru AI services

Checked characters are NUN4 Orochimaru **9 (`orc`)**, resident
`SLUS_218.62` / `BATTLE.BIN`, and retail NA2 Orochimaru **89 (`orw`)**,
resident `SLPS_258.37` / `BTL.BIN`. Both fighter virtual wrappers gate
their own tick on the same control bits, with no extra decisions in the
wrapper. Their overlay state and profile layouts differ: NUN4 uses
`0x1A0`-byte side slots and 31 profile halfwords; NA2 uses `0x1E0`
and 40.

NUN4 `battle_ai_update` (`0x006EA010`) reads the actual fighter ID at
`+0x68`, then copies two signed halfwords from
`ai_character_values` (`0x00853BE0`), stride four.
`orochimaru_ai_character_values` (`0x00853C04`) is **`{2,5}`**.
The first value selects the 50 rather than 30 post-dispatch roll for
fighter classes `0x15/0x16`; the second is a strict random-100 threshold
in `ai_find_competitive_world_object` (`0x006E1780`) and
`ai_construct_point_route` (`0x006E22E0`), together with closer-to-self
and resource/region gates. The row is not a selector plus flags byte.
Native ID 89's per-tick row is **`{1,30}`** through its own `ai_tick`.
Both first values take the checked 50-threshold branch; their alternate
target thresholds differ.

NUN4 has a separate actual-ID byte table `ai_character_flags`
(`0x008538D0`). `orochimaru_ai_flags` (`0x008538D9`) is **`0x10`**;
native's separate descriptor flags at `0x008C31B6` are also **`0x10`**.
Neither sets initializer multiplier bits `1/4/8`. The NUN4 readers are
`ai_initialize` (`0x006EACF0`), `ai_state11_update` (`0x006DEF90`),
`ai_react_target_state` (`0x006E4BB0`) and `ai_main_reaction`
(`0x006E8F00`). The two former reaction paths combine bit `0x10` with
a clear self contact bit 5 to attempt state 22; the main reaction
suppresses its corresponding attempt when both bits are set. Native
readers have the established roles below, with their own profile indices
and ordering. Equal flag bytes do not establish equal decision behavior.

In both checked incoming-reaction bodies, NUN4 `0x006E4F10` and native
`ai_react_incoming_action`, Orochimaru's actual ID takes the default
no-shape **bucket below 3** rule, outside the explicit 650/800/1200
distance groups. Neither matches the target-ID-49/current-index-34
exception. NUN4 `ai_late_reaction` (`0x006E37C0`) and its native counterpart
test actual target IDs 59/64, so donor 9 and native 89 take the general
branch. Both main reactions' target-ID-36 action exception also excludes
these Orochimaru IDs. These are bounded direct-body conclusions; shared
action metadata, other callees, indirect identity aliases and complete
decision equivalence remain outside this comparison.

### Orochimaru indexed support selection

For retail NA2 Orochimaru **fighter ID 89 (`0x59`, `orw`)**,
`orochimaru_support_candidates` (`BTL 0x008D2858`) supplies
**`0x1D,0x21,0x1D`** to `support_config_resolve`. The support-identity
table maps those IDs to Kabuto 90 and Sasuke 93; Orochimaru's own support
ID is **`0x1C`**, whose `orochimaru_support_identity` row at
`0x008D28F4` maps fighter/display ID 89. These are distinct numeric domains.

`support_pair_compatible` (`0x008858C0`) normalizes recognized fighter
forms before its 104-pair exclusion scan. Fighter 89 has exactly two
exclusions: support **`0x17`** at `0x008D1A18` and **`0x1C`** at
`0x008D1A38`. Other native support IDs `0..0x21` pass this predicate;
saved availability or recommendation is an additional selector gate.

The 66-row code lookup has one fighter-89 override:
`orochimaru_kabuto_support_code_override` (`0x008D1B03`) maps
support **`0x1D` to code `0x3C`**, replacing its wildcard code `0x3B`.
`item_character_selector` (`0x00885790`),
`support_pair_setup_event` (`0x00885FF0`) and
`support_config_normalize` (`0x00886250`) scan to the last matching row
after base normalization. Support `0x21` retains wildcard code `0x41`.

The complete 912-row recharge table has 33 exact fighter-89 matches:
support `0x1D` has class **4** at `0x008D2528`, support `0x20` has class
**1** at `0x008D25F7`, and the other 31 matches have class **0**.
Support `0x21` has no such row and keeps default class **2**.
The gauge initializer therefore selects multipliers 1.2, 0.9, 0.8 and
1.0 respectively; compatibility still rejects the two excluded supports
even though their recharge rows exist.

`orochimaru_linked_ultimate_admission` (`0x008D2684`) is
`{support 0x21,fighter 0x59,admission 0xA7}`. The ten-row consumer
`support_cinematic_archive_path` (`0x00885660`) uses support identity
to select the linked cinematic filename. The five six-byte rows consumed
by `support_linked_jutsu` (`0x00885F00`) contain no fighter-89 entry,
so no ordinary-jutsu replacement comes from that table for this fighter.
Recommendations, code choice, recharge, compatibility and cinematic
admission remain separate consumers. These are NA2 relationships; this
comparison establishes no equivalent NUN4 support relationship for
Orochimaru **ID 9 (`orc`)**.

### Orochimaru fighter and jutsu admission

Checked donor NUN4 Orochimaru **9 (`orc`)**, `SLUS_218.62`, has source
roster row `orochimaru_character_select_roster_entry` (`0x00582540`):
`{ID 9,category 0,list row 3}`. `character_select_build_roster_nodes`
(`0x003A63F0`) visits 63 records and its node builder accepts this row.
Own-game `roster_character_valid` (`0x003260E0`) returns zero for 9;
`character_is_transformed` (`0x00326230`) also returns zero, and the
forward form mapper returns zero. This establishes a base roster node
with no linked form from that mapper.

`character_select_refresh_availability` (`0x003A66D0`) sets that node's
availability from a nonnull manager and `profile_roster_available`
(`0x00323390`). The latter masks bit 0 after
`profile_character_status_load` (`0x0039CF30`) reads the byte at
**profile `+0x7E9`** for ID 9. A null manager clears availability in
this donor refresh. Fixed-choice presentation has its separate numeric
and fixed-filter gate; this is not evidence of every acquisition path.

Native NA2 Orochimaru **89 (`0x59`, `orw`)**, `SLPS_258.37`, passes
the native range/fixed filters and has no inverse-form mapping. Its ordinary
`character_select_fighter_available` (`0x003B3DB0`) therefore requires
only its own status bit 0, at **profile `+0x961`**, through
`profile_roster_available` (`0x001F54C0`). The native caller admits a
null manager as described above. Native ID **9** fails the fixed filter
and is not this Orochimaru character.

For native fighter 89, `jutsu_native_owner` (`0x00307ED0`) admits
selectors **178/179** only when their numeric owner and signed action
owner both equal 89; checked action 1 has packed owner/selector
`0x00B20059` at `0x00584830`. The separate cross-character mapping
`orochimaru_jutsu_exclusion_mapping` (`0x005C13D0`) selects list 4,
which excludes **`0x8D`**. The shared special-selector whitelist and
final restriction of **`0x34` to fighter `0x46`** still apply.
`profile_ability_get` (`0x001F7210`) then requires the saved selector bit.
Donor selectors **18/19** have numeric owner 9 and are absent from that
native special set: they do not pass either native admission route for
fighter 89. The checked donor action-1 owner/selector word is
`0x00120009` at `0x0045FAA0`. These are exact retail admission results,
not a choice of destination identity.

### NUN4 and NA2 Orochimaru presentation

For NUN4 Orochimaru **9 (`orc`)**, `SLUS_218.62`,
`orochimaru_character_select_display` (`0x005820FC`) is six halfwords
`{1,1,0,208,224,120}`. Own-game
`character_select_bind_fighter_portrait` (`0x003A68D0`) indexes the
twelve-byte `character_select_display_rows` (`0x00582090`), takes bank
1 plus one for **`TEX_purecharsel02`**, and computes atlas origin from
column 1 times 168 and row 0 times 256, normalized against 512.
`character_select_name_rectangle_copy` (`0x003A3AC0`) reads the final
three halfwords and returns **`{209,225,118,30}`** after its +1/+1/-2
adjustments. Its selected/form/fixed-choice gates precede that lookup.

Native NA2 Orochimaru **89 (`orw`)**, `SLPS_258.37`, has
`orochimaru_character_select_portrait` (`0x005D4B1C`), twelve bytes
`{bank 6,x 168,y 168,width 168,height 168}`. Native construction uses
**`TEX_purecharsel07`**; `character_portrait_origin` normalizes the
stored 168/168 directly. The separate eight-byte
`orochimaru_character_select_name_rectangle` (`0x005D5138`) is
**`{161,33,82,30}`**, copied directly by `character_name_rectangle_copy`.
Neither game's selector atlas row is its 3PCT CCS file.

NUN4's actual-ID-9 filename rows are `0x0057A1C4/0x0057A304/
0x0057A444/0x0057A584`, selecting **`2orcbod1.ccs`, `1orcbod1.ccs`,
`3orc3eye.ccs`, `3orc3pct.ccs`**. Native ID 89's corresponding rows
`0x00402254/0x00402874/0x00402E94/0x004034B4` select the **`orw`**
families. Both own-game `manager_publish_six_selections` bodies clear
flag `0x100` and publish 2BOD1/1BOD1/3EYE names, borrowed containers
and three-byte codes without a null-name check. The donor per-side queue
uses mask **8** for 3PCT, versus native mask **`0x10`**. File selection
and adoption are owned by [Character assets](../../../game/character_assets.md#selection-and-loading-consumers).

The separate NUN4 `character_presentation_array_initialize`
(`0x003B2CA0`) finds **zero** in actual-ID-9 entry
`orochimaru_presentation_array_entry` (`0x00583734`), so that path
creates no auxiliary descriptor players for this character. The row does
not suppress the independent 3EYE, 1BOD1 or 3PCT consumers. It is a
bounded negative for this descriptor array, not complete presentation
resource closure.
