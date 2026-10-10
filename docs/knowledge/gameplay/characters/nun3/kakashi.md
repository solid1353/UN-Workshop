# Kakashi: NUN3 donor

## Research coverage

Established for NUN3 Kakashi 8 against NA2 Kakashi 70: 46/178/154 against
48/186/157 actions/rows/names with equal stored base parameters but different
chains and callbacks; Fanged Pursuit against Lightning Blade Drop; differing
Lightning Blade actors; thirteen Ultimate Jutsu records selecting four films;
effect `0x15`'s borrowed opponent bank; typed providers; compact, PLVOICE and
intro voices.
Open: Fanged Pursuit and the shared Lightning Blade executable closure, the
borrowed-bank effect, input and callback semantics, typed asset lifetime, film
conversion, remaining voices and ID-dependent services.

Names come from `@annotations/NUN3` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [NUN3 and NUN4 characters](../nun3_nun4_characters.md).

## Records, moves and assets

Checked identities: NUN3 Kakashi Hatake **ID 8, `kks`**, resident
`SLUS_217.27` and `BATTLE.BIN`; retail NA2 Kakashi **ID 70
(`0x46`), `kkw`**, resident `SLPS_258.37` and `BTL.BIN`.
NA2's vacated ID 8 does not identify its playable Kakashi.
Complete clean-file identities are in
[Kakashi inputs](../../../game/files/file_identities.md#kakashi-comparison-inputs).

### Definitions, construction and ID services

| Root | NUN3 ID 8 | NA2 ID 70 |
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
`kakashi_ai_update` (`0x001E41A0`) calls NUN3 `ai_tick`
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
equal attacks. Callback and mutable-bank behavior is owned by
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
The inherited begin binds attacker/opponent animations and positions,
borrows the indexed resource/container and installs participant callbacks.
`kakashi_fanged_pursuit_begin` (`0x008C8690`) selects the
two attacker/one defender names and callback pair through GP-relative data.
`kakashi_fanged_pursuit_frame_events` (`0x008C86F0`) creates
a transient resource on frame 1. Its `kakashi_fanged_pursuit_event_rows`
(`0x00926290`) are `{50,21},{85,8}`; sound rows
(`0x009262A0`) are `{15,14},{20,111},{30,111},{50,13},
{85,134},{90,134},{104,135}`.
`kakashi_fanged_pursuit_restore_participants` (`0x008C8920`)
restores both participant subobjects.

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

Native's first actor is RTTI `ccSkillKKW000`; its constructor calls
`skill_tyo_base_construct` (`0x00797250`) and installs interface
`+0x110` vtable `0x005EFFD0`. Its second is the existing
`ccSkillANB000` actor, interface vtable `0x005EB610`.
Neither actor is established as equivalent to donor Fanged Pursuit.
Retained low-number legacy selector/resource slots do not identify native
Kakashi's selected jutsu.

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
[Marked character-reference consumers](../nun3_nun4_characters.md#marked-character-reference-consumers).
The eye file marks `1KKSBOD1` providers; its texture directory contains
`TEX_1kkseye1, TEX_1kksmou1, TEX_w1kn0body`.
`3KKS3PCT` has only `TEX_sp_kks`; the directory supplies no
`TEX_name*` mode-name texture. Cinematic `1KKSBOD2` and Guy body
dependencies are owned by
[Kakashi cinematics](#cinematics).

## Callbacks

This comparison checks NUN3 Kakashi Hatake **ID 8, `kks`** against
retail NA2 Kakashi **ID 70, `kkw`**. The concrete fighter and action
roots are owned by
[Character assets](#records-moves-and-assets).

The donor callback table `0x003AA360` is
`{0,1E41E0,1E4260,1E44F0,0,0,0}`.
Native's `0x005208D0` is
`{0,2C7540,2C7600,2C7E90,2C8070,0,0}`.
Slot 3 is the source-selected hit-response callback, not channel 4;
native additionally owns a channel-5 callback.

Donor `kakashi_channel2` (`0x001E41E0`) calls an auxiliary
motion/presentation helper at `0x001B89A0` when the action predicate
`(owner,0,3)` and phase 1 both hold. The helper arguments include
float words `0x3A11A2B4/0x3D088889`; their full meaning is not assigned.

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
selects `0x27/0x2E` by a receiver flag. Coefficient stores occur
only in callback mode 2; the ordinary default is `-1`.
The receiver-flag meaning and repeat helper's full semantics remain open.

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
Complete indirect descendants of these native helpers remain open.

Native `kakashi_hit_response` (`0x002C7E90`) has return set
`{-1,0x2A,0x2C,0x3C}`: action `0x24`, repeat >1 selects
`0x2C` and planar factor 0.5; action `0x22`, repeat 1 selects
`0x3C`; `0x1D` writes planar/vertical 0.6/1.2; `0x1C`,
repeat >1 writes planar 0.2; `0x17`, repeat >1 selects `0x2A`.
Factor writes again require mode 2. Numeric donor/native response
values belong to their own game's response domains.

## Ultimate Jutsu and effects

Checked identities are NUN3 Kakashi Hatake **ID 8, `kks`** and
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
instead of 0. The higher availability wrappers and ability-state meanings
remain open.

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
Their consumer meanings are not assigned by this stored-array comparison.

Native `kakashi_ultimate_record_list` (`0x006044A8`),
character pointer `0x005AD0C8`, contains three indices 154..156.
Native default entry `0x005AFE3C` selects record **154**.
Their `0x14`-byte records start at `0x005AF848`:

| Record / title | Skill | Category / class / cost tier | Intro / secondary | Effect | Damage percent |
| --- | --- | --- | --- | --- | ---: |
| 154, `雷切・一尖` | `0x7D` | 3 / 3 / 2 | 133 / -1 | `0x49` | 40 |
| 155, `土遁・裂穿牙` | `0x7E` | 2 / 3 / 0 | 134 / -1 | `0xFFFF` | 25 |
| 156, `コピー忍術` | `0x7F` | 1 / 3 / 1 | 135 / -1 | `0xFFFF` | 35 |

The checked NUN3 `ultimate_jutsu_record_form` (`0x0028BFF0`)
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
Stored factor differences do not establish all gameplay consumers.

Donor construction invokes `fighter_activate_borrowed_action_bank`
(`0x002340F0`). For an admitted opponent identity from fighter
`+0x20`, `fighter_copy_borrowed_action_bank`
(`0x00233EC0`) copies that fighter's baseline pointers/counts,
selectors and eight handle entries into Kakashi's current bank.
It recreates the auxiliary handle, clamps the count and sets fighter
`+0x62` bit `0x40`; the per-side match flag is also set.
The excluded source IDs are
`0x04,0x11,0x12,0x1D,0x23,0x25,0x26,0x27,0x28,0x2A,0x2B,
0x2F,0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38`.
These are donor identity values, not native ID exclusions.
`kakashi_effect_destroy` (`0x001E3F40`) calls
`fighter_deactivate_borrowed_action_bank` (`0x002342F0`):
restore own bank, current-action-specific descriptor/reset work,
auxiliary reconstruction, clear bit `0x40` and side flag, then
common effect cleanup/deletion. No replacement fighter is constructed here.

This establishes a temporary borrowed action-bank lifetime. Admission,
every copied-bank consumer and the meanings of the copied selector/handle
fields remain bounded open questions. The checked UJ form getter and
these effect methods do not establish every independent form/availability
service in either game.

## Cinematics

Checked identities are NUN3 Kakashi Hatake **ID 8, `kks`** and
retail NA2 Kakashi **ID 70, `kkw`**.
Local record selection, damage and effects are owned by
[Kakashi UJ/effects](#ultimate-jutsu-and-effects).
The NUN3 request-row and playback contract is established under
[NUN3 Guy cinematic requests](guy.md#cinematics);
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
This census checks the static typed-definition region; it does not
decode every streamed command, nested model/material field or lifetime.
The four stream common-1 `joe01/cloth3` keys also require donor
providers absent from the checked NA2 common file.

The selected `kakashi_cinematic_auxiliary_entries`
(`0x0047C308`) contain pointers
`0x006A0FC4/C8/CC/D0`, whose data are
`0x00546030,0x00548AA0,0x0054A2D0,0x0054C0F0`.
These are scene/renderer auxiliary data, not audio cue rows.
`kakashi_cinematic_defender_position_entries`
(`0x0047CA18`) select
`0x005C7D60,0x005C8560,0x005C89D0,0x005C91D0`.
Playback retains the selected skill and participant roles and consumes
those per-skill placement/scene tables. Exact placement triples,
appearance substitutions and nested camera/command data remain open.

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
Intro voice belongs to
[Kakashi voice](#voice);
the donor's complete timed cinematic damage/spoken-cue producer remains open.

## Voice

Checked identities are NUN3 Kakashi Hatake **ID 8, `kks`** and
retail NA2 Kakashi **ID 70, `kkw`**.
The shared synthesizer lookup is owned by
[Compact program-to-VAG lookup](../../session/battle_audio.md#compact-program-to-vag-lookup).
The following offsets identify source-file bytes in `DATA/SNDDATA.BIN`,
not live IOP addresses.

| Bank / resident descriptor | Header offset / bytes | Sample offset / bytes |
| --- | --- | --- |
| NUN3 English / `kakashi_compact_bank_english 0x003882F0` | `0x0058C000 / 0x13B0` | `0x0058D800 / 0x4E9E0` |
| NUN3 Japanese / `kakashi_compact_bank_japanese 0x0038859C` | `0x01680800 / 0x13B0` | `0x01682000 / 0x53950` |
| NA2 / `kakashi_compact_bank 0x003FDB78` | `0x01151800 / 0xF60` | `0x01152800 / 0x2F440` |

NUN3's descriptor selector `0x00185A30` uses
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

NUN3's streamed PLVOICE banks remain the separately established
outer **7/63**, handles **77/133**, each **213 slots / 80 populated**.
The complete sparse member set and selected physical members 6/45 are
owned by
[Checked NUN3 streamed descriptors](../nun3_nun4_characters.md#checked-nun3-streamed-descriptors-and-members).
Native ID 70's outer **69** starts at file offset **`0x00D39800`**,
size **350208**, with **44/44** members.
These physical banks cannot be joined by compact program or equal logical
member alone.

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
These intros are SOUND members, separate from the character PLVOICE bank.
The donor's complete timed cinematic spoken-cue scheduler and audible
content matches remain open.
