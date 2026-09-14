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
