/* D360 · a round without a photograph is a compact scorecard, on the desk.
   Five labelled fixture rows, none of them an account's: the reference round
   (an 89, 2.0 over the playing HCP), a long course name, a round with no
   handicap context, a round the board cache knows the consequence of, and a
   round with a photograph — which must keep its own presentation.

   Serve this checkout, open `/?cs_home_state=round_evening&exit` so the desk
   lands on Home without a session, evaluate with web-verify.mjs. Prefix the
   script with `document.documentElement.setAttribute('data-theme','light');`
   for the paper capture. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const until=(f,ms=6000)=>new Promise((res,rej)=>{ const t=Date.now(); (function tick(){ const v=f(); if(v) return res(v); if(Date.now()-t>ms) return rej(new Error('timeout: '+f)); setTimeout(tick,60); })(); });
  await until(()=>document.getElementById('homeFeed'));
  /* the desk lands on Home for the capture — the hatch does this itself a
     second later; doing it here means the capture never races it */
  try{ enterApp(); switchView('home'); }catch(_){}
  document.querySelectorAll('.onboard').forEach(d=>d.remove());
  const out={};

  /* a drawn photograph — a sky, a horizon, a ground mass; no place */
  const photo=(()=>{ const cv=document.createElement('canvas'); cv.width=900; cv.height=600; const x=cv.getContext('2d');
    const g=x.createLinearGradient(0,0,0,340); g.addColorStop(0,'#DCDCDC'); g.addColorStop(1,'#9E9E9E');
    x.fillStyle=g; x.fillRect(0,0,900,340); x.fillStyle='#575757'; x.fillRect(0,340,900,260);
    x.fillStyle='#767676'; x.beginPath(); x.ellipse(260,330,420,120,0,0,Math.PI*2); x.fill(); return cv.toDataURL('image/png'); })();

  const today=isoOf(new Date());
  const ago=n=>{ const d=new Date(); d.setDate(d.getDate()-n); return isoOf(d); };
  const row=(o)=>Object.assign({ round_id:crypto.randomUUID(), profile_id:crypto.randomUUID(), marker:'saguaro', handle:'fixture',
    played_on:ago(2), created_at:new Date().toISOString(), is_pr:false, is_first:false, is_sub80:false, is_me:false, photo_path:null, photo_url:null }, o);
  const rows=[
    row({ golfer:'FIXTURE · Sam Ridley', gross:89, pvi:-2.0, course:'UNM Championship Course', is_me:true }),
    row({ golfer:'FIXTURE · Priya Anand', gross:92, pvi:1.4, course:'The Championship Course at the University of New Mexico — North Loop' }),
    row({ golfer:'FIXTURE · Marcus Lee', gross:84, pvi:null, course:'Papago' }),
    row({ golfer:'FIXTURE · Dana Okafor', gross:79, pvi:3.1, course:'Aguila', played_on:ago(4) }),
    row({ golfer:'FIXTURE · Galen Marr', gross:81, pvi:0.2, course:'Encanto', photo_url:photo, played_on:ago(1) }),
  ];
  /* the board cache already knows the fourth round's consequence */
  window.roundCache=window.roundCache||{};
  window.roundCache[rows[3].round_id]={ id:rows[3].round_id, points:9, month_rank:2 };

  /* every fixture round has its one post, so the reactions have somewhere to live */
  window.homeRx={ post:Object.fromEntries(rows.map(r=>[r.round_id,{ post_id:'p-'+r.round_id }])), kud:{}, names:{}, myPid:rows[0].profile_id };
  const saved={ rows:window.homeFeedRows, posts:window.homePosts, demo:state.demo, cache:window.roundCache };
  state.demo=false; window.homeFeedRows=rows; window.homePosts=[];
  renderHomeFeed();
  const box=document.getElementById('homeFeed');
  const cards=[...box.querySelectorAll('[data-hfr]')];
  check(cards.length===5,'five fixture rows did not render: '+cards.length);
  const at=i=>box.querySelector(`[data-hfr="${i}"]`);

  /* ── the record: identity row, title, labelled figure, one story, a foot ── */
  const ref=at(0);
  check(ref.classList.contains('hfrecord'),'the reference round is not a record');
  check(ref.querySelector('.hfr-id .hfperson') && ref.querySelector('.hfr-who').textContent.includes('You'),'no quiet identity row');
  check(ref.querySelector('.hfr-title .cs-name').textContent==='UNM Championship Course','the course is not the title');
  check(ref.querySelector('.hfr-gross .cs-fig-l').textContent.trim()==='89','the gross is not the figure');
  check(ref.querySelector('.hfr-gross .cs-agate-s').textContent==='GROSS','the figure is not labelled');
  check(ref.querySelectorAll('.hfr-story').length===1 && ref.querySelector('.hfr-story').textContent==='2.0 over your playing HCP.','the story is not the handicap context: '+JSON.stringify(ref.querySelector('.hfr-story')?.textContent));
  check(ref.querySelector('.hfr-go') && ref.getAttribute('role')==='button','no route into the receipt');
  check(ref.querySelector('.hfr-foot [data-hreact]'),'no compact reactions in the foot');
  check(ref.querySelector('.hfr-topo'),'no contour behind the title');
  check(!ref.querySelector('img'),'the record grew a picture it does not have');

  /* the one story — the competition's consequence when the client has it */
  check(at(3).querySelector('.hfr-story').textContent==='9 pts · counting #2 this month','the cached consequence did not become the story: '+at(3).querySelector('.hfr-story')?.textContent);
  check(!at(3).textContent.includes('beat their'),'two stories on one round');
  /* no handicap context — the record stands on course and gross alone */
  check(!at(2).querySelector('.hfr-story'),'a round with no context invented one');
  check(at(2).querySelector('.hfr-gross .cs-fig-l').textContent.trim()==='84','the gross went with the missing context');
  /* the long name wraps inside the card and never leaves it */
  const long=at(1), lt=long.querySelector('.hfr-title');
  check(lt.getBoundingClientRect().right<=long.getBoundingClientRect().right+1,'the long course name escaped the card');
  check(document.documentElement.scrollWidth<=innerWidth,'horizontal overflow');
  /* the photograph keeps its own presentation */
  check(at(4).classList.contains('hfstory') && at(4).querySelector('img.hsbg'),'the photo round lost its presentation');

  /* ── colour: no decorative ember, paper readable ───────────────────────── */
  const cs=getComputedStyle(document.documentElement);
  const brand=cs.getPropertyValue('--brand').trim().toUpperCase();
  const hex=c=>{ const m=c.match(/\d+/g); return m ? '#'+m.slice(0,3).map(n=>(+n).toString(16).padStart(2,'0')).join('').toUpperCase() : c; };
  for(const el of ref.querySelectorAll('*')){ const st=getComputedStyle(el);
    check(hex(st.color)!==brand && hex(st.backgroundColor)!==brand && hex(st.borderTopColor)!==brand,'decorative ember on the record: '+el.className); }
  const lum=c=>{ const m=c.match(/\d+/g).slice(0,3).map(n=>{ n=n/255; return n<=.03928?n/12.92:Math.pow((n+.055)/1.055,2.4); }); return .2126*m[0]+.7152*m[1]+.0722*m[2]; };
  const contrast=(a,b)=>{ const l1=lum(a), l2=lum(b); return (Math.max(l1,l2)+.05)/(Math.min(l1,l2)+.05); };
  const ground=getComputedStyle(document.body).backgroundColor;
  const storyC=contrast(getComputedStyle(ref.querySelector('.hfr-story')).color, ground);
  const figC=contrast(getComputedStyle(ref.querySelector('.hfr-gross .cs-fig-l')).color, ground);
  check(storyC>=4.5 && figC>=4.5,'the record is not readable on this ground: story '+storyC.toFixed(2)+' figure '+figC.toFixed(2));
  out.theme=document.documentElement.getAttribute('data-theme')||'dark';
  out.contrast={ story:+storyC.toFixed(2), figure:+figC.toFixed(2) };

  /* ── compact: the record is shorter than the tall treatment it replaces ── */
  out.heights=cards.map(c=>Math.round(c.getBoundingClientRect().height));
  /* measured before this composition, same fixtures, 390 wide: 204 · 239 · 205 */
  check(out.heights[0]<=(innerWidth<360?215:190),'the record is still tall: '+out.heights[0]);

  /* ── the routes ────────────────────────────────────────────────────────── */
  let opened=null; const realOpen=window.openRoundReceipt; window.openRoundReceipt=(r)=>{ opened=r; };
  ref.querySelector('.hfr-title').click();
  check(opened && (opened===rows[0] || opened.round_id===rows[0].round_id || opened===rows[0].round_id),'the title did not open the receipt');
  window.openRoundReceipt=realOpen;
  ref.querySelector('.hfr-foot [data-hreact]').click();
  check(ref.querySelectorAll('.hfr-foot [data-hrx]').length>=4,'the reactions did not open in the foot');

  out.passed=true;
  return JSON.stringify(out);
})()
