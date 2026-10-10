# Render submission and buffers

## Research coverage

Established: render-pool ownership, rotating packet lists, priority/tree ordering,
frame submission, DMA continuation/completion, and paired GS environments.
Open: deferred-queue capacity, special-processing lifetime/setters, indirect
producers, a final GS FINISH fence, allocation-failure frequency and render cost.
Names and partial structure views come from `@annotations/NA2`.
Evidence is static retail code; capacities do not establish measured performance.

This document owns render packet allocation, list ownership, ordering,
submission and reuse in retail NA2 (`SLPS-25837`). Cited addresses are resident
`SLPS_258.37` live EE addresses; see
[address conventions](../../game/files/file_identities.md#address-conventions).

Related owners: [Renderer and coordinate systems](renderer_coordinates.md)
(transforms), [Texture palette and material runtime](texture_material_runtime.md)
(resource binding), [Full-screen and bounded 2D draw ownership](draw_2d_owners.md)
(draw ownership), [Model VU programs](model_vu_programs.md#initial-upload-boundaries)
(frame/model uploads), and
[Allocator and capacity](../ee_memory_map/allocator_and_capacity.md)
(general heap allocation).

## Pool and block ownership

**Observed, high confidence.** `engine_root_initialize` creates a
`RenderPool` through `render_pool_create_owned`; its `0x200000` backing
bytes include allocator headers and are shared by registered drawing
environments. `render_pool_configure` can instead borrow supplied backing.
`RenderPool.flags & 1` records ownership, and `render_pool_destroy` releases
backing only when that bit is set.

`RenderPool.next` preserves registration order; `first_free` is the
search-start block, `backing` the first physical block, and `end` the
exclusive backing end. The descriptor is `0x14` bytes.
`RenderPoolAllocation` is a `0x10`-byte header before payload:
`next` links blocks of one allocation list, `owner_list` identifies that
list or is zero for free storage, and `total_bytes` includes the header.
This metadata is separate from DMA tags in the payload.

`render_block_prepend_owned` assigns list ownership;
`render_block_list_release` clears it without clearing payload or size.
`render_pool_coalesce` merges physically adjacent free blocks.
Consequently, old packet bytes can remain at a released address until a later
allocation overwrites them. Ownership determines reuse eligibility.

`render_environment_packet_allocate` (`0x001097D0`) allocates from
`BattleHudRenderContext.packet_list.construction`. Adequate same-owner
capacity advances the shared bump cursor; changing owner goes through
`render_bump_change_owner`, and insufficient capacity through
`render_pool_allocate`. All three keep the requested size without alignment
repair or rounding; the inspected producers request multiples of `0x10`.

`render_pool_find_free_block` accepts only an unowned physical block other
than the active bump block whose total size is **strictly greater** than
`bytes + 0x10`. Exact fits fail. Pool search follows registration order and
returns zero when no pool qualifies.

The ordinary allocator supplies its remaining payload count as a
tail-reservation threshold. A tail above `0x20` can become a free block;
an adequate tail becomes the new shared bump region. Switching owners
finalizes the old block and adds a new `0x10`-byte header; a remaining tail
at most `0x20` disables the bump region.

`render_pool_release_frame` releases queued lists, resets their 16-bit count,
reclaims unused active-bump capacity, clears its remaining count/block
pointer, and coalesces all registered pools. It does not clear packet payloads.

## Two heads per render list

Each `RenderPacketList` is `0x20` bytes and is embedded in
`BattleHudRenderContext.packet_list`. `ordered_controller_list_initialize`
selects its two embedded `RenderPacketHead`s as `construction` and
`submission`. Each head owns allocation `blocks` and the
`first_packet`/`last_packet` endpoints of a DMA chain.

`render_packet_list_rotate` (`0x00110210`) clears the old submission
endpoints and releases their allocation ownership, makes that head the new
construction head, and selects the other for submission. Head addresses stay
stable while their roles rotate.
`render_packet_list_splice_submission` inserts the submission chain at a
supplied master-chain insertion tag.

`render_packet_list_destroy` releases construction blocks immediately and
queues the other head's blocks through `render_block_list_defer_release`
for the next `render_pool_release_frame`.
`ordered_controller_destroy` unregisters the drawing environment before
destroying its embedded list.

The deferred pointer queue starts at `render_deferred_block_lists`. Its first
entry is typed as a `RenderPoolAllocation *`; entries have a four-byte stride.
Registration retargets every queued block's `owner_list` to its queue entry,
then increments
a 16-bit count without a capacity comparison. The declared array capacity is
unresolved; neither counter width nor surrounding zero-filled bytes establishes
a safe bound.

## Packet ordering

`engine_embedded_object_reset` registers drawing environments in descending
signed 16-bit `BattleHudRenderContext.id` priority order, placing new equal
priorities after existing ones. `ordered_controller_set_group` changes that
priority by unregistering and reinserting.

Frame assembly visits this list and inserts each chain at the same master
tag. **Inference, high confidence from the links:** final chain order is
ascending priority, with equal-priority chains in reverse registration order.
This does not establish which primitive visibly overwrites another.

Within construction, `render_packet_append` appends,
`render_packet_initialize_append` initializes a tag from rounded quadword
count and appends, and `render_packet_prepend` prepends.
`render_dma_tag_initialize_next` creates a NEXT tag with QWC
`(bytes - 0x10) >> 4`. These helpers neither allocate nor check capacity.

Ordered work uses `BattleHudRenderContext.ordering`, a
`RenderOrderingTree` with `root` and `max_depth`.
`engine_root_allocate` passes `0x400` to
`render_ordering_pool_initialize`: 1024 shared `RenderOrderingNode`s,
`0x14` bytes each, occupy `0x5000` bytes.
Each node holds `key`, `left`, `right`, `first_packet` and `last_packet`.

`render_ordering_insert` (`0x0010A2C0`) reserves a node before attempting
insertion. New keys less than or equal to the existing key go left; larger
keys and unordered float comparisons go right. Root depth is 1; depth 51 is
abandoned. Its reserved node stays consumed and its packets are not linked.
Pool exhaustion also omits the supplied chain. Neither failure reports an
error or falls back to direct append.

`render_ordering_flush` passes the tree and destination list to recursive
`render_ordering_visit`, which visits left, node, right and appends each chain
through `render_packet_list_append_chain`. For finite keys this is ascending
order, with later equal insertions visited first.

Next-frame preparation clears every tree through
`render_contexts_prepare_frame` → `engine_embedded_object_initialize` →
`render_ordering_tree_clear`. Afterwards `engine_snapshot_service_word`
resets `render_ordering_pool_cursor` from `render_ordering_pool_base`.
Both globals are `RenderOrderingNode *` pointers. Tree nodes remain construction
metadata, not DMA payload.

## Frame chain and VIF1 submission

**Observed, high confidence.** `ordered_controller_list_process`
(`0x00109D50`) finalizes ordered work for each registered environment,
conditionally prepends a `0x30`-byte setup packet, rotates ordinary lists,
then splices the submission head into the master chain.

Ordinary rotation requires `BattleHudRenderContext.special_processing == 0`.
Nonzero calls the empty `ordered_controller_special_process_noop` instead.
Its setters and caller-owned packet lifetime remain unresolved.

`render_dma_chain_splice` copies the insertion tag's old next address to the
inserted chain's final linking tag and replaces the insertion link with the
chain's first packet. DMA IDs 0, 3, 4 and 5 step over `(QWC + 1) * 0x10`
bytes to reach a linking tag; other IDs use the supplied tag itself.

`engine_prepare_packet_buffer` selects one of
`EnginePadContext.master_templates` by `update_counter & 1`.
The two templates are `0x60` bytes each. It publishes `master_chain` and
`master_insertion`. The prefix references `model_vu_frame_prefix`
(`0x003CEA30`) with QWC `0x27B`, installing shared VU1 instruction regions;
[Model VU programs](model_vu_programs.md#initial-upload-boundaries)
owns their interpretation.

The next template slot copies the REF tag from `EnginePadContext.setup_packet`.
`display_setup_packet_rebuild` releases/replaces that separately owned packet
when display setup is regenerated. Its allocation request is
`0x140 + 0x40 * floor(display_width / 64)`, outside the frame packet pool.

`engine_root_update` (`0x001081B0`) increments `update_counter`, assembles
the current chains, and submits the master chain through
`display_submit_vif1_chain` only while `setup_request` is negative.
Submission saves `submitted_chain`, sets up VIF1 source-chain DMA with
CHCR `0x145`, and marks the transfer active. The caller then enables DMAC
channel 1. Register setup and interrupt sequencing are in the routine annotation.

After submission, `engine_update_services` prepares the next parity template,
resets context state, then recycles the packet pool. Shared ordering-node reset
follows. This establishes construction/submission rotation and preparation order.

## Completion and packet lifetime

`scheduler_update_loop` calls `engine_root_update` at iteration start,
schedules and waits for its workers, then calls `engine_root_finish_update`
before sleeping. Frame finish repeatedly calls `graphics_synchronize(0)`
and waits while the `vif1_transfer_active` byte is 1.
Failure runs graphics recovery/reset and clears it.

Blocking `graphics_synchronize` checks, in order:

| Gate | Busy condition |
| --- | --- |
| VIF1 DMA | CHCR bit `0x100` |
| GIF DMA | CHCR bit `0x100` |
| VIF1 | STAT mask `0x1F000003` |
| VU | Control register 29 bit `0x100` |
| GIF | STAT mask `0xC00` |

One poll counter covers all gates. Exceeding `0x1000000` prints register
diagnostics and returns `0xFFFFFFFF`; success returns zero.
Nonblocking mode returns bits 0..4 for the same busy conditions.
This is a poll-count bound, not an elapsed-time limit.

`graphics_interrupt_handlers_initialize` registers the single
`vif1_dma_handler_record` (`0x00602A08`), whose positive enable value is 99,
channel is 1, and handler is `vif1_dma_interrupt_handler` (`0x00108BA0`).
The handler accepts a 16-byte-aligned VIF1 MADR within
`0x00100000..0x01FFFFFF` and tag-ID state 0 or 7 before asking
`vif1_dma_continue` to process the preceding `RenderDmaContinuation`.

A zero `tag.address` completes the chain: save the completion counter,
disable its channel interrupt, clear transfer-active. Otherwise the optional
`callback` receives `callback_argument`; a NEXT resumes at
`resume_address`, and a RET unwinds the VIF1 return stack.
Unsupported resume tags or an empty RET stack reject continuation.
Handler validation/continuation failure resets graphics and clears active.

**Inference, high confidence for this worker.** While chain N is submitted,
construction uses the alternate list head and master template. Rotation
releases N-1, which the previous iteration's frame wait has finished or aborted.
N remains owned until the following rotation. The shared pool is not split
into two fixed 1 MiB halves. Deferred destruction retains submitted-head blocks
until next-frame recycle.

This is a DMA packet lifetime contract. It does not independently prove that
all GS rendering has completed when the handler clears transfer-active.

## Display and draw environments

EE list rotation, master-template parity and GS bank selection are separate.
`EnginePadContext.display_bank` selects paired GS environments;
`update_counter` selects the EE master template.

With `pacing_bypass == 0` and negative `setup_request`,
`engine_root_update` calls `display_environment_select(display, display_bank ^ 1)`
before renderer-chain submission. Nonzero `pacing_bypass` toggles the bank
without that call. A nonnegative request regenerates display setup through
`engine_install_display_interrupt` and restores `setup_request` to `0xFF`.

With `field_adjustment == 0`, `display_environment_select` writes DISPFB1
and DISPLAY1 from the selected display values. Otherwise it adjusts the
selected draw environment through `gs_draw_environment_adjust_field`,
using the observed GS field bit. It then calls `gs_paired_environments_submit`
and saves the bank.

`gs_paired_environments_submit` selects one `0x28`-byte
`GsDisplayEnvironment` and sends its separately paired draw packet from
`EnginePadContext.draw_environment_packets` through GIF.
`gs_display_environment_write` writes privileged GS registers;
`gif_submit_draw_environment` waits for idle channel 2 then starts normal DMA
with CHCR `0x101`. Its bounded idle wait returns `0xFFFFFFFF` on timeout,
but the pairing wrapper does not propagate that result.

Draw-state GIF submission is separate from the renderer's VIF1 source chain.
Neither path establishes a GS FINISH wait, so complete rasterization is not
proved by these routines.

## Bounded producer and consumer coverage

Direct-call coverage of `render_ordering_insert` is bounded to the resident
program and exposed `BTL.BIN`/`ETC.BIN`; indirect calls, inlined insertion
and other ordering algorithms remain open. The annotation owns the call census.

| Producer | Packet-list contract |
| --- | --- |
| `model_submit_packed_geometry` | Ordinary shared allocation; null omits submission; direct append or ordered negative `CcsModelDrawContext.camera_depth`. [Model runtime](model_runtime.md) owns geometry payloads. |
| `model_dispatch_geometry` | Two model-chain paths supply first/final pairs with negative camera depth; the second can append directly. |
| `particle_sprite_submit` | Reserve `0x1B0`; null omits submission; ordered key is projected Z/W, first is packet base and final is the next tag; other branches append directly. |
| `curve_packet_submit` | More than one accumulated strip is required; key is `CurvePacketState.depth_sum / (2 * strip_count)`; first and final are the same selected packet base. |
| `image_transfer_build_packet` | Reserve `0x90`; null omits submission; append or splice at supplied insertion. Source payload is referenced through descriptor/override, not copied. [Texture palette and material runtime](texture_material_runtime.md) owns transfer-resource meaning. |
| `image_transfer_copy`, `draw_environment_fill`, `draw_environment_submit_2d_record` | Check allocation before writes/appending; requests are `0x110`, `0x90`, and `0x150` or `0x2B0`, respectively. Neighboring owners cover their coordinate/material algorithms. |

`curve_packet_reserve` clears depth/count, toggles `half_index`, and
allocates `(4 * requested_strips + 6) * 0x20` bytes. Each half has
`4 * requested_strips + 6` quadwords.
`curve_packet_append_strip` adds a `0x40`-byte entry and increments
`strip_count` without a local reservation guard.

`puppet_trail_node_submit` and `trail_strip_owner_submit` pre-count entries,
gate filling on allocation success, then finalize through `curve_packet_submit`.
Their paired local halves remain within ordinary per-frame ownership;
half toggling creates no independent persistent packet lifetime.

## Capacity and failure summary

| Storage / operation | Established bound or failure behavior |
| --- | --- |
| Display-created pool | `0x200000` backing bytes including headers, shared by all registered environment lists |
| Pool search | Strictly larger free block required; no match returns zero |
| Bump allocation | No alignment repair; same-owner bytes share a block; owner changes add a header |
| Ordering nodes | 1024 globally, reset per frame; exhaustion omits insertion |
| Ordering depth | At most 50 including root; abandoned depth 51 consumes its node |
| Deferred lists | 16-bit unchecked count; declared queue capacity unresolved |
| Strip reservation | Formula above; fill helper lacks a local overrun guard; inspected callers pre-count |
| Graphics synchronization | Shared `0x1000000` poll threshold; failure `0xFFFFFFFF`, frame wait recovers and clears active |
| GIF draw-state submission | Bounded idle wait; caller ignores its timeout result |

These static capacities establish no utilization, transfer duration, frame
budget or safe additional packet count. Packet sizes, headers, owner switches,
reserved tails and still-owned submitted lists all affect available storage.
