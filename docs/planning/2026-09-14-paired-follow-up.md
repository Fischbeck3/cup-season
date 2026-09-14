# Paired follow-up packet · after the 1bc307f release — 2026-09-14

Scope: the three things the paired release left explicitly unverified or
uninstalled. **Web status and native status are stated separately for every
item**, per the standing delivery rule. Nothing here is bundled into the
signing recovery; this is the next packet, not this one.

Baseline: application commit **`1bc307f`**, live at `https://cupseason.app`
(`v23 · 1bc307f` in the page and in `sw.js`). Native: the same source archived
as build 890; delivery state is in
[the signing diagnosis](../reviews/2026-09-14-signing-diagnosis.md).

---

## F-1 · Web install / share icons, and the OG image

**Web status: prepared, not installed.** `tools/build-beta-mark.sh` emits the
candidate family from the pennant's own source into
`brand/candidates/testflight-pennant/generated/web/` — `icon-192`, `icon-512`,
`icon-512-maskable`, `apple-touch-icon`, `favicon-32`. Nothing references them:
the served favicon, PWA icons, apple-touch icon and OG image are still the
Tracer, so installing the web app or sharing a link still shows the old mark.

**Native status: shipped.** The pennant is the app icon; the iOS asset set comes
from the same generator and the same `source.json`.

**Owed.** Two rulings, then one commit:

1. the **production mark** — still recorded as the owner's open decision in
   `spec/brand-canon.md`; and
2. **D339 open 2**, the icon tile: the generator draws contour lines behind the
   mark, while `brand/README.md` calls for a solid ember field. It is visible in
   `generated/web/icon-512.png` and in the iOS set — look at the two side by
   side at home-screen size, which is the size the question is about.

Still to compose after that: the **OG image**. It is a 1200×630 composition, not
a square tile, so it is not a size of the existing generator's output — it needs
the mark, the wordmark and the brand line laid out for a link card. The web
artifact signature (`csArtifactSignature`) is the nearest existing composition
to follow.

**Acceptance.** Both platform icon families reviewed together; the manifest,
`<link rel="icon">`, `apple-touch-icon` and `og:image` all move in one commit or
none; a link preview and a fresh install are checked on a real phone. Production
replacement requires the explicit brand approval — it is not inferred from this
packet.

---

## F-2 · Physical iPhone Safari

**Web status: unverified.** Everything to date is Chromium at 320 / 390 / 1440,
plus a 390×560 short-viewport pass. That is a viewport, not a phone.

**Native status: not applicable** to Safari, and separately gated: the native
UI evidence is Simulator (iPhone 17 Pro), and a physical-device pass is still
owed there too — widgets in particular have never run on real hardware.

**Owed, on a real iPhone, on the live site:**

- **Safe areas** — the door's fixed overlay, the tab bar's bottom inset, and the
  season page under the home indicator.
- **The keyboard** — the door scrolls rather than being pinned (`.onboard` is
  `overflow:auto`, verified synthetically at 390×560); the composer's number
  pads; the join-code field; that the primary control can always be reached.
  `visualViewport` handling exists at `index.html:8349` and has never been seen
  on a device.
- **VoiceOver** — the door's brand line and standfirst, the after-golf card's
  three actions, the Compete rows, the new season room rail, and the standings
  history rows that became buttons in WA4.
- **Dynamic Type** — the welcome statement is `rem` and reflows (F3); the
  system roles elsewhere are px and will *not* scale, which is a real difference
  to look at rather than a claim to make.
- **Add to Home Screen** — install, launch, and whether the service worker
  serves the current build.

**Acceptance.** A named device and iOS version, what was tried, and what broke —
screenshots kept local. Anything that fails becomes its own finding with a
repro; this packet does not pre-suppose the outcome.

---

## F-3 · With-photo receipt sharing and opt-out

**Web status: unverified this pass, and partly blocked by data.** The receipt's
photo path exists (`csReceiptPhotoRow`, `csWireReceiptPhoto`, the signed-URL
fetch in `openRoundReceipt`), and the no-photo path is exercised. The
with-photo half was never walked here.

**Native status: unverified, and it has a known blocker.**
`AcceptedRoundReviewTests.testAcceptedReceiptToPreviewAndPhotoOptOut` fails on
the signed-in simulator at the *Include round photo* switch, because
`-cs_dev_open receipt` opens the account's **newest** accepted round and that
round has no photograph. The test presumes one. So the failure is a data
precondition, not a defect — and it means the opt-out has no passing evidence on
either client.

**Owed.**

1. Give the native test a round that actually carries a photograph — either a
   labelled fixture round, or point the hatch at a round chosen for having one,
   rather than at whichever is newest.
2. Walk the web receipt with a photo: the hero renders, the marker medallion is
   stamped, the opt-out removes the photo from the shared artifact and leaves
   the facts, and a failed image load yields the factual record (D342).
3. Confirm the shared artifact honours the opt-out — the four canvas generators
   now share one signature (D339 I-2), so check the photo's absence there too.

**Acceptance.** Both clients, both states (with photo, opted out), on controlled
data. Use a labelled fixture or an authorised test round — **not** the owner's
real account as a disposable test, and no private captures committed.

---

## Ownership and sequence

- Claude: lead builder, sole editor of `index.html` and of web tests, on an
  owned branch from `1bc307f`.
- Codex: independent review of committed checkpoints, native repair in its own
  workspace, integration.
- Neither agent edits the other's active branch.
- Every checkpoint returns: web half, native half, explicit differences, and a
  working HTTPS phone preview — signing must not block web delivery.

Suggested order: **F-2 first** (it needs no rulings, and it is the owner's own
phone on a site that is already live), then **F-3** (needs a fixture decision,
not an approval), then **F-1** (blocked on two brand rulings).

Database deploy owed: none. Edge deploy owed: none.
