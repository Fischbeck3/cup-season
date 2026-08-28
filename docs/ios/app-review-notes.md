# App Review notes — paste into App Store Connect (IOS-027)

Written before submission, not after a rejection (runbook: "Rejection playbook").
Replace the two placeholders. Everything else is final copy.

---

## Sign-in for review

Email: `reviewer@cupseason.app`
Password: `<<REVIEWER PASSWORD>>` — the sign-in screen shows a password field
as soon as this address is typed (every other user signs in with an emailed
8-digit code; Sign in with Apple is also offered).

The reviewer account is pre-loaded with a season in progress: a league of
eight golfers, standings, a board with posts, a settled live game with its
scorecard, and a Ryder-style event. Nothing in it is a real person.

## Walkthrough (5 minutes)

1. **Home** — the standing hero ("2nd · 10 points back"), the buddies' feed.
   Tap a round card → the round receipt: every point traces to the rounds that
   produced it.
2. **Clubhouse** — the league room: standings, the climb, the board (chat +
   posts), the schedule, the album. Tap "Standings" rows for receipts.
3. **⊕ Post** — post a round: pick a course (search), type front and back
   nines, or "Enter your card" for hole by hole. Post → the finish ceremony.
   (Posting from the review account is fine; it's a sandbox.)
4. **⊕ Play now** — the live tee sheet: match play / Wolf / skins, scored
   hole by hole; finish → the settlement card and the share sheet.
5. **You** — the golfer's card, trophies, the record. Settings → Appearance,
   Palette, Notifications, and **Delete account** (in-app, Guideline 5.1.1(v)).
6. **Push** — Settings → Notifications → Enable on this device. A board post
   from another member arrives as a routed notification (tap → the board).

## About "the pot" (Guideline 5.3.4 — please read)

Cup Season is a season-long points game between friends who already play
golf together. Some groups keep a friendly pot for the season; **the app
never handles money.** There is no wagering, no deposit, no payout, no
contest run by Cup Season, and no money moves through the app or any payment
rail. The app keeps a *ledger* — who has paid the group's organiser and who
is owed — exactly like a shared spreadsheet, and the group settles among
themselves outside the app. The screen is **Clubhouse → Pot** ("Cup Season
keeps the books. Buy-ins and payouts move friend-to-friend."). A league can
also run with no pot at all ("bragging rights"), which is what the review
league does.

## No in-app purchases

There are no purchases, subscriptions, or links to purchase anything in the
app. Every golfer's profile, index and record are free. A league's first year
is free; a future season pass (paid on the web by the league's organiser) is
described on one informational screen and is not sold in the binary.

## User content and safety (1.2)

Members can report any post or member (**Report** on the member sheet and on
every post) and mute any member (**Mute**). Reports land on the founder's desk
and are actioned within a day. Terms and privacy are linked from the sign-in
screen and Settings.

## Account deletion (5.1.1(v))

Settings → Danger zone → **Delete account** — in-app, immediate, removes the
profile, rounds and device tokens.

## Sign in with Apple (4.8)

Offered on the sign-in screen alongside the emailed code. No other third-party
login exists.

## Age rating

No gambling, no real-money gaming, no contests. Expected 4+.

---

## If review comes back (the playbook, native edition)

| If review says | Answer with |
|---|---|
| 5.3.4 real-money gaming | The paragraph above, verbatim; point at Clubhouse → Pot. Offer a screen recording of the ledger. |
| 2.1 incomplete / cannot evaluate | The reviewer landed in an empty state: the account is re-seeded (`test-seed` with `target_email`) and the walkthrough re-sent. |
| 1.2 UGC safety | Report + Mute paths above; `report_content` and `set_mute` are server RPCs, reachable from every post and member sheet. |
| 5.1.1(v) account deletion | In-app path above; `delete_account` RPC. |
| 4.8 Sign in with Apple | Present. |
| 4.2 minimum functionality | Not a web wrapper: native SwiftUI, APNs push with lock-screen actions, camera scan, share sheet, MetricKit, universal links, live-round sync with an offline queue. |
