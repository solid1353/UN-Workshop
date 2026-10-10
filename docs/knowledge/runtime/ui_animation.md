# UI animation and easing

## Research coverage

Established: scalar approach, RGBA transitions, panel opening/closing,
squash/stretch, delayed scrolling and Character Select easing/pulses, including
their ordering, gates and ownership. Open: pool-gate writer, intermediate-phase
arming, selector easing consumer, Collection counter initialization and unscreened
callers. Names come from `@annotations/NA2`; addresses are live.
Static evidence establishes call counts, not wall-clock duration or calls per frame.

This document covers presentation-value animation in retail NA2
(`SLPS-25837`). [Mode flow](../game/mode_flow.md) owns screen state machines;
[Character Select](../game/character_select.md) owns selector navigation;
[Animation runtime](animation_runtime.md) owns resource playback;
[Timer primitives](timer_primitives.md) owns general timers; and
[Battle HUD](../gameplay/session/battle_hud.md) owns HUD-specific gauges and
clock effects. Screen layout and localization remain with their own documents.
Binary identities follow
[Retail game file identities](../game/files/file_identities.md#address-conventions).

The inspected helper bodies establish arithmetic and local order. Constructors,
reset/rearm operations and representative Mode Select, Options, Character Select
and Collection owners establish the contracts below. Caller sampling is not an
exhaustive UI inventory; incomplete import analysis can miss indirect dispatch
and pointer aliases. Per-routine details and bounded call/encoding searches are
retained in annotation comments.

## Fixed-step scalar approach

`ui_scalar_approach` (`0x00387400`) receives a target, step and caller-owned
float. With a positive step, it subtracts above the target, adds below it, and
clamps overshoot; equality leaves the value unchanged. It does not validate the
step or supply timing, completion, reset, allocation or a pause gate. Its units
are value units per invocation.

`mode_select_update` approaches `ModeSelectInput.carousel_displacement` to
zero by `0.1` in the common tail. The terminal-state return skips that tail.
After the approach, the selected menu resource advances only when the absolute
displacement is at most `0.01`; other entries use another resource operation.
The neighborhood gate and the helper's exact endpoint clamp are distinct.
Selection and resource playback remain with their owning documents.

### Options weights and arrow phase

`options_audio_update` approaches `OptionsAudioPresentation.choice_weights`
and `row_weights` by `0.3` per common-tail invocation:

| Values | Target 1 | Target 0 |
| --- | --- | --- |
| Choice weights | Selected choice while selected row is 1 | Every other choice/row combination |
| Row weights | Selected row | Other row |

`options_audio_initialize` sets all four weights to zero. There is no completion
latch; `ui_scalar_approach` supplies endpoint clamps. Accept/cancel returns skip
the common tail.

The same tail adds `0.05` to `arrow_phase` and subtracts 1 only when the new
phase is greater than 1. `options_audio_reset` sets it to zero. The draw consumers
read phase without advancing it:

| Consumer | Weight mapping | Arrow displacement |
| --- | --- | --- |
| `options_audio_draw_choices` | Vertical `(1-choice_weight)*10` | Selected choice: `3*sin(pi*phase)` |
| `options_audio_draw_volume` | — | Mirrored arrows: `50 + 3*sin(pi*phase)` |
| `options_audio_present` | Horizontal `(1-row_weight)*20` | Vertical pair: `40 + 6*sin(pi*phase)` |

## Four-slot RGBA transition pool

`font_services_initialize` allocates two `0x98`-byte `UiTransitionPool` objects
and constructs them with `transition_pool_initialize`. Their resident global
pointers are `primary_transition_pool` and `global_transition_pool` (the
primary and secondary pool). `transition_present` assigns the current context
to the primary pool and `transition_alternate_render_context` to the secondary,
then calls `rgba_transition_pool_draw` (`0x00183650`) on each.

Each pool embeds four `0x24`-byte `UiTransitionSlot` objects; clearing a slot
does not release the pool. The constructor clears `gate`, every slot's
`flags`, and `render_context`, and establishes a shared default context.
`transition_pool_destroy` releases a non-null pool only when its signed-halfword
destroy argument is positive, through `heap_free` and
`heap_free_synchronized` (`0x00117C40`). There is no separate per-slot allocation.

| Slot field | Established contract |
| --- | --- |
| `flags` | Active mask `0x01`; completion masks `0x02`, `0x04`, `0x08` |
| `cursor`, `duration` | Signed-halfword phase progress and duration |
| `second_duration` | Reverse-phase duration supplied by `transition_opacity_in_start` |
| `intermediate_duration` | Duration consumed by mask `0x08`; arming producer unresolved |
| `x`, `y`, `width`, `height` | Float rectangle |
| `start_color`, `end_color` | Packed words whose four bytes interpolate separately |

A nonzero pool `gate` stops both drawing and advancement.
`render_context == 0` selects the shared default. Active slots are visited in
ascending index order. Coordinate conversion and packet ownership belong to
[2D draw ownership](rendering/draw_2d_owners.md).

`engine_root_finish_update` invokes `transition_present` outside its local
`(frame_gate & 7) == 0` scene-draw checks. This establishes local scheduling
order, without establishing a universal pause exemption: the pool gate still
applies. The constructor and reset do not identify its writer.
[Task system](task_system.md) owns scheduling.

### Arming, completion, and reuse

Allocators search indices `0..3` for flags exactly zero, returning `-1` if
full. They write the rectangle and start cursor zero.

| Routine | Initial flags | Color and phase contract |
| --- | --- | --- |
| `transition_opacity_out_start` | 3 | Supplied color → its low 24 bits, making the high byte zero; clears after the phase |
| `transition_opacity_in_start` | 5 | Supplied color with high byte zero → supplied color; stores two durations, rearms reverse phase on completion, then clears |
| `transition_start` | 1 | Explicit colors and duration; holds endpoint and remains occupied |
| `transition_slot_rearm` | 1 | Existing index, cursor zero, supplied duration, old stored endpoint → supplied color; preserves rectangle |
| `transition_pool_clear` | 0 | Clears all four flags only |
| `transition_slot_clear` | 0 | Clears one supplied index's flags only |
| `settings_resource_pending` | Unchanged | Returns signed `cursor < duration`, without activity or index validation |

Clearing flags retains cursors and colors, and does not clear pool gate/context.
Rearming starts from the old **stored endpoint**, not the current interpolated
color. A held complete transition therefore still occupies an allocator slot.

`transition_fullscreen_hold`, `transition_fullscreen_reverse` and
`transition_fullscreen_forward` clear the secondary pool before allocating a
held rectangle `(0,0,512,384)`. They read two-word color records from
`transition_fullscreen_colors` (`0x005C0950`, original `DAT_005c0950`).
Hold uses duration 1 and identical word-1 endpoints; reverse uses word 1 → word 0;
forward uses word 0 → word 1, both with caller-supplied duration. These owners
choose reset and presentation direction.

### Draw-before-advance order

For each active slot, `rgba_transition_pool_draw` samples the old cursor:

`byte = (start + trunc((end-start)*cursor/duration)) & 255`

Division uses `signed_integer_divide`. There is no zero-duration guard.
Only after packet values are written does the cursor advance by one and its
signed-halfword result compare with duration. Advancement still executes when
packet storage is unavailable. This pool counts eligible **draw-function
invocations**, including unsuccessful submissions.

Completion chooses the first matching behavior:

1. Mask `0x02`: clear flags, freeing the slot.
2. Mask `0x04`: replace it with `0x02`, reset cursor, load `second_duration`,
   copy endpoint to start and clear the endpoint's high byte.
3. Mask `0x08`: replace it with `0x04`, reset cursor, load
   `intermediate_duration` and copy endpoint to start without changing endpoint.
4. Otherwise clamp cursor to duration and keep the active flag.

For positive duration `D` without signed-halfword overflow, a held phase
samples cursors `0..D-1`, completes after invocation `D`, and first samples
the exact endpoint on the next eligible call. Clearing or switching phases acts
after sampling `D-1`, without an extra endpoint sample for that phase.
Mask `0x08` supports an intermediate constant-color phase, but its arming
owner remains unresolved.

## Shared panel open/close controller

`panel_initialize` constructs the reusable `0x80`-byte `UiPanel`.
`panel_set_rectangle` sets the style and rectangle and saves resting copies;
`panel_set_rectangle_record` accepts a `UiPanelRectangleRecord` containing
five signed halfwords `(style,x,y,width,height)`. Recovered opening owners
include Mode Select, Options, Save/Load, Character Select and other resident
dialogs; their navigation and text belong elsewhere.

| Panel fields | Animation contract |
| --- | --- |
| `style`, `x`, `y`, `width`, `height` | Current style and float rectangle |
| `resting_style`, `resting_x`, `resting_y`, `resting_width`, `resting_height` | Saved resting values |
| `state` | Signed halfword: 0 open/resting, 1 opening, 2 closing, 3 closed |
| `cursor`, `duration` | Signed-halfword reverse cursor and duration |
| `fraction` | Float transition fraction consumed by rendering |
| `text_enabled`, `hide_transition_text` | Text gate and transition hiding policy |
| `opening_sound_enabled` | Opening sound gate |

`panel_open(panel,D)` and `menu_transition_close(panel,D)` arm state 1/2
with `cursor = duration = D`. `panel_force_open` restores resting
style/rectangle, state 0, fraction 1, cursor 0 and text enabled.
`panel_force_closed` forces state 3 with zero current rectangle/fraction and
cursor 0, preserving resting geometry. `menu_transition_ready`,
`menu_transition_closed` and `panel_is_resting` test open, closed and either
resting endpoint respectively.

`panel_draw` calls `panel_transition_advance` (`0x00381AB0`) before drawing.
The transition returns immediately outside states 1/2. For resting rectangle
`(X,Y,W,H)`, cursor `q` and positive duration `D`:

| Value | Opening | Closing |
| --- | --- | --- |
| x | `X + (W/2 - 32)*q/D - D` | `X + (W/2 - 32)*(D-q)/D` |
| y | `Y + (H/2 - 32)*q/D - D` | `Y + (H/2 - 32)*(D-q)/D` |
| width | `64 + (W-64)*(D-q)/D + 2*D` | `64 + (W-64)*q/D` |
| height | `64 + (H-64)*(D-q)/D + 2*D` | `64 + (H-64)*q/D` |
| fraction | `(D-q)/D` | `q/D` |

Duration participates in opening geometry as well as timing. Arithmetic samples
the old cursor **before** testing negativity. Nonnegative `q` decrements by
one; a call beginning with `q < 0` overwrites its provisional arithmetic with
the resting endpoint. Positive `D` therefore needs `D+2` invocations:
`D+1` samples at `D..0`, then endpoint commit at `-1`. There is no
elapsed-time input or positive-duration guard.

When enabled, opening sound occurs on the first sample `q == D`.
The hiding policy can clear `text_enabled`; `panel_draw_text_positioned`
and `panel_draw_text_row` honor that gate.
`panel_draw_border` and `panel_draw_background` remain eligible while
state is below 3. Suppressing `panel_draw` stops the cursor; hiding text
does not. No independent pause flag is established.
`panel_destroy` releases text, child render objects and attached content;
transition scalars live in the panel.

## Counter-driven squash/stretch pulse

`ui_counter_pulse` (`0x0037E7C0`) fills `UiPulseSample`
`(110,36,sx,sy)` and mutates a caller-owned signed-halfword counter.
It increments **before** sampling. For incremented value `t`:

| Counter range | Horizontal scale | Vertical scale |
| --- | --- | --- |
| `t < 10` | `1 - 0.05*t` | `1 + 0.03*t` |
| `10 <= t < 15` | `0.5 + 0.1*(t-10)` | `1.3 - 0.06*(t-10)` |
| `15 <= t < 20`, odd | 0.95 | 1.05 |
| `15 <= t < 20`, even | 1.05 | 0.95 |
| `t >= 20` | 1 | 1 |

At `t >= 101` it resets the counter to zero while emitting the resting
sample. Zero initialization gives a 101-invocation cycle. There is no completion
return, independent pause flag, or guard against negative initialization or
signed-halfword overflow.

The three recovered wrappers each sample once and center the scaled sprite.
`ui_pulse_sprite_draw` applies translation and uniform scale;
`ui_pulse_sprite_draw_rotated` also swaps scale axes, draws at `pi/2`
and resets angle zero; `ui_pulse_sprite_draw_axes` accepts independent
translation and axis scales. Sharing a counter across wrapper calls advances
it more than once; drawing can mutate presentation state.

`mode_select_present` uses `ModeSelectInput.pulse_counter`, initialized
zero by `mode_select_initialize_fields`; terminal state 6 skips the draw
and increment. Collection `collection_update` in `ETC.BIN`
(live `0x006C8290`) also calls the resident wrapper with its GP-owned counter,
except in states 6 and 9. Its counter initialization remains untraced.

`options_audio_present` uses `OptionsAudioPresentation.pulse_counter`.
`options_audio_reset` clears it independently from `arrow_phase`.
This owner has a draw-driven pulse clock and an update-driven sine clock.

## Delayed scrolling strip

`scrolling_strip_initialize` constructs a reusable `UiScrollingStrip`;
`scrolling_strip_configure` applies a `0x24`-byte `UiScrollConfiguration`,
and `scrolling_strip_select_configuration` indexes
`scrolling_strip_configurations` (`0x005B16E0`). All four inspected
adjacent records provide speed `2.0`.
`scrolling_strip_advance` (`0x0037F7F0`) advances without drawing;
`scrolling_strip_draw` draws without advancing.

| Strip fields | Contract |
| --- | --- |
| `viewport_width`, `viewport_height` | Extents |
| `vertical` | Zero selects horizontal, nonzero vertical |
| `head` | Linked `0x10`-byte `UiScrollSegment` queue |
| `distance`, `speed` | Scroll distance and increment per eligible update |
| `delay`, `elapsed_delay` | Signed-halfword delay counters |
| `enqueue_inhibited` | Enqueue gate |
| `minimum_first_extent` | First-segment minimum policy |

Each segment has `owns_string`, `string`, `extent` and `next`.
`scrolling_strip_enqueue` admits a segment only when existing extents sum to
at most distance and inhibition is zero. Copied strings belong to their
segments; borrowed strings do not. For the first segment with nonzero delay,
distance becomes `0.9*viewport_extent` and elapsed delay resets zero.
The minimum policy can enlarge its extent to `distance + 20`.

An empty queue resets distance and elapsed delay. Otherwise, while
`elapsed_delay < delay`, the updater increments elapsed once and returns.
Movement first follows those delay invocations. Eligible movement adds speed;
on reaching `head.extent + viewport_extent`, it subtracts the head extent
and releases **one** head, even if a large speed has expired several.
Drawing places cumulative segments at
`viewport_extent - distance + accumulated_extent` on the selected axis.

`scrolling_strip_clear` frees the entire queue and owned copies and resets
distance/elapsed delay. `scrolling_strip_destroy` destroys child render objects
and clears the queue. These are invocation-based units, without establishing
one update per presented frame.

Mode Select's common tail enqueues before advancing; the inspected Options
subcontroller advances before enqueuing. Options construction selects record 3,
delay 30 and the minimum-first-extent policy, so that owner waits 30 eligible
updater calls. Inhibition does not pause updates: the updater does not inspect
it. Suppressing the update call is the only established local pause mechanism.

## Character Select presentation values

`character_select_poll` invokes `character_selector_advance` for both
player objects unless its terminal-state return skips the updates. Each
selector first dispatches its presentation-state callback, then advances
resource animations, then runs the scalar/pulse tail.
[Animation runtime](animation_runtime.md) owns playback.

`character_selector_update_source` (`0x005B4328`) supplies member descriptors
to `character_selector_update_dispatch` (`0x005D66B0`) during static
initialization. The source/runtime strides are 16/12 bytes; the first 14 inspected
records have adjustment 0, dispatch -1 and a direct entry. The annotated tables
contain 15 records; the following presentation coverage covers states 0..13.
`character_selector_update_table_initialize` names the verified initialization
code, and `member_descriptor_dispatch` consumes the records. The initial
zero-filled destination is not the initialized callback table.

| State IDs | Callback | Presentation contract |
| --- | --- | --- |
| 0 | `character_selector_update_0` | Raise support transition by 0.1 to 1, then lower fighter transition by 0.1 to 0; ordered completion |
| 4 | `character_selector_update_4` | Raise fighter transition by 0.1 to 1, then lower support transition by 0.1 to 0; also require support animation completion |
| 7 | `character_selector_update_7` | Raise support transition by 0.1, clamp at 1 and wait for support animation completion |
| 8 | `character_selector_update_8` | Poll child panel open |
| 10, 11 | `character_selector_update_10`, `character_selector_update_11` | Poll child panel closed |
| 12 | `character_selector_update_12` | Inspect resource cursor/completion and select a resource sample |
| 2, 3, 6 | `character_selector_update_2`, `character_selector_update_3`, `character_selector_update_6` | Routing without scalar increment |
| 1, 5, 9, 13 | `character_selector_update_1`, `character_selector_update_5`, `character_selector_update_9`, `character_selector_update_13` | No-op |

These callbacks bound presentation behavior, without describing navigation.
Entry helpers initialize ramp endpoints and resource-completion latches:
`character_selector_enter_0` starts fighter transition at 1;
`character_selector_enter_4` starts support transition at 1; and
`character_selector_enter_6` starts support transition at 0.
`character_selector_enter_8` and `character_selector_enter_11` open/close
the shared panel with duration 8.

### Linear motion, recursive easing and pulse request

The common tail of `character_selector_advance` (`0x003B9480`) owns these
`CharacterSelectorInput` values:

| Field | Formula/gate | Reset or consumption |
| --- | --- | --- |
| `portrait_visibility` | Add 0.2 toward 1 when `support_presentation_state` is neither 4 nor 3 and `state59_blocked` is neither 1, 3 nor 2; otherwise subtract 0.2 toward 0; clamp endpoints | `character_selector_construct` initializes zero; `character_selector_draw_fighter_portrait` maps mirrored position using `30*x - 150` |
| `fighter_anchor`, `support_anchor` | Outside `[-1,1]`, move by 0.2 toward nearest endpoint; inside leave unchanged | Selection setters reset offsets; navigation adds/subtracts 1 per visited slot; `character_selector_draw_fighter_cells` and `character_selector_draw_support_cells` scale by 36 |
| `recursive_easing` | `x = x + (1-x)*0.02` every common-tail call | `character_selector_set_fighter` and successful `character_selector_move_fighter` reset zero; rendering consumer unresolved |
| `pulse_phase` | With nonzero phase or `pulse_request`, add 0.03; only above 1 subtract 1 if requested, otherwise reset zero | `character_selector_construct` initializes zero; `pulse_request` always cleared at update end; `character_selector_update` requests 1 after its early-return gates |

Recursive easing has no threshold, clamp or completion latch.
**Formula inference:** from zero, exact arithmetic leaves distance `0.98^n`;
this is not a measurement or a promised exact floating endpoint.
The bounded float-load search does not exclude integer loads, aliases or an
unexamined rendering consumer. Navigation wrap and eligibility belong to
[Character Select](../game/character_select.md).

`character_selector_draw_arrows` reads phase without advancing it. Mirrored
arrow displacement is `5*max(0,sin(pi*phase)-0.1)/0.9`, through
`audio_angle_sine` and `sine_polynomial_kernel`.
It is one half-sine pulse per normalized `0..1` traversal with a dead zone
near both endpoints. Withdrawing a request lets a started pulse finish; it
stops at zero on crossing instead of freezing immediately.
