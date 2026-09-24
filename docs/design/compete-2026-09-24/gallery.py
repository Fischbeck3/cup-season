#!/usr/bin/env python3
"""Create a standalone local gallery of unedited simulator captures."""
import json, shutil
from pathlib import Path
root=Path(__file__).resolve().parents[3]
out=Path.home()/'cup-season-compete-explorations-review'
out.mkdir(exist_ok=True)
rows=[]
for p in sorted(out.glob('manifest-*.json')): rows += json.loads(p.read_text())
rows=sorted({r['key']:r for r in rows}.values(), key=lambda r:r['key'])
(out/'manifest.json').write_text(json.dumps(rows,indent=2)+'\n')
tokens=json.loads((root/'packages/tokens/tokens.json').read_text())
t={k:v for g in tokens['groups'].values() for k,v in g.get('tokens',{}).items()}
css=';'.join('--'+k+':'+t[k]['dark'] for k in ['bg0','bg1','bg2','ink','mut','rule','brand','act'])
page='''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Compete · three directions and the Book</title>
<style>
:root{TOKENS;color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:var(--bg0);color:var(--ink);font:16px/1.5 system-ui,sans-serif}header,main,footer{max-width:1500px;margin:auto;padding:32px}header{border-bottom:1px solid var(--rule)}.eyebrow{color:var(--mut);font-size:12px;letter-spacing:.14em;text-transform:uppercase}h1{font:600 clamp(32px,5vw,68px)/1.05 Georgia,serif;margin:14px 0 20px;max-width:900px}h2{font-size:28px;margin:0}h3{font:600 25px Georgia,serif;margin:0 0 8px}p{max-width:850px}.quiet{color:var(--mut)}a{color:inherit;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:10px;margin:24px 0}nav a{background:var(--bg1);padding:10px 18px;text-decoration:none}.controls{display:flex;gap:14px;flex-wrap:wrap;margin:20px 0 30px;padding:20px 0;border-top:1px solid var(--rule);border-bottom:1px solid var(--rule)}label{font-size:12px;letter-spacing:.04em;color:var(--mut);display:grid;gap:5px}select{max-width:270px;background:var(--bg1);border:1px solid var(--rule);padding:10px;color:var(--ink);font:15px system-ui;border-radius:0}select:focus-visible,a:focus-visible{outline:3px solid var(--act);outline-offset:4px}.comparison{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:28px}.shot{margin:0;background:var(--bg1);padding:18px}.shot img{width:100%;height:auto;display:block}.shot figcaption{font-size:13px;margin-top:15px;color:var(--mut)}.thesis{min-height:64px;color:var(--mut)}.absence{padding:50px 15px;color:var(--mut);border:1px solid var(--rule)}details{border-top:1px solid var(--rule);margin-top:40px;padding-top:24px}summary{cursor:pointer;font-size:24px;padding:8px 0}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:20px;margin-top:24px}.grid img{width:100%;height:auto}.note{border-left:4px solid var(--brand);padding:4px 20px;margin:30px 0}footer{font-size:13px;border-top:1px solid var(--rule);color:var(--mut)}@media(max-width:780px){header,main,footer{padding:20px}.comparison{grid-template-columns:1fr}.thesis{min-height:0}.shot{max-width:440px}.controls{position:static}}
</style>
<header><div class="eyebrow">Cup Season · local native study · September 24, 2026</div>
<h1>The competition, in view.<br>The whole season, in the Book.</h1>
<p>Three working SwiftUI directions, photographed in the simulator with fixture data. Compare the same season, screen, phone, printing and type size. Click any image for its full original PNG.</p>
<nav><a href="#compare">Compare directions</a><a href="#all">Browse by direction</a><a href="PROPOSAL.md">Read the proposal</a><a href="VERIFICATION.md">Verification</a><a href="manifest.json">Capture manifest</a></nav>
<p class="quiet">Recommendation: Scoreboard with the Book's weekly view; Race next; Broadsheet for dense comparison. The owner chooses. All prototypes are DEBUG-only and unpushed.</p></header>
<main><section id="compare"><h2>Same facts. Three compositions.</h2>
<div class="controls">
<label>FIXTURE<select id="fixture"><option value="field">16 golfers · 15 weeks</option><option value="tie">Two golfers · tied 41–41</option><option value="squads">Four squads · four golfers each</option><option value="upcoming">Upcoming · no standing</option><option value="finished">Finished · champion</option><option value="multi">Three seasons + a moment</option></select></label>
<label>SCREEN<select id="surface"><option value="root">Compete root</option><option value="season">Season standings head</option><option value="entry">Way into the Book</option><option value="book">The Book · weekly points</option><option value="totals">The Book · cumulative totals</option><option value="race">The Book · race</option><option value="week12">The Book · weeks 12–15</option><option value="contributions">The Book · squad contributions</option><option value="adjustments">The Book · adjustments</option><option value="receipt">Cell · included + dropped rounds</option><option value="round">Round receipt</option><option value="root-bottom">Three seasons · the moment below</option></select></label>
<label>PHONE<select id="phone"><option value="standard">iPhone 17 Pro</option><option value="small">iPhone SE (3rd generation)</option></select></label>
<label>PRINTING<select id="theme"><option value="dark">Dark</option><option value="light">Light</option></select></label>
<label>TYPE<select id="size"><option value="large">Default · Large</option><option value="ax3">Accessibility · AX3</option></select></label></div>
<div class="comparison" id="comparison"></div>
<div class="note"><strong>The Book contains points only.</strong><p>The matrix freezes names while weeks scroll. Every cell leads to its rounds and adjustments. At AX3, choose a week and read full-width rows. The race shows points counting today, not an invented historical standing.</p></div>
</section><section id="all"><h2>Browse by direction</h2><p class="quiet">These groups use the phone, printing and type controls above. Every image is a real simulator capture; no generated or composited screens.</p><div id="groups"></div></section></main>
<footer id="count"></footer>
<script>
const captures=CAPTURES;
const names={scoreboard:'01 · Scoreboard',race:'02 · Race',broadsheet:'03 · Broadsheet'};
const theses={scoreboard:'Your points take the display tier. The active season earns a full ember board.',race:'The season runs across time, with named lines over quiet livery terrain.',broadsheet:'Every season on one compact sports page, with the field printed underneath.'};
const controls=['fixture','surface','phone','theme','size'];
function value(id){return document.getElementById(id).value}
function title(id){let e=document.getElementById(id);return e.options[e.selectedIndex].text}
function shot(r){let fig=document.createElement('figure');fig.className='shot';let a=document.createElement('a');a.href=r.file;a.target='_blank';let img=document.createElement('img');img.src=r.file;img.loading='lazy';img.alt=names[r.direction]+', '+r.fixture+', '+r.surface+', '+r.phone+', '+r.size+', '+r.theme;a.append(img);let cap=document.createElement('figcaption');cap.textContent=r.fixture+' · '+r.surface+' · '+r.phone+' · '+r.size+' · '+r.theme;fig.append(a,cap);return fig}
function render(){let main=document.getElementById('comparison');main.replaceChildren();for(let d of Object.keys(names)){let div=document.createElement('article');let h=document.createElement('h3');h.textContent=names[d];let p=document.createElement('p');p.className='thesis';p.textContent=theses[d];div.append(h,p);let r=captures.find(r=>r.direction===d&&controls.every(k=>r[k]===value(k)));if(r)div.append(shot(r));else{let no=document.createElement('p');no.className='absence';no.textContent='No capture for this combination. Core screens cover every fixture; the extra Book studies focus on Scoreboard and Race. AX3 is on the standard phone.';div.append(no)}main.append(div)}let groups=document.getElementById('groups');groups.replaceChildren();for(let d of Object.keys(names)){let details=document.createElement('details'),summary=document.createElement('summary');let subset=captures.filter(r=>r.direction===d&&['phone','theme','size'].every(k=>r[k]===value(k)));summary.textContent=names[d]+' · '+subset.length+' captures';details.append(summary);details.addEventListener('toggle',()=>{if(details.open&&!details.querySelector('.grid')){let grid=document.createElement('div');grid.className='grid';subset.forEach(r=>grid.append(shot(r)));details.append(grid)}});groups.append(details)}document.getElementById('count').textContent=captures.length+' original PNGs · fixture-only · manifests record exact launch arguments, devices and image hashes. No production account, deployment, push or merge.'}
controls.forEach(id=>document.getElementById(id).addEventListener('change',()=>{if(value('phone')==='small')document.getElementById('size').value='large';render()}));render();
</script></html>'''
page=page.replace('TOKENS',css).replace('CAPTURES',json.dumps(rows).replace('</','<\\/'))
(out/'index.html').write_text(page)
for name in ['PROPOSAL.md','VERIFICATION.md']:
 p=root/'docs/design/compete-2026-09-24'/name
 if p.exists():(out/name).write_text(p.read_text().replace('../../planning/2026-09-24-codex-compete-explorations-prompt.md', 'BRIEF.md'))
(out/'BRIEF.md').write_text((root/'docs/planning/2026-09-24-codex-compete-explorations-prompt.md').read_text())
shutil.copytree(root/'docs/design/compete-2026-09-24/evidence', out/'evidence', dirs_exist_ok=True)
print(f'{len(rows)} images in {out}/index.html')
