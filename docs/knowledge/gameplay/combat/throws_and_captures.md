# Throws and captures

This document investigates throw and capture control in retail NA2 (`SLPS-25837`).

## Research coverage

Established: paired capture entry, contact/substitution gates, classification, guard exceptions, attachment/approach arithmetic,
continuations, release callbacks, category disabling, and selected model update/destruction ordering.
Open: `0x400/0x800` meanings/producers, anchor/partner-model availability, zero-distance/scale inputs, address-zero lookup failure,
isolated removal ordering, other escape/destruction families, branch reachability, and visible durations/outcomes.
Names come from `@annotations/NA2`; routine comments hold the code-level detail.

## Evidence and address conventions

Binary identities and live address conventions belong to
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
The evidence is static and bounded; equations describe velocity writes rather than a
measured trajectory. Annotation names describe the demonstrated roles, not recovered
source names. The bounded overlay direct-call census is preserved in the resident
routine comments and excludes no indirect transfer. Descriptor-driven receiver handoff
remains in [Hit response](hit_response.md).

[Target selection](target_selection.md) owns participant/provenance contracts;
[Combat action execution](combat_action_execution.md) owns ordinary execution and the
separate paired contest; [Hit response](hit_response.md) owns the receiver matrix;
[Extra Hit](extra_hit.md), [Substitution](../characters/substitution.md), and
[Damage](damage.md) own their respective mechanisms.

## Capture family and participant boundary

The common capture-related category service is resident `capture_classify`, separate
from the paired contest. It resolves the current action only in major state 8 when its
explicit record argument is null. Category `ActionRecord.category & 0x100` returns 1 in
phase 0 and 2 in any other phase; category `0x200` returns 3 in phase 0 and 4 otherwise.
The `0x200` check follows the `0x100` check and overrides its result if both bits are
present. These are internal classifications, not player-facing move names. The motion
and attachment predicates use the wider mask `0xF00`; the classifier's return branches
here recognize only `0x100/0x200`.

`capture_bypasses_guard` returns 1 only when that classification is nonzero and
`ActionRecord.flags & 0x4000` is set. The contact-side consumer `hit_attacker_landed`
uses this result to suppress its ordinary guard branch. This proves a
category/flag-specific guard bypass, not universal unguardability of everything entering
a held response. Hit admission, response selection and damage application remain
separate gates owned by [Hit response](hit_response.md) and [Damage](damage.md).

The partner is always the fighter already in `Fighter.opponent` in the common paths
examined here. They neither search a target list nor replace that pointer. Accepted-hit
source pointers have their own
[Target selection contract](target_selection.md#accepted-hit-source-boundary). The
attachment service does not use `Fighter.response_source` to choose its partner.

### Wide-mask bits without a classified capture

Bits `0x400/0x800` have a bounded common-code contract even though their authored
meanings remain unidentified. A record containing either bit but neither `0x100` nor
`0x200` passes the attachment category gate and the broad `fighter_side_query` predicate
(when behavior `& 0x7C` is zero), but `capture_classify` returns zero. Such a record
does not receive classifier-based guard bypass. Action entry and cleanup call only the
`0x100/0x200` category helpers; there is no matching wide-mask-only
snapshot/position-cleanup dispatch there. `capture_update_motion` still consumes the row
motion, but its facing events and computed-approach selection require the classified
`0x100/0x200` cases.

For a held receiver whose partner remains in major 8 with such a record,
`response_held_handoff` enters `(0,0)` if behavior `0x04000000` is clear: the current
record exists, but both classified category bits fail. When that behavior bit is set,
the same updater retains the receiver without checking those two category bits. Thus the
broad attachment mask alone does not establish a complete starter/release lifecycle for
`0x400/0x800`.

The selected IDs 39/47 arrays contain `0x100/0x200` in this group and no `0x400/0x800`.
No concrete authored wide-mask-only capture record or writer is established; matching
numbers in input/exchange or movement fields do not identify a category producer. Their
purpose and reachability remain open.

## Sender-side attachment

Resident `capture_attach_receiver` requires a nonnull major-8 action with category mask
`0xF00`, the partner in major 5 substate `0x4A..0x4E`, and
`self.section == partner.section`. These gates distinguish attachment from generic
collision or merely having a current action.

It obtains the sender's `Fighter.effect_anchor_name` and resolves it inside the sender's
scene/model handle `Fighter.owned_animation_player` through `resource_find_model`. The
retail name-owner predicate always returns zero, so this path uses the sender's name. A
missing sender model, empty name, or failed anchor lookup prevents all partner
position/model updates in the body. Character anchor ownership is recorded in
[Character assets](../../game/character_assets.md#character-records).

With an anchor, it copies the anchor transform, derives the partner position from its
translation, and subtracts half the partner's scaled height in Z except for response
`0x4E`. `puppet_reconcile_motion` can correct the derived planar position against the
sender's geometry. The partner's `Fighter.position` is then overwritten. The remaining
handling has three forms:

| Partner/action condition | Additional attachment operation |
| --- | --- |
| Response other than `0x4E`, behavior `0x04000000` clear | Refresh partner model through `entity_resource_update` |
| Response other than `0x4E`, behavior `0x04000000` set | Extract Euler angles through `capture_extract_euler`, add pi to the third angle with wrap, write partner `Fighter.orientation`, then refresh its model |
| Response `0x4E` | Apply partner/sender scale ratios to the copied transform, write it directly into partner player's `CollisionTransform.local`, and set its `dirty` byte to 1 |

After a successful anchor path, the function clears partner grounded bit
`Fighter.contact_flags & 0x80` and clamps negative `Fighter.response_vertical_speed` to
zero. Its local transform workspace pointer is restored before return. It does not store
an additional `opponent` pointer or install an allocation owner. This establishes the
static position/model binding; it does not establish the visible animation or which
resource supplies every anchor. The direct `0x4E` model-write branch has no explicit
partner-model null check; the investigation does not establish that model pointer's
availability under every possible interruption.

### Attachment equations and lookup failure

In column-vector notation, let A be the resolved anchor world matrix with translation t,
and let `H = 0.5 * partner.height * partner.scale`. The initial bound position is
`p = t + (0,0,-H,0)` for responses `0x4A..0x4D`, or `p = t` for `0x4E`. The correction
query receives `(p.x, sender.position.y, p.z, 1)` and the sender's scaled
`CollisionEntityScalars.height/width`. On success it replaces only `p.x/p.z`; the
stored partner position keeps the anchor-derived Y and W. Thus correction does not
simply replace the entire anchor translation.

For `0x4E`, a successful correction also replaces A's entire translation column with p;
without correction it leaves A's translation untouched. The final partner-model matrix
is
`A * diag(partner.scaleX/sender.scaleX, partner.scaleY/sender.scaleY, partner.scaleZ/sender.scaleZ, 1)`, using `Fighter.capture_scale[0..2]`. The matrix product scales basis columns and
retains translation. There is no denominator-zero or partner-model-null branch in this
path.

For the flagged rotation path, `capture_extract_euler` derives Euler angles with a
singular-branch threshold near 0.0001. The attachment caller adds pi to the third angle,
wraps once into `[-pi,pi]`, writes `Fighter.orientation`, and refreshes the player.
Unflagged `0x4A..0x4D` leaves orientation alone; the extraction equations and exact
threshold are in the routine annotation.

The anchor is borrowed for this call, not retained in a fighter field:
`resource_find_model` searches the sender scene's named entries and the optional
type-`0x100` `CaptureModelLookupNode.nested_type100` object. Its required-lookup failure
writes zero to address zero before returning null. `capture_attach_receiver` supplies
zero. Its later null branch prevents attachment stores, but does not prove that a
missing authored anchor is harmless. The effect of the address-zero write and
ordinary-play reachability of such a missing anchor are unresolved. The name pointer
itself is dereferenced without a null-pointer check after the nonnull sender-model gate.

## Common entry, handoff and interruption

Category-`0x100` entry/cleanup helpers `capture_starter_enter / capture_starter_exit`
are empty. Category-`0x200` entry `capture_release_enter` snapshots the partner's
position into partner `Fighter.saved_response_position`; cleanup
`fighter_cancel_current_action` independently runs the section-aware
`stage_project_position` (`0x007090D0`, BTL) position query for each fighter with
nonnull `Fighter.field`, replacing its Y coordinate only on a successful query. It does
not clear `Fighter.opponent` or free the partner.

The common major-8 updater `action_update_jutsu_record` dispatches category `0xF00` to
`capture_update_motion` after exchange and positive `Fighter.context_state` branches.
That body normally uses authored row motion through `response_motion_update`, but a
category-`0x100` action with behavior bit `0x2` instead uses `capture_compute_approach`. It also performs phase-specific facing changes. Ordinary entry, phase progression,
continuation and terminal exit remain in
[Combat action execution](combat_action_execution.md).

The held receiver's `response_held_handoff` uses partner major state, category, behavior
`0x04000000` and phase-payload bits to decide retention, another response, or release.
The complete receiver matrix belongs to [Hit response](hit_response.md#response-exits).
The matrix is conditional on the paired fighter's execution; it is not an independent
fixed-duration hold. Loss of the partner's major-8 current record can restore receiver
`Fighter.saved_response_position` before its next state.

Major-8 cleanup `action_exit_record` runs category cleanup while the old action record
is still installed. When the requested next major is not 8, it also releases a partner
specifically held in `(5,0x50)` to `(0,0)`; this branch is distinct from attachment
responses `0x4A..0x4E`. It does not immediately force those attachment responses to
neutral. Their following response updates consult the partner's resulting state through
`response_held_handoff`. This proves a scheduled handoff, not complete protection
against every possible participant destruction or indirect callback.

### Facing and sender approach

`capture_update_motion` has two capture-specific facing events. In category `0x100`
phase 0, primary event 0 plus behavior `0x40` and grounded bit
`Fighter.contact_flags & 0x80` copies `Fighter.facing` into
`movement_facing/placement_facing/response_facing`, refreshes rotation, and moves
planar/vertical speeds toward zero. In category `0x200` phase 1, secondary event 0
reverses those facing halfwords when `fighter_side_query` is false. That predicate is
true exactly for category mask `0xF00` with behavior mask `0x7C` zero. Thus the phase-1
reversal is authored behavior dependent; it is not a mandatory operation for every
release.

The alternative sender movement `capture_compute_approach` snapshots its own
`Fighter.saved_response_position` at primary event 0, copies `approach_flags` to
`previous_approach_flags`, and clears `approach_flags/approach_angle`. It uses the
already paired fighter, current phase motion and attack payload, animation length,
facing, distance, current/previous contact `action_outcome/previous_action_outcome`,
and `ActionRecord.streak_exempt` to choose between ordinary row motion and a computed
approach. A successful computed path stores a target vector in `Fighter.capture_target`
and derives sender `response_planar_speed/response_vertical_speed`; its allocated
scratch pointer is restored. This is sender movement toward the existing partner,
separate from the receiver's anchor attachment. The equations below apply to the
computed branch.

### Computed approach equations

The computed branch has the following bounded calculation. Let `S` be the sender, `P`
its existing `Fighter.opponent`, `O = S.saved_response_position` the primary-event-0
position snapshot, `h = height * scale` and `w = width * scale` for each fighter. Here
height, width and scale are the typed `CollisionEntityScalars` fields.

Before selecting the computed path, it measures XYZ distance between
`S.position + (0,0,hS/2)` and `P.position + (0,0,hP/2)` and uses comparison radius
`(hS+wS+hP+wP)/4`. `vector_distance` explicitly subtracts its two vectors and takes
`sqrt(dx²+dy²+dz²)`. The selection also checks facing, `S.capture_range`,
current/prior outcomes, `ActionRecord.streak_exempt`, and the secondary timer. Null
partner/current record, missing motion/attack data, negative animation slot, or absent
animation object returns before computing new velocities. Motion flags `& 0x10`, and
behavior `0x08000000` with current outcome 1, choose ordinary `response_motion_update`
instead.

The duration parameter `N` defaults to 8. When attack-payload flags lack `4/8` and have
`1/2`, `CaptureAttackPayload.approach_duration` selects an animation-relative value:
`-0x7FFF` uses animation length minus 2. Otherwise `0x7FFF` first becomes -1, and every
resulting negative value uses `value + length - 1 - CharacterAnimationRow.start_frame`;
nonnegative values are used directly. It then clamps `N` to `[4,6]`, including the
default 8. This is an authored calculation parameter, not a measured hold duration.

The timer gate is `S.secondary_timeline.current <= N`. Let E denote the
computed-approach eligibility result. If `ActionRecord.streak_exempt` is zero, E is
simply prior outcome `S.previous_action_outcome != 0`; that branch overrides the
earlier facing/range checks. Otherwise E requires equal `S.response_facing/S.facing`,
centered distance at most `S.capture_range`, current outcome other than -2, and prior
outcome 1. In this latter case E is cleared when P is grounded and centered distance is
less than `0.75` times the comparison radius. This is the actual byte-dependent
predicate, not a single range check shared by every authored variant.

For the target-refresh branch, start with `T = P.position`. If P's grounded bit is set,
replace `T.x` with `T.x - sign(S.facing) * (wS/2 + wP/4)`, where facing 0 supplies +1
and facing 1 supplies -1. For exact behavior group `ActionRecord.flags & 0x7C == 0x10`,
also add `(hS+hP)/4` to `T.z`. Other groups do not add this height offset. The
target-refresh branch requires E; its alternative reuses `S.capture_target`.

Set `d = T-O`, `r = lengthXYZ(d)` and `C = S.capture_distance_cap`. If `r > C`, use
`d = C*d/r` and retained length `L = C`. Otherwise use `d = (1+wS/r)*d` and retain
`L = r`. Reverse only `d.x` when `S.response_facing != S.facing`, then store `O+d` in
`Fighter.capture_target`. No zero-distance guard precedes the `wS/r` division; the
evidence does not establish which authored/play states avoid that input.

The next stage sets the intermediate vector's Y to zero and computes
`a = wrap(pi/2 + atan2(d.z,d.x))`. Here `wrap` subtracts `2*pi` once above `pi` and
adds it once below `-pi`; the constants are float words
`0x3FC90FDB/0x40490FDB/0x40C90FDB`. Select center `c = pi/2` for `a > 0`, otherwise
`-pi/2`. The angular half-width is `0x3F9C61AB` when behavior bit 2 is set and P is
ungrounded, otherwise `0x3F5F66F3`. Clamp `a` into `[c-half_width,c+half_width]`, then
set `alpha = wrap(-wrap(a-pi/2))`. The final stored target is `O + RY(alpha)*(L,0,0,0)`, where the column-vector rotation maps `(x,y,z)` to `(Crot*x+Srot*z,y,-Srot*x+Crot*z)`.

The Y rotation uses `matrix_rotate_y_polynomial` and `vu_rotation_polynomial`, whose
annotated coefficients and operation order produce a polynomial and square-root
approximation. Substituting ideal trigonometric functions changes this arithmetic.

Finally, with update scalar `dt = S.update_rate`, advance
`q = min(S.approach_angle + (pi/2)*dt/(N+1), pi/2)` and store q in `S.approach_angle`.
The envelope is `g = 0.25*cos(q-pi/4)*min(B,1.25)`, where
`B = fighter_knockback_scalar(S)` starts at 1 and adds
`AwakeningEffectNode.payload_84 - 1` for each enabled node
(`AwakeningEffectNode.lifetime != 0`) in S's `effects/effect_tail` list. For final
displacement `v = target-O`, store
`S.response_planar_speed = max(g*v.x / sin(facing_angle[S.movement_facing]), 0)` and
`S.response_vertical_speed = g*v.z`. The scalar cosine and sine are `angle_cosine` and
`audio_angle_sine`; their small-angle kernels and quadrant branches distinguish the
two. These are velocity writes, not direct position integration or a measured
player-visible trajectory.

The approach-state lifetime is explicit: secondary event 0 with zero
`Fighter.approach_flags` selects bit 2 only while the timer window and E both hold;
otherwise it sets bit 1. Loss of either gate turns bit 2 into bit 4. The computed
workspace path requires nonzero `Fighter.approach_flags` with neither bit 1 nor bit 4.
The other paths may use row motion or reduce prior velocities; they must not be
represented by the computed equation. The computed workspace is restored after the call
and owns no persistent partner allocation.

Related reset helper `capture_reset_approach` clears
`approach_flags/previous_approach_flags/approach_angle`. Initialization, action exit,
zero-motion-classification exit and the selected character callback reset it. These
fields have per-execution lifetime rather than storing another participant.

The sender-grounding update follows the routed-this-update rejection in
`fighter_update_phase_and_exits`. For behavior `0x04000000` plus category
`0x200` and primary cursor below 5, `capture_update_sender_grounding` clears
grounded bit `0x80` and moves a negative vertical speed toward zero. This is sender-side
handling of the same flag used to retain and rotate the held receiver. It complements
the attachment pass, which always clears the attached receiver's grounded bit and clamps
its negative vertical speed.

Chain selection adjusts a chain-selection signature for mode 1 when the current action
is category `0x200` with behavior `0x80`. It clears signature bits `0x3000` and, when
current progress is at least `0.75`, adds `0x1000` only for a direction pair `0x4000`
if `fighter_side_query` is true or `0x8000` if false. The progress value is the shared
authored-window query, not unconditional elapsed action time. Full chain matching
belongs to [Action commands](action_commands.md#chain-masks).

## Contact admission and substitution boundary

`hit_resolve_pair` sends each surviving attack-side contact bit `0x100` to
`hit_classify_pair(sender)`. That function resolves the sender's current record, uses
`capture_bypasses_guard` for the guard decision, applies ordinary source/receiver
admission, rejects positive receiver `Fighter.hit_rejection.current`, and calls
`hit_new_record_allowed(receiver, record)`. The last helper admits a nonnull record
when the receiver's cached record differs/is null, or when a matching cached record has
`Fighter.attack_repeat_countdown > 1`. A same-record final repetition is therefore not
a fresh admitted connection at this stage.

Its outcomes are `0` rejected, `1` ordinary connection, `-1` guarded, and `-2`
intercepted by substitution. Before publishing the result through
`action_publish_outcome`, it asks `input_match_trigger_binding` about substitution with
the anticipated receiver major/substate. Both the ordinary and the alternate
effect-backed paths can produce `-2`; their timing, resource gates and source kinds
belong to [Substitution](../characters/substitution.md). Capture category alone does
not bypass this predicate.

The ordinary and effect-backed interception routes commit codes `0x211` / `0x11` in modes
0/1 respectively. Arbitration removes the corresponding attack/receive bits after
outcome `-2` and clears the receiver's record through `hit_clear_retained_record`. On
an ordinary surviving receive bit 1 it instead installs the paired fighter in
`Fighter.response_source` and publishes the sender's record through
`hit_retain_attack_record`, before accepted-hit routing.

`action_publish_outcome` writes `Fighter.action_outcome`, updating outcome auxiliaries
when requested. The common automatic continuation, which requires outcome 1 and the
partner's resolved accepted-hit record to equal the sender's current record, is owned by
[Combat action execution](combat_action_execution.md#continuation-and-common-exit-decisions). In the sampled records below it is the capture-to-release link: the release record's
continuation byte names the starter and its signature contains `0x08000000`. It does
not select a new participant.

### Other direct category consumers

Additional consumers show why classification is broader than guard handling:

| Consumer | Capture-specific effect |
| --- | --- |
| `response_choose_facing` | Classification 3 uses the sender's facing, reversed when `ActionRecord.capture_facing_distance_factor` is negative, to derive the receiver's facing; `fighter_side_query` and `ActionRecord.knockback_scale` can further change the result |
| `hit_intercept` | For substitution code low nibbles `0x11`, the extra code bit `0x100` is added under a facing match only when the partner's capture classification is zero |
| `hit_handle_bit2` | Its major-5 branch checks the partner's capture classification before consulting ordinary reaction helper `response_class_motion` |
| `fighter_overlap_push` | Either fighter's nonzero classification prevents this ordinary paired body-separation block |
| `section_transfer_down_allowed` | Classifications 3/4 reject the request whose caller would clear retained hit provenance and enter `(3,0x1F)` |
| `yellow_flash_channel3` | The Yellow Flash's callback can dispatch `Fighter.pending_action` during classification 1 under its action/cursor gates |
| `naruto_nine_tails_channel3` | Classic Naruto's Nine-Tailed form callback dispatches a pending index other than `-1` during classification 1 before its action-specific effects |

The request/cancel contracts remain in
[Combat action execution](combat_action_execution.md#input-interruption-of-an-executing-action). These code paths do not establish a universal escape command or a separate
target-selection mechanism.

For a receiver in major 5, that separate `section_transfer_down_allowed` request checks
`response_is_downed_family(receiver,-1)`, which returns zero for every held substate
`0x4A..0x4E`. Held substates are not explicitly blacklisted there. Its outer gates
still require zero `exchange_roles/context_state`, grounded bit
`Fighter.contact_flags & 0x80`, `movement_flags & 0x10000`, and logical request
`0x100000` or both `0x8/0x10000`. Successful attachment clears that grounded
prerequisite. Thus this request is excluded by the bound receiver's grounded state after
the attachment pass, not by a universal no-escape flag. Reachability before attachment
or with an absent anchor is unresolved. The two ordinary input-recovery state lists also
omit `0x4A..0x4E`; their complete conditions remain in
[Hit response](hit_response.md#input-recoveries).

The first callback's table is `yellow_flash_callbacks` for definition ID 39
`yellow_flash_character_record`; its pending dispatch additionally requires secondary
cursor greater than 0 for source indices `0x1D/0x20/0x2D`, or greater than 2 for `0x23`. ID 47 definition `naruto_nine_tails_character_record` instead has slot 2 at table
`naruto_nine_tails_callbacks` pointing to `naruto_nine_tails_channel3`, with no
corresponding cursor threshold at its initial pending-dispatch branch. These are
concrete character differences in how a selected release can begin.

## Representative capture and release records

This sample covers records and selected phase sequences from the complete arrays for IDs
57, 58, 61, 18 and 51. The all-definition census belongs to
[Action commands](action_commands.md#static-action-data) and
[Combat action execution](combat_action_execution.md#complete-authored-array-census).
Character ID names follow [Character identity](../characters/character_ids.md).

| Definition / capture to release indices | Capture record / phase start | Release record / phase start | Authored receiver `response_selector` / release `repeat_count` |
| --- | --- | --- | --- |
| 57, Naruto / `0x24 -> 0x25` | `capture_id_057_action_24 / capture_id_057_phases_24` | `capture_id_057_action_25 / capture_id_057_phases_25` | `0x17 -> 0x16` / 3 |
| 58, Sakura / `0x21 -> 0x22` | `capture_id_058_action_21 / capture_id_058_phases_21` | `capture_id_058_action_22 / capture_id_058_phases_22` | `0x18 -> 0x13` / 1 |
| 61, Temari / `0x20 -> 0x21` | `capture_id_061_action_20 / capture_id_061_phases_20` | `capture_id_061_action_21 / capture_id_061_phases_21` | `0x17 -> 0x12` / 1 |
| 18, Classic Kankuro / `0x21 -> 0x22` | `capture_id_018_action_21 / capture_id_018_phases_21` | `capture_id_018_action_22 / capture_id_018_phases_22` | `0x19 -> 0x12` / 1 |
| 51, Super Choji / `0x17 -> 0x18` | `capture_id_051_action_17 / capture_id_051_phases_17` | `capture_id_051_action_18 / capture_id_051_phases_18` | `0x19 -> 0x14` / 1 |

All five displayed starters have category `0x100`, zero `ActionRecord.damage`, and
repeat 1; their finishers have category `0x200`, raw damage bits `0x3D4CCCCD` (`0.05`),
signature family `0x08000000`, and continuation byte naming the starter. Raw damage is
an input to the common calculator, not an observed HP loss. The zero-damage starter
still has collision and response data; it can select held state `0x4A/0x4B/0x4C` through
the ordinary response selector. Character callbacks may override that selector.

The first four displayed starters set behavior `0x4000`; Super Choji's `0x17` starter
has behavior `0x5` and lacks it. His additional starters `0x19` at
`super_choji_action_19` and `0x1C` at `super_choji_action_1c` also have `0x5`. They
therefore do not obtain the common category-specific guard bypass from
`capture_bypasses_guard`. His separate starter `0x24` at `super_choji_action_24` does
have `0x4041`. The category is shared across both kinds; the guard result cannot be
inferred from category alone.

Sakura and Temari's displayed sequences have two nonterminal phases (both animation-end
condition `-16`, rate `0x100`) followed by terminal `animation == -1`. Classic
Kankuro's sequences include a third nonterminal animation slot `0x3B` before the
terminal. Naruto's starter uses animation slots `0x83/0x84` with rates `0x128/0x100`;
its phase-0 payload is `0x12`, phase 1 is `0x28`. His release uses slots `0x85/0x86`
with the same rates, phase-0 payload `0x12` with bank-0 attack interval 15..15 and
bank-1 interval 6..6, and phase-1 payload `0x2A` with bank-0 interval 0..0.
`naruto_capture_animation_names` identifies these four slots as
`ANM_pnrwhol00..ANM_pnrwhol03`. These are native asset identifiers, not measured hold
durations or recovered player-facing move names.

The sampled airborne signature-context variants also preserve capture and release pairs,
but differ in receiver selector and behavior. Naruto's `0x2C -> 0x2D` pair uses
`0x18 -> 0x12` and release repeat 1; Sakura's `0x29 -> 0x2A` pair uses `0x18 -> 0x15`
and release behavior `0x00104242`. Complete substitution eligibility still depends on
the common predicate and current state.

### Naruto's release callback changes the live record

The displayed `0x25` release's clean `0.05` value is not the value retained through
every response-selection call. Definition `naruto_character_record` has callback table
`naruto_callbacks`; slot 3 contains `naruto_hit_response`. For source action index
`0x25`, that complete callback obtains the remaining-repeat value through
`hit_repeat_value(sender, receiver)` and the live current record through
`fighter_action_record(sender, -3)`, then writes these fields:

| Repeat-helper result | Live `ActionRecord.damage` | `response_sfx` / raw halfword `+0x48` | Response override |
| --- | --- | --- | --- |
| Below 2 | `0x3D99999A` (`0.075`) | `0x32 / -1` | `-1`, allowing common selection |
| Exactly 2 | `0x3D99999A` (`0.075`) | `0x30 / 3` | `0x3F` |
| At least 3 | zero | `-1 / 0` | `0x29` |

These record writes are outside the callback's mode-2 gate; only its receiver motion
writes `attack_scale/planar_scale/vertical_scale` are restricted to that mode. The
response constants are `0x3F` / `0x29`. Ordinary response entry calls selection in mode 2
before pause initialization and damage consumption, so the live callback data matters
before using clean raw damage. The repeat-helper result is conditional on the receiver's
cached source record and remaining count; it is not an elapsed frame count. Damage
division and scaling belong to [Damage](damage.md).

In mode 2, repeat result 2 also writes receiver `vertical_scale = 0.8`; result at least
3 writes `planar_scale = -0.2`. Their float words at
`naruto_release_repeat2_vertical/naruto_release_repeat3_planar` accompany the response
constants above. The order and meaning of the common receiver motion modifiers belong to
[Hit response](hit_response.md#modifiers).

### Full-transform and hold-preserving variants

Two additional complete action arrays, IDs 50 and 84, supply examples of the attachment
branches not used by the first table:

| Definition / pair | Capture / release records | Capture selector / behavior | Release selector / behavior |
| --- | --- | --- | --- |
| 50, Possessed Gaara / `0x20 -> 0x21` | `capture_id_050_action_20 / capture_id_050_action_21` | `0x1B / 0x4041` | `0x13 / 0x4041` |
| 84, Tsunade / `0x2D -> 0x2E` | `capture_id_084_action_2d / capture_id_084_action_2e` | `0x1A / 0x4042` | `0x15 / 0x04004242` |

Possessed Gaara's authored selector `0x1B` maps to held response `0x4E`, which receives
the full anchor transform with relative scale and player `CollisionTransform.dirty`.
Callback slot 3 `gaara_possessed_hit_response` returns `-1` for action `0x20`, so it
supplies no character response override for that starter. The phase sequences at
`capture_id_050_phases_20 / capture_id_050_phases_21` each contain two animation-end
rows and a terminal; release payloads are `0x12/0x28`. The held updater can reselect a
response on the second payload's `0x8` bit because release behavior `0x04000000` is
clear. Other common selector gates still apply.

Tsunade's starter maps selector `0x1A` to held response `0x4D`. Its rows at
`capture_id_084_phases_2d` are two animation-end rows and a terminal. Release rows at
`capture_id_084_phases_2e` have condition `-17`, payload `0x13`, then condition `1`,
payload `0x2A`, then terminal. Her response callback `tsunade_hit_response` has no
`0x2D/0x2E` override. The release's `0x04000000` flag prevents the shared held updater
from using payload `0x8` for reselection while that action is current. In callback
`tsunade_channel3`, action `0x2E` phase 1 secondary event 0 calls
`tsunade_release_event`, but that retail helper is empty. It supplies no receiver
transition. Ordinary action exit and contact routing must therefore be considered
separately from a presumed callback release; no additional callback release is proved by
this call.

### Additional authored release families

Definitions 39 and 47 add representative release families from their complete action
arrays, selected phase sequences, and response callbacks.

| Definition / pair | Capture / release records | Phase starts | Capture / release behavior | Selector low bytes / release repeats |
| --- | --- | --- | --- | --- |
| 39, The Yellow Flash / `0x1D -> 0x1E` | `capture_id_039_action_1d / capture_id_039_action_1e` | `capture_id_039_phases_1d / capture_id_039_phases_1e` | `0x9 / 0x109` | `0x18 / 0x14`, 2 |
| 39 / `0x20 -> 0x21` | `capture_id_039_action_20 / capture_id_039_action_21` | `capture_id_039_phases_20 / capture_id_039_phases_21` | `0x60011 / 0x60091` | `0x17 / 0x10`, 1 |
| 39 / `0x23 -> 0x24` | `capture_id_039_action_23 / capture_id_039_action_24` | `capture_id_039_phases_23 / capture_id_039_phases_24` | `0x60021 / 0x600A1` | `0x17 / 0x12`, 1 |
| 39 / `0x25 -> 0x26` | `capture_id_039_action_25 / capture_id_039_action_26` | `capture_id_039_phases_25 / capture_id_039_phases_26` | `0x4041 / 0x4242` | `0x17 / 0x15`, 4 |
| 47, Classic Naruto's Nine-Tailed form / `0x22 -> 0x23` | `capture_id_047_action_22 / capture_id_047_action_23` | `capture_id_047_phases_22 / capture_id_047_phases_23` | `0x4041 / 0x4201` | `0x19 / 0x15`, 1 |
| 47 / `0x2A -> 0x2B` | `capture_id_047_action_2a / capture_id_047_action_2b` | `capture_id_047_phases_2a / capture_id_047_phases_2b` | `0x4042 / 0x40C2` | `0x18 / 0x12`, 1 |

Each displayed release has category `0x200`, clean raw damage `0.05`, signature bit
`0x08000000`, and continuation byte naming its category-`0x100` starter. The first
three ID-39 starters lack behavior `0x4000` and have nonnegative predecessor bytes
`0x1C/0x1F/0x22`; they are authored chained capture variants rather than independent
starter records. Their callback's pending-release dispatch thresholds are recorded
above. The ID-39 `0x25` starter and both ID-47 starters have predecessor -1 and behavior
`0x4000`. The common automatic handoff still requires outcome 1 and matching accepted
source record; a continuation byte by itself does not establish connection.

The `0x25/0x26` sequences use ID-39 animation slots `0x8A/0x8B` and `0x8C/0x8D`.
Capture conditions are `-16/-16`, release conditions `-16/-18`, each followed by
terminal -1; both have payloads `0x12/0x28`. The release phase 0 attack intervals are
bank 0 `7..19` and bank 1 `10..19`. ID-47's `0x22/0x23` sequences use slots `0x79/0x7A`
and `0x7B/0x7C`, both conditions `-16/-16` and terminal, with payloads `0x12/0x28`;
release phase 0 uses rate `0x80`, then `0x100`. These are static rows and event
windows, not visible-duration measurements. The named sequences resolve from clean
`ActionRecord.row` indices; those clean indices are not runtime phase pointers.

ID-39 release `0x26` also demonstrates a response override through bounded slot-3 target
`yellow_flash_hit_response`: repeat-helper result below 2 selects `0x40`; otherwise
PRNG bit 0 selects `0x2C` when clear or `0x2B` when set. Mode 2 writes receiver
`attack_scale = 1.5` or `0.005`, respectively. This branch does not change the record's
category or free either participant. The clean selector `0x15` therefore does not fix
the release's final response. The wider callback response contract is in
[Hit response](hit_response.md#character-callbacks).

ID-47 response callback `naruto_nine_tails_hit_response` has no override for either
displayed pair. Its channel-3 callback's initial classification-1 dispatch consequently
changes the pending action through the normal setter, while channel 5 later changes
scene bone transforms before common attachment. The pending release, receiver response
and model transform are separate operations, not one unconditional character callback
that destroys the hold.

### Category changes also call cleanup

The Tsunade and Choji mode setters change which live action categories are enabled and
call position cleanup before disabling an active capture variant. Neither helper
searches for or replaces a participant.

Tsunade's `tsunade_set_mode` reacts to a changed `TsunadeCaptureMode.mode`. On its zero
mode, current release indices `0x21/0x27`, or current starter indices `0x20/0x26` with
outcome 1, call capture cleanup. It then restores category words for indices
`0x1E/0x1F/0x24/0x25` from `Fighter.alternate_actions` and zeros them for
`0x20/0x21/0x26/0x27`. `tsunade_mode0_category_indices` and
`tsunade_mode1_category_indices` supply these sets. Mode 1 swaps which set is
restored/zeroed. Callback `tsunade_channel2` supplies the mode from fighter
`contact_flags` bit `0x20` for ID 84. This category-changing cleanup does not alter the
separate `0x2D/0x2E` pair above.

The clean `0x20/0x21` records at `tsunade_action_20/tsunade_action_21` have category
`0x100/0x200` and behavior `0x9/0x1`; neither has `0x04000000`. After the zero-mode
helper clears those live category words, common attachment no longer passes `0xF00`. A
still-held receiver whose partner remains in major 8 reaches the missing-`0x100/0x200`
branch of `response_held_handoff` and enters `(0,0)` on that updater. Position cleanup,
category disabling and receiver transition are separate operations; the helper does not
synchronously free the partner or clear its `opponent` pointer.

For ID 81, `choji_set_mode` reacts to changed `ChojiCaptureMode.mode`. On its zero
mode, a current category-`0x200` record, or category `0x100` with outcome 1, calls
capture cleanup before restoring category words for indices `0x15..0x2A` and zeroing
them for `0x2B..0x37`. Mode 1 swaps the enabled sets. The direct caller
`choji_channel2` gates this helper on fighter ID `0x51` and supplies the same
`contact_flags` bit `0x20` mode. This establishes an interruption path during category
activation changes, without assigning a player-facing name to that mode.

## Attachment scheduling

`fighters_update_character_auxiliaries` refreshes every fighter's model, runs every
fighter's `FighterCaptureVtable.pre_attachment`, runs callback channel 5 for every
fighter, then runs attachment for every fighter. Attachment therefore uses the
transforms resulting from those preceding passes. Its loop is not restricted by positive
pause in that pass; the attachment body's own state/category/partner/anchor gates
still apply.

This order proves when the position binding is applied relative to the examined model
callbacks. It does not prove every indirect invocation or all frame scheduling;
[Battle lifecycle](../session/battle_lifecycle.md) owns the coordinator schedule.

### Selected pre-attachment callbacks and model lifetime

The complete virtual tables for IDs 39, 47, 50 and 84 at
`fighter_id_039_vtable/fighter_id_047_vtable/fighter_id_050_vtable/fighter_id_084_vtable`
all select `fighter_pre_attachment_noop` (`0x002504A0`) for
`FighterCaptureVtable.pre_attachment`. The verified entry is an empty routine. There is
no character-specific model replacement in that particular slot.

`character_dispatch_channel` reads `CharacterCaptureCallbacks.channel5`. For these
current-action indices (all at least 4), it uses the fighter's own `character_callbacks`
table; its contract is owned by
[Character assets](../../game/character_assets.md#per-character-code).

| Definition / channel-5 table | Target before attachment | Bounded effect |
| --- | --- | --- |
| 39 / `yellow_flash_callbacks` | null | No channel-5 call |
| 47 / `naruto_nine_tails_callbacks` | `naruto_nine_tails_channel5` | Under `node_flags & 0x02` and `state_flags & 0x20`, calls `naruto_nine_tails_update_bones`, then hides two optional named objects in its `NarutoNineTailsCaptureScene.auxiliary_scene` by zeroing basis columns and setting `CollisionTransform.dirty`; it does not free a fighter or clear `owned_animation_player` |
| 50 / `gaara_possessed_callbacks` | `gaara_possessed_channel5` | Hides one optional object for actions `0x18/0x1C/0x1D` at cursor gates; its `0x20/0x21` capture pair does not meet those gates |
| 84 / `tsunade_callbacks` | null | No channel-5 call |

The full ID-47 helper `naruto_nine_tails_update_bones` includes authored `0x22/0x23` and
`0x2A/0x2B` capture events, derives reach offsets, and writes selected bone matrices in
its primary and auxiliary scenes. It resolves optional names with argument 2 equal to 1
and skips absent objects. It stores no new participant and contains no model-destruction
call. This is a concrete pre-attachment transform producer; it does not prove every
anchor matrix is always present. General skeleton binding remains in
[Model and skeleton runtime](../../runtime/rendering/model_runtime.md#animation-binding-to-scene-nodes).

The four record-provided anchor strings are respectively `OBJ_eff_dummy_fouhol0`,
`OBJ_eff_dummy_nrvhol0`, `OBJ_eff_dummy_gavhol0`, and `OBJ_eff_dummy_tnwhol0`, named
by `yellow_flash_capture_anchor_name`, `naruto_nine_tails_capture_anchor_name`,
`gaara_possessed_capture_anchor_name` and `tsunade_capture_anchor_name`. These are
nonempty names, not successful lookup in every loaded scene.

Successful common setup `fighter_load_character` allocates and publishes
`owned_animation_player` before returning success; `fighter_load_character_record` then
initializes `(0,0)` and enables `node_flags & 0x02`. The initial reciprocal participant
graph and its separate registry owners are established in
[Battle entities](../session/battle_entities.md#initial-cross-reference-graph).
However, `fighters_update_character_auxiliaries` itself checks only each list node's
presence before its model/attachment passes, not `node_flags & 0x02`.
`capture_attach_receiver` reads partner state without first checking `opponent` for
null. Successful construction plus ordinary scheduling explains the intended
prerequisites; it is not a proof of availability under every malformed or interrupted
graph.

The selected `FighterCaptureVtable.ai_update` functions
`yellow_flash_ai_update / naruto_nine_tails_ai_update / gaara_possessed_ai_update / fighter_ai_update_2ee330`
all return zero after an optional packed-mode BTL call. They do not request removal by
their return values. Their concrete destructors
`fighter_id_039_destroy / fighter_id_047_destroy / fighter_id_050_destroy / fighter_id_084_destroy`
all reach common `fighter_cleanup -> fighter_release_handles`, then
`fighter_base_destroy`, before freeing the fighter. ID 47 first destroys its auxiliary
scene/model trio; ID 50 first releases its 17-entry geometry bank. The instance
ownership is documented in
[Common fighter-owned children](../session/battle_entities.md#common-fighter-owned-children).

For capture lifetime specifically, those destructors and the inspected common teardown
contain no call to `action_exit_record / fighter_cancel_current_action` and no explicit
held-partner release or reciprocal `opponent` invalidation. Common handle release
destroys and clears the player, but does not clear the other fighter's pointer. The
current-state setter's interruption cleanup and whole-fighter destruction are therefore
distinct paths. The normal form replacement rebuilds both participants, as recorded in
[Awakening](../characters/awakening.md#static-reconstruction-order); an isolated
participant removal between receiver update and attachment remains unproved. Neither the
local anchor scratch pointer nor the full-transform write establishes general
stale-pointer protection.
