# Content availability and state ownership

## Research coverage

Established: resident reader ownership, fighter/form and support dependencies,
stage and mode gates, complete bounded Jutsu eligibility tables, progress gates,
and all six Collection groups, ownership/viewing, NEW scans and Movie caches.
The NUN4 ID-9/NA2 ID-89 comparison covers roster status readers and native
jutsu admission.
Open: Movie acquisition, small-table indices 22..31, several eligibility
producers, other difficulty-word writers and indirect access outside the audit.
Names come from `@annotations/NA2` and `@annotations/NUN4`; static evidence
establishes bounded paths.

This document records the availability gates of retail NA2 (`SLPS-25837`)
and the saved, resident, and temporary state consumed by frontend and battle
selectors, plus the bounded NUN4 Orochimaru comparison below.

Profile serialization and layout belong to [Save-data record format and
lifecycle](save_data.md); roster presentation to [Native Character Select
flow](character_select.md); stage identity and loading to
[Stages](../gameplay/stages/stages.md); mode construction to [Mode flow](mode_flow.md);
and the difficulty-word producer's result gates to
[Survival](../gameplay/modes/survival.md). Wider acquisition controllers are
outside this investigation. Recorded memory comparisons corroborate values,
not every acquisition or lifecycle transition. Indirect calls and inlined or
bulk memory access remain outside the direct-reference evidence.

## Evidence identity

All addresses are live and follow [Retail game file
identities](files/file_identities.md#address-conventions). Routine comments and
named data in `@annotations/NA2` hold code-level detail. The resident ELF,
`BTL.BIN` and `ETC.BIN` are separate programs even where overlay addresses
overlap.

## Live manager and profile mapping

The resident global `battle_manager` points to the `BattleManager`; its
`profile` field points to the live `SaveProfile`. Availability wrappers consume that profile.
Heap addresses in recorded comparisons identify allocation instances.

The resident global `live_profile` points directly to the same live profile;
it must not be followed as another manager. `resident_flow_dispatch` owns the
allocation and manager construction borrows it
([Save-data lifecycle](save_data.md#resident-save-ownership)).

## Resident readers

| State | Routine | Live entry | Result |
| --- | --- | ---: | --- |
| Character status bit 0 | `profile_roster_available` | `0x001F54C0` | Boolean |
| Secondary support bit | `profile_secondary_available` | `0x001F5750` | Boolean |
| Small availability table | `profile_small_get` | `0x001F7030` | Raw byte |
| Grouped content | `overlay_abi_target_001f70c0` | `0x001F70C0` | Raw byte |
| Character/Jutsu pair | `profile_ability_get` | `0x001F7210` | Saved bit after eligibility gates |
| Progress word | `profile_word1_get` | `0x001F7780` | Raw word |

`profile_roster_available` masks bit 0 from `profile_status_load`.
Character Select adds its ID, metadata and linked-form filters outside that
reader; a set bit alone does not establish a roster entry.
`profile_secondary_available` delegates to `profile_secondary_bit_get`.
`profile_small_load` and `profile_grouped_load` retain the stored byte,
rather than reducing it to owned/unowned.

The first 22 `SaveProfile.small_availability` entries are item counts indexed
by the resident [field-item name
table](../localization/field_item_names.md#resident-field-item-name-table).
`battle_item_selection_update` transfers units between those bytes and
`BattleItemSelectionView.selected_units`: adding a selection decrements the
saved count, removing it increments the count, and cancellation returns all
selected units through `profile_small_set`. Its cursor domain is 0..21 and
its return-all loop covers 22 entries, so this path cannot produce indices
22..31.

`profile_small_reset` clears all 32 entries through `profile_small_store`,
including the ten unnamed entries. Wider snapshot/restore copies also cover
all 32 bytes, but do not establish an in-scope acquisition or meaning for
22..31. Their copy contract and the secondary-bank mirror belong to
[Save-data lifecycle](save_data.md#secondary-block-and-opaque-tail) and
[Save-data layout](save_data.md#header-settings-and-resident-availability-state).

`profile_ability_get` checks native-owner or cross-character eligibility
before `ability_bit_get` reads `SaveProfile.abilities[character]`.
A saved selector bit cannot admit an incompatible pair.

## Fighter and support availability dependencies

`character_select_fighter_available` first applies the numeric and metadata
filters owned by [Character
identity](../gameplay/characters/character_ids.md#selector-id-filters).
It then uses `character_to_base` to require a recognized form's base before
checking the original ID's saved status bit. With the retail inverse map, a
base needs its own bit and a recognized form needs both bits: every mapped
base has no predecessor. This establishes the retail dependency, without
requiring an arbitrary form chain.

Ordinary editable form resolution in `character_selector_resolve_fighter`
uses that predicate. A fixed constructor choice bypasses the saved-bit
check while retaining numeric and metadata filtering. Constructor and final
choice ownership belong to [Character
Select](character_select.md#appearance-fixed-choices-and-final-handoff).

A null manager bypasses the predicate's saved-bit checks. This is caller-side
admission; the reader itself has no null-manager contract. Ordinary manager
construction supplies a fresh or loaded live profile.

`character_select_populate_supports` assigns the 33 native support IDs
state 4 for a set secondary bit, state 5 for a clear bit, and state 7 for
sentinel `0x24`. A null manager also gives state 4.
Recommendations and compatibility are independent gates
([Character Select compatibility](character_select.md#compatibility)).

Fresh/reset initialization grants the fixed 22-character set and clears all
secondary support bits ([Fresh-profile
initialization](save_data.md#fresh-profile-initialization)). A clear support
bit therefore does not alone exclude selection: the recommendation exception
still matters. A granted bit does not bypass compatibility.

## Resident stage-slot availability

`stage_slot_set` and `stage_slot_get` share the resident bit bank rooted at
`stage_availability_bits`; both ignore the manager argument. Each slot has an
independent bit, and the reader returns Boolean availability.

`stage_slots_initialize`, reached by `profile_reset`, enables
`native_stage_slots`: exactly 0..23. It leaves other positions untouched.
`stage_select_build_choices` reads only those 24 slots and admits each
directly when the manager is null. Consequently the recorded initialization
provides all 24 native Stage Select choices
([Native Stage Select](stage_select.md#choice-list)).

This bank is resident state, separate from `SaveProfile.small_availability`
and from the manager's current or remembered stage. The active/saved slots
and battle-load handoff belong to
[Stages](../gameplay/stages/stages.md#archive-preload-adoption-and-switching).
The bounded producer audit found the initializer; it does not exclude
indirect or inlined writes.

## In-scope mode gates

`mode_select_build_slots` admits physical slots whose `mode_select_results`
value is nonnegative, without consulting profile availability. Free Battle,
Practice, Collection and Options are admitted. Their physical/result mapping
and remembered selection belong to
[Mode flow](mode_flow.md#mode-select-result-table).

`menu_select_saved_gate` accepts port 0 for all four; port 1 directly accepts
only Free Battle and Practice. Collection and Options reject port 1 through
the modal path. `mode_select_decode_direct_input` distinguishes the two
Circle actions, `mode_select_dispatch_input` forwards their source, and
`mode_select_update` supplies separate `ModeSelectInput.port_pressed`
snapshots. Acceptance stores the source in temporary
`BattleManager.active_side`, without writing the profile.
Other mode branches are outside this gate's established scope.

## Jutsu admission and saved bits

`profile_ability_get` admits eligibility when `jutsu_native_owner` returns
exactly 1 or `jutsu_cross_character_allowed` returns nonzero, then requires
the saved selector bit. For native owners, both `character == selector >> 1`
and the signed interpretation of `ActionRecord.owner_character` must agree.
Numerical pairing alone is insufficient. The owner path bypasses the
cross-character exclusions.

The cross-character predicate's complete fixed inputs are named as follows:

| Input | Annotation | Live address |
| --- | --- | ---: |
| Ten rejected characters | `jutsu_cross_character_rejections` | `0x005C0C50` |
| 26 special selectors | `jutsu_cross_character_selectors` | `0x005C0C70` |
| Twelve exclusion lists | `jutsu_selector_exclusions` | `0x005C0CE0` |
| 43 character/list mappings | `jutsu_character_exclusions` | `0x005C12E0` |
| Restricted selector exception | `jutsu_restricted_selector` | `0x005C1440` |

Rejected character IDs are `0x1A, 0x1D, 0x1F, 0x21, 0x08, 0x14,
0x17, 0x18, 0x1E, 0x20`. Special selectors in source order are:

```text
8D 16 19 1B 1F 21 45 47 4B 57 5D 69 3F
75 85 89 8B 9B AB 91 8F A5 A9 A7 34 83
```

A selector outside that set is rejected. For a mapped character, a matching
exclusion rejects it; a list beginning with `-1` rejects all special
selectors. An unmapped character otherwise starts admitted after preceding
gates. The final `0x34` exception restricts it to character `0x46`; it never
revives a pair rejected earlier.

All character/list mappings and exclusions follow. IDs are hexadecimal;
display names were not recovered for every row.

| List | Character IDs, hexadecimal | Excluded selectors, hexadecimal |
| ---: | --- | --- |
| 0 | `2F 30 33 31 32 26 38 25 37 24 36 23 35 22 34 49 4B` | All (`-1` first word) |
| 1 | `03 28 43` | `8D 16 19 21 45 47 4B 57 5D 69 3F 75 85 89 8B 9B AB 91 8F A7 34 83` |
| 2 | `29` | `8D 16 19 21 45 47 4B 57 5D 69 3F 75 85 89 8B 9B AB 91 8F A7 34` |
| 3 | `4C` | `8D 19 1B 1F 21 45 47 4B 57 5D 69 3F 75 89 8B 91 A5 A9 A7 34 83` |
| 4 | `07 06 0A 41 47 48 40 53 59 4D 3F 5D` | `8D` |
| 5 | `01 27 39` | `A7` |
| 6 | `0F` | `8D 1B AB` |
| 7 | `2E` | `8D A7` |
| 8 | `55` | `8D 1B` |
| 9 | `4E` | `21` |
| 10 | `3E` | `9B 8D` |
| 11 | `3D` | `8D 1B 1F 4B A5 A9` |

Character `0x03` admits special selectors `0x1B, 0x1F, 0xA5, 0xA9`;
`0x29` additionally admits `0x83`. Character `0x4C` admits
`0x16, 0x85, 0x9B, 0xAB, 0x8F`. A form assigned list 0 can still use its
metadata-valid own pair through the owner predicate. These tables establish
eligibility; every admitted pair still needs its saved bit.

`profile_abilities_reset` calls `ability_bits_reset` to clear each record
and grant the two own selectors, plus `0x34` for character `0x46`.
Other characters have no third default (`jutsu_default_extra_selector = -1`).
`profile_ability_set` checks only cross-character admission when setting
value 1; clearing skips it. Default own bits come from initialization.
Writing a bit does not override the reader's owner-or-cross-character gate.

### Auxiliary Jutsu selectors `0x34` and `0x35`

`jutsu_select_step` visits IDs 2..`0xBB` and uses `profile_ability_get` for
admission; `jutsu_select_update` uses the same predicate to count choices.
Eligibility is evaluated before saved availability.

Boot initialization installs these entries from
`auxiliary_1a_character_record` and `auxiliary_1a_actions`:

| Mapping | Selector | Table entry | Action record | Metadata owner | CCS resource |
| --- | ---: | --- | --- | ---: | --- |
| T2210 `Ninja Hound Summoning` | `0x34` | `hound_selector_entry` | `hound_selector_action` (index 1) | `0x1A` | `hound_jutsu_archive_name` (`2kkvcha1.ccs`) |
| T2211 `Demon Wind Bomb` | `0x35` | `demon_wind_selector_entry` | `demon_wind_selector_action` (index 3) | `0x1A` | `demon_wind_jutsu_archive_name` (`2nrocha1.ccs`) |

The metadata owner `0x1A` is not a playable entry in the 74-character
reference. Classic Naruto's character ID is `0x01`.
`jutsu_cross_character_selectors` and `jutsu_restricted_selector` admit
`0x34` for Kakashi (`0x46`), whose fresh record also receives that bit.

Selector `0x35` is absent from the special set; its only compatible native
owner is `0x1A`. Ordinary Jutsu Select therefore cannot supply Demon Wind
Bomb for a playable character even when its saved bit is set.

Generic consumption is complete: `jutsu_select_draw` resolves the title
through `support_linked_jutsu` and `jutsu_selector_title`;
`jutsu_animation_archive_name` returns the resource.
`actions_setup_working_array` uses `jutsu_selector_character` and copies
odd selector `0x35`'s records 2 and 3 into the live Jutsu slots. It is
consumable if supplied; the ordinary playable producer does not supply it.

## Progress gates

`profile_word1_get` reads `SaveProfile.secondary.word_bank1`.
Index `0x6A` is the Ultimate difficulty gate, independent of
`SaveProfile.secondary.byte_bank2[0x6A]`. Their equal indices do not join
their ownership or meaning.

`difficulty_selector_update` and `difficulty_selector_draw` reduce the
six-value Strength maximum from 5 to 4 only when the manager exists and the
word is zero. Null manager retains 5. The sixth value displays Ultimate.
`battle_strength_update`, `battle_strength_draw`,
`practice_adjust_option` and `practice_draw_row_selection` use the same
condition, starting from their row-count tables.
Separate enabled-row conditions belong to
[Practice mode](../gameplay/modes/practice_mode.md#row-availability).

### Recovered difficulty-word producer

`survival_finish_course` (`BTL.BIN`, live `0x006EC5B0`) writes
`profile_word1_set(manager, 0x6A, 1)` for course index at least `0x18`.
Only course 24 satisfies that condition in the native 25-course domain.
Acknowledging its eligible result grants the word unless it is already
exactly 1; a top-three time is unnecessary. The admission gates, course table
and final-result announcement belong to
[Survival](../gameplay/modes/survival.md#difficulty-word-producer).
Other writers, indirect calls and inlined stores remain possible.

### Form progress gate

`character_selector_handle_fighter_input` sets
`CharacterSelectorInput.form` for held mask `0x08`, then immediately clears
it if `profile_progress_at_least_101` is false, before
`character_selector_resolve_fighter` uses `character_to_transformed`.

Despite its preserved annotation name, that predicate requires the signed
`SaveProfile.secondary.word_bank1[0]` to be strictly greater than `0x65`
(102 or higher). A null manager returns false. Recorded memory comparisons
found `0x66` in a fully progressed profile and 0 without a loaded save.
Unlike roster and difficulty admission, null manager cannot enable forms.
[Save-data lifecycle](save_data.md#secondary-block-and-opaque-tail) identifies
the word as a main-progression ordinal, without assigning chapters; its
acquisition flow remains outside this investigation.

## Stored availability fields

[Save-data record format and lifecycle](save_data.md#record-layout) owns the
layout. These are observed stored values in `SaveProfile`, not claims about
every native acquisition path.

| Field | Count | Fully unlocked loaded profile | No-save runtime profile |
| --- | ---: | --- | --- |
| `character_status` | 94 bytes | ID 0 `FF`; IDs 1..93 `03` | Mostly `00`; `03` at IDs 57..61, 65..70, 73, 78..87 |
| `secondary_availability` | 64 bits | all `FF` bytes | all `00` |
| `small_availability` | 32 bytes | all `FF` | all `00` |
| `figures` (group 0) | 93 | index 0 `03`; remainder `FF` | all `00` |
| `music` (group 1) | 41 | all `FF` | all `00` |
| `voices` (group 2) | 155 | all `FF` | all `00` |
| `skills` (group 3) | 168 | all `FF` | all `00` |
| `movies` (group 4) | 7 | index 0 `03`; remainder `FF` | all `00` |
| `dioramas` (group 5) | 12 | all `FF` | all `00` |

`profile_grouped_reset` confirms the six counts. Collection record tables,
viewer group choices and embedded class strings establish the content labels.
ETC consumes all six groups.

## Native grouped-content lifecycle

| Group | Content | Count | Record-table annotation |
| ---: | --- | ---: | --- |
| 0 | Figures/Dolls | 93 | `collection_figure_records` |
| 1 | Music | 41 | `collection_music_records` |
| 2 | Voice | 155 | `collection_voice_records` |
| 3 | Skills/Ultimate Jutsu | 168 | `collection_skill_records` |
| 4 | Movies | 7 | `replay_movie_map` |
| 5 | Dioramas | 12 | `collection_diorama_records` |

`collection_figure_bundles` and `collection_voice_bundles` each group
content into 31 character bundles. `CollectionBundleRecord` names their
character, price, first record, count and record pointer.

| Byte value | Native meaning |
| ---: | --- |
| 0 | Default/unowned/not promoted; prerequisites can still make it eligible |
| 1 | Available or announced, still unowned |
| 2 | Owned and NEW/unviewed |
| 3 | Owned and viewed/stable |

The bounded ETC writer inventory promotes 0 to 1 for Figure, Voice and Music
offers. Skills can be eligible at zero; no group-3 state-1 writer was found.
`collection_award` writes state 2, using character bundles for Figure and
Voice and one ID for Skill and Music. No ETC writer of Movie state 1 or 2,
or Diorama state 1, was found.

Every Collection viewer requires ownership greater than 1, then persists 3:
`collection_figure_open`, `collection_diorama_open`,
`collection_skill_open`, `collection_voice_open`,
`collection_movie_confirm` and `collection_music_open`.
Exact-2 NEW scans cover all groups.

Figure IDs equal their `collection_figure_records` index.
`collection_figure_open` also sets the selected list cache to 3.
Thus state 3 is the stable viewed-and-unlocked Figure state.

### Movie list state and acquisition limits

`collection_movie_initialize` removes old nodes and creates independent
`ContentListNode` copies of `replay_movie_map` IDs and saved group-4 state.
`content_id` identifies the Movie, `cached_state` holds its copied byte,
and `next` links the nodes. These are list-local values, not pointers into
the saved Movie bank.

`collection_movie_confirm` first requires `cached_state > 1`, then rereads
the saved state for `content_id` and rejects values below 2. Only after both
checks does it persist 3 and update the selected cache to 3. An admitted
cache alone cannot bypass current saved ownership.

`collection_movie_release` releases the nodes and
`CollectionMovieViewer.list` owner. This lifecycle has no newly-owned Movie
producer. Wider resident restore copies all seven Movie bytes; its acquisition
flow is outside this investigation. The copy contract belongs to
[Save-data lifecycle](save_data.md#secondary-block-and-opaque-tail).

The bounded callback search did not establish another writer. Register-built
targets, carried interior profile pointers and bulk writes remain possible.
Movie state-1/state-2 acquisition and nonzero producers or meanings for
small-table indices 22..31 remain unresolved.

### Collection-root NEW badges

`collection_kind_present` builds three category flags:

- Characters scans all Dioramas, then Figure, Skill and Voice entries grouped
  through the 75-entry `collection_character_table`.
- Movie scans all seven group-4 entries.
- Music scans all 41 group-1 entries.

Every scan tests exactly state 2; a category draws NEW only when its flag
is set.

### Derived Diorama unlocks

`collection_diorama_menu_initialize` visits all 12
`collection_diorama_records`. For a state below 2 it skips negative
`DioramaCharacterLink.character` IDs and checks whether any linked character
owns any Figure (group-0 state greater than 1). The first success persists
Diorama state 2, and opening it later persists 3. The rule requires any
linked character, not all six.
