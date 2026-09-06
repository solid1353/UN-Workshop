# PCSX2 tooling

Workshop resolves game resources, prepares PCSX2 worker configurations, and
launches or replays one or two games through the `workshop.ps1` entrypoint. The
user-facing syntax is available through `workshop help`.

## Game and path resolution

`workshop resolve` returns every available source game and, when invoked inside
a configured project, every available project build. Supplying a game returns
all of its resolved properties; supplying a property prints only that value,
such as `workshop resolve NUN5 iso`.

When invoked inside a supported project, Workshop discovers that project's root
settings automatically. Shared source games remain available without project
settings.

## Launching games

Supplying one or two games or ISO paths launches them at normal speed. A single
launch opens a centered window whose render area matches the game's effective
aspect ratio. Paired launches remain tiled in argument order and mute both
PCSX2 instances. `-t` selects Turbo, while `-u` selects Unlimited; these speed
options are mutually exclusive. Each result reports the ordered game, process,
PINE port, and window position.

`workshop pcsx2` launches development PCSX2 without a game in Turbo.

Configured launches pass the catalog-derived memory-card path directly to PCSX2
without changing GameSettings. Build postfixes derive from canonical build keys
by replacing underscores with spaces and title-casing the result. Project build
card names insert that postfix after the project's serial-wide memory-card
base. Speed selection is positive throughout the launcher: callers may request
Turbo, permanent Unlimited, or frame-limited Unlimited; no speed option means
Normal. Turbo may accompany frame-limited Unlimited and becomes its fallback.
Snapshot replay explicitly selects permanent Unlimited.

## Input recordings and captures

`-p <recording>` replays one shared input recording in every launched instance.
`-r <recording>` records only the last or rightmost instance. Recording names
may be relative paths below `@pcsx2_input_recordings/`; Workshop adds the
`.p2m2` extension automatically. Recording creates missing parent directories.

`workshop <game|iso-path> [game|iso-path] -s <recording> [-o <path>]`
replays one or two configured games or explicit ISOs concurrently in PCSX2's
surfaceless no-GUI mode. It captures every recorded L3+R3 snapshot marker
without creating a render window or taking focus. For one game, `-o` selects
the exact capture directory. For two games, it selects a parent containing one
directory per game. Relative paths resolve from the invoking directory; without
`-o`, captures go below `@work/captures/<recording>/<game>/`.

Each target capture directory is deleted before replay starts. PNGs are saved
directly in that directory as `001.png`, `002.png`, and so on. Corresponding
savestates are directories under `sstates/001/`, `sstates/002/`, and so on, and
each savestate retains its own `Screenshot.png`. Without `-mc`, an explicit ISO
path uses PCSX2's configured memory-card selection.

A marker is the rising edge of the L3+R3 chord, so holding both buttons creates
one capture. A successful marker savestate and its standalone PNG use the same
encoded screenshot. If actual memory-card activity blocks the savestate outside
discard mode, the standalone PNG is still written. The command waits for every
replay to finish.

Snapshot recordings are power-on timelines. They may be shortened without
rerecording only by removing trailing frames after the final required marker.
Cutting the prefix or middle changes controller timing and the resulting game
state. A physical tail trim must update the recording's total-frame value and
truncate the file at the matching frame boundary.

## Editing P2M2 markers

`scripts/pcsx2/edit_p2m2_markers.ps1 <recording>` lists every L3+R3 marker and
its frame range. Use `-RemoveMarker 6,8` to remove markers by their current
numbers or `-MoveMarker 5 -OffsetFrames 12` to move one marker while preserving
its duration, controller port, and unrelated input.

Each mutation validates the version 1 P2M2 structure and resulting marker
sequence before replacing the recording. The previous recording becomes
`.bak1`; existing `.bakN` files shift upward and are never discarded by
rotation. Retain those backups until the user plainly approves the specific
recording edit, independently of `ver`. After that approval, the agent must run
the same script with `-RecycleBackups`, which sends only the recording's
numbered backups to the Windows Recycle Bin.

## Memory cards

`-mc <card>` selects one memory-card file for every launched game. A relative
value resolves below `@pcsx2_memory_cards/`; an absolute path is also accepted.
Workshop adds the `.ps2` extension automatically when omitted. A bare name
falls back to `@pcsx2_memory_cards/templates/` when no root-level card exists.

`-dw` makes ordinary launches report memory-card writes as successful without
persisting them. File-backed cards use shared access with or without `-dw`;
discard mode additionally suppresses memory-card busy state. Snapshot replay
with `-s` always discards writes.

## PNACH overlays

`-pnach <file>` appends one PNACH file to every launched game after its selected
default or caller-supplied per-game PNACH set. The option is repeatable and
preserves command-line order.

Shared callers may provide PNACH paths and inline PNACH lines keyed by the
selected game, plus an ordered additional PNACH list applied to every selected
game. Each process receives only its own ordered file and line sets.

## Input profiles

`workshop input` regenerates every complete PCSX2 input profile from the tracked
base and partial overrides without changing GameSettings assignments.
`workshop input <profile>` also assigns the selected profile variants in every
configured GameSettings file.

Every generated profile at the root of `@pcsx2_input_profiles/` is tracked by
Git. Base outputs use `<profile>_Base.ini`; game-specific outputs use
`<profile>_<game>.ini`. Profile selectors are case-insensitive and ignore `_`
or `-`, so `Cap_ture` selects canonical `Capture`.

Generation first merges all selected overrides by section, action, and input
family. It then removes conflicting bindings, replaces existing actions in
place, and appends only new actions. Multiple assignments declared by the
effective override may still deliberately share one binding.
