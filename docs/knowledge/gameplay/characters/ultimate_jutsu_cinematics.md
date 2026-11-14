# Ultimate Jutsu cinematics

## Research coverage

Established: opponent selection, side/role setup, the names of a stream's
optional offsets and filter, authored appearance and
texture/draw switches and how UN3 keeps its appearance substitutions, defender draw/placement/matrix gates, bone replacement,
popup interruption, selected geometry providers, the resident BSS globals
for opponent groups, optional switch tables and the derived main path, and
the screen-held panels, domes, distortion lenses and their texture
projection, backdrops ending at the 4:3 view, and characters kept just
outside it, in sampled films.
Open: the intended optional-body constant/resource, the capacity of the
derived main-path buffer, targets across every cinematic, accumulated matrix orientation and visible body animation in
omitted-draw ranges, and why the renderer draws nothing of the floor faces
that leave `D91_10`'s sliver and `D76_10`'s streak, what `D86_20`'s untextured black figure is (frame 71), and
which part of the left Kakashi leaves the clear colour in `D70_25`'s bottom-left corner (frame 91). Names come from `@annotations/NA2`; comments and types
carry code-level details. Static resident/BTL/ETC and clean CCS evidence
establishes dependencies, not live allocation success. UN4's cinematic formats
are compared in [UN4 Ultimate Jutsu](un4/ultimate_jutsu.md); donor character
cinematics are in [UN3 and UN4 characters](un3_un4_characters.md).

Retail NA2 (`SLPS-25837`) selects and adjusts authored Ultimate Jutsu cinematics
for an attacker, defender and skill. Starting the cinematic, the contest and
its outcome belong to [Ultimate Jutsu](ultimate_jutsu.md).
Transport, request tables and player controls belong to
[CCS runtime](../../game/files/ccs_runtime.md);
record identities to [CCS object types](../../game/files/ccs_object_types.md);
character palette ownership to [Character assets](../../game/character_assets.md);
curve evaluation to [Animation runtime](../../runtime/animation_runtime.md);
cue rows to [Battle audio](../session/battle_audio.md#authored-cinematic-frame-rows).

## Screen-held panels

Films cover the screen with flat effect models held in front of their
camera, each sized to the 4:3 screen with a small margin. White flashes and
letterbox bars are the shared boards `MDL_e00board01_w` and `MDL_e00board01_b`
(` e\00\max\e00board01.max`), as in `D81_20` and `D65_10`; `D92_10`'s green
band `MDL_e92img01b` and its speed-line sheets `MDL_e92syt02a/b` face the
camera the same way. A distant backdrop can be tilted: `D68_20`'s sky
`MDL_e68sky02` is a flat plane whose corners' depths differ by about 8%.
`D70_25`'s smoke instead comes from strongly tilted sheets
(`MDL_e21windw02_a..e`), and `D58_50`'s background from 3D pieces
(`MDL_e58bgcla..d`), which `D62_50` shares. Speed lines can be several
copies of one flat piece, each from one screen edge toward the middle:
`D69_20` draws `MDL_e00line46a` (` e\00\max\e00line46.max`) that way, with
no depth offset. Some screen covers are domes around the camera rather than
flat panels: `D58_50`'s expanding air disc `MDL_e58air5a` (frame 28) spans
the whole 4:3 width with its far corners 1.21–1.40 times as deep as its near
ones, and `D69_20`'s green disc `MDL_e69back03` (frame 168) 1.53–2.56 times.
`D76_10`'s light sphere `MDL_e76img01` (frame 44), 2.5 times as deep at its
far corners as at its near ones, ends just past both 4:3 edges, behind a
burst panel that covers the screen's height. It loads from the film's
effect container `str/d76_10e.ccs`, as a hemisphere of seven vertex rings
(scale 512) from its pole at the origin, under the burst, to its rim at
raw radius about 3075 and Z 3082, which leaves the 16:9 corners bare.
The streak lines `MDL_e71line03a/b` of `D71_50` and `D72_50` start at the left 4:3 edge at frame 147. Backdrops and effects of other films end just past
the 4:3 view: `D07_10`'s pink backdrop `MDL_e07back01` (frame 195),
`D13_30`'s red backdrop `MDL_e13img03` (frame 153), which `D13_10` shares,
`D13_30`'s backdrop `MDL_e00back35` (frame 206), the sky
`MDL_e60sky02_a` of `D60_10` (frame 34) and `D60_20`, `D60_20`'s fire
`MDL_e60smp02_b` (frame 353), `D62_20`'s smoke `MDL_e62smk01c` (frame 597)
and sky dome `MDL_e62bg_sky` (frame 565), and `D86_20`'s fire cloud
`MDL_e86fir01a..d` (frame 183). So do 3D sets, such as `D70_10`'s rocks and
`D78_20`'s smoke and walls. `D07_10`'s orange filter `MDL_e07fil01` (frames
362 and 376) is a flat panel facing the camera that ends just past the right
4:3 edge, while its left end stops inside the left one. `D60_10`'s light
pillar `MDL_e60img02_a/b` (frame 128), which `D18_20` and `D60_20` share, is
curved, its far corners 1.6 times as deep as its near ones, and each of its
two layers ends just past one 4:3 edge. `D57_20`'s floor `MDL_e57flo01`
(frame 177), which `D57_25` shares, is a round crater disc seen from above at
an angle, its far corners 1.7 times as deep as its near ones, whose edge ends
just past both 4:3 edges. `D57_35`'s blast dome `MDL_e57shoth` (frame
428) ends just past the left 4:3 edge. `D58_10`'s floor `MDL_e58flo05`
(frame 188), part of which is behind the camera, ends past the left 4:3 edge
in the screen's top-left corner. Its other floor `MDL_e58flo04` and its
mesas `MDL_e58gak02` and `MDL_e58gak03` (frames 38, 202, 242 and 266) end
just past the 4:3 edges, leaving the sky showing below the horizon at the
sides; `D58_30` shares `MDL_e58gak02`. At frame 150, the slope of
`MDL_e58flo04` hides a darker part of the sky `MDL_e58sky04`. `D58_20`'s canyon walls `MDL_e58gake03`
(frame 38) end in a straight vertical cut just past the right 4:3 edge. Just
past a 4:3 edge also end `D58_20`'s pink burst `MDL_e58img02sr` (frames 206
and 287) and clouds `MDL_e58kmo01` (frame 378), `D58_30`'s cliff
`MDL_e58gak01` (frame 218) and rubble `MDL_e58rocs01b` (frame 285; it and
`MDL_e58rocs01a`, which meets it, are in `D58_20` too), `D65_30`'s floor
`MDL_e65flo05` (frame 378), `D70_20`'s distant mountain `MDL_e70mtn01a`
(frame 271) and the sky `MDL_e70sky01` (`D70_10` frame 348), which `D70_20`
and `D70_25` share. At `D70_20` frame 240 the base of `MDL_e70mtn01a` hides
part of the sky that is dark below the horizon. `D65_20`'s
background blocks `MDL_e65fbk00_00..10` (frame 285) form a ring around the
scene, and one of them stands with a straight edge just past the right 4:3
edge. Also ending just past a 4:3 edge: `D66_30`'s light column
`MDL_e66img02` (frame 213), `D67_30`'s canyon wall pieces
`MDL_e67rock01_a..d` (frame 20) and rock step `MDL_e67rock02_e/f` (frame
44), `D68_30`'s smoke `MDL_e68kem7b` (frame 460), which `D93_30` shares,
`D79_10`'s disc `MDL_e79clr00` (frame 401), and `D80_10`'s backdrops
`MDL_e80bgf20`, `MDL_e80bgs20`, `MDL_e80bgm20` and `MDL_e80bgr20` (frames
72, 176 and 285); widening the rear one, `MDL_e80bgr20`, cuts its cliff
open at frame 285. In
`D64_30` at
frame 23, the forest `MDL_e64ki00` ends just past the right 4:3 edge, and
its nearest trunk hides a dark area that the far forest `MDL_e64enki00`,
which ends left of the screen center, leaves uncovered; the dark areas at
the sides of frames 30 and 165 lie past the near trees and the flat tree
cards behind them, `MDL_e64kiha00` and `MDL_e64itaki00`: at frame 30 nothing
draws at the top right past the near trees, which no card, the far forest,
sky, mountains or hills reach at up to five times as wide. The forest is four
placements of `MDL_e64ki00`; the far forest card `MDL_e64enki00` lies flat
and recedes to the left, ending left of the screen center at frames 23 and
30, so lengthening it moves its end further left; the frame's clear colour
shows there. While Deidara transforms
(frames 80 to 130, as frame 104), the black see-through sheet `MDL_e64bl00`
dims the forest: a wall behind him and a floor toward the camera, five
columns across, whose ends lie at the 4:3 edges, so the forest past them
shows undimmed. Widened about the screen center, its floor's near corners
pass the renderer's drawing limits, and those faces drop as light patches at
the bottom; with only its end columns moved outward, it reaches the 16:9
sides. The thin green strips then left at the bottom sides are the grass
piece `MDL_e64jim03`, whose texture `e64jim01` is grass with transparent
gaps, over the dirt `MDL_e64jim00`. It shows only past the 4:3 edges in this
shot, and its vertices are at full brightness where the forest's are at
about two-thirds, so under the same sheet it stays brighter. Hidden, it
uncovers lighter ground at the corners. Other shots show it inside the 4:3
view (frames 45, 200 and 240). The draw sends a mesh's vertex colors by DMA
reference to its loaded array, so changing that array changes the next draw. At frame 369 the white
notch at the right of the horizon is where the grassy band `MDL_e64jim05`
ends: half a ring about the crater, from about 11 to 158 degrees, over the
full ground ring `MDL_e64jim02`, which holds the crater. Widened about the
screen center, the band reaches past the 16:9 edge but its lower edge comes
off the ground ring at the left.
`D21_30` (frames 29 and 322) and `D77_10` (frame 197) frame the film between
black bars drawn as effect models across the screen that reach far past its
top and bottom edges, each edged inside by a thin line drawn separately at the
bar's inner edge.
`D79_10`'s snowy mountain range `MDL_e79mtn00` (frame 171) ends inside the
16:9 sides, leaving a dark ledge at the left and a dark notch at the right of
the horizon. In `D79_20` at frame 45, the sky `MDL_e79sky10` behind Shino
ends in a diagonal edge inside the 4:3 view, where Shino covers it; past that
edge nothing draws, so the 16:9 top-right corner is black. The edge clears
that corner only once the sky is about 1.9 times as wide about the screen
center. `D66_10`'s sky `MDL_e66sky00a` (frame 286) ends just short of the
16:9 top-right corner, which the haze in front shows darker. `D70_20`'s far
mountain `MDL_e70mtn01b` reaches the ground; at frame 271 the pale wedge at
the right is sky between its flank and the near slope, which widening it as
far as 2.5 times does not close. The near mountain `MDL_e70mtn01a` closes it
at 4/3 as wide, and with it the slope `MDL_e70flo01`, without which the near
mountain's other end shows black at the bottom left (frames 240 and 271). At
`D78_10` frame 338 a dark notch shows at the foot of the right cliff of the
background `MDL_e78bg10`, which covers it at 4/3 as wide; that shot starts at
frame 332 in a dissolve from Akamaru's, and in the shots before it the
widened background shows its cliffs' edges at the sides (frames 120 and
320).
The scenes of `D05_10`, `D05_11`, `D12_10`, `D12_11` and `D15_10` hold a glow
board, `MDL_ca_kasan_bord`, over the screen and sized just past the 4:3 view
(`D05_10` frame 50, `D15_10` frame 231). `D18_10`'s speed-line backdrop
`MDL_e18back11` (frame 238) and `D18_30`'s `MDL_e18back01` (frame 129) have
cut corners that clear the 16:9 corners only at about 1.6 times as wide.
`D09_20`'s fist `MDL_e09tkbi01` (frame 250) is a picture on a 4-by-4 grid,
500 units square, whose last strip is plain arm ending just past the right
4:3 edge. `D89_10`'s floor `MDL_e89bgf` (frame 21) ends in a near corner just
past the bottom-right of the 4:3 view. In `D01_20`, `MDL_nrt_copy_2` draws a
group of running clones; from frame 58 its nearest clone's face lies just past
the right 4:3 edge while its other clones show inside the view, and at frame 70
it passes behind the camera. In `D62_20`, from frame 474 to 510 of the shot of
frames 462 to 515, Chiyo's right-hand puppet, the `rh_body` part of
`MDL_st6200t0`, stands far off past the left 4:3 edge. `D59_30`'s dark wedges
at both sides (frames 330 to 380) are where its sand wall `MDL_e59gak01a`
ends: its ends lie just inside the 16:9 sides, and it covers them at 4/3 as
wide. `D05_20`'s dark slanted bands at both sides (frame 210) are where its
translucent light panel `MDL_e05_kogen` ends: its slanted edges cross both
16:9 sides, and it covers them at about 2 times as wide. `D91_10`'s dark
sliver at the right of the horizon (frames 6 to 11, as the opening shot fades
in from white) is a gap in its floor
`MDL_e91flo01`: in a 16:9 view, the renderer draws neither the face of its
vertices 776 to 778, whose corner 776 lies far below the screen at a tenth of
the others' depth, nor any clipped piece of it, while the clipped faces
around it draw. At 4/3 as wide, with its hills `MDL_e91bg0` covering its far
edge at the left, the floor reaches past the gap; later in the shot (frame
25) the widened floor's near edge crosses the 4:3 view beside Yamato.

More films' skies, backdrops and effects end just past a 4:3 edge:
`D59_10`'s sky `MDL_e59sky00` (frame 90) and `D59_35`'s sky
`MDL_e59sky02` (frame 408), `D59_30`'s ring of background pieces
`MDL_e59back01_a..i` (frame 77), which `D59_20` shares, `D60_30`'s sky
`MDL_e60sky01r` (frame 146) and red glow `MDL_e60gre01` (frame 324),
`D61_10`'s smoke ring `MDL_e61skrm01b` (frame 279), `D61_20`'s background
`MDL_e61bg001` and floor `MDL_e61fl01`, which leave a dark line at the right
horizon between them (frame 333), `D61_30`'s cliff `MDL_e61roc04_01..03`
(frame 278), `D62_10`'s sound-effect letters `MDL_e62zugaa/b`, cut where
their panel ends (frame 313), `D63_10`'s rocks `MDL_e63roch01a/b` and
`MDL_e63bgrc01b/d/e` (frame 315), which `D63_20` shares, the sky
`MDL_e63sky01_01` of `D63_50` and `D64_50` (`D64_50` frame 114),
`D71_10`'s floor `MDL_e71flo01` (frame 293), which `D71_50`, `D71_51`,
`D72_50` and `D72_51` share, `D72_20`'s water burst `MDL_e72hasi04` (frame
385), `D72_30`'s sky `MDL_e72_sora` (frame 288), `D83_10`'s sky `MDL_e83sky10` (frames 91 and
162), `D90_10`'s speed lines `MDL_e90line01k` (frame 145) and blue flames
`MDL_e90cut07` and `MDL_e90cut07b` (frame 352), `D91_10`'s speed lines
`MDL_e91line01` (frame 49), `D91_20`'s filter `MDL_e91fil0` (frame 165),
the background `MDL_e93bg01_sky` and `MDL_e93bg01_mut` of `D89_50` (frame
25), which `D93_20` and `D93_50` share, the speed-line tunnel
`MDL_e93img01b` of `D93_30` (frame 25), which `D89_50` and `D93_50` share,
and `D93_30`'s backdrop `MDL_e93_bgl` (frame 398). `D76_10`'s background
pieces `MDL_e76back01_a..i` end just past the 4:3 edges too (frames 63 and
384), but at frame 384 those drawn, widened together, open a dark band at
the left. There the dark line at the bottom left and the light wedge at the
bottom right are where the foreground sand `MDL_e76fbk02` ends over
`MDL_e76back01_h`; `MDL_e76fbk02` alone covers them at 4/3 as wide. In `D93_30` at frame 119, Sasuke's close-up face `MDL_e93ssfac0`, a
flat drawing of about 1,100 vertices sized to the 4:3 view, ends short of
the right 16:9 edge in the shaded edge of his cheek; its left end lies behind
the hair pieces `MDL_e93sshar*`, and past them at the left nothing draws.
`D36_10`'s night sky `MDL_e36_back01` (frame 251) leaves the 16:9 top-left
corner black until it is about 1.6 times as wide. At `D76_20` frame 54 the
slanted edge across the bottom-left corner is that of the overlay
`MDL_e76egre01`, which moves the sand inside the 4:3 view when it widens; the
darker wedge at the bottom right is where a translucent dust card of 18
vertices, `MDL_e76smk06`, `MDL_e76smk10` or `MDL_e76tiri01`, ends. The dark
streak at `D76_10`'s right edge (frames 61 to 72, in the sand shot after
the white flash) is a gap in its sand floor, whose pieces use the texture
`e76back09`: the renderer draws no part of a face there, as in `D91_10`, and
widening the floor does not bring it back. The frame's clear colour shows
through it, lifted by the film's overlays. `D72_20`'s sky dome `MDL_e72sky00` has a
dark rim just past the left 4:3 edge in the top-left corner (frame 385), and
`D80_10`'s floor `MDL_e80bgf20` leaves the bottom-right corner of the 16:9
view bare (frame 176).

Some films tilt the shared boards so an edge crosses a 16:9 side:
`MDL_e00board01_w` in `D04_10` (frame 157) and `D39_10` (frame 270), and
`MDL_e00board01_b` in `D19_10` (frame 321). Also ending just past a 4:3
edge: the shared speed-line backdrops `MDL_e00back01` (`D03_30` frame 242)
and `MDL_e00back18` (`D03_30` frame 311), `D05_20`'s sky `MDL_e05_sky`
(frame 316), `D07_20`'s backdrop `MDL_e07bac01` (frame 50), `D15_30`'s
`MDL_e15_back13` (frame 48), `D22_20`'s floor `MDL_e22flo01` (frame 93) and
its red filter board `MDL_filter_board` (frames 17 and 93), which is in the
film container `D22_20.CCS` rather than its effect container, from the
film's scene ` d\22\sss\d22_20.max`,
`D38_15`'s glow `MDL_e38img3` (frame 327), `D41_10`'s backdrop
`MDL_e41_back` (frame 52), `D42_10`'s floor `MDL_e42flox0` (frame 473),
`D42_20`'s fire `MDL_e42shbom00` and its cloud `MDL_e42clter00` (frame 836),
and `D43_10`'s clouds `MDL_e43_kumo` and wind `MDL_e43_kaze` (frames 208 and
242), splash `MDL_e43_sibuki` and its foam `MDL_e43_kemu` (frame 118).
Widened by 4/3, `MDL_e42flox0` draws a dark line across the right side at
`D42_10` frame 30, where it covers the dark notch at the right of the horizon
in the shot of Hashirama from frame 447 (frame 473), `MDL_e43_kumo` shows
straight cloud edges at the sides at `D43_10` frames 60, 150 and 210, while
`MDL_e43_kaze` alone fills the black right side at frame 208 and the cloud
edge at the left at frame 242, and `MDL_e00back18` in
`D05_10` ends in a hard horizontal edge at the top at frame 50. At `D42_10`
frame 127 the pale gap at the left of the horizon is where its distant hills
`MDL_e42mtn00` end, which cover it at 4/3 as wide.
`D01_20`'s clone crowds `MDL_nrt_tex_l/r` end short of the 16:9 sides
(frame 28), and its near clones are one scene model, `MDL_nrt_copy_2`, that
spans the whole screen (frame 63). Also ending just past a 4:3 edge:
`D04_10`'s sand tsunami `MDL_e04snm02` (frame 125), whose deeper parts lie
behind its sky dome `MDL_e04sky01` near the left of the view, so the depth
test alone keeps the sky's yellow band hidden behind the tsunami's front
lobe (frames 110 to 157), `D07_10`'s floor
`MDL_e07flo00`, whose far edge shows at the right (frames 63 and 354),
`D09_30`'s twisted snakes `MDL_e09snk06t0 body` (frame 223), `D61_30`'s floor
`MDL_e61flo03`, whose end leaves a dark wedge at the right horizon (frame
232), `D63_30`'s sky panel `MDL_e63kbg01` (frame 199), `D68_20`'s log
leaning behind the fighter `MDL_e68wood01_b`, one part of 180 vertices
running about 4,700 units along its Y between end caps, its far end cut and
resting under the diagonal trunk `MDL_e68wood_c` (frame 171), `D83_10`'s
rock slope
`MDL_e83gak01` (frame 10) and `D91_10`'s wind lines `MDL_e91air02a/b`
(frame 329).

More pieces end just past a 4:3 edge, by film and frame: `D04_10`'s distant
sand `MDL_e04enkeisuna00` (242), whose end cuts the dune at the right, over
the near sand `MDL_e04sandf01`, whose own edge shows as a light streak at the
bottom left when the distant sand alone is 4/3 as wide; `D15_10`'s hill
`MDL_e15_oka` (215); `D58_20`'s cloud piece `MDL_e58kmok` (371), past whose
end the blue backdrop shows above the dune; `D61_10`'s sky `MDL_e61sky02` and
smoke `MDL_e61smbl01` (281 and 310); `D61_20`'s mountains `MDL_e61mtn00`
(365); `D68_30`'s far mountains `MDL_e68mtn0` (347); `D70_10`'s backdrop
`MDL_e70img05` (193); `D70_25`'s three slanted panels `MDL_e70back03_a..c`
(91), one 3-by-5 grid mesh each with the texture `e70back01`, whose light
edges are the white lines between them; `D71_10`'s distant view
`MDL_e71enkei01` (308); `D71_30`'s rocks `MDL_e71rcbk01a..c` (174); `D78_10`'s
dust `MDL_e78skn01` and sky `MDL_e78sky03` (49); `D79_10`'s crater
`MDL_e79jng00a` (439); `D79_20`'s ground `MDL_e79bg10` (176); `D80_20`'s floor
`MDL_e80bgf` and `MDL_e80bgf01` with its distant mountains `MDL_e80bgm` (49),
whose floor widened opens a dark hole under the sphere and a light floor edge
in the sphere's shot (331); `D81_20`'s sky `MDL_e81sky02` (212); `D83_10`'s
floor `MDL_e83flo02` and background `MDL_e83bg10` (442); `D89_10`'s shadow
`MDL_e89kge01` and distant hills `MDL_e89bgm` (166); `D90_10`'s flames
`MDL_e90cut04` (357); and `D93_30`'s light filter `MDL_gemfil` (105), which
lights the face while Chidori shines. `D09_30`'s arching snake
`MDL_e09snk00_a` hangs its tail past the right 4:3 edge, where it is cut off
blunt in mid-air (83), in the shot that ends at frame 97. Earlier in that
shot the tail's end lies in the ground, inside the 4:3 view to frame 62 and
just past its right edge from frame 64; it lifts out of the ground at frame
66, and from frame 67 to 75 it lies in front of the body of the snake
lunging left below it. That
snake ends at the right in its own tapering tail tip, and a third snake's
head comes in from the right 16:9 edge under the hanging tail, reaching the
4:3 view by frame 93. The arching snake's tube is a blend of the tubes of
`MDL_e09snk00_a` and `MDL_e09snk00_b`, 1,062 vertices each: their mean
from frame 66 to 97, and four parts of `_a` to six of `_b` at frame 64. The
other two snakes are both `MDL_e09snk00_c`, drawn twice, its tube 726
vertices and rigid. The camera cuts close at frame 79; from then the
lunging snake's last quarter runs below the bottom edge from inside the 4:3
view and comes back up to its tip at about 16:9 (620, 307) at frame 83,
beside the third snake's head, which is nearer the camera. At `D09_20` frame 174 the dark mass whose straight
end shows just past the right 4:3 edge, at 16:9 X 570 of 640, is the picture
card of hands `MDL_e09hdita01`, textured `e09hdita01`: like the fist
`MDL_e09tkbi01`, a 4-by-4 grid, of 54 vertices running X -4,013 to -13 and Z
-2,000 to 2,000 raw, its texture's U reaching 254 at its largest X. The
snaking arms textured `e09hd_l02` run far past both edges.
`MDL_e93ssfac0`'s colours come from its
vertex colours over a white region of the swatch texture `e93sstex0`: every
vertex samples U and V 0.69 to 0.97. Its right end is one column of 23
vertices at X 1,074, the next vertices at X 649, and at frame 80 its end
lies just inside the right 16:9 edge.

What draws at the 16:9 sides of more shots: in `D61_20` (365) the floor is two
models, the ringed `MDL_e61fl03` near and the dusty `MDL_e61fl01` far, whose
edge between them lies across the screen under the rolled camera. In `D79_10`
(439) the forest is `MDL_e79jng00` and `MDL_e79jng00a`, which meet along the
crater's rim. In `D83_10` (442) a ridge `MDL_e83mori` (texture `e83bg02`)
lies in front of the rocks of `MDL_e83bg10`, and its end shows just past the
right 4:3 edge. In `D36_10` (247) the cloud card `MDL_e36_wd03` ends in a
straight slanted edge at the top left of the 16:9 view, with the night sky
past it. `D22_30`'s red tint (12) is `D22_30.CCS`'s untextured
`MDL_e22_img_color`, drawn in vertex colour red 0x28 at alpha 0x19 and
spanning 16:9 X 36 to 598, so the sides past it show the scene untinted; it
is that film's only untextured model. In `D34_20` (204) nothing draws left of
16:9 X 33 above the middle, where the rocks `MDL_e34rock a..c` (texture
`e34rock06`) end. `D80_10`'s light band at the left (353) is what its filter
`MDL_e80fil01`, textured `e00white01` and drawn black at alpha 0x2a over the
scene, leaves uncovered: its slanted left edge crosses the left side between
16:9 X 30 and 70. In `D79_20` (176) the ground slope `MDL_e79flo01` is a
single quad textured `e79flo20` whose left end lies at 16:9 X 40, past which
the background `e79bg03` shows. `D19_10`'s white past the trees at the right
(248) is its sky `MDL_e19sky02`, seen between the foliage (texture
`e19tree00`) of the scene's big tree `MDL_d19301wdnc` and the cut-out forest
cards `MDL_e19mor01a` and `MDL_e19mor01c` (textures `e19mor01` and
`e19mor03`), as it shows in gaps at the right of the 4:3 view. In
`D58_30` (293) and `D80_20` (331) the dark gap at the left is the clear
colour, where no model draws. In `D67_20` (336) the dark notch at the left
edge is the shadowed side, textured `e67rock06`, of one of the 71 floor
fragments `MDL_e67hhn00_01..71`; its floor is the square slab
`MDL_e67flo04`, 1,762 units across, with the strip `MDL_e67flo05` along one
side, and past its far corner at the top left of the 16:9 view only the dark
sky shows; that shot down onto the broken ground runs from frame 311 to the
film's white fade near frame 360, after a shot of a floating rock that ends
at frame 310. The sky `MDL_e67sky03` lies over the far ground's edge there
as haze: with the sky hidden, the top of the far-left rock turns from
(117, 108, 161) to (113, 92, 131), the tone of the rocks beside it.
`D57_35`'s shot of the crater runs from a white fade, white to frame 536,
to frame 601; frame 602 is the close shot after it. Its crater, all in
`D57_35E.CCS`, is the near floor `MDL_e57flo38` (233 vertices, texture
`e57flo35`), the wall, the second part of `MDL_e57flo37` (282 vertices,
drawn with `e57bg36`), and the far rock `MDL_e57bg37` (130 vertices,
`e57bg35`) at the left, under the dust cards `MDL_e57kem..`, `MDL_e57kmr00`
and `MDL_e57kmb01`. At frame 555 the floor's left end and its right corner
lie just past the 4:3 edges, and so does the wall's left end, with the far
rock showing beside it. In `D58_50`'s last shot, from frame 766, Sakura stands
far off on the cliffs with the defender crouched at her feet; `D62_50`
ends with the same shot from the same frame. The cliffs are many copies of
the rocks `MDL_e58bgcla..f`, each drawn with its own matrix, and their left
end lies just past the left 4:3 edge, the clear colour and the sky showing
beyond it. The shadows at the two fighters' feet are their own shadow parts
and the stand-in's, `MDL_1cmn00t0 shadow..`. A shadow part's device matrix
is the projection controller's renderer's device projection (renderer
+0x40; the controller at the active render environment +0xCC, its renderer
at +0x4C) times the part's model matrix (draw context +0x110), composed in
`model_part_queue_projection`. In `D36_20` (266) the posts and logs are `MDL_e00wood_a..f`
(textures `e00wood01..03`): the teal crossbeam is `MDL_e00wood_c`, the
diagonal log below it `MDL_e00wood_b`, the vertical post `MDL_e00wood_d` and
the thick trunk at the right `MDL_e00wood_a`. Both logs are crooked, rings of
a few vertices joined by long segments: the crossbeam is two meshes, of 93
and 87 vertices, and its left end is the ring at its largest Y; the diagonal
log is one mesh of 180 vertices, and its left end the ring at its smallest Y.
In `D86_20` (71) the foot at the left edge is the defender's: the film
stands the defender just past the left 4:3 edge while its shot shows the
lunch box, and with Naruto as defender hiding `MDL_1nrw00t0` removes it. A
defender's body parts are the records named `MDL_` and the first four
letters of its presentation body file (`1nrwbod1.ccs`), the character taken
from `UltimateJutsuSkillPlay.defender_id` (57 there, with attacker 86,
Asuma). The shadow under that foot is not the defender's: in that frame
`scene_object_submit_geometry` queues shadow parts only for Asuma
(`MDL_1asw00t0 shadow01..17`) and for `MDL_1cmn00t0`, a stand-in whose body
does not draw there, and dropping the stand-in's removes the shadow.
`model_part_queue_projection` is the only caller of
`projection_controller_append_packets`, and the call at 0x0019109C its only
caller. The frame also draws an untextured black figure at alpha 0x80, of
2,573 vertices in one strip, mostly off the screen to the left. The fire
trail `MDL_e86firtl01` (texture `e86firtl01`, drawn additively) is a ribbon
of 262 vertices from past the right edge to the defender's feet, its end
there at its smallest Y. A bright spot near that end shows at the left 16:9
edge at frame 71 (X 0 to 6), 72 (15) and 73 (39); by frame 74 the trail
shows nothing left of X 260. The shot travels low over the water from frame
66, and the floor `MDL_e86flo01` is cut off close to the camera: the
bottom-right corner shows the clear colour from frame 66, 72 pixels wide at
the bottom edge, to frame 72, 6 pixels wide. The lighter's shot ends and
the defender stands in the top-left of the 16:9 view from frame 74. `D70_25`'s left
panel is `MDL_e70back03_b`, its outer end at its smallest Y, and its right
panel `MDL_e70back03_c`, its outer end at its largest Y; the middle panel is
`MDL_e70back03_a`. Each outer panel is a flat square 100 units across, of 30
vertices in a 2-by-4 grid, whose texture's streaks run along its X. At frame
91 the left one leans: its outer edge slants in toward the bottom, and its
top edge, at its smallest X, crosses the top-left 16:9 corner. The panels
draw after the characters, with alpha 0 down their middle column, so each
one's dark band is the clear colour. At frame 91 the bottom-left 16:9
corner, about 10 by 20 pixels under the left Kakashi's vest hem, also shows
the clear colour, although the left panel's outer strip covers it once its
outer end is moved out: strips of that Kakashi, textured as his body, and
their shading passes, which subtract, test no alpha and write depth, cover
that pixel nearer than the panel. The seam in `D72_20`'s clouds (414) is the left edge of
the flat card `MDL_e72hasi00` (texture `e72hasi00`, 18 vertices), at 16:9 X
68; the burst `MDL_e72hasi04` is many small quads over it. The card is in
the one shot from frame 345 to 450: it shows as the water column from frame
365 to 375, and the clouds cover it from about frame 380. `D09_30`'s
snakes `MDL_e09snk00_a..c` are each a head part and a body tube whose end at
its largest Y is the tail tip. `D93_30`'s close-up shot starts at frame 80; frames 76 to 79 are the 3D
shot before it. At frame 80 the card `MDL_e93ssfac0` leans, its right end
column slanting in toward the bottom, and nothing draws past it: the grey
band at the right (80), widest at the bottom, is the film's overlays and its
blend of earlier frames over the clear colour, until the card's end passes
the 16:9 edge by frame 84. `D34_20`,
`D36_10`, `D36_20` and `D93_30` blend earlier frames into each frame, so a change shows fully only
tens of frames later. These are GS draws of sampled frames, matched to models
through their textures.

Films keep some characters just outside the 4:3 view. In `D02_10`, from
frame 190 to 232, Sasuke's `MDL_1ssk00t1` lies at screen X -1.08 to -1.00
renderer half widths and `MDL_1ssk00t0`'s bounds at -1.73 to -0.63, while
the 4:3 view, at +-0.75, shows none of him (frames 200 and 220). In
`D59_10`, from frame 186 to 234, Gaara's `MDL_1gaw00t0` and `MDL_1gaw01t0`
lie at 0.81 to 1.24, and his robe `MDL_1gawl00t0` beside them, whose bounds
reach behind the camera. In `D62_20`, Chiyo is the film's own `MDL_st6200t0`
(parts `body`, `lh_body` and `rh_body`), which 4:3 shows at the left (frames
470 to 505), while her battle model `MDL_1chy00t0` draws no part but still
reaches the shadow pass. `MDL_1cmn00t0` draws no part in the films sampled
(`D04_10`, `D25_20`, `D36_10`, `D62_20`, `D80_10`, `D83_10`, `D89_10` and
`D91_10`), yet its 17 limb shadows reach the shadow pass.

`scene_object_submit_geometry` (`0x00190F40`) gates a scene object's shadow,
its auxiliary model queued through `model_part_queue_projection`, apart from
its body, so a hidden body still casts one. In `D62_10` at frame 313,
Chiyo's `MDL_1chy00t0 shadowNN` and the wire puppet's
`MDL_e6200t0 shadow` reach the shadow pass while neither body draws; both
shadows lie just outside the 4:3 view. These are frames sampled through PINE
while the film plays, not every film.

Distortion lenses are `ygm` models, such as `D58_50`'s `MDL_58ygm_a` and
`D57_25`'s `MDL_e57zygm02_b`, which about forty films carry. Before one draws,
the film copies the screen with sprites to its own buffer, and the lens draws
that copy back blended at half, through a destination-alpha test. Its texture
coordinates follow its own projected vertices, clamped to the copy: in
`D58_50` frame 28 each vertex samples about 0.63 of its distance from the
screen center, a zoom, in both directions. `morpher_blend_vertices`
(`0x00197570`) computes them when the draw context's flags at `+0x20C` hold
`0x80000`: it projects each vertex through the renderer's
`device_projection` times the context's matrix at `+0x110`
(`0x00197668`), maps the renderer's device rectangle onto `0..4096` by
`0..3576`, and clamps. That projection is separate from the model's drawn
device matrix, so a lens samples where it draws only while the two agree.
`D25_20` carries the lens `MDL_e25ygm02`.

## Addresses

Addresses are live and follow
[Retail game file identities](../../game/files/file_identities.md#address-conventions).
The following globals belong to the resident ELF, `SLPS_258.37`, and are
annotated in its BSS block. Their producers and consumers establish these roles:

| Symbol | Role |
| --- | --- |
| `sp_skill_opponent_groups` | Relocated `SpSkillOpponentGroup` array pointer |
| `sp_skill_opponent_group_count` | Signed halfword opponent-group count |
| `sp_skill_texture_switch_table` | Owned expanded texture-switch table pointer |
| `sp_skill_draw_switch_table` | Owned expanded draw-switch table pointer |
| `sp_skill_override_main_path` | Buffer for the derived main resident path; capacity remains unestablished |

## Opponent-dependent cinematic selection

`sp_skill_play_start` (`0x0035CF00`) resolves the attacker/defender roles,
then asks `jutsu_resolve_character_skill` (`0x0035CA80`) for a replacement.
Any result other than `-1` replaces the requested skill before resource
lookup. The initialized opponent table contains three defender groups:

| Defender ID | Requested skill | Replacement skill | Stored path |
| ---: | ---: | ---: | --- |
| `0x59` | `0x48` | `0x49` | `pl/2nrtbod1.ccs` |
| `0x4C` | `0x04` | `0xB6` | `pl/2nrtbod1.ccs` |
| `0x4C` | `0x0C` | — | `str/d05_11.ccs` |
| `0x4C` | `0x18` | `0xB7` | `pl/2nrtbod1.ccs` |
| `0x4C` | `0x1C` | — | `str/d13_21.ccs` |
| `0x4C` | `0x22` | — | `str/d15_21.ccs` |
| `0x4C` | `0x3B` | — | `str/d36_21.ccs` |
| `0x4C` | `0x7A` | — | `str/d69_21.ccs` |
| `0x4C` | `0x48` | — | `str/d46_12.ccs` |
| `0x4C` | `0x84` | — | `str/d71_51.ccs` |
| `0x4C` | `0x88` | — | `str/d72_51.ccs` |
| `0x28` | `0xB0` | — | `str/d92_11.ccs` |

A dash represents stored replacement `-1`. These nine rows keep the skill
and let `sp_skill_find_stream_override` (`0x0035C930`) choose the stored
opponent-specific stream path. The main resident path in
`sp_skill_override_main_path` substitutes `e.ccs` for `.ccs`, using
`sp_skill_main_ccs_extension` and
`sp_skill_ccs_extension`. `sp_skill_build_requests` (`0x0035CC20`) uses
both paths. The three nonnegative replacements change the skill first,
so their old stored paths are not selected by lookup on the replacement;
that skill's normal SINF row supplies its resources
([request-table source](../../game/files/ccs_runtime.md#request-table-source)).

Attacker `0x51` has the only additional attacker-specific branch:
skill `0x95` becomes `0x96` when `Fighter.contact_flags` has marker
`0x20`. `awakening_clear_marker` (`0x0020DD20`) clears it before return.
With this attacker and a valid fighter, the helper also clears the marker
when the replacement condition fails, before the table lookup. The raw
byte access and saved field declaration establish this gate.

An uninitialized group pointer or zero count returns `0`, whereas an
initialized search without replacement returns `-1`; the constructor accepts
the former as a replacement. This contract does not establish a presentation
before initialization. `sp_skill_relocate_request_table` (`0x00357B10`)
initializes the tables after resource adoption in
`battle_skill_ccs_adopt` (`BTL.BIN 0x00769110`) and
`etc_skill_ccs_acquire` (`ETC.BIN 0x006BE710`).
The direct-call coverage does not exclude indirect callers.

## Participant fields and request callbacks

The two side descriptors are independent of attacker side. Each descriptor's
low byte is its fighter ID; bits `16..23` are its appearance flags.
`UltimateJutsuSkillPlay` retains both side and role ordering. These fields
are established by raw accesses; typed owner-array expressions alone do not
establish their layout:

| Field | Initial value |
| --- | --- |
| `attacker_side` | attacker side |
| `side_ids[0/1]` | side-0 / side-1 fighter IDs |
| `appearance_flags[0/1]` | side-0 / side-1 appearance flags |
| `attacker_id / defender_id` | role-ordered fighter IDs |
| `selected_skill / skill` | selected skill after replacement |
| `request_ordinal` | zero |

`sp_skill_play_begin` (`0x0035A070`) runs for each request. It retains
`container` and the first resident request's `main_container`, binds defender
body/eye/mouth resources to `EXT_1cmn00t0`, and finds the attacker body through
the side-formatted `EXT_1xxx00t0 body` name. It names the stream's optional
defender offsets and filter after the stream's header name,
`sp_skill_damage_offset_name_format` (`0x005AB668`) and
`skill_stream_filter_resource_format` (`0x005AB760`, any extension removed),
and finds each through the case-sensitive optional lookup, so a stream whose
header name differs from those objects' suffix, even in letter case only,
plays without them. Appearance lookup uses each side's
own retained flags. After installing resources and the time limit, setup
increments `request_ordinal`. Callback order belongs to
[CCS runtime](../../game/files/ccs_runtime.md#per-request-lifecycle-in-playdecode).

Two exclusions skip construction of `optional_body` while setup continues:
defender `0x5D`, or defender `0x0A` with `stream_identifier == 0x200302`.
The latter identifies no shipped move.

### Stream-name identifier and the optional-body comparison

The identifier comes from the inline CCS header name read by
`ccs_read_header` (`0x001AC290`) into `CcsContainer.name`, independently
of request path, selected skill or defender ID. Setup computes:

`(((name[1]-'0')*16 + name[2]-'0') << 8) | ((name[4]-'0')*16 + name[5]-'0')`.

The bytes are signed. The parser ignores the `d`, underscore, optional
`e` suffix and any third digit in either pair; `d14_20` produces `0x1420`.

The inspected retail numeric headers have two decimal digits in each pair.
Their maximum result is `0x9999`, so they cannot satisfy the setup comparison
with `0x200302`. The separate defender-`0x5D` exclusion remains unconditional.
No alternate identifier producer appears between parsing and comparison
inside this callback. The mismatch establishes neither an intended constant,
resource nor player-facing move name.

UN2's begin routine builds its identifier from three digits of a
`dDD_L_P` stream name, so `0x200302` there is stream `D20_3_2` (Guy's
Ultimate: Hidden Lotus), the one film in which defender Haku (ID 10) does
not get his mask, and `0x70302` is `D07_3_2`, where UN2 also hides
`OBJ_1skr20t0 bod`
([Nine-Tailed Naruto: UN2](un2/nine_tailed_naruto.md#ultimate-jutsu-contest-and-damage)).
NA2 kept both constants.

| SINF skill | Stream path | Header identifier |
| ---: | --- | ---: |
| `0x20` | `str/d14_20.ccs` | `0x1420` |
| `0x84` | `str/d71_50.ccs` | `0x7150` |
| `0x88` | `str/d72_50.ccs` | `0x7250` |
| `0x95` | `str/d81_20.ccs` | `0x8120` |
| `0x96` | `str/d81_30.ccs` | `0x8130` |

The header check does not decode every cinematic or establish selection of
every request.

## Authored appearance substitutions

`SpSkillRequestRow.appearance_count` and `appearance_rows` select
`SpSkillAppearanceRow` entries independently of the resident/stream request
counts. The clean table contains 142 entries used by 57 skills: 96 `EXT`
and 46 `MAT` targets. A zero count has a null appearance pointer.

Each entry names a source container, source palette and target.
A null source-container name means the request's main resident container.
Attacker-side flags are masked with `5`: bit `0` appends
`sp_skill_palette_c1_suffix` (`c1`), otherwise bit `2` appends
`sp_skill_palette_c2_suffix` (`c2`), otherwise the name is unchanged.
Bit `0` wins when both are set
([palette ownership](../../game/character_assets.md#model-and-appearance-name-consumers)).

`sp_skill_apply_external_palette` (`0x00357FE0`) substitutes streamed
`EXT` targets only after finding the target, source container, selected
palette and target `CcsScenePlayTarget.model`. It duplicates the affected
arrays through `model_instance_duplicate_arrays` (`0x00198B10`) with
`0x2000`, then applies the palette through
`model_instance_rebind_palettes` (`0x00198AB0`).
`sp_skill_apply_material_palette` (`0x00358130`) substitutes other targets
in the selected resident container through `SpSkillPaletteTarget.palette`.
Missing required lookups omit the substitution; this does not establish a
shipped lookup miss.

`sp_skill_play_begin` applies a skill's entries after rebinding the attacker's
and defender's bodies (`sp_skill_play_begin_apply_appearance_rows`). It reads
the request row by skill with no upper bound, sends an entry whose target
starts with `EXT` to the external routine and any other to the material
routine, and applies entries with the default costume too, through the
unsuffixed palette.

UN3 keeps these substitutions in its executable instead.
`sp_skill_palette_record_lists` gives each skill `{container, target,
CLT…c1, CLT…c2}` records, applied only when the attacker's flags masked with
`5` are set. `sp_skill_apply_appearance_substitutions` also swaps material
palettes in code for streams `d23_101`, `d10_102`, `d03_202` and `d01_204`,
whatever the flags, with the unsuffixed palette when they are zero.

| Skill | Entries | Representative substitutions |
| ---: | ---: | --- |
| `0x01` | `5` | `2nrtbod1/CLT_2nrtbody` on five `EXT_2nrt00t0..04t0 body` targets. |
| `0x02` | `24` | Nine main-container copy targets, four body-provider targets, and eleven main-container material targets. |
| `0x20` | `2` | `1tovbod1/CLT_1tovbody` on `EXT_1tov00t0 body`; `1tyobod1/CLT_1tyobody` on `EXT_1tovudebody`. |
| `0x7F` | `5` | Three `1kkwbod1` and two `2kkwbod1` body targets. |
| `0x95 / 0x96` | `1` each | Both use main-container `CLT_2tywhss` on `MAT_e81hss01e`. |
| `0xB5` | `1` | Main-container `CLT_e93ssw` on `EXT_e93ssw`. |

## Per-character texture and draw-state switches

Two optional families use `character_model_abbreviations` to load attacker
`BIN_` resources from `strmcmn`, independently of the SINF appearance count.
The clean resource inventory is:

| Resource | Directory ID | Authored changes |
| --- | ---: | --- |
| `BIN_strtc_data_kiw` | `404` | Skill `0x8F`: source `d78_30e.ccs`, `TEX_1kiwakw1 -> TEX_1kiwakw2` on `EXT_1akw00t0 body` at frame `1`, reversed at `510`. |
| `BIN_strrev_data_itw` | `401` | Skill `0x84`: `OBJ_rev01/OBJ_rev03`, enabled at `385`, disabled at `538`, group values `15/5`. |
| `BIN_strrev_data_kbw` | `402` | Skill `0xAC`: `OBJ_rev01`, enabled at `235`, disabled at `263`, group value `10`. |
| `BIN_strrev_data_ksw` | `403` | Skill `0x88`: the same target names and `385/538` changes as the `itw` resource. |

`sp_skill_load_texture_switches` (`0x00358560`) runs before player
construction. Missing resources or zero groups return zero; no group for
the requested skill frees the table but returns one. The constructor does
not branch on this return.

`sp_skill_apply_texture_switches` (`0x00358AD0`) does nothing without a
table. Forward playback applies matching changes at their exact frame;
frame `1` or negative playback instead uses
`sp_skill_reconstruct_textures` (`0x003588D0`) to restore each target from
the latest eligible entry.
`sp_skill_apply_texture_entry` (`0x00358BF0`) requires the source,
target and texture before applying a change. `sp_skill_play_destroy`
(`0x0035D7C0`) releases the table during teardown.

`sp_skill_load_draw_switches` (`0x00358DA0`) runs during request setup.
Missing resources, zero groups or no matching skill return zero; the last
case frees its table. A match initializes targets hidden through
`scene_apply_table_draw_modes` (`0x003592C0`).
Per-frame application selects the last change at or before the current frame,
updates the render group through `ordered_controller_set_group`
(`0x0010A0A0`), and sets `CcsScenePlayTarget.alpha` and its
flag-dependent `inherited_factor` to `0.0/1.0`.
`model_instance_set_blend` (`0x001987A0`) selects `0/10`.
`sp_skill_release_draw_switches` (`0x003590D0`) frees the table and
attached helpers at request end.

Absent tables omit optional changes while the surrounding callbacks continue.
The resource inventory comes from clean CCS contents; the receiving resident
pointer slots are uninitialized in the static image. These facts establish
neither failure nor provider/target presence in every stream.

## Defender-specific draw and placement dispatch

`sp_skill_play_draw` (`0x0035C110`) uses
`sp_skill_defender_body_draw_allowed` (`0x00356E90`) with defender ID,
selected skill and current frame. Zero omits
`sp_skill_draw_scene_entries` (`0x003556C0`) for `optional_body`;
other drawing continues.

`sp_skill_defender_draw_gates` holds inclusive frame ranges and optional
defender lists. An empty list selects `{0x38,0x35,0x23,0x32,0x33,0x30}`.
Outside the ranges, for an unlisted defender or without a skill table, ordinary
drawing proceeds. Seven code-driven substitutions replace the selected gates:

| Skill | Defender | Replacement omitted-draw ranges |
| ---: | ---: | --- |
| `0x84 / 0x88` | `0x30` | `258..274`, `426..539` |
| `0x84 / 0x88` | `0x49` | `426..635` |
| `0xB0` | `0x30` | `170..219` |
| `0x78` | `0x30` | `470..521` |
| `0x4E` | `0x35` | `333..667` |

Ordinary skill `0x78` omits `169..180`, `350..405` and `460..469`
only for `0x49/0x30`; the override changes the `0x30` case.
Ordinary `0x84/0x88` omit `426..539` for
`{0x3B,0x30,0x38,0x33,0x32,0x49,0x4B}`.
These gates affect rendering, not damage, contest state or cinematic stopping.

UN3 keeps the same hiding in `sp_skill_optional_body_hide_ranges`
(`0x0047C010`): per skill, a range count and inclusive `{start, end}` frame
halfwords, always for the six default defenders, read by
`sp_skill_defender_optional_body_allowed`. Against Kidomaru, the hidden
optional body includes his fourth arm, which disappears in those frames
(runtime observation).
Visible body animation within the omitted ranges remains unestablished.

`sp_skill_adjust_defender_position` (`0x003571F0`) selects from
`sp_skill_defender_position_groups` and `sp_skill_defender_position_rules`.
A matching defender and inclusive frame range replaces the four-component
position prepared by the frame callback; no match keeps it unchanged.
Shared lists cover skills `0x4F/0x54`, `0x84/0x88`, `0xA7/0xB5` and
`0x1E/0x1F`. Representative entries show why the replacement skill matters:

| Skill | Defender | Frame range | Stored vector |
| ---: | ---: | --- | --- |
| `0x4F / 0x54` | `0x33` | `400..460` | `(-36,82,0,1)` |
| `0x84 / 0x88` | `0x3F` | `426..539` | `(9,-5,5,1)` |
| `0x95` | `0x28` | `421..470` | `(-144,-29,33,1)` |
| `0x96` | `0x28` | `461..510` | `(-144,-29,33,1)` |

`ccs_matrix_row_toggle` (`0x003572E0`) applies
`sp_skill_defender_object_groups` for a specific defender or `-1`
and an inclusive frame range. Authored command prefixes mean:

- `U ` clears `CcsScenePlayTarget.flags` bits `2..3`; `D ` sets them
  and restores `alpha/inherited_factor` to `1.0` through the ordinary
  flag-dependent update.
- `UU` finds the named subobject of `CMP_1cmn00t0 trall` and replaces
  the first three local-matrix vectors with zero vectors.
- `SXR` negates the first local-matrix vector and marks `matrix_dirty`.

The helper also implements `SR/SYR/SZR`, negating all three, the second
or the third vector, respectively; none occurs in the inspected clean table.
Missing targets keep their existing state. The complete shipped dispatch is:

| Skill | Defender | Inclusive frame ranges and targets |
| ---: | --- | --- |
| `0x05` | any | From `336` through `9999`, `U ` on `EXT_e02_tdrn01/02`. |
| `0x84 / 0x88` | `0x16` / any | `UU` on the named common-body subobject at `426..539` for `0x16`; `SXR` on `EXT_e71eye02` at `0..9999` for every defender. |
| `0xA7 / 0xB5` | any | `U ` on `EXT_e93smk05c32/33/34`, `0..9999`. |
| `0x29` | any | `U ` on `EXT_1sin00t0 body`, `111..269`. |
| `0x9B` | any | `U ` on `EXT_1jrw00t0 body`, `151..168`. |
| `0x94` | any | `U ` on both `EXT_1tyw00t0` and `EXT_1cmn00t0` eye1/eye2/mou1 targets, `97..139`. |
| `0xB2` | any | On common eye1/eye2/mou1 targets: `D ` at `212..236`, `U ` at `237..281`, `D ` at `282..455`. |

These predicates can run every eligible frame, including `SXR`.
The operation and ordering do not establish the accumulated visible
orientation after surrounding animation updates.

`jutsu_hit_popups_draw` (`0x0035C5B0`) consumes the same interruption gate
as the presentation cut. With contest status `4` and
`jutsu_branch_frame_reached` (`0x0035DB20`) accepting argument `0`,
both `UltimateJutsuSkillPlay.popups[].active` fields clear and normal popup
animation is skipped. The authored threshold is frame `126`.
This consumer neither produces status `2` nor issues a cinematic branch.

`sp_skill_bind_alternate_body_parts` (`0x00358250`) retains original models
for `sp_skill_defender_bone_names`. Defender `0x32` enables all 17 through
`sp_skill_gaara_bone_mask`; `0x4C` enables only `pelvis/spine/spine1`
through `sp_skill_hiruko_bone_mask`; other IDs do no replacement.
It requires the node and provider before constructing a replacement.
`sp_skill_play_end` (`0x0035AF20`) restores the models at request end.

### Selected defender providers and cinematic targets

The provider comes from `CcsSceneObjectDescriptor.shadow_model_record`,
which `ccs_parse_scene_object` (`0x001B2670`) populates separately from
`model_record`. Replacement requires a `CcsRecord.runtime` other than
null or sentinel `4`; `ccs_model_instance_initialize` (`0x001992A0`)
constructs the replacement handle, installed as
`CcsScenePlayTarget.auxiliary` while `bone_replacements[].original`
retains the previous model. Before that geometry check, the node mask writes
target `flags` bit `5`, including clearing it for a disabled node.
Both node-name lookups are optional; their handling belongs to
[CCS runtime](../../game/files/ccs_runtime.md#wildcards-and-secondary-values).

`character_presentation_body_filenames` and `character_model_abbreviations`
select `1gavbod1.ccs/gav` for defender `0x32` and `1schbod1.ccs/sch`
for `0x4C`. Names follow `sp_skill_defender_node_name_format`
(`EXT_1cmn00t0 %s`) and `sp_skill_provider_node_name_format`
(`OBJ_1%s00t0 %s`)
([body-table ownership](../../game/character_assets.md#character-indexed-filename-families)).

Both `PL/1GAVBOD1.CCS` and `PL/1SCHBOD1.CCS` contain all 17 requested
provider nodes with these directory IDs. Secondary links select
`MDL_1gav00t0 shadowNN` or `MDL_1sch00t0 shadowNN`, each with model flags
`0x0008` and one mesh part. The primary bone-node models have zero parts
and are not this helper's source.

| Node | Provider object ID | Secondary model ID / `shadow` suffix | Cinematic wrapper ID |
| --- | ---: | --- | ---: |
| `pelvis` | `6` | `72 / 17` | `118` |
| `spine` | `7` | `74 / 16` | `119` |
| `l thigh` | `8` | `76 / 12` | `120` |
| `l calf` | `9` | `78 / 11` | `121` |
| `l foot` | `10` | `80 / 10` | `122` |
| `r thigh` | `12` | `88 / 15` | `124` |
| `r calf` | `13` | `90 / 14` | `125` |
| `r foot` | `14` | `92 / 13` | `126` |
| `spine1` | `19` | `104 / 09` | `131` |
| `neck` | `20` | `106 / 08` | `132` |
| `head` | `21` | `108 / 01` | `133` |
| `l upperarm` | `33` | `132 / 04` | `145` |
| `l forearm` | `34` | `134 / 03` | `146` |
| `l hand` | `35` | `136 / 02` | `147` |
| `r upperarm` | `48` | `157 / 07` | `160` |
| `r forearm` | `49` | `159 / 06` | `161` |
| `r hand` | `50` | `161 / 05` | `162` |

`ccs_parse_model` (`0x001B0C40`) allocates model descriptors for the nonzero
part counts. These stored dependencies and the parser path do not establish
successful allocation during a cinematic.

The wrapper IDs in the table are shared by the inspected
`D71_50/D71_51/D72_50/D72_51.CCS` files. All 17 common-node records use
`0x0A00` wrappers; `ccs_parse_external_record` (`0x001B2800`) changes
only the first three name bytes from `OBJ` to `EXT`.
[CCS runtime](../../game/files/ccs_runtime.md#type-0x0a00-traversal)
owns wrapper traversal.

| Variant | Pelvis/spine/spine1 linked model-instance IDs | Stored parents |
| --- | --- | --- |
| `50` | `1161/1162/1174` | `117/118/119` |
| `51` | `1252/1253/1265` | `117/118/119` |

The independently adjusted `EXT_e71eye02` is wrapper `112` in all four
files, linked to same-named `OBJ_e71eye02`: ID `1155` for `50`, ID
`1246` for `51`, parent `72` in both.
SINF skills `0x84/0x88` normally select `50`; defender `0x4C` selects
`51` through the [opponent override](#opponent-dependent-cinematic-selection).
These selected targets and providers are present. The bounded asset evidence
does not establish every cinematic's targets, allocation success or the
accumulated result of repeated `SXR`.
