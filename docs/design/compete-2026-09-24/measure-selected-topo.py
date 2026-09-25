#!/usr/bin/env python3
"""Measure actual selected-header ink over worst-case full contour strokes."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[3]
j=json.loads((root/'packages/tokens/tokens.json').read_text())
t={k:v for g in j['groups'].values() for k,v in g.get('tokens',{}).items()}
def rgb(h):return [int(h[i:i+2],16)/255 for i in (1,3,5)]
def luminance(c):return sum(w*(x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4) for w,x in zip([.2126,.7152,.0722],c))
def ratio(a,b):
 lo,hi=sorted([luminance(a),luminance(b)]);return (hi+.05)/(lo+.05)
def mix(f,b,a):return [x*a+y*(1-a) for x,y in zip(f,b)]
for theme in ['dark','light']:
 c={k:rgb(v[theme]) for k,v in t.items() if isinstance(v,dict) and isinstance(v.get(theme),str) and v[theme].startswith('#')}
 live=ratio(c['brand-ink'],mix(c['brand-ink'],c['brand'],.08))
 print(f'{theme} | full brandInk over a08 brandInk contour on ember | {live:.2f}:1')
 assert live>=4.5
 # Neutral header text stays full-strength ink, including the Book title.
 for ground in ['bg0','bg1']:
  choices=[('default',c['act'])]+[(look['key'],rgb(look['accent'][theme])) for look in j['looks']['all']]
  name,worst=min(((name,ratio(c['ink'],mix(accent,c[ground],.24))) for name,accent in choices),key=lambda x:x[1])
  print(f'{theme} | full ink over a24 livery contour on {ground}, worst {name} | {worst:.2f}:1')
  assert worst>=4.5
