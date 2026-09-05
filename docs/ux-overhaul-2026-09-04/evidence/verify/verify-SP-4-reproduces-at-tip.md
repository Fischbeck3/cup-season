# Verify SP-4 · lens "reproduces-at-tip" · tip 3bba87e · 2026-09-04

**Verdict: HOLDS.** Every load-bearing claim reproduces in the shipping phone client and in the web PWA; the prod counts match exactly. Several evidence lines need tightening (below) — two of them make the problem *stronger*, two soften a sub-claim without changing the verdict.

Read-only throughout. Line numbers are as of 3bba87e. SAW = read in code/prod; INFER marked where used.

## 1. What friendship changes (SAW)

- `friendships` is a two-column pair table with status pending/accepted — `supabase/migrations/20260712010000_social_graph.sql:19-33`. The RPC that tombstones a golfer deletes friendships with the comment **"friendships carry no competition weight"** — `20260715210000_former_member_gone.sql:72-73`. That comment is the design statement the root cause was looking for.
- The four effects: home_feed circle (`20260723090000_home_feed_photo.sql:22-27,46`), `my_schedule`/`can_see_round` visibility (`20260718192400_round_object.sql:21-36, 212-242`), `tour_card` visibility gate (`TourCard.swift:4-6`), `add_friend_to_league` requires an accepted friendship (`20260831120000_board_voice_natural_case.sql:14-18` "Not golf buddies yet — send a request first"). Confirmed; nothing else joins `friendships`.

## 2. No pair-wise competitive object outside league/Ryder (SAW)

- `grep -i 'challenge|callout|head_to_head|wager'` over 185 migrations: only `stake` hits, all inside live-round `game_result` JSON or the forfeit ledger. Zero `callout`. `packages/db/contract.psv` lists no challenge/callout/head_to_head RPC (pair-wise reads are `my_rivalries`, `rivalry_weeks`, `event_session_targets`, `home_clash`, forfeits).
- `week_clashes`: `season_id` + `league_members` FKs, `unique(season_id, week_no)` — `20260829091000_weekly_clash.sql:82-96`; the pair is engine-picked "order by staleness asc — rotation guarantee: the most-due pair first" — `20260902170000_the_clash_stops_repeating_itself.sql:83-85`; no client write policy (`:104-115`).
- `event_duels`: `event_players` FKs, session-bound — `20260713120000_ryder_events.sql:67-80`.
- `forfeits`: `create_forfeit` raises `'crew only'` and `'The other side has to be in the crew'` — `20260724120000_forfeit_ledger.sql:60,70-74`; the latest redefinition keeps both guards — `20260727160000_board_voice.sql:350,363`.
- Push: `CsKind` union has no challenge kind — `supabase/functions/push/index.ts:100-102` (the statement's `:100-103` is correct).
- Phone: `grep -i challenge|callout` over Swift sources → only `mfaChallengeVerified` and a standings sentence "waiting on a challenger". Web: only `-webkit-touch-callout` CSS.
- D21 Callout is **unbuilt**, not "status unknown": `spec/decision-log.md:345-369`, three ⚑ still open at `:355-362`; no artefact anywhere.
- D12 retired "duel" as a user word — `spec/decision-log.md:181-188` ("Duel" and "event" become schema/doc words only).

## 3. Head-to-head only inside a shared season, three times (SAW)

Same `shared` CTE (league_members × league_members × seasons) in all three: `my_rivalries` `20260716210000_named_rivalries.sql:76-110`; `rivalry_weeks` `20260716010000_rivalries.sql:75-104`; `tour_card.vs_you` `20260902180000_one_lens_on_the_tour_card.sql:151-170`. Naming requires a row in `my_rivalries()` — `20260716210000:47-50` "name a rivalry only once it has history". `game_results` has no INSERT/UPDATE in any migration since the baseline; no Swift reference; web references are comments (`index.html:8758, 9204`) — dead table confirmed.

## 4. No friends ranking (SAW)

`my_friends` returns `index_current` and nothing computed — `20260715210000:81-83`. The People row prints "@handle · City" only (`apps/ios/CupSeason/People/PeopleScreen.swift:215`) — the index isn't even rendered. No Swift file pairs "friend/buddy" with "rank".

## 5. The Tour Card and the rivalry rows (SAW) — evidence line needs amending

`apps/ios/CupSeason/You/TourCardSheet.swift` actions on someone else's card: Add buddy / Accept buddy request (`:172-178`, labels `TourCard.swift:221-227`), Mute (`:133-138`), Report photo (`:143-157`), and a **VS YOU chip** (`:81-86`) rendered only when `vs.total > 0` that opens `RivalrySheet` → "Name this rivalry" (`RivalriesSection.swift:106`). No challenge/rematch/stake. `TourCard.parse` reads profile/career/trophies/recent/vs_you and drops the server's `courses`/`shared_courses` (`TourCard.swift:93-125` vs `20260902180000:216-217`); the web reads them (`index.html:15461`).

`RivalriesSection.swift:26` — the row's button is `openTourCard(r.opponent)`; the rivalry receipts are one more tap via the chip. The row does print the christened name in gold (`:31-33`). It sits under "Your seasons" at the foot of You (`YouScreen.swift:176-183`).

Clubhouse: no file under `apps/ios/CupSeason/Clubhouse` or `League` reads `my_rivalries`/`RivalsCache` (callers: `RivalryTags.swift:41`, `YouRepository.swift:84`, `RivalriesSection.swift:145`). The room's only head-to-head is `ClashCard` (`StandingsPane.swift:108,332-366`).

## 6. RSVP and the calendar (SAW) — mechanism is a ruled IA split, not a bug

- RSVP: server raises `'Only the host and tagged players can RSVP to this round'` — `20260725160000_rsvp_invited_only.sql:30-35`; phone `canRsvp: Bool { mine || taggedMe }` — `ScheduleModels.swift:511`; buttons gated `if d.canRsvp` — `ScheduledRoundSheet.swift:77-84`.
- The calendar's nearest affordance, "I'm in" on **In your crew's plans** (`ScheduleScreen.swift:82-86`), opens `DeclarePrefill` — it declares *your own* round on the same day/course tagging the host; it is a co-declare, not an RSVP, and it renders only for `isCrewPlan` rows.
- Server returns friend-only rounds (`my_schedule` WHERE `20260718192400:235-242`). The phone drops them: grid + day sheet filter `inLeagueScope` (`ScheduleModels.swift:17, 290-292, 296-300`), watch list filters `isCrewPlan` = `shared_league || tagged_me` (`:19, 301-302`), `Dot` has no buddy case (`:223-230`), legend has no buddy colour (`ScheduleScreen.swift:127`). Home keeps them: `UpcomingRoundsSection.swift:3-4` ("Home keeps buddies, D38"), `:133` unfiltered `sched.watch()`; Up Next "Buddy's playing" uses `is_friend || shared_league` (`ScheduleModels.swift:396-401`). The web does the identical split by design — `index.html:18452-18460` "pure buddies stay on Home. (pilot #3)" vs `:12311`. So persona F's disorientation is real and is a *ruling* (D38 / pilot #3), which makes it a level-3 IA contradiction with the screen's own eyebrow "yours, your buddies', your leagues'".

## 7. Anticipation surfaces that DO exist (softens one clause)

`RivalryTag` (`RivalryTags.swift:16-31`) prints "“The Grudge” · Galen leads 2–1" on a league-mate's booking (`ScheduleScreen.swift:98`) and on the round sheet with "· one more round." (`ScheduledRoundSheet.swift:60-63`). The Ryder duel nudge already sends "X posted — +1.4 to beat · 2 days left" (`20260828040000_nudge_payloads.sql:145-152`, kind `nudge`). Neither creates anything, and both are league/Ryder-scoped — the statement's "never an invitation" should read "the record precedes a round only as a tag on a league-mate's booking; nothing lets it create one".

## 8. Prod (SAW, `supabase db query --linked`, 2026-09-04)

rivalry_names 0 · week_clashes 8 (winner_member set: 0; `settle_week_clash` does write it at `20260902170000:412-413`, so this is "no week settled yet", not a missing write) · forfeits 0 · game_results 0 · event_duels 9 · events 1 · accepted friendships 12, of which 6 share no league. Matches the evidence line exactly.

## 9. Ryder at n=2 (SAW schema / INFER product)

`create_event` has no roster minimum (`20260713120000:158-160`), roster is organizer-only `add_event_player` (`:183-190`), `p_league` nullable — a two-player Ryder is creatable at the schema level. The phone's Start-an-event sheet pitches "Two teams · weekly vs-index duels · first to the clinch" (persona F `:200-202`), so the machine exists and the door is mislabelled for the "beat Jake" intent — INFER: supports why_structural's build-on-the-duel-engine option.

## Corrections to the statement/evidence

1. Tour Card actions → "Add/Accept buddy, Mute, Report photo, and a VS YOU chip (history-gated) that opens the rivalry receipts and naming; no challenge".
2. "rows open the Tour Card rather than the rivalry" → "rows open the Tour Card (`RivalriesSection.swift:26`); the receipts are one tap further via the chip (`TourCardSheet.swift:81-86`)".
3. D21 "build status unknown" → "unbuilt; three ⚑ open (`decision-log.md:355-362`)".
4. Calendar → cite the client filters (`ScheduleModels.swift:17,19,290-302`) and the web's `watchRows` (`index.html:18452-18460`); name it a D38/pilot-#3 IA ruling contradicting the screen's eyebrow.
5. Add the "I'm in" co-declare (`ScheduleScreen.swift:82-86`) as the nearest existing affordance, league-scoped.
6. Root cause: D80 (`decision-log.md:2725-2800`) rules the noun only; the "no competition weight" reading lives in code (`20260715210000:72-73`). Principle cites → `spec/memory-layer-v1.md:261-275` (guardrails) and `spec/product-vision-v1.0.md:31-34` (#3 Real Golf).
7. Prod clash line → "8 clashes, none yet settled".
8. Add: Ryder duel nudge is an existing pair-wise push (`20260828040000:145-152`); the phone's Ryder pitch copy hides the n=2 path.
9. `posts_home_check` cite → `20260716160000_ryder_slice3.sql:27-28`.
