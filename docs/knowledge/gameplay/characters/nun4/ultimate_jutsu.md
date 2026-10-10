# NUN4 Ultimate Jutsu

## Research coverage

Established in retail NUN4 (`SLUS-21862`): record and request layouts,
tier selection, ordinary streamed playback and damage, branch thresholds,
form-result mapping, optional palette/script/position/filter interfaces,
and the separate authored-ID-1 presentation, stage
transition and seven-controller route. Open: complete resource and method
closure of each selected move, and the authored damage/repeat/reaction choices
in each special controller's concrete attack sets.

This document owns the checked NUN4 contracts. The corresponding NA2 owners
are [Ultimate Jutsu](../ultimate_jutsu.md),
[cinematics](../ultimate_jutsu_cinematics.md), and
[Awakening](../awakening.md). Addresses are live; symbols and the `Nun4*`
declarations are applied in `@annotations/NUN4`.
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

| Offset | `Nun4UltimateJutsuRecord` field | Consumer |
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
from SINF. `jutsu_record_playable_skill` returns zero for classifications
below 2 or equal to 5; otherwise it returns the authored ID.
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

`Nun4SpSkillRequestRow` stores display word/name at 0, main path at 4,
extra/stream counts at 8/9, extra-array index at `0x0C`, and stream-pair
index at `0x10`. Relocation converts these offsets/indices into pointers.
The two-byte field at `0x0A` is not assigned a meaning here. NUN4 has no
NA2-style appearance-list pointer at row `+0x14`.
Relocation clears main paths for rows 0 and 1; their authored placeholder
paths do not establish playback of either row.

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

These are decoded request identities, not complete typed dependency closures.

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

The [NUN4/NA2 optional-format comparison](#nun4-and-na2-optional-cinematic-formats)
owns the checked field order, name handling, script timing, defender-index
and CCFM interfaces. Palette row order and basename handling differ;
position and CCFM serialization agree, with a transformed-filter reader
difference. Selected payloads and providers remain separate questions.

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
`Nun4UltimateJutsuHitRow` is eight bytes: signed frame at 0, signed popup
and sound bytes at 2/3, unsigned damage/chakra halfwords at 4/6.
`sp_skill_play_frame` divides both fractions by 32768. It consumes rows
only when the next row's frame equals the container cursor; it does not
catch up a row whose frame was skipped.

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
NUN4 effect numbers and condition IDs are not NA2's values.

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
`Nun4ReversalDefinition` entries at `reversal_definition_table`
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

### Rebuild, active phase and return

`battle_request_reversal_transition` sets manager flag `0x80`, pending
stage byte `+0xFE` to the entry's resource index and side byte `+0x4F5`
to `side + 1`. `battle_rebuild_for_pending_reversal` (`0x0031D2E0`)
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
path. The concrete controllers' authored damage, repeat counts, reaction choices
and number of admitted contacts remain to be closed for each selected entry.

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
They do not establish every concrete controller's authored attack set or
complete asset dependencies.

## NUN4 and NA2 optional cinematic formats

This comparison uses retail NUN4 `SLUS_218.62` and NA2 `SLPS_258.37`.
It establishes the shared readers' interfaces, independently of the selected
character payloads below. CCS frame commands and camera records remain owned
by [CCS runtime](../../../game/files/ccs_runtime.md#frame-payloads).

### Resident palette rows and appearance flags

NUN4 `sp_skill_apply_authored_palettes` (`0x0032DB20`) indexes
`sp_skill_palette_substitution_descriptors` (`0x00579810`) by resolved
skill. An eight-byte descriptor contains a pointer to an array of row
pointers, then a signed count. Each pointed-to `Nun4SpSkillPaletteRow`
is twelve bytes: source-container name at `+0`, target name at `+4`,
source-palette name at `+8`. This is not an inline row array.

NUN4 `sp_skill_apply_external_palette` (`0x0032D9D0`) forms the palette
basename from the source string's byte length minus two. It then appends
`c1` when attacker appearance bit 0 is set, otherwise `c2` when bit 2 is
set. Both clear means the trimmed basename. NA2's same-named helper
(`0x00357FE0`) copies the entire source name before choosing the same suffix.
Consequently, equal source strings do not establish equal palette lookups.

NA2 instead obtains an inline array through its SINF request row. Each
`SpSkillAppearanceRow` is twelve bytes: container at `+0`, palette at
`+4`, target at `+8`. Its begin callback chooses the external helper for
target prefix `EXT`, otherwise `sp_skill_apply_material_palette`
(`0x00358130`). NUN4's resident list always calls the external helper.
The shared external route treats a null container name as the retained main
resident, requires the streamed target and its model, duplicates model
arrays with `0x2000`, and rebinds the selected palette. The distinct NA2
material route writes the resident target's palette pointer. Neither route
obtains a provider from the row's numeric position alone.

### Resident frame scripts

Both `sp_skill_play_frame` callbacks (NUN4 `0x0032F200`, NA2
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

NUN4 `sp_skill_frame_scripts` (`0x005794F8`) is indexed directly by
resolved skill. NA2's pointer vector (`0x005AB380`) uses `skill - 1`,
with unsigned indices above `0xB5` selecting entry zero. Both begin
callbacks retain current/original pointers at skill-owner `+0x160/+0x164`.
The helper at `+0x15C` drives `draw_environment_device_alpha_pass`
(NUN4 `0x0010BFA0`, NA2 `0x0010BD20`). Its allocation and reset/end
release are separate from the filter owner and draw-switch resources.

### Defender position tracks

Both `sp_skill_parse_defender_offsets` readers (NUN4 `0x0032D340`,
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
a translation from the chosen XYZ triple. NUN4 does not fill undeclared
defender entries. NA2 fills entries through ID 93 after a short table with
a shared cleared `0xC0`-byte buffer; it does not map same-name fighters
between games. NA2 then applies its independently authored
[position dispatch](../ultimate_jutsu_cinematics.md#defender-specific-draw-and-placement-dispatch).
The selected Shizune/Kabuto tables below demonstrate both changed ID
coverage and changed same-name position values.

### CCFM filter payloads and consumers

NUN4 `cinematic_filter_load_ccfm` (`0x00399FC0`) and NA2
`ccfm_owner_load` (`0x00370860`) use the same eight-byte `CCFM` header:
magic at `+0`, unsigned version at `+4`, then two bytes not interpreted
by these readers. The four blocks begin at `+8`, in this order:

| Block | NUN4 / NA2 reader | Serialized contents |
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
`render_callback_owner_initialize` (NUN4 `0x00397F80`, NA2
`0x0036E920`): selector 1 prepares/draws six rectangle pairs; selector
2 prepares/draws a center fan and four radial ring strips. Those code
pointers come from each game's resident template, not the serialized row.
Renderer ownership and viewport publication belong to
[renderer coordinates](../../../runtime/rendering/renderer_coordinates.md#ultimate-jutsu-callback-renderer-states).

One reader difference is established by NUN4 instructions
`0x0039A69C..0x0039A6C0`: it allocates the transformed bank's threshold
array and skips the source threshold bytes without copying them. NA2
copies those bytes. This establishes a reader difference, not a nonempty
donor bank, a shipped failure or equal filter output. The selected
byte-identical Shizune/Kabuto and Tsunade payload comparisons remain
bounded to their named films.

Version `>= 0x200` adds a fifth block through `ccfm_read_child_timeline`
(NUN4 `0x00399130`, NA2 `0x0036FA50`): unsigned 32-bit child count
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

`ccfm_child_initialize` (NUN4 `0x0039AF70`, NA2 `0x003717B0`)
clears the four output controls before loading channels. Mode 2 reads its
first frame/value pair unconditionally, so the checked reader expects a
nonzero key count. Both runtime-size tables reserve `4/4/12/0` bytes for
modes `0/1/2/3`; reset and advancement consume state only for modes 1/2.

Both channel readers construct owned segment arrays for mode 2, use
`frame << 8` durations, prepend a zero lead-in when the first key is
nonzero, and extend to the cinematic frame limit. Scalar evaluation
interpolates value deltas; discrete evaluation keeps the current step.
`ccfm_child_advance` (NUN4 `0x0039B390`, NA2 `0x00371BC0`) publishes
the four controls at child `+0x44/+0x48/+0x4C/+0x50`.
`ccfm_child_timeline_draw` (`0x00399280 / 0x0036FB90`) submits them
through `ccfm_sampling_pass_submit` (`0x00357010 / 0x001C8B40`) in
each child's draw environment. Negative owner rate resets and seeks to
the integer cinematic frame; ordinary stepping uses the retained fixed-point
rate. Release frees the generated mode-2 arrays and runtime payload;
mode-1 words remain borrowed from the serialized input.

Thus the checked CCFM serialization and binding interfaces agree. This
comparison does not establish complete packet-byte equivalence, every
selected provider/target or participant-wrapper lifetime. Those depend on
the exact film and are separate from the format reader contracts.
