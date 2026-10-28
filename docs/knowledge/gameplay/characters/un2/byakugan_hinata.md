# Byakugan Hinata (UN2)

## Research coverage

Established: identity, record, constructor and files of UN2 (`SLUS-21575`)
Byakugan Hinata; the UN2 record, action, row, category, flag, signature,
response-selector, animation-slot and effect formats against retail NA2
(`SLPS-25837`); her callbacks, Meridian specials and effects; her two jutsu
classes; her files' CCS versions and missing common objects; the action
sound-selector map, voice cues and banks; and NA2's state for ID 33.
Open: which samples the translated sound selectors and voice cues play,
the 64 Palms and Rotation classes' behavior beyond their timed script and
override lists, and any UN2 consumer of action `+0x54`.
Names come from `@annotations/UN2` and `@annotations/NA2`; addresses are
live US addresses.

## Identity and files

Byakugan Hinata is character ID 33 (code `hnx`). Row 33 of
`character_definition_table` (`0x0040FBC0`, rows 0..33) holds
`byakugan_hinata_create` and `byakugan_hinata_character_record`
(`0x0040DDB0`). `byakugan_hinata_create` allocates `0x1AF0` bytes: the
base fighter (`0xAF0`), 144 working animation-name words and 40 working
actions. `byakugan_hinata_construct` installs `0x00550E80`, copies
`byakugan_hinata_character_descriptor` and calls
`fighter_load_character_record`. The fighter has no private state.

Her vtable differs from the base vtable `0x00550D00` only in its destructor
and slot `+0x1C`, `byakugan_hinata_com_update`, which runs
`ai_fighter_update` while the COM level is set, exactly as Hinata's
(ID 12) slot does.

| File (`DATA.CVM` root) | Bytes | CCS version |
| --- | ---: | --- |
| `2HNXBOD1.CCS` | 655,266 | `0x111` |
| `2HNXCHA0.CCS` | 114,824 | `0x111` |
| `2HNXCHA1.CCS` | 98,038 | `0x111` |
| `1HNXBOD1.CCS` | 114,410 | `0x111` |
| `3EYE/3HNX3EYE.CCS` | 36,981 | `0x111` |
| `CSHNX.CCS` | 117,204 | `0x111` |

Every UN2 CCS is version `0x111`, inside NA2's accepted interval
([version census](../../../game/files/ccs_runtime.md#versions-in-the-retail-files)).
UN2 has no `3???3PCT` family and no `D33_*` film.

Checked against NA2's providers, `2HNXBOD1`, `2HNXCHA1` and `CSHNX` name
`OBJ_2cmn00t0 muffler` and `muffler1`, which NA2's `CMN/2CMNBOD1.CCS`
lacks; every other `2cmnbod1` reference resolves by name. `2HNXCHA0`
resolves completely, `1HNXBOD1` has no external reference, and the
`3HNX3EYE` references into `EFFECT0X` resolve in NA2's file. UN2's
`2cmnbod1` also holds `ANM_pcmnbom0`, `pcmnhtn2`, `pcmnwal1`, `pcmnwal2`
and `dummy23`, which NA2's lacks.

## Record

The UN2 record layout against NA2's is in
[Nine-Tailed Naruto: UN2](nine_tailed_naruto.md#character-record). ID 33's
named-handle words `+0x44/+0x48` are zero.

The display name is `ヒナタＸ`. The appearance arrays use NA2's 30-byte
name records: palettes `CLT_2hnxbody`, `bodyc1`, `bodyc2` (nine empty),
texture `TEX_2hnxbody`, model `MDL_2hnx00t0 body`, effect anchor
`OBJ_eff_dummy_hnxhol0`.

UN2 has no separate row table (below). Against UN2 Hinata (ID 12), only
these parameters differ: jump preparation (NA2 `+0x80`) 3 against 4,
NA2 `+0xAC/+0xB0` 300/200 against 250/150, and offense (NA2 `+0xBC`) 1.1
against 0.9.

## Actions and rows

The UN2 action-record and phase-row layouts against NA2's are in
[Nine-Tailed Naruto: UN2](nine_tailed_naruto.md#action-records). Pairing
every UN2 action with the UN3 action of the same debug name over IDs 1..26
(UN3 uses NA2's layout) confirms that translation and gives it for every
bit, not only the bits one character uses: category bits 0..1 kept, 2..3
`<<6`, 4..6 and 8..14 `<<8`; flag bits 0..3 kept, 4..8 `>>2`, 12..16
`<<9`, 17 → `0x10000`, 18 → `0x4000000`, 20..22 `>>13`, 24..26 `>>14`,
28..30 `>>15`. UN3 retuned many substitution timings and sets the capture
factor to 1.5 throughout.

Action `+0x54` holds the jutsu selector number (ID 33: 66/67 on actions
0..3, 1 elsewhere; ID 12: 24/25; ID 1: 2/3); no UN2 consumer was checked.

All 1,685 UN2 -1 rows and 419 -2 rows paired with UN3 -0x10/-0x11
equivalents, and UN2 code tests -2/-4/-5 as grounded conditions, which
confirms the [phase-row conditions](nine_tailed_naruto.md#phase-rows).

### Animation slots

`fighter_load_character` leaves UN2 slots `0x48..0x4F` for jutsu; NA2
reserves `0x46..0x4D`. Matching ID 33's names to NA2's slot meanings:

| UN2 slots | NA2 slots |
| --- | --- |
| 0..3 | 0..3 |
| 5..8 | 4..7 |
| 9..18 | 9..18 |
| 19, 20 | 20, 21 |
| 21, 22 | 23, 24 |
| 23 | 25 |
| 26..28 | 26..28 |
| 30..35 | 29..34 |
| 36..63 | 35..62 |
| 65..67 | 63..65 |
| 68..71 | 66..69 |
| 72..79 (jutsu) | 70..77 |
| 80..143 | 78.. |

UN2 slots 4 (`ANM_pcmnhtn2`), 24/25 (`phnxwal1/2`), 29 (`phnxbom0`) and 64
(`phnxkxn0`) have no NA2 slot; NA2 slots 8, 19 and 22 (`pcmnyft0`,
`pcmnbnd0`, `pcmnhth2`) have no UN2 name. Her body holds `phnx` versions
of NA2's common slots 25..34.

### Moves

| Actions | Debug names | Display |
| --- | --- | --- |
| 0, 1 | CHB0, CHA0 | 8 Trigrams 64 Palms (selector 66) |
| 2, 3 | CHB1, CHA1 | Rotation (selector 67) |
| 4..36 | PNC/KCN/KCS/CRS/HOL/PNA/KCA/HLA/DAS/FLA | Ordinary attacks and exchanges |
| 37..39 | SPL0..2 | Meridian: First/Second/Third State, cost 5/10/15 |

## Response selection

UN2 `response_select_substate` (`0x001A27F0`) reads the selector at action
`+0x28`; a guard bypass returns `0x47`. UN2's state-name table
(`0x00410CB0`, one 8-byte row per state, first word an `ACT_DMG_*` name)
and NA2's [native identifiers](../../combat/hit_response.md#native-identifiers)
give these substates, and UN2 `response_motion_table` rows match NA2's for
each pair. UN2 `0x43` is `HOLD` (NA2 `0x4A`); `0x44` `HOL2` and `0x45`
`HOLA` have motion rows equal to NA2's `0x4B`/`0x4C`/`0x4E`, and `0x46`
`HOLB` to NA2 `0x4D` alone:

| UN2 substates | NA2 substates |
| --- | --- |
| `0x27..0x2C` | same |
| `0x2D..0x3B` | `+2` (`0x32` → `0x34`, whose NA2 row changes gravity and pause) |
| `0x3C, 0x3D` | `0x3F, 0x40` |
| `0x3E..0x42` | `+4` |
| `0x43..0x46` | `0x4A..0x4D` |
| `0x47, 0x48` | `0x4F, 0x50` |
| `0x49..0x54` | `+8` |

The selector-to-selector mapping is in
[Nine-Tailed Naruto: UN2](nine_tailed_naruto.md#response-and-guard-selectors).
ID 33 uses selectors 0, 2, 3, 4, 9, `0xC`, `0xE`, `0xF`, `0x10`, `0x11`, `0x12`,
`0x15`, `0x16`.

## Callbacks

`byakugan_hinata_callbacks` populates slot 1 (an empty return),
`byakugan_hinata_channel2` and `byakugan_hinata_hit_response`.

- `byakugan_hinata_channel2`: actions 37..39 call
  `fighter_self_buff_special` with level 0..2 and effect `0x38 + level`;
  action 14 at primary event 7 and action 10 at events `0x12`/`0x16`
  change the phase.
- `byakugan_hinata_hit_response` (called by `response_select_substate`
  with source and receiver): action 12 returns `0x30`; actions 7 and 10
  return `0x3C`/`0x30` by `receiver_retained_hit_count` (below 2 or not)
  and always set receiver `+0x75C` (action 10: 1.0 or 0.25; action 7: 1.0
  or 0.5); others return -1. Receiver `+0x75C` scales the next response's
  planar and vertical speeds and resets to 1.0. NA2's same-lineage
  callbacks (for example `neji_classic_hit_response`) take a third mode
  argument and write `receiver->attack_scale` only in mode 2; their
  returned substates use NA2 numbers (UN2 `0x30` = NA2 `0x32`, `0x3C` =
  `0x3F`).

## Meridian specials and effects

`fighter_self_buff_special` (shared by six UN2 fighters) runs in major 8:
phase 0 requests voice cue `0x22` of `fighter_voice_event_list` through
`audio_request_fighter_voice`, phase 1 emits particles up to
frame 8, phase 2 entry spends the action cost and calls
`fighter_status_effect_add(fighter, effect, -1, 1)`, then emits particles
every update. The three SPL actions hit nothing (response `0xFFFF`).

UN2 `status_effect_records` are `0x58` bytes by ID. The getters read:

| Record | Getter | NA2 field |
| --- | --- | --- |
| `+0x14` | `effect_attack_factor`, cap 2 | `attack_factor` |
| `+0x18` | `effect_defense_factor`, floor 0.25 | `defense_factor` |
| `+0x1C` | `effect_action_rate_factor`, cap 1.25 | `action_rate` |
| `+0x20` | `effect_jump_height_factor` | `payload_80` |
| `+0x2C` | `effect_hit_chakra_debit_maximum` | `payload_98` |
| `+0x30` | `effect_knockback_factor` | `payload_84` |
| `+0x34` | Scale at construction | — |

`hit_effect_chakra_debit` debits (guard selector % 5 + 1) × maximum ×
base, capped by the receiver's chakra, on non-jutsu hits; NA2's
`hit_effect_chakra_debit` uses the same formula on record byte `+0x2D`.

| Effect | Name | Lifetime, flags | Nonneutral values |
| --- | --- | --- | --- |
| `0x38` | ヒナタＸＡ | 600, 2 | attack 1.1, rate 1.25, debit 0.125, knockback 1.1 |
| `0x39` | ヒナタＸＢ | 600, 2 | attack 1.25, jump 1.75, debit 0.15, knockback 1.2 |
| `0x3A` | ヒナタＸＣ | 600, 2 | attack 1.5, debit 0.175, knockback 1.5 |

No NA2 effect record has these values; NA2's debit values are only 0.05,
0.1 and 0.15.

## Ultimate Jutsu

UN2's film Ultimate Jutsu are `sp_skill_level_rows` selected by
`sp_skill_level_index`; IDs 27..30, 32 and 33 have no row. Byakugan
Hinata's three chakra-level specials are the Meridian states above, with
no film, so the film damage and contest route
([Nine-Tailed Naruto: Ultimate Jutsu](nine_tailed_naruto.md#ultimate-jutsu))
has no Byakugan Hinata values.

## Jutsu

UN2 `jutsu_selector_resource_table` maps selector 66 to resource 31
(`2tyocha0.ccs`) and 67 to resource 70 (`2hnxcha1.ccs`). The jutsu files'
animations create their actors by command `0x8003`: `2HNXCHA0` creates
resource 69 (`0x145`), `2HNXCHA1` resource 70 (`0x146`). NA2 maps
selectors 66/67 to resources 69/70 with the same filenames, and its
`skill_factory_table` arms for 69 and 70 construct nothing.

- Resource 69, 8 Trigrams 64 Palms: `byakugan_hinata_jutsu0_construct`
  (`0x760` bytes) derives from `jutsu_sequence_base_construct`, the base
  of Nine-Tailed Naruto's resource-66 class, with data table
  `byakugan_hinata_jutsu0_table` at `+0x34C`. Against the base vtable
  `0x00558930` it overrides slot `+0x18`
  (`byakugan_hinata_jutsu0_anchor_position`) and slots `+0xBC`, `+0xC0`,
  `+0xC4`, `+0xE8`, `+0xEC`, `+0x104`. The base itself overrides the
  common jutsu vtable `0x0055C3A0` at `+0x4C`, `+0xA8`, `+0xBC..+0xC8`,
  `+0xD4..+0xDC`, `+0xE8`, `+0xEC`, `+0x100`, `+0x104` and `+0x15C`
  (actor vtable at `+0x30`). `2HNXCHA0` holds
  `ANM_phnxcha00/02`, `chb00/02` and the field model `st2100t0 hkj1`.
- Resource 70, Rotation: `rotation_jutsu_construct`, the class UN2 Neji's
  resource 15 also builds (`0x4C0` bytes, vtable `0x0055AF80`, overriding
  the common vtable at `+0x60`, `+0x64`, `+0x7C`, `+0xA0`, `+0xA8`,
  `+0xBC..+0xC4`, `+0xE8`, `+0xEC`, `+0x104`). `2HNXCHA1` matches UN2 `2NEJCHA1` object for
  object apart from the `hnx`/`nej` names; the class binds the shared
  `e0xchak`/`e06shk02` names. NA2's resource-15 class (`0x007A5CB0`) uses
  NA2's remade `2NEJCHA1`, whose effect objects differ.

`byakugan_hinata_jutsu0_construct`'s overrides run a timed script on the
actor frame: at frames `0x19`, `0x34`, `0x52` and `0x7A` they request the
owner's voice cues 2..5 (common sounds when the owner is not a fighter);
at frame `0x75` they start a screen effect and fade the owner's `+0x250`
from 1 to 0 over 25 frames, restoring it at frame `0xA7`.

The jutsu files' other `0x8003` commands use values 1, 2 and 10, which NA2's
`2NEJCHA0` also uses (1 and 10); the bodies have none. NA2 keeps one
interaction definition each for resources 69 and 70 at `0x008AD8E0`;
resource 70's equals resource 15's apart from its last word. UN2's jutsu
actors read no such table.

## Audio

Action audio follows the same scheduler shape in both games: at primary
event `+0x44`, unless category bit 2 is set, `audio_sfx` indexes
`action_sfx_map` and `audio_voice` names a voice cue, with -2/-3/-4
drawing cues 6..8/3..5/0..2 (a fourth draw plays nothing). UN2's map
(`0x00381B60`) has 93 entries, NA2's (`0x00406FD0`) 102. Aligned by their
runs of equal events and by both games' extra Shino sound (UN2 selector
`0xB`, NA2 `0xC`): 0..7 same, `0xB` → `0xC`, `0xC..0x42` `+2`,
`0x48..0x5C` `+9`; UN2 `0x08..0x0A` and `0x43..0x47` have no clear
counterpart. UN2 → UN3 pairs agree (attack `0x1C` → `0x1E`, response
`0x2E` → `0x30`, guard `0x48` → UN3 `0x50`, which is NA2 `0x51`). ID 33
uses attack selectors `0x1C..0x1F`, `0x21`, response `0x2E..0x31`, `0x33`
and guard `0x48..0x4B`, `0x4D`. The two banks' events are numbered
separately; which samples they play was not compared.

Voice cues index `fighter_voice_event_lists`; IDs 12 and 33 both use
`default_voice_event_list` (cues are mostly event = program).
`audio_request_fighter_voice` plays `battle_voice_controls[event]` from
the compact bank loaded for that character. ID 33's bank row in
`audio_character_banks` is SNDDATA offset `0xE4F800`, header `0x1240`,
samples `0x51C00` bytes (Hinata's: `0x6BD800`, `0x1280`, `0x4B2D0`).
Streamed voices use `PLVOICE.AFS` member character − 1
(`audio_write_pending_stream`): ID 33 is `032.afs`, 133 members; the US
disc has 33 subarchives, with no second language bank.

## NA2 counterparts

NA2 has no Byakugan Hinata. Its Hinata entries are Classic Hinata (12,
`hnt`, UJ records 27..29: Byakugan class 3 with effect `0x18`, Hundred
Palms, a third) and Hinata (80, `hnw`), with different movesets. NA2 ID 33
is a filler copy of ID 1: no filename-table entries, no
`character_jutsu_lists` entry, trigger -1/0, no awakening association,
`ai_character_descriptors` row `FFFF 00 00`, and excluded by
`roster_character_valid`. NA2 keeps selector 66/67 → resource 69/70
(`2hnxcha0/1.ccs`), interaction definitions for both, and
`MAT_hnxeye1/2`, `MAT_hnxmou1` in its resident material names; its
factory arms for 69/70 construct nothing.

NA2 fixes action slots that UN2 does not: 4..9 are Ultimate Jutsu slots
(categories `0x100000/0x200000/0x400000`, signature `0x00100112`),
10..18 the three exchange groups, 19 the dash (category 2, signature
`0x02000011`, which is ID 33's DAS0 after translation), 20 a category
`0x04000000` record, and ordinary attacks from 21.

NA2's class-7 Ultimate Jutsu (`awakening_enter_class_seven`) applies a
record's effect at lifetime -1 in phase 2 of a major-8 action with
category `0x00F00000` and flag `0x00010000`, with no film — the same
shape as `fighter_self_buff_special`. UN2's Meridian actions carry flag
`0x00020001`. In UN2 code, a special (category `0xF000`) with flag
`0x20000` skips the special-start gates of `action_dispatch_index`
(effect flag `0x10`, fighter `+0x68`, the following checks), and
`0x00197520` counts such specials separately: bit `0x20000` plays the role
of NA2's class-7 flag `0x00010000`.
