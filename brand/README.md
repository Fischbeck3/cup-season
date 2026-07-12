# Cup Season — brand assets

The mark: a flag standing in the cup, orbited by a four-arc ring in the
squad colors (green `#43E07C`, blue `#57A8FF`, orange `#FB8B4B`, violet
`#A78BFA`). Green leads (lower-left) — it's the brand accent.

## Files

| File | Use |
|---|---|
| `mark.svg` | Master mark, dark backgrounds. Scales anywhere. |
| `mark-light.svg` | Mark for white/light backgrounds (ink flag, deepened ring). |
| `lockup-dark.png` | Mark + CUP SEASON wordmark, transparent, for DARK surfaces. Email headers on dark, social banners. 2× (retina). |
| `lockup-light.png` | Same lockup for WHITE surfaces — **the email/marketing default**. 2×. |
| `../og-image.png` | 1200×630 social card (Open Graph / Twitter). Referenced from index.html metas. |
| `../icon-192.png` `../icon-512.png` | PWA install icons (dark tile, full mark). |
| `../icon-512-maskable.png` | Maskable variant — mark held inside the 80% safe zone. |
| `../apple-touch-icon.png` | 180×180 iOS home-screen icon. |

## Rules

- Email clients don't render SVG — always use the PNG lockups in mail.
- Don't recolor the ring; on light backgrounds use the `-light` variants,
  never opacity tricks.
- Clear space around the mark: half the ring's diameter on all sides.
- The wordmark is IBM Plex Mono 600, tracked ~0.32em, always CAPS.
- Regeneration: assets are canvas-rendered from the in-app mark
  (`scripts/` step lives in the v23.70 commit message); keep this folder
  in sync when the mark changes.
