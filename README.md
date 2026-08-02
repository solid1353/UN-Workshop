# UN Workshop

Shared public tooling and configuration for Ultimate Ninja modding workspaces.
The repository intentionally excludes original game media, extracted game data,
private analysis databases, local toolchains, emulator binaries, BIOS files,
memory cards, savestates, logs, and task artifacts.

## User command

`workshop.ps1` is the single user-facing entrypoint.

```powershell
workshop resolve [game] [property]
workshop pcsx2 [game] [input-recording]
workshop record <game> <input-recording>
workshop input [profile]
workshop ss move <game> <subpath> [-Target dev|stable] [-Cleanup|-c]
workshop ss extract <subpath|folder-or-savestates...>
```

- `workshop resolve` returns every available source game and, when invoked
  inside a configured project, every available project build. Supplying a game
  returns all of its resolved properties; supplying a property prints only that
  value, such as `workshop resolve NUN5 iso`.
- `workshop pcsx2` launches development PCSX2. Supplying a game launches its
  resolved ISO. An optional input-recording filename opens from the canonical
  shared input-recordings directory. An absolute canonical recording path is
  also accepted; the launcher passes only its filename to PCSX2.
- `workshop record <game> <input-recording>` launches development PCSX2 with
  the resolved game ISO and creates a power-on recording with that filename in
  the canonical shared input-recordings directory.
- `workshop input` regenerates every complete PCSX2 input profile from the
  tracked base and partial overrides without changing GameSettings assignments.
- `workshop input <profile>` also regenerates every complete profile, then
  assigns the selected profile variants in every configured GameSettings file.
  Every generated profile at the root of `pcsx2_shared/input_profiles/` is
  tracked by Git. Base outputs use `<profile>_Base.ini`; game-specific outputs
  use `<profile>_<game>.ini`. Profile selectors are case-insensitive and ignore
  `_` or `-`, so `Test_Capture` selects canonical `TestCapture`.
- Generation first merges all selected overrides by section, action, and input
  family. It then removes conflicting bindings, replaces existing actions in
  place, and appends only new actions. Multiple assignments declared by the
  effective override may still deliberately share one binding.
- `ss move` files matching savestates from the selected user PCSX2 installation
  below Workshop `work/__sstates/` for source games or the invoking project's
  `work/__sstates/` for project builds. `-Cleanup` first sends the existing
  selected destination directory to the Windows Recycle Bin.
- `ss extract <subpath>` resolves the subpath below Workshop
  `work/__sstates/` and extracts embedded screenshots beside that savestate
  folder. Explicit folder and savestate paths remain supported.

When invoked inside a supported project, the command discovers that project's
root build catalog automatically. Shared source games remain available without
a project catalog.

## Tracked layout

- `paths.json`: authoritative Workshop roots and named reusable files.
- `games.json`: stable source-game selectors, aliases, serials, and CRCs.
- `settings/git-authors.tsv`: shared non-secret agent commit identities.
- `settings/notifications.json`: shared notification mute state.
- `icons/`: reusable source-game `simple` and `detailed` icons.
- `pcsx2_shared/`: public cheats, GameSettings, input-profile sources, and
  input recordings. BIOS files and memory cards are deliberately ignored.
- `pcsx2_shared/input_profiles/sources/overrides/`: named input-profile
  overrides, with game-specific overrides under `games/`.
- `scripts/pcsx2/`: reusable PCSX2 launch, worker-copy, PINE, input-profile,
  savestate, and disc-identity utilities.
- `scripts/ghidra/`: reusable headless Ghidra Java scripts and runtime setup.
- `scripts/media/`: reusable ISO, AFS, and encrypted-CVM extractors.
- `tests/`: focused tests for Workshop-owned utilities.

Run the Workshop tests with:

```powershell
.\tests\run.ps1
```
