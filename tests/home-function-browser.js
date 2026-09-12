/* Local browser audit. Serve this checkout, open /?exit, then evaluate this
   file with web-verify.mjs. All rounds are illustrative; state.demo prevents
   writes and destination callbacks are restored after inspection. */
(async function(){
  const check=(ok,label)=>{if(!ok)throw new Error(label)};
  const until=async(test,label)=>{for(let i=0;i<100;i++){if(test())return;await new Promise(r=>setTimeout(r,20));}throw new Error(label);};
  const saved={demo:state.demo,rows:DEMO_FEED.slice(),receipt:openRoundReceipt,rpc:window.sb.rpc,user:window.CS.user,spent:window.__spentRounds};
  let openedRound=null,openedGolfer=null;
  const bad='data:image/png;base64,aW52YWxpZA==';
  const good='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII=';
  try{
    state.demo=true;window.__spentRounds=new Set();
    openRoundReceipt=r=>{openedRound=r;};
    window.CS.user={id:'a0000000-0000-4000-8000-000000000099'};
    window.sb.rpc=async(name,args)=>{
      if(name==='tour_card'){openedGolfer=args.p_profile;return {data:{visible:false},error:null};}
      if(name==='my_friends')return {data:[],error:null};
      throw new Error('Unexpected audit RPC: '+name);
    };
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
    first().querySelector('.hfrecord-body').click();check(openedRound===DEMO_FEED[0],'Receipt tap lost its source round');
    openedRound=null;
    const person=first().querySelector('.hfperson');person.focus();check(document.activeElement===person,'Golfer cannot take keyboard focus');
    const key=new KeyboardEvent('keydown',{key:'Enter',bubbles:true,cancelable:true});person.dispatchEvent(key);check(!key.defaultPrevented,'Receipt swallowed golfer keyboard activation');
    const row=()=>first().querySelector('.hrx');
    const visible=()=>[...row().querySelectorAll('[data-hrx]')].filter(b=>b.getClientRects().length);
    check(!visible().length,'Untouched round shows a reaction');
    row().querySelector('[data-hreact]').click();check(visible().length===4,'Missing reaction choices');
    visible()[0].click();check(visible().length===1 && visible()[0].textContent==='1','Selection did not collapse to actual count');
    check(!openedRound,'Reaction opened the receipt');
    visible()[0].click();check(!visible().length && row().textContent.includes('React'),'Removal did not restore invitation');
    const photoURL=DEMO_FEED[0].photo_url;DEMO_FEED[0].photo_url=good;renderHomeFeed();
    await until(()=>first().querySelector('.hsbg')?.naturalWidth>0,'Refreshed image did not load');
    check(first().classList.contains('hfstory'),'Successful image lost its photo treatment');
    await visitGolfer();
    // Leave the no-image fallback and the next row's revealed choices for QA.
    DEMO_FEED[0].photo_url=photoURL;renderHomeFeed();
    box.querySelectorAll('[data-hreact]')[1].click();
    check(box.querySelector('[data-hfr="1"] .hfrecord-date'),'Fallback lost the next row dateline');
    check(document.documentElement.scrollWidth<=innerWidth,'Horizontal overflow');
    const targets=[...box.querySelectorAll('.hfperson,.rxchip')].filter(b=>b.getClientRects().length);
    check(targets.every(b=>b.getBoundingClientRect().width>=44 && b.getBoundingClientRect().height>=44),'Target below 44px');
    console.log('Home audit passed: failed photo, refreshed photo, preserved data, golfer/receipt routes, keyboard, reactions, targets and reflow');
    return {passed:true};
  }finally{
    state.demo=saved.demo;DEMO_FEED.splice(0,DEMO_FEED.length,...saved.rows);openRoundReceipt=saved.receipt;window.sb.rpc=saved.rpc;window.CS.user=saved.user;window.__spentRounds=saved.spent;
    homeFailedPhotos.delete(bad);
  }
})()
