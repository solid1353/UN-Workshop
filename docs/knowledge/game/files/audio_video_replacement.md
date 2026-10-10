# Audio and video replacement

## Research coverage

Established: the complete clean AFS/PSS corpus, file-size source, descriptors/subtitles,
menu track selection, stream mode and completion, and the master, music, voice
stream and sound-effect output levels.
Open: adaptive AHX, ADX history/loop padding, PSS writing and `NOTICE`
encoding, decoder acceptance/bandwidth and indirect consumers of dormant movie
rows. Names come from `@annotations/NA2` and `@annotations/shared`; comments
hold per-routine details. Addresses are live.

This note records the native format and playback constraints for the four AFS audio
archives and ten PSS movies in retail *Narutimate Accel 2*. It is a static
research result, not a claim that the game has accepted a generated file at
runtime. The protected files under `@source_na2/` were inspected read-only.
CriCodecs 1.2.0 was exercised from a checksum-verified release.

Evidence labels in this note have their usual knowledge-base meaning:

- **Observed**: read directly from the source files.
- **Inferred**: a feasibility hypothesis follows from the observed layout;
  structural fit and native decoder acceptance remain separate questions.
- **Unresolved**: the current evidence does not close the question.

Evidence is one clean `SLPS_258.37` and its extracted media, bounded direct-call
research, corpus parsers and offline codec experiments. It establishes structure
and offline feasibility, not playback acceptance or the absence of indirect
consumers. The menu observation also uses two supplied savestates. File
identities and address conventions are owned by
[Retail game file identities](file_identities.md).

## Result

- **Audio has a fixed-slot fit hypothesis.** A same-or-smaller encoded leaf can
  occupy the observed aligned slot without changing the archive's size.
  Acceptance by the bundled CRI driver is unproved. CriCodecs 1.2.0 supplies
  bounded ADX/AHX evidence, but its fixed AHX allocation and incomplete ADX
  version-4 fields do not cover every observed profile.
- **Movies have an established source contract and unproved writing hypotheses.**
  A same-size donor with the target's stream contract has structural fit;
  size alone does not establish acceptance. Packet-skeleton rewriting and
  constrained full muxing are inferred possibilities. Resident descriptors
  retain geometry, transition frames and six Japanese subtitle schedules,
  independently of the PSS. Movie size comes from the disc directory, with no
  separate compiled per-movie size table.
- **The extracted `.adx` suffix is not codec evidence.** Header scans show
  9,068 CRI AHX voice/effect files and only 246 CRI ADX files.

## Movie file size

The native movie path obtains file length from the disc directory and adds no
second per-movie size limit.

### Runtime movie path and size source

`movie_play_descriptor` opens the selected filename through `mpeg_open_movie`
and `mpeg_create_tasks`. The reader's `mpeg_open_disc_stream` searches the
uppercase disc path, for example `\PSS\LOGO_C.PSS;1`, using
`movie_disc_path_prefix` and `cdvd_query_recovery_task`. The returned
`MovieDiscStream.start_lsn` and `file_size` supply its extent;
`remaining_bytes` and the reader's read/consume counters start from that size.
There is no descriptor-authored byte length.

The thread reads at most `0x10000` bytes per turn, rounds each physical read
down to whole `0x800`-byte sectors in `mpeg_read_disc_sectors`, and feeds a fixed
`0x60000`-byte ring buffer. Its main loop continues only while more than four
file bytes remain. With the observed `N * 0x4000 + 4` layout, it therefore reads
all program-stream packs and leaves the four-byte program-end code as the final
unread remainder. Total movie size is not a decoder-buffer allocation.

**Supported conclusion:** a different number of valid `0x4000` packs is not
rejected by a resident hard-coded length. The stream must retain the four-byte
tail convention; disc-image integration is outside this native format finding.

## AFS audio

### Actual codec and archive map

The four top-level AFS files contain 170 AFS archives when their nested
archives are included. Across them there are 9,966 declared indices, 9,480
non-empty members, and 486 null members. Of the non-empty members, 166 are
nested AFS containers and 9,314 are audio files.

| Top-level archive | Outer layout | Leaf audio observed | Channels and rate |
| --- | --- | --- | --- |
| `PLVOICE.AFS` | 93 indices: 72 nested AFS, 21 null | 2,232 AHX type `0x11` | Mono, 24,000 Hz |
| `RPGVOICE.AFS` | 82 indices: 81 nested AFS, 1 null | 914 AHX type `0x10`; 4,683 AHX type `0x11` | Mono; 5,596 at 24,000 Hz and one at 48,000 Hz |
| `SOUND.AFS` | 13 nested AFS, no null outer index | 642 AHX type `0x10`; 597 AHX type `0x11`; 73 ADX type `0x03` | AHX mono; ADX stereo; all 24,000 Hz |
| `STREAM.AFS` | 184 direct indices: 173 audio, 11 null | 173 ADX type `0x03` | Stereo, 24,000 Hz |

The one rate outlier is
`DATA/RPGVOICE.AFS.files/028.afs.files/015.adx`: its header reports AHX type
`0x10`, mono, 48,000 Hz, and 183,798 samples. Its `.adx` name came from the
extractor and does not change the header classification.

### Resident menu-music selection

The supplied Mode Select and Character Select savestates each contain coded
data from `SOUND.AFS.files/000.afs.files/001.adx` in EE and IOP memory. The
resident dispatcher `audio_dispatch_frontend_command`, reached through
`audio_request_frontend_command`, keeps the two screen commands separate even
though both clean commands select the same track-1 preset:

- Mode Select (`battle_mode_selector_update`) submits command 0, selecting
  `audio_frontend_mode_select_music`.
- BTL handoff state 6 (`battle_state_wait_selection_transition`), immediately
  before the resident Character Select child, submits command 6, selecting
  `audio_frontend_character_select_music`.

Both request music preset 1. It checks the current track, stops channel 0 only
when the track differs, then selects `SOUND.AFS/000` leaf 1. Selection stores
the leaf index, matching the coded data in both savestates. The separate
command labels are independent selection sites even though the clean result
is identical. **Inference:** these fixed-size instruction sites can select
other existing tracks independently without changing `SOUND.AFS`.

`audio_music_track_gain`, read by `audio_get_track_gain`, stores `-40` for
track 62 and `0` for track 68. `audio_start_streamed_music` combines track gain
with `AudioCommandContext.music_volume`, stores the effective channel gain,
and passes it to `cri_set_stream_gain`. `audio_set_music_channel_gain`
provides an independent update through `audio_set_stream_level` and the same
storage/setter.

The resident globals `audio_stream_manager_ptr` and `audio_command_context_ptr`
refer to distinct objects:
`AudioStreamManager` (including `music_stream0` and `selected_track`) and
`AudioCommandContext` (including `music_volume` and `current_music_track`).
A stream-state consumer must resolve the handle through the first pointer.

### Output levels

`AudioCommandContext.volume` holds the Options volume (`0..0x100`).
`audio_set_volume` stores it and queues hardware operation 1 with
`volume * 0x3FFF >> 8`; `audio_service_hardware_operations` applies that
through `sd_remote` SetParam to SPU2 core 1 `MVOLL`/`MVOLR` (`0x0981`/`0x0A81`),
the master output, so it scales every sound together. The `sd_remote` command
and parameter meanings are inferred from their libsd encodings.

`music_volume` (`+0x04`) is a separate level, initialized to `0x100` by
`sound_control_initialize`. `audio_start_streamed_music` applies it only to
`SOUND.AFS` (archive 0) streams, as `((track_gain + 300) * music_volume) / 256
- 300`; `audio_service_music_gain_requests` reapplies it to channel 0 when
`reapply_music_gain` (`+0xBD`) is set. Skill soundtracks (preset 9) start from archive 254
and get gain 0, so they ignore it. `afs_startup_load_partitions` loads the four
AFS archives as IDs 255 to 252; 255, 253 and 252 serve the `SOUND.AFS`,
RPGVOICE and PLVOICE nested loads, which leaves 254 as `STREAM.AFS`, whose 184
members match the 184 skills. Each member is a premixed soundtrack: decoded
member 001 contains music, voices and effects together. A scan of the 155 `gp`-relative context
loads in resident code and the overlays loaded at Character Select found no
other writer of `+0x04`; context pointers passed as arguments were not covered.

Stereo channels fade through `audio_start_music_fade`. A fade-in targets the
track gain scaled by `music_volume`; a fade-out starts from the stream's current
gain and can stop the channel. The live fade-ins are two `ETC.BIN` calls on
channel 0; the ELF's other callers are cases of `audio_music_control_unused`,
which nothing references. Channel 1, which carries cinematic music and
Ultimate Jutsu soundtracks, only receives fade-outs, so a gain set when a
soundtrack starts holds until it fades out.

The game creates two player sets: three stereo players for music and three
mono players. `audio_set_stream_level` also has a kind-2 branch, but no
constructor creates its handles and no caller passes kind 2.

Voice clips stream on the mono players. `audio_request_archive_member` is the
only caller of `audio_start_mono_member`, which starts the member and then
sets its gain to 0 through `audio_set_stream_level` kind 1. Every family it
serves is speech: family 2 is RPGVOICE, family 3 PLVOICE, and the family-0
`SOUND.AFS` requests are character calls on fighter confirmation (bank 6),
the defender's line in the screen-break cut-in (bank 8) and the match result
announcements (bank 10).

`audio_stream_set_level` sends RPC `0xB0 + kind` (kinds 0 to 4) with
`synth_level` (`+0x08`), initially `0x100`, and records it in
`synth_levels[kind]`. It runs for kind 0 after banks are released, a battle
mode is set up or the mode bank binds, and for kind 2 after a character bank
binds. `audio_service_level_fades` can also fade RPC `0xB0` toward
`level_fade_target`, but no code sets `level_fade_active`: scans of resident
code, `BTL.BIN`, `ETC.BIN` and the audio routines' context arguments found only
clears.

`SNDBASE.IRX` (identical in NA2, NUN4 and NUN5; annotated in the `shared`
target) drives Sony's MIDI sequencer and hybrid synthesizer.
`sndbase_set_port_volume` applies RPC `0xB0 + n` as a synthesizer port volume:
`n` 0 sets port 0, and `n` 2 to 4 set ports 2, 3 and 4 together. Port 1
aliases port 0. `sndbase_bind_bank` (RPC `0x9050 + slot`) loads the mode bank
(slot 1) into port 0 as a second bank beside the common bank, and the
character banks (slots `side + 2`) into ports 2 and 3. Kind 0 therefore sets
the volume of every common and mode-bank sound, and kind 2 that of both
character banks. Runtime tests that zeroed one kind at a time agree: kind 0
silenced the effects, including jutsu grunts stored in those banks, and kind 2
silenced the battle voice controls; streamed voice lines, music and the
premixed Ultimate Jutsu soundtracks were unaffected.

The commands travel in three packet buffers. Common and positional effects
reach `audio_common_packet` through `audio_common_append_handle`; the battle
voice dispatchers reach `audio_player_one_packet` and `audio_player_two_packet`
through `audio_player_one_append_handle` and `audio_player_two_append_handle`,
published as `audio_player_one_append_handle_ptr` and
`audio_player_two_append_handle_ptr`. Each handle reaches its packet buffer
through `AudioAppendHandle.streams->rows`, a one-row table.
`sound_task` sends them to the MIDI input buffers that `sndbase_initialize`
and `sndbase_midi_input_buffer` return for ports 0, 1 and 2.

Sound effects and battle voice controls are sent to the sound IRX as MIDI-style
messages per stream: `B0`, program change `C0`, note-on `90` with a note and
velocity, and the extended `F9` (pan) and `FD 0x10` (note, velocity) commands.
At least twelve routines append them directly, among them
`sfx_play_common` (common events, including menu sounds),
`battle_emit_position_event`, the two battle voice dispatchers,
`presentation_sound_request` and `audio_emit_common_control`, which serves
bank-routed requests. Each takes the velocity from the control's `scalar_cap`,
or from the distance scalar capped by it. Zeroing the velocity byte in
`audio_emit_common_control` alone silenced only the battle-start sound in a
runtime test, so there is no single per-event choke point.

Track 62 has a version-4 ADX loop block; track 68 uses the short version-4
header with no loop block. The ordinary streamed-music selector
`audio_select_music_track` selects mode `0` through `audio_start_streamed_music`
and `cri_set_stream_mode` before starting the stream. The separate
`audio_start_cinematic_music` selects mode `1` through the same path, and
`cri_apply_stream_mode` stores `CriStream.mode` and, in stream states 3 or 4,
updates the underlying ADX driver. This mode does not add loop points to a
short-header ADX.

The audio engine updates every live stream through `cri_update_stream_state`.
State 4 runs `cri_drain_finished_stream`, which continues draining decoded audio.
Once no buffered samples remain, it stops the driver and writes `CriStream.state`
5. The state-5 handler `cri_finished_stream_noop` is a no-op, so the finished
state persists until another audio command changes the stream. This is the
resident polling surface for detecting full-file completion when an ADX has
no authored loop block.

The common update `cri_update_active_streams` visits 16 slots and updates each
active stream. Its service runs from the registered audio callback and
synchronously during stream operations, so completion handling has more than
one entry path; it is not exclusive to a periodic callback.

**Observed codec contracts:**

- AHX files use CRI's `(c)CRI` marker, version `0x06`, one channel, and type
  `0x10` or `0x11`. No encrypted AHX file was observed.
- ADX files use type `0x03`, an 18-byte frame, 4-bit samples, two channels,
  24,000 Hz, a 500 Hz high-pass field, and version `0x04`. No encrypted ADX file
  was observed.
- 180 ADX files begin coded data at offset 40 and have no loop block: all 173
  `STREAM.AFS` files and seven `SOUND.AFS` files. The other 66 are looped tracks,
  all under `SOUND.AFS.files/000.afs.files`.

The maintained inventory's numeric `.adx` names were assigned by a shallow
`(c)CRI` signature check. The parsed header fields establish the codec profile;
the filename extension does not. The exact container/index/offset/length map
remains in [`media/afs_members.tsv`](media/afs_members.tsv).

### AHX frame, terminator, and fit contract

All 9,068 AHX members have the same 36-byte wrapper shape: coded data begins at
offset 36, the wrapper reports one channel, version `0x06`, and no encryption,
and `(c)CRI` ends at offset 36. Every coded frame begins with the four bytes
`FF F5 E0 C0`. That is an AHX-specific MPEG Layer II header which advertises a
nominal `0x414`-byte frame, but AHX removes unused frame padding and stores
variable-length frames. Boundaries must be derived by parsing the 30 allocation
values, scalefactor-selection fields, scalefactors, and quantized samples. A
plain search for the next four-byte header is unsafe because that value can
occur inside the coded payload.

The complete corpus parses without a missing or extra frame. In every file:

```text
frame_count = ceil(wrapper_sample_count / 1152)
file_size   = 36 + sum(syntax-derived frame sizes) + 17
```

The final frame therefore represents between 0 and 1,151 padded samples. The
17-byte terminator is identical in every file. Its leading zero is outside the
last syntax-derived frame:

```text
00 80 01 00 0C 41 48 58 45 28 63 29 43 52 49 00 00
               A  H  X  E  (  c  )  C  R  I
```

Observed encoded-frame distributions are:

| AHX type | Files | Frames | Actual frame bytes | Median | Mean |
| --- | ---: | ---: | ---: | ---: | ---: |
| `0x10` | 1,556 | 107,420 | 395–440 | 408 | 410.115 |
| `0x11` | 7,512 | 404,151 | 14–440 | 407 | 393.706 |

The 30 allocation widths are four bits for bands 0–3, three bits for bands
4–10, and two bits for bands 11–29. All 107,420 type-`0x10` frames use one
allocation vector:

```text
6 6 6 6  4 4  3 3 3 3 3 3  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
```

Type `0x11` is adaptive. Of its 404,151 frames, 305,434 use that default vector
and 98,717 use one of 42,156 other vectors. That includes 3,624 all-zero
allocation frames whose complete syntax is only 14 bytes. Type `0x10` therefore
stays in a narrow, comparatively large range while type `0x11` can collapse
quiet frames to very small payloads. AHX size is content-dependent even when
sample count is unchanged; unlike ADX, target fit cannot be predicted from
duration alone. The two types are not interchangeable space-saving presets.

**Inferred AHX fit hypothesis:** target-matched content is mono PCM at 24 kHz
(except for the documented 48 kHz outlier), with padding or cropping accounting
for the target sample count. Its encoded profile would retain the exact AHX
type, version `0x06` and unencrypted wrapper. Structural fit depends on every
variable-length frame parsing correctly, the fixed terminator being present,
and the complete encoded size fitting the AFS slot after encoding. Arbitrary
bytes after the terminator are outside this observed contract.

A shorter leaf could retain its slot by changing its AFS length and clearing
the unused remainder. Type `0x11` additionally depends on adaptive allocation
that fits that slot; structurally valid fixed allocation alone is insufficient.
Independent decoding can establish channel count, rate, sample count, timing
and waveform, but those comparisons do not establish native decoder acceptance.

### ADX history, loop, and footer contract

The version-4 header stores two signed big-endian predictor-history samples per
channel (`AdxV4History.predictor1_be` and `predictor2_be`, two rows beginning at
header byte `0x18`). They are active decoder state, not generic
reserved zeros. Ten NA2 ADX files have a nonzero history: one of the 66 looped
`SOUND` tracks, one non-looped `SOUND` cue, and eight `STREAM` cues. A different
waveform therefore needs history values produced from that waveform; copying a
target's nonzero values can alter its first decoded samples.

For every extended-header file, the 24-byte `AdxV4LoopBlock` beginning at header
byte `0x20` has these big-endian fields:

| Field | Bytes | Observed role |
| --- | ---: | --- |
| `padding_be` | 2 | Encoder loop padding, observed range 0–31 |
| `marker_be` | 2 | Loop marker, always 1 |
| `count_type_be` | 4 | Loop count/type flag, always 1 |
| `start_sample_be` | 4 | Loop-start sample |
| `start_offset_be` | 4 | Loop-start file offset |
| `end_sample_be` | 4 | Loop-end sample |
| `end_offset_be` | 4 | Loop-end file offset |

All 66 satisfy `0 <= loop_start < loop_end <= total_samples`; every loop start
is a multiple of 32 samples. With 18 bytes per channel frame, two channels, and
32 samples per frame, their stored byte positions satisfy exactly:

```text
loop_start_offset = data_start + (loop_start_sample / 32) * 36
loop_end_offset   = data_start + ceil(loop_end_sample / 32) * 36
```

Every loop-start offset is also a multiple of `0x800`. The encoder selected a
variable `data_start` from 96 through 2,096 bytes to make that true. Bytes from
the end of the loop block through the six-byte `(c)CRI` marker at
`data_start - 6` are zero; no `AINF` or other auxiliary header is present.

The coded-body size is content-independent for a fixed sample count:

```text
coded_bytes = ceil(total_samples / 32) * 18 * 2
```

It is followed in every file by `80 01`, a big-endian 16-bit zero-padding
length, and exactly that many zero bytes. The 180 non-looping files use 14 zero
bytes, making an 18-byte footer. The 66 looped files use a longer footer so the
complete declared AFS member length is a multiple of `0x800`. All 246 files
match the header/body/footer formula exactly.

**Inferred ADX fit hypothesis:** the target profile is 24 kHz stereo, type
`0x03`, frame size 18, 4-bit depth, 500 Hz cutoff and version `0x04`.
Padding or cropping to the target sample count makes coded-body fit predictable
independently of waveform. Retaining loop sample semantics with new content
would require byte positions derived from the generated `data_start`, initial
histories derived from the new waveform, and a `0x8001` footer giving the target
member length. Independent decoder round-tripping can establish encoded format
and waveform; acceptance by `CRI_ADXI.IRX` remains unproved.

CriCodecs 1.2.0 encoded the inspected non-looped and looped cases to the exact
target length and preserved the looped case's sample and byte positions. It did
not reproduce two opaque-but-live version-4 fields. Re-encoding
`STREAM.AFS.files/039.adx` changed all four nonzero predictor histories from 6
to 0 and measurably changed its first decoded samples. Re-encoding
`SOUND.AFS.files/000.afs.files/001.adx` changed the loop-padding field at
`0x20` from `0x0013` to zero while keeping its other reported loop metadata.
The inspected CLI output therefore leaves two acceptance questions open:
correct generation of those fields, or evidence that their differences are
irrelevant to the native decoder.

### Fixed-slot replacement model

**Observed:** every non-empty AFS member begins on a `0x800` boundary. Each AFS
also has one 48-byte `AfsFilenameDirectoryEntry` per declared index.
`AfsMemberEntry.offset` and `size` describe its member. The space from a
member offset to the next occupied member offset (or to the attributes table
for the last member) is its available slot. Observed unused space ranges from
0 to 2,047 bytes.

**Inferred fixed-slot feasibility:** the member identity is the top-level
archive, nested AFS index and leaf index in `media/afs_members.tsv`; a null index
has no payload to substitute. The hypothesis depends on matching codec type,
channels, rate, version, encryption and relevant ADX loop fields from the header,
with a complete encoded leaf no larger than its existing slot.

For a shorter leaf, only `AfsMemberEntry.size` would differ and the unused slot
would be cleared. Offsets, alignment, index order, null entries, archive length,
every 48-byte attributes row and all non-target payloads would remain identical.
An unchanged inner-archive length leaves its containing AFS offset and length
unchanged; the same argument applies outward to the top-level archive. This
establishes a possible layout-preserving substitution, not acceptance of a
generated archive by the game's loader.

A leaf larger than its slot invalidates this hypothesis. Shorter content or a
smaller encoding with the same profile could fit. Moving later members or
rebuilding the archive is a distinct, unestablished hypothesis that also depends
on retaining the AFS variant, opaque attributes and outer size.

### Candidate tools

These are capability observations from the recorded release/source inspection
and bounded experiments, not claims about every release or every NA2 member.

- [CriCodecs](https://github.com/Youjose/CriCodecs) 1.2.0 supplied a baseline
  for the recorded experiments, but its output did not cover every NA2 profile. Its
  documented CLI supports WAV-to-AHX/ADX and both AHX modes. A checksum-verified
  Windows release was tested against clean NA2 members. Generated type `0x10`
  and `0x11` files retained wrapper metadata and decoded to the declared PCM
  length; non-looped and looped ADX retained their primary format metadata, and
  the looped case retained exact loop samples and byte positions. The ADX
  history and loop-padding exceptions are documented above.

  The inspected CriCodecs AHX encoder applies one fixed allocation profile to every
  frame. It also prepends a 480-sample delay for mode `0x11`; 3,088 of NA2's
  7,512 type-`0x11` files would cross an additional 1,152-sample frame boundary
  under that policy. In the decisive silent case
  `RPGVOICE.AFS.files/044.afs.files/031.adx`, the clean 24,000-sample member is
  347 bytes (21 all-zero 14-byte frames), in a `0x800`-byte slot. Re-encoding
  its decoded silence with CriCodecs produced 8,743 bytes and 22 fixed-profile
  frames. It round-tripped to 24,000 silent samples but cannot fit that target.
  Runtime acceptance by `CRI_ADXI.IRX` is also still untested.
- [FFmpeg's ADX encoder](https://github.com/FFmpeg/FFmpeg/blob/master/libavcodec/adxenc.c)
  was not a direct NA2 writer in the inspected source: it emits a fixed 36-byte,
  version-3, non-looping header and an 18-byte standard terminator. The muxer
  can backfill total sample count, but it does not supply NA2's version-4
  histories or extended loop block. **Inference:** reuse of its ADPCM core
  would depend on a separate NA2-aware header/footer writer, whose feasibility
  and acceptance are unestablished.
- [vgmstream](https://github.com/vgmstream/vgmstream) supplied a candidate for
  independent decoding/metadata comparison in the recorded tool review. Its
  [AHX parser](https://github.com/vgmstream/vgmstream/blob/master/src/meta/ahx.c)
  distinguishes types `0x10` and `0x11`, while its
  [ADX parser](https://github.com/vgmstream/vgmstream/blob/master/src/meta/adx.c)
  exposes version, frame, loop, and encryption variants.
- [AFSLib](https://github.com/MaikelChan/AFSLib) and
  [AFSPacker](https://github.com/MaikelChan/AFSPacker) document configurable
  AFS alignment and attributes. The maintained extraction lacks AFSPacker's
  variant metadata, so an apparently valid rebuild could alter opaque attributes
  or layout. This limits the rebuild hypothesis; it does not establish a safe
  alternate archive writer.

The historical tools under `@tools/old/` are reference material, not maintained
or trusted build dependencies.

The recorded offline experiments used CriCodecs 1.2.0 and FFmpeg 9.0.1. An
exact-size synthetic `LOGO_C.PSS` passed static checks of its 90-picture MPEG-2
stream, replacement PCM body, packet lattice, timestamps, padding and complete
decode. This establishes bounded offline feasibility only.

## PSS movies

### Resident selector and dormant descriptor rows

`movie_descriptors` at live `0x00400AF0` contains 12 `MovieDescriptor` rows,
more than the ten-file ISO population:

| Index | Descriptor filename | ISO file | Statically recovered direct selector |
| ---: | --- | --- | --- |
| 0 | `logo_c.pss` | `PSS/LOGO_C.PSS` | Resident startup |
| 1 | `notice.pss` | `PSS/NOTICE.PSS` | None found |
| 2 | `opening.pss` | `PSS/OPENING.PSS` | Resident startup |
| 3–9 | `da2200.pss` through `da3999.pss` | Corresponding shipped files | Collection movie viewer and Master Mode |
| 10 | `logo_cT.pss` | **Absent** | None found |
| 11 | `openingT.pss` | **Absent** | None found |

`movie_filename_logo_c_t` and `movie_filename_opening_t` name the two strings.
`movie_descriptor_logo_c_t` matches row 0 field-for-field except for its
filename pointer; `movie_descriptor_opening_t` likewise matches row 2.

`movie_select_descriptor` selects by numeric ID without a suffix-selection
branch; a T row requires ID 10 or 11. `opening_update` uses IDs 0 and 2 through
`movie_play_with_flags`. The Collection movie viewer (`ccHomeIspMovie`) lists
all seven `replay_movie_map` records, IDs 3–9. `collection_movie_confirm`
admits an entry only once the save marks it unlocked, and
`replay_play_selected_movie` then plays it through resident blocking
`movie_play`. Master Mode plays the same seven movies.

**Observed:** `logo_cT.pss` and `openingT.pss` are real descriptor-table entries,
not omitted members of the shipped ISO inventory, and no recovered direct path
selects IDs 10 or 11. Cross-game meaning of the suffix is unestablished.

**Supported conclusion:** the two rows are dormant in the recovered direct-call
graph. The meaning of `T`, why the rows were retained, and computed indirect
consumers remain unresolved. The absent files leave their loader and disc-layout
behavior unestablished.

### Descriptor-authored geometry, transitions, and subtitles

The descriptor contains playback metadata outside the PSS.
`movie_play_descriptor` copies `MovieDescriptor.x/y/width/height` into signed
16-bit renderer fields and opens `filename`. With the decoded frame from
`mpeg_get_movie_frame`, the early transition begins strictly after
`early_frame`, the late transition at or after `late_frame`; each uses twice
its corresponding duration. A frame value of `-1` disables that transition.

For IDs outside `3..9`, including startup ID 2 `opening`, blocking playback
calls `mpeg_poll_movie_input` before its per-frame yield and decoder-completion
poll. Three native masks set `MpegMoviePlayer.stop_requested`, then set and
clear `pause_requested`. The player is reached through resident global
`mpeg_movie_player_ptr`.
A `0` to `1` transition of `stop_requested` across that call identifies a
native input-driven stop request while retaining the accepted-button policy.

The complete clean-row values are:

| ID / movie | `x, y, width, height` | Early frame / duration | Late frame / duration | Resident subtitle schedule |
| --- | --- | ---: | ---: | --- |
| 0 `logo_c` | `0, 0, 512, 448` | disabled | disabled | None |
| 1 `notice` | `0, 0, 512, 448` | disabled | disabled | None |
| 2 `opening` | `0, 0, 512, 448` | disabled | disabled | None |
| 3 `da2200` | `0, 20, 512, 352` | `0 / 15` | `6123 / 20` | 21 entries, frames 1372–4634 |
| 4 `da2255` | `0, 20, 512, 352` | `1 / 15` | `3645 / 20` | 6 entries, frames 418–3219 |
| 5 `da3195` | `0, 20, 512, 352` | `1 / 15` | `2105 / 20` | 4 entries, frames 450–1082 |
| 6 `da3210` | `0, 20, 512, 352` | `0 / 15` | `741 / 20` | 4 entries, frames 121–575 |
| 7 `da3235` | `0, 20, 512, 352` | `0 / 15` | `2703 / 20` | 11 entries, frames 23–2715 |
| 8 `da3250` | `0, 20, 512, 352` | `0 / 15` | `5741 / 20` | 29 entries, frames 29–5581 |
| 9 `da3999` | `0, 0, 512, 448` | `0 / 15` | `6447 / 20` | None |
| 10 `logo_cT` | `0, 0, 512, 448` | disabled | disabled | None |
| 11 `openingT` | `0, 0, 512, 448` | disabled | disabled | None |

For IDs 3–8, `subtitles_enabled` is 1 and `movie_subtitle_schedules` selects
`movie_subtitles_da2200`, `movie_subtitles_da2255`, `movie_subtitles_da3195`,
`movie_subtitles_da3210`, `movie_subtitles_da3235` or `movie_subtitles_da3250`.
Each array consists of `MovieSubtitleRow` `{start_frame, end_frame, text}`
triples ending with `{-1, -1, 0}`. `movie_update_subtitles` advances by decoded
frame, fades each entry, and draws CP932 text near the bottom through
`font_draw_centered_text`. ID 9 has neither the gate nor an array; all other
schedule pointers are null.

**Replacement consequence:** matching PSS byte size alone does not preserve
geometry, frame count/rate, subtitles or transition timing. Different content
for `DA2200` through `DA3250` retains original Japanese captions; different
duration retains the old late transition frame. Such content must account for
the descriptor's late frame and different schedule/text or a cleared
`subtitles_enabled` gate; the PSS cannot supply those changes. Static evidence
establishes these consumers and layouts, while playback acceptance remains open.

**Inferred resident-data feasibility:** different late-transition timing and
caption content would depend on changed resident frame/schedule/text data or a
cleared `subtitles_enabled` gate. Such a hypothesis also depends on clean-byte
preconditions and evidence of the resulting playback behavior. No accepted
generated content is established by this trace.

### Observed stream contract

All ten movies are MPEG-2 program streams. Each begins with a pack header
(`0x000001BA`) and contains video PES packets (`0xE0`), private-stream audio
packets (`0xBD`), and padding packets (`0xBE`). More specifically, each file is
exactly `N * 0x4000 + 4` bytes. A 14-byte pack header starts at every `0x4000`
boundary, the first pack alone also has a 15-byte system header (`0xBB`), and
the four-byte program end code `0x000001B9` starts at the final `0x4000`
boundary. That end-code boundary is also `0x800`-aligned; the file length adds
its four-byte tail. `0x4000` is the actual program-stream pack lattice.

Within an ordinary pack, the header plus four PES packets fill exactly
`0x4000` bytes. Pack-leading PES packets have a `4076`-byte declared length and
the other `0x1000` slots have a `4090`-byte length. The first video packet is
shorter by the one-time system-header size. Terminal partial stream packets and
`0xBE` packets filled with `0xFF` occupy the remaining tail while preserving
the next pack boundary. A sequential length-driven parse reaches the program
end exactly for every file; no byte scan or guessed delimiter is required.

Every private audio PES payload begins with `FF A0 00 00`. Removing that
four-byte per-packet header and concatenating the remainder produces one
`SShd` chunk followed by one `SSbd` chunk. Their numeric fields are
little-endian. Every movie reports format 1, 48,000 Hz, two channels,
`0x200`-byte interleave, and loop start/end `0xFFFFFFFF`. The `SSbd` body is
signed 16-bit little-endian PCM arranged as alternating `0x200`-byte
single-channel blocks: 256 samples of channel 0, 256 samples of channel 1, and
so on. It is not sample-interleaved WAV order, ADX, or PlayStation ADPCM. Each
declared body is a whole number of `0x400`-byte stereo superblocks and therefore
contains `body_bytes / 4` samples per channel.

| Movie | Total bytes | Video sequence | Header aspect | Sequence bit rate | PCM body bytes |
| --- | ---: | --- | --- | ---: | ---: |
| `DA2200.PSS` | 142,704,644 | 512×352 at 30000/1001 fps | 4:3 | 4,000,000 | 39,392,256 |
| `DA2255.PSS` | 100,401,156 | 512×352 at 30000/1001 fps | 4:3 | 5,000,000 | 23,485,440 |
| `DA3195.PSS` | 49,381,380 | 512×352 at 30000/1001 fps | 4:3 | 4,000,000 | 13,650,944 |
| `DA3210.PSS` | 17,743,876 | 512×352 at 30000/1001 fps | 4:3 | 4,000,000 | 4,908,032 |
| `DA3235.PSS` | 63,307,780 | 512×352 at 30000/1001 fps | 4:3 | 4,000,000 | 17,482,752 |
| `DA3250.PSS` | 134,266,884 | 512×352 at 30000/1001 fps | 4:3 | 4,000,000 | 37,066,752 |
| `DA3999.PSS` | 150,224,900 | 512×448 at 30000/1001 fps | 1:1 | 4,000,000 | 41,467,904 |
| `LOGO_C.PSS` | 2,179,076 | 512×448 at 30000/1001 fps | 4:3 | 4,000,000 | 672,768 |
| `NOTICE.PSS` | 4,931,588 | 512×448 at 30000/1001 fps | 4:3 | 5,000,000 | 1,152,000 |
| `OPENING.PSS` | 72,974,340 | 512×448 at 30000/1001 fps | 1:1 | 5,000,000 | 17,059,840 |

“Header aspect” is the MPEG sequence field, not a conclusion about how the game
ultimately displays the frame. A target-matched aspect field is the conservative
fit hypothesis; support for another value is unestablished.

`DA2200.PSS` has one original-file exception: its `SSbd` declares 39,392,256
body bytes, but concatenating all private-stream payloads yields the 40 bytes of
chunk headers plus only 39,392,230 body bytes. It is short by 26 bytes. The
physical tail is already zero, so the absent portion would only extend silence,
but the mismatch is part of the observed source contract. The other
nine files provide exactly `40 + declared_body_bytes` logical audio bytes.

The video elementary-stream and resident end-timing census is:

| Movie | `0x4000` packs | Video ES bytes | Pictures / GOPs | Resident late transition |
| --- | ---: | ---: | ---: | --- |
| `DA2200.PSS` | 8,710 | 102,474,544 | 6,144 / 410 | frame 6,123; 21 pictures before end |
| `DA2255.PSS` | 6,128 | 76,326,381 | 3,661 / 245 | frame 3,645; 16 pictures before end |
| `DA3195.PSS` | 3,014 | 35,441,915 | 2,126 / 142 | frame 2,105; 21 pictures before end |
| `DA3210.PSS` | 1,083 | 12,719,743 | 762 / 51 | frame 741; 21 pictures before end |
| `DA3235.PSS` | 3,864 | 45,450,345 | 2,724 / 182 | frame 2,703; 21 pictures before end |
| `DA3250.PSS` | 8,195 | 96,418,584 | 5,781 / 386 | frame 5,741; 40 pictures before end |
| `DA3999.PSS` | 9,169 | 107,879,863 | 6,468 / 432 | frame 6,447; 21 pictures before end |
| `LOGO_C.PSS` | 133 | 1,475,181 | 90 / 7 | Disabled |
| `NOTICE.PSS` | 301 | 3,731,602 | 180 / 13 | Disabled |
| `OPENING.PSS` | 4,454 | 55,491,310 | 2,662 / 178 | Disabled |

All elementary streams end exactly with MPEG sequence-end code `0x000001B7`.
They use MPEG-2 Main Profile at Main Level (`profile_and_level_indication`
`0x48`), 4:2:0 chroma, default quantization matrices, VBV size value 112, and
GOPs of at most 15 pictures. A full 15-picture GOP contains one I, four P, and
ten B pictures. Sequence, sequence-extension, and GOP headers repeat at every
GOP. The first GOP is closed and no GOP has `broken_link`; `DA2255` has one
additional closed GOP.

Nine movies declare an interlaced sequence and frame pictures with
`top_field_first = 0`, `repeat_first_field = 0`, `progressive_frame = 0`,
`frame_pred_frame_dct = 0`, and `alternate_scan = 1`. `NOTICE.PSS` is the sole
exception: both its sequence and pictures are progressive, with
`frame_pred_frame_dct = 1`, `chroma_420_type = 1`, and the same alternate scan.

PES timing is authored, not a fixed file-offset decoration. Every video PES has
the optional-header introducer `0x83` and a ten-byte optional-header area,
except for the initial packet's 13-byte area. Packets that begin a relevant
access unit carry PTS only for B pictures or PTS plus DTS for I/P pictures;
continuation packets carry neither. In coded order, video PTS deltas therefore
include `-6006`, `+3003`, and `+12012` ticks. Audio carries a PTS in every PES,
normally advancing by 1,902–1,910 ticks. Pack SCR values also include repeated
values, and four small backwards steps exist across `DA2255`, `DA3210`, and
`DA3999`; requiring simple monotonicity would reject clean originals.

The main `program_mux_rate` is 13,840 for the 4 Mbit/s targets and 16,340 for
the 5 Mbit/s targets, exactly matching the nominal video rate plus 1.536 Mbit/s
PCM in MPEG's 50-byte/s units. A small number of audio-only packs use 3,840.
The initial system-header rate bound changes with the same two target classes.

Audio timestamps have an exact byte-counter relationship in all ten clean
files. Let `logical_byte_offset[i]` be the number of concatenated private-audio
bytes before packet `i`, after removing each packet's four-byte `FF A0 00 00`
subheader but including the 40 bytes of `SShd`/`SSbd` headers. Then:

```text
audio_pts[i] = audio_pts[0]
             + floor((logical_byte_offset[i] * 15 + phase) / 32)
```

Each file has one fixed integer `phase`: 27 for `DA2200`, 13 for `DA2255`, 13
for `DA3195`, 30 for `DA3210`, 25 for `DA3235`, 29 for `DA3250`, 21 for
`DA3999`, 26 for `LOGO_C`, 5 for `NOTICE`, and 26 for `OPENING`. The factor
`15/32` is exactly 90,000 timestamp ticks divided by the 192,000 logical PCM
bytes per second. This formula reproduces every audio PES PTS exactly, including
the otherwise surprising treatment of the 40 chunk-header bytes as part of the
counter. It allows a writer to validate regenerated timestamps without
mistaking the observed 1,902–1,910-tick steps for arbitrary jitter.

For all seven `DA` movies and `OPENING`, the first audio PTS is 6,006 ticks
(two nominal video frames) before the first video PTS; `LOGO_C` and `NOTICE`
start both streams at the same PTS. PCM duration is not simply video picture
count divided by frame rate: the seven `DA` audio bodies extend 0.137–0.166
seconds past that duration, while `LOGO_C` extends 0.501 seconds, `NOTICE` is
0.006 seconds shorter, and `OPENING` extends 0.031 seconds. The target PCM
sample count and initial stream offset are therefore independent constraints;
neither follows from video duration alone.

### Replacement paths

**Inferred packet-skeleton hypothesis:** an in-place stream could retain an
original's `0x4000` pack lattice, stream-slot order, pack SCR values,
pack/system rate fields and total size. Video would retain target dimensions,
frame rate, aspect, coding flags, GOP shape, picture count and rate ceiling.
Audio would retain signed 16-bit stereo PCM at 48,000 Hz, the declared sample
count and alternating `0x200`-byte channel blocks rather than sample-interleaved
WAV order. This is a constrained feasibility hypothesis, not an established
retail writing method.

Different compressed picture sizes move access-unit boundaries, so PTS/DTS
belong to the new picture starts rather than the old file offsets. Reuse of the
target timestamp sequence depends on corresponding picture/GOP order. Exact
audio sample count permits target-matched audio PTS and slot timing.
A possible terminal layout uses valid `0xBE` padding for exhausted stream
capacity, with a split final stream packet within its pack where needed and
the program-end code retained. Either stream exceeding available capacity
invalidates this fit hypothesis. For `DA2200.PSS`, retaining the original
26-byte zero-tail omission and adjusting its terminal packet are separate
possibilities; acceptance of an adjustment is unproved. No purpose-built
parser/writer or native playback acceptance is established.

**Inferred full-mux hypothesis:** a newly muxed PS2-style stream could preserve
the stream IDs, `SShd`/`SSbd` PCM contract, `0x4000` pack lattice, disc alignment,
timing behavior, valid padding and exact outer size. It permits more extensive
content changes but has more unestablished behavior than the skeleton
hypothesis. The bounded tool review found no maintained open-source creator
that supplied the complete PSS video/audio contract of NA2's movies.
[PssMux](https://github.com/wagrenier/PssMux) injects audio from one PSS into
another; it does not create the complete target stream.
[PSSpectrum](https://github.com/Ailyth99/PSSpectrum) delegates creation to the
proprietary PS2STR tool.
[PS2-PSS-Tools](https://github.com/Silentwarior112/PS2-PSS-Tools) also documents
a PS2STR-based approach rather than an open muxer, and its published recipe
targets compressed PS2 ADPCM rather than NA2's observed 48 kHz
`SShd`/`SSbd` PCM. None of these observations closes the muxer gap.

Arbitrary appended bytes are outside the PSS syntax. Padding is valid only
before the program-end code. Lower bit rate or shorter content are possible
capacity hypotheses when a stream exceeds the target length; shorter content
also changes the duration constraint. ISO/UDF relocation and variable-size
replacement are disc-image mechanisms outside this format research.

## Evidence and acceptance limits

### Audio

The established target contract includes codec type, channels, sample rate,
sample count, version, loop fields and encryption state. The fixed-slot
hypothesis additionally depends on unchanged offsets, null indices, non-target
payloads, attributes, alignment and outer length throughout the nested AFS
tree. Independent decode comparison and recursive archive parsing can establish
those properties; they do not establish acceptance by the bundled CRI driver.
Clean-base ISO record position and size are image-assembler concerns rather
than additional codec facts.

The bounded codec experiments do not establish full-file completion and
repetition for generated cues, or the absence of silence, truncation, pitch/rate
errors, adjacent-cue corruption and archive-load failures. Those are open
acceptance questions, not observed failures.

### Movies

The clean corpus establishes legal pack/PES lengths, marker bits, stream IDs,
SCR/PTS/DTS cadence, every `0x4000` pack boundary, final program-end code and
exact outer length. Simple PTS or SCR monotonicity is not its contract.
Independent complete decoding can characterize frame count, GOP/picture flags,
PCM duration, block interleave, A/V synchronization and decoder errors, as in
the bounded synthetic `LOGO_C.PSS` experiment. It cannot by itself establish
acceptance by the bundled movie driver.

Generated startup and story-triggered playback remain separate open questions,
including normal completion and native skip behavior. Real-hardware
disc-streaming bandwidth is also unestablished. No emulator operation or
acceptance procedure follows from these static findings.

## Remaining unknowns

- Which encoder or CriCodecs change can reproduce NA2's adaptive type-`0x11`
  allocations and timing closely enough to fit the target slot and satisfy the
  bundled CRI driver. CriCodecs 1.2.0's fixed allocation and extra 480-sample
  pre-roll do not cover the full corpus.
- The exact writer-side derivation and runtime significance of ADX version-4
  predictor histories and `AdxV4LoopBlock.padding_be`; CriCodecs 1.2.0
  currently zeroes both in inspected cases.
- The exact timestamp-generation policy and decoder tolerance needed when a
  newly encoded stream's compressed picture sizes move access-unit boundaries.
- A maintained PSS writer and the exact progressive-plus-alternate-scan encode
  path for `NOTICE.PSS` remain open. No generated AFS or PSS has established
  acceptance by the bundled CRI/movie drivers in PCSX2 or on hardware.
