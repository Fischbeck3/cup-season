/* R1–R6 repair pass · the review's reproductions, as assertions of CORRECT
   behaviour. Network is disabled before any fictional signed-in state is set,
   exactly as the inspection probe does; every golfer here is invented. */
(async function(){
  const check=(ok,label)=>{if(!ok)throw new Error(label)};
  const until=async(t,l)=>{for(let i=0;i<150;i++){if(t())return;await new Promise(r=>setTimeout(r,20));}throw new Error(l);};
  const realFetch=window.fetch, realSb=window.sb, realCS=window.CS, realDemo=state.demo;
  const realToast=toast, realSwitch=switchView, realFinish=finishCeremony, realQa=window.qaEvent;
  const realPost=JSON.parse(JSON.stringify(state.post));
  const uid='f0000000-0000-4000-8000-000000000001';
  const PLAN='f0000000-0000-4000-8000-000000000002';
  const ctx={plan_id:PLAN, play_on:isoAgo(1), course_label:'Papago', course_id:null, tee_time:null};
  const msgs=[];
  try{
    window.fetch=async()=>{throw new Error('repair suite: network disabled')};
    window.CS={user:{id:uid},profile:{display_name:'Review golfer',marker:'azalea'},
      league:{id:'l1',name:'Current league'},member:{id:'member'},
      squads:[{id:'s1',name:'Current squad',squad_members:[{member_id:'member'}]}],memberships:[]};
    toast=m=>msgs.push(String(m));
    switchView=()=>{};
    window.qaEvent=()=>{};
    state.demo=false;
    clearPostRequest(uid); clearPostDraft(); closeSheet();
    /* `closeSheet` leaves the markup in place, so the question is "is the sheet
       OPEN", never "does the button exist". */
    const asking=()=>{const sh=document.getElementById('sheet');
      return !!(sh && sh.classList.contains('open') && document.getElementById('planTake'));};
    const reset=()=>{
      POST_FIELDS.forEach(id=>{const e=document.getElementById(id); if(e) e.value='';});
      stampPostDate();
      state.post={mode:'total',side:18,touched:false,rating9:false,parsCourse:null,
        pars:POST_PAR_STD.slice(),scores:POST_PAR_STD.slice(),playedWith:[],plan:null};
      _draftRestored=false;
    };

    /* ── R2a · a gross-only card is WORK, and is not changed without a tap ── */
    reset(); document.getElementById('inGross').value='84';
    check(postDraftHasContent(csPostVals(), false),'R2: a gross-only card still reads as empty');
    csPlanToComposer(ctx);
    await until(asking,'R2: a gross-only card was changed with no question');
    check(document.getElementById('inDate').value===_postDateStamp,'R2: the date moved before the golfer answered');
    check(document.getElementById('inGross').value==='84','R2: the gross was disturbed by the question');
    document.getElementById('planKeep').click();
    check(document.getElementById('inDate').value===_postDateStamp && document.getElementById('inGross').value==='84',
          'R2: keeping the started round changed it');

    /* ── R2b · the whole card survives save and a full relaunch ──────────── */
    document.getElementById('planKeep') && closeSheet();
    csPlanToComposer(ctx);
    await until(asking,'R2: the question did not return');
    document.getElementById('planTake').click();
    check(document.getElementById('inDate').value===ctx.play_on,'R2: agreeing did not take the plan day');
    check(state.post.plan && state.post.plan.id===PLAN,'R2: the plan identity was not kept');
    savePostDraft(); await new Promise(r=>setTimeout(r,450));
    const saved=JSON.parse(localStorage.getItem(postDraftKey(uid))||'null');
    check(saved && saved.vals.inGross==='84','R2: the gross was not saved');
    check(saved.vals.inDate===ctx.play_on,'R2: the plan day was not saved');
    check(saved.plan && saved.plan.id===PLAN,'R2: the plan context was not saved');
    check(saved.owner===uid,'R2: the draft is not owner-scoped');
    reset();
    check(restorePostDraft(),'R2: nothing was restored');
    check(document.getElementById('inGross').value==='84','R2: the gross did not come back');
    check(document.getElementById('inDate').value===ctx.play_on,'R2: the day did not come back');
    check(state.post.plan && state.post.plan.id===PLAN,'R2: the plan context did not survive the relaunch');
    /* the same plan again is a resume, not a question */
    closeSheet(); csPlanToComposer(ctx);
    await new Promise(r=>setTimeout(r,60));
    check(!asking(),'R2: the plan it is already filling in asked again');

    /* ── R2c · a plan is never inherited from another golfer's draft ─────── */
    const other='f0000000-0000-4000-8000-0000000000ff';
    const stolen=JSON.parse(JSON.stringify(saved)); stolen.owner=other;
    localStorage.setItem(postDraftKey(uid), JSON.stringify(stolen));
    reset(); restorePostDraft();
    check(state.post.plan===null,'R2: a plan was inherited from a draft written by somebody else');
    localStorage.removeItem(postDraftKey(uid));

    /* ── R2d · a kept request still owns the composer ────────────────────── */
    reset();
    postRequestWrite(uid,{id:'f0000000-0000-4000-8000-00000000000a',env:null,accepted:null});
    msgs.length=0; csPlanToComposer(ctx);
    await new Promise(r=>setTimeout(r,60));
    check(!asking(),'R2: a pending request was asked to be replaced');
    check(document.getElementById('inDate').value===_postDateStamp,'R2: a pending request had its date rewritten');
    check(msgs.some(m=>/already sent/i.test(m)),'R2: nothing said why the plan was refused');
    clearPostRequest(uid);

    /* ── R3 · the middle server: D345 without the capability gate ────────── */
    const legacy={key:'afterplan:'+PLAN,tier:'changed',rank:1,score:806,subject:'you',human_subject:true,
      headline:'A round yesterday',eyebrow:'YESTERDAY',action:'Add my round',
      route:{kind:'composer'},spine:'ember',at:ctx.play_on,suppress:[]};
    const good=Object.assign({},legacy,{context:ctx});
    const other2={key:'plan:x',tier:'coming',rank:2,score:600,subject:'you',human_subject:true,
      headline:'You have a round tomorrow.',eyebrow:'TOMORROW',action:'See the plan',
      route:{kind:'plan',id:PLAN},spine:'mut',at:isoAgo(-1),suppress:[]};
    const calls=[];
    const server=(accepts)=>async(name,args)=>{
      if(name!=='home_dispatch') return {data:null,error:null};
      calls.push(args);
      if(args.p_caps && !accepts.caps) return {error:{code:'PGRST202'}};
      if(args.p_today && !accepts.today) return {error:{code:'PGRST202'}};
      return {data:{items:(args.p_caps&&accepts.caps)?[good,other2]:[legacy,other2],lead_suppress:[]},error:null};
    };
    const answers=()=>document.querySelectorAll('[data-ans]').length;
    const door=k=>!!document.querySelector('[data-dgo="'+k+'"]');

    window.sb={rpc:server({caps:false,today:true})};   /* D345 only */
    calls.length=0; await loadHomeDispatch(); renderHomeDispatch();
    check(calls.length===2,'R3: the ladder did not stop at the day');
    check(!door(legacy.key),'R3: a D345-only server still rendered an unanswerable after-golf door');
    check(answers()===0,'R3: answer controls rendered for an item with no plan');
    check(door(other2.key),'R3: the rest of Home was thrown away with it');

    window.sb={rpc:server({caps:true,today:true})};    /* gated server */
    calls.length=0; await loadHomeDispatch(); renderHomeDispatch();
    check(calls.length===1,'R3: a capable server was asked twice');
    check(door(good.key) && answers()===2,'R3: a gated server lost the card or its answers');

    window.sb={rpc:server({caps:false,today:false})};  /* no D345 at all */
    calls.length=0; await loadHomeDispatch(); renderHomeDispatch();
    check(calls.length===3,'R3: the oldest shape was not reached');
    check(!door(legacy.key) && answers()===0,'R3: the oldest server produced an after-golf card');

    /* malformed context is the same answer as none */
    window.sb={rpc:async(n,a)=>{calls.push(a);return {data:{items:[Object.assign({},legacy,{context:{play_on:ctx.play_on}})],lead_suppress:[]},error:null};}};
    await loadHomeDispatch(); renderHomeDispatch();
    check(!door(legacy.key) && answers()===0,'R3: a context with no plan id was treated as usable');

    /* a transport failure leaves the ranker unreached, not a bad Home */
    window.sb={rpc:async()=>{throw new Error('offline')}};
    await loadHomeDispatch();
    check(window.homeDispatch===null,'R3: a transport failure did not read as unreachable');

    return {passed:true, checks:'R2 gross-only consent, save, relaunch, foreign draft, pending request; R3 four server shapes'};
  } finally {
    try{ clearPostRequest(uid); clearPostDraft(); closeSheet(); }catch(_){}
    window.fetch=realFetch; window.sb=realSb; window.CS=realCS; state.demo=realDemo;
    toast=realToast; switchView=realSwitch; finishCeremony=realFinish; window.qaEvent=realQa;
    state.post=realPost; window.homeDispatch=null; _draftRestored=false;
  }
})()
