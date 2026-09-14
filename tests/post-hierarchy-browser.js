/* MW-05 · the composer says what THIS league counts, and leads with the score.
   Serve this checkout, open /?exit, evaluate with web-verify.mjs at 390 and
   320. Nothing is submitted: the post button is never clicked. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const saved={ demo:state.demo, user:window.CS.user, league:window.CS.league, settings:window.CS.settings,
                structure:state.structure, capExact:state.capExact, phase:state.phase, rpc:window.sb&&window.sb.rpc,
                from:window.sb&&window.sb.from, scan:window.scanFlag, photo:state.post.photo, qa:window.qaEvent };
  const out={};
  /* the painted line if it exists; otherwise whatever the composer prints in
     its place, so this reads the same claim on a build that has not been
     repaired yet rather than dying on a missing id */
  const note=()=>{
    const el=document.getElementById('postCountingNote')
      || Array.from(document.querySelectorAll('#view-post p.fine'))
           .find(p=>/count/i.test(p.textContent) && /round/i.test(p.textContent));
    return el ? el.textContent.trim() : '(no counting sentence on this build)';
  };
  try{
    state.demo=false; window.CS.user={ id:'a0000000-0000-4000-8000-000000000099' };
    /* switchView('post') below is a REAL entry, and a real entry logs. With
       this walk's fictional user and no session that log is an authenticated
       write that 401s — the walk's artefact, not the composer's. Recorded
       here instead, the way the other suites record it. */
    window.qaEvent=()=>{};
    if(window.sb){
      window.sb.rpc=async(n)=>({ data:null, error:{ code:'AUDIT', message:'refused by the audit: '+n } });
      window.sb.from=()=>({ insert:async()=>({ data:null, error:null }),
                            select:()=>({ eq:()=>({ maybeSingle:async()=>({ data:null, error:null }),
                                                    single:async()=>({ data:null, error:null }),
                                                    limit:async()=>({ data:[], error:null }) }),
                                          limit:async()=>({ data:[], error:null }) }) });
    }

    /* ── the sentence is the league's own rule ─────────────────────────────── */
    window.CS.league={ id:'f0000000-0000-4000-8000-0000000000a1', name:'Fellas', phase:'season' };
    state.phase='season';
    window.CS.settings={ structure:'solo', counting_cap:2 }; state.structure='solo'; state.capExact=2;
    csRenderComposerEyebrow();
    check(!/squad/i.test(note()),'MW-05: a SOLO league is still told its rounds count toward a squad: '+note());
    check(/best two each month/.test(note()),'MW-05: the league’s stored cap is not in the sentence: '+note());
    check(/season total/.test(note()),'MW-05: the solo sentence does not say what it counts toward: '+note());
    out.solo=note();

    window.CS.settings={ structure:'squads4', counting_cap:3 }; state.structure='squads4'; state.capExact=3;
    csRenderComposerEyebrow();
    check(/toward your squad/.test(note()) && /best three each month/.test(note()),'MW-05: the squad sentence is wrong: '+note());
    out.squads=note();

    /* Unlimited is a real setting: null cap, and no "best few" claim */
    window.CS.settings={ structure:'solo', counting_cap:null }; state.capExact=null; state.structure='solo';
    csRenderComposerEyebrow();
    check(/every one of them counts/.test(note()) && !/best/.test(note()),'MW-05: Unlimited still claims a counting cap: '+note());
    out.unlimited=note();

    /* no season at all — it still posts, and says so without promising points */
    window.CS.league=null; window.CS.settings=null; state.phase='none';
    csRenderComposerEyebrow();
    check(/join a season/i.test(note()) && !/squad/i.test(note()),'MW-05: a golfer with no season is told about a squad: '+note());
    check(!/against your number/i.test(note()),'§42: the banned gloss came back');
    out.noLeague=note();

    /* ── the score leads; the optional camera is quiet but reachable ───────── */
    window.CS.league={ id:'f0000000-0000-4000-8000-0000000000a1', name:'Fellas', phase:'season' };
    state.phase='season'; state.structure='solo'; state.capExact=2;
    window.CS.settings={ structure:'solo', counting_cap:2 };
    switchView('post');
    /* `loadScanFlag` runs on entry and lands after this tick; the flag is set
       after it, so the scan control is the one the golfer with the flag on
       sees rather than whatever the stubbed read returned */
    await new Promise(r=>setTimeout(r,120));
    window.scanFlag={ enabled:true };
    refreshPostPhotoUI();
    await new Promise(r=>setTimeout(r,60));
    const gross=document.getElementById('inGross'), plate=document.getElementById('postPhotoBtn'),
          scan=document.getElementById('postScanBtn'), postBtn=document.getElementById('postBtn'),
          inherit=document.getElementById('postInherit');
    const box=el=>el.getBoundingClientRect();
    check(box(gross).height>0,'the gross box did not render');
    /* the primary number is the tallest thing above the action — ON A PHONE,
       which is where the finding was made and where the change is scoped. The
       desk keeps its approved side-by-side composition above 460. */
    if(innerWidth<=460)
      check(box(gross).height > box(plate).height,'MW-05: the optional photo frame is still taller than the score: '
            +Math.round(box(gross).height)+' vs '+Math.round(box(plate).height));
    else
      check(box(plate).height>0 && box(gross).height>0,'the desk composition lost a control');
    /* and the order down the page is score → course/date → action */
    check(box(gross).top < box(inherit).top,'MW-05: the course line sits above the score');
    check(box(inherit).top < box(postBtn).top,'MW-05: the action sits above the course line');
    /* quieter, never gone: both optional controls are still real targets */
    for(const [el,name] of [[plate,'the photo control'],[scan,'the scan control']]){
      check(box(el).width>0 && box(el).height>=44-1, 'MW-05: '+name+' is no longer usable: '+JSON.stringify({w:Math.round(box(el).width),h:Math.round(box(el).height)}));
    }
    check(/photo/i.test(plate.textContent) || /photo/i.test(plate.getAttribute('aria-label')||''),'the photo control lost its words');
    out.gross=Math.round(box(gross).height); out.plate=Math.round(box(plate).height);

    /* a real photograph earns the frame back rather than staying a thin row */
    const png=Uint8Array.from(atob('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII='), c=>c.charCodeAt(0));
    setPostPhoto(new Blob([png], { type:'image/png' }));
    await new Promise(r=>setTimeout(r,60));
    check(document.getElementById('postPhotoRow').classList.contains('has-photo'),'MW-05: an attached photo did not claim its frame');
    if(innerWidth<=460) check(box(document.getElementById('postPhotoBtn')).height>60,'MW-05: an attached photo is still a thin row');
    setPostPhoto(null);
    await new Promise(r=>setTimeout(r,60));
    check(!document.getElementById('postPhotoRow').classList.contains('has-photo'),'the cleared photo kept the frame');
    check(document.documentElement.scrollWidth<=innerWidth,'the composer overflows at this width');
    out.passed=true; return out;
  } finally {
    state.demo=saved.demo; window.CS.user=saved.user; window.CS.league=saved.league; window.CS.settings=saved.settings;
    state.structure=saved.structure; state.capExact=saved.capExact; state.phase=saved.phase;
    if(window.sb){ window.sb.rpc=saved.rpc; window.sb.from=saved.from; }
    window.scanFlag=saved.scan; window.qaEvent=saved.qa;
    try{ setPostPhoto(saved.photo||null); }catch(_){}
  }
})()
