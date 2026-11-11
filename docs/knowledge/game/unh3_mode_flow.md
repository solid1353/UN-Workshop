# UNH3 front-end and Practice flow

## Research coverage

Established statically and observed at runtime: the MOTHER thread's states,
the manager's phases and New Game's preparation and prompts, Mode Select's
results, the battle-mode controller's states through the battle, how
Character Select commits its fighters, stage and player count to the
manager, where Command Display and a COM's Practice settings live, and
Practice's default COM. Its outer states, manager phases and mode callbacks
follow NA2's ([Mode flow](mode_flow.md)).
Open: the opening's own states, Continue's preparation, the controller's
states 7, 9 and after the battle, and the other battle settings bits.

Routines and globals are named by `@annotations/UNH3`; addresses are live
`EBOOT.BIN` addresses, as in [UNH3 battle stages](../gameplay/stages/unh3_stages.md#evidence-and-address-convention).

## Main loop

The MOTHER thread (`mother_task`) waits for its startup services, stores
state 2 in `mother_state` once (`li v1,2` at `0x088C8420`) and then runs that
state each update: `2` the opening (`opening_update`, which returns only
when the logos end), `3` the title (`title_update`), `4` the manager
(`manager_update`). The title's -1 returns to the opening; its 1 (New Game)
or 2 (Continue) is kept as the title result beside the state and enters 4.
The manager returning 1 enters the title again.

## Manager phases

`manager_update` builds `battle_manager` (0x34C bytes) and runs its phase
`+8`:

| Phase | Work |
| ---: | --- |
| 1 | Title result 1 enters 2, 2 enters 3; any other enters 4 with mode 1 (`0x08975658`, `0x08975674`). |
| 2 | `new_game_prepare`: `new_game_prompts` (`player_name_entry`, the on-screen keyboard, then `install_prompt` once a name is entered), then `menu_files_load` and its wait; enters 4 with mode 1. |
| 3 | `continue_prepare`: Load Game; enters 4 with mode 1, or returns to the title. |
| 4 | Mode `+4`: `1` `mode_select_update`, `4` `practice_mode_update`, others the remaining modes. |
| 5 | Returns to the title. |

Mode Select draws from the files `menu_files_load` queues (`mdsel.ccs`
among them); without them it shows only its frame. Its result `4` is
Practice and `5` Master Road; results 2..7 become the mode.

## Practice

`practice_mode_update` builds the battle-mode controller
(`battle_mode_begin`, kind 2 at `battle_mode_kind`) and runs its state:

| State | Work |
| ---: | --- |
| 4 | `battle_mode_load_character_select`: queues and binds Character Select's files. |
| 5 | `battle_mode_character_select`: Character Select, then Customize (team, ninjutsu, handicap and Practice Settings), Map Select and the versus screen. Its sub-state `+4` starts at 0, which builds the menu. Confirm enters 6. |
| 6 | `battle_mode_commit_selection`: `battle_manager_finalize_slots`, then 7. |
| 8 | `battle_mode_create_battle`: Practice's settings object at `0x08CE061C`, then 10. |
| 10 | `battle_mode_battle_update`: the battle. |

Character Select chooses two to four players. On confirm,
`character_select_commit` writes each chosen slot of the manager's four
0x20-byte slots from `+0x10`: bit 1 of the flags byte for a COM, the
character `+0x14`, team `+0x1C`, side `+0x24`, the ninjutsu through
`battle_manager_set_ninjutsu`, whose -1 takes the character's default, and
the handicap. It clears the other slots' characters and writes the stage
scene `+0x90` and the player count `+0x98`
(`battle_manager_set_player_count`). State 6 copies them into the battle's
copy from `+0x9C`. Characters use NA2's IDs, such as Naruto 57 and Sasuke
93.

`battle_manager_set_battle_setting` keeps the battle settings from `+0x128`:
bit 0 of `+0x128` is Practice's Command Display (on by default), `+0x12E`
onward each slot's handicap, and five bytes per slot from `+0x132` a COM's
Practice settings. A Practice COM defaults to State Stand, Attack No, Guard
No and Action Don't Chase, so it stands still.
