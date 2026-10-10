# Battle-entity ownership and lifecycle

## Research coverage

Established: independent owners, aliases and lookup/callback contracts,
table-selected fighter lifetimes, transient serials/children, support
slots/generations, traced skill lifetimes, and inherited/specialized direct-skill
class/action/resource joins. Names come from `@annotations/NA2`.

Open: other creation/mutation routes, camera/coordinator/sentinel meanings,
duplicate lookup policy, and complete support/skill-specific lifetimes.
Static analysis establishes no execution or allocation-failure frequency.

## Evidence identity and address conventions

This concerns unmodified retail NA2 (`SLPS-25837`). Side 0 is Player 1;
side 1 is Player 2/COM. Selected support IDs are configuration, not live pointers.
[Battle lifecycle](battle_lifecycle.md) owns scheduling/session order,
[Battle camera](battle_camera.md) owns camera computation,
[Battle support mechanics](../characters/support_mechanics.md) owns request,
gauge and support behavior, and
[Character action callbacks](../characters/character_action_callbacks.md)
owns character combat methods.

Inputs and live-address conventions belong to
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
All addresses here are live; resident addresses have no overlay bias.

The resident ELF's BSS is mapped in Ghidra. The resident globals and shared
camera output below use names from `@annotations/NA2/SLPS_258.37`, including
globals accessed by BTL code.

## Ownership model

The resident manager holds configuration and borrowed aliases. Three other
roots own entities: the battle-state-owned hub, transient manager and support owner.

| Root | Storage/ownership |
| --- | --- |
| `battle_manager` | pointer to `BattleManager`, `0xDF8`; borrowed primary/input aliases |
| `battle_session` | pointer to `BattleState`, `0x38`; owns `hub`, borrows `camera_root` |
| `battle_hub` | borrowed mirror of `BattleState.hub` |
| `battle_transient_manager` | pointer to `ProjectileManager`, `0xD0`; owns singly linked actors and deferred-child owner |
| `support_owner` | pointer to `SupportOwner` / `ccBuddyAtkCtrl`, `0x24`; owns two side slots, embeds `SupportGeneration` / `ccBdySerialNo` |

`BattleHub` owns camera, input, fighter/coordinator and field registries,
each owning its linked nodes. `battle_owner_destroy_members` destroys those registries in
that order. Graph teardown destroys the transient manager first, while primary
aliases remain resolvable; it then clears all six primary/input aliases before
hub destruction. Borrowed fighter/input/camera/field cross-links never transfer
ownership or become destruction paths.

## Resident manager and battle-state lifecycle

### Manager allocation and alias slots

`manager_allocate` publishes the manager only when its global is null.
Construction and setup are separate. Initialization/teardown clear both
original three-entry alias arrays.

| Manager field | Original logical index | Contract |
| --- | ---: | --- |
| `reserved_fighter_alias` | 0 | reserved zero |
| `fighters[0/1]` | 1/2 | borrowed side-0/1 primary |
| `input_aliases[0]` | 0 | reserved zero |
| `input_aliases[1/2]` | 1/2 | borrowed side-0/1 input |

The original arrays use `side + 1`; reserved entries are not support slots.
Configuration uses `BattleManager.current.sides[side]` with `0x28` stride;
runtime pointers have stride 4. `BattleCharacterSlot.character_id`,
`selected_support` and `support_selector` are separate configuration fields.

`primary_fighter_get` returns a borrowed primary only for side 0 or 1; other inputs
return null. It does not inspect generic node flags. The sole decoded direct
nonzero publisher is `battle_create_graph`; manager initialization/teardown and
graph teardown clear aliases. Direct BTL references read them. Stores at equal
numeric offsets in unrelated objects do not identify manager writers.

The alias surface does not self-repair. Generic or fighter-specific removal
can destroy a registry member without clearing/republishing its manager alias.
Borrowed publication and membership therefore have separate lifetimes.

### Battle-state and hub publication

`battle_create_graph` allocates an absent hub, publishes its owning battle-state
pointer and borrowed mirror, constructs the graph, publishes input aliases
before primary aliases and borrows the root camera. The node-start broadcast
then reaches all four registries, followed by transient-manager creation.

`battle_destroy_graph` clears manager aliases before hub destruction, then clears
the owning hub pointer and mirror. It never directly frees a primary/input node.
Outer state construction and exact session order belong to
[Battle lifecycle](battle_lifecycle.md#session-construction).

## Hub and registry construction

| `BattleHub` field | Registry | Allocation | Initial contents |
| --- | --- | ---: | --- |
| `camera` | `ccCameraCtrl` / `CameraRegistry` | `0x18` | one `ccCamera01` root |
| `input` | `ccCommandCtrl` / `GenericList` | `0x10` | two per-side inputs |
| `fighters` | `ccPlayerCtrl` / `FighterCoordinator` | `0x34` | two primaries |
| `field` | `ccFieldCtrl` / `GenericList` | `0x10` | one `ccField` |

All share the owning list prefix; camera/fighter registries also own derived
state. Class identities come from RTTI rather than unexplained field shape.

### Derived fighter registry/coordinator

The owning fighter list also coordinates state. `FighterCoordinator.state`
starts at 1 and dispatches 0..6. `fighter_coordinator_set_state` installs state and clears
`local_state/local_counter/local_word`, retaining both borrowed participants.
`fighter_coordinator_get_state` returns state or -1 if unavailable.

The participants are borrowed from manager aliases or an explicit pair.
`auxiliary_b0` and `auxiliary_3c` are owned; the former also owns its
`CoordinatorAuxiliaryB0.owned_storage`. Destruction clears fighter nodes first, then the `0x3C`
auxiliary, then the nested allocation and `0xB0` auxiliary. It never frees
participants.

The chain `battle_hub → BattleHub.fighters → FighterCoordinator.state`
reaches a scalar. A zero gate is **state == 0**, as used by
[manual support gates](../characters/support_mechanics.md#manual-request-gates-and-return-states),
not support-pointer absence or fighter count.

Removal has two routes. `fighters_update` removes an update-enabled fighter
with `update_pause.current < 1` when fighter virtual slot `+0x1C` returns
nonzero. Subsequent generic maintenance independently removes for bit 0 or
a nonzero phase-1 callback. Both retain next before destruction.

### Coordinator timeout-marker check

State 3 selects `fighter_coordinator_state3`. Missing either borrowed participant resets
the selector and three local words. With both present, timeout is read only
at `local_state == 0` and old `local_counter == 0`.

A set marker selects local state 1/counter zero and bypasses the clear-marker
participant active-bit clearing and calls. Later nonzero counters or local
state 1 do not retest it. An independent counter advance also reaches state 1,
so that state alone does not prove timeout. State installation retains
participants. Neither this handler nor dispatcher writes the marker;
[Match outcomes](match_outcomes.md#terminal-detector-and-classifier)
owns its producer/reset. Original state names and broader effects remain open.

### Initial graph creation

`battle_create_sides` creates camera, input 0, input 1, fighter 0, fighter 1 and
field in order. Camera allocation is `0x1D0`, each input `0xC0`, field
`0x90`; fighter sizes follow below. Successful results append into their
registry; null results omit affected borrowed links.

This is not transactional allocation. Registries allocate independently and
can publish null. Camera creation checks its registry; fighter creation skips
its factory without a registry. Input/field creators guard new allocations
but assume destination registries. Resident setup can publish a null hub and
immediately call graph creation, and primary lookup assumes the fighter
registry. No rollback/failure return is decoded. Registry destruction remains
independently null-safe.

### Initial cross-reference graph

| Source | Borrowed target |
| --- | --- |
| fighter 0/1 `opponent` | fighter 1/0 |
| fighter 0/1 `input` | input 0/1 |
| both fighters `field` | field node |
| input 0/1 `fighter` | fighter 0/1 |
| input 0/1 `opponent` | fighter 1/0 |
| root camera `node.graph_links[0/1]` | fighter 0/1 |

Later opponent fallback/geometry belong to
[Target selection](../combat/target_selection.md#paired-opponent-and-geometry-refresh).
The field owns its embedded list and `0xAD0` background allocation, releasing
both before generic base destruction. Fighter `field` remains borrowed;
nested content belongs to [Stages](../stages/stages.md#live-environment-ownership-and-construction).

## Primary-fighter factory and lookup

`battle_create_primary_fighter` indexes `character_definition_table` by selected primary ID and invokes
its factory without a local ID bounds check. Row zero has no factory; row one
selects `fighter_id_001_create`. It does not consume support selection.

All 74 constructors surround class setup with common base construction and
initialization. Initialization copies `character_id` and the low
`control_flags` side bit; other bits are not side IDs. Success enables
generic bits 1/2. Bit 1 gates fighter update/derived processing, and the
fighter callback returns zero, never requesting generic virtual-return removal.
Bit 2's broader meaning remains unassigned here.

`battle_find_primary_fighter` returns the last linked low-side-bit match regardless of
generic flags. Resident setup publishes one result per side.

### Complete table-selected concrete lifetime paths

The 94-row resident table has row zero `{0,0}` and 93 populated rows selecting
74 factories; 20 rows share the ID-1 factory.
[Character identity](../characters/character_ids.md#character-definition-table)
owns record/eligibility differences. Annotations preserve every factory,
constructor, final-vtable and destructor join.

Factories allocate complete concrete sizes, construct only a nonnull result
and return it. All concrete deleting destructors run common cleanup and base
destruction with argument zero, then free the complete allocation only for a
positive signed 16-bit argument. Class cleanup may precede or follow common
cleanup; the zero base argument prevents double free. Borrowed aliases are
never destruction owners.

| Character ID(s) | Complete allocation |
| --- | ---: |
| 1, 8, 9, 20, 21, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 44, 45, 74, 88 | `0x5980` |
| 2 | `0x58E0` |
| 3 | `0x5950` |
| 4 | `0x5530` |
| 5 | `0x5890` |
| 6 | `0x5750` |
| 7 | `0x56C0` |
| 10 | `0x5280` |
| 11 | `0x5670` |
| 12 | `0x5270` |
| 13 | `0x5630` |
| 14 | `0x5040` |
| 15 | `0x5800` |
| 16 | `0x5820` |
| 17 | `0x5710` |
| 18 | `0x5380` |
| 19 | `0x56B0` |
| 22 | `0x57C0` |
| 34 | `0x5270` |
| 35 | `0x50C0` |
| 36 | `0x4A00` |
| 37 | `0x5860` |
| 38 | `0x58B0` |
| 39 | `0x5D40` |
| 40 | `0x5030` |
| 41 | `0x54E0` |
| 42 | `0x52A0` |
| 43 | `0x5530` |
| 46 | `0x58A0` |
| 47 | `0x5840` |
| 48 | `0x59C0` |
| 49 | `0x5E30` |
| 50 | `0x50C0` |
| 51 | `0x5470` |
| 52 | `0x5270` |
| 53 | `0x4AE0` |
| 54 | `0x4B70` |
| 55 | `0x5400` |
| 56 | `0x5690` |
| 57 | `0x5B60` |
| 58 | `0x5690` |
| 59 | `0x5CC0` |
| 60 | `0x5630` |
| 61 | `0x5720` |
| 62 | `0x5D00` |
| 63 | `0x5140` |
| 64 | `0x5C00` |
| 65 | `0x5F00` |
| 66 | `0x5CC0` |
| 67 | `0x6880` |
| 68 | `0x5C70` |
| 69 | `0x69C0` |
| 70 | `0x5870` |
| 71 | `0x5710` |
| 72 | `0x5090` |
| 73 | `0x5840` |
| 75 | `0x5660` |
| 76 | `0x4F40` |
| 77 | `0x6F60` |
| 78 | `0x6260` |
| 79 | `0x50E0` |
| 80 | `0x6230` |
| 81 | `0x6240` |
| 82 | `0x5D80` |
| 83 | `0x54C0` |
| 84 | `0x5950` |
| 85 | `0x59F0` |
| 86 | `0x5750` |
| 87 | `0x5630` |
| 89 | `0x5900` |
| 90 | `0x52C0` |
| 91 | `0x5AD0` |
| 92 | `0x5310` |
| 93 | `0x6200` |

The minimum is `0x4A00` (ID 36), maximum `0x6F60` (ID 77); nested heap
consumption is additional. All 74 constructors mark removal bit 0 after a
nonzero initializer result but still return the object. The hub appends a
nonnull result without testing that bit; lookup can still select it.
Initialization failure is deferred removal rather than factory rollback;
ordinary-play occurrence is not established.

`FighterId78.owned_children`, `FighterId80.owned_children` and its two
owned pairs, and `FighterId92.owned_children` identify demonstrated concrete
children. They are not extra primary slots. Character methods belong to
[Character action callbacks](../characters/character_action_callbacks.md#complete-bounded-classslot-census).

### Common fighter-owned children

The common class is `ccPlayer`; concrete construction replaces its base table.
All 74 concrete destructors invoke common cleanup/base destruction.

| Fighter storage | Lifetime |
| --- | --- |
| `owned_handle_e68/model_collection/owned_animation_player/owned_handle_e74` | four optional owning handle slots; release and null |
| `owned_handle_list` | owns nodes and each node's handle; free nodes/owner and null |
| `owned_child_list` | owns handle, child nodes and their handles; release all/free/null |
| `FighterListOwner.primary/secondary` at embedded `+0x8C4` | embedded owning lists; no separate storage free |
| `embedded_array_bd0/c80/d30` | three arrays of two `0x50`-stride objects; reverse teardown |
| `embedded_managed_dd0/df4/e18` | three embedded objects; reverse teardown |
| `embedded_children` | embedded owning generic list; clear nodes |
| `embedded_node` | generic node subobject of the same allocation |
| `primary_timeline` through `embedded_block_290` | seven `0x24`-stride subobjects; table restoration without outer frees |

Cleanup's use of `FighterHandleListNode.referenced_handle` alone does not
prove ownership. It additionally releases/clears the per-side combo owner;
[Damage](../combat/damage.md#native-combo-owner) owns that behavior.

### Bounded creation and mutation-route coverage

Each table-selected constructor has one decoded resident factory caller;
no encoded constructor call was found in BTL. Exact stored-pointer callbacks
for primary creation, generic append and removal were absent from both audited
images. The known direct route is startup.

This does not exclude assembled addresses, register-computed calls or
indirectly reached containers. Global absence of other creation/mutation
routes is not established.

## `ccCommandCtrl` per-side control registry

The hub input registry owns one `BattleInput` / `ccCommand` per side.
`side` is a full word, `pad` borrows the resident input slice,
`identifier` selects `controller1/controller2`, and `records` is owned.

Missing global input state/required allocation marks generic removal; successful
binding sets bit 1. `input_object_get_by_side` returns the last full-word side match
without checking removal flags. Published aliases are control/history objects,
not support fighters.
[Action commands](../combat/action_commands.md#battle-input-object-and-history)
owns interpretation.

## `ccCameraCtrl` current-node semantics

`CameraRegistry.current/previous` supplement its generic list. Each camera's
borrowed `output` is also its lookup key. Insertion clears bit 1/current marker
on an older same-key node, appends the new one, records old/new pointers and
marks the new node current.

`camera_registry_find_key` returns the last key match, ignoring current.
`camera_registry_find_current` also requires the requested current bit masked by 1;
`battle_find_current_camera` requests 1. Separately, `battle_find_camera_root` selects the last
generic `root_selector == 0` node; initial insertion sets it zero when count
becomes one.

Main and four controller slot cameras share output `primary_draw_environment`. Slot
cameras use ordinary append and start noncurrent, so last-key lookup can select
an inactive camera. Filtered lookup/current pointer are different contracts.
Each camera owns an independent `0x50` engine camera while borrowing output.
The selector's wider domain remains open.
[Battle camera](battle_camera.md#camera-classes-and-activation) owns switching.

## Generic intrusive node and list contracts

### Container prefix

`GenericList` names count/head/tail/vtable. Append links after old tail and
increments count. Removal repairs links/endpoints, decrements count and invokes
node deletion with argument 1. Clearing saves next before destroying every
linked node, establishing list ownership.

### Node prefix

`GenericNode` names flags, live marker, reset words, signed kind/root selector,
identifier, intrusive/borrowed graph links, reset bytes and vtable. The base
clears bits 0..2, initializes marker `0x474F`, sets both selectors -1 and
clears documented reset/link storage. Destruction restores its base table and
clears the marker before optional free. Subclasses specialize these fields.

### Generic node passes

| Node slot | Contract |
| --- | --- |
| `+0x08` | deleting destructor after unlink, argument 1 |
| `+0x0C` | start broadcast after graph construction |
| `+0x10` | phase 1; nonzero return requests removal |
| `+0x14` | phase 2 |
| `+0x18` | phase 3 |

Phase 1 saves next before acting. Bit 0 destroys immediately without invoking
phase 1; otherwise a nonzero callback also removes. A clear bit proves only
absence of this immediate request. Class bits 1/2 are separate.

Registry `+0x0C/+0x10/+0x14` reach the phases; `+0x08` destroys the registry.
Input/field use generic thunks, camera the generic phase-1 walk and fighter
coordinator overrides all three. Camera/field starts are empty; input start
refreshes bindings. Scheduling belongs to
[Battle lifecycle](battle_lifecycle.md#per-update-dispatch).

## Transient-actor manager and side ownership

`ProjectileManager` owns an independent transient family; the annotation
name does not restrict it to one gameplay role. It owns head/tail, linked count,
serial source, deferred-child service and a resident auxiliary at raw
`+0x2C`, whose complete width is not established here.

`Projectile.linked` is membership; `next` is only the chain link.
Unlink rejects a clear membership marker, repairs endpoints, clears membership
and decrements count. It neither clears removed next nor decrements serial.
A next pointer alone therefore cannot establish membership.

The first pass saves next, performs common work and invokes virtual
`+0x44`; zero unlinks and destroys. Whole teardown destroys tail to head.
This is independent of generic bit 0 and proves manager ownership rather
than primary-fighter ownership.

`update_disabled` suppresses actor/update/removal/deferred recycling.
`service_disabled` independently suppresses virtual-`+0x48` and the
second child pass. That actor callback also requires a nonzero signed read
of `service_enabled` (raw `+0x206`); its wider domain meaning is unassigned
here. Neither gate changes membership.

Serial source starts zero; insertion assigns its old value then advances.
Zero is valid. No decoded 32-bit-wrap collision check exists; duplicate
serial lookup returns the first reachable match. Type/side queries are separate.

### Factory, descriptor, and side mapping

`transient_actor_create` accepts selector 0/1, stores affiliation `selector ^ 1`,
constructs from `transient_actor_descriptors` (`0x68` stride), initializes and applies
virtual transform/state setup before linking. Other selectors return null.
`ProjectileConfig.class_selector` chooses among 103 decoded class constructions.

The wrapper assumes a nonnull factory result and has no partial rollback.
Membership guards repeat insertion. It appends/marks, assigns serial/counts
and only then registers an optional deferred child. The descriptor is borrowed;
`config_index` is the initializer type/index and `external_id` copies
`ProjectileConfig.external_id`.

| `side_tag` | Opposite side | Own primary | Opponent | Type-query selector |
| ---: | ---: | --- | --- | ---: |
| 0 | 1 | manager side 0 | manager side 1 | 1 |
| 1 | 0 | manager side 1 | manager side 0 | 0 |
| other | -1 | null | null | -1 |

This is an actor-family convention, not every BTL node. Side is a tag rather
than parent pointer; primary aliases supply context.

### Deferred child ownership

Descriptor child kinds 1/2 may create a `0x4C` `DeferredChild`, referenced
by `Projectile.notification`. It borrows parent `notification_transform`
through `parent_data`. With an available manager service, the child is
prepended into its owning `DeferredChildOwner` chain.

Parent unlink/base cleanup marks state 1 and clears the parent reference.
The auxiliary permits draining, advances 1 to 2 once drained and on a later
pass destroys state >= 2. Auxiliary destruction destroys all registered children.
This is deferred manager ownership, not immediate parent-recursive free.

## Dynamic support-object owner

Support selection, implementation selector, scalar side record and pointer slot
are distinct. Startup consumes primary IDs and creates only two primaries,
two inputs, camera and field. It pre-creates no fielded support.

Normalization replaces sentinel `0x26` in selected-support storage itself
and derives implementation. It is pre-battle configuration, not a live handle.
[Support setup](../characters/support_mechanics.md#setup-and-selected-support)
owns mapping/writers.

### Separate owner and exact side slots

Outer driver setup replaces the independent support owner after BTL selection;
cleanup destroys it/clears global. Constructor clears slots, initializes each
side record `{0,1,0}`, generation allocator and one-shot latch.
Supports join neither hub nor transient chain.

| `SupportSideRecord` field | Initial | Later role |
| --- | ---: | --- |
| `color` | 0 | normalized color variant |
| `linked_mode` | 1 | Manual 0 / Auto 1, Practice row 4 |
| `recharge_class` | 0 | setup class, default 2; initializes fighter raw `+0x78` |

These are scalar bytes, not addresses/occupancy. Presence is nonnull side slot.
[Practice mode](../modes/practice_mode.md#rows-local-values-and-manager-storage)
owns Linked Mode; Support mechanics owns color/recharge behavior.

Separate `support_counter_records` stores `SupportCounters`, three signed
halfwords per side. Creations increment after successful new allocation, never decrement
on slot destruction. Reasons use support side and assert if invalid.
The third receives signed lineage deltas. They are not occupancy/generation IDs.

### Request, class creation, and repeated calls

Resident gates pass masked fighter side to BTL.
`support_object_request` allocates/publishes. Selector below `0x44` with an empty
slot creates and returns 1; an occupied object is retained and queried for
2 or 0. Selector >= `0x44` returns 0.

| Selector(s) | Allocation | Class path |
| --- | ---: | --- |
| remaining `0x00..0x43` | `0x510` | common |
| `0x0A` | `0x520` | specialization |
| `0x0C/0x11` | `0x510` | table replacements |
| `0x15/0x16/0x17` | `0x520` | shared constructor, final table replacement |
| `0x19` | `0x530` | specialization |
| `0x1E` | `0x520` | specialization |
| `0x1F` | `0x510` | table replacement |
| `0x21` | `0x540` | specialization |
| `0x24/0x2A` | `0x510` | distinct table replacements |
| `0x2B` | `0x520` | specialization |
| `0x38` | `0x520` | shared constructor, final table replacement |
| `0x3F` | `0x530` | specialization |

Annotations preserve the 14 final tables and shared/overriding attack/reason
methods. Final means present during virtual initialization; shared intermediate
tables can be replaced.
[Support variants](../characters/support_mechanics.md#factory-variants-and-attack-completion)
owns behavior.

Slot publication precedes virtual initialization, enable bits and generation.
The generation snapshot includes the new object's constructor-cleared zero.
Only after generation assignment does cumulative count increment.
No alternate slot/rollback is retained. Constructors guard allocation but
converged publication immediately dereferences it; null is not a clean failure.

Generation candidate starts 1/reuse clear. Pre-wrap return/increment;
`0xFFFFFFFF` sets reuse, resets zero and common increment leaves 1.
Post-wrap compares unchanged candidate against both slot generations (empty 0),
rescans that same candidate up to count plus one, then returns zero on collision.
It searches no alternate free ID; either outcome increments once.

Zero can be published while creation still succeeds, so post-wrap uniqueness
is not unconditional. Battle initialization resets 1/clear.
Generation differs from side, transient serial and counters; audited
request/gauge/terminal/slot gates do not inspect it.

Factory side comparisons do not branch. Invalid indexing precedes a late
zero-address assertion; neither factory nor wrapper safely validates side.
Resident `control_flags & 1` is the observed safety boundary.

### Support-object common prefix and removal

`SupportObject` extends generic node with selector, side, lifecycle and
generation. Archive/five animations are borrowed; player, two other handles
and five children are owned. Initialization releases previous handles before
replacement; their allocations are `0x120/0xA0/0x50`.

Destruction releases/nulls handles and virtual-destroys/nulls children, tears
down embedded owners with six/three/one `0x50`-stride elements, releases/
reinitializes the managed object, destroys the base and optionally frees.

The animation format is `ANM_p%s%s%d`, suffix order `ent/nut/run/act/ext`.
Archive/name lookup returns existing payloads without allocation, reference
increment or ownership transfer; missing required names assert. Archive must
remain loaded. Destruction frees player, not borrowed payloads.
Bounded family writes are constructor clears/initializer lookups; computed
writes outside it are not excluded.

Slot writers are constructor clear, factory publication, enabled main-pass
lifecycle-2 destroy/clear and explicit destruction. Owner teardown removes both;
battle reset can retain the owner.

Bits 1/2 are callback enables, not membership. Main pass rewrites them;
disable clears them but retains slots. Lifecycle-2 destruction requires bit 1,
so disabled objects retain slots until later enabled processing/teardown.
Teardown ignores enables; presence/lookup continue to find occupied objects.
[Support lifecycle](../characters/support_mechanics.md#scheduled-lifecycle-and-teardown)
owns scheduling/predicates.

### Non-owning support lineage on transient actors

`support_spawn_transient` and `support_spawn_transient_scatter` create independent actors, copy support
generation into `Projectile.support_identifier` and set `support_notify`.
Reset clears both; source-actor creation copies them to descendants.

The notification resolves opposite side and submits the token to
`support_lineage_consume`, never finding its originating support. Deduplication may
set lineage bit 0 on whichever support now occupies the side slot.
No support pointer can dangle after replacement; managers retain independent
lifetimes. [Support counters](../characters/support_mechanics.md#support-counters-and-notification-suppression)
owns acceptance/ring behavior.

## BTL skill actors

`skill_actor_factory` creates traced skill actors. Authored route
`interaction_primary_register_call` registers returned actors by fighter side and binds resources
when nonnull. [Battle auxiliary services](battle_auxiliary_services.md#btl-skill-service-callbacks-and-ownership)
owns `ccSkillCtrl`, separate from hub primary and transient/support ownership.

### `ccSkillHNW001` skill actor

[Combo accounting](../combat/combo_accounting.md#repeated-event-contribution-in-ccskillhnw001)
owns pending contribution/gates; [Collision](../combat/collision.md#ccskillhnw001-interaction-records-and-accepted-event-route)
owns borrowed records/accepted events.

#### Class and retail action identity

RTTI identifies `ccSkillHNW001`. Numeric domains are distinct:

| Domain | Retail value |
| --- | --- |
| character | ID 80, `２部ヒナタ`, body `2hnwbod1.ccs` |
| action | index 3 of `0x34` records |
| owner/selector | `0x00A10050`: owner 80, selector 161 |
| display | **守護八卦六十四掌** |
| resource/factory | selector 161 → index 165 |
| resource | `2hnwcha1.ccs` |

Shift-JIS reading markup is
`<r守護八卦六十四掌|しゅごはっけろくじゅうよんしょう>`.
Common binding borrows the required container and retains index.
[Character assets](../../game/character_assets.md#selector-to-resource-mapping)
owns the wider map/record contracts.

#### Factory admission and authored creation

Factory admits unsigned indices < `0xC5`. HNW `0xA5` allocates `0x1180`,
constructs base/two pairs of `0x50` records, initializes its independent
reference/local state and installs HNW table; null skips construction.

Gzip `PL/2HNWCHA1.CCS` record 70, `ANM_phnwcha10`, has exactly one nested
tag-`0x0108` event after integer marker 1: record 69
(`OBJ_eff_dummy_hnwcha1`), `0x8003`, `0x1A5`. Complete nested blocks
of `ANM_phnwcha11a/11b/11c/12/1eff` have none; collision callbacks remain
possible. [Animation event delivery](../../runtime/animation_runtime.md#packed-command-crossing-and-event-delivery)
owns queue/marker crossing.

The fighter callback reaches `skill_authored_event_bridge`: `SkillSpawnEvent.event_word == 0x8003`
and unsigned `authored_selector` in `0x100..0x1C4` select spawn after subtracting `0x100`, so
`0x1A5` selects `0xA5`. It uses fighter, paired opponent and masked side.
An authored marker is a stream position, not measured delay after input.

#### Local state machine

Changing state resets `SkillHnw001.call_counter`; setter/update tables have
six entries.

| State | Entry | Update |
| ---: | --- | --- |
| 0 | activation after display reset | counter 5 enables `input_enabled` and input-event byte 0 |
| 1 | shared animation/child prep with 2 | clear positive `pending_hit_count` and `local_hit_count` |
| 2 | accepted event requests only if old state < 2 | counting; old `counting_counter` 16/40 thresholds select record `+0x30/+0x32` or 3 |
| 3 | disable records, mask argument 1 | counter >= 10 requests 4 |
| 4 | mask 0, disable records, `finish_requested = 1` | `finish_event == 1` requests 5 |
| 5 | finish animation, valid child retirement, input/records disabled | finish flags retained |

Accepted event concretely produces counting-state entry. Exact-offset screening
of finish-event/request fields finds initialization, activation, receiver,
respective state use and contribution helper; indexed/other aliases are outside
that bound. [Combo masks](../combat/combo_accounting.md#request-mask-producers-and-retained-values)
owns bank requests.

#### Resource retention and cleanup

Five retained animation resources differ from two constructed registered
children/generation-checked references. Cleanup destroys/nulls owned player.
Child retirement requires index 0..31 and matching serial **and** pointer in
either bank before the retirement callback; it is not unchecked-pointer free.
Independent reference is resolved before cleanup. Destructor tears down record
pairs/base and optionally frees for positive flag; full subordinate/base
lifetimes remain unproved.

### BTL skill classes on damage paths

RTTI names are internal types, not player-facing moves.
[Damage](../combat/damage.md#all-fifteen-btl-source-retaining-calls) owns arithmetic.

#### Shared-float caller classes

| Helper | Classes | Inheritance |
| --- | --- | --- |
| `skill_shared_float_damage_a` | `ccSkillNRW001/ccSkillNRT001B` | NRW derives from NRT, installs own table, sets byte `+0x1170 = 1` |
| `skill_shared_float_damage_b` | `ccSkillNRV001/ccSkillJRW001` | JRW derives from NRV and installs own table |

Each pair shares its calling method. Helper A also has
`skill_nrt_nrw_update` (`0x0079DFE0`) as a direct caller. Helper B's other
direct caller is `skill_nrv_jrw_interaction_update` (`0x007D11F0`).
The NRV-derived `ccSkillFOU001` installs `skill_fou001_vtable`
(`0x005F15F0`); `skill_fou001_update` (`0x007DC1D0`) delegates to
`skill_nrv_jrw_damage` outside local states 5/6. One helper therefore does
not identify one class.

##### Retail action and resource joins

All rows below are shipped action 3, category `0x00080000`. Owner/selector
words and Shift-JIS display names come from the resident `ActionRecord`;
[Character assets](../../game/character_assets.md#selector-to-resource-mapping)
owns the selector/resource domains. Factory indices below are the resource
indices, read through `skill_factory_table` (`0x008CD1F0`).
These are metadata owners; configured Jutsu selection can replace another
fighter's working action/animation rows
([Working action arrays](../combat/action_commands.md#working-action-arrays)).

| Metadata owner / move | Named action record | Selector / resource | Factory arm / concrete class | CCS |
| --- | --- | --- | --- | --- |
| 1, Naruto Uzumaki (Classic), `螺旋丸` (Rasengan) | `naruto_classic_rasengan_record` `0x0040CC9C` | 3 / 1 | `skill_factory_nrt001b` `0x00773CF4`, `ccSkillNRT001B` | `2nrtcha1.ccs` |
| 47, Naruto Uzumaki (Nine-Tailed), `朱い螺旋丸` | `naruto_nine_tailed_rasengan_record` `0x004A5A0C` | 95 / 113 | `skill_factory_nrv001_113` `0x007746A0`, `ccSkillNRV001` | `2nrvcha1.ccs` |
| 57, Naruto Uzumaki, Great Ball Rasengan (`大玉螺旋丸`) | `jutsu_great_ball_rasengan_record` `0x004D9E4C` | 115 / 117 | `skill_factory_nrw001` `0x00774938`, `ccSkillNRW001` | `2nrwcha1.ccs` |
| 83, Jiraiya, `螺旋丸` (Rasengan) | `jiraiya_rasengan_record` `0x005691AC` | 167 / 171 | `skill_factory_jrw001` `0x0077592C`, `ccSkillJRW001` | `2jrwcha1.ccs` |
| 39, The Yellow Flash, `螺旋丸` (Rasengan) | `yellow_flash_rasengan_record` `0x0048683C` | 79 / 107 | `skill_factory_fou001` `0x007748E8`, `ccSkillFOU001` | `2foucha1.ccs` |

Factory arms allocate `0x1180` for NRT/NRW, `0x1190` for NRV/JRW,
and `0x11A0` for FOU, then construct only on nonnull allocation. MCP
`get_code(skill_actor_factory)` omits its switch arms; the joins use MCP
table data and each arm's 40 raw bytes, rather than preserved exports.
NRV also has `skill_factory_nrv001_28` (`0x00774500`), resource 28
`2jrycha1.ccs`, selector 43/owner 21. NA2 owner 21 is a filler definition,
has no character asset entry, and this CCS is absent from the NA2 extraction
([Character IDs](../characters/character_ids.md#character-definition-table));
that retained factory arm does not establish a playable classic Jiraiya move.

Read-only gzip-memory walks of the five retail `PL/` files reached the declared
end of every nested animation block (17/12/15/12/16 respectively). Each file
has exactly one tag-`0x0108` command, after integer marker 1:

| CCS | Animation record / name | Target record / name | Event words | Decompressed offset |
| --- | --- | --- | --- | ---: |
| `2NRTCHA1.CCS` | 197 / `ANM_pnrtcha10` | 196 / `OBJ_eff_dummy_nrtcha1` | `0x8003 / 0x101` | `0xCD00` |
| `2NRVCHA1.CCS` | 123 / `ANM_pnrvcha10` | 122 / `OBJ_eff_dummy_nrvcha1` | `0x8003 / 0x171` | `0x78A0` |
| `2NRWCHA1.CCS` | 186 / `ANM_pnrwcha10` | 57 / `OBJ_eff_dummy_nrwcha1` | `0x8003 / 0x175` | `0xB63C` |
| `2JRWCHA1.CCS` | 125 / `ANM_pjrwcha10` | 124 / `OBJ_eff_dummy_jrycha1` | `0x8003 / 0x1AB` | `0x7690` |
| `2FOUCHA1.CCS` | 145 / `ANM_pfoucha10` | 144 / `OBJ_eff_dummy_foucha1` | `0x8003 / 0x16B` | `0x9898` |

`skill_authored_event_bridge` subtracts `0x100` and supplies the spawning
fighter and its opponent to `interaction_primary_register_call`, joining
these commands to their factory/resource indices. A stream marker does not
establish a measured delay after input. Command delivery belongs to
[Animation runtime](../../runtime/animation_runtime.md#packed-command-crossing-and-event-delivery).

##### Shared input-source availability

`skill_input_events_initialize` (`0x00796800`), called by base construction,
clears source `+0x144`, four halfwords `+0x148..+0x14E` and enable byte
`+0x150`. NRT sets its input-source flag `+0x1170` to zero; NRW sets it to
one. NRV sets `+0x1134` to zero; JRW sets it to one; FOU leaves it zero.
`skill_nrt_nrw_control_dispatch` (`0x007A14A0`) and
`skill_nrv_family_control_dispatch` (`0x007D2CF0`), each at control slot
`+0x208`, allocate/enable the source and clear its counts only with the
corresponding flag nonzero. Their paired interaction-update paths use the
same flags before creating a missing source.

**Observation:** These joined source-preparation routes admit NRW and JRW.
Base NRT/NRV and FOU method reuse does not admit their source/count gate.
Bounded constructor, method and direct-offset inspection does not rule out
arbitrary aliased writes or indirect external preparation. Input counts,
optional raw damage and tier ordering belong to
[Shared-float damage](../combat/damage.md#shared-float-event-count-and-categories).

#### Inherited primary-record caller classes

`skill_primary_submit_record` (`0x00789630`) is the base interface
`+0x194`; `ccSkillComboBase` installs
`skill_combo_submit_record` (`0x007984A0`) at that slot. The latter
prepares participant transforms, calls the inherited routine, then restores
the source transform. A shared method does not identify one concrete class.

A complete MCP read of all 197 descriptor counts/pointers and their counted
`0x44`-byte definitions finds the 21 response-`0x28` entries below.
Counts start at `0x008AD8E0 + resource * 8`; pointers start four bytes later.
The factory arms were read through `skill_factory_table`, constructors were
decompiled, and final tables/RTTI were read through MCP. Every listed final
table retains `skill_combo_submit_record` at `+0x194`.
The resident first-four-action census covers all 78 distinct selected
character records; only named action 1/3 metadata is shown.

| Resource / CCS | Concrete class / final table | Metadata owner / action / selector | Shipped display / action record | Response-28 definition index / address |
| --- | --- | --- | --- | --- |
| 6 / `2garcha0.ccs` | `ccSkillGAR000A` / `0x005FA4C0` | 4 (`我愛羅`) / 1 / 8 | `砂瀑送葬` / `0x0041CBB4` | 0 / `0x008A84F0` |
| 13 / `2zbzcha1.ccs` | `ccSkillZBZ001B` / `0x005FA740` | 11 (`再不斬`) / 3 / 23 | `鬼來` / `0x0043724C` | 0 / `0x008A87DC` |
| 17 / `2hakcha1.ccs` | `ccSkillHAK001B` / `0x005F9580` | 10 (`白`) / 3 / 21 | `魔鏡薄氷` / `0x00431C8C` | 0 / `0x008A88EC` |
| 23 / `2orccha1.ccs` | `ccSkillORO001` / `0x005F8C10` | No selected record | — | 0 / `0x008A8C1C` |
| 35 / `2tencha0.ccs` | `ccSkillTEN000B` / `0x005F1370` | 13 (`テンテン`) / 1 / 26 | `双燕刈` / `0x00441534` | 0 / `0x008A9348` |
| 63 / `2tyycha0.ccs` | `ccSkillTYY000B` / `0x005F58D0` | 36 (`多由也`) / 1 / 72 | `幻武操曲　絆狂` / `0x00475F84` | 0 / `0x008A9EF8` |
| 82 / `2seccha0.ccs` | `ccSkillSEC000` / `0x005F29A0` | 43 (`二代目`) / 1 / 86 | `黒暗行の術` / `0x0049AA74` | 0 / `0x008AA59C` |
| 98 / `2kdvcha0.ccs` | `ccSkillKDV000` / `0x005F6950` | 53 (`鬼童丸状態２`) / 1 / 106 | `天蜘蛛縛り` / `0x004C50D4` | 0 / `0x008AAB74` |
| 104 / `2skvcha0.ccs` | `ccSkillSKV000` / `0x005F5180` | 55 (`左近状態２`) / 1 / 110 | `双極落天` / `0x004CEDD4` | 0 / `0x008AADD8` |
| 106 / `2foucha0.ccs` | `ccSkillFOU000` / `0x005F1840` | 39 (`黄色い閃光`) / 1 / 78 | `瞬光` / `0x00486794` | 0 / `0x008AAE60` |
| 124 / `2tmwcha0.ccs` | `ccSkillTMW000` / `0x005EE3D0` | 61 (`テマリ`) / 1 / 122 | `斬り斬り舞` / `0x004EFB14` | 0 / `0x008ABADC` |
| 126 / `2chycha0.ccs` | `ccSkillCHY000` / `0x005EF5D0` | 62 (`チヨバア`) / 1 / 124 | `二親按包` / `0x004F5D74` | 0 / `0x008ABB64` |
| 132 / `2newcha0.ccs` | `ccSkillNEW000` / `0x005EF0C0` | 65 (`ネジ`) / 1 / 130 | `八卦掌回天` / `0x00506C44` | 1 / `0x008ABD84` |
| 136 / `2rowcha0.ccs` | `ccSkillROW000` / `0x005F09A0` | 67 (`リー`) / 1 / 134 | `表蓮華` / `0x00512EC4` | 0 / `0x008ABF60` |
| 138 / `2siwcha0.ccs` | `ccSkillSIW000` / `0x005F0250` | 68 (`シカマル`) / 1 / 136 | `影真似の術` / `0x00518AA4` | 0 / `0x008AC070` |
| 144 / `2itwcha0.ccs` | `ccSkillITW000` / `0x005EF350` | 71 (`イタチ`) / 1 / 142 | `幻術　不知火` / `0x0052A1F4` | 0 / `0x008AC428` |
| 174 / `2szwcha0.ccs` | `ccSkillComboBase` / `0x005FB240` | 85 (`シズネ`) / 1 / 170 | `仕込み千本・刺散` / `0x00574264` | 0 / `0x008AD170` |
| 186 / `2ymtcha0.ccs` | `ccSkillComboBase` / `0x005FB240` | 91 (`ヤマト`) / 1 / 182 | `木遁・完拿` / `0x0058F424` | 0 / `0x008AD56C` |
| 190 / `2sswcha0.ccs` | `ccSkillComboBase` / `0x005FB240` | 93 (`２部サスケ`) / 1 / 186 | `刹那` / `0x0059ADC4` | 0 / `0x008AD67C` |
| 195 / `2bdycha3.ccs` | `ccSkillJRWxTNW` / `0x005E4CB0` | 30 (auxiliary) / 3 / 61 | `伝説の片鱗` / `0x0059D6DC` | 0 / `0x008AD858` |
| 196 / `2bdycha4.ccs` | `ccSkillSAIxNRW` / `0x005E3130` | 31 (auxiliary) / 1 / 62 | `喧乱・超獣偽画絵巻` / `0x0059DE04` | 0 / `0x008AD89C` |

Action 1 metadata has category `0x00040000`; action 3 has
`0x00080000`. All twenty joined named records contain raw damage
`0.125`, repeat 1. Owner IDs 30/31 are auxiliary metadata records with empty
fighter names and no dedicated fighter; their class names do not establish
ordinary selectable characters. Resource 23 is the retained `2orccha1.ccs`
arm; ID 9 is a filler definition, so the selected-record census supplies no
classic Orochimaru action join
([Character IDs](../characters/character_ids.md#character-definition-table)).

Resources 174/186/190 allocate `0x1110` and construct `ccSkillComboBase`
directly, without a further class-table replacement in their arms.
The other constructors install the concrete tables shown.
[Damage](../combat/damage.md#inherited-primary-record-categories-and-tier)
owns authored scalar/repeat values, explicit amounts and contribution ordering.

#### Specialized source-retaining caller classes

These five originating actions are named action 1, category `0x00040000`,
`ActionRecord.damage` `0.125`, repeat 1. Each owner/selector comes from its resident
`ActionRecord`, with the common selector/resource join.

| Originating metadata owner / display | Action record | Selector / resource / CCS | Concrete primary / final table | Explicit-damage owner |
| --- | --- | --- | --- | --- |
| 22, Third Hokage, `火遁・火龍炎弾` | `third_hokage_fire_dragon_record` `0x004671B4` | 44 / 47 / `2hkgcha0.ccs` | `ccSkillHKG000` / `0x005F8560` | Two independently allocated floor-fire child classes below |
| 2, Sasuke (Classic), `無双豪炎弾` | `sasuke_classic_musou_gouendan_record` `0x00412314` | 4 / 2 / `2sskcha0.ccs` | `ccSkillSSK000A` / `0x005F6E50` | `downed_override_b`, slot `+0x24C` |
| 48, Second Stage Sasuke Uchiha, `無双豪風陣` | `sasuke_second_stage_musou_goufujin_record` `0x004AB454` | 96 / 88 / `2ssvcha0.ccs` | `ccSkillSSV000` / `0x005F3D70` | `downed_override_e`, slot `+0x24C` |
| 38, Kimimaro, `茨` | `kimimaro_ibara_record` `0x00480C64` | 76 / 72 / `2kmmcha0.ccs` | `ccSkillKMM000` / `0x005F4990` | `skill_contact_flush`, slot `+0x24C` |
| 13, Tenten (Classic), `双燕刈` | `tenten_classic_soenka_record` `0x00441534` | 26 / 35 / `2tencha0.ccs` | `ccSkillTEN000B` / `0x005F1370` | `skill_delayed_flush`, slot `+0x260`; `+0x24C` is a no-op |

Factory resources 2/88/72/35 allocate `0x1120/0x1110/0x1110/0x1110`
respectively and call their concrete constructors only on nonnull allocation.
HKG resource 47 allocates `0x1400` through `skill_factory_hkg000`
(`0x00774314`). Its `skill_hkg000_update` (`0x007B1F00`) creates
`ccSkillHKG000FireGen` (`0xE10`, table `0x005F87B0`).
`skill_hkg000_spawn_floor_fire` (`0x007B1780`) creates
`ccSkillHKG000FloorFire` (`0xBF0`, table `0x005F88F0`);
`skill_hkg000_spawn_floor_fire2` (`0x007B1A40`) creates
`ccSkillHKG000FloorFire2` (`0xB90`, table `0x005F8850`).
Their explicit-damage helpers are `skill_two_route_flush` and
`skill_route_flush`, rather than primary HKG methods.

The first child uses `skill_two_route_contact_update` at auxiliary slot
`+0x30`; the second uses `skill_route_timed_contact_update` at slot
`+0x18`. Both retain their originating resource/side and a snapshot of the
linked fighter's current-record damage taken when FireGen is created.
The second child's same-side guard subject differs from its linked
damage target. These joins establish a Jutsu lineage, not generic victim
guard/chip semantics.

`skill_primary_authored_event_relay` (`0x007966E0`) validates the primary
registry tuple before dispatching an authored event to slot `+0x13C`.
The SSK wrapper and inherited SSV/KMM/TEN implementations reach
`skill_combo_accepted_event`. Event 10 requests finish; other admitted
events contribute a manager pending word.
`skill_combo_phase3` clears the finish latch before slot `+0x24C`.
TEN instead uses `skill_combo_interaction_update` at `+0x11C`
(`+0x118` is a no-op), whose second-header/latch gate invokes `+0x260`.
[Damage](../combat/damage.md#specialized-skill-amounts-and-counted-tier)
owns count increments, raw boundaries and their attribution limits.

#### `ccSkillTYO000B`

Index 31 allocates `0x1110`, conditionally constructs this base-derived class
and installs `skill_tyo000b_vtable` (`0x005F9F20`). The native join is
Classic Choji (metadata owner 14), Jutsu action 1,
`choji_classic_donburi_throw_record` (`0x00446754`), **曇撫離投げ**.
Its owner/selector word is `0x001C000E`, category `0x00040000`, damage
`0.125`, repeat 1. Selector 28 maps to resource 31, `2tyocha0.ccs`, and
`skill_tyo000b_factory_arm` (`0x007745D8`). The move's name does not
identify an ordinary throw action.

A complete read-only gzip walk reached the declared ends of all six nested
animations in retail `PL/2TYOCHA0.CCS`. Startup record 68,
`ANM_ptyocha00`, has a tag-`0x0108` command at marker 1 targeting record 67,
`OBJ_eff_dummy_tyocha00`, with words `0x8003 / 0x11F`.
`skill_authored_event_bridge` selects resource 31 by subtracting `0x100`.
`skill_tyo000b_setup` (`0x007A50B0`) binds source names
`{null, ANM_ptyocha01, ANM_ptyocha03}` and target `ANM_ptyocha02`.
The internal animations contain further commands; their presence alone
does not establish new actors or accepted hits.

The class inherits `skill_combo_phase3` and `skill_combo_accepted_event`.
Its special slot `+0x1A0` is `skill_tyo000b_damage`.
[Damage](../combat/damage.md#known-class-source-categories-and-hit-tiers)
owns the sample producer and accepted-count ordering.

#### `ccSkillFIR000`

`skill_fir000_factory_arm` (`0x00774790`) allocates `0x1120` for
resource 80 and conditionally calls `skill_fir000_construct`
(`0x007D7710`). The constructor calls `skill_tyo_base_construct`, then
installs `fir000_vtable` (`0x005F2C20`). RTTI identifies `ccSkillFIR000`.

`first_hokage_shinra_bansho_record` (`0x00495824`) is The First Hokage's
(metadata owner 42) Jutsu action 1, **木遁・森羅万象**. It stores selector
84, category `0x00040000`, damage `0.125`, repeat 1. Selector 84 maps to
resource 80, `2fircha0.ccs`.

A complete read-only gzip walk reached the declared ends of all seven nested
animations in retail `PL/2FIRCHA0.CCS`. Startup record 90,
`ANM_pfircha00`, targets record 89, `OBJ_eff_dummy_fircha0`, at marker 1
with tag-`0x0108` words `0x8003 / 0x150`, selecting resource 80.
Main record 238, `ANM_pfircha01`, has only one such command: marker 115,
target record 237, `OBJ_eff_dummy_fircha01`, words `0x8003 / 10`.
It has no nonterminal authored count events; the other five animations
have no tag-`0x0108` commands.

Inherited `skill_combo_phase3` reaches `skill_auxiliary_flush`
(`0x007D7FB0`) through slot `+0x24C`; slot `+0x1A0` is
`skill_primary_accepted_callback_noop`. The authored finish marker does
not itself establish a hit count or elapsed time after input.
[Damage](../combat/damage.md#known-class-source-categories-and-hit-tiers)
owns the final amount and count attribution.

#### `ccSkillFOR000` allocation and lifetime

Index 22 allocates `0x1510`; this is its sole decoded direct constructor
route. Traced spawn creates/registers/binds a fresh allocation, calls class
setup and takes damage snapshot. It supplies no existing allocation for
reconstruction; other producers/later setup remain possible.

In the complete 188-word `skill_selector_resource_table`, resource 22 is
selected only by selector 18, nominal owner 9/action 1. Owner 9 is a
Naruto-ID-1 filler definition, and retail NA2's extracted `PL/` has no
`2ORCCHA0.CCS`. This retained class/factory/resource therefore supplies no
verified active NA2 character or move identity. The filename cannot establish
an Orochimaru move. [Filler definitions](../characters/character_ids.md#character-definition-table)
own the missing character metadata.

The class's authored-event slot `+0x13C` is
`skill_primary_event_callback_noop` (`0x007967D0`). Its accepted-damage
slot `+0x1A0`, `skill_for000_damage_entry` (`0x00805540`), enters damage
state 2 on the unguarded path. [Damage](../combat/damage.md#known-class-source-categories-and-hit-tiers)
owns count ordering and the separate primary/secondary amounts.

Destructor releases target link, validity-gated linked-fighter state,
interaction/effect children, restores base, removes primary registry entry
and optionally frees. It does not clear fighter `recovery_record`
(raw `+0x7CC`) or reset shared retained record/raw float; lifetimes differ.
[FOR players](../../runtime/scene_playback_owners_btl.md#btl-for-embedded-player-pair)
owns embedded players.

#### `ccSkillANB000` creation and destruction

Indices 3/11/53/89/143 use five arms, each fresh `0x13C0` of one class.
Setup selects a local name bank per selector and fills 17 resource pointers.
Shared retained record is outside the allocation.

The three current action joins are Jutsu action 3, category `0x00080000`,
authored damage `0.125` and repeat 1:

| Metadata owner / move | Named action record | Selector / resource | CCS |
| --- | --- | --- | --- |
| 2, Sasuke Uchiha (Classic), **千鳥** (Chidori) | `sasuke_classic_chidori_record` `0x004123BC` | 5 / 3 | `2sskcha1.ccs` |
| 48, Second Stage Sasuke Uchiha, **黒い千鳥** (Black Chidori) | `sasuke_second_stage_black_chidori_record` `0x004AB4FC` | 97 / 89 | `2ssvcha1.ccs` |
| 70, Kakashi Hatake, **雷切** (Lightning Blade) | `jutsu_lightning_blade_record` `0x00524CEC` | 141 / 143 | `2kkwcha1.ccs` |

Read-only gzip walks reached the declared end of every directory animation's
nested command block: 14 in SSK, 16 in SSV and 13 in KKW. Each has exactly
one tag-`0x0108` command, in its startup animation at integer marker 1:

| CCS | Animation record / name | Target record / name | Event words |
| --- | --- | --- | --- |
| `2SSKCHA1.CCS` | 160 / `ANM_psskcha10` | 159 / `OBJ_eff_dummy_sskcha1` | `0x8003 / 0x103` |
| `2SSVCHA1.CCS` | 192 / `ANM_pssvcha10` | 191 / `OBJ_eff_dummy_ssvcha1` | `0x8003 / 0x159` |
| `2KKWCHA1.CCS` | 89 / `ANM_pkkwcha10` | 37 / `OBJ_skl_266` | `0x8003 / 0x18F` |

`skill_authored_event_bridge` subtracts `0x100`, selecting resources
3/89/143 and the three joined ANB factory arms. These nested-block walks
do not establish complete outer-file consumption or actual contact admission.

Resource 11 has only selector 17, nominal owner 8/action 3; owner 8 is a
Naruto-ID-1 filler definition. Resource 53 is absent from all 188 selector
words. Retail NA2's extracted `PL/` contains neither `2KKSCHA1.CCS` nor
`2ANBCHA0.CCS`. Those two retained factory arms do not establish playable
Classic Kakashi or Anbu moves. Resource indices, Jutsu selectors and
character IDs are separate domains
([Character assets](../../game/character_assets.md#selector-to-resource-mapping)).

The class overrides authored-event slot `+0x13C` with
`skill_anb000_accepted_event_noop` (`0x0080BAB0`); accepted-damage slot
`+0x1A0` is `skill_anb000_damage`. Configured Jutsu selection can copy
the joined working records to another fighter; metadata owner is not a
restriction on the performer
([Working actions](../combat/action_commands.md#working-action-arrays)).

Destruction releases both side/target links, restores activity, removes two
interaction lists/effect children, restores base/removes primary entry and
optionally frees. Selector 143 also restores local timeline/linked fighter.
It does not reset shared record/raw float or clear fighter `recovery_record`.
Expiry of all later fighter aliases and whole-game reuse remain unproved.
[ANB players](../../runtime/scene_playback_owners_btl.md#btl-anb-embedded-and-associated-players)
owns associated players; Damage owns multipliers.

## Lookup and identity contract matrix

| API | Namespace/filter | Absent/invalid |
| --- | --- | --- |
| `primary_fighter_get` | direct borrowed primary side, no flags | null outside 0/1 |
| `input_object_get_by_side` | last linked full-word input side, no flags | null |
| `battle_find_primary_fighter` | last linked primary low-side-bit, no flags | null |
| `camera_registry_find_key` | last camera key, current ignored | null |
| `camera_registry_find_current` | last camera key/current bit | null |
| `battle_find_current_camera` | current camera key, requested bit 1 | null |
| `transient_actor_find_serial` | first reachable serial, no separate flags | null without manager/match |
| `transient_actor_next` | next type/inverted side after cursor, head for null cursor | null exhausted |
| `transient_actor_exists/transient_actor_count` | same predicate, existence/count | zero |
| `support_present` | support side-slot occupancy, no flags/lifecycle | zero without owner; side unchecked |
| `support_get` | exact support slot pointer, no flags/lifecycle | null without owner; side unchecked |

No public support-generation-to-originating-object lookup is decoded.
Descendants copy lineage while object consumers resolve current side slot.
Borrowed pointers, actor serials, support generations and cumulative counters
are not interchangeable.

## Annotation map

### Resident ELF

`@annotations/NA2/SLPS_258.37/symbols.tsv` owns names/prototypes/comments,
factory/vtable lifetime joins, skill class tables and data.
`@annotations/NA2/types.h` owns fixed layouts.

### BTL annotations

`@annotations/NA2/BTL.BIN/symbols.tsv` owns live hub, registry, transient,
support and skill routines, descriptor/selector tables, RTTI and resources.
Local gates/constants/returns/cleanup live in routine comments; this document
owns cross-routine relationships.

## Negative results

Reserved entries are zero slots, input aliases control objects, primary aliases
borrowed and coordinator selector scalar. Support configuration does not
pre-create objects; two support slots belong to neither hub nor transient owner.
Copied lineage has no parent pointer. Callback bits do not establish occupancy,
generic bit 1 is not removal, and a transient next pointer is not membership.
Borrowed graph links are not ownership, and last camera key is not necessarily
the current node.
