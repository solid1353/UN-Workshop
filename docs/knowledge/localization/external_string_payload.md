# External localization payloads

The official UN5 localization files and the native NA2 loader and memory
boundary.

## Research coverage

Established: UN5 indexed MWO3 localization images, language selection and
loading, NA2's table-selected PRG loader, and its structural memory boundary.
Names come from `@annotations/NA2` and `@annotations/UN5`; addresses are live.
Open: nothing.

## UN5 `TEXTENG.BIN`

The official English payload is a `0x30D00`-byte MWO3 data image. It mixes
zero-terminated strings with absolute in-image pointer tables that index whole
strings and interior fragments.
`english_localization_payload_start` (`0x008F3D40`) names its payload boundary.

The strings cover character and move names, menus, prompts, battle and Practice
help, conditions, collection text, story prose, and Save/Load messages. They
use an ASCII-compatible Western single-byte encoding with markup such as
`<br>` and `<color...>`. `english_localization_naruto_classic_name`
(`0x008F3E00`) is the first string in the data region.

The file declares zero BSS and an empty constructor interval. Its linked base
is `0x008F3D00`, and its complete image ends at `0x00924A00`. The inspected
image has no identified executable routines; its pointer tables and strings
form a structured localization payload.

Individual string relationships belong to
[NA2 and UN5 text correspondence](text_correspondence.md).

## Evidence

The retail NA2 (`SLPS-25837`) and UN5 inputs are identified in
[Retail game file identities](../game/files/file_identities.md).

The loader behavior and named data are resolved in the live-address MCP
programs. Complete-file header facts come from the original retail files:
the UN5 `TEXTENG.BIN` import omits its header from program memory.

## UN5 donor behavior

UN5 selects the following files through `locale_payload_filename_table`
(`0x005BB280`), whose filename block starts with
`locale_payload_filename_english` (`0x005BB228`):

| Locale index | Language | File |
| ---: | --- | --- |
| 0 | English | `TEXTENG.BIN` |
| 1 | French | `TEXTFRN.BIN` |
| 2 | German | `TEXTGER.BIN` |
| 3 | Italian | `TEXTITA.BIN` |
| 4 | Spanish | `TEXTSPA.BIN` |

`frontend_initialization_task` (`0x001E6B20`) begins localization through
`locale_initialize_from_system` (`0x003D3E50`). System language values 2, 4,
5 and 3 select locale indexes 1, 2, 3 and 4 respectively; every other value
selects English.

`locale_load_payload` (`0x003D3EF0`) clamps indexes outside 0..4 to English.
When the requested index differs from `frontend_locale`, it publishes the
requested index before loading and constructs a path from `locale_prg_prefix`
(`0x005BB298`), the selected filename and `locale_iso_version_suffix` (`;1`).
It repeatedly invokes `mwo3_read_image` (`0x00100300`) until a nonzero result,
then publishes the index in `locale_loaded_index`. An equal requested index
skips the read.

`frontend_locale_set` (`0x003D4000`) changes the requested index, clamped to
0..4, without loading. `locale_reload_payload` (`0x003D4040`) loads only when
the requested and loaded indexes differ and updates the loaded index after
success. `frontend_locale_index` (`0x003D4110`) returns the requested index
used by language-indexed accessors. Both indexes begin at -1 in the retail
ELF; initialization resets the loaded index before selecting the language.

Both load paths use `locale_payload_destination` (`0x0060FEE8`), initialized
to `0x008F3D00`. Changing the loaded language replaces the prior image at that
same address, so references into it do not retain the previous language's
text. This establishes a fixed destination and replacement lifetime, not an
independent allocation for each language.

`mwo3_read_image` accepts a positive read count, including a short read. It
then maintains caches, clears `Mwo3LoadHeader.bss_size` bytes immediately after
the bytes actually read, runs `constructor_begin` through `constructor_end`,
and returns 1. A nonpositive read yields 0 and causes the localization caller
to retry. Header identity, destination capacity and constructor bounds are
not validated on this path.

## MWO3 address convention

An MWO3 image starts with a `MWo3` header occupying its first `0x40` bytes.
The whole file loads at its live base; complete-file offsets map to that base
plus the offset, and the payload follows the header. Current disassembly
addresses are live. Historical imports are interpreted using
[Address conventions](../game/files/file_identities.md#address-conventions),
with code or data verified at the live location.

Absolute payload pointers and constructor bounds are linked addresses. The
observed loaders do not relocate them, so an image loaded at a different
destination keeps references to its linked addresses.
The broader loader interface is covered by [Overlay ABI](../runtime/overlay_abi.md).

## Native NA2 loader and memory boundary

`mwo3_load_file` (`0x001BE7F0`) selects its destination from
`overlay_destination_table` (`0x006029C0`), constructs
`cdrom0:\\PRG\\<filename>`, reads the file and invokes
`mwo3_initialize_image` (`0x00100270`). The retail table has slot 0 =
`0x00100000`, slot 1 = `0x006B3F00`, and slots 2..15 = zero.

The loader has no observed slot bounds check. It retries negative file
operations and reopens after a nonnegative short read; only an exact read
passes to image initialization, including an exact zero-length read. Image
initialization maintains caches, clears `Mwo3Header.bss_size` bytes after the
physical file, and processes its constructor interval without header or range
validation. A missing or misnamed file can therefore prevent the loader from
returning, and a truncated or malformed file is not rejected.

The retail ELF describes the resident image through `0x006B3F00`, mutually
exclusive overlays ending no later than `0x008DD080`, and a final zero-size
marker at `0x008DD080`. That boundary participates in several independent
parts of initialization:

| Owner | Boundary contract |
| --- | --- |
| `entry` (`0x00100008`) | Upper-exclusive startup zero-fill boundary and heap initialization start |
| `game_arena_initialize` (`0x00118730`) | Boundary used to calculate the arena request |
| `resident_heap_marker_initialize` (`0x005D6800`) | Writes `resident_upper_memory_marker` |
| `system_heap_break` (`0x003F78F4`) | Initialized break pointer |
| ELF program and section metadata | Retain the same boundary, including the final zero-size marker |

The boundary is materialized in code, initialized data and ELF metadata;
changing only one representation would leave the other consumers unchanged.
Memory ownership and capacity are covered by
[EE address space](../runtime/ee_memory_map/address_space.md).
