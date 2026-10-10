# Battle auxiliary services

## Research coverage

Static evidence establishes effect pools, individual registrations, skill record banks, phase gates, rate-following skill gates, handles, and deletion order.
Selected callbacks cover `ccEffDrawObj`, the skill bases, BlowWatch, Wall, and the cut-in controller; the producer and derived-class sets remain bounded.
All 166 primary interfaces in the audited resident interval have traced retirement-slot targets; the conditional common-action exit omits the auxiliary sweep.
Offset-gauge callbacks, cut-in child identities and producers, and remaining pooled delay, ownership, and completion writers remain open.
Direct-call and literal-address searches do not exclude indirect or computed callers; retail class names do not establish move names.
Routine, field, and data names come from `@annotations/NA2`; comments, prototypes, labels, and layouts live in `SLPS_258.37/symbols.tsv`, `BTL.BIN/symbols.tsv`, and `types.h`.

Retail NA2 (`SLPS-25837`) creates the resident `ccEffectManager` and the
BTL `ccSkillCtrl` for each battle session. This document owns their record
lifetimes and the ordering constraints between callbacks and deletion.
Session construction, dispatch order, and teardown belong to
[Battle lifecycle](battle_lifecycle.md).

## Address convention

Addresses identify live resident ELF or BTL locations, following
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
The resident service pointers are `effect_manager_global` for `ccEffectManager`
and `battle_input_phase_override` for `ccSkillCtrl`.
Named routines, tables, and fields below refer to the NA2 annotations.

## Resident effect-manager callbacks and ownership

`battle_auxiliary_create` creates the effect manager, and
`effect_manager_construct` with `effect_manager_setup` establishes its two
ownership groups: embedded pool controllers and individually registered
objects. `EffectManagerView.controllers` and `controller_count` describe the
controller list; `records` holds the separate individual registrations.

| Manager field | Retail controller | Allocation |
| --- | --- | --- |
| `draw_pool` | `ccEffDrawObjWorkCtrl` | `effect_draw_pool_allocate` allocates `0x200` records. |
| `hit_mark_pool` | `ccEffHitMarkWorkCtrl` | `effect_hit_mark_pool_allocate` allocates `0x34` records in seven resource groups. |
| `illustration_pool` | `ccEffIllustCharWorkCtrl` | `effect_illustration_pool_allocate` uses 21 count/resource rows. |

All three controllers own arrays of `0x210`-byte `WrappedScenePlayback`
records, constructed by `wrapped_resource_construct` and destroyed by
`wrapped_resource_destruct`. Their names identify retail subtypes without
classifying every resource or producer. The corresponding resource rows,
RTTI, names, and tables are annotated alongside the allocation routines.

The shared pool passes walk `EffectPoolController.head` through each record's
`next` link. Their gates and order differ:

| Pass | Eligibility and work |
| --- | --- |
| `effect_pool_phase1` | Requires `update_enabled`. A negative `signed_offset` becomes its absolute value and skips this callback; a positive value decrements. The first record callback runs when the resulting value is zero. |
| `effect_pool_phase2` | Requires `draw_enabled` and an absolute `signed_offset` of zero. It selects the manager view using `support_mode`, then invokes the draw callback. |
| `indexed_effects_update` | Requires `update_enabled`. It invokes the third callback only when the absolute `signed_offset` is zero, then independently checks `removal_flags & 1`. A delay can suppress the callback without suppressing removal. |

Pool removal calls `indexed_effect_release`, clears `occupied`, and unlinks
`previous` and `next`; the record allocation remains available for reuse.
An update-disabled record skips this removal pass too. `effect_pool_destroy`
instead destroys the complete array and clears `records`, `head`, and
`capacity`. The shared third pass therefore owns resource retirement as well
as callback dispatch. Its removal behavior differs from the graph's generic
third-phase walk.

Individual registration uses `EffectManagerView.records`, a bank of `0x300`
`RegisteredEffectRecord` entries. `effect_manager_insert` searches from either
end, stores the object and a nonzero serial, sets the object's manager,
index, and serial, and can publish an `(index, serial, pointer)` handle.
`registered_reference_resolve` requires the saved pointer, record pointer,
record serial, and object's current serial to agree. A pointer alone cannot
establish handle validity. That helper does not itself check index bounds;
this evidence does not establish every producer's lifetime.

`effect_manager_phase1` destroys individually registered objects marked for
removal and clears their records. `effect_manager_clear_records` destroys
all remaining individual objects during teardown; `effect_manager_destruct`
then cleans the pool arrays. These paths delete individual objects through
their own destruction interface, independently of pooled unlinking.

`effect_resource_third_pass` also has different eligibility from the pooled
third pass: it requires an update-enabled individual object with no removal
request and invokes its third callback without its own delay check.
Other individual effect classes and every producer remain unclassified.

The concrete pooled record is `ccEffDrawObj`, represented by
`WrappedScenePlayback`. `wrapped_player_update` binds transforms and advances
model/animation state; `wrapped_resource_submit` submits its selected model
or sprite; `wrapped_resource_bookkeeping` requires a nonnull `resource` and
advances configured fade, scale, texture-frame, rotation, and translation
state. Countdown and completed nonlooping playback can request retirement.
Animation and resource bookkeeping thus span both update passes.
Submission details belong to
[Render submission](../../runtime/rendering/render_submission.md).

## BTL skill-service callbacks and ownership

`interaction_manager_allocate` and `interaction_manager_init` create
`ccSkillCtrl`. `InteractionManager` separates two primary registrations,
two banks of 32 auxiliary registrations, embedded `cutin`, and an embedded
`ccSklOfstGauge` interface. The offset-gauge callback semantics remain open.
The retail names and resident interfaces are recorded in annotations.

`interaction_register_primary` registers only into an empty selected primary
entry. It writes `BtlSkillPlayback.manager` and `registration` as
`(side, serial, self pointer)`. `interaction_register_auxiliary_descending`
and `interaction_register_auxiliary_ascending` search an auxiliary side bank
from the back or front, using `CollisionSkillAuxiliary.side`. They write its
`registry` tuple and can return the same tuple to the caller. Primary and
auxiliary registration use separate serial counters; the primary path skips
`-1`, while zero is permitted. This bounded evidence does not recover every
producer or copied-handle lifetime.

`skill_primary_construct` establishes the `ccSkill` base. The service's
primary dispatch contract is:

| Callback | Service eligibility and position |
| --- | --- |
| `skill_primary_input_callback` | Phase 1; primary `retirement_flags & 3` must be zero. |
| `skill_primary_draw_callback` | Phase 2; the same retirement gate applies. |
| `associated_primary_descriptor_transfer` | Phase 3; the same retirement gate applies. |
| `skill_primary_voice_callback` | Called for every nonnull primary after the phase-3 auxiliary pass. |
| `skill_primary_final_noop` | Empty base callback in the final wrapper pass, for every nonnull primary. |

The voice callback delegates to `dialogue_voice_consume`, whose
`associated_fighter` admission begins with `downed_override_allowed`. That
resident helper establishes only nonnull actor/session pointers at this
boundary. The voice behavior belongs to
[Battle audio](battle_audio.md).

Base phase 3 enters `skill_primary_late_callback` when `transfer_blocked` is
zero. It invokes the late hook and, when `late_sequence_flags & 1` is set,
invokes the sequence callback and increments `late_sequence_count`. Later
base work conditionally addresses the fighter-override bank.
`skill_tyo_base_construct` installs the derived `ccSkillComboBase` table;
its `skill_combo_phase3` checks the authored descriptor, dispatches the
selected callbacks, consumes `SkillComboServiceView.pending_callback`, then
calls the base phase-3 method. The empty base final callback does not establish
that derived late work is empty. The service's final wrapper still marks
retirement states and performs separately owned combo maintenance.
Contribution and flush semantics belong to
[Combo accounting](../combat/combo_accounting.md).

`skill_auxiliary_construct` establishes the `ccSkillObj` base, while
`skill_dummy_player_construct` establishes `ccSkillDmyPlayer`. Two traced
registered examples are `ccSkillPlayerBlowWatch` and `ccSkillHKG001Wall`,
joined to their registrations by
`skill_auxiliary_register_ascending_call` and
`skill_auxiliary_register_descending_call`. These identify internal classes
without assigning a move name.

Both examples retain the shared service wrappers:

| Wrapper | Eligibility and ordering |
| --- | --- |
| `skill_auxiliary_phase1` | The ordinary path requires `update_flags & 2`. It refreshes `primary_header` and `secondary_header` before the path split. Fractional stepping or `submission_pause` can set `update_control & 1` to suppress ordinary late work. |
| `skill_auxiliary_phase2` | Requires `update_flags & 4`; `alternate_update_flags & 1` selects the alternate draw callback. |
| `skill_auxiliary_update_banks` | Ordinary late work requires `update_flags & 2` and `update_control & 1` clear. It services both bindings before the class-specific late callback, handles pending contact state and `pending_record`, decrements a nonzero `retirement_countdown` and requests retirement when it reaches zero, then increments `phase_counter`. The alternate path invokes its alternate late callback and increments `alternate_phase_counter`. |

The pending-contact cleanup clears only the low byte of
`accepted_contact_flags`; the shared annotation retains the established
word-sized field. The service wrapper and the class-specific node callback
are distinct dispatch levels.

### Rate-following steps

Skill primaries and auxiliaries follow their fighter's `update_rate` by
skipping work rather than scaling it:

- `skill_primary_action_dispatch` adds the associated fighter's rate to
  `+0x1E4` when `+0x389` is set and the fighter is valid. Below 1 it calls
  only virtual `+0x140`, sets `+0x1E0` bit 0 and returns. Otherwise it clears
  the bit, subtracts 1 and runs its virtual chain and two halfword countdowns.
  `skill_primary_late_callback` skips its counted late work while the bit is
  set. `skill_primary_construct` sets `+0x389` to 1, and no other writer was
  found. Without a valid fighter the gate is skipped and the work runs on
  every call.
- Before that gate, the `+0xF06` bit 0 block advances the player at `+0x320`
  by its stored step on every call. `skill_owner_rate_probe` writes such
  steps as `256 * update_rate` of the owner, or 256 without one.
- `skill_auxiliary_phase1` adds `entity.update_rate` to `fractional_step`
  and sets `update_control` bit 0 below 1. An auxiliary with a nonnull
  `alternate_entity` bypasses the accumulator.

At a rate below 1, skill logic therefore runs on a subset of calls, while
rate-derived animation advances on every call by a smaller step.

The primary interface slots split by cadence. On every call
`skill_primary_action_dispatch` (slot `0x130`) runs slot `0x140`, and its
`+0xF06` bit-0 block steps the clip list at `+0xF2E`, advances the `+0x320`
player and calls slots `0x14` and `0x1E0`. Past the gate it runs slots `0x78`,
`0x84`, `0x180`, `0x174`, `0xD8`, `0xF0`, `0x114`, `0xF8` and `0x1D4`.
`skill_primary_late_callback` (slot `0x134`) calls `0x10C` and, with
`+0xF06` bit 0, slot `0x1E8` and the `+0xF08` count on every call; its counted
work follows the gate mark. `skill_primary_deactivate_queries` sets `+0xF06`
bit 0 after packet reconciliation, and `skill_kbw001_clash_outcome` clears it.

The shared slot-`0x140` routine `skill_primary_update_participant_motion`
writes the owner's and target's planar and vertical speeds (`+0x994`,
`+0x998`) from per-skill speeds and increments, scales the owner's increments
by `update_rate` only in mode 0, and calls `fighter_movement_pass`. Classes
write the `+0x320` step either as `256 * update_rate` (`skill_owner_rate_probe`,
`FUN_00791F30`, `FUN_007DADE0`) or as constant `0x100`. On the auxiliary side,
`skill_auxiliary_phase1` runs slots `0x1C` and `0x10` past its gate, and
`skill_auxiliary_update_banks` runs slot `0x18` only when the gate stepped.
An auxiliary with `alternate_update_flags` bit 0 instead runs slot `0x6C`
every call; two classes override it with a stored-step player advance.
The draw slots (`skill_primary_draw_callback` and auxiliary `0x68`/`0x70`)
call no advance or random draw directly.

`skill_blow_watch_late` checks `SkillBlowWatchView.retained_actor`, `mode`,
and the selected readiness flag before its actor calls and retirement
request. `skill_blow_watch_destruct` also continues through conditional
retained-actor flag writes, base destruction, and heap deletion.
`skill_hkg_wall_late` has a `phase_counter == 0x3C` retirement request,
a further node callback, and local queue/binding work. These selected
callbacks do not classify all bank members, resource ownership, or indirect
producers.

`skill_auxiliary_request_retirement` sets `status_flags` bit 0. The service's
final phase-3 wrapper marks any nonzero auxiliary status with bit 1. In the
next eligible phase 1, `interaction_manager_remove_update` calls
`interaction_registry_remove_marked` before ordinary record dispatch. That
routine deletes primaries with `retirement_flags & 2` and auxiliaries with
`status_flags & 2`, then clears their pointer/serial entries. This deferred
bank deletion is distinct from effect-pool third-pass unlinking and immediate
whole-service teardown.

### Conditional action exit and skill retirement

`action_exit_release_skill_control` (`0x00776A10`) reaches
`interaction_request_skill_retirement` (`0x00777AF0`). With a nonnull
fighter, only a primary with a valid association to that exact fighter
receives virtual slot `0x230`. A null fighter selects both primary entries.
A nonzero auxiliary argument additionally invokes slot `0x80` across the
selected side's 32 auxiliary slots, or both banks for a null fighter.
The common action exit supplies a nonnull fighter and argument zero, so
that path omits the auxiliary sweep. Its category/status admission is owned
by [Combat action execution](../combat/combat_action_execution.md#common-exit-boundary).

`skill_primary_request_retirement` (`0x00785D60`) sets retirement bit 0,
clears the first working header and deactivates its five query lists.
The audited resident interval `0x005E0900..0x005FB94F` contains 166 primary
interfaces selected by their shared activation/packet/tag slots: 158 use this
slot-`0x230` entry directly, and all eight overrides eventually call it.
SZN/Sk4 add query cleanup; TND repeats first-header cleanup; JRY clears a
linked motion class; HKG clears retained local slots. These calls request
deferred retirement rather than immediately remove bank entries.

Two overrides have additional surviving presentation. JRB can initialize
motion and a 90-count fade on a validated retained auxiliary, preserving that
child. JRV can create six particle generators at a model anchor before
requesting retirement and always dispatches sound `0x25`. Retirement is
therefore not an empty-effects guarantee. The per-class targets and guards
are recorded in their annotations; class names do not assign move names.

The outer release also clears `state_flags & 0x80` on both published primary
fighters and calls `skill_exit_release_side_handles` (`0x00336930`). That
leaf marks only validated retained side handles and clears their associated
side words; it performs no call, unlink or free. MCP exposes no function at
that entry, so its complete raw bytes were used and the entry is annotated
as a label. This bounded exit chain does not cover unrelated transient,
support, pooled-effect or fighter-owned child lifetimes.

### Cut-in ownership

Cut-in state has another lifetime boundary. `cutin_stage_record` accepts a
primary handle only when its side is `0..1` and its serial and pointer match
the service's primary entry. It copies the tuple into the selected
`CutinController.side0` or `side1`, using the associated fighter's
`control_flags & 1` to select the side. `cutin_update` revalidates the handle
and resets selected side state when it becomes invalid. The cut-in flag's
update-mask effects belong to
[Pause and replay](pause_and_replay.md#auxiliary-btl-global-and-the-0xa50-override).

The separate `CutinController.children` bank has four entries per side and
three phase callbacks per child. Phase 1 deletes a child with
`removal_flags & 1` through its destruction interface and clears its entry.
`cutin_insert_child` fills the first empty selected-side entry, succeeding
with `1` or returning `0` when full. Bounded direct-call and literal-address
searches found no concrete producer; indirect or computed producers remain
possible. Original child class names and all derived targets remain open.

`interaction_registry_clear` invokes each primary's pre-destruction callback
and primary destruction interface, destroys auxiliaries through their
separate interface, and clears the record banks. `cutin_destruct` resets side
state, destroys its nonnull children, releases `first_sprite` and
`second_sprite`, and tears down embedded arrays and contexts. Primary,
auxiliary, and cut-in-child deletion interfaces remain distinct.
General skill outcomes and authored events belong to
[Match outcomes](match_outcomes.md) and
[Ultimate Jutsu](../characters/ultimate_jutsu.md).

## Indexed effect pool (ccEffDrawObj)

`EffectManagerView.draw_pool` lends records through generation-checked
handles. Its owner and passes are described in
[Resident effect-manager callbacks and ownership](#resident-effect-manager-callbacks-and-ownership).
Battle support objects are one traced consumer, covered by
[Support mechanics](../characters/support_mechanics.md#specialized-descendants-and-release-order).
The traced BTL pool owner is inferred to be this resident manager from its
address relationship, embedded controller, record stride, constructor, and
third-pass consumer; the calculation is retained in the pool-table annotation.

`indexed_effect_acquire` resets an unused record through
`wrapped_resource_reset`, links it into the active list, assigns a nonzero
generation, and publishes `(index, generation, pointer)`. It can also release
and reuse the current list head when the searched portion has no unused
record, replacing its generation. A held handle can therefore become invalid
while its holder still exists. Traced consumers require an in-range index,
a nonzero saved generation matching the record, and `occupied` set.
`indexed_handle_reset` writes `(-1, 0, 0)`. These checks protect the cached
record alone and do not validate other retained pointers.

`node_request_removal` sets `removal_flags & 1`; it neither destroys the
payload nor clears `occupied`. `effect_clear_removal_request` clears the bit
during reset. Pool update, draw, and signed-delay gates apply independently
of a consumer's own update flags.

`wrapped_resource_setup` with `(record, descriptor, 1, 0, 0, 0)` binds a
kind-1 animation player. `WrappedScenePlayback.kind` is a word-sized field.
`indexed_effect_set_step` writes the halfword playback step;
`indexed_effect_seek` seeks the animation. Submission publishes
`support_scalar` to the bound player's opacity before the model submission
helper. The exact field layouts and routine details live in annotations.

A traced consumer requests retirement through two concurrent mechanisms:

| State | Effect |
| --- | --- |
| `fade_in_count`, `fade_hold_count`, `fade_out_count`, `fade_phase` | `indexed_effect_set_fade(record, 0, 0, N)` selects phase 2. With `bookkeeping_mask & 4` set, bookkeeping subtracts `fade_upper / N` from `support_scalar` while it is at or below the upper bound, clamps at `fade_lower`, and selects phase 3 at the lower bound. This fade block itself does not request removal. |
| `retirement_requested`, `retirement_countdown` | The consumer separately sets `(1, N)`. With a nonnull payload, bookkeeping decrements a positive countdown and requests removal on the decrement reaching zero, before continuing through local fade calculation. |
| `removal_flags & 1` | The eligible pool third pass calls `indexed_effect_release` and unlinks the record. The payload-release handler runs and `occupied` clears, while the pooled allocation remains reusable. |

For an unchanged nonnull payload and eligible third callbacks, the `N`th
decrement requests removal. These are callback counts, rather than displayed
frames or seconds; they establish no minimum visible survival time.

Earlier removal can use the same interface. For kinds `1` and `4`,
`wrapped_player_update` advances playback while `complete` is clear and the
playback gate allows it. A later eligible call with `complete` set,
`looping` clear, and `retirement_enabled` set requests removal; looping
playback instead seeks and restarts. Pool pressure can recycle the record too.
Reset enables completion retirement, clears the countdown request,
completion, and countdown, and selects fade phase 3. Some writers of these
fields and the signed delay remain unaudited.

`wrapped_resource_release` obeys `owns_resource`. For owned kind-1/4
payloads it destroys `resource` and any `composition`, clearing both
pointers. For borrowed payloads it seeks and retains those allocations.
Construction sets ownership; acquisition reset and the traced kind-1 binding
do not rewrite it. Other ownership writers remain open, so clearing
`occupied` alone cannot prove payload destruction.

Whole-pool destruction calls `wrapped_resource_destruct` for the array
records. That destructor forces ownership before content release and does
not wait for a retirement countdown. Broader playback-child contracts belong
to [Scene playback owners](../../runtime/scene_playback_owners.md).
Particle-generator actions have a separate lifetime, owned by
[Effect-generator commands](../../runtime/effect_generator_commands.md#removal-and-reset-lifetime).
