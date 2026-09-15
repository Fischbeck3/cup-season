# Release checkpoint · 2026-09-14 evening — frozen before the gameplay increment

Recorded the moment it passed, before any further source change, so unfinished
gameplay work cannot enter it. Every state below was read back, not inferred.

## The checkpoint

| | |
|---|---|
| **Source** | `714609b` on `claude/brand-client-parity` |
| **Web** | the same client as `f6a31d9` (the commit after it is native-only); the preview at <https://deploy-preview-4--cupseason.netlify.app> read back `v23 · f6a31d9` with `sw.js` at the same SHA when the eight suites ran. `cupseason.app` is untouched at `1bc307f`. |
| **Native build** | **905**, archived from `714609b`, exported through the vault (manual signing), validated and uploaded |
| **TestFlight** | uploaded · processed **VALID** · **available to test: yes, internally** (`IN_BETA_TESTING` in the Owner group) · external `READY_FOR_BETA_SUBMISSION` — **not submitted**; Friends untouched |
| **Testers, roles, secrets** | unchanged. No certificate revoked. |
| **Database / Edge** | nothing applied. One migration is **prepared** for the gameplay increment and validated on an isolated cluster only (see below). |

## What is in it

- D361, closed with Codex's three findings: a credential this load could not
  get is not removal; a failed first download recovers, bounded; a decode is
  re-checked after it finishes; an in-flight signing call cannot repopulate a
  cache cleared for a new account. Home, the board and the receipt read one
  photo store by path and sign photographs one way, sized for a screen.
- The receipt's brand moment on the phone (ledger row 8), naming the course once.
- D360 (the compact scorecard, Home says each fact once), D358/D359.

## Checks run on this source

**Web, against the live HTTPS preview:** `brand-door`, `nav-band`,
`artifact-signature`, `round-photo`, `round-record`, `home-photos`,
`home-repetition`, `home-function` — all pass. `npm run preflight` — 0
failures, 0 warnings.

**Native, iPhone 17 Pro simulator:** `HomePhotoStoreTests` (8),
`SignedURLCacheTests` (2), `HomePageTests` (27), `HomePhotoStabilityTests`
(5), `HomeNoPhotoTests` (5), `ReceiptMomentTests` (1, four states),
`AcceptedRoundReviewTests` (2), `RoundShareReviewTests` (4) — all pass.

## Photo reliability · measured before and after

Before (real rounds, signed-in simulator, `-cs_dev_photo_probe_home`):

| | |
|---|---|
| fresh download | 470–877 KB · 350–510 ms each |
| same URL again | a cache hit once in three (no `Cache-Control` from the storage) |
| signing | 101–290 ms a path |

After, by construction and by test: a path keeps its URL for an hour, so a
refresh, a scroll and a return fetch nothing for an unchanged credential (the
fixture counts 2 fetches for 2 rounds across a scroll away and back); the
picture asked for is 1200 wide at quality 75, which the storage answers at
35–50% of the original bytes (measured 159–431 KB against 470–877 KB); the
decode is downsampled to 1400 on the long side. **Limitation:** the after
figures for bytes and time are the probe's transform fetches, not a second
instrumented run of the rebuilt Home; the reliability behaviour is proven on
fixtures, not on the owner's account.

## Still explicitly outstanding

- **Physical-device verification** — everything above is a viewport or a
  simulator.
- External distribution and production web promotion are separate decisions.
