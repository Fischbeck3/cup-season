# Verify · SP-2 · lens "is-it-structural"

Repo `/Users/fischbeck3/cup-season` at tip `3bba87e`, 2026-09-04, read-only. SAW = read in code or returned by a read-only prod query (`supabase db query --linked`); INFER marked.

## Verdict

**holds = false** under this lens. A Home-only change set (Home's own files plus the producers in `CupSeasonKit/Home`, one `HomeRoute` case, no tab, no server, no mechanic) answers the brief's five questions at the first Home for all six personas as far as the data can answer them; nothing a level-3 (IA) change would add is missing for any of A–F. What is left after that fix is (a) data-layer work that any Home design needs (level 4/6, not IA) and (b) one genuine IA question — one hero over one membership vs. a ranked NOW across memberships — that no persona in the walks exercises and that prod does not yet exhibit for a real user.

## 1 · The refutation: the single-screen fix ("SSF")

Everything below is reachable from Home with doors and reads that already exist on the phone.

| # | Change | Data / route already in hand (SAW) |
|---|---|---|
| S1 | A door per hero mode | rung 7 → `presenter.postOnComposer = true; presenter.showPost = true` (`Presenter.swift:17,20`; Home already does it for the clash/floor faces, `HomeView.swift:162-169`). Rung 6/5 → `HomeRoute.people` (exists, `MainTabView.swift:159`) or the wizard (`presenter.wizard`, `Presenter.swift:30-31`, which documents `initialStep: 2` = "Lock it in"). Forming/Pro → wizard step 2; draft/Pro → `presenter.draft` (`:32`). Forming/member → `ClubhouseView(leagueId:, pane: .league)` (the `pane:` parameter is used for `.pot` at `MainTabView.swift:163`). Preseason → `presenter.declare` (`:27`) or the composer. Wrapped → the CUP table (STANDINGS is already the final table, D139) plus `presenter.runBack` (`:33`); solo champion via `season.champion_member_id == m.member_id` (`Models.swift:50`, unread by `HomeView.swift:869,980`). |
| S2 | A persistent "Add my round" on Home | the same two presenter flags. |
| S3 | A ME strip: my number · my last round · my next round | `profile.index_current` (`Models.swift:18`); my last round is already on the page as the feed's `is_me` row with gross/pvi/course/date (`HomeStream.swift:170`, `HomeView.swift:520-530`); my next round is already the "NEXT ROUND · Mon Sep 7 · Gold Canyon with Galen" chip (`UpNextChips`, D219). |
| S4 | The foot to one line | copy; the endgame's first clause stays visible (L-17), the full sentence one tap away. |
| S5 | The pool keeps a wrapped league for N days; the row names the winner and is a door to the CUP table, not a lens switch | `HomeMode.pool` (`Models.swift:300-303`) is a Home default; `season.champion_*` on the payload. |
| S6 | An event face/rung | `me.events` / `me.open_duels` are decoded (`Models.swift:233-234`) and the phone HAS the room: `RyderRoomView.swift`, `EventRoomModel.swift`, `presenter.event` (`Presenter.swift:37`). |
| S7 | Home's lead league = the most time-bound membership, keyed by Home, not by the Clubhouse pager | a default change (`HomeView.swift:39,45`; `ClubhouseView.swift:110-114`). |
| S8 | Name the man above me | the Kit already reads `v_individual_standings` (`LeagueRoomModel.swift:215`, `MeRepository.swift:95`) — but see L-24/CC-44 below: the honest version is the server's `next_up` (DL-07), which is data-layer work, not IA. |

### The persona walk against SSF (five questions at the first Home)

- **A (rung 7, no buddies).** Q1/Q2 copy on the rung-7 card; Q3 S1+S2 ("Add your first round"); Q4 "nobody yet" + the buddies door — no IA change can name a competitor for a golfer with none; Q5 copy ("three rounds make your number"). Answered.
- **B (wrapped, one league).** Q1 "Dew Sweepers wrapped · Priya took it" (S5); Q2/Q4 the 0–2 v Priya record (`my_rivalries` is already called on the phone, `ScheduleScreen.swift:303`, and is league-agnostic, CC-39); Q3 recap door + run-it-back (S1); Q5 "Season 2 is Marcus's call" (copy). Answered.
- **C (week 7, 3rd of 8).** Q1 already yes; Q2 "4 back of the cut" from `standing.gap_to_next` at rank K+1 (D130 rung 4, D24 wording); Q3 S2; Q4 S8; Q5 the week-close date is client-derivable (`LeagueDates`) and the Saturday chip exists. "The app didn't notice my round": S3 prints "Your 84 Saturday · 9 pts" from the `is_me` row; a per-device last-seen rank (D27's seen-mark precedent) gives "▲ up 1 since Saturday" without the Sunday snapshot. Answered.
- **D (rung 7, wants to run a season).** Q2/Q5 copy + an intent door on the card (S1); the wizard's shape is O-04's problem, not Home's. Answered at Home.
- **E (preseason, invited, $50 due).** Q3 S1's preseason door + S2; Q4 the roster on the card (`membership.members` count is on the payload; names need the server per CC-44); Q5 S4. Answered.
- **F (buddies, no league).** Q2/Q4 the rung-5 card the web already has (`index.html:11465-11474`) naming Dev/Tash; the record v Dev from `my_rivalries`; Q5 "Sunday with Tash — get on the tee sheet" (the RSVP exists in the scheduled-round sheet). Answered as far as any Home could.

No persona is left with a question that the structural fix in SP-2 (compose across memberships from `home_stories()`, level 3) would answer and SSF cannot.

## 2 · What SSF does not do — the residue, and its level

- **R1 · One hero over one membership** (D81/D94/D121, level 3). SSF keeps it. It only bites a multi-league golfer. None of A–F is one. Prod (SAW, 2026-09-04): 12 golfers are in any real non-setup league; exactly ONE is in 2+ real leagues (Fellas + Who's the bitch? — both live two-person solo leagues); the other ten "2+" profiles are members only of the four 2026-08-28 leagues (Fairway Society 5 members / Ridgeline Cup 8 / Sunset Match 6 / Winter Circuit 9), each with exactly one member who has ever signed in — seeded. Zero real golfers have a wrapped league beside a live one (the only complete league is Sandbox). So HM-26 and SV-28/29 describe no real user today, and the "11 of 17" figure in the SP-2 draft is a seeded artifact.
- **R2 · Server fields** — week producer, movement since my round, `next_up` name, `last_round_on`, last season (DL-05/06/07/27/31; DL B-6). Level 4/6. Any Home design needs them; they do not make the problem IA-level.
- **R3 · Events on Home** — a new cell/rung, Home-local (S6).

## 3 · The evidence is largely ruled-and-unbuilt, not structural (CC-30)

- D81 (`decision-log.md:2803-2838`) ruled the league-less ladder INCLUDING rung 5 ("four makes a league, you have six") and the complete hero "with run-it-back". The phone has neither (`Models.swift:309` — rung 7 or 6 only; `HomeView.swift:981` — a sentence, no door). The web has both (`index.html:11448-11474`, `:11251-11253` "Season recap →" + "Run it back — Season 2").
- D119 (`:4222-4231`) ruled "every cell with a move the viewer can make" — the phone's forming/preseason cells are sentences whose only door is STANDINGS (`HomeView.swift:803,839-842,950-968`).
- D130 rung 4 ("back of the last cup spot") and D128 (rules as a place, which relieves the hero foot) are unbuilt (CC-15, PA-021).
- D129's build note already put the money foot on Home by ruling; it is not a design accident.

## 4 · Immutable-law check on the statement (constraints, not blockers)

- **L-10 / D129 (level 4):** "a member's unpaid state is self-only on Home … fires from state, not a schedule." The evidence line "owe line every open (HM-08, HM-27, SV-10)" treats a level-4 ruling as a defect. A fix may restyle or relocate it within Home; it may not demote it to a once-per-condition card (that is D23's nudge shape; D129 says this is state).
- **L-17 / D126:** "the endgame is a sentence you can always see." The foot trim must keep the endgame visible on an always-present Home surface (or explicitly amend D126 (2) at UI level while keeping L-17). Shorten, do not delete.
- **L-24 / CC-44:** first names leave the app; a Home name is a server producer's (`firstname()`). S5/S8 must not split `display_name` on the client — so the WHO layer's names are honestly R2 (data-layer), not a client join.
- **L-13 / D123:** "carry the lens per row" is compatible (one PvI per round per league); D123's "open league" clause for one-league surfaces needs restating (CC-13). Note: D123's server half is unbuilt — `home_feed(p_days: 21)` takes no league (`HomeStream.swift:125`) — so Home's feed scores at 100% today and removing the open-league premise changes nothing today.
- **L-22 / D63 (CC-39):** the statement's "streak" must be worded as a moment (L-42: mark > barrier > PB > streak) never as "you haven't" or streak-shame.
- **L-25:** gold earned only — the solo-champion fix must read `champion_member_id`.
- **O-08:** SSF keeps one lane and the feed whole; it is not D94's rejected layout A.

## 5 · Corrections to the statement and evidence

1. "events do not exist" → "Home never reads `me.events`/`open_duels`" — the phone has an event room (`RyderRoomView`, `EventRoomModel`, `presenter.event`).
2. Strike "11 of 17 active golfers hold 2+ leagues"; replace with the prod facts in §2 R1. Strike HM-26 as a live cost; keep it as a rule for the pool.
3. Note that none of A–F is multi-league; the compose-across-memberships claim is unevidenced by the walks and belongs to the IA problem (O-08/O-09) with a multi-league persona as its test.
4. Re-label the root cause: the dead ends are D81/D119 UNBUILT on the phone (level 6), not "IA: D81/D94". Cite them as "execute here" (CC-30), not as new proposals.
5. Re-label "server work beneath" as level 4/6 data-layer work (DL B-6) that any Home needs.
6. Add the L-10 and L-17 constraints to the recommendation; wording for "streak" per D63/L-42.
7. If SP-2 survives at all, split it: (a) "Ship the Home rulings the phone owes" — S1–S7, single-screen; (b) `native_home` v3 / `home_stories` — data-layer; (c) fold the one-membership-vs-ranked-NOW question into the IA problem.
