# Kisame: NUN3 donor

## Research coverage

Established for NUN3 Kisame 24 against NA2 Kisame 72: equal action counts with
164/166 phase rows and 148/147 names, different chains, callbacks and jutsu;
Water Shark and Mad Dance ownership, resources and cleanup roots; twenty-four
Ultimate Jutsu records selecting six films; effects and prerequisites; marked
providers; compact, PLVOICE and six startup intros; AI values.
Open: Water Shark and Mad Dance executable closure, film conversion, typed
descendants, end-demo ring publication, remaining voices, effect consumers,
input and contact semantics, and ID-dependent services.

Names come from `@annotations/NUN3` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [NUN3 and NUN4 characters](../nun3_nun4_characters.md).

## Records, moves and assets

Checked pair: **NUN3 Kisame Hoshigaki 24 (`0x18`, `ksm`)**, resident
`SLUS_217.27` / `BATTLE.BIN`, versus **retail NA2 Kisame Hoshigaki
72 (`0x48`, `ksw`)**, `SLPS_258.37` / `BTL.BIN`.
NA2 ID 24 is a filler and is not the same-name comparison.

### Records and construction

| Item | NUN3 Kisame 24 | NA2 Kisame 72 |
| --- | --- | --- |
| Definition / factory | `0x004767F0` / `kisame_create 0x00201FA0` | `0x005A2B40` / `fighter_id_072_create 0x002CBC10` |
| Allocation / constructor | `0x4F20` / `kisame_construct 0x00201FF0` | `0x5090` / `fighter_id_072_construct 0x002CBC60` |
| Character record | `kisame_character_record 0x003F6D70` | `kisame_character_record 0x005304F0` |
| Mutable descriptor | `kisame_construction_descriptor 0x003F6E50` | `kisame_construction_descriptor 0x005305D0` |
| Final fighter vtable | `kisame_vtable 0x00689260` | `fighter_id_072_vtable 0x005DA5D0` |
| Actions | `kisame_actions 0x003F5F50`, 43 × `0x54` | `kisame_actions 0x0052F6C0`, 43 × `0x54` |
| Phase rows | `kisame_phase_rows 0x003F2EA0`, 164 × `0x4C` | `kisame_phase_rows 0x0052C350`, 166 × `0x4C` |
| Animation names | `kisame_animation_names 0x003F2C50`, 148 | `kisame_animation_names 0x0052C0D0`, 147 |
| Palette / texture names | `0x003F2A28` / `0x003F2B90` | `0x0052B5D0` / `0x0052B738` |
| Model / anchor names | `0x003F2BD0` / `0x003F2C10` | `0x0052B778` / `0x0052B7B8` |

Complete stored parameter bytes `+0x58..+0xDB` agree across these records.
That does not equate the different action arrays, callbacks or assets.
Donor construction uses the common fighter base, final vtable and writable
descriptor, supplying embedded animation/action/row storage at fighter
`+0xE00/+0x1050/+0x1E6C`; no private-tail constructor is called.
`kisame_destroy` (`0x002020B0`) uses common cleanup/base destruction/free.
The native constructor likewise invokes the common base and record loader,
but installs native vtable and embedded names/actions/rows at
`+0xEE0/+0x112C/+0x1F48`. Its live instructions write those addresses
to mutable descriptor fields `+0x4C/+0x30/+0x40`.
Both AI virtual methods dispatch the common AI path under their controller
predicate: donor `kisame_ai_update 0x00202130`, native `0x002CBDA0`.
Detailed action events belong to
[Kisame callbacks](#callbacks).

### Complete authored action-family correspondence

Suffixes below omit `ANM_pksm` or `ANM_pksw`. They describe exact stored
phase-name sequences, not equal motion, hit timing or physical-input admission.

| NUN3 action | Donor sequence | NA2 action / sequence |
| --- | --- | --- |
| 0 | empty | 0 / `chb00,chb02` |
| 1 | `cha00` | 1 / `cha00` |
| 2 | empty | 2 / empty |
| 3 | `cha10` | 3 / `cha10` |
| 4 | `rdy1,spl00,spl02` | 4 / same suffixes |
| 5 | `rdy1,spl10,spl10,spl12` | 5 / same suffixes |
| 6 | `rdy1,spl20,spl22` | 6 / same suffixes |
| 7..9 | `nxs0,sig0,sig0,sxn0`, each | 7..9 / same suffixes |
| 10 | `jmp1,swa60,swa62,lan0` | 10 / same suffixes |
| 11 | `jmp1,swa90,swa92,lan0` | 11 / same suffixes |
| 12 | `jmp1,swb20,swb22,lan0` | 12 / same suffixes |
| 13 | `jmp1,swa70,swa72,lan0` | 13 / same suffixes |
| 14 | `jmp1,swb00,swb02,lan0` | 14 / same suffixes |
| 15 | `jmp1,swb30,swb32,lan0` | 15 / same suffixes |
| 16 | `jmp1,swa80,swa82,lan0` | 16 / same suffixes |
| 17 | `jmp1,swb10,swb12,lan0` | 17 / same suffixes |
| 18 | `swb40,swb40` | 18 / `swb40,swb42` |
| 19 | `jmp2,jmp1,dow0,jpz1,jpz0` | 19 / same suffixes |
| 20 | `swd00,swd02` | 21 / same suffixes |
| 21 | `swd10,swd12` | 22 / same suffixes |
| 22 | `swd20,swd22` | 23 / same suffixes |
| 23 | `swd30,swd32` | 31 / same suffixes |
| 24 | `swd50,swd52` | 26 / same suffixes |
| 25 | `kcn00,kcn02` | no corresponding suffix sequence |
| 26 | `swd40,swd42` | 25 / same suffixes |
| 27 | `swd80,swd82` | 29 / same suffixes |
| 28 | `swd90,swd92` | 30 / same suffixes |
| 29 | `swd60,swd62` | 27 / same suffixes |
| 30 | `swd70,swd72` | 28 / same suffixes |
| 31 | `swe00,swe02` | 32 / same suffixes |
| 32 | `kcn10,kcn12` | no corresponding suffix sequence |
| 33 | `hol00,hol01` | 33 / same suffixes |
| 34 | `hol02,hol03` | 34 / same suffixes |
| 35 | `swa20,swa20,swa22` | 35 / `swa20,swa22` |
| 36 | `swa30,swa32` | 36 / same suffixes |
| 37 | `swa40,swa42` | 37 / same suffixes |
| 38 | `swa50,swa50,swa52` | 38 / `swa50,swa51,swa52` |
| 39 | `hla00,hla01` | 39 / same suffixes |
| 40 | `hla02,hla03` | 40 / same suffixes |
| 41 | `swa00,swa00,swa02` | 41 / `swa00,swa02` |
| 42 | `swa10,swa12,swa12` | 42 / same suffixes |

The two additional native sequences are action 20,
`jmp2,swa60,swa60,swa62,lan0,ost0`, and action 24, `swe10,swe12`.
Donor display titles include action 23 **Consistent Slash**, 24 **Back
Roaring Hit**, 25 **Kick In**, 26 **Giant Rectangular Drop**, 28
**Necessary Slashing**, 30 **Forgiveness-Piercing Drop**, 32 **Kick Slide**,
34 **Back Slash**, 36 **Reverse Trimming**, 38 **Crossbar**, 40 **Dump Hit**
and 42 **Giant Dance Slash**. Numeric action positions therefore cannot
stand in for a cross-game move correspondence.

### Ordinary jutsu and concrete ownership

| Selected route | NUN3 Kisame | NA2 Kisame |
| --- | --- | --- |
| First configured action / selector | 1 / 48, cost about 3.6, **Water Style: Water Shark Jutsu** | 1 / 144, cost 0, `水遁・潜鮫削滅` |
| Second configured action / selector | 3 / 49, cost 3, **Mad Dance of Annihilation** | 3 / 145, cost 3, `水遁・水鮫散弾の術` / **Water Style: Water Shark Shotgun Jutsu** |
| Selected resources | 37/38 at BATTLE `0x0093E8C0` | 146/147 at BTL `0x008CB3A0` |
| Resident provider rows | `0x00476418/24`, twelve-byte rows, `2ksmcha0/1.ccs` | `0x005A27A0/A8`, eight-byte rows, `2kswcha0/1.ccs` |
| First concrete factory | `kisame_water_shark_factory_case 0x0086D020`, `0x5C0` | `kisame_stealth_shark_factory_case 0x00774A78`, `0x1120` |
| Second concrete factory | `kisame_mad_dance_factory_case 0x0086CDE0`, `0x6B0` | `kisame_shark_shotgun_factory_case 0x00775154`, `0x1010` |

Native action 0 separately uses selector 144, category `0x10000`, cost 3
and `chb00/02`. This is not an additional resource number.
The donor and native configured action-1 categories are `0x40000`;
action 3 uses `0x80000`.
The clean CHA animations contain these tag-`0x0108` resource commands,
separate from configured selector numbers:

| Game / provider / animation ID and name | Frame | Target | Kind / encoded resource |
| --- | ---: | ---: | --- |
| NUN3 `2KSMCHA0`, 65 `ANM_pksmcha00` | 1 | 2 | `0x8003 / 0x125` |
| NUN3 `2KSMCHA1`, 65 `ANM_pksmcha10` | 1 | 2 | `0x8003 / 0x126` |
| NA2 `PL/2KSWCHA0`, 81 `ANM_pkswcha00` | 1 | 80 | `0x8003 / 0x192` |
| NA2 `PL/2KSWCHA1`, 73 `ANM_pkswcha10` | 1 | 2 | `0x8003 / 0x193` |

Native CHA0's `ANM_pkswcha02` (345) also contains kind `0x8003`,
argument `0x20`, target 272 at frame 123; its consumer meaning is not
assigned here. Donor CHA0's shark-secondary animations and native CHA1's
shark-secondary animations also contain separate kind-`0x8002` commands.

Donor resource 37 uses common construction `0x0087B720`, installs
`kisame_water_shark_vtable` (`resident 0x0068E110`) at actor `+0x28`,
sets the resource halfword and resets its tail through
`kisame_water_shark_reset` (`BATTLE 0x00905570`).
`kisame_water_shark_update` (`0x00905620`) creates a `0x9A0` projectile
at initiating animation frame 15. It uses the common projectile/water bases,
final `kisame_water_shark_projectile_vtable` (`resident 0x0068E080`),
one private shape and seven allocated `0x50` shapes, then registers the actor.

`kisame_water_shark_projectile_bind` (`0x00905910`) requires
`2ksmcha0`, composition `CMP_2ksmskd00t0 body1`, and
`ANM_pksmskd00`; it owns an `0xA0` model, `0xF0` path object and
`0x120` player. Reset/update/motion roots are
`0x009058B0/0x00905B70/0x00905D90`.
The active route performs wall probing, proximity/impact setup and shared
effect emission; phases 4/5 terminate at 7.
`kisame_water_shark_projectile_enter_impact` (`0x00906080`) owns the
impact player/path placement and releases two auxiliary actor handles.
`kisame_water_shark_projectile_contact_effect` (`0x00906EB0`) emits
randomized contact presentation under its private flag.
`kisame_water_shark_projectile_destroy` (`0x0090FE30`) destroys the
seven shapes and private shape, common water state, base and allocation.
Its inherited damage/response and remaining effect descendants remain open.

Donor resource 38 constructs through `kisame_mad_dance_construct`
(`0x008A9B50`) and installs `kisame_mad_dance_vtable`
(`resident 0x0069A4B0`). It owns two allocated `0x50` shapes,
participant handles at `+0x640/+0x64C`, three emitted actor slots at
`+0x658`, charge at `+0x664`, nine animation slots at `+0x668`, and
state at `+0x690`. Begin `0x008AA690` binds its auxiliary compound,
player and resource animations; binder `0x008AC6B0` consumes
`0x00924FA0 = {null,ANM_pksmcha11..18}`.
Participant update `0x008AA800` advances charge stages at approximately
`0.33/0.66/1`, corrects placement and synchronizes auxiliary objects.
Update/input/state roots are `0x008AAFE0/0x008AA640/0x008AC820`;
contact/follow-up roots are `0x008A9E50/0x008AA000`.
The contact route selects response variant `0x58` for source ID 24,
`0x52` for ID 11, and `0x51` otherwise, and consumes separate
charge-dependent interaction definitions. Shape update `0x008AC340`
uses its typed shape bank and common spine/trall anchors.
`kisame_mad_dance_destroy` (`0x008A9C40`) validates and marks its
three emitted actors for deletion, restores participant state and releases
the auxiliary handle, timer, shapes and base. Complete contact/damage,
effect descendants and interruption behavior remain open.

Native resource 146's `kisame_stealth_shark_construct` (`0x007E39F0`)
calls `skill_tyo_base_construct`, installs interface `0x005EFD50`
at `+0x110`, and clears tail words `+0x1114/+0x1118`.
Resource 147 uses `skill_primary_construct` (`0x00785410`), installs
`0x005E7770` at `+0x110`, and calls `kisame_shark_shotgun_reset`
(`0x00846DB0`) to clear three emitted pointers and private counters/flags.
These checked construction differences do not establish equivalence of
their unvisited methods to either donor actor.

### Providers and identity services

The donor body/CHA0/CHA1 contain 138/4/12 animation-directory names;
native contains 137/13/6. Donor battle body has 38 marked common-2
keys, all present in donor `CMN/2CMNBOD1`; four are absent from NA2's
common provider: `OBJ_2cmn00t0 muffler/muffler1/muffler2/muffler3`.
Donor marked IDs 58/60/62/64 are targets of typed `0x0A00` wrappers
57/59/61/63, parent-linked 23 → 57 → 59 → 61 → 63.
Thus these are actual transform dependencies, not an unused-name census.

CHA0 wrapper 51 targets marked 52, `OBJ_2ksmswd` under
`#c\2ksm\max\2ksmswd.max`; donor body local object 66 defines it
as tag `0x0100`. With the body and donor common providers, all CHA0/1
marked keys match. CHA1's marked common keys also match the checked
native common set. This does not equate typed geometry or lifetime.

Donor eye animations are `ANM_3ksmwin00/10`. Of 59 marked keys,
58 match `1KSMBOD1`; the remaining `OBJ_1ksm00t0 ring` is under
`#c\1ksm\max\1ksmring.max`. Eye wrappers 74/162 target marked 75.
A census of all 2,400 clean donor CCS TOCs finds its exact local definition
in `DOLL/IFKSM`, tag `0x0100`, object 68, model ID 377.
Publication of that provider into the eye/end-demo context is unestablished.
The donor 1BOD contains one animation; the portrait contains none.

NUN3 `ai_tick` (`BATTLE 0x00825260`) indexes the actual fighter ID
with stride eight in `ai_character_descriptors` (`0x0093ADF0`).
Kisame's row at `0x0093AEB0` stores words `{1,5}`.
The [native per-character lookup](../../session/battle_ai.md#per-side-state-block)
instead indexes `ai_character_values` (`BTL 0x008C3460`) with stride four.
NA2 Kisame 72 selects `kisame_ai_character_values` (`0x008C3580`),
signed short values `{1,20}`. These are different table formats and selected
values, not a full AI comparison.
Native initialization and reaction routines independently consume the
[character descriptor's flags byte](../../session/battle_ai.md#character-descriptors-and-hard-coded-exceptions).
UJ/default/form services belong to
[Kisame awakening](#ultimate-jutsu-and-effects),
and compact/streamed descriptors to
[Kisame voice](#voice).
Exact clean provider identities are in
[Kisame inputs](../../../game/files/file_identities.md#kisame-comparison-inputs).

## Callbacks

Checked identities are NUN3 Kisame 24 (`ksm`) and retail NA2 Kisame
72 (`ksw`), using each game's resident executable.
Donor `kisame_callbacks` (`0x003F2C30`) contains
`{0,202180,202220,202670,0,0,0}`; native `kisame_callbacks`
(`0x0052B7E0`) contains `{0,2CCD10,2CCDE0,2CDA90,2CDF20,0,0}`.
Addresses inside these lists are hexadecimal. Record and action ownership
belongs to [Kisame assets](#records-moves-and-assets).

Donor `kisame_channel2` (`0x00202180`) requires major/substate `(0,3)`
and phase halfword `+0x8A6 == 0`. On the `+0x1A4` timeline, marker 7
requests fighter SFX `0x2C`; marker 58 requests direct compact control
`0x1B`, key `0x60`. Native `kisame_channel2` (`0x002CCD10`)
instead checks `(0,5)` and emits a facing-dependent spatial effect.
The direct donor command's bank/sample mapping is in
[Kisame voice](#voice).

Donor `kisame_channel3` (`0x00202220`) reads local action and phase,
using timeline `+0x1C8`:

| Action / phase | Marker | Request or state change |
| --- | ---: | --- |
| 4, 5, 6 / 0 | 3 | SFX `0x2C` |
| 4 / 1 | 5 | SFX `0x2C`, fighter voice event 7 |
| 5 / 1 | 0 | SFX `0x2C`, fighter voice event 7 |
| 6 / 1 | 6 | SFX `0x2C`, fighter voice event 7 |
| 5 / 2 | 0 | Fighter voice event 6 |
| 5 / 3 | 0 | SFX `0x2C` |
| 5 / 3 | 2 | Transform/feedback helpers `(1.0;2,1,4,0)` |
| 38 / 0 | 7 | Positional SFX `0x28` |
| 38 / 0 | 12 | Shared helper with colour `0x20808080`, count `0x14` |
| 38 / 2 | 0 | Transform/feedback helpers `(1.25;3,2,12,2)` |

Action 3 also resets the nonzero handle list at fighter `+0x8A0`.
Native `kisame_channel3` (`0x002CCDE0`) retains the basic UJ 4/5/6
voice/SFX schedules but has additional action 23/24/25/26/28/30/31/32/34/36
paths and changed action-38 behavior. Native `kisame_channel5`
(`0x002CDF20`) calls its additional helper when node flag bit 1 and
control byte `+0x61` bit 5 are set; the donor slot is null.

Donor `kisame_hit_response` (`0x00202670`) has source-action branches
5/25/27/28/30/31/36/37/38/42. Its complete returned response set is
`{-1,0x27,0x29,0x2A,0x2D,0x30,0x33,0x36,0x3A,0x3B,0x3E}`.
Repeat count and participant flags alter both response and scale selection.
For example, action 25's initial hit selects response `0x36` and factors
`0.25/1.5/1.0`; action 42 after the first hit selects `0x33` and
`0.5/0.25/1.0`. The scale destinations `+0x8F8/+0x8FC/+0x8F0`
are written only in callback mode 2, when their value is not the sentinel.
Action 5 compares receiver halfwords `+0x8E0/+0x306` to choose
`0x3B` or `0x3A`.

Native `kisame_hit_response` (`0x002CDA90`) instead returns
`{-1,0x27,0x28,0x29,0x2A,0x2B,0x30,0x3C,0x3D,0x40,0x51}`
through its own differently numbered branches.
Equal callback position or numeric response does not establish equal behavior.
Physical-input admission and complete indirect descendants remain open.

## Ultimate Jutsu and effects

Checked donor is NUN3 Kisame Hoshigaki 24 (`ksm`); the same-name native
comparison is retail NA2 Kisame Hoshigaki 72 (`ksw`).
Donor list slot `0x0047B7C0` points to `kisame_ultimate_jutsu_list`
(`0x0047B640`), count 24, global records 314..337.
`kisame_ultimate_jutsu_records` (`0x004DB008`) contains the complete
24 × `0x24` records. The default at `0x0047BD80` selects 319;
mode-1 default at `0x0047BE00` selects 314.

| First record / English title | Authored skill | Ability prerequisites | Intro | Effect | Damage percent |
| --- | --- | --- | ---: | --- | ---: |
| 314 / Hidden Mist Jutsu | `0x6B` | 103 | 108 | `0x25` | 25 |
| 315 / Water Clone Jutsu | `0x6C` | 129,103 | 109 | `0x25` | 30 |
| 316 / Diminishing Slash | `0x6D` | 129,117 | 110 | `0x25` | 25 |
| 317 / Appetite Slash | `0x6E` | 129,117,116 | 111 | `0x25` | 30 |
| 318 / Water Style: Water Shark Bomb Jutsu | `0x6F` | 129,116,115 | 112 | `0xFFFF` | 35 |
| 319 / Water Style: Clinging Grand Whirlpool Jutsu | `0x70` | 129,115,136 | 113 | `0xFFFF` | 40 |

Records 320..325, 326..331 and 332..337 repeat these six skills with
title suffixes 2/3/4 and different metadata/stat adjustments. These are
six cinematic timelines, not 24 distinct films. Donor record `+6` is
prerequisite count and `+8..+0xC` holds prerequisite IDs; bytes
`+0xE..+0x11` have not been assigned NA2 category semantics.
The six signed stat adjustments at `+0x18..+0x22` vary across the list;
their consumer's full stat interpretation remains open.

Native list `0x005ACF80` contains four records 161/162/163/164;
default `0x005AFE40` selects 161. `kisame_ultimate_jutsu_records`
(`0x005AF8D4`) uses native `0x14`-byte records:

| Native record / stored title, ruby removed | Skill | Category / class / cost tier | Intro | Effect | Damage percent |
| --- | --- | --- | ---: | --- | ---: |
| 161 / `水遁・五食鮫` | `0x85` | 2 / 3 / 0 | 140 | `0xFFFF` | 25 |
| 162 / `水遁・無限鮫` | `0x86` | 3 / 3 / 2 | 141 | `0xFFFF` | 45 |
| 163 / `水遁・爆水衝波` | `0x87` | 1 / 3 / 1 | 142 | `0xFFFF` | 35 |
| 164 / `最凶の刺客` | `0x88` | 2 / 3 / 0 | 143 | `0xFFFF` | 30 |

The native secondary selector is `0xFFFF` in all four records.
Cinematic resources and donor placement/substitution tables belong to
[Kisame cinematics](#cinematics).

Donor `kisame_ultimate_effect_record` (`0x00474D1C`, effect `0x25`)
has an empty name, null factory, duration 600, flags 2 and stored factors
`{1.5,1.1,1.1,1.25,1,1,1,0,1,0.3}`. The inspected factory-binding
routine supplies no custom factory for this effect. Native effect
`0x4B`, `effect_4b_definition` (`0x0059FFF0`), is the established
**Samehada Mode** association for Kisame 72. Duration, flags and first nine
factors agree after the layout shift; its tenth factor is `0.05`,
and its trailing data contains count 6 and pointer `0x006031F0`.
Matching leading factors do not establish full effect equivalence.

Native trigger `0x005C1C70` stores event `0x1F`, flags 8;
association `0x005C1F70` stores `{0x4B,1}`.
The inspected NUN3 form getter `0x0028BFF0` only maps effects
`0x3D..0x46` to identities 47..56, so donor `0x25` requests no
replacement identity through UJ completion. The checked native
character-to-form map likewise gives Kisame 72 no linked form.
Neither result proves every effect-entry, stat or material consumer.
Remaining donor ordinary-mode admission, effect-factor consumers,
cleanup and identity-service branches are open.

## Cinematics

Checked donor: NUN3 Kisame 24 (`ksm`), skills `0x6B..0x70`.
The same-name native comparison is NA2 Kisame 72 (`ksw`), whose
four selected skills are `0x85..0x88`. Selection, damage metadata and
effects are owned by
[Kisame UJ/effects](#ultimate-jutsu-and-effects).

`kisame_cinematic_requests` (`SLUS_217.27 0x0067099C`) contains
six resident `0x14`-byte request rows, using NUN3's own
[request/playback contract](guy.md#cinematics).
Each has zero explicit extra providers and one stream. Main path strings
are `0x0066FD00/20/40/60/80/A0`; stream pairs are
`0x0066EB10/30/50/70/90/B0`, pointing to the preceding stream strings.
The clean outer section walks reach decompressed EOF:

| Skill / title | Resident / stream pair under `STR/` | Marked stream keys | Camera ID / `0x0502` frames | Missing with native common providers |
| --- | --- | ---: | --- | ---: |
| `0x6B` / Hidden Mist | `D24_101E / D24_101` | 189 | 852 / 331 | 20 |
| `0x6C` / Water Clone | `D24_102E / D24_102` | 208 | 599 / 271 | 16 |
| `0x6D` / Diminishing Slash | `D24_103E / D24_103` | 170 | 484 / 271 | 21 |
| `0x6E` / Appetite Slash | `D24_104E / D24_104` | 177 | 614 / 276 | 25 |
| `0x6F` / Water Shark Bomb | `D24_105E / D24_105` | 203 | 762 / 329 | 24 |
| `0x70` / Clinging Grand Whirlpool | `D24_301E / D24_301` | 223 | 913 / 361 | 2 |

Every stream has one `CAM_camera01`, the stated number of nonterminal
frame markers and one terminal marker. No outer tag `0x0108` appears.
All marked stream and resident keys match the matching resident companion,
donor `1KSMBOD1`, `1CMNBOD1`, `STRMCMN` and `CMN/EFFECT0X`.
Matching exact namespace/name keys is not full typed-record or lifetime closure.

The last column keeps the donor companion/body but replaces the three
common providers with native `PL/1CMNBOD1`, `STRMCMN` and
`CMN/EFFECT0X`. Every film then lacks common-1 objects
`OBJ_1cmn00t0 joe01/cloth3`; the first five also lack selected donor
effect textures/objects. Examples shared across the first five are
`TEX_e0yline06` and `TEX_e0ycolor01`. The Whirlpool film's only two
missing keys are the common-1 objects. Equal common-provider basenames
therefore do not establish this set's destination dependencies.

`kisame_cinematic_auxiliary_entries` (`0x0047C3F4`) selects
request-ordinal arrays `0x006A10B0/B4/B8/BC/C0/C4`.
Their selected two-request descriptors are consecutive entries among
`0x00588A60/588E90/5892A0/5896B0/589AE0/58A230/58A360`;
all four timed counts at `+0/+0xC/+0x18/+0x24` are zero in each.
These are scene/renderer auxiliary records, not established damage/audio rows.

`kisame_cinematic_position_entries` (`0x0047CB04`) selects counted
signed-short frame thresholds and defender-ID-indexed signed XYZ triples:

| Skill | Position descriptor | Short frame thresholds | Checked Classic Naruto defender 1 triples |
| --- | --- | --- | --- |
| `0x6B` | `kisame_hidden_mist_defender_positions 0x005E3420` | 1,120,136,161 | `{0,0,0},{0,0,0},{0,0,5},{0,0,0}` |
| `0x6C` | `kisame_water_clone_defender_positions 0x005E3FA0` | 1,31,71,86,117,136 | `{0,0,0},{0,0,0},{0,0,0},{0,-11,0},{13,0,18},{-22,0,0}` |
| `0x6D` | `kisame_diminishing_slash_defender_positions 0x005E4740` | 1,76,97,133 | `{0,0,2},{0,15,7},{-5,0,0},{0,0,0}` |
| `0x6E` | `kisame_appetite_slash_defender_positions 0x005E4D20` | 1,60,115,140 | four zero triples |
| `0x6F` | `kisame_water_shark_bomb_defender_positions 0x005E4E20` | 1 | one zero triple |
| `0x70` | `kisame_grand_whirlpool_defender_positions 0x005E4F80` | 1,173 | two zero triples |

`sp_skill_play_update` (`0x00294F10`) consumes thresholds as shorts,
selects the corresponding six-byte XYZ triple and constructs a translation.
The checked defender-1 values do not describe every defender.
All six appearance-script pointers at `0x0047C8D4` and camera-admission
range entries at `0x0047C1BC` are null. Palette/substitution pairs at
`0x0047D088` are zero except Water Clone: pointer `0x0047CD10`, count 3.
Its three records at `0x005F49F0/5F4A20/5F4A50` name
`EXT_2ksm02t0 body`, `EXT_2ksm00t0 body`, and `EXT_2ksm03t0 body`,
with `CLT_2ksmbodyc1` and `CLT_2ksmbodyc2` at `0x005F49C8/D8`.
Their full consumer interpretation and typed model/palette chains remain open.

The six startup intros are separately joined to donor SOUND members
108..113 in [Kisame voice](#voice).
`sp_skill_play_frame` (`0x002952B0`) only delegates camera auxiliary
update in the inspected NUN3 code. The six skills' own cinematic damage
and spoken-cue scheduler remains open, as do nested scene commands,
full camera semantics, participant substitutions and typed descendants.
Absence of an outer event tag does not prove silence or absence of damage.
Complete file identities are in
[Kisame inputs](../../../game/files/file_identities.md#kisame-comparison-inputs).

## Voice

Checked identities: **NUN3 Kisame 24 (`ksm`)** and **retail NA2 Kisame
72 (`ksw`)**. Compact SNDDATA, sparse PLVOICE and cinematic SOUND
selection are separate domains. All archive offsets below identify clean
file bytes, not live EE addresses.

| Compact bank | Resident descriptor | SNDDATA header offset / bytes | Aligned sample offset / bytes |
| --- | --- | --- | --- |
| NUN3 English | `0x003883B0` | `0x00ACE800 / 0x13B0` | `0x00AD0000 / 0x5F010` |
| NUN3 Japanese | `0x0038865C` | `0x01B31000 / 0x13B0` | `0x01B32800 / 0x50B90` |
| NA2 Kisame | `0x003FDB90` | `0x011AD000 / 0xF60` | `0x011AE000 / 0x44020` |

Donor voice-list pair `0x003891E8` points to `0x004E4F30` in both
slots; native pair `0x00406F18` points to `0x005C16C0` twice.
The complete `0x50`-byte list payloads agree. The inspected own-game
list selectors have no Kisame-specific alternate arm. Matching lists do
not establish matching bank samples or identical event producers.

Applying the [compact program lookup](../../session/battle_audio.md#compact-program-to-vag-lookup)
to these clean banks gives the selected candidates below. Programs
0/6/7/26 use key `0x3C`; program 27 uses the checked direct key `0x60`.
Each selected split admits keys 12..119; both set/sample velocity intervals
are 1..127. Each candidate has rate 22,050 Hz.

| Program | NUN3 Sset / Smpl / Vagi | English sample offset | Japanese sample offset | NA2 Sset / Smpl / Vagi / sample offset |
| --- | --- | --- | --- | --- |
| 0 | 0 / 0 / 13 | `0x00AE47B0` | `0x01B47350` | 0 / 0 / 3 / `0x011B5130` |
| 6 | 6 / 6 / 10 | `0x00ADACB0` | `0x01B40090` | 6 / 6 / 0 / `0x011AE000` |
| 7 | 7 / 7 / 11 | `0x00ADE1E0` | `0x01B423B0` | 7 / 7 / 1 / `0x011AFD20` |
| 26 | 26 / 26 / 39 | `0x00B2AE80` | `0x01B7F480` | 23 / 23 / 28 / `0x011EC430` |
| 27 | 27 / 27 / 19 | `0x00AEFA40` | `0x01B4F040` | No program-27 record |

`kisame_channel2` (`NUN3 0x00202180`) emits direct control `0x1B`
with key `0x60` at marker 58. The control row at `0x00385518` selects
program 27; this establishes that particular producer-to-sample join.
Donor channel 3 emits fighter events 6/7 during actions 4/5/6;
the normal list maps them to controls/programs 6/7. These are compact
requests, not PLVOICE member indices.

The separate spatial SFX helpers `audio_emit_spatial_sfx_control`
(`0x001894B0`) and `audio_emit_spatial_sfx_control_with_key`
(`0x00189700`) index eight-byte rows at `0x00385A90`, derive positional
gain/direction and submit program/key commands to the global sound context.
They use the row's default key or the explicit caller key, respectively.
Water Shark's projectile impact requests controls 9/`0xB`; wall termination
requests `0x79`/9 at key `0x3C`, and its six-update motion interval requests
`0x35` at key `0x46`. Channel 3's action-38 marker 7 requests control
`0x28` through the default-key helper. These are SFX table indices,
distinct from the fighter voice table and from effect factory IDs.
Physical SFX samples, remaining ordinary-jutsu/direct commands and
audible/spoken-content comparisons remain open.

Donor PLVOICE descriptors `0x00388B38/0x00388CF8` declare 209 slots
and select physical outer entries 23/79. The two archives begin at
`0x00A70000/0x01AA7000`, sizes 561,152/428,032 bytes, each with
29 populated sparse indices:
`6,7,23,24,45,47,49,50,68,69,85,92,100,101,102,103,104,105,111,112,118,125,151,165,166,167,199,202,208`.
The checked physical members 100..105 are:

| Sparse member | English file offset / bytes | Japanese file offset / bytes |
| --- | --- | --- |
| 100 | `0x00AA3000 / 21128` | `0x01ACC800 / 16323` |
| 101 | `0x00AA8800 / 11076` | `0x01AD0800 / 7321` |
| 102 | `0x00AAB800 / 20381` | `0x01AD2800 / 17851` |
| 103 | `0x00AB0800 / 13594` | `0x01AD7000 / 15432` |
| 104 | `0x00AB4000 / 28156` | `0x01ADB000 / 22705` |
| 105 | `0x00ABB000 / 25987` | `0x01AE1000 / 22917` |

These six members' physical existence does not establish each film's cue
producer or timing. Native PLVOICE descriptor `0x003FE228` declares 42
physical members; outer entry 71 starts at `0x00DE3000`, size 571,392,
and all members 0..41 are populated. Native's 42-entry suffix list at
`0x003FF280` contains none of 100..105. Directly copying a donor sparse
index into that physical bank would select a different domain.

The selected donor UJ startup intro selectors 108..113 use SOUND family
9 or 23 through `audio_request_sound_member_for_voice_set`
(`0x0018A1C0`), descriptors `0x00388878/0x003888E8`.
Native selected intros 140..143 use family 7, independent of PLVOICE:

| Donor intro | SOUND outer 9 offset / bytes | SOUND outer 23 offset / bytes |
| --- | --- | --- |
| 108 | `0x12F35800 / 19582` | `0x26286800 / 22061` |
| 109 | `0x12F3A800 / 10411` | `0x2628C000 / 11841` |
| 110 | `0x12F3D800 / 14343` | `0x2628F000 / 10546` |
| 111 | `0x12F41800 / 20684` | `0x26292000 / 25059` |
| 112 | `0x12F47000 / 16402` | `0x26298800 / 10155` |
| 113 | `0x12F4B800 / 19006` | `0x2629B000 / 16764` |

Native family-7 intro 140/141/142/143 offsets and sizes are
`0x0842F800/11566`, `0x08432800/14429`, `0x08436800/13969`,
and `0x0843A000/35860`.
The NUN3 cinematic damage/spoken-cue scheduler remains open;
the startup join does not establish all later dialogue.
Complete SNDDATA/PLVOICE identities and donor SOUND outer identities
are already recorded in [File identities](../../../game/files/file_identities.md).
