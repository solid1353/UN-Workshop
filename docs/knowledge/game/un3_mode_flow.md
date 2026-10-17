# UN3 front-end and Practice flow

## Research coverage

Established statically: the main-loop states, New Game's manager setup, the
scene and mode dispatch, Mode Select's results, the Practice controller's
states, how Character and Stage Select hand their results to the manager,
where each side's Ultimate Jutsu is kept, and where Practice Behavior, Command
Display, Easy Display and the COM flags live.
Open: which choice the Easy Display dialog labels on, modes 1, 5 and 6 and
scenes 2..4, Load Game beyond its manager setup, the HOME.BIN New Game
sequence, and what Mode Select stores in the active-side word. No runtime
observation backs this document.

Routines and globals are named by `@annotations/UN3`; addresses are live
resident `SLUS_217.27` addresses (see
[Retail game file identities](files/file_identities.md#address-conventions)).
The NA2 counterparts are in [Mode flow](mode_flow.md) and
[Practice mode](../gameplay/modes/practice_mode.md).

## Main loop

`game_main_task` runs one state word: `2` logos, `3` title, `4` attract demo,
`5` New Game, `6` Load Game, `7` game. Boot and soft reset enter `2`. The
title's New Game result leads to `5`, Load Game to `6`; both reach `7` on
success.

`new_game_start` builds `battle_manager` with a default profile and loads
`Battle.bin`, the overlay holding Stage Select and the in-battle Practice
objects. Outside the attract demo it then runs
`memory_card_check_directories`; a nonzero result runs a HOME.BIN sequence
that also sets the profile's money to 50000. A zero result only fades.

## Scenes and Mode Select

`game_scene_update` dispatches the manager's scene word `+0x54`. Scene `0` is
`mode_select_scene_update`; scene `1` dispatches the mode word `+0x58`, where
mode `7` is Practice (`practice_mode_update`), mode `2` is the
character-and-stage battle in `battle_stage_transition_update`, and mode `0xB`
is the attract battle. Mode Select's result `7` sets scene `1`, mode `7`; it
does no Practice setup of its own.

## Practice controller

| State | Work |
| ---: | --- |
| 0 | Stage `0`, Player 1 ID `1` (Naruto), Player 2 ID `2` (Sasuke), their default loadouts, and control mode `1` (Player 2 COM), or `2` when the active side `+0xA38` is nonzero. |
| 3 | Character Select. Results `1/3/5/7` confirm; `result >> 1` marks the sides that customize. Each side then goes through `battle_side_finalize_loadout`. |
| 4 | Customization, only for marked sides. |
| 5 | Stage Select (`0x0082FCD0`); its result is the scene index in `+0x61`. |
| 6 | `battle_request_match_resources` queues both fighters and the stage from the manager fields. |
| 9, 10 | Build and run the battle owner. |

Stage Select lists scene indices `0..19` (archives `S01..S20`); see
[UN3 stages](../gameplay/stages/un3_stages.md#stage-select-presentation).

`battle_side_finalize_loadout` leaves each side's Ultimate Jutsu as a record
of `ultimate_jutsu_record_get`'s table in the side's active halfword (`+0x70`
for Player 1, `+0x72` for Player 2) and its pending choice (`+0x8A` + side ×
2). State 6 passes the active record through `ultimate_matchup_variant`, which
changes only character `0x2E` against `9`, and the fighter takes it from there.
Naruto (ID 1) lists records 1..21; record 1 is Naruto Uzumaki Barrage and his
normal default is record 9, The Nine-Tailed Rasengan.

## Behavior, Command Display, Easy Display and COM flags

Practice Settings' BEHAVIOR row offers MANUAL `0`, COM `1`, STAND `2` and
JUMP `3`. In mode `7`, `practice_behavior_set` stores it in profile byte
`+0x5A`. Its COMMAND DISPLAY row, OFF `0` or ON `1`, is bit 1 of profile byte
`+0x5F` (`practice_command_display_set`); Practice's command display reads
it every frame. The pause menu's Easy Display Setup, in every battle mode,
sets or clears bit 6 of the same byte (`easy_display_update`), and the
battle shows Easy Display cues only while it is set (`easy_display_show`).
On commit, `practice_toggle_com` writes the COM flag of the side opposite
`+0xA38` (`+0x67` for Player 2), set unless Behavior is MANUAL, and updates a
live dummy's behavior bits.

Fighters take their COM flag from the manager when
`battle_fill_fighter_spawn_descriptor` builds them, so a flag cleared before
loading makes the dummy a player fighter. With Behavior MANUAL in mode `7`,
the in-battle menu setups at `0x002FAAB0` and `0x002F41A0` also treat both
sides as players.
