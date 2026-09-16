/* F12 · the truth about the save, and which round is mine — on the desk.
   Twins of the phone's RoundReconcileTests after Codex R2/R3/R5: a status is
   decided by PROFILE ID and never by a name; an old payload without identities
   is UNCERTAIN until one authoritative match confirms it; the rounds cache is
   per account and a failed or signed-out read is unknown, never empty. */
(function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const out={};
  const ME='00000000-0000-0000-0000-0000000000e1', ALEX='00000000-0000-0000-0000-000000000a1e';
  /* identity decides */
  let s=csSaveStatus([{name:'Jerecho',profile_id:ME,round_id:'r1'}],[],false,ME);
  check(s.title==='Round posted' && s.hasRound && s.roundId==='r1','my posted card, by id, reads as posted with its round id');
  s=csSaveStatus([],[{name:'Jerecho',profile_id:ME,reason:'No holes scored'}],false,ME);
  check(s.title==='Not posted' && s.detail==='No holes scored' && !s.hasRound,'my skipped card reads as not posted with the reason');
  /* Codex R3 · another Alex posted, this Alex was skipped */
  s=csSaveStatus([{name:'Alex',profile_id:ALEX,round_id:'r2'}],[{name:'Alex',profile_id:ME,reason:'incomplete card'}],false,ME);
  check(s.title==='Not posted' && s.detail==='incomplete card','a shared name does not borrow someone else’s post');
  s=csSaveStatus([{name:'Galen',profile_id:ALEX,round_id:'r2'}],[],false,ME);
  check(s.title==='Not posted' && !s.hasRound,'somebody else’s post is not mine');
  s=csSaveStatus([],[],true,ME);
  check(s.title==='Not posted' && /casual/.test(s.detail),'a casual round says what it is');
  /* an old payload names nobody: uncertain until evidence */
  s=csSaveStatus([{name:'Jerecho'}],[],false,ME);
  check(s.unconfirmed && s.title==='Not confirmed yet' && !s.hasRound,'a payload without identities is unconfirmed');
  check(csConfirmStatus(s,{kind:'one',id:'r9'}).hasRound===true,'one authoritative match confirms it');
  check(csConfirmStatus(s,{kind:'ambiguous',ids:['a','b']}).unconfirmed===true,'two candidates leave it unconfirmed');
  check(csConfirmStatus(s,{kind:'none'}).unconfirmed===true,'no match leaves it unconfirmed');
  /* which round is mine */
  const rounds=[{id:'a',api_course_id:'100',played_on:'2026-09-15'},{id:'b',api_course_id:'212',played_on:'2026-09-15'}];
  check(csMyRoundMatch(rounds,'100','2026-09-15').kind==='one' && csMyRoundMatch(rounds,'100','2026-09-15').id==='a','one round on the course that day matches');
  check(csMyRoundMatch(rounds,null,'2026-09-15').kind==='none','no course id is no evidence');
  check(csMyRoundMatch(rounds,'100','2026-09-14').kind==='none','another day is not this round');
  const two=[{id:'a',api_course_id:'100',played_on:'2026-09-15'},{id:'b',api_course_id:'100',played_on:'2026-09-15'}];
  check(csMyRoundMatch(two,'100','2026-09-15').kind==='ambiguous','two candidates are a question');
  /* Codex R2 · signed out, the evidence is UNKNOWN and unknown never hides */
  return (async()=>{
    const rows = await csMyRoundsOn('2026-09-15');
    check(rows===null,'signed out, my rounds are unknown (null), not an empty list');
    check((await csBookingPlayed('100','2026-09-15'))==='unknown','an unknown read never marks a booking played');
    check((await csBookingPlayed(null,'2026-09-15'))==='open','no course id keeps the booking open');
    out.passed=true; return JSON.stringify(out);
  })();
})()
