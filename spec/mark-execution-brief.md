# The Mark — Execution Brief (Territory 1: The Marker)

Growth/Launch lane · 2026-07-17 · hands off to the **design lane**
Status: **adopted pending Jerecho's veto** (bible §11 step 1, "in your order").
If vetoed, the fallback control is Territory 4 (Orbit, evolved) — same gates,
§5 still applies.

## The concept, in two sentences

The mark is a **stamped ball-marker coin**: a circular badge in one-color
relief, champagne on dusk. It wins because golfers already carry one, the ball
marker is *already* the in-app identity token (the golfer card's marker
field), and it makes brand mark, profile identity, and the one piece of merch
every golfer would actually use **the same physical object**.

## Construction notes (direction, not dictation)

- **A coin has two faces — use both.**
  - **Obverse (the primary mark):** the flag standing in the green's cup,
    reduced to one-color relief inside the coin's ring. Carry the current
    mark's perspective-cup DNA (`brand/mark.svg`) so the equity PIGL knows
    survives the redesign — simplified, no orbit, no multicolor.
  - **Reverse (the secondary mark):** the CS monogram, engraver's cut (canon
    §6 territory 5) — for trophy plates, season books, wax-seal moments.
- **Relief, not line art.** The coin should read *stamped* (solid + negative
  space), not *drawn* (hairlines). Hairlines die at 16px and in embroidery.
- **Ring text is optional and earned:** if used, mono caps ("CUP SEASON" ·
  founded year), tracked wide, never a slogan.
- **Color logic (canon §4):** champagne `#D8B25A` relief on dusk `#0A0E0C` is
  the default coin. On paper surfaces, ink-champagne `#9A7418`. Fairway-green
  and squad-color coins are allowed as *variants* (e.g., squad avatars), never
  the primary.
- **Wordmark:** keep **mono caps** (the record's voice — per `brand/README.md`
  it's IBM Plex Mono 600, tracked ~0.32em). The serif is for ceremony
  headlines, not the lockup. This resolves the open question flagged in canon
  §6.

## Process — the kill-70% pass (applies here and only here)

1. Sketch **8–10 coin variations** (obverse compositions: flag angle, cup
   perspective, ring weight, with/without ring text).
2. Kill to **2–3** against the gates below — be brutal; "too safe" dies.
3. Test survivors at **16px favicon**, on a **hat mockup**, and as a
   **one-color stamp** before any polish.
4. Jerecho picks. One round of refinement, then freeze and regenerate.

## Acceptance gates (from canon §6 — all five, in order)

1. **Hat test** — wearable by someone who's never heard of the app.
2. **Archive test** — right in the crew's 2046 season book.
3. **Embroidery** — 2–3 thread colors, no gradients, no hairlines, ~2".
4. **One-color version** — engraving, stamping, 16px favicon.
5. **Crops** — circle avatar + maskable 80% safe zone; works on dusk AND paper.

## Deliverables checklist (regeneration per `brand/README.md`)

- [ ] `mark.svg` (dark) + `mark-light.svg`
- [ ] Lockup PNGs (dark + light, 2×) — mono-caps wordmark
- [ ] `icon-192.png`, `icon-512.png`, `icon-512-maskable.png`,
      `apple-touch-icon.png`
- [ ] `og-image.png` (1200×630)
- [ ] Reverse/monogram SVG (new: `brand/monogram.svg`)
- [ ] One-color stamp SVG (new: `brand/mark-mono.svg`)
- [ ] In-app mark reference updated (the canvas-render script noted in the
      v23.70 commit) — **code change: NOT this lane; ships with a design-lane
      client push**
- [ ] `brand/README.md` updated (colors, new files, the coin story)

## The physical coin (do this — it's the cheapest brilliant thing available)

Mint **~15 real metal ball markers** of the final obverse (custom coin shops
run ~$3–6/unit at that quantity). Ten are the **Founding League Pro gift**
(status > coupons — GTM §8), a few live in Jerecho's bag for white-glove
meetings, one goes in the press-kit photo. The brand's first merch is the mark
itself doing its job on a green.

## Blocks / unblocks

Blocked by: nothing (canon + this brief are complete inputs).
Unblocks: social templates (bible §4), press-kit assets (bible §10), landing
hero polish (bible §5), the PWA icons on every tester's home screen.
