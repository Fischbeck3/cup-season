/* MW-01 · Compete's START SOMETHING opens the intent sheet — through the
   rendered control, at the width under test. Serve this checkout, open
   /?exit, evaluate with web-verify.mjs. The audit reproduced the dead link by
   clicking it; this clicks it the same way and asserts the sheet, its season
   path, that closing it creates nothing, and that the empty root's door lands
   in the same place. state.demo is off for the walk (Compete renders nothing
   in demo) and every real write is refused by the RPC stub. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const until=async(t,label)=>{ for(let i=0;i<100;i++){ if(t()) return; await new Promise(r=>setTimeout(r,20)); } throw new Error(label); };
  const saved={ demo:state.demo, user:window.CS.user, mems:window.CS.memberships, rpc:window.sb&&window.sb.rpc,
                events:window.myEvents, sched:window.mySchedule, watch:window.watchAll, qa:window.qaEvent, dispatch:window.homeDispatch };
  const rpcs=[]; const logged=[];
  const sheet=()=>document.getElementById('sheet');
  const open=()=>sheet().classList.contains('open');
  const results={};
  try{
    state.demo=false;
    window.CS.user={ id:'a0000000-0000-4000-8000-000000000099' };
    window.qaEvent=(n,p)=>logged.push([n,p]);
    if(window.sb) window.sb.rpc=async(name,args)=>{ rpcs.push(name); return { data:null, error:{ code:'AUDIT', message:'refused by the audit: '+name } }; };
    window.myEvents=[]; window.mySchedule=[]; window.watchAll=[]; window.homeDispatch=null;

    /* ── populated Compete: two seasons, entered through the rendered tab ── */
    window.CS.memberships=[
      { id:'m1', role:'player', league:{ id:'f0000000-0000-4000-8000-0000000000a1', name:'Fellas', phase:'season' } },
      { id:'m2', role:'commissioner', league:{ id:'f0000000-0000-4000-8000-0000000000a2', name:'Who’s the bitch?', phase:'season' } }];
    const tab=document.querySelector('[data-v="compete"]');
    check(!!tab,'no rendered Compete tab');
    tab.click();
    await until(()=>document.getElementById('view-compete')?.classList.contains('active') || getComputedStyle(document.getElementById('view-compete')).display!=='none','Compete did not open from its tab');
    renderCompete();
    check(document.querySelectorAll('#cmpList .cband').length===1,'F11: the lead season is not a band');
    check(document.querySelectorAll('#cmpList .peerrow').length===1,'the other season did not render as a row');
    const start=document.getElementById('cmpStart');
    check(!!start,'START SOMETHING is not on the page');
    const r=start.getBoundingClientRect();
    check(r.width>0 && r.height>0,'START SOMETHING has no size at this width');
    check(start.tabIndex>=0 || start.tagName==='A','START SOMETHING is not keyboard reachable');
    check(!open(),'a sheet was already open');
    start.click();
    await until(open,'MW-01: START SOMETHING did not open the intent sheet');
    check(!!document.getElementById('csi-runASeason'),'the intent sheet does not offer a season');
    check(!!document.getElementById('csi-code'),'the intent sheet lost its code door');
    check(location.hash!=='#',"the link's href=\"#\" navigated instead of opening");
    results.populated=document.getElementById('shTitle').textContent;

    /* ── cancel creates nothing: Escape, the backdrop, the close control ── */
    document.dispatchEvent(new KeyboardEvent('keydown',{ key:'Escape', bubbles:true }));
    await until(()=>!open(),'Escape did not close the sheet');
    start.click(); await until(open,'the second open failed');
    document.getElementById('shClose').click();
    await until(()=>!open(),'the close control did not close the sheet');
    start.click(); await until(open,'the third open failed');
    sheet().dispatchEvent(new MouseEvent('click',{ bubbles:true }));
    await until(()=>!open(),'the backdrop did not close the sheet');
    check(rpcs.length===0,'cancelling the sheet wrote to the server: '+rpcs.join(','));
    check(logged.filter(x=>x[0]==='cta_tapped' && x[1] && x[1].door==='compete:start').length===3,'the taps were not recorded as the compete door');

    /* ── the season path lands on the name sheet's control, and only there ── */
    let named=0; const wc=document.getElementById('wCreate');
    check(!!wc,'no name-sheet control to land on');
    const stop=e=>{ named++; e.stopImmediatePropagation(); e.preventDefault(); };
    wc.addEventListener('click',stop,{ capture:true });
    start.click(); await until(open,'the fourth open failed');
    document.getElementById('csi-runASeason').click();
    await until(()=>!open(),'choosing a season did not close the sheet');
    wc.removeEventListener('click',stop,{ capture:true });
    check(named===1,'the season intent did not reach the name sheet exactly once');
    check(rpcs.length===0,'choosing the season path wrote to the server before a name was given');

    /* ── the empty root: the same door, not a straight jump to the wizard ── */
    window.CS.memberships=[]; window.__buddyCount=0;
    renderCompete();
    const door=document.querySelector('#cmpList [data-erdoor="startSomething"]');
    check(!!door,'the empty root has no Start something door');
    check(door.getBoundingClientRect().height>=44-1,'the empty-root door is under the tap target');
    const views=[]; const realView=switchView; switchView=v=>{ views.push(v); };
    try{
      door.click();
      await until(open,'MW-01: the empty root’s door did not open the intent sheet');
      check(!views.includes('wizard'),'the empty root jumped straight to the wizard');
    } finally { switchView=realView; }
    document.getElementById('shClose').click(); await until(()=>!open(),'could not close after the empty-root open');
    check(rpcs.length===0,'the empty-root path wrote to the server');
    results.empty=true;
    results.passed=true;
    return results;
  } finally {
    state.demo=saved.demo; window.CS.user=saved.user; window.CS.memberships=saved.mems;
    if(window.sb) window.sb.rpc=saved.rpc; window.myEvents=saved.events; window.mySchedule=saved.sched;
    window.watchAll=saved.watch; window.qaEvent=saved.qa; window.homeDispatch=saved.dispatch;
    if(open()) closeSheet();
  }
})()
