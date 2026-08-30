# UN Workshop

## Launch

### `ws <game|ISO> [game|ISO] [options]`

Launch one or two games. Paired launches close existing user PCSX2 instances
first.

#### Modes

- `-p <name>` — Replay an input recording
- `-r <name>` — Create an input recording
- `-s <name>` — Replay and take snapshots

#### Options

- `-o <path>` — Snapshot output directory
- `-mc <card>` — Memory card or template
- `-pnach <file>` — Additional PNACH; may be repeated
- `-dw` — Discard memory-card writes
- `-t` — Turbo speed
- `-u` — Unlimited speed

#### Available values

- Sources: {{SOURCES}}

## Input profiles

### `ws input [profile]`

Regenerate all profiles and optionally assign one.

## PCSX2

### `ws pcsx2`

Launch development PCSX2 without a game.

## Resolve

### `ws resolve [source] [property]`

Resolve all sources, one source, or one property.

#### Available properties

- `iso`
- `extracted`
- `cheats`
- `game_settings`
- `memory_card`
- `input_profile`
- `input_profile_overrides`

## Savestates

### `ws ss extract <subpath|folder-or-savestates...>`

Extract embedded PNGs into `screenshots/`.

### `ws ss move <game> <subpath> [-c]`

Move development savestates.

#### Options

- `-c` — Recycle the existing destination before moving

## Help

### `ws help`

Show this help.
