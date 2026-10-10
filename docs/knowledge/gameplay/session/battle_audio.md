# Battle audio and cue scheduling

## Research coverage

Established in retail NA2 (`SLPS-25837`): stage-dependent battle music,
EE cue selection, queues, transport, bank loading, action/surface scheduling,
selected cinematic bindings, and guide ownership/lifetime. Compact fighter
commands use SNDDATA headers/sample data through the inspected IOP load and
packet worker, separately from PLVOICE. The embedded synthesizer establishes
compact program/key/velocity lookup through sample sets and sample records to
VAG/SPU offsets. Static compact admission, priority/stealing, release and
per-update ordering are established in the shared synthesizer and SNDBASE
timer/worker path.
Open: live IOP relocation bases, audible identity and observed timing,
complete resources and indirect reachability, and initial guide payload/state
writers. NUN3 and NUN4 voice contracts and donor character voices are in
[NUN3 and NUN4 characters](../characters/nun3_nun4_characters.md).

Routines, structures and data are named in `@annotations/NA2` and `shared`;
their comments carry per-routine detail. Numeric code/data citations below
are live EE addresses. IOP symbols are qualified by program because their
imported zero-based values have no established live relocation base; see
[Retail game file identities](../../game/files/file_identities.md).

## Battle music selection

Free Battle and Practice share the resident battle session. Its
`manager_update_substate_four` (`0x001EF9C0`) requests frontend command 8
when inner state 3 enters active state 4 with no recorded match result.
`audio_frontend_battle_music` (`0x001D3880`) forwards music preset 5 to
`audio_request_music_preset` (`0x001D9A30`). The preset branch
`audio_music_preset_battle` (`0x001D3B48`) requires a battle manager and
selects SOUND descriptor 0, a member number, and stereo channel 0.

The member selection has two paths:

- A nonnegative `AudioRequestContext.battle_music_override` at `+0x00`
  supplies the member directly.
- A negative override reads the manager's **signed raw load-slot byte**
  at `+0x98` and directly indexes resident `stage_music_tracks`
  (`0x003FE470`). It does not convert to a logical stage ID.

`audio_request_context_initialize` (`0x001D24C0`) sets the override to
`-1`. `audio_clear_battle_music_override` (`0x001D3DE0`) restores that
value, and `audio_get_battle_music_override` (`0x001D3E00`) reads it.
Control-dispatch selector 5 has a writer at
`audio_set_battle_music_override_case` (`0x001D3D20`), but the bounded
resident/BTL/ETC direct-call census found no caller of its dispatcher.
These paths establish a program-controlled override, not a player-facing
music setting. Neither selection path chooses by fighter or draws randomly.
The complete reachability of the override writer remains open.

The 24 normal raw slots select these members of `SOUND.AFS/000`:

| Raw slots | Members in slot order |
| --- | --- |
| 0..3 | 4, 14, 5, 6 |
| 4..7 | 12, 13, 18, 22 |
| 8..11 | 23, 19, 7, 15 |
| 12..15 | 24, 25, 26, 27 |
| 16..19 | 16, 17, 8, 9 |
| 20..23 | 10, 11, 20, 21 |

There is no slot bound in the preset branch. The next two contiguous words,
at `0x003FE4D0/0x003FE4D4`, contain 4/14, followed by two zero words.
The data annotation retains all 26 observed track words; the retail meaning
of the two extra words is unresolved. A raw-slot-24 read therefore obtains
member **4**, beyond the 24 normal-stage entries, rather than selecting a
fallback branch or rejecting the slot. Logical ID 25 has no effect on this
selector. A nonnegative override bypasses the slot table entirely.

`audio_select_music_track` (`0x001D9680`) suppresses an unchanged idle
selection and otherwise passes the descriptor's archive handle and member to
`audio_start_streamed_music` (`0x001D6CF0`) with mode 0. Stream inhibition
can reject the start after selection. Archive/codec and gain contracts belong
to [Audio and video replacement](../../game/files/audio_video_replacement.md#resident-menu-music-selection).
Member numbers identify files, not established musical titles.

## Fighter voice-event selection

`fighter_request_descriptor_event` selects an event through
`fighter_voice_event_list`, then dispatches its control by object or ID.
Event indices, control indices, program bytes and archive members are separate
values. The event path's action/state gates are annotated on the routine.

Events `0x18/0x19` share `Fighter.voice_event_cooldown`, initialized to zero
and set to `0x3C` by admitted requests. Eligible housekeeping decrements it
once before the positive-pause branch, without action-rate multiplication.
Its unit is a housekeeping call; wall-clock seconds are unestablished.

### Complete event-list coverage

The 93 pairs in `voice_event_pointer_pairs` select only `voice_events_base`,
`voice_events_110` and `voice_events_160`, each with 33 controls. The latter
two add 110/160 to every base slot. Complete identity assignments are
annotated on the table; the six alternate-selection identities are recorded
on `fighter_voice_event_list`. A stored alternate for ID 20 does not
establish reachability through that selector.

Event `0x20` resolves to disabled controls in all lists. Event `0x19` is
disabled only in the base list; controls 137/187 are enabled. This suppression
is independent of the cooldown.

`fighter_voice_pseudo_event` maps `-2/-3/-4` to groups `6..8`, `3..5`,
and `0..2`. Inclusive draw 3 suppresses the request, as does event `-1`.
`fighter_voice_control` bypasses event lists/cooldown but retains
object-versus-ID routing.

## Compact battle commands

Both voice dispatchers resolve `AudioControl` in `battle_voice_controls`.
Negative programs and fighter ID `0x27` suppress emission. Object routing
uses the fighter side and `battle_audio_suppressed`; ID routing compares
stored participants and alternates its selector when both IDs are equal.
An unmatched ID emits nothing.

Suppression also checks command-context availability, bank transactions and
the state-6/substate-zero cinematic flag. The retail state-3 branch requires
successive reads of the same substate to be nonpositive and at least 2,
without intervening yield/source update. With an unchanged source it cannot
suppress a request; this is not a normal substate `0..1` suppression window.

Program/channel, direction and scalar commands are appended through
`sound_append_short_command` and `sound_append_extended_command`.
Their annotations carry the two-, three-, five- and seven-byte encodings.
`sound_append_bytes` checks stream/capacity. Battle dispatchers ignore
failure, so capacity rejection is not retained for retry. EE encodings,
transport and [synthesizer decoding](#compact-program-to-vag-lookup) are established.

### Complete control-table census

`battle_voice_controls` has 202 records, 123 enabled and 79 disabled, all
using stream/channel zero. The complete constants, program range and default
distribution are annotated on the table. Repeated program bytes with different
defaults are distinct controls; a control index is not a clip number.

### Compact voice resource and lifecycle

`audio_setup_mode` (`0x001D3470`) obtains both selected participant IDs from
the battle manager and queues operation 3 for side 0, waits for it to finish,
then queues side 1 and waits again. It stores the IDs for later ID-based
dispatch only after both loads. `audio_service_bank_transaction`
(`0x001DA860`) routes that operation to `audio_load_character_bank`
(`0x001DB060`). Descriptor identities and exact checked file ranges belong to
[Compact fighter bank resources](../../game/character_assets.md#compact-fighter-bank-resources).

The loader allocates the selected header size in IOP memory and retains it in
`AudioCommandContext.player_allocations[side]`. RPC `0x9400` sends that pointer,
the bank file offset, header size, sample size, current SPU placement and
`audio_snddata_filename`. `shared:SNDBASE.IRX:sndbase_load_bank_disc` reads
the header and transfers the subsequent, `0x800`-aligned sample region to SPU
through `hsyn_voice_transfer`. Its return is transferred bytes; the EE waits
until it equals the requested sample byte count. The host-file branch
`sndbase_load_bank_host` uses the same header/sample split.

RPC `0x9052 + side` then supplies the IOP header pointer and SPU base to
`shared:SNDBASE.IRX:sndbase_bind_bank`. It invokes `hsyn_load` with bank 0 on
synth port 2 or 3. The EE configures that port, advances placement by sample
bytes plus `0x10`, resets auxiliary state and ends the transaction.
`audio_release_banks` (`0x001DB520`) requests stop and, when bank retention
is clear, frees positive IOP header allocations and restores initial placement.
That establishes header ownership and SPU placement reuse, without proving
hardware execution timing or every indirect bank writer.

`sound_task` (`0x001D2570`) obtains the two side DMA destinations from RPC
`0x8100` indices 1 and 2. `shared:SNDBASE.IRX:sndbase_packet_worker` copies
the submitted packets into the inputs used by synth ports 2 and 3 and calls
`hsyn_main`. The inspected compact selection, load, bind and packet chain
requests `SNDDATA.BIN`; it performs no PLVOICE archive-member lookup.
`audio_queue_player_voice` instead writes the separate streamed pending row.
`sound_rpc2_service` (`0x001D9930`) polls CRI mono/stereo activity; it neither
decodes these compact packets nor maps their program bytes to PLVOICE members.

For admitted requests with an out-of-range caller parameter, the checked
event-list/table rows produce these commands. Position can change direction
and scalar bytes; this table records the program and default parameter only.

| NA2 IDs / selected list | Event | Control | Program | FD `0x10` parameter low byte |
| --- | --- | ---: | ---: | ---: |
| 1, 57, 92, 93 / normal | `0` | 0 | 0 | `0x3C` |
| 1, 57, 92, 93 / normal | `0x18` | 26 | 26 | `0x3C` |
| 1 / alternate | `0` / `0x18` | 160 / 186 | 0 / 26 | `0x3E` |
| 57 / alternate | `0` / `0x18` | 110 / 136 | 0 / 26 | `0x3D` |

Sai/Sasuke select the base list in both pointer slots. Classic Naruto's
alternate requires effect `0x0E`, and Naruto's requires effect `0x39`.
Normal event `0x19` selects disabled control 27; the checked alternate lists
select enabled 187/137, program 27 with defaults `0x3E/0x3D`.
Event/cooldown admission still applies. These are exact emitted selectors,
not established spoken lines, sample IDs or guaranteed successful playback.

#### Embedded synthesizer images

`bootstrap_module_offsets` (`0x003FB890`), used by `iop_bootstrap_modules`
(`0x001BD0B0`), identifies these members of NA2's `MODULES/MODULES.BIN`.
Their ELF `.iopmod` names and `modmidi`/`modhsyn` export tables identify the
two modules. Separate shared MCP programs `MODMIDI.IRX` and `MODHSYN.IRX`
map their verified ELF images; `shared:/MODULES.BIN` maps the first, SIO2,
member. Hashes cover exactly the bootstrap-specified image bytes.

| Embedded identity | Source file offset | Image bytes | SHA-256 |
| --- | ---: | ---: | --- |
| `Midi_Sequencer_Module` / `modmidi` | `0x30000` | 21,941 | `C22DF1C868D4BAA4F51AB45E319E6B76FCAB7FE0BE7F0D5493A9F60285501489` |
| `SPU2_Synthesizer_Module` / `modhsyn` | `0x35800` | 60,957 | `E6B1520286B86CA22A99B8BA581B03B706678AAC8916AE95EE91A212E358599F` |

Both members have one ELF load segment starting at module-relative zero;
Ghidra maps the initialized sections and their uninitialized tails. This is
a clean file-to-module mapping, not a fixed live IOP address. The loader's
live relocation bases remain unresolved; all IOP references below use
qualified program/symbol names. The NUN3/NUN4 source containers and selected
members are byte-identical to the NA2 inputs.

`shared:MODHSYN.IRX:hsyn_export_table` identifies `hsyn_main`,
`hsyn_load_bank` and voice transfer at export ordinals 5/6/7, matching the
SNDBASE imports. `hsyn_main` reaches `hsyn_drain_port_packets`, which
reads each packet's payload at input `+8` and its byte length at `+4`, clears
the length and dispatches by port mode. Mode bit 0 clear selects the compact
decoder; set selects the separate scheduled decoder.
`shared:MODMIDI.IRX:midi_main` is the sequencer's export ordinal 5;
the checked compact packet worker invokes `hsyn_main` directly.

#### Compact program-to-VAG lookup

**Code observations:** `shared:MODHSYN.IRX:hsyn_load_bank` builds a
seven-word `HsynBankBinding`: Head, Prog, Sset, Smpl, Vagi, optional Setb,
and SPU base. Head is header `+0x10`; the five section offsets at Head
`+0x14..+0x24` are relative to the whole header. Bank index is distinct
from the EE NUN4 language-set selector. The per-channel bank byte selects
a binding row; the checked fighter binding installs bank zero.

`hsyn_decode_compact_packet` consumes `C0` as two bytes, `F9` as five
and `FD` as seven; incomplete commands return without dispatch.
`hsyn_dispatch_short_command` sends `C0 | channel` to
`hsyn_select_program`. The selector resolves the program's section-relative
offset and retains its program and bank pointers on that channel.
A missing offset or zero split count clears the selection.

The complete `FD 0x10` command is
`{FD, 10, channel, key, tag, velocity, trailing}`.
`hsyn_dispatch_extended_command` passes the seven-bit key, velocity and
tag to `hsyn_note_on`; zero velocity instead reaches `hsyn_note_off`.
The trailing byte is unused by this subcommand. Thus the EE caller/default
parameter is a **key selector**. The position-derived scalar supplies
**velocity**, which also gates sample selection; it is not only gain.
The checked battle dispatchers write tag zero.

`hsyn_note_on` performs this lookup, using the annotated serialized types:

| Stage | Checked fields and selection |
| --- | --- |
| Prog | Section `+0x0C` is the inclusive maximum index; offsets start at `+0x10` and are relative to that section. Program `+0` locates its split array relative to the program; byte `+4` is split count. |
| Program split | `HsynProgramSplit` stride `0x14`: ushort `+0` is Sset index; bytes `+2/+4`, masked with `0x7F`, bound the key inclusively. |
| Sset | Resolved section-relative record: bytes `+1/+2` bound velocity, byte `+3` counts sample indices, and ushort sample indices start at `+4`. |
| Smpl | Resolved section-relative record: ushort `+0` is Vagi index; bytes `+2/+4`, masked with `0x7F`, bound velocity inclusively. The checked records occupy `0x2A` bytes. |
| Vagi | Resolved section-relative record: uint32 `+0` is sample-region/SPU-relative start; ushort `+4` is sample rate; byte `+6` carries flags. The checked records occupy eight bytes. |

Each indexed section uses an inclusive maximum and `0xFFFFFFFF` holes.
The routine walks every matching split and sample; lookup can therefore
produce multiple candidate voices. Allocation/admission can prevent a
candidate from starting. An out-of-range Vagi index supplies a null VAG
pointer to the noise branch, while an in-range hole or VAG start `-1`
skips that candidate. The checked fighter candidates below use valid VAGs.

`hsyn_start_selected_voice` sends the selected VAG's first word plus the
binding's SPU base to `hsyn_set_spu_address`, with libsd selector `0x2040`.
`hsyn_initialize_selected_voice` uses its sample rate in pitch normalization.
After packet decoding, `hsyn_main` calls `hsyn_dispatch_staged_voices`;
its mode-zero branch starts selected voices, then moves them to the active
list. `hsyn_update_active_voices` follows that dispatch.
This establishes the final compact sample address. There is no PLVOICE
member lookup in this chain.

**Clean-file observations joined to those consumers:** the following exact
bank selections use the bank ranges in
[Compact fighter bank resources](../../game/character_assets.md#compact-fighter-bank-resources).
Each selected Sset contains one sample, and both its velocity range and
the sample's range are `1..127`. Consequently any admitted nonzero velocity
in that range selects the listed candidate. File offsets below are in the
owning clean `DATA/SNDDATA.BIN`; they are not runtime addresses.
All selected VAG records store sample rate 22,050.

| NA2 exact character / ID | Program | Key | Sset / Smpl | Vagi | Sample file offset |
| --- | ---: | ---: | ---: | ---: | ---: |
| Naruto Uzumaki (Classic), 1 / normal | 0 | `0x3C` | 0 / 0 | 6 | `0x004321E0` |
| Same / alternate | 0 | `0x3E` | 58 / 58 | 7 | `0x00432DD0` |
| Same / normal | 26 | `0x3C` | 46 / 46 | 56 | `0x0048A6F0` |
| Same / alternate | 26 | `0x3E` | 81 / 81 | 57 | `0x0048F130` |
| Naruto Uzumaki, 57 / normal | 0 | `0x3C` | 0 / 0 | 14 | `0x00DE5FC0` |
| Same / alternate | 0 | `0x3D` | 41 / 41 | 14 | `0x00DE5FC0` |
| Same / normal | 26 | `0x3C` | 23 / 23 | 39 | `0x00E0FAD0` |
| Same / alternate | 26 | `0x3D` | 64 / 64 | 39 | `0x00E0FAD0` |
| Sai, 92 | 0 | `0x3C` | 0 / 0 | 3 | `0x01560520` |
| Same | 26 | `0x3C` | 23 / 23 | 28 | `0x015834F0` |
| Sasuke Uchiha, 93 | 0 | `0x3C` | 0 / 0 | 3 | `0x0158D510` |
| Same | 26 | `0x3C` | 23 / 23 | 28 | `0x015B2BB0` |

The Sai/Sasuke splits admit keys `12..119`; the checked Naruto splits
match their individual keys. All four checked NA2 banks have a missing
Prog entry 27. Thus the enabled alternate event `0x19` can emit program 27,
but that program clears selection in those banks and cannot reach a VAG
through this decoder. EE control enablement alone does not establish a clip.

| NUN4 exact character / ID | Program | Key | Sset / Smpl | Vagi | English / Japanese sample file offsets |
| --- | ---: | ---: | ---: | ---: | --- |
| Naruto Uzumaki (Classic), 1 / normal | 0 | `0x3C` | 0 / 0 | 6 | `0x0034A670` / `0x0182DFA0` |
| Same / alternate | 0 | `0x3E` | 61 / 61 | 7 | `0x0034B150` / `0x0182E7E0` |
| Same / normal | 26 | `0x3C` | 46 / 46 | 58 | `0x003B2BA0` / `0x01885D30` |
| Same / alternate | 26 | `0x3E` | 84 / 84 | 59 | `0x003B66A0` / `0x0188A310` |
| Same / alternate event `0x19` | 27 | `0x3E` | 85 / 85 | 19 | `0x0035E630` / `0x018410B0` |
| Naruto Uzumaki, 57 / normal | 0 | `0x3C` | 0 / 0 | 33 | `0x00FCAAC0` / `0x022A5F20` |
| Same / alternate | 0 | `0x3E` | 31 / 31 | 3 | `0x00F87970` / `0x0226F330` |
| Same / normal | 26 | `0x3C` | 23 / 23 | 59 | `0x01000D20` / `0x022CE8C0` |
| Same / alternate | 26 | `0x3E` | 77 / 77 | 29 | `0x00FBE660` / `0x0229BDF0` |
| Same / alternate event `0x19` | 27 | `0x3E` | 79 / 79 | 9 | `0x00F8FBD0` / `0x02277510` |
| Orochimaru, 9 | 0 | `0x3C` | 0 / 0 | 13 | `0x0067CF80` / `0x01AC7080` |
| Same | 26 | `0x3C` | 26 / 26 | 39 | `0x006B95C0` / `0x01AF72F0` |

Both language sets have the same checked index/key/velocity relationships;
their sample offsets differ. Orochimaru's checked splits admit
keys `12..119`. These tables establish stored sample selection, not spoken
content, guaranteed audible playback or complete bank equivalence.

#### Compact voice admission and allocation

**MCP code observations:** the already established lookup supplies candidates
to `shared:MODHSYN.IRX:hsyn_note_on`. For each eligible candidate it first
applies a nonzero `HsynSampleRecord.exclusive_group` at sample `+0x0E`
through `hsyn_choke_channel_group`. Matching voices on the same channel's
held, sustained and released lists are removed: started voices receive
key-off and forced ADSR2 `0xC021`, then recycle; unstarted voices recycle
without hardware key-off. This precedes quota/allocation, so a subsequently
rejected candidate can already have stopped its group peers.

The candidate's priority is **unsigned sample byte `+0x0F` plus unsigned
port byte `+0`**, retained as a 16-bit value at voice `+0x14`. Port byte
`+1` is its voice quota; byte `+0x16` counts its allocated slots, including
staged and released slots until recycling. `hsyn_initialize` defaults to
priority base 0 and quota 48. The checked NA2 fighter loader
`audio_load_character_bank` (`0x001DB060`) calls
`audio_stream_set_parameter` with side+2, 0, 1; its RPC `0xA0 + port`
reaches `shared:SNDBASE.IRX:sndbase_set_port_parameter`, which writes
**base priority 0, quota 1** to fighter ports 2 and 3.
This is the loader's configuration, not a census of every possible writer.

When count is at least quota, `hsyn_enforce_port_voice_limit` scans all
16 channels in that port. It first chooses the lowest-priority released
voice no higher than the incoming priority. Only when none qualifies does
it scan held and sustained voices. Equal priorities replace the current
candidate, retaining the last encountered tie. A selected victim receives
key-off/forced ADSR2 and recycles. No victim causes an immediate return from
the **whole note-on**, abandoning remaining splits/samples; voices already
admitted in that call remain allocated.

`hsyn_initialize_voice_pool` initializes **24 records per SPU core**, each
`0x150` bytes, with fixed core/slot bytes `+0x40/+0x41`. This pool is shared
across ports. `hsyn_reserve_voice_masks` can remove currently free slots
into reserved lists; its masks therefore reduce available free counts.
The compact allocation sequence is:

| Step | Static rule |
| --- | --- |
| `hsyn_take_free_voice` | Sample `+0x29` core mask `0x10` selects core 0, `0x20` core 1; neither or both chooses the larger free count, ties core 0. Pop the selected free list or return null. |
| `hsyn_reclaim_finished_voices` | On the first pressured allocation while `hsyn_status_refresh_available` is set, clear that flag, inspect active completion and cache ENVX at `+0x12`; recycle completed slots, then retry the free list if any were recovered. |
| `hsyn_steal_active_voice` | Only compact-mode voices (`+0x57 == 0`) on allowed cores. Zero core mask admits both; traverse core 1 then 0. Prefer lower `flags & 0x300`, then lower priority, then lower cached ENVX, with victim priority no higher than incoming. Exact rank ties keep the first encountered voice. |
| `hsyn_steal_staged_voice` | If active stealing fails, traverse allowed cores 1 then 0 for compact staged voices. Pick the lowest priority no higher than incoming; equal ties keep the first. |

Successful stealing detaches the old owner and decrements its port/global
counts before reusing the same slot. Active stealing stages key-off;
staged stealing does not start or release the old pending voice. If no
slot can be obtained, note-on skips that candidate and continues its
remaining candidates, unlike the quota failure's whole-call return.
Rejected candidates are not retained as a queue for retry. Allocated
candidates are retained on the staged list until dispatch can start them.

#### Checked compact admission fields

These reads use the already established candidate indices, without
repeating the decoder or identifying spoken content. Complete NA2/NUN4
`SNDDATA.BIN` SHA-256 values were rechecked against
[File identities](../../game/files/file_identities.md#character-comparison-inputs).
All entries below have exclusive group **0**, priority **10**, sample
core/mix flags **`0x03`**, and VAG flags **0**.

| Exact bank selection | Checked Smpl indices |
| --- | --- |
| NA2 Classic Naruto, ID 1 | `0,58,46,81` |
| NA2 Naruto, ID 57 | `0,41,23,64` |
| NUN4 English Classic Naruto, ID 1 | `0,61,46,84,85` |
| NUN4 English Naruto, ID 57 | `0,31,23,77,79` |
| NUN4 English Orochimaru, ID 9 | `0,26` |

Joined to the inspected NA2 fighter-port configuration, these candidates
have incoming priority 10 and allow either core. Sample flag bits `1/2`
enable the two direct output paths; bits `4/8` control effect output paths
in `hsyn_start_selected_voice`. This bounded field check does not establish
those values for every donor sample, other language sets or character.

#### Compact release and update timing

`shared:MODHSYN.IRX:hsyn_note_on` marks an allocated compact voice
`0x208`: held `0x200` and unstarted `0x08`. It links the voice into its
channel and the core staged list. `hsyn_main` drains all port packets
before calling `hsyn_dispatch_staged_voices`, then
`hsyn_update_active_voices`. Consequently later packets in the same drain
can replace an earlier staged candidate before it starts.

Dispatch visits cores 0 then 1. It flushes pending key-off masks first,
then **defers any slot whose ENVX is greater than 999** (or the separate
scheduled-mode/key-`0xFF` condition). Eligible voices are initialized on
the SPU, unstarted flag `0x08` is cleared, and they move to the active
list; accumulated key-on masks flush afterward. An allocated replacement
can therefore wait across updates for the old hardware envelope to fall.
There is no fixed delay count for this ENVX gate.

`hsyn_note_off` scans the held list for matching key and tag, with tag
`0xFF` as wildcard. Sustain byte channel `+0x32` moves the matched voice
to its sustained list and sets flag `0x100`. Otherwise a started voice
releases modulation, stages key-off, clears held/sustained flags and moves
to the released list. Its allocated count remains occupied until completion
or eviction. An unstarted voice recycles immediately. Sustain-off and
`hsyn_release_channel_notes` similarly move started voices to release;
`hsyn_recycle_voice` finally returns the slot to its core free list.

For completion, a released voice (`flags & 0x300 == 0`) recycles at
ENVX zero. Held/sustained voices require both ENDX and ENVX zero after
the startup grace. Both starters set grace byte `+0x4B` to 3: a completion
read with ENDX still set decrements it and reports protected ENVX `0x7FFF`;
ENDX clear resets it to zero. **Inference:** this protects initial stale
completion state. It is not a declared clip duration. A pressure-reclaim
sweep uses the same completion conditions and caches ENVX for stealing;
when it clears the
refresh flag, that call's later active update skips repeated completion
reads. The active updater restores refresh eligibility afterward.

Each retained active voice advances its enabled modulation, portamento and
ramps once per `hsyn_update_active_voices` call, followed by changed pitch/volume
writes. Newly dispatched voices are included in that same call's active
update; still-staged voices receive no active step. Portamento accumulators
move once toward zero; modulation delay and ramp counters advance once.
`hsyn_initialize_modulation` converts its authored duration fields to update
ticks using `hsyn_update_scale`, with rounded `duration*256/scale`; it does
not count EE fighter animation frames.

`shared:SNDBASE.IRX:sndbase_initialize` supplies interval argument
**`0x1047` (4167)** to both synth and sequencer initialization.
`sndbase_configure_worker_timer` passes the same value through the
`thbase` ordinal-39 time conversion, registers
`sndbase_timer_wake_worker` on the hard timer, then starts it through
`sndbase_start_worker_timer`. The callback wakes the sleeping packet worker
and returns the configured timer ticks. Each worker iteration copies pending
packets and calls `hsyn_main`, including when no packet was pending.
Synth initialization stores `(4167 << 8) / 1000 = 1066` as its update scale.
This establishes configured timing and per-call units, not measured cadence,
an audible latency bound or a guarantee that every timer wake is serviced.
`shared:MODMIDI.IRX:midi_main` remains a separate sequencer step/output path;
the checked compact worker calls the synthesizer directly, without a
sequencer tick prerequisite for these fighter packets.

### Position-dependent command parameters

`audio_reference_vectors` supplies references to `audio_position_scalar`
and `audio_position_direction`. The former uses full three-dimensional
distance; the latter uses the first two coordinates. The coordinate convention
remains unresolved.

**Inference:** these provide attenuation and stereo parameters. Command
placement is established; IOP units/mixing are not. Helper annotations preserve
formulas, ranges and distinct null/reference defaults. Their `cvt.w.S`
instructions do not change FCSR. Caller-lifetime rounding mode is unknown,
so decompiler casts do not prove truncation.

## Pending streamed requests

In NA2, `AudioRequestContext` holds four `AudioPendingStream` rows.
`audio_consume_pending_streams` scans in order, stops each pending slot
before requesting its replacement, then clears pending regardless of admission.
This bounded array has no FIFO or retry contract.

`audio_request_archive_member` admits slots `0..2` and families 0/2/3.
`audio_archive_families` selects `audio_sound_descriptors`,
`audio_rpgvoice_descriptors` or `audio_plvoice_descriptors`. Inclusive
bounds 13/82/93 reach all-`0xFF` sentinels whose negative member counts reject
nonnegative members. `audio_rpgvoice_bound`/`audio_plvoice_bound` hold the
latter bounds. Nonzero `audio_stream_inhibit` inhibits stream starts.

`audio_queue_player_voice` resolves a filename number through
`voice_filename_number_lists` and queues the physical member in family 3.
A null list leaves pending rows unchanged. A nonnull list lacking the number
queues member `-1`: consumption still stops the slot before rejecting it.
Its signed upper-bound check alone does not establish unrestricted caller
safety. Family-3 inventory belongs to
[Character assets](../../game/character_assets.md#voice-descriptors-and-filename-number-lists).

### Recovered BTL PLVOICE producers

In NA2, `dialogue_voice_produce` queues immediately or defers through the owner's
inline FIFO. `dialogue_voice_produce_indexed` reads an indexed eight-byte
row and takes fighter/slot from supplied participants.
`dialogue_voice_consume` has two idle-gated pop/request branches. Argument
and predicate details are annotated on those routines.

Immediate/pop routes can resolve ID zero when the owner's fighter-enabled
byte or child predicate rejects its fighter. ID zero's null filename list
leaves pending rows unchanged. Indirect callers remain open.
This does not establish that compact commands feed the streamed queue or
identify dialogue resources.

`audio_request_sound_member` forces family zero.
`audio_request_match_result` separately maps results `0/1/3/4` to SOUND
descriptor 10, members `2/1/3/4`, slot zero; other results emit nothing.
[Match outcomes](match_outcomes.md) owns result-state producers.

### Selected deferred voice-value lifetime

`dialogue_voice_row` returns a resident row of `dialogue_voice_rows`
using `DialogueVoiceRoot.voice_row`. Both recovered selectors use eight-byte
rows without allocation/copy. The deferred producer copies only a voice number;
its coordinator gate and `-1` suppression are annotated on the routine.

`DialogueVoiceFifo` holds eight inline numbers. A ninth unconsumed push
overwrites the oldest, retaining the latest eight in FIFO order. Push/pop
annotations own cursor/empty-state details. Construction/reset callers are open.

Consumption checks the owner's predicate and cached mono activity before pop,
then binds to its current fighter/slot. A zero-ID path or later member rejection
does not restore the number. Source-row lifetime is irrelevant after copying;
fighter/slot binding is deferred to consumption. All possible owner-field
changes and audible dialogue identity remain unestablished.

## SFX selectors and loaded sound banks

Compact battle audio uses `DATA/SNDDATA.BIN` separately from CRI members.
`audio_snddata_filename` holds the disc name. The shallow `IECS` format is
owned by [Disc inventory](../../game/files/disc_files.md#data-fonts-graphics-sound-and-archives).

`audio_sfx_control` resolves common and current-mode bank events:

| Mode | Event range | Control table | Records |
| ---: | --- | --- | ---: |
| Any | `0..0x5C` | `sfx_common_controls` | 93 |
| 0 | `0x1000..0x103A` | `sfx_mode0_controls` | 59 |
| 1 | `0x2000..0x20B0` | `sfx_mode1_controls` | 177 |
| 2 | `0x4000..0x4006` | `sfx_mode2_controls` | 7 |
| 3 | `0x3000..0x3056` | `sfx_mode3_controls` | 87 |

All 423 accepted controls have nonnegative programs and stream/channel zero.
Their complete program/default census is annotated on the tables; these values
do not identify samples.

`audio_route_bank_event` applies suppression before separating common/bank
events. Bank wrappers require a current mode allocation and valid control.
`audio_emit_common_control` constructs commands with position-derived or
explicit parameters; some modes/channels allocate tokens. Its annotation owns
the individual construction branches.

### Character bank loading

Character-bank file ranges and direct-ID descriptor selection belong to
[Character assets](../../game/character_assets.md#compact-fighter-bank-resources).

The 94 rows comprise 17 wholly null and 77 populated records, with 64 distinct
triples. Null IDs/sharing groups are annotated on the table. ID 9 has a bank
despite null PLVOICE; IDs 39/51 reuse banks despite null PLVOICE. These
inventories have different contracts.

The confirmed header/sample loading, binding and resource lifetime are owned by
[Compact voice resource and lifecycle](#compact-voice-resource-and-lifecycle);
the final lookup is established under
[Compact program-to-VAG lookup](#compact-program-to-vag-lookup).

`audio_replace_mode_bank` uses one of four `audio_mode_banks`, resets sound,
issues `0x140`, waits for all three cached family-zero busy flags to clear,
loads and binds through `0x9051`. Neither state machine identifies every cue.

### Interrupted and identified requests

`audio_release_event_token`, `audio_update_token_position` and
`audio_update_token_scalar` construct token-directed maintenance or zero-scalar
termination commands. Encodings prove EE maintenance, not IOP priority or
interruption policy.

`audio_token_allocate`/`audio_token_release` manage eight reusable tokens
`1..8`; full allocation returns `0xFF`. Automatic audible-completion release
and priority stealing are unestablished.

`audio_release_banks` requests stop and conditionally frees IOP allocations.
`audio_reset_auxiliary_state` resets tokens, retention and the request selector,
without clearing four pending stream rows. `audio_clear_request_selector`
changes only that selector.

## Transport and stream-poll scheduling

Runtime ownership uses request-context pointer `audio_request_context_ptr`,
CRI-manager pointer `audio_stream_manager_ptr`, and command/RPC-context pointer
`audio_command_context_ptr`.
`AudioRequestContext`, `AudioStreamManager` and `AudioCommandContext` name
established fields. The cooperative tasks have distinct consumers:

| Task | Ordering after its wait |
| --- | --- |
| `sound_task` (`SOUND`) | Drain common, player-one, then player-two packets. |
| `sound_rpc_task` (`SND_RPC`) | Fade/update; reset the sixteen `audio_auxiliary_words` to `-1`; queued parameters; cinematic stop; pending streams; stop command; bank transaction; separate operation slot. |
| `sound_rpc2_task` (`SND_RPC2`) | Wait for readiness, then poll only when polling is enabled. |

Task annotations own individual gates. Relative ordering within each task is
established; inter-task cadence and IOP execution time remain unknown.
[Task system](../../runtime/task_system.md) owns cooperative lifetime.

### Bounded compact packet drain

`audio_common_packet_initialize` and `audio_player_packets_initialize`
construct fixed packets, initialized with `C0 00`:

| Use | Append handle | Packet |
| --- | --- | --- |
| Common | `audio_common_append_handle` | `audio_common_packet` |
| Player one | `audio_player_one_append_handle`, pointer slot `audio_player_one_append_handle_ptr` | `audio_player_one_packet` |
| Player two | `audio_player_two_append_handle`, pointer slot `audio_player_two_append_handle_ptr` | `audio_player_two_packet` |

`AudioAppendHandle` reaches a table of `AudioStreamBufferRow`s.
Append requires `used + length + 8 <= capacity`. Initialized capacity is
`0xF4`, with trailer 1 in the `0x100`-byte packet. Append failure neither
grows nor overwrites existing payload.

`audio_drain_packet` submits through `audio_submit_packet_dma` then clears
usage regardless of success. Submission uses SIF descriptor
`audio_packet_dma_descriptor` and bounded polling. Capacity/DMA failures can
lose requests; IOP acknowledgment, ordering and rejection remain unknown.

### Immediate RPC and bank transactions

`audio_rpc_call` rejects loading or an already-held lock, then holds it while
selecting one of two `audio_rpc_clients`. Service IDs, command bits, lengths
and completion exceptions are annotated on the helper. Ordinary commands use
`audio_rpc_buffer`; others send caller data. The inspected IOP bank-load/bind
operations are described above; the remaining service commands are not a
complete decoded protocol.

`audio_queue_bank_transaction` has one overwriteable operation slot;
`audio_service_bank_transaction` consumes operations `0..4`. Battle
setup's per-side wait prevents that caller replacing its unfinished operation.

### Cached stream activity and replacement

`sound_rpc2_service` polls three stereo then three mono handles through
`audio_poll_stream_activity`, caching activity.
`audio_cached_stream_activity` reads without polling or advancing playback.
Mono/stereo polls use CRI state/completion, not sample cursors. CRI end-state
ownership is in [Audio and video replacement](../../game/files/audio_video_replacement.md#resident-menu-music-selection).

`audio_stop_mono_slot` reaches `audio_stop_mono_handle`, setting level
`-960` and stopping CRI. `audio_start_mono_member` starts on the existing
handle and sets level zero; its inspected body ignores the descriptor's extra
start parameter. Pending replacement stops the previous stream before knowing
whether the new selection is valid.

## Fighter action cue production

`fighter_update_movement_slot` invokes effects then
`fighter_schedule_action_audio` under its node-update flag, outside the
positive-pause branch. The scheduler reads major/substate, primary timeline,
current `ActionRecord` and `hit_lookup_record`.

Most entry cues use `timeline_secondary_event_crossed(primary,0)`, requiring
the whole-unit flag and zero integer/fractional cursor. Major 8 uses
`ActionRecord.audio_time`. Timeline/execution ownership is in
[Timer primitives](../../runtime/timer_primitives.md#event-and-interval-predicates),
[Animation runtime](../../runtime/animation_runtime.md), and
[Combat action execution](../combat/combat_action_execution.md).

The complete switch has audio branches for majors `0/1/2/5/6/8`; others emit
nothing here. Its annotation records every cue/fallback/predicate. Fighter
halfwords `+0x964/+0x966/+0x968`, `+0x9BA/+0x9C2`, and float `+0xA48`
retain raw offsets because wider meanings are unresolved.

Minor 9 falls into 10: successful zero-event checks can issue two voice
`0x1D` requests, with the second SFX conditional on `+0xA48 == 0`.
Inclusive random bounds establish minor 8's `0x1A..0x1C` group and the
draw-3 no-request outcome in three-choice response groups.

### Periodic and response selectors

`fighter_surface_sfx_period` provides identity-dependent divisors of the
primary integer cursor. These are action-cursor units, not worker countdowns.
Its complete identity map is annotated.

`action_sfx_map` translates 102 action/response selectors into common or
mode-zero events. `fighter_schedule_response_sfx` owns bounded response
selection, suppressed substates and extra cues. Mapped values do not prove
audible identity. `ActionRecord` names `audio_sfx/audio_voice/audio_time`,
`response_sfx/guard_sfx/response_voice`.

Response voice distinguishes disabled `-2`, explicit nonnegative events and
other negatives selecting minor-dependent random groups. The scheduler
annotation preserves those groups and the gated fallback override to `0x12`.

### Other recovered fighter cue producers

Local resource-gain, taunt, charge, awakening, table and auxiliary gates are
annotated on `fighter_hp_add`, `fighter_secondary_resource_add`,
`item_immediate_dispatch`, `taunt_update`, `chakra_charge_update`,
`input_sector_widen_state_b`, `awakening_dispatch`,
`fighter_request_table_voice` and `fighter_schedule_auxiliary_audio`.
Their wider behavior belongs to
[Damage](../combat/damage.md#character-durability-and-effective-base-hp),
[Chakra and guard](../combat/chakra_and_guard.md), and
[Awakening](../characters/awakening.md).

Character cues use primary and secondary timelines.
`fighter_primary_timeline_voice_update` and
`fighter_secondary_timeline_voice_update` demonstrate different authored
times/action gates through `timeline_event_crossed`. A shared primary cursor
cannot explain every voice cue.

Direct-control requests bypass event selection and cooldown while retaining
object suppression. Controls are neither event IDs nor physical members.
Their caller-specific values and random pairs are annotated on the routines.

Pseudo-events include literal, random and authored values with cursor/phase
gates. `fighter_authored_voice_update` uses `fighter_authored_voice_event`;
`tsunade_channel3` uses `tsunade_audio_event_time`. Local blocks do not
identify every character action/resource.

### Surface-dependent SFX

`audio_surface_event` and `audio_request_contact_surface` mask
`0xF0F0F0` but differ on several inputs. Both complete maps are annotated
without inferred material names. `audio_request_periodic_surface` uses the
first map, identity-dependent defaults and an extra cue for IDs `0x15/0x53`.
[Stage surface attributes](../stages/stage_surface_attributes.md) owns inputs.

## Cinematic and guide voice schedulers

### Authored cinematic frame rows

`sp_skill_play_frame` compares the next `CinematicAudioRow` with the exact
scene integer frame, emits its enabled cue and advances once, without catch-up.
**Inference:** skipped authored frames can leave a row unconsumed; actual
progression belongs to [Scene playback callers and owners](../../runtime/scene_playback_owners.md).

Transformed characters remap `0x0C..0x14` to `0xAC..0xB4`.
`audio_request_cinematic_cue` matches scene participants to player packets;
the second append requires first-append success. This lacks ordinary event
state/cooldown gates. The streamed intro's latch/countdowns are owned by
[Ultimate jutsu](../characters/ultimate_jutsu.md#presentation-state-machine);
their `audio_cached_stream_activity(1,0)` query uses the cache contract above.

#### Selected row binding and resident lifetime

`sp_skill_play_start` permits `jutsu_resolve_character_skill` to replace
the selector, then binds `cinematic_audio_descriptors`. Owner pointers retain
resident descriptors/rows rather than copies; `sp_skill_play_begin` keeps
them while initializing other resources. Callback registration and the
first-frame-1 index sentinel are annotated on the binder.

Fully read bindings are selector 1's three `cinematic_audio_rows_1` rows,
selector 2's four `cinematic_audio_rows_2` rows and selector 3's one
`cinematic_audio_rows_3` row. Ordered frame/cue values are annotated.
These post-resolution selectors are not asserted character/jutsu names;
other resources and creator reachability remain open. Selection belongs to
[Ultimate Jutsu cinematics](../characters/ultimate_jutsu_cinematics.md).

#### Match-category-6 request admission

Category 6 enters `audio_request_category6_cue` before ordinary control-range
and participant-ID checks. Thirteen `category6_audio_keys` exclude remapped
`0xAC..0xB4`. The chosen fighter supplies the temporary program after
base-ID conversion. Fighter `0x27` and negative programs suppress emission;
ID `0x4A` maps to `-1`, yielding suppressed signed program `0xFE`.

The first seven matches copy `sfx_mode2_controls`; matches `7..12` copy
`audio_category6_adjacent_bytes`, containing path/RPC strings and padding.
The caller has no seven-record bound. These are not six additional authored
controls; successful/audible requests for them remain unestablished.

This common compact route bypasses object suppression and mode-allocation
gates, without bank waiting/availability checks; signed-program suppression
and bounded append still apply. It does not request PLVOICE members.
Sample availability/lifetime require the selected bank and voice admission;
this category's exact loaded-bank/program sample closure remains open.

### Guide Ninja Sound

`GuideVoice` is a retained command-display child. `guide_ninja_update`
admits idle scheduling only when setting key `0x0A` is enabled and cached
mono slot 2 is idle. Countdown advances only under those gates. It chooses
one of two three-member groups, tries at most ten draws to avoid repeating,
requests SOUND descriptor 4 on slot 2, and reseeds `150..240` eligible calls.

`guide_voice_selectors`/`guide_voice_cues` cover 94 identities/fifteen
rows; all candidates `3..82` fit descriptor 4's 99 members.
`guide_voice_construct` starts at 90, with fallback selector 11 on its
signed upper-bound rejection; negative-ID safety is unestablished.
`guide_voice_set_countdown` uses nonzero caller values directly or
`150 + prng_inclusive(90)`.

The retained name `commands_hud_state_update` denotes the guide state body:
zero runs idle scheduling; one becomes two; two requests an event member and
enters three; three waits for countdown zero and cached idle, then reseeds.
Four emits nothing. State-three decrement lacks the setting gate. The event
repeat loop is unbounded in attempts, although every six-member group contains
at least two different values.

Setting-gated `guide_ninja_event` arms idle state two with countdown 5.
`guide_condition_query` is a constant-zero stub, making its nonzero-query
state-four alternative dormant.
[Practice mode](../modes/practice_mode.md) owns the menu setting.

#### Guide allocation, publication and dispatch

`battle_state_allocate` publishes `CommandsHudAudioOwner` through
`battle_commands_hud` under its coordinator-child gates.
`commands_hud_initialize` initializes the parent;
`commands_hud_construct_children` selects side/fighter, creates tracking
and allocates a separate guide, retained as its child rather than task.

Neither `guide_voice_initialize` nor construction initializes
`GuideVoice.previous_member`. `heap_allocate` and payload/placement
helpers build headers without clearing payload. The first comparison's value
is therefore unspecified; zero is unestablished. First selection writes it.
The parent's unsigned ID byte does not prove unrestricted signed-caller safety.
[Allocator and capacity](../../runtime/ee_memory_map/allocator_and_capacity.md#allocator-model)
owns the arena contract.

`battle_state_wait_graph` chooses owner update/stop under coordinator/match
gates. Key 1 controls drawing, not that branch.
`commands_hud_update` calls `fighter_build_action_statistics` before guide
update; success can still output index `-1`, so each idle decrement does not
require a new command. Tracking belongs to [Practice mode](../modes/practice_mode.md).

`commands_hud_event_update` is the recovered trigger caller. Display
countdown/tracking/index/record gates precede marking, display reload and
trigger. It can arm state two after that invocation's guide update; no
inter-call time interval follows from this ordering.

#### Guide interruption and local teardown

State two requests directly without idle checking or the pending consumer's
prior stop, records the member and enters three without checking admission.
It retains countdown 5. This starts on the same handle; replacement, rejection
or audible overlap while busy remain unestablished.

`guide_voice_stop` leaves coordinator states 1/2/6 alone; others reach
`audio_guide_stop_slot(2)`. It does not alter guide state/countdown.

Descriptor bounds admit known candidates, but the stream-inhibit global can
reject admission. The archive helper returns one without checking CRI success.
Neither guide callers nor admission check RPC lock, bank transaction or ready.
Eligibility does not prove priority/completion. Availability belongs to
[Startup](../../game/startup.md#audio-initialization-bottleneck) and
[Audio and video replacement](../../game/files/audio_video_replacement.md#actual-codec-and-archive-map).

`commands_hud_destroy_children` cleans/frees the guide, clears its pointer
and reinitializes the parent. `guide_voice_cleanup` clears local state without
stopping audio. Resident deletion/transitions free the parent and clear
publication; [Battle lifecycle](battle_lifecycle.md) owns those transitions.
Memory teardown does not prove an admitted stream ended.

No nonzero writer of states one/four is established outside the inspected
owner. Initial payload, indirect callers and admitted-update intervals are open.
