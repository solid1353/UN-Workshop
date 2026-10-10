# Battle HUD

## Research coverage

Established: ordinary retail NA2 HUD ownership, ordering, visibility, meter/clock
presentation, root displays, transforms and cleanup. Open: original identities,
decorative artwork, helper-vector semantics, indirect writers and special-scene
variants. Names and routine detail come from `@annotations/NA2`.

This document describes unmodified retail NA2 (`SLPS-25837`). File identities
and address conventions belong to
[Retail game file identities](../../game/files/file_identities.md).
[Battle lifecycle](battle_lifecycle.md) owns allocation of the session and root
graph; [Battle item inventory](../projectiles_and_items/battle_item_inventory.md)
owns wheel storage; [Support mechanics](../characters/support_mechanics.md)
owns the support resource; [Combo accounting](../combat/combo_accounting.md)
owns combo publication; [Ultimate Jutsu](../characters/ultimate_jutsu.md)
owns its HUD-hiding presentation. Localized name layout belongs to
[Battle HUD character-name renderer](../../localization/ui/battle/character_names.md).

Evidence is static and bounded; incomplete overlay cross-references do not
establish absence. Annotation addresses are live runtime addresses.

## Battle-session ownership and order

`battle_create_graph` constructs the ordinary presentation after publishing
both fighters. The session owns the item manager with both lower item/support
panels, two `BattleTopPanel` objects, one `BattleHudClock`, and a separate
`BattlePresentationRoot`. Each top parent binds its side's fighter and
selected character ID. Top entrypoints are direct session calls, not virtual
fighter-registry callbacks.

After the three graph phase walks and auxiliary presentation,
`battle_dispatch_phases` services these owners:

| Order | Owner | Update/draw admission |
| --- | --- | --- |
| 1 | Item manager and lower panels | Each corresponding session mask has `0x100` |
| 2 | Side-0 top parent | Each corresponding mask has either `0x600` bit |
| 3 | Side-1 top parent | Same |
| 4 | Clock | Each corresponding mask has `0x200` |
| 5 | Root presentation forest | Each corresponding mask has `0x200` |

Each owner's update precedes its draw; side 0's pair precedes side 1's pair.
The item-manager consumer `item_pickup_list_destroy` additionally admits
lower-panel updates only when its own flags permit and
`fighter_coordinator_get_state` returns 0, 3 or 4. Its list work has separate
gates. Mask construction belongs to
[Pause and replay](pause_and_replay.md#controller-fields-and-mask-construction).

The final `query_process_active_pairs` follows HUD/root work. Thus the HUD
samples fighter state before that final overlap-query publication. This
ordering does not establish a universal elapsed time or same-update contact
result.

## Top-panel construction

`battle_top_panel_construct` and `hud_top_initialize` create a
`0x68`-byte parent. Constructor sides 1/2 become internal sides 0/1.
The primary and secondary render contexts are separate `0x40`-byte objects.

| Parent member | Ownership and binding |
| --- | --- |
| `primary_context` | ID `0x80`; borrows the resident renderer; shared by all four children |
| `secondary_context` | ID `0x83`; owns its allocated `0x2B0`-byte renderer; also borrowed by chakra feedback |
| `frame` | `0x1C`-byte child; decorative discs, frame and character-keyed cell |
| `name` | `0x0C`-byte child; character name |
| `hp` | `0x28`-byte child; current HP and damage trail |
| `chakra` | `0x6C`-byte `BtlGauge`; fill, reservation, thresholds and feedback |

Child construction order is frame, name, HP, chakra; update/draw order differs.
The parent starts at scale 1, with base positions `(6,10)` and `(506,10)`.
`hud_top_reset` sets resting offset `(0,-2)`, idle transition and visible
children, clears hide/show substates, and leaves shake initialization to its
request.

`ordered_controller_register` distinguishes borrowed and owned renderers;
`ordered_controller_destroy` frees only an owned renderer. Sprites own their
wrappers and borrow texture payloads. The resident renderer pointer
`default_renderer` is borrowed by the primary context.

## Child update and draw boundaries

`battle_side_service_reentry` visits non-null frame, HP, chakra and name,
then advances the parent transition. Child updates continue while parent
drawing is suppressed. `battle_side_update_reentry` skips every child only
when `child_draw_suppressed == 1`; otherwise it recomputes the effective
anchor from base plus offsets, visits the same children, and restores the
previous render context.

| Child | Update | Draw | Presentation contract |
| --- | --- | --- | --- |
| Frame | `hud_frame_disc_update` | `hud_frame_draw` | Fighter status changes disc speed; parent anchor, scale and side place the pieces |
| HP | `hud_hp_trail_update` | `hud_hp_draw` | Samples `Fighter.hp`; current/trailing values are child-owned; ratio and tint are draw-computed |
| Chakra | `gauge_update` | `hud_chakra_draw` | Samples chakra/reservation, advances feedback, then draws fill, feedback and icon |
| Name | `hud_name_update` | `hud_name_draw` | Character-keyed rectangle with one conditional key substitution |

Support belongs to the lower `ItemPanel.support_gauge`, outside this
four-child sequence. `item_panel_update` advances support after selected-item
and list work and before clearing panel event bytes. `hud_support_update`
samples before advancing its pulse. `item_support_gauge_draw` samples again
before checking visibility. An admitted update/draw pair therefore samples
support twice and advances its pulse once; masks can separate those operations.

### Frame and character-keyed cell

`BattleHudFrame` borrows its parent and owns two sprites.
`hud_frame_initialize` selects a cell through
`hud_frame_character_cells`: 94 keys, 1..93 followed by 0, with cell values
0..7. Unmatched keys select cell 8.

`hud_frame_cell_rectangles` contains nine rectangles: eight 30-by-30 cells
in the grid with U/V values 1, 33 and 65, and default `(17,17,30,30)`.
Selection does not identify the depicted symbol.

A bound fighter with `contact_flags & 0x20` selects speed target 8.0 and
step 0.4; otherwise target 1.0 and step 0.1. All three phases advance and wrap.
Draw submits the three discs first, mirrors X displacement and rotation for
side 1, then draws the frame/panel pieces and chosen cell.

### HP and name bindings

`BattleHudHp` borrows its parent and owns one sprite. Display maximum
starts at 1.0; current HP, trailing HP and delay are independent display state.
Initialization samples the trailing value and clears delay. Each admitted
update samples `Fighter.hp`; equality with the trail arms delay 100,
otherwise a positive delay decrements. At zero, the trail moves toward current
by 0.01 per update with a clamp. These operations do not write fighter health.

`hud_hp_draw` computes `ratio = current / maximum` and chooses:

| Ratio | Tint category |
| --- | ---: |
| Above 0.5 | 0 |
| Above 0.1 through 0.5 | 1 |
| At most 0.1 | 2 |

A separate trail segment exists only while trailing exceeds current, covers
their difference and uses RGB `(0x4A,0x04,0x09)`.

`hud_hp_geometry` returns the filled segment's endpoint, Y, width and height
using the draw-computed ratio and effective parent position.
`hud_top_hp_geometry` delegates when the child exists and otherwise returns
a zero vector. Calling geometry alone does not refresh HP or the ratio;
hidden drawing skips the ratio-producing call.

`BattleHudName` borrows its parent and owns one sprite.
`hud_name_set_rectangle` selects `hud_character_name_rectangles` by character
ID minus one; invalid indexes use the final record under
`hud_character_name_count` (96).
Only selected key `0x25` with a fighter can substitute `0x5E`: it requires
`major_state == 0 && substate == 3`. Leaving that condition restores
`0x25`. This bounded substitution is not generalized to every character.

### Chakra storage and display

`BtlGauge` owns three sprites, three `ANM_ef_gau02a/01a/00a` players
and a `0x50`-byte view helper; parent, fighter, container and secondary
context are borrowed. `gauge_container_setup` binds `battlegauge`,
`TEX_xgauge` and `TEX_xgauge3`. Its two helper vectors' original semantic
types remain unresolved.

`hud_chakra_reset` initializes current/previous samples from
`Fighter.chakra` and requested/displayed reservation from
`Fighter.staged_chakra`. Gameplay mutations belong to
[Chakra and guard](../combat/chakra_and_guard.md#fighter-and-action-record-fields).

`gauge_update` orders `hud_chakra_rate_update`,
`hud_chakra_reservation_update`, `gauge_players_update`, then the rotating
icon phase. The total, named `BtlGauge.threshold` in annotations, is current
plus requested reservation. It is upper-clamped to 15 by reducing the display
current only. Fighter chakra is not written.

| Display total | Category | Animation-rate target |
| --- | ---: | ---: |
| Nonpositive | 0 | 0.1 |
| Positive, below 5 | 1 | 0.4 |
| At least 5, below 10 | 2 | 0.8 |
| At least 10, below 15 | 3 | 1.2 |
| At least 15 | 4 | 1.8 |

Rate moves 10% toward the category target in `hud_chakra_rate_targets`;
`state_active` overrides the target to 3.0. Icon phase advances by rate/90
and subtracts 1 when above 1.

Displayed reservation rises by 0.5 per child update, clamped at the request;
a decrease copies immediately. Fill uses total minus displayed reservation for
the first segment and displayed reservation for the second, both divided by
15. Thus a fixed gameplay total can produce changing segment widths.
Positive displayed reservation changes its palette every two updates; zero
clears the blink. Three threshold markers follow the segments. Marker-cell
selection advances once per child update and wraps after 12 cells.

`btl_initialize_derived_float_constants` initializes the bar when BTL loads:
the 108-by-8 signed rectangle becomes float dimensions, three threshold X
positions are derived, and final threshold 15 becomes the bar maximum.
Those output fields start at zero before initialization. The constructor
interval belongs to [Overlay ABI](../../runtime/overlay_abi.md#constructor-interval).

Feedback scans `Fighter.actions` records 4..9 and takes the first nonzero
`ActionRecord.category` record's `cost`. A nonnegative cost no greater than
the display total admits threshold feedback. Separate state feedback requires
`major_state == 0 && substate == 4`. First/third feedback fade by 0.1 and
1/30 per update after their respective conditions cease. Animation progression,
active flags and fades remain local to the child. This consumer does not
establish whether an action will execute; the array contract belongs to
[Action commands](../combat/action_commands.md#working-action-arrays).

Draw orders fill/thresholds, optional feedback when `feedback_enabled`,
then the rotating icon. Feedback draws only active players in the secondary
context and restores the previous context. The icon clears rotation afterward;
the wrapper resets all three sprites.

## Support gauge

`BattleHudSupport` stores the side, bound fighter, visibility/category,
current/prior fill, three sprite wrappers and pulse scale/alpha.
`hud_support_sample` reads `Fighter.support_gauge`; resource production is
owned by Support mechanics. Sampling precedes the draw visibility gate.

`hud_support_draw` anchors the complete block at X 120/392 and
Y 340 plus the owning lower panel's `vertical_offset`, resolved through
`battle_active_object`, `world_side_object_get` and
`item_panel_vertical_offset`. Side 1 uses negative horizontal dimensions.
Foreground starts at relative X 20, spans `64 * fill`, and has its fixed
half-bar marker at relative X 52.

Draw order is frame cap, stretched texel column, flipped cap, full-width
neutral background, foreground, marker, button frame, glyph and icon.
Frame/glyph use relative Y +20 and icon Y -2. Category 1/2 repeats the icon
with pulse alpha and scale `1 + pulse_scale`, multiplied by 1.1 in category
2. The glyph uses the side's configured Linked Attack binding
(`bindings_get(side + 1)[5]`), resolved by `hud_glyph_get`,
`hud_glyph_texture_group`, `hud_glyph_texture_get`,
`sprite_glyph_initialize` and `hud_glyph_draw_rectangle`.
Its alpha is 0.8 in category 0.

The rectangles are `TEX_xgauge` texel units, V measured from the top:

| Annotation | Piece | U, V, width, height |
| --- | --- | --- |
| `hud_support_frame_rectangle` | Cap | 89, 108, 22, 20; stretched column U 111 |
| `hud_support_marker_rectangle` | Marker | 89, 89, 7, 18 |
| `hud_support_icon_rectangle` | Icon | 125, 101, 26, 26 |
| `hud_support_fill_rectangle` | Fill column | 4, 91, 0, 10 |
| `hud_support_button_rectangle` | Button frame | 21, 33, 36, 24 |

`TEX_xgauge` in `battlegauge.ccs` is a 256-by-128 PSMT8 texture with
bottom-up stored rows. The rectangle submission path supports X/Y flips,
without rotation. `sprite_draw_rectangle` and
`sprite_draw_scaled_rectangle` preserve RGB and alpha while setting source
geometry and submitting; the latter also scales dimensions and centering.

The marker uses neutral RGB `(0x80,0x80,0x80)` from `hud_neutral_tint`,
preserving its texture color. Only RGB is copied; alpha and Q remain intact.
Foreground tint is separate, with neutral background RGB
`(0x7F,0x7F,0x7F)` drawn first.

| Fill, while visibility state is 1 | Category | Foreground RGB |
| --- | ---: | --- |
| Below 0.5 | 0 | `(0x1E,0x64,0x78)` |
| At least 0.5, below 1.0 | 1 | `(0x7F,0x50,0x32)` |
| At least 1.0 | 2 | `(0x7F,0x78,0x32)` |

Visibility state 2 overrides with `(0x7F,0x00,0x00)`.
`hud_support_palette` contains these four packed rows; packing changes RGB
only. `hud_support_category` uses `support_half_gauge_eligible` for the
half threshold; the sampler separately compares fill against 1.0.

## Central battle-clock display

`battle_clock_construct` and `hud_clock_initialize` create the clock
owner, borrow `battlegauge/TEX_xgauge5`, sample `battle_clock_get`, and own
a context with ID `0x86` plus one sprite. The sprite borrows that context.
Each digit has its own value and scale, initially 0.8.

`battle_clock_update` skips digit sampling and change feedback for an
unlimited clock. Otherwise it refreshes integer/decimal digits. Zero sets
both scales to 1.1; below ten, scale increases by 0.015 up to 1.1. A changed
sample then overrides both scales to 0.8, increments the change counter,
and requests sound `0x102D` only for values 1..5. Previous sample is copied,
hide/show advances, then RGB becomes `(FF,52,02)` below ten or
`(FF,D2,05)` otherwise. Timer units and production belong to
[Shared timer primitives](../../runtime/timer_primitives.md).

`battle_clock_present` skips hidden state 1. Unlimited uses the eleventh
rectangle in `hud_clock_rectangles` (78-by-62); decimal digits use ten
38-by-62 rectangles. Leading zero is suppressed while at least one digit
draws. One digit centers at logical X 256; two at 271 and 241. Y is integer
conversion of offset plus 33. The sprite is reset afterward.

## Destruction and resource lifetime

`battle_destroy_graph` destroys the item manager, then side-0/side-1 top
parents, then clock, then root forest. The surrounding lifetime belongs to
[Battle lifecycle](battle_lifecycle.md#teardown-order).

Top cleanup deletes name, chakra, HP, frame in that order, clears their
pointers, then deletes secondary and primary contexts.
`hud_top_destroy` frees the parent only for a positive signed delete flag.
Frame releases two sprites; name and HP one each. Chakra releases three
sprites, three players and its view helper, clearing owned slots.
Borrowed parent, fighter, container, texture and context pointers are not
freed by those children.

Clock cleanup deletes its context then sprite, clears both and resets the
shared top-slide publication to -2. These construction/cleanup paths establish
no independently scheduled per-meter task.

## Visibility and shared transforms

`battle_hud_hide` and `battle_hud_show` select independent owners and
clear/set the session's corresponding visibility-intent bits. Intent is
separate from completed slide/visibility state.

| Mask bit | Owner | Request |
| ---: | --- | --- |
| 1 | Clock | `hud_clock_hide_request` / `hud_clock_show_request` |
| 2 | Side-0 top | Set its hide/show transition |
| 4 | Side-1 top | Set its hide/show transition |
| 8 | Side-0 lower | `lower_panel_hide` / `lower_panel_show` |
| `0x10` | Side-1 lower | Same lower request path |

Mask -1 selects all five. Mask -7 (`0xFFFFFFF9`) selects clock and both
lower panels, leaving the two top bits clear. Thus Ultimate-Jutsu staging
does not itself hide the two HP/name/chakra parents; its sequence belongs to
[Ultimate Jutsu](../characters/ultimate_jutsu.md#presentation-state-machine).

`hud_top_hide` starts velocity -5, adds it to Y offset and decreases it by
0.7 each update. Crossing -120 clamps there and enters terminal substate;
the next call suppresses child drawing and selects idle.
`hud_top_show` starts velocity 20, adds it to offset and increases it by
0.1 with minimum 10, clearing suppression while moving. It clamps at -2;
its terminal substate holds -2 while retaining show selection.
Visibility alone therefore does not prove return-slide completion.

Clock hide subtracts velocity starting at 5, increasing by 0.7; its terminal
state after crossing -120 sets hidden and idle. Clock show adds velocity
starting at 20, decreasing by 0.1 with minimum 10, clears hidden while moving
and clamps at -2 before selecting idle. Construction begins at offset zero
and visible, independently of top-parent reset.

Lower hiding is positional: hide changes state 0/3 to 1, show changes 1/2
to 3. `item_panel_animate_position` moves 30% of remaining distance toward
200 when hiding or zero when showing, snaps within one unit and ends at
state 2/0. Lower draw still executes with the shifted wheel origin; support
uses the same offset. Top and clock terminal hiding instead skip drawing.

### Top-panel shake and attachment consumers

`hud_top_shake_request` admits only levels 0..4 and selects shake with
sample duration 1:

| Level | Samples | Amplitude |
| ---: | ---: | ---: |
| 0 | 3 | 0.5 |
| 1 | 3 | 1 |
| 2 | 5 | 1.75 |
| 3 | 7 | 2.5 |
| 4 | 7 | 4 |

A different amplitude restarts shake; equal amplitude preserves an ongoing
shake. `hud_top_shake` initializes resting offsets and chooses the starting
row from eight `hud_top_shake_samples`. Each sample multiplies X/Y by
amplitude, adds resting Y -2, clamps base X plus offset to 0..512 and advances
the count. Termination restores `(0,-2)` and idle transition.

The bounded direct-call screen establishes `sp_skill_play_frame` as the
shake producer: it finds the opposing side's parent through
`battle_top_panel_get` and passes a hit-record signed level unless it is -1.
Indirect producers are not excluded.

`hud_top_anchor` computes fresh base plus offsets. The root-owned status
glyph's `hud_status_glyph_anchor` adds its signed-halfword attachment offset
to that anchor. Thus slide/shake moves the attachment even though it is outside
the parent's four children. This getter differs from the HP geometry getter.

Top update publishes its Y offset in `hud_shared_top_slide_y`; side 1 is
the last top writer in the side-order service pass. Clock cleanup resets it
to -2. It is a shared publication, not per-parent storage; other consumers
are not exhaustively assigned.

### Direct visibility request coverage

The bounded resident/BTL direct-call screen establishes whole-HUD hide/show
requests with -1 and the Ultimate-Jutsu staging hide with -7. Two other BTL
hide/show pairs have independent enclosing state gates; their class names and
full presentation semantics are not established by the request. The exact
call census is in the request routine annotations. Indirect/unindexed callers
remain open; mirrored resident instructions do not count as extra producers.

## Remaining ordinary presentation forest

`BattlePresentationRoot` is a separate session-owned forest. Its root
children are outside top-panel and item-manager ownership. Root construction,
paired arrays, phase gate and deletion belong to
[Battle lifecycle's root component forest](battle_lifecycle.md#root-component-forest).
Each child's active/fade gate remains separate from root admission.
The inspected constructors install no vtables, so these are functional
descriptions, not recovered class names.

| Root member | Presentation and bindings | First / second callback |
| --- | --- | --- |
| `combo` | `TEX_xcombo`, `ANM_xcombo_ht` | `hud_combo_digits_update` / `hud_combo_draw` |
| `prompts` | `TEX_xcommand`, `TEX_xcommand02` | `hud_prompt_update` / `hud_prompt_draw` |
| `command_strip` | `TEX_j_waku`, command glyphs, `TEX_xosubotan` | `hud_command_strip_update` / `hud_command_strip_draw` |
| `shared_icons` | `TEX_xicon_b`, `TEX_xicon`, `TEX_xmenu`, `ANM_xicon02` | `hud_icon_player_update` / `hud_shared_icons_draw` |
| `gameplay_icons` | Per-side parent with 26 owned glyph slots | `hud_gameplay_icons_update` / `hud_gameplay_icons_draw` |
| `history` | Per-side linked numeric popups/history with `TEX_xcombo` | `hud_numeric_history_update` / `practice_damage_draw` |
| `world_markers` | Projected fighter position; borrowed shared textures | `battle_camera_state_consumer` / `hud_world_marker_draw` |
| `notice` | `TEX_xsuccess`, `TEX_xfails` | `battle_notice_update` / `battle_notice_draw` |

The command strip reads at most five sequence bytes, stopping at sentinel
`0x1E`, and sends them to the command glyph renderer.
The icon parent checks gameplay-node IDs 0..`0x89` through
`fighter_has_effect`, assigns present/not-yet-displayed IDs to glyph slots,
and excludes `0x79/0x7A`. Draw traverses children in reverse order.
This membership display does not establish another gameplay update; node
effects belong to
[Battle items and status effects](../projectiles_and_items/battle_items_and_status_effects.md#per-fighter-storage).

The marker projects `Fighter.position` through `fighter_position_project`.
Draw uses descriptor groups 117..119 and 120..122 with screen-edge clamps
and borrowed shared textures. Numeric history maintains a linked popup list
and saturated aggregate/peak pair and draws admitted active entries;
its triggering gameplay meanings are not established here.
Shared icons own five sprite wrappers, an animation and two render layers.

### Combo digit presentation

Each side's `BattleRootCombo` is a `0x44`-byte element.
[Combo accounting](../combat/combo_accounting.md#separate-presentation-count)
owns `btl_counter_arm_stopped_player` and `hud_combo_reset_running`,
which publish the running/latched result, active flag and shake countdown.
`battle_combo_display_get` uses the resident `battle_session` pointer to
return the side element, or zero when the session/root is absent.

Update is skipped while suppressed or inactive. Eligible calls:

| State | Operation |
| --- | --- |
| Hold | Increment hold count until 30; later calls fade opacity by 0.05 and clear active at nonpositive opacity |
| Appearance overlay | While active on entry, add opacity 0.1 until at least 0.4, then clear its flag; add extra scale 0.15 |
| Hit animation | Advance while enabled; clear flag only when complete and main opacity is nonpositive |
| Shake | Ten-call countdown after publication; while positive decrement and obtain two signed offsets, magnitude `min(running_count * 0.65, 7)`; otherwise clear offsets |

These are eligible update calls, not seconds. Fade does not inspect the native
combo count or its 90-unit window; it can run while the live combo persists.
Inactive updates skip animation work too.

Draw requires active and uses the latched count. It never selects style row 0:

| Latched count | Row | Packed color word | Digit scale |
| --- | ---: | --- | ---: |
| Below 5 | 1 | `0xFF00A0A0` | 1.0 |
| 5..9 | 2 | `0xFF00A0A0` | 1.0 |
| 10..19 | 3 | `0xFF0060A0` | 1.1 |
| 20..29 | 4 | `0xFF0040A0` | 1.2 |
| At least 30 | 5 | `0xFF0000A0` | 1.3 |

`hud_combo_styles` names the base and `hud_combo_selected_styles` the
five selected rows. No unverified color-channel convention is assigned to
those numeric words. `hud_combo_render_digits` uses 32-by-40 atlas cells,
spacing `24 * scale`, and at most three digits from the clamped publication.
Base position is `(96,140)` or `(386,140)` plus shake. Draw orders main
digits, optional appearance overlay with extra scale, then hit animation.
Resetting only the running count leaves the latched display intact.

### Prompt placement and activation interfaces

The two `0x580`-byte `BattlePromptDisplay` objects separate side, active
state, placement selector, label, command bytes, opacity and ramp state.

| Placement | Behavior |
| ---: | --- |
| 0 | Stored side coordinates `(100,160)` / `(412,160)` |
| 1 | Fighter position plus `entity_scaled_height`, projected by `world_position_project`; Y minus 70, X clamped 70..442 |
| 2 | `(256,260)` for both sides |
| 3 | `(100,260)` / `(412,260)` chosen by relative fighter X ordering; ordinary-path scale forced to 0.6 |

`hud_prompt_set_placement` stores the mode and coordinates from
`hud_prompt_placements`. Modes 0/2 use the object's side; mode 3 chooses
a placement side from the fighters' relative X positions. Mode 1's stored
zeros are replaced by draw-time projection. The modes do not establish
original gameplay names or every caller's reachability.

`hud_prompt_activate` at live `0x006B5D20` activates only when
`battle_simple_display_get` succeeds or force is nonzero. It sets duration,
active, opacity 1, ordinary path, placement and force.
`hud_prompt_activate_ramp` uses the manager gate for activation, while a
positive ramp independently clears ordinary path, zeroes fraction/count and
sets denominator. Those ramp writes and final placement occur outside the
activation gate, so calling the helper does not prove activation.

Eligible update advances the ramp once and changes to ordinary path when count
reaches denominator. During ramp, draw submits two horizontally displaced
copies at `±70 * (1 - fraction)`, each with opacity
`opacity * fraction * 0.5`. Ordinary positive duration decrements; zero
duration fades by 0.15 until inactive; negative duration does not decrement.
`hud_prompt_hide` sets duration zero and may clear active immediately,
depending on its argument and ordinary-path state.

Suppressed value 1 or inactive state skips both callbacks. Unforced prompts
also retain manager/fighter gates. All counts are eligible invocations,
not measured durations. Full label/glyph gameplay identity remains unresolved.

Player-marker rectangles/labels belong to
[Battle UI selectors and prompts](../../localization/ui/battle/selectors_and_prompts.md#player-markers);
item/status label composition belongs to
[Battle item/status presentation](../../localization/ui/battle/item_status.md).
These display values are not additional gameplay resource state.

## Confidence and remaining limits

Ownership, direct ordering, reads/stores, atlas bounds and selector branches
are established by static code/data. Functional names describe consumers and
textures; they are not original class identities. Rates count admitted native
callbacks and do not imply wall-clock durations.

Decorative-cell artwork, chakra helper-vector semantics, indirect scalar/enable
writers, complete prompt subtype identities and sharing with cut-in/special-scene
HUD variants remain open.
