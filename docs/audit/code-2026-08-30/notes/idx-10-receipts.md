# idx-10 · `index.html` 11060–12371 — Batch-13 surfaces & drill-down receipts

Read line by line, 11060–12371 (1,312 lines). Call sites judged outside the
range where needed: `vsShort`/`vsPhrase`/`bandName`/`pointsFor`/`floorSentence`
(5787–5990), `esc` (4123), `feedRow`/`postRow`/`rxChipsHtml` (4918, 10870),
`face`/`memberMarker`/`founderTag` (10731, 10844), `heroFloorFoot` (10362),
the stats loader (15175–15265), `loadCareer`/`loadTrophies` (17290–17355),
`loadStakes`/`stakeSettle` (17105–17165), `lockBody`/`unlockBody` (5562),
migration `20260729180000_round_card.sql`, and `v_rounds_ranked` /
`score_round()` in `00000000000000_initial_baseline.sql` (lines 679–690,
1352–1392).

## What this slice is

Four things, in order down the file:

1. **The Home stream** — `feedBuckets`, the quiet-day digest (`dg*`),
   `renderHomeFeed`, `renderUpNext`, `renderHomeRequests`, `renderPulse`,
   `renderHomeHub`.
2. **The Tour Card** — trophy case, career record, form row, recent rounds.
3. **The You table and its receipts** — `renderIndStats` (demo),
   `renderIndStatsReal` (real), `openMemberHist`, `roundCardBody`,
   `enrichRoundReceipt`, `openRoundReceipt`.
4. **The ceremony and the demo drill-down** — `csMoney`/`csSplitCents`/
   `csSettlement`/`openSeasonCeremony`, then `openSheet`/`closeSheet`,
   `showSquad`/`showSquadReal`/`showPlayer`/`showRound`.

## The headline: the receipt does not reconcile

`roundCardBody` (11930–11980) is the surface §16 exists for, and it is the one
place in the slice where the arithmetic is wrong rather than merely awkward.

* **The playing index is missing.** The card prints `index_at_post` under
  "Your number that day" (11955–11957) and then prints a PvI that the engine
  computed from `playing_index = round(index_at_post × handicap_allowance/100, 1)`
  (baseline:1359–1360). The default preset is **Standard = 95 %**
  (`[100,95,90][state.preset]`, 15657, `state.preset:1` at 3816), so on most
  leagues the two numbers on the card are 5 % apart and the subtraction the
  card invites gives a different answer than the card's own verdict.
  `round_card()` already returns `playing_index` (migration line 133). The
  render ignores it.
* **The differential line is written wrong.** 11953 emits
  `86 − 64.9 × 113 ⁄ 111` with no parentheses (precedence: 19.9, card says
  21.5) and, for a nine, drops the `× 2` the engine applies
  (`round(((gross − nine_rating) * 113.0 / slope) * 2, 1)`, baseline:681).
* **The verdict stutters.** 11962 now renders `vsShort(pvi)` *and*
  `bandName(pvi)`. Inside the played-to-it band the two are the same words —
  "played to it — PLAYED TO IT" — and the number the comment above it promises
  ("the number explains the phrase") is gone entirely.

## The sign sweep landed on the diorama, not on the league

Commit `2ae4d22` (Q-23) rewrote `renderIndStats` — the **demo** renderer — to
`vsShort`, and renamed the column header on **both** tables to "Avg vs your
number". `renderIndStatsReal`, the renderer every real league actually hits
(`if(!state.demo){ renderIndStatsReal(); return; }`, 11829), still prints
`sgn()`: 11882 `#msAvg`, 11883 `#msBest`, 11905 the table cell. Same for the
Tour Card's `#clAvg`/`#clBest` (11785–11786). The two real receipts one level
down — `openMemberHist` (11921) and `showSquadReal` (12295) — still say
"vs index" with a raw sign, the vocabulary D1 retired.

Net effect: the demo says "beat by 1.2"; the same column in the same build says
"+1.2" for a real golfer, under a header that was changed in the same commit.
The colour thresholds diverged too (`p.avg>-1` demo vs `p.avg>=0` real), so a
−0.5 average is green in the diorama and red in the league.

## Dates

`dgDay` (11136) is elapsed-hours arithmetic wearing calendar-day clothes:
`Math.round((Date.now() − dgTime(t)) / 864e5)`. A round played this morning
reads "Yesterday" from noon onward, and a round genuinely played yesterday
never reaches the "Yesterday" branch at all (it is already ≥ 1.5 days by the
time anyone looks). `feedBuckets` two functions above does it correctly, off
local midnights.

`renderHomeFeed` (11255) slices a `timestamptz` to ten characters and hands
the result to `localDate` — the documented UTC-midnight landmine applied to
`created_at` rather than `played_on`. Phoenix is UTC−7, so anything posted
after 5 pm carries tomorrow's UTC date and sits in the wrong bucket for a day.

## Money and ceremony

`csMoney` / `csSplitCents` are correct (remainder rides the early seats, parts
sum to the whole) and `openSeasonCeremony`'s "Unclaimed" guard genuinely keeps
§16. The soft spot is `owing` (12138–12140): it names debtors from
`window.buyIns`, a map built at 15058 from a read whose `{ error }` is dropped.
An empty map is indistinguishable from "nobody paid", and the ceremony then
prints every member of the league under "Still owed to the pot".

## Smaller things

* `_trophySeen` (11668–11695) latches on the **boot** render, which runs at
  13426 with `state.demo === true`. Every real trophy therefore counts as a
  fresh arrival on the first data render and replays the gold-needle engrave.
* `enrichRoundReceipt` writes into `#rcptBody` / `#shTitle` / `#shSub` with no
  check that the open sheet is still the one it was launched for.
* `showSquadReal` derives the ledger as `t.pts − Σ indRows.pts`; when the stats
  read fails (swallowed at 15259) that reads as "the whole squad total came
  from bonuses".
* `m.e` at 11213 is the only unescaped interpolation in the digest, and it is
  a client-written column (`post_kudos.emoji`, constrained only to ≤ 8 chars).
  `rxChipsHtml` escapes the same value.
* `renderIndStatsReal` explains an empty Most Improved tile as "needs 2+
  rounds" (11895) even when the real reason is that nobody's index went down.
* `renderPulse`'s live path (11449–11456) prints the floor sentence with no
  season-state gate; the SX-01 guard that added one lives on the branch below
  it that can no longer be reached. D122 fixed the neighbouring "Month closes"
  chip for exactly this reason in this same session.
* `homeRoundCard` / `renderHomeRounds` / `fillHomeWeather` (11302–11352) are
  unreachable — `#homeRounds` and `#homeRoundsHead` do not exist in the
  markup. ~50 lines, including a `weather` edge-function call and the slice's
  only bare classic→module reference (`fmtTee`, defined at 17567).
* The digest thumbnail (11226) is `aria-hidden="true"`, not focusable, and
  carries the only handler that opens that receipt.

## Checked and found clean

`csSplitCents` remainder distribution · `formRowHtml` streak/skew handling
(`'beat' in r`) · `renderLRW`'s next-Saturday date maths (Saturday correctly
rolls to +7) · `achSubtitle` year slicing · `emptyState` escaping ·
`openSheet`/`closeSheet` body-lock (guarded by `anyOverlayOpen`) ·
`dgMentions` (`window.homeRx` is initialised whole at 10752) ·
`renderRequestsInto`'s `friend_respond` call (destructures `{error}`) ·
the delete-round handler (destructures `{error}`) · the `#awImp` index-delta
direction (`▼` for a falling index is right) · `esc()` on every other
user-sourced field in the slice.
