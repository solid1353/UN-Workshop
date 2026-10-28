# Sealed Orochimaru: UN2

## Research coverage

Established for UN2 US (`SLUS-21575`) Sealed Orochimaru, ID 29 (`for`),
against retail NA2 (`SLPS-25837`) Orochimaru 89 (`orw`): identity, record,
action and row formats, both jutsu actors, the three-level Ultimate Jutsu
and its status effects, character parameters, files and their common-provider
references, and streamed and support voice selection.
Open: the compact bank's program-to-sample records (the bank is carried
whole) and the meaning of status-effect columns
f4/f5 (neutral for this character).

Names come from `@annotations/UN2` and `@annotations/NA2`; addresses are live.
UN2 evidence is from MCP target `UN2` (`SLUS_215.75`, `BATTLE.BIN` loaded at
`0x006AB000`) and the read-only `@source/UN2.iso.files` extraction.

## Identity and files

`character_definition_table` (`0x0040FBC0`) holds `{factory, record}` pairs
by character ID; slot 0 is empty and slots 1..33 are filled. Slot 29 is
`sealed_orochimaru_create` (`0x001E7840`), which allocates `0x1D30` bytes and
calls `sealed_orochimaru_construct` (`0x001E7890`). The constructor installs
vtable `0x00550F40`, points record `+0x40` at fighter `+0xAF0` (animation
lookup) and record `+0x30` at fighter `+0xD60` (working actions, 46 × `0x58`
bytes, ending exactly at `0x1D30`), then calls
`fighter_load_character_record` (`0x00187FC0`).

`sealed_orochimaru_character_record` (`0x003FCA40`) has ID 29, display name
`封印大蛇丸` and body `2forbod1.ccs`. Debug action names are `PL29_ATK_*`.
UN2 also has a separate Orochimaru (`orc`).

Files in `DATA/DATA.CVM` (gzip-compressed, every UN2 CCS is version `0x111`):

| File | Contents |
| --- | --- |
| `2FORBOD1.CCS` | Battle body, 135 source files, 123 animations |
| `2FORCHA0.CCS` | First jutsu (`pforcha00..04`, tongue `2fortan`) |
| `2FORCHA1.CCS` | Second jutsu (`pforcha10..18`, Kabuto model `2forkbt`, sword `2forkng02`, Manda `mndbody`) |
| `1FORBOD1.CCS` | Close-up body and `x\name\for\name.bmp` |
| `3EYE/3FOR3EYE.CCS` | Eye/mouth set |
| `CSFOR.CCS` | Character Select model and animation |
| `DOLL/IFFOR.CCS` | Figure |

`RPG/RPGFOR.CCS` and `RPG/RPHFOR.CCS` belong to Adventure. The Japanese
release carries the same six battle and select files. No other checked game
(UN3, UN4, UN5, NA2) has a `2FOR*` file.

## Record

The UN2 record layout against NA2's is in
[Nine-Tailed Naruto: UN2](nine_tailed_naruto.md#character-record).

| UN2 offset | Field | Sealed Orochimaru |
| --- | --- | --- |
| `+0x00..+0x1C` | ID, name, body, palette/texture/model names, anchor, callbacks | 29, `0x004B2A48`, `0x004B2A58`, `0x003F8270`, `0x003F83D8`, `0x003F8418` (`MDL_2for00t0 body`), `OBJ_eff_dummy_forhol0`, `sealed_orochimaru_callbacks` (`0x003F8480`) |
| `+0x28/+0x2C/+0x30` | Action count, actions, working actions | 46, `sealed_orochimaru_actions` (`0x003FBA70`), set by constructor |
| `+0x38/+0x3C/+0x40` | Animation count, names, lookup | 156, `sealed_orochimaru_animation_names` (`0x003F84A0`), set by constructor |
| `+0x44/+0x48` | Optional named-handle list | Zero |
| `+0x4C..+0xCF` | Physical and balance parameters | See below |

`fighter_load_character_record` copies 52 record words to fighter `+0x70`.
The parameter block `+0x4C..+0xCF` matches NA2 `+0x58..+0xDB` word for word
in order: UN2's jump code reads record `+0x78/+0x7C` (330/200), NA2's first
and second jump heights at `+0x84/+0x88`; record `+0x60` (1.2) is NA2's
gravity factor `+0x6C`; UN2's stat-growth code (`0x00185650`) treats
`+0xB0` as offense like NA2 `+0xBC`.

Against NA2 Orochimaru 89 the values agree except:

| NA2 offset | Meaning | UN2 Sealed Orochimaru | NA2 Orochimaru 89 |
| --- | --- | ---: | ---: |
| `+0x58` | Contact height | 170 | 180 |
| `+0x98` | X-dash maximum distance | 800 | 750 |
| `+0xA4` | — | 30 | 25 |
| `+0xA8` | — | 0.02 | 0.015 |
| `+0xAC` | — | 2.0 | 2.25 |
| `+0xBC` | Offense | 1.2 | 1.15 |
| `+0xC0` | Durability | 1.2 | 1.05 |
| `+0xC4` | — | 1.1 | 1.15 |
| `+0xCC` | — | 1.4 | 1.35 |
| `+0xD4` | HP recovery | 0.9 | 0.8 |
| `+0xD8` | Chakra recovery | 0.9 | 0.8 |

UN2 applies save-based stat growth (`fighter_apply_stat_growth`,
`0x00185650`) only when the side's growth flag is set; character select
(`0x00321BF0`) clears it for IDs 29..33 (`character_has_stat_growth`,
`0x002BA370`, list `0x004412C0`), so Sealed Orochimaru never grows.

## Actions and rows

### Action records

The shared field-by-field translation, with the category, flag,
response-selector, guard-selector and phase-condition tables, is in
[Nine-Tailed Naruto: UN2](nine_tailed_naruto.md#action-records); it applies
to this character's records, which use the same layout. This character's
records add: debug names `PL29_ATK_*` (NA2's are empty), English display
names (NA2's are Shift-JIS), signature bits `0xF0000` giving jutsu slot 1/2,
the `-17320.508` threshold sentinel, `+0x54` holding halfword 58/59 on
actions 1/3 (this character's selectors) and 1 elsewhere, read by no checked
consumer, and `+0x56`, set to ±4 by a jutsu swap. UN2 has no owner
halfword; `jutsu_selector_character` (`0x001ED4C0`) gives the owner as
`selector >> 1`.

`actions_setup_working_array` (`0x0018B8E0`) builds fighter `+0x800`:
actions 0..3 come from configured selectors `+0x154/+0x156` and the owner's
record (selector 1 copies `null_action_record`, `PL_ATK_NULL`, `0x00382190`);
a parity swap moves continuation ±2, sets `+0x56` to ±4 and rewrites the
`+0x20` jutsu nibble. It binds reserved animation slots `0x48..0x4A`, `0x4B`,
`0x4C..0x4E` and `0x4F` from the owner's names (NA2 `0x46..0x48`, `0x49`,
`0x4A..0x4C`, `0x4D`). `fighter_load_character` (`0x001884E0`) leaves slots
`0x48..0x4F` empty and resolves `cmn` names in `2cmnbod1`.

### Rows

Rows are `0x4C` bytes with NA2's `CharacterAnimationRow` prefix
`{slot, duration, start, rate}`. Each action owns its own array, ended by
slot -1 and padded to 16 bytes.

### Move list

| Actions | Moves |
| --- | --- |
| 0..3 | CHB0, CHA0 Snake Tongue Sucks In, CHB1, CHA1 Giant Snake: Underworld Dash |
| 4..32 | Ground and aerial combos (`ktn`, `sit`, `kcn`, `hol`, `snk`, `kca`, `kta`, `hla` families) |
| 33 | Dash (`DAS0`) |
| 34..42 | Aerial attacks `FLA00..FLA22` |
| 43..45 | Trained Soul Release: Stage One/Two/Three |

Named finishers: Blade of the Lamenting Demon (6), Sword of the Deceased (7),
Corpse Mow-Down (8), Fence of the Vengeful Demon (10), Snake Tongue of
Underworld (14), Blade from the Center of Hades (16), Snake Rope (19), Soft
Neck Throw (21), Blade of Love and Hate (24), Blade of the Vestige of
Vengeance (27), Snake Grip (29), Dazzling Spin (32).

NA2 Orochimaru 89 has 48 actions in a different order: Ultimate Jutsu slots
4..9 near the front where UN2 puts them at 43..45, and its own `porw` moves.

### Callbacks and class methods

`sealed_orochimaru_callbacks` fills slots 1..4:

- Slot 1 (`0x001E7B30`) is empty (`jr ra`).
- Slot 2 (`sealed_orochimaru_channel2`, `0x001E7B40`) sends actions 43..45 to
  `fighter_power_up_action` (below); plays common positional SFX `0x41` at
  one frame of actions 13 (6), 14 (4), 17 (12), 18 (9), 19 (0), 20 (6) and
  28 (8); plays action sound selector `0x0E` at frame 9 of action 12 and
  frame 10 of action 16; and at frame 5 of action 29 plays action sound
  `0x0E` and calls `0x00183FC0` with `0x16`.
- Slot 3 (`sealed_orochimaru_response_override`, `0x001E7E40`) picks
  response states (UN2 numbering, `action_descriptor_table` `0x00410CB0`;
  the names equal NA2's): action 27 after its first hit gives `NLH` or `BD`
  by the target's `+0x53` bit 2; action 18 gives `HOL2`; action 17 a random
  `NSH/NMH/NML` or `NAS`; action 7 `BSB` with target knockback scale 1.5 on
  its first hit, then `NB15` with 0.75; action 6 `NB12` after its first hit;
  otherwise -1.
- Slot 4 (`sealed_orochimaru_neck_throw_head`, `0x001E8020`) rewrites
  `OBJ_2cmn00t0 head`'s matrix and marks it modified during actions 20/21
  (Soft Neck Throw).

`sealed_orochimaru_vtable` (`0x00550F40`, 12 slots) differs from the base
fighter vtable (`0x00550D00`) at `+0x08` (`sealed_orochimaru_destroy`,
`0x001E7940`, common teardown), `+0x1C` (`sealed_orochimaru_update_ai`,
`0x001E7AD0`, which runs the shared BATTLE `ai_fighter_update` like every
fighter) and `+0x20/+0x28`, which are empty, as the base's
`0x001BEE90/0x001BE300` also are. The class adds no behavior to the base
fighter, and the constructor owns no helper objects or handle list.

## Jutsu

`jutsu_animation_provider_table` (`0x0040F898`, 68 rows) maps selectors
58/59 to `2forcha0/1.ccs`; BATTLE `jutsu_selector_resource_table`
(`0x0083BBD0`) maps them to resources 55/56, whose names in
`jutsu_resource_filenames` (`0x00826990`) are `2forcha0/1.ccs`.
`jutsu_create_for_resource` (`0x00756450`, `jutsu_factory_table`
`0x0083C180`) builds resource 55 at `0xA10` bytes and 56 at `0x6A0`.
The startup animations create them by animation command (`0x8003`,
`jutsu_create_from_command`): `2FORCHA0` emits `0x137` (resource 55) and
`2FORCHA1` emits `0x138` (56), then scene events `0x0F`, `0x10` and `0x0F`.
NA2 keeps resources 55/56 with the same names, but its factory arms for them
build nothing.

### First jutsu: Snake Tongue Sucks In

`sealed_orochimaru_jutsu0_construct` (`0x007E9C40`, vtable
`sealed_orochimaru_jutsu0_vtable`, `0x00555EC0`) owns five `0x50` query
shapes, compound players `+0x590/+0x720`, charge `+0x3A8 = 0.6` and step
`+0x3B0 = 0.03628118`. `sealed_orochimaru_jutsu0_initialize`
(`0x007EA050`) binds `ANM_pforcha00_1` (played at once), `01`, `01_1`,
`ANM_pfortan2`, `03`, `02` and `02_1`, and sets the base drain to
`0.6 × D / 63`, where D is the current action's damage `+0x24`.

`sealed_orochimaru_jutsu0_process` (`0x007EA500`) runs phases in `+0x3A0`:
phase 0 enables the query from count 8 until contact; phase 2 drains for
fewer than 64 counts, adds the step to the charge on each accepted input and
then debits `step × D` (halved above 1.0; the 1.2 clamp arm cannot be
reached), heals the attacker half of each debit, and every 15 counts plays
SFX `0xB2` and reports condition `0x0E`; phase 3 releases the pair, submits a
per-side action-shaped record from `0x008447E0` (response selector 15,
knockback 0.7, flags `0x40000000`, field `+0x48` zero) and shows a damage
popup of `charge × D × 0.5`; phase 4, the miss, plays `02_1`.
`sealed_orochimaru_jutsu0_select_phase` (`0x007EABD0`) pairs the participants
and plays `01_1` and `ANM_pfortan2` when phase 2 starts.

NA2's `ccSkillFOR000` (`for_construct`, BTL `0x00804670`, factory index 22,
retained for `2orccha0.ccs`) descends from this actor: same 0.6 and
`0x3D149B93` constants, same drain, charge, 15-count condition and popup. It
differs: it binds four names (`ANM_porccha01`, `01_1`, one more, `03`), has
phases 0/2/3 only (no miss phase, no initial `00_1` play) and adds a held
phase-2 particle. UN4 Orochimaru's first jutsu is the same class with `porc`
names ([UN4 Orochimaru](../un4/orochimaru.md#donor-first-jutsu-contact-drain-and-owned-helpers)).

### Second jutsu: Giant Snake: Underworld Dash

`sealed_orochimaru_jutsu1_construct` (`0x007EFF10`, vtable
`sealed_orochimaru_jutsu1_vtable`, `0x00555B30`) binds `ANM_pforcha10..18`
in its initializer (`0x007F0320`) and uses anchors `OBJ_ksng_top2`,
`OBJ_ksng_under2` and `OBJ_2kbt00t0 l hand`. Its process (`0x007F0AB0`)
enables the query at counts 10..17; contact cuts to a scene through
`sealed_orochimaru_jutsu1_setup_participants` (`0x007F1620`), which places
both fighters at their `field_player_placement` starts (on scene 17 at the
fixed point (0, 750, 220), [UN2 battle stages](../../stages/un2_stages.md));
phase 1 holds them until count 18 and phase 2 plays to completion.
`sealed_orochimaru_jutsu1_select_camera` (`0x007F40E0`) picks the shots.

On each scene event `0x0F` (`0x007F0FF0`, two in the file) it submits a
per-side `0x58`-byte action-shaped record from `0x00844AA0`: response
selector 18, knockback 2.0, damage D from the second jutsu action (0.125),
flags `0x60002000`; then common SFX `0x16` with key `0x34`. Flag `0x2000`
sets the receiver's guard to 0 before its response in the UN2 hit
admission routine `0x00192A30` (where `0x4000` sets -1), the behavior NA2's
`hit_mode1_apply` gives flag `0x400000`; `0x20000000` and `0x40000000`
follow the shared [flag table](nine_tailed_naruto.md#flags). Event
`0x10` spawns an effect at a position. No NA2 actor descends from this one.

## Ultimate Jutsu: Trained Soul Release

Actions 43..45 cost 5, 10 and 15 and play `pfornxs0`, `pforsig0` (twice) and
`pforsxn0`, the row shape of NA2 Orochimaru's actions 7..9. There is no
cinematic: `sp_skill_level_index` (`0x004415E8`) gives ID 29 no
`sp_skill_table` row, and UN2's `STR` folder holds `D01..D26` and `D31` only.
UN2's film damage and input contest ([Nine-Tailed Naruto: UN2](nine_tailed_naruto.md#ultimate-jutsu))
therefore never run for this character.

`sealed_orochimaru_channel2` calls `fighter_power_up_action` (`0x001904F0`)
with level 0..2 and effect `0x2F + level`. In phase 2 it spends the action's
cost (`0x00197390`), applies the effect through
`fighter_apply_status_effect` (`0x001EB220`) with the effect's own lifetime
and emits aura particles (`0x001BC7E0`). The move is a three-level power-up
in shared code; only the effect IDs are this character's.

### Status effects

`status_effect_definitions` (`0x0040DF20`) has `0x58`-byte rows
`{name, pad, id, lifetime, flags, f0..f8, hp delta, hp boundary,
chakra delta, chakra boundary}`; `status_effect_node_construct`
(`0x001E9E60`) copies them into list nodes.

| Column | Reducer | Meaning |
| --- | --- | --- |
| f0 | `effect_attack_factor`, additive, cap 2.0 | Attack factor |
| f1 | `effect_defense_factor`, additive, floor 0.25 | Defense factor |
| f2 | `effect_action_rate_factor`, additive, cap 1.25, neutral in majors 5/6 and gated in 8 | Action rate (NA2's rule) |
| f3 | `effect_jump_height_factor`, additive | Jump height |
| f4, f5 | `0x001EC1F0`, `0x001EC270`, additive | Not assigned |
| f6 | `effect_hit_chakra_debit_maximum`, maximum | Hit chakra debit (`0x00190360`) |
| f7 | `effect_knockback_factor`, additive | Attacker knockback (`0x0018D070`) |
| f8 | `status_effect_node_construct` | Model scale; SFX `0x4E` when not 1 |

| Effect | Name | Lifetime | Non-neutral columns |
| --- | --- | ---: | --- |
| `0x2F` | `封印大蛇丸Ａ` | 600 | attack 1.1, action rate 1.25, knockback 1.1 |
| `0x30` | `封印大蛇丸Ｂ` | 600 | attack 1.25, jump height 1.75, knockback 1.2 |
| `0x31` | `封印大蛇丸Ｃ` | 600 | attack 1.5, hit chakra debit 0.15, knockback 1.5 |

All three have flags 2. Shizune's `0x29..0x2B` (`シズネＡ..Ｃ`), Kabuto's
`0x2C..0x2E` (`カブトＡ..Ｃ`), ANBU Kakashi's `0x32..0x34` (`暗部Ａ..Ｃ`) and
Taijutsu Naruto's `0x35..0x37` (`ナルトＺＡ..ＺＣ`) have the same lifetime,
flags and values, level for level. No retail NA2 effect has any of the
three value sets ([NA2 factor columns](../../projectiles_and_items/battle_items_and_status_effects.md#authored-factor-columns)):
NA2's attack-1.1 effects (`2E`, `53`, `59`) all raise defense, none has
jump height 1.75, and its effects with attack 1.5 and knockback 1.5
(`0E`, `0F`, `10`, `24`, `57`) all raise defense. NA2's comparable path is the class-7 Ultimate Jutsu
entry, which applies its effect with lifetime -1
([Awakening](../awakening.md#exact-class-7-uj-entry)).

## Common providers

Every Sealed Orochimaru body, jutsu and select file references
`#c\2cmn\max\2cmnbod1.max` rows for `OBJ_2cmn00t0 l toe0`, `r toe0`,
`dummy23`, `muffler` and `muffler1`. UN2's `CMN/2CMNBOD1.CCS` has those rows;
NA2's has none of them in that namespace (its toe objects sit under
`c\2cmn\anm\pcmncol0.max`; muffler and `dummy23` are absent). NA2 matches
hash, namespace and name ([Cross-container references](../../../game/files/ccs_runtime.md#cross-container-references)),
so these rows stay unresolved. UN2's provider defines `muffler`, `muffler1`
and `dummy23` as skeleton objects with models; Sealed Orochimaru's body has
its own `MDL_2for00t0 muffler`, `muffler1`, `dummy23` and `l/r toe0` models
for them, and animations `pforkca70`, `pforkta50`, `pforkxn0` and `pforwal4`
key the muffler bones, so these references carry visible geometry. NA2's
`2CMNBOD1` adds `cloth1`, `cloth2` and `tail2`, which UN2's lacks. UN2's `1CMNBOD1` names are a subset of NA2's.
Every other marked row of the battle files resolves in NA2's providers. The
first jutsu's generators name `EFF_x001`, which both games'
`EFFECT0X.CCS` define.

`3FOR3EYE.CCS` references its `1FORBOD1` rows and two marked effect
namespaces, `#e\0x\tex\tiritiri.bmp` and `#e\0x\tex\e0xback03.bmp`, which UN2
supplies from `EFF3EYE.CCS` (`tiritiri.max`, `e0xback03.max` and their
textures). NA2 has no `EFF3EYE.CCS`; NA2's own `3ORW3EYE.CCS` references only
`1ORWBOD1`. UN2 has no `3???3PCT` portrait file; `1FORBOD1.CCS` carries the
name image `x\name\for\name.bmp`.

## Voice

UN2 US `PLVOICE.AFS` holds 33 nested archives (`audio_plvoice_descriptors`,
`0x00419A30`, handles `0x32..0x52`, member counts at `+6`).
`audio_queue_player_voice` (`0x002B8590`, characters below 34) queues through
`audio_write_pending_stream` (`0x00261230`) with bank = character − 1;
`audio_consume_pending_streams` (`0x002B8490`) requests family 3 through
`audio_request_archive_member` (`0x0025DB40`), which checks the member count. There is no language bank. ID 29 selects
nested archive 28, where only cues 109..112 hold audio (28,336, 7,600,
18,747 and 18,499 bytes); every other member is a 347-byte placeholder.
Ordinary characters' archives populate about 65 cues.

As a support, the actor `0x002837E0` requests SOUND.AFS bank 2 through
`audio_queue_support_voice` (`0x002B85E0`) and `support_voice_rows`
(`0x00440970`): ID 29's row (`0x0055ED20`) gives members
266..269 and variants 270..273; rows overlap the next ID's.

Compact battle voices come from `DATA/SNDDATA.BIN`.
`audio_load_battle_character_banks` (`0x002B7C30`) passes each side's
character ID minus one to `audio_load_character_bank` (`0x0025FAE0`), which
reads `audio_character_banks` (`0x00419780`, 12-byte
`{file offset, header bytes, sample bytes}` rows, the layout of NA2's table).
ID 29's row (`0x004198D0`) is `0x00CF1000`, `0x1130`, `0x556C0`. The bank
has NA2's IECS layout (`Vers`, `Head` with header/sample sizes `0x1130` /
`0x556C0`); its `Prog` section at bank `+0x900` has maximum index 41
(NA2's checked banks: 40), `Sset` (`+0x7B0`) and `Smpl` (`+0x1E0`) maximum 31
and `Vagi` (`+0x50`) maximum 30. `fighter_voice_event_list` (`0x00183E80`)
gives ID 29 the list at `0x0049A400` (row 28 of the pairs at `0x00381A50`,
base and alternate equal), which maps each voice event to the program of the
same number. The actions' voice selectors (`+0x42`) are 1, 2 and the
random-group pseudo events -2 and -3 (-1 for none); their sound selectors
(`+0x40`) are `0x1F..0x21` and `0x27..0x2A`. Callback slot 2 adds voice
event `0x16` on action 29 through `fighter_play_voice_event` (`0x00183FC0`,
events 0..35, which plays the listed program through `battle_voice_control`).
