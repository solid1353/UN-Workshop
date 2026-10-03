# Annotation layout repair and verification

Completed on 2026-10-03. Fighter's layout, fresh-project type loading and MCP annotation recovery are repaired. Every declared struct/union was checked against the applied Ghidra layout in every program of its game. No offset or width mismatches remain. This report accompanies the annotation and MCP repairs.

## Confirmed cause

The installed Ghidra 12.1.2 CParser parsed `char (*field)[30]` as an inline 30-byte array rather than a four-byte pointer. Fighter's three name fields added 78 bytes; alignment rounded the displacement to 80 bytes (0x50). The independent parser audit used the installed EmotionEngine data organization, including four-byte pointers and eight-byte long/long long.

Before repair, Fighter.major_state was at 0x1DE instead of 0x18E and update_pause.assigned was at 0x254 instead of 0x204. Live `action_entry_allowed` at NA2/SLPS_258.37:0x00239E50 displayed raw +0x254 as update_pause.assigned and raw +0x18E as capture_distance_cap + 2.

After repair and a clean-project restart, the same function displays action_lock.current, major_state, substate and primary_timeline.current. Matching NA2-clean decompilation accesses +0x254, +0x18E, +0x190 and +0x1C4. `fighter_release_handles` also displays the late owned fields +0xE68/+0xE6C/+0xE70/+0xE74, matching clean accesses.

## Every changed declaration

All type edits used `annotate_type`, with the owning types.h reread immediately before each call. Existing fields were preserved.

| Game | Struct | Fields changed | Replacement and retained interpretation |
| --- | --- | --- | --- |
| NA2 | Fighter | palette_names, texture_names, model_names | `void *`; contiguous records of 30 chars |
| NA2 | AwakeningCharacterRecord | palette_names, texture_names, model_names | `void *`; contiguous records of 30 chars |
| NA2 | SurvivalSaveCourse | opponents | `void *`; contiguous three-byte rows |
| NA2 | EncounterSequenceDefinition | records | `void *`; contiguous three-byte rows |
| NUN3 | Nun3CharacterRecord | palette_names, texture_names, model_names | `void *`; contiguous records of 30 chars |

Total: **11 fields in five declarations**, across NA2/types.h and NUN3/types.h. The three-byte pointer-to-array declarations also parsed as inline arrays; alignment sometimes masked the following-field displacement.

One existing routine prototype changed through `annotate_symbol`: `void fighter_release_handles(int param_1)` became `void fighter_release_handles(Fighter *fighter)`. Its established owner and raw accesses prove the parameter type. Fifteen existing resident routine comments now identify old discrepancies as pre-repair observations, with the confirmed parser cause where previously unresolved. Their raw-offset facts were retained; previous comments and fresh decompilations are saved in fighter-comment-repair-evidence.json.

Five newly identified reader routines were named, given established signatures and commented through `annotate_symbol`. Existing names and uniqueness were checked before naming:

| Game/program | Live entry | Name and prototype |
| --- | --- | --- |
| NA2/SLPS_258.37 | 0x002D3030 | `void sasori_variant75_emit_material_particles(SasoriVariant75Materials *owner, int count)` |
| NA2/BTL.BIN | 0x0083D230 | `void rng_pair_record_update(RngPairRecord *record)` |
| NA2/BTL.BIN | 0x00835B20 | `void auxiliary_parameter_step(char *block)` |
| NUN3/BATTLE.BIN | 0x007E6A40 | `void stage_wire_build_segments(Nun3StageWire *wire, unsigned long long texture)` |
| NUN5/SLES_556.05 | 0x0010F420 | `void renderer_refresh_viewports(void)` |

## MCP startup and recovery repair

The first restart failed because several JVMs could not allocate native memory. Eleven crash logs were preserved. No speculative heap or machine configuration change was made.

A later startup exposed forward-declaration dependencies hidden by previous in-memory applications: ExchangeAttackMotionView in NA2, Nun3ActionRecord in NUN3 and CharacterSelectorFooterView in NUN5. The router rejected even `annotate_type` for a target whose startup annotations failed, preventing the prescribed repair path.

Workshop's maintained implementation was repaired:

- AnnotationApplier registers named struct/union tags and typedef aliases before parsing complete definitions. Alias dependencies are resolved first.
- The router permits `annotate_type` on a failed annotated target. Recovery reapplies the game's complete annotations, including symbols, and clears its unavailable state only after every application succeeds.
- Existing `classes`/`get_info` now exposes actual DataTypeManager composite size, alignment and field offsets, including nested paths and the first element of aggregate arrays. This enables exhaustive applied-layout inspection.
- The shared runbook documents these behaviors and the recovery path.

The maintained installer compiled and installed the Java extension and .NET router successfully. From Workshop, the requested command was run again:

```powershell
& '.\scripts\ghidra\manage_ghidrassist_mcp.ps1' -Action Restart
```

The supervisor log records successful annotation application for **NA2, NUN3, NUN4, NUN5, NUN6 and shared**, then readiness of all 12 annotated/clean targets. Current status also reports Running and Ready. No annotation-loading error remains. See layout-supervisor-success.log.

Installing the router closed the original chat-bound stdio transport. Verification continued through fresh stdio clients of the installed maintained router, using its normal MCP tools/call interface and supervisor. No direct disassembly fallback was used.

## Exhaustive offset and width checks

All annotation directories were searched. Four types.h files exist; NUN6 and shared have none. There are **1,104 named structs and four named unions**.

| Game | Distinct types | Programs checked | Type applications checked | Mismatches |
| --- | ---: | ---: | ---: | ---: |
| NA2 | 982 | 4 | 3,928 | 0 |
| NUN3 | 45 | 6 | 270 | 0 |
| NUN4 | 4 | 6 | 24 | 0 |
| NUN5 | 77 | 9 | 693 | 0 |
| Total | 1,108 | 25 | 4,915 | 0 |

The independent declaration parser audit checked 8,874 top-level components and all 1,950 explicit top-level _pad_/_unknown_ offset anchors. The live DataTypeManager comparison checked 18,576 named/padding component occurrences, including 14,310 meaningful named field occurrences after expanding embedded composites. Another 601 first-array-element component rows were covered by array stride and nested-type comparisons. Unnamed aggregate rows were excluded from name-keyed comparisons; their named children were checked. No named field offset or width differed.

Every program's applied type size, alignment and component offsets/widths were then compared with its game's verified primary program. All 4,915 applications matched, including NUN3's two IOP IRX programs and text overlays.

The syntax audit covered 40 union occurrences, 52 nested-array declarators and one function-pointer typedef; no bit fields were present. No additional size error was established. KernelTimerCallback remains four bytes; KernelTimerRecord.callback is +0x28 and KernelAlarmRecord.callback is +0x08. These declarations needed no change.

Selected repaired Fighter checks:

| Field | Verified offset |
| --- | --- |
| palette_names / texture_names / model_names | 0x98 / 0x9C / 0xA0 |
| major_state / substate | 0x18E / 0x190 |
| primary_timeline.current | 0x1C4 |
| update_pause.assigned / update_pause.current | 0x204 / 0x20C |
| action_lock.current | 0x254 |
| current_action / initial_actions | 0xA3C / 0xA58 |
| owned_handle_e68 / model_collection / owned_animation_player / owned_handle_e74 | 0xE68 / 0xE6C / 0xE70 / 0xE74 |
| embedded_children | 0xEA4 |
| Total Fighter size | 0xEB4 |

## Large-struct decompilation checks

All **289 types of at least 0x100 bytes** have saved annotated/clean comparisons: NA2 266, NUN3 12 and NUN5 11. large-struct-reader-verification.tsv records each selected routine or receiver chain, field offset and supporting clean expression. verified-reader-decompilations.jsonl holds 284 unique function pairs. NUN4's four smaller structs have additional paired evidence in nun4-offset-evidence.json.

Receiver ownership was reviewed rather than treating an unrelated object's matching displacement as proof. Adjusted pointers and embedded/array receivers were calculated explicitly:

| Type | Checked field | Calculation or paired evidence |
| --- | --- | --- |
| AiState | phase_cursors +0x1B4 | 0x008D6744 minus ai_states base 0x008D6590; side stride 0x1E0 |
| AuxiliaryParameterView | secondary_flag +0xBB8 | caller passes owner+0xBB0; helper reads block+8 |
| BtlSawarabiRecord | state +0x134 | parent read +0xC24 minus record base +0xAF0; stride 0x340 |
| BtlTndRecord | completion_latched +0x141 | group read +0x2A1 minus child base +0x160; stride 0x150 |
| FighterCcsSide | paths +0x24 | path base +0xB70 minus containers base +0xB4C |
| ItemChakraPickup | final_decay_alpha +0x190 | loop reads +0xB0 + 7*0x20 |
| PuppetTrailSample | points[15].projected_position +0x300 | sample+0x10 + 15*0x30 + point+0x20; caller and segment reader checked |
| RendererOwner | embedded_renderer.next +0x428 | owner+0x1C0 passed through destroy to list reader at renderer+0x268 |
| SphereSnapshotBank | count +0x800 | manager+0x1A20 minus bank base manager+0x1220; stride 0x810 |
| TentenCallbackState | phase_entry_count +0x5BB5 | fighter+0x5BB0 local pointer, signed byte +5 |
| ToneShadeRenderContext | tone_destination +0x250 | clean 16-byte array receiver index 0x25 |
| Nun3StageWire | second_endpoint +0xF0 | segment builder reads +0xE0/+0xF0 separation |
| RunningHelpViewportView | viewport_height +0x290 | refresher reads +0x284/+0x288/+0x28C/+0x290 |

Four large records require a transfer-boundary qualification: AudioPacket is read as a complete 0x100-byte DMA transfer; CardIconSystem is passed as a complete 0x3C4-byte file write; ModelMaterialStatePacket and ShadowProjectionPacket are produced and consumed as VIF/DMA command streams. Their tail layouts and producer/transfer boundaries were checked, but separate scalar CPU tail readers were not established. The final table labels these four cases explicitly.

CharacterSelectData's proven late array reader accesses fighter_portraits +0x24C, whose 96 pointers extend through +0x3CB. A direct support_portraits +0x3CC reader was not established; the support-portrait routine also uses fighter_portraits. All declared fields, including support_portraits, passed the applied-layout check.

These checks establish applied offsets and widths plus selected raw reader/transfer contracts. They do not claim every field's meaning was independently rediscovered from machine code.

## Saved evidence and changed files

Detailed evidence is retained locally in the original task work folder and is not included in this repository:

- layout-before.tsv and layout-after.tsv: installed-parser layouts before and after repair.
- struct-verification.tsv: complete inventory and completed statuses.
- live-layouts.jsonl and live-layout-verification.tsv: actual applied primary layouts and per-type counts.
- live-layout-differences.json and all-program-layout-differences.json: both empty arrays.
- all-program-layout-verification.tsv: every program's checked-type count.
- large-struct-reader-verification.tsv and reader-review.json: final per-large-type results.
- verified-reader-decompilations.jsonl: selected live/clean pairs and supporting receiver chains.
- nun4-offset-evidence.json: paired checks of NUN4's four types.
- fighter-comment-repair-evidence.json: previous comments and fresh decompilations.
- layout-supervisor-success.log: successful startup and all-game annotation application.
- layout-supervisor-failed-annotations.log, layout-supervisor-first-restart.log and layout-crash-*.log: earlier failure evidence.

Tracked changes are confined to Workshop:

- reverse_engineering/annotations/NA2/types.h and NUN3/types.h.
- NA2/SLPS_258.37/symbols.tsv, NA2/BTL.BIN/symbols.tsv, NUN3/BATTLE.BIN/symbols.tsv and NUN5/SLES_556.05/symbols.tsv.
- scripts/ghidra/GhidrAssistMcpRouter/Program.cs.
- scripts/ghidra/ghidrassistmcp-2.11.0-hardening.patch.
- docs/runbooks/ghidrassistmcp.md.

The original report and evidence remain in the existing task work root. Temporary scripts and discarded candidate-match outputs were removed after final evidence was saved. Maintained compilation, restart, live MCP checks and git diff --check succeeded.
