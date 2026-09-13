/* Local-only fault injection through the real Post button. No backend writes. */
(async () => {
  const check=(ok,label)=>{if(!ok)throw new Error(label); checks++;};
  let checks=0, mode='offline';
  const calls=[], events=[], messages=[];
  const uid='b0000000-0000-4000-8000-000000000001';
  const round='b0000000-0000-4000-8000-000000000002';
  // Disable network before mounting a fictional signed-in golfer.
  window.fetch=async()=>{throw new Error('Fixture forbids network');};
  window.sb={
    rpc:async(name,args)=>{
      calls.push({name,args});
      if(name==='post_round_once'){
        if(mode==='offline')return {error:{message:'Failed to fetch'}};
        if(mode==='conflict')return {error:{message:'different scorecard'}};
        return {data:{round:{id:round},epilogue:{}}};
      }
      if(name==='round_post_status')return {data:{round:{id:round}}};
      return {data:null};
    },
    from:()=>({insert:async value=>{events.push(value);return {data:null};}})
  };
  window.CS={user:{id:uid},profile:{id:uid,display_name:'QA golfer'},memberships:[]};
  for(const name of ['loadStandingsAndFeed','loadCareer','loadHome','refreshHomeLead','openRoundSheet'])window[name]=async()=>{};
  window.csEarnInstallNudge=()=>{};
  // Keep navigation and celebration out of this fault test; acceptance and cleanup are real.
  switchView=()=>{}; scrollFeedBottom=()=>{}; showEpilogue=()=>{};
  toast=message=>messages.push(message);
  finishCeremony=()=>{throw new Error('Fixture narration failure');};
  state.demo=false;
  const seed=gross=>{
    state.post={mode:'total',side:18,pars:POST_PAR_STD.slice(),scores:POST_PAR_STD.slice(),playedWith:[],touched:true};
    for(const [id,value] of Object.entries({inDate:'2026-09-12',inGross:gross,inF9:'',inB9:'',inCourse:'QA course',inRating:72,inSlope:113}))document.getElementById(id).value=value;
    state.lastPost={pts:0,vs:10,label:String(gross)};
    document.getElementById('postBtn').disabled=false;
  };
  const tap=async()=>{
    document.getElementById('postBtn').click();
    for(let i=0;i<100;i++){
      await new Promise(r=>setTimeout(r,10));
      if(!document.getElementById('postBtn').disabled)return;
    }
    throw new Error('Post never settled');
  };
  clearPostRequest(uid); seed(84); await tap();
  const first=postRequestRead(uid);
  check(first?.id && first.env.payload.gross===84,'Offline attempt was not durably recorded');
  check(document.getElementById('inGross').value==='84','Offline attempt lost the card');
  seed(85); mode='conflict'; await tap();
  const posts=calls.filter(c=>c.name==='post_round_once');
  check(posts.length===2 && posts[0].args.p_request_id===posts[1].args.p_request_id,'Edited retry minted a second identity');
  check(posts[1].args.p_payload.gross===85,'Edited retry lost the corrected card');
  check(calls.some(c=>c.name==='round_post_status'),'Conflict did not recover the accepted round');
  check(!postRequestRead(uid) && !state.lastPost && !document.getElementById('inGross').value,'Recovered acceptance left a postable draft');
  seed(86); mode='success'; await tap();
  check(!postRequestRead(uid) && !state.lastPost && !document.getElementById('inGross').value,'Narration error left an accepted card postable');
  check(events.some(e=>e.event==='post_tail_fail'),'Narration failure was not exercised');
  check(!messages.some(m=>m.startsWith('Post failed')),'Accepted round was reported as a failed post');
  seed(87); localStorage.setItem(postRequestKey(uid),'{broken');
  const before=calls.filter(c=>c.name==='post_round_once').length; await tap();
  check(calls.filter(c=>c.name==='post_round_once').length===before,'Unreadable receipt sent another round');
  check(document.getElementById('inGross').value==='87','Unreadable receipt lost the draft');
  clearPostRequest(uid);
  return {checks,network:'disabled',journeys:['offline','edited retry','accepted recovery','narration failure','unreadable storage']};
})()
