# Verify SP-5 · lens "reproduces-at-tip" · tip 3bba87e · 2026-09-04

**Verdict: HOLDS (true).** Every load-bearing behaviour in the statement is in the shipping phone client at tip; the web reproduces the same shape except one point (PP-01), where the web is ahead. Four evidence lines overstate and should be amended (see Corrections).

Method: opened every cited file at tip, followed the state branches, quoted copy; three read-only prod queries via `supabase db query --linked`. SAW = read in code at tip; PROD = queried; INFERRED = code-traced, not executed on a device.

## 1 · The ⊕ → "Golf" cover → quiet Post row (SAW)

- `apps/ios/CupSeason/Main/MainTabView.swift:337` — selecting the ⊕ tab: `presenter.postOnComposer = false; presenter.showPost = true; tab = old == .post ? .home : old`. The ⊕ ALWAYS presents the cover and the selection snaps back to the tab underneath.
- `:209` the tab is labelled **"Post"** (`Label { Text("Post") } icon: { Image(uiImage: emberPlus) }`).
- `apps/ios/CupSeason/Post/PostCoverView.swift:40` `startOnPost: (startOnComposer && !forcedCover) || forcedOpen` → cover unless a caller set `postOnComposer = true`.
- `:90` header **"Golf"** · "Play one live, post one you just finished, or plan the next".
- `:95-98` `PostLiveHeroRow(title: "Play now — score the group", sub: "Everyone scores from their own phone — Match Play, Wolf or Skins — …")` — ember spine, breathing LIVE word (`:120-156`).
- `:99-100` `PostOptionRow(tick: cs.line2, title: "Post a round — after you play", sub: "Gross + tee, 20 seconds · counts on your card and in every league")` — the quiet second row.
- `:5-7` file header still says "Post is the 90% case — so the ⊕ opens ON the composer (IOS-004 §2)"; `:30-32` the D110 addendum comment says the ⊕ opens the cover. `docs/ios/DECISIONS.md:127` (IOS-011) "⊕ is a full-screen cover opening **on the post form**"; `spec/decision-log.md:4112-4120` (D110 addendum) "the ⊕ and the Clubhouse record door now ALWAYS open the cover; only explicit 'post a round' CTAs (Home/You links, the postround deep link) jump straight to the composer." Never reconciled — confirmed.
- **Tap count:** ⊕ (1) → "Post a round — after you play" (`:100` → `path.append(.post)` → `:111` `PostRoundScreen`) (2). **Two taps to the form, not three.**

## 2 · The composer's shape (SAW)

`apps/ios/CupSeason/Post/PostRoundScreen.swift`: `:147-148` "Course & tees" + `PostCourseSearchField`; `:175-191` "Rating / slope" row folded behind "edit", reading "— / —" when empty (`:205`); `:194-195` placeholders "72.1" / "128"; `:228` 18/9 seg; `:258-259` "Front 9 gross" / "Back 9 gross" only — no total box; `:269` "How most golfers keep it — 41 out, 43 in…"; `:289-310` Details = date / scan / photo. No partner field anywhere. `PostCard.swift:47-55` typed inputs are f9, b9, rating, slope, course, courseId, date; `PostPayload :278-289` gross, rating, nine_rating, slope, holes_played, source, played_on, course_label, api_course_id, season_id, photo_path — no partner.

## 3 · PP-01 · hand-typed course / blank rating (INFERRED from code + SQL; PROD-consistent)

- `PostCourseSearchField.swift:22` placeholder **"Search a course, or type your own"**; `:33` no-match hint "No match — type the course, rating and slope by hand."; `:44` "No rated tees listed — type the rating and slope by hand." So a hand-typed course IS a designed path — provided rating and slope are also typed.
- `PostCard.swift:238-239` `rating = card.ratingValue` (blank → 0), `slope = … : 113`; `:241-248` returns a full preview with gross and a vs figure off rating 0. `PostRoundModel.swift:201` `tapPost` guards only `preview != nil` → Post enabled. `PostCard.swift:297-302` payload `rating: 0`, `slope: card.slopeValue` (blank → 0).
- `supabase/migrations/20260718173100_security_hardening_medium.sql:57-60` `rounds_rating_sane check (rating between 25 and 90) not valid` AND `rounds_slope_sane check (slope between 55 and 155) not valid` — both refuse.
- `PostService.swift:69-80` `insertRound` retries dropping `api_course_id`, then `photo_path`, then throws. `PostRoundModel.swift:224` `toast.show(HumanError.text(error, prefix: "Post failed."))`; `PeopleModels.swift:160-161` "violates|constraint" → "That didn't go through — please try again."; `CSDesign/Toast.swift:18` default 2.6 s.
- Web: `index.html:6989-6999` Q-22 — blank rating/slope with a gross → "Pick a tee — or type the rating and slope — to see the points." and `state.lastPost=null` (Post inert). **The phone lacks this guard.**
- PROD: `rounds where rating is null or rating=0` = 0 (consistent with the constraint refusing).

## 4 · PP-06 · total in Front 9 posts a nine (SAW code path)

`PostCard.swift:68-70` `inputs` with side 18, b9 blank → `(f, 0)`; `:250-261` any single nine → 9-hole preview "half value"; `:294-303` `holes_played: 9`, `nine_rating: rating/2`. No plausibility guard on an 18-hole card. Confirmed.

## 5 · No partner (SAW + PROD)

No field on card/payload (§2). `rounds` columns: of `played_with / partners / posted_by / live_round_id`, only `posted_by` and `live_round_id` exist (PROD information_schema). Receipt "Played with" (`ReceiptSeed.swift:208` `.playedWith`) is fed by `round_card`'s `v_mates` = `live_round_players ∪ attestations` (`20260902173000_what_a_deleted_round_leaves_behind.sql:315-323`) — live seats only. Confirmed.

## 6 · Ends in a close, no funnel rung (SAW)

- `FinishCeremonyView.swift:55-64` buttons: "Share the card" (`PostCeremony.shareLabel`, `PostEpilogue.swift:167`) and "Back to the board" (`:168`) → `onBack` = `model.ceremony = nil` (`PostRoundScreen.swift:137`).
- `PostRoundScreen.swift:136` `.fullScreenCover(item: $model.ceremony, onDismiss: { if !model.afterCeremony() { onDone() } })`; `:139` epilogue `onDismiss: onDone`; `:140` partners `onDismiss: onDone`; `:72` `finish()` → `onDone` = `close` (`PostCoverView.swift:111`) = `dismiss()` (`:40`). The tab is already the one underneath (§1).
- `EpilogueSheet.swift:32-42` buttons: share / "Share a link — no account needed" / "Turn off this link". No door to receipt, people, challenge, or plan.
- `MainTabView.swift:390-392` `PostLinks(openLive:…, openReceipt: { presenter.receipt = $0 }, openPeople: { … youPath.append(YouRoute.people) })` — grep of `Post/` and `Main/` finds **zero** invocations of `openReceipt`/`openPeople` through `PostLinks`. Confirmed.
- League-less copy: `PostRoundScreen.swift:328-333` `countingLine` → "Every posted round scores. Your best **few** each month count toward your squad — …" when `membership == nil` — but it lives under the collapsed "How points work" fold (`:354 if bandsOpen`). Unconditional league-less lines are `:434` "A preview — your league's own math scores it on the books." and `:453` chip "counts on your card". `PostEpilogue.swift:93` `title(firstEver:)` → "Welcome to the season ⛳" regardless of membership; `:88` row sub "Welcome to the season — your number and record start here". Confirmed.

## 7 · PP-03 · blind-18 verdict on ceremony and PNG (INFERRED; PROD n=0)

`PostCard.swift:216` `fallbackIndex = 18.0`; `:236-237` `idx = myIndex ?? fallbackIndex`, `provisional = myIndex == nil`; `:244` `vs = pvi(index: idx, …)`. `PostRoundModel.swift:247` `ceremony = PostCeremony(… vs: preview.vs, points: counts ? preview.points : nil …)` — no provisional gate. `PostEpilogue.swift:155` `band = vsIsSane(vs) ? vsPhrase(vs) : ""`; `FinishCeremonyView.swift:47-49` renders it; `PostEpilogue.swift:172` `recap … pvi: vs`; `:203-205` `bandLine`/`vsLine` gated only on `pviSane`; `RecapCardView.swift:43-44` draws them. D124 (`spec/decision-log.md:4275`) "the preview drops the blind 18 … never a signed vs-figure". The points line is safe (provisional points 0 → `earned` false → seasonNote / "COUNTS ON YOUR CARD", `:157-166`). PROD: `index_provisional` rounds = 0 → no tester has hit it yet.

## 8 · Doors on Home / Upcoming / Clubhouse / You (SAW)

- **Home — CORRECTION to "no post door in any mode".** `HomeView.swift:162-170` `take(_:)`: `.clash` (when `c.mine == nil || c.edge != .me`) and `.floor` set `presenter.postOnComposer = true; presenter.showPost = true` → straight to the composer. `HomeLeadCard.swift:93` `.floor` action label "Post a round". But `HomeLead.swift:166-176`: `.clash` needs a clash (`repo.clash(league: m?.league_id …)`, `HomeView.swift:323`), `.floor` needs a non-solo league pulse with a floor and ≤ 3 days left. Both require an in-season league. `HomeView.swift:178-190` the `+` menu: Start a league / Start an event / Join with a code / Your golf calendar / Find golfers — no Post. `:123` "No rounds from your buddies yet. Post one, or" — prose. So: **no persistent post door; none league-less or between seasons; a conditional one on two lead-card faces in season.** The reader's HM-12 (`reader-home.md:146`) states this correctly; SP-5's paraphrase does not.
- `UpcomingRoundsSection.swift:42-44` `NavigationLink(value: HomeRoute.schedule)` "Put a round on the calendar" → the schedule screen, not `presenter.declare`. Confirmed.
- `ClubhouseView.swift:171` `openRecord: { p.postOnComposer = false; p.showPost = true }` → the ⊕ cover. Callers: "Post a round" at `IndividualRaceView.swift:44`, `ReceiptSheets.swift:99`, `RoomAlbumPane.swift:21`; "Live round" at `StandingsPane.swift:320`. Confirmed — and this contradicts the D110 addendum's own carve-out (explicit "post a round" CTAs jump to the composer).
- `YouScreen.swift:161-162` "the 'Post a round' button that sat here is gone". The addendum's "Home/You links" — You's no longer exists.

## 9 · Live twin (SAW + PROD)

`LiveSetupView.swift:24-34` four cards before "Tee off →"; `:94-103` Tee / Rating / Slope fields on every setup; `LiveModels.swift:201-202` `effectiveRating { rating ?? 72 }`, `effectiveSlope { slope ?? 113 }` — silent. `LiveRoundStore.swift:784-785` `finish()` sets `state.active = false; state.stage = .setup` and shows the recap as a sheet; `LiveRoundHost.swift:50-56` renders `LiveSetupView` under it; `LiveFinishViews.swift:74-76` posted rows are plain `checkRow`s with no action. PROD `live_rounds`: abandoned 21, final 5, live 0 (= 26).

## 10 · Prod figures (PROD, 2026-09-04)

`client_events event='post_submit'`: n = 24, p50 = 39 s, p90 = 76 s — exactly as cited vs the cover's "20 seconds". `rounds` by source: quick 207, live 5. Rating-less rounds 0. Provisional rounds 0. Profiles with no league: 14.

## 11 · Web (SAW)

`index.html:3911` tab "Post" (aria "Post a round") → `#view-record` `:3196-3215`: same "Golf" eyebrow, same three doors, same "Gross + tee, 20 seconds". `#view-post` `:3361-3411`: Course & tees / Rating / Slope / 18-9 seg / Front 9 / Back 9 / Date — same shape, no partner field (`#inCourse` placeholder "Search for the course you played"). The web guards blank rating (Q-22). Both clients declare the ⊕ "one door for before, during and after" (`:15058`).

## 12 · Persona quotes

A `persona-A-new-golfer.md:301` "Close saves nothing, so I can't set up tomorrow tonight." ✓ · C `persona-C-active-competitor.md:335` "Posting a round is a tab, not a sentence." ✓ · F `persona-F-buddies-no-league.md:270` "never connected to the Sunday it could animate" ✓ · E `persona-E-invited-joiner.md:259` (the cover walk; grep matched the line).

## Corrections to the statement / evidence

1. "3 taps from a leagueless Home to the form" → **2 taps** (⊕, then the Post row). "6–10 to submit" stands (≈8 with course, tee, two nines, Post).
2. "cannot post a hand-typed course at all" → **"cannot post a hand-typed course unless rating AND slope are also typed behind 'edit'; the composer previews the score and enables Post regardless, and the refusal is the DB's (rating 25–90 and slope 55–155, `20260718173100:57-60`), surfaced as 'Post failed. That didn't go through — please try again.' for 2.6 s."** Cite the slope constraint as well as rating.
3. "asks course, tee, rating/slope, 18/9 and two nines before it accepts a score" → the composer **accepts** a score with only two nines typed; the defect is that the UI accepts what the server refuses and the rating/slope row reads as optional ("— / — · edit"). The web (Q-22) already closes this gap — the phone regressed behind its reference here.
4. "No post door on Home in any mode (HM-12)" → **"No persistent post door on Home; the D176 lead card reaches the composer only on the clash and floor faces (`HomeView.swift:162-170`, `HomeLeadCard.swift:93`), both gated on an in-season league (`HomeLead.swift:166-176`); none league-less or between seasons; the `+` menu has no Post (`HomeView.swift:178-190`)."**
5. CH-16 "room CTAs open the hub" → they open the ⊕ **cover**; add that this breaks the D110 addendum's own rule for explicit "Post a round" CTAs, and that the addendum's "You link" no longer exists (`YouScreen.swift:161-162`).
6. Label PP-03 INFERRED (0 provisional rounds in prod); note the points line is safe and only the band line and the PNG's bandLine/vsLine carry the blind 18.
7. "league-less poster told rounds 'count toward your squad'" — add that it sits under the collapsed "How points work" fold (`:354`); the always-visible league-less lines are `:434` and `:453`.
8. Add the concrete name mismatch: tab "Post" (`MainTabView.swift:209`; web `index.html:3911`) opens a cover titled "Golf" led by "Play now".
9. Line refs: ember hero `PostCoverView.swift:95-98`; countingLine `PostRoundScreen.swift:328-333`; setup branch `LiveRoundHost.swift:50-56`; ceremony/epilogue/partners dismiss `PostRoundScreen.swift:136,139,140`.
