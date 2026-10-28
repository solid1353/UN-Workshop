# Dialogue localization

## Research coverage

Established: the five resident NA2 ELF dialogue strings are movie subtitle
captions, their exact UN5 English homologs, the screen that shows them and
how it is reached.
Open: nothing. Names come from `@annotations/NA2` and `@annotations/UN5`;
addresses are live.

Established source and donor relationships belong to
[NA2 and UN5 text correspondence](text_correspondence.md).

## Movie captions

The five locations in retail NA2 `SLPS_258.37` are CP932 captions in the
resident movie subtitle schedules. Each caption is a row of both
`movie_subtitles_da2200` (movie 3, `DA2200.PSS`) and `movie_subtitles_da3250`
(movie 8, `DA3250.PSS`), at the same frames in both. UN5 keeps the same
schedules with the same frames in its language overlays; English
`TEXTENG.BIN` holds them at `movie_subtitles_da2200_eng` (`0x00924580`) and
`movie_subtitles_da3250_eng` (`0x00924830`), and `movie_subtitles_da2200_row`
(`SLES_556.05 0x003D3620`) picks the language's schedule through
`movie_subtitles_da2200_by_language` (`0x005BB110`).

| NA2 label | Live address | NA2 text | DA2200 / DA3250 row | UN5 English (`TEXTENG.BIN`) |
| --- | ---: | --- | --- | --- |
| `dialogue_candidate_a` | `0x003FFC40` | ナルト……それにサクラか……。 | 0 / 1 | `Naruto... and Sakura...` (`0x0091C690`) |
| `dialogue_candidate_b` | `0x003FFC58` | ……。 | none | none |
| `dialogue_candidate_c` | `0x003FFC80` | やっと……`<ruby見\|み>`つけたってばよ……。 | 2 / 3 | `Finally... I found you!` (`0x0091C6C0`) |
| `dialogue_candidate_d` | `0x003FFCB0` | サスケ…。 | 3 / 4 | `Sasuke...` (`0x0091C6D8`) |
| `dialogue_candidate_e` | `0x003FFCC0` | …サスケ……くん。 | 4 / 5 | `S--Sasuke...` (`0x0091C6E8`) |

`dialogue_candidate_b` is the tail of `dialogue_candidate_a`; no schedule row
or other reference points at it, so it is not a caption of its own. The row
between `a` and `c`, その声は…。 at `0x003FFC60`, is UN5's `That voice...`.

`movie_update_subtitles` draws these captions near the bottom of the frame
while the movie plays
([Audio and video replacement](../game/files/audio_video_replacement.md#descriptor-authored-geometry-transitions-and-subtitles)).
The Collection's Movie viewer plays both movies: Collection, then Movie, then
the first entry (`DA2200`) or the sixth (`DA3250`). The viewer plays an entry
only when its saved Movie byte is at least 2
([Movie list state](../game/content_availability.md#movie-list-state)).
`profile_grouped_reset` clears all seven Movie bytes to 0, and a fully
unlocked profile holds 3 for the first and `0xFF` for the rest
([Stored availability fields](../game/content_availability.md#stored-availability-fields)).
In the resident image, `BTL.BIN` and `ETC.BIN`, the grouped-content store
(`profile_grouped_store`) writes Movie bytes only from that reset, from
`profile_secondary_restore` through `overlay_abi_target_001f7090`, and from
`collection_movie_confirm`, which marks an already owned entry viewed. None
of them grants a Movie, so both captions show only from a profile whose
Movie bytes were set elsewhere.
