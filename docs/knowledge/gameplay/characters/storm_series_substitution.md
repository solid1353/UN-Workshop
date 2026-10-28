# Storm-series substitution gauge

## Research coverage

Established: the official manuals' limited-use substitution gauge, its
recovery over time and by other means, the *Storm 4* one-notch cost and
next-round refill, and the *Storm Connections* 1.20 fix of frame-rate-dependent
recovery. The official sources give no numbers; the `0..100` meter, cost,
delay, refill rate and damage threshold below come from community measurement.
Open: nothing.

## Evidence labels

- **Official** behavior is stated by a publisher-provided source.
- **Measured** behavior comes from community measurement or visual inspection
  and is not an official specification.

## Official contract

The official *Storm 3 Full Burst* manual describes substitution as a
limited-use action, identifies the HUD element that tracks remaining uses,
states that substitution is unavailable when the gauge is empty, and says the
gauge refills gradually. The *Storm Revolution* and *Storm 4* manuals preserve
that contract and explicitly say the gauge fills over time and by other means.
The *Storm 4* manual additionally says every performed substitution removes one
notch, and that both the round winner's and loser's substitution gauges refill
to maximum for the next round.

Bandai Namco's official *Storm Connections* 1.20 notes call recovery speed
varying with frame rate an issue, report fixing it, and separately shorten the
delay before recovery begins. Recovery rate and delay are therefore distinct
tunable behaviors, and a frame-rate-dependent refill is a defect, not series
behavior.

| Behavior | Confidence |
| --- | --- |
| Substitution has a separate gauge | Official |
| The gauge exposes a countable number of uses | Official |
| Each ordinary performance consumes one displayed notch | Official in *Storm 4* |
| Empty gauge prevents substitution | Official |
| Gauge recovers over time | Official |
| Later variants can recover it by another mechanism | Official, mechanism not numerically specified |
| A new *Storm 4* round refills both players to maximum | Official |
| Recovery should not vary with frame rate | Official fix in *Connections* |

## Measured numeric model

A detailed *Storm 4* mechanics guide reports values observed with the PC debug
application:

- the internal meter spans `0..100`;
- a substitution costs `25`, giving four stocks;
- every successful use restarts the automatic-recovery delay;
- the guide's switch-buffered free substitution also restarts that delay even
  though it does not spend a stock;
- automatic recovery waits about 14 seconds;
- after the delay, recovery continues stock by stock until full;
- receiving about `31.25` damage units grants one stock in the guide's
  normalized model; and
- the observed refill rate differed between 30 and 60 FPS builds: about one
  second per stock at 30 FPS and half a second at 60 FPS.

An empirical *Storm Generations* test, relevant because that game introduced
the stock system inherited by *Storm 3*, also reports four stocks, no spending
on an input that does not actually substitute, a roughly 14-second post-use
delay, continuous recovery to full, and recovery from damage. It is a
translated community test, so it corroborates the shape of the state machine
without making any exact number official. The same test reports that throw and
Ultimate Jutsu demonstration animations suspend game time, so real-world
recovery takes longer across those cinematics.

## Visual language

Official manual diagrams and battle screenshots show a consistent information
hierarchy across the later series:

- four immediately countable cells sit directly beneath the chakra bar;
- Player 1 and Player 2 layouts mirror one another;
- available cells are bright orange/gold;
- spent cells remain visible as a dark frame or background;
- recovery can be shown by a partial fill of the next cell; and
- a platform-specific substitution-input reminder may sit on the outer side.

*Storm 3* uses a connected segmented rail. Later games use four more distinct
capsules.

## Sources

- [Official *Naruto Shippuden: Ultimate Ninja Storm 3 Full Burst* PC manual](https://cdn.akamai.steamstatic.com/steam/apps/234670/manuals/NS3FB_PC_MANUAL_GBqs_HR.pdf), especially battle controls and HUD on page 8.
- [Official *Naruto Shippuden: Ultimate Ninja Storm Revolution* PC manual](https://cdn.steamstatic.com/steam/apps/272510/manuals/Naruto_Storm_Revolution_PC_manual_ENG.pdf?t=1580312767), battle gauge descriptions on pages 4-5.
- [Official *Naruto Shippuden: Ultimate Ninja Storm 4* PC manual](https://media-center.namcobandaigames.eu/manuals/nsuns4/game/pc/NSUNS4_PC_manual_GB.pdf), next-round state, battle HUD, and one-notch substitution cost on pages 12-16.
- [Official *Naruto x Boruto: Ultimate Ninja Storm Connections* 1.20 notes](https://en.bandainamcoent.eu/naruto/news/naruto-x-boruto-ultimate-ninja-storm-connections-patch-120-notes), official confirmation that frame-rate-dependent substitution recovery was a bug and that the pre-recovery delay is independently adjustable.
- [*Storm 4* mechanics and strategy guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2085597351), community debug-tool measurements for the `0..100` meter, cost, delay, refill, and damage recovery.
- [*Storm Generations* substitution-system test](https://gl.ali213.net/html/2012/27197.html), translated empirical predecessor evidence for stocks, delayed refill, and damage recovery.
- [*Storm Revolution* terminology guide](https://www.gamepressure.com/narutoninjastormrevolution/in-game-terminology/zf6b1f), secondary explanation of the segmented gauge and post-use recovery.
- [*Storm 3 Full Burst* HUD screenshot](https://www.konsolinet.fi/tuotekuvat/1200x1200/1289475-naruto-shippuden-ultimate-ninja-storm-3-full-burst-10_1.jpg), visual reference for the connected four-cell rail and mirrored layout.
- [*Storm Connections* HUD screenshot](https://primagames.com/wp-content/uploads/pcinvasion/2023/11/how-to-stop-enemy-attacks-in-naruto-ultimate-ninja-storm-connections-subtitution.jpg), visual reference for the later separated-cell presentation.
