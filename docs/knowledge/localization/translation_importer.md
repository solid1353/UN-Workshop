# NA2 and NUN5 text correspondence

Retail NA2 (`SLPS-25837`) text ownership and its official NUN5 English
counterparts: displayed-string selection, homologous record families, and
packed messages.

## Research coverage

Established: the documented menu, Practice, Ninja Song, Collection, Jutsu,
Command Chart, confirmation and memory-card text relationships and storage.
Open: untraced selecting paths and records without an exact homolog or owner;
memory-card screenshots cover only format/creation failures and create-data confirmation.
Names come from `@annotations/NA2` and `@annotations/NUN5`; addresses are live.
Table membership or matching wording alone does not prove displayed selection.

Memory-card message layout belongs to
[Confirmation Font layouts](font/screen_layouts/confirmations.md#message-boundaries);
Collection graphics and prompts belong to
[Collection UI draw-path analysis](ui/collection.md). Retail inputs are identified
in [Standard game file identities](../game/files/file_identities.md).

## Shared modal and Character Select strings

Character Select's resident option-string block begins at
`character_select_assignment_1p_2p`; its return confirmation is
`character_select_return_prompt`. NUN5's homolog is
`Return to Game Mode Screen?`.

The generic modal selects `modal_yes` and `modal_no`. Collection selects
its separate `collection_no` and `collection_yes` records, with the same
official English choices. The sources remain distinct even when the wording
matches.

Mode Select uses `mode_select_return_prompt`, whose NUN5 wording is
`Return to Title Screen?`. Save/Load and Character Select confirmations
have different sources and capitalization.

## Settings string references

`battle_settings_draw_rows` uses `battle_settings_labels` and indexed
`battle_value_arrays`. The six label homologs, in row order, are
`Time`, `Difficulty`, `Items`, `Chakra`, `Ultimate Jutsu`, and
`Handicap`. `battle_settings_defaults_message` corresponds to
`Battle Settings returned to defaults.`.

`practice_settings_draw` selects labels through `practice_labels` and
row-local value arrays through `practice_values`. Entries 10..16 select
the seven Practice Settings rows in order. Value arrays belong to both
`BTL.BIN` and the resident ELF, including the distinct pairs
`practice_off_on_505bc0`, `practice_off_on_505bd0`, and
`practice_off_on_505bd8`. Rows displaying `Normal` can select separate
records.

`character_selector_draw_linked_mode` reads the two-word
`character_select_linked_labels` pair. Its second pointer selects
`character_select_linked_auto`. Pointer fields and source text slots are
separate owners.

### Battle and Practice quit confirmations

For both return destinations, the BTL modal builds its body in this order:

`mode head + connective + destination + terminator`

The head is `start_menu_battle_text` or `quit_practice_head`; the shared
parts are `start_menu_end_and_text` and
`start_menu_return_confirmation_text`. Destination records are
`start_menu_character_select_text` and `start_menu_mode_select_text`,
separate from pause-menu labels.

NUN5's `quit_return_template` is
`Are you sure you want to quit %1 and return to %2?`. Its destination
records select `Character Select` and `Game Mode Select`. Choices use
the generic Yes/No records above. Paired Battle and Practice states establish
this composition for both destinations.

## Ninja Song units

NA2's `btl_record_definitions` arithmetic descriptors use
`ResultMetricDescriptor.unit_index`. Objective 6 selects index 2;
NA2's unit-pointer lookup reaches `ninja_song_timer_counts_unit` through
pointer-table index 3.

NUN5's `ninja_song_draw_objective_values` resolves the localized unit with
`NinjaSongArithmeticDescriptorView.unit_index + 4`. The selected English
text is `timer counts`. Objective 9's descriptor index 4 has no visible
NUN5 unit.

## Command Chart and Jutsu records

Command Chart names belong to 74 matching character record arrays.
`ActionRecord` is `0x54` bytes and its `display_name` selects the
displayed text. Corresponding NA2/NUN5 array indices identify homologous
records.

Ultimate and character-specific Jutsu names instead use the separate
`0x14`-byte `UltimateJutsuRecord` family at `jutsu_name_table`
(`0x005AEC40`). Its `display_name` is the first word; all four remaining
metadata words identify a homolog. String order alone does not.

`ultimate_jutsu_title_storage` (`0x005AD2D0`) is string storage,
distinct from the record table.

### Jutsu selector titles

The Jutsus selector uses Command Chart records despite its screen name.
In both games, `jutsu_select_draw` passes the selector through
`support_linked_jutsu` and then `jutsu_selector_title`, which reads the
first pointer of a `jutsu_animation_provider_table` row. NA2 reads
`ActionRecord.display_name`; NUN5 resolves `ActionNameView.display_name`
through `action_record_display_name`. This distinguishes the selector
from Collection strings and the metadata-owned `0x14` family.

For each displayed row, the nonlocalized metadata through the end of the
`0x54` record identifies the NUN5 homolog independently of its title.
`1000 Autumn Shower` is the sole duplicate: two NA2 records share one
source slot and match two NUN5 records; both select the same English string.

NUN5's `english_text_group_roots` resolves the homolog's `(group,index)`
selector. The record names below exist in each game's resident ELF
annotations. Their associated `_source` and `_title` rows name the NA2
source and NUN5 English storage, respectively; comments retain the exact
record correspondence.

| NUN5 English title | Homologous record name(s) | NUN5 selector(s) |
| --- | --- | --- |
| `Temple of Nirvana Technique` | `jutsu_temple_of_nirvana_technique_record` | `31:3` |
| `Water Style: Water Dragon Jutsu` | `jutsu_water_style_water_dragon_jutsu_record` | `11:1` |
| `Super Healing Medicine` | `jutsu_super_healing_medicine_record` | `12:3` |
| `Sacred Dance Shuriken` | `jutsu_sacred_dance_shuriken_record` | `13:3` |
| `Ninja Wolfsbane` | `jutsu_ninja_wolfsbane_record` | `15:3` |
| `Tunneling Fang ` | `jutsu_tunneling_fang_record` | `16:3` |
| `Earth Style: Sphere of Graves` | `jutsu_earth_style_sphere_of_graves_record` | `34:3` |
| `Giant Spider Drop` | `jutsu_giant_spider_drop_record` | `35:3` |
| `Explosive Destruction Formation` | `jutsu_explosive_destruction_formation_record` | `37:3` |
| `Water Style: Water Wall` | `jutsu_water_style_water_wall_record` | `43:3` |
| `Marauding Snakes` | `jutsu_marauding_snakes_record` | `46:3` |
| `Earth Style: Gushing Rock Mountain Cannonball` | `jutsu_earth_style_gushing_rock_mountain_cannonball_record` | `52:3` |
| `Naruto Uzumaki Combo Attack` | `jutsu_naruto_uzumaki_combo_attack_record` | `57:1` |
| `Great Ball Rasengan` | `jutsu_great_ball_rasengan_record` | `57:3` |
| `Killer Spring` | `jutsu_killer_spring_record` | `58:3` |
| `1000 Autumn Shower` | `jutsu_1000_autumn_shower_record / jutsu_1000_autumn_shower_record_2` | `62:3` / `77:3` |
| `8 Trigrams Sky Palm` | `jutsu_8_trigrams_sky_palm_record` | `65:3` |
| `Concealed Kunai Blast` | `jutsu_concealed_kunai_blast_record` | `66:3` |
| `Explosive Style Shadow Conceal: Improvement` | `jutsu_explosive_style_shadow_conceal_improvement_record` | `68:3` |
| `Night Phoenix` | `jutsu_night_phoenix_record` | `69:3` |
| `Lightning Blade` | `jutsu_lightning_blade_record` | `70:3` |
| `Fire Style: Fire Ball Jutsu` | `jutsu_fire_style_fire_ball_jutsu_record` | `71:3` |
| `Water Style: Water Shark Shotgun Jutsu` | `jutsu_water_style_water_shark_shotgun_jutsu_record` | `72:3` |
| `Beautiful Seasons` | `jutsu_beautiful_seasons_record` | `82:3` |
| `Heaven Defending Kick` | `jutsu_heaven_defending_kick_record` | `84:3` |
| `Ninja Art: Poison Fog` | `jutsu_ninja_art_poison_fog_record` | `85:3` |

### Moveset Ultimate and Jutsu titles

The third slot of moveset specials grids selects the `0x14` family.
Granny Chiyo (Taijutsu), unique-mode grid `0x4E`, selects ordinary moves
from her alternate ordinary-move block. An identical Collection title is a
different record.

`konohamaru_moveset_record` matches across the games by all four metadata
words and selects `konohamaru_moveset_title`. The NUN5 text is
`<BLACK>Charge! Konohamaru <color0808C0>Ninja Squad<BLACK>!`;
`konohamaru_collection_title` selects the plain copy. Retail NA2 also
contains native `<BLACK>` tokens.

Likewise, `temari_moveset_record` selects
`<BLACK>Cyclone Scythe <color0808C0>Jutsu` through
`temari_moveset_title`; `temari_collection_title` selects the plain copy.
The terminal red span belongs to the moveset record.

### Command Chart relationship strings

`command_chart_relationship_strings` selects `Charge-weak` and
`Charge-strong` at indices 16 and 17. `command_chart_charge_qualifier`
selects `Charge`, separately from `practice_charge_chakra_title`
(`Charge Chakra`). `command_chart_while_jumping` and
`command_help_while_jumping` likewise distinguish `While jumping` from
`(while jumping)`.

`air_strike_palm_source` has a NUN5 homolog selecting
`air_strike_palm_title`: the visible title is followed by LF and NUL.
The NUN5 one-line consumer ignores the terminal LF.

## Collection records

### Master roster and character plaques

`collection_master_roster` has 75 `CollectionRosterRecord` entries:
74 characters followed by the Diorama selector. Every Collection character
plaque, including the common Figurine viewer, consumes this master table.
The visible Diorama grid label comes from `HOME.CCS` artwork instead of
`collection_diorama_selector_title`; short character-grid labels are also
texture artwork.

Several families share `collection_granny_chiyo_source`, but the plaque
uses `collection_granny_chiyo_name_pointer` in the master roster. Its NUN5
homolog selects `Granny Chiyo ` with a terminal space
(`collection_granny_chiyo_title`), separately from the primary unpadded
`granny_chiyo_unpadded_title`.

`collection_locked_movie_title` supplies the locked Movie placeholder;
the official NUN5 counterpart is `???`.

### Collection Figure titles

Figure animation titles have their own namespace, separate from character
moveset and Jutsu names. Similar wording does not prove shared storage:
articles, nouns and qualifiers can differ.

The Figure table interleaves stable animation identifiers such as
`if...anm#` with display strings in NA2 `ETC.BIN`. NUN5 retains that
identifier sequence and selects its English strings from `TEXTENG.BIN`.
The identifier owning an NA2 slot therefore identifies its NUN5 Collection
record and selected title.

| Selected Collection title | Lookalike elsewhere |
| --- | --- |
| `Ninja Tool User` | `Tool User` |
| `Coercion` | `Pressure` |
| `A Sharp Kick` | `Sharp Kick` |
| `Giant Sword: Samehada` | `Samehada` |
| `My Favorite` | `Favorite` |
| `Heaven Kick of Pain` | `Heaven Kick` |

The selected strings are named by the `collection_figure_` annotation rows.

### Collection Ultimate titles

Collection Characters selects opponent-list Ultimate titles from
`collection_ultimate_records`, separately from resident moveset records
even when both select identical English text.

Immutable `CollectionUltimateRecord` entries place `display_name`
before their three metadata words. Instantiated
`CollectionUltimateScreenRecord` entries place it after those words.
The metadata and record order are retained. The paired Opponents capture
establishes the first displayed triple:

| Title | Metadata triple | NA2 captured record / display pointer | NUN5 captured record / display pointer |
| --- | --- | --- | --- |
| `8 Trigrams 64 Palms` | `(0x6E,0x3E8,0x0F)` | `0x00CE0208 / 0x006DC5C0` | `0x00C13588 / 0x008F7DF0` |
| `8 Trigrams 361 Style` | `(0x6F,0x7D0,0x10)` | `0x00CE0218 / 0x006DD370` | `0x00C13598 / 0x008F8730` |
| `Last Resort: Eight Gates Assault` | `(0x70,0xBB8,0x11)` | `0x00CE0228 / 0x006DD3B0` | `0x00C135A8 / 0x008F8750` |

These are captured instance addresses, not fixed table locations. The
`collection_ultimate_` string annotations name their selected storage.
Instantiated Collection ownership, metadata sequence and record order establish
the homologs; matching wording is the result.

Both immutable tables have 168 records. Indices 0..166 have identical
metadata triples in the same order, so each NUN5 pointer supplies that
index's official English title. Terminal record 167 is `Crystal Ice Mirrors`:
NA2 retains `(0x39,0x04,0x006D8E98)`, while NUN5 uses `(0xA8,0,0)`.
Both select the same title, and the terminal position is unambiguous.

Three valid NUN5 records select resident ELF strings:
`collection_ultimate_iq_200` (`IQ 200`),
`collection_ultimate_art` (`Art`), and
`collection_ultimate_uwabami` (`Uwabami`).
Some selected strings retain otherwise invisible trailing spaces.

### Collection Music and Voice titles

Music rows retain their sequence across homologous Collection tables.
The record for 「巨悪現る」 selects
`collection_music_a_great_evil_appears`, the complete
`A Great Evil Appears`. `Great Evil Appears` is its interior substring,
not a separately selected string.

Voice has a third Collection-owned namespace. Both
`collection_voice_records` tables contain 154 `CollectionVoiceRecord`
entries with `display_name`, `voice_id` and `type`.
All 154 metadata pairs match in the same order, including records selecting
resident ELF strings.

Three NA2 source strings appear in multiple Voice records. One duplicate
selects the same NUN5 text twice; the others select `The Match Begins`
versus `Duel Start`, and `A Cinch` versus `No Worries`.
Two further Voice records share Japanese storage with another namespace:
Figure `Myself` versus Voice `Me Myself`, and Ultimate
`Youth at Full Power!!` versus Voice `Youth at Full Power!`.

## NUN5 English markup

NUN5 uses paired byte-`0x40` delimiters as quotation markup. The
`quoted_white_picture`, `quoted_dragon`, `quoted_wild_dog`,
`quoted_petal_shower` and `quoted_divinity` strings contain
`@White Picture@`, `@Dragon@`, `@Wild Dog@`, `@Petal Shower@`
and `@Divinity@`, respectively. Collection and Command Chart render
those spans as quotation marks.

## Packed message structure

Some dialogs store consecutive NUL-terminated fragments in one fixed region.
The message table points to the first fragment; processing reaches
continuations in order and then the block terminator. The retail
`card_loading_message` has three fragments and one
`card_loading_message_pointer`. No direct continuation pointers were
found in the inspected retail ELF, BTL and ETC files.

`card_repair_confirmation` has two NA2 fragments selected by
`card_repair_confirmation_pointer`. The NUN5 English block states
`The Naruto Shippuden: Ultimate Ninja 5` and
`data on memory card (PS2)  in`, followed by
`MEMORY CARD slot 1 is corrupt!` and `Recover the data?`.

The surrounding family uses the same tables:

| Message storage | NA2 pointer record | Packed NA2 fragments |
| --- | --- | ---: |
| `card_corrupt_notice` | `card_corrupt_notice_pointer` | — |
| `card_load_failure_notice` | `card_load_failure_notice_pointer` | — |
| `card_recovery_progress` | `card_recovery_progress_pointer` | 3 |
| `card_recovery_failed` | `card_recovery_failed_pointer` | — |
| `card_recovery_completed` | `card_recovery_completed_pointer` | — |

NUN5's identically named storage annotations select the official English
counterparts. Fragment boundaries, region sizes and pointer values are in
the owning annotation comments.

## Memory-card failure messages

`card_format_failure` selects
`フォーマットに<ruby失敗|しっぱい>しました。` in a 48-byte padded NA2
slot, through `card_format_failure_pointer`. The NUN5 homolog is
`Format failed!`.

`card_creation_failure` selects
`セーブ<ruby領域|りょういき>の<ruby作成|さくせい>に<ruby失敗|しっぱい>しました。`
in a 96-byte padded slot, through `card_creation_failure_pointer`.
Its official English counterpart is `Creation of save data has failed.`.

User screenshots identify both Japanese messages in the lower message panel.
Static storage and selection establish the source records and official
wording; they do not establish either operation's failure cause or the blank
upper dialog.

### Other memory-card messages

NA2's `card_wrong_type_message` contains two adjacent strings within
96 bytes and states that the inserted card is not a PlayStation 2 memory
card. `card_save_set_preflight` returns 1 when the card type is neither
0 nor 2; `save_worker_update` converts that to status 7 and selects
`card_wrong_type_message_pointer`.

NUN5's `card_save_set_preflight` has the same card-type branch.
Its `save_worker_update` selects status 7 unless
`MemoryCardWorkerView.mode == 2`, when it selects status 6.
`memory_card_message_get` selects the current language's status entry.
The English initializer at `memory_card_english_status_initialization`
copies `card_absent_message_pointer` into statuses 5 and 6 and
`card_unsupported_message_pointer` into status 7. Both select
`card_absent_or_unsupported_message`:

`No memory card (PS2) is inserted in <br>MEMORY CARD slot 1.<br>Please insert a memory card (PS2) in<br>MEMORY CARD slot 1.`

The native English game therefore shares the absent-card message with
unsupported cards, while Japanese distinguishes them. This establishes
static selection, not wrong-card screen coverage. The resident ELF table
is `memory_card_messages`. The initializer's containing routine entry remains
unestablished.

| Message | NA2 region | Official NUN5 wording |
| --- | ---: | --- |
| `card_slot_selection` | 80 bytes | `Please select MEMORY CARD slot to save to.` |
| `card_load_failed` | 64 bytes | `Load failed!` |
| `card_save_failed` | 64 bytes | `Save failed! ` |

`card_insufficient_space_startup` has six NA2 fragments followed by zero
padding; NUN5's identically named block supplies the complete English
counterpart. Both this message and the absent-card startup message require
**103 KB** in NA2 and **102 KB** in NUN5. Ordinary lower notices and the
separate startup caller are owned by
[confirmation layouts](font/screen_layouts/confirmations.md#message-boundaries).
The retail comparisons establish text and storage, not complete screen coverage.
