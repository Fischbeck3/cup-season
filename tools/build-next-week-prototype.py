#!/usr/bin/env python3
"""Build the standalone review artifact from existing tokens and brand assets."""
import base64
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
groups = json.loads((ROOT / 'packages/tokens/tokens.json').read_text())['groups']

def token(group, name, room):
    item = groups[group]['tokens'][name]
    return item.get(room, item['dark'])

def data(path, mime):
    return 'data:' + mime + ';base64,' + base64.b64encode((ROOT / path).read_bytes()).decode()

css = []
for room in ('light', 'dark'):
    values = {name: token(group, name, room) for group in ('ground', 'text', 'semantic', 'metal', 'radius', 'type') for name in groups[group]['tokens']}
    values.update({'paper': token('ground', 'bg0', 'light'), 'paper-ink': token('text', 'ink', 'light'), 'dusk': token('ground', 'bg0', 'dark'), 'dusk-ink': token('text', 'ink', 'dark')})
    css.append('html[data-room="' + room + '"]{' + ''.join('--' + name + ':' + str(value) + ';' for name, value in values.items()) + '}')
replacements = {
    '__TOKENS__': '\n'.join(css),
    '__FONT__': data('apps/ios/CupSeason/Resources/Fonts/IBMPlexSansCondensed-SemiBold.ttf', 'font/ttf'),
    '__MARK__': (ROOT / 'brand/candidates/testflight-pennant/generated/mark-one-color.svg').read_text().strip(),
    '__TOPO__': json.loads((ROOT / 'brand/candidates/testflight-pennant/source.json').read_text())['topo'],
    '__ICON__': data('apps/ios/CupSeason/Assets.xcassets/AppIcon.appiconset/app-icon.png', 'image/png'),
    '__SMALLICON__': data('brand/candidates/testflight-pennant/generated/icon-32.png', 'image/png'),
}
html = (ROOT / 'docs/prototypes/next-week.template.html').read_text()
for key, value in replacements.items():
    html = html.replace(key, value)
assert not re.search(r'__[A-Z]+__', html), 'Unresolved template placeholder'
out = ROOT / 'docs/prototypes/next-week.html'
out.write_text(html)
print(f'Built {out.relative_to(ROOT)} ({out.stat().st_size:,} bytes)')
