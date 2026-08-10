# UN Workshop

Shared public tooling and configuration for Ultimate Ninja modding workspaces.
The repository intentionally excludes original game media, extracted game data,
private analysis databases, local toolchains, emulator binaries, BIOS files,
memory cards, savestates, logs, and task artifacts.

## User command

`workshop.ps1` is the single user-facing entrypoint.

```powershell
workshop [game] [game] [-p <recording>|-r <recording>] [-mc <card>] [-dw]
workshop <game> -t <recording> [-mc <card>]
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
  records only the last/rightmost instance. Recording names may be relative
  paths below `pcsx2_shared/input_recordings/`, and the `.p2m2` extension is
  added automatically. For `-r`, missing parent directories are created. Each
  result reports the ordered game, process, PINE port, and window position.
- `-mc` selects one memory-card file for every launched game. A relative value
  resolves below `pcsx2_shared/memory_cards/`; an absolute path is also accepted.
  The `.ps2` extension is added automatically when omitted. A bare name falls
  back to `pcsx2_shared/memory_cards/templates/` when no root-level card exists.
  `-dw` makes ordinary launches report memory-card writes as successful without
  persisting them. File-backed cards use shared access with or without `-dw`;
  discard mode additionally suppresses memory-card busy state. Regression replay
  with `-t` always discards writes.
- `workshop <game> -t <recording>` replays one game in PCSX2's
  surfaceless no-GUI mode and captures every recorded L3+R3 regression marker
  without creating a render window or taking focus. Captures go below
  `work/captures/<recording>/<game>/`. A marker is the rising edge of the chord,
  so holding both buttons creates one capture. A successful marker savestate and
  its standalone PNG use the same encoded screenshot. If actual memory-card
  activity blocks the savestate outside discard mode, the standalone PNG is
  still written. The command waits for the replay to finish.
- Regression recordings are power-on timelines. They may be shortened without
  rerecording only by removing trailing frames after the final required marker;
  cutting the prefix or middle changes controller timing and the resulting game
  state. A physical tail trim must update the recording's total-frame value and
  truncate the file at the matching frame boundary.
- `workshop pcsx2` launches development PCSX2 without a game.
- `workshop input` regenerates every complete PCSX2 input profile from the
  tracked base and partial overrides without changing GameSettings assignments.
- `workshop input <profile>` also regenerates every complete profile, then
  assigns the selected profile variants in every configured GameSettings file.
  Every generated profile at the root of `pcsx2_shared/input_profiles/` is
  tracked by Git. Base outputs use `<profile>_Base.ini`; game-specific outputs
  use `<profile>_<game>.ini`. Profile selectors are case-insensitive and ignore
  `_` or `-`, so `Cap_ture` selects canonical `Capture`.
- Generation first merges all selected overrides by section, action, and input
  family. It then removes conflicting bindings, replaces existing actions in
  place, and appends only new actions. Multiple assignments declared by the
  effective override may still deliberately share one binding.
- Configured launches pass the catalog-derived memory-card path directly to
  PCSX2 without changing GameSettings. Build postfixes derive from canonical
  build keys by replacing underscores with spaces and title-casing the result.
  Project build card names insert that postfix after the project's serial-wide
  memory-card base.
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
