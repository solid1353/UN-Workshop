# PCSX2 scripts

`patch_savestate_memory.py` creates a separate experimental savestate from a
source PCSX2 savestate and a JSON runtime patch plan. It extracts
`eeMemory.bin`, applies each `patch_memory` action only when `expected_hex`
matches, rebuilds the archive in its original member order, and verifies the
result. The source is never overwritten, and the output path must not exist.

```powershell
python scripts/pcsx2/patch_savestate_memory.py `
  work/savestate-experiment/inputs/source.p2s `
  work/savestate-experiment/inputs/plan.json `
  work/savestate-experiment/outputs/patched.p2s
```

The plan must contain an `actions` array. Relevant entries have
`"action": "patch_memory"`, an integer-formatted `address`, and equal-length
hex strings in `expected_hex` and `replacement_hex`; other action kinds are
ignored. Chained writes to one address must be contiguous. The source must be
a PCSX2 archive with a 32 MiB `eeMemory.bin`; unsupported ZIP compression needs
7-Zip or `tar`. This is an offline experiment aid, not a maintained validation
route. Promote reusable results into the owning Workshop or NA2 knowledge
record rather than retaining patched states as evidence by themselves.
