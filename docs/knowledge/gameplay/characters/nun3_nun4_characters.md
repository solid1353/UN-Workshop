# NUN3 and NUN4 characters

## Research coverage

This document compares how NUN3 (`SLUS-21727`) and NUN4 (`SLUS-21862`)
represent playable characters against retail NA2 (`SLPS-25837`), and holds the
NUN3 and NUN4 character tables. Each donor character's own research is in its
document below.

Established: record copies and concrete construction, action and row
representations, constructor-owned dependencies, separate jutsu resource domains,
compared CCS and voice files, marked character-reference consumers, NUN3's
filename tables, selector comparison and streamed voice selection, and NUN4's
compact voice contract and jutsu resource caches.
Open: complete code and resource closure of any one character, untranslated
row fields and arbitrary indirect consumers. Names come from each game's
annotations; addresses are live.

## Character documents

| Donor | Document | NA2 counterpart |
| --- | --- | --- |
| NUN4 Naruto 57 and Second Stage 73 | [Naruto](nun4/naruto.md) | Naruto 57, form 73 |
| NUN4 Jiraiya 21 | [Jiraiya](nun4/jiraiya.md) | Jiraiya 83 |
| NUN4 Tsunade 25 | [Tsunade](nun4/tsunade.md) | Tsunade 84 |
| NUN4 Orochimaru 9 | [Orochimaru](nun4/orochimaru.md) | Orochimaru 89 |
| NUN4 Shizune 27 and Kabuto 28 | [Shizune and Kabuto](nun4/shizune_kabuto.md) | Shizune 85, Kabuto 90 |
| NUN3 Guy 20 | [Guy](nun3/guy.md) | Might Guy 69 |
| NUN3 Green Beast | [Green Beast](nun3/green_beast.md) | Classic Naruto |
| NUN3 Kakashi 8 | [Kakashi](nun3/kakashi.md) | Kakashi 70 |
| NUN3 ANBU Kakashi 30 | [ANBU Kakashi](nun3/anbu_kakashi.md) | Kakashi 70 |
| NUN3 Itachi 23 | [Itachi](nun3/itachi.md) | Itachi 71 |
| NUN3 Kisame 24 | [Kisame](nun3/kisame.md) | Kisame 72 |

NUN4's Ultimate Jutsu records, request layouts and optional cinematic formats are
in [NUN4 Ultimate Jutsu](nun4/ultimate_jutsu.md).

## NA2, NUN4 and NUN3 character representation

### Representative coverage

The following counts and pointers were read through MCP in each game's own
resident program. Counts are stored metadata, not a claim that every authored
action is reachable. `A/R/N` means authored actions, `0x4C` rows and animation
name slots; the last count includes shared and reserved names, so it need not
equal the number of `ANM_` objects in a body CCS.

| Game / exact character | ID | Annotated record / live address | A/R/N |
| --- | ---: | --- | --- |
| NA2 / Naruto Uzumaki (Classic) | 1 | `naruto_classic_character_record`, `0x0040DB70` | 48/190/156 |
| NUN3 / Naruto Uzumaki (Classic) | 1 | `naruto_classic_character_record`, `0x0038E730` | 47/183/156 |
| NUN4 / Naruto Uzumaki (Classic) | 1 | `naruto_classic_character_record`, `0x0043E650` | 48/190/156 |
| NA2 / Naruto Uzumaki | 57 | `naruto_character_record`, `0x004DAD80` | 49/193/157 |
| NUN4 / Naruto Uzumaki | 57 | `naruto_character_record`, `0x0051CD90` | 49/193/157 |
| NA2 / Sai | 92 | `fighter_id_092_character_record`, `0x00595B60` | 44/173/149 |
| NA2 / Sasuke Uchiha | 93 | `sasuke_character_record`, `0x0059BDB0` | 49/216/168 |
| NUN3 / Kakashi Hatake | 8 | `kakashi_character_record`, `0x003AE9F0` | 46/178/154 |
| NUN4 / Orochimaru | 9 | `orochimaru_character_record`, `0x00460C80` | 47/180/156 |

For Classic Naruto, bytes `+0x58..+0xDB` agree between NA2, NUN3 and NUN4.
Naruto's same region agrees between NA2 and NUN4. These are stored-parameter
observations; individual behavioral effects require the owning consumer.

NUN4 `character_definition_table` (`0x005744E0`) has a contiguous 78-entry
paired-pointer region before the next data, covering slots 0..77. Its factory
consumer indexes by eight bytes. Region size does not prove roster
eligibility. Only the named character rows were individually
identified in this comparison.

### Record copies and concrete construction

Each game's own `fighter_load_character_record` copies 55 words from record
`+0x00..+0xD8`, then chooses authored or constructor-installed working arrays.
The inspected Classic Naruto constructors supply their embedded animation,
action and row storage before that call.

| Game | Loader | Copied record base in fighter | Working action base / count | Classic Naruto constructor; allocation | Embedded animation / action / row arrays |
| --- | --- | --- | --- | --- | --- |
| NA2 | `0x002151E0` | `+0x8C` | `+0xA54` / `+0xA38` | `naruto_classic_construct`, `0x00250C50`; `0x5980` | `+0xEE0` / `+0x1150` / `+0x2110` |
| NUN3 | `0x001A6190` | `+0x80` | `+0x9A4` / `+0x988` | `naruto_classic_construct`, `0x001D9DA0`; `0x5630` | `+0xE00` / `+0x1070` / `+0x1FDC` |
| NUN4 | `0x001FC390` | `+0x84` | `+0xA44` / `+0xA28` | `naruto_classic_construct`, `0x0023FF40`; `0x5C70` | `+0xED0` / `+0x1140` / `+0x2400` |

NUN4's common asset initializer `fighter_load_character` (`0x001FCC00`)
chooses shared versus body animation providers by the stored name,
initially leaves slots `0x46..0x4D` empty and
constructs the selected model against the common body scene. It borrows
providers at fighter `+0xE50/+0xE54`. The NA2 path is owned by
[Model and appearance name consumers](../../game/character_assets.md#model-and-appearance-name-consumers).

NUN4 Classic Naruto's seven-slot `naruto_classic_callbacks` table
(`0x00439890`) populates slots 1..4. Slots 1 and 2
are both `jr ra; nop`. NUN4 Orochimaru's
`orochimaru_callbacks` (`0x0045C220`) likewise populates 1..4; their individual
effects were not compared here. NUN3 Kakashi's existing `kakashi_channel3`
(`0x001E4260`) reads NUN3 phase and particle-colour offsets, as documented
under [Per-character code](../../game/character_assets.md#per-character-code). Pointer population alone
does not establish callback equivalence.

### Action and row representations

NUN4 `actions_setup_working_array` (`0x00200900`) uses `0x64`-byte action
records. The checked Classic Naruto array, `naruto_classic_actions`
(`0x0043D390`), has five display slots at `+0x08..+0x18`; the initializer
selects one with `ui_language_index`. Packed owner/selector starts at `+0x1C`,
and `actions_resolve_rows` (`0x002002C0`) turns authored row index `+0x60`
into a pointer to the working row array.

NUN4 copies `0x4C`-byte rows and can import the two six-row
configured-jutsu groups from a different definition. Thus a character's
working arrays can depend on the selected jutsu owner, beyond its own
authored record. NA2/NUN3 contracts remain under [Action records](../../game/character_assets.md#action-records)
and [Animation-name and row tables](../../game/character_assets.md#animation-name-and-0x4c-stride-tables).

### Additional constructor-owned dependencies

The record pair at `+0x50/+0x54` can describe a count and pointer to
`0x90`-byte named-handle descriptors. `fighter_construct_named_handle_list`
is verified in NA2 (`0x00214420`) and NUN4 (`0x001FB400`).
This list is separate from the animation-name lookup array
at record `+0x4C`; existing fighter field names do not replace the checked
raw offsets.

NUN4 `orochimaru_construct` (`0x0024A890`) writes count 1 and
`orochimaru_named_handle_descriptor` (`0x0045C190`). Its first name is
`OBJ_2cmn00t0 r hand`, and name `+0x20` is `MDL_2orc00t0 ktn0`.
`fighter_construct_named_handle` and `fighter_named_handle_create_model`
resolve the hand against the shared scene and the model against the selected
body provider, then attach them. Other descriptor fields remain unassigned.

Resident constructor roots can call overlay code. NA2 Sasuke's
`fighter_id_093_construct` (`0x003000E0`) allocates
`0x30/0x14/0xB0/8/8` helper blocks through these
separately inspected BTL routines:

| Annotated helper | NA2 BTL |
| --- | --- |
| `fighter_auxiliary30_initialize` | `0x0071F8E0` |
| `fighter_auxiliary_scale_context_construct` | `0x00721C10` |
| `fighter_auxiliary_b0_construct` | `0x00720370` |
| `fighter_auxiliary8_initialize_a` | `0x007233B0` |
| `fighter_auxiliary8_initialize_b` | `0x00722D80` |

Their allocation/initialization dependencies are established; complete helper
behavior and transitive descendants were not classified by this inventory.
Shared lifetime facts belong to [Battle entities](../session/battle_entities.md).

### Separate jutsu resource domains

#### Identity and authored action owners

**Observation:** NUN4 `actions_setup_working_array` (`0x00200900`)
reads the two configured selectors at fighter `+0x17C/+0x17E`.
`jutsu_selector_character` (`0x002D1490`) returns a positive arithmetic
`selector >> 1`, otherwise zero. The initializer uses that result to
select a definition. Selector parity chooses the definition's authored
actions 0/1 or 2/3 for each working pair; selector 1 copies the null action
record. It copies the authored packed owner/selector word unchanged.
The current fighter ID at `+0x68`, selected jutsu owner and authored
action owner are therefore separate inputs.

These exact first-four-action words were checked in each game's own program.
The low halfword is the authored owner; the high halfword is its selector.
NUN4 stores the word at action `+0x1C` with `0x64` stride, NA2 at
`+0x0C` with `0x54` stride.

| Exact checked character | Game and action array | Packed words, actions 0..3 |
| --- | --- | --- |
| Naruto Uzumaki (Classic), ID 1 | NA2 `naruto_classic_actions`, `0x0040CBA0`; NUN4 same name, `0x0043D390` | `00020001, 00020001, 00010001, 00030001` in both games |
| Naruto Uzumaki, ID 57 | NA2 `naruto_actions`, `0x004D9D50`; NUN4 same name, `0x0051BA60` | `00720039, 00720039, 00010039, 00730039` in both games |
| Orochimaru, ID 9 | NUN4 `orochimaru_actions`, `0x0045FA20` | `00010009, 00120009, 00130009, 00130009` |

For these three NUN4 characters, actions 1/3 carry the usual selector pair.
Classic Naruto and Naruto action 2 use selector 1; Orochimaru action 0 does.

NA2 `character_definition_slot_009` (`0x005A2948`) repeats Classic
Naruto's factory and `naruto_classic_character_record`; it supplies that
record's authored array rather than a dedicated Orochimaru record.
Independently, NA2 selectors 18/19 retain resident `2orccha0/1.ccs`
and BTL resource indices 22/23 with the same names. A retained resource
selector does not establish a dedicated fighter definition or disc file.

#### Complete NUN4 selector map

The census covers every resident row, BATTLE mapping word and resource
filename pointer below, including their referenced strings.

| NUN4 domain | Annotated table / live address | Complete static coverage |
| --- | --- | --- |
| Resident animation selector | `jutsu_animation_provider_table`, `0x00573D90` | 156 rows, selectors 0..155, 12-byte stride; filename at `+8` |
| BATTLE selector translation | `jutsu_selector_resource_table`, `0x0085B160` | 156 signed words |
| BATTLE resource index | `jutsu_resource_filenames`, `0x0084A660` | 160 pointers, indices 0..159; next table at `0x0084A8E0` starts `MAT_cmneye1` |

`jutsu_animation_archive_name` (`0x002D12E0`) directly returns the
resident filename without an internal bound. Selectors 0/1 name
`2cmnbod1.ccs`, while BATTLE maps them to -1. Every other selector maps
to a distinct nonnegative resource index; the 154 outputs omit six of the
160 resource slots.

The full BATTLE mapping follows. Each pair lists even/odd selector order.
The owner column is the result of `jutsu_selector_character`, not proof
that every ID has a dedicated definition or is selectable. A filename
written as `cha0/1.ccs` means the two separate filenames in that order.

| Selectors | Selected owner | BATTLE resource indices | BATTLE filenames |
| --- | ---: | --- | --- |
| 0/1 | 0 | -1/-1 | — |
| 2/3 | 1 | 0/1 | `2nrtcha0/1.ccs` |
| 4/5 | 2 | 2/3 | `2sskcha0/1.ccs` |
| 6/7 | 3 | 4/5 | `2roccha0/1.ccs` |
| 8/9 | 4 | 6/7 | `2garcha0/1.ccs` |
| 10/11 | 5 | 8/9 | `2sikcha0/1.ccs` |
| 12/13 | 6 | 14/15 | `2nejcha0/1.ccs` |
| 14/15 | 7 | 20/21 | `2skrcha0/1.ccs` |
| 16/17 | 8 | 10/11 | `2kkscha0/1.ccs` |
| 18/19 | 9 | 22/23 | `2orccha0/1.ccs` |
| 20/21 | 10 | 16/17 | `2hakcha0/1.ccs` |
| 22/23 | 11 | 12/13 | `2zbzcha0/1.ccs` |
| 24/25 | 12 | 19/18 | `2hntcha0/1.ccs` |
| 26/27 | 13 | 35/36 | `2tencha0/1.ccs` |
| 28/29 | 14 | 31/32 | `2tyocha0/1.ccs` |
| 30/31 | 15 | 33/34 | `2inocha0/1.ccs` |
| 32/33 | 16 | 25/26 | `2kibcha0/1.ccs` |
| 34/35 | 17 | 39/40 | `2sincha0/1.ccs` |
| 36/37 | 18 | 41/42 | `2knkcha0/1.ccs` |
| 38/39 | 19 | 43/44 | `2tmrcha0/1.ccs` |
| 40/41 | 20 | 29/30 | `2guycha0/1.ccs` |
| 42/43 | 21 | 27/28 | `2jrycha0/1.ccs` |
| 44/45 | 22 | 47/48 | `2hkgcha0/1.ccs` |
| 46/47 | 23 | 49/50 | `2itccha0/1.ccs` |
| 48/49 | 24 | 37/38 | `2ksmcha0/1.ccs` |
| 50/51 | 25 | 51/52 | `2tndcha0/1.ccs` |
| 52/53 | 26 | 114/115 | `2nrocha0/1.ccs` |
| 54/55 | 27 | 57/58 | `2szncha0/1.ccs` |
| 56/57 | 28 | 45/46 | `2kbtcha0/1.ccs` |
| 58/59 | 29 | 55/56 | `2forcha0/1.ccs` |
| 60/61 | 30 | 53/54 | `2anbcha0/1.ccs` |
| 62/63 | 31 | 65/66 | `2nrvcha0/1.ccs` |
| 64/65 | 32 | 67/68 | `2nrzcha0/1.ccs` |
| 66/67 | 33 | 69/70 | `2hnxcha0/1.ccs` |
| 68/69 | 34 | 62/85 | `2jrbcha0/1.ccs` |
| 70/71 | 35 | 61/84 | `2kdmcha0/1.ccs` |
| 72/73 | 36 | 63/86 | `2tyycha0/1.ccs` |
| 74/75 | 37 | 64/87 | `2skncha0/1.ccs` |
| 76/77 | 38 | 72/73 | `2kmmcha0/1.ccs` |
| 78/79 | 39 | 106/107 | `2foucha0/1.ccs` |
| 80/81 | 40 | 108/109 | `2khmcha0/1.ccs` |
| 82/83 | 41 | 110/111 | `2hnbcha0/1.ccs` |
| 84/85 | 42 | 80/81 | `2fircha0/1.ccs` |
| 86/87 | 43 | 82/83 | `2seccha0/1.ccs` |
| 88/89 | 44 | 76/77 | `2asmcha0/1.ccs` |
| 90/91 | 45 | 78/79 | `2krncha0/1.ccs` |
| 92/93 | 46 | 74/75 | `2ankcha0/1.ccs` |
| 94/95 | 47 | 112/113 | `2nrvcha0/1.ccs` |
| 96/97 | 48 | 88/89 | `2ssvcha0/1.ccs` |
| 98/99 | 49 | 90/91 | `2rovcha0/1.ccs` |
| 100/101 | 50 | 92/93 | `2gavcha0/1.ccs` |
| 102/103 | 51 | 94/95 | `2tovcha0/1.ccs` |
| 104/105 | 52 | 100/101 | `2jrvcha0/1.ccs` |
| 106/107 | 53 | 98/99 | `2kdvcha0/1.ccs` |
| 108/109 | 54 | 102/103 | `2tyvcha0/1.ccs` |
| 110/111 | 55 | 104/105 | `2skvcha0/1.ccs` |
| 112/113 | 56 | 96/97 | `2kmvcha0/1.ccs` |
| 114/115 | 57 | 116/117 | `2nrwcha0/1.ccs` |
| 116/117 | 58 | 118/119 | `2skwcha0/1.ccs` |
| 118/119 | 59 | 120/121 | `2gawcha0/1.ccs` |
| 120/121 | 60 | 122/123 | `2knwcha0/1.ccs` |
| 122/123 | 61 | 124/125 | `2tmwcha0/1.ccs` |
| 124/125 | 62 | 126/127 | `2chycha0/1.ccs` |
| 126/127 | 63 | 128/129 | `2scocha0/1.ccs` |
| 128/129 | 64 | 130/131 | `2ddrcha0/1.ccs` |
| 130/131 | 65 | 132/133 | `2newcha0/1.ccs` |
| 132/133 | 66 | 134/135 | `2tewcha0/1.ccs` |
| 134/135 | 67 | 136/137 | `2rowcha0/1.ccs` |
| 136/137 | 68 | 138/139 | `2siwcha0/1.ccs` |
| 138/139 | 69 | 140/141 | `2guwcha0/1.ccs` |
| 140/141 | 70 | 142/143 | `2kkwcha0/1.ccs` |
| 142/143 | 71 | 144/145 | `2itwcha0/1.ccs` |
| 144/145 | 72 | 146/147 | `2kswcha0/1.ccs` |
| 146/147 | 73 | 148/149 | `2nwvcha0/1.ccs` |
| 148/149 | 74 | 150/151 | `2chvcha0/1.ccs` |
| 150/151 | 75 | 152/153 | `2scvcha0/1.ccs` |
| 152/153 | 76 | 156/157 | `2schcha0/1.ccs` |
| 154/155 | 77 | 158/159 | `2cybcha0/1.ccs` |

For selectors 2..155, resident and translated BATTLE filenames agree in
143 cases. These eleven are the complete differences; the resident path
uses the `nrt` name shown instead:

| Selectors | Resident filenames | BATTLE filenames |
| --- | --- | --- |
| 52 | `2nrtcha0.ccs` | `2nrocha0.ccs` |
| 58/59 | `2nrtcha0/1.ccs` | `2forcha0/1.ccs` |
| 62/63 | `2nrtcha0/1.ccs` | `2nrvcha0/1.ccs` |
| 66/67 | `2nrtcha0/1.ccs` | `2hnxcha0/1.ccs` |
| 148/149 | `2nrtcha0/1.ccs` | `2chvcha0/1.ccs` |
| 150/151 | `2nrtcha0/1.ccs` | `2scvcha0/1.ccs` |

The six resource slots omitted by the initial selector map are:

| Resource index | Filename |
| ---: | --- |
| 24 | `2zbzcha1.ccs`, also named by resource 13 |
| 59/60 | `2dtucha0/1.ccs` |
| 71 | `2ndrcha0.ccs` |
| 154 | `2kkwbod1.ccs` |
| 155 | `2kkwcha1.ccs`, also named by resource 143 |

The first 116 resource filenames agree with NA2 and NUN3, including repeated
names. NUN4 and NUN3's complete common selector region 0..113 agrees;
relative to NA2's same region, the seven different selectors are 52 and
58..63, as detailed in [NUN3 selector comparison](#nun3-selector-comparison).
NA2 and NUN4 resource names 116..153 and 156..159 also agree.
At resource 154/155, NA2 instead names `2kkvcha1.ccs` /
`2kkwbod1.ccs`. Across the full common 156-selector region, the numeric
mapping differs only at those same seven selectors. This is table agreement,
not interchangeable character code or resource availability.

#### Resource consumers and cache capacities

NUN4 `interaction_setup_jutsu_resources` (`0x007577B0`) translates
four configured manager selectors at `+0x90/+0x94/+0xB0/+0xB4`.
This consumer and `interaction_preallocate_record_banks`
(`0x007573B0`) use resource 0 for a selector below zero or at least 156;
valid selectors 0/1 retain their -1 map entries and are skipped.
Direct consumers such as `ai_action_record_allowed` (`0x006D6980`)
read configured selectors through the map without the same local bounds check.

| NUN4 storage | Capacity and selection | Establishing consumer |
| --- | --- | --- |
| Per-side interaction record caches | Two 160-pointer arrays at owner `+0xBB8/+0xE38`, side stride `0x280`; accept translated resources 0..159 | `interaction_preallocate_record_banks` allocates the resource descriptor's signed record count times `0x78` bytes |
| Shared resource-bank cache | 160 pointers at `interaction_jutsu_resource_cache`, `0x008675D0`; setup clears `0x280` bytes | `interaction_setup_jutsu_resources` allocates one `0x280`-byte damage-offset bank for a found `BIN_skldamoffs_%s` payload |
| Damage-offset bank variant arrays | Two arrays of 79 pointers at bank `+0x08/+0x144`; raw shared count at `+0x00`, borrowed short-array pointer at `+0x04` | `interaction_decode_damage_offset_bank`, `0x0074BF60`, checks `_damOffs` / version `0x100`, caps the variant count at 79 and clears unused variant slots |

Preallocation additionally checks the actual fighter's current ID for numeric
ID 70 and allocates resource 154/155 in both per-side caches. Those resources
have no entry in the initial selector map. Absence from that map therefore
does not establish absence from code-selected dependencies.
Resource selection and bank/provider ownership are separated in
[NUN4 load and cache edges](#nun4-checked-jutsu-resource-load-and-caches).

`interaction_create_jutsu_from_command` (`0x0074CCF0`) accepts command
kind `0x8003` with encoded resource `0x100..0x19F`, subtracts
`0x100`, and calls `interaction_create_bound_jutsu`
(`0x0074E7A0`). `jutsu_create_for_resource` (`0x0074CD70`) admits
resource indices below 160 to its factory dispatch.
`jutsu_initialize_resource_binding` (`0x00768D70`) requires that
resource's provider and stores its index at object `+0x54C`.
Its owner comparison reverse-scans the 156 selector words, taking the first
matching selector or selector 1 when none matches, before calling
`jutsu_selector_character`. It does not derive an owner directly from
the resource index.

The checked `jutsu_bind_three_resource_animations` (`0x0078BA70`)
requires the filename indexed by the resource value at object `+0x54C` and
consumes `jutsu_three_resource_animation_names` (`0x0084B090`):
zero, `ANM_phkgcha11` and `ANM_phkgcha12`. It passes three slots from
object `+0xAFC..+0xB04` to its virtual binder. These particular literal
names do not establish that every jutsu class uses this routine.

**Coverage limit:** the complete lookup/capacity census and the named consumers
above do not establish every selector's admission, every factory case's
concrete behavior, the resident table's first two words, all animation-name
consumers, or provider residency. Complete behavior and typed asset closure
remain specific to the chosen character and actions.

### Compared CCS and voice files

Complete-file hashes are owned by
[Retail game file identities](../../game/files/file_identities.md#character-comparison-inputs).
NA2 `PL/2NRTBOD1.CCS`, `PL/2NRWBOD1.CCS`, `PL/2SAIBOD1.CCS` and
`PL/2SSWBOD1.CCS`, for Classic Naruto, Naruto, Sai and Sasuke,
contain 111, 131, 119 and 123 `ANM_` directory names, respectively.

NUN4 English-view `PL/2NRTBOD1` and `2NRWBOD1` differ from their NA2
counterparts. Those two and NUN4 `PL/2ORCBOD1` contain 111, 129 and 119
`ANM_` names, respectively.
Every marked `2cmnbod1.max` object name in these three bodies is present in
NA2's shared provider. NUN4 Orochimaru's `2ORCCHA1` additionally has 69
marked `1cmn` rows, all present by exact name bytes in NA2's `1CMNBOD1`.
This checks common-provider directory presence, not complete parsing or use.

The NUN3 Kakashi comparison reconfirms the four absent `2cmn` muffler
objects and the two absent `1cmn` objects in `2KKSCHA0`, listed under
[Shared skeleton containers](../../game/character_assets.md#shared-skeleton-containers). The typed Sai
and Kakashi consumers are established under
[Marked character-reference consumers](#marked-character-reference-consumers).
Sasuke's body also names marked `TEX_sampling01`; shared sampling ownership belongs to
[Asset dependency graphs](../../game/files/asset_dependencies.md#locally-filled-external-marker-rows).

NA2's checked physical voice subarchives for Classic Naruto, Naruto, Sai
and Sasuke have declared/populated counts 40/40, 48/48, 41/41 and 45/45.
NUN4 has 77 outer entries; sampled Classic Naruto, Orochimaru and Naruto
subarchives are dense with 22, 18 and 24 members. Their first physical
filenames are `PL01_000`, `PL09_038` and `PL57_256`, respectively. NUN3's
sampled Classic Naruto and Kakashi subarchives have 209/27 and 213/80
declared/populated slots in each of the two banks. These PLVOICE counts concern
streamed members. Compact resources are owned by
[Compact fighter bank resources](../../game/character_assets.md#compact-fighter-bank-resources); their
checked decoding is in [Battle audio](../session/battle_audio.md#compact-program-to-vag-lookup).
NUN3's streamed selection is
established separately in the [checked descriptor/member contract](#checked-nun3-streamed-descriptors-and-members).

### Marked character-reference consumers

**Clean-file observations:** NA2 `PL/2SAIBOD1.CCS` rows 2212/2214/2216
name `OBJ_2ssw00t0 dummysaya`, `OBJ_2sswswd01` and `OBJ_2sswswd02`
under marked Sasuke namespaces `#c\2ssw\max\2sswswd01.max` and
`#c\2ssw\max\2sswswd02.max`. Their exact namespace/name keys match
unmarked `PL/2SSWBOD1.CCS` rows 65/67/69. Sai's local rows 2211/2213
use `c\2sai\psaikca42.max`; they are wrappers targeting those marked
rows, rather than local definitions of the Sasuke objects. Local row 2215
is named `OBJ_2sswswd06` but targets marked `OBJ_2sswswd02`.

NUN3 `2KKSCHA0.CCS` marked row 61 names
`#c\2kks\max\ekkskiseki0.max` / `OBJ_ekkskiseki0`. Its own
`2KKSBOD1.CCS` row 462 supplies the matching unmarked scene object;
the checked `1KKSBOD1` and `2KKSCHA1` do not supply that key.

| Consumer file | Local `0x0A00` wrapper → marked target | `0x0102` animation consumer | Frames |
| --- | --- | --- | ---: |
| NA2 `PL/2SAIBOD1` | 2211 → 2212; 2213 → 2214; 2215 → 2216 | `ANM_psaikca42`, animation row 2217; key flags 9 | 14 |
| NUN3 `2KKSCHA0` | 60 → 61 | `ANM_pkkscha00`, animation row 62; key flags `0x452` | 2 |
| NUN3 `2KKSCHA0` | 469 → 61 | `ANM_pkkschb00`, animation row 470; key flags `0x452` | 11 |
| NUN3 `2KKSCHA0` | 496 → 61 | `ANM_pkkschb02`, animation row 497; key flags `0x452` | 16 |

The Sai wrappers' parent records are 2178/2211/2213; all three Kakashi
wrappers have parent zero. Each selected wrapper also has a `0x2000`
metadata payload `{ID,1,0,0,0}`. Nested command walks for the selected
animations reach their outer payload ends; the target words are actual
`0x0102` IDs, rather than incidental directory or frame-marker matches.

The matching providers have typed `0x0100` definitions and these model
dependencies, beyond directory-name agreement:

| Provider and scene row | Model row | Material → texture → CLUT rows |
| --- | --- | --- |
| NA2 `PL/2SSWBOD1`, 65 | 5003, `MDL_2ssw00t0 dummysaya` | Short model payload; no material dependency established. |
| NA2 `PL/2SSWBOD1`, 67 | 5004, `MDL_2sswswd01` | 5006 → 5007 → 5069 |
| NA2 `PL/2SSWBOD1`, 69 | 5009, `MDL_2sswswd02` | 5011 → the same 5007 → 5069 |
| NUN3 `2KKSBOD1`, 462 | 3037, `MDL_ekkskiseki0` | 3039 → 3040 → 3045 |

The Sasuke material names are `MAT_2sswswd01/02`, sharing
`TEX_2sswswd` and `CLT_2sswswd`. The Kakashi chain names
`MAT_ekkskiseki0`, `TEX_ekkskiseki0` and `CLT_ekkskiseki0`.
These are the checked selected chains, not complete body-file closure.

**Code and authored-data observations:** Sai's main name array contains
`sai_sword_animation_name` (`0x00591220`) at
`sai_sword_animation_slot` (`0x005916CC`), index `0x63`.
`sai_sword_action_record` (`0x00595274`), authored action `0x11`, starts
at row 75. Phase 2 is `sai_sword_action_phase_row` (`0x00592E9C`),
row 77, whose prefix is `{slot 0x63, condition -17, start 0, rate 256}`.
The condition means grounded completion in
[Shared phase progression](../combat/combat_action_execution.md#shared-phase-progression).
`fighter_load_character` resolves that nonreserved slot from Sai's body;
`actions_resolve_rows` preserves row 77 outside the first twelve
jutsu-replaceable rows. The shared phase selector and start helper therefore
have a concrete authored route to bind this animation, subject to their
existing gates. Every Sai input/callback admission path was not audited.

When the selected wrapper's target remains unresolved, the checked NA2/NUN3
chain helper returns zero and animation binding leaves its play entry empty.
It does not load the named provider. The owning behavior and own-game
addresses are in
[Animation wrapper resolution](../../game/files/ccs_runtime.md#animation-wrapper-resolution).
Thus absence of Sasuke's body does not make these authored Sai references
unused; it prevents the three wrappers from acquiring their provider objects
at that bind. This does not establish a whole-fighter failure or final visibility.

NUN3 `battle_request_selected_character_ccs` (`0x00279720`) requests
the battle body by selected identity, under mask 2; identity 8 selects
`2kksbod1.ccs`. Under mask 8, configured selectors use
`jutsu_animation_archive_name` (`0x002347E0`), the first word of
12-byte `jutsu_animation_provider_table` rows (`0x004761D8`): checked
selectors 16/17 name `2kkscha0/1.ccs`. This supplies the observed own-body
provider when Kakashi is selected. Selecting that jutsu on another body
does not add a Kakashi-body request through this root. Complete load-set
lifetimes and all other publication paths remain outside this bounded trace.


## NUN3 tables

### NUN3 filename tables

NUN3 `SLUS_217.27` has the same families in adjacent 60-slot tables;
the names below belong to NUN3 annotations.

| Family | NUN3 table | Live address |
| --- | --- | ---: |
| `2???bod1.ccs` | `character_battle_body_filenames` | `0x0047D2F0` |
| `1???bod1.ccs` | `character_presentation_body_filenames` | `0x0047D3E0` |
| `3???3eye.ccs` | `character_end_demo_filenames` | `0x0047D4D0` |
| `3???3pct.ccs` | `character_portrait_filenames` | `0x0047D5C0` |

Slot 0 and slots 57..59 are null; slots 1..56 are populated. Definition-copy
IDs 29, 31 and 33, and jutsu-bearing ID 26, repeat `nrt` rather than
being null. Every other slot matches its definition's code. Shared fighters
have identical codes across both games. NUN3-only codes are `kks` (8),
`orc` (9), `guy` (20), `jry` (21), `itc` (23), `ksm` (24),
`tnd` (25), `szn` (27), `kbt` (28), `anb` (30), `nrz` (32),
`asm` (44), and `krn` (45).

### NUN3 selector comparison

NUN3 `jutsu_selector_resource_table` (live `0x0093E800`) has 114
signed words; `jutsu_resource_filenames` has 116 pointers. The next
pointer starts the material-name table with `MAT_cmneye1`.
All 116 filenames match the NA2 prefix. Of 114 selector mappings, 107 agree
and seven differ:

| Selector | NUN3 resource / filename | NA2 resource / filename |
| ---: | --- | --- |
| 52 | 114 / `2nrocha0.ccs` | 154 / `2kkvcha1.ccs` |
| 58 / 59 | 55 / 56, `2forcha0/1.ccs` | 192 / 193, `2bdycha0/1.ccs` |
| 60 / 61 | 53 / 54, `2anbcha0/1.ccs` | 194 / 195, `2bdycha2/3.ccs` |
| 62 / 63 | 65 / 66, `2nrvcha0/1.ccs` | 196 / 45, `2bdycha4.ccs` / `2kbtcha0.ccs` |

`jutsu_selector_resource` returns zero for negative selectors or
selectors at least 114; valid selectors 0 and 1 return their -1 entries.
`interaction_setup_fighter_resources` translates both configured
selectors and fills two 116-pointer resource caches. Selector bounds and
resource capacity are distinct.

`jutsu_resource_filename` directly indexes the filename table without
an internal bound. `interaction_bind_jutsu_resource` passes a resource
index to it and requires that CCS provider through `ccs_require_container`.
This is an asset consumer, not evidence that a raw character ID can replace
either index domain.

### Checked NUN3 streamed descriptors and members

**Own-game code and clean-file observation:** NUN3
`audio_plvoice_descriptors` (`0x00388A80`) holds 112 eight-byte descriptors
followed by an all-`0xFF` sentinel. Each valid descriptor's handle is
`70 + outer_index`; its signed halfword at +6 is the declared sparse member
count. The selection rule, setting owner and startup loading belong to
[Battle audio](#checked-nun3-streamed-bank-selection).
Bank 0 is English and bank 1 is Japanese, established by the
[voice-menu texture and direct setting write](#nun3-streamed-bank-language).

| Character | Bank | Outer index | Descriptor live address | Handle | Declared/populated members |
| --- | ---: | ---: | ---: | ---: | ---: |
| Classic Naruto, 1 | 0 | 0 | `0x00388A80` | 70 | 209/27 |
| Classic Naruto, 1 | 1 | 56 | `0x00388C40` | 126 | 209/27 |
| Kakashi, 8 | 0 | 7 | `0x00388AB8` | 77 | 213/80 |
| Kakashi, 8 | 1 | 63 | `0x00388C78` | 133 | 213/80 |

For these four subarchives, every populated filename-directory field contains
ASCII `playe` followed by zeros. It identifies neither the numeric cue nor
the language. Both checked Naruto banks have the populated indices listed
above. Both checked Kakashi banks populate exactly
`4..7, 11, 13, 23..25, 28, 32, 35..39, 42, 44..50, 53..57, 59..60,
63, 68..69, 78..81, 85, 92..96, 98, 100, 104, 106..107, 111..112,
116..118, 121..125, 131, 134, 144, 146, 151, 165..167, 181..185,
199, 202, 204, 208..212`.

These exact member identities use offsets in the complete clean
`DATA/PLVOICE.AFS`, not EE addresses. Cue 6 has a checked battle producer;
cue 45 additionally demonstrates a sparse index that differs from NA2's.

| Character / cue | Bank-0 outer/member, file offset, bytes | Bank-1 outer/member, file offset, bytes |
| --- | --- | --- |
| Classic Naruto / 6 | `0/6`, `0xE000`, 9,889 | `56/6`, `0x1292800`, 7,398 |
| Kakashi / 6 | `7/6`, `0x37D000`, 16,249 | `63/6`, `0x1538800`, 12,102 |
| Classic Naruto / 45 | `0/45`, `0x16000`, 22,517 | `56/45`, `0x1299000`, 15,437 |
| Kakashi / 45 | `7/45`, `0x3B2800`, 20,617 | `63/45`, `0x1562800`, 17,191 |

Naruto's member 4 has zero offset and size in both banks. Kakashi's member 0
has offset `0x800` but zero size in both banks. A nonzero stored offset alone
does not establish a populated clip. NA2 Classic Naruto instead uses descriptor
handle 150 with 40 dense members: cue 45 maps to physical member 3. NA2 ID 8
has a null outer member and descriptor count zero. These identities establish
selection and stored bytes, without establishing spoken content or a complete
donor cue set.

### Checked NUN3 streamed bank selection

**Own-game code observation:** NUN3 `audio_queue_player_voice`
(`0x001856D0`) accepts a character below 57 and calls
`audio_write_pending_stream` (`0x00184E40`). The latter writes character
minus one, the unchanged cue/member, slot, alternate-family zero and pending
byte one into `audio_request_context_ptr`'s four 0x14-byte rows. This path has
no filename-number-list lookup. Its signed upper-bound check and unchecked
slot do not establish safety for arbitrary arguments. The descriptor/member
comparison checks character IDs 1/8; the inspected phase calls derive slots
0/1 from the fighter side bit.

`audio_consume_pending_streams` (`0x00185570`) stops each pending mono slot
before requesting its replacement. For alternate-family zero it calls
`audio_request_archive_member` (`0x0018A3B0`) with family 3 and
`bank = character - 1 + 56 * (voice_set == 1)`. The member is the queued
value narrowed to a signed halfword. The setting is read when the row is
consumed, not when it is queued. Pending is cleared regardless of admission.
The separate nonzero-alternate branch selects SOUND with a 14-descriptor
offset; it is not the PLVOICE path.

`voice_set` is the signed word at `audio_command_context_ptr`
(`0x006A3110`) +0xC. `audio_command_context_initialize` (`0x0018A8A0`)
sets it to zero; `audio_set_voice_set` (`0x00188710`) writes a changed value;
`audio_alternate_voice_set_enabled` (`0x00188740`) returns one only for
value one. `audio_settings_menu_initialize` (`0x002BC860`) copies that choice,
and row 2 of `audio_settings_menu_update` (`0x002BC920`) toggles 0/1 and applies
it on confirmation. `profile_load_audio_voice_set` (`0x00282980`) restores
saved halfword +0xA444 by equality to one. The help string
`audio_voice_mode_help_english` (`0x0066DC50`) identifies English/Japanese
choices; their numeric order is established by the
[menu texture below](#nun3-streamed-bank-language).

`audio_archive_initialize_counts` (`0x00118F00`) counts all 112 PLVOICE
descriptors. `afs_startup_load_partitions` (`0x00188350`) loads the top-level
PLVOICE partition 252 and every nonzero-count nested descriptor in both banks,
independent of the voice setting. `audio_request_archive_member` checks the
declared member count, then `audio_start_mono_member` (`0x00119330`) forwards
the selected descriptor handle/member unchanged. `cri_start_archive_member`
(`0x0034AFE0`) and `cri_archive_resolve_member_inner` (`0x0033FEB0`) resolve
the physical member through the selected partition's metadata. The checks
bound the sparse index but do not require a nonzero clip size. Exact descriptors,
member bytes and the NA2 dense-index comparison belong to
[Character assets](#checked-nun3-streamed-descriptors-and-members).

**Checked IOP boundary:** NUN3 `cri_bind_iop_rpc_service` (`0x003562F0`)
binds service `0x90000200`, matching `CRI_ADXI.IRX:cri_adxi_rpc_worker`.
`cri_create_remote_playback` (`0x0035D598`) sends RPC `0x408` with channel
count, SPU core selector and IOP stream handles; the IOP
`cri_adxi_rpc_create_remote_playback` accepts that same shape.
`cri_service_stream_transfer_pair` (`0x00355618`) copies buffer bytes by SIF
DMA. Its chunk notifications, built by `cri_stream_transfer_outbound_callback`
(`0x00361468`), reach `CRI_ADXI.IRX:cri_adxi_receive_stream_chunks` through
DTX ID 0 as paired handle/address/byte-count records. Separate DTX ID 1
records from `cri_collect_playback_controls` (`0x0035CA20`) carry operation,
IOP playback handle and parameters. These checked calls transport supplied
buffers and playback controls; they do not select a character, bank or cue.
This does not establish every IOP path or the transferred buffers' codec.
IOP relocation remains unestablished, so its symbols are program-qualified
rather than assigned live addresses.

**Checked producers:** NUN3 BATTLE `dialogue_voice_produce`
(`0x0086B100`) and `dialogue_voice_produce_from_fighter` (`0x0086B580`) queue
selected halfword cues. `dialogue_voice_remap_for_fighter` (`0x0086AF70`)
leaves Kakashi ID 8 unchanged; its ID 1 branch can suppress cue 0 under the
checked alternate predicate but does not renumber nonzero cues. The phase
call `battle_phase_queue_voice6_first` (`0x008740F0`) queues member 6 using
fighter character +0x64 and side bit +0x60. Both checked characters have
member 6 in both banks. Earlier phase calls queue -1, which stops the slot
before member admission fails. Complete producer reachability and the meaning
of every cue are not established. These streamed requests do not establish
compact SNDDATA program-to-sample decoding.

#### NUN3 streamed bank language

**Own-game code and resource observations:** `settings_menu_create_sprites`
(`0x002BB220`) calls `menu_create_named_texture_sprite` (`0x002A1180`)
with `settings_option_container_name` (`0x005F6F48`, `option`) and
`audio_voice_choice_texture_name` (`0x005F6F60`, `TEX_option_so`).
`sprite_bind_named_texture` (`0x001781F0`) resolves that named texture in the
container and binds it through `sprite_bind_texture_record` (`0x00178110`).
The resulting sprite is stored at menu `+0x64` and used by
`audio_settings_draw_voice_choice` (`0x002BD5C0`). Its
`audio_voice_choice_rectangles` (`0x0047DE30`) identify these labels:

| Menu `+0x1C` | Unselected rectangle `(u, v, width, height)` | Selected rectangle | Visible label / PLVOICE bank |
| ---: | --- | --- | --- |
| 0 | `(168, 232, 64, 20)` | `(168, 212, 64, 20)` | `ENGLISH` / 0 |
| 1 | `(104, 232, 64, 20)` | `(104, 212, 64, 20)` | `JAPANESE` / 1 |

The labels were read from the checked NUN3 `OPTION.CCS` texture
`TEX_option_so`, directory ID 61, using its referenced `CLT_option_so`,
ID 160; the atlas is 512 by 256 pixels. MCP exposes the binding and
rectangles but does not map external CCS pixels. The maintained CCS explorer
decoded the source read-only in memory; its upright bitmap uses the source
coordinates above. The complete-file identity is recorded with the
[character comparison inputs](../../game/files/file_identities.md#character-comparison-inputs).

`audio_settings_menu_initialize` copies the voice-set equality result directly
into menu `+0x1C`; confirmation in `audio_settings_menu_update` passes that
value directly to `audio_set_voice_set`, without inversion. Joined to the
streamed selection rule above, this establishes **bank 0 as English** and
**bank 1 as Japanese**. Individual spoken content remains unestablished.


## NUN4 tables

### Checked NUN4 compact contract

NUN4 `audio_load_character_bank` (`0x001DBB90`) uses RPC `0x9400`, waits for
the selected sample-byte completion value, and binds through `0x9052 + side`.
Its `SNDBASE.IRX` is byte-identical to the inspected NA2 shared module; complete
identities are in [Retail game file identities](../../game/files/file_identities.md#character-comparison-inputs).
The selected NUN4 bank rows are in the owning character-resource table.

Compact descriptor set **0 is English**, and set **1 is Japanese**. The
[language-setting evidence below](#compact-bank-set-language) joins the
menu's sprite labels to its inverse selector write; the UI-language index
used for display strings is a separate selector.

NUN4 `fighter_voice_event_list` (`0x001EA080`) selects base/alternate lists
for checked IDs 1 and 57; ID 9 has base/base pointers. Against
`battle_voice_controls` (`0x00433C80`), base events `0/0x18` select controls
0/26, programs 0/26 and default parameter `0x3C`. Both checked Naruto
alternates add 160, retaining programs 0/26 with parameter `0x3E`.
Base event `0x19` is disabled; alternate control 187 enables program 27,
default `0x3E`. Event `0x20` is disabled in both lists. This differs from
NA2 Naruto's alternate list/default; the final checked samples are established
under [Compact program-to-VAG lookup](../session/battle_audio.md#compact-program-to-vag-lookup).
NUN3 compact decoding was not part of this comparison. Its separate streamed
selector is established [below](#checked-nun3-streamed-bank-selection).

#### Compact bank-set language

**Code and resource observations:** `audio_settings_menu_create_resources`
(`0x003590A0`) finds `option.ccs` and binds `TEX_option` to the sprite at
menu `+0x08`. `audio_settings_menu_draw` (`0x00359AA0`) draws two choices
from `audio_voice_choice_sprite_regions` (`0x0057AD20`) and highlights the
index equal to menu `+0x2C`. Its five stored pairs repeat these rectangles:

| Menu index | Source rectangle `(u, v, width, height)` | Visible label | Compact set / settings `+0x0F` |
| ---: | --- | --- | ---: |
| 0 | `(345, 457, 78, 22)` | `JAPANESE` | 1 |
| 1 | `(345, 481, 78, 22)` | `ENGLISH` | 0 |

The labels were read from `TEX_option` (directory ID 75, palette
`CLT_option` ID 174, 512 by 512 pixels) in the checked NUN4 English-view
`OPTION.CCS`. MCP exposes the binding and rectangles but does not map the
external CCS pixels; the resource was decoded read-only in memory through
the maintained CCS explorer. Its complete-file identity is recorded with
the [character comparison inputs](../../game/files/file_identities.md#character-comparison-inputs).
`TEXTENG.BIN:audio_voice_mode_help_english` (`0x008917A0`) independently
names the English/Japanese choices; that help text alone does not give their order.

`audio_settings_menu_update` (`0x00359380`, inverse write at
`0x00359410..0x00359448`) passes 1 for menu index 0 and 0 for index 1 to
`audio_set_bank_set` (`0x001D8570`), which writes word `+0x10` in the
context referenced by `audio_command_context_ptr` (`0x006096F0`).
Committing the menu stores the same value in settings `+0x0F`;
`audio_apply_persisted_settings` (`0x0039CE90`) restores it through that setter.
`audio_settings_menu_read_current` (`0x00359300`) performs the inverse
conversion back into menu `+0x2C`.

`audio_bank_set_selector` (`0x001D85B0`) returns one exactly when the
context word equals 1. `audio_character_bank_descriptor` (`0x001D4D90`)
therefore selects `audio_character_banks` (`0x00435670`, English) or
`audio_character_banks_alternate` (`0x00435A18`, Japanese), then indexes
the selected set by character ID with 12-byte rows. In setup modes 1/2,
`audio_setup_mode_banks` (`0x001D4E50`) queues character operation 3 for
side 0 and side 1 with a wait after each; `audio_service_bank_transaction`
(`0x001DB350`) routes it to `audio_load_character_bank`, which uses those
selected rows for the SNDDATA load/bind described above. The checked IDs
1/9/57 and both sets' exact file ranges are in
[Compact fighter bank resources](../../game/character_assets.md#compact-fighter-bank-resources).
This establishes the retail setting identity of each set. The checked final
VAG selection is established above; spoken content remains unassigned.

### NUN4 checked jutsu resource load and caches

This comparison covers NUN4's two selected resident jutsu paths, the checked
BATTLE resource consumers and their data-cache release loops. Complete
selector maps, filenames and capacities belong to
[Separate jutsu resource domains](#separate-jutsu-resource-domains).
It does not extend the NA2 nine-slot layout or its release rules to NUN4.

NUN4 `battle_queue_fighter_ccs` (`0x00316140`) uses mask `0x04` for both
configured selectors. For sides 1/2, selector words are at manager
`+side*0x20+0x70/+0x74`. Each selector greater than 1 supplies a filename
through resident `jutsu_animation_archive_name` (`0x002D12E0`), joined to
`pl/`. The two path buffers are at manager `+side*0xF0+0x238/+0x256`;
nonzero new-load results write handles at `+0x1E8/+0x1EC` relative to the
same side base. The BATTLE selector-to-resource table is not read by this
path selection.

`ccs_require_container` (`0x001AD710`) instead strips path and extension
through `ccs_container_key_from_path` (`0x001AD780`) and searches published
container names. It makes no load request or ownership increment.
BATTLE `interaction_setup_jutsu_resources` (`0x007577B0`) requires the
translated resource filename, then looks for `BIN_skldamoffs_%s` in that
provider. `interaction_bind_jutsu_resource` (`0x0074C110`) borrows the
provider and a shared damage-offset-bank pointer into its interaction record.
`jutsu_initialize_resource_binding` (`0x00768D70`) separately borrows the
resource-selected provider into its jutsu object. Loader selection, provider
lookup and allocated interaction storage are distinct dependency edges.

The shared cache owns allocated `0x280`-byte damage-offset banks; each stores
pointers into the provider's BIN payload. The two per-side caches separately
own resource-count-sized arrays of `0x78`-byte interaction records.
`interaction_release_resource_caches` (`0x0074F870`) visits both 160-slot
per-side arrays, then the linked interaction records and all 160 shared bank
pointers, freeing and clearing the cache entries. Those cache loops free
their allocations; they do not establish the enclosing CCS provider's
lifetime. Complete provider release and retention for a selected donor remain
outside this bounded comparison.
