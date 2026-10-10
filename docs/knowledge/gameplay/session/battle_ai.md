# Battle AI

## Research coverage

Established: retail NA2 (`SLPS-25837`) AI ownership, lifecycle, configuration,
targeting, decision precedence, dispatch, action queues, numeric exceptions
and shared RNG. The bounded NUN4 ID-9/NA2 ID-89 Orochimaru comparison covers
separate AI value/flag lookups and the checked direct reaction exceptions.
Open: move names and reaction reachability/semantics, the seventh profile row,
consumers of parameters 24/31 and descriptor bits
`0x02/0x40`, meanings of the descriptor's first halfword and final byte,
and unrecognized external aliases.

Routines, structures and data are named by the annotations in
`@annotations/NA2` and `@annotations/NUN4`; their comments carry the per-routine
detail. Findings are static; names describe demonstrated behavior rather than
native move names.

Related owners: [Action commands](../combat/action_commands.md),
[Practice mode](../modes/practice_mode.md),
[Pause and replay](pause_and_replay.md),
[Target selection](../combat/target_selection.md),
[Combat action execution](../combat/combat_action_execution.md),
[Character action callbacks](../characters/character_action_callbacks.md),
[Chakra and guard](../combat/chakra_and_guard.md),
[Battle support mechanics](../characters/support_mechanics.md), and
[Resident randomness](../../runtime/randomness.md).
Retail file identity is owned by
[Retail game file identities](../../game/files/file_identities.md).

## Address convention and overlay mapping

Addresses in annotations are live. The BTL mapping and resident-file convention
are owned by
[Retail game file identities](../../game/files/file_identities.md#address-conventions)
and [MWo3 overlay ABI](../../runtime/overlay_abi.md).

## Principal function map

`ai_tick` is the shared entry. `ai_initialize` installs state and parameters;
`ai_refresh_actors` binds the fighters; `ai_classify_spatial_bucket` classifies
their geometry. `ai_opening_plan`, `ai_guard_and_incoming_stage`,
`ai_main_reaction` and `ai_late_reaction` make ordered decisions.
`ai_dispatch_state` executes the resulting state. `ai_select_action_record`
and resident `action_queue_set` provide the direct-action path.

## Controller ownership and lifecycle

Resident character wrappers call `ai_tick` when the controller nibble,
bits 5..8 of the halfword beginning at `Fighter.control_flags`, is nonzero.
Zero selects the human path. The four fully compared wrappers,
`fighter_ai_update_250da0`, `fighter_ai_update_26f930`,
`fighter_ai_update_29b250` and `fighter_ai_update_2ee330`, pass the original fighter,
add no character-specific decision logic, and return zero.
The resident caller census contains 74 direct calls to the shared tick.
The four-wrapper sample does not establish identical later consumers for
every character.

`fighters_update` invokes the fighter's virtual AI slot during its first
eligible-fighter pass, then `fighter_copy_input_outputs` and the ordinary
input consumers during its second pass. The AI therefore proposes this
update's logical mask, magnitude and angle before the resident bridge
consumes them. There is no extra-update queue at this boundary.

The bridge can suppress all three outputs and clear `bridge_output_age`
when `state_flags & 0x80` or `status_flags & 1` is set. Otherwise it copies
the triple; simultaneous `0x1000` and `0x01000000` loses the latter bit.
A synthesized command therefore remains subject to resident arbitration.

Practice settings are applied only on Confirm; Cancel closes without applying.
`practice_toggle_com` clears the controller nibble for Manual and installs
kind 1 for every non-Manual Status. Initialization occurs when the old nibble
was zero or the supplied force flag is nonzero. Apply compares Strength after
its setter, so matching normalized values pass force zero; an ordinary Strength
edit does not itself force initialization. Selecting Manual clears neither
static slot and calls no AI destructor or free routine; returning from Manual
to a non-Manual Status initializes again. Settings staging, normalization and
side selection are
owned by [Practice mode](../modes/practice_mode.md#confirmapply-side-effects).

No AI heap allocation, object constructor, destructor or deallocation path was
recovered. AI state occupies two static slots.

## Per-side state block

`ai_states` contains two `AiState` records, each `0x1E0` bytes. Side selection
uses `Fighter.control_flags & 1`. Named fields distinguish the output triple,
self and target, spatial bucket, dispatcher state, request latch, source and
route fields, candidate bytes, timers, parameters, cached action index and
phase cursors. Unidentified storage remains padding in the declaration.

`ai_initialize` resets transient state in **both** slots, then installs a
profile only on the selected side. It preserves the other side's existing
parameters. Thus reinitializing one controller can interrupt the other side's
current AI action without replacing its profile. Randomized initialization
timers are also generated for both slots.

`ai_reset` performs a smaller current-side reset: it clears output, state,
request latch, route submode, selected cooldowns and route markers, and releases
the two handles. It does not clear the three candidate bytes. Its precise
write set and the initializer's constants are in their annotations.

Each tick indexes `ai_character_values` (`BTL.BIN 0x008C3460`) directly
with the selected fighter's `character_id` at `+0x68`, using a four-byte
stride without a local bounds check. `ai_tick` (`0x00704D40`) loads the
two signed halfwords at `0x00704F50..0x00704F70` into the current side's
region value and alternate-target threshold. `character_region_value` ranges 0..3;
`alternate_target_threshold` ranges 0..90 and gates competitive world-object
and point searches with a strict comparison against an inclusive 0..100 roll.

Checked retail NA2 rows are:

| Character | Actual ID | `ai_character_values` row | Region value | Alternate-target threshold |
| --- | ---: | --- | ---: | ---: |
| Might Guy (`guw`) | 69 | `0x008C3574` | 1 | 20 |
| Kakashi (`kkw`) | 70 | `0x008C3578` | 2 | 20 |
| Itachi (`itw`) | 71 | `0x008C357C` | 2 | 20 |
| Kisame (`ksw`) | 72 | `0x008C3580` | 1 | 20 |
| Orochimaru (`orw`) | 89 | `0x008C35C4` | 1 | 30 |

## Main tick and output boundary

`ai_tick` selects current and opposite sides, checks the outer context,
refreshes actors, checks both fighters and the terminal marker, decrements
timers, hot-reloads changed Practice Strength, then clears the output triple.
An inconsistent occupied latch with state zero is reset before continuing.
A nonzero `context_mode_word` resets and returns. Null outer context,
inactive fighters and `battle_timeout_marker_get` return before the internal output
clear or publication; those paths do not themselves reset the slot.

Early returns still publish no input under the recovered phase ordering.
`input_object_update` calls `input_build_logical_mask` with suppression for a
nonzero controller nibble, clearing `BattleInput.logical_mask`,
`stick_magnitude` and `stick_angle`. `battle_dispatch_phases` runs this input
phase before the fighter phase, so the bridge subsequently copies zeros when
the AI returned early.

This depends on both phase bits running together. The recovered suppression
writers allow or suppress bits `0x0002/0x0004` together; the auxiliary override
permits only the command phase. Session filters further restrict allowed masks.
No recovered writer to the first-phase filter separates fighter updates from
command clearing; the known second-phase setter cannot do so. Unrecognized
indexed or pointer aliases remain open.
[Pause and replay](pause_and_replay.md#selective-update-gating) owns those masks.

After classification and the action-slot scan, decision order is:

1. `ai_paired_context_prepass`;
2. `ai_opening_plan` and `ai_guard_and_incoming_stage` in ordinary modes and
   Practice COM;
3. `ai_main_reaction`, ending with `ai_practice_scripted_tail`;
4. `ai_late_reaction`;
5. `ai_practice_linked_attack`, or `ai_schedule_own_support` followed by
   `ai_react_opponent_support`;
6. `ai_dispatch_state`;
7. ordinary/COM environment correction and post-dispatch replacements;
8. paired-AI arbitration and publication to the fighter's `BattleInput`.

A positive `fighter_context_state_get` after the prepass bypasses all remaining
decision and dispatch stages. Only prepass commands survive because output
has already been cleared. The prepass handles paired transient states and
context-state requests; its profile-25 command attempt and quotient-based
context choice are separate from ordinary planning.

Scripted Practice Status Stand/Jump/Double-jump skips the ordinary opening
and guard/incoming stages and the ordinary post-dispatch block. It uses
`ai_practice_linked_attack` after the main and late stages. Ordinary modes and
Practice COM normally run both support stages; Practice Linked Attack
frequent/random substitutes `ai_practice_linked_attack`.

Publication copies `AiState.logical_mask`, `movement_magnitude` and
`movement_angle` to `BattleInput`. AI input shares the human logical-command
representation. Direct action queues coexist with that command source.

### Decision priority and ordinary-plan replacement

`ai_opening_plan` returns for an occupied request latch. Otherwise it saves
the old state, clears it and chooses a replacement. Later reactions can replace
state with the latch already set, so the latch is a stage-specific gate.

The opening order is region-bound recovery; bucket-0/1 action attempts;
nonzero-bucket route or state-1 choices; then the bucket-0 modulo-20 choice.
Region-bound recovery can continue after selecting state 10. The bucket-0/1
branches use parameter 14 and the position-component separation threshold 200
to choose state 11, 10 or 28. Nonzero buckets use parameter 10 to choose
state 11 or a primary-target route; a failed roll selects state 1. Target
effect 9 can reject the route. The modulo-20 choice sends results 0..5 to a
state-11 attempt and the other 14 to a latched neutral wait; saved state 7
can first require facing correction. `ai_opening_cases` records that split.

`ai_guard_and_incoming_stage` calls `ai_select_exchange_response` and
`ai_react_target_state`, performs its own reactions, then calls
`ai_react_incoming_action` before two final state-11 checks. Its parameter-9
branch resets into state 14 with a clear latch; failure can instead produce
mask `0x1020` via parameter 14. The subsequent incoming-action helper can
replace either result. Final state-11 checks use self action 8/parameter 4 or
target actions 3/4/parameter 14.

### Main reaction stage and later rewrites

`ai_main_reaction` first resets states 2/3/4/24/26 only when self
`major_state == 5`. Scripted Practice then goes directly to its tail.
The ordinary path processes exchange/action reactions, target response
geometry, bucket-2 action reactions, self action `0x5D`, target-facing
reactions, incoming collision objects, nearby region objects, timeline
reactions, alternate targets, small random choices, and environment prediction
in that order. Gates and cooldown writes for each family are in its annotation.

The self-action-`0x5D` branch rolls before checking its cooldown: below 30
selects state 33, 30..59 selects 15, and 60..100 selects neither. It bypasses
the remaining families until the final current-action check. Other important
branches select 12, 10/25/5/1, 18, 11/6, 8, 35 or 25, with parameter and
geometry gates. Region-object enumeration can make multiple rolls in one pass.

The small choice is reached only without a collision candidate, in state 0/1,
and when `ai_resource_target_reaction` returns zero. Results 0/1 correct
facing; 2/3 attempt short-history movement `0x40000`; 4/5 attempt state 22;
6..14 can select state 21; 15..60 select none here. State-22 attempts impose
timers `12+rand(0..3)` and `300+rand(0..150)` even when the parameter-20
roll fails. State 21 instead uses `38+rand(0..30)` and
`210+rand(0..150)`. Failed attempts can therefore delay later attempts.

`fighter_reaction_variant_high` tests the low two bits of
`Fighter.reaction_variant` for values 2/3. Its ordinary self/state-0-or-1
branch emits mask 8 and returns before the remaining main reactions, while
the main tick's later stages still run. No player-facing condition is assigned.

`ai_late_reaction` can convert states 21/22 to 25 without a clear latch and
later select 9/17/34/11/20. A main-stage constructor therefore does not prove
that its handler runs that update: late, linked and support reactions precede
dispatch and can replace it.

### Final support-dependent arbitration

`ai_schedule_own_support` queries `support_get` for the current side;
`ai_react_opponent_support` queries the opposite side. The former schedules
an own-side request, while the latter reacts to the opponent's active support.
[Battle support mechanics](../characters/support_mechanics.md) owns its lifecycle.

Own-support scheduling seeds its interval from parameter 38 plus a bounded
roll. Parameter 21 can select state 38 and clear the latch. This is separate
from Strength selection.

Opponent-support arbitration clears the latch and returns for absent support
when state is 39..42, leaving the state intact. Existing support must pass
`support_within_fighter_y_range`: absolute Y separation from the fighter
opposite `SupportObject.side` must be below 50. An expired support cooldown
clears the latch; otherwise an occupied latch returns. Reasons outside 0..2,
self class 8, and selector-4 Strength below 4 reject subsequent branches.

Nearby-opponent parameter-14 choices can select state 11/10 before support
range is considered. Inside `SupportObject.reaction_range`, reason 2 with
selector 4 has a parameter-28 action-selector path: it can queue an index after
parameter-14 admission or fall back to a parameter-10 state-5 attempt.
Other inside/outside branches select 34 or 6, or the following responses:

| Context | Result |
| --- | --- |
| Reason 2, selector other than 4, expired primary reaction cooldown | Parameter 5 selects state 40; failure returns |
| Same context, primary cooldown active, short retry expired, affordable 1.0 | Parameter 1 selects state 39; either outcome returns after setting retry timing |
| Reason 0/1, ready support, distance at most 250, expired movement cooldown | Parameter 14 selects state 42 |
| Same availability branch with movement cooldown active and no active action word | Parameter 8 selects state 41 |
| Outside range, reason 1, distance at most 400, no active action word | Parameter 8 selects state 41 |

`support_reason1_ready` requires reason 1 and zero `ready_countdown`.
`support_action_pointer_present` tests the word at `+0x368`; that word's
wider embedded-object meaning remains unnamed. Its absence participates in
state-41 branches. These returns are local priority boundaries, so the support
stage does not overwrite every earlier state unconditionally.

### Incoming-action reactions and effective Strength gates

`ai_react_incoming_action` and `ai_react_incoming_collision_object` can
replace earlier decisions. They refresh `attack_candidate` and
`collision_candidate`, respectively. Attack-shape queries classify incoming
objects; they do not select another primary fighter.

`sphere_cache_proximity_offset` scans 32 attack-object indices and exposed shapes;
`sphere_cache_proximity` returns classification 0/1/2 with kind-specific distance
gates. Raw attack kinds differ from character IDs. Broader payload ownership
remains outside this document.

The incoming-action magnitude starts at parameter 5. Exact target category
values `0x10000/0x20000` select parameter 6;
`0x100000/0x200000/0x400000` select parameter 7 and can reduce parameter 1
to integer `0.8*parameter1`, subject to the demonstrated HP comparison.
An overlap can instead select parameter 6 and mark the attack candidate.
These are equality comparisons, not bit tests.

The priority is an affordable parameter-1/scalar state-20 attempt; an alternate
contact-flag state-6 attempt; the ten-step phase/classification state-18
reaction; a further mask-`0x02000000` state-23 lookup; then geometry and
current-record departures. Thus even phase-selected state 18 can be replaced
before returning.

`ai_target_action_scalar` maps signed `ActionRecord.ai_reaction_scalar`
values -3..3 to -0.5, -0.3, -0.1, 0, 0.1, 0.3, 0.5; other values, a missing
record or a target outside class 8 contribute zero. The threshold is
`base + base*scalar`, converted to an integer before rolling. This adjustment
uses no extra random draw. It affects parameter 1 in incoming and late
reactions, and parameter 2 in collision-object reactions.

The collision-object path initially queries radius 550. Certain subtypes mark
the candidate immediately; others requery at 450 for types 12/25 or 250
otherwise. Its marked-candidate gate compares a float roll with
`1.9*parameter5`, distinct from the integer phase consumer. Parameter 2
plus the action scalar can select state 20; type 25 instead selects 8.
Other subtype, resource, region and cooldown gates can select 34/8/5/10/18.
The precise numeric kinds and departure rules are in the routine comments.

### Scripted-Practice reaction priority

`ai_practice_scripted_tail` returns outside Practice or for COM. Otherwise
it clears all three candidate bytes and first calls `ai_select_exchange_response`.
A successful exchange response ends the tail before Guard, movement or Attack.

Guard Yes with equal regions collects collision, attack and opposite-support
reason-2 candidates. Outside self classes 7/8, target class 8 or any candidate
can reset into state 18 with a 30-count timer and return. This outranks
movement, jumping and attacking without making every guard state unconditional.

Move Follow can maintain or construct a source-0 primary-target route in
state 5 and return before jumping or Attack. Jump/Double-jump preserves
state 18 and resets other states before checking `practice_jump_countdown`.
Both require zero countdown and self outside classes 7/8. Double-jump uses
state 36 with timer 18 for self class 0, or timer 90 for class 2/action
`0x18/0x22/0x24`. Jump selects 36 with timer 90. Reaching the expired jump
branch returns before Attack even when no Double-jump combination selected 36.

Stand cancels a state-5 route when Move is not Follow. Attack other than No
requires expired `practice_attack_countdown` before selecting state 37;
the class-2/3 and neutral-state branches have different additional gates.
The menu options alone therefore do not describe their execution priority.
[Practice mode](../modes/practice_mode.md) owns the settings transaction.

### Post-dispatch output replacement

Ordinary/COM environment correction can alter an already synthesized direction
or construct a new route state. The subsequent self-action-`0x15/0x16`
branch can reset and select state 11 after dispatch. Its fixed threshold is
50 for character region values 0/1/2, or 30 otherwise; it can emit `0x1000`
immediately. The new state is not dispatched again that tick.

Attack-object property `0x80` with a special-action cooldown resets and
writes object `+0x13C=2`. Property `0x100` resets **before** its parameter-27
roll; success writes `+0x13C=1`, while failure still discards the dispatched
output. Both property paths can run on one object. Scripted Practice bypasses
this block.

The paired-AI reset follows these branches and precedes publication. Selecting
the current side clears this tick's output; selecting the opposite side clears
that side's internal slot. Neither dispatcher runs again. A successful state
constructor or handler therefore does not guarantee its output survives.

### Character descriptors and hard-coded exceptions

Separate from the per-tick values, `ai_character_descriptors`
(`BTL.BIN 0x008C3050`) has 96 four-byte records: an unsigned halfword,
a flags byte at `+2`, and a final byte. The recovered readers index
`0x008C3052 + character_id*4` using the selected fighter's actual ID at
`+0x68`. `ai_initialize` loads that byte at `0x00706170`;
`ai_state11_update`, `ai_react_target_state`, and `ai_main_reaction` load it
at `0x006F9F10`, `0x007003E4`, and `0x00704B74`, respectively.
These reads do not establish a selector meaning for the first halfword
or a meaning for the final byte.

| Character | Actual ID | `ai_character_descriptors` row | First halfword | Flags byte |
| --- | ---: | --- | --- | --- |
| Might Guy (`guw`) | 69 | `0x008C3164` | `0x001F` | `0x10` |
| Kakashi (`kkw`) | 70 | `0x008C3168` | `0xFFFF` | `0x11` |
| Itachi (`itw`) | 71 | `0x008C316C` | `0xFFFF` | `0x10` |
| Kisame (`ksw`) | 72 | `0x008C3170` | `0x001F` | `0x08` |
| Orochimaru (`orw`) | 89 | `0x008C31B4` | `0x001F` | `0x10` |

Recovered flag consumers are:

| Flag | Established use | Character IDs |
| --- | --- | --- |
| `0x01` | Multiply parameter 16 by 1.2 at initialization | `1..6,12..15,17,22,34..38,46..57,63..65,67,68,70,73,75,80,85,87,90..93` |
| `0x04` | Multiply parameter 8 by 1.2 | `13,66` |
| `0x08` | Multiply parameter 24 by 1.2; authored values are zero | `6,60,65,72,86` |
| `0x10` | State-22 construction/suppression gates | `5,7,16..19,46,58,59,61,62,64,67..71,77..84,87,89,91,92` |
| `0x02` | No recovered meaning | `12,76` |
| `0x40` | No recovered meaning | `10,11,39..43,85` |

A first-halfword value `0xFFFF` does not invalidate nonzero flags, including
IDs 46/59. These reads do not prove roster selectability or named awakening
behavior. [Character identity in battle](../characters/character_ids.md) owns
identity and selection evidence.

`ai_state11_update` and `ai_react_target_state` use bit `0x10` plus a clear
self contact-flag bit 5 for parameter-20 state-22 attempts. The main reaction
instead suppresses its ordinary state-22 attempt only when both bits are set;
that attempt does not require descriptor bit `0x10`. The former constructor
can also emit mask 4 after selecting state 22.

Hard-coded target IDs alter geometry independently of profiles:

| Routine | Exception |
| --- | --- |
| `ai_react_incoming_action` | In the no-shape branch, IDs 4/57/64 require distance at most 650; 35/48/53/60/73 at most 800; 18/19/39/47/54/61/77 at most 1200; other IDs require bucket below 3 |
| `ai_late_reaction` | IDs 59/64 with contact-flag bit 5 use a parameter-10 state-9 attempt and bypass general nearby state-17/34 choices |
| `ai_main_reaction` | ID 36/current indices 4/5/6/21/22 divert the normal facing state-11 branch; a parameter-22 state-6 attempt can be overwritten by a later parameter-5 state-18 attempt |
| `ai_react_incoming_action` | ID 49/current accessor result 34 takes the reset/departure branch |

These differences do not establish move names, author intent, or reachability
of every listed combination.

### Numeric-exception admission and working records

ID 36 has 37 source records in `ai_character36_actions`; ID 49 has 49 in
`ai_character49_actions`. The compared source records are:

| ID/index | `ActionRecord.category` | `cost` |
| --- | --- | ---: |
| 36/4 | `0x00100000` | 5 |
| 36/5 | `0x00200000` | 10 |
| 36/6 | `0x00400000` | 15 |
| 36/21, 36/22 | `1` | 0 |
| 49/34 | `0x02000000` | 0 |

`actions_setup_working_array` keeps only the configured action among slots
4..9 and zeroes the other categories. ID 36's indices 4/5/6 require configured
selections 0/1/2 through the common start path. A zero category is rejected;
the AI's index comparison does not itself check selection and cannot exclude
another current-index writer. Indices 21/22 and ID 49's 34 lie outside the
zeroing range.
[Action commands](../combat/action_commands.md#working-action-arrays) owns setup
and later `jutsu_slots_rewrite`.

**Conditional ID-49 producer:** `lee_loopy_channel3`, callback slot 2 in
`lee_loopy_callbacks`, can dispatch index 34 from current index 33/43,
phase 2 and timeline event `0x12`. The event is a cursor crossing, not proof
of elapsed frame 18. Those indices exceed the configured-provider remapping
range. Record 34 has no generic jutsu prerequisite and zero cost; the common
class-8 start accepts it, and `fighter_current_action_index` returns it
unchanged.

The same callback re-evaluates the index and can immediately request 35 or
enter class 6/substate `0x5F`. Its producer therefore does not prove that a
later AI tick observes 34. The AI exception additionally requires no attack
candidate, state 18/20, target class 8 and ID 49. It resets before remaining
record checks, which would otherwise finish without resetting because record
34 lacks category bit 8. Practice/near-bucket departure can subsequently
select 11, and later stages can replace it. Equal category at index 35 does
not extend the exact-index-34 exception.

Open: a given match's ID-36 selection, full producers of its five compared
indices, antecedents of ID-49's actions 33/43 and event, and the other numeric
exceptions' complete contexts.

## Primary target and spatial classification

`ai_refresh_actors` binds `self` to the supplied fighter and `target` to the
opposite entry of `BattleManager.fighters` every tick. It copies
`Fighter.facing` and `opponent_distance`. Primary ownership is deterministic:
no fighter-list search, reciprocal `opponent` lookup or RNG chooses that target.
[Target selection](../combat/target_selection.md#paired-opponent-and-geometry-refresh)
owns the source geometry refresh.

`ai_classify_spatial_bucket` caches the fighter position with its recovered
center adjustment and classifies geometry. Equal `target_section` and
`section` use distance boundaries 150/250/400 for buckets 0/1/2/3.
Higher/lower target section gives 4/5. An absolute `position[2]` difference
above 400 forces buckets below 3 to 3.

`ai_correct_facing` compares primary-target X and `movement_facing`.
A wrong-facing right case writes angle approximately `-pi/2` (literal
`-1.57`), mask 1 and magnitude 0; left uses `+1.57`, mask 2 and magnitude 0.
These are logical direction values.

## Alternate target-position sources and path states

Primary fighter ownership stays fixed while `target_source` chooses a
navigation position in `ai_target_position_get`:

| Source | Position |
| ---: | --- |
| 0 | Primary opponent's live position |
| 1 | World object resolved from `world_object_handle` |
| 2 | Navigation point resolved from flattened `point_index` |

`ai_alternate_target_stage` can use parameter 28 to construct source 1/state
24 from `ai_find_competitive_world_object`. State 27 can independently use
`ai_find_world_object_in_radius(120.0)` to construct the same route.
`ai_construct_point_route` uses parameter 0 and an expired interval to scan
regions for source-2 candidates. Each must be valid, pass the character
threshold and be closer to self than to the opponent. The first passing point
wins; stage `0x16` excludes region 0 from one traversal path. Success selects
26, caches index/vector/region and plans the route, with near/far deadlines
30/210; no candidate imposes a 60-count retry interval.

The constructor and `ai_navigation_point_get` contain traversal paths for
two providers. `stage_navigation_points_get` supplies records;
`stage_secondary_navigation_points_get` returns zero unconditionally in the
recovered retail implementation. The second path exposes no records there.
Producer and lookup share region-first flattened ordering, so later lookup
can refresh the selected live point.

The three searches enumerate through `world_objects_enumerate`,
`world_object_enumerated_handle` and `world_object_get_record`.
`world_object_build_record` supplies kind, position and region; the AI validates
region bounds and caches vector/region. Each search returns zero when
`world_object_handle` differs from -1, without selecting another object.

| Search | Selection rule |
| --- | --- |
| `ai_find_competitive_world_object` | Skip kind 7; strict character-threshold roll and strictly closer to self than opponent; first passing candidate wins; failures set a 90-count delay and continue |
| `ai_find_world_object_in_radius` | Skip kind 2; strict radius to self; first eligible wins without RNG or opponent-relative comparison |
| `ai_find_world_object_by_kind` | Exact kind and strict limit; lower limit after acceptance; stop on an accepted distance at most 400, otherwise retain the closest accepted candidate |

The kind-2/3000 search in `ai_resource_target_reaction` returns on success
without constructing source-1/state-24 there. Failure selects state 21 and
seeds its retry timers. A stored handle alone does not prove navigation starts.

Shared kind-specific gates can terminate the whole search. Kind 2 rejects
when effect 10/11 is present or an affordability check for 5.0 succeeds.
Kind 3 rejects when the side object passes `world_side_object_blocked`.
The radius search's later kind-2 affordability call is unreachable because
it already skipped that kind; its presence is not another executable path.
Kinds remain numeric.

`stage_plan_route` selects 3 for a direct same-region or stage-specific route,
4 for populated inter-region routing, or 5/0 when resolution fails under
the relevant gates. The resulting consumers form these lifecycles:

| State | Role |
| ---: | --- |
| 3 | `ai_move_to_target_point`: direct cached-position motion, including region transitions |
| 4 | `stage_execute_route`: route segments/interpolation; delegates to direct motion when segments end |
| 5 | `ai_opponent_route_update`: execute route, refresh the moving primary target, replan and retain 5/latch |
| 24 | `ai_object_route_update`: validate the handle every pass, reset on failure, maintain/replan and retain 24 |
| 26 | `ai_point_route_update`: refresh point, enforce near/far deadlines, maintain/replan and retain 26/latch |
| 27 | Retry an invalid point; after countdown expiry, attempt the radius-search source-1 route |

An invalid point can clear its index, select 27 and seed retry 30.
Within distance 115 and the target region, state 26 enters direct facing/action
logic under its near deadline; component separation above 100 can request a
mask-8 action and queue it when no action is pending. Outside that case,
expiry of the far deadline resets. These are active lifetimes.

## Action-state dispatcher

`ai_dispatch_state` accepts states 0..42 through `ai_state_handlers`.
State roles and outputs are below; detailed gates remain in handler annotations.
Masks describe logical input, with player-facing sources owned by
[Action commands](../combat/action_commands.md#logical-mask).

| State | Behavior |
| ---: | --- |
| 0 | Return without action |
| 1 | Reset after its wait cooldown |
| 2 | Region-bound reset or bucket-dependent movement/`ai_state11_update` |
| 3 | Direct target-point motion |
| 4 | Route-segment traversal |
| 5 | Moving-primary-target route maintenance |
| 6 | Timed `0x40000` input with contact/distance gates |
| 7 | `ai_state7_update` |
| 8 | `ai_region_transition_update` |
| 9 | `ai_state9_update` |
| 10 | `ai_state10_update` |
| 11 | `ai_state11_update` |
| 12 | Conditional `action_stage_exchange_candidate`, otherwise reset |
| 13 | Exchange-role-dependent reset/staging |
| 14 | Target downed-family/reset gates or mask `0x1080` |
| 15 | Self action `0x60` selects/queues; `0x5D` emits `0x1000`; otherwise reset |
| 16 | Timed `0x1000`, reset on expiry or self class 4/5 |
| 17 | `ai_state17_select_action`, a selector/queue path |
| 18 | Conditional guard and action departures |
| 19 | Exchange-role-dependent reset/staging |
| 20 | Target/collision gate, Practice transition to 18 or `guard_set_input_timing(-2)` |
| 21 | Effect gate or timed mask 8 |
| 22 | Timed mask 4 |
| 23 | Find mask-`0x02000000` action and queue when eligible |
| 24 | Alternate-object route lifecycle |
| 25 | [Item-use handler](../projectiles_and_items/battle_item_inventory.md#na2-cpu-item-use) |
| 26 | Navigation-point route lifecycle |
| 27 | Point retry/source-1 construction |
| 28 | `ai_state28_update` |
| 29..32 | Shared no-op return |
| 33 | Self action `0x5D` emits `0x10000`; otherwise reset |
| 34 | Reset and emit `0x10000` |
| 35 | `stage_navigation_response` |
| 36 | Reset and emit `0x10000` |
| 37 | `ai_practice_attack_update`, a selector/queue path |
| 38 | Emit `0x20000000`; handshake value 2 clears latch |
| 39 | `guard_set_input_timing(-2)` |
| 40 | Emit `0x10000000` |
| 41 | Emit `0x01000000` |
| 42 | Select category 1 with directional gate, then queue the result |

The direct -2 guard-age setters are states **20 and 39**. State **38** emits
`0x20000000`. State 20's Practice key `0x11==1` changes to 18 and returns
before its setter; [Practice mode](../modes/practice_mode.md#substitution-jutsu)
owns the option and fighter-side effect.

With default bindings, `0x1000` comes from new Circle, `0x10000` Cross,
`0x01000000` Square, `0x20000000` R1, and held L2/R2 produces guard
`0x10000000`. Low masks 4/8 are opposite direction sectors.
`0x40000` is a short-history Cross-plus-direction modifier.
Bindings remain configurable; these sources do not establish move names.

### State-18 guard reaction

`ai_guard_reaction_update` differs from state 40's unconditional guard.
Target class 8 with current-record flag `0x02000000` resets immediately.
Scripted Practice Guard Yes supplies an override, affecting guard gates and
suppressing both random action departures.

For a target outside class 8, any candidate byte equal to 1 emits guard and
returns; otherwise the helper resets. A nearby-bucket departure can then select
11, latch it with timer 30, correct facing and call `ai_state15_select_action`.
Its parameter-14 threshold gains 10 when raw Strength is nonzero.

For target class 8, category bit 2, bucket 0/1, a candidate byte, or the
override outside buckets 4/5 can emit guard. With no such gate it returns
without adding guard. After emitting, a non-override category-`0x100` path
can use a cooldown and parameter-14 roll to reset, correct facing and select
an action. That reset clears the guard just added.

`fighter_action_record` arguments -3/-1 both return the current record while
the target is class 8; they do not establish distinct records. Record-bit move
names remain unresolved.
[Chakra and guard](../combat/chakra_and_guard.md#guard-input-and-action-lifecycle)
owns guard input and counters.

### Candidate-byte lifetime across Practice Status changes

The scripted tail clears `support_candidate` and sets it for opposite support
reason 2. Initialization also clears it. Ordinary incoming reactions refresh
only `attack_candidate` and `collision_candidate`; opponent-support
arbitration does not refresh `support_candidate`, and `ai_reset` clears none
of the three.

**Static consequence:** changing scripted Status to COM can retain an earlier
support candidate of 1. Apply stores Status/Strength before comparing requested
Strength with the normalized stored value. Matching Strength supplies force
zero; a nonzero controller nibble then avoids initialization. The tail returns
for COM before its clears. A subsequent initializer or scripted-tail pass clears
the retained value. Going through Manual then COM does initialize again.

This is an ordinary consumer of a retained scripted byte, not a recovered
ordinary positive producer. The bounded AI-cluster/alias search found no such
producer; an unrecognized external writer remains open. It does not establish
that every ordinary match can produce the flag.

### Direct state constructors

The direct BTL constructor inventory is recorded on `ai_state_handlers`.
A table entry alone does not establish selection. `ai_select_exchange_response`
dynamically chooses 13 for exchange-role values `0x1000/0x400`, or 19 for
`0x100`, before its phase gate. State 2 has no recovered direct constant
constructor. States 29..32 have neither a recovered constructor nor an active
handler and are apparently reserved under the current static evidence.
External or aliased writes are not excluded.

## Action-record selection and direct queues

`ai_select_action_record` filters up to the fighter's counted working records
into a 128-index local array. It returns -1 for none, otherwise selects by
raw-RNG modulo the eligible count. Eligibility combines category mask/range,
distance threshold, signature/direction, vertical separation and
`ai_action_record_allowed`. Default mask is `0x000F000D`; default category
range comes from parameters 36/37. The category byte shares
`ActionRecord.streak_exempt`, read signed by AI and as category 0..3 by queues.

Practice Attack Combo rejects jutsu-family/category-zero records. Parameter
15's eligibility roll is bypassed only by scripted Stand/Jump/Double-jump.
Special mapped actions create `special_action_cooldown` using
`mapped_action_value_get`: percentage ranges are 10..40, 20..60, 30..80,
or 40..100 for buckets 0,1,2,other; multiplication truncates to an integer.

The 12 selector and 14 queue call sites are in the annotations. Paths include
states 15/17/37/42, the point route and opponent-support reaction.

Resident `action_queue_set` independently checks index, fighter/context state,
record category/mode and resources. It returns zero on rejection, including
selector result -1, and one only after installation. Normal success installs
`queued_chain` and up to four category-indexed `chain_slots` by following
`continuation`; a special path replaces `pending_action` instead.

`action_select_from_signature` gives an installed chain precedence over the
logical mask in the same update. `action_queue_dispatch` starts category 0,
optionally installs category 1 as pending, then advances through 2/3 as pending
action becomes -1. Suppressed input, admission failure, invalid/exhausted slots
or leaving class 8 clears the retained chain. This is a bounded four-category
chain rather than a command FIFO.
[Combat action execution](../combat/combat_action_execution.md) owns general
execution.

The cached-action branch in `ai_state15_select_action` has an extra precheck:
it converts `ActionRecord.cost` to an integer lookup index, obtains a signed
byte from `resource_table_signed_value`, converts that byte directly to float
and calls `chakra_affordable`. It does **not** multiply by 5.0. Resident queue
admission still checks the selected action independently. Height branches can
instead request masks `0x212/0x10A/0x86`.

## Configuration and behavior profiles

`battle_strength_get` returns raw `battle_setting_get(manager,0x0B)`.
The normalized range 0..5 selects six rows of `ai_behavior_profiles`;
`practice_strength_count` is 6. The top row is unlock-gated: unavailable
feature key `0x6A` lowers the menu maximum to 4. The seventh contiguous row
has no confirmed selector and does not establish a seventh difficulty tier.

Each row supplies 40 signed parameters. Initialization copies the selected
row, conditionally applies `ai_secondary_modifiers`, applies descriptor
multipliers, then `ai_normalize_profile`. Negative defaults are replaced only
at indices 1/2/5/8/9/10/11/12/14/15/16/18; exact values and all authored rows
are recorded on the table and normalizer.

The percentage matrix has ten signed-byte rows. The count returned by
`continue_completion_count_get` selects row count-1 for counts 1..10,
clamping larger counts to row 9. Each value becomes
`value + trunc(value*signed_percent/100)`. Manager modes 2/3, the setup bypass
or a nonpositive count skip it.

The resident continue flow increments the count for Yes or optional Change
character, and leaves it unchanged for No. The three native labels and ruby
markup are recorded in `continue_choice_labels`; Up/Down changes the bounded
choice and Confirm accepts it. No timeout substitute was found. Availability
of the third choice is separate from the counter's ownership. Surrounding flow
initialization and teardown clear the count; no other clean resident writes
were recovered. This count is separate from ordinary Strength.

`ai_profile_modifier_bypass_get` reads a setup-specific byte. `setup_apply_mode`
can call `setup_begin_modifier_bypass` for setup value 2, using resident
continue data; `setup_flow_update` clears the byte on completion. Equal numeric
setup and manager values do not establish equal mode meanings. The setup
value's player-facing name remains open.

Practice Strength hot reload copies a raw row only. It does not rerun percentage
modification, descriptor multipliers, normalization, the two-slot reset or
initializer-only randomized timers.

### Direct profile-parameter consumers

The full 40-index value/consumer ledger is recorded on `ai_behavior_profiles`.
Parameters supply strict random thresholds, phase inputs, cooldown/retry seeds,
action category bounds and directional intervals. Different consumers can
transform the same parameter: parameter 5 feeds the integer phase gate or the
float `1.9*value` comparison; parameter 14 can be halved or gain 10;
action-record scalars adjust parameters 1/2 before integer conversion.
Raw Strength is therefore not a uniform chance multiplier.

Indices 24/31 have no recovered decision consumer. All seven authored rows
have zero at 24; descriptor bit `0x08` transforms it without changing that
zero. Parameter 31 has nonzero authored values, so it remains unresolved rather
than presumed unused.

### Computed profile copies and unresolved parameters

Initialization and Practice hot reload both install all 40 parameters, including
24/31. The percentage loop also adjusts both; the initializer can further
multiply 24. Neither installation exports a new row or pointer to another owner.

The bounded row-base, shifted-slot, overlapping-load and surviving-pointer
trace found no additional decision use or outgoing row copy. The normalizer
excludes 24/31; a leftover caller-saved pointer is not evidence that a helper
consumes it. Unknown aliases and indirect external access remain open.
These results establish installation and transformation, not meanings or
universal non-use.

The analogous descriptor trace found four byte readers: the initializer uses
bits `0x01/0x04/0x08`, and the reactions use `0x10`. No recovered copy or
forwarding establishes a consumer of `0x02/0x40`; alternative address paths
remain open.

## RNG ownership and confirmed uses

BTL has no local PRNG state. Its calls enter the resident raw wrapper
`effect_context_bit` or `prng_inclusive` around `prng_next`.
[Resident randomness](../../runtime/randomness.md#mt19937-core) owns state,
reductions and seeding. `prng_inclusive(bound)` returns
`(raw ^ 0x80000000) % (abs(bound)+1)`, including both endpoints and modulo
bias. A strict threshold on 0..100 is over 101 results, not an exact percentage.

The audited cluster contains 167 direct wrapper calls: 10 raw and 157 bounded.
Raw uses include filtered-record selection, phase seed/reseed modulo 10,
four state-11 choices modulo 5, and the opening modulo-20 choice. Bounded
uses include action cooldown percentages, both-slot initialization timers
`150+rand(0..120)`, reactions and paired-AI arbitration. The per-routine
census and exact call sites are in annotations.

The state is shared game-wide. Non-AI draws and reset ordering can change the
next AI result; equal AI-slot contents do not imply equal next decisions.

`ai_incoming_phase_gate` buckets its integer argument by ten, selects one of
three `phase_cursors`, seeds/reseeds at -1 or wrap with raw RNG modulo 10,
and otherwise advances deterministically through `ai_phase_patterns`:

| Row | Ten boolean cells |
| ---: | --- |
| 0 | `0 1 0 0 0 1 0 0 0 0` |
| 1 | `0 1 0 0 0 1 0 1 0 0` |
| 2 | `0 1 0 1 0 1 0 1 0 0` |
| 3 | `0 1 0 0 1 1 0 1 0 1` |
| 4 | `0 1 0 1 1 1 0 1 0 1` |
| 5 | `0 1 1 1 1 1 0 1 0 1` |

Its result contributes to state 18 with latch and timer 30 in
`ai_react_incoming_action`. It is not an independent Bernoulli draw on every
evaluation.

`ai_exchange_phase_gate` uses parameter 11 implicitly. Quotients 0..1,
2..3 and 4..5 select rows 0/1/2 with cursor 0; 6..7 select row 4/cursor 1;
8+ select row 5/cursor 2. `ai_select_exchange_response` applies this phase gate
for Normal, while Practice Always return bypasses it after clearing the
relevant cooldown. Thus the cursors serve two reaction paths.

The main tick's paired-controller, both-state-5, different-region branch tests
`rand(0..100)<20`, then randomly resets one side with `rand(0..1)`.
Its purpose as a stalemate breaker remains a hypothesis.
`ai_target_action_scalar` maps record values to scalar float bits and is not
an RNG helper.

## Evidence limits, negative results, and hypotheses

Bounded negatives: no AI-specific BTL ASCII class name, no BTL-internal
caller of the tick, no randomized primary fighter selection, no state reset
on Manual disable, and no recovered AI heap ownership. The controller class
names support structural identification. Numeric states, unlisted logical masks
and action-record bits retain unresolved move meanings.

Open questions include every large reaction branch's complete semantics,
descriptor bits `0x02/0x40`, profile parameters 24/31, the seventh row's
selector, complete numeric-exception admission, an ordinary positive support
candidate producer, the modifier-bypass setup name and unrecognized first-phase
filter aliases. These limits are not evidence of universal non-use.

Hypotheses: paired-AI random reset may break stalemates; the seventh row may
belong to an inaccessible tier or special mode; the continue counter's signed
modification may implement adaptive easing. Their control flow and data are
established, but these purposes are not.
