# Particle and emitter runtime

The particle and emitter runtime of retail NA2 (`SLPS-25837`): construction,
pool reuse, emission, movement, lifetime, force fields, drawing and destruction.

## Research coverage

Established: base/battle construction, circular pools, spawn/velocity selectors,
fades, all 34 force keys, history, visual publication and manager gates.
Open: repeat reachability, key-9 direct/nonzero-mode publication, complex velocity
axes, selector reachability and other callers. Names and per-routine detail are
in `@annotations/NA2`.

## Evidence and address conventions

Evidence is static resident ELF analysis with a bounded BTL repeat-store search;
computed or bulk writes remain outside that search. Counts do not establish a
universal wall-clock rate or an exhaustive particle-family inventory.

Related owners: [Effect-generator commands](../effect_generator_commands.md)
(authored packets and anchors), [CCS object types](../../game/files/ccs_object_types.md)
(resources), [Renderer and coordinate systems](renderer_coordinates.md#draw-environment-selection-and-streamed-exceptions)
(environments), [Render submission and buffers](render_submission.md)
(GS/VU submission), [Retail game file identities](../../game/files/file_identities.md),
and [Puppet control](../../gameplay/characters/puppet_control.md)
(Sasori's caller relationships).

Addresses here are live resident EE addresses in `SLPS_258.37`; see
[address conventions](../../game/files/file_identities.md#address-conventions).
Names describe demonstrated behavior, rather than recovered source names.
Unknown flag meanings stay numeric. R5900 vector/scalar decompiler omissions
were checked against instructions or bytes where consequential; missing leaf
entries were verified through their callers or dispatch/vtable pointers before
annotation.

Layouts are named in `ParticleEmitter`, `BattleParticleGenerator`,
`ParticleManager`, `ParticleElement`, `ParticleVisual`,
`ParticleForceField`, `ParticleForceDescriptor`,
`ParticleGeneratorParameters`, `ParticleResourceChoice`,
`ParticleOriginLink`, `ParticleHistorySnapshot` and the partial
`ParticleStandaloneOwner` prefix. Unresolved owner layouts keep their raw offsets.

## Construction and ownership

`generator_allocate` (`0x0034B720`) creates a 0x220-byte `ccGenerator2`,
initializes its two origin links through `particle_origin_links_initialize`,
then resets it through `particle_emitter_reset`. Its identity is
`generator_vtable` / `generator_type_descriptor` /
`generator_type_name`. Force objects use `particle_force_vtable`,
whose type descriptor names `ccForceField2`; the neighboring battle force
identity is `ccHigeParticleForceField`.

`generator_create_from_descriptor` packages four field descriptors for
`particle_manager_create_emitter`. Admission checks
`reserved_capacity < capacity_budget` before construction, then adds the
emitter's whole returned capacity. It does not clamp to the remaining budget.
`particle_manager_register_emitter` appends to the doubly linked emitter list,
assigns the next identifier and increments the manager count. An emitter with
an identifier other than -1 is returned without reinsertion.

### Emitter fields demonstrated by construction and update

The layout declarations own offsets and widths. These contracts matter across
routines:

| Field | Contract |
| --- | --- |
| `age` | Starts at zero and increments before emission. |
| `state` | 0 running; 1 returns false after particle processing; 2/3 return false when the pre-advancement live count reaches zero. |
| `fields`, `field_count` | Linked field ownership; each field has `next`, `previous` and a `slot`. |
| `particles`, `capacity`, `constructed_count`, `cursor` | Capacity-bounded pool, lazy visuals and circular replacement. |
| `live_count` | Active visuals whose unsquared visual/element alpha product exceeds the positive threshold. |
| `emission_enabled`, `emission_stopped` | Enabling clears stopped; emission requires enabled and not stopped. |
| `repeat_enabled` | Separate from emission enable; no positive producer is established. |
| `distance_enabled` | Enables reference-distance suppression and alpha processing. |
| `resources`, `resource_count` | Linked choices sampled on each spawn. |
| `identifier`, `previous`, `next` | Manager registration and linkage. |
| `scale`, `color`, `scale_product`, `color_product` | Emitter vectors multiplied componentwise by manager vectors. Color alpha is component 3. |
| `alpha_scale`, `random_alpha_bound` | Spawn copies the scale to the visual and can sample its alpha from the bound. |
| `distance_min`, `distance_max`, `alpha_inner`, `alpha_outer` | Suppression bounds and the alpha breakpoints below. |
| `custom_spawn` | Optional custom operator for geometry family 6. |
| `draw_environment` | Environment selected for the emitter's particle draw loop. |
| `history_capacity`, `history_distance`, `history_option` | Lazily allocated per-particle history configuration. |
| `parameters` | Copy of the 0x38-byte generator descriptor, or `particle_generator_defaults`. |

### Pool sizing and lazy visual resources

`generator_initialize_parameters` (`0x0034BBB0`) copies the parameters,
constructs each nonnull one of four supplied fields as a 0x90-byte object,
and replaces the old particle array. Explicit capacity bypasses estimation.
Capacity -1 estimates from particle lifetime, rate divided by 30.0,
lifetime variation and signed fade increments divided by 2048.0. The estimate
is clamped to at least one and rounded with `(estimate + 15) & 0xFFF0`.
Capacity above 2000 reaches a write to address zero in the inspected routine.

The allocation is `capacity * 0xA0 + 0x10`; `allocated_array_initialize`
sets up its header and callbacks `particle_element_initialize` /
`particle_element_destroy`. Each slot initially has no visual or history,
fade state `0xFF` and hold zero. The element initializer itself only installs
the vtable and returns; pool setup owns those initial state writes.
`particle_visual_initialize` initializes a new visual's active/suppression
bytes and ages to zero.

`particle_emitter_spawn` (`0x0034CF70`) uses the current circular slot,
selects a resource, and lazily creates a separate 0xA0-byte `ccParticle2`
(`particle_visual_vtable`, `particle_visual_type_descriptor`,
`particle_visual_type_name`). Its selector chooses the underlying family:

| Selector | Allocation and construction | Reuse |
| --- | --- | --- |
| 0 | 0x60 bytes; `ccs_effect_child_bind_descriptor` | Rebuild when resource pointer changes. |
| 1 | 0xA0 bytes; `projectile_simple_service_initialize`, `projectile_simple_service_configure` | Rebuild when resource pointer changes. |
| 2 | 0x120 bytes; `projectile_simple_service_initialize`, embedded `ccs_reader_construct`, `projectile_compound_initialize` / `animation_attach` | Rebind existing object or restart playback. |
| `0x12` | 0xB0 bytes; `projectile_simple_service_initialize`, `ccs_scene_child_bind_models` | Rebuild when resource pointer changes. |

A selector change destroys the old visual and history and initializes
fade/hold again. Same-selector reuse keeps the wrapper and performs
`particle_element_reset(element, 1)`: transforms, colors, angular/history
state and the one-draw skip reset, but fade state and hold do not.
Spawn replaces hold and activates the visual separately. Nonzero fade
parameters select state 1 or 3; with both zero, same-selector reuse retains
its old fade state instead of restoring `0xFF`.

Spawn increments/wraps `cursor` and caps `constructed_count` at `capacity`.
It replaces slots circularly rather than searching for a free particle.

`particle_emitter_append_resource` creates 0x28-byte choices, assigning
`index` from the resource count. The four producers are
`generator_register_effect` (0), `generator_register_composition` (1),
`generator_register_animation` (2), and `generator_register_scene_object`
(`0x12`). Each choice carries the resource, two auxiliary pairs, selector,
playback configuration, byte option and next link. Spawn takes the integer
absolute value of `prng_inclusive(resource_count - 1)` and walks that many
nodes. The RNG contract is owned by [Resident randomness](../randomness.md).

### Battle particle generator extension

`battle_generator_create` (`0x00349BA0`) allocates 0x280 bytes.
`battle_particle_generator_initialize` initializes the base before installing
`battle_particle_generator_vtable`, whose RTTI/name identify
`ccHigeParticleGenerator`. Parameter and pool setup is shared. Supplied
fields are 0x90-byte objects using `battle_particle_force_vtable`;
construction ends with emission disabled.

`battle_generator_resolve_visual_resource` constructs the extension's
0x14-byte resource descriptors. `battle_generator_register` enables and
registers the generator, filling that array from the shared catalog when
needed or publishing an existing array through
`battle_particle_generator_publish_resources`. Both routes feed the same
resource-choice nodes, so pool reuse, spawn, fades, integration and drawing
are shared.

`battle_particle_generator_pre_update` can refresh the primary position
from `primary_position`, clears `origin_updated`, and publishes the
requested environment to the base `draw_environment`. When the requested
environment is zero it substitutes the battle owner's environment at
`+0x2990`. `battle_particle_generator_post_update` refreshes four cached
field pointers. `battle_particle_manager_update` converts
`deferred_stop == 1` to stop state 2 and `== 2` to stop state 1, clears the
request, then runs the ordinary manager update.

`battle_particle_generator_destroy_fields` handles four externally held
field slots and indices before destroying remaining fields.
`battle_particle_generator_destroy` frees the extension resource array
before object deletion. Particular effects' resource choices and caller
semantics belong to their owners.

Environment binding has a class-dependent publication boundary:

| Class | Binding behavior |
| --- | --- |
| Base `ccGenerator2` | `particle_emitter_bind_environment` (`0x00352EE0`) immediately writes `draw_environment`. |
| Battle `ccHigeParticleGenerator` | `battle_particle_generator_bind_environment` (`0x002A8DE0`) writes `requested_environment`; pre-update later publishes it, substituting the owner default for zero. |

Both classes have empty `particle_emitter_pre_draw_hook` /
`particle_emitter_post_draw_hook`. A virtual binding alone therefore does
not establish immediate battle draw-loop publication.
`ccs_draw_generator_actions` obtains the current environment through
`draw_environment_get_current`, calls `particle_manager_bind_environment`,
then draws the manager.

## Stop and destruction

`particle_emitter_update` (`0x0034C610`) increments age, emits, counts live
visuals, processes fades and field updates, then checks emitter lifetime.
The signed lifetime expires strictly when `age > emitter_lifetime`;
-1 disables it. Expiry selects state 2, stops emission, disables repeat and
selects emitter fade state 3. States 2/3 retain the emitter until the counted
live visuals reach zero. That count precedes the call's particle advancement.

`particle_manager_request_state` finds the emitter by identifier.
Every nonzero requested state stops emission; state 2 also disables repeat
and selects fade state 3. `particle_manager_remove_emitter` unlinks and
destroys one emitter, subtracts its capacity from reserved capacity clamped
at zero, and decrements the emitter count.
`particle_manager_clear_emitters` performs that accounting/destruction for
the full list and clears its head/count.

`particle_emitter_destroy` clears resource choices through
`particle_emitter_clear_resources`, destroys fields through the virtual
cleanup (`particle_emitter_destroy_fields` in the base), destroys constructed
visuals, frees histories and the particle array, frees the optional custom
spawn operator, then invokes the emitter destructor.
`particle_visual_destroy_resource` selects underlying destruction by
0/1/2/`0x12`.

The base `particle_emitter_pre_update_hook` /
`particle_emitter_post_update_hook` are empty. They are separate from the
shared update and draw services.

## Emission, particle lifetime and update ordering

`particle_emitter_schedule` (`0x0034CE00`) requires a resource choice and
`emission_mode != 1`. A nonzero delay increments the counter and returns
while `counter <= delay`, then resets it. An eligible call adds
`emission_rate / 30.0` to the accumulator and spawns its truncated integer
part; a positive integer part is subtracted, preserving the remainder.
Low nibble 1 of `parameters.emission_geometry` instead emits the truncated
rate itself once and stops emission.

The 30.0 divisor appears in emission and capacity estimation. These are
call-count contracts; it does not establish that every manager runs at
30 calls per second.

### Fade and hold states

`particle_fade_update` (`0x0034FAF0`) visits all constructed elements.
Signed `parameters.fade_in` / `fade_out` are divided by 2048.0.

| Element state | One-call operation |
| --- | --- |
| 0 | Alpha zero, enter 1. |
| 1 | Add fade-in increment, clamp above 1, enter 2 at alpha >= 1. |
| 2 | Decrement hold; below zero enter 3 when fade-out is nonzero, otherwise 4. |
| 3 | Subtract fade-out increment, clamp below zero, enter 4 at alpha <= 0. |
| 4 | Enter 5 and clear visual active. |
| 5 | With repeat enabled, enter 0 and resample hold; the reactivation pointer has the limitation below. |
| `0xFF` | Clear visual active when hold is negative; do not decrement hold. |

Spawn and repeat sample
`L - integer_conversion(L * abs(rng_signed_scaled(variation)))`, with signed
particle lifetime `L`. `soft_double_abs` clears the double sign bit after
float conversion. For positive `L`, this is a reduction rather than a
symmetric variation.

Spawn chooses state 1/alpha 0 for nonzero fade-in, otherwise state 3/alpha 1
for nonzero fade-out. Both zero leave the fade state unchanged.
Emitter fade state 3 promotes only `0xFF` elements to 3; emitter fade state
0 promotes only `0xFF` to 1. Existing fade states are not all replaced.

### Retained repeat pointer and its incoming owner

The fade pass visits pool indices in ascending order and retains a pointer
within that invocation. States 0/1/2/3 do not replace it. State 4 and
negative-hold `0xFF` replace it with their visual before checking for null,
so a null visual also replaces it. State 5 with repeat enabled reactivates
through that retained pointer, without loading the current element's visual
or checking the retained pointer, while its hold write still targets the
current element. It is restored on return; the preceding invocation's last
visual is not retained. The fade loop has no active-visual admission gate.

On the recovered `particle_emitter_update` caller path, the initial pointer
is the manager scale vector. Before a disabling slot replaces it, an admitted
repeat write targets `manager + 0xA0`, beyond the recovered 0x70-byte manager.
After such a slot, it targets the most recently visited disabling slot's
visual, which can differ from the repeating element's visual. The owning
routine annotations carry the register and instruction evidence.

### Repeat producers and the reachability boundary

The established repeat-byte producers disable it:
`particle_emitter_reset`, finite expiry in `particle_emitter_update`
(after fade processing), and state request 2 in
`particle_manager_request_state`. Other nonzero state requests stop
emission without clearing repeat. The inspected base and battle construction
paths include reset and never enable repeat. Emission enable and battle
registration do not enable it; the parameter copy does not cover this byte.

**Bounded inference:** fresh emitters on those construction paths keep
repeat disabled until another writer changes it, so reaching state 5 does
not itself reach reactivation. Spawn precedes fade and can reset a slot;
an arbitrary pool ordering alone cannot prove wrong-visual reactivation or
an out-of-object write.

No positive producer, ordered pool population before respawn, or reachable
retail failure is established. The immediate-offset store search preserved
in the reset annotation does not exclude computed/bulk writes or other
subtype callers. `particle_fade_state_targets` corroborates the seven state
targets.

### Manager gates and call sequence

`particle_manager_update` (`0x0034FEA0`) returns without updating when
`update_enabled` is zero. An admitted emitter receives:

1. Virtual pre-update.
2. `particle_emitter_update`: age, emission, emitter vector products,
   distance processing/live count, fades, field-object updates and stop decision.
3. `particle_force_dispatch`: force handling over eligible particles.
4. `particle_emitter_compose_visuals`: transform/scale/color composition and
   visual advancement.
5. Virtual post-update.
6. Removal if step 2 returned false.

The manager's `anchor_changed` controls anchor refresh and is cleared after
any emitter was visited. The manager has no elapsed-time argument.

`particle_emitter_compose_visuals` multiplies element scale/color by emitter
products and calls `particle_element_compose_history`, then the active
visual's update. Composition through `particle_visual_compose` applies
accumulated translation/rotation and scale/color. History shifts existing
records from `used_count - 1` down through 1, publishes a new head snapshot,
then increments/clamps used count. During growth the newly counted tail
slot is not filled by that call's shift. A nonzero history-distance limit
caps older positions at `distance * history_index` from the head.
Partial element reset then clears accumulators.

Composition multiplies element color twice on this path:
`element_color * element_color * emitter_product`, componentwise.
Element alpha is squared before visual alpha scale is applied by
`particle_history_draw`. The earlier live census uses the unsquared
element/visual alpha product.

### Caller scheduling and suppression

`particle_manager_initialize` constructs a 0x70-byte `ccParticleManager`
with budget 2000, no emitters, update/draw enabled, zero position/reference
and unit scale/color. `battle_particle_manager_initialize` installs the
`ccHigeParticleManager` identity and builds the resource catalog consumed
by battle generators. Catalog authorship belongs to
[Asset dependency graphs](../../game/files/asset_dependencies.md).

Recovered scheduling boundaries:

- `engine_root_finish_update` (`0x00108490`) admits the default manager
  and detached-list update/draw only when the engine gate's low three bits are
  zero. All four operations share that gate. The resident default manager
  is `default_particle_manager`.
- `particle_manager_list_update` destroys detached managers with no emitters
  and otherwise updates them; `particle_manager_list_draw` is separate.
- `battle_auxiliary_first_pass` invokes battle manager update when that
  manager exists. `battle_auxiliary_second_pass` publishes its reference
  vector and invokes `particle_manager_draw`.
- `particle_standalone_owner_initialize` allocates the same battle manager
  in `ParticleStandaloneOwner.manager`; `particle_standalone_owner_update` and
  `particle_standalone_owner_draw` schedule it separately.
- `ccs_update_generator_actions` processes authored action runners first,
  then updates particles for each requested iteration only with a nonzero
  owner. A zero owner uses the separately stepped default manager.
- `ccs_draw_generator_actions` with a nonzero owner binds the environment
  before drawing that owner's particle manager.

The default-manager pass follows the cooperative task barrier
([Task system](../task_system.md#manager-pass-and-ordering-boundary)).
It establishes one invocation per eligible render-phase call.

Battle phase mask bit 7 admits the first/second wrappers and writes the
default manager's `update_enabled` / `draw_enabled` bytes at
`battle_effect_first_phase_enabled` / `battle_effect_second_phase_enabled`.
The mask, pause relationships and exceptions
are owned by [Pause and replay](../../gameplay/session/pause_and_replay.md#selective-update-gating).
Update and draw suppression are distinct; the emitter has no battle-pause
query. [Effect-generator scheduling](../effect_generator_commands.md#scheduling-and-owner-gates)
owns the recovered scene callers and their different iteration-count units.

### Distance suppression and alpha processing

With `distance_enabled`, emitter update measures distance `d` from each
visual to the manager reference. Below `distance_min` or above
`distance_max` suppresses the visual; inclusive bounds clear suppression.
Inside them, element alpha is multiplied by:

| Condition | Multiplier |
| --- | --- |
| `d < alpha_inner` | `(distance_min - d) / (alpha_inner - d)` |
| Otherwise, `d > alpha_outer` | `(distance_max - d) / (alpha_outer - d)` |
| Otherwise | 1 |

Reset values are minimum 50, maximum 5000, inner 400 and outer 4000.
The default near/far intervals can produce negative multipliers; this routine
does not clamp them. Live counting follows and compares visual alpha times
element alpha with the positive threshold encoded as `0x01800000`.
Suppression is checked later by `particle_element_draw`. Descriptor
producers belong to [Effect-generator commands](../effect_generator_commands.md).

## Drawing and history

`particle_manager_list_draw` (`0x003530A0`) admits only managers with
`draw_enabled`. Emitter pre/post draw hooks surround the constructed pool
loop. An emitter environment can temporarily replace the selected environment
pointer `active_draw_environment`; selection/restoration belongs to
[renderer coordinates](renderer_coordinates.md#particle-environment-overrides-and-nested-scene-cameras).

An element with `skip_draw_once` is skipped once and the byte clears.
Otherwise `particle_element_draw` (`0x0034B5A0`) requires a nonnull,
active, unsuppressed visual. Without history it draws once. With history it
draws snapshots oldest to newest, restoring position, rotation, base scale
and color, multiplying snapshot alpha by `1 - index / history_capacity`,
calling `particle_history_draw` to publish, and drawing each snapshot.
This outer wrapper does not advance emitter/visual age or velocity.

History restores `base_scale`, while resource publication reads
`composed_scale`. History drawing does not call `particle_visual_compose`
to recompute it, so restored base-scale records alone do not establish a
different submitted scale per snapshot.

Full element reset sets the one-draw skip. That byte also selects
`particle_zero_vector` instead of the emitter translation input during
composition.

### Concrete visual update and draw

`particle_visual_vtable` selects `particle_visual_update` /
`particle_visual_draw`; the overridden `particle_visual_frame_hook` is
empty. The base resource operations are `particle_visual_update_draw` and
`particle_visual_draw_resource`.

`particle_visual_update` increments both ages by one, adds velocity to
position, publishes through `particle_history_draw`, then calls the empty
derived frame hook. There is no elapsed-time factor.

`particle_visual_update_draw` handles selector-2 scene playback through
`animation_advance_position` / `animation_player_compose`.
Playback mode 0 skips; 1 advances until the final scene frame; 2 can rewind
and advance again near the end. Scene presence/time gates at `+0xFC`
also apply. Selector-0 sprites increment and clamp their frame to
`0..frame_count - 1` for any nonzero mode. Mode 2 first resets an already
out-of-range index to -1; an ordinary final-frame value does not itself reset.

`particle_history_draw` (`0x0034B070`) calls that playback routine before
publishing transforms, color and alpha. Every history snapshot therefore also
invokes resource playback under those gates, without incrementing outer
visual age or adding velocity. An admitted selector-2 scene step can reach
its own action/particle manager through `ccs_update_generator_actions`.
Selector 0 packs truncated RGB components times 128 into three bytes and
uses `visual.color[3] * visual.alpha_scale`; 1/2/`0x12` publish transforms
and that alpha through underlying setters.

`particle_visual_draw` checks active before forwarding.
`particle_visual_draw_resource` selects `projectile_compound_submit` (2),
`particle_sprite_submit` (0), `scene_object_submit_geometry` (`0x12`),
and `projectile_simple_service_submit` (1). Selector 0/`0x12`
`render_option` enables extra render-state setup first. These are consumer
families; [Render submission and buffers](render_submission.md) owns the
GS/VU primitives beneath them.

## Spawn geometry and velocity

Spawn dispatches the high nibble of `parameters.emission_geometry`; its low
nibble controls emission mode. `parameters.velocity_flags` bit 4 supplies
the extra manager-vector option and its low nibble selects velocity.
Attachment origin resolution belongs to
[Effect-generator commands](../effect_generator_commands.md).

| Geometry high nibble | Route |
| --- | --- |
| 0, 7 | `particle_spawn_angular`, zero radius, planar. |
| 1 | Angular, sampled radius, planar. |
| 2, 3, `0xB` | Angular, sampled radius, spatial. |
| 4 | `particle_spawn_between_origins`, zero radius. |
| 5, `0xC` | Between origins, sampled radius, origin addition. |
| 6 | Optional `custom_spawn` operator. |
| 8 | Angular, twice sampled radius, planar. |
| 9, `0xA` | Angular, twice sampled radius, spatial. |
| `0xD..0xF` | No geometric case in this switch. |

`particle_spawn_angular` rotates the resident unit vector, scales by radius
and adds the resolved primary origin. Planar uses one angle; spatial uses two.
It publishes position and element angular state. A uniform surface/volume
distribution is not established.

`particle_spawn_between_origins` uses primary and secondary origins.
Velocity selectors 3/10 place the point along their separation using
`cursor / capacity`, after that spawn has advanced/wrapped the cursor.
Other selectors use `abs(rng_signed_scaled(separation_length))` along the
normalized separation and can add a random planar radial offset.
This establishes the sampling operation, not a uniform continuous distribution.

`particle_spawn_velocity` uses angular bases/spreads converted with
`pi / 32768`, and sampled speed from `speed` / `speed_variation`.

| Velocity selector | Demonstrated family |
| --- | --- |
| 0, 5, `0xD..0xF` | Default angle-derived normalized direction transformed by emitter basis and sampled speed. |
| 1, 8 | Outward from primary origin, with basis handling and sampled-speed branch. |
| 2, 9 | Inward toward primary origin, normalized/scaled. |
| 3, 10 | No vector-producing branch here; used by the two-origin helper. The resulting vector is unresolved. |
| 4 | Random angles, then the selector-6 basis/direction path. |
| 6 | Angle/basis direction, normalization and speed scaling. |
| 7, `0xC` | Two angle matrices composed with emitter basis, then scaled unit vector. |
| `0xB` | Two random angles composed with emitter basis, then scaled unit vector. |

Exact axis conventions and distributions of complex branches remain
incomplete because of R5900 vector/scalar decompiler limitations.
The writes, branch set and per-call integration are established; authored
cone/sphere names are not recovered.

## Force-field consumer table

`particle_force_dispatch` (`0x003500F0`) walks enabled linked fields in
order and searches `particle_force_dispatch_table` (`0x005A6650`), all 34
key/function pairs. An element needs a nonnull active visual and fade state
other than 4. Field center is `manager_anchor + offset`; distance must be
strictly below the selected radius. Radius mode 1 uses the descriptor radius,
with zero replaced by float max; other modes use float max directly.

There is no exhausted-search check before reading the handler pointer.
Malformed-selector reachability in retail assets is not established.

| Key(s) | Annotated handler | Consumer behavior |
| --- | --- | --- |
| 0 | `particle_force_displacement` | Add displacement; flag bit 0 selects velocity-scaled form. |
| 1 | `particle_force_velocity` | Add field vector to velocity, or velocity-direction variant with element correction. |
| 2 | `particle_force_orbit_planar` | Orbit-like position correction using angular state, center and angular increment. |
| 3 | `particle_force_euler` | Increment/wrap visual Euler rotation for selector 1. |
| 4, `0x15` | `particle_force_distance_correction` | Add distance-weighted field vector to correction. |
| 5 | `particle_force_scale_aspect` | Age-based scalar scale/aspect adjustment. |
| 6 | `particle_force_scale_x_interpolate` | Age-based interpolation into X scale. |
| 7 | `particle_force_scale_y_interpolate` | Parallel Y interpolation. |
| 8 | `particle_force_scale_replace` | Replace/multiply scale using field vector and visual scale/aspect. |
| 9 | `particle_force_scale_cycle` | Zero-mode alternating linear scale; nonzero-mode contract below. |
| `0xA`, `0x1B` | `particle_force_angle_add` | Add signed `descriptor.angle * pi / 32768` to element rotation component 1, wrapping near +/-pi. |
| `0xB`, `0x1C` | `particle_force_angle_set` | Set that angle from the signed halfword. |
| `0xC`, `0x1D` | `particle_force_rotation_initialize` | At visual age zero copy descriptor values to element rotation. |
| `0xD`, `0x1E` | `particle_force_position_correction` | Add position-derived displacement, scaled by signed angular conversion. |
| `0xE` | `particle_force_alpha_envelope` | Age-driven multiphase alpha, optional modulo period. |
| `0xF`, `0x20` | `particle_force_rotate_offset` | Rotate center-relative offset by signed angle and add the difference to displacement. |
| `0x10` | `particle_force_radius_constraint` | Constrain position inside/outside emitter-origin radius by field scalar. |
| `0x11` | `particle_force_displacement_add` | Add descriptor values directly to displacement. |
| `0x12` | `particle_force_correction_add` | Add descriptor values directly to correction. |
| `0x13` | `particle_force_orbit_spatial` | Three-dimensional orbit from stored offset/angles; rotate velocity too. |
| `0x14` | `particle_force_rotation_add` | Add descriptor values directly to rotation. |
| `0x16` | `particle_force_scale_xyz_step` | Apply X/Y handlers plus corresponding Z increment. |
| `0x17` | `particle_force_scale_x_step` | Initialize/move X scale toward terminal value using visual age. |
| `0x18` | `particle_force_scale_y_step` | Parallel Y operation. |
| `0x19` | `particle_force_scale_copy` | Copy descriptor values to scale. |
| `0x1A` | `particle_force_scale_oscillate` | Alternate scale steps between thresholds; `scale_direction` stores direction. |
| `0x1F` | `particle_force_alpha_periodic` | Four-duration periodic alpha phases. |
| `0x21` | `particle_force_radial_displacement` | Within radius, radial displacement weighted by `1 - distance / radius`. |

`direct_selection` chooses descriptor values when zero and direct values
when nonzero. Several handlers use visual `age`; angular increments use
`pi / 32768` and scale/alpha changes occur once per dispatch.
No inspected handler takes delta time. Exact authored flag meanings belong
to the resource/command owners.

`particle_emitter_update_fields` refreshes the manager anchor when changed
and invokes enabled fields' update hook. `particle_force_update_hook` is
empty for the base/battle fields. That hook is separate from particle force
dispatch.

### Force key 9 and the incoming scalar

`particle_force_scale_cycle` (`0x00351960`) converts the selected mode
float to an integer. Zero mode computes triangular scale from visual age
and half the converted period. Nonzero mode skips local scalar computation.

On the recovered dispatcher path, the nonzero-mode scalar is
`field.center[0] - visual.position[0]`, recomputed for each admitted particle.
The handler scales `particle_unit_scale_vector` (`0x005C8D10`,
`(1,1,1,0)`) and explicitly writes W 1, giving
`(delta_x, delta_x, delta_x, 1)` in element scale. Direct and descriptor
selection share this continuation. It is independent of a previous field
handler's scalar.

Admission still requires enabled field, active visual, fade other than 4 and
strict radius inclusion. It does not require a nonzero X delta or constrain
its sign. Other indirect routes and a concrete admitted retail use of
nonzero mode remain unestablished.

### Selected key-9 field publication and authored values

Base setup and battle construction initialize `direct_selection` and direct
values to zero, copy the supplied 0x20-byte descriptor, then enable the field.
`ParticleForceDescriptor.key` selects dispatch; its four `values` are
start/end/period/mode for key 9. These are copied authored values, not
necessarily recomputed each update; both field update hooks are empty.

Direct selection instead uses `direct_values`, initially all zero.
Neither descriptor copying nor emission enable sets the selection byte.
A direct vector writer alone would not establish selection; the key-9 direct
writer/selection producer remains unresolved.

Selected resident descriptors (decimals describe binary32 values):

| Annotated descriptor (live address) | Key | Start / end / period / mode | Half-period |
| --- | --- | --- | --- |
| `particle_scale_cycle_descriptor_004f0b80` (`0x004F0B80`) | 9 | 1.5 / 3.0 / 20.0 / 0.0 | 10 |
| `particle_scale_cycle_descriptor_004f0be0` (`0x004F0BE0`) | 9 | 1.0 / 3.0 / 10.0 / 0.0 | 5 |
| `particle_scale_cycle_descriptor_00580030` (`0x00580030`) | 9 | 1.4 / 1.48 / 8.0 / 0.0 | 4 |
| `particle_scale_cycle_descriptor_005800d0` (`0x005800D0`) | 9 | 1.5 / 1.8 / 8.0 / 0.0 | 4 |
| `particle_scale_cycle_descriptor_005a7ad0` (`0x005A7AD0`) | 9 | 0.5 / 1.0 / 15.0 / 0.0 | 7 |
| `particle_scale_cycle_descriptor_005a7b30` (`0x005A7B30`) | 9 | 0.5 / 1.0 / 10.0 / 0.0 | 5 |
| `particle_scale_cycle_descriptor_005a7b50` (`0x005A7B50`) | 9 | 0.8 / 1.7 / 50.0 / 0.0 | 25 |
| `particle_scale_cycle_descriptor_005a7bd0` (`0x005A7BD0`) | 9 | 1.0 / 2.0 / 30.0 / 0.0 | 15 |
| `particle_scale_cycle_descriptor_005a7e10` (`0x005A7E10`) | 9 | 0.01 / 1.0 / 16.0 / 0.0 | 8 |
| `particle_scale_cycle_descriptor_005d5650` (`0x005D5650`) | 9 | 0.5 / 1.5 / 20.0 / 0.0 | 10 |

All ten mode words are exactly zero and do not admit the nonzero branch.
For nonnegative age and positive half-period `H`, let
`q = age / H`, `r = age % H`; odd `q` replaces `r` with `H - r`.
Uniform XYZ scale is `start + r * (end - start) / H`, W 1.
Half-period uses signed integer division by two after float conversion.
Thus period 15.0 produces a 14-call arithmetic cycle. The routine has no
local zero-divisor guard; calls are not assigned seconds.

`particle_generator_preset` (`0x00353790`) selects a 0x38-byte row of
`particle_generator_presets` using a signed-byte index. Four signed field
indices map nonnegative values into 0x20-byte rows of
`particle_force_presets`; negative indices supply null.

| Preset data | Field indices | Selected key-9 descriptor |
| --- | --- | --- |
| `particle_generator_preset_3` (`0x005A7528`) | 11, 12, -1, -1 | Field 12: `particle_scale_cycle_descriptor_005a7ad0` |
| `particle_generator_preset_6` (`0x005A75D0`) | 16, 27, -1, -1 | Field 16: `particle_scale_cycle_descriptor_005a7b50` |
| `particle_generator_preset_11` (`0x005A76E8`) | 16, -1, -1, -1 | Field 16: the same descriptor |

`particle_preset_pair_owner_initialize` (`0x0031B2D0`) establishes that
publication mechanism but selects preset 1 in the inspected construction
path, not presets 3/6/11. Their concrete caller/gate selection remains open.
Arithmetic and these sources are established; authored mode names, a selected
nonzero-mode descriptor, all indirect callers and live admission are not.
Broader descriptor distributions and interpretation belong to the resource
and effect-command owners.
