/* WA3 · the You credential tells the truth about a count it may not have yet.
   Serve this checkout, open /?exit, evaluate with web-verify.mjs. No writes. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const saved={ demo:state.demo, user:window.CS.user, profile:window.CS.profile, career:window.career, render:window.renderCareer };
  const out={};
  const fig=label=>{
    const f=Array.from(document.querySelectorAll('#youFigs .cfig'))
      .map(c=>[c.querySelector('small')?.textContent||'', c.querySelector('b')?.textContent||''])
      .find(([l])=>l===label);
    return f ? f[1] : null;
  };
  try{
    state.demo=false;
    window.CS.user={ id:'a0000000-0000-4000-8000-000000000099' };
    window.renderCareer=()=>{};

    /* 1 · ESTABLISHED index, career not back yet — the count is unknown, not 0 */
    window.CS.profile={ display_name:'Audit', handle:'audit', index_current:11.4, index_source:'engine' };
    window.career=null;
    window.refreshWhoChip();
    check(fig('Handicap index')==='11.4','the index cell is missing');
    check(fig('Rounds')==='—','WA3: an unread career printed a zero: '+fig('Rounds'));
    out.beforeLoad=fig('Rounds');

    /* 2 · the count arrives — the credential must catch up even though the
       index is established (the old refresh only fired while it was building) */
    window.career={ rounds:12, rows:[], recent:[] };
    window.refreshWhoChip();
    check(fig('Rounds')==='12','WA3: the credential did not take the career count');
    out.afterLoad=fig('Rounds');

    /* 3 · a TRUE empty history is a zero, and says zero */
    window.career={ rounds:0, rows:[], recent:[] };
    window.refreshWhoChip();
    check(fig('Rounds')==='0','WA3: a real empty history stopped reading zero');

    /* 4 · a FAILED read is not a zero either */
    window.career=null;
    window.refreshWhoChip();
    check(fig('Rounds')==='—','WA3: a failed read printed a zero');

    /* 5 · and a provisional profile behaves the same way */
    window.CS.profile={ display_name:'Audit', handle:'audit', index_current:null };
    window.career={ rounds:2, rows:[], recent:[] };
    window.refreshWhoChip();
    check(fig('Handicap index')===null,'a building index printed a figure');
    check(fig('Rounds')==='2','WA3: a provisional profile lost its count');
    out.passed=true; return out;
  } finally {
    state.demo=saved.demo; window.CS.user=saved.user; window.CS.profile=saved.profile;
    window.career=saved.career; window.renderCareer=saved.render;
  }
})()
