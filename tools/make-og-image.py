#!/usr/bin/env python3
"""Regenerate og-image.png — the link preview — from the door's crest (D91).

WHY THIS EXISTS: the sign-in door has carried the crest (four tracers landing
on a flagged cup) since D76, while every link preview showed a plain flag
lockup. Someone who saw a settlement card in a text thread and then opened the
app met two different products. This composes the SAME geometry as the door
into the 1200x630 card so the two surfaces agree.

The mark is NOT changing: the ember flag stays on every icon and favicon (D89).
This is the key visual only.

Lives in tools/ deliberately — stamp-version.sh copies brand/ wholesale into
dist/, so a script placed there would be served publicly.

Run:  python tools/make-og-image.py
Then: verify the PNG is 1200x630 and looks right before committing.
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "og-image.png")

W, H = 1200, 630
CHARCOAL = (12, 13, 15)
EMBER = (255, 90, 46)
FIRE = (255, 59, 26)
AMBER = (233, 162, 59)
INK = (240, 242, 243)
PAPER = (244, 247, 244)
SLATE = (142, 151, 158)

# crest viewBox is 0 0 460 300; place it centred with the cup on the upper third
S = 1.5
OX = 600 - 230 * S          # cup cx=230 lands dead centre
OY = 10


def P(x, y):
    """crest coordinate -> canvas coordinate"""
    return (OX + x * S, OY + y * S)


def bezier(p0, p1, p2, p3, n=160):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        x = u**3 * p0[0] + 3 * u**2 * t * p1[0] + 3 * u * t**2 * p2[0] + t**3 * p3[0]
        y = u**3 * p0[1] + 3 * u**2 * t * p1[1] + 3 * u * t**2 * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts


def font(path, size):
    return ImageFont.truetype(os.path.join(r"C:\Windows\Fonts", path), size)


img = Image.new("RGB", (W, H), CHARCOAL)

# ---- the heat pooled at the cup: a blurred ember ellipse ---------------------
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
cx, cy = P(230, 238)
rx, ry = 150 * S, 44 * S
gd.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=EMBER + (52,))
# 58px of blur turned the pool into a brown smudge — the door's glow is a
# radial stop, not a bloom, so keep it tight enough to still read as ember
glow = glow.filter(ImageFilter.GaussianBlur(40))
img = Image.alpha_composite(img.convert("RGBA"), glow)

layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(layer)

# ---- rings spreading from where the tracers land ----------------------------
for r_x, r_y, cyy, alpha in ((118, 32, 236, 32), (78, 22, 233, 58), (44, 13, 230, 92)):
    ex, ey = P(230, cyy)
    d.ellipse([ex - r_x * S, ey - r_y * S, ex + r_x * S, ey + r_y * S],
              outline=EMBER + (alpha,), width=2)

# ---- the four tracers, on the heat ramp -------------------------------------
TRACERS = [
    (((-24, 96), (80, 118), (160, 176), (224, 224)), AMBER),
    (((96, -20), (140, 66), (190, 160), (227, 222)), EMBER),
    (((364, -20), (320, 66), (270, 160), (233, 222)), FIRE),
    (((484, 96), (380, 118), (300, 176), (236, 224)), INK),
]
for pts, colour in TRACERS:
    curve = bezier(*[P(*p) for p in pts])
    d.line(curve, fill=colour + (217,), width=4, joint="curve")

# ---- the cup, and the flag standing in it -----------------------------------
ex, ey = P(230, 226)
d.ellipse([ex - 15 * S, ey - 5.5 * S, ex + 15 * S, ey + 5.5 * S],
          fill=(10, 11, 13, 255), outline=(51, 32, 24, 255), width=3)

px, py1 = P(236, 223)
_, py2 = P(236, 120)
d.line([(px, py1), (px, py2)], fill=INK + (255,), width=6)
d.polygon([P(236, 120), P(274, 133), P(236, 146)], fill=EMBER + (255,))

bx, by = P(230, 224)
d.ellipse([bx - 6.75, by - 6.75, bx + 6.75, by + 6.75], fill=PAPER + (255,))
d.ellipse([ex - 15 * S, ey - 5.5 * S, ex + 15 * S, ey + 5.5 * S],
          outline=EMBER + (255,), width=2)

img = Image.alpha_composite(img, layer).convert("RGB")

# ---- wordmark + tagline, in the brand's own faces ---------------------------
d = ImageDraw.Draw(img)
# SERIF stack is 'Charter','Iowan Old Style','Palatino Linotype',Georgia — Georgia
# is the member of it that exists on this machine, and the one the settlement
# card falls back to, so the two artifacts stay in the same voice.
title = font("georgia.ttf", 80)
tag = font("segoeui.ttf", 27)

t = "Cup Season"
tw = d.textbbox((0, 0), t, font=title)
d.text(((W - (tw[2] - tw[0])) / 2 - tw[0], 452), t, font=title, fill=INK)

s = "Season-long golf with your crew — points, pot, pressure."
sw = d.textbbox((0, 0), s, font=tag)
d.text(((W - (sw[2] - sw[0])) / 2 - sw[0], 556), s, font=tag, fill=SLATE)

img.save(OUT, "PNG", optimize=True)
print(f"wrote {OUT} — {img.size[0]}x{img.size[1]}, {os.path.getsize(OUT)} bytes")
