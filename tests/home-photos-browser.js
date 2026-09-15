/* D361 · each Home round owns its photograph, on the desk. Two adjacent photo
   rounds on labelled fixtures — drawn pictures, no account, nothing signed
   for real: the "signed URL" is a data URI the test mints, with a token that
   changes when the test re-signs, exactly as the real one does.

   Serve this checkout, open `/?cs_home_state=round_evening&exit`, evaluate
   with web-verify.mjs. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const until=(f,ms=6000)=>new Promise((res,rej)=>{ const t=Date.now(); (function tick(){ const v=f(); if(v) return res(v); if(Date.now()-t>ms) return rej(new Error('timeout: '+f)); setTimeout(tick,50); })(); });
  await until(()=>document.getElementById('homeFeed'));
  try{ enterApp(); switchView('home'); }catch(_){}
  document.querySelectorAll('.onboard').forEach(d=>d.remove());
  const out={};

  /* two drawn photographs, told apart by tone; a broken one for the miss */
  const draw=(tone)=>{ const cv=document.createElement('canvas'); cv.width=900; cv.height=600; const x=cv.getContext('2d');
    x.fillStyle=tone; x.fillRect(0,0,900,600); x.fillStyle='#4A4A4A'; x.beginPath(); x.ellipse(300,420,420,140,0,0,Math.PI*2); x.fill();
    return cv.toDataURL('image/png'); };
  const A=draw('#CFCFCF'), B=draw('#8A8A8A'), BAD='data:image/png;base64,AAAA';
  /* the "signature": the same bytes with a token after a fragment, so the URL
     string changes on a re-sign while the picture does not */
  const sign=(uri,tok)=>uri+'#t='+tok;

  const ago=n=>{ const d=new Date(); d.setDate(d.getDate()-n); return isoOf(d); };
  const row=(o)=>Object.assign({ round_id:crypto.randomUUID(), profile_id:crypto.randomUUID(), marker:'saguaro', handle:'fixture',
    played_on:ago(1), created_at:new Date().toISOString(), is_pr:false, is_first:false, is_sub80:false, is_me:false }, o);
  const rows=[
    row({ golfer:'FIXTURE · Galen Marr', gross:81, pvi:0.2, course:'Encanto', photo_path:'fixture/first.png' }),
    row({ golfer:'FIXTURE · Jade Okafor', gross:77, pvi:2.6, course:'Aguila', photo_path:'fixture/second.png' }),
  ];
  window.homeRx={ post:Object.fromEntries(rows.map(r=>[r.round_id,{ post_id:'p-'+r.round_id }])), kud:{}, names:{}, myPid:rows[0].profile_id };
  state.demo=false; window.homePosts=[];
  csSignedClear();

  /* a load: sign what the cache lacks, hand every row its URL */
  let token=0;
  const load=(uris)=>{
    rows.forEach((r,i)=>{ if(r.photo_path && !csSignedGet(r.photo_path)) csSignedPut(r.photo_path, sign(uris[i],++token), 3600);
      r.photo_url = r.photo_path ? csSignedGet(r.photo_path) : null; });
    homeFailedPhotos.clear();
    window.homeFeedRows=rows; renderHomeFeed();
  };
  const imgs=()=>[...document.querySelectorAll('#homeFeed img.hsbg')];
  const loaded=()=>imgs().filter(i=>i.complete && i.naturalWidth>0);

  /* ── 1 · both photographs up, together ─────────────────────────────────── */
  load([A,B]);
  await until(()=>loaded().length===2);
  check(imgs().length===2,'two photo rounds did not both render as photographs');
  const first=imgs()[0].getAttribute('src'), second=imgs()[1].getAttribute('src');
  check(first!==second,'the two rounds share a URL');
  out.bothUp=true;

  /* ── 2 · a refresh: the cache hands back the SAME URLs, nothing reloads ── */
  const signed=csSigned.size;
  load([A,B]);
  check(imgs()[0].getAttribute('src')===first && imgs()[1].getAttribute('src')===second,'a refresh minted new URLs for unexpired credentials');
  check(csSigned.size===signed,'a refresh re-signed a cached path');
  check(loaded().length===2,'a refresh took a picture down');
  out.refreshReusesURLs=true;

  /* ── 3 · a re-sign whose new URL misses: the last good picture stays ───── */
  csSignedForget('fixture/second.png');
  load([A,BAD]);
  await until(()=>imgs()[1] && imgs()[1].getAttribute('src')===second, 4000);
  check(imgs().length===2 && loaded().length===2,'a transient miss on refresh removed the second photograph');
  check(imgs()[0].getAttribute('src')===first,'the first was touched by the second\'s miss');
  out.transientKeepsLastGood=true;

  /* ── 4 · a miss with no picture ever seen: the record, not an empty panel ─ */
  csSignedClear();
  rows[1].photo_path='fixture/third.png';
  load([A,BAD]);
  await until(()=>document.querySelector('#homeFeed [data-hfr="1"].hfrecord'), 4000);
  check(imgs().length===1 && loaded().length===1,'the first photograph did not survive the second\'s failure');
  out.missWithoutPriorIsRecord=true;

  /* ── 5 · removal: no attachment → the record; the other untouched ──────── */
  rows[1].photo_path=null; rows[1].photo_url=null;
  load([A,null]);
  check(document.querySelector('#homeFeed [data-hfr="1"].hfrecord') && !document.querySelector('#homeFeed [data-hfr="1"] img'),'a removed attachment did not become the record');
  check(loaded().length===1 && imgs()[0].getAttribute('src')===csSignedGet('fixture/first.png'),'removing the second touched the first');
  out.removalIsRecord=true;

  /* ── 5b · a credential this load could not get: the last good picture stays ─ */
  csSignedClear();
  rows[1].photo_path='fixture/fourth.png'; rows[1].photo_url=null;
  load([A,B]);
  await until(()=>loaded().length===2);
  /* the next load cannot sign the second (transient): the cache is cold for it,
     nothing is put — but the last good URL still carries the picture */
  csSignedForget('fixture/fourth.png');
  rows.forEach(r=>{ r.photo_url = csSignedGet(r.photo_path) || csLastGoodPhoto.get(r.photo_path) || null; });
  window.homeFeedRows=rows; renderHomeFeed();
  check(imgs().length===2 && loaded().length===2,'a transient signing failure took a picture down');
  out.unsignableKeepsLastGood=true;
  /* an account change while a signing call is in flight: the epoch moves */
  const e0=csSignedEpoch; csSignedClear(); check(csSignedEpoch===e0+1,'sign-out did not move the signing epoch');

  /* ── 6 · sign-out: no credential survives ──────────────────────────────── */
  csSignedClear();
  check(csSigned.size===0 && !csSignedGet('fixture/first.png'),'a credential survived sign-out');
  out.signOutClears=true;

  /* the score and course never wait for the picture: the band carries them in markup */
  const band=document.querySelector('#homeFeed [data-hfr="0"]');
  check(/81/.test(band.textContent) && /Encanto/i.test(band.textContent),'the band does not carry score and course');
  check(document.documentElement.scrollWidth<=innerWidth,'horizontal overflow');
  out.passed=true;
  return JSON.stringify(out);
})()
