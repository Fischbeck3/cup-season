# Pricing discovery — 2026-07 (pricing-arc, task #41)

Consultant-hat deliverable · 2026-07-21 · governed by **D56** (pricing
unparked: refine the canon model, visible-no-checkout at iOS launch).
Inputs: `gtm-year1.md` §11 + §14.1 · CLAUDE.md monetization canon ·
`product-vision-v1.0.md` · `focus-group-plan.md` v0.1 · the wizard's real
economics (`index.html` — stakes `[0, 25, 50, 75, 100, 150, 200]` per
player, rosters 8–16). Companion deck: `spec/handoffs/pricing-deck.html`.
Frame law: **price against the pot, never against other apps**; D39
posture wherever money appears (the pass is paid TO Cup Season; the pot is
never held BY it).

---

## 1. Price-point analysis — anchored to the pot

### 1.1 The real economics under the price

Pot = buy-in × roster, from the wizard's actual dials:

| Buy-in | 8-man | 12-man | 16-man |
|---|---|---|---|
| $0 | — bragging rights | — | — |
| $25 | $200 | $300 | $400 |
| $50 | $400 | $600 | $800 |
| $75 *(wizard default)* | $600 | **$900** | $1,200 |
| $100 | $800 | $1,200 | $1,600 |
| $150 | $1,200 | $1,800 | $2,400 |
| $200 | $1,600 | $2,400 | $3,200 |

Center of mass for a real money league: **$500–$1,200** ($50–100 buy-in,
10–12 players). The reference frame the deck leads with is the wizard's
own default at a typical roster: **12 × $75 = a $900 pot**.

### 1.2 The three candidate points against that reality

Per-player share of the pass, by roster:

| Pass | ÷ 8 | ÷ 12 | ÷ 16 | % of the $900 pot | % of one $75 buy-in (12-man) |
|---|---|---|---|---|---|
| **$49** | $6.13 | $4.08 | $3.06 | 5.4% | 5.4% |
| **$79** | $9.88 | **$6.58** | $4.94 | 8.8% | **8.8%** |
| **$99** | $12.38 | $8.25 | $6.19 | 11.0% | 11.0% |

The deck's core sentence, instantiated: **"$79 ≈ $6.60 a player of your
$900 pot."** Equivalent framings that survive contact with a skeptical
Pro: *less than a tenth of one buy-in* · *the cheapest thing in the
league, including the range balls.*

### 1.3 The finding that decides the structure

The three candidate flats are **$6/head in disguise**: $49 ≈ $6.13 × 8 ·
$79 ≈ $6.08–7.90 across 10–13 · $99 ≈ $6.19–7.07 across 14–16. Priced as
roster bands, every league lands **$5.44–$7.90 per player** — the canon
"$5–8/player" window, preserved by construction at every roster size.
A single flat price cannot do this: flat $79 costs an 8-man crew $9.88 a
head (outside the window, worst deal to the smallest, most price-sensitive
crews) and a 16-man crew $4.94 (undersold). This is the basis of the §2
recommendation.

### 1.4 Small-pot stress test

8 × $25 = a $200 pot; $79 is **39.5% of the pot** — a framing disaster if
copy ever speaks in % of pot. Two rules follow:

1. **Copy law: per-head and per-buy-in framings only.** "% of the pot"
   appears in this analysis and the deck's math slide, never in product
   copy. "$6 a man" is true and painless at every pot size; "8.8% of the
   pot" invites the $200-pot Pro to compute 40%.
2. **The pass rides ON TOP of the buy-in, never out of the prize pool.**
   "Paid from the pot" (canon shorthand) must resolve, mechanically, as a
   line item the Pro adds to the buy-in they already collect ($75 + $7 =
   $82 in, pot stays a round $900) — not as a deduction that shrinks
   payouts. This keeps D39's two ledgers visibly distinct: pot money moves
   between friends; the pass is the one line paid to Cup Season. It also
   answers the focus-group-plan's gatekeeper trap (the Pro never fronts
   personal money). This is a **mechanics-level consequence** — its own
   decision-log entry when the checkout build starts (named in
   focus-group-plan §Pressure-test; re-flagged here).

### 1.5 The bragging-rights league ($0 pot)

No pot anchor exists; the pass is naked out-of-pocket money and the Pro
feels all of it. Three postures considered:

- **Same price, re-anchored** *(recommended)*. The product's value to a
  $0 league is identical (season, standings, memory — the pot was never
  the product; §16 receipts don't care about stakes). Copy drops the pot
  anchor for golf-goods per-head anchors: *"$79 for the season — about
  six bucks a man, less than a sleeve each."* The app suggests the split
  (a "split it on Venmo" line on the Pro's surface), so the Pro is a
  collector again, not a donor.
- **Discounted for $0 leagues** — rejected. It prices the pot itself: add
  stakes, pay more. Perverse against the pot ritual (the retention engine
  per GTM), and it invites the dodge (run $0 officially, cash on the
  side).
- **Deferred until stakes added** — rejected, same tax-on-the-pot logic
  inverted, plus a free tier that never converts.

Psychological cost stays real — flag as a dedicated probe for any $0-pot
Pro in the focus group (script §5, probe B2a).

### 1.6 Recommendation (to be closed by the script, not this doc)

Walk into the focus group with **$79 as the anchor** for the standard
(10–13) roster, banded per §2. $49 reads suspiciously cheap against a
$900 pot (Van Westendorp "so cheap you'd question it" — likely under the
floor for seat-3 Pros); $99 crosses $8/head at 12 and touches $12.38/head
at 8 even banded down. $79 sits mid-window at every banded roster. The
script's Block B medians from **arms-length Pros (seat 3)** close the
number; PIGL's read weights low (insider trap, focus-group-plan §frame).

---

## 2. Flat vs per-head — recommendation: banded flat, quoted as one number

| Model | 8-man | 12-man | 16-man | Fairness story | Failure mode |
|---|---|---|---|---|---|
| Pure flat $79 | $9.88/head | $6.58/head | $4.94/head | "One price, any crew" | Smallest crews pay double per head; the $200-pot league gets the worst deal in the store |
| Pure per-head $6 | $48 | $72 | $96 | "Six bucks a man, period" | A meter, not a price: repricing on every roster change, no single quotable number, reads as SaaS-per-seat — the exact framing canon forbids |
| **Banded flat** *(rec.)* | **$49** (≤9) | **$79** (10–13) | **$99** (14+) | "Seventy-nine for the season — about six a man" | Band edges need a rule (below) |

**The recommendation:** three flat prices by roster size, but **the app
only ever quotes one** — the wizard knows the roster, so this league sees
"$79 · about $6.60 a player," never a tier table. The band is pricing
machinery, not a surface. The Pro gets what a flat gives (one number to
say out loud, one line item to collect) and the crew gets what per-head
gives (everyone pays about a fiver, whatever size the league is).

**Band rule:** the band fixes at **roster lock** for the season — adds or
drops mid-season never reprice (set it once, argue never). Season 2
re-reads the roster at its own lock. Edges at 9/10 and 13/14 track the
$5–8 window (§1.3); they are tunable constants, not promises.

**The fairness sentence the Pro tells the crew:** *"The app's $79 for the
season out of the pot — call it six bucks a man. It keeps the books,
the standings, and the whole season; nobody touches a spreadsheet."*

---

## 3. Season-1-free scope + Founding League accounting

### 3.1 Scope options

- **Per league** *(recommended)* — every league's first completed season
  is free; the ask lands at its own "run it back." Honest reading of the
  canon sentence; the gift follows the thing that experiences the value
  (the league, not the person). A multi-league Pro gets each NEW league's
  first season free — correct, not a leak: multi-league Pros are the LTV
  concentration GTM §11 wants encouraged at exactly that moment.
- **Per Pro** (first league only) — rejected: punishes the best users at
  their expansion moment; also trivially dodged (the crew's other guy
  clicks Create).
- **Per calendar** (all free until date X) — rejected: cliff cohort,
  arbitrary unfairness at the boundary, and it decouples the ask from the
  proven-value moment, which is the entire pricing thesis.

**Abuse vector, named:** evergreen re-creation (delete league, recreate,
free again). **The product's own memory is the enforcement** — recreating
torches history, trophies, rivalry records, the Record. A crew that burns
its second season's story to dodge $79 was never a customer (Memory >
Statistics doing anti-abuse duty; no policing code needed at this scale;
revisit trigger: the first observed re-creation dodge).

### 3.2 Founding League free-forever accounting

Foregone pass revenue at the $79 anchor, 1–2 seasons/league/year:

| Cohort | /year | 5-year cumulative |
|---|---|---|
| 5 leagues | $395–790 | ~$2,000–4,000 |
| 10 leagues | $790–1,580 | ~$4,000–8,000 |

Trivial dollars against what the cohort buys: the permanent research
panel, the reference customers, the referral seeds (focus-group-plan:
seeding and the study are the same motion). **The real cost is precedent,
not revenue** — an uncapped or quietly-extended cohort teaches the whole
early market that waiting earns free. Therefore: **cap at 10, number the
badges ("Founding League #7 of 10"), close it loudly** when full. The cap
is the marketing.

---

## 4. Ryder / Major stance — included; standalone stays free at launch

**Recommendation: one pass, everything a league does is in it.** Ryder
and Major events attached to a passholder league are included — the pass
covers "the whole season," and the events ARE the season's best weekends.
No à-la-carte SKU at launch.

**Standalone events (no league) stay free at launch.** The Ryder's
guest-claim links and settlement cards are the GTM's cheapest acquisition
wedge; a paywall on the wedge throttles the funnel to protect revenue
that barely exists. **The claim link is never gated, at any price, ever.**

**Later door, held open:** a standalone-event SKU (~$19–29, the Trip Guy
buying one weekend) is the one à-la-carte product that maps to a real
persona. Decide at season-2 charging time, sized by script Block D — if
Trip Guys say "I'd pay for the weekend, I'd never buy a season," the SKU
earns a decision entry; if not, standalone stays a free funnel forever.

---

## 5. Willingness-to-pay script — 15 minutes, deck-driven

Tightened from `focus-group-plan.md` v0.1 (its seats, traps, and question
bank govern; this is the run-of-show). Instrument: the deck
(`pricing-deck.html`), slides 2–4. Run 1:1, live; PIGL answers weight low
on price, full on behavior (insider trap). Seat-3 arms-length Pros carry
the price decision.

**Minute 0–2 · The pot walk (deck hidden).** "Walk me through last
season's money — buy-in, who collected, where it sat, what organizing
cost you in dollars and hours." *(Records: pot size, treasurer, current
spend. This is the anchor everything else divides by.)*

**Minute 2–4 · Show the thing.** Deck slide 2 (the model) + slide 3 (the
math at THEIR pot — plug their numbers in live). No price question yet.

**Minute 4–8 · The four price fences (Van Westendorp, % framing).**
Against your pot: (1) so cheap you'd doubt it? (2) a bargain — easy yes?
(3) getting expensive — you'd think about it? (4) too expensive, period?
*(Record four numbers. Medians across seat 3 close the point.)*

**Minute 8–11 · The gatekeeper pair** — the study's most important data:
- To the Pro: "$79 for the season. Who decides, and does it come out of
  the pot or your pocket?"
- To members (separately): "Your Pro says the app's six bucks each this
  season. Instant yes, grumble, or no?"
*(The GAP between the two answers is the conversion risk. If members
chip in but Pros balk → the fix is the §1.4 line-item mechanic, not a
lower price.)*

**Minute 11–13 · The renewal cliff.** "First season free, season 2 is
$79 from the pot — what happens at renewal? Re-up, or does 'wait, it was
free' start a fight?" *(Tests D56's whole visible-model thesis: does a
price stated on day one defuse the fight?)*

**Minute 13–14 · Ryder à la carte (Trip Guys only).** "One-weekend Ryder
for the boys: ~$20 for the event, or free but only inside a $79 season?"

**Minute 14–15 · The kill question.** "What would make you not use this
even if it were free?" *(Everything before this is worthless if this
answer is big.)*

**Probe B2a ($0-pot Pros only):** "No money league — the app's still $79.
Split six ways or does that kill it?"

**What closes what:**

| Open decision | Closed by |
|---|---|
| Price point ($49/79/99 anchor) | Seat-3 medians, fences 2–3 |
| Flat-vs-banded confidence | Reaction to "about $6 a man" reframe |
| Season-1-free scope risk | Renewal-cliff answers |
| Ryder SKU (later door) | Block D split |
| Gatekeeper mechanic priority | q8/q9 gap size |

---

## 6. Apple posture memo — verified by web search, 2026-07-21

**Why this exists:** even visible-no-checkout touches App Review (we
state prices in-app with no purchase path), and the season-2 checkout
build must start from a settled posture. State of play verified against
current reporting, not training memory.

### 6.1 The legal landscape as of 2026-07-21

- **May 2025:** after the district court's contempt order in *Epic v.
  Apple*, Apple updated the App Review Guidelines — on the **US
  storefront**, apps may include buttons, external links, and other
  calls to action to outside purchases, **no entitlement required**
  (3.1.1(a); 3.1.3's anti-steering prohibition marked not applicable to
  the US storefront). Those guideline carve-outs remain in force today.
- **Dec 2025:** the Ninth Circuit **affirmed the contempt finding** but
  **narrowed the remedy** — the district court went too far in barring
  ANY commission on steered purchases; Apple may charge a "reasonable"
  commission (costs + IP), with the number to be fought out on remand.
- **May–June 2026:** Apple sought a stay and petitioned; **SCOTUS
  granted certiorari (2026-06-30)** on the contempt ruling. The external
  purchase fee (the old 27%) is **paused but contested** — nobody should
  build economics on link-outs staying commission-free.
- **Small Business Program:** active; **15%** (not 30%) on proceeds
  under $1M/yr — Cup Season's IAP rate for the foreseeable future.
- **Unaffected throughout:** the multiplatform pattern (guideline
  3.1.3(b)) — sell on your own website with **no in-app link-out**,
  unlock the purchase in the app. Commission-free since forever,
  untouched by every ruling above. Netflix's lane.

### 6.2 What this means at launch (visible model, no checkout)

- Stating prices in-app is safe on the US storefront under the current
  carve-outs — even calls-to-action are permitted, and we ship less than
  that (information only, no transaction, no link).
- **App Review honesty:** metadata and review notes say — free to
  download, individual golfer free forever, a league's first season
  free, a per-league season pass afterward, **no in-app purchases**.
  Update `appstore-launch-kit.md`'s FAQ line ("pricing still being
  decided") to the visible model — a stated model with a truthful "no
  IAP today" is cleaner for review than a vague one.
- **Gambling optics (guideline 5.3):** unchanged by this arc — the D39
  ledger line stays in store copy ("keeps the books; money moves between
  friends"). The pass being paid TO us must never blur into the pot in
  any store-facing sentence.

### 6.3 The season-2 checkout posture (the settled path)

1. **Primary rail: web purchase — Stripe on cupseason.app.** The buyer
   is one adult per league doing a deliberate ~$79 annual transaction —
   a desk purchase, not an impulse tap. Cost ~2.9% + 30¢ (≈ $2.59 on
   $79) vs $11.85 at Apple's 15%. Works identically regardless of how
   SCOTUS rules. The app shows pass status (3.1.3(b) unlock pattern);
   the Pro buys on the web.
2. **In-app link-out: use while the door is open, lean on it never.**
   Under current US rules we may link "Renew at cupseason.app" from the
   season-2 surface with no entitlement and (today) no fee. Build the
   copy so the link is removable without redesign — if SCOTUS restores a
   commission regime or the carve-outs revert, we drop to posture 1 and
   lose only a convenience, not the business.
3. **IAP: a conversion fallback, not a plan.** Enroll the Small Business
   Program regardless (free option value). Add a $79 IAP only if
   measured web-checkout friction actually costs renewals; at 15% it's
   margin, not survival. Never let IAP existence force IAP-first pricing.
4. **Never:** routing pot money through any rail, Apple's or ours —
   that's D39's future service door, a separate compliance project
   (money transmission), not part of any pass build.

**Sources:** [Apple developer news — guideline update](https://developer.apple.com/news/?id=9txfddzf) ·
[MacRumors — Ninth Circuit lets Apple charge external-link fees, Dec 2025](https://www.macrumors.com/2025/12/11/apple-app-store-fees-external-payment-links/) ·
[IPWatchdog — SCOTUS grants cert, 2026-06-30](https://ipwatchdog.com/2026/06/30/high-court-grants-cert-in-apples-challenge-to-ninth-circuit-contempt-ruling-in-app-store-dispute/) ·
[gHacks — SCOTUS to hear 27% fee appeal](https://www.ghacks.net/2026/07/02/supreme-court-agrees-to-hear-apple-appeal-over-27-external-payment-fee-in-epic-contempt-case/) ·
[Cravath — Ninth Circuit affirmance](https://www.cravath.com/news-insights/epic-games-ninth-circuit-win-affirming-civil-contempt-finding.html) ·
[Apple — Small Business Program](https://developer.apple.com/app-store/small-business-program/)

---

## 7. Open decisions register (each with a recommendation, for the deck)

| # | Decision | Recommendation | Closes |
|---|---|---|---|
| 1 | Price anchor | $79 standard band | Script, seat-3 medians |
| 2 | Structure | Banded flat ($49/$79/$99 at ≤9 / 10–13 / 14+), one number quoted | Script reaction; owner |
| 3 | Season-1-free scope | Per league, first completed season | Owner (risk read via renewal-cliff answers) |
| 4 | Founding cap | 10, numbered, closed loudly | Owner |
| 5 | Ryder/Major | Included; standalone free; SKU door held for season 2 | Block D + owner |
| 6 | Public /pricing page | **Yes — one quiet page** (deck §open-decisions has the full case) | Owner |
| 7 | Checkout rail (season 2) | Web/Stripe primary; link-out while allowed; IAP fallback at 15% | Owner at build time |
