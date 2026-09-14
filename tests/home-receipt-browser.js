/* WA1 · Home's shortcuts open the POSTED receipt, not the scheduled-round
   sheet. Serve this checkout, open /?exit, evaluate with web-verify.mjs.
   Every RPC is stubbed and recorded; nothing is written. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const until=async(t,label)=>{ for(let i=0;i<120;i++){ if(t()) return; await new Promise(r=>setTimeout(r,20)); } throw new Error(label); };
  const saved={ demo:state.demo, user:window.CS.user, mems:window.CS.memberships, league:window.CS.league,
                rpc:window.sb&&window.sb.rpc, cache:window.roundCache, dispatch:window.homeDispatch, qa:window.qaEvent,
                rows:window.homeFeedRows, career:window.career, profile:window.CS.profile, member:window.CS.member, toast:toast };
  const A='f0000000-0000-4000-8000-0000000000a1';
  const POSTED='40000000-0000-4000-8000-000000000001';   /* uncached on purpose */
  const CACHED='40000000-0000-4000-8000-000000000002';
  const GONE  ='40000000-0000-4000-8000-000000000009';
  const PLAN  ='50000000-0000-4000-8000-000000000001';
  const calls=[], toasts=[];
  const sheet=()=>document.getElementById('sheet');
  const open=()=>sheet().classList.contains('open');
  const card=id=>({ id, gross:84, rating:71.2, slope:128, differential:11.4, index_at_post:11.4, playing_index:11.4,
                    points:7, month_rank:1, counting_cap:2, band:'Played to it', pvi:0.2, holes_played:18,
                    course_label:'Papago', played_on:isoAgo(1), is_mine:true });
  const out={};
  try{
    state.demo=false; window.CS.user={ id:'a0000000-0000-4000-8000-000000000099' }; window.qaEvent=()=>{};
    window.homeFeedRows=undefined; window.roundCache={ [CACHED]: card(CACHED) };
    toast=m=>{ toasts.push(String(m)); };
    window.CS.memberships=[{ id:'m1', role:'player', league:{ id:A, name:'Fellas', phase:'season' } }];
    window.CS.league={ id:A, name:'Fellas', phase:'season' };
    window.sb.rpc=async(name,args)=>{
      calls.push([name,args]);
      if(name==='round_card') return args.p_round===GONE ? { data:null, error:{ message:'round not found' } } : { data:card(args.p_round), error:null };
      if(name==='round_detail') return { data:null, error:{ code:'400', message:'round_detail is the SCHEDULED read' } };
      return { data:null, error:{ code:'AUDIT', message:'refused by the audit: '+name } };
    };

    /* ── the lead's "See the receipt", on a round this page has never listed ── */
    window.homeDispatch={ me:{ memberships:[{ league_id:A, name:'Fellas' }] }, lead_suppress:[], items:[
      { key:'clash:'+A+':8', tier:'closing', rank:1, at:isoAgo(0), human_subject:true, spine:'ember', league_id:A,
        eyebrow:'FELLAS · THE CLASH', headline:'Jade has today to answer your 84.', standfirst:'Your round is the number to beat.',
        action:'See the receipt', route:{ kind:'receipt', id:POSTED }, suppress:[] } ] };
    renderHomeDispatch();
    document.querySelector('#homeLead [data-dgo]').click();
    await until(()=>document.getElementById('rcptBody'),'WA1: the lead’s receipt never opened');
    check(open(),'WA1: the receipt sheet is not open');
    check(!calls.some(c=>c[0]==='round_detail'),'WA1: the lead still read round_detail, the SCHEDULED round');
    check(calls.some(c=>c[0]==='round_card' && c[1].p_round===POSTED),'WA1: the lead did not read the posted round’s card');
    const body=()=>document.getElementById('rcptBody').textContent;
    check(/71\.2 \/ 128/.test(body()),'WA1: the receipt has no course facts');
    const row=label=>Array.from(document.querySelectorAll('#rcptBody .mathrow'))
      .map(r=>[r.querySelector('span')?.textContent||'', r.querySelector('b')?.textContent||''])
      .find(([k])=>k.trim()===label);
    check((row('Points')||[])[1]==='7','WA1: the receipt does not carry the server’s points');
    check(/COUNTING #1/.test((row('This month')||[])[1]||''),'WA1: the receipt lost the league’s counting lens');
    check(!toasts.length,'WA1: a working receipt complained: '+toasts.join(' | '));
    out.uncached=true;
    closeSheet(); await until(()=>!open(),'the sheet did not close');

    /* ── the compact strip's last score, on a round the page DOES hold ── */
    calls.length=0;
    window.CS.profile={ display_name:'Audit', index_current:11.4, index_source:'engine' };
    window.career={ rounds:12, recent:[{ id:CACHED, gross:84, played_on:isoAgo(1) }] };
    window.CS.member={ id:'m1', role:'player' };
    renderMeStrip();
    const last=document.querySelector('#homeMe [data-mego="my_last_round"]') || document.querySelector('#sideMe [data-mego="my_last_round"]');
    check(!!last && last.getAttribute('data-meid')===CACHED,'the last-score control does not carry its round');
    last.click();
    await until(()=>document.getElementById('rcptBody'),'WA1: the last score never opened its receipt');
    check(!calls.some(c=>c[0]==='round_detail'),'WA1: the last score still read round_detail');
    check(/71\.2 \/ 128/.test(body()),'WA1: the cached receipt has no course facts');
    out.cached=true;
    closeSheet(); await until(()=>!open(),'the sheet did not close after the cached receipt');

    /* ── a round that cannot be read says so, and leaves no empty sheet ── */
    calls.length=0; toasts.length=0;
    await window.csOpenPostedRound(GONE);
    check(!open(),'WA1: an unreadable round left a sheet open');
    check(toasts.length===1,'WA1: an unreadable round said nothing');
    check(!document.getElementById('rcptBody'),'WA1: an unreadable round drew a receipt anyway');
    out.error=toasts[0];

    /* ── a SCHEDULED round still opens the scheduled round ── */
    calls.length=0;
    window.mySchedule=[{ id:PLAN, mine:true, play_on:isoAgo(-2), course_label:'Papago', profile_id:window.CS.user.id }];
    const views=[]; const realView=switchView; switchView=v=>{ views.push(v); };
    try{
      const door=csItemDoor({ key:'plan:'+PLAN, route:{ kind:'plan', id:PLAN }, headline:'x' });
      check(!!door,'the scheduled-round door is gone'); door();
      check(views.includes('schedule'),'WA1: the scheduled-round door stopped opening the schedule');
    } finally { switchView=realView; }
    await window.openRoundSheet(PLAN);
    await until(()=>document.getElementById('sheet').classList.contains('open'),'the scheduled sheet did not open');
    check(calls.some(c=>c[0]==='round_detail' && c[1].p_round===PLAN),'WA1: the scheduled sheet stopped reading round_detail');
    closeSheet();
    /* ── WA6 · the verdict says one thing once, in the right voice ────────── */
    const V=(pvi,mine)=>window.csReceiptVerdict(bandName(pvi), vsPhrase(pvi), mine);
    check(V(0.2,true)==='Played to your playing HCP.','WA6: the verdict still stutters: '+V(0.2,true));
    check(V(2.4,true)==='Beat your playing HCP by 2.4.','WA6: the beat verdict still stutters: '+V(2.4,true));
    check(V(4.1,true)==='Beat your playing HCP by 4.1 \u2014 torched it.','WA6: a band that ADDS something was dropped: '+V(4.1,true));
    check(V(-2.4,true)==='2.4 over your playing HCP \u2014 a little loose.','WA6: the loose verdict changed: '+V(-2.4,true));
    check(V(0.2,false)==='Played to their playing HCP.','WA6: somebody else’s round is still announced as yours: '+V(0.2,false));
    check(V(4.1,false)==='Beat their playing HCP by 4.1 \u2014 torched it.','WA6: the third person did not reach the phrase: '+V(4.1,false));
    out.verdict=V(0.2,true);

    /* ── WA6 · the arithmetic is grouped the way it is computed ───────────── */
    await window.csOpenPostedRound(CACHED);
    await until(()=>document.getElementById('rcptBody'),'the receipt did not reopen for the arithmetic');
    const math=Array.from(document.querySelectorAll('#rcptBody .mathrow span')).map(e=>e.textContent);
    const expr=math.find(t=>/113/.test(t));
    check(!!expr,'WA6: the differential line is gone');
    check(/^\(\s*84\s*\u2212\s*71\.2\s*\)/.test(expr.replace(/−/g,'\u2212')),'WA6: the expression is still ungrouped: '+expr);
    out.expression=expr;
    closeSheet(); await until(()=>!open(),'the sheet did not close after the arithmetic');

    /* ── WA4 · a standings history row opens the round behind it (§16) ────── */
    calls.length=0;
    window.CS.member={ id:'mem-1', role:'player' };
    openMemberHist({ n:'Audit', mid:'mem-1', me:true, r:2, pts:16,
      hist:[ { round_id:POSTED, played_on:isoAgo(1), pvi:0.2, points:7, counting:true, holes_played:18 },
             { round_id:CACHED, played_on:isoAgo(8), pvi:-2.4, points:6, counting:false, holes_played:18 },
             { round_id:null,   played_on:isoAgo(20), pvi:1.1, points:9, counting:true, holes_played:18 } ] });
    await until(()=>document.querySelectorAll('#shBody [data-histround]').length===2,'WA4: the history rows are not doors');
    const doors=Array.from(document.querySelectorAll('#shBody [data-histround]'));
    check(doors.every(d=>d.getBoundingClientRect().height>=44-1),'WA4: a history door is under the tap target');
    check(document.querySelectorAll('#shBody .histrow.static').length===1,'WA4: a row with no round became a door anyway');
    check(/BUMPED/.test(doors[1].textContent),'WA4: the bumped row lost its explanation');
    doors[1].click();                                   /* the BUMPED round, and it is cached */
    await until(()=>document.getElementById('rcptBody'),'WA4: a history row did not open its receipt');
    check(/71\.2 \/ 128/.test(document.getElementById('rcptBody').textContent),'WA4: the receipt opened without its facts');
    closeSheet(); await until(()=>!open(),'the sheet did not close after the history receipt');
    /* and an UNCACHED history round resolves itself rather than opening nothing */
    calls.length=0;
    openMemberHist({ n:'Audit', mid:'mem-1', me:true, r:1, pts:7,
      hist:[ { round_id:'40000000-0000-4000-8000-00000000000c', played_on:isoAgo(3), pvi:0.2, points:7, counting:true, holes_played:18 } ] });
    await until(()=>document.querySelector('#shBody [data-histround]'),'the single history row did not render');
    document.querySelector('#shBody [data-histround]').click();
    await until(()=>document.getElementById('rcptBody'),'WA4: an uncached history round opened nothing');
    check(calls.some(c=>c[0]==='round_card'),'WA4: the uncached history round never read its card');
    check(!calls.some(c=>c[0]==='round_detail'),'WA4: a history row read the SCHEDULED round');
    out.history=true;
    closeSheet();

    out.passed=true; return out;
  } finally {
    state.demo=saved.demo; window.CS.user=saved.user; window.CS.memberships=saved.mems; window.CS.league=saved.league;
    if(window.sb) window.sb.rpc=saved.rpc; window.roundCache=saved.cache; window.homeDispatch=saved.dispatch;
    window.qaEvent=saved.qa; window.homeFeedRows=saved.rows; window.career=saved.career;
    window.CS.profile=saved.profile; window.CS.member=saved.member; toast=saved.toast;
    if(document.getElementById('sheet').classList.contains('open')) closeSheet();
  }
})()
