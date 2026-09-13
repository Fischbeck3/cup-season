# Season activation sprint — handoff to Codex, 2026-09-13

Packet: `docs/planning/2026-09-13-claude-led-season-activation.md` at `2f51b45`.
Baseline: `1c59a96` (`codex/busy-friends-native-2026-09-13`).
Branch: `claude/season-activation`, worktree `~/cup-season-activation`.

**All three checkpoints are built. Nothing is deployed.** No production database
or Edge change, no merge to main, no TestFlight upload. Two migrations are
written and verified against an isolated database only.

## The commits

| Commit | Checkpoint |
|---|---|
| `98540b5` | S1 · the review of `1c59a96` and its fixes — the review-fix commit, first, on its own |
| `0889ddd` | S2 · the invite-to-post journey |
| `8403343` | S3 · this month, in the league's own terms |

S1 carries only review fixes, so it can be integrated independently of the new
behavior in S2 and S3, as the packet requires. The full S1 review, with a
disposition for every named area, is `docs/reviews/2026-09-13-season-activation-s1.md`.

## Decisions recorded

`D347` stored counting cap · `D348` an invitation is not a member ·
`D349` a stamped date is not a started round · `D350` one ordinary round however
many times Post is pressed · `D351` the terms reach every door ·
`D352` this month in the league's own terms. All six are in `spec/decision-log.md`,
and the two that add a contract (D350's use of an existing one, D351's new one)
state identity, ownership, replay, conflicting-body, old-client, old-server and
grants **before** the wiring, as the packet requires.

## What was wrong, in one line each

1. `lock_league` swallowed an explicit Unlimited, and both clients snapped an
   off-ladder stored cap to a rung and then **saved the rung** — to two different
   rungs. The cap decides `month_rank`, so this reached the points table.
2. The phone's lock-share line counted invitations as members: a Pro alone with
   five invitations out was told "Six in."
3. Both composers stamp today's date at open, then asked "is this card empty?"
   with a predicate requiring the date to be absent. The phone therefore
   **never once restored a draft**; the web restored an empty one and announced it.
4. Ordinary posting had no request identity on either client. A post that
   committed and lost its response invited the one tap that mints a second
   scoring round.
5. The web accepted an invitation from three controls without the covenant, and
   the phone accepted one from the lock screen with the app shut. A $50 season
   could be joined with the stake never shown.
6. `respond_invite` returns silently on an already-answered invitation and both
   clients said "Joined ✓" for a join that did not happen.
7. An Unlimited league got no month line and no foot; the minimum's figure was
   printed as a round count; a league with **no minimum** was told its month was
   "covered"; and an extra round was described as points rather than a chance.

## Migrations — written, verified, NOT deployed

| File | What it does |
|---|---|
| `20261025090000_unlimited_means_unlimited.sql` | one line of `lock_league`: `counting_cap = p_counting_cap`. Same signature, so no overload and no discarded ACL. The argument default stays `3`, so an old client that omits it is unaffected. |
| `20261026090000_the_terms_reach_every_door.sql` | adds `join_covenant_for_invite(uuid)` — a **new name**, not a defaulted argument beside `join_covenant_info`. Execute to `authenticated` only. |

Both carry read-only self-checks that raise rather than report success. Deploy
with `supabase db push` (owner). Neither needs a client push of its own; the
`index.html` half ships on the normal Netlify path.

**Deploy order does not matter.** Each client falls back on `PGRST202`/`42883`
alone: ordinary posting keeps today's `post_round` path and today's guarantees,
and invite acceptance keeps today's behavior, with the copy promising nothing
more on either fallback.

## Acceptance matrix

| Scenario | Status | Where |
|---|---|---|
| Busy friends, Best 2 / no minimum, one round this month | **Pass** | The no-minimum league says its counting rule and nothing about owing; "covered" is gone; the extra round is a chance, not points. `LeagueRoomTests.nextUpAndTheMeter` asserts the sentence contains none of *adds · overtake · guarantee · qualif*. |
| Former D1 group, custom squad count and tougher rules | **Pass** | A chosen `squads3`/`squads4` survives `preparedForReview`; an off-ladder or Unlimited cap survives the lock, proven on the isolated database and across thirteen stored values on both clients. |
| New golfer accepting an invitation | **Partly.** Consent and the rules: pass. | No membership before consent (`invite_golfer` writes `member_invites` only, verified). The covenant now gates every accept on the web and the lock-screen accept is retired. **The covenant does not carry the handicap allowance** — not in the payload, recorded as its own contract, not invented. The Major exhibition gate is not conflated with season contribution anywhere I changed. |
| Club professional gathering an existing member group | **Partly.** | Roster counts are truthful on the lock share, the members sheet and the agreement. The wizard's pot tile now says "expected", not "in so far", and the web's collected-pot fallback no longer turns typed email addresses into payers. No new club model. |
| Failure and time boundaries | **Partly.** | Duplicate tap and ambiguous response: covered by D350 and proven on the isolated database. Relaunch: the request id rides with the draft, so a retry after a kill is the same request. Account switch: the draft key is owner-scoped and the pending invitation is now cleared on sign-out. 9/18 holes, monthly boundary and partial month: covered by the D352 producers and their tests. **Offline and an older server were reasoned about and not executed.** |

## Evidence — everything below was run

| Check | Result |
|---|---|
| `CupSeasonKit` suite, iPhone 17 Pro simulator | **1,103 tests in 179 suites, TEST SUCCEEDED** |
| `CupSeasonTests` (app target), same destination | **85 tests in 17 suites, TEST SUCCEEDED** |
| `CupSeasonUITests/LeagueSetupReviewTests` | **2 tests passed**, including `testAccessibilitySizeReachesReviewAndConfirmation` (52s) |
| `CupSeason` app build | **BUILD SUCCEEDED** (XcodeGen regenerated first) |
| `npm run preflight` | **0 failures, 0 warnings**, including the free-identifier check over all four script blocks |
| `node tools/web-verify.mjs --widths 1440,390,320` | no horizontal overflow at any width; **0 console errors, 0 warnings** |
| Isolated PostgreSQL 17 cluster, port 5470 | every migration applied, none skipped |

On that cluster, executed live rather than recalled:

- **The cap.** Stored 4 + explicit `null` → `null` (Unlimited means Unlimited).
  Stored 4 + explicit `5` → `5` (an off-ladder cap writes unaltered). Argument
  omitted → `3`, the SQL default, **unchanged by the fix** — a pre-existing sharp
  edge neither shipped client can reach, named so nobody rediscovers it as new.
  The participation floor beside it is untouched. `lock_league` resolves to one function.
- **`post_round_once`.** A replay returns the same round; only one round exists;
  a conflicting body is refused with **nothing written**; a new request id is a new round.
- **`join_covenant_for_invite`.** The invitee sees the stake and the name; a
  stranger gets nothing; a resolved invitation is not a door; the league code is never returned.
- **Client-side.** Thirteen stored caps round-trip unaltered on the web
  (1,2,3,4,5,6,7,8,10,12,20,31,null); moving the picker off an off-ladder cap
  takes the ladder's value in the direction of travel; the web's draft predicate
  distinguishes a stamped date from a chosen one across six cases; the web's
  counting rule reads correctly at caps 1, 3, 5, 12 and Unlimited, with the
  picker's label proven absent from every one.

**Environment actually used.** Local Mac session. iOS Simulator, iPhone 17 Pro.
PostgreSQL 17.11 on port 5470, socket `/tmp`, database `cupseason`.

**Not run, and not counted.** Dark and light passes; AX3 beyond the league-setup
journey above; actual taps through the post composer, the invite acceptance and
the month surfaces on a device; the web with service workers and caches cleared
in a real browser; any offline or older-server run. These are Codex's
independent integration QA and they are the reason this handoff does not call
the sprint verified end to end.

## Open — named, not fixed

1. **Duplicate leagues after an ambiguous create.** An orphaned setup league is
   recoverable (its room has a wizard door), but the leagueless "Start a season"
   door passes no existing id, so a golfer can mint a second one beside the
   first. Needs a durable in-flight record or request identity on `create_league`.
2. **The phone has no invitations list and no decline control at all.**
   `InvitesBanner` is complete and rendered by nothing. Restoring it is a
   surface, not a fix, so it was not done inside this sprint.
3. **"See the terms" shows no terms.** The Home invitation item routes to the
   season page on the phone (which then says the season is not yours to see) and
   drops the id entirely on the web.
4. **The covenant omits the handicap allowance.** Not in `join_covenant_info`'s
   payload. Its own contract.
5. **The join-month waiver and the auto-bye cannot be spoken honestly.**
   `league_pulse.partial` has no `joined_at` arm, so a golfer who joined
   mid-month may be shown a minimum `close_month` will waive; and nothing says
   whether a golfer's bye is still available. One more fact on `league_pulse`,
   and its own decision.
6. **A link tapped while the app is open and signed in does nothing.** The
   pending code is stored and only `MainTabView.onAppear` reads it.
7. **The §14.3 / D212 Final conflict.** Untouched by design. Owner decision.
   Nothing in these three commits touches `enter_cup_final`, `v_rounds_ranked`,
   `cup_points` or `close_season`.
8. **No backfill for caps already rewritten** by an older client. Nothing can
   tell a rewrite from a choice.

## To rerun this independently

```
cd ~/cup-season-activation
npm ci && npm run preflight
node tools/web-verify.mjs --widths 1440,390,320
(cd apps/ios && xcodegen generate)
(cd apps/ios/Packages/CupSeasonKit && xcodebuild test -scheme CupSeasonKit \
   -destination 'platform=iOS Simulator,name=iPhone 17 Pro')
(cd apps/ios && xcodebuild test -project CupSeason.xcodeproj -scheme CupSeason \
   -destination 'platform=iOS Simulator,name=iPhone 17 Pro')
```

The database evidence needs the isolated cluster at
`~/cup-season-gameplay/tests/sim/sandbox` (`apply.sh` builds it; it was running
on port 5470 for this work). Production was never used as a test sandbox.
