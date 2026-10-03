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

Ghidra addresses are live runtime addresses. An MWO3 overlay loads whole, its
`0x40`-byte header at the header's base address, so the import maps the payload
after the header at that base plus `0x40`. Annotations and documentation cite
live addresses only.

## Rebuilding

Run every command with `NA228_TASK_WORK_ROOT` set to the task's work directory:

```powershell
& .\scripts\ghidra\import_targets.ps1 -Target <game>
& .\scripts\ghidra\export_project.ps1 -Target <game>
& .\scripts\ghidra\set_analysis_readonly.ps1
```

`import_targets.ps1` verifies each source hash and imports and analyzes the
programs. `export_project.ps1` exports the tree and writes its manifest.
Annotation changes never require either.

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
type that does not parse makes the `<game>` target report the error until the
files are fixed and the host is restarted.
