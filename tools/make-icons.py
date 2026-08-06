#!/usr/bin/env python3
"""Regenerate every raster icon and lockup from the Tracer mark.

The mark (2026-08-06 final): one shot falls out of the sky and lands in the
flagged cup — the tapered comet is the ball flight, the pin stands proud, the
cup catches both. Master art is brand/mark*.svg; this script renders the SAME
geometry to PNG so the two can never drift. If you change the mark, change the
SVGs and re-run this — never hand-edit a PNG.

Lives in tools/ deliberately — stamp-version.sh copies brand/ wholesale into
dist/, so a script placed there would be served publicly. Same reasoning as
make-og-image.py.

Fonts: IBM Plex Mono SemiBold (OFL) is expected at tools/fonts/. It is
gitignored — grab it from
https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexmono/IBMPlexMono-SemiBold.ttf
The lockups are the only outputs that need it; the icons render without.

Run:  python tools/make-icons.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRAND = os.path.join(ROOT, "brand")
FONTS = os.path.join(ROOT, "tools", "fonts")

EMBER = (244, 113, 46)      # #F4712E — one ember, everywhere. No gradient.
CHARCOAL = (12, 13, 15)     # #0C0D0F
BONE = (244, 247, 244)      # #F4F7F4

SS = 4                      # supersample factor; PIL has no vector AA
TILE_R = 21 / 96            # squircle radius as a fraction of the tile

# ---- the mark, in its 96x96 viewBox ----------------------------------------
CUP = (38, 79, 17, 6.5)                                   # cx cy rx ry
POLE = (27, 13, 10, 68, 5)                                # x y w h rx
PENNANT = [(36, 13), (74, 26), (36, 39)]
# the comet: a tapered fill bounded by four cubics — outer edge, head cap,
# inner edge, tail cap. Same path data as the SVGs' comet.
COMET = (
    ((88, 12), (82, 36), (70, 59), (54, 73)),
    ((54, 73), (51, 76), (47, 75), (46, 72)),
    ((46, 72), (60, 60), (73, 38), (83, 13)),
    ((83, 13), (84, 10), (87, 9), (88, 12)),
)

# Ink bounds inside the 96 box. Icons map the whole 96 box so the PNG matches
# the SVG exactly; the maskable recentres on this, the lockups lay out on it.
ART = (21, 9, 88, 85.5)
ART_C = ((ART[0] + ART[2]) / 2, (ART[1] + ART[3]) / 2)    # (54.5, 47.25)


def bezier(p0, p1, p2, p3, n=200):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        pts.append((
            u**3 * p0[0] + 3 * u**2 * t * p1[0] + 3 * u * t**2 * p2[0] + t**3 * p3[0],
            u**3 * p0[1] + 3 * u**2 * t * p1[1] + 3 * u * t**2 * p2[1] + t**3 * p3[1],
        ))
    return pts


def draw_mark(d, ox, oy, s, color):
    """Draw the mark with its 96-space origin at (ox, oy), scaled by s."""
    def X(x, y):
        return (ox + x * s, oy + y * s)

    poly = []
    for seg in COMET:
        poly += bezier(*seg, n=120)
    d.polygon([X(*p) for p in poly], fill=color)

    cx, cy, rx, ry = CUP
    d.ellipse([*X(cx - rx, cy - ry), *X(cx + rx, cy + ry)], fill=color)

    px, py, pw, ph, pr = POLE
    d.rounded_rectangle([*X(px, py), *X(px + pw, py + ph)], radius=pr * s, fill=color)

    d.polygon([X(*p) for p in PENNANT], fill=color)


def icon(size, path, rounded=True, scale=1.0, opaque=False):
    """One ember tile with the mark knocked out in charcoal.

    rounded=False for apple-touch-icon, the maskable tile and the App Store
    square: iOS and Android apply their OWN mask, and a pre-rounded source
    double-rounds into dark notches at the corners.
    """
    W = size * SS
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if rounded:
        d.rounded_rectangle([0, 0, W - 1, W - 1], radius=W * TILE_R, fill=EMBER)
    else:
        d.rectangle([0, 0, W, W], fill=EMBER)

    s = (W / 96) * scale
    if scale == 1.0:
        ox = oy = 0.0                         # full 96-box map — matches the SVG tile
    else:
        # maskable: recentre the ART (not the viewBox) so the safe-circle math
        # in mark-tile-maskable.svg holds here too
        ox = W / 2 - ART_C[0] * s
        oy = W / 2 - ART_C[1] * s
    draw_mark(d, ox, oy, s, CHARCOAL)

    img = img.resize((size, size), Image.LANCZOS)
    if opaque:
        img = img.convert("RGB")
    img.save(path)
    print("  %-34s %dx%d %s" % (os.path.basename(path), size, size,
                                "opaque" if opaque else "alpha"))


def lockup(path, mark_color, text_color):
    """Mark + CUP SEASON wordmark, transparent ground, 2x retina.

    IBM Plex Mono 600, caps, tracked 0.32em. Clear space is one pennant-height
    (28/96 of the mark box) on all sides, and the same gap between the two.
    """
    face = os.path.join(FONTS, "IBMPlexMono-SemiBold.ttf")
    if not os.path.exists(face):
        print("  SKIP %s — IBM Plex Mono SemiBold not in tools/fonts/" % os.path.basename(path))
        return

    ax0, ay0, ax1, ay1 = ART
    MARK_H = 180                              # rendered height of the INK, 2x
    s = MARK_H / (ay1 - ay0)
    MARK_W = (ax1 - ax0) * s
    PAD = round(MARK_H * 26 / 76.5)           # one pennant-height
    TSIZE = 68
    TRACK = round(TSIZE * 0.32)
    word = "CUP SEASON"

    f = ImageFont.truetype(face, TSIZE * SS)
    adv = [f.getlength(c) for c in word]
    tw = (sum(adv) + TRACK * SS * (len(word) - 1)) / SS
    asc, desc = f.getmetrics()

    W = round(PAD * 3 + MARK_W + tw)
    H = round(MARK_H + PAD * 2)

    img = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # place the ART's bounding box at PAD, not the 96 box — otherwise the
    # viewBox's empty right margin reads as a hole in the lockup
    draw_mark(d, (PAD - ax0 * s) * SS, (PAD - ay0 * s) * SS, s * SS, mark_color)

    mid = (PAD + MARK_H / 2) * SS
    x = (PAD * 2 + MARK_W) * SS
    y = mid - (asc - desc) / 2
    for c, a in zip(word, adv):
        d.text((x, y), c, font=f, fill=text_color)
        x += a + TRACK * SS

    img.resize((W, H), Image.LANCZOS).save(path)
    print("  %-34s %dx%d alpha" % (os.path.basename(path), W, H))


print("[icons] web + app")
icon(192, os.path.join(ROOT, "icon-192.png"))
icon(512, os.path.join(ROOT, "icon-512.png"))
# Android crops to a circle; hold the art inside the 80% safe zone (r 38.4).
# Recentred on the ink bbox and held at 0.75: half-diagonal 50.85 x 0.75 = 38.1.
icon(512, os.path.join(ROOT, "icon-512-maskable.png"), rounded=False, scale=0.75)
# iOS masks it itself, and the App Store rejects alpha outright.
icon(180, os.path.join(ROOT, "apple-touch-icon.png"), rounded=False, opaque=True)
icon(1024, os.path.join(BRAND, "appstore-1024.png"), rounded=False, opaque=True)

print("[icons] lockups")
lockup(os.path.join(BRAND, "lockup-dark.png"), EMBER, BONE)
lockup(os.path.join(BRAND, "lockup-light.png"), CHARCOAL, CHARCOAL)
print("[icons] ok")
