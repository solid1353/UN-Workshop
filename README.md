# UN Workshop

Shared public tooling and configuration for Ultimate Ninja modding workspaces.
The repository intentionally excludes original game media, extracted game data,
private analysis databases, local toolchains, emulator binaries, BIOS files,
memory cards, savestates, logs, and task artifacts.

## User command

`workshop.ps1` is the single user-facing entrypoint. A personal `ws` alias is
convenient but not required.

```powershell
ws input [profile]
ws ss move <game> <subpath> [-Target dev|stable] [-Cleanup|-c]
ws ss extract <folder-or-savestates...>
```

- `input` generates the selected complete PCSX2 input profile from the tracked
  base and partial overrides, then updates every configured GameSettings file.
- `ss move` files matching savestates from the selected user PCSX2 installation
  below Workshop `work/__sstates/` for source games or the invoking project's
  `work/__sstates/` for project builds. `-Cleanup` first sends the existing
  selected destination directory to the Windows Recycle Bin.
- `ss extract` extracts embedded screenshots beside one selected savestate
  folder.

When invoked inside a supported project, the command discovers that project's
root build catalog automatically. Shared source games remain available without
a project catalog.

## Tracked layout

- `paths.json`: authoritative Workshop roots and named reusable files.
- `games.json`: stable source-game selectors, aliases, serials, and CRCs.
- `settings/git-authors.tsv`: shared non-secret agent commit identities.
- `settings/notifications.json`: shared notification mute state.
- `icons/`: reusable source-game `simple` and `detailed` icons.
- `pcsx2/__shared/`: public cheats, GameSettings, input-profile sources, and
  input recordings. BIOS files and memory cards are deliberately ignored.
- `scripts/pcsx2/`: reusable PCSX2 launch, worker-copy, PINE, input-profile,
  savestate, and disc-identity utilities.
- `scripts/ghidra/`: reusable headless Ghidra Java scripts and runtime setup.
- `scripts/media/`: reusable ISO, AFS, and encrypted-CVM extractors.
- `tests/`: focused tests for Workshop-owned utilities.

Run the Workshop tests with:

```powershell
.\tests\run.ps1
```
