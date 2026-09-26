/* D391 · the web half of the connected blend, walked in a real browser against a
   STUBBED rpc layer. Every name below is a labelled fixture, none an account's.

   Serve this checkout, open `/?cs_home_state=round_evening&exit`, and evaluate
   with web-verify.mjs:
     node tools/web-verify.mjs --url 'http://127.0.0.1:8791/?cs_home_state=round_evening&exit' \
       --widths 1440,390 --eval "$(cat tests/social-course-browser.js)"

   Covers: the Home wire's two doors; the receipt's conversation (escaping,
   reply target, a FAILED send that keeps the draft and its key, the retry that
   lands, follow); the inbox (badge, sentence, open-at-comment, mark read, a
   preference that fails and reverts); the course's circle (tie, filters, the
   honest scope label); and deploy skew (no bell, no conversation, no doors). */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const until=(f,ms=6000)=>new Promise((res,rej)=>{ const t=Date.now(); (function tick(){ let v; try{ v=f(); }catch(_){} if(v) return res(v); if(Date.now()-t>ms) return rej(new Error('timeout: '+f)); setTimeout(tick,40); })(); });
  const tick=()=>new Promise(r=>setTimeout(r,30));
  await until(()=>document.getElementById('homeFeed'));
  try{ enterApp(); switchView('home'); }catch(_){}
  document.querySelectorAll('.onboard').forEach(d=>d.remove());
  const out={};

  const ME='00000000-0000-4000-8000-0000000000a1', THEO='00000000-0000-4000-8000-0000000000a2', MARA='00000000-0000-4000-8000-0000000000a3';
  const R1='10000000-0000-4000-8000-000000000001', C1='20000000-0000-4000-8000-000000000001', C2='20000000-0000-4000-8000-000000000002';
  const N1='30000000-0000-4000-8000-000000000001';
  const person=(id,name)=>({ id, name, marker:'saguaro', handle:null });
  const now=Date.now(), iso=ms=>new Date(now-ms).toISOString();

  /* ── the stub: rpc by name, everything else a harmless chain ── */
  const calls=[]; const fail={}; let skew=false;
  let comments=[
    { id:C1, round_id:R1, parent_id:null, root_id:null, reply_to:null, author:person(THEO,'Theo Fixture'),
      body:'Same ball? <b>witness</b> & "quotes"', created_at:iso(7200e3), origin:'round', is_mine:false, can_reply:true },
    { id:C2, round_id:R1, parent_id:C1, root_id:C1, reply_to:{ id:C1, name:'Theo Fixture' }, author:person(MARA,'Mara Fixture'),
      body:'Caught the left edge.', created_at:iso(720e3), origin:'round', is_mine:false, can_reply:true },
    { id:'20000000-0000-4000-8000-000000000009', round_id:R1, parent_id:null, root_id:null, reply_to:null, author:person(MARA,'Mara Fixture'),
      body:'League chatter', created_at:iso(600e3), origin:'board', is_mine:false, can_reply:false },
  ];
  let thread={ state:'none', following:false, muted:false };
  let notes=[{ id:N1, kind:'reply', created_at:iso(720e3), read:false, read_at:null, actor:person(MARA,'Mara Fixture'),
               round_id:R1, comment_id:C2, excerpt:'Caught the left edge.', course_name:'FIXTURE Oaks', round_owner_name:'You',
               link:{ kind:'round_comment', round_id:R1, comment_id:C2, web:`/?round=${R1}&comment=${C2}` } }];
  let prefs={ own_round:true, replies:true, followed:true };
  const coursePage=(tee,holes)=>({ ok:true,
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
  const SKEW={ code:'PGRST202', message:'Could not find the function public.x in the schema cache' };
  const rpc=async(name,args)=>{
    calls.push([name, JSON.parse(JSON.stringify(args||{}))]);
    await tick();
    const D391=['posted_round_thread','add_posted_round_comment','set_round_thread_state','notification_badge','my_notifications',
                'mark_notifications_read','social_notify_prefs','set_social_notify_prefs','course_page','posted_rounds_social','report_content','remove_posted_round_comment'];
    if(skew && D391.includes(name)) return { data:null, error:SKEW };
    if(fail[name]){ const e=fail[name]; delete fail[name]; return { data:null, error:e }; }
    switch(name){
      case 'posted_rounds_social': return { data:{ items:(args.p_rounds||[]).filter(id=>id===R1).map(id=>({ round_id:id, comment_count:comments.length, can_comment:true, thread_state:thread.state,
        course:{ api_course_id:'fx-1', name:'FIXTURE Oaks', circle_golfers:3, faces:[person(THEO,'Theo Fixture'), person(MARA,'Mara Fixture')] } })) }, error:null };
      case 'posted_round_thread': return { data:{ ok:true, round:{ id:R1, owner:person(ME,'You Fixture'), is_mine:true, gross:84, holes:18, played_on:'2026-09-20',
          course:{ api_course_id:'fx-1', name:'FIXTURE Oaks', label:'FIXTURE Oaks · White', tee_name:'White', tee_key:'white@70.1/124' }, photo_path:null },
          can_comment:true, comment_block_reason:null, thread, notify_prefs:prefs, count:comments.length, comments }, error:null };
      case 'add_posted_round_comment': {
        const c={ id:crypto.randomUUID(), round_id:R1, parent_id:args.p_parent||null, root_id:args.p_parent?C1:null,
          reply_to: args.p_parent ? { id:args.p_parent, name:'Theo Fixture' } : null, author:person(ME,'You Fixture'),
          body:args.p_body, created_at:new Date().toISOString(), origin:'round', is_mine:true, can_reply:true };
        comments=comments.concat([c]);
        return { data:{ ok:true, replayed:false, comment:c, count:comments.length }, error:null }; }
      case 'set_round_thread_state': thread={ state:args.p_state, following:args.p_state==='following', muted:args.p_state==='muted' }; return { data:{ ok:true, state:args.p_state }, error:null };
      case 'notification_badge': return { data:{ unread:notes.filter(n=>!n.read).length }, error:null };
      case 'my_notifications': return { data:{ ok:true, unread:notes.filter(n=>!n.read).length, items:notes, next_before:null }, error:null };
      case 'mark_notifications_read': notes.forEach(n=>{ if(args.p_all || (args.p_ids||[]).includes(n.id)) n.read=true; }); return { data:{ ok:true, unread:notes.filter(n=>!n.read).length }, error:null };
      case 'social_notify_prefs': return { data:prefs, error:null };
      case 'set_social_notify_prefs': return { data:prefs, error:null };
      case 'course_page': return { data:coursePage(args.p_tee, args.p_holes), error:null };
      default: return { data:null, error:{ message:'not in this fixture' } };
    }
  };
  const chain=new Proxy(function(){}, { get:(t,k)=> k==='then' ? (res=>res({ data:null, error:null })) : chain, apply:()=>chain });
  const saved={ sb:window.sb, user:window.CS && window.CS.user, demo:state.demo, rows:window.homeFeedRows };
  window.sb=new Proxy({}, { get:(t,k)=> k==='rpc' ? rpc : chain });
  window.CS=window.CS||{}; window.CS.user={ id:ME }; window.CS.profile=Object.assign({}, window.CS.profile||{}, { id:ME, display_name:'You Fixture', marker:'saguaro' });
  state.demo=false;
  const toasts=[]; const realToast=window.toast; window.toast=m=>{ toasts.push(m); };

  try{
    /* ── 1 · the Home wire's two doors ── */
    window.homeFeedRows=[{ round_id:R1, profile_id:THEO, golfer:'Theo Fixture', marker:'saguaro', gross:79, pvi:1.2, course:'FIXTURE Oaks',
      played_on:new Date().toISOString().slice(0,10), created_at:new Date().toISOString(), is_me:false, photo_path:null, photo_url:null }];
    window.csTalkSocial={};
    const okFetch=await csTalkFetch([R1]);
    check(okFetch,'posted_rounds_social did not answer');
    renderHomeFeed();
    const card=await until(()=>document.querySelector('#homeFeed [data-hfr="0"]'));
    const talkBtn=card.querySelector('[data-hftalk]'), courseBtn=card.querySelector('[data-hfcourse]');
    check(talkBtn && /3 comments, open the conversation/.test(talkBtn.getAttribute('aria-label')),'no labelled conversation door: '+(talkBtn&&talkBtn.getAttribute('aria-label')));
    check(courseBtn && courseBtn.textContent.includes('Theo and Mara have played here'),'no course door naming the circle: '+(courseBtn&&courseBtn.textContent));
    out.doors='ok';

    /* ── 2 · the receipt's conversation ── */
    openRoundReceipt(window.homeFeedRows[0], { focusTalk:true });
    await until(()=>document.querySelector('#rcptTalk .cs-talk')); const slot=document.getElementById('rcptTalk');
    const first=slot.querySelector(`#talk-c-${C1} .cs-talk-text`);
    check(first && first.textContent==='Same ball? <b>witness</b> & "quotes"' && !first.querySelector('b'),'a comment was not rendered as text');
    check(slot.querySelector(`#talk-c-${C2}`).classList.contains('is-reply') && slot.querySelector(`#talk-c-${C2} .cs-talk-to`).textContent==='To Theo','the reply is not under its root');
    const board=[...slot.querySelectorAll('.cs-talk-c')].find(a=>a.textContent.includes('League chatter'));
    check(board && !board.querySelector('[data-talk-reply]'),'a league-board comment offered a reply');
    check(slot.querySelector('#talkHead').textContent.includes('3'),'the head does not count the thread');
    check(slot.querySelector('label[for="talkDraft"]'),'the draft has no label');
    check(slot.querySelector('#talkErr').getAttribute('role')==='alert','the error line is not announced');

    /* reply target, then a failed send: the draft, the target and the key stay */
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
    const firstKey=calls.filter(c=>c[0]==='add_posted_round_comment')[0][1].p_client_id;
    slot.querySelector('#talkSend').click();
    await until(()=>document.querySelector('#rcptTalk .cs-talk-c.is-target'));
    const sends=calls.filter(c=>c[0]==='add_posted_round_comment');
    check(sends.length===2 && sends[1][1].p_client_id===firstKey && sends[1][1].p_parent===C1,'the retry did not reuse its key and target');
    const slot2=document.querySelector('#rcptTalk');
    check(slot2.querySelector('#talkDraft').value==='','the draft survived a landed comment');
    const mineRow=slot2.querySelector('.cs-talk-c.is-target');
    check(mineRow.querySelector('.cs-talk-text').textContent==='Saturday again? <script>x</script>' && !mineRow.querySelector('script'),'the new comment is not text');
    check(document.activeElement===mineRow,'the new comment did not take focus');
    check(mineRow.querySelector('[data-talk-remove]') && !mineRow.querySelector('[data-talk-report]'),'my own comment offers report, or no remove');
    out.thread='ok';

    /* follow */
    slot2.querySelector('[data-talk-follow]').click();
    await until(()=>document.querySelector('#rcptTalk [data-talk-follow][aria-pressed="true"]'));
    check(document.querySelector('#talkHint').textContent==='Updates from this conversation are on.','the hint did not follow the follow');

    /* ── 3 · the inbox ── */
    await csBadgeRefresh();
    const bell=document.getElementById('hdrBell');
    check(!bell.hidden && bell.getAttribute('aria-label')==='Notifications, 1 unread' && document.getElementById('hdrBellN').textContent==='1','the bell is not counting');
    bell.click();
    const item=await until(()=>document.querySelector('#shBody [data-inbox]'));
    check(item.textContent.includes('Mara replied to your comment.') && item.textContent.includes('“Caught the left edge.”') && item.textContent.includes('Unread'),'the inbox sentence is wrong: '+item.textContent.replace(/\s+/g,' '));
    /* a preference that fails reverts */
    const pref=document.querySelector('#shBody input[data-pref="followed"]');
    fail.set_social_notify_prefs={ message:'Failed to fetch' };
    pref.click();
    await until(()=>!pref.disabled && pref.checked===true);
    item.click();
    const target=await until(()=>document.querySelector(`#rcptTalk #talk-c-${C2}.is-target`));
    check(calls.some(c=>c[0]==='mark_notifications_read' && (c[1].p_ids||[]).includes(N1)),'opening did not mark it read');
    check(document.activeElement===target && /opened from a notification/.test(target.getAttribute('aria-label')),'the notification did not open the exact comment');
    await until(()=>document.getElementById('hdrBellN').hidden);
    out.inbox='ok';

    /* ── 4 · the course's circle ── */
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
    out.course='ok';

    /* ── 5 · deploy skew: nothing drawn that the server cannot answer ── */
    skew=true; window.csTalkSocial={};
    await csBadgeRefresh();
    check(document.getElementById('hdrBell').hidden,'the bell stayed on a server without the inbox');
    check(!(await csTalkFetch([R1])),'the doors read succeeded on a skewed server');
    renderHomeFeed();
    const card2=await until(()=>document.querySelector('#homeFeed [data-hfr="0"]'));
    check(!card2.querySelector('[data-hftalk]') && !card2.querySelector('[data-hfcourse]'),'doors drawn without the server');
    openRoundReceipt(window.homeFeedRows[0], {});
    await until(()=>calls.filter(c=>c[0]==='posted_round_thread').length>=4 && document.getElementById('rcptTalk'));
    await new Promise(r=>setTimeout(r,120));
    check(document.getElementById('rcptTalk').innerHTML==='','a conversation was drawn on a skewed server');
    out.skew='ok';
  } finally {
    closeSheet();
    window.sb=saved.sb; if(window.CS) window.CS.user=saved.user; state.demo=saved.demo; window.homeFeedRows=saved.rows;
    window.toast=realToast; window.csTalkSocial={};
    try{ renderHomeFeed(); }catch(_){}
  }
  out.toasts=toasts;
  return out;
})()
