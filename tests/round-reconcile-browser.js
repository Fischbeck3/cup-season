/* F12 · the truth about the save, and which round is mine — on the desk.
   Twins of the phone's RoundReconcileTests: a status is never inferred from a
   title, a match uses the COURSE ID and the day, two candidates are a
   question, and a booking is reconciled per golfer. */
(function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const out={};
  /* three different sentences */
  let s=csSaveStatus([{name:'Jerecho'}],[],false,'Jerecho');
  check(s.title==='Round posted' && s.hasRound,'my posted card reads as posted');
  s=csSaveStatus([],[{name:'Jerecho',reason:'No holes scored'}],false,'Jerecho');
  check(s.title==='Not posted' && s.detail==='No holes scored' && !s.hasRound,'my skipped card reads as not posted with the reason');
  s=csSaveStatus([],[],true,'Jerecho');
  check(s.title==='Not posted' && /casual/.test(s.detail),'a casual round says what it is');
  s=csSaveStatus([{name:'Galen'}],[],false,'Jerecho');
  check(s.title==='Not posted' && !s.hasRound,'somebody else’s post is not mine');
  /* which round is mine */
  const rounds=[{id:'a',api_course_id:'100',played_on:'2026-09-15'},{id:'b',api_course_id:'212',played_on:'2026-09-15'}];
  check(csMyRoundMatch(rounds,'100','2026-09-15').kind==='one','one round on the course that day matches');
  check(csMyRoundMatch(rounds,'100','2026-09-15').id==='a','and it is the right one');
  check(csMyRoundMatch(rounds,null,'2026-09-15').kind==='none','no course id is no evidence');
  check(csMyRoundMatch(rounds,'100','2026-09-14').kind==='none','another day is not this round');
  const two=[{id:'a',api_course_id:'100',played_on:'2026-09-15'},{id:'b',api_course_id:'100',played_on:'2026-09-15'}];
  check(csMyRoundMatch(two,'100','2026-09-15').kind==='ambiguous','two candidates are a question');
  out.passed=true; return JSON.stringify(out);
})()
