# Pricing integration plan — visible model, no checkout (eng handoff)

Filed 2026-07-21 by the pricing arc (task #41) · **written, not built** —
this is the handoff an eng lane executes in about half a day. Governed by
**D56** (visible model at iOS launch, checkout waits for season 2).
Companion artifacts: `spec/pricing-discovery-2026-07.md` (the analysis) ·
`spec/handoffs/pricing-deck.html` (mockups + final copy voice).

**Line references** below are against v23.163-era `index.html` — re-anchor
by the quoted strings, not the numbers, if the file has moved.

---

## 0. Laws for the build

- **Zero mechanic changes.** Copy + one `app_flags` key. No schema for
  leagues, no checkout, no Stripe.
- **Voice:** priced against the pot, plain language, "the Pro," never
  SaaS-per-month. D47 nouns (crew, the books). Numbers speak per-head
  ("about $6.60 a player"), never % of pot (small-pot framing disaster —
  discovery §1.4).
- **D39 separation, visible everywhere:** the pass is paid TO Cup Season;
  the pot is never held BY it. The two never share a sentence's subject or
  a card's line. Pot figures may wear gold (earned); **the pass never
  wears gold** — plain ink numerals, brand-green banners/CTAs only.
- **First-season-free leads every surface.** The price is context; the
  gift is the message at launch.
- **The app's front door stays pricing-free** (D56 upholds). No pricing
  copy on splash, sign-in, or the join covenant.
- **Demo mode is a diorama:** demo renders State B (free season) with
  static copy; gate every real read with `!state.demo`.

---

## 1. The `app_flags` key — flip messaging without a deploy

Mirrors the `scan` precedent (`index.html:4889` —
`window.sb.from('app_flags').select('value').eq('key','scan').maybeSingle()`).

**Key:** `pricing` · **seed value:**

```json
{
  "visible": true,
  "anchor_cents": 7900,
  "bands": [
    { "max_roster": 9,  "cents": 4900 },
    { "max_roster": 13, "cents": 7900 },
    { "max_roster": 99, "cents": 9900 }
  ],
  "season1_free": true,
  "founding": { "cap": 10, "closed": false, "ids": {} }
}
```

- `visible:false` reverts every pricing surface to today's copy in one
  flag write — the no-deploy kill switch D56's "owner ships the copy"
  posture wants.
- `anchor_cents` may be re-pointed after the focus-group script closes
  the price (49/79/99 stay the band frame; discovery §1.6).
- `founding.ids` maps league UUID → badge number (`{"<uuid>": 1}` for
  PIGL). At ≤10 leagues a flag map beats a schema change; graduate to a
  `leagues` column only if the cap ever lifts (it shouldn't — the cap is
  the marketing).
- **Migration** (new file, timestamp-named): `insert into app_flags
  (key, value) values ('pricing', '…') on conflict (key) do update set
  value = excluded.value;` — confirm the existing `app_flags` SELECT
  policy covers `authenticated` (scan's read works in prod, so the
  table policy exists; nothing new to grant — it's a table read, not an
  RPC).
- **Client read** happens module-side (where `sb` lives); bridge to the
  classic renderers via `window.CS.pricing = value` **before** first
  render or guard every classic reference with `window.CS?.pricing?.` —
  the classic boot chain runs ahead of the module (landmine list).
  **Deploy-skew + missing-key default:** if the key is absent or the read
  fails, render as `visible:false` (today's copy). Never block boot on it.
- Per-league derived helper the surfaces share:
  `passFor(roster) → first band with roster ≤ max_roster` · `perPlayer =
  cents / roster` formatted "$6.60 a player" (2 decimals under $10,
  else round).

---

## 2. Copy insertions, surface by surface

### 2a. Create wizard · stakes step (launch)

**Anchor:** the Buy-in dial block — `<div class="lab">Buy-in<small>Per
player · $0 = bragging rights…` (`index.html:2440`) — insert the pass
card AFTER the pot preview, BEFORE the pot-split eyebrow (`<div
class="eyebrow">The pot split` at `:2477`).

Card (mockup: deck slide 5):

> **THE SEASON PASS** *(eyebrow)*
> One pass, whole league, all season — **$79** · ≈ $6.60 a player · one
> line on the buy-in
> 🟩 **Your first season is free.** The pass starts if you run it back.
> *(fine)* **Where the money goes:** the pass is paid to Cup Season. The
> pot never is — buy-ins and payouts move friend-to-friend, and the app
> keeps the books so nobody argues at the bar.

- Numbers live: `passFor(rosterEstimate)` — the wizard's roster-aware
  structure step already knows expected crew size; recompute on roster
  and buy-in changes. $0 buy-in swaps the per-player line to the
  bragging-rights framing ("split it on Venmo — less than a sleeve
  each"; discovery §1.5), never hides the card.
- Also extend the existing `#ih-payout` help (`:2478`) last sentence —
  after "money moves on Venmo" append: "The season pass is separate —
  paid to Cup Season, never out of the prize money."

### 2b. You tab · Membership & billing (launch)

**Anchor:** the existing stub at `index.html:9123–9125`:

```html
<div class="eyebrow" ...>Membership &amp; billing</div>
<div class="byrow"><span>PLAN</span><b>FREE · PILOT</b></div>
<p class="fine" ...>Cup Season membership lands at launch. Nothing to pay during the pilot.</p>
```

Replace with the three-state membership card (deck slide 6):

- **State A — Founding** (`founding.ids[leagueId]` present): gold badge
  `★ FOUNDING LEAGUE № {n}` · "*{League}* — free forever." · "One of the
  ten. Thanks for building this with us."
- **State B — free season** (default at launch): "*{League} · Season 1*
  — **This season is free.** Every league's first season is on us." +
  chips: `After season 1 · $79/season` · `≈ $6.60 a player` · `Paid by
  the Pro, from the pot`.
- **State C — paid** (post-checkout, FUTURE — ship the markup dark
  behind the flag or omit until the Stripe phase): "Season pass · paid
  through {date} · $79 · renewed by {Pro name} (the Pro) · from the pot."
- Constant footer line, all states: "**Your golfer profile is free
  forever.** Index, record, rounds — yours for life, in any league or
  none."
- Multi-league members: one row per league, State per league.
- `visible:false` → render today's PLAN stub unchanged.

### 2c. League Room · pot pane, Pro view (launch)

**Anchor:** `#room-pot` (`index.html:2687–2708`); insert the pass block
after the Season-stakes card, and extend the fine print at `:2701`.

Pro-only card (deck slide 7):

> **SEASON PASS · PRO ONLY** *(eyebrow)*
> **Season 1 — free.** ~~$79~~
> Season ends {date} · run-it-back opens with the recap
> Next season: $79 from the pot · ≈ $6.60 a player

Fine print — replace the current sentence pair ("**Cup Season keeps the
books.** Buy-ins and payouts move friend-to-friend on Venmo or cash. We
just make sure nobody argues at the bar.") with:

> **Cup Season keeps the books.** Buy-ins and payouts move
> friend-to-friend on Venmo or cash. The pass is the one line paid to
> Cup Season — it never comes out of the prize money.

- Members see the pot pane as today (no pass card); the fine-print
  sentence updates for everyone.
- Founding leagues: the card swaps to the gold badge + "free forever."
- Season-end date from the league's season row; "run-it-back opens with
  the recap" is static copy at launch (the surface itself is Stripe-phase).

### 2d. Store + docs metadata (launch, non-client)

- `spec/appstore-launch-kit.md` FAQ — replace "What does it cost? —
  Free to download and play today; long-term pricing is honestly still
  being decided…" with: "Free to download, and every golfer's profile,
  index, and record are free forever. A league's first season is free;
  after that the league runs on a season pass (about $79/season, paid by
  the Pro out of the pot — around $6 a player). There are no in-app
  purchases." Keep the "no in-app purchases" sentence VERBATIM true
  until the Stripe phase ships (Apple memo, discovery §6.2).
- The public **/pricing page** is open decision #6 (owner) — if
  approved, it ships AFTER the script locks the number; quiet page,
  footer + FAQ links only, never the door.

### 2e. Season-2 run-it-back paywall — NOT in this build

Designed (deck slide 8), built in the Stripe phase. Nothing ships now;
the launch surfaces above pre-announce it, which is the whole D56 point.

---

## 3. What the dormant Stripe phase needs later (filed, not started)

1. **The line-item mechanic decision** — "pass rides ON TOP of the
   buy-in, pot stays whole" is a mechanics-level change that needs its
   own decision-log entry before build (discovery §1.4; focus-group-plan
   pressure-test).
2. **Checkout on the web** (Apple memo §6.3): Stripe products for the
   three bands; a `league_passes` table (league, season, band, amount,
   status, paid_at, stripe refs) + security-definer RPCs + explicit
   grants (D37); receipts surface (§16 — the pass shows its work too).
3. **Run-it-back surface** wired to recap completion (deck slide 8);
   Founding leagues bypass forever.
4. **Apple:** enroll the Small Business Program (15%) regardless; in-app
   link-out per the then-current US rules (SCOTUS pending — re-verify at
   build); IAP only if measured web friction costs renewals.
5. **Flag graduation:** `pricing.visible` stays the kill switch;
   `season1_free` scope enforcement moves from copy to the pass table's
   own logic.

---

## 4. Eng-lane verification checklist

- Serve locally (`python -m http.server 8791`), clear SW + caches first,
  `?exit` to reset auth; fetch a marker string to confirm the served tree
  (port-multibind landmine).
- Both themes on every touched surface; gold only on pot/founding.
- Demo mode: wizard + You tab + League Room render State-B copy with
  demo data, zero `sb` reads.
- Flag off (`visible:false`) → pixel-identical to today.
- Missing key / failed read → same as flag off; console clean but for
  the known boot rejection.
- Mixed middot encodings landmine: anchor Edits on ASCII lines near the
  quoted strings, not on `·` lines.
