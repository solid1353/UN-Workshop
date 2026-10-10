# X-dash

## Research coverage

Established: native slot, zero cost, shared entry/exit gates, preparation, commitment, motion, delayed contact and cleanup.
Static coverage includes all 74 definitions containing slot `0x13`, their thresholds, and definition 14's distinct contact record.
Observed coverage is three completed/cancelled attempts in one Kakashi-versus-Sai Practice sequence, with bounded phase-writer instrumentation.
Open: callback/indirect bypasses, simultaneous cancellation reachability, later overrides, unsampled descendants, cooldown lifetime and visible timing.
Routine, field and data names come from `@annotations/NA2`; comments hold the per-routine details.
Addresses are live resident EE addresses; raw instructions establish offsets where applied `Fighter` field names disagree.

Native X-dash behavior in retail NA2 (`SLPS-25837`). Related owners:
[Movement and physics](../stages/movement_and_physics.md) owns integration and
ordinary destination states; [Combat action execution](combat_action_execution.md)
owns common phase dispatch; [Character action callbacks](../characters/character_action_callbacks.md)
owns the wider callback census.

## Evidence basis and address conventions

Binary identities follow
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
The findings below combine static retail evidence with the bounded observations
stated above. Those observations do not establish identical cancellation
reachability for every character or visible elapsed timing.

The X-dash fields are named in `Fighter` and
`AwakeningCharacterRecord`. The saved declarations and some applied decompiler
field expressions disagree: for example, the verified accesses to motion
classification `+0x9BA`, startup `+0x118`, duration `+0x11C` and primary cursor
`+0x1C4` appear under unrelated fields in the current decompilation.
The raw instruction offsets support the meanings used here; the cause of the
type-view disagreement is not established.

## Native action and cost

X-dash uses major state `8`, action index `0x13`, and ordinary phases
`0`, `1` and `2`. Its `ActionRecord` has category `2`, flags `0`,
signature `0x02000011` and cost `0.0`. It consumes no chakra and has no
minimum-chakra requirement.

`action_select_record` (`0x00239530`) selects the fixed slot.
`action_validate_candidate` (`0x00244190`) returns the accepted ordinary
category result before affordability checking for this category.
`action_dispatch_index` (`0x0023A9A0`) then enters it through
`fighter_set_action_state` (`0x00217E40`). The shared cost path reads the
record's cost and subtracts it with a zero floor when a debit applies.

## State transitions

Phase `0` is cancellable preparation, phase `1` is dash movement, and
phase `2` is the ordinary hit/completion transition. A phase write alone is
not a safe commitment boundary: phases `1` and `2` can be transient during
an update that ultimately cancels the action.

`Fighter.action_motion_class` distinguishes preparation (`1`), committed
movement (`2`) and recovery (`3`). In
`action_exit_motion_class` (`0x0023C230`), preparation waits for the primary
cursor to reach `x_dash_startup`; `x_dash_commit_movement`
(`0x0023C0F0`) then selects movement and phase `1`.
`paired_action_entry` (`0x0023D980`) handles contact, completion and
interruption recovery. Its ordinary reason-`2` path selects recovery and
phase `2`, but delayed contact can retain movement.

The three bounded observations established these ordered paths:

- Completed dash: phase `0`/motion class `1`, then persistent
  phase `1`/class `2`, then phase `2`/class `3`.
- Early cancellation: preparation directly to another major action.
- Final-frame cancellation: a transient phase-`1` write, then direct exit
  from preparation to another major action.

In that sequence, the first fighter-update boundary entered with phase
`1` and motion class `2` was the first persistent state after the final
cancellation opportunity. Static evidence does not establish that boundary's
reachability for every callback or variant.

## Character-authored records and threshold producers

All 74 distinct definitions containing slot `0x13` give it the same
category, flags, signature and zero cost. Four auxiliary four-record
definitions omit it, and repeated filler references do not add distinct
definitions. The wider inventory belongs to
[Character identity](../characters/character_ids.md#character-definition-table)
and [Action commands](action_commands.md#static-action-data).

`character_definition_table` (`0x005A2900`) selects each character record
and its default action array. All inspected X-dash records' `debug_name`,
unnamed string pointer `+0x04` and `display_name` point to
`empty_string` (`0x006031F0`), whose first byte is NUL. The table therefore
supplies no character-specific X-dash move name.

`fighter_load_character_record` (`0x002151E0`) copies the authored
`x_dash_startup`, `x_dash_duration`, `x_dash_min_distance` and
`x_dash_max_distance` into the fighter.
Startup ranges from `6..12` and duration from `8..18`; these are action
cursor thresholds, not established visible frames or seconds.
`actions_resolve_thresholds` (`0x00218D30`) replaces the slot's sentinel
`threshold` and `threshold_2` with `x_dash_max_distance`.
Target construction uses that distance independently of the timing sum.

| Definition ID | Annotated character record | Annotated slot `0x13` | Startup / duration | Repeat/contact limit | Maximum distance |
| ---: | --- | --- | --- | ---: | ---: |
| 14 | `fighter_id_014_character_record` (`0x004474A0`) | `fighter_id_014_x_dash_record` (`0x00446D3C`) | `12 / 18` | 4 | 700 |
| 39 | `yellow_flash_character_record` (`0x004877D0`) | `fighter_id_039_x_dash_record` (`0x00486D7C`) | `9 / 15` | 1 | 850 |
| 51 | `fighter_id_051_character_record` (`0x004BC530`) | `fighter_id_051_x_dash_record` (`0x004BBC7C`) | `9 / 18` | 1 | 900 |
| 70 | `fighter_id_070_character_record` (`0x00525BC0`) | `fighter_id_070_x_dash_record` (`0x0052522C`) | `8 / 12` | 1 | 700 |
| 76 | `hiruko_character_record` (`0x005403A0`) | `fighter_id_076_x_dash_record` (`0x0053FCAC`) | `8 / 8` | 1 | 400 |
| 92 | `fighter_id_092_character_record` (`0x00595B60`) | `fighter_id_092_x_dash_record` (`0x0059531C`) | `8 / 12` | 1 | 700 |

Definition 14 is the only inspected static slot with `repeat_count = 4`;
the other 73 use `1`. Its `fighter_id_014_x_dash_rows`
(`0x00444D2C`) have these headers:

| Phase | Animation slot | Condition | Start | Rate |
| ---: | ---: | ---: | ---: | ---: |
| 0 | `0x00` | 0 | 0 | `0x0C0` |
| 1 | `0x66` | 0 | 0 | `0x200` |
| 2 | `0x39` | 0 | 0 | `0x100` |
| 3 | `0x45` | 0 | 0 | `0x100` |
| 4 | `0x44` | 0 | 0 | `0x100` |
| 5 | -1 | 0 | 0 | 0 |

Condition-zero rows do not advance on an authored positive count. Explicit
phase selection and the shared state machine still govern them
([phase progression](combat_action_execution.md#shared-phase-progression)).
The repeat-count difference selects delayed contact without changing
category-`2` dispatch.

The authored data is a template. Constructor-installed writable arrays can
replace it, `actions_setup_working_array` (`0x00219620`) copies default
slots from `4` onward, and `actions_resolve_rows` (`0x00218FE0`) links the
copied phase rows
([working arrays](action_commands.md#working-action-arrays)).
Preservation of slot `0x13` and its thresholds throughout every constructor,
callback and indirect writer is not established.

Definition 14's `fighter_id_014_create` (`0x0025EF70`) calls
`fighter_id_014_construct` (`0x0025EFC0`).
Its `choji_classic_callbacks` (`0x00442800`) select
`choji_classic_channel2` (`0x0025F170`),
`character_id014_channel3` (`0x0025F410`),
`choji_classic_hit_response` (`0x0025FDA0`) and
`choji_classic_channel5` (`0x00260260`). Their full descendants were not
followed for X-dash preservation or bypass.

## Static entry and dispatch gates

The fixed request route needs category bit `2` and
`action_slot19_allowed` (`0x0023BEE0`):

- `x_dash_cooldown` and `exchange_roles` must both be zero.
- `contact_flags & 0x0C` must be clear, or `section` and
  `target_section` must differ.
- If already in major `8`, `current_action_payload` must exist and its
  `flags` word must equal `0x20` exactly.

Input recognition belongs to [Action commands](action_commands.md), and
exchange roles to [Extra Hit](extra_hit.md#exchange-state-at-fighter-0xb00).

`fighter_enter_action_record` (`0x00238A70`) selects the working record;
category `2` enters `x_dash_enter_preparation` (`0x0023C000`), which
selects preparation, clears the invocation count, and saves direction and
starting position. Common phase/timeline resets belong to
[action entry](combat_action_execution.md#action-entry-and-state-ownership).

After exchange and paired-state branches, the category routes
`action_stage_outcome_continuation` (`0x0023B280`) to transition handling
and `action_update_jutsu_record` (`0x0023BAC0`) to motion handling
([common decisions](combat_action_execution.md#continuation-and-common-exit-decisions)).
Different authored records alone do not prove a shared-path bypass.

For slot `0x13`, `character_dispatch_channel` (`0x00217670`) uses the
fighter's callbacks without the provider remapping reserved for indices
below `4`. `fighter_dispatch_action_update` (`0x00249640`) runs channels
`2` and `3` before the later motion dispatcher
([callback ownership](../characters/character_action_callbacks.md#evidence-convention-and-ownership)).
This establishes when selected callbacks can run, not that all leave
X-dash unchanged.

## Committed motion and counter lifetime

Commitment clears `action_motion_updates` and
`x_dash_motion_accumulator`, sets `x_dash_cooldown = 20`, and selects
phase `1`.

`action_motion_class_update` (`0x0023CD80`) zeros planar and vertical
speed during preparation. During movement it constructs a displacement from
`x_dash_start_position` to `x_dash_target_position`, advances the
accumulator by `(pi/2 / x_dash_duration) * update_rate`, and scales the
displacement by `angle_cosine(accumulator - pi/10) * 0.11`.
`angle_cosine` (`0x0016EFB8`) is verified as the scalar cosine helper.
The resulting planar and vertical speeds feed
[Movement and physics](../stages/movement_and_physics.md).

The target is not universally fixed at entry. The ordinary matching-section
route, excluding an opponent in `(6,0x61/0x62)`, recomputes it through
`x_dash_target_opponent` (`0x0023C6D0`). Other inspected routes call
`x_dash_target_directional` (`0x0023C840`) only while
`action_motion_updates == 0`.

The opponent target uses the distance clamped by `x_dash_min_distance`
and `x_dash_max_distance`, each scaled by
`effect_jump_height_factor` (`0x00306E80`). The directional target uses
the maximum and stage-query adjustment. Producing effects and every
adjustment variant were not comprehensively followed; stage collision
services belong to [Collision](collision.md).

The motion consumer increments `action_motion_updates` once at its common
tail, including preparation and recovery. Entry, commitment and ordinary
recovery initialization reset it. It counts consumer invocations, unlike
the primary action cursor; the movement accumulator uses fighter delta.
Neither establishes player-visible timing by itself. Complete cooldown
decrement/writer lifetime remains open.

## Contact latch and recovery continuations

Preparation waits until the primary cursor reaches `x_dash_startup`.
Committed movement compares it with `x_dash_startup + x_dash_duration`.

With `repeat_count != 1` and `previous_action_outcome == 1`, transition
handling waits for that sum, then invokes reason `2` and returns.
Otherwise it checks timeout (reason `0`), ceiling contact (reason `0`)
and side contact (reason `4`) sequentially. More than one continuation
is structurally possible in one update; simultaneous reachable conditions
are not established.

A reason-`2` invocation with `repeat_count != 1` latches
`previous_action_outcome = 1`. Before the timing sum it raises the fighter's
vertical position by `5.0`, prepares the opponent through
`fighter_recursive_motion_update` (`0x0021A8D0`), and calls
`hit_init_update_pause` (`0x00224510`) in mode `1` only when the
opponent's current pause count is nonpositive. It retains movement and does
not select phase `2`. Contact therefore does not always end committed
movement. General hit effects belong to [Hit response](hit_response.md).

The ordinary continuations are:

| Reason | Phase | Motion class | Recovery limit |
| ---: | ---: | ---: | ---: |
| 0 | 2 | 3 | `0x10` |
| 1 | 2 | 3 | `0x24` |
| 2, outside delayed contact | 2 | 3 | `0x14` |
| 3 | 3 | 3 | `0x0C` |
| 4 | 4 | 3 | `0x0C` |
| 5 / 6 | 2 | 0 | — |

These codes do not completely name every contact outcome.

In recovery, grounding can admit exit independently of
`action_motion_updates >= action_motion_countdown`.
Matching sections with an opponent outside `(6,0x61/0x62)` suppress the
count-based airborne exit; otherwise it is admitted except for airborne
reason `1`. Admitted exits clear the motion class and select:

| Condition | Destination |
| --- | --- |
| Grounded | Landing `(4,0x26)` |
| Airborne, reason `1/3/4` | `(3,0x25)` |
| Airborne, reason `0/2` | `(3,0x23)` |
| Motion class zero, grounded | Neutral `(0,0)` |
| Motion class zero, airborne | Ordinary fall `(3,0x1E)` |

The zero-class path first calls `capture_reset_approach`
(`0x0023EF30`). Destination behavior belongs to
[ordinary state dispatch](../stages/movement_and_physics.md#ordinary-state-dispatch).

`fighter_action_exit` (`0x00217BD0`) reaches old major-`8` cleanup in
`action_exit_record` (`0x00238D00`) before the new state is installed.
A nonzero X-dash motion class invokes reason `6` to clear it during an
external action change. This does not make every external request eligible
at every X-dash point.
