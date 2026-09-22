/* F13 · a birdie is a birdie — the refusals, on the desk.
   Every check here is something the producer must NOT do: claim a moment off
   an estimated par, fire twice for one commit, speak during hydration or a
   remote echo, or replay a reward through undo and re-entry. */
(function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const out={};

  /* the arithmetic */
  check(csHoleMoment(3,4,true)==='birdie','one under is a birdie');
  check(csHoleMoment(3,5,true)==='eagle','two under is an eagle');
  check(csHoleMoment(1,4,true)==='eagle','three under is still called an eagle');
  check(csHoleMoment(4,4,true)===null,'a par is not a moment');
  check(csHoleMoment(5,4,true)===null,'a bogey is not a moment');

  /* an estimated par claims nothing */
  check(csHoleMoment(3,5,false)===null,'an estimated par declared an eagle');
  check(csHoleMoment(3,null,true)===null,'a missing par declared a moment');
  check(csHoleMoment(null,4,true)===null,'an empty cell declared a moment');
  check(csHoleMoment(0,4,true)===null,'a zero declared an eagle');

  /* one commit speaks once */
  let l=csMomentLedger();
  check(l.commit('me',7,1,3,4,true)==='birdie','the committed birdie did not fire');
  check(l.commit('me',7,1,3,4,true)===null,'the same commit fired twice');

  /* hydration and sync are silent, but the tally still knows */
  l=csMomentLedger();
  l.seen('me',7,1,3,4,true);
  check(l.commit('me',7,1,3,4,true)===null,'hydration replayed the reward');
  check(l.tallyLine('me')==='1 birdie','the hydrated birdie is missing from the tally');

  /* a correction revises rather than replaying */
  l=csMomentLedger();
  check(l.commit('me',7,1,3,4,true)==='birdie','birdie');
  check(l.commit('me',7,2,5,4,true)===null,'a bogey was celebrated');
  check(l.tallyLine('me')===null,'the corrected birdie stayed in the tally');
  check(l.commit('me',7,3,3,4,true)==='birdie','a genuine re-entry did not stand');
  check(l.tallyLine('me')==='1 birdie','the re-entry double-counted');

  /* the tally is facts, per golfer, and never a streak claim */
  l=csMomentLedger();
  l.commit('me',2,1,3,5,true); l.commit('me',7,1,3,4,true); l.commit('me',9,1,4,4,true);
  l.commit('galen',7,1,3,4,true);
  out.tally=l.tallyLine('me');
  check(out.tally==='1 eagle · 1 birdie','the tally is wrong: '+out.tally);
  check(l.tallyLine('galen')==='1 birdie','a partner’s card leaked into mine');
  check(l.tallyLine('nobody')===null,'a golfer with no holes got a tally');
  check(!/heat/i.test(out.tally),'the tally claimed a streak');

  /* plurals */
  l=csMomentLedger();
  [2,5].forEach(h=>l.commit('me',h,1,3,5,true));
  [7,9,11].forEach(h=>l.commit('me',h,1,3,4,true));
  out.plural=l.tallyLine('me');
  check(out.plural==='2 eagles · 3 birdies','plurals: '+out.plural);

  out.passed=true;
  return JSON.stringify(out);
})()
