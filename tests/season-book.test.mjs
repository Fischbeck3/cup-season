import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const html=readFileSync(new URL('../index.html',import.meta.url),'utf8');
const source=html.slice(html.indexOf('/* D381 · the Book.'),html.indexOf('/* END D381 BOOK */'));
const ctx={window:{},esc:s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;'),climbOrd:n=>n+(['st','nd','rd'][n-1]||'th')};vm.createContext(ctx);vm.runInContext(source,ctx);
const B=ctx.window.SeasonBook,read=n=>JSON.parse(readFileSync(new URL('./fixtures/season-book/'+n+'.json',import.meta.url)));
let count=0;function test(name,body){body();count++;console.log('PASS '+name);}
test('actual RPC fixtures reconcile in both clients',()=>{for(const n of ['squads','tie','upcoming','finished']){const b=read(n);B.validate(b,b.league_id,b.season_id);}});
test('wrong season, stale version and truncated cells fail visibly',()=>{for(const change of [b=>b.version=2,b=>b.coverage_complete=false,b=>b.rows[0].points++,b=>b.rows[0].cells.pop(),b=>b.rows[0].kind='pot']){const b=read('squads');change(b);assert.throws(()=>B.validate(b,b.league_id,b.season_id));}const b=read('tie');assert.throws(()=>B.validate(b,b.league_id,'other'));});
test('small tied field stays equal and uses Rounds & points',()=>{const b=read('tie');assert.equal(B.prominent(b),false);assert(b.rows.every(r=>B.standing(r)==='1st · Tied'));const h=ctx.csSeasonBookBody(b,{group:'golfer',squad:'all',mode:'Weeks'});assert(!h.includes('sb-matrix'));assert(h.includes('41 pts'));});
test('multiple receipts and dropped rounds are retained',()=>{const b=read('squads'),r=b.rows.find(r=>r.kind==='golfer'&&r.mine),es=B.entries(r,12);assert.equal(es.filter(e=>e.round_id).length,2);assert(B.label(r,r.cells[11]).includes('D'));assert.equal(B.label(r,r.cells[14]),'•');});
test('contribution filter keeps the selected squad adjustments',()=>{const b=read('squads'),s=b.rows.find(r=>r.kind==='squad'&&r.name==='Saguaros'),h=ctx.csSeasonBookBody(b,{group:'golfer',squad:s.squad_id,mode:'Weeks'});assert(h.includes('August minimum: one round short'));assert(!h.includes('Late recorded squad correction'));});
test('outside-week points do not become a fabricated race',()=>{const b=read('squads'),r=b.rows.find(r=>r.unplaced_points===2);assert(ctx.csSeasonBookRace(b,[r],r.id).includes('outside the season weeks'));assert(!ctx.csSeasonBookRace(b,[r],r.id).includes('<svg'));});
test('negative running totals and earlier peaks fit the race',()=>assert.equal(JSON.stringify(B.domain([{cells:[{cumulative:12},{cumulative:-8},{cumulative:2}]}])),'[-8,12]'));
test('names and reasons are escaped, and the Book contains no pot fields',()=>{const b=read('squads');b.rows[0].name='<img src=x>';b.rows[0].entries[0].reason='<script>alert(1)</script>';const h=ctx.csSeasonBookReceipt(b.rows[0].name,b.rows[0].entries);assert(!h.includes('<script>'));assert(!h.includes('<img'));assert(h.includes('&lt;script>'));const rendered=ctx.csSeasonBookBody(b,{group:'squad',squad:'all',mode:'Weeks'});assert(!/ledger|buy.?in|payout|\$\d/i.test(rendered));});
console.log(count+' Book checks passed');
