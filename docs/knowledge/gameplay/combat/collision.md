# Collision and hit-query infrastructure

## Research coverage

Static NA2 analysis establishes sphere registration and overlap, result
snapshotting, candidate filtering, interaction-record lifecycles, the common
response-packet handoff, resident environment queries, and stage query contracts.
Routine, type, field, and data names come from `@annotations/NA2`.
Original enum names, some record fields, indirect aliases and ownership edges,
interfaces outside the audited set, and complete event admission remain open.

## Result

Collision-facing BTL behavior follows this ordering:

```text
CollisionSphere registrations
    -> resident query_process_active_pairs
    -> CollisionResult chains
    -> CollisionSnapshot buckets
    -> per-object candidate masks
    -> manager aggregation and relationship filters
    -> ResponsePacket producers
    -> common packet handoff
```

The resident registration processor enumerates active pairs, filters directional
masks, and immediately checks sphere overlap. No separate spatial broad phase
is established for that processor. The manager's compact sphere caches also
support proximity queries, but no inspected edge makes them its broad phase.

Environment collision is a separate system with packed object/group/triangle
bounds and segment or swept-sphere narrow phases. BTL triangle-cache updates
feed that environment system. The `ccBg*` stage cluster separately queries
line envelopes and boundaries; no direct edge connects its query structures
to the interaction manager or the BTL triangle-cache owner.

This document ends at the common response-packet handoff. Related owners are
[Hit response](hit_response.md), [Damage](damage.md),
[Substitution](../characters/substitution.md),
[Projectiles](../projectiles_and_items/projectiles.md),
[Battle items and status effects](../projectiles_and_items/battle_items_and_status_effects.md),
[Target selection](target_selection.md#collision-candidates-and-routing-order),
[Movement and physics](../stages/movement_and_physics.md#floor-side-surfaces-and-limits),
[Stage surface attributes](../stages/stage_surface_attributes.md),
[Stages](../stages/stages.md#line-construction), and
[Battle entities](../session/battle_entities.md).

## Inputs and address conventions

The inspected programs are NA2 `BTL.BIN` and resident `SLPS_258.37`.
[Retail game file identities](../../game/files/file_identities.md#address-conventions)
owns their identities and live address conventions;
[Overlay ABI](../../runtime/overlay_abi.md) owns BTL loading. Annotation names
are analysis names unless a literal RTTI or resource string establishes the
retail spelling.

The resident BSS globals below are annotated in `SLPS_258.37`; their roles are
established by the consuming routines:

| Resident annotations | Established state |
| --- | --- |
| `active_sphere_count`, `active_sphere_head`, `active_sphere_tail` | Simple active-sphere count, head, tail |
| `sphere_compatible_counterpart_mask` | Simple resolver's OR of compatible counterpart masks |
| `query_active_list_count`, `query_active_list_head`, `query_active_list_tail`, `query_list_generation` | Active-list count, head, tail, list-generation source |
| `query_active_registration_count`, `query_active_registration_head`, `query_active_registration_tail` | Active-registration count, head, tail |
| `environment_object_count`, `environment_object_head`, `environment_object_tail` | Environment-object count, head, tail |
| `environment_candidate_count` | Accepted environment-candidate count |
| `environment_candidates`, `environment_candidate_overflow_slot` | 32 candidate slots; the second name aliases slot 31, also reused for overflow |
| `environment_published_candidate`, `environment_published_primitive_flags` | Published environment candidate; alias of its `primitive_flags` |
| `battle_timeout_marker` | Timeout marker read by `battle_timeout_marker_get` |

## Interaction manager and object registries

### Manager lifetime

`interaction_manager_allocate` creates a `0x3330`-byte
`InteractionManager` through `heap_allocate`, initializes it, and publishes
the manager globally. Initialization installs its interface and clears both
pending slots. Release invokes virtual destruction, clears the published
pointer, and brackets the operation with a resident busy bit.

The three manager phase wrappers each invoke three subordinate updates when
a manager exists. Their original phase names remain unknown.
`interaction_manager_destruct` frees nonnull record-bank entries for both
sides and all 197 resource indices. `interaction_registry_clear` destroys the
two primaries and all 64 auxiliaries, clears their entries, and resets the four
sphere-cache counts.

### Registry layout

`InteractionManager.primary` has two entries;
`InteractionManager.auxiliary` has 32 entries per side. Each
`InteractionRegistryEntry` carries an object and generation. Objects and
optional outputs retain an `InteractionTuple` of slot, generation, and self.
Auxiliary handoff validates its retained `primary_registry` tuple against the
corresponding primary manager entry before resolving the backing primary.

Primary registration directly indexes the side's slot. An occupied slot takes
an assertion/fault path. Successful registration publishes the manager pointer
and tuple, taking its generation from `primary_registration_generation`.
Auxiliary registration takes generations from
`auxiliary_registration_generation`, selecting its side from the object.
The two insertion routines scan descending or ascending slot order. A full
auxiliary registry returns without a status value and leaves the object and
optional output tuple untouched.

Both counters skip `-1` before issuing a generation and increment after
successful insertion. Vacated entries have null object pointers and generation
`-1`. Full cleanup invokes primary cleanup slots `0x18C` and `0x228`, and
auxiliary destruction slot `0x08`. Selective cleanup removes objects with bit
1 set in their `status_flags`; `interaction_manager_remove_update` performs
that cleanup in the first manager phase.

## Resident query-list boundary

Three independent lifecycles coexist: simple active spheres, active query
lists and registrations, and active environment objects. Registering a sphere
with a list does not itself activate either the simple-sphere chain or the
query list. Representative primary and auxiliary setup routines deliberately
finish by deactivating the list. The auxiliary rebuild path removes
registration 2 and then reactivates its list.

`CollisionSphere` is `0x50` bytes. Its effective center is `center` with
`z_bias` added to component 2. Sphere overlap accepts
`radiusA + radiusB - distance >= 0`, using Euclidean center distance.
The separate simple resolver clears `correction`, checks
`receive_mask & other.send_mask`, and adds a full penetration correction with
an additional `0.1`. Its compatible-counterpart summary is OR-accumulated.

The sphere initializer sets receive and environment masks to `0xFFFFFFFF`,
environment match mode to 1, radius to `1.0`, and center/correction to the zero
vector. It writes through the correction vector; the final `0x10` bytes are
not generally initialized by it. A representative primary setup uses radius
`30.0`, zero z-bias, and these directional values:

| Receive mask | Send mask |
| --- | --- |
| `0x00088900` | `0x00000080` |
| `0x00044090` | `0x00000800` |

With a nonzero `environment_mask`, `sphere_resolve_active` clears
`environment_flags`, applies swept-sphere environment corrections, and reduces
the accepted primitive flags. A zero mask skips that branch and leaves the
previous `environment_flags` value. Its return is bit 0 for sphere overlap
and bit 1 for environment correction, giving values 0 through 3.

### Manager sphere snapshot caches

`InteractionManager.sphere_banks` contains two `SphereSnapshotBank`s per side,
each with 64 `0x20`-byte entries and a count. Generic snapshotting follows
1-based list registrations, stores their effective centers and radii, and
stops at count 64. It ignores inactive lists unless `include_inactive` is set;
a specialized primary path intentionally sets that argument.

`interaction_reset_sphere_caches_update` zeros all four counts before invoking
primary and auxiliary callbacks. The frame consumer later snapshots primary
list 0 into bank 0 and auxiliary list 0 into the bank selected by
`skill_auxiliary_sphere_bank`: nonnull `alternate_entity` chooses bank 1.
That selector's live entry is `0x0077FD10`.

Specialized appenders can write directly. The unit-sphere appender stores
`cache_center` with radius `1.0`; KSM appenders also use inline writes. These
writers have no visible count-64 check. Therefore 64 is the physical capacity
and generic-builder limit; a capacity invariant covering every writer remains
unproved.

The two proximity consumers use these caches. One shifts cached x or z by
`0.9 * radius` according to a four-way selector and accepts when
`distance < 1.8 * cached_radius + query_radius`. Direct count references identify
these two consumers, builders, appenders, reset, and cleanup. Indirect accesses
remain possible, and no inspected call joins these queries to the central
candidate dispatcher or resident pair processor.

### Resident list and registration layouts

`CollisionQueryList` is `0x24` bytes, `CollisionRegistration` is `0x34`, and
`CollisionResult` is `0x40`. The list owns a doubly linked registration chain,
a separate result chain, accumulated `result_mask`, result and registration
counts, an optional gameplay `owner`, and a nonzero `generation`.

List activation appends an inactive head to the global active-list chain and
activates its eligible registrations. List deactivation unlinks the head,
deactivates its registration chain, and clears its result summary/count.
Registration activation has a separate global chain; bulk activation admits
only registrations whose `activation_eligible` equals 1. The pair processor
walks that registration chain.

`projectile_handle_associate` appends a registration around a sphere. Its
third argument becomes `send_mask` and fourth becomes `receive_mask`. When
no sphere is supplied it allocates and initializes one, recording
`owns_sphere`. Removal first deactivates an active registration, repairs the
owner chain, releases its owned state, and decrements the list's count.
Registration and registration-result accessors use 1-based indexing.

The auxiliary initializer creates four lists with their `owner` set to self
and establishes `class_id = 5`. The primary constructor creates five lists
without installing self in their owner fields. This establishes the observed
null-owner versus auxiliary-owner convention in these constructors; it does
not give null ownership a universal gameplay meaning. A separate fighter
construction family creates three adjacent lists fed by two-sphere arrays.

### Resident pair processor

`battle_dispatch_phases` calls `query_process_active_pairs`. The latter clears
prior results, enumerates globally active registrations belonging to different
owner lists, rejects inactive spheres, and requires at least one directional
intersection:

```text
(A.receive_mask & B.send_mask) != 0
or (A.send_mask & B.receive_mask) != 0
```

It then directly checks sphere overlap. One enabled direction receives the
full correction and one result; two directions receive opposing half
corrections and a result each. A zero-distance overlap chooses a signed
separation axis. Emission accumulates sphere correction and updates the
registration's result count and OR mask.

When the receiving registration has an owner list,
`query_registration_append_result` first emits the list-level copy and then
allocates the registration-local copy. These are distinct allocations with
the same observed payload. Fighter consumption belongs to
[Target selection](target_selection.md#collision-candidates-and-routing-order).

### Resident segment/environment broad and narrow phases

`CollisionEnvironment` has its own active chain, hierarchy, transform mode,
origin, transform matrices, and enabled-group mask. Registration stores the
transform mode and appends an inactive object; removal clears active/next
state. The halfword at `+0x96`, reset during unregister, has no established
meaning.

The hierarchy is packed rather than pointer-linked. An
`EnvironmentBoundsHeader` gives aggregate AABB bounds and group count. Each
group repeats that `0x20`-byte header followed by its consecutive `0xA0`-byte
`TrianglePrimitive`s. The next group follows its last primitive.

`collision_segment_query` clears the candidate count and prepares each
registered environment. Preparation subtracts its origin, optionally applies
world-to-local transformation, computes the segment AABB, and carries both
query-mask predicates forward. Narrow-phase admission proceeds through:

1. aggregate AABB overlap;
2. enabled-group bit and group AABB overlap;
3. primitive AABB overlap;
4. both caller-selected primitive-flag predicates;
5. directed plane crossing and three edge half-space tests, tolerance `-0.001`.

Accepted `EnvironmentCandidate`s carry a world point and normalized surface
direction, travel distance, environment pointer, group/primitive indices,
primitive flags, and local normal. The local-to-world matrix supplies output
transformation. The collision world-to-local operation consumes three rows
and supplies a fixed homogeneous row.

Swept-sphere queries use the same hierarchy and masks but test triangle
planes, edges, and vertices. Their candidate `branch_class` values are 1, 2,
and 3, and feature selectors range from 0 through 3; original names remain
unknown. Accepted corrections accumulate surface-normal displacement.
`environment_reduce_candidate_flags` ORs bits outside `0x00F0F0F0` and selects
the masked group by its distance/class rule, including precedence for
`0x80000` and masked value `0x00E000E0`.

Both narrow phases retain 32 physical candidate slots. Once the count reaches
32, further accepted hits overwrite slot 31 while the total count continues
increasing. For more than 32 hits, selection therefore sees the first 31 hits
and the last overflow hit. The original slot 31 and intermediate overflow
hits can be lost. `environment_candidate_overflow_slot` aliases
`environment_candidates[31]`, not a separate scratch slot.

`environment_publish_nearest` clamps its scan to 32 and replaces the winner
on distance `<=` the current best. Equal distances choose the last retained
candidate in index order. The segment wrapper publishes that candidate,
overwrites its second endpoint with the hit point, and returns travel distance.
With no hit it returns `-1.0`, leaving both the second endpoint and published
record unchanged.

Publication is partial. Segment candidates do not initialize `branch_class`
or `feature_selector`; neither inspected narrow phase writes `+0x2C` or
`+0x4C`, although publication copies them. The `+0x34..+0x3C` bytes are
unwritten and skipped by publication. Consumers cannot assume the full
`0x60`-byte public record is fresh. Its `primitive_flags` side channel is the
chosen triangle's flags. Authored meanings belong to
[Stage surface attributes](../stages/stage_surface_attributes.md#authored-word-and-geometric-class).

## Query-result and snapshot records

A result carries receiving and counterpart masks, counterpart radius,
center distance, effective counterpart center, counterpart list/generation,
and a next pointer. `separation` is
`max(distance - counterpart_radius - receiver_radius, 0)`, normally zero for
results emitted by the overlap pass.

`collision_snapshot_copy` copies the observed result fields and caches the
validated counterpart list plus its current generation. Both resident handle
resolution and `collision_snapshot_owner` require that generation to match;
a null or stale handle resolves to null. The snapshot check protects against
reuse of the referenced resident list.

Classifiers choose buckets by the exact counterpart mask:

| Counterpart mask | Bucket | Qualifying-owner distinction |
| --- | --- | --- |
| `0x80000`, `0x40000` | 3 or 6 | Qualifying owner chooses 6 |
| `0x8000`, `0x4000` | 1 | No distinction |
| `0x800`, `0x80` | 0 or 4 | Qualifying owner chooses 4 |
| `0x200`, `0x20` | 7 | No distinction |
| Other values | None | Ignored |

The auxiliary classifier qualifies any resolved owner. The primary classifier
requires a resolved owner's class word to equal 5. Each accepted result
overwrites its bucket, retaining the last accepted result per bucket.

## Candidate-mask production

### Primary objects

`collision_build_primary_candidates` refreshes four snapshot families and
writes `CollisionSkillPrimary.candidates`. In this table, a slash joins
alternative source bits in a list's `result_mask`:

| Query list | Snapshot family | Source bits to candidate bits |
| --- | --- | --- |
| `query_lists[4]` | `snapshots[2]` | `0x20/0x200 -> 0x80000000`; `0x80/0x800 -> 0x40000000` |
| `query_lists[1]` | `snapshots[1]` | `0x20/0x200 -> 0x08000000`; `0x80/0x800 -> 0x1`; `0x40/0x400 -> 0x20000000` |
| `query_lists[0]` | `snapshots[0]` | `0x40000/0x80000 -> 0x20000`; `0x80/0x800 -> 0x40` for a generation-checked class-5 bucket-4 owner, or `0x8` for nonempty bucket 0; `0x10/0x100 -> 0x10`; `0x4000/0x8000 -> 0x20` |
| `query_lists[3]` | `snapshots[3]` | `0x40000/0x80000 -> 0x80000`; `0x80/0x800 -> 0x100000` |

These are exact reductions, without recovered gameplay names for the bits.

### Auxiliary objects

`collision_build_auxiliary_candidates` refreshes three families and writes
`CollisionSkillAuxiliary.candidates`:

| Query list | Snapshot family | Source bits to candidate bits |
| --- | --- | --- |
| `query_lists[2]` | `snapshots[1]` | `0x80/0x800 -> 0x10000` for class-5 owner, or `0x8000` for nonempty bucket 0 |
| `query_lists[0]` | `snapshots[0]` | `0x40000/0x80000 -> 0x40000`; `0x10/0x100 -> 0x80`; `0x80/0x800 -> 0x800` for class-5 owner, or `0x400` for nonempty bucket 0; `0x4000/0x8000 -> 0x100` |
| `query_lists[3]` | `snapshots[2]` | `0x80/0x800 -> 0x100000`; `0x40000/0x80000 -> 0x80000` |

The first two listed families suppress resolved owners on the same side.
The result is a BTL relationship summary rather than a copy of resident masks.

### Manager aggregation and frame caller

`interaction_aggregate_candidates` requires its battle-state gate and clear
bit 0 in manager `flags`. It rebuilds each primary mask and copies it to
`primary_candidates`, then ORs all auxiliary masks by side into
`auxiliary_candidates`. Rejection zeros the primary masks and clears auxiliary
side/object masks for occupied entries.

The frame order is aggregation, pending-result processing, then
`interaction_consume_candidates`. That consumer clears object result flags,
calls the central dispatcher with ordinary handoff enabled, consumes or clears
candidate masks according to the result, and rebuilds the sphere caches.
Later gameplay handling is outside this document. The central dispatcher reads
individual auxiliary masks rather than the auxiliary aggregates.

## Active interaction records

### Definition-to-runtime copy

`interaction_record_from_definition` constructs a `0x68`-byte
`InteractionRecord` from a `0x44`-byte `InteractionDefinition`, first applying
`interaction_record_init` to its `0x54`-byte prefix. The annotation holds the
copy map and initializer defaults. Eight halfword slots at runtime
`+0x40..+0x4F` initially contain `0xFFFF`, then receive the definition's
16-byte copy; their semantics are unknown. This does not establish a vec4 or
shape record there.

Builders separately set `attack_scalar`. The auxiliary builder multiplies
definition `attack_scalar` by the object's scalar returned by
`skill_auxiliary_scalar`. The primary builder multiplies it by the linked
entity's `current_record.damage`. Its entity path requires
`entity_link_valid` and `downed_override_allowed`. That resident predicate
checks only a nonnull argument and its global gate. A failed gate leaves a
null pointer before the scalar load; this path supplies no neutral multiplier
fallback. Downstream scalar interpretation belongs to [Hit response](hit_response.md).

### Selected runtime-field consumers

`skill_auxiliary_update_descriptor` reloads its record through the descriptor.
Signed `update_form` selects two confirmed forms; other values skip their
construction branches and reach the common descriptor-end check:

| Update form | Category selection |
| --- | --- |
| 0 | Incremented `update_count == saved_repeat_count` selects `saved_category`; otherwise selects `alternate_category` |
| 1 | Reads signed linked-entity `guard_state` only when context `+0x48` is zero; nonzero selects alternate category; zero restores saved category, clears preparation, sets `repeat_count = 1`, and sets pause/rejection to `0x7FFF` |

Both category halfwords are truncated to the record's `response_selector`
byte. Each selected branch invokes
auxiliary callback `0x4C`, reloads the descriptor record, writes its scalar,
submits the prefix, then invokes callback `0x50`. The base callbacks are the
annotated no-op leaves; derived callback effects remain open. A callback can
therefore change which record receives the later write and submission.

Terminal cleanup clears header/descriptor state, including saved category and
scalar, but does not clear or free the record allocation. Earlier gates can
return before increment or category rewrite. Equivalent behavior for every
primary/derived updater and full writers of the selectors remain unresolved.

The primary updater has two receiver-interface calls at slot `+0x8C`.
A bounded exact-load census also found three BTL uses through other
auxiliary tables and none in resident code. That instruction search does not
establish a complete set of indirect calls.

### Computed construction and prefix publication

KSM constructs selected records without the definition-copy path:

| Selector | Data destination | Selected values |
| --- | --- | --- |
| `0x93` | `skill_ksm_prefix_records[side]` | Prefix category 1, flags `0xC000`, scalar from auxiliary, response selector `0x10`, repeat 1; computed record state 4 |
| `0x93` | `skill_ksm_extended_93[side]` | Flags `0xC000`, scalar from auxiliary, response selector `0x10`, repeat/pause/rejection 1 |
| `0x31` | `skill_synthetic_31[side]` | Flags `0xC000`, scalar from auxiliary, knockback scale 0, response selector 2, repeat 5, pause/rejection 1 |
| `0x3B` | `skill_ksm_extended_3b[side]` | Flags `0xC000`, scalar from auxiliary, response selector `0x10`, repeat/pause/rejection 1 |

The extended constructors clear `alternate_category`, the low halfword of
`extended_58`, `extended_5c`, and both relation masks; selectors `0x93` and
`0x31` also clear halfword `+0x48`. Their inspected writes leave `update_form`
and the high halfword of `extended_58` untouched.
`cc_skill_ksm_object_interface` identifies `ccSkillKSM000` and routes its
six-way update dispatch to this producer when `computed_update_state == 0`.
That table identity does not establish instance-level admission of every case.

Prefix publication requires computed update state 3, publication-context
`+0x6C > 1`, an admitted resource selector, and nonzero list-0 result count.
It initializes `skill_prefix_publication_records[side]`, clears extended
fields, copies exactly `0x54` bytes from the prefix, and prepares the first
header with the secondary header as context. It snapshots category, scalar,
and repeat count, forces repeat 1, and sets `prepared`.

This copy and the initializer leave `update_form` untouched. Overlay BSS
clearing establishes initial storage contents, but this publication does not
establish a fresh selector for a reused record. Overlay lifetime belongs to
[Overlay ABI](../../runtime/overlay_abi.md). Preparation also does not establish
that separate activation gates accept the descriptor.

The primary computed producer's selector `0x31` uses the same
`skill_synthetic_31[side]` storage, but sets repeat 1 and supplies its own
resource, mask, and scalar. This proves aliasing; ordering, simultaneous use,
complete consumers, cleanup, and further pointer aliases remain unresolved.
The record's response selector is distinct from the object's packet tag.

### Active descriptor headers

Primary and auxiliary objects each carry two `InteractionHeader` banks.
Builders select definition/runtime entries, prepare `context` and `record`,
save repeat/category/scalar, reset accumulators, and force record repeat 1.
The explicit auxiliary producer additionally sets `explicit_definition` and
candidate bit `0x80`. The default producer builds response selector `0x12`,
submits it, and invokes auxiliary callback `0x44`.

The submission bridge mutates record category/flags, derives the object's
submission pause, copies only the first `0x54` bytes to
`interaction_prefix_scratch`, and calls `interaction_submit_prefix`.
Alternate category and update form are outside that copy, while the selected
response byte is inside it.

Activation wrappers require `prepared`; their installers set `self`, copy
`context` to `active_context` and `record` to `active_record`, and set flag
bit 0. They accept either supplied bank. Primary table slot `0x88` and
auxiliary slot `0x48` route to these wrappers. The auxiliary two-bank branch
requires update-flags bit 1 and clear update-control bit 0; its alternate
update-flags bit-0 branch invokes another callback.

All 166 primary and 53 auxiliary interfaces in the audited resident interval
retain these activation targets. Selected immediate primary preparation paths
use the same contract. Ordinary pair filters read the first bank, independently
of second-bank activation. Removal clears active pointers, preparation,
accumulators, saved descriptor values, and flag bits 0/1 (also bit 2 for the
primary); it restores saved repeat 1 and
category halfwords `0xFFFF`. Conditions selecting the removal timing remain
outside this document.

## Central relationship and compatibility filters

`interaction_dispatch_pairs` short-circuits in this order:

1. primary 0 versus primary 1;
2. primary 0 versus the opposite 32-entry auxiliary registry;
3. primary 1 versus the other auxiliary registry;
4. the two auxiliary registries, 32 by 32.

First acceptance returns 1; exhaustion returns 0. The dispatcher's second
argument becomes each filter's fourth argument and suppresses ordinary handoff
when nonzero. Special cross-mask classes dispatch before that check, so the
argument does not make the call free of side effects. The frame consumer
passes zero.

Every filter rejects while `battle_timeout_marker_get` returns 1. That helper
reads only the timeout marker. Expiry sets it and battle initialization clears
it; ownership and other consumers belong to
[Match outcomes](../session/match_outcomes.md#terminal-detector-and-classifier),
[Pause and replay](../session/pause_and_replay.md#start-menu-admission-timeout-marker-check),
and [Battle entities](../session/battle_entities.md#coordinator-timeout-marker-check).
An active record requires nonnull first-bank `active_record` and flag bit 0.

### Primary versus primary

The candidate gate requires both manager masks to intersect `0x001A0000`, or
both to contain `0x08`. The relationship gate requires either the union of
record `relation_mask`s to contain `0x04`, or linked entities' signed
`movement_facing` values to differ. Ordinary compatibility then requires:

```text
(A.relation_mask & B.relation_mask & 0x80000000) != 0
and ((A.relation_mask & B.counterpart_mask) != 0
     or (B.relation_mask & A.counterpart_mask) != 0)
and (A.relation_mask & B.relation_mask & 0x04) == 0
```

With neither setting bit `0x04`, identities must differ. Exactly one setting it
admits equal identities through the relationship gate; both setting it reject
ordinary compatibility. Candidate, high-bit, and cross-mask gates still apply.
Successful ordinary handoff clears both primary manager masks.

### Primary versus auxiliary

The filter walks exactly 32 opposite-side entries and requires a
snapshot-owner backlink to equal the current auxiliary:

| Primary bit | Auxiliary bit | Primary snapshot |
| --- | --- | --- |
| `0x40` | `0x400` | `snapshots[0][4]` |
| `0x100000` | `0x40000` | `snapshots[3][4]` |
| `0x20000` | `0x100000` | `snapshots[3][6]` |
| Shared `0x80000` | Shared `0x80000` | `snapshots[3][6]` |

Let `x = primary.relation_mask & auxiliary.counterpart_mask` and
`y = auxiliary.relation_mask & primary.counterpart_mask`. Special classes are:

| Class | Intersection |
| --- | --- |
| 1 | `((x | y) & 0x300) == 0x300` |
| 2 | `(x & y & 0x100) == 0x100` |
| 3 | `(x & y & 0x200) == 0x200` |

They invoke the special response before ordinary suppression, deriving a
midpoint-like vector from the primary built record and input position. A
geometric contact-point interpretation is unproved. The ordinary branch uses
the high-bit and cross-mask compatibility expression above, including mutual
`0x04` rejection, and consumes relevant primary/auxiliary masks on success.

### Auxiliary versus auxiliary

The fixed 32-by-32 traversal requires reciprocal generation-checked backlinks:

| Relationship | Auxiliary snapshots |
| --- | --- |
| Shared `0x800` | Both `snapshots[0][4]` |
| `0x100000` versus `0x40000` | `snapshots[2][4]` versus `snapshots[0][6]`, in either direction |
| Shared `0x80000` | Both `snapshots[2][6]` |

Special classes use the same intersections and dispatch before ordinary
exclusion, deriving a midpoint-like vector from auxiliary positions. Ordinary
acceptance uses the same compatibility family but does not explicitly clear
either auxiliary mask. Reciprocal relations do not establish universal
attacker/target roles.

## Response-packet handoff boundary

The wrappers involving auxiliaries validate retained primary tuples and resolve
their backing primaries. All three ordinary wrappers require clear low two
bits in the primary status flags, publish selected active-record categories,
invoke preparation callbacks, build two `ResponsePacket`s, order participants
by side, and invoke `interaction_handoff_packets`. Auxiliary participants then
receive their post-handoff callback at slot `0x40`.

`skill_publish_active_category` chooses the auxiliary active record when an
auxiliary argument is present, otherwise the primary active record. It clears
and fills primary `published_category`. This preparation precedes packets;
`skill_primary_deactivate_queries` is the separate later callback.

The primary/primary wrapper can swap resource positions before packet
production when both records share relation bit `0x01`, using signed resource
orientation. This is an established position side effect, without a recovered
universal gameplay direction.

`ResponsePacket` is `0x30` bytes: a byte tag, anchor vec4, and position vec4.
The handoff first replaces packet positions from the ordered primaries' current
positions. Tag exactly 1 snapshots that position into the manager; other tags
put `10000.0` in the temporary's final component. It then reconciles packets,
writes tag-1 positions back to linked entities, and invokes both primary
callbacks at slot `0x1F4`. The combiner consumes only tag and the two vectors;
bytes `+0x01..+0x0F` remain producer-private or padding.

### Packet producers and tag source

The common producers prepare their participant, invoke the anchor callback,
read the tag getter, and copy its low byte to the packet. The primary getter
returns `CollisionSkillPrimary.packet_tag`; the auxiliary getter returns
`CollisionSkillAuxiliary.packet_tag`. They do not normalize nonzero values.
All 166 primary and 53 auxiliary audited interfaces retain these builders and
getters; preparation and anchor targets vary.

The backing-entity gate controls initial resident preparation only. Later
preparation, anchor, and tag callbacks still run when it fails. The auxiliary
path also continues through descriptor callbacks. Failure of that predicate
therefore does not by itself clear or prevent a packet tag.

Direct writers establish primary base initialization to 1, JRB's clearing leaf
to 0, FIR construction to 0, and auxiliary base/Rock construction to 0. No
nonzero auxiliary writer was found in the direct byte audit. Complete writer
sets and the tag's original semantic name remain open.

### Tag lifetime and non-byte access bounds

The bounded audit of 486,832 aligned BTL text words found no wider or partial
store overlapping either tag and no immediate formation of its exact byte
address. Arbitrarily
rebased aliases and generic copies remain unresolved. Auxiliary `attack_scalar`
and `update_control`, and the primary neighboring counter, have distinct
widths and do not overlap the tags.

JRB event update reaches its clearing leaf through slot `0x22C`. Rock
construction requires primary selector `0x0E`, allocates `0xDB0` bytes, calls
base auxiliary initialization, installs `cc_skill_jrb_rock_interface`, and
clears its tag before binding. Binding copies the primary tuple, side and
entity pointers, prepares both headers, supplies the scalar, and can build
definition 0. The Rock after-bind callback is a no-op. Its ascending registry
insertion writes the primary's separate `auxiliary_output` tuple.

Rock retains the common activation, packet builder/getter, and its specialized
anchor. Its destructor releases embedded records and base state, with no
inspected tag reset. This bounded construction/publication/packet/cleanup chain
supplies no nonzero tag writer. Allocation-failure paths, later callbacks and
arbitrary aliases remain open; a universal auxiliary-zero invariant is unproved.

### Anchor callback family

The audited interfaces have 20 distinct primary anchor callbacks and 8
auxiliary callbacks. Of the 166 primary tables, 146 use the base and 20 use
19 alternatives; of the 53 auxiliary tables, 46 use the base and 7 alternatives.
These counts describe tables, not instantiated objects or admitted moves.
Each callback's arithmetic and resource effects are recorded in its annotation.

The primary base takes registration 1's sphere center, without z-bias. No
registration preserves `(0,0,0,1)`; a registration with null sphere produces
`(0,0,0,0)`. Alternative callbacks use signed offsets, scaled entity height,
entity positions, model bones, list results, or environment-corrected positions.
The recovered height scalar is
`(0.5 * CollisionEntityScalars.scale) * CollisionEntityScalars.height`;
the helpers multiply coefficient and scale before height or width. Original
anatomical meanings are not established.

The hand and foot resource names are `skill_anchor_hand_name` and
`skill_anchor_foot_name`. Resource branches refresh transforms: with no parent,
they copy local rows to world rows and clear the dirty byte; otherwise they
call `resource_transform_update`. Some temporarily replace the linked entity's
animation-player pointer, run `entity_resource_update`, then restore it.
Anchor generation can therefore mutate resources and participant state.

FIR performs forward and possible reverse environment segments with mask
`0x40000001`, match mode 1, second mask 0 and mode -1. It starts with a signed
175-unit endpoint offset; two hits add a signed 30-unit offset. It stores the
selected position, forces w=1, and can copy it to the linked entity before the
common combiner.

The auxiliary base starts from registration 1's center without z-bias.
Positive `anchor_span_x * anchor_span_z` instead selects object position plus
half spans; otherwise x shifts by signed `0.9 * radius`. Other callbacks add
fixed offsets, use a saved anchor, update a transform, add Rock's vec4 offset,
or substitute the Gate/Wall height calculation.

Conditional initialization remains a constraint. The auxiliary base's
no-registration branch overwrites its initialized output with an uninitialized
stack vector; a null sphere with nonpositive span takes a null radius load.
Some primary entity-position callbacks continue after a gate that leaves their
source uninitialized. KIW initializes result-center components only on an
accepted result, but its exhausted path still copies them. These static paths
do not establish that ordinary play supplies the missing inputs.

### Contact reconciliation

`interaction_reconcile_packets` combines anchors and positions. Its horizontal
helper uses half-width `w = width * 0.5`, displacement `d`, direction `s`,
position `p`, and anchor `a`. It queries from `(p.x,p.y,p.z+5,1)` to
`(a.x+s*(d+w),p.y,p.z+5,1)` with masks `(1,0,0,-1)`. A hit clips the endpoint;
a miss preserves it. The helper subtracts `s*w` from x, restores original y/z,
and returns `s*(output.x-a.x)`. Its `0x20`-byte scratch allocation is restored
before return.

| Ordered tags | Reconciliation | Position writeback |
| --- | --- | --- |
| `0,0` | Anchor midpoint, w=1; geometry branch skipped | Neither |
| `1,0` or `0,1` | Vertical/horizontal queries reconcile tagged participant against other anchor; emit corrected tagged anchor | Tag-1 participant |
| `1,1` | Reconcile both, paired horizontal adjustment and vertical checks, align anchor z, emit midpoint with w=1 | Both |

Manager packet-position snapshots precede reconciliation. Writeback follows
it, and both post-reconciliation callbacks run regardless of tags. The combiner
uses zero/nonzero tests and numeric byte addition, while the outer handoff
requires equality to 1. Arbitrary tag bytes cannot be generalized from this
confirmed 0/1 matrix.

### Pending-result slots

The manager has two `InteractionPending` slots containing participant,
counterpart, record, and active byte. The confirmed equal-branch producer
creates mirrored entries, selecting each slot by participant resource
`control_flags` bit 0, storing a copied prefix pointer, and setting active 1.

Processing temporarily changes the source, copies record data, submits it,
restores the source, and clears every slot field. Observed copy lengths are
`0x54` for a prefix and `0xA8` across the paired scratch area. Downstream
application belongs to [Hit response](hit_response.md).

## Separable stage/background queries

The annotated literal names `cc_bg_object_name`, `cc_bg_object_list_name`,
`cc_bg_system_name`, and `cc_bg_control_name` identify the stage cluster.
Queries use `BattleField.background`. `BgControl` carries per-section counts,
selected indices and head arrays for two line families, plus a vector of
`StageSectionConfig` boundary records.

First-family descriptor types are `0x25/0x26`; second-family types are
`0x23/0x24`. Section indices are 0 or 1. Original family/section gameplay names
remain unknown. Layouts, builders, stage counts, and selected-index writers
belong to [Stages](../stages/stages.md#line-construction) and its
[selected-index section](../stages/stages.md#selected-index-writers-and-neighboring-aliases).

Both builders initialize `StageLine.filter_flags` and `cached_attributes` to
zero. The second builder asserts on other descriptor types and inserts its
boundary record through `stage_insert_boundary_record`. The four resource
factories obtain the active control; a missing control selects
`bg_line_factory_noop` rather than building lines.

Nearest-line queries require `filter_flags == 1` when querying
`Fighter.movement_flags` includes `0x800`. No writer setting a nonzero line
flag is established. Traced selected-index initialization uses head 0 for each
populated section.

### Stage query functions

Here x and z mean vector components 0 and 2; engine axis names are unproved.

`bg_floor_profile` first takes the first second-family line satisfying the
strict interval `endpoint_a.x < query.x < endpoint_b.x`, then scans all
first-family lines and retains the lowest interpolated z, starting its minimum
at `32767.0`. Endpoints and reversed-x lines are excluded, and cached attributes
are not read. Output preserves input x/y, gives chosen z or sentinel
`-32768.0`, and w=1. `field_floor_profile` returns that sentinel when no
background control exists.

`bg_clamp_section_position` compares x with the caller-selected boundary
endpoints. Below or above copies the corresponding whole vec4 and returns 0;
inside returns 1. `field_clamp_position` works on a copy, can return the vector,
and returns 1 for a missing background control.

`stage_resolve_boundary` refreshes record B's span from its referenced endpoint
x difference, computes `ratio = abs(B.first.x-query.x)/B.span`, then
`candidate_x = A.first.x+A.span*ratio`. At or before B's first endpoint it
copies A's first endpoint; ratio above 1 or candidate x beyond A's second
copies A's second. Otherwise it interpolates z through A's endpoint pairs,
or uses the nearer neighboring endpoint in its terminal fallback. It mutates
the vector without a status result. Zero numerator leaves ratio zero; a
nonzero numerator with zero span is unguarded. Nonzero spans in valid resources
are therefore an inference. `stage_project_position` validates against field
`+0x7C`, whose broader meaning remains open, before reporting success/failure.
Boundary-record access is bounds-checked separately.

`bg_cache_line_attributes` queries line midpoints and caches the published
primitive flags. It inherits the environment query's slot-31 overflow reuse
and last-equal-distance winner rule. Flag meanings belong to
[Stage surface attributes](../stages/stage_surface_attributes.md#attribute-data-flow).

The two direct floor-profile caller paths use signed `Fighter.section`.
`skill_primary_height_gate` chooses the linked entity's section only when its
header-relative link-valid byte and resident linked-entity gate accept;
otherwise it selects 0. Its caller supplies the primary header.
`stage_correct_position` forwards its supplied section. The wrapper and
selected-chain accessors do not range-check it, so the two-section arrays
require a valid index. This selector is a geometry contract, not evidence that
a player's registry slot selects the stage section.

## Local triangle geometry cache

`triangle_build_primitive` derives a `TrianglePrimitive` from three vertices:
AABB bounds, flags, plane constant, normal, normalized edges, and edge lengths.
The plane constant is the negative dot product of normal and vertex 0.
`+0x9C` is unwritten by the builder and unread by the inspected narrow phases.
The `0xA0` format is the same primitive consumed by both resident query paths.

`triangle_update_hierarchy` rebuilds consecutive primitives from vertex data.
HKG and RSM callers resolve `skill_hkg_environment_model_name`
(`MDL_2hkgwal0`) and `skill_rsm_environment_model_name`
(`MDL_2rsm00t0 hit00`), then follow the resolved model's environment hierarchy.
Their refresh routines unregister and register the same resource collection
around updates.

`resource_register_environment` and its inverse walk collection entries:
type `0x800` uses an object's environment pointer, while type `0x100` follows
its nested model first. These edges establish ownership by resident
environment objects and registration for segment/swept-sphere queries.
No direct pointer/call edge joins the builder or updater to the interaction
manager or stage line manager. Indirect ownership remains open.

## Evidence strength, hypotheses, and negative results

The conclusions are bounded static results. Complete inspected bodies and
layout arithmetic establish ordering, gates, widths and capacities; negative
direct-reference audits cover their stated address/access forms. They do not
exclude arbitrary aliases, prove instance-level admission, or recover original
names. Conditional null/uninitialized paths do not establish ordinary-play
reachability. Full synthetic-record reuse, unexamined interfaces, derived
callback effects, and indirect ownership are unresolved.

## `ccSkillHNW001` interaction records and accepted-event route

[Battle entities](../session/battle_entities.md#ccskillhnw001-skill-actor)
owns identity, creation and states;
[Combo accounting](combo_accounting.md#repeated-event-contribution-in-ccskillhnw001)
owns pending-hit contribution.

### Borrowed interaction records

`skill_hnw_definition_row` identifies resource 165, count 4, and
`skill_hnw_definitions`. `interaction_preallocate_record_banks` maps the two
fighter jutsu selectors to resource indices, allocating only absent entries
for each admitted side. Count 4 requests `0x1A0` bytes per entry; repeat
admission retains the existing pointer. The manager owns both 197-entry banks
and frees them during destruction. Setup ownership belongs to
[Battle lifecycle](../session/battle_lifecycle.md#setup-helpers-after-fighter-publication).

HNW activation selects definition/runtime index 3, builds into the primary
header, and uses its secondary header as context. The descriptor borrows the
manager-bank allocation rather than making an actor-local copy. Earlier common
binding initializes index 0 when definitions exist. HNW update state 2 changes
pause/rejection through that first record, distinct from activation's record 3.
Unique ownership, later aliases and simultaneous reuse remain unresolved.

### Accepted-event callback and descriptor update

`skill_primary_accept_event` invokes the HNW receiver through primary slot
`0x1A0`, represented by `cc_skill_hnw_accepted_event_slot`. The ordinary branch
first tallies accepted events and flushes accumulated words; the guarded-target
branch also reaches the callback join. Statistical ownership belongs to
[Battle statistics](../session/battle_statistics.md#accepted-ninjutsu-and-combo-flushing).
Complete collision/authored-registration admission to the helper remains open.

`skill_primary_update_descriptor` requires active-header flag bit 0. One
confirmed local branch requires signed record pause nonzero and repeat count
below 2 before descriptor services and accepted-event delivery. Another calls
the helper after an optional definition-index increment: a valid linked target
with nonzero guard state skips the increment but still reaches the helper.
Earlier admission gates are not fully enumerated, and a receiver invocation
alone does not establish a newly delivered authored event.

`skill_hnw_accepted_event` compares header `update_count` with signed
`saved_repeat_count` before setting
`SkillHnw001.descriptor_threshold_reached`. The compared values belong to the
interaction descriptor; their comparison does not establish a timer or a
duration in frames or seconds.
