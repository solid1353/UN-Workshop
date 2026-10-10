# Animation runtime

## Research coverage

Established: resident NA2 cursor/seek/loop ordering, typed interpolation,
sampled-endpoint blending, target binding, queued events and removal boundaries.
Names and layout fields come from `@annotations/NA2`; addresses are live.
Open: deferred `0x0104` reachability/index producers, alternate-output ownership,
seek-callback consumers, event-word meanings and completion-flag `0x10` writers.
Evidence is static; exceptional inputs, caller guarantees and scheduling remain open.

This document owns playback and evaluation after parsing in retail NA2
(`SLPS-25837`). All cited routines are in resident `SLPS_258.37`.
[Retail game file identities](../game/files/file_identities.md#address-conventions)
owns input identities and address conventions. Annotation comments carry
per-routine details; partial types name established fields without claiming
complete object layouts. Recovered signatures do not establish original C
argument ordering for mixed scalar/general inputs or unused return values.

Related owners: [CCS runtime](../game/files/ccs_runtime.md#animation-track-parsing)
(parsing and container lifetime),
[Character asset tables](../game/character_assets.md#animation-name-and-0x4c-stride-tables)
(selection), [Scene playback callers and owners](scene_playback_owners.md)
(caller ownership), [Model runtime](rendering/model_runtime.md)
(hierarchy/palettes), [Timer primitives](timer_primitives.md)
(action-frame arithmetic), and [Effect-generator commands](effect_generator_commands.md)
(attached actions).

## Descriptor and player separation

`ccs_load` constructs the shared tag-`0x0700` animation resource;
`ccs_parse_animation_tracks` builds its track pairs and relation map.
`animation_attach` (`0x001B99B0`) separately materializes targets, initializes
per-player evaluator work and resets cursor publications.

| Shared descriptor field | Contract |
| --- | --- |
| `CcsAnimationDescriptor.container` | Owning CCS container. |
| `frame_count` | Terminal cursor is `(frame_count - 1) * 256`. |
| `reader_start` | Packed command stream start. |
| `track_pairs`, `track_count` | Array/count of `AnimationTrackPair` record/key-descriptor pairs. |
| `relations` | Halfword parent map; `0xFFFF` means no matching relation. |
| `flags & 0x02` | Loop policy. |

`CcsAnimationPlayer` owns the bound `animation`, halfword `step`, unsigned
`cursor`, published `fraction` and `frame_index`, embedded `reader`,
`next_boundary`, `queued_commands`, `command_callback`, `play_entries`,
`container`, attached generator manager `completion_stream`, and optional
`blend`. The inspected fighter uses the halfword step; the advance API accepts
a full unsigned word. `CcsPlayEntry` separates target `value`, resolved
`provider`, `type_tag`, `flags` and evaluator pointer in `type_specific`.

`animation_player_destroy` releases per-player work and the reader; it does
not free the animation through `animation_descriptor_destroy`. Shared
descriptor lifetime belongs to CCS resource destruction, so a player's cursor
and evaluator work cannot be treated as shared animation fields.

## Advance and end behavior

`animation_advance_position` (`0x001BB210`) requests unsigned
`old_cursor + delta`, with 256 units per whole frame. The API establishes
neither reverse playback nor an overflow guard. It clears the previous event
list through `animation_commands_clear` before every advance.

While `blend` is active and the requested cursor is below
`blend.duration * 256`, only `animation_blend_apply` runs. Cursor, fraction
and integer frame are published and the call returns zero. At the duration
boundary, the blend is destroyed, its duration is subtracted, and only the
residual step advances the incoming animation.

Normal evaluation has this order:

1. Clamp to the terminal cursor and remove overshoot from the typed-curve delta.
2. Evaluate typed curves through `ccs_apply_packed_frame_command`, including
   fractional or zero delta without an integer-frame change.
3. Advance the enabled generator-action manager by the old/new integer-frame
   difference, then publish cursor/fraction/frame.
4. If the integer frame changed, advance every materialized `0x0E00` effect
   by that difference, install the player's container/table/reader context,
   and dispatch packed commands through `ccs_parse_streamed_block_range`
   when the new frame reaches `next_boundary`. Restore the container reader.
5. Within that integer-change branch, apply completion/loop policy.
6. Finalize nonnull alternate output after normal advance.

`completion_flags & 0x04` suppresses the attached generator manager.
Loop handling is inside the integer-change branch, not an unconditional
terminal check.

For a looping descriptor, completion destroys any remaining blend, resets
typed work through `animation_evaluators_reset`, rewinds to `reader_start`,
restarts enabled generator actions, clears completion flag bit 7, and zeros
`next_boundary`, `cursor`, `fraction` and `frame_index`. It returns zero
and discards overshoot. This branch neither dispatches the next cycle's frame
zero nor reapplies its transforms: the target retains the terminal transform
until a later evaluation or another writer changes it.

For a non-looping descriptor, reaching the terminal cursor normally returns
one. Only inside the integer-change branch, `completion_flags & 0x10`
replaces this with `animation_stream_complete`: the action-manager result
when enabled/present, otherwise one. Geometric end and action completion are
distinct; a terminal zero-step call skips the replacement and returns the
clamp result. Flag-`0x10` producers remain unresolved.
[Support mechanics](../gameplay/characters/support_mechanics.md#animation-result-and-common-state-transitions)
owns one consumer of that result.

## Absolute seeks and evaluator reset

`animation_player_seek` (`0x001BB5C0`) accepts a target in 1/256-frame units.

| Without an active blend | Behavior |
| --- | --- |
| Forward target | Advance by `target - old_cursor`, without alternate output. |
| Backward target | Reset typed work, rewind commands, restart enabled actions, clear completion flag bit 7 and zero boundary/cursor publications, then advance by `target` from zero. |
| Equal target | Clear queued events and return zero without evaluating curves or dispatching commands. |

Backward seeks reconstruct from zero rather than walking key pointers
backward. They retain normal end-clamping and loop policy because they use
normal advance.

An active blend is destroyed before comparison and sets the comparison origin
to zero, but that branch retains the stored cursor/publications. Seeking zero
then takes the equal-target return. A positive target becomes a delta added to
the retained blend cursor by normal advance; typed curves receive that target
delta subject to terminal clamping. This does not establish a complete player
restart after blend cancellation.

Seek flags bit 0 temporarily clears `command_callback` during delegated
advance and restores it afterward. Event-list construction does not check
that callback, so this flag does not establish suppression of queued events.

`animation_evaluators_reset` walks nonnull entry work and uses
`animation_evaluator_reset` for `0x0102`, `0x0202`, `0x0503`,
`0x0603/05/07/09` and `0x1902`. Vector, rotation, scalar and color
initializers restore initial values, zero local times and reinstall initial
segment pointers without allocating new curve data.

## Packed command crossing and event delivery

`ccs_parse_streamed_block_range` (`0x001B4F80`) reads sequentially while
`boundary <= target`. A `0xFF01` marker replaces the boundary with its
payload; the first marker beyond the target ends the pass and becomes
`next_boundary`. Large forward advances consume intervening commands.
The reader already points past the marker, so the caller's old integer frame
does not request replay of that frame's block. Packed dispatch follows typed
curve evaluation.

Tag `0x0108` uses `ccs_frame_tag_0108` to consume three words and prepend a
`CcsFrameCommand`. It retains the second/third words unchanged in
`value1/value2`, the current integer marker in `frame`, and the first word's
resolved `target/type_tag` from `ccs_play_target_unchecked` and
`ccs_play_target_type_unchecked`. A nonnull container external-play context
routes it to the player's list; otherwise the stream play context owns it.

`animation_player_deliver_commands` (`0x001BB190`) follows `next` links
in reverse encounter order and invokes `command_callback(node, argument)`
only with a nonnull callback/list. Delivery is separate from advance:
`fighter_advance_animation` calls it after advance and attachment service.
Delivery does not remove nodes, so repeated calls can revisit them before
another advance. The next advance clears them even for fractional, zero or
blend-only steps.

**Inference, high confidence:** a backward seek to a positive target can
recreate earlier packed events because it rewinds and dispatches forward; it
is not a pure pose sample. The gameplay meaning of the retained words remains
unresolved. Payload parsing belongs to
[CCS streamed playback](../game/files/ccs_runtime.md#frame-stream).

## Typed curve evaluation

`animation_evaluator_allocate` gives each typed track an
`AnimationEvaluatorHeader` followed by channel work. The header retains the
parsed descriptor, whose `channel_modes` selects the work layout. Evaluators
receive deltas. `ccs_pack_tag_0102` converts source compression selections
to runtime mode 5; these modes are not the original file selectors.

| Channel | Initializer / evaluator | Modes and work sizes |
| --- | --- | --- |
| Translation | `animation_vector_init` / `animation_vector_evaluate` | 0: zero/no work; 1: borrowed constant, `0x10`; 2: relative linear, `0x20`; 4: cubic cache, `0x50`; 5: compact endpoints/absolute time, `0x40`. |
| Scale diagonal | `animation_vector_init` / `animation_scale_evaluate` | Identity default; modes 1/2/4 use vector work sizes; no mode-5 branch. |
| Rotation matrix | `animation_rotation_init` / `animation_rotation_evaluate` | Identity default; 1: constant matrix, `0x40`; 2: accumulated matrix/relative axis-angle, `0x50`; 4/5: float/packed quaternion endpoints, `0x50`. |
| Scalar | `animation_scalar_init` / `animation_scalar_evaluate` | 0: caller default; 1: constant, `0x10`; 2: relative linear, `0x10`. |
| Packed color | `animation_color_init` / `animation_color_evaluate` | Modes 1/2, `0x10`; packed endpoints converted to RGB before interpolation. |

Linear scalar/vector curves use unsigned elapsed/duration values in
`AnimationScalarWork`, `AnimationVectorWork` and their segment types.
Advancing adds delta, consumes segments only while `duration < elapsed`,
subtracts duration and adds value deltas to the base, then evaluates
`base + segment_delta * (elapsed / duration)`. Equality retains the current
segment at its endpoint; switching requires a later positive step.

Cubic vectors use `AnimationCubicVectorWork.cursor/key/control_points`.
The key moves only when the next whole-frame time times 256 is below the
absolute cursor. For `t = (cursor - start*256) / ((end-start)*256)`, both
translation and scale use Bezier weights
`(1-t)^3, 3*(1-t)^2*t, 3*(1-t)*t^2, t^3` on cached control-point columns.

Compact vectors use `AnimationCompactVectorWork.cursor/times/packed_values`.
Crossing an interval advances both source pointers, decodes signed XYZ
halfwords with the packed low-nibble power-of-two scale, caches start and
endpoint difference, and linearly interpolates. Time-table values are whole
frames scaled by 256. These are parser-produced runtime values, not original
file halfwords.

Rotation mode 2 consumes full relative axis-angle rotations into the
accumulated matrix, then applies the current fractional rotation through
`matrix_from_axis_angle`. It does not interpolate three Euler components.
Modes 4/5 use `AnimationQuaternionWork.cursor/times/endpoints`, flip a
negative-dot destination, and use sine-weighted interpolation below dot
`0.95`, otherwise `q0 + t*(q1-q0)`. `matrix_from_quaternion` uses
`2/dot(q,q)`, accounting for nonunit results.
`animation_packed_quaternion_scales` (`0x005BF900`) scales XYZ by
`1/16384` and W by approximately `0.0000958738`.

Color mode 2 replaces packed endpoints rather than adding numeric word
deltas. `packed_color_to_weighted_rgb` treats a zero high byte as RGB bytes
scaled by `1/255`; a nonzero high byte selects HSV conversion.
`packed_color_interpolate` sums endpoint RGB vectors with weights `1-t`
and `t`. This establishes neither integer packed-word interpolation nor
alpha interpolation. Source reading and padding belong to
[CCS animation-track parsing](../game/files/ccs_runtime.md#animation-track-parsing).

## Animation-to-animation blending

A zero blend duration in `animation_attach` removes any prior blend.
With a prior animation and nonzero duration, types `0x0100`, `0x0E00`,
`0x0500`, `0x0600` and `0x1900` are matched through
`animation_name_index_create`, `animation_name_index_insert` and
`animation_name_index_match`. Matching uses hash and case-sensitive suffix
text after `name_offset` (zero if beyond the name length). Matched entries
copy old target, record/type and flags. Later materialization still runs for
ownership-bit entries, so target retention is conditional; matched/unmatched
entries both pass through remaining composition/ownership binding.

`AnimationBlendHeader` owns duration, count and item pointers.
`animation_blend_item_create` (`0x001B79B0`) requires two nonnull evaluator
pointers and old descriptor type `0x0102`; it does not separately check
the destination type. It samples both with zero delta, retaining the old
current pose and incoming initial pose in a copied `AnimationBlendItem`.

`animation_transform_blend_vtable` (`0x005D9EB0`) selects
`scene_object_blend_orientation` for initialization and
`scene_object_interpolate_orientation` for evaluation.
`animation_quaternion_blend_init` extracts endpoint quaternions and flips
a negative-dot destination; dot below `0.95` uses sine weighting, otherwise
normalized linear interpolation. Position, scale and alpha use
`start + t*delta`.

`animation_blend_apply` evaluates nonnull items at
`blend_cursor/(blend_frames*256)` and applies their composed transform to
model/effect nodes. Normal typed curves, packed commands and generator actions
do not advance during this interval: it blends sampled endpoints while the
incoming animation stays at its initial pose.

`animation_blend_destroy` frees items, the pointer array and optionally the
header. Each retained entry belongs to the incoming player table; copied
endpoint values survive release of the old evaluator table after binding.

## Target binding and transform application

Binding temporarily publishes each runtime entry in its resolved record's
`transient_play_entry` field. Existing compositions come through
`composition_children`. With `completion_flags & 0x02` clear, their
`0x0100` children bind by source-record identity; with it set,
incoming `0x0100/0x0E00` records match composition children through the
same name/hash and suffix-offset rules as blending. The name path has scratch
capacity for `0x80` entries, but its count can continue beyond guarded
storage; safe handling of larger inputs is not established, nor is retail
exceedance. Binding clears all temporary record links before return.

| Entry flag | Contract |
| --- | --- |
| Bit 0 | Target materialization/destruction ownership. |
| Bit 1 | Apply the descriptor relation map. |
| Bit 2 | Model/effect submission through `projectile_compound_submit`. |

Borrowed composition targets receive flags 2 or 6 without ownership.
Relations select the parent target, or the player node for `0xFFFF`;
`scene_node_set_parent` writes `CcsScenePlayTarget.parent`.
[Model hierarchy and matrix lifetime](rendering/model_runtime.md#composition-hierarchy-and-matrix-lifetime)
owns palette and composition-child construction.

The ordinary `0x0102` route evaluates position, rotation, scale and alpha,
with default alpha 1. `matrix_multiply_entry` / `matrix_multiply` form
`rotation * scale`; `scene_matrix_copy_translate` /
`matrix_copy_translate` add position to the last column.
`scene_node_set_local_matrix` writes `local_matrix` and sets
`matrix_dirty`. Bone-world accumulation uses the linked hierarchy's
`parent_world * local`, not independent curve writes to world matrices.

`scene_node_set_alpha` writes `alpha`; when `alpha_flags` bit 0 is clear
it also writes `inherited_factor`, otherwise it sets bit 2. This contract is
separate from matrix dirtiness.

A model's nonnull `transform_attachment` overrides scale through
`AnimationModelTransformAttachment.scale_x/scale_y/scale_z` and multiplies
position by `position_scale`, also during blending. Effects copy evaluated
X/Y scale to `AnimationEffectTransformView.scale_x/scale_y` and can call
`effect_request_restart` under their prior-state gates.
[Particle runtime](rendering/particle_runtime.md) owns their broader lifetime.

### Alternate output and deferred branch

With nonnull alternate output, a matching model record from
`animation_output_find_record` routes its pose into
`AnimationAlternateOutput` rather than writing the local node.
`animation_output_write_position`, `animation_output_write_rotation_diagonal`
and `animation_output_write_scale` lazily allocate vector rows.
Rotation mode 2 extracts Euler angles from the evaluated matrix and converts
to degrees; mode 1 uses the source constant Euler triple; other modes write
zero on this route. Alpha goes through the alpha channel to
`animation_output_write_alpha`. Missing matches use ordinary node
application. Normal advance calls `animation_output_finalize`; blend-only
advance returns first. The format's broader owner/use remains unresolved.

The deferred `0x0104` branch queues entries for evaluation after ordinary
ones. It reads `AnimationDeferredScratchView.first_index/second_index`,
refreshes selected targets, composes a transform and applies alpha zero.
Its producer, reachability and valid scratch state remain unresolved. The
application branch alone does not establish a reachable retail track contract;
the inspected parser and evaluator initialization do not supply that contract.

## Restart, hold and removal boundaries

| Operation | Contract |
| --- | --- |
| `animation_attach` | Build new track state, select incoming descriptor and reset cursor/stream publications; no normal advance at the end. |
| Backward seek / descriptor loop | Reinitialize work and rewind commands; restart enabled generator actions. |
| Terminal non-loop advance | Clamp/complete while retaining descriptor/table; a later zero-step call still evaluates curves and clears old events. |
| `animation_player_release_actions` | Immediately release generator runners through `generator_actions_release_runners`; retain descriptor/table/cursor. |
| `animation_player_clear_targets` | Destroy only owned targets, free all work/table and clear `play_entries`; retain descriptor/cursor. |
| `animation_player_destroy` | Release blend, track state, action manager, events, material state and reader; `animation_player_clear_composition_links` frees links without destroying supplied compositions. |

Owner holds/restart selection belong to
[Scene playback owners](scene_playback_owners.md#fighter-animation-ownership);
the separate streamed worker's stop/restart contract belongs to
[Streamed playback](../game/files/ccs_runtime.md#streamed-playback-sp-skill-play).

This player advances generator actions by integer-frame difference before
packed dispatch. Rewind retains generator allocations; replacement/removal
uses separate release paths.
[Effect-generator commands](effect_generator_commands.md#scheduling-and-owner-gates)
owns command gates, anchors and immediate/deferred release. The streamed CCS
owner passes a raw rate to the same manager: its count contract cannot be
inferred from this player's `>>8`.

Gameplay predicates such as `timeline_secondary_event_crossed` use a
distinct fractional timer with previous/current/predicted values and flags,
not this player's cursor.
[Timer primitives](timer_primitives.md#event-and-interval-predicates)
owns their arithmetic and gates. Visual animation advance alone does not
establish how an action-frame predicate was armed or scheduled.
