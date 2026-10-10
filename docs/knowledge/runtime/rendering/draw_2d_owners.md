# Full-screen and bounded 2D draw ownership

## Research coverage

Established: shared-2D consumers, the direct primitive-emitter census, all 62
direct presentation-rectangle requests, colored covers, oversized masks,
bounded atlas/text, authored CCS owners, interaction regions, selected cursor
and computed-callback paths, extended/directional sprite and scrollbar
attachments, framebuffer coordinate ownership, 71 scoped
transition-pool setups, BTL cover/window identities, native help backing,
splash source artwork and selected authored menu backing models.
Open: unsampled authored frames, indirect/inline
draw paths, the optional Circle panel's parent, exact SPBATTLE labels and
higher resource ownership of local flashes.
Names come from `@annotations/NA2`; comments carry per-routine evidence.
Coverage is static and bounded; incomplete references do not prove absence.

This document classifies retail NA2 (`SLPS-25837`) 2D geometry by its
screen/object, purpose, coordinate space, transforms and clipping owner.
All addresses are [live](../../game/files/file_identities.md#address-conventions);
resident routines belong to `SLPS_258.37`; overlay routines identify `BTL.BIN`
or `ETC.BIN` where the distinction is needed.

Shared transform formulas belong to [Renderer and coordinate systems](renderer_coordinates.md),
packet lifetime to [Render submission](render_submission.md), HUD bindings to
[Battle HUD](../../gameplay/session/battle_hud.md), and font metrics to
[Font renderer metrics](../../localization/font/renderer_metrics.md).
No rendered output is established by this static classification.

## Colored-rectangle slots

`transition_pool_initialize` (`0x001834B0`) creates a `UiTransitionPool`
whose four slots hold a logical origin and width/height, rather than endpoints.
Its shared default drawing environment starts with viewport `(0,0,512,384)`,
center `(256,192)` and unit projection scales. That environment is separate
from each caller's pool.

`transition_opacity_out_start`, `transition_opacity_in_start` and
`transition_start` retain the supplied geometry.
[UI animation and easing](../ui_animation.md#four-slot-rgba-transition-pool)
owns allocation, RGBA interpolation, durations, completion and reuse.

`rgba_transition_pool_draw` (`0x00183650`) skips a pool when
`UiTransitionPool.gate != 0`; otherwise it selects `render_context` or the
shared default and processes active slots in ascending index order. It
transforms the origin with `renderer_transform_2d_integer`, but derives
width/height only from the X/Y diagonals of `RendererTransformState.transform_2d`.
Its four corners therefore remain axis-aligned even when the anchor uses a
rotated transform.

`transition_present` (`0x00186000`) assigns its supplied environment to
`primary_transition_pool` (`0x00607460`), then draws it. It assigns
`transition_alternate_render_context` to the second, `global_transition_pool`
(`0x00607464`), then draws that pool. `transition_global_start` and the
inspected global frontend/battle requests use this second pool.
The constructor's default viewport does not establish the final list used by
every global fade. Local pools can also select their own context.

## Immediate rectangles and bounded sprites

`immediate_rectangle_float` (`0x00353850`) and
`immediate_rectangle_integer` (`0x00353F40`) accept logical
`(x,y,width,height)` and packed RGBA. Both reset shared render state, begin a
type-5 primitive through `render_begin_draw_packet`, submit four corners with
`model_property_build_draw_workspace(0)`, and end with `render_end_draw_packet`.
The integer helper uses signed-halfword dimensions and endpoint sums and
additionally disables depth writes through `render_set_depth_writes`.
Neither helper supplies a full-screen size.

Every immediate corner passes through the current local transform composed
with the selected renderer's `transform_2d`. The vertex emitter's alternative
projection branch uses `device_projection`; these helpers choose the 2D
branch. This differs from the slot consumer's diagonal-only extent calculation.

`sprite_draw_rectangle` (`0x0037BC40`) reads a `BattleHudRectangle` of
signed-halfword source origin and size. It retains source dimensions and fixed4
UV origin, sets `ProjectedTextGeometryView.source_mode` to 1, and sets
destination size, caller position and centered local origin.
`sprite_draw_scaled_rectangle` (`0x0037BD00`) scales destination size and
centering independently on X/Y while preserving source size. Both retain the
sprite's texture, RGB and opacity and submit through `scene_output_finalize`.
`sprite_reset` (`0x001CC070`) attaches accumulated packets to the selected
list and clears the batch count and packet pointer.

The shared consumer `text_draw_projected_rectangle` (`0x001CC3A0`) traverses
a byte sequence; `scene_output_finalize` supplies the one-byte sequence used by
these sprites. Its geometry branches use `ProjectedTextGeometryView`:

| State | Transform and bounds contract |
| --- | --- |
| `geometry_flags & 2 == 0` | Transform `x/y + local_x/local_y`; size uses the 2D matrix diagonals. Reject by extent overlap outside device X `0x7000..0x9000`, Y `0x7200..0x8E00`. |
| `geometry_flags & 2 != 0` | Negate `rotation`, rotate the local offset and two extent vectors, add caller position, and transform all four corners. Reject when all four corners fail the same device bounds. |
| Textured `geometry_flags & 1` | Construct source UVs from atlas size/origin; bits `0x20/0x40` exchange X/Y UV corners independently of geometry rotation. |

The rejection region is 512 by 448 device pixels, at 16 units per pixel and
centered on `0x8000`. It is broader vertically than the logical 384-line
viewport. These are coarse CPU bounds, separate from object-specific scissor
state; they do not establish visible pixels outside the logical viewport.
Generic rotation support does not establish that an individual HUD caller
enables it.

### Direct primitive-emitter census

The encoded JAL to `model_property_build_draw_workspace` has 98 physical
resident sites in 19 routines and 13 BTL sites in four routines; ETC has none.
Resident memory aliases produce 294 byte matches for those 98 sites. All 19
resident caller bodies use flags zero and the shared 2D branch. This census
covers direct calls to this emitter, rather than every GS packet producer or
indirect call in the game.

Besides the immediate rectangles, glyphs, playback bars and splashes, the
resident cohort includes these owners:

| Geometry owner | Named routines | Coordinate ownership |
| --- | --- | --- |
| Textured quads | `immediate_textured_rectangle_scaled_rotated` (`0x00353A60`), `centered_texture_owner_draw` (`0x00391EA0`), `centered_record_quad_draw` (`0x003943B0`) | Caller dimensions, optional local rotation or uniform scale, then shared 2D. Texture/artwork identity is separate from quad extent. |
| Atlas number | `atlas_number_with_suffix_draw` (`0x00360740`) | Up to three decimal digits and suffix use local atlas metrics on the supplied context. Exact screen identity remains open. |
| Colored mesh/segments | `colored_six_rectangle_pairs_draw` (`0x0036E480`), `colored_radial_mesh_draw` (`0x0036E590`), `gradient_axis_segment_draw` (`0x00378AD0`), `gradient_rectangle_draw` (`0x00378D50`), `gradient_axis_segment_color_first_draw` (`0x0037DDB0`) | Caller pairs, ring/band geometry or segment/rectangle dimensions. None has an intrinsic screen-cover contract. |
| Rectangle records | `immediate_rectangle_outline_draw` (`0x0037DC20`), `colored_rectangle_record_draw` (`0x0037E030`), `twelve_rectangle_color_pulse_draw` (`0x0038AB60`) | Closed perimeter, caller rectangle or twelve signed-halfword table rectangles. Producer semantics remain separate. |
| Text/state overlays | `ccs_player_status_overlay_draw` (`0x0019FD20`), `text_panel_state_draw` (`0x00390A30`) | Bounded backing plus text; CCS status reachability and the panel's screen identity remain open. |

BTL's `linked_ribbon_geometry_draw` (`0x00707BD0`) selects flags zero when
owner flag `0x1000` is set, otherwise flags one and `device_projection`.
`track_render_weights` (`0x00720FD0`) uses flags one for its world-space trail
points; that path is not evidence of a bounded UI bypass. The remaining two
owners are the interaction-region draws below.

## Practice geometry cohort

`practice_settings_draw` (`BTL.BIN:0x00882250`) selects
`PracticeSettings.backing[0]` for its full-frame colored backdrop. The
`backdrop` byte gates `(0,0,512,384)` with RGBA
`(s16(alpha)<<24) | 0x86A8BE`, independently of later rows, authored backing
and prompts. Rows remain gated by opacity and the separate reveal delay.

Its bounded pulse panel uses `panels[0]` and
`practice_settings_panel_rectangle` (`0x008D1908`), whose first source cell
is `(1,1,126,30)`, through `ui_pulse_sprite_draw`. The four
`panels[0..3]` batches are submitted separately. A backdrop elsewhere in the
child does not change this atlas panel's bounds.

The adjacent `battle_settings_present` (`BTL.BIN:0x008807A0`) owns a
separate backdrop with the same logical geometry and alpha-derived color.
It uses `BattleSettings.render_context`, rather than the Practice settings
pool, and separately gates backing, rows and prompts.

Backing/title geometry is authored CCS animation/model content. Resources,
row windows and lifetime are owned by
[Practice Mode](../../gameplay/modes/practice_mode.md#native-practice-settings-presentation-geometry).

## Confirmed screen-sized callers

These owners explicitly request origin `(0,0)`, extent `(512,384)`.
Classification follows their geometry and fade state, together with the
selected list's clipping contract.

| Owner/path | Named owner | Geometry and state ownership |
| --- | --- | --- |
| Global fade | `transition_global_start` (`0x00105600`) | Forward supplied duration/colors to the second/global pool with fixed full-frame geometry; presentation selects the alternate context. |
| Table-selected fill/fade | `transition_fullscreen_hold` (`0x001EB600`), `transition_fullscreen_reverse` (`0x001EB670`), `transition_fullscreen_forward` (`0x001EB700`) | Clear the secondary slots first; hold uses the second color for both endpoints, reverse uses second→first, forward uses first→second. |
| Playback/transition | `movie_play_descriptor` (`0x001DBD60`) | Initial cover and timed/skip transitions use opaque/transparent white. Wait on `settings_resource_pending` and yield through `task_wait_current`. The exact presentation identity remains open beyond the established movie ownership. |
| Title | `title_update` (`0x001DF690`) | State 2 starts a 14-step white cover; states 4/6 use the black table fade over 20 steps. Scene geometry belongs separately to `title_present`. |
| Mode Select entry/return | `mode_select_construct_resources` (`0x00383DB0`), `mode_select_update` (`0x003854F0`) | Entry: opaque→transparent white over 16 steps. Return to title: transparent→opaque saved clear color over 30 steps. Resumed dialog: `0x50000000`→transparent over four steps. |
| Character Select confirmation | `character_select_update` (`0x003BBBB0`) | Accepted selection starts transparent→opaque white over 16 steps, independently of portrait and prompt batches. |

The decoded `transition_fullscreen_colors` (`0x005C0950`) values are:

| Index | First color | Second color |
| ---: | ---: | ---: |
| 0 | `0x00000000` | `0xFF000000` |
| 1 | `0x00FFFFFF` | `0xFFFFFFFF` |
| 2 | `0x00FFFFFF` | `0xFFFFFFFF` |

These express black/white opacity transitions; the wrapper chooses direction.
Table index bounds are unproved.

Title and Mode Select state ownership is in
[Front-end mode flow](../../game/mode_flow.md#mode-select-controller);
Character Select's final handoff is in
[Character Select](../../game/character_select.md#appearance-fixed-choices-and-final-handoff).

### Scoped transition producer ownership

The inspected in-scope setup labels comprise 38 resident sites, 27 BTL sites
and six Collection ETC sites. All 71 supply `(0,0,512,384)`: 69 select
`global_transition_pool`, while two select embedded pools below. This closes
geometry in that cohort, rather than every call to these generic services.

| Screen/path | Named producer ownership | Cover relationship |
| --- | --- | --- |
| Options and its Controls/Audio/Display children | `options_initialize` (`0x0038AFB0`), `options_exit_update` (`0x0038B710`), `options_save_confirm_update` (`0x0038BBF0`) | Entry/exit white fades, black save-confirm fade and child-return white opacity-out; bounded child windows remain separate. |
| Mode/Character Select | `mode_select_dispatch_input` (`0x003849C0`), `menu_select_saved_gate` (`0x00384760`), `character_select_prepare_practice` (`0x003B9F60`), `character_select_start_cancel_exit` (`0x003BBB30`), `character_select_poll` (`0x003BCA90`) | Save-child dimmer and accepted/cancelled screen changes use the global pool, independently of portraits, prompts and dialogs. |
| Settings and Stage Select | `btl_reset_player_records` (`BTL:0x006C0380`), `settings_parent_select` (`BTL:0x006C07C0`), `preparation_owner_reset` (`0x00714700`), `directional_players_input` (`0x00714830`), `stage_select_random_update` (`0x00714AD0`) | White entry/accept/cancel covers; stage artwork and settings rows retain their own geometry. |
| Results, jutsu and Start Menu | `battle_score_presentation_create` (`0x001EE880`), `manager_update_substate_four` (`0x001EF9C0`), `encounter_conditions_result_update` (`0x001F2920`), `position_player_seek` (`0x00717A60`), `jutsu_presentation_render` (`0x0076A8E0`), `rng_case5_state_update` (`0x0076CC00`), `start_menu_select_update` (`0x0087C720`), `start_menu_update_module` (`0x0087CB20`) | Screen-sized color/opacity requests remain independent of result stamps, fighter scenes and bounded menu panels. |
| Collection | `collection_skill_open` (`ETC:0x006C0500`), `collection_movie_confirm` (`ETC:0x006C3D70`), `replay_play_selected_movie` (`ETC:0x006C4260`), `collection_completion_query` (`ETC:0x006C7DA0`) | White entry/confirmation/movie-return/exit covers select the same resident global pool. |

`transition_member_owner_draw` (`0x00392730`) and
`transition_record_owner_draw` (`0x00394620`) request one-step full-frame white
flashes from pools embedded at owner `+0x90` and `+0x40`. Their constructors,
`transition_member_owner_initialize` (`0x00392140`) and
`transition_record_owner_initialize` (`0x00393E70`), bind the pools to contexts
borrowing `default_renderer`. The separate textured flare quads remain bounded.
Visibility/alpha comes from `bg_update_visibility_rays` and
`bg_update_visibility_screen_placements`. The first constructor reads container
and animation names from supplied `0x58`-byte descriptors; the second receives
its container and name/size/color records from its caller. Exact asset indexing
is separate from this completed fill/artwork distinction. Indexed references,
stored-pointer and direct J/JAL searches across resident, BTL and ETC expose no
attachment to the second initializer/draw, without truncation. Computed-address
reachability remains open; these searches do not establish that the code is dead.

### Presentation-rectangle records

`presentation_effect_request` (`0x00309C50`) retains a caller origin and
width/height in one of four `0x50`-byte records. Its direct encoded-JAL and
xref census is five physical resident calls, 57 BTL calls and no ETC calls.
All 62 inspected setups supply `(0,0,512,384)`. Source-setup labels in
`@annotations/NA2` retain each site's evidence. The service itself still
accepts arbitrary dimensions; the census does not classify indirect callers.

Known producers include `clash_initialize`, `skill_primary_submit_record`,
`skill_camera_enter` and the cut-in controller. `cutin_stage_record`
(`0x0086FCD0`) requests transparent-to-`0x40000000` black on its own bank;
`cutin_reset` (`0x0086FEA0`) and `cutin_update` (`0x00870270`) request the
reverse. Other inspected producers use black, white or colored opacity
transitions, independently of their authored scene geometry. Exact character
and scene identities remain open for some producer routines.

`presentation_rectangle_records_draw` (`0x00309BC0`) counts active records
and selects its optional environment or the current environment.
`effect_resource_second_pass` (`0x0030BF00`) separately draws the manager's
two four-record banks before resource callbacks, using their optional
environments. Both submit through `sprite_draw_projected_rectangle`
(`0x00309800`): the anchor uses the complete shared 2D matrix and extents
use its X/Y diagonals. These colored records do not use
`draw_transform_record_initialize` or its framebuffer-effect record.

`presentation_rectangle_records_update` (`0x00309400`) interpolates the
records' RGBA channels into the packed color consumed by drawing; geometry is
retained separately. `effect_manager_phase1` updates both manager banks.
`linked_players_tyvc_update` (`BTL.BIN:0x007C7BF0`) owns another bank at
`+0x1120`, requests screen-sized black transitions and updates that bank at
the end of its pass. These local banks keep their own phase/color state.

## Direct immediate-rectangle caller inventory

This is the bounded cohort of inspected direct callers. It does not cover
inline quads, function-pointer calls or rectangle-slot producers. Annotation
comments retain the physical-call census and individual call evidence.
Logical geometry is `(x,y,width,height)`; dimensions alone do not identify a
screen.

| Owner | Named routine(s), live entry | Logical geometry and draw state |
| --- | --- | --- |
| Ultimate Battle and Survival result backgrounds | `btl_menu_background_draw` (`0x006DE7A0`), `btl_menu_modal_draw_a` (`0x006EBAF0`), `btl_menu_modal_draw_b` (`0x006EDB80`) | Float `(0,0,512,384)`, RGBA `0x18000000`, before separate menu/result geometry. A is the Survival win result; B is the finite-course result. |
| Start Menu row highlight | `start_menu_panel_draw` (`0x0087D200`) | Float `(windowX+1,panel_center_y-22,windowWidth-2,44)`, `0x5FD45050`; uses the transition panel's context and queried origin/extent. Bounded row highlight. |
| Battle settings backdrop | `battle_settings_present` (`0x008807A0`) | Float `(0,0,512,384)`, `(s16(alpha)<<24)\|0x86A8BE`; separately owned from Practice settings. |
| Practice settings backdrop | `practice_settings_draw` (`0x00882250`) | Same full-frame/color contract, gated by `PracticeSettings.backdrop`. |
| SPBATTLE window dimmers | `btl_window_rows_draw` (`0x006E2D70`, `ccTermsInfoWnd`), `btl_window_two_boxes_draw` (`0x006E4D80`, `ccTermsBtlSetWnd`), `btl_window_scene_draw` (`0x006E6CE0`, `ccTermsSelWnd`) | Integer `(0,0,512,448)`, black with computed opacity. The first two multiply modal opacity by parent `fraction` and `255*0.5`. Requested logical height does not establish a 448-line viewport. |
| Two repeated boxes | `btl_window_two_boxes_draw` (`0x006E4D80`) | For `i=0,1`: outer `(110,16+36*i,123,25)`, RGB `0x808080`; inner `(112,18+36*i,121,23)`, RGB `0xF0F0F0`. Parent `fraction` controls alpha, independently of its modal dimmer. |
| BTL modal covers | `btl_menu_modal_draw_a`, `btl_menu_modal_draw_b`, `btl_modal_text_draw_a` (`0x006ED080`), `btl_modal_text_draw_b` (`0x006ED2E0`) | Integer `(0,0,512,384)`, `0x88000000`, before modal/menu children. Exact modal labels remain open. |
| Selected-stage fallback | `stage_select_selected_stage_draw` (`0x007151D0`), called by `stage_select_close` (`0x00715CC0`) | Integer `(20,340,200,40)`, `0x7F000000`, when the selected stage has no match in the 24-row record table. Matching selects its stage-name atlas cell; fallback adds a box/text and subsequently uses record 0's atlas cell. |
| Battle item-selection separator | `btl_item_menu_draw` (`0x008768D0`), `btl_item_menu_separator_rectangle` (`0x008BD830`) | Fixed X `8`, width `348`, height `1`, RGBA `0xA0402020`; when item index `0x15` is in the seven visible rows, only Y becomes `rowY-16`. Signed-halfword conversion uses the parent window's content context. This is a bounded rule. |
| Three menu rules | `btl_item_menu_draw`, `btl_menu_rule_rectangles` (`0x008BD850`) | `0xFF404040` with `(200,14,1,296)`, `(284,14,1,296)`, `(8,42,348,2)`: bounded vertical/horizontal rules. |
| Start Menu host cover | `start_menu_draw` (`0x0087D460`), `start_menu_cover_rectangle` (`0x008BD9F0`) | Integer `(0,0,512,384)`, `0x88000000`; host `render_context` selected before child dispatch. |
| Running-help backing | `scrolling_strip_draw` (`0x0037F900`) | Native styles stretch a `2x48` alpha slice to an owner-width `512x48` band in a separate backing context; text has its own cropped context. Null texture/descriptor selects the generic solid rectangle branch. |
| Character Select modal covers | `character_select_draw_assignment_dialog` (`0x003BC780`), `character_select_draw_return_dialog` (`0x003BC950`) | Integer `(0,0,512,384)`, `0x88000000`, followed by windows and bounded text/prompts. Specific modal labels remain open. |

The Start Menu child/result boundaries are in
[Pause and replay](../../gameplay/session/pause_and_replay.md#btl-start-menu-construction-and-ui-states);
stage records, previews and names are in
[Native Stage Select](../../game/stage_select.md#stage-records).

`ultimate_battle_menu_resources_initialize` (`0x006DE1F0`) links the menu
background to `spbattle.ccs`, `TEX_spbattle01/02` and `CMP_sp_plane01`.
`survival_result_wrapper_construct` (`0x006EE0C0`) constructs the two result
children; `encounter_result_helper_draw` (`0x006EE4E0`) dispatches kind 1 to
the win result and kind 2 to the finite-course result. Their full-frame
background/modal covers remain distinct from ranking, row highlights and text.

`battle_spbattle_ccs_acquire` (`0x006E78A0`) constructs the three Terms window
classes. `spbattle_linked_windows_draw` (`0x006E8070`) invokes their descriptor
draw member `+0x18`, establishing computed reachability. Their authored
`ANM_spbattle_ca`/rule/player scenes and `gauge` atlas children have separate
geometry. Exact translated screen wording remains open.

`battle_item_selection_construct` (`0x00875B80`) creates the item-selection
window and `ANM_xkun1a` / `MDL_xkun1` player. The same owner supplies the
22 selectable item rows to `battle_item_selection_update`. Its separator and
three fixed rules do not derive their extents from that authored player.

`panel_initialize` (`0x0037FFC0`) gives the panel's backing/modal-cover,
border and text contexts separate newly constructed renderers.
`panel_create_sprite_children` (`0x003802C0`) binds backing to the first,
border children to the second. `panel_set_rectangle` (`0x00380420`)
updates only the text renderer's viewport to the panel interior. Text viewport
updates also occur during origin/style/transition changes; their lifetime is
owned by [Selected UI renderer bindings](renderer_coordinates.md#selected-ui-renderer-bindings).
Thus the modal cover selected by `panel_get_render_context` uses a different renderer
from cropped text; panel bounds do not make that cover a bounded text quad.

## Screen and resource ownership

The inspected consumers distinguish the frame they cover from the bounded
artwork, text or authored scene layered with it.

| Screen/object | Named owner/resource | Geometry/layout contract |
| --- | --- | --- |
| Startup splashes | `splash_create_children` (`0x001E0390`), `splash_draw` (`0x001E00E0`); four `TEX_logo_*_pss` textures in `logo.ccs` | Full-frame type-5 textured quad `(0,0)..(512,384)`, reversed V, `SplashObject.opacity`, suppressed in state 7. Opaque backing and bounded source artwork are baked into each texture, as detailed below. |
| Title scene | `title_present` (`0x001DFAB0`), `TitleController.player/item_players` | Authored CCS geometry, selected camera/list; presentation phase gates scene/items. Separate transition owns the cover. |
| Mode Select scene/footer | `mode_select_present` (`0x00385C00`), `ModeSelectInput.background_player/foreground_player/decoration_player` | Authored CCS main scene. Footer uses bounded atlas sprites on `prompt_context`, plus separately owned windows/help. Full-frame list selection does not make each sprite full-frame. |
| Support carousel | `character_selector_draw_support_cells` (`0x003B84D0`), `support_portrait_rectangle_copy` (`0x0037D470`), `support_portrait_rectangles` (`0x005D4B70`) | Thirteen columns `-6..6`, caller-derived X and Y `61`, centered atlas rectangles. Decoded leading portraits, `support_unavailable_rectangle` (`0x00604830`) and `support_selected_rectangle` (`0x00604838`) are `38x46`; selector motion changes centers independently of the cover. |
| Battle top panels | `hud_hp_draw` (`BTL.BIN:0x0071C0E0`) | Current/trailing HP widths derive from source rectangles and sampled ratios. Mirrored parent position/scale places atlas bars, frames, names and icons. |
| Running help | `scrolling_strip_draw` (`0x0037F900`) | Full-width band made from native alpha-strip artwork; linked text uses its separate crop. Local layout width is independent of glyph dimensions. |
| Font glyphs | `font_draw_glyph` (`0x00187CC0`) | Individual type-5 textured quads. Normal destination uses descriptor width on both axes, right endpoint minus one; output height remains a source V extent. Orientation changes corners/UV; context/caller owns placement. |

Splash resource lifecycle is in [Startup](../../game/startup.md#splash-controller).
Portrait identity/motion is in
[Character Select](../../game/character_select.md#support-cursor-and-carousel).
HUD resources, anchors, proportions and clock are in
[Battle HUD](../../gameplay/session/battle_hud.md#top-panel-construction).
Help backing resources, viewports and priorities are in
[Running help](../../localization/ui/running_help.md#native-na2-backing-resources).
Glyph descriptors are in
[Font renderer metrics](../../localization/font/renderer_metrics.md#glyph-geometry).

### Authored scenes and mixed owners

Original `LOGO.CCS` contains four `512x512` textures. All used pixels have
alpha `0x80`; the entire outer perimeter is opaque black for the notice page
and opaque white for the other three. These source-pixel bounds are inclusive,
with Y measured from the texture's top, rather than measured screen ink:

| Texture | TEX/CLT object IDs | Non-backing source-pixel bounds |
| --- | --- | --- |
| `TEX_logo_notice_pss` | `8/7` | `(93,111)..(429,404)` |
| `TEX_logo_bn_pss` | `6/5` | `(143,128)..(371,394)` |
| `TEX_logo_b_pss` | `4/3` | `(191,170)..(324,344)` |
| `TEX_logo_adx_pss` | `2/1` | `(178,170)..(482,454)`, including the auxiliary lettering |

The original compressed source SHA-256 is
`101a7f51ffc92476ae47d56c205c111da99709ef98109e9784bb45152b1ed1d9`.
`ccs_parse_clut_block` prepares the source palette into resident CSM1 order;
source image indices therefore use the original file palette's logical order.
Changing the whole splash destination changes both backing and artwork.

`title_present` and `mode_select_present` submit authored animation through
`projectile_compound_submit`. Its model children reach
`model_dispatch_geometry` and its effect children reach
`ccs_effect_child_update` / `particle_sprite_submit`. Both compose geometry
with `device_projection`, independently of the shared 2D matrix. A menu's
atlas footer and its authored scene therefore have different transform owners.
Model and effect contracts belong to [Model runtime](model_runtime.md) and
[Texture and material runtime](texture_material_runtime.md#frame-state-and-advancement).

`title_update` selects `ANM_title_menu01` or `ANM_mt01` from original
`TITLE.CCS`; item players use separate panel A/B animations. `ANM_mt01`
contains independent `MDL_blackpanel`, `MDL_char_back01`, `MDL_title_char`,
logo and writing models; banner/scroll models belong to the separate
`ANM_panel_a01/a02/b01/b02` item animations. The black panel has four vertices at X
`±268.75`, Z approximately `±201.56`, zero RGB/alpha `0x80` and identical
texture coordinates. The character backing is a separate atlas swatch;
`MDL_title_char` is a `512x384` model-space plane whose scenic texture includes
portraits. The latter combines backing with bounded artwork. Sharing
`TEX_mtttl02` or one player does not combine the models' geometric purposes.
Title camera positions have multiple authored keys, so one fixed camera does
not establish coverage throughout both animations.

`mode_select_construct_prompt_resources` (`0x00383F80`) binds original
`MODESEL1.CCS` players `ANM_modesel_ca`, `ANM_mode_back` and
`ANM_modemachine`. The first is camera-only, with constant position
`(0,-635.7800293,0)`, Euler `(90,0,0)` and view scalar `43.9131126`.
`ANM_mode_back` links to four-vertex `MDL_mode_back` through object/provider
IDs `20/21`, material `1412` and texture `1413`. Its model-space X bounds
are `-529.75..530`, Z `-397.25..397.5`; all four paired texture coordinates
are `(4,251)`. This constant-sample backing is separate from the machine's
15 object tracks, the tube and secondary backing model. Model-space extents
and source sampling identify these owners; they do not establish final
projected or widened coverage. Source identities are retained in annotations.

`hud_combo_draw` (`BTL.BIN:0x006B7100`) similarly mixes atlas digits with an
optional authored animation. It reconstructs the animation's world anchor
through `renderer_screen_depth_to_world` at depth 500. The digit and animation
paths are separate; their placement agreement depends on the forward
projection and the fixed-reference inverse described in
[Renderer and coordinate systems](renderer_coordinates.md#coordinate-utility-consumers).
Their separate paths do not by themselves establish a visible mismatch.

### Auxiliary interaction regions

`interaction_embedded_second_pass` (`BTL.BIN:0x00870CA0`) invokes
`interaction_region_draw` (`0x0086D690`) for two embedded per-side regions.
The active linked quad supplies region geometry; owner offsets and uniform
scale modify it about `(256,192)`. The draw mixes cropped black/transparent
mask geometry, an optional border and an authored animation player.

The two regions own eight renderer states. Their selected environments,
repeated viewport/2D publications, scoped player copies and teardown are owned
by [Interaction-region state lifetime](renderer_coordinates.md#interaction-region-state-lifetime).
Cropped masks and authored players use one region environment, the optional
border uses a full-frame-view environment, and tiles use width 512 with a
derived Y interval. `interaction_region_tiled_texture_draw` (`0x0086E260`)
draws `128x64` texture tiles along the supplied region edge.

These primitive vertices use shared 2D; their masks are region-owned, not
generic screen covers. Viewport/scissor construction and the authored player
remain independent of the primitive transform. Restoring environment selection
after the draw retains the newly published renderer state.

### Playback bars and captions

`movie_update_subtitles` (`0x001DC1A0`) uses
`transition_alternate_render_context` and emits two opaque black type-5 quads.
They share X endpoints: signed word `movie_bar_left_x` (`0x006075A0`) and
`movie_bar_bounds.right_x = 512`. `entry` zero-fills the BSS interval containing
the left word at `0x00100160`, establishing initial X `0`. Own-game xrefs
expose the four subtitle reads; an aligned GP word-store search across the
three maintained programs found no later producer. Indirect, bulk or aliased
mutation remains outside that bounded writer audit.

| Bar | Y interval |
| --- | --- |
| Upper | `0..20` |
| Lower | `314..384` |

`movie_bar_bounds` (`0x00602CB8`) supplies the three nonzero Y endpoints.
Caption text is independently centered at X `256`, Y `338` or `328` by
newline presence, with opacity from its controller. Sharing a presentation
list does not merge bar and caption geometry ownership.

### Framebuffer-effect local 2D object

CCS `ccStreamFBSBlurParam` (type `0x1D00`) owns an embedded
`DrawTransformRecord2D`, initialized by `draw_transform_record_initialize`
(`0x0010BB10`) with local pivot `(256,192)`, equal supplied X/Y scales,
angle, color and material state. `ccs_build_play_runtime_table`
(`0x001A0B80`) constructs this resource with scale `1` and rotation `0`.
Its descriptor is
`blur_parameter_vtable` (`0x005D9EC0`); type identity is owned by
[CCS object types](../../game/files/ccs_object_types.md).

`draw_environment_submit_2d_record` (`0x0010A520`) derives corners from
the selected renderer's viewport width/height and composes local
scale/rotation/translation with its 2D matrix. This is a framebuffer-effect
coverage owner, separate from atlas portrait, glyph and HUD-bar size contracts.

Its framebuffer UV rectangle comes separately from
`renderer_get_pixel_viewport_fixed4`; changing destination geometry does not
change that source rectangle. The second packet branch first draws into
texture-sized intermediate coordinates, installs context-2 SCISSOR register
`0x41` from the texture dimensions, then submits the final sampled quad through
the shared 2D matrix. Intermediate clipping and final list clipping have
different owners.

Other framebuffer producers bypass the shared 2D matrix:

| Owner | Source and destination coordinates |
| --- | --- |
| `sampling_texture_capture` (`0x0019DCD0`) | Source is the display-sized framebuffer; destination width/height halve independently to fit the texture. The display-width gate and texture scissor are owned by [Sampling texture resource consumer](texture_material_runtime.md#sampling-texture-resource-consumer). |
| `image_transfer_copy` (`0x00109430`) | Caller rectangle supplies source UVs; destination and context-2 scissor use copy dimensions directly. Screen-break capture is later consumed by `stream_break_draw` (`0x003730C0`) as authored projected geometry. |
| `projection_controller_composite` (`0x0018BF90`) | Destination comes from renderer device bounds, while source UV dimensions come from the target. [Shadow rendering](shadow_rendering.md) owns the complete pass. |

## Bounded packet, cursor and callback classification

**Observed, high confidence within the named paths.** Packet attachment does
not choose coordinates: `render_packet_append` (`0x00109740`) only links DMA
tags. Its exposed resident callers are image copy, the two framebuffer-record
branches and the device alpha pass below; exposed BTL/ETC references add no
callers. Other producers inline those links. This is a bounded attachment
query, not a census of raw GS writers.

| Screen/object path | Established coordinate owner |
| --- | --- |
| Panel border and completion prompts | `panel_draw_border` (`0x00381510`) uses tiled or scaled/rotated atlas geometry through `panel_sprite_rectangle_scaled_rotated_draw` (`0x00380A50`) and `scene_output_finalize`. `panel_completion_prompt_draw` (`0x00381720`) prompt kinds 1/2 also use that sprite consumer. Border/interior geometry and prompt nodes use shared 2D. |
| Character Select cells and arrows | `character_selector_draw_support_cells` (`0x003B84D0`) retains the shared-2D portrait, unavailable and selected-marker routes. `character_selector_draw_arrows` (`0x003B9160`) positions atlas arrows at queried panel edges; horizontal UV mirroring does not bypass the shared matrix. |
| Mode Select button footer | `mode_select_present` (`0x00385C00`) calls `button_icon_submit` at logical `(400,362)` and `(470,362)`, separately from its authored scene. The atlas footer uses shared 2D. |
| Default inline font icons | `font_inline_icon_resources_initialize` (`0x00378120`) installs `font_inline_icon_draw_dispatch` (`0x00377E70`) in the font state's kind-4 callback. The eight accepted indices in `font_inline_icon_draw_branches` (`0x005D4640`) converge on atlas geometry and `scene_output_finalize`. The installed callback is shared 2D; this does not classify arbitrary replacement callbacks. |
| Save/Load slot cursor | `save_ui_initialize` (`0x001E57B0`) resolves `ANM_xkun1a` and `MDL_xkun1` from `gauge.ccs`. `save_ui_select_slot` (`0x001E69B0`) selects its own environment, updates the player camera and submits the authored player. This bounded cursor follows the model/device-projection route independently of slot text. |

The Save/Load cursor position is `(-163,192-row_y,0,1)`, with `row_y`
`42/109/176`, hence Y `150/83/16`. Its rotation vector is `(0,0,1.5,0)`;
`animation_player_set_transform` composes rotations and translation, without
a scale input. The controller's direct selection call is at `0x001E500C`,
and cursor submission at `0x001E6CA4`. [Save/Load ownership](../menu_input/README.md#saveload-controller)
owns navigation; [confirmation layouts](../../localization/font/screen_layouts/confirmations.md#message-boundaries)
owns the independently moving row text. No model artwork bounds are inferred
from the player anchor.

### Authored model and effect packet consumers

The [authored screen owners](#authored-scenes-and-mixed-owners) feed model and
effect children rather than the atlas consumer. `model_dispatch_geometry`
(`0x001910E0`) composes `device_projection * model_matrix`, and
`model_submit_packed_geometry` (`0x0018FFB0`) uploads the prepared matrix to
its selected model VU program. The depth-offset branch instead composes a
modified `projection_only`, `camera_transform` and model matrix. Neither is a
shared-2D destination path; [model composition](renderer_coordinates.md#model-to-device-composition-and-draw-scratch)
owns those matrices.

`particle_sprite_submit` (`0x00195A90`) builds local scale/rotation, applies
`inverse_camera_rotation`, replaces translation with the effect position,
then composes `device_projection`. Its offset branch uses the separate
projection-only/camera composition. The packet uploads that composed matrix
to VU data slots `0..3`. `particle_sprite_vu_entry_31f` (embedded EE bytes at
`0x003CEB30`, VU entry `0x31F`) consumes all four columns, divides XYZ by
homogeneous W and converts to fixed4 before emitting the planar quad. It does
not fetch another renderer matrix. Its projected XY sign checks against
`0/4095` can suppress the kick; boundary arithmetic is not established here.
The [shared upload boundary](model_vu_programs.md#initial-upload-boundaries)
owns installation. MCP exposes these embedded instructions as bytes rather
than EE functions; their decoding is recorded in the annotation.

`effect_position_history_draw` (`0x0039D8D0`) and
`effect_fifteen_records_draw` (`0x003A72B0`) also reach that particle route.
Their local position records alone do not establish a bounded UI owner.
World trails and framebuffer transfer quads are not classified as UI by their
packet or rectangle shape.

### Computed streamed callbacks and raw rectangles

`ccfm_callback_member_templates` (`0x005ACDF0`) supplies the callback owner's
six member descriptors. Preparation selectors 0/1/2 choose a no-op,
`ccfm_rectangle_pairs_prepare` or `ccfm_radial_mesh_prepare`; the corresponding
draw group chooses a no-op, `colored_six_rectangle_pairs_draw` or
`colored_radial_mesh_draw`. `ccfm_owner_draw` (`0x003701E0`) and the nested
transformed owner select that draw group with their byte selector. Thus these
computed calls reach the already classified shared-2D meshes. This establishes
the installed descriptor family, not every authored callback in NA2.

Other packets in those owners have separate contracts:

| Packet owner | Coordinate and clipping contract |
| --- | --- |
| `render_context2_textured_rectangle` (`0x0018E9F0`) | Raw destination from centered display bounds to those bounds plus display width/height in fixed4; UV extent derives from descriptor/depth and renderer device spans. Installs renderer-owned context-2 scissor. The exposed callers are ordinary/packed model dispatch, not a bounded atlas UI owner. |
| `draw_environment_device_alpha_pass` (`0x0010BD20`) | Uses `renderer_get_device_rectangle_fixed4` and raw GS corners, bypassing shared 2D. Reached by `sp_skill_play_frame` and `battle_device_alpha_pass_callback`; it covers the selected viewport. |
| `stream_color_rectangle_submit` (`0x001C9E50`) | Multiplies record X/Y endpoints by shared-2D diagonal scales, then adds raw display centering. Omits matrix translation, pivot and cross terms. Optional framebuffer strips use those endpoints through `stream_color_sample_strips`. The two inspected producers supply full-frame filtering, as established by [source geometry](#streamed-color-source-geometry). |
| `ccfm_sampling_pass_submit` (`0x001C8B40`) | CCFM auxiliary owner supplies four packed integer source/destination rectangles to sampling passes. Optional final depth reads projection-only Z/W coefficients; destination geometry bypasses shared 2D. This is framebuffer sampling, with its own transfer state. |

### Remaining bounded sprite attachments

**Observed, high confidence within the named paths.** Encoded JAL searches of
the three maintained NA2 programs identify two BTL calls to
`sprite_extended_rectangle_scaled_rotated_draw` (`0x001EB790`), six to
`indexed_directional_sprite_draw` (`0x0037E530`) and five to
`sprite_scrollbar_draw` (`0x0037FCE0`). Resident and ETC searches add no direct
sites; literal entry-pointer searches add no attachments. These bounds do not
exclude split-address, computed, interior-entry or inline consumers.

| Sprite attachment | Logical geometry and drawing-environment owner |
| --- | --- |
| EndDemo victory names | `pause_end_demo_effect_update` (`0x0076DCF0`) draws the two records at controller `+0x3C8/+0x3E0` through the embedded sprite `+0x2D0`, anchored at `(256,275)`. `rng_case5_state_update` (`0x0076CC00`) explicitly binds that sprite to controller context `+0x408`; `end_demo_controller_construct` (`0x0076BFF0`) creates its owned renderer. Flags `0x300` gate the batch; each repeated pair retains the controller's uniform scale and wrapped rotation, while its draw key decreases by `0.02`. Authored player submission has a separate binding. |
| Ultimate Battle course-list arrows | `ultimate_battle_course_list_draw` (`0x006E1460`) reaches `btl_window_vertical_arrows_draw` (`0x006E1940`) on its scrollable course-name list. State 2 draws upper/lower arrows at supplied anchors `(370,50)` / `(370,245)`, scale 1, directions 2/3. `ultimate_battle_construct_rank_resources` (`0x006DFFC0`) binds both arrow owners to its owned context `+0x44`. |
| Survival time-ranking arrows | `survival_time_ranking_draw` (`0x006E95F0`) draws left/right arrows at supplied anchors `(20,192)` / `(460,192)`, scale 1, directions 0/1, while byte `+0x24` is zero. `survival_time_ranking_resources_construct` (`0x006E9200`) binds both to a separate owned context `+0x3C`; selecting the parent panel environment does not replace that binding. |
| Ninja Song detail arrows | `endpoint_counter_player_draw` (`0x00718320`) state 3 draws upper/lower arrows at supplied anchors `(72,80)` / `(72,350)`, scale 1.5, omitting the arrow at each reached scroll endpoint. `endpoint_counter_player_construct` (`0x00717DA0`) gives the arrow owner its own context through `indexed_sprite_owner_bind`, separately from the animation, objective and footer contexts. Footer camera refresh does not refresh that arrow renderer. |

`indexed_sprite_owner_bind` (`0x0037E280`) borrows a supplied environment or,
for a null argument, constructs an owned renderer with list selector `0x80`.
Its installed mode-1 branch, `sprite_batch_mode_1_setup` (`0x001CBE78`), sets
sprite flags `0xB`, including the enabled local-rotation bit. The directional
helper's pulse changes the supplied anchor before the indexed sprite's local
rotation/centering; direction 2 also temporarily flips V. These local changes
retain the shared-2D consumer and the sprite's stored context. They publish no
private viewport or scissor.

Scrollbar rectangle ownership is separate from thumb state. For supplied
rectangle `(x,y,w,h)`, `sprite_scrollbar_draw` builds three backing segments,
then uses `q=(h-4)/total` for thumb origin `(x+2,y+2+q*start)` and extent
`(w-4,q*visible)`. `sprite_scrollbar_set_rectangle` (`0x0037FCC0`) stores the
four logical floats; `sprite_scrollbar_bind_context` (`0x0037FCB0`) changes
only the existing sprite's environment.

| Scrollbar attachment | Geometry/scroll source | Stored environment |
| --- | --- | --- |
| Condition information window; `btl_window_rows_draw` (`0x006E2D70`) | Parent text renderer `+0x74` supplies viewport `(x,y,w,h)`: rectangle `(max(x,x+w-17),y+2,min(w-x,16),h-4)`. Start is the current row; total is linked-list count minus 4; visible is 1. Five rows are displayed. | `btl_terms_info_construct` (`0x006E2280`) binds the parent panel's backing environment `+0x6C`. |
| Condition template window; `btl_terms_template_draw` (`0x006E3DB0`) | Same viewport-derived rectangle; start is the current row, total 3, visible 1. Five visible rows come from seven template records. | `btl_terms_template_construct` (`0x006E35F0`) binds the panel backing environment `+0x6C`. |
| Survival win opponents; `survival_win_opponent_list_draw` (`0x006EB230`) | Panel origin plus `(238,60)`, extent `(14,246)`; present when wins exceed 7. Start is scroll, total is wins minus 6, visible is 1. | `survival_win_opponent_list_construct` (`0x006EABE0`) binds the result panel's backing environment, separately from its row-text crop. |
| Command List; `command_list_draw` (`0x00878860`) | Fixed `(460,50,14,304)`; start is scroll, total is row count, visible is 1. | Constructor copies command-menu layer 2's host context. |
| Command Chart; `move_chart_draw` (`0x0087A740`) | Fixed `(413,50,14,304)`, present when row count exceeds 3; start is scroll, total is row count, visible is 1. | Initializer copies command-menu layer 2's host context. |

The condition windows' resident descriptors, `btl_terms_info_callbacks`
(`0x005DDCF0`) and `btl_terms_template_callbacks` (`0x005DDCD0`), install the
named constructors and draw callbacks. `battle_spbattle_ccs_acquire` creates
the children, `btl_terms_child_link` (`0x006E8250`) links them, and
`spbattle_linked_windows_draw` (`0x006E8070`) invokes descriptor slot `+0x18`.
This closes their installed computed draw path; exact player-facing labels
and complete frontend reachability remain open. The command-menu layer-2
sprite binds to the owned host context `+0x40` in `start_menu_create_resources`
(`0x0087B7F0`).
[Start Menu ownership](../../gameplay/session/pause_and_replay.md#btl-start-menu-construction-and-ui-states)
owns its child/result routing.

None of these five draw callers publishes a scrollbar-specific viewport or
scissor. A rectangle derived from the text renderer can therefore submit on
the panel backing or host renderer instead. Moving the text crop does not
establish a matching change to that sprite's final matrix or list scissor.

`optional_circle_prompt_owner_initialize` (`0x003906B0`) instead creates one
environment borrowing `default_renderer`, selector `0xFF`, and leaves its
optional sprite context null. `text_panel_state_draw` (`0x00390A30`) selects
that environment and, while copied draw state `+0x10C == 1`, draws an opaque
black strip with endpoints `(0,120)..(512,230)`, text at `(100,135)` and
`optional_circle_prompt_draw` (`0x00390540`) at `(450,195)`. The two sprite
cells yield the same 18-by-18 destination; the font fallback binds the same
environment, although its extent is not established by the sprite table.
Neither branch introduces another renderer or private crop. The backing's
512-wide interval does not establish its intended screen coverage.

Exposed references and encoded direct-call/literal-pointer searches establish
no parent attachment for this Circle-panel initializer or draw. Its screen
identity remains open. These attachment findings close the named consumers
and installed callbacks, while universal indirect/inline, asset-frame and
all-screen coverage remain unproved.

### Streamed-color source geometry

The packet contract above is independent of these two proved producers.
`bg_color_rectangle_create` (`0x00399250`) creates `ccBgColorFilter`;
`bg_color_rectangle_parse` (`0x00398FD0`) initializes its record through
`stream_color_rectangle_initialize` (`0x001C9CA0`) to `(0,0,512,384)`.
Parsing changes nine RGB controls, while the class update is a no-op.
This producer supplies a full logical-frame color filter rather than bounded
texture artwork.

`sp_skill_play_begin` resolves `BIN_strfilter_<container-name>` and passes its
data to `ccfm_owner_load`. `ccfm_read_transformed_records` (`0x00370E10`)
copies authored `0x360` records; `ccfm_transformed_draw_owner_apply_record`
(`0x0036F420`) transfers their X/Y/width/height unchanged. In the original
383-file `STR` directory, 188 actual `0x2400` CCFM payloads were identified;
187 have empty transformed banks. The sole transformed record is
`BIN_strfilter_d93_10`, object `1183` in `STR/D93_10.CCS`: `(0,0,512,384)`,
group `7`, enabled, with no nested callback prefix. Its source compressed
SHA-256 is `db7bd41f7137742d31a6fa099e2ea4e6e987a85931a1e4b231f004808e9b6d6f`.
This closes the authored source extent in that retail STR cohort. Arbitrary
payloads or other indirect callers remain outside it; destination and sampling
ownership still follow the packet contract.

## Clipping and coordinate ownership

The viewport setter `abi_float_arguments_consume` (`0x0010E460`) sets
`RendererTransformState.packed_left/packed_right/packed_top/packed_bottom`
as inclusive scissor endpoints.

`ordered_controller_list_process` (`0x00109D50`) resolves ordered work
before prepending the normal list's scissor state packet.
`BattleHudRenderContext.special_processing == 0` uses the selected
renderer endpoints for GS register `0x40`; nonzero uses the empty
`ordered_controller_special_process_noop` (`0x00109D00`) and does not emit
the same packet. Ordering and lifetime belong to
[Render submission](render_submission.md#frame-chain-and-vif1-submission).

Caller geometry and local transforms therefore inherit the **selected
list's** scissor on the normal path. Replacing a pool context or selecting a
window context changes that viewport owner. A 512-by-448 mask or glyph beyond
a window does not establish visible coverage outside the selected viewport.

`render_begin_draw_packet` also copies `device_min/device_max` and
`clip_min/clip_max` into the primitive; `model_property_build_draw_workspace`
uses them when selecting vertex emission. `transition_packet_setup`
(`0x00184020`), immediate primitive setup and `sprite_packet_setup`
(`0x001CD5E0`) install no separate GS scissor. The sprite consumer's coarse
512-by-448 CPU rejection region is independent of this list-owned clipping.

`draw_environment_fill` (`0x00109A10`) uses
`renderer_get_device_rectangle_fixed4` endpoints to make a viewport-sized
fill, without installing GS register `0x40`. A zero-color call does not
establish a new clipping rectangle. Its device-coordinate fill bypasses the
shared 2D matrix and already spans the selected viewport. Matrix construction,
logical pivots and output-coordinate conversion belong to
[Renderer and coordinate systems](renderer_coordinates.md).
