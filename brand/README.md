# Cup Season — brand assets

Two pieces of art, two jobs (D91). Do not mix them up.

**The mark — the ember flag.** A pennant on a rounded pole, filled with the
ember gradient (`#F2A03D` → `#FF5A2E`). Nothing else. It goes on every icon,
the favicon, the apple-touch icon, the maskable tile and the in-app header.
D89 retired the old four-arc orbit ring from the last three places it survived
so one mark ships everywhere. **The mark is chosen for 16 pixels** — that is
the whole reason it is this simple, and why it is not the crest.

**The key visual — the crest.** Four tracers on the heat ramp (amber, ember,
fire, white-hot) converging on a flag planted in the cup, rings spreading from
the strike. It lives on the sign-in door as an animation (`index.html`, Entry
V4 / D76) and on the 1200×630 link preview as a still. It is built to be seen
LARGE on a dark ground; its 2.6px tracers disappear below about 32px, so it
never goes on an icon.

> **Regenerating the link preview:** `python tools/make-og-image.py` composes
> `og-image.png` from the crest's exact geometry. The script sits in `tools/`
> and not here on purpose — `stamp-version.sh` copies this whole folder into
> `dist/`, so anything left here is served publicly.

> **Stale PNGs:** `lockup-dark.png` and `lockup-light.png` still render the
> retired ring mark and need regenerating from the SVGs above before they are
> used anywhere. The root icons (`icon-192`, `icon-512`, `icon-512-maskable`,
> `apple-touch-icon`) are correct — they are what the flag was taken from.

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
