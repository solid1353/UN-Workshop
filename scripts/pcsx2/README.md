# PCSX2 scripts

`patch_savestate_memory.py` creates a separate experimental savestate directory
from a source PCSX2 savestate directory and a JSON runtime patch plan. It copies
the state, applies each `patch_memory` action to `eeMemory.bin` only when
`expected_hex` matches, and verifies the result. The source is never
overwritten, and the output path must not exist.

```powershell
python scripts/pcsx2/patch_savestate_memory.py `
  work/savestate-experiment/inputs/source `
  work/savestate-experiment/inputs/plan.json `
  work/savestate-experiment/outputs/patched
```

The plan must contain an `actions` array. Relevant entries have
`"action": "patch_memory"`, an integer-formatted `address`, and equal-length
hex strings in `expected_hex` and `replacement_hex`; other action kinds are
ignored. Chained writes to one address must be contiguous. The source must be a
PCSX2 savestate directory with a 32 MiB `eeMemory.bin`. This is an offline
experiment aid, not a maintained validation route. Promote reusable results
into the owning Workshop or NA2 knowledge record rather than retaining patched
states as evidence by themselves.
