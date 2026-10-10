# Naruto: NUN4 donor

## Research coverage

Established for NUN4 Part II Naruto 57 and Second Stage 73 against NA2 Naruto 57
and Nine-Tailed form 73: stored base move counts and parameters agree while action
layouts and animation payloads differ; the donor form's actions, private
motion/arm/particle ownership and jutsu classes; low-HP record 111 selecting
`D57_10` and effect `0x64` to form 73, outside the reversal table; selected
provider sets and film voice candidates.
Open: action labels and input admission, form and jutsu executable descendants,
typed and code-created providers, cinematic payload and appearance conversion,
remaining voice producers and ID-dependent services.

Names come from `@annotations/NUN4` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [NUN3 and NUN4 characters](../nun3_nun4_characters.md).

## Records, moves and assets

**Checked identities:** NUN4 `SLUS-21862` Part II Naruto ID 57
(`nrw`) and Part II Naruto State 2 ID 73 (`nwv`), against retail
NA2 `SLPS-25837` Naruto ID 57 and Nine-Tailed Fourth Awakened State
ID 73. The donor record strings are `２部ナルト` at
`0x005B7D38` and `２部ナルト状態２` at `0x005BF800`.
The descriptive donor annotation prefix is `naruto_second_stage`;
matching numeric ID 73 does not establish the same form. Classic Naruto
ID 1 (`nrt`) and his Nine-Tailed form ID 47 (`nrv`) were also checked
as distinct characters.

### Definition and construction roots

All addresses below are resident live addresses. Counts are actions /
`0x4C` phase rows / animation-name slots.

| Exact fighter | Record; authored array roots | Counts | Factory / constructor; allocation |
| --- | --- | --- | --- |
| NUN4 Classic Naruto 1 | `naruto_classic_character_record 0x0043E650`; `0x0043D390 / 0x00439B20 / 0x004398B0` | 48 / 190 / 156 | `fighter_id_001_create 0x0023FEF0 / naruto_classic_construct 0x0023FF40`; `0x5C70` |
| NA2 Classic Naruto 1 | `0x0040DB70`; `0x0040CBA0 / 0x00409110 / 0x00408CA0` | 48 / 190 / 156 | `naruto_classic_construct 0x00250C50`; `0x5980` |
| NUN4 Nine-Tailed Naruto 47 | `naruto_nine_tails_character_record 0x004ED7A0`; `0x004EC540 / 0x004E8DB0 / 0x004E8B50` | 47 / 187 / 149 | `naruto_nine_tails_create 0x00279690 / naruto_nine_tails_construct 0x002796E0`; `0x5B20` |
| NA2 Nine-Tailed Naruto 47 | `0x004A68A0`; `0x004A5910 / 0x004A1F90 / 0x004A1C90` | 47 / 187 / 149 | `0x0027E810`; `0x5840` |
| NUN4 Naruto 57 | `naruto_character_record 0x0051CD90`; `naruto_actions 0x0051BA60 / 0x00518110 / 0x00517E90` | 49 / 193 / 157 | `naruto_create 0x00292560 / naruto_construct 0x002925B0`; `0x5E60` |
| NA2 Naruto 57 | `0x004DAD80`; `0x004D9D50 / 0x004D61F0 / 0x004D5E30` | 49 / 193 / 157 | `naruto_construct 0x00295DB0` |
| NUN4 Second Stage 73 | `naruto_second_stage_character_record 0x00565950`; `naruto_second_stage_actions 0x005645C0 / naruto_second_stage_animation_rows 0x005609C0 / naruto_second_stage_animation_names 0x00560740` | 50 / 202 / 159 | `naruto_second_stage_create 0x002C2340 / naruto_second_stage_construct 0x002C2390`; `0x6170` |
| NA2 Fourth Awakened 73 | `nine_tails_fourth_character_record 0x00535D50`; `0x00534E20 / 0x005316A0 / 0x00531260` | 46 / 181 / 152 | `0x002CE5A0`; `0x5840` |

The complete 33 stored parameter words at record `+0x58..+0xD8`
agree in all four same-ID pairs. These stored parameters do not establish
equal animation, callbacks or jutsu. NUN4 action stride is `0x64`, with
five display pointers and packed owner/selector at `+0x1C`; NA2 stride
is `0x54`, with one display pointer and that word at `+0x0C`.
`Nun4ActionRecord` records the checked NUN4 layout.

Donor Naruto's mutable descriptor is `naruto_character_descriptor
0x0051CE70`, vtable `naruto_vtable 0x005EB200`; names/actions/rows
are embedded at instance `+0xED0/+0x1144/+0x2468`.
Its cached clone model, palette and composition are
`MDL_2nrw01t0 body`, `CLT_2nrwbody` and `CMP_2nrw00t0 trall`.
Both checked ID-57 constructors set cooldown/threshold/cap to 16/16/30.
Donor Second Stage uses descriptor `0x00565A30`, vtable
`naruto_second_stage_vtable 0x005EAEE0`, embedded
`+0xED0/+0x114C/+0x24D4`, and 16/12/60.

### Authored moves and animation comparison

For IDs 1, 47 and 57, all name-array slots and all non-pointer phase-row
words agree with NA2; pointer fields `+0x28/+0x40` refer to each game's
own name pool. Checked ID-1/57 bone names also agree. Their action-tail
words still differ: every differing word at donor `+0x3C` versus native
`+0x2C` has the same high halfword and native low halfword two higher.
ID 57 additionally changes `+0x58/+0x48` from
`0xFFFF0013` to `0xFFFF0018` in actions 36/44.
ID 1 has additional differences there in actions 25/29/35/43; ID 47 in
actions 6/21/23/26/29/32/33/34/40/42/44/45.
Those numeric domains are not interchangeable merely because phase rows match.

Clean CCS animation payload comparison gives a stronger result for Classic
Naruto: all 111 body, eight CHA0 and seventeen CHA1 `0x0700` payloads
are byte-identical. For ID 47, all 135 body and twelve CHA1 payloads agree;
five of seven CHA0 payloads agree, while the other two retain equal
authored lengths. For ID 57, none of the 129 common body payloads is
byte-identical, and `ANM_pnrwpxn0` changes authored length 13 → 9.
NA2 adds `ANM_nrwact00/02`; all other body animation names agree.
The eight CHA0 and fifteen CHA1 names and authored lengths agree, with
only one/four complete payloads identical, respectively. Equal names and
lengths alone do not establish equal transforms or commands.

Second Stage's complete ordinary-action sequence census follows. Prefix
`ANM_pnwv` is omitted. A native number means an equal ordered animation
name sequence among NA2 ordinary actions 21..45; it does not assert equal
input, timings, hit banks or motion. A dash means no such equal sequence.

| Donor action | Animation sequence | NA2 equal sequence |
| --- | --- | --- |
| 21 | `pnc00/pnc02` | 22 |
| 22 | `pnc10/pnc12` | 23 |
| 23 | `kcn00/kcn02` | — |
| 24 | `pnc20/pnc21/pnc22` | 25 |
| 25 | `pnc30/pnc32` | 24 |
| 26 | `pnc50/pnc52` | — |
| 27 | `pnc40/pnc41/pnc42/pnc43` | — |
| 28 | `pnc90/pnc91` | — |
| 29 | `pnc92/pnc96/pnc93` | — |
| 30 | `pnc94/pnc95` | — |
| 31 | `pnc60/pnc61/pnc62` | — |
| 32 | `pnc70/pnc71/pnc72` | — |
| 33 | `pnc80/pnc82` | 29 |
| 34 | `kcn10/kcn12` | — |
| 35 | `pnb20/pnb21/pnb22` | — |
| 36 | `pnb30/pnb32` | — |
| 37 | `hol00/hol01` | 33 |
| 38 | `hol02/hol03` | 34 |
| 39 | `pna00/pna02` | — |
| 40 | `pna10/pna12` | 38 |
| 41 | `pna20/pna22` | 43 |
| 42 | `kca10/kca11/kca12` | — |
| 43 | `pna50/pna52` | — |
| 44 | `pna60/pna62` | — |
| 45 | `hla00/hla01` | 41 |
| 46 | `hla02/hla03` | 42 |
| 47 | `pna30/pna32` | — |
| 48 | `pna40/pna42` | — |
| 49 | `kca00/kca01/kca02` | — |

There are 82 common body animation names; none has an identical complete
payload. Forty-two have different authored lengths. Examples, donor → NA2:
`pnc00/02` 7/10 → 21/25, `pnc10/12` 9/11 → 34/29,
`pnc30/32` 22/31 → 46/17, `pnc40/42` 13/19 → 28/11,
`hol00/02` 19/17 → 11/9 and `pna10/12` 14/12 → 12/9.
Even donor action 21/native action 22's equal name sequence has phase-row
rate 208 versus 296. Donor-only/NA2-only body animation counts are 67/48.

### Ordinary jutsu factories and assets

Configured selectors are not concrete resource IDs or UJ authored skills.
For donor/native IDs 57 and 73, the checked selector and resource numbers
agree while concrete classes or implementations differ.

| Fighter / slot | Selector → resource; provider | NUN4 concrete construction | NA2 construction |
| --- | --- | --- | --- |
| Naruto 57 / 0 | 114 → 116; `2nrwcha0` | `naruto_jutsu0_construct 0x007BB340`, `ccSkillNRW000`, allocation `0x1250`, vtable `0x005FA950` | `naruto_jutsu0_construct 0x007DD550`, `ccSkillNRW000`, allocation `0x2830`, vtable `0x005F0E70` |
| Naruto 57 / 1 | 115 → 117; `2nrwcha1` | `naruto_jutsu1_construct 0x007BBD50`, `ccSkillNRT001B`, allocation `0x8B0`, vtable `0x005FA710` | `0x007DDE80`, `ccSkillNRW001`, allocation `0x1180`, vtable `0x005F0C20`; enables inherited input byte `+0x1170` |
| Second Stage / Fourth Awakened 73 / 0 | 146 → 148; `2nwvcha0` | `naruto_second_stage_jutsu0_construct 0x007CC2E0`, `ccSkillNWV000`, allocation `0x840`, vtable `0x005F7CC0` | `nine_tails_fourth_jutsu0_construct 0x007EE370`, `ccSkillNWV000`, allocation `0x1120`, vtable `0x005EDC80` |
| Second Stage / Fourth Awakened 73 / 1 | 147 → 149; `2nwvcha1` | `naruto_form_rasengan_construct 0x007AD1E0`, `ccSkillNRV001`, allocation `0x8B0`, vtable `0x005FDAA0` | `nine_tails_fourth_jutsu1_construct 0x00852BF0`, `ccSkillNWV001`, allocation `0x10A0`, `descriptor_array_vtable 0x005E29D0` |

Jutsu addresses in this table are live `BATTLE.BIN/BTL.BIN` addresses.
MCP did not expose the individual dispatcher switch arms as functions;
the factory allocation/call joins used MCP memory bytes from those arms,
then MCP decompilation of each destination constructor and its RTTI.

Donor `naruto_jutsu0_setup 0x007BB840` binds
`ANM_pnrwcha02/03` and two embedded `0x510` owners at `+0x830/+0xD40`.
Its named update/draw/emit/prepare/destroy roots are
`0x007BB550/0x007BB760/0x007BB7C0/0x007BB820/0x007BB3A0`;
update consumes frame/effect/voice tables `0x0084C790/7B0/7C0`.
`naruto_jutsu1_refresh_body 0x007BBE70` replaces body material from
the current fighter's texture/palette, using `OBJ_2nrw00t0 body`.
Second Stage first-jutsu setup/update/destroy roots are
`0x007CC650/0x007CC410/0x007CC320`, with event tables
`0x0084D3F0/440/4A0`. Its second jutsu shares the actual
`ccSkillNRV001` class with donor ID 47 resource 113; resource ID remains
an input to that class's effects and sound behavior.

The donor form's CHA0 has six animations: main `cha01/02` and camera
are 181 frames, versus native 160. CHA1 has eleven animations versus
native fifteen: donor adds `enwvcha11a/b/c/d`, `pnwvcha15/20`;
native instead has `enwv_fire00`, `enwvcha1_1`,
`pnwvcha10a/b/c/t` and `pnwvcha11t/12t/13t/14t`.
Shared `cha10/12/13/14` lengths are 12/7/10/11 versus 9/16/11/16.

### Indexed services and related owners

NUN4 `battle_ai_update` reads `naruto_ai_character_values
0x00853CC4` and `naruto_second_stage_ai_character_values 0x00853D04`:
both `{2,20}`. Native corresponding rows `0x008C3544/0x008C3584`
also contain `{2,20}`; complete decision behavior is not proved equal.
Donor ID 73's compact bank descriptors are byte-identical to ID 57's
in both language sets; donor ID 47 similarly shares ID 1's bank.
Native ID 73 likewise shares ID 57's descriptor, including header offset
`0x00DB1000`, header bytes `0x2120` and sample bytes `0x5F1C0`.
The base descriptor ranges are owned by [Compact fighter bank resources](../../../game/character_assets.md#compact-fighter-bank-resources).
Current-ID checks, constructor-owned auxiliary lifetime and callback-local
action semantics belong to [Naruto callbacks](#callbacks).
UJ categories/effects and form linkage belong to
[Naruto awakening](#ultimate-jutsu-and-effects).
The selected jutsu provider and texture/palette chains are in
[Naruto dependencies](#typed-providers);
SINF request pairs are in
[Naruto cinematics](#cinematics),
and compact/streamed resources in
[Naruto voice](#voice).

## Callbacks

This comparison checks NUN4 Naruto ID 57 and his Second Stage ID 73
against retail NA2 Naruto ID 57 and Fourth Awakened ID 73. Array and
class roots are in [Character assets](#records-moves-and-assets).
The following addresses are live NUN4 resident addresses.

`naruto_callbacks 0x00517E70` contains
`0x00295C80/0x00295CB0/0x002960E0/0x002978A0/0x00297C60/0/0`.
`naruto_channel1` forwards common action selector `0x22`.
`naruto_channel2` applies effect `0x43` with lifetime -1 and route 1
when HP is at most 0.15, that effect is absent, the root suppression
bit is clear and the coordinator is inactive. NA2's analogous callback
uses effect `0x39`. This is separate from the half-HP UJ selection gate.

`naruto_channel3` has the same checked action/event structure as NA2's
counterpart: local action `0x30`/event 9 requests positional sound
`0x1005`; `0x2B`/event 7 requests 13/38; `0x2A` approaches
the opponent under facing/distance/height/outcome gates; `0x1B`/event 37
requests `0x1005`; `0x22`/event 0 restores facing; `0x1F`/event 12
uses effect `0x3B` and a vector. Numeric resources still belong to each
game's own domain. `naruto_hit_response` changes the repeated action
`0x25` damage/response fields, reads effect `0x43` for actions
`0x16/17`, and writes receiver overrides only in mode 2.

Active/pass-gated `naruto_channel5` delegates to
`naruto_private_update 0x00295860`. Its descendants
`naruto_clone_motion_update 0x00292FC0` and
`naruto_clone_event_update 0x002963E0` own two-clone motion,
named-bone anchors, model transforms and projectile handles.
Private storage includes inline `+0xA50`, second clone state
`+0x5DD0` and handles `+0x5DB4/+0x5DB8`.
Clone model replacement rebinds a constructed `0x50` instance to the
current body texture/palette. This is executable fighter behavior beyond
the authored action arrays.

`naruto_second_stage_callbacks 0x00560720` contains
`0x002C4D10/0x002C4E40/0x002C50D0/0x002C5E30/0x002C62A0/0/0x002C4E00`.
Its first two named channels check the actual current ID 73.
`naruto_second_stage_channel1` also disables its three particles when
the root visibility state changes; channel 2 updates the particle owner.
Channel 3 dispatches action-specific effect/contact/voice events for
`6,0x17..0x20,0x22..0x24,0x26,0x29,0x2A,0x31`.
Action `0x17` changes a writable action flag `0x20000` across its
event window; action `0x1B` uses auxiliary arm animation.
The selected hit-response return set is `{-1,0x2C,0x2D,0x2E,0x31}`.
Channel 5 delegates to `naruto_second_stage_private_update 0x002C3BE0`
and resolves foot nodes through the auxiliary controller.
`naruto_second_stage_channel7 0x002C4E00` saves the shared render
descriptor pointer at `+0x6100` and publishes the class descriptor
at `+0x60D0`, only for current ID 73. The complete leaf has no calls.
Transitive contact-helper behavior remains open.

### Second Stage auxiliary ownership

`naruto_second_stage_construct 0x002C2390` creates two `0x120`
controllers from body `ANM_pnwvarm1/2`, a `0x1C` particle owner,
a common `CMP_2cmn00t0 trall` composition, a `0x120` auxiliary
controller and a `0x50` model instance from `MDL_2kyw00t0 body`.
Its render descriptor uses `TEX_enwv_cel`.
`naruto_second_stage_auxiliary_update 0x002C29D0` synchronizes the
primary/auxiliary animations and drives both arm controllers during
action `0x1B`. `naruto_second_stage_register_arm_hitbanks 0x002C2EE0`
registers the selected arm's two collision banks within that action's
event interval.

`naruto_second_stage_update_auxiliary_model 0x002C3050` changes body
node flags and oscillates the auxiliary alpha. The draw method
`naruto_second_stage_draw_auxiliary 0x002C2D50` temporarily publishes
the class render descriptor, draws the auxiliary and active arms, then
restores the saved descriptor.
`naruto_second_stage_particle_initialize 0x002C1DC0` creates three
instances from `EFF_nrwpar00` and definitions
`0x00565A80/0x00565AC0/0x00565AE0`; its update disables them in mode 2
or successful jutsu actions 1/3, otherwise maintains their facing/position.
`naruto_second_stage_destroy 0x002C2810` releases the arm controllers,
particle owner, auxiliary controller, composition, model and render
descriptor before common destruction.

NA2 `fighter_id_073_construct 0x002CE5A0` instead binds
`ANM_pnwvpnb10/11`, `Shade.ccs`, `TEX_2nwv_cel00`,
`TEX_2nwv_tone32` and a tone context; its optional presentation body
uses `TEX_1nwv_tone01`. These checked auxiliary resources differ from
the donor's arm/particle ownership and cannot be equated by ID or `nwv`
filename alone.

## Typed providers

The selected donor is NUN4 Naruto ID 57 / Second Stage ID 73. The
following exact namespace/name comparisons use its clean English CVM view,
not NA2 providers. Ordinary namespace text is compared after its leading
byte, as the runtime matcher does.

| Donor consumer | Marked rows | Checked providers with matching keys |
| --- | ---: | --- |
| `PL/2NRWCHA0.CCS` | 134 | `CMN/2CMNBOD1`, `PL/1CMNBOD1`, `PL/2NRWBOD1` |
| `PL/2NRWCHA1.CCS` | 64 | `CMN/2CMNBOD1`, `PL/2NRWBOD1` |
| `PL/2NWVCHA0.CCS` | 103 | `CMN/2CMNBOD1`, `PL/1CMNBOD1` |
| `PL/2NWVCHA1.CCS` | 34 | `CMN/2CMNBOD1` |
| `STR/D57_10.CCS` | 359 | `D57_10E`, `PL/1CMNBOD1`, `PL/1NRWBOD1`, `PL/1NWVBOD1`, `PL/2NRWBOD1`, `STRMCMN` |
| `STR/D57_20.CCS` | 280 | `D57_20E`, `PL/1CMNBOD1`, `PL/1NRWBOD1`, `PL/2NRWBOD1`, `STRMCMN` |
| `STR/D57_30.CCS` | 247 | `D57_30E`, `PL/1CMNBOD1`, `PL/1NWVBOD1`, `STRMCMN` |

Every marked key in these seven consumers exists in its respective checked
provider union, with zero absent keys. Each film was checked with only
its own matching resident scene, not the other two scenes.
`D57_10E` has no marked rows. `D57_20E/30E` each have one:
`#e\0x\tex\sampling00.bmp / TEX_sampling00`. No matching ordinary
provider or local definition was found for that key in those checked
sets, including `STRMCMN`; its runtime sampling-texture producer remains
open. This is not a claim that the retail scene fails.

The battle bodies mark the common-2 skeleton namespace. The two Naruto
jutsu files additionally mark the actual Naruto body:
`#c\2nrw\max\2nrwbod1.max`, plus `TEX_2nrwbody` in CHA0.
Thus those ordinary jutsu animations require that body provider, whereas
the form's checked jutsu external keys use common skeleton providers.

The form's constructor selects additional concrete local resources from
`PL/2NWVBOD1.CCS`. The typed payload edges checked there are:

| Source | Local target |
| --- | --- |
| `EFF_nrwpar00`, record 6108, tag `0x0E00` | `TEX_nrwpar00`, record 6109 |
| `TEX_nrwpar00`, tag `0x0300` | `CLT_nrwpar00`, record 6110 |
| `TEX_enwv_cel`, record 6105, tag `0x0300` | `CLT_enwv_cel`, record 6104 |

`MDL_2kyw00t0 body`, record 5938, has a `0x0800` payload with
stored subtype 4. The maintained explorer exposes its raw payload but
does not give a usable part census for this record; the complete geometry/
material chain has not been established here.
`ANM_pnwvarm1/2`, the common composition and the three particle
definitions have direct constructor/update consumers in
[Naruto callbacks](#second-stage-auxiliary-ownership).
Directory matches and these selected typed edges do not establish every
nested animation command, code-created effect, provider lifetime or
participant replacement. Request ownership is in
[Naruto cinematics](#cinematics).

## Ultimate Jutsu and effects

**Checked identities:** NUN4 Naruto ID 57 (`nrw`) / Second Stage ID 73
(`nwv`), versus retail NA2 Naruto ID 57 / Fourth Awakened ID 73.
NUN4 `naruto_ultimate_jutsu_list 0x00607DA0` contains records
110/111 and defaults to 110. Its form list
`naruto_second_stage_ultimate_jutsu_list 0x00607E18` contains record
153 and defaults to 0. NA2 ID 57 likewise lists 110/111; ID 73's
list at `0x006044B0` contains record 165 and defaults to 0
(`0x005AFE42`). Default 0 does not replace the matched category-1 row.

NUN4 metadata uses the own locale-selected `0x10`-byte format;
NA2 uses resident `0x14`-byte records. All six rows have contest
class 3; native secondary-intro values are -1.

| Exact row / live address | Authored skill | Category / cost tier | Intro | Post-effect | Damage percent |
| --- | --- | --- | --- | --- | --- |
| NUN4 Naruto 110 / `0x008701F0` | `0x5A` | 2 / 0 | `0x54` | -1 | 25 |
| NUN4 Naruto 111 / `0x00870200` | `0x59` | 3 / 1 | `0x53` | `0x64` | 20 |
| NUN4 Second Stage 153 / `0x008704A0` | `0x5B` | 1 / 1 | `0x55` | -1 | 35 |
| NA2 Naruto 110 / `0x005AF4D8` | `0x4B` | 2 / 0 | `0x5B` | -1 | 25 |
| NA2 Naruto 111 / `0x005AF4EC` | `0x4C` | 3 / 1 | `0x5C` | `0x72` | 20 |
| NA2 Fourth Awakened 165 / `0x005AF924` | `0x4E` | 1 / 1 | `0x90` | -1 | 35 |

Own-game NUN4 `jutsu_slots_rewrite 0x0022E8C0` selects tier 2 when
the fighter's marker bit `+0x63 & 0x20` is set, otherwise tier 1
at HP `+0x6C <= 0.5`, otherwise tier 0. These tiers request categories
1/3/2, respectively, after the separate side tier remap. With the
identity remap, Naruto's unmarked low-HP record is 111,
and his ordinary record is 110; a missing requested category returns
the character's default. The exact decoded SINF titles for skills
`0x59/0x5A/0x5B` are `多影撃連弾`, `特大螺旋丸` and
`抑えきれない力`. Localized display-pointer binding remains open.

The Naruto low-HP record plays authored skill `0x59`; it is distinct
from authored skill 1's seven-character reversal route. The complete
NUN4 `reversal_definition_table` has IDs 50/16/19/21/25/9/7,
not Naruto 57/73. The [NUN4 reversal contract](ultimate_jutsu.md)
owns that system route. Calling Naruto's low-HP record “reversal” does
not put him in that minigame table or remove his cinematic request.

NUN4 `jutsu_record_form_character 0x003CCD00` maps effect
`0x64` to ID 73; NA2 `jutsu_record_form 0x00372D00` maps
`0x72` to ID 73. Both own-game forward/inverse identity helpers
join 57 ↔ 73, but the concrete form classes and moves differ.
NUN4 `naruto_awakening_flags 0x00592329` is 1, its presentation
event is 31, and `naruto_awakening_association 0x005925E8` is
effect `0x64`, count 1. The form association `0x00592668` agrees.
The existing-state adoption helper recognizes transformed ID 73;
`fighter_apply_inherent_form_effect 0x002CF540` applies
`0x64` to that reconstructed form with lifetime -2.
The base's separate HP-0.15 effect `0x43` is owned by
[Naruto callbacks](#callbacks).

For the separate Classic Naruto pair, donor ID 1 lists 1/2, defaults
to 1; ID 47 lists 100, defaults to 100. Authored skills are 2/3/4,
categories 2/3/1, damages 25/20/35, with record 2 effect
`0x5A` mapping to form 47. This is distinct from the Part II
Naruto 57/73 path. Cinematic requests belong to
[Naruto cinematics](#cinematics).

## Cinematics

This checks NUN4 Naruto 57 / Second Stage 73 against retail NA2
Naruto 57 / Fourth Awakened 73. Metadata selection is owned by
[Naruto awakening](#ultimate-jutsu-and-effects);
the shared NUN4 route by [NUN4 Ultimate Jutsu](ultimate_jutsu.md).
The own-game SINF relocators establish the `0x14` donor and `0x18`
native request-row representations. The decoded selected requests are:

| Game / authored skill | Decoded donor title | Resident main | Ordered extra residents | Stream |
| --- | --- | --- | --- | --- |
| NUN4 `0x59` | `多影撃連弾` | `STR/D57_10E.CCS` | `PL/2NRWBOD1.CCS`, `PL/1NWVBOD1.CCS` | `STR/D57_10.CCS` |
| NUN4 `0x5A` | `特大螺旋丸` | `STR/D57_20E.CCS` | `PL/2NRWBOD1.CCS` | `STR/D57_20.CCS` |
| NUN4 `0x5B` | `抑えきれない力` | `STR/D57_30E.CCS` | `PL/1NRWBOD1.CCS` | `STR/D57_30.CCS` |
| NA2 `0x4B` | — | `STR/D57_20E.CCS` | `PL/2NRWBOD1.CCS` | `STR/D57_20.CCS` |
| NA2 `0x4C` | — | `STR/D57_25E.CCS` | none | `STR/D57_25.CCS` |
| NA2 `0x4E` | — | `STR/D57_35E.CCS` | `PL/2NWVBOD1.CCS` | `STR/D57_35.CCS` |

Every row requests one stream. The table records authored SINF titles for
the donor, not an established English menu-label join. Reusing `nrw/nwv`
or a `D57` prefix does not establish identical requests: only the normal
`D57_20` pair agrees in path selection. Its eleven resident hit/cue rows
are byte-identical between games; the selected low-HP and form rows differ,
as recorded in [Naruto voice and hit rows](#voice).

The donor streams contain `CAM_camera01`,
`BIN_damoffs_d57_10/20/30` and `BIN_strfilter_d57_10/20/30`.
Their decompressed sizes are 10,801,492 / 8,720,936 / 11,833,940 bytes;
matching resident requests are 689,184 / 643,892 / 932,576 bytes.
Their exact marked-name provider sets and selected texture/particle edges
belong to [Naruto provider dependencies](#typed-providers).
Skill `0x5B` explicitly adds `1NRWBOD1`, while its stream's actor
keys name `1NWVBOD1`; selected fighter/participant publication therefore
remains part of the resource set. Extra-path membership alone is not
the complete body-provider closure.

The separate donor Classic Naruto skills 2/3/4 select
`D01_10E/D01_10`, `D01_20E/D01_20`, `D01_30E/D01_30`.
Their extras are `2NRTBOD1`, `2NRTBOD1 + 6NRVBOD1` and
`6NRVBOD1`, respectively. These are not Part II Naruto's requests.

Full typed camera/command, damage-offset/filter and appearance-substitution
comparison for the three Part II donor scenes remains open. The checked
normal hit-row equality does not prove equal complete scene files or
equal camera presentation.

## Voice

The exact comparison is NUN4 Naruto ID 57 / Second Stage ID 73 against
retail NA2 Naruto ID 57 / Fourth Awakened ID 73. Compact bank identity
and the separate Classic Naruto pair are owned by
[Character assets](#records-moves-and-assets).
The generic synthesizer decoder is owned by
[Compact program-to-VAG lookup](../../session/battle_audio.md#compact-program-to-vag-lookup).

NUN4 `voice_event_pointer_pairs` gives ID 57 the base/alternate lists
at `0x00591DD0/0x00591E70`; ID 73 stores them in reversed order.
The form uses that first, +160 list through the checked selector, while
base Naruto's alternate predicate reads effect `0x43`.
The donor alternate defaults to key `0x3E`, versus native ID 57's
alternate key `0x3D`. Exact normal/alternate event 0/24/25 candidates
already appear in the decoder table; enabled program 27 has a donor
sample and no corresponding Prog entry in the checked native Naruto bank.

### Selected cinematic hit and compact-cue rows

These are resolved authored skills, distinct from global metadata indices.
All roots below are resident live addresses. `sp_skill_play_frame`
consumes eight-byte rows and divides the unsigned damage/chakra weights
by 32768. Every selected descriptor has total damage weight 32768 and
all chakra weights zero.

| Exact selected skill | Count / annotated row root | Nonnegative frame:cue pairs |
| --- | --- | --- |
| NUN4 low HP `0x59` | 27 / `naruto_low_hp_ultimate_hit_rows 0x005CADC0` | 24:14, 46:12, 220:18 |
| NUN4 normal `0x5A` | 11 / `naruto_grand_rasengan_hit_rows 0x005CAEA0` | 27:13, 159:15, 244:18 |
| NUN4 Second Stage `0x5B` | 67 / `naruto_second_stage_ultimate_hit_rows 0x005CAF00` | 119:13, 315:18 |
| NA2 low HP `0x4C` | 4 / `naruto_low_hp_ultimate_hit_rows 0x005CCAA0` | 238:16, 283:12, 302:14, 315:18 |
| NA2 normal `0x4B` | 11 / `naruto_grand_rasengan_hit_rows 0x005CCA40` | 27:13, 159:15, 244:18 |
| NA2 Fourth Awakened `0x4E` | 111 / `nine_tails_fourth_ultimate_hit_rows 0x005CCCE0` | 127:16, 227:12, 300:17, 427:18 |

All remaining cues are -1. NUN4 low-HP weights are 1024 at 24, zero at
46, 7168 at 220 and 1024 on every frame 221..244.
The normal rows, including popup bytes, agree byte-for-byte: 1214 at
27/165, zero at 159, 6068 at 244, 2427 at 247/250/253/256/259/262,
and 9710 at 266.
Donor form rows are 119,315,326..454 in steps of two in that final range;
all 66 initial weights are 489 and the final weight is 494.
Native low HP damages only 238/315 with weights 5461/27307.
Native form damages only 300/427 with the same weights; its zero-damage
tail occupies every frame 428..534. The record's damage percentage is
applied independently of these normalized distributions.

NUN4 `audio_request_cinematic_cue 0x001D7360` uses the participant's
already selected compact bank and `battle_voice_controls`; outside
manager mode 6, it emits C0 program then 90 key/velocity commands.
Controls 12..18 at `0x00433CE0..0x00433D10` select programs 12..18,
key `0x3C`, velocity `0x7F`. The shared synthesizer's annotated
`hsyn_dispatch_short_command` joins 90 to the same `hsyn_note_on`
sample lookup as the extended command. This route does not select a
PLVOICE physical member.

The checked cinematic control values therefore select these single
candidates from Naruto's bank. Offsets are in each game's clean
`DATA/SNDDATA.BIN`, not live addresses; all rates are 22,050.

| Program / Sset=Smpl | Donor Vagi; English / Japanese file offsets | NA2 Vagi; file offset |
| --- | --- | --- |
| 12 / 9 | 48; `0x00FF0580 / 0x022C4BB0` | 28; `0x00E03600` |
| 13 / 10 | 49; `0x00FF1C50 / 0x022C52E0` | 29; `0x00E04730` |
| 14 / 11 | 50; `0x00FF3460 / 0x022C61E0` | 30; `0x00E050A0` |
| 15 / 12 | 51; `0x00FF4E60 / 0x022C6B20` | 31; `0x00E06890` |
| 16 / 13 | 52; `0x00FF6BC0 / 0x022C7750` | 32; `0x00E07690` |
| 17 / 14 | 53; `0x00FF8EC0 / 0x022C8F00` | 33; `0x00E08B40` |
| 18 / 15 | 45; `0x00FE7DF0 / 0x022BE0C0` | 25; `0x00DFB790` |

These are stored sample selections, not established spoken-content matches
or guaranteed audible admission. Manager mode 6 uses a separate cue route.

### Streamed archive members

NUN4 `audio_request_archive_member 0x001DA180` bounds a requested
member against the selected family descriptor. For family 3 and language
set 1, it adds half the descriptor's physical member count to the requested
logical member. The checked descriptors therefore split these archives:

| Exact donor / descriptor | Handle / physical count | First-half named suffixes; second-half names |
| --- | --- | --- |
| Classic Naruto 1 / `0x004361E0` | 121 / 22 | `000,002,003,265,289,293,298,299,302,312,338`; eleven `plv` names |
| Nine-Tailed 47 / `0x00436350` | 167 / 22 | `213,214,215,217,265,289,293,298,299,302,312`; eleven `plv` names |
| Naruto 57 / `0x004363A0` | 177 / 24 | `256,257,258,259,260,265,289,293,298,299,302,312`; twelve `plv` names |
| Second Stage 73 / `0x00436420` | 193 / 30 | `265,289,293,298,299,302,312,319,320,321,322,323,324,325,326`; fifteen `plv` names |

First-half names have the owning `PL01/47/57/73_` prefix and `.ahx`
extension. Native physical counts are 40/4/48/4, respectively; native
ID 73's four names are `PL73_325/326/327/328.ahx`.
Filename suffixes are not physical member indices.
The selected record's intro halfword still needs its producer-to-family/
physical-member join; a differing halfword or named archive member does
not alone identify the spoken intro. Full ordinary-jutsu and event
cue/sample closure outside the checked controls remains open.
