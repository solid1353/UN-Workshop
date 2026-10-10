# End-demo presentation

## Research coverage

Established: requests, both lookup tables, win-instance binding, drawing and
teardown, and shared appearance selection with character-specific gates.
Open: direct cached-slot 5..14 consumers, nine other states, visible phase
and state names, and the full extent of `end_demo_character_request_path`.
Static evidence covers eight win animations in four pairs;
it does not establish all character attachments or indirect callers.
Names and field views come from `@annotations/NA2`; addresses are live.

Retail NA2 (`SLPS-25837`) uses the pause-controller child selected by
`AwakeningPauseGate.selector == 1` for this presentation. “End-demo” is
the functional identification in
[Shared ownership and controller lifecycle](../session/pause_and_replay.md#shared-ownership-and-controller-lifecycle),
not a recovered native name.

Selector dispatch, controller lifetime and pause-suppression writes belong to
[Pause and replay](../session/pause_and_replay.md#proven-btl-suppression-writers).
The 3EYE/3PCT filename tables and 3EYE-to-1BOD1 dependency belong to
[Character asset tables](../../game/character_assets.md#ccs-format).
Generic construction and hierarchy binding belong to
[Model and skeleton runtime](../../runtime/rendering/model_runtime.md#animation-binding-to-scene-nodes),
playback and target lifetime to
[Animation runtime](../../runtime/animation_runtime.md#descriptor-and-player-separation),
material binding to
[Texture and material runtime](../../runtime/rendering/texture_material_runtime.md#material-binding-and-coordinate-updates),
and packet ownership to
[Render submission](../../runtime/rendering/render_submission.md).
[Resident CCS runtime](../../game/files/ccs_runtime.md#loading-and-cancellation)
owns loading and queue contracts.

## Evidence and address conventions

Inputs and live address conventions follow
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
The evidence is static resident ELF, BTL and clean CCS reads; CCS files were
gzip-decompressed in memory. The eight sampled animations establish body/face
provider links, without a complete geometry decode or coverage of every
character attachment. Direct-call searches do not exclude indirect callers.

The following resident ELF BSS globals have saved annotations. The three
family-indexed arrays contain two actor entries per family; the request path
buffer's full extent remains unestablished.

| Resident global | Established role |
| --- | --- |
| `end_demo_character_container` | Adopted selected-character 3EYE container handle |
| `character_appearance_holders` | Three pairs of shared appearance lookup holders |
| `character_selection_containers` | Published borrowed containers, indexed by family and actor |
| `character_selection_codes` | Published three-byte character codes packed into words for template substitution |
| `end_demo_character_request_path` | Formatted selected-character 3EYE request path buffer |

## Request and lookup

This request family is separate from the nine per-side request slots.
`end_demo_request_character_ccs` (`0x001E90F0`) requests
`3eye/<3EYE basename>`. An already published container becomes the adopted
global handle; a miss queues the file and clears that handle.
The request neither starts the queue worker nor releases a different
previously held container before replacing the handle.
`end_demo_adopt_character_ccs` (`0x001E9180`) performs lookup only while
the handle is zero; `presentation_completion_notify` (`0x001E91E0`)
destroys and clears a nonzero handle.

`rng_case5_state_update` (`0x0076CC00`) uses the eleven-target
`rng_low31_switch_table` (`0x008CADA0`). Its established loading order is:

1. `end_demo_request_state` requests the selected character's 3EYE file
   and `3eye/enddemo.ccs` (`end_demo_ccs_path`), starts the queue worker,
   then advances the controller state.
2. `end_demo_adoption_state` waits for the initial animation's completion
   and no active worker, clears the queue, adopts 3EYE, looks up the separate
   `enddemo` container into `EndDemoController.enddemo_container`, then
   calls `end_demo_setup_resources` (`0x0076C670`).

This establishes ordering, not successful loads or player-facing state names.
The remaining nine states are outside the established presentation coverage.

Setup publishes both characters through `manager_publish_six_selections`
(`0x001E1530`; see
[Character asset tables](../../game/character_assets.md#publish-six-match-asset-selections)),
then initializes both `EndDemoController.lookups` with actors 0 and 1,
each using the fifteen rows of `end_demo_lookup_templates`
(`0x008CA010`):

| Lookup slots | Provider family | Name templates |
| --- | --- | --- |
| 0, 1 | 3EYE, family 2 | `ANM_3xxxwin00`, `ANM_3xxxwin10` |
| 2, 3 | 3EYE, family 2 | Both `ANM_3xxxeye00` |
| 4 | 3EYE, family 2 | `ANM_3xxxnut00` |
| 5 | 1BOD1, family 1 | `CLT_1xxxbodyc1` |
| 6, 7 | 1BOD1, family 1 | Both `CLT_1xxxbod2c1` |
| 8, 9 | 1BOD1, family 1 | `CLT_1xxxbodyc2`, `CLT_1xxxbod2c2` |
| 10 | 1BOD1, family 1 | `TEX_1xxxbod2` |
| 11..14 | 1BOD1, family 1 | `MDL_1xxx00t0 body`, `MDL_1xxx00t0 eye1`, `MDL_1xxx00t0 eye2`, `MDL_1xxx00t0 mou1` |

`character_lookup_holder_initialize` (`0x001E19D0`) allocates a
`CharacterResourceLookupHolder.resources` array and borrows pointers from
the actor's published provider. `character_resource_name_format`
(`0x001E16A0`) replaces literal `xxx` with the corresponding published
three-byte character code. For these family-1/family-2 rows,
`animation_find_by_name` (`0x001A8F00`) uses optional lookup:
a missing container or name gives a zero slot. This differs from common
fighter setup's required model lookup. Initializing the holders neither
loads files nor materializes the returned models.

## Cleanup and teardown

Teardown keeps four ownership layers separate:

1. `end_demo_release_instances` (`0x0076C2E0`) releases the eight
   `EndDemoController.regular_players` and the players in its three
   `repeated_instances`, then destroys its separate `enddemo_container`.
2. `pause_end_demo_release` (`0x0076F840`) reaches that cleanup,
   frees the `EndDemoModelWorkView.work` allocations of
   `selected_instance.work_targets`, clears both retained targets,
   then destroys and clears `selected_instance.player` through
   `animation_player_destroy` (`0x001B7570`) with delete flag 1.
3. `end_demo_lookup_holder_destroy` (`0x0076F980`) receives delete
   flag -1 from the two-holder array teardown and frees only each borrowed
   pointer array.
4. Wrapper completion finally calls `presentation_completion_notify`
   to release the adopted selected-character 3EYE container.

The lookup-holder destructor does not release the 1BOD1 provider container.
Freeing retained model work is instance cleanup, not container release.

## Animation instances and model adoption

The controller's `configuration.mode` selects the actor; its
`configuration.character_id[actor]` selects the character.
`pause_branch_resource_setup` (`0x0076BA70`) uses
`character_lookup_holder_get` (`0x001E19A0`) to select
`lookups[actor].resources[animation_slot]`. A zero resource leaves the
instance unchanged. The two established win selections use slots 0 and 1
and `EndDemoController.selected_instance`.

For a nonzero selection, setup frees and clears both retained
`work_targets`, creates a player if needed, binds the selected animation
with zero blend through `animation_attach` (`0x001B99B0`), and clears
`EndDemoAnimationInstance.complete`.
`animation_collect_matching_targets` (`0x001BAA20`) then collects the
player's model targets using `model_target_name_pattern` (`MDL_*`).

The ordinary appearance branch prepares each collected model through
`model_instance_duplicate_arrays` (`0x00198B10`). Models with
`EndDemoModelWorkView.flags & 0x804` receive nonzero texture and palette
choices from `character_appearance_select` (`0x001E1760`), through
`model_rebind_part_textures` (`0x00198990`) and
`model_instance_rebind_palettes` (`0x00198AB0`).
These choices use the separate shared appearance holders described below,
not the controller's fifteen-entry arrays. Neither those fifteen entries
nor these appearance calls prove direct consumption of cached slots 5..14.

**Clean-file observation:** Both `win00` and `win10` in
`3NRT3EYE`, `3KNW3EYE`, `3CHY3EYE` and `3SIN3EYE` contain
typed `0x0102` tracks for the body, two eyes and mouth. These select local
`0x0A00` wrappers linked to the same-code external
`#c\1???\max\1???bod1.max` provider. Body wrappers attach to the local
pelvis track; eye/mouth wrappers attach to the local head track.
In the corresponding four `1???BOD1` files, provider `0x0100` object
records select the exact `MDL_1???00t0 body/eye1/eye2/mou1` models with
the same parent names.

For example, the first `3NRT3EYE` animation's body wrapper ID 103 uses
parent ID 7 (`pelvis`) and external provider ID 104; eye1 wrapper ID 37
uses parent ID 35 (`head`) and provider ID 38.
`win10` has different local wrappers and parents but shares the external
provider records. This gives an attachment path independent of directly
reading the four cached model slots.

The reads cover these eight animations and matching body/face descriptors.
They do not establish complete geometry decoding or every character-specific
attachment.

**Inference, high confidence:** A new player has no pre-attached composition
list after `projectile_compound_initialize` (`0x001B7520`).
Binding these tracks therefore follows wrapper/provider records to create
scene nodes and runtime models, then attaches them according to the local
parent map. `ccs_parse_animation_tracks` (`0x001A29D0`) builds that map;
`ccs_resolve_external_record_chain` (`0x00116210`) resolves providers;
`animation_scene_child_initialize` (`0x001BA930`) and
`ccs_scene_child_bind_models` (`0x00196B40`) materialize their models.
The generic contract remains in the linked model-runtime owner.
The bounded consumer scan establishes the win selections, without proving
cached slots 5..14 unused by other code or differently formed aliases.

## Selected-instance drawing

`pause_end_demo_effect_update` (`0x0076DCF0`) skips its whole body in
state 8. Otherwise `EndDemoController.flags & 0x400` gates drawing the
selected instance. It temporarily offsets the selected player's
`CcsAnimationPlayer.camera` node's
`EndDemoDrawNodeView.local_translation` by `(-20,+20,-70)`, calls
`projectile_compound_submit` (`0x001BB790`), then restores all four
original words. Regular animation instances use the same submission helper
with controller-selected renderers.

The submission helper draws flagged bound type-`0x0100` nodes and
type-`0x0E00` effects. Animation-created character nodes therefore reach
submission; borrowed model descriptors alone are not drawable instances.

## Appearance resources

`character_appearance_holders_initialize` (`0x001E13A0`) creates three
pairs of shared nine-entry holders, one per actor in each pair. The family-1
pair uses `character_body_appearance_templates` (`0x005C0570`),
whose every row selects provider family 1:

| Shared slot | Resource template |
| --- | --- |
| 0 | `CLT_1xxxbody` |
| 1 | `CLT_1xxxbodyc1` |
| 2 | `CLT_1xxxbod2` |
| 3 | `CLT_1xxxbod2c1` |
| 4, 5 | Both `CLT_1xxxbodyc2` |
| 6 | `CLT_1xxxbod2c2` |
| 7 | `TEX_1xxxbody` |
| 8 | `TEX_1xxxbod2` |

These use the same template substitution and optional lookup as the
fifteen-entry table. `battle_character_pair_prepare` (`0x0035CE20`)
publishes both characters and builds these shared holders; shared setup is
distinct from later local end-demo setup.
`battle_create_graph` (`0x001EF330`) and the cinematic callback
`sp_skill_play_begin` (`0x0035A070`) reach this shared setup.

`character_appearance_select` clears both outputs and dispatches unsigned
selectors below 7 through `character_appearance_selector_targets`
(`0x005C05C0`):

| Appearance selector | Texture slot | Palette slot | If texture slot 8 is zero |
| --- | ---: | ---: | --- |
| 0 | 7 | 0 | — |
| 1 | 7 | 1 | — |
| 2 | 8 | 2 | Retry selector 0 |
| 3 | 8 | 3 | Retry selector 1 |
| 4 | 7 | 4 | — |
| 5 | — | — | Outputs remain zero |
| 6 | 8 | 6 | Retry selector 4 |

Selectors outside this dispatch leave both outputs zero. The end-demo
caller passes family 1, applies texture before palette, and skips each zero
output independently. Model flags and character-specific gates restrict
which collected models change; this is not a blanket replacement of every
body/eye/mouth material.

For selected win slots 0/1 and model flags including `0x804`,
`pause_character_resource_query` (`0x0076E180`) compares character ID
and exact model name. Result 0 skips ordinary appearance; -1 selects the
separate palette lookup; 10/11 select two retained model-work blocks.
Representative established branches are:

| Character ID | Model names | Appearance behavior |
| ---: | --- | --- |
| 18 | `MDL_1krs00t0 body`, `MDL_1mnt00t0 mant` | Result -1, but the separate palette helper returns zero: no override through this path |
| 60 | `MDL_1krs00t0 body`, `MDL_2kar00t0 bod2`, `MDL_1kar00t0 mant` | Skip ordinary appearance |
| 60 | `MDL_1mnt00t0 mant`, `MDL_1kar10t0 mant2` | Retained model work |
| 62 | `MDL_st5600t0 body`, `MDL_st5600t0 hed`, `MDL_st5700t0 hed` | Skip ordinary appearance |
| 62 | `MDL_st5601t0 body` | `pause_character_effect_query` (`0x0076E7C0`) selects `CLT_st56bodyc1` from `3chy3eye` |

When `0x804` is clear and appearance bits `& 5` are nonzero,
`pause_character_animation_query` (`0x0076E870`) also handles ID 17's
`MDL_3sinpok01` and `MDL_3sinpok02`. It looks up `3sin3eye` and
chooses `CLT_3sinbodyc2` when appearance bit 4 is set, otherwise
`CLT_3sinbodyc1`. These special resources come from 3EYE itself; the
shared family-1 appearance table is a separate provider.
