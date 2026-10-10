# Controller input runtime

## Research coverage

Established statically for retail NA2 (`SLPS-25837`): pad initialization,
publication/decoding, resident pad storage, configuration, vibration, library
boundaries and inspected consumers' ordering/retention. Open: opaque fields,
shutdown writer, callback API name, indirect callers/writers and direct binding
predicates' scheduling.
Hardware effects/timing remain unobserved; Adventure consumers and remaining
PADMAN/SIO2MAN code were not surveyed.

## Related owners

Input-history interpretation belongs to
[Action commands](../gameplay/combat/action_commands.md), battle pacing to
[Battle lifecycle](../gameplay/session/battle_lifecycle.md), contest scoring
and pending-code retention to
[Ultimate Jutsu](../gameplay/characters/ultimate_jutsu.md#contest-objects),
task scheduling to [Resident task system](task_system.md), Save/Load to
[Save data](../game/save_data.md), and file services to
[Resident file and archive services](../game/files/runtime_services.md).

## Binary and evidence identity

Resident ELF/BTL identities and address rules belong to
[Retail game file identities](../game/files/file_identities.md#address-conventions).
`pad_library_version_tag` is `PsIIlibpad  3000`. Sony API identities
are strong ABI-correlated identifications, not recovered original symbols.

Supporting IOP evidence is the embedded `padman` IRX in
`@source_na2/MODULES/MODULES.BIN` (315,392-byte container). Its analyzed
45,056-byte image includes padding up to the following IRX and has SHA-256
`0DFC9FCBE832D10B172CAAE862920561EB919426307EEE671A1679A9D138CD64`.
It is ELF32 little-endian MIPS R3000 with tag `PsIIpadman  3000`.
Shared MCP `MODULES.BIN` maps only the first embedded module, not PADMAN.
Prior findings retain that image identity; annotating its code requires
the missing owning program and relocation evidence.

Addresses are live. PADMAN behavior is preserved without numeric code
citations because its runtime relocation is unestablished. Resident pad globals
are named in the ELF's zero-filled BSS block.

### Confidence guide

- **High, direct static evidence:** addresses, record/global offsets, call
  order, packet transformation, edge/repeat formulas, stick math, pressure
  copy/clear condition, configuration branches, vibration stack operations,
  and DMA-half selection.
- **High, ABI-correlated:** the `scePad*` identities, standard button/pressure
  names, and conventional `libpad` state labels. These match the compiled
  behavior and bundled PS2SDK source but are not symbols retained by the ELF.
- **Unproven dynamically:** real-time cadence, hardware/emulator presentation,
  observed pressure/rumble values, and whether statically unreferenced helpers
  can be reached through a computed mechanism.

## Ownership, initialization, and update order

`engine_pad_context` is the context-pointer slot. `engine_root_allocate`
allocates a `0x530`-byte context, constructs it, then initializes its two
`PadRecord` instances.

| Port / slot | Record | Live DMA area |
| --- | --- | ---: |
| 0 / 0 | `EnginePadContext.pads[0]` | `pad_port0_dma_snapshots` |
| 1 / 0 | `EnginePadContext.pads[1]` | `pad_port1_dma_snapshots` |

`pad_worker` initializes/opens/configures/actuates/closes both ports and
yields; ordinary packet decode belongs to `pad_update_all`.
Both opens must return 1 before either configuration machine runs or lifecycle
1 is published. Persistent port-1 failure can leave an opened, core-readable
port 0 without worker configuration. Shutdown closes port 0 before port 1,
then ends the library. These loops have no timeout/per-port failure isolation.

Cycle order:

1. `scheduler_update_loop` runs `engine_root_update`.
2. After display/flush, `pad_update_all` ages both stacks, then polls both
   ports through `pad_read_packet_words`.
3. Services and frame-gate processing precede the enabled
   `EnginePadContext.early_callback`.
4. Scheduled tasks run, including pad worker and front-end adapter.
5. `engine_root_finish_update` copies each public held word to
   `PadRecord.previous_public_held` when the normal-frame gate is open.

Core polling lies outside `EnginePadContext.frame_gate & 7`.
Only task flag `0x08` permits gated-cycle execution; the pad worker has it.
The callback, late held snapshot and ordinary front-end task are gated.
Core input/configuration can therefore advance while those consumers skip.

The callback sees core publication before front-end synthesis; the late
snapshot can include synthesized directions. `raw_held_history` stays the
physical/core history used for edges. Engine cycles are not proven one-for-one
displayed frames under all skip/stall modes.

## Publication lifetime and consumer snapshots

The shared pad words are a latest-sample publication, not an acknowledged
event queue. Every `pad_read_packet_words` call overwrites held, pressed, released,
repeat, and raw history, including on a zero-derived input update. Reading a
word does not clear it. Within a cycle multiple consumers can read the same
pressed/released mask; on the next unchanged physical sample the core edges
are zero even if an earlier consumer did not run. The late public-held
`PadRecord.previous_public_held` is a separate, normal-frame-gated store.

**Inference from those stores and gates:** a shared edge arising entirely
during skipped higher-level cycles is not retained for those consumers.
A button still held when they resume remains visible in held, but need not
remain visible as a core press. No claim about a live occurrence is made.

Battle adds a different retention boundary. The per-side complete update is `input_object_update` (BTL live `0x006F0EA0`).
It advances the history ring, copies the current resident held/pressed/released
words and stick outputs into one `0x18`-byte record, then calls `input_normalize_record` (live `0x006EF3C0`). That normalizer
rewrites both edges against the preceding normalized history held word.
Consequently battle edges represent changes between consumed history samples,
not preservation of each intervening core edge. Neither resident repeat nor
core raw history is copied. Each sample overwrites one ring record and leaves
the others until the ring wraps. Field layout, ring indices, normalization,
and matcher algorithms are owned by
[Action commands](../gameplay/combat/action_commands.md#battle-input-object-and-history).

The history phase runs in resident `battle_dispatch_phases` through the command controller. It runs when the `BattleState.first_phase_mask` contains
bit `0x0002`, or the object referenced by `battle_input_phase_override` has `BattleInputPhaseOverride.force_history == 1`.
A null owner/controller skips it. The controller/list wrappers reach `input_object_update`.
`battle_loop_active` calls mask collection `battle_collect_scheduler_masks` before that dispatcher
only when its state handler returns 0; return 2 skips the dispatcher, while
1/3 complete that branch. Thus a skipped history phase leaves its records
unchanged while the resident pad can continue publishing new samples.
The input object's fighter-state suppression flag zeroes logical output
after recording; it does not prevent the ring advance or held snapshot.

### Consumers in the front-end task

`resident_flow_dispatch` runs the analog adapter before its selected
handler and yields one update afterwards. State 3 reaches title handling;
state 4 reaches the manager's current mode, including Mode Select and running
battle. This orders that task, not independent threads. See
[Resident task system](task_system.md#manager-pass-and-ordering-boundary)
and [Battle lifecycle](../gameplay/session/battle_lifecycle.md#battle-update-cadence).

| Consumer | Snapshot/gate | Retention |
| --- | --- | --- |
| Title, `title_update` | Captures port-0 pressed once; selected states test `0x0820/0x0860` and pass it to title navigation | Invocation-local, no acknowledgement |
| Mode Select, `mode_select_update` | Before state switch rewrites `ModeSelectInput.port_pressed`, combined `pressed`, `repeat`, `held` | Children see latest invocation snapshot |
| Generic list, `list_collect_pad_input` / `list_handle_pad_input` | Source bits 0/1 select ports; `&3 == 0` skips handling. Pressed Circle/Cross accept/cancel; repeat Up/Down navigates | ORed arguments, no retained events |
| Character Select parent, `character_select_update` | Start joins, Cross cancels; sides processed in order with controlling port supplied | Later selectors can read the same edge; routing belongs to [Character Select](../game/character_select.md) |
| Selector, `character_selector_update` | State 1 with `state1_blocked`, or 5/9 with `state59_blocked`, returns before copying. Otherwise rewrites `CharacterSelectorInput.pressed/repeat/held/navigation`; countdown zero adds held to navigation, nonzero decrements with pressed-only navigation | Early return retains memory but skips handler; ordinary update overwrites |
| Support, `character_support_handle_input` | State 5 reads pressed Circle/Cross/Triangle and navigation directions | Navigation can include held with core repeat zero |
| Start detector, `battle_start_menu_input_side` | Eligible sides test pressed Start; result 1/2, later match wins; manager/session gates can skip | No stored pad snapshot |
| Start menu, `start_menu_input` (`0x0087C3F0`) | State 3 and resident-list ready. Selected port, or both for `StartMenuHost.input_source == 2`; Circle/Cross pressed, repeat joins navigation only when `repeat_countdown < 1`, otherwise it decrements | Shared pad words, without battle history |

Snapshots do not accumulate missed presses. Copied words do not imply an
additional pad poll. `manager_dispatch_state` runs
`battle_start_menu_update` before its battle state callback and mask
collection. The open wrapper `start_menu_update_draw` (`0x0087D940`)
dispatches state before presentation. The later session can suppress history
while the menu still reads shared pressed/repeat.
[Pause and start-menu control](../gameplay/session/pause_and_replay.md#resident-pause-controller-consumption)
owns suppression and lifecycle.

### Gameplay readers outside command history

`battle_dispatch_phases` services command input before fighters in phase 1;
the logical bridge belongs to
[Action commands](../gameplay/combat/action_commands.md#bridge-and-dispatch-order).
After phase-1/2/3 registries, first-mask bit `0x0400` and the contest
enable gate run `jutsu_contest_update`, independently of history advance.

| Contest reader | Input and local boundary |
| --- | --- |
| Command, `jutsu_command_update` | Shared human pressed decodes into `ContestCommandInput.pending` before lockout |
| Combo, `jutsu_combo_update` | Shared human pressed decodes into `ContestComboInput.pending` before lockout/rearm; rearm defers processing without clearing it |
| Timing, `jutsu_timing_update` / `jutsu_timing_score_side` | State 9 scoring decrements `ContestTimingInput.lockout`; reaching zero permits human pressed sampling, CPU sides use a generator |
| Turn, `jutsu_turn_update` | Right polar stick, left fallback below magnitude `0x20`; local angle/invalid sentinel, without digital repeat |

Command/Combo/Turn require `ContestInputState.active`, clear
`finishing`, state 9 and `time_bar_state == 1`; `cpu[side] == 0`
selects human input. Command priority is
`0x10,0x40,0x20,0x80,0x1000,0x4000,0x2000,0x8000` → codes 0..7;
Combo takes the first four → codes 0..3. Each side retains one decoded
command, not a mask queue. Latches preserve sampled input, not publications
missed behind outer gates; Timing does not sample while lockout stays positive.
Scoring/lifecycle belongs to
[Ultimate Jutsu](../gameplay/characters/ultimate_jutsu.md#contest-objects),
including [Command](../gameplay/characters/ultimate_jutsu.md#command-mode)
and [Combo](../gameplay/characters/ultimate_jutsu.md#combo-mode).

Direct BTL predicates `binding1_shared_press_a` (`0x00796A50`),
`binding1_shared_press_b` (`0x007FF520`) and
`binding1_shared_press_c` (`0x00806680`) also read shared pressed.
Their human branch uses `SharedBindingInputReader.side` and configured
binding 1, returning false for null bindings. The controlled branch can use
`controlled_press & 1` instead. Full registry placement is unresolved;
no relative scheduling order is assigned.

The jutsu-clash reader `interaction_pending_pair_call` (`0x0077C270`)
intersects each side's shared pressed with its clash mask and increments
its counter on any match. It counts matching-publication updates, not
physical presses.
[Battle statistics](../gameplay/session/battle_statistics.md#jutsu-clash-outcome-selection-and-callback-lifetime)
owns the outcome contract.

`engine_clear_early_callback` clears `EnginePadContext.early_callback`
during construction. No active nonzero installation was found; indirect
writers remain possible. Conditional ordering is established without a
proved ordinary battle reader there.

## Per-port record

`PadRecord` in `types.h` owns the `0x78`-byte layout. Named fields
cover DMA, `PadPacket`, actuator state, `VibrationEntry` storage,
counters, pressure, polar sticks, late held and public masks. Packet-derived
masks use low 16 bits of 32-bit words; the adapter can rewrite public words
without changing `raw_held_history`.

Opaque byte `+0x46` has no proved meaning: initialization clears it and
polling preserves low bits 0/1 without branching. Padding `+0x4B` has no
identified access.

### Initializer defect

`pad_initialize_record` is not bytewise zero initialization: the pressure
loop clears only its first byte repeatedly, packet/retry storage is not
explicitly cleared, and upper six vibration-flag bits survive.
Normal polling copies/clears all twelve pressures; normal retry increments
first reset the counter. No persistent effect from the pressure/retry
omissions or preserved flag bits is established. Before a full packet copy,
bytes beyond the latest length can retain earlier memory contents.

## Raw PS2 packet and game mask

`pad_library_read` copies `PadDmaSnapshot.length` bytes from the selected
snapshot's packet to `PadRecord.packet`.
`PadPacket` names status/ID, active-low button bytes, right then left X/Y,
twelve pressure bytes and twelve reserved bytes. Only the first 20 bytes have
a proved resident decode.

Neither EE layer adds a local size guard. The embedded `pad_library_read` trusts the
DMA snapshot's 32-bit length and copies exactly that many bytes into the
caller's 32-byte packet area. `pad_read_packet_words` tests only whether the returned
length is nonzero before reading packet ID and button bytes; it does not require
a minimum of four bytes (or eight before reading sticks). A malformed short
snapshot could therefore mix newly copied and stale packet bytes, while a
length above 32 would overrun the wrapper packet field. The wrapper also never
checks `PadPacket.status`; state, nonzero read length, and packet ID alone
control classification/decode.

The exact bundled IOP `padman` producer narrows that concern on the ordinary
path. Its packet producer returns exactly 32 and writes
status byte 0 when its per-slot data-ready word equals 1; otherwise it writes a
leading `0xFF`, zeroes the other 31 staging bytes, and returns length 0. Thus
this producer gives the EE client only complete 32-byte packets or no packet,
not partial lengths. The unchecked EE boundary still matters for corruption,
hooks, or a replacement IOP producer; it was not exercised dynamically.

For an exact `0x79` pressure packet, that same IOP routine also reconciles each
of packet bytes `+8..+19` with its corresponding active-low digital bit. If the
button is not held it forces the pressure byte to 0; if the button is held but
the pressure byte is 0 it raises it to 1; all other nonzero pressure values are
preserved. The mapping is the standard order in the pressure section below.
Consequently a pressure-ready packet delivered by this bundled module cannot
represent a released button with nonzero pressure or a held button with
exactly zero pressure.

The held mask is formed exactly as:

```text
held = ~((packet[2] << 8) | packet[3]) & 0xFFFF
```

That explicit byte order makes the game's masks byte-swapped relative to a
little-endian `padButtonStatus.btns` word:

| Game mask | Button | Game mask | Button |
| ---: | --- | ---: | --- |
| `0x0001` | L2 | `0x0100` | Select |
| `0x0002` | R2 | `0x0200` | L3 |
| `0x0004` | L1 | `0x0400` | R3 |
| `0x0008` | R1 | `0x0800` | Start |
| `0x0010` | Triangle | `0x1000` | Up |
| `0x0020` | Circle | `0x2000` | Right |
| `0x0040` | Cross | `0x4000` | Down |
| `0x0080` | Square | `0x8000` | Left |

The raw transformation is directly proven. Button names follow the standard
PS2 pad packet and are corroborated by resident consumers, including menu code
that treats `0x1000/0x4000` as vertical directions and `0x20/0x40` as
accept/cancel.

## Held, edges, and repeat

For a newly decoded 16-bit `held` value, `pad_read_packet_words` computes:

```text
pressed  = ~raw_history & held
released =  raw_history & ~held
```

It then updates repeat state as follows:

1. If `held` is zero or differs from `raw_history`, `repeat=held` and the
   one-byte counter is reset to zero.
2. On the next 15 unchanged nonzero updates, the counter advances from 0 to 15
   and `repeat=0`.
3. On the 16th and every later unchanged update, `repeat=held`; the counter
   remains 15.
4. Finally, both `PadRecord.held` and `raw_held_history` receive
   `held`.

Consequently `PadRecord.repeat` is not a periodic pulse. It exposes the full held mask on
the initial/change update, suppresses it for 15 unchanged updates, and then
exposes it continuously until the mask changes. A change in any held button
puts the entire new held mask in `repeat`, not only the newly pressed bits.

## Connection and configuration behavior

The wrapper-facing `pad_library_get_state` values are the usual `libpad` states:

| Value | State |
| ---: | --- |
| `0` | disconnected |
| `1` | finding pad |
| `2` | finding controller protocol (`FINDCTP1`) |
| `3` / `4` | reserved/unnamed in this client |
| `5` | executing command |
| `6` | stable |
| `7` | error |
| `99` | NA2's unopened-port sentinel from `pad_library_get_state` |

The compiled debug-name table `pad_state_names` literally contains
`DISCONNECT`, an empty string for state 1, `FINDCTP1`, empty strings for 3 and
4, then `EXECCMD`, `STABLE`, and `ERROR`. “Finding pad” for value 1 is the
ABI-correlated conventional name rather than a retained literal. The adjacent
request-state table names 0 `COMPLETE`, 1 `FAILED`, and 2 `BUSY`.

The embedded `pad_library_get_state` normally returns `PadDmaSnapshot.state`, but it
maps raw stable state 6 plus `PadDmaSnapshot.request_state == 2` to exposed state 5.
Thus a configuration request in flight makes an otherwise stable
pad non-readable to `pad_read_packet_words`, producing the zero-derived frame described
below. `pad_library_get_request_state` returns complete (0) for an unopened slot.

`pad_read_packet_words` accepts packet data only in states 2 and 6. State 0 resets the
wrapper state to 1 and clears the cached mode. Every update starts with zero
held, zero stick outputs, and—unless an exact pressure packet is accepted—zero
pressure. Therefore a disconnect, configuration interval, failed/empty read,
or other non-readable state clears public held. On the first such update,
released is the preceding raw-held mask; later zero-input updates have no
release edge. Reconnection does not expose input until mode negotiation returns
to ready state `0x40`.

`PadRecord.packet` is not cleared on disconnect or a
non-readable update. It may remain stale while all derived/public outputs are
zero; consumers should use the derived fields or validate state rather than
treating the packet buffer as fresh.

The IOP read worker accepts a read
reply only when the transport succeeds, response marker byte 2 is `0x5A`,
response ID byte 1 equals the cached controller ID, and that ID is not `0xF3`.
An accepted response copies all 32 bytes to the stable button buffer, marks data
ready, and exposes state 2 while `modeConfig == 1` or state 6 otherwise. It
also completes a busy ordinary request only after the slot's run-task word has
returned to zero.

A transport/read failure instead clears data-ready, exposes state 7, increments
`PadDmaSnapshot.find_retries`, and adds the
driver's reported error contribution to a local accumulator. The accumulator
resets after a successful read; once it reaches at least 10, the update worker
hands the slot to its query worker. A successful transport with a bad marker,
mismatched ID, or ID `0xF3` skips that threshold and hands over immediately in
state 5. The IOP discovery worker clears cached mode,
model, capabilities, button masks, direct-actuator size, data-ready, and retry
count before probing. While no supported pad is found it repeatedly publishes
state 0 and marks the slot disconnected; once a pad is found it enters state 5
and rebuilds configuration.

This creates a useful distinction at the resident layer. Transient IOP state 7
or 5 zeroes all derived input but does not itself change `PadRecord.configuration_state`; only eventual exposed state 0 performs the wrapper's disconnect
reset to state 1/mode 0. During that transient interval the wrapper can still
look ready to its vibration enqueue/state-machine gates even though input is
zero. The IOP query takeover itself clears its six live actuator bytes and
restores alignment `[00,01,FF,FF,FF,FF]`; that is internal-state evidence, not
a measured guarantee about when a detached physical motor stops.

Disconnect does not immediately clear the vibration stack or send an actuator
stop. The wrapper changes only configuration state/mode there, while
`pad_age_vibration` continues aging the current vibration segment each update and
the worker stops entering its ready-state actuator branch. On an ordinary
DualShock reconnection, successful actuator alignment resets depth to zero,
marks the stop sentinel dirty, and causes the state machine to submit a zeroed
motor pair before accepting new queued effects. This sequence is statically
proven; behavior of a physically detached motor was not tested.

That reset is path-dependent. Neither disconnect nor classification state 2
clears `PadRecord.actuator_state` or `vibration_depth`; the common path into
actuator probe state `0x30` clears the substate, and successful alignment later
clears the depth. Pad type 5 instead jumps straight from classification to
ready, and the 21-immediate-failure pressure fallback also jumps directly to
ready. Those two paths can therefore inherit the preceding actuator substate,
stack, and dirty flags after a reconnect or reconfiguration. The ready-state
actuator branch immediately resumes processing whatever survived. This is a
static state-persistence result; whether a replacement type-5 device responds
to an inherited direct command was not tested.

`PadRecord.configuration_state` advances as follows:

| State | Static role |
| ---: | --- |
| `0x00` | unstarted; ordinary poll skips `libpad` |
| `0x01` | port opened or disconnect observed; wait for a readable packet |
| `0x02` | classify the packet mode and start/restart configuration |
| `0x10..0x12` | turn a digital pad type 4 toward locked DualShock mode with `pad_library_info_mode`, `pad_library_set_main_mode(1,3)`, and request-state waits |
| `0x20..0x22` | probe and enter native pressure mode for type 7 |
| `0x30` | probe the two expected actuators |
| `0x31..0x32` | align actuators with `[00,01,FF,FF,FF,FF]` and wait for completion |
| `0x40` | ready; packet decode and vibration enqueue are enabled |
| `0x50` | port closed; ordinary poll skips `libpad` |

Pad type 5 is accepted directly as ready. Type 7 takes the pressure path. Type
4 uses main-mode negotiation and then restarts classification. The actuator
probe requires two actuators with exact `(function,subfunction,size)` tuples
`(1,2,0)` and `(1,1,1)` before vibration is enabled. A stable controller that
does not match that exact capability signature becomes ready with vibration
disabled.

`PadRecord.configuration_retries` is narrower than a general timeout. It is
reset on entry to the main-mode, pressure, and actuator-alignment stages. The
three setter-call paths increment it after an immediate call failure, retry
while it is below `0x15`, and fall back when it reaches `0x15`. A request-state
result of failed instead moves back one setter state without itself incrementing
the byte; busy simply waits. Consequently repeated request failures can cycle
indefinitely even though immediate setter failures have the `0x15` fallback.
The pad worker's init/open/close/end loops are independently unbounded.

The pressure fallback has a further static quirk. State `0x21` sets the record's
`PadRecord.pressure_configured` to 1 *before* calling the press-mode setter. If
21 consecutive immediate setter calls fail, the state machine enters ready
state `0x40` without clearing that flag. A continuing `0x73` packet therefore
causes the next core poll to return the record to classification state 2 and
publish a zero-derived frame, after which the worker starts another pressure
attempt batch. The `0x15` limit is consequently not a permanent fallback from
an attached pressure-capable pad: persistent immediate failures can produce
repeated 21-attempt batches separated by zero-input reclassification frames.

Actuator probe state `0x30` contains a distinct branch oddity. It normally
checks the capability tuple only when the last exposed pad state stored in `PadRecord.last_state` is stable (6). If that value is not 6, it increments `PadRecord.configuration_retries` once; a
value below `0x15` then advances directly to actuator alignment, clears the
counter, and attempts `[00,01,FF,FF,FF,FF]` without having proven the tuple.
Only a value already reaching `0x15` takes the vibration-disabled ready
fallback. All ordinary entrances to state `0x30` first clear `PadRecord.configuration_retries`, so the
21-count non-stable fallback is not normally reachable: the first non-stable
pass takes the alignment branch.

When pressure negotiation has succeeded, a later ready-state packet ID `0x73`
forces reconfiguration. Packet ID `0x79` is the only packet for which pressure
values are retained. Reclassification is checked before the ready-state decode,
so the triggering `0x73` frame publishes zero held/sticks/pressure and produces
release edges for the preceding held mask. The first readable packet after
state 1, and a newly observed transition to mode nibble 7, are likewise used
only to enter configuration rather than as an input frame.

The mode-change test is asymmetric: while already configured, a changed packet
nibble forces classification only when the new nibble is 7. A changed nibble
of 4 or 5 without an intervening exposed disconnect does not update the cached
mode or restart setup; the current packet still controls whether sticks are
decoded, and pressure is cleared unless the exact ID is `0x79`. Normal device
replacement is expected to pass through state 0, so this hot-swap edge remains
static-only.

`pad_worker` owns the broader worker lifecycle byte `pad_worker_lifecycle`: it sets
0 while records are initialized, 1 after both ports open, waits for an external
2 shutdown request, then closes both ports, calls `pad_library_end`, and writes 3. No
direct writer of value 2 was found in the resident evidence.

## Stick conversion

For each stick, `pad_stick_angle_magnitude` (`0x00114B40`) receives unsigned X/Y bytes,
stores a float angle and byte magnitude, and returns whether magnitude is
nonzero. `pad_read_packet_words` routes packet `[6,7]` to the left outputs and `[4,5]`
to the right outputs when the mode nibble is 5 or 7.

Let `dx=x-128`, `dy=y-128`. Each axis is adjusted independently:

```text
raw 0..71    -> adjusted = raw - 72       (-72..-1)
raw 72..184  -> adjusted = 0
raw 185..255 -> adjusted = raw - 184      (+1..+71)
```

Magnitude is:

```text
min(255, floor(sqrt(adjusted_x^2 + adjusted_y^2) * 255 / 72))
```

The square per-axis deadzone is therefore inclusive `-56..+56`; radial
magnitude outside it is capped at 255. If the result is zero, angle and
magnitude are both zero. Otherwise the angle convention is:

| Direction | Representative raw X/Y | Angle |
| --- | --- | ---: |
| Up | `128,0` | `+pi` or `-pi` |
| Right | `255,128` | `-pi/2` |
| Down | `128,255` | `0` |
| Left | `0,128` | `+pi/2` |

The endpoint scaling is slightly asymmetric. Raw 0 maps to adjusted `-72`, so
a negative full-scale cardinal axis reaches magnitude 255. Raw 255 maps to only
`+71`, so a positive full-scale cardinal axis truncates to magnitude 251.
Either first sample outside the deadzone (raw 71 or 185 on one axis) maps to
magnitude 3. Diagonal values can still hit the 255 cap on either side.

A subtle implementation detail is that magnitude uses the deadzone-adjusted
axes, while angle uses the original centered `dx/dy`. An off-axis component
that falls inside the per-axis deadzone can therefore still tilt the reported
angle whenever the other axis makes the total magnitude nonzero.

## Native pressure

Only a ready-state packet whose ID byte is exactly `0x79` copies `PadPacket.pressure` to `PadRecord.pressure`. All 12 outputs are cleared on every other
update. Their standard packet order is:

```text
Right, Left, Up, Down,
Triangle, Circle, Cross, Square,
L1, R1, L2, R2
```

The order is established both by the `libpad` packet contract and by the exact
IOP producer's per-byte reconciliation against game-order digital masks
`2000,8000,1000,4000,0010,0020,0040,0080,0004,0008,0001,0002`.
The resident wrapper itself treats the range as an opaque 12-byte copy and no
distinct pressure consumer was needed to establish polling behavior.

## Analog-to-D-pad compatibility

### Active front-end path

`pad_frontend_analog_adapter` (`0x001E0D20`) runs inside front-end task `resident_flow_dispatch`. It runs at the top of that task's steady loop,
before its state-specific handlers and before the task yields. This proves its
placement for that front-end task only; it is not part of the core poll and is
not proven to run for every resident/overlay consumer.

For each port it:

1. Reads public held. If physical D-pad bits `0xF000` are already nonzero, it
   gives them priority, resets its private repeat counter, and snapshots the
   full public mask without synthesizing anything.
2. Calls `pad_direction_from_analog` with the left-stick angle and magnitude.
3. Synthesizes a D-pad direction only when magnitude is strictly greater than
   `0xA0`.
4. Replaces only D-pad bits in pressed and released, updates public held, and
   recreates the same 15-update repeat delay with private history.

It does not touch the right stick, `PadRecord.raw_held_history`, or the
physical packet. Its repeat comparison uses the full augmented mask, not only
the D-pad nibble. A simultaneous non-D-pad button change can therefore reset
this adapter's repeat delay and can put the complete augmented held mask in
the repeat field. Keeping private history even on physical-D-pad frames also
lets a transition from a physical direction to the same synthesized stick
direction avoid a false release/press pair.

The unsuccessful synthesis branch matters for release publication.
`pad_direction_from_analog` returns zero at magnitude `<=0xA0`; the adapter then resets only its private counter
and saved mask. It does not rewrite public held, pressed, released or repeat.
The preceding core poll has already replaced those public words. **Inference:**
returning a stick-only direction to neutral/below threshold does not publish
that synthesized direction's release edge in this adapter, because the raw
core history never contained it. Switching between qualifying stick sectors
does pass through the D-pad release/press rewrite. Battle history instead
recomputes releases against its preceding normalized held sample, so it can
represent the neutral transition when its input phase consumes it.

Under `pad_stick_angle_magnitude`'s scaling, `magnitude > 0xA0` requires adjusted radial
distance large enough to truncate to at least 161 (about 45.46 adjusted units).
On a single cardinal axis the first qualifying raw value is therefore 26 on
the negative side or 230 on the positive side; diagonal motion can qualify
with smaller per-axis components.

Private state is `pad_frontend_repeat_counters` (two counters) and
`pad_frontend_held_history` (two saved masks). Both arrays lie in the zero-filled
portion of the resident load segment, so their initial state is zero without an
explicit constructor.
`pad_direction_from_analog` chooses and ORs a sector with:

```text
sector = ((((int)(((angle + pi) * 8) / pi)) + 1) & 0xF) >> 1
held |= angle_to_direction_table[sector]
```

This produces eight nominal 45-degree sectors with boundaries halfway between
the canonical directions; sector 0 wraps across `-pi/+pi`.

The sector table at `angle_to_direction_table` is:

| Sector | Canonical angle | Mask | Direction |
| ---: | ---: | ---: | --- |
| 0 | `+/-pi` | `0x1000` | Up |
| 1 | `-3pi/4` | `0x3000` | Up + Right |
| 2 | `-pi/2` | `0x2000` | Right |
| 3 | `-pi/4` | `0x6000` | Right + Down |
| 4 | `0` | `0x4000` | Down |
| 5 | `+pi/4` | `0xC000` | Down + Left |
| 6 | `+pi/2` | `0x8000` | Left |
| 7 | `+3pi/4` | `0x9000` | Left + Up |

### Unreferenced twin and battle reverse helper

`pad_unused_analog_adapter` has the same behavior as
`pad_frontend_analog_adapter`, with separate zero-filled private counters
in `pad_unused_repeat_counters` and saved masks in `pad_unused_held_history`.
No direct caller or stored pointer was found; its intended context is unresolved.

`pad_analog_from_direction` maps valid held direction nibbles to the same
angle convention with magnitude `0xFF`; all other nibbles produce zero
angle/magnitude. No resident caller was found. Battle
`input_normalize_record` invokes it when normalized stick magnitude is
zero and digital held exists.

`direction_to_angle_table` accepts exactly
`1=Up (+pi),2=Right (-pi/2),3=Up+Right (-3pi/4),4=Down (0),
6=Right+Down (-pi/4),8=Left (+pi/2),9=Left+Up (+3pi/4),
C=Down+Left (+pi/4)`. The remaining nibbles, including opposite pairs and
three/four-way combinations, use invalid sentinel 4.0.

## Vibration and actuator scheduling

`pad_enqueue_vibration` schedules a small-motor on/off bit and large-motor
intensity. `vibration_enqueue_preset` reads the packed `VibrationPreset`
values in `vibration_presets`:

| Index | Small | Large | ms | Index | Small | Large | ms |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 1 | 128 | 125 | 11 | 1 | 0 | 125 |
| 1 | 1 | 152 | 150 | 12 | 1 | 0 | 126 |
| 2 | 1 | 176 | 175 | 13 | 1 | 0 | 127 |
| 3 | 1 | 208 | 200 | 14 | 1 | 0 | 128 |
| 4 | 1 | 240 | 250 | 15 | 1 | 0 | 129 |
| 5 | 1 | 255 | 200 | 16 | 0 | 215 | 125 |
| 6 | 1 | 64 | 125 | 17 | 0 | 225 | 135 |
| 7 | 1 | 80 | 137 | 18 | 0 | 235 | 145 |
| 8 | 1 | 96 | 150 | 19 | 0 | 245 | 155 |
| 9 | 1 | 112 | 175 | 20 | 0 | 255 | 165 |
| 10 | 1 | 128 | 200 |  |  |  |  |

An enqueue is accepted only when:

- the global gate at `vibration_enqueue_enabled` is nonzero;
- the record is ready (`PadRecord.configuration_state == 0x40`); and
- `PadRecord.actuator_state` is nonzero.

The clean ELF initializes `vibration_enqueue_enabled` to 1. Its only direct clean-resident
reference is this read in `pad_enqueue_vibration`; no resident writer was found. It is
therefore an enabled-by-default enqueue gate whose external/overlay control, if
any, remains unproven.

Milliseconds become nominal 60 Hz ticks using:

```text
ticks = (milliseconds * 3 + 25) / 50
```

For table indices 0 through 20 above, the resulting tick counts are
`[8,9,11,12,15,12,8,8,9,11,12,8,8,8,8,8,8,8,9,9,10]`. Every shipped
preset therefore begins above the actuator worker's `remaining > 5` send
threshold. For a custom nonnegative duration, 92 ms is the first value that
converts to six ticks; 0..91 ms converts to at most five and can never itself
pass that send test, although such an enqueue can still prune/subtract older
segments and change dirty flags. A zero-tick top is removed by the next
maintenance pass before it can be transmitted.

`VibrationEntry` stores remaining display ticks, dirty bit 0, small-motor
bit 1 and large intensity. Entry 0 is the stop sentinel; entries 1..3 form a
maximum-depth-three LIFO residual timeline:

- on enqueue, every older entry with remaining time less than or equal to the
  new duration is deleted;
- the new duration is subtracted from every older entry that would outlast it;
- the surviving entries are compacted and the new command is pushed on top;
- the previous top is marked dirty so that its residual tail is resent after
  the override ends.

Older commands therefore do not pause. Their residual tails represent how
long they would still have been active after the newer override's time span.
Only the current top is aged by `pad_age_vibration`, saturating at zero;
zero-duration tops are popped at the start of the next maintenance pass.

Aging subtracts `EnginePadContext.display_divisor`. The display wait uses
that divisor and the setter resets `display_counter`. Initialization sets 1;
the front-end task sets it to 2 immediately before entering its permanent main
state loop. This establishes that vibration durations are stored in 60 Hz
display ticks rather than update-call counts: a front-end update normally ages
the active segment by two ticks while the update loop is paced by two display
counts. The same distinction does **not** apply to the button repeat counter,
which increments once per `pad_read_packet_words` poll. Real elapsed timing
remains unobserved.

At full depth, if all three older tails survive pruning, the code cannot push a
fourth entry even though it has already reduced those tails and marked the old
top dirty. The requested new command is dropped, while the shortened old top
can be retransmitted. This edge case is statically visible but has not been
reproduced at runtime.

`pad_configure_actuators` owns configuration and actuator transmission. Once configured,
its actuator substates are:

| `PadRecord.actuator_state` | Meaning |
| ---: | --- |
| `0` | unavailable/disabled |
| `1` | idle; inspect the stop sentinel or current top |
| `2` | submit the zero/stop pair |
| `3` | submit the current active pair |
| `4` | one-worker-pass delay that samples the ordinary `libpad` request result after a successful EE-side submit |

It sends a dirty live top only while more than five ticks remain. When the
stack empties, dirty entry 0 causes `[0,0]` to be sent. The lower-level call is
`pad_library_set_actuator_direct`; alignment earlier established
`[00,01,FF,FF,FF,FF]`.

`pad_library_set_actuator_direct` itself does not mark request state busy: it starts the
separate direct-DMA path. Substate 4 nevertheless reads the ordinary pad
request state on the following worker pass. Complete returns to idle, failed
returns to idle and increments `PadRecord.actuator_failures`, and busy leaves substate 4 in
place. Because neither the EE direct-DMA submitter nor the exact IOP direct
consumer changes that request state, this is not an acknowledgement of the
motor command. On the normal ready path it merely observes the completed
ordinary configuration request left by actuator alignment. An active-pair
EE-side submission failure also increments `PadRecord.actuator_failures` and routes through the stop
state; a stop submission failure simply remains in the stop state. No threshold
or other consumer of `PadRecord.actuator_failures` was found in the resident, so it is a wrapping
diagnostic count rather than a retry limit.

The active command's dirty bit is cleared before the submit attempt. Therefore
an active-pair return of zero—including the lower layer merely reporting that
its previous SIF DMA is still in flight—is not retried as an active command.
The wrapper increments `PadRecord.actuator_failures`, enters stop substate 2, and keeps retrying the
zero pair until it can be submitted; when it returns to idle, the still-live
top is no longer dirty. By contrast a failed stop retains substate 2 and is
retried. This makes direct-DMA contention capable of dropping a vibration
segment and replacing it with an eventual stop, not merely delaying the
segment.

The IOP read worker consumes the newest of two `PadDirectCommand` halves:
unsigned sequence comparison selects half 1 only for `seq0 < seq1`, ties half 0.
A nonzero `command` submits exactly six `payload` bytes, then clears the
command even if application refuses it. The `size` field is not validated.

The IOP apply routine accepts a direct command only while its slot is in
configuration level greater than 1 and current-task state 1. Before copying the
six bytes to the live actuator data it enforces a cross-controller power budget.
The IOP other-slot current summation sums the term-4/current value for every nonzero aligned actuator
on all other open slots; the IOP current limiter then considers the current slot's six
alignment entries in order and zeroes any requested actuator byte that would
raise the cumulative value above `0x3C`. Any nonzero intensity consumes the
actuator's whole reported term-4 value for this test; it is not scaled by the
large-motor byte. With NA2's `[00,01,FF,FF,FF,FF]` alignment, the small motor is
considered before the large motor. A command can consequently be accepted by
the EE DMA layer yet be silently discarded by IOP state gating or partially
zeroed by the PADMAN power cap.

The IOP command-half comparison has the same non-modular-counter limitation as
the EE input-half selector. When a direct-command sequence wraps from
`0xFFFFFFFF` to 0, the freshly written even half appears older; the following
sequence selects the other half and the wrapped command can be lost before its
half is overwritten. This requires roughly 2^32 direct submissions and is a
latent static edge, not a practical observed failure.

## Resident soft-reset check

No recognizable resident controller-combination reset was found.
Canonical IGR literals `0x0F09,0x090F,0x0F08,0x0F06,0x0F0F` and game
reset/reboot strings were absent in the bounded resident search.
`os_load_exec_wrapper` and `os_exec_browser_wrapper` reach OS relaunch
services without an identified direct caller or stored pointer.
`frontend_slideshow_update` changes state on Start; its separate exit
ancestry was a vector-bounds fatal path. This negative result does not exclude
indirect/overlay reset; overlays were not surveyed for that check.

## Embedded `libpad` boundary

Annotation names identify strongly recognized Sony API behavior.
`PadClientSlot`, `PadDmaSnapshot` and `PadDirectCommand` own layouts.
The snapshot names packet/direct/alignment data, four actuator rows then four
combination rows, four modes, generation/retries/length, configuration/model/
task/state bytes and packed requested/supported button masks.
Opaque snapshot `+0x6C` is cleared on open and set to 1 at the end of one
IOP configuration worker; its external meaning remains open. The final three
bytes have no identified producer write/linked reader. Direct/alignment data,
retries, mode/lock/direct-size/run-task/status70 and requested-mask outputs
have no identified linked EE reader.

| Live storage | Layout / role |
| ---: | --- |
| `pad_primary_rpc_client`, `pad_secondary_rpc_client` | Two `0x28`-byte SIF RPC clients |
| `pad_client_slots` | Eight `PadClientSlot` records, two ports × four slots |
| `pad_direct_commands` | Eight `PadDirectCommand` blocks |
| `pad_rpc_buffer` | Shared `0x80`-byte synchronous RPC buffer |
| `pad_dma_callback_gp` | Saved callback GP |
| `pad_dma_completion_callback` | Optional callback pointer |

These locations lie in the resident ELF's zero-filled BSS block. Slot `unused`
words are cleared with no identified linked use.

`pad_library_init` binds servers `0x80000100/0x80000101` indefinitely,
requires module-version high byte 4, then initializes ports.
`pad_library_initialized` is write-only, set before binding and cleared
only by logical-success end. `pad_library_diagnostics_enabled` starts at 1
and gates version/alignment/already-open/direct-DMA diagnostics.
Nonnegative port-init transport registers SIF `0x80000019` even with
logical reply zero. Any nonnegative end transport removes that handler
before examining reply; only reply 1 clears initialized bookkeeping.

Each input DMA area is `0x40`-aligned and has two `0x80` snapshots.
Open initializes both generations/lengths to zero, state 5, request 2 and
packet bytes to `0xFF`. `pad_select_dma_snapshot` compares signed
generations: half 1 only if half 0 is smaller, ties half 0.
The IOP uses pre-increment even generations for half 0, odd for half 1, then
advances its counter. No modular ordering handles
`0x7FFFFFFF → 0x80000000`; the newer half can appear older for one interval,
a latent very-long-lived-counter edge.

Direct blocks hold sequence/command/size and six payload bytes.
`pad_library_set_actuator_direct` writes command 1 and size 6;
`pad_submit_direct_dma` increments sequence, cache-syncs the
`0x20`-byte block and sends to alternating IOP destinations.
An in-flight prior DMA or zero submission ID fails without queuing another.
Input snapshots and direct commands are separate two-half paths.
The direct setter requires current task 1 but does not first check open:
before open null-area selection is possible, after close retained pointers
can be reused. Game ready/substate gates prevent ordinary calls there.
These compiled APIs do not bounds-check port/slot.

One game pad worker serializes init/open/configure/close/end through the
shared RPC buffer, which has no internal lock. Ordinary reads use DMA;
direct submission uses per-slot blocks. This bounded call-graph serialization
does not establish general thread safety for additional callers.

Mode metadata requires open/current task 1/request not busy. Selectors return
mode nibble (`0xF3 → 0`), current mode entry/offset or count/indexed entry;
current-entry/offset access rejects configuration 1. Actuator/combination
metadata also requires configuration at least 2. Button-mask metadata also
requires model at least 2; pressure support tests exact `0x0003FFFF`.
Mode/actuator/combination access special-cases −1 but otherwise checks only
upper bounds, accepting out-of-contract more-negative indices before tables.
Combination selectors −1/0/1/2 access four bytes; the contiguous metadata
also appears as eight rows to the actuator accessor.

Successful RPC setters mark ordinary request busy; direct submission uses
DMA without changing that request. The frame-count/combination helpers,
pressure-exit wrapper, state formatters, Vref/warning setters and port/slot
maxima queries have no identified game caller.
The request formatter permits 3 despite its null fourth table entry,
passing null to string copy; this is latent unused-library behavior.

The client reserves two ports/four slots but the game uses only ports 0/1,
slot 0; no resident multitap path was found. Legacy connection RPC `0x11`
has no EE wrapper and no case in this IOP dispatcher, which sends it to
invalid-function handling. Connectivity derives from state queries.

After nonnegative RPC transport, open marks the EE slot open and installs
pointers before logical reply; close similarly clears open before reply.
The game worker requires reply 1. Logical zero can wedge retries because
the next attempt is rejected locally without RPC. Zero open leaves wrapper
state 0 despite low-level open; zero close can leave wrapper ready despite
low-level closed. Sentinel 99 then publishes zero without disconnect reset.
Vibration may still enqueue/age locally while the stuck close loop never
services transmission. These failure replies are unobserved.

`pad_set_dma_completion_callback` returns the previous callback.
Null clears it and retries RPC `0x18` value 0 until transport succeeds;
first nonnull installation sends 1, then saves callback/caller GP under an
interrupt-safe critical section. Its exact public Sony API name is unknown.
The IOP value-0 path transfers ordinary snapshots without completion command.
Value 1 waits for completion-aware batch DMA and sends `0x80000019`
with the IOP VBlank counter only when at least one open slot contributed.
`pad_dma_completion_handler` supplies that counter, not a port/pad pointer,
to the callback. No game installation was found; port initialization registers
the SIF handler.

NUN5 `SLES_556.05` has the same tag and instruction-identical library
sequence, shifted by `0xDC0`. Its annotated `pad_library_init`
(`0x00174E58`) corroborates NA2 library identity without proving NUN5's
higher-level wrapper behavior.

### Matching IOP PADMAN function map

Prior embedded-module research covers direct-command selection, snapshot
batch construction, VBlank wake/counter, current summation/limiting,
read/discovery workers, module initialization, port open/close, packet/pressure
normalization, actuator/combination/mode metadata, direct application, warning
and completion-mode setters, and the main `0x80000100` RPC dispatcher.

No owning PADMAN MCP program or runtime relocation is available. Its behavior
and exact image identity remain here without module-relative code citations.

## Resident function map

Names, prototypes, comments and live entries are in
`@annotations/NA2/SLPS_258.37/symbols.tsv`; battle readers are in
`@annotations/NA2/BTL.BIN/symbols.tsv`. Layouts are in
`@annotations/NA2/types.h`.

## Useful negative results and remaining uncertainty

- The work is static-only. Update cadence, disconnect presentation, pressure
  values, vibration timing, and adapter behavior have not been live-tested.
- Record `+0x46` remains semantically opaque. `pad_initialize_record` initializes it to
  zero; `pad_read_packet_words` merely snapshots it and writes back `value & 3` without
  branching on either surviving bit. No other direct clean-resident access to
  the two context instances was found, so bits 0/1 are preserved storage with
  no proven resident effect.
- No clean-resident writer of pad-worker lifecycle value 2 in
  `pad_worker_lifecycle` was found. An overlay or indirect path may own shutdown.
- No statically recognizable resident soft-reset/controller combo was found;
  the resident OS relaunch wrappers are unreferenced library code.
- `pad_unused_analog_adapter` has no proven caller in the clean ELF. The reverse helper
  `pad_analog_from_direction` has no proven resident caller but is called by BTL input
  normalization.
- No active right-stick-to-digital adapter was found; the proven adapter uses
  only the left stick.
- The wrapper reserves 32 raw packet bytes, but only offsets through pressure
  byte 19 have a proven resident decode.
- `pad_library_set_vref`, `pad_library_set_warning_level`, the port/slot maxima queries,
  `pad_library_exit_pressure_mode`, and the callback/RPC-`0x18` path have no NA2 caller.
- `pad_library_init` can wait indefinitely for both RPC binds; the pad worker's
  init/open/close/end retry loops likewise have no static timeout.
- Adventure-mode input consumers were not inspected.

## Provenance

Pointer-slot xrefs do not establish all GP-relative references or computed
calls. PADMAN findings are bound to the exact image identified above;
its runtime relocation and owning MCP program remain unavailable.
