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
- `packages.json`: the pinned packages, each by URL and SHA-256.
  `scripts/lib/pinned_packages.ps1` downloads, verifies and unpacks each into
  `@cache/` on first use.
  - `python`: the official CPython package. Every Workshop script runs it
    through `scripts/lib/run_python.ps1`. A repository passed to that runner
    whose own `packages.json` pins packages gets a virtual environment of them,
    built from this interpreter in its own cache root.
  - `ee_toolchain`: the EE compiler, at `@ee_toolchain/`. It is ps2dev's GCC
    built by [solid1353/ps2toolchain-ee](https://github.com/solid1353/ps2toolchain-ee)
    from [solid1353/gcc](https://github.com/solid1353/gcc), whose one change
    keeps the R5900 EABI stack 16-byte aligned. Code from the PS2's native
    compilers saves 128-bit registers to the stack with `sq`, so code that
    calls into a retail game needs that alignment.
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
- `scripts/lib/`: Workshop and project path loading, the pinned Python,
  source-game resolution, the task work-folder context, and console help.
- `@annotations/`: names, types, and comments for the disassembly trees,
  recorded through the GhidrAssistMCP annotation tools.
- `docs/knowledge/`: research on the unmodified retail games.
- `tests/scripts/`: focused tests mirroring Workshop-owned script components,
  including PCSX2 and media utilities.

Run the Workshop tests with:

```powershell
.\tests\run.ps1
```
