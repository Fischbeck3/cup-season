# League cancellation with consent (D71) — design

**Date:** 2026-07-24
**Status:** design, pending owner review
**Motivation:** A pilot Pro wants to cancel a league that has already started.
The current `delete_league` refuses any started league ("a live league cannot
be deleted") and is commissioner-only — correct, but it leaves no path to end a
league once it's under way. This adds that path, gated by consent when money is
on the line, and drops brand-name payment references while we're in the money
copy.

---

## Decisions (settled in brainstorming)

1. **Who initiates:** the Pro (commissioner) only. Matches `delete_league`.
2. **Consent bar — strictness tracks the money:**
   - **Free league** (no buy-in configured): the Pro cancels alone, immediately.
   - **Money league** (buy-in > 0): every member must approve. **Unanimous.**
3. **On any decline the request dies.** One "no" withdraws it; the Pro may open
   a fresh request later, or withdraw an open one themselves. No lingering
   request a holdout can freeze.
4. **Cancel = full removal.** League, season, memberships, buy-ins, squads,
   board posts, and scheduled rounds tied to the league are deleted — like it
   never happened. Every player's actual golf **rounds survive on their
   profile** (rounds are global; the league is only a lens). The Pro lands on a
   "Start another league" prompt.
5. **Refund notice (D39-safe):** the pot never moved — buy-ins are a ledger. A
   cancellation has no winner, so each member is owed **their own paid buy-in
   back**. No settlement math. The app moves nothing; it posts a notice.
6. **Cancellation email:** a money-league cancellation also emails each member
   their refund amount — a durable off-app record — via the existing D68
   season-email channel with a new kind.
7. **Venmo drop (bundled):** one pass over every "Venmo" mention (settlement
   card, ceremony, season-email, older SQL post generators) → generic settle-up
   language. D39 wording, no brand name.

## Open item — deferred (NOT built here)

**Pro membership / season pass.** Stripe is parked; no league is charged today,
so cancelling one has zero payment to reconcile now. When the season pass goes
live (Pro pays out of the pot), the principle to hold is **the pass follows the
account, not the league** — a credit the Pro carries — so cancel-and-restart
never burns it. That is exactly what the "start another league" prompt is for.
Logged as an open monetization item for the Stripe design; no refund path is
built for a charge that doesn't exist.

---

## Architecture

### Data model
- **`league_cancellations`** — one open request per league.
  `league_id uuid pk references leagues(id) on delete cascade`,
  `requested_by uuid`, `requested_at timestamptz default now()`.
  RLS on, no policies (definer-only; the RPCs are the sole path).
- **`cancellation_votes`** — per-member approvals.
  `league_id uuid`, `member_id uuid`, `voted_at timestamptz default now()`,
  pk `(league_id, member_id)`, `league_id references leagues(id) on delete cascade`.
  (A row exists only for an approval — a decline never records a vote; it kills
  the request.)
- **`cancellation_notices`** — a **self-contained snapshot** of the refund
  breakdown, written BEFORE the league is deleted so the async email never reads
  deleted data. `id uuid pk`, `payload jsonb` ({league, recipients:[{email,
  name, cents}]}), `created_at`, `sent_at`, `error`. **No FK to leagues** — it
  must outlive the deletion. Its own INSERT webhook drives the send.

### RPCs (all SECURITY DEFINER; grants explicit per D37; new authenticated RPCs
added to `tests/db-checks.sql` check 3 in the same commit)
- **`request_league_cancel(p_league)`** — commissioner-gated.
  - Refuses `phase='complete'` (the record book — keep `delete_league`'s rule).
  - `money := (league_settings.buyin_cents > 0)`.
  - **No money →** perform the cancel routine inline. Returns `'done'`.
  - **Money →** upsert an open `league_cancellations` row, clear any prior
    votes, and record the Pro's own approval (initiating IS approving). Returns
    `'open'`.
- **`vote_league_cancel(p_league, p_approve)`** — member-gated
  (`is_league_member`); requires an open request.
  - `p_approve=false` → **request dies**: delete the `league_cancellations` row
    and its votes. Returns `'declined'`.
  - `p_approve=true` → record the vote (`on conflict do nothing`). If **all**
    current members have now approved → run the cancel routine inline. Returns
    `'done'`; otherwise `'pending'`.
- **`withdraw_league_cancel(p_league)`** — commissioner-gated. Deletes the
  request + its votes. Returns `'withdrawn'`.
- **`league_cancel_status(p_league)`** — member-readable; returns the open
  request (if any) + who has approved + the caller's own refund amount, so the
  client can render the consent screen and the "3 of 5 approved" progress.

### The cancel routine (internal, ordered so the email survives deletion)
1. Build the refund snapshot: for each member with a real address, `{email,
   name, cents = their paid buy-in}` + the league name.
2. Insert one `cancellation_notices` row with that snapshot (fires its webhook →
   the send function, self-contained payload).
3. Delete the league (cascades season, memberships, buy_ins, squads, posts,
   scheduled rounds, the cancellation request + votes).
   Players' `rounds` are untouched (no FK from rounds to leagues).

### Edge function
Extend `season-email` (or a sibling) to handle the `cancellation_notices`
webhook: read the row's self-contained `payload`, send each recipient their
refund email, `mark` the row sent. Bot/placeholder addresses already filtered in
the snapshot step (reuse the season-email address filter). A sandbox league
never mails anyone (same fence).

## Data flow (money league)
Pro taps "Cancel league" → `request_league_cancel` opens the request (Pro
auto-approves) → each member sees the consent screen (their refund + progress)
via `league_cancel_status` → members `vote_league_cancel(true)` → the final
approval triggers the cancel routine → snapshot written + emails fired → league
deleted → every member's app drops the league, the Pro sees "Start another
league". Any `vote_league_cancel(false)` ends it immediately.

## Client
- **Founder desk / League room (Pro):** a "Cancel this league" control
  (replaces / extends the existing "Cancel & delete" affordance, which today
  only shows pre-first-tee). For a money league it opens the request; for a free
  league it confirms and cancels inline.
- **Consent surface (members):** when an open request exists, a card/sheet — "The
  Pro wants to cancel [league]. You get back $X. Approve / Decline" + progress.
- **Skew-safe:** new RPCs/columns get the client's retry-on-any-error; the
  consent card only renders when `league_cancel_status` returns a request.

## Error handling
- Non-commissioner calling request/withdraw → "commissioner only".
- Voting with no open request → clean "nothing to vote on" (skew-safe).
- `phase='complete'` → refuse (record book).
- Email send best-effort: a Brevo failure is logged on the notice row; the
  cancellation still completes (the in-app consent screen was the primary
  record). Never blocks the deletion.

## Testing
- Free league: Pro cancels alone, no request, no email, league gone, rounds
  survive.
- Money league: request opens; a decline kills it; unanimous approve deletes it
  and fires one email per member with the right refund; the notice snapshot
  matches each member's paid buy-in and the parts equal the pot.
- Non-Pro cannot request/withdraw; a non-member cannot vote.
- Completed league refuses.
- Sandbox league cancellation mails no one.
- `tests/db-checks.sql`: new authenticated RPCs in check 3; no new anon surface.

## Venmo drop (bundled, separate commit)
Grep every `VENMO` / `Venmo` across SQL post generators and `index.html` +
`season-email`; replace with generic settle-up copy ("settle up between
yourselves", "the Pro collects the pot"). `close_season`'s pot line already
reads "settle between yourselves" (D66) — bring the rest in line.

## The "Who's the bitch?" deletion (the trigger for this)
Do NOT delete blindly. Session context ties league `e29dc147` "Who's the bitch?"
to real pilot activity (the pilot-feedback CSV originated there). Before any
cancellation: verify the members, rounds, and buy-ins live, and confirm with the
owner that the data is genuinely disposable. The Pro of that league (not
Jerecho, who is a player) must drive the cancel — or, once built, the owner
consents through the new flow. If it turns out to be genuinely empty/test, the
new `request_league_cancel` is the path.
