# UN2 front-end and Practice flow

## Research coverage

Established statically: the main-loop dispatch, New Game's manager setup and
`Home.bin` branch, the scene and mode dispatch, Mode Select's results, the
Practice controller's states through Stage Select, the manager's default
fighters and stage, and where Practice Behavior, Command Display and the COM
flags live. Open: main-loop states 3, 5 and 7, the title, modes 4, 5
and 7 and scenes 2..4 beyond their dispatch, what `0x00263150` checks,
the Practice Settings menu's row labels, and the Practice states after Stage
Select. No runtime observation backs this document.

Routines and globals are named by `@annotations/UN2`; addresses are live
resident `SLUS_215.75` addresses (US `SLUS-21575`; see
[Retail game file identities](files/file_identities.md#address-conventions)).
UN3's flow, which UN2's resembles, is in [UN3 mode flow](un3_mode_flow.md).

## Main loop

`game_main_task` runs the state object at `gp-0x68C0`: `2` the logos
(`0x0017E4F0`), `3` `0x0017E8A0`, `4` the title menu (`0x0017E9D0`), which
also builds the fade object at `gp-0x68EC`, `5` `0x0017F8C0`, `6` New Game,
`7` `0x00241480` and `8` the game. Boot and soft reset enter `2`
(`0x0017D9A4`). A successful `6` or `7` sets the fade object's countdown and
enters `8`.

`new_game_start` builds `battle_manager` (`gp-0x681C`, 0x2F4 bytes) and loads
`Battle.bin`. Outside state 5 it then calls `0x00263150`; a result of
-1 runs a `Home.bin` sequence that also sets the profile's money to 50000,
any other result only fades. `battle_manager_defaults` sets stage scene
index `+0x41` to 0, Player 1 and Player 2 to characters 1 and 2 (`+0x42`,
`+0x43`) and both COM flags (`+0x46`, `+0x47`) to 0; the constructor clears
the active side `+0x26C`.

## Scenes and Mode Select

`game_scene_update` dispatches the manager's scene word `+0x38`. Scene `0` is
`mode_select_scene_update`; scene `1` dispatches the mode word `+0x3C`, where
mode `1` is Practice (`practice_mode_update`), `4` a fighter-versus-fighter
battle (`0x00244590`) and `6` Ultimate Contest (`0x00242CC0`, `RPG.bin`).
Mode Select's state 4 runs its menu (`0x00296110`, result `0x00296390`),
whose confirm (`mode_select_menu_confirm`) queues the chosen mode's files
through `mode_queue_files`: for Practice `prac.ccs`, `rpg/pirk.ccs` and the
battle menus' files. State 6 maps result `1` to scene 1, mode 1, `4` to mode 4 with its control
mode, `6` to mode 6, `2` and `3` to scenes 2 and 3, `7` to scene 4, mode 7,
and -1 to scene 5, the title.

## Practice controller

`practice_mode_update` runs its states from the table at `0x004B8A70`.

| State | Work |
| ---: | --- |
| 0 | Control mode `+0x40` `1` with Player 2's COM flag set, or `2` with Player 1's when the active side `+0x26C` is set. |
| 1 | Waits for the queued files and binds `charsel1.ccs`, `mapsel1.ccs`, `mcmn.ccs`, `prac.ccs`, `pirk.ccs` and `itya.ccs`; a file that was not loaded stops the game at a break in `0x00158890`. |
| 2 | Character Select (object `0x0031FC50` at `+0x25C`, run by `0x00322350`). Result 1 finalizes both sides' loadouts (`0x0023CE60`) and enters state 3; -1 enters state 13, which reloads Mode Select's files. |
| 4 | Stage Select, the `BATTLE.BIN` object at `gp-0x67D4`. On success it stores the chosen scene index in `+0x41` and waits three updates before state 6. |

Stage Select lists scene indices `0..15` (US); see
[UN2 stages](../gameplay/stages/un2_stages.md#stage-select-presentation).

## Behavior, Command Display and COM flags

In mode 1, `practice_behavior_set` stores Practice Behavior in profile byte
`+0x58` (default 1); MANUAL is 0. The Practice Settings commit (caller of
`practice_toggle_com` at `0x0032B588`) clears the COM flag of the side
opposite `+0x26C` (`+0x47` for Player 2) when Behavior is 0 and sets it
otherwise, also updating a live fighter's behavior bits.
Command Display is bit 2 of profile byte `+0x5D` (`practice_command_display_set`,
default on), which only Practice reads: `BATTLE.BIN` `0x006AB970` shows and
fades the command rows only while it is set. Bit 1 of the same byte, which
modes 1 and 4 read through `battle_setting_flag1_get`, is a different setting:
fighter setup (`0x00188F60`) sets fighter `+0x140` while it is clear, and a
`BATTLE.BIN` COM routine acts only while it is set. Fighters take their COM
flags from the manager when they are built, so a flag cleared before loading
makes the dummy a player fighter.
