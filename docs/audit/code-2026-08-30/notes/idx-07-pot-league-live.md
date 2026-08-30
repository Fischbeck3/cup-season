# Slice 07 — `index.html:7459–8478` · pot, league setup, live round

Read: all 1,020 lines of the range, plus the call sites needed to judge them —
`openBuyInTerms` (5900–5922), the Pot markup (3515–3560), `.payer`/`.fine` CSS
(483–499), `resetWizard` (14538–14548), `applyBylaws`/`loadBylaws` (14845–14872),
`renderEmails` (12606–12621), the second pot-split renderer at 12566–12594,
`#gAdd` (9347–9356), `holeDone` (8481), `state` init (3812–3820).
Server side: `20260830040000_buy_in_terms.sql` (whole file),
`20260828170000_pot_two_numbers.sql` (`recompute_season_payouts` 41–120,
`mark_buy_in` 409–471), `20260728220000_visitor_rounds.sql`
(`my_visitor_rounds` 142–170), `20260728120000_live_sync.sql:184–220`.
Prod verified read-only: `league_settings` has no column-level ACLs (so
`select('*')` picks the two new columns up cleanly); the FK hint
`live_round_players_live_round_id_fkey` is the real constraint name;
`set_buy_in_terms` / `my_visitor_rounds` / `mark_buy_in` all exist in prod.

Session commits touching this range: `d41d2b7` (D126/D127/D129 — the pot rewrite)
and `47b1cda` (M-085 FK hint in the resume query). Those two hunks got the
hardest read.

---

## The pot arithmetic

**The trio now sums, but the headline number moved away from the engine.**
Q-28's fix (7497–7501) makes the champion absorb the rounding — correct
principle, wrong unit. It rounds in *dollars*; `recompute_season_payouts`
rounds in *cents* and then has the champion absorb. A $250 pot at 60/25/15:

| | champs | runner-up | king | sum |
|---|---|---|---|---|
| Pot tab (7499–7501) | **$149** | $63 | $38 | $250 ✓ |
| `recompute_season_payouts` | **$150.00** | $62.50 | $37.50 | $250 ✓ |

Before the fix the tab said $150 (right) and summed to $251 (wrong). After it,
the tab sums (right) and the biggest tile is a dollar light. Both are symptoms
of formatting a cent-denominated split in whole dollars. The fix is to keep the
split in cents and format it, not to reshuffle which tile eats the error.

Two collateral notes on the same hunk:

- `pc` (7484) is now destructured and never read. The champion's *percentage*
  no longer participates in the champion's figure — the tile is whatever is
  left over. Any league whose three payout columns don't total 100 hands the
  difference to the champ with no warning.
- The **same rule has a second producer** at 12590 (`#lineSplit`, the gold "On
  the line" bar), and it did **not** get the fix: it still prints
  `CHAMPS $150 · RUNNER-UP $63 · POINTS KING $38` for the same $250 pot. So the
  League Room now shows a golfer two different champ figures on two panes of the
  same room, and the surface Q-28 was actually filed against is unchanged.
  (Root is outside this slice — recorded here because it is the direct
  consequence of fixing one of two producers.)

**`invited` is dead weight in the money path.** 7477–7478 prices the pot off
`state.emails`. The wizard's email slots were removed by A-W2 (`renderEmails`
bails at 12607 because `#emailSlots` no longer exists in the markup), and
`state.emails` is only ever written by `resetWizard`, so `invited` is
permanently 0 and `Math.max(ms.length, invited+1, 1)` can only return
`Math.max(ms.length, 1)`. Not a live bug today — filed as dead code, because it
is a loaded gun: D106's owed number is defined as *buy-in × roster*
(decision-log:4181, and `pot_c := buyin_cents * n_members` in the engine), and
restoring any invite-staging surface would silently inflate the Pro's pot past
both the definition and the server without touching this line.

**Rounding / negative / zero on `fmt$`.** `fmt$ = n => '$'+n.toLocaleString()`
(3859). `total`, `runnerUp`, `king` are always non-negative integers here
(`state.payout` comes from three fixed segments or from `payout_*` columns), so
no `$-5`. `collected` can be fractional (`amount_cents/100`) and
`toLocaleString` caps at 3 fraction digits, which is safe for cents. `$0`
renders `$0`. No finding.

## `#payHow` and the role gate

The gate itself is sound: `isPro` (7481) reads `CS.member.role`, the edit link
is rendered only for the Pro, and `set_buy_in_terms` is `is_commissioner`-gated
at the database with an explicit `grant execute … to authenticated` (D37 kept).
`esc()` covers the note and the due date; `localDate()` is used for the date, so
the UTC-midnight landmine is avoided. Deploy skew is handled honestly — an older
database simply returns no such columns from `select('*')` and the box degrades
to "the Pro hasn't posted how to pay yet".

Three things are wrong around it:

1. `#payHow` is written **only** inside the `!state.demo && stake > 0` path. The
   demo diorama has `stake: 75` (3815), so the demo Pot tab is visible and its
   "How to pay" eyebrow sits over an empty paragraph — the one tile on that pane
   with nothing in it, on the surface a prospective Pro explores first.
2. The member's row stopped being a `<button>` but kept `class="payer"`, and
   `.payer` still carries `cursor:pointer` (487). D129's whole complaint was
   "the rows LOOKED tappable and refused everyone but the Pro"; they still look
   tappable, and the explanation that used to fire on the tap
   (`toast('The Pro marks buy-ins as money moves between you')`) was deleted in
   the same hunk. It is now a silent no-op instead of a refusal.
3. D129 asked for "the ✓ absent from the DOM when unpaid". It is present on
   every row and merely `color:transparent` (494), which does **not** remove it
   from the accessibility tree. VoiceOver reads an unpaid member's row as
   "Casey, check mark" — the inverse of the fact — and there is no "Not yet".

Also: the Pro's only route into the payment terms is a 13px inline `<a>` inside
a `.fine` paragraph, roughly 21px tall, two lines above a `.payer` rule that
sets `min-height:44px`. The pane knows the rule and doesn't apply it to the one
control that answers the audit's number-one question.

## `mark_buy_in`

Signature matches prod (`uuid, uuid, boolean`), grant present, `{error}` is
destructured and thrown (not dropped), and the failure path re-enables the row.
The season guard is duplicated verbatim on 7533/7534 — the fingerprint of the
`!isPro` line being replaced in place without removing the original.

The optimistic write at 7540 invents `amount_cents: state.stake*100` rather than
reading back what the RPC recorded, and the RPC's `on conflict do update` sets
only `paid` — it never re-stamps `amount_cents`. So a row first marked at one
buy-in keeps the old cents server-side while the client shows the new ones until
the next reload.

Copy: in a bragging-rights league 7467 writes `Bragging rights` into
`#paidCount`, which the markup wraps as `Buy-ins · <span>…</span> in` →
"Buy-ins · Bragging rights in".

## Live round

The sync layer holds up. Score clocks are epoch-ms on both sides
(`extract(epoch from s.client_ts) * 1000` at live_sync:220 ↔ `Number(s.cts)`),
wolf clocks are timestamptz on the wire and `Date.parse`d — I checked this
specifically because a type mismatch there would silently disable the reconcile
pull, and it is correct. LWW comparisons are `>=`-guarded in the right
direction. The M-085 FK hint names a constraint that really exists in prod, and
the two skew retries degrade the right columns.

**The one serious bug is an index of exactly zero.** Every resume path writes
`Number(x) || 18`, seven times. A scratch player's `0` is falsy, so a scratch
golfer or a scratch guest comes back from a refresh as an 18. `#gAdd` (9351)
already gets this right (`isNaN(gi) ? 18 : gi`), and `guest_index: 0` is stored,
so the round *starts* correct and the *resume* corrupts it — which is worse than
being wrong throughout, because nobody re-checks the card after a refresh. In
match play that moves the strokes-off-the-low-man ladder by ~20 strokes and the
settlement pays on it.

**The second is a false "already finished".** When a local snapshot exists but
the server list doesn't contain its id, 8226–8229 deletes every local snapshot,
resets `state.live`, and toasts "That round was already finished". Two ways to
reach that with a round that is still `live` on the server:

- the round is older than `LIVE_MAX_AGE` (8205). The comment says "Don't
  auto-resume it (the play view's 'Scrap this round' still closes it if they
  open it)" — but the code doesn't merely decline to resume, it destroys the
  local card, so they can't open it.
- `my_visitor_rounds` fails (8194–8200). The `catch(_){}` is documented as
  "fail-open: the member path stands on its own", but the member path *cannot
  see* a visitor's round — RLS on `live_rounds` is `is_league_member(league_id)`,
  which is the entire reason that RPC exists. For a visitor it is fail-closed,
  and the failure mode is "your round is gone and we told you it finished".

Smaller: `estimateSI()` is called with no argument on both resume paths, before
`holes` is known, so a resumed nine with no SI in its snapshot would rank 18
holes and under-allocate strokes. `buildLiveSnapshot` always writes a full
18-wide SI, so the branch is near-dead — recorded as a latent trap, not a live
bug.

Checked and clean: `courtSwap`'s pairing derivation (`{1:0,2:1,3:2}` matches
`PAIRINGS` exactly), `strokeOn`'s 19+-stroke wrap, `recomputeStrokes`'s
before/after-`state.live` double call on all three resume paths (deliberate and
correct — the second call is what makes a nine halve the handicap),
`renderResumeBanner`'s `k<18` loop against a 9-hole card (breaks at 9 because
the back nine is null), `courtDrag`'s listener lifecycle (fresh chips per
render, no accumulation, no orphaned ghost when `setPointerCapture` throws),
the `PRESETS` → `CAPS` → `PRESET_SUMMARY` copy chain (all three summaries match
the caps and floors they set, and the 100/95/90 allowances they promise really
are written at 15657/15700/15721), and `defaultStart()`'s
`((6 - d.getDay() + 7) % 7 || 7)` next-Saturday arithmetic.
