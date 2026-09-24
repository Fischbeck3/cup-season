"""Build a disconnected browser harness around the real production functions."""
from pathlib import Path
import json,sys,shutil
root=Path(__file__).resolve().parents[3];html=(root/'index.html').read_text()
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
css=html[html.index('<style>')+7:html.index('</style>')]
# Bundle the same licensed faces the app already ships, keeping this harness offline.
(out/'fonts').mkdir(exist_ok=True)
for family,file,weight in [('IBM Plex Sans Condensed','IBMPlexSansCondensed-SemiBold.ttf',600),('IBM Plex Sans Condensed','IBMPlexSansCondensed-Bold.ttf',700),('IBM Plex Mono','IBMPlexMono-Regular.ttf',400),('IBM Plex Mono','IBMPlexMono-Medium.ttf',500),('IBM Plex Mono','IBMPlexMono-SemiBold.ttf',600)]:
 shutil.copyfile(root/'apps/ios/CupSeason/Resources/Fonts'/file,out/'fonts'/file)
 css+='\n@font-face{font-family:"'+family+'";src:url("fonts/'+file+'");font-weight:'+str(weight)+';}'

book=html[html.index('/* D381 · the Book.'):html.index('/* END D381 BOOK */')]
def lift(start):
 at=html.index(start);i=html.index('{',at);depth=0
 for end in range(i,len(html)):
  if html[end]=='{':depth+=1
  elif html[end]=='}':
   depth-=1
   if depth==0:return html[at:end+1]
band=lift('function csCompetitionBandHtml(')
topo=lift('window.csTopoHead = function(')
fixtures={n:json.loads((root/'tests/fixtures/season-book'/f'{n}.json').read_text()) for n in ['squads','tie','upcoming','finished']}
script='''const state={demo:false};window.CS={user:{id:'synthetic-reviewer'}};
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');
const climbOrd=n=>n+(['st','nd','rd'][n-1]||'th');let failure=false, current='squads';
window.sb={rpc:async()=>{if(failure){failure=false;document.getElementById('failure').checked=false;return {error:Error('offline')};}return {data:structuredClone(fixtures[current])};}};
window.csOpenPostedRound=id=>document.getElementById('roundResult').textContent='Opened fixture round '+id;
'''+book+'\n'+band+'\n'+topo+';\n'+'''
function showFixture(){const b=fixtures[current],rows=b.rows.filter(r=>r.kind===(b.structure==='solo'?'golfer':'squad')),r=rows.find(r=>r.mine);const row={id:'fixture',state:b.current_week===0?'Upcoming':b.status==='complete'?'Final':'Live',title:b.name,eyebrow:'Week '+b.current_week+' of '+b.weeks.length,points:b.current_week?r.points:null,standing:b.current_week?SeasonBook.standing(r):null,story:b.current_week?'The season is underway.':'First tee is ahead.'};document.getElementById('board').innerHTML=csCompetitionBandHtml(row);document.querySelectorAll('.sb-terrain').forEach(csTopoHead);document.getElementById('openBook').textContent=SeasonBook.prominent(b)?'Open the Book':'Rounds & points';}
document.getElementById('fixture').onchange=e=>{current=e.target.value;showFixture();};document.getElementById('printing').onchange=e=>document.documentElement.dataset.theme=e.target.value;
document.getElementById('openBook').onclick=()=>{const b=fixtures[current];csOpenSeasonBook(b.league_id,b.season_id);};document.getElementById('failure').onchange=e=>failure=e.target.checked;showFixture();
'''
page='<!doctype html><html lang="en" data-theme="dark"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Selected build · fixture review</title><style>'+css+'</style><body style="padding:24px;overflow:auto"><main style="max-width:1000px;margin:auto"><p>LOCAL FIXTURES · Selected production renderers · no account or network</p><label>Fixture <select id="fixture"><option>squads</option><option>tie</option><option>upcoming</option><option>finished</option></select></label> <label>Printing <select id="printing"><option>dark</option><option>light</option></select></label> <label><input id="failure" type="checkbox">Fail the next read</label><div id="board"></div><button id="openBook" class="sb-door">Open the Book</button><p id="roundResult"></p></main><script>const fixtures='+json.dumps(fixtures).replace('</','<\\/')+';\n'+script+'</script></body></html>'
(out/'web.html').write_text(page)
print(out/'web.html')
