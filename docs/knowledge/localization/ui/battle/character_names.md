# Battle HUD character-name renderer

## Research coverage

Established: the shared mirrored X anchors, scaled Y placement, renderer
ownership, destination lifetime and NUN5 width cap. No open question is
recorded for this bounded path. Screen evidence covers 74 populated character
cells at 640 pixels; destination lifetime also has one prior native-renderer
capture. Names come from `@annotations/NA2` and `@annotations/NUN5`; annotation
comments hold the code-level detail. All addresses below are live.

Binary identities and address conventions are defined in the
[Standard game file identities](../../../game/files/file_identities.md).

## Screen evidence

Idle battle screenshots of 74 populated character cells show that, in
every cell, retail NA2 places the Player 1 name exactly 20 output pixels to the
right of NUN5 and the Player 2 name exactly 20 output pixels to the left. At the
640-pixel capture width, that symmetric difference corresponds to 16 units in
the game's 512-unit logical coordinate system. Together with the shared
renderer constants, this identifies the mirrored anchor as the cause of that
uniform difference; it does not require character-specific data or font-metric
changes.

## Renderer and X anchor

Both games use `hud_name_draw` in `BTL.BIN`: NA2 at `0x0071BE20`, NUN5 at
`0x00731DC0`. The name child borrows its effective anchor, scale and side from
its parent (`BattleHudName.parent` / `BattleTopPanel` in NA2,
`BattleHudNameView.parent` / `BattleHudNameAnchorView` in NUN5).

With `local_x = hud_name_local_x * parent.scale` and the scaled sprite width,
placement is:

```text
left:  x = base_x + local_x
right: x = base_x - local_x - rendered_width
```

Here `base_x` is the parent's `draw_x`; side zero selects the left formula and
nonzero side selects the right. The shared constants are:

| Game | `hud_name_local_x` | Value | `hud_name_local_y` | Value |
| --- | --- | ---: | --- | ---: |
| NA2 | `0x008C42D8` | 90.0 | `0x008C42DC` | 44.0 |
| NUN5 | `0x008DC8F8` | 74.0 | `0x008DC8FC` | 44.0 |

`ProjectedTextGeometryView.source_width` and `source_height` supply the source
dimensions. NA2 scales both directly by the parent scale. NUN5 additionally
shrinks source widths above 160 to 160 before parent scaling, without changing
height or enlarging narrower names. The right formula subtracts the resulting
rendered width, so width fitting and mirrored placement must agree.

## Y path and destination lifetime

Both renderers place Y at `parent.draw_y + hud_name_local_y * parent.scale`.
They publish `x`, `y`, `width` and `height` in the name sprite's
`ProjectedTextGeometryView` before submitting it.

NA2 obtains the sprite destination before loading either local coordinate and
keeps that destination through the X/Y stores. An intervening hook must
preserve that destination, parent scale and side-dependent placement. The
exact load sites, bytes and destination register are recorded in the
`hud_name_draw` annotation; the prior capture confirms the same lifetime.
