# Awakening and transformation gameplay

## Research coverage

Established in retail NA2 (`SLPS-25837`): controller triggers and cleanup,
the 94 trigger/association rows, all 223 UJ records and 94 local/default
selections, the 12 effect/form replacements, effect persistence, reconstruction
ordering, and selected character parameter overrides. Open: visible timing,
class-7 skill-play outcome seeding, record 0's use, later indirect parameter
writers, and the identity of the earlier contest-type-0 observation. Donor
Ultimate Jutsu and power comparisons are in
[NUN3 and NUN4 characters](nun3_nun4_characters.md).

Routine, field and data names come from `@annotations/NA2`. Per-routine
details are in their annotation comments; addresses are live. BSS globals
belong to the resident ELF even when overlay code accesses them. Conventional
BTL-reference negatives do not exclude computed indirect calls.

The native implementation has three related, independent states:

1. the controller marker in `Fighter.contact_flags & 0x20`;
2. nodes in the fighter's effect list; and
3. for effects `0x68..0x73`, the current character identity and its resources.

An effect can exist without the marker; flag cleanup can leave the effect
alive. Reconstructed forms receive a protected effect by identity and can
adopt the marker independently of successful insertion. A single
`is_awakened` value would lose these distinctions.

Related owners: [Character identity](character_ids.md),
[Combo accounting](../combat/combo_accounting.md),
[Battle status effects](../projectiles_and_items/battle_items_and_status_effects.md),
[Damage](../combat/damage.md), [Ultimate Jutsu](ultimate_jutsu.md),
[Action commands](../combat/action_commands.md),
[Battle statistics](../session/battle_statistics.md),
[Battle lifecycle](../session/battle_lifecycle.md),
[Pause and replay](../session/pause_and_replay.md),
[Movement and physics](../stages/movement_and_physics.md),
[Character action callbacks](character_action_callbacks.md), and
[Hit response](../combat/hit_response.md). Adventure-mode and animation
internals are outside this scope.

## Evidence identity and address mapping

Inputs and address conventions are owned by
[Retail game file identities](../../game/files/file_identities.md#address-conventions)
and [Overlay ABI](../../runtime/overlay_abi.md#exact-clean-layouts).
The conclusions below distinguish proven behavior from inferred purpose and
unmeasured presentation. A matching store displacement alone does not identify
the object being changed.

## Resident ownership and the BTL boundary

Controller eligibility, associations, form mapping, requests and cleanup are
resident-owned. The bounded BTL scans found no ordinary direct or conventional
computed reference to the controller family, inherent-form constructor,
form mapper, request owner or the two awakening tables. This does not exclude
arbitrary indirect address computation.

BTL's `battle_create_primary_fighter` propagates the selected UJ class and effect into
fighter-construction metadata; `jutsu_presentation_update` reads category for
UJ presentation. Neither metadata propagation applies an effect nor requests
a replacement. BTL's 23 generic-effect entry calls have immediate IDs
`0,1,4,5,6,7,0x0C,0x0D`; its table-driven set is
`2,3,5,6,8,9,0x0C,0x11,0x12,0x3C,0x65`, with three dynamic wrappers.
No site explicitly constructs `0x68..0x73`; dynamic inputs are not range
proved. Its six exact-ID removals use `0,1,4,6,7,0x0A`.

Awakened Deidara `0x40` and Gaara `0x3B` set both
`BattleInput.sector_threshold_23/45` to 120 degrees through
`input_set_angle_thresholds`. Defaults are 90 degrees up/down and 150
degrees left/right. Relative to vertical:

| Sectors | Vertical only | Both | Horizontal only |
| --- | --- | --- | --- |
| Default 90/150 | within 15 degrees | 15..45 degrees | beyond 45 degrees |
| Awakened 120/120 | within 30 degrees | 30..60 degrees | beyond 60 degrees |

This widens up/down recognition by 15 degrees per side and narrows left/right
by the same amount. Fixed logical bits `0x10..0x200` are unchanged.
`input_reset_angle_thresholds` restores defaults. The interpreter and its
other consumers are owned by [Action commands](../combat/action_commands.md#logical-mask).

The input bridge precedes `awakened_vertical_input`, which runs after
`awakening_dispatch` in the movement slot. For marked Deidara/Gaara it changes
`response_vertical_speed`, later consumed as vertical displacement by
`fighter_apply_movement`. Majors 6 and 8 leave it untouched. Major 1, or
major 0/substate 0 or 4, accepts logical up `0x04` before down `0x08`.
Downward and neutral handling clear `next_gravity`; neutral handling approaches
zero without crossing it. The two `AwakeningAltitude` records are:

| Record field | Gaara `0x3B` | Deidara `0x40` |
| --- | ---: | ---: |
| `upward_increment`, upward increment | `12.5` | `4` |
| `downward_increment`, downward increment | `-3.75` | `-4` |
| `upward_limit`, upward limit | `20` | `20` |
| `downward_limit`, ordinary downward limit | `-22.5` | `-20` |
| `substate_four_downward_limit`, substate-`4` downward limit | `-2` | `-2` |
| `return_increment`, ordinary return increment | `1.25` | `3` |
| `major_four_return_increment`, major-`4` positive-velocity return increment | `1.5` | `2` |

No time or distance unit is established. For these marked identities,
`fighter_consume_logical_input` bypasses the ordinary held-up transition
`(0,0)->(0,3)` and held-down transition `(0,0)->(0,4)`. The widened sectors
therefore feed direct ascent/descent. Alternate attack signatures use fixed
logical bits `0x10/0x20/0x100` for direction contributions
`0x200/0x400/0x4000`; variable-sector widening does not generate those
contributions.

### Pause-controller gate

The live pointer `battle_pause_controller` owns the pause controller, whose
signed lifecycle byte is `0` inactive, `1` construction pending or `2` child active.
`awakening_dispatch` permits descriptor work with no controller, lifecycle
0, or tolerated sentinel -1, and suppresses it in 1/2. This coordinates
presentation; it does not represent an awakening resource or persistent form.
Ownership is in [Pause and replay](../session/pause_and_replay.md#shared-ownership-and-controller-lifecycle).

## Controller tables and fighter state

### Association table

`awakening_associations` has 94 `AwakeningAssociation` entries. Count zero
means no association; count one uses the inline ID; larger counts use the
ushort array. Presence, class-7 membership, ordinary selection and
reconciliation share this table. Association membership does not prove a
native trigger reaches the effect.

### Trigger descriptors

`awakening_triggers` has 94 `AwakeningTrigger` entries. A nonnegative
`presentation_selector` is passed to `fighter_request_descriptor_event`
after ordinary entry; every active nonnegative value is `0x1F`, whose
gameplay meaning remains open. Active -1 rows are
`2E,3B,3D,3E,43,44,46,47,4D,50,51,54`; every reserved byte is zero.

| Bit | Route or predicate | Clean rows |
| ---: | --- | --- |
| `0x01` | Adopt an already-present or constructor-owned state through `input_sector_widen_state_a` | Used alone and in combinations |
| `0x02` | HP `<= 0.15`, only Classic Hinata `0x0C` and Sasori (Hiruko) `0x4C` | `0x0C`, `0x4C` |
| `0x04` | Character-specific counter threshold | Classic Tenten `0x0D`, Tenten `0x42` |
| `0x08` | Native current-combo threshold through `awakening_combo_threshold` | `0x06`, `0x3C`, `0x41`, `0x48`, `0x56` |
| `0x10` | Raw fighter-state predicate through `fighter_action_progress_gate` | Broad ordinary-trigger family |
| `0x20` | A Sakura-only branch exists in code | No clean descriptor uses it |
| `0x40` | Exact selected class-7 UJ effect through `awakening_enter_class_seven` | `0x0A`, `0x0B`, `0x27..0x2B`, `0x55` |

The complete nonzero retail flag groups are:

| Flags | Character IDs |
| ---: | --- |
| `0x01` | `01..04`, `0E`, `0F`, `16`, `22..26`, `2F..39`, `3F`, `49`, `4B`, `5A`, `5D` |
| `0x02` | `4C` |
| `0x03` | `0C` |
| `0x04` | `42` |
| `0x05` | `0D` |
| `0x08` | `3C`, `48`, `56` |
| `0x09` | `06`, `41` |
| `0x10` | `07`, `10`, `12`, `13`, `3A`, `3B`, `3D`, `3E`, `45`, `47`, `4D`, `4E`, `4F`, `51..54`, `59` |
| `0x11` | `05`, `11`, `2E`, `40`, `43`, `44`, `46`, `50`, `57`, `5B`, `5C` |
| `0x40` | `0A`, `0B`, `27..2B` |
| `0x41` | `55` |

The hard-coded helpers still matter: bit `0x01` alone does not make every row
adoptable, and bit `0x20` has no retail row.

### Relevant fighter and manager fields

The fixed-width fields are named in `Fighter`, `BattleInput`,
`BattleCharacterSlot`, `BattleConfiguration`, `BattleManager`,
`TimelineBlock`, `NativeCombo`, `BattleTopPanel`, and the awakening record/node
types. The key ownership is:

| State | Field |
| --- | --- |
| Update enable | `node_flags & 0x02` |
| Ordinary-controller suppression | `status_flags & 0x01` |
| Deidara/Gaara paired special state | `contact_flags & 0x10` |
| Controller marker | `contact_flags & 0x20` |
| Live form and normalized HP | `character_id`, `hp` |
| Selected class-7 effect | `selected_jutsu_effect` |
| Authoritative effects | `effect_count`, `effects`, `effect_tail` |
| Historical cache | `last_effect_id` |
| Item/projectile counter | `item_projectile_count` |
| Accepted hits awaiting combo consumption | `pending_combo_hits` |
| Current/pending identities | `BattleManager.current.sides[].character_id/pending_character_id` |
| Match-start identities | `BattleManager.saved.sides[].character_id` |

The list is current truth. `last_effect_id` initializes to -1, changes only
after successful insertion, and is never cleared by removal; its reader
cross-checks the list. Side selection uses the low bits of the halfword
starting at `control_flags`. The re-entry barrier uses each top HUD panel's
`transition_selector` and `child_draw_suppressed` fields.

## Per-fighter dispatch

With update enable set, the movement slot runs `awakening_dispatch` before
the remaining fighter maintenance. Dispatch order is:

1. Apply root suppression, except for marked Deidara/Gaara.
2. Apply the pause-controller gate. Suppression clears ordinary markers but
   preserves `0x2F..0x38,0x49,0x4A,0x4B,0x51`; Deidara/Gaara cleanup also
   restores their special flag and command sectors. No effect is removed.
3. Try descriptor `0x40` first. Class-7 success credits bookkeeping and exits;
   failure falls through.
4. Reconcile an already-marked fighter and exit.
5. Try `0x01` adoption, then combine successful `0x02..0x20` predicates;
   any accepted ordinary trigger enters `input_sector_widen_state_b`.

### Already-present and constructor-owned adoption

`input_sector_widen_state_a` accepts these live effect pairs:

| Character ID | Effect presence accepted |
| ---: | --- |
| `0x05` | `0x11` |
| `0x06` | `0x12` |
| `0x0C` | `0x18` |
| `0x0D` | `0x19` |
| `0x0F` | `0x1B` |
| `0x11` | `0x1D` |
| `0x16` | `0x21` |
| `0x2E` | `0x37` or `0x38` |
| `0x40` | `0x41` |
| `0x41` | `0x42` |
| `0x43` | `0x45` |
| `0x44` | `0x46` |
| `0x46` | `0x49` |
| `0x50` | `0x52` |
| `0x55` | `0x58` |
| `0x57` | `0x5B` or `0x5C` |
| `0x5A` | `0x5E` |
| `0x5B` | `0x5F` |
| `0x5C` | `0x62` |
| `0x5D` | `0x63` or `0x64` |

Except `0x57`'s `0x5C`, every accepted effect is in the character's own UJ
records and adopts a [post-UJ outcome effect](#post-uj-outcome-effect).
Transformed identities `0x2F..0x38,0x49,0x4A,0x4B` succeed by identity
without a list check.

Base `01..04,0E,22..26` have no associations. Naruto `39` and Sasori `3F`
have `72/73` associations but no adoption case. Sasori form `4B` has inline
`73` with count zero, ignored by association readers, yet adopts by identity.
The constructor-owned -2 node is therefore not the reconstructed marker's
entry prerequisite.

Adoption sets the marker. Transformed adoption reads result metric 10; a
nonzero value skips another event-6 credit but still increments local
statistic 17 through `stats_increment`, unless root suppression blocks it.
Ordinary/class-7 entry credits both. **Inference:** the metric check prevents
duplicate event credit on reconstruction; it does not prevent a new local
statistic increment. Statistics are capped at 9999 with a running maximum.

The shared re-entry phase `battle_continuation_phase` progresses:

| Phase | Meaning |
| ---: | --- |
| 0 | Ordinary setup; initial BSS, no resident zero writer found |
| 1 | Replacement or alternate re-entry requested |
| 2 | Identity/resources prepared; controller/fighters await reconstruction |
| 3 | Reconstruction attempted; allocation success is not implied |

Route `8` uses variant `battle_continuation_route`: 1 selects state `0x17`,
2 selects `0x18`. The phase is shared with the alternate route; direct writers are
resident. `battle_reentry_ready` returns 0 outside phase 1, 2 while allocated
and ready side masks differ, and 3 once all allocated sides are ready.
Its handshake selects top-panel transition 0 once and waits for nonzero
`child_draw_suppressed`.
Controller allocation clears result rows outside phase 2, preserves them
during phase 2, and advances to 3 even outside its allocation-success branch.

Deidara's accepted `0x41` effect also establishes the paired special flag
and 120/120 command sectors; cleanup restores defaults.

### Proven HP and counter prerequisites

Descriptor HP entry is limited to Classic Hinata `0x0C` and Sasori (Hiruko)
`0x4C` at `hp <= 0.15`. There is no universal HP or chakra prerequisite.

Classic Tenten `0x0D` requires `item_projectile_count >= 25`; Tenten `0x42`
requires 40. The signed halfword counts accepted item uses and successful
projectile/resource creations. It has no clean resident decrement or cap.
Common initialization zeroes it, threshold acceptance resets it before entry,
and marked Tenten reconciliation holds it at zero.

Generic item use requires metadata kind 3/6 with flag `0x10` clear
(82 of `0x00..0x73` rows; `0x27` is the sole kind-3/6 exclusion), the zero
`item_action_blocker`, and the secondary acceptance predicate. Classic
Tenten creates resources `0x34/0x35/0x11`; Tenten creates `0x50/0x23`.
Their callbacks increment only when BTL returns a non-null object. This
counter is not chakra.

`awakening_combo_threshold` instead uses the native current combo:

| Character | ID | Required current combo |
| --- | ---: | ---: |
| Asuma | `0x56` | `10` |
| Kisame | `0x48` | `15` |
| Neji | `0x41` | `30` |
| Kankuro | `0x3C` | `20` |
| Classic Neji | `0x06` | `15` |

The object and its signed `NativeCombo.current` count belong to
[Combo accounting](../combat/combo_accounting.md#resident-owner-and-update-order).

### Raw state predicate

The ordinary progress trigger requires `major_state = 0`, `substate = 3`,
`phase = 2`, zero `action_progress_blocker`, and a successful
`timeline_event_crossed` on `secondary_timeline`. Its position is 6 for
Deidara and 0 for every other retail row. Position 0 succeeds only at the
enabled exact integer boundary; nonzero events can also succeed in the
crossed/projected interval. `timeline_secondary_event_crossed` uses independent
crossing bit `0x02` for class-7 entry at event 0.

These are action-progress positions, not resource quantities. The dormant
descriptor `0x20` branch uses Sakura `0x3A` and position 0, but no retail row
enables it. Exact visible timing remains open; the tracker contract is in
[Timer primitives](../../runtime/timer_primitives.md#event-and-interval-predicates).

### Deidara and Gaara character variants

The marker, associated effect, altitude control and character variant have
separate gates. Variants switch animation arrays and working action categories:

| Character | Mode byte | Ordinary enabled partition | Alternate enabled partition |
| --- | ---: | --- | --- |
| Deidara `0x40` | `DeidaraVariant.mode` | restore source categories for slots `21..41`; zero `42..45` | zero `21..41`; set `42..45` category `1` |
| Gaara `0x3B` | `GaaraVariant.mode` | restore source categories for slots `21..43`; zero `44..47` | zero `21..43`; restore source categories for `44..47` (all `1`) |

Slots below 21 are unchanged; source alternate rows begin disabled in the
working arrays. Deidara's ordinary constructor initializes mode 0. Its callback
selects mode 1 by association presence and mode 0 by absence, independently of
the marker; a successful mode-1 switch applies the scaled vertical helper
with `20.0,1.0`.

Gaara with a marker retains the variant while effect `0x3B` is present and
requests mode 0 when it disappears. Without a marker, an existing mode 1 first
resets; a phase-1/event-47 progress gate with exact-current permission can then
select mode 1, emit its BTL presentation and apply the same vertical helper.
That gate precedes the common phase-2/event-0 controller trigger.

Both setters change only on a different mode request and defer while the
effective action index is 6; that is not a major-state-6 check.
`DeidaraVariant` and `GaaraVariant` name their mode and animation-storage
fields. Their working movement parameters are:

| Character / field | Ordinary | Alternate |
| --- | ---: | ---: |
| Deidara `ground_target` | `20` | `30` |
| Deidara `ground_acceleration` | `0.25` | `0.3125` |
| Deidara `ground_braking` | approximately `0.3` | approximately `0.375` |
| Gaara `ground_target` | `16` | `25` |
| Gaara `ground_acceleration` | `0.25` | `0.3125` |
| Gaara `ground_braking` | `0.25` | `0.125` |
| Gaara `first_jump_height` | `350` | `200` |

Deidara's alternate multipliers are `1.5/1.25/1.25`; Gaara restores its own
ordinary defaults. Shared target/acceleration/braking/jump meanings are owned
by [Movement](../stages/movement_and_physics.md#character-movement-parameters).
Alternate records still pass signature, state, continuation and action
validation; a category of zero excludes them.

### Choji's marker-selected parameter override

Choji `0x51` copies ground target 13.5 from `choji_character_record`, but his
constructor primes mode 1 and forces mode 0. That overwrites the copied target
with 16.0 from `gaara_ground_defaults`; the shared source is established,
its reason is not. The callback selects mode from the controller marker:

| Requested mode | `ground_target` | Working action categories | Action `0x13`'s `ChojiActionPayload.mode_value` |
| ---: | ---: | --- | ---: |
| `0` | `16.0` | Restore source slots `0x15..0x2A`; zero `0x2B..0x37` | `80.0` |
| `1` | `25.0` | Zero slots `0x15..0x2A`; restore source `0x2B..0x37` | `150.0` |

The mode comparison avoids repeated partition/parameter writes. Returning to
mode 0 may cancel an action with flag `0x200`, or `0x100` with
`action_outcome = 1`. Effective action index 6 invokes direct size targets
`3.0,0,0,0` before the comparison even when mode matches, and does not defer
the mode change. This is separate from generic effect aggregation.

A separate `0x54` presence test controls later contact/presentation work,
not this mode. Flag cleanup can therefore request target 16 while the node
survives. The setter changes neither the four damage/resource parameters below
nor acceleration, braking or first-jump height. Static order does not establish
visible timing; the action-row value's units remain open.

## Entry paths

### Ordinary controller entry

`input_sector_widen_state_b` requires the side awakening gate to be zero and
normally selects the first association, with these retail exceptions:

| Character ID | Selection or pre-entry behavior |
| ---: | --- |
| `0x5D` `[0x63,0x64]`, `0x5C` `[0x61,0x62]` | Return if the second effect is present; otherwise select the first |
| `0x5B` `[0x5F,0x60]`, `0x57` `[0x5B,0x5C]`, `0x55` `[0x58,0x59]`, `0x50` `[0x52,0x53]` | Return if the first effect is present; otherwise select the second |
| `0x4D` | Remove constructor-owned `0x4D`, then apply associated `0x4E` |
| `0x40`, `0x3B` | Set special bit `0x10`, call `input_set_angle_thresholds`, then continue with `0x41` or `0x3B` |
| `0x45` `[0x47,0x48]` | If already marked awakened, stop at `0x48`; replace `0x47` with `0x48` |
| `0x19` | Remove `0x22`, then apply associated `0x24` |
| `0x2F..0x38`, `0x49`, `0x4A`, `0x4B` | Set controller bit `0x20` and return without constructing an effect |

The tail applies the effect with lifetime -1, sets the marker, credits event 6
and statistic 17, then optionally performs descriptor and positional
presentation outside the alternate state.

No insertion status is checked. Missing container ownership, a protected
duplicate or null allocation/factory can reject insertion while the marker
and bookkeeping still execute. A replaceable duplicate is removed before
allocation, with no restoration on failure. Classes 1/2/3 bypass the ordinary
root eligibility gate.

If the list has no associated effect afterwards, the next unsuppressed marked
pass clears the marker and Deidara/Gaara special/sector changes. A protected
duplicate already present is different: rejection leaves the association alive
and does not imply marker cleanup. Failure frequency is not established.

### Exact class-7 UJ entry

`awakening_enter_class_seven` requires major 8, a current record with category
`0x00F00000` and flag `0x00010000`, a successful current-record lookup,
phase 2 and secondary event 0. It removes associated IDs below `0x68` with
reason 1, applies `selected_jutsu_effect` at lifetime -1, then checks
membership. A match sets the marker and returns success; mismatch only clears
flags and returns failure.

The retail class-7 selections are:

| Character | Class-7 record index: key -> effect | Association | Result |
| --- | --- | --- | --- |
| Haku `0x0A` | `22/0x16`: `3 -> 0x15` | `[0x15]` | Match |
| Zabuza `0x0B` | `25/0x19`: `3 -> 0x16` | `[0x16]` | Match |
| Yellow Flash `0x27` | `75/0x4B`: `2 -> 0x2C`; `77/0x4D`: `1 -> 0x2D` | `[0x2C,0x2D]` | Both match |
| Konohamaru Squad `0x28` | `78/0x4E`: `2 -> 0x2E`; `79/0x4F`: `3 -> 0x2F` | `[0x2F]` | Record `78` mismatches |
| Hanabi `0x29` | `81/0x51`: `2 -> 0x30`; `83/0x53`: `1 -> 0x31` | `[0x30,0x31]` | Both match |
| First Hokage `0x2A` | `85/0x55`: `3 -> 0x32` | `[0x32]` | Match |
| Second Hokage `0x2B` | `87/0x57`: `2 -> 0x33`; `89/0x59`: `1 -> 0x34` | `[0x33,0x34]` | Both match |
| Shizune `0x55` | `195/0xC3`: `3 -> 0x58` | `[0x58,0x59]` | Match; no class-7 record yields `0x59` |

UJ selection starts at the default and substitutes a category/key match from
the character-local list. The tier keys are `2,3,1`. Konohamaru's key-2
record 78 applies `0x2E`, then mismatches association `0x2F`. The other 11
class-7 records in these eight lists match.

`konohamaru_mismatched_effect` is class 1, generic, flags 2, lifetime 600,
with attack and defense factors approximately 1.1. Its positive lifetime ticks
once per eligible countdown update. The folds depend on live node/lifetime,
not the marker, so a sole surviving node can still contribute approximately
1.1 attack and 1.1 defense (approximately 0.9 incoming factor when enabled).
No on-screen name or presentation is established.

Konohamaru's descriptor is only `0x40`; neither adoption nor an ordinary
trigger restores the marker, and failure skips success bookkeeping. Repeated
qualifying calls can replace the unprotected node and restart its lifetime
while failing membership again. Successful class-7 entry credits event 6 and
statistic 17 plus ordinary positional presentation outside alternate state,
but omits the descriptor event request.

### Naruto's separate low-HP effect

Naruto's callback applies `0x39` at `hp <= 0.15` while absent, root
suppression clear and the coordinator's alternate state inactive. It sets no
controller marker and credits neither controller tail. This differs from the
two descriptor HP characters and Naruto's `0x72` replacement.

### Post-UJ outcome effect

The cinematic outcome effect is independent of the form request.
`sp_skill_play_start` starts a contest outside manager mode 6; contest type 1
chooses a random type and types 2..6 run `jutsu_contest_init`. Type 0 creates
nothing.

Initialization seeds `jutsu_outcome_effect_id` from the attacker's selected
record (record 99 for skill `0x49`; -1 without a manager), sets
`jutsu_outcome_control_flag = 1` and damage total
`jutsu_contest_damage_fraction_total = 0`.
Battle setup resets those values to `-1,1,0`. Only contest status-4 clears
also write the effect global. Type 0 therefore leaves it at -1 unless an
earlier UJ left another value.

Post-cinematic state 1 first removes both participants' unprotected class-0..2
effects with reason 3. If the target is not defeated and the outcome effect is
not -1, it applies the effect to the attacker, then uses the outcome control
flag to choose the next state. Subsequent adoption can set the controller
marker. Excluding record 0 (effect 0), the complete class-3 UJ-record outcomes
are:

| Outcome | Character: record (category) -> effect |
| --- | --- |
| Effect adopted by `input_sector_widen_state_a`; sets the marker | `0x05`: `11` (`1`) -> `0x11`; `0x06`: `13` (`3`) -> `0x12`; `0x0C`: `27` (`2`) -> `0x18`; `0x0D`: `31` (`3`) -> `0x19`; `0x0F`: `35` (`2`) -> `0x1B`; `0x11`: `42` (`3`) -> `0x1D`; `0x16`: `54` (`3`) -> `0x21`; `0x2E`: `97` (`3`) -> `0x37`, `99` (`1`) -> `0x38`; `0x40`: `135` (`2`) -> `0x41`; `0x41`: `140` (`3`), `141` (`1`) -> `0x42`; `0x43`: `146` (`3`) -> `0x45`; `0x44`: `148` (`3`) -> `0x46`; `0x46`: `154` (`3`) -> `0x49`; `0x50`: `179` (`2`) -> `0x52`; `0x55`: `196` (`1`) -> `0x58`; `0x57`: `200` (`2`) -> `0x5B`; `0x5A`: `211` (`3`) -> `0x5E`; `0x5B`: `214` (`3`) -> `0x5F`; `0x5C`: `217` (`3`), `218` (`1`) -> `0x62`; `0x5D`: `219` (`2`) -> `0x63`, `220` (`3`) -> `0x64` |
| Effect only; `input_sector_widen_state_a` has no case | `0x01`: `1` (`2`) -> `0x0E`; `0x02`: `3` (`2`) -> `0x0F`; `0x03`: `6` (`3`) -> `0x10`; `0x0E`: `33` (`2`) -> `0x1A`; `0x19`: `56` (`2`), `57` (`3`) -> `0x22`; `0x22..0x26`: `65`, `67`, `69`, `71`, `73` (`2`) -> `0x27..0x2B`; `0x4D`: `171` (`3`) -> `0x4D`; `0x54`: `191` (`2`) -> `0x22` |
| Transforming effect `0x68..0x73` | The 12 records in [Effect-to-form mapping](#effect-to-form-mapping-and-resource-replacement) |

Class-7 effects have their separate entry path; whether their skill plays also
seed the outcome global remains open. Character `0x57`'s `0x5C` is the sole
adoption effect outside the records above.

For every non-transforming outcome record, this is the only post-UJ effect
source, and for the adopted pairs it is also the source of the later marker.
Under type 0 the application is skipped while ordinary unprotected-node
cleanup still occurs.

For transforming records the outcome inserts a class-3 -1 node on the base
fighter. No proven effect-list reader connects it to the request: base IDs
have no adoption case, completion gates use record/mode/outcome/latch, old
teardown force-removes the node, and the replacement constructs a new -2 node
by identity. The form request has no static contest-type dependency.

Under type 0 the outcome control flag retains 1, the ordinary uninterrupted
value; its other reader rebuilds per-action statistics without controller
work. Damage total retains zero, so per-hit damage uses the unscaled fraction.
An absent contest returns status 0, preventing the presentation's outcome-2
interruption branch. These globals do not supply an additional controller/form
gate. The earlier observation lacks its character/record identity; the static
non-transforming explanation is established, while a transforming-record
interpretation remains open. Its experiment details remain with
`jutsu_outcome_effect`'s annotation.

## Generic effect state

Generic application, aggregation and removal are owned by
[Battle status effects](../projectiles_and_items/battle_items_and_status_effects.md).
`fighter_has_effect` is authoritative; awakening-specific consequences follow.

### Class-3 transformed-form records

Effects `0x68..0x73` are exactly class 3. Every record has a null custom
factory, matching ID, default lifetime -1 and flags exactly 2. Creation is
generic and owner-only: no per-effect resource-swap callback, opponent
propagation, notification-map row, low-ID positional event or class-1/2
sidecar applies. Successful insertion updates the historical cache.
Classes 1/2/3 bypass ordinary root/context eligibility.

### Persistence and removal

`fighter_add_inherent_form_effect` requests lifetime -2 during replacement
setup, independently of the authored -1 default. That lifetime blocks duplicate
replacement and ordinary reasons 0/1/2. Reason 3 preserves all classes 3/4
and protected -2 nodes in 0..2. Reason 5 force-removes any node.

Bulk ordinary removal visits only classes 0..2; common fighter teardown
force-removes 0..4, including inherent form nodes. Their persistence ends with
fighter ownership, rather than an inverse form request.

### Authored lifetime and resource behavior

Representative `AwakeningEffectRecord` recurring values are:

| Effect / character context | Default countdown | HP delta per eligible contribution pass | HP boundary | Chakra delta |
| --- | ---: | ---: | ---: | ---: |
| `0x10`, Classic Rock Lee `0x03` | `600` | `-1/3000` | `0.1` | `0` |
| `0x3A`, Sakura `0x3A` | `600` | `+1/4000` | `1.0` | `-1/120` |
| `0x3B`, Gaara `0x3B` | `600` | `0` | no HP contribution | `-1/120` |
| `0x41`, Deidara `0x40` | `600` | `0` | no HP contribution | `-1/120` |
| `0x47`, Might Guy `0x45`, first stage | `600` | `-1/12000` | `0.1` | `0` |
| `0x48`, Might Guy `0x45`, second stage | `450` | `-1/4500` | `0.1` | `0` |
| `0x54`, character `0x51` | `600` | `0` | no HP contribution | `-1/120` |

Classic Lee's `0x10` comes from local UJ record 6, category 3; his base
association count is zero. Other contexts use controller associations.

All scoped negative chakra contributions have boundary zero. The HP/chakra
folds aggregate active nodes before evaluating the boundary: a sole negative
contributor is allowed at equality and disabled below, so the boundary is not
an exact final-write floor. Sakura's positive HP contribution is allowed at or
below full HP; ordinary recovery clamps the result.

Recurring consumers request no extra per-call clamp. Negative HP uses the HP
debit helper; negative chakra uses a separate debit that clamps at zero.
Neither resource boundary clears the marker nor removes the effect. Independent
character cancellation can still remove a node.

Resource and countdown passes have different gates. Recurring resources require
root suppression clear, a zero result from `fighter_restore_gate_b`, and both
owner and linked opponent outside `fighter_resource_contribution_blocked`.
The latter means major 8, an action record with `category & 0xC0000 != 0`,
and `ActionRecord.streak_exempt`, read as signed, at least 1.
Other chakra-debit gates remain in
[Chakra and guard](../combat/chakra_and_guard.md#debit-and-reservation-behavior).
A negative authored delta does not establish continuous drain in every state.

Positive lifetimes decrease by exactly one per eligible countdown pass, without
reading `update_rate`. These IDs are at least `0x0D` and bypass low-ID scalar
normalization. Counts 600/450 are not confirmed elapsed-frame or action-progress
durations: gating, exits and replacements can suspend, end or restart them.

The separate action-rate contribution is 1.25 for `0x10/0x47/0x48`, 1.1
for `0x3A`, neutral for `0x3B/0x41/0x54`. Its fold caps at 1.25 and
neutralizes in majors 5/6, the context gate, or major 8 with the qualifying
category. Maintenance uses it only with `update_rate_override = 1.0`, then
applies `update_rate_multiplier`. It does not accelerate lifetime countdown
and the marker does not bypass combat gates.

## Effect-to-form mapping and resource replacement

`jutsu_name_table` contains 223 `UltimateJutsuRecord` rows.
`jutsu_record_form` maps only:

| Effect | Replacement character ID | Character/form |
| ---: | ---: | --- |
| `0x68` | `0x2F` | Naruto (Nine-Tailed) |
| `0x69` | `0x30` | Second Stage Sasuke |
| `0x6A` | `0x31` | Loopy Fist Lee |
| `0x6B` | `0x32` | Possessed Gaara |
| `0x6C` | `0x33` | Super Choji |
| `0x6D` | `0x34` | Second Stage Jirobo |
| `0x6E` | `0x35` | Second Stage Kidomaru |
| `0x6F` | `0x36` | Second Stage Tayuya |
| `0x70` | `0x37` | Second Stage Sakon |
| `0x71` | `0x38` | Second Stage Kimimaro |
| `0x72` | `0x49` | Nine-Tailed Fourth Awakened State |
| `0x73` | `0x4B` | Sasori (Puppet) |

Other effects return form zero. Exactly 12 records map, each appearing in one
native local list:

| Base character | Record (`authored_id`) | Category | Default record? | Effect -> form |
| --- | ---: | ---: | --- | --- |
| Classic Naruto `0x01` | `2` (`2`) | `3` | No; default `1` | `0x68 -> 0x2F` |
| Classic Sasuke `0x02` | `4` (`5`) | `3` | No; default `3` | `0x69 -> 0x30` |
| Classic Rock Lee `0x03` | `5` (`7`) | `2` | Yes | `0x6A -> 0x31` |
| Classic Gaara `0x04` | `8` (`0x0B`) | `3` | No; default `7` | `0x6B -> 0x32` |
| Classic Choji `0x0E` | `34` (`0x1E`) | `3` | No; default `33` | `0x6C -> 0x33` |
| Jirobo `0x22` | `66` (`0x34`) | `3` | No; default `65` | `0x6D -> 0x34` |
| Kidomaru `0x23` | `68` (`0x37`) | `3` | No; default `67` | `0x6E -> 0x35` |
| Tayuya `0x24` | `70` (`0x3A`) | `3` | No; default `69` | `0x6F -> 0x36` |
| Sakon `0x25` | `72` (`0x3D`) | `3` | No; default `71` | `0x70 -> 0x37` |
| Kimimaro `0x26` | `74` (`0x40`) | `3` | No; default `73` | `0x71 -> 0x38` |
| Naruto `0x39` | `111` (`0x4C`) | `3` | No; default `110` | `0x72 -> 0x49` |
| Sasori `0x3F` | `132` (`0x63`) | `3` | No; default `131` | `0x73 -> 0x4B` |

UJ tier selection prioritizes marker -> tier 2, otherwise `hp <= 0.5` ->
tier 1, otherwise tier 0. The disabled/initialized per-side remap is identity;
tiers 0/1/2 request categories 2/3/1. Thus 11 replacements select a low-HP
category-3 record; Classic Lee alone uses category-2/high-HP (>50%), while his
category-3 record is non-transforming. These are selection prerequisites,
separate from completion. Connection and presentation admission belong to
[Ultimate Jutsu](ultimate_jutsu.md#start).

`sp_skill_play_end` tears down its 17 owned entries and transient handles,
then invokes `jutsu_apply_completion` unconditionally. Form-request gates are:

1. Manager exists and mode is not 6 (Collection).
2. UJ outcome `jutsu_cinematic_outcome` is not 2. Outcome 2 instead credits
   result metric 14 to the opposing side and returns before subsequent completion
   bookkeeping.
3. The manager's selected record maps to a nonzero form.
4. The side's condition slot 7 is not 1.

The presentation initializes outcome 0, writes 2 from state 4 with contest
status 4 and the cinematic branch-frame gate, then requests branch 2/state 5;
a finished owned handle writes 1. Contest status 4 requires attacker-relative
meter below -5; merely negative [-5,0) gives status 1 and does not create this
gate. Outcome 2 credits “Defeat an enemy Ultimate.” An absent contest yields
status zero but is not itself a completion gate.

The condition matrix `side_condition_statuses` is three rows of 93 words,
stride `0x174`. The two sides' slot-7 entries are `side_one_uj_defeat_latch`
and `side_two_uj_defeat_latch`; they initialize/reset to -1. Value 1 is the
UJ defeat latch, written only by the proven constant-slot path when outcome control flag
is 1 and target HP is at or below zero. Five reset/abort branches restore -1.
It is not chakra or another resource check.

`battle_request_form_replacement` stages a pending ID and route 8/variant 1/
phase 1; it does not change the live fighter. State `0x17` replaces the current
side identity, refreshes selected UJ metadata, and loads the full resource mask
`0x1FF`. Old resources release mask `0x113`, additional slots 5..7 and
trailing handles, with protection for pointers shared by the other side.

The load helper has no returned status and the handler has no rollback branch.
It proceeds to phase 2, clears both pending IDs and its trailing byte, then
selects state `0x0D`. It does not snapshot the saved/match-start configuration.
Variant-2 state `0x18` can restore an altered opposite side and snapshots its
new configuration; shared phase 2 alone does not identify a form swap.

Replacement setup mirrors the forward mapping: `2F..38 -> 68..71`,
`49 -> 72`, `4B -> 73`, each applied at -2. This constructor sets no
controller marker; a later pass adopts the transformed identity.

### Replacement character parameters

The twelve inherent class-3 payloads are identical and neutral across generic
attack, defense, update-rate, jump, motion, recovery, recurring HP/chakra and
guard-damage consumers. Flags 2 grant none of the `0x10/0x20/0x40/0x80`
effect-list privileges. Presentation selectors differ but do not alter these
payloads; move-specific attack flags are separate.

The changed character record supplies the parameter differences. All 55 record
words are copied to the new fighter. Rounded single-precision comparisons are:

| Base -> form | Offense | Durability | HP recovery | Chakra recovery |
| --- | --- | --- | --- | --- |
| `0x01 -> 0x2F` | `1.10 -> 1.25` | `0.90 -> 1.20` | `1.00 -> 1.10` | `1.20 -> 1.50` |
| `0x02 -> 0x30` | `1.10 -> 1.20` | `1.00 -> 1.10` | `0.90 -> 0.90` | `1.00 -> 0.90` |
| `0x03 -> 0x31` | `1.05 -> 1.20` | `1.10 -> 1.15` | `0.85 -> 1.10` | `0.80 -> 1.10` |
| `0x04 -> 0x32` | `0.90 -> 1.30` | `1.10 -> 1.20` | `1.00 -> 1.00` | `0.90 -> 0.90` |
| `0x0E -> 0x33` | `1.05 -> 1.25` | `1.05 -> 1.10` | `0.85 -> 0.85` | `0.85 -> 0.90` |
| `0x22 -> 0x34` | `1.05 -> 1.25` | `1.05 -> 1.20` | `0.85 -> 1.20` | `0.85 -> 1.20` |
| `0x23 -> 0x35` | `1.00 -> 1.20` | `1.00 -> 1.10` | `1.00 -> 1.00` | `1.00 -> 1.00` |
| `0x24 -> 0x36` | `0.95 -> 1.30` | `0.95 -> 0.85` | `1.10 -> 0.90` | `1.10 -> 0.90` |
| `0x25 -> 0x37` | `1.05 -> 1.20` | `0.90 -> 1.10` | `0.95 -> 1.05` | `0.95 -> 1.00` |
| `0x26 -> 0x38` | `1.10 -> 1.20` | `0.95 -> 1.10` | `1.05 -> 1.05` | `1.00 -> 1.00` |
| `0x39 -> 0x49` | `1.10 -> 1.25` | `0.90 -> 1.20` | `1.00 -> 1.10` | `1.20 -> 1.50` |
| `0x3F -> 0x4B` | `1.10 -> 1.10` | `0.90 -> 0.90` | `1.00 -> 1.00` | `1.20 -> 1.20` |

These are copied parameters, not additional effect multipliers. Tayuya lowers
durability; Sasori changes none of the four. Replacement therefore has no
universal increase of every stat. Durability/recovery consumers are in
[Damage](../combat/damage.md#confirmed-character-record-fields).
Later callbacks can still alter other working values.

#### Selected transformed callbacks and destination bases

Loopy Fist Lee's neutral callback adds `0.25 * loopy_motion_factor` to
`transient_motion`, consumed by movement and then cleared. It is action-dependent
motion, not a copied ground-target change or another class-3 multiplier.

Nine-Tailed Fourth's first callback is a no-op. The later callback performs
action-selected position/vector work and clears planar/vertical speed.
Apparent ground-target/acceleration/braking/jump displacements in that body
are stack stores, not fighter overrides.

Both selected response callbacks can write receiver `attack_scale`,
`planar_scale` and `vertical_scale` in mode 2 while selecting a response and
altering attack-record fields. No direct primary-fighter write to the four
compared damage/resource parameters was found in the complete screened
callbacks. This does not cover every slot, helper or update path.

The matching displacements in the Classic Naruto, Super Choji, Second Stage
Kimimaro and Kankuro callbacks instead target a `0x120`-byte scratch allocation
through `BattleManager.scratch`. They do not establish primary movement
overrides. Full indirect-writer coverage remains open.

### Static reconstruction order

Native replacement changes one manager identity but reconstructs both primary
fighters:

1. Save both sides' scoped values, then destroy the old battle graph before
   releasing target resources or installing the pending identity. Hub/registry
   teardown reaches common fighter cleanup and force-removes old effect nodes.
2. Install the pending identity, load its resources, set phase 2, then pass
   states `0x0D/0x0E` and the preparation barriers.
3. Successful controller allocation constructs both fighters from current side
   records. Common initialization clears marker and creates fresh effect
   ownership; common setup copies the selected live identity.
4. Successful setup inserts the inherent -2 node, initializes action `(0,0)`,
   then enables update. Identity and any successfully inserted node precede
   update enable; marker remains clear.
5. Publish both new aliases, restore variant-1 saved values, then adopt recognized
   transformed identities on later eligible dispatch.

These are static ordering constraints, not measured display boundaries.
Neither pending ID nor phase 3 transfers an old effect container. Identity-based
adoption does not certify effect insertion or successful allocation.

### State retained across the native rebuild

State `0x17` saves/restores both sides' HP, chakra, remaining/elapsed timer
words and eligible inventory entries (side -2, mask -1). Continuation phase 2
preserves the BTL result bank and both external fighter-statistics banks.
Native combo objects, action/progress, item/projectile counts, marker bits and
effect ownership are freshly constructed.
[Battle lifecycle](../session/battle_lifecycle.md#values-crossing-the-reconstruction-boundary)
owns the complete save/restore and statistics reload.

#### Reconstruction adoption increment

A retained nonzero result metric 10 suppresses another event credit but not the
new fighter's local statistic-17 increment. Block zero selects the newly copied
local pairs; root suppression can block the increment. Adoption neither reloads
bank one nor writes an external bank, and therefore does not repair the
[statistics reload ordering](../session/battle_lifecycle.md#fighter-statistics-across-reconstruction).
This is bounded constructor/save/restore coverage, not a classification of every
field in the rebuilt graph.

### Reserved transformed slot `0x4A`

The forward pairing maps Chiyo `0x3E -> 0x4A` and transformed inputs to
themselves; classification includes `0x4A`. Roster validity rejects it,
reverse mapping has no case and returns -1, and its definition reuses the
Classic Naruto factory and record with actual identity `0x01`.

Its UJ list is null, trigger is `{-1,0}`, association empty, and neither UJ
form mapping nor inherent-effect construction has a `0x4A` case. Unlock
pairing can mark the slot but cannot bypass validity. Controller code would
recognize a pre-existing `0x4A` and set/preserve the marker without constructing
an effect; no clean path here constructs a genuine fighter or requests it.
It is a reserved/incomplete Chiyo pairing, not a native reachable awakening.

## Controller exit and reconciliation

`awakening_clear_marker` removes flags only, returning 0 when already clear
and 1 otherwise. Deidara/Gaara also restore the paired special state and command
sectors. The effects remain.

Reconciliation returns immediately for recognized transformed identities.
Taijutsu Chiyo's progress trigger removes its associated `0x4E`, emits event
`0x3A` and clears the marker. Character `0x19` removes `0x22/0x23` before
checking `0x24`. Guy advances stages while associated and the progress gate
passes; Sakura removes `0x07`; Tenten keeps its counter zero. No association
clears ordinary markers and the Deidara/Gaara paired state.

The UJ skill resolver additionally clears awakened Choji's marker for requested
`0x95` and substitutes `0x96`. Its surrounding gameplay label is open;
ownership is in [UJ cinematics](ultimate_jutsu_cinematics.md#opponent-dependent-cinematic-selection).

The distinct exits are flag suppression, list-based marker reconciliation,
targeted node removal, ordinary-reason persistence and terminal fighter teardown.

### Manager identity and resource reset

Saved configuration contains the match-start identities. State `0x17`
changes current identity without updating this snapshot; variant-2 state
`0x18` does update it.

Reset builds a changed-side mask, releases all changed sides' full resource
masks, restores the complete saved configuration once, then reloads those sides.
The result-choice-0 path invokes it after its battle-state transition.
Fighter teardown separately removes the old inherent nodes.

The request's only direct caller supplies forward forms. Reverse identity
mapping has ten direct event/selection consumers but none in the swap chain.
The proven lifecycle is one-way replacement during battle, followed by saved
configuration restoration and teardown at reset; no decoded direct in-battle
inverse request was found.

## Address index

Most code references use annotation names. The main live boundaries are:

| Routine/data | Program | Live address |
| --- | --- | ---: |
| `awakening_dispatch` | Resident | `0x0020E280` |
| `input_sector_widen_state_a` / `input_sector_widen_state_b` | Resident | `0x0020D030` / `0x0020D910` |
| `fighter_add_inherent_form_effect` | Resident | `0x00305FF0` |
| `jutsu_apply_completion` | Resident | `0x0035B3B0` |
| `battle_request_form_replacement` | Resident | `0x001EC5E0` |
| `manager_replace_form` | Resident | `0x001EE1C0` |
| `awakening_triggers` / `awakening_associations` | Resident | `0x005C1B50` / `0x005C1D30` |
| `battle_create_primary_fighter` | BTL | `0x00709860` |
| `jutsu_presentation_update` | BTL | `0x00769790` |

Resident globals relevant to awakening are named in `@annotations/NA2/SLPS_258.37`:

| Resident global | Established use |
| --- | --- |
| `battle_route_code` | Route, replacement uses 8 |
| `battle_continuation_phase` | Shared re-entry phase |
| `battle_continuation_route` | Re-entry variant |
| `battle_reentry_handshake` | Readiness handshake byte |
| `combo_owners`, `combo_owner_side_two` | Per-side native combo pointers; the second name labels array slot 1 |
| `jutsu_contest_state` | Contest-object pointer |
| `jutsu_contest_damage_fraction_total` | Contest damage total |
| `jutsu_cinematic_outcome` | UJ outcome word |
| `battle_pause_controller` | Pause-controller pointer |
| `side_condition_statuses` | Condition matrix |
| `side_one_uj_defeat_latch`, `side_two_uj_defeat_latch` | The two sides' condition slot 7 |
| `side_jutsu_tier_remaps` | Identity-initialized per-side UJ tier remap |
| `fighter_statistics_banks` | External statistics banks, stride `0x2D6`, pair-copy length `0x60` |

## Negative results and open questions

Established negatives are limited to the screened paths: no general awakening
chakra/HP gate, no active descriptor `0x20`, no authoritative cache after
removal, no class-3 custom resource-swap callback, no reachable reserved
`0x4A` form, and no direct reverse request.

Open matters remain the visible timing of progress/marker/effect/identity and
presentation; Konohamaru mismatch presentation; arbitrary indirect BTL behavior;
later parameter writers/delegated callbacks; class-7 skill-play outcome seeding;
UJ record 0's use; and the earlier contest-type-0 observation's missing
character/record identity. Static evidence explains non-transforming
outcome-effect loss, but does not predict removal of the forward form request.
