# Kakashi: UN3 donor

## Research coverage

Established for UN3 Kakashi 8 against NA2 Kakashi 70: 46/178/154 against
48/186/157 actions/rows/names with equal stored base parameters, the same
record layout and input signatures, and the UN3-to-NA2 response-selector,
response-substate and guard-sound numbering; callbacks; Fanged Pursuit's
overrides, voices and single contact; Lightning Blade's state machine and its
NA2 form `ccSkillANB000`; thirteen Ultimate Jutsu records selecting four
films, with placement, palettes, soundtracks and cue rows; effect `0x15`'s
factors, borrowed opponent bank and lifetime; NA2 reading of every donor
file; compact, PLVOICE, jutsu-dialogue, end-demo and intro voices.
Open: which clips match intended lines needs listening.

Names come from `@annotations/UN3` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [UN3 and UN4 characters](../un3_un4_characters.md).

## Records, moves and assets

Checked identities: UN3 Kakashi Hatake **ID 8, `kks`**, resident
`SLUS_217.27` and `BATTLE.BIN`; retail NA2 Kakashi **ID 70
(`0x46`), `kkw`**, resident `SLPS_258.37` and `BTL.BIN`.
NA2's vacated ID 8 does not identify its playable Kakashi.
Complete clean-file identities are in
[Kakashi inputs](../../../game/files/file_identities.md#kakashi-comparison-inputs).

### Definitions, construction and ID services

| Root | UN3 ID 8 | NA2 ID 70 |
| --- | --- | --- |
| Definition | `0x00476770` | `0x005A2B30` |
| Record | `kakashi_character_record`, `0x003AE9F0` | `kakashi_character_record`, `0x00525BC0` |
| Actions / rows / animation names | `0x003ADAD0 / 0x003AA5F0 / 0x003AA380` | `0x00524BF0 / 0x005212E0 / 0x00521020` |
| Counts | 46 / 178 / 154 | 48 / 186 / 157 |
| Factory / constructor | `0x001E4000 / 0x001E4050` | `0x002C6510 / 0x002C6560` |
| Allocation / concrete vtable | `0x5460 / 0x00689620` | `0x5870 / 0x005DA650` |
| Descriptor / embedded names, actions, rows | `0x003AEAD0 / +0xE00,+0x1068,+0x1F80` | `0x00525CA0 / +0xEE0,+0x1154,+0x2114` |

The complete record range `+0x58..+0xDB` agrees byte for byte.
Pointers and authored-array counts differ. Both constructors install
the concrete vtable at fighter `+0x50`, bind one
`OBJ_2cmn00t0 r_hand` descriptor and initialize their own embedded
working storage before the common asset load. Native construction also
initializes its mode byte at `+0x584C` to zero.
Donor `kakashi_destroy` (`0x001E4120`) restores its concrete vtable,
runs common fighter/base cleanup and frees only for a positive deleting flag.

The donor's first twelve vtable words agree with the checked common
Classic Naruto slots except its destructor and virtual `+0x1C` AI callback.
This is a bounded slot comparison, not a complete class-equivalence claim.
`kakashi_ai_update` (`0x001E41A0`) calls UN3 `ai_tick`
(`0x00825260`) under controller flags; the actual fighter ID at
`+0x64` indexes `ai_character_descriptors` (`0x0093ADF0`).
Its ID-8 row `kakashi_ai_descriptor` at `0x0093AE30` is
`{2,0x46}`. Native's callback `0x002C66C0` reaches
`ai_tick` at `0x00704D40` and uses the
[native per-character lookup](../../session/battle_ai.md#per-side-state-block).
Its four-byte layout differs from the donor's eight-byte descriptors.

### Complete authored move correspondence

Both games use `0x54`-byte action records and `0x4C`-byte phase rows.
The table lists every donor action's ordered nonempty animation suffixes.
Own prefixes are `pkks` versus `pkkw`; repeated suffixes denote separate
authored phases. An equal suffix order does not establish equal motion,
input admission, attack descriptors or callback behavior.

| Donor / native action, decimal | Donor suffix order | Native comparison |
| --- | --- | --- |
| 0 / 0 | `chb00,chb02` | same suffix order |
| 1 / 1 | `cha00` | same suffix order |
| 2 / 2 | `empty` | same suffix order |
| 3 / 3 | `cha10` | same suffix order |
| 4 / 4 | `rdy1,spl00,spl02` | same suffix order |
| 5 / 5 | `rdy1,spl10,spl10,spl12` | same suffix order |
| 6 / 6 | `rdy1,spl20,spl20,spl22` | same suffix order |
| 7 / 7 | `nxs0,sig0,sig0,sxn0` | same suffix order |
| 8 / 8 | `nxs0,sig0,sig0,sxn0` | same suffix order |
| 9 / 9 | `nxs0,sig0,sig0,sxn0` | same suffix order |
| 10 / 10 | `jmp1,kca00,kca02,lan0` | same suffix order |
| 11 / 11 | `jmp1,kca10,kca12,lan0` | same suffix order |
| 12 / 12 | `jmp1,pna70,pna72,lan0` | same suffix order |
| 13 / 13 | `jmp1,kca30,kca32,lan0` | same suffix order |
| 14 / 14 | `jmp1,pna00,pna02,lan0` | same suffix order |
| 15 / 15 | `jmp1,pna80,pna82,lan0` | same suffix order |
| 16 / 16 | `jmp1,kca90,kca92,lan0` | same suffix order |
| 17 / 17 | `jmp1,kcb00,kcb02,lan0` | same suffix order |
| 18 / 18 | `jmp1,pna90,pna92,lan0` | same suffix order |
| 19 / 19 | `pcmnjmp2,jmp1,dow0,jpz1,jpz0` | same suffix order |
| 20 / 22 | `pnc10,pnc12` | same suffix order |
| 21 / 23 | `pnc20,pnc22` | same suffix order |
| 22 / 24 | `pnc30,pnc32` | same suffix order |
| 23 / 25 | `pna20,pna22` | same suffix order |
| 24 / 26 | `pnc50,pnc52` | same suffix order |
| 25 / 27 | `kcs30,kcs32` | same suffix order |
| 26 / 28 | `pnc90,pnc92` | same suffix order |
| 27 / 29 | `pnc60,pnc62` | same suffix order |
| 28 / 30 | `pnc40,pnc42` | same suffix order |
| 29 / 31 | `pnc70,pnc72` | same suffix order |
| 30 / 32 | `kcs10,kcs12` | `kcs10,kcs11,kcs12,kcs13` |
| 31 / 33 | `crs00,crs00,crs02` | `crs00,crs02` |
| 32 / 34 | `kcs20,kcs22` | same suffix order |
| 33 / 35 | `hol00,hol01` | same suffix order |
| 34 / 36 | `hol02,hol03` | same suffix order |
| 35 / 37 | `pna30,pna30,pna30,pna32` | same suffix order |
| 36 / 38 | `kca40,kca42` | same suffix order |
| 37 / 39 | `kca50,kca50,kca52` | same suffix order |
| 38 / 40 | `kca60,kca60,kca60,kca62` | same suffix order |
| 39 / 41 | `pna40,pna42` | same suffix order |
| 40 / 42 | `kca80,kca82` | same suffix order |
| 41 / 43 | `hla00,hla01` | same suffix order |
| 42 / 44 | `hla02,hla03` | same suffix order |
| 43 / 45 | `pna50,pna50,pna52` | `pna50,pna52` |
| 44 / 46 | `pna60,pna62` | same suffix order |
| 45 / 47 | `kca70,kca70,kca72` | `kca70,kca72` |

Native-only actions **20/21** occupy rows 92/99:
`pcmnjmp2,kca00,kca00,kca02,lan0,ost0` with category
`0x04000000`, and `cha10` with category zero.
Action 21's title is `万華鏡写輪眼` (Mangekyo Sharingan).
Donor action 1 is `Summoning Earth Style: Fanged Pursuit Jutsu`;
native action 1 is `雷切落とし` (Lightning Blade Drop).
Both second-jutsu action 3 titles identify Lightning Blade
(donor `Lightning Blade`, native `雷切`).

Across the 46 aligned actions, all stored cost `+0x20` and damage
`+0x24` words agree. Other payloads do not: every aligned action
except 2 and 7..9 differs somewhere in `+0x10..+0x4F`.
Many differences are packed response/audio values and continuation indices.
Distinct flags occur at donor/native 31/33 (`0x21/0x60021`),
32/34 (`0x21/0x60021`), 34/36 (`0x40C1/0x4081`),
and 42/44 (`0x4242/0x40C2`).
Stored `+0x28` factors differ at 28/30 (1/0.9) and 32/34 (1/0.8);
threshold words `+0x34/+0x38` differ at 30/32, 31/33, 32/34
and 34/36. Equal costs and animation names therefore do not establish
equal attacks.

The record layout is NA2's `ActionRecord`, and every one of the 46
aligned actions has the same input `signature` (`+0x1C`) as native's,
so the input encoding is shared. Two fields are numbered differently.
`response_selector` (`+0x2C`) indexes each game's
`response_select_substate` (UN3 `0x001C07E0`, NA2 `0x00231C60`); NA2
inserts selectors 6/7 (`0x2D/0x2E` heavy responses) and `0x16`
(`0x41`), so UN3 selectors `0..5` stay, `6..0x13` add 2 and
`0x14..0x24` add 3, and `0xFF` stays. `guard_sfx` (`+0x4A`) is one
higher in NA2. Actions 0..19 show both: their stored selectors
13/16/18/19 are native 15/18/20/21, their guard sounds 81..91 are native
82..92, and their other audio fields are equal. The phase rows of those
actions (NA2's `CharacterAnimationRow`) are equal except the two
skeleton-object name pointers at `+0x28/+0x40`, which point into each
executable's own strings. Callback and mutable-bank behavior is owned by
[Kakashi callbacks](#callbacks).

### Ordinary jutsu actors and providers

| Route | Donor | Native |
| --- | --- | --- |
| Configured selector → resource | 16/17 → 10/11, map `0x0093E840` | 140/141 → 142/143, map `0x008CB390` |
| Resident provider rows | `0x00476298`, stride 12 | `0x005A2780`, stride 8 |
| Filename roots | `2kkscha0 / 2kkscha1` | `2kkwcha0 / 2kkwcha1` |
| First factory / allocation / constructor | `0x0086C958 / 0x730 / 0x008C8650` | `0x00774A00 / 0x1110 / 0x007E3480` |
| Second factory / allocation / constructor | `0x0086C980 / 0x930 / 0x008E54F0` | `0x0077512C / 0x13C0 / anb_construct 0x00807AC0` |

Donor `kakashi_fanged_pursuit_construct` calls
`fanged_pursuit_base_construct` (`0x008B3E00`) and installs
`kakashi_fanged_pursuit_vtable` (`0x00694F90`) at actor `+0x28`.
The table ends before the next table at `0x00695210`.
Against the base vtable `0x00699430`, Kakashi replaces only the
destructor (`kakashi_fanged_pursuit_destroy`, `0x00910510`), begin,
frame events, attacker completion (`+0x258`, made a no-op) and defender
completion (`+0x25C`); its `+0xEC/+0x248` replacements are no-ops,
as in the base. Everything else, including contact application, is inherited.

`kakashi_fanged_pursuit_begin` (`0x008C8690`) calls
`fanged_pursuit_bind_participant_animations` (`0x008B58A0`) with
attacker phases `{none, ANM_pkkscha01}` and defender
`ANM_pkkscha02`, then `jutsu_actor_set_camera_target_names`
(`0x0087C240`) stores `OBJ_camera2kkscha01` and
`OBJ_target2kkscha02` at actor `+0x2C/+0x30`. These are SLUS
data at `0x006A21F8..0x006A2208`, not callbacks.
`kakashi_fanged_pursuit_frame_events` (`0x008C86F0`) plays
`ANM_pkkscha03` (`0x006A220C`) on a scene player at frame 1, placed
by the actor transforms at `+0x1F0/+0x200`. Its
`kakashi_fanged_pursuit_event_rows` (`0x00926290`) `{50,21},{85,8}`
are voice indices for the attacker: through
`jutsu_default_voice_index_table` (`0x0093D770`) they emit compact
controls 22 and 8 at frames 50 and 85. Sound rows
(`0x009262A0`) are `{15,14},{20,111},{30,111},{50,13},
{85,134},{90,134},{104,135}`.

`fanged_pursuit_participant_completion` (`0x008B6D50`) calls
`+0x25C` each time the defender's participant animation ends.
`kakashi_fanged_pursuit_restore_participants` (`0x008C8920`)
restores the defender and then calls
`interaction_publish_resource_contact` (`0x0087F270`) with
resource 10's only contact row,
`kakashi_fanged_pursuit_contact_definition` (`0x00920718`):
response selector `0x13` (NA2 `0x15`), damage factor 1.0 times the source action's
`+0x24` damage. This is the jutsu's only damage call.
The inherited `fanged_pursuit_apply_contact` (`0x008B4D20`) turns
both participants to face each other, places the defender beside the
attacker when they are within 100 units, sets record `+0x14` bit
`0x80000` and applies the record through the common jutsu contact
routine `0x0087FD00`.

Donor `lightning_blade_construct` (`0x008E54F0`) is shared
by resources `3/0xB/0x35/0x59`; Kakashi selects `0xB`.
`lightning_blade_begin` (`0x008E5C20`) selects the fourteen-slot
`kakashi_lightning_blade_name_bank` (`0x00928240`):
`ANM_pkkscha11..15`, `ANM_ekkscha11a/b/c`,
`ANM_ekkscha12`, remaining common/empty slots, and
`TEX_pkkscha02/01`. It creates three registered `0x4C` children
from `0x00927DF0+i*0xB0` and a `0xD0` auxiliary renderer,
with embedded players at `+0x660/+0x6B0/+0x720`, contact at
`+0x8C4`, participant/camera state and private state transitions.
`lightning_blade_update` (`0x008E6260`) has an exact
attacker-ID-8 branch that selects `OBJ_2cmn00t0 r_hand`
(`0x0093E6A0`). `lightning_blade_contact_response`
(`0x008E59B0`) changes state, clears children, emits sound and
handles guarded/ordinary contact damage. `lightning_blade_destroy`
(`0x008E5720`) cleans both participants, players, renderer,
children and resource handles before deleting the actor.

`lightning_blade_enter_state` (`0x008E6DF0`) and
`lightning_blade_state_update` (`0x008E64C0`) run these states:

| State | Behavior |
| ---: | --- |
| 0 | Startup dialogue; the first scene event starts charging. |
| 1 | Charge: sound `0x86`, charge rates `0x00927DD8`; charge level from `lightning_blade_charge_levels` (`0x00927DB0`), `[0,0.5]`, `[0.5,0.8]`, `[0.8,1]`, rebinds the effect player. Release starts state 3. |
| 3 | Dash: sound `0x29`, dash player, dialogue, contact row 1 or 2 for levels 2/3 (begin already prepared row 0). It lasts `lightning_blade_dash_durations` (`0x006A23C8`), 3 updates for resources 11/53, 8 for 3/89, then a miss scales `+0x5EC` by 0.1 and enters 5. |
| 4 | Hit: participant scene and camera; after 30 updates (times the attacker's `+0x198` rate while the opponent has effect `0x24`) it publishes contact row 3 and enters 5. |
| 5 | Release participants, then 6 or 7 by a grounded test. |
| 6, 7 | Wind-down players 7/8 until the actor ends. |

A contact in state 3 enters state 4 unless the defender guards or is
in response `(5,0x4B)`; then it deals row 3's factor × action damage
× 0.5 and enters 5. `kakashi_lightning_blade_contact_definitions`
(`0x0092075C`) has four rows, category `0x80000`, response
selector `0x10` (NA2 `0x12`, see
[move correspondence](#complete-authored-move-correspondence)):
rows 0..2 have damage factor 0 and row 3 has 1.0.
`OBJ_2cmn00t0 r_hand` (`0x006A23C0`) is the effect node for
resources 11 and 53.

NA2 keeps this class as `ccSkillANB000`. `anb_setup`
(`0x008085E0`) still has arms for resources 11 and 53 with the same
name banks (`0x008B5630`, `0x008B52F0`); `anb_update`
(`0x00808F20`) and `skill_anb000_damage` (`0x00808200`) run the
same states, with NA2's guard response `(5,0x4F)` and opponent effect
`0x4A` within 400 units. NA2's resource-11 rows
(`skill_anb_descriptor_11`, `0x008A8688`) carry the translated
selector `0x12` and row-3 factor 1.2; resource 53 keeps 1.0. NA2's hand-node branch tests
fighter ID 8 or 70. For every resource, NA2 also tests the attacker's
movement segment against stage collision
(`anb_dash_stage_collision`, `0x0080B120`) during the dash
and enters state 5 on a hit; UN3's two state routines have no such test.
[`ccSkillANB000`](../../session/battle_entities.md#ccskillanb000-creation-and-destruction)
owns the NA2 factory and selector joins.

Native's first actor is RTTI `ccSkillKKW000`; its constructor calls
`skill_tyo_base_construct` (`0x00797250`) and installs interface
`+0x110` vtable `0x005EFFD0`. Its second is the existing
`ccSkillANB000` actor, interface vtable `0x005EB610`, the NA2 form of
donor Lightning Blade described above. `ccSkillKKW000` is built on a
different base than `fanged_pursuit_base_construct`, and NA2's
`skill_factory_table` (`0x008CD1F0`) arms for resources 10 and 54 only
store to address 0, so NA2 has no Fanged Pursuit or Young Fang class.

### Body, eye and common dependencies

Donor `2KKSBOD1` has 109 animations, versus native `2KKWBOD1`'s 114;
`2KKSCHA0/1` have 6/14, versus native `2KKWCHA0/1`'s 6/13.
The donor body and CHA1 mark the four common-2
`OBJ_2cmn00t0 muffler,muffler1,muffler2,muffler3` names absent
from the checked NA2 common provider; CHA1 rows are 206/208/210/212.
CHA0 also marks common-1 `joe01` (row 111) and `cloth3`
(row 406), absent from the checked NA2 common provider.
These donor common objects are real dependencies, not own `kks` filenames.

The marked `OBJ_ekkskiseki0` animation target in CHA0 belongs
to the donor battle body, with the established object → model → material
→ texture → palette chain under
[Marked character-reference consumers](../un3_un4_characters.md#marked-character-reference-consumers).
The eye file marks `1KKSBOD1` providers; its texture directory contains
`TEX_1kkseye1, TEX_1kksmou1, TEX_w1kn0body`.
`3KKS3PCT` has only `TEX_sp_kks`; the directory supplies no
`TEX_name*` mode-name texture. Cinematic `1KKSBOD2` and Guy body
dependencies are owned by
[Kakashi cinematics](#cinematics).

Every Kakashi and ANBU donor file (bodies, CHA, eye, portrait and all
ten film files) has container version `0x123`, NA2's own, so NA2 takes
the same version branches. Against the
[parser differences](../../../game/files/ccs_runtime.md#un3s-parser-compared-with-na2s):
every ordinary image's declared pixel words equal its storage size, so
NA2 keeps all of them; no file has a `0x0D90` generator; and NA2's
ordinary-model `0x804` trap cannot be reached, because
`ccs_parse_model` sets bit `0x800` for no file flag and bit 4 only
for packed models. The extra UN3 list-link word is runtime state, not
file data. NA2 therefore reads these files as UN3 does; the missing
common objects above are the only unresolved bindings.
Files load where their roles load: bodies and eye files with the
battle character, CHA files with their jutsu resource, and film
files through `sp_skill_build_requests` for the film's duration.

## Callbacks

This comparison checks UN3 Kakashi Hatake **ID 8, `kks`** against
retail NA2 Kakashi **ID 70, `kkw`**. The concrete fighter and action
roots are owned by
[Character assets](#records-moves-and-assets).

The donor callback table `0x003AA360` is
`{0,1E41E0,1E4260,1E44F0,0,0,0}`.
Native's `0x005208D0` is
`{0,2C7540,2C7600,2C7E90,2C8070,0,0}`.
Slot 3 is the source-selected hit-response callback, not channel 4;
native additionally owns a channel-5 callback.

Donor `kakashi_channel2` (`0x001E41E0`) runs in phase 1 of the
held-up state `(0,3)`. It calls `fighter_convert_chakra_to_hp`
(`0x001B89A0`) in mode 1: each update, unless HP is full, effect
flag `0x40` is active or chakra is empty, it spends 0.0333 chakra
and adds 1/1800 of full HP, with an effect and sound every 36 updates.

Donor `kakashi_channel3` (`0x001E4260`) has the following
code-authored events, with hexadecimal action indices:

| Action / phase | Timeline condition | Event |
| --- | --- | --- |
| `0x19 / 0` | secondary event 14 | sound 18 |
| `0x19` | primary interval 15..28 | eight particles, scale 10, owner position/orientation and `particle_colour & 0xF0F0F0` |
| `4 / 1` | event 6 / 9 | compact voice 6 / sound 29 |
| `5 / 1` | event 6 | compact voice 7 / sound 26 |
| `6 / 1` | event 9 | compact voice 8 / sound 23 |

Donor `kakashi_hit_response` (`0x001E44F0`) returns response
`0x36` for action `0x1A` with receiver coefficients
`1,0.35,1.5`, and for action `0x1E` with repeat value below 2
with `1,0.2,1.15`. Action `0x1B` with repeat value above 1
selects `0x27` for a grounded receiver and `0x2E` otherwise. Coefficient
stores occur only in callback mode 2; the ordinary default is `-1`.

The receiver flag is byte `+0x63` bit `0x20`, UN3's grounded bit
(set by `fighter_set_action_state` and `fighter_apply_movement`).
NA2 keeps that byte as `contact_flags` but marks grounded with `0x80`
and uses `0x20` as its awakening controller marker.
The repeat value comes from `fighter_action_repeat_for_receiver`
(`0x001C0770`): with no current major-8 action record it is 0; when
the receiver already retains this source action it is
`receiver_retained_hit_count` (`0x001B3630`), the receiver's positive
counter `+0xD7C` (1 while `+0xA50` is set); otherwise it is the
action's authored repeat count `+0x2E`.

Response numbers are major-5 substates. UN3's
`response_motion_table` (`0x00389550`) has 50 rows, `0x27..0x58`;
NA2's (`0x00407670`) has 54, and every UN3 row occurs unchanged in
NA2's, which adds rows `0x2D/0x2E`, `0x41` and `0x47`. A UN3 response
therefore names NA2 response:

| UN3 substates | NA2 substate |
| --- | --- |
| `0x27..0x2C` | same |
| `0x2D..0x3E` | UN3 + 2 |
| `0x3F..0x43` | UN3 + 3 |
| `0x44..0x58` | UN3 + 4 |

Kakashi's `0x27/0x2E/0x36` become NA2 `0x27/0x30/0x3A`
(`ACT_DMG_NSH/NAM/DDS`), and the guard test `(5,0x4B)` in
Lightning Blade becomes NA2's `(5,0x4F)`, as `ccSkillANB000` has it.

Native `kakashi_channel2` (`0x002C7540`) is gated on actual ID 70.
Its controller marker `0x20` selects
`kakashi_swap_mode_actions` (`0x002C6700`) mode 1;
marker absence restores mode 0 when `+0x584C == 1`.
The action-progress predicate `(1,0x1E,1)` also invokes the overlay
presentation routine `gaara_variant_presentation` (`0x0071EF70`).

`kakashi_swap_mode_actions` operates on the same fighter.
Mode entry saves animation slots `0x4A..0x4D`, clears them and
places slot `0x66` in `0x4D`; it also saves/clears action 2's
category. Exit restores those values. Both directions assign action
3 category zero and action `0x15` category `0x80000`, then swap
the complete action 3/`0x15` records. A mode change away from an
already active mode is deferred while the current action is 1.
These are native's ordinary/Sharingan action banks, not donor's
opponent-bank effect mechanism.

Native `kakashi_channel3` (`0x002C7600`) additionally handles
actions `0x17,19,1A,1B,1C,1D,20,21,22,24`: timeline gates update
motion, effect/rejection state, transforms and relative positioning.
Its shared UJ actions 4/5/6 emit voice 6/7/8.
Native `kakashi_channel5` (`0x002C8070`) invokes a private helper
under active/side flags; no corresponding donor callback slot exists.

Native `kakashi_hit_response` (`0x002C7E90`) has return set
`{-1,0x2A,0x2C,0x3C}`: action `0x24`, repeat >1 selects
`0x2C` and planar factor 0.5; action `0x22`, repeat 1 selects
`0x3C`; `0x1D` writes planar/vertical 0.6/1.2; `0x1C`,
repeat >1 writes planar 0.2; `0x17`, repeat >1 selects `0x2A`.
Factor writes again require mode 2. Numeric donor/native response
values belong to their own game's response domains.

## Ultimate Jutsu and effects

Checked identities are UN3 Kakashi Hatake **ID 8, `kks`** and
retail NA2 Kakashi **ID 70, `kkw`**.
Donor `kakashi_ultimate_jutsu_list` (`0x0047B400`) contains
13 local records, indices 96..108; its character-list pointer is
`0x0047B780`. `kakashi_ultimate_jutsu_records`
(`0x004D9160`) uses `0x24`-byte records.
The `ability_count/ability_ids` fields are acquisition prerequisites,
not NA2's category byte. `character_ultimate_default_record`
(`0x0027BED0`) selects the mode-1 table only for mode 1; mode -1
reads the manager's mode at `+0x58`. Kakashi's normal default
`0x0047BD60` is record **98**, Lightning Blade Single Slash;
mode-1 default `0x0047BDE0` is record **96**, The Origin of its Name.

`ultimate_jutsu_record_abilities_available` (`0x0028B830`) admits a
normal-default record without prerequisite checks when its third argument
is zero. Otherwise the whole-record query checks all three stored ability
IDs and requires the successful count to equal `ability_count`; an
individual query checks the selected prerequisite. A missing manager or
record -1 rejects. The mode-1 companion uses ability-reader argument 1
instead of 0.

| Records | Checked English title family | Authored skill | Prerequisite IDs | Intro | Damage percent |
| --- | --- | --- | --- | ---: | ---: |
| 96,100,103,106 | The Origin of its Name, then 2/3/4 | `0x30` | `5` | 46 | 20 |
| 97,101,104,107 | Lightning Blade Double Charge, then 2/3/4 | `0x31` | `5,4,0x56` | 47 | 25 |
| 98,102,105,108 | Lightning Blade Single Slash, then 2/3/4 | `0x32` | `5,0x60` | 48 | 30 |
| 99 | Eternal Rivals | `0x33` | `0x8C` | 49 | 40 |

All thirteen select effect **`0x15`**. In stored six-halfword order,
the stat arrays are:
96 `[0,0,0,0,0,0]`, 97 `[0,0,0,10,0,0]`,
98 `[10,0,0,20,0,0]`, 99 `[20,0,0,10,0,0]`,
100 `[0,0,0,10,0,0]`, 101 `[10,0,0,10,0,0]`,
102 `[20,0,0,20,0,0]`, 103 `[0,0,0,20,0,0]`,
104 `[10,0,0,20,0,0]`, 105 `[20,0,0,30,0,0]`,
106 `[0,0,0,30,0,0]`, 107 `[20,0,0,20,0,0]`,
108 `[20,10,0,30,0,0]`.
Their only reader, through `ultimate_jutsu_record_stat_adjustment`
(`0x0028BD00`), is `ultimate_menu_stat_digits` (`0x002C5650`),
which draws them as signed digits; they change no battle value.
The numbered variants of one film share skill, intro, damage and
effect, so in battle they behave the same.

Native `kakashi_ultimate_record_list` (`0x006044A8`),
character pointer `0x005AD0C8`, contains three indices 154..156.
Native default entry `0x005AFE3C` selects record **154**.
Their `0x14`-byte records start at `0x005AF848`:

| Record / title | Skill | Category / class / cost tier | Intro / secondary | Effect | Damage percent |
| --- | --- | --- | --- | --- | ---: |
| 154, `雷切・一尖` | `0x7D` | 3 / 3 / 2 | 133 / -1 | `0x49` | 40 |
| 155, `土遁・裂穿牙` | `0x7E` | 2 / 3 / 0 | 134 / -1 | `0xFFFF` | 25 |
| 156, `コピー忍術` | `0x7F` | 1 / 3 / 1 | 135 / -1 | `0xFFFF` | 35 |

The checked UN3 `ultimate_jutsu_record_form` (`0x0028BFF0`)
maps only effects `0x3D..0x46` to replacement IDs 47..56.
Donor `0x15` therefore returns form zero in this UJ completion route.
Native `0x49` also retains ID 70. Its in-place bank change is owned by
[Kakashi callbacks](#callbacks).

Donor `status_effect_bind_factories` (`0x00231530`) installs
the pair `{0x15,kakashi_effect_create}` at `0x00473D28`.
`effect_list_add` (`0x00231F60`) uses that `0xC0` factory
(`0x001E3E80`), `kakashi_effect_construct`
(`0x001E3EE0`) and vtable `0x00689650`.
`kakashi_effect_payload` (`0x00474664`) stores lifetime
**1350**, flags **2**, and leading seven factors
**1.5,1.1,1.1,1,1.2,1,1**.
Native effect `0x49` factory anchor `0x0059FF28` instead stores
lifetime **600**, flags **2**, and **1.2,1.1,1.1,1,1.1,1,1**.

`fighter_status_effect_construct` (`0x002316C0`) copies the record
into the node, and the UN3 reducers read the same node fields as NA2's:
attack 1.5 (`effect_attack_factor`, summed and capped at 2.0), defense
input 1.1 (`effect_defense_factor`, read by `damage_calculate`), action
rate 1.1 (`effect_action_rate_factor`), jump factor 1.0, `+0x84`
factor 1.2 (`effect_payload_84_factor`, read by
`response_motion_update` and four movement routines), HP and chakra
recovery 1.0. The record's chakra word is **15**, which construction
adds through `fighter_apply_effect_chakra_delta` when the effect
starts; it has no HP delta.

Donor construction invokes `fighter_activate_borrowed_action_bank`
(`0x002340F0`). For an admitted opponent identity from fighter
`+0x20`, `fighter_copy_borrowed_action_bank`
(`0x00233EC0`) copies that fighter's baseline pointers/counts,
selectors and eight handle entries into Kakashi's current bank.
It recreates the auxiliary handle, clamps the count and sets fighter
`+0x62` bit `0x40`; the per-side match flag is also set.
The excluded source IDs are
`0x04,0x11,0x12,0x1D,0x23,0x25,0x26,0x27,0x28,0x2A,0x2B,
0x2F,0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38`: classic Gaara,
Shino and Kankuro, filler row 29, Kidomaru, Sakon, Kimimaro, Minato,
Konohamaru, Hashirama, Tobirama and all ten transformed forms 47..56.
These IDs name the same characters in NA2
([UN3 ID lineage](../character_ids.md#un3-id-lineage)); NA2's IDs 57..93
did not exist in UN3 and have no donor rule.

The copied fields are the action array pointer and count, the
`jutsu_selector` pair at `+0x178` (`+0x17C/+0x17E` only when the
source's value there exceeds 3), the counts at `+0xA9C..+0xAA4`, the
input parameter block at `+0xA6C`, which `input_params_template`
then resets to its hold/multi-press defaults, and the eight handles at
`+0xDA4`. Kakashi therefore runs the opponent's own action records
and jutsu selectors; the auxiliary helper at `+0x8A0` is
rebuilt from the opponent's `+0xD0/+0xD4` descriptor list against the
opponent's `+0xD84` collection. For an excluded opponent nothing is
copied, but the effect's factors and chakra still apply.
`kakashi_effect_destroy` (`0x001E3F40`) calls
`fighter_deactivate_borrowed_action_bank` (`0x002342F0`):
restore own bank, current-action-specific descriptor/reset work,
auxiliary reconstruction, clear bit `0x40` and side flag, then
common effect cleanup/deletion. No replacement fighter is constructed here.

Entry: `jutsu_post_cinematic_update` calls `effect_apply_outcome`
only when the defender survives the film's damage. With record flags
2, `fighter_status_effect_add` (`0x002326B0`) adds the effect to
Kakashi only (flag 4, absent here, would also add it to the opponent).
Every removal of the node runs `kakashi_effect_destroy`: expiry after
1350 updates, replacement by a new effect `0x15`, and bulk cleanup.
Restoration resets Kakashi to state `(0,0)` when he is in state
`(0,3)` or `(0,4)` (`fighter_state_is`, `0x001A8DD0`), and rebinds
his own first action record when his major state is 8.

## Cinematics

Checked identities are UN3 Kakashi Hatake **ID 8, `kks`** and
retail NA2 Kakashi **ID 70, `kkw`**.
Local record selection, damage and effects are owned by
[Kakashi UJ/effects](#ultimate-jutsu-and-effects).
The UN3 request-row and playback contract is established under
[UN3 Guy cinematic requests](guy.md#cinematics);
Eternal Rivals is the same shared skill `0x33` in both lists.

`kakashi_cinematic_requests` (`0x00670500`) contains four
`0x14`-byte rows for skills `0x30..0x33`:

| Skill / row | Resident main / stream | Explicit extra resident paths | Camera directory ID | Marked stream / main keys |
| --- | --- | --- | ---: | ---: |
| `0x30 / 0x00670500` | `str/d08_101e.ccs / str/d08_101.ccs` | none | 786 | 180 / 6 |
| `0x31 / 0x00670514` | `str/d08_201e.ccs / str/d08_201.ccs` | none | 781 | 182 / 8 |
| `0x32 / 0x00670528` | `str/d08_301e.ccs / str/d08_301.ccs` | `1kksbod2.ccs` | 1734 | 173 / 3 |
| `0x33 / 0x0067053C` | `str/d08_401e.ccs / str/d08_401.ccs` | `1kksbod1.ccs,1kksbod2.ccs,1guybod1.ccs` | 832 | 252 / 3 |

Every camera entry is `CAM_camera01`. No `BIN_` directory name
occurs in these eight files; embedded commands and code-selected data
are separate from that name census.

**Clean-file observation:** each marked namespace/name key in all eight
files has a non-carrier typed definition against its matching film pair
plus donor `1CMNBOD1,1KKSBOD1,1KKSBOD2,1GUYBOD1,STRMCMN`
and `CMN/EFFECT0X`. Matching strips only the leading `#`.
All eight missing-key lists are empty. The two sampling keys in
`D08_201E` (ID 315) and `D08_301E` (ID 335) resolve to
`CMN/EFFECT0X` texture definition ID 2189 at decompressed
`0x1027CC`, not a local image block in those companions.
The four stream common-1 `joe01/cloth3` keys also require donor
providers absent from the checked NA2 common file. How NA2 reads
these files is under [Kakashi body dependencies](#body-eye-and-common-dependencies).

The selected `kakashi_cinematic_auxiliary_entries`
(`0x0047C308`) contain pointers
`0x006A0FC4/C8/CC/D0`, whose data are
`0x00546030,0x00548AA0,0x0054A2D0,0x0054C0F0`.
These are scene/renderer auxiliary data, not audio cue rows.
`kakashi_cinematic_defender_position_entries`
(`0x0047CA18`) select one placement descriptor per skill. Each is a
count, a frame-threshold list and a pointer per UN3 defender ID 0..56
(ID 0 null) to that many signed XYZ halfword triples;
`sp_skill_play_update` (`0x00294F10`) translates the defender by the
triple of the current threshold interval.

| Skill | Placement descriptor | Frame thresholds | Camera reject range | Palette records |
| --- | --- | --- | --- | --- |
| `0x30` | `kakashi_origin_defender_positions` `0x005C7D60` | 1, 189, 241 | 80..92 | `1kksbod1` |
| `0x31` | `kakashi_double_charge_defender_positions` `0x005C8560` | 1, 139, 202 | none | `1kksbod1` |
| `0x32` | `kakashi_single_slash_defender_positions` `0x005C89D0` | 1, 211 | none | `1kksbod2` |
| `0x33` | `eternal_rivals_defender_positions` `0x005C91D0` | 1, 210, 249, 296 | none | `1kksbod2`, `1guybod1` |

In skill `0x30` the triples are small per-defender corrections within
-140..+32 units, mostly on one axis. The camera reject range
(`kakashi_origin_camera_reject_ranges`, `0x00512470`) only applies to
defender IDs `0x23,0x30,0x32,0x33,0x35,0x38`, through
`sp_skill_defender_camera_admission` (`0x00294770`).
`sp_skill_apply_appearance_substitutions` (`0x00294CF0`) applies the
palette records (`kakashi_cinematic_palette_record_lists`,
`0x0047CEB0`) when the attacker's appearance flags include 1 or 4:
each record names a body container, its `EXT_` body object and the
`CLT_...bodyc1`/`c2` palette chosen by flag 1 or 4. None of the four
skills has a timed command script, and none is among the stream codes
that swap material palettes. `sp_skill_play_begin` also binds the
defender's common eye/mouth materials by defender ID.

None of the eight Kakashi film files contains a queued tag-`0x0108`
command or an audio section. Film damage, soundtracks and cue rows
follow [UN3 cinematic damage and audio](itachi.md#un3-cinematic-damage-and-audio).
Kakashi's `skill_cinematic_cue_descriptors` entries select these
stereo 48,000 Hz `STREAM.AFS` soundtracks and defender cue rows, all
with request ordinal 1:

| Skill | Cue rows | Soundtrack member EN / JP (file offset) | Length | Cue rows: frame / control |
| --- | --- | --- | --- | --- |
| `0x30` | `0x00386C30` | 47 (`0x01A2C000`) / 187 (`0x06C65000`) | 10.03 s | 81/`0x0C`, 142/`0x11` |
| `0x31` | `0x00386C60` | 48 (`0x01AB0800`) / 188 (`0x06CE9800`) | 12.03 s | 140/`0x0F`, 255/`0x11` |
| `0x32` | `0x00386C90` | 49 (`0x01B4F800`) / 189 (`0x06D88800`) | 11.37 s | 140/`0x11` |
| `0x33` | `0x00386CB0` | 50 (`0x01BE5800`) / 190 (`0x06E1E800`) | 13.03 s | 298/`0x11` |

Eternal Rivals' row is shared with Guy. The startup intros are in
[Kakashi voice](#kakashi-ultimate-jutsu-intro-members).

Native's relocated SINF rows are in clean `STRMCMN.CCS`,
`BIN_strtbln4`, block `0x68E70`, payload `0x68E7C`.
`sp_skill_relocate_request_table` (`0x00357B10`) establishes
the string decode/relocation and `0x18`-byte row layout.
The checked native skills select:

| Skill / decoded title | Resident main / stream | Extra resident paths | Appearance rows |
| --- | --- | --- | ---: |
| `0x7D`, `雷切・一尖` | `str/d70_10e.ccs / str/d70_10.ccs` | `pl/1kkwbod2.ccs` | 0 |
| `0x7E`, `土遁・裂穿牙` | `str/d70_20e.ccs / str/d70_20.ccs` | none | 0 |
| `0x7F`, `コピー忍術` | `str/d70_25e.ccs / str/d70_25.ccs` | `pl/1kkwbod2.ccs,pl/2kkwbod1.ccs` | 5 |

Each native row requests one stream. These native request families
are distinct from all four donor pairs; title resemblance does not
establish film identity. The native Copy Ninjutsu request has explicit
appearance rows as well as two extra bodies.
Intro voice belongs to [Kakashi voice](#voice).

## Voice

Checked identities are UN3 Kakashi Hatake **ID 8, `kks`** and
retail NA2 Kakashi **ID 70, `kkw`**.
The shared synthesizer lookup is owned by
[Compact program-to-VAG lookup](../../session/battle_audio.md#compact-program-to-vag-lookup).
The following offsets identify source-file bytes in `DATA/SNDDATA.BIN`,
not live IOP addresses.

| Bank / resident descriptor | Header offset / bytes | Sample offset / bytes |
| --- | --- | --- |
| UN3 English / `kakashi_compact_bank_english 0x003882F0` | `0x0058C000 / 0x13B0` | `0x0058D800 / 0x4E9E0` |
| UN3 Japanese / `kakashi_compact_bank_japanese 0x0038859C` | `0x01680800 / 0x13B0` | `0x01682000 / 0x53950` |
| NA2 / `kakashi_compact_bank 0x003FDB78` | `0x01151800 / 0xF60` | `0x01152800 / 0x2F440` |

UN3's descriptor selector `0x00185A30` uses
`0x00388290+ID*12+0x2AC*alternate_voice_set`.
The donor's two banks both have inclusive Prog/Sset/Smpl/Vagi maxima
`55/40/40/39`; native has `40/28/28/28`.
The voice-event list pairs `0x00389168` and `0x00406F08`
both select the same checked 33-halfword base list.
This is event-index agreement, not sample-content agreement.

For compact key **60**, the following entries each select one candidate,
with key interval 12..119, Sset and Smpl velocity intervals 1..127,
and sample rate 22050. Triples are `Sset/Smpl/Vagi`.

| Program | Donor English triple / sample offset | Donor Japanese triple / sample offset | Native triple / sample offset |
| ---: | --- | --- | --- |
| 0 | `0/0/13 / 0x005A5540` | `0/0/12 / 0x0169DD80` | `0/0/3 / 0x011580A0` |
| 5 | `5/5/18 / 0x005A8DD0` | `5/5/17 / 0x016A18B0` | `5/5/8 / 0x0115C380` |
| 6 | `6/6/10 / 0x0059C240` | `6/6/10 / 0x01695F20` | `6/6/0 / 0x01152800` |
| 7 | `7/7/11 / 0x0059ED50` | `7/7/11 / 0x01698660` | `7/7/1 / 0x01154240` |
| 8 | `28/28/12 / 0x005A3A70` | `8/8/39 / 0x016D4C20` | `8/8/2 / 0x01156350` |
| 15 | `15/15/31 / 0x005CA470` | `15/15/30 / 0x016C3370` | `12/12/20 / 0x01173750` |
| 18 | `18/18/25 / 0x005C2490` | `18/18/24 / 0x016BCAB0` | `15/15/14 / 0x0116A4E0` |
| 26 | `26/26/39 / 0x005D84B0` | `26/26/38 / 0x016D05A0` | `23/23/28 / 0x0117F1D0` |
| 27 | `27/27/19 / 0x005A9C20` | `27/27/18 / 0x016A2640` | no candidate |

Donor `audio_emit_fighter_voice_control` (`0x00186460`)
indexes the `0x00385440` control table, with default key at control
`+3`. Control 27 has program 27, while native control 27
(`0x003FC428`) has signed program `-1` and is disabled.
Donor event `0x19` maps to that control; its particular producers
are not all established here. UJ startup action callbacks emit controls
6/7/8, as recorded in
[Kakashi callbacks](#callbacks).

UN3's streamed PLVOICE banks remain the separately established
outer **7/63**, handles **77/133**, each **213 slots / 80 populated**.
The complete sparse member set and selected physical members 6/45 are
owned by
[Checked UN3 streamed descriptors](../un3_un4_characters.md#checked-un3-streamed-descriptors-and-members).
Native ID 70's outer **69** starts at file offset **`0x00D39800`**,
size **350208**, with **44/44** members.
These physical banks cannot be joined by compact program or equal logical
member alone.

Lightning Blade's spoken cues go through `dialogue_voice_produce`
(`0x0086B100`) with `dialogue_voice_rows` (`BATTLE 0x0093D3D0`) row 11,
`{37,36,36,36}`; the cue is the physical PLVOICE member of the
performer's bank. State 0 emits index 1 (member 36) and state 3 index 0
(member 37). Fanged Pursuit uses only the compact controls 22 and 8
listed above.

| PLVOICE member | Outer 7 offset / bytes | Outer 63 offset / bytes |
| ---: | --- | --- |
| 36 | `0x0039E800 / 14311` | `0x01552000 / 12101` |
| 37 | `0x003A2000 / 8808` | `0x01555000 / 5759` |

The win end demo, `end_demo_update` (`0x002E2120`), plays one random
member of Kakashi's `end_demo_quote_lists` (`0x0047F140`) entry, SOUND
members 34..38 from outer 2, or outer 16 for Japanese voices:

| Member | Outer 2 offset / bytes | Outer 16 offset / bytes |
| ---: | --- | --- |
| 34 | `0x11EFC000 / 18993` | `0x25144800 / 22844` |
| 35 | `0x11F01000 / 27037` | `0x2514A800 / 19578` |
| 36 | `0x11F08000 / 22719` | `0x2514F800 / 19791` |
| 37 | `0x11F0E000 / 17881` | `0x25154800 / 19023` |
| 38 | `0x11F12800 / 21075` | `0x25159800 / 18518` |

### Kakashi Ultimate Jutsu intro members

Donor `ultimate_jutsu_presentation_update` (`0x002E36D0`)
calls `audio_request_sound_member_for_voice_set`
(`0x0018A1C0`) with bank 9, the record intro and mono slot 0.
Language selection adds 14, giving SOUND family 0 outer **9/23**.
Their descriptor/count/range identities are already recorded in
[Guy intro archive](guy.md#guy-ultimate-jutsu-intro-archive).
Kakashi's selected intro members are:

| Member | English absolute SOUND offset / bytes | Japanese absolute SOUND offset / bytes |
| ---: | --- | --- |
| 46 | `0x12E0D000 / 26253` | `0x26175000 / 20215` |
| 47 | `0x12E13800 / 26280` | `0x2617A000 / 20215` |
| 48 | `0x12E1A000 / 12891` | `0x2617F000 / 17133` |
| 49 | `0x12E1D800 / 15510` | `0x26183800 / 18740` |

Native `jutsu_presentation_update` requests SOUND bank 7/slot 0
at `0x00769F28..0x00769F30`; descriptor
`ultimate_jutsu_sound_archive_descriptor` (`0x003FDD08`)
declares 189 members. Physical outer 7 starts at `0x08226000`,
size 3086336. Selected members 133/134/135 occur at
`0x0840C000 / 10864`, `0x0840F000 / 11186`,
`0x08412000 / 23899`.
These intros are SOUND members, separate from the character PLVOICE bank
and from the film soundtracks listed under [Kakashi cinematics](#cinematics).
