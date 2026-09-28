from pathlib import Path
import json, re

root = Path('/Users/fischbeck3/cup-season-ten-gallery')
out = root / 'approved'
base = (root / 'index.html').read_text()
style = re.search(r'<style>(.*?)</style>', base, re.S).group(1).replace('url(fonts/', 'url(../fonts/')
style += '\n.pair{grid-template-columns:minmax(0,1fr) minmax(0,1fr)}.pair h2{grid-column:1/-1;margin:0}.pair img{max-height:750px}a.image{min-height:44px}.note{grid-column:1/-1} @media(max-width:680px){.pair{grid-template-columns:1fr}}'
rows = []
for width in [375,402,1280,1600]:
    for theme in ['dark','light']:
        rows.append(dict(family='Door · web', device=str(width), theme=theme,
                         title=f'Email entry · {width}px · {theme}',
                         before=f'../web/door-email--{width}--{theme}.png',
                         after=f'door-initial--{width}--{theme}.png',
                         note='Fresh initial entry. Email now remains visible and names the field. No authentication submitted. Re-entry and short-height checks are in verification.json.'))
        rows.append(dict(family='Home · web', device=str(width), theme=theme,
                         title=f'Home occasion · {width}px · {theme}',
                         before=f'home-card-baseline--{width}--{theme}.png',
                         after=f'home-card-after--{width}--{theme}.png',
                         note='Focused component capture of the existing event_live fixture. Heading, body and ordinary action exceed 4.5:1. Copy, competition spine and destination are unchanged. Compact crops include fixed navigation; normal scrolling exposes the action, confirmed on baseline and after. Desktop shows the complete card.'))
for r in json.loads((root / 'native-approved-verification/manifest-after.json').read_text()):
    rows.append(dict(family='Door · iPhone', device=r['phone']+' '+r['textSize'], theme=r['theme'],
                     title=f"Email entry · {r['phone']} · {r['theme']} · {r['textSize']}",
                     before='../'+str(Path(r['baselineFile']).relative_to(root)),
                     after='../'+str(Path(r['file']).relative_to(root)),
                     note='Empty field, keyboard visible. Pixels are unchanged; XCTest verifies the accessible name changed from empty to Email before and after typing. Accessibility evidence, not a full VoiceOver usability pass.'))
page = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cup Season · Approved repairs</title><style>'+style+'</style>'
page += '''<main><header><div class="record">CUP SEASON · APPROVED REPAIRS · SEPTEMBER 28, 2026</div><h1>Two repairs, in place.</h1><p>Email has a persistent name on the web and iPhone. Home’s occasion text reads clearly in both themes. Each repair has its own local branch from 5fabf861.</p><p>Selected behavior checks pass. Release gates remain open: an inherited wide-screen Door assertion, a simulator entitlement failure, console warnings and owner device/human proof. Nothing has been pushed or deployed.</p><p><a href="../index.html">Full baseline gallery</a> · <a href="verification.json">Web results</a> · <a href="../native-approved-verification/REPORT.md">Native results</a></p></header><div class="controls"><label>Surface<select id="family"><option value="all">All approved repairs</option><option>Door · web</option><option>Home · web</option><option>Door · iPhone</option></select></label><label>Theme<select id="theme"><option value="all">Both themes</option><option>dark</option><option>light</option></select></label><label>Device / text<select id="device"><option value="all">All captured sizes</option></select></label></div><p id="count" role="status"></p><div id="gallery"></div></main><script>const rows='''
page += json.dumps(rows).replace('</','<\\/')
page += ''';const $=id=>document.getElementById(id);for(const v of [...new Set(rows.map(r=>r.device))]){const o=document.createElement('option');o.textContent=v;$('device').append(o)}function render(){const selected=rows.filter(r=>['family','theme','device'].every(k=>$(k).value==='all'||r[k]===$(k).value));$('count').textContent=selected.length+' matched comparisons · select an image to view it at full size';$('gallery').replaceChildren();for(const r of selected){const s=document.createElement('section');s.className='pair';const h=document.createElement('h2');h.textContent=r.title;s.append(h);for(const side of ['before','after']){const f=document.createElement('figure');const a=document.createElement('a');a.className='image';a.href=r[side];const i=document.createElement('img');i.src=r[side];i.alt=side+' · '+r.title;i.loading='lazy';a.append(i);const c=document.createElement('figcaption');c.textContent=side.toUpperCase();f.append(a,c);s.append(f)}const p=document.createElement('p');p.className='note';p.textContent=r.note;s.append(p);$('gallery').append(s)}}for(const k of ['family','theme','device'])$(k).onchange=render;render();</script></html>'''
(out / 'index.html').write_text(page)
(out / 'gallery-pairs.json').write_text(json.dumps(rows,indent=2)+'\n')
base=base.replace('The evidence before the work.','The baseline and the repairs.')
base=base.replace('This is the baseline checkpoint. Product source is unchanged; after images wait for an approved build.','The original baseline is preserved below. The two approved repairs have a separate before/after gallery.')
if 'href="approved/index.html"' not in base:
    base=base.replace('<a href="web/index.html">Full web evidence</a>','<a href="approved/index.html">View approved repairs</a> · <a href="web/index.html">Full web evidence</a>')
base=base.replace('after: awaiting approved implementation','original baseline · approved repairs linked above')
base=base.replace("h.textContent='After: pending'","h.textContent='Original checkpoint'")
base=base.replace('No implementation is approved. The matching state will be recaptured after the owner selects a slice and says “build it.”','Door email and Home occasion repairs are in the approved-repairs gallery. Other design work remains deferred; this image preserves the original checkpoint.')
(root / 'index.html').write_text(base)
print(f'{len(rows)} before/after pairs; all referenced images exist: '+str(all((out/r[k]).exists() for r in rows for k in ['before','after'])))
