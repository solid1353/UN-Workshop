# Battle-session and stage lifecycle

## Research coverage

Established: retail NA2 (`SLPS-25837`) session construction and ownership,
three-phase dispatch, stage binding, root cleanup, continuation rebuilds and
their retained values. Open: original names of non-polymorphic root children,
elapsed timing under stalls, character tails beyond six examples, indirect
statistics copies and a whole-graph field census.

Routines, fields and data use names from `@annotations/NA2`; routine comments
hold code-level detail and bounded searches. Addresses are live. Evidence is
static; shared virtual entries do not establish every downstream meaning.

This document owns structural lifecycle and ordering. Related owners cover
[masks and pause](pause_and_replay.md), [outcomes and timer](match_outcomes.md),
[HUD](battle_hud.md), [audio and guide](battle_audio.md),
[auxiliary services](battle_auxiliary_services.md), [entities](battle_entities.md),
[stages](../stages/stages.md), [character resources](../../game/character_assets.md),
[items and effects](../projectiles_and_items/battle_items_and_status_effects.md),
[inventory](../projectiles_and_items/battle_item_inventory.md),
[awakening](../characters/awakening.md), [collision](../combat/collision.md),
[combat execution](../combat/combat_action_execution.md),
[combo accounting](../combat/combo_accounting.md),
[puppets](../characters/puppet_control.md), [scene playback](../../runtime/scene_playback_owners.md)
and [render submission](../../runtime/rendering/render_submission.md).

## Battle update cadence

The ordinary front-end loop consumes two VBlank-start counts per manager
cycle. One eligible iteration selects one battle-process callback; one active
battle-service invocation runs each phase-1 registry callback at most once.
At a nominal 60 Hz interrupt rate this gives 30 battle-service iterations per
second. It establishes counts and ordering, not measured elapsed timing or a
new battle image on every display refresh.

The three graph phases are ordered parts of one service call. Camera,
fighters and stage share that cadence subject to their masks. A delayed or
gated task can miss an opportunity; work lasting beyond two interrupts can
delay the next pass. The same threshold drives tick-counted vibration.
See [task pacing](../../runtime/task_system.md#root-pacing-and-the-engine-gate),
[front-end ordering](../../runtime/overlay_abi.md#front-end-thread-ordering-and-its-limit)
and [controller scheduling](../../runtime/controller_input.md#vibration-and-actuator-scheduling).

## Address map

The session-root accessor, graph lifecycle entries, registry walks and stage
callbacks are named in `@annotations/NA2/BTL.BIN`; resident entrypoints are
named in `@annotations/NA2/SLPS_258.37`. All addresses are live, with resident
routines retaining ELF virtual addresses. The retail overlay's internal name
is `BTL_product.bin`; [File identities](../../game/files/file_identities.md#address-conventions)
owns its address mapping. [Stages](../stages/stages.md#address-index) owns
stage and background behavior.

## Resident setup order

The resident battle process published in `btl_process` is dispatched by
`manager_dispatch_state`; `battle_driver_setup` selects BTL synchronously before state 1.
Its handoff and return contract belongs to
[Mode flow](../../game/mode_flow.md#btl-handoff-and-return).

| State | Handler | Established work |
| ---: | --- | --- |
| 1 | `battle_state_prepare_entry` | Entry type 2 queues absent `prac.ccs` and starts a loader fence. |
| 2 | `practice_driver_reset_settings` | Waits for the fence and initializes manager battle fields and timer work. |
| 3 | `practice_driver_reset_snapshots` | Resets the timer with limit 99 and clears both inventory caches. |
| 4, 5 | `battle_state_queue_selection_archives`, `battle_state_adopt_selection_archives` | Queue, then adopt, `charsel1.ccs`, `mapsel1.ccs` and `setting.ccs`. |
| 6..9 | [Mode flow](../../game/mode_flow.md), [Stages](../stages/stages.md#archive-preload-adoption-and-switching) | Character Select then stage selection; state 9 publishes the raw active stage slot. |
| 10 | `battle_state_preload` | Releases selection archives, snapshots the manager and queues battle resources. |
| 11, 12 | [Stages](../stages/stages.md#archive-preload-adoption-and-switching) | Wait for loading and readiness gates. |
| 13 | `battle_state_create_fighters` | Adopts both fighters' resources, the skill archive bank and selected stage archive. |
| 14 | `battle_state_enter` | Both resident gates ready: construct the session, initialize support and enter `0x0F`. |

`battle_load_ccs(1)` is the battle resource queue point. It queues absent
`cmn/2cmnbod1.ccs`, `pl/1cmnbod1.ccs`, `modename/mode1cmn.ccs` and
`battlegauge.ccs`, then the skill bundle, selected stage, both fighters'
resource masks `0x1FF` and the stage-associated archive; one loader fence
covers the queue. The stage-specific inputs are the manager's raw active
slot, `stage_archive_paths` and `stage_rash_archive_path`.

## Session construction

`battle_state_allocate` requires an existing manager and an empty `battle_session`.
It prepares session admission, recognizes Unlimited time (setting 6 equals
100) through bit `0x02` of `battle_countdown.flags`, and clears the result bank
except when `battle_continuation_phase == 2`.
It allocates the `0x38`-byte `BattleState`, initializes and publishes it,
then invokes `battle_create_graph`. Entry type 2 also creates the `0xA8`-byte
[guide owner](battle_audio.md#guide-allocation-publication-and-dispatch).

Construction order is fixed:

1. Bind controls and prepare resident scene, query and auxiliary systems.
2. If `BattleState.hub` is absent, allocate the `0x10`-byte `BattleHub`,
   publish it as `battle_hub` and build it, publish both input and fighter aliases in
   `BattleManager`, and borrow its main camera as `camera_root`.
   Input history capacity is fixed during this graph build from the current
   pacing threshold ([Action commands](../combat/action_commands.md#battle-input-object-and-history)).
3. Always broadcast node start.
4. Create and publish `camera_controller`.
5. Create the `0xC8`-byte resident `item_manager`.
6. Create the transient-actor manager, reset fighter overrides, prepare the
   published auxiliary systems, then cache selected attachment models.
7. In continuation phase 2, restore retained values.
8. Create the two `0x68`-byte `top_panels`.
9. Create the `0x44`-byte `clock`, `0x70`-byte `presentation_root` and
   `0xC`-byte `auxiliary` child.
10. Prepare character-pair resources from both character IDs.
11. Create an absent `0x6C0`-byte pause controller, initialize it with both
    character IDs and the stage slot, copy side flags and refresh it.

Publication joins belong to
[Battle entities](battle_entities.md#battle-state-and-hub-publication);
camera publication to
[Battle camera](battle_camera.md#shared-controller-entry-points);
pause ownership to
[Pause and replay](pause_and_replay.md#shared-ownership-and-controller-lifecycle).

### Session fields

`BattleState` names the fixed layout.

| Fields | Ownership or contract |
| --- | --- |
| `first_phase_mask`, `second_phase_mask` | Allowed work rebuilt each update; [mask construction](pause_and_replay.md#controller-fields-and-mask-construction). |
| `first_phase_filter`, `second_phase_filter` | Session-local mask overrides. |
| `inner_state`, `inner_delay` | Inner end-sequence state and delay; [Match outcomes](match_outcomes.md#inner-end-sequence). |
| `entry_type` | Session entry type. |
| `camera_root` | Borrowed main `ccCamera01`. |
| `hub` | Owned graph and registries. |
| `camera_controller` | Owned controller, also published globally. |
| `item_manager` | Owned resident item manager. |
| `top_panels` | Owned per-side top HUD panels. |
| `clock` | Owned battle-clock display. |
| `presentation_root` | Owned BTL component forest. |
| `auxiliary` | Owned child with construction and teardown but no direct dispatcher update. |

[Battle HUD](battle_hud.md#battle-session-ownership-and-order) owns
presentation behavior and child update/draw semantics.

### Setup helpers after fighter publication

`battle_prepare_published_resources` prepares the existing interaction owner when present,
then calls `battle_auxiliary_prepare_resources` unconditionally. The latter prepares an existing
resident effect owner only when that owner exists. Neither path creates
another fighter or performs another fighter update.

The interaction preparation resets its embedded service and resource banks,
then preallocates missing descriptor resources from the two published
fighters and a character-specific row. Complete allocation-descriptor
semantics remain outside this document.

The resident preparation orders seven archive/animation lookups selected from
both fighter IDs, resolution of two registered resource lists, then resolution
of available entries of a 20-pointer static table. Their ownership and RTTI
joins belong to [Battle auxiliary services](battle_auxiliary_services.md).

`battle_cache_attachment_models` separately clears `attachment_model_cache` and scans every matching
`AttachmentModelRow` in `attachment_model_rows`, side 0 before side 1.
It uses `character_id`, `model_name` and `archive_path`; it ignores
`attachment_name`. The complete nine-row cache is:

| Row | Character ID | Archive | Model |
| ---: | ---: | --- | --- |
| 0 | `0x03` | `2rocbod1.ccs` | `MDL_2roc00t0 hair1` |
| 1 | `0x03` | `2rocbod1.ccs` | `MDL_2roc00t0 hair2` |
| 2 | `0x0A` | `2hakbod1.ccs` | `MDL_2hak00t0 mask` |
| 3 | `0x0A` | `2hakbod1.ccs` | `MDL_2hak00t0 sen0` |
| 4 | `0x1C` | `2kbtbod1.ccs` | `MDL_2kbt00t0 glas` |
| 5 | `0x43` | `2rowbod1.ccs` | `MDL_2row00t0 hair1` |
| 6 | `0x43` | `2rowbod1.ccs` | `MDL_2row00t0 hair2` |
| 7 | `0x45` | `2guwbod1.ccs` | `MDL_2guw00t0 hair1` |
| 8 | `0x45` | `2guwbod1.ccs` | `MDL_2guw00t0 hair2` |

The archive must resolve before model lookup. Each result occupies its row's
cache slot; if both fighters match, side 1 overwrites that slot.
The helper does not null-check the manager or fighters, so graph publication
must precede it. These are borrowed model resources; asset identities belong
to [Character assets](../../game/character_assets.md).

## Graph registries and node contract

`BattleHub` owns four registries. Resident vtables and RTTI establish their
retail identities:

| Hub field | Registry | Nodes |
| --- | --- | --- |
| `camera` | `ccCameraCtrl` (`cc_camera_ctrl_vtable`) | `ccCamera01` (`camera_main_vtable`); later `ccDummyCamera` and `ccPMCCamera`. |
| `input` | `ccCommandCtrl` (`cc_command_ctrl_vtable`) | One `ccCommand` per side (`cc_command_vtable`). |
| `fighters` | `ccPlayerCtrl` (`fighter_controller_vtable`) | Fighters; [Battle entities](battle_entities.md). |
| `field` | `ccFieldCtrl` (`cc_field_ctrl_vtable`) | `ccField` stage owner (`cc_field_vtable`). |

These are the camera, per-side control, fighter and shared-match registries
in [Battle entities](battle_entities.md). The main camera refers to both
fighters; each fighter refers to its opponent, input node and stage owner.

`GenericNode.vtable` uses the five named `NodeMethods` lifecycle slots:

| Method | Contract |
| --- | --- |
| `destroy` | Container destruction retires the node. |
| `start` | Run once by the post-build broadcast. |
| `update` | Phase 1; nonzero return unlinks and destroys the node. Node flag bit 0 does the same before the callback. |
| `second_phase` | Phase 2; the node decides its work. |
| `third_phase` | Phase 3; the node decides its work. |

Command and field registry thunks reach the generic walkers; the camera's
phase-1 wrapper reaches the same update/removal walk. Scoped camera classes
and the stage use an empty start callback, while `ccCommand` refreshes
bindings. The broadcast is a node-start hook, not a round reset.

## Per-update dispatch

While the inner battle is active, outer `0x0F` runs
`battle_loop_active`: mask construction, `battle_dispatch_phases`, timer work,
then terminal detection when the inner machine returns zero.
Services also run in the three opening substates: initialize the opening,
wait for its controller state to clear, then clear its opening bit and emit
event 8 when no result is latched.

The dispatcher orders:

1. Pause-controller pre-work, then camera-controller update, both skipped
   while `BattleManager.menu_state == 1`.
2. Apply pending fighter overrides.
3. Phase 1: camera, input, interaction auxiliary, fighters, support, stage,
   transient actors, resident auxiliary service, then pause post-work.
4. Reapply overrides, then phase 2 over the same consumers in the same order.
5. Reapply overrides, then phase 3 in the same order without transient actors.
6. Service the resident contest object, then item manager, both top panels,
   clock and presentation root through their separately masked callbacks.
7. Produce the final resident directional query results.

[Pause and replay](pause_and_replay.md#selective-update-gating) owns mask bits
and exceptions, including the contest object's first/second callback gates.

**Inference:** the camera controller and main camera compute from fighter
positions left by the preceding update, because both run before fighters
in phase 1.

### What phase 2 guarantees

Phase 2 is a dispatch boundary. Its generic node method does not establish
a second full fighter update or universal drawing behavior.

| Consumer | Established work |
| --- | --- |
| Camera registry | Four scoped camera classes have empty second-phase methods. |
| Input registry | `ccCommand` has an empty second-phase method; history work runs in phase 1. |
| Fighter registry | Generic node pass, gameplay-list secondary callbacks, optional presentation retirement, then registry auxiliary presentation. |
| Support registry | Under the battle view, each present side object runs its second-phase method only with node flag bit 2 set; prior view is restored. |
| Stage registry | Stage drawing; [Per-update stage work](#per-update-stage-work). |
| Interaction auxiliary | Embedded service installs presentation globals/views and runs subordinate virtual callbacks. |
| Transient manager | Active actors receive their presentation callback with argument 1 under the battle view, then the manager's child under the auxiliary view; its suppression byte can skip the pass. |
| Resident auxiliary | Under the auxiliary view, BTL presentation work precedes callbacks over up to `0x300` active resource slots and a registered list, with view restoration. |

All 74 table-selected concrete fighters share `fighter_render_slot`.
It requires node flag bit 2, submits the fighter model with auxiliary
bracketing, then runs embedded and character-specific presentation callbacks.
Shared entry does not make those downstream methods identical.

The fighter registry's additional gameplay-list pass follows its generic
node pass. It then visits fighters with an owned presentation chain and
a nonzero context marker before drawing its auxiliary presentation.
`fighter_presentation_retire` can decrement a presentation countdown and destroy expired
linked children. A second-phase callback can therefore draw, dispatch
subordinates or retire objects.

### Phase 3 and the final collision boundary

Phase 3 uses the first mask again. Its generic walker captures the count and
head at entry, invokes the third-phase method, then reads the next node.
It neither checks flags nor removes a node based on callback return.
Derived callbacks supply their own gates. Phase 2 has the same post-callback
next lookup; phase 1 instead saves next before removal. These walks do not
establish general safety for a phase-2/3 callback to destroy its current node.

| Consumer | Established work |
| --- | --- |
| Camera, input, stage | Generic walk; scoped node third-phase methods are empty. |
| Fighters | All 74 final concrete tables use `fighter_update_timelines_slot`. |
| Support | Two present side objects run their third-phase methods only with node flag bit 1 set. |
| Interaction auxiliary | Embedded service visits a two-by-four pointer bank and invokes each present object's late method. |
| Resident auxiliary | BTL late service followed by resident resource callbacks when the resident owner exists. |

The shared fighter callback includes late gameplay work: combo accounting,
attack registration, a character tail, callback selector 6 and action timeline
work, followed by command-history publication. Its initial state gates can
skip the full tail; a positive update pause suppresses the ordinary
attack/timeline portion without removing all later work.
[Hit response](../combat/hit_response.md#pause-lock-and-update-order) owns
the exact gates; [Combat execution](../combat/combat_action_execution.md#ordinary-attack-registration)
owns attack publication.

Six representative character tails establish distinct resource interfaces:

| Character ID | Established interface |
| ---: | --- |
| 4 | In major state 8, adjusts two retained attack vectors. |
| 60 | Reaches the puppet attack/animation bridge. |
| 92 | Calls the shared wood-controller late helper on its owned controller. |
| 18 | Passes a separately owned scene and embedded timer to the attack bridge; then independently advances or holds that timer. Construction/binding provides a model, scene and control object; cleanup destroys and clears them. |
| 59 | Owns three `0x120`-byte scenes plus a separately destroyed scene. In major 8, applies its retained attack offset before later eligibility gates and chooses a scene by character-local state. |
| 91 | Owns a `0x2C`-byte `pl91WoodCtrl`, bound to its fighter and 15 descriptor rows, plus two separate allocations; cleanup frees and clears all three. It reaches the same late helper as ID 92. |

ID 18's independent timer pass uses scene rate divided by 256 when its hold
gate returns zero and otherwise holds. It follows the gated registration loop
rather than being contained in it. ID 59 returns outside major 8.
These scenes are separate from the primary scene; no exhaustive character-tail
classification follows from these examples. Attack admission and temporary
scene-rate rules belong to
[Combat execution](../combat/combat_action_execution.md#character-specific-scene-and-timer-selection),
general advancement to [Scene playback](../../runtime/scene_playback_owners.md)
and puppet ordering to
[Puppet control](../characters/puppet_control.md#root-movement-remains-coupled-to-the-primary).

The resident auxiliary's BTL late chain performs an empty callback, a gated
primary/subordinate virtual pass, then finalization. The pass dispatches two
primary objects, two banks of 32 subordinates and another primary callback.
Finalization maintains pending flags and resident scalar pairs, then handles
the two sides' accumulated contributions. Resident resource callbacks follow.
[Combo accounting](../combat/combo_accounting.md#per-side-accumulated-contribution-route)
and [Auxiliary services](battle_auxiliary_services.md) own those mechanisms.

Only after phase 3 and session-child work does `query_process_active_pairs`
clear prior query results and produce new directional registration overlaps.
Common attack publication therefore precedes production, while phase-1
fighter consumption precedes it. This establishes the producer/consumer order,
not an elapsed display delay or a universal collision-query path.
See [Collision](../combat/collision.md#resident-query-list-boundary).

### Fighter overrides at phase boundaries

`chakra_control_state` holds three two-side `OverrideRequest` channels:

| Channel | Fighter destination | Value |
| --- | --- | --- |
| `update_requests[side]` | `node_flags` bit 1 | Requested bit 0. |
| `render_requests[side]` | `node_flags` bit 2 | Requested bit 0. |
| `special_requests[side]` | `state_flags` bit 7 | Requested bit 0. |

`fighter_overrides_apply` applies a value only with a nonzero request mask and an
existing published fighter. Other bits are preserved. Channel predicates
reject side indices outside 0..1 and return a Boolean mask test.

Neither application nor its phase wrappers clears masks. Zero mask retains
the current fighter bit; pending requests can persist and be reapplied at
all three boundaries in one service call. Session setup and teardown reset
the leading words, all six requests and the trailing control pair.
This is override application, not another fighter update or registry.
Gameplay meanings belong to the flag consumers.

## Root component forest

`BattleState.presentation_root` is the `0x70`-byte forest returned by
`battle_session_root`. Construction initializes its embedded ordered controller,
then performs one-time allocation and side binding.

| `BattlePresentationRoot` field | Allocation | Shape |
| --- | ---: | --- |
| `prompts` | `0xB10` | Two `0x580`-byte objects. |
| `combo` | `0x98` | Two `0x44`-byte objects. |
| `command_strip` | `0x650` | Two `0x320`-byte objects. |
| `shared_icons` | `0x28` | Singleton. |
| `gameplay_icons` | `0xF0` | Two `0x70`-byte objects. |
| `history` | `0xB0` | Two `0x50`-byte objects. |
| `world_markers` | `0x90` | Two `0x40`-byte objects. |
| `notice` | `0x34` | Resident-constructed singleton. |

Every pair is registered with side IDs 0 and 1. The root accessors expose
paired elements through the session. Element constructors install no vtables,
so their original class names are unresolved.
[Battle HUD](battle_hud.md#remaining-ordinary-presentation-forest) owns roles,
bindings and prompt placement.

Both root callbacks return while `callbacks_suppressed == 1`.
Otherwise the first updates shared icons and notice, then both sides of the
six arrays. The second draws each side's combo, prompts, command strip,
gameplay icons, world markers and history, then notice and shared icons.
In manager mode 3, combo digits draw only for the selected active side and
numeric history draws only in that mode. Children retain independent
active/fade gates.

Initialization finishes with `callbacks_suppressed = 0` and
`initialized = 1`. Scoped direct paths leave the callback gate open after
initialization; an indirect writer remains possible.

## Teardown order

After the end countdown, outer state `0x10` prepares the transition,
destroys both slotted support objects and releases the guide owner.
Route 8 selects continuation state `0x17` or `0x18`, which owns session
destruction. Other routes destroy the session before archive-release state
`0x11`. See [outcome cleanup](match_outcomes.md#cleanup-boundaries),
[support](../characters/support_mechanics.md#scheduled-lifecycle-and-teardown)
and [guide ownership](battle_audio.md#guide-allocation-publication-and-dispatch).

`battle_destroy_graph` destroys, in order:

1. Pause controller after shutdown.
2. Camera controller, clearing its published pointer.
3. Item manager, both top panels, clock, presentation root and auxiliary child.
4. Resident item globals, the start-menu owner after its shutdown, then
   transient-actor manager.
5. Six manager input/fighter alias words.
6. Graph and its published global.
7. Character-pair resources, interaction auxiliary owner, query subsystem
   and fighter overrides.

Graph destruction orders camera, input, fighter and stage registries.
Stage destruction is reached virtually through the registry and stage tables.

The item manager destroys its field-object chain before auxiliary handles and
both inventory panels. Saved inventory cache survives independently;
no old panel pointer transfers to the replacement session.
[Inventory](../projectiles_and_items/battle_item_inventory.md#na2-ownership)
owns the panel contract.

After deep cleanup, `battle_state_destroy` uses the constructor's reset helper:
all four mask halfwords become `0xFFFF`, inner state/delay zero, entry type
1 and all child pointers null. A positive signed delete flag frees the
session; the outer caller then clears its global. Reset does not copy the old
session into its replacement.

### Root resource ownership and nested cleanup

Root array destruction orders prompts, combo, command strip, gameplay icons,
history and world markers, followed by shared icons, notice and embedded controller.
A positive signed 16-bit delete flag frees the root.

`AllocatedArrayHeader` precedes each allocated pair by 16 bytes and retains
element size, count and destructor. `array_delete` invokes the stored
destructor from last element to first with delete flag -1, then frees the
header. Each pair therefore destroys side 1 before side 0. Embedded-array
cleanup also runs backwards without separately freeing embedded storage.

| Owner | Nested ownership |
| --- | --- |
| `BattlePromptDisplay` | Optional layer, embedded animation and four embedded `0xF8`-byte sprites. |
| `BattleRootCombo` | Layer, sprite wrapper and animation handle. |
| `BattleCommandStrip` | Three embedded `0xF8`-byte sprites. |
| `BattleGameplayIcons` | 26 child pointers; every present child is freed and its slot cleared. |
| `BattleRootHistory` | Sprite, then linked popup chain; next is saved before each free. |
| World-marker element | No nested free; pair destruction's -1 flag leaves storage to the array owner. |
| `BattleSharedIcons` | Five allocated sprite wrappers, two layers and animation handle, then parent allocation. |
| `BattleNotice` | Layer, `0x80`-byte subordinate and two allocated notice sprites; all four fields cleared, then parent allocation. |

Shared-icon sprites own wrappers, not archive texture payloads.
Sprite creation allocates `0xF8` bytes and binds a named borrowed payload;
the paired destructor frees the wrapper. The animation wrapper is
`0x120` bytes. Root cleanup releases handles and layers; later archive
release owns archive allocations. Markers borrow the shared icon bundle
and have no nested shared-sprite destructor. Child frees continue through
slot clearing, remaining children and parent cleanup.

### Archive lifetime is separate from session lifetime

Ordinary state `0x11` releases the shared battle archives, gauge, BTL skill
bank, stage, both fighters' selected masks `0x1FF` and stage-associated
resident archive after session teardown. Continuation states bypass this
full release and prepare resources selectively. New fighter allocations
therefore do not imply every underlying CCS archive was unloaded.

Both continuation handlers release pending-side resources after session
destruction, preserving cross-side sharing as described in
[Asset dependencies](../../game/files/asset_dependencies.md#pending-side-release-preserves-the-other-sides-resources).
State `0x18` additionally compares selected-side pending and active identities,
fully releases mask `0x1FF` and restores that side only on a mismatch, then
prepares and queues the other side. These comparisons concern identities
and archive handles, not survival of old fighters.

## Continuation encounters rebuild the session

Both audited route-8 paths destroy the whole session, prepare resources and
select outer state `0x0D`. States `0x0D/0x0E` then adopt resources and
construct a new session through ordinary entrypoints.

State `0x17` adopts a pending stage only when it is not -1, without releasing
the loaded stage archive. State `0x18` releases stage and associated resident
archive only when pending and active stage bytes differ; it queues replacements
only when that changed pending stage is not -1. Retained archives do not
retain stage-bound objects: stage owner and background controller are
recreated on either route.

### Values crossing the reconstruction boundary

`battle_save_reentry_values` saves before destruction;
`battle_restore_reentry_values` restores after new fighter publication.
Side -2 iterates sides 1 and 2.

| Mask bit | Retained value | Restore |
| ---: | --- | --- |
| `0x01` | `Fighter.hp` | Direct float copy. |
| `0x02` | `Fighter.chakra` | Direct float copy. |
| `0x10` | Remaining and elapsed timer counters, when any side resolves. | Both saved counters copied back. |
| `0x20` | Eligible inventory cache. | Eligible entries rebuilt into new panels. |

HP is normalized and is not rescaled by the new character's static durability.
Timer flags and configured limit are not copied. Item restoration transfers
cache values, not gameplay effect nodes; its filtering and compaction belong
to [Inventory](../projectiles_and_items/battle_item_inventory.md#item-cache).
These are the same compact-cache helpers used by Practice.

Timer capture copies `battle_countdown_remaining` and `battle_countdown_elapsed`
to `battle_countdown_remaining_snapshot` and `battle_countdown_elapsed_snapshot`.
Restoration copies those saved words back under mask bit `0x10`.

| Route and entry condition | Save | Restore |
| --- | --- | --- |
| `0x17`, re-entry variant 1 | Both sides, mask -1: HP, chakra, timer, inventory. | Both sides, mask -1. |
| `0x18`, outer entry type 4 | Selected side, mask -17 (`~0x10`): HP, chakra, inventory. | Both sides, mask -17; no timer counters. |
| `0x18`, other entry types | Selected side, mask `0x20`: inventory only. | Both sides, mask -17; no timer counters. |

In `0x18`, the selected saved side is 1 when the first pending character ID
is zero and 2 otherwise. A single-side save first initializes **both**
snapshot pairs to HP 1.0 and chakra 15.0 and clears both three-record inventory
caches. Only then are selected-side requested values copied. Thus entry type 4
retains that side's HP/chakra and leaves the other defaults; other entry types
leave both pairs at defaults.

Session setup initializes new timer counters and limit before graph build.
Route `0x17` later restores both counters; `0x18` keeps the new counters.
Restoration occurs after both fighter aliases and item manager publication,
before the remaining presentation children and root. No old command nodes,
gameplay nodes or graph pointers survive through these helpers.

Fresh fighter construction resets the selected Ultimate Jutsu effect,
state/phase/progress, logical command, pending-hit byte, item projectile
counter and controller/special bits. Both sides receive new native combo
objects with current/maximum and timer reset. Neither continuation helper
copies these fields. See [Combo accounting](../combat/combo_accounting.md).

Both handlers finish with continuation phase 2, clear pending character/stage
values and select state `0x0D`. The reconstruction entry skips result-bank
reset in phase 2 and advances to phase 3 after its allocation attempt.
That store occurs even when allocation fails: phase 3 alone does not prove
a replacement session exists. Form adoption belongs to
[Awakening](../characters/awakening.md#static-reconstruction-order).

### Fighter statistics across reconstruction

Statistics use a separate external bank. Fighter cleanup first saves all 24
current/high-water pairs. Construction clears the new local pairs, preserves
the external pairs in continuation phase 2, then reloads them.
The statistic contract belongs to [Hit response](../combat/hit_response.md#hit-count).

Both save and reload select
`fighter_statistics_banks + (Fighter.control_flags & 1) * 0x2D6`
and copy exactly 24 pairs of signed halfwords. An established side-two
fighter saves bank 1.

The construction ordering differs: common initialization clears the side bit
before statistics reload; later character setup assigns the side.
Both new common constructors therefore initially reload bank 0, including
the fighter that becomes side two. Both external banks are retained, but the
scoped common setup and continuation restore contain no correcting reload.

**Static consequence, high confidence within this chain:** distinguishable
old pairs initially become the old side-one pairs on both new fighters.
A later teardown saves each fighter's current pairs to its assigned bank,
so prior side-two contents are not protected from that later save.
This is traced dataflow, not a measured player-visible statistics result;
an untraced derived copy could change intervening values.
[Awakening](../characters/awakening.md#reconstruction-adoption-increment)
owns the adoption increment.

The `0x2D6` layout contains 24 pairs (`0x60` bytes) followed by 63
five-halfword action rows (`0x276` bytes).
Construction resets every local `Fighter.action_statistics` row even in
phase 2; save/reload and external clearing stop after the first 24 pairs.
Bounded address/store searches do not exclude differently derived pointers,
wider stores or indirect copies.

## Stage content binding

The graph owns a `BattleField` and its `0xAD0`-byte background controller.
Background construction publishes that controller; field initialization
clears its local work, snapshots the controller binding and runs an empty
binding callback. [Stages](../stages/stages.md#live-environment-ownership-and-construction)
owns the construction and `stage_archive_paths` archive table.

### Per-update stage work

Stage work reaches only the node lifecycle methods. `field_update`
runs an empty background callback then its update callback with argument 0
and returns 0. Its return never requests removal, though the generic
node-flag-bit-0 rule still applies. `field_draw` runs background drawing;
the third-phase stage callback is empty.

Stage phase 1 visits five object lists; phase 2 draws 12 selector-group views
and restores the battle view. Their eligibility and timing belong to
[Stages](../stages/stages.md#update-eligibility-and-local-timing).
This stage update/draw split does not generalize to other registries
([phase 2](#what-phase-2-guarantees)).

Stage destruction clears the published background controller as described in
[Stages](../stages/stages.md#destruction-and-archive-release).

## Stage-specific inputs

A battle consumes these inputs keyed by the manager's raw active stage slot:

- Archive path from the unchecked 24-entry `stage_archive_paths` table,
  `stage/s01.ccs` through `stage/s24.ccs`.
- Associated resident archive selected by `stage_rash_archive_path`.
- Archive `BIN_bgdata` records and `DMY_*` line/boundary nodes read by the
  background controller ([boundary data](../stages/stages.md#boundary-and-floor-profile-data)).
- The main camera's [per-stage record](battle_camera.md#per-stage-camera-record).
- The stage slot supplied to the pause controller.

## Limits and negative results

Both continuation routes rebuild rather than retain the graph.
Scoped direct paths leave the root gate open; indirect writers remain open.
Stage destruction is established through virtual dispatch.
Direct-call and address searches do not exclude computed or other-overlay
callers, and no exhaustive indirect-caller search was performed.
