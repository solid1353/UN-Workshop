# Save-data record format and lifecycle

## Research coverage

Established: retail NA2 save files/slots, record layout, checksum/copy contracts,
load/save/repair ordering, worker task lifetime and frame timing, defaults, settings, snapshots and recovered counters.
Open: discriminator/class/status-bit meanings, most secondary/opaque fields,
and early-failure reachability/reclamation. One historical card corroborates
these findings; it does not establish current execution or fault behavior.

## Evidence, identity, and terminology

Names and fixed-layout fields come from `@annotations/NA2`; resident and BTL
addresses are live. Embedded card modules lack separately mapped MCP programs
and verified relocation bases. Resident save globals are labeled in the
resident ELF's BSS.

Static analysis uses the clean resident ELF, BTL and ETC overlays, the embedded
card-service modules in `MODULES.BIN`, and conventions in
[Retail game file identities](files/file_identities.md#address-conventions).

Record offsets are absolute offsets within the little-endian `SaveProfile`.
`SaveSecondaryBlock` starts at record `0x0DFC`; `SaveDescriptor`, `SaveWorker`,
`SaveCardContext`, `CardDirectoryEntry`, and the dialog types name verified
fixed-layout fields. Storage shape alone does not establish semantics.
Inferences remain identified explicitly. Static failure paths were not exercised
with controlled corruption, allocation failure, short I/O or partial writes.
Adventure-mode consumers remain outside the inspected scope.

A read-only parse of one historical local card image corroborates the static
contracts but is not evidence of current
runtime state. Its relevant bytes are recorded in
[Historical-card corroboration](#historical-card-corroboration).

The related resident availability readers and their overlay consumers are
documented in [Content availability and state ownership](content_availability.md).
The startup UI and 30 Hz play-time presentation are documented in
[Startup sequence](startup.md).

## On-card files and visible-slot model

The native directory is `BISLPS-25837NARUTO5`.
`save_expected_filenames` names seven regular files:

| File | Written size | Source |
| --- | ---: | --- |
| `icon00.icn` | `0xE920` (59,680) | First `0xE920` bytes of disc `icon.bin` |
| `data01`, `data02`, `data03`, `data04` | Each `0x2400` (9,216) | Raw profile |
| `BISLPS-25837NARUTO5` | `0x40` (64) | Four `SaveDescriptor` rows |
| `icon.sys` | `0x3C4` (964) | Regenerated icon metadata |

The record is stored directly without an outer header, compression, encryption,
or container layer. Generic `card_read_record`/`card_write_record` can
name `data01..data13`; every recovered native create/scan/save/repair/UI path
uses only indices 0..3.

Files are addressed as the card context's directory path, `/`, and a name.
No native path deletes save data: `card_rpc_delete` (`0x00176800`, card RPC
command `0xF`) packages a path deletion but has no caller.

Exactly three primary slots are visible; the slot binding/rendering/counting/
selection routines use descriptors 0..2. Successful save writes the same
serialized buffer first to the selected primary and then `data04`.
The selected descriptor and row 3 receive the same occupied flag/checksum,
independently sampled live play times and individual file timestamps.
Each classification byte is preserved; row 3 has no source-slot field.

**High-confidence inference:** `data04` is one shared rolling copy of the last
saved visible slot. The historical card's exact `data01 == data04` bytes
corroborate this interpretation.

`card_create_icon` uses `icon_source_slice`, a `0x40`-aligned allocation,
and a disc read rounded to `0xF000`; card length remains `0xE920`.
The remainder of disc `icon.bin` is not written; its identity is owned by
[Retail game file identities](files/file_identities.md#na2-supporting-files).
`card_write_icon_sys` clears/rebuilds all `0x3C4` bytes from fixed
`PS2D`, title, settings and icon tables. `CardIconSystem.first_icon_name`,
`second_icon_name`, and `third_icon_name` each receive the eleven-byte
`icon00.icn` string including NUL; full slot capacities remain open.
No profile fields or payload checksum enter it.

The seven files occupy 97 rounded 1 KiB blocks. Native directory-overhead
arithmetic for nine entries adds six, giving `SaveCardContext.expected_blocks`
103. This assumes the expected files plus two directory entries and is not
measured allocation for an arbitrary card.

## Descriptor table

`SaveDescriptor` is exactly `0x10` bytes; four rows are the complete file,
without magic, version, aggregate checksum or trailer.

| Offset | Field | Width | Contract |
| ---: | --- | ---: | --- |
| `0x00` | `occupied` | 1 | Exactly 0/1 |
| `0x01` | `classification` | 1 | Signed; occupied accepts 0..4 |
| `0x02` | `checksum` | 2 | Additive payload sum |
| `0x04` | `play_time` | 4 | Displayed 30 Hz sample |
| `0x08` | `modified.reserved` | 1 | Not initialized/validated |
| `0x09` | `modified.seconds` | 1 | Modification timestamp |
| `0x0A` | `modified.minutes` | 1 | Modification timestamp |
| `0x0B` | `modified.hours` | 1 | Modification timestamp |
| `0x0C` | `modified.day` | 1 | Modification timestamp |
| `0x0D` | `modified.month` | 1 | Modification timestamp |
| `0x0E` | `modified.year` | 2 | Modification timestamp |

`save_descriptors_reset` clears occupied/classification/checksum/play_time,
sets non-reserved timestamp bytes to `0xFF`, and leaves reserved untouched.
The uncleared worker allocation can retain heap/prior-row residue there, which
is written with the raw table. Neither validation nor rendering consumes it;
historical zeros are not a format invariant.

`save_descriptors_valid` requires empty rows' classification/checksum/play_time
zero; occupied rows require signed classification 0..4 and signed play_time
0..`0x066FF2E2` inclusive (999:59:59 at 30 Hz). It ignores timestamps and
payload/checksum agreement. Reset/reconstruction write classification 0;
ordinary save preserves it. No other direct resident consumer was recovered,
so classes 1..4 remain semantically unresolved.

`save_scan_start` resets all rows and requests operation 3.
`save_worker_update` reads the table through `card_read_descriptors` and
copies all four rows only on structural acceptance. Rejection still reports
successful scan with reset/empty rows. An error in hidden row 3 therefore hides
valid primaries. Scan neither opens profiles nor recomputes sums; corruption
can remain apparently occupied until load.

An existing structurally invalid descriptor file is not automatically rebuilt
when `card_cached_timestamps_ordered` returns 1. Intact profiles can disappear
from the native UI. Comparator 0 adds a reconstruction trigger; its limitations
are described under
[Card-error ownership and cached timestamp classification](#card-error-ownership-and-cached-timestamp-classification).

`save_descriptor_refresh_timestamp` searches four cached `dataNN` rows.
No match leaves timestamp halfwords uninitialized before descriptor writes.
Ordinary save calls after both payload writes and a successful four-row query,
so the expected name should be present; the no-match path was not forced.

## Record layout

### Header, settings, and resident availability state

| Record range | `SaveProfile` field | Size/count | Contract |
| --- | --- | ---: | --- |
| `0x0000..0x0001` | `discriminator` | 2 | Unknown semantics; fresh 3 |
| `0x0002..0x0003` | `checksum` | 2 | Embedded additive sum |
| `0x0004..0x0007` | `play_time` | 4 | 30 Hz ticks |
| `0x0008..0x0009` | `display_x` | 2 | Signed horizontal offset |
| `0x000A..0x000B` | `display_y` | 2 | Signed vertical offset |
| `0x000C..0x000D` | `volume` | 2 | UI range 0..`0x100` |
| `0x000E..0x000F` | `audio_mode` | 2 | Inferred 0 mono/1 stereo |
| `0x0010` | `vibration_mask` | 1 | Bits 0/1: ports 1/2 |
| `0x0011` | `_gap_0011` | 1 | Structured-copy omission |
| `0x0012..0x0031` | `bindings[2][8]` | 16 × `u16` | Per-port action maps |
| `0x0032..0x0033` | `_gap_0032` | 2 | Structured-copy omission |
| `0x0034..0x0037` | `ryo` | 4 | Setter upper cap 9,999,999 |
| `0x0038..0x0907` | `abilities[94]` | 94 × `0x18` | 192-bit ability records |
| `0x0908..0x0965` | `character_status[94]` | 94 bytes | Bit 0 roster availability |
| `0x0966..0x0967` | `_gap_0966` | 2 | Structured-copy omission |
| `0x0968..0x096F` | `secondary_availability` | 64 bits | Availability bitset |
| `0x0970..0x098F` | `small_availability` | 32 bytes | Small availability table |
| `0x0990..0x09EC` | `figures` | 93 bytes | Figures/Dolls |
| `0x09ED..0x0A15` | `music` | 41 bytes | Music |
| `0x0A16..0x0AB0` | `voices` | 155 bytes | Voice |
| `0x0AB1..0x0B58` | `skills` | 168 bytes | Skills/Ultimate Jutsu |
| `0x0B59..0x0B5F` | `movies` | 7 bytes | Movies |
| `0x0B60..0x0B6B` | `dioramas` | 12 bytes | Dioramas |
| `0x0B6C..0x0DC3` | `survival_times[25][3]` | 25 × 3 × 8 | Signed character ID/cumulative seconds |
| `0x0DC4..0x0DF3` | `survival_wins[2][3]` | 2 × 3 × 8 | Signed character ID/completed wins |
| `0x0DF4..0x0DF7` | `gate_bits` | 4 | Bit 0 explicitly reset |
| `0x0DF8..0x0DFB` | `scalar` | 4 | Reset zero; semantics open |

`profile_ryo_draw` uses `ryo_display_format`,
`%s<ruby両|りょう>`, establishing ryo as currency. Rewards add to it and a
debug path grants 100,000. `profile_ryo_set` has only an upper cap, without
a lower clamp or load-time validation. Checksum-valid words outside
0..9,999,999 load verbatim until another writer changes them.

`roster_unlock_form_pair` sets unavailable target bit 0 and marks bit 1;
the optional `character_to_transformed` linked form gets only bit 0.
`profile_status_clear` clears the complete byte. No bit-1 meaning is established by the inspected direct consumers; inlined/indirect use remains open.

Grouped category names come from ETC tables/consumers, not byte counts.
Established values are 0 default/unowned, 1 offered/announced but unowned,
2 owned/new, 3 owned/viewed. Consumer thresholds differ; arbitrary nonzero
does not safely mean unlocked. Supporting behavior is owned by
[Content availability and state ownership](content_availability.md).

`profile_mirror_pairs`, resolved by `profile_small_table_index` through
`profile_small_ids`, establish this 22-entry permutation:

```text
small index:  0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19,20,21
bank index:   3,21, 7, 8, 9,10,11,12,13,14,15,16,17,18,20, 0, 1, 2, 4, 5, 6,19
```

`profile_small_table_to_byte_bank`/`profile_byte_bank_to_small_table` copy
in opposite directions between `small_availability` and `secondary.byte_bank2`.
This establishes the relationship, not wider semantics. Indices 22..245 are
untouched.

### Secondary block and opaque tail

| Record range | Secondary offset | Field | Storage |
| --- | ---: | --- | --- |
| `0x0DFC..0x114D` | `0x0000` | `byte_bank0` | 850 bytes |
| `0x114E..0x17F1` | `0x0352` | `halfword_bank` | 850 × `u16` |
| `0x17F2..0x1B43` | `0x09F6` | `byte_bank1` | 850 bytes |
| `0x1B44..0x1C5B` | `0x0D48` | `word_bank0` | 70 × `u32` |
| `0x1C5C..0x20FF` | `0x0E60` | `word_bank1` | 297 × `u32` |
| `0x2100..0x21F5` | `0x1304` | `byte_bank2` | 246 bytes |
| `0x21F6..0x21F7` | `0x13FA` | `_gap_13fa` | Two omitted bytes |
| `0x21F8..0x2213` | `0x13FC` | `opaque_13fc` | Seven aligned words; semantics open |
| `0x2214..0x2393` | `0x1418` | `opaque_1418` | 96 aligned words; semantics open |
| `0x2394..0x23FF` | Outside secondary | `SaveProfile.opaque_tail` | `0x6C` bytes |

`profile_copy_secondary` and independent
`profile_secondary_snapshot`/`profile_secondary_restore` agree on these
boundaries. Copy instruction choices do not establish floats or fixed-size
semantic records in opaque regions. Bank accessors do not check indices.

No semantic use of the first four banks is established by the inspected resident/BTL/ETC consumers; indirect and inlined uses remain open. The tail's established handling is whole-record
comparison and normal save/load copy, without a dedicated semantic reader/writer.
The independent snapshot pair moves aligned opaque ranges but excludes the
tail; its excluded-mode consumer was not interpreted.

**High-confidence inference:** `word_bank1[0]` is the main-progression ordinal:
`profile_word1_get` exposes it, `profile_progress_at_least_101` tests signed progression greater than
`0x65`, `loading_choose_random_asset` selects assets at thresholds
`0x3E`/`0x66`, and presentation objects range-test it. Individual story
chapters remain unassigned. `word_bank1[0x6A]` independently gates an extra
menu entry; other entries remain unresolved.

### Battle-result counters in the byte bank at `0x2100`

`profile_byte2_set`/`profile_byte2_get` access `secondary.byte_bank2[i]`.
BTL `survival_result_update_saved_counters` (`0x006EC2D0`) selects a
[Survival course](../gameplay/modes/survival.md#course-table) by
`BtlSaveResultController.course_index` and applies:

| Result kind | Update |
| ---: | --- |
| 0 | Unless `ranking_result == -2`, add signed course `counter_increment` to `counter_id` |
| 4 | Same increment without that gate |
| 5 | Increment course-group counter |
| 6 | Increment group counter and aggregate `0x6C` |

All writers clamp to 0..99; loaded bytes are not validated by that contract.
`survival_group_counter_rows` maps:

| Group | Byte-bank index | Record offset |
| ---: | ---: | ---: |
| 0 | `0x68` | `0x2168` |
| 1 | `0x69` | `0x2169` |
| 2 | `0x6A` | `0x216A` |
| 3 | `0x6B` | `0x216B` |
| 4 | `0x65` | `0x2165` |
| Aggregate | `0x6C` | `0x216C` |

The processor mirrors small availability into the bank before updates and
back afterwards; kind 0 with `ranking_result == -2` returns after the first
mirror. `result_update_saved_counter_a` (`0x006EB7A0`) and
`result_update_saved_counter_b` (`0x006ED820`) also increment an
object-callback-selected index by one, skip `-1`, and cap at 99.
Their content labels remain unresolved. Byte index `0x6A` at `0x216A`
differs from word index `0x6A` at `0x1E04`.

## Checksum and normal load/save

`save_task` advances `save_worker_update`. The normal checksum is:

```text
temporary.checksum = 0
C = sum(all 0x2400 temporary bytes) modulo 65536
```

Truncation after each addition is equivalent. There is no CRC, hash, salt or
per-section checksum. Byte permutations and compensating changes preserve the
sum and are undetectable. The descriptor sum is the only normal-load check.

### Load path

The worker requests `0x2400` bytes through `card_read_record`, destroys
the temporary's embedded checksum by zeroing it, and compares the sum only with
the selected descriptor. A match transfers the profile by structured copying.

Consequently checksum-byte-only corruption is ignored, successful load copies
zero into live `checksum`, and `discriminator` is not validated.
Profile `play_time` is neither range-checked nor compared with descriptor
time. Descriptor validation protects only its displayed sample; historical
32..34-tick drift corroborates independent values.

The only observed semantic discriminator test is repair's `0xFFFF` erased
sentinel. Reconstruction copies the embedded checksum without recomputing it,
making it indirectly authoritative only through that reconstruction.
Normal load has no rolling-copy fallback after checksum failure.

### Save path and ordering

Operation 8 reports `0x1A` empty or `0x1B` occupied;
`save_confirm_operation` schedules 9/10, which share one implementation:

1. Allocate an uncleared `0x2400` temporary and clone the live record.
2. Zero its checksum, sum every byte, and store the sum.
3. Write the selected primary then `data04`, attempting both even after
   the first reports failure.
4. After both writes and directory refresh succeed, update selected descriptor
   and row 3, preserving classification.
5. Write/close the whole descriptor file, then rewrite `icon.sys`.

There is no rollback. Failure can leave:

| Primary write | Backup write | Later outcome | Persistent possibility |
| --- | --- | --- | --- |
| Success | Failure | Metadata skipped | New primary, old descriptor |
| Failure | Success | Metadata skipped | New backup, old row 3 |
| Success | Success | Directory/table failure | New payloads, old/partial metadata |
| Success | Success | Descriptor succeeds, icon fails | New payloads/table, failed icon; reported failure |

A new backup with stale row 3 can subsequently be restored with the old checksum
and immediately fail normal load.

Time is sampled when the profile is cloned, then independently for both
descriptors after payload writes. `profile_play_time_tick` advances live time
while the manager exists and `BattleManager.flags` bit 0 is set, adding one
and saturating at `0x066FF2E2`. Serialized/primary/backup descriptor times
need not match. The historical selected/backup samples happened to match.

### Worker task and frame timing

The `SaveWorker` object is persistent, but its `SAVE_SYS` task exists only
while an owner keeps it: `front_end_gate_construct` starts it in mode 2 for
the Save/Load dialog, `startup_card_check_loop` in mode 0, and
`front_end_gate_destroy` stops it through `save_worker_request_stop`, which
also resets the worker to operation 1, status 4. Requests are field writes:
`save_scan_start` schedules operation 3, `save_record_select` operation 5,
operation 8 reports occupancy, and `save_confirm_operation` turns a confirmed
`0x1A`/`0x1B` into operation 9/10. Save completes with status `0x18`, result 1,
or fails with `0x19`, result 2. Before any card I/O, `save_worker_update`
resets the operation to 1 and, for loads, writes, creation and formatting,
publishes an in-progress status with result 4; that result alone marks the
work as running. Mode 1 classifies an unformatted card and an
absent game directory as terminal statuses `0x28`/`0x29` instead of the format
and create-data questions.

Card reads and writes block the calling thread: `card_rpc_wait` with mode 0
waits on the completion semaphore. `save_worker_start` gives the task control
flag 4, and `scheduler_update_loop` exempts control-4 tasks from its per-frame
wait for every task to sleep again, so frames continue while the worker blocks
on card I/O.

## Structured serialization and omitted bytes

| Piece | Owner | Record span |
| --- | --- | --- |
| Header | `profile_copy_header` | `0x0000..0x0007` |
| Main | `profile_copy_main` | Nominal `0x0008..0x0DFB` |
| Secondary | `profile_copy_secondary` | Nominal `0x0DFC..0x2393` |
| Tail | `save_worker_update` | `0x2394..0x23FF` |

Only `0x23F9` bytes transfer. Seven absolute bytes at `0x0011`,
`0x0032..0x0033`, `0x0966..0x0967`, `0x21F6..0x21F7` are omitted
in both directions. Load includes them in checksum validation but leaves live
gaps unchanged. Save checksums/writes uncleared temporary gaps.
Whole-record reset clears live gaps; no dedicated resident writer was recovered,
so established initialization/load paths keep them zero.

**High-confidence inference:** alignment padding carries stale allocator contents
on card. Each gap precedes the next aligned field, and historical values vary.
Native save can persist seven bytes of unrelated prior heap state; their source
allocation cannot be recovered from card bytes alone.

Within one save, primary/backup gaps and sums match. Across saves, semantically
identical live profiles can yield different files/sums.
`save_snapshot_changed` cannot detect residue introduced later in serialization.

## Fresh-profile initialization

`profile_construct` runs main, 94 ability-object and secondary
subconstructors, then clears all `0x2400` bytes, discarding earlier defaults.
`manager_initialize` calls `profile_reset` to clear and apply:

| Field | Fresh/reset value |
| --- | --- |
| `discriminator` | 3; semantics open |
| `checksum`, `play_time`, `ryo` | 0 |
| `display_x/display_y` | Cold start 0/0 |
| `volume` | Cold start `0x100` |
| `audio_mode` | Cold start 1 |
| `vibration_mask` | Cold start 3 |
| Secondary/small/grouped availability | 0 |
| `gate_bits` | Bit 0 explicitly clear; word remains zero |
| `scalar` | 0 |
| Secondary/opaque storage | Initially zero before later writes |

Later reset copies current display/audio globals and vibration cache, so it
need not reproduce cold settings. After load, `startup_load_profile` applies
display, `profile_apply_audio` audio, `profile_bindings_to_global` maps.

The display editor creates X `-48..48` step 3, Y `-16..16` step 1.
Load accepts any checksum-valid signed halfwords.
Audio choice 0 stores/applies 1 with `ANM_on_speaker2`; choice 1
stores/applies 0 with `ANM_on_speaker1`. Reset selects choice 0/volume
`0x100`. **High-confidence inference:** 1 stereo/two-speaker and 0
mono/one-speaker, from assets rather than recovered enums.
`audio_set_output_mode` accepts only 0/1. UI volume ranges 0..`0x100`
in steps of two; `audio_set_volume` does not clamp loaded values before
scaling. Normal load performs no per-setting sanity checks.

Vibration predicates consume bits 0/1; other stored bits survive without a
recovered predicate effect. Cold initialization builds mask 3 from
`default_vibration_enable == 1` as `b | (b << 1)`.
`profile_vibration_set` changes live record and cache; port below 1 resets
mask 3, but Controls confirmation uses only ports 1/2.
`manager_teardown` caches the active mask; later same-process reset inherits
it. `profile_vibration_enabled` is false without manager or in modes 8/9,
otherwise tests the requested saved mask.

Difficulty is not a profile field. Selector `0x0B` in
`manager_difficulty_get`/`manager_difficulty_set` accesses
`BattleManager.difficulty`, member 7 of the third 12-byte runtime-options
object. `practice_pack_defaults` initializes it to 2 (Normal).
Options writes it before snapshot comparison, so difficulty-only changes do not
dirty/serialize the profile. The byte lives for the manager's lifetime and resets on
construction independently of card load.

`resident_default_bindings` contains:

```text
0010 0020 0040 0080 0004 0008 0001 0002
```

| Saved index | Logical action | Default control |
| ---: | --- | --- |
| 0 | Ultimate Jutsu Prep | Triangle |
| 1 | Attack | Circle |
| 2 | Jump | Cross |
| 3 | Item Use | Square |
| 4 | Item Select | L1 |
| 5 | Linked Attack | R1 |
| 6 | Guard slot 1 | L2 |
| 7 | Guard slot 2 | R2 |

| Physical control | Stored mask |
| --- | ---: |
| Circle | `0x0020` |
| Triangle | `0x0010` |
| Square | `0x0080` |
| Cross | `0x0040` |
| L1 | `0x0004` |
| R1 | `0x0008` |
| L2 | `0x0001` |
| R2 | `0x0002` |

Whole-record reset leaves maps zero. `bindings_update(-1, 0)` resets global
maps before first manager publication, making its save synchronization a no-op.
After publication, `manager_setup` copies two fixed defaults into `bindings`.
`profile_bindings_from_global` performs later synchronization.

`options_controls_initialize`/`control_editor_masks` treat maps as
permutations of display-scan masks `20,10,80,40,4,8,1,2`. Native edit/swap
preserves them and `options_controls_confirm` reconstructs eight
action-order halfwords. Load does not validate uniqueness/recognized masks.
Missing/duplicate/foreign values can leave editor selections `-1`, later
used as stack-array indices on confirmation; that path was not exercised.
The shoulder selector cycles indices 4..6 and `control_action_labels` has
eight entries, first Ultimate Jutsu Prep. Captured control screen and historical
record bytes corroborate the mapping.

Status reset clears 94 bytes then sets `0x03` for 22
`profile_default_character_ids`:

```text
0x39..0x3D, 0x41..0x46, 0x49, 0x4E..0x57
```

Ability reset clears each 192-bit record then sets `2*i`/`2*i+1`;
character `0x46` also gets `0x34`. Secondary availability deliberately
skips sentinel `0x24` in `profile_secondary_availability_initializer`,
leaving all 64 bits clear.

Survival rankings seed 25 × 3 time pairs and 2 × 3 win pairs with independent
RNG modulo 94 IDs rejected by fixed `roster_character_valid`;
`roster_secondary_filter` always returns zero. No duplicate avoidance or
saved-unlock lookup occurs. Excluded IDs are
`0,8,9,0x14..0x15,0x17..0x21,0x2C..0x2D,0x4A,0x58`.

Time metrics are each `survival_seed_row_factors` byte multiplied by
60, 75, 90:

```text
2,3,3,3,3,3,2,3,3,3,3,3,4,5,5,3,3,5,5,5,5,5,5,5,5
```

Win metrics are 10, 8, 5 in both rows. Static initialization copies
`survival_seed_win_metrics` to scratch metric words; ranking initialization
refreshes ID words and copies three pairs into both rows.
Reset consumes at least 81 `rng_low31` draws plus rejected IDs, without
reseeding. Manager creation consumes them even if subsequent load overwrites
all seeds.

Finite-course mode 5 inserts ascending whole elapsed seconds; mode 4 inserts
descending completed wins and uses only win row 0. Insertion takes controller
row index verbatim; pair accessors do not check row/slot bounds.
Controller modes/courses/ranking/navigation and the win-row-1 producer search
remain owned by [Survival](../gameplay/modes/survival.md).

### Bitset `0x0DF4` and scalar `0x0DF8`

`SaveProfile.gate_bits` bit 0 in `menu_select_saved_gate` diverts selected
item 0 to `menu_enter_saved_gate`. Its semantics remain unnamed.
Only the reset clear is established as a writer in the inspected consumers.

`SaveProfile.scalar` resets to zero, but the inspected resident and battle
consumers establish no semantic meaning. ETC consumers reach an excluded
component. These bounds do not exclude indirect, inlined or pointer-arithmetic
use.

## Snapshot and change detection

`save_snapshot_capture` lazily allocates/copies the whole record; it does
not refresh an existing snapshot. `save_snapshot_release` frees it and
clears the pointer.

`save_snapshot_changed` returns 1 only with manager mode 4..7, an existing
snapshot and difference in record `0x0008..0x23FF`. It ignores
discriminator/checksum/play_time but includes seven gaps. Its sole recovered
caller `options_exit_update` exits directly when unchanged, or enters save
confirmation when changed.

During manager phase 4:

| Manager mode | Snapshot owner | Lifecycle |
| ---: | --- | --- |
| 4 | `manager_snapshot_state4` | Capture entry; release normal exit |
| 5 | `manager_snapshot_state5` | Capture entry; release normal exit |
| 6 | `manager_snapshot_state6` | Capture entry; release normal exit |
| 7, Options | `manager_options_lifecycle` | Create child, capture; destroy child, release |

Normal exit returns mode to 1. Only Options has the recovered comparator call.
Other owners' gameplay remains uninterpreted.

Reversed edits matching baseline bytes produce no difference; play-time alone
does not dirty, while any changed compared byte can prompt outside named
settings. Normal save does not refresh the baseline; next entry obtains one
only after release.

Options save-confirm state 2 creates shared Save/Load parent and invokes
`save_dialog_update`. Any nonzero result destroys it and advances exit
state 3. Initial No in `save_dialog_controller` flows through states
`0x0A`/`0x0C` to parent result 2. This branch, Options completion,
snapshot release and Controls/Audio/Display destruction do not restore baseline
bytes or old settings. **Static conclusion:** declining save keeps edited live
settings active and skips card write. A general rollback contract or persistent
dirty flag for other controllers is not established.

## Save/Load dialog text and confirmations

`SaveDialogController.ui` points to the UI. `save_ui_refresh_text`
stores `save_status_text_get` in `SaveDialogUi.text`, a text pointer
rather than animation state.

With `text_enabled` set, `save_ui_draw` invokes
`save_ui_draw_text_lines` for four consecutive NUL-terminated strings,
first local X/Y 22/18 then Y increments 30. It advances past terminators,
without splitting a long string.

`save_ui_yes_no` renders at local Y 80; `choice` is 0 Yes/1 No.
Returns are 1 Yes, 2 No, 3 back, 0 waiting, -1 not ready. It clears
`choice_enabled` to prevent later duplicate handling.
`save_ui_next(ui, 0)` draws Next and returns 1 on acknowledgement.

## Creation, repair, and negative results

### Card-error ownership and cached timestamp classification

Card-context file helpers retain `SaveCardContext.file_handle` and return
only 0/1. `card_file_error_hook` is empty; stage/result arguments do not
form a persistent error log. Indexed record/descriptor wrappers flatten
open/transfer/flush/close failure into 6 read/7 write; success is `-777`.
These results expose neither byte count nor failure stage.
`SaveWorker.preflight_result` stores separate directory/card classification.
Normal read failure is status `0x14`/class 2; write/directory/descriptor/icon
failure is `0x19`/class 2.

Lower submissions share one request gate and pending command:

| Submission | Pending command |
| --- | ---: |
| `card_rpc_open` | 2 |
| `card_rpc_close` | 3 |
| `card_rpc_read` | 5 |
| `card_rpc_write` | 6 |
| `card_rpc_get_info` | 1 |
| `card_rpc_flush` | 10 |

| Immediate result | Condition |
| ---: | --- |
| 0 | Submitted; pending command set |
| -100 | Initialized-state word zero |
| -200 | Request-semaphore poll negative |
| -91 | RPC submission nonzero; gate released |
| -210, open only | Null/empty path; gate released |

`card_rpc_wait` waits for completion, clears pending command, copies the
completed count/error when requested, and releases the request gate.
No pending command returns `-1` without writing the destination.
`card_file_wait` and inspected callers ignore that return; this does not
establish an ordinary submitted request can leave its result unwritten.

Read accepts every nonnegative completed byte count. Write does likewise, then
requires flush completion zero. Requested counts are never compared.
Indexed wrappers close only after successful transfer/flush. Successful close
sets the stored handle to `-1`; failure retains it. Later open can overwrite
the handle. Missing EE close alone does not prove a leak because the lower
service can invalidate ownership.

#### EE completion and teardown ownership

`rpc_submit` retains callback, argument and saved global pointer in
`SaveRpcClient`. `rpc_complete_dispatch` restores that pointer,
calls the callback, releases the packet and clears `SaveRpcClient.active_request`.
`rpc_packet_release` only clears `SaveRpcPacket.release_word` and
allocation bit 0. Neither interprets card results nor closes the payload handle.

`card_rpc_signal_completion` signals completion;
`card_rpc_read_completion` first copies two optional uncached-response edge
fragments then signals. Neither tracks handles or closes
files. Error completion releases the one-request gate just as success.

`card_rpc_teardown` waits, deletes the two semaphores and invalidates the
request-semaphore ID, without handle walk/close. No direct resident invocation
was found, without excluding indirect calls. Inspected EE completion/teardown
therefore does not supply file-descriptor reclamation.

#### IOP descriptor reclamation

Embedded `mcserv` binds RPC ID `0x80000400` and dispatches commands
2/3/5/6/10/13 to open/close/read/write/flush/directory handlers.
Its `mcman` import ordinals 6/7/8/9/14/12 identify corresponding manager
exports. These relationships establish operation identity.

The manager has three shared `0x30`-byte descriptor slots. Byte `+0` is
in-use, `+1/+2` write/read permission, and signed halfwords `+6/+8`
retain port/slot. Raw field offsets remain because no owning live program is
available for applying their type. Open selects the first inactive slot,
returns `-7` if all three are occupied, and marks successful ownership.

| Lower operation | Reclamation contract |
| --- | --- |
| Read | Invalid index/inactive/no-read/early card-gate exits precede local clearing; negative backend result clears; nonnegative short/full results do not |
| Write | Corresponding early validation/card-gate exits precede clearing; negative backend result clears; nonnegative does not |
| Flush | Initial card-gate exit does not locally clear; nonzero first cache flush or dirty-file update clears; negative final cache flush clears |
| Close | After index/activity validation, clears in-use before card gate and later flush/update; a later close failure still releases slot |

Read/write errors below `-9` also invalidate all descriptors and cache entries
matching that port/slot, rather than only the failed descriptor.
The common card gate can do the same after probe failure when a card type was
previously recorded, also clearing card-type state. Early exits therefore do
not guarantee continued occupancy.

Manager full-close visits each occupied slot and invokes close. Its
negative-argument module stop reaches full-close after unregister zero or
`-213`, as do two device-lifecycle paths. This establishes lower teardown
reclamation without establishing that ordinary NA2 save failure requests it.
Server read/write errors return normally without close; inspected
open/close/read/write/flush handlers contain no cancellation command.

The server's active flag is set during dispatch and cleared on the common
result path. Negative-argument stop returns 2 while active rather than cancelling.
Once idle, unregister zero/`-213` allows thread/RPC removal.
That server stop has no manager-close-import call; manager teardown supplies
the descriptor-reclamation evidence.

**Static conclusion:** backend-negative read/write and listed flush/close
paths can release ownership despite an EE context retaining its numeric handle.
Earlier errors, including EE submission failure after open, do not establish
reclamation. A permanent leak is not proved either: later card invalidation/
teardown can reclaim slots. Actual early-failure conditions remain open.

`shared:/MODULES.BIN` retains later embedded card members as unallocated
bytes rather than separately analyzed programs. Relocated execution addresses
are unestablished; their routines/types cannot be annotated at live addresses.
The findings retain module and import/export identity without link-relative
code citations.

#### Directory-query producer and cached-buffer lifetime

`card_rpc_get_directory` submits command `0x0D` through
`CardRpcDirectoryRequest` with port/slot/mode/limit/destination and
NUL-terminated pattern. It prepares `maximum_rows * 0x40` bytes for DMA,
without clearing/sorting. Submissions share one cache.

Preflight queries directory path mode 0/limit 8, changes directory, then queries
`*` mode 0/limit `0x18`. Repair does likewise but wildcard limit
`0x0C`. `card_query_path_suffix` combines directory/suffix; creation
and normal save use `/data??` mode 0/limit 4 for timestamps.
The smaller queries overwrite the first four rows without clearing the suffix.
Cache is shared query state; load/repair comparator paths perform their own full
refresh. No EE filename rearrangement occurs.

Embedded `mcserv` requests one `mcman` row at a time, first supplied
mode then mode 1, appends each `0x40` DMA row and returns accumulated count.
Neither sorts names/timestamps. PS2 manager mode 0 resets its shared cursor,
resolves parent and walks increasing directory-entry indices, incrementing
before filtering, skipping inactive attribute-bit-`0x8000` entries and
matching wildcard against entry filename at raw `+0x40`.
The entry reader selects directory-chain sectors and `0x200`-byte entries
from the index.

Non-root enumeration starts at zero; root at 2. Non-root `*` retains its
first two active entries and synthesizes `.`/`..`; ordinary names are
copied. Creation order is consistent with payload rows 3..6 and descriptor
row 7. Deleted/inactive/differently placed/extra matching entries change
compacted indices. This is storage order, without an arbitrary-card guarantee.

Only accepted rows are written. Short enumeration preserves an old suffix;
a later negative one-row manager request returns error without rolling back
already DMA-copied rows. Failed queries can therefore leave a new prefix and old
suffix. These buffer-lifetime findings do not establish any particular card's
contents.

`card_info_stable` repeats paired responses until type/free-space/format/
completed-result agree. Neither submission retry nor disagreement has an attempt
bound. It returns the cached completed result; a nonzero result clears the
worker's repair-history flag, rather than any changed-save flag.

`card_cached_timestamps_ordered` compares cached rows 3..6 with row 7:

```text
T = modified.seconds | modified.minutes << 8
  | modified.hours << 16 | modified.day << 24
return 0 if any of rows 3..6 has T greater than row 7
return 1 otherwise
```

Month/year/reserved byte/filename/size/valid-entry count are ignored.
**Inference:** intended detection is a payload newer than its descriptor.
The unchecked ordering and day-only calendar comparison cannot establish
chronology across months/years.

Checksum mismatch with comparator 0 gives status `0x2C`/class 3 and repair
confirmation; comparator 1 gives `0x2A`/class 1.
Repair comparator 0 forces reconstruction even with an existing nonzero
descriptor. No payload checksum is recomputed.

Post-repair reporting ignores repair's return: status `0x2E`/class 5 if
fresh preflight is 0, 5 or `0x0B`, or comparator is 0; otherwise
`0x2F`/class 5. Thus `0x2F` does not prove successful repair I/O or
descriptor/recomputed-checksum agreement.

### Allocation, creation, and repair limits

Preflight compares directory names with context path minus its leading slash.
Missing match gives 4 when free space meets expected allocation, else 3;
nonpositive query can follow the same branch except separately handled card
errors. Result 4 alone does not identify why no directory matched.
Load mode maps 3/4 to `0x29`/class 1/idle operation 1, before descriptor
or profile reads.

Allocation is `sum((file_size + 0x3FF) >> 10) + (entry_count - 1)/2 + 2`.
Expected `SaveCardContext.expected_blocks` is 103. Mismatch gives
`0x0B` with enough free space, else 3. Worker performs this before
operation dispatch and reloads operation/status/result afterwards; idle 1
prevents the switch. Initial mismatch in save as well as load can give
`0x2C`/class 3; confirmation schedules `0x0E`. Retained repair history
changes a later mismatch to `0x2A`/class 1.

`card_create_save_set` accepts directory-already-exists `-4`, rewrites
icon then four all-`0xFF` records in index order and metadata.
Operation `0x0C` additionally clears descriptors and writes metadata again.
Existing sets can be rewritten without deleting the directory. Replacement is
not atomic: a later failure leaves earlier files; there is no rollback.

All-`0xFF` is an erased sentinel rather than a valid profile: zeroing
checksum bytes gives sum `0xDA02`, while embedded physical value is
`0xFFFF` and empty descriptor checksum zero. Native emptiness uses
occupancy plus discriminator sentinel.

`card_repair_save_set` runs only for operation `0x0E`:

- Missing/zero-size primary with present nonzero backup: structurally validate
  descriptor table, copy row 3 and exact backup bytes, then rewrite metadata.
  Several primaries can become identical copies.
- Missing backup: no replacement.
- Existing checksum-corrupt or nonzero wrong-size primary: no substitution,
  even after confirmed checksum-mismatch recovery.
- Missing icons: recreate native sources.
- Missing/zero-size descriptor or comparator 0: rebuild from all four profiles.

Presence means nonzero file size, without expected-size checking. Backup
checksum/occupancy are not validated before copying; valid empty row 3 can
leave restored bytes logically empty. Copied timestamps remain the backup's
save date, without a post-write refresh; several restored primaries share
payload and descriptor timestamp.

Invalid descriptor validation on missing-primary repair leaves descriptor-data
source null, still writes backup bytes to primary, then forwards null with
length `0x40` to `card_write_descriptors`. This records the call contract
without predicting an unexercised crash/card result.

Reconstruction treats discriminator `0xFFFF` as empty with occupied/class/
checksum/play_time zero. Every other discriminator gives occupied 1, class 0
and stored checksum/time; each row receives that file's directory timestamp.
No checksum recomputation occurs. All four files must read successfully.

The two strategies do not compose: if primary and descriptor are both missing,
the earlier missing-primary branch fails reading descriptor before reconstruction
even with a backup. Missing backup fails the four-profile rebuild.
**Deduction:** an all-zero record reconstructs as occupied, passes structural
validation and normal checksum zero, and loads without discriminator/default
validation. This malformed case was not exercised.

Nonnegative short profile reads leave an uncleared heap suffix inside checksum
calculation, also during reconstruction/restoration. Scan pre-fills its table
destination `0xFF`, so short table read validates received bytes plus that
remainder. Nonnegative short writes report success too. These are static
contracts, without induced short-I/O observations.

No per-slot delete flow was recovered; occupied slots are overwritten.
`card_rpc_delete` packages path deletion without a recovered resident
caller. Worker `0x0B` uses full-card `card_format`/`card_rpc_format`;
`0x0C` recreates the whole set.

Normal load/save/snapshot, erased-record creation, missing-primary restoration
and aligned icon allocation are unchecked before I/O/copy. Most secondary banks,
aligned opaque regions and the tail retain unresolved meanings; copy shape
does not establish float or fixed semantic record interpretation.

## Historical-card corroboration

The inspected card contained a 64-byte descriptor file and four exact
`0x2400`-byte records. `data01` and `data04` were byte-for-byte identical.

The raw descriptor table was:

```text
01002b6189532e00002528101a07ea07
010052631d942d00001a21041107ea07
0100636229962d00002c21041107ea07
01002b6189532e00002628101a07ea07
```

All four records had header value 3, display offsets 0/0, volume `0x0100`,
audio mode 1, Ryo 9,999,999, and progression word `0x1C5C == 0x66`.
`data01`/`data04` had vibration mask 1, while `data02`/`data03` had mask 0.
Their controller arrays were:

| Records | Port 1 action array | Port 2 action array |
| --- | --- | --- |
| `data01`/`data04` | `0010 0020 0040 0080 0004 0008 0001 0002` | `0010 0020 0040 0080 0001 0002 0004 0008` |
| `data02`/`data03` | `0010 0020 0040 0080 0001 0002 0004 0008` | `0010 0020 0040 0080 0001 0002 0004 0008` |

The first sequence is the fixed native default. In the second, the four
shoulder assignments are permuted so Item Select uses L2, Linked Attack uses
R2, and Guard uses L1/R1. The `data01` pair exactly matches the independently
captured control-settings screen: default port 1 and shoulder-permuted port 2.
The additive checksum formula reproduced each embedded and descriptor checksum
exactly:

| Record | Checksum | Serialized play time | Descriptor play time | Difference |
| --- | ---: | ---: | ---: | ---: |
| `data01` | `0x612B` | 3,036,008 | 3,036,041 | +33 ticks |
| `data02` | `0x6352` | 2,987,003 | 2,987,037 | +34 ticks |
| `data03` | `0x6263` | 2,987,529 | 2,987,561 | +32 ticks |
| `data04` | `0x612B` | 3,036,008 | 3,036,041 | +33 ticks |

`data02` and `data03` differ only at record offsets `0x0002..0x0005`, covering
the checksum and the low two bytes of their play-time values. Descriptor rows
0 and 3 give the byte-identical `data01`/`data04` payloads distinct timestamps,
corroborating two separate file writes and timestamp queries.

The seven checksum-covered structured-copy gaps were:

| Offset | `data01`/`data04` | `data02` | `data03` |
| ---: | ---: | ---: | ---: |
| `0x0011` | `BF` | `00` | `00` |
| `0x0032` | `C7` | `7F` | `7F` |
| `0x0033` | `00` | `45` | `45` |
| `0x0966` | `8D` | `30` | `30` |
| `0x0967` | `42` | `BF` | `BF` |
| `0x21F6` | `00` | `00` | `00` |
| `0x21F7` | `00` | `00` | `00` |

The values demonstrate that those bytes are not reliably zero. In combination
with the proven copy omissions and non-clearing temporary allocation, their
variation strongly supports the stale-allocation inference; one historical
image alone would not establish provenance.

All four records shared identical Survival-table and late opaque-region bytes.
The table values corroborate both insertion directions and seed metrics. For
example, first-block row 9 contains metrics `128, 180, 225`, consistent with
inserting 128 ahead of the factor-3 seeds `180, 225, 270`; row 12 contains
`108, 240, 300` against factor-4 seeds `240, 300, 360`. Second-block row 1
retains `10, 8, 5`, while row 0 has `10, 10, 8`, consistent with a score of 10
being inserted ahead of the seed tie. These are consistency observations, not
proof of the individual play events that produced the historical file.

`0x21F8..0x2213` contained 8 nonzero bytes and `0x2214..0x2393` contained 151,
confirming that the aligned opaque ranges are runtime-populated rather than
padding, without establishing their meanings. The final `0x6C`-byte tail was
all zero in all four records; one card is insufficient to conclude that the
tail is unused. Words `0x0DF4` and `0x0DF8` were zero in every record.

## Resident save ownership

The resident ELF owns worker pointer `save_worker`, direct profile pointer
`live_profile`, manager pointer `battle_manager`, vibration cache byte
`vibration_mask_cache`, and snapshot pointer `save_snapshot`.
`resident_flow_dispatch` allocates worker and profile separately;
`manager_initialize` adopts the direct profile as `BattleManager.profile`.
Manager and worker therefore share one live `0x2400` allocation.

The same ELF owns repair-history word `save_repair_history`, directory-row
cache `card_directory_cache`, initialized-state word `card_rpc_initialized_state`,
completed card result `card_rpc_completed_result`, request file-handle word
`card_rpc_request_handle`, directory-request packet `card_rpc_directory_request`,
and controller-map banks `resident_bindings_port0`/`resident_bindings_port1`.
`card_rpc_directory_request` uses the existing partial `CardRpcDirectoryRequest`
view; its pattern field does not describe the full submitted packet extent.
