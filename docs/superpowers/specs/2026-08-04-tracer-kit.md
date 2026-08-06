# The Tracer — master SVG kit (SUPERSEDED 2026-08-06)

> This kit's arc-as-pole geometry was replaced during execution review — it
> read as a wilted flag and matched nothing in the door. The shipped geometry,
> the door decision (Forge + Stamp) and the regeneration pipeline live in
> `2026-08-04-tracer-mark-brief.md`, FINAL section. Kept for provenance.


Chosen mark: board option 4c — the tracer arcing down into the cup, straight wedge
pennant, hoist curved into the arc so pole and flag are one silhouette.

## Geometry (96×96)
- Cup: ellipse (27, 82) rx 14 ry 5.5
- Tracer: `M27 80 C30 54 36 30 47 19`, stroke 12, round cap
- Pennant: `M44 15 L84 30 L40.5 43 C42.5 34 43 24 44 15 Z`

## Colors
- Ember (flat field): `#F4712E` — one ember, everywhere. No gradient in the mark.
- Charcoal (knockout / light-ground ink): `#0C0D0F`

## Files
| File | Use |
|---|---|
| `mark.svg` | Bare mark, dark grounds (in-app header, watermarks) |
| `mark-light.svg` | Bare mark, white/light grounds |
| `mark-tile.svg` | Icon tile — master for icon-192 / icon-512 / apple-touch-icon |
| `mark-tile-maskable.svg` | icon-512-maskable — mark at 0.8 inside the 80% safe zone |
| `mark-appstore.svg` | 1024×1024 App Store — square, opaque, no rounding |

## Favicon (index.html AND legal.html — kills the stray)
```html
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 96 96'%3E%3Crect width='96' height='96' rx='21' fill='%23F4712E'/%3E%3Cellipse cx='27' cy='82' rx='14' ry='5.5' fill='%230C0D0F'/%3E%3Cpath d='M27 80 C30 54 36 30 47 19' fill='none' stroke='%230C0D0F' stroke-width='12' stroke-linecap='round'/%3E%3Cpath d='M44 15 L84 30 L40.5 43 C42.5 34 43 24 44 15 Z' fill='%230C0D0F'/%3E%3C/svg%3E">
```

## In-app header (#hdrLogo) — bare mark, 24px
```html
<svg viewBox="0 0 96 96" fill="none" style="width:24px; height:24px; flex:none" aria-hidden="true">
  <ellipse cx="27" cy="82" rx="14" ry="5.5" fill="#F4712E"/>
  <path d="M27 80 C30 54 36 30 47 19" fill="none" stroke="#F4712E" stroke-width="12" stroke-linecap="round"/>
  <path d="M44 15 L84 30 L40.5 43 C42.5 34 43 24 44 15 Z" fill="#F4712E"/>
</svg>
```
(On light theme use `var(--ink)`-style charcoal, per mark-light.)

## Rules carried forward
- Wordmark: IBM Plex Mono 600, tracked ~0.32em, always caps.
- Clear space: one pennant-height on all sides of the bare mark.
- Don't center it; don't outline it; don't recolor the field per context.
- D89/D91 should be cross-referenced when this ships.
