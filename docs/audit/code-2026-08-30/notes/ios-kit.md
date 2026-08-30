
# Slice — `apps/ios/Packages/CupSeasonKit/Sources/` (the shared logic package)

Auditor pass, 2026-08-30. Read line by line: `Board/CSBands.swift`, `Dates.swift`,
`League/LeagueDates.swift`, `League/StandingsMath.swift` (incl. `ClimbMath`,
`ScenarioLine`), `League/PotMath.swift`, `League/LeagueCopy.swift`,
`League/WeekClash.swift`, `League/CupFinalRace.swift`, `League/LeagueRoomRows.swift`
(Settings), `Post/PostCard.swift` (`PostCalc`, `PostSeasonRule`, `PostPars`,
`PostStrip`, `PostScan`), `Post/PostEpilogue.swift`, `Post/PostService.swift`,
`Rounds/RoundCopy.swift`, `Rounds/ReceiptSeed.swift`, `Models.swift` (`SeasonPhase`,
`HomeMode`, `CSCopy`), `Wizard/WizardState.swift`, `Wizard/WizardService.swift`,
`Live/LiveEngines.swift`, `Live/LiveModels.swift`, `Live/LiveResult.swift` (tail),
`Live/LiveRehydrate.swift`, `Schedule/ScheduleModels.swift`, `Events/EventMath.swift`,
`Home/HomeDigest.swift`, `You/SeasonStats.swift`, `You/Career.swift`,
`AuthRules.swift`, `Config.swift`, `Founding.swift`, `SupabaseService.swift`,
`Telemetry.swift`. Cross-checked against `index.html` (the same functions the
headers cite), `tests/preflight.mjs` check 20, `tests/db-checks.sql` check 17, and
live prod SQL (`cup_points`, `v_rounds_ranked`, `score_round`, `daily_season_tick`,
`settle_week_clash`, `seasons` defaults, `rounds` check constraints) via
`supabase db query --linked`.

## The shape of what I found

The engines are in good order. `LiveEngines` matches the web function for function
(match, wolf incl. the comeback rule and the recursion bound, skins carry/death,
Sunningdale two-side and solo incl. the single-owner bank walk, round robin,
`settleTransfers`' termination, `strokeOn`'s wrap, `jsRound`'s floor(v+0.5)).
`CSBands.cupPoints` is byte-identical to prod's `cup_points`. `EventMath.evHalf` /
`nthUp` / the clinch arithmetic are right. `CSDate`/`LeagueDates` genuinely avoid the
UTC-midnight landmine — every path goes through parts, never an ISO parser. Nothing
in the package fabricates a points figure it then presents as authoritative.

The damage is concentrated in one place: **this session fixed four things on the web
(Q-20 bands, Q-22 blank rating, Q-23 no-sign vocabulary, D122 season note) and only
one and a half of them reached the phone.** Every one of those four was written up in
the blind audit as "the same fact stated two different ways", so a half-landed fix
does not halve the problem — it relocates it to the seam between the two clients.

## The findings, in order

### 1 · A blank rating still scores on the phone (Q-22 landed web-only) — P1

`Post/PostCard.swift:199-222`. `PostCalc.preview` reads `card.ratingValue` (0 when the
box is blank) and divides by a slope it silently defaults to 113:

```swift
let rating = card.ratingValue
let slope = card.slopeValue > 0 ? Double(card.slopeValue) : 113
let diff = (Double(gross) - rating) * 113 / slope
```

Type 45 and 46 with no tee picked: diff = 91, vs = 18 − 91 = −73, `cupPoints(-73)` = 5.
The composer shows "91 · 18 holes", the chips read "5 pts · PIGL" and "-73.0 vs your
index", and Post stays live. `PostPayload.build` then sends `rating: 0, slope: 0`;
`score_round()` divides by that slope and the round dies at the database
("division by zero", or `rounds_slope_sane`), surfacing as an opaque
"Post failed. …". The web fixed exactly this on 2026-08-29:

```js
if((f9>0 || b9>0) && (!(rating>0) || !(slope>0))){
  $('#calcMsg').textContent='Pick a tee — or type the rating and slope — to see the points.';
  state.lastPost=null; return;
}
```
with the comment "a 91 with no tee picked previewed '-75.8 vs your index · 5 pts' and
Post stayed live". That is the phone's current behaviour, verbatim.

### 2 · The receipt still uses the pre-Q-20 band ladder — P1

`Rounds/RoundCopy.swift:28-34` is a **second** Swift band producer that Q-20 did not
touch:

```swift
public static func bandName(_ vs: Double) -> String {
  ...
  if vs >= -1 { return "Played to it" }
```

`Rounds/ReceiptSeed.swift:142` is its only real caller — and it is the round receipt,
the §16 "shows its work" surface. A round at exactly pvi −1.0 renders
"−1.0 — PLAYED TO IT" beside the server's **6** points, while the same round in the
board card and the epilogue (`CSBands.bandName`, now `> -1`) reads "A LITTLE LOOSE".
`RoundCopy.pointsFor(-1.0)` returns **7** — one point more than `cup_points(-1.0)` and
than `CSBands.cupPoints(-1.0)` — and `Tests/…/RoundsYouTests.swift:71,77,93` pin the
old rule, so the suite will keep the divergence alive. (`pointsFor` has no non-test
caller, which is the only reason the 7 does not reach a screen.)

### 3 · The clash's band changes when the tick settles it — P1

`League/WeekClash.swift:73` computes the mid-week best with the corrected ladder
(`band: top.pvi.map(CSBands.bandName)`). The settle that replaces it,
`supabase/migrations/20260829091000_weekly_clash.sql:263,279`, carries a **third**
inline copy still on the old rule:

```sql
when rr.pvi >= -1 then 'Played to it'
```

Same round, pvi −1.0: the phone's clash card says "A little loose" on Thursday and
"Played to it" on Monday after `settle_week_clash` writes `a_best`. `db-checks` 17
only pins `cup_points`, so nothing catches it.

### 4 · A cup_final league under six weeks: the bylaws say points table, the engine runs a Cup Final — P1

`Wizard/WizardState.swift:236` sets `canCup = cup && d.durWeeks >= 6` and line 250
renders "4 wk · POINTS TABLE" in the portrait; `League/LeagueCopy.swift:127-131` writes
"FINISH · Points table crowns it · whole season, one race" for the same league. But
`WizardLockPayload` (`WizardState.swift:303`) writes `finish = d.finish` = `"cup_final"`
regardless, and prod's `daily_season_tick` has no minimum-length guard:

```sql
if se.status = 'active' and coalesce(v_finish,'cup_final') = 'cup_final'
   and current_date >= se.ends_on - 27 then perform enter_cup_final(se.id); end if;
```

`WizardDials.durs` offers 2, 3, 4 and 5 weeks. Pick 4 weeks (ends_on = start + 28) and
the tick flips the season to `cup_final` on day **two** — `RoomClock.isCupFinal` then
reads true from `status`, the room header says "Cup Final", `phaseSub` says
"CUP FINAL · Wk 1 / 4 · fresh slate", and `close_season` crowns and pays the pot by the
Cup path. The bylaws card promised the opposite. Both clients share the copy half; the
phone is the one that also writes the payload.

### 5 · Two total-weeks formulas on one phone — P2

`Models.swift:185` (`SeasonPhase.of`):

```swift
let total = max(1, ((CSDate.days(from: s.starts_on, to: s.ends_on) ?? 0) + 1 + 6) / 7)
```

vs `LeagueDates.totalWeeks` (and the web's `totalWeeks()`), which is
`max(1, ceil(days/7))` with no `+1`. They differ by exactly one whenever `days % 7 == 0`
— which is *every* season this app creates: `seasonEndDate()` is `start + durWeeks*7`
and `lock_league` defaults `ends_on = current_date + 182`. A stock 26-week league shows
"PIGL · week 4 of **27**" in the Home eyebrow (`HomeView.swift:532`) and
"Wk 4 / **26**" in the league room. On the final day it reads "week 27 of 27".

### 6 · `insertHoles` swallows the error completely — P2

`Post/PostService.swift:91-94`:

```swift
public func insertHoles(_ rows: [PostHoleRow]) async {
  guard !rows.isEmpty else { return }
  _ = try? await db.from("round_holes").insert(rows).execute()
}
```

Best-effort is the right policy (the web's is too), but the web *tells* somebody:

```js
if(eh){ qaEvent('round_holes_fail', {…}); toast("Round posted — hole detail didn't save"); }
```

The phone has no breadcrumb, no toast, and no return value to check. An RLS or
constraint failure on `round_holes` means the golfer's hole-by-hole card is gone,
the scorecard strip is empty forever, and nothing anywhere records that it happened.
`round_holes` is one of the four paths named in CLAUDE.md's 2026-08-28 silent-write
sweep.

### 7 · Q-23's no-sign vocabulary never reached the phone — P2

The web replaced signed PvI with words in four places this session (`vsShort`):
`#calcVs` (6626), `#msAvg` (11841), the individual-race avg column (11858) and the
receipt row (11962), because "six of seven blind testers misread it, and the same round
appeared as '-3.7', '3.7 over' and '+0.0' on three consecutive screens". The phone's
producers still emit the sign:

- `Post/PostCard.swift:185` — `vsText` → `PostRoundScreen.swift:402` renders
  `"+2.4 vs your index"` (and the jargon D1/D2 forbids).
- `You/SeasonStats.swift:36-37`, `You/Career.swift:42`, `You/TourCard.swift:107` —
  `RoundCopy.signed`.
- `League/StandingsMath.swift:266` — `sgn`, used by `IndividualRaceView.swift:79` and
  `ReceiptSheets.swift:57`.
- `Rounds/ReceiptSeed.swift:144` — `"\(pvi >= 0 ? "+" : "")\(RoundCopy.f1(pvi))"`.

The web also moved the colour threshold to `vs > -1` (pos/neg); the phone still splits
at `>= 0` (`PostRoundScreen.swift:402`), so a −0.4 round is red on the phone and green
on the web.

### 8 · D122 stopped at the ceremony; the composer still promises points — P2

The session added `PostSeasonRule.note` and wired it into `PostCeremony` (the sheet
*after* the post). The web wired the same fact into the composer, where the promise is
actually made:

```js
if(_k) _k.textContent = _ss === 'live' ? 'League points this round' : 'This round';
$('#calcPts').textContent = _ss === 'live' ? pts : '—';
```

`PostPreview` carries no season awareness, so `PostRoundScreen.pointsText` (line 421)
returns `"\(p.points) pts · \(name)"` whenever a membership exists. A golfer a week
before first tee is still told "9 pts · PIGL" and then shown zero — the exact sequence
D122 was written to end, on the exact screen D122 measured it on.

### 9 · `PostSeasonRule.note` announces a season is over while it is running — P2

`Post/PostCard.swift:449`:

```swift
let st: LeagueCopy.Stage = played < s.starts_on ? .preseason : .complete
```

The branch is chosen from the ROUND's date, but the sentence it selects speaks about the
SEASON. Back-date a round to before first tee mid-season and the phone says "Practice —
the season **starts** Sat Sep 5" about a season that started five weeks ago; date one
past `ends_on` and it says "The season is over" while the season is live. (The rule
itself — window-only, ignoring `seasons.status` — is correct: `v_rounds_ranked` admits
`active`/`cup_final`/`complete`, so a window hit always scores. The web's stage-based
`seasonNote()` is the one that gets that wrong for a complete season.)

### 10 · `AuthRules.human` is applied far outside auth — P2

`AuthRules.swift:45-72` maps `"expired"`, `"403"`, `"deleted"`, `"otp"`, `"banned"` to
sign-in sentences. It is called from `SessionStore.swift:100`,
`LeagueRoomModel.swift:225`, `PushService.swift:92`, `ProfileRepository`/
`CardAndSettingsScreen`/`FeedbackSheet`. A refresh-token expiry during a league-room
load renders "That code has expired. Codes expire when a new one is sent — use the
newest email." on a screen with no code on it; any error text containing "403" or
"deleted" renders "This account was closed and can't sign in again. Start fresh with a
different email." to a golfer whose account is fine.

### 11 · D129's payment terms are web-only — P2 (opportunity)

`20260830040000_buy_in_terms.sql` adds `buy_in_note` / `buy_in_due_on` and
`set_buy_in_terms`; the web reads them off `CS.settings` and shows them on the Pot tab.
`League/LeagueRoomRows.swift:30-56` (`LeagueRoom.Settings`) does not declare either
column and `LeagueRoomModel.swift:182` selects an explicit list without them. A Pro sets
"Venmo @casey · in by Sep 30" on the desk and every iOS member sees a pot with no
instruction for paying it. D126's `endgameLine()` has the same shape of gap — a new web
producer with no Swift twin.

### 12 · Smaller things, verified but low value

- `PotMath.jsRound` is `Int(v.rounded())` (away from zero); `LiveEngines.jsRound` is
  `Int((v + 0.5).rounded(.down))` (JS-exact). Two helpers, one name, one package,
  different answers at negative halves.
- `ClashMath.bestSoFar` reads a missing `month_rank` as **counting** (`?? 1`);
  `StandingsMath.indRows` reads it as **not** (`?? Int.max`).
- `CSCopy.ordinal(-1)` indexes `["th","st","nd","rd"]` at −1 and traps. No caller passes
  a negative today (`ClimbMath.ordinal(i + 1)`, `i >= 0`).
- Q-27's `floorSentence()` — the web's new single producer for the floor rule — has no
  Swift twin. The phone still states the penalty from `Bylaws.penalty[presetIdx]`, so a
  **solo** league's bylaws row reads "2 / mo · −5 sqd pts / round short" with no squad to
  dock, and nothing mentions the bye that covers the first miss or the short-month waiver.
- `WizardService.lock` still performs the four-write lock under RLS even though
  `Rpc.lock_league` is in the generated snapshot (`Rpc.swift:898`) and D111 built the
  atomic, `already_locked`-reporting RPC precisely because "the lock stops lying". The
  step-(1) `update` also matches zero rows silently if `league_settings` has no row.

## What I could not assess

- Whether `LiveRoundState.scores.count` can ever drift from `players.count` at runtime.
  Every path I read guards it (`LiveRehydrate.overlay` line 160, `LiveEngines` bounds
  checks), but `netParThru` and `LiveResult.sunningdaleSolo` index the *other* array
  unguarded, so the invariant is load-bearing and undeclared.
- Swift's `sorted(by:)` is not stable where JS's is; `StandingsMath.awards`'s movers list
  and `LiveResult.sunningdaleSolo`'s `order` can list tied players in a different order
  than the web. Cosmetic, unverified against a real tie.
- The views under `apps/ios/CupSeason/` are outside this slice; I cited them only as
  evidence that a Kit producer reaches a screen.
