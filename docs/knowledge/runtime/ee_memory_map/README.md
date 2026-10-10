# EE runtime memory map

This directory records the unmodified game's EE memory ownership, capacity,
and lifetime constraints for runtime analysis and asset-size planning.

## Research coverage

Established: resident and overlay address ownership, allocator placement and
entry points, the system allocation layer, stacks, persistent pools, CCS-load
costs, and sampled retail capacity. Open: result screens, active Save/Load,
long transition stress, per-asset battle heap use, and byte-level main-thread
stack use. Routine, structure and data names come from `@annotations/NA2`;
the linked documents use live addresses.

- [Address space](address_space.md) owns the resident ELF and startup layout,
  large static objects, allocator boundaries, and unsafe fixed-storage regions.
- [Allocator and capacity](allocator_and_capacity.md) owns the allocator model,
  placement policy, system allocation layer, CCS-load costs, and capacity samples.
- [Runtime lifetimes](runtime_lifetimes.md) owns overlay loading and replacement,
  stacks, high-memory ownership, persistent pools, and transient allocations.

## Safe-use constraints

- Do not use overlay slack for resident data; later overlays can overwrite it.
- Do not use allocator gaps as fixed caves; allocate through the game allocator
  and retain the returned pointer for the required lifetime.
- Do not use the high `0x01FF6000..0x02000000` tail; it holds the `malloc`
  remainder and the main-thread stack.
- Loaded executable code requires correct EE instruction and data cache
  maintenance; stable RAM alone is insufficient.

Sampled free space is not a formal maximum-use bound for every state.
