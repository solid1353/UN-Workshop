# Green Beast: NUN3 donor

## Research coverage

Established for NUN3 Green Beast against NA2 Classic Naruto: its own class and
moves, Guy-derived jutsu (sharing Guy's actors), the Green Impact cinematic,
voice banks, the cross-CHA anchor, and the common muffler and effect providers
NA2 lacks.
Open: typed asset descendants, effect consumers, ID-dependent services, dialogue
voice mapping, and input and contact semantics.

Names come from `@annotations/NUN3` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [NUN3 and NUN4 characters](../nun3_nun4_characters.md).

## Records, moves and assets

Checked donor: **NUN3 Green Beast, ID 32 (`0x20`), `nrz`**, in
`SLUS_217.27` / `BATTLE.BIN`; its resident display name is `ナルトＺ`.
Checked same-age comparison: **retail NA2 Classic Naruto, ID 1, `nrt`**,
in `SLPS_258.37` / `BTL.BIN`. NA2 modern Naruto is the separate
ID 57 (`nrw`); the action comparison below concerns ID 1. NA2 ID 32
points to Classic Naruto's filler definition and has null filename families;
it is not a dedicated Green Beast fighter.
Addresses below are live; CCS IDs are local to their file.

### Fighter records and lifetime

| Item | NUN3 Green Beast 32 | NA2 Classic Naruto 1 |
| --- | --- | --- |
| Definition / record | `green_beast_definition`, `0x00476830` / `green_beast_character_record`, `0x0040DAF0` | `0x005A2908` / `0x0040DB70` |
| Factory / constructor | `green_beast_create`, `0x00207260` / `green_beast_construct`, `0x002072B0` | `0x00250C00 / 0x00250C50` |
| Allocation / vtable | `0x54B0` / `green_beast_vtable`, `0x00689130` | `0x5980` / `0x005DB170` |
| Authored actions, stride `0x54` | 46 at `green_beast_actions`, `0x0040CBD0` | 48 at `0x0040CBA0` |
| Phase rows, stride `0x4C` | 179 at `green_beast_animation_rows`, `0x004096A0` | 190 at `0x00409110` |
| Animation-name slots | 157 at `green_beast_animation_names`, `0x00409420` | 156 at `0x00408CA0` |

The donor constructor runs the common base constructor, installs the concrete
vtable at fighter `+0x50`, copies descriptor `0x0040DBD0`, and assigns
embedded name/action/row working storage at `+0xE00/+0x1074/+0x1F8C`.
It invokes the record loader and sets failure flag bit 0 on failure.
It does not call the additional Classic Naruto setup: NUN3 Classic Naruto's
constructor `0x001D9DA0` calls `0x001D9F30`, while NA2 Classic Naruto's
constructor calls `0x00250DE0` after installing working storage at
`+0xEE0/+0x1150/+0x2110`.
`green_beast_destroy` (`0x00207370`) performs common cleanup and base
destruction, with deleting-flag free; no private allocated child is released.

Only two words differ in the raw record parameter region `+0x58..+0xDB`:
`+0x60` is float 26 versus 20, and `+0xCC` is float 1 versus 1.2.
Their full gameplay meanings were not established; this comparison does not
assign them speculative movement or damage names.

The first twelve vtable words are
`{0,0,207370,1D39C0,1D3AD0,1D3C60,1D3D20,2073F0,1D5870,1D3C50,1D3D10,1D3E40}`
(hexadecimal live addresses). Slot `+0x1C` is
`green_beast_ai_update` (`0x002073F0`): nonzero controller flags
`(fighter[+0x60] & 0x1FF) >> 5` invoke
`ai_tick` (BATTLE `0x00825260`).
The actual-ID descriptor pair is `{2,50}` at `0x0093AEF0`.
This identifies the entry and indexed data, not a complete AI policy.

### Complete authored action sequences

The following reads all donor/native action and phase arrays. Indices here
are hexadecimal. Suffixes are prefixed `ANM_pnrz` in the donor and
`ANM_pnrt` in NA2, except shared `ANM_pcmnjmp2`. Names and order do
not prove equivalent motion, contacts, timing or input admission.

Actions 0..3 are separate jutsu preparation/execution slots. Donor 0 has
an empty name-slot route; 1 is `cha00`, 2 is `chb10/chb12`, and 3
is `cha10`. Native 0 is `chb00/chb02`, 1 `cha00`, 2 an empty slot,
and 3 `cha10`. Donor selectors are `1/64/65/65`, native
`2/2/1/3`; the first four donor owner fields are all ID 32.

Both arrays' 4..6 start `rdy1` and select `spl0/1/2`. Donor 5/6
have a single opening `spl10/spl20`; native repeats those opening
phases, gives action 6 a `lan0` tail and uses terminal duration -17.
Both arrays' 7..9 are `nxs0/sig0/sig0/sxn0`, with the two signal
durations 16 and 8. Both action 13 sequences are shared jump, `jmp1`,
`dow1/jpz1/jpz0`. Native additionally has action 14
`pcmnjmp2/elb20/elb20/elb22/lan0/ost0`, category `0x04000000`.

| Aerial action | Donor middle sequence | Native middle sequence |
| --- | --- | --- |
| A | `kca70/kca72` | `elb20/elb20/elb22` |
| B | `ela10/ela12` | `pnc50/pnc50/pnc52` |
| C | `pna30/pna30/pna32` | `pna30/pna30/pna32` |
| D | `kcn50/kcn52` | `fin00/fin02` |
| E | `kca60/kca62` | `kca60/kca62` |
| F | `pna40/pna40/pna42` | `pna60/pna60/pna62` |
| 10 | `kca80/kca82` | `elb30/elb32` |
| 11 | `ela20/ela22` | `pna40/pna42` |
| 12 | `pna50/pna50/pna52` | `pna50/pna50/pna52` |

All have a `lan0` tail. Donor B starts `jmp0`, C `dow0`; other
donor aerials start `jmp1`, whereas all native A..12 start `jmp1`.
Repeated donor `pna30/40/50` phases last 8; native repeated
`pna30/60/50` phases last 4. Native A/B repeat their first attack for
duration 1. The terminal attack phases use -17.

The ground arrays below are independent sequences; their columns do not
equate equal numeric slots. Each listed two-phase family ends in 0/2
unless the full suffix sequence is written.

| Donor action group | Complete donor families | Native action group | Complete native families |
| --- | --- | --- | --- |
| 14..20 | `pnc0, kcn0, kcn1, kcn4, crs0, kcn70/71/72/73/74, kcn6, pnc1, kcs20/kcs20/kcs22, kcs0, kcs1, pnc2, kcn3` | 15..24 | `pnc0, pnc1, elb0, kcn4, kcn0, pnc3, pnc8, pnc6, pnc20/21, pnc22/23, kcs0, kcs2, crs0, kcn2, hol00/01, hol02/03` |
| 21/22 | `hol00/01, hol02/03` | — | Included above |
| 23..28 | `pna0, kca0, kca4, kca30/kca30/kca30/kca32, ela0, kca5` | 25..2A | `pna0, kca0, kca1, kca20/kca20/kca20/kca22, kca3, pna2` |
| 29/2A | `hla00/01, hla02/03` | 2B/2C | `hla00/01, hla02/03` |
| 2B..2D | `kca10/kca10/kca12, kca2, pna1` | 2D..2F | `kca40/kca40/kca42, pna1, kca5` |

Donor repeated `kcs20` lasts 2; triple `kca30` durations are 2/1/12,
compared with native triple `kca20` at 3/1/12. Repeated donor
`pna00` lasts 8, native 12; donor `kca10` and native `kca40`
repeat for 12. Ground final phases in the latter groups use -17.
Stored donor titles include **Iron Fist Flurry** (19),
**Green Whirling Attack** (1A), **Heavenly Dance of Falling Leaf** (1C)
and **Smashing Fist** (20).
Callback differences belong to
[Green Beast callbacks](#callbacks).

### Ordinary jutsu and typed provider dependencies

Donor action 1 is **Ultimate Entry**, selector 64, stored cost 4.5;
action 3 is **Primary Lotus**, selector 65, stored cost 0.
Native Classic Naruto's corresponding titles are
`多重影分身の術` and `螺旋丸`.
NUN3 resident provider rows at `0x004764D8` select
`2nrzcha0/1.ccs`; BATTLE selector rows at `0x0093E900` map
64/65 to resources 67/68.
The startup animations have explicit tag-`0x0108` commands at frame 1:

| File / animation | Target ID | Command words |
| --- | ---: | --- |
| `2NRZCHA0 / ANM_pnrzcha00` | 51 | `0x8003,0x143` |
| `2NRZCHA1 / ANM_pnrzcha10` | 28 | `0x8003,0x144` |
| NA2 `PL/2NRTCHA1 / ANM_pnrtcha10` | 196 | `0x8003,0x101` |

NUN3 `jutsu_create_by_resource` (BATTLE `0x0086C740`) uses
jump table `0x0093FB90`. Resource 67's
`green_beast_ultimate_entry_factory_case` (`0x0086D280`) allocates
`0x790` and calls `guy_dynamic_entry_construct` (`0x00899250`);
68's `green_beast_primary_lotus_factory_case` (`0x0086D2A8`)
allocates `0x880` and calls `guy_primary_lotus_construct`
(`0x0089B860`). Their lifecycle and state roots are the shared Guy
classes documented in [Guy ordinary jutsu](guy.md#ordinary-jutsu-and-provider-domains).
Green Beast's corresponding per-resource variant pointers at
`0x0092371C/20` are null.
NA2 factory entries `0x008CD2FC/300` point at
`jutsu_resource67_empty_factory_case` (`0x0077459C`) and
`jutsu_resource68_empty_factory_case` (`0x007745A8`). Both contain a
zero store and an unconditional branch to the stack-restore/return epilogue
at `0x00776004`, with no allocation or constructor. Equal resource
numbers do not imply a retained actor.

`guy_dynamic_entry_bind_animations` (`0x00899510`) checks resource
`0x43` and binds `ANM_pnrzcha00/01/02`; its remaining three names
come from source fighter slots `0x45/0x37/0x3B`.
The Primary Lotus class binds `ANM_pguyskl10` and draws from
`OBJ_eff_dummy_guyall`. Both names actually exist in `2NRZCHA1`;
a Guy-prefixed name alone does not establish a dependency on `2GUYCHA1`.
Its state setter's resource-`0x44` arm emits source dialogue cue 0;
state 1 emits cue 1. The shared class owns participant locks, movement,
collision, an embedded animation player, surface-selected particles and
destruction. The checked indirect routes, local geometry, common leaf
particle and hit/landing graphs are owned by
[Shared Guy jutsu actor dependencies](guy.md#shared-guy-jutsu-actor-dependencies)
and [Lotus geometry and particles](guy.md#shared-lotus-local-geometry-and-surface-particles),
with [shared contact and landing effects](guy.md#shared-contact-and-landing-effects).

Checked donor providers are `2NRZBOD1`, `1NRZBOD1`,
`2NRZCHA0/1`, `3EYE/3NRZ3EYE` and `3EYE/3NRZ3PCT`.
Their battle body/CHA0/CHA1 have 120/4/10 animation directory names.
Record palette names at `0x004091F0` are
`CLT_2nrzbody/bodyc1/bodyc2` and `CLT_2nrzbod2/bod2c1/bod2c2`,
followed by six empty 30-byte entries. Texture names at `0x00409358`
are `TEX_2nrzbody/bod2`; model names at `0x00409398` select
`MDL_2nrz00t0 body` with an empty second entry. Anchor
`0x004093D8` names `OBJ_eff_dummy_nrzhol0`.

The donor body has 38 marked common-2 keys, all present in NUN3's
`CMN/2CMNBOD1`, but only 34 present in NA2's copy. Missing exact keys
are `OBJ_2cmn00t0 muffler/muffler1/muffler2/muffler3`, donor directory
IDs 1101/1103/1105/1107. These are referenced by local tag-`0x0A00`
wrappers 1100/1102/1104/1106, whose parent chain is
1079 → 1100 → 1102 → 1104 → 1106. This is an actual typed
dependency, not just four unused directory names.
Both jutsu files' 25 marked common-2 keys occur in NA2's common provider.

CHA0 local wrapper 51 `OBJ_eff_dummy_guycha1` targets marked key 52
`OBJ_eff_dummy_nrzcha1` under
`#c\\2nrz\\max\\2nrzcha1.max`. CHA1 supplies that exact key as local
tag-`0x0100` object 106 with no model ID. This establishes an
inter-file transform-anchor dependency. The eye file's 66 marked keys
resolve against the donor's `1NRZBOD1`; it contains
`ANM_3nrzwin00/10`, while the 1BOD and portrait contain no animations.
These checks bound the providers. The selected shared Lotus auxiliary,
surface-particle and common hit/landing chains are established above;
complete Green Beast body, other jutsu tracks and cinematic geometry,
and provider load lifetime remain open.
Complete source identities are in
[Green Beast inputs](../../../game/files/file_identities.md#green-beast-comparison-inputs).

## Callbacks

This bounded comparison checks NUN3 Green Beast 32 (`nrz`) against
NA2 Classic Naruto 1 (`nrt`), not modern Naruto 57 (`nrw`).
NUN3 `green_beast_callbacks` (`SLUS_217.27 0x00409400`) contains
`{0,207430,207440,2077B0,0,0,0}` (hexadecimal live addresses).
`green_beast_channel2` (`0x00207430`) is a verified `jr ra;nop`
leaf. Channel 3 and source-response therefore carry the concrete action logic.

`green_beast_channel3` (`0x00207440`) uses local action/phase markers:

| Action / phase | Marker | Indexed SFX | Compact voice event |
| --- | ---: | ---: | ---: |
| `0x19` / 0 | 8 | `0x20` | 5 |
| `0x19` / 1 | 8 | `0x20` | 5 |
| `0x19` / 2 | 13 | `0x23` | 5 |
| `0x19` / 3 | 4 | `0x20` | 7 |
| 4 / 1 | 11 | `0x20` | -2 |
| 5 / 1 | 8 | `0x23` | -2 |
| 6 / 1 | 8 | `0x20` | -2 |

Action `0x1E`, phase 0, marker 12 requests positional SFX `0x2A`.
Pseudo voice -2 selects one of events 6/7/8 or suppresses it through the
checked voice helper. These calls are voice requests, not effect IDs.

`green_beast_hit_response` (`0x002077B0`) overrides actions
`0x17/19/1B/1C/1E/1F`, returning destinations from
`{-1,27,29,2B,2C,2D,2E,30,31,36,3A,3B}` (hexadecimal).
Receiver scale writes at `+0x8F0/+0x8F8/+0x8FC` occur only when
the callback mode is 2. Action 19 phases 0/1/2 return `2C/2B/2C`;
late phases 3/4 select `3B` if receiver `+0x8E0 == 0x306`, otherwise
`3A`, and use vertical factor 1.25 in mode 2.
The annotation retains the other inspected branches; the meaning of the
auxiliary count helper has not been assigned.

NA2 Classic Naruto's table at `0x00408320` is
`{0,252C20,252C30,2536C0,2539E0,0,0}`.
It includes an additional channel-5 callback. Different callback roots,
action numbering and class layouts prevent equating the donor's events
with native Naruto's equal numeric slots. Native callback-body equivalence,
all indirect descendants and input reachability remain open.

## Ultimate Jutsu and effects

Checked identities: NUN3 Green Beast 32 (`nrz`) and NA2 Classic Naruto
1 (`nrt`). Modern NA2 Naruto 57 (`nrw`) is a separate identity.
NUN3's character-list slot `0x0047B7E0` points to
`green_beast_ultimate_jutsu_list` (`0x006A0E38`):
count 3, global records 368/369/370. Both checked default tables select
368: `green_beast_ultimate_default` (`0x0047BD90`) and
`green_beast_ultimate_mode1_default` (`0x0047BE10`).
The `0x24`-byte records begin at
`green_beast_ultimate_jutsu_records` (`0x004DB7A0`).

| Record / English title | Authored skill | Ability prerequisite | Intro member | Effect | Damage percent |
| --- | ---: | ---: | ---: | ---: | ---: |
| 368 / Green Impact | `0x79` | 80 | 122 | `0x2B` | 30 |
| 369 / Green Impact 2 | `0x79` | 80 | 122 | `0x2B` | 30 |
| 370 / Chakra Release | `0xFFFF` | 80 | -1 | `0x3C` | 0 |

The prerequisite count is 1 at record `+6`; the first ability ID is 80
at `+8`. It is not NA2's category field. Record
`+0xE..+0x11` bytes are `00 01 01 01`, `00 01 02 02` and
`00 01 04 00`; their full selection semantics remain open.
The six stored stat adjustments are
`{10,-10,-20,20,0,0}`, `{30,-10,-20,20,0,0}` and all zero.
`ultimate_jutsu_record_stat_adjustment` (`0x0028BD00`) reads them
from `+0x18..+0x22`; individual stat meanings were not established.
Thus the two Green Impact records select one timeline and differ in metadata.

NA2 Classic Naruto's list at `0x00604320` contains only records 1/2.
At `0x005AEC54/68`, they select authored skills 1/2,
categories 2/3, intro members 0/1, effects `0x0E/0x68`, and damage
25/20 percent. The stored titles are `うずまきナルト連弾` and
`うずまきナルト忍法帳` (ruby markup omitted).
Native record 2's effect `0x68` maps to Nine-Tailed Naruto ID 47;
modern Naruto's separately established effect `0x72` maps ID 57 to 73.

The inspected NUN3 effect-to-form getter `0x0028BFF0` accepts only
`0x3D..0x46`, producing IDs 47..56. Neither selected Green Beast
effect `0x2B/0x3C` returns a replacement identity.
`sp_skill_play_end` (`0x00295E00`) consequently receives form zero
for these records through that getter. This bounds the checked UJ completion
route; it does not establish every roster/form helper or the complete
stat, material and mode behavior of these two effects.
Their effect implementations, ability availability and other ID-dependent
awakening services remain open.

## Cinematics

This section checks NUN3 Green Beast 32 (`nrz`), selected global
records 368/369 and authored skill `0x79`; both records select the
same **Green Impact** cinematic. NA2 Classic Naruto 1 (`nrt`)
instead selects skills 1/2; this is not a comparison against modern
Naruto 57's cinematics.
The list, damage and non-replacing effects belong to
[Green Beast selection](#ultimate-jutsu-and-effects).

`green_beast_cinematic_request` (`SLUS_217.27 0x00670AB4`) is an
own-game **resident ELF** `0x14`-byte row, not a decoded SINF row.
Its display name is at `0x00669DB8`, main path at `0x0066FEC0`
is `str/d32_301e.ccs`, extra count is 0 and stream count is 1.
Stream pair `0x0066ECD0` points to
`str/d32_301.ccs` at `0x0066ECC0`.
`sp_skill_request_row` (`0x00373FB0`) indexes resident
`0x00670140`; `sp_skill_build_requests` (`0x00296030`)
requests the main with flag `0x1000` and first stream with `0x400`.

`ultimate_jutsu_presentation_update` (`0x002E36D0`) requests
the selected intro via `audio_request_sound_member_for_voice_set`
(`0x0018A1C0`), then at its 85-count transition classifies skill
`0x79` as ordinary cinematic playback through `sp_skill_play_start`
(`0x00296250`). Intro 122 belongs to SOUND family 9's language
descriptor, not PLVOICE's character-32 archive.
The checked completion path with result 1 and effect in `0x0E..0x3C`
starts the subsequent effect presentation.

The clean stream contains one tag-`0x0500` camera object,
directory ID 613 `CAM_camera01`, and 371 tag-`0x0502` camera frames.
It has 371 nonterminal frame markers plus a terminal marker; its complete
outer section walk reaches decompressed EOF. No tag-`0x0108` event
occurs in the outer stream. The resident E file contains no animations;
its local models/materials/textures provide the effect geometry.

Of 198 marked stream keys, 194 match the resident E file plus donor
`1NRZBOD1` and `1CMNBOD1`. The remaining four have typed definitions
in donor `CMN/EFFECT0X`:

| Stream key | NUN3 common provider ID / type |
| --- | --- |
| `TEX_e0yline04` | 157 / `0x0300` |
| `OBJ_e0yline04` | 1046 / `0x0100` |
| `OBJ_e0yline07` | 2458 / `0x0100` |
| `TEX_e0yline07` | 2464 / `0x0300` |

The corresponding exact names are absent from NA2's checked
`CMN/EFFECT0X`. This establishes marked-name provider closure for
the donor set, with typed definitions for these four additional keys;
it does not establish full material/model descendants or destination lifetimes.

`green_beast_cinematic_defender_positions` (`0x005E9630`)
has count 5, frame list `0x005E8F20 = {1,97,145,231,254}`, and
a null ID-0 entry followed by 56 defender-indexed pointers
`0x005E8F30..0x005E9610`, spaced by `0x20`.
Each contains five signed XYZ triples (`0x1E` bytes) plus padding.
For Classic Naruto defender ID 1, the triples are
`{0,0,-15}, {17,-15,8}, {23,-15,-5}, {4,-19,14}, {0,0,12}`.
The complete checked table contains distinct opponent data;
a single generic offset would discard it.

`green_beast_cinematic_auxiliary_requests` (`0x006A10E8`) selects
descriptors `0x00591B50` for request 0 and `0x00591F60` for request 1.
All four counted time channels (`+0/+0xC/+0x18/+0x24`) are zero
in both selected descriptors. The selected appearance-script pointer at
`0x0047C90C` is null and palette-substitution pair at `0x0047D0F8`
is zero.
`sp_skill_defender_camera_admission` (`0x00294770`) nevertheless
has a skill-specific exclusion: descriptor `0x005124D0` selects one
inclusive frame range 232..253. Only defenders
`0x38/35/23/32/33/30` consult it; other defenders always admit.
`sp_skill_play_frame` (`0x002952B0`) delegates camera auxiliary
update, without the own audio/hit-row loop found in NA2's frame callback.

**Open:** the NUN3-specific producer and scheduling of cinematic damage
and spoken cues; all typed geometry/material/effect descendants; the full
participant face/body substitutions and camera payload semantics.
Neither matching file framing nor the absence of outer event tags proves
that a cinematic is silent or has no damage events.
Complete file identities are in
[Green Beast inputs](../../../game/files/file_identities.md#green-beast-comparison-inputs).

## Voice

Checked donor is NUN3 Green Beast 32 (`nrz`); the fighter comparison
is NA2 Classic Naruto 1 (`nrt`), not modern Naruto 57 (`nrw`).
Compact, streamed dialogue and UJ intro archives are independent resources.
Source-file offsets below are explicitly archive/bank offsets, not live EE
or IOP addresses.

`green_beast_compact_bank` (`SLUS_217.27 0x00388410`) contains
SNDDATA triple `{0xD67000,0x1240,0x426D0}`.
Alternate descriptor `0x003886BC` contains
`{0x1D9F800,0x1240,0x426D0}`.
Aligned sample payloads begin at `0xD68800/0x1DA1000`.
The complete selected header ranges and complete sample ranges agree
byte-for-byte between these two banks. This is byte identity, not an
independent spoken-content comparison.

`fighter_voice_event_list` (`0x0019BDA0`) has special alternate
gates for IDs 31/20/3/2/1, not 32.
`green_beast_voice_event_list_pair` (`0x00389228`) points both
members to `green_beast_voice_event_list` (`0x004E4F30`):
`{0,1,2,3,4,5,6,7,8,12,13,14,15,16,17,18,19,20,21,22,23,24,25,28,26,27,38,39,40,23,36,37,41}`.
Controls come from the eight-byte table `0x00385440`.
`fighter_request_voice` (`0x0019C1D0`) resolves pseudo -2 to
6/7/8 or suppression; `fighter_request_voice_event`
(`0x0019C0B0`) admits indices 0..32 and gates events 24/25 by cooldown
and major state. The concrete channel-3 producers are recorded in
[Green Beast callbacks](#callbacks).

Using the [decoded compact lookup](../../session/battle_audio.md#compact-program-to-vag-lookup),
the checked default key `0x3C`, velocity 1..127, selects one sample
per program in each bank. All listed VAG sample rates are 22050 Hz:

| Compact program | Selected Sset / Smpl / VAG index | Set-0 sample offset | Set-1 sample offset |
| ---: | ---: | ---: | ---: |
| 0 | 0 | `0xD68800` | `0x1DA1000` |
| 5 | 5 | `0xD6CBB0` | `0x1DA53B0` |
| 6 | 6 | `0xD6EDB0` | `0x1DA75B0` |
| 7 | 7 | `0xD708D0` | `0x1DA90D0` |
| 8 | 8 | `0xD72D20` | `0x1DAB520` |
| 26 | 26 | `0xD957D0` | `0x1DCDFD0` |
| 27 | 27 | `0xD97F70` | `0x1DD0770` |
| 28 | 34 | `0xDA91B0` | `0x1DE19B0` |
| 38 | 30 | `0xDA07F0` | `0x1DD8FF0` |
| 39 | 31 | `0xDA1ED0` | `0x1DDA6D0` |
| 40 | 32 | `0xDA4420` | `0x1DDCC20` |

Thus program number is not generally the sample/VAG index.
Event 24/25 use controls 26/27; program 27 is present in this donor bank.
These candidates do not establish actual audible admission or the meaning
of every cue; dynamic key selection remains a separate call-site condition.

Streamed descriptors `0x00388B78/0x00388D38` select PLVOICE outer
members 31/87, handles 101/157, declared nested count 209 in both.
Each contains 26 populated physical members:
`6,7,23,24,45,47,49,50,68,69,85,92,111,112,118,125,144,145,146,151,165,166,167,199,202,208`.
The selected outer source ranges begin at `0xC96800/0x1C44800`,
sizes 473088/393216 bytes.
Member 6's absolute payloads are `0xC97000`, 19526 bytes, SHA-256
`C4FD6AFF52094DE5C268B6491C43680F9E2944E652198341F860304270A70AAD`,
and `0x1C45000`, 22922 bytes, SHA-256
`B835585D39289C8F30AB2869BC41513886C6E3348EBAD8C8337C3557D2232207`.
Equal nested indices do not identify equal clips across games or languages.
Primary Lotus emits dialogue selectors 0/1 through its source participant;
the selected physical member for those selectors remains unestablished.

Both selected Green Impact records use SOUND intro member 122.
`audio_request_sound_member_for_voice_set` (`0x0018A1C0`)
selects family 9 or 23 through descriptors `0x00388878/0x003888E8`,
each declaring 149 members. The physical payloads are:

| SOUND outer / nested member | Absolute archive offset | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| 9 / 122 | `0x12F70800` | 12860 | `117920D47895171AAFFD06B49485FD42E942379B9D1F835AE1C39D8B82C9CE6E` |
| 23 / 122 | `0x262BA800` | 13019 | `1B16F6DA34A916C1E8CCA9AF41781E0835D3E8DE6F2B88EC1371A9A34F96FC99` |

The compact and PLVOICE base identities are already owned by
[File identities](../../../game/files/file_identities.md); SOUND outer
identities are under [Guy inputs](../../../game/files/file_identities.md#guy-comparison-inputs).
The donor UJ dialogue/damage cue scheduler and spoken-content comparison
against NA2 Classic Naruto remain open.
