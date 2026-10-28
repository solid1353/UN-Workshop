# Doto (UN2)

## Research coverage

Doto Kazahana is fighter ID 26 of the Japanese UN2 (`SLPS_253.98`). Established:
his definition, record, actions, callbacks, files and their CCS references,
jutsu selectors, resources, actor classes and their code closure, the three
Ultimate Jutsu cinematics with their resident per-part data, his voice
archive and compact bank, the Character Select entry, what NA2's files lack
for his keys, and what the US release (`SLUS_215.75`) keeps of him. Open:
where a cinematic applies its damage, the meaning of his stored record
parameters and of each spoken clip.
Names come from `@annotations/UN2_JP`; addresses are live (`BATTLE.BIN` loads
at `0x00713800`).

## Identity and files

| Item | Value |
| --- | --- |
| Definition | `character_definition_table` (`0x004004A0`, 34 pairs, IDs 0..33), row 26 |
| Factory / constructor | `doto_create` (`0x001E3A50`, allocates `0x1AB0`) → `doto_construct` (`0x001E3AA0`, vtable `0x005BBF70`) |
| Record / descriptor | `doto_character_record` (`0x003E04C0`) / `doto_character_descriptor` (`0x003E0590`) |
| Display name | `ドトウ` |
| Code | `dtu` |

His files sit at the `DATA.CVM` root unless noted. Every one is CCS version
`0x111`, like every UN2 CCS
([CCS runtime](../../../game/files/ccs_runtime.md#versions-in-the-retail-files)).

| File | Role |
| --- | --- |
| `2DTUBOD1.CCS` | Battle body (record `body_filename`) |
| `2DTUCHA0.CCS`, `2DTUCHA1.CCS` | Jutsu resources 59/60 |
| `1DTUBOD1.CCS` | Animation-free second model, used by the win and cinematic files |
| `3EYE/3DTU3EYE.CCS` | Win presentation; references `1dtubod1` and effect-0x textures |
| `CSDTU.CCS` | Character Select model (`character_select_model_filenames`, `0x004E2FC0`) |
| `STR/D26_{1,2,3}E.CCS`, `STR/D26_{1,2,3}_{1,2}.CCS` | Ultimate Jutsu cinematics, one set per level |
| `DOLL/IFDTU.CCS` | Figurine, named only by `HOME.BIN` |
| `PLVOICE.AFS` entry 25 | Streamed voice (see [Voice](#voice)) |

## Record

The UN2 record is `0xD0` bytes; `fighter_load_character_record`
(`0x001867B0`) copies it to fighter `+0x70`. It has no `0x4C`-row table:
each action points to its own rows.

| Offset | Doto |
| --- | --- |
| `+0x00` | ID 26 |
| `+0x0C`/`+0x10`/`+0x14`/`+0x18` | `CLT_2dtubody` (+`c1`, `c2`), `TEX_2dtubody`, `MDL_2dtu00t0 body`, `OBJ_eff_dummy_dtuhol0` |
| `+0x1C` | `doto_callbacks` (`0x003DC8D0`) |
| `+0x28`/`+0x2C` | 39 actions, `doto_actions` (`0x003DF750`) |
| `+0x30` | Working actions; `doto_construct` points it at fighter `+0xD44` |
| `+0x38`/`+0x3C` | 149 animation names, `doto_animation_names` (`0x003DC8F0`) |
| `+0x40` | Animation lookup; fighter `+0xAF0` |
| `+0x4C..+0xCC` | Stored parameters |

All 149 animation names use the `dtu` code; none is a shared `pcmn` name.
`fighter_load_character` (`0x00186CD0`) leaves slots `0x48..0x4F` empty for
the configured jutsu; Doto's own names there are slot 75 `ANM_pdtucha00` and
slot 79 `ANM_pdtucha10`. Slots 65..67 all name `ANM_pdturdy1`.

His actions own 105 animation rows in all (`0x4C` bytes, each action's
array ending at slot -1). Jutsu actions use the reserved slots: action 0
slot 72, action 1 slot 75, action 2 slot 76, action 3 slot 79. Slots 70/71
(`ANM_pdtujpz0/1`) are used only by the dash attack, action 26. The
Ultimate Jutsu actions play slot 66 then `ANM_pdtuspl*`.

## Actions

Each action record is `0x58` bytes. Fields Doto's data shows:

| Offset | Meaning in Doto's records |
| --- | --- |
| `+0x00` | Debug name `PL26_ATK_*` |
| `+0x08` | Display name, Japanese with ruby markup |
| `+0x0C` | Category bits: `0x1` attacks, `0x2` dash, `0x4`/`0x8` throws, `0x10`/`0x20`/`0x40` the three throw follow-up groups `FLA0x`/`FLA1x`/`FLA2x`, `0x400`/`0x800` the two jutsu, `0x1000`/`0x2000`/`0x4000` the three Ultimate Jutsu levels |
| `+0x18` | Chakra cost |
| `+0x24` | Damage |
| `+0x28` | Defender response selector, read by `hit_select_response` (`0x001A0FD0`) |
| `+0x38`/`+0x3C` | Distance thresholds; `-17320.508` is the unset value |
| `+0x50` | Pointer to the action's own animation rows |
| `+0x54` | Jutsu selector: 52 on action 1, 53 on action 3, 1 elsewhere |

| Actions | Debug names | Display names |
| --- | --- | --- |
| 0, 2 | `CHB0`, `CHB1` | none (cost 0, category 0) |
| 1 | `CHA0` | `氷遁　黒龍暴風雪` (Ice Release: Black Dragon Blizzard), cost 3 |
| 3 | `CHA1` | `氷遁　双龍暴風雪` (Ice Release: Twin Dragon Blizzard), cost 3 |
| 4..15 | ground strings `PNC0..6`, `KCN0..3`, `RSH0`, `PNC3` | finishers `天仰翔雅`, `花烈蹴覇`, `瓔珞踏覇`, `双蹴覇`, `怒涛雅`, `閃蹴覇`, `永久機関` |
| 16, 17 | `HOL0`, `HOL1` | throw `威風花` |
| 18..25 | air strings `PNA0..3`, `KCA0/1` | finishers `煌典雅`, `華天落`, `雅昇覇` |
| 22, 23 | `HLA0`, `HLA1` | air throw `耀輝飛` |
| 26 | `DAS0` | dash attack |
| 27..35 | `FLA00..22` | throw follow-ups |
| 36..38 | `SPL0..2` | Ultimate Jutsu levels `ミゾレ`, `フブキ`, `ナダレ`, costs 5/10/15 |

The three level names are the names of Doto's three bodyguards (Mizore,
Fubuki, Nadare); each level's cinematic features one of them.

## Callbacks

`character_dispatch_channel` (`0x001887A0`) sends events 1, 2, 3, 5 and 6 to
slots 0, 1, 2, 4 and 5; slot 3 is read directly by `hit_select_response`.
During major state 8, actions 0..3 use the configured jutsu owner's table.

| Slot | Routine | Behavior |
| ---: | --- | --- |
| 0 | none | |
| 1 | `0x001E3D30` | Returns at once |
| 2 | `doto_channel3` (`0x001E3D40`) | Event 3: phase steps and effects for actions 8, 13, 14, 15, 17 and 36..38 (frame-timed phase changes, common sounds `0x28`/`0x2F`, forward motion, and a ground-code footstep sound with dust) |
| 3 | `doto_response_override` (`0x001E43C0`) | Picks the defender response for actions 8, 10, 13 and 14 by hit count and whether the defender is airborne; -1 keeps the default |
| 4 | `doto_capture_pin` (`0x001E4620`) | Event 5: during throw actions 16/17, when both fighters share a stage section, sets the held opponent's position from a node matrix |

## Jutsu resources and actors

| Selector | Resident provider (`jutsu_animation_provider_table`, `0x00400178`) | BATTLE resource (`jutsu_selector_resource_table`, `0x008ABC90`) | Actor (`jutsu_create_for_resource`, `0x007BE5A0`) |
| ---: | --- | --- | --- |
| 52 | `2dtucha0.ccs` | 59 | `0x3C0` bytes, base constructor `0x007C4140`, vtable `0x005C7640`, destructor `doto_jutsu0_destruct` (`0x0086B9A0`) |
| 53 | `2dtucha1.ccs` | 60 | `0x6B0` bytes, `doto_jutsu1_construct` (`0x008657E0`), vtable `0x005C05A0`, three `0x50` entries at `+0x3A0` |

Resource filenames are in `jutsu_resource_filenames` (`0x0088EA90`). Both
vtables share most methods with the other jutsu actors. Methods only the
resource-59 vtable holds: `0x007BCC50`, `0x007BCCC0`, `0x007BCCD0`,
`0x007BCFE0`, `0x007BCC30`, `0x007BACC0`, `0x007BCA30`, `0x007BC430`,
`0x007BC640`, `0x007BC7D0`, `0x007BC420`. Methods only the resource-60
vtable holds: `0x00865C70`, `0x00865D90`, `0x00865DA0`, `0x008661C0`,
`0x008661D0`, `0x00864C20`, `0x00864D00`, `0x008651C0`.

`2DTUCHA0` holds `ANM_pdtucha00`, the dragon's `ANM_pdtucha01` and
`OBJ_krh00t0 bone01..13`, and the `edtuwnd` wind effect; `2DTUCHA1` holds
`ANM_pdtucha10..12`.

Black Dragon Blizzard (resource 59): `doto_jutsu0_process` (`0x007BCCD0`)
waits for frame 15 of the actor's animation, then spawns a dragon actor
(`0xAB0` bytes, vtable `0x005C75E0`, on the common projectile base
`0x007C17A0`), a particle generator aimed by Doto's facing, and common
sounds `0x0E` and `0x27`; the jutsu ends on its animation's last frame.
`doto_jutsu0_dragon_setup` (`0x007BD020`) plays `ANM_pdtucha01` and uses
the 13 dragon bones as hit shapes, allowing at most 3 hits;
`doto_jutsu0_dragon_update` (`0x007BD3E0`) runs its launch, flight, contact
query and end states.

Twin Dragon Blizzard (resource 60): `doto_jutsu1_process` (`0x00865DA0`)
moves three attached effect entries each update, queries contacts at
frames 33 and 43 of the actor's animation, and repeats common sound `0x0E`
every 10 updates.

Code these two actors need beyond the shared jutsu actor:

| Actor | Own routines | Shared BATTLE callees | Resident callees |
| --- | --- | --- | --- |
| Resource 59 with its dragon | 24 routines in `0x007BACC0..0x007BE4C0` | 25, including the jutsu base `0x007C4140`, the projectile base `0x007C17A0` and the contact query `0x007C08D0` | 49 |
| Resource 60 | 31 routines in `0x00864C20..0x00867D80` | 7, including the jutsu base `0x007C4140` | 48 |

## Ultimate Jutsu cinematics

`sp_skill_play_start` (`0x002645A0`) takes the attacker and defender
characters and a level 0..2, reads the row from
`jutsu_cinematic_row_index` (`0x0050A23A`, `character * 3 + level`) in
`jutsu_cinematic_rows` (`0x00596840`), and builds requests through
`sp_skill_build_requests` (`0x00264350`): the row's resident file (flag
`0x1000`), its extra residents, then its parts in order (the first flagged
`0x400`). Doto's rows have no extra residents and two parts each.

| Level | Row | Title | Resident | Part 1 | Part 2 |
| ---: | ---: | --- | --- | --- | --- |
| 0 | 75 | `ミゾレ` | `str/d26_1e.ccs` | `爆走豪力氷打`, `str/d26_1_1.ccs` | `爆裂氷山崩し`, `str/d26_1_2.ccs` |
| 1 | 76 | `フブキ` | `str/d26_2e.ccs` | `ツバメ吹雪`, `str/d26_2_1.ccs` | `氷牢の術`, `str/d26_2_2.ccs` |
| 2 | 77 | `ナダレ` | `str/d26_3e.ccs` | `氷遁　破龍猛虎`, `str/d26_3_1.ccs` | `氷遁　一角白鯨`, `str/d26_3_2.ccs` |

`jutsu_presentation_update` (`0x0031A2C0`) starts the cinematic with level
`selector - 13`, as NA2 does. For each part, `sp_skill_part_begin`
(`0x00263160`) and `sp_skill_part_frame` (`0x00262C50`) use three resident
per-part tables:

| Table | Doto |
| --- | --- |
| `jutsu_cinematic_frame_scripts` (`0x0040A2B4`): per-frame operations 1..3 | none |
| `jutsu_cinematic_offsets` (`0x0040A540`): defender offsets | One block per part except level 2 part 1. A block holds a threshold count, a pointer to halfword frame thresholds and one pointer per defender ID 0..33 to that defender's XYZ halfword triples; each frame the defender takes the triple of the current threshold. Level 0 part 1 (`0x0057F500`) has 3 thresholds, `1, 141, 221`. |
| `jutsu_contest_rows` (`0x00597130`): input contest | Every part: descriptor `0x00597198` for both players and duration 90, shifted by up to 30 by the fighters' HP difference; byte `+10` is 40 on level 2 part 2, 0 elsewhere |

`jutsu_contest_begin` (`0x002F0BC0`) starts the contest. Where the
cinematic's damage is applied was not found in this bounded search.

The films' bodyguard models are `st37` (level 0) and `st38` (level 1), and
level 2 uses `1ndrbod1` objects; each level's resident file provides them.

## CCS references

The body, both jutsu files and `CSDTU` reference 31 marked
`#c\2cmn\max\2cmnbod1.max` bones. Doto's own skeleton in `2DTUBOD1` has
`muffler` and `muffler1` under `spine1`, and every body animation (139 of
them) plus `ANM_pdtucha00` and `ANM_pdtucha10..12` key them through
`0x0A00` wrappers whose targets are the marked `OBJ_2cmn00t0 muffler` and
`muffler1`.

The cinematic files' marked references resolve as follows:

| Provider | Keys |
| --- | --- |
| Each level's resident `D26_kE` | The level's stage, effect and bodyguard objects |
| `1CMNBOD1` | 60 per part |
| `1DTUBOD1` | 61 in `D26_2_1` and `D26_3_1` |
| `CMN/EFFECT0X.CCS` | 41 keys: effect-0x sound-word, wave, hit, line and smoke objects, effect-00 lines, and `TEX_e0xcolor01`, `TEX_e0xline06`, `TEX_e0xwhite01` |
| `STRMCMN.CCS` | `OBJ_e00down01a/b/c` (`D26_1_2`), `TEX_e00line07` (`D26_1E`) |

`3DTU3EYE` takes 63 keys from `1DTUBOD1` and `TEX_tiritiri`,
`OBJ_tiritiri` and `OBJ_e0xback03` from `EFF3EYE.CCS`.

These are NA2's files' gaps for the same keys: NA2's `CMN/2CMNBOD1.CCS`
lacks `OBJ_2cmn00t0 muffler` and `muffler1`; its `CMN/EFFECT0X.CCS` and
`STRMCMN.CCS` lack all 45 effect keys above (NA2's effect-0x objects with the
same names, `OBJ_e0xwave01/02`, sit under another namespace); NA2 has no
`EFF3EYE.CCS`, and its `3EYE/ENDDEMO.CCS` lacks the three win keys. NA2's
`PL/1CMNBOD1.CCS` holds every `1cmnbod1` key the films use.

## Voice

`audio_write_pending_stream` (`0x0025F8D0`) stores bank `character - 1`;
`audio_consume_pending_streams` (`0x002E08F0`) requests it from family 3,
`audio_plvoice_descriptors` (`0x00409E10`: 33 descriptors, handle
`0x32 + index`, member count at `+6`). There is one bank per character and
no language choice. Doto's is `PLVOICE.AFS` entry 25: 133 members, all
populated, Japanese, numbered by the sparse cue index. Every one of the JP
release's 4,528 nonempty clips starts `80 00 00 20 10 00 00 01 00 00 5D C0`
(encoding byte `0x10`); NA2's 2,232 clips use `0x11`.

His compact bank is row 25 of `audio_character_banks` (`0x00409B60`,
indexed by `character - 1` through `audio_setup_battle_banks`,
`0x002E0090`, and `audio_load_character_bank`, `0x0025E180`):
`SNDDATA.BIN` offset `0xB2E000`, header `0x1240` bytes, samples `0x6A9C0`
bytes.

## NA2

NA2 has no Doto and no `DTU` file. Its ID 26 is
`auxiliary_1a_character_record`, the owner of selectors 52/53, which NA2
maps to resources 154/115 for Ninja Hound Summoning and Demon Wind Bomb
([Content availability](../../../game/content_availability.md#auxiliary-jutsu-selectors-0x34-and-0x35)).
Its resources 59/60 still name `2dtucha0/1.ccs`, but no selector of
`skill_selector_resource_table` maps to them and `skill_actor_factory`'s
arms for them only fault.

## JP and US differences

The US release keeps Doto's definition (`SLUS_215.75` table `0x0040FBC0`,
row 26: factory `0x001E5280`, record `0x003EFBE0`), his actions, callbacks,
jutsu actors and cinematic rows, and all his `DATA.CVM` files (the
compressed files differ only in the gzip header time). What it removes:

- Character Select: `character_select_order` (`0x00586B00`, read by
  `character_select_build_choices`, BATTLE `0x0071AA20`) lists 33 IDs with 26
  as entry 28; the US list (`0x004F1D10`) has 32, without 26.
- Text: every Doto action display name and the three cinematic titles are
  empty strings in the US program. No English text for Doto exists.
- Voice: US `PLVOICE.AFS` entry 25 has 133 members of 347 bytes each. The
  US compact bank row 25 (`SNDDATA.BIN` at `0xBFA800`) has the same sizes as
  the JP row but different bytes.
- `HOME.BIN` names `ifdtu.ccs` and its animations only in the JP release.
