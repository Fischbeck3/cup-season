# App Review notes — paste into App Store Connect (IOS-027, rewritten 2026-10-01)

**Status: DRAFT for the owner. Not pasted.** This replaces the 2026-09-04 notes. Those
pointed at Sunset Match, which finished on 2026-09-05. They called Block "Mute",
quoted a pot sentence the app no longer prints, and named a "Danger zone" that does
not exist.

The block between the rules below is the paste for the **Notes** field. Apple's
limit is 4,000 bytes; check the count before pasting. The reviewer password goes
**only** into App Store Connect's sign-in fields. It never goes in this file, a
handoff or chat.

**Before pasting, all of these must be true. Each is a separate check:**

1. **The database deploy is live.**
   - Required: migrations `20261221090000`, `20261222090000` and `20261223090000`, plus the `scan` function redeployed.
   - Without them, the filter, the golfer report, photo takedown, removal and the server-side scan-consent check described below do not exist in production.
2. **The figures are re-read on the final build.**
   - Ridgeline Cup's figures come from seed data and move as it ages.
   - Read every number in the app on the final build. Never quote seed arithmetic.
3. **The reviewer sign-in works.** Confirm `reviewer@cupseason.app` signs in with its password on the Release build.
4. **Counsel's position is recorded.** No counsel opinion is claimed (D402). Nothing below says the pot is exempt from anything.

---

```
SIGN-IN
Use the sign-in details in the App Review Information section. After typing reviewer@cupseason.app, a Password field appears ("Review access"). Every other golfer signs in with an 8-digit code we email. There is no third-party or social login, so 4.8 does not apply.

WHAT THE ACCOUNT HOLDS
Four leagues of fictional golfers; the reviewer is a player, not the organiser ("the Pro"), in each. Please use Ridgeline Cup, which runs to December 19, 2026.

FIVE-MINUTE WALKTHROUGH
1. Home: the current story of the reviewer's season.
2. Compete > Ridgeline Cup: the table. Tap a golfer to see the rounds behind their points; tap a round for its receipt. "Open the Book" shows the season week by week.
3. In Ridgeline Cup, scroll to "The pot" > "Who has paid": the ledger described below.
4. Play (the centre button) > "Add a round you played": course, tees and score; posting is fine.
5. Play > "Score it live": Match play, Wolf, Skins, Sunningdale or just the score, hole by hole; "Finish the round" shows the card.
6. Golfers > any golfer > the ••• menu: Report and Block.
7. You > Settings > "Your account" > "Delete my account" (see below; please don't confirm on this account).

THE POT
Some groups keep a season pot. Cup Season keeps the ledger; the money moves between friends. The organiser records each golfer's buy-in (up to $200) and who has paid. A live game can record an optional amount per skin or point (up to $200), and its card shows the totals. Cup Season and Fischbeck3 LLC do not collect, hold, transfer or pay out money, take no fee, and offer no purchases. A pride bet is a forfeit in words, with no money. A league can play for bragging rights only ($0). The legal page's "The pot" section says the same and that Apple is not a sponsor.

USER CONTENT AND SAFETY (1.2)
- Filter: names, posts, comments, plans, league names and pride-bet wording are checked by our database against slurs, explicit sexual terms and threats before they are saved; refused text stays in the golfer's draft with a clear sentence. No AI service is used for this.
- Report: board posts, comments and golfers (with a reason).
- Block: blocked golfers' posts and comments disappear for you, and their requests, invites and notifications to you are refused by the server.
- Act: every report sends a push notification to the operator, who reviews within 24 hours and can take down posts, comments and photos (round and profile, including shared copies) and remove an account. A removed account cannot sign in, post or contact anyone, including from a session that was already open.
- Contact: the support page and email, linked in the app.

ACCOUNT DELETION (5.1.1(v))
You > Settings > "Your account" > "Delete my account" > "Delete permanently". The confirm screen says exactly what happens: name, email, profile, posts, comments and shared links are removed; photos are queued for removal; notifications stop; the login is closed for good. Posted rounds stay as "Former member" so other golfers' standings don't change. Organisers of a league with other golfers are asked to hand it off first; the review account is not an organiser. Please don't confirm on this account; we will provide a throwaway account on request.

AI PROCESSING (5.1.2)
The only AI use is the optional scorecard scan. When a golfer taps "Scan the scorecard", the app asks "Scan with Claude?" first; only after a yes saved to their account does our server send that photo to Anthropic's Claude to read the scores (not used for training). Scanning can be turned off in Settings. A scanned card is attached to the round as its photo, which the golfer can remove before posting; the composer says golfers in their seasons and their buddies will see it.

PRIVACY
Find-friends sends one-way hashes only when the golfer taps "Check my contacts"; unmatched hashes are not kept. No ads, tracking or in-app purchases.
```

---

## Notes for whoever pastes this (not for Apple)

**Rejection playbook:**

| If review says | Answer with |
|---|---|
| 5.3 / 5.3.4 real-money gaming | The THE POT paragraph above, verbatim; offer a screen recording of the ledger. No exemption claim, and no counsel claim (D402). |
| 1.2 UGC | The safety paragraph. The filter is `cs_text_guard` (migration `20261221090000`). Takedown and removal are `takedown_photo` / `ban_account` (`20261222090000`). |
| 2.1 cannot evaluate | Re-read Ridgeline Cup on the build. **Do not reseed:** `test-seed`'s reset removes every seed-domain league, not only the reviewer's. |
| 5.1.1(v) deletion | The deletion paragraph; the `delete_account` RPC. |
| 5.1.2 AI sharing | The AI paragraph. The server-side check is in `supabase/functions/scan/index.ts`, and `tests/edge-security-courses-scan.test.mjs` proves zero provider calls without consent. |
| 4.8 | The only way in is a code we email (our own account system). Sign in with Apple ships behind `ios.apple_sign_in`, which is off. |

**What these notes deliberately do not claim:**
- photo screening before publication (unresolved; see the package)
- counsel approval
- instant photo erasure

**Contacts detail (D251).** The phone hashes normalised emails and phone numbers with plain SHA-256 (`ContactHash.swift`), and the server applies a pepper. The hashes are compared once and never stored. The stored buddy list is linked to the golfer. The iOS permission string and the onboarding screen ("a scrambled version") describe the same flow.
