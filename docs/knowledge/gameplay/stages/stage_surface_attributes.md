# Stage polygon and surface attributes

## Research coverage

Established: authored flags, geometric query classes, eligibility contracts,
current and retained contact words, bounded consumers, footprint codes, all 24
stage archive distributions and generated wire attributes. Open: complete
consumer and alias coverage, remaining code meanings, resources, descriptor
replacement and mesh reachability.
Names come from `@annotations/NA2`.

## Evidence conventions

Addresses are live, following
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
Static code and archive evidence establish encoded predicates and ordering,
but not measured gameplay behavior, original material names, or reachability
of every input combination. Numeric predicates remain numeric unless their
meaning is established.

Per-routine details and bounded code censuses are in annotation comments.
This document describes
unmodified retail NA2 (`SLPS-25837`). Fighter field names follow verified raw
instruction offsets; current decompiler field expressions can misidentify
fields after pointer arrays.

Resident globals are annotated as `environment_published_primitive_flags`
for selected flags, `effect_manager_global` for the effect-manager pointer,
and `environment_object_head` for the shared environment registry root.

Related owners are [Collision](../combat/collision.md) for query geometry and
result layout, [Movement and physics](movement_and_physics.md) for motion,
[Stages](stages.md) for lifecycle and the independent stage/position effect
classifier, [CCS object types](../../game/files/ccs_object_types.md) for resource
attachment, [Battle audio](../session/battle_audio.md#surface-dependent-sfx) for
sound maps, and [Battle damage](../combat/damage.md#damage-caller-coverage) for
HP arithmetic.

## Authored word and geometric class

`ccs_parse_hit_mesh` reads a 16-byte `CcsHitHeader`, resolves its two
resource indices, and constructs geometry when `batch_count` is nonzero.
Each authored batch supplies a vertex count and one attribute word. Three XYZ
vertices form each triangle; an equal second bank of XYZ triples is read but
unused by this parser. The attribute word applies to every triangle in that
batch.

All batches are packed into one runtime group. Its
`EnvironmentBoundsHeader.count` is `total_vertices / 3`; the aggregate
group count is one. Authored batches therefore do not supply separate runtime
group-enable bits.

`ccs_transform_hit_triangles` builds the geometric cache and sets
`TrianglePrimitive.flags`:

```text
flags = (authored_word & 0x1FFFFFFF) | geometric_class
```

The authored word cannot override the derived high three bits. The normal's
third component and planar magnitude feed `audio_planar_angle` and
`atan2_float_bits`, supporting the interpretation
`atan2(n.z, sqrt(n.x*n.x + n.y*n.y))`. The encoded angle is the low 16 bits
of the integer conversion of `((angle + pi) * 32768 / pi) - 32768`.

| Encoded unsigned angle | Geometric class | Query role established by movement masks |
| --- | ---: | --- |
| `0x1C01..0x63FF` | `0x20000000` | Ordinary-axis downward contact selection |
| `0xA001..0xDFFF` | `0x80000000` | Ordinary-axis upward contact selection |
| Every other value | `0x40000000` | Ordinary-axis side contact selection |

Winding and normal direction matter independently of the authored low bits.
These classes describe query selection; they neither establish original enum
names nor guarantee fighter reachability. The confirmed producers are the CCS
hit parser and generated wire geometry.

## Attribute data flow

The resident environment query copies `TrianglePrimitive.flags` into
`EnvironmentCandidate.primitive_flags` and publishes the winner at
`environment_published_primitive_flags`. The polygon word and the
stage/position effect-variant column have separate producers; a matching
visual effect cannot identify which classification supplied it.

`fighter_apply_movement` copies the selected word to both
`Fighter.movement_flags` (current ground word) and
`Fighter.polygon_attributes` (retained selected word). No hit, selectively
passable rejection, and a nonzero `fighter_polygon_contact_class` result
clear only the current word. The retained word can therefore describe a
rejected contact as well as a previous accepted contact.

`fighter_base_construct` runs `fighter_init`, which clears all four words:
`side_damage_attributes`, `movement_flags`, `polygon_attributes`, and
`ceiling_damage_attributes`. Retention during movement does not imply
persistence through reconstruction
([Battle entities](../session/battle_entities.md#primary-fighter-factory-and-lookup)).

`effect_emit_with_contact_override` and
`effect_construct_twelve_selector` temporarily substitute current ground
attributes and position for effect selection, then restore them. The first
uses `SurfaceEffectScratch.saved_attributes` and `saved_position`;
the second uses the scratch attribute as its replacement while preserving the
old word separately. Neither updates the retained word. A current-word store
therefore need not publish a new ground selection.

### Bounded writer and alias coverage

The confirmed lifetime is constructor clearing followed by retained movement
selection. The bounded resident and BTL review established no additional
fighter retained-word writer, but did not exhaust computed addresses, virtual
callees, whole-object copies, or other programs. Its store counts and operand
search bounds are retained in the `fighter_init` annotation.

`fighter_load_character_record` copies the character definition into the
fighter's parameter block rather than copying another fighter's contact
block. Its complete body, `fighter_cleanup`, and
`fighter_base_destroy` have no direct retained-word reconstruction or
reset; this does not exclude their callees.

The same numeric region has different meanings in inspected auxiliary
layouts: position/velocity vectors (`AuxiliaryContactPositionView`,
`AuxiliaryCodeCacheView`, `AuxiliaryMidpointView`), an owned resource
handle (`AuxiliaryHandleView`), and parameter flags
(`AuxiliaryParameterView`). The two contact-query layouts use separate code
caches.
The handle's destructor releases it through `handle_e6c_destroy(handle,1)`
before clearing it. These stores cannot be classified as fighter writes from
their offset alone.

An embedded `WrappedScenePlayback` in `skill_jrb_rock_allocate`
also overlaps that numeric region: `wrapped_resource_construct` and
`wrapped_resource_reset` clear `signed_offset`; their `1.0` write is
to the separate `support_scalar`. This is auxiliary initialization, not
fighter contact reconstruction.

The retained word supplies the airborne recovery code
([Hit response](../combat/hit_response.md#response-exits)) and full-word wire
reaction predicate
([Stages](stages.md#animated-and-breakable-background-evidence)).
The annotation field name does not establish an original developer name.
The semantic consumer of the separate cached stage-line `+0x2C` remains
open ([Stages](stages.md#cached-line-attribute-consumers)).

## Query eligibility and contact classes

`collision_segment_query` uses
`environment_test_segment_triangles`. Both independent mask/mode pairs
must admit the primitive word `F`:

| Mode | Accepted predicate for mask `M` |
| ---: | --- |
| `0` | `(F & M) != 0` |
| `1` | `(F & M) == M` |
| `2` | `(F & M) != M` |
| `3` | `F != M` |
| Any other value | No restriction from that pair |

Zero mask with mode 0 rejects every triangle; with mode 1 it passes that pair
for every triangle. Inspected callers use mode -1 for an unrestricted pair.

`fighter_environment_query` uses `fighter_environment_collect`,
which first requires `F & 1`. Its single mask pair accepts any overlap in
mode 0 and requires all requested bits for every nonzero mode. The geometric
class alone is therefore insufficient for fighter contact. Both queries
publish the same winner word. The generic registry, geometry and result
contract are owned by [Collision](../combat/collision.md); the fighter
query's broader contract is not documented there.

The following attributes are consumed after selection, independently of the
geometric class:

| Consumer | Attribute selection | Consequence and boundary |
| --- | --- | --- |
| `surface_enter_from_air` | `side_damage_attributes & 0x100` | Permits aerial surface-axis entry after axis and input-duration gates. |
| `surface_segment_eligible` | Generic query `(0x40000001, mode 1)`, then winner `& 0x100` | Retains surface-axis eligibility; a missing hit substitutes `0x100` and retains it too. |
| `jump_select_variant` | Side word `& 0x100`, side-contact bit, and contact side different from desired direction | Sets `reaction_variant` bit `0x04` after direction handling; otherwise clears it. |
| `jump_impulse_update` | Grounded and `movement_flags & 0x800` | Doubles first-jump height input, not the resulting speed or an established measured apex. |
| `response_contact_enter` | Side word for `0x42/0x43`, ceiling for `0x44`, current ground for `0x45..0x47`, each `& 0x400` | Selects raw damage `0.04` rather than `0.02` through calculator flags `0x122` after entry gates. `0x48/0x49` do not set this selector; [Damage](../combat/damage.md#damage-caller-coverage) owns HP arithmetic. |
| `fighter_polygon_contact_class` | `movement_flags & 0xF0F0F0` | `0x00D0D0 -> 3`, `0xE0A000 -> 2`, `0x202020/0xE0E000 -> 1`, others 0. Only 1 and 2 have special handling. |
| `fighter_probe_special_ground` | Fresh downward fighter query and the same code classification | Only class 1 changes contact-phase bits and invokes the extra descent/contact path. It ORs the masked code into current `movement_flags`, without replacing either ground word with the full primitive word. |
| `effect_periodic_ground_code` | Supplied code `0xE0A000/0xE0E000` | Emits the numeric ground effect only when the integer cursor is divisible by 15. |

The special-ground classifier also has state, battle-sequence, attack and
resource gates. Class 2 always returns zero; class 1 can return one and enter
contact descent. A code match alone does not establish rejection of ordinary
grounding. Response exits belong to [Hit response](../combat/hit_response.md#response-exits)
and motion paths to [Movement and physics](movement_and_physics.md).
No material names are inferred from the repeated color-like bytes.

## Effects reached from polygon codes

`audio_surface_event` and `audio_request_contact_surface` select common
sound events from masked polygon codes. Their complete maps are owned by
[Battle audio](../session/battle_audio.md#surface-dependent-sfx).

### Retained-word consumers

These readers mask `Fighter.polygon_attributes` with `0xF0F0F0`,
independently of current contact, and do not refresh it:

| Reader | Retained-code consequence |
| --- | --- |
| `fighter_schedule_action_audio`, major 6 / substate `0x61`, after `timeline_secondary_event_crossed` event 0 succeeds | `0xE0E000/0xE0A000` suppress its `battle_emit_position_event` call; other codes take it. |
| `downed_recovery_update`, airborne `0x5D` with `state_flags & 0x08` | `0x202020/0xE0E000` retain recovery; other codes take the ordinary-response handoff. |
| `downed_motion_update`, `0x61`, after its animation-entry predicate | `0x202020/0xE0E000/0xE0A000` suppress paired `fighter_contact_feedback` and `vibration_enqueue_preset`; `0x00D0D0` does not. |

The surrounding response gates are owned by
[Hit response](../combat/hit_response.md#timed-downed-recovery);
the audio cue by
[Battle audio](../session/battle_audio.md#fighter-action-cue-production).

The `ccSkillTMR001` helpers use
`BtlAssociatedSelectorPlayback.fighter` only when
`substitute_primary` is nonzero and `downed_override_allowed` succeeds.
That gate requires a nonnull argument and battle hub; it does not inspect the
associated fighter or query collision. Otherwise the helpers substitute code
zero.

`tmr001_emit_retained_surface_objects` emits nothing for
`0x90B0C0`, `0xE0A000`, `0x202020` or `0xE0E000`. Every other code,
including substituted zero, creates two objects through
`battle_generator_create`, using `tmr001_generator_parameters_a` and
`tmr001_generator_parameters_b` with their annotated force descriptors,
then sets up and registers them. The independent stage/position classifier
supplies a column, stored as `column + 0x22` in
`BattleParticleGenerator.stage_surface_variant`. Polygon code gates emission
rather than supplying that column
([Stages](stages.md#background-classifier-and-slot-specific-objects)).

`tmr001_select_retained_surface` leaves `tmr001_surface_selector`
unchanged for `0xE0A000/0x202020/0xE0E000`, while obtaining a
stage-dependent scalar through `stage_effect_height_bits`; that scalar is
unused after its scratch store. Code `0x90B0C0` writes selector `0x72`;
all remaining codes write `0x70`.

The installed `cc_skill_tmr001_vtable`, its RTTI and name identify the class.
Its state-0 path enters state 1 through `tmr001_enter_state`, reaching the
first helper; the state-1 path reaches the second when the old `counter`
has its low two bits equal to three. Neither writes the associated retained
word. This is a bounded class-specific trace; move and terrain names and
complete callback coverage remain open.

### Effect-manager code inputs

`SurfaceEffectManagerView.polygon_code` is a shared effect input, distinct
from retained fighter contact:

| Writer | Publication and lifetime |
| --- | --- |
| `fighter_event_dispatch`, event `0x8002` | Publishes current ground `& 0xF0F0F0`, or zero for a missing fighter, before dispatch. Its tail writes `0xF0F0F0`, including other event types, without restoring the previous value. |
| `response_dispatch_transition`, grounded response `0x41` | Publishes current ground code, emits its ground row effect, then writes `0xF0F0F0`. |
| `tsunade_channel3`, action `0x2C` / phase 2 after the animation predicate | Publishes current ground code and invokes `effect_emit_manager_ground_code`; its complete body has no paired reset. |
| `effect_manager_setup` | Clears the code. |

This is the bounded direct-store set; computed and aliased writes remain
unexcluded. `0xF0F0F0` is itself recognized by
`effect_emit_manager_ground_code` and reaches an ordinary numeric
effect/sound branch, so the tail value is not an unused sentinel.

`effect_emit_selected_contact_code` reads the supplied fighter's current
word, or the manager code when the fighter is null. After masking,
`effect_emit_position_code` selects a numeric pooled effect for
`0x90B0C0`, the effect-21 helper for `0xE0A000/0xE0E000`, and no selected
branch for other codes. `effect_emit_manager_ground_code` and
`effect_emit_manager_contact_code` read the shared input too;
`effect_manager_dispatch` supplies it to `effect_emit_event25_code`
and `effect_emit_event29_code`. A helper can therefore consume polygon
code without directly reading a fighter word.

`effect_resolve_static_resources` resolves available resources from the
20 slots in `effect_static_resource_rows`. It converts each
`SurfaceEffectSourceRow.animation_name` to a runtime record ID, copies the
three masks into successive `SurfaceEffectRow` records at
`SurfaceEffectManagerView.first_surface_row`, and publishes
`surface_row_count`.

The row consumers select the first row satisfying:

```text
kind_bit = Fighter.exchange_roles == 0 ? 2 : 1
code = selected_contact_word & 0xF0F0F0
(row.kind_mask & kind_bit) == kind_bit
(row.contact_mask & contact_bit) == contact_bit
(row.code_mask & code) == code
```

`effect_emit_ground_contact_row` and `effect_emit_ground_descent_row`
use current ground and contact bit 1; `effect_emit_side_contact_row` uses
side contact and bit 2. A row mask can admit multiple codes; code zero passes
the code predicate. No match selects ID zero; a nonzero ID reaches pooled
animation setup.

Initially only slot 0 is nonnull:
`stage01_surface_effect_descriptor` names `s01.ccs` and one
`stage01_surface_effect_source_row` for `ANM_st01_bom_00`, with kind
mask 0, contact mask 1 and code mask `0x003060`. Kind mask zero fails both
kind choices, so the static row's presence does not establish emission.
Resource lookup success and descriptor replacement remain open. These
containment predicates differ from query eligibility and footprint equality.

The manager helpers also differ from each other:
`effect_emit_manager_contact_code` admits `0x202020/0xE0E000` and,
with a nonzero third argument, selects contact variant 3 using
`(polygon_code & 0x202020) != 0`; both codes pass.
`effect_emit_manager_ground_code` instead chooses variant 3 only for exact
`0x202020`, and variant 0 for `0xE0E000`.

Four bounded readers—`effect_1a_update`, `char_rcv1_callback_b`,
`char_rcv1_callback_a` and `effect_54_update`—share this current-ground
choice after their own action/animation gates:

| Current masked code | `battle_emit_position_event_variant` first / third arguments |
| --- | --- |
| Zero or `0x00D0D0` | Suppresses sound/effect branch and paired ground effects |
| `0xE0A000` or `0xE0E000` | `0x49 / 0x40` |
| `0x0060C0` | `0x21 / 0x3C` |
| Every remaining code | `0x25 / 0x3C` |

The first requires definition `0x0E`, the fourth `0x51`; both obtain the
fighter through `SurfaceCallbackOwner.fighter`. Their gates and placement
differ, so code equality alone does not cause emission. This is not a complete
callback census or a material-name assignment.

### Current-word activation

`fighter_polygon_contact_class` activates these per-side objects:

| Class and gate | Activation helper | Established internal identity |
| --- | --- | --- |
| Class 2 (`0xE0A000`), outside major states 2, 3 and 6 | `effect_activate_wash` | `ccEffWash`; sets `EffectWashActivation.active = 1` |
| Class 1 (`0x202020/0xE0E000`), major 0 or 1, `contact_flags & 0x10` clear | `effect_activate_leak_chakra_current_manager` / `effect_activate_leak_chakra` | `ccEffLeakChakra`; sets `EffectLeakChakraActivation.active = 1` |

Each helper resolves or creates the object. Wash excludes definition
`0x4C` (76), Sasori (Hiruko)
([Character IDs](../characters/character_ids.md)). Leak-chakra requires
`Fighter.hp != 0`, not current `chakra`. These are specific activation
gates rather than a complete exception census. RTTI establishes the internal
effect names, not the polygon code's original terrain label.

The separate periodic path uses `effect_emit_ground_21(fighter,0)`,
which derives placement from the fighter transform and reaches
`effect_create_ground_21`. The latter acquires an object from the manager
animation pool and assigns numeric effect `0x21` through
`effect_set_identifier`; its original effect name is unknown.

The class-1 contact path also conditionally debits current `chakra`,
lower-clamps it to zero and writes `15.0` to `chakra_history_old`.
Its initial classification uses ground codes, not input history.
[Chakra and guard](../combat/chakra_and_guard.md) owns the wider spend contract.

## Footprint surface selection

`footprint_surface_selected` masks the polygon word with `0xF0F0F0`
and returns true if any enabled bit of `BgFootmarks.surface_selection`
matches its exact code:

| Selection bit index | Required masked polygon code |
| ---: | ---: |
| 0 | `0x003060` |
| 1 | `0x90B0C0` |
| 2 | `0xE0E000` |
| 3 | `0xE0A000` |
| 4 | `0xE0E090` |
| 5 | `0x606060` |
| 6 | `0x80D0F0` |
| 7 | `0x005000` |
| 8 | `0x0060C0` |
| 9 | `0x00D000` |
| 10 | `0x8080F0` |
| 11 | `0x00D0D0` |
| 12 | `0xE0E0E0` |
| 13 | `0x0010C0` |
| 14 | `0x202020` |
| 15 | `0xF0F0F0` |
| 16 | `0xF0D0D0` |

`footprint_construct` stores the configuration's integer token into that
selection mask. S12, S16 and S18 configurations each supply token 2, enabling
only bit 1. Each archive contains four triangles authored `0x0090B0C1`,
which mask to `0x90B0C0`. This connects authored attributes to acceptance;
[Stages](stages.md#animated-and-breakable-background-evidence) owns model
placement, pooling and fade. The table neither names materials nor proves
every code occurs in a retail footprint configuration.

## Stage-authored attribute distribution

These observed counts come from gzip-decoded retail `STAGE/S01.CCS`
through `S24.CCS`. Retained `0x0B00` hit-block candidates have in-bounds
payloads, valid `HIT_` and linked `MDL_` directory indices, vertex counts
divisible by three, a batch sum matching the header total, and exact endpoints
after both vector banks. The aligned scan after chunk 3 does not depend on
unrelated blocks' sometimes inaccurate declared lengths
([CCS runtime](../../game/files/ccs_runtime.md#parsing-type-dispatch-and-publication)).

Entries are **authored word: triangle count**, before geometric
classification. They include object hit meshes present in the archive, not
only active, reachable or floor-facing polygons.

| Archive | Hit meshes / batches / triangles | Authored word: triangle count |
| --- | --- | --- |
| S01 | 5 / 8 / 1623 | `000061C1:8`, `0080D0F1:10`, `00E000E1:32`, `00E002EA:1573` |
| S02 | 7 / 10 / 749 | `00606061:28`, `00606161:8`, `0080D0F1:4`, `00E000E1:16`, `00E002E2:693` |
| S03 | 7 / 12 / 834 | `00003061:4`, `00005001:8`, `000063CF:2`, `0000D801:6`, `00606161:8`, `00E000E1:12`, `00E002E2:790`, `00E0E001:2`, `00E0E002:2` |
| S04 | 8 / 20 / 397 | `00003061:16`, `00606061:10`, `00606161:8`, `00E000E1:26`, `00E002E2:337` |
| S05 | 5 / 13 / 2179 | `00003161:34`, `00606161:12`, `00E000ED:9`, `00E002EE:1955`, `00E0A001:18`, `00E0E002:151` |
| S06 | 6 / 11 / 742 | `00003061:10`, `00005001:10`, `000061C1:2`, `000062CA:86`, `0000D80D:8`, `00606161:2`, `00E000E1:18`, `00E002EE:606` |
| S07 | 6 / 13 / 1125 | `00003061:12`, `00005001:8`, `000061C1:8`, `000062CE:236`, `0000D801:8`, `00E000E1:8`, `00E002E2:845` |
| S08 | 7 / 13 / 395 | `000060C1:34`, `000061C1:8`, `0000D801:16`, `00959595:2`, `00E000EF:24`, `00E002E2:311` |
| S09 | 5 / 13 / 976 | `00005001:12`, `000060C1:10`, `000061C1:2`, `00606061:12`, `0060606F:8`, `00606161:6`, `00E000E1:20`, `00E002E2:898`, `00E0A001:8` |
| S10 | 6 / 10 / 1471 | `000060CD:2`, `00606061:38`, `00606161:8`, `00E000E1:8`, `00E002E2:1409`, `00E0A001:4`, `00E202EA:2` |
| S11 | 6 / 12 / 1844 | `00003061:14`, `00005001:4`, `000060C1:4`, `000061C1:8`, `0000D801:8`, `00606161:2`, `00E000E1:16`, `00E002EA:1786`, `00E0A001:2` |
| S12 | 5 / 7 / 614 | `00606161:8`, `0090B0C1:4`, `00E000E1:8`, `00E002E2:594` |
| S13 | 13 / 20 / 593 | `0000D801:6`, `00606061:12`, `00606161:6`, `0080D0F1:14`, `00E000EF:24`, `00E002E2:413`, `00E0E001:2`, `00E0E002:100`, `00E202E6:16` |
| S14 | 7 / 13 / 456 | `00003061:14`, `00005001:6`, `000061C1:4`, `0000D805:16`, `00606161:4`, `00E000E1:10`, `00E002E2:402` |
| S15 | 4 / 13 / 410 | `00005001:22`, `000061C1:4`, `00202021:8`, `00606061:16`, `00606161:2`, `00E000E1:12`, `00E002E2:155`, `00E202E2:191` |
| S16 | 5 / 8 / 284 | `00005001:12`, `000061C1:8`, `0090B0C1:4`, `00E000E1:8`, `00E002E2:252` |
| S17 | 5 / 7 / 778 | `00005001:4`, `00606161:8`, `00E000E1:8`, `00E002E2:758` |
| S18 | 5 / 7 / 583 | `00606161:8`, `0090B0C1:4`, `00E000E1:8`, `00E002E2:563` |
| S19 | 6 / 10 / 812 | `00003061:4`, `00005001:16`, `000060C1:6`, `000061C1:8`, `0000D801:8`, `00E000E1:16`, `00E002E2:754` |
| S20 | 6 / 10 / 513 | `000061C1:4`, `00606061:2`, `0080D0F1:6`, `0080D1F1:4`, `00E000E1:24`, `00E002E2:473` |
| S21 | 5 / 7 / 360 | `00606061:4`, `00606161:8`, `00E000E1:12`, `00E002E2:336` |
| S22 | 5 / 11 / 1084 | `00003061:12`, `00005001:4`, `000061C1:2`, `00606161:4`, `0080D0F1:2`, `0080D1F1:2`, `00E000E1:12`, `00E002E2:1046` |
| S23 | 6 / 13 / 355 | `00606061:2`, `008080F1:10`, `008080FF:8`, `0080D0F1:22`, `00E000E1:20`, `00E000EF:4`, `00E002E2:86`, `00E202E2:95`, `00E202E6:108` |
| S24 | 5 / 8 / 738 | `0000326F:4`, `0060626F:28`, `0080D0FF:32`, `00E000EF:32`, `00E002E6:642` |

Every retained word is below `0x20000000`, so classification preserves all
its authored bits. Class-1 codes occur as `0xE0E001` in S03/S13 and
`0x202021` in S15; class-2 `0xE0A001` occurs in S05/S09/S10/S11.
Several `0xE0E002` batches lack required fighter-query bit 1, so membership
of a masked class alone cannot make them a fighter floor. No retained batch
masks to `0x00D0D0`.

The sole retained stage word with `0x10000` is `0x00959595`: two triangles
in S08 `HIT_s08are00_hit_s3`. Its masked `0x909090` is outside the four
special-ground codes. This bounds the authored selectively passable source
([Movement and physics](movement_and_physics.md#floor-side-surfaces-and-limits)),
without proving its registration or position. It is also the sole retained
stage word with the `0x400` contact-damage selector.

## Generated wire polygon attributes

`ccElectricWire` creates sixteen `0x1F0`-byte `ccWireHitModel`
elements, each with a resident environment-query object and two triangles.
[Stages](stages.md#animated-and-breakable-background-evidence) owns configuration
and reactive simulation.

The attribute ordering is:

1. `bg_wire_segment_construct` invokes `wire_segment_init`, clearing
   `BgWireSegment.polygon_attributes`.
2. `wire_segment_build` creates the environment object and initial geometry
   through `wire_segment_create_geometry` / `wire_segment_rebuild`,
   then registers it with `environment_object_register(object,0)`.
3. `bg_wire_build_segments` stores the wire word `0x2001D9D1` into the
   segment after that construction. The store alone does not update triangles.
4. `bg_electric_wire_parse` starts with `geometry_dirty = 1` and invokes
   the installed update. Eligible `bg_electric_wire_update` reaches
   `bg_wire_refresh_dirty`, which replaces endpoints and rebuilds dirty
   segments through `wire_segment_replace_endpoints`, then clears dirty.
   Later dirty refreshes use the same path.
5. `wire_segment_cleanup` releases the environment object and visual model.

Initial triangles have zero authored bits plus their derived class. Each
refresh supplies `0x2001D9D1` to the ordinary triangle builder, which drops
its supplied high bit and derives a fresh class from the current normal.
The retained authored low bits `0x0001D9D1` carry fighter-query bit 1,
surface eligibility `0x100`, first-jump input multiplier `0x800`,
selectively passable `0x10000`, and code `0x00D0D0` (class 3).
This is an additional static code source absent from the stage hit-block
distribution.

Both environment queries walk the same registry using
`CollisionEnvironment.next`; their attribute predicates still differ.
The wire reaction requires full retained-word equality with `0x2001D9D1`.
It therefore also requires geometric class `0x20000000`: an initial
triangle, or a refreshed triangle selected under another class, cannot satisfy
that equality simply because it belongs to the wire. Retention through contact
rejection also means equality alone does not prove current grounding.
The inspected wire path has no fighter hit or HP write.

`cc_wire_hit_model_vtable`, `cc_wire_hit_model_rtti` and
`cc_wire_hit_model_name` identify the segment class.
