# App Review notes — paste into App Store Connect (IOS-027)

Written before submission, not after a rejection (runbook: "Rejection playbook").
Replace the two placeholders. Everything else is final copy.

---

## Sign-in for review

Email: `reviewer@cupseason.app`
Password: `<<REVIEWER PASSWORD>>` — the sign-in screen shows a password field
as soon as this address is typed (every other user signs in with an emailed
8-digit code. Sign in with Apple is built but is behind a flag that is off
in this build — see the 4.8 note below; there is no third-party login to pair
it against.)

**Before every submission (founder, from the terminal — the seed lasts until the next `reset`):**
```
# founder token via the emailed code, then:
curl -s -X POST https://zddbfcokmvneltrgukzf.supabase.co/functions/v1/test-seed \
  -H "apikey: <publishable key>" -H "Authorization: Bearer <founder token>" -H "Content-Type: application/json" \
  -d '{"action":"seed","target_email":"reviewer@cupseason.app"}'
```
The reviewer profile's card must be set or the account lands on the card gate (done 2026-08-28: `Sam Reviewer · @reviewer · The Saguaro · Phoenix, AZ`; re-apply with `update profiles set display_name='Sam Reviewer', handle='reviewer', marker='saguaro' where email='reviewer@cupseason.app'` if it is ever cleared).

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
   **Please do not complete the deletion on this account** — it is the review
   account and the flow is real, not a demo. This account has posted rounds, so
   it takes the tombstone branch: the profile is anonymised and the login is
   banned permanently, which would end your session and cannot be undone from
   our side inside a review window. The confirm screen states exactly what the
   flow does; that screen is the thing to inspect. If you need to see it
   complete, tell us and we will provide a second throwaway account.
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
keeps the books. Buy-ins and payouts move friend-to-friend."). The review
account's league, Sunset Match, keeps a $450 pot so you can see the ledger
itself; a league can also run with no pot at all ("bragging rights").

## No in-app purchases

There are no purchases, subscriptions, or links to purchase anything in the
app. Every golfer's profile, index and record are free. A league's first year
is free; a future season pass (paid on the web by the league's organiser) is
described on one informational screen and is not sold in the binary.

## User content and safety (1.2)

Three things, all in the app:

1. **Report** — every board post has a Report action; a golfer's photo can be
   reported from their Tour Card; comments on posts and on rounds are
   reportable. All of it goes through the `report_content` RPC.
2. **Block** — **Mute** on any golfer's Tour Card. A muted golfer's posts,
   comments and round comments all disappear from the muter's surfaces; the
   filter is enforced in the database's row-level security, not in the client.
3. **Act** — reports land on the founder's desk with two actions on each:
   **Take it down** (`hide_content`, which removes the post from every reader's
   view and records who hid it and why) and **Leave it up**, which closes the
   report. A new report also pushes a notification to the founder, so it is
   seen rather than queued. Reports are actioned within a day.

Terms and privacy are linked from the sign-in screen and Settings.

## Account deletion (5.1.1(v))

Settings → Danger zone → **Delete account** — in-app, immediate, one tap and a
confirm. Exactly what it does, because a golfer with a season's history cannot
be erased the same way a brand-new signup can:

- **A golfer with no posted rounds** is deleted outright: profile, posts,
  comments, photos, device tokens and the auth record all go.
- **A golfer who has posted rounds** keeps those rounds, because other people's
  standings, settled matches and pot ledgers are computed from them and would
  silently change if they vanished. Everything that identifies the person is
  removed in the same transaction: name, handle, city, home course, marker,
  GHIN, **profile photo and every image they uploaded**, and the email address,
  which is replaced with an unroutable `@cupseason.invalid` tombstone that every
  send path already excludes. Push tokens — APNs and web — are deleted, so the
  phone stops. Discovery is set to nobody and the auth record is banned, so the
  account cannot be signed into again. What remains is an anonymous "Former
  member" attached to scores, with nothing that points back to a person.

The app says this in the confirm, rather than promising an erasure it cannot
perform without corrupting other people's seasons.

## Sign in with Apple (4.8)

**4.8 does not apply to this app.** It governs apps that offer a third-party or
social login service. Cup Season offers exactly one way in — an 8-digit code
emailed by us — and no Google, Facebook, Twitter or other third-party sign-in
anywhere. There is no login service to pair Sign in with Apple against.

Sign in with Apple is nonetheless implemented and ships in this binary behind
the `ios.apple_sign_in` flag, which is currently off. If it is switched on it
appears on the sign-in screen beside the emailed code.

## Age rating

No gambling and no real-money gaming: the app has no payment rail of any
kind and never touches the money (see the pot note above).

**Contests: yes — expected 13+.** Cup Season is a season-long competition with
a standings table, a Cup Final and a champion, and Apple's current
questionnaire (the July 2025 revision) asks about that directly. Answering
"none" would be answering the retired form. The reasoning is written out in
`docs/ios/app-store-listing.md` §6.

---

## If review comes back (the playbook, native edition)

| If review says | Answer with |
|---|---|
| 5.3.4 real-money gaming | The paragraph above, verbatim; point at Clubhouse → Pot. Offer a screen recording of the ledger. |
| 2.1 incomplete / cannot evaluate | The reviewer landed in an empty state: the account is re-seeded (`test-seed` with `target_email`) and the walkthrough re-sent. |
| 1.2 UGC safety | Report + Mute paths above; `report_content` and `set_mute` are server RPCs, reachable from every post and member sheet. |
| 5.1.1(v) account deletion | In-app path above; `delete_account` RPC. |
| 4.8 Sign in with Apple | Does not apply: 4.8 governs apps offering a third-party or social login, and the only way in is a code we email. Point at the 4.8 note above. |
| 4.2 minimum functionality | Not a web wrapper: native SwiftUI, APNs push with lock-screen actions, camera scan, share sheet, MetricKit, universal links, live-round sync with an offline queue. |
