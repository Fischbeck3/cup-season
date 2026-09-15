/* D363 · "Play with <name>" carries the person, and a course search answers
   above the keyboard (F7 / F8) — on the desk, signed out, no writes.
   1 · the three ways, the round fork, and the head-to-head REVIEW render with
       the real closing date, the basis and the invitation before any stake;
       the no-stake path is complete and the stake field appears only on ask.
   2 · the shared Sunday rule and the seating rule (pure).
   3 · a search answer that lands outside the visual viewport is revealed —
       the input is brought to the top — and one already in view is left alone. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const out={};
  const q=s=>document.querySelector(s);
  const vis=el=>{ if(!el) return false; const r=el.getBoundingClientRect(); return r.width>0 && r.height>0; };

  /* 1 · the three ways */
  csAskTheLength('p-alex', 'Alex Rivera');
  await new Promise(r=>setTimeout(r,80));
  const rows=[...document.querySelectorAll('#shBody [data-csln]')];
  out.head=(q('#shTitle')||q('.sheet.open h2')||q('.sheet.open .sh-title'))?.textContent?.trim()||document.querySelector('.sheet.open')?.textContent.slice(0,40);
  out.ways=rows.map(b=>b.dataset.csln);
  check(rows.length===3 && out.ways.join(',')==='aRound,headToHead,aSeason','three ways in order: '+out.ways.join(','));
  check(rows.every(vis),'every way is visible');
  check(rows.some(b=>/Play a round/.test(b.textContent)) && rows.some(b=>/Go head to head/.test(b.textContent)) && rows.some(b=>/Start a season/.test(b.textContent)),'the owner’s words');
  check(!/Saturday|One week/.test(document.querySelector('.sheet.open')?.textContent||''),'no weekday, no “one week”');

  /* the round fork */
  rows[0].click();
  await new Promise(r=>setTimeout(r,120));
  out.fork=[q('#csrw-now')?.textContent.trim().slice(0,3), q('#csrw-plan')?.textContent.trim().slice(0,15)];
  check(q('#csrw-now') && q('#csrw-plan') && vis(q('#csrw-now')) && vis(q('#csrw-plan')),'the fork: Now / On the schedule');
  closeSheet();

  /* the head-to-head review */
  csAskTheLength('p-alex', 'Alex Rivera');
  await new Promise(r=>setTimeout(r,80));
  [...document.querySelectorAll('#shBody [data-csln]')].find(b=>b.dataset.csln==='headToHead').click();
  await new Promise(r=>setTimeout(r,120));
  const closes=q('#csco-closes')?.textContent||'';
  out.closes=closes;
  const expect=csDowMonDay(csCalloutDefaultClose());
  check(closes==='Closes '+expect,'the real closing date: '+closes+' vs '+expect);
  check(/^Closes Sun /.test(closes),'it closes on a Sunday');
  const body=q('#shBody')?.textContent||'';
  check(/playing HCP/.test(body) && /all square/.test(body),'the basis is stated');
  check(/Alex gets a note/.test(body) && /Nothing is sent until/.test(body),'the invitation state is stated');
  check(/nothing scores toward a season/.test(body),'no points, said');
  const order=[body.indexOf('Closes'), body.indexOf('playing HCP'), body.indexOf('Alex gets a note'), body.indexOf("What's on it")];
  check(order.every((v,i)=>v>=0 && (i===0 || v>order[i-1])),'date, basis, invitation, THEN the stake: '+order.join(','));
  check(q('#csco-terms')?.hidden===true,'no stake field until asked');
  check(q('[data-csstake="0"]')?.getAttribute('aria-pressed')==='true','no stake is the default');
  check(vis(q('#csco-send')),'Send it is visible on the no-stake path');
  q('[data-csstake="1"]').click();
  await new Promise(r=>setTimeout(r,50));
  check(q('#csco-terms')?.hidden===false && q('[data-csstake="1"]')?.getAttribute('aria-pressed')==='true','asking for a pride bet reveals the words field');
  check(!/\$|dollars|cents/.test(body),'no money noun');
  closeSheet();

  /* 2 · the shared rules, pure */
  out.sunday=['2026-09-05','2026-09-07','2026-09-11'].map(csCalloutDefaultClose);
  check(out.sunday.join(',')==='2026-09-13,2026-09-13,2026-09-20','the Sunday rule: '+out.sunday.join(','));
  const roster=[{n:'You',i:12,pid:'p-me',me:true,locked:true}], sel=[0];
  out.seat=[csPreselectInto(roster,sel,{pid:'p-alex',name:'Alex Rivera'},9.8,{active:false}), csPreselectInto(roster,sel,{pid:'p-alex',name:'Alex Rivera'},9.8,{active:false}), sel.length];
  check(out.seat.join(',')==='seated,alreadySeated,2','seated once: '+out.seat.join(','));

  /* 3 · the reveal — a search answer outside the visual viewport */
  /* a scroller the height of the visual viewport, pinned to its top — the
     tee sheet's and the composer's own shape — with the field a screen below
     its fold, the way it sits once a keyboard has eaten the bottom half */
  const vv=window.visualViewport; const vtop=(vv?vv.offsetTop:0); const bottom=vtop+(vv?vv.height:window.innerHeight);
  const scroller=document.createElement('div');
  scroller.style.cssText=`position:fixed; left:0; top:${vtop}px; width:100%; height:${bottom-vtop}px; overflow:auto; z-index:9999; background:var(--bg0)`;
  const pad=document.createElement('div'); pad.style.height=(bottom-vtop+300)+'px'; scroller.appendChild(pad);
  const input=document.createElement('input'); input.className='f'; input.placeholder='Search a course';
  const dd=document.createElement('div'); dd.className='coursedd'; dd.style.display='block';
  dd.innerHTML='<button type="button" data-ci="0"><b>Bajamar Ocean Front</b><span>Ensenada · 3 tees</span></button>';
  scroller.appendChild(input); scroller.appendChild(dd);
  const tail=document.createElement('div'); tail.style.height=(bottom-vtop)+'px'; scroller.appendChild(tail);
  document.body.appendChild(scroller);
  const before=input.getBoundingClientRect().top;
  check(before>bottom,'the fixture answer starts below the visual viewport: '+before+' > '+bottom);
  const moved=csRevealSearch(input, dd);
  await new Promise(r=>setTimeout(r,700));   /* smooth scroll settles */
  const after=input.getBoundingClientRect(); const first=dd.querySelector('button').getBoundingClientRect();
  out.reveal={ moved, inputTop:Math.round(after.top), firstRowBottom:Math.round(first.bottom), viewportTop:vtop, viewportBottom:Math.round(bottom) };
  check(moved===true,'it moved');
  check(after.top>=vtop-2 && after.top<=vtop+8+2,'the input sits at the top of the visual viewport: '+after.top);
  check(first.bottom<=bottom,'the first complete row is inside the visual viewport');
  check(document.activeElement!==input,'focus untouched (never focused here)');
  const again=csRevealSearch(input, dd);
  check(again===false,'already in view: left alone');
  scroller.remove(); window.scrollTo(0,0);

  return out;
})()
