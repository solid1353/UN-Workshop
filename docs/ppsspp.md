# PPSSPP tooling

The [game launcher](pcsx2.md#launching-games) starts PSP games in PPSSPP, so
they can run beside PS2 games. A catalog game is a PSP game when its
`games.json` entry says `"platform": "psp"`; an ISO path is one when its ISO
9660 system identifier is `PSP GAME`, as PPSSPP itself checks.
`@ppsspp_scripts/launch.ps1` starts `@ppsspp_dev`, a build of
[solid1353/ppsspp](https://github.com/solid1353/ppsspp) whose
[launch options](../../../PPSSPP/docs/launch-options.md) it uses. None of those
options is saved to `ppsspp.ini`.

## Launching games

A PSP game takes the launcher's options as a PS2 game does, with these
differences:

- PNACH files and lines are CwCheat, passed as `--cheats` and `--cheat-line`.
  They apply after the game's own cheat file and run even while cheats are off
  for the game. Additional PNACH files never reach it.
- `-t` is alternate speed 1, and `-u` is fast-forward. Frame-limited Unlimited
  fast-forwards, and restarts on every reset.
- Its result reports a `DebuggerPort` and no `PinePort`. Every launch runs the
  [debugger](#debugger-client) on the first free port from 28111, on this
  machine only.

Launches of two or three games mute it, unless it is the game `-aud` keeps,
and start it in its tile through `--window`, then tile it like the PCSX2 windows; `-mute` mutes
it in any launch. A single launch uses
`--centered-window`. A recording cannot span PSP and PS2 games. `-k` and
launches of two or three games close development emulators, PPSSPP included,
as [PCSX2's](pcsx2.md#launching-games) do.

`-surfaceless` runs the game in `PPSSPPHeadless`, which has no window, focus or
sound, at PSP speed, Turbo's 200% with `-t`, or flat out with `-u`. It plays
live, for a caller that drives it through the [debugger](#debugger-client) and
stops its process when done. `-k` and tiled launches leave headless PPSSPP
running. Its saves follow `-mc`, `-dmc` and `-vmc` as in a normal launch.

`workshop ppsspp` launches development PPSSPP without a game in Turbo.

## Deploying a PPSSPP build

After building and validating the fork, run `workshop ppsspp deploy`. Like
[PCSX2's](pcsx2.md#deploying-a-pcsx2-build), it waits in the foreground until
the executables are free, cancels if the build changes meanwhile, and logs to
`@logs/ppsspp-deploy.log`. It installs `PPSSPPWindows64.exe`, its symbols,
`PPSSPPHeadless.exe` and whatever changed under `assets/`. The
[deployment script](../scripts/ppsspp/deploy.ps1) owns the file selection and
hash verification.

## Bindings

Every launch loads the tracked `@ppsspp_files/controls.ini` through
`--controlconfig`, and PPSSPP saves control changes back to it. It mirrors
PCSX2's [input profile](pcsx2.md#input-profiles). The PSP has no second stick
or L2 and R2, so the arrow keys drive its stick, and the keyboard's Z and C
do nothing. L3 and R3 are the marker chord below. The pause menu is on F1, since
Esc stops the game as it does in PCSX2. A game launch passes
`--pause-menu-exit`, so stopping the game, or the game quitting, closes PPSSPP.

The speeds behind Turbo and slow motion are `AltSpeedPercent` and
`AltSpeedPercent2` in `@ppsspp_dev`'s `ppsspp.ini`, set to 200 and 25 like
PCSX2's. A tile is taller than it is wide, which PPSSPP lays out as portrait, so
that layout's `DisplayOffsetY` is 0.5 to center the game as PCSX2 does.

## Saves

`-mc` names a folder of save directories below `@ppsspp_saves`, passed as
`--savedata`, which takes the place of `ms0:/PSP/SAVEDATA`. A bare name falls
back to `@ppsspp_saves/templates/`, where numbered templates such as `0_full`
also answer to their number or name. An absolute path is also accepted, and
`-mc none` runs without a memory stick.

`-dmc` reports saves as written without writing them, and `-vmc` runs on a copy
dropped when the game stops or resets. Both default to the memory stick's own
saves and follow the
[launch options](../../../PPSSPP/docs/launch-options.md). `-dmc` covers only
the savedata utility, which is what commercial games use, and is refused with
a recording, whose saves have to run.

## Input recordings and captures

`-r <recording>` records only the instance PCSX2's would, and `-rp <recording>` replays
one recording in every instance. Names are relative paths below
`@ppsspp_input_recordings/`, and Workshop adds the `.ppr` extension.

`-rps <recording>` replays in `PPSSPPHeadless` and captures every marker, with
the output layout of [PCSX2's](pcsx2.md#input-recordings-and-captures) and the
[fork's file names](../../../PPSSPP/docs/input-recording.md#markers). It uses
the installation's memory stick and `ppsspp.ini`, and runs on a copy of the
saves, as agent replays do. It always renders with Vulkan.

The `Input recording marker` hotkey is the grave key or L3+R3. A marker is an
event of its own, so holding the keys adds one, and the game never sees it. A
replay matches its recording only on the same build and settings.

`-rp <recording> -agent-replay -logfile <path>` starts `PPSSPPHeadless` paused
for the debugger client below. It has no window, and PPSSPP's log goes to the
file.

## Editing recording markers

`scripts/ppsspp/edit_recording_markers.ps1 <recording>` lists every marker with
its time and frame. Use `-RemoveMarker 6,8` to remove markers by their current
numbers, or `-MoveMarker 5 -OffsetFrames 12` to move one. The backup rules are
[those for P2M2 recordings](pcsx2.md#editing-p2m2-markers), including
`-RecycleBackups`.

## Live cheats

`workshop ppsspp cheat` applies a file or repeatable `-line` arguments directly
through the debugger. See `workshop help` for the syntax. `-port` is mandatory,
and it's the `DebuggerPort` the launch reported.

`@ppsspp_scripts/cheat.py` accepts blank lines, `//` comments, whole-line `#` or
`;` comments, and `_L` lines of the constant-write types: `0` (byte, widened
by value as PPSSPP does), `1` (halfword) and `2` (word). `_S`, `_G` and `_C`
headers and every other code type are rejected, and the batch is parsed before
any write.

`-expect <address>:<hex-bytes>` and `-watch` work as for
[PNACH](pcsx2.md#live-application), except that the address is a guest address
such as `08812345`, where a cheat line's is an offset from `08800000`. Each line
applies once per invocation. The debugger's writes clear compiled code
themselves.

`@ppsspp_scripts/assemble.py --port <port> --base <address> <listing>` turns a
listing of one Allegrex instruction per line, with `name:` labels that any
line can name as an operand and `;` comments, into `_L` word writes from that
guest address on. PPSSPP's `memory.assemble` encodes each line by writing it
into the running game, so assemble into memory the game doesn't use, such as
the 16 KiB from `08800000` that PPSSPP reserves for the user system library
and never writes.

## Debugger client

`@ppsspp_scripts/debugger.py` is the client for PPSSPP's
[WebSocket debugger](../../../PPSSPP/docs/WebSocketDebugger.md) and the fork's
`agent.*` events, PPSSPP's counterpart of [PINE](pcsx2.md#pine-client). A
command line covers `status`, `pause`, `resume`, `step`, `replay-status`,
`replay-step`, `screenshot`, `ge-dump`, `save-state`, `load-state` and
`shutdown`. Agent input set through `DebuggerClient` lasts until released, and
goes when that client disconnects, so the command line only takes it for a
`step`. PPSSPP reads the screen only while stopped, so a screenshot of a running
game pauses it around the capture.

## Savestates

`@ppsspp_savestates/` holds PPSSPP's savestates. Each slot's `.ppst` sits beside
a `.ppdmp` [GE dump](#ge-dumps) of the frame after the save.

`@ppsspp_scripts/savestate.py info <state>` prints a state's header and where
its memory sits. `ram <state> -o <file>` writes its RAM from guest `0x08000000`,
kernel memory included, so user memory at `0x08800000` is at file offset
`0x800000`.

## GE dumps

`@ppsspp_scripts/ge_dump.py` reads GE frame dumps (`.ppdmp`, or a `.zip` holding
one) to find why something draws differently in two games or builds. `list`
prints one frame's texture uploads, memory transfers, CLUT loads, register
changes and draws in submission order, with the state each draw uses. `diff`
diffs that list between two dumps. Textures and CLUTs are named by a hash of
their contents, and a diff drops addresses, so it shows what differs even when
two games place things elsewhere. `--frame` selects a frame.

```powershell
& '@ppsspp_scripts/../lib/run_python.ps1' -Script '@ppsspp_scripts/ge_dump.py' `
  -ArgumentList diff, first.ppdmp, second.ppdmp
```
