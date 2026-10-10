# Projectile lifecycle

## Research coverage

Established for retail NA2 (`SLPS-25837`): the 182 configuration records,
complete factory/class crosswalk, common construction and ownership, side and
lineage identity, all factory post-spawn/service/update contracts, throwing
and weighted emission, staged and immediate retirement, and bounded deduplication.
The default response records, direct record writers and all final factory
record-bearing callbacks are checked separately from the scalar damage path.
Open: deeper subclass state machines, indirect callers, unidentified service
types and field meanings, global limits outside the traced paths, and callback
cadence. Vector-2 and handle interpretations remain tentative.

Routines, fields and data use the names in `@annotations/NA2`; per-routine
facts are in their annotation comments. Addresses are live. The inputs are the
retail `BTL.BIN` and resident `SLPS_258.37`
([file identities](../../game/files/file_identities.md)).
Static callback counts establish neither seconds nor animation rates.

Derived motion and local schedules belong to
[Projectile motion and local timing](projectile_motion.md); fighter candidate
routing to [Target selection](../combat/target_selection.md#collision-candidates-and-routing-order);
resident queries to [Collision](../combat/collision.md#resident-segmentenvironment-broad-and-narrow-phases)
and [Stage surface attributes](../stages/stage_surface_attributes.md#authored-word-and-geometric-class);
contact credit to [Battle statistics](../session/battle_statistics.md#projectile-contact-deduplication);
support identifiers to [Support mechanics](../characters/support_mechanics.md);
random selection to [Randomness](../../runtime/randomness.md#mt-wrappers).
[Damage](../combat/damage.md), [Substitution](../characters/substitution.md),
[Hit response](../combat/hit_response.md), [Animation runtime](../../runtime/animation_runtime.md)
and [Render submission](../../runtime/rendering/render_submission.md) own the
corresponding systems.

## Lifecycle summary

1. `transient_actor_create` accepts a config index; `projectile_spawn_external_id`
   first finds the matching signed external ID.
2. `transient_actor_factory` selects a class from the config, and
   `transient_actor_initialize` binds the shared record and inverse side tag.
3. Spawn copies both vectors and runs post-spawn initialization before copying
   parent lineage or inserting the object into the manager.
4. `transient_manager_update` runs activation pre-work and the survival
   callback. A zero survival result unlinks the object and invokes its deleting
   destructor immediately.
5. `transient_manager_second_pass` visits service-enabled objects independently
   of the survival decision.
6. The common retirement helpers enter state 6. Common dispatch later promotes
   it to state 7, and a subsequent survival callback returns zero. Some derived
   callbacks instead finish and return zero in the current manager invocation.
7. Class-aware destruction releases derived and common resources. Manager
   teardown drains every remaining entry.

## Configuration and factory

### Record set

`projectile_configs` at `0x0089C910` contains 182 `ProjectileConfig`
records, each `0x68` bytes, ending at `0x008A1300`. Its records use 97
of the factory's 103 selectors (`0x00..0x66`). An out-of-range selector uses
bare `ccProjectile`, allocation `0x290`.

The config index is unchecked before the record is read. External-ID lookup is
linear and keeps the first signed-halfword match. There are 83 distinct external
IDs: zero occurs in 100 records and every nonzero ID is unique. Failed lookup
passes index -1 to spawn without a guard. Config index, external ID, class
selector and manager serial are separate identities.

The external-ID wrapper supplies no factory extra or parent. Its optional
scalar override applies only for flag 1, using the selected fighter's current
`ActionRecord.damage` or zero when that record is absent; the spawned object
itself is not null-checked before this write. The sole direct caller requests
external ID `0x27`, uses the same vector twice, and disables the override:
it resolves config `0x12`, selector `0x07`, `ccProjectileMakibishiLauncher`.

### Proven record fields

`ProjectileConfig` names the demonstrated fields. Names such as
`constructor_value`, `helper_word`, `config14`, `value38`,
`value3c`, `value40` and `value48` preserve mechanical uses without
claiming a game-design meaning. The record pointer refers to the global table,
not an object-local copy.

### Common profiles

The records use 56 profile indices in `0x00..0x40`.
`projectile_profiles` supplies the service mode and signed active/retiring
service IDs; -1 disables the corresponding submission. Configs `0xB4/0xB5`
force mode 4. Profile `0x22` also has a random-selection branch.

The special active-service value `0x14` creates the owned primary service:
modes 1/3 use `0xA0` bytes, modes 2/4 use `0x120`. Mode 2 with profiles
`0x11..0x13` additionally creates a `0xA0` secondary service. Construction,
service submission and cleanup agree on the mode-specific ownership. A
non-null primary service requires mode 1..4; another mode reaches a null-address
store during cleanup. These observations do not identify the concrete service
types or collision shapes.

### Additional binder side effects

Binding sets the object's kind to 1 and creates an optional notification for
record notification modes 1/2; mode 0 creates none. Service-mode selector 1
sets `service_state` to 3. `player_scalar_enabled` chooses a fighter-derived
`config_scalar`; otherwise the record supplies it.

Profile setup compares the two fighters' sections, retains equality in
`same_section`, and copies the low byte of the opposite-tag fighter's
section to `opposite_section`. Binding ends with `bound = 1`.
The handle's back-reference write and notification setup assume allocation
succeeded even though their allocation branches check for null.

### Activation setup

`activation_selector` controls common orientation setup. The names identify
stored axes mechanically; camera/world-space meaning remains open.

| Selector | Record count | Orientation setup |
| ---: | ---: | --- |
| 0 | 77 | None |
| 1 | 53 | Quantized random axis 1 and a constant-derived scalar |
| 2 | 9 | Quantized random axis 2 and a constant-derived scalar |
| 3 | 5 | Axis 1 = pi/2 |
| 4 | 0 | Axis 2 = pi/2 |
| 5 | 2 | Axis 0 = pi/2 |
| 6 | 0 | Axis 0 = -pi/2 |
| 7 | 36 | Default, no orientation write |

All branches enter state 2 and clear the notification's activation byte when
present. Values outside 0..6 use the default exit.

### Record-controlled response selectors

The response bodies' deeper combat effects are not decoded here. Every retail
record fits these bounds:

| Field | Table | Accepted values | Distinct retail values | Retail maximum |
| --- | --- | --- | ---: | ---: |
| `action_selector` | `projectile_action_response_table` | 0..22 | 16 | `0x16` |
| `response16_selector` | `projectile_response16_table` | 0..23 | 15 | `0x17` |
| `response17_selector` | `projectile_response17_table` | 0..22 | 17 | `0x16` |
| `contact_selector` | `projectile_contact_response_table` | 0..23 | 18 | `0x17` |
| `response32_selector` | `projectile_response32_table` | 0..14 | 9 | `0x0E` |

`response16_selector = 2` can take an additional response after entering
state 6. The common flag accessor returns `flags` verbatim; observed filters
include bits `0x04/0x08`.

The separate positional-service ID distribution is -1 (105 records), 9 (2),
`0x11` (1), `0x12` (29), and `0x13` (45); -1 disables construction.

### Tail-field consumers and mutable records

Clay Bird N, Clay Bird S and Ink Snake N first-activation paths rewrite the
shared record: `action_selector = 0x0E`, and the response16, response17 and
contact selectors become `0x0D`. Because every instance binds the same table
record, these changes affect later consumers and instances.

The helper-scalar relationships are:

| Class | Helper scalar |
| --- | --- |
| `ccProjClayBrdN`, `ccProjExplodeS`, `ccProjInkSnakeN` | Record `helper_scalar` |
| `ccProjClayBrdS` | 1.2 times that scalar |
| `ccProjExplodeL` | 1.5 times that scalar |

Clay Bird N also truncates `helper_byte_source` into a helper byte on one
branch. The config tail also supplies the response-record fields below.

### Response records and damage ownership

`stage_slot9_object_initialize` calls `projectile_response_record_build`
(`0x00729570`) for all 182 configurations. Each resulting `ActionRecord`
is `0x54` bytes in `projectile_response_records` (`0x008D6B60`). Initialization
leaves damage `0`, repeat count `1` and row `0`, and forces category
`0x01000000`, which suppresses ordinary and guarded HP sampling. Config
tail values populate response data without replacing those four fields:

| Config offsets | Response-record offsets |
| --- | --- |
| Word `+0x4C` | Flags `+0x14` |
| Halfwords `+0x50/+0x52` | Selector bytes `+0x2C/+0x2D` |
| Halfwords `+0x54/+0x56` | `+0x30/+0x32` |
| Halfwords `+0x58/+0x5A/+0x5C/+0x5E/+0x60` | `+0x46/+0x48/+0x4A/+0x4C/+0x4E` |
| Float `+0x64` | Knockback `+0x28` |

Each tail assignment skips its signed or floating `-1` sentinel.
`projectile_response_record_get` (`0x0072F420`) returns either the private
`attack_record_override` or the shared config-indexed record; it allocates
nothing. `projectile_response_record_ensure` (`0x0072F3A0`) allocates and
copies one default record only when that override is absent.
`transient_record_get` (`0x00734300`) copies the selected record to the
receiving side's entry in `projectile_response_scratch` (`0x008DA890`), a
two-record buffer overwritten by the next lookup for that side. Neither
the default getter nor the scratch lookup creates per-hit ownership.

The bounded mutation census covers all seven direct override-pointer stores,
all nine direct clone-helper callers, all fifteen direct getter callers and
all ten distinct `+0x58` callbacks across the 95 final factory vtables.
The callbacks comprise 84 root no-ops, three Dist2Speed-family tables and
eight singleton tables. Their record writes affect response selectors or
pause fields; all preserve category, damage, repeat count and row.
The checked clone/getter callers and carrier command application likewise
introduce no nonzero record damage. Chase's phase-2 override can change
category to `1`, but retains damage `0`; removing the category gate alone
therefore creates no ordinary HP amount. Hak1 can change response data in
a shared default when no private clone exists.

The separate generic object-hit amount comes from the instance's
`config_scalar`, not `ActionRecord.damage`. Common binding either copies
the config scalar or samples the inverse-tag fighter's current record
damage multiplied by `fighter_projectile_scalar` through the player-scalar
branch. Support emitters and selected subclass
updates can replace that instance scalar. This explains why a zero-damage
response record can accompany a nonzero direct amount.
[Damage source and count attribution](../combat/damage.md#ordinary-object-and-support-attribution)
owns its calculator route and count ordering;
[authored support records](../characters/support_mechanics.md#authored-support-damage-records)
own the support scalar snapshot.

This census does not exclude arbitrary aliased or indirect writes, other
kind-1 source implementations, or later mutations outside the inspected
callers. It establishes the default records and checked factory family,
not ordinary-play execution of every projectile or a player move name.

### Complete post-spawn initialization inventory

Across 95 final factory vtables, 79 keep the root no-op; 16 classes use 11
distinct overrides. Their complete operations are in the post-spawn
annotations. This initialization always precedes parent inheritance and list
insertion, so an override cannot depend on inherited parent metadata.

The notable record/config exceptions are the Insect Launcher scalar copy for
config `0x98`, Homing Delay's four record-derived inputs and config
`0x1B` mode flag, and the Parabola-family handle-entry rewrite for configs
`0x30/0x9A`: side tags 0/1 select `0x11000/0x22000` and clear the
other entry word. Dist2Speed and its two sharing classes select one of 42
resident vectors using an arithmetic-shifted random value and signed
remainder, scale it by 7.5, then clear two components. Numbness Smoke starts
its private count at 200.

LunFan and LunLinear share the record-to-instance contract. The child-pair
data is `(0x45,0x48), (0x46,0x49), (0x47,0x4A)`. Their retail records
(`0x4C/0x4E`) request child `0x46` and produce child config `0x48`.
A first-pair match reads before the six initialized local words; its intent
and reachability remain unresolved.

Both retail records supply count 10, delay bound 3 and speed-spread word 10;
their `value48` inputs are approximately 0.785398185 and 70. Post-spawn
setup initializes the local cursor to -1.0. Their motion consumers are in
[emitter schedules](projectile_motion.md#emitter-callbacks-and-their-local-schedules).

### Representative records with exact class identity

Configs `0x7A, 0x7B, 0xB3, 0xB4, 0xB5` construct the character-carrier
family through `ccProjChar` and `ccProjectile`. External ID `0x006B`
uniquely identifies `ccProjSZWExcItemTonton`, whose constructor uses resource
`2szwbod1.ccs`.

### Complete selector-to-class crosswalk

This covers all 103 factory selectors. Values are hexadecimal; `none`
means external ID zero. Six selectors are unused by retail records:
`0x02, 0x12, 0x13, 0x1A, 0x22, 0x63`. Selector `0x24` is used by
config `0x4D` / external ID `0x003F` but constructs bare `ccProjectile`.
Names retain the exact retail RTTI spelling, including `ccProjecShotgunLauncher`.

| Selector | Allocation | Exact class | Config indices | Nonzero external IDs |
| ---: | ---: | --- | --- | --- |
| 0x00 | 0x290 | ccProjectileStraight | 0x07, 0x08, 0x09, 0x19, 0x20, 0x22, 0x2F, 0x31, 0x32, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x52, 0x6A, 0x79, 0x7E | 0x0024, 0x002E, 0x0033, 0x005B |
| 0x01 | 0x2E0 | ccProjectileChase | 0x04, 0x25, 0x51 | 0x0023 |
| 0x02 | 0x2A0 | ccProjectileLauncherDelay | unused | none |
| 0x03 | 0x290 | ccProjDist2Speed | 0x00, 0x01, 0x02, 0x03, 0x11, 0x14, 0x15, 0x16, 0x2C, 0x3A, 0x3D, 0x42, 0x43, 0x55, 0x75, 0x77, 0x8F, 0xA7, 0xAC, 0xAD, 0xAE, 0xAF | 0x000F, 0x0010, 0x0011, 0x0012, 0x0016, 0x001C, 0x003D, 0x006C, 0x0021 |
| 0x04 | 0x2D0 | ccProjectileTenten1 | 0x05 | 0x0034 |
| 0x05 | 0x2A0 | ccProjectileTenten2Launcher | 0x06 | 0x0035 |
| 0x06 | 0x2A0 | ccProjectileMakibishi | 0x13 | none |
| 0x07 | 0x2A0 | ccProjectileMakibishiLauncher | 0x12, 0x9C | 0x0027, 0x006E |
| 0x08 | 0x290 | ccProjectileTenten0Launcher | 0x0E | 0x0013 |
| 0x09 | 0x2B0 | ccProjectileHoming | 0x10, 0x17, 0x1C, 0x1D, 0x24, 0x27, 0x2D, 0x33, 0x4F, 0x82, 0x99 | 0x0029, 0x002A |
| 0x0A | 0x2E0 | ccProjSoundWave | 0x38, 0x39 | 0x0019, 0x001A |
| 0x0B | 0x2B0 | ccProjHomingScatter | 0x37 | 0x0018 |
| 0x0C | 0x2C0 | ccProjectileInsectLauncher | 0x0F, 0x98 | 0x0015, 0x0065 |
| 0x0D | 0x2E0 | ccProjectileKibakukunai | 0x0B | 0x0025 |
| 0x0E | 0x340 | ccProjectileKibakufuda | 0x0D, 0xA0 | 0x0028 |
| 0x0F | 0x290 | ccProjectileExplosion | 0x18, 0x28, 0x29, 0x2A | none |
| 0x10 | 0x290 | ccProjectileKagebunshinLauncher | 0x0A, 0x88, 0xA2 | 0x002B, 0x0057, 0x005E |
| 0x11 | 0x2A0 | ccProjectileStickHead | 0x1A | none |
| 0x12 | 0x290 | ccProjectile | unused | none |
| 0x13 | 0x290 | ccProjectile | unused | none |
| 0x14 | 0x2B0 | ccProjectileHomingDelay | 0x1B, 0x70, 0x89, 0xA3 | 0x004C |
| 0x15 | 0x290 | ccProjectileParabola | 0x0C, 0x30, 0x36, 0x3B, 0x4B, 0x9A, 0xA1, 0xB0 | 0x0026, 0x002F, 0x0017, 0x001D, 0x0069, 0x0054, 0x006F |
| 0x16 | 0x290 | ccProjectilePoisonExplosion | 0x1E | none |
| 0x17 | 0x2B0 | ccProjectileLauncherHak1 | 0x1F | 0x0036 |
| 0x18 | 0x2B0 | ccProjectileLauncherHak1 | 0x21, 0x26, 0x6B, 0x6C, 0x6D | 0x0037, 0x0048, 0x0049, 0x004A |
| 0x19 | 0x2B0 | ccProjectileLauncherHak1 | 0x23 | 0x0038 |
| 0x1A | 0x330 | ccProjBakutiBall | unused | none |
| 0x1B | 0x2A0 | ccProjStickKibakuFuda | 0x2E | 0x002D |
| 0x1C | 0x2C0 | ccProjFloatLauncher | 0x34 | 0x0032 |
| 0x1D | 0x290 | ccProjecShotgunLauncher | 0x3C, 0x3F, 0x40, 0x41 | 0x001B, 0x003A, 0x003B, 0x003C |
| 0x1E | 0x2B0 | ccProjFixedFire | 0x44, 0x9B | none |
| 0x1F | 0x330 | ccProjBakutiBall | 0x35, 0x80 | 0x0030, 0x006A |
| 0x20 | 0x2A0 | ccProjKunaiBomb | 0x2B | 0x002C |
| 0x21 | 0x2A0 | ccProjSyncHand | 0x3E | 0x0039 |
| 0x22 | 0x2A0 | ccProjBoomerang | unused | none |
| 0x23 | 0x2C0 | ccProjLunFan | 0x4C | 0x003E |
| 0x24 | 0x290 | ccProjectile | 0x4D | 0x003F |
| 0x25 | 0x2C0 | ccProjLunLinear | 0x4E | 0x0040 |
| 0x26 | 0x2E0 | ccProjSandPellet | 0x50 | none |
| 0x27 | 0x300 | ccProjIronRain | 0x53 | none |
| 0x28 | 0x2A0 | ccProjectileScoLauncher | 0x54 | none |
| 0x29 | 0x2E0 | ccProjectileNrwCombo | 0x56, 0x57 | none |
| 0x2A | 0x470 | ccProjTest | 0x7A | none |
| 0x2B | 0x470 | ccProjCharNRW | 0x7B | none |
| 0x2C | 0x2D0 | ccProjClayBrdN | 0x58 | 0x0041 |
| 0x2D | 0x2B0 | ccProjLauncherClayBrdS | 0x5F | 0x0042 |
| 0x2E | 0x2A0 | ccProjLauncherClayBrdSA | 0x60 | 0x0043 |
| 0x2F | 0x2D0 | ccProjClayBrdS | 0x59, 0x5A | none |
| 0x30 | 0x2B0 | ccProjLauncherClayBrdU | 0x61 | 0x0044 |
| 0x31 | 0x2B0 | ccProjLauncherClayBrdUA | 0x62 | 0x0045 |
| 0x32 | 0x2B0 | ccProjLauncherClayBrdH | 0x65 | none |
| 0x33 | 0x2C0 | ccProjClayBrdU | 0x5B | none |
| 0x34 | 0x2C0 | ccProjClayBrdU | 0x5E | none |
| 0x35 | 0x2B0 | ccProjLauncherClaySpd | 0x63 | 0x0046 |
| 0x36 | 0x2B0 | ccProjLauncherClaySpd | 0x64 | 0x0047 |
| 0x37 | 0x330 | ccProjClaySpd | 0x5C | none |
| 0x38 | 0x340 | ccProjClaySpd2 | 0x5D | none |
| 0x39 | 0x2B0 | ccProjExplodeS | 0x66 | none |
| 0x3A | 0x2B0 | ccProjExplodeL | 0x67 | none |
| 0x3B | 0x2B0 | ccProjDDRFire | 0x68 | none |
| 0x3C | 0x2A0 | ccProjLauncherDDRFire | 0x69 | none |
| 0x3D | 0x2A0 | ccProjSIWTrap | 0x6E | 0x004B |
| 0x3E | 0x2F0 | ccProjCHYSkillKunai | 0x6F | none |
| 0x3F | 0x2B0 | ccProjLauncherTewAwake | 0x71 | 0x004D |
| 0x40 | 0x2B0 | ccProjLauncherTewRoll | 0x72 | 0x004E |
| 0x41 | 0x2B0 | ccProjLauncherTewKunai | 0x73 | 0x004F |
| 0x42 | 0x2A0 | ccProjLauncherTewAnki | 0x74 | 0x0050 |
| 0x43 | 0x2A0 | ccProjTewSkillAnki | 0x76 | none |
| 0x44 | 0x2A0 | ccProjSchSkillSenbon | 0x78 | none |
| 0x45 | 0x290 | ccProjSCOGen | 0x91 | 0x001F |
| 0x46 | 0x2B0 | ccProjDDRGen | 0x8A | 0x001E |
| 0x47 | 0x2A0 | ccProjSCVGen | 0x92 | 0x0022 |
| 0x48 | 0x290 | ccProjectileNumbnessBall | 0x85 | 0x0031 |
| 0x49 | 0x2B0 | ccProjectileNumbness | 0x86 | none |
| 0x4A | 0x290 | ccProjNumbnessSmoke | 0x87 | none |
| 0x4B | 0x2C0 | ccProjSNWCmbULauncher | 0x96, 0x97 | none |
| 0x4C | 0x290 | ccProjINWFlower | 0x7F | none |
| 0x4D | 0x2C0 | ccProjExcORWSnake | 0x9D | none |
| 0x4E | 0x290 | ccProjTripleChase | 0x7D | 0x0051 |
| 0x4F | 0x4E0 | ccProjCharNRWOtherSelf | 0xB3 | none |
| 0x50 | 0x290 | ccProjKNWbuddy | 0x9E | none |
| 0x51 | 0x290 | ccProjDDRExcItemLauncher | 0x8C | 0x0058 |
| 0x52 | 0x2B0 | ccProjDDRExcItemBullet | 0x8B | none |
| 0x53 | 0x290 | ccProjExplode3 | 0x81 | none |
| 0x54 | 0x290 | ccProjDDRBuddy | 0x8D | none |
| 0x55 | 0x290 | ccProjDDRBuddyLauncher | 0x8E | none |
| 0x56 | 0x2A0 | ccProjSCVExcItemFire | 0x93 | 0x0061 |
| 0x57 | 0x2A0 | ccProjYMTSkillYari | 0xA4, 0xA5, 0xA6 | none |
| 0x58 | 0x2A0 | ccProjSSWGoukakyu | 0xA8 | none |
| 0x59 | 0x2D0 | ccProjInkSnakeN | 0xAA | none |
| 0x5A | 0x2F0 | ccProjInkBrdN | 0xA9 | none |
| 0x5B | 0x330 | ccProjInkMouseN | 0xAB | none |
| 0x5C | 0x2B0 | ccProjSCVSkillPupBullet | 0x94, 0x95 | none |
| 0x5D | 0x470 | ccProjCharSZWBuddyTonTon | 0xB4 | none |
| 0x5E | 0x290 | ccProjTEWExcItemKagura | 0x83 | 0x005A |
| 0x5F | 0x290 | ccProjSIWExcItemRakushiki | 0x84 | 0x005C |
| 0x60 | 0x290 | ccProjKNWBuddyShikomi | 0x9F | none |
| 0x61 | 0x290 | ccProjSCHExcItemSenbon | 0x90 | 0x0062 |
| 0x62 | 0x2A0 | ccProjNWVGen | 0x7C | 0x0020 |
| 0x63 | 0x290 | ccProjectile | unused | none |
| 0x64 | 0x290 | ccProjBlueSmoke | 0xB1 | none |
| 0x65 | 0x290 | ccProjWhiteSmoke | 0xB2 | none |
| 0x66 | 0x470 | ccProjSZWExcItemTonton | 0xB5 | 0x006B |

## Construction and object layout

### `ccProjectile`

`transient_actor_construct` builds the list-child base, installs the root
vtable and initializes common fields. `typed_resource_setup` creates
the `0x24`-byte handle, which retains a projectile back-reference and two
associations. Terminal paths signal it; root cleanup signals and releases it.
The handle's participation in state/effect notification is a medium-confidence
interpretation; its owned type remains unidentified.

### `ccProjChar`

`ccProjChar` directly derives from `ccProjectile`; its constructor builds
four additional members/containers and runs the carrier reset. Common carrier
cleanup releases the resource and pointer-array members before continuing to
the root chain. Its deleting destructor tears down the derived containers,
restores parent vtables, and frees the object only for a positive deleting flag.

### Representative derived cleanup

Both Tonton constructors acquire a four-byte one-entry pointer array. Their
class destructors reach the common carrier cleanup that releases that array,
then the shared containers, root cleanup and final heap release.
`ccProjCharNRW` first releases two extra owned resources. The manager's
deleting call therefore reaches class-specific ownership, rather than simply
freeing the base allocation.

### Core instance fields

`Projectile` and `ProjectileManager` name the common fixed-layout fields.
`config` is shared mutable configuration; `next/linked` belong to list
ownership; `serial` belongs to manager identity; and lineage and support
fields retain association without retaining a parent or support-object pointer.
The two spawn-vector stores have different contracts: vector 1 initializes
the current and saved position; vector 2 is subclass-dependent. Interpreting
vector 1 as position has medium confidence; no universal aim/destination/
direction label is established for vector 2.

The carrier's embedded members are initialized at `+0x2D4`, `+0x300`,
`+0x350` and `+0x3B0`; container teardown uses `+0x3C0`, `+0x360`
and `+0x300`, and handle teardown uses `+0x2D4`. Two smaller members
start at `+0x410` and `+0x420`. Their full widths and types remain open,
so these member boundaries retain raw offsets.

## Spawn, side identity, and lineage

`transient_actor_create` returns null before allocation for a side other than
0 or 1. A valid side becomes `side_tag = 1 - side`. Factory allocation can
return null, but spawn binds and writes without checking it; this chain assumes
successful allocation and has no recoverable allocation-failure path.

The two vectors and post-spawn callback are followed by parent inheritance.
A non-null parent supplies support metadata and its external ID. Lineage tuple assignment and table
work additionally require its signed lineage key in 0..196; an out-of-range
key skips that work, but the external-ID and support copies still happen.
No parent pointer is retained.

| Side tag | `transient_actor_opposite_side` | Opposite-tag lookup | Same-tag lookup |
| ---: | ---: | --- | --- |
| 0 | 1 | Second battle fighter | First battle fighter |
| 1 | 0 | First battle fighter | Second battle fighter |

A child spawned with the parent's numeric spawn side inherits the same tag
after the second inversion. In contrast, the common contact callback's
parentless config-1/current-config emission passes the current tag directly,
so it gets the opposite tag and no parent-copy fields; current config
`0x6F` chooses config 1. These are distinct association routes.

Homing consumers use the same-tag fighter for tracked or snapshotted position
([homing strategies](projectile_motion.md#homing-target-data-and-the-delayed-strategy)).
A universal owner/target interpretation of the side tag is not established.
Fighter candidate routing also reads side, support flag, external ID and
`contact_filter`, under the Target selection document's gates.

### Support-notification metadata

The two traced support emitters spawn without a parent, set `support_notify`
to 1, and store the support object's allocated identifier in
`support_identifier`. Children inherit both fields. Common contact notifies
only when the enable byte equals 1, using the numeric spawn side and retained
identifier. This retains support association through descendants without
holding a support-object pointer.

### Higher-level spawn wrappers

`projectile_spawn_with_scalars` forwards factory extra and parent, checks
the returned object before post-initialization, and writes `scalar1`.
Homing Delay (selector `0x14`) additionally receives an argument through
its setter and a converted signed count. The sole direct caller requests
config `0x17`, ordinary Homing, with no extra or parent; it uses only the
ordinary scalar write.

`projectile_spawn_with_required_argument` returns null when its required
argument is null, otherwise forces no extra or parent and applies the same
post-initialization. No direct call or aligned function-pointer reference
was found in retail BTL; its reachability remains open.

### Throwing-skill emission interfaces

The skill and projectile class hierarchies are separate. The throwing-skill
event gate calls the emission virtual method once when the service event value
reaches the table threshold and the emission latch is clear, then sets the
latch. Reset ownership and the threshold's time unit remain open.

The complete direct-subclass interface contains TEN001, INO001, KNK000 and
SIN001. TEN001 and INO001 use counted emitters, constructing respectively
config `0x17` (`ccProjectileHoming`) and config `0x19`
(`ccProjectileStraight`), with no parent. Their skill keys are applied
after spawn through `projectile_skill_set_lineage`; INO001 sets
`scalar1 = 35.0` and constructs each aim vector locally. No retained
target pointer is passed to common spawn.

KNK000 emits through a separate schedule helper from skill states 2/3/4.
Its nominal emission virtual entry instead writes to address zero. The schedule
uses the high half of a service word; admitted entries advance the entry index
and can emit several projectiles in one invocation.

| Group | Thresholds | Config | Stop entry | Other initialized entries |
| ---: | --- | ---: | ---: | --- |
| 0 | 5 | `0x0C` | 1 | Entries 2..5 zero |
| 1 | 1, 8, 15 | `0x0C` | 3 | Entries 4..5 zero |
| 2 | 1, 7, 14, 21, 32 | `0x0C` | 5 | None |

Threshold 10000 stops before emission and index advancement. Config
`0x0C` is Parabola; successful spawns receive locally calculated scalars and
the skill's lineage keys. No seconds or player-facing skill name is assigned.

SIN001's emission entry is a no-op; its inspected skill update instead builds
and registers a `0xBE0`-byte `ccSklObjInsPillar`. The throwing base-class
name therefore does not prove that every subclass emits a `ccProjectile`.
No child descriptor of these four throwing subclasses was found.

### TEN000 weighted emission

TEN000 is a separate weighted emitter. It requires its counter to exceed the
start threshold, attempts to be below the attempt limit, and the counter
difference modulo its interval to equal 1. It increments attempts after the
selected branch. Signed-byte weights accumulate; `prng_inclusive(99)`
selects the first cumulative weight above its result. Both initialized lists
have positive weights totalling 100, so they always select an entry; the
general failed-selection index would be -1.

Initialization selects by the skill key:

| Key | Entries | Attempt limit |
| ---: | ---: | --- |
| `0x23` | 5 | Random 3..5 |
| `0x6D` | 21 | Random 2..4 |

Both set start threshold 10 and the other setup halfword to 1; the interval
is the signed conversion of 30.0 divided by the attempt limit. Construction
clears the counters, limits and list first. Type 0 calls the projectile emitter,
type 1 another emitter, and other types skip both.

The five-entry list is entirely type 1, with argument/weight pairs
`(0x24,20), (0x23,20), (0x25,20), (0x27,30), (0x28,10)`.
The 21-entry list is:

| Entry | Type | Emitter argument | Weight |
| ---: | ---: | ---: | ---: |
| 0 | 1 | `0x02` | 7 |
| 1 | 1 | `0x23` | 7 |
| 2 | 1 | `0x24` | 4 |
| 3 | 1 | `0x06` | 3 |
| 4 | 1 | `0x07` | 4 |
| 5 | 1 | `0x08` | 3 |
| 6 | 1 | `0x09` | 3 |
| 7 | 1 | `0x0A` | 2 |
| 8 | 1 | `0x25` | 6 |
| 9 | 1 | `0x26` | 5 |
| 10 | 1 | `0x27` | 4 |
| 11 | 1 | `0x28` | 6 |
| 12 | 1 | `0x29` | 5 |
| 13 | 1 | `0x2A` | 4 |
| 14 | 1 | `0x2B` | 7 |
| 15 | 1 | `0x2F` | 7 |
| 16 | 1 | `0x30` | 7 |
| 17 | 0 | `0x0C` | 7 |
| 18 | 0 | `0x0D` | 3 |
| 19 | 0 | `0x35` | 4 |
| 20 | 0 | `0x30` | 2 |


Projectile emission forwards config and skill side without a parent, then
applies skill lineage. Config `0x30` also receives `scalar2 = 5.0` and a
random-result-plus-30 scalar. The emitter's caller-local config substitution
is described under Limits and pooling.

## Manager ownership, callbacks, and cleanup

The manager owns a singly linked list, count, insertion serial and optional
shared service. Its allocation is `0xD0` bytes. Spawn inserts only when
`linked != 1`; insertion repairs head/tail, sets the flag, assigns the old
serial and increments both serial and active count. When both optional services
exist, insertion registers the object's notification with the manager service.

### Serial identity helpers

`transient_actor_find_serial` returns the first matching object or null.
`projectile_serial_retiring` returns zero only for a found object outside
states 6/7; an absent manager/serial or retiring object returns one. Serial is
separate from configuration and external-ID identity.

### Main update/removal interface

`update_disabled` gates the main pass. The manager preserves each next
pointer before activation and update. A zero survival result immediately
unlinks and invokes the class deleting destructor with flag 1. Service results
do not provide an additional removal decision.

### Activation gate before the survival/update callback

Activation pre-work admits an object when `activated` is zero and `delay`
is nonpositive. It latches activation; unless state is 6/7, it performs common
orientation/state setup, clears delay, runs the activation callback and creates
the optional positional service. Every exit clears `transient_flag`.
The root survival callback instead decrements a positive delay and returns one
before state dispatch or later virtual callbacks.

Unlinking repairs list ownership, clears `linked`, decrements count and
signals/detaches the optional notification. It does not free the object.
Deleting destruction follows. Manager-wide cleanup drains tail-to-head,
including the final head, clears the separate 19-service array, releases the
shared service and resets list/count/serial/gates. Teardown then destroys its
embedded member, frees the manager and clears the global pointer.

Root cleanup releases mode-selected primary service, auxiliary allocation,
handle and secondary service; detaches the notification; drains the owned
heap-node chain; and resets common state and linkage. Notification detach
signals its owner rather than freeing that helper directly. Derived destructors
add their own releases before the common chain.

### Collision-facing interface

`service_disabled` gates the pass, and only objects with `service_enabled`
nonzero are dispatched. The pass establishes/restores the resident context
and finishes with the manager's shared service.

The root service callback always returns one. It skips its work while delay is
positive, activation is clear or state is below 2. Otherwise transient setup
comes first when requested, followed by either signed service-ID submission or
the owned mode-selected service, then common post-service work. This connects
profile ownership to submission and cleanup without establishing internal shape
semantics.

`projectile_segment_query` forwards two vector pointers and a 32-bit filter,
with resident options `(1,0,-1)`, returning the floating result unchanged.
The Tonton paths establish -1.0 as their no-result sentinel. Its 13 direct
callers in seven classes all compare against that sentinel; OtherSelf also
checks another numeric threshold.

| Filter | Direct uses |
| ---: | ---: |
| `0x20000001` | 7 |
| `0x40000001` | 5 |
| `0x40000000` | 1 |

The class-facing filters establish neither an internal collision shape nor
damage meaning; their geometric mask predicates belong to the linked collision
and stage-surface documents.

### Complete collision/service override inventory

Of 95 final factory classes, 79 keep root service and 16 use 15 distinct
overrides. All return one or retain the root result. Their annotations preserve
the independent context/setup paths, root wrappers, record exceptions, owned
service submissions and temporary service-field save/clear/restore operations.

Root delay/activation/state gates apply only when the root body is reached.
Independent overrides and work before a root call have their own gates.
Explicit transient setup followed by root argument zero has a different order
from the ordinary root argument-one path. The complete slot inventory closes
this dispatch boundary; deeper resident service behavior remains open.

### Complete factory-class update contracts

All 95 classes retain the common contact-response callback. Its execution
still requires common state-2 dispatch or another caller; custom update bodies
need not run the dispatcher.

Exactly 68 classes keep root update. The other 27 use 25 distinct targets:
IronRain and SchSkillSenbon call root; 23 independent targets, used by 25
classes, return zero in state 7 and promote state 6 to 7 while returning one.
These promotion branches ignore the common countdown and omit the full
retirement helper's side effects. Most admit these checks only after delay and
activation gates; SyncHand checks states before active initialization.

Active completion is also a survival decision. The annotation comments retain
all exact branch conditions. Representative game values are:

| Class | Active completion |
| --- | --- |
| Explosion | Active count 17 |
| StickHead | Active count 90 |
| PoisonExplosion, NumbnessSmoke, BlueSmoke, WhiteSmoke | Active count 19 |
| LauncherDelay, MakibishiLauncher | Remaining-emission word becomes exactly zero |
| ScoLauncher and the Clay/DDRFire/shared Tew launchers | Remaining count becomes nonpositive |
| SyncHand | Emission index reaches the signed record count; sets state 6/count 1 and returns zero |
| InsectLauncher | Emits, performs position service, sets state 6 and returns zero |
| Tenten0/2 and Shotgun launchers | Their admitted child-emission work completes |
| NumbnessSmoke | Same-tag fighter absent, even without state 7 |

Some launchers process several emissions within one invocation while their
remaining count is positive. DDRFire can also finish immediately when its
`0x20000001` query returns -1.0. LauncherHak1 compares its incremented
counter to the record's locally adjusted threshold.

IronRain has a separate metadata gate before root: absent metadata, or a
nonzero metadata marker with a mismatched lineage word, rejects only while
delay is positive or state is below 3. States 3..5 with nonpositive delay
continue to root even after the mismatch; states 6 and above go directly to
root. The lookup type and broader metadata meaning remain open.
SchSkillSenbon forwards root survival after its local state write.

## Motion families and local timing

Derived motion, candidate-position and commitment order, record inputs,
contact phases, emitter schedules, Clay/Ink guide producers, character-carrier
command rows and local clocks are owned by
[Projectile motion and local timing](projectile_motion.md).

## Hit and despawn evidence

### State-6 transition helper

`projectile_begin_retirement` enters state 6 with count zero, signals the
handle, detaches notification, clears the optional-service flag and runs two
position-associated services. It neither unlinks nor frees the object.
A direct state store does not perform these effects. The helper is one
retirement route, not a universal meaning for every state-6 write.

### Alternate state-6 countdown

`projectile_begin_retirement_countdown` always latches the retirement
request. Its conditional gate can leave state unchanged; otherwise it enters
state 6 with the configured override, or 10 when the override is -1. It signals
the handle and detaches notification, but leaves the optional-service flag and
omits the two position services.

The root initializes the override to -1. SCVGen, SCVSkillPupBullet and NWVGen
activation copy the low half of `value38` into it. This establishes producers,
not that every transition in those classes consumes the override. Positive
countdown values delay common state-6 promotion, while independent update
overrides ignore them. No time unit is established.

### State `6` to manager destruction

The common state dispatcher has eight states:

| State | Common consequence |
| ---: | --- |
| 0 | No state-specific work |
| 1 | Null-address store; invalid/assert-like path |
| 2 | Contact-response callback |
| 3 | Failed completion predicate detaches/signals and enters 7 |
| 4 | Old count nonpositive enters 6, reloads 7 and clears two state vectors |
| 5 | Adds the state vector to position; count/7 scalar; old count nonpositive enters 7 and detaches/signals |
| 6 | Count/7 scalar; decrement; old count nonpositive signals and enters 7 |
| 7 | Dispatcher retirement result, converted to survival zero |

Out-of-range states take the ordinary dispatcher return, not the retirement
result. States 3 and 6 return one from their handlers but zero from the
dispatcher; only state 7 makes the root survival callback return zero.

For the zero-count helper route, the next common state-6 dispatch decrements
to -1 and promotes to 7 while survival remains one. The following callback
observes state 7 and returns zero, allowing manager unlink and deleting
destruction. This ordering counts callback invocations, not frames.

### Direct out-of-bounds removal

Root update also culls through position limits: a resident comparison derived
from axis 0 and constant 2500, axis 1 outside -3000..1500, or axis 2 outside
-500..3500. The first comparison's transform is unidentified. A failed check
signals the handle and enters 7 while still returning one; a later update
performs removal. Continuing updates advance the accumulator and active count
without establishing real-time units.

The two Tonton character carriers give the staged collision-to-destruction
example. Both use the common survival and service callbacks and class-specific
destructors. Their impact callbacks consult the common predicate and segment
queries. Buddy Tonton enters state 6 for predicate low byte 1 or non-sentinel
results on its termination queries. Item Tonton's first query can continue;
its later `0x40000001` result, or a prior local byte condition, can enter
state 6. That condition's game-design meaning remains open.

Their helper-routed path performs position cleanup, promotes to 7, later
returns removal, unlinks, releases derived/common resources, then frees the
allocation. The trap's response-scalar virtual callback is distinct from its
separate retirement helper; the latter also reaches the common helper.

## Limits and pooling

No simultaneous-projectile cap, object-reuse free list or object pool was found
in the traced factory, spawn, manager and destructor chain. General allocation
and deletion back this path; successful spawn increments the linked-list
count. Limits in other callers or systems remain open.

The separate lineage table has two side groups of four
`ProjectileLineageSlot` records. Duplicate comparison uses the signed key
and word, ignoring the consumed flag. Insertion takes the first empty key -1
or replaces the greatest unsigned age when full; it resets the slot and writes
the tuple. Age/consume increments occupied ages and credits the matching
unconsumed tuple once before marking it consumed.

Parent inheritance and `projectile_set_lineage` use this table. Its side is
the numeric inverse of the tag, the original spawn side. Duplicate detection
suppresses another lineage-table insertion, not construction or manager-list
insertion; four slots therefore do not imply a four-projectile cap.

TEN000's projectile emitter has a caller-local substitution: it counts config
`0x44` on the skill side, including objects in states 6/7 until unlink.
If the manager exists and that count is at least three, any incoming config
is replaced with `0x35`. This changes FixedFire to BakutiBall for the
counted request; it never refuses allocation and is not a global cap.
The condition applies regardless of the original requested config.

## Class family

The retail RTTI family contains 99 `ccProj*`/`ccProjectile*`
descriptors, including the root. Vtable class handles establish exact class
identity. The factory reaches 95 distinct final vtables; descriptor-family size
and factory-class count are different bounds.

Representative ancestry is root → Char, Homing, Parabola, Chase, SpecifyParam,
Bound, Launcher and Straight; Homing → SNWCmbULauncher; Parabola → Numbness;
Chase → NrwCombo; SpecifyParam → LunLinear; Bound → BakutiBall. Descriptor
and handle labels retain the exact relationships. Developer class names alone
do not establish subclass gameplay semantics.
