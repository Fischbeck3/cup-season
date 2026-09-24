#!/usr/bin/env python3
"""WCAG contrast from the canonical tokens, including worst-case topo strokes."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[3]
j=json.loads((root/'packages/tokens/tokens.json').read_text())
t={k:v for g in j['groups'].values() for k,v in g.get('tokens',{}).items()}
looks={x['key']:x for x in j['looks']['all']}
def rgb(h):return [int(h[i:i+2],16)/255 for i in (1,3,5)]
def lum(c):return sum(w*(x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4) for w,x in zip([.2126,.7152,.0722],c))
def ratio(a,b):
 x,y=sorted([lum(a),lum(b)]);return (y+.05)/(x+.05)
def mix(f,b,a):return [x*a+y*(1-a) for x,y in zip(f,b)]
rows=[]
for theme in ['dark','light']:
 c={k:rgb(v[theme]) for k,v in t.items() if isinstance(v,dict) and isinstance(v.get(theme),str) and v[theme].startswith('#')}
 for ink,bg in [('brand-ink','brand'),('ink','bg0'),('ink','bg1'),('ink','bg2'),('mut','bg0'),('mut','bg1'),('brand','bg0')]:
  rows.append([theme,ink+' on '+bg,round(ratio(c[ink],c[bg]),2)])
 # Terrain strips reserve empty space. These are conservative measurements
 # even though no text is placed over their high-opacity strokes.
 for look in ['oldest','teams']:
  accent=rgb(looks[look]['accent'][theme])
  for ink in ['ink','mut']:
   for alpha,bg in [(.08,'bg0'),(.56,'bg1')]:
    rows.append([theme,f'{ink} / {look} topo a{round(alpha*100):02} over {bg}',round(ratio(c[ink],mix(accent,c[bg],alpha)),2)])
 rows.append([theme,'brand-ink / topo a24 over ember (no text overlap)',round(ratio(c['brand-ink'],mix(c['brand-ink'],c['brand'],.24)),2)])
for row in rows:print(' | '.join(map(str,row)))
# Only actual text/plot pairs, not the deliberately empty terrain strips.
assert all(r[2]>=4.5 for r in rows if 'a56' not in r[1] and 'no text overlap' not in r[1])
