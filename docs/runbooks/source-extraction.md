# Source extraction runbook

Workshop's media scripts extract and protect original game archives under
`@source/`. Run them with `UN_TASK_WORK_ROOT` set to the task's folder, an
immediate child of a project's work root.

## Layout

Keep original archives under `@source/`. Extract each archive beside itself into
`<archive filename>.files`, repeating the convention for nested archives:

```text
<game>.iso
<game>.iso.files/
  DATA/DATA.CVM
  DATA/DATA.CVM.files/
    DATA.CVM.iso
    DATA.CVM.iso.files/
  DATA/SOUND.AFS
  DATA/SOUND.AFS.files/
```

Shared generated inventories use configured work/log roots and source-relative
paths, never the source tree.

## ISO extraction

```powershell
. '<UN Workshop>/scripts/lib/paths.ps1'
$paths = Get-UnWorkshopPaths -ProjectRoot (Get-Location).Path
& (Join-Path $paths.media_scripts 'extract_source_iso.ps1') -IsoPath <path>
```

The command stages under `temp/source_extraction/` in the task folder,
recursively expands CVM, inner ISO, AFS, and nested AFS containers, verifies
file sets/bytes, normalizes timestamps, and promotes one complete
`<ISO filename>.files` tree. It refuses to merge into an existing extraction.

Recheck an existing tree by running `@media_scripts/verify_source_extraction.py`
with the project's Python runner:

```text
verify_source_extraction.py --iso <original-iso> --out-dir <extraction-tree>
```

Add `--require-read-only` when verifying the protected active source ISO and
extraction tree.

Restore Windows read-only attributes for one explicit active ISO extraction
with:

```powershell
& (Join-Path $paths.media_scripts 'set_source_readonly.ps1') -SourceDir <tree>
```

The command refuses the whole source root and `@source/__old/`.

## DATA.CVM

Confirmed ROFS/CVM passwords:

- NA2, NUN3, NUN4, NUN5: `cc2fuku`

Use `@media_scripts/split_cvm_rofs.ps1` to split encrypted CVM safely. Do not use
the historical `@tools/old/CVM Parser/cvm_tool.exe` workflow.
