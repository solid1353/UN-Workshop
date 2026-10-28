# Nine-Tailed Naruto: UN2

## Research coverage

Established for UN2 (`SLUS-21575`) Nine-Tailed Naruto, ID 31, against NA2
(`SLPS-25837`) Nine-Tailed Naruto, ID 47: identity, record, constructor and
files; the action-record, phase-row, category, flag, response-selector and
guard-selector layouts and their NA2 counterparts; callbacks; jutsu resources
and command encoding; the action sound-selector domain; the Ultimate Jutsu
table, multi-part films, contest, damage, post-film effect, scripts,
positions, soundtracks and cue rows (common to UN2); voice banks and event
lists; animation slots; shared-provider closure; jutsu classes and their
event commands.
Open: the jutsu classes' per-state behavior is inventoried by method, not
described state by state; their hit route was traced to the fighter attack
banks they enable. The second pointer of each cue descriptor has no
traced consumer. UN2's AI was not compared.

Names come from `@annotations/UN2` and `@annotations/NA2`; addresses are live.

## Identity and files

UN2 ID 31 has code `nrx` and record name `ナルトＸ`. Character Select lists it
as "Nine-Tailed Naruto" with `ifnrx.ccs` (`nine_tailed_naruto_select_name`).
UN2's Japanese release (`SLPS-25398`) has the same 43 action records apart
from row pointers and names.

| Item | UN2 | NA2 ID 47 |
| --- | --- | --- |
| Definition table | `character_definition_table`, 34 `{factory, record}` rows | 94 rows |
| Factory / constructor | `fighter_id_031_create` (allocation `0x1C30`), `nine_tailed_naruto_construct` (vtable `0x00550EE0`) | `fighter_id_047_create` (allocation `0x5840`), `fighter_id_047_construct` |
| Record | `nine_tailed_naruto_character_record` | `naruto_nine_tails_character_record` |
| Actions / rows / animation names | 43 / rows per action / 157 | 47 / 187 / 149 |
| Effect anchor | `OBJ_eff_dummy_nrxhol0` | `OBJ_eff_dummy_nrvhol0` |
| Body files | `2NRXBOD1`, `1NRXBOD1` | `2NRVBOD1`, `1NRVBOD1` |
| Jutsu files | `2NRXCHA0/1` (resources 65/66) | `2NRVCHA0/1` (resources 112/113) |
| Other files | `3EYE/3NRX3EYE`, `CSNRX`, `DOLL/IFNRX`, `STR/D31_*` | |

Every UN2 CCS file is version `0x111`, inside the range NA2's reader accepts
([CCS runtime](../../../game/files/ccs_runtime.md#versions-in-the-retail-files)).

The two characters share no moveset. NA2 47 is the `紅蓮` moveset with
`九尾の力` and `朱い螺旋丸`. UN2 31 keeps Naruto-style moves; its actions
with names are:

| Action | English | Japanese |
| ---: | --- | --- |
| 1 | Super Pressure | 超重圧 |
| 3 | Instinct of the Beast | 野獣の本能 |
| 7 | Arcadius Kick | 無心蹴り |
| 8 | Naruto Spin | うずまき独楽 |
| 9 | Nosedive Bomb | 急降下爆撃 |
| 10 | Super Crushing Hit | 超激打 |
| 12 | Naruto Rising Dragon | うずまき昇竜 |
| 14 | Crown of the Head Cut | 脳天割り |
| 16 | Exploding Shot | 爆裂弾 |
| 18 | Giant Iron Fist | 大鉄拳 |
| 21 | Giant Swing | 大車輪 |
| 24 | Giant Windmill | 大風車 |
| 26 | Giant Ferocious Kick | 大剛脚 |
| 29 | Bamboo Helicopter | 竹蜻蛉 |
| 40 / 41 / 42 | Clone Jutsu / Summoning / The Nine-Tail | 分身 / 口寄せ / 九尾 |

## Character record

UN2's record is `0xD0` bytes; `fighter_load_character_record` copies 52
words of it. It lacks NA2's row count and row-table words (NA2 `+0x38..+0x40`),
because UN2 rows hang off each action:

| UN2 offset | Field | NA2 offset |
| --- | --- | --- |
| `+0x00..+0x1C` | ID, names, palette/texture/model names, effect anchor, callbacks | same |
| `+0x28` / `+0x2C` / `+0x30` | action count, actions, alternate actions | same |
| `+0x38` / `+0x3C` / `+0x40` | animation count, names, working array | `+0x44` / `+0x48` / `+0x4C` |
| `+0x44` / `+0x48` | named-handle count and descriptors | `+0x50` / `+0x54` |
| `+0x4C..+0xCC` | stored parameters | `+0x58..+0xD8`, same 33-word layout |

Stored parameters that differ from NA2 47 (UN2 / NA2): contact width 110 /
130, ground target 20 / 25, `+0xAC/+0xB0` 250/150 / 400/300, `+0xB4/+0xB8`
1.222/0.873 / 1.396/1.047, offense 1.1 / 1.25, durability 0.9 / 1.2,
`+0xC8` 1.0 / 1.25, `+0xCC` 1.0 / 1.1, HP recovery 1.0 / 1.1. The rest agree.

## Action records

UN2 action records are `0x58` bytes, NA2's `0x54`. UN2 has no owner/selector
word; the jutsu resource is reached by animation command (below).

| UN2 | Field | NA2 |
| --- | --- | --- |
| `+0x00` | debug name (`PL31_ATK_*`) | `+0x00` |
| `+0x08` | display name | `+0x08` |
| — | owner / selector | `+0x0C` |
| `+0x0C` | category | `+0x10` |
| `+0x10` | flags | `+0x14` |
| `+0x14` word | substitution timing | `+0x1A` byte |
| `+0x18` | cost | `+0x20` |
| `+0x1C` short | continuation | `+0x18` byte |
| `+0x1E` short | streak exemption | `+0x19` byte |
| `+0x20` | signature: NA2 encoding except `0x01000000` (dash) and `0x04000000` (outcome continuation), which are NA2 `0x02000000` and `0x08000000` | `+0x1C` |
| `+0x24` | damage | `+0x24` |
| `+0x28` short | response selector | `+0x2C` byte |
| `+0x2A` short | guard selector | `+0x2D` byte |
| `+0x2C` | knockback scale | `+0x28` |
| `+0x30` short | expected hit count | `+0x2E` |
| `+0x32` short | update pause | `+0x30` |
| `+0x34` short | rejection count | `+0x32` |
| `+0x38` / `+0x3C` | thresholds | `+0x34` / `+0x38` |
| — | capture facing-distance factor | `+0x3C` |
| `+0x40..+0x4E` | sound, voice, time, response, guard and response-voice selectors | same offsets |
| `+0x50` | phase-row pointer | `+0x50` row index |
| `+0x54` | not read by the checked consumers | — |

Evidence: `action_select_record` (`0x001AA7A0`) reads category, signature
and continuation; `action_dispatch_index` (`0x001ABE70`) debits the cost at
`+0x18`; `capture_update_sender_grounding` (`0x001B0410`) reads `+0x1E`
where NA2 reads `streak_exempt`; `substitution_attack_admits` (`0x0019AA10`)
reads `+0x14`; `response_select_substate` (`0x001A27F0`) reads the short at
`+0x28`; `guard_enter_response` (`0x00199EB0`) reads `+0x2A`, `+0x32` and
`+0x34`; the repeat countdown copies `+0x30`. `response_choose_facing`
(`0x0018D720`) uses a fixed 0.75, which is NA2's factor 1.5 halved.

### Categories

| UN2 | Meaning | NA2 |
| --- | --- | --- |
| `0x1` | ordinary | `0x1` |
| `0x2` | dash slot | `0x2` |
| `0x4` / `0x8` | capture / release | `0x100` / `0x200` |
| `0x10` / `0x20` / `0x40` | chain throws | `0x1000` / `0x2000` / `0x4000` |
| `0x100..0x800` | jutsu pair and companion | `0x10000..0x80000` |
| `0x1000` / `0x2000` / `0x4000` | Ultimate Jutsu levels | `0x100000` / `0x200000` / `0x400000` |

`action_update_jutsu_record` (`0x001ACC20`) routes UN2 `0xC00`, `0xC` and
`0x2` exactly as NA2 routes `0xC0000`, `0xF00` and `0x2`;
`action_build_chain_masks` (`0x001B1D40`) uses `0x10/0x20/0x40`.

### Flags

The bits the character uses map as follows; each NA2 counterpart is the bit
NA2's matching routine tests in the same place.

| UN2 | Meaning (checked UN2 routine) | NA2 |
| --- | --- | --- |
| `0x1` / `0x2` | ground / air | `0x1` / `0x2` |
| `0x10..0x100` | behavior group; `0x40` in `hit_rehit_allowed` (`0x001A66E0`), `0x100` capture facing, whole group `0xFF0` in `capture_compute_approach` | `0x4..0x40` (shift right 2; `0x10` and `0x40` checked individually, NA2 group `0x7C`) |
| `0x1000` | rehit bypass | `0x200000` |
| `0x4000` | guard bypass (`hit_classify_pair`, `0x001915D0`) | `0x800000` |
| `0x10000` | not substitutable, no trade | `0x2000000` |
| `0x20000` | chakra/statistics exemption | `0x10000` |
| `0x40000` | release grounding | `0x4000000` |
| `0x100000..0x400000` | mode-1 chain group | `0x80..0x200` |
| `0x1000000..0x4000000` | exchange group | `0x400..0x1000` |
| `0x20000000` | capture guard bypass (`capture_bypasses_guard`, `0x001AFA20`), no trade | `0x4000` |
| `0x40000000` | not substitutable | `0x8000` |

### Response and guard selectors

`response_select_substate` maps the selector to a UN2 response state.
UN2's response states are numbered differently; their names
(`ACT_DMG_*`, table `0x00410CB0`) match NA2's:

| UN2 selector | UN2 states (ground/air) | NA2 selector with the same states |
| ---: | --- | ---: |
| 0..5 | `NSH/NAS` .. `NLL/NAL` | 0..5 |
| 6 / 7 / 8 | `NAS` / `NAM` / `NAL` | 8 / 9 / 10 |
| 9..12 | `NB12..NB15` | 11..14 |
| 13 | `ND/NDA` | 15 |
| 14 / 15 | `NDH` / `NDL` | 16 / 17 |
| 16 | `BSF/BSB` by facing | 18 |
| 17 / 18 | `BR` / `BD` | 20 / 21 |
| 19 | `NLH/NAS` | none |
| 20..23 | `HOLD`, `HOL2`, `HOLA`, `HOLB` (states `0x43..0x46`) | 23..26 (`HOLD`, `HOLD_A`, `HOLD_L`, `HOLD_D`; the last three correspond by order, their names differ) |
| 24 | `CNT` (state `0x48`) | 28 |
| 25..28 | `AND/ANDA` .. `AWD/AWDA` | 29..32 |
| 29 | `XF` | 33 |

The guard bypass gives `GBR` in both games. UN2's guard selector is a row
0..9 like NA2's; airborne adds 5.

## Animation slots

`fighter_load_assets` (`0x001884E0`) leaves empty names and slots
`0x48..0x4F` unresolved; they are the jutsu block, two slots later than
NA2's `0x46..0x4D`. The character's block has the same grouping as NA2's:
action 0 uses `0x48..0x4A` (empty names; its row uses `0x48`), action 1
`0x4B` (`ANM_pnrxcha00`), action 2 `0x4C..0x4E` (`ANM_pnrxchb10`, empty,
`ANM_pnrxchb12`), action 3 `0x4F` (`ANM_pnrxcha10`). Each jutsu action's
rows fit NA2's six-row groups (rows 0..5 for actions 0/1, 6..11 for 2/3):
one, one, two and one rows plus terminators. Of the 157 names, 117 are
`nrx` animations and 36 shared `cmn` ones.

## Phase rows

Rows are `0x4C` bytes with NA2's field layout. Each action's rows are a
16-byte-aligned array ending in an animation-slot `-1` row.
`phase_event_completion` (`0x001F0500`) uses different condition numbers:

| UN2 condition | NA2 |
| ---: | ---: |
| -1 animation end | -16 |
| -2 grounded | -17 |
| -3 descending or grounded | -18 |
| -4 end or grounded | -19 |
| -5 end and grounded | -20 |

UN2 has no relative phase jump. The character's rows use only -1, -2, zero
and positive conditions. `fighter_motion_event_due` (`0x0018CA50`) resolves a
negative motion event against the animation length only, where NA2 uses a
positive condition first; no row of this character combines the two.
`fighter_register_attack_window` (`0x00191C80`) resolves negative window
bounds as NA2 does.

## Callbacks

`nine_tailed_naruto_callbacks` populates slots 1..3:

- Slot 1 is empty (`jr ra`).
- Slot 2 (`nine_tailed_naruto_action_update`, `0x001E8D30`): in actions
  40/41/42, phase 1 at secondary cursor 7 plays action sound 30/36/30 and
  voice event 6/7/8; in action 8 at primary cursor 17 it plays sound 33.
- Slot 3 (`nine_tailed_naruto_response_override`, `0x001E8EE0`): action 21
  gives `BR`; with more than one expected hit, action 12 gives `NB12`,
  action 7 `NB14`, and action 8 phase 0 a random `NMH/NML` on the ground or
  `NAM` in the air, later phases `NB15`; otherwise -1.

## Jutsu resources

`jutsu_resource_filenames` names 72 resources; 65 and 66 are `2nrxcha0/1`.
`jutsu_selector_resource_table` maps selectors 62/63 to them (owner 31).
`jutsu_create_from_command` creates resource *n* from animation command
`0x8003` with value `0x100 + n`, the same encoding as NA2.
`ANM_pnrxcha00` in `2NRXCHA0` emits `0x141`; `ANM_pnrxcha10` in `2NRXCHA1`
emits `0x142` and other `0x8003` events 0, 1, 2 and 10.

| Resource | Allocation | Constructor | Base / vtable |
| ---: | ---: | --- | --- |
| 65 | `0x3C0` | `nine_tailed_naruto_jutsu0_construct` | `0x0075BFF0` / `0x00559110` |
| 66 | `0x410` | `nine_tailed_naruto_jutsu1_construct` | `0x007B9870` / `0x00558760` |

UN2 has no class names. The common jutsu base has vtable `0x0055C3A0`.
Resource 65 overrides 10 of its slots (vtable offsets `0x0BC..0x0C4`,
`0x104`, `0x194`, `0x198`, `0x1A8..0x1B0`, `0x1B8`). Resource 66 derives from
an intermediate class (`jutsu_participant_construct`, `0x007B9870`, vtable
`0x00558930`) that eight other jutsus share, among them Byakugan Hinata's
first jutsu, and overrides seven of its slots (`0x014`, `0x0BC`, `0x104`,
`0x194`, `0x198`, `0x1A0`, `0x1B4`).

Resource 65's class is the one UN2 also builds for resource 28 (`2jrycha1`,
Jiraiya): its setup (`0x007B3670`) binds the attacker animations
`ANM_pnrxcha01/02` for resource 65 and `ANM_pjrycha11/12` otherwise, and its
update (`0x007B2A60`) steps the attacker through phases 0..2. NA2 builds
`ccSkillNRV001` for resources 28, 113 and 149 and selects a per-resource
descriptor in the same way (`skill_nrv001_select_resource_descriptor`), but
those descriptors bind three attacker animations (`pjrycha13..15`,
`pnwvcha11..15`) and effect animations UN2's class does not use.

`0x8003` values outside `0x100..0x147` go to the side's live jutsu actor
(`jutsu_actor_dispatch_event`, `0x0076B980`), its vtable offset `0x104`.
Resource 65 ignores them. Resource 66's handler (`0x007BF110`) runs the
intermediate class's `jutsu_participant_event` (`0x007BE3C0`): each event
applies a hit to the receiver through offset `0x1B8` with the event value as
its kind, plays a receiver voice from the receiver's own event list (events
0..2 pick events `9 + 3*min(e,2)` plus a random 0..2, event 5 picks 9..11,
event 10 picks 15..17 and marks the finishing hit `+0x3E0`), and rumbles
both participants. `ANM_pnrxcha10` sends events 0, 1, 2 and 10. Event 15
(not sent by this character) also plays one of five sounds. The hit kind
handler (`0x007BE1C0`) spawns the hit effect and common sound `0x12` for
events 0..3 and 10; it applies no damage. The intermediate class keeps both
participants' fighter attack banks enabled while it runs (`0x007BCFA0` calls
`fighter_attack_banks_enable`, `0x00191970`) and clears them at setup
(`fighter_attack_banks_disable`, `0x001919E0`); no damage call was found in
`BATTLE.BIN`. Actions 1 and 3 carry damage 0.125, four expected hits,
response selector 13 and guard selector 4.

NA2's resources 65/66 still name `2nrvcha0/1`, but
their factory arms store to address zero and no NA2 selector maps to them.

Method inventory (vtable offset: method), the code each resource runs beyond
the common base:

| Owner | Methods |
| --- | --- |
| Resource 65 | `0x0BC` `0x007B2A60`, `0x0C0` `0x007B2B20`, `0x0C4` `0x007B2B30`, `0x104` `0x007B3710` (empty), `0x194` `0x007B29C0` (destructor), `0x198` `0x007B3670`, `0x1A8` `0x007B1A10`, `0x1AC` `0x007B1B00`, `0x1B0` `0x007B1F30`, `0x1B8` `0x007B1FD0` |
| Intermediate class | `0x04C` `0x007BD820`, `0x0A8` `0x007BEDE0`, `0x0BC` `0x007BD840`, `0x0C0` `0x007BD850`, `0x0C4` `0x007BD860`, `0x0C8` `0x007BDCE0`, `0x0D4` `0x007BD870`, `0x0D8` `0x007BDA60`, `0x0DC` `0x007BDA70`, `0x0E8` `0x00802830`, `0x0EC` `0x00802840`, `0x100` `0x007BE110`, `0x104` `0x007BE3C0`, `0x15C` `0x007BCFA0`, `0x16C` `0x007BED90`, `0x188` `0x007B9E30`, `0x194` `0x007B3790`, `0x198` `0x007BD050`, `0x19C` `0x007B3D10`, `0x1A0` `0x007BE1B0`, `0x1A4` `0x007BEA60`, `0x1A8` `0x007BEC30`, `0x1AC` `0x007BECD0`, `0x1B0` `0x007BA690`, `0x1B4` `0x007BA6C0`, `0x1B8` `0x007BE1C0`, `0x1BC` `0x007B9920` |
| Resource 66 | `0x014` `0x007BEE60`, `0x0BC` `0x007BF440`, `0x104` `0x007BF110`, `0x194` `0x00802B80`, `0x198` `0x007BEF50`, `0x1A0` `0x007BF1B0`, `0x1B4` `0x007BF430` |

## Sounds

Action sound selectors index `action_sfx_map` (`0x00381B60`, 93 halfwords)
into common events (`audio_common_controls`). NA2's `action_sfx_map` has 102
entries: from selector 10 on it mostly holds the same event numbers two places
later (UN2 `0x19` at 55..57 is NA2 `0x5A`), and the guard block (event `0x1D`) runs 81..95 where UN2's runs 72..86.

UN2's common bank (`SNDDATA.BIN` offset 0, header `0x57E0`, samples at
`0x5800`) and NA2's (header `0x2F40`, samples at `0x3000`; battle bank at
`0x80000`, samples at `0x82800`) share many samples, but several event
numbers hold different samples. The character's events and their NA2
equivalents by sample bytes:

| UN2 event | Same sample in NA2 |
| --- | --- |
| `0x10`, `0x18`, `0x1C` | same event number |
| `0x13` | partly equal to NA2 `0x13` |
| `0x11`, `0x12`, `0x14`, `0x15`, `0x16`, `0x1D` | none |

## Voice

Battle voice is compact. `audio_character_bank_descriptor` row 31 gives the
bank at `SNDDATA.BIN` offset `0xDE6800`, header `0x1240`, samples
`0x67210`; it is not Naruto's bank (ID 1, offset `0x2FA800`).
`battle_voice_control` (`0x002B8760`) plays `battle_voice_controls`
(`0x00418A00`, 145 rows) on the side's bank, as NA2 does.

`fighter_voice_event_list` (`0x00183E80`) takes ID 31's alternate list while
effect `0x0D` is active; IDs 1 and 31 share both lists. The normal list holds
controls 0..25, 28, 26, 27, 38, 39, 40, 23, 36, 37, 41 (program equal to the
control, key 60); the alternate list holds controls 80..121, which play the
same programs at key 61. NA2's base list is the same list without events
9..11, so UN2 event *e* is NA2 event *e* below 9 and *e* - 3 from 12.
`fighter_voice_pseudo_event` (`0x00184070`) maps -2/-3/-4 to random groups
6..8, 3..5 and 0..2, as NA2 does.

`PLVOICE.AFS` holds 33 streamed ADX archives.

The only ID-31-specific application of effect `0x0D` found is
`battle_apply_scenario_effects` (`0x002FB5E0`), which gives it (lifetime -2)
when the overlay bytes `0x006A4CB4/0x006A4CB6` are 3 and 12. The
character's constructor, callbacks and jutsu apply no effect; general
routes such as items reach `fighter_apply_status_effect` (`0x001EB220`) for
any fighter.

## Ultimate Jutsu

`sp_skill_table` (`0x00542460`, `0x14`-byte rows) holds title, resident file,
extra-body count, part count, extra bodies and a part list of
`{caption, stream}` pairs. `sp_skill_play_start` (`0x00266070`) picks row
`sp_skill_index_by_character[ID * 3 + level]`; ID 31 uses rows 90..92:

| Level | Title | Resident | Extra body | Parts (caption, stream) |
| ---: | --- | --- | --- | --- |
| 1 | Clone Jutsu | `str/d31_1e.ccs` | `2nrxbod1.ccs` | Naruto's three captions with `d31_1_3/4/5` |
| 2 | Summoning | `str/d31_2e.ccs` | — | Naruto's four captions with `d31_2_1..4` |
| 3 | The Nine-Tail | `str/d31_3e.ccs` | — | "Red Chakra Released!" `d31_3_1`, "Red Chakra Explodes!" `d31_3_3` |

The level-1 and level-2 streams differ slightly in size from Naruto's
`D01_*` streams.

### Ultimate Jutsu contest and damage

This contract is common to every UN2 Ultimate Jutsu; only the table rows
are per character.

UN2 has no per-frame hit rows. Damage builds up during the film and is
debited once after it, like UN3:

1. `jutsu_connection_start` (`0x00189920`) starts battle-director event 5
   and presentation selector 13 + level. `jutsu_presentation_update`
   (`0x002F4DF0`) shows the cut-in and calls `sp_skill_play_start`.
2. `sp_skill_play_start` builds the requests (`sp_skill_build_requests`,
   `0x00265E20`): resident file and extra bodies (`0x1000`), then each part's
   own stream in order, the first with `0x400`, which holds it until the
   presentation releases it. It also builds the contest
   (`jutsu_contest_construct`, `0x002C80A0`): attacker side, both IDs, level,
   and a mode from `jutsu_contest_modes` (`0x004F53ED`), and clears
   `jutsu_damage_total` (`0x005601EC`).
3. As each part begins, `sp_skill_play_begin` (`0x00264C30`) starts contest
   stage *n* = part *n* (`jutsu_contest_begin_stage`, `0x002C8DD0`). The
   stage row in `jutsu_contest_stage_rows` (`0x004F4160`, 12 bytes per ID,
   level and stage) gives each side's input spec (strings such as `r0r1r2r2`),
   a 90-frame input window (70 or 75 on four parts) and, at byte `+10`, an
   effect stored in `jutsu_post_film_effect` (`0x005601F0`), so the last
   part started decides it. The window grows or shrinks by up to 30
   frames with the attacker's HP lead (by the lead beyond 10 points, capped
   at 30 from a 40-point lead) and is cut so that it ends at least 90 frames
   before the part's last frame.
4. When both sides finish a stage, `jutsu_contest_resolve` (`0x002C86A0`)
   adds that stage's percent from `jutsu_stage_damage` (`0x004F3EF1`, five
   bytes per ID and level: four stage percents and a bonus) to the total. A
   defender win scales the stage by 0.66; the attacker's bonus flag adds the
   bonus percent. In modes 1..3 the stage instead compares the two sides'
   counts; a defender lead beyond the mode's threshold gives outcome 2 and
   0.66 of the stage.
5. After the film, `battle_director_jutsu` (`0x001BFA40`) applies the whole
   total to the defender through the damage calculator with flag `0x100`
   (`0x00196A20`); Practice stops at HP 0.01. Unless the defender was
   defeated, it then applies `jutsu_post_film_effect` to the attacker
   (`fighter_apply_post_jutsu_effect`, `0x001EC720`, lifetime argument -1).
   The effects are each character's buffs 13..40 in
   `status_effect_definitions` (`0x0040DF20`), for example 13 `ナルト九尾`.

`sp_skill_play_frame` (`0x00264720`) runs each part's script and position
samples. Scripts come from `sp_skill_frame_scripts` (`0x00419ED4`, three
pointers per ID, each to per-part pointers): ops 1/2 `{op, frame}` create
and destroy an alpha helper, op 3 `{op, frame, relative side, bit}` sets
appearance bit 1; each runs once the frame passes its threshold. Position
samples come from `sp_skill_position_tables` (`0x0041A160`, same
indexing): per part a threshold count, halfword thresholds and one pointer
per defender ID 0..33 to XYZ halfword triples. The films hold no `0x0108`
command sections. `sp_skill_play_begin` has two hard-coded cases: with
defender Haku (ID 10) it builds `MDL_1hak00t0 mask` from `1hakbod1` on the
mouth slot and clears the eye slots, except in stream `D20_3_2`; in stream
`D07_3_2` it hides `OBJ_1skr20t0 bod`. It compares a stream identifier
built from the stream name's digits (`D20_3_2` gives `0x200302`).

Film sound comes from three sources:

- **Soundtrack.** Each part has its own ADX in `STR.AFS` (183 members,
  stereo 48,000 Hz type 3), listed per row in `sp_skill_part_soundtracks`
  (`0x00418860`, four halfword members, -1 none). The stream player
  (`ccs_stream_player_run`, `0x002678F0`) calls
  `audio_prepare_skill_soundtrack` (`0x002B98B0`), which requests music
  preset 9: part 1's track on stream channel 1, paused.
  `audio_skill_soundtrack_frame_update` (`0x002B9960`) unpauses it at part
  1's frame 1 and starts each later part's track at that part's frame 1
  (`audio_stream_channel_play`, `0x002AFFF0`).
- **Defender cries.** `sp_skill_cue_descriptors` (`0x00418570`, per row
  `{cue rows, second pointer}`) holds 12-byte rows `{u16 frame, u16 part,
  u32 voice control, ..., key byte +0xB}` ended by frame `0xFFFF`. A row
  fires when its frame and part match.
  `audio_emit_cinematic_defender_cue` (`0x002B93F0`) plays
  `battle_voice_controls[control]` on the defender side's compact bank,
  only when that bank holds the defender; in the film viewer
  `audio_emit_cinematic_mode_cue` (`0x002B9610`) uses the key byte
  instead. The rows use controls 0, 3, 4, 12..18, 20 and 22; 182 of the
  183 parts have a control-20 row, usually the last.
- **Start shout.** `battle_director_jutsu` plays the attacker's compact
  voice event 9 + level, 11 updates into director event 5. This character
  also shouts from its callback (voice events 6/7/8 in actions 40..42).

No film routine requests `PLVOICE.AFS`; its consumer is
`audio_queue_player_voice`
([Sealed Orochimaru: Voice](sealed_orochimaru.md#voice)).

NA2's `sp_skill_build_requests` has the same request layout but repeats the
first pair's stream for every stream count, where UN2 takes each pair's own
stream; NA2's player plays queued streams in order. NA2 runs one contest at
the first stream's hold and deals damage through per-frame hit rows
([Ultimate Jutsu](../ultimate_jutsu.md#damage)).

For ID 31 (Naruto, ID 1, has the same percents and stage rows, with level-3
mode 3):

| Level | Stage percents | Bonus | Mode | Stage input specs (window 90 each) |
| ---: | --- | ---: | ---: | --- |
| 1 | 13, 6, 5 | 8 | 0 | `r0r1r2r2`, `r0r1r2r2r2`, `r0r1r2r2r2r2` (defender's last row its own copy) |
| 2 | 17, 7, 6, 6 | 8 | 0 | `r0r1r2r2`, `r0r1r2r2`, `r0r1r2r2r2`, `r0r1r2r2r2r2` |
| 3 | 27, 18 | 8 | 2 | `r0r1r2`, `r0r1r2@` (row byte `+10` 13) |

## Shared providers

The files name shared objects through marked (`#`) rows. Checked against
NA2's providers (`CMN/2CMNBOD1`, `PL/1CMNBOD1`, `CMN/EFFECT0X`,
`STRMCMN`), with the character's own bodies and each level's resident file
counted as present:

| File | Marked names | Absent from NA2's providers |
| --- | ---: | --- |
| `2NRXBOD1` | 26 | `OBJ_2cmn00t0 muffler1` |
| `2NRXCHA0` | 25 | none |
| `2NRXCHA1` | 31 | `OBJ_2cmn00t0 muffler`, `muffler1` |
| `D31_1_3/4/5` | 184 / 209 / 340 | 34 / 33 / 33 |
| `D31_2_1..4` | 179 / 194 / 212 / 221 | 37 / 35 / 32 / 29 |
| `D31_3_1/3` | 192 / 193 | 32 / 27 |

Every name absent from NA2 is present in UN2's own `CMN/EFFECT0X` or
`STRMCMN` (for example `OBJ_e0x-dot02a`, `OBJ_e00back09`, `OBJ_dash02`);
with UN2's providers every marked name resolves. NA2's `2CMNBOD1` lacks the whole `muffler` chain
([shared skeleton containers](../../../game/character_assets.md#shared-skeleton-containers)).
The films also need the presentation body `1NRXBOD1` (eyes, mouth, body) and,
in level 1, the battle body `2NRXBOD1`, which the level-1 row lists as its
extra body.
