# Phase 3 — waves 3–6, the live round, the visual pass, the visible model

*Status artifact, 2026-08-27 (evening). Branch `native/m0-foundation`. Builds on
`PHASE-3-WAVE-1.md`; governed by IOS-018 (parity first), IOS-019 (visual pass),
IOS-020 (the card), IOS-021 (pay-to-play).*

## What is on the phone now

Every row of the IOS-001 parity matrix that the web has, walked in the web's copy
and behaviour, plus the first native pass over how it looks:

| Wave | Surface | State |
|---|---|---|
| 1 | Door (email OTP + reviewer password), card gate, Settings, push registration | merged |
| 2 | Home — hero, occasion, Up Next, digest, the one feed with reactions, coming up | merged · visual pass |
| 3 | Post a round — course/tee, front & back, the grid, scan, photo, ceremony, epilogue, partners | merged · **rebuilt as the scorecard (IOS-020)** |
| 4 | The live round — tee sheet, match play / Wolf / skins / settle engines (web vectors ported), group-phone sync with a durable queue, settlement PNG + share, the guest pencil, claim links | merged 2026-08-27 · `ddee137` |
| 5 | Start a league wizard (presets, every dial, portrait, lock, invite), draft night (blind draw, Pro assign, snake board), league-less doors, run it back | merged |
| 6 | Events — the Ryder and the Major: picker, setup, rooms, sessions, targets, jug | merged |
| — | Clubhouse — league hero, tab strip, season strip, climb, race, table, pot, bylaws, album, members | merged · visual pass |
| — | You — hero, trophies, record, rivalries, buddies, founder's desk | merged · visual pass |
| — | Pricing — `app_flags.pricing`, `PricingFlags`, wizard pass card, membership card, pot pass card + fine print | merged · **hidden until the flag flips** |

Numbers: 287 tests (282 kit / 73 suites + 4 design + 1 app), preflight 17/17,
head `286af65` pushed. Wave 4 alone added 56 tests (the Sunningdale vectors
t1–t11 / s1–s7, LWW merge, the queue, rehydrate, claim).

## The visual pass (IOS-019) — what changed

Four rules, applied to every screen: one hero per screen and only it wears the
wash; borders retreat and rows separate with hairlines; the page header lives in
the scroll (the iOS 26 glass toolbar was clipping the wordmark into "— C" — fixed
by construction); panes are a mono tab strip with a sliding ember underline.
`CSDesign/Surfaces.swift` carries the primitives (`CSWash`, `CSHero`,
`CSDuskCard`, `CSPageHeader`, `CSSectionHead`, `CSRow`, `CSTabStrip`,
`CSMotion.roll`). The Clubhouse's 2×2 stat grid is one season strip. The ⊕ tab
is a filled ember circle. Every colour still comes from `tokens.json` — preflight
15 (palette purity) is the lint.

## The card (IOS-020)

The composer's gross is the hero and it is live: serif figure on a dusk wash, the
band phrase under it, a points chip through the open league's lens. Remembered
courses are rows; rating/slope is one line that expands. Front & back are two
large mono figures; "Enter your card" opens the scorecard strip — OUT and IN rows
of nine cells, tap to select, one big − / + stepper, "Next hole →". Post is
pinned in a bottom bar. Every mechanic and every string of web copy is intact
(D32/D34, the even-par guard, half-value nines, scan soft-failures, draft
restore, the ceremony chain). The ⊕ opens ON the composer when there is no live
round (IOS-004 §2); the three-door cover is one back-tap away.

## Pay-to-play (IOS-021 executing D56)

Built, hidden: migration `20260827160000_pricing_flag.sql` seeds
`app_flags.pricing` with `visible:false`; `PricingFlags` (kit, tests for the
bands/formatting/founding/decode) ; three self-contained cards mounted on the
wizard's stakes step, Settings' membership block, and the pot pane (+ the D56
fine print). Owner's calls: the $79 anchor, and when to flip `visible`. Checkout
stays on the web at the first season 2 (Stripe; never IAP-first). Plan page:
the "Season Pass Plan" artifact; mount doc `docs/ios/pricing-surfaces.md`.

**Owner runs (Mac, repo root):** `supabase db push` — ships the pricing flag
migration. Nothing on the phone changes until the flag is flipped.

## Developer hatches (DEBUG only, never in a shipped build)

`-cs_dev_email <e>` / `-cs_dev_code <8 digits>` sign a simulator in;
`-cs_dev_open <place>` lands on a screen (clubhouse · board · schedule ·
settings · people · post · postround · live · wizard · events · you); the
composer adds `-cs_dev_post_seed <total|strip|scan>`; the room adds
`-cs_dev_pane` / `-cs_dev_scroll`. Screens in this artifact were verified on a
simulator signed in to the owner's account, look-only.

## Honest edges

- Not yet installed on the phone this evening — the device was disconnected;
  next tether: `xcodebuild … -destination id=B6F4570A-… -allowProvisioningUpdates
  build` then `xcrun devicectl device install app`.
- Home keeps ~90pt of empty navigation bar above the wordmark (the `+` keeps the
  bar alive). Candidate: move `+` into the header row and hide the bar.
- The cover's old eyebrow "Golf · before, during and after the round" is not
  rendered (would duplicate the header); restore as the header's `sub` if the
  copy law is read strictly.
- Wave 7 (push routing/categories, sharing — IOS-009 batch 2) and wave 8
  (parity audit vs IOS-001, TestFlight) remain; then the web-as-standalone
  decision (IOS-018's second half).
- Web pricing surfaces (the July handoff's `index.html` insertions) are held
  until the web's role is decided; the flag serves both.
