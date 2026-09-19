/* Codex S1 · ONE start. Drives the REAL tee-off handler with a mocked RPC
   layer and asserts, per case, how many ordinary starts were made and what the
   client's round became. */
(function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const ME='00000000-0000-0000-0000-0000000000e1', PLAN='b0000000-0000-4000-8000-000000000001';
  const LR_NEW='c0000000-0000-4000-8000-0000000000aa', LR_OLD='c0000000-0000-4000-8000-0000000000bb';
  window.CS = Object.assign(window.CS||{}, { user:{ id:ME }, league:null, chan:null });
  state.demo=false;
  window.liveSync = { join(){ }, flush(){}, reconcile(){} };
  let announces=0; window.liveAnnounceOpen = ()=>{ announces++; };
  const calls = [];
  const row = { id:LR_OLD, league_id:null, game:'none', game_config:{}, join_code:'JOINME', starter_profile_id:'00000000-0000-0000-0000-000000000a1e', started_by:null,
    course_snapshot:{ label:'Bajamar', pars:PAR.slice(), holes:18 }, course_label:'Bajamar', started_at:new Date(Date.now()-3600e3).toISOString(),
    live_round_players:[ { id:'p1', position:1, guest_name:'Galen', guest_profile_id:'00000000-0000-0000-0000-000000000a1e' },
                         { id:'p2', position:2, guest_name:'Jerecho', guest_profile_id:ME } ] };
  let mode='plan';
  window.sb = {
    rpc: async (name, args)=>{
      calls.push(name);
      if(name==='start_live_round_from_plan'){
        if(mode==='plan')  return { data:{ live_round_id:LR_NEW, join_code:'NEW', joined:false, players:[{id:'q1',position:1,guest_name:'Jerecho'}] }, error:null };
        if(mode==='join')  return { data:{ live_round_id:LR_OLD, join_code:'JOINME', joined:true }, error:null };
        if(mode==='skew')  return { data:null, error:{ message:'Could not find the function public.start_live_round_from_plan in the schema cache' } };
        if(mode==='denied')return { data:null, error:{ message:'Only the host and the tagged golfers can tee this booking up' } };
      }
      if(name==='start_live_round') return { data:{ live_round_id:'c0000000-0000-4000-8000-0000000000cc', join_code:'PLAIN', players:[] }, error:null };
      if(name==='my_friends' || name==='search_golfers') return { data:[], error:null };
      return { data:null, error:null };
    },
    from: ()=>({ select: ()=>({ eq: ()=>({ maybeSingle: async ()=>({ data:row, error:null }) }) }) }),
  };
  async function drive(m){
    mode=m; calls.length=0; announces=0;
    ROSTER.length=0; ROSTER.push({ n:'Jerecho', i:8.4, ci:1, guest:true, me:true, locked:true, pid:ME }); sel.length=0; sel.push(0); LIVE.length=0; LIVE.push(ROSTER[0]);
    state.live={ stage:'setup', active:false, game:'score', planId:PLAN, pairing:0, mode:'teams', rating9:false };
    const b=document.getElementById('teeOffBtn'); check(!!b,'the tee-off button exists');
    b.click();
    await new Promise(r=>setTimeout(r, 400));
    return { plan:calls.filter(c=>c==='start_live_round_from_plan').length, plain:calls.filter(c=>c==='start_live_round').length, lr:state.live && state.live.lr, active:!!(state.live&&state.live.active), announces };
  }
  return (async()=>{
    const out={};
    out.plan = await drive('plan');
    check(out.plan.plan===1 && out.plan.plain===0, 'a plan start makes ZERO ordinary starts: '+JSON.stringify(out.plan));
    check(out.plan.lr===LR_NEW && out.plan.active, 'the plan start\'s round IS the client\'s round');
    out.join = await drive('join');
    check(out.join.plan===1 && out.join.plain===0, 'a JOIN makes ZERO ordinary starts: '+JSON.stringify(out.join));
    check(out.join.lr===LR_OLD && out.join.active, 'a JOIN hydrates the standing round, not a new one');
    check(state.live.code==='JOINME' && state.live.mine===false, 'the joined round keeps its code and I am not its starter');
    check(Array.isArray(state.live.pmap) && state.live.pmap.join(',')==='p1,p2', 'the joined round keeps the server\'s seat ids');
    check(out.join.announces===0, 'a JOIN announces no start');
    out.skew = await drive('skew');
    check(out.skew.plan===1 && out.skew.plain===1, 'a missing function on an older server falls through to ONE ordinary start (deliberate)');
    out.denied = await drive('denied');
    check(out.denied.plan===1 && out.denied.plain===0, 'a refusal never starts an unrelated round');
    check(!out.denied.active && !out.denied.lr, 'and the client is back in setup with no round');
    out.passed=true; return JSON.stringify(out);
  })();
})()
