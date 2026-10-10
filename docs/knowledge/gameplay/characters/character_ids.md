# Character identity in battle

## Research coverage

Established: IDs 57/58/73 in four Practice captures, current versus selected
identity, selector gates, all 13 forward and 12 inverse form pairs, all 94 NA2
definition rows and their static NUN3 lineage. Open: remaining character
identities, ID 74's identity/use, auxiliary rows 29..31 and wider helper roles.
Names come from `@annotations/NA2` and `@annotations/NUN3`; routine comments
hold code detail. Static relationships do not establish ordinary reachability.

## Evidence identity and address conventions

Static findings use the maintained resident analysis of NA2 `SLPS_258.37`
and NUN3 `SLUS_217.27`; all cited addresses are live resident addresses.
File identities and mappings follow
[Retail game file identities](../../game/files/file_identities.md).
Captured identities are bounded to Naruto, Sakura, direct selection of
Nine-Tailed Fourth Awakened State, and an in-match Naruto transformation.
Screenshots establish matchups; extracted EE memory establishes the
selector, manager, pointer, ID and resource values. Heap pointers are
capture-specific. The NUN3 comparison is static and establishes no NUN3
battle observation.

## Confirmed IDs

| ID | Character | Character Select | Active Practice fighter |
| ---: | --- | --- | --- |
| 57 (`0x39`) | Naruto | Confirmed | Confirmed |
| 58 (`0x3A`) | Sakura | Confirmed | Confirmed |
| 73 (`0x49`) | Nine-Tailed Fourth Awakened State | Confirmed | Confirmed |

The save-backed character-status array stores 94 IDs, `0..93`. Character
Select's playable-entry checks use `1..93`; ID 0 is a special/non-playable
stored entry. See [Content availability](../../game/content_availability.md) for
the save-backed domain and unlock-reader contract.

## Native relationships

Each character's compatible active states are the union of its
fighter-controller association list, every non-`0xFFFF` post-effect in its
Ultimate-Jutsu records, and the effects applied by hard-coded transformed-form
initialization and character-specific direct or successor paths. The union
does not imply how the game normally enters each state; see
[Awakening](awakening.md).

A playable character maps to a separate native support-roster ID; some
characters have no support entry. Two native linked-attack tables, one for
Ultimate Jutsu and one for jutsu, associate a selected character with support
IDs; characters absent from a table have no linked attack of that kind. These
runtime tables hold numeric IDs only. HP, durability and multiplier fields of
each character's definition record are in
[Damage](../combat/damage.md#confirmed-character-record-fields).

## Character Select evidence

`character_selector_resolve_fighter` reads the selected character ID from
`CharacterSelectData.fighter_ids`. Changing the selected tile between the
two captures changed the table value from 57 for Naruto to 58 for Sakura.
`character_select_commit_choices` publishes the resolved choices to
`BattleManager.current.sides[].character_id` and copies them to
`saved.sides[].character_id`. Saved choices preserve match-start identity
after an in-match transformation changes current identity.

### Selector ID filters

The selector's numeric eligibility gate accepts only `1..93` and requires
both fixed filters to return zero. Despite its retained name,
`roster_character_valid` returns **one to exclude** this exact set:

```text
0, 8, 9, 20, 21, 23..33, 44, 45, 74, 88
```

`roster_secondary_filter` always returns zero and excludes no ID.
The playable reference has no row for any ID in the fixed excluded set.
This agreement supports treating `roster_character_valid` as a roster-hole
filter in this path, while the reason each numeric slot exists remains
unresolved.

Held-input bit `0x08` (R1) makes `character_selector_handle_fighter_input`
set `CharacterSelectorInput.form` to 1; releasing it clears the field.
The independent `profile_progress_at_least_101` gate clears it unless signed
progress is strictly above `0x65` (at least 102), regardless of its retained
name. With form 1, `character_selector_resolve_fighter` validates the selected
ID, maps it with `character_to_transformed`, validates the mapped candidate
with the same range and filters, and requires `character_is_transformed`.
That predicate recognizes exactly `47..56` and `73..75`. A rejected mapping
keeps the original ID. A valid form also needs save-backed availability unless
the selector has a fixed fighter; that availability is owned by
[Content availability](../../game/content_availability.md#fighter-and-support-availability-dependencies).

### Hard-coded linked-form mapping

`character_to_transformed` is the complete forward mapping used by the
selector path. It accepts either side of each pair and returns the form ID; any other input
returns zero. Names in this table come from the canonical character reference,
while the numeric relationship is observed directly in the clean ELF.

| Base ID | Base character | Form ID | Form character | Inverse in `character_to_base` |
| ---: | --- | ---: | --- | --- |
| 1 (`0x01`) | Naruto Uzumaki (Classic) | 47 (`0x2F`) | Naruto Uzumaki (Nine-Tailed) | Yes |
| 2 (`0x02`) | Sasuke Uchiha (Classic) | 48 (`0x30`) | Second Stage Sasuke Uchiha | Yes |
| 3 (`0x03`) | Rock Lee (Classic) | 49 (`0x31`) | Loopy Fist Lee | Yes |
| 4 (`0x04`) | Gaara (Classic) | 50 (`0x32`) | Possessed Gaara | Yes |
| 14 (`0x0E`) | Choji Akimichi (Classic) | 51 (`0x33`) | Super Choji | Yes |
| 34 (`0x22`) | Jirobo | 52 (`0x34`) | Second Stage Jirobo | Yes |
| 35 (`0x23`) | Kidomaru | 53 (`0x35`) | Second Stage Kidomaru | Yes |
| 36 (`0x24`) | Tayuya | 54 (`0x36`) | Second Stage Tayuya | Yes |
| 37 (`0x25`) | Sakon | 55 (`0x37`) | Second Stage Sakon | Yes |
| 38 (`0x26`) | Kimimaro | 56 (`0x38`) | Second Stage Kimimaro | Yes |
| 57 (`0x39`) | Naruto Uzumaki | 73 (`0x49`) | Nine-Tailed Fourth Awakened State | Yes |
| 62 (`0x3E`) | Granny Chiyo | 74 (`0x4A`) | Unresolved; no playable-reference row | No |
| 63 (`0x3F`) | Sasori | 75 (`0x4B`) | Sasori (Puppet) | Yes |

`character_to_base` implements the inverse form-to-base mapping for the 12 rows
marked **Yes** and returns `-1` otherwise. ID 74 is deliberately asymmetric in
the observed helper family: the forward mapper produces it and the form-set
predicate recognizes it, but `roster_character_valid` excludes it and the
inverse mapper omits it. In `character_selector_resolve_fighter`, that
exclusion rejects the mapped candidate and falls back to the original ID.
It is therefore a latent or disabled mapping in
this selector path; its character identity and any other consumer are not yet
established.

The mappings are shared beyond the selection-return path. Their annotations
retain the verified caller inventory; this does not establish one shared
semantic role for every consumer.

## Character-definition table

NA2 `character_definition_table` (`0x005A2900`) holds 94 eight-byte
`CharacterDefinition` rows indexed by character ID, with named `factory`
and `record` fields. Records use `AwakeningCharacterRecord`.
Battle dispatch through the factory word is documented in
[Battle entities](../session/battle_entities.md#primary-fighter-factory-and-lookup);
record fields with known battle consumers are in
[Damage](../combat/damage.md#confirmed-character-record-fields).

**Observation:** Dedicated and auxiliary records store their own ID in
`character_id`; filler copies retain ID 1 rather than their table index.
Row 0 is `{0, 0}`. The rows below do not describe a playable character
of their own:

| IDs | Factory | Record | Content |
| --- | --- | --- | --- |
| 8, 9, 20, 21, 23..25, 27, 28, 32, 33, 44, 45, 74, 88 | `fighter_id_001_create` | `naruto_classic_character_record` | Filler copy of ID 1 (Naruto Uzumaki (Classic)). All four character-filename tables in [Character asset tables](../../game/character_assets.md) are null for these IDs. |
| 26, 29, 30, 31 | `fighter_id_001_create` | `auxiliary_1a_character_record`, `auxiliary_1d_character_record`, `auxiliary_1e_character_record`, `auxiliary_1f_character_record` | Distinct own-ID records, empty `body_filename` and `display_name`, `action_count` 4, `row_count` 12 and `animation_count` 78; animation-name slots are empty. Action records 1 and 3 carry jutsu names; all four filename tables are null. |

Each auxiliary animation row is a `CharacterAnimationRow` of size `0x4C`;
the layout is owned by
[Character asset tables](../../game/character_assets.md#character-records).
ID 29's `auxiliary_1d_jutsu1_name` and `auxiliary_1d_jutsu3_name` render
`二人の切り札` and `砂塵舞う螺旋丸`.

These are exactly the IDs `1..93` that `roster_character_valid` excludes from
the selector, so the excluded set is the set of rows that lack a dedicated
fighter. ID 26's record is the auxiliary Jutsu metadata owner `0x1A` for
selectors `0x34` and `0x35`; see
[Content availability](../../game/content_availability.md#auxiliary-jutsu-selectors-0x34-and-0x35).
How rows 29..31 are used is unresolved.

### NUN3 ID lineage

NUN3 `character_definition_table` (`0x00476730`) uses the same eight-byte
`{factory, record}` format, named in `Nun3CharacterDefinition`. Rows `1..56`
are populated and row 57 is zero. Its `Nun3CharacterRecord.display_name`
is Shift-JIS and `body_filename` holds the body code, as NA2's do.

**Observation:** Every ID that has a dedicated fighter in both games names the
same character: IDs 1..7, 10..19, 22, and 34..56 have the same body-file code
in both tables. NUN3's rows at NA2's excluded IDs are:

| ID | NUN3 name | NUN3 code | NA2 row |
| ---: | --- | --- | --- |
| 8 | カカシ | `kks` | Filler |
| 9 | 大蛇丸 | `orc` | Filler |
| 20 | ガイ | `guy` | Filler |
| 21 | 自来也 | `jry` | Filler |
| 23 | イタチ | `itc` | Filler |
| 24 | 鬼鮫 | `ksm` | Filler |
| 25 | 綱手 | `tnd` | Filler |
| 26 | *(none; 4 action records)* | *(none)* | Jutsu-bearing record |
| 27 | シズネ | `szn` | Filler |
| 28 | カブト | `kbt` | Filler |
| 29, 31, 33 | *(filler copy of ID 1 in NUN3 too)* | — | 29 and 31 jutsu-bearing; 33 filler |
| 30 | 暗部 | `anb` | Jutsu-bearing record |
| 32 | ナルトＺ | `nrz` | Filler |
| 44 | アスマ | `asm` | Filler |
| 45 | 紅 | `krn` | Filler |

NA2 adds IDs 57..93 after the NUN3 range. Its later versions of several NUN3
characters use new IDs and new codes, for example Kakashi `70`/`kkw`, Might
Guy `69`/`guw`, and Orochimaru `89`/`orw`, rather than reusing the NUN3 slot.

**Inference (high confidence):** NA2's ID space is an extension of NUN3's.
The vacated NUN3 fighter slots were kept as filler rows and excluded by the
selector rather than renumbered, so shared characters keep their NUN3 IDs and
NUN3-only characters have no dedicated NA2 row, filename entry, or selector
eligibility.

## Active-battle identity

The resident global `battle_manager` points to the live `BattleManager`.
The capture-derived identity contracts use these named fields:

| Field | Meaning |
| --- | --- |
| `BattleManager.current.sides[0].character_id` | Player 1 current ID (32-bit) |
| `BattleManager.current.sides[1].character_id` | Player 2 current ID (32-bit) |
| `BattleManager.saved.sides[0].character_id` | Player 1 match-start selected ID (32-bit) |
| `BattleManager.saved.sides[1].character_id` | Player 2 match-start selected ID (32-bit) |
| `BattleManager.fighters[0]` | Player 1 fighter pointer |
| `BattleManager.fighters[1]` | Player 2/COM fighter pointer |
| `Fighter.opponent` | Opponent pointer; reciprocal in both base-character captures |
| `Fighter.character_id` | Active ID (32-bit) |
| `Fighter.chakra` | Current resource (`float32`); native substitution also spends it |

In Naruto versus Naruto, manager choices were 57/57 and both live fighter IDs
were 57. In Sakura versus Naruto, manager choices were 58/57 and the
live fighter IDs were 58/57. The heap pointers themselves are capture-specific;
the global and named field layouts are the reusable contracts.

Two additional Practice captures distinguish direct form selection from an
in-match transformation. With the Nine-Tailed Fourth Awakened State selected
directly, the match-start, current-manager, and live-fighter IDs were all
73/73. With base Naruto selected for both sides and Player 1 transformed during
the match, the match-start IDs remained 57/57 while the current-manager and
live-fighter IDs became 73/57. `BattleManager.saved.sides[].character_id`
is therefore the selection-time identity source that remains stable across
the observed transformation. The captured nonnegative IDs were read as
unsigned 32-bit words; the saved declarations use `int`, without changing
their width or these observed values.
