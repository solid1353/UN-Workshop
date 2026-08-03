# UN Workshop

Shared public tooling and configuration for Ultimate Ninja modding workspaces.
The repository intentionally excludes original game media, extracted game data,
private analysis databases, local toolchains, emulator binaries, BIOS files,
memory cards, savestates, logs, and task artifacts.

## User command

`workshop.ps1` is the single user-facing entrypoint.

```powershell
workshop [game] [game] [-p <recording>|-r <recording>]
workshop <game> -t <recording>
workshop input [profile]
workshop pcsx2
workshop resolve [game] [property]
workshop ss extract <subpath|folder-or-savestates...>
workshop ss move <game> <subpath> [-t dev|stable] [-c]
```

- `workshop resolve` returns every available source game and, when invoked
  inside a configured project, every available project build. Supplying a game
  returns all of its resolved properties; supplying a property prints only that
  value, such as `workshop resolve NUN5 iso`.
- Supplying one or two games launches their resolved ISOs in development PCSX2
  and tiles them in argument order. `-p`
  replays one shared input recording in every launched instance; `-r`
  records only the last/rightmost instance. The `.p2m2` extension is added
  automatically when omitted. Each result reports the ordered game, process,
  PINE port, and window position.
- `workshop <game> -t <recording> [-o <path>]` replays one game hidden and
  captures every recorded L3+R3 regression marker. `-o` writes directly
  to the requested directory; without it, captures go below
  `work/captures/<recording>/<game>/`. It waits for the replay to finish.
- `workshop pcsx2` launches development PCSX2 without a game.
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
  below Workshop `work/sstates/` for source games or the invoking project's
  `work/sstates/` for project builds. `-c` first sends the existing
  selected destination directory to the Windows Recycle Bin. Incoming states
  continue sequentially after the highest existing number in that directory.
- `ss extract <subpath>` resolves the subpath below Workshop
  `work/sstates/` and extracts embedded screenshots beside that savestate
  folder. Explicit folder and savestate paths remain supported.

When invoked inside a supported project, the command discovers that project's
root build catalog automatically. Shared source games remain available without
a project catalog.

## Tracked layout

- `paths.json`: authoritative Workshop roots and named reusable files.
- `games.json`: stable source-game selectors, aliases, serials, and CRCs.
- `settings/git-authors.tsv`: shared non-secret agent commit identities.
- `settings/notifications.json`: shared notification mute state.
- `assets/icons/`: reusable source-game `simple` and `detailed` icons.
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
