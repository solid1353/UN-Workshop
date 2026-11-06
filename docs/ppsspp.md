# PPSSPP tooling

The [game launcher](pcsx2.md#launching-games) starts PSP games in PPSSPP, so
they can run beside PS2 games. A catalog game is a PSP game when its
`games.json` entry says `"platform": "psp"`; an ISO path is one when its ISO
9660 system identifier is `PSP GAME`, as PPSSPP itself checks.
`@ppsspp_scripts/launch.ps1` starts `PPSSPPWindows64.exe` from `@ppsspp_dev`,
a build of [solid1353/ppsspp](https://github.com/solid1353/ppsspp) whose
launch options it uses. None of those options is saved to `ppsspp.ini`.

A PSP game takes from its caller:

- its per-game cheat files and lines, in CwCheat format, passed as `--cheats`
  and `--cheat-line`. They apply after the game's own cheat file and run even
  while cheats are off for the game. Additional PNACH files never reach it.
- its frame count for frame-limited fast-forward, passed as
  `--fast-forward-for-frames`, which also restarts on every reset.

Launches of two or three games mute it and start it in its tile through
`--window`, then tile it like the PCSX2 windows. Its result has no PINE port.
Input recordings, Turbo, Unlimited, read-only settings, log files and memory
card options are PCSX2-only, and a launch that includes a PSP game rejects them.
