# Verify SP-8 · lens "reproduces-at-tip" · tip 3bba87e · 2026-09-04

**Verdict: HOLDS.** The shipping phone client (and the web) prints the vocabulary the statement claims. Every cited site was opened; 14/14 "card" sites, 5/5 PotPane sites, all D120-leftover sites, all engine-word sites and all six week formulas reproduce verbatim. A handful of line numbers drifted and one headline string ("COUNTS ON YOUR CARD") is now a D122-gated fallback rather than the primary verdict — corrections below.

## 1 · League vs season as grammar — REPRODUCES
- `WizardState.swift:462` `startLeague = "Start a league"` → rendered `LeaguelessDoors.swift:29`.
- `WizardState.swift:394` `("Season length", "Weeks or months · ends the same weekday")` (statement says :393 — drift).
- `StandingsPane.swift:140` `"Run it back — Season 2"`; `LeagueRecord.swift:20` `"SEASON \(roman(number)) · …"`.
- `IndividualRaceView.swift:43` `"The race fills in once your league season is live and rounds land."`
- `OrientationScreen.swift:55` `title: "A league", sub: "Months. Every round counts toward a table."`
- Web: "Start a league" ×12, "Season length" ×1, "Run it back" ×6.

## 2 · "The Pro" undefined at first contact — REPRODUCES (one creator-only definition exists)
- `LeagueRoomScreen.swift:183` `"\(spanText) · THE PRO · \(proName)"` — no gloss. `MembersSheet.swift:67` `"THE PRO"` chip. `StandingsPane.swift:36` `"THE PRO"` trail on the checklist.
- `HomeHeroCopy.swift:231` `"You still owe … · ask the Pro how to pay — money moves between you"` — literal "the Pro", although the name IS on the membership (`MembershipCard.swift:76` reads `m.commissioner_name`). Producer bypass, not a data gap.
- `OrientationScreen.swift` — zero "Pro" strings. Covenant rows `JoinLeagueFlow.swift:135-138` = BUY-IN · PRESET · PARTICIPATION FLOOR · FINISH — no WHO row.
- "runs the league": 0 hits in `apps/ios` and `index.html`. Web `index.html:3629,:14649` `'THE PRO · '+proName` — same shape.
- The ONLY definition: `WizardState.swift:369-370` `proLabel = "Pro — that's you"`, `proSub = "you run this league"` — seen by the creator alone.
- `spec/decision-log.md:4353-4363` D132 = DECIDED "defined at first contact (orientation, covenant WHO row, Clubhouse chip)"; none of the three is built.

## 3 · "Card" in many senses — REPRODUCES (14/14 sites verbatim)
Profile: `CardGateView.swift:46`, `HomeView.swift:875` `"Your card"`. Record: `PostCoverView.swift:100` `"counts on your card and in every league"`, `LeagueCopy.swift:210` `"this round lands on your card"`, `:222`, `:223` `"On your card"`, `:271` `"PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON"`, `:356`, `WizardState.swift:465` `"Post a round — it counts on your card"`, `PostRoundScreen.swift:436`, `PostHoleGrid.swift:297`, `LeagueRoomScreen.swift:243`, `HomeStream.swift:167` `"First round on the card"`, `YouSections.swift:164`, `GuideCopy.swift:70`, `LiveClaim.swift:115,118`, `LiveRoundStore.swift:695`, `PostEpilogue.swift:50-51` `"Pinned to your card"` → ≥16 record-sense. Scorecard: `PostRoundScreen.swift:226` `"Your card"`, `:272` `"Enter your card"`, `PostHoleGrid.swift:296` `"YOU HAVEN'T ENTERED YOUR CARD YET"`, `LiveSetupView.swift:594` `"Course card"`, `LiveModels.swift:257` `"Card loaded"`. Artifact: `PostEpilogue.swift:167` `"Share the card"`. Major: `MajorRoomView.swift:110,135` `"No card"` / `"Yet to card"`.
- `decision-log.md:4343-4351` D131 assigned card = the golfer card only, record sense retires ("posts to your rounds") — NOT built.
- **Nuance:** `PostEpilogue.swift:163` `"COUNTS ON YOUR CARD"` is the fallback of `PostCeremony.pointsLine` (`:159-166`). The only production caller `PostRoundModel.swift:247-251` always passes `seasonNote: PostSeasonRule.note(...)` (`PostCard.swift:481-493`), so at tip the verdict prints `"ON YOUR CARD"` (no league), `"PRACTICE · SEASON STARTS SAT SEP 5"` (pre-tee) or `"SEASON COMPLETE"` (D122 built). The literal string is reachable only when the round counts but `preview.points` is nil/0 (rating-less post). The collision (verdict says "card") persists; the "every prior tester read it as counted" sentence is the prior audit's finding quoted in D131, not re-observed at tip.

## 4 · "Stake"/"on the books" opposite senses; "tee sheet" two senses — REPRODUCES
- `PotPane.swift:133` `"The other stakes · pride, on the books"` / `"Post a stake"`; `:189` `"Post a stake" · "Pride, on the books — never money"`; `:210` `"Put it on the books"`; `:223` `"Stakes settle … The pot stays money; this never is."`; `:263` `"Settle the stake"`. vs `HomeHeroCopy.swift:196-200` footMoney ("The books open at lock" — money) and `LiveModels.swift:73-75` `"Stake per side · $0 = bragging rights"` (money). The code noun is already `forfeit` (`router.open(.forfeitCreate)` at :133) — D131 unbuilt on the face.
- Tee sheet = calendar: `ScheduleScreen.swift:38` `"Tap any day to put a round on the tee sheet."`, `:40` `"Put a round on the tee sheet"`, `:80` `"ON THE TEE SHEET"`. Tee sheet = live scorer: `LiveSetupView.swift:67-68` `"On your tee sheet today"` / `"Load the course and your group into the tee sheet"`, `LiveCopy.swift:256` `"on the sheet · synced"`, `:271` `"You're on a live tee sheet"`, `LiveRehydrate.swift:231,275` `"put you on the tee sheet"`. Phone 54 non-test lines (incl. comments) / web 36 lines.

## 5 · Engine words reach users — REPRODUCES
- `LeagueCopy.swift:133-139` bylaw rows: `"STRUCTURE"`, `"Squad formation"`, `"PRESET"`, `"HANDICAP ALLOWANCE" "\(allow)%"`, `"VERIFICATION"`, `"COUNTING CAP" "\(capLabel) / mo"`, `"PARTICIPATION FLOOR" "\(floor) / mo · \(penalty)"`; `:151` `"… · scored fresh"`. Unconditional — the row is the `league_settings` key.
- `WizardState.swift:70` `"95% hcp · post what you'd post to GHIN · best 3 / mo count · 2-round floor"`, `:76` `"Standard: 95% handicap … post 2 or the squad feels it."` (statement's `:101-107` is the `Bylaws.init` — drift). `:387` presetHelp "handicap allowance … attested where you can; the Pro rules on the rest".
- `StandingsMath.swift:331,334` `"CUT LINE"`, `:421` `"EVERYONE ADVANCES — N CONTENDER(S), K SEAT(S)"`, `:433,458` `"SEEDS LOCKED" — … INTO THE CUP FINAL` (statement's `:361-469` — drift).
- "Attested": phone quoted 3 (`ReceiptSeed.swift:207` `"Attested"`, `LeagueCopy.swift:24` `"Attested where you can; the Pro rules on the rest"`, `LiveFinishViews.swift:75` `"✓ ATTESTED"`) + lowercase `WizardState.swift:387`; web 3 — "×8" ≈ both clients combined.
- Bare "vs index": `IndividualRaceView.swift:52` `"Avg vs index"`, `:78` `"· VS INDEX"`; `ReceiptSheets.swift:57` `"AVG vs index …"`, `:111` `"\(sgn(pvi)) vs index · \(points) PTS"`.
- Endgame `LeagueCopy.swift:413`: `"\(who) seed into a four-week Cup Final … — scored fresh, so the regular season sets the seeds, not the winner. The leader carries +10 in. …"` verbatim.

## 6 · D120 leftovers and squad-on-solo — REPRODUCES (partially gated)
- `StandingsPane.swift:54` `PhaseHero(k: "Squads are forming", n: "The Pro has the list.")`; `LeagueCopy.swift:263` `"LIVE NOW — CAPTAINS READY"`; `:271` `"… · SQUADS LOCKED · …"`; `:233` `"SETUP · LOCK THE BYLAWS TO OPEN INVITES"`; `:249,255` `"\(short) SEAT(S) OPEN"`. Web `index.html:3676` `The Pro has the list.`, `:13916` `SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD`, `:13922` `'LIVE NOW — CAPTAINS READY'`.
- Solo: `StandingsPane.swift:41` checklist `"Squad formation"` (no structure check); `LeagueCopy.swift:134` bylaw row (`bylawsRows` has no `solo` param); `:269-272` `kickoff(_:)` has no `solo` param → `"SQUADS LOCKED"` on a solo league; `IndividualRaceView.swift:99` `"… run in parallel with the squad race"` unconditional. BUT `LeagueCopy` already gates three neighbours on `solo` (`:259-260 squadsSub`, `:374-375 standingsEmpty` `"INDIVIDUAL RACE — NO SQUADS."`, `:407` `"The top 2 golfers"`) — the gate exists and four sites bypass it.

## 7 · One fact, many producers — REPRODUCES
- Week: `00000000000000_initial_baseline.sql:739-750` `snapshot_week` → `wk := least(total, floor((current_date - starts_on)/7.0))` (no +1; returns if today ≤ start); `20260902170000:79-80` `v_wk := floor((v_local - starts_on)/7)::int + 1`; `index.html:8111` `floor(round((today-s)/864e5)/7)` (no +1); `:11305` `floor(...)+1` clamped; `:11263` `wksLeft = ceil(...)`; `LeagueDates.swift:37-41` `floor(since/7)+1` clamped. Six formulas; server and server disagree by one.
- PvI: `home_feed`'s last definition `20260723090000_home_feed_photo.sql:51` `round(index_at_post - differential, 1)` (100%); no later redefinition (`grep -il "function.*home_feed"` → 3 files, last 20260723). The phone still reads it: `HomeStream.swift:4,12` `HomeFeedRow = Rpc.home_feed.Row`. `v_rounds_ranked` `20260902100000:97-98` applies `handicap_allowance/100`. Two lenses live.
- Band names: live copies = `settle_week_clash` `20260902170000:369-371` and `:385-387` (two case blocks in one function), `CSBands.swift:43-47`, `GuideCopy.swift:144`, `index.html:6198-6200` (`bandOf`), `index.html:3460-3463` (guide table) → six live; the copies in `20260829091000/20260831120000/20260831130000/20260831160000` are superseded redefinitions of the same function.
- Standings nouns (phone quoted): "standings" 30, "the table" 13, "the race" 6, "the ladder" 2, "leaderboard" 2 (+ "the board" 32, mostly the Clubhouse board). Door: tab `MainTabView.swift:209` `"Post"`, cover `PostCoverView.swift:95` `"Play now — score the group"`, `:99` `"Post a round — after you play"`, `PostRoundScreen.swift:272` `"Enter your card"`.

## 8 · Lints — REPRODUCES ("producers without lints")
- `tests/preflight.mjs:635-655` check 20 = "the two clients share one stage vocabulary (D120)" — compares web `STAGE_LABEL` to Kit `Stage.label`. No lint mentions band/card/stake/tee sheet/Pro/squad (grep). `tests/db-checks.sql:393-405` check 17 = band boundaries web vs `cup_points`. Nothing else gates vocabulary.

## Corrections to the statement/evidence
1. Line drift: `WizardState.swift:393`→`:394`; "95% hcp" is `WizardState.swift:70` and `:76` (not `:101-107`); `StandingsMath.swift:361-469`→`:331-334, :416-421, :433, :458`; "Attested ×8" → 3 phone strings (+1 lowercase) + 3 web.
2. "COUNTS ON YOUR CARD" is a D122-gated fallback (`PostEpilogue.swift:159-166`; caller `PostRoundModel.swift:251`); the shipping verdicts are `"ON YOUR CARD"` / `"PRACTICE · SEASON STARTS …"` / `"SEASON COMPLETE"`. Cite `LeagueCopy.swift:223` as the record-sense verdict and mark the "every prior tester" sentence as the prior audit's (D131 text), not re-observed.
3. The Pro IS defined once — for the creator only (`WizardState.swift:369-370`); say "undefined at every member first contact". Add: the name is on `Me.Membership.commissioner_name` and `HomeHeroCopy.owe` (`:231`) ignores it — a producer bypass.
4. Squad-on-solo: `LeagueCopy` gates three strings on `solo` (`:259-260, :374-375, :407`) while four sites bypass — sharpen the root cause to "the gate exists and is bypassed" (D201's rule).
5. Band copies: "six live copies" (list above); "seven" counts a superseded migration.
6. "tee sheet" counts: 54 non-test phone lines / 36 web (grep -i, comments included); the statement's 18/27 are string counts — the dual sense stands either way.
7. Strengthen PvI evidence: `HomeStream.swift:12` binds the phone Home feed to `home_feed` (100% lens) while standings use `v_rounds_ranked` (allowance lens); `20260902180000_one_lens_on_the_tour_card` fixed the tour card only.
8. Web SEEDS LOCKED = 0 hits (phone-only string); web has CUT LINE ×3, HANDICAP ALLOWANCE ×1, COUNTING CAP ×1, PARTICIPATION FLOOR ×2, "on the books" ×13, "the Pro" ×56.
