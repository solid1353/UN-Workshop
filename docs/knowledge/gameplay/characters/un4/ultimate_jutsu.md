# UN4 Ultimate Jutsu

## Research coverage

Established in retail UN4 (`SLUS-21862`): record and request layouts,
tier selection, ordinary streamed playback and damage, branch thresholds,
form-result mapping, optional palette/script/position/filter interfaces,
the separate authored-ID-1 presentation, stage transition, seven-controller
route and attack-pattern layout with every controller's descriptor values,
the common controller base (vtable, update/draw hosting, fighter lock,
clash interface, timer and stage lifetime);
the Naruto, Jiraiya, Tsunade and Orochimaru films' and summon stages'
external providers against NA2's files; no UN4 film uses the transformed
filter bank. Each move's own resources and methods belong to its character
comparison; summon controllers whose fighter has none are recorded under
the authored-ID-1 route. Nothing shared remains open.

This document owns the checked UN4 contracts. The corresponding NA2 owners
are [Ultimate Jutsu](../ultimate_jutsu.md),
[cinematics](../ultimate_jutsu_cinematics.md), and
[Awakening](../awakening.md). Addresses are live; symbols and the `un4*`
declarations are applied in `@annotations/UN4`.
[File identities](../../../game/files/file_identities.md) identifies the resident
ELF, `BATTLE.BIN`, `TEXTENG.BIN`, and the English-view `STRMCMN.CCS`.

The term “Reversal Ultimate Jutsu” does not by itself identify the authored-ID-1
route. A low-HP/category-3 move can use ordinary streamed skill play and request
a form afterward. Naruto's checked record below is one such case. The
seven-controller table is not a census of every move described as Reversal.

## Selection and metadata

`jutsu_slots_rewrite` (`0x0022E8C0`) derives tier 2 from fighter byte
`+0x63` bit `0x20`, otherwise tier 1 from normalized HP `+0x6C <= 0.5`,
otherwise tier 0. It applies a side-dependent tier remap before choosing the
character's record. The working action stride is `0x64`.

| Tier | Record category | Working slot | Class-7 slot | Action category |
| ---: | ---: | ---: | ---: | --- |
| 0 | 2 | 4 | 7 | `0x00100000` |
| 1 | 3 | 5 | 8 | `0x00200000` |
| 2 | 1 | 6 | 9 | `0x00400000` |

`jutsu_character_record_for_category` (`0x003CCA10`) searches the counted
record-index list selected by character ID in `jutsu_character_lists`
(`0x00583B10`); the fallback is `jutsu_character_default_records`
(`0x00583C50`). Selection publishes the record at manager
`+0x98 + side*0x20`, its display name in the active locale's action field,
and its independent signed cost tier. Cost tiers 0/1/2 become 5/10/15 chakra.
Class 7 also copies the effect into fighter `+0x182`.

`jutsu_record_get` (`0x003F3BE0`) selects the locale table through the
pointer vector at `0x00608128`, then indexes `0x10`-byte records. Its checked
English table is `jutsu_name_table`, `TEXTENG.BIN 0x0086FB10`.

| Offset | `un4UltimateJutsuRecord` field | Consumer |
| --- | --- | --- |
| `0x00` | Display-name pointer | `jutsu_record_display_name`, `0x003CCB10` |
| `0x04` | Authored skill ID, unsigned halfword | `jutsu_record_playable_skill`, `0x003CC8B0` |
| `0x06` | Category, signed halfword | `jutsu_record_category`, `0x003CCC00` |
| `0x08` | Record class, byte | `jutsu_record_class`, `0x003CCC40` |
| `0x09` | Cost tier, signed byte | `jutsu_record_cost_tier`, `0x003CCCB0`; verified `lb` |
| `0x0A` | Intro voice, signed halfword | `jutsu_record_intro_voice`, `0x003CCB70` |
| `0x0C` | Effect, unsigned halfword; `0xFFFF` sentinel | `jutsu_record_effect`, `0x003CCB40` |
| `0x0E` | Damage percent, signed halfword | `jutsu_record_damage_fraction`, `0x003CCBB0`; multiplier `0.01` |

This is distinct from NA2's `0x14`-byte record, which has a second intro voice
at `+0x0C`, effect at `+0x0E`, and damage percent at `+0x10`.

`jutsu_record_classify_playability` (`0x003CC6E0`) maps authored ID
`0xFFFF` to classification `0xFF`, ID 0 to 3, and ID 1 directly to 4.
Other IDs are searched in the per-character classification data relocated
from SINF, for characters 1..77: each character's pointer selects a
`0xE`-byte row `{signed halfword count, six skill bytes, six class bytes}`,
and the first matching skill gives its class. `jutsu_record_playable_skill`
returns zero for classifications below 2 or equal to 5; otherwise it
returns the authored ID. UN4's playable films are class 3; class 5 marks
films no record plays. The checked class-5 skills `0x68..0x6D`,
`0x70/0x71` and `0x85` have a one-row placeholder hit descriptor
`{frame 1, weight 32768}` and empty English `STREAM.AFS` soundtrack
members.
NA2's SINF uses the same row layout, with class 4 for its playable films
and class 5 for films no NA2 record selects.
`sp_skill_play_classify` (`0x00330860`) independently returns 0 for skill 0,
2 for skill 1, and 1 for other skills.

### Checked low-HP Naruto path

Naruto Uzumaki, ID 57, has the counted list `{110,111}` at `0x00607DA0`.
The two English records at `0x008701F0` / `0x00870200` contain:

| Record | Authored skill | Category | Class | Cost tier | Intro | Effect | Damage percent |
| ---: | --- | ---: | ---: | ---: | --- | --- | ---: |
| 110 | `0x5A` | 2 | 3 | 0 | `0x54` | `0xFFFF` | 25 |
| 111 | `0x59` | 3 | 3 | 1 | `0x53` | `0x64` | 20 |

Thus the low-HP selection is record 111 and ordinary skill `0x59`, not
authored ID 1. Its request resources and form mapping are established below.
Character-specific move and form behavior belongs to the Naruto comparison;
these record fields establish the shared selection/execution route only.

## Ordinary cinematic requests and callbacks

`sp_skill_relocate_request_table` (`0x0032D440`) requires `strmcmn.ccs`
and resolves `BIN_strtbln4`. The checked English-view file has CCS version
`0x123`. Its decompressed `0x2400` resource starts at `0x3480`, includes
directory ID 16, and contains the `0x3274`-byte SINF at `0x348C`.

| SINF data | Relative offset | Count / representation |
| --- | --- | --- |
| Extra paths | `0x60` | 37 string offsets |
| Stream pairs | `0x100` | 146 pairs, display string then path string |
| Skill rows | `0x590` | 146 rows, stride `0x14` |
| Character classification pointers | `0x1100` | 79 entries |
| Branch frames | `0x1240` | 144 signed halfwords for skills 2..145, all 126 |
| String pool | `0x16E4` | Header's `0x16E0` offset plus 4 |

`un4SpSkillRequestRow` stores display word/name at 0, main path at 4,
extra/stream counts at 8/9, extra-array index at `0x0C`, and stream-pair
index at `0x10`. Relocation converts these offsets/indices into pointers.
The two-byte field at `0x0A` has no reader: the only code that reads the
rows, through `sp_skill_request_rows` or the relocator's own pointer, is
the relocator, `sp_skill_build_requests` and `sp_skill_play_start`, and
none of them touches it; `BATTLE.BIN` and `HOME.BIN` reference neither
pointer. UN4 has no NA2-style appearance-list pointer at row `+0x14`.
Relocation clears main paths for rows 0 and 1; their authored placeholder
paths do not establish playback of either row. It decodes each row title in
place by inverting the second byte of every double-byte character; NA2's
relocator does the same.

`sp_skill_build_requests` (`0x00330590`) emits main and extra requests with
flags `0x1000`, followed by streams with `0x400` for the first and zero for
later streams. Skill `0x23` places extras before main. An opponent-dependent
override can replace the stream and derived main path. Its ordinary loop
reuses the selected stream path for every stream-count entry; the checked
examples below each have one stream.

| Skill | Main resident | Extra residents | Stream |
| --- | --- | --- | --- |
| `0x02` | `str/d01_10e.ccs` | `pl/2nrtbod1.ccs` | `str/d01_10.ccs` |
| `0x03` | `str/d01_20e.ccs` | `pl/2nrtbod1.ccs`, `pl/6nrvbod1.ccs` | `str/d01_20.ccs` |
| `0x59` | `str/d57_10e.ccs` | `pl/2nrwbod1.ccs`, `pl/1nwvbod1.ccs` | `str/d57_10.ccs` |
| `0x5A` | `str/d57_20e.ccs` | `pl/2nrwbod1.ccs` | `str/d57_20.ccs` |

These rows name the request files; the external references those files
make are below.

`sp_skill_play_start` first asks `sp_skill_resolve_opponent_skill`
(`0x003304A0`) for a replacement. It searches `sp_skill_opponent_groups`
(`0x00609818`), relocated from the SINF `SEXC` block, for the defender ID;
each row holds a replacement skill, the requested skill and a stream path.
A replacement other than -1 changes the skill before request and hit lookup;
-1 keeps the skill and lets the row's path override the stream. Retail has
two groups:

| Defender | Requested skill | Replacement | Stream path |
| ---: | ---: | ---: | --- |
| 9 | `0x57` | `0x58` | — |
| `0x4C` | `0x05` | `0x90` | — |
| `0x4C` | `0x1C` | `0x91` | — |
| `0x4C` | `0x0D`, `0x20`, `0x25`, `0x48`, `0x80`, `0x57` | — | one per skill; `0x57` uses `str/d46_12.ccs` |

Anko's record 99 (skill `0x58`, `str/d46_11.ccs`) follows record 98 in her
list with the same category, so ordinary selection never reaches it; the
film plays only through the defender-9 replacement.

### External providers against NA2's files

A streamed film binds a `#`-marked directory row by namespace text and
object name to an already-published container, the newest match winning
([cross-container references](../../../game/files/ccs_runtime.md#cross-container-references)).
For the UN4 films `D57_10/20/30`, `D21_20/30`, `D25_10/20` and `D09_20/30`
(each with its `E` file) and the stages `KTYS_BNT/KTY/MND`, every marked key
has a typed definition in the film's own pair or in one of these providers,
except as noted:

| Provider | Used by | Same-named NA2 file |
| --- | --- | --- |
| `PL/1CMNBOD1` | Every film, 69 keys | Byte-identical decompressed |
| `CMN/2CMNBOD1` | The three stages, 34 keys | Byte-identical decompressed |
| `STRMCMN` | `D57_20`, `D57_30`, 2 keys | Different file; defines both keys |
| `PL/1NRWBOD1`, `PL/2NRWBOD1`, `PL/1JRYBOD1`, `PL/1TNDBOD1`, `PL/1ORCBOD1` | That character's films | Different file; defines every used key |
| `PL/1NWVBOD1` | `D57_10`, `D57_30`, 124 keys | Different file; lacks the 55 `OBJ_1kyw00t0*` skeleton keys |

`TEX_sampling00` (`e\0x\tex\sampling00.bmp`) is marked without a stored
definition in six of the films; both games' `EFFECT0X` and NA2's own
`D57_20E` mark it the same way. `KTYS_MND`'s four `emnd_smp0` sampling keys
also have no stored definition, as recorded in the
[Orochimaru comparison](orochimaru.md#manda-stage-and-code-selected-effects).

`sp_skill_play_start` (`0x003308A0`) resolves a replacement skill before
request and hit-descriptor lookup. It allocates a `0x301`-byte owner and
`0x2E0`-byte streamed player, with four `0x10000` blocks in each ring.
The owner stores attacker side at `+0x28`, side IDs at `+0x2A/+0x2C`,
side appearance flags at `+0x2E/+0x30`, role IDs at `+0x36/+0x38`, and
selected/current skill at `+0x3A/+0x3C`. Its callbacks are:

| Callback | Live address | Established responsibility |
| --- | --- | --- |
| `sp_skill_play_begin` | `0x0032E030` | Retain request/main container; bind defender body, eye/mouth and optional body; apply palettes; set contest duration; bind position/filter data |
| `sp_skill_play_frame` | `0x0032F200` | Consume exact-frame hits, script commands, position track and filter update |
| `sp_skill_play_draw` | `0x0032FB00` | Apply optional defender-draw gate; render filter, popups and other cinematic objects |
| `sp_skill_play_end` | `0x0032EB00` | Restore replaced models, release request-owned helpers, forward residual damage/completion |

The common participant targets include `EXT_1cmn00t0 trall/body/eye1/eye2/mou1`
and `CMP_1cmn00t0 trall`; the attacker uses the side-formatted
`EXT_1xxx00t0 body`. The container cursor and endpoint are at
`+0x1BC/+0x1C0`. The contest limit is 70, reduced to `last_frame - 90`
when the endpoint is below 160, without a lower clamp in this callback.

### Data outside SINF

The request row alone does not contain all authored cinematic behavior:

- `sp_skill_palette_substitution_descriptors` (`0x00579810`) is a resident
  per-skill pointer/count array. `sp_skill_apply_authored_palettes`
  (`0x0032DB20`) also selects four header-ID-specific substitution sets.
  `sp_skill_apply_external_palette` (`0x0032D9D0`) resolves the target,
  provider container and appearance-adjusted palette before rebinding it.
- `sp_skill_frame_scripts` (`0x005794F8`) supplies the per-skill script
  retained at owner `+0x160/+0x164`. Frame processing interprets operation 1
  as constructing a transient helper, 2 as releasing it, and 3 as changing
  a side's appearance palette. Commands run after their threshold is passed.
- `sp_skill_damage_offset_name_format` (`0x005CD950`) is `BIN_damoffs_%s`;
  the request header name supplies the suffix. Its optional data supplies
  defender-specific position samples and frame thresholds.
- `sp_skill_filter_name_format` (`0x005CF020`) is `BIN_strfilter_%s`, with
  the request-name extension removed. Setup attaches optional filter data to
  the owner at `+0x2B0`; frame and draw callbacks both use that owner.

The [UN4/NA2 optional-format comparison](#un4-and-na2-optional-cinematic-formats)
owns the checked field order, name handling, script timing, defender-index
and CCFM interfaces. Palette row order and basename handling differ;
position and CCFM serialization agree, with a transformed-filter reader
difference that no UN4 film exercises. Each move's own payloads and
providers belong to its character comparison.

## Ordinary contest, damage and form result

`jutsu_contest_create` (`0x00376870`) creates these raw modes; the vtable's
type descriptor supplies the retained class name:

| Raw mode | Native class | Allocation | Vtable | Update / render |
| ---: | --- | --- | --- | --- |
| 1 | `ccInputMatchCmd` | `0x370` | `jutsu_command_vtable`, `0x005ED6B0` | `jutsu_command_update`, `0x00371BF0` / `jutsu_command_render`, `0x00372A30` |
| 2 | `ccInputMatchRot` | `0xE8` | `jutsu_turn_vtable`, `0x005ED690` | `jutsu_turn_update`, `0x00374120` / `jutsu_turn_render`, `0x003749E0` |
| 3 | `ccInputMatchHit` | `0xE0` | `jutsu_combo_vtable`, `0x005ED6A0` | `jutsu_combo_update`, `0x003734A0` / `jutsu_combo_render`, `0x00373D60` |
| 4 | `ccInputMatchSign` | `0x1B8` | `jutsu_sign_vtable`, `0x005ED680` | `jutsu_sign_update`, `0x00375550` / `jutsu_sign_render`, `0x00376230` |

Other values create no object in this factory. Raw mode 1 is therefore not
NA2's random-mode value. The checked status accessor reads controller byte
`+0xB8`; adjacent `+0xB7` is a result-render busy flag.

`jutsu_contest_resolve` (`0x0036F4D0`) uses attacker-relative meter and
the record's normalized damage `D`. The bands are `v < -5`: status 4,
`0.66D`; `-5 <= v < 0`: status 1, `0.66D`; `0 <= v <= 5`: status 1,
`D`; `v > 5`: status 1, `D + 0.08`. This contest interruption is a
different mechanism from authored-ID-1 stage/controller execution.

`jutsu_presentation_update` (`0x00377730`) starts ordinary skill play at
intro countdown 85. `jutsu_branch_frame_reached` (`0x00331500`) indexes
the branch table by `skill - 2`, unlike NA2's `skill - 1`. The checked
thresholds are all 126: argument 1 accepts at cursor 125, argument 0 at
126. Status 4 then sets manager cinematic outcome `+0x4F4` to 2 and cuts
the remaining stream.

`cinematic_audio_descriptors` (`0x005CD4B0`) is indexed by the resolved
skill with an eight-byte count/pointer descriptor. Each
`un4UltimateJutsuHitRow` is eight bytes: signed frame at 0, signed popup
and sound bytes at 2/3, unsigned damage/chakra halfwords at 4/6.
`sp_skill_play_frame` divides both fractions by 32768. It consumes rows
only when the next row's frame equals the container cursor; it does not
catch up a row whose frame was skipped.

The film soundtrack comes from `audio_prepare_skill_soundtrack`
(`0x001D7850`): for skills 0..145 it requests music preset 9 with
`STREAM.AFS` member skill for English voices and skill + 146 for Japanese
(`audio_bank_set_selector`). The checked tracks are stereo 24 kHz ADX
except English member 111 (48 kHz). NA2's routine (`0x001D5BE0`) uses
member = skill in a single 184-member bank. There is no separate film cue
table; each hit row's sound byte is the cue.

Before a nonzero contest total, damage uses `D * fraction`. Once a total
exists, the remaining fractions redistribute the undealt total. Chakra debit
uses `fraction * 15`; sounds use the row's signed cue byte independently.
`damage_apply_cinematic` (`0x0020D3D0`) passes only flag `0x100` to
`damage_calculate` (`0x0020CF40`): the stored factors at attacker `+0x164`
and defender `+0x168`, followed by a `0..1` clamp.
It subtracts normalized HP at fighter `+0x6C`;
manager mode `+0x54 == 2` floors HP at `0.01`, while the ordinary branch
honors subtraction-suppression bit 1 at fighter `+0x62` and floors defeat at
zero. Bit 0 at `+0x62` skips the debit.
Request end handles residual damage through `jutsu_apply_completion`
(`0x0032EE50`). Outcome 2 credits the defender's interruption and returns
before form completion.

`jutsu_record_form_character` (`0x003CCD00`) maps effects `0x5A..0x63`
to IDs `0x2F..0x38` and effect `0x64` to ID `0x49` (73); other values
return zero. `jutsu_apply_completion` requests the mapped form in manager
`+0x88/+0xA8` only when condition 9 is not 1, then sets manager flag
`0x80`. The ordinary frame callback sets that condition after target defeat
when the outcome control byte is 1. Naruto record 111 therefore reaches
ID 73 through its ordinary streamed result, subject to these outcome gates.
UN4 effect numbers and condition IDs are not NA2's values.

## Separate authored-ID-1 route

`jutsu_record_presentation_flags` (`0x003CC920`) sets bit 4 when the
playable skill is 1. After normalizing selectors 13..15 to 13,
`pause_controller_begin` (`0x0037DBB0`) redirects that request to selector
16 when manager submode `+0x58 != 2`, or selector 17 when it equals 2.
`pause_controller_before_phases` (`0x0037D9A0`) dispatches those two
additional branches. NA2's inspected counterpart dispatches only 0/1/13
([pause lifecycle](../../session/pause_and_replay.md#shared-ownership-and-controller-lifecycle)).

Selector 16's `reversal_presentation_update` (`0x00378940`) freezes
fighter updates, draws the cut-in, plays the selected record's intro from
stream family 9, and at countdown 85 queues a character-dependent resource.
It does not call `sp_skill_play_start` or create the ordinary contest.
It plays `ANM_ktys_smok0` in `ktys_smok`, restores fighter update rates,
and calls `battle_request_reversal_transition` (`0x0031BD80`) with the
character ID and initiating side.

### Entry, resource and concrete controller

`reversal_entry_for_character` (`BATTLE.BIN 0x007459C0`) searches seven
`un4ReversalDefinition` entries at `reversal_definition_table`
(`0x00859CD0`), returning -1 for no match. Entries contain ordinal at 0,
character key at 4, resource index at 8 and a zero word at `0x0C`.
`reversal_resource_index_get` (`0x007459A0`) reads the resource index.
The prepare/load and transition callers use both helpers directly.

| Entry | Character key | Resource index / path | Controller allocation | Vtable / retained class |
| ---: | ---: | --- | --- | --- |
| 0 | 50 | 18, `stage/ktys_skk.ccs` | `0x6A0` | `reversal_syukaku_vtable`, `0x005F05B0`, `ccSumSyukaku` |
| 1 | 16 | 19, `stage/ktys_str.ccs` | `0x4F0` | `reversal_soutourou_vtable`, `0x005F0560`, `ccSumSoutourou` |
| 2 | 21 | 20, `stage/ktys_bnt.ccs` | `0x8F0` | `reversal_gamabunta_vtable`, `0x005F0510`, `ccSumGamabunta` |
| 3 | 25 | 21, `stage/ktys_kty.ccs` | `0x470` | `reversal_katsuyu_vtable`, `0x005F04C0`, `ccSumKatsuyu` |
| 4 | 9 | 22, `stage/ktys_mnd.ccs` | `0x650` | `reversal_manda_vtable`, `0x005F0470`, `ccSumManda` |
| 5 | 7 | 23, `stage/ktys_skr.ccs` | `0x3D0` | `reversal_sakura_vtable`, `0x005F0420`, `ccSumSakura` |
| 6 | 14 | 24, `stage/ktys_tyo.ccs` | `0x570` | `reversal_chouji_vtable`, `0x005F03D0`, `ccSumChouji` |

Paths are read from `stage_archive_paths` at `0x0083ABE0`.
`reversal_game_create_for_entry` (`0x007465B0`) establishes allocations,
vtables, common base, entry `+0x2C0`, side `+0x2C4` and CPU byte
`+0x2C8`. Its vtable drives controller-specific initialization, input,
update, attacks, draw/camera and destruction.

The character key, entry ordinal and resource index are different domains.
For ID 9, the row at `0x00859D10` is `{4,9,22,0}`: the lookup returns entry
4, its resource getter returns 22, and the factory selects `ccSumManda`.
Neither Naruto ID 1 nor ID 57 is a key in this table. That fact does not
negate Naruto's separate low-HP streamed path.

The resident ELF holds a second copy of the seven keys:
`character_has_reversal_controller` (`0x003261B0`) returns 1 for IDs
50, 25, 21, 16, 14, 9 and 7, otherwise 0. It gates
`battle_request_reversal_transition`, and in `battle_queue_fighter_ccs`
(`0x00316140`) resource-mask bit `0x20` loads `modename/ktys_smok.ccs`
only for such a character when that file is not already published.
The table and this check are separate copies of the same key set.

### Rebuild, active phase and return

When the manager exists and that check passes,
`battle_request_reversal_transition` sets manager flag `0x80`, pending
stage byte `+0xFE` to the entry's resource index and side byte `+0x4F5`
to `side + 1`. `battle_rebuild_for_pending_reversal` (`0x0031D2E0`)
first saves both fighters' HP and chakra through
`battle_save_fighter_hp_chakra` (`0x003236C0`, side -2, mask 3), then
tears down the session, saves previous stage `+0xFC` into `+0xFD`, adopts
the pending stage and queues it. `battle_select_stage_submode`
(`0x00322340`) selects submode 2 for stage indices 18..24; otherwise it
selects submode 1 and clears the pending stage.

`battle_create_graph` (`0x0031E1F0`) constructs the special controller
behind the eight-byte owner at `0x006097E4` in submode 2. It supplies entry,
side and the initiating side's CPU flag. The ordinary session still owns
both fighters and the pause controller.

`reversal_game_bind_fighters` (`0x00747650`) orders initiating fighter
`+0xEC` and opponent `+0xF0`. `reversal_game_bind_initiator_model`
(`0x00747B20`) constructs an initiating-character model from the selected
body provider and copies its appearance palettes. The controller has
human/CPU input dispatch, attack-pattern and collision data, scene players,
HUD objects and its own render environment. `reversal_game_render`
(`0x00748820`) invokes its draw callbacks and restores borrowed renderer
parameters afterward.

`reversal_game_set_time_budget` (`0x007477D0`) starts with budget 100
and derives per-update drain `100 / (seconds*60)` from manager `+0x4D8`.
`reversal_game_update_progress` (`0x007485C0`) decrements/clamps that
budget and marks completion at expiry or manager end state 3.
`reversal_game_check_attack_contact` (`0x00749A50`) uses the concrete
controller's attack patterns and collision groups.
`reversal_game_deliver_hit` (`0x00748F50`) sends its synthetic source at
`+0x110` and action at `+0x170` through `reversal_deliver_fighter_hit`
(`resident 0x0021C590`) and `fighter_apply_hit_response`
(`0x0021BC60`). This path does not consume the ordinary cinematic hit table.

The forced response selects a reaction through `fighter_select_hit_response`
(`0x0021ABF0`) and enters major state 5 through `fighter_set_major_substate`
(`0x001FF0D0`). `fighter_update_state` (`0x00233790`) dispatches that state
to `response_update_ordinary` (`0x0021E030`); its event-zero path invokes
`response_apply_table_timing` (`0x0021D8A0`).
The damage consumer samples the retained action's float at `+0x34`, divided
by its nonzero signed repeat count at `+0x3E`. It requires fighter `+0x61`
bit 3, excludes action category `+0x20` bit `0x01000000`, flags `+0x24`
bit `0x02000000`, and major-5 reactions `0x40..0x47`. It uses calculator
flags `0x133` when category `& 0x000C0000` is zero and action `+0x60` is
nonzero, otherwise `0x122`. The result subtracts HP with the same checked
mode-2 floor and ordinary zero clamp.

Thus damage for an admitted ordinary reaction comes from the synthetic action
record and ordinary factors, separately from the cinematic percentage/fraction
path.

#### Attack patterns

Each controller's descriptor, held at controller `+0xF4`, has three
`0x2C`-byte attack patterns at `+0x0C` and four CPU weight rows at
`+0x90`, one per difficulty, which `reversal_game_bind_fighters` selects.
`reversal_game_pattern_for_state` (`0x00749D80`) selects pattern 0 for
state 3, 1 for state 1 and 2 for state 2. Pattern 0 contacts use collision
group `+0x60`; patterns 1 and 2 use `+0x84`.

| Pattern offset | Field | Consumer |
| --- | --- | --- |
| `+0x00..+0x10` | Five attack-name pointers, one per UI language | `reversal_bind_hit_descriptor` copies the `ui_language_index` entry to action `+0x04` |
| `+0x16` | Voice trigger count | State-count voice dispatch |
| `+0x18` | Final reaction | Last contact |
| `+0x1A` | Intermediate reaction | Earlier contacts, with response multiplier 1 |
| `+0x1C` | Damage, float | Action `+0x34`, times controller `+0x1D4` |
| `+0x20` | Final response multiplier, float | Last contact |
| `+0x24` | Contact cap | Action repeat `+0x3E` |
| `+0x26 / +0x28` | Two signed halfwords | When `+0x26` is positive, each contact adds both to controller counter `+0xAA`, `0x7FFF` counting as 1 |

`reversal_game_check_attack_contact` stops checking once the pattern's
contact count reaches the cap, and the damage consumer divides action
damage by the same cap. A pattern whose every contact is admitted therefore
deals its damage value once in total, before ordinary factors. Controller
code can rewrite the bound action afterwards; the
[Jiraiya](jiraiya.md#gamabunta-summon-controller),
[Tsunade](tsunade.md#katsuyu-stagecontroller-ultimate-jutsu) and
[Orochimaru](orochimaru.md#reversal-entry-4) comparisons record entries
2, 3 and 4 with those rewrites.
The other descriptors hold:

| Entry / descriptor | Pattern | Damage | Cap | Final / intermediate reaction | Final multiplier | Voice trigger |
| --- | ---: | ---: | ---: | --- | ---: | ---: |
| 0 `shukaku_reversal_descriptor`, `0x00858310` | 0 / 1 / 2 | 0.02 / 0.035 / 0.05 | 2 / 1 / 6 | `0x10/0x00`, `0x10/0x10`, `0x10/0x10` | 12 / 6 / 8 | 24 / 4 / 4 |
| 1 `soutourou_reversal_descriptor`, `0x008585A0` | 0 / 1 / 2 | 0.02 / 0.035 / 0.05 | 1 / 9 / 18 | `0x10/0x01`, `0x10/0x10`, `0x10/0x10` | 4 / 10 / 10 | 16 / 4 / 4 |
| 5 `sakura_reversal_descriptor`, `0x00858F90` | 0 / 1 / 2 | 0.005 / 0.035 / 0.05 | 1 / 1 / 1 | `0x04/0x01`, `0x13/0x01`, `0x10/0x01` | 1 / 4 / 12 | 8 / 4 / 8 |
| 6 `chouji_reversal_descriptor`, `0x008591F0` | 0 / 1 / 2 | 0.02 / 0.02 / 0.05 | 1 / 1 / 1 | `0x10/0x01`, `0x10/0x01`, `0x13/0x01` | 12 / 12 / 12 | 1 / 4 / 4 |

Their initializers, at vtable `+0x40`, are `shukaku_reversal_initialize`
(`0x00730BF0`), `soutourou_reversal_initialize` (`0x00733870`),
`sakura_reversal_initialize` (`0x007404F0`) and
`chouji_reversal_initialize` (`0x00742FF0`).

#### Common controller base

The factory installs the base vtable `reversal_game_base_vtable`
(`0x005F0380`) and then the concrete one, both stored at controller
`+0x2BC`, not `+0`. The base is `0x2D0` bytes; concrete members start at
`+0x2D0`. Slots and their base defaults:

| Slot | Base default | Use |
| --- | --- | --- |
| `+0x08` | returns 1 | CPU range test for the body attack |
| `+0x0C`, `+0x14`, `+0x18`, `+0x34` | empty | start, clash-mode, clash-effect and spare callbacks |
| `+0x10` | empty | set state (0 idle, 1/2 charge releases, 3 body, 4 charge, 5..8 reactions) |
| `+0x1C`, `+0x20` | empty | draw environment, draw (concrete draws call `reversal_game_draw_hud`) |
| `+0x24` | `reversal_game_create_default_list` | charge-threshold list `+0x30` |
| `+0x28`, `+0x2C`, `+0x30` | empty | attacks, model (skipped while hit-stop `+0xAA > 0`), post-model |
| `+0x38` | zero anchor | camera anchor (also stored at `+0x40`) |
| `+0x3C` | `reversal_game_is_first_side` | — |
| `+0x40`, `+0x44` | empty | initialize; stage acquisition, called first |
| `+0x48` | `reversal_game_destroy_base` (`0x007464E0`) | destructor |

The holder `reversal_game_holder` (`0x006097E4`) is created by
`battle_create_graph` in submode 2. `battle_dispatch_phases` (`0x0031F6F0`)
calls `reversal_game_update` in phase 1 after the interaction auxiliary and
before the fighter registry (outside menu state 1), and `reversal_game_draw`
in phase 2 after the fighters and before the stage. Both fighters keep
updating. Every update the base removes the initiator's ordinary timed
effects (`effect_remove_ordinary_classes`, reason 1).

`reversal_set_fighter_control` disables the initiator's body collision
(`fighter_collision_disable`, query list `+0xDC0`) and locks its control;
jutsu actors such as `jutsu_actor_release_captured_fighters`
(`0x0079AF60`) re-enable a captured fighter only when it is not the
initiator. The opponent's attacks reach the controller's incoming group
`+0x230`. During a clash, `interaction_clash_begin` (`0x00753360`) calls
`reversal_game_set_clash_mode` (`0x00748310`) with 1 (freeze the
controller, HUD-only draw) and `reversal_game_spawn_clash_effect`
(`0x00748440`), seeding the summon side from `reversal_game_clash_power`
(`0x00749F40`); `interaction_clash_resolve_reversal` (`0x00755260`) then
sets mode 3 (won), 2 (lost) or 4 (draw). The command list
(`command_list_build`, `0x0038ECD0`) shows the controller's attack names for
the initiating side.

The selector-16 presentation queues the summon stage at countdown 85
through the load queue and waits for the loader before the smoke.
`battle_wait_pending_rebuild` (`0x00320870`) turns manager flag `0x80`
into route 10 and saves the battle timer; route 10 reaches
`battle_rebuild_for_pending_reversal` through
`battle_state_after_session` (`0x0031CC70`). The rebuild does not release
the battle stage archive: `stage_archive_adopt` only replaces the retained
container `0x00863980`, and the return releases that container (the
summon stage) and re-adopts the still-published battle stage.
`battle_state_prepare_timer` (`0x0031DBB0`) gives submode 2 a 20-second
limit and restores the saved timer afterwards; the controller keeps the
clock in step with its budget through `battle_timer_subtract`
(`0x00323100`). In submode 2, timer expiry sets end route 6 instead of a
round result; a defeated fighter (`+0x61` bit 3 clear) returns at once
after a fade.

The base's compact voices are `battle_voice_controls` rows `0x5A..0x61`,
program 55 with keys 60..67. Every UN4 compact bank of the seven
characters, in both languages, holds program 55 with ten one-key splits;
NA2's banks for its same-named characters (50, 16, 83, 84, 89, 7, 14) stop
at program 40.

`reversal_game_request_voice` (`0x00730600`) uses streamed family 6,
with entry-specific cue bases `{0,16,20,24,8,4,12}` plus phase 0..3.
`reversal_game_finish_ready` (`0x00747E40`) waits for the finish voice's
observed start/stop. `battle_reversal_phase_update` (`0x0031E9D0`) then
waits 30 updates, requests selector 17 and waits for its completion.
`reversal_return_presentation_update` (`0x00379780`) owns that finish-only
smoke presentation. `battle_session_update` (`0x00320EA0`) requests the
previous stage and route 10 after this phase or defeat. Controller destruction
releases its input locks and graph through `reversal_game_destroy_current`
(`0x00746430`).

These observations establish a temporary interactive battle phase with a
separate lifetime, rather than an alternative ordinary cinematic hit script.
Entries 2, 3 and 4 have their resources, methods and code-side rewrites in
the Jiraiya, Tsunade and Orochimaru comparisons; entries 0, 1, 5 and 6 are
below.

#### Entry 0: Shukaku

Possessed Gaara's record 103, Playing Possum Jutsu (category 1, cost tier 1,
intro 129, damage 0, skill 1), selects entry 0. The vtable overrides
`+0x08` `shukaku_reversal_in_range` (distance below 700), `+0x0C`
`shukaku_reversal_start`, `+0x10` `shukaku_reversal_set_state`, `+0x14`
`shukaku_reversal_clash_event`, `+0x18` `shukaku_reversal_bind_clash_effect`,
`+0x1C` `shukaku_reversal_draw_environment` (renderer `+0xE0` = 1500.0,
`+0xE4` = `0x60`), `+0x20` `shukaku_reversal_draw`, `+0x28`
`shukaku_reversal_update_attacks`, `+0x2C` `shukaku_reversal_update_model`,
`+0x34` `shukaku_reversal_active_contact`, `+0x38`
`shukaku_reversal_camera_anchor`, `+0x40` `shukaku_reversal_initialize`,
`+0x44` `shukaku_reversal_acquire_stage_container` and `+0x48`
`shukaku_reversal_destroy`; `+0x30` is an empty function. Ghidra defines no
function at `+0x1C`, `+0x30` or `+0x34`.

`shukaku_reversal_bind_animations` (`0x00730FB0`) resolves from
`stage/ktys_skk.ccs` the state animations `ANM_skk` `nut0`, `atc00`,
`atc02`, `atc08`, `rdy0`, `dmg2`, `dmg3`, `dmg0`, `dmg0` (states 0..8), then
`ANM_skkrdy1` (charge hold), `ANM_ektys_skk00` (bullet), `ANM_s10aefe09`
(bullet dust) and `ANM_s10aefe10` (big-bullet trail). The Gaara riding
Shukaku is the stage's own `OBJ_2gar00t0`, also the camera anchor;
`shukaku_reversal_bind_rider_palette` (`0x00731140`) gives its body
`CLT_4garbody`, `c1` or `c2` by the initiating side's costume. When
`stage/ktys_skk2.ccs` is already published, the state animations come from
it and the rider is `OBJ_2gar10t0`; no code in the executable or the
`BATTLE`, `HOME` and `RPG` overlays loads that file, so battle uses
`KTYS_SKK`. The initiating fighter is kept at `(960*s, 0, 750)`, where `s`
is -1 for side 0 and 1 for side 1, and is not drawn. Shukaku stands at
`(1500*s, 120, 0)`. `KTYS_SKK` marks no external keys. Initialization
keeps the single charge threshold at 30; descriptor `+4`, the incoming
factor, is 0.5.

States: 0 idle, 1 two bullets, 2 big bullet, 3 claw, 4 charge, 5..8
reactions. Releasing the charge picks state 2 above 30, otherwise state 1,
with cooldown 50.

| Attack | Behavior | Pattern |
| --- | --- | --- |
| Claw of Shukaku (state 3) | `shukaku_reversal_claw_attack` (`0x007335D0`): frame 27 enables three contacts fixed at `x = s*{880, 520, 200}`, z 160, radius 256/160/160; off after frame 31 or the final contact. Frame 24 starts a sand emitter that moves for 20 updates. | Descriptor `+0x0C` |
| Wind Style: Air Bullet Flying Pellets (state 1) | `shukaku_reversal_fire_bullets` (`0x00733020`) fires bullet 0 at frame 70 and bullet 1 at frame 87 from `(840*s, 0, 650)`, radius `2*progress + 150`. `shukaku_reversal_update_bullets` (`0x007326B0`) moves them 60 per update toward the opponent and down 10 or 24 (`shukaku_bullet_descent`, resident `0x00608468`); they end past \|x\| 2000 or below z -100. | Descriptor `+0x38` |
| Air Bullets (state 2) | `shukaku_reversal_fire_big_bullet` (`0x00733330`) fires at frame 72 from `x = s*(4.6*(31 - progress) + 440)`, z 200, radius `4.6*progress`; it moves 80 per update without falling and leaves two trail effects per update. | Descriptor `+0x64` |

The descriptor's pattern names are English and French; the German,
Italian and Spanish slots hold `#SommonSkillGaara…` placeholders.

Each bullet also has a second contact carrying reversal bit `0x100000`,
which an opponent's jutsu can touch. The common event setter
(`0x00748310`) then calls `shukaku_reversal_clash_event`: event 1 holds the
touched bullet while the controller is frozen, 2 releases it, 3 sends it
back toward Shukaku and 4 destroys it. A returned bullet that reaches
\|x\| 1300 on Shukaku's side, or whose second contact reports a hit through
receive bit `0x80000`, hits Shukaku:
state 7 and one eighth of the time budget lost. A returned bullet that
meets the other small bullet cancels both.

Sounds: phase voices are bank 6 cues 0..3; battle voice controls `0x5F`
(claw), `0x5C..0x5E` (reactions) and `0x62` (event 2); common cues
`0x1013`, `0x16`, `0x1014`, `0x1005`, `0x100A`, `0x1000`, `0x0E` and notes
`0x3C`/`0x3B` on each big-bullet hit. Both emitters use particle resource
80. `shukaku_reversal_release_resources` (`0x00730A00`) frees the 16-player
impact pool, the bullet players, the emitters and the owned stage container.

#### Entry 1: Soutourou

Kiba's record 40, Man-Beast Transformation Combo (category 1, cost tier 1,
intro 133, damage 0, skill 1), selects entry 1. Only the two-headed wolf is
drawn: the controller never calls `reversal_game_bind_initiator_model`,
`stage/ktys_str.ccs` holds no fighter model, and no method reads a fighter
ID. The factory builds a body contact at `+0x2D0`, three tornado contacts
at `+0x320`, one more at `+0x410` in its own group `+0x460`, and calls
`soutourou_reversal_construct` (`0x00733810`). The vtable overrides `+0x08`
`soutourou_reversal_in_range` (distance below 700), `+0x0C`
`soutourou_reversal_reset`, `+0x10` `soutourou_reversal_set_state`, `+0x14`
`soutourou_reversal_control_changed` (controls 3 and 4 end the tornado,
control 3 first taking 15 from the time meter), `+0x18`
`soutourou_reversal_place_effect` (binds `ANM_4strgrg00` to the transient
effect `FUN_00748440` supplies), `+0x1C`
`soutourou_reversal_configure_draw_environment` (renderer `+0xE0` = 1500.0,
`+0xE4` = `0x40`), `+0x20` `soutourou_reversal_draw`, `+0x28`
`soutourou_reversal_update_attacks`, `+0x2C`
`soutourou_reversal_update_model`, `+0x38`
`soutourou_reversal_camera_anchor` (`OBJ_grg_dummy01` during the tornado,
otherwise `OBJ_4str00t0 l head`), `+0x3C`
`soutourou_reversal_is_first_side`, `+0x40`
`soutourou_reversal_initialize`, `+0x44`
`soutourou_reversal_acquire_stage_container` and `+0x48`
`soutourou_reversal_destroy`.

`soutourou_reversal_bind_animations` (`0x00733AE0`) resolves `ANM_4str`
`nut00`, `nut00`, `act03`, `act02`, `nxr0`, `dmg00`, `dmg01`, `dmg02`,
`dmg02` (states 0..8), then `nut00`, `rdy0` (charge hold), `grg00`
(tornado), `lan0` (landing) and `ANM_4strgrg01` (afterimage).
Initialization sets the single charge threshold to 56, the main camera
offset to `{0, -100, -100}` and the arrow HUD to a vertical pair; descriptor
`+4`, the incoming factor, is 0.75.

States: 0 idle, 1 Wolf Fang-Over-Fang, 2 Wolf Fang-Over-Fang:
Pan-dimensional, 3 Wolf Fang, 4 charge, 5..8 reactions. Releasing the
charge picks state 2 above 56, otherwise state 1.

| Attack | Behavior |
| --- | --- |
| Wolf Fang (state 3) | `soutourou_reversal_body_attack` (`0x007365C0`): the body contact (size 112) follows `OBJ_str_atcdmy0` at height 0 during frames 9..19; frame 20 calls `battle_emit_aura_and_secondary_visual`; frames 20..34 trail resource-`0x66` effects from two, then three, then four claw and paw bones (`battle_spawn_drifting_effect`). A hit uses auxiliary hit IDs `0x33/10` and a camera shake. |
| Fang-Over-Fang (state 1) | When the release animation ends, `soutourou_reversal_complete_substate` (`0x00734070`) plays `grg00` scaled `{3, 3.5, 3}` from x = 5000 on Soutourou's side at height 240 and enables the three row contacts (sizes 128/200/128) and `+0x410`. `soutourou_reversal_update_tornado` (`0x007356A0`) moves it 150 per update; past x = 1120 on the far side it glides 12 updates to that side's home and lands (`lan0`, camera shake at frame 12, dust). Soutourou has changed sides. Every update leaves a 16-update afterimage. |
| Pan-dimensional (state 2) | The same tornado runs to x = 4000, turns, and ends past 1120 on the starting side. |

While the tornado is within 1800 of the centre,
`soutourou_reversal_steer_tornado` (`0x00735CE0`) raises or lowers it: a
human holds Up or Down (pad bits `0x1000`/`0x4000`); the CPU picks a
direction every 6..13 updates when the tornado is more than 240 above or
below the opponent. `soutourou_reversal_apply_steering` (`0x00735FC0`)
eases the vertical speed and moves the height 120 per unit of speed; Down
stops below 120. The arrow HUD shows the pressed direction.

`soutourou_reversal_position_tornado_contacts` (`0x00735A00`) moves the
tornado contacts only while the running combo count `+0x256` is below a
limit: progress / 7 + 1 for state 1 (8 at progress 56) and 8 for state 2.
The combo count clears 30 updates after the last hit, so Pan-dimensional's
second pass can hit again. The charge, not the pattern caps 9 and 18,
therefore bounds tornado hits per combo.

The descriptor's pattern names are English and French; the German,
Italian and Spanish slots hold `#SommonSkillKiba…` placeholders.

Sounds: battle voice controls `0x5F` (Wolf Fang), 7 (24 updates after a
release) and 6 (a second-pass hit); common cues 10 (release, landing),
`0x17` (Wolf Fang, tornado hit), `0x3C` (tornado hit) and `0x0B`, a loop
whose velocity follows the opponent's distance (127 under 800, 36 beyond
4000). Phase voices are bank 6 cues 16..19: English `SOUND.AFS` outer 6
members 16..19 (`summon16..19.ahx`), Japanese 44..47. The intro is bank 9
member 133 (`strST_133.ahx`), Japanese 269.

`KTYS_STR` (version `0x123`, 915 names) holds the wolf (`4strbod1`, eyes,
teeth), ten `4str` animations, the tornado boxes, `e16wdw` smoke,
`strslash01`, effect models and the `s10b` stage. Its one marked key,
`TEX_e0xwave15`, is defined in both games' `EFFECT0X` with identical
pixels; it has no `2CMNBOD1` keys. Resource `0x66`, `particle` /
`EFF_e0xsmok11`, is NA2 common-effect row `0x72` (table `0x005A3D80`,
read by `effect_resolve_common_resources`), and both `PARTICLE` files
hold identical `e0xsmok11` objects. The arrow HUD's `gauge` / `TEX_xhanyou`
exists in NA2 with different pixels and palette.

#### Entry 5: Inner Sakura

Sakura's record 16, Inner Sakura Mode (category 3, cost tier 2, intro 130,
damage 0, skill 1), selects entry 5. The factory builds two `0x50` hand
contacts at `+0x2D0/+0x320` and calls `sakura_reversal_construct`
(`0x00740360`). The vtable overrides `+0x08` `sakura_reversal_in_range`
(distance below 150), `+0x10` `sakura_reversal_set_state`, `+0x1C`
`sakura_reversal_configure_draw_environment` (renderer `+0xE0` = 1500.0,
`+0xE4` = `0x40`), `+0x20` `sakura_reversal_draw`, `+0x28`
`sakura_reversal_update_attacks`, `+0x2C` `sakura_reversal_update_model`,
`+0x30` `sakura_reversal_update_initiator`, `+0x38`
`sakura_reversal_camera_anchor` (`OBJ_4skr20t0 head` raised by 800), `+0x40`
`sakura_reversal_initialize`, `+0x44`
`sakura_reversal_acquire_stage_container` and `+0x48`
`sakura_reversal_destroy`.

`sakura_reversal_bind_animations` (`0x00740700`) resolves from
`stage/ktys_skr.ccs` the state animations `ANM_4skr` `nut0`, `atc20`,
`atc30`, `atc10`, `rdy0`, `dmg00`, `dmg01`, `dmg02`, `dmg02` (states 0..8),
then `wlk0`, `rdy1`, `atc11`, `atc14`, `atc12`, `atc15`, `atc13`,
`ANM_2skrnut0` for the initiator, `CMP_4skn00t0 body` (a giant kunai) and
`battlegauge / CMP_xshadow`. `ANM_2skrnut0` keys only the marked
`OBJ_2cmn00t0` skeleton; the initiator body is `MDL_2skr00t0 body` from
the fighter's `2skrbod1.ccs`. The stage's own `2skr` model copy is not
selected by this code. Initialization sets the single charge threshold to
54 and descriptor `+4`, the incoming factor, is 0.75.

States: 0 idle, 1 Grace of Heaven, 2 Rage of Sky, 3 Roar of Earth, 4 charge,
5..8 reactions. In idle Inner Sakura walks along X at depth 900, 16 per
update within ±880 (`sakura_reversal_update_walk`, `0x00741450`), by pad
left/right or, for the CPU, toward an opponent at least 80 away; the
initiating fighter is kept at `(x, 0, 650)`. Releasing the charge picks
state 2 above 54, otherwise state 1.

| Attack | Behavior | Patterns |
| --- | --- | --- |
| Roar of Earth (state 3) | `sakura_reversal_combo_attack` (`0x00742A10`) and `sakura_reversal_advance_combo` (`0x00740C60`): `atc10`, then `atc11` (right hand) and `atc12` (left hand) alternate while the button is pressed again, `atc13` once the count reaches descriptor byte `+8` - 1 = 6; `atc14`/`atc15` recover. CPU continues 3 in 5 within 200, else 1 in 7. Hits have a 4-update cooldown. | Descriptor `+0x0C`; the finisher binds Golden Right when the hit record's `+0x10` is 0 |
| Grace of Heaven (state 1) | `sakura_reversal_rain_kunai` (`0x007421B0`) drops 1..6 kunai (6 at threshold 54, else `progress/9 + 1`) 300 apart around the opponent from Z 4800; `sakura_reversal_update_kunai` (`0x00741E40`) delays 30..44 updates, falls 160 per update, lands for 30 updates and hits once. | Descriptor `+0x38` on landing (life 30/29), Stuck Kunai otherwise |
| Rage of Sky (state 2) | `sakura_reversal_ground_punch` (`0x007426B0`): frames 45..53 right-finger contact, frame 47 shockwave timer, frame 48 camera-helper request and a row of 14 resource-`0x66` effects. `sakura_reversal_update_shockwave` (`0x00742500`) delivers Earthquake without a contact test to an opponent at Z ≤ 24 before tick 41 if the punch did not hit. | Descriptor `+0x64`, then Earthquake |

`sakura_reversal_extra_hit_patterns` (`0x00845040`) holds three more
`0x2C` patterns, named only in Japanese:

| Pattern | Damage | Cap | Final / intermediate | Final multiplier | `+0x26/+0x28` |
| --- | ---: | ---: | --- | ---: | --- |
| 黄金の右 (Golden Right), `0x00845040` | 0.04 | 2 | `0x10/0x10` | 12 | 2 / 2 |
| 突き刺さったクナイ (Stuck Kunai), `0x0084506C` | 0.02 | 1 | `0x04/0x04` | 1 | 0 / 0 |
| 地震 (Earthquake), `0x00845098` | 0.03 | 2 | `0x0D/0x0D` | 1 | 1 / 1 |

The descriptor's pattern names are English and French; the German,
Italian and Spanish slots hold `#SommonSkillSakura…` placeholders.

Both hand contacts are created inactive. Only combo substates 3, 5 and 7
activate them, and every other combo update deactivates both. Rage of Sky
deactivates the left one and uses the right one, so its punch can connect
only after a combo that ended on the finisher; otherwise only Earthquake
hits.

Sounds: battle voice controls `0x25` at charge start and `0x62` at the
finisher; common cues `0x0E`, `0x10`, `0x12`, `0x16`, `0x17`, `0x19`,
`0x4C`. Phase voices are bank 6 cues 4..7.
`sakura_reversal_release_resources` (`0x007403B0`) drains the kunai list
and releases the players, the arrow HUD and the owned stage container.

#### Entry 6: Super Expansion

Choji's record 33, Super Expansion Mode (category 2, cost tier 1, intro 132,
damage 0, skill 1), selects entry 6. Only the giant Choji is drawn: the
controller never calls `reversal_game_bind_initiator_model`, and the
initiating fighter is kept at `(0, 0, 750)`. The factory builds two hand
contacts at `+0x2D0` in group `+0x60` and five radius-280 dive contacts at
`+0x370` in group `+0x84`. The vtable overrides `+0x08`
`chouji_reversal_in_range` (distance above 50 and below 380), `+0x10`
`chouji_reversal_set_state`, `+0x1C`
`chouji_reversal_configure_draw_environment` (renderer `+0xE0` = 3200.0,
`+0xE4` = `0x40`), `+0x20` `chouji_reversal_draw`, `+0x28`
`chouji_reversal_update_attacks`, `+0x2C` `chouji_reversal_update_model`,
`+0x38` `chouji_reversal_camera_anchor` (`OBJ_4tyo00t0 head` plus
`{0, -1000, -144}`), `+0x40` `chouji_reversal_initialize`, `+0x44`
`chouji_reversal_acquire_stage_container` and `+0x48`
`chouji_reversal_destroy`; `+0x30` is an empty function. Ghidra defines no
function at `+0x1C` or `+0x30`.

`chouji_reversal_bind_animations` (`0x00743280`) resolves from
`stage/ktys_tyo.ccs` the state animations `ANM_4tyo` `nut0`, `act10`,
`act20`, `act00`, `rdy0`, `dmg0`, `dmg1`, `dmg2`, `dmg2` (states 0..8),
then `rdy1`, `act11`, `act12`, `act01`..`act05`. Only `nut0` and `rdy1`
loop. `chouji_reversal_apply_body_palette` (`0x007433B0`) gives
`MDL_4tyo00t0 body` `CLT_4tyobody`, `c1` or `c2` by the initiating side's
costume. Initialization sets the single charge threshold to 56, adds the
`battlegauge / CMP_xshadow` landing marker and a horizontal arrow HUD;
descriptor `+4`, the incoming factor, is 0.65. The head turns toward the
opponent, at most 1.35 radians, in idle and states 5 and 6.

States: 0 idle, 1 Chubby Go-round, 2 Chubby Dive, 3 Chubby Megaton, 4
charge, 5..8 reactions. Releasing the charge picks state 2 above 56,
otherwise state 1 with twice the charge count as roll time.

| Attack | Behavior | Pattern |
| --- | --- | --- |
| Chubby Megaton (state 3) | `chouji_reversal_update_punches` (`0x00745400`) and `chouji_reversal_advance_substate` (`0x00743880`): `act00` (right hand, impact frame 24), then `act02` (left, 26) and `act04` (both, 30) while the button is pressed again during the previous punch, each else ending in its recovery `act01`/`act03`/`act05`. The CPU continues 1 in 10 per update. Contacts follow `OBJ_dummy_tyoact00/02/04 l/r`. `chouji_reversal_punch_impact` (`0x00745090`) shakes the camera (12, 16 on the third), starts a screen effect and spawns effect resource 10 at the hand. Hits have a 4-update cooldown. | Descriptor `+0x0C` |
| Chubby Go-round (state 1) | `chouji_reversal_update_roll` (`0x00744410`): `act10`, then `act11` repeated until the roll time runs out, then `act12`. The two contacts follow `OBJ_dummy_tyoact10/11 l/r` and hit at most once every 5 updates. `chouji_reversal_steer_roll` (`0x007441B0`) moves Choji 32 per update along X within ±1000 by pad Left/Right (bits `0x8000`/`0x2000`); the CPU steers toward an opponent at least 80 away. The arrow HUD shows the direction. `act12` rolls back to the centre. While rolling, the shared gauge shows the remaining roll time; `reversal_game_draw_hud` keeps it visible only for entry 6. | Descriptor `+0x38` |
| Chubby Dive (state 2) | `chouji_reversal_update_dive` (`0x00744920`), on `act20` frames: Choji is hidden on frames 28..55; frame 28 picks one of two layouts by the sign of the opponent's X and lays the five contacts 280 apart along X; frames 29..97 grow the landing marker; frame 72 shakes the camera; frame 98 ends the contacts. One hit; contacts from frame 75 deal half damage with reaction 4. | Descriptor `+0x64` |

The descriptor's pattern names are English and French; the German,
Italian and Spanish slots hold `#SommonSkillChoji…` placeholders.

Sounds: battle voice controls `0x25` (charge start), `0x05` and `0x08`
(second and third punch), `0x5F` (punch start), `0x63` and `0x62` (roll),
`0x16`, `0x19` or `0x07` (dive) and `0x5C..0x5E` (reactions); common cues
`0x14` (punch impacts), `0x1F` and `0x1E` (dive). Controls `0x5C..0x63`
select program 55: UN4 Choji's compact banks hold it with keys
`0x3C..0x45`, NA2 Choji's bank (`Prog` maximum 40) does not. Phase voices
are bank 6 cues 12..15: English `SOUND.AFS` outer 6 members 12..15,
Japanese 40..43. The intro is bank 9 member 132, Japanese 268.

`KTYS_TYO` (version `0x123`, 1,523 names) holds Choji (`4tyobod1`), the 16
`4tyo` animations, the dummies and the `s10c` stage; it marks no external
keys. Its `BIN_bgdata` uses factories 0, 2, 10, 11, 17, 18, 31, 33, 34, 35
and 37. Effect resource 10 is `effect0x` / `ANM_e0x_down_01`, also NA2
common-effect row 10 (table `0x005A3D80`); NA2's animation is 1,264 bytes
against UN4's 7,568.

## UN4 and NA2 optional cinematic formats

This comparison uses retail UN4 `SLUS_218.62` and NA2 `SLPS_258.37`.
It establishes the shared readers' interfaces; each film's payloads belong
to its character comparison. CCS frame commands and camera records remain owned
by [CCS runtime](../../../game/files/ccs_runtime.md#frame-payloads).

### Resident palette rows and appearance flags

UN4 `sp_skill_apply_authored_palettes` (`0x0032DB20`) indexes
`sp_skill_palette_substitution_descriptors` (`0x00579810`) by resolved
skill. An eight-byte descriptor contains a pointer to an array of row
pointers, then a signed count. Each pointed-to `un4SpSkillPaletteRow`
is twelve bytes: source-container name at `+0`, target name at `+4`,
source-palette name at `+8`. This is not an inline row array.

UN4 `sp_skill_apply_external_palette` (`0x0032D9D0`) forms the palette
basename from the source string's byte length minus two. It then appends
`c1` when attacker appearance bit 0 is set, otherwise `c2` when bit 2 is
set. Both clear means the trimmed basename. NA2's same-named helper
(`0x00357FE0`) copies the entire source name before choosing the same suffix.
Consequently, equal source strings do not establish equal palette lookups.

NA2 instead obtains an inline array through its SINF request row. Each
`SpSkillAppearanceRow` is twelve bytes: container at `+0`, palette at
`+4`, target at `+8`. Its begin callback chooses the external helper for
target prefix `EXT`, otherwise `sp_skill_apply_material_palette`
(`0x00358130`). UN4's resident list always calls the external helper.
The shared external route treats a null container name as the retained main
resident, requires the streamed target and its model, duplicates model
arrays with `0x2000`, and rebinds the selected palette. The distinct NA2
material route writes the resident target's palette pointer. Neither route
obtains a provider from the row's numeric position alone.

### Resident frame scripts

Both `sp_skill_play_frame` callbacks (UN4 `0x0032F200`, NA2
`0x0035B740`) implement the following resident word stream, separately
from CCS commands and hit/cue rows:

| Operation | Words | Effect |
| ---: | --- | --- |
| 1 | `1, threshold` | Allocate the one-byte device-alpha helper. |
| 2 | `2, threshold` | Release and clear that helper. |
| 3 | `3, threshold, role_offset, alternate_bit` | Select side `(attacker_side + role_offset) & 1`; replace appearance bit 1 with `(alternate_bit & 1) << 1`, retaining the other saved flags; resolve and rebind that side's body texture/palette. |
| 0 | `0, threshold` | End the script by clearing its current pointer. |

Processing uses unsigned `threshold < integer_frame`, including the
terminator; it catches up all passed commands in one callback. A negative
playback rate first restores both sides' original appearance, frees the
helper and restores the saved script pointer. Operation 3 changes the
resolved body resources, not the saved side appearance flags.

UN4 `sp_skill_frame_scripts` (`0x005794F8`) is indexed directly by
resolved skill. NA2's pointer vector (`0x005AB380`) uses `skill - 1`,
with unsigned indices above `0xB5` selecting entry zero. Both begin
callbacks retain current/original pointers at skill-owner `+0x160/+0x164`.
The helper at `+0x15C` drives `draw_environment_device_alpha_pass`
(UN4 `0x0010BFA0`, NA2 `0x0010BD20`). Its allocation and reset/end
release are separate from the filter owner and draw-switch resources.

### Defender position tracks

Both `sp_skill_parse_defender_offsets` readers (UN4 `0x0032D340`,
NA2 `0x003579A0`) recognize `_damOffs` and version `0x100`:

| Payload offset | Stored data |
| --- | --- |
| `+0` | Eight magic bytes `_damOffs`. |
| `+8` | Unsigned version halfword. |
| `+0xA / +0xC` | Phase count and defender count, read with signed halfword loads. |
| `+0xE` | Phase-count signed halfword frame thresholds. |
| After thresholds | Defender-major arrays; each has phase-count signed halfword XYZ triples, six bytes per phase. |

Both readers publish borrowed threshold/sample pointers into a separately
allocated descriptor; the file contains no pointer table. Setup selects
the actual role-ordered defender ID. Frame processing uses the latest
eligible threshold, or phase zero before the first threshold, and builds
a translation from the chosen XYZ triple. UN4 does not fill undeclared
defender entries. NA2 fills entries through ID 93 after a short table with
a shared cleared `0xC0`-byte buffer; it does not map same-name fighters
between games. NA2 then applies its independently authored
[position dispatch](../ultimate_jutsu_cinematics.md#defender-specific-draw-and-placement-dispatch).
The [Shizune/Kabuto tables](shizune_kabuto.md#shizunekabuto-offsets-filters-and-resident-scripts)
show both changed ID coverage and changed same-name position values.

### CCFM filter payloads and consumers

UN4 `cinematic_filter_load_ccfm` (`0x00399FC0`) and NA2
`ccfm_owner_load` (`0x00370860`) use the same eight-byte `CCFM` header:
magic at `+0`, unsigned version at `+4`, then two bytes not interpreted
by these readers. The four blocks begin at `+8`, in this order:

| Block | UN4 / NA2 reader | Serialized contents |
| --- | --- | --- |
| Callback | `ccfm_read_callback_records`, `0x0039A270 / 0x00370AE0` | Two unsigned halfword counts; record-count `0x328` rows; interval-count halfword thresholds; interval-count halfword row counts. |
| Auxiliary sampling | `ccfm_read_auxiliary_records`, `0x0039A410 / 0x00370C70` | Same grouping, with `0x18` rows. |
| Transformed sampling | `ccfm_read_transformed_records`, `0x0039A5B0 / 0x00370E10` | Same grouping, with `0x360` rows. |
| Fog and resource names | `ccfm_read_fog_records`, `0x0039A760 / 0x00370FD0` | Halfword count and unused halfword; count `0x2C` rows; count 32-bit thresholds; 32-bit resource-name count and names at `0x20`-byte stride. |

For the first three blocks, zero records consumes only their four-byte
header. A zero fog count likewise consumes only its four-byte header,
without a resource-name count or names. Runtime grouping uses eight-byte
count/pointer descriptors into copied rows. The fog reader expands each
`0x2C` row to `0x30`: byte 0
and words `+4..+0x14` keep their offsets; four words `+0x18..+0x24`
move to runtime `+0x20..+0x2C`. Thresholds and the name count narrow
to signed halfwords. It copies `0x1E` bytes of each name and resolves
the scene lookup before refreshing secondaries.

Both draw callbacks select half-open intervals `start <= frame < next`;
the final interval extends to `0x7FFFFFFF`. Their row applicators agree:

| Row | Checked field use |
| --- | --- |
| `0x328` callback | Scalar/color controls at byte 0 and `+4..+0x34`; selector byte `+0x38`; selector 1 uses six `0x10` float vectors at `+0x3C`, selector 2 uses an eight-byte center at `+0x9C` and five `0x80` vertex blocks at `+0xA4`; signed group `+0x324`, enable byte `+0x326`. |
| `0x18` auxiliary | Option byte 0, controls `+4/+8/+0xC/+0x10`, signed group `+0x14`, enable byte `+0x16`. |
| `0x360` transformed | Prefix byte 0, XY/width/height at `+4..+0x10`, three vector/control triples at `+0x14..+0x34`, embedded callback row at `+0x38`, signed group `+0x35C`, enable byte `+0x35E`. |
| Expanded fog | Four float arguments at `+4..+0x10` and integer enable at `+0x14` feed the linked renderer's `render_set_fog`. |

The callback selectors use resident handlers installed by
`render_callback_owner_initialize` (UN4 `0x00397F80`, NA2
`0x0036E920`): selector 1 prepares/draws six rectangle pairs; selector
2 prepares/draws a center fan and four radial ring strips. Those code
pointers come from each game's resident template, not the serialized row.
Renderer ownership and viewport publication belong to
[renderer coordinates](../../../runtime/rendering/renderer_coordinates.md#ultimate-jutsu-callback-renderer-states).

One reader difference is established by UN4 instructions
`0x0039A69C..0x0039A6C0`: it allocates the transformed bank's threshold
array and skips the source threshold bytes without copying them. NA2
copies those bytes. No UN4 film exercises it: every one of the 143 CCFM
`BIN_strfilter_*` payloads in the English `STR` folder has a zero
transformed record count, so both readers consume only that bank's
four-byte header. `BIN_strfilter_d47_10` is the one `STR` filter blob
that is not CCFM.

Version `>= 0x200` adds a fifth block through `ccfm_read_child_timeline`
(UN4 `0x00399130`, NA2 `0x0036FA50`): unsigned 32-bit child count
and block byte length, then that many variable-length children. The reader
finishes at block start plus the declared length. Each child has an
eight-byte header: four two-bit channel modes in the low byte of word 0,
signed ordering group at `+4`, and option byte at `+6`. Channels follow
in order discrete/scalar/discrete/scalar:

| Mode | Serialized channel |
| ---: | --- |
| 0 | No bytes; scalar advancement assigns zero, discrete advancement retains its initialized control. |
| 1 | One borrowed 32-bit constant. |
| 2 | Unsigned 32-bit key count, then that many 32-bit frame/value pairs; scalar values are float32 and discrete values remain 32-bit words. |
| 3 | No bytes; no control assignment during advancement. |

`ccfm_child_initialize` (UN4 `0x0039AF70`, NA2 `0x003717B0`)
clears the four output controls before loading channels. Mode 2 reads its
first frame/value pair unconditionally, so the checked reader expects a
nonzero key count. Both runtime-size tables reserve `4/4/12/0` bytes for
modes `0/1/2/3`; reset and advancement consume state only for modes 1/2.

Both channel readers construct owned segment arrays for mode 2, use
`frame << 8` durations, prepend a zero lead-in when the first key is
nonzero, and extend to the cinematic frame limit. Scalar evaluation
interpolates value deltas; discrete evaluation keeps the current step.
`ccfm_child_advance` (UN4 `0x0039B390`, NA2 `0x00371BC0`) publishes
the four controls at child `+0x44/+0x48/+0x4C/+0x50`.
`ccfm_child_timeline_draw` (`0x00399280 / 0x0036FB90`) submits them
through `ccfm_sampling_pass_submit` (`0x00357010 / 0x001C8B40`) in
each child's draw environment. Negative owner rate resets and seeks to
the integer cinematic frame; ordinary stepping uses the retained fixed-point
rate. Release frees the generated mode-2 arrays and runtime payload;
mode-1 words remain borrowed from the serialized input.

Thus the checked CCFM serialization and binding interfaces agree. Each
film's payload bytes, targets and participant wrappers belong to its
character comparison.
