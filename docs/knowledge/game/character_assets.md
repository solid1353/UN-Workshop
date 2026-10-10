# Character asset tables

## Research coverage

Established: NA2's character-indexed filename families, fighter CCS layout and
shared skeleton containers, character/form/action records and animation-name
tables, per-character code, the jutsu-resource filename mapping, the voice
archive layout and descriptors, compact fighter-bank resources, and match asset
selection, loading and release. Bounded NUN3 format comparisons explain where
NA2's layout departs from its predecessor.
Open: complete character dependency closure, effect-name consumption and most
row fields. Names come from `@annotations/NA2`, and from `@annotations/NUN3`
where a section compares NUN3. Donor character research for NUN3 and NUN4 is in
[NUN3 and NUN4 characters](../gameplay/characters/nun3_nun4_characters.md).

## Evidence and address conventions

This document owns playable-fighter files and static asset data in retail NA2
(`SLPS-25837`), with bounded NUN3 (`SLUS-21727`) and NUN4 (`SLUS-21862`)
comparisons.
Routine comments carry code details and search censuses. Addresses below are live.
Evidence is static clean-file and MCP analysis; load timing, residency,
missing/foreign-asset behavior and NUN3 execution are not established.
The inspected `SNDBASE.IRX` load/packet paths and embedded synthesizer
lookup are described in the owning audio research.

Clean file identities and address conventions follow
[Retail game file identities](files/file_identities.md). The CCS content
findings used gzip-decompressed clean files. Descriptive annotation names are
working identities, not recovered original symbols.

Related owners: [Resident CCS runtime](files/ccs_runtime.md),
[CCS object types](files/ccs_object_types.md),
[Disc inventory](files/disc_files.md),
[Character identity](../gameplay/characters/character_ids.md),
[Battle entities](../gameplay/session/battle_entities.md),
[Damage](../gameplay/combat/damage.md),
[Action commands](../gameplay/combat/action_commands.md),
[Substitution](../gameplay/characters/substitution.md),
[Asset dependency graphs](files/asset_dependencies.md#all-nine-per-side-selection-slots),
[End-demo presentation](../gameplay/modes/end_demo_presentation.md),
[Battle audio](../gameplay/session/battle_audio.md),
[Model and skeleton runtime](../runtime/rendering/model_runtime.md),
[Animation runtime](../runtime/animation_runtime.md),
[Texture/material runtime](../runtime/rendering/texture_material_runtime.md),
[Render submission](../runtime/rendering/render_submission.md), and
[Awakening](../gameplay/characters/awakening.md#static-reconstruction-order).

## Character-indexed filename families

The boot ELF stores four character-ID pointer tables of lowercase,
NUL-terminated CCS basenames, with 16-byte pooled names.
`???` is a three-byte character code.

| Family | NA2 table | Live address |
| --- | --- | ---: |
| `2???bod1.ccs` | `character_battle_body_filenames` | `0x004020F0` |
| `1???bod1.ccs` | `character_presentation_body_filenames` | `0x00402710` |
| `3???3eye.ccs` | `character_end_demo_filenames` | `0x00402D30` |
| `3???3pct.ccs` | `character_portrait_filenames` | `0x00403350` |

Each table has 94 slots for IDs 0..93. For every ID, all four families are
either null or name the same code. Populated IDs are exactly those with a
dedicated [character-definition row](../gameplay/characters/character_ids.md#character-definition-table):

```text
1 nrt  2 ssk  3 roc  4 gar  5 sik  6 nej  7 skr
10 hak 11 zbz 12 hnt 13 ten 14 tyo 15 ino 16 kib 17 sin 18 knk 19 tmr
22 hkg
34 jrb 35 kdm 36 tyy 37 skn 38 kmm 39 fou 40 khm 41 hnb 42 fir 43 sec
46 ank 47 nrv 48 ssv 49 rov 50 gav 51 tov 52 jrv 53 kdv 54 tyv 55 skv 56 kmv
57 nrw 58 skw 59 gaw 60 knw 61 tmw 62 chy 63 sco 64 ddr 65 new 66 tew
67 row 68 siw 69 guw 70 kkw 71 itw 72 ksw 73 nwv 75 scv 76 sch 77 cyb
78 kiw 79 snw 80 hnw 81 tyw 82 inw 83 jrw 84 tnw 85 szw 86 asw 87 krw
89 orw 90 kbw 91 ymt 92 sai 93 ssw
```

Every other ID, including 0, is null in all four tables. A valid numeric
character ID alone therefore does not establish that an asset family exists.

## Disc placement and file contents

NA2 keeps fighter files in `DATA.CVM` directory `PL/`, with `3EYE/` holding the
`3???3EYE` and `3???3PCT` families. NUN3 keeps its `1???BOD1`, `2???BOD1`, and
`2???CHA0/1` files at the `DATA.CVM` root and the `3EYE`/`3PCT` pair in `3EYE/`.
The four filename tables hold bare basenames; the directory comes from the
resident path construction described under the per-fighter load path below.

### CCS format

**Observation:** NA2 and NUN3 fighter CCS files begin with the same header
section `0xCCCC0001` carrying `CCSF`, the container name, and version word
`0x123`, followed by the table of contents `0xCCCC0002`. Both use the same
section-type set in fighter files: `0x0100`, `0x0200`, `0x0300`, `0x0400`,
`0x0700`, `0x0800`, `0x0900`, `0x0A00`, `0x0C00`, `0x2000`, and, in some NA2
files, `0x1900` and `0x2400`, besides `0x0005` and `0xFF01`. The object-type
identities are in [CCS object types](files/ccs_object_types.md). NUN3's clean
`STAGE/S04.CCS` has the same header version.

**Observation:** The file families contain:

| Family | Content in the compared files |
| --- | --- |
| `2???BOD1` | Battle body: roughly 110 `ANM_` animations, the body `MDL_`/`OBJ_` hierarchy, one `TEX_` and several `CLT_` palettes, and `CMP_eff_dummy_*` effect anchors. NUN3 `2NRTBOD1` and NA2 `PL/2NRTBOD1` both hold 118 source files and 111 animations; NA2's copy has more `OBJ_` rows (4,467 against 3,492). |
| `1???BOD1` | A second, animation-free model: about 88 `OBJ_`/`MDL_` pairs, eye, mouth, and body textures. NUN3's compared copies (`1NRT`, `1KKS`, `1ASM`) also contain a `x\name\???\name.bmp` source; NA2's compared copies (`1NRT`, `1KKW`) do not. |
| `2???CHA0`, `2???CHA1` | Jutsu resources: `ANM_p???cha0*`/`cha1*` animations, effect models, and textures, bound to both the `2cmn` and `1cmn` skeleton containers. |
| `3???3EYE` | Every file in both games (78 in NA2, 52 in NUN3) names its own `#c\1???\max\1???bod1.max` as an external source; all but two NA2 files and one NUN3 file also contain `c\3???\anm\3???win*` animation sources. |
| `3???3PCT` | Name and portrait visuals; see [Disc and archive file inventory](files/disc_files.md#ccs-directory-map). |

**Inference (high confidence):** `1???BOD1` is a second character model,
separate from the `2cmn`-based battle body, that the `3EYE` win animations
use. The [end-demo presentation lookup](../gameplay/modes/end_demo_presentation.md#request-and-lookup)
directly selects those animations and the 1BOD1 body/face resources together.
Explicit skill-stream dependencies and the cinematic replacement path below
also establish use of the family during jutsu presentation.

**Observation:** NA2's `3EYE/` also holds `3EYE` and `3PCT` files for
NUN3-only codes `guy`, `itc`, `kks`, and `ksm`, which the NA2 filename tables do
not name. Their `3PCT` files contain only a `p\cut_sp\sp_???.bmp` source and no
`TEX_name` object; they are the four name-less `3PCT` members noted in the disc
inventory. Their `3EYE` files reference `1???bod1` models that are not on the
NA2 disc.

**Observation:** NA2 `PL/` also contains `1???BOD1` files for NUN3-only codes
`asm`, `jry`, `kbt`, `krn`, `orc`, `szn`, and `tnd`, and for `ukn`/`ukv`. Each
is smaller than, and not byte-identical to, the NUN3 file of the same name. No
`2???BOD1` file exists on the NA2 disc for any NUN3-only code, and the only
NUN3-only `CHA` file is `2KBTCHA0`. No NA2 executable or overlay contains any of
these `1???bod1.ccs` names as a string.

### Explicit jutsu-stream body dependencies

**Clean-file observation:** The `SINF` request data in `STRMCMN.CCS` has 184
skill rows. The [request-table source](files/ccs_runtime.md#request-table-source)
owns the blob framing, relocation, and stream transport. Reading every row's
extra resident paths yields exactly these 13 rows with a `pl/1???bod1.ccs`
dependency:

| Skill row | Extra resident body files |
| --- | --- |
| `0x06` | `1ssvbod1.ccs` |
| `0x08` | `1rocbod1.ccs` |
| `0x0B` | `1gavbod1.ccs` |
| `0x1E`, `0x1F` | `1tovbod1.ccs` |
| `0x20` | `1tovbod1.ccs`, `1tyobod1.ccs` |
| `0x34` | `1jrvbod1.ccs` |
| `0x35` | `1jrbbod1.ccs` |
| `0x3C`, `0x3D` | `1uknbod1.ccs` |
| `0x40` | `1kmvbod1.ccs` |
| `0x4A` | `2nrwbod1.ccs`, `1nwvbod1.ccs` |
| `0x4D` | `1nrwbod1.ccs` |

These skill-row IDs are a separate domain from the two-per-character jutsu
selectors below. `sp_skill_play_start` selects the row;
`sp_skill_build_requests` turns its extra resident paths into requests.
Thus `1uknbod1` has a data-driven selection path despite its absence from
executable strings. The census covers explicit extra requests, not every
model reference embedded in a cinematic CCS.

`sp_skill_play_begin` constructs the replacement body owner with flags 2.
`sp_skill_select_body_composition` consequently uses the shared
`1cmnbod1` composition and body object; flag bit 0 instead selects the
corresponding `2cmn` resources. Character resources are sought in 1BOD1
before 2BOD1. For subtype 3, `sp_skill_bind_body_model` materializes the
shared composition and selected model, then attaches the model to the shared
body. This establishes model selection and attachment beyond file-level
skeleton references.

### Shared skeleton containers

Every compared body and jutsu file names `#c\2cmn\max\2cmnbod1.max` as an
external source, and jutsu files also name `#c\1cmn\max\1cmnbod1.max` and the
`1cmn` textures. The `#` rows are cross-container references resolved against
already loaded containers by name; see
[Cross-container references](files/ccs_runtime.md#cross-container-references).
The boot ELF names the providers `cmn/2cmnbod1.ccs` and `pl/1cmnbod1.ccs`.

**Observation:** NA2's `CMN/2CMNBOD1.CCS` holds 178 object names, all of which
are also in NUN3's 191. The 13 NUN3-only names are the `muffler` chain
(`OBJ_`/`MDL_2cmn00t0 muffler`, `muffler d`, and `muffler1..3`) and
`CMP_`/`OBJ_eff_dummy_cmnrun0` and `OBJ_eff_dummy_spn0`. NA2's
`PL/1CMNBOD1.CCS` lacks NUN3's `1cmn00t0 cloth3`, `joe d`, and `joe01` object
and model rows.

**Observation:** Checking every external `2cmnbod1` reference in the thirteen
NUN3-only `2???BOD1` files against NA2's provider: `jry`, `guy`, `szn`, `kbt`,
and `anb` resolve completely. `kks`, `orc`, `itc`, `ksm`, `krn`, `nrz`, and
`asm` each reference the four `OBJ_2cmn00t0 muffler*` rows; `tnd` also
references `muffler d`. NUN3 `2KKSCHA0` and `2ASMCHA0` reference
`OBJ_1cmn00t0 joe01` and `cloth3`, which NA2's `1cmnbod1` lacks.

**Inference (high confidence):** NA2's providers have no record for those
names, and the NA2 resolver leaves an unmatched `#` record at runtime sentinel
`4`, which is not a usable object pointer.

## Character records

The [definition table](../gameplay/characters/character_ids.md#character-definition-table)
selects a static boot-ELF record. Its asset fields are named in
`AwakeningCharacterRecord` (NA2) and `Nun3CharacterRecord` (NUN3):

| Field | Asset meaning |
| --- | --- |
| `character_id`, `display_name` | Identity and Shift-JIS fighter name |
| `body_filename` | `2???bod1.ccs` basename |
| `palette_names` | Twelve 30-byte colour-palette names, such as `CLT_2nrtbody/bodyc1/bodyc2` |
| `texture_names` | Two 30-byte texture names, such as `TEX_2nrtbody` |
| `model_names` | Two 30-byte model names, such as `MDL_2nrt00t0 body` |
| `effect_anchor_name` | `OBJ_eff_dummy_???hol0`; copied-name consumer remains open |
| `callbacks` | Per-character function table |
| `action_count`, `default_actions` | Count and 0x54-byte action records |
| `alternate_actions` | Optional working-array pointer; initially zero in compared static rows |
| `row_count`, `default_rows`, `working_rows` | Count, authored and writable 0x4C-byte rows |
| `animation_count`, `animation_names`, `animation_working_array` | Count, `ANM_` names and writable lookup storage |

Physical/balance parameters occupy record +0x58..+0xD8; established
consumers belong to [Damage](../gameplay/combat/damage.md#confirmed-character-record-fields).
The adjacent constructor descriptor begins at record +0xE0 and points back
to the record; examples are `naruto_classic_character_descriptor`,
`chiyo_character_descriptor` and `hiruko_character_descriptor`.

For Classic Naruto (1) and Classic Sakura (7), every parameter word
+0x58..+0xDC agrees between NA2 and NUN3. Only pointers and action/row counts differ:
Naruto has 47 actions and 183 rows in NUN3, against 48 and 190 in NA2.

NA2 and NUN3 `fighter_load_character_record` copy the same 55 words,
but into different fighter layouts. NA2 also has setup steps absent from the
NUN3 loader, including its owned child-list allocation. Asset code compiled
for one fighter layout cannot be assumed to use the other's fields.

### Model and appearance name consumers

`fighter_load_character` requires the selected body provider and the
shared `2cmnbod1` provider, then creates the shared
`CMP_2cmn00t0 trall` scene and selected model and attaches that model to
`OBJ_2cmn00t0 body`. These are named in `Fighter.body_container`,
`shared_body_container`, `model_collection` and `owned_handle_e68`.

Control bit 4 selects model slot 0 or 1. An empty slot 1 clears that bit and
retries slot 0. Appearance names are resolved from the selected body container:

| Consumer | Name slot |
| --- | --- |
| `fighter_refresh_material` | Fixed `MAT_clut` / `MAT_clut01`, selected by bit 4 |
| `fighter_refresh_palette` | `palette_names[colour + 3 * bit3 + 6 * bit4]` |
| `fighter_refresh_texture` | `texture_names[bit3 + 2 * bit4]` |

Here `colour = (control_flags >> 1) & 3`; bit 3 and bit 4 come from the
same byte. The three caches refresh when empty or forced. Empty palette or
texture names yield zero; the selector helpers impose no upper slot bound.

Classic Naruto has six nonempty palette slots: body/bodyc1/bodyc2 followed
by bod2/bod2c1/bod2c2, then six empty slots. Its texture slots hold
`TEX_2nrtbody` and `TEX_2nrtbod2`; only model slot 0 is populated.
These formulas and stored names do not establish that every flag combination
is reachable.

Initial setup applies palette/material when both resolve.
`fighter_effect_material_disable` clears a set control bit 3, forces all
three lookups and applies texture/palette to the shared scene. The
player-facing meaning and writers of these combinations remain unassigned.

The separate nine-row BTL lookup for hair, masks, accessories and glasses is
owned by [Battle lifecycle](../gameplay/session/battle_lifecycle.md#setup-helpers-after-fighter-publication).

### Form records and instance ownership

Complete appearance arrays were compared for these native base/form pairs:

| IDs | Annotated records, base / form | Body basenames | Slot-0 models |
| --- | --- | --- | --- |
| 1 → 47 | `naruto_classic_character_record` / `naruto_nine_tails_character_record` | `2nrtbod1.ccs` / `2nrvbod1.ccs` | `MDL_2nrt00t0 body` / `MDL_2nrv00t0 body` |
| 57 → 73 | `naruto_character_record` / `nine_tails_fourth_character_record` | `2nrwbod1.ccs` / `2nwvbod1.ccs` | `MDL_2nrw00t0 body` / `MDL_2nwv00t0 body` |
| 36 → 54 | `ai_character36_definition` / `tayuya_second_state_character_record` | `2tyybod1.ccs` / `2tyvbod1.ccs` | `MDL_2tyy00t0 body` / `MDL_2tyv00t0 body` |
| 63 → 75 | `hiruko_character_record` / `sasori_true_form_character_record` | `2scobod1.ccs` / `2scvbod1.ccs` | `MDL_2sco00t0 body` / `MDL_2scv00t0 body` |

Only ID 57 has a nonempty slot-1 model among these eight:
`MDL_2nrw01t0 body`. IDs 1 and 57 have six nonempty palette slots; the
other six records have three, all using their selected body's code.
IDs 1, 47, 57 and 73 have two texture names; IDs 36, 54, 63 and 75 have
only slot 0. These are stored-name observations. ID 57's second model
belongs to its existing body provider; the 57 → 73 identity change selects
a separate `2nwvbod1` provider. Replacement gates belong to
[Awakening](../gameplay/characters/awakening.md#static-reconstruction-order).

Common setup borrows existing CCS containers and issues no file request.
The scene, animation controller and model are fighter-owned instances.
`fighter_release_handles`, reached by `fighter_cleanup`, destroys those
instances and the fourth optional handle while leaving borrowed providers and
appearance caches intact. It never destroys the CCS containers. Manager
release therefore concerns a different allocation layer.
[Battle entities](../gameplay/session/battle_entities.md#common-fighter-owned-children)
owns complete lifetime dispatch; [Model runtime](../runtime/rendering/model_runtime.md)
owns instance construction/binding.

`effect_anchor_name` is copied to the fighter, but its consumer remains
unestablished. A bounded resident/BTL/ETC instruction screen found no copied-name
consumer; its census is on `naruto_classic_effect_anchor_name`.
Direct record access, other opcodes and differently formed aliases remain
open. The screen does not establish that the field is unused.

### Action records

NA2 and NUN3 use 0x54-byte records. Aligning Classic Naruto/Sakura on words
+0x0C..+0x18 shows one additional NA2 record at index 20; earlier records
match those words, while many later ones differ. Other words can differ even
in aligned rows, for example +0x2C values `0x0001041A` and
`0x0001041D`.

The corresponding fields are named in NA2 `ActionRecord` and NUN3
`Nun3ActionRecord`. `debug_name` is an NUN3 name such as `PL01_ATK_CHA1`,
but an empty string in NA2. `display_name` is English in NUN3 SLUS and
Japanese with ruby markup in NA2. `owner_character` and
`jutsu_selector` occupy the low/high halfwords of the packed identity
word; Sai record 3 is `0x00B9005C`, Sasuke record 3
`0x00BB005D`. `cost` is the chakra cost owned by
[Chakra and guard](../gameplay/combat/chakra_and_guard.md). Apart from
three string pointers, the compared authored records contain no pointers.

Records 0..3 follow NUN3 debug order CHB0, CHA0, CHB1, CHA1; slots 1 and 3
carry the two jutsu display names in both games. Sai (92) record 3,
`忍法・超獣偽画　狛犬`, and Sasuke (93) record 3, `千鳥`,
both cost 2.625.

### Animation-name and `0x4C`-stride tables

Animation-name arrays for IDs 1, 2, 7 and 34 agree between NA2 and NUN3; ID 47
differs in two names. Compared arrays begin with shared `ANM_pcmn*`
names before character-specific names, except NUN3 Kisame (24) and Anbu
(30), which use their own codes in the leading positions, such as
`ANM_pksmjmp2`.

Initial `fighter_load_character` resolves names with `cmn` at bytes
5..7 in the shared provider and other names in the body provider. Empty
names and reserved slots 0x46..0x4D initially remain zero.
`actions_setup_working_array` later binds those reserved slots using
the configured jutsu owner's animation-name array:

| Source action slot | Source animation-name indices |
| ---: | --- |
| 0 | 0x46..0x48 |
| 1 | 0x49 |
| 2 | 0x4A..0x4C |
| 3 | 0x4D |

Selector parity can swap source pairs. The selected names are copied into
the destination pair's lookup slots. The selector separately supplies the
provider through `jutsu_animation_archive_name`; shared names still
resolve in `2cmnbod1`. Object names and provider selection are distinct.

`actions_resolve_rows` copies authored rows into the writable array;
configured jutsu selection can replace rows 0..5 or 6..11 from the owner's
first or second six-row group. Moving the second group into the first remaps
0x4A..0x4D to 0x46..0x49; the reverse move reverses that remap. Unexpected
indices become -1. Action-pointer conversion belongs to
[Action commands](../gameplay/combat/action_commands.md#working-action-arrays).

The established fields of `CharacterAnimationRow` are:

| Field | Meaning |
| --- | --- |
| `animation_slot` | Lookup-array index; -1 ends the sequence |
| `duration` | Below 1, derive from animation frame count minus 1 and start frame |
| `start_frame` | Start frame used in that calculation |
| `skeleton_object_name` | Stored object-name pointer; consumer unassigned |

The duration interpretation comes from `fighter_predict_air_motion`.
Classic Naruto's first authored row names `OBJ_2cmn00t0 l foot`;
most remaining row fields remain open.

### Auxiliary-model animation providers

Chiyo's `chiyo_action_definition`, selected by
`fighter_id_062_construct`, supplies a different auxiliary binding path
through `chiyo_setup_puppets`. `ChiyoPuppetState` holds two 139-slot
lookup arrays. `chiyo_auxiliary_animation_names` interleaves all 278
source pointers, using `ANM_poya*`, `ANM_pfat*` and `ANM_pmot*`.

Outside reserved slots, nonempty names resolve in the body provider.
When the main reserved animation exists, its name is changed to the
auxiliary `fat` or `mot` code; slots 0x46..0x48 use the first configured
selector and 0x4A..0x4C the second. Optional lookup failure falls back to
auxiliary slot 0x29 (`ANM_pfatnut0` / `ANM_pmotnut0`).
Slots 0x49 and 0x4D use that fallback directly; an absent main animation
keeps the reserved auxiliary slot zero.

Each array gets an auxiliary scene from `CMP_2kgt00t0 trall`, with
`MAT_2kgtbody` and palettes `CLT_2kgtbody` /
`CLT_2kgtbodyc1` resolved from the body provider. These are additional
body-archive consumers, separate from common setup.

Hiruko's `hiruko_character_record`, selected by
`fighter_id_063_construct`, reaches `sasori_setup_puppets`.
Its `hiruko_auxiliary_animation_names` has 120 `ANM_pkkg*` pointers;
`SasoriPuppetState` names the lookup storage and pointer. Nonreserved
names resolve in the body provider. Populated main reserved names become
`kkg`; slots 0x46..0x49 use the first selector and 0x4A..0x4D the second.
Optional misses and slots 0x49/0x4D use slot 0x29
(`ANM_pkkgnut0`); absent main animations leave zero.

The scene uses `CMP_2kkg00t0 trall`. Six separate body animations are
`ANM_2kkgstt10`, `ANM_2kkgstt00`, `ANM_2kkgstt40`,
`ANM_2kkgstt50`, `ANM_2kkgstt60` and `ANM_2kkgskm00`.
If either selector is 0x7E and `2scocha0.ccs` is already found,
`ANM_2kkgchb00` is also bound. Its explicit provider name agrees with
resident selector 126. These bindings do not establish downstream auxiliary
battle behavior.

## Per-character code

Dedicated fighter definitions select resident factories that allocate concrete
fighters and call their constructors. Construction calls the common base,
installs the concrete vtable, supplies fighter-owned action/row/animation
storage to the selected record, loads it and runs character-specific setup.
Classic Naruto allocates 0x5630 bytes in NUN3 (`naruto_classic_create`)
and 0x5980 in NA2 (`fighter_id_001_create`); the corresponding constructors
are both named `naruto_classic_construct` in their own programs.

All factories and the seven-slot character callbacks are resident, rather
than battle-overlay entry points. The complete callback population across
78 distinct NA2 records is:

| Slot | Tables with a nonzero pointer |
| ---: | ---: |
| 0 | 25 |
| 1 | 74 |
| 2 | 78 |
| 3 | 74 |
| 4 | 44 |
| 5 | 13 |
| 6 | 13 |

Every dedicated fighter has slots 1, 2 and 3. Auxiliary records 26, 29,
30 and 31 populate only slot 2, with `auxiliary_id026_channel3`,
`auxiliary_id029_channel3`, `auxiliary_id030_channel3` and
`auxiliary_id031_channel3`. Classic Naruto populates slots 1..4 in
both games.

`character_dispatch_channel` maps events 1..3 and 5..7 to slots 0..2
and 4..6. It has no event-4 case, so populated slot 3 alone does not make
it an event-4 target.

During major 8, action indices 0..3 can use the configured jutsu owner's
callback table: actions 0/1 select the first jutsu selector, 2/3 the second.
A positive `jutsu_selector_character` selects that owner's table;
otherwise retail `receiver_vector_predicate` returns zero and the
fighter's copied table is used. The callback always receives the original
fighter pointer, even when its table belongs to another owner.
Gameplay documents own callback effects and timing.

NUN3 Kakashi's `kakashi_channel3` uses NUN3 fighter fields and resident
helpers, including its phase and particle-colour fields in
`Nun3FighterAssets`. **Inference (high confidence):** per-character
code is compiled against its game's fighter layout and resident addresses;
both differ from NA2.

## Jutsu-resource filename table

NA2 BTL `skill_resource_name_table` (live `0x008A7AA0`) and
NUN3 BATTLE `jutsu_resource_filenames` (live `0x00923DA0`) are flat
resource-index tables of `2???cha?.ccs` names.

The first 116 names agree, including every NUN3-only code's cha0/cha1 pair.
NA2 appends names and ends with `2bdycha0..4`. Resource order is not
character-ID order. Of the retained names, 33 have no NA2 disc file,
including all NUN3-only resources except `2kbtcha0`; eight, such as
`2forcha0` and `2dtucha0`, have no NUN3 disc file either.

### Selector-to-resource mapping

NA2 has two domains: `skill_selector_resource_table` (live
`0x008CB160`) translates selectors 0..187 through 188 signed words;
`skill_resource_name_table` has 197 resource filename pointers.
Resource 0 names `2nrtcha0.ccs`.

Across all 78 selected records, action 1's `jutsu_selector` is
`2 * record_ID`, action 3's is `2 * record_ID + 1`, and both
`owner_character` fields equal the record ID. This includes the four
auxiliary records and does not imply a playable fighter or same-code CCS.
Selectors 0 and 1 map to -1.

| Record ID | Selector | Resource index | Filename |
| ---: | ---: | ---: | --- |
| 26 | 52 / 53 | 154 / 115 | `2kkvcha1.ccs` / `2nrocha1.ccs` |
| 29 | 58 / 59 | 192 / 193 | `2bdycha0.ccs` / `2bdycha1.ccs` |
| 30 | 60 / 61 | 194 / 195 | `2bdycha2.ccs` / `2bdycha3.ccs` |
| 31 | 62 / 63 | 196 / 45 | `2bdycha4.ccs` / `2kbtcha0.ccs` |

Sai (92) selectors 184/185 map to resources 188/189
(`2saicha0/1.ccs`), and Sasuke (93) selectors 186/187 to 190/191
(`2sswcha0/1.ccs`). Hinata (12) selectors 24/25 map to 19/18 because
the filename pool places `2hntcha1` before `2hntcha0`.

`interaction_setup_jutsu_resources` translates the four configured
manager selectors and initializes the 197-pointer
`interaction_jutsu_resource_cache`. `interaction_preallocate_record_banks`
translates both fighter selectors and accepts resource indices below 197.
`ai_action_record_allowed` also reads selectors through this map.
These establish asset selection; auxiliary battle behavior belongs to gameplay
documents.

### Resident animation-provider filenames

NA2 resident `jutsu_animation_provider_table` (live `0x005A2320`)
has 188 eight-byte rows. `jutsu_animation_archive_name` directly returns
each row's filename; it does not use BTL translation.

Selectors 0 and 1 name `2cmnbod1.ccs`. Every other selector has a CCS
filename, including 126, whose `hiruko_jutsu_provider_name` names
`2scocha0.ccs`. Of the other 186 names, 170 agree with the BTL
selector path and 16 differ. IDs 8, 20, 23, 24, 32, 33, 74 and 88 use the
resident `2nrtcha0/1.ccs` pair while BTL selects the corresponding
retained code pair; none has a dedicated NA2 fighter definition.
Shared selector arithmetic does not make the two lookup paths interchangeable.

## Voice archive

**Observation:** NA2's `DATA/PLVOICE.AFS` has 93 outer entries. Reading entry
`n` as character ID `n + 1`, the null entries are exactly IDs 8, 9, 20, 21,
23..33, 39, 44, 45, 51, 74, and 88. NUN3's 112 entries form two 56-entry banks
with the same null pattern in each bank; read the same way, they are null at
IDs 26, 29, 31, 33, 39, and 51.

**Inference (high confidence):** The archive null patterns agree with character
ID minus one within each bank. The null sets match the definition-table rows without a dedicated
fighter, except IDs 39 and 51, which have fighters but no voice sub-archive in
either game. In NA2, every populated member's directory filename begins with
`PL` followed by its outer-entry character ID, strengthening that indexing
interpretation independently of the null pattern.

### Nested member layout

**Clean-file observation:** NA2 `DATA/PLVOICE.AFS` is 22,192,128 bytes and
NUN3's is 34,574,336 bytes; their tables were read from the clean
extraction. Both targets' annotations name the serialized file layouts.
At both outer and inner levels, the eight-byte `AfsArchiveHeader` holds
`magic` (`AFS` plus NUL) and the 32-bit little-endian `member_count`.
It is followed by eight-byte `AfsMemberEntry` rows with 32-bit little-endian
`offset` and `size` fields. Offsets are relative to the owning archive start,
so inner offsets use the sub-archive start.
Immediately after the inner member table, `AfsFilenameDirectoryLocation`
holds the directory's archive-relative `offset` and byte `length`, both
32-bit little-endian values. All inspected directory lengths are
`member_count * 0x30`; each `AfsFilenameDirectoryEntry` is 0x30 bytes with
a 32-byte `filename` and an unassigned 16-byte tail. All
nonempty member offsets are aligned to `0x800`, and every member fits within
its owning outer entry's declared size.

| Game | Populated sub-archives | Declared slots per sub-archive | Populated clips | Inner layout |
| --- | ---: | --- | ---: | --- |
| NA2 | 72 | `1..48`; commonly `39..44` for base fighters | 2,232 | Every declared slot is nonempty; first clip always starts at `+0x800`. |
| NUN3 | 100, across two banks | `209..256`; 76 archives declare 209 | 2,525 | Every archive is sparse; first clip starts at `+0x800` except the two 256-slot archives, which start at `+0x1000`. |

All 4,757 nonempty clips share first 12 header bytes
`80 00 00 20 11 00 00 01 00 00 5D C0`, consistent with the AHX type-`0x11`,
mono, 24-kHz classification in [Disc and archive file inventory](files/disc_files.md).
No dialogue meaning is inferred from those headers.

**Observation:** NA2's dense physical index is different from the numeric
suffix retained in its filenames. Classic Naruto's 40-member sub-archive starts with `PL01_000.ahx`, `PL01_002.ahx`,
`PL01_003.ahx`, and `PL01_045.ahx` in physical slots 0..3. Nine-Tailed
Naruto's four members (outer index 46 / ID 47) are named
`PL47_213.ahx`, `PL47_214.ahx`, `PL47_215.ahx`, and `PL47_217.ahx`.
Thus a voice number such as 213 cannot be used directly as a physical inner
index in that NA2 archive.

**Observation:** NUN3 retains sparse numbering: its ID 1 bank-0 archive has
27 populated slots at
`0..3, 6..7, 23..24, 45, 47, 49..50, 68..69, 85, 92, 111..112, 118,
125, 151, 165..167, 199, 202, 208`. Its ID 47 archives declare 218 slots,
with only `213..217` populated; ID 56 declares 256 slots, with only
`249..255` populated. Corresponding banks have identical populated-index
sets for every ID except 40: bank 1 additionally has member 182. The
[menu-texture evidence](../gameplay/characters/nun3_nun4_characters.md#nun3-streamed-bank-language)
establishes bank 0 as English and bank 1 as Japanese.
NUN3's own request code establishes direct sparse-member selection and the
56-entry bank offset in [Battle audio](../gameplay/characters/nun3_nun4_characters.md#checked-nun3-streamed-bank-selection).

### Voice descriptors and filename-number lists

NA2 resident `audio_plvoice_descriptors` has 93 eight-byte descriptors
selected by character ID minus one. `AudioArchiveDescriptor.archive_handle`
is `150 + outer_index`; `member_count` is the physical inner count.
All 93 counts match the clean archive, including null sub-archives.

`afs_startup_load_partitions` loads nested headers through
`afs_startup_load_nested`. `audio_request_archive_member` family 3
bounds the physical member against the descriptor, then passes its handle and
member through `audio_start_mono_member` to `cri_start_archive_member`.
`audio_consume_pending_streams` uses this family when the pending
row's alternate-family field is zero.

`voice_filename_number_lists` has 94 character-ID pointers, with null
slots matching null archive IDs plus 0. Every signed-halfword list ends at -1.
All 2,232 values, in order, match each physical member's filename suffix:
ID 1 begins `0, 2, 3, 45`; ID 47 is `213, 214, 215, 217`.
Sixty-two pointers select the main lists; ten compact initialized lists for
IDs 34, 35, 36, 38, 49, 52, 53, 54, 55 and 75 cover 21 clips.
For example ID 34 holds `149, 150, 151`, ID 75
`347, 348, 349`.

`audio_queue_player_voice` searches the selected list and retains its
position as the physical member, or -1 when absent. It writes
character ID minus one, physical member and player slot to an
`AudioPendingStream` row. Explicit BTL voice-number producers belong to
[Battle audio](../gameplay/session/battle_audio.md#recovered-btl-plvoice-producers).
The ordinary fighter path selects compact controls backed by `SNDDATA.BIN`,
as recorded below. It does not translate those controls into PLVOICE members;
[Battle audio](../gameplay/session/battle_audio.md#compact-voice-resource-and-lifecycle)
owns the separate command and loading paths.

### Compact fighter bank resources

NA2 `audio_character_bank_descriptor` (`0x001D3450`) indexes
`audio_character_banks` (`0x003FD830`) by character ID directly. Its three
words are a `SNDDATA.BIN` byte offset, IOP header allocation/read size, and
SPU sample-transfer byte count. The IOP loader reads the header at that
offset, then the sample data at `offset + align_up(header_size, 0x800)`.
These are file offsets and sizes, not EE addresses or PLVOICE member IDs.

| NA2 character / ID | Bank header file offset | Header bytes | Sample file offset | Sample bytes |
| --- | ---: | ---: | ---: | ---: |
| Naruto Uzumaki (Classic), 1 | `0x00421000` | `0x2200` | `0x00423800` | `0x6FAF0` |
| Naruto Uzumaki, 57 | `0x00DB1000` | `0x2120` | `0x00DB3800` | `0x5F1C0` |
| Sai, 92 | `0x0155C000` | `0x0F60` | `0x0155D000` | `0x28E80` |
| Sasuke Uchiha, 93 | `0x01586000` | `0x0F60` | `0x01587000` | `0x2FE20` |

**Clean-file observation:** each checked bank begins with IECS version/header
sections. Header words `+0x1C/+0x20` agree with its descriptor's header/sample
sizes. Its `Prog` section begins at bank-relative `+0x1660`, `+0x1580`,
`+0x0850`, and `+0x0850`, respectively. Each has word `+0x0C = 40` followed
by 41 offset words, indexed `0..40`; slots `9..11` and `27..35` contain
`0xFFFFFFFF`. The code uses `+0x0C` as an inclusive maximum index, not
an entry count. The `Vagi` maxima are 57, 39, 28 and 28. Exact selected
sample records and offsets are established in
[Compact program-to-VAG lookup](../gameplay/session/battle_audio.md#compact-program-to-vag-lookup).
MCP does not map this external data file, so these header observations used
read-only source bytes; the loader contract came from MCP code.

NUN4 `audio_character_bank_descriptor` (`0x001D4D90`) uses a separate
descriptor set when its audio context word `+0x10` equals 1. The sets begin
at `audio_character_banks` (`0x00435670`) and
`audio_character_banks_alternate` (`0x00435A18`). Its checked rows use the
same three-word load contract against NUN4's own `DATA/SNDDATA.BIN`:

| NUN4 character / ID | Descriptor set | Language | Bank header file offset | Header bytes | Sample bytes |
| --- | ---: | --- | ---: | ---: | ---: |
| Naruto Uzumaki (Classic), 1 | 0 | English | `0x00335800` | `0x2310` | `0x827F0` |
| Naruto Uzumaki (Classic), 1 | 1 | Japanese | `0x01814800` | `0x2310` | `0x76C70` |
| Orochimaru, 9 | 0 | English | `0x00641000` | `0x13B0` | `0x7AFC0` |
| Orochimaru, 9 | 1 | Japanese | `0x01AA9000` | `0x13B0` | `0x50B90` |
| Naruto Uzumaki, 57 | 0 | English | `0x00F79800` | `0x2310` | `0x88440` |
| Naruto Uzumaki, 57 | 1 | Japanese | `0x0225C800` | `0x2310` | `0x73120` |

[Battle audio](../gameplay/characters/nun3_nun4_characters.md#compact-bank-set-language)
owns the code-linked sprite evidence for the language labels and the setting
consumers; its [checked compact contract](../gameplay/characters/nun3_nun4_characters.md#checked-nun4-compact-contract)
owns the event-list comparison. Complete source identities belong
to [Retail game file identities](files/file_identities.md#character-comparison-inputs).

## Selection and loading consumers

### Publish six match asset selections

`manager_publish_six_selections` removes flag 0x100 from both character
IDs and publishes 2BOD1, 1BOD1 and 3EYE selections as three pairs. For each
basename it also borrows an existing container and packs its three-byte
character code.

All three filename-table rows must be populated after removing the flag:
there is no null check before reading the selected name. Container lookup
can return zero, which is retained. This distinguishes a valid filename
selection from an available provider.

The resident six-entry publication arrays are
`character_selection_filenames` (names), `character_selection_containers`
(borrowed containers) and `character_selection_codes` (packed code words).
Each occupies `0x18` bytes, indexed by three families and two actors.
The publisher writes all six names, then fills the corresponding containers
and packed codes.

### Per-side request, adoption and release

`battle_queue_fighter_ccs` builds selected 1BOD1, 2BOD1 and 3PCT paths
with mask bits 0x01, 0x02 and 0x10, alongside jutsu-provider,
support and cut-in paths. Its nine-slot layout, deferred adoption,
cache reset, masked release and pending-side release belong to
[Asset dependency graphs](files/asset_dependencies.md#all-nine-per-side-selection-slots).

Separate 3EYE request/adoption/release use
`end_demo_request_character_ccs`, `end_demo_adopt_character_ccs` and
the existing `presentation_completion_notify`. Their controller and
combined 3EYE/1BOD1 consumers belong to
[End-demo presentation](../gameplay/modes/end_demo_presentation.md).

### Loading-presentation portrait selection

`loading_request_character_portrait` requests `loading/spload.ccs`
and the selected 3PCT separately. The portrait reuses side 2's path and handle
in the [nine-slot layout](files/asset_dependencies.md#all-nine-per-side-selection-slots),
rather than allocating another cache. A published portrait gives no adopted
handle from `ccs_load_if_absent`; deferred mode starts the queue with
progress 1.

`loading_release_spload` releases and clears only the separate
`loading_spload_archive` container pointer.

`loading_create_character_presentation` requests synchronously, then
independently finds the portrait container and selects `TEX_name` before
creating presentation objects. It can consume a published portrait even if
the shared manager slot was not filled by that request. This establishes a
3PCT name-image consumer, not the full loading presentation or input behavior.
