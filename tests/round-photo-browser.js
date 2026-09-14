/* The round photograph, on the desk · both states, on a deterministic fixture.
   Owner ruling 2026-09-14: "use deterministic fixtures, including a round that
   actually has a photo. Verify opting out removes it from the output and
   opting back in restores it. Keep a separate no-photo case."

   The photograph here is DRAWN, not an account's — a flat bright field with
   two coloured bands, so "the photo is in the output" is a measurement and
   not a look. Nothing is uploaded, nothing is posted, nothing is shared: the
   share sheet is stubbed and every canvas stays in memory.

   Serve this checkout and evaluate with web-verify.mjs. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const out={};

  /* ── the fixture photograph ────────────────────────────────────────────── */
  const photo = await (async()=>{
    const cv=document.createElement('canvas'); cv.width=1200; cv.height=800;
    const x=cv.getContext('2d');
    x.fillStyle='#FFFFFF'; x.fillRect(0,0,1200,800);
    x.fillStyle='#E8622C'; x.fillRect(0,300,1200,120);
    x.fillStyle='#5FA271'; x.fillRect(0,540,1200,120);
    return await new Promise(res=>cv.toBlob(res,'image/png'));
  })();
  check(photo && photo.size>0,'the fixture photograph did not render');

  const fixture={ name:'FIXTURE · Sam Ridley', marker:'saguaro', gross:84, pvi:0.2, points:7,
                  course:'FIXTURE GC', date:new Date(2026,8,11), league:'FIXTURE LEAGUE', badge:null };

  /* ── 1 · the OUTPUT, read off the canvas ───────────────────────────────── */
  /* the card's interior, averaged. Without a photograph the ground is one flat
     charcoal; with one it is that charcoal lifted by whatever came through the
     wash — which is the whole reason the backdrop exists. */
  const interior=cv=>{
    const d=cv.getContext('2d').getImageData(120,420,840,500).data;
    let sum=0,n=0; for(let i=0;i<d.length;i+=4){ sum+=(d[i]+d[i+1]+d[i+2])/3; n++; }
    return sum/n;
  };
  const bare=interior(drawRecapCard(Object.assign({},fixture)));
  const img=await photoDrawable(photo);
  const lit=interior(drawRecapCard(Object.assign({},fixture,{ _img:img })));
  check(lit>bare+8,'the photograph is not in the card: bare '+bare.toFixed(1)+' vs with-photo '+lit.toFixed(1));
  out.cardGround={ noPhoto:+bare.toFixed(1), withPhoto:+lit.toFixed(1) };

  /* ── 2 · the ceremony's control ────────────────────────────────────────── */
  const opt=document.getElementById('finPhoto');
  check(!!opt,'the ceremony has no photograph opt-out');
  check(!!document.getElementById('finShare'),'the ceremony has no share');

  /* every card the share path draws, and whether it was handed the photograph */
  const drawn=[];
  const realDraw=window.drawRecapCard;
  window.drawRecapCard=d=>{ drawn.push(!!d._img); return realDraw(d); };
  /* the artifact never leaves: canShare says yes so the download branch is not
     taken, and share itself records instead of opening anything */
  const shared=[];
  const realCanShare=navigator.canShare, realShare=navigator.share;
  Object.defineProperty(navigator,'canShare',{ value:()=>true, configurable:true });
  Object.defineProperty(navigator,'share',{ value:async o=>{ shared.push(o); }, configurable:true });
  const settle=()=>new Promise(r=>setTimeout(r,320));
  const restore=()=>{
    window.drawRecapCard=realDraw;
    Object.defineProperty(navigator,'canShare',{ value:realCanShare, configurable:true });
    Object.defineProperty(navigator,'share',{ value:realShare, configurable:true });
  };

  try{
    /* a round that actually has a photograph */
    finishCeremony(Object.assign({}, fixture, { vs:0.2, inLeague:true, squad:'FIXTURE',
      leagueName:'FIXTURE LEAGUE', photo }));
    check(!opt.hidden,'a round with a photograph does not offer the opt-out');
    check(opt.getAttribute('aria-pressed')==='true','the photograph is not included by default');
    check(opt.textContent.trim()===CS_PHOTO.include,
      'the opt-out does not read the shared sentence: '+JSON.stringify(opt.textContent));

    document.getElementById('finShare').click(); await settle();
    check(drawn.length===1 && drawn[0]===true,'the shared card left the photograph out: '+JSON.stringify(drawn));

    /* opting out removes it from the output */
    opt.click();
    check(opt.getAttribute('aria-pressed')==='false','the opt-out did not take');
    document.getElementById('finShare').click(); await settle();
    check(drawn.length===2 && drawn[1]===false,'opting out did not remove the photograph: '+JSON.stringify(drawn));

    /* and opting back in restores it */
    opt.click();
    check(opt.getAttribute('aria-pressed')==='true','the opt-out did not come back on');
    document.getElementById('finShare').click(); await settle();
    check(drawn.length===3 && drawn[2]===true,'opting back in did not restore the photograph: '+JSON.stringify(drawn));
    out.sharedCards=drawn.slice();
    check(shared.length===3,'the share path did not run three times: '+shared.length);

    /* ── 3 · the separate no-photo case ──────────────────────────────────── */
    finishCeremony(Object.assign({}, fixture, { vs:0.2, inLeague:true, squad:'FIXTURE',
      leagueName:'FIXTURE LEAGUE', photo:null }));
    check(opt.hidden,'a round with no photograph still offers the opt-out');
    document.getElementById('finShare').click(); await settle();
    check(drawn.length===4 && drawn[3]===false,'the no-photo card carried something: '+JSON.stringify(drawn));
    out.noPhotoCase='no control, no photograph in the card';
  } finally {
    restore();
    if(typeof finishDismiss==='function') finishDismiss();
  }

  /* the round's own attachment is never touched by a share choice (§16) */
  check(!/clear_round_photo|set_round_photo/.test(String(shareRecapCard)),
    'the share path writes to the round');

  out.ok=true;
  return JSON.stringify(out);
})()
