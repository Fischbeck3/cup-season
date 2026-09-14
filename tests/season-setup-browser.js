/* MW-04 + MW-06 · the season page leads with the table and names its rooms;
   the wizard says which step you are on and what a preset sets. Serve this
   checkout, open /?exit, evaluate with web-verify.mjs at 390, 320 and 1440.
   Nothing is created: the lock/create controls are never clicked. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const until=async(t,label)=>{ for(let i=0;i<120;i++){ if(t()) return; await new Promise(r=>setTimeout(r,20)); } throw new Error(label); };
  const saved={ demo:state.demo, wiz:state.wiz, preset:state.preset, cap:state.cap, floor:state.floor,
                structure:state.structure, capExact:state.capExact };
  const out={ width: innerWidth };
  try{
    /* ── MW-04 · the season's rooms are reachable, and the table leads ────── */
    switchView('hub');
    await new Promise(r=>setTimeout(r,60));
    window.renderSeasonJump();
    const jump=document.getElementById('seasonJump');
    check(!!jump,'MW-04: the season page has no room rail');
    const names=Array.from(jump.querySelectorAll('[data-jump]')).map(b=>b.textContent.trim());
    check(names.join(',')==='Standings,Money,Board,Rules','MW-04: the rail does not name the rooms: '+names.join(','));
    /* every offered room is a pane that exists — a rail may not name a door
       that does not open (L-32) */
    for(const b of jump.querySelectorAll('[data-jump]'))
      check(!!document.getElementById('room-'+b.dataset.jump),'MW-04: the rail offers a room that is not on the page: '+b.dataset.jump);
    const shown=getComputedStyle(jump).display!=='none';
    if(innerWidth<960){
      check(shown,'MW-04: the phone has no way to reach the other rooms');
      check(Array.from(jump.querySelectorAll('button')).every(b=>b.getBoundingClientRect().height>=36-1),'MW-04: a room control is too small');
      /* and it actually moves: the pane is asked to scroll to itself */
      let scrolled=null; const pane=document.getElementById('room-pot');
      const realScroll=pane.scrollIntoView; pane.scrollIntoView=function(){ scrolled='pot'; };
      try{ jump.querySelector('[data-jump="pot"]').click(); await until(()=>scrolled,'MW-04: Money did not go to the money'); }
      finally{ pane.scrollIntoView=realScroll; }
      check(document.getElementById('roomGrid').dataset.room==='pot','MW-04: the room did not change');
    } else {
      check(!shown,'MW-04: the desk shows the rail as well as its sidebar list');
      check(!!document.querySelector('#deskMenu [data-seg]'),'the desk lost its own room list');
    }
    /* the table before the graphic of the table, on a phone */
    const grid=document.querySelector('#homeSeason .homegrid');
    if(grid){
      const climb=document.getElementById('climb')?.closest('.homegrid > div');
      const table=document.getElementById('standings')?.closest('.homegrid > div');
      if(climb && table && innerWidth<960){
        const box=el=>el.getBoundingClientRect();
        check(box(table).top<=box(climb).top,'MW-04: the climb still sits above the standings on a phone');
      }
      out.tableFirst = innerWidth<960;
    }

    /* ── MW-06 · the step has a name, and a preset says what it sets ──────── */
    state.demo=true;                       /* the wizard's own demo dials; no league is touched */
    state.wiz=0; renderWizard();
    const stepName=()=>document.getElementById('wizStepName').textContent.trim();
    check(/^Step 1 of 3 · The league$/.test(stepName()),'MW-06: step 1 is not named: '+stepName());
    state.wiz=1; renderWizard();
    check(/^Step 2 of 3 · The rules$/.test(stepName()),'MW-06: step 2 is not named: '+stepName());
    state.wiz=2; renderWizard();
    check(/^Step 3 of 3 · Review$/.test(stepName()),'MW-06: step 3 is not named: '+stepName());
    const dots=document.querySelectorAll('.wizdots i');
    check(Array.from(dots).every(d=>d.classList.contains('on')),'the rail stopped tracking the step');

    const lead=i=>document.querySelector('[data-preset-lead="'+i+'"]').textContent.trim();
    check(lead(0)==='Every round counts · no monthly minimum.','MW-06: Casual does not say what it sets: '+lead(0));
    check(lead(1)==='Your best three each month count · two-round monthly minimum.','MW-06: Standard does not say what it sets: '+lead(1));
    check(lead(2)==='Your best two each month count · three-round monthly minimum.','MW-06: Cutthroat does not say what it sets: '+lead(2));
    for(const t of ['guardrail','screws','Tight.']) check(!document.querySelector('.preset').closest('.card, div').textContent.includes(t),'MW-06: the mood copy is still on a preset: '+t);
    out.presets=[lead(0),lead(1),lead(2)];

    /* the card agrees with what the preset WRITES — read from the same ladder */
    for(let i=0;i<3;i++){
      const capWord = CAP_DB[PRESETS[i].cap]==null ? null : csWord(CAP_DB[PRESETS[i].cap]);
      if(capWord) check(lead(i).includes('best '+capWord),'MW-06: preset '+i+' names a cap it does not set');
      if(PRESETS[i].floor) check(lead(i).includes(csWord(PRESETS[i].floor)+'-round'),'MW-06: preset '+i+' names a minimum it does not set');
    }
    /* choosing one still writes the dials it advertises, and stays editable */
    const before={ cap:state.cap, floor:state.floor };
    const realToast=toast; toast=()=>{};
    try{ document.querySelector('.preset[data-p="2"]').click(); } finally { toast=realToast; }
    check(state.cap===PRESETS[2].cap && state.floor===PRESETS[2].floor,'MW-06: the preset stopped writing its own dials');
    check(!!document.getElementById('capSeg') || !!document.querySelector('#structSeg'),'MW-06: the dials below the presets are gone');
    state.cap=before.cap; state.floor=before.floor;
    check(document.documentElement.scrollWidth<=innerWidth,'the setup page overflows at this width');
    out.passed=true; return out;
  } finally {
    state.demo=saved.demo; state.wiz=saved.wiz; state.preset=saved.preset; state.cap=saved.cap;
    state.floor=saved.floor; state.structure=saved.structure; state.capExact=saved.capExact;
    try{ renderWizard(); }catch(_){}
  }
})()
