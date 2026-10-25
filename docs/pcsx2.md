# PCSX2 tooling

Workshop resolves game resources, prepares PCSX2 worker configurations, and
launches or replays one to three games through the `workshop.ps1` entrypoint. The
user-facing syntax is available through `workshop help`.

## Game and path resolution

`workshop resolve` returns every available source game and, when invoked inside
a configured project, every available project build. Supplying a game returns
all of its resolved properties; supplying a property prints only that value,
such as `workshop resolve UN5 iso`.

When invoked inside a supported project, Workshop discovers that project's root
settings automatically. Shared source games remain available without project
settings.

## Launching games

Supplying one to three games or ISO paths launches them at normal speed. A single
launch opens a centered window through PCSX2's `-centered-window`
[launch option](../../../PCSX2/docs/launch_options.md#process-overrides).
Launches of two or three games tile them left to right in argument order, each
window an equal share of the screen width, and keep them there through PCSX2's
`-no-recenter`, which stops game starts from recentering the windows; they also
mute every PCSX2 instance. `-t` selects Turbo, while `-u` selects Unlimited;
these speed options are mutually exclusive. Each result reports the ordered
game, process, PINE port, and window position.

`-k` closes every running development PCSX2 before launching. Launches of two or
three games do this automatically, except agent replays. Snapshot replays never
close PCSX2 and reject `-k`. Each PCSX2 gets five seconds to close before it is
force-stopped.

`workshop pcsx2` launches development PCSX2 without a game in Turbo.

Speed selection is positive throughout the launcher: callers may request
Turbo, permanent Unlimited, or frame-limited Unlimited; no speed option means
Normal. Frame-limited Unlimited uses PCSX2's `-unlimited-for-frames`, and Turbo
may accompany it as its fallback; a caller may give each launched game its own
frame count. See the
[speed options](../../../PCSX2/docs/launch_options.md#speed). Snapshot replay
explicitly selects permanent Unlimited.

## Deploying a PCSX2 build

After building and validating the fork, run `workshop pcsx2 deploy`. The command
uses the configured build output and development installation paths and waits
in the foreground until the installed files become available. Close PCSX2 when
convenient; deployment continues automatically, and the command returns when
it finishes or fails.

Deployment reads the completed build directly without staging another copy.
If its source files change while waiting, deployment is cancelled. Results are
appended to Workshop's `@logs/pcsx2-deploy.log`. The
[deployment script](../scripts/pcsx2/deploy.ps1) owns the deployed file selection
and hash verification.

## Input recordings and captures

`-rp <recording>` replays one shared input recording in every launched instance
through PCSX2's
[read-only playback](../../../PCSX2/docs/input_recording_capture.md#read-only-playback).
`-r <recording>` records only the last or rightmost instance. Recording names
may be relative paths below `@pcsx2_input_recordings/`; Workshop adds the
`.p2m2` extension automatically. Recording creates missing parent directories.

`workshop <game|iso-path>... -rps <recording> [-o <path>]`
replays one to three configured games or explicit ISOs concurrently in PCSX2's
surfaceless no-GUI mode. It captures every recorded L3+R3 snapshot marker in
PCSX2's `full`
[capture mode](../../../PCSX2/docs/input_recording_capture.md#marker-capture)
without creating a render window or taking focus. For one game, `-o` selects
the exact capture directory. For more games, it selects a parent containing one
directory per game. Relative paths resolve from the invoking directory; without
`-o`, captures go below `<capture root>/<recording>/<game>/`. The capture root
is the launcher's `-CaptureRoot` parameter, or the project's `captures/`
directory when the caller does not pass one.

Each target capture directory is deleted before replay starts, and PCSX2 then
writes `001.png` and `sstates/001/` style captures into it. The command
waits for every replay to finish.

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

Without `-mc`, every launch uses PCSX2's configured memory cards. `-mc <card>`
selects one memory card, a file or folder card, for every launched game. A relative
value resolves below `@pcsx2_memory_cards/`; an absolute path is also accepted.
Workshop adds the `.ps2` extension automatically when omitted. A bare name
falls back to `@pcsx2_memory_cards/templates/` when no root-level card exists.
Numbered templates also accept their number or name: `0_full.ps2` can be
selected with `-mc 0` or `-mc full`. Matching is case-insensitive; an exact
filename takes precedence, and an ambiguous shortcut requires a full filename.

The selected card is passed as PCSX2's `-memory-card <path>`. `-mc none`, in
any letter case, is forwarded as `-memory-card none`, which disconnects every
slot. To select a file named `none.ps2`, include its extension or give its
path.

`-dmc` passes `-discard-memory-card-writes`, and `-vmc` passes
`-volatile-memory-card`. The
[memory card options](../../../PCSX2/docs/launch_options.md#memory-cards)
describe both modes. `-dmc` and `-vmc` are mutually exclusive. Either flag may
take an optional card selector: `-vmc full` is equivalent to `-mc full -vmc`,
and `-dmc 1` to `-mc 1 -dmc`. Without a value, the flag uses the normally
selected card. Specify a card only once.

Ordinary launches persist writes to the selected card, including templates,
unless `-dmc` or `-vmc` is specified. Snapshot replay with `-rps` defaults to
discarded writes for all cards; explicit `-vmc` selects volatile mode.

## PNACH overlays

A game's default PNACH is `games/<game>.pnach` in the project's or Workshop's
`pcsx2_files/`, when one exists; the same file in both is an error.
`-pnach <file>` appends one PNACH file to every launched game after its selected
default or caller-supplied per-game PNACH set. The option is repeatable and
preserves command-line order.

Shared callers may provide PNACH paths and inline PNACH lines keyed by the
selected game, plus an ordered additional PNACH list applied to every selected
game. Each process receives only its own ordered file and line sets, passed as
PCSX2's [`-pnach` and `-pnach-line`](../../../PCSX2/docs/pnach.md#command-line-pnach)
options.

## Input profiles

Every game uses the tracked `@pcsx2_input_profiles/Default.ini`, which holds
all controller bindings, hotkeys and input-source settings. PCSX2.ini names it
as the fork's
[default input profile](../../../PCSX2/docs/README.md), so it replaces PCSX2's
shared input settings. Edit it through Controller Settings.

## PINE client

`@pcsx2_scripts/pine.py` is the client for the development fork's
[PINE opcodes](../../../PCSX2/docs/pine_agent_control.md), including agent
input, replay analysis, and the full-state pad encoder. Its connections time
out after three seconds, so clients follow these rules:

- Keep each agent or replay step short enough to finish within the timeout.
  A client that times out disconnects, but PCSX2 finishes the step before it
  notices.
- Do not disable PINE or change its port while a step is in progress.
- Release agent overrides explicitly when done; a failed non-agent request does
  not clear them.

## Savestates

A savestate folder holds the game's memory at the moment it was saved
(`eeMemory.bin`, the 32 MiB EE RAM) and a GS dump of its frame
(`GS.gs.zst`), which [`gs_dump.py`](#gs-dumps) lists and diffs.

## GS dumps

`@pcsx2_scripts/gs_dump.py` reads PCSX2 GS dumps (`.gs` or `.gs.zst`, from
the `snaps` folder) to find why something draws differently in two games or
builds. `list` prints one frame's image uploads, local moves and draw batches
in submission order, with the GS state of the context each draw's PRIM
selects; `diff` diffs that list between two dumps. Textures and palettes are
named by a hash of the image last uploaded to their base block, so a diff
shows a texture that is uploaded or drawn in one dump only, even when the two
games place it at different addresses. The first line of `list` gives the
displayed framebuffers, which a frame's draws reach only after the game
copies them there.

```powershell
& '@pcsx2_scripts/../lib/run_python.ps1' -Script '@pcsx2_scripts/gs_dump.py' `
  -ArgumentList diff, first.gs.zst, second.gs.zst, --frame, 1
```

Frame 0 holds only the state at the dump's start; games that render at half
the display rate draw in every other frame.
