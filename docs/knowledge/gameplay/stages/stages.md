# Battle stage gameplay knowledge

## Research coverage

Established: retail NA2 stage resources and ownership, geometry/navigation,
reactive props and stage-object damage, with complete archive and named-factory
censuses, and the bounded stage-count/readers audit below. Open: arithmetic,
bulk and indirect stage accesses, untraced consumers/writers/callers, opaque
profile fields, unnamed semantics and context-dependent outcomes. Names come
from `@annotations/NA2`; addresses are live.

## Evidence and address convention

Retail input identities/conversions belong to
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
Names resolve in the NA2 MCP target: `BTL.BIN` for overlay routines and
`SLPS_258.37` for resident routines. Annotations own signatures, offsets,
callsites and RTTI links.

Evidence is static retail NA2 code/data and archives whose sizes match
`GZLIST.TXT`. Routine traces are bounded. Generic factory identities and
sampled configurations retain their qualifications in their owning sections.

**Confirmed** claims follow directly from bytes and control/data flow.
**Supported** interpretations also use RTTI, names or surrounding behavior.
Open questions retain the limits of the inspected paths.

Resident globals are mapped in the ELF's BSS and annotated in `SLPS_258.37`,
including those accessed by BTL routines.

Related owners: [Native Stage Select](../../game/stage_select.md),
[Battle lifecycle](../session/battle_lifecycle.md),
[Battle entities](../session/battle_entities.md), [Battle AI](../session/battle_ai.md),
[Collision](../combat/collision.md#stage-query-functions),
[Stage surface attributes](stage_surface_attributes.md),
[Section transfers](section_transfers.md), [Damage](../combat/damage.md),
[Match outcomes](../session/battle_statistics.md#ninja-tools-and-stage-objects),
[Pause and replay](../session/pause_and_replay.md#shared-ownership-and-controller-lifecycle),
[Battle camera](../session/battle_camera.md), [NUN3 battle stages](nun3_stages.md).
Stage Select presentation and fighter mechanics beyond stage consumers belong
to those owners.

## Stage identity and resource mapping

`BattleConfiguration.active_load_slot` is a zero-based archive slot;
`pending_load_slot` is the incoming slot for switching. `bg_control_load_stage`
copies it to active configuration and `BgControl.load_slot`, then indexes
`stage_archive_paths`. Mode 2 preselects slot 6, loading `stage/s07.ccs`
([Mode flow](../../game/mode_flow.md#mode-select-result-table)).

`stage_slot_logical_id` maps slots to
`1,2,23,24,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,3,4`.
The first word of each `stage_select_records` entry has the same logical
ID; its preview index equals the raw slot.

| Logical ID | Load slot | Archive |
| ---: | ---: | --- |
| 1 | 0 | `stage/s01.ccs` |
| 2 | 1 | `stage/s02.ccs` |
| 23 | 2 | `stage/s03.ccs` |
| 24 | 3 | `stage/s04.ccs` |
| 5 | 4 | `stage/s05.ccs` |
| 6 | 5 | `stage/s06.ccs` |
| 7 | 6 | `stage/s07.ccs` |
| 8 | 7 | `stage/s08.ccs` |
| 9 | 8 | `stage/s09.ccs` |
| 10 | 9 | `stage/s10.ccs` |
| 11 | 10 | `stage/s11.ccs` |
| 12 | 11 | `stage/s12.ccs` |
| 13 | 12 | `stage/s13.ccs` |
| 14 | 13 | `stage/s14.ccs` |
| 15 | 14 | `stage/s15.ccs` |
| 16 | 15 | `stage/s16.ccs` |
| 17 | 16 | `stage/s17.ccs` |
| 18 | 17 | `stage/s18.ccs` |
| 19 | 18 | `stage/s19.ccs` |
| 20 | 19 | `stage/s20.ccs` |
| 21 | 20 | `stage/s21.ccs` |
| 22 | 21 | `stage/s22.ccs` |
| 3 | 22 | `stage/s23.ccs` |
| 4 | 23 | `stage/s24.ccs` |

## Stage-count limits

The scoped audit covers `BTL.BIN`, resident `SLPS_258.37` and `ETC.BIN`:
immediate byte/halfword/word loads at manager offsets `0x98/0x9A/0x114`,
decoded direct calls to the two stage-ID services, relevant table references,
and aligned `slti/sltiu` comparisons with 24/25. It establishes the readers
and cases below, not an exhaustive pointer-flow census. Arithmetic aliases,
bulk/unaligned accesses, indirect calls and other accessors remain open;
`BgControl.load_slot` provenance was followed in the listed methods rather
than proved for every possible object pointer. No stage-sensitive ETC reader
was established by these searches. Tables can be unsafe even without a
stage-count comparison.

### Mapping and indexed data

`stage_slot_logical_id` (`0x006C14E0`) begins with unsigned `slot < 24`.
Accepted inputs dispatch through 24 code pointers at
`stage_slot_logical_id_dispatch` (`0x008C1F40`) to the 24 case entries
`stage_slot_id_case_0..23` (`0x006C1508..0x006C161C`). The result sequence
is the mapping above. `stage_slot_id_default` (`0x006C1628`) returns 0,
including raw slot 24 and negative inputs. The retail mapper has no result 25.
`stage_get_logical_id`
(`0x00308080`) reads unsigned manager `+0x98`, calls that numeric overlay
address at `0x0030809C`, and returns 0 without a manager.

| Data / live base | Index and count | Recovered readers | Raw slot 24 today |
| --- | --- | --- | --- |
| `stage_archive_paths`, `0x00890A10`; strings `0x00890890..0x00890A00` | Unchecked raw integer; 24 pointers, strings at stride `0x10` | `bg_control_load_stage` (`0x006C1AA4`), `stage_archive_acquire` (`0x006C311C`), `stage_archive_enqueue` (`0x006C31E8`), `stage_archive_adopt` (`0x006C3228`) | Reads `0x00890A70`, the `BIN_` bytes `0x5F4E4942`, as a path pointer. There is no 25th path. |
| `stage_camera_records_by_slot`, `0x00891E10`; records `0x00891510` | Unchecked raw slot; 24 pointers and 24 records | `camera_bind_stage_record`; [camera reader contract](../session/battle_camera.md#stage-count-limits) | Reads adjacent debug-name bytes as a record pointer. |
| `stage_combo_anchors`, `0x008C1DC0` | Signed manager byte; 24 records of `0x10` bytes | `stage_choose_combo_anchor` (`0x006C1300`; slot load `0x006C1374`) | Reads adjacent mapper dispatch data as an anchor record: pointers `0x006C1508/0x006C1514`, counts 32/21. The scan treats executable code as vectors. |
| `stage_navigation_authored_routes`, `0x00898A60` | Signed manager byte; 24 pointers | `stage_navigation_initialize` (`0x00705950`; table base `0x00705B18`) | Reads `0x00898AC0`, the `TEX_tail` prefix `0x5F584554`, as a route-list pointer. |
| `stage_select_records`, `0x008C3B10` | Bounded logical-ID search; 24 records of `0x10` bytes | Record lookup, TV construction, preview refresh and selected-stage drawing; all recovered readers are Stage Select routines | Mapper result 0 matches no row; lookup returns -1, preview uses row 0, drawing enters the name fallback. No outside-Stage-Select reader was recovered. |
| `stage_select_fallback_names`, resident `0x005C04C0` | Unchecked raw slot; 24 pointers | BTL `stage_select_selected_stage_draw`, base materialization `0x00715434` | Reads the zero word at `0x005C0520` as its text pointer. This word is adjacent appearance data, not a 25th name; renderer behavior for that null input is not established here. |
| `effect_4a_stage_intensity`, resident `0x005C3D40` | Signed slot load followed by unsigned `<25`; 24 authored bytes | `effect_4a_secondary_update` (`0x002C8900`; bound `0x002C8A00`, byte load `0x002C8A18`) | Passes the bound and reads zero padding at `0x005C3D58`. Absent manager or unsigned slot ≥25 uses `0xBF`. |
| `stage_line_change_rules`, resident `0x0054D540` | Six-record bounded search by signed raw slot | `fighter_stage_line_changed` (`0x002DEFE0`) | Misses every key and returns 1 at `0x002DF464` after the preceding geometry/height gates. It does not index record 24. |

Element/field references for the path, camera, anchor, route and selection
tables, camera records, archive strings and combo vectors found no additional
code readers. In particular, the anchor arrays are reached through `stage_choose_combo_anchor`;
camera record fields through the bound record. This is recovered-reference
evidence and does not exclude computed addresses. Stage Select's storage,
texture and loop capacities belong to
[Native Stage Select](../../game/stage_select.md#fixed-stage-count-limits).

The authored route list contains `StageRouteRecord` values of `0x0C` bytes,
terminated by signed `source_line == -1`. Initialization copies them into
the separate 64-record runtime work area. Its 32-line and 64-route capacities
are geometry limits, not counts of stages. All 24 authored pointers are
nonnull; the reader also accepts a null pointer as an empty list.

The effect intensity bytes, in raw-slot order, are
`CF CF 68 78 7F 8F 8F 7F AF 5F 90 7F AF 7F AF 6F 7F CF 7F 78 6C 7F 7F 7F`.
The selected byte is passed to resident `0x002C80C0` in mode 3 and replicated
into the packet's RGB components. Its table therefore contains stage-dependent
rendering data; zero padding is not evidence of an authored slot-24 value.

### Generation, retained state and resource defaults

| Path / live entry | Representation and limit | Raw slot 24 today |
| --- | --- | --- |
| `support_config_pair_side1`, `0x001F2AC0` | Ordinary `rng_low31() % 24`; scripted three-byte record uses byte 2 after sequence/count gates | Ordinary generation cannot produce 24. A scripted byte 24 is trusted and written to active `+0x98` or pending `+0x9A`. |
| `support_config_copy_swap`, `0x001FE540` | Trusted setup-record byte `+0x128`, copied at `0x001FE6F4` | Accepts byte 24 and snapshots it without a stage-count check. This input record is not a `SaveProfile`. |
| `manager_snapshot_configuration`, `0x001F4DD0`; `manager_restore_configuration`, `0x001F4ED0` | Copy current bytes `+0x98/+0x99/+0x9A` to/from `+0x114/+0x115/+0x116` | Preserve byte 24. The remembered Stage Select input is process-local manager state. |
| `manager_replace_configuration`, `0x001EE500` | Compares signed active/pending bytes; only incoming `0xFF` is the no-stage sentinel | Different incoming 24 passes the sentinel gate and reaches unchecked stage enqueue/adoption. Old stage and `n_rash` resources are released before the sentinel gate. |
| `manager_replace_form` | Guarded pending-to-active byte copy | A non-sentinel 24 can replace the byte; this path does not itself switch stage archives. |
| `stage_rash_archive_path`, `0x00207E20`; `stage_rash_group`, `0x00207EE0` | Equality groups selecting a six-path table; only groups 0/3/4/5 returned | Default group 0: `n_rash.ccs`. The two inlined group selections in `rash_parallel_animation_construct` (`0x00208CF0`) also choose `ANM_rash_b`. |
| Pause construction/refresh | Raw byte `BattlePauseController +0x0E`; mirrored by `battle_create_graph` and `bg_control_load_stage` | Constructor `pause_controller_update` (`0x0076E9D0`) retains 24. `pause_controller_refresh` (`0x0076EC10`) passes its signed byte to `pause_clear_stage_tag_refresh`, which ignores it; no indexed stage access occurs there. |
| `stage_slots_initialize`, `0x001F5780` | 24 native slot numbers, bounded at `0x001F57C8` | Does not initialize bit 24. The bit bank can represent it, but its existing value is not established by this initializer. |

Stage availability belongs to
[Content availability](../../game/content_availability.md#resident-stage-slot-availability).
Its bank rooted at `stage_availability_bits` is separate from the serialized
profile and from active/snapshot configuration. In the inspected profile-copy and secondary
snapshot/restore paths, no saved field was established as a battle stage slot
or logical ID. Their 25-column loops address ability projections, not stages.
The unknown secondary/opaque ranges in
[Save-data layout](../../game/save_data.md#record-layout) prevent a claim that
the whole on-card record contains no stage-valued field.

### Logical-ID equality cases

These are equality branches, not arrays indexed by logical ID. ID 25 is not
produced by the retail mapper; if supplied as the comparison value, it takes
the listed ordinary branch. Current raw slot 24 instead produces ID 0 and
takes those same branches.

| Routine / live location | Logical-ID exception | ID 25 or mapper default 0 |
| --- | --- | --- |
| `camera_controller_mode18`, `0x006DA8E0` | ID 5 adds 80 to eye endpoint component 2 | No bias; shared fixed presentation record and common stage correction. [Camera contract](../session/battle_camera.md#stage-count-limits). |
| `effect_selector_route`, `0x00308A70`; mapper calls `0x00308B94/0x00308C04` | Scoped attributes use selector `0x72` for IDs 18/12/2; `E0A000/E0E000` variants 1/2 for IDs 7/13 | Selector `0x7A`, variant 0. |
| Resident `FUN_003152C0`, mapper call `0x00315668` | ID 10 selects randomized duration limit 1 | Limit 30. |
| `stage_effect_height_override`, `0x00345A40` | IDs 23/5/10/9 write -50/-10/387/50 and return 1 | Write 0, return 0. |
| `stage_effect_height_bits`, `0x00345B20` | IDs 23/5/10/9 return `$v0 = 1` and `$f0 = -50/-10/387/50` | Return `$v0 = 0`, `$f0 = 0`. Retained TND wave creation stores the float result at BTL `0x007C0210`. |
| `masked_effect_begin`, mapper call `0x007F83A8` | ID 10 adds 70 to a probe endpoint/extent | No addition. |
| BTL `FUN_0078AA80`, accessor call `0x0078AB8C` | ID 10, fighter section 0 and the scoped owner IDs admit special collision placement | Skip that exception. |
| `btl_associated_descriptor5_select`, accessor call `0x007E0688` | IDs 6/3 with section 0 select flags `0xFFFFFFFD` and BTL `0x007E03F0` | Flags `0xFFFFFFFF`. |
| BTL `FUN_007EB880/FUN_007EB940`, accessor calls `0x007EB900/0x007EB9A4` | ID 8 with section 0 toggles scene selector `0x30` | Skip the stage-specific toggle. |
| `masked_effect_emitter_second`, accessor call `0x007F96DC` | ID 14 selects resident `0x0033AB10` variant 3 | Variant 0 and common generator path. |

### Immediate 24/25 comparisons

The aligned immediate-comparison search returned 73 sites across the three
images. Inspected stage-sensitive sites are:

| Site | Compared value | Bound and consequence |
| --- | --- | --- |
| `0x006C14E0` | Raw mapper argument | `sltiu 24`; reject slot 24 to result 0. |
| `0x001F57C8` | Native stage-slot initializer index | `slti 24`; process the existing 24 native slot entries. |
| `0x002C8A00` | Signed raw manager byte | `sltiu 25`; admit slot 24 into intensity padding. |
| `0x00713AA8/0x00713D00/0x007143A0` | Stage Select TV-object loop index | `slti 24`; construct, destroy and bind 24 objects. |
| `0x00714430/0x00714590/0x00715320` | Stage Select logical-record search index | `slti 24`; scan 24 records. |
| `0x007144F0` | Stage Select raw-slot choice scan | `slti 24`; slot 24 is never considered. |

Other inspected comparisons operate on course/encounter indices, action or
projectile-command values, timing, internal arrays, profile ability columns,
statistics and library quantities. ETC's `0x006CAF4C` bounds an audio-command
selector, not a proven stage value. Comparisons encoded through other
instructions or calculated limits are not excluded by this immediate search.

## Archive preload, adoption, and switching

The confirmed resource order follows controller states; whole-session gates
belong to [Battle lifecycle](../session/battle_lifecycle.md#resident-setup-order).

1. State 9 (`battle_state_select_stage`) gets the current raw slot from `stage_select_get_slot`
   and copies its low byte to active configuration.
2. State 10 (`battle_state_preload`) releases selection/common handles and calls
   `battle_load_ccs`(1): common resources, both fighters, selected stage and
   stage-grouped `n_rash`. The asynchronous branch uses `stage_archive_enqueue`
   and a loader fence; the synchronous alternative uses `stage_archive_acquire`.
   No direct caller of the preload's synchronous branch was found.
3. State 11 (`battle_state_wait_loader`) waits for the worker to stop and finalizes
   the queue. State 12 (`battle_state_wait_ready`) advances when either readiness query
   succeeds.
4. State 13 (`battle_state_create_fighters`) constructs/registers both fighters, then
   `stage_archive_adopt` adopts the loaded stage.
5. State 14 (`battle_state_enter`) needs both final gates before `battle_state_allocate`
   and heavy graph construction through `battle_create_graph`.
6. State 15 drives `battle_loop_active` until the main graph is ready.
   Its environment-only contribution is not isolated.

The Stage Select initializer (`stage_select_initialize`) restores the saved slot.
State 9 calls `stage_select_set_slot` again: entry type 2 supplies slot 6; others supply
active configuration, replacing `0xFF` with slot 0. This overrides the
restored choice. The retail list contains all raw slots in ascending order.

The three trailing configuration bytes initialize to `0xFF` and snapshot/
restore together (`battle_manager_init`, `manager_snapshot_configuration`, `manager_restore_configuration`).
The middle byte's lifecycle role is unobserved. `support_config_pair_side1` first clears
pending configuration through `manager_clear_pending_forms`; its initial branch writes active
slot, its state-24 branch generates the next fighter/pending stage.
Ordinary generation uses random modulo 24; scripted generation trusts byte 2
of a three-byte record. `support_config_copy_swap` imports a trusted slot and snapshots it.

State 16 selects state 24 for mode 8/submode 2 and state 23 for submode 1.
`manager_replace_form` guards a pending-to-active copy but ordinarily sees `0xFF`:
this path neither generates a pending stage nor swaps archives. A restored
pending slot could change the byte, but a different value would violate the
visible loaded-resource invariant.

`manager_replace_configuration` (state 24) destroys the old graph, compares slots and,
when different, releases both old archives **before** checking incoming slot
against `-1`. A non-sentinel slot is copied to active configuration, enqueued
with its associated resource, fenced and returned to state-13 construction.
Normal generation must precede state-24 dispatch. This switches resources
between sessions
([continuation encounters](../session/battle_lifecycle.md#continuation-encounters-rebuild-the-session)).

### Stage-grouped `n_rash` battle animation/effect archive

`stage_rash_archive_path` selects `stage_rash_archive_paths`:

| Table index | Path | Load slots |
| ---: | --- | --- |
| 0 | `n_rash.ccs` | all slots not listed below, including out-of-range values |
| 1 | `n_rash1.ccs` | never returned |
| 2 | `n_rash2.ccs` | never returned |
| 3 | `n_rash3.ccs` | 10, 13 |
| 4 | `n_rash4.ccs` | 18 |
| 5 | `n_rash5.ccs` | 0, 1, 6, 19, 20 |

`stage_rash_group` has the same grouping and accepts `-1` as use-active,
falling back to slot 0 without an active slot. Entries 1/2 are unreachable
through both selectors; their path pointers occur only in two table words,
without decoded code xrefs. Dynamic name lookup remains open.

`rash_parallel_animation_construct` requires `2cmnbod1` and the selected archive, resolves
`ANM_rash_p1`, then selects 0 → `ANM_rash_b`, 3 → `ANM_rash_e`,
4 → `ANM_rash_f`, 5 → `ANM_rash_g`; `c/d` correspond to unreachable
indices 1/2. Its archive and parallel-animation decisions inline the raw-slot
grouping separately; they do not both delegate to the named selectors.

Group 0's `ANM_rash_b` and `ANM_rash_p1` are byte-identical to the fixed
NUN4 resources, including their authored camera/target coordinates. Their
typed model/material/texture dependencies also correspond; the sampling
texture comes from NA2's common provider. This correspondence is established
under [NUN4 fixed n_rash](nun4_stages.md#fixed-n_rash-archive). Raw slot 24's
default group 0 therefore already selects the corresponding parallel content.

Other consumers resolve `ANM_gear1_la/ra`,
`ANM_gear2_la/ra`, `ANM_wait1_la/ra`, `ANM_wait2_la/ra`,
`ANM_kizu_a` (`rash_gear_animation_construct`), and `ANM_xrush_ca`, `ANM_start`,
`ANM_fight_01a/02a/03a`, `TEX_xrush` (`coordinator_auxiliary_initialize`).
This establishes stage-grouped battle animation/effect resources.

Consumers borrow without a reference increment and destroy derived children.
Central teardown recomputes the active path and destroys the archive node;
no dedicated `n_rash` handle is retained. Switching unloads the old group
before replacing the slot and enqueues the new path if absent. Two slots in
one group still unload/re-enqueue that path.

`stage_archive_acquire` looks up or synchronously loads the stage; `stage_archive_enqueue`
enqueues, `stage_archive_adopt` adopts after the fence, `stage_archive_release` destroys/
clears owner handle `stage_archive`. No direct BTL call or pointer word targets
these helpers; confirmed callers are resident.

Stage helpers index directly, requiring slots 0..23. Retail selection/
ordinary generation supply valid slots. Imported, scripted and restored bytes
lack an upper-bound check; sentinel handling does not reject every malformed
value. The `n_rash` selector defaults defensively.

Stage/`n_rash` paths assume exclusive lifecycle ownership: preexisting
lookup nodes are still destroyed without a loaded-by-controller bit.
The common bundle tracks ownership separately for `shade.ccs`,
`gauge.ccs`, `strmcmn.ccs`, `ougi.ccs`, preserving preexisting members.

## Live environment ownership and construction

The resident graph owns a BTL field owner, which owns standalone
`ccFieldCtrl` and its `ccField` list. Each `BattleField` embeds a separate
`ccGameObjCtrl` and owns `BgControl`; the control owns `BgScene`
(original `ccBgSystem`) and borrows the archive. The standalone controller
derives from `ccGameObjCtrl`; the field derives from `ccGameObj` and
embeds another controller.

`battle_create_graph` is the sole direct resident integration caller found for
`battle_create_sides`, which creates peer camera/command/player/field objects,
cross-links them and appends the field through `field_ctrl_append`.
This establishes resident graph ownership.

`field_create` constructs the field through `field_construct`, initializing/
publishing background control. With a manager it uses active slot and scalar
fighter identities; otherwise caller slot and identities `-1`.
`bg_control_load_stage` mirrors the slot into control/pause tags, borrows the archive,
initializes scene/line/config containers and calls `bg_scene_load` for
`BIN_bgdata`. `bg_scene_build` creates selectors, expands records,
dispatches factories and completes setup.

### `BIN_bgdata` records and factory dispatch

`BgRecord` contains owner-list selector, factory index, scene-list selector
and optional configuration. `bg_scene_parse_records` expands three signed 16-bit fields
and aligned strings. `bg_scene_dispatch_records` dispatches `bg_record_factories`,
whose 129 entries (0..128) are non-null.

`bg_scene_attach_object` copies record identity into each object and registers it in
one of 12 non-owning selector lists. Five separate owning lists own lifetime.
The class initializer consumes configuration. Every named retail record
uses owning list 4; ordinary classes use selector 2, `ccBgTrans*` selector 4.

| Factory index | Class | Factory routine |
| ---: | --- | --- |
| 40 | `ccBgTransObject` | `bg_trans_object_create` |
| 41 | `ccBgBreakDollBattle` | `bg_break_doll_create` |
| 43 | `ccElectricWire` | `bg_electric_wire_create` |
| 48 | `ccBgLandingTreeBattle` | `bg_landing_tree_create` |
| 50 | `ccBgBreakObjectBattle` | `bg_break_object_create` |
| 55 | `ccBgCrashBreakBattle` | `bg_crash_break_create` |
| 68 | `ccBgSuspensionBridge` | `bg_suspension_bridge_create` |
| 75 | `ccBgEscapeBirdBattle` | `bg_escape_bird_create` |
| 77 | `ccTumbleGrass` | `bg_tumble_grass_create` |
| 78 | `ccBgBreakObjectRebornBattle` | `bg_break_reborn_create` |
| 79 | `ccBgTransObject2` | `bg_trans_object2_create` |
| 80 | `ccBgBreakObjectFallBattle` | `bg_break_fall_create` |
| 81 | `ccBgBreakObjectMoveBattle` | `bg_break_move_create` |
| 82 | `ccHandRowShip` | `bg_hand_row_ship_create` |
| 83 | `ccCraneTruck` | `bg_crane_truck_create` |
| 84 | `ccHadesMarshSnake` | `bg_hades_snake_create` |
| 93 | `ccBgFootMarkBattle` | `bg_footmark_create` |
| 95 | `ccBgMangroveBattle` | `bg_mangrove_create` |
| 102 | `ccBgBreakObjectBattleAnm` | `bg_break_animation_create` |
| 103 | `ccBgBreakObjectBattleChandelier` | `bg_chandelier_create` |
| 107 | `ccBgTransAnm` | `bg_trans_animation_create` |

`ccGrassInfluence`, `ccWireHitModel`, `ccBgAttackHit` have compiled
RTTI/vtable identities without a top-level entry in this linkage.
Construction establishes helper/embedded uses, not every use.

### Resident generic factories and mandatory records

Indices 0..32 and several later entries point into the resident library.
These identities are **supported** by the last RTTI-named vtable installed
before registration:

| Factory indices | Class |
| --- | --- |
| 0 / 1 / 2 / 3 / 4 | `ccBgDrawObject` / `ccBgDrawClump` / `ccBgDrawAnm` / `ccBgDrawEff` / `ccBgDrawEffAnm` |
| 5 / 6 / 7 / 8 | `ccBgSwingTree` / `ccBgClothFlag` / `ccBgSwingGrass` / `ccBgRotateSky` |
| 11 / 12 / 18 | `ccBgGlareFilter` / `ccBgColorFilter` / `ccBgLightDistant` |
| 23 / 24 / 25 | `ccBgCurtain` / `ccBgClutAnmAlpha` / `ccBgClutAnmIndex` |
| 27 / 28 / 29 / 30 | `ccBgDrawShadowAnm` / `ccBgCelShadeAnm` / `ccBgUVAnm` / `ccBgWindBell` |
| 45 / 56 / 66 / 73 | `ccBgLantern` / `ccBgFloatingLightCtrl` / `ccBgDrawAnimationSpc1` / `ccBirdFly` |
| 57 / 58 / 59 / 60 / 61 / 62 | `ccBgDrawObjectGroup` / `ccBgDrawClumpGroup` / `ccBgDrawAnmGroup` / `ccBgSwingTreeGroup` / `ccBgSwingGrassGroup` / `ccBgSwingLeaf` |
| 85 / 86 / 87 / 88 / 114 | `ccBgCameraTraceObject` / `Clump` / `Animation` / `Eff` / `UVAnm` |
| 89 / 90 / 91 / 92 | `ccBgExtDrawObject` / `Clump` / `Anm` / `Eff` |
| 96 / 108 / 111 / 112 / 113 | `ccBgS13Effect` / `ccBgCamFallLeaf` / `ccBgEventProgDrawObj` / `Clump` / `Anm` |

That heuristic selects embedded `ccBgAttackHit` for BTL entries 50/84/102.
Decoded constructors establish the outer classes for resident entries
0/2/6/11/18/23/45. The remaining resident identities retain the heuristic's
qualification. Their scoped parser formats are recorded below; the
[NUN4 comparison](nun4_stages.md#s01-background-archive-and-native-factory-parity)
records both games' outer-vtable/RTTI chains.

| Factory | Confirmed meaning and retail use |
| ---: | --- |
| 10 | Fog; one per archive. S01: `125,200,190,0,40,0,100000`. |
| 17 | Two render coefficients; 21 archives. Example `0.45,0.35`. |
| 31 | Selector resource; every archive has `BLT_bg/BLT_obj`. S03/S04/S10/S18/S19 add `BLT_bg2`, `BLT_efe`, `BLT_hnd` or `BLT_obj2`. |
| 33/34 | Required `DMY_pp1_010/DMY_pp2_010` nodes; every archive uses string `-1`. |

Each archive has one record for 10,18,33,34,35,36,37,38, at least two
factory-31 records and one factory-11 record (S10 has two). Factory 18 names
a light animation/light, e.g. `ANM_stalig00,255,255,255,LGT_dis_0`.

`bg_factory_player1_node`/`bg_factory_player2_node` require player nodes without a null/sentinel
guard. `field_player_placement` adds `(0,0,200,1)` to the side's node position,
forces its last component to one, and gives orientation component 2
`+pi/2` for side 0 or `-pi/2` for side 1. Section is zero except slot 12
(S13), where it is one.

`fighter_initialize_placement` connects these nodes to ordinary placement through the
graph's four-registry initialization. Recovery `0x61/0x62` uses
`stage_placement_section`; `0x62` also projects through `stage_project_position`.
`fighter_recovery_placement` wraps recovery; `effect_4a_callback` uses it for a paired fighter
in major state 6/action `0x61`. They update the same section field as
[Section transfers](section_transfers.md#request-admission-and-retained-destination).

Factory 17 writes the `StageRenderDescriptor` object `stage_render_descriptor`,
initialized to `0.4/0.3` by `battle_initialize_render_descriptor`.
`battle_dispatch_phases` selects it; draw setup
retains it. `model_build_packet` multiplies one coefficient by 128 (and opacity
for flag `0x20000`) to pack a high color byte; the other enters another
packet word. `captured_pose_record_submit` temporarily adjusts
`stage_render_color_coefficient` and restores it; `battle_draw_adjust_render_b`
adjusts both that member and `stage_render_packet_coefficient` and restores them.
Authored values establish the rendering base; original names and final draw
values remain unresolved.

Factory 31 retains lookup results other than 0/4 in the selector owner.
S01's `BLT_bg/BLT_obj` are section-less names; their result was not traced.

`bg_scene_draw` applies fog before selector drawing and
resets the context afterward. `render_set_fog` converts `p` to
`(100-p)*2.55` and derives the distance ramp. S01 means distances
0..100000/percentages 0..40.
[NUN3 category 1](nun3_stages.md#nun3-scene-record-dispatch) has the same
role with different token ordering.

### Native background configuration formats

`bg_scene_parse_records` (`0x003ADE40`) expands signed-short triples and
copies each configuration separately, replacing its commas with NUL bytes.
`string_nul_token` (`0x001849E0`) selects the resulting zero-based token.
Factory lookup is independent of the record's owning-list and scene-list
selectors. Factory 31 uses the scene-list selector at record `+8` to choose
the selector owner whose resource field it writes.

These are native parser input formats. Numeric fields below are decimal
integers or floating-point text as specified; unspecified float meanings
remain unresolved.

| Index | Native parser/handler, live address | Tokens, zero-based |
| ---: | --- | --- |
| 0 | `bg_draw_object_parse`, `0x00395870` | 0 object name; 1 transform dummy or literal `0`; 2 float opacity; 3 float uniform scale. |
| 2 | `bg_animation_initialize`, `0x00396320` | 0 animation name; 1 transform dummy or `0`; 2 opacity; 3 uniform scale; 4 rate multiplier, all floats; 5 integer initial frame, with `-1` choosing a random frame. |
| 6 | `bg_cloth_flag_parse`, `0x00397680` | 0 texture name; 1 position/Euler dummy; 2 integer construction selector; 3/4 float dimensions multiplied by four; 5/6 floats; 7 **integer converted to float**; 8/9 floats; 10/11 integer grid dimensions. |
| 7 | `bg_swing_grass_parse`, `0x003980D0` | 0 object stem, children `stem_a0`..; 1 node; 2 integer child count; 3 float sway amplitude, multiplied by the scene factor; 4/5 integer minimum/maximum gust length in updates; 6 float not read by `bg_grass_sway_step`; 7 integer gust chance in percent per update; 8 integer angle step in degrees. Vertices at or above height 2.5 move. |
| 10 | `bg_factory_fog`, `0x00398A90` | 0..2 integer RGB; 3 float near percentage; 4 integer far percentage; 5/6 integer near/far distance, converted to float. |
| 11 | `bg_glare_parse`, `0x00398C40` | 0..3 packed-color integers; 4 float; 5..7 RGB integers; 8 integer mode; 9 float. |
| 17 | `bg_factory_render_coefficients`, `0x00399340` | 0/1 floats for the render descriptor's coefficients. |
| 18 | `bg_light_distant_parse`, `0x003993D0` | 0 animation name; 1..3 integer RGB; 4 light name. |
| 22 | `bg_projection_scalar_create`, `0x00399770` | 0 float stored at scene `+0x30`; the factory constructs no background class. |
| 23 | `bg_curtain_parse`, `0x00399A40` | 0 object name; 1 transform dummy or `0`; 2 opacity; 3 scale; 4..6 motion parameters, all floats. |
| 26 | `bg_factory_particle_emitter`, `0x0039A400` | 0 source composition; 1 position node; 2/3 floats stored in a copy of the `0x1F0`-byte particle template `0x005D5800`; 4 float multiplying one template field. The factory constructs no background class and registers the particle through `0x003AE2D0`. |
| 29 | `bg_uv_animation_parse`, `0x0039BBA0` | 0 object name; 1 transform dummy or `0`; 2 opacity; 3 uniform scale; 4/5 initial U/V, `-1` choosing a random value; 6/7 U/V speed per update. |
| 31 | `bg_factory_selector_resource`, `0x0039D2B0` | 0 resource name; a non-null/non-sentinel result is stored in the selected list owner. |
| 33/34 | player-position factories, `0x006C44C0/0x006C4520` | Configuration is ignored; require `DMY_pp1_010/DMY_pp2_010`, respectively. |
| 35/36 | second-line factories, `0x006C4580/0x006C45E0` | 0 integer node count, masked to eight bits; consumed in pairs, with no even-count guard. |
| 37/38 | first-line factories, `0x006C4640/0x006C46A0` | 0 integer pair count; normal/endpoint/move node families are tried for each numbered pair. |
| 41/50/80 | `bg_break_doll_parse`, `0x006C7180`; `bg_break_object_parse`, `0x006C5190`; `bg_break_fall_parse`, `0x006CE9B0` | Shared base tokens: 0 animation stem; 1 integer animation count; 2 integer threshold; 3 transform dummy; 4 collision dummy; 5 float scale; 6 float radius; 7 debris-object stem; 8 integer debris count. Animations and debris objects are named `stem_a0` through `stem_a(count-1)`. The subclass parsers consume no additional tokens. |
| 45 | `bg_lantern_parse`, `0x003A1930` | 0 object name; 1 transform dummy; 2 float angular step; 3 float amplitude. |
| 48 | `bg_landing_tree_parse`, `0x006C9BA0` | 0 object stem, children `stem_a0`..; 1 integer child count; 2 transform node; 3 float converted but not stored; 4 float uniform scale; 5/6 float landing-reaction width/height. |
| 75 | `bg_escape_bird_parse`, `0x006CD1D0` | 0 starting dummy; 1/2 floats; 3 ending dummy; 4 container filename; 5/6 animation names. |
| 79 | `bg_trans_object2_parse`, `0x006CE250`, through `bg_trans_object_parse`, `0x006C7510` | 0 visual name; 1 transform dummy; 2 float scale; 3 position dummy; 4 float radius; 5 float stored at `+0x60`, with initial blend at `+0x54` set to zero. |

Factory 6 constructs `ccBgClothFlag` at `0x00397AA0`:
vtable `0x005DD400` → RTTI `0x005D6150` →
name `0x005B3910`. Factory 45 constructs `ccBgLantern` at
`0x003A20B0`: vtable `0x005DCFF0` →
RTTI `0x005D5EC8` → name `0x005B36C8`.
Both classes are compiled into retail NA2, although neither factory is used
by a retail NA2 stage.

### Per-stage `BIN_bgdata` factory census

Each retail `STAGE/S01.CCS`..`S24.CCS` has exactly one `BIN_bgdata`,
in CCS marker `0xCCCC2400` (low tag `0x2400`). All share this framing:

```text
takaCreateBackGround|1.00|N|  N * { int16 owner, int16 factory, int16 selector }
||  N pipe-terminated configuration strings
```

Two pipes after the triples precede string zero. All 24 payloads yielded
exactly N triples/N aligned strings before padding. N includes generic types.
Factory 27 (`ccBgDrawShadowAnm`) has no record among 1,487 entries;
other construction and ordinary shadows are not excluded
([Shadows](../../runtime/rendering/shadow_rendering.md#background-controller-and-fighter-consumers)).

| Archive / load slot | N | Named factory records |
| --- | ---: | --- |
| `S01 / 0` | 85 | `TransObject x1`, `BreakObject x6`, `BreakReborn x3`, `BreakAnm x4`, `EscapeBird x10` |
| `S02 / 1` | 85 | `BreakDoll x3`, `BreakObject x5`, `BreakFall x10`, `EscapeBird x8`, `TransObject2 x2` |
| `S03 / 2` | 55 | `LandingTree x1`, `BreakDoll x2`, `BreakObject x1`, `TransObject x1` |
| `S04 / 3` | 61 | `BreakObject x5`, `BreakDoll x2`, `CrashBreak x3`, `TransAnm x1` |
| `S05 / 4` | 66 | `BreakObject x1`, `BreakDoll x5` |
| `S06 / 5` | 59 | `LandingTree x1`, `BreakDoll x4`, `BreakObject x1` |
| `S07 / 6` | 75 | `BreakDoll x4`, `BreakObject x1`, `LandingTree x1` |
| `S08 / 7` | 62 | `LandingTree x2`, `BreakObject x4`, `BreakDoll x1`, `BreakReborn x5` |
| `S09 / 8` | 52 | `BreakDoll x1`, `BreakObject x1` |
| `S10 / 9` | 57 | `BreakObject x1`, `BreakDoll x2`, `SuspensionBridge x1`, `TransObject x2` |
| `S11 / 10` | 93 | `BreakObject x4`, `BreakDoll x2`, `EscapeBird x3`, `LandingTree x1` |
| `S12 / 11` | 43 | `BreakDoll x4`, `BreakObject x1`, `FootMark x1` |
| `S13 / 12` | 63 | `BreakObject x1`, `BreakDoll x2`, `HandRowShip x1`, `CraneTruck x1`, `BreakFall x11`, `TransObject x1`, `Mangrove x1` |
| `S14 / 13` | 55 | `BreakObject x1`, `BreakDoll x3`, `LandingTree x2` |
| `S15 / 14` | 51 | `HadesMarshSnake x1`, `BreakObject x1`, `BreakDoll x1` |
| `S16 / 15` | 70 | `BreakObject x7`, `BreakDoll x4`, `FootMark x1`, `TumbleGrass x1` |
| `S17 / 16` | 33 | `BreakDoll x4`, `BreakObject x1`, `TransObject x1` |
| `S18 / 17` | 42 | `BreakDoll x4`, `BreakObject x1`, `FootMark x1` |
| `S19 / 18` | 65 | `ElectricWire x1`, `LandingTree x1`, `BreakDoll x4`, `BreakObject x1`, `EscapeBird x7` |
| `S20 / 19` | 72 | `BreakAnm x6`, `BreakFall x5`, `BreakObject x3`, `BreakDoll x2`, `TransObject x2` |
| `S21 / 20` | 59 | `ElectricWire x3`, `BreakChandelier x6`, `BreakAnm x4`, `TransAnm x2` |
| `S22 / 21` | 52 | `BreakDoll x4`, `BreakObject x1` |
| `S23 / 22` | 47 | `BreakObject x3`, `BreakDoll x4`, `TransObject x1` |
| `S24 / 23` | 85 | `BreakObject x13`, `BreakDoll x2`, `ElectricWire x3` |

This assigns physical archives: logical 3/4 load S23/S24, 23/24 load S03/S04.
Representative unique authored configurations:

| Archive, record | Factory | Exact configuration string |
| --- | --- | --- |
| `S10 #53` | `ccBgSuspensionBridge` | `OBJ_gim02,17,0,DMY_hasi,TEX_s10obj22,DMY_hasira_a,DMY_hasira_b,120,180` |
| `S12 #38` | `ccBgFootMarkBattle` | `s12.ccs,OBJ_s12efe05,2` |
| `S13 #33` | `ccHandRowShip` | `OBJ_obj_010_,OBJ_obj_011_,DMY_fune_dummy` |
| `S13 #34` | `ccCraneTruck` | `-1` |
| `S13 #51` | `ccBgMangroveBattle` | `OBJ_obj_120,3,DMY_dummy_010,1,1,300,200,OBJ_obj_121,DMY_ki_dummy` |
| `S15 #27` | `ccHadesMarshSnake` | `-1` |
| `S16 #59` | `ccBgFootMarkBattle` | `s16.ccs,OBJ_s16efe00_,2` |
| `S16 #69` | `ccTumbleGrass` | `OBJ_kusa_000,DMY_kusa_010,5,80` |
| `S18 #35` | `ccBgFootMarkBattle` | `s18.ccs,OBJ_s18efe05,2` |
| `S19 #44` | `ccElectricWire` | `DMY_dummy_010,DMY_dummy_020,TEX_s19obj40` |
| `S21 #53` | `ccBgTransAnm` | `ANM_s21gim100,DMY_dmy_020,1,DMY_s21has00,250,1,3` |
| `S21 #54` | `ccBgTransAnm` | `ANM_s21gim00_a0,DMY_dmy_030,1,DMY_s21has01,250,1,9` |

S21 records 39..41 create three wires with separate endpoint pairs/
`TEX_s21obj05`; 43..48 create six chandeliers. S24 records 82..84 create
three wires/`TEX_s24obj42`. Construction is established; methods determine
contact consequences.

The separately owned `battle_pause_controller` retains scalar
fighter identities/mirrors the slot. Its refresh calls `pause_clear_stage_tag_refresh`,
which clears auxiliary refresh without using the tag for any archive,
field, geometry or boundary operation.

### Update eligibility and local timing

`field_update` dispatches background update slots; `field_draw` dispatches
drawing. Virtual integration explains missing direct xrefs, not cadence.

`bg_control_update` detects transitions in `scene_update_restricted` and disables/restores
factory types 2/48 through `bg_scene_set_type_updates`. It always calls `bg_scene_update`.
Scene bit 1 skips owning-object loops; otherwise only enabled objects update.
Bits 2/4/8 independently gate three auxiliaries. The predicate combines
scene/control, menu/sequence, fighter markers and terminal queries;
one universal pause meaning is unproved.

`bg_scene_init` sets scene factor 1.0. Transition-animation step is
`u16(original_step * configured_multiplier * scene_factor)`;
CrashBreak uses `u16(256 * scene_factor)`. Advance units are 1/256
animation frame
([Scene playback callers](../../runtime/scene_playback_owners.md#playback-families)).
The full factor-writer set is open.

RotateSky advances/wraps angle under retained bounds classification;
UV animation gates factor-scaled increments/wraps to 0..1; sway gates phase;
the two-model owner skips countdown/random draws/transforms when both
classifications reject
([Visibility](../../runtime/rendering/visibility.md#bounded-resident-caller-inventory)).
These findings cover inspected methods.

A tick below means an eligible invocation of that object's update.
Counters/fades/sampled indices have local units; animation frames refer to
the separate playback cursor.

## Boundary and floor-profile data

### Line construction

`bg_build_first_lines` builds first-family `StageLine` from
`DMY_%scl_%d_nor/ewr/mov`; types `0x25/0x26` choose sections 0/1.
`bg_build_second_lines` builds second-family records from `DMY_line_010/020` and
numbered suffixes; types `0x23/0x24` supply node counts consumed in pairs
without an even-count guard. The callbacks obtain `bg_control_get_active`;
when absent they call resident no-op `bg_line_factory_noop` instead.

Lines contain endpoints/next/filter/section/cached attributes, with filter/
attributes initially zero. Each builder creates one head entry per populated
section; its linked list can contain many records.

The second builder creates `StageSectionConfig` with separate
`StageEndpointPair` copies, boundaries/references and absolute component-0
span. Capacity two matches both sections. `DMY_linemin01/max01/min02/max02`
give per-section bounds; component-0 comparisons derive overall bounds.
Endpoint copies lack cached attributes and do not alias linked records.

Every archive starts with factories `0x23,0x24,0x25,0x26`. The first two
strings supply node counts, producing half as many second-family records;
the last two directly give first-family counts. S06's `0x23` string
`6, , , ` parses as 6.

| Archive | Second family 0 | Second family 1 | First family 0 | First family 1 |
| --- | ---: | ---: | ---: | ---: |
| `S01` | 1 | 1 | 1 | 1 |
| `S02` | 5 | 3 | 1 | 2 |
| `S03` | 1 | 6 | 1 | 3 |
| `S04` | 5 | 1 | 1 | 1 |
| `S05` | 7 | 11 | 1 | 2 |
| `S06` | 3 | 5 | 1 | 2 |
| `S07` | 5 | 5 | 1 | 2 |
| `S08` | 7 | 5 | 3 | 1 |
| `S09` | 5 | 5 | 5 | 5 |
| `S10` | 5 | 12 | 5 | 5 |
| `S11` | 1 | 6 | 2 | 4 |
| `S12` | 1 | 1 | 1 | 1 |
| `S13` | 3 | 3 | 3 | 3 |
| `S14` | 1 | 1 | 1 | 3 |
| `S15` | 2 | 7 | 2 | 7 |
| `S16` | 1 | 5 | 1 | 1 |
| `S17` | 1 | 1 | 1 | 1 |
| `S18` | 1 | 1 | 1 | 1 |
| `S19` | 1 | 3 | 1 | 5 |
| `S20` | 1 | 1 | 1 | 1 |
| `S21` | 1 | 1 | 2 | 3 |
| `S22` | 1 | 1 | 1 | 1 |
| `S23` | 1 | 4 | 3 | 10 |
| `S24` | 7 | 7 | 8 | 9 |

`bg_cache_line_attributes` vertically queries every midpoint in both families/sections,
caching selected polygon attributes on a hit; a miss preserves the old value.
These are attributes, not a collider pointer/distance
([Collision](../combat/collision.md#stage-query-functions),
[Stage surface attributes](stage_surface_attributes.md#attribute-data-flow)).

### Cached line attribute consumers

`field_first_line_head` returns the active first-family head; `field_second_line_head`
returns the second. Both return zero without a background and otherwise
select the indexed head without reading cached attributes.

Direct census: ten first-getter/one second-getter BTL calls, two first-getter
resident calls, neither target in ETC, no BTL literal pointer word for either.
This covers direct encodings, not every computed call.

Inspected consumers use endpoints, next links, identity or filter:
nearest-line queries, planner/executor, AI proximity, `stage_navigation_initialize`,
BTL's `stage_correct_position`, `stage_nearest_endpoint`,
`fighter_stage_line_index` and `fighter_stage_line_changed`.
`stage_navigation_second_head` uses the second-family midpoint to choose a side.
No semantic cached-attribute reader was found; late-BTL clamp and
nearest-endpoint paths do not copy the tail.

The audited head-table aliases and navigation consumers yielded no semantic
reader of `StageLine.cached_attributes`. Other owners account for apparent
aliases. Untraced arithmetic, partial or unaligned loads and indirect
consumers remain open.

### Selected-index writers and neighboring aliases

The aligned audit covered all 486,832 BTL text words, including ordinary
stores overlapping active-index bytes and exact-address formations.
No exact formation was found. Twelve stores overlap: two initialize stage
indices to zero, ten belong to interaction/auxiliary/snapshot layouts.
MCP instruction annotations retain their owner census.

Builders set head **count 1**, allocate one-entry tables and leave active
indices unchanged. `bg_section_vector_reserve` changes only vector capacity/data and
reads size without reaching adjacent bytes. Destruction frees the tables;
getters only read them. Traced paths establish active head 0/count 1 per
populated section, without an authored multiple-head choice.

Unaligned partial stores/arithmetic through unidentified bases remain outside
the audit; the complete writer set is open.

### Boundary clamp and floor-profile queries

`bg_clamp_section_position` via `field_clamp_position` clamps component 0 between selected
configuration endpoints. `bg_floor_profile` via `field_floor_profile` interpolates
component 2 over section lines, returning `-32768.0` without an applicable
line/background. The contract belongs to
[Collision](../combat/collision.md#stage-query-functions).

## Stage-specific configuration and numeric branches

### Combo/skill anchor table

`stage_combo_anchors` has 24 `StageAnchorRecord` entries with side-specific
arrays/counts. Every vector's component 3 is 1.0. Raw order below preserves
tie-breaking; c0/c1/c2 mean components without assumed axis names.

| Slot / logical / archive | Side 0 anchors | Side 1 anchors |
| --- | --- | --- |
| 0 / 1 / S01 | `c0=[600,500,400,300,200,100,0,-100,-200,-300,-400,-500,-600] @ (c1,c2)=(0,0)` | `c0=[400,300,200,100,0,-100,-200,-300,-400] @ (c1,c2)=(1000,699)` |
| 1 / 2 / S02 | `c0=[-100,0,100] @ (c1,c2)=(0,-50)` | `c0=[-100,0] @ (c1,c2)=(1000,-50)` |
| 2 / 23 / S03 | `c0=[-500,-400,-200,0,200,400,500] @ (c1,c2)=(0,0)` | `c0=[0] @ (c1,c2)=(1050,-50)` |
| 3 / 24 / S04 | `c0=[0] @ (c1,c2)=(0,-50)` | `c0=[0] @ (c1,c2)=(750,0)` |
| 4 / 5 / S05 | `c0=[-400,-300,-200,-100,0,100] @ (c1,c2)=(0,5)` | `c0=[-50] @ (c1,c2)=(1000,16)` |
| 5 / 6 / S06 | `c0=[400,300,200,100,0,-100,-200,-300] @ (c1,c2)=(0,0)` | `c0=[300,200,100,0] @ (c1,c2)=(1000,127)` |
| 6 / 7 / S07 | `c0=[-400,-300,-200,-100,0] @ (c1,c2)=(0,75)` | `c0=[450] @ (c1,c2)=(1100,75)` |
| 7 / 8 / S08 | `c0=[-480] @ (c1,c2)=(0,53)` | `c0=[0,100,200,300,400] @ (c1,c2)=(800,1030)` |
| 8 / 9 / S09 | `c0=[300] @ (c1,c2)=(1000,600)` | `c0=[300] @ (c1,c2)=(1000,600)` |
| 9 / 10 / S10 | `c0=[0] @ (c1,c2)=(987,360)` | `c0=[0] @ (c1,c2)=(987,360)` |
| 10 / 11 / S11 | `c0=[200,100,0,-100,-200,-300,-400,-500,-600] @ (c1,c2)=(0,0)` | `c0=[-300] @ (c1,c2)=(800,0)` |
| 11 / 12 / S12 | `c0=[-500,-400,-300,-200,-100,0,100,200,300,400,500,600] @ (c1,c2)=(0,0)` | `c0=[-500,-400,-300,-200,-100,0,100,200,300,400,500] @ (c1,c2)=(1000,0)` |
| 12 / 13 / S13 | `c0=[0,100,200,300,400,500,600] @ (c1,c2)=(0,0)` | `c0=[-500,-400,-300,-200,-100,0,100,200,300,400,500] @ (c1,c2)=(1250,450)` |
| 13 / 14 / S14 | `c0=[-750,0,750] @ (c1,c2)=(0,0)` | `c0=[-750,0,750] @ (c1,c2)=(0,0)` |
| 14 / 15 / S15 | `c0=[-50,50,150] @ (c1,c2)=(0,60)` | `c0=[0] @ (c1,c2)=(1250,60)` |
| 15 / 16 / S16 | `c0=[0] @ (c1,c2)=(800,0)` | `c0=[0] @ (c1,c2)=(800,0)` |
| 16 / 17 / S17 | `c0=[-500,-400,-300,-200,-100,0,100,200,300,400,500] @ (c1,c2)=(0,0)` | `c0=[-500,-400,-300,-200,-100,0,100,200,300,400,500] @ (c1,c2)=(1000,0)` |
| 17 / 18 / S18 | `c0=[-500,-400,-300,-200,-100,0,100,200,300,400,500] @ (c1,c2)=(0,0)` | `c0=[-300,-200,-100,0,100,200,300,400,500] @ (c1,c2)=(1000,0)` |
| 18 / 19 / S19 | `c0=[100,0,-100,-200] @ (c1,c2)=(0,0)` | `c0=[0] @ (c1,c2)=(1000,0)` |
| 19 / 20 / S20 | `c0=[400,300,200,100,0,-100,-200,-300,-400,-500,-600] @ (c1,c2)=(0,0)` | `c0=[400,300,200,100,0,-100,-200,-300,-400,-500,-600] @ (c1,c2)=(0,0)` |
| 20 / 21 / S21 | `c0=[300,200,100,0,-100,-200,-300] @ (c1,c2)=(0,0)` | `c0=[300,200,100,0,-100,-200,-300] @ (c1,c2)=(1000,0)` |
| 21 / 22 / S22 | `c0=[100,0,-100] @ (c1,c2)=(0,0)` | `c0=[200,100,0,-100,-200] @ (c1,c2)=(0,0)` |
| 22 / 3 / S23 | `c0=[0] @ (c1,c2)=(1050,375)` | `c0=[0] @ (c1,c2)=(1050,375)` |
| 23 / 4 / S24 | `c0=[-200,-100,0,100] @ (c1,c2)=(0,0)` | `c0=[-200,-100,0,100] @ (c1,c2)=(0,0)` |

`stage_choose_combo_anchor` selects active slot/requested side, searches that array and
copies the strictly nearest anchor. Equal distance keeps the first raw
element. Without a live field/background it leaves a zero vector/returns 0.

`skill_combo_choose_anchor`, reached through `skill_combo_anchor_entry` on `ccSkillComboBase`,
supplies the fighter's signed section (or zero), masks it to a byte and
retains returned side/position. This establishes combo/skill placement.

After search, slots 13/19/21/23 force return 0; 8/9/15/22 force 1.
The forced return does not change which array was searched.

### Background classifier and slot-specific objects

`bg_surface_variant` via `field_surface_variant` selects surface/background **effect-variant
columns**, not geometry-transition codes:

| Case | Code |
| --- | ---: |
| No background, wrapper fallback | 1 |
| Slot 6 (S07) | 0 |
| Slot 12 (S13) | 2 |
| Slot 13 (S14), no position | 4 |
| Slot 13, absolute c0 distance from -700 less than 200 | 3 |
| Slot 13, absolute c0 distance from +700 less than 200 | 6 |
| Other classifier cases | 0 |

The +700 test wins if both could pass. Full vectors:
`(-700,950,400,0)`, `(700,950,400,0)`. `surface_effect_variants` has
rows `0x7B..0x81`/`0x82..0x88`; `surface_effect_construct` selects the column
by classifier and row through the selected context bit. Materials are unnamed.

Eight BTL/seven resident direct consumers select these effects or use
`code+0x22` for a spawned object's variant; four LandingTree callsites
request count 10. Classifier codes are 0/2/3/4/6, fallback 1.
No audited path produces 5; the seven-column table supports 0..6.

`bg_setup_s15_animation` resolves `ANM_s15efe04` only for slot 14 (S15);
all other slots clear the retained animation.

Other numeric exceptions have no established visual/gameplay names:

| Slot/archive | Function | Confirmed exception |
| --- | --- | --- |
| 1/`s02`, 7/`s08`, 18/`s19`, 20/`s21` | `stage_nearest_line_extended` | Replace the input with `1100.0`, then apply the common multiplication by 10: query extent `11000.0`; other slots use `argument * 10`. |
| 5/`s06`, 22/`s23` | `stage_navigation_response` | When `Fighter.major_state == 5`, call resident `fighter_navigation_response_adjust` before common handling. |
| 7/`s08` | `stage_plan_route` | Source line 1 or 2 may accept direct state 3 when a target or route is absent. |
| 7/`s08` | `stage_navigation_s08` | Lines 1/2 receive special handling around component-2 threshold `800`. |
| 12/`s13` | `stage_navigation_s13` | Special handling uses `Fighter.section` and action IDs `0x30`, `0x2C`, `0x27`, and `0x25`. |
| 18/`s19` | `stage_plan_route` | Source line 5 may accept direct state 3. |
| 20/`s21` | `stage_plan_route` | Source line 1 may accept direct state 3. |

All are load slots; 22 is logical ID 3/archive S23.

### Other recovered raw-slot equality cases

These comparisons contain no stage-indexed array. Raw slot 24 takes the
ordinary case in every row; a branch match would require one of the explicitly
listed retail slots. Field/scene identities beyond the stated data flow remain
unassigned where the routine still has its generated name.

| Reader / live slot-load site | Confirmed special case | Ordinary case, including raw slot 24 |
| --- | --- | --- |
| `field_player_placement`, `0x00708FFC` | Slot 12 initially uses section 1 | Section 0. |
| `stage_set_scene_selector_state`, `0x006C3088` | Slot 15 remaps requested selector 7 to 2 | Preserve the requested selector. |
| `ai_point_route_update`, `0x006F44A0/0x006F46BC` | Slot 7 raises a distance gate from 10 to 40 and specializes input `0x1000` handling | Common distance/orientation handling. |
| `ai_construct_point_route`, `0x006FD09C` | Slot 22 rejects region 0 in one secondary-provider candidate path | No stage-specific rejection. |
| `ai_predict_environment_reaction`, `0x006FD700` | Slot 12 admits the scoped random special handling | Ordinary dispatcher-state path. |
| `stage_slot9_object_initialize`, `0x00734978` | Slot 9 sets object byte `+0x60` to 1 | Does not write that flag in this routine. |
| `stage_slot8_resource_select`, `0x007365FC` | With the third argument zero, slot 8 selects resource index 3 | Resource index 4. |
| BTL `FUN_0079D520` (`0x0079D818`), `FUN_007E8FD0` (`0x007E9090`), resident `FUN_003132B0` (`0x00313390`) | Slots 5/10/9 add component-2 probe padding 30/27/50 | Padding 0. |
| `anb_primary_endpoint_advance`, `0x0080DC40` | Slot 23 with associated fighter section 1 replaces 350 with 150 | Retain 350. |
| `effect_select_polygon_code`, `0x0020A860` | Slot 12 makes attribute `E0E000` choose variant 4 and height 0 | Variant 0. |
| Resident `FUN_002DE6D0`, `0x002DE72C` | Slot 23, section 1, line index 1 changes 60 to 100 | Retain 60. |
| Resident `FUN_002DF790`, `0x002DF820` | Slot 4 adds 10 to the local height probe | No addition. |
| `bg_break_anm_trigger`, `0x006C58D8` | Slots 0/19 emit event `0x26` before common event `0x22` | Emit only `0x22`. |

`fighter_stage_line_changed` additionally uses tolerance 50 for slots 2/6/13,
200 for slot 18, and 100 otherwise. With a nonzero second argument,
slots 2/6/13 specialize section-1 old-line/counter/height gates. Its
`stage_line_change_rules` search has six keys, rather than one row per stage:

| Raw slot | Transition list | Count |
| ---: | --- | ---: |
| 8 | Null | 0 |
| 9 | `stage_line_change_slot9`, `0x0054D440` | 4 |
| 14 | `stage_line_change_slot14`, `0x0054D460` | 7 |
| 18 | `stage_line_change_slot18`, `0x0054D490` | 5 |
| 22 | `stage_line_change_slot22`, `0x0054D4B0` | 9 |
| 23 | `stage_line_change_slot23`, `0x0054D4F0` | 13 |

Each transition is three signed shorts: section, previous line and current
line. A matching null list or missing transition returns 0; a matching triple
returns 1. An unlisted slot, including 24, returns 1 after the earlier gates.

### Proximity-driven background transitions

The three `ccBgTrans*` classes reversibly change model/animation state from
fighter proximity; their compiled paths neither switch archives nor move
fighters between arenas.

`bg_trans_object_parse`/`bg_trans_object_update` use configured model/animation, scale,
origin/radius. Either fighter inside the 3D radius eases blend toward 0;
neither inside toward 1, at rate 0.2. Frame is
`blend * bg_animation_limit(700.0, model)`. A nonnegative override writes
once then resets to -1. `bg_trans_object_draw` chooses an endpoint controller
around frame 1. No fighter state is written.

`bg_trans_anm_parse`/`bg_trans_anm_update` retain that behavior with configured
step multiplier/animation index (-1 chooses randomly).
`bg_trans_object2_parse`/`bg_trans_object2_update` derive from the base: blend starts at zero,
eases toward configured target in radius/zero outside at 0.2 and becomes
the model frame directly.

The complete authored instances:

| Archive, record | Class | Configuration |
| --- | --- | --- |
| `S01 #44` | `ccBgTransObject` | `OBJ_obj_040_,DMY_s01has01,1,DMY_s01has00,200` |
| `S02 #79` | `ccBgTransObject2` | `OBJ_efe_040_,DMY_has2_000,1,DMY_has2_000,700,0.8` |
| `S02 #80` | `ccBgTransObject2` | `OBJ_efe_050_,DMY_has2_010,1,DMY_has2_010,700,1` |
| `S03 #51` | `ccBgTransObject` | `OBJ_obj_300_,DMY_has00,1,DMY_has00,0` |
| `S04 #56` | `ccBgTransAnm` | `ANM_s04efe10,DMY_s04has00a,1,DMY_s04has00b,0,0.9,1` |
| `S10 #54` | `ccBgTransObject` | `OBJ_obj_070_,DMY_hnd_00_,1,DMY_has00_hit,350` |
| `S10 #55` | `ccBgTransObject` | `OBJ_obj_080_,DMY_hnd_01_,1,DMY_has10_hit,350` |
| `S13 #48` | `ccBgTransObject` | `OBJ_obj_300_,DMY_gmk_a0,1,DMY_s13has00_hit,100` |
| `S17 #28` | `ccBgTransObject` | `OBJ_obj_010_,DMY_has00,1,DMY_has00,0` |
| `S20 #66` | `ccBgTransObject` | `OBJ_obj_100_,DMY_has00,1,DMY_has00,0` |
| `S20 #67` | `ccBgTransObject` | `OBJ_obj_110_,DMY_has01,1,DMY_has01,0` |
| `S21 #53` | `ccBgTransAnm` | `ANM_s21gim100,DMY_dmy_020,1,DMY_s21has00,250,1,3` |
| `S21 #54` | `ccBgTransAnm` | `ANM_s21gim00_a0,DMY_dmy_030,1,DMY_s21has01,250,1,9` |
| `S23 #30` | `ccBgTransObject` | `OBJ_obj_110_,DMY_gmk_a0,1,DMY_s23_has_hit,100` |

## Geometry-driven navigation graph

`stage_nearest_line_extended`/`stage_nearest_line`/`stage_nearest_line_vertical` scan first-family segments via
`stage_line_intersection` for the nearest intersecting line. Movement flag `0x800`
additionally requires line filter 1.

`stage_plan_route` maps current/target lines into `stage_navigation_lines`
(maximum 32 pointers), finds sections through active lists and uses
`stage_navigation_routes` (64 `StageRouteRecord`s) with
`stage_navigation_visited` (64 bytes). These are runtime work areas:
`stage_navigation_initialize` initializes line pointers/extrema and authored adjacency.
Their static imported bytes do not establish initialized contents.

Routes contain signed source/destination indices, interpolation fraction and
action/type. `stage_route_search`/`stage_route_search_branch` recursively search; the point is
`A+(B-A)*fraction`. The inspected section mismatch sets state 4/cancels
that route.

`stage_execute_route` consumes route/type to write traversal input: yaw near
`+/-pi/2`, flags `1,2,0x100000`, consulting fighter section.
All 15 direct BTL planner calls are AI decisions/dispatch; no direct
resident/ETC planner call exists. Ordinary AI ticks require a nonzero
controller nibble. This proves AI traversal input without excluding indirect
callers. Tick/route-state ownership belongs to
[Battle AI](../session/battle_ai.md#controller-ownership-and-lifecycle) and
[path states](../session/battle_ai.md#alternate-target-position-sources-and-path-states).

## Animated and breakable-background evidence

`ccBgAttackHit` is a reusable **contact receiver** with category
`0x43020000`, query ID `0x224`, mode 2 and a compact reset/destructor
vtable without a damage/update slot. Generic break contact is not an attack.

`bg_break_trigger` advances base-break models, capping count at 99.
Finite threshold clamps to the final model/enables transform/effect blocks/
emits event `0x22`. Threshold -1 loops; before a finite threshold it
clamps to the penultimate model and restarts playback.

`bg_break_update` enumerates fighters or queried contacts, rejecting category
mask `0x00F00000`/bit 2 and flags `0x02000000`. Accepted contact
advances background state; threshold credits metric 12 to the contacting
side through `projectile_contact_statistic`
([Match outcomes](../session/battle_statistics.md#ninja-tools-and-stage-objects)).
No fighter HP/state write or class-specific damage call occurs.

BreakAnm (`bg_break_anm_trigger`/`bg_break_anm_update`) emits `0x22` for every
slot; slots 0/19 (S01/S20) first emit an additional `0x26`. Names remain unknown.
Contact uses the same filters/credits metric 12 when the break flag is nonzero.
With nonzero remaining count, it waits more than 120 ticks, resets model/
index/playback/opacity and decrements a finite count. Fade rises 0.05 per
tick to one, then state/opacity/flag reset and model opacity is fixed at one.

`bg_break_reborn_update` gives BreakReborn a distinct cycle after base update:
final break waits more than 120 ticks, resets model zero, decrements finite
repeat count, fades by 0.05 and clears break count. It exists only in S01
(three)/S08 (five), all configured repeat -1: retail rebirth is indefinite.

Other classes have separate local behavior:

- BreakDoll (`bg_break_doll_update`): similarly filtered contact resets animation/
  collider/spawns configured effect, then a `prng_inclusive(60)+60`
  cooldown only decrements while nonzero.
- BreakMove (`bg_break_move_update`): cubic-Bezier mover `bg_break_move_model`, then
  base update; full break starts `prng_inclusive(30)+30` delay, whose
  expiry resets model/playback/count.
- BreakFall (`bg_break_fall_update`): base update, predicted downward query mask
  `0x20000000`, vertical velocity minus 3.0 while unsupported,
  transforms propagated to models/effects; final break advances/enables all.
- CrashBreak (`bg_crash_break_update`): matching section/incomplete count required.
  Mode bit 1 accepts major state 5/substates `0x42/0x43/0x48`,
  animation predicate and configured planar proximity; bit 2 accepts
  `0x45/0x46/0x49` with vertical separation above half configured height.
  The first accepted fighter triggers the break. At threshold,
  `resource_unregister_environment` removes every model's environment
  registration and metric 19 is credited to the opposite side. Playback
  continues through the separate scene-factor update.
  No direct fighter-damage write occurs.

S13-only moving props:

- HandRowShip (`bg_hand_row_ship_update`): component deltas below `160,30,150`
  latch each fighter, clamp bounce velocity to at most -2.5/reset phase;
  one fighter state clears contact/sets -5. Damped sinusoidal rocking/
  vertical bob moves its two models without fighter writes/combat-hit calls.
- CraneTruck (`crane_truck_update`): ignores `-1`, resolves
  `ANM_s13cra00_a0/a1`, attaches a separate scene-owned break object
  `{owner=4,factory=50,selector=2}`. Threshold changes animation;
  completion restores animation/linked model/playback/count. Frames
  410/350/250/206/60/0 emit `0x1017`. Destructor leaves linked object
  to the scene; no explicit fighter hit occurs.

ElectricWire (S19/S21/S24) owns simulation, visuals and registered query
geometry. `bg_electric_wire_parse` configures resources/endpoints, 15 interior nodes/
16 `BgWireSegment`s. `bg_wire_build_segments`/`bg_wire_segment_construct` build them;
`wire_segment_build`/`wire_segment_create_geometry`/`environment_object_register` create/register world-space
environment objects. Each has a four-vertex visual and one group/two-triangle
hierarchy with rebuilt bounds. Generic/fighter queries walk that chain
([Collision](../combat/collision.md#resident-segmentenvironment-broad-and-narrow-phases)).

Attributes belong to
[Generated wire polygon attributes](stage_surface_attributes.md#generated-wire-polygon-attributes).
Configuration marks dirty/invokes update before owning-list attachment.
`bg_electric_wire_update` skips refresh under the shared restriction; otherwise both
amplitude branches call `bg_wire_refresh_dirty`. It rebuilds all pairs through
`wire_segment_replace_endpoints`/`wire_segment_rebuild`, clears dirty; oscillation marks dirty again.

`bg_wire_fighter_reaction` requires fighter proximity within 20 in c1, endpoint c0
span, 150 in c2 and full-word polygon-attribute equality. State/action
selects reaction. `bg_wire_track_node` retains the last node strictly below
fighter c0 and writes excitation/sag/tracking. The sole fighter-side call
is a read-only animation predicate; there is no explicit hit/damage call or
fighter write. Generic movement selecting registered polygons can have
separate consequences; damage/measured contact outcomes are not established.

S10 SuspensionBridge configures 17 segments/key 0/`DMY_hasi`/
`TEX_s10obj22`/`DMY_hasira_a/b`/120/180. `bg_bridge_update_geometry` matches
section/key, finds support and, with fighter flag bit 7, loads a node by -10
with outward attenuation 0.8. Central support change starts oscillation
0.02/-25, damped 0.999. Only bridge geometry/render state is written;
no receiver/fighter write/combat-hit call was found.

EscapeBird (S01/S02/S11/S19) is proximity escape. `bg_escape_bird_parse`
passes origin/destination/radius/arrival-speed/archive/models to a resident
child: state 0 waits in radius, 1 selects escape/moves, 2 moves/fades 0.05
per tick to inert 3. Outer update supplies fighter positions only.
No attack receiver/impact call exists.

S16 TumbleGrass (`bg_tumble_grass_parse`/`bg_tumble_grass_update`) creates five optional
variants/80 clumps. Trajectories within radius 150 change reaction angles.
Otherwise wind `(1,0,0,1)` acts in randomized 10..19-tick bursts,
damping/clamping to `+/-pi/3`. No fighter write/receiver/transition/
damage call occurs.

FootMark (S12/S16/S18) passes archive/model and a **surface-selection
bitmask**, not pool size, through `bg_footmark_parse`/`footprint_construct`.
Each fighter gets two 30-node pools, 120 models total, initially inactive,
opacity limit 0.5/fade 0.01.

`bg_footmark_update` requires nonnull `battle_manager`/zero from
`battle_footprint_gate`; `bg_footmark_bind_fighters` retries model-collection binding to
`OBJ_2cmn00t0 l foot/r foot`. These foot models are borrowed.
`footprint_update` queries c2 offsets +5..-100, mask `0x20000001`.
Result other than -1 and at most 20 latches contact/orientation/normal only
if `footprint_surface_selected` accepts selection
([Footprint surface selection](stage_surface_attributes.md#footprint-surface-selection)).
A later missing/distant result emits once/clears latch. Sustained contact
does not emit repeatedly; a close unselected surface avoids emission.

`footprint_emit` uses first inactive node; full pool skips emission.
Retained orientation/normal place it 4 higher in c2 at opacity 0.5.
That same update subtracts 0.01 from all nodes/deactivates below 0.01.
No fighter write/impact call occurs.

S13 Mangrove derives from LandingTree. `bg_mangrove_parse`/`bg_landing_tree_parse`
build three `OBJ_obj_120_a%d` around `DMY_dummy_010`, plus three
`OBJ_obj_121_a%d` with `DMY_ki_dummy`.

`bg_landing_tree_update`/`bg_landing_tree_reaction` require half-width in c0, height in c2/
200 in c1. Outside clears latches; inside requires `0x2000D801`
movement flags. States 0/1/4 arm a fresh reaction; 2 requires latch/nonzero
vertical speed/substate other than 23 then clears latch. Others require
grounded counter 1/clear latch; in 0/1, counter at least 9 pre-arms/
suppresses impulse. Accepted paths queue -50/start if idle/spawn variant
effect with width/scalar 2/count 10. No fighter hit/write; effect unnamed.

Displacement samples a shared curve, advancing 4 per call times amplitude.
At signed-halfword length it adopts stronger queued negative impulse or
halves amplitude/resets; magnitude below 0.5 ends motion.
`bg_mangrove_update` puts the derived group at
`derived_origin-(current_center-original_center)`: groups move oppositely.

S15 HadesMarshSnake ignores `-1`, resolves ten
`ANM_s15dai00_*` animations and uses two receivers/attack record.
States 0/1/2 idle/detect; reaction chooses 4/5. State 6 chooses
`prng_inclusive(2)+7`, configures attack/enables attack receiver.
`bg_hades_snake_hit_window` hits eligible fighters in animation-frame windows
27..29 (7), 26..27 (8), 46 (9) through `hit_enter_stage_object`, emitting `0x1F`.

S21's six Chandeliers use `chandelier_break_update`:

1. State 0: swing receiver; filtered break contact credits metric 12/enters 1.
2. State 1: acceleration 9.8/drop, break model/debris/effects on impact, then 2.
3. State 2: first 61 ticks enable impact receiver; `bg_chandelier_hit_window` hits
   eligible fighters through `hit_enter_stage_object`/effect `0x1001`, then disables
   receiver/removes debris/enters 3.
4. State 3: restores initial transform when broken state clears.

Separate rebirth waits more than 120 ticks/resets model zero/decrements
finite repeat count/fades 0.05/clears broken. The cycle supports configured
respawn. Exactly two direct BTL calls to `hit_enter_stage_object` exist: snake/
chandelier. Other indirect callers remain open.

### Proven stage-object hit-to-HP path

`hit_enter_stage_object` records source/attack, initializes ordinary response through
`response_enter_ordinary`, resets hit motion/calls callbacks. In the same call it
invokes `fighter_dispatch_action_update`: state 5 reaches `response_update_ordinary`, whose armed
event-zero path invokes `response_apply_table_timing` → `damage_calculate` → `fighter_apply_hp_debit`.
Authored snake/chandelier hits synchronously reach HP subtraction although
their methods/the entry contain no HP arithmetic
([Damage](../combat/damage.md#native-damage-calculation)).

Both records pass
[ordinary damage gates](../combat/damage.md#ordinary-hit-damage-gates):

| Source | Damage base | Divisor | Response selector | Response scalar |
| --- | ---: | ---: | --- | ---: |
| Snake 7/8 | 0.05 | 1 | `0x12` | 1.8 |
| Snake 9 | 0.05 | 1 | `0x15` | 1.0 |
| Chandelier | 0.05 | 1 | `0x1E` | 1.0 |

Flags are `0x122`, base 0.05/1. Durability/reservation/temporary effects/
handicap scale the result, clamped 0..1; exact contextual delta is unresolved.
Source callback bypass requires source `+0x0C` zero; both initialize -1.
Normal zero fighter override proceeds; observed fallback IDs remain outside
excluded `0x42..0x49`. No stage-source HP bypass was found.

Named assets further link `bg_break_animation_draw` to
`ANM_s13cra00_a1/DMY_s13hak00_hit`; S15 pool includes
`ANM_s15dai00_d1/d2/a1/a2/a3/a4`. RTTI makes Move/Fall/Reborn/Crash/
Doll base-break descendants and TransObject2 a TransObject descendant.
BreakAnm/Chandelier lack the base-break link and own state machines.

This establishes animated/breakable/proximity/contact-driven systems,
explicit snake/chandelier damage and reactive wires with registered geometry.
No background HP field was established. `bg_break_trigger` (`0x006C47B0`)
requests a shared item spawn at the finite threshold; its threshold -1 loop
requests one when `prng_inclusive(100) < 20`. The accepted-contact branch in
`bg_break_doll_update` (`0x006C6940`) also requests a shared item spawn.
These items belong to the shared battle service, beyond the eagerly owned
stage graph's allocation cost.

## Destruction and archive release

`field_destruct` destroys background through `bg_control_cleanup` then
`bg_control_unpublish`, frees remaining config/control storage and tears down the
embedded controller/field. Control cleanup destroys config entries, all
linked lines/head tables and the scene.

`bg_scene_destruct`/`bg_scene_destroy` destroy objects in five owning lists before
`bg_scene_destroy_selectors` destroys 12 selector owners/12 associated objects and auxiliaries.

| Class | Owned cleanup |
| --- | --- |
| Mangrove | derived models, then inherited LandingTree models |
| FootMark | four footprint pools through the resident controller |
| HadesMarshSnake | model, both receivers, source node |
| CraneTruck | model/controller; linked break object remains scene-owned |
| HandRowShip | both models/controllers |
| TumbleGrass | clumps, variant resources/array |
| EscapeBird | unregister/destroy resident child |
| SuspensionBridge | node/rope/helper arrays |
| ElectricWire | segments/all three node buffers |

Resolved outer classes reach their destructor through the scene's virtual
dispatch; compact helper vtables have separate layouts. Local cleanup
finishes through common teardown and optional self-free without archive release.

`bg_wire_segment_destruct` → `wire_segment_cleanup` cleans wire segments.
`environment_object_destruct` → `environment_object_unregister` unregisters environment objects, updates
chain head/tail/count and clears registration before free. Visuals are
destroyed/cleared separately, proving collision and visual cleanup.

Standalone `ccFieldCtrl` belongs to its parent. `battle_owner_destruct` uses
`battle_owner_destroy_members` to dispatch `field_ctrl_destruct`/`game_object_ctrl_destroy_members`, reaching
member-field destruction before controller release.

State 16 (`battle_state_exit`) destroys graph/pause/fighter-pointer arrays via
`battle_state_destroy`/`battle_destroy_graph`; state 17 (`battle_state_release_archives`) releases
common/four-resource/stage/fighter/`n_rash` archives. States 23/24 also
destroy the graph first; 24 does so before release/switch.
**Graph before archives** is established for orderly/switch paths
([Battle lifecycle](../session/battle_lifecycle.md#teardown-order)).

Emergency order differs: `battle_controller_destruct`/`battle_record_controller_destruct` call central
`battle_cleanup_resources` resource cleanup before conditional graph destruction.
They may normally see null; if still live, static order is **archives before
graph**. Orderly teardown is not a universal emergency guarantee.

Control/scene handles are borrowed; centralized `stage_archive` is
destroyed/cleared. `ccs_find_container`/`ccs_require_container` strip directory/final
extension to a basename stem and traverse `ccs_container_head` without count
increment. `ccs_destroy_container`(handle,1) unlinks the exact node, invalidates
`#` dependencies in remaining nodes (sentinel 4/metadata clear/dirty
propagation), destroys children/container and frees it.
This is full destruction after borrowed lookups.

## Other retail games compared with NA2

[NUN3 battle stages](nun3_stages.md) owns retail archives, compiled scene
records, summon scenes and comparison.
[Stage content shared with NA2](nun3_stages.md#stage-content-already-shared-with-na2)
lists reuse.
[NUN4 battle stages](nun4_stages.md) owns its archive comparison, scene
formats, stage data, soundtrack and Stage Select assets.

## Address index

### BTL functions

`@annotations/NA2/BTL.BIN` owns named stage/archive, field/background,
line/navigation and class routines. Query a name through NA2 MCP for live
entry/code.

### Resident lifecycle and scene functions

`@annotations/NA2/SLPS_258.37` owns lifecycle/resource/scene/rendering/
combat consumers; shared layouts are in `@annotations/NA2/types.h`.
Resident globals and the render descriptor's per-member aliases are named in
the same resident annotation file.

## Remaining questions

- Find semantic cached-line readers and active-index writers beyond the
  audited direct/alias paths, including arithmetic/partial accesses.
- Establish original rendering-coefficient semantics and name surface-variant materials.
- Decode unexamined factories and numeric route/effect meanings.
- Establish scene-factor writers/restriction/effect/surface semantics without
  converting local updates to elapsed-time units.
- Bound indirect callers/construction and contextual stage-hit HP deltas.
