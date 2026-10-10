# Shizune and Kabuto: NUN4 donors

## Research coverage

Established for NUN4 Shizune 27 and Kabuto 28 against NA2 Shizune 85 and
Kabuto 90: what changed (Shizune's Tonton jutsu, Kabuto's second jutsu, some
ordinary attack rows and callbacks); ordinary-jutsu titles; Kabuto's donor first
jutsu against NA2's retained `2KBTCHA0` and playable resource 184; selected typed
effect providers; compact and streamed voices; power effects; and the four shared
Ultimate Jutsu films, whose timelines, camera payloads and hit rows match while
selection metadata and other scene bytes differ.
Open: contact-mask and receiver-action translation, effect admission, enclosing
provider lifetime, and the films' nested geometry and wrapper lifetime.

Names come from `@annotations/NUN4` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [NUN3 and NUN4 characters](../nun3_nun4_characters.md).

## Records, moves and assets

**Checked identities:** NUN4 `SLUS-21862` Shizune ID 27 (`szn`) and
Kabuto ID 28 (`kbt`) are compared with retail NA2 `SLPS-25837` Shizune
ID 85 (`szw`) and Kabuto ID 90 (`kbw`). NA2 definition slots 27/28
are filler Classic Naruto records. Complete CCS identities are in
[Retail game file identities](../../../game/files/file_identities.md#shizune-and-kabuto-comparison-inputs).

| Exact fighter | Definition record | Actions / animation rows / names | Factory / constructor; allocation |
| --- | --- | --- | --- |
| NUN4 Shizune 27 | `shizune_character_record`, `0x004A58C0` | `0x004A4530` / `0x004A0D10` / `0x004A0A80`; 50/189/161 | `shizune_create`, `0x00264C70` / `shizune_construct`, `0x00264CC0`; `0x5D00` |
| NA2 Shizune 85 | `shizune_character_record`, `0x00575290` | `0x00574210` / `0x005707F0` / `0x00570560`; 50/189/161 | `0x002EFF80` / `shizune_construct`, `0x002EFFD0`; `0x59F0` |
| NUN4 Kabuto 28 | `kabuto_character_record`, `0x004AA2C0` | `0x004A9190` / `0x004A5E80` / `0x004A5C30`; 44/172/148 | `kabuto_create`, `0x00265F80` / `kabuto_construct`, `0x00265FD0`; `0x5570` |
| NA2 Kabuto 90 | `kabuto_character_record`, `0x0058AB50` | `0x00589CD0` / `0x00586850` / `0x00586600`; 44/172/148 | `0x002F83B0` / `fighter_id_090_construct`, `0x002F8400`; `0x52C0` |

**Stored-data observations:** all 33 words at record `+0x58..+0xD8`
agree within each same-name pair. This does not establish equal moves.
NUN4/NA2 action strides are `0x64/0x54`, with packed owner/selector at
`+0x1C/+0x0C`. After normalizing character codes, animation-name slots
differ only at 44 (donor `gxn0`, NA2 empty), and 70/72 (donor empty,
NA2 `chb00/chb02`). Other action-tail words differ, including response
selectors and audio fields; those differences are not all decoded here.

Excluding skeleton-name pointers, the complete differing ordinary `0x4C`
rows are below. Values are donor → NA2, using the established NA2 field
names for the matching serialized offsets. Their player-facing move names
are not inferred from the animation codes.

| Fighter; action / row / animation suffix | Differing stored values |
| --- | --- |
| Shizune; 32 / 132 / `kcn20` | planar speed `50 → 60` |
| Shizune; 32 / 133 / `kcn22` | motion decay `0.2 → 0.15` |
| Shizune; 35 / 141 / `pnc40` | rate `256 → 336` |
| Kabuto; 28 / 118 / `pnc60` | rate `256 → 208`, speed `10 → 25`, decay `0.25 → 0.2`, both bank-end halfwords `-1 → -2` |
| Kabuto; 28 / 119 / `pnc62` | decay `0.25 → 0.3` |
| Kabuto; 29 / 121 / `pnc70` | motion-event halfword `-1 → 4`, speed `40 → 35`, decay `0.25 → 0.15` |

Rows 0/1 also differ substantially: NUN4 stores no `chb00/chb02` animation
or attack banks there; NA2 supplies paired-scene approach/response data.
Jutsu action 1 starts at row 4 and action 3 at row 10 in all four records.
The first donor action costs 3.0; NA2 action 1 costs zero while its paired
action 0 costs 3.0. Second actions cost 3.0. Donor/NA2 first-action damage
scalars are Shizune `0.125/0.125`, Kabuto `0/0.125`; second-action
scalars are Shizune `0/0.125`, Kabuto `0.125/0.125`. These authored
scalars alone do not give total damage after actor effects.

### Shizune/Kabuto ordinary-jutsu localized title bindings

The NUN4 resident `fighter_authored_action_static_initialize`
(`0x005DA4A0`) fills these four actions' five display slots. Slot
`+0x08` receives the English pointer; `+0x0C..+0x18` all receive the
same French pointer. The action addresses below are the `0x64`-stride
authored records for Shizune 27 and Kabuto 28, not Ultimate Jutsu metadata.
The display slots are zero in the stored execution actions before this
initializer runs.

| Fighter / action; record address | English slot / pointer source / literal | Checked English title | Selector → resource / provider |
| --- | --- | --- | --- |
| Shizune 27 / 1; `0x004A4594` | `0x004A459C / 0x00437B80 / 0x005957D0` | Hog Style: Tonton | 54 → 57 / `2szncha0.ccs` |
| Shizune 27 / 3; `0x004A465C` | `0x004A4664 / 0x00437B84 / 0x005957F0` | Ninja Art: Poison Fog | 55 → 58 / `2szncha1.ccs` |
| Kabuto 28 / 1; `0x004A91F4` | `0x004A91FC / 0x00437BC0 / 0x00595900` | Feather Illusion Jutsu | 56 → 45 / `2kbtcha0.ccs` |
| Kabuto 28 / 3; `0x004A92BC` | `0x004A92C4 / 0x00437BC4 / 0x00595920` | Chakra Dissection Blade | 57 → 46 / `2kbtcha1.ccs` |

The four annotated English-title stores are
`shizune_jutsu0_bind_english_title` (`0x005DE6B4`),
`shizune_jutsu1_bind_english_title` (`0x005DE6EC`),
`kabuto_jutsu0_bind_english_title` (`0x005DEA34`) and
`kabuto_jutsu1_bind_english_title` (`0x005DEA6C`). Their following stores
fill the four other slots from `0x00438BB0/BB4/BF0/BF4`, respectively.
Those pointers select `Style du Cochon, Ton ton` (`0x0059B540`),
`Ninpô, Nuage de Poison` (`0x0059B560`), `Les Plumes du Nirvana`
(`0x0059B680`) and `Scalpel de Chakra` (`0x0059B6A0`).

`shizune_jutsu0_bind_display_record` (`0x005E742C`) loads the ID-27
definition's record and its `+0x2C` action base, adds `0x64`, and writes
selector 54's action pointer at `0x0057401C`; its following store at
`0x005E743C` uses `+0x12C` for selector 55. The matching Kabuto
`kabuto_jutsu0_bind_display_record` (`0x005E7454`) and store
`0x005E7464` bind ID-28 actions 1/3 to selector 56/57 pointer fields
`0x00574034/40`. These four provider rows' `+0x08` words select the
filenames above. Their action `+0x1C` words independently encode owner
27 with selectors 54/55 and owner 28 with selectors 56/57. The BATTLE
map words at `0x0085B238..247` are `{57,58,45,46}`.
`jutsu_selector_display_name` (`0x002D1310`) returns the selected
record's `+0x08 + 4*ui_language_index()` pointer, completing the
selector-to-displayed-title join.

MCP has no imported function for the selector-binding initializer tail;
its loads, additions and stores above were checked from MCP memory bytes
at `0x005E7418..0x005E7467`. The title initializer and display-name
consumer were checked in both decompiled code and their instruction operands.

These ordinary-action titles are resident ELF strings. The inspected
TEXTENG `english_text_static_initialize` (`0x00899480`) does not write
these four action slots. TEXTENG's `Dead Soul Jutsu` (`0x00874050`)
is a separate Ultimate Jutsu title; it does not name Kabuto action 3.
The descriptive actor annotations `kabuto_chakra_jutsu_*` and
`kabuto_dead_soul_jutsu_*` below identify code roots, not recovered
ordinary-jutsu display names.

### Selected jutsu actors and authored commands

| Fighter / action 1 or 3 | Selector → resource / provider | Factory and concrete actor evidence |
| --- | --- | --- |
| NUN4 Shizune 27 / 1 | 54 → 57 / `2szncha0` | Factory arm `0x0074D468`, allocation `0x1020`, final `shizune_tonton_jutsu_vtable` `0x005F2A90`, RTTI `ccSkillSZN000`; `sk4_jutsu_clear_state` `0x00810050`, concrete clear `0x00814710`, setup `0x00814A30`. |
| NA2 Shizune 85 / 1 | 170 → 174 / `2szwcha0` | Factory arm `0x0077574C`, allocation `0x1110`, base `0x00797250`, `shizune_combo_jutsu_vtable` `0x005E42B0`. |
| NUN4 Shizune 27 / 3 | 55 → 58 / `2szncha1` | `shizune_poison_jutsu_construct` `0x00796E20`, allocation `0x9E0`, vtable `0x00601080`, RTTI `ccSkillSZN001`. |
| NA2 Shizune 85 / 3 | 171 → 175 / `2szwcha1` | `shizune_poison_jutsu_construct` `0x007C0460`, allocation `0x12B0`, vtable `0x005F7210`. |
| NUN4 Kabuto 28 / 1 | 56 → 45 / `2kbtcha0` | `kabuto_chakra_jutsu_construct` `0x007D3210`, allocation `0x770`, vtable `0x005F6970`, RTTI `ccSkillKBT000`. |
| NA2 Kabuto 90 / 1 | 180 → 184 / `2kbwcha0` | Factory arm `0x00775828`, allocation `0x1110`, base `0x00797250`, `kabuto_chakra_combo_jutsu_vtable` `0x005E38B0`. |
| NUN4 Kabuto 28 / 3 | 57 → 46 / `2kbtcha1` | `kabuto_dead_soul_jutsu_construct` `0x007DAAF0`, allocation `0x7C0`, vtable `0x005F62B0`, RTTI `ccSkillKBT001`. |
| NA2 Kabuto 90 / 3 | 181 → 185 / `2kbwcha1` | Factory arm `0x00775EE8`, allocation `0xFF0`, base `0x00785410`, `kabuto_dead_soul_jutsu_vtable` `0x005E0900`; update `0x0086C810`. |

**Clean-file observations joined to the command consumer:** donor startup
animations emit `0x0108` command kind `0x8003` at marker 1 with encoded
resources `0x139/0x13A` for Shizune, `0x12D/0x12E` for Kabuto.
NA2 emits `0x1AE/0x1AF` and `0x1B8/0x1B9`. These are resource IDs plus
`0x100`, not selectors or fighter IDs
([command creation](../nun3_nun4_characters.md#complete-nun4-selector-map)).

Donor Shizune `cha00/01/02/03` lengths are 16/7/25/36, plus
`ton00..07` lengths 16/9/9/2/2/2/2/13. NA2's first file has
`cha00/01/02` lengths 2/151/151, `chb00/02` 11/15 and a 151-frame
camera. `shizune_tonton_jutsu_setup` binds `ton06/00/07` individually
and `ton03/04/05/01` in an array. Its contact handler
`shizune_tonton_jutsu_resolve_contact` (`0x00817610`) manages capture
state and moves the defender to the saved transform. The two Poison Mist
files both contain `cha10..13` lengths 23/13/11/16. Their checked motion
routines (`0x00797130` NUN4, `0x007C0810` NA2) use facing offset 300,
tick-15 helper activation and a 7.5-per-tick advance after tick 14;
their field offsets and called interfaces differ.

Donor Kabuto's first file has `cha00/02` lengths 21/16 and the two-frame
`ANM_e0x_wing_0`. **The NA2 retained `PL/2KBTCHA0.CCS` decompresses
to exactly the same 37,364 bytes.** Its retained resource-45 constructor
`kabuto_classic_chakra_jutsu_construct` (`0x007F4920`) installs
`0x005EC8C0`; it is distinct from playable Kabuto 90's resource 184.
That playable first file instead has 2/125/125-frame `cha00/01/02`,
19/17-frame `chb00/02`, and a 125-frame camera.

Donor second-file `cha10..13` lengths are 19/17/46/31, versus NA2
35/51/61/13 plus `cha14/15` 41/21. Donor `cha12` emits value 0 at
marker 14 and value 1 at marker 26 on target 148.
`kabuto_dead_soul_jutsu_command` (`0x007DB960`) latches those values
and copies the target transform. `kabuto_dead_soul_jutsu_update`
(`0x007DAF50`) consumes them for distinct contact sequences, including
effect 6 for 600 ticks. `kabuto_chakra_jutsu_resolve_contact`
(`0x007D3D90`) applies effect 0 for 200 ticks. Poison contact applies
effect 7 with default lifetime. These are NUN4 effect-number domains.

### Retained Kabuto first-jutsu executable comparison

**Checked actors:** NUN4 Kabuto 28's resource 45 `ccSkillKBT000`,
NA2's retained resource 45 `ccSkillKBT000`, and playable NA2 Kabuto 90's
resource **184** `ccSkillKBW000`. Its factory table word `0x008CD4D0`
selects `0x00775828`.
The retained resource-45 word `0x008CD2A4` selects
`kabuto_classic_chakra_jutsu_factory_case` (`BTL 0x00774D48`), which
allocates `0x1040` and calls its constructor only for a nonzero result.
Factory arms are checked MCP memory bytes because the imported factory's
decompiler omits them. Resident vtables are read from the boot ELF;
their overlapping overlay memory is zero-filled and does not supply them.

The identified clean `2KBTCHA0` files were independently decompressed in
memory and compared byte for byte: both contain 37,364 identical bytes,
SHA-256 `1BF599A9C4CD9FF29C89642CBD8199A4734C3424BF3382581B9D1FF6B1DD7D88`.
Their stored gzip identities differ as recorded in the input document.
This equality establishes the first-jutsu CCS payload only.

| Actor-owned role | NUN4 BATTLE method / vtable slot | Retained NA2 BTL method / vtable slot |
| --- | --- | --- |
| Construct | `kabuto_chakra_jutsu_construct`, `0x007D3210` | `kabuto_classic_chakra_jutsu_construct`, `0x007F4920` |
| Setup | `kabuto_chakra_jutsu_setup`, `0x007D3380` / `+0x220` | `skill_particle_sets_initialize_7f4c70`, `0x007F4C70` / `+0x22C` |
| Update | `kabuto_chakra_jutsu_update`, `0x007D3830` / `+0xFC` | `kabuto_classic_chakra_jutsu_update`, `0x007F50A0` / `+0x100` |
| Contact preparation | `kabuto_chakra_jutsu_contact_prepare`, `0x007D3C80` / `+0x188` | `kabuto_classic_chakra_jutsu_contact_prepare`, `0x007F54B0` / `+0x18C` |
| Contact resolution | `kabuto_chakra_jutsu_resolve_contact`, `0x007D3D90` / `+0x198` | `effect00_source_duration200`, `0x007F55C0` / `+0x1A0` |
| State selection | `kabuto_chakra_jutsu_set_state`, `0x007D3EF0` | `btl_byte_ff0_descriptor1000_select`, `0x007F5720` |
| Destroy | `kabuto_chakra_jutsu_destroy`, `0x007D32B0` / `+0x21C` | `kabuto_classic_chakra_jutsu_destroy`, `0x007F49C0` / `+0x228` |

The complete concrete tables were compared against their own primary bases:
NUN4 `0x005F6970` against `0x00604F30`, and NA2 `0x005EC8C0` against
`0x005FB4D0`. Both replace the three update phases, post-update,
contact preparation/resolution, setup and destruction. Their phase-0,
phase-1 and post-update bodies are verified `jr ra; nop`.
NA2 additionally replaces contact-record slot `+0x19C` and completion
slot `+0x1B4`; the corresponding NUN4 `+0x194/+0x1A8` bodies,
`skill_contact_record_noop` (`0x00756EB0`) and
`skill_contact_complete_noop` (`0x00761820`), are verified no-ops.
No uniform vtable-slot shift describes the entire translation.

**Established shared structure:** all concrete constructor-owned fields
translate from donor `+0x720..+0x76C` to NA2 `+0xFF0..+0x103C`
by `+0x8D0`, preserving widths and initial values. The primary vtable
pointer instead moves `+0x100 → +0x110`, participant headers
`+0x1E0/+0x390 → +0x200/+0x3B0`, resource `+0x54C → +0x56C`,
and the first embedded contact helper `+0x660 → +0xF30`.
These are distinct offset domains, not one object-wide delta.

Both updates use states 0..3. State 0 emits at ticks 20/24 and changes
to state 1 after tick 29; state 1 moves its two x boundaries by
`-40/+40` through tick 20 and changes to 2 after tick 25. State 2
waits for its primary-header outcome, then selects 3; state 3 calls
the inherited finish request (`skill_primary_request_finish`, donor
`0x0075F590`, versus `skill_primary_request_retirement`, NA2
`0x00785D60`). That request sets the retirement flag and clears embedded
contact helpers; it does not itself free the actor.

The complete actor-specific helper pairs preserve the following algorithms:
central and `±210` contact nodes through an 800-unit reach at owner z+150;
`0x60` nodes initialized with countdown 12, activation between moving boundaries,
handle removal and list destruction; ring distance increments of 120,
emission every second update and completion beyond 800; four particles
moving at `±40` to an 800-unit limit; and a fifth particle following
`OBJ_2cmn00t0 l hand`. The paired helpers are annotated under
`kabuto_chakra_jutsu_*` / `kabuto_classic_chakra_jutsu_*`.
Both bind `ANM_e0x_wing_0` and `ANM_pkbtcha02`; all `0x130` bytes of
the three generator records and force descriptors at donor `0x0084DA20`
and NA2 `0x008B37F0` agree. Both ring constructors select
`effect0x/CMP_e0xring01` and initialize the lifetime field at `+0x1BC`
to 15. This identifies
code-selected roots without closing their full provider graph.

**Established differences:** setup side-0 contact words are donor
`{0x40,0x410900}` versus NA2 `{0x80,0x88900}`; side 1 uses
`{0x800,0x208048}` versus `{0x800,0x44090}`. Donor
`jutsu_extra_contact_mask_flag` (`0x00745A30`) can additionally OR
`0x100000` into the second word; retained NA2 setup has no such branch.
Contact preparation checks effect IDs 0/1 and the same receiver flag bits
through each game's services. Donor `fighter_has_effect_id`
(`0x002CF980`) and NA2 `fighter_has_effect` (`0x00306420`) use the same
bounded list traversal: exact effect ID at node `+0x68`, next node at
`+0x1C`, without a countdown qualification. Resolution checks receiver
major state 5,
but donor actions `0x2D..0x33` versus NA2 `0x2F..0x35`, then requests
effect 0 for 200 ticks, clears the response word and contact helper.
The selected action ranges' semantic correspondence and complete resident
effect/mask admission are not established by these matching call shapes.

Retained NA2's extra `kabuto_classic_chakra_jutsu_build_contact_record`
(`0x007F4B60`) clears response fields in the selected side/resource cache,
sets category 4 and attack scalar to **half the owner's current action
scalar**, submits via `+0x194`, then invokes completion.
`kabuto_classic_chakra_jutsu_contact_complete` (`0x00873FD0`) forwards
that completion to the effect-0 resolver. The checked donor slots do
neither. This is an executable difference even with identical CCS bytes;
the extra scalar is zero with the checked donor action-1 scalar but
nonzero with native Kabuto's stored action-1 scalar.

Both destructors stop registry-valid particle handles, clear/release contact
nodes and restore the owner auxiliary (`fighter +0x940 → +0x950`) before
common cleanup and optional deleting free. The NUN4 common destructor
`skill_primary_destroy` (`0x0075F460`) unregisters through manager `+0x230`
and clears a shared scene flag. NA2 uses its native registry at manager
`+0x210`, additional owned `+0x144` storage and five translated helper
destructors. Shared cleanup services are not interchangeable raw addresses.

**Playable NA2 actor:** resource 184 allocates `0x1110`, constructs
`skill_tyo_base_construct` (`0x00797250`) and installs
`kabuto_chakra_combo_jutsu_vtable` (`0x005E38B0`, RTTI `ccSkillKBW000`).
Its complete `0x280`-byte table differs from combo base `0x005FB240`
only in RTTI and four methods: linked-player update `+0xF8`
(`kabuto_combo_jutsu_update_linked_players`, `0x00850B30`), setup
`+0x22C` (`kabuto_combo_jutsu_setup`, `0x00850AF0`), transition contact
`+0x260` (`kabuto_combo_jutsu_transition_contact`, `0x00850C00`), and
destroy `+0x228` (`kabuto_combo_jutsu_destroy`, `0x008721F0`). Setup
binds two source names and one target name through the inherited
participant/camera binder. Transition contact uses a resource definition's
scalar times the owner's current action scalar; inherited accepted events
use the native combo/finish routes. Destruction drains linked players and
camera/reference storage before primary cleanup. This is a different actor
and callback/lifetime contract from the retained contact-line actor.

**Conclusion:** the retained actor supplies the donor-specific state machine,
geometry and lifetime structure, with native field/service translations
already present. It is not fully executable-equivalent to NUN4, and the
playable combo actor is not a substitute for it. Remaining independent
questions are the donor extra-mask flag's producer/meaning, mask and
effect-0/1 admission/cleanup correspondence, and the checked major-5 action
range's semantic mapping. Code-selected providers are recorded below;
remaining changed-piece audio questions belong to the audio comparison.

### Code-selected ordinary-jutsu effect providers

This scope is NUN4 Shizune 27 (`szn`) and Kabuto 28 (`kbt`), compared
with NA2 Shizune 85 (`szw`) and Kabuto 90 (`kbw`). It closes selected
resource keys and typed file edges, rather than complete visual or actor
equivalence. All record IDs below are local to the named CCS container.
NUN4 `frontend_load_common_ccs` (`0x00315F80`) loads `CW2`, `EFFECT0X`,
`GAUGE`, `PARTICLE` and `SHADE` from `CMN/`. `battle_load_ccs`
(`0x00317130`) separately includes `CMN/2CMNBOD1`, `PL/1CMNBOD1` and
`MODENAME/MODE1CMN`. Selected fighter jutsu files use the
[NUN4 jutsu request and borrowed-provider path](../nun3_nun4_characters.md#nun4-checked-jutsu-resource-load-and-caches).
Requiring a published provider does not load or retain it.

**Tonton:** `shizune_tonton_jutsu_setup` (`0x00814A30`) requires
`2szncha0` and binds `ANM_psznton06`, `00`, `07` and `03/04/05/01`
to its auxiliary players. `shizune_tonton_jutsu_bind_action_animations`
(`0x00814F70`) constructs `ANM_pszncha0%d` for 0..3 and
`ANM_psznton0%d` for 0..6. Together these select all eight `ton` roots,
not only the actor's four ordinary `cha` animations. Their local branches
have the following typed closure in `PL/2SZNCHA0.CCS`:

| Selected root | Scene/model and material/image closure |
| --- | --- |
| `ton00..05`, IDs 205/235/265/295/325/355 | Local Tonton wrappers and the 29-child `CMP_2szntnt00t0 trall` (381). Body scene 202 selects model 432; all 17 model parts select `MAT_2szntnt` (433) → `TEX_2tntbody` (434) → `CLT_2tntbody` (472). Local shadow models have shadow geometry rather than material/image edges. |
| `ton06`, ID 358 | Wrapper 356 → `OBJ_pszncha0` (357) → model 438 → material 440 → `TEX_pszncha0` (441) → CLUT 473. |
| `ton07`, ID 380 | Eight wrappers resolve to local scene IDs 360/362/364/366/368/370/372/374. Models 446/450/453/456 use materials 448/452/455 → `TEX_szncolor0a` (449) → CLUT 475; models 462/466/468/470 use material 464 → `TEX_szncolor0b` (465) → CLUT 476. Four authored material tracks 375/377/378/379 additionally select `TEX_szncolor` (376) → CLUT 474. |

The body-part walk ends exactly at model 432's payload end; the outer
file walk ends at 144,952 decompressed bytes. The local branches above
have no undefined target or nonzero auxiliary controller reference.
The `cha00..03` common-skeleton branches use the marked provider matches
below. The grabbed opponent scene is borrowed: the selected capture method
binds local `ANM_pszncha01` to that scene, not another named effect file.
The two smoke requests in the Tonton state methods call
`battle_create_smoke_helper` (`0x0030C9B0`); its
`battle_smoke_helper_update` (`0x0030CCF0`) low/high emission branches
select transient catalog row 26, `effect0x / EFF_e0ysmok03a`
(`0x00575418`).

**Poison:** `shizune_poison_jutsu_bind_animations` (`0x007976B0`) binds
`ANM_pszncha11/12` through the table at `0x0084B490`.
`shizune_poison_jutsu_create_auxiliary` (`0x00796F80`) captures the
owner's `OBJ_2cmn00t0 neck` transform and passes its jutsu provider to
the helper. `shizune_poison_auxiliary_start` (`0x007981A0`) and its
tick-six emitter update (`0x00797A00`) initially select particle catalog
67 (`0x00577030`), then replace the selected choice's descriptor with
local `EFF_pszndgr0`. The literal pointer is resident `0x00608720` →
BATTLE `0x0085D578`; NUN4 entry initializes GP to `0x0060EF70`, so
the code's GP-relative `-0x6850` operand reaches that exact pointer.
In `2SZNCHA1`, effect 119 → `TEX_pszndgr0` (121) → CLUT 124;
material 120 also selects texture 121. `ANM_pszncha13` (122) controls
the effect wrapper and material; composition 123 contains effect 119.

The contact path `shizune_poison_jutsu_resolve_contact` (`0x007974C0`)
uses descriptor `0x005788C0` and the same catalog 67 without that local
replacement. It retains shared `effect0x / EFF_x001` and the
`CLT_x001c4` palette alias. `particle_choice_bind_effect`
(`0x00348BA0`) changes descriptor, kind and render mode only; it does
not clear the other choice words. Thus the local replacement and shared
catalog/alias dependencies are both part of the inspected setup.

**Feather Illusion:** `kabuto_chakra_jutsu_setup` (`0x007D3380`)
selects two descriptor-`0x0084DA20` emitters using catalog 0, then
replaces their choices with local `ANM_e0x_wing_0`; two
descriptor-`0x0084DA58` emitters use catalog 56, and the fifth
descriptor-`0x0084DA90` emitter uses catalog 73. The local wing root
in `2KBTCHA0` is animation 17 → wrappers 15/16 → scenes 4/2 →
models 9/5 → materials 11/7 → textures 12/8 → CLUTs 13/14.
These are the same retained-file records in NA2 resource 45.
`kabuto_chakra_jutsu_create_feather_visual` (`0x007D4770`) also
uses descriptor `0x0084DB50`: `effect0x / CMP_e0xring01`.
Its typed chain is composition 2246 → scene 2247 → model 2253 →
material 2255 → `TEX_e0xcolor00` (109) → CLUT 2704.
NA2's same key resolves through 2042 → 496 → 2050 → 2052 →
`TEX_e0xcolor00` (177) → CLUT 2514. The independently defined
`TEX_e0xring01` is not the texture selected by this composition.
The fifth emitter follows the owner's `OBJ_2cmn00t0 l hand` transform.
`kabuto_chakra_jutsu_create_wing` (`0x007D4200`) constructs a
collision helper, with no CCS lookup or model binding.

The selected shared particle/effect roots and palette aliases are:

| NUN4 catalog row / provider key | Typed root → texture → default CLUT | Selected palette alias |
| --- | --- | --- |
| 0 / `particle / EFF_e0xpar00` | 64 → 65 → 154 in both games | None in this row. |
| 56 / `particle / CLT_x002c5` | Alias of `EFF_x002`: 113 → 114 → 184 in both games | CLUT 189; base row 51 gives palette number 5. |
| 73 / `particle / CLT_e0xpar01` | Alias of `EFF_e0xpar01`: 67 → 68 → 160 in both games | CLUT 160; base row 73 gives palette number 0. |
| 67 / `effect0x / CLT_x001c4` | Alias of `EFF_x001`: donor 2651 → 2652 → 2798; NA2 2459 → 2460 → 2616 | Donor CLUT 2802; NA2 CLUT 2620; base row 63 gives palette number 4. |
| Transient 26 / `effect0x / EFF_e0ysmok03a` | Donor 2822 → `TEX_e0ysmok03` (2356) → 2830; NA2 2646 → 2647 → 2655 | Default image palette. |

`battle_initialize_particle_resources` (`0x003158D0`),
`battle_particle_bind_cached_resources` (`0x0039C8E0`), and
`ccs_find_resource_palette_texture_variants` (`0x001ADD70`)
establish the alias/base joins and constructed `CLT_` names. The table
does not claim that matching directory IDs establish equal pixels.

**Chakra Dissection Blade:** `kabuto_dead_soul_jutsu_setup`
(`0x007DACE0`) binds local `ANM_pkbtcha11/12/13` and the shared
D8 auxiliary. In `2KBTCHA1`, the scalpel model 24 → material 26 →
`TEX_ekbtmesu` (27) → CLUT 38. Six other drawable models
5/9/16/19/31/34 and their materials 7/11/18/21/33/36 select
`TEX_ekbtcolor01` (8) → CLUT 37; the six `cha13` material tracks
196..201 use the same image. Scene 148, the `cha12` event target,
has no model. Model 202 likewise has no parts. These local branches
and all reachable auxiliary controller references are resolved or zero.
The selected owner-hand and opponent-calf anchors borrow scene transforms;
their exact keys are `OBJ_2cmn00t0 l hand` and `OBJ_2cmn00t0 l calf`.

`battle_emit_aura_and_secondary_visual` (`0x0030C6F0`) selects
transient row 33, `effect0x / ANM_e0x_aura_00`, plus the secondary
pool's row 7, `effect0x / ANM_e0x_gard_01`.
`battle_secondary_visual_pool_initialize` (`0x002DA980`) prebinds
rows 3..7; the context's `+0x4B4/+0x4B8` slot selects row 7.
`battle_emit_contact_visuals` (`0x0030C530`) additionally requests a
surface-selected root through `battle_emit_surface_contact_visual`
(`0x00301F90`). For this caller's index 0, surfaces 0/1/2/3 select
ground IDs 55/60/59/58, mapping to transient rows 49/54/53/52.
The prebound ground-pool table and fallback table agree on those roots.
The D8 auxiliary's inspected draw path uses an untextured rectangle and
has no additional CCS lookup; its actor behavior is covered with the
shared Tsunade auxiliary above.

Each selected shared animation's object tracks resolve through scene
wrappers, drawable models, per-part materials, texture records and CLUTs
to the following image leaves. Non-drawing model records add no image
edge, and all reachable auxiliary controller references are zero.

| `effect0x` root / donor animation ID | Complete donor texture leaves, with their local CLUT IDs |
| --- | --- |
| `ANM_e0x_aura_00` / 143 | `TEX_e0xcolor00` / 2704; `wind00` / 2789; `aura00` / 2698; `aura02` / 2699; `ring00` / 2754; `fla06` / 2712; `wave15` / 2788. The abbreviated names in this table retain the `TEX_e0x` prefix. |
| `ANM_e0x_gard_01` / 533 | `color00` / 2704; `fla01` / 2709; `wave00` / 2786; `par03` / 2746; `tub00` / 2783; `wave15` / 2788, plus the absent shock target described below. |
| `ANM_e0x_kin_00` / 950 | `TEX_e0x_i00` / 2667; `TEX_e0x_ki00` / 2672; `TEX_e0x_nn03` / 2678. |
| `ANM_e0x_gasi_00` / 543 | `TEX_e0x_dot04` / 2665; `TEX_e0x_ka02` / 2671; `TEX_e0x_shi00` / 2683; `TEX_e0x_tu01` / 2687. |
| `ANM_e0x_zan_00` / 1660 | `TEX_e0x_nn04` / 2679; `TEX_e0x_za01` / 2693. |
| `ANM_e0x_zasyu_00` / 1670 | `TEX_e0x_shi02` / 2684; `TEX_e0x_tu03` / 2688; `TEX_e0x_yu00` / 2691; `TEX_e0x_za00` / 2692. |

NA2 contains all six animation keys. Its four surface roots reach the
same named texture leaves. Its aura and guard graphs differ: aura 178
uses `color00/par03`, with 31 authored frames versus donor 143's 46;
guard 505 uses `color00/par03/par12/wave06/wave07/fla03`.
These common names therefore establish available binding targets, not
equivalent donor presentation.

Donor guard animation 533 has two frame-zero `0x0102` keys for
wrappers 516/517 (`OBJ_e0xshock01a/b`). Both target directory row 524,
`OBJ_e0xshock01`, namespace `#e\0x\max\e0xshock01.max`, which has
no defining section. A read-only search decoded **all 4,031 extracted
NUN4 CCS files** beneath the retail ISO view without an error; the only
exact-name occurrences are this undefined row in the English/French
`EFFECT0X` copies. This bounds absence to that complete extracted CCS
inventory, rather than hypothetical generated records or other formats.

This edge is handled by the selected retail consumer.
The secondary pool invokes `transient_bind_effect_resource`
(`0x002DBD70`) for row 7; `transient_bind_typed_resource`
(`0x002DB9C0`) selects its type-1 animation branch, with no auxiliary
model, and calls `animation_attach` with blend zero.
`ccs_pack_tag_0102` (`0x001A92F0`) retains those source/key pairs;
`ccs_resolve_external_record_chain` (`0x00116A50`) returns zero for a
null or sentinel-4 target runtime. `animation_attach` (`0x001BD710`)
then zeroes each play entry, including its evaluator, and
`animation_evaluate_typed_tracks` (`0x001BC0B0`) skips null evaluators.
Neither shock track parents another selected track: both are children of
scene 511. Thus absence of a published shock provider gives two inactive
tracks without requiring another CCS file. This is a consumer-specific
static conclusion, not evidence of an additional donor shock visual.

The remaining lifetime question is the enclosing selected jutsu/common CCS
retention and release, identified in the linked load/cache section. Typed
keys, their selected file graphs and the guard's absent-edge branch are
established here; complete packed geometry, animation interpretation and
pixel equality between different files are outside that result.

### Common provider and character callback differences

All four donor jutsu files mark only `#c\2cmn\max\2cmnbod1.max`.
Byte-exact namespace/name comparison, preserving Japanese name bytes,
finds 28/28/34/34 marked rows in NA2's common provider, respectively.
All matched provider rows have typed `0x0100` definitions. The donor
files contain 112/84/68/102 local `0x0A00` wrappers targeting those
marked rows; complete nested animation walks reach each outer payload end.
The additional Tonton geometry is local to `2SZNCHA0`, not an extra
marked body provider. These skeleton links complement the
[code-selected effect chains](#code-selected-ordinary-jutsu-effect-providers).

NUN4 Shizune's `shizune_callbacks` (`0x004A0A60`) has four nonzero
slots `0x00264EA0/0x00264ED0/0x00265600/0x00265BB0`; NA2's table
`0x0056FBA0` has `0x002F01B0/0x002F01E0/0x002F0520/0x002F0B10`.

NUN4 Kabuto's `kabuto_callbacks` (`0x004A5C10`) is
`0,0x00266430,0x002664E0,0x00266AA0,0,0,0`; NA2's `0x00585F40`
is `0,0x002F8840,0x002F8850,0x002F8DC0,0,0,0`.
Their compared gameplay effects belong to
[Character action callbacks](#callbacks).

### Checked sound resources

Compact descriptor offsets below use the established
[SNDDATA loader contract](../../../game/character_assets.md#compact-fighter-bank-resources).
Selected program/key samples are decoded by
[Battle audio](../../session/battle_audio.md#compact-program-to-vag-lookup);
the ranges alone do not establish clip selection or spoken content.

| Exact fighter / set | Header offset / bytes | Sample offset / bytes |
| --- | --- | --- |
| NA2 Shizune 85 | `0x0141C800 / 0xF60` | `0x0141D800 / 0x34D10` |
| NA2 Kabuto 90 | `0x014F6800 / 0xF60` | `0x014F7800 / 0x33A70` |
| NUN4 Shizune 27 / English | `0x00B12800 / 0xFE0` | `0x00B13800 / 0x3DDE0` |
| NUN4 Shizune 27 / Japanese | `0x01E95000 / 0xFE0` | `0x01E96000 / 0x35960` |
| NUN4 Kabuto 28 / English | `0x00B51800 / 0xFE0` | `0x00B52800 / 0x3BDB0` |
| NUN4 Kabuto 28 / Japanese | `0x01ECC000 / 0xFE0` | `0x01ECD000 / 0x34BD0` |

Clean `PLVOICE.AFS` outer entries for NA2 Shizune/Kabuto are 84/89,
at file offsets `0x01210000/0x013C3000`, containing 41/43 physical
clips. Donor outer entries 26/27 are at `0x0052D000/0x0056C800`,
containing 18/20 clips. First named members are donor `PL27_116` /
`PL28_121`, versus NA2 `PL85_045` / `PL90_045`. Directory suffixes
are not interchangeable physical member indices.

The [ordinary-jutsu voice comparison](#shizune-and-kabuto-ordinary-jutsu-voice)
owns the selected base controls, exact compact program/key/sample mappings
in all six banks, authored startup difference, eight resource dialogue rows,
physical PLVOICE members, selected frame/state dialogue producers and native
combo command selectors with their other-participant gates.

**Coverage limits:** retained resource-45 concrete methods and helpers are
compared above; their inherited mask/effect services and selected action-range
semantics and enclosing CCS provider retention/release remain open.
The linked audio comparison bounds the selected voice producer paths;
spoken content remains unestablished.
The donor powers' gameplay payload, consumers and lifetime are established in
[Power effects](#power-effects);
their controller entry is in
[Awakening](#ultimate-jutsu-and-effects).
The character comparison does not assert
a complete fighter or cinematic equivalence.

## Callbacks

The exact checked pairs are NUN4 Shizune 27 / NA2 Shizune 85 and NUN4
Kabuto 28 / NA2 Kabuto 90. Static callback tables, records and changed
ordinary animation rows are in
[Character assets](#records-moves-and-assets).
Action indices below are local authored indices, not Ultimate Jutsu skills.

**Shizune:** donor `shizune_channel1` (`0x00264ED0`) and NA2's
`0x002F01E0` both apply the checked HP/chakra cadence for major state 0,
substate 3, phase 1. The donor also creates particles around a body anchor
or fallback position and emits positional audio `0x1020/0x101F`; the
NA2 routine ends after the cadence call.

Donor `shizune_channel2` (`0x00265600`) uses producer `0x31` at action
`0x1B`, primary marker 19. NA2
`fighter_outcome_callback_002f0520` (`0x002F0520`) uses producer `0x37`
and publishes the outcome at the same action/marker. The NA2 routine also
emits positional `0x1030` at action 0, primary marker 1; the donor does not
have that branch. These checks do not establish identical thrown objects,
since the producer-number domains differ.

**Kabuto:** donor `kabuto_channel1` (`0x00266430`) checks major state 0,
substate 3, zero halfword `+0x946`, phase 2 and secondary marker 0, then
calls its HP/chakra cadence helper with floats 0.125/5. NA2's corresponding
callback at `0x002F8840` is `jr ra; nop`.

Donor `kabuto_channel2` (`0x002664E0`) uses primary markers 13/22 for
action `0x1A`, emits effect `0x23` and pseudo-voice selector `-2`.
NA2's `0x002F8850` uses markers 4/13 and pseudo-voice `-4` for that
same local action. For action 4 in phase 1, donor secondary marker 0
replaces NA2 marker 5. Other inspected positional-audio branches have
matching action/marker pairs. Sample and audible-content identity are not
established by matching event codes.

These are static callback differences. Complete input admission and every
response-callback branch are outside this bounded comparison.

## Ultimate Jutsu and effects

Checked characters are NUN4 Shizune **27** and Kabuto **28**, against
retail NA2 Shizune **85** and Kabuto **90**. Their UJ record joins are
owned by [the cinematic comparison](#cinematics);
the matching gameplay payloads, consumers and independent visual lifetime
by [Power effects](#power-effects).

| Current fighter | Trigger flags / address | Association / address | Selected power entry |
| --- | --- | --- | --- |
| NUN4 Shizune 27 | `0x40`, `shizune_awakening_flags 0x0059230B` | `{0x26,1}`, `shizune_awakening_association 0x005924F8` | UJ 60, class 7, effect `0x26` |
| NUN4 Kabuto 28 | `0x40`, `kabuto_awakening_flags 0x0059230C` | `{0x27,1}`, `kabuto_awakening_association 0x00592500` | UJ 63, class 7, effect `0x27` |
| NA2 Shizune 85 | `0x41`, `awakening_triggers[85] 0x005C1CA4` | `{0x58,0x59}`, two-member family at `0x005C1FD8` | UJ 195 class 7; UJ 196 cinematic post-effect `0x58` |
| NA2 Kabuto 90 | `0x01`, `awakening_triggers[90] 0x005C1CB8` | `{0x5E,1}`, `0x005C2000` | UJ 211 cinematic post-effect `0x5E`; no selected class-7 record |

NUN4 `awakening_dispatch` (`0x001F4B80`) tries class-7 flag `0x40`
before marked reconciliation. `awakening_enter_class_seven`
(`0x001F3FB0`) requires major 8, current-record category mask `0x00F00000`,
flag `0x00010000`, an available action record, phase 2 and secondary
timeline event 0. It removes the current ID's associated effects below
`0x5A` with reason 1, then applies the selected effect with default
lifetime and local route 1. Matching the association sets fighter
`+0x63` bit `0x20`; application itself returns no success status.
The donor flags contain neither ordinary progress nor existing-effect
adoption, and both families contain only their single power.

NA2 `awakening_enter_class_seven` (`0x0020D690`) implements that route in
the native action/list layout and skips family removal only for IDs `0x68+`.
Shizune's two native family members are both removed before selected
`0x58` is applied. No checked class-7 Shizune record selects `0x59`.
`input_sector_widen_state_a` (`0x0020D030`) also adopts existing
Shizune `0x58` or Kabuto `0x5E`, explaining the native cinematic route.
Kabuto's flag `0x01` supplies adoption rather than the donor's class-7 route.

NUN4 `awakening_reconcile_marker` (`0x001F4690`) takes its ordinary
association branch for IDs 27/28: retain the marker while the respective
power is present, clear it when absent. NA2 `awakening_reconcile`
(`0x0020DDC0`) similarly checks the native families. Generic effect expiry
has no marker-clear callback; a later admitted reconciliation does that.
The controller's suppression/pause gates can clear or defer marker handling
independently of active gameplay nodes.

None of these selected effects chooses another fighter ID through either
game's form map. Construction and scalar consumers retain the actual
Shizune/Kabuto identity; the effect number and controller marker are
separate state. This establishes no body reconstruction dependency for
the four powers, without asserting arbitrary indirect service equivalence.

## Power effects

Checked identities are **NUN4 Shizune 27 (`szn`) / Kabuto 28 (`kbt`)**
in `SLUS_218.62`, against **retail NA2 Shizune 85 (`szw`) / Kabuto 90
(`kbw`)** in `SLPS_258.37`. These are the class-7/associated power
effects, distinct from the ordinary jutsu actors' contact effects.
Their entry/marker routes belong to
[Awakening](#ultimate-jutsu-and-effects).

### Gameplay payload and consumers

| Pair | NUN4 definition / NA2 factory anchor | Default lifetime | Recurring HP delta, exact bits |
| --- | --- | ---: | --- |
| Shizune `0x26 / 0x58` | `shizune_medical_effect_definition 0x00571C38` / `effect_58_definition 0x005A0504` | 600 | `0x39DA740E`, approximately `0.00041666668` |
| Kabuto `0x27 / 0x5E` | `kabuto_recovery_effect_definition 0x00571CA4` / `effect_5e_definition 0x005A075C` | 450 | `0x3A11A2B4`, approximately `0.00055555557` |

Both pairs have null concrete factories, flags `2`, HP boundary `1`, and
exactly matching **all twenty copied words after ID**: node `+0x6C..+0xB8`.
NUN4's definition stride is `0x6C`; NA2's factory-anchor stride is `0x64`.
The different row layouts and IDs do not change the copied scalar payload.

Both powers carry attack `1.2`, defense `1.1`, action rate `1.2`,
jump height `1`, knockback `1.1`, size `1`, HP-recovery factor `1`,
chakra-recovery factor `1`, and zero guard-damage/hit-chakra-debit maxima.
All entry, zero-exit and recurring chakra deltas are zero.
The HP delta is a direct recurring contribution, not an HP-recovery
multiplier, chakra gain, or constructor-time healing burst.

NUN4 `fighter_projectile_scalar` (`0x002D0170`) and
`effect_defense_factor` (`0x002D0220`) fold active nodes as
`1 + sum(value - 1)`, with upper attack cap 2 and lower defense cap 0.25.
`damage_calculate` (`0x0020CF40`) uses them only under flags `0x10/0x20`;
defense becomes `max(0.1, 2 - fold)`. A sole power therefore supplies
attack `1.2` and incoming-damage factor approximately `0.9` on those
enabled calculator paths. This does not multiply every damage request.

`fighter_effect_rate_factor` (`0x002D02D0`) folds node `+0x7C`, caps at
1.25 and returns neutral under its restore gate, majors 5/6 or its
major-8 category gate. `fighter_knockback_scalar` (`0x002D08D0`) folds
node `+0x84` without a local clamp. The checked
`fighter_apply_motion_record` (`0x00202100`) source path multiplies planar
motion by that nonneutral fold and vertical motion by half its deviation
from 1: a sole power contributes `1.1/1.05` there. These own-game
reducers have the native semantics described above, with fighter list
offsets translated from NUN4 `+0x8B4/+0x8B8` to NA2 `+0x8C4/+0x8C8`.
They depend on nonzero node lifetime, not awakening marker or character ID.

NUN4 `effect_hp_contribution` (`0x002D04B0`) sums active node `+0xAC`
and uses the maximum positive boundary from `+0xB0`. For a sole power,
HP at or below 1 admits its full positive delta; HP above 1 suppresses it.
`fighter_update_timed_effects` (`0x002CEF50`) calls this before countdown
under its separate resource gates. `effect_apply_hp_contribution`
(`0x002CF5D0`) additionally checks suppression and both fighters'
contribution blockers, then calls `fighter_hp_add` (`0x0020CE00`) with
feedback flags `0/0`. The adder requires the life flag and caps HP at 1.
Neither helper scales this delta by action rate or HP-recovery factor.
Default countdown alone therefore does not establish realized total healing
or wall-clock duration: resource and countdown admission are separate.

### Construction, replacement and removal

`fighter_apply_timed_effect` (`0x002CF220`) classifies both donor effects
as category 1. Route 1 with flags `2` applies only locally; there is no
opponent-propagation bit `4`. Input lifetime -1 selects the finite default;
`effect_resolve_duration` (`0x002CFF10`) preserves these 600/450 values.
`fighter_insert_timed_effect` (`0x002CE7F0`) removes a replaceable same-ID
node with reason 5 before allocating its common `0xC0` replacement.
Different IDs can coexist. A stored -2 would block replacement, but neither
selected default authors that sentinel.

`timed_effect_construct` (`0x002CDE80`) installs
`timed_effect_vtable` (`0x005EBC30`) and copies the payload without any
character-specific factory, model/player allocation or identity write.
On admitted countdown passes `timed_effect_tick` (`0x002CE2F0`) subtracts
one from positive lifetime. The extra input-mask debit applies only to IDs
0/1, not these powers. At zero their final resource deltas are zero and
`timed_effect_expiry_noop` (`0x002CE420`) does nothing before reason-0
removal. `effect_major8_hold_allowed` (`0x002CFA00`) recognizes only
effect `0x1B`; neither power takes that deferred-removal path.

`fighter_remove_timed_effect` (`0x002CE600`) unlinks through generic list
destruction. `timed_effect_destroy` (`0x0023FDA0`) runs
`timed_effect_cleanup` (`0x002CE1A0`) and base destruction, then optionally
frees the node. Natural category-1 expiry emits effect-event index `0x0B`;
forced removal skips that event. Neutral size requires no inverse size
write. Scalars stop contributing because the node leaves the list; no
private restoration callback is needed. Marker cleanup is a separate later
association reconciliation. Native generic lifetime/replacement/removal
has the same behavior for effects `0x58/0x5E`.

### Separate presentation lifetime

Successful donor insertion calls `effect_notify_application`
(`0x0032C6E0`), but neither ID occurs in its twelve-row notification map
(`0x00578E50`). They also take no low-ID application positional-feedback arm.
Category 1 instead appends a separate visual through
`effect_aux_visual_create` (`0x0031A920`), with interface
`effect_aux_visual_vtable` (`0x005ED460`).

`effect_aux_visual_construct` (`0x0031A090`) selects default texture
`TEX_mode1name1` for both powers. It borrows `modename/mode1cmn.ccs`
(`0x005C5870`), owns two `0x120` players for side-selected
`ANM_mode1name_01/02` and `ANM_mode1name_ca`, and owns a `0x40`
composition. The side-selected loaded provider supplies `MDL_mn_panel` /
`MAT_joutai` and the texture, which is rebound only when all three exist.
The forwarded control-selector argument is not a character ID; the label
depends on the recipient's loaded side provider.

`effect_aux_visual_update` (`0x0031A740`) waits on its own primary animation,
then uses a countdown of 3. Missing common resource instead sets 10.
`effect_aux_visual_destroy` (`0x00319FB0`) releases both players and the
composition. It has no gameplay-node backpointer or 600/450 countdown
dependency. The native compositor selects the same names and texture
selector for `0x58/0x5E`; gameplay expiry and label completion remain
independent in both games.

**Evidence limits:** the comparison establishes code-selected common and
side-provider dependencies, not pixel/content equivalence of those donor
and native labels. Exact label asset contents are an independent question
if identical donor presentation is required. The direct character-callback
screen finds no power-ID application/removal/membership calls in the six
checked Shizune/Kabuto channels per game; it does not exclude arbitrary
indirect consumers elsewhere.

## Cinematics

The exact pairs are NUN4 Shizune 27 / NA2 Shizune 85, and NUN4 Kabuto 28 /
NA2 Kabuto 90. Fighter and ordinary-jutsu evidence belongs to
[Character assets](#records-moves-and-assets).
Clean request data comes from each game's `STRMCMN.CCS`; complete file
identities are in [Retail game file identities](../../../game/files/file_identities.md#shizune-and-kabuto-comparison-inputs).

**Resident observations:** NUN4 `shizune_ultimate_record_list`
(`0x00607D08`) contains 59/60/61; `kabuto_ultimate_record_list`
(`0x00607D10`) contains 62/63/64. Their defaults are 59/62 through
`jutsu_character_default_record` (`0x003CCCE0`). NA2's same-name lists
at `0x00604500/0x00604520` contain 194/195/196 and 210/211/212.
NUN4 English `shizune_ultimate_records` (`0x0086FEC0`) and
`kabuto_ultimate_records` (`0x0086FEF0`) use stride `0x10`; NA2's
`0x005AFB68/0x005AFCA8` use stride `0x14`.

| Exact fighter | Record; category; class; stored cost tier; authored skill; damage |
| --- | --- |
| NUN4 Shizune 27 | `59; 2; 3; 0; 0x3D; 25` — Tonton Combo |
| Same | `60; 3; 7; 2; none; 0` — effect `0x26` |
| Same | `61; 1; 3; 1; 0x3C; 35` — Great Cross Slash |
| NA2 Shizune 85 | `194; 2; 3; 0; 0xA1; 25` — Great Cross Slash |
| Same | `195; 3; 7; 1; none; 0` — effect `0x58` |
| Same | `196; 1; 3; 2; 0xA2; 35` — Tonton Combo; effect `0x58` |
| NUN4 Kabuto 28 | `62; 2; 3; 0; 0x3E; 25` — Dead Soul Jutsu |
| Same | `63; 3; 7; 2; none; 0` — effect `0x27` |
| Same | `64; 1; 3; 1; 0x3F; 35` — Chakra Scalpel |
| NA2 Kabuto 90 | `210; 2; 3; 0; 0xAC; 25` — Dead Soul Jutsu |
| Same | `211; 3; 3; 1; 0xAD; 45` — Chakra Scalpel; effect `0x5E` |
| Same | `212; 1; 3; 2; 0xAB; 35` — `死術・帰魂遊戯` (Returning Soul technique) |

Record indices and authored skill indices are different domains. In
particular, donor record 59 (`0x3B`) executes authored skill `0x3D`,
not authored skill `0x3B`. Titles above are joined through SINF display
names and paths, rather than inferred from neighbouring English strings.
NUN4 `jutsu_record_form_character` (`0x003CCD00`) maps only effects
`0x5A..0x64` to alternate fighter IDs; effects `0x26/0x27` return zero.
NA2's medical/recovery effects and its form map are owned by
[Awakening](../awakening.md); no separate Shizune/Kabuto fighter form is
established by these selected records.

| Shared technique | NUN4 / NA2 skill | Resident request / streamed request | Authored frame range; camera ID NUN4 / NA2 |
| --- | --- | --- | --- |
| Great Cross Slash | `0x3C / 0xA1` | `str/d27_10e.ccs` / `str/d27_10.ccs` | `0..325`; `1016 / 1016` |
| Tonton Combo | `0x3D / 0xA2` | `str/d27_20e.ccs` / `str/d27_20.ccs` | `0..515`; `682 / 682` |
| Dead Soul Jutsu | `0x3E / 0xAC` | `str/d28_10e.ccs` / `str/d28_10.ccs` | `0..360`; `1368 / 1369` |
| Chakra Scalpel | `0x3F / 0xAD` | `str/d28_20e.ccs` / `str/d28_20.ccs` | `0..407`; `508 / 508` |

Each checked SINF row has one main resident request, one stream pair and
zero extra resident requests. NUN4 rows have stride `0x14`, NA2 `0x18`.
NA2 `0xAD` additionally has one authored appearance substitution at
appearance index 133; the other three NA2 rows have none. NUN4's checked
SINF layout has no corresponding appearance-list fields. NA2 `0xAB`
instead selects `str/d90_10e.ccs` / `str/d90_10.ccs`.

**Clean-file observations:** sequential frame-block walks terminate at the
final `-1` marker and reach each complete stream's end. All four pairs have
identical marker sequences and identical `0x0502` camera payloads after the
directory ID; the Dead Soul ID changes as shown above. Other scene bytes
differ: total dispatched blocks are NA2/NUN4 `101444/101444`,
`152468/152234`, `154736/154750` and `92841/92888`. Both files in every
resident/stream pair differ as complete files. The matching selected hit
rows and differing intro cues are owned by
[Battle audio](#shizune-and-kabuto-selected-cinematic-rows).

### Shizune/Kabuto non-camera scene records

The complete frame walks use the consumers' widths rather than declared
block lengths. NUN4 `ccs_parse_streamed_block_range` (`0x001B8940`)
dispatches the same eighteen frame tags as NA2. The checked differing tags
have matching input contracts in their own games:

| Frame tag | NUN4 / NA2 consumer | Meaning of the compared fields |
| --- | --- | --- |
| `0x0101` | `ccs_frame_tag_0101`, `0x001B92C0 / 0x001B5900` | Conditional position/scale, Euler degrees, alpha and visibility; consumes fields before target lookup. |
| `0x0201` | `ccs_frame_tag_0201`, `0x001B8DA0 / 0x001B5400` | Conditional material parameters; both use the six-float branch at version `0x120`. |
| `0x1A01` | `ccs_frame_tag_1a01`, `0x001BA960 / 0x001B6E40` | Two conditional floats and a third four-byte field, integer at version `0x111`. |
| `0x1C01` | `ccs_frame_tag_1c01`, `0x001BACF0 / 0x001B71A0` | Three conditional floats and a conditional two-float pair. |

Full widths and destination fields remain owned by
[Frame stream](../../../game/files/ccs_runtime.md#frame-stream).
Correspondence below removes each record's target ID, joins target names,
and normalizes the fighter codes `szn/szw` and `kbt/kbw`. Namespace and
provider bindings are checked separately below; this name comparison alone
does not establish equivalent model instances. There are no queued `0x0108`
commands in any of these eight streams. The changed participant motion is
authored as frame snapshots, rather than ordinary fighter action rows.

| Pair | Non-camera frame differences |
| --- | --- |
| `D27_10` | Only `0x0101` differs after target correspondence: 1,667 frame/target groups. Changes include Tonton's hierarchy, local rock/particle transforms and `OBJ_con_lig`. Changed fields are position, rotation and scale; matching targets retain alpha/visibility. |
| `D27_20` | Transform records differ. NA2 adds `eye1`, `eye2`, `mou1` records for `OBJ_1szw00t0` at frames `108..185`: 78 each, accounting for all 234 additional blocks. The second Shizune hierarchy is renamed and reordered as described below. |
| `D28_10` | NA2 adds 361 `OBJ_rev01` transforms at `0..360` and omits 375 common-defender face transforms: `OBJ_1cmn00t0 eye1/eye2/mou1` at `236..360`, 125 each. Shared transforms differ; `OLP_out00_world02` has differing `0x1A01` float words in 69 frames. |
| `D28_20` | Donor-only transforms address `OBJ_e28flo01` at `187..231` and `OBJ_e28ngr01` at `233..234`, accounting for the 47-block difference. Shared transforms differ; `OLP_out_kbt` and `TSP_tone21_kbt` float words differ throughout all 408 frames, and the mouth material differs at `355..362`. |

For matched target names, alpha changes occur in three records each in
`D27_20/D28_10` and 24 in `D28_20`; visibility and transform flags agree.
The outline/tone float differences include small rounding differences:
`D28_20` frame-zero outline second-field words are donor `0x3F19998A`
and native `0x3F199991`. They are distinct stored values; their visible
significance is not established. The mouth material change is larger:
after ID and zero flags, donor `MAT_kbtmou1` has
`(0.75,0.25,0.25,0.25,0,1)`, native `MAT_kbwmou1` has
`(0.5,0.75,0.25,0.25,0,1)` for those eight frames.
All other frame-tag payloads agree under the stated target correspondence,
including `0x1901` morpher weights and source names in `D27_20/D28_20`.

`D27_20`'s second body illustrates why directory-ID or substring replacement
alone does not establish the binding. Donor wrapper row 335,
`OBJ_1szn00t0 body01`, stores `{335,274,828}`: local parent
`OBJ_1szn00t0 pelvis01` and marked body target in `1sznbod1.max`.
Native row 678, `OBJ_1szw01t0 body`, stores `{678,617,957}`:
local parent `OBJ_1szw01t0 pelvis` and marked `00t0 body` target in
`1szwbod1.max`. NUN4 `ccs_parse_external_object` (`0x001B5F70`)
and NA2 `ccs_parse_external_record` (`0x001B2800`) consume own/parent/target
IDs, create the wrapper, and rewrite its `OBJ` prefix to `EXT`.
The second hierarchy is a separate transform instance of the same body
provider, not another selected fighter form. The wrapper parser does not
request a file from the marked namespace.

Native Dead Soul's `OBJ_rev01` is a local `0x0100` object parented to
`OBJ_cmrbox`, selecting local `MDL_rev01` and `MAT_rev01`, whose texture
is `TEX_e00white01`. Native `BIN_strrev_data_kbw` selects this object
for skill `0xAC`: hidden initially, enabled at frame 235 and disabled
at 263, with render group 10. Its loader and draw-mode consumer are owned
by [Per-character switches](../ultimate_jutsu_cinematics.md#per-character-texture-and-draw-state-switches).
Donor Chakra Scalpel's two omitted transform targets
are external wrappers: `e28flo01` is parented to local `OBJ_bg`,
`e28ngr01` to `OBJ_cambox`; their typed object/model providers occur in
the matching `D28_20E`. Names alone do not establish their visible purpose.

### Shizune/Kabuto providers and authored appearance

The marked stream keys number `251/218/286/212` for the four pairs in
table order, in both games. Marked resident keys number donor `0/1/0/1`
and native `0/2/0/1`. Every key resolves to a non-carrier typed definition
against its own resident/stream pair, own fighter `PL/1SZNBOD1` or
`PL/1KBTBOD1` (native `1SZWBOD1/1KBWBOD1`), `PL/1CMNBOD1`,
`STRMCMN` and `CMN/EFFECT0X`. Keeping the donor pair/body and using the
three native common providers also leaves zero missing keys in every pair.
The resident `TEX_sampling00` imports resolve to native `EFFECT0X`'s
typed sampling texture, which has no pixel payload. The parser accepts
typed definitions with marked namespaces; filtering them out would give
an incorrect missing-provider result.

This is a directory/typed-record audit, including complete frame walks.
Resident model boundaries were located at subsequent typed headers;
every nested geometry field, matrix-palette binding and wrapper lifetime
was not decoded. Provider matches do not establish those remaining properties.

Common resident texture pixels/palette colors match in the two Shizune
pairs. Both Kabuto resident pairs instead change the pixels of
`TEX_e28kbt01` and colors of `CLT_e28kbt01`; all other corresponding
resident pixel/color payloads agree. Both native Kabuto files add
`CLT_e28kbt01c1/c2`. Stored object families also differ: donor
`D27_10E` has `e00back40s`; donor `D27_20E` has `e27sznda/e00line10`
where native adds `e00board01_b/_w`; donor `D28_10E` adds
`e28fog00/e28tndp01a/b/c/e28tir01/e29rai_sg01` families.
Stored presence alone does not establish a streamed draw.

NA2 skill `0xAD`'s SINF appearance row 133 is
`{source container null, CLT_e28kbt01, EXT_e28kbt01}`; null source
selects the resident main container. `sp_skill_apply_external_palette`
(`0x00357FE0`) retains the full base palette name and appends `c1`
for appearance flag bit 0, otherwise `c2` for bit 2, then rebinds the
target model palettes. NUN4's own helper (`0x0032D9D0`) instead trims
two trailing palette-name characters before adding its suffix, and its
descriptor fields use a different order. All four selected donor resident
palette descriptors at `0x005799F0..0x00579A0F` are zero; native
`0xA1/0xA2/0xAC` have no SINF appearance row. Adding native color
sets in Dead Soul's file therefore does not establish this Chakra Scalpel
substitution there. Participant-body appearance selection/restoration is
separate and follows the general bindings above.

### Shizune/Kabuto offsets, filters and resident scripts

Each pair's `BIN_strfilter_*` CCFM payload is byte-identical: lengths are
6,244 / 1,680 / 3,444 / 2,740 bytes in table order. The
`BIN_damoffs_*` blobs differ. NUN4 `sp_skill_parse_defender_offsets`
(`0x0032D340`) and NA2's counterpart (`0x003579A0`) read `_damOffs`,
version `0x100`, phase count at `+0xA`, defender count at `+0xC`,
then short thresholds at `+0xE` followed by defender-major arrays of
phase-count signed-short XYZ triples. Both frame callbacks index by the
actual defender ID and translate by the selected phase triple.

| Pair | Phase thresholds, identical in both | Donor / native defenders | Donor / native blob bytes | Equal same-index entries among donor's first 78 |
| --- | --- | --- | --- | ---: |
| `D27_10` | `1,72,223` | `78 / 94` | `1424 / 1712` | 59 |
| `D27_20` | `1,101,231,322` | `78 / 94` | `1896 / 2280` | 24 |
| `D28_10` | `1,145,177,235` | `78 / 94` | `1896 / 2280` | 20 |
| `D28_20` | `1,102,127,140,150,186,255,296` | `78 / 94` | `3776 / 4544` | 55 |

The character-domain change is not the entire difference. In `D27_10`
phase 2, donor Shizune 27 has `(4,-1,-28)` versus native Shizune 85's
`(7,13,-25)`; donor Kabuto 28 has `(3,0,-23)` versus native Kabuto
90's `(7,0,-21)`. Native's parser supplies cleared fallback arrays for
IDs beyond a short blob's declared defender count; it does not remap
donor IDs to same-name native fighters.
NA2 additionally applies `shizune_tonton_defender_position_rule`
(`0x005A95F0`) through `sp_skill_adjust_defender_position`
(`0x003571F0`): skill `0xA2`, defender 75, inclusive frames `101..230`
replace the translation vector with `(0,3,-2,1)`. The other three
selected native skills have no entry in this fifteen-header rule table.

NUN4 Dead Soul skill `0x3E` has resident script
`kabuto_dead_soul_scene_frame_script` (`0x005C7290`), selected by the
pointer at `0x005795F0`: words `{1,234,2,262,0,0}`. Its
`sp_skill_play_frame` (`0x0032F200`) runs script rows when the threshold
is strictly below the current integer frame. Operation 1 allocates the
device-alpha helper at frame 235, operation 2 releases it at 263; the
negative-rate reset also releases it and restores the script pointer.
The other three selected donor scripts are null, as are all four
corresponding native script entries (native Dead Soul at `0x005AB62C`).
NA2 `sp_skill_play_frame` (`0x0035B740`) already implements the same
operation-1/2 script interpreter and cleanup, separately from CCS queued
commands and counted damage/cue rows.

The script helper is a one-byte allocation used as an enable flag;
`device_alpha_helper_construct` (`NUN4 0x0010C150`, NA2 `0x0010BED0`)
calls a no-op initializer and returns that pointer. The donor frame callback
uses `draw_environment_device_alpha_pass` (`0x0010BFA0`) while it is
nonnull: an `0x80`-byte packet with the active renderer's device rectangle,
ZBUF write mask, `TEST=0x1001`, `ALPHA=0x80000000A4` and
`RGBA=0x3F80000080FFFFFF`. This is a different drawing mechanism from
native Dead Soul's local-object draw switch, with the same authored
`235..262` interval. Timing agreement does not establish equal output.

The remaining independent scene questions are the full typed nested
geometry/matrix-palette routes and all imported participant-wrapper
lifetimes for these exact pairs. The stored non-camera frame changes,
named provider matches, selected appearance rows, offset format/filter
identity and selected resident script are established above.

## Voice

### Shizune and Kabuto ordinary-jutsu voice

Checked identities are **NUN4 Shizune 27 / Kabuto 28**, in both English
and Japanese banks, and **NA2 Shizune 85 / Kabuto 90**. These are separate
compact SNDDATA and streamed PLVOICE selections. The four donor ordinary
jutsu are resources 57/58 (Shizune) and 45/46 (Kabuto); native resources
are 174/175 and 184/185.

#### Selected compact controls and samples

The annotated `shizune_voice_event_pair` and `kabuto_voice_event_pair`
rows are NUN4 `0x004366F0/0x004366F8` and NA2
`0x00406F80/0x00406FA8`. Each stores the base list twice:
NUN4 `0x00591DD0`, NA2 `0x005C16C0`.
Their own `fighter_voice_event_list` routines
(`0x001EA080/0x00203E90`) have no alternate-selection branch for these
IDs. Donor language selection changes the loaded bank, not this event list.
Consequently controls from the +110/+160 lists are not selected here.

The 33 ordered base controls, in decimal, are
`0,1,2,3,4,5,6,7,8,12,13,14,15,16,17,18,19,20,21,22,23,24,25,28,26,27,38,39,40,23,36,37,41`.
All enabled selected controls use the same-numbered program and default
key **60 (`0x3C`)** in both games. Event 25 selects disabled control 27;
event 32 selects disabled control 41. Event 23 selects enabled control 28,
but program 28 is absent in all six inspected banks, so it produces no
sample candidate. Donor program 27 exists, but its presence does not enable
the disabled base control.

The [compact lookup](../../session/battle_audio.md#compact-program-to-vag-lookup) decodes every remaining
selected program below. Each has exactly one split, index **0**, key range
**12..119**, one Sset sample, and both Sset/sample velocity ranges **1..127**.
A positive velocity in that range selects the listed candidate; velocity zero
is note-off. All listed samples have group 0, priority 10, mix byte
`0x03`, rate 22050 Hz and VAG flags 0. These are lookup results, subject to
the established packet, bank, quota and allocation admission rules.

Tuple columns are **Sset / Smpl / Vagi indices**, in decimal. Donor tuples
apply independently to Shizune English/Japanese and Kabuto English/Japanese;
native tuples apply independently to Shizune 85 and Kabuto 90.

| Base event | Control / program | NUN4 tuple | NA2 tuple |
| --- | --- | --- | --- |
| 0 | 0 | 0/0/3 | 0/0/3 |
| 1 | 1 | 1/1/4 | 1/1/4 |
| 2 | 2 | 2/2/5 | 2/2/5 |
| 3 | 3 | 3/3/6 | 3/3/6 |
| 4 | 4 | 4/4/7 | 4/4/7 |
| 5 | 5 | 5/5/8 | 5/5/8 |
| 6 | 6 | 6/6/0 | 6/6/0 |
| 7 | 7 | 7/7/1 | 7/7/1 |
| 8 | 8 | 8/8/2 | 8/8/2 |
| 9 | 12 | 9/9/18 | 9/9/17 |
| 10 | 13 | 10/10/19 | 10/10/18 |
| 11 | 14 | 11/11/20 | 11/11/19 |
| 12 | 15 | 12/12/21 | 12/12/20 |
| 13 | 16 | 13/13/22 | 13/13/21 |
| 14 | 17 | 14/14/23 | 14/14/22 |
| 15 | 18 | 15/15/15 | 15/15/14 |
| 16 | 19 | 16/16/16 | 16/16/15 |
| 17 | 20 | 17/17/17 | 17/17/16 |
| 18 | 21 | 18/18/24 | 18/18/23 |
| 19 | 22 | 19/19/26 | 19/19/25 |
| 20, 29 | 23 | 20/20/27 | 20/20/26 |
| 21 | 24 | 21/21/28 | 21/21/27 |
| 22 | 25 | 22/22/25 | 22/22/24 |
| 24 | 26 | 23/23/29 | 23/23/28 |
| 30 | 36 | 25/25/14 | 24/24/13 |
| 31 | 37 | 26/26/13 | 25/25/12 |
| 26 | 38 | 27/27/10 | 26/26/9 |
| 27 | 39 | 28/28/11 | 27/27/10 |
| 28 | 40 | 29/29/12 | 28/28/11 |

The exact absolute **SNDDATA.BIN sample starts** are:

| Program | Shizune 27 English | Shizune 27 Japanese | Kabuto 28 English | Kabuto 28 Japanese | Shizune 85 NA2 | Kabuto 90 NA2 |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | `0x00B1A700` | `0x01E9C0F0` | `0x00B59340` | `0x01ED4220` | `0x014243B0` | `0x014FEDB0` |
| 1 | `0x00B1B2F0` | `0x01E9C710` | `0x00B5A5B0` | `0x01ED5290` | `0x01424B50` | `0x014FFAB0` |
| 2 | `0x00B1C3D0` | `0x01E9D0C0` | `0x00B5B040` | `0x01ED59F0` | `0x01425880` | `0x01500230` |
| 3 | `0x00B1DBD0` | `0x01E9DF90` | `0x00B5C1C0` | `0x01ED6030` | `0x01426550` | `0x01500B80` |
| 4 | `0x00B1FD00` | `0x01E9FCC0` | `0x00B5D7A0` | `0x01ED6C00` | `0x01427B10` | `0x015017D0` |
| 5 | `0x00B210F0` | `0x01EA0900` | `0x00B5F650` | `0x01ED7940` | `0x014295C0` | `0x015024A0` |
| 6 | `0x00B13800` | `0x01E96000` | `0x00B52800` | `0x01ECD000` | `0x0141D800` | `0x014F7800` |
| 7 | `0x00B16170` | `0x01E985A0` | `0x00B545B0` | `0x01ECE980` | `0x01420440` | `0x014F9290` |
| 8 | `0x00B17ED0` | `0x01E99990` | `0x00B56CC0` | `0x01ED1490` | `0x01421E10` | `0x014FC000` |
| 12 | `0x00B3C810` | `0x01EB9070` | `0x00B7CD20` | `0x01EF3550` | `0x0143E5D0` | `0x0151C880` |
| 13 | `0x00B3D760` | `0x01EB9C80` | `0x00B7DB50` | `0x01EF3FA0` | `0x0143FAC0` | `0x0151CF00` |
| 14 | `0x00B3EB60` | `0x01EBB2C0` | `0x00B7E5D0` | `0x01EF4810` | `0x01440750` | `0x0151D800` |
| 15 | `0x00B41150` | `0x01EBD0B0` | `0x00B7F8D0` | `0x01EF5510` | `0x014424A0` | `0x0151EBA0` |
| 16 | `0x00B42AF0` | `0x01EBE190` | `0x00B80BA0` | `0x01EF61F0` | `0x01443850` | `0x0151F880` |
| 17 | `0x00B43CA0` | `0x01EBEFF0` | `0x00B82840` | `0x01EF7D80` | `0x01445F00` | `0x015211B0` |
| 18 | `0x00B35610` | `0x01EB3CA0` | `0x00B77030` | `0x01EEE470` | `0x01438CD0` | `0x015185B0` |
| 19 | `0x00B37B60` | `0x01EB5680` | `0x00B78940` | `0x01EEF840` | `0x0143A490` | `0x015197E0` |
| 20 | `0x00B3A190` | `0x01EB7040` | `0x00B7A600` | `0x01EF0F60` | `0x0143C1B0` | `0x0151AD90` |
| 21 | `0x00B45650` | `0x01EC0860` | `0x00B83BD0` | `0x01EF8CC0` | `0x01447420` | `0x015220C0` |
| 22 | `0x00B4ACE0` | `0x01EC55A0` | `0x00B888A0` | `0x01EFC610` | `0x0144C650` | `0x01526020` |
| 23 | `0x00B4BDB0` | `0x01EC6060` | `0x00B89C60` | `0x01EFD290` | `0x0144D410` | `0x01526BA0` |
| 24 | `0x00B4CBE0` | `0x01EC6760` | `0x00B8A840` | `0x01EFDA90` | `0x0144DB00` | `0x01527370` |
| 25 | `0x00B47400` | `0x01EC2940` | `0x00B85E30` | `0x01EFA290` | `0x014490C0` | `0x015234F0` |
| 26 | `0x00B4DA30` | `0x01EC73D0` | `0x00B8B310` | `0x01EFE330` | `0x0144E900` | `0x01527D50` |
| 36 | `0x00B2FF20` | `0x01EAE5E0` | `0x00B72820` | `0x01EE8220` | `0x01436050` | `0x01511E60` |
| 37 | `0x00B2D570` | `0x01EAC700` | `0x00B6E320` | `0x01EE4030` | `0x014331F0` | `0x0150DDF0` |
| 38 | `0x00B25FF0` | `0x01EA5C50` | `0x00B65C90` | `0x01EDC850` | `0x0142AE60` | `0x015044E0` |
| 39 | `0x00B285C0` | `0x01EA7DA0` | `0x00B687E0` | `0x01EDEE20` | `0x0142D7E0` | `0x01507310` |
| 40 | `0x00B2B4C0` | `0x01EA9F20` | `0x00B6B8D0` | `0x01EE1E70` | `0x01430280` | `0x0150ADC0` |

Header/sample ranges and descriptor rows belong to
[Character assets](#checked-sound-resources).
The decoded files have SHA-256
`CC24E6DB57639BBD005146CC3086E843DA9EB207EDC0085E15F17F5E5336951D`
(NUN4) and
`209598766499E52D40A2714579E818DCA2A4941885736B51AE887BA4FC96937C`
(NA2).

#### Jutsu participant compact selectors

The actor route uses a separate selector-to-control row rather than
`fighter_voice_event_list`. NUN4 `jutsu_participant_compact_cue_row`
(`0x0074B840`) indexes pairs at `0x00845390 + (actual fighter ID-1)*8`.
`shizune_jutsu_compact_cue_pair` (`0x00845460`) and
`kabuto_jutsu_compact_cue_pair` (`0x00845468`) both store
`0x0085A4F0` in both lanes, the shared annotated
`jiraiya_jutsu_compact_cue_row`. Neither ID has an alternate branch.
`jutsu_request_participant_compact_cue` (`0x0074B740`) passes the row's
signed halfword control directly to `battle_voice_control_by_object`
(`0x001D5900`) with default key -1. It checks the coordinator gate,
participant validity and the other participant's `+0xD0` cooldown;
passing those gates for the other participant sets that cooldown to 20
before the resident dispatcher applies its own suppression.

NA2's corresponding selector is `status_family_pointer_choose`
(`0x00770030`), consumed by `item_skill_event_service` (`0x0076FF40`)
and `battle_voice_control_by_object` (`0x001D4080`). Its ID-85 pair
`shizune_jutsu_compact_cue_pair` (`0x008A8060`) stores
`0x008CC3C0` twice. ID-90 `kabuto_jutsu_compact_cue_pair`
(`0x008A8088`) stores normal `0x008CC3C0`, alternate `0x008CC420`.
The selector has no ID-85/90 alternate branch, so both select the normal
row. The distinct stored Kabuto alternate pointer does not select a different
bank or establish reachability for playable Kabuto 90.

The normal rows agree in both games. Their first 32 controls, for actor
selectors 0..31, are
`0,1,2,3,4,5,8,7,8,12,13,14,15,16,17,18,19,20,9,10,11,22,23,24,25,26,27,38,39,40,36,37`.
Thus selector 6 selects **control/program 8**, not program 6;
selectors 18..20 select disabled controls 9..11, and selector 26 selects
disabled control 27. The other first-32 controls use key 60 and the exact
program tuples/offsets above. These are actor selectors, not fighter events.

The inspected shared row also stores controls 160..168 at selectors 32..40,
and 80..85 at selectors 41..46. In both resident control tables,
160..168 select programs 0..8 with key **62**, which remains inside the
same sole split and selects the same tuples/offsets as key 60. Controls
80..85 select program **53**, keys 60..65; program 53 exceeds the inclusive
Prog maximum **40** in all six banks and supplies no sample candidate.
The consumer does not check a selector count in its inspected body.
The selected producers below establish which of these stored selectors the
checked ordinary-jutsu paths request.

#### Authored startup requests

`fighter_schedule_action_audio` (NUN4 `0x001EA770`, NA2
`0x00204610`) reads the current action's signed voice and audio-time
fields when major state is 8 and category bit 2 is clear. NUN4 fields are
`+0x52/+0x54`; NA2 fields are `+0x42/+0x44`.
Voice -1 suppresses that request. Voice -2 draws inclusively from 0..3;
draw 3 suppresses, while 0..2 select base events 6..8 with default key 60.

The donor Shizune/Kabuto action arrays (`0x004A4530/0x004A9190`,
stride `0x64`) have voice -1 and time 0 in actions 0..3.
Their checked channel-2 callbacks (`0x00265600/0x002664E0`) add no
ordinary-action 0..3 voice branch. Native action arrays
(`0x00574210/0x00589CD0`, stride `0x54`) instead have voice -2,
time 8 in action 0; actions 1..3 have -1/time 0. Thus the native first
startup's possible compact samples are programs 6/7/8, split 0,
Sset/Smpl 6/7/8 and Vagi 0/1/2 at the native offsets above. The donor
authored startup path supplies no corresponding compact request.
This bounded observation does not establish that the complete jutsu actor
or its helper-generated effects are silent.

#### Streamed rows and physical members

`jutsu_dialogue_cue_row` (NUN4 `0x0074BA60`) selects
`0x00859FF0 + resource*8`; NA2 `dialogue_voice_row` selects
`0x008CB760 + resource*8`. Each row has four signed halfwords.
The immediate participant producer uses the actual participant fighter ID
and side slot; it is not a compact-program request.

| Actor / resource | Annotated row | Four indexed PLVOICE cues |
| --- | --- | --- |
| NUN4 Shizune 27 Tonton / 57 | `shizune_tonton_jutsu_voice_row`, `0x0085A1B8` | 116 / -1 / 116 / 116 |
| NUN4 Shizune 27 poison / 58 | `shizune_poison_jutsu_voice_row`, `0x0085A1C0` | 118 / -1 / -1 / -1 |
| NUN4 Kabuto 28 first jutsu / 45 | `kabuto_classic_chakra_jutsu_voice_row`, `0x0085A158` | 125 / 121 / 121 / 121 |
| NUN4 Kabuto 28 second jutsu / 46 | `kabuto_dead_soul_jutsu_voice_row`, `0x0085A160` | 121 / -1 / 123 / 121 |
| NA2 Shizune 85 first jutsu / 174 | `shizune_combo_jutsu_voice_row`, `0x008CBCD0` | 377 / 378 / -1 / -1 |
| NA2 Shizune 85 poison / 175 | `shizune_poison_jutsu_voice_row`, `0x008CBCD8` | 379 / -1 / -1 / -1 |
| NA2 Kabuto 90 first jutsu / 184 | `kabuto_chakra_combo_jutsu_voice_row`, `0x008CBD20` | 392 / 393 / -1 / -1 |
| NA2 Kabuto 90 second jutsu / 185 | `kabuto_dead_soul_jutsu_voice_row`, `0x008CBD28` | 394 / 395 / -1 / -1 |

NUN4 `kabuto_dead_soul_jutsu_set_state` (`0x007DBA90`) state 3
checks the audio set through `0x001D85B0`. Only set 1 (Japanese) calls
virtual +0xD4 with the source participant, index 2 and immediate flag 1.
The selected vtable resolves this to
`jutsu_request_participant_dialogue` (`0x0074B640`), hence cue **123**.
This explicit request selects Kabuto's Japanese member **11**.
NA2 `kabuto_dead_soul_jutsu_set_state` (`0x0086C6B0`) state 2 instead
calls virtual +0xD8 with source participant, index 1 and immediate flag 1.
Its vtable resolves to `dialogue_voice_produce` (`0x0076FE50`),
selecting native cue **395**, member **42**, without that language branch.

NUN4 `shizune_player_voice_cues` (`0x00435110`) is
`116,118,265,289,293,298,299,302,312,-1`;
`kabuto_player_voice_cues` (`0x00435130`) is
`121,123,125,265,289,293,298,299,302,312,-1`.
The list ordinal selects the English physical member; Japanese adds
9/10 through the descriptor's half-count. Shizune/Kabuto descriptors
`0x004362B0/0x004362B8` hold archive handles 147/148,
type 1, start 1 and counts 18/20. Their clean PLVOICE outer entries are
26/27 at `0x0052D000/0x0056C800`.

Native `shizune_player_voice_cues` (`0x003FF600`) has 41 entries;
its terminal 377/378/379 are ordinals 38/39/40.
`kabuto_player_voice_cues` (`0x003FF780`) has 43 entries;
392/393/394/395 are ordinals 39/40/41/42.
Descriptors `0x003FE290/0x003FE2B8` hold handles 234/239,
type 1, start 1 and counts 41/43. Their outer entries are 84/89,
at `0x01210000/0x013C3000`.

All nonnegative cues in the eight resource rows map to these exact physical
members. Offsets are absolute within the respective **PLVOICE.AFS**;
sizes are member payload bytes, excluding archive padding.

| Fighter / cue | English member / offset / bytes | Japanese member / offset / bytes |
| --- | --- | --- |
| NUN4 Shizune 27 / 116 | 0 / `0x0052D800` / `0x34C6` | 9 / `0x00550800` / `0x231E` |
| NUN4 Shizune 27 / 118 | 1 / `0x00531000` / `0x4349` | 10 / `0x00553000` / `0x2A89` |
| NUN4 Kabuto 28 / 121 | 0 / `0x0056D000` / `0x3594` | 10 / `0x0058B000` / `0x185F` |
| NUN4 Kabuto 28 / 123 | 1 / `0x00570800` / `0x3DC9` | 11 / `0x0058D000` / `0x3BDA` |
| NUN4 Kabuto 28 / 125 | 2 / `0x00574800` / `0x3A59` | 12 / `0x00591000` / `0x2D55` |

| NA2 fighter / cue | Physical member | Absolute offset | Payload bytes |
| --- | --- | --- | --- |
| Shizune 85 / 377 | 38 | `0x01272000` | `0x2EDE` |
| Shizune 85 / 378 | 39 | `0x01275000` | `0x2002` |
| Shizune 85 / 379 | 40 | `0x01277800` | `0x2AF9` |
| Kabuto 90 / 392 | 39 | `0x01411000` | `0x2391` |
| Kabuto 90 / 393 | 40 | `0x01413800` | `0x204B` |
| Kabuto 90 / 394 | 41 | `0x01416000` | `0x23BF` |
| Kabuto 90 / 395 | 42 | `0x01418800` | `0xD09` |

The checked archive identities are NUN4 14,446,592 bytes, SHA-256
`BC13E5DBD6E53C9D1327D89556AE37155340EEF7B79B451F50B8385866ACDD2A`,
and NA2 22,192,128 bytes, SHA-256
`A54F57FC690D3061F09291D72B6C9568FB09386E1A270AD4FB48A6A7673915F0`.

#### Selected dialogue producers

NUN4's four selected primary vtables install
`jutsu_update_resource_binding` (`0x0076FE70`) at +0x12C. After its
participant/status and elapsed-time gates, it compares actor `+0x1BC`
with four signed frame values at `0x0085A5B0 + resource*8` and calls
installed +0xD4 with source participant `+0x1E0`, row index and immediate
flag 1. All four selected frame rows are `0,-1,-1,-1`:

| NUN4 resource | Annotated frame row / live address | Eligible frame-0 request |
| --- | --- | --- |
| 45 | `kabuto_classic_chakra_dialogue_frames`, `0x0085A718` | Index 0 / cue 125 |
| 46 | `kabuto_dead_soul_dialogue_frames`, `0x0085A720` | Index 0 / cue 121 |
| 57 | `shizune_tonton_dialogue_frames`, `0x0085A778` | Index 0 / cue 116 |
| 58 | `shizune_poison_dialogue_frames`, `0x0085A780` | Index 0 / cue 118 |

These requests use either selected donor language. Resource 46's Japanese
state-3 request additionally selects index 2 / cue 123 as established above.
The stored index-1/3 cues are not requested by these frame rows.
The selected donor producers therefore join nine physical clips: Shizune
English members 0/1 and Japanese 9/10; Kabuto English 0/2 and Japanese
10/11/12. Kabuto's mapped English cue 123/member 1 has no request on
these selected paths.

NA2's selected primary vtables install `skill_primary_action_dispatch`
(`0x00795190`) at +0x130. Its admitted timing branch compares actor
`+0x1DC` with `0x008CBD90 + resource*8`, then calls installed +0xD8
with source participant `+0x200`, index and immediate flag 1.

| NA2 resource | Annotated frame row / live address | Four frames | Requested cue / frame |
| --- | --- | --- | --- |
| 174 | `shizune_combo_dialogue_frames`, `0x008CC300` | 70 / 0 / -1 / -1 | 378 / 0; 377 / 70 |
| 175 | `shizune_poison_dialogue_frames`, `0x008CC308` | -1 / -1 / -1 / -1 | None through this frame row |
| 184 | `kabuto_chakra_combo_dialogue_frames`, `0x008CC350` | 0 / 80 / -1 / -1 | 392 / 0; 393 / 80 |
| 185 | `kabuto_dead_soul_dialogue_frames`, `0x008CC358` | -1 / -1 / -1 / -1 | None through this frame row |

Resources 174/184 install `skill_primary_voice_produce_mode0`
(`0x007A3AE0`), which forces mode 0 and copies the cue into the source
participant FIFO. Thus these are queued requests despite the dispatcher's
flag 1. Resource 185 instead directly installs `dialogue_voice_produce`
(`0x0076FE50`); its state-2 index-1 request selects cue 395 immediately.
The checked selected frame, state and command paths supply no producer for
native stored cues 379 or 394.

NUN4's `jutsu_proxy_animation_event_bridge` (`0x0075BD60`) forwards
eligible participant animation commands through the resident fighter route
to `jutsu_active_primary_command_dispatch` (`0x007714F0`), which validates
the side's active primary and calls +0x138. Resources 45/57/58 install
`kabuto_classic_chakra_jutsu_post_update_noop` (`0x007D3C70`),
`shizune_tonton_jutsu_command_noop` (`0x00816A60`) and
`shizune_poison_jutsu_command_noop` (`0x00797690`): complete return-only
leaves. Resource 46's `kabuto_dead_soul_jutsu_command` (`0x007DB960`)
sets command latches and captures a transform; its dependent state path is
the Japanese request already identified. These callbacks add no row index.

Retirement adds no dialogue request. Donor `skill_primary_request_finish`
(`0x0075F590`) clears the source participant and contact lists. Tonton's
override `shizune_tonton_jutsu_request_finish` (`0x008175D0`) clears
two additional lists through `sk4_jutsu_request_finish` (`0x008102B0`)
before that same finish path. Native `skill_primary_request_retirement`
(`0x00785D60`) clears its participant header and query lists; combo
`skill_combo_phase3` (`0x0079B4F0`) reaches that retirement and an
installed return-only +0x24C. These checked exits do not consume the
otherwise stored row entries.

#### Selected compact producers and helpers

The checked donor primary methods, their direct callees, selected
participant-command bindings and presentation helpers have no call to
`jutsu_request_participant_compact_cue`. Together with the action-0..3
startup fields, this establishes no actor-owned compact selector on these
four donor paths. It does not classify unrelated fighter reaction audio.

NA2's `skill_bind_authored_audio_row` (`0x00796B40`) clears actor
`+0x154` and scans exactly 21 resource records at `0x008CCF90`, stride
`0x1C`. The selected 174/184 rows at `0x008CD070/0x008CD134` contain
17/12 global sound-effect entries, but both compact-lane counts are zero.
Resources 175/185 are absent. Consequently
`skill_dispatch_authored_audio_row` (`0x00796BA0`) supplies no source
participant compact selector for these resources. Global effects use their
own bank and are separate from the six character banks above.

Native first-jutsu compact requests instead come from authored scene
commands. `ccs_frame_tag_0108` (`0x001B69B0`) queues the target, two
values and current marker. The selected participant proxy binders install
`skill_dummy_player_event_bridge` (`0x007822C0`) at player +0xE8.
Value 1 `0x8003` with value 2 below `0x100` reaches the active primary's
+0x13C through `skill_primary_authored_event_relay` (`0x007966E0`).
Resources 174/184 install `skill_combo_accepted_event` (`0x0079BAB0`).
Its compact producer uses the **other participant**, `+0x3B0`:

| Checked native animation | Authored command / markers | Possible actor selectors |
| --- | --- | --- |
| `2SZWCHA0.CCS`, `ANM_pszwcha01`, ID 274 | 5 / 24,46,51,62 | 9..11 |
| Same animation | 2 / 32,39,100,103,106 | 15..17 |
| `2KBWCHA0.CCS`, `ANM_pkbwcha01`, ID 253 | 1 / 21,32,50 | 12..14 |
| Same animation | 2 / 118 | 15..17 |

Each request chooses a permuted `random % 3` member. The two complete
first-jutsu file walks contain no other compact-producing command value;
their frame-1 startup commands 430/440 select the jutsu through the spawn
route instead. Resources 175/185 install
`skill_primary_event_callback_noop` (`0x007967D0`) at +0x13C.

`item_skill_event_service` requires the participant's valid fighter handle,
the coordinator gate and zero other-participant `+0xD0` cooldown. A passed
other-participant request sets that cooldown to 20 before resident audio
admission. Authored markers therefore establish request opportunities, not
one audible clip per marker. The other fighter determines the bank. If that
fighter is Shizune 85 or Kabuto 90, selectors 9..11, 12..14 and 15..17
select programs 12..14, 15..17 and 18..20 respectively, with default key
60 and native VAG indices 17..19, 20..22 and 14..16. The exact six-bank
lookup table above supplies their physical offsets.

The selected Kabuto-185 auxiliary installs vtable `0x005E24C0`.
`dead_soul_auxiliary_update` (`0x0085BE60`, +0xA0) reaches
`dead_soul_auxiliary_apply_command_state` (`0x0085B9B0`, +0xA4),
`dead_soul_auxiliary_state3_motion` (`0x0085B8D0`, +0xA8) and
`dead_soul_auxiliary_command_state_12` (`0x0085B8A0`, +0xAC).
Their animation-state, object-binding and exit paths add global sound
effects, but no participant compact or PLVOICE request. This helper's
player setup retains the image's zero default callback; it does not install
the fighter proxy event bridge. Thus this selected auxiliary supplies no
additional character-bank selector.

**Evidence limits:** these conclusions cover the selected primary methods,
joined participant callbacks, frame/state producers and checked helpers.
They do not assert silence for every fighter or global effect reached during
a battle. Code and archive indices establish candidate recordings and
request opportunities; their spoken meaning and audible equivalence remain
unestablished.

### Shizune and Kabuto selected cinematic rows

Checked pairs are NUN4 Shizune 27 / NA2 Shizune 85 and NUN4 Kabuto 28 /
NA2 Kabuto 90. Selection metadata, skill/title joins and clean stream/camera
comparison are in
[Ultimate Jutsu cinematics](#cinematics).
The counted `cinematic_audio_descriptors` arrays are NUN4 `0x005CD4B0`
and NA2 `0x005D3D20`; both use eight-byte rows with frame, popup, signed
sound cue, damage fraction and chakra fraction.

**MCP observations:** each paired descriptor's entire row payload agrees,
including popup bytes and all zero chakra fractions. The annotated row roots
and ordered nonzero damage/cue data are:

| Technique; NUN4 / NA2 skill | Count; NUN4 / NA2 row root | Authored frame: damage fraction; cue |
| --- | --- | --- |
| Great Cross Slash; `0x3C / 0xA1` | 30; `shizune_great_cross_slash_hit_rows`, `0x005C9870 / 0x005D2D70` | `72..100`: 275 each, cue 13 at 72 then -1; `235`: 24793, cue 18 |
| Tonton Combo; `0x3D / 0xA2` | 2; `shizune_tonton_combo_hit_rows`, `0x005C9960 / 0x005D2E60` | `72`: 5461, cue 13; `324`: 27307, cue 18 |
| Dead Soul Jutsu; `0x3E / 0xAC` | 3; `kabuto_dead_soul_hit_rows`, `0x005C9970 / 0x005D3320` | `158/198/238`: 6554/6554/19660, cues 13/15/18 |
| Chakra Scalpel; `0x3F / 0xAD` | 3; `kabuto_chakra_scalpel_hit_rows`, `0x005C9990 / 0x005D3340` | `107/280/326`: 1057/21141/10570, cues 12/15/18 |

NUN4/NA2 selected-record intro cue halfwords differ: Great Cross Slash
`0x36/0xA8`, Tonton Combo `0x37/0xA9`, Dead Soul `0x38/0xB2`,
Chakra Scalpel `0x39/0xB3`. The record's damage amount can differ despite
equal per-frame fractions. These halfwords and cue rows do not by themselves
establish an audible clip or equivalent spoken content. The character bank
ranges and physical archive counts are recorded in
[Character assets](#checked-sound-resources).

NA2's additional Kabuto skill `0xAB` has five rows at `0x005D32F0`:
frames 122/134/182/302/339, damage fractions 555/1111/2777/555/27770,
cues 12/-1/15/13/18, all chakra fractions zero. No selected NUN4 Kabuto
record in this comparison executes that skill's `d90_10` request pair.
