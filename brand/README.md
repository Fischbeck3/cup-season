# Cup Season — brand assets

## The production mark is the CS pennant (D358, owner-ratified 2026-09-14)

**One authoritative source, one generator, one family.**
`brand/candidates/testflight-pennant/source.json` holds the geometry and
`tools/build-beta-mark.sh` draws everything from it: the phone's app icon set,
the Swift `CSBrandMark`, the light/dark/one-colour vectors and lockups, and the
**web family** — `favicon.svg`, `favicon-32`, `icon-192`, `icon-512`,
`icon-512-maskable`, `apple-touch-icon` and the 1200×630 `og-image`. Those web
files are generated into `candidates/testflight-pennant/generated/web/` and
**installed at the site root**, which is what the served pages reference. Never
hand-edit one: change the source, re-run the script, copy the family across in
one commit so a tab, a home screen and a link preview can never disagree.

The tile is a **fescue field, a cream pennant and sparse, fine contours**. The
contour field is dropped at 32px and below — the tab and the small favicon take
the simplified drawing — because the ruling allows simplifying the contours
wherever clarity needs it. The mark signs identity (welcome, mastheads, app
icon, shared artifacts) and is used sparingly; it is not a generic action icon
(LINT-28).

Everything below this line describes **the Tracer**, the former mark. It is
kept as history for that asset family, and `tools/make-icons.py` /
`tools/make-og-image.py` are its generators, not the product's.

---

**The mark — the Tracer (historical).** One shot falls out of the sky and lands in the
flagged cup: a tapered comet (the ball flight), a proud pin with a wedge
pennant, the cup catching both. Flat ember `#F4712E` — the mark NEVER takes
the gradient (it bands at 32px and dies in monochrome). It goes on every icon,
the favicon (index.html AND legal.html), the apple-touch icon, the maskable
tile, the App Store square and the in-app header. **Chosen at 16 pixels
first** — the tab is where a weak mark hides in plain sight.

**The door manufactures the mark.** Entry V5 (the Forge, `index.html`): four
tracers land on the heat ramp, then three burn off and the survivor hands its
line to the icon-weight mark — the door RESTS on the logo, so every sign-in
replays where the mark came from. Return visits get the Stamp (the finished
mark sears in, ~1.5s) via `localStorage.cs_forge`; `?forge` replays the
ceremony. The old D91 quarantine ("the crest never shrinks") is resolved: the
crest's idea survives at icon weight, so mark and key visual are finally the
same drawing at two volumes.

> **Regenerating rasters:** `python tools/make-icons.py` renders every PNG
> below from the mark's exact geometry (icons, App Store, lockups), and
> `python tools/make-og-image.py` composes the link preview. Both scripts sit
> in `tools/` and not here on purpose — `stamp-version.sh` copies this whole
> folder into `dist/`, so anything left here is served publicly. The lockups
> need IBM Plex Mono in `tools/fonts/` (gitignored; fetch URL in the script
> header). Never hand-edit a PNG: change the SVGs, re-run the scripts.

## Files

| File | Use |
|---|---|
| `mark.svg` | Master mark, ember on dark grounds. Scales anywhere. |
| `mark-light.svg` | Mark for white/light grounds — takes ink, never opacity tricks. |
| `mark-tile.svg` | Icon tile master (ember field, charcoal knockout, rx 21). |
| `mark-tile-maskable.svg` | Maskable master — art recentred, held inside the 80% safe circle. |
| `mark-appstore.svg` | App Store master — square, opaque, NO rounding (Apple masks it). |
| `appstore-1024.png` | 1024×1024 App Store submission render. |
| `lockup-dark.png` | Mark + CUP SEASON wordmark (IBM Plex Mono 600), transparent, DARK surfaces. 2×. |
| `lockup-light.png` | Same lockup for WHITE surfaces — **the email/marketing default**. 2×. |
| `../og-image.png` | 1200×630 link preview — the forge's moment: three tracers inbound, the mark already forged. |
| `../icon-192.png` `../icon-512.png` | PWA install icons (from mark-tile). |
| `../icon-512-maskable.png` | Android maskable (from mark-tile-maskable). |
| `../apple-touch-icon.png` | 180×180 iOS home-screen icon — square + opaque (iOS masks it). |

## Rules

- **SUPERSEDED FOR THE PRODUCTION MARK (D358, 2026-09-14).** The tile is a
  **fescue field with a cream pennant and sparse, fine contours**, simplified at
  small sizes for legibility. The rule below described the Tracer's tile and is
  kept as history for that asset family.
- **Solid ember field, never a black tile** — a near-black tile reads as a
  hole between home-screen icons.
- **Flat ember only in the mark.** The gradient (`#F2A03D` → `#FF5A2E`) is an
  expressive treatment for large surfaces (door glow, heat ramp), never the
  mark itself.
- Light grounds use `mark-light.svg` (ink), never opacity tricks.
- Email clients don't render SVG — always the PNG lockups in mail.
- Clear space: one pennant-height on all sides of the bare mark.
- The wordmark is IBM Plex Mono 600, tracked ~0.32em, always CAPS. (The door's
  seared serif "CUP SEASON" is the door's voice, not the lockup's.)
- ~~The favicon data-URIs in `index.html` and `legal.html` must always equal
  `mark-tile.svg`~~ — **superseded (D358).** Both pages now link the generated
  `/favicon.svg`, with `/favicon-32.png` behind it for browsers that want a
  raster. There is no hand-written favicon left to go stale, which was the
  point of the rule.
