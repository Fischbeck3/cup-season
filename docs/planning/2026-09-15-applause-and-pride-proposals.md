# Proposals held open from the phone-fixes sprint · 2026-09-15

Three decisions the sprint deliberately did **not** take. Each is a mechanics or
policy change to a contract that exists today; each is written here so the
owner can decide it as itself, with the migration and the risks named. Nothing
in this file is built, applied or activated.

What IS built and shipping on the sprint branch: the applause control on both
clients over the existing `post_kudos` row (D365), and the pride-bet composer
that says what it is (D366). Both work against production as it stands.

---

## §1 · Applause: one per golfer per ROUND, and the historical reactions

### Today's contract

`post_kudos(post_id, profile_id, emoji)`, primary key on all three. A round
fans into one `posts` row per league (`round_to_board`), so the same round can
carry applause on two posts from the same golfer, and a viewer in one league
sees one post's count. Both clients fold counts client-side from
`select * from post_kudos where post_id in (...)`. The four retired tokens
(`azalea`, `jug`, `eagle`, `rake`) sit in rows written before 2026-09-15; rows
from before D309 were folded to `azalea` by `20261017090000`. Nothing on the
server counts, and nothing notifies.

### Proposal A · fold applause to the round on the server

One migration, `NNNN_applause_is_one_per_round.sql`:

1. **Identity.** Add `round_id uuid` to `post_kudos`, filled by the
   `post_kudos_home()` trigger from `posts.round_id` on insert (nullable: chat
   posts have none). Backfill existing rows from their posts.
2. **The rule.** A partial unique index
   `(round_id, profile_id) where emoji = 'applause' and round_id is not null`.
   A second applause on another copy of the same round is refused (23505),
   which both clients already treat as "already yours" by re-reading.
3. **The read.** A `security invoker` view `v_round_applause(round_id, n,
   actors jsonb)` counting distinct `profile_id` across every copy the viewer
   can read, so the count is the same number on Home, the board and the
   receipt regardless of which post is under the thumb. `round_card` gains
   `applause_n` and `applause_mine`; `home_dispatch` is untouched.
4. **Deletion.** Removing applause deletes every copy for that `(round_id,
   profile_id)` — one act, not one per league.
5. **Grants.** The view to `authenticated` only; no anon; the table's RLS
   unchanged.

Client change after the migration: read `v_round_applause` where the fold is
built today; write stays `insert/delete` on `post_kudos` with the post the
viewer is on. No new RPC. The Kit's `Applause.state` gains the served count.

### Proposal B · what to do with the four historical tokens

Options, with the recommendation last:

- **Leave them (the sprint's default).** Rows stay; the people list notes
  "N earlier reactions, from before applause"; the count is applause only.
  Honest, no data loss, no migration. Cost: a round applauded under the old
  menu shows 0 applause and a footnote.
- **Delete them.** Rejected — §16 keeps what people did.
- **Sum them casually.** Rejected — four taps by one golfer would count as
  four; the count must be people, not rows.
- **Convert, one per golfer per round (recommended).** In the same migration:
  for each `(round_id, profile_id)` with any historical token and no applause
  row, insert ONE applause row with `created_at` set to the earliest of that
  golfer's historical rows. Keep the historical rows (they are the record of
  what was said). The people list keeps its footnote for a season, then it can
  go. **This backfill must never notify**: no `posts` insert, no `push_nudges`
  row, and the digest reads `created_at`, which is set in the past.

### What it needs from the owner

Yes/no on A; a choice on B. Both are idempotent and reversible (drop the
index, the view and the column; the applause rows stand). Neither is required
for the control to work — it works today.

---

## §2 · Applause notifications (nothing is activated)

### Today

The `push` Edge Function is driven by `posts` inserts and `push_nudges`. It has
never handled `post_kudos` and still does not. The only surface for applause
is in-app: the Home digest's "Alex and 2 others applauded your round" and the
realtime nudge that re-pulls the strip.

### Proposal

- **Opt-in, per golfer**, under Notifications as "Applause on your rounds",
  default **off** for existing golfers, asked contextually the first time a
  golfer's round receives applause from someone else (L-20: the ask is never
  on launch).
- **Grouped and batched.** One notification per round per window:
  "Alex applauded your round" on the first; "Alex and 2 others applauded your
  round" replaces it (same `collapse_id = round_id`) rather than stacking. The
  window is 30 minutes; at most one delivery per round per day; never for
  your own tap, never for an undo or a re-add, never for a retry, never for a
  backfill (§1B), never for a golfer who has muted you or whom you have
  blocked, never for a round you can no longer see.
- **Mechanism.** A `push_nudges` row of kind `applause` written by a
  scheduled job (`pg_cron`, every 5 minutes) over `post_kudos` rows newer than
  the last run, grouped by round — not a trigger per row. The Edge Function
  gets one new kind with `thread: 'you'` and the round as the route, no
  category (not actionable from the lock screen).
- **Undo.** A removed applause inside the window cancels the pending nudge
  (delete the `push_nudges` row); after delivery nothing is retracted.
- **Audience and mutes** reuse `push_mutes`/the existing per-kind flags; no
  new table beyond a `notified_at` on the grouped row.

### What it needs from the owner

Whether applause should push at all (L-22 leans no; the digest may be enough),
and if so the window and the daily cap. Until decided, in-app only.

---

## §3 · Pride agreements: acceptance and competition-backed settlement

### Today (record-only, by design — D64/D242/D299)

`create_forfeit` records parties and prose (`name`, `terms`, `hangs_on`,
`kind`) homed on a league, an event, a plan, or on the two golfers. Creation
does not ask the other golfer; `settle_forfeit` lets a party (or the Pro)
name the winner by hand; nothing scores, nothing notifies (L-20/L-22). The
sprint's composer now says all of this out loud (D366).

### Proposal · an agreement with a lifecycle, attached to a competition

- **Entry from a person selects the context first**: an existing clash this
  week, a planned round you are both in, the season you share, or "just
  between us". Only then: what is on the line.
- **Lifecycle.** `proposed → accepted | declined | cancelled → settled |
  disputed`. New columns on `forfeits`: `status` gains `proposed`, `declined`
  and `cancelled` (today: `open | settled | scrapped`); `accepted_at`,
  `accepted_by`; `decided_by` (`'tap' | 'clash' | 'plan' | 'event'`).
- **Acceptance.** The other party accepts or declines on their own phone
  (`respond_forfeit(p_id, p_accept)`), the same shape as `respond_callout`.
  Until accepted the record reads *Proposed — waiting on Alex*, appears only
  to the two parties, and settles nothing. A decline leaves no mark on the
  decliner (L-22): the proposer sees "Passed", nothing is posted.
- **Settlement.** Where the context is a scored competition (a week's clash,
  a callout's session, an event with a result), the result **fills the winner
  automatically** when that competition settles (`settle_week_clash`,
  `close_event_session`), and the record says "decided by the clash". Where
  it is not (a plan, "between us"), either party proposes a result and the
  other confirms; a disagreement marks it `disputed` and it waits for the Pro
  or a joint tap. No engine ever awards it from a handicap comparison it did
  not run.
- **Edit / cancel.** The proposer may edit terms or cancel until accepted;
  after acceptance, cancelling needs both taps. A correction after settlement
  reopens to `disputed` with a note, never silent.
- **Notifications.** A proposal is the one legitimate nudge (a seat-shaped
  ask: "Alex proposed a pride bet — Winner picks the next course"); accept,
  decline and settlement are in-app only. Opt-in like §2.
- **Existing records** keep `open`/`settled`/`scrapped` and are treated as
  accepted-by-construction; nothing is rewritten.

### What it needs from the owner

This is a mechanics decision (D-level), not copy: whether pride bets become
two-sided at all; whether a scored competition may settle one automatically;
who resolves a dispute. Until then the record-only composer stands, and it
says so.
