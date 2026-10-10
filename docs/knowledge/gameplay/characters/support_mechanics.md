# Battle support mechanics

## Research coverage

Established for retail NA2 (`SLPS-25837`): selection, Linked Mode, request/gauge
gates, common lifecycle, contact exits, notifications, manager passes, teardown,
ordinary attack-record construction and selected `0x0A/0x3F` script/effect
interfaces. Orochimaru 89's indexed recommendations, exclusions, code/recharge
overrides and linked-attack admission are established; a donor NUN4 equivalent
is not established. Open: full subclass payloads, scheduler-gate meanings,
resource lengths/event streams, character names for
numeric IDs, notification frequency, and retained-source lifetime safety.

Names come from `@annotations/NA2`; annotation comments carry per-routine
details. Timing counts eligible calls, not seconds.

Related owners: [Battle entities](../session/battle_entities.md#dynamic-support-object-owner)
(allocation, common ownership, factory tables and identifier allocator),
[Practice mode](../modes/practice_mode.md#rows-local-values-and-manager-storage)
(Linked Mode), [Battle HUD](../session/battle_hud.md#support-gauge),
[Battle lifecycle](../session/battle_auxiliary_services.md#indexed-effect-pool-cceffdrawobj)
(indexed pool), [Hit response](../combat/hit_response.md),
[Target selection](../combat/target_selection.md),
[Projectiles](../projectiles_and_items/projectiles.md),
[Damage](../combat/damage.md), and
[Combat action execution](../combat/combat_action_execution.md#continuation-and-common-exit-decisions).

## Evidence identity and address conventions

Retail identities and live mappings follow
[Game file identities](../../game/files/file_identities.md#address-conventions).
Resident globals below are annotated in the resident ELF `SLPS_258.37`,
including those accessed by BTL overlay routines.

## Ownership model

Resident setup pointer `battle_manager` supplies selected-side records.
Fighters own `support_gauge`, `support_recovery` and `logical_input`.
BTL's `SupportOwner` is a `0x24`-byte two-side manager published through
resident slot `support_owner`. Retail names are `ccBuddyAtkCtrl`
(`support_owner_class_name`) and embedded allocator `ccBdySerialNo`.

`SupportOwner.slots[2]` holds at most one ordinary support per side.
Only construction, successful request publication, first-pass terminal deletion
and explicit deletion change slots. Other references read occupancy/metadata;
this owner does not scan the generic population.
Both side records start `{color=0, linked_mode=1, recharge_class=0}`;
`SupportOwner.one_shot` starts at `1`.

| Side field | Meaning |
| --- | --- |
| `color` | Collision-resolved variant `0..2`; `1/2` request alternate resources. |
| `linked_mode` | Manual `0`, Auto `1`; affects entry facing, automatic attack requests and role-zero occupied-slot input, not member/slot selection. |
| `recharge_class` | Selection-derived multiplier class `0..4`; others use `1.0`. |

`support_linked_mode_get` (`0x00882630`) and `support_linked_mode_set`
(`0x00882670`) rely on manager creation order: absent manager accesses byte
address `1`, not a default. Practice's `practice_settings_load` /
`practice_settings_apply` round-trip that selector.

## Setup and selected support

`manager_snapshot_configuration` reaches `support_config_normalize`
(`0x00886250`) before fighter construction. Each `BattleCharacterSlot`
holds `selected_support` and resolved `support_selector`.
`support_config_copy_swap` swaps primary/support pairs together when
side-order byte is nonzero. `support_config_pair_side1` installs support
sentinel `0x26` for side 1. Names of `0x24/0x25/0x26` remain unestablished.

Selection `0x26` is deterministic. `support_config_resolve` (`0x00885C30`)
canonicalizes primary via `character_to_base`, retaining original on `-1`,
then reads `support_candidate_rows`; missing primary returns `0`.
Setup uses candidate `0`.

| Data | Established content |
| --- | --- |
| `support_candidate_rows` | 62 unique eight-byte primary/three-candidate/zero-padding rows; candidates support IDs `0..33`. |
| `support_code_rows` | 66 unique three-byte support/primary/code rows: 34 wildcard-primary (`0xFF`) rows for IDs `0..33`, then 32 specific overrides. Scan continues; codes `0..65` occur once each. |
| `support_recharge_rows` | 912 unique exact pairs, no wildcard: class `0` 475 rows, `1` 46, `3` 293, `4` 98. Class `2` exclusively defaults absent pairs. |

Candidate `0` is the selected support. Candidates `1/2` are used for selection
comparisons, not runtime rotation. The manager and request handler do not
resolve a new member. Setup's retry for a result still `0x26` is unreachable
with retail bytes.

`support_code_normalization_table` and `support_setup_normalization_table`
normalize code `49` to `0`. Sole code-49 row `[23,0xFF,49]` has no ID-23
specific override; ID `23` always resolves to code `0`, also independently
mapped by ID `0`. No character names follow from these IDs. Missing mapping
asserts through zero rather than returning unavailable.

`support_color_resolve` (`0x00885CE0`) starts colors at zero and applies,
after identity resolution, in order:

```text
if support_identity[0] == primary_identity[1]:
    support_color[0] = (primary_color[1] + 1) % 3
if support_identity[1] == primary_identity[0]:
    support_color[1] = (primary_color[0] + 1) % 3
if support_identity[1] == support_identity[0]:
    support_color[1] = (support_color[0] + 1) % 3
```

Primary colors are `BattleCharacterSlot.color`; character selection likewise
increments the second modulo three for an identity/color collision.
Support identities are resolved before comparison.

Resolved byte alone chooses factory implementation. Codes `>= 0x44` reject;
retail `0..65` cannot trigger this. Accepted classes use different sizes and
constructors. `support_object_initialize` stores `selector` and `side`;
later owner-fighter lookups use that side.

### Request-time side and member selection

Resident requests derive only `control_flags & 1`, addressing `slots[side]`
and configured code. Occupied slots query existing objects, without candidate
replacement. Packed role `((u16 control/state flags & 0x1FF) >> 5)` affects
input, not identity, code, color or slot count.

Native side/retained-point selection belong to
[Target selection](../combat/target_selection.md#support-side-selection-and-point-retention),
including its [attack-slot boundary](../combat/target_selection.md#complete-native-attack-slot-boundary).
Primary auxiliary playback/attack origins belong to
[Puppet control](puppet_control.md#attack-results-remain-primary-owned).

## Gauge state and availability

`Fighter.support_gauge` is clamped to `[0,1]` and starts `1.0`.
`support_recovery` initializes once via `support_gauge_initialize`:
classes `0..4` give `0.8/0.9/1.0/1.1/1.2`; absent manager/unknown class gives
`1.0`. Later writers do not rerun selection. HUD copies that gauge.

`fighter_update_movement_slot` requires `node_flags & 0x02` before
`support_request` then immediately `support_gauge_update`. Both require
`exchange_roles == 0`, `context_state == 0`, derived coordinator state zero
(resident hub `battle_hub`; see
[Battle entities](../session/battle_entities.md#derived-fighter-registrycoordinator)).

```text
if owner.slots[side] == null:
    gauge = clamp(gauge + support_recovery / 450.0, 0.0, 1.0)
else:
    gauge = clamp(gauge - 1.0 / 300.0, 0.0, 1.0)
```

Upward full crossing can emit `0x2D` for packed role zero/coordinator state
zero. Signed-delta writers share clamp/event gates and require empty
recipient slot:

| Recipient | Amount and ordering |
| --- | --- |
| Supplied fighter (`support_gauge_add`) | Applied normalized HP debit from `fighter_apply_hp_debit`, after status exclusion/before HP subtraction. |
| Supplied fighter's `opponent` (`support_add_to_opponent`) | Ordinary, guarded and common record consumers supply `ActionRecord.damage` divided by signed `repeat_count` when nonzero, before damage factors. |

Thus applied damage can recharge its recipient and raw record damage its
paired fighter. The latter follows the caller's fighter argument, not inferred
support ownership. Caller gates/fallback/HP calculation belong to [Damage](../combat/damage.md).

Empty-slot entry needs `>= 0.5`; active re-request bypasses threshold but keeps
an object-state latch. Request neither spends `0.5` nor resets gauge.
Creation lets the immediately following updater drain if gates pass.
Exhaustion/notification/terminal state do not select recharge; drain continues
until actual slot clear.

Derived float32 counts start exactly zero for recharge/one for drain,
and reproduce arithmetic rather than measured duration:

| Class | Multiplier | Calls to `>= 0.5` | Calls to clamped `1.0` |
| ---: | ---: | ---: | ---: |
| `0` | `0.8` | 282 | 563 |
| `1` | `0.9` | 250 | 501 |
| `2` | `1.0` | 226 | 450 |
| `3` | `1.1` | 205 | 410 |
| `4` | `1.2` | 188 | 376 |

Drain reaches zero on call 301; differences from ideal division are float32
accumulation. Request precedes recharge, so a crossed threshold admits only
later requests. Suppressed updates do not count.

Exhaustion shares this chain: `buddy_substate_update` (`0x00889C10`) reads
`support_gauge_get` and requests reason `3` for exact zero.
`support_reason_handle` resets state without terminal/slot writes; nine tables
use it directly, five call it first. Later enabled `support_departure_update`
(`0x0088A890`) requires substate zero/completion before `support_set_terminal`
writes `lifecycle = 1`. `buddy_player_update` (`0x00888720`) advances to
`2`; manager pass 1 deletes/clears. A request inside lifecycle-zero branch
advances next enabled call. All 14 share state-1/departure/terminal;
twelve use common update directly, two call it first.

`buddy_substate_update` and the HUD's `hud_support_sample` are the only
readers of `support_gauge_get`, and no support attack routine reads the gauge
field directly. A zero gauge therefore ends a support only through this
follow-state check, after any attack in progress has returned to that state.

## Manual request gates and return states

`support_request` (`0x00238340`) uses null-safe `support_present` /
`support_request_global` before `support_object_request` (`0x008872E0`).

| Gate | Requirement |
| --- | --- |
| Empty input | Logical `0x20000000` (default R1). |
| Occupied input | Packed role zero/Auto: `0x40000000` (default Circle); otherwise `0x20000000`. Other roles do not read Linked Mode. |
| Empty gauge | `>= 0.5`; failed low-gauge role-zero attempts can emit `0x2C`. |
| Participant/coordinator | `exchange_roles`, `context_state`, coordinator state zero. |

Bindings are configurable; [Action commands](../combat/action_commands.md#logical-mask)
owns logical-bit interpretation.

| Manager result | Meaning |
| ---: | --- |
| `0` | Invalid code/occupied query false; global wrapper also returns zero for absent manager. |
| `1` | Empty slot allocated, initialized, published; callback masks `0x02/0x04` enabled. |
| `2` | Occupied shared query accepted. |

Every final class shares `support_active_request` (`0x00888FE0`), requiring
`(reason, ready_countdown) = (1,0)`. Inherited `ready_countdown` is a substate
latch, not a decrementing timer. Acceptance sets `3`; another request needs
a later exact `(1,0)`, with no fixed count. Creation starts `(0,0)`: immediate
drain, initially failed re-request. Reason `1` alone is insufficient under
Auto, which can immediately latch `3`.

Resident handling clears `paired_hit_marker` only for manager `1/2`, but
returns its own `1` after resident gates even for manager `0`, so it does
not prove creation. Absent manager wrappers return no object/request zero,
skip unsafe selector and recharge; resident return can still be `1`.

### Animation result and common state transitions

Borrowed payloads `ent/nut/run/act/ext` belong to
[Battle entities](../session/battle_entities.md#support-object-common-prefix-and-removal).
State consumes `animation_complete` before current advance, normally using
the preceding result. Missing object list gives zero. `skip_advance` skips
one call, clears itself and preserves completion. Animation replacement
clears completion and sets that one-call skip.

`animation_advance_position` clamps fixed-point cursor at
`(frame_count-1)*0x100` and initially reports completion; descriptor loop
flags restart/force zero, a player flag can substitute stream completion.
This is not an elapsed support count.

`buddy_state0_update` installs `ent` at `(0,0)`, sets substate `1`, then
completion requests reason `1`: Manual leaves `(1,0)`, Auto `(1,3)`.
Auto also faces the opponent and may invoke entry callback before completion.
All five reason overrides retain common states.

| Substate with reason `1` | Common behavior |
| ---: | --- |
| `0` | Auto latches `3`, continues current owner-follow/positioning; positioning may instead choose substate `1`. |
| `1` | Completion installs `ent`, moves to `2`. |
| `2` | Completion installs `nut`, moves to `0`, reopening query. |
| `3` | Approach if opponent horizontal distance exceeds `reaction_range` and both `approach_flags` zero; otherwise reason `2`. |

Writing `3` in branch `0` does not execute it immediately.
Completion transitions `1/2` return early, deferring zero-gauge checks.
Lengths and subclass positioning remain open.

### Contact-triggered exit and contact-list activation

Common update checks `support_contact_requests_exit` (`0x0088B150`) before
dispatch. True selects reason `4` and dispatches it that call, replacing
approach/attack. Later state-1 exhaustion is only one departure trigger.
Exit needs `lineage_flags & 4` clear, positive main `contact_result_count`,
reason `1/2`. Query interfaces belong to
[Collision](../combat/collision.md#resident-list-and-registration-layouts).

| Secondary results | Exit rule |
| --- | --- |
| Positive | Main results must be kind `1`, signed byte `+0x208` in `0..3` (`0..5` with `lineage_flags & 2`), and in secondary results; failures exit. Byte's domain meaning unnamed. |
| Nonpositive | Null/other than kind `0/5` exits. Kind `5` exits unless word `+0x90` matches `support_kind5_exclusions`: `9/0x57/0x8B`, unnamed IDs. |

Kind `0` needs opposite primary to pass `downed_override_allowed` (nonnull
fighter/hub), have `current_record`, record flags `0x4000` clear.
False continues scan. This bounded support rule does not inspect action in
the resident leaf or establish a whole-game hurtbox rule.

`contact_activation_countdown` starts zero; initialization sets `90` after
registering/deactivating main list. Eligible lifecycle-zero calls decrement
positives; zero activates then falls into contact checking that call.
Reason `2` instead clears/activates immediately, so ninety decrements are not
required before attack. This countdown is independent of gauge and request
admission.

### Factory variants and attack completion

[Battle entities](../session/battle_entities.md#request-class-creation-and-repeated-calls)
owns 14 tables. Attack overrides: `0x0A/0x0C/0x11/0x19/0x1E/0x21/0x2B/0x3F`;
reason: `0x0A/0x19/0x21/0x2B/0x3F`. Nine attack bodies share substate-zero/
completion admission to post-attack callback then reason `3`, never `1`.
`support_attack_19` moving-effect collision rejoins that tail after clear.
Child-list overrides call common update first with no extra state/completion writes.

`support_contact_exit_update` positions/emits at substate `0`, sets `1`,
then completion requests `3`. Lifecycle: entry `0 -> 1`, attack
`1 -> 2 -> 3`, contact exit `1/2 -> 4 -> 3`. Only reason-1 substates
`1 -> 2 -> 0` reopen query; attack completion departs. Completion does not
establish damage/statuses/payloads. [Character assets](../../game/character_assets.md#selector-to-resource-mapping)
owns separate jutsu IDs, which do not identify support classes.

### Request preconditions and identifiers

Resident callers mask side; manager does not normalize other indices.
Heap allocation must succeed: null is stored then dereferenced, not return
zero. `SupportObject.generation` is `ccBdySerialNo` summon lineage;
post-wrap active-ID collision can yield zero without rejecting creation.
Request/gauge/terminal/slot gates do not consume it. Notification identity
is separate from indexed-effect generation.

### Support counters and notification suppression

`support_counter_records` holds per-side cumulative creation, reason-2 and
accepted-notification counts. Reset clears them; deletion does not subtract
creations. `support_creation_count` exposes the cumulative count to
`stats_condition`, independently of slot occupancy and availability. Reason
`2` increments its count after selecting the attack animation.
None of these counters admits or rejects a support request.

`support_notify_object_hit` and tagged transient contacts feed
`support_lineage_consume`. Identifier zero is accepted only with an active
support whose `lineage_flags & 1` is clear. A nonzero identifier is compared
with the four words in that side's `SupportNotificationRing`; a duplicate is
ignored, otherwise it replaces the next word and advances the index modulo
four. Acceptance emits side event `(side + 1, 2, 1)`, adds one notification
and sets the current support's bit `1`. Reason `2` clears that bit.
The notification path does not dereference an origin object.

Tagged transient contacts require `support_notify == 1`, derive the side through
`transient_actor_opposite_side`, and submit their copied summon identifier.
Support emitters set that tag and identifier; descendant construction copies
them from its source, while base construction clears them. Several descendants
can therefore share one suppression identity. The object-hit route submits
identifier zero.

Phase initialization clears every ring word and its cursor even when counters
are retained. The ring remembers four recent identifiers, not every prior
summon. Notification acceptance changes neither gauge nor slot membership.

### Resident direct-hit notification route

`hit_paired_marker_consume` first requires its enable argument's low byte.
It reads the receiving fighter's `opponent.paired_hit_marker`; `0`, `-1` and
`-2` do nothing. Other values reach the support notification path, although
the ordinary accepted-hit router supplies this mode only for marker `1`.
The opposite-side slot is dereferenced without a null check.

`support_notify_object_hit` copies the support's current `ActionRecord` into
the following retained record, deactivates the attack collection, submits
identifier zero, and increments local `hit_notifications`. The resident path
then calls `combo_add_pending` on the paired fighter. Both local increments
occur even when duplicate suppression rejects the notification. Common
support update clears the local notification count before state work.
These operations do not change gauge, request latch or slot occupancy.
Accepted-hit routing and combo ownership belong to
[Hit response](../combat/hit_response.md).

### Support-record borrowing and retained-source lifetime

`hit_source_record_get` recognizes a nonnull source header with magic
`0x474F` and kind `2`, then requests `support_record_get` for the side opposite
the receiving fighter. It does not use the source's side, summon lineage or
indexed-effect generation. `support_record_refresh` maintains a fixed pair
of `ActionRecord` buffers for each side; script command `6` writes the current
record, and hit notification copies it into the retained one.

The returned record is shared, overwritable side storage, not a per-hit
allocation. Source-header access precedes the copy and has no indexed-handle
generation check. The bounded route establishes how the record is selected,
but not the lifetime safety of every retained source pointer. Source ownership
and broader targeting rules belong to
[Target selection](../combat/target_selection.md).

### Authored support damage records

`support_object_initialize` (`0x00887FD0`) resets the current side record,
then sets category `0x08000000`, damage `0`, repeat count `1`, response
selector `0x15`, knockback `1`, flags `0x6000` and rejection field `1`.
Row remains `0`. This category permits ordinary HP sampling; its flags do
not set the ordinary `0x02000000` suppression bit. The ordinary consumer's
zero-row branch selects calculator flags `0x122`.

Script opcode `6`, `support_script_write_attack_record` (`0x00882E40`),
writes the current record at `support_side_records + side * 0xA8` when
the authored position matches. It treats command `+0x08` as a float,
multiplies `0.05f` by that weight, then multiplies the result by the
support's scalar at `+0x124` before storing `ActionRecord.damage`:

```text
record.damage = support_scalar * (0.05f * command_weight)
```

The instruction sequence uses `lwc1` and two `mul.s` operations, not an
integer-to-float conversion. Command `+0x0C` selects the response, and
float `+0x14` supplies knockback. Flags start at `0x6000`; command bit
`0x4000` becomes record bit `0x8000`, and command bits `0x80000`,
`0x100000`, `0x400000` and `0x800000` pass through. The command leaves
category, repeat count and row unchanged. It does not establish that a
collision is admitted or that the later ordinary damage event occurs.

`support_script_load_scalars` (`0x0088B600`) resolves the separate
`BIN_%s%dscr` blob and requires marker `0x101` at resolved blob `+0x08`.
Its first float at blob `+0x0C` becomes `support_scalar` without the sentinel
fallback used for two subsequent fields. The two selected retail resources both supply
scalar `1`. Their complete bounded attack-command walks give these inputs:

| Code / resource | Base payload | Attack opcode-6 position and weight |
| --- | --- | --- |
| `0x0A` / `new1` | `BIN_new1scr`, object `0xE8`, scalar `1` | Position `1`: `0.5f` (`0x3F000000`), command selector `0x10` maps to response `0x12`, flags `0x80000`, knockback `0.8f` |
| `0x3F` / `ymt1` | `BIN_ymt1scr`, object `0xDD`, scalar `1` | Position `1`: `0.3f` (`0x3E99999A`), selector/response `3`, flags `0`, knockback `0.1f`; position `27`: `0.4f` (`0x3ECCCCCD`), command selector `0x12` maps to response `0x14`, flags `0`, knockback `1` |

These bytes come from `2NEWBDY1.CCS` and `2YMTBDY1.CCS` under retail
`BUDDY`. Base chunk headers are at decoded offsets `0x272D0` and
`0x12354`; attack chunk headers are at `0x272F0` and `0x12374`, with
payload lengths `396` and `172`. Both native-width walks reach the exact
end of their payload, including the two-word terminator. This establishes
positive authored raw expressions, not measured HP or every reached
position. Numeric support codes and resource tokens do not establish
their character display names.

`support_spawn_transient` (`0x0088B040`) and
`support_spawn_transient_scatter` (`0x0088D880`) copy the current side
record's damage into the emitted projectile's `config_scalar`, then set
its support notification flag and allocated identifier. The conditional
code-`0x0E` / config-`4` case scales that copied scalar by `0.2f`.
A later support-record update does not rewrite this cached value.
These emitters retain the projectile response-record contract rather than
copying the support category/raw field into it, so emitted-object damage
uses the generic direct path. Count ownership and ordering belong to
[Damage](../combat/damage.md#ordinary-object-and-support-attribution), and
the response-record copies to
[Projectile lifecycle](../projectiles_and_items/projectiles.md#response-records-and-damage-ownership).

## Scheduled lifecycle and teardown

`battle_dispatch_phases` dispatches mask `8` to the support wrappers in order:
`support_update`, `support_second_pass`, then `support_third_pass`.
The manager's first pass recomputes callback masks `2/4`, initially enabled
for both occupied sides. If `BattleManager.fighters[0]` has nonzero
`exchange_roles` or `context_state`, both masks are disabled.
First-pass mask `2` also uses these shared gates:

| Gate | Established predicate |
| --- | --- |
| A | `battle_footprint_gate` and `battle_control_resource_blocked` read `ChakraControlState.enabled` / `active`. |
| B | The caller requires resident auxiliary slot `battle_input_phase_override` nonnull, then `support_global_gate_b` tests the supplied object's word `+0x32D0 & 0x14` for zero. That word's domain meaning remains open. |
| C | `battle_nested_state_is_3` tests the hub's derived registry/coordinator state. |

Mask `2` is disabled by `(A && B) || (C && !(fighter0.node_flags & 2))`.
The same result applies to both sides. Before iterating them, `A && !B`
causes `support_terminal_broadcast`.

An enabled first pass calls the object's common update, then deletes and
clears a slot whose lifecycle is `2`. A pre-loop terminal broadcast sets
`1`, so that enabled update can advance it to `2` and delete it in the same
pass. A disabled object retains the terminal state until a later enabled
pass. Presence and record queries ignore callback masks and terminal state;
gauge drain therefore continues until the slot is actually cleared.
Unconditional teardown also ignores those masks.

The second pass invokes presentation under mask `4`. It temporarily installs
default context `primary_draw_environment` through shared draw/list-environment
slot `active_draw_environment` and restores the previous value afterward.
The third pass invokes the third object callback under mask `2`.

`support_owner_allocate` clears the six counters, deletes any previous
manager and publishes a new one through `support_owner`.
`support_owner_release` destroys both slots and clears that pointer.
Phase initialization resets the generation candidate to `1` and its reuse
state to zero, conditionally resets counters, and always clears notification
rings. `support_owner_clear` retains the manager and rearms `one_shot`;
its code predicate can emit `(side + 1, 18, 1)` before clearing that flag.
Natural support deletion and enclosing battle teardown use these explicit
owner paths.

### Paired-participant transitions and temporary callback disable

`support_disable` sends reason `1` to each occupied object, then clears its
callback bits `2/4`. It retains the objects and their lifecycle state.
Every final class preserves the common reason-1 handling, which clears
attack/contact bindings and movement and selects the waiting animation.
Auto can immediately leave `ready_countdown == 3`, so reason `1` alone does
not establish request availability.

The resident accepted-extra-hit boundary calls this before
`exchange_set_roles`. The paired transition calls it after setting both
participants' `context_state` to `-1`. Their surrounding behavior belongs to
[Hit response](../combat/hit_response.md) and
[Combat action execution](../combat/combat_action_execution.md).
The next manager first pass recomputes the callback masks. While a retained
slot is disabled it still selects gauge drain rather than recharge.

### Specialized descendants and release order

Most specialized destructors use the common destructor before conditionally
freeing the object. The code-`0x3F` indexed variant and the two child-list
variants release their additional ownership first.
`support_variant_c040_vtable` covers codes `0x15..0x17` with four presentation
children; `support_variant_bfc0_vtable` covers code `0x38` with three.
These children are presentation nodes, not additional primary fighter slots.

`SupportListObject.presentation` owns a header and its successfully allocated
`SupportPresentationNode` chain. A node borrows its definition and player,
owns its sample buffer, and embeds two presentation records. Failed node
allocations are skipped and the header count reflects successful nodes.
The list variants run common update/presentation before their children.
Destruction saves each next pointer, frees the sample buffer, destroys both
embedded records through `embedded_presentation_record_destroy`, frees the
node and then the header, clears the owner pointer, and runs common teardown.

`SupportIndexedObject.effect` is valid only when its index is nonnegative
and below pool capacity, generation is nonzero and matches the selected
record, and that record is occupied. Attack and attachment consumers validate
the cached record each time.
Code `0x3F` runs common reason handling before releasing its old indexed
effect for every reason; reason `2` then acquires a fresh one. A valid release
sets fade `(0, 0, 10)`, countdown `10` and retirement request, then resets the
handle to `(-1, 0, null)`. Invalid handles skip both the writes and reset.
Its destructor applies the same release before common teardown, without
freeing the pool record directly.

Code `0x0A` acquires its indexed effect at attack position `2`.
Reason `4` requests retirement with `(0, 0, 5)` and resets a valid handle;
an invalid handle skips that reset. Other reasons reset the handle without
those retirement writes. Its destructor follows the ordinary common wrapper.
These differences do not establish a leak or a visible survival duration.

### Selected resource commands and callback routes

Support state scripts and animation event streams are separate consumers.
`support_scripts_bind` finds resource tokens through
`support_script_resource_rows` and formats `support_script_name_format` as
`BIN_%s%dscr_%s`. Suffixes `ent/wit/atk/ext` map to reasons `0/1/2/3`; the
fifth suffix is null. The selected tokens are `new1` for code `0x0A` and
`ymt1` for code `0x3F`. Owned `SupportScriptWrapper` objects borrow command
storage from their resource containers.

`support_script_update` selects the current reason's wrapper.
`support_script_dispatch` runs only on a changed whole cursor position and
walks that wrapper's commands from the beginning each call, dispatching
commands whose authored position equals the current position. It does not
consume a start cursor or replay every crossed position; revisiting a position
can dispatch it again. Opcode zero terminates the walk without checking its
position. Playback and descriptor ownership belong to
[Scene playback owners](../../runtime/scene_playback_owners_btl.md#btl-buddy-resource-descriptor-changes).

| Opcode | Established support behavior |
| ---: | --- |
| `6` | Replace the current side record's damage, response, flags and knockback from the authored command and base scalar. |
| `4` | Bind attack entry `1` when radius is positive; retain its attachment name and side-record pair, otherwise clear the entry. |
| `14` | The same attack binding with an explicit entry index. |
| `15` | Bind an explicitly indexed secondary contact entry. |
| `5`, `16` | Activate/deactivate the attack and secondary contact collections respectively. |
| `18` | Nonzero sets contact-exit suppression bit `4`; zero clears it. Other lineage flags are preserved. |

Both selected `atk` resources have type `0x2400` and leading word `0x101`.
Their bounded native-width walks establish these schedules:

| Resource | Authored command positions |
| --- | --- |
| `new1` | Position `3`: opcode `18(1)`, attack radius `150` and secondary contact entry `0` radius `180`, both attached to `OBJ_2cmn00t0` pelvis. Attack activation at `7, 17, …, 77`; contact activation at `7`. Position `85` deactivates both and calls `18(0)`. Terminator position word is `90`. |
| `ymt1` | Position `1`: attack entry `0`, radius `100`, attachment `OBJ_hit_dmy01`. Attack activation at `21/24/27`, deactivation at `30`; terminator position word is `33`. |

The selected `ent/wit/ext` scripts contain only their header and terminator.
The attack scripts also contain opcode `1`, whose full audio interpretation
remains outside this bounded result. Opcode `6` and its selected raw inputs
are established above. Authored positions do
not establish seconds, all positions actually reached, resource animation
length, or departure timing. A terminator position is not a departure event.

Binding names remain borrowed resource bytes, not copied strings or cached
scene objects. Reset clears six attack bindings and three secondary contact
bindings, their radii, record pairs and names, and deactivates the collections.

Separately, `fighter_event_dispatch` forwards event `0x8002` through
`support_stream_event_forward`. Codes `0x2000..0x3000` select the primary
fighter's side and invoke the occupied support's stream callback.
The selected `0x0A/0x3F` classes use `support_stream_event_noop`; that callback
does not execute their state-script commands or indexed-effect operations.
Other consumers and the full animation event stream remain open.

### Indexed animation binding and attachment sampling

For code `0x0A`, changed attack position `2` in substate zero acquires
`support_animation_enewact1`, binds type `1` through `wrapped_resource_setup`
with `(1, 0, 0, 0)`, seeks position `1`, copies the support transform, and sets
support mode `1` / scalar `0.3`. The initial seek is not repeated; later valid
updates transfer the transform and playback step.

Code `0x3F` reason `2`, after old-handle release, binds
`support_animation_pymtact1e` as type `1`, retains its origin, uses support
mode `2`, and transfers playback step. Changed attack position `14` in
substate zero sends four `support_cmp_ymt_names` descriptors to
`effect_descriptor_spawn` (`0x002F9010`) at the retained origin. Those
descriptor effects have separate ownership from the indexed handle;
their full payload behavior remains open.

`support_attack_samples_from_indexed` validates the handle and type-1 player,
then resolves every nonnull attack attachment name with `resource_find_model`
on the current resource. It refreshes the transform and copies the attachment
vector into `SupportAttackSample.point`; it does not retain the scene-object
lookup result. This is the consumer of the `OBJ_hit_dmy01` binding.
The established scalar/mode/step writes do not identify opacity, animation
rate or callback frequency.

### Indexed-effect retirement consumers

Both selected classes acquire from the `ccEffDrawObj` indexed pool, whose
ownership is independent of `SupportOwner`. Pool scheduling and destruction
belong to
[Battle lifecycle](../session/battle_auxiliary_services.md#indexed-effect-pool-cceffdrawobj).

Retirement values `10/5` act as fade divisors and countdowns. In the eligible
pool retirement callback, the countdown reaches removal on the corresponding
eligible call; these values do not establish frames or seconds. Animation
completion or pool reuse can remove/invalidate a record earlier. Generation
checks protect a reused indexed record, but do not validate borrowed fighter
or resource pointers. Support deletion requests asynchronous pool retirement;
whole-pool destruction does not wait for those countdowns.

## Limits and useful negative results

The established manager has one slot per side and no runtime candidate
rotation, second support slot or fixed re-request cooldown. The state latch,
contact activation countdown and gauge are separate mechanisms.
Zero gauge requests departure; only an enabled manager pass advances terminal
state and clears occupancy. Linked Mode changes request/entry behavior, not
selection or slot count.

Shared completion establishes lifecycle transitions, not damage or subclass
payload outcomes. Notification counts and remembered identifiers are
bookkeeping, not availability gates. Full subclass effects, scheduler-gate
meanings, borrowed-pointer lifetime guarantees and actual callback frequency
remain unestablished. All derived timing in this document counts eligible
invocations.
