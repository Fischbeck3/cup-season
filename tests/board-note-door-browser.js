/* The schedule note is a door (owner report, 2026-09-17): a system post that
   carries scheduled_round_id renders as an openable row and opens the round
   sheet; a settlement note keeps its scorecard door; a bare note stays flat.
   And ONE surviving league note prints its own sentence, not "1 league note". */
(function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const SRID='bcb72a83-0000-4000-8000-000000000001', LRID='a48299ed-0000-4000-8000-000000000002';
  /* the row renderer */
  const plan = sysRowHtml({ sys:true, txt:'Galen put a round on the schedule — Sat Sep 19 · 2:10PM · Papago', srid:SRID }, 0, 't-');
  check(plan.includes('data-planrow="'+SRID+'"') && plan.includes('open the round'), 'a schedule note renders as a door to the round');
  const settle = sysRowHtml({ sys:true, txt:'Match settled', lrid:LRID }, 1, 't-');
  check(settle.includes('data-card="'+LRID+'"') && !settle.includes('data-planrow'), 'a settlement note keeps the scorecard door');
  const flat = sysRowHtml({ sys:true, txt:'Sandbaggers close the gap' }, 2, 't-');
  check(!flat.includes('data-planrow') && !flat.includes('data-card'), 'a bare note stays flat');
  /* the delegated click opens the sheet */
  let opened=null; const prev=window.openRoundSheet; window.openRoundSheet=(id)=>{ opened=id; };
  const host=document.createElement('div'); host.innerHTML=plan; document.body.appendChild(host);
  host.querySelector('[data-planrow]').click();
  window.openRoundSheet=prev; host.remove();
  check(opened===SRID, 'tapping the note opens the round sheet');
  /* one note says its sentence */
  const one = csNotesLine({ names:['Who’s the bitch?'], count:1, body:'Galen put a round on the schedule — Sat Sep 19 · 2:10PM · Papago Golf Course · Blue', srid:SRID });
  check(one.startsWith('Galen put a round on the schedule'), 'one note prints its own sentence');
  check(csNotesLine({ names:['A','B'], count:2 })==='A & B · 2 league notes', 'a stack still counts');
  return JSON.stringify({ passed:true });
})()
