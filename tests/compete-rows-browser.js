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
      { league_id:A, name:'Fellas', standing:{ rank:2, of:2, points:14, gap_to_leader:3, leader_name:'Jade Park' }, season:{ week_no:8, weeks_total:26, days_left:127 }, clash:{ closes_today:true } },
      { league_id:B, name:'Who’s the bitch?', standing:{ rank:1, of:2, points:21, gap_to_leader:0, leader_name:'Audit' }, season:{ week_no:6, weeks_total:13, days_left:3 }, clash:{ closes_today:false } },
      /* a stale/error membership row: no standing at all — the row must not invent one */
      { league_id:C, name:'No facts yet', standing:null, season:null } ] } };
    document.querySelector('[data-v="compete"]').click();
    renderCompete();
    const row=id=>document.querySelector('#cmpList [data-peer="league:'+id+'"]');
    const text=(id,sel)=>row(id).querySelector(sel)?.textContent||'';
    check(text(A,'.ps')==='2nd of 2 · 14 pts · 3 behind Jade','MW-03: the standing line is wrong: '+text(A,'.ps'));
    check(text(A,'.pe')==='In season · Week 8 of 26','MW-03: the week is wrong: '+text(A,'.pe'));
    check(text(A,'.pt')==='The clash closes today','MW-03: the closing clash is not the status: '+text(A,'.pt'));
    check(text(B,'.ps')==='1st of 2 · 21 pts · leading · you run it','MW-03: the leader’s line is wrong: '+text(B,'.ps'));
    check(text(B,'.pt')==='3 days left','MW-03: the last week is not the status: '+text(B,'.pt'));
    check(text(C,'.ps')==='You’re in it.' && text(C,'.pe')==='In season' && !row(C).querySelector('.pt'),'MW-03: a row with no facts invented some: '+text(C,'.ps'));
    check(!/1st|leading/.test(text(C,'.ps')),'MW-03: a missing rank was rendered as first');
    check(text(D,'.pe')==='Forming' && text(D,'.ps')==='You’re in it.','a forming league borrowed season facts');
    check(document.querySelectorAll('#cmpList .peerrow').length===4,'the four seasons did not all render');
    check(Array.from(document.querySelectorAll('#cmpList .peerrow')).every(b=>b.getBoundingClientRect().height>=44),'a row is under the tap target');

    /* the empty archive: chrome on the phone, a column on the desk */
    const aside=document.querySelector('#view-compete .deskaside');
    check(aside.hasAttribute('data-empty'),'the empty shelf was not marked empty');
    const shown=getComputedStyle(aside).display!=='none';
    if(innerWidth<960) check(!shown,'MW-03: the empty Finished shelf still shows on the phone');
    else check(shown,'the desk lost its Finished column');
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
