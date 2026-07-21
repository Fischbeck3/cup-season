# Pricing arc — discovery + deck + presentation design (UNPARKS pricing)

*Brief for a BUSINESS/STRATEGY + UX session run as a two-hat pair: a
pricing consultant and a product/UX designer. This session UNPARKS the
pricing question (parked 2026-07-15 pending focus groups) — an owner
decision at levels 1–2 of the hierarchy. Log the unparking in
`spec/decision-log.md` with conflicts NAMED. Zero app code ships from this
session: discovery, a deck, mockups, and an integration plan only.*

## Decisions already made (the frame — do not relitigate)

- **Model scope: REFINE the canon model**, don't reopen the field. Base:
  per-league **season pass paid by the Pro out of the pot** (working range
  $49–99/season ≈ $5–8/player), **individual golfer free forever** (the
  TheGrint lesson — never resell the handicap), **Founding Leagues (PIGL +
  first ~5–10) free forever**, **charge after proven value** — a league's
  first season is free; the ask lands at the "run it back" season-2 moment
  (gtm-year1 §11).
- **Launch depth: VISIBLE MODEL, NO CHECKOUT.** At iOS launch (mid-Aug)
  pricing is public and honest on the surfaces below, with first-season-
  free messaging. No payment rails; Stripe stays parked; charging begins
  when the first leagues hit season 2.
- Standing decisions that still hold: **no pricing on the app's front
  door**; the Founding League offer is an outreach hook. The one this arc
  deliberately overrides: the blanket "no public pricing talk" — name that
  override in the log entry.

## Phase 1 — Discovery (consultant hat)

Inputs: `spec/gtm-year1.md` §11 + §14.1, CLAUDE.md monetization canon,
`spec/product-vision-v1.0.md`, the wizard's real stake options ($0
bragging-rights, $25–200) × real roster sizes (8–16).

Produce:
1. **Price-point analysis anchored to the pot, never to other apps.**
   Model $49 / $79 / $99 against real pot sizes; the deck's core frame is
   "$X ≈ $Y/player of your $Z pot." Include the bragging-rights ($0 pot)
   league — what does the pass cost THEM psychologically, and does a
   discounted/deferred posture apply?
2. **Per-league flat vs per-head**, modeled on 8/12/16 rosters; a
   recommendation with the fairness story a Pro tells their crew.
3. **Season-1-free scope options** (per league? per Pro? per calendar?)
   and the Founding League cost accounting (what free-forever actually
   costs at 5 vs 10 leagues).
4. **Ryder / Major add-on stance** — included, add-on, or later; one
   recommendation.
5. **Willingness-to-pay script** — a 15-minute focus-group instrument to
   run with the PIGL crew and 2–3 prospect Pros, using the deck. This is
   the focus group pricing was parked pending; the script's answers
   close the price point.
6. **Apple posture memo.** Even visible-no-checkout needs care: research
   CURRENT App Store anti-steering rules and the US external-purchase-link
   ruling (verify with web search — do not rely on training memory).
   Write the compliance path for the later checkout phase: web purchase
   (Stripe on cupseason.app) vs IAP and the 30% — so the season-2
   charging build starts with a settled posture, not a scramble.

## Phase 2 — Presentation design (UX hat)

Mock every surface pricing touches under visible-no-checkout, in the
app's real design system (tokens at `index.html:30–79` — trophy room at
dusk, three type voices, gold is earned-only):

- **Wizard pot step**: the pass as a pot line-item with the per-player
  math, plus the "your first season is free" banner.
- **You tab**: a membership card — Founding badge state, free-season
  state, future paid state.
- **League Room (Pro view)**: where the Pro sees league status/renewal
  runway.
- **The season-2 "run it back" moment**: the future paywall, designed now
  (recap just landed, season worked, "$79 from the pot to run it back"),
  built later.
- **Public web /pricing page: OPEN QUESTION** — bring the owner a
  recommendation (transparency + App Store metadata vs door-stays-clean).
  The door itself stays pricing-free.

Copy voice: priced against the pot, plain language, "the Pro," no SaaS
per-month framing, D39 ledger posture anywhere money is mentioned (the
pass is paid TO us; the pot is never held BY us — keep the two visibly
distinct so the pass never muddies the ledger story).

## Phase 3 — The deck

`spec/handoffs/pricing-deck.html` — self-contained (inline CSS, brand
tokens copied in, no external assets), themed both light and dark.
Sections: the model in one slide · the pot-anchored math · each surface
mockup · the rollout timeline (visible at launch → checkout at first
season-2 → Apple posture) · the focus-group script · open decisions, each
with a recommendation. The deck doubles as the focus-group instrument —
build it to be SHOWN, not archived.

## Phase 4 — Integration plan (no build)

A written handoff for the eng lane: exact copy insertions per surface
(client-only, small, each with its anchor location), an `app_flags`
pricing key for flipping messaging without a deploy, and what the dormant
Stripe phase will need later. Filed as task(s), not built.

## Guardrails

- Zero app-code changes; the deck and docs are the only writes.
- Decision-log entry for the unparking BEFORE the deck is built
  (hierarchy-of-truth: business level, conflicts named).
- No public posting of prices anywhere by the session — the deck is an
  internal + focus-group artifact until the owner ships the copy.
- Commit fetch-first; lanes share main.

## Success gate

The owner can (a) run the focus-group script with the crew using the
deck, (b) hand the integration plan to an eng lane and get the launch
surfaces built in a day, and (c) point at one decision-log entry that
says exactly what was unparked, what it overrode, and what stays parked
(Stripe, checkout, the price point itself until the script's answers are
in).
