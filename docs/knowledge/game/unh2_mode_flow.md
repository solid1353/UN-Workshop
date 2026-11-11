# UNH2 front-end and VS CPU flow

## Research coverage

Established statically and observed at runtime: the MOTHER task's states,
the logos' and title's sub-states and New Game's manager setup, the scene and
mode dispatch, Mode Select's results and entries, the VS CPU controller's
sub-states, where the manager keeps the stage scene, fighters and COM levels,
where Battle Time lives, and that a fighter with COM level 0 runs no AI and
reads no pad. UNH2 has no Practice mode; VS CPU is its one-on-one fight.
Open: Mode Select's own sub-states, the Character Select object's layout and
how it writes its selection to the manager.

Routines and globals are named by `@annotations/UNH2`; addresses are live
`BOOT.BIN` addresses, as in [UNH2 battle stages](../gameplay/stages/unh2_stages.md#evidence-and-address-convention).
UN2's flow, whose manager UNH2's resembles, is in [UN2 mode flow](un2_mode_flow.md).

## Main loop

`game_main` builds the heap and starts the MOTHER task (`mother_task`), which
runs one state word (`mother_state`): `1` the logos (`mother_logos_update`),
`2` the title (`mother_title_update`), `5` the game (`game_scene_update`).
Boot enters `1`. The logos run until `logos_running` returns 0, then enter `2`.
The title's result `0` (New Game) or `1` (Load Game) enters `5`; `2`, its
timeout, returns to `1`. Returning to the title from Mode Select enters `2`.

The logos' sub-states (`logos_construct`) load system data from the memory
stick once (`logos_system_data_load`), then show the logos, which Start
skips. The title's (`title_construct`) build and show the title, then run
its menu (`title_menu_update`): New Game or Load Game, whose cursor starts
on Load Game, or a return to the logos after 1800 updates. Its New Game
(`title_confirm_update`) builds `battle_manager` (`battle_manager_construct`),
calls `battle_manager_begin`, `profile_new_game_defaults(profile, 1)` and
`0x08A090A8`, and returns 0 without loading a save.

## Scenes and Mode Select

`game_scene_update` dispatches the manager's scene word `+0x34`: scene `1` is
`mode_select_scene_update`, scene `2` dispatches the mode word `+0x38`, and
scene `5` returns to the title. Mode Select lists The Mugenjo, Heroes Mode,
VS CPU, Wireless Mode, Ninja Road, Naruto's House and Options. Its result
`3`, VS CPU, sets scene `2`, mode `5` (`vs_cpu_mode_update`) and nothing else;
results `0`..`5` set modes `2`..`7`, `6` scene `3`, `7` scene `4`, and -1 scene
`5`.

## VS CPU

`vs_cpu_mode_update` builds `vs_cpu_mode` and runs its sub-state `+4`:

| Sub-state | Work |
| ---: | --- |
| 1 | `vs_cpu_character_select_update`: Character Select, then Stage Select. Its own state `+8` starts at 0, which builds the menu. Confirm keeps the selection at `vs_cpu_mode` `+0xC..+0x30` and enters 2; back enters 4. |
| 2 | `vs_cpu_fighter_setup`: the side flags, both sides' jutsu choices (`+0x44..+0x47`) and fighter files, then 3. |
| 3 | `vs_cpu_battle_update`: builds and runs the battle; the pause menu's Return to Character Select enters 1. |
| 4 | Exits to Mode Select (scene 1). |

The battle builds both fighters (`battle_build_fighters`) from the manager's
characters `+0x3E` and `+0x3F`, New Game's 1 (Naruto) and 2 (Sasuke), and COM
levels `+0x42` and `+0x43`, New Game's 0 and 1. Its stage is the scene byte
`+0x3D` ([UNH2 battle stages](../gameplay/stages/unh2_stages.md#scene-table-and-records)).
`battle_create_fighter` puts the COM level in bits 5..8 of fighter `+0x50`.
Each character's AI method runs `com_think` only while those bits are
nonzero; a fighter with COM level 0 on the second side reads no pad, so it
stands still and faces its opponent.

Battle Time is the profile's (`battle_manager_profile`) halfword `+0x44`
(`battle_time_setting`), 99 by default; 100 is unlimited, which the Battle
Settings menu shows as ∞.
