# Controller and help UI

## Research coverage

Established: three Controls help strings have matching NA2/NUN5 table slots;
a fourth controller restriction has an apparent wording counterpart. Open:
the fourth string's consumer and screen ownership, visible coverage of the
four strings, and whether all four belong to one structural family.
Names come from `@annotations/NA2` and `@annotations/NUN5`; addresses are live.

Controls lifecycle, help ordering, nine-row geometry and frontend prompts
belong to [Shared frontend prompt layout](options.md#native-controls-lifecycle).
Queue movement and extent belong to [Running help](running_help.md), and
Command Chart relationship geometry to [Controls Font layouts](../font/screen_layouts/controls.md).
Established source and donor relationships belong to
[NA2 and NUN5 text correspondence](../translation_importer.md).

## Unresolved executable targets

The four earlier file-location leads identify string storage, not routine
entries. The shared names below resolve separately in each game's annotations:

| String | NA2 resident live address | NUN5 English live address | Established relationship |
| --- | --- | --- | --- |
| `controller_port2_restriction` | `0x005B1D30` | `0x008F59B0` | Both describe a controller in port 2 being unusable in the current mode; the consumer and exact screen remain unresolved |
| `controls_item_select_restriction` | `0x005B23E0` | `0x008F5080` | Controls help slot 5; Item Select requires L1/R1 or L2/R2 |
| `controls_player1_edit_notice` | `0x005B2480` | `0x008F50D0` | Controls help slot 6; completion is blocked while 1P is making changes |
| `controls_player2_edit_notice` | `0x005B24D0` | `0x008F5100` | Controls help slot 7; completion is blocked while 2P is making changes |

NA2's resident `controls_help_messages` and NUN5's English
`controls_help_messages` in `TEXTENG.BIN` establish the same-slot relationships
for the three Controls notices. NUN5 `localized_controls_help_text`
(`0x003D1210`) selects the current language's table through
`controls_help_language_tables`. Confirmation requires both players to be
outside active editing; the blocked notice identifies the other player.
These static relationships establish Controls ownership for those three
strings without establishing their visible coverage.

The controller-port restriction remains a wording correspondence alone.
Neither that resemblance nor adjacent storage establishes its reachability,
exact screen, or membership in the Controls help family. No screen trace is
recorded for these four candidates.
