# UN4 front-end and Practice flow

## Research coverage

Established statically: resident startup, New Game's directory-check branch,
Mode Select's Practice result, Practice's selection and loading states,
participant fields, raw stage ownership, and manual-opponent settings.
Open: runtime confirmation, other settings' complete player-facing meanings,
and unrelated mode branches. No runtime observation backs this document.

Names come from `@annotations/UN4`. Addresses are live resident
`SLUS_218.62` addresses unless a battle-overlay routine is named. Binary
identity and address conventions belong to
[Retail file identities](files/file_identities.md#address-conventions).

## Startup and Practice entry

`game_main_task` (`0x001C94D0`) initializes MOTHER and enters outer state 2
at `0x001C97CC..0x001C97D0`. States 2 and 3 run logos and title; state 5
runs `new_game_start`, state 6 Load Game, and state 7 `game_scene_update`.
New Game allocates the `0xCF0` manager at `0x00609794`, initializes its
profile and battle resources, then calls `memory_card_check_directories`
at `0x00317AB0`. A zero result selects the plain fade path. Success returns
1 and MOTHER advances to outer state 7.

`game_scene_update` (`0x00317870`) dispatches manager scene `+0x50`.
Scene 0 runs `mode_select_scene_update` (`0x00318220`). Its state 3 creates
the menu owner, calls its updater at `0x00318454`, and on success 1 reads
the choice at `0x0031848C` before preloading that mode. Choice 2 leads to
scene 1, mode `+0x54 = 2`, which dispatches `practice_mode_update`.
Practice's graph variant is 1; its handlers are shared with Free Battle.

## Selection and battle loading

| Practice state | Work |
| ---: | --- |
| 1 | Reset participants, loadouts and control flags. |
| 2..4 | Queue and acquire preparation resources, including `prac.ccs`. |
| 5 | Call `battle_manager_select_characters` at `0x0031C3F4`; result 1 advances to state 7. |
| 7 | Call `battle_manager_select_stage` at `0x0031C474`; result 1 seeds a three-update delay and advances to state 8. |
| 8 | Finalize both native loadouts, release preparation assets, queue fighters and the raw stage, then enter state 9. |
| 9 onward | Wait for loading and construct/run the battle through the remaining native states. |

`battle_manager_select_stage` (`0x00322DD0..0x00322EF4`) has one direct
caller, state 7. It creates a `0x140` selector/settings owner at manager
`+0x11C`, initially selecting raw slot 6 in Practice. Confirmation stores
the selected raw slot at manager `+0xFC` and releases the owner. The raw
stage range `0..17` and archive mapping belong to
[UN4 stages](../gameplay/stages/un4_stages.md#archive-set-and-ccs-format).

## Participants and manual control

`battle_manager_reset_participants` (`0x00322500`) initializes the two
participant entries at manager `+0x80` and `+0xA0`. Character IDs are words
at `+0x84/+0xA4`; bit 1 of the entries' first byte selects COM control.
`battle_manager_set_control_mode` (`0x003223E0`) stores the control mode at
`+0x5C`; mode 0 clears both COM
flags. `battle_manager_finalize_loadouts` (`0x00322670`) prepares each
side's jutsu and chooses its native default Ultimate record when absent,
before state 8 queues the fighters.

In Practice, `practice_behavior_set` (`0x003241B0`) and
`practice_behavior_get` (`0x00324290`) use profile `+0x40`, reached through
manager `+4`. `practice_settings_apply` (`0x00384F60`) treats Behavior 0
as manual and calls `practice_toggle_com` (`0x003850D0`) to clear the
opposite side's COM flag. The same getter value permits both players'
menus in `battle_menu_initialize_players` (`0x0038BAD0`).
