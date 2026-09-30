/* MW-03 · a Compete row says my standing when the dispatch carries it, keeps
   its plain sentence when it does not, never invents a leader, and the empty
   archive stands down on the phone. Serve this checkout, open /?exit,
   evaluate with web-verify.mjs at 390, 320 and 1440. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const saved={ demo:state.demo, user:window.CS.user, mems:window.CS.memberships, rpc:window.sb&&window.sb.rpc, dispatch:window.homeDispatch,
                events:window.myEvents, sched:window.mySchedule, watch:window.watchAll, qa:window.qaEvent };
  const A='f0000000-0000-4000-8000-0000000000a1', B='f0000000-0000-4000-8000-0000000000a2', C='f0000000-0000-4000-8000-0000000000a3', D='f0000000-0000-4000-8000-0000000000a4';
  const out={ width: innerWidth };
  try{
    state.demo=false; window.CS.user={ id:'a0000000-0000-4000-8000-000000000099' }; window.qaEvent=()=>{};
    if(window.sb) window.sb.rpc=async(name)=>({ data:null, error:{ code:'AUDIT', message:'refused by the audit: '+name } });
    window.myEvents=[]; window.mySchedule=[]; window.watchAll=[];
    window.CS.memberships=[
      { id:'m1', role:'player',       league:{ id:A, name:'Fellas', phase:'season' } },
      { id:'m2', role:'commissioner', league:{ id:B, name:'Who’s the bitch?', phase:'season' } },
      { id:'m3', role:'player',       league:{ id:C, name:'No facts yet', phase:'season' } },
      { id:'m4', role:'player',       league:{ id:D, name:'Forming one', phase:'setup' } }];
    window.homeDispatch={ items:[], lead_suppress:[], me:{ memberships:[
      { league_id:A, name:'Fellas', standing:{ rank:2, points_rank:2, points_tied:false, of:2, points:14, gap_to_leader:3, leader_name:'Jade Park' }, season:{ week_no:8, weeks_total:26, days_left:127 }, clash:{ closes_today:true } },
      { league_id:B, name:'Who’s the bitch?', standing:{ rank:1, points_rank:1, points_tied:false, of:2, points:21, gap_to_leader:0, leader_name:'Audit', runner_up_name:'Casey Placeholder', runner_up_points:12 }, season:{ week_no:6, weeks_total:13, days_left:3 }, clash:{ closes_today:false } },
      /* a stale/error membership row: no standing at all — the row must not invent one */
      { league_id:C, name:'No facts yet', standing:null, season:null } ] } };
    document.querySelector('[data-v="compete"]').click();
    renderCompete();
    const row=id=>document.querySelector('#cmpList [data-peer="league:'+id+'"]');
    const text=(id,sel)=>row(id).querySelector(sel)?.textContent||'';
    /* F11 · the season being played leads as the BAND, and it keeps every
       fact the plain row carried: figure once, points and gap, week, status */
    const band=document.querySelector('#cmpList .cband');
    check(!!band,'F11: no band for the lead season');
    const btext=sel=>band.querySelector(sel)?.textContent||'';
    check(btext('.cband-fig')==='14points','the band lost the points figure: '+btext('.cband-fig'));
    check(btext('.cband-note')==='2ndYou are 3 back of Jade Park.','MW-03: the band said the rank twice or lost the line (W7-130: the table\'s own noun is "back of", D26/PAR-09): '+btext('.cband-note'));
    check(btext('.cband-meta')==='Week 8 of 26 · The clash closes today','MW-03: the band lost the week or the closing clash: '+btext('.cband-meta'));
    check(btext('.cband-state')==='Live','the band lost its state word');
    check(text(B,'.ps')==='1st of 2 · 21 pts · 9 clear of Casey · you run it','PAR-09: the leader’s line is wrong: '+text(B,'.ps'));
    check(text(B,'.pt')==='3 days left','MW-03: the last week is not the status: '+text(B,'.pt'));
    check(text(C,'.ps')==='You’re in it.' && text(C,'.pe')==='Season live' && !row(C).querySelector('.pt'),'MW-03: a row with no facts invented some: '+text(C,'.ps'));
    check(!/1st|clear of|leading/.test(text(C,'.ps')),'MW-03: a missing rank was rendered as first');
    check(text(D,'.pe')==='Forming' && text(D,'.ps')==='You’re in it.','a forming league borrowed season facts');
    check(document.querySelectorAll('#cmpList .peerrow').length===3 && document.querySelectorAll('#cmpList .cband').length===1,'the four seasons did not all render (band + three rows)');
    check(Array.from(document.querySelectorAll('#cmpList .peerrow')).every(b=>b.getBoundingClientRect().height>=44),'a row is under the tap target');

    /* the empty archive. W5 · the second column holds the moments and the
       finished shelf; holding neither, it stands down at EVERY width — on the
       desk it printed "Nothing finished yet." and nothing else in its 340
       (the owner and craft panels, desk D: "fill or remove the second
       column") — and the desk's main column takes the whole body */
    const aside=document.querySelector('#view-compete .deskaside');
    check(aside.hasAttribute('data-empty'),'the empty shelf was not marked empty');
    const shown=getComputedStyle(aside).display!=='none';
    check(!shown,'W5: an empty second column still shows');
    if(innerWidth>=960){
      const body=document.getElementById('cmpBody');
      check(body.hasAttribute('data-solo') && getComputedStyle(body).gridTemplateColumns.trim().split(/\s+/).length===1,'W5: the desk kept an empty column beside the list');
    }
    check(document.documentElement.scrollWidth<=innerWidth,'Compete overflows at this width');

    /* and with something finished, the shelf returns everywhere */
    window.CS.memberships.push({ id:'m5', role:'player', league:{ id:'f0000000-0000-4000-8000-0000000000a5', name:'Last year', phase:'complete' } });
    renderCompete();
    check(!aside.hasAttribute('data-empty') && getComputedStyle(aside).display!=='none','a finished season did not bring the shelf back');
    check(document.querySelectorAll('#cmpFinished .peerrow').length===1,'the finished season is not on the shelf');
    out.passed=true; return out;
  } finally {
    state.demo=saved.demo; window.CS.user=saved.user; window.CS.memberships=saved.mems; if(window.sb) window.sb.rpc=saved.rpc;
    window.homeDispatch=saved.dispatch; window.myEvents=saved.events; window.mySchedule=saved.sched; window.watchAll=saved.watch; window.qaEvent=saved.qa;
  }
})()
