# UN4 front-end and Practice flow

## Research coverage

Established statically: resident startup's language-selection dependency,
New Game's directory-check branch,
Mode Select's Practice result, Practice's selection and loading states,
participant fields, raw stage ownership, manual-opponent settings, and the
Command Display and Easy Display flags.
An observed startup snapshot confirms waiting in the language selector before
the outer state loop.
Open: nothing.

Names come from `@annotations/UN4`. Addresses are live resident
`SLUS_218.62` addresses unless a battle-overlay routine is named. Binary
identity and address conventions belong to
[Retail file identities](files/file_identities.md#address-conventions).

## Startup and Practice entry

`game_main_task` (`0x001C94D0`) initializes MOTHER and enters outer state 2
at `0x001C97CC..0x001C97D0`, after its startup readiness loop. Before that
write, the loop calls `splash_update` (`0x001C8E20`). State 1 constructs the
English/French selector; state 2 waits for `language_select_update`
(`0x003F5B20`) to confirm it. The selector's selected row is halfword `+0x1A`.
Its input load at `0x003F5B40` reads the engine's pressed-button word;
bit `0x40` commits the selected row through `ui_language_set_index`
(`0x003F50B0`) and returns 1. Merely choosing a different outer starting
state does not bypass this earlier wait.

`splash_update` state 3 calls `ui_language_reload_resources`
(`0x003F50F0`) to load the selected text overlay, adjusts audio resources
if the language changed, starts audio readiness work, then constructs the
splash sequence. These steps precede MOTHER's outer loop. States 2 and 3
of that outer loop run logos and title; state 5
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

## Command Display and Easy Display

Both settings occupy profile byte `+0x38`, reached through manager `+4`.
`practice_command_display_set` (`0x003239E0`) changes bit `0x01` only in
Practice mode 2; zero disables it. `practice_command_display_get`
(`0x00323A80`) reads that bit in Practice and returns 1 in other modes.
The first Practice Settings row commits this field; its English help at
`TEXTENG.BIN:0x00890F00` identifies Command Display.

Pause menu action 14 is Easy Display Setup, identified by the English label
at `TEXTENG.BIN:0x00890080`. `easy_display_initialize` (`0x003921E0`)
selects row 0 when profile bit `0x04` is set and row 1 otherwise.
`easy_display_update` (`0x003922A0`) confirms row 0 by setting that bit and
row 1 by clearing it; cancellation leaves it unchanged. Both display flags
can therefore be cleared with mask `0xFA`, preserving the other profile bits.
