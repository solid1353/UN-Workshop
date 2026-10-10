# BTL scene playback owners

## Research coverage

189 of the 214 direct BTL seek sites are classified. The established contracts
cover selection, rate, completion, submission and local ownership; the remaining
25 sites are listed in the [direct-call census](scene_playback_owners.md#direct-call-census-and-analysis-limits).
Routine names, signatures, field layouts, resource labels and local details are
recorded in `@annotations/NA2` for `BTL.BIN` and `SLPS_258.37`.

This is static coverage. Indirect dispatch, invocation cadence, the inherited
primary player's full lifetime and schedule, GAR's continuing update, SKN/SKM
child playback, typed-resource type-3 selection and derived initialization,
linked-node flag bit 1, and all buddy outer-gate producers remain open.

[Animation runtime](animation_runtime.md) owns evaluation algorithms;
[CCS runtime](../game/files/ccs_runtime.md) owns parsing and resource lifetime.
[Stages](../gameplay/stages/stages.md#animated-and-breakable-background-evidence)
owns background contact, geometry, timers and lifetime algorithms.

## Summary

Seek counts are direct seek call sites in each section. "Frame 1" is the seek
target `0x100`; every listed seek also carries the
[active-blend exception](scene_playback_owners.md#playback-families).

| Owner | Seek sites | Policy class |
| --- | ---: | --- |
| [Stage objects](#btl-stage-owner-playback): `ccBgBreak*`, `ccBgTransAnm`, `ccCraneTruck`, and two earlier reset owners | 22 | Scene-rate advance; trigger, end and rebirth requests at zero, frame 1 or `(F-1)`; construction frames |
| [Additional local contracts](#additional-btl-local-owner-contracts) | 19 | Whole-frame adapter, descriptor and controller selectors, fixed frames with step zero, shared-player draw restoration |
| [Requested-state sequencing](#btl-requested-state-and-endpoint-sequencing) | 11 | State-selected descriptor at frame 1; endpoint request followed by advance |
| [Byte selectors](#btl-byte-selectors-and-frame-one-requests) | 10 | Byte-selected descriptor at frame 1 |
| [Gauge players](#btl-threshold-latched-gauge-players) | 3 | Threshold-latched activation at frame 1; fade-out reset |
| [Captured poses and typed owners](#btl-captured-poses-and-typed-owners) | 2 | Captured whole-frame sample; typed-resource construction at frame 1 |
| [Input and endpoint requests](#btl-input-and-endpoint-request-owners) | 5 | Input-armed zero requests; endpoint and counter-derived requests |
| [Recreation and restoration](#btl-player-recreation-and-descriptor-restoration) | 12 | Recreate and restore a saved frame; descriptor change at frame 1 or `(F-1)` |
| [Frog `ccSkillJRY001Frog`](#btl-wrapped-frog-player) | 1 | State transition at frame 1 with conditional rate write |
| [`ccSkillGUW001`](#btl-guw-embedded-player) | 1 | Selector-gated frame 1 on an embedded player |
| [GAR and GAV](#btl-gar-and-gav-primary-player-transitions) | 5 | Primary-player state transitions at frame 1 |
| [`ccSkillTOV001`](#btl-tov-variant-selected-primary-player-seeks) | 7 | Variant-selected state transitions at frame 1 |
| [`ccSkillASM001`](#btl-asm-requested-state-primary-player-seeks) | 4 | Requested-state transitions at frame 1 |
| [`ccSkillKIB001New3`](#btl-kib-primary-and-looping-embedded-player) | 6 | State transitions at frame 1; completion-driven embedded repeat |
| [SKN and SKM](#btl-skn-and-skm-counter-gated-primary-players) | 2 | Counter-gated transition at frame 1 |
| [TYV parent and object](#btl-tyv-parent-and-allocated-player-object) | 3 | Counter-gated transitions and allocated-object setup at frame 1 |
| [`ccSkillObjSawarabi`](#btl-sawarabi-embedded-player-array) | 2 | Record-state array: setup and delayed transition at frame 1 |
| [ZBZ and KMV](#btl-zbz-and-kmv-counter-gated-primary-players) | 4 | Counter-gated transitions at frame 1 |
| [`ccSkillObjWaterDragon`](#btl-water-dragon-embedded-player) | 2 | Setup at frame 1; advance then frame-1 request in an explicit update |
| [`ccSkillANB000`](#btl-anb-embedded-and-associated-players) | 8 | Range-index and requested-state descriptor changes on embedded, associated, linked and controller players |
| [`ccSkillFOR000`](#btl-for-embedded-player-pair) | 2 | Activation pair at frame 1 |
| [`ccSkillTND001`](#btl-tnd-embedded-player-group) | 3 | Randomized initial frames; frame 1 with completion latch |
| [`ccSkillCHY000`](#btl-chy-supplementary-player) | 1 | Construction request at cursor zero |
| [Wall and gate players](#btl-wall-and-gate-players) | 4 | Construction at frame 1; endpoint `(F-1)`; even-counter advance gate |
| [Linked-player owners](#btl-linked-player-owners) | 30 | Construction at cursor zero; list advance ignores completion |
| [Descriptor-switched array](#btl-descriptor-switched-player-array) | 5 | Setup at frame 1; transitions at frame 1 or a randomized frame |
| [Buddy resources](#btl-buddy-resource-descriptor-changes) | 15 | Descriptor replacement at frame 1; one-invocation advance suppression |
| Total | 189 | |


## BTL stage-owner playback

Stage playback combines scene-rate increments with explicit trigger, endpoint,
rebirth and construction requests. Contact-count and flag gates in the base
break owners choose contact processing, then converge on playback; they do not
establish an animation pause.

| Owner | Increment policy | Explicit requests |
| --- | --- | --- |
| `ccBgBreakObjectBattle` | Scene rate × 256 | Trigger at zero; infinite-threshold completion returns model 1 to model 0 at frame `F-1` |
| `ccBgBreakObjectBattleAnm` | Playback rate × scene rate × 256 | Trigger at zero; the same endpoint return; timed rebirth at frame 1 |
| `ccBgBreakDollBattle` | Scene rate × 256 after the cooldown gate | Accepted contact selects model zero at cursor zero; later model transitions use frame 1 or return to zero |
| `ccBgTransAnm` | Cached default step × animation multiplier × scene rate; requires the battle context | Configured construction frame, or random frame `0..F-1` |
| `ccBgBreakObjectRebornBattle` | Base playback precedes rebirth handling | Rebirth selects model zero at frame 1 and clears completion |
| `ccBgBreakObjectMoveBattle` | Mover and base playback precede reset handling | Delay expiry selects model zero at frame 1 and clears completion and break count |
| `ccCraneTruck` | Its own player advances in both inspected states | Alternate-animation completion rebinds and evaluates the default once, then resets the linked break player's model zero to frame 1 |
| `ccBgBreakObjectBattleChandelier` | Playback rate × scene rate × 256 | Trigger at zero, endpoint return at `F-1`, and timed rebirth at frame 1 |

The doll's nonzero cooldown decrements and returns before playback. The
transition-animation owner advances before its proximity/render-value handling.
Break-animation and chandelier construction bind, request the configured frame,
and evaluate once before installing the player. Construction is therefore
separate from later periodic playback.

Two earlier owners have independent initialization contracts.
`btl_counter_arm_stopped_player` arms its player when the clamped counter
exceeds 1, requests frame 1 and assigns step zero.
`btl_reset_player_records` requests frame 1 while resetting owner and record
state. Their complete scheduling chains remain open.

## Additional BTL local owner contracts

Whole-frame selection, stopped poses and ordinary increments have distinct
contracts. `animation_seek_whole_frame` forwards its caller's seek flags;
the other classified BTL requests use flag zero. All requests retain the
[active-blend exception](scene_playback_owners.md#playback-families), including
zero after a new bind.

| Contract | Established behavior |
| --- | --- |
| Associated next/previous-frame helpers | Request the current whole frame ±1, narrowed to 16 bits; their upper checks use `F-2` and `F-1` respectively. The previous-frame helper has no local lower-bound guard |
| Fixed primary poses | Frames 20 and 50 are selected only when capture is inactive, followed by step zero; the separate selector-2 path selects frame 9 |
| Descriptor and controller selectors | Bind with zero blend, request frame 1 when valid, then clear their local controller counter; the four controller helpers do not assign a step or advance |
| SIN requested states | States 1 and 2 select controller descriptors 1 and 2 |
| State-8 transition | Requests frame 1 twice on the same player, separated by event clearing and conditional primary-player substitution |
| Wall pose-rate selector | Selector 1 with pose selector 1 sets step zero and requests frame 1; the alternate pose branch assigns step `0x100` |

The shared-pose owner separates logical frame production from submission.
`shared_pose_players_update` increments its signed logical frame once per
invocation and wraps to 1 when it reaches the shared descriptor's frame count.
It also advances two other embedded players using their own fixed-point steps.

Submission visits 20 instance records. Nonzero-opacity instance zero uses the
first player; the remaining instances sequentially reuse a shared player,
restoring each instance's transform, opacity and the owner's logical frame
before submitting. Submission does not increment that logical frame. A helper
can change draw suppression after update clears it; its full gate and cadence
remain open.

## BTL requested-state and endpoint sequencing

Requested selectors and stored states form separate transitions. Valid-player
requests follow zero-blend binding and precede conditional primary-player
substitution. The substitution predicates are separate from the seek guards.

| Requested selector | Stored state / descriptor index |
| --- | --- |
| 1 / 2 / 3 | 4 / 1 / 7 |
| 4 or 5 | 10 |
| 7 | 13 |

Event-driven states 1/4/7 transition to 2/5/8 and clear the playback event.
A later substate-1 branch with saved old counter zero and no secondary request
selects state 6/3/9 for selector 1/2/3; other selectors select state 3.
A pending secondary request produces pending request 6 instead. This later
branch can issue another bind/seek in the same invocation.

The state-11 path uses the saved old counter value 15 to leave substate zero.
Its common tail rereads the current substate, state and playback event before
selecting state 12. Virtual calls and earlier state changes therefore matter to
the later gate.

The associated-player direction path selects descriptor index 5 in both
direction branches, then sets pending request 3. The direction-change flag and
rotation copy do not choose between different descriptors.

`anb_primary_endpoint_advance` requests the primary player's `F-1` endpoint
and then advances/composes that player in the same eligible path. Endpoint
selection here does not imply a stationary pose. Its earlier association work
converges before this pair; the complete upstream schedule remains open.

## BTL byte selectors and frame-one requests

These byte-driven changes reuse the inherited primary player. They bind with
zero blend and request frame 1, then continue local bookkeeping. They do not
establish the player's ordinary advance schedule.

| Selector family | Byte value | Descriptor choice |
| --- | ---: | --- |
| `btl_byte_ff0_descriptor1000_select` | 2 | `descriptor_1000` |
| `btl_byte_ff0_descriptor_ff8_select` | 3 / 4 | `descriptor_ff8` / `descriptor_ff4` |
| `btl_byte_ff0_descriptor_ffc_select` | 3 / 4 | `descriptor_ffc` / `descriptor_ff8` |
| `btl_stored_byte_descriptor_select` | 0 / 1 / 2 / 3 / 4 | Descriptor array index 1 / 0 / 2 / 3 / 4 |

Unrecognized values skip these direct requests. The stored-byte footer still
selects local helper value `0x1028` for byte 4 and `0x1027` otherwise.
Event clearing and later resource creation do not turn these transition
requests into a looping rule.

## BTL threshold-latched gauge players

The gauge owns three allocated players in the borrowed `battlegauge`
container. Construction binds and evaluates each once; clearing a latch does
not imply an unevaluated player. Cleanup destroys all three, while the inspected
cleanup retains the container.

The threshold predicate selects the first qualifying fighter record among
records 4..9. Activation requires its value in `0..threshold`; no qualifying
record yields -1. The value's player-facing meaning remains unassigned.

| Resource / role | Activation | Active update and release of latch |
| --- | --- | --- |
| `ANM_ef_gau01a`, threshold player | Predicate true: request frame 1 and latch | Advance first, then clear latch if predicate fails; no rewind or destruction |
| `ANM_ef_gau02a`, fading player | Predicate true, and threshold player inactive or within 10 whole frames of its end: request frame 1, latch and fade 1 | Advance first; true predicate restores fade 1, otherwise subtract 0.1 and clear latch at zero |
| `ANM_ef_gau00a`, state player | Fighter substate 0 and phase 4: latch and fade 1 without seeking | Advance first; leaving that state subtracts `0.033333335`; fade expiry requests frame 1 and clears latch |

Completion results do not clear these latches. The fading player continues
advancing throughout fade-out. Gauge update orders value calculation and local
counters before this player pass, then performs texture-offset handling.

## BTL captured poses and typed owners

Captured-pose records reuse allocated players. Spawn takes the first inactive
record, binds the fighter's current descriptor, samples its primary player's
whole frame, optionally applies the capture pair, and records its transform.
The active pose then fades without advance or seek; submission restores its
recorded transform and opacity. Fade expiry makes the record reusable.
Pool destruction separately releases the player and other resources.

The opacity increment is fade increment × fighter update rate. Negative values
clamp to zero and deactivate the record; the inspected upper branch also writes
zero for values above 1. Submission requires opacity at least 0.01. Neither
the meaning of the capture pair nor the higher-level spawn/fade schedule is
established.

Typed playback has a separate allocation and update contract.

| Type | Owned resource | Ordinary update | Established producer |
| --- | --- | --- | --- |
| 1 | Effect | Transform and effect update | Descriptor-bound setup/replacement |
| 2 | Animation player | Transform/opacity, advance and composition; completion ignored | Descriptor-bound setup/replacement; replacement requests frame 1 |
| 3 | Effect | Transform and effect update | Implemented allocation arm; selection remains open |
| 4 | Animation player | Transform/opacity, advance and composition; completion ignored | Owner IDs `0xB4/0xB5` and table rows 62..64 |

The typed table has binding code `0x14` for the descriptor-bound type-1/2
setup. Types 3/4 pass their constructed resource to a virtual initializer;
the base initializer is empty and derived implementations remain open.
Replacement explicitly releases previous types 1/2; use on types 3/4 is
unestablished. Full cleanup releases all four types and the separate effect.

Both inspected update callers apply delay and enable gates before playback.
The first can skip playback through state-7 dispatch. The counter-90 caller
returns early in states 6/7, but in its other paths checks counter 90 only
after playback. That terminal invocation can therefore still advance.
Submission uses delay, enable and state greater than 1, independently of those
update gates.

## BTL input and endpoint-request owners

Directional input arms a left or right player and requests zero when the
settled-value comparisons permit it. Update advances armed directional players
until completion clears their latches. Decoration players advance independently.
A local dispatch connection exists; its complete upstream entry gate remains
open.

The position helper requests endpoint `F` for selector zero, or its unsigned
counter frame otherwise. It performs no ordinary advance. The endpoint-counter
controller has a different state policy:

| State | Playback behavior |
| --- | --- |
| 0 | Reinitialize and evaluate once, then enter state 1 |
| 1 | Advance until completion, then enter state 3 |
| 2 | No local advance or seek |
| 4 | Request `F-counter`; completion sets the latch and clears state and counter |

Positive-state draw increments the 16-bit counter, moving the state-4 target
one frame earlier per such invocation. The full draw/update ordering and
upstream controller schedule remain open.

## BTL player recreation and descriptor restoration

Associated-player recreation saves only descriptor and whole frame, destroys
the old player, allocates a replacement, binds the saved descriptor and requests
that frame. It does not establish preservation of step, fractional position or
active blend. Ordinary associated update is gated by the owner enable bit;
the alternate update assigns step zero after prior completion but still calls
advance/composition. Cleanup separately releases the player and local resources.

Primary pose capture and restoration likewise save descriptor and whole frame.
Virtual hooks run before capture and restoration; the restoration request
clears the capture record afterward. Conditional primary-player substitution
has a separate predicate and does not gate the valid-player seek.

Controller selection compares the requested index with the previous selector
unless forced. A valid descriptor clears its counter and assigns step
`0x100` even when restart is zero; restart controls the guarded frame-one
request. Previous/current selection bookkeeping follows the association work.
Referenced-player ownership remains open.

Other descriptor transfers preserve three ordering constraints. Consuming a
pending request clears request data without releasing the player. Copying a
linked player's descriptor can precede destruction of that linked object;
the descriptor's complete backing lifetime remains open. A virtual callback
can change the later rebind gate, so that gate uses fields reread after the
callback. The nonpositive/positive descriptor choice and separately gated
primary substitutions are recorded on their owning routines.

## BTL wrapped frog player

`ccSkillJRY001Frog` owns an allocated animation player through an embedded
resource wrapper. The wrapper owns storage; completion reset and descriptor
selection do not release it.

The state transition first runs wrapper bookkeeping and increments its owner
counter. Position below -499 selects a virtual callback. Otherwise state 1
with transition readiness binds the second descriptor and requests frame 1.
Owner ID other than `0x54` then assigns step `0x200`; ID `0x54`
retains the step. Completion and counters clear before state 2 is established.

Wrapper bookkeeping, ordinary advance/repeat and submission are separate
virtual phases. Their full dispatcher order remains open. Submission requires
a resource, draw enable and nonpositive signed delay; it has no seek or advance.
Destruction releases the allocated player through the wrapper's ownership path.

## BTL GUW embedded player

`ccSkillGUW001` owns an embedded player whose storage survives selector
changes. The enable flag gates its local playback and submission.

| Selector | Resource | Explicit request |
| --- | --- | --- |
| 0 | `ANM_2guwcha1a` | None in the selector |
| 1 | `ANM_2guwcha1b` | None in the selector |
| 2 | `ANM_2guwcha1c` | Frame 1 when the current selector is still 2 and the track is valid |
| 3 or other | No resolved descriptor in this footer | Disable the embedded player |

A nonnull resolved descriptor binds with zero blend and enables playback.
The footer rereads the selector after earlier callbacks. Selection does not
assign a step or advance.

Two update routes share enable, transform and valid-track gates, consume the
player's current step, and ignore completion. The caller's later association
checks follow one route's playback. Their existence does not establish that
both execute in one scheduling cycle. Enabled submission assigns opacity 0.8;
a separate local object can still draw while the embedded player is disabled.

## BTL GAR and GAV primary-player transitions

GAR and GAV reuse the inherited primary player. Their local state changes bind
with zero blend and request frame 1 without directly advancing or assigning
its step.

| Owner | Transition gate | Descriptor choice |
| --- | --- | --- |
| GAR | Requested low-byte state 1 / 2 | Descriptor 0 / 1; state 1 clears the signed-byte counter before binding |
| GAV | State 0 and playback event | Descriptor 0, then state 1 |
| GAV | State 1 and virtual predicate false | Descriptor 1, then state 2 |
| GAV | State 2 and current playback event | Descriptor 2, then state 3 |

GAV clears its unsigned 16-bit counter on each listed transition.
Its later counter-2 event is separate from descriptor selection.
The recovered GAR update increments its signed-byte counter before dispatch:
state 0 with a playback event requests state 1, and state 1 at counter at least
31 requests state 2. A separate cleanup helper also requests state 2 before
resource cleanup. GAR's continuing body and both inherited-player schedules
remain open; the local counters establish no elapsed duration.

## BTL TOV variant-selected primary-player seeks

`ccSkillTOV001` stores the requested state before selection. The variant
bytes choose these resources, each bound to the inherited primary player with
a frame-one request:

| Requested state | Variant gate | Resource |
| --- | --- | --- |
| 1 | Variant 1 / other | `ANM_ptovcha14` / `ANM_ptovcha11` |
| 2 | Variant 1 / other | `ANM_ptovcha15` / `ANM_ptovcha12` |
| 4 | Variant 1 and secondary variant 1 / other | `ANM_ptovcha17` / `ANM_ptovcha16` |
| 4 | Variant other than 1 | `ANM_ptovcha13` |

The eighth setup resource is `ANM_2tovdash01`. Resource prefixes do not
establish action identities. States 0/3 do not seek. State 3 saves and clears
the counter and later clears the secondary variant. State 2's non-1 variant
sets limit 5 and clears its counter after selection; variant 1 omits those
counter writes.

Update increments the 16-bit counter before callbacks and state dispatch.
State 0 requests 1 unconditionally; state 1 requests 2 on the playback event.
State 2 variant 1 requires a nonzero predicate result to request 4, and result
exactly 1 sets secondary variant 1. Other variants require signed counter
greater than the signed limit.

State 3 instead requires signed counter greater than 10 and the resident
predicate result 1, then restores the saved counter and writes state 2
directly. This bypasses the setter and its seek. Neither local update nor
setter directly advances or assigns the primary-player step.

## BTL ASM requested-state primary-player seeks

`ccSkillASM001` has six requested states. States 1/2/3/5 select
`ANM_paswcha11/12/13/14` respectively and request frame 1 on the inherited
primary player. States 0/4 contain no direct seek.

| Calling phase | Requested state |
| --- | --- |
| Setup | 0 |
| State 0 with playback event | 1 |
| State 1 with virtual predicate false | 2 |
| State 2 with playback event | 3 |
| State 3 with signed counter greater than limit | 5 |
| State 4 with signed counter greater than 11 and resident predicate result 1 | Restore saved counter, then request 5 |
| Separate request helper | 4 |

Update increments its 16-bit counter before virtual/local work and dispatch.
These requests do not establish its inherited player's complete advance
schedule. State-4 restoration here still enters the setter, unlike TOV's
direct state-2 write.

## BTL KIB primary and looping embedded player

`ccSkillKIB001New3` owns a separate embedded player and also uses the
inherited primary player.

| State or phase | Player / resource |
| --- | --- |
| State 1, substitution and associated status gates all true | Primary, `ANM_pkibcha11`; subsequently enables local effect flags |
| State 1, other branch | Primary, `ANM_pkibcha15` |
| State 2 entry | Embedded, `ANM_pkibcha12` |
| State 3 entry | Primary, `ANM_pkibcha12` |
| State 4 entry | Primary, `ANM_pkibcha16` |
| State-2 completion | Embedded, rebind `ANM_pkibcha12` and request frame 1 |

Setup also resolves `ANM_pkibcha14/17`. Every listed request follows
zero-blend binding and a valid-track guard.

State-2 update prepares the transform, advances and composes the embedded
player, then repeats it on nonzero completion in that same invocation.
The earlier association branches choose position sources and converge before
playback. No step write separates advance, rebind and seek.

Only after this playback/repeat work does current unsigned counter greater
than 25 request state 4. That transition invocation can already have repeated
the embedded player. Submission uses state 2; state changes retain storage,
and destruction separately destroys the embedded player. The primary player's
full schedule remains open.

## BTL SKN and SKM counter-gated primary players

These owners use different state and counter gates for their frame-one
descriptor transitions:

| Owner | Gate | Local ordering |
| --- | --- | --- |
| `ccSkillSKN001` | State 1, unsigned counter greater than 10 | Clear counter, bind/seek, then increment current state |
| `ccSkillSKM001New3` | State 0, playback event | Create child first, bind/seek, clear counter, then increment current state |

The factories establish child creation and registration, not those children's
playback contracts. Neither state method directly advances or assigns the
inherited primary-player step. Counter thresholds are per invocation;
their elapsed duration and the primary-player lifetime remain open.

## BTL TYV parent and allocated-player object

The TYV parent and its allocated object have separate ownership and playback
contracts. Parent state 0 creates the object at unsigned counter 9, before
checking the playback event. That event binds `ANM_ptyvcha15` and requests
frame 1 on the inherited primary player. State 1 at unsigned counter greater
than 30 selects `ANM_ptyvcha12` and requests frame 1. The parent state
method does not directly advance that player.

The object owns an allocated player and composition. Setup binds
`ANM_ptyvcha11` and requests frame 1. A matching parent registration can
request object state 3 and clear its counter; this requests fading without
destroying the player.

All inspected object states converge on transform, opacity and valid-track
advance/composition. States 3/4 still reach that tail after fade or termination
handling; completion is ignored. A state change or fade alone therefore does
not establish a local pause. The outer phase wrapper can omit the update
through its enable, phase and countdown gates. Submission has no matching
local state/opacity/track gate. Storage release occurs later in destruction.

## BTL Sawarabi embedded-player array

Sawarabi owns 20 embedded-player records. Placement can stop setup early:
failure at the first query configures only the first record at a fallback
position; later failure stops further configuration. Unconfigured records
remain inactive.

Configured records bind `ANM_pkmvswrb00`, request frame 1, and enter state
0. The return descriptor is `ANM_pkmvswrb02`.

| Record state | Playback policy |
| --- | --- |
| -1 | Omit state and playback work |
| 0 | Decrement activation delay; omit advance while still positive, otherwise activate, advance/compose and increment current state |
| 1 | Advance/compose; completion increments current state and runs attachment handling |
| 2 | Decrement return delay; expiry binds the return descriptor, requests frame 1 and increments current state without ordinary advance |
| 3 | Advance/compose; completion marks the record inactive without destroying storage |

Missing tracks yield zero completion in states 1/3. State 2 remains eligible
for submission during its delay, while ordinary advance is omitted. Submission
excludes inactive and state-0 records.

Owner termination requires that no record passed the active-state check during
the entire update pass. Retiring the last record in state 3 therefore does not
terminate that same pass. Destruction later destroys all embedded records,
independently of playback-state retirement.

## BTL ZBZ and KMV counter-gated primary players

Both owners increment a wrapping 16-bit counter before dispatch, then reload
it unsigned for threshold checks. Their transition requests bind the existing
primary player with zero blend and seek frame 1.

| Owner | State 0 | State 1 | Resources |
| --- | --- | --- | --- |
| `ccSkillZBZ000New` | Playback event selects descriptor 0 and clears counter | Counter greater than 40 selects descriptor 1 without an event gate | `ANM_pzbzcha01/02` |
| `ccSkillKMV001` | Playback event clears counter and selects descriptor 0 | Counter greater than 45 clears counter and selects descriptor 1 | `ANM_pkmvcha11/12` |

KMV state 1 also creates local resources at counter 5, then continues to the
separate greater-than-45 check. State 2 with a playback event marks completion
and calls the virtual continuation instead of these seek branches. ZBZ's
ordinary update/draw slots are empty; its state method is a separate phase.
Neither state method directly advances or assigns the referenced player step.

## BTL Water Dragon embedded player

Water Dragon owns an embedded player. Setup binds `ANM_psrdbod1`, requests
frame 1 and installs `skill_authored_event_bridge` before inspecting prior
activation. A previously active valid player then advances using its prior
step; only afterward does setup enable playback and assign step `0x140`
and opacity 0.8. Initialization and later rate assignment are distinct phases.

Periodic update requires enable and state other than 1. Attachment command
delivery can still run in state 1 for an enabled player with an attachment.
Later state changes occur after the current advance decision. Submission
requires enable without a state-1 exclusion, so a state-1 player can remain
drawable while ordinary periodic advance is omitted.

The explicit transform/update method advances/composes first, then separately
requests frame 1 without an intervening bind or step write. It has no local
enable or state-1 gate. Its request does not replace that invocation's ordinary
advance. The full dispatcher order and callers remain open.

## BTL ANB embedded and associated players

ANB owns an embedded player and references associated, linked and controller
players. Setup resolves 17 descriptors from a resource-ID-selected name bank,
binds embedded descriptor index 9, requests frame 1 and installs
`skill_authored_event_bridge`, then disables ordinary embedded playback.
The initial seek alone does not enable submission or advance.

State 1 selects the first inclusive interval matching its range value:

| Range | Index | Embedded descriptor index |
| --- | ---: | ---: |
| `[0,0.5]` | 0 | 9 |
| `[0.5,0.8f]` | 1 | 10 |
| `[0.8f,1]` | 2 | 11 |
| No match | -1 | 8 |

Shared boundaries use the earlier interval. Changed index causes zero-blend
binding, frame-one selection and callback installation. The -1 index has no
additional local rejection. Enabled state-1 playback can then advance in the
same update's shared tail.

| Phase | Request |
| --- | --- |
| State-4 associated-player transition | Descriptor 9 at frame 3 for frame variant zero; descriptor 4 at frame 6 otherwise |
| Requested state 4 | Associated descriptor/frame pair chosen by geometry; embedded descriptor 10 at frame 1 when range index is zero |
| Later requested-state-4 linked branch | Associated primary descriptor on linked player, reusing frame 3 or 6 |
| Requested state 5 with next frame variant zero | Embedded descriptor 10 at frame 1 |
| Controller selector | Selected descriptor at frame 1, then clear controller counter |

Associated-player predicates can select a null binding. The update-side
state-4 transition additionally requires its counter/geometry path, a present
fighter, negative height and an armed transition, which it clears before
selection. These requests retain existing player storage.

The requested-state method saves the previous state and accepts cases 0..10.
State 0 enables embedded playback. State-4 update and requested state 4 both
call the earlier primary endpoint/advance helper before later requests.
Controller selection also occurs in requested states 1/3/4/6/7/8/9.

The shared advance tail accepts any nonzero enable value; the earlier
attachment/position branch requires exactly 1. Completion is stored, or zero
for a missing track. Submission shares the nonzero enable gate, while a
separate object can draw regardless. All enable producers, remaining cases
and full phase order remain open.

## BTL FOR embedded-player pair

FOR owns two embedded players. Selector 2 binds both descriptors, requests
frame 1 and enables both records, then calls their transform/update helpers.
Ordinary advance can therefore follow those requests in the same invocation.
Selector 3 clears both enable flags without destroying storage.

The helpers perform timer-driven transform work before their common playback
tails. An enabled valid player advances/composes with its current step.
The first helper then replaces that step from `next_step`, even when its
advance gate was closed; the second has no corresponding replacement.
The `next_step` producer remains open. Completion is ignored.

Submission uses each record's enable flag without a completion gate.
Destruction separately destroys both embedded players. The full phase order,
cadence and remaining record-control producers remain open.

## BTL TND embedded-player group

TND owns one embedded main player and three embedded child records.
Initial setup binds a common child descriptor, requests independent randomized
frames, clears both child completion controls, requests frame 1 on the main
player and activates the group.

For child frame count `F>=3`, the requested frame is chosen from
`1..F-2` by the inclusive random helper. A preceding random call with
argument 3 does not supply the seek target. The resources' general minimum
frame-count guarantee remains open.

Active update advances unlatched child players. Completion latches only when
`stop_on_completion` is set. Main-player advancement is absent from this
local group helper. Child reassignment binds, requests frame 1 and enables
completion stopping, but leaves an existing completion latch set. Reassignment
alone therefore does not resume a latched child.

Draw requires an active group and no draw suppression, then submits main and
child players without checking child completion latches. A latched child can
remain drawable while its ordinary update is omitted. Destruction releases
embedded storage separately from these controls.

## BTL CHY supplementary player

CHY allocates its supplementary player only when `ANM_pchycha03` resolves.
It binds with zero blend and requests cursor zero. The equal-cursor return
means this request alone does not establish evaluation of frame-zero records.

Earlier owner events and randomized callbacks converge on the supplementary
player's update. A present valid player advances/composes with its own step;
completion is ignored. Submission's geometry predicates select the render
context, then draw the player. They do not suppress that draw.
Destruction later destroys and clears the allocated player.

## BTL wall and gate players

Wall and gate own separate allocated players, share the same gated owner
counter producer, and advance only at even phase-counter values. Odd values
still reach transform and contact handling, while leaving the previous
completion value intact.

| Owner | Resource / construction step | Endpoint request |
| --- | --- | --- |
| `ccSkillHKG001Wall` | `ANM_phkgwal00`; setup requests frame 1 | `F-1` without a step change |
| `ccSkillSKV001Gate` | `ANM_pskvcha13`; allocation at counter zero with a null player slot, frame-one request, then step `0x40` | `F-1` without a step change |

Counter zero caches `OBJ_wall_top`. A qualifying segment-probe result after
the parity-selected playback assigns step zero and clears that cache while
retaining the player. Zero step and omitted odd-counter advances are therefore
separate controls.

`skill_auxiliary_update_banks` increments the phase counter only in its
enabled ordinary bank after countdown handling. Its alternate phase bank
increments a different signed halfword. The relation between that counter
phase and playback phase remains open; even-counter gating does not establish
an advance every two rendered frames.

Submission has no corresponding parity gate. Destruction separately destroys
and clears each owned player.

## BTL linked-player owners

Each linked node owns a player plus flags, an optional render context and a
next pointer. Setup constructs nodes in the following resource order, binds
with zero blend, requests cursor zero and prepends each node. The request alone
does not establish frame-zero evaluation.

| Setup family | Resource names in construction order | Installed masks |
| --- | --- | --- |
| TYVC | `ANM_ptyvcha03/04` | 0, 0 |
| INW | `ANM_pinwcha03` | 1 |
| SNW | `ANM_psnwcha04` | 1 |
| TNW | `ANM_tnw_effect` | 1 |
| TYW | `ANM_ptywcha03` | 1 |
| BDY33 | `ANM_pbdycha33/34` | 2, 1 |
| ORW | `ANM_porwcha03..08` | 2, 2, 2, 2, 2, 1 |
| SSW | `ANM_sswcha0_effect` | 1 |
| JRW | `ANM_pjrwcha03/04` | 1, 2 |
| SAI | `ANM_psaicha03` | 2 |
| BDY13 | `ANM_pbdycha13` | 2 |
| BDY43 | `ANM_pbdycha43..47` | 2, 3, 2, 2, 2 |
| BDY22 | `ANM_pbdycha22/23` | 2, 1 |
| BDY03 | `ANM_pbdycha03/04/05/06` | 2, 2, 2, 1 |

These labels identify resource families, not player-facing actions.
The first BDY33 node is also retained as `first_node`.

Common and inspected specialized passes set transforms, then advance/compose
every valid node. Mask bit 0 clear uses owner position/rotation; bit 0 set uses
constant position and zero rotation. Masks 0/2 therefore use owner vectors,
and masks 1/3 use the constant branch. Bit 1's meaning remains open.
Completion is ignored and does not unlink a node. Later owner events follow
the inspected list passes and cannot gate advances already performed.

Submission walks the same list without seek or advance. A nonnull node
context temporarily overrides the default context; the prior context restores
between nodes and at return.

Release saves the next pointer, destroys the player's internals and frees each
node. The inspected release helper leaves the owner head uncleared.
Virtual wrappers connect update, submission and release, but their full
dispatcher order and all shutdown routes remain open.

## BTL descriptor-switched player array

This owner holds four players and four per-instance offsets. Setup replaces
the previous arrays, resolves `ANM_pnwvcha10t..14t`, binds the first
descriptor and requests frame 1 on each valid player, then calls common update.

| Entry state / transition gate | New state / resource | Requested frame |
| --- | --- | --- |
| -1, playback event | 0 / `ANM_pnwvcha11t` | Independent random `1..F` |
| 0, virtual predicate false | 1 / `ANM_pnwvcha12t` | 1 |
| 1, playback event | 2 / `ANM_pnwvcha13t` | Independent random `1..F` |
| 2, incremented counter greater than signed limit | 3 / `ANM_pnwvcha14t` | 1 |

The positive-`F` random range includes endpoint `F`, with no additional
local clamp before seek. These are phase-selection requests rather than
variable increments.

All inspected state branches then call common update. Its associated-player
predicate chooses an extra transform-vector copy; both branches reach ordinary
array advance. Geometry handling is therefore not a local playback pause.
Completion is ignored. Later passes apply instance offsets and copy associated
opacity, or zero when absent.

Submission draws the array without playback. Cleanup destroys the player array
and releases the offsets, clearing both pointers. State transitions reuse the
arrays; the full upstream schedule remains open.

## BTL buddy-resource descriptor changes

Buddy setup obtains containers through `buddy/2%sbdy.ccs` and
`buddy/2%sbdy%d.ccs`, owns an allocated player, and resolves five
descriptors through `ANM_p%s%s%d`. The formatted names do not establish
an arbitrary instance's character or action. Setup installs
`fighter_event_dispatch`, requests frame 1, then forces selector zero;
the early setup request is not its final descriptor selection.

| Requested reason | Descriptor role / index |
| --- | --- |
| 1 | nut / 1 |
| 2 | act / 3 |
| 3 | ext / 4 |
| 4 | ent / 0 |

The general selector skips replacement only when unforced and already selected.
Selector/state replacement binds with zero blend, requests frame 1 when valid,
clears completion and sets one-invocation suppression. Local state-zero and
substate handlers also make replacements under their own gates. These 15
requests establish descriptor transitions, not periodic looping.

Rate preparation precedes the outer gate. It copies the primary fighter
player's step when `battle_nested_state_is_3` succeeds. Otherwise effect
`0x4A` and geometry at most 400 choose step `0x40` and rate 0.25;
the other branch uses `0x100` and rate 1. The copied-step branch stores
step divided by 256 as rate. The nested object's word `+0x14` has no
established high-level meaning.

Cursor-change bookkeeping and the separate step accumulator both run before
the lifecycle gate. Nonzero lifecycle omits later state, playback and transform
work; lifecycle 1 becomes 2. This gate does not stop the earlier accumulator.

With lifecycle zero, state handlers run before the advance decision and can
set suppression in the same invocation. Suppression skips ordinary
advance/composition and command delivery once, then clears while transform
handling continues. Otherwise valid playback stores completion; missing tracks
store zero. This is distinct from the outer lifecycle gate.

Submission also requires lifecycle zero but performs no playback.
Cleanup destroys and clears the player, effect and composition in sequence.
Complete container retention, all lifecycle producers and upstream scheduling
remain open.
