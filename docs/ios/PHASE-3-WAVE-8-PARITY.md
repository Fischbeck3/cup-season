# Phase 3 — wave 8, the parity audit

*Audit artifact, 2026-08-28. Branch `native/m0-foundation` at `b0b8f87` plus this
wave. Governed by IOS-018 (full web parity first) and IOS-022 (the polish list).
Walks every row of the IOS-001 §6 parity matrix against the web's own copy and
behaviour, fixes what fits in the walk, and carries the rest with a size.*

**Method.** Each of the ~100 rows was checked three ways: the web's
implementation in `index.html` (line-cited below), the phone's implementation in
`apps/ios/`, and — where the `-cs_dev_open` hatch reaches it — a look at the
screen on a simulator signed in to the owner's account (Home, Clubhouse, Board,
Schedule, Card & settings, Buddies, You, the event picker, the wizard, the tee
sheet, the composer, the door). Status vocabulary: **parity** — the web's copy
and behaviour, verbatim · **partial** — a named gap · **absent** · **intentional**
— a decision id. Fixes were limited to what fits in ~40 lines of Swift with no
new RPC; anything larger is carried.

**Numbers.** 23 files, +266/−56. Build clean; 325 kit + 11 design + 8 app tests
pass; preflight 17/17 PASS. Rows walked: 97. Parity or better on entry: 61.
Small fixes landed this wave: 33 (across 19 rows). Carried: 24 gaps (7 S ·
12 M · 3 L · 2 backend-blocked), listed in §4.

Honest caveat on the screen pass: the hatch reaches a screen, not a flow. Two-tap
confirms, toasts and the live handle check were verified by reading the code and
by build + test, not by a finger on the simulator.

---

## 1. What was fixed this wave — by matrix section

Every fix below ports the web's copy verbatim (line cited) unless marked
*phone-only improvement*.

### §6.1 Identity

| Row | Fix | Where |
|---|---|---|
| Door | 20 s spam hint — "No code yet? Check spam for the newest Cup Season email — older codes retire when a new one sends." (web 15091), gated exactly as the web: code stage open, field empty, no error showing | `CupSeason/Door/DoorView.swift` `scheduleSpamHint()` |
| Door | `Code sent` toast on the first send (web 15130) — the door carries its own `CSToastCenter` because it sits above the tab host | `DoorView.swift` |
| Door | Rate-limit line completed: "…limits sends per hour. Give it a few minutes." (web 15143) | `CupSeasonKit/AuthRules.swift:55` |
| Door | Resend note carries the address again: "Fresh code sent to \<email\> — the newest email wins." (web 15101) | `DoorView.swift` `resend()` |
| Door | Accessibility labels on the code field ("The 8 digits") and the password field ("Review password"); `.textContentType(.password)` | `DoorView.swift` |
| Reviewer door | "Review access: enter the password from the notes." on entry (15122) · `REVIEW PASSWORD` placeholder (15119) · the 8-char floor with "Enter the review password from the notes." (15015) · fallback "That password didn't take." (15025) · "Signed in, loading…" on success | `DoorView.swift` `send()` / `reviewer()` |
| Legal | "By continuing you agree to the Terms & Privacy Policy." with the two words as the links (web 2648) — was two bare links | `DoorView.swift` `legal` |
| Card gate | **Live handle check** through `Rpc.handle_available` (shipped in `20260827130200`, had zero callers): "Handle: 3–20 letters, numbers or underscores." · "Checking @x…" · "@x is available ✓" · "@x is taken — tap to edit it." (web 13051–13057), 360 ms debounce like the web; a known-taken handle does not advance. Clears the matrix's ⏳ on this row | `CupSeason/Onboarding/CardGateView.swift` `checkHandle` |
| Card gate | Claim thread: "Saving your card attaches the round you're claiming." when a claim intent is pending (web 2906) | `CardGateView.swift` |
| Card gate | "City and home course live on your card — add them any time from the You tab." at the marker step (web 2674); GHIN placeholder and explainer "Links your USGA record — that's identity, not your number. Your index still comes from your posted scores." (2668–2669) | `CardGateView.swift` |
| Your card | "No leagues yet. Start one or join with a code." (web 13509) replaces the dead-end "No league yet." · `Card saved` toast beside the inline tick (13698) | `CupSeason/Settings/CardAndSettingsScreen.swift` |
| Handicap index | Composer eyebrow says "Post a round · your index builds at 3 rounds" when nothing is minted (web 14242, setup-QA S6-03) — was a dash | `CupSeason/Post/PostRoundModel.swift` `eyebrow` |
| Tour Card | The load-failure branch no longer claims PRIVATE; it says "Could not pull the card — check your signal and try again." and offers **Try again** (*phone-only improvement* — the web has no retry either) | `CupSeason/You/TourCardSheet.swift` |

### §6.2 Home · §6.6 Social

| Row | Fix | Where |
|---|---|---|
| Cross-league stream | "Earlier" opens on its own when Today and This week are empty, "so the feed never looks empty" (web 10479–10481) | `CupSeason/Home/HomeView.swift` `FeedBucketView.only` |
| Reactions | The bare 🔥 quick chip is back on every Home round card — F11 3.1 "the heater is the one-thumb chip, always on the card face" (web 4708–4710). The in-code citation of IOS-019 for hiding it was not supported by IOS-019's text | `HomeView.swift` `HomeReactionStrip` |
| Digest | The web's `<b>` restored: the count and the name are semibold (web 10538–10600) — `HomeDigest.strong` carries the substrings, the row sets them in an `AttributedString` | `CupSeasonKit/Home/HomeDigest.swift`, `HomeView.swift` `HomeDigestRow` |
| Occasion | `home_occasion_tap` telemetry with `win`, `act` and `platform: ios` (web 10082/10093) | `HomeView.swift` |

### §6.3 Leagues · §6.7 Money

| Row | Fix | Where |
|---|---|---|
| Members sheet | The three `confirm()` reasons ride the two-tap arm and read as the accessibility hint: Remove — "Their profile and rounds are untouched. They just leave this league." (16959) · Bye — "Their one season bye — it waives this month's floor. (A missed floor auto-uses it anyway; this is for a known absence.)" (16974) · Make Pro — "You become a player. Only they can hand it back." (16988). `ArmedMini` gained an `onArm` callback for this | `CupSeason/League/MembersSheet.swift`, `League/RoomBits.swift` |
| Members sheet | After `transfer_pro` the room refreshes before the sheet closes (the web reloads the page, 16995) so `isPro` stops lying | `MembersSheet.swift` |
| Standings / receipt | **The Trend column is back** — `StandingsTableView` promised it "stays on the squad receipt" and it existed nowhere. `RoomSpark` ports the web's `sparkline()` (4462: last seven points, 60×16, min–max) onto the squad receipt as a "Trend" row with a spoken accessibility value, and onto your own rung of the climb (`climbSpark`, 4421) | `League/RoomBits.swift` `RoomSpark`, `League/ReceiptSheets.swift`, `League/ClimbView.swift` |
| Member history | The calendar date renders ("AUG 12 · 9 HOLES") instead of the ISO string (*phone-only improvement*; web 11303 prints raw) | `ReceiptSheets.swift:89` |
| Album | The empty state ends in the door it names: "Photos land here when rounds carry them — add one from the Post card." + **Post a round** | `League/RoomAlbumPane.swift` |
| Individual race | Same treatment: the web's sentence (11258) + **Post a round** | `League/IndividualRaceView.swift` |
| Pot | The figure runs the web's odometer (`csOdo`, 7000) — `numericText` transition on `potTotal` | `League/PotPane.swift` |

### §6.4 Rounds · §6.5 Live & events

| Row | Fix | Where |
|---|---|---|
| ⊕ hub | "Play now" sub restored verbatim: "A shared pencil: hole-by-hole, match play, Wolf & the settle-up · guests welcome" (web 2967) — had lost "hole-by-hole" and "guests welcome" | `CupSeason/Post/PostCoverView.swift` |
| Bands table | The fine print under the five bands: "Every posted round scores. Your best 4 each month count toward your squad — a better round always replaces your lowest, in real time." (web 3198) | `Post/PostRoundScreen.swift` |
| Scan | Confidence per cell (the matrix's ✦): a hole the model could not read (`scan.read[i] == 0`) wears a dashed `warm` hairline and says "not read from the card — check it" to VoiceOver | `Post/PostHoleGrid.swift` `cell` |
| Tee sheet | The league-less block says why, honestly: "The tee sheet posts into a league — join or start one first" (was an invented "No active season to post into"; the real fix is carried, §4) | `Live/LiveRoundStore.swift` `teeOff` |
| Ryder / Major | The scrap arm shows the web's confirm sentence — `Scrap "NAME"? It hasn't been scored, so this removes it, its board and its field completely.` (16265) — `RyderMath.scrapQuestion` existed and was never called. `CSArmedButton` gained `onArm` | `Events/RyderRoomView.swift`, `Events/MajorRoomView.swift`, `People/Links.swift` |

---

## 2. The matrix, row by row

Status after this wave. `web` = index.html line(s). Rows not listed under "fix" in §1 were already at parity on entry.

### §6.1 Identity
| Row | Status | Note |
|---|---|---|
| Door: email → 8-digit code | **parity** (fixed) | web 15009–15150 |
| Reviewer door | **parity** (fixed) | |
| Invite code before sign-in | **partial** → carried S | no "I have an invite code" field on the signed-out door; `league_by_code` (anon, bound at `Rpc.swift:775`) is not pre-validated; the invited-door lines (15209/17657) and the F1 name warm-up (17570) are absent |
| Golfer card gate | **parity minus the photo** | handle check, claim thread and copy fixed; the photo-at-the-marker-step ✦ is carried S |
| Orientation (four places) | **absent** → carried M | `CSConfig.orientedKey` is defined and never read; the screen (web 2681–2713, 13000–13008) does not exist. The copy survives in `GuideCopy.swift` as sheets |
| Your card (edit) | **parity** (fixed) | |
| Handicap index | **parity** (fixed) | |
| Avatars + per-league marker | **parity** | `set_league_marker("")` clears via `nullif` — correct |
| Settings | **parity** | "Fescue" for "Charcoal" is D103a/IOS-025 |
| Delete account | **partial** → carried S | the server's blocker lands as a transient toast; the matrix's "link to the league" is unbuilt |
| Legal | **parity minus the browser** | sentence fixed; links open Safari, not an in-app browser (carried S) |
| Mute / report photo | **parity** | |

### §6.2 Home
| Row | Status | Note |
|---|---|---|
| Lifecycle hero | **partial** → owner-owned, logged | no CTA in any of the 8 states (web wires one in 5: 9853, 9925, 9945, 9958, 9976); rung 5 cannot render (`HomeMode.of` reads no buddy count); rung-6 and preseason copy drift (9955, 9922); one of three forming branches (9926); wrapped lacks "Season recap →" (9852); no progress bars. **Hero region is owned elsewhere — not edited** |
| Doors above the hero | **intentional** (IOS-012) + carried S | run-it-back is unreachable for anyone with an active membership (web shows it for any completed league, 9737) |
| Live-round banner | **parity** | |
| Ryder duel on Home | **absent** → carried M | IOS-008 option 2, unbuilt |
| Up Next chips | **parity** | |
| Occasion card | **partial** → carried S | six date winks ported; the seventh, the weekend **cluster** (10071–10085: "This weekend" · "N of you out Sat." · "Put a jug on it"), is absent |
| Digest | **parity** (fixed) | |
| Cross-league stream | **partial** (fixed one) → carried M | Earlier auto-open fixed; no realtime on Home (web re-runs `loadHome()` on `posts` INSERT, 14700) |
| Hero/CTA telemetry | **absent** → carried S | `home_hero_state` / `home_hero_tap`; the occasion tap is now sent |

### §6.3 Leagues & seasons
| Row | Status | Note |
|---|---|---|
| League switcher | **partial** → owner-owned, logged | no phase chips (15260–15268), no events or invites in the menu (15365), no per-league scrap ×, hidden at one membership. **`ClubhouseView.swift` is owned elsewhere** |
| Standings sentence/climb/table/split-flap/scenario | **parity** (fixed) | Trend restored on the receipt and the climb |
| Individual race | **parity** (improved) | stored king once complete |
| Squad receipt, member history | **parity** (improved; fixed date) | ledger rows carry reasons |
| Cup Final state | **built** (D105, 2026-08-28) | `cup_final_race()` is the one window expression for the live race AND `close_season`; seeds carry the §14.3 ladder with `seed_rung`; `CupFinalRaceView` leads Standings during the Final, receipt sheet per finalist. Web ships the same block |
| Trophy Room / ceremony / run it back | **parity** (improved) | renders from `season_payouts` |
| Bylaws card | **parity** | |
| Wizard | **parity** | IOS-018 supersedes IOS-007's 🖥 |
| Join by code + covenant | **parity** (improved) | fails closed |
| Invite golfers, pending invites | **parity** | |
| Blind draw / assign / start | **parity** (improved) | |
| Draft night | **exceeds web** | a real snake board; the web shows demo scenery only |
| Members sheet | **parity** (fixed) | |
| Season calendar | **parity** | |
| Album | **parity** (fixed empty state) | |
| Cancel / delete, D71 vote | **parity** | |

### §6.4 Rounds
| Row | Status | Note |
|---|---|---|
| ⊕ hub | **parity** (fixed) | |
| Two-box post | **parity** | ⏳ `post_round()` is a backend item, unbuilt server-side |
| Par stepper, set the pars, even-par guard | **parity** | |
| Course search + tee pick | **parity** | |
| Scan the card | **parity** (fixed confidence) | |
| Photo | **parity** | |
| Preview + bands | **parity** (fixed) | |
| Draft restore | **parity** | the photo-in-draft ✦ is unbuilt on both |
| Finish ceremony | **parity** | |
| Epilogue | **parity** | |
| Round receipt | **parity** | |
| Scorecard view | **parity to web** → carried M | `round_holes_of()` is deployed and bound (`Rpc.swift:1256`) with zero callers; the receipt's scorecard row appears only for live rounds |
| Delete a round | **parity** | |
| Scheduled rounds | **parity** | the phone adds a "Sure? Cancel it" arm |
| Share recap card + link | **parity** | |

### §6.5 Live games & events
| Row | Status | Note |
|---|---|---|
| Tee sheet setup | **partial** → carried M | a league-less golfer cannot tee off; the web runs the local pencil (8952). Toast made honest this wave |
| Live scoring | **parity** | |
| Engines | **parity** | 56 test vectors |
| Group phones | **partial** → backend-blocked | no `live_set_scores` batch write (not in `contract.psv`); no `BGTaskScheduler` flush (S, additive) |
| Guest pencil / claim | **parity** | |
| Lock-screen presence | **absent** → carried L | no ActivityKit, no widget target |
| Finish + settlement | **parity** | |
| Scrap / abandon | **parity** | |
| Ryder room | **parity** (fixed scrap) | ⏳ `notify_board` unshipped; board realtime unbuilt on both |
| Major room | **parity** (fixed scrap) | door hidden — IOS-022 item 7 |
| Create a Ryder / Major | **parity** | |
| Rivalries | **parity** | |
| Personal stakes (D51) · weekly clash (D52) | **absent on both** | out of scope |

### §6.6 Social & notifications
| Row | Status | Note |
|---|---|---|
| Board | **parity** (+ pagination) | |
| Reactions + comments | **parity** (fixed Home chip) | |
| Realtime | **partial** → carried M | one league, and only while a `BoardStore` is mounted — so the D86 doorbell only rings with the board on screen |
| Buddies | **parity** | |
| Tour Card | **parity** (fixed failure branch) | |
| Trophy case + engraver | **parity** | |
| Career record, Last Round With | **parity** | |
| Push registration | **parity ✦** | |
| Push payload routing | **parity** (⏳ closed by wave 7) | |
| Taunts + doorbell | **partial** → carried L | the "doorbell gains a mute" needs a per-user switch on `push_nudges` (migration) |
| Emails | **parity** | |
| Share links + OG | **parity** | AASA excludes `?share` |

### §6.7 Money, stats, admin
| Row | Status | Note |
|---|---|---|
| Pot | **parity** (fixed odometer) | roster arithmetic is the matrix's ⚑ open question (`stake × members` here vs `max(members, invited+1)` on the web); needs a decision line before it changes |
| Pro marks buy-ins | **parity** | |
| Forfeits | **parity** | |
| Ceremony "you're owed" | **parity** (improved) | |
| Career earnings | **parity** | |
| Stats | **parity to web** | IOS-016's three surfaces are ⏳ on the "best" definition |
| Founder desk | **parity** (exceeds the 🖥 plan) | |
| Feedback | **parity** | |
| `app_flags` + `min_ios_build` | **parity** (improved) | |
| Sandbox / `test-seed` | **nothing to port** | no web surface |
| Membership / Pro Shop | **parity** | hidden until `pricing.visible` |
| Demo diorama | **intentional** (D83) | |

---

## 3. Empty states — do they end in a next move?

Fixed this wave: Your leagues (Settings), Album, Individual race, Tour Card failure.

Still dead ends, **shared with the web** (the web's own Phase-4 rule at 11086 says every dead end becomes a next move, so these are product gaps, not port gaps): Career record "Your record fills in when a season closes." (11110) · Tour Card PRIVATE (13314) · Standings table "NO ROUNDS YET" (4516) · Climb "THE RACE STARTS WITH THE FIRST POSTED ROUND" (4366, a hint without a button) · Founder desk "Nothing yet." ×4 (15429) · Live "No guests in this round." (9323) · Ryder "No one assigned yet." / "Pairings not set." for a non-organizer (12345, 12290) · Scheduled round "Just you so far — tag your group." for a non-host (16794) · Event room "No event loaded." (12200).

Phone-only: the Board's synthetic "\<League\> is live — post the first round" system row names the move but is inert (`BoardRows.swift:78`); worth making it open the composer.

---

## 4. Carried gaps, sized

| Gap | Size | Row | Notes |
|---|---|---|---|
| Invite code on the signed-out door (+ F1 name warm-up on `?join=`) | **S** | 6.1 | `league_by_code` is anon and bound; ~60–80 lines in `DoorView` + `CupSeasonApp.swift:30` |
| Photo at the marker step | **S** | 6.1 | `AvatarCrop` + `uploadAvatar` exist; needs an ordering decision (upload before `set_profile`) |
| In-app browser for legal | **S** | 6.1 | one `SFSafariViewController` wrapper, five `Link` sites |
| Delete-account blocker with a link to the league | **S** | 6.1 | parse the two named blockers into a persistent `CSNote` |
| Run-it-back reachable with an active membership | **S** | 6.2 | surface `RunItBackCard` when any membership is `complete` |
| Occasion cluster wink | **S** | 6.2 | the 14-day watch list is already loaded for Up Next |
| Hero/CTA telemetry (+ `platform:'ios'` everywhere) | **S** | 6.2 | call sites only |
| Group-phone background flush (`BGTaskScheduler`) | **S** | 6.5 | additive on the phone |
| Orientation screen | **M** | 6.1 | new screen between card and Home; set-on-show semantics (13001) |
| Hero CTAs, rung 5, forming branches, wrapped recap link, progress bars | **M** | 6.2 | **owner-owned region** (`HomeView` hero) |
| Ryder duel on Home | **M** | 6.2 | IOS-008 option 2 |
| Home realtime / doorbell reach across memberships | **M** | 6.2/6.6 | move the channel from `BoardStore` to the session |
| League switcher (phase chips, events, invites, scrap, one-membership) | **M** | 6.3 | **owner-owned file** (`ClubhouseView`) |
| Scorecard for every round with holes | **M** | 6.4 | `round_holes_of()` deployed, no caller; a second `Scorecard` construction path |
| League-less live round (local pencil) | **M** | 6.5 | confirm intent first — the web's own league-less finish dead-ends |
| Event-board realtime + reactions | **M** | 6.5 | net-new; wants `notify_board` |
| Stats → three insight surfaces (IOS-016) | **M–L** | 6.7 | ⏳ "best" definition |
| Cup Final seeds, head start, fresh-slate race (`cup_finalists`) | **done** | 6.3 | D105 — both clients read `cup_final_race()` |
| Live Activity / Dynamic Island | **L** | 6.5 | new widget target |
| Doorbell mute | **L** | 6.6 | migration on `push_nudges` |
| Group-phone batch write `live_set_scores` | backend | 6.5 | not in `contract.psv` (IOS-009 batch 2) |
| `post_round()` RPC | backend | 6.4 | the direct `rounds` insert stays until it ships |
| Pot roster arithmetic | decision | 6.7 | the matrix's ⚑; log a line before changing either client |
| Server-side ceremony seen cursor | decision | 6.3 | per-device today on both clients |

Skipped on purpose: the `set_profile(p_photo_path)` deploy-skew message (web 13655) — that migration shipped weeks ago and `call(_:)` already retries by dropping the optional arg; the "Card saved. Welcome, \<name\>." toast at the gate — the view unmounts into Home on save, so a local toast would never be seen; a shared toast center is a small refactor for another pass.

---

## 5. Findings in regions owned by other sessions (logged, not edited)

- `Home/HomeView.swift` hero (`HomeHero`, 421–529) and `You/YouHero.swift`: the whole §6.2 hero row above.
- `Clubhouse/ClubhouseView.swift`: the switcher row; its `arrow.left.arrow.right` toolbar button (line 47) has no accessibility label.
- `League/LeaguePane.swift`: at parity; nothing to log.
- `Settings/CardAndSettingsScreen.swift` palette section: untouched (the "No leagues yet" and toast edits are in the card section).
- `Events/` nudge routing: untouched; the two edits in `Events/` are the scrap sentence only.

## 6. Verification

- `xcodebuild build` on the audit simulator: clean.
- `xcodebuild test`: 325 kit (80 suites) + 11 design + 8 app, all passing.
- `node tests/preflight.mjs`: 17/17 PASS (swift palette purity — the new hairline uses the `warm` token; swift rpc grants — 112 phone RPCs, `handle_available` included).
- Screens looked at after the fixes: the door (legal sentence), Home (digest bold, bare 🔥 chip). The rest of the fixes are on sheets and arms the hatch does not reach.

Nothing here touches the database or the edge functions: no migration, no deploy owed.
