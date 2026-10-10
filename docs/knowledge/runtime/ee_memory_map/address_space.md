# EE address space

Static and runtime findings for the retail NA2 (`SLPS-25837`) EE address space.
All ranges are end-exclusive.

## Research coverage

Established: resident and overlay ranges, allocator boundaries, high-memory
ownership, large static buffers, and their relevant lifetimes.
Open: smaller-object ownership in `arena_low_boundary..audio_stereo_work_areas` and
`audio_common_append_handle..0x006B3F00`, and byte-level main-thread stack use.
Routine, structure and data names come from `@annotations/NA2`; addresses are live.

Allocator internals belong to [Allocator and capacity](allocator_and_capacity.md);
overlay lifetimes belong to [Runtime lifetimes](runtime_lifetimes.md).
The map combines program headers, startup ownership, all three overlay kinds,
allocator sentinels, the `malloc` layer, and sampled high-memory states.
Zero or stable bytes do not establish unused memory. The static-object map uses
absolute and `gp`-relative references, so objects reached only through computed
pointers can be merged into a neighbouring span.

## Address-space map

| Address range | Size | Native owner |
| --- | ---: | --- |
| `0x00000000..0x00100000` | `0x100000` | Low system/runtime region outside the NA2 ELF image. |
| `0x00100000..arena_low_boundary` | `0x507380` | Resident NA2 ELF code and static data. The load segment is RWX and contains six static thread stacks. |
| `arena_low_boundary..0x006B3F00` | `0xACB80` | Zero-filled resident ELF tail containing BSS, allocator globals, and other mutable state. |
| `0x006B3F00..0x008DD080` | `0x229180` | Shared MWo3 overlay window for `BTL.BIN`, `ADV.BIN`, and `ETC.BIN`. |
| `0x008DD080..0x008DD090` | `0x10` | `malloc` chunk header and alignment before the vanilla allocator sentinel. |
| `0x008DD090..0x01FF6000` | `0x1718F70` | Vanilla game allocator arena including both sentinels. |
| `0x01FF6000..0x01FF8000` | `0x2000` | Remainder of the `malloc` area above the arena. |
| `0x01FF8000..0x02000000` | `0x8000` | Main-thread stack. |

The vanilla allocator user base is `0x008DD0A0`; the end sentinel begins at
`0x01FF5FF0`. The overlay effective ends and phase-specific slack are documented
in [runtime lifetimes](runtime_lifetimes.md). The `malloc` layer and the
stack-placement inference are documented in
[the allocator document](allocator_and_capacity.md#system-memory-layer).

The executable's own program headers declare this layout. Segment 0 loads
`0x507380` file bytes at `0x00100000` with memory size `0x5B3F00`. Three
zero-file-size headers at `0x006B3F00` have memory sizes `0x229180`,
`0x213300`, and `0x30F00`, ending at `0x008DD080`, `0x008C7200`, and
`0x006E4E00`, which are the BTL, ADV, and ETC effective ends. A final empty
header marks `0x008DD080`. Startup `entry` (`0x00100008`) zero-fills
`arena_low_boundary..0x008DD080` and starts the `malloc` area at `0x008DD080`.

## Large static objects in the zero-filled range

| Object or span | Size | Owner |
| --- | ---: | --- |
| `arena_low_boundary..0x006073C8` | `0x48` | Allocator, placement-scope, and secondary-pool globals |
| `arena_low_free_bins`, `arena_high_free_bins`, `arena_low_large_gap_sentinel`, `arena_high_large_gap_sentinel` | `0x1020` | Two allocator free-bin families and their large-gap sentinels |
| `audio_stereo_work_areas` | `0x545AC` | Three `0x1C1E4`-byte stereo ADX stream-player work areas |
| `audio_mono_work_areas` | `0x34B6C` | Three `0x11924`-byte mono ADX stream-player work areas |
| `audio_mono_buffers` | `0x9000` | Three `0x3000`-byte buffers attached to the mono players |
| `progressive_text_buffer` | `0x200` | Short-string buffer of `text_draw_progressive` (`0x00379FE0`) |

The startup sound controller is a `0x718`-byte heap owner retained through
`audio_stream_manager_ptr` (`afs_manager_allocate`, `0x001D7A30`). Its six
players retain the static backing above through `AudioStreamManager.music_work0..2`,
`mono_work0..2` and `mono_buffer0..2` (`audio_stream_manager_construct`,
`0x001D66B0`; `audio_players_initialize`, `0x001D6810`). The stereo/mono
channel counts are 2/1 (`audio_adxt_create_with_hooks`, `0x00133B88`);
`adxt_library_banner` (`0x005B75B8`) identifies `ADXT/PS2EE Ver.9.69`.
**Inference (high confidence):** these `0x92120` bytes, about 585 KiB, are
permanent streaming-audio work memory and are never reusable.

## Heap-relative rendering state

In retail NA2, the persistent rendering state's horizontal scale field is at
`0x00AF3694`, the first `1.0f` field in the stable structure context
`0000BF01 00000000 00000045 FFFFFF44 0000803F 0000803F 00008043 00004043`.
The structure is allocated at a fixed displacement from the heap boundary, so
its absolute address is not a permanent game constant and moves with that
boundary.
