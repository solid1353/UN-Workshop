# Projectile motion and local timing

Retail NA2 projectile callbacks combine launch velocity, steering, direct positioning, contact responses, child emission, and several independent clocks. Configuration and lifetime belong to [Projectile lifecycle](projectiles.md). Routine names and layouts are maintained in `@annotations/NA2`; this document describes how those routines combine.

## Research coverage

The 60 distinct factory motion bodies, common candidate/commitment order, selected Clay/Ink guide producers and cleanup, five carrier command publications, and seven representative callback compositions are established by static analysis of retail `BTL.BIN` and its called resident services. The tables retain their game values and gates.

Nested services, complete class state machines, unselected guide interpolation modes and key blocks, remaining carrier row payloads and producers, and external resource lifetimes remain open. COP1 conversion rounding and callback cadence are not established; clocks and counters below imply neither frames nor seconds.

Shared random services belong to [Randomness](../../runtime/randomness.md#mt-wrappers), collision internals to [Collision](../combat/collision.md#resident-segmentenvironment-broad-and-narrow-phases), resource execution to [Animation runtime](../../runtime/animation_runtime.md) and [CCS runtime](../../game/files/ccs_runtime.md), and damage to [Damage](../combat/damage.md).

## Continuing state-2 motion and position commitment

The continuing state-2 path in `projectile_contact_response` calls motion, computes a candidate through `projectile_candidate_position`, admits contact for response modes outside `3/4` when `setup81 == 1`, and finally calls commitment. Earlier response branches can take other paths.

```text
step = min(projectile.accumulator_step, manager.side_steps[inverse-side])
candidate.xyz = position.xyz + (state_vector + state_vector2).xyz * step
candidate.w = 1
```

`transient_actor_opposite_side` supplies the inverse side. Candidate calculation leaves the current position intact; root `projectile_commit_position` copies all four components only with `commit_enabled != 0`. Derived contact or commitment can therefore affect the final position after motion has run. Direct-position callbacks must be assessed with this later commitment order.

`projectile_setup_linked_helper` initializes speed (`scalar1`) from `config.initial_scalar` only at sentinel `-1`; that branch also copies the inverse-side manager step and enables adaptive stepping. `transient_manager_reset` sets both manager steps to `1`.

After the positive-delay and inactive gates, `projectile_update_local_step` preserves the instance step when adaptive stepping is disabled. Otherwise it chooses the same-tag fighter, uses `fighter_has_effect(fighter, 0x4A)` and `vector_distance`, and sets the step to `0.25` when the effect is present within distance `400`, or `1` otherwise. This consumer establishes the membership gate, without defining the effect's broader behavior.

At the admitted root update's tail, `accumulator` gains the instance step while signed `active_count` gains one. Position uses the minimum of instance and manager steps; derived callbacks can use the instance step, an unscaled counter, or their own multiplier. These quantities remain distinct.

Below, `q = accumulator_step`, `int(x)` means the observed COP1 conversion with rounding mode unresolved, `bounded_draw(n)` is `prng_inclusive` (unsigned remainder modulo `abs(n)+1`), and signed draws use `rng_signed_scaled`. Ordinary nonnegative bounded inputs include both endpoints.

## Straight and distance-scaled launch vectors

`ccProjectileStraight` motion `projectile_straight_motion` initializes only
when byte `first_activation == 1`: it enables `service_enabled`, signals `handle`, normalizes
`spawn_vector2 - position` into `direction`, and writes
`state_vector = direction * scalar1`. It clears `first_activation` and performs the
position-associated call `effect_emit_scaled_position(0.5f, position)`. Later calls
to this body leave that launch velocity unchanged. Movement and contact then
use the common candidate/commitment path above.

Config `0x31` has a preliminary aim adjustment: it compares the sign of
`(spawn_vector2 - spawn_position).x` with the opposite-tag fighter's `orientation[2]`, and reverses
that x difference if their signs disagree. With byte `same_section == 0`, it instead
resets the aim to `spawn_position` and offsets x by `+100` or `-100` according to that
fighter scalar. These are config-specific branches, not a general Straight
target acquisition policy.

`ccProjDist2Speed` and `ccProjKNWbuddy` share motion
`projectile_dist2_speed_motion`. Their first-call direction starts from
`spawn_vector2 - current position`; signed halfword `local_phase == 0` adds vector `post_spawn_vector`
before normalization. The distance used to choose speed is separately measured
between `spawn_vector2` and `spawn_position`, without that vector addition. If signed record
word `config.value38 != -1`, launch initialization replaces
`scalar1` with:

```text
clamp(distance / float(config.value38),
      float(config.value40), float(config.value3c))
```

The three inputs are signed words converted numerically to floats, not float
bit patterns. The body stores normalized direction in `direction`, scales it into
`state_vector`, and clears `first_activation`. The ratio is a launch-time speed selection;
this body does not recompute it on subsequent motion calls.

## Parabola vertical update

`ccProjectileParabola` and `ccProjectileNumbnessBall` share motion
`projectile_parabola_motion`. First activation enables `service_enabled`, clears
`initialized/first_activation`, and signals `handle`. If scalar `scalar2 == -1.0f`, it calls
automatic launch solver `projectile_parabola_solve_launch`; otherwise it normalizes
`spawn_vector2 - spawn_position` and scales it by speed `scalar1` into `state_vector`.

That initial branch falls through into helper
`projectile_parabola_gravity` on the same invocation. The velocity update is:

```text
state_vector[2] -= scalar2 * q
state_vector[2] = max(state_vector[2], -60.0f)
```

Each continuing call applies this helper and normalizes the resulting velocity
into `direction`. Config `0x36` additionally increments angle `orientation[1]` by the float
bits `0x3E80ADFD` (approximately `0.25132743`) and wraps it around the pi
boundary. That angular increment has no `accumulator_step` multiplier in this body.

The automatic solver `projectile_parabola_solve_launch` writes acceleration `scalar2 = 3.0f`.
It can revise the aim for configs `0x30/0x9A` using the same-tag fighter's
position and a height result; it also compares opposite-tag direction
and the two fighters' halfword `section` in config-specific branches. The bounded
solver at `projectile_parabola_solve_launch` uses horizontal difference `X`, vertical
difference `Z`, speed `s = scalar1`, and `g = 3`:

```text
a = g * X * X / (2 * s * s)
b = -abs(X)
c = Z + a
D = b*b - 4*a*c
angles = atan((-b + sqrt(D))/(2*a)), atan((-b - sqrt(D))/(2*a))
```

For configs `0x36/0x3B` when the fighters' `section` values differ, `X` is
the length of the aim-minus-spawn xy vector and the resulting velocity is
rotated back by its xy bearing. Otherwise `X` is the x difference. The reference
angle is `atan(abs(Z/X))`, or zero for zero x difference.

The solver sorts the two roots as low/high and
first tries the low root. For each root it calculates
`t = abs(X)/(s*cos(angle))` and height
`spawn.z + t*s*sin(angle) - 0.5*g*t*t`. Low is kept when its height plus
`150` reaches the target height; otherwise high is tried. If neither reaches
that comparison, the result is high when the reference angle exceeds low,
otherwise `max(low, btl_converted_scalar30)`. The retail word at that constant
address is zero. These comparisons select the launch angle; continuous trajectory predictions do not establish exact equality with the discrete updater.

For negative `D` or zero `X`, the fallback compares `abs(X)` with double
`5.0` through predicate `double_less_than`. Its true branch selects either
sign of pi/2 according to target height. Its other branch wraps
`reference-angle + 0.55` around pi and takes the minimum with the float at
`btl_converted_scalar50`, also zero in retail. A negative x difference reflects
the selected angle as `pi - angle` and wraps it again. The final stores are
`velocity.x = s*cos(angle)` and `velocity.z = s*sin(angle)`; the motion
callback then applies the first gravity update described above.

Parabola contact slot `projectile_parabola_contact` first calls root contact
response `projectile_response32(self, candidate, 1)`. Only configs `0x30/0x9A` then run
its extra emission path. It admits object flag `contact_flags` bit `4`, or bit `5`
(also remembering bit `3`), or contact-query result bit `4` from
`projectile_query_contact`.

- Config `0x30` emits one config `0x44` at the candidate position.
- Config `0x9A` normally emits two config `0x9B` children, reduced to one
  when object flag bit `5` admitted the path. Each starts from the projectile
  position, with a direction-dependent x offset of `200 * child-index`; the
  code probes a vertical segment with `150`-unit endpoints using resident
  `collision_segment_query`. A failed probe preserves the attempted position; a successful
  probe uses the returned point with a `10`-unit adjustment.
- Successful children get delay `delay = 10 + 2*child-index` and the observed
  parent lineage copy. Bit `5` clears child `ProjectileParabolaChild.child_flag`; with that branch
  and remembered bit `3`, it also sets child `ProjectileParabolaChild.phase = 3`.

After the loop it signals the parent handle and writes common `state_count = 1`,
`state = 6` directly. This does not call the common
[state-6 helper](projectiles.md#state-6-transition-helper).

## Homing target data and the delayed strategy

`projectile_homing_activate` initializes direction from aim minus spawn and enables collision. Unless `ProjectileHoming.control_supplied` is set, record words `value3c/value40` supply signed steering start/end, the reserved word is cleared, and `value48` supplies the turn scalar. `projectile_homing_set_control` copies the supplied 16-byte control block and sets that preservation flag.

`projectile_homing_motion` resolves the same-tag fighter whenever its steering route runs. Its aim is the fighter's current position, the selected height-service adjustment, and `post_spawn_vector`. The steering control block is separate from this bias. With `steering_enabled == 1` and `steering_start <= s16(int(accumulator)) < steering_end`, turn amount is `turn_scalar*q`; otherwise it is zero.

Steering normalizes desired/current directions, snaps when their dot product exceeds the cosine of the admitted turn, or rotates about their normalized cross-product axis. The result becomes `direction` and speed-scaled `state_vector`. Fighter major state `1` with substate `21/22`, or manager x-bound failure, clears the turn scalar after the current turn amount has been computed. Config `0x10` reaches a separate signed retirement threshold and directly selects state `6`, clears `state_count`, signals the handle, detaches notification, and disables the optional service.

`projectile_homing_delay_post_spawn` numerically converts record words `value38/value3c/value40` to speed and the two float steering-window bounds; `value48` supplies the turn scalar. It sets `post_spawn_count = -1`, and config `0x1B` also sets `homing_mode`. `projectile_homing_delay_motion` has three private phases independent of common state:

| Phase | Motion and transition |
| --- | --- |
| Activation | Enables collision, clears first activation, normalizes aim-minus-spawn into `state_vector2`; selects phase `0`, or `1` when the wait is `-1`, then executes the selected phase immediately. |
| 0 | Decreases speed by `8*q`; at nonpositive speed clamps to zero, selects phase `1`, and clears the phase count. |
| 1 | Decrements the signed wait by one. At nonpositive wait selects `2`, clears phase count and accumulator, sets speed `50`, and snapshots the same-tag fighter's position into the aim with its height exception and `post_spawn_vector` bias. |
| 2 | In the stored float window, turn amount is the turn scalar times `q`, otherwise zero. Steers toward the snapshot; leaving manager x bounds clears the turn scalar. |

Every continuing phase publishes the chosen direction and speed-scaled velocity, clears its fourth component, and increments the unscaled phase count. The default `-1` wait takes activation through phase `1` into phase `2` on the same call. Homing reacquires a live position; HomingDelay phase `2` uses its earlier snapshot. Neither retains the selected fighter pointer. The common side tag does not by itself establish ownership.

## SoundWave phases and repeated events

`ccProjSoundWave` motion `projectile_sound_wave_motion` calls Homing
`projectile_homing_motion` before its private `phase` byte. Constructor initialization
clears that byte and event threshold `event_threshold`. Activation at `projectile_sound_wave_activate`
loads signed countdown halfword `countdown` from record word `config.value38`; its
Homing steering inputs retain the record `config.value3c/config.value40/config.value48` contract.

In phase `0`, a single `event_threshold < accumulator` check emits a resident-service event
and adds `5.0f` to the threshold. It does not loop to catch up missed thresholds.
The same phase subtracts `1.5f` from speed `scalar1` and clamps at zero, without
a step multiplier. It decrements `countdown` by one. Once the new signed value is
negative, it emits another event, ends the three private effect references via
`projectile_sound_wave_release_effects`, resets the countdown to `20`, and increments phase to `1`.
Phase `1` decrements that countdown by one; a negative result writes common
state `6` and clears `state_count`. Contact slot `projectile_sound_wave_contact` also ends those three
references when root response sets `contact_flags` bit `0`. The events are
recorded as scheduling operations without assigning damage or audio meaning.

## Kibakukunai contact and private countdown

`ccProjectileKibakukunai` motion `projectile_kibakukunai_motion` first builds a
normalized launch vector from `(spawn_vector2 - current position) + post_spawn_vector`, with the
observed 42-vector random selection scaled by `7.5f` and its y word cleared.
It scales direction by speed, enables collision, clears `first_activation`, sets private
word `phase = 1`, and initializes float `countdown = 17.0f`.

Phase `1` copies velocity into `direction`, subtracts `accumulator_step` from the countdown,
and writes its integer conversion into halfword `exposed_countdown`. Phase `2` likewise
subtracts the step. A negative countdown in either phase invokes
`projectile_kibakukunai_enter_phase3`: clear common counter `active_count`, signal the handle, set private
phase `3`, and set `exposed_countdown = -1`. Phase `3` calls `projectile_response_kibaku_phase` rather than
continuing the launch countdown. Byte `repeated_event` additionally admits a repeated
event when signed `active_count % 5 == 1`.

Contact slot `projectile_kibakukunai_contact` skips its query in phase `3`.
Otherwise query result bit `1` routes to `projectile_response_contact_complete`. Bits `2/3` stop speed
and velocity and signal the handle. Bit `3` immediately performs the phase-3
transition; bit `2` instead sets phase `2`, clears byte `contact_phase_enabled`, and calls
`projectile_kibakukunai_phase2_service`. This is a private phase change, not a common state-6 write.

## Kibakufuda contact, countdown, and nine-row emission schedule

`ccProjectileKibakufuda` motion `lcg_vector_difference_update` uses private
phase byte `position_service_enabled`. Initial motion clears velocity and speed, sets acceleration
increment `acceleration_increment = 0.5f`, and sets angular rate `angular_rate` to `+10` or `-10`
according to opposite-tag fighter's `orientation[2]`.

Phase `0` adds the quantized rate times `accumulator_step * pi/32768` to `angle`
and wraps around pi. It increases speed by `acceleration_increment` without a step multiplier,
caps it at `10`, writes vertical velocity `-speed`, and horizontal velocity
`20 * sin(angle)`. Accumulator `accumulator > 300.0f` writes common state `6`
and countdown `state_count = 10` by the motion callback.

Contact slot `projectile_kibakufuda_contact` uses two segment queries.
The first uses mask `0x20000001`, adjusts the returned vertical coordinate by
`5`, and sets attachment byte `attachment = 1`. The second uses mask `0x40000002`,
stops x velocity on a hit, and, when result flags include `0x200`, sets angle
`orientation[2]` to either sign of pi/2 and attachment byte `2`. Either admitted
attachment, while private phase is not `2`, clears speed/acceleration/velocity,
clears common counter `active_count`, sets float countdown `position_service_argument = 29.0f`, and
sets phase `1`. Without that admission it does not advance the phase.

When predicate `projectile_context_predicate` returns zero, phase `1` subtracts
`accumulator_step` from `position_service_argument` and exposes its integer conversion in `exposed_countdown`.
A negative result, or positive registration count `registration_count` tested by helper
`projectile_kibakufuda_has_registration`, sets phase `2`, clears `state_count`, and writes `exposed_countdown = -1`.
Phase `0` can also enter phase `2` through that registration-count predicate.

Phase `2` disables collision byte `service_enabled`. Except for config `0xA0`'s separate
child-emission route, it scans exactly nine rows at `projectile_kibakufuda_schedule`, stride
`0x30`, when predicate `projectile_context_predicate` is zero. A row runs only when
its `counter` equals signed counter `state_count`. The row's `offset` xyz vector is added to the current position, and `child_config` supplies the child config;
`retire` can write common state `6`. The complete bounded schedule is:

| Row | Counter | Position offset x/z | Child config | State-6 byte |
| ---: | ---: | --- | ---: | ---: |
| 0 | 0 | `0 / +50` | `0x29` | 0 |
| 1 | 0 | `+50 / -120` | `0x2A` | 0 |
| 2 | 0 | `-50 / -120` | `0x2A` | 0 |
| 3 | 0 | `+100 / -120` | `0x2A` | 0 |
| 4 | 0 | `-100 / -120` | `0x2A` | 0 |
| 5 | 4 | `+250 / +50` | `0x28` | 0 |
| 6 | 8 | `+500 / +50` | `0x28` | 0 |
| 7 | 4 | `-250 / +50` | `0x28` | 0 |
| 8 | 8 | `-500 / +50` | `0x28` | 1 |

Every row's y offset is zero. Matching rows all run on the same invocation;
this includes the five counter-zero emissions. Phase `2` increments `state_count`
by one even when the predicate suppresses the table scan, so skipped
equalities are not retried by this body. Config `0xA0` calls child helper
`projectile_kibakufuda_emit_a0(self, 2)` and writes state `6`, then follows the same counter
increment. These schedule values are callback counters, not frame durations.

## Chase's local phases

`ccProjectileChase` and `ccProjectileNrwCombo` share motion
`projectile_chase_motion` and activation `lcg_vector_chase_initialize`.
Here common halfword `state_count` also selects the local movement phase; it must
not be treated as a universal countdown. Activation selects `3` for config
`0x51`, otherwise `2`, and initializes float clock `clock = -1`. Unless
record float `config.value48` is `-1`, it supplies turn amount `turn_scalar`; byte
`same_section == 0` clears that amount. Unset float `launch_delay` becomes `8`.

The motion body uses the same-tag fighter's position, with the observed
height exception, unless byte `stored_target == 1` or sticky `flags` bit `0`
selects stored point `spawn_vector2`. That flag becomes sticky when stored byte
`opposite_section` differs from the fighter's signed halfword `section`. The body
increments `clock` by `accumulator_step` only on paths reaching its final tail.

- Phase `2` waits for `accumulator >= launch_delay`, then selects phase `3`, resets
  `clock = -1`, and initializes normalized target-minus-position velocity
  scaled by speed. Byte `stored_launch_target` chooses the resolved point or stored `spawn_vector2`.
- Phase `3` admits steering only with byte `steering_enabled != 0` and
  `clock < steering_deadline`. It uses float `turn_scalar` directly as the angle limit,
  without multiplying it by the step in this body. Configs `0x56/0x57`
  additionally have fighter-state/direction branches that choose an x point
  `5000` units away instead of the normal steering route.
- Phase `1` can clear velocity and auxiliary vector on `flags` bit `1`.
  When predicate `projectile_classify_contact(self, 0)` returns `2`, it can directly move
  position by a normalized `20`-unit step toward the fighter if distance
  exceeds `50`. Its early return branches signal the handle and do not reach
  the local clock increment.

Contact `projectile_chase_contact` skips its query in phase `1`.
Query result bit `1`, or bits `2/3`, cause config-specific completion for
`0x51/0x57`; `0x51` clears velocity, speed, and collision and writes state
`6`, countdown `10`, while `0x57` writes state `6`, countdown `0`.
For other configs those routes call `projectile_response_contact_complete` or `projectile_response_contact_motion` instead.
Config `0x57` also terminates on bits `4/5`, with the observed signed
`100`-unit x adjustment to the candidate. Its angle/transform callbacks are
described in [callback composition](#representative-callback-composition).

## Clay motion clocks and guide sampling

The class-local multiplier in the Clay callbacks below is distinct from both
`q` and the manager scalar used by the later common candidate step.

| Class / motion body | Local clock and multiplier | Motion and completion |
| --- | --- | --- |
| `ccProjClayBrdN`, `projectile_clay_brd_n_motion` | `dt = motion_multiplier*q`; guide `clock` | Phase `100` advances the guide clock by `dt`, samples owned guide `guide`, and steers toward sampled position `sample_position`. At clock `>= guide.endpoint - 1`, calls `projectile_retire_motion_a(self, 0)`. Phase `200/300`, if byte `retirement_requested` is zero, calls `projectile_emit_clay66_retire/projectile_emit_clay67_retire`, emitting child config `0x66/0x67` before their state-6 work. |
| `ccProjClayBrdS`, `projectile_clay_brd_s_motion` | `dt = motion_multiplier*q`; `clock += dt` | Uses the same guide sampling and angular steering pattern. Completes through `projectile_retire_motion_a(self, 0)` at `clock >= guide.endpoint - 1 - cutoff_adjustment`. |
| `ccProjClayBrdU`, `projectile_clay_brd_u_motion` | `dt = motion_multiplier*q`; `clock += dt` | Continually steers toward normalized `spawn_vector2 - spawn_position`, with angle limit `turn_scalar*dt`. Scales the chosen direction by speed and then by `motion_multiplier`. At clock `>= deadline`, calls `projectile_retire_motion_a(self, 0)`. |
| `ccProjClaySpd`, `projectile_clay_spd_motion` | `dt = motion_multiplier*q`; `clock` advances only with byte `clock_enabled != 0` | Private vertical speed `vertical_speed -= g*q`, with `g` from float bits `0x3FFAE148`; writes x velocity `horizontal_direction*speed`, z velocity `vertical_speed`, then scales the vector by `motion_multiplier`. Contact controls recovery, described below. Clock `>= deadline` enters a state-6 helper. |
| `ccProjClaySpd2`, `projectile_clay_spd2_motion` | Same `dt`, conditional clock, gravity, and vector scaling | On admitted contact in phase `0`, same/opposite fighters must have equal `section`, `abs(dx) < proximity`, and `abs(dz) < 100` to set phase `1`, choose horizontal direction toward the fighter, and restore speed from `stored_speed`. Phase `1` contact clears vertical speed. The same deadline completes it. |

Bird N/S call guide setter `projectile_guide_set_cursor(guide, clock)`, which clamps guide
`guide.cursor` to `0..guide.endpoint`, then sampler `projectile_guide_sample` returns a
position, angles, and a further vector of parameters. Their steering limit is
the latter vector's x float times `dt`. Bird N/S derive speed as
`(length(new sampled position - old sampled position) + parameter-vector.y)
/ dt`, copy direction to `direction`, then scale velocity by that speed and the
class multiplier. Thus speed is not simply guide-point distance divided by
time: the sampled y parameter is an additional input. The selected guide
producers and their binding ownership are established in
[guide construction and binding](#guide-construction-and-binding). A complete
curve-interpolation audit is outside this projectile-facing contract.

Bird N private phase halfword `local_phase` selects its route. Phase `0` adds `q`
to `clock` and derives an oscillating velocity around spawn `spawn_position`;
clock `> 90` selects its completion route. Phases `10/20/40` install guides
from `projectile_clay_bird_n_guide0/projectile_clay_bird_n_guide20/projectile_clay_bird_n_guide40`, with channel strides of
`8/9/9` key records, clear the clock, and select `100`; phases `20/40`
multiply `motion_multiplier` by `1.1`.
Phase `30` selects `300` directly and, when byte `retirement_requested` is zero, calls
child/completion helper `projectile_emit_clay67_retire` on that same invocation.
The guide pointers are route data, not newly emitted projectile configs.

Activation inputs are class-specific; `r` below is `rng_signed_half_unit`'s
`float(int32(random word)) / 4294967296.0f`, whose shared contract is in
[randomness](../../runtime/randomness.md#mt-wrappers).

| Setup / entry | Direct record or supplied-block inputs |
| --- | --- |
| Bird N, `projectile_clay_brd_n_activate` | Signed record word `config.value40 / 100` supplies `motion_multiplier`. The record-tail/helper consumers remain in [tail-field consumers](projectiles.md#tail-field-consumers-and-mutable-records). |
| Bird S, `rng_half_unit_object_initialize` | Without supplied block `supplied_block`, cutoff adjustment `cutoff_adjustment = 5*(r+1)` and multiplier `motion_multiplier = 1`. With that block: signed `base/range` give adjustment `base + range*(r+1)/2`, and signed `percentage / 100` supplies the multiplier. |
| Bird U, `rng_half_unit_base_initialize` | Record signed words `config.value38/config.value3c` give deadline `deadline = config.value38 + config.value3c*(r+1)/2`; word `config.value40 / 100` supplies `motion_multiplier`, and float `config.value48` supplies turn scalar `turn_scalar`. A supplied block `supplied_block` uses the corresponding `base/range/percentage` and `speed_spread` fields. |
| Clay Spd, `rng_half_unit_pair_initialize` | Record words `config.value38/config.value3c` produce the same deadline form in `deadline`; word `config.value44` produces recovery threshold `recovery_threshold = config.value44*(r+1)/2`; word `config.value40 / 100` supplies `motion_multiplier`. Float `config.initial_scalar` and a signed draw with range float `config.value48` produce stored `stored_speed`. Byte `local_mode != 0` instead sets deadline `9999`, recovery threshold zero, and stored speed zero. |
| Clay Spd2, `rng_half_unit_size_initialize` | Multiplies existing deadline `deadline` by signed record word `config.value38`; word `config.value40 / 100` supplies `motion_multiplier`. Word `config.value3c` gives proximity `proximity = config.value3c*0.6 + config.value3c*(r+1)*k`, with `k` from float bits `0x3E4CCCCC`. Speed uses the same `config.initial_scalar/config.value48` inputs. |

Clay Spd contact helper `projectile_query_motion_flags` returns a word of flags. On flag
`0x20000000`, byte `local_mode` chooses whether to zero the deadline or to
start its clock and clear vertical speed. If clock exceeds recovery threshold
`recovery_threshold`, it increments word `recovery_count` and restores stored speed; otherwise
`scalar_approach` approaches speed toward zero. Without that flag it also
approaches zero, with rate `0.1*q` unless byte `local_mode` selects zero rate.
Flag `0x40000000` sets the clock to its deadline. On expiry, byte `local_mode`
can select between helpers `projectile_retire_motion_a/projectile_retire_motion_b` using a bounded draw;
both clear motion and write state `6`, countdown `10` on the cited calls.
Clay Spd2's phase-0 slowing uses `0.2*q` before its proximity check; this
differs from Spd's ordinary `0.1*q` route.

## Guide construction and binding

`ProjectileGuide` stores channel descriptors, cursor, endpoint, and a position bias. `projectile_guide_construct` and `projectile_guide_reset` initialize that state. `projectile_guide_build_channels` selects at most three channels from mask bits `0..2`; Bird mask `0x27` produces flags `0x21/0x22/0x24`, routed by `projectile_guide_sample` to parameter, position, and angle outputs.

`projectile_guide_bind_borrowed` keeps authored key pointers. `projectile_guide_allocate_keys` and `projectile_guide_copy_keys` instead make writable copies, including all ten key words and a high-bit sentinel with nine zero words. Before rebinding or deletion, key arrays are freed only when the allocation flag is set. Descriptor arrays belong to the guide in both cases. A positive deleting argument to `projectile_guide_destroy` also frees the guide itself.

Channel stride chooses the next channel's start; it does not bound sentinel scanning or enforce destination capacity. Each channel must contain a non-sentinel key before its sentinel: the binder's endpoint calculation otherwise addresses the preceding key. The endpoint is the maximum final key time. The selected source blocks have these contracts:

| Authored block | Channel stride in keys | Non-sentinel counts: parameter / position / angles | Final times / endpoint |
| --- | ---: | --- | --- |
| `projectile_clay_bird_n_guide0` | 8 | `2 / 7 / 6` | `56 / 56 / 56`; 56 |
| `projectile_clay_bird_s_guide0` | 7 | `2 / 6 / 4` | `51 / 51 / 51`; 51 |
| `projectile_ink_bird_guide0` | 8 | `2 / 6 / 2` | `25 / 25 / 25`; 25 |

Their sentinels lie inside the selected strides. All six tail floats of the selected non-sentinel keys are zero; the selected linear flag `0x20` does not use them as tangents. This does not establish other interpolation modes or blocks.

Bird N activation (`projectile_clay_brd_n_activate`) allocates the guide, borrows its initial block with stride `8`, mirrors x through guide flag `2` on the directional branch, and sets bias from spawn. Its route changes borrow replacement blocks. Bird S (`rng_half_unit_object_initialize`) selects one of `projectile_clay_bird_s_guide0` through `projectile_clay_bird_s_guide4`, allocates and copies three channels with count/stride `7`, then edits the copied position keys. The guides are allocated in both classes, but their keys have different ownership.

Bird S's launcher (`projectile_launcher_clay_brd_s_update`) passes the shared parent record beginning at `value38` through `projectile_clay_brd_s_set_block`. The child retains that pointer for activation; the block is neither a parent-object pointer nor a separate child allocation. Parent retirement does not free the shared record storage. The supplied `ProjectileBirdBlock` exposes base/range cutoff adjustment, percentage multiplier, and speed-spread input corresponding to parent `value38/value3c/value40/value48`.

Initial copied-guide speed is first position-segment distance divided by its authored time difference, multiplied by `1 + signed_draw(speed_spread)`; the default spread is `0.1`. For selection below `3`, copied position keys can gain signed x/z draws ranged by `10/20`. Key z is clamped so spawn z plus the key remains at least `20`. Each later position-key time becomes prior time plus x/z segment distance divided by that selected speed; the final endpoint and other channels' last times are aligned to it. Production and retiming precede sampling.

Ink Bird (`projectile_ink_brd_n_activate`) initially borrows `projectile_ink_bird_guide0` with stride `8`. Routes `10/11`, `20..24`, and `30..33` replace it with allocated copies of the selected blocks at successive `0x3C0` displacements through `projectile_ink_bird_guide10`, using count/stride `8`; default routes keep the borrowed keys. Routes `40/41/42` enter stored-target phase `100` before allocating a guide, so that phase alone does not imply sampling.

`projectile_clay_brd_n_destroy` and `projectile_clay_brd_s_destroy` delete a non-null guide, clear it, and continue root destruction. `projectile_ink_brd_n_destroy` reaches `projectile_ink_brd_n_release`, which deletes the guide and separately releases its owned auxiliary reference. Guide and reference lifetimes are distinct. Unrestricted aliases and repeated setup outside these routes remain open.

## Ink motion and completion

| Class / motion body | Local timing inputs | Motion and completion |
| --- | --- | --- |
| `ccProjInkSnakeN`, `projectile_ink_snake_n_motion` | `dt = motion_multiplier*q`; `clock += dt`; bias countdown `bias_countdown -= dt` | Speed is `35` through clock `5`, then `13`. In phase `20`, clock `5..20` can adjust stored aim toward the selected fighter. Expired bias countdown regenerates vector `bias` and flips `flags` bit `1`. Query flag `0x40000000`, or clock `>= signed halfword deadline`, ends owned reference `owned_reference` with `projectile_ink_reference_end` and calls `projectile_retire_ink(self, 0, 0)`. |
| `ccProjInkBrdN`, `projectile_ink_brd_n_motion` | `dt = motion_multiplier*q`; `clock += dt` | Phase `100` steers toward stored target `target`; other guide-bearing routes sample owned guide `guide`. At clock `>= signed halfword deadline`, uses the same reference-end/state-6 pair. |
| `ccProjInkMouseN`, `projectile_ink_mouse_n_motion` | `dt = motion_multiplier*q`; `clock += dt` | Vertical scalar `scalar2 -= 8*dt`, clamped to `-20`. Builds x/z velocity from signed direction `horizontal_direction`, speed, and that scalar, then scales it by `dt`. At clock `>= signed halfword deadline`, calls `projectile_retire_ink(self, 0, 0)`. |

Snake helper `projectile_ink_snake_n_steer` decreases vertical scalar
`scalar2` by `4*dt`, clamps it at `-40`, and advances `anchor`
by normalized `spawn_vector2 - spawn_position` times `speed*dt`, with that vertical scalar
added to z. It steers current velocity toward `anchor + bias`
with angle limit `0.2*dt`, writes `direction`, and scales velocity by
`speed*dt`. Its query using mask `0x60000001` also uses flag
`0x20000000` to set anchor z to returned z plus `20`; the other flag ends
the object as shown above. These are two different query responses.

Ink Bird helper `projectile_ink_brd_n_steer` uses angle limit `0.15*dt`
and velocity magnitude `speed*dt` for phase `100`. Setup `projectile_ink_brd_n_activate`
initializes multiplier `motion_multiplier = 1`; its routes `40/41/42` select phase
`100`, speed `40`, deadline `30`, stored target, and a retarget window
`3..10` in floats `retarget_start/retarget_end`. Flag `flags` bit `1` admits
retargeting during that window; the selected fighter comes from halfword
`fighter_selector`, and predicate `projectile_ink_retarget_predicate` can clear the flag. The guide route
has the same sampled-parameter speed addition as Clay Bird N/S, scales its
turn by `dt`, and scales the final velocity by `motion_multiplier`. Helper
`projectile_ink_reference_set_step` stores `dt` into owned reference `step`; it is not a local
elapsed-time increment.

Mouse setup `projectile_ink_mouse_n_activate` reads signed record words `config.value38/config.value3c` for
its deadline, combining `config.value38` with the magnitude of a signed random draw
ranged by `config.value3c`, then converting to halfword `deadline`. Word
`config.value40 / 100` supplies `motion_multiplier`; float `config.initial_scalar` and a signed draw
ranged by float `config.value48` supply stored `stored_speed`. Query flag
`0x20000000` clears the vertical scalar and restores that speed; without
it, speed approaches zero with rate `0.1*q`. Flag `0x40000000` assigns
the deadline to the clock, causing the same-call expiry check to admit
completion. No other class's record field interpretation is implied.

Clay Bird N/S and Ink Snake/Bird additionally set their optional helper's
halfword `step` to the low half of `int(256*q)`. They do not add that
quantity to an existing helper counter at those stores. Their object clocks,
helper input, root accumulator, and position step therefore remain separate
observed quantities.

## Other flight phases

The following contracts cover the other distinct flight bodies reached from
the factory classes' common motion interface. `q` remains the instance `accumulator_step`.
Local phase values are identified by their actual storage, not equated with
common state `state`.

| Class / body | Verified movement, phase, and timing inputs |
| --- | --- |
| `ccProjectileTenten1`, `projectile_tenten1_motion` | Common `state_count == 0` initializes via `projectile_tenten1_initialize_motion`: quantized angle `30/150` according to opposite-tag direction, `launch_direction`, `vertical_accumulator = -20`, increment `scalar2 = 4`, phase `1`, word `phase_count = 0`. Phases `1/2` add `5` to speed, cap at `45`, and scale `launch_direction` into velocity. Every call adds `scalar2` to `vertical_accumulator`, writes it into auxiliary z `state_vector2[2]`, normalizes velocity-plus-auxiliary into `direction`, and increments `phase_count`. Phase `2` writes state `6` once the old word is at least `6`. These increments are unscaled. |
| `ccProjectileMakibishi`, `projectile_makibishi_motion` | First call uses the 42-vector draw scaled by `7.5`, clears its y, and sets velocity to unnormalized `aim - position + post_spawn_vector`; speed starts at zero and decrement `gravity_decrement = 6`. While private byte `phase == 0`, speed decreases by that amount, floors at `-5`, and the resulting z value is added to existing velocity each call. It normalizes velocity into `direction`. Common counter `active_count > 300` signals the handle and writes state `6`, countdown `10`. |
| `ccProjBoomerang`, `projectile_boomerang_motion` | Setup `projectile_boomerang_setup` numerically converts record word `config.value38` to speed, takes low halves of `config.value3c/config.value40` into `window_start/window_end`, and float `config.value48` into turn scalar `turn_scalar`. The motion body uses angle limit `turn_amount = turn_scalar*q`. Before `clock` reaches `30` it resolves the same-tag fighter with the observed height exception; thereafter it resolves the opposite-tag fighter. It adds bias `post_spawn_vector`, normalizes and angle-limits the direction, and scales by speed. Manager x-bound failure clears turn scalar. Clock increases by `q`; `> 120` writes state `6`, countdown `1`. |
| `ccProjSandPellet`, `projectile_sand_pellet_motion` | Private byte `phase` selects phases `0/1/2`. Phase `0` subtracts `speed*q` from distance `initial_distance`; a negative value stops speed and selects `1`, with halfword `countdown = bounded_draw(5)+1`. Phase `1` steers toward a fighter position or stored snapshot using angle `0.2`, then decrements the halfword by one; new value below zero selects `2`. Phase `2` adds `6*q` to speed, caps at `60`, and scales direction into velocity. Phases `0/2` subtract `speed*q` from remaining distance `remaining_distance`; negative distance clears collision, speed and velocity, writes state `6`, countdown `10`, and signals the handle. |
| `ccProjIronRain`, `projectile_iron_rain_motion` | Private byte `phase` selects four phases. Phase `0` post-decrements signed halfword `countdown`; old value `<= 0` sets phase `1`, zero speed, and a new bounded draw with argument `2`. Phase `1` increases `scale` by `0.15` per call, caps at `scale_limit`, and selects `2`. Phase `2` decrements the halfword; new negative value selects `3`, signals the handle, resolves direction, and measures collision distance along a `5000`-unit ray, using `5000` for sentinel `-1`. Phase `3` adds `24` to speed, capped at `240`, without a `q` factor. Phases `0/3` subtract `speed*q` from distance `remaining_distance`; only phase `0` directly calls completion helper `projectile_retire_iron_rain` when it becomes negative. Every phase writes velocity `speed*direction`. |
| `ccProjCHYSkillKunai`, `projectile_chiyo_kunai_motion` | Private halfword `local_phase` selects four routes. Phase `0` approaches a fighter-relative anchor, subtracting a speed clamped to `2..20` times `q` from distance `remaining_distance`. Completion selects phase `1` when byte `local_mode` is set, otherwise `2`, and initializes sinusoidal inputs. Phase `1` directly positions the object around the same-tag fighter with stored offsets and z oscillation; angular input increments without `q`. Fighter distance `<= 550` admits phase `2` and a bounded delay with argument `15`. Phase `2` decrements delay `launch_delay` by one, floors at `-1`, and at zero initializes normalized launch velocity with speed `65` and enables collision. Phase `3` applies an unscaled `3.5` gravity decrement and direct z positioning; query bits `2/3/4` enter common state `4` and use returned z plus `10`, while bit `1` calls `projectile_response_contact_complete`. |
| `ccProjExcORWSnake`, `projectile_orochimaru_snake_motion` | Private halfword `local_phase == 0` directly advances position using speed `horizontal_speed` and vertical scalar `vertical_speed`, then adds `vertical_increment` to the latter. Segment hit from `projectile_orochimaru_snake_query` places z at hit plus `2`, selects phase `1`, clears vertical scalar, and sets `flags` bit `0`. Phase `1` adds `horizontal_increment` to speed up to `horizontal_limit`, and adds `vertical_increment` to vertical scalar up to `vertical_limit` unless that flag suppresses it; its horizontal displacement uses `q`. Accumulator `accumulator >= 200`, or a hit through query mask `0x40000001`, selects phase `2` and calls `projectile_begin_retirement_countdown(self, 0)`. |
| `ccProjNWVGen`, `projectile_nwv_gen_motion` | Floors speed at zero and writes velocity `speed*direction`. Phase halfword `local_phase == 0` calls position-associated helper `projectile_position_service` while counter `phase_count < 15`; speed `<= 35` selects phase `1` through `projectile_nwv_gen_set_phase`, which resets the counter. Phase `1` writes scale `transition_scalar = lerp(counter/5, 1, 0)`; a nonpositive result writes state `6` and signals the handle. Counter increments by one per call. |

Makibishi contact `projectile_makibishi_contact` runs only while its private byte
is zero. Query bit `1` calls `projectile_response_contact_complete`; bits `2/3/4` clear speed,
decrement and velocity, place the candidate at the returned point plus `10`
in z, and set byte `phase = 1`. Bit `5` has the separate horizontal-stop
path. This explains why the continuing motion body stops accumulating gravity
after the first admitted contact, without assigning a collision shape.

SandPellet setup `projectile_sand_pellet_setup` snapshots the opposite-tag fighter into
`fighter_snapshot`, stores its direction scalar in `fighter_direction`, and initializes negative
distance `initial_distance` from Euclidean aim-to-position distance. The motion body
can choose the same-tag fighter instead while steering. The stored snapshot
and the later resolved fighter are separate inputs.

## Bound and character-carrier motion

`ccProjBakutiBall` motion `projectile_bakuti_ball_motion` snapshots current
position into `previous_position`. Its first-call setup enables collision, clears
`initialized/first_activation`, and initializes its private state and resources, then falls
through to `ProjectileBoundVtableView.integrate`, then `choose_emission`, on that same call.
Its signed halfword `count` increments by one after those callbacks.

The bound `integrate` callback, `projectile_bound_motion`, applies unscaled gravity
`velocity.z -= gravity`, floored at `-terminal_speed`, and passes the moving point
and velocity to contact helper `projectile_query_motion_flags`. Its flag responses are exact:

- `0x20000000`: z velocity below `-10` becomes `-vz * bounce_factor`, otherwise
  zero; x velocity is multiplied by `horizontal_damping`. Additional small-speed and
  height comparisons can settle horizontal motion.
- `0x40000000`: x velocity becomes `-vx * bounce_factor`.
- `0x80000000`: a positive z velocity is negated.

It stores the returned flags in `contact_flags` and calls the bound `rotate` callback.
That target, `projectile_bound_rotate`, updates angle `orientation[1]` from
the x difference against snapshot `previous_position` and scalar `rotation_scalar`, then wraps
around pi. These contact responses precede the emission decision.

The bound `choose_emission` callback, `projectile_bakuti_ball_choose_emission`, admits its six-way
choice at `accumulator >= 60`, contact flag `0x20000000`, and
predicate `projectile_context_predicate == 0`. It copies six bytes from resident
`projectile_bakuti_weights`, draws inclusively from `0..100`, and chooses the first byte
whose unsigned cumulative sum is **at least** the draw. Retail bytes are
`18, 18, 10, 18, 18, 18`; the exact inclusive comparison is retained rather
than interpreting these as six exact percentage probabilities. The complete
jump table is `projectile_bakuti_emission_table`, with these outcomes:

| Index | Called helper | Bounded emitted result |
| ---: | --- | --- |
| 0 | `projectile_bakuti_emit_fuda(self, 4)` | One config `0x29` and four config `0x28`, with the helper's alternating x offsets and delays. |
| 1 | `projectile_bakuti_emit_1e(self, 2)` | One config `0x1E` plus two further config `0x1E`. |
| 2 | `projectile_bakuti_emit_services(self)` | Resident allocations/services; no call to projectile spawn in the complete helper. |
| 3 | `projectile_bakuti_emit_fuda(self, 0)` | One config `0x29`. |
| 4 | `projectile_bakuti_emit_1e(self, 0)` | One config `0x1E`. |
| 5 | `projectile_bakuti_emit_28(self, 2)` | Three config `0x28`, with delays `0/2/4`. |

After an admitted choice it writes common state `6`, countdown `0`.
The same callback also has an independent accumulator `> 180` completion
and an earlier flag-tuple route to `projectile_response_contact_complete`. The weighted decision is
therefore not its only completion route.

The five factory classes using character-carrier motion
`projectile_carrier_motion` are `ccProjTest`, `ccProjCharNRW`,
`ccProjCharNRWOtherSelf`, `ccProjCharSZWBuddyTonTon`, and
`ccProjSZWExcItemTonton`. First activation clears `first_activation/initialized`, enables
collision, signals the handle, and selects word `direction = 2/3` according
to the spawn/aim x comparison. With collision byte enabled it calls extended
`ProjectileCarrierVtableView.update_command` before `integrate`, then resolves the embedded handle through
`projectile_carrier_update_registration`. This differs from BakutiBall's callback order.

The shared carrier `integrate` callback, `projectile_carrier_integrate`, combines
horizontal scalar `horizontal_speed`, vertical scalar `vertical_speed`, `direction`,
and mode `horizontal_mode` into velocity, with `q` multipliers. It moves the object's
position through one or two stored contact contexts,
stores the union of flags in `contact_flags`, clears vertical scalar on flag
`0x20000000`, and ends its horizontal mode on `0x40000000/0x80000000`.
At the tail it subtracts `gravity_multiplier * gravity_scale * q * 3` from the vertical
scalar and resets `gravity_multiplier = 1`. The shared carrier `update_command` entry
`projectile_carrier_update_command` dispatches the class-specific `command_callback`, consumes
movement-parameter records through `projectile_carrier_apply_movement_row`, updates its local command
cursor through `projectile_carrier_update_cursor`, and increments word `command_clock` by
`int(256*q)`. Its selected producers, row formats, and admission gates are
established below; the concrete Tonton completion branches remain
in [hit and despawn evidence](projectiles.md#hit-and-despawn-evidence).

## Carrier command publication and retained references

The five carrier constructors publish borrowed resource and command tables and allocate `ProjectileChar.pointer_array` for resolved resource pointers. Each `ProjectileCarrierResource` contains a name and a second word retained when that resource is selected. `projectile_carrier_find_resource` calls `animation_find_by_name` using `resource290` and argument zero; that path returns an existing record's pointer without copying a descriptor or incrementing a reference count. A missing name takes the resident null-address-store path, so these publications require their named resources to exist.

| Carrier | Constructor | Resource table | Command table | Pointer-array entries |
| --- | --- | --- | --- | ---: |
| `ccProjTest` | `projectile_test_construct` | `projectile_test_resources` | `projectile_test_commands` | 8 |
| `ccProjCharNRW` | `projectile_naruto_carrier_construct` | `projectile_naruto_resources` | `projectile_naruto_commands` | 2 |
| `ccProjCharNRWOtherSelf` | `projectile_naruto_other_self_construct` | `projectile_naruto_other_resources` | `projectile_naruto_other_commands` | 4 |
| `ccProjCharSZWBuddyTonTon` | `projectile_tonton_buddy_construct` | `projectile_tonton_buddy_resources` | `projectile_tonton_buddy_commands` | 1 |
| `ccProjSZWExcItemTonton` | `projectile_tonton_item_construct` | `projectile_tonton_item_resources` | `projectile_tonton_item_commands` | 1 |

These counts bound construction and allocation; they do not limit command rows. Resource IDs index both the resolved-pointer array and resource table directly. Cleanup frees the array, while this path leaves the borrowed tables and individual descriptor pointers intact. The wider source-container and animation-player lifetimes remain outside the selected carrier routes.

`projectile_carrier_update_registration` uses `projectile_find_registration` and `query_list_registration_at` to find a node whose sphere pointer matches the embedded carrier member. Only a found node permits copying position into that member. `projectile_char_cleanup_tail` searches the same pair, calls `query_registration_deactivate`, then `query_list_remove_registration`, and signals the embedded handle. Removal repairs the registration links, decrements the owner-list count, and calls `query_registration_destroy(node, 1)`. This binding is independent of row resource IDs; its producer under every carrier route remains open.

`projectile_carrier_publish_command` is rejected while carrier flag `1` is set. Otherwise it clears flag `8`, stores callback command and table index, resets the fixed-point clock to `-256`, retains the selected header, and resets row index to zero. It neither copies the rows nor checks the table index. Test and both Tonton activations publish `(0,0)`. Test command zero can publish `(1,1)` after contact flag `0x20000000`; its command-one callback selects full rows through flag `8`. NRW and both Tonton command-zero callbacks also select full rows on their admitted routes.

`projectile_carrier_get_movement_row` and `projectile_carrier_get_command_row` use the header's borrowed row base. Flag `8` selects `ProjectileCarrierMovementRow` with stride `0x4C`; otherwise the movement reader returns null and the command reader uses the eight-byte prefix. Neither reader bounds row index or checks a null row base.

| Prefix field | Shared use |
| --- | --- |
| `resource_id` | Signed resolved-pointer/resource-table index; `-1` suppresses new resource selection. |
| `advance_control` | Zero prevents endpoint advancement, nonzero permits one row increment; `-16` additionally holds movement flag `1` until that endpoint. It is not decremented as a duration. |
| `start` | Authored resource start written on selection and subtracted in the movement-event threshold. |
| `step` | Multiplied by `q`, converted, and stored as the helper's step halfword. |

Test command zero (`projectile_test_command0_rows`) begins `(0,0,0,256)`, then `(-1,0,0,0)`. Command one's full rows (`projectile_test_command1_rows`) begin `(1,-16,0,256)`, flags `0x0202`, and disabled event `0x7FFF`. These selected examples establish both formats without enumerating all authored commands.

`ProjectileCarrierCommandView` names the established command, table index, clock, selected header, retained resource word, row index, borrowed tables, speeds, and gravity multiplier. The command and movement contracts here use those named roles.

## Carrier movement-event gates and cursor order

`projectile_carrier_update_command` calls the class callback with the current command, obtains the full movement row, applies it through `projectile_carrier_apply_movement_row`, updates resource/command state through `projectile_carrier_update_cursor`, then adds `int(256*q)` to the fixed-point clock. The class callback can change tables, format, or common state before the shared work. The shared routine does not recheck state or collision admission afterwards.

`projectile_carrier_movement_event_crossed` requires a selected header, full-row flag `8`, and event other than `0x7FFF`. Its threshold, for every enabled event, is:

```text
threshold = max(0, row.event + helper.animation.frame_count - 1 - row.prefix.start)
```

Row flag `2` chooses the resource cursor; otherwise it uses the carrier clock. For a nonzero threshold `t`, `projectile_carrier_clock_crossed` and `projectile_carrier_resource_crossed` use:

```text
carrier: C - int(256*q) < (t << 8) <= C
resource: A - (u16(helper.step) - 1) < (t << 8) <= A
          A = (helper.frame_index << 8) | u16(helper.fraction)
```

At threshold zero, the carrier helper still evaluates its numeric inequalities; the resource helper instead returns transient resource-change flag `2`, without evaluating the resource inequality. The resource helper rejects a null animation helper, while the carrier-clock helper does not access it. The threshold producer and cursor updater dereference helper storage without that null guard. The resource route's stored step, fraction, and subtraction of one remain material.

On crossing admission, the row's high-byte flag group selects speed publication: `0x0100` replaces horizontal and vertical, `0x0200` adds both, `0x0400` adds horizontal/replaces vertical, and `0x0800` replaces horizontal/adds vertical. Other groups preserve both speeds. All branches publish the pair and set carrier flag `4`.

Independently of crossing admission, a non-null full row with gravity other than `1` replaces the carrier gravity multiplier. Integration consumes and resets that multiplier to `1`. While flag `4` is set, row damping supplies horizontal approach-to-zero rate `damping*q`; integration clears flag `4` only on its admitted low-speed comparison with contact flag `0x20000000`, and the low-speed branch zeroes horizontal speed. These stores bound the event's lifetime beyond initial speed publication. The analogous fighter-row gates belong to [Combat action execution](../combat/combat_action_execution.md#authored-motion-events-and-phase-payload) and [Movement and physics](../stages/movement_and_physics.md).

`projectile_carrier_update_cursor` clears transient flag `2` before deciding about resources. Endpoint is descriptor frame count minus `2` when descriptor flag `2` is set, otherwise minus `1`. With carrier flag `4`, it sets flag `1` and skips row advancement, resource replacement, and step publication.

On the continuing ungated path it compares `u32(helper.cursor) >> 8`, separately from the crossing cursor above. When the current ID matches the row, that cursor has reached endpoint, and advance-control is nonzero, it increments row index once and reads the next row. It does not catch up multiple rows on one call.

For a different resource ID other than `-1`, it sets transient flag `2`, calls `animation_attach(helper, pointer, 0)`, writes the authored start, stores the ID, and retains that resource entry's second word. It then publishes the scaled step. This links borrowed publication, retained references, event crossing, and resource selection without treating any of them as a fighter-owner pointer.

Unrestricted table aliases, all class-local command/index choices, remaining full-row payload consumers, and external source-container teardown remain open. Resource-loop execution belongs to [Animation runtime](../../runtime/animation_runtime.md).

## Emitter callbacks and their local schedules

These bodies occupy the same motion interface but perform scheduled child
emission or phase management. That interface placement alone does not imply
that the body continuously integrates the parent's position.

| Class / body | Trigger and verified emitted/state result |
| --- | --- |
| `ccProjectileKagebunshinLauncher`, `projectile_kagebunshin_launcher_motion` | Initializes normalized launch velocity. At common counter `active_count == 1`, renormalizes it and scales to `10`. Three equality thresholds at `projectile_kagebunshin_counters` are exactly `2/6/10`; each calls `projectile_kagebunshin_emit_fan` with record child `config.constructor_value`, the selected angle input, and explicit speed/offset inputs. Counter `13` writes state `6`. The equality scan is bounded to three entries. |
| `ccProjFloatLauncher`, `projectile_float_launcher_motion` | Private byte `phase == 0` waits for `accumulator > startup_deadline`; helper `projectile_float_launcher_set_phase(self, 1)` clears `state_count/accumulator`. Phase `1` writes x velocity `horizontal_speed*direction`, increments `horizontal_speed` by `speed_increment` and caps toward `speed_limit`, writes z velocity `1.5*sin(angle)`, and adds float bits `0x3D00ADFD` to its angle without `q`. At `accumulator > emission_deadline` it selects phase `2`. Predicate `projectile_context_predicate == 0` admits phase-2 emission of signed record byte `config.constructor_count` children using `config.constructor_value`, plus five children when byte `local_mode` is set. The child value `config_scalar` is parent `config_scalar` divided by the original record count, including on the extra-five path. Phase `2` writes state `6`, countdown `1` even when the predicate suppresses emission. |
| `ccProjKunaiBomb`, `projectile_kunai_bomb_motion` | Setup `projectile_kunai_bomb_setup` sets x velocity `-5/+5` from aim direction, z velocity `-1`, gravity scalar `gravity = 3`, and enables collision. Private phase halfword `phase == 0` subtracts gravity from z velocity per call, floors at `-100`, and normalizes velocity. Phase `1` adds `q` to `clock`; clock `> 30` with predicate zero emits record `config.constructor_count` children of `config.constructor_value`, applies bounded child delay with argument `10`, and distributes parent `config_scalar` over that count. The completion route writes state `6`, countdown `1`. |
| `ccProjLunFan`, `projectile_lun_fan_motion` | Emits signed halfword count `count` in one invocation. Uses normalized aim-minus-spawn, fan angle from `-0.5*spread_or_speed` with increment `spread_or_speed/(count-1)`; count `1` selects the unrotated direction. Child config is word `child_config`; every child gets bounded delay with signed halfword range `delay_bound`, parent `config_scalar/count`, and speed `cursor*speed_multiplier + signed_draw(speed_spread*spread_multiplier)`. Writes state `6`, countdown `0` after the loop. |
| `ccProjLunLinear`, `projectile_lun_linear_motion` | Same count/config/delay/speed/value inputs and same-call completion as Fan. Uses parallel normalized direction, with positions distributed from `spawn - 0.5*width` along a step `width/count`; count `1` uses spawn itself. Width is `spread_or_speed`. |
| `ccProjTripleChase`, `projectile_triple_chase_motion` | Emits signed record count `config.constructor_count` using `config.constructor_value`. Child float `launch_delay = float(config.value38) + 3*index`; child `turn_scalar/steering_deadline` receive numerically converted record words `config.value3c/config.value40`, and byte `stored_launch_target = 0`. Direction geometry can use fighter byte `contact_flags` bit `7`. Writes parent state `6` after the bounded loop. |
| `ccProjLauncherTewAnki`, `projectile_anki_launcher_motion` | Private phase `local_phase == 0` changes to `1` only when common counter `active_count` equals signed `context_threshold`; it does not execute phase `1` on that same call. Phase `1` calls `projectile_begin_retirement`, emission helper `projectile_anki_launcher_emit`, and sets private phase `2`. |
| `ccProjTewSkillAnki`, `projectile_anki_motion` | Calls Parabola motion first. With signed `context_threshold != 0` and `accumulator >= that threshold`, calls `projectile_anki_query_motion`, whose full loop emits 15 config `0x77` children, three aimed through the fighter-service route and twelve using random spatial inputs. It signals the parent handle; neither this call site nor the helper clears the threshold, so this body alone does not establish a one-shot trigger. Angular `orientation[1]` also uses `orientation_scalar*q` and wrapping. |
| `ccProjSNWCmbULauncher`, `projectile_snw_cmb_u_launcher_motion` | At `s16(int(accumulator)) >= emission_threshold`, config other than `0x97` emits config `0x0F`, copies `steering_enabled`, `retire_threshold`, and the 16-byte Homing control block through their exact setters. Then calls `projectile_response_selector2`, also for config `0x97` and failed child spawn. |
| `ccProjDDRExcItemLauncher`, `projectile_ddr_item_launcher_motion` | Uses record count/config `config.constructor_count/config.constructor_value`, bounded speed/amplitude inputs, and child delay `2*index`. The scalar setters publish deadline, amplitude, angle rate, and angle; `projectile_ddr_bullet_copy_vector40` separately copies a 16-byte block whose broader meaning remains open. Writes parent state `6` only on the body path with a resolved same-tag fighter; the null-fighter route skips that write. |
| `ccProjDDRBuddyLauncher`, `projectile_ddr_buddy_launcher_motion` | Uses record count/config `config.constructor_count/config.constructor_value`, indexed vectors at `projectile_ddr_buddy_directions`, direction-dependent rotation, and child `config_scalar = parent.config_scalar/count`. Writes parent state `6`. |
| `ccProjTEWExcItemKagura`, `projectile_tew_kagura_motion` | Clears first-call byte, signals handle, disables collision, and emits record count/config `config.constructor_count/config.constructor_value` with interpolated angles; odd child indices get delay `5`. Writes parent state `6`. |
| `ccProjSIWExcItemRakushiki`, `projectile_siw_rakushiki_motion` | Same first-call/handle/collision setup and record count/config interface; its loop assigns child parameters through `projectile_siw_child_set_parameters / projectile_siw_child_set_value298 / projectile_siw_child_set_value2ac / projectile_siw_child_set_value2a8` using random inputs. Writes parent state `6`. |
| `ccProjSCHExcItemSenbon`, `projectile_sch_senbon_motion` | Emits record count/config children with random xyz offsets. Fighter distance `<= 350` chooses the alternate base x displaced `350` from spawn according to direction. Child delay is integer `index/2`. Writes parent state `6`. |

Kagebunshin's three schedule arrays are `projectile_kagebunshin_angles` (angle inputs),
`projectile_kagebunshin_counters` (counter equalities), and `projectile_kagebunshin_wait_bases` (wait bases). The wait
range is converted from float `5` at `projectile_kagebunshin_wait_range` and supplied to the
inclusive bounded wrapper:

| Common counter | Angle input | Supplied wait input |
| ---: | ---: | --- |
| 2 | 10 | `8 + bounded_draw(5)`, range `8..13` |
| 6 | -10 | `4 + bounded_draw(5)`, range `4..9` |
| 10 | 0 | `bounded_draw(5)`, range `0..5` |

The helper `projectile_kagebunshin_emit_fan` receives fan words
`5, 20, 20, 40` from `projectile_kagebunshin_fan_parameters`: count, angle-spread input,
speed-draw bound, and base speed. Its complete loop makes five spawn attempts
per admitted equality, using the parent's record child `config.constructor_value`;
successful children get speed `40 + bounded_draw(20)`, range `40..60`.
For child records whose selector byte is `0x14` (`HomingDelay`), it copies
the supplied block from `projectile_kagebunshin_delay_control` through setter `projectile_homing_delay_set_argument`
and stores the converted wait input into child `post_spawn_count`. Thus the three
equalities supply 15 child attempts if all are visited; this body does not
catch up a missed equality or guarantee successful allocation.

KunaiBomb contact `projectile_kunai_bomb_contact` first calls root response.
Flag `contact_flags` bit `1` calls `projectile_response_contact_complete`; bit `2` selects private phase
`1`, clears velocity, and performs its effect/service work. Bit `5` additionally
sets byte `flags` bit `1`. A phase transition is therefore contact-driven,
while the later emission clock is step-scaled.

Lun's record-to-instance fields and retail child remap are established in
[post-spawn initialization](projectiles.md#complete-post-spawn-initialization-inventory).
In the motion bodies, speed sentinel `cursor == -1` is replaced from the
chosen child's record float `config.initial_scalar` before emission.

## Direct positioning, attachments, and auxiliary movement

| Class / body | Verified local movement contract |
| --- | --- |
| `ccProjSCOGen`, `projectile_sco_gen_motion`; `ccProjINWFlower`, `projectile_inw_flower_motion` | First-call launch normalizes `aim - current position`, copies direction to `direction`, scales it by speed into `state_vector`, clears `first_activation`, and enables collision. Later motion calls do not reconstruct the launch vector. |
| `ccProjDDRGen`, `projectile_ddr_gen_motion` | First call normalizes aim-minus-spawn and sets its oscillation/anchor inputs. Continuing calls directly derive position from `anchor` plus a z sine offset, increase `angle` by rate `angle_rate` without `q`, and wrap it. They write velocity from direction and `speed*q`, then advance the anchor by that vector. |
| `ccProjDDRExcItemBullet`, `projectile_ddr_item_bullet_motion` | Similar direct sine-offset position and anchor movement, with amplitude `amplitude`, `angle`, and unscaled rate `angle_rate`. Accumulator `accumulator > float deadline` calls transition helper `projectile_retire_ddr_bullet(self, 1)`. |
| `ccProjSCVGen`, `projectile_scv_gen_motion` | Calculates `position + direction*speed`; admitted `auxiliary` receives that point through `projectile_auxiliary_set_position`. This body does not directly commit object position or write a common state. |
| `ccProjSCVExcItemFire`, `projectile_scv_item_fire_motion` | Same auxiliary-point route with `direction*speed*4`. Common counter `active_count % 4 == 0` additionally runs its resident-service event chain. The event counter and spatial multiplier are different inputs. |
| `ccProjSSWGoukakyu`, `projectile_ssw_goukakyu_motion` | Calls Dist2Speed motion, then admitted `auxiliary` receives the current position. Its launch-time speed contract is inherited from the explicitly called body. |
| `ccProjYMTSkillYari`, `projectile_yamato_yari_motion` | Direct x displacement uses speed signed by `direction_scalar`; direct z displacement uses float `vertical_speed`. It normalizes new-minus-old position into `direction`, adds float `vertical_increment` to the vertical scalar without `q`, and services its handle when that scalar becomes negative. |
| `ccProjSCVSkillPupBullet`, `projectile_scv_pup_bullet_motion` | With byte `setup81 == 0`, subtracts the length of velocity from remaining distance `remaining_distance`. At nonpositive distance it zeroes velocity/speed, restores position from `saved_position`, runs auxiliary helper `projectile_scv_pup_bullet_emit` with word `child_parameter`, and calls `projectile_begin_retirement_countdown(self, 0)`. This counter uses vector length, without a local `q` multiplier. |
| `ccProjStickKibakuFuda`, `projectile_stick_kibakufuda_motion` | Float `countdown -= q`. On a continuing countdown, helper `projectile_stick_kibakufuda_follow` copies the same-tag fighter's position, adds its height-service result, and performs position work. Negative countdown either suppresses emission when predicate returns `1` or emits config `0x28` at the fighter position, copying parent `config_scalar` and setting child byte `child_marker`; both routes write state `6`, countdown `0`. Fighter `major_state == 6` with `substate == 0x61` supplies a separate completion store. |
| `ccProjectileNumbness`, `projectile_numbness_motion` | First call disables collision, clears velocity/speed, and creates two auxiliary references. Continuing calls position admitted references from fighter-resource/bone-service results. Integer `int(accumulator) >= 80` writes state `6`; it has no continuing launch-velocity integration of its own. |
| `ccProjDDRBuddy`, `projectile_ddr_buddy_motion_noop` | Motion is a literal no-op. The no-op motion entry says nothing about its separately documented manager-update behavior. |

Direct stores in these callbacks are local facts. A later shared candidate
commit or a derived commitment gate may affect the final object position;
the common call order is retained in
[position commitment](#continuing-state-2-motion-and-position-commitment).

## Stationary and resource-controlled phase timing

`ccProjFixedFire` `projectile_fixed_fire_motion` uses signed halfwords
`startup_countdown/active_countdown` as startup and active countdowns, each decremented by one
on its admitted route. Setup `projectile_fixed_fire_setup` copies record word `config.value38`
into the active countdown when its sentinel is `-1`, chooses startup as
`config.value3c + bounded_draw(config.value40-config.value3c)`, clears velocity, and
sets byte `setup81 = 0`. Startup completion activates its references; active
completion writes state `6`, countdown `1`, signals the handle and clears its
references. Their follow-position service calls do not introduce a projectile
flight integrator in this body.

`ccProjExplodeS/L`, `projectile_explode_s_active_motion` and
`projectile_explode_l_active_motion`, likewise have startup halfword `startup_countdown` and
optional active halfword `active_countdown`. Startup decrements by one and at new
value `<= 0` clamps to zero and activates the handle. Once startup is zero,
an active countdown other than `-1` decrements; reaching zero signals the
handle and changes that field to `-1`. Independently, reference predicate
`projectile_explode_reference_predicate(post_spawn_word) == 0` calls `projectile_set_state(self, 6)` and
`projectile_set_state_count(self, 1)` and signals the handle. Thus countdown zero is not
alone the direct state-completion test.

`ccProjDDRFire` `projectile_ddr_fire_motion` needs optional helper
`primary_service`. It sets that helper's `step = low16(int(256*q))`;
reference cursor `projectile_carrier_resource_cursor` returns `helper.cursor >> 8`, and endpoint
`projectile_carrier_resource_endpoint` returns `helper.animation.frame_count`. Once cursor is
at least endpoint minus one, it writes state `6`, countdown `1`, and signals
the handle. This is resource-cursor timing rather than its own float clock.

`ccProjSIWTrap` `projectile_siw_trap_motion` uses phase halfword
`local_phase` and unscaled counter `count`. Phase `0` runs helper
`projectile_siw_trap_periodic` when counter is divisible by `30`, snapshots the selected
fighter's state into `fighter_state`, and increments the counter by one. Old counter
`>= 250` selects phase `1`; a later phase-1 call enters `projectile_trap_terminate`,
which disables collision and signals the handle. Its separately documented
manager update supplies the removal decision.

`ccProjExplode3` `projectile_explode3_motion` waits for float
`accumulator > 8`, then signals the handle and calls the same exact
state/countdown setters with `6/1`. The root motion entry at
`projectile_motion_noop` is another literal no-op; classes inheriting it can still have
their own manager-update schedules in
[update contracts](projectiles.md#complete-factory-class-update-contracts).

## Representative callback composition

Projectile strategies replace different interfaces. The exact root and derived callback maps are retained on `projectile_vtable` and the seven representative vtable annotations.

| Selector / class | Composition relevant to behavior |
| --- | --- |
| `0x00` / `ccProjectileStraight` | Replaces launch motion while retaining the shared contact and commitment path. |
| `0x03` / `ccProjDist2Speed` | Combines distance-scaled launch motion with distinct action, post-spawn, and `response58` callbacks. Launch velocity and setup are separate calls. |
| `0x01` / `ccProjectileChase` | Combines steering/contact phases with derived orientation, transform, action, service, and activation callbacks. |
| `0x09` / `ccProjectileHoming` | Combines live-target steering with its action and activation callbacks. |
| `0x14` / `ccProjectileHomingDelay` | Combines delayed snapshot motion with action, service, and post-spawn callbacks. |
| `0x15` / `ccProjectileParabola` | Combines gravity motion with derived contact emission and post-spawn setup. |
| `0x0F` / `ccProjectileExplosion` | Replaces the manager update while retaining the root no-op motion. |

Shared invocation order is narrower than these class strategies: spawn invokes `post_spawn`; the manager invokes `update`; the collision pass invokes `service`; root active update invokes orientation and transform callbacks; common state `2` dispatches `contact_response`. Its continuing branch also reaches motion, admitted contact, and commitment in the [established order](#continuing-state-2-motion-and-position-commitment). The pose callbacks are named in `ProjectilePoseVtableView`; their interface does not imply direct position integration.

Root `projectile_update_orientation` selects orientation/transform helpers from record `activation_selector` values `0..7`; its default builds a separate matrix workspace from orientation. Chase's `projectile_chase_update_orientation`, in common states `2/5`, enables the optional service and updates the third orientation component from signed angular rate, `q`, and pi/32768 quantization. It leaves position intact. `projectile_chase_build_transform` consumes that angle and anchors the transform to current position. Common state `5` has a separate direct integration path adding `state_vector` to position on each invocation.

After its positive-delay and inactive gates, Explosion's `projectile_explosion_update` returns removal result `0` for state `7`; for state `6`, it writes `7` and returns continuation result `1`. Thus state `6` advances on that manager callback and is removed on a later admitted one, bypassing the common state-6 handler. At `active_count == 0`, its continuing path also invokes activation setup and `battle_emit_position_event(0x1000, position)`. The static callback contracts establish neither cadence nor a damage meaning.
