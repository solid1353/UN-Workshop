# Survival controller, courses, and rankings

## Research coverage

Established: controller modes, all 25 courses, ranking insertion/display,
Records bounds, row preservation, course admission and the Ultimate unlock.
Open: win-row-1 meaning/producers, other difficulty-word writers, indirect or
inlined row writers, and event-5 spoken words. Evidence is static resident/BTL/ETC
inspection; English course names are translations of retail Japanese strings.
Names and field layouts come from `@annotations/NA2`; addresses are live.

Retail NA2 (`SLPS-25837`) identifies this controller as `サバイバル戦闘`
(Survival Battle), stored in `survival_battle_controller_name`
(`0x00404AF0`). The finite result's internal class name is
`ccTimAtkResult`; that name does not change the player-facing identification.

Save layouts, fresh ranking seeds and counter writes belong to
[Save-data record format and lifecycle](../../game/save_data.md#fresh-profile-initialization)
and [Battle-result counters](../../game/save_data.md#battle-result-counters-in-the-byte-bank-at-0x2100).
Difficulty-word consumers belong to
[Content availability](../../game/content_availability.md#progress-gates) and
[Practice mode](practice_mode.md#row-availability). Shared outcome and
battle-number transitions belong to
[Match outcomes](../session/match_outcomes.md#higher-level-sequence-counter-and-result-8-continuation);
audio playback belongs to [Battle audio](../session/battle_audio.md).

## Evidence and address conventions

Inputs and live addresses follow
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
Per-routine gates, signatures, call evidence and data layouts are retained in
the annotations. Indexed cross-references are incomplete; neither their
absence nor bounded direct-call searches exclude indirect or inlined access.

The resident BSS globals `battle_route_code` and `battle_countdown_elapsed`
are named and typed in `@annotations/NA2/SLPS_258.37`.

## Controller modes and ranking insertion

`setup_apply_mode` admits selection-node kinds 0 and 1 to
`survival_setup_encounter`; kind 2 takes a different constructor.
`SurvivalSelectionNode.kind` determines the Survival path:

| Node kind | Controller mode | Opponents | Saved ranking row |
| ---: | ---: | --- | --- |
| 0 | 5 | Selected course's fixed three-byte entries | Selected course ID, 0..24 |
| 1 | 4 | Randomized list | Win row 0 |

`encounter_flow_construct` clears the controller through
`encounter_flow_clear`, then `rng_shuffle_allocate` assigns its mode and
opponent-list ownership. `encounter_set_ranking_course` supplies
`EncounterFlow.ranking_row` and `definition`: mode 5 receives the course
table entry; mode 4 receives row zero and a null definition.

`survival_result_initialize` publishes two separate ranking meanings:

| Mode | Insertion routine | Metric and order | Admission/result |
| ---: | --- | --- | --- |
| 5 | `survival_insert_time_ranking` (`0x001F24B0`) | Cumulative whole elapsed seconds, ascending; ties insert ahead | `battle_route_code` must equal 1; otherwise -2 without table writes |
| 4 | `survival_insert_win_ranking` (`0x001F2630`) | `EncounterFlow.ordinal - 1` completed wins, descending; ties insert ahead | Requires mode 4 |

Both routines use `ranking_row` verbatim and insert the current character.
They compare full signed 32-bit metrics and return a slot 0..2 or -1 when
the metric misses the top three; a missing manager or wrong mode also returns
-1. The time path's -2 specifically excludes an ineligible battle route.

`battle_countdown_advance` maintains the Q8.24 value
`battle_countdown_elapsed`, with active delta `0x00044444` (approximately 1/60 second)
and integer cap 99. After a win, `manager_request_alternate_reentry` adds
`max(0, elapsed >> 24)` to `EncounterFlow.elapsed`.
`battle_evaluate_terminal_conditions` compares the same integer seconds
with 31 and 61, establishing the at-most-30/at-most-60-second conditions.
The ordinal starts at 1 and advances after wins, establishing the completed-win
meaning of the other metric.

## Course table

`survival_save_courses` (`0x00896370`) contains exactly 25
`SurvivalSaveCourse` records. Each `row` equals its course ID, `group`
defines its selector group, `battle_count` gives its length, and
`native_name` points to its retail Japanese string. Ruby markup is omitted
below; English names are translations.

The counter column gives the hexadecimal byte-bank ID and signed increment
from `counter_id` and `counter_increment`, used by result kinds 0/4 in the
[battle-result counter processor](../../game/save_data.md#battle-result-counters-in-the-byte-bank-at-0x2100).
Repeated IDs are intentional table values; these are not independent flags
for each course.

| Save row | Native course name | English meaning | Battles | Counter increment |
| ---: | --- | --- | ---: | --- |
| 0 | 忍者学校 | Ninja Academy | 2 | `0x0B` += 3 |
| 1 | 下忍ランクＡ | Genin Rank A | 3 | `0x01` += 3 |
| 2 | 下忍ランクＢ | Genin Rank B | 3 | `0x00` += 3 |
| 3 | 下忍ランクＣ | Genin Rank C | 3 | `0x04` += 2 |
| 4 | 下忍ランクＤ | Genin Rank D | 3 | `0x08` += 3 |
| 5 | 砂の三姉弟 | Three Sand Siblings | 3 | `0x07` += 3 |
| 6 | 霧の刺客 | Mist Assassins | 2 | `0x0D` += 3 |
| 7 | 新紅班 | New Kurenai Team | 3 | `0x05` += 3 |
| 8 | 新アスマ班 | New Asuma Team | 3 | `0x0F` += 3 |
| 9 | 新ガイ班 | New Guy Team | 3 | `0x09` += 3 |
| 10 | 新カカシ班 | New Kakashi Team | 3 | `0x13` += 3 |
| 11 | 上忍ランクＡ | Jonin Rank A | 3 | `0x02` += 3 |
| 12 | 上忍ランクＢ | Jonin Rank B | 4 | `0x00` += 3 |
| 13 | 砂の強者 | Sand's Strong Fighters | 5 | `0x0A` += 3 |
| 14 | 音の五人衆 | Sound Five | 5 | `0x0C` += 3 |
| 15 | 邪なる者 | Evil Ones | 3 | `0x06` += 2 |
| 16 | 伝説の三忍 | Legendary Sannin | 3 | `0x11` += 3 |
| 17 | “暁” | Akatsuki | 5 | `0x10` += 3 |
| 18 | 火影たち | Hokage | 5 | `0x0E` += 3 |
| 19 | 特別対戦 | Special Match | 5 | `0x14` += 3 |
| 20 | 金髪五人衆 | Five Blond Fighters | 5 | `0x12` += 5 |
| 21 | 傀儡軍団 | Puppet Army | 5 | `0x04` += 3 |
| 22 | 木ノ葉先生 | Leaf Teachers | 5 | `0x13` += 5 |
| 23 | 血継限界 | Kekkei Genkai | 5 | `0x06` += 3 |
| 24 | 高みの者たち | Those at the Top | 5 | `0x15` += 3 |

The course groups are:

| Group | Course IDs |
| ---: | --- |
| 0 | 0..5 |
| 1 | 6..10 |
| 2 | 11..15 |
| 3 | 16..19 |
| 4 | 20..24 |

The battle counts equal all 25 `survival_seed_row_factors`
(`0x005C0710`), connecting each fresh seed time to its course length
([Fresh-profile initialization](../../game/save_data.md#fresh-profile-initialization)).

## Ranking display and Records navigation

`survival_time_ranking_draw` reads slots 0..2 through
`profile_survival_time_get`; `ranking_highlight_draw_b` independently
reads slots 0..2 through `profile_survival_wins_get`. Both use their
`SurvivalRankingView.ranking_row`, establishing separate saved time and win
lists.

The saved `SurvivalRankingEntry.character_id` and `metric` are signed
32-bit words, but `ranking_highlight_draw_a` (wins) and
`ranking_highlight_draw_c` (time) display their signed low halfwords.
The display therefore neither validates nor represents the full stored range.

Win row 0 is the native `壮絶サバイバル` list, named by
`survival_win_ranking_name` (`0x00897860`) and submitted through
`survival_ranking_header_draw`.

`survival_records_construct` creates separate win and time children with
both rows initially zero. `survival_records_input` gives
`survival_ranking_select_row` a maximum of zero for wins and `0x18` for
time. Its wraparound therefore exposes all 25 time rows and only win row 0.

## Win-row producer and ordinary-controller lifetime

`encounter_flow_clear` initializes the row to zero.
`rng_shuffle_allocate` leaves it unchanged; the creation path explicitly
sets zero for mode 4 and the selected course for mode 5.
`manager_request_alternate_reentry` preserves that row through ordinary
wins, continuation and result entry while changing the ordinal, cumulative
time and completion state.

`survival_result_initialize` forwards the same row to ranking insertion and
the result setter. `survival_win_result_set` copies it into
`SurvivalWinResult.ranking_row` and then its ranking child's row. This
separate presentation object does not write back into the encounter or the
saved row selector.

**Bounded conclusion:** the inspected construction, continuation, result and
Records paths supply no native row-1 producer or selector. The independently
seeded, checksum-covered second win row does not by itself establish a
reachable ranking or second playable Survival submode. An uninspected indirect
or inlined producer remains possible.

## Finite-course result admission

`survival_result_initialize` creates the finite owner only for mode 5:
it obtains the time-ranking result, asks `survival_result_wrapper_construct`
for the finite child, and forwards the selected course and ranking result
through `survival_course_result_set`. Mode 4 takes the win owner.

The finite child is a `0x68`-byte controller identified through
`survival_course_result_descriptor` (`0x005DDC30`) and
`survival_course_result_class_name` (`0x008980D0`, `ccTimAtkResult`).
Its descriptor owns reward presentation, ranking-counter selection, reward
calculation and state entry through `survival_course_reward_draw`,
`survival_course_counter_index`, `survival_course_reward_compute` and
`survival_course_result_enter_state`.

`result_update_saved_counter_b` dispatches the child's seven states through
`survival_course_update_dispatch` (`0x008C2E90`).
State 0 reaches `survival_course_confirm`, which first requires
`BtlSaveResultController.presentation` ready and then accepts edge-input
`0x20` (Circle) from the manager's selected port. Only accepted input invokes
`survival_course_admit_completion`.

The wrapper retains the child until `encounter_conditions_result_update`
finishes and `survival_result_wrapper_release` destroys it. The enclosing
post-battle lifetime and result codes are owned by
[Match outcomes](../session/match_outcomes.md#higher-level-sequence-counter-and-result-8-continuation).

## Difficulty-word producer

**Observation, high confidence:** `survival_course_admit_completion`
(`0x006EC6F0`) declines completion when any of these holds:

- `BtlSaveResultController.ranking_result == -2`;
- saved word `0x6A == 1`;
- saved word `0x6C` already contains the selected course's completion bit.

A result of -1 is admitted, so obtaining a top-three time is not required.
This is a battle-route gate, independent of the saved difficulty option.
The caller tests exactly 1; difficulty menus accept any nonzero saved value.

Otherwise `survival_finish_course` (`0x006EC5B0`) sets
`1 << (course_index & 0x1F)` in word `0x6C` and selects a result state:

| Course condition | Saved change beyond completion bit | Sound event | Returned state |
| --- | --- | ---: | ---: |
| Index below `0x18`, next course in same group | None | 3 | 4 |
| Index below `0x18`, next course in different group | Enable the **next** group's bit in word `0x6B` | 4 | 5 |
| Index at least `0x18` | Write word `0x6A = 1` through `profile_word1_set` | 5 | 6 |

The admission routine stores a nonzero returned state and invokes the
descriptor's state-entry callback. Group boundaries are courses 5, 10, 15 and
19; the enabled bit belongs to the next record's group.

**Inference, high confidence:** within the native 25-course domain, index 24
is the only index satisfying `index >= 0x18`. Its row is
`高みの者たち` (Those at the Top), group 4, five battles.
Acknowledging its eligible result therefore writes word `0x6A`, provided
that word is not already exactly 1 and the course bit is still clear.

Earlier admission has two separate gates. `survival_enable_first_group`
ORs bit 0 into word `0x6B`, preserving later group bits.
`survival_group_confirm` accepts only a selected group whose bit is set.
Within that group, `survival_course_select_confirm` admits course 0
directly; every other course `i` requires bit `i - 1` in word `0x6C`.
Group admission and per-course completion are distinct.

**Inference, high confidence:** starting from freshly cleared word banks,
ordinary confirmation and accepted result acknowledgement advance through
courses 0..24 in order. The final writer checks its current index and local
result gates; it does not verify all earlier course bits together.
Other producers of word `0x6A` remain open.

## Final-result text and event 5

The state-6 branch of `btl_menu_modal_draw_b` submits all seven
`survival_final_message_lines` (`0x00897D20`), including two blank
separators. With only ruby/color markup removed, its mode label is
`「究極連激戦」全クリア報酬！`; the title's ruby is
`ナルティメットれんげきせん`.
Its difficulty announcement is
`最も手強い難易度の「究極」が追加されました！`, preceded by
`「フリーバトル」などの「難易度設定」`.
The retail display explicitly announces the Ultimate difficulty tier for Free
Battle and other difficulty settings.

Event 5 is an audio request; no dialog-ID meaning is established.
`survival_result_sound_event` dispatches it through
`survival_result_sound_dispatch` (`0x008C2E40`) to sound index `0x25`.
`survival_voice_request` calls
`audio_request_rpg_voice(0x4E, 0x25, 0)`: category 2, descriptor
`survival_voice_archive_descriptor` (`0x003FDFC0`), bank `0x62`,
variant 1, count `0x47`. Its spoken words remain unestablished; the displayed
unlock wording is independent evidence.
