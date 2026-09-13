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

    /* ── R6 · the question describes THIS card ──────────────────────────── */
    window.sb={rpc:async()=>({data:null,error:null})};
    reset(); document.getElementById('inGross').value='84';
    csPlanToComposer(ctx); await until(asking,'R6: no question for a started card');
    let q=document.getElementById('sheet').textContent;
    check(/changes the date and the course/.test(q),'R6: a blank course should take the plan\u2019s');
    document.getElementById('planKeep').click();
    reset(); document.getElementById('inGross').value='84';
    document.getElementById('inCourse').value='Somewhere else';
    csPlanToComposer(ctx); await until(asking,'R6: no question with a typed course');
    q=document.getElementById('sheet').textContent;
    check(/changes the date, and nothing else/.test(q),'R6: it promised a course change it will not make');
    check(/Somewhere else stays/.test(q),'R6: it did not say the typed course stays');
    document.getElementById('planTake').click();
    check(document.getElementById('inCourse').value==='Somewhere else','R6: the typed course was replaced after all');
    check(document.getElementById('inDate').value===ctx.play_on,'R6: the date did not change');

    /* ── R4 · one server result, one attribution ─────────────────────────── */
    let ceremony=null; finishCeremony=o=>{ceremony=o;};
    const post=(round,epi)=>{
      window.sb={rpc:async(n)=>n==='post_round_once'?{data:{round:round,epilogue:epi},error:null}:{data:null,error:null},
                 from:()=>({insert:async()=>({data:null,error:null})})};
    };
    const fire=async()=>{
      ceremony=null;
      clearPostRequest(uid); clearPostDraft();
      reset();
      document.getElementById('inGross').value='84';
      document.getElementById('inRating').value='72';
      document.getElementById('inSlope').value='113';
      state.lastPost={pts:99,vs:8,label:'84'};
      const b=document.getElementById('postBtn'); b.disabled=false; b.click();
      await until(()=>ceremony,'R4: the ceremony never fired');
      await new Promise(r=>setTimeout(r,80));
      return ceremony;
    };
    for(const k of ['loadStandingsAndFeed','loadCareer','loadHome','refreshHomeLead','openRoundSheet'])window[k]=async()=>{};
    window.scrollFeedBottom=()=>{}; window.showEpilogue=()=>{}; window.csEarnInstallNudge=()=>{};
    if(typeof scrollFeedBottom==='undefined'){} else { scrollFeedBottom=()=>{}; }
    showEpilogue=()=>{};

    /* a BACKDATED round the server scored for an earlier league */
    post({id:'f0000000-0000-4000-8000-000000000003',counts:true,league_name:'Earlier league',squad:'Earlier squad'},{points:12,pvi:3});
    let c=await fire();
    check(c.points===12 && c.vs===3,'R4: the ceremony did not use the server figures');
    check(c.leagueName==='Earlier league','R4: the ceremony named the open league, not the scoring one');
    check(c.squad==='Earlier squad','R4: the ceremony named the open squad, not the scoring one');
    check(c.inLeague===true,'R4: a counting round did not read as counting');

    /* a round that counts for NO season names no league and no squad */
    post({id:'f0000000-0000-4000-8000-000000000004',counts:false,league_name:null,squad:null},{points:0,pvi:1});
    c=await fire();
    check(c.inLeague===false,'R4: a non-counting round read as counting');
    check(c.leagueName===null && c.squad===null,'R4: the open league stood in for a season the round does not belong to');
    check(c.points===null,'R4: points were claimed for a round that counts for nothing');

    /* an older server that omits `counts` falls back, and says so */
    const logged=[]; window.qaEvent=(n,p)=>logged.push(n);
    post({id:'f0000000-0000-4000-8000-000000000005',league_name:null,squad:null},{points:7,pvi:2});
    c=await fire();
    check(logged.includes('ceremony_client_figures'),'R4: a client-figure ceremony was not recorded as one');
    window.qaEvent=()=>{};

    /* ── F2 · the ACTUAL Start over button ───────────────────────────────
       Reset kept its own field list without `inGross` and never cleared the
       plan, so a fresh round began carrying the previous one's score and its
       plan identity while the date reset to today. The button is clicked here,
       not the function called. */
    window.sb={rpc:async()=>({data:null,error:null})};
    clearPostRequest(uid); clearPostDraft();
    reset();
    document.getElementById('inGross').value='84';
    document.getElementById('inF9').value='41';
    document.getElementById('inB9').value='43';
    document.getElementById('inRating').value='71.2';
    document.getElementById('inSlope').value='128';
    document.getElementById('inCourse').value='Papago';
    document.getElementById('inCourse').dataset.courseId='gc-1';
    state.post.playedWith=['f0000000-0000-4000-8000-00000000000b'];
    state.post.touched=true; state.post.side=9; state.post.rating9=true;
    state.post.plan={id:PLAN, play_on:ctx.play_on};
    document.getElementById('inDate').value=ctx.play_on;
    savePostDraft(); await new Promise(r=>setTimeout(r,450));
    check(!!localStorage.getItem(postDraftKey(uid)),'F2: nothing was saved to start over from');

    document.getElementById('postReset').click();
    await new Promise(r=>setTimeout(r,60));
    check(document.getElementById('inGross').value==='','F2: Start over kept the gross');
    for(const id of ['inF9','inB9','inRating','inSlope','inCourse'])
      check(document.getElementById(id).value==='','F2: Start over kept '+id);
    check(document.getElementById('inCourse').dataset.courseId==='','F2: Start over kept the course id');
    check(state.post.plan===null,'F2: Start over kept the plan');
    check(state.post.playedWith.length===0,'F2: Start over kept the partners');
    check(state.post.touched===false && state.post.side===18 && state.post.rating9===false,'F2: Start over kept the card shape');
    check(document.getElementById('inDate').value===_postDateStamp,'F2: Start over did not restore today\u2019s date');
    check(!postDraftHasContent(csPostVals(), state.post.touched),'F2: the cleared card still reads as work');

    /* and the abandoned content does not come back on the next load */
    check(!localStorage.getItem(postDraftKey(uid)),'F2: the abandoned draft survived Start over');
    _draftRestored=false;
    check(restorePostDraft()===false,'F2: a reload restored the abandoned card');
    check(document.getElementById('inGross').value==='','F2: the abandoned gross came back');
    check(state.post.plan===null,'F2: the abandoned plan came back');

    /* the frozen request is NOT released by Start over — that is what it is for */
    postRequestWrite(uid,{id:'f0000000-0000-4000-8000-00000000000c',env:null,accepted:null});
    reset(); document.getElementById('inGross').value='91';
    document.getElementById('postReset').click();
    await new Promise(r=>setTimeout(r,60));
    const kept=postRequestRead(uid);
    check(kept && kept.id==='f0000000-0000-4000-8000-00000000000c','F2: Start over released a request the server may hold');
    clearPostRequest(uid);

    /* navigating away is not starting over: an ordinary draft continues */
    reset(); document.getElementById('inGross').value='77';
    savePostDraft(); await new Promise(r=>setTimeout(r,450));
    switchView('home'); switchView('post');
    await new Promise(r=>setTimeout(r,60));
    check(document.getElementById('inGross').value==='77','F2: leaving the screen cleared the card');
    check(!!localStorage.getItem(postDraftKey(uid)),'F2: leaving the screen scrapped the draft');
    clearPostDraft();

    return {passed:true, checks:'R2 consent/save/relaunch/foreign/pending; R3 four server shapes; R4 attribution; R6 question copy; F2 actual Start over + reload + request ownership + navigation'};
  } finally {
    try{ clearPostRequest(uid); clearPostDraft(); closeSheet(); }catch(_){}
    window.fetch=realFetch; window.sb=realSb; window.CS=realCS; state.demo=realDemo;
    toast=realToast; switchView=realSwitch; finishCeremony=realFinish; window.qaEvent=realQa;
    state.post=realPost; window.homeDispatch=null; _draftRestored=false;
  }
})()
