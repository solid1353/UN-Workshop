# Shadow VU program

## Research coverage

Established: the complete 389-pair upload, its input/output contract, extrusion,
depth and clipping, batch alternation, conditional overlap and convex capacities.
Open: retail overlap reachability, topology distribution, scalar units,
preliminary-kick purpose, transfer timing and complete hardware numerical behavior.
Routine, field and data names come from `@annotations/NA2`.

## Evidence and address convention

This document owns the retail NA2 (`SLPS-25837`) shadow microprogram and its
geometry/storage contract. The EE controller, target setup and compositing
belong to [shadow rendering](shadow_rendering.md). General coordinates,
geometry conversion, submission and classification belong to
[renderer coordinates](renderer_coordinates.md), [model runtime](model_runtime.md),
[render submission](render_submission.md) and [visibility](visibility.md).

Evidence is static retail code and uploaded bytes, plus a bounded reconstruction
of 207 selector-4 shadow parts in six body files. Reconstruction uses rounded
single-precision arithmetic; it does not establish hardware normalization
agreement, unrestricted asset reachability, damaged-packet effects or exceptional
clipping behavior. Exact numerical contact/overflow behavior across all VU
pipeline cases remains open. Convex capacity bounds require finite, intact
geometry.

EE addresses are live retail `SLPS_258.37` addresses; see
[address conventions](../../game/files/file_identities.md#address-conventions).
VU instruction addresses count 64-bit pairs; VU data addresses count 128-bit
quadwords. Named VU families below are **labels in the resident upload data**,
not EE functions. Their annotation comments own opcode details, register use
and instruction locations. The resident Ghidra program uses R5900 EE analysis,
so VU semantics come from the raw upload decoded with PCSX2's VU tables and
Sony's VU/EE manuals, as recorded on `projection_geometry_microprogram`.

## Upload boundary and entry families

`model_part_queue_projection` (`0x0018CF70`) references
`projection_geometry_microprogram` (`0x003C3CA0`) as a DMA REF of
`0xC40` bytes, QWC `0xC4`. The stream starts with FLUSHA, uploads all
389 pairs in two MPG blocks, and ends with NOP padding.

| Upload label | Live EE address | VU destination | Instruction pairs |
| --- | --- | ---: | ---: |
| `projection_shadow_vif_mpg_first` | `0x003C3CA4` | `0x000` | 256 |
| `projection_shadow_vif_mpg_second` | `0x003C44AC` | `0x100` | 133 |

| Family label | Live EE upload address | VU entry | Established operation |
| --- | --- | ---: | --- |
| `projection_shadow_vu_initialize` | `0x003C3CA8` | `0x000` | Load fixed parameters, seed output tags and end |
| `projection_shadow_vu_classify_directions` | `0x003C3D40` | `0x013` | Classify the direction table and end |
| `projection_shadow_vu_triangles` | `0x003C3D98` | `0x01E` | Transform faces, select state, emit fast geometry and defer outside polygons |
| `projection_shadow_vu_edges` | `0x003C4028` | `0x070` | Admit edges whose adjacent classifications differ |
| `projection_shadow_vu_emit_edge` | `0x003C4130` | `0x091` | Build displaced strips, emit fast geometry and retain outside polygons |
| `projection_shadow_vu_split_near` | `0x003C4340` | `0x0D3` | Split deferred polygons into the beyond-near and capped lists |
| `projection_shadow_vu_clip_and_emit_fan` | `0x003C4520` | `0x10E` | Clip against four XY planes and emit a fan |
| `projection_shadow_vu_clip_plane` | `0x003C47A8` | `0x15F` | Clip one homogeneous polygon against one XY plane |

Initialization and classification stop separately; topology MSCNT resumes
classification after initialization. Triangle and edge batches start their own
entries. Deferred processing drains retained polygons before ending.

## Distinction from the VU0 classifier

`visibility_vu0_classifier_upload` (`0x003D11E0`) is a separate
90-pair stream with its own DMA tag and renderer-initialization channel.
The shadow stream starts directly with VIF commands and its XTOP/XGKICK
operations establish VU1 input/output. Sharing entry number zero does not
make the streams the same program or VU. Classifier predicates and return
values belong to [visibility](visibility.md#vu-point-tests-and-classification).

## Parameter slots and entry selection

The producer supplies seventeen consecutive V4-32 parameter quadwords at
fixed VU1 data slot `0x184`. Their layout is `ShadowVuParameters`;
`projection_shadow_vu_initialize` loads the working values and tag templates.

| Parameter field | VU data slot | Value or role |
| --- | --- | --- |
| `lower_clip_plane` | `0x184` | `(-(4096-W)/2, -(4096-H)/2, 0, -1)` |
| `upper_clip_plane` | `0x185` | `((4096+W)/2, (4096+H)/2, 0, 1)` |
| `near_reference` | `0x186` | Transformed `(0,0,max(8,near),1)` |
| `fast_lower_bounds` | `0x187` | `(0,0,0,near)` |
| `fast_upper_bounds` | `0x188` | `(4095.75,4095.75,0,far)` |
| `model_to_device` | `0x189..0x18C` | Remapped matrix columns |
| `state_tag` | `0x18D` | Template copied to `0x203` and `0x204` |
| `vertex_tag` | `0x18E` | XYZ2 template copied to `0x207`; low halfword supplies direction count |
| `rgbaq_negative` / `rgbaq_nonnegative` | `0x18F` / `0x190` | Two RGBAQ A+D payloads |
| `alpha_negative` / `alpha_nonnegative` | `0x191` / `0x192` | Two ALPHA_2 A+D payloads |
| `direction` | `0x193` | Inverse-model environment direction |
| `displacement` | `0x194` | Scale-adjusted direction times projection scalar, W=0 |

W/H are target pixel dimensions. Near/far and matrix construction remain owned
by renderer coordinates and shadow rendering. The Z/W of `near_reference`
supply the near split; they do not establish a constant ground height.
Producer mode 3 zeros displacement XYZ; the VU family is shared across the
inspected mode branches.

After MSCAL initialization, the producer references
`CcsRuntimeModelPart.projection_geometry`, whose size is
`projection_geometry_size`. `model_prepare_projection_geometry`
(`0x0018D740`) constructs that topology packet:

| Packet content | VU consumer and contract |
| --- | --- |
| V4-32 direction/normal table at fixed data slot `0x212` | Direction count is the selector-4 use of part `packet_bytes`; MSCNT resumes classification |
| Triangle batches, at most 24 | Masked signed V4-16 XYZ; first vertex W carries `direction_index + 0x212`; MSCAL triangle entry |
| Endpoint-pair batches, at most 24 | Signed V4-16 XYZ; each endpoint W carries its adjacent direction-table slot; MSCAL edge entry |

The triangle row is `(0,0,0,1)`: the first vertex retains its table pointer,
the other two receive W=1, and the VU replaces the first W after reading the
pointer. Edge processing supplies W=1 to all four working positions.

`scene_object_submit_geometry` (`0x00190F40`) supplies the secondary model
from `CcsScenePlayTarget.auxiliary` and a prepared draw context. This direct
edge does not establish that every character archive contains the topology
route. Source layout and allocation belong to
[model runtime](model_runtime.md#triangle-topology-conversion).

## Direction classification and extrusion

`projection_shadow_vu_classify_directions` takes the sign of the XYZ dot
product between `direction` and each direction-table vector. It retains XYZ
and stores integer 0 or `0x80` in W. Three extra iterations flush its pipeline;
table W is a classification, not a float normal component.

The triangle family reads the first vertex's direction reference, converts
signed XYZ with a scale of `1/4096`, and adds `displacement.xyz` to all three
positions only when classification is zero. The nonzero classification keeps
the original face.

The edge family skips equal adjacent classifications. Unequal classifications
produce the original endpoints and their displaced copies; a zero first
classification reverses their working order. **Inference, high confidence:**
faces and shared-edge strips form an extrusion along the supplied direction.
They do not project every point onto a fixed floor plane. The physical unit
of the EE projection scalar remains open; its interpretation also depends on
model scale and caller convention.

The direction table comes from face geometry. `integer_vector_subtract`
(`0x0018E970`) forms point differences; `integer_vector_cross_shift`
(`0x0018E7B0`) supplies the signed XYZ cross product.
`model_topology_build_triangle` (`0x0018E530`) reuses the first normalized
direction whose dot product is strictly greater than `0.99609375`, or adds
scaled float XYZ with W=0. This groups near directions, not just exactly
coplanar faces.

`model_topology_build_edge` (`0x0018E240`) matches reversed shared edges.
Equal face-table indexes remove the edge; differing indexes retain both
references. An unmatched `ShadowTopologyEdge` initially has
`second_direction_index = -1 - first_direction_index`. Construction can
reject the packet; this does not establish that a negative reference reaches
a submitted retail packet.

## Transform, depth and the fast geometry pass

For each working position p, the triangle and edge families form
`h = column0*p.x + column1*p.y + column2*p.z + column3*p.w`.
The supplied matrix already includes model scale and transform, camera
projection and the target XY remap. No second camera matrix is fetched.

Perspective division affects **XYZ only**; W retains homogeneous depth for
bounds and clipping. Fast vertices are converted with four fractional bits
and their W words become draw flags. Packed XYZ2 Z is converted projected Z,
not homogeneous W or floor height. The clipped path also divides and converts
XYZ only.

The remap changes XY and preserves the Z/W axes, so the reverse depth
numerator and homogeneous division in
[renderer coordinates](renderer_coordinates.md#projection-refresh) still
supply depth. Scene-depth copying and GS depth comparison belong to shadow
rendering.

Projected winding is
`(b.x-a.x)*(c.y-a.y) - (c.x-a.x)*(b.y-a.y)`.
Its negative sign selects the negative RGBAQ/ALPHA_2 pair; the other branch
selects the nonnegative pair. This chooses raster state instead of rejecting
one orientation.

Fast bounds use divided X/Y and retained W:

| Bound | Finite-value interpretation |
| --- | --- |
| Lower | X>=0, Y>=0, W>=near |
| Upper | X<=4095.75, Y<=4095.75, W<=far |

The comparisons accumulate sticky sign flags after clearing them. Signed zero
and exceptional arithmetic retain hardware flag semantics; the inequalities
above describe ordinary finite values.

Outside triangles mark their final vertex ADC=1 and retain three pre-divide
homogeneous vectors. Outside edge strips mark both final vertices ADC=1 and
retain four vectors. Deferred storage starts at VU data `0x18D` and advances
only for outside primitives. Inside scratch copies are unretained and can be
overwritten. Thus a fast outside flag requests explicit clipping rather than
proving permanent rejection.

## Near-plane split and four-plane clipping

`projection_shadow_vu_split_near` reloads the two XY-plane vectors and near
reference N from data slots `0x184`, `0x185` and `0x186`. It closes each
deferred triangle or four-vertex polygon and splits it by the sign of
`h.w-N.w`.

| Vertex/edge case | Stored result |
| --- | --- |
| Nonnegative `h.w-N.w` | Original homogeneous point in list `0x1ED` |
| Negative side | Original X/Y with Z=N.z and W=N.w in list `0x1F3` |
| Crossing edge | Full homogeneous intersection in both lists |

For ordinary finite crossing endpoints A/B,
`C=A+t*(B-A)`, `t=(N.w-A.w)/(B.w-A.w)`, in all four lanes.
Both nonempty lists enter the same clip/fan family.

**Inference, high confidence:** the split retains a near-depth cap as well
as the beyond-near portion. Capped points keep homogeneous X/Y; changing W
changes their eventual perspective division. This establishes coordinates,
not visible coverage.

The fan family applies `projection_shadow_vu_clip_plane` in this order:

| Plane | Vector | Finite homogeneous inside condition |
| --- | --- | --- |
| Lower X | `(-Lx,-Ly,0,-1)` | `h.x-Lx*h.w >= 0` |
| Upper X | `(Ux,Uy,0,1)` | `Ux*h.w-h.x >= 0` |
| Lower Y | Lower vector | `h.y-Ly*h.w >= 0` |
| Upper Y | Upper vector | `Uy*h.w-h.y >= 0` |

`Lx/Ly=(4096-W/H)/2` and `Ux/Uy=(4096+W/H)/2` are the centered
small-target boundaries, distinct from the fast pass's global GS range.
The helper alternates buffers `0x1F9` and `0x208`, closes each input polygon
with its first vertex, and emits nothing if any plane returns zero vertices.

With `d(h)=plane.xyz*h.w-h.xyz*plane.w`, crossing interpolation is
`C=A+t*(B-A)`, `t=d(A)/(d(A)-d(B))`, in all four lanes. Clipping therefore
precedes perspective division and preserves projected-depth interpolation.

**Bounded observation:** W>far can set the fast outside flag, but the deferred
family has no far split or final W<=far rejection. It splits at N.w and then
clips X/Y only. The initial flag does not establish an additional Z-plane rule.

## Output packets and bounded storage

Triangle fast packets contain two A+D state writes and three XYZ2 vertices per
triangle, with a loop count equal to the input triangle count. Their primitive
is context-2 untextured blended triangles (`PRIM=0x243`). Edge packets contain
two A+D writes and four XYZ2 vertices per emitted edge, using a context-2
triangle strip (`PRIM=0x244`). Fast submission begins at `TOP+0x49`.

Before the EE model-orientation swap, the producer supplies:

| Producer mode | Negative / nonnegative RGBAQ | Negative / nonnegative ALPHA_2 |
| --- | --- | --- |
| 1 | `0x80000001` / `0x80000001` | `0x48` / `0x42` |
| 2 | `0x80000040` / `0x80004000` | `0x48` / `0x48` |
| 3 | `0x800000FF` / `0x80000000` | `0x44` / `0x48` |

ALPHA_2 values come from `model_blend_states` (`0x005B5940`).
Winding chooses the VU pair; the prior EE orientation swap belongs to shadow
rendering. Code branches do not establish retail content choosing modes 2/3.

Clipped submission starts at `0x204`: state tag, state payloads at
`0x205/0x206`, XYZ2 tag at `0x207`, vertices at `0x208`. It uses a
context-2 fan (`PRIM=0x245`). The state tag clears EOP and the final vertex
tag receives polygon count plus `0x8000`. The first two vertices have ADC=1,
preventing drawing before three vertices exist. The earlier kick from
`0x203` has the extent described [below](#preliminary-kick-packet-extent).

| VU data slots | Role |
| --- | --- |
| `0x184..0x194` | Seventeen fixed parameter quadwords |
| `0x18D` upward | Deferred homogeneous polygons, reusing loaded template storage |
| `0x1ED` / `0x1F3` | Near-split list starts |
| `0x1F9` / `0x208` | Alternating XY clip buffers |
| `0x203..0x207` | Fixed fan/state headers and payloads |
| `0x212` upward | Direction vectors with classification in W |
| `TOP` onward | Double-buffered batch input; fast output at `TOP+0x49` |

The VU list writers have no explicit capacity checks. The EE builder limits
each face/edge batch to 24 and direction count to below `0x1EF`; these are
input limits, not by themselves clipping-capacity proofs.

With BASE=0 and OFFSET=`0xC2`, a maximum triangle batch occupies 73 input
quadwords (`TOP..TOP+0x48`) and 121 fast-packet quadwords
(`TOP+0x49..TOP+0xC1`), fitting the 194-quadword spacing.
An edge packet occupies `1+6*E` quadwords for E emitted edges; at E=24 it
ends at `TOP+0xD9`. Equal classifications skip emission, so 24 inputs alone
do not establish parameter overlap.

## Edge batch alternation and live overlap

Each batching family resets BASE=0 and OFFSET=`0xC2`. OFFSET clears DBF and
sets TOPS to BASE; execution copies TOPS to TOP, then alternates TOPS between
BASE+OFFSET and BASE. Consequently, one-based batches 1,3,5,... use TOP=0,
and 2,4,6,... use TOP=`0xC2`. The edge reset makes triangle parity irrelevant
to the first edge batch. Skipping geometry inside a batch does not change TOP.

Each batch flushes before its TOP-relative unpack and waits for VU completion
before MSCAL. Beyond the 24-input limit, the bounded builder has no
emitted-edge-count or TOP-dependent size gate. Submission/controller gates
belong to [shadow rendering](shadow_rendering.md#geometry-inputs-and-renderer-ownership).

The edge family starts its tag at zero loops while keeping EOP. Only unequal
classifications increment the emitted count and advance the output pointer.
Clipped edges still count as emitted edges in the fast packet.

At TOP=`0xC2`, the tag is at `0x10B` and payloads begin at `0x10C`:

| Emitted edge, one-based | Fast payload slots | Consequence if reached |
| --- | --- | --- |
| 20 | `0x17E..0x183` | Below fixed parameters |
| 21 | `0x184..0x189` | RGBAQ replaces lower plane; ALPHA_2 replaces upper plane; first converted vertex replaces near reference |
| 22 | `0x18A..0x18F` | Converted vertices reach deferred storage at `0x18D` |
| 23 | `0x190..0x195` | Further deferred overlap; direction/displacement already loaded |
| 24 | `0x196..0x19B` | Maximum end; fast output does not reach fan packet `0x203` or direction table `0x212` |

**Conditional consequence, high confidence:** deferred processing runs only
when homogeneous polygons were retained, and reloads the three fixed clipping
inputs after fast writes and kick. Therefore at least 21 high-TOP emissions
change that batch's later clipping inputs if it defers any polygon.
Without deferred polygons, the damaged slots remain until the next producer's
fixed-parameter unpack; a later batch in the same topology packet can still
reload them. The builder does not repair them per batch.

At 22 or more emissions, fast output can also overlap retained homogeneous
vertices. Every emitted edge writes four scratch vertices first, retaining
them only if outside. Later fast writes can replace earlier retained values;
later scratch writes can replace completed fast-packet values before the
batch kick. Survival depends on emission order and which edges are deferred.
This arithmetic does not identify a damaged retail submission or visible result.

## Selected authored shadow topology

The bounded sample is exactly `2NRWBOD1.CCS`, `2SSWBOD1.CCS`,
`2SKWBOD1.CCS`, `2CYBBOD1.CCS`, `2DDRBOD1.CCS` and `2SCOBOD1.CCS`
under retail DATA `PL/MODEL/`, all version `0x123`. Record selection and
consumption checks are recorded on `model_prepare_projection_geometry`;
this is not a full block walk or asset census. Declared-length limitations
belong to [CCS parsing](../../game/files/ccs_runtime.md#parsing-type-dispatch-and-publication).

The 207 one-part models comprise 17 `shadow01..shadow17` records in each
`MDL_2nrw`, `MDL_2cyb`, `MDL_2ddr` and `MDL_2sco` `00t0/05t0`
family; 17 each in `MDL_2ssw00t0` and `MDL_2skw00t0`; 14 each in
`MDL_2bir00t0` and `MDL_2bir05t0`; and nine in `MDL_2kkg00t0`.
The `2bir` records are in `2DDRBOD1.CCS`, `2kkg` in `2SCOBOD1.CCS`.
All have flags `0x0008`, selector 4, zero optional byte-list count,
8..24 points and 12..40 triangles. File selection/loading belong to
[character assets](../../game/character_assets.md#selection-and-loading-consumers).

Reconstruction follows authored triangle order, first-matching normal reuse,
three cyclic edge insertions and removal-by-last-record swap. The normal
cross-product shift is zero and components have magnitude at most 18,259,320
in this sample. Rounded single-precision comparisons come no closer than
approximately `8.77e-5` to the reuse threshold; full hardware agreement is
not established.

| Sample family | Reconstructed directions | Retained edges per part | High-TOP inputs | Maximum high-TOP emissions over binary signs |
| --- | --- | --- | --- | --- |
| Both `2nrw` variants | 6..19 | 12..40 | 7, 9 or 16 when a second batch exists | 6, 7 or 13, respectively |
| `2ssw00t0` | 6..19 | 12..40 | 8 or 16 when a second batch exists | 6 or 13, respectively |
| `2skw00t0` | 6..19 | 12..40 | 7, 9 or 16 when a second batch exists | 6, 7 or 13, respectively |
| Both `2cyb`/`2ddr`; `2sco00t0` | 6..19 | 12..40 | 7, 9 or 16 when a second batch exists | 6, 7 or 13, respectively |
| `2sco05t0` | 6..14 | 12..33 | 7 or 9 when a second batch exists | 6 or 7, respectively |
| Both `2bir` variants | 6..10 | 12..20 | No second batch | No high-TOP batch |
| `2kkg00t0` | 6..12 | 12..24 | No second batch | No high-TOP batch |

No reconstructed part has a third batch or unmatched negative adjacency.
Every sample satisfies `ShadowTopologyBuilder.negative_pair_count >=
nonnegative_pair_count`. Emission bounds exhaust binary assignments to each
high-TOP batch's referenced directions, fixing one sign because complementing
all signs keeps unequal-pair counts unchanged. These are conservative bounds;
an actual light direction need not reach every assignment.

The maximum-size example `MDL_2nrw00t0 shadow09` has 24 points, 120 indexes,
40 triangles, 19 reconstructed directions and 40 retained edges. Its second
batch has these 16 direction-index pairs in packet order:

```text
(12,11) (13,11) (15,11) (1,11) (13,12) (15,12) (17,13) (16,14)
(18,14) (17,14) (1,14) (18,15) (18,16) (17,16) (17,1) (18,1)
```

At most 13 pairs differ for any binary assignment; 16 inputs cannot produce
21 emissions. **Bounded conclusion:** these six files provide no reconstructed
high-TOP overlap case. Other characters, appearances, stages, effects and
other retail topology resources remain outside the sample. The reconstruction
does not identify an actual submitted packet or visible artifact.

Construction rejects when `negative_pair_count < nonnegative_pair_count`,
`direction_count >= 0x1EF`, `edge_count == 0`, or `construction_status != 0`.
That final gate does not separately walk adjacency to reject unmatched negative
references; nonnegative references are a sample result, not a loader guarantee.

Selector 4 supplies model flag `0x08`.
`ccs_finalize_dependencies` (`0x001AD240`) stores that child's model record
in its resolved type-`0x0100` parent's
`CcsSceneObjectDescriptor.shadow_model_record`.
`ccs_scene_child_bind_models` (`0x00196B40`) binds it to
`CcsScenePlayTarget.auxiliary` and enables `flags & 0x20`; common draw
selects the producer through those fields. Secondary attachment and binding belong to
[model runtime](model_runtime.md#composition-hierarchy-and-matrix-lifetime).
Sampled source topology does not prove when a scene passes shadow rendering's
controller, strength, bounds and allocation gates.

## Deferred and clipping capacity bounds

Triangle batches retain at most `24*3=72` homogeneous quadwords,
`0x18D..0x1D4`; edge batches at most `24*4=96`, `0x18D..0x1EC`.
The first near list starts immediately after at `0x1ED`. Inside scratch
writes reuse the current pointer; their primitive occupies one of the 24 inputs,
so no 25th primitive's storage is needed. This count bound does not repair
the conditional fast-output alias.

**Inference, high confidence for finite convex geometry:** edge scratch
positions follow boundary order `A,B,B+D,A+D` or its reverse, an affine
parallelogram rather than strip raster order. Triangles are convex too.
The homogeneous matrix preserves this parameterization. A linear half-plane
crosses a convex boundary at most twice, so retaining inside points and crossing
intersections increases a nonempty polygon by at most one vertex per plane.

The near split produces at most four vertices per triangle list or five per
edge list. Capped X/Y remain an affine image of the split polygon with fixed W;
varying intersection Z does not enter the XY predicates. Each six-slot near
list fits five vertices plus its closing copy: `0x1ED..0x1F2` and
`0x1F3..0x1F8`. Processing one list therefore preserves the other.

Four XY clips yield a conservative maximum of eight triangle vertices or nine
edge vertices. The output buffers alternate `0x208`, `0x1F9`, `0x208`,
`0x1F9`. Nine vertices plus closing copy fit `0x1F9..0x202` or
`0x208..0x211`, below fixed headers `0x203..0x207` and direction table
`0x212`; the final nine XYZ payloads occupy `0x208..0x210`.
These mathematical bounds fit the layout. Missing explicit capacity checks
alone do not establish overflow.

The bounds assume intact homogeneous vertices, ordinary finite arithmetic and
the established triangle/parallelogram order. They do not cover fast aliasing,
exceptional division, hardware numerical disagreement or arbitrary nonconvex/
corrupt lists; no unrestricted whole-game capacity proof is claimed.

## Preliminary kick packet extent

Initialization leaves the same template at `0x203` and `0x204`:
control `0x1122C00000008002`, register word `0xEEEEEEEEEEEEEEEE`,
packed mode, NREG=1, A+D, NLOOP=2 and EOP=1. No later instruction in the
bounded upload writes `0x203`.

With that template intact, the preliminary kick from `0x203` describes exactly
three quadwords: its tag, `0x204` as A+D payload and `0x205` as A+D payload.
It does not treat `0x204` as a second tag, include `0x206`'s ALPHA_2 write,
or reach XYZ2 vertices. The first A+D destination byte is `0xEE`; PCSX2 masks
it to index `0x6E`, which alone establishes no retail hardware effect.

The kick precedes current polygon-state stores, including possible state-pair
replacements. Static instruction ordering does not establish whether transfer
samples `0x205` before or after those stores. Extent and absence of vertex
payload are established; transfer timing and purpose remain unresolved.
The later kick from `0x204` submits the completed fan state and vertices.
