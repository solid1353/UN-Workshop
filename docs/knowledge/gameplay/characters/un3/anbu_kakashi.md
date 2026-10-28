# ANBU Kakashi: UN3 donor

## Research coverage

Established for UN3 ANBU Kakashi 30 against NA2 Kakashi 70: katana moves,
46 actions, 179 rows and 157 names, callbacks and parameters; Young Lightning on
the shared Lightning Blade's ANBU branch; Young Fang's players, contacts and
camera, interrupts and borrowed handle; Hazy Moon's variants, placement,
soundtrack and cue rows; effect `0x2A/0x3C` factors; response translation to
NA2; NA2 reading of every donor file and the definitions NA2 lacks; compact
samples, sparse streamed banks, jutsu dialogue, end-demo quotes and intro 121.
Open: the trigger route of the effect-only Chakra Release record; which clips
match intended lines needs listening.

Names come from `@annotations/UN3` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [UN3 and UN4 characters](../un3_un4_characters.md).

## Records, moves and assets

Checked donor: **UN3 ANBU Kakashi, ID 30 (`0x1E`), `anb`**,
in `SLUS_217.27` and `BATTLE.BIN`. The same-name destination
comparison is retail NA2 Kakashi **ID 70 (`0x46`), `kkw`**.
NA2 ID 30 is a four-action filler definition, with null filename families;
it does not supply this fighter. Ordinary UN3 Kakashi ID 8 is a separate
identity, documented [above](kakashi.md#records-moves-and-assets).
The clean donor files are identified under
[ANBU inputs](../../../game/files/file_identities.md#anbu-kakashi-comparison-inputs).

### Fighter records and lifetime

| Root | UN3 ANBU | NA2 Kakashi |
| --- | --- | --- |
| Definition / record | `0x00476820 / 0x004090C0` | `0x005A2B30 / 0x00525BC0` |
| Actions / phase rows / names | `0x004081A0 / 0x00404C70 / 0x004049F0` | `0x00524BF0 / 0x005212E0 / 0x00521020` |
| Counts | 46 / 179 / 157 | 48 / 186 / 157 |
| Factory / constructor | `anbu_kakashi_create`, `0x002060F0`; `anbu_kakashi_construct`, `0x00206140` | `0x002C6510 / 0x002C6560` |
| Allocation / concrete vtable | `0x54B0 / 0x00689160` | `0x5870 / 0x005DA650` |
| Descriptor / embedded names, actions, rows | `0x004091A0 / +0xE00,+0x1074,+0x1F8C` | `0x00525CA0 / +0xEE0,+0x1154,+0x2114` |

The donor constructor initializes embedded working arrays and common loading,
without allocating a separate private helper. `anbu_kakashi_destroy`
(`0x00206200`) runs common fighter/base cleanup and frees for a positive
deleting flag. Of the first twelve vtable words, only destruction and the
AI callback differ from ordinary UN3 Kakashi's common methods.
This is a bounded slot comparison.

The complete record `+0x58..+0xDB` comparison finds nine unequal words:

| Offset | ANBU value | Native value |
| --- | ---: | ---: |
| `0x94 / 0x98` | 600 / 800 | 500 / 700 |
| `0xAC / 0xB0` | 300 / 200 | 250 / 150 |
| `0xBC / 0xC0 / 0xC4` | 1.05 / 0.95 / 1.1 | 1.15 / 1 / 1.15 |
| `0xD4 / 0xD8` | 0.95 / 0.95 | 1 / 1 |

These are stored floating-point values; this comparison does not assign
untraced field meanings. `anbu_kakashi_ai_update` (`0x00206280`)
calls `ai_tick` (`BATTLE.BIN 0x00825260`) under controller flags.
That routine indexes the actual fighter ID at `+0x64` with stride 8.
`anbu_kakashi_ai_descriptor` (`0x0093AEE0`) contains `{1,5}`;
ordinary UN3 Kakashi's row contains `{2,0x46}`.
The comparison's NA2 Kakashi ID 70 uses the
[native per-character lookup](../../session/battle_ai.md#per-side-state-block).
Its four-byte layout and numeric domain differ from these donor descriptors.

### Complete authored action sequences

Both compared games use `0x54` actions and `0x4C` phase rows.
The following covers all 46 donor actions. Suffixes omit the own `panb`
prefix; repeated names are separate authored phases. The native sequence
table [above](kakashi.md#complete-authored-move-correspondence) supplies the complete
ID-70 comparison. Similar suffixes do not establish equal input, timing,
motion, contacts or damage.

| Action, decimal | Ordered animation suffixes |
| ---: | --- |
| 0 | empty |
| 1 | `cha00` |
| 2 | empty |
| 3 | `cha10` |
| 4 | `rdy1,spl00,spl02` |
| 5 | `rdy1,spl10,spl12` |
| 6 | `rdy1,spl20,spl22` |
| 7,8,9 | `nxs0,sig0,sig0,sxn0` |
| 10 | `jmp1,kca40,kca42,lan0` |
| 11 | `jmp1,pna30,pna32,lan0` |
| 12 | `jmp1,kca70,kca72,lan0` |
| 13 | `jmp1,pna10,pna12,lan0` |
| 14 | `jmp1,kca60,kca62,lan0` |
| 15 | `jmp1,pna70,pna72,lan0` |
| 16 | `jmp1,kca50,kca52,lan0` |
| 17 | `jmp1,pna50,pna52,lan0` |
| 18 | `jmp1,pna80,pna82,lan0` |
| 19 | `jmp2,jmp1,dow0,jpz1,jpz0` |
| 20 | `pnc00,pnc02` |
| 21 | `ktn00,ktn02` |
| 22 | `kcn00,kcn02` |
| 23 | `ktn20,ktn21,ktn22` |
| 24 | `ktn10,ktn12` |
| 25 | `ktn40,ktn42` |
| 26 | `ktn30,ktn31,ktn32` |
| 27 | `kcs10,kcs12` |
| 28 | `kni00,kni01,kni02` |
| 29 | `kni10,kni12` |
| 30 | `kni20,kni22` |
| 31 | `elb00,elb00,elb02` |
| 32 | `kcs00,kcs02` |
| 33 | `hol00,hol01` |
| 34 | `hol02,hol03` |
| 35 | `kna10,kna10,kna12` |
| 36 | `kna20,kna20,kna22` |
| 37 | `kca20,kca20,kca20,kca22` |
| 38 | `pna00,pna00,pna00,pna02` |
| 39 | `ela00,ela02` |
| 40 | `kca30,kca32` |
| 41 | `hla00,hla01` |
| 42 | `hla02,hla03` |
| 43 | `kca00,kca00,kca02` |
| 44 | `kca10,kca12` |
| 45 | `kna00,kna02` |

The donor's ground `ktn/kni/kna/elb/ela` families and aerial orders
therefore differ from native's checked move set. Donor action 0 has no
phase where native has `chb00/chb02`; native additionally owns actions
20/21. Several common UJ chains also have different repetition counts.
The donor's callback-controlled row and response behavior is recorded under
[ANBU callbacks](#callbacks). ANBU's records use the same layout and
input-signature encoding; their `response_selector` and `guard_sfx`
numbers translate to NA2 as described under
[Kakashi moves](kakashi.md#complete-authored-move-correspondence).

### Ordinary jutsu and concrete actors

| Donor action / title | Packed owner / selector | Category / stored cost | Resource / provider |
| --- | --- | --- | --- |
| 1 / Young Lightning | `0x003C001E` | `0x40000 / 3.9` | 53 / `2anbcha0.ccs` |
| 3 / Young Fang | `0x003D001E` | `0x80000 / 3.9` | 54 / `2anbcha1.ccs` |

Actions 0/2 have packed `0x0001001E`, category/cost zero.
Resident provider rows are `0x004764A8/0x004764B4`, stride 12.
At frame 1, CHA0 `ANM_panbcha00` (ID 120) queues target 67,
`0x8003/0x135`; CHA1 `ANM_panbcha10` (ID 57) queues target 2,
`0x8003/0x136`. These encoded resource commands are separate from
configured selectors 60/61. NA2 selectors 60/61 instead select resources
194/195, `2bdycha2/3.ccs`; native Kakashi uses 140/141 → 142/143.

Young Lightning's factory case `0x0086D908` allocates `0x930` and
calls shared `lightning_blade_construct` (`0x008E54F0`). Its common
ownership and methods are documented under
[ordinary Kakashi](kakashi.md#ordinary-jutsu-actors-and-providers).
`lightning_blade_begin` explicitly selects the resource-53
`anbu_young_lightning_name_bank` (`0x00928180`): fourteen animation
slots plus `TEX_panbcha02/01`. Slots 0/3/4/5 are null;
the others include `panbcha01..05`, `eanbcha01a/b/c/02` and
common `e0x_tidori00`. The shared update's actual-ID-8 branch is
not taken by actual ANBU ID 30.

Young Fang's factory case `0x0086D358` allocates `0x9A0`,
initializes the common/compound base, and installs intermediate vtable
`0x0068E360` followed by final `anbu_young_fang_vtable`
(`0x0068D960`) at `+0x28`. It initializes embedded helpers at
`+0x5D0/730/788/7B0/800/870/8E0/930`, stores resource 54 at
`+0x688`, then calls `anbu_young_fang_initialize_state`
(`0x0090C230`) and `anbu_young_fang_bind_players` (`0x0090C340`).
Binding allocates a `0x370` block for three compound players at
`+0x850`, binds `panbcha14a/14b/10d`, and allocates a `0x30`
helper through `jutsu_compound_helper_allocate` (`0x009043A0`).

`anbu_young_fang_update` (`0x0090DD50`) dispatches private states
0/1/2/3/4/5/6/9/C. Participant animation completion starts approach
state 2; accepted contact selects hit 3 or miss 9. Hit progression
binds `panbcha15a/b`, freezes/restores the receiver scale, completes
eight clone-animation cycles, then raises the third player. It submits
up to ten intermediate hits from `0x0094A080/0x00949EE0` and a
final record `0x0094A130`. Receiver action predicate `(5,41)`
selects escape C, whose 30-update path restores the receiver and exits.
Miss uses `0x00949FB0`; contact processing copies current action
damage into the private hit record. This is a participant/contact state
machine, not just a body animation.

`anbu_young_fang_draw` (`0x0090DF50`) draws two players in state 9,
three in 2/3, suppresses state 5, and restores changed shared renderer
fields. `anbu_young_fang_camera_position` (`0x0090C530`) returns
the actor's `+0x360` position lowered by `+0x968 * 100`. `+0x968`
is a 0..1 ramp: `anbu_young_fang_hit_update` (`0x0090D330`) zeroes it
when the eight clone cycles end and raises it by 0.1 per update during
the final rise, so the camera point drops by up to 100 units while the
third player rises.
`anbu_young_fang_destroy` (`0x0090FAA0`) invokes participant/player
release, destroys the embedded helpers, restores the intermediate
vtable for `jutsu_compound_release` (`0x00903380`), and completes
common destruction before optional free. The latter releases the
allocated `+0x5A4` helper. `anbu_young_fang_release` (`0x0090C290`)
restores the receiver's scale `+0x19C` to 1, releases the target
participant and frees the three-player block, so destruction from any
state (hit, miss 9, escape C or an external removal) leaves the
receiver unfrozen. The `+0x990` pointer set by
`anbu_young_fang_prepare` (`0x0090C590`) is the `OBJ_2cmn00t0` entry
of the receiver participant's player, found by `ccs_player_find_entry`
(`0x00148090`): a borrowed pointer that allocates nothing and needs no
release, valid while that participant player exists.
The escape predicate `(5,0x41)` is NA2 substate `0x44` after the
[response translation](kakashi.md#callbacks).

### Checked typed asset bindings

The donor body has 147 animations, CHA0 14, CHA1 10 and eye 2.
Portrait `3ANB3PCT` contains `CLT_sp_anb/TEX_sp_anb`, with no
`TEX_name*` entry. All 26 marked body rows resolve to typed NA2
common-2 definitions; the body itself does not require the missing
common muffler objects found in ordinary Kakashi's body.

Body katana object ID 115 references model 116, part 117/material 118,
texture 110 `TEX_2anbbody` and palette 139. The second katana object
120 references model 123, part 124/material 125, texture 126
`TEX_2anbktn` and palette 142 `CLT_2anbktn`.
CHA0 marked katana row 117 and CHA1 row 54 resolve to body object 115.
CHA0's nested `0x0102` wrappers bind this object in startup and
`panbcha01/02/03`.

CHA0 additionally binds common-2 muffler objects through marked rows
214/216/218/220, with wrappers 213/215/217/219. These four keys
occur in `panbcha03/05` and both offset animations and are absent
from the checked NA2 common-2 provider. CHA1's marked row 257,
`OBJ_2tendos200t0 body` in namespace `c\w\2\ds0\max\2tends2.max`,
resolves to donor CW2 object/model 67/68 and native CW2 74/75.
Its marked kunai row 201 also has an available provider. Name/type
presence does not establish equal geometry.

For each of the eight checked donor files, every marked namespace/name
has a non-carrier typed definition against the matching own files and
UN3 `1CMNBOD1/2CMNBOD1/CW2/STRMCMN/EFFECT0X` providers.
The walker uses the maintained texture/model section-size rules and
consumes every outer block to the exact decompressed end. Namespace
matching removes the leading local-space or marked-`#` character.
Replacing the common providers with NA2 leaves four missing keys in
CHA0 and the film differences recorded under
[Hazy Moon](#cinematics).
The eye's 52 marked keys resolve through `1ANBBOD1`.
NA2 reads all these files as UN3 does, as checked under
[Kakashi body dependencies](kakashi.md#body-eye-and-common-dependencies);
the missing common definitions are the only unresolved bindings.

## Callbacks

Checked donor: UN3 ANBU Kakashi ID 30 (`anb`), resident
`SLUS_217.27`. Its record/working-array ownership belongs to
[Character assets](#records-moves-and-assets).
The same-name NA2 ID-70 callback comparison is recorded
[below](kakashi.md#callbacks).

`anbu_kakashi_callback_table` (`0x004049D0`) contains
`{0,2062C0,206370,206C10,207150,0,0}`:
channels 2/3, source-selected hit response, and channel 5.
`anbu_kakashi_channel2` (`0x002062C0`) uses action predicate
`(0,3)` and the `+0x1A4` timeline: events 5/30 request sound
`0x2C`; event 70 requests position effect `0x1B`.

`anbu_kakashi_channel3` (`0x00206370`) has own action-indexed
voice, sound and effect schedules across ground/air actions and shared
UJ actions 4/5/6. Its voice producers include pseudo -2/-3 and
events `0x13/0x14`. At action `0x1C`, phase 0 versus phase 1,
the working action halfwords `+0x46/48/4A/4C` are respectively
`{0x3B,9,0x5B,3}` and `{0x35,0xFFFF,0x55,0xFFFF}`.
At action `0x20`, it calls shared `kakashi_spawn_action_particles`
with count 8, scale 10, owner position/orientation and masked colour
`& 0xF0F0F0`. Its delayed effect calls use effect `0x1B` and
delay 50. These action numbers differ from ordinary Kakashi's schedules.

`anbu_kakashi_hit_response` (`0x00206C10`) has the following
bounded return sets. Action indices and responses are hexadecimal;
the ordinary default is `-1`.

| Action | Possible nondefault responses | Selection condition |
| --- | --- | --- |
| `17` | `3D,30,2B,32,2C` | phase, repeat and receiver byte `+0x63` bit 5 |
| `19` | `2A,2E` | repeat >1, receiver bit |
| `1A` | `36` | repeat <2 |
| `1B` | `32,2E` | receiver bit |
| `1C` | `31,2E,32` | phase and receiver bit |
| `1E` | `36` | unconditional in this action |
| `1F` | `29,2E` | receiver bit |
| `20` | `2A,2E` | repeat >1, receiver bit |
| `23,24` | `31` | unconditional in these actions |
| `25` | `3D,31` | repeat <2 versus >=2 |
| `27` | `2A,2E` | receiver bit |
| `28` | `2A` | repeat >1 and receiver bit |

Only callback mode 2 writes selected receiver coefficients at
`+0x8F0/8F8/8FC`; sentinel values leave fields unchanged.
For example action `0x1A`, repeat <2 writes `{1,0.35,1.35}`,
and `0x1E` writes `{1,0.25,1.25}`. This response behavior
differs from both ordinary UN3 Kakashi and native Kakashi.
The receiver bit is UN3's grounded bit, and the repeat value comes
from `fighter_action_repeat_for_receiver`; both are described under
[Kakashi callbacks](kakashi.md#callbacks), with the UN3-to-NA2
response table. Through it ANBU's set
`29,2A,2B,2C,2E,30,31,32,36,3D` becomes NA2
`29,2A,2B,2C,30,32,33,34,3A,3F`.

`anbu_kakashi_channel5` (`0x00207150`) returns for actual
fighter ID 30. Other actual fighters using this configured jutsu
callback find `anbu_kakashi_katana_name` (`0x004FC160`),
`OBJ_2anb00t0 katana`, in model collection `+0xD90`,
transform its `+0x40..7C` matrix and mark `+0x8D` dirty.
The configured owner and actual receiver are therefore separate.

## Ultimate Jutsu and effects

Checked donor: ANBU Kakashi ID 30 (`anb`), `SLUS_217.27`.
Character-list entry `0x0047B7D8` selects
`anbu_kakashi_ultimate_jutsu_list` (`0x006A0E30`), count 3,
global records 365/366/367. Both normal and mode-1 defaults
(`0x0047BD8C/0x0047BE0C`) select record 365.
`anbu_kakashi_ultimate_jutsu_records` (`0x004DB734`) has
three `0x24`-byte entries:

| Record / checked English title | Authored skill | Ability prerequisite | Intro | Effect | Damage percent |
| --- | ---: | ---: | ---: | ---: | ---: |
| 365 / Hazy Moon | `0x78` | 90 | 121 | `0x2A` | 30 |
| 366 / Hazy Moon 2 | `0x78` | 90 | 121 | `0x2A` | 30 |
| 367 / Chakra Release | `0xFFFF` | 90 | -1 | `0x3C` | 0 |

Prerequisite count is 1 at `+6`, ability ID `0x5A` at `+8`.
This is not NA2's category byte. Stored bytes `+0xE..0x11`
are `00 01 01 01`, `00 01 02 02`, `00 01 04 00`.
The six stat-adjustment halfwords at `+0x18..0x22` are
`{10,0,0,0,0,0}`, `{20,0,0,10,0,0}`, and all zero.
Thus the first two records share one authored cinematic and differ in
metadata. The stat halfwords are only drawn as digits by
`ultimate_menu_stat_digits` (`0x002C5650`), as for
[Kakashi](kakashi.md#ultimate-jutsu-and-effects), so Hazy Moon and
Hazy Moon 2 behave the same in battle. Admission follows the shared
ability check described there.

`anbu_kakashi_effect_record` (`0x00474F40`), indexed effect
`0x2A`, stores lifetime 600 and flags 2. Effect `0x3C`'s record at
`0x004756D8` also stores lifetime 600 and flags 2. Neither ID occurs in
the terminated `status_effect_factory_bindings` list (`0x00473D00`),
so both use the generic node built by `fighter_status_effect_construct`.
Their nonneutral fields, read by the reducers listed under
[Kakashi UJ/effects](kakashi.md#ultimate-jutsu-and-effects), are:

| Effect | Attack | Defense input | Action rate | Jump | `+0x84` factor |
| --- | ---: | ---: | ---: | ---: | ---: |
| `0x2A` | 1.2 | 1.1 | 1.2 | 1 | 1.1 |
| `0x3C` | 1 | 1 | 1.5 | 1.5 | 1 |

`effect_action_rate_factor` caps the summed rate at 1.25, so
`0x3C`'s 1.5 acts as 1.25. Neither record has an HP or chakra delta.
Effect `0x2A` enters like Kakashi's effect, through
`jutsu_post_cinematic_update` after a surviving defender, and
applies to ANBU only (flags 2).

`ultimate_jutsu_record_form` (`0x0028BFF0`) maps only effects
`0x3D..0x46` to IDs 47..56. Neither ANBU effect `0x2A/0x3C`
returns a replacement identity through that completion route.
The effect-only third record does not establish a separate fighter form.

The native ID-70 record set 154..156, skills `0x7D/7E/7F`,
intro members 133/134/135, damage 40/25/35 and effect
`0x49/FFFF/FFFF` is owned by the
[ordinary Kakashi comparison](kakashi.md#ultimate-jutsu-and-effects).
Native's effect `0x49` changes its in-place action bank;
it is not ANBU's generic effect `0x2A`.
Film resources belong to [Hazy Moon](#cinematics).

## Cinematics

UN3 ANBU Kakashi's two Hazy Moon records share skill `0x78`.
Selection/effects are owned by
[ANBU UJ records](#ultimate-jutsu-and-effects).
Resident `anbu_kakashi_cinematic_request` (`0x00670AA0`)
is a `0x14`-byte UN3 request row: main name
`str/d30_301e.ccs` at `0x0066FEA0`, zero explicit extra
resident bodies, and one stream pair at `0x0066ECB0`, selecting
`str/d30_301.ccs` through `0x0066ECA0`.
It follows the UN3 request/playback contract documented under
[Guy](guy.md#cinematics), not native's relocated SINF layout.

The stream has `CAM_camera01` at directory ID 1062 and 391 outer
`0x0502` authored frame updates. It marks 307 namespace/name keys;
the resident companion marks 6. All resolve to non-carrier typed
definitions against the matching pair, `1ANBBOD1`, donor common
body/effect and stream providers. The authored participant keys use
the ANBU body and common defender body; the request has no extra
SINF-style body list. No `BIN_` directory name or `0x2400`
blob occurs in the checked pair; that census does not exclude
embedded commands or code-selected data.

Against the same own files with NA2 common providers, the resident
companion lacks four marked textures:
`TEX_e0ywhite01,TEX_e0yline06,TEX_e0ycolor01,TEX_e0yline07`.
The stream additionally requires the absent common-1 `joe01/cloth3`
objects, and the line06/color01/line07 textures.
Their exact donor namespace/name/type definitions, rather than a
matching basename alone, are required to close those bindings.
The resident sampling key ID 479 resolves to the typed
`TEX_sampling00` definition in both checked `EFFECT0X` files;
its runtime capture producer is a separate existing dependency.

The selected skill's auxiliary entry at `0x0047C428` points
to `0x006A10E4`, whose two request-ordinal pointers are
`0x005909F0/0x00591B50`. Both have zero counts in all four
timed auxiliary channels. These are scene/renderer entries, not
the cinematic spoken-cue/damage rows.
The defender-position entry at `0x0047CB38` selects
`anbu_hazy_moon_defender_positions` (`0x005E8E30`): count 4, frame
thresholds `{1,103,263,320}` at `0x005E8720`, then a pointer per UN3
defender ID 0..56 to four signed XYZ halfword triples, applied by
`sp_skill_play_update` (`0x00294F10`) as a defender translation
for the current threshold interval. The descriptor format is the one
described under [Kakashi cinematics](kakashi.md#cinematics).

The timed command script at `0x0047C908` is zero and the
palette-record list at `0x0047D0F0` is zero/zero, so Hazy Moon has
no timed screen or appearance commands and no costume palette records.
The camera-reject entry at `0x0047C1F0` is zero, so
`sp_skill_defender_camera_admission` (`0x00294770`) admits the
camera auxiliary for every defender.

Neither film file contains a queued tag-`0x0108` command or an audio
section. Film damage, soundtracks and cue rows follow
[UN3 cinematic damage and audio](itachi.md#un3-cinematic-damage-and-audio).
Skill `0x78`'s `skill_cinematic_cue_descriptors` entry selects cue rows
`0x003879D0` and `STREAM.AFS` soundtrack member 119 (`0x0437D800`),
Japanese 259 (`0x095B6000`), stereo 48,000 Hz, 13.03 s. Its defender
cue rows, all request ordinal 1, are frame/control 109/`0x0C`,
129/`0x0D`, 143/`0x0E`, 173/`0x0F` and 271/`0x11`. Source-file hashes are in
[ANBU inputs](../../../game/files/file_identities.md#anbu-kakashi-comparison-inputs);
startup SOUND intro 121 is independently established in
[ANBU voice](#voice).

## Voice

Checked donor: UN3 ANBU Kakashi ID 30 (`anb`). The same-name
NA2 ID-70 bank is owned by the [Kakashi comparison](kakashi.md#voice).
All offsets in the tables below are source-file offsets, not live SPU/IOP
addresses. Compact voice, streamed PLVOICE and UJ startup SOUND are
independent paths.

`anbu_kakashi_compact_bank_english` (`SLUS_217.27 0x003883F8`)
contains SNDDATA triple `{0xC9C000,0x1BE0,0x7B4F0}`;
the Japanese descriptor at `0x003886A4` contains
`{0x1CDF800,0x1BE0,0x7B4F0}`.
Aligned sample starts are `0xC9E000/0x1CE1800`.
The two complete header ranges are byte-identical, SHA-256
`3A1419209BD81517ACA1C83FF3D34D7E7F367060EBDA3A2568D6A4C92C6144F5`;
the complete sample ranges are also identical, SHA-256
`12CB3E65430A2F5D85D412835F94F04F33DC3FDEBF801E496687FA3D0D19AA92`.
This establishes byte identity, without an audible-content comparison.

`anbu_kakashi_voice_event_list_pair` (`0x00389218`) contains
base/base `0x004E4F30`, the same 33-entry list recorded under
[Green Beast](green_beast.md#voice).
`fighter_voice_event_list` (`0x0019BDA0`) has no ID-30 alternate
branch. ANBU channel 3 emits pseudo -2/-3 and events `0x13/14`;
the latter select controls 22/23. Normal control 27 is disabled;
its sample data below does not prove an admitted producer for program 27.

The established [compact lookup](../../session/battle_audio.md#compact-program-to-vag-lookup),
at key `0x3C`, yields these stored candidates. Each selected Sset
contains one sample, and both velocity ranges are 1..127. Listed sample
rates are 22,050 Hz; program, Sset/Smpl and VAG indices are separate domains.

| Program | Sset / Smpl / VAG | English SNDDATA offset | Japanese SNDDATA offset |
| ---: | --- | ---: | ---: |
| 0 | 4 / 4 / 0 | `0xC9E000` | `0x1CE1800` |
| 5 | 26 / 26 / 4 | `0xCA0DE0` | `0x1CE45E0` |
| 6 | 32 / 32 / 6 | `0xCA3DF0` | `0x1CE75F0` |
| 7 | 36 / 36 / 8 | `0xCAB190` | `0x1CEE990` |
| 8 | 12 / 12 / 8 | `0xCAB190` | `0x1CEE990` |
| 22 | 37 / 37 / 25 | `0xCCF9E0` | `0x1D131E0` |
| 23 | 39 / 39 / 27 | `0xCD1780` | `0x1D14F80` |
| 26 | 43 / 43 / 31 | `0xCD6F00` | `0x1D1A700` |
| 27 | 47 / 47 / 33 | `0xCDD9D0` | `0x1D211D0` |

Native ID-70 program 22/23 instead selects Sset 19/20 and VAG
25/26, at `0x117C7B0/0x117D360`; native program 27 is absent.
Even a common program number does not establish the same sample mapping.

`anbu_kakashi_streamed_descriptor_english/japanese`
(`0x00388B68/0x00388D28`) select PLVOICE outer 29/85,
handles 99/155, type/channel 1 and declared nested count 209.
Both contain 31 populated physical members:
`6,7,23,24,45,47,49,50,68,69,85,92,111,112,118,125,131,132,133,134,135,136,137,138,151,165,166,167,199,202,208`.
The outer ranges begin at `0xC37800/0x1BF8800`, sizes
389120/311296. Member 6's exact payloads are:

| PLVOICE outer / member | Offset | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| 29 / 6 | `0xC38000` | 11719 | `2CBF1E65ED05921737C9B553B4C8CA1767B8465B0F635BCB07E5B244BD5E9915` |
| 85 / 6 | `0x1BF9000` | 10512 | `F14D1D92A478E3F0E78F4E9A36CD78ED97141D7B030B8C94806C64898D3624BE` |

`dialogue_voice_remap_for_fighter` (`BATTLE.BIN 0x0086AF70`)
has no ID-30 exception in the inspected body. The jutsu cues go through
`dialogue_voice_produce` with `dialogue_voice_rows`
(`BATTLE 0x0093D3D0`), where each cue is the physical PLVOICE member
of the performer's bank:

| Jutsu / row | Row cues | Emitted |
| --- | --- | --- |
| Young Lightning / 53 | `138,136,134,137` | State 0: index 1 (136) for actual ID 30, index 2 (134) for any other performer; state 3: index 0 (138) for ID 30 only |
| Young Fang / 54 | `131,132,133,-1` | First update: index 0 (131) when the performer is the resource's configured owner (`0x0087BFC0`); otherwise compact voice index 6 or 7 at random (controls 6/7) |

| PLVOICE member | Outer 29 offset / bytes | Outer 85 offset / bytes |
| ---: | --- | --- |
| 131 | `0x00C67000 / 8726` | `0x01C1C800 / 7469` |
| 134 | `0x00C6C800 / 8596` | `0x01C22000 / 9538` |
| 136 | `0x00C71800 / 9537` | `0x01C26800 / 9765` |
| 138 | `0x00C77800 / 13572` | `0x01C2C000 / 5061` |

The win end demo, `end_demo_update` (`0x002E2120`), plays one random
member of ANBU's `end_demo_quote_lists` (`0x0047F140`) entry, SOUND
members 118..121 from outer 2, or outer 16 for Japanese voices:

| Member | Outer 2 offset / bytes | Outer 16 offset / bytes |
| ---: | --- | --- |
| 118 | `0x120FE000 / 19211` | `0x25348800 / 13571` |
| 119 | `0x12103000 / 9633` | `0x2534C000 / 18531` |
| 120 | `0x12105800 / 16009` | `0x25351000 / 12931` |
| 121 | `0x12109800 / 10937` | `0x25354800 / 11444` |

Both Hazy Moon records use intro 121 through
`audio_request_sound_member_for_voice_set` (`0x0018A1C0`),
SOUND outer 9/23, separately from PLVOICE:

| SOUND outer / member | Offset | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| 9 / 121 | `0x12F6B800` | 18655 | `9223D0ECD564AD9B7B899FBDEBCC623BF88974FF12979B8F6EBAD4386AB0C50A` |
| 23 / 121 | `0x262B6800` | 16254 | `09BD682960B3B8CC56121FDCFA259C2FF2401893780EE94F05EA5CDE18C48D1A` |

Complete archive identities are owned by
[File identities](../../../game/files/file_identities.md).
