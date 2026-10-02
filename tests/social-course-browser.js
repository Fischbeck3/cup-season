/* D391 + D405 · the web half of the connected blend, walked in a real browser
   against a STUBBED rpc layer. Every name below is a labelled fixture, none an
   account's.

   Serve this checkout, open `/?cs_home_state=round_evening&exit`, and evaluate
   with web-verify.mjs:
     node tools/web-verify.mjs --url 'http://127.0.0.1:8791/?cs_home_state=round_evening&exit' \
       --widths 1440,390 --eval "$(cat tests/social-course-browser.js)"

   Covers: the Home wire's two doors, and D405's conversation IN LINE — the door
   as a real toggle (aria-expanded, aria-controls, its two labels), the newest
   three flat and oldest first under "Earlier comments (N)", the composer that
   names the round, a comment that lands in line without leaving Home, one
   thread open at a time, a repaint that keeps the thread, the draft, the focus
   and the caret (with and without moveBefore), a comment removed in line, a
   thread longer than the server's page, the newest comment under a closed
   round (escaped, and absent on a server that sends no `latest`), an open
   thread that reads again with Home but never under the golfer's hands; the
   board's door in line, each post on its own, re-read by a board refresh;
   the receipt's conversation (escaping, reply target, a FAILED send
   that keeps the draft and its key, the retry that lands, the page and its head
   naming whose round it is, Notify me about: its three states, the owner's two
   choices, a failed write that reverts); the inbox (badge, the sentences that
   name the round and both older-server sentences, open-at-comment, mark read);
   the digest counting a round-thread comment; the person card when the buddy
   list cannot be read; the course's circle (tie, filters, the honest scope
   label); and deploy skew (no bell, no conversation, no doors). Section 1d
   pins what a review of the build found: an answer that began before a comment
   (or a choice) landed never redraws the thread over it; a reply target chosen
   in one view is shown, and sent, by every view; a refused send says so even
   when the thread was redrawn while it was on the way, or folded; the compact
   board's column does not run off the side; the full board stays at the bottom
   under a digest; a thread on a board that is not showing is not read; and an
   older server's golfer is not told they are following. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const until=(f,ms=6000)=>new Promise((res,rej)=>{ const t=Date.now(); (function tick(){ let v; try{ v=f(); }catch(_){} if(v) return res(v); if(Date.now()-t>ms) return rej(new Error('timeout: '+f)); setTimeout(tick,40); })(); });
  const tick=()=>new Promise(r=>setTimeout(r,30));
  await until(()=>document.getElementById('homeFeed'));
  try{ enterApp(); switchView('home'); }catch(_){}
  document.querySelectorAll('.onboard').forEach(d=>d.remove());
  const out={};

  const ME='00000000-0000-4000-8000-0000000000a1', THEO='00000000-0000-4000-8000-0000000000a2', MARA='00000000-0000-4000-8000-0000000000a3', BLAKE='00000000-0000-4000-8000-0000000000a4';
  const R1='10000000-0000-4000-8000-000000000001', R2='10000000-0000-4000-8000-000000000002', R3='10000000-0000-4000-8000-000000000003';
  const C1='20000000-0000-4000-8000-000000000001', C2='20000000-0000-4000-8000-000000000002', C9='20000000-0000-4000-8000-000000000009';
  const D=n=>'21000000-0000-4000-8000-00000000000'+n;
  const N1='30000000-0000-4000-8000-000000000001', N=n=>'30000000-0000-4000-8000-00000000000'+n;
  const person=(id,name)=>({ id, name, marker:'saguaro', handle:null });
  const now=Date.now(), iso=ms=>new Date(now-ms).toISOString();
  const today=(()=>{ const d=new Date(); return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`; })();
  const MID='·';

  /* ── the threads, one per posted round: Theo's 79 (three comments), my 84
     (five, so the newest three sit under "Earlier comments (2)"), Blake's 91
     (none yet) ── */
  const cm=(id, rid, who, body, ago, extra)=>Object.assign({ id, round_id:rid, parent_id:null, root_id:null, reply_to:null, author:who,
    body, created_at:iso(ago), origin:'round', is_mine:who.id===ME, can_reply:true }, extra||{});
  const T={
    [R1]:{ owner:person(THEO,'Theo Fixture'), is_mine:false, gross:79,
           course:{ api_course_id:'fx-1', name:'FIXTURE Oaks', label:'FIXTURE Oaks · White', tee_name:'White', tee_key:'white@70.1/124' },
           thread:{ state:'none', following:false, muted:false },
           comments:[
             cm(C1, R1, person(THEO,'Theo Fixture'), 'Same ball? <b>witness</b> & "quotes"', 7200e3),
             cm(C2, R1, person(MARA,'Mara Fixture'), 'Caught the left edge.', 720e3, { parent_id:C1, root_id:C1, reply_to:{ id:C1, name:'Theo Fixture' } }),
             cm(C9, R1, person(MARA,'Mara Fixture'), 'League chatter', 600e3, { origin:'board', can_reply:false }) ] },
    [R2]:{ owner:person(ME,'You Fixture'), is_mine:true, gross:84,
           course:{ api_course_id:null, name:'FIXTURE Pines', label:'FIXTURE Pines', tee_name:null, tee_key:null },
           thread:{ state:'none', following:false, muted:false },
           comments:[
             cm(D(1), R2, person(THEO,'Theo Fixture'), 'Front nine was a clinic.', 9000e3),
             cm(D(2), R2, person(MARA,'Mara Fixture'), 'Then the back nine happened.', 8000e3),
             cm(D(3), R2, person(THEO,'Theo Fixture'), 'Three putts on 16.', 7000e3),
             cm(D(4), R2, person(MARA,'Mara Fixture'), 'It was four.', 6000e3, { parent_id:D(3), root_id:D(3), reply_to:{ id:D(3), name:'Theo Fixture' } }),
             cm(D(5), R2, person(BLAKE,'Blake Fixture'), 'Did the putt on 18 drop?', 5000e3) ] },
    [R3]:{ owner:person(BLAKE,'Blake Fixture'), is_mine:false, gross:91,
           course:{ api_course_id:null, name:'FIXTURE Dunes', label:'FIXTURE Dunes', tee_name:null, tee_key:null },
           thread:{ state:'none', following:false, muted:false }, comments:[] },
  };
  /* `latest` arrives only from a server with D405 */
  let latestOn=true;
  const latestOf=rid=>{ const l=T[rid].comments.slice().sort((a,b)=>a.created_at<b.created_at?-1:1).at(-1);
    return l ? { id:l.id, author:l.author, body:Array.from(l.body).slice(0,140).join(''), created_at:l.created_at } : null; };

  /* ── the stub: rpc by name, everything else a harmless chain ── */
  const calls=[]; const fail={}; let skew=false;
  /* something that happens on the server just before the NEXT thread read is evaluated (another golfer's comment) */
  let onThread=null;
  let notes=[
    { id:N1, kind:'reply', created_at:iso(720e3), read:false, read_at:null, actor:person(MARA,'Mara Fixture'),
      round_id:R1, comment_id:C2, excerpt:'Caught the left edge.', course_name:'FIXTURE Oaks', round_owner_name:'Theo Fixture',
      link:{ kind:'round_comment', round_id:R1, comment_id:C2, web:`/?round=${R1}&comment=${C2}` } },   /* an older server: no round_is_mine */
    { id:N(2), kind:'reply', created_at:iso(1800e3), read:true, read_at:iso(1), actor:person(MARA,'Mara Fixture'),
      round_id:R2, comment_id:D(4), excerpt:'It was four.', course_name:'FIXTURE Pines', round_owner_name:'You Fixture', round_is_mine:true, link:{ kind:'round_comment', round_id:R2, comment_id:D(4) } },
    { id:N(3), kind:'reply', created_at:iso(2400e3), read:true, read_at:iso(1), actor:person(BLAKE,'Blake Fixture'),
      round_id:R1, comment_id:C1, excerpt:'Same ball?', course_name:'FIXTURE Oaks', round_owner_name:'Theo Fixture', round_is_mine:false, link:{ kind:'round_comment', round_id:R1, comment_id:C1 } },
    { id:N(4), kind:'followed', created_at:iso(3000e3), read:true, read_at:iso(1), actor:person(BLAKE,'Blake Fixture'),
      round_id:R1, comment_id:C1, excerpt:'Same ball?', course_name:'FIXTURE Oaks', round_owner_name:'Theo Fixture', round_is_mine:false, link:{ kind:'round_comment', round_id:R1, comment_id:C1 } },
    { id:N(5), kind:'followed', created_at:iso(3600e3), read:true, read_at:iso(1), actor:person(BLAKE,'Blake Fixture'),
      round_id:R1, comment_id:C1, excerpt:'Same ball?', course_name:'FIXTURE Oaks', link:{ kind:'round_comment', round_id:R1, comment_id:C1 } },   /* an older server: no owner's name */
  ];
  /* the digest's one inbox read (p_limit 50): only the first is news about MY round */
  let digestNotes=[
    { id:N(6), kind:'own_round', created_at:iso(3600e3), read:false, actor:person(THEO,'Theo Fixture'), round_id:R2, comment_id:D(3), round_owner_name:'You Fixture', round_is_mine:true },
    { id:N(7), kind:'own_round', created_at:iso(1800e3), read:false, actor:person(ME,'You Fixture'), round_id:R2, comment_id:D(5), round_owner_name:'You Fixture', round_is_mine:true },
    { id:N(8), kind:'reply', created_at:iso(1800e3), read:false, actor:person(MARA,'Mara Fixture'), round_id:R1, comment_id:C2, round_owner_name:'Theo Fixture', round_is_mine:false },
    { id:N(9), kind:'own_round', created_at:iso(5*3600e3), read:true, actor:person(BLAKE,'Blake Fixture'), round_id:R2, comment_id:D(1), round_owner_name:'You Fixture', round_is_mine:true },
  ];
  let prefs={ own_round:true, replies:true, followed:true };
  let friends=[];
  const coursePage=(tee,holes)=> holes===9 ? { ok:true, course:{ api_course_id:'fx-1', name:'FIXTURE Oaks' },
      scope:{ key:'circle', label:'Your circle', best_label:'Your circle best', note:'Not an official course record.' },
      selection:{ tee_key:'white@70.1/124', tee_name:'White', holes:9 }, tees:[{ key:'white@70.1/124', name:'White', gender:'male', rating:70.1, slope:124, rounds:2 }],
      holes_options:[{ holes:18, rounds:4 },{ holes:9, rounds:1 }], unknown_tee_rounds:0, best:null, best_unavailable:'nine_side_unrecorded', my_best:null, people_total:0, people:[] }
    : ({ ok:true, best_unavailable:null,
    course:{ api_course_id:'fx-1', name:'FIXTURE Oaks', city:'Testville', state:'CA', country:'USA' },
    scope:{ key:'circle', label:'Your circle', best_label:'Your circle best', note:'From your rounds, your friends’ rounds and the rounds of the golfers in your seasons, Ryders and Majors. Not an official course record.' },
    selection:{ tee_key: tee||'white@70.1/124', tee_name: tee==='blue@72.3/131'?'Blue':'White', holes: holes||18 },
    tees:[{ key:'white@70.1/124', name:'White', gender:'male', rating:70.1, slope:124, rounds:4 },{ key:'blue@72.3/131', name:'Blue', gender:'male', rating:72.3, slope:131, rounds:1 }],
    holes_options:[{ holes:18, rounds:4 }], unknown_tee_rounds:1,
    best: tee==='blue@72.3/131' ? { gross:68, tied:false, eligible_rounds:1, holders:[{ round_id:R1, person:person(MARA,'Mara Fixture'), played_on:'2026-09-01' }] }
      : { gross:70, tied:true, eligible_rounds:4, holders:[{ round_id:R1, person:person(ME,'You Fixture'), played_on:'2025-08-01' },{ round_id:R1, person:person(THEO,'Theo Fixture'), played_on:'2025-11-01' }] },
    my_best:{ gross:70, round_id:R1, played_on:'2025-08-01', rounds:3 },
    people_total:2,
    people:[{ person:person(THEO,'Theo Fixture'), relation:'friend', rounds_total:1, latest_played_on:'2025-11-01',
              best_in_selection:{ gross:70, round_id:R1, played_on:'2025-11-01' },
              rounds:[{ round_id:R1, played_on:'2025-11-01', gross:70, holes:18, tee_key:'white@70.1/124', tee_name:'White', has_photo:false, in_selection:true }] },
            { person:person(MARA,'Mara Fixture'), relation:'league', rounds_total:2, latest_played_on:'2026-09-01', best_in_selection:null,
              rounds:[{ round_id:R1, played_on:'2026-09-01', gross:81, holes:18, tee_key:null, tee_name:null, has_photo:false, in_selection:false }] }] });
  const GONE='10000000-0000-4000-8000-0000000000ee';
  const older={ id:'30000000-0000-4000-8000-0000000000aa', kind:'own_round', created_at:iso(4000e3), read:true, read_at:iso(1), actor:person(THEO,'Theo Fixture'),
                round_id:R2, comment_id:D(1), excerpt:'Front nine was a clinic.', course_name:'FIXTURE Pines', round_owner_name:'You Fixture', round_is_mine:true, link:{ kind:'round_comment', round_id:R2, comment_id:D(1) } };
  const SKEW={ code:'PGRST202', message:'Could not find the function public.x in the schema cache' };
  const rpc=async(name,args)=>{
    calls.push([name, JSON.parse(JSON.stringify(args||{}))]);
    await tick();
    const D391=['posted_round_thread','add_posted_round_comment','set_round_thread_state','notification_badge','my_notifications',
                'mark_notifications_read','social_notify_prefs','set_social_notify_prefs','course_page','posted_rounds_social','report_content','remove_posted_round_comment'];
    if(skew && D391.includes(name)) return { data:null, error:SKEW };
    if(fail[name]){ const e=fail[name]; delete fail[name]; return { data:null, error:e }; }
    switch(name){
      case 'posted_rounds_social': return { data:{ items:(args.p_rounds||[]).filter(id=>T[id]).map(id=>Object.assign({ round_id:id, comment_count:T[id].comments.length+(T[id].extra||0), can_comment:true, thread_state:T[id].thread.state,
        course: id===R1 ? { api_course_id:'fx-1', name:'FIXTURE Oaks', circle_golfers:3, faces:[person(THEO,'Theo Fixture'), person(MARA,'Mara Fixture')] } : null },
        latestOn ? { latest:latestOf(id) } : {})) }, error:null };
      case 'posted_round_thread': { if(onThread){ const f=onThread; onThread=null; f(); }
        const t=T[args.p_round];
        if(!t) return { data:{ ok:false, reason:'not_visible' }, error:null };
        /* `extra` · comments past the newest page: the server's count holds them, the page does not */
        return { data:{ ok:true, page:{ newest:t.comments.length, limit:200, truncated:!!t.extra, focus_id:args.p_focus||null },
          round:{ id:args.p_round, owner:t.owner, is_mine:t.is_mine, gross:t.gross, holes:18, played_on:'2026-09-20', course:t.course, photo_path:null },
          can_comment:true, comment_block_reason:null, thread:Object.assign({}, t.thread), notify_prefs:Object.assign({}, prefs), count:t.comments.length+(t.extra||0), comments:t.comments.slice() }, error:null }; }
      case 'add_posted_round_comment': { const t=T[args.p_round];
        const parent=args.p_parent ? t.comments.find(c=>c.id===args.p_parent) : null;
        const c={ id:crypto.randomUUID(), round_id:args.p_round, parent_id:args.p_parent||null, root_id:parent ? (parent.root_id||parent.id) : null,
          reply_to: parent ? { id:parent.id, name:parent.author.name } : null, author:person(ME,'You Fixture'),
          body:args.p_body, created_at:new Date().toISOString(), origin:'round', is_mine:true, can_reply:true };
        t.comments=t.comments.concat([c]);
        /* D405 · the server records `following` for a commenter with no setting who does not own the round
           (a server without D405 records nothing, and sends no `latest` either) */
        if(latestOn && t.thread.state==='none' && !t.is_mine) t.thread={ state:'following', following:true, muted:false };
        return { data:{ ok:true, replayed:false, comment:c, count:t.comments.length }, error:null }; }
      case 'set_round_thread_state': T[args.p_round].thread={ state:args.p_state, following:args.p_state==='following', muted:args.p_state==='muted' };
        return { data:{ ok:true, state:args.p_state }, error:null };
      case 'remove_posted_round_comment': Object.values(T).forEach(t=>{ t.comments=t.comments.filter(c=>c.id!==args.p_comment); });
        return { data:{ ok:true }, error:null };
      case 'notification_badge': return { data:{ unread:notes.filter(n=>!n.read).length }, error:null };
      case 'my_notifications': return args.p_limit===50
          ? { data:{ ok:true, unread:0, items:digestNotes, next_before:null, next_before_id:null }, error:null }
        : args.p_before
          ? { data:{ ok:true, unread:notes.filter(n=>!n.read).length, items:[older], next_before:null, next_before_id:null }, error:null }
          : { data:{ ok:true, unread:notes.filter(n=>!n.read).length, items:notes, next_before:notes[0].created_at, next_before_id:N1 }, error:null };
      case 'mark_notifications_read': notes.forEach(n=>{ if(args.p_all || (args.p_ids||[]).includes(n.id)) n.read=true; }); return { data:{ ok:true, unread:notes.filter(n=>!n.read).length }, error:null };
      case 'social_notify_prefs': return { data:prefs, error:null };
      case 'set_social_notify_prefs': return { data:prefs, error:null };
      case 'course_page': return { data:coursePage(args.p_tee, args.p_holes), error:null };
      case 'tour_card': return { data:{ visible:true, profile:{ id:args.p_profile, display_name:'Theo Fixture', handle:'theofixture', marker:'saguaro', is_me:false },
        career:{ rounds:3 }, trophies:[], recent:[], courses:[], shared_courses:[] }, error:null };
      case 'my_friends': return { data:friends, error:null };
      default: return { data:null, error:{ message:'not in this fixture' } };
    }
  };
  const chain=new Proxy(function(){}, { get:(t,k)=> k==='then' ? (res=>res({ data:null, error:null })) : chain, apply:()=>chain });
  const saved={ sb:window.sb, user:window.CS && window.CS.user, demo:state.demo, rows:window.homeFeedRows, feed:feed.slice(), dgAsOf:window.dgAsOf };
  const sbHadRpc=!!saved.sb && Object.prototype.hasOwnProperty.call(saved.sb, 'rpc'), sbRpc=saved.sb && saved.sb.rpc;
  /* a late answer: `delay.<rpc>` holds the NEXT answer of that rpc back that many ms (its effect on the
     fixture is immediate, as a server's is, so a read's snapshot is taken when it is asked) */
  const delay={};
  const rpcD=async(name,args)=>{ const d=delay[name]; if(d!=null) delete delay[name]; const r=await rpc(name,args); if(d) await new Promise(z=>setTimeout(z,d)); return r; };
  window.sb=new Proxy({}, { get:(t,k)=> k==='rpc' ? rpcD : chain });
  window.CS=window.CS||{}; window.CS.user={ id:ME }; window.CS.profile=Object.assign({}, window.CS.profile||{}, { id:ME, display_name:'You Fixture', marker:'saguaro' });
  state.demo=false;
  const toasts=[]; const realToast=window.toast; window.toast=m=>{ toasts.push(m); };
  const sheetOpen=()=>document.getElementById('sheet').classList.contains('open');

  try{
    /* ── 1 · the Home wire's two doors ── */
    window.homeFeedRows=[
      { round_id:R1, profile_id:THEO, golfer:'Theo Fixture', marker:'saguaro', gross:79, pvi:1.2, course:'FIXTURE Oaks',
        played_on:today, created_at:iso(0), is_me:false, photo_path:null, photo_url:null },
      { round_id:R2, profile_id:ME, golfer:'You Fixture', marker:'saguaro', gross:84, pvi:-1.4, course:'FIXTURE Pines',
        played_on:today, created_at:iso(3600e3), is_me:true, photo_path:null, photo_url:null },
      { round_id:R3, profile_id:BLAKE, golfer:'Blake Fixture', marker:'saguaro', gross:91, pvi:-4.2, course:'FIXTURE Dunes',
        played_on:today, created_at:iso(7200e3), is_me:false, photo_path:null, photo_url:null }];
    window.csTalkSocial={};
    const okFetch=await csTalkFetch([R1,R2,R3]);
    check(okFetch,'posted_rounds_social did not answer');
    renderHomeFeed();
    const card=await until(()=>document.querySelector('#homeFeed [data-hfr="0"]'));
    const talkBtn=card.querySelector('[data-hftalk]'), courseBtn=card.querySelector('[data-hfcourse]');
    check(talkBtn && /3 comments, open the conversation/.test(talkBtn.getAttribute('aria-label')),'no labelled conversation door: '+(talkBtn&&talkBtn.getAttribute('aria-label')));
    check(courseBtn && courseBtn.textContent.includes('Theo and Mara have played here'),'no course door naming the circle: '+(courseBtn&&courseBtn.textContent));
    out.doors='ok';

    /* ── 1b · D405 · the conversation in line on Home ── */
    const doorOf=rid=>document.querySelector(`#homeFeed [data-hftalk="${rid}"]`);
    const cardOf=rid=>doorOf(rid) && doorOf(rid).closest('[data-hfr]');
    const lineOf=rid=>doorOf(rid) && document.getElementById(doorOf(rid).getAttribute('aria-controls'));
    const peekOf=rid=>cardOf(rid) && cardOf(rid).querySelector('[data-talk-peek]');
    const texts=el=>[...el.querySelectorAll('.cs-talk-c .cs-talk-text')].map(p=>p.textContent);
    /* the newest comment sits under a closed round, before any tap */
    check(peekOf(R1) && peekOf(R1).textContent==='Mara: League chatter' && peekOf(R1).querySelector('b').textContent==='Mara:','the newest comment is not under the round: '+(peekOf(R1)&&peekOf(R1).textContent));
    check(peekOf(R2) && peekOf(R2).textContent==='Blake: Did the putt on 18 drop?','the newest of five is not the one under the round');
    check(talkBtn.getAttribute('aria-expanded')==='false' && lineOf(R1) && lineOf(R1).hidden && card.contains(lineOf(R1)),'the closed door does not control a hidden thread under its own round');
    check(!peekOf(R3) && doorOf(R3).getAttribute('aria-label')==='Comment on this round' && doorOf(R3).getAttribute('aria-expanded')==='false','a round with no comments drew a preview, or lost its label');

    /* open: the thread is under the round, the door says so, nothing else opened */
    doorOf(R1).click();
    const line1=await until(()=>lineOf(R1) && lineOf(R1).querySelector('.cs-talk.is-inline .cs-talk-c') && lineOf(R1));
    check(doorOf(R1).getAttribute('aria-expanded')==='true' && doorOf(R1).getAttribute('aria-label')==='3 comments, hide the conversation','the door is not an open toggle: '+doorOf(R1).getAttribute('aria-label'));
    check(document.activeElement===doorOf(R1),'the door lost the focus it was pressed with');
    check(!sheetOpen() && cardOf(R1).contains(line1) && !line1.hidden,'the thread did not open in place under its round');
    check(!peekOf(R1),'the newest comment stayed under an open thread');
    check(calls.some(c=>c[0]==='posted_round_thread' && c[1].p_round===R1 && !c[1].p_focus),'the thread was not read');
    check(texts(line1).join('|')==='Same ball? <b>witness</b> & "quotes"|Caught the left edge.|League chatter' && !line1.querySelector('.cs-talk-text b'),'in line is not the three, oldest first, as text');
    check(!line1.querySelector('.is-reply') && line1.querySelectorAll('.cs-talk-c')[1].querySelector('.cs-talk-to').textContent==='To Theo','in line is not flat, or a reply lost its To');
    check(!line1.querySelector('[data-talk-earlier]'),'Earlier comments offered with nothing earlier');
    const ta1=line1.querySelector('textarea[data-talk-draft]');
    check(ta1 && ta1.placeholder==='Comment on Theo’s 79…','the composer does not name the round: '+(ta1&&ta1.placeholder));
    check(line1.querySelector(`label[for="${ta1.id}"]`).textContent==='Add a comment' && line1.querySelector('.cs-talk').getAttribute('aria-label')==='On Theo’s 79','the in-line thread or its field is unnamed');
    const sel1=line1.querySelector('select[data-talk-notify]');
    check(sel1 && sel1.value==='replies' && [...sel1.options].map(o=>o.value).join(',')==='every,replies,nothing','Notify me about is wrong in line: '+(sel1&&sel1.value));
    check(line1.querySelector('[data-talk-hint]').textContent==='You’ll be notified of replies to you.','the in-line hint is wrong');
    check(!line1.querySelector('[data-talk-follow],[data-talk-mute]') && !/\bFollow(ing)?\b|Mute conversation/.test(line1.textContent),'a Follow or a Mute survived in line');

    /* a tap inside the thread is not a tap on the round (the card opens the receipt) */
    line1.querySelector('.cs-talk-text').click();
    await tick();
    check(!sheetOpen(),'a tap in the thread opened the receipt');

    /* a repaint keeps the thread, the draft, the focus and the caret */
    ta1.focus(); ta1.value='Birdie on 7 or '; ta1.dispatchEvent(new Event('input')); ta1.setSelectionRange(7,7);
    renderHomeFeed();
    await csTalkFetch([R1,R2,R3]); renderHomeFeed();
    check(lineOf(R1)===line1 && line1.querySelector('textarea[data-talk-draft]')===ta1 && cardOf(R1).contains(line1),'a repaint replaced the open thread');
    check(document.activeElement===ta1 && ta1.selectionStart===7 && ta1.value==='Birdie on 7 or ','a repaint took the focus, the caret or the draft: '+(document.activeElement&&document.activeElement.tagName)+' '+ta1.selectionStart);
    check(doorOf(R1).getAttribute('aria-expanded')==='true','a repaint closed the door');
    /* ...and in a browser that cannot move an element without blurring it (no
       moveBefore: the fallback path), the focus and the caret are put back */
    const mb=Object.getOwnPropertyDescriptor(Element.prototype, 'moveBefore');
    if(mb) delete Element.prototype.moveBefore;
    try{
      ta1.focus(); ta1.setSelectionRange(3,3);
      renderHomeFeed();
      check(lineOf(R1)===line1 && document.activeElement===ta1 && ta1.selectionStart===3 && ta1.value==='Birdie on 7 or ','without moveBefore a repaint took the focus, the caret or the draft');
    } finally { if(mb) Object.defineProperty(Element.prototype, 'moveBefore', mb); }
    ta1.value=''; ta1.dispatchEvent(new Event('input'));

    /* one thread open at a time on Home */
    doorOf(R3).click();
    const line3=await until(()=>lineOf(R3) && lineOf(R3).querySelector('.cs-talk.is-inline textarea') && lineOf(R3));
    check(doorOf(R1).getAttribute('aria-expanded')==='false' && lineOf(R1).hidden && !lineOf(R1).querySelector('.cs-talk'),'opening a second thread left the first open on Home');
    check(peekOf(R1) && peekOf(R1).textContent==='Mara: League chatter','the closed thread did not give its newest comment back');
    check(line3.textContent.includes('The conversation is yours to start.') && line3.querySelector('textarea').placeholder==='Comment on Blake’s 91…','an empty thread does not invite the first comment on the named round');

    /* a comment lands in line at once, and Home stays Home */
    const ta3=line3.querySelector('textarea[data-talk-draft]');
    ta3.value='Birdie on 7 or bust'; ta3.dispatchEvent(new Event('input'));
    line3.querySelector('[data-talk-send]').click();
    const mine3=await until(()=>line3.querySelector('.cs-talk-c.is-target'));
    check(mine3.querySelector('.cs-talk-text').textContent==='Birdie on 7 or bust' && document.activeElement===mine3,'the comment did not land in line, or did not take the focus');
    check(!sheetOpen() && lineOf(R3)===line3 && !line3.hidden && cardOf(R3).contains(line3),'sending left Home, or closed the thread');
    check(line3.querySelector('textarea[data-talk-draft]').value==='','the draft survived a landed comment');
    check(doorOf(R3).getAttribute('aria-label')==='1 comment, hide the conversation','the door did not count the new comment: '+doorOf(R3).getAttribute('aria-label'));
    check(window.csTalkSocial[R3].comment_count===1 && window.csTalkSocial[R3].latest && window.csTalkSocial[R3].latest.body==='Birdie on 7 or bust','the doors’ row did not follow the send');
    check(line3.querySelector('[data-talk-notify]').value==='every' && line3.querySelector('[data-talk-hint]').textContent==='Updates from this conversation are on.','commenting did not join the conversation');
    check(calls.filter(c=>c[0]==='posted_round_thread' && c[1].p_round===R3).length===1,'the landed comment cost a second read');
    check(toasts.includes('Comment added.'),'no word that the comment landed');
    doorOf(R3).click();
    await until(()=>doorOf(R3).getAttribute('aria-expanded')==='false');
    check(lineOf(R3).hidden && peekOf(R3) && peekOf(R3).textContent==='You: Birdie on 7 or bust','the closed thread does not show the comment just sent');
    /* a comment removed in line leaves the thread, the door and the preview */
    peekOf(R3).click();
    const rm=await until(()=>lineOf(R3) && lineOf(R3).querySelector('[data-talk-remove]'));
    rm.click();
    check(rm.textContent==='Tap again to remove','Remove did not arm on the first press');
    rm.click();
    await until(()=>calls.some(c=>c[0]==='remove_posted_round_comment') && lineOf(R3) && !lineOf(R3).querySelector('.cs-talk-c') && doorOf(R3).getAttribute('aria-label')==='Comment on this round');
    check(window.csTalkSocial[R3].comment_count===0 && window.csTalkSocial[R3].latest===null && doorOf(R3).getAttribute('aria-expanded')==='true','a removed comment stayed on the door');
    doorOf(R3).click();
    await until(()=>doorOf(R3).getAttribute('aria-expanded')==='false');
    check(!peekOf(R3),'a removed comment stayed under the round');

    /* my own round: the newest three under Earlier comments (2), the owner's two choices */
    peekOf(R2).click();
    const line2=await until(()=>lineOf(R2) && lineOf(R2).querySelector('.cs-talk-c') && lineOf(R2));
    check(doorOf(R2).getAttribute('aria-expanded')==='true','the newest comment did not open the thread');
    check(texts(line2).join('|')==='Three putts on 16.|It was four.|Did the putt on 18 drop?','the newest three are not oldest first: '+texts(line2).join('|'));
    check(!line2.querySelector('.is-reply') && line2.querySelectorAll('.cs-talk-c')[1].querySelector('.cs-talk-to').textContent==='To Theo','a reply in line is nested, or lost its To');
    const earlier=line2.querySelector('[data-talk-earlier]');
    check(earlier && earlier.textContent==='Earlier comments (2)' && earlier.compareDocumentPosition(line2.querySelector('.cs-talk-c')) & Node.DOCUMENT_POSITION_FOLLOWING,'Earlier comments (2) is not above the newest three');
    check(line2.querySelector('textarea[data-talk-draft]').placeholder==='Comment on your 84…','the composer on my own round is wrong');
    const sel2=line2.querySelector('select[data-talk-notify]');
    check([...sel2.options].map(o=>o.value+':'+o.textContent).join('|')==='every:Every comment|nothing:Nothing' && sel2.value==='every','the owner was offered Replies to me, or not Every comment');
    check(line2.querySelector(`label[for="${sel2.id}"]`).textContent==='Notify me about','the setting is not labelled');
    check(line2.querySelector('[data-talk-hint]').textContent==='Updates from this conversation are on.','the owner’s hint does not say every comment');
    earlier.click();
    await until(()=>line2.querySelectorAll('.cs-talk-c').length===5);
    check(!line2.querySelector('[data-talk-earlier]') && document.activeElement===line2.querySelector('.cs-talk-c') && texts(line2)[0]==='Front nine was a clinic.','Earlier comments did not show the rest, oldest first, with the focus');
    doorOf(R2).click();
    await until(()=>doorOf(R2).getAttribute('aria-expanded')==='false');
    check(lineOf(R2).hidden && doorOf(R2).getAttribute('aria-label')==='5 comments, open the conversation' && peekOf(R2),'the door did not close the thread');
    /* a thread longer than the server's newest page: Earlier counts the whole
       thread, and the rest says how much of it is here */
    T[R2].extra=240;
    doorOf(R2).click();
    const line2b=await until(()=>lineOf(R2) && lineOf(R2).querySelector('[data-talk-earlier]') && lineOf(R2));
    check(line2b.querySelector('[data-talk-earlier]').textContent==='Earlier comments (242)' && line2b.querySelectorAll('.cs-talk-c').length===3,'Earlier comments does not count the whole thread');
    line2b.querySelector('[data-talk-earlier]').click();
    await until(()=>line2b.querySelectorAll('.cs-talk-c').length===5);
    check(line2b.textContent.includes('The newest 5 of 245 comments.'),'the rest of a long thread does not say how much of it is here');
    T[R2].extra=0;
    doorOf(R2).click();
    await until(()=>doorOf(R2).getAttribute('aria-expanded')==='false');
    await csTalkFetch([R1,R2,R3]); renderHomeFeed();

    /* the preview is text, and a server without `latest` keeps the count alone */
    window.csTalkSocial[R3]=Object.assign({}, window.csTalkSocial[R3], { comment_count:1, latest:{ id:'x', author:person(BLAKE,'Blake Fixture'), body:'<img src=x onerror="window.__pwn=1"> & "q"', created_at:iso(1e3) } });
    renderHomeFeed();
    check(peekOf(R3).textContent==='Blake: <img src=x onerror="window.__pwn=1"> & "q"' && !peekOf(R3).querySelector('img'),'the preview is not text');
    latestOn=false; await csTalkFetch([R1,R2,R3]); renderHomeFeed();
    check(!document.querySelector('#homeFeed [data-talk-peek]') && /5 comments, open the conversation/.test(doorOf(R2).getAttribute('aria-label')),'a server without latest drew a preview, or lost the count');
    latestOn=true; await csTalkFetch([R1,R2,R3]); renderHomeFeed();

    /* a comment from somebody else shows when Home next reads, in the open
       thread too, but never redraws a thread the golfer is typing in */
    doorOf(R1).click();
    const line1b=await until(()=>lineOf(R1) && lineOf(R1).querySelector('.cs-talk-c') && lineOf(R1));
    const LATE='20000000-0000-4000-8000-0000000000a7';
    T[R1].comments=T[R1].comments.concat([cm(LATE, R1, person(BLAKE,'Blake Fixture'), 'Rematch Saturday.', 1e3)]);
    const ta1b=line1b.querySelector('textarea[data-talk-draft]');
    ta1b.focus(); ta1b.value='Same'; ta1b.dispatchEvent(new Event('input'));
    const mark1=calls.length;
    await fetchHomeSocial();
    await until(()=>calls.slice(mark1).some(c=>c[0]==='posted_rounds_social'));
    await new Promise(r=>setTimeout(r,250));
    check(!calls.slice(mark1).some(c=>c[0]==='posted_round_thread' && c[1].p_round===R1) && !texts(lineOf(R1)).includes('Rematch Saturday.')
      && document.activeElement===ta1b && ta1b.value==='Same','a Home read redrew the thread being typed in');
    ta1b.value=''; ta1b.dispatchEvent(new Event('input')); ta1b.blur();
    await fetchHomeSocial();
    await until(()=>lineOf(R1) && texts(lineOf(R1)).includes('Rematch Saturday.'));
    check(doorOf(R1).getAttribute('aria-label')==='4 comments, hide the conversation' && lineOf(R1).querySelector('[data-talk-earlier]').textContent==='Earlier comments (1)','the re-read thread and its door disagree');
    T[R1].comments=T[R1].comments.filter(c=>c.id!==LATE);
    doorOf(R1).click();
    await until(()=>doorOf(R1).getAttribute('aria-expanded')==='false');
    await csTalkFetch([R1,R2,R3]); renderHomeFeed();
    out.inline='ok';

    /* ── 1c · the board: the same door, each post on its own ── */
    feed.length=0;
    feed.push({ d:'Today', ts:iso(0), roundpost:true, post_id:'40000000-0000-4000-8000-000000000001', rid:R1, who:'Theo Fixture', pid:THEO, team:'', ci:0, txt:'THEO FIXTURE POSTED 79 AT FIXTURE OAKS' },
              { d:'Today', ts:iso(3600e3), roundpost:true, post_id:'40000000-0000-4000-8000-000000000002', rid:R2, who:'You Fixture', pid:ME, team:'', ci:0, txt:'YOU POSTED 84 AT FIXTURE PINES' });
    renderFeed();
    const bdoor=rid=>document.querySelector(`#feedList [data-talk-open="${rid}"]`);
    const bline=rid=>bdoor(rid) && document.getElementById(bdoor(rid).getAttribute('aria-controls'));
    check(bdoor(R1) && bdoor(R1).getAttribute('aria-expanded')==='false' && bdoor(R1).getAttribute('aria-label')==='3 comments, open the conversation','the board door is not a closed toggle');
    check(bdoor(R1).closest('.social').querySelector('[data-talk-peek]').textContent==='Mara: League chatter','the board post does not show its newest comment');
    bdoor(R1).click();
    await until(()=>bline(R1) && bline(R1).querySelector('.cs-talk.is-inline .cs-talk-c'));
    check(bdoor(R1).getAttribute('aria-expanded')==='true' && bdoor(R1).getAttribute('aria-label')==='3 comments, hide the conversation' && bdoor(R1).closest('.msgrow').contains(bline(R1)) && !sheetOpen(),'the board door did not open the thread under its post');
    bdoor(R2).click();
    await until(()=>bline(R2) && bline(R2).querySelector('.cs-talk-c'));
    check(bdoor(R1).getAttribute('aria-expanded')==='true' && !bline(R1).hidden,'opening a second post closed the first (the board opens each on its own)');
    const keepB=bline(R1); renderFeed();
    check(bline(R1)===keepB && bdoor(R1).getAttribute('aria-expanded')==='true' && bdoor(R2).getAttribute('aria-expanded')==='true','a board repaint closed a thread');
    check(!document.querySelector('#homeFeed [aria-expanded="true"][data-hftalk]'),'the board’s doors opened a thread on Home');
    /* a board refresh (the realtime nudge's read) re-reads an open thread too */
    const LATE2='20000000-0000-4000-8000-0000000000a8';
    T[R1].comments=T[R1].comments.concat([cm(LATE2, R1, person(BLAKE,'Blake Fixture'), 'See you Saturday.', 1e3)]);
    if(document.activeElement && document.activeElement.blur) document.activeElement.blur();
    await fetchSocial(feed.filter(f=>f.post_id).map(f=>f.post_id));
    await until(()=>bline(R1) && texts(bline(R1)).includes('See you Saturday.') && bdoor(R1).getAttribute('aria-label')==='4 comments, hide the conversation');
    T[R1].comments=T[R1].comments.filter(c=>c.id!==LATE2);
    bdoor(R1).click();
    await until(()=>bdoor(R1).getAttribute('aria-expanded')==='false');
    check(bdoor(R2).getAttribute('aria-expanded')==='true' && bline(R1).hidden,'closing one board post closed the other');
    bdoor(R2).click();
    await until(()=>bdoor(R2).getAttribute('aria-expanded')==='false');
    feed.splice(0, feed.length, ...saved.feed); renderFeed();
    out.board='ok';

    /* ── 1d · D405 · what a review of the build found, each case pinned ── */
    const sleep=ms=>new Promise(r=>setTimeout(r,ms));
    const raf=()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)));
    /* every case starts from the three fixture threads as they were written */
    const fresh=async()=>{
      closeSheet();
      [...csTalkUi().open].forEach(csTalkLineDrop); csTalkDrafts.clear();
      T[R1].comments=T[R1].comments.filter(c=>[C1,C2,C9].includes(c.id)); T[R3].comments=[];
      Object.values(T).forEach(t=>{ t.thread={ state:'none', following:false, muted:false }; });
      window.csTalkSocial={}; await csTalkFetch([R1,R2,R3]); renderHomeFeed(); await sleep(30);
    };
    const quiet=()=>{ if(document.activeElement && document.activeElement.blur) document.activeElement.blur(); };
    const openLine=async rid=>{ doorOf(rid).click(); return until(()=>lineOf(rid) && lineOf(rid).querySelector('.cs-talk.is-inline textarea') && lineOf(rid)); };
    const typeIn=(line,words)=>{ const t=line.querySelector('textarea[data-talk-draft]'); t.focus(); t.value=words; t.dispatchEvent(new Event('input')); return t; };

    /* a read that began before a comment landed is stale: the comment, the door's count and its
       newest comment stay (the old answer used to redraw the thread from its three-comment snapshot) */
    await fresh();
    const lineA=await openLine(R1);
    await until(()=>texts(lineA).length===3);
    quiet();
    delay.posted_round_thread=600;
    csTalkRefreshOpen(k=>k.startsWith('h|'));          /* a Home read: asked now, answered late */
    await sleep(60);
    typeIn(lineA,'Raced it');
    lineA.querySelector('[data-talk-send]').click();
    await until(()=>texts(lineOf(R1)).includes('Raced it'));
    await sleep(900);                                  /* the old answer arrives */
    check(texts(lineOf(R1)).includes('Raced it') && doorOf(R1).getAttribute('aria-label')==='4 comments, hide the conversation'
      && window.csTalkSocial[R1].comment_count===4 && window.csTalkSocial[R1].latest.body==='Raced it','a read that began before a comment landed took the comment back out of the thread, or the door with it');
    /* …and the same for a Notify me about choice made while a read was out */
    await fresh();
    const lineA2=await openLine(R1);
    await until(()=>texts(lineA2).length===3);
    quiet();
    delay.posted_round_thread=600;
    csTalkRefreshOpen(k=>k.startsWith('h|'));
    await sleep(60);
    const selA2=lineA2.querySelector('select[data-talk-notify]');
    selA2.value='nothing'; selA2.dispatchEvent(new Event('change'));
    await until(()=>calls.some(c=>c[0]==='set_round_thread_state' && c[1].p_round===R1 && c[1].p_state==='muted'));
    await sleep(900);
    check(lineOf(R1).querySelector('[data-talk-notify]').value==='nothing' && lineOf(R1).querySelector('[data-talk-hint]').textContent===CS_TALK.mutedHint,'a read that began before a choice put the old choice back');

    /* one draft per round, however many views of the thread are open: a reply target the page chose
       is shown in line, and what a view shows is what it sends */
    await fresh();
    const lineB=await openLine(R1);
    openRoundReceipt(window.homeFeedRows[0], {});
    await until(()=>document.querySelector(`#rcptTalk [data-talk-reply="${C1}"]`));
    document.querySelector(`#rcptTalk [data-talk-reply="${C1}"]`).click();
    await until(()=>document.querySelector('#rcptTalk .cs-talk-ctx'));
    check(lineB.querySelector('.cs-talk-ctx') && /Replying to Theo/.test(lineB.querySelector('.cs-talk-ctx').textContent) && lineB.querySelector('[data-talk-send]').textContent===CS_TALK.sendReply,
      'the thread in line did not say it is a reply once the page chose a target');
    /* …and Cancel on the page takes the target off the thread in line, too */
    document.querySelector('#rcptTalk [data-talk-cancel]').click();
    check(!lineB.querySelector('.cs-talk-ctx') && lineB.querySelector('[data-talk-send]').textContent===CS_TALK.send,'Cancel on the page left the thread in line replying');
    document.querySelector(`#rcptTalk [data-talk-reply="${C1}"]`).click();
    await until(()=>lineB.querySelector('.cs-talk-ctx'));
    /* the golfer picks Reply in the sheet and a view's selection is the page's: choose a choice in the sheet too */
    const rsel=document.querySelector('#rcptTalk select[data-talk-notify]');
    rsel.value='nothing'; rsel.dispatchEvent(new Event('change'));
    await until(()=>lineB.querySelector('[data-talk-notify]') && lineB.querySelector('[data-talk-notify]').value==='nothing');
    check(lineB.querySelector('[data-talk-hint]').textContent===CS_TALK.mutedHint,'a choice made on the page did not reach the thread in line');
    closeSheet(); await sleep(50);
    lineB.querySelector('[data-talk-cancel]').click();
    check(!lineB.querySelector('.cs-talk-ctx') && lineB.querySelector('[data-talk-send]').textContent===CS_TALK.send,'Cancel did not take the reply target off the thread in line');
    typeIn(lineB,'A plain comment');
    const mB=calls.length;
    lineB.querySelector('[data-talk-send]').click();
    await until(()=>calls.slice(mB).some(c=>c[0]==='add_posted_round_comment'));
    check(calls.slice(mB).find(c=>c[0]==='add_posted_round_comment')[1].p_parent===null,'a comment written after Cancel was sent as a reply');
    await until(()=>texts(lineOf(R1)).includes('A plain comment'));
    /* a target no view was redrawn for is not sent unseen */
    csTalkDraft(R1).parent=C1;
    typeIn(lineOf(R1),'Second comment');
    const mB2=calls.length;
    lineOf(R1).querySelector('[data-talk-send]').click();
    await until(()=>calls.slice(mB2).some(c=>c[0]==='add_posted_round_comment'));
    check(calls.slice(mB2).find(c=>c[0]==='add_posted_round_comment')[1].p_parent===null,'a reply target the composer did not show was sent');

    /* a refused send says so, and keeps what was typed, even when the thread is redrawn while it is on the way */
    await fresh();
    const lineC=await openLine(R3);
    lineC.scrollIntoView({ block:'center' }); await sleep(30);
    typeIn(lineC,'This will be refused');
    fail.add_posted_round_comment={ code:'P0001', message:'Easy — try again in a minute' };
    delay.add_posted_round_comment=500;
    const sendC=lineC.querySelector('[data-talk-send]');
    sendC.focus(); sendC.click();                      /* a real press: the button that holds the focus is off while it sends */
    await sleep(30);
    const readsC=calls.filter(c=>c[0]==='posted_round_thread').length;
    csTalkRefreshOpen(k=>k.startsWith('h|'));          /* a Home read lands while the comment is on the way */
    await sleep(60);
    check(calls.filter(c=>c[0]==='posted_round_thread').length===readsC && lineOf(R3).querySelector('[data-talk-send]').disabled,'a read redrew a thread whose comment was on the way');
    await sleep(700);
    check(/try again in a minute/.test(lineOf(R3).querySelector('[data-talk-err]').textContent) && lineOf(R3).querySelector('textarea[data-talk-draft]').value==='This will be refused'
      && !lineOf(R3).querySelector('[data-talk-send]').disabled,'a refused send said nothing, lost the draft, or left Send off');
    check(lineOf(R3).contains(document.activeElement),'a refused send left the focus on the page');
    /* …a Reply pressed while it is on the way redraws the thread, and the answer still finds the line */
    await fresh();
    const lineC2=await openLine(R1);
    typeIn(lineC2,'Refused again');
    fail.add_posted_round_comment={ code:'P0001', message:'Easy — try again in a minute' };
    delay.add_posted_round_comment=500;
    lineC2.querySelector('[data-talk-send]').click();
    await sleep(40);
    lineC2.querySelector('[data-talk-reply]').click();
    check(lineOf(R1).querySelector('[data-talk-send]').disabled,'a thread redrawn while its comment was on the way offered Send again');
    await sleep(700);
    check(/try again in a minute/.test(lineOf(R1).querySelector('[data-talk-err]').textContent) && !lineOf(R1).querySelector('[data-talk-send]').disabled
      && lineOf(R1).querySelector('textarea[data-talk-draft]').value==='Refused again','a refused send was lost to a Reply pressed while it was on the way');
    /* …and a thread folded while it sends has nowhere to say so: the toast does */
    await fresh();
    const lineC3=await openLine(R3);
    typeIn(lineC3,'Folded away');
    fail.add_posted_round_comment={ code:'P0001', message:'Easy — try again in a minute' };
    delay.add_posted_round_comment=400;
    const toastsC=toasts.length;
    lineC3.querySelector('[data-talk-send]').click();
    await sleep(30);
    doorOf(R3).click();
    await sleep(600);
    check(toasts.slice(toastsC).some(m=>/try again in a minute/.test(m)) && csTalkDraft(R3).text==='Folded away','a refused send from a folded thread said nothing, or lost the draft');

    /* the compact board: a round post is a flex row whose text column may be narrower than its longest
       line, so the newest-comment line shortens and the post stays inside the list */
    await fresh();
    window.csTalkSocial[R1].latest={ id:'x', author:person(BLAKE,'Blake Fixture'), body:'Did the putt on 18 drop or did it lip out again like last week when we all watched it horseshoe around the cup and come back', created_at:iso(1e3) };
    feed.length=0;
    feed.push({ d:'Today', ts:iso(0), roundpost:true, post_id:'40000000-0000-4000-8000-000000000001', rid:R1, who:'Theo Fixture', pid:THEO, team:'', ci:0, txt:'THEO FIXTURE POSTED 79 AT FIXTURE OAKS' });
    renderFeed();
    const probeBox=document.createElement('div');
    probeBox.style.cssText='position:absolute; left:0; top:0; width:358px;';
    probeBox.innerHTML=document.querySelector('#feedList .msgrow').outerHTML;
    document.body.appendChild(probeBox);
    const mrow=probeBox.querySelector('.msgrow'), mtxt=probeBox.querySelector('.mtxt'), peekSpan=probeBox.querySelector('.cs-talk-peek > span');
    check(peekSpan && mtxt.getBoundingClientRect().width<=mrow.getBoundingClientRect().width && probeBox.scrollWidth<=probeBox.clientWidth+1 && peekSpan.scrollWidth>peekSpan.clientWidth,
      'a long newest comment pushed the compact board’s post past its list: column '+Math.round(mtxt.getBoundingClientRect().width)+' in a row of '+Math.round(mrow.getBoundingClientRect().width));
    probeBox.remove();
    feed.splice(0, feed.length, ...saved.feed); renderFeed();

    /* the full board on a quiet day: a golfer at the newest post who opens its thread stays there
       (a digest at the top used to carry every redraw back to the top) */
    await fresh();
    const keepCache=window.roundCache && window.roundCache[R1];
    window.roundCache=window.roundCache||{};
    window.roundCache[R1]={ id:R1, profile_id:THEO, gross:79, pvi:1.2, course_label:'FIXTURE Oaks', holes_played:18, played_on:today, month_rank:1, points:10 };
    window.bdAsOf=window.bdAsOf||{};
    const seenKey=boardSeenKey(), keepSeen=window.bdAsOf[seenKey];
    window.bdAsOf[seenKey]=Date.now()-60e3;
    const baseTs=Date.now()-6*3600e3;
    feed.length=0;
    for(let i=0;i<24;i++) feed.push({ d:'Today', ts:baseTs+i*60e3, msg:true, post_id:'41000000-0000-4000-8000-0000000000'+String(10+i), who:'Mara Fixture', pid:MARA, txt:'Filler line '+i });
    feed.push({ d:'Today', ts:baseTs+30*60e3, roundpost:true, post_id:'40000000-0000-4000-8000-000000000001', rid:R1, who:'Theo Fixture', pid:THEO, team:'', ci:0, txt:'THEO FIXTURE POSTED 79 AT FIXTURE OAKS' });
    try{
      openBoardFull(); await raf(); await sleep(50);
      const full=document.getElementById('feedListFull');
      check(full.querySelector('.digest'),'the quiet-day digest is not showing (the case this pins)');
      full.scrollTop=full.scrollHeight; await raf();
      const atBottom=full.scrollTop;
      check(atBottom>200,'the full board does not scroll (nothing to pin)');
      full.querySelector(`[data-talk-open="${R1}"]`).click();
      await raf(); await sleep(80);
      check(full.scrollTop>=atBottom-8 && full.querySelector(`[data-talk-open="${R1}"]`).getAttribute('aria-expanded')==='true','opening the newest post’s thread at the bottom of the full board threw the reader to the top: '+Math.round(atBottom)+' → '+Math.round(full.scrollTop));
    } finally {
      closeBoardFull();
      if(keepCache) window.roundCache[R1]=keepCache; else delete window.roundCache[R1];
      if(keepSeen===undefined) delete window.bdAsOf[seenKey]; else window.bdAsOf[seenKey]=keepSeen;
      feed.splice(0, feed.length, ...saved.feed); renderFeed();
    }

    /* a thread open on a board that is not showing is not read; it reads again when its board comes back */
    await fresh();
    const twoPosts=()=>{ feed.length=0;
      feed.push({ d:'Today', ts:Date.now()-60e3, roundpost:true, post_id:'40000000-0000-4000-8000-000000000001', rid:R1, who:'Theo Fixture', pid:THEO, team:'', ci:0, txt:'THEO FIXTURE POSTED 79 AT FIXTURE OAKS' },
                { d:'Today', ts:Date.now()-30e3, roundpost:true, post_id:'40000000-0000-4000-8000-000000000002', rid:R2, who:'You Fixture', pid:ME, team:'', ci:0, txt:'YOU POSTED 84 AT FIXTURE PINES' }); };
    twoPosts(); renderFeed();
    bdoor(R1).click(); await until(()=>bline(R1) && bline(R1).querySelector('.cs-talk.is-inline .cs-talk-c'));
    bdoor(R2).click(); await until(()=>bline(R2) && bline(R2).querySelector('.cs-talk.is-inline .cs-talk-c'));
    quiet();
    feed.length=0;
    feed.push({ d:'Today', ts:Date.now(), msg:true, post_id:'41000000-0000-4000-8000-000000000099', who:'Mara Fixture', pid:MARA, txt:'Another league' });
    renderFeed();                                      /* the golfer is on a board that has neither round */
    const away0=calls.length;
    for(let i=0;i<3;i++){ csTalkRefreshOpen(k=>/^(f-)?b\|/.test(k)); await sleep(100); }
    check(!calls.slice(away0).some(c=>c[0]==='posted_round_thread'),'a thread on a board that is not showing was read on every refresh');
    check([...csTalkUi().open].filter(k=>k.startsWith('b|')).length===2,'a thread on a board that is not showing was closed');
    twoPosts(); renderFeed();                          /* back to the first board: both threads are open and read again */
    await until(()=>new Set(calls.slice(away0).filter(c=>c[0]==='posted_round_thread').map(c=>c[1].p_round)).size===2);
    check(bdoor(R1).getAttribute('aria-expanded')==='true' && !bline(R1).hidden && bdoor(R2).getAttribute('aria-expanded')==='true','a thread did not wait open for its board to come back');
    [...csTalkUi().open].forEach(csTalkLineDrop);
    feed.splice(0, feed.length, ...saved.feed); renderFeed();

    /* …a sheet closed while it sent, and a view switched away from, are not places to write the refusal: the toast says it */
    await fresh();
    openRoundReceipt(window.homeFeedRows[0], {});
    await until(()=>document.querySelector('#rcptTalk textarea[data-talk-draft]'));
    const taSheet=document.querySelector('#rcptTalk textarea[data-talk-draft]');
    taSheet.value='Sheet closed mid-send'; taSheet.dispatchEvent(new Event('input'));
    fail.add_posted_round_comment={ code:'P0001', message:'Easy — try again in a minute' };
    delay.add_posted_round_comment=400;
    const toastsSheet=toasts.length;
    document.querySelector('#rcptTalk [data-talk-send]').click();
    await sleep(40);
    closeSheet();
    await sleep(700);
    check(toasts.slice(toastsSheet).some(m=>/try again in a minute/.test(m)) && csTalkDraft(R1).text==='Sheet closed mid-send','a refused send from a sheet that closed said nothing, or lost the words');
    await fresh();
    const lineView=await openLine(R3);
    typeIn(lineView,'View switched mid-send');
    fail.add_posted_round_comment={ code:'P0001', message:'Easy — try again in a minute' };
    delay.add_posted_round_comment=400;
    const toastsView=toasts.length;
    lineView.querySelector('[data-talk-send]').click();
    await sleep(40);
    const homeView=document.getElementById('homeFeed').closest('[id^="view-"]');
    homeView.style.display='none';                       /* the golfer switched to another view */
    await sleep(700);
    homeView.style.display='';
    check(toasts.slice(toastsView).some(m=>/try again in a minute/.test(m)) && csTalkDraft(R3).text==='View switched mid-send','a refused send from a view that was switched away from said nothing, or lost the words');

    /* a doors read asked before a comment landed does not take the count, or the newest comment, back */
    await fresh();
    const lineDoor=await openLine(R1);
    await until(()=>texts(lineDoor).length===3);
    delay.posted_rounds_social=600;
    const staleDoors=csTalkFetch([R1,R2,R3]);            /* asked now, answered late with three comments */
    await sleep(60);
    typeIn(lineDoor,'The door must not forget me');
    lineDoor.querySelector('[data-talk-send]').click();
    await until(()=>texts(lineOf(R1)).includes('The door must not forget me'));
    await staleDoors; await sleep(60);
    renderHomeFeed();
    check(window.csTalkSocial[R1].comment_count===4 && window.csTalkSocial[R1].latest && window.csTalkSocial[R1].latest.body==='The door must not forget me'
      && doorOf(R1).getAttribute('aria-label')==='4 comments, hide the conversation','a doors read asked before a comment landed took the count and the newest comment back');
    doorOf(R1).click();
    await until(()=>doorOf(R1).getAttribute('aria-expanded')==='false');
    check(peekOf(R1) && peekOf(R1).textContent==='You: The door must not forget me','the folded thread shows the comment it had before the stale doors read answered');

    /* a word about a thread that was taken before the door's newest one never overwrites it (the clock is the thread's own) */
    {
      const row=window.csTalkSocial[R1], was=row.comment_count, spoke=row.__spoke;
      row.__spoke=1e9;
      csTalkSocialSync(R1, was+5, null, 1);
      check(row.comment_count===was,'an older word about a thread overwrote a newer one on its door');
      csTalkSocialSync(R1, was+5, null, 2e9);
      check(row.comment_count===was+5,'a newer word about a thread did not reach its door');
      row.comment_count=was; row.__spoke=spoke;
    }

    /* an in-line thread whose FIRST read is still out when a comment lands from the round's page reads again */
    await fresh();
    delay.posted_round_thread=700;
    doorOf(R1).click();                                  /* its first read: asked now, answered late with three comments */
    await sleep(60);
    openRoundReceipt(window.homeFeedRows[0], {});        /* the page's own read is not held back */
    await until(()=>document.querySelector('#rcptTalk textarea[data-talk-draft]'));
    const taFirst=document.querySelector('#rcptTalk textarea[data-talk-draft]');
    taFirst.value='Landed while the first read was out'; taFirst.dispatchEvent(new Event('input'));
    document.querySelector('#rcptTalk [data-talk-send]').click();
    await until(()=>T[R1].comments.some(c=>c.body==='Landed while the first read was out'));
    closeSheet();
    await sleep(1100);
    check(texts(lineOf(R1)).includes('Landed while the first read was out') && doorOf(R1).getAttribute('aria-label')==='4 comments, hide the conversation',
      'a thread whose first read was out when a comment landed drew the snapshot from before it');

    /* a read that answers while the choice is being written draws the old one: the control the golfer used says the new one */
    await fresh();
    const lineChoice=await openLine(R1);
    await until(()=>texts(lineChoice).length===3);
    quiet();
    delay.posted_round_thread=150;                       /* asked now (the thread still says none), answered during the write */
    csTalkRefreshOpen(k=>k.startsWith('h|'));
    await sleep(10);
    delay.set_round_thread_state=450;
    const selChoice=lineChoice.querySelector('select[data-talk-notify]');
    selChoice.value='nothing'; selChoice.dispatchEvent(new Event('change'));
    await sleep(900);
    check(lineOf(R1).querySelector('[data-talk-notify]').value==='nothing' && lineOf(R1).querySelector('[data-talk-hint]').textContent===CS_TALK.mutedHint,
      'a read drawn while the choice was being written left the old choice under the new hint');

    /* a refusal under a sheet that opened over the thread is covered: the toast says it (the thread is in the window, and drawn) */
    await fresh();
    const lineCov=await openLine(R3);
    lineCov.scrollIntoView({ block:'center' }); await sleep(30);
    check(csTalkSeen(lineCov.querySelector('textarea[data-talk-draft]')),'the thread under test is not in the window (nothing to pin)');
    typeIn(lineCov,'Covered mid-send');
    fail.add_posted_round_comment={ code:'P0001', message:'Easy — try again in a minute' };
    delay.add_posted_round_comment=500;
    const toastsCov=toasts.length;
    lineCov.querySelector('[data-talk-send]').click();
    await sleep(40);
    openRoundReceipt(window.homeFeedRows[0], {});         /* a sheet opens over Home while the comment is on the way */
    await sleep(700);
    check(toasts.slice(toastsCov).some(m=>/try again in a minute/.test(m)) && csTalkDraft(R3).text==='Covered mid-send','a refused send from a thread a sheet had covered said nothing, or lost the words');
    closeSheet();

    /* two doors reads and a comment between them: the older read, answering last, does not undo the comment, and neither
       does a thread read asked before a doors read that answered after it */
    await fresh();
    const lineTwo=await openLine(R1);
    await until(()=>texts(lineTwo).length===3);
    delay.posted_rounds_social=700;
    const firstDoors=csTalkFetch([R1,R2,R3]);            /* asked first, answered last, with three comments */
    await sleep(40);
    typeIn(lineTwo,'Between two doors reads');
    lineTwo.querySelector('[data-talk-send]').click();
    await until(()=>texts(lineOf(R1)).includes('Between two doors reads'));
    await csTalkFetch([R1,R2,R3]);                       /* asked after the comment, answered at once: four */
    await firstDoors; renderHomeFeed();
    check(window.csTalkSocial[R1].comment_count===4 && window.csTalkSocial[R1].latest && window.csTalkSocial[R1].latest.body==='Between two doors reads'
      && doorOf(R1).getAttribute('aria-label')==='4 comments, hide the conversation','an older doors read, answering after a newer one, undid a comment that landed between them');
    await fresh();
    const lineLate=await openLine(R1);
    await until(()=>texts(lineLate).length===3);
    quiet();
    delay.posted_round_thread=700;
    csTalkRefreshOpen(k=>k.startsWith('h|'));            /* a thread read, asked now (three comments), answered last */
    await sleep(40);
    T[R1].comments=T[R1].comments.concat([cm('20000000-0000-4000-8000-0000000000c1', R1, person(BLAKE,'Blake Fixture'), 'Said while that read was out', 1e3)]);
    await csTalkFetch([R1,R2,R3]);                       /* asked after it, answered at once: four */
    await sleep(900);
    check(window.csTalkSocial[R1].comment_count===4 && window.csTalkSocial[R1].latest && window.csTalkSocial[R1].latest.body==='Said while that read was out',
      'a thread read asked before a doors read took the newer doors answer back');

    /* the landing's own re-read is the newest snapshot there is: another golfer's comment, committed after the landing,
       reaches the door as well as the thread */
    await fresh();
    delay.posted_round_thread=700;
    doorOf(R1).click();                                  /* its first read is out */
    await sleep(60);
    openRoundReceipt(window.homeFeedRows[0], {});
    await until(()=>document.querySelector('#rcptTalk textarea[data-talk-draft]'));
    const taAgain=document.querySelector('#rcptTalk textarea[data-talk-draft]');
    taAgain.value='Mine, then theirs'; taAgain.dispatchEvent(new Event('input'));
    onThread=()=>{ T[R1].comments=T[R1].comments.concat([cm('20000000-0000-4000-8000-0000000000c2', R1, person(BLAKE,'Blake Fixture'), 'Theirs, a moment later', 1e3)]); };
    document.querySelector('#rcptTalk [data-talk-send]').click();
    await until(()=>T[R1].comments.some(c=>c.body==='Theirs, a moment later'));
    closeSheet();
    await sleep(1100);
    check(window.csTalkSocial[R1].comment_count===5 && texts(lineOf(R1)).includes('Theirs, a moment later') && doorOf(R1).getAttribute('aria-label')==='5 comments, hide the conversation',
      'the re-read a landing asks for was refused for the door, so the door and the thread disagreed');

    /* a choice written on the page while an in-line thread's FIRST read is out reaches that thread too */
    await fresh();
    delay.posted_round_thread=700;
    doorOf(R1).click();
    await sleep(60);
    openRoundReceipt(window.homeFeedRows[0], {});
    await until(()=>document.querySelector('#rcptTalk select[data-talk-notify]'));
    const selPage=document.querySelector('#rcptTalk select[data-talk-notify]');
    selPage.value='nothing'; selPage.dispatchEvent(new Event('change'));
    await until(()=>calls.some(c=>c[0]==='set_round_thread_state' && c[1].p_round===R1 && c[1].p_state==='muted'));
    closeSheet();
    await sleep(1100);
    check(lineOf(R1).querySelector('[data-talk-notify]').value==='nothing' && lineOf(R1).querySelector('[data-talk-hint]').textContent===CS_TALK.mutedHint,
      'a choice written while an in-line first read was out left that thread on the old choice');

    /* a server without D405 does not record the follow a comment would have made: the control and the hint do not say it did */
    latestOn=false; await fresh();
    const lineG=await openLine(R1);
    typeIn(lineG,'Is this an older server?');
    lineG.querySelector('[data-talk-send]').click();
    await until(()=>texts(lineOf(R1)).includes('Is this an older server?'));
    check(lineOf(R1).querySelector('[data-talk-notify]').value==='replies' && lineOf(R1).querySelector('[data-talk-hint]').textContent===CS_TALK.replyHint
      && window.csTalkSocial[R1].thread_state==='none','on a server without D405 a comment told the golfer they were following');
    /* …and the same for a thread opened with no door of its own (a link, a notice): the page remembers what the last doors read said */
    await fresh();                                       /* still without D405: its doors carry no `latest` */
    delete window.csTalkSocial[R1];
    openRoundReceipt(window.homeFeedRows[0], {});
    await until(()=>document.querySelector('#rcptTalk textarea[data-talk-draft]'));
    const taOld=document.querySelector('#rcptTalk textarea[data-talk-draft]');
    taOld.value='A thread with no door, on an older server'; taOld.dispatchEvent(new Event('input'));
    document.querySelector('#rcptTalk [data-talk-send]').click();
    await until(()=>document.querySelector('#rcptTalk .cs-talk-c.is-target'));
    check(document.querySelector('#rcptTalk [data-talk-notify]').value==='replies' && document.querySelector('#rcptTalk [data-talk-hint]').textContent===CS_TALK.replyHint,
      'a comment on a thread with no door, on a server without D405, told the golfer they were following');
    closeSheet();
    latestOn=true;
    await fresh();
    out.review='ok';

    /* ── 2 · the receipt's conversation ── */
    openRoundReceipt(window.homeFeedRows[0], { focusTalk:true });
    await until(()=>document.querySelector('#rcptTalk .cs-talk')); const slot=document.getElementById('rcptTalk');
    /* D405 · the page and its conversation say whose round it is */
    const title=document.getElementById('shTitle');
    check(title.textContent==='Theo’s round' && title.querySelector('.rcpt-owner[aria-hidden="true"] .fc'),'the page does not name whose round it is: '+title.textContent);
    check(slot.querySelector('#talkHead').textContent===`On Theo’s 79 ${MID} 3`,'the conversation head does not name the round: '+slot.querySelector('#talkHead').textContent);
    check(slot.querySelector('#talkDraft').placeholder==='Comment on Theo’s 79…','the receipt’s composer does not name the round');
    const first=slot.querySelector(`#talk-c-${C1} .cs-talk-text`);
    check(first && first.textContent==='Same ball? <b>witness</b> & "quotes"' && !first.querySelector('b'),'a comment was not rendered as text');
    check(slot.querySelector(`#talk-c-${C2}`).classList.contains('is-reply') && slot.querySelector(`#talk-c-${C2} .cs-talk-to`).textContent==='To Theo','the reply is not under its root');
    const board=[...slot.querySelectorAll('.cs-talk-c')].find(a=>a.textContent.includes('League chatter'));
    check(board && !board.querySelector('[data-talk-reply]'),'a league-board comment offered a reply');
    check(slot.querySelector('#talkHead').textContent.includes('3'),'the head does not count the thread');
    check(slot.querySelector('label[for="talkDraft"]'),'the draft has no label');
    check(slot.querySelector('#talkErr').getAttribute('role')==='alert','the error line is not announced');
    check(!slot.querySelector('[data-talk-follow],[data-talk-mute]') && !/\bFollow(ing)?\b|Mute conversation/.test(slot.textContent),'the bare Follow, or a Mute button, survived on the receipt');
    const sel=slot.querySelector('select[data-talk-notify]');
    check(sel && slot.querySelector(`label[for="${sel.id}"]`).textContent==='Notify me about','no labelled Notify me about');
    check([...sel.options].map(o=>o.value+':'+o.textContent).join('|')==='every:Every comment|replies:Replies to me|nothing:Nothing' && sel.value==='replies','the three choices, or the baseline, are wrong: '+sel.value);
    check(document.querySelector('#talkHint').textContent==='You’ll be notified of replies to you.','the baseline hint is wrong');

    /* reply target, then a failed send: the draft, the target and the key stay */
    const sendMark=calls.length;
    slot.querySelector(`[data-talk-reply="${C1}"]`).click();
    await until(()=>slot.querySelector('.cs-talk-ctx'));
    check(slot.querySelector('label[for="talkDraft"]').textContent==='Your reply' && slot.querySelector('#talkSend').textContent==='Reply','the composer did not become a reply');
    const ta=slot.querySelector('#talkDraft');
    ta.value='Saturday again? <script>x</script>'; ta.dispatchEvent(new Event('input'));
    fail.add_posted_round_comment={ message:'Failed to fetch' };
    slot.querySelector('#talkSend').click();
    await until(()=>slot.querySelector('#talkErr').textContent);
    check(slot.querySelector('#talkDraft').value==='Saturday again? <script>x</script>','the draft was lost on a failed send');
    check(!slot.querySelector('#talkSend').disabled,'the send stayed disabled after a failure');
    check(slot.querySelector('.cs-talk-ctx'),'the reply target was lost on a failed send');
    const firstKey=calls.slice(sendMark).filter(c=>c[0]==='add_posted_round_comment' && c[1].p_round===R1)[0][1].p_client_id;
    slot.querySelector('#talkSend').click();
    await until(()=>document.querySelector('#rcptTalk .cs-talk-c.is-target'));
    const sends=calls.slice(sendMark).filter(c=>c[0]==='add_posted_round_comment' && c[1].p_round===R1);
    check(sends.length===2 && sends[1][1].p_client_id===firstKey && sends[1][1].p_parent===C1,'the retry did not reuse its key and target');
    const slot2=document.querySelector('#rcptTalk');
    check(slot2.querySelector('#talkDraft').value==='','the draft survived a landed comment');
    const mineRow=slot2.querySelector('.cs-talk-c.is-target');
    check(mineRow.querySelector('.cs-talk-text').textContent==='Saturday again? <script>x</script>' && !mineRow.querySelector('script'),'the new comment is not text');
    check(mineRow.classList.contains('is-reply') && mineRow.querySelector('.cs-talk-to').textContent==='To Theo','the landed reply is not under its comment');
    check(document.activeElement===mineRow,'the new comment did not take focus');
    check(mineRow.querySelector('[data-talk-remove]') && !mineRow.querySelector('[data-talk-report]'),'my own comment offers report, or no remove');
    check(slot2.querySelector('#talkHead').textContent===`On Theo’s 79 ${MID} 4` && window.csTalkSocial[R1].comment_count===4,'the head or the doors did not count the landed comment');
    out.thread='ok';

    /* Notify me about (D405 · the bare Follow is gone): commenting already
       turned it on; each choice writes its state; a failed write reverts */
    const nsel=()=>document.querySelector('#rcptTalk select[data-talk-notify]');
    const hint=()=>document.querySelector('#talkHint').textContent;
    check(nsel().value==='every' && hint()==='Updates from this conversation are on.','commenting did not turn the conversation on');
    const choose=async v=>{ const s=nsel(); s.value=v; s.dispatchEvent(new Event('change')); await until(()=>s.dataset.choice===v); return calls.filter(c=>c[0]==='set_round_thread_state').at(-1)[1]; };
    let w=await choose('nothing');
    check(w.p_round===R1 && w.p_state==='muted' && hint()==='This conversation is muted.','Nothing did not mute');
    w=await choose('replies');
    check(w.p_state==='replies' && hint()==='You’ll be notified of replies to you.','Replies to me did not write replies');
    w=await choose('every');
    check(w.p_state==='following' && hint()==='Updates from this conversation are on.','Every comment did not write following');
    fail.set_round_thread_state={ code:'22023', message:'Unknown conversation setting' };
    nsel().value='nothing'; nsel().dispatchEvent(new Event('change'));
    await until(()=>toasts.some(t=>String(t).startsWith('That setting did not save.')));
    check(nsel().value==='every' && nsel().dataset.choice==='every' && hint()==='Updates from this conversation are on.','a failed write did not put the control back');
    out.notify='ok';

    /* the owner's own page: "Your round", no face, the two choices */
    openRoundReceipt(window.homeFeedRows[1], {});
    await until(()=>document.querySelector('#rcptTalk .cs-talk') && document.getElementById('rcptTalk').dataset.rid===R2 && document.querySelector('#rcptTalk select[data-talk-notify]'));
    check(document.getElementById('shTitle').textContent==='Your round' && !document.querySelector('#shTitle .rcpt-owner'),'my own page is not titled Your round');
    check(document.querySelector('#talkHead').textContent===`On your 84 ${MID} 5`,'my own round’s head is wrong');
    check([...nsel().options].map(o=>o.value).join(',')==='every,nothing','the owner’s page offered Replies to me');
    out.owner='ok';

    /* ── 3 · the inbox ── */
    await csBadgeRefresh();
    const bell=document.getElementById('hdrBell');
    check(!bell.hidden && bell.getAttribute('aria-label')==='Notifications, 1 unread' && document.getElementById('hdrBellN').textContent==='1','the bell is not counting');
    bell.click();
    await until(()=>document.querySelector('#shBody [data-inbox]'));
    /* the composite cursor: "Show older" carries (created_at, id), and a row it already has is not doubled */
    document.querySelector('#shBody [data-inbox-more]').click();
    await until(()=>document.querySelectorAll('#shBody [data-inbox]').length===notes.length+1 && !document.querySelector('#shBody [data-inbox-more]'));
    const more=calls.filter(c=>c[0]==='my_notifications').at(-1)[1];
    check(more.p_before===notes[0].created_at && more.p_before_id===N1 && more.p_limit===30,'"Show older" did not send the composite cursor: '+JSON.stringify(more));
    const item=document.querySelector('#shBody [data-inbox="'+N1+'"]');
    check(item.textContent.includes('Mara replied to your comment.') && item.textContent.includes('“Caught the left edge.”') && item.textContent.includes('Unread'),'the inbox sentence is wrong: '+item.textContent.replace(/\s+/g,' '));
    /* D405 · a notice names the round; a key an older server does not send keeps the older sentence */
    const say=id=>document.querySelector('#shBody [data-inbox="'+id+'"] .cs-inbox-line').textContent;
    check(say(N(2))==='Mara replied to you on your round.','a reply on my round does not say so: '+say(N(2)));
    check(say(N(3))==='Blake replied to you on Theo’s round.','a reply on Theo’s round does not name it: '+say(N(3)));
    check(say(N(4))==='Blake commented on Theo’s round at FIXTURE Oaks.','a followed comment does not name the round and the course: '+say(N(4)));
    check(say(N(5))==='Blake commented in a conversation you’re in.','an older server’s followed notice lost its sentence: '+say(N(5)));
    check(say(older.id)==='Theo commented on your round.','the own-round sentence moved: '+say(older.id));
    /* TEN / W6 (root, 2026-09-28) · the three conversation switches are
       Settings' now (W2's one Notifications section, owner C), read and written
       there through the same RPCs — so the inbox carries ONE door to them and
       no second set of switches. The revert-on-failure this block exercised
       belongs to Settings' switches (`phTalk_*`). */
    check(!document.querySelector('#shBody input[data-pref]'),'the inbox still carries its own notification switches');
    const door=document.querySelector('#shBody [data-inbox-prefs]');
    check(!!door && door.textContent.trim()==='Notification settings','the inbox lost its door to the notification settings');
    item.click();
    await until(()=>calls.some(c=>c[0]==='posted_round_thread' && c[1].p_focus===C2));
    const target=await until(()=>document.querySelector(`#rcptTalk #talk-c-${C2}.is-target`));
    check(calls.some(c=>c[0]==='mark_notifications_read' && (c[1].p_ids||[]).includes(N1)),'opening did not mark it read');
    check(document.activeElement===target && /opened from a notification/.test(target.getAttribute('aria-label')),'the notification did not open the exact comment');
    check(document.getElementById('shTitle').textContent==='Theo’s round','a notice opened a page that does not name its golfer');
    await until(()=>document.getElementById('hdrBellN').hidden);
    out.inbox='ok';

    /* ── 3b · the digest counts a round-thread comment on MY round ── */
    const mark=now-3*3600e3;
    await fetchHomeSocial();
    check(calls.some(c=>c[0]==='my_notifications' && c[1].p_limit===50 && !c[1].p_before),'the digest did not read the inbox');
    const men=dgMentions(mark);
    check(men.length===1 && men[0].who==='Theo Fixture' && men[0].e===null && men[0].gross===84 && men[0].rid===R2,'the digest counted the wrong comments: '+JSON.stringify(men));
    const asOf=window.dgAsOf; window.dgAsOf=mark;
    renderHomeDigest();
    check(/Theo Fixture chimed in on your 84/.test(document.getElementById('homeDigest').textContent),'the digest does not say who chimed in: '+document.getElementById('homeDigest').textContent);
    window.dgAsOf=asOf;
    fail.my_notifications={ message:'Failed to fetch' };
    await fetchHomeSocial();
    check(dgMentions(mark).length===0,'a failed inbox read invented a mention');
    out.digest='ok';

    /* ── 3c · the person card when the buddy list cannot be read (L-32) ── */
    if(saved.sb) saved.sb.rpc=rpc;   /* the module's client is the real object; its rpc answers from this stub for the walk */
    try{
      fail.my_friends={ message:'Failed to fetch' };
      await openTourCard(THEO);
      await until(()=>sheetOpen() && /Theo Fixture/.test(document.getElementById('shTitle').textContent));
      check(!document.getElementById('tcAdd') && !/Add buddy|Buddies|Requested/.test(document.getElementById('shBody').textContent),'a buddy list that could not be read offered Add buddy');
      check(/Block/.test(document.getElementById('shBody').textContent),'the rest of the card did not draw');
      friends=[{ profile_id:THEO, friendship_id:'50000000-0000-4000-8000-000000000001', status:'accepted', incoming:false }];
      await openTourCard(THEO);
      check(!document.getElementById('tcAdd') && document.getElementById('shBody').textContent.includes('Buddies'),'an existing buddy is not shown as one');
      friends=[];
      await openTourCard(THEO);
      check(document.getElementById('tcAdd') && document.getElementById('tcAdd').textContent==='Add buddy','a golfer who is not a buddy lost Add buddy');
    } finally {
      if(saved.sb){ if(sbHadRpc) saved.sb.rpc=sbRpc; else delete saved.sb.rpc; }
    }
    closeSheet();
    out.card='ok';

    /* ── 4 · the course's circle ── */
    openRoundReceipt(window.homeFeedRows[0], {});
    await until(()=>document.querySelector('#rcptTalk [data-talk-course]'));
    document.querySelector('#rcptTalk [data-talk-course]').click();
    await until(()=>document.querySelector('#shBody .cs-cp-best'));
    const body=document.getElementById('shBody');
    check(body.querySelector('.cs-cp-best .eyebrow').textContent==='Your circle best · gross','the best is not labelled as the circle');
    check(body.querySelector('.cs-cp-best').textContent.includes('Shared best') && body.querySelectorAll('.cs-cp-best [data-cp-round]').length===2,'a tie is not shown as shared, each with its round');
    check(/Not an official course record/.test(body.textContent) && /1 round without a tee we can prove is listed but never compared/.test(body.textContent),'the scope or the unknown-tee note is missing');
    check(!/League mate|course record\b(?! )/i.test(body.querySelector('.cs-cp-best').textContent),'forbidden wording in the best');
    check([...body.querySelectorAll('.cs-cp-p summary')].some(s=>s.textContent.includes('In your seasons')),'relation label missing');
    check(body.querySelector('.cs-cp-r').textContent.includes('White tees'),'history row does not carry its tee');
    const teeSel=body.querySelector('[data-cp-tee]'); teeSel.value='blue@72.3/131'; teeSel.dispatchEvent(new Event('change'));
    await until(()=>calls.some(c=>c[0]==='course_page' && c[1].p_tee==='blue@72.3/131') && document.querySelector('#shBody .cs-cp-best .cs-fig-l')?.textContent==='68');
    /* a nine: no best, and the sheet says why */
    const holesSel=document.querySelector('#shBody [data-cp-holes]');
    holesSel.innerHTML+='<option value="9">9 holes</option>'; holesSel.value='9'; holesSel.dispatchEvent(new Event('change'));
    await until(()=>/Nines aren’t compared/.test(document.getElementById('shBody').textContent));
    check(!document.querySelector('#shBody .cs-cp-best') && !document.querySelector('#shBody .cs-cp-mine'),'a nine drew a best');
    out.course='ok';

    /* ── 4b · the new doors never open a cached receipt; a friend with no league opens the facts ── */
    window.roundCache=window.roundCache||{};
    window.roundCache[GONE]={ id:GONE, gross:61, points:12, course_label:'Stale cache', played_on:'2026-09-01' };
    const opened=await csOpenPostedRound(GONE, { fresh:true });
    check(opened===false && !window.roundCache[GONE] && toasts.includes('That round isn’t available any more.'),'a voided/muted round opened from the cache');
    check(!/Stale cache/.test(document.getElementById('shBody').textContent) || !document.getElementById('sheet').classList.contains('open'),'the stale receipt is on screen');
    window.roundCache[R1]={ id:R1, gross:99, points:40, course_label:'Stale cache' };
    await csOpenPostedRound(R1, { fresh:true });
    await until(()=>document.querySelector('#rcptTalk .cs-talk'));
    check(calls.some(c=>c[0]==='round_card' && c[1].p_round===R1),'the league card was not asked');
    const sheetText=document.getElementById('shBody').textContent;
    check(/79/.test(document.querySelector('#rcptHero').textContent) && !/Stale cache/.test(sheetText),'the receipt did not come from the gate');
    check(!document.querySelector('#shBody .rcpt-figs .p'),'points shown to a golfer with no shared league');
    check(!window.roundCache[R1] || window.roundCache[R1].points!==40,'the stale cached card survived');
    check(document.getElementById('shTitle').textContent==='Theo’s round','the gate’s page does not name its golfer');

    /* ── 5 · deploy skew: nothing drawn that the server cannot answer ── */
    skew=true; window.csTalkSocial={};
    await csBadgeRefresh();
    check(document.getElementById('hdrBell').hidden,'the bell stayed on a server without the inbox');
    check(!(await csTalkFetch([R1])),'the doors read succeeded on a skewed server');
    renderHomeFeed();
    const card2=await until(()=>document.querySelector('#homeFeed [data-hfr="0"]'));
    check(!card2.querySelector('[data-hftalk]') && !card2.querySelector('[data-hfcourse]') && !card2.querySelector('[data-talk-peek],[data-talk-line]'),'doors drawn without the server');
    openRoundReceipt(window.homeFeedRows[0], {});
    await until(()=>calls.filter(c=>c[0]==='posted_round_thread').length>=4 && document.getElementById('rcptTalk'));
    await new Promise(r=>setTimeout(r,120));
    check(document.getElementById('rcptTalk').innerHTML==='','a conversation was drawn on a skewed server');
    out.skew='ok';
  } finally {
    closeSheet();
    window.sb=saved.sb; if(window.CS) window.CS.user=saved.user; state.demo=saved.demo; window.homeFeedRows=saved.rows;
    window.toast=realToast; window.csTalkSocial={}; window.__csTalkUi=undefined; window.dgAsOf=saved.dgAsOf;
    if(feed.length!==saved.feed.length || feed.some((f,i)=>f!==saved.feed[i])){ feed.splice(0, feed.length, ...saved.feed); try{ renderFeed(); }catch(_){} }
    try{ renderHomeFeed(); }catch(_){}
  }
  out.toasts=toasts;
  return out;
})()
