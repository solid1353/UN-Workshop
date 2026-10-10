# Target selection and locking

This document describes target selection and retention in retail NA2
(`SLPS-25837`).

## Research coverage

Established: paired geometry, collision provenance and ordering, copied recovery
provenance, skill locks, support points, and pickup side selection and recheck.
Open: exhaustive pointer writers, indirect callbacks, other skill cancellation,
whole-program lifetime safety, and concrete reads beyond the copied prefix.
Names and fields come from `@annotations/NA2`; comments hold routine detail.

Related owners: [Battle AI](../session/battle_ai.md#primary-target-and-spatial-classification)
owns AI opponent binding and navigation points;
[Projectile motion](../projectiles_and_items/projectile_motion.md#homing-target-data-and-the-delayed-strategy)
owns steering; [Battle entities](../session/battle_entities.md#initial-cross-reference-graph)
owns allocation and the initial reciprocal graph;
[Battle item inventory](../projectiles_and_items/battle_item_inventory.md#field-pickup-object-lifecycle)
owns pickup lifecycles; [Hit response](hit_response.md) and
[Extra Hit](extra_hit.md) own response and exchange rules.

## Evidence and address conventions

Addresses below are live. Binary identities and mappings are in
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
Static instructions establish the bounded paths here. Missing direct xrefs and
incomplete function recovery do not establish whole-program exclusions.
Fighter field names follow verified raw offsets and the saved declaration;
some current decompiler expressions disagree with that layout.

## Paired opponent and geometry refresh

`fighter_refresh_opponent_geometry` (`0x002174A0`) uses `Fighter.opponent`.
A null link is replaced with self and the call returns with cached geometry
unchanged. With a nonnull link, the position source is:

| Gate | Position source | `target_section` |
| --- | --- | --- |
| `(state_flags & 7) >> 1 == 1` | Self position, shifted X by -500 for `response_facing == 1`, +500 for 0 | Own `section` |
| Other role, current-position mode | Opponent `position` | Opponent `section` |
| Other role, previous-position mode | Opponent `previous_position` | Unchanged |

The outputs are `paired_target_angle`, planar `opponent_distance`, full XYZ
`effect4a_distance`, and `opponent_vertical_delta`. `facing` changes only when
the absolute angle is strictly between `0.31415927` and `2.8274333`: positive
bearing writes 0, otherwise 1. These describe the retained pair's geometry.

`fighter_update_countdowns` refreshes current-position geometry before
pause/countdown handling and snapshots the current position near its end.
Relative placement refreshes after moving self, using the opponent's saved
position. Paired placement branches update both positions before refreshing
both, so each current-position lookup observes the other's resulting position.
The inspected resident and skill paths refresh geometry without acquiring a
new opponent; this does not cover every character-specific target path.

## Accepted-hit source boundary

`hit_route_accepted` (`0x002209A0`) treats `response_source` independently of
`opponent`. Mode 0 uses the paired fighter; modes 2 and 3 require a nonnull
retained source. Mode 1 also requires `GenericNode.live_marker == 0x474F`,
`node_kind == 1`, and `hit_mode1_check`. These are hit-provenance contracts.
Response, repeat-hit and countdown gates are owned by
[Hit response](hit_response.md#rehit-suppression).

### Collision candidates and routing order

`fighter_consume_collision_results` (`0x0021E700`) consumes existing collision
results. Unless `contact_flags & 1` is set, it clears `contact_attack_source`,
`contact_secondary_source`, `auxiliary_attack_source`, and
`auxiliary_secondary_source`, then consumes the primary and secondary query
lists' `result_mask` and `result_count`.

| Primary result mask | Retention and routing |
| --- | --- |
| `0x20` or `0x200` | Result bit 1; paired fighter in `contact_attack_source`; derive `contact_point` from matching contacts |
| `0x10` or `0x100` | Result bit 2; paired fighter in `contact_secondary_source` |
| `0x40` or `0x400` | Enumerate contacts; require live marker `0x474F`, kind 1 and `projectile_contact_admitted`; retain passing object in `response_source` and `contact_attack_source`, resolve its record, copy contact position |
| `0x100000` or `0x200000` | Enumerate kind-2 contacts; retain the passing object and its contact position through the same channels |

Both enumerating branches can overwrite an earlier passing candidate. Selection
therefore follows collection order, with no nearest-object ranking. The paired
action's `ActionRecord.flags & 0x08000000` together with `action_outcome == 1`
suppresses kind 2. For kind 1 it suppresses an actor whose `support_notify` is
nonzero or whose signed `external_id` is `0x27`. These are contact-routing gates.

`projectile_contact_admitted` (`0x007369A0`) normally returns the actor's
`contact_admission`. It returns zero instead when
`projectile_configs[config_index].contact_filter != 1`, the actor's `side_tag`
resolves a fighter and that fighter's paired link, and
`effect08_action_bank_allowed` succeeds for the paired fighter. It adds a
state gate without ranking targets or checking allocation generation.
Descriptor and tag meanings are owned by
[Projectiles](../projectiles_and_items/projectiles.md).

The secondary result path produces the auxiliary source channels and bits
`0x200`, `0x100`, and `0x400`; its kind-1 branch checks only the first contact
of the first registration. `hit_resolve_pair` arbitrates summaries and current
records, can promote `auxiliary_attack_source` into `contact_attack_source`,
and installs the paired fighter in `response_source` with its attack record
when ordinary result bit 1 survives.

`fighters_update` orders maintenance for every fighter, channel-1 callbacks
for every fighter, collision consumption for active fighters, then arbitration
and accepted-hit routing. Only side-bit-zero fighters initiate pair arbitration.
Bits 1, 8 and 4 route accepted-hit modes 0, 2 and 1; bit `0x100` invokes
`hit_attacker_landed`. Candidates thus exist before response eligibility is
applied. Shape queries and response rules have separate ownership.

### Retained-source writers and record lookup

Initialization clears both source channels. Collision setup clears
`contact_attack_source` while leaving `response_source` unchanged. Explicit
source/record routes and Extra Hit role reversal can replace both; their gates
remain attached to the owning routines' annotations.

`hit_lookup_record` (`0x00222B20`) resolves, in order:

1. cached `response_attack_record`;
2. non-kind-0 `response_source`, through `hit_source_record_get`;
3. non-kind-0 `contact_attack_source`, through the same getter;
4. `atk_dummy_record` (`0x00407C00`, the retail `PL_ATK_DUMMY`).

`hit_source_record_get` requires marker `0x474F`. Kind 0 uses the fighter's
current action only in major 8; kind 1 uses `transient_record_get`; kind 2
uses the opposite receiver side's current support record via
`support_record_get`. Null service results fall back to `atk_dummy_record`.
A retained source pointer and a retained attack record are separate contracts.

### Copied provenance and pointer lifetime limits

`response_enter_ordinary` maintains the separate `recovery_source` and
`recovery_record` channel. With source marker `0x474F`,
`fighter_status_suppressed == 0`, and `context_mode_word == 0`, a non-kind-0
source is copied into `embedded_node` and `recovery_source` points there.
Kind 0 retains the supplied source itself. `hit_source_copy` (`0x00221460`)
copies exactly 0x50 bytes, excluding the node's vtable and all pointed-to
allocations. This copy does not replace `response_source`.

`fighter_update_countdowns` refreshes this recovery channel only when
`status_flags & 1` and `state_flags & 8` are clear, the receiver marker is
`0x474F`, and both suppression predicates above return zero. It installs self
for kind 0 or a fresh self-prefix copy for another kind, pairs it with
`atk_dummy_record`, and samples grounded bit `contact_flags & 0x80` into
`recovery_grounded`. It leaves the contact source, response source, and paired
link intact. This gated refresh establishes no unconditional release or
object-removal notification.

The copy extent limits later-facing claims. `recovery1_motion` can pass a
nonnull non-kind-0 recovery source unchanged to `response_choose_facing`.
That router checks the marker, then uses `projectile_response_facing` for
kind 1 or `support_response_facing` for kind 2. The former reads
`Projectile.config_index` and, outside IDs `0x19` and `0x45..0x4A`,
`spawn_position`; the latter reaches `support_source_record_get`, which reads
`SupportObject.side` to select its separate record/point storage. Those fields
are outside the 0x50-byte prefix.

Kind dispatch from a copied prefix therefore does not establish that subsequent
reads are confined to that copy. Concrete producer/state reachability and the
values in later receiver storage remain unresolved. The evidence establishes
neither a stale-pointer failure nor a safe complete-object snapshot. Wider
actor and support behavior belongs to
[Projectiles](../projectiles_and_items/projectiles.md) and
[Support mechanics](../characters/support_mechanics.md).

`hit_lookup_record` reads the source kind before `hit_source_record_get` checks
its marker; neither checks allocation identity or generation. The bounded
direct-store audit establishes initialization zeroing of `response_source`,
while collision refresh can leave it unchanged. It excludes adjusted-base
aliases, bulk copies and other store widths. Dummy-record fallback does not
establish safe dereferencing of an expired source. Ownership/removal order
belongs to [Battle entities](../session/battle_entities.md), and graph scheduling
to [Battle lifecycle](../session/battle_lifecycle.md#per-update-dispatch).

## Skill participants and lock release

`opponent_lock_override` selects the attacker's paired fighter and requires
the attacker's current record to match that fighter's resolved hit provenance.
It searches for no alternative. Complete admission and presentation rules are in
[Ultimate Jutsu](../characters/ultimate_jutsu.md#start).

`jutsu_connection_cleanup` installs the attacker and paired target in
`FighterCoordinator.participants`, with the level in `local_word`, when
entering state 6. These are
[borrowed aliases](../session/battle_entities.md#derived-fighter-registrycoordinator).
`fighter_coordinator_set_state` resets `local_state`, `local_counter` and
`local_word`, retaining both participant pointers.

`jutsu_post_cinematic_update` (`0x0024ED40`) requires both participants and
the presentation-controller global `battle_pause_controller`. Its missing-input
branch resets the selector and local words but retains participant pointers.
Traced substates operate on the installed pair without selecting a replacement.
Initial handling sets both fighters' input-lock bit `state_flags & 0x80`.
`fighter_copy_input_outputs` then publishes zero logical input and stick
outputs and clears `bridge_output_age`.

Final local substate 4 increments `local_counter` and requires its previous
value greater than 30 and both participants' `contact_flags & 0x80` set.
Only then are the input locks and state-local words cleared and both participant
pointers released. The fighters' paired links remain. No allocation-generation
check appears in this handler; other interruption/destruction paths remain open.

## Separate side-index eligibility selector

Field pickups (`ItemData`, `ItemRecoverLife`, `ItemChakraBall`) retain
`ItemPickup.side`, initialized to -1, rather than a fighter pointer.
Their factory, admission wrappers, state dispatcher, collection continuation
and teardown belong to
[Battle item inventory](../projectiles_and_items/battle_item_inventory.md#field-pickup-object-lifecycle).

### Admission gate and selector body

`item_pickup_select_side` (`0x0070B840`) chooses:

| Input flags | Selection |
| --- | --- |
| Both `0x10` and `0x100` | Check both primary fighters with `fighter_participant_eligible`; retain the only eligible side, write -1 and return 0 if neither is eligible, or compare distances if both are eligible |
| Only `0x10` | Side 0, skipping this initial predicate |
| Only `0x100` | Side 1, skipping this initial predicate |
| Neither | Side 1 |

Both established admission wrappers require `flags & 0x110 != 0`; the final
row describes callable selector behavior outside those wrapper inputs.

`fighter_participant_eligible` rejects `state_flags & 0x80`, major 6, major-5
substates `0x42..0x49`, and nonzero `exchange_roles`. With both fighters
eligible, `rng_two_side_distance_select` (`0x00709FD0`) compares their current
positions to the pickup using full XYZ Euclidean distance. Equal distances
consume one `prng_inclusive(1)` draw: 1 chooses side 0, 0 chooses side 1.
Unequal distances choose the nearer side without a draw.

The selector resolves the retained index through `primary_fighter_get`; it
stores no fighter pointer. A later rejection transition clears the index
back to -1. Item resolution, inventory gates and terminal results belong to
the pickup lifecycle.

### Recheck before collection

`item_pickup_select_continue` (`0x0070B720`) saves the selector's byte result
and checks the retained side. -1 returns 1. A fresh null fighter lookup also
returns 1 without clearing the index. A nonnull fighter must pass
`fighter_participant_eligible`; failure clears the index and returns 1.
This recheck applies to single-side branches too, so their flags bypass only
initial ranking eligibility.

This pickup contract is separate from general combat eligibility. Its state
exclusions do not establish hurtbox invulnerability; see
[Hit response](hit_response.md#rehit-suppression).

## Support side selection and point retention

All 14 final factory tables share `buddy_substate_update` (`0x00889C10`),
their entry, departure and alternate-exit methods. Table identities and the
factory mapping belong to
[Support mechanics](../characters/support_mechanics.md#factory-variants-and-attack-completion).
The target contract therefore covers the whole final factory set.

Each common state-1 invocation resolves the owning fighter from
`BattleManager.fighters[side]` and the opposite fighter from
`fighters[(side + 1) & 1]`, using the signed `SupportObject.side`.
Waiting/following derives a point 120 X units toward the opponent from the
owning fighter. Approach compares opponent X separation with `reaction_range`,
then moves toward the opponent or starts attack reason 2. Motion and facing
survive; the resolved fighter pointer does not. The next invocation resolves
the side again, without list search or candidate ranking. These loads assume
a valid manager and nonnull primary slots.

`support_face_selected_side` (`0x0088B510`) selects the owning side for a
zero opposite argument and the opposite side otherwise. It compares selected
fighter X with support X, writes -pi/2 or +pi/2 to `facing_angle`, optionally
inverts it, and copies it to `node.orientation[2]`. Initial entry faces the
opponent without inversion. Entry also independently resolves the opposite
fighter when its side-record request selector is 1. Reaction range and motion
are derived values, with no retained fighter ownership.

`support_within_fighter_y_range` (`0x0088B980`) chooses the opposite side
for zero and the owning side otherwise, accepting absolute Y separation below
50.0. It neither checks hurtbox eligibility nor retains the fighter.

### Complete native attack-slot boundary

The nine distinct final native attack bodies establish:

| Routine | Target or point contract |
| --- | --- |
| `support_attack_common` | Shared completion dispatch, no fighter lookup |
| `support_attack_1e` | Newly crossed animation index 1 resolves the opposite fighter; X/Z derive `SupportElevationView.elevation`, clamped to ±0.47123894; no retained fighter pointer |
| `support_attack_21` | Resource/animation dispatch and local state, no fighter lookup |
| `support_attack_11` | Newly crossed index `0x5F` resolves the owning fighter and applies effects `0x0C` and 5 |
| `support_attack_0c` | The same owning-fighter effects at index `0x5A` |
| `support_attack_0a` | Retains an effect record validated by index, active byte and generation; transforms it from support position |
| `support_attack_19` | Creates/moves `SupportMovingPointView.local_position` and queries motion against a field, no fighter lookup |
| `support_attack_2b` | Local scalar and completion dispatch, no fighter lookup |
| `support_attack_3f` | Validates and advances a separately indexed/generation-checked effect record, no fighter lookup |

These effect pointers and retained points are separate from fighter targets.
Native-body exclusions do not cover animation-resource commands, indirect
effect callbacks or every emitted actor. Completion and lifecycle belong to
[Support mechanics](../characters/support_mechanics.md).

`support_spawn_transient` forwards the support side and supplied vectors to
`transient_actor_create`. The selector-`0x24` table
`support_variant_bdc0_vtable` instead uses `support_spawn_transient_scatter`,
which resolves the opposite fighter and derives a randomly offset point around
its current position, supplying that same point as both spawn vectors.
Both emitters configure copied scalar metadata without retaining a fighter
pointer. `generation` becomes actor `support_identifier`, with
`support_notify = 1`: this is
[support lineage](../session/battle_entities.md#non-owning-support-lineage-on-transient-actors).

The final tables' native auxiliary methods return availability, format resource
names, or attach resources to animations; none selects a fighter.
`support_handle_absent` returns whether `handle_50` is null, and the
selector-`0x2A` `support_available_2a` always returns 1.
