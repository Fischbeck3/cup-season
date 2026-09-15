/* MW-02 / D360 audit · one fact, one place on Home. Pure producers, no account. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const A='a0000000-0000-4000-8000-00000000000a', B='a0000000-0000-4000-8000-00000000000b';
  const chapter=(key,league)=>({ key, tier:'chapter', headline:'You are the one to catch.', eyebrow:'X · WEEK 3 OF 12', league_id:league, at:null, route:'season', action:'Open the season' });
  const lead={ key:'clash:1', tier:'closing', headline:'Galen has today to answer your 89.', league_id:null, human_subject:true };
  window.homeDispatch={ me:{ memberships:[{ league_id:A, name:'Fellas' },{ league_id:B, name:'Sunday Cup' }] }, items:[] };
  const w=csWireArrange(lead,[chapter('chapter:a',A), chapter('chapter:b',B), chapter('chapter:a2',A)]);
  const keys=w.deck.map(i=>i.key);
  check(keys.join(',')==='chapter:a,chapter:b','same sentence, same league is one line; different leagues are two: '+keys);
  check(w.ctx.get('chapter:a')==='Fellas' && w.ctx.get('chapter:b')==='Sunday Cup','the repeated sentence does not name its league: '+JSON.stringify([...w.ctx]));
  check(!w.ctx.has('clash:1'),'a sentence said once needs no league');
  /* the season summary yields when the column says the standing */
  check(csSaysStanding(chapter('chapter:a',A)) && !csSaysStanding(lead),'saysStanding is keyed on the family');
  window.__standingSaid=true; check(csMeSeasonRow()===null,'the season row did not stand down');
  window.__standingSaid=false;
  return JSON.stringify({ deck:keys, ctx:[...w.ctx], passed:true });
})()
