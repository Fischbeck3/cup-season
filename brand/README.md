# Cup Season — brand assets

The mark (D89): **the ember flag** — a pennant on a rounded pole, filled with
the ember gradient (`#F2A03D` → `#FF5A2E`). Nothing else. It is the mark the
install icons, the apple-touch icon and every link preview already carried;
D89 retired the old four-arc orbit ring from the last three places it survived
(the favicon, the in-app header, and this folder's SVGs) so one mark ships
everywhere.

> **Stale PNGs:** `lockup-dark.png` and `lockup-light.png` still render the
> retired ring mark and need regenerating from the SVGs above before they are
> used anywhere. The root icons (`icon-192`, `icon-512`, `icon-512-maskable`,
> `apple-touch-icon`, `og-image`) are already correct — they are what the
> flag was taken from.

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
  (Both lockups are stale as of D89; regenerate before use.)
- Don't recolor the gradient; on light backgrounds use the `-light` variant,
  never opacity tricks.
- Clear space around the mark: one flag-height on all sides.
- The wordmark is IBM Plex Mono 600, tracked ~0.32em, always CAPS.
- Regeneration: assets are canvas-rendered from the in-app mark
  (`scripts/` step lives in the v23.70 commit message); keep this folder
  in sync when the mark changes.
