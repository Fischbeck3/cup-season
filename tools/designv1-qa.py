#!/usr/bin/env python3
"""Build review comparisons, never app assets. Requires the local QA Pillow install.

Usage: python3 tools/designv1-qa.py /absolute/review/directory
Original simulator PNGs are never altered. Reference screen interiors (without
hardware frames) are normalized to 402×874 for comparison with the iPhone 17 Pro.
The concept phones have a different aspect ratio; this normalization is explicit.
"""
import hashlib
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(sys.argv[1]).resolve()
OUT.mkdir(parents=True, exist_ok=True)
REFERENCE = ROOT / "Desingv1.png"
source = Image.open(REFERENCE).convert("RGB")
size = (int(sys.argv[2]), int(sys.argv[3])) if len(sys.argv) > 3 else (402, 874)
crops = {
    "home": (342, 111, 569, 681),
    "board": (604, 111, 837, 681),
    "round": (876, 109, 1118, 678),
    "rivalry": (1158, 109, 1398, 685),
}
manifest = {
    "reference": str(REFERENCE), "sha256": hashlib.sha256(REFERENCE.read_bytes()).hexdigest(),
    "dimensions": source.size, "comparison_dimensions": size, "reference_crops": crops,
    "method": f"Reference interior normalized to {size[0]}x{size[1]}; actual scaled to the same size. No content retouching.",
}
(OUT / "comparison-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

def pair(left, right, label):
    result = Image.new("RGB", (size[0] * 2 + 24, size[1] + 32), "#F4F1E9")
    draw = ImageDraw.Draw(result)
    draw.text((8, 8), "DesignV1 target", fill="#0F1A15")
    draw.text((size[0] + 24, 8), label, fill="#0F1A15")
    result.paste(left, (0, 32)); result.paste(right, (size[0] + 24, 32))
    return result

for screen, bounds in crops.items():
    target = source.crop(bounds).resize(size, Image.Resampling.LANCZOS)
    target.save(OUT / f"{screen}-target.png")
    name = f"{screen}-{'dark' if screen == 'rivalry' else 'light'}.png"
    if not (OUT / name).exists():
        continue
    actual = Image.open(OUT / name).convert("RGB").resize(size, Image.Resampling.LANCZOS)
    pair(target, actual, "Actual simulator" + (" · DEBUG fixture" if screen == "rivalry" else "")).save(OUT / f"{screen}-comparison.png")
    Image.blend(target, actual, 0.5).save(OUT / f"{screen}-overlay.png")
    pair(target.filter(ImageFilter.GaussianBlur(12)), actual.filter(ImageFilter.GaussianBlur(12)), "Actual · 12px blur").save(OUT / f"{screen}-blur.png")

mark = source.crop((45, 124, 264, 247))
mark.save(OUT / "reference-mark.png")
logos = Image.new("RGB", (720, 450), "#F4F1E9")
draw = ImageDraw.Draw(logos)
draw.text((24, 12), "DesignV1 primary symbol", fill="#0F1A15")
draw.text((380, 12), "Production vector master", fill="#0F1A15")
y = 50
for n in (256, 64, 32, 16):
    h = round(n * 0.57)
    draw.text((12, y), f"{n}px", fill="#0F1A15")
    logos.paste(mark.resize((n, h), Image.Resampling.LANCZOS), (70, y))
    actual = Image.open(ROOT / f"brand/candidates/testflight-pennant/generated/mark-{n}.png").convert("RGBA")
    logos.paste(actual, (425, y), actual)
    actual.save(OUT / f"production-mark-{n}.png")
    y += h + 36
logos.save(OUT / "logo-comparison.png")
Image.open(ROOT / "apps/ios/CupSeason/Assets.xcassets/AppIcon.appiconset/app-icon.png").save(OUT / "app-icon-asset.png")
print(f"Comparison artifacts: {OUT}")

# An index and contact sheets make the acceptance artifact repeatable too.
def contact_sheet(entries, filename):
    entries = [(title, name) for title, name in entries if (OUT / name).exists()]
    if not entries:
        return
    width = 300
    height = round(width * size[1] / size[0])
    sheet = Image.new("RGB", (len(entries) * (width + 16), height + 42), "#F4F1E9")
    draw = ImageDraw.Draw(sheet)
    for i, (title, name) in enumerate(entries):
        x = i * (width + 16)
        draw.text((x + 8, 10), title, fill="#0F1A15")
        image = Image.open(OUT / name).convert("RGB").resize((width, height), Image.Resampling.LANCZOS)
        sheet.paste(image, (x + 8, 34))
    sheet.save(OUT / filename)

heroes = [("Home · real account", "home-light.png"), ("The Board · real account", "board-light.png"),
          ("Round · real account", "round-light.png"), ("Rivalry · DEBUG fixture", "rivalry-dark.png")]
states = [("Home dark", "home-dark.png"), ("Round dark", "round-dark.png"),
          ("Rivalry · real empty", "rivalry-real-empty.png")]
contact_sheet(heroes, "four-screens.png")
contact_sheet(states, "state-checks.png")
sections = []
def gallery(title, entries):
    cards = "".join(f'<figure><a href="{name}"><img src="{name}" alt="{label}" loading="lazy"></a><figcaption>{label}</figcaption></figure>'
                    for label, name in entries if (OUT / name).exists())
    sections.append(f'<section><h2>{title}</h2><div class="grid">{cards}</div></section>')

gallery("A · Logo QA", [("Target | production · 256 / 64 / 32 / 16px", "logo-comparison.png"),
                       ("Generated iOS app icon", "app-icon-asset.png")])
gallery("B · Actual app screenshots", heroes)
gallery("C · State checks", states + [("Home AX3", "home-AX3.png"), ("Round AX3", "round-AX3.png"),
                                      ("Board AX3", "board-AX3.png"), ("App icon on iOS", "app-icon-home-screen.png")])
gallery("D · Target | actual", [(screen, f"{screen}-comparison.png") for screen in crops])
gallery("50% overlays", [(screen, f"{screen}-overlay.png") for screen in crops])
gallery("Blurred silhouette comparison · 12px", [(screen, f"{screen}-blur.png") for screen in crops])
(OUT / "index.html").write_text('''<!doctype html><meta charset="utf-8"><title>Cup Season · DesignV1 Pass 2</title>
<style>body{margin:32px auto;padding:0 24px;max-width:1400px;background:#F4F1E9;color:#0F1A15;font:16px system-ui}
h1,h2{font-family:Georgia,serif}section{margin:48px 0}a{color:inherit}.grid{display:flex;gap:20px;flex-wrap:wrap}
figure{margin:0;flex:1 1 280px;max-width:680px}img{width:100%;height:auto}figcaption{padding:10px 0;color:#26352E}</style>
<h1>Cup Season · DesignV1 Pass 2</h1><p>Owner visual review only. No archive or TestFlight action.</p>
<p>Canonical reference: <a href="../cup-season/Desingv1.png">Desingv1.png</a> · 1448 × 1086.<br>
SHA-256: 5e6c73d5c3d0bd537ba3999af6056b31b6a3fe120de627185f1bdbaf3e141797</p>
<p>Actual captures: signed-in CS-SE3, 375 × 667 points. Original simulator PNGs remain unedited.
The concept screen interiors have a different aspect ratio and are normalized to the same canvas for overlays;
this includes nonuniform reference scaling. See <a href="comparison-manifest.json">crop coordinates and method</a>.</p>
<p>Two real standings entries remain two; points remain points. The captured round has no confirmed par or FIR/GIR/putts.
Rivalry has no linked photo or multi-person ranking in its payload. No fake slots were added to fill the concept.</p>
<p><a href="STATUS.md">Results and compromises</a> · <a href="files-changed.txt">Files changed</a> ·
<a href="final-tests.json">Final tests</a> · <a href="preflight.log">Preflight</a></p>''' + "".join(sections))
