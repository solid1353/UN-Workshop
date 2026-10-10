# Extra Hit

## Research coverage

Established: eligibility, authored chase/counter records, role changes, counter
window and limit, initialization and teardown in retail NA2 (`SLPS-25837`).
Open: attacker-bit `8/0x20` writers beyond the bounded search, precise probe
geometry, intermediate rounded windows, visual labels and score meaning.
Static ordering does not establish exhaustive character-specific behavior.
Names come from `@annotations/NA2`; routine comments hold code-level detail.

This document owns the native exchange between a launched fighter and its
opponent: chase eligibility, counter selection, role reversal and teardown.
[Hit response](hit_response.md) owns launch reactions, the exchange velocity
multiplier and response gating; [Combat action execution](combat_action_execution.md#continuation-and-common-exit-decisions)
owns major-8 entry and common exits; [Action commands](action_commands.md#selector-modes-and-entry-gates)
owns selector modes; [Practice mode](../modes/practice_mode.md#linked-attack-and-extra-hit)
owns counter options; [Target selection](target_selection.md#retained-source-writers-and-record-lookup)
owns retained-source contracts.

## Evidence and address conventions

Binary identities and address conventions are in
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
All addresses below are live. The routines are resident ELF entries; the
stage queries and `action_descriptor_table` belong to `BTL.BIN`.
Named fighter fields follow the saved `Fighter` declaration and verified raw
loads/stores. Applied decompiler field expressions can disagree with that
declaration and do not independently establish offsets.

The authored inventory covers all 74 primary action tables (3,428 records).
The role-writer search covered direct role-word/byte and window stores;
rebased aliases, bulk writes and uninspected overlay writers remain open.
The pair resolver was inspected here only for its calls into this exchange.

## Eligibility and action exit

For a pending record with `ActionRecord.category & 0x1000`,
`action_stage_outcome_continuation` asks `exchange_wait_update` for
eligibility. Result `1` starts the paired sequence through
`exchange_set_roles`: it writes the roles, clears the opponent's rejection
countdown on a fresh exchange unless activation is pending, and enters the
candidate attack. Wait `0` and rejection `-1` both continue into the
[common exit decisions](combat_action_execution.md#continuation-and-common-exit-decisions).
[Major-8 entry](combat_action_execution.md#action-entry-and-state-ownership)
resets the pending candidate, so later candidates can be checked again.

### Eligibility conditions

`exchange_wait_update` (`0x00241A50`) requires:

- Initiator `exchange_roles == 0`; opponent `state_flags & 0x08`.
- Opponent major `5`, response `0x3C`, `0x3D`, `0x3F`, `0x40` or `0x41`.
- A zero coordinator state. The nullable `battle_hub` leads through
  `BattleHub.fighters` to `FighterCoordinator.state`; missing links count
  as zero.
- No initiator `character_id == 0x40/0x3B` with `contact_flags & 0x20`,
  the exclusion shared with the ordinary-response fallback
  ([Hit response](hit_response.md#contact-rebounds)).
- Initiator major `8` and its `current_record` exactly equal to the
  opponent's retained hit record. Resolution takes `response_attack_record`,
  then nonzero-kind `response_source` and `contact_attack_source` through
  `hit_source_record_get`, then `atk_dummy_record`; the same provenance
  contract is used by `response_apply_table_timing`.

Failure rejects. Otherwise it waits while the opponent's
`primary_timeline.current < 7 * update_rate` or the initiator's
`action_outcome != 1`. After that, the candidate in `actions` selects a
geometry gate by `ActionRecord.flags & 0x1C00`.

Here `W = contact_width * capture_uniform_scale` and
`H = contact_height * capture_uniform_scale`, on the opponent unless stated
otherwise. *Airborne* means `contact_flags & 0x80` is clear. Probe sentinel
`-17320.508` means the stored boundary is unset.

| Kind | Additional gate |
| ---: | --- |
| `0x0400` | `exchange_side_eligible` (`0x00241650`): airborne, `contact_flags & 0x40` clear, `side_probe_distance` unset or at least `2.5W`. A facing-directed endpoint query through `field_clamp_section_endpoints` (`0x00708AF0`) accepts result `1` directly; otherwise its signed corrected clearance must be at least `2W`. |
| `0x0800` | Inline in `exchange_wait_update`: airborne, `ceiling_flags & 1` clear, `ceiling_probe_distance` unset or at least `1.5H`, and `puppet_reconcile_motion` (`0x0021C640`) returns zero for the two positions using the initiator's scaled dimensions. |
| `0x1000` | `exchange_floor_eligible` (`0x00241890`): airborne, `floor_probe_distance` unset or at least `2H`; position component 2 is at least `H` above the projected boundary and no lower than the floor profile. |

Each gate re-requires one of the five launch responses. Other kinds reject.
The endpoint query is not an established “contact means reject” predicate.
The probe field names follow
[Movement and physics](../stages/movement_and_physics.md#floor-side-surfaces-and-limits);
precise geometry interpretation beyond their measured use remains open.

### Authored Extra Hit records

Every primary table has exactly three category-`0x1000` records:

| Action index | Kind | Response selector | Selected response |
| ---: | ---: | ---: | --- |
| `10` | `0x0400` | `0x12` in 73 tables, `0x13` in one | `0x3C/0x3D`, or `0x3E` |
| `11` | `0x0800` | `0x15` | `0x40` |
| `12` | `0x1000` | `0x14` | `0x3F` |

All have `repeat_count == 1`. Indices `13..15` (category `0x2000`) and
`16..18` (category `0x4000`) repeat those three kinds and selectors, without
category `0x1000`. Their flags add `0x80`, `0x200`, `0x100` respectively.
These are the receiver's counter records. Primary table ownership is in
[Substitution](../characters/substitution.md#attack-record-ownership-and-clean-elf-inventory).

### Selecting Extra Hit and counter records

`action_select_from_signature` queries `action_selector_mode`.
With no exchange role, mode `1` requires major `8`, current record flags
in `0x380`, no category `0x00F00000`, and current payload flag `0x10`.
Receiver modes `2/3` are described below. Selection still requires
`action_entry_allowed`: a zero action lock, and in ordinary major `5`,
mode `2` unless the independent `0x5B/0x5C` exception applies. Mode `3`
therefore cannot bypass the ordinary launch-state gate.

`action_select_record` reaches `action_stage_chain_slot`, which selects the
first matching index `10..18` by normalized signature, affordable `cost`
against `chakra` (unless `effect_flag40_active` applies), and nonempty
intersections with the category/kind masks. The match becomes
`pending_action`. `action_build_chain_masks` gives the exchange pairings:

| Mode and state | Category | Kind source |
| --- | --- | --- |
| `1`, attacker in major `8` | `0x1000` | Current launch flags `0x80/0x100/0x200` → `0x400/0x800/0x1000` |
| `2/3`, receiver without a current attack | `0x2000` | Opponent's current kind, only with its attacking low role byte set |
| `2/3`, current category `0x1000/0x2000` | Keep `0x2000` on `prng_inclusive(3) == 0`, otherwise `0x4000` | Own current kind |
| `2/3`, current category `0x4000` | Keep `0x4000` on zero, otherwise `0x2000` | Own current kind |
| `2/3`, another current category | `0x4000` | Own current kind |

The nominal keep probability is one in four; the draw repeats per candidate.
[Action commands](action_commands.md#chain-masks) owns the complete masks and
signature normalization.

Outside indices `10..18`, 867 records across all 74 tables carry exactly one
launch bit. Dominant authored pairings:

| Launch flag | Records with the dominant selector | Launch response | Normally offered chase |
| ---: | ---: | --- | --- |
| `0x80` | 434 with selector `0x12` | `0x3C/0x3D` | `10` → another `0x3C/0x3D` |
| `0x100` | 159 with `0x14` | `0x3F` | `11` → `0x40` |
| `0x200` | 167 with `0x15` | `0x40` | `12` → `0x3F` |

## Exchange state at fighter `+0xB00`

`exchange_set_roles` (`0x00241F10`) writes the paired roles on an accepted
chase or counter. A nonzero initiating low byte skips role changes but still
runs the common tail. Otherwise:

| Initiator role before | Initiator after | Opponent after | Retarget |
| --- | --- | --- | --- |
| High byte clear | Set `0x0001` | Set `0x0100`; clear rejection unless pending | No |
| Any of `0x0300` | Set `0x0004`, clear high byte | Clear low byte, set `0x0400` | Yes |
| Any of `0x0C00` | Set `0x0010`, clear high byte | Clear low byte, set `0x1000` | Yes |
| Any of `0x3000` | Set `0x0004`, clear high byte | Clear low byte, set `0x0400` | Yes |

Bits outside those masks survive. A nonzero high byte outside those three
groups supplies no new role. The low byte is the attacking role; the high byte
is the receiving role.

Each role update sets the opponent's window from its count **before** the
common increment:

`exchange_window = max(1, s16(cvt(12.0 - 1.7142857 * exchange_count)))`

The conversion uses the active EE rounding mode. Exact established endpoints
are `12` at count `0` and the floor `1` from count `7`; intermediate
rounded values remain open.

Retargeting makes the initiator retain its opponent as both `response_source`
and `contact_attack_source`, clears `response_attack_record`, and adopts
the opponent's `published_action_record`, or its `current_record` when
category `0x000C0000` is clear. The retained record supplies `repeat_count`
and `knockback_scale` through the retained-repeat gate. Pair linkage itself
is unchanged.

The common tail cancels nonzero `staged_chakra` on both fighters through
`chakra_cancel_stage` with mode zero, dispatches the candidate through
`action_dispatch_index` with force `1`, then retargets after role reversal.
`exchange_retarget_response` (`0x00242360`) selects the response from the
retained record. For a current attack without category `0x1000`, it copies
the second-phase animation slot from `action_descriptor_table` and six
motion fields from `response_motion_table` into `ActionRecord.exchange_motion`.
The copied fields are flags, event gate, planar/vertical speed, damping and
gravity auxiliary; the row's pause and lock are untouched. Finally both
`exchange_progress` values clear and both counts increment, regardless of
the dispatch return.

Missed windows change receiver `0x100 → 0x200` and paired attacker
`1 → 2`, or receiver `0x400 → 0x800` / `0x1000 → 0x2000` while attacker
`4/0x10` remain set. This does not establish `4 → 8` or `0x10 → 0x20`.
Teardown handles `8/0x20`, but their writers remain outside the established
fighter-role paths.

### Receiver response and exchange limit

`hit_resolve_pair` calls `exchange_receiver_update` (`0x002426C0`) for a
surviving `hit_request_bits & 1`. A nonzero result discards that incoming hit
and the opponent's matching `0x100` outgoing request. A role bit alone does
not schedule this handler every update. Receiver priority is
`0x100`, `0x400`, `0x1000`, with interleaved attacking-role checks.

| Receiving role | Candidate | Result |
| ---: | --- | --- |
| `0x100` | Present | Stage own rejection `60` unless already pending, call `exchange_set_roles`, discard incoming hit |
| `0x100` | Absent | Receiver → `0x200`, attacker `1 → 2`; clear own rejection unless pending; let hit proceed |
| `0x400/0x1000` | Present and count below `15` | As above, also clear attacker's rejection unless pending |
| `0x400/0x1000` | Absent, or count at least `15` | Discard pending candidate at the limit; receiver → `0x800/0x2000`; clear own rejection unless pending; let hit proceed |

The initial `0x100` branch has no count gate. Attacking roles `4/0x10`
return success and discard hits while active. Missed-counter branches also
clear the receiver's saved landing speed and physics selector.

For a receiving role with no candidate, `action_selector_mode` asks
`action_window_progress` (`0x00239250`) about the opponent with
`exchange_window`. A valid score is cached in `exchange_progress`; invalid
progress stores zero and returns mode `-1`. Valid roles `0x100/0x400/0x1000`
select modes `2/3/2`; successful `0x100` also clears `action_lock`.
With a candidate already pending it skips the score query, keeps the old
score and returns `-1`.

The progress interval follows the current authored attack phase. Its ordinary
width is `window * converted_phase_rate / 256` animation frames, where the
phase rate times update rate is converted under the active rounding mode;
the active matching animation player can supply its own rate, frame and
fraction. Payload flags and authored end fields can bypass or extend the
ordinary terminal window, so “only the last window frames” is conditional.
The score is a normalized progress formula, without a clamp proving an
unconditional `0..1` bound. Its player-facing meaning remains open.
The full mode table belongs to
[Action commands](action_commands.md#selector-modes-and-entry-gates);
counter options belong to
[Practice mode](../modes/practice_mode.md#linked-attack-and-extra-hit).

### Initialization and teardown

`fighter_init` clears the roles, count, window and cached progress.

`exchange_teardown` (`0x00243EF0`) returns when both role words are zero.
With a nonzero caller low byte it removes caller groups `0x3/0xC/0x30`
and the opponent's corresponding `0x300/0xC00/0x3000`; otherwise it clears
both whole words. It resets both counts and exchange presentation latches,
the caller's presentation amount/factor fields, and the applicable motion
selectors/saved speeds. When the caller's role word becomes zero it restores
both `update_rate_override` values to `1.0`. It leaves the window and cached
progress unchanged: retained timing values do not prove admission.

`exchange_terminal_handoff` admits teardown on a terminal phase, caller
recovery `0x61/0x62`, or the opponent entering major `6`, then exits to
neutral when grounded or ordinary fall otherwise. Other entry/exit owners
invoke this cleanup conditionally; state interruption alone does not imply
exchange teardown.

## Exchange fields

| Fighter field | Type | Contract |
| --- | --- | --- |
| `exchange_roles` | `u32` | Attacking low byte `1/4/0x10`, missed initial attack `2`; receiving high byte `0x100/0x400/0x1000`, missed `0x200/0x800/0x2000` |
| `exchange_count` | `s16` | Both increment after entry; both reset at teardown |
| `exchange_window` | `s16` | Receiver's interval against the opposite fighter's phase; survives teardown |
| `exchange_progress` | `f32` | Cached timing score; entry clears it, teardown preserves it |

## Interpretation

**Inference:** requiring a launch caused by the initiating current attack,
then selecting another authored launch, makes this the native air-chase/juggle
continuation. The window shrinks with each exchange; later receiving roles
refuse further counters at count `15`. Visual labels and the player-facing
score meaning have not been established.
