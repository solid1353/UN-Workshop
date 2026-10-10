# Itachi: NUN3 donor

## Research coverage

Established for NUN3 Itachi 23 against NA2 Itachi 71: equal action counts with
different rows, names, chains, callbacks and ordinary-jutsu classes; twenty
Ultimate Jutsu records selecting five films; effect `0x24` against NA2's `0x4A`;
marked typed providers and the four muffler definitions NA2 lacks; compact
programs, sparse streamed banks and five SOUND intros.
Open: input and contact semantics, the Clone Explosion and Haze actors, film
conversion, typed descendants, effect admission, ID-dependent services and
remaining voice mapping.

Names come from `@annotations/NUN3` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [NUN3 and NUN4 characters](../nun3_nun4_characters.md).

## Records, moves and assets

Checked identities are **NUN3 Itachi, ID 23 (`0x17`, `itc`)**, in
`SLUS_217.27/BATTLE.BIN`, and **retail NA2 Itachi Uchiha, ID 71
(`0x47`, `itw`)**, in `SLPS_258.37/BTL.BIN`. NA2 ID 23 is a filler
Naruto definition with null file families; it is not the same-name fighter.

| Root | NUN3 ID 23 | NA2 ID 71 |
| --- | --- | --- |
| Definition entry | `itachi_character_definition 0x004767E8`, factory/descriptor `{001FFB10,003F2820}` | `0x005A2B38`, `{002C8E70,0052B120}` |
| Character record / descriptor | `itachi_character_record 0x003F2820` / `0x003F2900` | `itachi_character_record 0x0052B120` / `0x0052B200` |
| Factory / allocation | `itachi_create 0x001FFB10`, `0x5510` bytes | `fighter_id_071_create 0x002C8E70`, `0x5710` bytes |
| Constructor / vtable | `itachi_construct 0x001FFB60` / `itachi_vtable 0x00689290` | `fighter_id_071_construct 0x002C8EC0` / `0x005DA600` |
| Actions | 47 at `itachi_authored_actions 0x003F18B0` | 47 at `0x0052A1A0` |
| Animation rows | 179 at `itachi_authored_rows 0x003EE380` | 183 at `0x00526960` |
| Animation-name pointers | 158 at `itachi_animation_names 0x003EE100` | 154 at `0x00526670` |

The raw record parameter bytes `+0x58..+0xDB` agree. The donor constructor
publishes working names/actions/rows at fighter `+0xE00/+0x1078/+0x1FE4`,
loads its record and binds borrowed dash material/palette caches.
Native construction also allocates an owned `0x120`-byte compound player,
binds `ANM_eitwsrn`, composes it and clears its private halfword.
`fighter_id_071_destroy` (`0x002C9030`) destroys that player before common
cleanup; `itachi_destroy` (`0x001FFC30`) has no corresponding owned player.
Both clear their borrowed dash caches, run base destruction and free the
complete fighter only for a positive signed deletion flag.

`itachi_update_tsukuyomi_player` (`0x002C9120`) advances that native player
only with effect `0x4A`, places it at fighter position plus 70 on Z, chooses
a scalar around distance 400, and edits `EFF_eitwring0` properties.
`itachi_draw_tsukuyomi_player` (`0x002C92D0`) scopes the effect renderer and
submits it under the effect/presentation gate. The corresponding donor
virtuals `itachi_virtual_noop_a/b` (`0x001FFD00/10`) are `jr ra; nop`.
The factories are therefore not interchangeable even though the stored
parameter suffix agrees.

### Itachi authored move correspondence

Both games use `0x54`-byte authored actions and `0x4C`-byte animation rows.
The following comparison walks every action's row chain to the signed
animation-slot `-1` sentinel. Names below omit `ANM_pitc` or `ANM_pitw`;
the common `ANM_pcmnjmp2` remains common. Values in parentheses are stored
signed duration halfwords, not inferred visible durations.

| Donor action(s) | Native action(s) | Checked sequence correspondence or difference |
| --- | --- | --- |
| 0 | 0 | Donor empty-name slot 70; native `chb00,chb02` |
| 1 | 1 | `cha00` in both; different jutsu title/resource |
| 2 | 2 | Donor `chb10,chb11(6),chb12`; native empty-name slot 74 |
| 3 | 3 | `cha10` in both; different jutsu title/resource |
| 4..6 | 4..6 | `rdy1,spl00/10/20,spl02/12/22` respectively |
| 7..9 | 7..9 | `nxs0,sig0(16),sig0(8),sxn0` |
| 10..18 | 10..18 | `jmp1`, paired `kca40/60,kna30,pna20,kna50/40/20,kca70/50`, then `lan0`; suffixes and signed durations agree |
| 19 | 19 | Common `jmp2`, then `jmp1,dow1,jpz1,jpz0`, all duration 0 |
| — | 20 | Common `jmp2(0),kna20(-16),kna20(4),kna22(-17),lan0(-16),ost0(-16)` |
| 20..25 | 21..26 | `pnc00/02,elb00/02,kcn00/02,kni00/02,pnc10/12,kcn30/32` respectively |
| 26 | 27 | Donor `kbs20/21/22/23`; native `kbs20/22` |
| 27..30 | 28..31 | `kcn20/22,kbs00/02,kni20/22,kbs10/12` respectively |
| 31 | 32 | Donor `kni10/12`; native inserts `kni10(10)` before the retained pair |
| 32 | 33 | Donor `kcn10/11`; native `kcn10(-16),kcn10(4),kcn12(-16)` |
| 33 | — | Donor continuation `kcn12/13` has no corresponding native authored sequence |
| 34..35 | 34..35 | `hol00/01` and `hol02/03` |
| 36..38 | 36..38 | `kca10(3),kca10(-16),kca12(-17)`; `kca20/22`; `kna00/02` |
| 39 | 39 | `kca30(6),kca30(1),kca30(12),kca32(-17)` |
| 40..42 | 40..42 | `pna10/12,kna10/12,hla00/01` respectively |
| 43 | 43 | `hla02(-17),hla03(1),nxj0(6),jmp3(-18)` |
| 44..46 | 44..46 | `pna00(-16),pna00(2),pna02(-17)`; `ela00/02`; `kca00/02` |

All unmarked duration pairs in corresponding rows agree. Matching suffixes
and durations establish authored sequence correspondence, not identical
animation payloads, movement, contact windows or physical-input admission.
The callbacks also consume different action indices, as recorded in
[Itachi callbacks](#callbacks).

### Itachi ordinary jutsu and resources

Donor action 1's resident title (`0x004F80C0`) is **Clone Jutsu: Super
Explosion**, and action 3's (`0x004F8100`) is **Shadow Clone: Haze**.
Native titles at `0x00529FC0/0x00529FF0`, with ruby markup removed, are
`幻術 不知火` and `火遁・豪火球の術`. Their English descriptions are
Genjutsu: Shiranui and Fire Style: Fireball Jutsu; those translations do not
replace the checked Japanese strings.

| Domain | NUN3 ID 23 | NA2 ID 71 |
| --- | --- | --- |
| Fighter selectors | 46/47 | 142/143 |
| Executable resource IDs | 49/50, map pair `BATTLE 0x0093E8B8` | 144/145 |
| Resident filename rows | `0x00476400/0C`: `2itccha0.ccs/2itccha1.ccs`, metadata `{1,0}` | `2itwcha0.ccs/2itwcha1.ccs` |
| Factory switch cases | `itachi_clone_explosion_factory_case 0x0086D180`; `itachi_haze_factory_case 0x0086D258` | `0x00774B18`; `0x00775290`, through `BTL 0x008CD430/34` |
| Allocation / final interface | `0x970 / 0x0068DBC0`; `0xBC0 / 0x00699D00` | `0x11D0 / 0x005EF350`; `0x1000 / 0x005E7080` |

MCP does not recognize these inline allocator arms as separate functions;
their switch targets and MIPS instruction bytes establish the allocation,
calls and interface stores. Resource 49 calls common construction
`0x0087B720`, secondary-base construction `0x00903330`, then
`itachi_clone_explosion_clear/setup` (`0x0090A620/6D0`).
`itachi_clone_explosion_bind` (`0x0090A730`) allocates an owned `0xA0`
helper at actor `+0x854` and binds `CMP_2itcdash`. Its actual-ID `0x17`
branch borrows the selected fighter's body/palette; a foreign source uses
CHA0 and `CLT_2itcdashc3`. This is an executable identity dependency.

`itachi_clone_explosion_update` (`0x0090BA00`) has startup, clone-animation
wait, approach, attack and finish phases. The attack path
`itachi_clone_explosion_attack_update` (`0x0090AF30`) owns fade, raycast
and hit-count progression. `itachi_clone_explosion_contact`
(`0x0090C070`) increments actor `+0x850`; it sets response `+0x2C=0x12`
and factor `+0x28=0.35`, then changes the final hit to `0x0E`,
`+0x32=0x7FFF` and factor 1 before shared submission.
`itachi_clone_explosion_contact_dispatch` (`0x0090BD00`) uses per-side
descriptors at `0x00949D40`, stride `0x68`; finish sets clone `+0xAB0=100`
and invokes cleanup virtual `+0x22C`.
`itachi_clone_explosion_draw` (`0x0090BB10`) saves/restores borrowed fighter
model state and scopes the renderer.

`itachi_haze_jutsu_construct` (`0x008AF390`) uses the shared fanged-pursuit
base, embeds a helper at `+0x730`, and publishes command-table pointers
`0x00941FE0/0x00942000/0x00942020` at `+0x41C/+0x420/+0x424`.
`itachi_haze_jutsu_position` (`0x008AF400`) reads `OBJ_2cmn00t0` or a
stored position fallback. `itachi_haze_jutsu_update` (`0x008AF510`)
advances the helper and dispatches commands `0x2D/0x51/0x6E` to states
1/2/3; command `0x51` requests dialogue or a common cue 6..8.
`itachi_haze_jutsu_draw` (`0x008AF740`) scopes the renderer and submits
the embedded actor. Full inherited state, collision, interruption and
destruction descendants remain open.

Native resource 144's `skill_itw000_construct` (`0x007E5770`) instead uses
`skill_tyo_base_construct`, installs `0x005EF350`, constructs a private
helper at `+0x1110`, and initializes vectors/fields through `+0x11CC`.
Resource 145 uses `skill_primary_construct` (`0x00785410`), installs
`0x005E7080`, and clears three private words at `+0xFF0` through
`0x00848510`. These are different actor/layout roots, not donor classes
retained under new numbers.

Donor AI uses `itachi_ai_descriptor` (`BATTLE 0x0093AEA8`), uint pair
`{2,5}`. Its own `ai_tick` (`0x00825260`) indexes
`ai_character_descriptors 0x0093ADF0` by actual fighter ID at `+0x64`
with eight-byte stride, then copies both words into per-side state.
Native `ai_tick` (`BTL 0x00704D40`) indexes
`ai_character_values 0x008C3460` by actual ID with four-byte stride;
`itachi_ai_character_values` (`0x008C357C`) has signed halfwords
`{region_value 2,alternate_target_threshold 20}`. The native consumer and
threshold semantics are owned by [Battle AI](../../session/battle_ai.md#per-side-state-block).
Native initialization and reaction routines independently consume the
[character descriptor's flags byte](../../session/battle_ai.md#character-descriptors-and-hard-coded-exceptions).
The fighter AI virtuals retain their control-word gate but call their own
overlay dispatchers. These entries do not establish complete decision
equivalence. Remaining availability, support, input admission and indirect
identity-specific branches are unestablished.

Typed CCS relationships belong to
[Itachi providers](#typed-providers);
selected Ultimate Jutsu and effects to
[Itachi UJ comparison](#ultimate-jutsu-and-effects);
voice to [Itachi audio](#voice).

## Callbacks

Checked donor is NUN3 Itachi **ID 23 (`itc`)**; native comparison is
retail NA2 Itachi Uchiha **ID 71 (`itw`)**. Their record, action and
allocation roots are in
[Character assets](#records-moves-and-assets).
The callback tables are:

| Slot | Donor `itachi_character_callbacks 0x003EE0E0` | Native `itachi_character_callbacks 0x00525F50` |
| --- | --- | --- |
| 0 | null | null |
| 1, channel 2 | `itachi_channel2 0x001FFD20` | `itachi_channel2_noop 0x002CA780` |
| 2, channel 3 | `itachi_channel3 0x001FFEA0` | `0x002CA790` |
| 3, source-selected hit response | `itachi_hit_response 0x00200A80` | `itachi_hit_response 0x002CB950` |
| 4, channel 5 | `itachi_channel5 0x00201F50` | `0x002CBBC0` |
| 5..6 | null | null |

Slot 3 is the hit-response service, not a dispatched channel-4 callback.
Native slot 1's raw bytes are `jr ra; nop`; MCP does not recognize it
as a function. Donor channel 2 has phase-dependent behavior: phase 1
uses a modulo-10 gate, sets fighter `+0xAB0` to 80 or a random value
plus 10, and on the zero remainder emits positional event `0x0F` and
translucency feedback. Phase 0 at marker 7 requests SFX `0x0F`.

Donor channel 3 handles local actions `4/5/6`, `0x15/18/19/1A/1C/1E/1F/20`
and `0x29/2B`. It owns marker-gated feedback, response/motion writes
and transient particles, using `OBJ_2itc00t0` and `OBJ_2cmn00t0`.
Actions 4/5/6 at phase 1 request compact events 6/7/8 at markers 5/10/6.
Native channel 3 has its own action numbering and effect-`0x4A` branches;
it cannot be substituted for the donor's callback by pointer translation.
The complete per-branch native comparison remains open.

The complete static donor hit-response return set is
`{-1,0x29,0x2B,0x2C,0x2E,0x30,0x32,0x33,0x36,0x3A,0x3E}`;
native's is `{-1,0x2A,0x2C,0x30,0x3C,0x40}`.
Donor mode 2 can write receiver scale fields
`+0x8F0/+0x8F8/+0x8FC`; action `0x1A` also changes the active
response/guard-SFX path. These are game-local response destinations,
not equivalent numeric action IDs across the two games.

Donor channel 5 requires byte `+0` bit 1 and byte `+0x61` bit 5 before
calling `itachi_update_dash_effect` (`0x00201B10`). Native's channel 5
uses the same entry gates, then its own updater `0x002CA310`.
The donor updater calls `itachi_update_dash_transform` (`0x00201090`),
whose ten private floats at `+0x9AC..+0x9D0` track dash transforms.
Its action/phase markers update the body/dash objects; it restores the
shared scratch-arena cursor before returning.

`itachi_bind_dash_material` (`0x00200E60`) looks up `MAT_2itcdash`
and four palette names `CLT_2itcdash/c1/c2/c3` in fighter body `+0xD84`,
publishing five borrowed caches at `0x003F2A10..0x003F2A24`.
`itachi_clear_dash_material` (`0x00200F20`) zeros those caches without
freeing their provider. The update's actual-ID `0x17` branch chooses
colour 0..2; foreign source identities choose palette c3. Native binder
`0x002C9370` uses body `+0xE64` and retains all four palette-name strings
at `0x0052B280`, but stored definitions and consuming code still require
their own provider checks. The donor's concrete typed dash chain is in
[Itachi providers](#typed-providers).

## Typed providers

Checked donor is **NUN3 Itachi ID 23 (`itc`)**; native comparison is
**retail NA2 Itachi Uchiha ID 71 (`itw`)**. The clean CVM inputs are
NUN3's root fighter files and NA2's `PL/2ITWBOD1.CCS`, with each game's
own `CMN/2CMNBOD1.CCS` and `CMN/CW2.CCS`.
Counts below concern complete decompressed CCS files. A marked key keeps
its full namespace/name pair; comparison removes only the namespace's
leading ownership marker. A provider must have a non-carrier typed
definition, excluding `0x2000/0xFF01` carriers alone.

| Donor file | Bytes / file rows / object rows | Marked keys | Checked provider result |
| --- | --- | ---: | --- |
| `2ITCBOD1.CCS` | 1,288,172 / 123 / 4,241 | 38 | All in donor common body; 34 in native common body |
| `2ITCCHA0.CCS` | 34,972 / 4 / 73 | 30 | All in native common body |
| `2ITCCHA1.CCS` | 155,452 / 8 / 268 | 39 | 34 in native common body; one weapon in native CW2; four missing muffler objects |
| `1ITCBOD1.CCS` | 695,948 / 8 / 206 | 0 | Own resident cinematic presentation definitions |
| `3EYE/3ITC3EYE.CCS` | 29,880 / 5 / 204 | 67 | All resolve to donor `1ITCBOD1` typed definitions |
| `3EYE/3ITC3PCT.CCS` | 65,932 / 1 / 2 | 0 | No marked dependencies |

Native `PL/2ITWBOD1.CCS` is 1,500,076 bytes, 128 file rows and 4,375
object rows. Those counts do not identify equivalent animations or materials.

The four absent exact names are `OBJ_2cmn00t0 muffler`, `muffler1`,
`muffler2` and `muffler3` under `c\\2cmn\\max\\2cmnbod1.max`.
Donor body directory IDs are 974/976/978/980; CHA1 IDs are
97/99/101/103. They are the shared common-provider difference also
established for NUN3 Kakashi/Guy-family bodies.
CHA1's marked row 140, `OBJ_w2kn00t0 weapon`, instead resolves under
`c\\w\\2\\kn0\\max\\w2kn0body.max` to typed object `0x0100` in both
games' `CMN/CW2.CCS`: donor ID 269 and native ID 276. Its absence from
the common body is not an absent native provider.

The donor battle dash is a concrete typed chain:
`OBJ_2itcdash` ID 156 (`0x0100`) → `MDL_2itcdash` ID 4218 (`0x0800`)
→ inline model part ID 4219 / material ID 4220 (`0x0200`)
→ `TEX_2itcdash` ID 4221 (`0x0300`) → `CLT_2itcdash` ID 4226
(`0x0400`). Alternate palettes c1/c2/c3 are IDs 4227/4228/4229.
`CMP_2itcdash` ID 4217 is a `0x0900` composition targeting object 156.
Local `0x0A00` wrappers 155/2075/2110/2143/2783/3426/3832 also target
object 156 and have `0x2000` carriers. The model part's absence as a
separate top-level section does not make its enclosing model untyped.

CHA0 defines its own `ANM_pitccha00`, dash composition/object/model,
material/texture and all four dash palettes. The executable selection of
body versus CHA0 and colour versus c3 belongs to
[Itachi ordinary jutsu](#itachi-ordinary-jutsu-and-resources).
Its borrowed cache lifetime belongs to
[Itachi callbacks](#callbacks).
The five cinematic pairs' complete marked-key census belongs to
[Itachi cinematics](#cinematics).

These checks establish exact provider identity and selected typed payload
edges. All remaining nested geometry/effect fields, foreign reader behavior,
participant substitution and simultaneous residency remain open.

## Ultimate Jutsu and effects

Checked donor is **NUN3 Itachi ID 23 (`itc`)**; native comparison is
**retail NA2 Itachi Uchiha ID 71 (`itw`)**.
`itachi_ultimate_jutsu_list` (`SLUS 0x0047B610`, selected by pointer row
`0x0047B7BC`) contains count 20 and global records 294..313.
`itachi_ultimate_jutsu_records` (`0x004DAD38`) contains twenty
`0x24`-byte records. They are four five-record groups selecting the same
five authored skills, with base/2/3/4 display variants and different
six-word stat-adjustment vectors. They are not twenty separate cinematics.

| Base record / skill | Stored English title | Required ability IDs | Intro / effect / damage percent |
| --- | --- | --- | --- |
| 294 / `0x66` | Tsukuyomi: Nightmare Phantom | `0x2F` | 103 / `0x24` / 25 |
| 295 / `0x67` | Tsukuyomi: Black Nightmare | `0x2F` | 104 / `0x24` / 30 |
| 296 / `0x68` | Visual Jutsu: Flame of Misfortune | `0x2F,0x80,0x4F` | 105 / `0xFFFF` / 30 |
| 297 / `0x69` | Visual Jutsu: The Rising Sun | `0x2F,0x80,0x59` | 106 / `0xFFFF` / 30 |
| 298 / `0x6A` | Visual Jutsu: The Sun God | `0x2F,0x80,0x46` | 107 / `0xFFFF` / 40 |

Groups 299..303, 304..308 and 309..313 retain those skill, prerequisite,
intro and effect selections. The fourth group's `0x68/0x69` damage
percent becomes 35; the other group damage values agree with the base.
`itachi_ultimate_default` (`0x0047BD7E`) selects 298; the mode-1
default (`0x0047BDFE`) selects 294. Ability IDs are the donor's prerequisite
domain, not NA2's UJ categories or fighter identities. Complete admission
and every stat-adjustment consumer remain unestablished.

Native `itachi_ultimate_jutsu_list` (`0x005ACF70`, pointer row
`0x005AD0CC`) has count 4 and records 157..160 at `0x005AF884`.
Its default (`0x005AFE3E`) is 157. Ruby markup is removed from the
following stored Japanese titles; `威凪` is the authored spelling.

| Native record / skill | Stored title | Category / class / cost tier | Intro / secondary intro / effect / damage percent |
| --- | --- | --- | --- |
| 157 / `0x82` | 火遁・豪焔球 | 2 / 3 / 0 | 136 / -1 / `0xFFFF` / 25 |
| 158 / `0x81` | 幻術・泡沫 | 3 / 3 / 2 | 137 / -1 / `0xFFFF` / 45 |
| 159 / `0x83` | 瞳術・威凪 | 1 / 3 / 1 | 138 / -1 / `0xFFFF` / 35 |
| 160 / `0x84` | 最凶の刺客 | 2 / 3 / 0 | 139 / -1 / `0xFFFF` / 30 |

The cinematic selections, intros, metadata and effects differ.
Native's independent `itachi_awakening_association` (`0x005C1F68`)
is `{effect 0x4A,count 1}`; none of its four selected UJ records inserts
that effect through their authored post-film field.
NUN3's `ultimate_jutsu_record_form` (`0x0028BFF0`) returns a replacement
identity only for effects `0x3D..0x46` → IDs 47..56. Effect `0x24`
returns zero: the checked Itachi UJ completion route does not replace
ID 23 with another fighter. This does not prove every donor availability
or awakening service equivalent to NA2's.

The separate effect implementations and native owned-player difference
are in [Itachi effects](#power-effects).
The five donor request pairs and four native pairs are in
[Itachi cinematics](#cinematics).

## Power effects

Checked identities are **NUN3 Itachi ID 23 (`itc`)** and **retail NA2
Itachi Uchiha ID 71 (`itw`)**. NUN3's selected Tsukuyomi records use
effect `0x24`; native Itachi's independent awakening association uses
`0x4A`. Record selection and lack of donor fighter replacement are in
[Itachi UJ comparison](#ultimate-jutsu-and-effects).

Donor `itachi_tsukuyomi_effect_definition` (`SLUS 0x00474CB4`) stores
effect `0x24`, countdown 600 and flags `0x12`; the first seven factor
words are 1.0. Factory binding `0x00473D48` selects
`itachi_tsukuyomi_effect_create` (`0x001FF310`), allocating `0xE0`.
`itachi_tsukuyomi_effect_construct` (`0x001FF370`) installs vtable
`0x006892C0`, constructs two tint helpers at `+0xC4/+0xC8`, and clears
the private state/phase fields. The factory binding identifies this as
effect `0x24` independently of the native effect ID.

`itachi_tsukuyomi_effect_primary_update` (`0x001FF4D0`) selects owner
through effect `+0x64` and opponent through fighter `+0x20`.
It writes actor `+0x1A0` to 0.75 for the owner and 0.25 for the opponent
unless the owner's `0x001CEA50` gate holds, when both become 1.0.
Exact 1.0 at actor `+0x2F0` becomes 0.99. The same routine controls
linked response/position paths; the full gate semantics remain unassigned.
`itachi_tsukuyomi_effect_secondary_update` (`0x001FF710`) owns tint
helper submission under its opponent-action gate, uses a scene-indexed
intensity when scene < 28 or `0xBF` otherwise, scopes the rendering
context and advances private jitter/phase feedback.
`itachi_tsukuyomi_effect_destroy` (`0x001FF3D0`) restores both actor
rate fields to 1.0, destroys the two helpers and performs common cleanup.

Native `effect_4a_definition` (`0x0059FF8C`) instead stores countdown
450 and flags 2. `effect_4a_callback` (`0x002C8690`) also writes
owner/opponent rate multipliers to 0.75/0.25, but uses native `+0x1B4`
and distance-400, restore-gate and context-state admission. Rejection
restores both rates; another nonzero context state skips the update.
The shared numeric rate values therefore do not establish equivalent
activation, duration or linked-action behavior.
Native's separately owned `ANM_eitwsrn`/`EFF_eitwring0` player is in
[Itachi construction](#records-moves-and-assets).
The donor has no corresponding player in its fighter constructor/virtuals.

## Cinematics

Checked identities are **NUN3 Itachi ID 23 (`itc`)** and **retail NA2
Itachi Uchiha ID 71 (`itw`)**. The selected records and damage percentages
are owned by [Itachi UJ comparison](#ultimate-jutsu-and-effects).
The donor uses the request and callback contract already established under
[NUN3 Guy requests](guy.md#cinematics).

`itachi_cinematic_request_rows` (`SLUS 0x00670938`) contains five
`0x14`-byte resident request rows, skills `0x66..0x6A`. Each has zero
explicit extra resident requests and exactly one streamed pair.

| Skill / row address | Resident main / stream | `CAM_camera01` directory ID | Marked main / stream keys |
| --- | --- | ---: | ---: |
| `0x66` / `0x00670938` | `str/d23_101e.ccs` / `str/d23_101.ccs` | 1006 | 1 / 202 |
| `0x67` / `0x0067094C` | `str/d23_102e.ccs` / `str/d23_102.ccs` | 788 | 4 / 216 |
| `0x68` / `0x00670960` | `str/d23_103e.ccs` / `str/d23_103.ccs` | 336 | 0 / 169 |
| `0x69` / `0x00670974` | `str/d23_104e.ccs` / `str/d23_104.ccs` | 360 | 1 / 201 |
| `0x6A` / `0x00670988` | `str/d23_301e.ccs` / `str/d23_301.ccs` | 1298 | 0 / 206 |

**Complete bounded clean-file census:** every marked namespace/name key in
each selected pair has a non-carrier typed definition within that pair,
donor `1ITCBOD1`, `1CMNBOD1`, `STRMCMN` and `CMN/EFFECT0X`.
There are zero unresolved keys against that checked set. All ten complete
files were section-walked to their decompressed end. None has a `BIN_`
directory name. Neither the latter absence nor a provider match establishes
absence of embedded commands, equivalent camera behavior, or successful
foreign parsing. The selected geometry/renderer reader differences remain
owned by [CCS runtime](../../../game/files/ccs_runtime.md#nun3s-parser-compared-with-na2s).

`itachi_cinematic_auxiliary_entries` (`0x0047C3E0`) selects arrays
`0x006A109C..0x006A10AC`; their single-request entries are
`0x00584870/0x00586090/0x005871C0/0x00587A70/0x005885C0`.
These are scene auxiliary roots, not audio or damage tables.
`itachi_cinematic_defender_position_entries` (`0x0047CAF0`) selects
the following counted, defender-ID-indexed placement descriptors.

| Skill | Placement descriptor | Authored frame thresholds |
| --- | --- | --- |
| `0x66` | `0x005E0CE0` | 1, 125, 175, 275 |
| `0x67` | `0x005E14E0` | 1, 60, 260 |
| `0x68` | `0x005E1CE0` | 1, 288, 297 |
| `0x69` | `0x005E24E0` | 1, 60, 115, 165 |
| `0x6A` | `0x005E2C20` | 1, 73, 106 |

`sp_skill_play_begin` (`0x002952D0`) selects these descriptors and
the request-ordinal auxiliary data. `sp_skill_play_update`
(`0x00294F10`) applies placement; `sp_skill_play_frame`
(`0x002952B0`) delegates camera auxiliary updating. That frame callback
has no native-style audio/hit-row loop. The donor's separate cinematic
damage and dialogue producer/scheduler remains unestablished, including
its relation to the stored record damage percentages. All exact per-defender
XYZ triples, camera payload interpretation and timed appearance substitutions
remain open.

The native comparison's own `STRMCMN.CCS` `BIN_strtbln4` SINF rows
(payload at decompressed `0x68E7C`) select:

| Native skill | Resident main / stream | Explicit extras / streams / appearance rows |
| --- | --- | --- |
| `0x82` | `str/d71_20e.ccs` / `str/d71_20.ccs` | 0 / 1 / 0 |
| `0x81` | `str/d71_10e.ccs` / `str/d71_10.ccs` | 0 / 1 / 1 |
| `0x83` | `str/d71_30e.ccs` / `str/d71_30.ccs` | 0 / 1 / 0 |
| `0x84` | `str/d71_50e.ccs` / `str/d71_50.ccs` | 0 / 1 / 1 |

Native rows have stride `0x18`; `sp_skill_relocate_request_table`
(`0x00357B10`) resolves strings from payload `+0x25C4`, stream indices
and 12-byte appearance entries. Skill `0x81` appearance entry 113
binds `CLT_1itwhand` to `EXT_1itw00t0 arm`; skill `0x84` entry 114
binds `CLT_e71char01` to `EXT_e71char01`, each with null optional path.
These checked native request and substitution rows are separate from the
donor's five scene families. Startup voice belongs to
[Itachi audio](#voice).

## Voice

Checked identities are **NUN3 Itachi ID 23 (`itc`)** and **retail NA2
Itachi Uchiha ID 71 (`itw`)**. Compact SNDDATA, streamed PLVOICE and
SOUND intro indices are independent domains.

| Exact bank | Descriptor live address | SNDDATA header offset / bytes | Aligned sample start / bytes |
| --- | --- | --- | --- |
| Donor English, set 0 | `itachi_compact_bank_english 0x003883A4` | `0x00A65000 / 0x1000` | `0x00A66000 / 0x68300` |
| Donor Japanese, set 1 | `itachi_compact_bank_japanese 0x00388650` | `0x01AD0800 / 0x1000` | `0x01AD1800 / 0x5F2B0` |
| Native ID 71 | `itachi_compact_bank 0x003FDB84` | `0x01182000 / 0xF60` | `0x01183000 / 0x298F0` |

Donor `itachi_voice_event_lists` (`0x003891E0`) has both pointers equal
to the shared base list `0x004E4F30`. `fighter_voice_event_list`
(`0x0019BDA0`) has no Itachi alternate-list branch. Events
`0/0x18/0x19` select controls `0/26/27`; the common controls at
`0x00385440` encode programs 0/26/27 with normal key `0x3C`.
The existing [compact lookup](../../session/battle_audio.md#compact-program-to-vag-lookup), applied to
these clean banks, establishes the following stored candidates.

| Program / key `0x3C` | Donor Sset / Smpl | Donor English Vagi / file offset | Donor Japanese Vagi / file offset | Native Sset / Smpl / Vagi / file offset |
| --- | --- | --- | --- | --- |
| 0 | 0 / 0 | 3 / `0x00A72EC0` | 2 / `0x01ADA430` | 0 / 0 / 3 / `0x011860B0` |
| 26 | 26 / 26 | 29 / `0x00AC9760` | 28 / `0x01B28690` | 23 / 23 / 28 / `0x011A9140` |
| 27 | 27 / 27 | 9 / `0x00A82A10` | 8 / `0x01AE8060` | missing program entry |

Every listed split admits keys 12..119; Sset and sample velocity bounds
are 1..127, and all selected sample rates are 22050 Hz. These are file
offsets, not live IOP addresses or PLVOICE indices. The native bank's
missing program 27 establishes a bank difference without proving which
native events emit that control or equating spoken content.

Donor PLVOICE descriptors `0x00388B30/0x00388CF0` select physical outer
members 22/78, handles 92/148, each with 209 declared sparse members.
Their subarchives start at file offsets `0x00A0D000/0x01A5C800`, sizes
405504/305152. Both have the same 27 populated physical indices:
`6,7,23,24,45,47,49,50,68,69,85,92,96,97,98,99,111,112,118,125,151,
165,166,167,199,202,208`.
Native PLVOICE outer 70 starts at `0x00D8F000`, size 344064, with 42
dense physical members. Its filename suffixes, in physical order, are
`45,47,49,63,68,69,125,126,151,155,165,166,167,199,209,210,211,235,
269,290,293,302,303,308,312,313,315,316,317,318,323,324,338,339,364,
365,366,369,370,373,374,379`.
Donor members 96..99 have no corresponding native filename-number entry.
That is a numbering/content-container difference, not an audible identity.

The donor's selected five UJ records request SOUND intro members 103..107.
The checked presentation path `0x002E36D0` uses language-dependent outer
bank 9 or 23 and mono slot 0. Native's four records request members
136..139 in SOUND outer 7. The physical selections are:

| Donor intro | English SOUND offset / bytes | Japanese SOUND offset / bytes |
| ---: | --- | --- |
| 103 | `0x12F1C000 / 20414` | `0x2626E800 / 12014` |
| 104 | `0x12F21000 / 28341` | `0x26271800 / 22620` |
| 105 | `0x12F28000 / 16137` | `0x26277800 / 14440` |
| 106 | `0x12F2C000 / 25044` | `0x2627B800 / 26486` |
| 107 | `0x12F32800 / 12266` | `0x26282000 / 16993` |

Native SOUND outer 7 has 189 members and begins at `0x08226000`.
Its members 136/137/138/139 begin at
`0x08418000/0x0841C000/0x08421000/0x08425800`, with
14920/19381/18238/38934 bytes respectively.
These are startup intros, not complete cinematic spoken-cue schedules.
The donor Haze update's command `0x51` requests dialogue or common
cue 6..8; its final physical member selection and admission, all other
dialogue producers, cinematic damage/audio scheduling and spoken-content
matches remain open. The executable Haze roots belong to
[Character assets](#itachi-ordinary-jutsu-and-resources).
