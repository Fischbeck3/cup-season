# The Tracer — Cup Season mark brief

**Status:** direction chosen, geometry is a first draft — open for design to push on.
**Date:** 2026-08-04
**Replaces:** the ember flag (D89) as the app mark. See *Provenance* at the end.

> Not in `brand/` on purpose. `stamp-version.sh` copies that whole folder into
> `dist/`, so anything left there is served publicly at cupseason.app.

---

## 1. The idea in one line

**The ball's flight path and the flagstick are the same stroke.**

One line rises off the ground, bends, and the pennant flies from its top. You
cannot tell where the shot ends and the flag begins, because in this product
they are the same event.

---

## 2. The ethos

Cup Season is not a golf utility. It is a season-long competition among people
who already know each other — separate rounds, played on different courses on
different weekends, all counting toward one cup. The whole thesis is
**convergence**: scattered play resolving into a single settled thing.

The brand already owns that idea. The crest — four tracers on a heat ramp
arcing in from four directions, converging on a flag planted in the cup, rings
spreading from the strike — states it exactly. It runs as an animation on the
sign-in door and sits still on every link preview.

The problem is that the crest was never allowed to be the mark. Its tracers are
2.6px; they disappear below about 32px, so D91 quarantined it to large surfaces
and gave the icon a plain pennant instead. The result is a brand whose
distinctive asset never reaches an icon, and whose icon-sized asset is generic.
An orange flag is the category's stock photo — 18Birdies, Golfshot, Hole19,
TheGrint all ship one. It says *golf*. It does not say *this*.

**The Tracer refuses that split.** It takes the crest's idea — flight
converging on a flag — and redraws it at icon weight instead of illustration
weight. One tracer instead of four. A stroke thick enough to survive 16 pixels
instead of a hairline. Same sentence, larger type.

What that buys:

- **It is a gesture, not an object.** A picture of a flag reads as clipart
  because the idea *is* the flag. A stroke that arcs has motion built into its
  form, so it reads as a mark even before you decode it.
- **It leans.** The composition runs bottom-left to upper-right. Not centered,
  not posed. Golf marks are almost universally static and vertical; this one
  is in the middle of something.
- **It reconciles the family.** Mark and key visual finally use the same
  vocabulary. The crest becomes the Tracer at full volume rather than an
  unrelated second identity.
- **It carries meaning at every size.** At 88px you read *a shot arcing to the
  pin*. At 16px you read *a curve and a wedge* — still unmistakably not a
  vertical stick. The idea degrades gracefully instead of collapsing.

---

## 3. What the mark must survive

Non-negotiable. Any revision that fails one of these is out, however good it
looks at 1024.

| Constraint | Why |
|---|---|
| **Solid field, never black** | The current icon is 92% `#0C0D0F`. On an iOS home screen a near-black tile reads as a hole between its neighbours. The field carries the color; the shape knocks out of it. |
| **One closed silhouette** | The current pole and pennant are two disconnected parts. Below ~24px they merge into a smudge. Every element must touch or overlap. |
| **No gradient** | It bands at 32px and dies completely in greyscale — App Store listings, watch complications, embroidery on a hat, a laser-etched ball marker. Flat ember only. The gradient may survive as an *expressive* treatment on large surfaces, never in the mark. |
| **No stroke thinner than ~10/96** | Anything finer disappears at 16px. This is the exact failure that quarantined the crest. |
| **Monochrome-legible** | Must read as pure black on white with nothing lost but color. Test before anything else. |
| **80% maskable safe zone** | Android crops to a circle. All content inside a centered circle at 80% of the tile width. |
| **Legible at 16px** | The browser tab is where a stale or weak mark hides in plain sight. Test there first, not last. |

---

## 4. Geometry — first draft

96×96 canvas, tile is full-bleed with `rx="21"` (approximate iOS squircle;
final art should use a true superellipse).

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">
  <rect width="96" height="96" rx="21" fill="#F4712E"/>
  <path d="M22 82 C 27 54 34 30 47 19"
        fill="none" stroke="#0C0D0F" stroke-width="12" stroke-linecap="round"/>
  <path d="M44 15 L83 30 L44 45 Z" fill="#0C0D0F"/>
</svg>
```

**Bare mark** (no tile — in-app header, watermarks). Same two paths, `#F4712E`
fill/stroke on charcoal grounds, `#0C0D0F` on light grounds:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">
  <path d="M22 82 C 27 54 34 30 47 19"
        fill="none" stroke="currentColor" stroke-width="12" stroke-linecap="round"/>
  <path d="M44 15 L83 30 L44 45 Z" fill="currentColor"/>
</svg>
```

Notes on the draft, for whoever picks it up:

- The tracer is a single cubic. Its lower end sits at `(22,82)`, so the mark is
  anchored bottom-left and the mass runs to upper-right. That asymmetry is the
  point — resist the urge to center it.
- The pennant's left edge (`x=44`) overlaps the arc's terminus (`47,19`) so
  pole and flag are one silhouette. Keep the overlap on any redraw.
- The arc currently reads a little stiff in its lower third. A tapered stroke
  (variable width, heavier at the bottom) would give it more speed but costs
  the single-path simplicity — worth testing both.
- Nothing here is precious. Curvature, pennant proportion, lean angle, and
  whether the pennant should notch (swallowtail) are all open.

---

## 5. Color

| Role | Hex | Use |
|---|---|---|
| Ember (flat) | `#F4712E` | The field. Sampled between the two gradient stops. |
| Charcoal | `#0C0D0F` | The knockout shape. Also the app's page ground. |
| Bone | `#F4F7F4` | Alternate knockout for a punchier variant — test it. |
| Amber | `#F2A03D` | Gradient stop, expressive surfaces only. |
| Fire | `#FF5A2E` | Gradient stop, expressive surfaces only. |

The exact ember flat is not settled. `#F4712E` is a midpoint, not a decision —
pick the value that holds up against both a white and a black home-screen
wallpaper.

---

## 6. Rules

**Do**

- Test at 16px before anything else.
- Test in pure monochrome second.
- Keep the lean. It is the mark's only source of energy.
- Keep pole and pennant fused.

**Don't**

- Don't center it.
- Don't put it on a black tile.
- Don't recolor the field per context — one ember, everywhere. On light
  surfaces use the charcoal bare mark, never an opacity trick.
- Don't add the other three tracers. That's the crest, and it doesn't shrink.
- Don't outline it. Strokes around the shape close up at small sizes.

**Clear space:** one pennant-height on all sides of the bare mark.
**Wordmark:** IBM Plex Mono 600, tracked ~0.32em, always caps.

---

## 7. Surfaces it has to land on

Everything below currently carries the ember flag or a stray. All of it moves
together — the last time these drifted apart, the app's own header disagreed
with the card it texts you.

| Surface | File |
|---|---|
| Browser tab favicon | `index.html` — inline `data:` SVG, `<link rel="icon">` |
| In-app header | `index.html` — `#hdrLogo` inline SVG |
| PWA install icons | `icon-192.png`, `icon-512.png` |
| Android maskable | `icon-512-maskable.png` — 80% safe zone |
| iOS home screen | `apple-touch-icon.png` (180×180) |
| Link preview | `og-image.png` (1200×630) — crest + wordmark |
| Master art | `brand/mark.svg`, `brand/mark-light.svg` |
| **Stray** | `legal.html` favicon — a *different* mark (white flag + cup ellipse) |
| **Stale** | `brand/lockup-dark.png`, `brand/lockup-light.png` — still the retired four-arc ring |

The App Store submission additionally needs a 1024×1024 with no transparency
and no rounded corners — Apple applies the mask itself.

---

## 8. Open for design

1. **Tapered vs. uniform stroke.** Taper reads faster; uniform stays one path.
2. **Lean angle.** Current arc is fairly upright. Does pushing it flatter help
   or does the mark start to read as a checkmark?
3. **Pennant shape.** Plain wedge, or a swallowtail notch? The notch adds
   character at 60px but closes up by 16px.
4. **Knockout color.** Charcoal (drafted) or bone. Bone is punchier on ember
   but loses the tie to the app's ground.
5. **Does the cup appear?** A punched hole at the arc's base was the competing
   direction and the two compose — tracer arcing down into a hole. Adds the
   convergence payoff at the cost of a third element.
6. **Full-bleed field vs. inset.** Field-to-edge is the assumption. Worth
   testing a variant with an ember disc floating on charcoal.

---

## Provenance

- **D89** retired the four-arc orbit ring from the last three places it
  survived — favicon, app header, `brand/mark.svg` — so one mark shipped
  everywhere. That consolidation is worth keeping; only the artwork changes.
- **D91** split mark from key visual: the flag for icons, the crest for large
  surfaces, on the reasoning that the crest's tracers vanish below 32px. **The
  Tracer treats that split as a false one** — the crest's *idea* survives at
  icon weight even though its *drawing* does not.
- Any change here is a UI-level change under the hierarchy of truth and does
  not touch mechanics. No decision-log entry is required, but the D89/D91
  entries should be cross-referenced when the new mark ships.

---

## FINAL (2026-08-06) — geometry and door decision

The draft geometry above (section 4) is SUPERSEDED. Execution rounds against
the entry animation settled on **the Drop**: the tapered comet falls steeply
from the top corner into the flagged cup; the pin stands proud and straight —
matching the door's own flag, which was always a straight pin. The delivered
zip's arc-as-pole draft read as a wilted flag and appears nowhere else in the
product.

Final geometry (96×96, masters in `brand/`):

```svg
<g fill="#F4712E">
  <path d="M88 12 C 82 36, 70 59, 54 73 C 51 76, 47 75, 46 72 C 60 60, 73 38, 83 13 C 84 10, 87 9, 88 12 Z"/>
  <ellipse cx="38" cy="79" rx="17" ry="6.5"/>
  <rect x="27" y="13" width="10" height="68" rx="5"/>
  <path d="M36 13 L74 26 L36 39 Z"/>
</g>
```

Ink bbox (21,9)–(88,85.5); maskable recentres on its centre (54.5,47.25) at
scale 0.75 so the half-diagonal (50.85) stays inside the 80% safe circle.

**Door: Entry V5, the Forge + the Stamp.** First door showing plays V4's full
show, then the forge — radar and three tracers burn off, the fire tracer
(re-bent to the comet's approach) hands off to the icon-weight mark, and the
door rests ON the logo. Return visits (`localStorage.cs_forge`, decided
pre-paint) get the Stamp: the finished mark slams in white-hot and cools to
ember, ~1.5s to rest; every sear/rise delay compresses ×0.3. `?forge` replays
the ceremony. Both choreographies rest on the identical frame — bare ember
mark + seared wordmark — which is also the lockup, and, tiled, the app icon.

Rest-frame discipline (forceReveal): the mark is the ONLY show element whose
base state is visible; tracers, the illustration flag, the radar and all
transients rest hidden. The mark's positioning transform lives on an outer
group; only the inner group animates.

Rasters regenerate via `tools/make-icons.py` (icons, App Store 1024, Plex
Mono lockups) and `tools/make-og-image.py` (link preview = the forge's
moment: three tracers inbound, the mark already forged).
