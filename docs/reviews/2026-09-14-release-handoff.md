# Release handoff · the seven ratified decisions — 2026-09-14

Every state below was read back from App Store Connect or from the served
page, not inferred from a command succeeding. **Upload is not delivery, and
neither is processed**, so the three states are reported apart.

---

## What is where

| | |
|---|---|
| **Web commit** | `807eeaf` on `claude/brand-client-parity` — the last commit that changed a served file. Anything after it on this branch is documentation, so the preview's SHA may read later while the client is byte-identical. |
| **Web preview** | <https://deploy-preview-4--cupseason.netlify.app> — the preview tracks the branch head and rebuilds on every push; verified serving `v23 · 807eeaf` with `sw.js` carrying the same SHA |
| **Production web** | `cupseason.app` is still `1bc307f` and was deliberately not touched; this branch is a preview, not a merge |
| **Native source commit** | `807eeaf` — the same tree |
| **Native build** | **898** (`git rev-list --count HEAD`) |
| **Earlier checkpoint** | **890**, source `1bc307f`, the release Codex reviewed on 2026-09-13 |

## TestFlight, in three states

| Build | Uploaded | Processed | Available to test |
|---|---|---|---|
| **890** · earlier checkpoint | yes | **VALID** | **yes, internally** — `IN_BETA_TESTING` in the new internal group. Externally `READY_FOR_BETA_SUBMISSION`, i.e. **not** in front of the four Friends testers |
| **898** · this work | yes | **VALID** | **yes, internally** — `IN_BETA_TESTING`. Externally `READY_FOR_BETA_SUBMISSION` |

Neither build was submitted for Beta App Review, so neither has reached the
external group. That is a deliberate stop: an external submission puts a build
in front of four other people, and 898 has not been reviewed by Codex yet.
Submitting is one call when you want it.

**What each build says it is.** 890's What to Test names it as the earlier
checkpoint and says outright that it does not carry the 2026-09-14 work, per
the owner's instruction. 898's names the work it carries and its source commit.

## Testers

An **internal** group named **Owner** now exists, holding the Account Holder
and nobody else. **Friends stays external, with its four testers, untouched.**
No other tester was given App Store Connect access — an internal tester *is* an
App Store Connect user, so adding one would have been exactly the access the
owner withheld.

## Signing, recovered

The account had **no** distribution certificate of any kind. The likeliest
cause is ordinary annual expiry — the last one signed build 795 on 2026-09-12
and the first failed export was the next day — and it **cannot be proved**,
because Apple stops returning an expired certificate. The remedy is the same
either way, so it was treated as a hypothesis and not as a finding.

Two things were wrong, and both are fixed:

1. **No certificate.** `tools/ios-signing.sh` generates a private key on this
   Mac, asks Apple for a distribution certificate against it, and keeps the
   identity in a vault at `~/.appstoreconnect/cupseason-dist` (mode 700,
   outside this public repository). Nothing was revoked; the login keychain was
   never written to; no key was printed.
2. **Cloud signing cannot be used by an API key.** The key authenticates, reads
   the app and mints profiles, and then `-exportArchive` says *"Cloud signing
   permission error / No signing certificate iOS Distribution found"*. The two
   App Store **profiles** are now created explicitly through the API, bound to
   this certificate, and `tools/ios-archive.sh` exports **manually** against the
   vault. A machine with a working Xcode login is unaffected — with no vault the
   old automatic path runs unchanged.

One honest note: the first attempt created a certificate and then failed to
export, and its private key went with the temporary directory it was made in.
That certificate is inert and was **left alone rather than revoked**, per the
standing instruction. The working identity is the second one, expiring
**2027-09-14**.

## Functional checks

**Web, against the live HTTPS preview** (Chromium over the DevTools protocol,
service worker and caches cleared first):

| Suite | Result |
|---|---|
| `brand-door-browser.js` | pass — the mark reads cream on fescue and dark on paper; the statement enlarges and wraps on **whole words** |
| `nav-band-browser.js` | pass — five slots in order, all labelled, Play in-box, Play in `rgb(95,162,113)` which is `act` |
| `artifact-signature-browser.js` | pass — the four artifacts share one signature within a third |
| `round-photo-browser.js` | pass — card ground 36.8 with no photograph and 59.2 with one; the three shares read true / false / true |

**Native, iPhone 17 Pro simulator:** the six share and receipt UI tests pass,
including `testAcceptedReceiptToPreviewAndPhotoOptOut`, which used to fail on a
data precondition and now runs on a deterministic fixture.

`npm run preflight` — **0 failures, 0 warnings**, including the new **BRAND-02**.

## Still open

- **A physical iPhone.** Safe areas, the keyboard, VoiceOver, Dynamic Type,
  Add to Home Screen, and a real link preview of the new card. Everything above
  is a viewport, not a phone.
- **Codex's review** of `807eeaf`, and then the external Beta App Review
  submission that actually puts a build in front of the Friends group.
- **The native receipt moment** — the desk's composition has not crossed to the
  phone yet. It is row 8 of the parity ledger.


---

## Evening addendum · 2026-09-14 — the scorecard, the Home audit, photo stability, and the sprint packet

**Source.** Everything below is on `claude/brand-client-parity`; the last commit that changed a served file is the one this addendum ships in (the preview's `#obCaption` names it). Native build **898** predates this work; **no new native build was archived** — the signing path is proven and `tools/ios-archive.sh --upload` mints the next number when Codex has reviewed.

| Work | Web | Native | Evidence |
|---|---|---|---|
| D360 · compact no-photo scorecard | built | built | `round-record-browser.js` (dark/light, 390/320), `HomeNoPhotoTests` (5, both appearances, AX3) |
| D360 · Home says each fact once | season row yields to the column | MW-02's twin (`HomePage.arrangeWire`) | `home-repetition-browser.js`, `HomePageTests` (27) |
| D361 · photo stability | signed cache by path, sized pictures, last-good fallback, nodes kept | `HomePhotoStore`, `SignedURLCache`, sized signing, loading frame | `home-photos-browser.js` (6), `HomePhotoStoreTests` (5), `HomePhotoStabilityTests` (3); measurements in D361 |
| Sprint packet | — | — | `docs/planning/2026-09-14-gameplay-sprint-candidates.md`; nothing in the release |

**Remaining parity gaps.** The scorecard's *competition* story reaches the desk through the board cache and cannot reach the phone until `home_feed` carries points and the month rank (sprint B's migration). The board's story card still uses `AsyncImage`; the wire is fixed, the board is next. A physical iPhone pass is still owed for everything above.

**Deployment status.** Database: **no migration applied or proposed for this release** (the packet names its migrations; none run). Edge: none. Web: preview only; `cupseason.app` stays at `1bc307f`. Signing: recovered and repeatable; builds 890 and 898 remain internal-only on TestFlight.


---

## Evening checkpoint and increment · 2026-09-14, late

| Increment | Source | Web | Native | Database | Checks |
|---|---|---|---|---|---|
| Photo findings closed + receipt moment | `f6a31d9`, `714609b` | preview at `f6a31d9` (same client) | **build 905** — VALID, internal `IN_BETA_TESTING`, external not submitted | none | eight web suites on the preview; 54 native tests across nine suites |
| The round that counts, explained (D362) | the commit after `714609b` | composer worth line, receipt denominator and door | prepared behind the migration | `20261104090000` prepared, isolated-cluster validated, **not applied** | `counting-explained-browser.js` |

The frozen checkpoint is recorded in [2026-09-14-release-checkpoint-evening.md](2026-09-14-release-checkpoint-evening.md). Physical-device verification remains outstanding.


---

## The counting increment, both clients · 2026-09-14, late

| | |
|---|---|
| **Quality checkpoint, unchanged** | `714609b` · build 905 · internal-only |
| **Source** | `0792ddd` (the commit after it is this note) |
| **Web** | preview on every push; the desk's composer worth line, lens rows with denominators, and the door to the month's rounds through `counting_rounds` |
| **Native** | the composer's worth lines from `my_month_counters`; lens rows from `contributions`; `CountingRoundsSheet` from `counting_rounds`; honest on the older database. **No native build archived** for this increment — the phone's half needs the migration to say anything on production. |
| **Database** | `20261104090000` prepared, validated on an isolated cluster, **not applied**; the held `20261024090000` unchanged. Packet: `docs/reviews/2026-09-14-counting-deployment-packet.md` |
| **Contract** | `packages/db/contract.psv` regenerated from the isolated cluster; `rpc.ts` and `Rpc.swift` regenerated by `tools/build-db.mjs`; re-take from the live database after the push |

**Checks run on this source.** Web: `counting-explained-browser.js` (composer sentences: room, full, capped, uncapped, no live season; the receipt's denominator, single and named lenses, no-lens, the door through the stubbed producer, the served counters), plus the eight standing suites on the preview. Native: `ReceiptLensesTests` (clause, one lens, two lenses named with points, bumped, uncapped, the older database, served lines), `ReceiptLensesUITests` (two, bumped, uncapped; the door opens the sheet, which says the honest thing against the older database), `ComposerWorthUITests` (room, full, capped, open, two), `ReceiptMomentTests`, `AcceptedRoundReviewTests`. Database: `tests/db/counting-explained.sql` on the isolated cluster — two-league owner, one-league mate, refusal, backdated, bumped, per-league counters.

**Unverified.** Production behaviour of the three functions (they are not applied); a physical device; squads' summed counting sets (not drawn by design).
