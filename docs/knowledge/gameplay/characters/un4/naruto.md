# Naruto: UN4 donor

## Research coverage

Established for UN4 Part II Naruto 57 and Second Stage 73 against NA2 Naruto 57
and Fourth Awakened 73: action records, input routes and the response-selector
domain; ordinary and UJ titles; the form's private motion, arm and particle
ownership; which NA2 jutsu classes and contact definitions match the donor's;
typed, code-selected and command dependencies; film payloads, appearance rows,
damage offsets and NA2's retained request rows; intro, dialogue and compact
voice joins; AI, roster, jutsu admission and NA2 support services.
Open: none.

Names come from `@annotations/UN4` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [UN3 and UN4 characters](../un3_un4_characters.md).

## Records, moves and assets

**Checked identities:** UN4 `SLUS-21862` Part II Naruto ID 57
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
| UN4 Classic Naruto 1 | `naruto_classic_character_record 0x0043E650`; `0x0043D390 / 0x00439B20 / 0x004398B0` | 48 / 190 / 156 | `fighter_id_001_create 0x0023FEF0 / naruto_classic_construct 0x0023FF40`; `0x5C70` |
| NA2 Classic Naruto 1 | `0x0040DB70`; `0x0040CBA0 / 0x00409110 / 0x00408CA0` | 48 / 190 / 156 | `naruto_classic_construct 0x00250C50`; `0x5980` |
| UN4 Nine-Tailed Naruto 47 | `naruto_nine_tails_character_record 0x004ED7A0`; `0x004EC540 / 0x004E8DB0 / 0x004E8B50` | 47 / 187 / 149 | `naruto_nine_tails_create 0x00279690 / naruto_nine_tails_construct 0x002796E0`; `0x5B20` |
| NA2 Nine-Tailed Naruto 47 | `0x004A68A0`; `0x004A5910 / 0x004A1F90 / 0x004A1C90` | 47 / 187 / 149 | `0x0027E810`; `0x5840` |
| UN4 Naruto 57 | `naruto_character_record 0x0051CD90`; `naruto_actions 0x0051BA60 / 0x00518110 / 0x00517E90` | 49 / 193 / 157 | `naruto_create 0x00292560 / naruto_construct 0x002925B0`; `0x5E60` |
| NA2 Naruto 57 | `0x004DAD80`; `0x004D9D50 / 0x004D61F0 / 0x004D5E30` | 49 / 193 / 157 | `naruto_construct 0x00295DB0` |
| UN4 Second Stage 73 | `naruto_second_stage_character_record 0x00565950`; `naruto_second_stage_actions 0x005645C0 / naruto_second_stage_animation_rows 0x005609C0 / naruto_second_stage_animation_names 0x00560740` | 50 / 202 / 159 | `naruto_second_stage_create 0x002C2340 / naruto_second_stage_construct 0x002C2390`; `0x6170` |
| NA2 Fourth Awakened 73 | `nine_tails_fourth_character_record 0x00535D50`; `0x00534E20 / 0x005316A0 / 0x00531260` | 46 / 181 / 152 | `0x002CE5A0`; `0x5840` |

The complete 33 stored parameter words at record `+0x58..+0xD8`
agree in all four same-ID pairs. These stored parameters do not establish
equal animation, callbacks or jutsu. UN4 action stride is `0x64`, with
five display pointers and packed owner/selector at `+0x1C`; NA2 stride
is `0x54`, with one display pointer and that word at `+0x0C`.
`un4ActionRecord` records the checked UN4 layout.

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

### Naruto ordinary-jutsu display bindings

UN4 stored action display slots are zero until the resident initializer
fills them. It writes each jutsu action's English slot `+0x08` and the
same French pointer to `+0x0C..+0x18`. NA2 stores one Japanese pointer
at action `+0x08`.

| Fighter / selector / action | UN4 English; French | UN4 store | NA2 title |
| --- | --- | --- | --- |
| Naruto 57 / 114 / 1 | **Naruto Uzumaki Combo Attack**; `Combo Naruto Uzumaki` | `naruto_jutsu0_bind_english_title 0x005E345C` | `うずまきナルト連撃` |
| Naruto 57 / 115 / 3 | **Rasengan**; `L'Orbe Tourbillonnant` | `naruto_jutsu1_bind_english_title 0x005E3494` | `大玉螺旋丸` |
| Form 73 / 146 / 1 | **Nine Claw Combo Attack**; `Combo des Neuf Griffes` | `naruto_second_stage_jutsu0_bind_english_title 0x005E63D4` | `緋染絣` |
| Form 73 / 147 / 3 | **Vermilion Rasengan**; `Rasengan Vermillon` | `naruto_second_stage_jutsu1_bind_english_title 0x005E640C` | `虚狗砲` |

The English pointers are `0x004381B0/B4` and `0x00438570/74`; the French
ones are `0x1030` higher. Selector rows are `{action, filename, 1}`.
`naruto_jutsu0/1_bind_display_record` (`0x005E78C4/0x005E78D4`) write
ID 57's action base `+0x64/+0x12C` to selectors 114/115; the second-stage
pair at `0x005E7B44/0x005E7B54` does the same for selectors 146/147.
`jutsu_selector_display_name` returns that action's `+0x08 + 4*language`
slot. NA2's `naruto_jutsu0/1_bind_display_record` (`0x005D8D1C/28`) and
`nine_tails_fourth_jutsu0/1_bind_display_record` (`0x005D8F5C/68`) write
action base `+0x54/+0xFC`. MCP does not expose these initializer tails as
functions; the stores were read as MCP memory bytes.

### Naruto input admission and response selectors

All 49 base actions agree in owner/selector, category, flags,
continuation, signature and cost; their phase rows also agree. The base
fighter therefore has the same stored Circle routes, jutsu inputs and Extra
Hit groups in both games. Its stored differences are the response selector
and, in actions 36/44, word `+0x58` (native `+0x48`) `0x13` versus `0x18`.

UN4 `fighter_select_hit_response` reads `un4ActionRecord.response_selector`
at `+0x3C`; NA2 `response_select_substate` reads `+0x2C`. UN4 selectors
`0..5` choose the same grounded/airborne substates as NA2 selectors `0..5`.
NA2 adds grounded selectors 6/7 (substates `0x2D/0x2E`), and every UN4
selector from 6 equals NA2 selector +2, with substates also two higher
(for example UN4 `0x0D` → `0x34/0x35`, NA2 `0x0F` → `0x36/0x37`; UN4
`0x1F` → `0x57`, NA2 `0x21` → `0x59`). Every differing Naruto 57 value
is from 6 and native is donor +2. The guard-bypass, failed-gate and streak
results follow the same two-higher substate domain.

The form's jutsu actions 0..3 agree with native 73 apart from that response
conversion: Up, Up, Circle is startup 0 (cost 3) with outcome continuation 1,
and Down, Down, Circle directly selects action 3 (cost 3). Signatures and
Extra Hit groups follow
[Orochimaru input admission](orochimaru.md#orochimaru-input-admission-and-phase-rows).
The form's ordinary routes differ:

| Route after admission | UN4 form 73 actions | NA2 form 73 actions |
| --- | --- | --- |
| Ground basic presses, then branch Up / facing / Down / opposite facing | `21 → 22 → 23 →` `24/25/26/27` | `21 → 22 →` `23/24/25/26` |
| Ground Circle hold (`0x00400112`), release (`0x00800112`), outcome follower (`0x08000111`) | `28 → 29 → 30` | none |
| Ground Up opener and continuation | `31 → 32` | `27 → 28` |
| Ground Down opener and continuation | `33 → 34` | `29 → 30` |
| Ground toward-opponent opener and continuation | `35 → 36` | `31 → 32` |
| Ground away throw / outcome follower | `37 / 38` | `33 / 34` |
| Air Up opener and continuations | `39 → 40 → 41` | `35 → 36 → 37` |
| Air Down opener and continuations | `42 → 43 → 44` | `38 → 39 → 40` |
| Air away throw / outcome follower | `45 / 46` | `41 / 42` |
| Air basic presses | `47 → 48 → 49` | `43 → 44 → 45` |

Extra Hit groups are UN4 `0x80`: 25, 30, 36, 46, 49; `0x100`: 24, 41;
`0x200`: 34, 38, 44. NA2 has `0x80`: 24, 42, 45; `0x100`: 23, 37;
`0x200`: 30, 34, 40. The hold route needs the form constructor's
16/12/60 hold parameters; NA2's ID-73 constructor sets none, so native
form 73 produces no hold/release signature. The base ID-57 hold route
(actions 34/35) uses 16/16/30 in both games.

### Ordinary jutsu factories and assets

Configured selectors are not concrete resource IDs or UJ authored skills.
For donor/native IDs 57 and 73, the checked selector and resource numbers
agree while concrete classes or implementations differ.

| Fighter / slot | Selector → resource; provider | UN4 concrete construction | NA2 construction |
| --- | --- | --- | --- |
| Naruto 57 / 0 | 114 → 116; `2nrwcha0` | `naruto_jutsu0_construct 0x007BB340`, `ccSkillNRW000`, allocation `0x1250`, vtable `0x005FA950` | `naruto_jutsu0_construct 0x007DD550`, `ccSkillNRW000`, allocation `0x2830`, vtable `0x005F0E70` |
| Naruto 57 / 1 | 115 → 117; `2nrwcha1` | `naruto_jutsu1_construct 0x007BBD50`, `ccSkillNRW001` derived from `ccSkillNRT001B`, allocation `0x8B0`, vtable `0x005FA710` | `0x007DDE80`, `ccSkillNRW001`, allocation `0x1180`, vtable `0x005F0C20`; enables inherited input byte `+0x1170` |
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
update consumes compact-cue, dialogue and sound tables
`0x0084C790/7B0/7C0`.
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

### Retained NA2 jutsu classes

Each vtable's first word is its RTTI record `{name, base list}`. Class
overrides were found by diffing each class table against its game's
`ccSkill` table (UN4 `0x00604F30`, NA2 `0x005FB4D0`); NA2 tables insert
three slots below donor `+0x1B0`, so matching overrides sit 4..0xC bytes
later. NA2 skill-actor fields are `+0x20` higher in the shared base (the
interface pointer `+0x10`) and `+0x8D0` higher in class storage. In all
four classes each donor class-specific method pairs with one native
method in the matching slot:

| Donor class / native counterpart | Result |
| --- | --- |
| `ccSkillNRW000` / NA2 `ccSkillNRW000` (resource 116) | Same override set. Setup binds the same `ANM_pnrwcha02/03` pair; NA2 `naruto_jutsu0_update` (`0x007DD710`) uses compact-cue, dialogue and sound rows `0x008B1BA0/BC0/BD0` with values equal to donor `0x0084C790/7B0/7C0`. NA2's two embedded owners are `0xB90` bytes, not `0x510`, which accounts for the larger allocation. |
| `ccSkillNRW001` / NA2 `ccSkillNRW001` (resource 117) | Same hierarchy and overrides: destroy, setup (`naruto_jutsu1_setup` / `skill_nrw001_setup`) and body refresh (donor slot `+0x9C`, NA2 `skill_nrw001_refresh_body` slot `+0x24C`, same `OBJ_2nrw00t0 body` material copy). Both `ccSkillNRT001B` updates test resource 149/117 at the same point. NA2's `skill_nrw001_construct` sets added byte `+0x1170`, which enables `skill_shared_float_damage_a`'s button-input route; donor latch bytes `0x8A0..0x8A2` are NA2 `0x1171..0x1173`. Donor's first latch path also requires `reversal_game_active_side() == 0`; NA2's has no such test. |
| `ccSkillNRV001` / NA2 `ccSkillNRV001` (resources 28/113) | Same 19 overrides. `skill_nrv001_select_resource_descriptor` (`0x007D3870`) still selects a resource-149 descriptor (`0x008B0F60`) equal to donor `0x0084C100`: attackers `ANM_pnwvcha11..15`, receiver `ANM_pnwvcha20`, effects `ANM_enwvcha11a/b/c/d`, scale 1.7. Both `bind_resource_descriptor` routines build the emitter from byte-identical descriptors (UN4 `0x00578C90/CD0/CF0`, NA2 `0x005A8CA0/CE0/D00`) and pick particle choice 35 for resource 149; `CMN/PARTICLE.CCS` is identical in both games. NA2 adds resource 171 and a disabled-by-default input byte `+0x1134` in `skill_nrv_family_control_dispatch`. |
| `ccSkillNWV000` / NA2 `ccSkillNWV000` (resource 148) | Different behavior. Setup agrees, but NA2's destroy uses `linked_players_owner_destruct` and `nine_tails_fourth_jutsu0_update` (`0x007EE420`) drives a linked player list at `+0x10B4` and swaps participant facing at frame 35. It has none of the donor update's rows: sounds `97/0x1005, 119/10, 123/13, 169/0x1005`; participant compact cues `15:0, 31:2, 41:1, 50:0, 59:2, 70:3, 119:21, 134:22`; and deferred dialogue indices `87:1, 116:2, 148:3` (`jutsu_defer_participant_dialogue`). |

All four classes build contact records from the resource-indexed
`owner_descriptor_transfer_table` (UN4 `0x00849FE4`, NA2 `0x008AD8E4`),
rows of `{InteractionDefinition array, count}`. Response and alternate
selectors there follow the same two-higher NA2 domain as action records.
After that conversion:

| Resource | UN4 / NA2 definitions | Remaining differences |
| --- | --- | --- |
| 116 | 8 / 8 | Definitions 6/7: attack scalar 0.3 versus 0.2; definition 7 also repeat 5 versus 2 and rejection 1 versus 3. |
| 117 | 1 / 1 | None. |
| 148 | 8 / 4 | Donor rows equal resource 116's donor rows except guard 4 in row 0 and alternate 0 instead of 4 in rows 1/2/4. Native rows 1..3 use flags `0x4C005`, alternate 37, knockback 1.1, relation mask 2, attack 1.0/1.0/1.1, repeat 20/25/30, pause/rejection `0x7FFF`. |
| 149 | 1 / 1 | Donor row equals resource 117's except alternate 0 instead of 4; native row equals native resource 148 row 1. |

Animation command blocks `0x0108` in the four donor jutsu files queue
`0x8003` values: `0x100 + resource` at frame 1 of each main animation
(`0x174/0x175/0x194/0x195` for resources 116/117/148/149), and actor
events 2/3/10 in `pnrwcha01` and 3/5/10 in `pnwvcha01`. NA2's same-named
files use the same resource encoding; its `pnwvcha01` instead queues
events 0..3. Both bodies have no `0x0108` blocks.

### Indexed services and related owners

UN4 `battle_ai_update` reads `naruto_ai_character_values
0x00853CC4` and `naruto_second_stage_ai_character_values 0x00853D04`:
both `{2,20}`. Native corresponding rows `0x008C3544/0x008C3584`
also contain `{2,20}`. Both games' fighter slot `+0x1C` for IDs 57/73
only calls the AI tick when mode bits `(+0x60 & 0x1FF) >> 5` are nonzero.
UN4 `ai_character_flags` (`0x008538D0 + ID`) and NA2
`ai_character_descriptors` (`0x008C3050 + ID*4`, flag byte `+2`, halfword
`0x001F`) hold flags `0x01` for both IDs in both games. The AI reaction
ID exceptions recorded in
[Orochimaru AI services](orochimaru.md#un4-orochimaru-and-na2-orochimaru-ai-services)
(targets 49/34, 59/64, 36) do not name 57 or 73; the two games' AI
profile layouts differ as recorded there.

UN4 roster rows are `{57, category 0, row 0}` at `0x005825B0` and
`{73, category 2, row 0}` at `0x00582630`. NA2 `jutsu_native_owner`
admits a selector only when its numeric owner and its action owner equal
the fighter; the donor's packed words `0x00720039/0x00730039` (57) and
`0x00920049/0x00930049` (73) equal NA2's, so they pass for those IDs.

NA2's support relationships for fighter 57, from complete scans of each
table, are:

| NA2 service | Fighter 57 entries |
| --- | --- |
| `support_candidate_rows` (`0x008D2690`) | Recommendations support `0x01` (Sasuke 58), `0x02` (Kakashi 70), `0x18` (Jiraiya 83) |
| `support_exclusion_rows` (`0x008D1980`) | Supports `0x00` (Naruto) and `0x17` excluded |
| `support_code_rows` (`0x008D1A50`) | Support `0x02` → code 6; support `0x1F` → code `0x3F` |
| `support_recharge_rows` (`0x008D1BB0`) | 30 exact rows: 10 class 0, 15 class 3, 5 class 4 |
| `support_linked_jutsu_rows` (`0x008D2880`) | Support `0x08` (Gaara 59) replaces selector 114 with `0x3B`; support `0x20` (Sai 92) replaces 114 with `0x3E` |
| `support_cinematic_admission_table` (`0x008D2660`) | Support `0x01` with fighter 57 → linked UJ skill `0x4F` (`D57_50`); Naruto as support `0x00` with fighter 58 → `0x54` |

Candidates and exclusions normalize fighter 73 to 57 through
`character_to_base`; the linked-jutsu and linked-UJ scans compare the raw
fighter ID, so they apply to 57 only.

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

This comparison checks UN4 Naruto ID 57 and his Second Stage ID 73
against retail NA2 Naruto ID 57 and Fourth Awakened ID 73. Array and
class roots are in [Character assets](#records-moves-and-assets).
The following addresses are live UN4 resident addresses.

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
event interval. In major 8, with payload flag 2, `fighter_timer_hold_gate`
not 1 and no exchange role `0xFF00`, action `0x1B` takes the `+0x6118`
controller inside interval `0x00607640` and `+0x6138` outside it. Each
bank not yet `fighter_attack_bank_registered` goes to
`fighter_register_attack_window` with that controller, the fighter's
animation result and secondary timeline. NA2's native form uses the same
two common helpers from `fighter_alternate_scene_attack_pass`
(`0x002D0050`), with its own actions and players.

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

The selected donor is UN4 Naruto ID 57 / Second Stage ID 73. The
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
`#e\0x\tex\sampling00.bmp / TEX_sampling00`. It resolves to
`CMN/EFFECT0X.CCS` row 2797 (NA2 row 2615): a typed `0x0300` texture
with flags `0x21` and no pixels, built as a sampling texture as described
in [Locally filled external-marker rows](../../../game/files/asset_dependencies.md#locally-filled-external-marker-rows).
NA2's `D57_30E` is byte-identical to the donor's, and NA2's own `D57_20E`
marks the same key.

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

`MDL_2kyw00t0 body`, record 5938, has model flags `0x0004`, so
`ccs_parse_model` reads it as packed subtype 2 (`(flags >> 1) & 7`), not
as the shadow subtype 4 read by `ccs_read_shadow_volume_part`. It has 17
parts and 27 bone-map bytes; every part selects `MAT_kywbod1` (5939) →
`TEX_2kywbody` (5940) → `CLT_2kywbody` (6100). Scene
`OBJ_2kyw00t0 body` (68) places it under local node 8. All 641 `kyw`
rows of `2NWVBOD1` have local typed blocks, so the chain is local.
`ANM_pnwvarm1/2`, the common composition and the three particle
definitions have direct constructor/update consumers in
[Naruto callbacks](#second-stage-auxiliary-ownership).
The jutsu files' animation commands and the form Rasengan's code-selected
descriptor, emitter and particle choice are in
[Retained NA2 jutsu classes](#retained-na2-jutsu-classes). Request
ownership is in [Naruto cinematics](#cinematics).

## Ultimate Jutsu and effects

**Checked identities:** UN4 Naruto ID 57 (`nrw`) / Second Stage ID 73
(`nwv`), versus retail NA2 Naruto ID 57 / Fourth Awakened ID 73.
UN4 `naruto_ultimate_jutsu_list 0x00607DA0` contains records
110/111 and defaults to 110. Its form list
`naruto_second_stage_ultimate_jutsu_list 0x00607E18` contains record
153 and defaults to 0. NA2 ID 57 likewise lists 110/111; ID 73's
list at `0x006044B0` contains record 165 and defaults to 0
(`0x005AFE42`). Default 0 does not replace the matched category-1 row.

UN4 metadata uses the own locale-selected `0x10`-byte format;
NA2 uses resident `0x14`-byte records. All six rows have contest
class 3; native secondary-intro values are -1.

| Exact row / live address | Authored skill | Category / cost tier | Intro | Post-effect | Damage percent |
| --- | --- | --- | --- | --- | --- |
| UN4 Naruto 110 / `0x008701F0` | `0x5A` | 2 / 0 | `0x54` | -1 | 25 |
| UN4 Naruto 111 / `0x00870200` | `0x59` | 3 / 1 | `0x53` | `0x64` | 20 |
| UN4 Second Stage 153 / `0x008704A0` | `0x5B` | 1 / 1 | `0x55` | -1 | 35 |
| NA2 Naruto 110 / `0x005AF4D8` | `0x4B` | 2 / 0 | `0x5B` | -1 | 25 |
| NA2 Naruto 111 / `0x005AF4EC` | `0x4C` | 3 / 1 | `0x5C` | `0x72` | 20 |
| NA2 Fourth Awakened 165 / `0x005AF924` | `0x4E` | 1 / 1 | `0x90` | -1 | 35 |

Own-game UN4 `jutsu_slots_rewrite 0x0022E8C0` selects tier 2 when
the fighter's marker bit `+0x63 & 0x20` is set, otherwise tier 1
at HP `+0x6C <= 0.5`, otherwise tier 0. These tiers request categories
1/3/2, respectively, after the separate side tier remap. With the
identity remap, Naruto's unmarked low-HP record is 111,
and his ordinary record is 110; a missing requested category returns
the character's default. The exact decoded SINF titles for skills
`0x59/0x5A/0x5B` are `多影撃連弾`, `特大螺旋丸` and
`抑えきれない力`. `english_text_static_initialize` (`TEXTENG.BIN
0x00899480`) installs record `+0x00` display pointers: 110 **Grand
Rasengan** (`0x00874328`), 111 **Multiple Shadow Barrage**
(`0x00874310`) and 153 **Uncontrollable Power** (`0x00874340`). The
`TEXTFRN.BIN` initializer at `0x0089A380` installs `Super Rasengan`,
`Barrage Multiple Ombre` and `Puiss. Incontrôlable`. NA2's direct
record-name pointers give `大玉螺旋丸` (110), `漏れ出す力` (111) and
`妖狐の衣` (165).

The Naruto low-HP record plays authored skill `0x59`; it is distinct
from authored skill 1's seven-character reversal route. The complete
UN4 `reversal_definition_table` has IDs 50/16/19/21/25/9/7,
not Naruto 57/73. The [UN4 reversal contract](ultimate_jutsu.md)
owns that system route. Calling Naruto's low-HP record “reversal” does
not put him in that minigame table or remove his cinematic request.

UN4 `jutsu_record_form_character 0x003CCD00` maps effect
`0x64` to ID 73; NA2 `jutsu_record_form 0x00372D00` maps
`0x72` to ID 73. Both own-game forward/inverse identity helpers
join 57 ↔ 73, but the concrete form classes and moves differ.
UN4 `naruto_awakening_flags 0x00592329` is 1, its presentation
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

This checks UN4 Naruto 57 / Second Stage 73 against retail NA2
Naruto 57 / Fourth Awakened 73. Metadata selection is owned by
[Naruto awakening](#ultimate-jutsu-and-effects);
the shared UN4 route by [UN4 Ultimate Jutsu](ultimate_jutsu.md).
The own-game SINF relocators establish the `0x14` donor and `0x18`
native request-row representations. The decoded selected requests are:

| Game / authored skill | Decoded donor title | Resident main | Ordered extra residents | Stream |
| --- | --- | --- | --- | --- |
| UN4 `0x59` | `多影撃連弾` | `STR/D57_10E.CCS` | `PL/2NRWBOD1.CCS`, `PL/1NWVBOD1.CCS` | `STR/D57_10.CCS` |
| UN4 `0x5A` | `特大螺旋丸` | `STR/D57_20E.CCS` | `PL/2NRWBOD1.CCS` | `STR/D57_20.CCS` |
| UN4 `0x5B` | `抑えきれない力` | `STR/D57_30E.CCS` | `PL/1NRWBOD1.CCS` | `STR/D57_30.CCS` |
| NA2 `0x4B` | — | `STR/D57_20E.CCS` | `PL/2NRWBOD1.CCS` | `STR/D57_20.CCS` |
| NA2 `0x4C` | — | `STR/D57_25E.CCS` | none | `STR/D57_25.CCS` |
| NA2 `0x4E` | — | `STR/D57_35E.CCS` | `PL/2NWVBOD1.CCS` | `STR/D57_35.CCS` |

Every row requests one stream. The table records authored SINF titles;
the English menu labels are joined in
[Naruto awakening](#ultimate-jutsu-and-effects). Reusing `nrw/nwv`
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
Skill `0x5B` explicitly adds `1NRWBOD1`, but no marked `D57_30` key
needs it. Its `1NWVBOD1` keys resolve to the attacker side's presentation
body: `battle_queue_fighter_ccs` (`0x00316140`) loads
`character_presentation_body_filenames` (`0x0057A2E0`) entry
`1nwvbod1.ccs` for the side's current character under resource-mask bit 1.
Skill `0x59` plays while the side is ID 57 and requests `1NWVBOD1`
explicitly. NA2's `1NWVBOD1` lacks the 55 `OBJ_1kyw00t0*`
keys these films use.

The separate donor Classic Naruto skills 2/3/4 select
`D01_10E/D01_10`, `D01_20E/D01_20`, `D01_30E/D01_30`.
Their extras are `2NRTBOD1`, `2NRTBOD1 + 6NRVBOD1` and
`6NRVBOD1`, respectively. These are not Part II Naruto's requests.

### Naruto film payloads and appearance

The three donor streams contain no queued `0x0108` commands; their frame
blocks target local names and participant wrappers. Per-skill resident data:

| Data | `0x59` | `0x5A` | `0x5B` |
| --- | --- | --- | --- |
| `sp_skill_palette_substitution_descriptors` rows (container, target, palette) | `2nrwbod1` `EXT_2nrw00t0 body` and `EXT_2nrw01t0 body`, `1nwvbod1` `EXT_1nwv00t0 body`; all `CLT_*bodyc1` | `2nrwbod1` `EXT_2nrw00t0 body/body01/body02/body03`, `CLT_2nrwbodyc1` | `1nwvbod1` `EXT_1nwv00t0 body`, `CLT_1nwvbodyc1` |
| `sp_skill_frame_scripts` | none | none | none |
| `sp_skill_defender_body_draw_allowed` gate (`0x00578EB0`) | none | frames 120..415, default defenders | none |
| `BIN_damoffs` phases (thresholds) / defenders | 3 (1, 23, 195) / 78 | 6 (1, 24, 89, 120, 157, 239) / 78 | 2 (1, 244) / 78 |

The damage-offset tables cover UN4 defender IDs 0..77. NA2's same-path
`D57_20` stream equals the donor's in every typed object except
`BIN_damoffs_d57_20`: NA2's has the same thresholds, 94 defenders, and
equal rows for IDs 0..56 and 74. `D57_20E` differs: the donor has 66
typed objects NA2 lacks (`e57moj01*`, `e57pl01*` families) and NA2 has ten the
donor lacks (`e00board01*`, `TEX_e57smp01`, `TEX/CLT_e00white01`). NA2
skill `0x4B` uses the same request paths, the same four appearance rows
with base palette name `CLT_2nrwbody` (NA2's helper does not trim the
`c1` suffix; see [palette rows](ultimate_jutsu.md#resident-palette-rows-and-appearance-flags)),
and the same 120..415 draw gate.

NA2's SINF table also keeps the donor's other two requests. Row `0x4A`
requests `D57_10E` with `2NRWBOD1` and `1NWVBOD1` and stream `D57_10`;
row `0x4D` requests `D57_30E` with `1NRWBOD1` and stream `D57_30`. Their
hit rows, `naruto_shadow_barrage_hit_rows` (`0x005CC960`) and
`naruto_uncontrollable_power_hit_rows` (`0x005CCAC0`), equal the donor's
`0x59`/`0x5B` rows; neither has a frame script or draw gate. No record in
the scanned resident UJ table (rows 0..259) selects either skill. Row
`0x4D` has the donor's one appearance row; row `0x4A` has the donor's
three `EXT` rows plus eight material rows the donor lacks:
`CLT_e57nrwpz` on `MAT_e57nrwpz_a/b/c/d`, `CLT_e57ndody` on
`MAT_e57lnrw01/02` and `CLT_e57bnrw01` on `MAT_e57bnrw01/02`. Both
games' `D57_10E` contain those materials and their `c1/c2` palettes.
NA2's `D57_30/D57_30E` are byte-identical to the donor's; its `D57_10`
pair differs.

## Voice

The exact comparison is UN4 Naruto ID 57 / Second Stage ID 73 against
retail NA2 Naruto ID 57 / Fourth Awakened ID 73. Compact bank identity
and the separate Classic Naruto pair are owned by
[Character assets](#records-moves-and-assets).
The generic synthesizer decoder is owned by
[Compact program-to-VAG lookup](../../session/battle_audio.md#compact-program-to-vag-lookup).

UN4 `voice_event_pointer_pairs` gives ID 57 the base/alternate lists
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
| UN4 low HP `0x59` | 27 / `naruto_low_hp_ultimate_hit_rows 0x005CADC0` | 24:14, 46:12, 220:18 |
| UN4 normal `0x5A` | 11 / `naruto_grand_rasengan_hit_rows 0x005CAEA0` | 27:13, 159:15, 244:18 |
| UN4 Second Stage `0x5B` | 67 / `naruto_second_stage_ultimate_hit_rows 0x005CAF00` | 119:13, 315:18 |
| NA2 low HP `0x4C` | 4 / `naruto_low_hp_ultimate_hit_rows 0x005CCAA0` | 238:16, 283:12, 302:14, 315:18 |
| NA2 normal `0x4B` | 11 / `naruto_grand_rasengan_hit_rows 0x005CCA40` | 27:13, 159:15, 244:18 |
| NA2 Fourth Awakened `0x4E` | 111 / `nine_tails_fourth_ultimate_hit_rows 0x005CCCE0` | 127:16, 227:12, 300:17, 427:18 |

All remaining cues are -1. UN4 low-HP weights are 1024 at 24, zero at
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

UN4 `audio_request_cinematic_cue 0x001D7360` uses the participant's
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

These are the stored sample selections. Manager mode 6 uses a separate
cue route.

### Streamed archive members

UN4 `audio_request_archive_member 0x001DA180` bounds a requested
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

### Ultimate Jutsu intros

`jutsu_presentation_update` requests the record's intro selector as a
SOUND member through the same bank-9 route as
[Orochimaru's intros](orochimaru.md#selected-ultimate-jutsu-intros-and-compact-frame-cues):
UN4 SOUND outer 9 (272 members at `0x15668800`, Japanese +136), NA2 SOUND
outer 7 (189 members at `0x08226000`). Offsets are absolute clean-file
offsets in `SOUND.AFS`.

| Record / intro | UN4 English member / offset / bytes | UN4 Japanese member / offset / bytes | NA2 record / member / offset / bytes |
| --- | --- | --- | --- |
| 110 / `0x54` | 84 `strST_084.ahx` / `0x157FD800` / 12,145 | 220 / `0x15A4C800` / 9,221 | 110 / 91 / `0x08352000` / 10,879 |
| 111 / `0x53` | 83 `strST_083.ahx` / `0x157FA000` / 14,027 | 219 / `0x15A48800` / 15,132 | 111 / 92 / `0x08355000` / 13,966 |
| 153 / `0x55` | 85 `strST_085.ahx` / `0x15800800` / 11,308 | 221 / `0x15A4F000` / 10,511 | 165 / 144 / `0x08443000` / 14,847 |

### Ordinary-jutsu dialogue

`audio_queue_player_voice` finds a cue in the actual fighter's streamed
cue list and queues its ordinal; English uses the ordinal and Japanese adds
half the descriptor's count. UN4 Naruto 57's list (`0x004352D0`) is
`256,257,258,259,260,265,289,293,298,299,302,312`, descriptor
`0x004363A0` (handle 177, count 24), PLVOICE outer 56 at `0x0090F000`.
Second Stage's list (`0x00435490`) is
`265,289,293,298,299,302,312,319..326`, descriptor `0x00436420`
(handle 193, count 30), outer 72 at `0x00CEE000`. NA2 57's list
(`0x003FED10`) has 48 cues including `256..260`, descriptor handle 206,
count 48, without a language half; NA2 73's is `325,326,327,328`,
handle 222, count 4.

Rows of `dialogue_voice_rows` (UN4 `0x00859FF0`, NA2 `0x008CB760`):

| Resource | UN4 row | NA2 row | UN4 producers |
| --- | --- | --- | --- |
| 116 | `-1,256,257,-1` | same | `naruto_jutsu0_update` deferred dialogue: frame 99 index 2 → 257, frame 125 index 1 → 256 |
| 117 | `258,-1,259,260` | `260,-1,258,-1` | `skill_nrt001b_update` index 2 (two states) → 259; `skill_nrt001b_contact_update` index 3 → 260 |
| 148 | `319,320,321,322` | `325,326,-1,-1` | `naruto_second_stage_jutsu0_update` deferred dialogue: frames 87/116/148 indices 1/2/3 → 320/321/322 |
| 149 | `324,-1,325,326` | `327,328,-1,-1` | `jutsu_nrv001_update` state 5 and `jutsu_nrv001_set_phase`, index 2 → 325 |

The four resources' frame rows at `0x0085A5B0 + resource*8` are all
`-1`, so cues 258, 319, 324 and 326 have no producer on these paths.
The produced cues select these PLVOICE clips:

| Cue | English member / offset / bytes | Japanese member / offset / bytes |
| --- | --- | --- |
| 256 | 56:0 / `0x0090F800` / 5,539 | 56:12 / `0x00937000` / 5,453 |
| 257 | 56:1 / `0x00911000` / 4,710 | 56:13 / `0x00938800` / 4,495 |
| 259 | 56:3 / `0x00915000` / 17,944 | 56:15 / `0x0093C000` / 17,726 |
| 260 | 56:4 / `0x00919800` / 15,973 | 56:16 / `0x00940800` / 14,630 |
| 320 | 72:8 / `0x00D0B000` / 13,054 | 72:23 / `0x00D37800` / 9,456 |
| 321 | 72:9 / `0x00D0E800` / 7,147 | 72:24 / `0x00D3A000` / 7,287 |
| 322 | 72:10 / `0x00D10800` / 6,714 | 72:25 / `0x00D3C000` / 5,374 |
| 325 | 72:13 / `0x00D17000` / 11,577 | 72:28 / `0x00D41800` / 10,447 |

### Compact jutsu and event cues

`jutsu_request_participant_compact_cue` indexes the participant's row
from `jutsu_participant_compact_cue_row` (pairs at `0x00845390`, ID−1)
and sends the selector to `battle_voice_control_by_object`, whose
`battle_voice_controls` row gives program and default key. Naruto 57 uses
row `0x0085A4F0` (selectors 0..24); Second Stage uses `0x0085A550`
(selectors from 160). Controls 0..40 use key 60 and 160..201 key 62 with
the same program numbers. Both forms share ID 57's bank. Sample offsets
are absolute clean-file offsets in each game's `SNDDATA.BIN`, found with
the [compact lookup](../../session/battle_audio.md#compact-program-to-vag-lookup):

| Producer | Frame : index → control → program / key | UN4 English Vagi / offset | UN4 Japanese offset |
| --- | --- | --- | --- |
| `naruto_jutsu0_update` | 46:0 → 0 → 0/60; 57:2 → 2 → 2/60; 66:1 → 1 → 1/60 | 33 `0x00FCAAC0`; 35 `0x00FCCA60`; 34 `0x00FCBBA0` | `0x022A5F20`; `0x022A7350`; `0x022A67D0` |
| `naruto_second_stage_jutsu0_update` | 15:0, 50:0 → 160 → 0/62; 31:2, 59:2 → 162 → 2/62; 41:1 → 161 → 1/62; 70:3 → 163 → 3/62; 119:21 → 182 → 22/62; 134:22 → 183 → 23/62 | 3 `0x00F87970`; 5 `0x00F89B40`; 4 `0x00F88820`; 6 `0x00F8B070`; 26 `0x00FBB920`; 27 `0x00FBC8E0` | `0x0226F330`; `0x02271120`; `0x02270430`; `0x02271CE0`; `0x02299530`; `0x0229A3B0` |

`skill_nrt001b_update` and `jutsu_nrv001_update` request compact index
31 only for other resources; resources 117 and 149 take the dialogue branch instead.
The fighter event lists `0x00591DD0` (base) and `0x00591E70` (alternate)
hold 40 selectors each. Every positive-program base selector (programs
0..8, 12..26, 36..40, key 60) and alternate selector (same programs,
key 62, plus program 27) resolves to exactly one donor sample in each
language. Controls 27/41 and 201 have negative programs and emit
nothing; program 28 is a hole in the bank. Event 25 is silent in the
base list and plays program 27 key 62 in the alternate list. NA2 57's bank
resolves the same key-60 programs to its own samples, maps several key-62
programs to shared samples (programs 0..2 all to Vagi 1), and has no
program 27.
