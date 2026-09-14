/* MW-02 · Home's hierarchy on the phone, and one fact one place on the wire.
   Serve this checkout, open /?exit, evaluate with web-verify.mjs at 390, 320
   and 1440. Fixture dispatch; destinations recorded, never followed; the RPC
   stub refuses every write. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const until=async(t,label)=>{ for(let i=0;i<100;i++){ if(t()) return; await new Promise(r=>setTimeout(r,20)); } throw new Error(label); };
  const saved={ demo:state.demo, user:window.CS.user, mems:window.CS.memberships, league:window.CS.league, rpc:window.sb&&window.sb.rpc,
                dispatch:window.homeDispatch, enter:window.enterLeagueById, qa:window.qaEvent, rows:window.homeFeedRows, spent:window.__spentRounds,
                career:window.career, profile:window.CS.profile, member:window.CS.member, stake:state.stake, phase:state.phase, buy:window.buyIns,
                sched:window.mySchedule, watch:window.watchAll, posts:window.homePosts };
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

    /* WA2 · the season door ARRIVES at the season it names. The previous
       assertion here required no view change after the other-league click,
       which is the defect written down as an expectation: it confirmed a call
       and never asked whether the golfer got anywhere. The loader stub now
       does what a real load does — it changes the context — so the walk can
       assert the active league AND the active view. */
    const entered=[]; const views=[]; const toasts=[];
    const realView=switchView, realToast=toast;
    let loader=async(id)=>{ entered.push(id); window.CS.league={ id, name:'Loaded', phase:'season' }; };
    window.enterLeagueById=(id,nav)=>{ check(nav===false,'the season door let enterLeague navigate for itself'); return loader(id); };
    switchView=v=>{ views.push(v); };
    toast=m=>{ toasts.push(String(m)); };
    try{
      /* the OTHER league: one click, and both the context and the room move */
      byKey('chapter:'+B).click();
      await until(()=>views.includes('hub'),'WA2: the other league’s season door never opened the season');
      check(entered.length===1 && entered[0]===B,'the season door entered the wrong league');
      check(window.CS.league.id===B,'the season door opened the hub without changing league');
      check(!toasts.length,'a successful arrival complained');

      /* the CURRENT league: still one click, and no reload */
      views.length=0; entered.length=0;
      window.CS.league={ id:A, name:'Fellas', phase:'season' };
      renderHomeDispatch();
      byKey('chapter:'+A).click();
      await until(()=>views.includes('hub'),'the open league’s season door did not open the hub');
      check(entered.length===0,'the open league was re-entered');

      /* a FAILED load must not navigate: the wrong league’s table under
         another league’s name is worse than staying put */
      views.length=0; entered.length=0; toasts.length=0;
      loader=async(id)=>{ entered.push(id); /* context never changes */ };
      byKey('chapter:'+B).click();
      await until(()=>toasts.length===1,'WA2: a failed load said nothing');
      check(!views.length,'WA2: a failed load navigated anyway');
      check(window.CS.league.id===A,'a failed load changed the league');

      /* a league that is NOT a membership: no load attempt, an honest line */
      views.length=0; entered.length=0; toasts.length=0;
      const gone=window.CS.memberships; window.CS.memberships=[gone[0]];
      byKey('chapter:'+B).click();
      await until(()=>toasts.length===1,'WA2: an absent membership said nothing');
      check(!entered.length,'WA2: an absent membership still tried to load');
      check(!views.length,'WA2: an absent membership navigated anyway');
      window.CS.memberships=gone;

      /* a THROWN load is a failure too, not an exception on the page */
      views.length=0; toasts.length=0;
      loader=async()=>{ throw new Error('network'); };
      byKey('chapter:'+B).click();
      await until(()=>toasts.length===1,'WA2: a thrown load said nothing');
      check(!views.length,'WA2: a thrown load navigated anyway');
    } finally { switchView=realView; toast=realToast; }

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
    /* ── F1 · A SCHEDULED ROUND LANDS EXACTLY ONCE, AT EVERY WIDTH ─────────
       The compact strip drops `my_next_round`, but suppression was copied
       from the full desktop strip — so the hidden sidebar owned the fact and
       the chip and the tile both stood down: on a phone the golfer's next
       round appeared NOWHERE. This counts the fact after the whole Home
       render, which is the only way to see either failure (missing, or twice). */
    const iso=n=>{ const d=new Date(); d.setDate(d.getDate()+n); return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0'); };
    window.mySchedule=[{ id:'50000000-0000-4000-8000-000000000001', mine:true, play_on:iso(2),
                         course_label:'Papago', tee_time:'08:10', profile_id:window.CS.user.id }];
    window.watchAll=[]; window.homeDispatch.items=[]; window.homePosts=[];
    const wholeHomeRender=()=>{ renderMeStrip(); renderHomeDispatch(); renderUpNext(); renderHomeTiles(); };
    const visible=el=>{ if(!el) return false; const r=el.getBoundingClientRect(); return !!(r.width && r.height); };
    const nextPlaces=()=>{
      const places=[];
      document.querySelectorAll('[data-mego="my_next_round"]').forEach(el=>{ if(visible(el)) places.push('strip:'+(el.closest('#homeMe')?'phone':'desk')); });
      document.querySelectorAll('#homeUpNext .upchip').forEach(el=>{ if(visible(el) && /next round/i.test(el.textContent)) places.push('chip'); });
      document.querySelectorAll('#homeTiles .htile').forEach(el=>{ if(visible(el) && /^Next/.test(el.textContent)) places.push('tile'); });
      return places;
    };
    wholeHomeRender();
    const places=nextPlaces();
    check(places.length===1,'F1: the scheduled round is on Home '+places.length+' time(s) at '+innerWidth+': '+JSON.stringify(places));
    out.nextRoundOwnedBy=places[0];
    if(innerWidth<960) check(places[0]==='chip','F1: the phone’s next round is not carried by the Up next chip: '+places[0]);
    else check(places[0]==='strip:desk','F1: the desk stopped carrying the next round in its strip: '+places[0]);
    /* and the round's own facts are on the screen, not merely a slot that
       claims the fact: the chip names the course, the desk strip the tee */
    /* the desk's strip lives in the SIDEBAR, outside #homeHub — read the
       element that claimed the fact rather than one container */
    const claimed=document.querySelector(places[0]==='chip'
      ? '#homeUpNext .upchip' : '[data-mego="my_next_round"]');
    const said=(claimed&&claimed.textContent)||'';
    if(places[0]==='chip') check(/papago/i.test(said),'F1: the chip claimed the round without naming its course: '+said);
    else check(/8:10/.test(said) || /papago/i.test(said),'F1: the desk strip claimed the round without naming its tee or course: '+said);
    /* with no plan at all the tile keeps its door, and nothing claims a fact */
    window.mySchedule=[];
    wholeHomeRender();
    check(!nextPlaces().some(x=>x==='chip'),'F1: a chip printed a round that does not exist');

    out.passed=true;
    return out;
  } finally {
    state.demo=saved.demo; window.CS.user=saved.user; window.CS.memberships=saved.mems; window.CS.league=saved.league;
    if(window.sb) window.sb.rpc=saved.rpc; window.homeDispatch=saved.dispatch; window.enterLeagueById=saved.enter;
    window.qaEvent=saved.qa; window.homeFeedRows=saved.rows; window.__spentRounds=saved.spent; window.career=saved.career;
    window.CS.profile=saved.profile; window.CS.member=saved.member; state.stake=saved.stake; state.phase=saved.phase; window.buyIns=saved.buy;
    window.mySchedule=saved.sched; window.watchAll=saved.watch; window.homePosts=saved.posts;
  }
})()
