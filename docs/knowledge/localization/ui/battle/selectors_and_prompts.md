# Battle UI selectors and prompts

## Research coverage

Established: retail NA2 and NUN5 selector, prompt, scroll-arrow and label differences.
The recorded awakening-texture correspondences have high confidence; all 72
mapped ordinary labels have checked retail source hashes and decoded textures.
Open: other callers and animation phases, and the NUN5 player-marker comparison.
Jutsu-name lead `jutsu_name_display_unverified_lead` (`0x001F64A4`) remains open.
Names come from `@annotations/NA2` and `@annotations/NUN5`.
Addresses are live; annotation comments hold the per-routine details.

Binary identities and address conventions are defined in the
[Standard game file identities](../../../game/files/file_identities.md).
Command List and move-chart rows belong to
[Battle Command List and move chart](command_list_and_move_chart.md),
awakening behavior to [Awakening](../../../gameplay/characters/awakening.md),
and Jutsu-selector row text to
[Numeric and settings text rendering](../../font/numeric_rendering.md#jutsu-selector-row).

## Player markers

NA2 `hud_world_marker_draw` (`0x006BA870`, BTL) draws the marker above a
fighter. It suppresses drawing when `BattleWorldMarkerView.state == 1` or
`hud_marker_visible` returns zero; that resident gate excludes coordinator
states 4, 5 and 6.

The label and arrow come from `battle_hud_sprite_records`
(`0x008BFFB0`). Its `BattleHudSpriteRecord` fields describe UV coordinates,
width, height, texture slot and color index. The six marker records are also
named `battle_player_marker_records` (`0x008C052C`):

| Case | Label record and rectangle | Arrow record and rectangle |
| --- | --- | --- |
| Side 0 | 117, `1P`, `(129,1,34,26)` | 120, red, `(129,29,22,22)` |
| Other side | 118, `2P`, `(165,1,34,26)` | 121, blue, `(153,29,22,22)` |
| COM gate passes | 119, `COM`, `(201,1,46,26)` | 122, green, `(177,29,22,22)` |

All six use texture slot 4, `TEX_xmenu`, and color index 0. The COM gate
resolves `primary_fighter_get(marker.side)` and requires nonzero bits 5–8 of
`FighterMarkerControlView.packed_control_flags`. This partial view records the
verified halfword read independently of the applied full `Fighter` type.
It also requires
`fighters_both_marker_control_fields_set` to return zero. That predicate
returns one only when both primary fighters have a nonzero packed field.
The interpretation as a computer-controlled marker is inferred from the
`COM` label.

The marker position is clamped to X 20..492 and Y 40..344. The arrow is drawn
first, then the label 17 pixels above it, through
`sprite_draw_scaled_rectangle`; the arrow's horizontal scale pulses while
the label keeps unit scale.

## Ordinary awakening-label composition

| Game | Routine | Live resident entry |
| --- | --- | ---: |
| NA2 | `effect_aux_visual_construct` | `0x00303AA0` |
| NUN5 | `effect_aux_visual_construct` | `0x0030E250` |

Both games build the ordinary awakening-name panel from the same resource
roles. `effect_apply` supplies a side and effect; the side selects the common
label and the character-resource bank. The additional forwarded control value
is unused by the compositor.

The 13-row `effect_aux_selector_table` selects a texture-name slot.
A negative selector or unavailable common resource sets
`EffectAuxVisual.countdown` to 10. Otherwise the compositor stores the side
and effect, creates the side-selected common label and
`effect_aux_common_animation_name` (`ANM_mode1name_ca`), and obtains
resource slot 4 for that side.

In NA2, `battle_queue_fighter_ccs` supplies slot 4 from the selected
character's `character_portrait_filenames` entry, a `3EYE/3???3PCT.CCS`
container. [Per-side resource adoption](../../../game/character_assets.md#per-side-request-adoption-and-release)
owns that loader. The selected phrase therefore depends on the recipient's
resource, not only the gameplay effect ID.

The label uses `effect_aux_panel_model_name` (`MDL_mn_panel`) and
`effect_aux_panel_material_name` (`MAT_joutai`). Texture replacement
requires the model, material and selected texture to exist.
`effect_aux_texture_names` contains `TEX_mode1name1`,
`TEX_mode1name2` and `TEX_mode1name3`; the established selector paths
use only the first two.

Recorded asset correspondences include:

- NA2 `x\mode1\tex\hnt\mode1name1.bmp` → NUN5
  `x\mode1\tex\hnw\mode1name1.bmp`;
- NA2 `x\mode1\tex\row\mode1name1.bmp` → NUN5
  `x\mode1\tex\roc\mode1name1.bmp`;
- NA2 `x\mode1\tex\tnd\mode1name2.bmp` → NUN5
  `x\mode1\tex\tnw\mode1name2.bmp`.

The recorded comparison established decoded RGBA equality for all 72
mappings across the complete retail CVM inventory. The compositor interpretation
and texture correspondence have high confidence.

The current naming census checked the maintained NA2/NUN5 source hashes for
all 61 portrait containers behind the 72 mapped `mode1name` textures and
decoded all 144 source textures. [Status identity and naming coverage](../../../gameplay/projectiles_and_items/battle_items_and_status_effects.md#status-identity-and-naming-coverage)
owns the effect/character/phrase joins. Shared phrases and paired IDs need
owner qualifiers; a corresponding English phrase does not establish equal
mechanics or a fixed title for arbitrary recipients.

## Open VS Jutsu selector

### Homologous methods

| Game | Open callback | Closed callback |
| --- | --- | --- |
| NA2 | `jutsu_selector_draw_open`, `0x006BD510` | `jutsu_selector_draw_closed`, `0x006BD130` |
| NUN5 | `jutsu_selector_draw_open`, `0x006D0890` | `jutsu_selector_draw_closed`, `0x006D04B0` |

Both open callbacks render two rows and the selected entry through
`jutsu_select_draw`. The confirmation-state object dispatches them
indirectly; a single direct caller is not established.

Arrows require a resolved selected character and at least three eligible
Jutsu. In the stable open state, their center is X 115 for side 0 or X 409
for the other side, and Y `selected_row * 68 + 210`.
Their pulse displacement is `sin(pulse_angle) * 6`.

NUN5 draws only the two vertical arrows. It clears vertical flip, sets
`ProjectedTextGeometryView.rotation` to +pi/2, and draws the upper arrow
at `centerY - 56 - pulse`. It then sets vertical flip and rotation -pi/2
and draws the lower arrow at `centerY + 56 + pulse`. After both draws,
it restores rotation zero and clears vertical flip.

NA2 retains two horizontal-arrow submissions while open and does not set
either quarter-turn rotation before its vertical submissions.
Its `jutsu_selector_vertical_arrow_rectangle` (`0x008C08E0`) is
`(139,257,38,22)`. NUN5's `localized_jutsu_arrow_rectangle(0)` selects
`jutsu_selector_english_arrow_rectangle` (`0x005DDF70`),
`(145,385,22,38)`, in English. Draw count, orientation and source geometry
all differ between the two presentations.

## VS confirmation prompts and bottom legends

`vs_settings_draw_prompts` is the confirmation draw callback in both games:
NA2 `0x006C0D00`, NUN5 `0x006D4170`. It draws selection prompts, then
reuses `VsConfirmationPromptView.footer_sprite` for OK followed by Back.
Both use base X anchors 400 and 470 and Y 356; NUN5 adds its regional
horizontal offsets.

The native `button_icon_submit` implementations differ. NA2's first two
`common_prompt_regional_rectangles` (`0x005D4690`) are 70×22 regional
legends, with a backing rectangle submitted before each. The backing's sprite
identity is unestablished. NUN5's first two
`common_prompt_english_rectangles` (`0x005DE870`) combine Cross/OK
`(1,1,56,22)` and Triangle/Back `(1,25,64,22)`.
The shared sprite's queued geometry changes between submissions, so equal
base anchors do not establish equal raster placement in the two games.

## Command Menu and Command Chart scroll indicators

### Shared renderer and record

| Game | Draw callback | Scroll rectangle |
| --- | --- | --- |
| NA2 | `command_list_draw`, `0x00878860` | `command_scroll_arrow_rectangle`, `0x008D1548` |
| NUN5 | `command_list_draw`, `0x00894FA0` | `command_scroll_arrow_rectangle`, `0x008E81D8` |

Both callbacks belong to the shared Practice/Free Battle command presentation
associated with `ccStartMenuPrivateCmd`. Their draw dispatch is indirect.
The controller's constructor entry remains unestablished.

Both games obtain layer 3 through `command_menu_sprite_get`, set its
rotation to pi and draw the top arrow at X 256, Y `32 + pulse_offset`.
They then set rotation zero and draw the bottom arrow at X 256,
Y `348 - pulse_offset`, before `sprite_reset` flushes the batch.
The helper does not release the sprite or its texture.

The draw ordering and orientation agree. The source geometry differs:

| Game | Rectangle | Bytes |
| --- | --- | --- |
| NA2 | `(194,195,20,20)` | `C200C30014001400` |
| NUN5 | `(1,225,20,22)` | `0100E10014001600` |

## Ultimate Jutsu one-part label

NA2's Ultimate Jutsu banner uses two 64×64 label halves. Official NUN5 uses
one 128×64 label and one-part construction behavior; its `OUGI.CCS` contains
the corresponding model, UV, texture and animation layout.

## Round label

NA2 constructs `Round` from two Japanese 38×38 glyph rectangles at X 216,
Y 44 and scale 1.4. NUN5 uses one English 94×30 rectangle at X 256,
Y 24, scale 1.2 and a Y 64 render constant.
