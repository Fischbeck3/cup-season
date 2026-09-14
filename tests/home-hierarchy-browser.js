/* MW-02 · Home's hierarchy on the phone, and one fact one place on the wire.
   Serve this checkout, open /?exit, evaluate with web-verify.mjs at 390, 320
   and 1440. Fixture dispatch; destinations recorded, never followed; the RPC
   stub refuses every write. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const until=async(t,label)=>{ for(let i=0;i<100;i++){ if(t()) return; await new Promise(r=>setTimeout(r,20)); } throw new Error(label); };
  const saved={ demo:state.demo, user:window.CS.user, mems:window.CS.memberships, league:window.CS.league, rpc:window.sb&&window.sb.rpc,
                dispatch:window.homeDispatch, enter:window.enterLeagueById, qa:window.qaEvent, rows:window.homeFeedRows, spent:window.__spentRounds,
                career:window.career, profile:window.CS.profile, member:window.CS.member, stake:state.stake, phase:state.phase, buy:window.buyIns };
  const out={ width: innerWidth };
  const A='f0000000-0000-4000-8000-0000000000a1', B='f0000000-0000-4000-8000-0000000000a2';
  try{
    state.demo=false;
    window.CS.user={ id:'a0000000-0000-4000-8000-000000000099' };
    window.qaEvent=()=>{};
    window.homeFeedRows=undefined;
    if(window.sb) window.sb.rpc=async(name)=>({ data:null, error:{ code:'AUDIT', message:'refused by the audit: '+name } });
    window.CS.memberships=[
      { id:'m1', role:'player', league:{ id:A, name:'Fellas', phase:'season' } },
      { id:'m2', role:'player', league:{ id:B, name:'Who’s the bitch?', phase:'season' } }];
    window.CS.league={ id:A, name:'Fellas', phase:'season' };
    const item=(o)=>Object.assign({ tier:'chapter', human_subject:false, spine:'mut', suppress:[], at:null, standfirst:null }, o);
    window.homeDispatch={
      me:{ memberships:[ { league_id:A, name:'Fellas' }, { league_id:B, name:'Who’s the bitch?' } ] },
      lead_suppress:[],
      items:[
        item({ key:'clash:'+A+':8', tier:'closing', rank:1, at:isoAgo(0), human_subject:true, spine:'ember', league_id:A,
               eyebrow:'FELLAS · THE CLASH · CLOSES TODAY', headline:'Jade has today to answer your 84.', standfirst:'Your round is the number to beat.',
               action:'See the receipt', route:{ kind:'receipt', id:'r0000000-0000-4000-8000-000000000001' } }),
        item({ key:'story:r0000000-0000-4000-8000-000000000002', tier:'circle', rank:2, at:isoAgo(3), eyebrow:'AROUND YOUR BUDDIES',
               headline:'Galen posted 92 at Gold Canyon.', action:'See the round', route:{ kind:'receipt', id:'r0000000-0000-4000-8000-000000000002' } }),
        item({ key:'chapter:'+B, rank:3, league_id:B, eyebrow:'WHO’S THE BITCH? · WEEK 6 OF 13', headline:'You are the one to catch.', standfirst:'50 days still to play.', action:'Open the season', route:{ kind:'season', id:B } }),
        item({ key:'chapter:'+A, rank:4, league_id:A, eyebrow:'FELLAS · WEEK 8 OF 26', headline:'You are the one to catch.', standfirst:'127 days still to play.', action:'Open the season', route:{ kind:'season', id:A } }),
        /* the same sentence about the same league, minted twice — one item */
        item({ key:'chapter:'+A+':dup', rank:5, league_id:A, eyebrow:'FELLAS · WEEK 8 OF 26', headline:'You are the one to catch.', action:'Open the season', route:{ kind:'season', id:A } }),
      ] };
    renderHomeDispatch();
    const deck=document.getElementById('homeDeck');
    const rows=Array.from(deck.querySelectorAll('.cswire'));
    check(rows.length===3,'MW-02: the wire has '+rows.length+' rows, not 3 (the duplicate was kept or a fact was lost)');
    const byKey=k=>deck.querySelector('[data-dgo="'+k+'"]');
    check(!byKey('chapter:'+A+':dup'),'MW-02: the exact duplicate survived');
    check(byKey('chapter:'+A).querySelector('.lc')?.textContent==='Fellas','MW-02: the Fellas row does not name its league');
    check(byKey('chapter:'+B).querySelector('.lc')?.textContent==='Who’s the bitch?','MW-02: the other league’s row does not name its league');
    check(!byKey('story:r0000000-0000-4000-8800-000000000002')?.querySelector('.lc') && !deck.querySelector('[data-dgo^="story:"] .lc'),'MW-02: a story that is not shared got a league name');
    check(document.getElementById('homeLead').querySelector('.cs-lead')?.textContent==='Jade has today to answer your 84.','the lead is not the ranked lead');
    const texts=rows.map(r=>r.querySelector('.ln').textContent);
    check(new Set(texts).size===3,'MW-02: two wire rows still read identically: '+JSON.stringify(texts));

    /* the season door opens THAT league, not whichever is open */
    const entered=[]; window.enterLeagueById=async(id,nav)=>{ entered.push([id,nav]); };
    const views=[]; const realView=switchView; switchView=v=>{ views.push(v); };
    try{
      byKey('chapter:'+B).click();
      await until(()=>entered.length===1,'MW-02: the other league’s season door did not enter that league');
      check(entered[0][0]===B && entered[0][1]===false,'the season door entered the wrong league');
      check(!views.length,'the season door also switched view before entering');
      byKey('chapter:'+A).click();
      await until(()=>views.includes('hub'),'the open league’s season door did not open the hub');
      check(entered.length===1,'the open league was re-entered');
    } finally { switchView=realView; }

    /* the compact strip below the desk: number and last round, never the debt */
    window.CS.profile={ display_name:'Audit', index_current:11.4, index_source:'engine' };
    window.career={ rounds:12, recent:[{ id:'r0000000-0000-4000-8000-000000000001', gross:84, played_on:isoAgo(1) }] };
    window.CS.member={ id:'m1', role:'player' }; state.stake=75; state.phase='season'; window.buyIns={};
    renderMeStrip();
    const home=document.getElementById('homeMe'), side=document.getElementById('sideMe');
    const facts=el=>Array.from(el.querySelectorAll('.mefact')).map(b=>b.getAttribute('data-mego'));
    check(facts(side).includes('my_money'),'the sidebar strip lost the money it still owns');
    check(!facts(home).includes('my_money') && !facts(home).includes('my_next_round'),'MW-02: the narrow strip still leads with debt or the next round: '+facts(home).join(','));
    check(facts(home).includes('my_number'),'the narrow strip lost the number');
    out.narrowFacts=facts(home);

    /* the order on the phone, the grid on the desk */
    const top=id=>document.getElementById(id).getBoundingClientRect().top;
    const wire=document.querySelector('#homeHub .deskwire').getBoundingClientRect();
    const main=document.querySelector('#homeHub .deskmain');
    if(innerWidth<960){
      check(getComputedStyle(main).display==='contents','the narrow column did not dissolve the desk column');
      check(top('homeLead')<top('homeMe') && top('homeMe')<top('homeDeck'),'MW-02: the lead, strip and wire are out of order');
      check(top('homeDeck')<wire.top,'MW-02: recent golf sits above the wire');
      check(wire.top<top('homeTiles') && wire.top<top('homePulse'),'MW-02: the tiles or the pulse sit above recent golf');
      check(document.documentElement.scrollWidth<=innerWidth,'the narrow column overflows');
    } else {
      check(getComputedStyle(main).display!=='contents','the desk column dissolved on the desk');
      check(wire.left>main.getBoundingClientRect().left+200,'the desk lost its second column');
    }
    out.passed=true;
    return out;
  } finally {
    state.demo=saved.demo; window.CS.user=saved.user; window.CS.memberships=saved.mems; window.CS.league=saved.league;
    if(window.sb) window.sb.rpc=saved.rpc; window.homeDispatch=saved.dispatch; window.enterLeagueById=saved.enter;
    window.qaEvent=saved.qa; window.homeFeedRows=saved.rows; window.__spentRounds=saved.spent; window.career=saved.career;
    window.CS.profile=saved.profile; window.CS.member=saved.member; state.stake=saved.stake; state.phase=saved.phase; window.buyIns=saved.buy;
  }
})()
