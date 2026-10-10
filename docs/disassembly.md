# Disassembly

Workshop keeps a Ghidra analysis of every registered game program under
`@disassembly`, and the annotations that name and type it under
`@annotations`. Agents read both through [GhidrAssistMCP](runbooks/ghidrassistmcp.md).

## Analysis trees

Each `@disassembly/<game>/` is one read-only tree with the import of the retail
programs and Ghidra's own analysis. Annotations are never stored in it; the
MCP applies them when it opens the project. It contains:

- `ghidra/<game>.gpr`, `<game>.rep`: one Ghidra project with the game's programs;
- `exports/<program>/`: the decompiled C (`.c`), the listing (`.txt`), and an
  `export.complete` marker;
- `summaries/<program>.tsv`: program identity, layout, and function and
  instruction counts;
- `manifest.tsv`: one row per program with its source, SHA-256, format, load
  base, counts, export sizes, and Ghidra version.

[`targets.tsv`](../scripts/ghidra/targets.tsv) lists every program with its
source and expected SHA-256.

## Addresses

EE Ghidra addresses are live runtime addresses. An MWO3 overlay loads whole, its
`0x40`-byte header at the header's base address, so the import maps the payload
after the header at that base plus `0x40`. The import also maps zero-filled
memory without file bytes, such as an ELF's BSS, as uninitialized blocks, so
globals there can be annotated. Annotations and documentation cite live
addresses only. Relocatable IOP ELFs are imported at module-relative base zero;
that base does not establish their live IOP placement. Cite their qualified
program/symbol names until a live relocation base is established.

## Rebuilding

Run every command with `UN_TASK_WORK_ROOT` set to the task's work directory:

```powershell
& .\scripts\ghidra\import_targets.ps1 -Target <game>
& .\scripts\ghidra\export_project.ps1 -Target <game>
& .\scripts\ghidra\set_analysis_readonly.ps1
```

`import_targets.ps1` verifies each source hash and imports and analyzes the
programs; `-Program <name> -ReanalyzeExisting` reanalyzes one existing program,
and `-Program <name> -Reimport` replaces it with a fresh import.
`export_project.ps1` exports the tree and writes its manifest. Annotation
changes never require either.

### Embedded IOP modules

An `iop_elf` row can select an embedded image using `source_offset`,
`source_size` and `container_sha256` in `targets.tsv`. `expected_sha256`
then covers the selected image. The maintained input reader verifies both
hashes, the exact range, the little-endian MIPS IOP ELF header and its single
zero-based load segment before importing anything. The importer writes the
verified member only inside its disposable task runtime, imports it through
Ghidra's ELF loader and includes its uninitialized memory tail. It removes
the runtime afterward. The source archive remains unchanged.

The shared programs `MODMIDI.IRX` and `MODHSYN.IRX` select the NA2
`MODULES.BIN` members at file offsets `0x30000` and `0x35800`, respectively.
Their exact image sizes and hashes are in `targets.tsv`; they are separate
from the existing first-member `MODULES.BIN` program. Export both before
publishing the manifest:

```powershell
& .\scripts\ghidra\import_targets.ps1 -Target shared -Program MODMIDI.IRX
& .\scripts\ghidra\import_targets.ps1 -Target shared -Program MODHSYN.IRX
& .\scripts\ghidra\export_project.ps1 -Target shared `
    -Program MODMIDI.IRX,MODHSYN.IRX -RestartMcp
```

Import/export temporarily permits Ghidra access to project files and restores
read-only attributes. The manifest records each image's bytes, source offset
and container hash. `-RestartMcp` restarts the shared host after a successful
export/manifest publication so its startup program inventory includes the
new programs; explain the interruption to concurrent researchers beforehand.

## Annotations

`@annotations/<game>/` is tracked in Git and is the only place annotations are
edited:

- `types.h`: C struct, union, enum, and typedef declarations shared by the
  game's programs.
- `<program>/symbols.tsv`: one row per live address with the columns `address`,
  `kind`, `name`, `type`, and `comment`.

| Kind | Applied as |
| --- | --- |
| `function` | Function name, creating the function if Ghidra missed it; `type` is its prototype; `comment` is its plate comment |
| `label` | Primary label; `comment` is an end-of-line comment |
| `data` | Primary label with `type` applied as its data type; `comment` is an end-of-line comment |

Each annotation replaces the name Ghidra generated, which stays at the address
as a secondary label. A missing file means the game or program has no
annotations.

Agents record annotations through the MCP `annotate_symbol` and `annotate_type`
tools, which update these files and apply the change to the running `<game>`
target at once. When the files change any other way, such as a pull, checkout,
hand edit, or removed row, restart the MCP host to apply them. A row that names
an address outside program memory, a function that cannot be created, or a
type that does not parse makes the `<game>` target report the error from its
first use until the files are fixed and the host is restarted.

[`check_annotations.ps1`](../scripts/ghidra/check_annotations.ps1) `[-Target <game>]`
applies the files to fresh copies of the projects and lists every failing type
or row, without touching the MCP. Run it after changing the files outside the
tools, before restarting the host.

### Other games

[`match_annotations.ps1`](../scripts/ghidra/match_annotations.ps1)
`-From <game> -To <game> [-Apply]` copies the annotations of exactly matching
functions from one game to another: the same instructions apart from jump,
call, and address operands, with exactly one candidate on each side and at
least six instructions. It copies names and comments, starting each comment
with the source function it was inferred from, and prototypes whose types the
target game already declares; it never copies types or replaces existing rows.
Without `-Apply` it only reports the counts; with `-Apply` it records the rows
through `annotate_symbol`. Everything else is carried over by hand when an
investigation reaches it.
