# UN Workshop

Shared public tooling, configuration, and retail-game research for Ultimate
Ninja modding workspaces. The repository intentionally excludes original game media, extracted game data,
private analysis databases, local toolchains, emulator binaries, BIOS files,
memory cards, savestates, logs, and task artifacts.

## User command

`workshop.ps1` is the single user-facing entrypoint; `CLI.txt` holds its help
text.

See [PCSX2 tooling](docs/pcsx2.md) for command behavior, launch and recording
workflows, marker editing, memory cards, PNACH overlays, and input profiles.

Commands that stage temporary files read `UN_TASK_WORK_ROOT`, the acting
task's folder as an immediate child of a consuming project's work root.

## Tracked layout

- `paths.json`: authoritative Workshop roots and named reusable files.
- `games.json`: stable source-game selectors, aliases, serials, and CRCs.
- `@pcsx2_files/`: NUN3 and NUN4
  [registered bundles](../../PCSX2/docs/content_folders.md#content-aliases)
  under `games/`, shared input-profile sources, and ignored default and test cards.
  Consuming projects own their other game bundles and input recordings.
- `@pcsx2_input_profiles/sources/overrides/`: named input-profile
  overrides, with game-specific overrides under `games/`.
- `@pcsx2_scripts/`: reusable PCSX2 launch, worker-copy, PINE, input-profile,
  and marker-editing utilities.
- `@ghidra_scripts/`: cross-game import, export, manifest, and
  read-only tooling for the [disassembly trees](docs/disassembly.md); reusable
  headless Ghidra Java scripts and runtime setup; and the
  [GhidrAssistMCP integration](docs/runbooks/ghidrassistmcp.md).
- `@media_scripts/`: ISO, AFS, and encrypted-CVM extractors, recursive source
  extraction and verification, and source read-only tooling; see the
  [source extraction runbook](docs/runbooks/source-extraction.md).
- `scripts/lib/`: Workshop and project path loading, source-game resolution,
  the task work-folder context, and console help.
- `@annotations/`: names, types, and comments for the disassembly trees,
  recorded through the GhidrAssistMCP annotation tools.
- `docs/knowledge/`: research on the unmodified retail games.
- `tests/scripts/`: focused tests mirroring Workshop-owned script components,
  including PCSX2 and media utilities.

Run the Workshop tests with:

```powershell
.\tests\run.ps1
```
