# UN Workshop

Shared public tooling and configuration for Ultimate Ninja modding workspaces.
The repository intentionally excludes original game media, extracted game data,
private analysis databases, local toolchains, emulator binaries, BIOS files,
memory cards, savestates, logs, and task artifacts.

## User command

`workshop.ps1` is the single user-facing entrypoint.

See [PCSX2 tooling](docs/pcsx2.md) for command behavior, launch and recording
workflows, marker editing, memory cards, PNACH overlays, and input profiles.

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
- `docs/knowledge/`: research on the unmodified retail games.
- `tests/scripts/`: focused tests mirroring Workshop-owned script components,
  including PCSX2 and media utilities.

Run the Workshop tests with:

```powershell
.\tests\run.ps1
```
