# Guy: NUN3 donor

## Research coverage

Established for NUN3 Guy 20 against NA2 Might Guy 69: complete action-family
correspondence and the meaning of every unequal aligned phase row; definition,
construction, callbacks and hair ownership; input admission and continuation
gates; Dynamic Entry and Primary Lotus actors, shared with Green Beast, with their
geometry, contact, landing and surface effects; twenty Ultimate Jutsu records
selecting eight skills; effect `0x21`; compact, PLVOICE and SOUND dependencies.
Open: unmatched payloads and later remaps, contact-domain translation, enclosing
provider lifetime, cinematic frame contracts, remaining effect consumers and
voice cues, and ID-dependent services.

Names come from `@annotations/NUN3` and `@annotations/NA2`; addresses are live. Shared format comparisons are in [NUN3 and NUN4 characters](../nun3_nun4_characters.md).

## Records, moves and assets

The exact checked pair is **NUN3 Guy, ID 20 (`0x14`), `guy`**, in
`SLUS_217.27` / `BATTLE.BIN`, and **NA2 Might Guy, ID 69 (`0x45`),
`guw`**, in `SLPS_258.37` / `BTL.BIN`. NA2 ID 20 has a Naruto filler
definition and null filename families; it is not the same-name comparison.
All addresses in this section are live; CCS directory IDs are file-local.

### Records and concrete fighter ownership

| Item | NUN3 Guy | NA2 Might Guy |
| --- | --- | --- |
| Definition row | `0x004767D0`: factory `0x001FBB50`, record `0x003E4BC0` | `0x005A2B28`: factory `0x002C1BA0`, record `0x00520470` |
| Constructor / allocation | `guy_construct`, `0x001FBBA0`, `0x5430` bytes | `fighter_id_069_construct`, `0x002C1BF0`, `0x69C0` bytes |
| Concrete vtable | `guy_vtable`, `0x00689340` | `fighter_id_069_vtable`, `0x005DA680` |
| Construction descriptor | `guy_construction_descriptor`, `0x003E4CA0` | `0x00520550` |
| Actions, stride `0x54` | 46 at `0x003E3CA0` | 56 at `0x0051F200` |
| Phase rows, stride `0x4C` | 177 at `0x003E0810` | 232 at `0x0051AAE0` |
| Animation-name slots | 157 at `0x003E0590` | 176 at `0x0051A7E0` |
| Palette / texture / model / anchor names | `0x003E0360 / 0x003E04C8 / 0x003E0508 / 0x003E0548` | `0x00519D40 / 0x00519EA8 / 0x00519EE8 / 0x00519F28` |

The record parameter bytes `+0x58..+0xDB` agree exactly. The authored arrays,
callbacks and concrete classes differ. NUN3's constructor installs working
name/action/row storage at fighter `+0xE00/+0x1074/+0x1F8C`, invokes the
common record loader, clears its `+0x5418..+0x542B` tail, then creates and
selects the hair models. NA2 additionally owns two allocated `0x120` service
objects, other descriptor/counter state and a `0x34` optional render-pass
object at `+0x69B4`; its chain and mode bytes are `+0x69B0/+0x69B1`.
Those raw offsets follow the constructor; misleading decompiler array-field
expressions do not change them.

NUN3's seven callback pointers at `0x003E0570` are
`{0, 0x001FC100, 0x001FC200, 0x001FC640, 0, 0, 0}`:
channel 2, channel 3 and source hit response are active. NA2's table at
`0x00519F50` is `{0x002C3DF0, 0x002C4010, 0x002C4710, 0x002C55B0,
0x002C5AA0, 0, 0x002C3FD0}`. Its channel 1 rewrites action categories
for three modes, and channels 5/7 manage extra owned state. NUN3's virtual
update/draw/destructor roots are `guy_effect_hair_update` (`0x001FC040`),
`guy_auxiliary_draw` (`0x001FC0E0`) and `guy_destroy` (`0x001FBC90`).

### Complete authored move correspondence

The following compares every donor action's ordered non-sentinel animation
suffixes against the native array. A match means names and order only;
duration, rate, motion, contact banks, input admission and callbacks remain
separate data. The complete arrays were read, not just named attacks.

| Donor actions | Native actions | Checked correspondence or difference |
| --- | --- | --- |
| 0 / 1 / 2 / 3 | 0 / 1 / 2 / 3 | Donor 1/3 use `cha00/cha10`; donor 2 uses `chb10/chb12`, native 0 uses `chb00/chb02`. Donor 0 and native 2 instead reference empty animation-name slots. |
| 4 | 4 | Donor starts with `rdy2`, native `rdy1`; both then `spl00,spl00,spl02`. |
| 5..15 | 5..15 | Ordered suffixes agree, including three `SPC` preparations and six aerial sequences. |
| 16 / 17 | 18 / 16 | Ordered suffixes agree for `kca70/kca72` and `pna90/pna92`, respectively. Native 17 additionally uses `kca60/kca62`. |
| 18 | — | Donor `jmp1,pnb00,pnb00,pnb02,lan0` has no native counterpart. Native 18 uses `kca70/kca72`. |
| 19 | 19 | Common jump/dash suffix sequence agrees; starts at donor row 86 versus native 85. |
| 20 / 21 / 22 / 23 / 24 | 21 / 22 / 23 / 24 / 25 | `pnc0/1/2/4/3`; native repeats opening attack phases in 22..25. |
| 25 | 27 | `kcs00,kcs02`; native repeats `kcs00` three times. |
| 26 | 26 | Donor `cmb00,01,02,03,04`; native repeats `cmb00` three times then `cmb02`. |
| 27 / 28 / 29 / 30 | 30 / 31 / 34 / 35 | `kcn2/3/4` and `pnc5`; native repeats each first suffix. |
| 31 | 38 / 39 | Donor `kcn00,kcn02`; native has separate `kcn00/01` and `kcn02/03` actions. |
| 32 | — | Donor `kcn10,kcn12` has no native name family. |
| 33 / 34 | 43 / 44 | `hol00/01`, then `hol02/03`, ordered suffixes agree. |
| 35..45 | 45..55 | Ordered suffixes agree: `kca1/2/3`, `pna2/3/4`, `hla0/1`, `pna0/1`, `kca0`. |

Native-only sequences additionally occupy action 20 and actions 28/29,
32/33, 36/37 and 40..42: the extra `pna50` aerial path, `nnc00..03`,
`pnz50..53`, `pnz00/02`, `pnz10/12`, `pnz20/22`, `pnz30/32`,
`kcn50/52` and `pnz40..43`. Donor-only animation names include
`rdy2`, `chb10/12`, `pnb00/02`, `cmb01/03/04`, `kcn10/12`.
These counts include authored slots, not a claim that all are selectable moves.

The donor's stored English move titles include Rise-to-Sky Uppercut (23),
Hot-Blooded Straight Right (24), Kick of Steel (25), Heart-and-Soul Body
Blow (26), Rise-to-Sky Kick (28), Chop of Steel (30), Hot-Blooded Kick
(32), One-Legged Hit Style (34), Rolling Shoot (37), Burning Beat (40),
Rolling Throw (42), and Greatest Hit (45). Titles alone do not identify
the native animation or input mapping.

### Guy input admission and action chaining

This comparison checks the resident NUN3 selector on Guy 20 and NA2's
selector on Might Guy 69. Action numbers in the tables are decimal;
signatures, categories and masks are hexadecimal. The native common contract
is in [Action commands](../../combat/action_commands.md) and
[Combat action execution](../../combat/combat_action_execution.md).
The following establishes static admission and continuation, independently
of motion, hit results and the duration of each phase.

NUN3 `input_build_logical_mask` (`0x001D8890`) uses configurable bindings
copied by `bindings_reset` (`0x001D8140`) from `0x00389C60`:
Triangle/Circle/X/Square/L1/R1/L2/R2 masks
`0x10/0x20/0x40/0x80/4/8/1/2`. A Circle press produces logical
`0x1000`; `action_select_from_signature` (`0x001C6A70`) maps it to
signature family `0x100000`. Simultaneous Circle and Square is resolved in
Circle's favor by `fighter_copy_input_outputs` (`0x001A8330`). State-byte
`+0x61` mask `0x80` or status-byte `+0x62` mask `0x01` suppresses those copied
outputs. The subsequent `fighter_consume_logical_input` (`0x001D0290`)
skips its pass for status mask `0x80`.
`fighter_update_attached_input_gate` (`0x001B83B0`) bypasses ordinary
input with attached effect 0/1 and status mask `0x10` clear, also clearing
pending; it can change state before the selector runs. Otherwise auxiliary
input and requests for states `0/3` and `0/4` precede
`guard_update_input` (`0x001B9360`) and Triangle's `chakra_staged_gate`
(`0x001B6BA0`). Guard can enter state `0/5`, still in the selector's
accepted set. The binding-2 rewrite/consume route follows, then signature
selection, then Cross's movement requests. Circle alone does not activate
the auxiliary or Triangle branches; chorded input retains this ordering.

| Direction selector | NUN3 logical bit | Constructed signature bit |
| --- | --- | --- |
| 2 / 3, Up / Down | `0x10 / 0x20` | `0x200 / 0x400` |
| 6 / 7, opponent-relative angle / its opposite | `0x40 / 0x80` | `0x1000 / 0x2000` |
| 14 / 15, facing-angle horizontal sign / its opposite | `0x100 / 0x200` | `0x4000 / 0x8000` |
| Down-Down / Up-Up | `0x400 / 0x800` | `0x10000 / 0x20000`, replacing direction context |

`input_direction_in_sector` (`0x001D81D0`, jump table `0x004E6120`)
checks wrapped sectors, not raw Left/Right pad masks. Up/Down use total
tolerance pi/2; the other listed sectors use about 5pi/6. Zero magnitude
does not satisfy them. `input_history_advance` (`0x001D94D0`) derives
the opponent angle from both positions, including height, and the facing
angle from fighter yaw and camera orientation. `command_tables_evaluate`
(`0x001D9170`) reads the two exact two-press tables at
`0x00389C70/0x00389C90`, each with window 16. Signature context is
ground `2` or air `4`, plus height class `0x40` when vertical centers
are less than 150 apart, otherwise `0x20/0x80`. Donor ground context
reads contact-byte `+0x63` bit `0x20`; a nonzero reaction classifier
forces air context. Native uses its own contact bit `0x80` and reaction class.

NUN3 `input_params_template` (`0x001CF6A0`) leaves hold/release disabled
(progress cap zero), with multi-press threshold 2 and distance 12. Guy's
constructor does not replace those defaults. Native Guy retains disabled
hold/release but changes multi-press distance to 16, threshold still 2.
Both checked signature builders omit synthesized logical `0x8000`;
that bit does not become an additional signature condition for the rows below.

For ordinary mode 0, both selectors scan upward, skip zero categories and
categories `2`, `0xF000` and `0xF00000`, then require exact equality after
candidate-specific normalization. Candidate bit `1` replaces context's low
nibble; `0x10` replaces its height nibble; `0x100` replaces all direction
context; `0x3000` clears facing bits `0xC000`; `0xC000` clears
opponent-relative bits `0x3000`. Candidate family `0x200000` rewrites
constructed Circle family `0x100000` to `0x200000`. Thus a neutral/wildcard
label below describes the stored signature and these rewrites, rather than
an extra character-specific input handler.

| Ground input branch | NUN3 Guy | NA2 Might Guy |
| --- | --- | --- |
| Neutral Circle chain | `20 → 21 → 22` | `21 → 22 → 23` |
| Up after that chain | `22 → 23`, `0x100212` | `23 → 24`, same signature |
| Facing selector 14 after that chain | `22 → 24`, `0x104012` | `23 → 25`, same signature |
| Down after that chain | `22 → 25`, `0x100412` | `23 → 26`, same signature |
| Facing selector 15 after that chain | `22 → 26`, `0x108012` | `23 → 27`, same signature |
| Additional normalized Circle branch | absent | `23 → 28` in mode 0, `23 → 29` in modes 1/2; `0x200112` |
| Up root, then neutral Circle | `27 → 28` | `32 → 33` in mode 0, `30 → 31` in modes 1/2 |
| Down root, then neutral Circle | `29 → 30` | `34 → 35` in modes 0/1, `36 → 37` in mode 2 |
| Opponent selector 6 root | `31 → 32` with neutral Circle | `38 → 39` automatically on accepted outcome, or `38 → 40` with Circle and wildcard direction/context, modes 0/1 |
| Additional opponent-selector root | absent | `41 → 42` automatically on accepted outcome, mode 2 |
| Opposite selector 7 capture root | `33 → 34` automatically on accepted outcome | `43 → 44` automatically on accepted outcome |

All donor actions 20..45 have cost zero. Their continuation byte at
record `+0x18` is `-1` for roots, or the preceding action number for
dependent rows. Ground/air Circle roots use `0x100012/0x100014`;
Up/Down add `0x200/0x400`, opponent selectors add `0x1000/0x2000`.
Donor automatic records 34/42 instead have signatures
`0x08000011/0x08000014`. The air graphs retain the same numbered topology
after rebasing: donor Up `35 → 36 → 37`, Down `38 → 39 → 40`,
neutral `43 → 44 → 45`, and outcome capture `41 → 42` correspond to
native `45 → 46 → 47`, `48 → 49 → 50`, `53 → 54 → 55`,
and `51 → 52`. Matching topology does not equate payload behavior.

Native `might_guy_effect_mode_update` sets mode 1 for effect `0x47`,
else mode 2 for `0x48`, else zero (`0x47` takes precedence).
`might_guy_channel1` (`0x002C3DF0`) requires actual ID 69 and replaces
whole categories, rather than adding a flag to the original category:

| Native actions (decimal) | Mode 0 | Mode 1 | Mode 2 |
| --- | --- | --- | --- |
| 28 / 29 | `4 / 0` | `0 / 4` | `0 / 4` |
| 30, 31 / 32, 33 | `0 / 1` | `1 / 0` | `1 / 0` |
| 34, 35, 38, 39, 40 | `1` | `1` | `0` |
| 36, 37 | `0` | `0` | `1` |
| 41 / 42 | `0 / 0` | `0 / 0` | `0x100 / 0x200` |

NUN3 Guy's selected callback table has no channel-1 category rewriter.
His effect-`0x21` hair update is a separate consumer.

These character modes are distinct from the common selector modes.
NUN3 `action_select_from_signature` bypasses input selection for an active
queued chain, otherwise requires selector mode other than `-1`, logical
mask intersection `0x3F000` and `action_entry_allowed`.
`action_selector_mode` (`0x001C6810`) forces mode 0 with effect 0/1.
With no exchange roles, mode 1 requires a major-8 record whose flags
intersect `0x380`, no category `0xF00000`, and payload bit `0x10`;
otherwise it is mode 0. Exchange roles `0x100/0x400/0x1000`, in that
priority, select `2/3/2` only with pending empty and valid opposite
`action_window_progress` (`0x001C57E0`), otherwise `-1`.
The successful `0x100` route clears the action lock.

The opposite-selector capture route also has a threshold rewrite before
ordinary scanning. `action_find_by_masks` (`0x001AEC60`) finds the first
category-`0x100`, flags-`0x41/0x42`, subtype-0 record. Donor 33/41 and
native 43/51 all store threshold 400. NUN3
`action_capture_threshold_passed` (`0x001C5B00`) requires matching
section/target, nonzero record threshold and distance below it, reading
fighter `+0x30C` on ground or `+0x310` in air. If it fails and the
signature's `0xFFF03000` portion matches the capture row, the builder
removes `0x2000`; logical Left/Right sector bits `1/2` then substitute
`0x1000`. The branch table therefore does not grant capture irrespective
of distance or section.

`action_entry_allowed` rejects a nonzero action lock in both games.
The accepted major/substate sets agree for major 0 (`0,3,4,5,7`),
major 1 (`0x0E..0x14`), majors 2/3/4, and major 8 (current category
outside `0xC0000`). NUN3 (`0x001C6590`) accepts major 5 only in selector
mode 2; native additionally accepts substates `0x5B/0x5C`. NUN3 major 6
uses substate `0x5B` from cursor 8 or `0x5C` from cursor 3, whereas
native uses `0x5F/0x60` at those bounds. Native also calls
`paired_binding1_intercept` before entry; the donor selector has no such call.
That native gate (`0x002455B0`) returns 1 for nonzero paired context.
With zero context it returns 0 for a negative marker, or the opponent's
ID 59/64 with contact mask `0x20`. If own substate is `0x5B/0x5C`,
the opposite substate must also be in that pair; otherwise own action
19/class 3/stage 3 and opposite class 3/stage 3 are required.
Interception also requires both contact-mask `0x0C` values below
`0x08`, logical Circle `0x1000`, and
`paired_facing_clearance_allowed` (`0x002459E0`, multiplier 1.4).
The latter checks both participants through their facing/section probes;
a short facing-side distance rejects unless the stored side matches facing
and the stored distance is not the missing-value sentinel. Successful
interception sets paired context `-1` on both fighters
and returns 1, preventing ordinary selection for that input.

NUN3 `action_select_record` (`0x001C5B70`) admits roots with
continuation `-1/-2` outside an existing ordinary action. During major 8,
unless the category-2 reselect exception applies, it requires payload
bit `0x10`, a matching continuation and signature, then writes pending
`+0x98E` and returns `-1`. `-2` substitutes the current action, with
additional companion-category rules. Donor `action_reselect_allowed`
(`0x001C80D0`) requires current category bit 2, motion class 3/stage 2,
and at least five motion updates. NUN3 additionally calls
`action_disabled_by_effect` (`0x00234780`): effect `0x0F/0x15` with
status-byte bit `0x40` disables records carrying flag `0x2000`.
Guy's ordinary actions 20..45 carry none of that flag. Their validator
(`0x001CEB00`) returns `-1` before the companion chakra/manager checks;
ordinary admission therefore does not acquire those companion-only gates.

`action_stage_outcome_continuation` (`0x001C7630`) separately requires
the opponent's published attack record to resolve to the current record
and own outcome `1`, then selects the first matching continuation with
signature bit `0x08000000` through `action_find_outcome_continuation`
(`0x001A8D10`). Validator result 3 or current-record flag `0x02000000`
dispatches immediately; otherwise it stages the candidate. For an ordinary
pending row, execution then requires zero exchange roles and payload bit
`0x20`, after the earlier category/exchange exits. `action_dispatch_index`
(`0x001C7050`) still checks nonzero category, effect disable and candidate
validation before entering major 8. Selection and execution are distinct gates.

The stored payload masks make that distinction concrete. Donor ground
20..25 and 27..34 have successive `0x10,0x20` phases; donor 26 has
four `0x10` phases then `0x20`. Native 22/23 and 30..37 repeat
their `0x10` phase before `0x20`; native 24..28 have three `0x10`
phases before `0x20`, while native 29's last phase has neither bit.
Donor air roots 35/38/43 and native 45/48/53 store
`0x10,0x30,0x20`, allowing selection and consumption in the middle phase.
Native channel 3 additionally sets/clears action 48 phase-1 bit `0x20`
according to outcome `1`, after its delegated loop handling; donor action
38 retains the authored mask. Only these two bits are compared here.

Fixed slots remain independent of those ordinary graphs. NUN3
`action_scan_jutsu_slots` (`0x001C6020`) selects the highest matching
slot 4..9 with staged chakra, special admission and an affordable cost
(effect `0x0F/0x15` can waive that comparison). Selector modes 1..3 use
`action_stage_chain_slot` (`0x001C6260`) on slots 10..18 only when
pending is empty, with category/flag masks, cost and effect gates.
`action_build_chain_masks` (`0x001CC0E0`) gives mode 1 category
`0x1000`, mapping exact current flag groups `0x80/0x100/0x200` to
secondary `0x400/0x800/0x1000`. Modes 2/3 preserve the exact current
`0x1C00` flag group and choose category `0x2000/0x4000` from the
current category group and a per-candidate random draw; with no current
record they use category `0x2000` and the opposite exchange kind.
Modes 2/3 erase direction context from both signatures when the candidate
uses it. Mode 1's category-`0x200`/flag-`0x80` source has an additional
rewrite from progress 0.75: `action_record_has_f00_without_7c`
(`0x001C9D40`) chooses facing mask `0x4000` when category intersects
`0xF00` and flags exclude `0x7C`, otherwise `0x8000`. When that mask
matches the original signature's `0xC000` portion, the builder adds
opponent-relative `0x1000`. These mask gates select the first
qualifying fixed slot, rather than the ordinary continuation rows.
Signature family `0x02000000` checks only slot 19;
`action_slot19_allowed` (`0x001C7FC0`) requires cooldown zero, no
exchange, contact mask `0x06` clear or section different from target,
and during major 8 a payload word exactly `0x20`. Native's contact mask
is `0x0C`.
Native action 20's authored category `0x04000000` does not extend that
fixed-slot selector. These are separate routes from the Circle branch table.

### Stored differences in aligned phase rows

For actions 1/3, 5..15, 16→18, 17→16, 19→19, 20→21,
33→43, 34→44 and 35..45→45..55, both arrays have the same ordered
suffixes and phase counts. Comparing every non-sentinel row in those pairs,
excluding the animation-slot index and the two object-name pointers,
gives exactly the differences below. Phase numbering starts at zero within
the action. Values run donor → native; offsets are within the `0x4C` row.
Offsets `+0x02..+0x0A`, `+0x20/+0x22` and `+0x38/+0x3A`
are 16-bit words; `+0x1C/+0x34` are 32-bit words. Other displayed
values are IEEE-754 floats, rounded to seven significant digits.
The checked consumers and meanings of these unequal fields follow below.
Matching stored values alone do not establish matching behavior.

| Donor / native action | Phase | Differing offsets and values |
| --- | --- | --- |
| 10 / 10 | 0 | `+0x06` 0x0200 → 0x0400 |
| 13 / 13 | 0 | `+0x08` 0x0202 → 0x0102; `+0x0A` 0x7FFF → 0x0000; `+0x0C` 0 → 60; `+0x10` 0 → 20; `+0x14` 0.5 → 0.075 |
| 14 / 14 | 0 | `+0x08` 0x0202 → 0x0102; `+0x0A` 0x7FFF → 0x0000; `+0x10` 0 → -50; `+0x14` 0.5 → 0.35; `+0x18` 1 → 1.25 |
| 15 / 15 | 0 | `+0x08` 0x0202 → 0x0102; `+0x0A` 0x7FFF → 0x0000; `+0x10` 0 → 55; `+0x14` 0.5 → 0.35 |
| 16 / 18 | 0 | `+0x08` 0x0202 → 0x0102; `+0x0A` 0x7FFF → 0x0000; `+0x10` 0 → 55; `+0x14` 0.5 → 0.35 |
| 16 / 18 | 1 | `+0x06` 0x0100 → 0x00C0; `+0x08` 0x0202 → 0x0102; `+0x0A` 0x7FFF → 0xFFFE; `+0x10` 0 → 42.5 |
| 17 / 16 | 0 | `+0x08` 0x0202 → 0x0102; `+0x0A` 0x7FFF → 0x0000; `+0x0C` 0 → 60; `+0x10` 0 → 20; `+0x14` 0.5 → 0.075 |
| 17 / 16 | 1 | `+0x20` 0xFFFF → 0xFFFE |
| 20 / 21 | 0 | `+0x0A` 0xFFFE → 0xFFFD; `+0x20` 0xFFFF → 0xFFFD; `+0x38` 0xFFFE → 0xFFFD |
| 33 / 43 | 0 | `+0x24` 40 → 60 |
| 37 / 47 | 1 | `+0x1C` 0x0000002A → 0x00000028; `+0x34` 0x0000002A → 0x00000028 |
| 38 / 48 | 0 | `+0x0C` 30 → 20 |
| 41 / 51 | 0 | `+0x18` 1.5 → 1.2; `+0x24` 50 → 70 |
| 41 / 51 | 1 | `+0x18` 1.5 → 1.2 |
| 42 / 52 | 0 | `+0x10` 30 → 100; `+0x14` 0.125 → 0.1; `+0x18` 0.5 → 1.5; `+0x1C` 0x00000012 → 0x00000010; `+0x20` 0xFFFF → 0x8001; `+0x22` 0xFFFF → 0x8001; `+0x24` 100 → 0; `+0x34` 0x00000012 → 0x00000010 |
| 42 / 52 | 1 | `+0x02` 0x000C → 0xFFEF; `+0x08` 0x0102 → 0x0402; `+0x0C` 5 → 0; `+0x10` 10 → -40; `+0x14` 0 → 0.1; `+0x18` 0 → 2.5; `+0x1C` 0x00000028 → 0x00000010; `+0x34` 0x00000028 → 0x00000010 |
| 42 / 52 | 2 | `+0x02` 0xFFF0 → 0xFFEF; `+0x04` 0x000C → 0xFFFF; `+0x08` 0x0202 → 0x0402; `+0x14` 0.125 → 0.1; `+0x18` 1 → 2.5; `+0x1C` 0x00000028 → 0x0000001A; `+0x20` 0x8001 → 0x0000; `+0x22` 0x8001 → 0x7FFF; `+0x24` 0 → 120; `+0x30` 0 → 100; `+0x34` 0x00000028 → 0x0000001A |
| 43 / 53 | 0 | `+0x24` 50 → 70 |
| 43 / 53 | 1 | `+0x24` 50 → 70 |

All other compared values in those aligned rows agree. The other action
families have changed phase counts or names; this comparison does not assign
one-to-one scalar equivalence to them.

### Guy phase consumers and reaction-number translation

The 30 aligned action pairs above contain 19 unequal non-sentinel rows.
`Nun3CharacterAnimationRow` covers all `0x4C` bytes; its signed `duration`
halfword is a phase **condition**, not always a duration.
Both games use the same widths, offsets and numeric meanings below.
Animation slots and object-name pointers belong to each game's resources.

| Row fields | Checked NUN3 consumer | Checked NA2 consumer | Meaning |
| --- | --- | --- | --- |
| `+0x02` condition | `phase_event_completion`, BATTLE `0x00835BC0` | BTL `0x0071F160` | Positive: secondary cursor threshold; `-16`: animation end; `-17`: grounded; zero: hold. Other special conditions and relative jumps follow the [shared phase contract](../../combat/combat_action_execution.md#shared-phase-progression). |
| `+0x04/+0x06` start/rate | `phase_select_animation`, BATTLE `0x00835DD0`; `fighter_advance_animation`, resident `0x001D3470`; `fighter_advance_timelines`, `0x001D37D0` | BTL `0x0071F640`; resident `0x0024D1C0/0x0024D5E0` | Negative start adds animation frame count. Unsigned rate `/256` scales the phase clock and playback step; start zero with rate below 256 seeks frame 1 when binding. |
| `+0x08..+0x18` motion | `response_motion_update`, resident `0x001ABAD0`; `fighter_motion_event_due`, `0x001AB490` | Resident `0x0021ACB0/0x0021A6D0` | Flags/event, planar/vertical speeds, decay gain and next-gravity multiplier. `0x7FFF` disables the impulse; mask `0x02` selects the secondary clock. Upper flags `0x0100` replace both speeds, `0x0200` add both, `0x0400` add planar and replace vertical. |
| `+0x1C/+0x34` flags | `fighter_register_primary_attack_banks`, resident `0x001B0F50` | `fighter_update_timelines_slot`, `0x0024DE40` | First-bank mask `0x02` admits **both** ordinary registrations for major 8, outside exchange mask `0xFF00`. The second bank's flags do not independently admit this pass. |
| `+0x20/+0x22`, `+0x38/+0x3A` bounds | `fighter_register_attack_window`, resident `0x001B0850` | Resident `0x0021FC70` | Signed inclusive window bounds; either `-0x7FFF` disables that bank. Negative values resolve against positive phase condition, otherwise animation frame count minus one, less the resolved start, clamped at zero. |
| `+0x24/+0x3C`, `+0x28/+0x40`, `+0x2C/+0x30/+0x44/+0x48` | Same registration consumers | Same registration consumers | Radius, named attachment and local X/Z offsets. Empty attachment uses the fighter transform; missing requested attachment disables the bank. These fields publish geometry, not an HP amount. |

`action_update_jutsu_record` (`0x001C7C50` / `0x0023BAC0`)
passes the current phase's `+8` block to the motion consumer on the ordinary
path. Guy's capture/release categories instead reach `capture_update_motion`
(`0x001C9E20` / `0x0023E500`); the checked actions still use that same
block because only category `0x100` combined with action flag 2 delegates
to approach motion. Character channels 2/3 precede this work in
`fighter_dispatch_action_update` (`0x001D0560` / `0x00249640`).
The authored rows therefore remain subject to callback writes and exits.

The unequal rows have these bounded consequences, donor → native:

| Action pair / phase | Consequence of the stored difference |
| --- | --- |
| 10/10, 0 | Rate 512 → 1024, scaling both playback and phase-clock advancement. |
| 13/13 and 17/16, 0 | Disabled impulse → phase event 0 replacing speeds with 60/20; decay gain 0.5 → 0.075. |
| 14/14, 0 | Disabled impulse → phase event 0 replacing vertical speed with -50; decay 0.5 → 0.35, gravity request 1 → 1.25. |
| 15/15 and 16/18, 0 | Disabled impulse → phase event 0 replacing vertical speed with 55; decay 0.5 → 0.35. |
| 16/18, 1 | Rate 256 → 192; disabled impulse → relative event -2 replacing vertical speed with 42.5. At update delta 1, the slower rate also selects the registration consumer's scene-frame branch. |
| 17/16, 1 | First window starts at resolved -1 → -2. |
| 20/21, 0 | Motion event -2 → -3; first window start -1 → -3 and second start -2 → -3. |
| 33/43, 0 | Radius 40 → 60; attachment also changes from left foot to right foot. |
| 37/47, 1 | First-bank `0x2A` → `0x28` removes ordinary-registration mask `0x02`. Donor's first bank is disabled by its bounds, but its second bank can publish radius 100 at the left foot at window 0..0; native's common pass deactivates both. |
| 38/48, 0 | Authored planar impulse 30 → 20. |
| 41/51, 0..1 | Gravity request 1.5 → 1.2. Phase 0 also changes radius 50 → 70 and left-foot attachment → right-finger attachment. |
| 42/52, 0 | Event-0 vertical speed 30 → 100, decay 0.125 → 0.1, gravity 0.5 → 1.5. Donor's terminal radius-100 window on `OBJ_eff_dummy_guyhol0` becomes disabled bounds, zero radius and no ordinary-registration bit. |
| 42/52, 1 | Secondary threshold 12 → grounded condition -17; replace speeds 5/10 → add planar 0 and replace vertical -40; decay 0 → 0.1, gravity 0 → 2.5. Neither row admits ordinary registrations. |
| 42/52, 2 | Animation-end condition -16/start 12 → grounded condition -17/start -1; decay 0.125 → 0.1, gravity 1 → 2.5. Donor has disabled ordinary banks; native admits a first-bank 0..32767 pelvis window, radius 120, local Z offset 100. |
| 43/53, 0..1 | First-bank radius 50 → 70. |

The excluded attachment pointers were also resolved in **every** aligned row.
The only additional name difference is action 34/44 phase 0: left foot →
right foot. All other attachment strings agree, including empty names.
The differing strings above were checked at donor `0x004E6B10/70`,
`0x004F5950` and native `0x00408F70/90`, `0x00409090`;
the strings are object keys, not file-local numeric IDs.

Both registration consumers branch on the effective unsigned scene step
at player `+0x94`. Ordinary playback stores `trunc(row rate × fighter delta)`
as a halfword there, then forces zero if the prior animation-end latch is set.
Steps above 256 enable the crossing/end adjustment; nonzero steps below 256
replace the interval result with an inclusive scene-frame comparison.
Both consumers also share wrapped/ordinary interval selection.

Negative motion events resolve as `max(0, base - raw phase start + event)`,
where base is the positive condition, otherwise animation frame count minus
one. Negative contact bounds use the same base but first add frame count
minus one to a negative phase start. Phase animation binding instead adds
the full frame count to a negative start. These distinct resolutions agree
between the two games. Animation length, callbacks, pause and grounding
still determine whether the resulting thresholds are reached.

`fighter_set_scaled_velocity` (`0x001A9490`) consumes donor decay as a
proportional gain, scaled by fighter delta unless exactly 1, capped at 1;
an error below 0.1 snaps to zero. `apply_gravity` (`0x001A9680`) consumes
the row multiplier via `fighter_apply_movement` (`0x001D0D20`): ordinary
gravity subtracts multiplier × record gravity × 3 × delta, zero skips it,
and a non-1 multiplier removes the ordinary terminal-speed floor.
The ordinary physics-mode-0 path then resets the request to 1; the ungrounded
mode-3 branch uses fixed gravity and skips that reset. These checked rules agree with
the [native movement contract](../../stages/movement_and_physics.md#gravity-and-input-smoothing).

The reaction domain is separate from phase flags. `response_select_substate`
(`0x001C07E0` / `0x00231C60`) reads the action's byte `+0x2C`, then
allows the source response callback to replace it. The following exact
translations cover Guy's checked ordinary/capture selectors and callback
results; they are not a claim that the complete response machines agree.

| Donor selector | NA2 selector preserving the checked family |
| --- | --- |
| `0x00..0x05` | Same number |
| `0x09`, `0x0A`, `0x0C`, `0x0F` | `0x0B`, `0x0C`, `0x0E`, `0x11` |
| `0x10..0x13` | `0x12..0x15` |
| `0x16`, `0x17` | `0x19`, `0x1A` |

For example, donor 37's selector `0x12` translates to native `0x14`;
donor 34's `0x10` to native `0x12`. Donor 41's selector `0x17`
translates to `0x1A`, while the actual native action 51 uses `0x1B`:
the same animation suffixes do not imply the same held receiver state.
Other genuine mismatches are 16→18 (donor `0x10`, native `0x14`),
17→16 (donor `0x13`, native `0x12`) and 20→21 (3 → 2).

`guy_hit_response`'s nondefault destinations translate as
`0x27/0x29/0x2A` unchanged and `0x2E/0x30/0x31/0x33` →
`0x30/0x32/0x33/0x35`; -1 remains the no-override result.
For those seven pairs, and authored destinations `0x2F/0x36/0x37/0x3A..0x3E`
→ `0x31/0x38/0x39/0x3C..0x40` and `0x46..0x4A` → `0x4A..0x4E`,
the complete descriptor phase lists through their sentinel and each
24-byte motion/timing row are byte-identical. Descriptor roots are
NUN3 BATTLE `action_descriptor_table` (`0x0091ACC0`) and NA2 BTL
`0x0089AEB0`; motion roots are resident `response_motion_table`
(`0x00389550` / `0x00407670`).
This supports those table translations without asserting identical body
animation bytes or all later conditional remaps.

Mode-2 donor callback scales `+0x8F0/+0x8F8/+0x8FC` translate to
native `+0x9A0/+0x9A8/+0x9AC`: knockback, planar and vertical scales.
The motion consumer applies and resets them; **attack scale here is not
HP damage**. Motion speeds/gravity use donor `+0x8E4/+0x8E8/+0x904`
versus native `+0x994/+0x998/+0x9B4`. Phase rate/start use
donor `+0xAB0/+0xAB4` versus native `+0xB90/+0xB94`;
the primary/secondary clocks are `+0x1A4/+0x1C8` versus `+0x1B8/+0x1DC`.

HP damage instead reaches `response_apply_table_timing`
(`0x001C2660` / `0x002346B0`) at primary event 0, under its independent
status/category/rejection gates. Donor `action_damage_per_repeat`
(`0x001A8C50`) reads action damage `+0x24` divided by nonzero signed
repeat count `+0x2E`. All 30 aligned pairs store equal raw damage;
repeat counts agree except action 1 (1 → 8), whose ordinary-jutsu actors
already differ. Phase radius, attachment and motion multiplier do not enter
this amount. The checked `damage_calculate` formulas
(`0x001B5E30` / `0x00224E30`) agree in offense, durability curve,
reservation factor, effect-factor arithmetic, handicap and clamp ordering;
the underlying effect-producing functions are not established equivalent.
The native accepted-hit rules remain owned by
[Damage](../../combat/damage.md#native-damage-calculation).

This comparison establishes field meanings, threshold/geometry differences
and the listed numeric translations. It does not establish collision outcomes,
body-animation payload equivalence, complete later donor response/contact
remaps, or all action/attack flag translations. Input admission is covered
separately above. Callback/CCS audio producers are outside this phase-row
comparison; no audio cue is encoded in the checked `0x4C` phase row.

### Ordinary jutsu and provider domains

| Item | NUN3 Guy | NA2 Might Guy |
| --- | --- | --- |
| Action 1 / selector | Dynamic Entry / 40 | `マキシマム・エントリー` / 138 |
| Action 3 / selector | Primary Lotus / 41 | `夜鳳凰` (Night Phoenix, literal title) / 139 |
| Overlay resources | 29 / 30, `2guycha0/1` | 140 / 141, `2guwcha0/1` |

Donor resident provider rows `0x004763B8` and BATTLE selector rows
`0x0093E8A0` agree on the Guy resources. NA2 BTL retains selectors 40/41
as resources 29/30 at `0x008CB200`, but its resident rows at `0x005A2460`
name **`2nrtcha0/1`**. The retained Guy filenames in the overlay do not
establish a usable native Guy provider pair. Those Guy CHA files are absent
from the NA2 disc. Native selectors 138/139 map at `0x008CB388`.

NUN3 `jutsu_create_by_resource` (`BATTLE 0x0086C740`) dispatches through
`0x0093FB90`. Resource 29's branch `0x0086CE08` allocates `0x790` and
calls `guy_dynamic_entry_construct` (`0x00899250`), installing resident
vtable `0x0069B5F0`. Begin/contact callback/destruction are `0x00899CF0 /
0x00899CA0 / 0x00899350`; phase dispatch is `0x00899460`. The animation binder `0x00899510` loads three
`pguycha0*` animations and three fighter-indexed animations; resource 67
uses its separate `pnrzcha0*` branch. Resource 30's branch `0x0086CE30`
allocates `0x880`, constructs at `0x0089B860` and installs `0x0069B3A0`.
Its begin/update/draw/destruction are `0x0089BEF0 / 0x0089BB90 /
0x0089BC40 / 0x0089B950`; state setter `0x0089C010` owns four states,
both participant movement/collision paths and auxiliary-object handling.
It requests `ANM_pguyskl10` and `OBJ_eff_dummy_guyall`, rather than merely
playing a character action. Both selected per-resource variant-data pointers
at `0x00923684/88` are null. Fixed interaction records remain distinct.
NA2 resource-29/30 factory entries `0x008CD264/68` both select
`guy_legacy_jutsu_empty_factory_case` (`0x00774308`): a zero store and
unconditional branch to return epilogue `0x00776004`, with no allocation
or constructor. There are no retained resource-29/30 actors in that factory.
Playable Might Guy instead uses the distinct native actors compared below.

### Shared Guy jutsu actor dependencies

This comparison checks **NUN3 Guy ID 20, resources 29/30**, and
**NUN3 Green Beast ID 32, resources 67/68**, against the corresponding
empty NA2 factory slots and **NA2 Might Guy ID 69, resources 140/141**.
The two donor identities share executable classes and fixed definitions;
their resource-selected animation names and participant-dependent services
remain distinct. Live addresses below belong to NUN3 unless marked NA2.

`battle_apply_animation_resource_command` (BATTLE `0x0086C6C0`)
accepts command `0x8003`, subtracts `0x100` from encoded values
`0x100..0x173`, and calls `jutsu_create_and_bind_participants`
(`0x0086DBF0`). That wrapper creates the resource actor, registers it,
then binds the supplied participants. The four checked startup animation
tracks issue this command at frame 1:

| Provider / animation | Target ID | Encoded value / resource |
| --- | ---: | --- |
| `2GUYCHA0 / ANM_pguycha00` | 51 | `0x11D` / 29 |
| `2GUYCHA1 / ANM_pguycha10` | 2 | `0x11E` / 30 |
| `2NRZCHA0 / ANM_pnrzcha00` | 51 | `0x143` / 67 |
| `2NRZCHA1 / ANM_pnrzcha10` | 28 | `0x144` / 68 |

The fixed-definition table at `0x00923274` contains pointer/count pairs:
29 → `guy_dynamic_entry_interaction_definition` (`0x00920ECC`),
30 → `guy_primary_lotus_interaction_definition` (`0x00920F10`),
67 → `green_beast_ultimate_entry_interaction_definition` (`0x00921EBC`),
68 → `green_beast_primary_lotus_interaction_definition` (`0x00921F00`).
Each count is one. The complete `0x44` bytes agree for **29 = 67**
and **30 = 68**. These definitions are separate from the null
per-resource variant-data pointers described above.

`interaction_record_from_definition` (`0x0086C0F0`) copies a definition
into a `0x68` working record. `interaction_prepare_resource_contact`
(`0x0087E530`, Primary Lotus's virtual `+0x1A4`) retains that record,
definition and row number at actor `+0x110/+0x114/+0x118`;
`interaction_publish_resource_contact` (`0x0087F270`) provides the
parallel virtual `+0x1A0` path. Both select participant/resource cache
rows through `interaction_record_for_resource` (`0x00870210`). Their
working attack scalar is definition float `+0x28` (1 in both selected
definitions) multiplied by source action float `+0x24`.
The definition's response halfword `+0x14` is `0x10` for Entry and
4 for Lotus; repeat halfword `+0x2C` is 1 for both. The Entry definition
also stores `0x84000001` at `+0x20` and 7 at `+0x24`, versus zero
for Lotus. These are executable contact inputs, not CCS resource IDs;
complete cross-game flag/response translation is not established here.

**Dynamic Entry / Ultimate Entry.** The `0x790` constructor owns three
embedded `0x50` contact shapes at `+0x5A0/+0x5F0/+0x640`, a fourth
at `+0x690`, and a receiver at `+0x6E0`. They are not CCS models.
`guy_dynamic_entry_setup_contact_shapes` (`0x0089A730`) links the first
three to receiver `+0x50C` with radii 45/30/30 and depth bias 30.
`jutsu_source_contact_masks` (`0x0086C5A0`) supplies side-0 masks
`0x40/0x410900`, or other-side `0x800/0x208048`, with optional
receive bit `0x100000` from its common gate. The fourth shape has
radius 200, zero depth bias and masks `0x10/0x10100` or
`0x200/0x8008`. The receiver registration nodes borrow these embedded
shapes. `guy_dynamic_entry_position_contact_shapes` (`0x0089A220`,
virtual `+0x240`) places the first three at source `l foot`, `l calf`
and `pelvis` scene transforms.

`guy_dynamic_entry_bind_animations` (`0x00899510`) fills six borrowed
slots: `ANM_pguycha00/01/02`, or resource-67
`ANM_pnrzcha00/01/02`, followed by source fighter slots
`0x45/0x37/0x3B`. `guy_dynamic_entry_select_animation` (`0x008999E0`)
binds a selected slot to the source scene. The latter three dependencies
therefore come from the selected fighter's body/action bank.

| Concrete virtual route | Checked behavior |
| --- | --- |
| `+0xE8/+0xEC/+0x104`, `0x00899430/40/50` | No-op reserved methods. |
| `+0xF0`, `guy_dynamic_entry_phase_update`, `0x00899460` | State 0 startup `0x0089ACC0`, 1 leap `0x0089ADB0`, 2 finish `0x0089B810`, 3 recoil `0x0089B4D0`; then position contact shapes. The common finish pass `interaction_finish_phase_dispatch` (`0x0088A300`) reaches this slot. |
| `+0x1A4`, `guy_dynamic_entry_update`, `0x00899CA0` | Contact flag `+0x490 & 2` selects alternate `0x0089A6B0` or hit `0x0089A380`; this is distinct from phase dispatch. |
| `+0x118/+0x11C`, contact lock/unlock `0x0089A8E0/0x0089A950` | Acquire/release retained service `+0xD4` and clear/set session mask `0x80`. |
| `+0x210/+0x214`, capture begin/end `0x0089A9B0/0x0089AB30` | Save/restore participant positions and source velocity, arm/clear `+0x771`, and pair stage/participant/presentation service changes. |

The hit callback begins the common capture-service route, selects opponent
animation slot 4 or 9 according to facing, and emits source dialogue
cue 0 when the checked effect predicate succeeds, otherwise random 0..2.
It unregisters contact and selects source action `0xE`; the alternate path
selects source action `0x13` when valid. During capture, the leap phase
aligns the opponent using source foot/opponent pelvis transforms, requests
shake and one of two common initial-hit effects described below, and
releases capture after its 30-tick counter gate. Recoil requests slot 3/contact mask `0x80` at phase
15, later slot 4, and reaches finish after grounding. The called
`guy_dynamic_entry_effect_reserved` (`0x0089A720`) is a no-op.

`interaction_begin_capture_services` (`0x00888A20`, virtual `+0x1FC`)
routes its flags to the concrete lock/capture methods; Entry resources 29/67
are not in its `{8,26,30}` capture exclusions. The release wrapper
`interaction_end_capture_services` (`0x00888C90`, virtual `+0x200`)
reaches concrete `+0x214`. The Entry destructor also invokes that
capture-end slot directly, unregisters both receivers and destroys the
embedded receiver/shapes before common cleanup and optional owner free.

**Primary Lotus.** The `0x880` actor binds exactly seven ordinary
animation names through `guy_primary_lotus_bind_animations`
(`0x0089CB20`): `ANM_pguycha10/11/12/13/14/21/22`, or the
`ANM_pnrz` equivalents for resource 68. Begin borrows
`ANM_pguyskl10` from its own loaded CHA and creates the embedded
animation player at `+0x5E0`. During state 2 its update, draw and
finish slots service that player; draw requires `OBJ_eff_dummy_guyall`.
`guy_primary_lotus_follow_anchor` (`0x0089D080`) also requires the
source scene key `OBJ_eff_dummy_guycha1`, or resource-68
`OBJ_eff_dummy_nrzcha1`, and uses its matrix to position the opponent.
This is a consumed cross-CHA anchor, not an unused directory name.

| State updater | Checked descendants |
| --- | --- |
| 0, `guy_primary_lotus_startup_phase`, `0x0089D870` | Common action/animation completion enters state 1; state setup selects target height and stage-dependent participant/presentation gates. |
| 1, `guy_primary_lotus_lift_phase`, `0x0089D990` | Source `cha11`, opponent `cha21`, anchor-follow mode 2; animation gate enters state 2. State setter emits dialogue cue 1. |
| 2, `guy_primary_lotus_fall_phase`, `0x0089DB80` | Source `cha12`, opponent `cha22`, embedded player, anchor-follow mode 0, ceiling/ground landing gate, paired rotation and periodic SFX `0x16/0x32`. Resource 68 additionally emits source dialogue cue 0 on entry. |
| 3, `guy_primary_lotus_recovery_phase`, `0x0089DD00` | Surface-specific impact, participant correction, source `cha13` at phase 15 or armed surface service, then `cha14` after grounding; periodic SFX `0x16/0x38`, final animation gate and shutdown. |

The ceiling path is concrete: `guy_primary_lotus_select_target_height`
(`0x0089CC20`) probes 1250 above the opponent, with a stage-`0x1E`
exception and hit offset -200. `guy_primary_lotus_probe_ceiling`
(`0x0089CD20`) probes 500 above the participant; masked surface `0xD0D0`
arms `+0x5D1`. `guy_primary_lotus_resolve_ceiling_landing`
(`0x0089CE40`) uses the falling collision result and clears that mode
through `guy_primary_lotus_clear_ceiling_mode` (`0x0089CDE0`).
The stage-height gate (`0x0089D420`) has a separate stage-`0x12`,
source-side-1, height-above-1150 exception.

On impact, surfaces `0x202020/0xE0E000` reach
`guy_primary_lotus_arm_surface_services` (`0x0089E320`), which saves
impact position `+0x5B0`, retains opponent identity with the source-side
mask, and arms `+0x87C`; other surfaces reach
`guy_primary_lotus_regular_impact` (`0x0089E280`). The latter sets
opponent counters `+0xA8A/+0xA8C` to 120/90 and refreshes response
animation/state. State 3 separately calls
`interaction_apply_source_action_damage` (`0x0087D9E0`) with source
action `+0x24`; it is not damage read from the auxiliary geometry.
Effect wrappers `0x0089D4C0/0x0089D530` forward to virtual
`+0x190/+0x194`: `guy_primary_lotus_screen_fragment_begin`
(`0x0089D560`) and `interaction_release_screen_fragment_handle`
(`0x00886700`). They create/release a retained framebuffer fragment effect,
described below; the release wrapper does not itself process damage.

### Shared Lotus local geometry and surface particles

The selected auxiliary animation's graph is locally defined in **both**
`2GUYCHA1` and `2NRZCHA1`. Guy-prefixed namespace/name keys in NRZ
do not imply loading GUYCHA1 or `CMN/EFFECT0X` for this graph.

| Typed node | `2GUYCHA1` local ID | `2NRZCHA1` local ID |
| --- | ---: | ---: |
| `ANM_pguyskl10`, tag `0x0700` | 290 | 26 |
| `CMP_eff_dummy_guyall`, tag `0x0900`, 20 children | 265 → 266..285 | 1 → 2..21 |
| `OBJ_eff_dummy_guyall`, tag `0x0100`, no model | 266 | 2 |
| Four wind wrappers → local `OBJ_e06wnd01` | 268..271 → 286 | 4..7 → 22 |
| Two wave wrappers → local `OBJ_e00wave01` | 273..274 → 287 | 9..10 → 23 |
| Ten impact wrappers → local `OBJ_e03ko-ka02` | 276..285 → 288 | 12..21 → 24 |
| `OBJ_box00_eguyrng10` → zero-part model | 272 → 289 | 8 → 25 |

The three geometric models have one part each. Their chains in both files
are wave model 293 → part 294 → material 295 → texture 296,
wind 298 → 299 → 300 → texture 301 `TEX_eguyrng11`, and
impact 303 → 304 → 305 → texture 306 `TEX_eguyrng12`.
Wave's palette is local 309 in GUYCHA1 and 310 in NRZCHA1;
wind/impact select local palettes 307/308 in both. The complete selected
stored object/model/material/image edges resolve locally. This does not
establish identical foreign packed-geometry evaluation in NA2; the
[resident CCS contract](../../../game/files/ccs_runtime.md) owns that separate limitation.

Lotus state 2 creates a **separate common particle emitter**, retaining it
at `+0x7F0`: resident `battle_particle_create_fields` (`0x002FFA90`)
uses descriptor `0x0047A600` and field records
`0x0047A640/60/80`. Its position is offset -300 on the height component
and its follow pointer is opponent position `+0x360`. The actor replaces
choice `+0x238` with `34 + field_surface_variant`
(BATTLE `0x008268C0`) before publication. That helper returns 1 without
background control, otherwise calls `battle_background_particle_variant`
(`0x007C4930`), whose return range is 0..6. Choice rows 34..40 at
resident `0x00479090..0x004790F0` therefore cover all selected variants.

`battle_particle_resource_cache_setup` (resident `0x002730D0`) builds
101 eight-byte cached choices from `0x00478E70`'s 16-byte rows.
The selected rows name provider `particle`, alias base choice 1
`CMP_e0xleaf01`, and encode default/`c1..c6` palette selection from
`CLT_e0xleaf01` names. `battle_particle_bind_resources` (`0x003001C0`)
classifies the base as composition `0x0900`, applies the selected palette
mapping and registers it through `battle_particle_register_resources`
(`0x003003A0`). These CLT aliases do not turn the emitter into an
independent palette-only effect.

Original NUN3 `CMN/PARTICLE.CCS` supplies composition 54 → object 55
→ model 56 → part 57 → material 58 → texture 59 → base palette 144,
with alternate palettes 145..150. The corresponding original NA2 provider
supplies 51 → 52 → 53 → 54 → 55 → 56 → base 140,
with alternates 141..146. The stored files and decoded sizes differ:
NUN3 SHA-256 `0125C0E9F2CA4C04AFA7C5595C5AED5E1394D95EEC3F34193488FA74DF91CF5F`,
228272 decoded bytes; NA2
`A0379670F510FFC7C13E4F45B1C69A92072D06294D1D4862EED710979EBAEF94`,
219892 decoded bytes. The checked typed counterparts establish the
available leaf graph, not whole-provider byte equality or equivalent cache IDs.

State 3 and destruction invalidate retained particles only after their
serial handle still resolves to the same object, set its removal fields
`+0x34/+0x23C`, and clear the actor pointer. Destructor also checks
`+0x7F4`; no creation of that second pointer was established by the
selected class paths. `battle_particle_cleanup_fields`
(`0x002FFF90`) releases field state, while `battle_particle_destroy`
(`0x002FFEE0`) frees the resource-descriptor array. Lotus destruction
pairs armed surface services with `0x002B80F0/0x002B8280` and destroys
the embedded player before common cleanup. This establishes actor-owned
cleanup; it does not establish enclosing CCS-provider retention/release.

### Shared contact and landing effects

The shared Entry/Lotus classes also reach resident effects outside their
local CHA graphs. The following roots apply to both Guy 29/30 and
Green Beast 67/68. Common scene-effect indices address 24-byte rows at
`0x004773C0`; particle choices use the separate cache described above.
Neither set of indices is a CCS directory ID.

| Actor path / resident effect root | Selected providers and resources |
| --- | --- |
| Entry's first captured leap, `battle_dynamic_entry_initial_hit_effect`, `0x002607F0` | Scene-effect index `0x74` aliases base 8, `EFFECT0X / ANM_e0x_gard_01`, with `CLT_e0xfla03c1` and optional scene `CMP_e0xfla12-00` from index 44. Particle descriptor `0x004795A0` selects cache choice 29, `CLT_e0xpar00c1`, over `PARTICLE / EFF_e0xpar00`. |
| Entry's alternate initial effect, `battle_hit_effect_with_composite`, `0x0025F360` | Called with type 2; `battle_hit_effect_base` (`0x0025EDC0`) binds scene-effect index 3, `EFFECT0X / ANM_e0x_hit_97`. Random composite ID `0x37` or `0x35` adds paired indices 57/58, `ANM_e0x_gan_00a/b`, or 53/54, `ANM_e0x_gon_00a/b`. Its particle descriptor `0x00479A70` binds `EFF_e0xpar00/par01` with their `c5` palettes. |
| Lotus regular impact via `guy_primary_lotus_impact_service`, `0x0089D840`, then `battle_lotus_impact_effects`, `0x00237780` | Composite ID `0x38` selects scene-effect indices 59/60, `EFFECT0X / ANM_e0x_dogo_00a/b`. Particle descriptor `0x0047A490`, fields `0x0047A4D0/4F0`, uses default choice 5, `PARTICLE / EFF_e0xsmok06`, with parameter `+0x1FC = 30`. |
| Lotus grounded recovery, `battle_surface_landing_effects`, `0x00267C00` | Masked surface `0xE0A000` calls `battle_surface_drop_effects` (`0x002677F0`); selected other surfaces call `battle_landing_smoke_effects` (`0x00263C50`). These bind `PARTICLE / EFF_e0xdrop01` and `EFF_e0xsmok20`, respectively. |

`battle_effect_bind_resource` (`0x0023E3A0`) resolves the common row,
including kind-6 aliases and old/new palette pointers, then owns a typed
model/animation/effect instance at `+0x19C/+0x1A0` and optional
auxiliary state at `+0x1A8`. `battle_effect_bind_resource_with_scene`
(`0x0023DD40`) accepts an optional composition/scene descriptor for
the animation child. Entry's `CMP_e0xfla12-00` argument is that scene
descriptor, rather than a camera record.

The selected original NUN3 `CMN/EFFECT0X.CCS` edges are:

| Animation/composition root | Selected local descendants |
| --- | --- |
| `ANM_e0x_gard_01`, 697 | Dot model 9 → part 10 → material 11 → texture 8 `TEX_e0ycolor01` → palette 2538; smoke wrapper 1161 → object 1162 → model 2494 → part 2495 → material 2496 → texture 1166 `TEX_e0ysmok01` → palette 2560. |
| Optional `CMP_e0xfla12-00`, 1783 | Object 1784 → model 1785 → part 1786 → material 1787 → texture 1755 `TEX_e0xfla03` → base palette 2134, with selected alternate 2135 `CLT_e0xfla03c1`. |
| `ANM_e0x_hit_97`, 934 | Dot model 9 and smoke 1161/1162 as above; offset animation 1152 → ring wrapper 1153 → object 1154 → model 1875 → part 1876 → material 1877 → texture 1878 → palette 2163; ring wrapper 1170 → object 1174 → model 1899 → part 1900 → material 1901 → texture 1902 → palette 2167, with parent 1169's zero-part model 1177. |
| `ANM_e0x_gan_00a/b`, 675/689, and `ANM_e0x_gon_00a/b`, 785/799 | Local dot/ka/ko/nn objects and the one-part model chains below; zero-part box models 673/674/687/688 and 783/784/797/798. |
| `ANM_e0x_dogo_00a/b`, 503/523 | Line box object 1089 → zero-part model 1112, and smoke object 1162's model/image/palette chain above. |

The selected GAN/GON geometry shares texture 8 and palette 2538:

| Local object | Model → part → material |
| --- | --- |
| Dot `01a/01b`, 640/655 | 2211 → 2212 → 2213 / 2214 → 2215 → 2216 |
| Ka `01a/01b`, 527/534 | 2255 → 2256 → 2257 / 2258 → 2259 → 2260 |
| Ko `01a/01b`, 496/516 | 2273 → 2274 → 2275 / 2276 → 2277 → 2278 |
| Nn `01a/01b`, 458/472 | 2302 → 2303 → 2304 / 2305 → 2306 → 2307 |

All listed selected object/model/material/image references are defined in
the donor provider. The selected `dogo/gan/gon` animation names,
`CMP_e0xfla12-00` and `CLT_e0xfla03c1` are absent from the checked
original NA2 `EFFECT0X` directory. NA2 does contain `ANM_e0x_gard_01`
and `ANM_e0x_hit_97`, at IDs 505/768, but their stored graphs differ,
including generator/sampling descendants. A shared name therefore does
not establish an interchangeable typed graph.

The separately selected original `CMN/PARTICLE.CCS` edges are:

| Base resource | NUN3 typed chain | NA2 typed counterpart |
| --- | --- | --- |
| `EFF_e0xsmok06` | Effect 87 → texture 88 → palette 178 | 85 → 86 → 174 |
| `EFF_e0xsmok20` | Effect 22 → texture 112 → palette 184 | 110 → 111 → 180 |
| `EFF_e0xdrop01` | Effect 37 → texture 38 → palette 127 | 34 → 35 → 123 |
| `EFF_e0xpar00` | Effect 67 → texture 68 → base palette 158; `c1/c5` palettes 159/163 | 64 → 65 → base 154; `c1/c5` 155/159 |
| `EFF_e0xpar01` | Effect 19 → texture 70 → base palette 164; `c5` 169 | 67 → 68 → base 160; `c5` 165 |

Entry's type-2 hit emitter explicitly creates two resource descriptors,
replacing `par00`'s base palette with `c5` and doing the same for `par01`.
`battle_particle_cached_palette` (`0x002FF910`) resolves an alternate
by formatting `CLT_%sc%d` from the base effect name after `EFF_` and
the cached selector. `battle_particle_descriptor_remap_palette`
(`0x002A6EE0`) stores original/replacement pointers at `+0x0C/+0x10`.
These cache aliases select typed palette leaves of the base effects.

Landing smoke creates eight pooled scene-effect objects, binds common
index `0x88`, and assigns lifetime 40 with motion and randomized rotation.
Surface drops create sixty `0x260`-byte moving objects, bind index
`0x97` aliasing base `0x80`, and use the default drop palette. Every
fourth stores position at `+0x240` and value `0x27` at `+0x250`.
The selected update/draw paths do not establish that latter field's
consumer or any additional provider selected by it. The landing dispatcher
returns without creating these effects on `0x202020/0xE0E000`;
`0xD0D0` emits only its checked spatial SFX `8/0x3C` on this path.

`battle_create_composite_effect` (`0x002629D0`) allocates `0x430`,
with main and embedded `+0x210` scene players. Its paired animation
bindings select the GAN/GON/DOGO resources above.
`battle_composite_effect_destroy` (`0x00272710`) destroys both players;
`battle_surface_drop_destroy` (`0x00272F30`) destroys its main player.
Both reach `battle_effect_player_destroy` (`0x0023CB20`), which releases
owned typed resources before common owner cleanup and optional free.
Particle field/resource cleanup remains as described above.

The common virtual `+0x190/+0x194` service has a different purpose.
`interaction_begin_screen_fragment_effect` (BATTLE `0x00886680`) and
Lotus's override `guy_primary_lotus_screen_fragment_begin`
(`0x0089D560`) call resident `battle_screen_fragment_create`
(`0x00264960`), allocating `0xA30` and retaining an effect-manager
handle at actor `+0xC8`. `battle_screen_fragment_initialize`
(`0x00257C60`) initializes two framebuffer draw/texture environments,
32 fragment records at `+0x484` with stride `0x2C`, and optionally a
secondary renderer at half blend. No CCS camera resource is bound there.
`interaction_release_screen_fragment_handle` (`0x00886700`) checks
the manager's index/serial/object triple, ends the retained object and clears
the handle. `battle_screen_fragment_destroy` (`0x00257B80`) releases
the optional renderer, render packet, two environments and embedded
renderer before base cleanup. This closes the selected effect owners;
enclosing common-CCS retention and foreign packed-geometry evaluation
remain separate questions.

### Native Might Guy jutsu actor comparison

Native NA2 resource 140's factory case `0x00774A28` allocates `0x1130`
and calls `guw_maximum_entry_construct` (`0x007EC440`). Its RTTI
identifies `ccSkillGUW000`, resident vtable `0x005EE150`; the constructor
uses `skill_tyo_base_construct` and adds two effect handles at
`+0x1110/+0x111C`. `guw_maximum_entry_events` (`0x007EC5A0`) owns
frame-specific framebuffer fragment, voice/SFX and skill-service calls; contact
(`0x007EC870`) builds a native working interaction record and switches
source animation. Destruction (`0x007EC4A0`) releases the two handles,
then the inherited linked-player owner. This is not the donor `0x790`
Entry class or its embedded contact/capture layout.

Native resource 141's case `0x00774A50` allocates `0x1350` and calls
`guw_construct` (`0x007ECB50`), installing `ccSkillGUW001` vtable
`0x005EDF00`. It constructs contact shapes `+0xFF0/+0x1040` and
embedded players `+0x10E0/+0x1210/+0x12B0`. Its `guw_select`
(`0x007EDEE0`) binds `ANM_2guwcha1a/b/c` to the first embedded
player, with a separate enable byte and native contact/state callbacks.
`guw_destruct` (`0x007ECCC0`) clears its retained child, destroys the
first player/contact shapes and performs native registry/base cleanup.
Those executable/layout differences establish a distinct Night Phoenix
actor; they do not equate every inherited native method with donor Lotus.

### Guy asset bindings

The checked donor files are `1GUYBOD1`, `1GUYBOD2`, `2GUYBOD1`,
`2GUYCHA0/1`, `3EYE/3GUY3EYE` and `3EYE/3GUY3PCT`. Their complete
identities are in [File identities](../../../game/files/file_identities.md#guy-comparison-inputs).
The body/CHA0/CHA1 contain 120/3/10 `ANM_` directory names, versus
136/6/6 for native `2GUWBOD1/2GUWCHA0/1`. Each donor battle file's 25
marked common-2 names occurs in NA2 `CMN/2CMNBOD1`; this bounds names,
not behavior of their bindings. Neither donor CHA file has a `BIN_` name;
native CHA0 contains `BIN_skldamoffs_2guwcha0`.

Donor CHA0 additionally marks directory 52, `OBJ_eff_dummy_guycha1`,
under `#c\2guy\max\2guycha1.max`. CHA1 supplies matching local object
80, typed `0x0100`, and compound 291, typed `0x0900`; that object has
no model ID. Thus the cross-CHA dependency is a transform/effect anchor.
It cannot be replaced by a similarly named model.

`guy_setup_hair_models` (`0x001FBD20`) borrows
`OBJ_2cmn00t0 head/body` from the scene, then owns two `0x50` model
instances from `MDL_2guy00t0 hair1/hair2` in the battle body.
The typed chains are hair1 object 3269 → model 3270 → material 3272
`MAT_clut` → texture 3266 `TEX_2guybody` → palette 3283;
hair2 object 3274 → model 3275 → material 3277 `MAT_clut` → texture
3278 `TEX_2guybod2` → palette 3280. Their model-part IDs are 3271/3276.
`guy_select_hair_model` (`0x001FBE50`) attaches the selected
instance to the borrowed head node. `guy_sync_head_node_state`
(`0x001FBF20`) synchronizes body/head transform state; release
(`0x001FBFD0`) frees the two owned models, not the borrowed scene nodes.

NUN3 `ai_tick` (`BATTLE 0x00825260`) uses the actual character
ID for the eight-byte descriptor at `0x0093ADF0`. Guy's row `0x0093AE90`
contains `{2,5}`. NA2 Might Guy 69 uses
[per-tick region/threshold values](../../session/battle_ai.md#per-side-state-block)
and separate [initialization/reaction flags](../../session/battle_ai.md#character-descriptors-and-hard-coded-exceptions).
Those native fields have different recovered roles; the stored rows do not
establish the full AI behavior. Filename families, jutsu selectors,
voice-event pair, compact-bank descriptor, streamed archive row, UJ list/default,
effect factory owner check and AI descriptor are independent ID consumers.

## Callbacks

The checked pair is NUN3 Guy 20 (`guy`) and NA2 Might Guy 69 (`guw`),
with their exact records and callback tables in
[Character assets](#records-moves-and-assets).
The donor has channel 2/channel 3/source-response roots, while native Guy
additionally has channels 1/5/7. Action numbers below belong to each version's
own array; [the correspondence](kakashi.md#complete-authored-move-correspondence)
does not make numeric IDs interchangeable.

NUN3 `guy_channel2` (`0x001FC100`) emits position request `0x7C` and
its delegated visual helper on neutral state `0/3` event 10; state `0/4`
has its own events 4/5. `guy_channel3` (`0x001FC200`) emits position
request `0x7C` for action `0x2A` event 15, `0x29` for action `0x1D`
event 5, a delegated event for action `0x1C` event 3, and sound event
`0x20` on action `0x1A` events 20/25/32. At event 32 it also invokes
`fighter_request_voice` with pseudo-event `-2`.
Actions 4/5/6 have distinct phase/timeline sound and voice schedules:
action 4 phase 1 event 8, action 5 phase 1 events 3/5 and phase 2 event
10, and action 6 phase 1 events 2/7. Phase-0 preparations emit `0x7C`
at their respective events. The indexed `fighter_request_sound_effect`
values `0x10/0x20/0x23` are sound controls, not PLVOICE indices.

`guy_hit_response` (`0x001FC640`) branches on actions
`0x17/0x1A/0x1B/0x1C/0x1E/0x1F/0x22`, with return set
`{-1,0x27,0x29,0x2A,0x2E,0x30,0x31,0x33}`. Its threshold helper
`fighter_action_repeat_for_receiver` (`0x001C0770`) returns the current
action's repeat field or the matching receiver's delegated count; it is
not an unconditional hit-count getter. Receiver flags, phase and the
threshold result determine the selected response. Only mode 2 writes the
authored attack/planar/vertical overrides at receiver `+0x8F0/+0x8F8/+0x8FC`.
Action `0x22`, for example, supplies scales `1.0/1.5/2.0` while retaining
the default response `-1`. Native `might_guy_hit_response`
(`0x002C55B0`) has a different selected return set `{-1,0x2A,0x39}`.

Native `might_guy_channel1` (`0x002C3DF0`) switches action categories
using the mode byte: actions `0x1C..0x2A` change their admission values
across modes 0/1/2. Its channel-3 action-`0x30` continuation window is
described above. NUN3 Guy has no channel-1 equivalent in his selected table.
His virtual hair update instead reads effect `0x21`; the
[effect/lifetime comparison](#ultimate-jutsu-and-effects)
owns that behavior. [Guy input admission and chaining](#guy-input-admission-and-action-chaining)
records the ordinary selector, mode categories and payload-window gates.
Complete transitive event-helper behavior remains open.

## Ultimate Jutsu and effects

The checked identities are NUN3 Guy 20 (`guy`) and NA2 Might Guy 69
(`guw`). NUN3 `ultimate_jutsu_record_get` (`0x00373860`) indexes
`0x004D83E0` with stride **`0x24`**. Guy's local list at `0x0047B580`,
selected through character table `0x0047B760`, contains 20 records,
indices **237..256**; its records begin `0x004DA534`.
`character_ultimate_record_by_local_index` (`0x0028BC20`) reads that list.
The mode-1 default table at `0x0047BDD0` selects 237; the other default
table at `0x0047BD50` selects 242. This identifies stored defaults, not
every caller's selection mode.

| Record | Authored skill | Stored English title | Intro member | Effect | Damage percent |
| ---: | ---: | --- | ---: | ---: | ---: |
| 237 | `0x56` | Broad-Minded and Open-Hearted | 84 | — | 25 |
| 238 | `0x57` | Hot-Blooded Primary Lotus | 84 | — | 30 |
| 239 | `0x58` | One's Own Rule | 85 | — | 40 |
| 240 | `0x59` | Hidden Lotus | 86 | `0x21` | 20 |
| 241 | `0x5A` | Ultimate: Hidden Lotus | 88 | `0x21` | 25 |
| 242 | `0x5B` | Dashing Up Burning Spirit! | 89 | `0x21` | 35 |
| 243 | `0x1A` | Primary Lotus of Love and Youth | 90 | — | 40 |
| 244 | `0x33` | Eternal Rivals | 91 | — | 40 |

Records 245..250 and 251..256 repeat skills `0x56..0x5B` as named
versions 2 and 3, with differing stored stat adjustments. They are twelve
additional records, not twelve additional cinematic timelines. The selected
skill comes from `+4`; `+6` is an **ability-prerequisite count**, checked
against the three ability IDs at `+8/+0xA/+0xC` by
`ultimate_jutsu_record_abilities_available` (`0x0028B830`). It is not
NA2's category field. Intro/effect/damage are halfwords at
`+0x12/+0x14/+0x16`; six stat adjustments occupy `+0x18..+0x22`.
The individual stat meanings and raw bytes `+0xE..+0x11` are not fully
established by this character comparison.

NA2 Might Guy's list at `0x006044A0`, selected by row `0x005AD0C4`,
contains **151/152/153**, with default 151. At
`0x005AF80C/0x005AF820/0x005AF834`, the native `0x14`-byte records
select skills **`0x7A/0x79/0x7C`**, categories **3/2/1**, intro members
**130/131/132**, damage **45/25/35** and no post-cinematic effect.
Their stored Japanese titles are Own Rule—rock-paper-scissors,
Own Rule—youth, and Morning Peacock (translations of the checked strings).
No donor list/category equivalence follows from sharing a character name.

NUN3 Guy's post-cinematic `0x21` remains an effect on ID 20.
`ultimate_jutsu_record_form` (`0x0028BFF0`) maps only effects
`0x3D..0x46` to replacement IDs, so this effect does not replace the fighter.
The presentation at `0x002E36D0` applies this class-1 effect only after
its cinematic-completion outcome gate. The effect record at `0x00474B74`
has authored lifetime 600 and flags `0x92`.
`status_effect_bind_factories` (`0x00231530`) copies the pair
`{0x21, guy_effect_create}` at `0x00473D40` into its initially-null
factory slot. `effect_list_add` (`0x00231F60`) then uses
`guy_effect_create` (`0x001FB9B0`), a `0xC0` allocation,
`guy_effect_construct` (`0x001FBA10`) and vtable `0x00689370`.
Construction enables fighter material state only for actual owner ID 20;
destruction (`0x001FBA80`) disables it before common cleanup.
The fighter's virtual update checks effect `0x21` to select hair 0/1;
the same effect selects its alternate compact voice-event list.
Those concrete bindings belong to
[Guy assets](#records-moves-and-assets)
and [Guy voice](#voice).

Native Might Guy instead has the two associated Eight Gates stages,
effects **`0x47/0x48`**, retaining ID 69. Their authored lifetimes and
resource deltas are recorded under [Authored lifetime](../awakening.md#authored-lifetime-and-resource-behavior);
the controller advances between stages under its progress gate.
Native channel 1 also changes mode-dependent move categories. These are
different effect IDs, entry mechanisms and move-state consumers. All
remaining NUN3 effect-scalar consumers are outside this bounded comparison.

## Cinematics

This section checks NUN3 Guy, ID 20 (`guy`), against the resources selected
by his own Ultimate Jutsu list. NA2 Might Guy is ID 69 (`guw`); its selected
skills are `0x7A/0x79/0x7C`, rather than the donor skills below.
Record selection and damage belong to
[Guy UJ/effects](#ultimate-jutsu-and-effects).

NUN3 `sp_skill_request_row` (`0x00373FB0`) indexes a resident
`0x14`-byte row at `0x00670140`. `sp_skill_build_requests`
(`0x00296030`) requests the main resident file first, then the counted
extra resident paths, all with `0x1000`, followed by the stream with
`0x400`. The display pointer is row `+0`, main path `+4`, byte counts
`+8/+9`, extra pointer `+0xC`, and stream-pair pointer `+0x10`.
This is not NA2's relocated `0x18`-byte SINF request-row format.

| Skill / request-row address | Resident main / stream pair | Explicit extra resident paths | Stream camera directory ID | Marked stream / main references |
| --- | --- | --- | ---: | ---: |
| `0x56`, `0x006707F8` | `str/d20_101e.ccs` / `str/d20_101.ccs` | none | 478 | 199 / 3 |
| `0x57`, `0x0067080C` | `str/d20_201e.ccs` / `str/d20_201.ccs` | none | 586 | 185 / 4 |
| `0x58`, `0x00670820` | `str/d20_102e.ccs` / `str/d20_102.ccs` | none | 745 | 217 / 4 |
| `0x59`, `0x00670834` | `str/d20_103e.ccs` / `str/d20_103.ccs` | none | 1008 | 326 / 4 |
| `0x5A`, `0x00670848` | `str/d20_202e.ccs` / `str/d20_202.ccs` | none | 1293 | 259 / 4 |
| `0x5B`, `0x0067085C` | `str/d20_301e.ccs` / `str/d20_301.ccs` | `1guybod2.ccs` | 1413 | 210 / 3 |
| `0x1A`, `0x00670348` | `str/d03_402e.ccs` / `str/d03_402.ccs` | `1rocbod1.ccs`, `1guybod1.ccs` | 1735 | 263 / 2 |
| `0x33`, `0x0067053C` | `str/d08_401e.ccs` / `str/d08_401.ccs` | `1kksbod1.ccs`, `1kksbod2.ccs`, `1guybod1.ccs` | 832 | 252 / 3 |

All eight camera entries are named `CAM_camera01`. None of these sixteen
files has a `BIN_` directory name. That absence does not imply absence of
embedded playback commands or code-selected resident tables.
The last two skills are shared cinematic requests; the character-local
list does not give Guy eight exclusive `d20` streams.

**Clean-file observation:** every marked namespace/name key in each stream
and its main resident companion has a non-carrier typed definition within
that pair's matching resident file, its listed extra paths, donor
`1GUYBOD1`, `1CMNBOD1`, `STRMCMN`, and `CMN/EFFECT0X`.
The lookup removes the leading `#` marker but keeps the complete namespace
and resource name. For streams `d20_103/202`, the resident companion
supplies the additional `1guybod2` keys without an explicit extra request.
The counters in the table cover all marked keys, with zero unresolved keys
against this checked provider set. This proves stored provider identity
and typed-definition presence, not every nested field, lifetime or renderer
interpretation. In particular, foreign packed/skinned geometry has the
reader differences recorded in [CCS runtime](../../../game/files/ccs_runtime.md#nun3s-parser-compared-with-na2s).

`sp_skill_play_start` (`0x00296250`) installs per-request begin/update/draw/end
callbacks and retains role/side IDs, selected skill and both resident
per-skill tables. `sp_skill_play_begin` (`0x002952D0`) binds the attacker
body, defender body/eye/mouth, camera target and auxiliary scene object.
`sp_skill_auxiliary_table` (`0x0047C248`) supplies the request-ordinal
scene data. `sp_skill_defender_position_table` (`0x0047C958`) supplies
a counted frame-threshold list and defender-ID-indexed signed XYZ triples;
`sp_skill_play_update` (`0x00294F10`) applies the corresponding translation
matrix. The latter table is placement data, not audio cues. The exact
per-defender triples and every timed appearance command are outside this
character-specific comparison. The selected intro audio's physical members
are established in [Guy voice](#voice).

## Voice

Checked identities: NUN3 Guy 20 (`guy`) and NA2 Might Guy 69 (`guw`).
These concrete selections use the separate compact, PLVOICE and SOUND
routes already described above; their numeric domains are independent.

NUN3 `audio_character_bank_descriptor` (`0x00185A30`) selects twelve-byte
rows at `0x00388290 + ID*12 + set*0x2AC`. Guy's rows at
`0x00388380/0x0038862C` hold bank/header/sample triples
`{0x00970800,0x13B0,0x5B2B0}` and
`{0x019E3000,0x13B0,0x5DCE0}`. Set 0 is English and set 1 Japanese.
`audio_prepare_character_bank_load` (`0x0018C210`) requests SNDDATA,
copies those participant-selected values and aligns the sample start to
`0x800`. Native Might Guy's row `0x003FDB6C` holds
`{0x010E0000,0x1950,0x6F0E0}`.

NUN3 `fighter_voice_event_list` (`0x0019BDA0`) selects Guy's base list
`0x004E4F30` or effect-`0x21` list `0x004E4F80`. Events
`0/0x18/0x19` map to controls `0/26/27` or `110/136/137`.
Against controls at `0x00385440`, both lists emit programs `0/26/27`;
the default key is `0x3C` normally and `0x3D` with effect `0x21`.
`fighter_request_voice_event` (`0x0019C0B0`) adds its event/cooldown gates;
`audio_emit_fighter_voice_control` (`0x00186460`) encodes the admitted
program/key and position-dependent velocity. This is compact packet evidence,
not a PLVOICE cue mapping.

| Exact bank | Program | Sset / Smpl | Vagi | Sample file offset in SNDDATA |
| --- | ---: | --- | ---: | ---: |
| NUN3 Guy, English | 0 | 1 / 1 | 14 | `0x009904E0` |
| Same | 26 | 26 / 26 | 39 | `0x009C7870` |
| Same | 27 | 27 / 27 | 19 | `0x00997820` |
| NUN3 Guy, Japanese | 0 | 1 / 1 | 14 | `0x01A04190` |
| Same | 26 | 26 / 26 | 39 | `0x01A3D100` |
| Same | 27 | 27 / 27 | 19 | `0x01A0AFF0` |
| NA2 Might Guy | 0 | 0 / 0 | 6 | `0x010F2820` |
| Same | 26 | 46 / 46 | 56 | `0x0114A6B0` |
| Same | 27 | missing program entry | — | — |

All listed samples use 22050 Hz and sample/set velocity bounds 1..127.
Donor splits admit keys 12..119, including both emitted defaults; the native
checked splits admit only key `0x3C`. These are stored sample candidates
joined to the shared synthesizer's lookup, not spoken-content or admission
claims. Native Guy's full alternate-control emission was not traced here.

Guy's PLVOICE descriptors `0x00388B18/0x00388CD8` select physical outer
members 19/75, with handles 89/145 and declared count 209 in each language
set. Their AFS ranges start at file offsets `0x008B0000/0x01940000`,
with sizes 526336/364544. Both contain the same 29 populated physical
indices: `6,7,23,24,45,47,49,50,68,69,81,82,83,84,85,86,87,92,111,112,
118,125,151,165,166,167,199,202,208`. Empty indices remain sparse.
NA2 Might Guy's outer member 68 starts at `0x00CDC800`, size 380928,
with 41 dense physical members. Its suffix-number list at `0x003FF160`
is `45,47,49,63,68,69,125,126,151,155,165,166,167,199,209,210,211,235,
269,290,293,302,303,306,307,308,312,313,318,323,324,338,339,364,365,
366,369,370,373,374,379`, terminated by `-1`. A suffix number is not
a physical member index. The donor 81..87 suffixes have no corresponding
entry in that native list; this does not establish spoken-content matches.

### Guy Ultimate Jutsu intro archive

The donor UJ intro halfwords are **SOUND-family members**, not those Guy
PLVOICE members. Presentation `0x002E36D0` calls
`audio_request_language_sound_member` (`0x0018A1C0`) with bank 9 and
mono slot 0. It adds 14 for the alternate language and invokes archive
family 0. Descriptors `0x00388878/0x003888E8` are SOUND outer 9/23,
each with 149 members. Their physical AFS starts are
`0x12D50800/0x260C1800`, sizes 2658304/2451456.

| Intro member | English SOUND file offset / bytes | Japanese SOUND file offset / bytes |
| ---: | --- | --- |
| 84 | `0x12EC1800` / 14890 | `0x2621A800` / 10760 |
| 85 | `0x12EC5800` / 22324 | `0x2621D800` / 14657 |
| 86 | `0x12ECB000` / 21480 | `0x26221800` / 12081 |
| 88 | `0x12ED5800` / 13742 | `0x26228800` / 10798 |
| 89 | `0x12ED9000` / 17157 | `0x2622B800` / 10762 |
| 90 | `0x12EDD800` / 20396 | `0x2622E800` / 15551 |
| 91 | `0x12EE2800` / 17725 | `0x26232800` / 16544 |

These are the seven physical intro selections used by the eight distinct
Guy skills. The complete cinematic frame-cue/damage route remains separate
from this startup voice. Sample offsets are source-file evidence, not live
IOP addresses. Input identities are owned by
[File identities](../../../game/files/file_identities.md#guy-comparison-inputs).
