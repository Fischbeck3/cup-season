/* Local browser audit. Serve this checkout, open /?exit, then evaluate this
   file with web-verify.mjs. All rounds are illustrative; state.demo prevents
   writes and destination callbacks are restored after inspection. */
(async function(){
  const check=(ok,label)=>{if(!ok)throw new Error(label)};
  const until=async(test,label)=>{for(let i=0;i<100;i++){if(test())return;await new Promise(r=>setTimeout(r,20));}throw new Error(label);};
  const saved={demo:state.demo,rows:DEMO_FEED.slice(),receipt:openRoundReceipt,rpc:window.sb.rpc,user:window.CS.user,spent:window.__spentRounds,dispatch:window.homeDispatch,rx:window.homeRx,feed:window.homeFeedRows,posts:window.homePosts,write:rxWrite};
  let openedRound=null,openedGolfer=null;
  const bad='data:image/png;base64,aW52YWxpZA==';
  const good='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII=';
  try{
    state.demo=true;window.__spentRounds=new Set();
    openRoundReceipt=r=>{openedRound=r;};
    window.CS.user={id:'a0000000-0000-4000-8000-000000000099'};
    const dispatchCalls=[];
    const answerCalls=[];
    let answerReply=()=>({data:{applied:true,reason:null},error:null});
    window.sb.rpc=async(name,args)=>{
      if(name==='home_dispatch'){
        dispatchCalls.push(args);
        /* D353 · the ladder is three rungs now: capability, then day, then
           neither. An old server rejects the two it has never heard of. */
        if(args.p_caps || args.p_today) return {data:null,error:{code:'PGRST202'}};
        return {data:{items:[]},error:null};
      }
      if(name==='answer_plan_followup'){ answerCalls.push(args); return answerReply(args); }
      if(name==='tour_card'){openedGolfer=args.p_profile;return {data:{visible:false},error:null};}
      if(name==='my_friends')return {data:[],error:null};
      throw new Error('Unexpected audit RPC: '+name);
    };
    state.demo=false;await loadHomeDispatch();state.demo=true;
    check(dispatchCalls.length===3,'Home did not walk the capability ladder');
    check(Array.isArray(dispatchCalls[0].p_caps) && dispatchCalls[0].p_caps.indexOf('afterplan.v1')>=0,'Home did not declare what it can do');
    check(dispatchCalls[0].p_today===isoAgo(0),'Home did not send its own calendar day');
    check(!('p_caps' in dispatchCalls[1]) && dispatchCalls[1].p_today===isoAgo(0),'Home did not retry without the capability');
    check(!('p_caps' in dispatchCalls[2]) && !('p_today' in dispatchCalls[2]),'Home did not fall back to the oldest shape');
    check(window.homeDispatch?.items.length===0,'Home retry discarded a valid reply');

    /* ── D353/D354 · the after-golf card, on a server that answers ──────────
       Home renders nothing in demo, so this stretch runs as the signed-in
       desk it is testing and hands demo back afterwards. */
    state.demo=false;
    /* The destination is not what is under test here, and letting the real one
       run starts network loads that outlive the audit. The door is asked for,
       recorded, and handed back at the end. */
    const views=[]; const realView=switchView; switchView=v=>{views.push(v);};
    /* Repainting the wire and the digest fetches avatars and photos for a
       session this audit does not have. The card is what is under test. */
    const realRows=window.homeFeedRows; window.homeFeedRows=undefined;
    /* Every tap below is a real one, and a real tap logs. With this audit's
       fictional user and no session that log is an authenticated write that
       401s — the walk's artefact, not the page's. Recorded instead. */
    const logged=[]; const realQa=window.qaEvent; window.qaEvent=(n,p)=>{logged.push([n,p]);};
    const PLAN='c0000000-0000-4000-8000-0000000000a1', PLAY=isoAgo(1);
    const card=()=>({key:'afterplan:'+PLAN,tier:'changed',rank:1,score:806,subject:'you',human_subject:true,
      eyebrow:'SAT · PAPAGO',headline:'You planned a round for yesterday.',standfirst:'Nothing posted yet.',
      action:'Add my round',route:{kind:'composer'},spine:'ember',at:PLAY,suppress:[],
      context:{plan_id:PLAN,play_on:PLAY,course_label:'Papago',course_id:null,tee_time:null}});
    window.homeDispatch={items:[card()],lead_suppress:[]};
    renderHomeDispatch();
    const lead=document.getElementById('homeLead');
    check(!!lead.querySelector('[data-dgo=\"afterplan:'+PLAN+'\"]'),'The after-golf card lost its round door');
    const outs=()=>Array.from(lead.querySelectorAll('[data-ans]'));
    check(outs().length===2,'The after-golf card has no way out');
    check(outs().map(b=>b.getAttribute('data-ans')).join(',')==='later,didnt_play','The two ways out are not Later and Didn\u2019t play');
    check(outs().every(b=>b.getBoundingClientRect().height>=44),'An answer control is below the tap target');

    /* the round door fills in the day that was PLAYED, not today */
    const dEl=document.getElementById('inDate'), cEl=document.getElementById('inCourse');
    dEl.value=isoAgo(0); cEl.value=''; cEl.dataset.courseId='x'; state.post.touched=false; state.post.plan=null;
    ['inF9','inB9','inRating','inSlope'].forEach(id=>{document.getElementById(id).value='';});
    lead.querySelector('[data-dgo]').click();
    check(dEl.value===PLAY,'The composer did not take the plan\u2019s day');
    check(cEl.value==='Papago','The composer did not take the plan\u2019s course');
    check(cEl.dataset.courseId==='','A course id was claimed without a tee');
    check(state.post.plan && state.post.plan.id===PLAN,'The plan identity was not kept beside the draft');
    check(views[views.length-1]==='post','The after-golf door did not open the composer');

    /* a started card is never replaced without a tap */
    dEl.value=isoAgo(0); cEl.value=''; state.post.plan=null;
    document.getElementById('inF9').value='41';
    lead.querySelector('[data-dgo]').click();
    await until(()=>document.getElementById('sheet')?.classList.contains('open'),'A started card was replaced with no question');
    check(dEl.value===isoAgo(0),'A started card lost its date before the golfer answered');
    document.getElementById('planKeep').click();
    check(dEl.value===isoAgo(0) && document.getElementById('inF9').value==='41','Keeping the started round changed it');
    lead.querySelector('[data-dgo]').click();
    await until(()=>document.getElementById('planTake'),'The replace choice did not return');
    document.getElementById('planTake').click();
    check(dEl.value===PLAY && document.getElementById('inF9').value==='41','Replacing changed more than the date and course');
    document.getElementById('inF9').value='';state.post.plan=null;

    /* an answer that lands clears the card; one that fails keeps it */
    answerCalls.length=0;
    window.homeDispatch={items:[card()],lead_suppress:[]};renderHomeDispatch();
    answerReply=()=>({data:null,error:{message:'network'}});
    lead.querySelector('[data-ans=\"later\"]').click();
    await until(()=>answerCalls.length===1,'Later did not reach the server');
    check(answerCalls[0].p_plan===PLAN && answerCalls[0].p_answer==='later' && answerCalls[0].p_today===isoAgo(0),'Later sent the wrong request');
    await until(()=>lead.querySelector('[data-ans=\"later\"]') && !lead.querySelector('[data-ans=\"later\"]').disabled,'A failed answer left the control dead');
    check(!!lead.querySelector('[data-dgo]'),'A failed answer threw the card away');

    answerReply=()=>({data:{applied:true,reason:null,answer:'didnt_play',snooze_until:null},error:null});
    window.homeDispatch={items:[card()],lead_suppress:[]};renderHomeDispatch();
    lead.querySelector('[data-ans=\"didnt_play\"]').click();
    await until(()=>!lead.querySelector('[data-ans]'),'An applied answer left the card on Home');

    /* a terminal answer is resolved, not a failure: the card still goes */
    answerReply=()=>({data:{applied:false,reason:'terminal',answer:'didnt_play',snooze_until:null},error:null});
    window.homeDispatch={items:[card()],lead_suppress:[]};renderHomeDispatch();
    lead.querySelector('[data-ans=\"later\"]').click();
    await until(()=>!lead.querySelector('[data-ans]'),'A terminal answer was treated as a failure');
    answerReply=()=>({data:{applied:true,reason:null},error:null});
    window.homeDispatch=null;dispatchCalls.length=0;
    check(logged.some(([n,p])=>n==='cta_tapped' && p && p.door==='afterplan' && p.tier==='later'),'An answer logged the wrong thing');
    check(!JSON.stringify(logged).includes(PLAN),'Telemetry carried the plan id');
    state.demo=true;switchView=realView;window.homeFeedRows=realRows;window.qaEvent=realQa;
    DEMO_FEED.splice(0,DEMO_FEED.length,
      {round_id:'a0000000-0000-4000-8000-000000000001',profile_id:'a0000000-0000-4000-8000-000000000011',golfer:'You',marker:'azalea',gross:84,pvi:0,course:'Oak Quarry',played_on:isoAgo(0),is_me:true,photo_url:bad,rx:{}},
      {round_id:'a0000000-0000-4000-8000-000000000002',profile_id:'a0000000-0000-4000-8000-000000000012',golfer:'Sam',marker:'jug',gross:79,course:'Papago',played_on:isoAgo(1),is_pr:true,rx:{}});
    const box=document.getElementById('homeFeed');
    const wrapper=document.createElement('main');wrapper.style.cssText='max-width:620px;margin:0 auto;padding:24px';
    const sprite=document.querySelector('#i-plus').closest('svg');
    wrapper.id='cs-home-audit';wrapper.append(box);document.body.append(wrapper);
    const hide=document.createElement('style');hide.textContent='body > :not(#cs-home-audit):not(#sheet):not(#toast):not(svg){display:none!important}';document.head.append(hide);
    renderHomeFeed();
    await until(()=>box.querySelector('[data-hfr="0"].hfrecord'),'Failed photo did not yield to record');
    check(DEMO_FEED[0].photo_url===bad,'Photo failure mutated round data');
    const first=()=>box.querySelector('[data-hfr="0"]');
    const visitGolfer=async()=>{
      openedGolfer=null;state.demo=false;first().querySelector('.hfperson').click();
      await until(()=>openedGolfer!==null,'Golfer route never requested a card');
      check(openedGolfer===DEMO_FEED[0].profile_id && openedRound===null,'Golfer tap opened wrong destination');
      await until(()=>document.getElementById('shSub').textContent==='PRIVATE','Golfer route did not reach its result');
      closeSheet();state.demo=true;
    };
    await visitGolfer();
    first().querySelector('.hfr-title').click();check(openedRound===DEMO_FEED[0],'Receipt tap lost its source round');
    openedRound=null;
    const person=first().querySelector('.hfperson');person.focus();check(document.activeElement===person,'Golfer cannot take keyboard focus');
    const key=new KeyboardEvent('keydown',{key:'Enter',bubbles:true,cancelable:true});person.dispatchEvent(key);check(!key.defaultPrevented,'Receipt swallowed golfer keyboard activation');
    const row=()=>first().querySelector('.hrx');
    const visible=()=>[...row().querySelectorAll('[data-hrx]')].filter(b=>b.getClientRects().length);
    check(!visible().length,'Untouched round shows a reaction');
    row().querySelector('[data-hreact]').click();check(visible().length===4,'Missing reaction choices');
    check(!row().querySelector('[data-hreact]').getClientRects().length,'Expanded reactions retained plus');
    check(document.activeElement===visible()[0],'Reaction reveal lost keyboard focus');
    visible()[0].click();check(visible().length===1 && visible()[0].textContent==='1','Selection did not collapse to actual count');
    check(!openedRound,'Reaction opened the receipt');
    check(document.activeElement===visible()[0],'Reaction selection lost focus');
    visible()[0].click();check(!visible().length && row().textContent.includes('React'),'Removal did not restore invitation');
    check(document.activeElement===row().querySelector('[data-hreact]'),'Reaction removal lost focus');
    // Exercise the real optimistic/rollback render with an isolated failed write.
    window.homeFeedRows=DEMO_FEED;window.homePosts=[];
    window.homeRx={post:{[DEMO_FEED[0].round_id]:{post_id:'qa-post',league_id:null}},kud:{'qa-post':{}},names:{}};
    rxWrite=async()=>({message:'Deliberate local reaction failure'});
    state.demo=false;renderHomeFeed();
    row().querySelector('[data-hreact]').click();
    const choice=visible()[0];choice.focus();const emoji=choice.dataset.e;
    await toggleHomeRx(DEMO_FEED[0],emoji);
    check(!visible().length && document.activeElement===row().querySelector('[data-hreact]'),'Failed reaction lost restored invitation focus');
    rxWrite=saved.write;state.demo=true;renderHomeFeed();
    const photoURL=DEMO_FEED[0].photo_url;DEMO_FEED[0].photo_url=good;renderHomeFeed();
    await until(()=>first().querySelector('.hsbg')?.naturalWidth>0,'Refreshed image did not load');
    check(first().classList.contains('hfstory'),'Successful image lost its photo treatment');
    await visitGolfer();
    for(const course of [null,'','   ']){
      const missing={...DEMO_FEED[0],course,gross:null,pvi:-4,is_pr:true};
      for(const photo_url of [null,good]){
        const probe=document.createElement('div');probe.innerHTML=feedRow({...missing,photo_url});
        check(probe.querySelector('.hfcard').getAttribute('aria-label').includes('Course not recorded'),'Missing-course spoken copy lost');
        check(!probe.textContent.includes('Personal best') && !probe.textContent.includes('beat their'),'Missing score asserted performance');
      }
    }
    // Leave the no-image fallback and the next row's revealed choices for QA.
    DEMO_FEED[0].photo_url=photoURL;renderHomeFeed();
    box.querySelectorAll('[data-hreact]')[1].click();
    check(box.querySelector('[data-hfr="1"] .hfr-day'),'Fallback lost the next row dateline');
    check(document.documentElement.scrollWidth<=innerWidth,'Horizontal overflow');
    const targets=[...box.querySelectorAll('.hfperson,.rxchip')].filter(b=>b.getClientRects().length);
    check(targets.every(b=>b.getBoundingClientRect().width>=44 && b.getBoundingClientRect().height>=44),'Target below 44px');
    console.log('Home audit passed: failed photo, refreshed photo, preserved data, golfer/receipt routes, keyboard, reactions, targets and reflow');
    return {passed:true};
  }finally{
    state.demo=saved.demo;DEMO_FEED.splice(0,DEMO_FEED.length,...saved.rows);openRoundReceipt=saved.receipt;window.sb.rpc=saved.rpc;window.CS.user=saved.user;window.__spentRounds=saved.spent;
    homeFailedPhotos.delete(bad);window.homeDispatch=saved.dispatch;window.homeRx=saved.rx;window.homeFeedRows=saved.feed;window.homePosts=saved.posts;rxWrite=saved.write;
  }
})()
