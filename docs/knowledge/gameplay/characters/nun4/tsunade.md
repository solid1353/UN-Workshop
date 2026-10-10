# Tsunade: NUN4 donor

## Research coverage

Established for NUN4 Tsunade 25 (`tnd`) against NA2 Tsunade 84 (`tnw`), with
NA2's retained TND resources 51/52 kept distinct: authored move and phase
differences, callbacks, construction and both donor jutsu classes; ordinary-jutsu
titles and typed assets; the retained-actor comparison; matched ordinary
Ultimate Jutsu camera/filter/hit payloads; the Katsuyu stage, controller, slug and
acid objects, contacts, CPU decisions and cleanup; power and regeneration
effects; compact samples and exact streamed voices.
Open: Katsuyu's acquisition-field producer and the next charge-list halfword;
later binding of one untyped hit record; shared framebuffer and blur lifetime;
contact masks and effect admission; wave stage-height correspondence; remaining
input/phase semantics, ID services and voice producers.

Names come from `@annotations/NUN4` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [NUN3 and NUN4 characters](../nun3_nun4_characters.md).

## Records, moves and assets

**Identity:** NUN4 (`SLUS-21862`) Tsunade is ID **25**, code `tnd`.
Retail NA2 (`SLPS-25837`) Tsunade is ID **84**, code `tnw`; ID 85 is
Shizune. This comparison uses the NUN4 English CVM view and NA2 Japanese
retail files. All addresses in this section are live.

### Definition, construction and authored arrays

| Root | NUN4 Tsunade, ID 25 | NA2 Tsunade, ID 84 |
| --- | --- | --- |
| Definition pair | `tsunade_definition`, `0x005745A8` | `0x005A2BA0` |
| Factory / constructor | `tsunade_create`, `0x00262F50`; `tsunade_construct`, `0x00262FA0` | `0x002EE150` / `tsunade_construct`, `0x002EE1A0` |
| Allocation / final vtable | `0x5D30` / `tsunade_vtable`, `0x005EB700` | `0x5950` / `0x005DA340` |
| Character record | `tsunade_character_record`, `0x0049FF90` | `0x0056F7E0` |
| Class descriptor | `tsunade_character_descriptor`, `0x004A0070` | `0x0056F8C0` |
| Actions | `tsunade_actions`, `0x0049EC60`: 49 at stride `0x64` | `0x0056E7B0`: 49 at stride `0x54` |
| Phase rows | `tsunade_animation_rows`, `0x0049B3A0`: 191 at stride `0x4C` | `0x0056ADD0`: 188 at stride `0x4C` |
| Animation names | `tsunade_animation_names`, `0x0049B120`: 160 pointers | `0x0056AB50`: 160 pointers |
| Seven callback slots | `tsunade_callbacks`, `0x0049B100` | `0x0056A3D0` |

Record parameter bytes `+0x58..+0xDB` agree. This is stored-parameter
agreement, not fighter behavior equivalence. NUN4 construction replaces the
descriptor's working pointers with fighter `+0xED0` names, `+0x1150` actions
and `+0x2474` phase rows, then initializes mode zero. Hold/release cooldown,
threshold and initial cap are 16/12/90 in both constructors.
`tsunade_destroy` (`NUN4 0x002630B0`) uses common cleanup/base destruction
and optional deleting free; these class bodies add no separate heap child.
Channel 6 uses two embedded transient records instead.

The NUN4 vtable's AI slot `+0x1C` is `tsunade_ai_update`
(`0x00263130`), which calls BATTLE `0x006EA010` when the controller nibble
is nonzero. Slots `+0x20/+0x28` are checked `jr ra; nop` leaves
`fighter_virtual20_noop` (`0x0023B8E0`) and
`tsunade_virtual28_noop` (`0x00263170`). Callback behavior is owned by
[Tsunade callback comparison](#callbacks).

The complete arrays establish these **authored animation routes**. Suffixes
omit `ANM_ptnd` / `ANM_ptnw`; correspondence does not establish equal motion
curves, input admission or callback behavior.

| Donor local action | NA2 local action | Authored route / difference |
| --- | --- | --- |
| `0` | `0` | Donor reserved slot 70 empty, category zero; native `chb00/chb02`, category `0x10000`, selector 168, cost 3. |
| `1` / `3` | `1` / `3` | `cha00` / `cha10`; donor selectors 50/51, costs 3/3; native selectors 168/169, costs 0/3. Stored damage 0.125/0.15 in both pairs. |
| `4..0x18` | Same indices | Same normalized animation-name sequences; phase payloads and response selectors may differ. |
| `0x19` | `0x19` | Donor rows 110..113 `kcn10/kcn11/kcn12/end`; native rows 110..112 omit `kcn11`. |
| `0x1A..0x24` | Same indices | Same normalized sequences; donor row starts one row ahead after the added phase. |
| — | `0x25` | Native extra `crs10/crs12/end`, rows 148..150. |
| `0x25..0x2A` | `0x26..0x2B` | Corresponding `hol10`, `hol12`, `hol00`, `hol02`, `kca00`, `kca10` sequences. |
| `0x2B` | `0x2C` | Donor repeats `pna20` three times then `pna22`; native `pna20/pna21/pna22`. |
| `0x2C` | — | Donor `kca20/kca20/kca22/end`, rows 175..178. |
| `0x2D..0x30` | Same indices | Corresponding `hla00`, `hla02`, `pna00`, `pna10` sequences. |

All donor actions own ID 25, native ID 84. Donor slots 0..3 carry selectors
`1/50/1/51`, native `168/168/1/169`; other authored selectors are 1.
The reserved `0x46..0x4D` binding and first-twelve-row replacement rules above
apply. Donor-only body animations after prefix normalization are `kca20`,
`kca22`, `kcn11`; native-only are `crs10`, `crs12`, `pna21`.
Both body directories have 115 `ANM_` names. Selected matching actions also
change stored knockback: donor/native `0x15` and `0x16` are 0.5/0.8,
`0x17` 0.5/0.7, `0x19` 0.5/1.5, `0x1E` 0.75/1.1, `0x1F` 1/0.8,
and `0x24` 1.5/1.1. Their damage scalars agree; callback scaling remains
separate from these authored values.

### Tsunade ordinary-jutsu localized title bindings

NUN4 `fighter_authored_action_static_initialize` (`0x005DA4A0`) fills
Tsunade ID 25's execution actions 1 and 3. Their five display pointers are
zero in the stored image; the initializer supplies the titles below.
Action `+0x08` receives the English pointer, and `+0x0C..+0x18` all
receive the same French pointer. These are resident ordinary-action titles.

| Exact fighter / selector / action; authored record | Display title / literal | Pointer source and display slot |
| --- | --- | --- |
| NUN4 Tsunade 25 / 50 / 1; `0x0049ECC4` | **Heaven Kick of Pain**, `0x00595650` | `0x00437B30` → `0x0049ECCC` |
| NUN4 Tsunade 25 / 51 / 3; `0x0049ED8C` | **Gambling Shot**, `0x00595668` | `0x00437B34` → `0x0049ED94` |
| NA2 Tsunade 84 / 168 / 1; `0x0056E804` | `痛天脚・天帝`, `0x0056E5A0` | Single stored pointer at `0x0056E80C` |
| NA2 Tsunade 84 / 169 / 3; `0x0056E8AC` | `天守脚`, `0x0056E5D0` | Single stored pointer at `0x0056E8B4` |

The English stores are `tsunade_jutsu0_bind_english_title`
(`0x005DE2CC`) and `tsunade_jutsu1_bind_english_title` (`0x005DE304`).
Their following stores use pointers `0x00438B60/64` to
`tsunade_jutsu0_title_french` (`0x0059B380`), **Coup de Pied Marteau**,
and `tsunade_jutsu1_title_french` (`0x0059B398`), **Tir du Joueur**.
Native Shift-JIS literals retain ruby markup
`<r痛天脚|つうてんきゃく>・<r天帝|てんてい>` and
`<r天守脚|てんしゅきゃく>`; the table removes only that markup.

NUN4 `tsunade_jutsu0_bind_display_record` (`0x005E73DC`) loads
ID 25's definition-record pointer `0x005745AC` → `0x0049FF90`, takes
its `+0x2C` action base `0x0049EC60`, adds `0x64`, and writes selector
50's action pointer at `0x00573FEC`. The following
`tsunade_jutsu1_bind_display_record` (`0x005E73EC`) adds `0x12C`
and writes selector 51's pointer at `0x00573FF8`.
The twelve-byte provider rows at `0x00573FE8/0x00573FF4` independently
name `2tndcha0.ccs/2tndcha1.ccs` in their `+0x08` fields.
`jutsu_selector_display_name` (`0x002D1310`) returns the selected
action's `+0x08 + 4*ui_language_index()` pointer, completing the
selector-to-action-to-title join. The two actions' packed `+0x1C` words
independently contain owner 25 and selectors 50/51.

Native `tsunade_jutsu0_bind_display_record` (`0x005D90D4`) loads
ID 84's definition-record pointer `0x005A2BA4` → `0x0056F7E0`, takes
action base `0x0056E7B0` and adds `0x54`; it writes selector 168's
action pointer at `0x005A2860`.
`tsunade_jutsu1_bind_display_record` (`0x005D90E0`) adds `0xFC`
and writes selector 169's pointer at `0x005A2868`. Each native provider
row is eight bytes; its second word names `2tnwcha0.ccs/2tnwcha1.ccs`.
`jutsu_selector_title` (`0x00307C80`) returns the selected action's
single display pointer at `+0x08`. The packed action `+0x0C` words
contain owner 84 and selectors 168/169.

The initializer stores and both title consumers were checked through MCP
code. MCP exposes neither selector-binding tail as a function, so their
load/add/store joins were checked with MCP memory bytes. This establishes
the static display bindings, without assigning input gestures or proving
equal jutsu behavior. Actor roots and resource 51/52 versus 172/173 are
owned by [Jutsu classes and resource roots](#jutsu-classes-and-resource-roots).

### Fighter files and common providers

NUN4 uses `PL/2TNDBOD1.CCS`, `PL/1TNDBOD1.CCS`, both
`PL/2TNDCHA0/1.CCS`, and `3EYE/3TND3EYE.CCS` / `3TND3PCT.CCS`.
The record names `TEX_2tndbody`, `MDL_2tnd00t0 body`, three nonempty
palettes `CLT_2tndbody/bodyc1/bodyc2`, and anchor
`OBJ_eff_dummy_tndhol0`. NA2 uses corresponding `tnw` roots.
Complete identities are in
[Tsunade comparison inputs](../../../game/files/file_identities.md#tsunade-comparison-inputs).

Complete section walks reach EOF for these six donor files. Directory sizes
are 3,833 / 204 / 190 / 392 / 211 / 8 nonsentinel entries; animation counts
are 115 / 0 / 5 / 16 / 2 / 0. Every marked `2cmnbod1.max` name in the donor
body/jutsu files occurs by exact name in NA2 `CMN/2CMNBOD1.CCS`: 31 body,
31 jutsu-0 and 36 jutsu-1 rows. Neither donor jutsu marks a `1cmn` provider.
This establishes directory availability, not equal payloads or complete
provider lifetimes. The eye file's marked `1tnd` body/head/eye/mouth names
resolve in its own `1TNDBOD1` provider.

### Jutsu classes and resource roots

| Domain | NUN4 Tsunade | NA2 Tsunade |
| --- | --- | --- |
| Selector → resource | 50 → 51; 51 → 52 | 168 → 172; 169 → 173 |
| Resource files | `2tndcha0/1.ccs` | `2tnwcha0/1.ccs` |
| Concrete classes | `ccSkillTND000` / `ccSkillTND001` | `ccSkillTNW000` / `ccSkillTNW001` |
| Resident vtables | `tsunade_jutsu0_vtable`, `0x006012C0`; `tsunade_jutsu1_vtable`, `0x005F5E30` | `0x005E5400` / `0x005E1930`, installed at object `+0x110` |
| Allocator arms / sizes | BATTLE `0x0074D630` / `0xA20`; `0x0074DF20` / `0x1030` | BTL `0x0077560C` / `0x1110`; `0x00775B98` / `0x11E0` |
| Construction | `tsunade_jutsu0_construct`, `0x007955A0`; `tsunade_jutsu1_construct`, `0x007DF9A0` | Common `skill_tyo_base_construct`, `0x00797250`; common primary `0x00785410`, then inline derived initialization |

Own-game reads establish filename, factory and RTTI chains. The native
classes differ from the legacy `ccSkillTND000/001` classes retained elsewhere
in NA2. Native jutsu-0 additionally has a camera, `ANM_tnw_camera`,
`ANM_tnw_effect` and `BIN_skldamoffs_2tnwcha0`; native jutsu-1 has four
animations rather than the donor's sixteen.

`tsunade_jutsu0_initialize` (`BATTLE 0x00795750`) binds
`ANM_ptndznz00` from the adopted resource;
`tsunade_jutsu0_bind_animations` (`0x00796D30`) binds `cha01/cha02`
through the instance's selected resource filename. `tsunade_jutsu0_update`
(`0x00795A60`) controls two embedded contacts and creates a ground wave
through `tsunade_jutsu0_create_wave` (`0x00796340`), using the common
left-foot bone. The transient allocation is `0x9B0`, class
`ccSkillTND000Wave`, `tsunade_wave_vtable` (`0x00601500`).
`tsunade_wave_update` (`0x00794990`) updates two five-contact banks;
`tsunade_wave_initialize` (`0x00795140`) binds `ANM_ptndwav00` at rate
0.8 and scale 1.5/1.5/1. The parent destructor (`0x00795650`) clears
animation references, unregisters contacts and destroys embedded owners
before base destruction; the transient has a separate finish/manager handle.

Own-provider effect roots `CMP_ptndhhn_0/1/2/3` are donor `2TNDCHA0`
IDs 158/152/154/156. Each typed `0x0900` composition has one child,
IDs 159/153/155/157. Wave/auxiliary animations are typed `0x0700` IDs
148/151. Surface-dependent emissions also use shared resident descriptors;
their selected typed chains, palette choices and remaining limits are in
[Tsunade ordinary-jutsu dependency graphs](#tsunade-ordinary-jutsu-dependency-graphs).

`tsunade_jutsu1_initialize` (`BATTLE 0x007DFD80`) resolves **all sixteen**
names from `tsunade_jutsu1_animation_name_storage` (`0x0085F278`):
`cha10..17`, `enm00`, `ase00`, `cha18..23`. All exist exactly in donor
`2TNDCHA1`. Three embedded `0x150` owners bind `cha18`; the subordinate main
player binds `cha23`. `tsunade_jutsu1_set_state` (`0x007E0CE0`) controls
both participant animations/movement, receiver suppression and side locks;
the finishing pattern chooses `cha14/13/12/16/17`.
`tsunade_jutsu1_attach_right_hand` (`0x007E1140`) uses
`OBJ_2cmn00t0 r hand`. Movement tables are `0x0085F240/0x0085F260`,
weighted patterns start at `0x0084E570`, computed templates at `0x0084E378`.
The file also has six typed camera records.

This class allocates a `0xD8` auxiliary renderer, constructed at
`0x007E78D0`, vtable `0x005F5980`, retained at instance `+0x924`.
`tsunade_jutsu1_auxiliary_initialize` (`0x007E7930`) binds its descriptor
at `+0x88` from the shared context plus `0x2A00`.
`tsunade_jutsu1_auxiliary_update` (`0x007E79F0`) advances its enabled
interval, position, scale, RGB and alpha, then rebuilds the packet at `+0x48`.
`tsunade_jutsu1_auxiliary_draw` (`0x007E7C80`) temporarily publishes that
descriptor, submits the packet and restores the preceding descriptor.
`tsunade_jutsu1_auxiliary_destroy` (`0x007D5320`) performs common cleanup
and optional deleting free. The shared descriptor's full resource graph is open.
`tsunade_jutsu1_destroy` (`0x007DFB80`) restores participant state/locks,
deleting-destructs that child and destroys three subordinate owners, two
embedded rendering owners and contact storage before common destruction.
The checked update also invokes `tsunade_jutsu1_emit_three_events`
(`0x007E1D90`): three calls to `item_remove_random_inventory_to_world`
(`0x0032C150`), each with angle 25.0, receiver side, count 1, mode 20
and lifetime 10.
The helper excludes a sole kind-6 item; otherwise it removes a selected
inventory item and emits it. This is a gameplay dependency separate from
animation/camera resources.

### Retained TND ordinary-jutsu executable comparison

Checked donor: NUN4 Tsunade **ID 25, `tnd`**, `SLUS_218.62` /
`BATTLE.BIN`. Checked comparison: NA2's retained **resource-51/52
`ccSkillTND000/001` actors**, `SLPS_258.37` / `BTL.BIN`. These are
separate from playable NA2 Tsunade **ID 84, `tnw`**, whose selected actors
are resources 172/173. Retention of the old factories does not establish
an active playable TND definition or complete asset availability.

NA2 retains selector 50 → resource 51 and selector 51 → resource 52.
Resident `tsunade_legacy_jutsu0_provider` (`0x005A24B0`) and
`tsunade_legacy_jutsu1_provider` (`0x005A24B8`) name
`2tndcha0.ccs` / `2tndcha1.ccs`; their stored action pointers are zero.
The resource-factory words at `0x008CD2BC/0x008CD2C0` select
`tsunade_legacy_jutsu0_factory` (`0x00774528`) and
`tsunade_legacy_jutsu1_factory` (`0x00774E10`). They allocate `0x12F0`
and `0x1900` and call `tsunade_legacy_jutsu0_construct`
(`0x007BED20`) and `tnd_construct` (`0x00800510`). The donor
allocations are `0xA20/0x1030`. Each constructor installs its own concrete
table and initializes the translated embedded owners.

The complete primary tables were compared against each game's common
primary-skill table, donor `0x00604F30` and native `0x005FB4D0`.
The first actor has eight concrete overrides and the second twelve in
each game. The checked role correspondence is:

| Concrete role | NUN4 TND slot | Retained NA2 TND slot |
| --- | --- | --- |
| Animation update / draw / action update, both actors | `+0xF4/+0xF8/+0xFC` | `+0xF8/+0xFC/+0x100` |
| Jutsu-0 contact callback / hit latch | `+0x138/+0x198` | `+0x13C/+0x1A0` |
| Jutsu-0 destruction / setup / retirement request | `+0x21C/+0x220/+0x224` | `+0x228/+0x22C/+0x230` |
| Jutsu-1 movement selection | `+0x64` | `+0x64` |
| Jutsu-1 contact / obstruction / receiver cleanup / advance gate | `+0x138/+0x13C/+0x188/+0x198` | `+0x13C/+0x140/+0x18C/+0x1A0` |
| Jutsu-1 exit / destruction / setup / hand attachment | `+0x210/+0x21C/+0x220/+0x238` | `+0x21C/+0x228/+0x22C/+0x244` |

The native tables are `tsunade_legacy_jutsu0_vtable`
(`0x005F7460`) and `tnd_vtable` (`0x005EBD30`). There is no
single vtable-slot translation. Primary actor private storage translates
by `+0x8D0`: jutsu-0 render player `+0x720 → +0xFF0`, registry handle
`+0x930 → +0x1200`, contacts `+0x940 → +0x1210`, animation references
`+0x9E0 → +0x12B0`; jutsu-1 state/timers `+0x720 → +0xFF0`,
contact `+0x770 → +0x1040`, source player `+0x7F0 → +0x10C0`,
allocated child `+0x924 → +0x11F4`, drop countdown `+0x928 → +0x11F8`,
event FIFO `+0x92C → +0x11FC`, subordinate group `+0x970 → +0x1240`,
three `0x150` children `+0xAD0 → +0x13A0` and pattern/index
`+0x1020/+0x1023 → +0x18F0/+0x18F3`. This is not a whole-object
offset rule: the primary interface moves `+0x100 → +0x110`, source
fighter `+0x2FC → +0x31C`, and adopted-resource container
`+0x1C8 → +0x1F0`.

**Heaven Kick of Pain:** `tsunade_legacy_jutsu0_initialize`
(`0x007BEF90`) and `tsunade_legacy_jutsu0_update` (`0x007BF290`)
retain the donor's three-state control, distance/angle clamps, movement
impulses, contact activation at frame 11 and clearing at frame 15,
ground/air gate, wave creation and registry-checked hit latch.
Both parent contacts have radius 75. The separate wave is `0x9B0` in
NUN4 and `0x1030` in NA2, with native `tsunade_legacy_wave_vtable`
(`0x005F76B0`) still installed at `+0x50`. Wave private storage shifts
by `+0x680`; shared interface/handle fields at `+0x50/+0x6C/+0x70/+0x74`
remain at their original offsets.

`tsunade_legacy_wave_initialize` (`0x007BE8F0`),
`tsunade_legacy_wave_update` (`0x007BE090`) and
`tsunade_legacy_wave_hit_feedback` (`0x007BE7A0`) retain the donor's
`wav00` rate 0.8, scale 1.5/1.5/1, two five-contact banks, frame-1/frame-11
activation window, five animated profiles and resource-33/resource-51
hit dispatch. Parent and wave destruction unregister their contacts and
destroy their rendering owners before common cleanup; deleting free is
conditional on a positive flag. Wave finish clears both registrations and
movement and marks retirement. A retirement request is not immediate freeing.

Contact masks differ. The primary contacts and wave first bank use donor
side-0 `{0x40,0x410900}` and side-1 `{0x800,0x208048}`, with donor
`jutsu_extra_contact_mask_flag` (`0x00745A30`) conditionally adding
`0x100000`. Native uses `{0x80,0x88900}` / `{0x800,0x44090}` without
that addition. Wave second-bank masks are donor `{0x2000,0x400}` /
`{0x4000,0x20}` versus native `{0x1000,0x400}` / `{0x2000,0x40}`.
Matching contact windows do not establish matching admission semantics.

The checked surface-emission branches retain their composition names and
attribute cases. For `0xE0A000`, donor wave creation selects heights
-10/387/50 for its logical stage IDs 5/10/9 and zero otherwise. Native
`tsunade_legacy_jutsu0_create_wave` (`0x007BFAC0`) instead consumes
the floating-point result of `stage_effect_height_bits` (`0x00345B20`),
which additionally selects -50 for native logical ID 23. The service has
both an integer success result and a float result; its caller stores `$f0`
at `0x007C0210`. Logical IDs require each game's own mapping; see
[Stage consumers](../../stages/stages.md#logical-id-equality-cases).

**Gambling Shot:** `tsunade_legacy_jutsu1_initialize` (`0x008009A0`),
`item_tnd001_action_update` (`0x00800FF0`), contact/receiver gates,
hand attachment and subordinate playback retain the donor's states 0..4,
participant suppression, side-lock acquisition/release, sixteen animation
bindings, receiver response sequence and five finishing-animation choices.
Initialization calls `tsunade_legacy_jutsu1_select_pattern`
(`0x00802240`), which writes the three-byte pattern at `+0x18F0` and
its index at `+0x18F3`: weighted indices 0..3 or computed index 4.
`effect01_06_source` (`0x00802540`) reads that index: 1 requests effect 1
for 100, 2 arms drop countdown 3, and 3 requests effect 6 for 300.
Its event tail sets age -2 and limit 15. The index producer and these
consumers are established; calling the event helper alone does not arm drops.
The index-1 particle helper `tsunade_legacy_jutsu1_emit_pattern1_particle`
(`0x008028A0`) retains donor `tsunade_jutsu1_emit_pattern1_particle`
(`0x007E1E20`)'s create/bind/position/activate sequence. Its selected
effect comes from native global `0x006B37F4` versus donor `0x006B64B0`;
their respective common-effect rows 29/28 resolve `EFFECT0X`'s
`EFF_e0xstar00`, with different typed effect/image bytes.

`tnd_update` (`0x00800E70`) advances the event FIFO, queued voice,
source player, allocated blur child and subordinate group. `tnd_submit`
(`0x00800F10`) draws those owners. Countdown and inventory dispatch belong
to the action update. `tnd_record_reassign` (`0x008002D0`) takes the
signed pattern byte as its fourth argument; it binds/seeks the selected
child without resetting its completion latch. The `0xD8` blur child has
the same checked field layout and position/scale/RGB/alpha/angle update
arithmetic, while its shared descriptor source changes from context
`+0x2A00` to `+0x29D0`.

The attached particle follows the selected source anchor and is retired
only after a registry-identity check. `tnd_destruct` (`0x008006D0`)
restores participant state and side locks, unregisters contacts, retires
that particle, deletes the allocated blur child and destroys the three
subordinate children and two embedded players before common destruction.
These ownership paths correspond to the donor; shared service semantics
are not established merely by corresponding calls.

Two concrete jutsu-1 services differ. Donor
`tsunade_jutsu1_emit_three_events` makes three one-item requests; its
inventory service removes the selected entry and emits its original code.
NA2's service normalizes personal codes `0x51..0x73` to `0x0E`, and an
original code `0x6A` can emit `floor(count/3)` objects. The native caller
also gates on a nonnull manager. Exact native consumption/order is owned by
[Battle item inventory](../../projectiles_and_items/battle_item_inventory.md#field-object-drops-and-pickup-aliases).
The donor exit override `tsunade_jutsu1_status_panel_restore`
(`0x007E1600`, slot `+0x210`) restores a status panel; native
`tnd001_camera_exit` (`0x008020F0`, slot `+0x21C`) resets the camera
and sends event 6. They are distinct effects of the exit path.

These loaded data ranges agree byte for byte:

| Data | NUN4 live address | NA2 live address | Compared bytes |
| --- | --- | --- | --- |
| Wave profiles | `0x0084B260` | `0x008AF930` | `0x140` |
| Wave initial radii | `0x0084B3F0` | `0x008AFAD0` | `0x14` |
| Parent contact positions | `0x0084B410` | `0x008AFAF0` | `0x40` |
| Sixteen animation names | `0x0085F278` | `0x008B44A8` | `0x100` |
| Finishing metadata | `0x0084E350` | `0x008B42F0` | `0x28` |
| Five computed three-byte templates | `0x0084E378` | `0x008B4318` | `0x0F` |
| Weighted patterns | `0x0084E570` | `0x008B4610` | `0x10` |
| Three consumed default-movement rows | `0x0085F240` | `0x008CDA00` | `0x18` |
| Three consumed alternate-movement rows | `0x0085F260` | `0x008CDA20` | `0x18` |
| Subordinate placement/rotation | `0x0084E4A0` | `0x008B4440` | `0x40` |
| Intermediate event pool | `0x0084E510` | `0x008B45B0` | `0x24` |
| Finish-response pool | `0x0084E580` | `0x008B4620` | `0x0C` |

Agreement establishes those bounded data ranges and the compared
control/ownership structure, not raw binary equivalence.

Remaining independent questions are the shared contact-mask interpretation
and the writers/admission of the donor extra-mask flag, semantic correspondence
of each game's stage IDs, and identity-dependent admission/meaning of the
shared effect, collision and compact-cue calls reached by these actors.
The mask/extra-flag question is shared with the
[retained Kabuto actor](shizune_kabuto.md#retained-kabuto-first-jutsu-executable-comparison);
the participant compact-selector contract is owned by
[Battle audio](shizune_kabuto.md#jutsu-participant-compact-selectors).
Typed CCS/provider closure is recorded in
[Tsunade ordinary-jutsu dependency graphs](#tsunade-ordinary-jutsu-dependency-graphs);
later local record binding and shared renderer/framebuffer lifetime remain
resource questions. The retained actors are therefore
structurally corresponding implementations with verified service differences,
not completely equivalent executable behavior.

### Katsuyu stage/controller Ultimate Jutsu

The selected category-3 record uses the
[authored-ID-1 transition contract](ultimate_jutsu.md#separate-authored-id-1-route).
`reversal_definition_table` entry at BATTLE `0x00859D00` is
`{3,25,21,0}`: controller ordinal 3, Tsunade character key 25 and stage
resource index 21. The checked `reversal_game_create_for_entry`
(`0x007465B0`) arm allocates `0x470`, installs resident
`reversal_katsuyu_vtable` (`0x005F04C0`, retained class `ccSumKatsuyu`),
and constructs three `0x50` contacts at `+0x2D0` plus one at `+0x3C0`.
The factory and table domains remain distinct from the fighter identity.

`katsuyu_reversal_initialize` (`0x0073A510`) selects
`katsuyu_reversal_descriptor` (`0x00858A80`) and `stage/ktys_kty.ccs`,
binds the initiating fighter's body, creates a `0x120` player at `+0xDC`,
and prepares camera/contact state. `katsuyu_reversal_acquire_stage_container`
(`0x0073A680`) passes entry 3's fourth table word, obtained through
`reversal_definition_auxiliary_value` (`0x00745970`), to resident
`ccs_acquire_container_by_path` (`0x00341730`); ownership and container are
stored at `+0xB0/+0xB4`. This is stage acquisition. The fourth word at
`0x00859D0C` is zero in the checked overlay, and its runtime writer has not
been identified. The descriptor's own first word and resource-21 filename
table separately name `stage/ktys_kty.ccs`; they do not establish a write
to that fourth word.
`katsuyu_reversal_bind_animations` (`0x0073A6D0`) resolves nine
Katsuyu suffixes and nine Tsunade suffixes from `0x00844D50/0x00844D80`,
using `ANM_4kty%s` / `ANM_4tnd%s`, plus `ANM_4ktyrdy1`.
`katsuyu_reversal_set_state` (`0x0073AA80`) selects paired animations,
rates `0x100/0x150/0x180` and the state-3 attack descriptor.
The camera anchor is `OBJ_4kty 00t0 bone06`; the initiating model follows
`OBJ_eff_dummy_tndpos0` through `katsuyu_reversal_update_initiator`
(`0x0073AFD0`).

`katsuyu_reversal_update_attacks` (`0x0073B110`) dispatches these distinct
authored attacks and charge-release behavior:

| State | Checked attack and lifetime |
| --- | --- |
| 1 | `katsuyu_reversal_emit_slugs` (`0x0073C8D0`) emits at animation frame 49: 11 at the terminal pattern value, otherwise a progress-derived count capped at 10. `katsuyu_reversal_spawn_slug` (`0x0073B360`) allocates a `0xB0` node and `0x120` player for `ANM_4ktysml00`, with contact/group storage. Contact selects descriptor `+0x38`; a successful hit starts four-update retirement. |
| 2 | `katsuyu_reversal_emit_acid` (`0x0073C9E0`) emits at frame 49 from `OBJ_4ktydummy`: 28 nodes at progress 60, otherwise the charge-list formula below. `katsuyu_reversal_spawn_acid` (`0x0073BDE0`) owns an `0xA0` node and `0xA0` model chosen from `MDL_4ktysan2a/b/c`; negative flight delay, movement, ground effect and 30-update persistence run through `katsuyu_reversal_update_acid` (`0x0073C220`). Contact selects descriptor `+0x64`. |
| 3 | `katsuyu_reversal_body_attack` (`0x0073CB70`) positions three embedded contacts at the main body and two named bones, enables them at frame 12 and disables them from 33. Frame 30 requests twelve radial transient effects through `katsuyu_reversal_emit_radial_effects` (`0x0073C590`), using shared effect resource `0x66`; successful emission depends on allocation and registration. |

#### Contact, damage and reactions

The three `0x2C` pattern groups retain these authored values. Addresses
are in BATTLE; damage is the normalized synthetic-action input.

| Pattern / state | Named group | Damage | Final / intermediate reaction | Final response multiplier | Repeat/contact cap |
| --- | --- | ---: | --- | ---: | ---: |
| Body / 3 | `katsuyu_reversal_body_hit_pattern`, `0x00858A8C` | `0.03` | `0x11 / 4` | `15.0` | 1 |
| Slug / 1 | `katsuyu_reversal_slug_hit_pattern`, `0x00858AB8` | `0.01` | `3 / 1` | `1.0` | 1 |
| Acid / 2 | `katsuyu_reversal_acid_hit_pattern`, `0x00858AE4` | `0.005` | `0x1B / 1` | `1.0` | 1 |

Both auxiliary halfwords at group `+0x26/+0x28` are `0x7FFF` in all three groups.
`reversal_bind_hit_descriptor` (`0x00748E80`) copies group damage multiplied
by controller `+0x1D4`, response multiplier, reaction, repeat and auxiliary
fields into the synthetic action at `+0x170`, and resets hit admission.
`reversal_game_initialize_hit_factors` (`0x007482A0`) unconditionally sets
`+0x1D4 = 1.0` and incoming factor `+0x1D8 = 0.4`; these overwrite its
earlier mode-4 CPU stores. The selected body group's cap admits at most one
shared contact after each bind, so its delivered body reaction is the final
`0x11`, not the stored intermediate 4.

`katsuyu_reversal_initialize_contacts` (`0x0073A820`) creates three initially
disabled contacts in group `+0x60` and one in `+0x84`; controller `+0x464`
is side mask `0x100` or `8`. The shared body checker requires a nonempty
group, matching controller `+0x14` mask, a valid pattern and an eligible
opponent. `katsuyu_reversal_slug_contact` (`0x0073BB30`) instead checks its
node group against `+0x464`, binds its own pattern and retires the node after
a delivered hit. The acid updater checks its node group against `+0x14`,
binds its own pattern and clears that group after the delivery attempt.
Thus each projectile's admission and retirement are distinct from the
shared body's one-hit counter. Spawn counts are not admitted-hit counts.

The synthetic source/action enters the
[ordinary fighter reaction and HP consumer](ultimate_jutsu.md#separate-authored-id-1-route).
The three floats above do not establish a fixed final HP debit: the consumer
has response admission, repeat division, ordinary factors and HP clamps.
`reversal_game_receive_opponent_contact` (`0x007490A0`) separately subtracts
opponent action damage/repeat, scaled by `0.4` and controller `+0x54`, from
the controller's time meter `+0x50`. Zero action damage uses `0.015` before
scaling. It tracks repeated contacts and cooldown, rejects action flag
`0x02000000`, and returns reaction states 5..8 only from idle/5/6.
`katsuyu_reversal_update_model` (`0x0073AD10`) applies those states to the
paired animations; reaction states have substate zero, so animation completion
returns them to idle through the same state setter. This incoming meter loss
is separate from opponent HP damage.

#### Charge and CPU decisions

The inherited `reversal_game_create_default_list` (`0x00747830`), selected
by concrete vtable `+0x24`, requests a one-element halfword array and sets
count 1/current index 0. Katsuyu initialization changes its only threshold
to **56**. `reversal_game_update_charge` (`0x00749F80`) increments progress,
sets pause 10 at the threshold, advances the index up to count 1, and releases
the hold at progress 60. `katsuyu_reversal_release_charge` (`0x0073B1E0`)
selects state 2 when progress exceeds the last threshold, otherwise state 1,
and installs cooldown 40.

At progress 60 the acid emitter takes an explicit 28-node branch. Otherwise
its signed-integer formula is `25 + (progress - T) / trunc((60 - T) / 4)`,
where `T` is `list[current_index]`. After reaching threshold 56 that index
can be 1, beyond the only initialized element. Both allocation placement
helpers leave payload bytes uncleared. No selected write to this next
halfword has been established, so **25..28 is not a proven bound for
nonterminal acid emission**. This identifies the precise missing value;
it does not establish a crash or the value in a running game.

`reversal_game_bind_fighters` (`0x00747650`) replaces initialization's
temporary CPU row with `katsuyu_reversal_cpu_weight_rows`
(`0x00858B10`) selected by difficulty. Four signed halfwords copy to
`+0xF8/+0xFA/+0xFC/+0xFE`:

| Difficulty row | F8 / FA / FC / FE | Shared timing 100 / 102 / 104 |
| ---: | --- | --- |
| 0 | `45 / 8 / 20 / 15` | `90 / 7 / 32` |
| 1 | `40 / 8 / 20 / 20` | `75 / 6 / 24` |
| 2 | `30 / 8 / 20 / 20` | `60 / 6 / 16` |
| 3 | `24 / 8 / 20 / 25` | `45 / 5 / 8` |

The timing rows are `reversal_cpu_timing_rows` at `0x00858100`.
`reversal_game_generate_cpu_input` (`0x00748B60`) counts down `+0x2C` while
idle. Its random draw uses span `FA + FC + FE`: below `FC/2` selects held
state 4; `FC/2 <= draw < FC` selects body state 3; `FC <= draw < FC + FE`
selects body when `katsuyu_reversal_in_range` (`0x0073ACC0`) reports distance
below 900, otherwise held state 4. At `draw >= FC + FE` it remains idle.
An issued action resets the delay to `F8 + random(104)`. While charging,
a random draw against 400 releases the hold when its result is at most 10;
the 60-progress limit independently releases it. Incoming contacts add
timing `102` to the CPU delay, capped by `100`. Practice branches use the
configured input path rather than this weighted decision. Human sampling
and the shared scheduler remain owned by the linked general contract.

#### Resource ownership and cleanup

The selected radial effect is resource **`0x66` (decimal 102)**, row base
resident `0x00575B30`; `katsuyu_radial_effect_resource` names its type field
at `0x00575B38`. It selects `particle / EFF_e0xsmok11`, type 2, whose owned
child is a `0x60` sprite. The adjacent resource `0x67` names
`ANM_e0x_smok_12` and is not this emission. Acid landing uses
`katsuyu_acid_ground_particle_descriptor` / `katsuyu_acid_ground_particle_force`
(`0x008444D0/0x00844510`) through resident `battle_particle_create`
(`0x0039C1B0`), selecting `effect0x / EFF_x001` with its base palette.
Exact typed stage, smoke, effect and selected HUD chains are in
[Katsuyu dependency graphs](#tsunade-katsuyu-dependency-graphs).

`katsuyu_reversal_release_resources` (`0x0073A3F0`) releases players
`+0xDC/+0xE0` and helpers `+0xE4/+0xE8`, drains the slug list
at `+0x438` until count `+0x460` is zero, drains the acid list at `+0x440`,
and releases `+0xB4` only when `+0xB0` says it owns the container.
`katsuyu_reversal_destroy_slug`
(`0x0073B730`) unlinks/frees its node and player and destroys its contact/group.
`katsuyu_reversal_destroy_acid` (`0x0073C0A0`) retires its retained ground
emitter only if the live effect registry still returns that same pointer;
it then releases its model and contact/group and unlinks/frees the node.
`katsuyu_reversal_destroy` (`0x0074AE40`) also destroys the four embedded
contacts and invokes `reversal_game_release_resources` (`0x00747470`) for
the shared players, renderer, camera, sprites, input list and collision owners.
The shared transition, finish voice and reconstruction/return lifetime remain
owned by the linked NUN4 UJ contract. `katsuyu_reversal_draw`
(`0x0073AC20`) draws both projectile lists and the paired participants before
shared presentation. Selected compact and phase voice bindings remain in
[Battle audio](#voice).

## Callbacks

**Checked identities:** NUN4 Tsunade, ID 25 (`tnd`), and retail NA2
Tsunade, ID 84 (`tnw`). The record/array roots and authored animation-route
comparison are in [Character assets](#records-moves-and-assets).
Every callback below was read in its owning game. The seven-slot tables
contain null/channel-2/channel-3/source-response/null/channel-6/null.

| Callback | NUN4 live address | NA2 live address |
| --- | --- | --- |
| `tsunade_set_mode` | `0x00263180` | `0x002EE380` |
| `tsunade_channel2` | `0x00263350` | `0x002EE600` |
| `tsunade_channel3` | `0x002633B0` | `0x002EE660` |
| `tsunade_hit_response` | `0x002642D0` | `0x002EF7E0` |
| `tsunade_channel6` | `0x002648C0` | `0x002EFC40` |

Channel 2 checks actual fighter ID 25/84 and takes mode from byte `+0x63`
bit `0x20`. NUN4 mode storage is `+0x5D28`, NA2 `+0x5944`.
NUN4 mode zero restores categories for local actions `0x1E/0x1F/0x24`
and disables `0x20/0x21/0x25/0x26`; mode one reverses those sets.
NA2 instead restores `0x1E/0x1F/0x24/0x25` and disables
`0x20/0x21/0x26/0x27` in mode zero. Both caps are 90/60.
Native mode-zero transition additionally cancels current `0x21/0x27`, or
`0x20/0x26` when outcome is 1; NUN4's complete mode body has no equivalent
current-action cancellation. These modes reuse the existing fighter class.

Channel 3 has concrete differences even for corresponding animations:

- Both local `0x1D` routines choose flags `0x400000/0x800000` using the
  hold ratio and stored 0.8/1 thresholds (NUN4 `0x00607198`, NA2
  `0x00603E90`).
- Donor local `0x19` has phase 0/1/2 voice/effect logic absent from the
  native callback's corresponding local-action case.
- Donor local `0x24` primes outcome at primary event 20; native `0x25`
  uses event 7. Their random rotation constants are approximately
  0.7853982 and 1.1561061; their shake windows also differ.
- Native local `0x24` has additional secondary velocity events 1/8/17,
  primary voice/effects 4/11/18, surface events 1/5/12/19/26 and writable
  planar phase changes. That is not donor local `0x24`'s behavior.
- Donor local `0x26`, native `0x27`, use authored primary range 6..23 and
  voice event 7. Local-action renumbering accompanies the matching sequence.
- Native local `0x2C` phase 2 publishes a manager ground code and invokes its
  effect consumer; donor `0x2C` has no such channel-3 branch.
- Both local `0x2E` phase 1 secondary event zero call their own
  `tsunade_release_event` (NUN4 `0x002EA590`, NA2 `0x0031E490`), each a
  checked `jr ra; nop` leaf.

The source-response callbacks also differ. For local `0x18`, donor
response IDs are `0x3D/0x30`, native `0x3F/0x32`; local `0x1A` first-hit
responses are `0x37/0x39`. Local `0x23` first-hit responses are `0x3E/0x40`,
and its grounded multiplier is 0.25/0.84. NUN4's scaling factor is 1 for
actual ID 25 and 1.5 for other source identities using this callback.
Receiver movement writes occur only for response mode 2. Identical animation
names therefore do not establish identical hit response.

Channel 6 uses two embedded transient records in both games. Donor action 6,
phase 1, uses the checked timeline interval 11..12 to seed record 1; native
uses secondary event 12. Both action `0x1A`, phase 1, secondary event zero
seed record 0. Both decay each record's float `+0x74` by 0.95 and pass its
position into contact/effect feedback. This establishes local state ownership
without a separately allocated class child; final visual cadence remains
unmeasured.

## Typed providers

### Tsunade ordinary-jutsu dependency graphs

Checked donor: NUN4 Tsunade **ID 25 (`tnd`)**, `SLUS_218.62` /
`BATTLE.BIN`. Checked native character: retail NA2 Tsunade **ID 84
(`tnw`)**, `SLPS_258.37` / `BTL.BIN`. The file/request and concrete-actor
inventory belongs to [Character assets](#records-moves-and-assets).
This section follows ordinary-jutsu typed records and selected code-created
effects; it does not cover Katsuyu, cinematic streams or full actor equivalence.

#### Local models, images and controllers

Complete section walks reach EOF in donor `PL/2TNDCHA0/1.CCS` and native
`PL/2TNWCHA0/1.CCS`. The donor files contain 5/16 animations, 10/3 models,
6/3 materials, 4/7 textures and 4/7 palettes. Every nonempty donor model
has one ordinary subtype-0 part with a typed material reference. One wave
root model has zero parts. Both donor files' `0x2000` metadata blocks have
zero nullable controller/reference IDs; flags are scalar values rather than
additional record edges. Neither donor file has a generator-action packet
or generator definition. These checks inspect material references and packed
curve endpoints, not complete vertex/geometry decoding.

The selected local chains have no absent typed model, material, texture or
palette target. IDs below belong only to the indicated file:

| Donor file / consumer | Typed chain |
| --- | --- |
| `2TNDCHA0`, `CMP_ptndhhn_0/1/2/3` | Compositions 158/152/154/156 → scene objects 159/153/155/157 → models 168/160/164/166 → material 162 → texture 163 `TEX_ptndhhn` → palette 190. |
| `2TNDCHA0`, `ANM_ptndwav00` 148 | Five scene-key wrappers 134/136/138/140/142 → objects 135/137/139/141/143. Object 135 owns zero-part model 171 and is the other four objects' parent. Models 172/175/180 → material 174 → texture 145 → palette 189; model 177 → material 179 → texture 147 → palette 188. Material tracks 144/146 reach those same two textures. Composition 170 retains all five children. |
| `2TNDCHA0`, `ANM_ptndznz00` 151 | Wrapper 149 → object 150 → model 183 → material 185 → texture 186 → palette 187. Composition 182 retains object 150. |
| `2TNDCHA1`, `cha18..22` | Wrappers 305/309/312/315/318 → object 306 → model 368 → material 370 → texture 371 `TEX_ptndcha1` → palette 382. Each animation also binds its separate camera 307/310/313/316/319. |
| `2TNDCHA1`, `cha23` | Wrapper 321 → object 322 → model 378 → material 380 → texture 381 `TEX_ptndslt0` → palette 390, plus camera 323. |
| `2TNDCHA1`, `ase00` | Wrapper 1 → object 2 → model 373 → material 375 → texture 376 `TEX_ptndcha17` → palette 383. |
| `2TNDCHA1`, code-selected finish images | `TEX_ptndsvn/ker/hbi/nmk` 392/387/385/389 → palettes 391/386/384/388. These four textures are separate from the three model-material chains. |

`tsunade_jutsu1_select_finish_image` (BATTLE `0x007E26C0`) selects
svn/ker/hbi/nmk for patterns 0/1/2/3; pattern 4 omits the image.
`tsunade_jutsu1_configure_finish_image` (`0x007DF410`) initializes the
embedded `+0x970` owner's texture packet at `+0x554`, size 64×64 and
pattern-specific color. Following only model materials would omit this path.

Raw namespace/name-byte matching confirms every marked common-2 record in
donor `2TNDCHA0` (31) and `2TNDCHA1` (36) resolves to a typed `0x0100`
scene object in both donor and native `CMN/2CMNBOD1.CCS`. This includes the
left-foot and right-hand names used by the jutsu code. Finish anchors come
from `tsunade_finish_anchor_indices` (resident `0x00608C30`): patterns
0/1/2/3 select left hand/right hand/left hand/left foot from BATTLE
`0x0084E590`. Names with non-ASCII bytes were compared as stored bytes.
This establishes available scene definitions, not foreign skeleton transforms
or provider retention.

All 21 donor animation command ranges and individual vector, rotation and
scalar curve endpoints agree with the owning NUN4 packed handlers. `CHA0`
contains 102 scene keys, two material keys and three queued `0x0108` events;
`CHA1` contains 298 scene keys, six camera keys and nine queued events.
Queued events contain command `0x8003`: `cha00` value 307 and `cha10`
value 308 select resources 51/52 through
`interaction_create_jutsu_from_command` (BATTLE `0x0074CCF0`), which subtracts
`0x100` for values `0x100..0x19F`. Other authored values 0/1 use the active
primary-command path. They are command values, not directory-record dependencies.
Native `CHA0/1` have 7/4 animations; native `CHA1` also has two typed morphers
and nonzero controller references, absent from these donor files.

#### Code-created surface and finish particles

`tsunade_jutsu0_create_wave` (BATTLE `0x00796340`) uses the valid fighter's
surface key masked with `0xF0F0F0`. Its selected roots are:

| Surface key / path | Provider and typed descendants |
| --- | --- |
| `0x00D000` | `battle_emit_surface_debris` (resident `0x00301B90`) / `battle_surface_debris_bind` (`0x002DE7F0`) select the 14 resource rows 111..124 using bank × 7 + field variant. Their aliases are `PARTICLE` leaf01/leaf02 compositions and base/`c1..c6` palettes. Leaf01 chain: 51 → 52 → 53 → 55 → texture 56 → palette 140 (variants 141..146). Leaf02: 57 → 58 → 59 → 61 → texture 62 → palette 147 (variants 148..153). |
| `0x0060C0`, `0x80D0F0` | Descriptor `tsunade_wave_composition_particle` (`0x00578A18`) uses four explicit own-provider `CMP_ptndhhn_*` choices, whose local chains are above. The descriptor's ordinary cached-resource selection is replaced. |
| `0x202020`, `0xE0E000`, `0xE0A000` | Facing selects `tsunade_wave_splash_particle_positive/negative` (`0x00578590/0x005785C8`). `battle_splash_particle_palette_offset` (`0x002D4EF0`) returns zero, so override index is 81. Choice count is three: 81/82 use `EFF_e0xdrop01` with default/`c1` palettes; 83 uses `EFF_e0xdrop02` with its default palette. Typed chains are effect 34 → texture 35 → palette 123, extra palette 124; effect 40 → texture 41 → palette 130. |
| `0xF0D0D0` | Three `tsunade_wave_debris_particle` (`0x005789E0`) emitters receive an explicit composition from `battle_ground_particle_composition` (BATTLE `0x006C5590`). Its field/background chain ends at `background_ground_particle_composition` (`0x006C54D0`), which returns zero. No named CCS composition is established by that branch. This does not establish its visible result. |

`tsunade_jutsu1_update_attached_particles` (BATTLE `0x007E2230`) writes
catalog indices 32/31/30/33, selected by `tsunade_finish_particle_indices`
(resident `0x00608C34`), into emitter descriptors `0x0084E3C8/0x0084E400`.
Each descriptor selects one cached choice. Those rows alias particle resource
0, `EFF_e0xpar00`, with palettes `c4/c3/c2/c5` respectively:
effect 64 → texture 65 → base palette 154, selected palettes 158/157/156/159
in `CMN/PARTICLE.CCS`. Default descriptor choice 33 is overwritten.
The corresponding anchor and four local finish images are independent dependencies.

The entire decoded `PARTICLE.CCS` agrees between donor and native, as already
established under [Manda code-selected effects](orochimaru.md#manda-stage-and-code-selected-effects).
All leaf/drop/par00 variants named above have typed palette definitions.
The resource cache and adoption/release ordering remain owned by
[Resident CCS runtime](../../../game/files/ccs_runtime.md); identical bytes do not establish every
cross-game emitter or borrowed-pointer lifetime.

#### Shared impact and generator graphs

`tsunade_jutsu1_emit_phase_impact` (BATTLE `0x007E1660`) reads
`0x0084E330` and requests variants 0/1/2.
`tsunade_jutsu1_update_finish_effects` (`0x007E1AA0`) reads `0x0084E350`:
patterns 0..3 request variant 4 and pattern 4 requests variant 0.
`battle_emit_impact_with_ground` (resident `0x002FF230`) calls
`battle_emit_primary_impact` (`0x002FEC80`) and adds the selected ground actor.

| Reachable selection | `CMN/EFFECT0X` root |
| --- | --- |
| Primary transient resources 0/1/2/38 | `ANM_e0x_hit_99/98/97/24` respectively. Resource 37 is another hit24 row, but variant 3 is absent from the checked Tsunade event tables. |
| Secondary resources 3/4/5 for variants 0/1/2 | `ANM_e0x_hit_par00/01/02`. `battle_acquire_secondary_impact` (`0x002FF0A0`) uses their prebound pools. |
| Ground IDs 50/52/53/51/62 | Transient resources 44/46/47/45/56, `ANM_e0x_ga_00/go_00/gan_00/gon_00/doka_00`; mapping is through `battle_acquire_ground_effect` (`0x00302120`). Variants 0/1 select first or second through the context bit; variant 2 selects third or fourth; variant 4 selects fifth. |

The twelve-root union reaches 427 donor directory records, including one
without a typed definition. The native same-name union reaches 428, all typed.
The walk includes wrapper parents/targets, scene models/shadows/controllers,
single-part materials, images/palettes, animation record/key pairs and linked
`0x0D80` packets. It follows every selected `0x0D90` attachment, parameter
and child record. All reached nonempty models have a single supported part;
no unknown record type remains in this union.

NUN4 `hit_par00` has **two** linked packets and four generator definitions;
`hit_par01/02` have one packet and three/two definitions. The generator
resource indices are `-1` and first-child palette/texture variants are zero.
`ccs_materialize_generator_action` (`0x001ADEA0`) therefore registers their
typed children. Their effect children reach `TEX_e0xpar05`, `TEX_e0xpar07`
and `TEX_e0xpar11` and their palettes. Omitting the reverse animation-to-packet
join would lose these descendants. Native same-name secondary roots instead
reach `ANM_e0x_par_03` and different children. Primary impact graphs also
differ: for example donor hit99 reaches hit03/hit06/hit05/sousai01/hit00
images, while native hit99 reaches wave08/wave16/wave11/par07/par12.
Equal root names do not establish matching resource graphs or presentation.

The donor gap is `EFFECT0X` record 665 `OBJ_e0xfla02_c`, in ordinary local
namespace ` e\0x\max\e0xfla02.max`. Wrapper 664 targets it; hit97/hit24
reach that wrapper. The record has no typed definition or metadata carrier
in this file. `ccs_resolve_marked_provider_record` (`0x001169D0`) returns
ordinary local records even when untyped, but
`ccs_resolve_external_record_chain` (`0x00116A50`) returns zero when the
wrapper's target runtime is sentinel 4. `animation_attach` (`0x001BD710`)
then leaves that track's target, type, flags and evaluator zero. Thus the
initial hit97/hit24 attachment does not materialize this scene child. This
is not a marked request for another provider. A later local producer or
rebinding has not been established. The checked Tsunade emission path calls
`battle_acquire_primary_impact` (`0x002FEEB0`): it restarts a prebound
resource-2/38 player when available, or binds the same type-4 resource through
`transient_bind_typed_resource` (`0x002DB9C0`) and `animation_attach` on
fallback. Neither emission branch supplies a replacement scene record.

One additional code-selected path closes through the common-effect table:
`tsunade_jutsu1_emit_pattern1_particle` (BATTLE `0x007E1E20`) creates
descriptor `0x0084E390` and binds one explicit **effect** choice through
`particle_choice_bind_effect` (resident `0x00348BA0`). Its pointer is loaded
from resident `tsunade_pattern1_particle_effect` (`0x006B64B0`).
`effect_resolve_common_resources` (`0x002D9870`) clears the table and fills
slot 28 from row `0x00575440`, which names `effect0x` / `EFF_e0xstar00`.
The donor typed chain is effect 2435 → texture 2436 `TEX_e0xstar00` →
palette 2778 `CLT_e0xstar00`. Native `effect_resolve_common_resources`
(`0x0030D3B0`) uses row 29 at `0x005A3F50` to fill native slot
`0x006B37F4` from the same root name; its typed IDs are 2232 → 2233 →
2588. The effect and image sections differ between games. This explicit
choice replaces the descriptor's default catalog choice.

#### Auxiliary blur environment

The donor `battle_effect_context_construct` (resident `0x002D6010`)
initializes twelve 0x40-byte renderer descriptors at context `+0x2980`.
`tsunade_jutsu1_auxiliary_initialize` (BATTLE `0x007E7930`) borrows the
third descriptor at `+0x2A00` into its 0xD8-byte child's `+0x88` field.
`render_descriptor_construct` (`0x0010A410`) either borrows the supplied
renderer or allocates and owns a 0x2B0-byte renderer when that pointer is
zero. The context sets the descriptor's 512×384 logical viewport and draw
order. `tsunade_jutsu1_auxiliary_update` (`0x007E79F0`) builds the embedded
2D packet at `+0x48`; its enabled draw (`0x007E7C80`) temporarily selects
the borrowed descriptor and submits that packet through
`draw_environment_submit_2d_record` (`0x0010A790`). The submitter uses
the descriptor renderer's device rectangle and shared framebuffer state
`0x00609588` for its texture coordinates and draw registers. This path
does not request a Tsunade CCS image for the blur.
The shared 2D submit geometry and framebuffer sampling contract is documented
in [Framebuffer-effect local 2D object](../../../runtime/rendering/draw_2d_owners.md#framebuffer-effect-local-2d-object).

The retained NA2 TND blur has the same 0xD8-byte local layout and draw
sequence but borrows its native context descriptor at `+0x29D0` through
`skill_blur_initialize` (BTL `0x00807510`); `skill_blur_draw`
(`0x00807850`) submits through native resident `0x0010A520`. The shared
framebuffer's production and renderer lifetime remain broader engine
questions; the local blur's selected descriptor and submit path are closed.

### Tsunade Katsuyu dependency graphs

Checked route: retail NUN4 Tsunade **ID 25 (`tnd`)**, reversal entry **3**,
resource **21**, `ccSumKatsuyu`. Native provider comparisons use retail NA2
Tsunade **ID 84 (`tnw`)** and its common files. This section owns selected
typed resources; controller contact, damage, CPU and cleanup are in
[Katsuyu ownership](#katsuyu-stagecontroller-ultimate-jutsu).
The shared entry/rebuild/return route remains in
[NUN4 Ultimate Jutsu](ultimate_jutsu.md#separate-authored-id-1-route).

#### Stage, participants and projectiles

`STAGE/KTYS_KTY.CCS` completely walks to EOF: 751 named directory records,
21 `0x0700` animations, 15 textures, 15 palettes and one `BIN_bgdata`.
The concrete animation binder's 19 slots collapse to **16 distinct paired
animations**: nine Katsuyu roots including separate `rdy1`, and seven TND
roots. Code-created slugs add the distinct `ANM_4ktysml00`. Their packed
blocks contain frame boundaries and `0x0102` scene keys; no queued command,
nested animation or generator block occurs in those 17 roots. All selected
scene-key targets have typed local wrappers/scene definitions or marked
common-2 scene providers.

| Selected root | Checked typed dependencies |
| --- | --- |
| Main Katsuyu and body contacts | `OBJ_4kty 00t0 trall` scene row 2 and its bone hierarchy; body model 521 `MDL_4kty 00t0 body` has five packed parts, all material 522 `MAT_4kty` → texture 523 `TEX_4ktybody` → palette 564 `CLT_4ktybody`. Four parts are rigid; the fifth has 754 logical vertices and 1,347 weighted influences. Its nine shadow models use subtype 4. |
| Camera/initiator anchors | `OBJ_4kty 00t0 bone06` wrapper 13 → typed scene 14; its model 507 is an intentional zero-part bone model, with shadow 508. `OBJ_eff_dummy_tndpos0` wrapper 25 → typed scene 26, model zero. These anchors are not missing geometry. The initiating fighter model additionally uses its separately selected body provider. |
| Spawned slug | `ANM_4ktysml00` row 215 reaches the small-slug hierarchy and model 560 `MDL_4skty00t0 body`: three packed parts all material 561 `MAT_4skty` → texture 562 `TEX_4sktybody` → palette 567 `CLT_4sktybody`. Two parts are rigid; the third has 118 vertices and 200 weighted influences. |
| Stage animation acid components | Four `MDL_4ktysan0*` models 526/530/532/534 each use material 528 `MAT_e25san5` → texture 529 `TEX_4ktysan0` → palette 565 `CLT_4ktysan0`. |
| Code-created acid | `MDL_4ktysan2a/b/c` models 544/548/550 each have one ordinary part using material 546 `MAT_e25ekic01` → texture 547 `TEX_4ktysan2` → palette 566 `CLT_4ktysan2`. Model `d` also exists, but the checked spawn selector chooses a/b/c. |

The ordinary and packed model part walks reach each selected model's declared
endpoint using the owning NUN4 readers. Model-internal subtype-0 submesh IDs
are cleared by `ccs_parse_model`; they do not require independent typed
providers. This check establishes part/material boundaries, not complete
geometry or matrix behavior. All 34 raw marked namespace/name pairs resolve
to exactly one typed `0x0100` scene object in both games' `2CMNBOD1`.
The complete decoded common-2 files are byte-identical, so those provider
payloads agree. Publication, chosen provider and simultaneous lifetime remain
separate from this stored-data comparison.

The stage's `BIN_bgdata` contains 21 signed-short triples and 21 configuration
strings. Its factory set is `0/2/8/10/11/17/18/31/33/34/35/37/85`.
Named draw roots are `OBJ_bac_000_/020_/030_`, `OBJ_flo_000_/010_`,
`OBJ_obj_000_/010_`, `OBJ_snd_040_/_1`, `ANM_s10befe00`, `ANM_stalig00`
and `LGT_dis_0`; all have typed definitions. Their local model/material/image
chains and packed animation block endpoints were checked. Model-linked hit
rows 705/713 belong to object models 682/706. Player/line factories consume
the existing `DMY_pp1_010/DMY_pp2_010`, `DMY_line_010/_1`,
`DMY_f_cl_1_nor/_1` and both `DMY_linemin/max01/02` boundary pairs;
all ten markers have typed `0x1300` definitions. Factory 8 is
`bg_factory_rotate_sky` (resident `0x003BB160`), `ccBgRotateSky`, selecting
`OBJ_snd_040_`; factory 85 is `bg_factory_camera_trace_object`
(`0x003C5AA0`), `ccBgCameraTraceObject`, selecting `OBJ_snd_040_1`.
Their initializers at `0x003BAE60/0x003C57A0` bind those typed scene roots.
The shared parser/factory meanings are owned by
[NUN4 stage records](../../stages/nun4_stages.md#complete-bin_bgdata-record-ledger).
The authored selector names `BLT_bg/BLT_obj`, rows 740/744, have no typed
definitions. `bg_list_selector_create` (`0x003BF680`) skips their initial
runtime sentinel 4; this does not make them external provider requests.

#### Code-selected effect leaves

`katsuyu_reversal_emit_radial_effects` (BATTLE `0x0073C590`) passes
**`0x66` = decimal 102** to `transient_bind_effect_resource`
(resident `0x002DBD70`). Its 24-byte catalog row starts at `0x00575B30`:
provider `particle`, root `EFF_e0xsmok11`, type 2. The typed chain is
effect 94 → texture 95 `TEX_e0xsmok11` → palette 177 `CLT_e0xsmok11`.
`transient_bind_typed_resource` (`0x002DB9C0`) creates the `0x60` sprite
child. Resource `0x67`, in the next row, is `ANM_e0x_smok_12`; it is not
selected by this Katsuyu emission. The entire decoded `CMN/PARTICLE.CCS`
agrees between NUN4 and NA2, including the selected effect leaf.

`katsuyu_reversal_update_acid` (`0x0073C220`) lands each acid model and
creates an emitter using `katsuyu_acid_ground_particle_descriptor`
(`0x008444D0`, `0x38` bytes) and `katsuyu_acid_ground_particle_force`
(`0x00844510`, `0x20` bytes). `battle_particle_activate`
(resident `0x0039C0F0`) takes descriptor short `+0x0E = 63`; zero choice
count means one. `katsuyu_acid_ground_particle_resource` (`0x00576FF0`)
aliases catalog 15's `effect0x / EFF_x001` with base `CLT_x001`.
The typed donor chain is effect 2651 → texture 2652 `TEX_x001` → palette
2798 `CLT_x001`; NA2's same-name chain is 2459 → 2460 → 2616.
All three selected complete sections agree after removing their own record
IDs and the effect/texture's linked record IDs. The initializer caches this
choice; `battle_particle_bind_cached_resources` (`0x0039C8E0`) binds it as
an effect, and `battle_particle_register_bound_choices` (`0x0039CB00`)
registers it with the emitter. Matching sections do not establish foreign
cache offsets, allocation success or lifetime.

#### Smoke and selected HUD images

`MODENAME/KTYS_SMOK.CCS` completely walks to EOF: 92 named records, one
typed `ANM_ktys_smok0` (48), eight textures/palettes and no marked imports.
The shared entry/return code selects animation 48. Its packed blocks contain
one `0x0503` camera key for typed `CAM_camera01` (46), 24 `0x0102` scene
keys and frame boundaries, with no queued command or generator. The selected
wrappers/scene/model/material/image chains close locally. The extra black
and white composition/model graphs also have local definitions; archive
presence does not establish a separate code selection of them.

`reversal_game_initialize_presentation` (BATTLE `0x00747900`) creates
the selected sprites from `battlegauge / TEX_xicon03`, `gauge / TEX_xcommand`
and `battlegauge / TEX_xgauge`, borrowing the battle stage/render context
and owning its separate renderer. Selected provider bindings are:

| Provider / image | NUN4 texture → palette | NA2 texture → palette | Complete selected payload comparison after record IDs |
| --- | --- | --- | --- |
| `BATTLEGAUGE / xicon03` | 373 → 372 | 433 → 432 | Both agree. |
| `BATTLEGAUGE / xgauge` | 362 → 361 | 421 → 420 | Both differ. |
| `CMN/GAUGE / xcommand` | 227 → 225 | 143 → 141 | Both differ. |

All six donor texture/palette records have typed definitions. Same root names
do not establish matching gauge/command presentation. These selected roots
exclude `TEX_xhanyou`, whose checked callers belong to other controllers.
File identities remain in
[Tsunade comparison inputs](../../../game/files/file_identities.md#tsunade-comparison-inputs).
Shared publication, sprite/render construction and release contracts remain
owned by [Resident CCS runtime](../../../game/files/ccs_runtime.md) and the general UJ route.

## Ultimate Jutsu and effects

**Checked identities:** NUN4 (`SLUS-21862`) Tsunade ID 25, `tnd`,
and retail NA2 (`SLPS-25837`) Tsunade ID 84, `tnw`.
The named NUN4 comparison here extends the otherwise NA2-focused coverage.
The class's same-identity action-bank switching is owned by
[Character callbacks](#callbacks).

NUN4 `awakening_dispatch` (`0x001F4B80`) reads
`tsunade_awakening_flags` (`0x00592309`) = `0x10` and
`tsunade_awakening_presentation_event` (`0x00592372`) = -1.
The flags select its ordinary action-progress predicate.
`tsunade_awakening_association` (`0x005924E8`) stores effect `0x25`, count 1.
`input_sector_widen_state_b` (`0x001F4240`) has an explicit ID-25 branch:
remove effect `0x23`, insert the association effect, and set byte `+0x63`
bit `0x20`, followed by statistics/presentation. The complete existing-state
adoption body `input_sector_widen_state_a` (`0x001F3B90`) has no ID-25 case.
These are own-game reads; NUN4 flags and presentation events occupy separate
tables, unlike NA2's interleaved four-byte trigger rows.

Removing donor `0x23` invokes `tsunade_regeneration_effect_destroy`
(`0x00262D30`), which requests successor `0x24` for the same fighter before
the ordinary entry applies `0x25`. The removal reason does not gate that
request. NA2's corresponding regeneration destructor requests successor
`0x23`, but its ordinary entry branches on ID `0x19`, not Tsunade's native
ID `0x54`; the checked native entry therefore applies her associated `0x57`
without removing `0x22`. The gameplay and presentation effects of these
records belong to [Tsunade power and regeneration](#power-effects).

NA2 `tsunade_awakening_trigger` (`0x005C1CA0`) likewise stores flags
`0x10`, event -1; its association (`0x005C1FD0`) is effect `0x57`, count 1.
This is the established Sannin Mode definition `effect_57_definition`
(`0x005A04A0`). Donor `tsunade_ordinary_effect_definition`
(`0x00571BCC`), ID `0x25`, has the same stored default duration 600, flags
2 and seven leading factors `1.5/1.25/1.25/1/1.5/1/1`.
Their stored factors agree; the different record layouts and later effect
consumers are not thereby interchangeable.

### Ultimate Jutsu selection records

NUN4 `tsunade_ultimate_jutsu_list` (`0x00607D00`), pointed to by the
ID-25 slot (`0x00583B74`), contains count 3 and records **56/57/58**;
the default is 56 (`0x00583C82`).
`jutsu_record_get` (`0x003F3BE0`) uses a `0x10` stride
under the locale pointer at `0x00608128`. English rows are in TEXTENG:

| Record / live address | Skill | Category / contest class / cost | Intro / effect / damage percent |
| --- | --- | --- | --- |
| 56 / `0x0086FE90` | `0x39` | 2 / 3 / 0 | `0x34` / `0x23` / 20 |
| 57 / `0x0086FEA0` | 1 | 3 / 3 / 2 | `0x87` / -1 / 0 |
| 58 / `0x0086FEB0` | `0x3A` | 1 / 3 / 1 | `0x35` / -1 / 35 |

NA2 ID-84 list pointer `0x005AD100` selects `0x006044F8`, count 3,
records **191/192/193**. Its `0x14`-stride rows are:

| Record / live address | Skill | Category / contest class / cost | Intro / effect / damage percent |
| --- | --- | --- | --- |
| 191 / `0x005AFB2C` | `0x9E` | 2 / 3 / 0 | `0xA5` / `0x22` / 25 |
| 192 / `0x005AFB40` | `0x9F` | 3 / 3 / 1 | `0xA6` / -1 / 45 |
| 193 / `0x005AFB54` | `0x9D` | 1 / 3 / 1 | `0xA7` / -1 / 35 |

All three native secondary-intro fields are -1; NUN4's record has no such
field. NUN4's class-3/category-3 record points to skill 1, whose clean SINF
row is zero and whose main/title are overwritten to placeholders by
`sp_skill_relocate_request_table` (`0x0032D440`).
`jutsu_record_classify_playability` (`0x003CC6E0`) returns 4 for this
authored ID, and `jutsu_record_presentation_flags` (`0x003CC920`) sets
bit 4. It selects the [separate stage/controller route](ultimate_jutsu.md#separate-authored-id-1-route).
Tsunade's entry is 3, resource index 21, concrete `ccSumKatsuyu`; it does
not request a third Tsunade film. Its stored zero damage percent does not
establish zero damage from the controller's attacks.

Donor record 56's effect `0x23` is
`tsunade_regeneration_effect_definition` (`0x00571AF4`). Its duration 600,
flags 2, neutral seven leading factors and later stored scalar values
`15/0/0.00083333335/1/-0.025/0` agree with NA2 regeneration
`effect_22_definition` (`0x0059EFEC`) after their layout offset.
The 20 gameplay words copied into each effect node agree byte for byte after
the respective ID word; the same bounded comparison also holds for donor
successor `0x24` / native `0x23` and ordinary power `0x25` / native `0x57`.
NA2 owns the established Mitotic Regeneration Mode identity; this comparison
establishes the donor record/selection and stored values without transferring
an unchecked type declaration. NUN4 `jutsu_record_form_character`
(`0x003CCD00`) maps only effects `0x5A..0x64` to replacement identities;
all three Tsunade UJ records therefore return no replacement identity.
Ordinary marker-driven mode changes also preserve the existing Tsunade object.
This does not establish every later indirect effect writer or visible timing.

## Power effects

**Checked identities:** NUN4 Tsunade 25 (`tnd`) in `SLUS_218.62` and retail
NA2 Tsunade 84 (`tnw`) in `SLPS_258.37`. [Awakening](#ultimate-jutsu-and-effects)
owns the UJ and ordinary-entry selection. NUN4 definition stride is `0x6C`;
NA2's factory-anchor stride is `0x64`. The 20 gameplay words copied after the
ID match byte for byte in each checked pair:

| NUN4 definition | NA2 definition | Stored gameplay and lifetime |
| --- | --- | --- |
| Regeneration `0x23`, `0x00571AF4` | `0x22`, `0x0059EFEC` | Default 600, flags 2; neutral factors; entry chakra `+15`, recurring HP approximately `+1/1200` through boundary 1 and chakra `-1/40` through boundary 0. |
| Successor `0x24`, `0x00571B60` | `0x23`, `0x0059F050` | Default 450, flags 2; attack, action rate, jump and knockback factors `0.75`; other factors neutral; no entry, recurring or final resource deltas. |
| Ordinary power `0x25`, `0x00571BCC` | `0x57`, `0x005A04A0` | Default 600, flags 2; attack `1.5`, defense and rate `1.25`, knockback `1.5`; other factors neutral; no resource deltas. |

Donor `0x23/0x24` register `0xC0`-byte specialized nodes through
`tsunade_regeneration_effect_create` (`0x00262C90`) and
`tsunade_regeneration_successor_create` (`0x00262E00`). Their constructors
run `timed_effect_construct` (`0x002CDE80`) and install distinct vtables;
neither allocates a private model or renderer. The `0x25` factory is null,
so `fighter_insert_timed_effect` (`0x002CE7F0`) creates the generic node.
`tsunade_regeneration_effect_destroy` (`0x00262D30`) requests `0x24` with
default lifetime and local route whenever its owner remains, without checking
the removal reason. Successor destruction has no further request. NA2
`effect_22_destroy` (`0x003037C0`) likewise requests `0x23`; its two classes
and generic `0x57` have the corresponding ownership roles.

All three donor IDs are category 1 with local flags `2`. Active nodes
contribute while lifetime is nonzero, independently of Tsunade's mode marker.
`fighter_projectile_scalar` (`0x002D0170`) and `effect_defense_factor`
(`0x002D0220`) use additive deviations from 1; `damage_calculate`
(`0x0020CF40`) consumes them only on its attack/defense enabled paths.
With only `0x25`, those paths receive attack factor `1.5` and incoming
damage factor `0.75`. `fighter_effect_rate_factor` (`0x002D02D0`) caps its
rate at `1.25` and has separate state gates. `effect_jump_height_factor`
(`0x002D0430`) and `fighter_knockback_scalar` (`0x002D08D0`) read their
respective fields; the checked `fighter_apply_motion_record` path turns
`0x25`'s knockback `1.5` into planar `1.5` and vertical `1.25`.
These are selected consumers, not an assertion that every action or hit uses
those factors.
When regeneration removal leaves `0x24` alongside `0x25`, the additive
folds from those two nodes alone are attack `1.25`, defense `1.25`, rate
`1`, jump `0.75` and knockback `1.25`. This is an inference from the
stored factors and checked reducers; other active nodes and state gates can
change the returned values.

`timed_effect_construct` routes `0x23`'s entry chakra `+15` through
`effect_apply_chakra_contribution` (`0x002CF770`). On eligible update passes,
`fighter_update_timed_effects` (`0x002CEF50`) folds active node HP and chakra
deltas before the separate countdown pass. `effect_hp_contribution`
(`0x002D04B0`) requires HP at or below its positive boundary 1;
`effect_chakra_contribution` (`0x002D05D0`) suppresses a negative delta
only below its boundary 0. The HP/chakra routers also check restoration,
status and both fighters' contribution blockers. Thus the stored 600 does
not establish realized healing, total chakra cost or elapsed time.
Admitted countdown passes decrement positive lifetime; zero-expiry and
forced removal both reach the specialized destructor and successor request.

Successful category-1 insertion creates an independent presentation node
through `effect_aux_visual_create` (`0x0031A920`). NUN4 `0x23` selects
`TEX_mode1name2`, `0x25` selects `TEX_mode1name1`, and `0x24` has selector
`-1`, which skips label binding and starts a 10-countdown visual. `effect_aux_visual_construct`
(`0x0031A090`) borrows `modename/mode1cmn.ccs`, owns two animation players
and looks up the selected texture in the recipient's loaded side resource
alongside `MDL_mn_panel` and `MAT_joutai`. The visual's `0x40` render
composition constructs an owned `0x2B0` renderer because
`render_descriptor_construct` (`0x0010A410`) receives a null renderer.
`effect_aux_visual_draw` (`0x0031A860`) scopes the render environment;
`effect_aux_visual_destroy` (`0x00319FB0`) releases both players and the
composition. Its own animation/countdown governs retirement, separately
from the gameplay node. Native effects `0x22/0x57/0x23` select the same respective
`name2/name1/no-label` routes. The selected donor family is `3TND3PCT.CCS`
and the native family is `3TNW3PCT.CCS`; corresponding image pixels and all
indirect effect writers have not been established.

## Cinematics

**Checked identities:** NUN4 Tsunade ID 25 (`tnd`) and NA2 Tsunade ID 84
(`tnw`). Their selection records and outcome effects belong to
[Awakening](#ultimate-jutsu-and-effects).
Clean SINF reads establish these titles/request pairs:

| Game / skill | Decoded authored title | Resident request | Stream request |
| --- | --- | --- | --- |
| NUN4 `0x39` | `忍法・創造再生` | `str/d25_10e.ccs` | `str/d25_10.ccs` |
| NUN4 `0x3A` | `火影の力` | `str/d25_20e.ccs` | `str/d25_20.ccs` |
| NA2 `0x9E` | `忍法・創造再生` | `str/d25_10e.ccs` | `str/d25_10.ccs` |
| NA2 `0x9F` | `火影の力` | `str/d25_20e.ccs` | `str/d25_20.ccs` |
| NA2 `0x9D` | `地流` | `str/d84_10e.ccs` | `str/d84_10.ccs` |

Titles are decoded using the checked second-byte complement operation, not
English move-name guesses. All five rows have zero extra-path count and one
stream. Native `0x9D` additionally has two appearance entries; the donor
`0x14` request row has no native appearance-count field.
NUN4 skill 1 has a zero clean row and a runtime placeholder main/title, not
a third Tsunade request pair. General skill/reversal behavior is independent
of this bounded asset comparison.

All ten listed CCS files were walked to EOF. Each `D25` stream has one typed
`CAM_camera01`; `D25_10` has 383 top-level `0x0502` camera-update blocks,
`D25_20` has 451, in both games. Each has typed `0x1800` projection data
and `BIN_damoffs_d25_10/20` / `BIN_strfilter_d25_10/20` blobs.
Their same paths do not mean equal files: every compared complete-file hash
differs; identities are in
[Tsunade comparison inputs](../../../game/files/file_identities.md#tsunade-comparison-inputs).
After excluding each block's first target-ID word, all 384 camera-definition/
update payloads in `D25_10`, and all 452 in `D25_20`, agree byte-for-byte
between donor and native. The selected `0x1800` payloads likewise agree
after that target word. Both complete `BIN_strfilter` payloads agree
byte-for-byte; the `BIN_damoffs` payloads differ. This establishes preserved
authored camera/filter data for these two pairs, while character coverage
and damage-offset adaptation remain separate.

Every marked namespace/name key in the donor streams is present in the checked
union of the matching resident `D25_*E` request, NUN4 `PL/1TNDBOD1`,
`PL/1CMNBOD1` and `STRMCMN`: 234 marked rows for `D25_10`, 214 for `D25_20`,
with zero absent keys. Both native `D25` streams also have zero absent keys
in their corresponding `tnw` provider union. This is a concrete provider set
and directory-closure result, not complete typed-reference/lifetime proof.
Donor cinematic references retain `1tnd` namespaces; native files use `1tnw`.

The complete streamed frame walks end at the `0xFF01/-1` marker and consume
every declared payload length exactly. `D25_10` has 113,334 donor and 113,436
native frame records; `D25_20` has 108,331 and 108,442. Neither pair contains
`0x0108` queued commands or nested `0x0700` animations. After pairing records
by frame, tag and target namespace/name (`tnd` to `tnw`), including the
`d25_20_hi.max` to `d25_20_03.max` scene namespace change, the changed
payloads are:

| Stream | Changed frame data after target translation |
| --- | --- |
| `D25_10` | 46,301 paired `0x0101` object snapshots change position, rotation, scale or alpha; NA2 adds 102 snapshots: `OBJ_1tnw00t0 forehead` at frames 0..31 and `OBJ_1tnw00t0 trall` at 32..80 and 175..195. Four paired `trall` alpha values change at frames 31 and 172..174. Sixty `0x1801` projection commands at 172..231 retain their Euler triples but change the final scalar; donor stores 1 throughout, native steps from 0.7407407 to 0.2592593 to 0. |
| `D25_20` | 21,986 paired `0x0101` object snapshots change transform fields, with one `forehead` alpha difference at frame 161. Donor alone has `forehead` snapshots at 162..350; native alone has `eye1`, `eye2` and `mou1` snapshots at 351..450, 100 each. `CSP_celhnd` changes the first consumed scalar in 348 `0x1B01` cel-shading commands at frames 0..350. The 699 `0x1901` morpher commands retain their target/source names, source counts and weights after translating all source IDs. |

These `0x0101` records feed scene-object/effect transforms and alpha through
`ccs_frame_tag_0101` (NUN4 `0x001B92C0`, NA2 `0x001B5900`).
`ccs_frame_tag_1801` (NUN4 `0x001B91B0`, NA2 `0x001B57F0`) uses its last
word as a projection-controller parameter. `ccs_frame_tag_1901`
(NUN4 `0x001B9080`, NA2 `0x001B56E0`) consumes each source ID and weight;
`ccs_frame_tag_1b01` (NUN4 `0x001BAB00`, NA2 `0x001B6FD0`) consumes the
cel-shading scalars. The selected differences therefore include authored
participant and scene state, even though camera-update and filter blobs match.

The resident appearance lists are empty for these films. NUN4
`tsunade_regeneration_palette_descriptor` (`0x005799D8`) and
`tsunade_hokage_power_palette_descriptor` (`0x005799E0`) each store
`{null,0}`; their stream header identifiers `0x2510/0x2520` miss the four
code-selected palette sets in `sp_skill_apply_authored_palettes`
(`0x0032DB20`). NA2 skills `0x9E/0x9F` have zero SINF appearance rows.
All four selected `sp_skill_frame_scripts` pointers are null: NUN4
`0x005795DC/0x005795E0`, NA2 `0x005AB5F0/0x005AB5F4`. Their selected
defender draw-gate pointers are also null: NUN4 `0x00578F94/98`, NA2
`0x005A93A8/AC`. The begin callbacks still bind both participants' bodies
from their own appearance flags; these zero optional lists do not disable
that base binding.

The `forehead`/hand appearances have concrete typed sources. NUN4
`D25_20`'s local `OBJ_1tnd00t0 forehead` wrapper 1157 targets the
`#c\\1tnd\\max\\1tndhead.max` provider; its `D25_20E` request supplies
`OBJ/MDL_1tnd00t0 forehead`, `MAT_1tndhead`, `TEX_1tndhead` and
`CLT_1tndhead`. The same resident request supplies
`OBJ/MDL_1tndh00t0 body`, whose part material `MAT_clut3` selects
`TEX_1tndhand02` with `CLT_1tndhand02` for the alternate hand.
NA2 `D25_20` has corresponding `tnw`/`tnwh` wrappers and typed resident
resources, including `CLT_1tnwhand02c1/c2`. In `D25_10`, NA2 alone adds
a `forehead` wrapper targeting `#c\\1tnw\\max\\1tnwhead.max`; the
corresponding object/model/material/texture/palette chain is in its
`PL/1TNWBOD1` provider. NUN4 `D25_10` has no such wrapper. These are
stored links and named resources, not proof of visible appearance or live
allocation. NA2's separate `BIN_extobj_data_tnw` row in `STRMCMN` names
`OBJ_1tnw00t0 forehead` and `OBJ_1cmn00t0 head`; the donor `STRMCMN`
contains no corresponding `BIN_extobj_data_tnd` row. The native
`sp_skill_select_body_composition` (`0x00354640`) selects that row by
fighter abbreviation when constructing a participant body.

The `_damOffs` tracks also differ independently of scene commands.
`D25_10` has thresholds 1/232 in both games, with 78 donor versus 94
native defender entries. At donor Tsunade ID 25 its two XYZ triples are
`(0,0,0)` and `(0,0,-9)`; at native Tsunade ID 84 they are `(0,0,0)`
and `(0,0,-13)`. `D25_20` has donor thresholds 1/66/86 and native
1/66/86/161, again 78 versus 94 defenders. Donor ID 25 has
`(0,-9,-15)`, `(0,0,-10)`, `(0,0,-19)`; native ID 84 has
`(2,-3,-13)`, `(2,0,-13)`, `(0,0,-19)`, `(0,0,-19)`.
Sixty-three of the first 78 `D25_10` entries and 69 `D25_20` entries
agree at the same numeric index over the donor phases; the remaining
same-index rows and NA2's fourth phase require character-specific mapping.
The generic participant substitutions, optional body, streamed block dispatch
and shared renderer owners above still govern consumption. Exact appearance
of every opponent and successful resource construction are not established
by these static records.

The cinematic hit/cue row comparison is owned by
[Battle audio](#voice).

## Voice

**Checked identities:** NUN4 Tsunade ID 25 (`tnd`) and retail NA2 Tsunade
ID 84 (`tnw`). Compact bank descriptors and physical streamed members are
different resource domains; neither control indices nor bank programs are
PLVOICE member indices.

| Game / bank set | Descriptor live address | SNDDATA header offset / bytes | Sample offset / bytes |
| --- | --- | --- | --- |
| NUN4 / English 0 | `tsunade_compact_bank_english`, `0x0043579C` | `0x00AA9000` / `0x13B0` | `0x00AAA800` / `0x67FD0` |
| NUN4 / Japanese 1 | `tsunade_compact_bank_japanese`, `0x00435B44` | `0x01E48800` / `0x13B0` | `0x01E4A000` / `0x4AE40` |
| NA2 / native | `0x003FDC20` | `0x013DD000` / `0xF60` | `0x013DE000` / `0x3E3A0` |

The NUN4 `tsunade_voice_event_pair` (`0x004366E0`) contains base/base
`0x00591DD0`; NA2's ID-84 pair (`0x00406F78`) contains base/base
`0x005C16C0`. There is no different alternate event list for these characters.
Base events 0/`0x18` emit programs 0/26 under the checked EE control rules.
Using the established [compact decoder](../../session/battle_audio.md#compact-program-to-vag-lookup),
clean bank parsing gives these candidates for key `0x3C`:

| Game | Program | Sset / Smpl / Vagi | English / Japanese sample file offsets |
| --- | ---: | --- | --- |
| NUN4 Tsunade | 0 | 0 / 0 / 13 | `0x00ACDB30` / `0x01E5D820` |
| NUN4 Tsunade | 26 | 26 / 26 / 39 | `0x00B0F280` / `0x01E91530` |
| NUN4 Tsunade | 27 | 27 / 27 / 19 | `0x00AD9740` / `0x01E63D70` |
| NA2 Tsunade | 0 | 0 / 0 / 3 | `0x013E4570` / — |
| NA2 Tsunade | 26 | 23 / 23 / 28 | `0x01418DE0` / — |

Each selected split admits keys 12..119; Sset/sample velocity ranges are
1..127 with one sample and rate 22,050. NUN4's inclusive serialized maxima
are Prog 55, Sset/Smpl 40, Vagi 39; NA2's are 40/28/28/28.
Native program 27 is absent. Donor program 27 exists, but Tsunade's base
event `0x19` is disabled: resource presence does not establish emission.
The English/Japanese donor index relationships agree while sample bytes and
offsets differ. Audible identity, priority and admission are not inferred.

### Physical streamed resources

NUN4 PLVOICE outer member 24 (ID 25) is at file `0x004E3000`, size
`0x4A000`, with 22 declared/populated inner members. The first eleven names
are `PL25_106/107/111/112/265/289/293/298/299/302/312.ahx`; the remaining
eleven stored names are `plv`. This filename observation does not assign
a language or event to those latter members.
NA2 outer member 83 (ID 84) is at `0x011A9800`, size `0x66800`, dense
43/43. Its filename suffixes are
`045,047,049,063,068,069,125,126,151,155,165,166,167,199,209,210,211,235,269,290,293,302,303,308,312,313,318,323,324,338,339,364,365,366,369,370,371,372,373,374,375,376,379`.
These physical PLVOICE members are separate from the selected UJ intros.

### Selected UJ and Katsuyu streamed voices

NUN4 `jutsu_presentation_update` (`0x00377730`) and
`reversal_presentation_update` (`0x00378940`) request the selected intro
through `audio_request_sound_member` (`0x001D9FC0`), bank 9, slot 0,
archive family 0. `audio_request_archive_member` (`0x001DA180`) indexes
`ultimate_jutsu_sound_archive_descriptor` (`0x00435E58`): handle 9,
272 members. The member gains 136 when audio context `+0x10` equals 1.
`afs_startup_load_partitions` (`0x001D8250`) loads that handle from
`SOUND.AFS` outer member 9, under parent handle 255.
This establishes direct member selection for intros 52/135/53 without a
Tsunade PLVOICE lookup.

`reversal_game_request_voice` (`BATTLE 0x00730600`) selects bank 6 for
Katsuyu entry 3, cues 24..27 for its four phases. Its
`reversal_sound_archive_descriptor` (`0x00435E40`) has handle 6, 56
members; setting 1 adds 28. NA2 `jutsu_presentation_update`
(`BTL 0x00769790`, checked call `0x00769F30`) requests bank 7, slot 0.
Native `ultimate_jutsu_sound_archive_descriptor` (`0x003FDD08`) has
handle 7, 189 members; its archive dispatcher adds no language-bank offset.
Complete source hashes belong to [File identities](../../../game/files/file_identities.md#tsunade-comparison-inputs).

| Selected record / phase | SOUND outer | Setting 0 member; complete-file offset; bytes | Setting 1 member; complete-file offset; bytes |
| --- | ---: | --- | --- |
| NUN4 UJ record 56, intro 52 | 9 | 52; `0x15775000`; 9,174 | 188; `0x159DA800`; 9,614 |
| NUN4 UJ record 57, intro 135 | 9 | 135; `0x158FA000`; 12,252 | 271; `0x15B16800`; 11,600 |
| NUN4 UJ record 58, intro 53 | 9 | 53; `0x15777800`; 21,606 | 189; `0x159DD000`; 16,304 |
| NUN4 Katsuyu phase 0, cue 24 | 6 | 24; `0x14AB7800`; 9,088 | 52; `0x14B34800`; 7,337 |
| NUN4 Katsuyu phase 1, cue 25 | 6 | 25; `0x14ABA000`; 23,445 | 53; `0x14B36800`; 24,248 |
| NUN4 Katsuyu phase 2, cue 26 | 6 | 26; `0x14AC0000`; 6,081 | 54; `0x14B3C800`; 7,790 |
| NUN4 Katsuyu phase 3, cue 27 | 6 | 27; `0x14AC1800`; 13,624 | 55; `0x14B3E800`; 11,789 |
| NA2 UJ record 191, intro 165 | 7 | 165; `0x084A5800`; 19,780 | — |
| NA2 UJ record 192, intro 166 | 7 | 166; `0x084AA800`; 13,632 | — |
| NA2 UJ record 193, intro 167 | 7 | 167; `0x084AE000`; 22,218 | — |

The donor setting-0 intro filenames are `strST_052/135/053.ahx`; its
setting-1 names are `str`. Katsuyu's first set is `summon24..27.ahx`,
the second `kuc`. Native files are `strST_165/166/167.ahx`.
These code/file bindings establish exact selected bytes. Spoken-content
equivalence, audible admission and timing remain unestablished.

### Cinematic hit and sound descriptors

The selected skill's resident descriptor, independent of PLVOICE, is retained
by `sp_skill_play_start`. NUN4 descriptors are
`tsunade_cinematic39_hits` / `tsunade_cinematic3a_hits`
(`0x005CD678/0x005CD680`); native are
`tsunade_cinematic9e_hits` / `tsunade_cinematic9f_hits`
(`0x005D4210/0x005D4218`). Corresponding **complete row bytes agree**:

| Pair | Frames | Cue bytes | Damage words |
| --- | --- | --- | --- |
| Donor `0x39` / native `0x9E` | 235 | `0x12` | `0x8000` |
| Donor `0x3A` / native `0x9F` | 53 / 70 / 90 / 142 / 231 | `0x0D` / -1 / -1 / `0x0F` / `0x12` | `0x4000` / 0 / 0 / 0 / `0x4000` |

All chakra words are zero. Native `tsunade_cinematic9d_hits`
(`0x005D4208`) has two rows at 163/337, cues `0x0C/0x12`, damage
0/`0x8000`. These are authored descriptor values; the UJ record damage
percentages differ independently, and shared admission/scaling still applies.
The [cinematic resource comparison](#cinematics)
owns provider and camera/filter data.
