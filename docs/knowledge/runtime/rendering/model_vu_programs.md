# Model VU programs

The VU uploads, geometry evaluation, strip controls and output contracts of
retail NA2 (`SLPS-25837`) model rendering.

## Research coverage

Established: descriptor selection, representative geometry/output contracts,
clipping/storage bounds and six body samples. Open: complete variant semantics,
asset validity and observed use. Names come from `@annotations/NA2`.

## Evidence conventions

EE addresses below are live resident addresses in `SLPS_258.37`, following
[address conventions](../../game/files/file_identities.md#address-conventions).
An embedded upload stream has an EE address, but its VU instruction entry and
VU data slots belong to separate address spaces. Stream labels are data, not
EE routines. VU instruction indices below identify entrypoints, not EE calls.

The evidence is static retail code and a bounded sample of retail character
CCS files. Upload presence and a conditional selector outcome do not establish
execution by a particular character or a roster-wide distribution. The resident
MCP import exposes EE code and bytes; the embedded VU decoding used PCSX2's
VU/VIF definitions, recorded with the stream annotations.

Coverage includes all 42 nonnull descriptor upload streams and shared setup
and continuation. Semantic conclusions are bounded to representative
weighted/rigid, lighting, strip-control, two-pass and six-plane clipping bodies.
Later selector changes, exceptional arithmetic and the supported asset domain
beyond the sample remain open. Annotation comments carry the code details.

Related owners: [Model runtime](model_runtime.md) owns CPU readers, skeletons,
morphs and strip normalization; [Render submission](render_submission.md) owns
DMA chain lifetimes; [Renderer coordinates](renderer_coordinates.md) owns CPU
transform state; [Texture and material runtime](texture_material_runtime.md)
owns CPU material state; [Visibility](visibility.md) owns whole-model
admission; [Shadow rendering](shadow_rendering.md) owns its separate producer
family.

## Initial upload boundaries

`model_vu_descriptors` (`0x005BEEC0`) contains 136 `ModelVuDescriptor` slots,
including gaps and null uploads. `model_renderer_static_initialize`
(`0x005D6A30`) fills their instruction entries and rounded upload lengths;
zero lengths in the imported image are pre-initialization data. Descriptor 0
uploads `model_vu_upload_000` (`0x003BDD90`) with length `0x280` and VU entry 0.
The annotation records the complete initializer bounds.

`model_submit_packed_geometry` (`0x0018FFB0`) and
`model_build_ordinary_vif_setup` (`0x00192AE0`) select the descriptor by adding
`CcsModelDrawContext.base_selector`, `direction_selector` and
`geometry_selector`. `upload_stream` and `upload_bytes` supply the REF payload;
`instruction_entry` supplies its VU start and `gif_registers` its output list.

The nonnull descriptor streams upload the replaceable low program at VU
instruction 0, adding an upload at instruction `0x100` for longer bodies.
Each instruction pair has eight bytes, lower word before upper word. An MPG
count of zero means 256 pairs; rounded DMA sizes also include command words
and padding. It is therefore necessary to distinguish a descriptor's upload
length from its instruction count.

`model_vu_frame_prefix` (`0x003CEA30`) installs eight shared instruction
regions above the low program, then sets VIF BASE 0 and OFFSET `0x200`.
The segment destinations, pair counts and extents are in its annotations and
those of `model_vu_shared_upload_35c`, `model_vu_shared_upload_458`,
`model_vu_shared_upload_52f`, `model_vu_shared_upload_61e`,
`model_vu_shared_upload_6a7`, `model_vu_shared_upload_706` and
`model_vu_shared_upload_791`. [Frame submission](render_submission.md#frame-chain-and-vif1-submission)
owns its DMA lifetime. This establishes separation from the replaceable low
program, without assigning every shared body to model rendering.

## Packed influence evaluation

The representative packed bodies are `model_vu_upload_025` (`0x003C86C0`,
468 pairs), `model_vu_upload_024` (`0x003C9580`, 398),
`model_vu_upload_033` (`0x003CA210`, 372) and
`model_vu_upload_032` (`0x003CADD0`, 364). Their first header distinguishes
weighted marker `0x8000` from rigid marker `0xC000`; continuation retains the
chosen setup instead of interpreting each batch as a fresh first batch.

`ccs_convert_weighted_vif` (`0x001AE950`) supplies this layout relative to VIF
TOP. Influence index `i` and logical vertex index `v` are distinct; UV is
already placed for the compacted logical vertex.

Each view below describes one 16-byte VU data slot after unpacking, with four
32-bit lanes. The input streams retain their separate influence or vertex
index; these views do not form a single per-influence record.

| VU data slot relative to TOP | View | Established fields |
| --- | --- | --- |
| `0` | `ModelVuWeightedHeader` | X `vertex_count_and_flags = vertex_count + 0x8000`; Y `logical_vertex_end = 4 * vertex_count + 1`; Z `first_batch_marker = 0x8000` in the first weighted batch, zero thereafter; W consumer meaning remains unknown |
| `1 + 4*i` | `ModelVuWeightedControl` | X `scaled_weight`: low-nine-bit weight shifted left four; Y `palette_address = 0x50 + 4 * bone_index`; Z `list_count`: narrowed list count at its first influence, one thereafter; W remains unknown |
| `2 + 4*v` | `ModelVuWeightedUv` | X/Y `u` / `v`: masked source UV halfwords expanded into VU lanes; Z/W meaning remains unknown |
| `3 + 4*i` | `ModelVuWeightedAttribute` | X/Y/Z `direction_x` / `direction_y` / `direction_z` and W `strip_control`: sign-extended source bytes |
| `4 + 4*i` | `ModelVuWeightedPosition` | Float `x` / `y` / `z`; W remains unknown |

VIF cycling scatters these streams into interleaved slots. The reader,
terminators and original halfword position scale are owned by
[Model runtime](model_runtime.md#packed-geometry-influences-and-matrix-palette).
The command words, source widths and unpack evidence are in the converter
annotation. Unknown lanes retain their numeric slot positions above.

For each influence, the weighted body transforms position by the palette
matrix's three XYZ columns plus translation, transforms direction by the XYZ
columns without translation, and multiplies both by
`encoded_low_nine_bits / 256` before accumulating them separately. The signed
direction bytes become float integers without a preceding division by 64.

It normalizes the accumulated XYZ direction using its reciprocal length and
compacts direction and position into one four-slot record per logical vertex.
Input advances once per influence; output advances once per logical vertex.
Position is not divided by a weight sum. Zero-length or cancelling direction
sums have no established asset-level contract.

This differs from the inspected
[CPU property-skinning direction loop](model_runtime.md#property-geometry-and-cpu-skinning),
which omits the position weight multiplier. Each route retains its own
arithmetic contract.

The rigid path uses one shared palette address from header W. It composes that
matrix with the global position matrix, separately combines its three direction
columns with the global direction matrix, and obtains three reciprocal lengths
for direction setup. `ccs_convert_rigid_vif` (`0x001AF9D0`) supplies
`0x50 + 4 * palette_selector`; its vertex stream has no per-influence weights.

## Entrypoint selection and continuation

`model_dispatch_geometry` (`0x001910E0`) chooses the three descriptor
contributions in `CcsModelDrawContext`:

| Contribution | Selection |
| --- | --- |
| `base_selector` | Retained visibility classification minus one, plus 2 with runtime flag `0x10000` |
| `direction_selector` | Initially 0; 4 for ordinary direction/light setup; 8 for the alternate attachment path |
| `geometry_selector` | Adds `0x18` for packed flag `0x04`, `0x30` for CPU-evaluated property flag `0x0800`, and optionally `0x48` for the selected runtime flag mode |

The ordinary non-property clipping gate adds `0x10` to `direction_selector`
when `ModelDrawBase.clipping_enabled` is nonzero, that selector is below five,
and `base_selector` is odd. The packed delegation occurs before this gate.

When `alpha < 0.9921875`, the mode is runtime bits `0x01800000` shifted by 23;
otherwise it is bits `0x00600000` shifted by 21. Mode 1 adds the parallel bank
and sets `strip_sign = -1.0`; mode 2 adds it and sets `+1.0`. These are
selection values, without inferred names for the source flag fields. Shared
upload pointers do not imply identical entries or setup.

| Descriptor indexes | Selected uploads or shared VU instruction entries |
| --- | --- |
| `0..3` | Short ordinary `model_vu_upload_000`, `model_vu_upload_001`, `model_vu_upload_002`, `model_vu_upload_003`, entry 0 |
| `4..7` | Direction/light `model_vu_upload_004`, `model_vu_upload_005`, `model_vu_upload_006`, `model_vu_upload_007`, entry 0 |
| `8..11` | Alternate `model_vu_upload_008` / `model_vu_upload_009`, by parity |
| `12..15` | Null upload; shared entries `0x61f` / `0x6a8` |
| `16..19`, `20..23` | Longer clipping `model_vu_upload_016` / `model_vu_upload_020`, repeated across four selectors |
| `24..31` | Packed direction/light `model_vu_upload_024` / `model_vu_upload_025`, by parity |
| `32..35` | Packed alternate `model_vu_upload_032` / `model_vu_upload_033` |
| `36..39` | Null upload; shared entries `0x459` / `0x35c` |
| `48..59` | Property-evaluated ordinary/alternate uploads; CPU supplies float geometry |
| `60..63` | Null upload; shared entries `0x707` / `0x792` |
| `72..135` | Parallel bank selected by `+0x48`; shared clipping pointers, separate direction/packed variants and corresponding shared entries |

There are further empty slots. The table identifies static selection and
uploads, without naming visibility variants or asserting character use.

Ordinary setup uploads 17 vectors beginning at VU data slot 0 and starts
shared VU instruction `0x304`. This loads the global position and direction
columns and associated setup vectors, then computes three reciprocal lengths
from componentwise squared direction-column sums. It applies no per-vertex
position and emits no geometry.

Geometry batches use MSCNT to continue after the current program's end,
retaining matrix setup. The short ordinary continuation reads the next TOP
and header and returns to vertex processing. Packed continuation can retain
rigid processing or return to weighted initialization. Matrix setup and batch
continuation consequently have different lifetimes.

## Shared direction-offset programs

The null-upload groups select already installed bodies with GIF list `0x5fff`:
three NOP slots followed by XYZ2. They use direction to offset position,
a separate operation from computing RGB through direction-driven lighting.

Shared VU entry `0x61f` produces the homogeneous result
`M * [p + s*n, 1]`, then divides by W and emits XYZ2. Here `p` is the ordinary
fixed-point position converted by `/4096`, `n` is the signed-byte direction
converted to float integers, and `s` is VU data `0x14.x`. Entry `0x6a8` uses the
same construction with plane checks. Float-property entries `0x707` and
`0x792` consume float position/direction without those ordinary conversions.

Shared packed entry `0x35c` first splits weighted and rigid inputs. Its
weighted path accumulates and normalizes direction, compacts logical vertices,
and applies the offset with columns scaled by VU data `0x17.x`. Its rigid
path composes the palette matrix and uses `0x18.w` for scaled position columns,
with signed-byte direction converted to float integers. Entry `0x459` also
contains weighted and rigid paths followed by the offset construction.

`model_build_material_vif_setup` (`0x00192740`) supplies ordinary `0x14.x`
from `ModelDrawBase.direction_offset` and the selected descriptor register list
and sign parameters in slot `0x15`. The arithmetic alone does not establish
the higher-level purpose of those scalar writers.

## Projected-triangle sign controls

The parallel descriptor bank selects projected-XY edge calculations that
contribute to XYZ2 controls. `model_vu_upload_072` (`0x003C48F0`) forms a
projected cross-product sign from successive post-divide positions and adds
that sign contribution to the source-derived control.

Setup supplies `strip_sign` and `-1.0`; the program uses the former as its
initial XY edge factor and flips it as the strip advances. This accounts for
alternating strip winding. The contribution is added to a source integer
adjusted by `0x7fff`, so it can change ADC bit 15 through addition. It is not a
direct bit-15 OR.

`model_vu_upload_097` (`0x003CB950`) combines the sign contribution with
rolling plane flags and source-control adjustment. The short base ordinary
`model_vu_upload_000` lacks this projected-edge family. The
[selected control consumers](#source-strip-controls-and-their-selected-consumers)
below do not establish identical semantics for every variant or source byte.

## Geometry, direction and GIF output

The short ordinary body transforms signed fixed XYZ at `/4096`, divides by
homogeneous W, and converts projected XYZ to integer coordinates with four
fractional bits. Its UV halfwords use the same `/4096` conversion and Q for
perspective correction. The alpha lane becomes float, is multiplied by its
setup scalar, and becomes integer again. The property representative
`model_vu_upload_048` (`0x003BE8B0`) transforms float XYZ directly.

The ordinary lighting representative `model_vu_upload_004` (`0x003BF2A0`)
converts signed direction bytes to float integers, applies a first three-column
matrix stage and clamps against zero, then applies a second stage plus ambient
color, clamps to the setup upper RGB limit and converts to integer. Packed
`model_vu_upload_025` uses the corresponding stages after weighted direction
normalization, with an inspected upper clamp of 255. Neither establishes an
inverse-transpose normal transform for arbitrary nonuniform matrices.

Alternate ordinary `model_vu_upload_008` (`0x003C24B0`) uses a scalar direction
dot product instead of the full RGB chain. It scales slot `0x16`'s coefficients
by `1/64`, converts signed direction bytes to float integers, and clamps the
dot product against zero for texture arithmetic. Float-property alternate
`model_vu_upload_057` (`0x003C17B0`) uses float direction and unscaled
coefficients. There is no universal byte-to-normal scale across these routes.

### Output passes and continuation

The ordinary alternate body writes both ordinary UV-derived STQ and an extra
texture vector with S 0, Q 1 and T equal to the clamped direction dot product
plus coefficient W. It submits state packet `0x20`, the geometry with list
`0x512f`, state packet `0x30`, and that geometry again with list `0x5ff2`.
The first pass consumes ordinary STQ/RGBA; the second consumes the extra
texture vector followed by two NOPs and XYZ2. One batch therefore has two
geometry submissions with distinct state and register selection.

Its continuation copies the preceding batch's last two four-vector output
records into the next output region and adds two to the count. The next header
is at TOP `+0xc9`, before those copied records. `model_vu_upload_009`
(`0x003C1B10`) and the float-property alternate representative have the same
two-pass and two-record continuation families, with additional plane flags.

Packed alternate `model_vu_upload_032` also switches the same batch from
`0x512f` to `0x5ff2`, with a state `0x30` submission between its geometry
submissions. Both weighted and rigid continuations copy two records before
the next TOP, use header TOP `-8`, and add two to the count. Its header position
is different from the ordinary alternate contract.

### Packet layout

| GIF register list | Four slot meanings, in order |
| --- | --- |
| `0x512f` | NOP, STQ, RGBA, XYZ2 |
| `0x512a` | FOG, STQ, RGBA, XYZ2 |
| `0x5ff2` | STQ, NOP, NOP, XYZ2 |
| `0x5fff` | NOP, NOP, NOP, XYZ2 |

STQ holds perspective-correct S/T and Q; RGBA holds integer color lanes;
XYZ2 holds projected XYZ with four fractional bits. A NOP slot is ignored.

The short ordinary body writes a header at TOP `+0xd1`, followed by four
slots per vertex, copies its count from input header X, and submits that header.
The packed body instead compacts logical vertices and overwrites their input
UV/direction/position slots with STQ/RGBA/XYZ2. It updates header Y/Z from setup
and submits TOP itself. These are distinct output-region contracts.

XYZ2 W contributes ADC bit 15. ADC suppresses the current primitive while
retaining the vertex in strip history; combining source controls with rolling
plane flags is therefore different from a whole-model visibility decision.

## Source strip controls and their selected consumers

`ccs_read_packed_weighted_part` (`0x001AE190`) retains one attribute dword per
influence, and the weighted converter copies it unchanged. The base packed
VU body carries the first influence's W control into the compacted logical
vertex; later direction transforms and normalization alter XYZ only. It
neither substitutes nor combines later influences' controls.

The consumed control is the converter input after optional CPU normalization.
`ccs_convert_packed_model_mesh` (`0x001AFF20`) can run
`ccs_normalize_weighted_strips` (`0x001AE430`) between reading and converting,
so original asset order/control is not necessarily the final packet.

For the selected base packed body:

`XYZ2.W = (c - 0x7f31 - R) mod 65536`.

Here `c` is the first-influence control and `R` is the rolling AND of the
current and previous two vertices' X/Y/W comparison masks. Each mask combines
signs of the setup upper bound minus position and position minus the lower
bound, using `0xd0`; the bounds are VU data slots `0x0c` and `0x0d`. XYZ has
already undergone perspective division, while W retains its homogeneous value.
Previous masks initially equal `0xd0`. All pipelined and one/two-vertex tail
paths retain this equation.

| First-influence control | W when `R == 0xd0` | ADC bit | Base-body effect |
| --- | --- | --- | --- |
| `0` | `0x7fff` | clear | Permits the current strip primitive |
| `1` | `0x8000` | set | Retains the vertex but suppresses its primitive |
| `2` | `0x8001` | set | Same ADC result as 1 in this body |

For `c` in the observed domain `{0,1,2}`, a proper subset of mask `0xd0`
always sets ADC; the smallest result is `0x800f` for `c=0, R=0xc0`.
Control 0 therefore permits output only while all three masks keep every
X/Y/W bit. This body rejects rather than interpolates a crossing triangle.
The contract is sign-based, including boundaries and signed-zero sensitivity;
exceptional arithmetic behavior is not established.

In the selected `2NRTBOD1.CCS` weighted part, the first logical controls are
`1,1,0,0,2,2,0,1,1,0,0,1,1,0,0,2,2,0`. Later influences match their own
list's first control. Paired nonzero markers supply the two history vertices
at strip starts; optional normalization may change their order and controls.
This remains an observation of that one part.

Shared packed offset entry `0x35c` distinguishes control 1 from 2: nonzero
control becomes `2*c - 3`, converts to float, and multiplies by setup `-1.0`.
Control 1 seeds the projected-edge factor at `+1.0`, control 2 at `-1.0`,
while both retain nonzero ADC suppression. With control 0 it evaluates the
projected XY determinant using the preceding two positions and that factor,
flips the factor for the next vertex, and changes control to 1 when the
selected sign is clear. The same rolling-mask W equation follows. Its rigid
path repeats the operation with per-vertex W. These are opposite winding seeds,
without coordinate-independent clockwise/counterclockwise names.

CPU normalization treats a nonzero first control as a run start and scans from
its third vertex through zero controls. It corrects control 1 on even
`(run_start + inserted_vertices)` parity and control 2 on odd parity, reversing
the run and switching 1/2 when endpoint parity permits; otherwise it inserts a
duplicate first vertex. [Model runtime](model_runtime.md#ordinary-geometry-and-strip-conversion)
owns those array changes. The short ordinary body instead adds `0x7fff` to
its per-vertex control, also separating zero from 1/2 at ADC bit 15. Neither
consumer proves a universal winding convention or invalidity of other bytes.

## Clipping and interpolated output

`model_vu_upload_016` (`0x003C2890`, 309 pairs) retains homogeneous position,
float color and texture data before projection. Plane signs and successive
strip-vertex masks select triangles for clipping. It saves working state in
VU data `0x72`, `0x73`, `0x74` and seeds three vertices into scratch at `0x77`.

Six polygon passes alternate scratch starts `0x77` and `0x95`. They use setup
vectors in `0x0f`/`0x10` and Z/Y/X comparison masks `0x20`, `0x40`, `0x80`.
Each pass retains inside vertices and inserts an intersection when an edge
changes side. A coordinate/W difference ratio is applied equally to
homogeneous position, color and texture-field differences. This creates
clipped vertices with interpolated attributes.

Zero returned vertices stop processing that triangle. Otherwise the result
is projected, color and XYZ become integer, and a four-register GIF packet
starts at VU data `0xb3`. Its first two XYZ2 controls start a new strip.
Scratch/output starts are 30 slots apart; that spacing alone is not a numeric
capacity guard.

The neighboring `model_vu_upload_020` (`0x003C3250`, 327 pairs) adds
direction/light work before a homologous interpolation family. The complete
six-plane derivation here applies to the selected 309-pair body.

### Selected clipping scratch bound

Each scratch vertex has three vectors. A pass computes its endpoint from the
input count, copies its first vertex there to close the last edge, and visits
exactly one edge per input vertex. An inside vertex contributes one output
record; a side-changing edge contributes another intersection record. There
is no numeric scratch-capacity comparison in the complete pass.

**Inference, limited to finite convex geometry:** clipping a convex polygon
against one linear half-space adds at most one vertex. Starting from the
selected triangle, six passes can therefore return at most `4,5,6,7,8,9`
vertices. The largest input has eight vertices plus the closing copy: nine
records or 27 slots. The final nine-vertex result also uses 27 slots, within
the two 30-slot scratch intervals. The last pass returns to scratch `0x77`;
its furthest result slot is `0x91`, and the largest closing copy uses slots
`0xad`, `0xae`, `0xaf` in the other buffer.

Final output is one header plus four slots per result vertex. Nine vertices
reach slot `0xb3 + 4*9 = 0xd7`; the header uses the returned count, and the
first two controls carry nonzero ADC. These endpoint contracts establish
conditional space sufficiency, not a general ten-vertex interface, a capacity
guard, or behavior for nonfinite/nonconvex inputs. Those inputs are not
established as retail cases.

## Packed palette and influence storage bounds

The weighted index contains six bits and addresses four consecutive matrix
vectors beginning at `0x50 + 4*index`. It represents 64 matrices, with the
last matrix starting at `0x14c` and its last vector at `0x14f`. Packed upload
emits exactly the selected count; VIF NUM is `(count << 2) & 0xff`.
Counts 1..63 encode their four-vector totals; count 64 encodes NUM zero,
meaning 256 vectors. The sample's largest palette of 43 is a different fact.

This is not an enforced validity limit. The optional palette list allocates
`0x40` bytes but copies its declared count without a corresponding maximum
check. The draw producer also lacks that guard; larger totals disagree with
wrapped eight-bit VIF NUM. A declared count of zero instead selects the
composition child count. Oversized lists and zero-child packed draws have no
established asset-level contract. [Model runtime](model_runtime.md#packed-geometry-influences-and-matrix-palette)
owns CPU palette/list ownership. The rigid selector is a separate source dword
without the weighted six-bit extraction or an established range check.

`model_weighted_vu_batch_bases` (`0x005BF988`) contains VU data BASE values
`0x158`, `0x23a`, `0x31c`, selected modulo three with OFFSET 0. Each region
has `0xe2` slots; the final one reaches `0x3fd`. Palette vector `0x14f`
precedes the first base by eight slots. For `I` influences and `V` logical
vertices, the furthest input position is TOP `+4*I` and compacted output is
TOP `+4*V`. Remaining within a region requires `I <= 56` and `V <= 56`.
These are storage conditions, not reader-enforced list limits.

`ccs_count_weighted_batch_vertices` (`0x001AE770`) includes a vertex and its
entire list before testing `3*(I+V)+1 > 0xda`. Both converter passes use the
total vertex endpoint, so no influence list is split. The reader's list count
is a dword, narrowed to a halfword during conversion, and the VU traverses it
without a numeric maximum check.

**Derived limitation:** two lists of 30 influences give `I=60,V=2`, below the
stop threshold but requiring TOP `+0xf0`, beyond the region. This is a
counterexample to a universal capacity inference, not an observed asset or
execution. For one/two-influence lists, a threshold-crossing batch has
`I+V <= 75` and `I <= 50`, so the sample's input shape fits. Rigid conversion
separately caps a batch at `0x36` vertices. General supported list lengths
remain open.

## Representative retail body payloads

Six complete main-body payloads in retail `PL/` CCS files were inspected.
All have version `0x123`, file flags `0x3804` selecting the packed reader, and
one weighted part. The mode and palette count are separate header fields.
[Character assets](../../game/character_assets.md) owns file organization;
[Model runtime](model_runtime.md#packed-geometry-influences-and-matrix-palette)
owns the reader. Exact source locations and payload endpoints are recorded
with `ccs_parse_model` and `ccs_read_packed_weighted_part`.

| CCS file | Body model | Mode | Palette matrices | Rigid / weighted parts | Logical vertices |
| --- | --- | --- | ---: | --- | ---: |
| `2NRTBOD1.CCS` | `MDL_2nrt00t0 body` | `0x0440` | 20 | 19 / 1 | 3,062 |
| `2NRVBOD1.CCS` | `MDL_2nrv00t0 body` | `0x0440` | 20 | 19 / 1 | 3,062 |
| `2SKRBOD1.CCS` | `MDL_2skr00t0 body` | `0x0240` | 26 | 19 / 1 | 3,588 |
| `2SCOBOD1.CCS` | `MDL_2sco00t0 body` | `0x0440` | 24 | 17 / 1 | 3,998 |
| `2SCVBOD1.CCS` | `MDL_2scv00t0 body` | `0x0440` | 24 | 18 / 1 | 4,282 |
| `1NRTBOD1.CCS` | `MDL_1nrt00t0 body` | `0x0440` | 43 | 30 / 1 | 6,677 |

| CCS file | Weighted vertices | Influence records | One / two influences per vertex | Highest palette index |
| --- | ---: | ---: | --- | ---: |
| `2NRTBOD1.CCS` | 976 | 1,457 | 495 / 481 | 19 |
| `2NRVBOD1.CCS` | 976 | 1,457 | 495 / 481 | 19 |
| `2SKRBOD1.CCS` | 1,329 | 2,182 | 476 / 853 | 25 |
| `2SCOBOD1.CCS` | 1,507 | 2,392 | 622 / 885 | 23 |
| `2SCVBOD1.CCS` | 804 | 1,121 | 487 / 317 | 23 |
| `1NRTBOD1.CCS` | 2,628 | 4,382 | 874 / 1,754 | 42 |

Every terminated weighted-list count matched its part's logical count, and
all six complete payloads ended before the expected following chunk. Across
8,220 weighted vertices, every encoded weight sum is 256. With the VU `/256`
conversion this gives unit-sum position weights for the sample, without a
VU weight-sum division. One/two influences in the sample do not establish a
format maximum.

Two influence records in `2SCOBOD1.CCS` have zero weight but their complete
lists still sum to 256. All 12,991 influence controls are 0, 1 or 2. The
selected consumers above establish their effects, without declaring a
permitted domain for every variant.

One file can contain several routes. `2NRTBOD1.CCS`'s
`MDL_w2kn00t0 weapon` has flags `0x3801`, mode `0x1000` and one ordinary
part. `1NRTBOD1.CCS`'s `MDL_1nrt00t0 eye1`, `eye2` and `mou1` each have
zero flags/mode and one part. These header facts do not independently select
their eventual VU descriptor.

### Sampled headers joined to descriptor selection

`ccs_parse_model` (`0x001B0C40`) extracts mode fields at shifts 6 and 9,
turns nonzero values into `field - 1`, and writes the results into runtime
flag fields at shifts 21 and 23. A zero field defaults to 1 when parsed flags
contain `0x804` or `0x80`, otherwise 0. Version `0x123` mode bit `0x1000`
sets runtime flag `0x10000`.

`ccs_model_instance_initialize` (`0x001992A0`) copies
`CcsModelDescriptor.runtime_flags` to `CcsModelInstance.runtime_flags`;
`model_copy_instance_draw_state` (`0x00198290`) copies them into the draw
context immediately before selection. General parsing and instance ownership
remain in [Model runtime](model_runtime.md).

The following outcomes are conditional on draw admission, unchanged copied
flags, and the ordinary direction branch for body/weapon rows, rather than an
alternate attachment. They are derived selectors, not observed draws.

| Source model | Shift-21 / shift-23 values | Selector contributions | Conditional outcome |
| --- | --- | --- | --- |
| Five packed bodies with mode `0x0440` | `0 / 1` | Constructor clears bounds; null-box classification 2 gives base 1; direction 4; packed 24 | Alpha at least `0.9921875`: descriptor 29, `model_vu_upload_025`; below: descriptor 101, `model_vu_upload_097`, sign `-1.0` |
| `2SKRBOD1.CCS` body, mode `0x0240` | `0 / 0` | Same null-box, direction and packed contributions | Descriptor 29 at either side of the alpha threshold |
| `2NRTBOD1.CCS` weapon, mode `0x1000` | `1 / 1` from defaults | Classification 1 or 2 plus mode's 2 gives base 2 or 3; direction 4; ordinary route | Parallel descriptor 78/79 (`model_vu_upload_078` / `model_vu_upload_079`); classification 2 with clipping enabled selects 95 (`model_vu_upload_020`) |
| `1NRTBOD1.CCS` eye1/eye2/mou1, flags/mode zero | `0 / 0` | Classification 1 or 2 gives base 0 or 1; direction 0 | Descriptor 0/1 (`model_vu_upload_000` / `model_vu_upload_001`); classification 2 with clipping enabled selects 17 (`model_vu_upload_016`) |

The descriptor table confirms those upload relationships. The packed branch
runs before the ordinary clipping-selector gate, so that gate cannot redirect
the packed-body row to the longer ordinary interpolation program. The ordinary
companions retain a classifier dependency that their CCS headers cannot decide.

Admission precedes selection: empty instances and alpha below `1/128` return;
a nonnull bounds classification of zero also returns. Ordinary per-part
material-alpha admission follows. Packed delegation instead takes the first
part's factor and emits packed part chains without that ordinary loop.
[Visibility](visibility.md#ordinary-model-draw-boundary) owns scene and bounds
gates, and [Texture and material runtime](texture_material_runtime.md) owns
material factors. Later flag setters, attachment state, alpha, classification
and draw history remain necessary to identify a descriptor in a retail scene.

## Remaining evidence gaps

- Conditional descriptor formulas do not establish character draw histories,
  later flag changes, factors, attachments or companion classifications.
- The selected base packed and shared offset controls establish first-influence
  ownership, ADC and opposite seeds for 0/1/2. Other values and each variant's
  winding and exceptional sign behavior remain open.
- Complete upload extents were decoded, but semantic conclusions remain tied
  to representative bodies. Six-plane interpolation is established for
  `model_vu_upload_016`; it is not a general packed-body contract.
- Cancelling direction sums, exceptional W/Q inputs and arbitrary nonuniform
  matrices have no established asset-level contract.
- Sixty-four weighted matrices are representable; unchecked palette counts
  and rigid dword selectors do not define a universal validity limit.
  The 56-influence region condition is separate from the open supported
  list-length domain.
- The selected clipper's nine-vertex bound assumes finite convex triangle
  clipping through six linear planes. There is no numeric capacity guard;
  degeneracies, rounding and other bodies need separate evidence.
