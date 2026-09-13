(async()=>{
  window.fetch=async()=>{throw new Error('Review probe: network disabled');};
  const uid='f0000000-0000-4000-8000-000000000001';
  const ctx={plan_id:'f0000000-0000-4000-8000-000000000002',play_on:isoAgo(1),course_label:'Papago'};
  window.CS={user:{id:uid},profile:{display_name:'Review golfer'},league:{name:'Current league'},member:{id:'member'},squads:[{name:'Current squad',squad_members:[{member_id:'member'}]}],memberships:[]};
  const messages=[];toast=m=>messages.push(m);
  window.sb={rpc:async(name)=>name==='post_round_once'?{data:{round:{id:'f0000000-0000-4000-8000-000000000003',counts:true,league_name:'Earlier league',squad:'Earlier squad'},epilogue:{points:12,pvi:3}}}:{data:null},from:()=>({insert:async()=>({data:null})})};
  for(const k of ['loadStandingsAndFeed','loadCareer','loadHome','refreshHomeLead','openRoundSheet'])window[k]=async()=>{};
  switchView=()=>{};scrollFeedBottom=()=>{};showEpilogue=()=>{};window.csEarnInstallNudge=()=>{};
  state.demo=false;clearPostRequest(uid);clearPostDraft();closeSheet();
  const reset=()=>{
    for(const id of ['inF9','inB9','inGross','inRating','inSlope','inCourse'])document.getElementById(id).value='';
    stampPostDate();state.post={mode:'total',side:18,touched:false,pars:POST_PAR_STD.slice(),scores:POST_PAR_STD.slice(),playedWith:[],plan:null};
  };
  reset();document.getElementById('inGross').value='84';
  csPlanToComposer(ctx);
  const grossOnly={dateChangedWithoutConsent:document.getElementById('inDate').value===ctx.play_on,questionPresent:!!document.getElementById('planTake'),gross:document.getElementById('inGross').value};
  savePostDraft();await new Promise(r=>setTimeout(r,450));
  const saved=JSON.parse(localStorage.getItem(postDraftKey(uid))||'null');
  const persistence={grossSaved:saved?.vals?.inGross??null,planSaved:saved?.plan??null,dateSaved:saved?.vals?.inDate??null};
  reset();_draftRestored=false;const restored=restorePostDraft();
  const reload={restored,gross:document.getElementById('inGross').value,plan:state.post.plan??null,date:document.getElementById('inDate').value};
  let ceremony=null;finishCeremony=o=>{ceremony=o;};
  document.getElementById('inGross').value='84';document.getElementById('inRating').value='72';document.getElementById('inSlope').value='113';
  state.lastPost={pts:99,vs:8,label:'84'};document.getElementById('postBtn').disabled=false;document.getElementById('postBtn').click();
  for(let i=0;i<100 && !ceremony;i++)await new Promise(r=>setTimeout(r,20));
  await new Promise(r=>setTimeout(r,100));
  const ceremonyResult=ceremony?{points:ceremony.points,vs:ceremony.vs,league:ceremony.leagueName,squad:ceremony.squad}:null;
  // A D345-only server accepts p_today and returns an item with no context.
  const legacy={key:'afterplan:'+ctx.plan_id,tier:'changed',rank:1,score:806,headline:'A round yesterday',eyebrow:'YESTERDAY',action:'Add my round',route:{kind:'composer'},at:ctx.play_on};
  const homeCalls=[];
  window.sb.rpc=async(name,args)=>{homeCalls.push(args);return args.p_caps?{error:{code:'PGRST202'}}:{data:{items:[legacy],lead_suppress:[]}};};
  await loadHomeDispatch();renderHomeDispatch();
  const oldServer={calls:homeCalls.length,itemReturned:window.homeDispatch?.items?.[0]?.key,roundDoor:!!document.querySelector('[data-dgo="'+legacy.key+'"]'),answerButtons:document.querySelectorAll('[data-ans]').length};
  clearPostRequest(uid);clearPostDraft();
  return {grossOnly,persistence,reload,ceremony:ceremonyResult,oldServer};
})()
