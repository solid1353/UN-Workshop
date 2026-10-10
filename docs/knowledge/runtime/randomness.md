# Resident randomness

## Research coverage

Established: three resident streams, coordinated reset, wrapper reductions,
caller gates and draw counts, state recovery, cycles and vectors. Open: caller
ordering, unproven branches, animator dispatch/period writers, arithmetic low
bits and unnamed consumers' gameplay meaning.

## Evidence and scope

This concerns retail NA2 (`SLPS-25837`), resident `SLPS_258.37` and its
`BTL.BIN` consumers. File identities and address mapping are owned by
[Retail game file identities](../game/files/file_identities.md).
Findings are static or derived from the recovered recurrences. An incoming
static edge does not establish every internal branch's feasibility.

Names and per-routine details are maintained in `@annotations/NA2`.
Addresses below are live.

Related owners: [Damage](../gameplay/combat/damage.md),
[Substitution](../gameplay/characters/substitution.md),
[Save data](../game/save_data.md), [Controller input](controller_input.md),
[Battle camera](../gameplay/session/battle_camera.md), and
[Battle lifecycle](../gameplay/session/pause_and_replay.md#tone-shade-destination-block).
Camera descriptions here establish draw/reduction/store behavior only.

| Stream | Output | State | Coordinated reset |
| --- | --- | --- | --- |
| MT19937 | `prng_next` and MT wrappers | 624 low32 words in eight-byte slots in `rng_mt_state`, `rng_mt_index` | Fixed bootstrap; tag chooses 0..31 discarded words |
| 64-bit LCG | `prng_u32` | `rng_lcg_state` | Full low32 tag seed, no output draw |
| Persistent16 | `rng_persistent16_next` | Halfword `rng_persistent16_state` | Advance existing state 0..31 times, never reset |

They share an initializer, not a mutable state.

## State and clean-image values

| Data / live address | Size | Cold value | Role |
| --- | ---: | --- | --- |
| `rng_lcg_state`, `0x003FAD10` | 8 | 1 | LCG word |
| `rng_mt_twist_table`, `0x003FB3D0` | 2 x 8 | 0, `0x9908B0DF` | Even/odd twist |
| `rng_current_tag`, `0x00602A20` | 4 | `0x1100` | Reset input, then retained MT output |
| `rng_previous_tag`, `0x00602A24` | 4 | `0x1100` | Last reset input snapshot, no resident read |
| `rng_mt_index`, `0x00602A28` | 4 | 625 | Lazy bootstrap; 624 requests twist |
| `rng_persistent16_state` | 2 | Zero | Persistent16 state |
| `rng_mt_state` | 624 x 8 | Zero | MT state, low32 of each slot |

The resident load segment is file-backed through `0x0060737F`; zero-fill
begins at the address of `arena_low_boundary`. The tag/index and LCG are
initialized data; the persistent16 halfword and MT array begin at zero. The
library anchor pointer `rng_library_anchor` contains `0x003FAC68`, whose LCG
field is `+0xA8`.
These globals are annotated in the resident ELF's mapped BSS block. Related
globals are `effect_manager_global`, the model-validity gate `battle_hub`,
the pause-sequence pointer `battle_pause_controller`, and the masked selector
source `environment_published_primitive_flags`.

## Coordinated initialization and reseeding

`rng_initialize` (`0x00180060`) runs in this order:

1. Snapshot the current 32-bit tag.
2. Seed the LCG with its full low32 value.
3. Rebuild 624 MT words from fixed `0x1100`, index 624.
4. For `n = tag & 31`, discard one MT word and advance persistent16 once,
   repeated n times.
5. Retain one more MT word as the next reset tag.

This consumes n+1 MT words, n persistent16 advances and no LCG output. The
final MT index is n+1. `rng_set_tag` alone is a four-byte store; it does
not reseed anything.

`resident_flow_dispatch` supplies `RngEngineRoot.update_counter`
before reset. `engine_root_initialize` starts it at zero;
`engine_root_update`, reached through `scheduler_update_loop`, increments
it modulo 2^32. The seed is a software update counter; no hardware entropy
source was identified. If timing is the only changing input, the MT selector
repeats every 32 updates while the full LCG seed repeats only at counter wrap.

The other reset is in `manager_initialize`, reached by
`manager_construct` on `manager_allocate`'s null-manager branch.
It uses the retained tag without a setter; existing-manager updates skip
construction. Thus a following second reset selects MT[n]&31 even if ordinary
MT/LCG draws intervene. Counter zero gives selector composition 0 -> 9.
With no intervening persistent16 calls, the two-reset state is retained tag
`0x0F96266C`, next MT `0x0EADC242`, LCG seed `0x889C77E9`, and
persistent16 `0x8CAF`. This is a conditional derived vector.

## MT19937 core

`prng_next` produces canonical 32-bit MT19937 outputs from 624 words
stored in eight-byte slots. Index 625 triggers the fixed `0x1100` bootstrap;
index 624 triggers a twist before output. `rng_initialize` rebuilds the same
fixed state and leaves its first draw to perform the twist.

The recovered nonzero state therefore has canonical MT19937 period
`2^19937 - 1` if allowed to run continuously. That long core period should not
be confused with reset diversity: every `rng_initialize` call discards the
current MT history, rebuilds this one fixed state, and resumes at only one of
32 early offsets selected by the tag.

The exact state range is 4,992 bytes because each 32-bit word occupies a
little-endian eight-byte slot. SHA-256 over the complete
MT state-array layout is:

| State-array point | SHA-256 | First / last low-32-bit words |
| --- | --- | --- |
| Fixed bootstrap, before twist | `FB6C273F74FDD5B4EEE77F35190BD11C4B2DA8BD706EA7F72FB043D967F2BB86` | first `000011EA`; last `5903372E` |
| After the first twist | `6461422553F410D65F4DAC0AF5DA78A93D98BDDCE14DC631E6C8147E1A651008` | first `2B577921`; last `D98F2A34` |

`rng_initialize` always makes at least the final retained-tag draw, so its
completed state has the post-twist hash for all 32 selectors. Drawing does not
mutate array words until the next twist; the selector cases differ only in
index `n + 1`. These hashes use eight-byte slots with zero upper halves.

### Recovery from raw MT outputs

The tempering transform is bijective. A practical inverse, with every
intermediate constrained to 32 bits, is:

```text
undo_right(y, shift):
    x = y
    repeat x = y ^ (x >> shift) until x is unchanged
    return x

undo_left(y, shift, mask):
    x = y
    repeat x = y ^ ((x << shift) & mask) until x is unchanged
    return x

untemper(y):
    y = undo_right(y, 18)
    y = undo_left(y, 15, 0xEFC60000)
    y = undo_left(y, 7,  0x9D2C5680)
    y = undo_right(y, 11)
    return y
```

For a capture aligned to MT index zero, untempering 624 consecutive complete
outputs reconstructs all 624 post-twist state words. Store each recovered word
in the low half of its eight-byte slot, zero the upper half, and set the index to
624 to reproduce the state immediately after that capture; the next core call
twists and emits the 625th output. In the clean fixed sequence, untempering
first output `0x889C77E9` gives state word `0x2B577921`; all 624 recovered
slots hash to the documented post-twist SHA-256, and the predicted next output
is `0x9705D2ED`.

Alignment matters for reconstructing the original physical array and index.
A 624-word capture beginning at a nonzero index straddles two resident twisted
arrays, so copying untempered words in capture order does not recreate those
same physical bytes. It does, however, form an equivalent predictive rolling
state: set its index to 624, then the recovered core predicts the next word
and following uninterrupted outputs without knowing the original index.
The distinction is physical state identity versus future output identity.

This follows from the sequential twist recurrence in `prng_next`. For the untempered stream `X`, the next word is

```text
X[k+624] = X[k+397]
           ^ ((X[k] & 0x80000000 | X[k+1] & 0x7FFFFFFF) >> 1)
           ^ ((X[k+1] & 1) ? 0x9908B0DF : 0)
```

The second twist loop reads already replaced slots, and the final word reads
the updated slot zero. Thus a window of 624 consecutive untempered words
supplies the same recurrence even when its start differs from the resident
array boundary. Representative vectors from the fixed bootstrap are:

| First captured output index | First predicted output after 624 captured words |
| ---: | --- |
| 0 | `9705D2ED` |
| 1 | `B115896D` |
| 31 | `08F3A452` |
| 227 | `1AC8818D` |
| 397 | `3556C522` |
| 623 | `8C4AB9A1` |

The capture must contain consecutive complete core outputs, with no missing
draws or coordinated reset. `rng_low31`, bounded results, and float
wrappers discard information; the recovery above requires complete 32-bit
outputs such as those returned by `effect_context_bit` or the core.


### MT wrappers

The shared output contracts are:

| Function | Proven operation | MT words consumed |
| --- | --- | ---: |
| `rng_set_tag(uint32 value)` | Store only to `rng_current_tag`; this is a tag setter, not an immediate MT seed routine. | 0 |
| `rng_low31()` | `prng_next() & 0x7FFFFFFF`; result is `0..0x7FFFFFFF`. | 1 |
| `effect_context_bit()` | Return the complete 32-bit MT bit pattern. | 1 |
| `prng_inclusive(int32 bound)` | Let `m = abs(bound)` with 32-bit negation; return the unsigned remainder `uint32(word ^ 0x80000000) % (m + 1)`. For ordinary nonnegative input the range is inclusive `0..bound`. | 1, including when `bound == 0` |
| `rng_signed_half_unit()` | `float(int32(word)) / 4294967296.0f`; a signed half-unit result, not a `[0,1)` result. | 1 |
| `rng_signed_scaled(float scale)` | If `scale == 0`, return positive zero. Otherwise return `float((double)scale * ((double)(int32(word)) / 2147483648.0))`. | 0 for either signed zero; otherwise 1 |
| `rng_central_band(float A, float B)` | Signed scaled draw with a conditional central-band remap described below. | 0 when `A == 0`; otherwise 1 or 2 |

The recovered resident and BTL consumers use this shared wrapper surface.

`prng_inclusive` is a plain modulo reduction. The `^ 0x80000000` is a
permutation of all 32-bit words and does not remove modulo bias; the result is
unbiased only when `abs(bound) + 1` divides `2^32`.

More exactly, for `q = abs(bound) + 1`, let
`base = floor(2^32 / q)` and `extra = 2^32 mod q`. Results `0` through
`extra - 1` each have `base + 1` preimages; the remaining results each have
`base`. Thus bounds `1`, `3`, `7`, and any other `2^k - 1` are exact, while
bound `2` gives result zero one additional preimage out of `2^32`.
Negative inputs other than `INT32_MIN` behave like their positive magnitude.
For `INT32_MIN`, word-sized negation wraps to `0x80000000`, so
the divisor is `0x80000001` and the returned range is `0..0x80000000`; no
possible signed 32-bit input produces a zero divisor.


### EE hardware conversion and software packing

The EE FPU rounds toward zero (FCR31 low bits hardwired 01), treats exponent
255 as finite and exponent zero as zero, and has no IEEE NaN/infinity/denormal
semantics. Missing guard/round/sticky bits can change arithmetic's least
significant bit relative to host IEEE truncation.
[EE Core User's Manual v6.0, sections 8.1, 8.7 and 8.8](https://docs.alexrp.com/mips/ee.pdf#page=156).

Hardware conversion maps INT32_MAX to 2^31-128 (`0x4EFFFFFF`).
The signed-half-unit quotient is `0.5-2^-25` (`0x3EFFFFFF`), with
negative endpoint -0.5; LCG /2^31 has positive endpoint
`1-2^-24` (`0x3F7FFFFF`). Conversion cannot round them up to 0.5 or 1.
These are derived endpoints, not a separate divider-bit measurement.

Scaled MT wrappers use software packing: normal double-to-float conversion
discards 29 fraction bits; the working double packer discards eight, with no
rounding increment/carry. Exponents below -1022 (double) or -126 (float)
flush to signed zero. FCR31 does not participate. Positive normal scale has
nominal support [-scale,scale): INT32_MIN reaches -scale, truncation cannot
raise an interior value to +scale, and small magnitudes can flush. The central
remap's later hardware arithmetic still needs the EE qualification.

EE `cvt.w.s` also converts toward zero, unlike generic MIPS with that
instruction name.
[EE Core Instruction Set Manual v6.0, p. 356](https://docs.alexrp.com/mips/ee_insns.pdf#page=356).

### Central-band remap

Zero A makes `rng_central_band(A, B)` return positive zero without a draw.
For ordinary nonnegative finite bounds, it starts with a signed-scaled draw
using A. A result outside the central interval is retained; an interior result
is remapped to the same sign's band between A and B. A zero remap width
suppresses the second draw.

For ordinary nonnegative bounds whose midpoint and halfwidth calculations
remain in range, the function chooses a sign and a magnitude between `A` and
`B`; the argument order changes how it gets there:

- If `0 < B < A`, a first value already outside `(-B, B)` is retained;
  otherwise it is remapped on the same sign side. Nominal implementation
  support is `[-A, -B]` union `[B, A)`, and consumption is one or two words.
- If `0 < A < B`, no first value can reach magnitude `B`. The first draw only
  chooses the sign, `halfwidth` is negative, and a mandatory second draw maps
  into nominal support `(-B, -A]` union `(A, B]`. Consumption is exactly two
  words.
- If `A == B != 0`, an interior first result collapses to the same-sign
  endpoint and `halfwidth == 0` suppresses the second draw. If `B == 0` and
  `A != 0`, the first signed-scaled result is returned directly. Both cases
  consume one word.

For unequal positive bounds in an ideal continuous model with independent
uniform draws, the result is uniform across the two signed bands between them.
In the `B < A` case, each
retained outer value starts with density `1 / (2A)` and the remapped
same-sign central mass supplies the balance; in the `B > A` case, each sign
has probability one half and the mandatory second draw is uniform across that
side's band. Finite integer inputs and float rounding make the implementation
a discrete approximation and can alter endpoint inclusion.

Caller values include ordinary, reversed, equal and table-selected bounds:

| A | B | Draw behavior |
| ---: | ---: | --- |
| 25 | 10 | One or two |
| 10 | 25 | Two |
| 25 | 25 | One, endpoint |
| 0.18 | 0.25 | Two |
| 13 | 17 | Two |
| 55 | 70 | Two |
| 3.5 | 5.5 | Two |
| binary32 pi | 0.10471976 | One or two |
| 0.95 or 1.25 | paired 0.75 or 1.05 | One or two |
| 25 | 30 | Two |
| 60 | 70 | Two |

Decimal spellings round-trip to the loaded binary32 values. Negative bounds
and extreme exponent patterns have no assigned range interpretation;
EE comparisons and software packing do not establish IEEE exceptional-value
semantics.


## 64-bit LCG stream

`lcg_seed(seed)` and `prng_u32()` form a separate seed/output pair.

```text
lcg_seed(seed):
    rng_lcg_state = uint32(seed)

prng_u32():
    rng_lcg_state = rng_lcg_state * 0x5851F42D4C957F2D + 1  // modulo 2^64
    return (rng_lcg_state >> 32) & 0x7FFFFFFF
```

`prng_u32` always advances and returns 0 through `0x7FFFFFFF`.

The LCG transition has full period `2^64`: its increment is odd and its
multiplier is congruent to 1 modulo 4, satisfying the full-period conditions
for a power-of-two modulus. The multiplier's inverse modulo `2^64` is
`0xC097EF87329E28A5`, so a state can be rewound exactly:

```text
previous = (next - 1) * 0xC097EF87329E28A5  // modulo 2^64
```

Multiplying the recovered multiplier and inverse modulo `2^64` gives 1, and
rewinding first state `0x71370215ED71FD01` gives seed `0x0000000000001100`.
The exposed result discards the low 32 state bits and the top bit of the high
word, so exactly `2^33` states share any one exposed value; an output
alone does not identify the state needed for rewind.

Arbitrary draw positions can be reached in logarithmic time by exponentiating
the affine transition. All operations below are modulo `2^64`:

```text
advance(state, count, cur_mul, cur_add):
    acc_mul = 1
    acc_add = 0
    while count != 0:
        if count & 1:
            acc_add = acc_add * cur_mul + cur_add
            acc_mul = acc_mul * cur_mul
        cur_add = (cur_mul + 1) * cur_add
        cur_mul = cur_mul * cur_mul
        count >>= 1
    return acc_mul * state + acc_add
```

For forward skips, initialize `cur_mul = 0x5851F42D4C957F2D` and
`cur_add = 1`. For backward skips, use inverse transition multiplier
`0xC097EF87329E28A5` and addend `0x3F681078CD61D75B` (the two's-complement
value of the negated inverse). As a validation vector, advancing seed
`0x1100` by 1,000 transitions yields state `0xF57A15AC5E49B078`; applying the
backward form for 1,000 transitions returns exactly to `0x1100`.


### Tone-shade animator timing is not another seed

`tone_shade_random_construct` builds an eight-byte
`ToneShadeRandomAnimator`, original class `ccToneShadeAnimRandom`, with
counter zero and period two. Its vtable names the update at `0x0018F410`;
construction performs no RNG work.

`tone_shade_random_update` increments the unsigned16 counter, returning
without draws or writes while it is below period. Otherwise it resets the
counter, draws two consecutive LCG values before either store, and writes
their /2^31 floats to `ToneShadeRandomDestination.random_component0/1`.
The default alternates zero and two draws. Period zero/one would give two
per invocation; no writer of those values was established. This local timing
does not seed, rewind or use MT/persistent16.

`battle_create_graph` constructs it only on the null-allocation branch of
the 0x6C0-byte pause sequence: animator +0x68C, destination +0x650.
`tone_shade_destination_initialize` clears the two destination values.
Ownership, publication, teardown and an independent non-RNG destination writer
belong to [Battle lifecycle](../gameplay/session/pause_and_replay.md#tone-shade-destination-block).

Animator dispatch, nondefault period writers and other destination producers
remain unresolved; adjusted pointers, bulk stores and generic virtual dispatch
are not excluded.

## Persistent 16-bit stream

`rng_persistent16_next` updates the halfword `rng_persistent16_state`:

```text
x = ((state ^ 0x1100) - 0x6553) & 0xFFFF
state = rol16(x, 2)
return sign_extend16(state)
```

There is no resident setter/reset, and this routine has the only direct state
accesses. The known effect consumers mask its low three bits, redundantly apply
`integer_selector_lookup` (integer absolute value), negate them, and store
0..-7 as `WrappedScenePlayback.signed_offset`.

### Allocation gates and a consumed but overwritten MT result

| Routine | Gate / completed attempts | Direct per-object calls |
| --- | --- | --- |
| `effect_construct_twelve_selector` | Resolved selector zero; twelve attempts; null allocation skips draws | Raw MT 1, scaled 4, central 4, persistent16 1 |
| `effect_construct_twelve_sized` | Twelve attempts; null allocation skips draws | Raw MT 1, scaled 4, central 3, persistent16 1 |
| `effect_construct_twelve_unchecked` | Twelve iterations without a pre-draw allocator gate | Raw MT 1, scaled 4, central 3, persistent16 1 |

The first two advance persistent16 s times for s successful allocations,
0<=s<=12; the third advances twelve times if it completes. None of these
direct sequences uses the LCG. Nested work is outside those counts.

The extra central(2,0.25)*size X value in
`effect_construct_twelve_selector` is cleared before any read or call.
Its result is lost but its one/two MT draws still matter to stream alignment.

`effect_sized_route` invokes the sized producer.
For slots zero/one it requires object word +0x68 bit zero clear and passes
1.5; another slot can use `effect_selector_route`. Its classifier meaning
remains open. Size 1.5 becomes 5.25 with coefficient clamped to 1.25.
Exact floats 3.75 and 12.5 convert to divisor three/base twelve, giving
12..14 after absolute signed remainder. Central(5,-4.25) returns its first
draw; only central(10,2.5) and central(64,16) can draw again. A successful
allocation consumes 8..10 MT words and one persistent16 advance; twelve
successes consume 96..120 MT and twelve persistent16. The bounds do not
assert every total is feasible.

Every operation in the 16-bit update is bijective. One step can be reversed
without a lookup table:

```text
previous = (((ror16(next, 2) + 0x6553) & 0xFFFF) ^ 0x1100)
```

Exhaustively applying the exact recurrence to all 65,536 halfword values gives
11 disjoint cycles with lengths:

```text
43951, 13698, 5447, 1089, 844, 435, 64, 3, 3, 1, 1
```

Using each cycle's smallest state as a reproducible representative, the
length/representative pairs are:

```text
43951/0000  13698/0001  5447/000B  1089/000F  844/0049  435/00BE
64/01A7     3/1FAB      3/51F4     1/9DC4     1/F319
```

Cold state zero is in the 43,951-state cycle. The two fixed points are
`0x9DC4` and `0xF319`. Therefore a cold process never reaches the other ten
cycles through ordinary calls. Any starting halfword in a different cycle
remains there. This cycle result and the inverse were verified
over all 65,536 inputs from the recovered recurrence; they are derived static
results rather than live observations.

The three-bit value actually used by the identified effect callers also has
measurable structure. Over the complete cold cycle, counts for masked results
0 through 7 are respectively:

```text
5492, 5488, 5479, 5532, 5532, 5522, 5457, 5449
```

The masked sequence itself has period 43,951, but only 32 of the 64 possible
adjacent result pairs occur. If `r[t] = state[t] & 7`, then
`bit2(r[t+1]) = 1 - bit0(r[t])`: subtracting odd constant `0x6553` complements
the low bit, and the rotate-left-by-two moves that bit to bit 2. Consecutive
effect-side results are therefore deterministically correlated even though all
eight values occur. The counts and adjacent-pair constraint were checked over
the full cold cycle.


## Direct BTL imports

Recovered BTL consumers call the resident MT wrappers and LCG output.
No BTL seed/reset or local RNG state was identified. Computed targets remain
open; a recovered entry edge alone does not establish its internal branches.

Raw callers use unsigned XOR reduction, parity, folded signed remainder and
dynamic unsigned remainder. Nonzero dynamic divisors remain an unresolved
precondition. Positive literal bounded calls consume one word; dynamic bounds
can also be zero or negative. Dynamic scaled values can be zero, suppressing
the draw, and their positivity is not generally established.

Two coherent LCG angle blocks have no recovered incoming edge. They compute
((output>>3)&0x1800)*pi/32768 into two owner angles, but their invocation
is unproven. Their presence does not establish gameplay consumption.

### Masked-selector construction family and registration gates

`masked_effect_construct_fifty` (`0x007F8F80`) and
`masked_effect_construct_single` (`0x007F93A0`) allocate 0x210-byte
`ccEffDrawObj` objects through `wrapped_resource_construct`, then call
`effect_register(object,0)`. An absent `effect_manager_global` returns
zero; `effect_manager_insert` otherwise admits into one of up to 0x300 slots,
returning one on insertion or zero if full. Registration return gates draws.
The wrapper still writes object fields, so this does not prove safe null
allocation recovery.

| Producer | Admitted direct sequence | Completed-body MT bound |
| --- | --- | --- |
| Fifty attempts | Raw abs(signed%5), central(pi,0.10471976) | 2s..3s, 0<=s<=50 |
| Single attempt | Same, then scaled bits 3F060B41 and 3F060AA4 | 0 rejected; 4..5 admitted |

Neither direct sequence uses LCG/persistent16; nested helpers and later updates
are separate. The fifty-attempt producer subsequently calls
`effect_construct_record_transform` three times using
`masked_effect_transform_records`: (1.5,1.5,1,1), (1,1,2,1),
(0.2,0.2,3,1), with the remaining 32 copied bytes zero. That helper has no
direct documented RNG import.

| Selector | First dispatcher | Second dispatcher |
| --- | --- | --- |
| F0F0F0 | First emitter then fifty attempts | Third emitter |
| 202020, E0A000, E0E000 | Second emitter | Fourth emitter |
| Other | Fifty attempts | Single attempt |

The four emitter alternatives contain no direct documented RNG import;
nested/later work belongs to [Particle runtime](rendering/particle_runtime.md).
`masked_effect_selector_get` returns
`environment_published_primitive_flags & 0x00F0F0F0`.
`masked_effect_begin` retains it as
`RngMaskedEffectOwner.retained_selector` after a float comparison other than
-1, then invokes `masked_effect_dispatch_first`.
`masked_effect_update` later passes the retained value to
`masked_effect_dispatch_second`; calls do not reread the selector.

Broader owner lifecycle, frequency and player-facing selector names remain
open.

### Fixed pairs in a two-record producer

`rng_pair_record_produce` (`0x0083D860`) stores
`RngPairOwner.record_count`; a missing records array allocates
count*0x100+0x10 and constructs 0x100-byte records, otherwise the array is
reused. `rng_pair_owner_initialize` clears its pointer/count for fresh use.

Each iteration draws inclusive(1) for a resource pointer, separately applies
the loop-indexed `rng_central_pairs`, converts the result and stores
`RngPairRecord.remapped_value`:

| Index | A bits / value | B bits / value | Central words |
| ---: | --- | --- | ---: |
| 0 | 3F733333 / 0.95 | 3F400000 / 0.75 | 1..2 |
| 1 | 3FA00000 / 1.25 | 3F866666 / 1.05 | 1..2 |

`rng_pair_record_route` supplies count two, so completion consumes
4..6 MT words in that pair order. It requires owner word +0x8 zero and signed
word +0x4 converted to float equal to 5, then attempts three 0xB50 helper
allocations. Null allocation skips production; s completed producers,
0<=s<=3, contribute 4s..6s words. Other counts, computed calls, broader
lifecycle and gameplay meaning remain open.

### Guarded dynamic scales in a type-specific callback

`skill_szn000_random_position` (`0x00834FA0`) is slot +0x8C of
`skill_szn000_random_vtable`, internal type ccSkillSZN000. The table is
stored in `CollisionSkillPrimary.interface`. No player-facing type/move name is assigned.

Its special branch requires `RngPositionReceiver.state == 10` and
`phase == 2`, updates its counter/action record, then joins the shared
random-position operation. The incoming third argument is unused.

A nonzero model plus global `battle_hub` is valid
(`downed_override_allowed`); caller `model_valid` bytes gate the query.
Missing gates supply positive-zero scale. With model extents E8/E4 and scale:

```text
X  = valid(target)   ? target.model.x_extent * (0.8 * target.model.scale) : +0
Zt = valid(target)   ? target.model.z_extent * (0.3 * target.model.scale) : +0
Zc = valid(receiver) ? receiver.model.z_extent * (0.5 * receiver.model.scale) : +0
position = target.position
position.x += signed_scaled(X)
position.z += signed_scaled(Zc + Zt)
b0 = abs(int32(raw_mt()) % 2)
b1 = abs(int32(raw_mt()) % 2)
if receiver.visual_blocked == 0:
    emit(position, b1, b0 != 0, 2, 0)
```

The coefficient*model-scale multiplication precedes extent multiplication
(`entity_scaled_width` and `entity_scaled_height`). No positivity/nonzero is established.
Each completion draws exactly two raw words plus zero/one/two scaled words.
The visual gate is after all draws and cannot save them; nested emission
is separate.

`skill_primary_update_descriptor` requires `primary_header.flags & 1`,
then calls this slot through branches for `InteractionRecord.update_form` zero
or one, passing the receiver, `primary_header.context`, the embedded
`primary_header`, and `primary_header.record`.
Further eligibility/response gates remain with
[Character action callbacks](../gameplay/characters/character_action_callbacks.md)
and [Hit response](../gameplay/combat/hit_response.md). The recovered indirect
users are not an exhaustive callback census.
The neighboring table uses `skill_random_position_noop` (`0x007895F0`);
this randomness is a type-specific override, not every receiver's behavior.

### LCG-selected 42-vector table

`projectile_random_vectors` (`0x003FBC80`) has 42 float4s, 672 bytes,
SHA-256 `692AEB37982E021CA8D08AA14506C723B44948FDC3C6CA8F0BAD927CCEF82C34`.
All xyz triples are distinct, fourth word is 1, and there are 21 exact
antipodal pairs. Norms are 1.414198183637919..1.414214015007019,
near sqrt(2); the game's name/role is not established.

One selector uses output%42, scales xyz by 4, then adds/normalizes. Five use
(output>>3)%42, scale xyzw by 7.5 and store object +0xB0. Their later uses
differ: clearing +0xB4/+0xBC; retaining the whole vector; clearing +0xB4 then
adding; clearing +0xB4, adding and normalizing xyz to +0xF0; or adding before
clearing the resulting y word. Per-site annotation labels retain that mapping.

For output%42, 2^31 = 42*51130563+2: indices zero/one have one extra input.
For shifted output, 2^28 = 42*6391320+16: indices 0..15 have one extra
shifted input. The full LCG cycle exposes every 31-bit output equally often,
so these are exact full-period multiplicities.

`rng_half_unit_object_initialize`, `rng_half_unit_base_initialize`,
`rng_half_unit_pair_initialize`, and `rng_half_unit_size_initialize` use the
signed-half-unit result in initialization formulas.
Caller formulas are base+width*(r+1)*0.5, (r+1)*5, unbased width*(r+1)*0.5,
and size*0.6+size*(r+1)*0.19999999. Their nominal coefficients span
[0.25,0.75), [2.5,7.5), and approximately [0.7,0.9).
The unusual signed-half-unit semantics fit these formulas; object gameplay
roles remain unassigned.

## Representative non-damage MT consumers

Loading resource selection is implemented by `loading_choose_random_asset`
and `loading_load_selected_asset`, using low31 modulo 3/6/7.
`render_transient_jitter` adds two scaled(3) draws independently to render
coordinates +0x50/+0x54 while its transient counter is active.
`query_process_active_pairs` uses low31&1 to choose -1/+1 only when
spatial-overlap separation length is exactly zero. The shuffled-ID and effect
families below, plus the tone-shade LCG consumer, establish use of all three
streams outside damage.

## Caller reductions and conditional tie selection

These reductions act on a shared MT word. Counts enumerate 2^32 possible
word patterns; they do not assert invocation frequency or independent draws.

### Unsigned XOR reduction and folded signed remainder

`ai_select_action_record` selects
unsigned(word^0x80000000)%eligible_count: one final raw draw for any nonempty
list, including singleton; empty returns -1 before it. Filtering can draw
separately and belongs to [Battle AI](../gameplay/session/battle_ai.md#action-record-selection-and-direct-queues).
Other callers use abs(signed(word)%5)+55 or abs(signed(word)%5); that is neither
unsigned remainder nor absolute value before division.
`integer_selector_lookup` performs the fold.

Let `M = 2^31` and positive divisor `m <= M`. The exact preimage count of
folded result zero is
`floor((M - 1)/m) + 1 + floor(M/m)`. For `1 <= r < m`, its count is
`floor((M - 1 - r)/m) + 1 + floor((M - r)/m) + 1`. This follows by counting
nonnegative magnitudes `0..M-1` and negative magnitudes `1..M` separately;
the asymmetry comes from `INT32_MIN` having no positive counterpart.
For the proven divisor-five sites:

| Result `r` | Unsigned XOR remainder by five | Absolute signed remainder by five |
| ---: | ---: | ---: |
| 0 | 858,993,460 | 858,993,459 |
| 1 | 858,993,459 | 858,993,460 |
| 2 | 858,993,459 | 858,993,460 |
| 3 | 858,993,459 | 858,993,459 |
| 4 | 858,993,459 | 858,993,458 |

Both columns sum to `2^32`. Even their per-result bias differs. Divisor two
is a useful special case: `abs(int32(word) % 2)`, `word & 1`, and the
bounded wrapper with argument one all give the same low bit and have
`2^31` preimages per result. This explains their equivalence at the binary
choice sites without generalizing it to divisors three or five.


### Exact-distance two-side tie

`rng_two_side_distance_select` (`0x00709FD0`) compares computed
binary32 distances to the two primary fighters using `vector_distance`.
Unequal distances choose side zero if the first is smaller, otherwise one,
without a draw. Exact equality consumes inclusive(1) once and returns side
zero for result one, side one for result zero.

This is one binary tie, not a reservoir or pairwise-selection loop.
Its recovered caller belongs to the
[separate side-index selector](../gameplay/combat/target_selection.md#separate-side-index-eligibility-selector).
Null fighters skip their position copy but both distances still read the
stack vectors, so no meaningful null-fighter result is established.
No IEEE unordered/NaN interpretation is applied.

### Shuffled IDs versus rejection and separate byte selection

`rng_shuffle_accepted_ids` scans 1..93 through
`roster_character_valid` and `roster_secondary_filter`; exactly 74 remain
([Character IDs](../gameplay/characters/character_ids.md#selector-id-filters)).
It draws inclusive bounds 73..0, emits each accepted ID once, and swaps the
final candidate into the chosen slot. Completion consumes exactly 74 words,
including bound zero, with no retries or terminator shuffle.
Both leading `RngShuffledIds` halfwords become last index 73.
`rng_shuffle_allocate` allocates/clears 0xC4
only for numeric mode four; its player-facing name is unassigned.

| `support_config_pair_side1` source | Direct MT draws |
| --- | --- |
| Null manager | Zero |
| Mode five, nonnull record, indexed triplet in range | Zero, ID and byte from record |
| Existing shuffled list | One, list ID then separate low31%24 byte |
| No list, outside triplet branch | At least two: low31%94 until filters pass, then separate %24 byte |

The rejection loop has no iteration cap; each rejected ID adds one draw.
List index beyond last wraps modulo(last+1), enabling reuse without
regeneration; the separate attribute draw still advances the stream.
Its byte destinations are manager +0x98/+0x9A. Prior generation and nested
work are outside these body counts.

Modulo94 has 2^31 = 94*22845570+68; residues 0..67 have one extra input.
The accepted set has 50 in that group and 24 in 68..93, so filtering retains
the modulo weighting. This is input multiplicity, not an independent-trials
model of rejection timing.

## Deterministic state implications

The following consequences follow directly from the state and call graph:

- Resetting with tag `t` produces only 32 possible post-reset MT positions,
  selected by `t & 31`. In contrast, the LCG is seeded from all 32 bits of
  `t`.
- For example, tags `0x00000000` and `0x00001100` produce identical MT and
  16-bit reset behavior because both select `n = 0`, but they leave different
  LCG seeds (`0` and `0x1100`).
- Resetting does not make the 16-bit stream a pure function of `t`; its result
  also depends on the pre-reset halfword. A cold process supplies zero, but a
  later reset advances the existing state.
- Reproducing generator outputs across a reset requires the MT array and index,
  `rng_current_tag` for the future reset tag, LCG 64-bit word `rng_lcg_state`, and
  halfword `rng_persistent16_state`. `rng_previous_tag` is useful for observation
  but is not read by resident code.
- A later `resident_flow_dispatch` setter/reset event also depends on the `RngEngineRoot.update_counter`. That upstream field replaces
  `rng_current_tag` immediately before the reset and therefore supplies both the
  next full LCG seed and the MT low-five-bit selector.
- Resident and BTL callers share the same MT and LCG states. A draw in a
  loading, tone-shade, camera-labelled, or effect path advances the sequence
  seen by every later consumer of that stream.
- Control flow affects MT alignment: zero-scale `rng_signed_scaled` consumes no
  word; `rng_central_band` consumes zero, one, or two; bounded integer calls always
  consume one even when the bound is zero.
- The shared states alone do not determine future call timing. Caller-owned
  counters, branch inputs, allocation results and prior shuffled lists can
  change the order and number of draws.

Derived static vectors for the clean algorithms are:

| Situation | Expected value |
| --- | --- |
| First five fixed-bootstrap MT outputs | `889C77E9`, `C8C10059`, `4F014569`, `3B11BCC1`, `0E34B264` |
| Clean-image tag before any setter | `00001100` (`n = 0`) |
| Tag stored when `rng_initialize` receives `00001100` | `889C77E9` |
| Next public MT word in that same case | `C8C10059` |
| LCG state after first advance from seed `0x1100` | `71370215ED71FD01` |
| Corresponding first LCG return | `71370215` |
| LCG first state / return after an update-counter seed of zero | `0000000000000001` / `00000000` |
| First four 16-bit states from cold zero | `AEB6`, `698D`, `4CE8`, `E257` |

These vectors were calculated from the exact static recurrences and constants;
they have not yet been checked against a live trace.

### Complete cold reset map

For any incoming tag with low five bits `n`, the fixed MT stream discards
outputs `0..n-1`, stores output `n` as `rng_current_tag`, and leaves output
`n + 1` for the next public draw. Starting the separate 16-bit stream from its
cold zero value gives this complete reset map. The MT index after initialization
is also `n + 1`.

| `n` | Retained tag `MT[n]` | Next public `MT[n+1]` | Cold 16-bit state after `n` steps |
| ---: | ---: | ---: | ---: |
| 0 | `889C77E9` | `C8C10059` | `0000` |
| 1 | `C8C10059` | `4F014569` | `AEB6` |
| 2 | `4F014569` | `3B11BCC1` | `698D` |
| 3 | `3B11BCC1` | `0E34B264` | `4CE8` |
| 4 | `0E34B264` | `AF349767` | `E257` |
| 5 | `AF349767` | `145102A9` | `3812` |
| 6 | `145102A9` | `7CABC042` | `0EFF` |
| 7 | `7CABC042` | `31EAE5A7` | `EAB2` |
| 8 | `31EAE5A7` | `0F96266C` | `597E` |
| 9 | `0F96266C` | `0EADC242` | `8CAF` |
| 10 | `0EADC242` | `A33A0F84` | `E170` |
| 11 | `A33A0F84` | `BC2AE9C5` | `2C76` |
| 12 | `BC2AE9C5` | `EC3B11E1` | `608F` |
| 13 | `EC3B11E1` | `DF4B14E3` | `30F0` |
| 14 | `DF4B14E3` | `03777F97` | `F276` |
| 15 | `03777F97` | `B845C23A` | `F88D` |
| 16 | `B845C23A` | `171F18C0` | `10EA` |
| 17 | `171F18C0` | `D0089F8C` | `725E` |
| 18 | `D0089F8C` | `17AA3BEE` | `F82F` |
| 19 | `17AA3BEE` | `DFFC5D7A` | `0F72` |
| 20 | `DFFC5D7A` | `ED4F076E` | `E47E` |
| 21 | `ED4F076E` | `1B0B50C8` | `40AE` |
| 22 | `1B0B50C8` | `1CD2D1B6` | `B16F` |
| 23 | `1CD2D1B6` | `891633C1` | `EC70` |
| 24 | `891633C1` | `00ECAD12` | `6076` |
| 25 | `00ECAD12` | `C2AC3908` | `308C` |
| 26 | `C2AC3908` | `169EC52B` | `F0E6` |
| 27 | `169EC52B` | `6F678F68` | `F24D` |
| 28 | `6F678F68` | `EC5B1DA4` | `F7E9` |
| 29 | `EC5B1DA4` | `65B766B7` | `065A` |
| 30 | `65B766B7` | `E7043078` | `C81E` |
| 31 | `E7043078` | `267025AE` | `CF2D` |

Only the MT columns are functions of `n` alone. The LCG state after reset is
the complete incoming 32-bit tag, and a non-cold 16-bit column must be obtained
by advancing that run's existing halfword `n` times.

### Repeated direct-reset attractors

Ordinary MT, LCG and 16-bit draws do not change the retained tag. Therefore, if the direct `manager_initialize` reset recurs
without the external counter setter, the next low-five-bit selector is exactly
`MT[n] & 31` from the table above.

The resulting 32-node map has only two attractors:

```text
4 -> 4
2 -> 9 -> 12 -> 5 -> 7 -> 2
```

Starting selectors `4`, `11`, `27`, and `29` reach the fixed point; all other
selectors reach the five-cycle within at most six direct resets. Clean selector
zero goes to 9 on its first reset. The corresponding retained full tag at the
fixed point is `0E34B264`. Around the five-cycle, the full retained tags are:

```text
n=2  -> 4F014569 -> next n=9
n=9  -> 0F96266C -> next n=12
n=12 -> BC2AE9C5 -> next n=5
n=5  -> AF349767 -> next n=7
n=7  -> 7CABC042 -> next n=2
```

This short attractor applies to the reset selector, retained tag, MT position,
and newly seeded LCG. It does not by itself make the complete state repeat:
the 16-bit stream is advanced rather than reset. In a cold-start sequence of
these resets with no other `rng_persistent16_next` calls, the five-cycle advances that stream
by `9 + 12 + 5 + 7 + 2 = 35` steps per lap. Since 35 is coprime to the cold
cycle length 43,951, the complete reset-state period is `5 * 43951 = 219755`
resets after entering the attractor. On the fixed `n=4` branch it is 43,951
resets. Intervening effect-side 16-bit calls change those complete-state periods
but not the low-tag attractor.


## Confidence and useful negative results

Generator constants, widths, clean values, wrapper reductions, draw counts,
reset relationships and derived recurrences are established by static evidence.
Tables without identified gameplay names are limited to indexing/store facts.

Open matters are caller frequency/order and internal branch feasibility,
animator dispatch and nondefault period writers, exact hardware arithmetic
low bits, most unnamed BTL consumers' gameplay roles, and a complete catalogue
of unrelated caller-owned recurrences. The recovered BTL imports have static
entry edges; those do not resolve these uncertainties.

The tag setter is not an immediate reseed; the snapshot has no resident
reader; persistent16 has no resident reset; the signed-half-unit wrapper has
no resident caller; and BTL has no identified direct state access or direct/
identified indirect seed/reset/core import.
